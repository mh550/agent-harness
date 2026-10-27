#!/usr/bin/env bash
# Usage: source lib/record.sh; run_paths   (by lib/driver.sh, the coordinator, and lib/lane.sh, one per open milestone)
# The run record and everything both processes share (lanes P1-03, P1-04). The record (.harness/runs/<run>/) lives only
# on harness/<run>, in the record worktree RWT; code lives on lane branches harness-lane/<run>/<m>, worked in slot
# worktrees. Every write to the record goes through `record` (one flock on $STATE/record.lock, so two writers never lose
# each other's lines); sessions, inits and suites never run under it. A session sees the record as a copy materialized
# into its slot, excluded from git there, and taken back after it.
# Plan: docs/plans/2026-10-26-P1-lanes-serial.md §2, §5, §6. Needs WT (the record worktree, the cwd) RUN_ID STATE
# PROJECT_DIR HARNESS_HOME, and config.sh, prompt.sh, scope.sh and notify.sh sourced.

# The spec's helper: the lock is held while "$@" runs and released when fd 9 closes. HARNESS_RECORD_DELAY=<s> (tests
# only, unset everywhere else) holds it that long first, so a check can make two writers meet.
_record() { flock 9; [[ -n ${HARNESS_RECORD_DELAY:-} ]] && sleep "$HARNESS_RECORD_DELAY"; "$@"; } 9> "$STATE/record.lock"
# A wrapped function may call another (note inside a commit): the inner call runs under the lock it already holds,
# never a second flock on a new descriptor, which would wait on itself.
record() { (( ${REC_HELD:-0} )) && { "$@"; return; }; REC_HELD=1; _record "$@"; local rc=$?; REC_HELD=0; return $rc; }

commit_all() { git add -A && ! git diff --cached --quiet && git commit -q -m "$1"; return 0; }
rec_commit_() { ( cd "$RWT" && commit_all "$1" ); }
rec_commit() { record rec_commit_ "$1"; }   # <message>: a commit of the record worktree

# <file> [<delta>] → the run counter in <file> (sessions: coding sessions started, limits: refused in a row) plus delta
rec_count_() { local n; n=$(cat "$1" 2> /dev/null || echo 0); echo $(( n + ${2:-0} )) > "$1"; }
rec_count() { record rec_count_ "$1" "${2:-0}"; cat "$1"; }


