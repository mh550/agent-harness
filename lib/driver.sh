#!/usr/bin/env bash
# The harness driver (what `harness start` runs, in tmux or in the foreground). Deterministic glue around agent sessions:
#   1. no feature list → one initializer session writes it (from the spec files and the run's brief)
#   2. one fresh coding session per feature, in dependency order. Before each: take answers, sync with the remote,
#      honour pause/stop and the box-wide usage-limit window, run the project's init and the cached suite.
#      After each: a session that ended on a usage limit or API error is given back (not the feature's fault);
#      otherwise commit leftovers, repair the feature list, un-pass on a red suite, record metrics, push.
#      The record (.harness/runs/<run>/) lives only on harness/<run> in the record worktree (lib/record.sh); each
#      milestone's code lives on its lane branch harness-lane/<run>/<m>, worked one lane at a time in the slot worktree,
#      where sessions see a copy of the record that is taken back after them (lanes P1-03).
#   3. a milestone's features all pass → merge main into its lane branch → one verify session re-runs every step and
#      writes an evidence row per step (too few rows: one more verify on a stronger model; still too few: not verified)
#      → the suite is green on that tree → tag the lane tip → merge it into main through its own PR
#      (MERGE_POLICY=auto), or leave the PR for Michael (pr), or neither (off). The tag holds main, the lane's
#      dependencies and this milestone's commits only; its PR merges once every milestone it depends on has merged.
#      A session that can't go on without Michael ends with "PARKED: <why>": the feature is parked (no attempt spent)
#      until INBOX.md's answers change, and work that doesn't depend on it goes on. Past WEEKLY_STOP_AT of the plan's
#      7-day window (as sessions report it), the run ends before its next coding session.
#      DESK=1: whatever needs Michael (a park, verify, a refused merge or conflict) also starts his desk (lib/desk.sh).
#   4. the end, whatever the reason: summary.json and report.md, a notification (blocked or waiting: the desk too), a
#      retro session, the harness ledger, and (after a session cap, within the run's --until) a continuation in the queue.
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

