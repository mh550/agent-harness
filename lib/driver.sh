#!/usr/bin/env bash
# The harness driver (what `harness start` runs, in tmux or in the foreground). Deterministic glue around agent sessions:
#   1. no feature list → one initializer session writes it (from the spec files and the run's brief)
#   2. one fresh coding session per feature, in dependency order. Before each: take answers, sync with the remote,
#      honour pause/stop and the box-wide usage-limit window, run the project's init and the cached suite.
#      After each: a session that ended on a usage limit or API error is given back (not the feature's fault);
#      otherwise commit leftovers, repair the feature list, un-pass on a red suite, record metrics, push.
#   3. a milestone's features all pass → merge main into the run branch → one verify session re-runs every step and
#      writes an evidence row per step (too few rows: one more verify on a stronger model; still too few: not verified)
#      → the suite is green on that tree → tag the milestone → merge it into main through its own PR
#      (MERGE_POLICY=auto), or leave the PR for Michael (pr), or neither (off). A tag merges only if every commit in it
#      is verified work: milestones merge in list order, and a tag that contains another milestone's unverified
#      work, or predates main's latest commits, waits and merges with the next verified milestone.
#      A session that can't go on without Michael ends with "PARKED: <why>": the feature is parked (no attempt spent)
#      until INBOX.md's answers change, and work that doesn't depend on it goes on. Past WEEKLY_STOP_AT of the plan's
#      7-day window (as sessions report it), the run ends before its next coding session.
#      DESK=1: whatever needs Michael (a park, verify, a refused merge or conflict) also starts his desk (lib/desk.sh).
#   4. the end, whatever the reason: summary.json and report.md, a notification (blocked or waiting: the desk too), a
#      retro session, the harness ledger, and (after a session cap, within the run's --until) a continuation in the queue.
# Verify and retro sessions may not change code: whatever they change outside the run record (retro: anything) is
# reverted. A session that ends on a usage limit or API error keeps its commits but not its "passes".
# Environment (set by bin/harness): WT RUN_ID STATE PROJECT_DIR HARNESS_HOME
set -uo pipefail
: "${WT:?}" "${RUN_ID:?}" "${STATE:?}" "${PROJECT_DIR:?}" "${HARNESS_HOME:?}"
cd "$WT" || exit 1
# shellcheck source=lib/config.sh
source "$HARNESS_HOME/lib/config.sh"
# shellcheck source=lib/prompt.sh
source "$HARNESS_HOME/lib/prompt.sh"

prompt_vars   # PROJECT_NAME BRANCH RUN_DIR SCRATCH CHECK PORT
CLAUDE=${HARNESS_CLAUDE:-claude} GH=${HARNESS_GH:-gh}
F() { node "$HARNESS_HOME/lib/features.mjs" "$@"; }
MET() { node "$HARNESS_HOME/lib/metrics.mjs" "$@"; }
SUM() { node "$HARNESS_HOME/lib/summary.mjs" "$@"; }

LIST=$RUN_DIR/feature_list.json
LOGS=$STATE/logs ATT=$STATE/attempts.json PARKED=$STATE/parked.json
STATE_ROOT=$(cd "$STATE/../.." && pwd) LIMIT_FILE=$(cd "$STATE/../.." && pwd)/LIMIT_UNTIL USAGE=$(cd "$STATE/../.." && pwd)/USAGE_7D
LEDGER=${HARNESS_LEDGER:-$HARNESS_HOME/ledger}
mkdir -p "$LOGS" "$RUN_DIR" "$SCRATCH"
# The configuration comes from the worktree, so it is loaded again after a resumed run merges main (which may have
# changed .harness/config.sh, e.g. a new POLICY).
load_config() {
  harness_config "$WT" "$STATE"
  prompt_env   # the exports every session and template sees (lib/prompt.sh)
}
load_config
echo "$MAX_ATTEMPTS" > "$STATE/max-attempts"
T0=$(date +%s); DEADLINE=$(( T0 + HOURS * 3600 )); (( DEADLINE_AT > 0 && DEADLINE_AT < DEADLINE )) && DEADLINE=$DEADLINE_AT
rm -f "$STATE"/waited-*   # a restart inside a usage-limit window waits for it again

log() { echo "$(date '+%F %T') $*" | tee -a "$STATE/run.log"; }
note() { log "$*"; echo "- $(date '+%F %H:%M') · $*" >> "$RUN_DIR/harness-log.md"; }   # phone-readable, committed
# shellcheck source=lib/notify.sh
source "$HARNESS_HOME/lib/notify.sh"; NOTIFY_TAG=$RUN_ID   # notify "<message>" [title=… body=… click=… …]: "[<run>] <message>"
# shellcheck source=lib/deploy.sh
source "$HARNESS_HOME/lib/deploy.sh"   # deploy_status: hosts that would build every pushed run branch
source "$HARNESS_HOME/lib/version.sh"  # harness_version: the harness commit driving this segment, and whether it is dirty
commit_all() { git add -A && ! git diff --cached --quiet && git commit -q -m "$1"; return 0; }
green() { "$CHECK" > /dev/null 2>&1; }