# The run's paths and configuration, read in the record worktree (cwd). A lane then moves to its slot (lane_paths).
run_paths() {
  prompt_vars   # PROJECT_NAME BRANCH RUN_DIR SCRATCH CHECK PORT
  # the record worktree and branch, the record itself (absolute), the slots' parent; a lane's slot and branch come later
  RWT=$WT RBRANCH=$BRANCH REC=$WT/$RUN_DIR WT_ROOT_DIR=${WT%/*} SLOT="" LBRANCH="" LANE="" LANEU="" LDIR=""
  CLAUDE=${HARNESS_CLAUDE:-claude} GH=${HARNESS_GH:-gh}
  LIST=$REC/feature_list.json SLIST=$REC/feature_list.json
  LOGS=$STATE/logs ATT=$STATE/attempts.json PARKED=$STATE/parked.json LS=$STATE
  STATE_ROOT=$(cd "$STATE/../.." && pwd); LIMIT_FILE=$STATE_ROOT/LIMIT_UNTIL USAGE=$STATE_ROOT/USAGE_7D
  LEDGER=${HARNESS_LEDGER:-$HARNESS_HOME/ledger} SVC_UNIT=$(scope_unit "$RUN_ID" svc)
  mkdir -p "$LOGS" "$REC" "$SCRATCH"
  load_config
}
F() { node "$HARNESS_HOME/lib/features.mjs" "$@"; }
MET() { node "$HARNESS_HOME/lib/metrics.mjs" "$@"; }
SUM() { node "$HARNESS_HOME/lib/summary.mjs" "$@"; }
# The configuration comes from the worktree, so it is loaded again after a resumed run merges main (which may have
# changed .harness/config.sh, e.g. a new POLICY).
load_config() {
  harness_config "$WT" "$STATE"
  prompt_env   # the exports every session and template sees (lib/prompt.sh)
}

log() { echo "$(date '+%F %T') $*" | tee -a "$STATE/run.log"; }
note_() { echo "- $(date '+%F %H:%M') · $*" >> "$REC/harness-log.md"; }
note() { log "$*"; record note_ "$*"; }   # phone-readable, committed with the record
# <why>: the project's teardown, then the services scope, then one note (decisions/2026-10-25-teardown-hook). Only after
# an init started something (SVC_UP): finish's call and the EXIT trap's after it give one note, and a segment that never
# ran an init is silent. SVC_UP clears after the stop, so a TERM during a teardown still stops the scope; the hook runs
# in the background (SVC_TD) so the trap, which bash runs at once, waits for it instead of starting a second. A TERM
# during an init (SVC_INIT) stops the init first, or it would start what the hook just stopped (L2-06 review).
# SVC_UNIT is the run's harness-<run>-svc, a lane's harness-<run>-<m>-svc; a lane's services leave LDIR/svc-up behind
# while they run, so the coordinator stops them at finish when the lane closed with them up (lane_services_down).
services_down() {
  (( ${SVC_UP:-0} )) || return 0
  local rc=0 unit=$SVC_UNIT cmd=${TEARDOWN_CMD:-} dir=${SVC_DIR:-$PWD}
  [[ -n $cmd || ! -x $dir/.harness/teardown.sh ]] || cmd=.harness/teardown.sh   # looked up now: a hook added mid-run counts
  (( ${SVC_INIT:-0} )) && scope_stop "$unit"
  if [[ -n ${SVC_TD:-} ]]; then wait "$SVC_TD"; rc=$?
  elif [[ -n $cmd ]]; then
    ( cd "$dir" || exit 1; HARNESS_PORT=$PORT HARNESS_SCRATCH=$SCRATCH HARNESS_TEARDOWN_WHY=$1 exec timeout -k 10s 2m bash -c "$cmd" ) < /dev/null >> "$SCRATCH/teardown.out" 2>&1 &   # in the tree the init ran in (a lane's slot)
    SVC_TD=$!; wait "$SVC_TD"; rc=$?
  fi
  scope_stop "$unit"; SVC_UP=0 SVC_TD=""; [[ -n $LDIR ]] && rm -f "$LDIR/svc-up"
  if (( rc )); then note "services stopped ($1; teardown exit $rc, see $SCRATCH/teardown.out, at finish $STATE/teardown.out)"
  else note "services stopped ($1)"; fi
}
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
  q=$(cat "$LS/question" 2> /dev/null)   # what take_question found in the session's copy (gone by now)
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

# <epoch>: the box-wide usage-limit window raised to it, never lowered (any lane, any run may have set a later one)
limit_raise() { (( $1 > $(cat "$LIMIT_FILE" 2> /dev/null || echo 0) )) && echo "$1" > "$LIMIT_FILE"; return 0; }
# One usage limit covers every run on the box: wait until the window that refused a session (any run's) is over.
# Each lane waits for a window once (its marker in its lane dir: a shared one would let one lane's wait cover another
# that then starts sessions inside the window); the coordinator waits only while no lane is open, so a window it or any
# lane already waited for is done for it, and one it waited for before opening is done for the lane.
limit_wait() {
  local upto now w; upto=$(cat "$LIMIT_FILE" 2>/dev/null || echo 0); now=$(date +%s)
  (( upto > now )) && [[ ! -f $STATE/waited-$upto && ! -f $LS/waited-$upto ]] || return 0
  [[ $LS == "$STATE" ]] && compgen -G "$STATE/lanes/*/waited-$upto" > /dev/null && return 0
  w=$(( upto - now )); (( w > DEADLINE - now )) && w=$(( DEADLINE - now )); (( w > 0 )) || return 0
  touch "$LS/waited-$upto"
  if (( w > SVC_IDLE_STOP_MIN * 60 )); then   # a short wait keeps them (decisions/2026-10-25-services-stop-points)
    services_down "usage-limit wait"; [[ $LS == "$STATE" ]] && lanes_services_down "usage-limit wait"   # the coordinator: closed lanes' too
  fi
  note "usage-limit window (shared by all runs): waiting until $(date -d "@$upto" '+%H:%M') ($(( w / 60 )) min)"
  rec_commit "HARNESS: waiting for the usage limit"; sync_record
  sleep "${HARNESS_LIMIT_SLEEP:-$w}"
}

prompt() {   # template name → $LS/prompt.md (lib/prompt.sh, which `harness eval probes` renders the same way)
  prompt_render "$1" > "$LS/prompt.md"
  cp "$LS/prompt.md" "$STATE/prompt-$1.md"   # the last prompt of each kind (any lane's), for debugging
}

# <attempt N of M | verify round N of M> → the clock line of a coding or verify prompt ({{CLOCK}}): sessions can't tell
# time, budget or attempt otherwise. The run is this driver's segment (T0 to DEADLINE). decisions/2026-10-21-clock-and-bounded-init-output
clock() {
  local now el tot; now=$(date +%s); el=$(( (now - T0) / 60 )); tot=$(( (DEADLINE - T0) / 60 ))
  printf 'Clock: %s · run %dh%02dm of %s, ends %s · this session: $%s budget, %s turns, %s timeout · %s\n' "$(date '+%F %H:%M')" \
    $(( el / 60 )) $(( el % 60 )) "$( (( tot % 60 )) && printf '%dh%02dm' $(( tot / 60 )) $(( tot % 60 )) || echo "$(( tot / 60 ))h")" \
    "$(date -d "@$DEADLINE" +%H:%M)" "$SESSION_BUDGET_USD" "$MAX_TURNS" "$SESSION_TIMEOUT" "$1"
}

# kind model log who → runs claude headless on $LS/prompt.md in its own capped scope (decisions/2026-10-25-scoped-sessions);
# sets S_EXIT, S_WALL, S_PEAK (MB, empty when uncapped) and S_NOTES (what the scope showed; noted here, except for the
# read-only retro, whose caller notes them after restrict, which would revert them)
session() {
  local settings=() mcp=(--strict-mcp-config) t0 seq unit left x
  t0=$(date +%s) S_NOTES=()
  # an entry.json no ingest took (the driver died after its session) would pass for this session's own
  [[ -e $RUN_DIR/entry.json ]] && { mv -f "$RUN_DIR/entry.json" "$STATE/entry-stale-$(date +%s).json"; note "an earlier session's entry.json moved aside before this $1 session"; }
  cp "$LS/prompt.md" "${3%.jsonl}.prompt.md"   # each session's prompt beside its transcript, so two can be diffed (decisions/2026-10-21-static-first-prompts)
  [[ $1 == coding || $1 == verify ]] && cp "$RUN_DIR/context.md" "${3%.jsonl}.context.md" 2> /dev/null   # and the pack it read first
  [[ -f $AGENT_SETTINGS ]] && settings=(--settings "$WT/$AGENT_SETTINGS")
  # only the project's committed MCP servers, never the user's or another project's (decisions/2026-10-25-strict-mcp-and-deepequal-rule)
  [[ -f $WT/.mcp.json ]] && mcp+=(--mcp-config "$WT/.mcp.json")
  # s<n> is per run, never per segment: a crashed segment's scope may still hold its name; a lane's is harness-<run>-<m>-s<n>
  seq=$(rec_count "$STATE/scope-seq" 1); unit=$(scope_unit "$RUN_ID" "${LANEU:+$LANEU-}s$seq")
  # timeout inside the scope: outside it would signal the wrapper and leave claude running; -k: claude ignoring TERM
  S_UNIT=$unit   # the EXIT trap stops it when the driver dies mid-session
  scope_run "$unit" "$SESSION_MEMORY_HIGH" "$SESSION_MEMORY_MAX" timeout -k 30s "$SESSION_TIMEOUT" \
    "$CLAUDE" -p "$(cat "$LS/prompt.md")" --model "$2" --permission-mode auto "${settings[@]}" "${mcp[@]}" \
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
  fi
  record journal_ "$who" "$kind" "$id" "$name" "$4" "$outcome"
  return 0
}
journal_() {   # who kind id name model outcome: the ingest and the render, in the record
  local out rc
  if [[ $PWD != "$RWT" ]]; then   # a lane: the take-back of the copy's entry, under the lock with the ingest
    rm -f "$REC/entry.json"; [[ -e $RUN_DIR/entry.json ]] && mv -f "$RUN_DIR/entry.json" "$REC/entry.json"
  fi
  out=$(node "$HARNESS_HOME/lib/entries.mjs" ingest "$REC" "$2" "$3" "$4" "$5" "$6" "$SCRATCH/entry-files" "$SCRATCH/entry-final"); rc=$?
  (( rc == 3 )) && note "$1: entry.json $out; recorded a minimal entry"
  (( rc == 0 || rc == 3 )) || { note "$1: the journal append failed (exit $rc): $out"   # aside, so the next session's ingest can't take it
    mv -f "$REC/entry.json" "$STATE/entry-failed-$4.json" 2> /dev/null; }
  out=$(node "$HARNESS_HOME/lib/entries.mjs" render "$REC" 2>&1) || note "$1: rendering progress.md failed: $out"
  return 0
}

# <feature> <start commit> → a note when the `## Gotchas` lines of CLAUDE.md differ between the session's start commit
# and HEAD (lib/memlint.mjs gotchasDiff; decisions/2026-10-26-gotchas-in-place). Coding sessions only: verify and retro
# are read-only, restrict reverts their CLAUDE.md. In a lane, the slot's commits.
gotchas() {
  local d
  git show "$2:CLAUDE.md" > "$SCRATCH/gotchas-before.md" 2> /dev/null || : > "$SCRATCH/gotchas-before.md"
  git show HEAD:CLAUDE.md > "$SCRATCH/gotchas-after.md" 2> /dev/null || : > "$SCRATCH/gotchas-after.md"
  d=$(node "$HARNESS_HOME/lib/memlint.mjs" gotchas "$SCRATCH/gotchas-before.md" "$SCRATCH/gotchas-after.md") && [[ -n $d ]] && note "$1: gotchas $d"
  return 0
}

# <m> → how many verify entries the milestone has in entries.jsonl (the rendered progress.md shows only the 15 newest in
# full). A run with a list always has the file by its first verify: the start-up or the initializer's append creates it
vcount() {
  jq -cR --arg m "$1" 'fromjson? | objects | select(.kind == "verify" and .feature == $m)' "$REC/entries.jsonl" 2> /dev/null | wc -l
}

# <feature or milestone> [<cap>] → <run>/context.md, the bounded pack of the journal the next coding or verify session
# reads first (lib/entries.mjs pack, at most <cap>, default CONTEXT_PACK_BYTES; verify passes CONTEXT_PACK_BYTES_VERIFY:
# decisions/2026-10-22-context-pack, decisions/2026-10-26-pack-current-rules). Its Gotchas and Current rules are the
# cwd's (a lane's slot: the code the session sees). Committed with the run record on the record branch; materialize
# copies it into the slot.
context_() {
  if node "$HARNESS_HOME/lib/entries.mjs" pack "$REC" "$1" "${2:-$CONTEXT_PACK_BYTES}" "$PWD" > "$SCRATCH/context.md" 2> "$SCRATCH/context.err"; then
    mv -f "$SCRATCH/context.md" "$REC/context.md"
    note "context.md for $1: $(wc -c < "$REC/context.md") bytes$(sed -n 's/^_\([0-9]*\) items left out at .*/, \1 items left out/p' "$REC/context.md")"
  else   # never a stale pack: the session is sent to the full record instead
    printf '# Context pack for `%s`\n\nThe harness could not build it this time; read entries.jsonl / progress-archive.md.\n' "$1" > "$REC/context.md"
    note "context.md for $1: the pack failed ($(head -c 200 "$SCRATCH/context.err" | tr '\n' ' ')); it points at the full record"
  fi
  # committed now, alone: anything else uncommitted in the record stays for its own commit (E4 review F4)
  git -C "$RWT" add -- "$RUN_DIR/context.md" && { git -C "$RWT" diff --cached --quiet -- "$RUN_DIR/context.md" || git -C "$RWT" commit -q -m "HARNESS: context pack for $1" -- "$RUN_DIR/context.md"; }
}
context() { record context_ "$@"; }

# The project's init, then the suite (cached per code tree); both go into the next prompt. The init runs in
# harness-<run>-svc (decisions/2026-10-25-services-scope): what it backgrounds (a dev server) stays there, capped at
# SVC_MEMORY_MAX. timeout bounds the init, not the servers it left once it returned (a timeout takes its process group
# too); stdin is /dev/null, so no tool waits on the tmux pane. The last init's scope is stopped first: systemd refuses
# a unit name still loaded (tests/fixtures/systemd-run-unit-exists.txt), and its services would live on beside the new.
run_init() {   # [fresh: clear the suite cache's marker for the tree as the init left it, so the suite runs in full]
  local unit=$SVC_UNIT
  scope_stop "$unit"
  SVC_UP=1 SVC_INIT=1 SVC_DIR=$PWD; [[ -n $LDIR ]] && echo "$unit" > "$LDIR/svc-up"   # before the start: a TERM during the init must still stop what it began (services_down, L2-03)
  HARNESS_PORT=$PORT HARNESS_SCRATCH=$SCRATCH scope_run "$unit" "" "$SVC_MEMORY_MAX" timeout -k 10s "$INIT_TIMEOUT" bash -c "$INIT_CMD" < /dev/null > "$SCRATCH/init.out" 2>&1
  local rc=$?; SVC_INIT=0; echo "(init exit $rc)" >> "$SCRATCH/init.out"
  [[ -n ${SCOPE_BARE:-} ]] && note "init ran uncapped: $SCOPE_BARE"   # systemd refused the unit; its line is in init.out
  (( rc == 0 )) || log "  init exit $rc (the session is told to fix it first)"
  [[ ${1:-} == fresh ]] && rm -f "$STATE/green/green-$(node "$HARNESS_HOME/lib/treekey.mjs")"
  "$CHECK" >> "$SCRATCH/init.out" 2>&1 || log "  suite red before the session (the session is told to fix it first)"
  [[ -f $STATE/tests-start ]] || node "$HARNESS_HOME/lib/testcount.mjs" "$SCRATCH/check.out" | cut -d' ' -f1 | grep . > "$STATE/tests-start" \
    || rm -f "$STATE/tests-start"
  # once per run, from the first suite that wrote a check.out (a cached green wrote none): where the count came from, so
  # a scraped count is told from the contract and a missing one explains the report's `?` (testcount-nomatch: older runs)
  local src
  if [[ -f $SCRATCH/check.out && ! -f $STATE/testcount-source && ! -f $STATE/testcount-nomatch ]]; then
    src=$(node "$HARNESS_HOME/lib/testcount.mjs" "$SCRATCH/check.out" --source); src=${src##* · }
    case $src in
      contract) note "test count: HARNESS_TESTS contract" ;;
      none|"") src=none; note "test count: no match in the suite's output (tests start/end stay unknown)" ;;
      *) note "test count: parsed ($src)" ;;
    esac
    echo "$src" > "$STATE/testcount-source"
  fi
}