prompt_vars   # PROJECT_NAME BRANCH RUN_DIR SCRATCH CHECK PORT
# the record worktree and branch (cwd between sessions), the record itself (absolute), the slot's parent; the slot and
# lane branch are set by slot_open (lib/record.sh)
RWT=$WT RBRANCH=$BRANCH REC=$WT/$RUN_DIR WT_ROOT_DIR=${WT%/*} SLOT="" LBRANCH="" LANE=""
CLAUDE=${HARNESS_CLAUDE:-claude} GH=${HARNESS_GH:-gh}
F() { node "$HARNESS_HOME/lib/features.mjs" "$@"; }
MET() { node "$HARNESS_HOME/lib/metrics.mjs" "$@"; }
SUM() { node "$HARNESS_HOME/lib/summary.mjs" "$@"; }

LIST=$REC/feature_list.json SLIST=$REC/feature_list.json
LOGS=$STATE/logs ATT=$STATE/attempts.json PARKED=$STATE/parked.json
STATE_ROOT=$(cd "$STATE/../.." && pwd) LIMIT_FILE=$(cd "$STATE/../.." && pwd)/LIMIT_UNTIL USAGE=$(cd "$STATE/../.." && pwd)/USAGE_7D
LEDGER=${HARNESS_LEDGER:-$HARNESS_HOME/ledger}
mkdir -p "$LOGS" "$REC" "$SCRATCH"
# The configuration comes from the worktree, so it is loaded again after a resumed run merges main (which may have
# changed .harness/config.sh, e.g. a new POLICY).
load_config() {
  harness_config "$WT" "$STATE"
  prompt_env   # the exports every session and template sees (lib/prompt.sh)
}
load_config
mkdir -p "$HARNESS_CACHE"   # installs a project keeps across runs and boots (Playwright browsers …); scratch goes at finish
echo "$MAX_ATTEMPTS" > "$STATE/max-attempts"
T0=$(date +%s); DEADLINE=$(( T0 + HOURS * 3600 )); (( DEADLINE_AT > 0 && DEADLINE_AT < DEADLINE )) && DEADLINE=$DEADLINE_AT
rm -f "$STATE"/waited-*   # a restart inside a usage-limit window waits for it again

log() { echo "$(date '+%F %T') $*" | tee -a "$STATE/run.log"; }
note_() { echo "- $(date '+%F %H:%M') · $*" >> "$REC/harness-log.md"; }
note() { log "$*"; record note_ "$*"; }   # phone-readable, committed with the record
# <why>: the project's teardown, then the services scope, then one note (decisions/2026-10-25-teardown-hook). Only after
# an init started something (SVC_UP): finish's call and the EXIT trap's after it give one note, and a segment that never
# ran an init is silent. SVC_UP clears after the stop, so a TERM during a teardown still stops the scope; the hook runs
# in the background (SVC_TD) so the trap, which bash runs at once, waits for it instead of starting a second. A TERM
# during an init (SVC_INIT) stops the init first, or it would start what the hook just stopped (L2-06 review).
services_down() {
  (( ${SVC_UP:-0} )) || return 0
  local rc=0 unit cmd=${TEARDOWN_CMD:-} dir=${SVC_DIR:-$PWD}; unit=$(scope_unit "$RUN_ID" svc)
  [[ -n $cmd || ! -x $dir/.harness/teardown.sh ]] || cmd=.harness/teardown.sh   # looked up now: a hook added mid-run counts
  (( ${SVC_INIT:-0} )) && scope_stop "$unit"
  if [[ -n ${SVC_TD:-} ]]; then wait "$SVC_TD"; rc=$?
  elif [[ -n $cmd ]]; then
    ( cd "$dir" || exit 1; HARNESS_PORT=$PORT HARNESS_SCRATCH=$SCRATCH HARNESS_TEARDOWN_WHY=$1 exec timeout -k 10s 2m bash -c "$cmd" ) < /dev/null >> "$SCRATCH/teardown.out" 2>&1 &   # in the tree the init ran in (a lane's slot)
    SVC_TD=$!; wait "$SVC_TD"; rc=$?
  fi
  scope_stop "$unit"; SVC_UP=0 SVC_TD=""
  if (( rc )); then note "services stopped ($1; teardown exit $rc, see $SCRATCH/teardown.out, at finish $STATE/teardown.out)"
  else note "services stopped ($1)"; fi
}
# shellcheck source=lib/notify.sh
source "$HARNESS_HOME/lib/notify.sh"; NOTIFY_TAG=$RUN_ID   # notify "<message>" [title=… body=… click=… …]: "[<run>] <message>"
# shellcheck source=lib/deploy.sh
source "$HARNESS_HOME/lib/deploy.sh"   # deploy_status: hosts that would build every pushed run branch
source "$HARNESS_HOME/lib/version.sh"  # harness_version: the harness commit driving this segment, and whether it is dirty
# shellcheck source=lib/record.sh
source "$HARNESS_HOME/lib/record.sh"   # record (the lock), commit_all, rec_commit, sync_record, slot_open, materialize …
green() { "$CHECK" > /dev/null 2>&1; }

# Revert what a session changed since <base> outside what it may change: "record" (the run record), "nothing", or
# "runs" (a lane may change anything but .harness/runs/: an added path is only un-indexed, the copy is still read).
# Its commits stay in history; a new commit puts the files back. Prints what it reverted.
restrict() {   # base record|nothing|runs who
  local base=$1 spec=(. ':!.harness/runs') st path
  [[ $2 == nothing ]] && spec=(.)
  [[ $2 == runs ]] && spec=(.harness/runs)
  commit_all "WIP: uncommitted at session end (harness)"
  while IFS=$'\t' read -r st path; do
    [[ -n $path ]] || continue
    if [[ $st == A ]]; then git rm -q --cached -- "$path" && { [[ $2 == runs ]] || rm -f -- "$path"; }; else git checkout -q "$base" -- "$path"; fi
    echo "$path"
  done < <(git diff --name-status --no-renames "$base" HEAD -- "${spec[@]}")
  commit_all "HARNESS: reverted edits a $3 session may not make"
}

[[ -z $BRANCH || $BRANCH == "$MAIN_BRANCH" ]] && { log "refusing to run on '${BRANCH:-detached HEAD}'"; exit 1; }
[[ -f $HARNESS_HOME/prompts/policy/$POLICY.md ]] || { log "unknown POLICY '$POLICY' (prompts/policy/*.md)"; exit 1; }

# `harness status` reads these: alive while driver.pid names a live process; why it ended in "ended".
echo $$ > "$STATE/driver.pid"; rm -f "$STATE/ended"
END_REASON="driver exited unexpectedly (see run.log)"
# A TERM runs this at once while the session goes on: its scope stops first, so claude can't work on unread meanwhile.
# It may now take minutes (the teardown): a second TERM/HUP (tmux closing) must not cut it short. Its note is committed
# (that file only, not pushed): a dirty worktree would keep gc from removing it
trap 'trap "" TERM INT HUP; [[ -n ${S_UNIT:-} ]] && scope_stop "$S_UNIT"; services_down "driver exited"; git -C "$RWT" commit -q -m "HARNESS: driver exited" -- "$REC/harness-log.md" > /dev/null 2>&1; echo "$END_REASON · $(date "+%F %T")" > "$STATE/ended"; rm -f "$STATE/driver.pid"' EXIT

# Bring main's new commits into the branch checked out here (a lane at its verify, so what is verified is what merges;
# the record branch at a resumed start, for its configuration). 1 = conflict (left as it was).
sync_main() {
  local b; b=$(git branch --show-current)
  git fetch -q origin "$MAIN_BRANCH" 2>/dev/null || return 0
  git merge-base --is-ancestor "origin/$MAIN_BRANCH" HEAD && return 0
  if git merge -q --no-edit "origin/$MAIN_BRANCH" > /dev/null 2>&1; then note "merged $MAIN_BRANCH into $b"; return 0; fi
  git merge --abort 2>/dev/null; note "$MAIN_BRANCH conflicts with $b; carrying on without it (merges into $MAIN_BRANCH need Michael)"
  return 1
}

# Answers typed locally (`harness answer`, the supervisor) are moved into INBOX.md so sessions see them.
take_answers_() {
  [[ -s $STATE/inbox.md ]] || return 0
  { echo; echo "### $(date '+%F %H:%M') (local)"; cat "$STATE/inbox.md"; } >> "$REC/INBOX.md"
  : > "$STATE/inbox.md"
  rec_commit "HARNESS: answers from Michael"
}
take_answers() { record take_answers_; }

# A milestone Michael must act on (verify, a conflict): high, one tap from the run-record file that explains it.
needs_you() {   # <milestone> <why> <file in the run record>
  notify "$1 needs Michael: $2" title="[$RUN_ID] $1 needs you" priority=high click="$(gh_url "$RUN_DIR/$3")"
  desk "$1 needs Michael: $2"
}

# DESK=1: a Remote Control session briefs Michael (lib/desk.sh). It never changes the run: a failure is a note.
# Its note is committed at once: left over, the retro's revert would drop it, or a session's "WIP" commit take it.
# 9>&-: no lock fd may reach a tmux server it starts.
desk() {
  [[ $DESK == 1 ]] || return 0
  "$HARNESS_HOME/bin/harness" desk "$RUN_ID" --why "$1" > /dev/null 2>&1 9>&- || note "desk: could not start (exit $?): $1"
  [[ -n $(git -C "$RWT" status --porcelain -- "$RUN_DIR") ]] && { rec_commit "HARNESS: desk"; sync_record; }
  return 0
}

# The park's notification: the question the session wrote in INBOX.md and how to answer, with the INBOX one tap away.
notify_park() {
  local id=$1 why=$2 q body acts
  q=$(cat "$STATE/question" 2> /dev/null)   # what take_question found in the session's copy (gone by now)
  body="PARKED: $why"$'\n\n'"${q:+$q$'\n\n'}Answer: harness answer $RUN_ID \"…\""
  acts=$(node "$NOTIFY_MJS" actions "Edit INBOX" "$(gh_url "$RUN_DIR/INBOX.md" edit)" "Answer with Claude" "$DESK_URL" Progress "$(gh_url "$RUN_DIR/progress.md")")
  notify "needs Michael: $id · $why" title="[$RUN_ID] $id needs you" priority=high tags=question click="$(gh_url "$RUN_DIR/INBOX.md")" actions="$acts" body="$body"
}

# What unparks a feature: Michael's answers changing (INBOX.md from "## Answers" on, local answers included).
answers_hash() { sed -n '/^## Answers/,$p' "$REC/INBOX.md" 2> /dev/null | sha1sum | cut -c1-12; }

control() {   # → run | pause | stop
  local s; s=$(sed -n 's/^status:[[:space:]]*//p' "$REC/INBOX.md" 2>/dev/null | head -1)
  if [[ -f $STATE/STOP || $s == stop* ]]; then echo stop
  elif [[ -f $STATE/PAUSE || $s == pause* ]]; then echo pause
  else echo run; fi
}

stop_why() {   # → "stopped by Michael[: <why>]": STOP's line (harness stop --why), else the text after control()'s `status: stop`
  local w s; w=$(head -1 "$STATE/STOP" 2> /dev/null)
  s=$(sed -n 's/^status:[[:space:]]*//p' "$REC/INBOX.md" 2> /dev/null | head -1 | tr -d '\r')
  [[ -z $w && $s =~ ^stop[^[:alnum:]]+([[:alnum:]](.*[^[:space:]])?) ]] && w=${BASH_REMATCH[1]}   # "stopped", "stop" or "stop -" give none
  echo "stopped by Michael${w:+: ${w:0:200}}"
}

