#!/usr/bin/env bash
# The harness driver (what `harness start` runs, in tmux or in the foreground): the run's coordinator. Deterministic glue
# around agent sessions:
#   1. no feature list → one initializer session writes it (from the spec files and the run's brief)
#   2. every HARNESS_LANE_POLL seconds it reaps lanes that ended and opens lanes (lanes P1-04): a lane is one milestone
#      run by its own process, lib/lane.sh, in a slot worktree on harness-lane/<run>/<m>, on its own port; MAX_LANES of
#      them at once (default 1: one after another), a further one only with headroom (admit: memory, the five-hour
#      window). A lane opens when its milestone has a feature to try (or all pass, to be verified) and every milestone
#      it depends on is verified (F lanes). In its lane, one fresh coding session per
#      feature, in dependency order. Before each: take answers, sync with the remote, honour pause/stop and the box-wide
#      usage-limit window, run the project's init and the cached suite. After each: a session that ended on a usage
#      limit or API error is given back (not the feature's fault); otherwise commit leftovers, repair the feature list,
#      un-pass on a red suite, record metrics, push.
#      The record (.harness/runs/<run>/) lives only on harness/<run> in the record worktree (lib/record.sh), where
#      sessions see a copy of it that is taken back after them; every write to it goes through one lock.
#   3. a milestone's features all pass → its lane merges main into its branch → one verify session re-runs every step
#      and writes an evidence row per step (too few rows: one more verify on a stronger model; still too few: not
#      verified) → the suite is green on that tree → tag the lane tip → merge it into main through its own PR
#      (MERGE_POLICY=auto), or leave the PR for Michael (pr), or neither (off). The tag holds main, the lane's
#      dependencies and this milestone's commits only; its PR merges once every milestone it depends on has merged.
#      A session that can't go on without Michael ends with "PARKED: <why>": the feature is parked (no attempt spent)
#      until INBOX.md's answers change, and work that doesn't depend on it goes on. Past WEEKLY_STOP_AT of the plan's
#      7-day window (as sessions report it), the run ends before its next coding session.
#      DESK=1: whatever needs Michael (a park, verify, a refused merge or conflict) also starts his desk (lib/desk.sh).
#   4. the end, whatever the reason: every lane exited, summary.json and report.md, a notification (blocked or waiting:
#      the desk too), a retro session, the harness ledger, the slots removed, and (after a session cap, within the
#      run's --until) a continuation in the queue.
# Verify and retro sessions may not change code: whatever they change outside the run record (retro: anything) is
# reverted. A session that ends on a usage limit or API error keeps its commits but not its "passes".
# Environment (set by bin/harness): WT RUN_ID STATE PROJECT_DIR HARNESS_HOME
# HARNESS_LANE_POLL: seconds between the lane coordinator's polls (default 10; the suite sets 1)
set -uo pipefail
: "${WT:?}" "${RUN_ID:?}" "${STATE:?}" "${PROJECT_DIR:?}" "${HARNESS_HOME:?}"
cd "$WT" || exit 1
# shellcheck source=lib/config.sh
source "$HARNESS_HOME/lib/config.sh"
# shellcheck source=lib/prompt.sh
source "$HARNESS_HOME/lib/prompt.sh"
# shellcheck source=lib/scope.sh
source "$HARNESS_HOME/lib/scope.sh"   # scope_run/stop/peak/left/capped: each session in its capped user scope
# shellcheck source=lib/notify.sh
source "$HARNESS_HOME/lib/notify.sh"; NOTIFY_TAG=$RUN_ID   # notify "<message>" [title=… body=… click=… …]: "[<run>] <message>"
# shellcheck source=lib/deploy.sh
source "$HARNESS_HOME/lib/deploy.sh"   # deploy_status: hosts that would build every pushed run branch
source "$HARNESS_HOME/lib/version.sh"  # harness_version: the harness commit driving this segment, and whether it is dirty
# shellcheck source=lib/record.sh
source "$HARNESS_HOME/lib/record.sh"   # record (the lock), run_paths, note, session, journal, merge_milestones, slot_open …
run_paths   # PROJECT_NAME BRANCH RUN_DIR SCRATCH CHECK PORT, RWT REC LIST …, the configuration
mkdir -p "$HARNESS_CACHE"   # installs a project keeps across runs and boots (Playwright browsers …); scratch goes at finish
echo "$MAX_ATTEMPTS" > "$STATE/max-attempts"
T0=$(date +%s); DEADLINE=$(( T0 + HOURS * 3600 )); (( DEADLINE_AT > 0 && DEADLINE_AT < DEADLINE )) && DEADLINE=$DEADLINE_AT
rm -f "$STATE"/waited-* "$STATE"/lanes/*/waited-*   # a restart inside a usage-limit window waits for it again

[[ -z $BRANCH || $BRANCH == "$MAIN_BRANCH" ]] && { log "refusing to run on '${BRANCH:-detached HEAD}'"; exit 1; }
[[ -f $HARNESS_HOME/prompts/policy/$POLICY.md ]] || { log "unknown POLICY '$POLICY' (prompts/policy/*.md)"; exit 1; }

# `harness status` reads these: alive while driver.pid names a live process; why it ended in "ended".
echo $$ > "$STATE/driver.pid"; rm -f "$STATE/ended"
END_REASON="driver exited unexpectedly (see run.log)"
# A TERM runs this at once while the session goes on: its scope stops first, so claude can't work on unread meanwhile.
# It may now take minutes (the teardown): a second TERM/HUP (tmux closing) must not cut it short. Its note is committed
# (that file only, not pushed): a dirty worktree would keep gc from removing it
# Lanes first: each stops its own session and services; fd 9 closed so none waits on a lock this process holds.
trap 'trap "" TERM INT HUP; exec 9>&-; REC_HELD=0; lanes_term; [[ -n ${S_UNIT:-} ]] && scope_stop "$S_UNIT"; services_down "driver exited"; lanes_services_down "driver exited"; git -C "$RWT" commit -q -m "HARNESS: driver exited" -- "$REC/harness-log.md" > /dev/null 2>&1; echo "$END_REASON · $(date "+%F %T")" > "$STATE/ended"; rm -f "$STATE/driver.pid"' EXIT

demote_requests() {   # a stop after Michael queued a continuation of this run is his later word: that one turns automatic
  # the stop's time is when it reached this box (STOP, else INBOX.md pulled), not when the driver got to it: a request
  # queued after it stays requested
  local f at=$STATE/STOP; [[ -f $at ]] || at=$REC/INBOX.md
  for f in "$STATE_ROOT"/queue/*-continue-"$RUN_ID".args "$STATE_ROOT"/queue/h*/*-continue-"$RUN_ID".args; do   # queued, or parked there
    [[ -f $f && ! $f -nt $at ]] && grep -qx -- --requested "$f" || continue
    sed -i '/^--requested$/d' "$f" && note "stop: the queued continuation ${f##*/} is automatic now (the stop came after the request)"
  done
}

