#!/usr/bin/env bash
# `harness debrief [--if-missed] [--dry-run]`: after a queue, one short read-only session reviews what happened and
# tells Michael, so nobody has to open a session to triage. The queue runner calls it when it exits (if it started a
# run); a daily timer calls it with --if-missed (contrib/systemd/).
#   1. bash gathers the context, no model: status, trends, the queue, runner.log since the last "runner up", and for
#      every run started since then: why it ended, summary.json, report.md, retro.md, INBOX.md, open questions
#   2. waits for the usage-limit window (LIMIT_UNTIL), at most 5 h; a longer one: exits, the timer retries
#   3. one headless session (DEBRIEF_MODEL) writes the note; the never-list goes in as --disallowedTools
#   4. its "CONTINUE: <run> :: <brief>" lines are checked here and queued (`harness queue add --continue`); the note
#      goes to <ledger>/debriefs/<YYYY-MM-DD-HHMM>.md; NOTIFY_CMD gets the headline (≤ 3 lines) and the note's path
# --if-missed: nothing if a debrief is newer than the last "runner up" and the runner is gone, or if that runner
#   started no run; a runner still going more than 1 h past its --until gets a "queue looks stuck" debrief.
# --dry-run: print the context file's path and contents; no wait, no session.
set -uo pipefail
: "${HARNESS_HOME:?}"
STATE_ROOT=${HARNESS_STATE:-${XDG_STATE_HOME:-$HOME/.local/state}/harness} Q=${HARNESS_STATE:-${XDG_STATE_HOME:-$HOME/.local/state}/harness}/queue
H=$HARNESS_HOME/bin/harness CLAUDE=${HARNESS_CLAUDE:-claude} LEDGER=${HARNESS_LEDGER:-$HARNESS_HOME/ledger}
MAX_WAIT=$(( 5 * 3600 )) STUCK_AFTER=3600
# shellcheck source=lib/config.sh
source "$HARNESS_HOME/lib/config.sh"; harness_config /nonexistent   # defaults + the user's config
F() { node "$HARNESS_HOME/lib/features.mjs" "$@"; }
MET() { node "$HARNESS_HOME/lib/metrics.mjs" "$@"; }

missed=0 dry=0
for a in "$@"; do case $a in --if-missed) missed=1 ;; --dry-run) dry=1 ;;
  *) echo "usage: harness debrief [--if-missed] [--dry-run]" >&2; exit 2 ;; esac; done
mkdir -p "$Q"
log() { echo "$(date '+%F %T') $*" | tee -a "$Q/runner.log"; }   # what a debrief did: next to the runner's own lines
say() { echo "harness debrief: $*"; }                            # why it did nothing: stdout only
runner_alive() { [[ -f $Q/runner.pid ]] && kill -0 "$(cat "$Q/runner.pid")" 2>/dev/null; }
alive() { local p; p=$(cat "$1/driver.pid" 2>/dev/null) && [[ -n $p ]] && kill -0 "$p" 2>/dev/null; }

UP_LINE=$(grep -E '^[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9:]{8} runner up' "$Q/runner.log" 2>/dev/null | tail -1)
UP_TS=${UP_LINE:0:19} UP_EPOCH=0; [[ -n $UP_TS ]] && UP_EPOCH=$(date -d "$UP_TS" +%s)
SINCE=${UP_TS:-$(date -d '24 hours ago' '+%F %T')}   # no runner ever: the last day's runs
LAST=$(cut -f1 "$Q/last-debrief" 2>/dev/null || echo 0)

runs_since() {   # → state dirs of the runs whose driver started at or after $SINCE
  local d
  for d in "$STATE_ROOT"/*/*/; do
    [[ -f $d/meta.env && -f $d/run.log ]] || continue
    awk -v s="$SINCE" '/^[0-9-]+ [0-9:]+ run [^ ]+ on / && ($1 " " $2) >= s { f = 1; exit } END { exit !f }' "$d/run.log" \
      && echo "${d%/}"
  done
}
rec_dir() {   # state dir → the run's record: in its worktree, else the ledger's copy
  ( source "$1/meta.env"; local r=$WT/.harness/runs/$RUN_ID
    [[ -d $r ]] && echo "$r" || echo "$LEDGER/$(basename "$PROJECT_DIR")/$RUN_ID" )
}