demote_requests() {   # a stop after Michael queued a continuation of this run is his later word: that one turns automatic
  # the stop's time is when it reached this box (STOP, else INBOX.md pulled), not when the driver got to it: a request
  # queued after it stays requested
  local f at=$STATE/STOP; [[ -f $at ]] || at=$REC/INBOX.md
  for f in "$STATE_ROOT"/queue/*-continue-"$RUN_ID".args "$STATE_ROOT"/queue/h*/*-continue-"$RUN_ID".args; do   # queued, or parked there
    [[ -f $f && ! $f -nt $at ]] && grep -qx -- --requested "$f" || continue
    sed -i '/^--requested$/d' "$f" && note "stop: the queued continuation ${f##*/} is automatic now (the stop came after the request)"
  done
}

# One usage limit covers every run on the box: wait until the window that refused a session (any run's) is over.
limit_wait() {
  local upto now w; upto=$(cat "$LIMIT_FILE" 2>/dev/null || echo 0); now=$(date +%s)
  (( upto > now )) && [[ ! -f $STATE/waited-$upto ]] || return 0
  w=$(( upto - now )); (( w > DEADLINE - now )) && w=$(( DEADLINE - now )); (( w > 0 )) || return 0
  touch "$STATE/waited-$upto"
  (( w > SVC_IDLE_STOP_MIN * 60 )) && services_down "usage-limit wait"   # a short wait keeps them (decisions/2026-10-25-services-stop-points)
  note "usage-limit window (shared by all runs): waiting until $(date -d "@$upto" '+%H:%M') ($(( w / 60 )) min)"
  rec_commit "HARNESS: waiting for the usage limit"; sync_record
  sleep "${HARNESS_LIMIT_SLEEP:-$w}"
}

prompt() {   # template name → $STATE/prompt.md (lib/prompt.sh, which `harness eval probes` renders the same way)
  prompt_render "$1" > "$STATE/prompt.md"
  cp "$STATE/prompt.md" "$STATE/prompt-$1.md"   # the last prompt of each kind, for debugging
}

# <attempt N of M | verify round N of M> → the clock line of a coding or verify prompt ({{CLOCK}}): sessions can't tell
# time, budget or attempt otherwise. The run is this driver's segment (T0 to DEADLINE). decisions/2026-10-21-clock-and-bounded-init-output
clock() {
  local now el tot; now=$(date +%s); el=$(( (now - T0) / 60 )); tot=$(( (DEADLINE - T0) / 60 ))
  printf 'Clock: %s · run %dh%02dm of %s, ends %s · this session: $%s budget, %s turns, %s timeout · %s\n' "$(date '+%F %H:%M')" \
    $(( el / 60 )) $(( el % 60 )) "$( (( tot % 60 )) && printf '%dh%02dm' $(( tot / 60 )) $(( tot % 60 )) || echo "$(( tot / 60 ))h")" \
    "$(date -d "@$DEADLINE" +%H:%M)" "$SESSION_BUDGET_USD" "$MAX_TURNS" "$SESSION_TIMEOUT" "$1"
}

# kind model log who → runs claude headless on $STATE/prompt.md in its own capped scope (decisions/2026-10-25-scoped-sessions);
# sets S_EXIT, S_WALL, S_PEAK (MB, empty when uncapped) and S_NOTES (what the scope showed; noted here, except for the
# read-only retro, whose caller notes them after restrict, which would revert them)
session() {
  local settings=() mcp=(--strict-mcp-config) t0 seq unit left x
  t0=$(date +%s) S_NOTES=()
  # an entry.json no ingest took (the driver died after its session) would pass for this session's own
  [[ -e $RUN_DIR/entry.json ]] && { mv -f "$RUN_DIR/entry.json" "$STATE/entry-stale-$(date +%s).json"; note "an earlier session's entry.json moved aside before this $1 session"; }
  cp "$STATE/prompt.md" "${3%.jsonl}.prompt.md"   # each session's prompt beside its transcript, so two can be diffed (decisions/2026-10-21-static-first-prompts)
  [[ $1 == coding || $1 == verify ]] && cp "$RUN_DIR/context.md" "${3%.jsonl}.context.md" 2> /dev/null   # and the pack it read first
  [[ -f $AGENT_SETTINGS ]] && settings=(--settings "$WT/$AGENT_SETTINGS")
  # only the project's committed MCP servers, never the user's or another project's (decisions/2026-10-25-strict-mcp-and-deepequal-rule)
  [[ -f $WT/.mcp.json ]] && mcp+=(--mcp-config "$WT/.mcp.json")
  # s<n> is per run, never per segment: a crashed segment's scope may still hold its name
  seq=$(( $(cat "$STATE/scope-seq" 2> /dev/null || echo 0) + 1 )); echo "$seq" > "$STATE/scope-seq"; unit=$(scope_unit "$RUN_ID" "s$seq")
  # timeout inside the scope: outside it would signal the wrapper and leave claude running; -k: claude ignoring TERM
  S_UNIT=$unit   # the EXIT trap stops it when the driver dies mid-session
  scope_run "$unit" "$SESSION_MEMORY_HIGH" "$SESSION_MEMORY_MAX" timeout -k 30s "$SESSION_TIMEOUT" \
    "$CLAUDE" -p "$(cat "$STATE/prompt.md")" --model "$2" --permission-mode auto "${settings[@]}" "${mcp[@]}" \
    --max-turns "$MAX_TURNS" --max-budget-usd "$SESSION_BUDGET_USD" --output-format stream-json --verbose > "$3" 2>&1
  S_EXIT=$? S_WALL=$(( $(date +%s) - t0 ))
  # read what the wrapper recorded, then stop the scope: whatever the session left running goes with it
  S_PEAK=$(scope_peak "$unit") left=$(scope_left "$unit"); scope_stop "$unit"; S_UNIT=""
  (( left > 0 )) && S_NOTES+=("$1 session left $left process(es) running; stopped with its scope")
  [[ -n ${SCOPE_BARE:-} ]] && S_NOTES+=("$1 session ran uncapped: $SCOPE_BARE")   # its error is in the transcript
  # the peak alone could be page cache: a cap kill is the kernel's 137 with the peak at the cap
  (( S_EXIT == 137 )) && scope_capped "$unit" "$SESSION_MEMORY_MAX" && S_NOTES+=("${4:-$1}: the session hit its memory cap ($SESSION_MEMORY_MAX)")
  [[ $1 == retro ]] || for x in "${S_NOTES[@]}"; do note "$x"; done
  MET usage "$3" > "$USAGE.tmp" 2> /dev/null && mv "$USAGE.tmp" "$USAGE" || rm -f "$USAGE.tmp"   # the box-wide 7-day window
  log "  $1 exit $S_EXIT · $(git log --oneline -1)"
}

