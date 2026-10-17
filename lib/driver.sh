#!/usr/bin/env bash
# The harness driver (what `harness start` runs inside tmux). Deterministic glue around agent sessions:
#   1. no feature list → one initializer session writes it
#   2. one fresh coding session per feature; before each: take answers, sync remote edits, honour pause/stop, run the
#      project's init; after each: commit leftovers, repair the feature list, un-pass on a red suite, record metrics, push
#   3. a milestone's features all pass → one verify session re-checks them → tag the milestone and open/update the
#      run's pull request into main with the evidence (merging stays a human review: one tap, or GitHub auto-merge)
# Environment (set by bin/harness): WT RUN_ID STATE PROJECT_DIR HARNESS_HOME
set -uo pipefail
: "${WT:?}" "${RUN_ID:?}" "${STATE:?}" "${PROJECT_DIR:?}" "${HARNESS_HOME:?}"
cd "$WT" || exit 1

# ---- configuration: defaults, then the project's .harness/config.sh ----
PROJECT_NAME=$(basename "$PROJECT_DIR")
HOURS=8 MAX_SESSIONS=40 MAX_ATTEMPTS=2 MAX_REPAIRS=3 MAX_VERIFY_ROUNDS=2 MAX_LIMIT_HITS=6
LIMIT_WAITS="900 1800 3600"   # seconds to wait after the 1st, 2nd, 3rd+ consecutive usage-limit hit
SESSION_TIMEOUT=100m MAX_TURNS=250 SESSION_BUDGET_USD=20
INIT_MODEL=fable WORKER_MODEL=opus VERIFY_MODEL=sonnet
PR_POLICY=milestone MAIN_BRANCH=main
CHECK_CMD=true INIT_CMD=true SMOKE_CMD=true SPEC_FILES="" NOTIFY_CMD="" AGENT_SETTINGS=.claude/settings.json
# shellcheck source=/dev/null
source .harness/config.sh

CLAUDE=${HARNESS_CLAUDE:-claude}
GH=${HARNESS_GH:-gh}
F() { node "$HARNESS_HOME/lib/features.mjs" "$@"; }
MET() { node "$HARNESS_HOME/lib/metrics.mjs" "$@"; }

BRANCH=$(git branch --show-current)
RUN_DIR=.harness/runs/$RUN_ID LIST=.harness/runs/$RUN_ID/feature_list.json
LOGS=$STATE/logs ATT=$STATE/attempts.json
SCRATCH=${HARNESS_SCRATCH_ROOT:-/tmp/harness}/$PROJECT_NAME/$RUN_ID
PORT=$(cat "$STATE/port")
mkdir -p "$LOGS" "$RUN_DIR" "$SCRATCH"
DEADLINE=$(( $(date +%s) + HOURS * 3600 ))
export HARNESS_RUN_ID=$RUN_ID HARNESS_RUN_DIR=$RUN_DIR HARNESS_BRANCH=$BRANCH HARNESS_PORT=$PORT HARNESS_SCRATCH=$SCRATCH \
  HARNESS_CHECK_CMD=$CHECK_CMD HARNESS_SMOKE_CMD=$SMOKE_CMD HARNESS_INIT_CMD=$INIT_CMD HARNESS_SPEC_FILES=$SPEC_FILES \
  HARNESS_MAIN_BRANCH=$MAIN_BRANCH HARNESS_PROJECT=$PROJECT_NAME

log() { echo "$(date '+%F %T') $*" | tee -a "$STATE/run.log"; }
note() { log "$*"; echo "- $(date '+%F %H:%M') · $*" >> "$RUN_DIR/harness-log.md"; }   # phone-readable, committed
notify() { [[ -n $NOTIFY_CMD ]] && bash -c "$NOTIFY_CMD" _ "[$RUN_ID] $*" > /dev/null 2>&1; return 0; }
commit_all() { git add -A && ! git diff --cached --quiet && git commit -q -m "$1"; return 0; }
# The code tree's identity, ignoring the run record: an unchanged tree that was green is not re-tested (slow suites).
tree_key() { { git ls-files -s -- . ':!.harness/runs'; git diff HEAD -- . ':!.harness/runs'; } | sha1sum | cut -c1-16; }
green() {
  local k; k=$(tree_key); [[ -f $SCRATCH/green-$k ]] && return 0
  bash -c "$CHECK_CMD" > "$SCRATCH/check.out" 2>&1 && touch "$SCRATCH/green-$k"
}