# Revert what a session changed since <base> outside what it may change: "record" (the run record) or "nothing".
# Its commits stay in history; a new commit puts the files back. Prints what it reverted.
restrict() {   # base record|nothing who
  local base=$1 spec=(. ':!.harness/runs') st path
  [[ $2 == nothing ]] && spec=(.)
  commit_all "WIP: uncommitted at session end (harness)"
  while IFS=$'\t' read -r st path; do
    [[ -n $path ]] || continue
    if [[ $st == A ]]; then git rm -q --cached -- "$path" && rm -f -- "$path"; else git checkout -q "$base" -- "$path"; fi
    echo "$path"
  done < <(git diff --name-status --no-renames "$base" HEAD -- "${spec[@]}")
  commit_all "HARNESS: reverted edits a $3 session may not make"
}

[[ -z $BRANCH || $BRANCH == "$MAIN_BRANCH" ]] && { log "refusing to run on '${BRANCH:-detached HEAD}'"; exit 1; }
[[ -f $HARNESS_HOME/prompts/policy/$POLICY.md ]] || { log "unknown POLICY '$POLICY' (prompts/policy/*.md)"; exit 1; }

# `harness status` reads these: alive while driver.pid names a live process; why it ended in "ended".
echo $$ > "$STATE/driver.pid"; rm -f "$STATE/ended"
END_REASON="driver exited unexpectedly (see run.log)"
trap 'echo "$END_REASON · $(date "+%F %T")" > "$STATE/ended"; rm -f "$STATE/driver.pid"' EXIT

# Pull edits made on GitHub (INBOX.md from the phone), push local commits. Never rewrites history.
sync() {
  if git fetch -q origin "$BRANCH" 2>/dev/null; then
    git merge -q --ff-only "origin/$BRANCH" 2>/dev/null \
      || git merge -q --no-edit "origin/$BRANCH" > /dev/null 2>&1 \
      || { git merge --abort 2>/dev/null; log "remote edits on $BRANCH conflict with local work; kept local"; }
  fi
  git push -q -u origin "$BRANCH" 2>> "$STATE/run.log" || log "push of $BRANCH failed"
}

# Bring main's new commits into the run branch, so what is verified is what merges. 1 = conflict (left as it was).
sync_main() {
  git fetch -q origin "$MAIN_BRANCH" 2>/dev/null || return 0
  git merge-base --is-ancestor "origin/$MAIN_BRANCH" HEAD && return 0
  if git merge -q --no-edit "origin/$MAIN_BRANCH" > /dev/null 2>&1; then note "merged $MAIN_BRANCH into $BRANCH"; return 0; fi
  git merge --abort 2>/dev/null; note "$MAIN_BRANCH conflicts with $BRANCH; carrying on without it (merges into $MAIN_BRANCH need Michael)"
  return 1
}

# Answers typed locally (`harness answer`, the supervisor) are moved into INBOX.md so sessions see them.
take_answers() {
  [[ -s $STATE/inbox.md ]] || return 0
  { echo; echo "### $(date '+%F %H:%M') (local)"; cat "$STATE/inbox.md"; } >> "$RUN_DIR/INBOX.md"
  : > "$STATE/inbox.md"
  commit_all "HARNESS: answers from Michael"
}

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
  [[ -n $(git status --porcelain -- "$RUN_DIR") ]] && { commit_all "HARNESS: desk"; sync; }
  return 0
}

# The park's notification: the question the session wrote in INBOX.md and how to answer, with the INBOX one tap away.
notify_park() {
  local id=$1 why=$2 q body acts
  q=$(node "$NOTIFY_MJS" question "$STATE/inbox-before.md" "$RUN_DIR/INBOX.md" 2> /dev/null)
  body="PARKED: $why"$'\n\n'"${q:+$q$'\n\n'}Answer: harness answer $RUN_ID \"…\""
  acts=$(node "$NOTIFY_MJS" actions "Edit INBOX" "$(gh_url "$RUN_DIR/INBOX.md" edit)" "Answer with Claude" "$DESK_URL" Progress "$(gh_url "$RUN_DIR/progress.md")")
  notify "needs Michael: $id · $why" title="[$RUN_ID] $id needs you" priority=high tags=question click="$(gh_url "$RUN_DIR/INBOX.md")" actions="$acts" body="$body"
}

# What unparks a feature: Michael's answers changing (INBOX.md from "## Answers" on, local answers included).
answers_hash() { sed -n '/^## Answers/,$p' "$RUN_DIR/INBOX.md" 2> /dev/null | sha1sum | cut -c1-12; }

control() {   # → run | pause | stop
  local s; s=$(sed -n 's/^status:[[:space:]]*//p' "$RUN_DIR/INBOX.md" 2>/dev/null | head -1)
  if [[ -f $STATE/STOP || $s == stop* ]]; then echo stop
  elif [[ -f $STATE/PAUSE || $s == pause* ]]; then echo pause
  else echo run; fi
}