# <kind> <feature> <transcript> <model> <start commit> → the session's entry.json into entries.jsonl: the driver is its
# only writer (decisions/2026-10-22-journal-single-writer). Missing or invalid: a note and a minimal entry from git and
# the final message, whose outcome is what the list says now (the session's claim, before the driver's checks; a
# refused session's claim is reverted, so not yet). A session's own edits to the journal are undone first.
# Then progress.md and progress-archive.md are rendered from the journal (decisions/2026-10-22-rendered-progress).
journal() {
  local kind=$1 id=$2 who=$2 outcome="not yet" name out rc f; name=$(basename "$3" .jsonl)
  git -c core.quotePath=false diff --name-only --no-renames "$5" HEAD -- . ":!$RUN_DIR" > "$SCRATCH/entry-files"
  MET final "$3" > "$SCRATCH/entry-final" 2> /dev/null
  case $kind in   # the claim is the session's own list: the slot's copy in a lane (the flip comes after the checks)
    coding) if MET limit "$3" "$S_WALL" "$S_EXIT" > /dev/null; then :   # refused: the driver reverts its claim below
            elif F passes "$RUN_DIR/feature_list.json" "$id"; then outcome=passes
            elif sed -n 's/^[[:space:]*`>-]*PARKED:[[:space:]]*//p' "$SCRATCH/entry-final" | grep -q .; then outcome=parked; fi ;;
    verify) who="verify $id" ;;   # a verify without its entry has no evidence rows, so it never holds: not yet
    init)   F summary "$LIST" > /dev/null 2>&1 && outcome=passes ;;
  esac
  if [[ $PWD == "$RWT" ]]; then   # the initializer: committed by the WIP/restrict commit, so a diff from the start sees it
    for f in entries.jsonl progress-archive.md; do
      git diff --quiet "$5" -- "$RUN_DIR/$f" 2> /dev/null && continue
      if git cat-file -e "$5:$RUN_DIR/$f" 2> /dev/null; then git show "$5:$RUN_DIR/$f" > "$RUN_DIR/$f"; else rm -f "$RUN_DIR/$f"; fi
      note "$who: $f edited by the session; restored (the driver is its only writer)"
    done
  else   # a lane: the copy is discarded, so a session's edit to it never reaches the record; said all the same
    for f in entries.jsonl progress-archive.md; do
      [[ ! -e $RUN_DIR/$f && ! -e $REC/$f ]] || cmp -s "$RUN_DIR/$f" "$REC/$f" && continue
      note "$who: $f edited by the session; restored (the driver is its only writer)"
    done
    rm -f "$REC/entry.json"; [[ -e $RUN_DIR/entry.json ]] && mv -f "$RUN_DIR/entry.json" "$REC/entry.json"   # the take-back
  fi
  record journal_ "$who" "$kind" "$id" "$name" "$4" "$outcome"
  return 0
}
journal_() {   # who kind id name model outcome: the ingest and the render, in the record
  local out rc
  out=$(node "$HARNESS_HOME/lib/entries.mjs" ingest "$REC" "$2" "$3" "$4" "$5" "$6" "$SCRATCH/entry-files" "$SCRATCH/entry-final"); rc=$?
  (( rc == 3 )) && note "$1: entry.json $out; recorded a minimal entry"
  (( rc == 0 || rc == 3 )) || { note "$1: the journal append failed (exit $rc): $out"   # aside, so the next session's ingest can't take it
    mv -f "$REC/entry.json" "$STATE/entry-failed-$4.json" 2> /dev/null; }
  out=$(node "$HARNESS_HOME/lib/entries.mjs" render "$REC" 2>&1) || note "$1: rendering progress.md failed: $out"
  return 0
}

# <m> → how many verify entries the milestone has in entries.jsonl (the rendered progress.md shows only the 15 newest in
# full). A run with a list always has the file by its first verify: the start-up or the initializer's append creates it
vcount() {
  jq -cR --arg m "$1" 'fromjson? | objects | select(.kind == "verify" and .feature == $m)' "$REC/entries.jsonl" 2> /dev/null | wc -l
}

# <feature or milestone> → <run>/context.md, the bounded pack of the journal the next coding or verify session reads first
# (lib/entries.mjs pack, at most CONTEXT_PACK_BYTES; decisions/2026-10-22-context-pack). Committed with the run record
# on the record branch; materialize copies it into the slot.
context_() {
  if node "$HARNESS_HOME/lib/entries.mjs" pack "$REC" "$1" "$CONTEXT_PACK_BYTES" > "$SCRATCH/context.md" 2> "$SCRATCH/context.err"; then
    mv -f "$SCRATCH/context.md" "$REC/context.md"
    note "context.md for $1: $(wc -c < "$REC/context.md") bytes$(sed -n 's/^_\([0-9]*\) items left out at .*/, \1 items left out/p' "$REC/context.md")"
  else   # never a stale pack: the session is sent to the full record instead
    printf '# Context pack for `%s`\n\nThe harness could not build it this time; read entries.jsonl / progress-archive.md.\n' "$1" > "$REC/context.md"
    note "context.md for $1: the pack failed ($(head -c 200 "$SCRATCH/context.err" | tr '\n' ' ')); it points at the full record"
  fi
  # committed now, alone: anything else uncommitted in the record stays for its own commit (E4 review F4)
  git -C "$RWT" add -- "$RUN_DIR/context.md" && { git -C "$RWT" diff --cached --quiet -- "$RUN_DIR/context.md" || git -C "$RWT" commit -q -m "HARNESS: context pack for $1" -- "$RUN_DIR/context.md"; }
}
context() { record context_ "$1"; }

# The project's init, then the suite (cached per code tree); both go into the next prompt. The init runs in
# harness-<run>-svc (decisions/2026-10-25-services-scope): what it backgrounds (a dev server) stays there, capped at
# SVC_MEMORY_MAX. timeout bounds the init, not the servers it left once it returned (a timeout takes its process group
# too); stdin is /dev/null, so no tool waits on the tmux pane. The last init's scope is stopped first: systemd refuses
# a unit name still loaded (tests/fixtures/systemd-run-unit-exists.txt), and its services would live on beside the new.
run_init() {   # [fresh: clear the suite cache's marker for the tree as the init left it, so the suite runs in full]
  local unit; unit=$(scope_unit "$RUN_ID" svc)
  scope_stop "$unit"
  SVC_UP=1 SVC_INIT=1 SVC_DIR=$PWD   # before the start: a TERM during the init must still stop what it began (services_down, L2-03)
  HARNESS_PORT=$PORT HARNESS_SCRATCH=$SCRATCH scope_run "$unit" "" "$SVC_MEMORY_MAX" timeout -k 10s "$INIT_TIMEOUT" bash -c "$INIT_CMD" < /dev/null > "$SCRATCH/init.out" 2>&1
  local rc=$?; SVC_INIT=0; echo "(init exit $rc)" >> "$SCRATCH/init.out"
  [[ -n ${SCOPE_BARE:-} ]] && note "init ran uncapped: $SCOPE_BARE"   # systemd refused the unit; its line is in init.out
  (( rc == 0 )) || log "  init exit $rc (the session is told to fix it first)"
  [[ ${1:-} == fresh ]] && rm -f "$STATE/green/green-$(node "$HARNESS_HOME/lib/treekey.mjs")"
  "$CHECK" >> "$SCRATCH/init.out" 2>&1 || log "  suite red before the session (the session is told to fix it first)"
  [[ -f $STATE/tests-start ]] || node "$HARNESS_HOME/lib/testcount.mjs" "$SCRATCH/check.out" | cut -d' ' -f1 | grep . > "$STATE/tests-start" \
    || rm -f "$STATE/tests-start"
  # once per run: a suite whose output has no count leaves the report's tests at `?` (a cached green wrote no check.out)
  if [[ -f $SCRATCH/check.out && ! -f $STATE/testcount-nomatch && -z $(node "$HARNESS_HOME/lib/testcount.mjs" "$SCRATCH/check.out") ]]; then
    note "test count: no match in the suite's output (tests start/end stay unknown)"; touch "$STATE/testcount-nomatch"
  fi
}

