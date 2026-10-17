#!/usr/bin/env bash
# `harness debrief [--dry-run]`: after a queue, one short read-only session reviews what happened and tells Michael,
# so nobody has to open a session to triage. The queue runner starts it, detached, as it exits (if it started a run);
# Michael can run it by hand any time (that is the fallback).
#   Which runs: every run whose driver started since the last successful debrief (queue/last-debrief, written only
#   when a note was produced), so a debrief that failed, was refused or was killed is covered by the next one. The
#   first debrief ever covers the runs since the newest "runner up".
#   1. debrief.lock (a second debrief waits for the first, then covers only what is left), the preflight (node, jq,
#      git, flock, claude), the usage-limit window (LIMIT_UNTIL): waits up to 5 h, longer: exits, the next one covers it
#   2. bash gathers the context, no model: status, trends, the queue, runner.log, and for every run: why it ended,
#      summary.json, report.md, retro.md, INBOX.md, open questions, each capped
#   3. one headless session (DEBRIEF_MODEL), prompt on stdin, in dontAsk mode with an allowlist of read-only tools and
#      the never-list as --disallowedTools; git status and refs of the ledger, worktrees and projects compared after
#   4. its "CONTINUE: <run> :: <brief>" lines are checked here and queued (`harness queue add --continue … --keep-attempts`);
#      the note overwrites <ledger>/debrief.md (git history is the archive); NOTIFY_CMD gets its headline and path
# --dry-run: print the context only.
set -uo pipefail
: "${HARNESS_HOME:?}"
STATE_ROOT=${HARNESS_STATE:-${XDG_STATE_HOME:-$HOME/.local/state}/harness} Q=${HARNESS_STATE:-${XDG_STATE_HOME:-$HOME/.local/state}/harness}/queue
H=$HARNESS_HOME/bin/harness CLAUDE=${HARNESS_CLAUDE:-claude} LEDGER=${HARNESS_LEDGER:-$HARNESS_HOME/ledger}
NOTE=$LEDGER/debrief.md MAX_WAIT=$(( 5 * 3600 )) LOCK_WAIT=$(( 7 * 3600 ))

dry=0
for a in "$@"; do case $a in --dry-run) dry=1 ;; *) echo "usage: harness debrief [--dry-run]" >&2; exit 2 ;; esac; done
mkdir -p "$Q"
log() { echo "$(date '+%F %T') $*" | tee -a "$Q/runner.log"; }   # what a debrief did: next to the runner's own lines
say() { echo "harness debrief: $*"; }                            # why it did nothing: stdout only

# A detached or cron-like start may not have Michael's PATH (node comes from nvm, claude from ~/.local/bin).
missing() { local c m=(); for c in node jq git flock "$CLAUDE"; do command -v "$c" > /dev/null 2>&1 || m+=("$c"); done; echo "${m[*]}"; }
if [[ -n $(missing) ]]; then
  # shellcheck source=/dev/null
  [[ -s ${NVM_DIR:-$HOME/.nvm}/nvm.sh ]] && { set +u; . "${NVM_DIR:-$HOME/.nvm}/nvm.sh" > /dev/null 2>&1; set -u; }
  PATH=$HOME/.local/bin:$PATH
  [[ -z $(missing) ]] || { log "debrief: cannot run, missing: $(missing) (PATH=$PATH)"; exit 1; }
fi
# shellcheck source=lib/config.sh
source "$HARNESS_HOME/lib/config.sh"; harness_config /nonexistent   # defaults + the user's config
F() { node "$HARNESS_HOME/lib/features.mjs" "$@"; }
MET() { node "$HARNESS_HOME/lib/metrics.mjs" "$@"; }
alive() { local p; p=$(cat "$1/driver.pid" 2>/dev/null) && [[ -n $p ]] && kill -0 "$p" 2>/dev/null; }
rec_dir() {   # state dir → the run's record: in its worktree, else the ledger's copy
  ( source "$1/meta.env"; local r=$WT/.harness/runs/$RUN_ID
    [[ -d $r ]] && echo "$r" || echo "$LEDGER/$(basename "$PROJECT_DIR")/$RUN_ID" )
}