STUCK=""
if (( missed )); then
  if runner_alive; then
    until=$(cat "$Q/runner.until" 2>/dev/null || echo 0); now=$(date +%s)
    if (( until > 0 && now > until + STUCK_AFTER )); then
      STUCK="Queue looks stuck: its runner (pid $(cat "$Q/runner.pid")) is still going $(( (now - until) / 60 )) min past its --until ($(date -d "@$until" '+%F %H:%M'))."
    else say "the queue runner is still running; nothing to do"; exit 0; fi
  elif [[ -z $UP_TS ]]; then say "no queue has run; nothing to do"; exit 0
  elif (( LAST >= UP_EPOCH )); then say "already debriefed since the last queue ($(cut -f2 "$Q/last-debrief")); nothing to do"; exit 0
  fi
fi
mapfile -t RUNS < <(runs_since)
if (( missed )) && [[ -z $STUCK ]] && (( ${#RUNS[@]} == 0 )); then
  say "no runs started since the last runner up ($UP_TS); nothing to do"; exit 0
fi

if (( ! dry )); then
  exec 9> "$STATE_ROOT/debrief.lock"
  flock -n 9 || { say "another debrief is running; nothing to do"; exit 0; }
  upto=$(cat "$STATE_ROOT/LIMIT_UNTIL" 2>/dev/null || echo 0); now=$(date +%s)
  if (( upto > now )); then
    if (( upto - now > MAX_WAIT )); then
      log "debrief: the usage-limit window is closed until $(date -d "@$upto" '+%F %H:%M'), past the 5 h cap; no debrief now (harness debrief --if-missed retries)"
      exit 0
    fi
    log "debrief: usage-limit window closed until $(date -d "@$upto" '+%H:%M'); waiting $(( (upto - now) / 60 )) min"
    sleep "${HARNESS_LIMIT_SLEEP:-$(( upto - now ))}"
  fi
fi

# ---- 1. the context, deterministically -------------------------------------------------------------------------
WS=$STATE_ROOT/debrief/$(date +%F-%H%M%S); mkdir -p "$WS"; CTX=$WS/context.md
fence() { echo '~~~'; cat; echo '~~~'; }
run_context() {   # state dir → this run's section
  ( source "$1/meta.env"
    local proj rd ended
    proj=$(basename "$PROJECT_DIR"); rd=$(rec_dir "$1")
    if alive "$1"; then ended="still running"; else ended=$(cat "$1/ended" 2>/dev/null || echo "not running, no end reason"); fi
    echo; echo "### $RUN_ID ($proj)"; echo
    echo "- ended: $ended"
    echo "- project: $PROJECT_DIR (its docs: CLAUDE.md, README.md, docs/) · branch harness/$RUN_ID"
    echo "- worktree: $WT$( [[ -d $WT ]] || echo ' (removed)') · run record: $rd · local state: $1"
    echo "- continuation queued: $(compgen -G "$Q/*-continue-$RUN_ID.args" > /dev/null && echo yes || echo no)"
    echo "- features: $(F summary "$rd/feature_list.json" 2>/dev/null || echo 'no feature list')"
    local f
    for f in summary.json report.md retro.md INBOX.md; do
      echo; echo "#### $f"
      if [[ ! -s $rd/$f ]]; then echo "(none)"
      elif [[ $f == *.json ]]; then { jq -c . "$rd/$f" 2>/dev/null || cat "$rd/$f"; } | fence
      else fence < "$rd/$f"; fi
    done
    echo; echo "#### Questions for Michael in progress.md (newest first)"
    grep -i 'question' "$rd/progress.md" 2>/dev/null | grep -viE 'none new|questions that are not|answers to the questions' | head -12 | fence
    echo; echo "#### harness-log.md: needs Michael, conflicts, refusals, holds"
    grep -iE 'needs Michael|conflict|refused|blocked|held' "$rd/harness-log.md" 2>/dev/null | tail -15 | fence
    echo; echo "#### harness-log.md (last 12 lines)"
    tail -n 12 "$rd/harness-log.md" 2>/dev/null | fence )
}
rate_info() {   # the newest rate-limit event in these runs' transcripts
  local d f files=() last line=""
  for d in "${RUNS[@]}"; do for f in "$d"/logs/*.jsonl; do [[ -f $f ]] && files+=("$f"); done; done
  while IFS= read -r f; do   # oldest first: the last one found is the newest
    last=$(grep -h '"type":"rate_limit_event"' "$f" | tail -1); [[ -n $last ]] && line=$last
  done < <( (( ${#files[@]} )) && ls -tr "${files[@]}")
  [[ -n $line ]] || { echo "none recorded"; return; }
  jq -r '.rate_limit_info | "status \(.status); " + ([.unifiedWindows // {} | to_entries[]
    | "\(.key) \((.value.utilization // 0) * 100 | round)% (resets \(.value.resetsAt | strflocaltime("%a %H:%M")))"] | join(", "))' <<< "$line" 2>/dev/null \
    || echo "$line"
}
spend() {
  local d rd total=0 c
  for d in "${RUNS[@]}"; do rd=$(rec_dir "$d"); c=$(jq -r '.cost.total // 0' "$rd/summary.json" 2>/dev/null || echo 0)
    total=$(jq -n "$total + ${c:-0}"); done
  echo "$total"
}
{
  echo "# Debrief context · $(date '+%F %H:%M')"
  echo
  echo "- Queue runner: ${UP_LINE:-no runner has started; this covers the runs of the last 24 h}"
  echo "- Runner now: $(runner_alive && echo "running (pid $(cat "$Q/runner.pid"), --until $(u=$(cat "$Q/runner.until" 2>/dev/null || echo 0); (( u )) && date -d "@$u" '+%F %H:%M' || echo none))" || echo "not running")"
  echo "- Runs started since $SINCE: ${#RUNS[@]}$( (( ${#RUNS[@]} )) && echo " ($(for d in "${RUNS[@]}"; do basename "$d"; done | paste -sd' ' -))")"
  echo "- Spend of these runs (summary.json cost.total, summed): \$$(spend)"
  upto=$(cat "$STATE_ROOT/LIMIT_UNTIL" 2>/dev/null || echo 0)
  echo "- Usage-limit window (LIMIT_UNTIL): $( (( upto > $(date +%s) )) && echo "closed until $(date -d "@$upto" '+%F %H:%M')" || echo "open$( (( upto )) && echo " (last closed until $(date -d "@$upto" '+%F %H:%M'))")")"
  echo "- Latest rate-limit info in these runs' sessions: $(rate_info)"
  [[ -n $STUCK ]] && echo "- **$STUCK**"
  echo; echo "## harness status"; echo; "$H" status 2>&1 | fence
  echo; echo "## harness trends"; echo; "$H" trends 2>&1 | fence
  echo; echo "## harness queue"; echo; "$H" queue list 2>&1 | fence
  echo; echo "## Queue runner.log since the last \"runner up\""; echo
  n=$(grep -nE '^[0-9-]{10} [0-9:]{8} runner up' "$Q/runner.log" 2>/dev/null | tail -1 | cut -d: -f1)
  { [[ -n $n ]] && tail -n "+$n" "$Q/runner.log" | tail -n 200; } | fence
  echo; echo "## Runs started since $SINCE"
  (( ${#RUNS[@]} )) || { echo; echo "(none)"; }
  for d in "${RUNS[@]}"; do run_context "$d"; done
  echo; echo "## Earlier retros (newest first; for proposals seen in two or more)"; echo
  ls -t "$LEDGER"/*/*/retro.md 2>/dev/null | head -20 | fence
} > "$CTX"

if (( dry )); then echo "$CTX"; echo; cat "$CTX"; exit 0; fi

# ---- 2. the session ---------------------------------------------------------------------------------------------
# The never-list, as far as flags can say it (prefix rules; `git -C … push` and the like are on the prompt).
DENY=(Edit Write NotebookEdit)
for h in harness "$H"; do
  for c in start continue merge gc init answer pause resume stop debrief "queue add" "queue start" "queue stop" "queue rm" "queue clear"; do
    DENY+=("Bash($h $c:*)"); done
done
DENY+=("Bash(git push:*)" "Bash(git commit:*)" "Bash(git merge:*)" "Bash(git rebase:*)" "Bash(git reset:*)"
  "Bash(git checkout:*)" "Bash(git switch:*)" "Bash(git restore:*)" "Bash(git stash:*)" "Bash(git tag:*)"
  "Bash(git branch -d:*)" "Bash(git branch -D:*)" "Bash(git branch -f:*)" "Bash(git branch -m:*)" "Bash(git worktree:*)"
  "Bash(gh pr merge:*)" "Bash(gh pr create:*)" "Bash(gh pr close:*)" "Bash(gh pr edit:*)" "Bash(gh pr review:*)"
  "Bash(gh pr comment:*)" "Bash(gh pr ready:*)" "Bash(gh api:*)" "Bash(gh repo:*)" "Bash(gh release:*)" "Bash(gh workflow:*)"
  "Bash(sudo:*)" "Bash(ssh:*)" "Bash(scp:*)" "Bash(rsync:*)" "Bash(docker:*)" "Bash(systemctl:*)" "Bash(kubectl:*)"
  "Bash(tmux:*)" "Bash(kill:*)" "Bash(pkill:*)" "Bash(rm:*)" "Bash(mv:*)" "Bash(cp:*)" "Bash(curl:*)" "Bash(wget:*)"
  "Bash(npm:*)" "Bash(npx:*)")
ADD=(--add-dir "$LEDGER")
for d in "${RUNS[@]}"; do
  while read -r x; do [[ -d $x ]] && ADD+=(--add-dir "$x"); done < <(source "$d/meta.env"; echo "$WT"; echo "$PROJECT_DIR")
done
MODEL=$(F model "$DEBRIEF_MODEL") STUCK_P=""
[[ -n $STUCK ]] && STUCK_P=$'\n'"**$STUCK** Start the headline with \"Queue looks stuck:\" and say what the runner is waiting on (its log, the running runs)."$'\n'
HARNESS_NOW=$(date '+%F %H:%M') HARNESS_LEDGER=$LEDGER HARNESS_STUCK=$STUCK_P \
  node "$HARNESS_HOME/lib/render.mjs" "$HARNESS_HOME/prompts/debrief.md" "Context=$CTX" > "$WS/prompt.md"
log "debrief · $MODEL · ${#RUNS[@]} run(s) since $SINCE$( [[ -n $STUCK ]] && echo ' · queue looks stuck') · $WS"
t0=$(date +%s)
( cd "$WS" && timeout "$SESSION_TIMEOUT" "$CLAUDE" -p "$(cat "$WS/prompt.md")" --model "$MODEL" --permission-mode auto \
    --max-turns 40 --max-budget-usd 3 "${ADD[@]}" --disallowedTools "${DENY[@]}" \
    --output-format stream-json --verbose > "$WS/session.jsonl" 2>&1 9>&- )
rc=$? wall=$(( $(date +%s) - t0 ))
if why=$(MET limit "$WS/session.jsonl" "$wall" "$rc"); then
  log "debrief: session refused (${why%%$'\t'*}); no note (harness debrief --if-missed retries)"; exit 1
fi
MET final "$WS/session.jsonl" > "$WS/final.md"
[[ -n $(tr -d '[:space:]' < "$WS/final.md") ]] || { log "debrief: the session wrote no note (exit $rc; $WS/session.jsonl)"; exit 1; }
COST=$(grep '^{' "$WS/session.jsonl" | jq -s '[.[] | select(.type == "result") | .total_cost_usd // 0] | max // 0' 2>/dev/null || echo "?")

# ---- 3. continuations, the note, the notification -----------------------------------------------------------------
continue_check() {   # run → nothing if it may be continued, else why not (exit 1)
  local run=$1 d="" x ended rd
  for x in "${RUNS[@]}"; do [[ $(basename "$x") == "$run" ]] && d=$x; done
  [[ -n $d ]] || { echo "not a run of this debrief"; return 1; }
  alive "$d" && { echo "still running"; return 1; }
  ended=$(cat "$d/ended" 2>/dev/null)
  [[ $ended == deadline* || $ended == "usage limit"* ]] || { echo "it ended '${ended%% · *}', not on its time or a usage limit"; return 1; }
  compgen -G "$Q/*-continue-$run.args" > /dev/null && { echo "a continuation is already queued"; return 1; }
  rd=$(rec_dir "$d")
  jq -e '.features.passing >= .features.total' "$rd/summary.json" > /dev/null 2>&1 && { echo "no work left"; return 1; }
  return 0
}
re='^CONTINUE:[[:space:]]*([A-Za-z0-9][A-Za-z0-9._-]*)[[:space:]]*(::[[:space:]]*(.*))?$'
while IFS= read -r line || [[ -n $line ]]; do
  if [[ $line =~ $re ]]; then
    run=${BASH_REMATCH[1]} brief=${BASH_REMATCH[3]} args=()
    [[ -n $brief ]] && args=(--brief "$brief")
    if why=$(continue_check "$run") && "$H" queue add --continue "$run" "${args[@]}" > /dev/null 2>&1; then
      echo "- Queued: \`harness continue $run\`${brief:+ with the brief \"$brief\"} (it starts when the queue runs)"
      log "debrief: queued a continuation of $run" >&2   # stdout is the note
    else echo "- Not queued: $run (${why:-harness queue add failed})"; fi
  else printf '%s\n' "$line"; fi
done < "$WS/final.md" > "$WS/body.md"
if [[ -n $STUCK ]] && ! grep -qi 'queue looks stuck' "$WS/body.md"; then   # the headline must say so
  if grep -qi '^## headline' "$WS/body.md"; then
    awk -v s="$STUCK" '{ print } !done && tolower($0) ~ /^## headline/ { print s; done = 1 }' "$WS/body.md" > "$WS/b.md"
  else { echo "## Headline"; echo "$STUCK"; echo; cat "$WS/body.md"; } > "$WS/b.md"; fi
  mv "$WS/b.md" "$WS/body.md"
fi
base=$(date +%F-%H%M); mkdir -p "$LEDGER/debriefs"
NOTE=$LEDGER/debriefs/$base.md i=1
while [[ -e $NOTE ]]; do i=$(( i + 1 )); NOTE=$LEDGER/debriefs/$base-$i.md; done
{ echo "# Debrief · $(date '+%F %H:%M')"; echo
  echo "_$( (( missed )) && echo "harness debrief --if-missed" || echo "harness debrief") · runs started since $SINCE: $(for d in "${RUNS[@]}"; do basename "$d"; done | paste -sd' ' - | sed 's/^$/none/') · $MODEL, \$$COST · context: ${CTX}_"
  echo; cat "$WS/body.md"; } > "$NOTE"
printf '%s\t%s\n' "$(date +%s)" "$NOTE" > "$Q/last-debrief"
if [[ $LEDGER_COMMIT == 1 ]] && git -C "$LEDGER" rev-parse --show-toplevel > /dev/null 2>&1; then
  ( flock 9; git -C "$LEDGER" add -- "$NOTE" && git -C "$LEDGER" commit -q -m "ledger: debrief $base" -- "$NOTE" ) 9> "$STATE_ROOT/ledger.lock" \
    || log "debrief: ledger commit skipped"
fi
log "debrief written: $NOTE ($MODEL, \$$COST)"

mapfile -t HL < <(awk '/^## / { if (on) exit; if (tolower($0) ~ /^## headline/) { on = 1; next } } on && NF' "$WS/body.md" | head -3)
(( ${#HL[@]} )) || mapfile -t HL < <(grep -v '^#' "$WS/body.md" | grep . | head -3)
HL[0]="[debrief] ${HL[0]:-}"
[[ -n $NOTIFY_CMD ]] && bash -c "$NOTIFY_CMD" _ "$(printf '%s\n' "${HL[@]}"; echo "$NOTE")" > /dev/null 2>&1
exit 0