pr_body() {   # milestone → the evidence a reviewer (or the record) needs; the archive has every entry in full
  local p=$REC/progress-archive.md; [[ -f $p ]] || p=$REC/progress.md
  echo "Milestone **$1** of harness run \`$RUN_ID\` (lane \`harness-lane/$RUN_ID/$1\`), verified by an independent session."
  echo; echo "**Features:**"; for id in $(F ids "$LIST" "$1"); do echo "- \`$id\` · $(jq -r --arg id "$id" '.features[]|select(.id==$id)|.description' "$LIST" 2>/dev/null)"; done
  echo; echo "**Run so far:** $(F summary "$LIST") · $(MET summary "$REC/metrics.jsonl")"
  echo; echo "**Verify entry:**"; echo
  # `verify M1` followed by anything but a letter, digit, _ or - (M1 never matches M10; a legacy `verify M1: …` does)
  awk -v m="verify $1" 'index($0, "### ") == 1 { if (on) exit; i = index($0, m); if (i && substr($0, i + length(m), 1) !~ /[[:alnum:]_-]/) on = 1 } on' "$p" | head -60
  echo; echo "Run record: \`$RUN_DIR/\` on branch \`$RBRANCH\` (progress.md, harness-log.md, feature_list.json, metrics.jsonl)."
}

# Merge one verified milestone (its tag, the lane tip) into main through a PR. The invariant: the tree that lands on
# main is the tree that was verified. 0 = merged, proposed, or (--open) its PR open and waiting · 1 = needs Michael
# (conflict, refusal, or main moved since the verify: D1 until lanes re-base, decisions/2026-10-26-lanes)
merge_one() {
  local m=$1 tag=run/$RUN_ID/$1 c head url tree mn
  head=harness-merge/$RUN_ID-$m
  c=$(git rev-list -n1 "$tag") || return 1
  git fetch -q origin "$MAIN_BRANCH" || return 1
  if git merge-base --is-ancestor "$c" "origin/$MAIN_BRANCH"; then touch "$STATE/merged-$m"; note "$m merged into $MAIN_BRANCH (already there)"; return 0; fi
  mn=$(git rev-parse "origin/$MAIN_BRANCH")
  if ! tree=$(git merge-tree --write-tree "origin/$MAIN_BRANCH" "$c" 2>/dev/null | head -1); then
    # once per main: merge_milestones runs again after every verify and at the end
    [[ $(cat "$STATE/conflict-$m" 2>/dev/null) == "$mn" ]] && return 1
    echo "$mn" > "$STATE/conflict-$m"
    note "$m conflicts with $MAIN_BRANCH; not merged (needs Michael)"; rec_commit "HARNESS: $m conflicts with $MAIN_BRANCH"; sync_record
    needs_you "$m" "conflicts with $MAIN_BRANCH" harness-log.md; return 1
  fi
  if [[ $tree != "$(git rev-parse "$c^{tree}")" ]]; then   # main has content the lane wasn't verified with
    [[ $(cat "$STATE/moved-$m" 2>/dev/null) == "$mn" ]] && return 1
    echo "$mn" > "$STATE/moved-$m"
    note "$m verified, but $MAIN_BRANCH moved since; not merged (needs Michael)"; rec_commit "HARNESS: $m waits on $MAIN_BRANCH"; sync_record
    needs_you "$m" "$MAIN_BRANCH moved since its verify" harness-log.md; return 1
  fi
  git push -q -f origin "$c:refs/heads/$head" 2>> "$STATE/run.log" || { note "$m: push of $head failed (see run.log)"; return 1; }
  pr_body "$m" > "$STATE/pr-body.md"
  url=$($GH pr view "$head" --json url,state -q 'select(.state=="OPEN") | .url' 2>/dev/null) || url=""
  [[ $url == http* ]] || url=$($GH pr create --base "$MAIN_BRANCH" --head "$head" --title "$RUN_ID: $m (verified)" --body-file "$STATE/pr-body.md" 2>> "$STATE/run.log" | tail -1)
  [[ $url == http* ]] || { note "$m: could not open its PR (see run.log)"; return 1; }
  if [[ $MERGE_POLICY != auto && ! ${HARNESS_MERGE_ONLY:-} ]]; then touch "$STATE/proposed-$m"; note "$m proposed for merging · $url"; notify "$m verified · review: $url" title="[$RUN_ID] $m ready to merge" click="$url"; return 0; fi   # harness merge lands it whatever the policy
  [[ ${2:-} == --open ]] && return 0   # a dependency hasn't merged: the PR waits for it
  if $GH pr merge "$url" --merge --match-head-commit "$c" > /dev/null 2>> "$STATE/run.log"; then
    git push -q origin --delete "$head" 2>/dev/null
    touch "$STATE/merged-$m"; note "$m merged into $MAIN_BRANCH · $url"; notify "$m merged · $url" click="$url"
  else
    # once per tag commit (merge_milestones runs again after every verify and at the end); `harness merge` always says so
    [[ ! ${HARNESS_MERGE_ONLY:-} && $(cat "$STATE/refused-$m" 2>/dev/null) == "$c" ]] && return 1
    echo "$c" > "$STATE/refused-$m"
    note "$m: the merge was refused; PR left open for Michael · $url"; notify "$m needs Michael: merge refused · $url" title="[$RUN_ID] $m needs you" priority=high click="$url"
    [[ ${HARNESS_MERGE_ONLY:-} ]] || desk "$m: merge refused"   # `harness merge`: Michael is at the terminal
    return 1
  fi
}