if (( ! dry )); then
  exec 9> "$STATE_ROOT/debrief.lock"
  flock -w "$LOCK_WAIT" 9 || { log "debrief: another debrief held the lock for 7 h; giving up"; exit 1; }
fi

# ---- which runs: since the last successful debrief (decided under the lock) --------------------------------------
SINCE=$(cut -f2 "$Q/last-debrief" 2>/dev/null)
if [[ -z $SINCE ]]; then   # the first debrief: since the newest "runner up" (else the last day)
  SINCE=$(grep -E '^[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9:]{8} runner up' "$Q/runner.log" 2>/dev/null | tail -1 | cut -c1-19)
  [[ -n $SINCE ]] || SINCE=$(date -d '24 hours ago' '+%F %T')
fi
RUNS=()
for d in "$STATE_ROOT"/*/*/; do
  [[ -f $d/meta.env && -f $d/run.log ]] || continue
  awk -v s="$SINCE" '/^[0-9-]+ [0-9:]+ run [^ ]+ on / && ($1 " " $2) >= s { f = 1; exit } END { exit !f }' "$d/run.log" && RUNS+=("${d%/}")
done
(( ${#RUNS[@]} )) || { say "no runs started since the last debrief ($SINCE); nothing to do"; exit 0; }

if (( ! dry )); then
  upto=$(cat "$STATE_ROOT/LIMIT_UNTIL" 2>/dev/null || echo 0); now=$(date +%s)
  if (( upto > now )); then
    if (( upto - now > MAX_WAIT )); then
      log "debrief: the usage-limit window is closed until $(date -d "@$upto" '+%F %H:%M'), past the 5 h cap; no debrief now (the next one covers these runs; or run harness debrief later)"
      exit 0
    fi
    log "debrief: usage-limit window closed until $(date -d "@$upto" '+%H:%M'); waiting $(( (upto - now) / 60 )) min"
    sleep "${HARNESS_LIMIT_SLEEP:-$(( upto - now ))}"
  fi
fi

# ---- the context, deterministically (every part capped: it all goes into one prompt) ------------------------------
STARTED=$(date '+%F %T')   # becomes the next debrief's "since" if this one produces a note…
for d in "${RUNS[@]}"; do   # …or a still-running run's start, so the next debrief sees how it ended
  alive "$d" || continue
  t=$(awk -v s="$SINCE" '/^[0-9-]+ [0-9:]+ run [^ ]+ on / && ($1 " " $2) >= s { t = $1 " " $2 } END { print t }' "$d/run.log")
  [[ -n $t && $t < $STARTED ]] && STARTED=$t
done
WS=$STATE_ROOT/debrief/$(date +%F-%H%M%S); mkdir -p "$WS"; CTX=$WS/context.md
fence() { echo '~~~'; cat; echo '~~~'; }
capped() {   # bytes file [tail] → the file's head (or tail), with a note when cut
  local n; n=$(wc -c < "$2")
  if [[ ${3:-} == tail ]]; then tail -c "$1" "$2"; else head -c "$1" "$2"; fi
  (( n > $1 )) && printf '\n… (cut: %s of %s bytes shown; the whole file: %s)\n' "$1" "$n" "$2"
  return 0
}
run_context() {   # state dir → this run's section
  ( source "$1/meta.env"
    local proj rd ended f
    proj=$(basename "$PROJECT_DIR"); rd=$(rec_dir "$1")
    if alive "$1"; then ended="still running"; else ended=$(cat "$1/ended" 2>/dev/null || echo "not running, no end reason"); fi
    echo; echo "### $RUN_ID ($proj)"; echo
    echo "- ended: $ended"
    echo "- project: $PROJECT_DIR (its docs: CLAUDE.md, README.md, docs/) · branch harness/$RUN_ID"
    echo "- worktree: $WT$( [[ -d $WT ]] || echo ' (removed)') · run record: $rd · local state: $1"
    echo "- started by a queue runner: $( [[ -s $1/runners ]] && echo yes || echo 'no (by hand)') · continuation queued: $(compgen -G "$Q/*-continue-$RUN_ID.args" > /dev/null && echo yes || echo no)"
    echo "- features: $(F summary "$rd/feature_list.json" 2>/dev/null || echo 'no feature list')"
    echo; echo "#### harness status"; N=3 "$H" status "$RUN_ID" 2>&1 | head -c 3000 | fence
    for f in summary.json:12000 report.md:8000 retro.md:6000 INBOX.md:4000; do
      echo; echo "#### ${f%%:*}"
      if [[ ! -s $rd/${f%%:*} ]]; then echo "(none)"
      elif [[ $f == summary.json:* ]]; then jq -c . "$rd/summary.json" > "$WS/s.json" 2>/dev/null || cp "$rd/summary.json" "$WS/s.json"
        capped "${f##*:}" "$WS/s.json" | fence
      elif [[ $f == INBOX.md:* ]]; then capped "${f##*:}" "$rd/INBOX.md" tail | fence
      else capped "${f##*:}" "$rd/${f%%:*}" | fence; fi
    done
    echo; echo "#### Questions for Michael in progress.md (newest first)"
    grep -i 'question' "$rd/progress.md" 2>/dev/null | grep -viE 'none new|questions that are not|answers to the questions' | head -12 | cut -c1-600 | fence
    echo; echo "#### harness-log.md: needs Michael, conflicts, refusals, holds"
    grep -iE 'needs Michael|conflict|refused|blocked|held' "$rd/harness-log.md" 2>/dev/null | tail -15 | cut -c1-400 | fence
    echo; echo "#### harness-log.md (last 12 lines)"
    tail -n 12 "$rd/harness-log.md" 2>/dev/null | cut -c1-400 | fence )
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
    || echo "${line:0:400}"
}
spend() {
  local d c total=0
  for d in "${RUNS[@]}"; do c=$(jq -r '.cost.total // 0' "$(rec_dir "$d")/summary.json" 2>/dev/null || echo 0); total=$(jq -n "$total + ${c:-0}"); done
  echo "$total"
}
names() { local d; for d in "${RUNS[@]}"; do basename "$d"; done | paste -sd' ' -; }
{
  echo "# Debrief context · $(date '+%F %H:%M')"
  echo
  echo "- Covers: every run whose driver started since $SINCE (the last debrief, or the queue runner's start): ${#RUNS[@]} ($(names))"
  echo "- Queue runner now: $( [[ -f $Q/runner.pid ]] && kill -0 "$(cat "$Q/runner.pid")" 2>/dev/null && echo "going (pid $(cat "$Q/runner.pid"))" || echo "not running")"
  echo "- Spend of these runs (summary.json cost.total, summed): \$$(spend)"
  upto=$(cat "$STATE_ROOT/LIMIT_UNTIL" 2>/dev/null || echo 0)
  echo "- Usage-limit window (LIMIT_UNTIL): $( (( upto > $(date +%s) )) && echo "closed until $(date -d "@$upto" '+%F %H:%M')" || echo "open$( (( upto )) && echo " (last closed until $(date -d "@$upto" '+%F %H:%M'))")")"
  echo "- Latest rate-limit info in these runs' sessions: $(rate_info)"
  echo; echo "## harness status (these runs; each one's section below has more)"; echo
  for d in "${RUNS[@]}"; do N=1 "$H" status "$(basename "$d")" 2>&1 | head -1; done | fence
  echo; echo "## harness trends (last 40 lines)"; echo; "$H" trends 2>&1 | tail -n 40 | cut -c1-400 | fence
  echo; echo "## harness queue"; echo; "$H" queue list 2>&1 | head -n 60 | cut -c1-400 | fence
  echo; echo "## Queue runner.log since $SINCE (last 200 lines)"; echo
  awk -v s="$SINCE" 'on || (/^[0-9-]+ [0-9:]+ / && ($1 " " $2) >= s) { on = 1; print }' "$Q/runner.log" 2>/dev/null | tail -n 200 | cut -c1-400 | fence
  echo; echo "## Runs"
  for d in "${RUNS[@]}"; do run_context "$d"; done
  echo; echo "## Earlier retros (newest first; for proposals seen in two or more)"; echo
  ls -t "$LEDGER"/*/*/retro.md 2>/dev/null | head -20 | fence
} > "$CTX"

if (( dry )); then echo "$CTX"; echo; cat "$CTX"; exit 0; fi

# ---- the session ------------------------------------------------------------------------------------------------
# THE SCOPE, in one place. The session runs with --permission-mode dontAsk: only what ALLOW lists can run, and DENY
# wins over ALLOW. v1 is strictly read-only. To widen the scope (e.g. let it write a draft file), add to ALLOW here,
# take the matching entry out of DENY, and say so in prompts/debrief.md.
HB=(harness "$H")   # harness as Michael types it, and by its full path
ALLOW=(
  Read Grep Glob                                                     # files: read only
  "Bash(cd:*)" "Bash(ls:*)" "Bash(cat:*)" "Bash(head:*)" "Bash(tail:*)" "Bash(wc:*)" "Bash(grep:*)" "Bash(rg:*)"
  "Bash(jq:*)" "Bash(date:*)"
  "Bash(git log:*)" "Bash(git show:*)" "Bash(git diff:*)" "Bash(git status:*)" "Bash(git branch:*)"
  "Bash(git rev-parse:*)" "Bash(git rev-list:*)" "Bash(git merge-base:*)" "Bash(git for-each-ref:*)"
  "Bash(git ls-files:*)" "Bash(git grep:*)"
  "Bash(gh pr view:*)" "Bash(gh pr list:*)" "Bash(gh pr checks:*)"     # PRs: look only
  "Bash(${HB[0]} status:*)" "Bash(${HB[0]} trends:*)" "Bash(${HB[0]} queue list:*)" "Bash(${HB[0]} report:*)"
  "Bash(${HB[1]} status:*)" "Bash(${HB[1]} trends:*)" "Bash(${HB[1]} queue list:*)" "Bash(${HB[1]} report:*)"
)
DENY=(Edit Write NotebookEdit                                       # the never-list, as far as prefix rules go
  "Bash(git push:*)" "Bash(git commit:*)" "Bash(git merge:*)" "Bash(git rebase:*)" "Bash(git reset:*)"
  "Bash(git checkout:*)" "Bash(git switch:*)" "Bash(git restore:*)" "Bash(git stash:*)" "Bash(git tag:*)"
  "Bash(git branch -d:*)" "Bash(git branch -D:*)" "Bash(git branch -f:*)" "Bash(git branch -m:*)" "Bash(git worktree:*)"
  "Bash(gh pr merge:*)" "Bash(gh pr create:*)" "Bash(gh pr close:*)" "Bash(gh pr edit:*)" "Bash(gh pr review:*)"
  "Bash(gh pr comment:*)" "Bash(gh pr ready:*)" "Bash(gh api:*)" "Bash(gh repo:*)" "Bash(gh release:*)" "Bash(gh workflow:*)"
  "Bash(sudo:*)" "Bash(ssh:*)" "Bash(scp:*)" "Bash(rsync:*)" "Bash(docker:*)" "Bash(systemctl:*)" "Bash(kubectl:*)"
  "Bash(tmux:*)" "Bash(kill:*)" "Bash(pkill:*)" "Bash(rm:*)" "Bash(mv:*)" "Bash(cp:*)" "Bash(curl:*)" "Bash(wget:*)"
  "Bash(npm:*)" "Bash(npx:*)")
for h in "${HB[@]}"; do
  for c in start continue merge gc init answer pause resume stop debrief "queue add" "queue start" "queue stop" "queue rm" "queue clear"; do
    DENY+=("Bash($h $c:*)"); done
done
ADD=(--add-dir "$LEDGER") WATCH=()
LTOP=$(git -C "$LEDGER" rev-parse --show-toplevel 2>/dev/null) && WATCH+=("$LTOP")
for d in "${RUNS[@]}"; do
  while read -r x; do [[ -d $x ]] && { ADD+=(--add-dir "$x"); WATCH+=("$x"); }; done < <(source "$d/meta.env"; echo "$WT"; echo "$PROJECT_DIR")
done
snapshot() {   # what a read-only session must not change: each repo's files, HEAD and refs
  local d
  while IFS= read -r d; do
    git -C "$d" status --porcelain 2>/dev/null | sed "s|^|$d: |"
    git -C "$d" for-each-ref --format="$d: %(refname) %(objectname)" 2>/dev/null
    echo "$d: HEAD $(git -C "$d" rev-parse HEAD 2>/dev/null)"
  done < <(printf '%s\n' "${WATCH[@]}" | sort -u)
}
MODEL=$(F model "$DEBRIEF_MODEL")
HARNESS_NOW=$(date '+%F %H:%M') HARNESS_LEDGER=$LEDGER HARNESS_SINCE=$SINCE \
  node "$HARNESS_HOME/lib/render.mjs" "$HARNESS_HOME/prompts/debrief.md" "Context=$CTX" > "$WS/prompt.md"
log "debrief · $MODEL · ${#RUNS[@]} run(s) since $SINCE · $WS"
snapshot > "$WS/before.txt"
t0=$(date +%s)
( cd "$WS" && timeout "$SESSION_TIMEOUT" "$CLAUDE" -p --model "$MODEL" --permission-mode dontAsk \
    --max-turns 40 --max-budget-usd 3 "${ADD[@]}" --allowedTools "${ALLOW[@]}" --disallowedTools "${DENY[@]}" \
    --output-format stream-json --verbose < "$WS/prompt.md" > "$WS/session.jsonl" 2>&1 9>&- )
rc=$? wall=$(( $(date +%s) - t0 ))
snapshot > "$WS/after.txt"
if why=$(MET limit "$WS/session.jsonl" "$wall" "$rc"); then   # refused: no note; the window is shared with every run
  upto=$(( ${why##*$'\t'} > 0 ? ${why##*$'\t'} + 120 : $(date +%s) + 900 ))
  (( upto > $(cat "$STATE_ROOT/LIMIT_UNTIL" 2>/dev/null || echo 0) )) && echo "$upto" > "$STATE_ROOT/LIMIT_UNTIL"
  log "debrief: session refused (${why%%$'\t'*}); no note (the next debrief covers these runs)"; exit 1
fi
result=$(grep '^{' "$WS/session.jsonl" | jq -rs '[.[] | select(.type == "result")] | last // {} | "\(.subtype // "no result") \(.is_error // false)"' 2>/dev/null)
[[ $result == "success false" ]] || { log "debrief: the session failed ($result, exit $rc); no note ($WS/session.jsonl)"; exit 1; }
MET final "$WS/session.jsonl" > "$WS/final.md"
[[ -n $(tr -d '[:space:]' < "$WS/final.md") ]] || { log "debrief: the session wrote no note (exit $rc; $WS/session.jsonl)"; exit 1; }
COST=$(grep '^{' "$WS/session.jsonl" | jq -s '[.[] | select(.type == "result") | .total_cost_usd // 0] | max // 0' 2>/dev/null || echo "?")

# ---- continuations, the note, the notification -------------------------------------------------------------------
continue_check() {   # run → nothing if it may be continued, else why not (exit 1)
  local run=$1 d="" x ended
  for x in "${RUNS[@]}"; do [[ $(basename "$x") == "$run" ]] && d=$x; done
  [[ -n $d ]] || { echo "not a run of this debrief"; return 1; }
  alive "$d" && { echo "still running"; return 1; }
  ended=$(cat "$d/ended" 2>/dev/null)
  [[ $ended == deadline* || $ended == "usage limit"* ]] || { echo "it ended '${ended%% · *}', not on its time or a usage limit"; return 1; }
  compgen -G "$Q/*-continue-$run.args" > /dev/null && { echo "a continuation is already queued"; return 1; }
  jq -e '.features.passing >= .features.total' "$(rec_dir "$d")/summary.json" > /dev/null 2>&1 && { echo "no work left"; return 1; }
  return 0
}
re='^[-*>`[:space:]]*CONTINUE:[[:space:]]*([A-Za-z0-9][A-Za-z0-9._-]*)[[:space:]]*(::[[:space:]]*(.*))?$'
while IFS= read -r line || [[ -n $line ]]; do
  if [[ $line =~ $re ]]; then
    run=${BASH_REMATCH[1]} brief=$(sed 's/[`[:space:]]*$//' <<< "${BASH_REMATCH[3]}")
    # attempts are kept (a given-up feature stays given up, Michael's holds stay); the brief says whose it is
    args=(--keep-attempts --brief "Suggested by the debrief of $(date '+%F %H:%M') (not Michael's words): ${brief:-continue where it stopped}")
    if why=$(continue_check "$run") && "$H" queue add --continue "$run" "${args[@]}" > /dev/null 2>&1 9>&-; then
      echo "- Queued: \`harness continue $run --keep-attempts\`${brief:+ with the brief \"$brief\"} (it starts when the queue runs)"
      log "debrief: queued a continuation of $run" >&2   # stdout is the note
    else echo "- Not queued: $run (${why:-harness queue add failed})"; fi
  else printf '%s\n' "$line"; fi
done < "$WS/final.md" > "$WS/body.md"
CHANGED=$(diff "$WS/before.txt" "$WS/after.txt" | grep '^[<>]')
if [[ -n $CHANGED ]]; then
  { echo; echo "## Warning: changed during the debrief session"; echo
    echo "The debrief is read-only, yet these changed while it ran (the session, or something else on the box):"
    echo '~~~'; head -n 40 <<< "$CHANGED"; echo '~~~'; } >> "$WS/body.md"
  log "debrief: files or refs changed during the session: $(wc -l <<< "$CHANGED") line(s); see the note"
fi
mkdir -p "$LEDGER"
{ echo "# Debrief · $(date '+%F %H:%M')"; echo
  echo "_runs since $SINCE: $(names) · $MODEL, \$$COST · context: ${CTX}_"
  echo; cat "$WS/body.md"; } > "$NOTE"
printf '%s\t%s\n' "$(date +%s)" "$STARTED" > "$Q/last-debrief"   # only now: a failed or killed debrief changes nothing
if [[ $LEDGER_COMMIT == 1 && -n $LTOP ]]; then
  ( flock 9; git -C "$LEDGER" add -- "$NOTE" && git -C "$LEDGER" commit -q -m "ledger: debrief $(date '+%F %H:%M')" -- "$NOTE" ) 9> "$STATE_ROOT/ledger.lock" \
    || log "debrief: ledger commit skipped"
fi
log "debrief written: $NOTE ($MODEL, \$$COST)"

mapfile -t HL < <(awk '/^## / { if (on) exit; if (tolower($0) ~ /^## headline/) { on = 1; next } } on && NF' "$WS/body.md" | head -3)
(( ${#HL[@]} )) || mapfile -t HL < <(grep -v '^#' "$WS/body.md" | grep . | head -3)
HL[0]="[debrief] ${HL[0]:-}"
[[ -n $NOTIFY_CMD ]] && bash -c "$NOTIFY_CMD" _ "$(printf '%s\n' "${HL[@]}"; echo "$NOTE")" > /dev/null 2>&1 9>&-
exit 0