# tests-end: a green tree's count, its marker's (a continued segment's scratch has no output of a tree cached green),
# else (an older, empty marker) its output's; a red tree has none, whatever its output counted. Written after every
# session too (by its lane, of its slot's tree), so status and report show it between sessions; tests-start, the run's
# baseline, is never rewritten (decisions/2026-10-26-test-count-contract). Without a count only `final` (finish) clears
# it: mid-run, the last stays. The cwd's tree, with this process's SCRATCH.
tests_end() {   # [final]
  local key n=""; key=$(node "$HARNESS_HOME/lib/treekey.mjs")
  if [[ -f $STATE/green/green-$key ]]; then
    n=$(cat "$STATE/green/green-$key"); [[ -n $n ]] || n=$(node "$HARNESS_HOME/lib/testcount.mjs" "$SCRATCH/check-$key.out" 2> /dev/null)
  fi
  if [[ -n $n ]]; then echo "${n%% *}" > "$STATE/tests-end"; elif [[ ${1:-} == final ]]; then rm -f "$STATE/tests-end"; fi
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
  pr_body "$m" > "$LS/pr-body.md"; [[ $LS == "$STATE" ]] || cp "$LS/pr-body.md" "$STATE/pr-body.md"   # the last body, whichever lane (checks read it)
  url=$($GH pr view "$head" --json url,state -q 'select(.state=="OPEN") | .url' 2>/dev/null) || url=""
  [[ $url == http* ]] || url=$($GH pr create --base "$MAIN_BRANCH" --head "$head" --title "$RUN_ID: $m (verified)" --body-file "$LS/pr-body.md" 2>> "$STATE/run.log" | tail -1)
  [[ $url == http* ]] || { note "$m: could not open its PR (see run.log)"; return 1; }
  [[ ${2:-} == --open ]] && return 0   # a dependency hasn't merged: the PR waits for it, whatever the policy
  if [[ $MERGE_POLICY != auto && ! ${HARNESS_MERGE_ONLY:-} ]]; then touch "$STATE/proposed-$m"; note "$m proposed for merging · $url"; notify "$m verified · review: $url" title="[$RUN_ID] $m ready to merge" click="$url"; return 0; fi   # harness merge lands it whatever the policy
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
# until then its PR is opened and waits (noted once, under pr too). v2 tags (verified under weaker rules) and proposed
# milestones (pr) merge only through `harness merge`, in the same order. Nothing under MERGE_POLICY=off.
merge_milestones() {
  [[ $MERGE_POLICY == off || ! -f $LIST ]] && return 0
  local m d wait
  for m in $(F milestones "$LIST"); do
    [[ -n ${1:-} && $m != "$1" ]] && continue
    [[ -f $STATE/merged-$m ]] && continue
    if [[ -f $STATE/proposed-$m && ! ${HARNESS_MERGE_ONLY:-} ]]; then   # Michael's to merge, or `harness merge`'s
      # merged by Michael meanwhile (its PR on GitHub): merged here too, so what waits on it moves on
      git rev-parse -q --verify "refs/tags/run/$RUN_ID/$m" > /dev/null && git fetch -q origin "$MAIN_BRANCH" 2> /dev/null \
        && git merge-base --is-ancestor "run/$RUN_ID/$m" "origin/$MAIN_BRANCH" && { touch "$STATE/merged-$m"; note "$m merged into $MAIN_BRANCH (by its PR)"; }
      continue
    fi
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

# Pull Michael's phone edits (INBOX.md) into the record, push its commits. Never rewrites history. 9>&-: a network
# command never holds the lock past this call (an ssh ControlPersist master would keep fd 9).
sync_record_() {
  if git -C "$RWT" fetch -q origin "$RBRANCH" 9>&- 2> /dev/null; then
    git -C "$RWT" merge -q --ff-only "origin/$RBRANCH" 2> /dev/null \
      || git -C "$RWT" merge -q --no-edit "origin/$RBRANCH" > /dev/null 2>&1 \
      || { git -C "$RWT" merge --abort 2> /dev/null; log "remote edits on $RBRANCH conflict with local work; kept local"; }
  fi
  git -C "$RWT" push -q -u origin "$RBRANCH" 9>&- 2>> "$STATE/run.log" || log "push of $RBRANCH failed"
}
sync_record() { record sync_record_; }
sync_lane() { [[ -n ${LBRANCH:-} ]] || return 0; git -C "$SLOT" push -q -u origin "$LBRANCH" 2>> "$STATE/run.log" || log "push of $LBRANCH failed"; }

# <m> [<k>] → slot k (0) on harness-lane/<run>/<m>, cwd there; HARNESS_WT and HARNESS_BRANCH name it for sessions.
# The coordinator opens it, then starts the lane process in it (lib/lane.sh). A lane resumes its branch (the newer of
# the box's and the origin's, both merged if they diverged), else starts from BASE_REF (harness start --base) or
# origin/main, then merges the tag of every dependency main doesn't have yet. 1 = its base
# conflicts or the slot can't be checked out (needs-<m>, noted: the loop would only pick it again), cwd back in the
# record worktree.
slot_open() {
  local m=$1 k=${2:-0} b=harness-lane/$RUN_ID/$1 base fold dep tag first=0 sha
  SLOT=$WT_ROOT_DIR/lanes/$RUN_ID/slot-$k
  LBRANCH="" LANE=""   # from here the slot leaves the last lane's branch: only a full open names a lane again
  if [[ -d $SLOT ]]; then   # a segment killed mid-session left its work here: committed before the base is chosen, so it stays
    local cur; cur=$(git -C "$SLOT" branch --show-current)
    ( cd "$SLOT" && commit_all "WIP: uncommitted in the slot when it was reused (harness)" )
    [[ $cur == harness-lane/* ]] && git -C "$SLOT" push -q origin "$cur" 2> /dev/null
  fi
  git -C "$RWT" fetch -q origin 2> /dev/null
  base=${BASE_REF:-origin/$MAIN_BRANCH} fold=""
  # a lane resumes its branch (harness continue, a segment that ended mid-milestone): the origin's, which may be ahead
  # (Michael pushed a fix by hand); the box's when it has commits the origin lacks (a failed push); both when they diverged
  if git -C "$RWT" rev-parse -q --verify "refs/remotes/origin/$b" > /dev/null; then
    base=origin/$b
    if git -C "$RWT" rev-parse -q --verify "refs/heads/$b" > /dev/null && ! git -C "$RWT" merge-base --is-ancestor "refs/heads/$b" "refs/remotes/origin/$b"; then
      base=$b; git -C "$RWT" merge-base --is-ancestor "refs/remotes/origin/$b" "refs/heads/$b" || fold=origin/$b
    fi
  elif git -C "$RWT" rev-parse -q --verify "refs/heads/$b" > /dev/null; then base=$b; fi
  if [[ ! -d $SLOT ]]; then
    mkdir -p "${SLOT%/*}"; first=1
    git -C "$RWT" worktree add -q -f "$SLOT" -B "$b" "$base" 2>> "$STATE/run.log" || { slot_fail "$m" "worktree add of $SLOT"; return 1; }
  else
    git -C "$SLOT" checkout -q -f -B "$b" "$base" 2>> "$STATE/run.log" || { slot_fail "$m" "checkout of $b"; return 1; }
  fi
  if [[ -n $fold ]]; then
    if ! git -C "$SLOT" merge -q --no-edit "$fold" > /dev/null 2>&1; then
      git -C "$SLOT" merge --abort 2> /dev/null
      note "$m: $b here and on origin diverged and conflict; needs Michael"; touch "$STATE/needs-$m"
      cd "$RWT" || return 1; return 1
    fi
    note "$m: $b here and on origin had diverged; merged origin's into it"
  fi
  for dep in $(F deps "$LIST" "$m"); do
    tag=run/$RUN_ID/$dep
    git -C "$SLOT" rev-parse -q --verify "refs/tags/$tag" > /dev/null || continue
    git -C "$SLOT" merge-base --is-ancestor "$tag" "origin/$MAIN_BRANCH" 2> /dev/null && continue
    git -C "$SLOT" merge-base --is-ancestor "$tag" HEAD && continue
    if ! git -C "$SLOT" merge -q --no-edit "$tag" > /dev/null 2>&1; then
      git -C "$SLOT" merge --abort 2> /dev/null
      note "$m: its base conflicts ($dep vs $MAIN_BRANCH); needs Michael"; touch "$STATE/needs-$m"
      cd "$RWT" || return 1; return 1
    fi
  done
  # the copy of the record is invisible to the slot's git (a per-worktree excludes file, never .git/info/exclude,
  # which the record worktree shares), plus the user's own global excludes the worktree value would shadow
  mkdir -p "$STATE/lanes/$m"
  { echo ".harness/runs/"; cat "$(git config --global --path core.excludesFile 2> /dev/null || echo "${XDG_CONFIG_HOME:-$HOME/.config}/git/ignore")" 2> /dev/null; } > "$STATE/lanes/$m/exclude"
  [[ $(git -C "$RWT" config extensions.worktreeConfig) == true ]] || git -C "$RWT" config extensions.worktreeConfig true
  git -C "$SLOT" config --worktree core.excludesFile "$STATE/lanes/$m/exclude"
  echo "$SLOT" > "$STATE/lanes/$m/slot"   # lib/prompt.sh as a command renders a lane's prompt from it
  LBRANCH=$b LANE=$m; lane_cd
  sha=$(git rev-parse --short HEAD)
  note "lane $m opened (slot $k, port $PORT, from $sha$( (( first )) || echo ", slot reused"))"
}
slot_fail() { note "$1: its slot failed ($2; see run.log); needs Michael"; touch "$STATE/needs-$1"; cd "$RWT" || :; }
lane_cd() { cd "$SLOT" || return 1; export HARNESS_WT=$SLOT HARNESS_BRANCH=$LBRANCH; SLIST=$SLOT/$RUN_DIR/feature_list.json; }
rec_cd() { cd "$RWT" || return 1; export HARNESS_WT=$RWT HARNESS_BRANCH=$RBRANCH; SLIST=$LIST; }

# The record copied into the slot for the next session; the snapshot and the INBOX it is judged against are the copy's,
# so a phone edit merged into the record meanwhile is never the session's. A record tracked at the slot's base (a run
# whose record reached main before lanes) is marked skip-worktree, so the session's `git add -A` stages none of it.
materialize_() {
  rm -rf "${SLOT:?}/$RUN_DIR"; mkdir -p "$SLOT/$RUN_DIR"; cp -a "$REC/." "$SLOT/$RUN_DIR/"
  git -C "$SLOT" ls-files -z -- "$RUN_DIR" | (cd "$SLOT" && xargs -0 -r git update-index --skip-worktree)
  F snapshot "$SLIST" > "$LS/before.json"
  cp "$SLOT/$RUN_DIR/INBOX.md" "$LS/inbox-before.md" 2> /dev/null || : > "$LS/inbox-before.md"
}
materialize() { record materialize_; }
# The copy goes; the slot is clean again (the next checkout -B and gc rely on it).
unmaterialize() {
  [[ -n ${SLOT:-} && -d $SLOT/$RUN_DIR ]] || return 0
  local tracked; tracked=$(git -C "$SLOT" ls-files -- "$RUN_DIR")
  rm -rf "${SLOT:?}/$RUN_DIR"
  [[ -n $tracked ]] && { git -C "$SLOT" ls-files -z -- "$RUN_DIR" | (cd "$SLOT" && xargs -0 -r git update-index --no-skip-worktree); git -C "$SLOT" checkout -q HEAD -- "$RUN_DIR"; }
  return 0
}

# The lines a session added above "## Answers" in its copy go into the record's INBOX.md above that line (at the end
# they would sit under the answers and change answers_hash, unparking at once); saved for the park's notification.
take_question_() {
  local q; q=$(node "$NOTIFY_MJS" question "$LS/inbox-before.md" "$SLOT/$RUN_DIR/INBOX.md" 2> /dev/null)
  printf '%s' "$q" > "$LS/question"
  [[ -n $q ]] || return 0
  if grep -q '^## Answers' "$REC/INBOX.md"; then
    node -e 'const fs=require("fs"),[f,q]=process.argv.slice(1),t=fs.readFileSync(f,"utf8"),i=t.search(/^## Answers/m);fs.writeFileSync(f,t.slice(0,i)+q+"\n\n"+t.slice(i))' "$REC/INBOX.md" "$q"
  else printf '\n%s\n' "$q" >> "$REC/INBOX.md"; fi
}
take_question() { record take_question_; }

# <start commit> <who>: a lane commit that touched .harness/runs/ (a session that `git add -f`'d the copy) is reverted
# by a new commit; the record never takes anything from it.
lane_guard() {
  [[ -n $(git diff --name-only "$1" HEAD -- .harness/runs/ 2> /dev/null) ]] || return 0
  restrict "$1" runs "$2" > /dev/null
  note "$2: a lane commit touched the run record; reverted"
  sync_lane
}

# Every slot goes at the end of a segment (its lane's branch is pushed: a continuation reopens it); merged lanes'
# branches go, locally and on the origin; unverified ones stay.
slot_close() {
  local s
  rec_cd
  for s in "$WT_ROOT_DIR/lanes/$RUN_ID"/slot-*; do
    [[ -d $s ]] || continue
    git -C "$RWT" worktree remove --force "$s" 2>> "$STATE/run.log" || log "slot: could not remove $s"
  done
  git -C "$RWT" worktree prune
  rmdir "$WT_ROOT_DIR/lanes/$RUN_ID" "$WT_ROOT_DIR/lanes" 2> /dev/null
  LBRANCH="" LANE=""
  local f m b
  for f in "$STATE"/merged-*; do
    [[ -f $f ]] || continue; m=${f##*/merged-} b=harness-lane/$RUN_ID/$m
    git -C "$RWT" rev-parse -q --verify "refs/heads/$b" > /dev/null && git -C "$RWT" branch -q -D "$b"
    git -C "$RWT" rev-parse -q --verify "refs/remotes/origin/$b" > /dev/null && git -C "$RWT" push -q origin --delete "$b" 2> /dev/null
  done
  # a lane opened and never pushed (the run ended before its first session) that carries nothing main lacks is litter
  for b in $(git -C "$RWT" for-each-ref --format='%(refname:short)' "refs/heads/harness-lane/$RUN_ID"); do
    git -C "$RWT" rev-parse -q --verify "refs/remotes/origin/$b" > /dev/null && continue
    git -C "$RWT" merge-base --is-ancestor "$b" "origin/$MAIN_BRANCH" 2> /dev/null && git -C "$RWT" branch -q -D "$b"
  done
  return 0
}