# [<m>] → merge every verified, unmerged milestone (or just <m>) in list order. A tag is a lane tip, so it carries no
# other milestone's unverified work: each merges on its own once every milestone it depends on (F deps) has merged;
# until then its PR is opened and waits (noted once). v2 tags (verified under weaker rules) merge only through
# `harness merge`. Nothing under MERGE_POLICY=off.
merge_milestones() {
  [[ $MERGE_POLICY == off || ! -f $LIST ]] && return 0
  local m d wait
  for m in $(F milestones "$LIST"); do
    [[ -n ${1:-} && $m != "$1" ]] && continue
    [[ -f $STATE/merged-$m || -f $STATE/proposed-$m ]] && continue
    git rev-parse -q --verify "refs/tags/run/$RUN_ID/$m" > /dev/null || continue
    if [[ ! ${HARNESS_MERGE_ONLY:-} ]] && ! git tag -l --format='%(contents:subject)' "run/$RUN_ID/$m" | grep -q '(v3'; then
      [[ -f $STATE/legacy-noted ]] || { touch "$STATE/legacy-noted"; note "$m was verified by harness v2; it merges only with: harness merge $RUN_ID"; }
      continue
    fi
    wait=""; for d in $(F deps "$LIST" "$m"); do [[ -f $STATE/merged-$d ]] || wait+="${wait:+, }$d"; done
    if [[ -n $wait ]]; then
      merge_one "$m" --open && [[ ! -f $STATE/waits-$m && ! -f $STATE/proposed-$m ]] && { touch "$STATE/waits-$m"; note "$m verified; its PR waits for $wait to merge"; }
      continue
    fi
    merge_one "$m"
  done
  return 0
}