[[ -z $BRANCH || $BRANCH == "$MAIN_BRANCH" ]] && { log "refusing to run on '${BRANCH:-detached HEAD}'"; exit 1; }

# Pull edits made on GitHub (INBOX.md from the phone), push local commits. Never rewrites history.
sync() {
  if git fetch -q origin "$BRANCH" 2>/dev/null; then
    git merge -q --ff-only "origin/$BRANCH" 2>/dev/null \
      || git merge -q --no-edit "origin/$BRANCH" > /dev/null 2>&1 \
      || { git merge --abort 2>/dev/null; log "remote edits on $BRANCH conflict with local work; kept local"; }
  fi
  git push -q -u origin "$BRANCH" 2>> "$STATE/run.log" || log "push of $BRANCH failed"
}

# Answers typed locally (`harness answer`, the supervisor) are moved into INBOX.md so sessions see them.
take_answers() {
  [[ -s $STATE/inbox.md ]] || return 0
  { echo; echo "### $(date '+%F %H:%M') (local)"; cat "$STATE/inbox.md"; } >> "$RUN_DIR/INBOX.md"
  : > "$STATE/inbox.md"
  commit_all "HARNESS: answers from Michael"
}

control() {   # → run | pause | stop
  local s; s=$(sed -n 's/^status:[[:space:]]*//p' "$RUN_DIR/INBOX.md" 2>/dev/null | head -1)
  if [[ -f $STATE/STOP || $s == stop* ]]; then echo stop
  elif [[ -f $STATE/PAUSE || $s == pause* ]]; then echo pause
  else echo run; fi
}

prompt() {   # template name → $STATE/prompt.md (generic prompt + the project's rules)
  local extra=(); [[ -f .harness/project.md ]] && extra=(.harness/project.md)
  HARNESS_INIT_OUTPUT=$(tail -c 4000 "$SCRATCH/init.out" 2>/dev/null) \
    node "$HARNESS_HOME/lib/render.mjs" "$HARNESS_HOME/prompts/$1.md" "${extra[@]}" > "$STATE/prompt.md"
}

session() {   # kind model log → runs claude headless; the prompt is $STATE/prompt.md
  local settings=(); [[ -f $AGENT_SETTINGS ]] && settings=(--settings "$WT/$AGENT_SETTINGS")
  timeout "$SESSION_TIMEOUT" "$CLAUDE" -p "$(cat "$STATE/prompt.md")" --model "$2" --permission-mode auto "${settings[@]}" \
    --max-turns "$MAX_TURNS" --max-budget-usd "$SESSION_BUDGET_USD" --output-format stream-json --verbose > "$3" 2>&1
  log "  $1 exit $? · $(git log --oneline -1)"
}

run_init() {
  HARNESS_PORT=$PORT HARNESS_SCRATCH=$SCRATCH bash -c "$INIT_CMD" > "$SCRATCH/init.out" 2>&1
  local rc=$?; echo "(init exit $rc)" >> "$SCRATCH/init.out"
  (( rc == 0 )) || log "  init exit $rc (the session is told to fix it first)"
}