# ---- the lanes (lanes P1-04): each open milestone is a lib/lane.sh process; $STATE/lanes/<m>/pid is written here, at
# its start, never by the lane (a lane still sourcing its libraries would look closed and be reaped or opened twice)
POLL=${HARNESS_LANE_POLL:-10} LANE_END="" LANE_ONCE=0
lane_alive() { local p; p=$(cat "$STATE/lanes/$1/pid" 2> /dev/null) && [[ -n $p ]] && kill -0 "$p" 2> /dev/null; }
lanes_open() { local f n=0 m; for f in "$STATE"/lanes/*/pid; do [[ -f $f ]] || continue; m=${f%/pid}; lane_alive "${m##*/}" && n=$(( n + 1 )); done; echo "$n"; }
# Sleep the poll (or <s>), less when a lane exits: its exit wakes the coordinator at once
lane_wait() {
  local f pids=() sp; for f in "$STATE"/lanes/*/pid; do [[ -f $f ]] && pids+=("$(cat "$f")"); done
  sleep "${1:-$POLL}" & sp=$!
  wait -n "$sp" "${pids[@]}" 2> /dev/null; kill "$sp" 2> /dev/null; wait "$sp" 2> /dev/null
  return 0
}
# Every lane whose process is gone: its exit line noted, its pid gone (its slot free), the merges it may have unblocked.
# A session cap, a usage limit, the weekly budget or feature-list edits end the run (LANE_END, and state/lanes-end, so
# every other lane exits 16 before its next session); a stop and the deadline are seen by the coordinator itself. A
# lane that died without a reason needs Michael (never reopened in a loop).
reap() {
  local f m code why n=0
  for f in "$STATE"/lanes/*/pid; do
    [[ -f $f ]] || continue; m=${f%/pid}; m=${m##*/}
    lane_alive "$m" && continue
    read -r code why < "$STATE/lanes/$m/exit" 2> /dev/null || { code=12 why="lane exited unexpectedly"; }
    mv -f "$STATE/lanes/$m/exit" "$STATE/lanes/$m/closed" 2> /dev/null; rm -f "$f"; n=$(( n + 1 ))
    note "lane $m closed ($why)"
    [[ $why == "lane exited unexpectedly" ]] && touch "$STATE/needs-$m"
    [[ $code == 13 || $why == "feature-list edits" ]] && { LANE_END=$why; echo "$why" > "$STATE/lanes-end"; }
  done
  (( n )) && merge_milestones
  return 0
}
wait_lanes() { while (( $(lanes_open) )); do lane_wait; reap; done; reap; }   # until every lane has exited (between sessions)
# <m> → its port, the first free from BASE_PORT (port_taken), written to lanes/<m>/port with lanes/<m>/opening, which
# holds it until lane_open has written the pid; under the record lock (record port_alloc_) and the box-wide port lock,
# which cmd_start takes too, so neither another lane nor another run takes it meanwhile
port_alloc_() {
  local p=$BASE_PORT
  { flock 7; while port_taken "$p"; do p=$(( p + 1 )); done
    echo "$p" > "$STATE/lanes/$1/port"; : > "$STATE/lanes/$1/opening"; } 7> "$STATE_ROOT/port.lock"
  echo "$p"
}
# <m>: the lowest slot no open lane holds; the services the slot's last lane left up stopped silently (its port is
# reused, as run_init replaces its own: D4); its port (slot 0: the run's, so one lane is the run as before; slot 1 up:
# port_alloc_); the slot opened (slot_open: its base, the note); the lane's process started
lane_open() {
  local m=$1 k=0 f d busy
  while :; do
    busy=0; for f in "$STATE"/lanes/*/pid; do [[ -f $f ]] || continue; d=${f%/pid}
      lane_alive "${d##*/}" && [[ $(cat "$d/slot" 2> /dev/null) == "$WT_ROOT_DIR/lanes/$RUN_ID/slot-$k" ]] && busy=1; done
    (( busy )) || break; k=$(( k + 1 ))
  done
  (( ${SVC_UP:-0} )) && { scope_stop "$SVC_UNIT"; SVC_UP=0; }   # the initializer's services: the lane starts its own
  for f in "$STATE"/lanes/*/svc-up; do
    [[ -f $f && $(cat "${f%/svc-up}/slot" 2> /dev/null) == "$WT_ROOT_DIR/lanes/$RUN_ID/slot-$k" ]] || continue
    scope_stop "$(cat "$f")"; rm -f "$f"
  done
  mkdir -p "$STATE/lanes/$m"
  if (( k == 0 )); then LANE_PORT=$PORT; echo "$PORT" > "$STATE/lanes/$m/port"; else LANE_PORT=$(record port_alloc_ "$m"); fi
  slot_open "$m" "$k"; local rc=$?
  LANE="" LBRANCH=""; rec_cd   # SLOT stays: finish counts the last lane's tests in it
  (( rc == 0 )) || { rm -f "$STATE/lanes/$m/opening"; return 1; }
  rm -f "$STATE/lanes/$m/exit" "$STATE/lanes/$m/need"
  LANE=$m LANE_SLOT=$k LANE_PORT=$LANE_PORT LANE_ONCE=$LANE_ONCE bash "$HARNESS_HOME/lib/lane.sh" "$m" < /dev/null 8>&- 9>&- &
  echo $! > "$STATE/lanes/$m/pid"; rm -f "$STATE/lanes/$m/opening"
  LANE=""
}
# <m> "<kind>\t<reason>": admit refused its lane; noted once per kind (the GB figure changes every poll, the kind
# doesn't), and the open is tried again next poll
wait_note() {
  local kind=${2%%$'\t'*}
  [[ $(cat "$STATE/lanes/$1/waiting" 2> /dev/null) == "$kind" ]] && return 0
  echo "$kind" > "$STATE/lanes/$1/waiting"; note "lane $1 waiting: ${2#*$'\t'}"
}
# <why>: the services every closed lane left up, torn down in its slot with its port and scratch (finish, the EXIT trap)
lanes_services_down() {
  local f d
  for f in "$STATE"/lanes/*/svc-up; do
    [[ -f $f ]] || continue; d=${f%/svc-up}
    lane_alive "${d##*/}" && continue   # a live lane tears its own down
    ( LDIR=$d SVC_UP=1 SVC_INIT=0 SVC_TD="" SVC_UNIT=$(cat "$f") SVC_DIR=$(cat "$d/slot" 2> /dev/null) PORT=$(cat "$d/port" 2> /dev/null) \
        SCRATCH=$SCRATCH/lanes/${d##*/}; mkdir -p "$SCRATCH"; services_down "$1" )
    rm -f "$f"
  done
}
# The coordinator exiting (a TERM, a crash): every lane gets a TERM and up to 150 s to stop its session and services
# (its teardown runs under timeout -k 10s 2m)
lanes_term() {
  local f i
  for f in "$STATE"/lanes/*/pid; do [[ -f $f ]] && kill -TERM "$(cat "$f")" 2> /dev/null; done
  for (( i = 0; i < 1500; i++ )); do (( $(lanes_open) )) || break; sleep 0.1; done
  return 0
}
# A lane process an earlier coordinator left (it died without its trap: SIGKILL, OOM) still works in its slot: a TERM
# and its own trap stop it before this segment reopens that slot. Only a pid that is lib/lane.sh of this state dir.
lanes_orphans() {
  local f p
  for f in "$STATE"/lanes/*/pid; do
    [[ -f $f ]] && p=$(cat "$f") && kill -0 "$p" 2> /dev/null && tr '\0' ' ' < "/proc/$p/cmdline" 2> /dev/null | grep -q "lib/lane.sh" || continue
    p=${f%/pid}; note "lane ${p##*/}: its process $(cat "$f") outlived the last segment's driver; stopped"; kill -TERM "$(cat "$f")" 2> /dev/null
  done
  for (( p = 0; p < 1500; p++ )); do (( $(lanes_open) )) || break; sleep 0.1; done
}

# The deadline's verify (decisions/2026-10-26-verify-before-deadline): one session per complete, unverified milestone
# whose lane can open, each in its lane (LANE_ONCE), unless a stop came first or a usage-limit window holds, when its
# session would only be refused (the next segment verifies first thing)
deadline_verify() {
  local m ms="" upto
  for m in $(F milestones "$LIST"); do
    [[ -f $STATE/verified-$m || -f $STATE/needs-$m ]] || ! F milestone-done "$LIST" "$m" || ms+="${ms:+, }$m"
  done
  [[ -n $ms ]] || return 0
  upto=$(cat "$LIMIT_FILE" 2>/dev/null || echo 0)
  if [[ $(control) == stop ]]; then note "deadline reached: $ms complete but unverified; stopped by Michael, so no verify before the end"
  elif (( upto > $(date +%s) )); then note "deadline reached: $ms complete but unverified; the usage limit holds until $(date -d "@$upto" +%H:%M), so no verify before the end"
  else
    for m in $(F lanes "$LIST" "$ATT" "$MAX_ATTEMPTS" "$PARKED" "$STATE" | cut -f1); do
      [[ $m != default ]] && F milestone-done "$LIST" "$m" || continue
      (( $(cat "$LIMIT_FILE" 2>/dev/null || echo 0) > $(date +%s) )) && break   # a verify just refused: the next would be too
      note "deadline reached: $m complete but unverified; one verify before the end"
      LANE_ONCE=1; lane_open "$m" && { LAST_LANE=$m; wait_lanes; }; LANE_ONCE=0
    done
  fi
}

retro() {   # a short read-only session that turns this run's evidence into proposed harness changes
  local rlog=$LOGS/zz-retro-$(date +%H%M%S).jsonl rstart reverted x backlog nolist="" p=$RUN_DIR/retro-proposals.json
  rstart=$(git rev-parse HEAD)
  # the backlog as the list prints it ({{BACKLOG}}): ids to reuse and statuses to cite, not re-argue
  backlog=$(node "$HARNESS_HOME/lib/backlog.mjs" list "$LEDGER/retro-backlog.jsonl" --max-bytes 6000 2> "$SCRATCH/backlog.err") \
    || nolist="backlog: the retro prompt has no backlog: $(head -1 "$SCRATCH/backlog.err" | cut -c1-200 | sed 's/^backlog: //')"
  HARNESS_BACKLOG=$backlog HARNESS_SUMMARY=$REC/summary.json HARNESS_STATE=$STATE HARNESS_LEDGER=$LEDGER HARNESS_END_REASON=$END_REASON prompt retro
  log "retro · $(F model "$RETRO_MODEL")"
  MAX_TURNS=40 SESSION_BUDGET_USD=3 session retro "$(F model "$RETRO_MODEL")" "$rlog" retro
  # its one output file besides retro.md: restrict deletes it, so it goes to scratch first, and only when this retro
  # wrote it (not a continued run's earlier copy) as a plain file of at most 64 KB (a symlink would carry another file
  # into the record); ledger() merges it into the backlog (decisions/2026-10-26-retro-backlog)
  rm -f "$SCRATCH/retro-proposals.json"
  [[ -f $p && ! -L $p ]] && (( $(stat -c %s "$p") <= 65536 )) && ! git show "$rstart:$p" 2> /dev/null | cmp -s - "$p" \
    && cp "$p" "$SCRATCH/retro-proposals.json"
  reverted=$(restrict "$rstart" nothing retro | { [[ -f $SCRATCH/retro-proposals.json ]] && grep -vxF "$p" || cat; } | paste -sd' ')
  for x in "${S_NOTES[@]}"; do note "$x"; done   # after restrict: the driver's notes, not the retro's edits
  [[ -n $reverted ]] && note "retro: reverted edits (it is read-only): $reverted"
  [[ -n $nolist ]] && note "$nolist"   # noted here: restrict reverts a note written before the session
  if [[ -f $SCRATCH/retro-proposals.json ]]; then cp "$SCRATCH/retro-proposals.json" "$REC/"   # in the run record, as retro.md
  else note "backlog: the retro wrote no retro-proposals.json"; fi
  MET final "$rlog" > "$SCRATCH/retro.md"
  [[ -s $SCRATCH/retro.md ]] && ! MET limit "$rlog" "$S_WALL" "$S_EXIT" > /dev/null && cp "$SCRATCH/retro.md" "$REC/retro.md"
  record MET append "$rlog" "$REC/metrics.jsonl" "$RUN_ID" retro "" "$(F model "$RETRO_MODEL")" true "$S_WALL" "$S_EXIT" false retro "$S_PEAK"
}

ledger() {   # the whole run record into the harness's own record, for `harness trends`, retros and calibration
  local d=$LEDGER/$PROJECT_NAME/$RUN_ID
  mkdir -p "$d" && cp -r "$REC/." "$d/"
  (
    flock 9
    SUM ledger-line "$REC/summary.json" "$LEDGER/runs.jsonl"
    local out paths=("$d" "$LEDGER/runs.jsonl")   # the retro's proposals into the backlog; a bad file is noted and skipped whole
    if [[ -f $SCRATCH/retro-proposals.json ]]; then
      out=$(node "$HARNESS_HOME/lib/backlog.mjs" merge "$LEDGER/retro-backlog.jsonl" "$SCRATCH/retro-proposals.json" "$RUN_ID" "$(date +%F)" 2>> "$STATE/run.log")
      note "${out:-backlog: merge failed (run.log)}"
    fi
    [[ -f $LEDGER/retro-backlog.jsonl ]] && paths+=("$LEDGER/retro-backlog.jsonl")
    if [[ $LEDGER_COMMIT == 1 ]] && git -C "$LEDGER" rev-parse --show-toplevel > /dev/null 2>&1; then
      git -C "$LEDGER" add -- "${paths[@]}" \
        && git -C "$LEDGER" commit -q -m "ledger: $RUN_ID ($PROJECT_NAME): $(F summary "$LIST")" -- "${paths[@]}" \
        || log "ledger commit skipped"
    fi
  ) 9> "$STATE_ROOT/ledger.lock"
}

finish() {   # reason → every lane exited, summary, notification, retro, ledger, slots removed, continuation
  END_REASON=$1
  wait_lanes   # each stops between sessions: a stop, the deadline, a cap
  unmaterialize; rec_cd   # a copy a killed lane left in its slot
  echo "$1 · $(date '+%F %T')" > "$STATE/ended"   # now, not at exit: the summary reads it
  note "run ended ($1): $(F summary "$LIST" 2>/dev/null) · $(MET summary "$REC/metrics.jsonl")"
  merge_milestones
  # the tree's count (the slot's, the last lane's code, if one opened): tests_end's, a red tree none. The last lane's
  # outputs are the run's (scratch_done keeps them in the state dir): copied first, so tests_end reads that lane's
  # check-<key>.out under an older, empty marker
  local key f dir=$RWT L=$SCRATCH/lanes/${LAST_LANE:-}; [[ -n $SLOT && -d $SLOT ]] && dir=$SLOT
  if [[ -n ${LAST_LANE:-} && -d $L ]]; then
    for f in "$L"/init.out "$L"/check.out "$L"/check-*.out; do [[ -f $f ]] && cp -f "$f" "$SCRATCH/"; done
  fi
  key=$(cd "$dir" && { green; tests_end final; node "$HARNESS_HOME/lib/treekey.mjs"; })   # scratch_done keeps this tree's output
  services_down "$1"; lanes_services_down "$1"   # after the last suite run, which may need them
  [[ -n ${LAST_LANE:-} && -f $L/teardown.out ]] && cat "$L/teardown.out" >> "$SCRATCH/teardown.out"
  slot_close   # every slot goes; lane branches are pushed; a merged lane's branch goes
  SUM build "$RWT" "$RUN_ID" "$STATE" > "$REC/summary.json"
  SUM report "$REC/summary.json" > "$REC/report.md"   # the end notification's click; rewritten after the retro
  rec_commit "HARNESS: run ended ($1)"; sync_record
  # the run's one end notification goes out now, not after the retro (minutes, and a crash there would lose it).
  # The reasons below are Michael's to act on: the report, the INBOX one tap away
  local pri="" acts="" sum
  case $1 in "blocked on"* | "waiting on Michael"* | "feature-list edits"* | "initializer failed"*)
    pri=high acts=$(node "$NOTIFY_MJS" actions "Edit INBOX" "$(gh_url "$RUN_DIR/INBOX.md" edit)" Progress "$(gh_url "$RUN_DIR/progress.md")") ;;
  esac
  sum="$(F summary "$LIST" 2>/dev/null) · $(jq -r '"$\(.cost.total) · $\(.cost.per_passing_feature) per passing feature"' "$REC/summary.json" 2>/dev/null)"
  notify "ended ($1): $sum" title="[$RUN_ID] ended: $1" priority=$pri click="$(gh_url "$RUN_DIR/report.md")" actions="$acts"
  # a failed post notes it in harness-log.md: commit it now, before a retro that may never finish
  [[ -n $(git status --porcelain -- "$RUN_DIR") ]] && { rec_commit "HARNESS: run-end notification failed"; sync_record; }
  case $1 in "blocked on"* | "waiting on Michael"*) desk "ended: $1" ;; esac   # after that commit: its note is no failed post
  if [[ $RETRO == 1 && -f $LIST ]]; then retro; SUM build "$RWT" "$RUN_ID" "$STATE" > "$REC/summary.json"; fi
  SUM report "$REC/summary.json" > "$REC/report.md"
  rec_commit "HARNESS: summary and retro"; sync_record
  ledger
  scratch_done "$key"   # the record keeps the last suite and init output; the run's scratch goes (decisions/2026-10-25-scratch-cleanup)
  # Only a session cap continues by itself (time and Michael's stops don't), within the run's --until, at most
  # AUTO_CONTINUE_MAX times, without giving given-up features new attempts.
  local left conts; left=$(F next "$LIST" "$ATT" "$MAX_ATTEMPTS" "$PARKED" 2>/dev/null); conts=$(cat "$STATE/auto-continues" 2>/dev/null || echo 0)
  for f in "$STATE"/lanes/*/review-escalate; do [[ -s $f ]] && left+=" ${f%/review-escalate}"; done   # a pending round is work left: it takes no attempt
  if [[ -n $left && $AUTO_CONTINUE == 1 && $1 == session\ cap* ]] && (( conts < ${AUTO_CONTINUE_MAX:-3} )) \
     && (( DEADLINE_AT == 0 || $(date +%s) < DEADLINE_AT - 600 )); then
    echo $(( conts + 1 )) > "$STATE/auto-continues"
    "$HARNESS_HOME/bin/harness" queue add --continue "$RUN_ID" --automatic --keep-attempts $( (( DEADLINE_AT )) && echo "--until-epoch $DEADLINE_AT") > /dev/null 2>&1 \
      && note "continuation queued ($(( conts + 1 )) of ${AUTO_CONTINUE_MAX:-3}, automatic; it starts when the queue runs)"
  fi
  # a note after the last commit (the continuation): commit it too, or the worktree stays dirty and gc skips it
  [[ -n $(git status --porcelain -- "$RUN_DIR") ]] && { rec_commit "HARNESS: run end notes"; sync_record; }
  log "run kept in $RWT on $RBRANCH · report: harness report $RUN_ID · continue: harness continue $RUN_ID"
  exit 0
}

# ---------------------------------------------------------------------------------------------------------------
resumed=0; grep -q " run $RUN_ID on " "$STATE/run.log" 2> /dev/null && resumed=1   # an earlier segment logged its start
# which harness drove this segment (the latest segment's wins in the summary; run.log keeps each), for trends --by version
harness_version "$HARNESS_HOME"
[[ ${HARNESS_MERGE_ONLY:-} ]] || { echo "$HARNESS_VERSION" > "$STATE/harness-version"; echo "$HARNESS_DIRTY" > "$STATE/harness-dirty"; }   # `harness merge` drives no sessions
log "run $RUN_ID on $BRANCH in $WT · port $PORT · policy $POLICY · merge $MERGE_POLICY · harness $HARNESS_VERSION$( (( HARNESS_DIRTY )) && echo +dirty)"
log "  suite: ${CHECK_CMD:-(none detected; nothing gates passes)} · smoke: $SMOKE_CMD · init: $INIT_CMD"
log "  permissions: user settings$( [[ -f $AGENT_SETTINGS ]] && echo " + $AGENT_SETTINGS (--settings)" || echo " only ($AGENT_SETTINGS not found)")"
log "  MCP servers: $( [[ -f $WT/.mcp.json ]] && echo ".mcp.json (--strict-mcp-config --mcp-config)" || echo "none (--strict-mcp-config; no .mcp.json)")"
[[ -f $REC/INBOX.md ]] || cat > "$REC/INBOX.md" <<EOF
status: run
<!-- Steer this run from the GitHub app: edit this file on branch $BRANCH.
     Change the first line to "status: pause" or "status: stop"; write answers to questions under "## Answers".
     The harness pulls before every session; every session reads this file at startup. -->

## Answers
EOF
if [[ -s $STATE/brief.md ]]; then   # a brief given at start or continue: committed, so sessions and the record see it
  { [[ -s $REC/brief.md ]] && echo; echo "## $(date '+%F %H:%M')"; cat "$STATE/brief.md"; } >> "$REC/brief.md"
  : > "$STATE/brief.md"
fi
if [[ -s $STATE/inbox-unstopped ]]; then   # harness continue reset a phone stop that ended the last segment
  note "INBOX.md: \`$(cat "$STATE/inbox-unstopped")\` set back to \`status: run\` (that stop ended the last segment; harness continue started this one)"
  rm -f "$STATE/inbox-unstopped"
fi
echo 0 > "$STATE/sessions"; echo 0 > "$STATE/limits"   # per segment, as the counters were: a continuation after a cap starts afresh
rec_commit "HARNESS: start run $RUN_ID"
sync_record
# A resumed run (with or without its list) catches up with main and its configuration before any session, the
# initializer included, so a re-run initializer plans from the current spec; a fresh run already starts from main.
if [[ -f $LIST ]] || (( resumed )); then
  before_cfg=$(git rev-parse -q HEAD:.harness/config.sh 2>/dev/null)
  sync_main
  if [[ $(git rev-parse -q HEAD:.harness/config.sh 2>/dev/null) != "$before_cfg" ]]; then
    load_config
    [[ -f $HARNESS_HOME/prompts/policy/$POLICY.md ]] || { log "unknown POLICY '$POLICY' after merging main"; END_REASON="unknown POLICY"; exit 1; }
    note "configuration reloaded after merging $MAIN_BRANCH: policy $POLICY · suite ${CHECK_CMD:-none} · spec ${SPEC_FILES:-(none)}"
  fi
  [[ -f $LIST ]] && merge_milestones   # merge what is verified
fi
if [[ ${HARNESS_MERGE_ONLY:-} ]]; then   # `harness merge`: also retire a v2 whole-run PR (milestones merge through their own PRs)
  if [[ $($GH pr view "$BRANCH" --json state -q .state 2>/dev/null) == OPEN ]]; then
    $GH pr close "$BRANCH" --comment "Superseded: harness v3 merges each verified milestone into $MAIN_BRANCH through its own PR (tags run/$RUN_ID/<milestone>). Unverified work stays on $BRANCH until its milestone is verified." > /dev/null 2>> "$STATE/run.log" \
      && note "closed the whole-run PR for $BRANCH (milestones merge through their own PRs now)"
  fi
  rmdir "$SCRATCH" 2> /dev/null   # created above for nothing: `harness merge` runs no init or session (a kept scratch isn't empty)
  rec_commit "HARNESS: merge"; sync_record; END_REASON="merge only"; exit 0
fi

# A run from before the journal (a feature list, no entries.jsonl): its progress.md is kept, byte for byte, as
# progress-archive.md and the journal starts here (decisions/2026-10-22-rendered-progress). Nothing is rendered until
# the first entry, so progress.md stays as it was until a session ends; `harness merge` exited above, untouched.
if [[ -f $LIST && ! -f $REC/entries.jsonl ]]; then
  : > "$REC/entries.jsonl"
  if [[ -f $REC/progress.md ]]; then cp "$REC/progress.md" "$REC/progress-archive.md"
    note "journal started; progress.md kept as progress-archive.md"
  else note "journal started (no progress.md to keep)"; fi   # then the default header, and no legacy part
  rec_commit "HARNESS: journal started"; sync_record
fi

# Once per run (a continue doesn't repeat it): a host that builds every branch makes a preview per pushed session
# unless origin/main carries the guard, since the run branch branches off main (E0b, D-H33). The run goes on.
deploy_check() {
  [[ -f $STATE/deploy-checked ]] && return 0
  touch "$STATE/deploy-checked"
  git fetch -q origin "$MAIN_BRANCH" 2> /dev/null
  local h hosts=() j
  while read -r h; do
    case $h in
      vercel) note "deploy guard: vercel.json on origin/$MAIN_BRANCH has no git.deploymentEnabled \"harness/**\": false; this run will create a preview deploy per session (harness init adds it)" ;;
      netlify) note "deploy guard: netlify.toml on origin/$MAIN_BRANCH has no [build] ignore for harness/* refs; this run will create a preview deploy per session (harness init adds it)" ;;
      *) continue ;;
    esac
    hosts+=("$h")
  done < <(deploy_status "$WT" "origin/$MAIN_BRANCH")
  (( ${#hosts[@]} )) || return 0
  printf -v j '%s, ' "${hosts[@]}"; notify "no deploy guard (${j%, }): this run will create a preview deploy per session"
  return 0
}
deploy_check

# Every segment: the project's memory files linted (lib/memlint.mjs; decisions/2026-10-26-memlint), one note per
# finding. Notes only: a finding or a failing lint never stops the run. HARNESS_MEMLINT stands in for the lint (tests).
# Findings are stdout only (a node warning on stderr is no finding); a store on a hung mount can't hold the segment.
memlint_check() {
  local out rc f err=$SCRATCH/memlint.err
  if [[ ${HARNESS_MEMLINT:-} ]]; then out=$(timeout 60 "$HARNESS_MEMLINT" "$WT" 2> "$err")
  else out=$(timeout 60 node "$HARNESS_HOME/lib/memlint.mjs" "$WT" 2> "$err"); fi
  rc=$?
  if (( rc )); then f=$(grep -m1 -v '^\s*$' "$err" 2> /dev/null); note "memlint: failed (exit $rc)${f:+: ${f:0:200}}"; return 0; fi
  while IFS= read -r f; do [[ -n $f ]] && note "memlint: $f"; done <<< "$out"
  return 0
}
memlint_check

# One probe per segment (this driver process): without a user bus every session runs bare, said once
unset SCOPE_OK; scope_available || note "no user systemd: sessions and suites run uncapped"

if [[ ! -f $LIST ]]; then
  mem_gate
  run_init
  HARNESS_CALIBRATION=$(SUM calibration "$LEDGER" "$PROJECT_NAME" 2>/dev/null) prompt initializer
  log "initializer · $(F model "$INIT_MODEL")"
  istart=$(git rev-parse HEAD)
  session init "$(F model "$INIT_MODEL")" "$LOGS/00-init.jsonl" initializer
  commit_all "WIP: initializer — uncommitted at session end (harness)"
  # the record branch holds the record only: whatever the initializer changed elsewhere goes (D3, decisions/2026-10-26-lanes)
  reverted=$(restrict "$istart" record initializer | paste -sd' ')
  [[ -n $reverted ]] && note "initializer: reverted edits outside the run record (the record branch holds the record only): $reverted"
  journal init init "$LOGS/00-init.jsonl" "$(F model "$INIT_MODEL")" "$istart"   # a failed or refused initializer too
  if ! F summary "$LIST" > /dev/null 2>&1; then
    if why=$(MET limit "$LOGS/00-init.jsonl" "$S_WALL" "$S_EXIT"); then note "initializer refused: ${why%%$'\t'*}"; finish "usage limit before the feature list"; fi
    note "initializer did not produce a valid $LIST; stopping"; finish "initializer failed"
  fi
  record MET append "$LOGS/00-init.jsonl" "$REC/metrics.jsonl" "$RUN_ID" init "" "$(F model "$INIT_MODEL")" true "$S_WALL" "$S_EXIT" false init "$S_PEAK"
  note "feature list written: $(F summary "$LIST")"
  note "$(F lint "$LIST" --note)"   # what the initializer's own lint run left; the list stays as written (decisions/2026-10-26-step-lint)
  rec_commit "HARNESS: initializer done"; sync_record
  notify "started: $(F summary "$LIST")" click="$(gh_url "$RUN_DIR/progress.md")"
fi

if [[ ! -f $STATE/deps-noted ]]; then   # once per run: milestones that wait on everything before them
  u=$(F undeclared "$LIST")
  [[ -n $u ]] && note "dependencies: $u $( [[ $u == *,* ]] && echo have || echo has) no after list, so $( [[ $u == *,* ]] && echo each waits || echo it waits) on every earlier feature (one given up or parked there stops it)"
  touch "$STATE/deps-noted"
fi
[[ $MAX_SESSIONS == auto ]] && MAX_SESSIONS=$(( 3 * $(jq '.features | length' "$LIST") + 5 ))
export HARNESS_T0=$T0 HARNESS_DEADLINE=$DEADLINE LANE_MAX_SESSIONS=$MAX_SESSIONS SCOPE_OK
mkdir -p "$STATE/lanes"; lanes_orphans   # an earlier segment's lanes are gone, and its run end with them
rm -f "$STATE"/lanes/*/pid "$STATE"/lanes/*/exit "$STATE"/lanes/*/opening "$STATE"/lanes/*/waiting "$STATE/lanes-end"
paused=0 LAST_LANE=""
# The coordinator: every POLL seconds (at once when a lane exits) reap, check the run's ends, open what can open.
while :; do
  rec_cd
  reap
  [[ -n $LANE_END ]] && finish "$LANE_END"
  (( $(lanes_open) == 0 && $(cat "$STATE/sessions") >= MAX_SESSIONS )) && finish "session cap ($MAX_SESSIONS)"
  if (( $(date +%s) >= DEADLINE )); then   # the lanes stop between sessions; complete milestones get one verify
    if (( paused )); then note "deadline reached while paused"; else note "deadline reached"; fi
    wait_lanes; deadline_verify
    if (( paused )); then finish "deadline (paused)"; else finish "deadline"; fi
  fi
  alive=$(lanes_open)
  if (( alive < MAX_LANES || paused )); then   # with every lane slot taken there is nothing to decide: no fetch each poll
    take_answers; sync_record
    for id in $(record F unpark "$PARKED" "$(answers_hash)"); do note "$id unparked: INBOX.md has new answers"; done
  fi
  c=$(control)
  [[ $c == stop ]] && { wait_lanes; demote_requests; why=$(stop_why); note "$why"; finish "$why"; }
  if [[ $c == pause ]]; then   # the lanes pause themselves after their session; nothing opens
    if (( ! paused )); then
      paused=1; log "paused (INBOX.md status or harness pause)"; notify "paused"
      services_down paused; lanes_services_down paused; rec_commit "HARNESS: paused"; sync_record   # the note reaches the phone now
    fi
    lane_wait "${HARNESS_PAUSE_POLL:-60}"; continue
  fi
  (( paused )) && { paused=0; log "resumed"; }
  if (( alive == 0 )); then   # box-wide gates: with a lane open, it waits and stops by itself
    limit_wait || continue   # cut short by a stop: the next poll sees it
    (( $(date +%s) >= DEADLINE )) && continue
    if why=$(weekly_over "$USAGE"); then note "stopping before the next session: $why"; finish "weekly budget ($why)"; fi
  fi
  opened=0
  if (( alive < MAX_LANES )) && (( $(cat "$LIMIT_FILE" 2> /dev/null || echo 0) <= $(date +%s) || alive == 0 )); then
    while IFS=$'\t' read -r m _; do
      [[ -n $m ]] || continue
      a=$(lanes_open); (( a < MAX_LANES )) || break   # the slot count is the configuration, not headroom: no note
      if why=$(admit "$a"); then lane_open "$m" && { opened=1 LAST_LANE=$m; rm -f "$STATE/lanes/$m/waiting"; }
      else mkdir -p "$STATE/lanes/$m"; wait_note "$m" "$why"; fi
    done < <(F lanes "$LIST" "$ATT" "$MAX_ATTEMPTS" "$PARKED" "$STATE")
  fi
  if (( ! opened && $(lanes_open) == 0 )); then   # nothing open and nothing to open: the run's end, as before lanes
    [[ $(F summary "$LIST") =~ ^([0-9]+)/([0-9]+) && ${BASH_REMATCH[1]} == "${BASH_REMATCH[2]}" ]] && { note "every feature passes"; finish "done"; }
    parked=$(F parked "$PARKED" "$LIST" | cut -f1 | paste -sd, -)
    blocked=$(F blocked "$LIST" "$ATT" "$MAX_ATTEMPTS" "$PARKED" | awk -F'\t' '{print $2}' | sort -u | grep -vxF -f <(tr , '\n' <<< "$parked") | paste -sd, -)
    # D5: features that could run but wait on a milestone that needs Michael (its lane can't open past it)
    needs=""; [[ -n $(F next "$LIST" "$ATT" "$MAX_ATTEMPTS" "$PARKED") ]] && for f in "$STATE"/needs-*; do [[ -f $f ]] && needs+="${needs:+,}${f##*/needs-}"; done
    ends=()
    if [[ -n $blocked ]]; then note "blocked: the remaining features wait on $blocked (given up; needs Michael)"; ends+=("blocked on $blocked"); fi
    if [[ -n $parked ]]; then note "waiting on Michael: $parked (parked; answer in INBOX.md, then harness continue $RUN_ID)"; ends+=("waiting on Michael: $parked"); fi
    if [[ -n $needs ]]; then note "waiting on Michael: the remaining features wait on $needs (needs Michael; see harness-log.md)"; ends+=("waiting on Michael: $needs"); fi
    if (( ${#ends[@]} )); then finish "$(printf '%s; ' "${ends[@]}" | sed 's/; $//')"; fi
    note "no feature left to try: $(F summary "$LIST")"; finish "no feature left to try"
  fi
  lane_wait
done