# Independently re-check milestone m, in its lane. 0 = verified (tagged) · 1 = not verified · 2 = deferred (a usage
# limit: retry). `once` (at the deadline): one session, no escalation, and this round is the last
# (decisions/2026-10-26-verify-before-deadline). The session reads a copy of the record; what it un-passes in it is
# applied to the record's list afterwards.
verify() {
  local m=$1 out vlog rounds model short before vstart reverted result=fail need="" failed=() maxr=$MAX_VERIFY_ROUNDS id
  local models=("$VERIFY_MODEL" "$VERIFY_ESCALATE_MODEL") last=$VERIFY_ESCALATE_MODEL
  rounds=$(( $(cat "$STATE/verify-rounds-$m" 2>/dev/null || echo 0) + 1 ))
  [[ ${2:-} == once ]] && { models=("$VERIFY_MODEL"); maxr=$rounds last="one verify at the deadline"; }
  slot_open "$m" || { rec_cd; return 1; }
  sync_main || touch "$STATE/nomerge-$m"
  sync_lane
  # the verified tree's suite runs in full: a session can leave a stale green marker (decisions/2026-10-26-verify-runs-the-suite)
  note "verify $m: suite cache cleared; the suite runs in full on the verified tree"
  run_init fresh
  for model in "${models[@]}"; do
    context "$m"   # each round: an escalated verify's pack has the first round's entry
    materialize
    before=$(vcount "$m"); vstart=$(git rev-parse HEAD)
    mem_gate || run_init   # before the clock, so the prompt's time is the session's; a wait stopped the services
    HARNESS_CLOCK=$(clock "verify round $rounds of $maxr") HARNESS_MILESTONE=$m HARNESS_FEATURES=$(F ids "$LIST" "$m" | paste -sd' ') prompt verify
    vlog="$LOGS/$(date +%H%M%S)-verify-$m.jsonl"
    log "verify $m · $(F model "$model")"
    session verify "$(F model "$model")" "$vlog" "verify $m"
    reverted=$(restrict "$vstart" record verify | paste -sd' ')
    [[ -n $reverted ]] && note "verify $m: reverted code edits the verifier may not make: $reverted"
    journal verify "$m" "$vlog" "$(F model "$model")" "$vstart"   # before the limit branch: a refused verify is journaled too
    lane_guard "$vstart" "verify $m"; sync_lane
    rec_commit "HARNESS: journal verify $m"
    if why=$(MET limit "$vlog" "$S_WALL" "$S_EXIT"); then   # refused: no verdict, and nothing reached the record's list
      unmaterialize; rec_cd
      record MET append "$vlog" "$REC/metrics.jsonl" "$RUN_ID" verify "$m" "$(F model "$model")" false "$S_WALL" "$S_EXIT" true verify "$S_PEAK"
      local upto; upto=$(( ${why##*$'\t'} > 0 ? ${why##*$'\t'} + 120 : $(date +%s) + 900 ))
      (( upto > $(cat "$LIMIT_FILE" 2>/dev/null || echo 0) )) && echo "$upto" > "$LIMIT_FILE"
      note "verify $m refused (${why%%$'\t'*}); deferred until $(date -d "@$upto" '+%H:%M')"
      rec_commit "HARNESS: verify $m deferred"; sync_record; return 2
    fi
    out=$(F repair-verify "$SLIST" "$STATE/before.json" "$m") || note "verify $m: reverted list edits beyond un-passing: $out"
    for id in $(F ids "$LIST" "$m"); do F passes "$SLIST" "$id" || record F unpass "$LIST" "$id"; done   # the verdict, on the record
    unmaterialize
    record MET append "$vlog" "$REC/metrics.jsonl" "$RUN_ID" verify "$m" "$(F model "$model")" \
      "$(F milestone-done "$LIST" "$m" && echo true || echo false)" "$S_WALL" "$S_EXIT" false verify "$S_PEAK"
    F milestone-done "$LIST" "$m" || { result=fail; break; }
    if (( $(vcount "$m") <= before )); then short="no new verify entry"
    elif short=$(F evidence "$LIST" "$m" "$REC/progress.md"); then result=hold; break; fi
    [[ $model == "${models[-1]}" ]] && { result=thin; break; }   # the last model (the only one in once mode)
    note "verify $m: evidence short of the steps ($short); re-running on $VERIFY_ESCALATE_MODEL"
  done
  echo "$rounds" > "$STATE/verify-rounds-$m"
  if [[ $result == hold ]] && ! green; then result=red; fi   # on the slot's tree, the one tagged below
  case $result in
    hold)
      touch "$STATE/verified-$m"
      git tag -a "run/$RUN_ID/$m" -m "harness run $RUN_ID: $m verified (v3)" 2>/dev/null \
        && git push -q origin "run/$RUN_ID/$m" 2>> "$STATE/run.log"
      rec_cd
      note "$m verified and tagged run/$RUN_ID/$m"
      rec_commit "HARNESS: $m verified"; sync_record
      [[ -f $STATE/nomerge-$m ]] || merge_milestones "$m"
      return 0 ;;
    thin) touch "$STATE/needs-$m"; note "verify $m: evidence still short of the steps ($short) after $last; not verified (needs Michael)"
      need="verify evidence too thin" ;;
    red) touch "$STATE/needs-$m"; note "verify $m: the suite is red on the verified tree (main merged in); not verified (needs Michael)"
      need="suite red after merging main" ;;
    fail)
      for id in $(F ids "$LIST" "$m"); do
        F passes "$LIST" "$id" && continue
        if (( rounds < maxr )); then
          note "verify $m: $id failed the re-check, back in the queue (one more attempt)"; record F grant "$ATT" "$id" "$MAX_ATTEMPTS"
        else
          touch "$STATE/needs-$m"; note "verify $m: $id failed the re-check in round $rounds of $maxr; $m needs Michael (see progress.md)"
          failed+=("$id")
        fi
      done
      if (( ${#failed[@]} == 1 )); then need="${failed[0]} fails verification"
      elif (( ${#failed[@]} )); then need=$(printf '%s, ' "${failed[@]}"); need="${need%, } fail verification"; fi ;;
  esac
  rec_cd
  rec_commit "HARNESS: verify $m"; sync_record
  [[ -n $need ]] && needs_you "$m" "$need" progress.md   # after the push: the click shows the verify entry
  return 1
}

# The deadline's verify (decisions/2026-10-26-verify-before-deadline): verify_ready once, unless a stop came first or a
# usage-limit window holds, when its session would only be refused (the next segment verifies first thing)
deadline_verify() {
  local m ms="" upto
  for m in $(F milestones "$LIST"); do
    [[ -f $STATE/verified-$m || -f $STATE/needs-$m ]] || ! F milestone-done "$LIST" "$m" || ms+="${ms:+, }$m"
  done
  [[ -n $ms ]] || return 0
  upto=$(cat "$LIMIT_FILE" 2>/dev/null || echo 0)
  if [[ $(control) == stop ]]; then note "deadline reached: $ms complete but unverified; stopped by Michael, so no verify before the end"
  elif (( upto > $(date +%s) )); then note "deadline reached: $ms complete but unverified; the usage limit holds until $(date -d "@$upto" +%H:%M), so no verify before the end"
  else verify_ready once; fi
}

# Verify every milestone that is complete, not yet verified and whose lane can open (F lanes: its dependencies are
# verified), in order. 2 = a verify was deferred by a limit. `once`: the deadline's last look, one session per milestone
verify_ready() {
  local m rc
  for m in $(F lanes "$LIST" "$ATT" "$MAX_ATTEMPTS" "$PARKED" "$STATE" | cut -f1); do
    [[ $m != default ]] && F milestone-done "$LIST" "$m" || continue
    [[ ${1:-} == once ]] && note "deadline reached: $m complete but unverified; one verify before the end"
    verify "$m" "${1:-}"; rc=$?
    (( rc == 2 )) && return 2
  done
  return 0
}

retro() {   # a short read-only session that turns this run's evidence into proposed harness changes
  local rlog=$LOGS/zz-retro-$(date +%H%M%S).jsonl rstart reverted x
  rstart=$(git rev-parse HEAD)
  HARNESS_SUMMARY=$REC/summary.json HARNESS_STATE=$STATE HARNESS_LEDGER=$LEDGER HARNESS_END_REASON=$END_REASON prompt retro
  log "retro · $(F model "$RETRO_MODEL")"
  MAX_TURNS=40 SESSION_BUDGET_USD=3 session retro "$(F model "$RETRO_MODEL")" "$rlog" retro
  reverted=$(restrict "$rstart" nothing retro | paste -sd' ')
  for x in "${S_NOTES[@]}"; do note "$x"; done   # after restrict: the driver's notes, not the retro's edits
  [[ -n $reverted ]] && note "retro: reverted edits (it is read-only): $reverted"
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
    if [[ $LEDGER_COMMIT == 1 ]] && git -C "$LEDGER" rev-parse --show-toplevel > /dev/null 2>&1; then
      git -C "$LEDGER" add -- "$d" "$LEDGER/runs.jsonl" \
        && git -C "$LEDGER" commit -q -m "ledger: $RUN_ID ($PROJECT_NAME): $(F summary "$LIST")" -- "$d" "$LEDGER/runs.jsonl" \
        || log "ledger commit skipped"
    fi
  ) 9> "$STATE_ROOT/ledger.lock"
}

finish() {   # reason → summary, notification, retro, ledger, continuation
  END_REASON=$1
  unmaterialize; rec_cd   # it may end mid-step in a lane (a cap, feature-list edits)
  echo "$1 · $(date '+%F %T')" > "$STATE/ended"   # now, not at exit: the summary reads it
  note "run ended ($1): $(F summary "$LIST" 2>/dev/null) · $(MET summary "$REC/metrics.jsonl")"
  merge_milestones
  # the tree's count (the slot's, the last lane's code, if one opened): its green marker's (a continued segment's
  # scratch has no output of a tree cached green), else its output's
  local key n dir=$RWT; [[ -n $SLOT && -d $SLOT ]] && dir=$SLOT
  key=$(cd "$dir" && { green; node "$HARNESS_HOME/lib/treekey.mjs"; })
  n=$(cat "$STATE/green/green-$key" 2> /dev/null); [[ -n $n ]] || n=$(node "$HARNESS_HOME/lib/testcount.mjs" "$SCRATCH/check-$key.out")
  if [[ -n $n ]]; then echo "${n%% *}" > "$STATE/tests-end"; else rm -f "$STATE/tests-end"; fi
  services_down "$1"   # after the last suite run, which may need them
  slot_close   # its branch is pushed; a merged lane's branch goes
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
commit_all "HARNESS: start run $RUN_ID"
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
  commit_all "HARNESS: merge"; sync_record; END_REASON="merge only"; exit 0
fi

# A run from before the journal (a feature list, no entries.jsonl): its progress.md is kept, byte for byte, as
# progress-archive.md and the journal starts here (decisions/2026-10-22-rendered-progress). Nothing is rendered until
# the first entry, so progress.md stays as it was until a session ends; `harness merge` exited above, untouched.
if [[ -f $LIST && ! -f $REC/entries.jsonl ]]; then
  : > "$REC/entries.jsonl"
  if [[ -f $REC/progress.md ]]; then cp "$REC/progress.md" "$REC/progress-archive.md"
    note "journal started; progress.md kept as progress-archive.md"
  else note "journal started (no progress.md to keep)"; fi   # then the default header, and no legacy part
  commit_all "HARNESS: journal started"; sync_record
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
  commit_all "HARNESS: initializer done"; sync_record
  notify "started: $(F summary "$LIST")" click="$(gh_url "$RUN_DIR/progress.md")"
fi

if [[ ! -f $STATE/deps-noted ]]; then   # once per run: milestones that wait on everything before them
  u=$(F undeclared "$LIST")
  [[ -n $u ]] && note "dependencies: $u $( [[ $u == *,* ]] && echo have || echo has) no after list, so $( [[ $u == *,* ]] && echo each waits || echo it waits) on every earlier feature (one given up or parked there stops it)"
  touch "$STATE/deps-noted"
fi
[[ $MAX_SESSIONS == auto ]] && MAX_SESSIONS=$(( 3 * $(jq '.features | length' "$LIST") + 5 ))
repairs=0 gated=0
while :; do
  rec_cd
  (( $(cat "$STATE/sessions") >= MAX_SESSIONS )) && finish "session cap ($MAX_SESSIONS)"
  (( $(date +%s) >= DEADLINE )) && { note "deadline reached"; deadline_verify; finish "deadline"; }
  take_answers; sync_record
  for id in $(F unpark "$PARKED" "$(answers_hash)"); do note "$id unparked: INBOX.md has new answers"; done
  c=$(control)
  if [[ $c == pause ]]; then
    log "paused (INBOX.md status or harness pause)"; notify "paused"
    services_down paused; rec_commit "HARNESS: paused"; sync_record   # nothing else commits during a pause: the note reaches the phone now
    while [[ $(control) == pause ]]; do
      (( $(date +%s) >= DEADLINE )) && { note "deadline reached while paused"; deadline_verify; finish "deadline (paused)"; }
      sleep "${HARNESS_PAUSE_POLL:-60}"; take_answers; sync_record
    done
    log "resumed"; continue
  fi
  [[ $c == stop ]] && { demote_requests; why=$(stop_why); note "$why"; finish "$why"; }
  limit_wait
  (( $(date +%s) >= DEADLINE )) && continue
  if why=$(weekly_over "$USAGE"); then note "stopping before the next session: $why"; finish "weekly budget ($why)"; fi

  # one lane at a time (MAX_LANES=1): the first milestone that can open (F lanes: its dependencies verified) and is
  # complete gets its verify, else its next feature runs in it
  next="" vm=""
  while IFS=$'\t' read -r m _; do
    [[ -n $m ]] || continue
    [[ $m != default ]] && F milestone-done "$LIST" "$m" && { vm=$m; break; }
    next=$(F next "$LIST" "$ATT" "$MAX_ATTEMPTS" "$PARKED" "$m"); [[ -n $next ]] && break
  done < <(F lanes "$LIST" "$ATT" "$MAX_ATTEMPTS" "$PARKED" "$STATE")
  if [[ -n $vm ]]; then verify "$vm"; continue; fi   # 2 = deferred by a usage limit: the window is waited for first
  if [[ -z $next ]]; then
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
  IFS=$'\t' read -r id mdl milestone <<< "$next"
  # the memory gate before the attempt and its prompt; after a wait, the checks above (deadline, stop, pause, the pick)
  # run again, and the gate doesn't: once is enough, then the session starts anyway (decisions/2026-10-25-memory-gate)
  if (( ! gated )) && ! mem_gate; then gated=1; continue; fi; gated=0
  slot_open "${milestone:-default}" || continue   # its base conflicts: needs Michael, noted
  n=$(rec_count "$STATE/sessions" 1)
  record F bump "$ATT" "$id"
  run_init; context "$id"; materialize   # the copy, the snapshot and the INBOX the session is judged against
  HARNESS_CLOCK=$(clock "attempt $(jq -r --arg id "$id" '.[$id] // 0' "$ATT") of $MAX_ATTEMPTS") HARNESS_FEATURE=$id HARNESS_MILESTONE=$milestone prompt coding
  log "session $n · $id · $mdl"
  slog="$LOGS/$(printf '%02d' "$n")-$id.jsonl"
  sstart=$(git rev-parse HEAD)
  session coding "$mdl" "$slog" "$id"
  commit_all "WIP: $id — uncommitted at session end (harness)"; sync_lane   # the copy is excluded: code only
  journal coding "$id" "$slog" "$mdl" "$sstart"   # before the limit branch and F repair: every session is journaled
  take_question   # what it asked above ## Answers, into the record's INBOX.md
  lane_guard "$sstart" "$id"

  # A usage/rate limit, an API error or a session that did no work is not the feature's fault: give the attempt back.
  # Its work stays (committed above); its claims never reach the record (the copy goes).
  if why=$(MET limit "$slog" "$S_WALL" "$S_EXIT"); then
    IFS=$'\t' read -r reason reset <<< "$why"
    unmaterialize; rec_cd
    record F unbump "$ATT" "$id"; rec_count "$STATE/sessions" -1 > /dev/null; limits=$(rec_count "$STATE/limits" 1)
    record MET append "$slog" "$REC/metrics.jsonl" "$RUN_ID" coding "$id" "$mdl" false "$S_WALL" "$S_EXIT" true "" "$S_PEAK"
    if (( limits >= MAX_LIMIT_HITS )); then
      note "$limits sessions in a row refused ($reason)"
      finish "usage limit ($limits sessions refused in a row)"
    fi
    read -ra waits <<< "$LIMIT_WAITS"; w=${waits[$(( limits > ${#waits[@]} ? ${#waits[@]} - 1 : limits - 1 ))]}
    upto=$(( ${reset:-0} > 0 ? reset + 120 : $(date +%s) + w ))
    (( upto > $(cat "$LIMIT_FILE" 2>/dev/null || echo 0) )) && echo "$upto" > "$LIMIT_FILE"
    (( limits == 1 )) && notify "refused ($reason); waiting until $(date -d "@$upto" '+%H:%M')"
    note "session for $id hit a limit ($reason); not counted; resuming at $(date -d "@$upto" '+%H:%M')"
    rec_commit "HARNESS: usage limit"; sync_record
    continue
  fi
  echo 0 > "$STATE/limits"

  # the driver's checks act on the session's copy; only the flip reaches the record's list
  if out=$(F repair "$SLIST" "$STATE/before.json" "$id"); then repairs=0; else
    repairs=$(( repairs + 1 )); note "restored the feature list after $id: $out"
    (( repairs >= MAX_REPAIRS )) && { note "$repairs sessions in a row edited the feature list; stopping for Michael"; finish "feature-list edits"; }
  fi
  if F passes "$SLIST" "$id" && ! green; then F unpass "$SLIST" "$id"; note "$id un-passed: suite red after the session"; fi
  passed=$(F passes "$SLIST" "$id" && echo true || echo false)
  unmaterialize; rec_cd
  if [[ $passed == true ]]; then record F pass "$LIST" "$id"; else record F unpass "$LIST" "$id"; fi
  record MET append "$slog" "$REC/metrics.jsonl" "$RUN_ID" coding "$id" "$mdl" "$passed" "$S_WALL" "$S_EXIT" false "$(F kind "$LIST" "$id")" "$S_PEAK"
  note "$id · $mdl · passes=$passed · $(( S_WALL / 60 )) min · $(F summary "$LIST")"
  if [[ $passed == false ]] && why=$(MET final "$slog" | sed -n 's/^[[:space:]*`>-]*PARKED:[[:space:]]*//p' | head -1) && [[ -n $why ]]; then
    record F unbump "$ATT" "$id"; record F park "$PARKED" "$id" "$(answers_hash)" "$why"   # waiting on Michael is not the feature's fault
    note "$id parked (waiting on Michael): $why"
  else why=""; fi
  rec_commit "HARNESS: after $id (passes=$passed)"; sync_record
  if [[ -n $why ]]; then   # after the push, so its links show the question; a failed post's note is committed too
    notify_park "$id" "$why"; [[ -n $(git status --porcelain -- "$RUN_DIR") ]] && { rec_commit "HARNESS: park notification failed"; sync_record; }
    desk "$id parked: $why"
  fi

done