# Tag a verified milestone and open (or refresh) the run's PR into main with the evidence. Merging is Michael's.
propose() {   # label
  local tag="run/$RUN_ID/$1" body="$STATE/pr-body.md" url
  git tag -a "$tag" -m "harness run $RUN_ID: $1 verified" 2>/dev/null && git push -q origin "$tag" 2>> "$STATE/run.log"
  {
    echo "Harness run \`$RUN_ID\` (branch \`$BRANCH\`). Verified milestones are tagged \`run/$RUN_ID/<milestone>\`."
    echo; echo "**Features:** $(F summary "$LIST") · **Sessions:** $(MET summary "$RUN_DIR/metrics.jsonl")"
    echo; echo "Progress log: \`$RUN_DIR/progress.md\` · harness log: \`$RUN_DIR/harness-log.md\` · steer: \`$RUN_DIR/INBOX.md\`"
    echo; echo "### Harness log"; tail -n 25 "$RUN_DIR/harness-log.md"
  } > "$body"
  if url=$($GH pr view "$BRANCH" --json url,state -q 'select(.state=="OPEN") | .url' 2>/dev/null) && [[ -n $url ]]; then
    $GH pr edit "$BRANCH" --body-file "$body" > /dev/null 2>> "$STATE/run.log"
  else
    url=$($GH pr create --base "$MAIN_BRANCH" --head "$BRANCH" --title "harness $RUN_ID" --body-file "$body" 2>> "$STATE/run.log" | tail -1)
  fi
  note "$1 verified and tagged $tag · PR ${url:-not created (see run.log)}"
  notify "$1 verified · review: ${url:-PR failed}"
}

verify() {   # milestone → 0 if every feature of it still passes after an independent re-check
  local m=$1 out vlog rounds
  rounds=$(( $(cat "$STATE/verify-rounds-$m" 2>/dev/null || echo 0) + 1 )); echo "$rounds" > "$STATE/verify-rounds-$m"
  F snapshot "$LIST" > "$STATE/before.json"
  run_init
  HARNESS_MILESTONE=$m HARNESS_FEATURES=$(F ids "$LIST" "$m" | paste -sd' ') prompt verify
  vlog="$LOGS/$(date +%H%M%S)-verify-$m.jsonl"
  log "verify $m · $(F model "$VERIFY_MODEL")"
  session verify "$(F model "$VERIFY_MODEL")" "$vlog"
  commit_all "WIP: verify $m — uncommitted at session end (harness)"
  out=$(F repair-verify "$LIST" "$STATE/before.json" "$m") || note "verify $m: reverted edits beyond un-passing: $out"
  for id in $(F ids "$LIST" "$m"); do
    if ! F passes "$LIST" "$id"; then
      if (( rounds < MAX_VERIFY_ROUNDS )); then
        note "verify $m: $id failed the re-check, back in the queue (one more attempt)"
        F grant "$ATT" "$id" "$MAX_ATTEMPTS"
      else
        note "verify $m: $id failed the re-check in round $rounds of $MAX_VERIFY_ROUNDS; $m needs Michael (see progress.md)"
        notify "$m needs Michael: $id fails verification"
      fi
    fi
  done
  MET append "$vlog" "$RUN_DIR/metrics.jsonl" "$RUN_ID" verify "$m" "$(F model "$VERIFY_MODEL")" "$(F milestone-done "$LIST" "$m" && echo true || echo false)"
  commit_all "HARNESS: verify $m"
  F milestone-done "$LIST" "$m"
}

# ---------------------------------------------------------------------------------------------------------------
log "run $RUN_ID on $BRANCH in $WT · port $PORT · PR policy $PR_POLICY"
[[ -f $RUN_DIR/INBOX.md ]] || cat > "$RUN_DIR/INBOX.md" <<EOF
status: run
<!-- Steer this run from the GitHub app: edit this file on branch $BRANCH.
     Change the first line to "status: pause" or "status: stop"; write answers to questions under "## Answers".
     The harness pulls before every session; every session reads this file at startup. -->

## Answers
EOF
commit_all "HARNESS: start run $RUN_ID"
sync

if [[ ! -f $LIST ]]; then
  run_init; prompt initializer
  log "initializer · $(F model "$INIT_MODEL")"
  session init "$(F model "$INIT_MODEL")" "$LOGS/00-init.jsonl"
  commit_all "WIP: initializer — uncommitted at session end (harness)"
  F summary "$LIST" > /dev/null 2>&1 || { note "initializer did not produce a valid $LIST; stopping"; notify "initializer failed"; exit 1; }
  MET append "$LOGS/00-init.jsonl" "$RUN_DIR/metrics.jsonl" "$RUN_ID" init "" "$(F model "$INIT_MODEL")" true
  note "feature list written: $(F summary "$LIST")"; commit_all "HARNESS: initializer done"; sync
  notify "started: $(F summary "$LIST")"
fi