# One usage limit covers every run on the box: wait until the window that refused a session (any run's) is over.
limit_wait() {
  local upto now w; upto=$(cat "$LIMIT_FILE" 2>/dev/null || echo 0); now=$(date +%s)
  (( upto > now )) && [[ ! -f $STATE/waited-$upto ]] || return 0
  w=$(( upto - now )); (( w > DEADLINE - now )) && w=$(( DEADLINE - now )); (( w > 0 )) || return 0
  touch "$STATE/waited-$upto"
  note "usage-limit window (shared by all runs): waiting until $(date -d "@$upto" '+%H:%M') ($(( w / 60 )) min)"
  commit_all "HARNESS: waiting for the usage limit"; sync
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

session() {   # kind model log → runs claude headless on $STATE/prompt.md; sets S_EXIT and S_WALL
  local settings=() t0; t0=$(date +%s)
  cp "$STATE/prompt.md" "${3%.jsonl}.prompt.md"   # each session's prompt beside its transcript, so two can be diffed (decisions/2026-10-21-static-first-prompts)
  [[ -f $AGENT_SETTINGS ]] && settings=(--settings "$WT/$AGENT_SETTINGS")
  timeout "$SESSION_TIMEOUT" "$CLAUDE" -p "$(cat "$STATE/prompt.md")" --model "$2" --permission-mode auto "${settings[@]}" \
    --max-turns "$MAX_TURNS" --max-budget-usd "$SESSION_BUDGET_USD" --output-format stream-json --verbose > "$3" 2>&1
  S_EXIT=$? S_WALL=$(( $(date +%s) - t0 ))
  MET usage "$3" > "$USAGE.tmp" 2> /dev/null && mv "$USAGE.tmp" "$USAGE" || rm -f "$USAGE.tmp"   # the box-wide 7-day window
  log "  $1 exit $S_EXIT · $(git log --oneline -1)"
}

# <kind> <feature> <transcript> <model> <start commit> → the session's entry.json into entries.jsonl: the driver is its
# only writer (decisions/2026-10-22-journal-single-writer). Missing or invalid: a note and a minimal entry from git and
# the final message, whose outcome is what the list says now (the session's claim, before the driver's checks).
journal() {
  local kind=$1 id=$2 who=$2 outcome="not yet" name out rc; name=$(basename "$3" .jsonl)
  git diff --name-only --no-renames "$5" HEAD -- . ":!$RUN_DIR" > "$SCRATCH/entry-files"
  MET final "$3" > "$SCRATCH/entry-final" 2> /dev/null
  case $kind in
    coding) if F passes "$LIST" "$id"; then outcome=passes
            elif sed -n 's/^[[:space:]*`>-]*PARKED:[[:space:]]*//p' "$SCRATCH/entry-final" | grep -q .; then outcome=parked; fi ;;
    verify) who="verify $id"; F milestone-done "$LIST" "$id" && outcome=passes ;;
    init)   F summary "$LIST" > /dev/null 2>&1 && outcome=passes ;;
  esac
  out=$(node "$HARNESS_HOME/lib/entries.mjs" ingest "$RUN_DIR" "$kind" "$id" "$name" "$4" "$outcome" "$SCRATCH/entry-files" "$SCRATCH/entry-final"); rc=$?
  (( rc == 3 )) && note "$who: entry.json $out; recorded a minimal entry"
  (( rc == 0 || rc == 3 )) || { note "$who: the journal append failed (exit $rc): $out"   # aside, so the next session's ingest can't take it
    mv -f "$RUN_DIR/entry.json" "$SCRATCH/entry-failed-$name.json" 2> /dev/null; }
  return 0
}

run_init() {   # the project's init, then the suite (cached per code tree); both go into the next prompt
  HARNESS_PORT=$PORT HARNESS_SCRATCH=$SCRATCH bash -c "$INIT_CMD" > "$SCRATCH/init.out" 2>&1
  local rc=$?; echo "(init exit $rc)" >> "$SCRATCH/init.out"
  (( rc == 0 )) || log "  init exit $rc (the session is told to fix it first)"
  "$CHECK" >> "$SCRATCH/init.out" 2>&1 || log "  suite red before the session (the session is told to fix it first)"
  [[ -f $STATE/tests-start ]] || node "$HARNESS_HOME/lib/testcount.mjs" "$SCRATCH/check.out" | cut -d' ' -f1 | grep . > "$STATE/tests-start" \
    || rm -f "$STATE/tests-start"
}

pr_body() {   # milestone → the evidence a reviewer (or the record) needs
  echo "Milestone **$1** of harness run \`$RUN_ID\` (branch \`$BRANCH\`), verified by an independent session."
  echo; echo "**Features:**"; for id in $(F ids "$LIST" "$1"); do echo "- \`$id\` · $(jq -r --arg id "$id" '.features[]|select(.id==$id)|.description' "$LIST" 2>/dev/null)"; done
  echo; echo "**Run so far:** $(F summary "$LIST") · $(MET summary "$RUN_DIR/metrics.jsonl")"
  echo; echo "**Verify entry:**"; echo
  awk -v m="verify $1" 'index($0, "### ") == 1 { if (on) exit; if (index($0, m)) on = 1 } on' "$RUN_DIR/progress.md" | head -60
  echo; echo "Run record: \`$RUN_DIR/\` (progress.md, harness-log.md, feature_list.json, metrics.jsonl)."
}

verified_list() { local m out=(); for m in $(F milestones "$LIST"); do [[ -f $STATE/verified-$m ]] && out+=("$m"); done; (IFS=,; echo "${out[*]}"); }