repairs=0 n=0 limits=0
while (( n < MAX_SESSIONS )); do
  (( $(date +%s) >= DEADLINE )) && { note "deadline (${HOURS} h) reached"; break; }
  take_answers; sync
  c=$(control)
  if [[ $c == pause ]]; then
    log "paused (INBOX.md status or harness pause)"; notify "paused"
    while [[ $(control) == pause ]]; do sleep "${HARNESS_PAUSE_POLL:-60}"; take_answers; sync; done
    log "resumed"; continue
  fi
  [[ $c == stop ]] && { note "stopped by Michael"; break; }

  next=$(F next "$LIST" "$ATT" "$MAX_ATTEMPTS")
  [[ -z $next ]] && { note "no feature left to try: $(F summary "$LIST")"; break; }
  IFS=$'\t' read -r id mdl milestone <<< "$next"
  n=$(( n + 1 ))
  F bump "$ATT" "$id"; F snapshot "$LIST" > "$STATE/before.json"
  run_init
  HARNESS_FEATURE=$id HARNESS_MILESTONE=$milestone prompt coding
  log "session $n · $id · $mdl"
  slog="$LOGS/$(printf '%02d' "$n")-$id.jsonl" t0=$(date +%s)
  session coding "$mdl" "$slog"
  commit_all "WIP: $id — uncommitted at session end (harness)"

  # A usage/rate limit or an outage is not the feature's fault: give the attempt back, wait, try again.
  if why=$(MET limit "$slog" $(( $(date +%s) - t0 ))); then
    F unbump "$ATT" "$id"; n=$(( n - 1 )); limits=$(( limits + 1 ))
    read -ra waits <<< "$LIMIT_WAITS"; w=${waits[$(( limits > ${#waits[@]} ? ${#waits[@]} - 1 : limits - 1 ))]}
    if (( limits >= MAX_LIMIT_HITS )); then
      touch "$STATE/PAUSE"; note "$limits usage-limit hits in a row ($why); paused — harness resume $RUN_ID"; notify "paused: usage limit"; continue
    fi
    (( limits == 1 )) && notify "usage limit, waiting"
    left=$(( DEADLINE - $(date +%s) )); (( w > left )) && w=$(( left > 0 ? left : 0 ))
    note "session for $id hit a limit ($why); not counted; waiting $(( w / 60 )) min"
    commit_all "HARNESS: usage limit"; sync
    sleep "${HARNESS_LIMIT_SLEEP:-$w}"; continue
  fi
  limits=0

  if out=$(F repair "$LIST" "$STATE/before.json" "$id"); then repairs=0; else
    repairs=$(( repairs + 1 )); note "restored the feature list after $id: $out"
    (( repairs >= MAX_REPAIRS )) && { note "$repairs sessions in a row edited the feature list; stopping for Michael"; notify "stopped: feature list edits"; break; }
  fi
  if F passes "$LIST" "$id" && ! green; then F unpass "$LIST" "$id"; note "$id un-passed: suite red after the session"; fi
  passed=$(F passes "$LIST" "$id" && echo true || echo false)
  MET append "$slog" "$RUN_DIR/metrics.jsonl" "$RUN_ID" coding "$id" "$mdl" "$passed"
  note "$id · $mdl · passes=$passed · $(F summary "$LIST")"
  commit_all "HARNESS: after $id (passes=$passed)"; sync

  if [[ -n $milestone && ! -f $STATE/verified-$milestone ]] && F milestone-done "$LIST" "$milestone"; then
    if verify "$milestone"; then
      touch "$STATE/verified-$milestone"
      [[ $PR_POLICY == milestone ]] && propose "$milestone" || note "milestone $milestone verified"
    fi
    commit_all "HARNESS: milestone $milestone"; sync
  fi
done

note "run ended: $(F summary "$LIST") · $(MET summary "$RUN_DIR/metrics.jsonl")"
commit_all "HARNESS: run ended"; sync
[[ $PR_POLICY != off ]] && propose final
commit_all "HARNESS: run ended"; sync
log "run kept in $WT on $BRANCH · resume: harness start $PROJECT_DIR $RUN_ID · after merging: harness gc $PROJECT_DIR"