# Merge one verified milestone (its tag) into main through a PR. The invariant: the tree that lands on main is the
# tree that was verified. 0 = merged or proposed · 1 = needs Michael (conflict, refusal) · 3 = held: main has content
# this milestone wasn't verified with (the next milestone's verify includes it, and its merge carries this one)
merge_one() {
  local m=$1 tag=run/$RUN_ID/$1 c head url tree
  head=harness-merge/$RUN_ID-$m
  c=$(git rev-list -n1 "$tag") || return 1
  git fetch -q origin "$MAIN_BRANCH" || return 1
  if git merge-base --is-ancestor "$c" "origin/$MAIN_BRANCH"; then touch "$STATE/merged-$m"; note "$m merged into $MAIN_BRANCH (already there)"; return 0; fi
  if ! tree=$(git merge-tree --write-tree "origin/$MAIN_BRANCH" "$c" 2>/dev/null | head -1); then
    # once per main: merge_milestones runs again after every verify and at the end
    [[ $(cat "$STATE/conflict-$m" 2>/dev/null) == "$(git rev-parse "origin/$MAIN_BRANCH")" ]] && return 1
    git rev-parse "origin/$MAIN_BRANCH" > "$STATE/conflict-$m"
    note "$m conflicts with $MAIN_BRANCH; not merged (needs Michael)"; commit_all "HARNESS: $m conflicts with $MAIN_BRANCH"; sync
    needs_you "$m" "conflicts with $MAIN_BRANCH" harness-log.md; return 1
  fi
  [[ $tree == "$(git rev-parse "$c^{tree}")" ]] || return 3
  git push -q -f origin "$c:refs/heads/$head" 2>> "$STATE/run.log" || { note "$m: push of $head failed (see run.log)"; return 1; }
  pr_body "$m" > "$STATE/pr-body.md"
  url=$($GH pr view "$head" --json url,state -q 'select(.state=="OPEN") | .url' 2>/dev/null) || url=""
  [[ $url == http* ]] || url=$($GH pr create --base "$MAIN_BRANCH" --head "$head" --title "$RUN_ID: $m (verified)" --body-file "$STATE/pr-body.md" 2>> "$STATE/run.log" | tail -1)
  [[ $url == http* ]] || { note "$m: could not open its PR (see run.log)"; return 1; }
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

# Merge verified milestones into main, in list order. Stops at the first milestone without a tag (later tags contain
# its commits). A tag that contains other milestones' unverified work (tainted-<m>) or predates main's latest commits
# is held, and counts as merged once a later milestone's merge carries it. v2 tags (verified under weaker rules)
# merge only through `harness merge`.
merge_milestones() {
  [[ $MERGE_POLICY == off || ! -f $LIST ]] && return 0
  local m pending=() p rc
  for m in $(F milestones "$LIST"); do
    [[ -f $STATE/merged-$m || -f $STATE/proposed-$m ]] && continue
    git rev-parse -q --verify "refs/tags/run/$RUN_ID/$m" > /dev/null || break
    if [[ ! ${HARNESS_MERGE_ONLY:-} ]] && ! git tag -l --format='%(contents:subject)' "run/$RUN_ID/$m" | grep -q '(v3'; then
      [[ -f $STATE/legacy-noted ]] || { touch "$STATE/legacy-noted"; note "$m was verified by harness v2; it merges only with: harness merge $RUN_ID"; }
      break
    fi
    if [[ -s $STATE/tainted-$m ]]; then pending+=("$m"); continue; fi
    merge_one "$m"; rc=$?
    (( rc == 3 )) && { pending+=("$m"); continue; }
    (( rc == 0 )) || break
    for p in "${pending[@]}"; do git merge-base --is-ancestor "$(git rev-list -n1 "run/$RUN_ID/$p")" "origin/$MAIN_BRANCH" 2>/dev/null \
      && { touch "$STATE/merged-$p"; note "$p merged into $MAIN_BRANCH with $m"; }; done
    pending=()
  done
  (( ${#pending[@]} )) && [[ ! -f $STATE/held-${pending[-1]} ]] && { touch "$STATE/held-${pending[-1]}"
    note "held: ${pending[*]} (its tag contains another milestone's unverified work, or main has changes it wasn't verified with); it merges with the next verified milestone"; }
  return 0
}

# Independently re-check milestone m. 0 = verified (tagged) · 1 = not verified · 2 = deferred (a usage limit: retry)
verify() {
  local m=$1 out vlog rounds model short before vstart reverted result=fail need="" failed=()
  rounds=$(( $(cat "$STATE/verify-rounds-$m" 2>/dev/null || echo 0) + 1 ))
  sync_main || touch "$STATE/nomerge-$m"
  run_init
  for model in "$VERIFY_MODEL" "$VERIFY_ESCALATE_MODEL"; do
    F snapshot "$LIST" > "$STATE/before.json"
    before=$(grep -c "^### .*verify $m\b" "$RUN_DIR/progress.md" 2>/dev/null); vstart=$(git rev-parse HEAD)
    HARNESS_CLOCK=$(clock "verify round $rounds of $MAX_VERIFY_ROUNDS") HARNESS_MILESTONE=$m HARNESS_FEATURES=$(F ids "$LIST" "$m" | paste -sd' ') prompt verify
    vlog="$LOGS/$(date +%H%M%S)-verify-$m.jsonl"
    log "verify $m · $(F model "$model")"
    session verify "$(F model "$model")" "$vlog"
    reverted=$(restrict "$vstart" record verify | paste -sd' ')
    [[ -n $reverted ]] && note "verify $m: reverted code edits the verifier may not make: $reverted"
    journal verify "$m" "$vlog" "$(F model "$model")" "$vstart"   # before the limit branch: a refused verify is journaled too
    if why=$(MET limit "$vlog" "$S_WALL" "$S_EXIT"); then   # refused: no verdict, and no "holds" by default
      cp "$STATE/before.json" "$LIST"; node -e 'const f=process.argv[1],fs=require("fs");fs.writeFileSync(f,JSON.stringify(JSON.parse(fs.readFileSync(f)),null,2)+"\n")' "$LIST"
      MET append "$vlog" "$RUN_DIR/metrics.jsonl" "$RUN_ID" verify "$m" "$(F model "$model")" false "$S_WALL" "$S_EXIT" true verify
      local upto; upto=$(( ${why##*$'\t'} > 0 ? ${why##*$'\t'} + 120 : $(date +%s) + 900 ))
      (( upto > $(cat "$LIMIT_FILE" 2>/dev/null || echo 0) )) && echo "$upto" > "$LIMIT_FILE"
      note "verify $m refused (${why%%$'\t'*}); deferred until $(date -d "@$upto" '+%H:%M')"
      commit_all "HARNESS: verify $m deferred"; sync; return 2
    fi
    out=$(F repair-verify "$LIST" "$STATE/before.json" "$m") || note "verify $m: reverted list edits beyond un-passing: $out"
    MET append "$vlog" "$RUN_DIR/metrics.jsonl" "$RUN_ID" verify "$m" "$(F model "$model")" \
      "$(F milestone-done "$LIST" "$m" && echo true || echo false)" "$S_WALL" "$S_EXIT" false verify
    F milestone-done "$LIST" "$m" || { result=fail; break; }
    if (( $(grep -c "^### .*verify $m\b" "$RUN_DIR/progress.md" 2>/dev/null) <= before )); then short="no new verify entry in progress.md"
    elif short=$(F evidence "$LIST" "$m" "$RUN_DIR/progress.md"); then result=hold; break; fi
    [[ $model == "$VERIFY_ESCALATE_MODEL" ]] && { result=thin; break; }
    note "verify $m: evidence short of the steps ($short); re-running on $VERIFY_ESCALATE_MODEL"
  done
  echo "$rounds" > "$STATE/verify-rounds-$m"
  if [[ $result == hold ]] && ! green; then result=red; fi
  case $result in
    hold)
      touch "$STATE/verified-$m"
      F touched-outside "$LIST" "$ATT" "$m" "$(verified_list)" > "$STATE/tainted-$m"
      git tag -a "run/$RUN_ID/$m" -m "harness run $RUN_ID: $m verified (v3)" 2>/dev/null \
        && git push -q origin "run/$RUN_ID/$m" 2>> "$STATE/run.log"
      note "$m verified and tagged run/$RUN_ID/$m$( [[ -s $STATE/tainted-$m ]] && echo " (contains unverified work of $(paste -sd, "$STATE/tainted-$m"): held until that is verified)")"
      commit_all "HARNESS: $m verified"; sync
      [[ -f $STATE/nomerge-$m ]] || merge_milestones
      return 0 ;;
    thin) touch "$STATE/needs-$m"; note "verify $m: evidence still short of the steps ($short) after $VERIFY_ESCALATE_MODEL; not verified (needs Michael)"
      need="verify evidence too thin" ;;
    red) touch "$STATE/needs-$m"; note "verify $m: the suite is red on the verified tree (main merged in); not verified (needs Michael)"
      need="suite red after merging main" ;;
    fail)
      for id in $(F ids "$LIST" "$m"); do
        F passes "$LIST" "$id" && continue
        if (( rounds < MAX_VERIFY_ROUNDS )); then
          note "verify $m: $id failed the re-check, back in the queue (one more attempt)"; F grant "$ATT" "$id" "$MAX_ATTEMPTS"
        else
          touch "$STATE/needs-$m"; note "verify $m: $id failed the re-check in round $rounds of $MAX_VERIFY_ROUNDS; $m needs Michael (see progress.md)"
          failed+=("$id")
        fi
      done
      if (( ${#failed[@]} == 1 )); then need="${failed[0]} fails verification"
      elif (( ${#failed[@]} )); then need=$(printf '%s, ' "${failed[@]}"); need="${need%, } fail verification"; fi ;;
  esac
  commit_all "HARNESS: verify $m"; sync
  [[ -n $need ]] && needs_you "$m" "$need" progress.md   # after the push: the click shows the verify entry
  return 1
}

# Verify every milestone that is complete and not yet verified, in order. 2 = a verify was deferred by a limit.
verify_ready() {
  local m rc
  for m in $(F milestones "$LIST"); do
    [[ -f $STATE/verified-$m || -f $STATE/needs-$m ]] && continue
    F milestone-done "$LIST" "$m" || continue
    verify "$m"; rc=$?
    (( rc == 2 )) && return 2
  done
  return 0
}

retro() {   # a short read-only session that turns this run's evidence into proposed harness changes
  local rlog=$LOGS/zz-retro-$(date +%H%M%S).jsonl rstart reverted
  rstart=$(git rev-parse HEAD)
  HARNESS_SUMMARY=$RUN_DIR/summary.json HARNESS_STATE=$STATE HARNESS_LEDGER=$LEDGER prompt retro
  log "retro · $(F model "$RETRO_MODEL")"
  MAX_TURNS=40 SESSION_BUDGET_USD=3 session retro "$(F model "$RETRO_MODEL")" "$rlog"
  reverted=$(restrict "$rstart" nothing retro | paste -sd' ')
  [[ -n $reverted ]] && note "retro: reverted edits (it is read-only): $reverted"
  MET final "$rlog" > "$SCRATCH/retro.md"
  [[ -s $SCRATCH/retro.md ]] && ! MET limit "$rlog" "$S_WALL" "$S_EXIT" > /dev/null && cp "$SCRATCH/retro.md" "$RUN_DIR/retro.md"
  MET append "$rlog" "$RUN_DIR/metrics.jsonl" "$RUN_ID" retro "" "$(F model "$RETRO_MODEL")" true "$S_WALL" "$S_EXIT" false retro
}

ledger() {   # the whole run record into the harness's own record, for `harness trends`, retros and calibration
  local d=$LEDGER/$PROJECT_NAME/$RUN_ID
  mkdir -p "$d" && cp -r "$RUN_DIR/." "$d/"
  (
    flock 9
    SUM ledger-line "$RUN_DIR/summary.json" "$LEDGER/runs.jsonl"
    if [[ $LEDGER_COMMIT == 1 ]] && git -C "$LEDGER" rev-parse --show-toplevel > /dev/null 2>&1; then
      git -C "$LEDGER" add -- "$d" "$LEDGER/runs.jsonl" \
        && git -C "$LEDGER" commit -q -m "ledger: $RUN_ID ($PROJECT_NAME): $(F summary "$LIST")" -- "$d" "$LEDGER/runs.jsonl" \
        || log "ledger commit skipped"
    fi
  ) 9> "$STATE_ROOT/ledger.lock"
}

finish() {   # reason → summary, notification, retro, ledger, continuation
  END_REASON=$1
  echo "$1 · $(date '+%F %T')" > "$STATE/ended"   # now, not at exit: the summary reads it
  note "run ended ($1): $(F summary "$LIST" 2>/dev/null) · $(MET summary "$RUN_DIR/metrics.jsonl")"
  merge_milestones
  green; node "$HARNESS_HOME/lib/testcount.mjs" "$SCRATCH/check-$(node "$HARNESS_HOME/lib/treekey.mjs").out" | cut -d' ' -f1 | grep . > "$STATE/tests-end" \
    || rm -f "$STATE/tests-end"
  SUM build "$WT" "$RUN_ID" "$STATE" > "$RUN_DIR/summary.json"
  SUM report "$RUN_DIR/summary.json" > "$RUN_DIR/report.md"   # the end notification's click; rewritten after the retro
  commit_all "HARNESS: run ended ($1)"; sync
  # the run's one end notification goes out now, not after the retro (minutes, and a crash there would lose it).
  # The reasons below are Michael's to act on: the report, the INBOX one tap away
  local pri="" acts="" sum
  case $1 in "blocked on"* | "waiting on Michael"* | "feature-list edits"* | "initializer failed"*)
    pri=high acts=$(node "$NOTIFY_MJS" actions "Edit INBOX" "$(gh_url "$RUN_DIR/INBOX.md" edit)" Progress "$(gh_url "$RUN_DIR/progress.md")") ;;
  esac
  sum="$(F summary "$LIST" 2>/dev/null) · $(jq -r '"$\(.cost.total) · $\(.cost.per_passing_feature) per passing feature"' "$RUN_DIR/summary.json" 2>/dev/null)"
  notify "ended ($1): $sum" title="[$RUN_ID] ended: $1" priority=$pri click="$(gh_url "$RUN_DIR/report.md")" actions="$acts"
  # a failed post notes it in harness-log.md: commit it now, before a retro that may never finish
  [[ -n $(git status --porcelain -- "$RUN_DIR") ]] && { commit_all "HARNESS: run-end notification failed"; sync; }
  case $1 in "blocked on"* | "waiting on Michael"*) desk "ended: $1" ;; esac   # after that commit: its note is no failed post
  if [[ $RETRO == 1 && -f $LIST ]]; then retro; SUM build "$WT" "$RUN_ID" "$STATE" > "$RUN_DIR/summary.json"; fi
  SUM report "$RUN_DIR/summary.json" > "$RUN_DIR/report.md"
  commit_all "HARNESS: summary and retro"; sync
  ledger
  # Only a session cap continues by itself (time and Michael's stops don't), within the run's --until, at most
  # AUTO_CONTINUE_MAX times, without giving given-up features new attempts.
  local left conts; left=$(F next "$LIST" "$ATT" "$MAX_ATTEMPTS" "$PARKED" 2>/dev/null); conts=$(cat "$STATE/auto-continues" 2>/dev/null || echo 0)
  if [[ -n $left && $AUTO_CONTINUE == 1 && $1 == session\ cap* ]] && (( conts < ${AUTO_CONTINUE_MAX:-3} )) \
     && (( DEADLINE_AT == 0 || $(date +%s) < DEADLINE_AT - 600 )); then
    echo $(( conts + 1 )) > "$STATE/auto-continues"
    "$HARNESS_HOME/bin/harness" queue add --continue "$RUN_ID" --keep-attempts $( (( DEADLINE_AT )) && echo "--until-epoch $DEADLINE_AT") > /dev/null 2>&1 \
      && note "continuation queued ($(( conts + 1 )) of ${AUTO_CONTINUE_MAX:-3}; it starts when the queue runs)"
  fi
  # a note after the last commit (the continuation): commit it too, or the worktree stays dirty and gc skips it
  [[ -n $(git status --porcelain -- "$RUN_DIR") ]] && { commit_all "HARNESS: run end notes"; sync; }
  log "run kept in $WT on $BRANCH · report: harness report $RUN_ID · continue: harness continue $RUN_ID"
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
[[ -f $RUN_DIR/INBOX.md ]] || cat > "$RUN_DIR/INBOX.md" <<EOF
status: run
<!-- Steer this run from the GitHub app: edit this file on branch $BRANCH.
     Change the first line to "status: pause" or "status: stop"; write answers to questions under "## Answers".
     The harness pulls before every session; every session reads this file at startup. -->

## Answers
EOF
if [[ -s $STATE/brief.md ]]; then   # a brief given at start or continue: committed, so sessions and the record see it
  { [[ -s $RUN_DIR/brief.md ]] && echo; echo "## $(date '+%F %H:%M')"; cat "$STATE/brief.md"; } >> "$RUN_DIR/brief.md"
  : > "$STATE/brief.md"
fi
commit_all "HARNESS: start run $RUN_ID"
sync
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
  commit_all "HARNESS: merge"; sync; END_REASON="merge only"; exit 0
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

if [[ ! -f $LIST ]]; then
  run_init
  HARNESS_CALIBRATION=$(SUM calibration "$LEDGER" "$PROJECT_NAME" 2>/dev/null) prompt initializer
  log "initializer · $(F model "$INIT_MODEL")"
  istart=$(git rev-parse HEAD)
  session init "$(F model "$INIT_MODEL")" "$LOGS/00-init.jsonl"
  commit_all "WIP: initializer — uncommitted at session end (harness)"
  journal init init "$LOGS/00-init.jsonl" "$(F model "$INIT_MODEL")" "$istart"   # a failed or refused initializer too
  if ! F summary "$LIST" > /dev/null 2>&1; then
    if why=$(MET limit "$LOGS/00-init.jsonl" "$S_WALL" "$S_EXIT"); then note "initializer refused: ${why%%$'\t'*}"; finish "usage limit before the feature list"; fi
    note "initializer did not produce a valid $LIST; stopping"; finish "initializer failed"
  fi
  MET append "$LOGS/00-init.jsonl" "$RUN_DIR/metrics.jsonl" "$RUN_ID" init "" "$(F model "$INIT_MODEL")" true "$S_WALL" "$S_EXIT" false init
  note "feature list written: $(F summary "$LIST")"; commit_all "HARNESS: initializer done"; sync
  notify "started: $(F summary "$LIST")" click="$(gh_url "$RUN_DIR/progress.md")"
fi

if [[ ! -f $STATE/deps-noted ]]; then   # once per run: milestones that wait on everything before them
  u=$(F undeclared "$LIST")
  [[ -n $u ]] && note "dependencies: $u $( [[ $u == *,* ]] && echo have || echo has) no after list, so $( [[ $u == *,* ]] && echo each waits || echo it waits) on every earlier feature (one given up or parked there stops it)"
  touch "$STATE/deps-noted"
fi
[[ $MAX_SESSIONS == auto ]] && MAX_SESSIONS=$(( 3 * $(jq '.features | length' "$LIST") + 5 ))
repairs=0 n=0 limits=0
while :; do
  (( n >= MAX_SESSIONS )) && finish "session cap ($MAX_SESSIONS)"
  (( $(date +%s) >= DEADLINE )) && { note "deadline reached"; finish "deadline"; }
  take_answers; sync
  for id in $(F unpark "$PARKED" "$(answers_hash)"); do note "$id unparked: INBOX.md has new answers"; done
  c=$(control)
  if [[ $c == pause ]]; then
    log "paused (INBOX.md status or harness pause)"; notify "paused"
    while [[ $(control) == pause ]]; do
      (( $(date +%s) >= DEADLINE )) && { note "deadline reached while paused"; finish "deadline (paused)"; }
      sleep "${HARNESS_PAUSE_POLL:-60}"; take_answers; sync
    done
    log "resumed"; continue
  fi
  [[ $c == stop ]] && { note "stopped by Michael"; finish "stopped by Michael"; }
  limit_wait
  (( $(date +%s) >= DEADLINE )) && continue
  verify_ready || continue   # 2 = deferred by a usage limit: wait for the window first
  if why=$(weekly_over "$USAGE"); then note "stopping before the next session: $why"; finish "weekly budget ($why)"; fi

  next=$(F next "$LIST" "$ATT" "$MAX_ATTEMPTS" "$PARKED")
  if [[ -z $next ]]; then
    [[ $(F summary "$LIST") =~ ^([0-9]+)/([0-9]+) && ${BASH_REMATCH[1]} == "${BASH_REMATCH[2]}" ]] && { note "every feature passes"; finish "done"; }
    parked=$(F parked "$PARKED" "$LIST" | cut -f1 | paste -sd, -)
    blocked=$(F blocked "$LIST" "$ATT" "$MAX_ATTEMPTS" "$PARKED" | awk -F'\t' '{print $2}' | sort -u | grep -vxF -f <(tr , '\n' <<< "$parked") | paste -sd, -)
    ends=()
    if [[ -n $blocked ]]; then note "blocked: the remaining features wait on $blocked (given up; needs Michael)"; ends+=("blocked on $blocked"); fi
    if [[ -n $parked ]]; then note "waiting on Michael: $parked (parked; answer in INBOX.md, then harness continue $RUN_ID)"; ends+=("waiting on Michael: $parked"); fi
    if (( ${#ends[@]} )); then finish "$(printf '%s; ' "${ends[@]}" | sed 's/; $//')"; fi
    note "no feature left to try: $(F summary "$LIST")"; finish "no feature left to try"
  fi
  IFS=$'\t' read -r id mdl milestone <<< "$next"
  n=$(( n + 1 ))
  F bump "$ATT" "$id"; F snapshot "$LIST" > "$STATE/before.json"
  run_init
  HARNESS_CLOCK=$(clock "attempt $(jq -r --arg id "$id" '.[$id] // 0' "$ATT") of $MAX_ATTEMPTS") HARNESS_FEATURE=$id HARNESS_MILESTONE=$milestone prompt coding
  log "session $n · $id · $mdl"
  slog="$LOGS/$(printf '%02d' "$n")-$id.jsonl"
  cp "$RUN_DIR/INBOX.md" "$STATE/inbox-before.md" 2> /dev/null || : > "$STATE/inbox-before.md"   # what the session adds is the park's question
  sstart=$(git rev-parse HEAD)
  session coding "$mdl" "$slog"
  commit_all "WIP: $id — uncommitted at session end (harness)"
  journal coding "$id" "$slog" "$mdl" "$sstart"   # before the limit branch and F repair: every session is journaled

  # A usage/rate limit, an API error or a session that did no work is not the feature's fault: give the attempt back.
  if why=$(MET limit "$slog" "$S_WALL" "$S_EXIT"); then
    IFS=$'\t' read -r reason reset <<< "$why"
    F unbump "$ATT" "$id"; n=$(( n - 1 )); limits=$(( limits + 1 ))
    # its work stays (committed above); its claims don't: the list goes back to the snapshot, "passes" included
    F repair "$LIST" "$STATE/before.json" "$id" > /dev/null; F passes "$STATE/before.json" "$id" || F unpass "$LIST" "$id"
    MET append "$slog" "$RUN_DIR/metrics.jsonl" "$RUN_ID" coding "$id" "$mdl" false "$S_WALL" "$S_EXIT" true
    if (( limits >= MAX_LIMIT_HITS )); then
      note "$limits sessions in a row refused ($reason)"
      finish "usage limit ($limits sessions refused in a row)"
    fi
    read -ra waits <<< "$LIMIT_WAITS"; w=${waits[$(( limits > ${#waits[@]} ? ${#waits[@]} - 1 : limits - 1 ))]}
    upto=$(( ${reset:-0} > 0 ? reset + 120 : $(date +%s) + w ))
    (( upto > $(cat "$LIMIT_FILE" 2>/dev/null || echo 0) )) && echo "$upto" > "$LIMIT_FILE"
    (( limits == 1 )) && notify "refused ($reason); waiting until $(date -d "@$upto" '+%H:%M')"
    note "session for $id hit a limit ($reason); not counted; resuming at $(date -d "@$upto" '+%H:%M')"
    commit_all "HARNESS: usage limit"; sync
    continue
  fi
  limits=0

  if out=$(F repair "$LIST" "$STATE/before.json" "$id"); then repairs=0; else
    repairs=$(( repairs + 1 )); note "restored the feature list after $id: $out"
    (( repairs >= MAX_REPAIRS )) && { note "$repairs sessions in a row edited the feature list; stopping for Michael"; finish "feature-list edits"; }
  fi
  if F passes "$LIST" "$id" && ! green; then F unpass "$LIST" "$id"; note "$id un-passed: suite red after the session"; fi
  passed=$(F passes "$LIST" "$id" && echo true || echo false)
  MET append "$slog" "$RUN_DIR/metrics.jsonl" "$RUN_ID" coding "$id" "$mdl" "$passed" "$S_WALL" "$S_EXIT" false "$(F kind "$LIST" "$id")"
  note "$id · $mdl · passes=$passed · $(( S_WALL / 60 )) min · $(F summary "$LIST")"
  if [[ $passed == false ]] && why=$(MET final "$slog" | sed -n 's/^[[:space:]*`>-]*PARKED:[[:space:]]*//p' | head -1) && [[ -n $why ]]; then
    F unbump "$ATT" "$id"; F park "$PARKED" "$id" "$(answers_hash)" "$why"   # waiting on Michael is not the feature's fault
    note "$id parked (waiting on Michael): $why"
  else why=""; fi
  commit_all "HARNESS: after $id (passes=$passed)"; sync
  if [[ -n $why ]]; then   # after the push, so its links show the question; a failed post's note is committed too
    notify_park "$id" "$why"; [[ -n $(git status --porcelain -- "$RUN_DIR") ]] && { commit_all "HARNESS: park notification failed"; sync; }
    desk "$id parked: $why"
  fi

done
