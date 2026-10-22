#!/usr/bin/env bash
# Usage: harness eval run [--set <name|file>] [--harness <ref>] [--label <L>] [--repeat <N>]  ·  harness eval compare <A> <B>
# Replays a set of tasks (evals/tasks/<id>/task.json) with one harness version's driver: the ref is checked out into a
# temporary worktree, and each task runs on a fresh clone of its repo at its base, with a local bare origin, its own
# state, worktree, scratch, ledger and config roots, and nothing that can post or merge (plan:
# docs/plans/2026-10-21-E2-evals.md §3, decisions/2026-10-21-eval-run-isolation). Results land in
# evals/results/<stamp>-<short sha>-<label>/. Every task is real sessions, so it costs money: Michael runs it.
# Money and time: no task starts once the tasks have spent EVAL_BUDGET_USD, or while the plan's 7-day window (the real
# state root's USAGE_7D, or the eval's own) is past WEEKLY_STOP_AT; past it at the start, nothing is created at all.
# --repeat N runs every task N times (r1 of each task, then r2 …), each on a fresh clone, into <task>/r<N>/.
# compare reads two results dirs (a path, or a name under evals/results/) and prints, per task and in total, pass rate,
# $ and tokens per verified feature, cache hit rate, orientation, context peak, wall time and rework, each with B's
# verdict against A: better, worse, within noise (the spread across repeats), one sample or no data. It spends nothing.
set -uo pipefail
HARNESS_HOME=${HARNESS_HOME:-$(cd "$(dirname "$(readlink -f "$0")")/.." && pwd)}
# shellcheck source=lib/version.sh
source "$HARNESS_HOME/lib/version.sh"
# shellcheck source=lib/config.sh
source "$HARNESS_HOME/lib/config.sh"
EV() { node "$HARNESS_HOME/lib/eval.mjs" "$@"; }
die() { echo "harness eval: $*" >&2; exit 1; }
say() { echo "$*" | tee -a "$R/eval.log"; }

# A set is a file, or the name of one under evals/sets/; each line an id under evals/tasks/ or a task.json path
# (relative to the set file). `#` starts a comment.
set_tasks() {
  local f=$1 l
  while IFS= read -r l || [[ -n $l ]]; do
    l=${l%%#*}; l=${l#"${l%%[![:space:]]*}"}; l=${l%"${l##*[![:space:]]}"}
    [[ -n $l ]] || continue
    if [[ $l == */* || $l == *.json ]]; then [[ $l == /* ]] && echo "$l" || echo "$(dirname "$f")/$l"
    else echo "$HARNESS_HOME/evals/tasks/$l/task.json"; fi
  done < "$f"
}

# The lines that keep an eval run from touching or reaching anything real. They go in the runs' user config (so
# Michael's ~/.config/harness/config.sh, its notifications and models stay out, and A/B runs share the defaults) and
# in each run's run.env, which beats a project's own .harness/config.sh (a live-staged POLICY, a merge policy).
safety() {
  echo "POLICY=build-only MERGE_POLICY=off PR_POLICY=off RETRO=0 AUTO_CONTINUE=0 DESK=0 LEDGER_COMMIT=0"
  echo "NTFY_URL='' NTFY_TOKEN='' NOTIFY_CMD='' DESK_URL='' DEBRIEF_PAGE_CMD=''"
  printf 'LIVE_LOCK=%q\n' "$E/live.lock"
  echo "WEEKLY_STOP_AT=$WEEKLY_STOP_AT"   # the eval's own threshold, so a task's driver stops where the eval would
}

write_json() {   # eval.json, rewritten after every task so an interrupted eval still has its record
  local spent; spent=$(EV spent "$R") || spent=null
  jq -n --arg stamp "$STAMP" --arg ref "$REF" --arg sha "$SHA" --arg label "$LABEL" --arg set "$SET" --arg e "$E" \
    --arg h "$E/harness" --argjson repeat "$REPEAT" --argjson cap "$EVAL_BUDGET_USD" --argjson spent "$spent" \
    --arg text "$BUDGET_TEXT" --arg weekly "$WEEKLY" --slurpfile tasks "$E/tasks.jsonl" \
    '{ stamp: $stamp, ref: $ref, sha: $sha, label: $label, set: $set, repeat: $repeat, eval_dir: $e, harness_dir: $h,
       budget: ({ cap: $cap, spent: $spent, not_started: $ARGS.positional } + if $text == "" then {} else { text: $text } end),
       weekly: (if $weekly == "" then null else $weekly end), tasks: $tasks }' --args ${NOT_STARTED[@]+"${NOT_STARTED[@]}"} \
    > "$R/eval.json"
}

unit() {   # <task.json> <repeat> → the unit's name: its result dir under $R and its dir under $E (<id>, or <id>/r<N>)
  local id; id=$(jq -r .id "$1"); (( REPEAT > 1 )) && echo "$id/r$2" || echo "$id"
}

# A usage limit a real run hit holds for the eval too: the eval's driver waits on $E/state/LIMIT_UNTIL, not the real one.
share_limit() {
  local real own; real=$(cat "$STATE_REAL/LIMIT_UNTIL" 2> /dev/null || echo 0) own=$(cat "$E/state/LIMIT_UNTIL" 2> /dev/null || echo 0)
  [[ $real =~ ^[0-9]+$ && $own =~ ^[0-9]+$ ]] && (( real > own && real > $(date +%s) )) || return 0
  echo "$real" > "$E/state/LIMIT_UNTIL" && say "the usage limit until $(date -d "@$real" '+%a %H:%M') holds for this eval too"
}

run_task() {   # <task.json> <repeat> → one replay; its record in $R/<unit>/ and a line in eval.json
  local tf=$1 rp=$2 id project repo base run u d o clone st res rc=null spec brief v f cost=null end=""
  id=$(jq -r .id "$tf") project=$(jq -r .project "$tf") repo=$(jq -r .repo "$tf") base=$(jq -r .base "$tf") u=$(unit "$tf" "$rp")
  repo=${repo/#\~/$HOME} run=eval-${u//\//-} d=$E/$u
  o=$d/origin.git clone=$d/$project st=$E/state/$project/$run res=$R/$u
  local wt=$E/wt/$project/$run
  mkdir -p "$d" "$res"
  # the clone reads <repo> and never writes it; dropping its origin drops every ref of the source but main = base
  if git init -q --bare -b main "$o" && git clone -q --no-checkout "$repo" "$clone" && git -C "$clone" checkout -q -B main "$base" \
     && git -C "$clone" remote remove origin && git -C "$clone" remote add origin "$o" && git -C "$clone" push -q -u origin main; then
    # the run branch carries the task's feature list already, so cmd_start takes origin/harness/<run> and the
    # driver skips the initializer; the clone itself goes back to main (cmd_start adds the run's worktree on the branch)
    mkdir -p "$clone/.harness/runs/$run"
    if git -C "$clone" checkout -q -b "harness/$run" && EV seed "$tf" "$run" > "$clone/.harness/runs/$run/feature_list.json" \
       && printf '# Progress — eval task %s\n\nReplayed by `harness eval run` (harness %s), from %s at %s.\n' "$id" "$SHA" "$repo" "$base" \
          > "$clone/.harness/runs/$run/progress.md" \
       && git -C "$clone" add ".harness/runs/$run" && git -C "$clone" commit -q -m "EVAL: seed $id" \
       && git -C "$clone" push -q -u origin "harness/$run" && git -C "$clone" checkout -q main; then
      # the port is chosen here, not by cmd_start: there a project's BASE_PORT wins, and the ports real runs hold
      # (in the real state root) can't be seen, so eval runs keep to 7900 and up
      local port=7900; mkdir -p "$st"
      while (echo > "/dev/tcp/127.0.0.1/$port") 2> /dev/null || grep -qsx "$port" "$E"/state/*/*/port; do port=$(( port + 1 )); done
      echo "$port" > "$st/port"
      { safety; v=$(jq -r '.check_cmd // empty' "$tf"); [[ -n $v ]] && printf 'CHECK_CMD=%q\n' "$v"
        v=$(jq -r '.model // empty' "$tf"); [[ -n $v ]] && printf 'WORKER_MODEL=%q\n' "$v"; } > "$st/run.env"
      local args=(--foreground --no-supervisor)
      spec=$(jq -r '.spec // empty' "$tf") brief=$(jq -r '.brief // empty' "$tf")
      [[ -n $spec ]] && args+=(--spec "$spec"); [[ -n $brief ]] && args+=(--brief "$brief")
      [[ -n $spec || -n $brief ]] || args+=(--brief "Eval task $id: build the features in feature_list.json.")
      say "task $u: run $run on $clone (base ${base:0:12})"
      # HARNESS_EVAL_GH/CURL: the suite's logging stubs; otherwise any call that slipped through fails instead of posting
      env -u TMUX -u TMUX_PANE -u HARNESS_MERGE_ONLY -u HARNESS_RUNNER_ID \
        HARNESS_STATE="$E/state" HARNESS_WORKTREES="$E/wt" HARNESS_SCRATCH_ROOT="$E/scratch" HARNESS_LEDGER="$E/ledger" \
        HARNESS_CONFIG="$E/config.sh" HARNESS_GH="${HARNESS_EVAL_GH:-false}" HARNESS_CURL="${HARNESS_EVAL_CURL:-false}" \
        HARNESS_NO_RUNNER=1 HARNESS_EVAL=1 \
        "$E/harness/bin/harness" start "$clone" "$run" "${args[@]}" > "$res/start.log" 2>&1
      rc=$?   # logged, never fatal: the next task goes on
      for f in summary.json metrics.jsonl harness-log.md feature_list.json progress.md; do
        [[ -f $wt/.harness/runs/$run/$f ]] && cp "$wt/.harness/runs/$run/$f" "$res/"; done
      cost=$(jq '.cost.total // null' "$res/summary.json" 2> /dev/null) || cost=null
      end=$(jq -r '.end_reason // ""' "$res/summary.json" 2> /dev/null)
      say "task $u: exit $rc · $(node "$HARNESS_HOME/lib/features.mjs" summary "$res/feature_list.json" 2> /dev/null) · \$$cost · ended: ${end:-?}"
    else end="seeding failed" SKIPPED=$(( SKIPPED + 1 )); say "task $u: seeding harness/$run failed; skipped"; fi
  else end="clone failed" SKIPPED=$(( SKIPPED + 1 )); say "task $u: cloning $repo at $base failed; skipped"; fi
  jq -cn --arg id "$id" --arg run "$run" --arg p "$project" --arg c "$clone" --arg w "$wt" --arg s "$st" --arg end "$end" \
    --argjson rc "$rc" --argjson cost "${cost:-null}" --argjson rp "$rp" --arg u "$u" \
    '{ id: $id, repeat: $rp, run: $run, project: $p, clone: $c, worktree: $w, state: $s, result: $u, exit: $rc, cost: $cost,
       end_reason: $end }' >> "$E/tasks.jsonl"
  write_json
}

cmd_run() {
  SET=default REF=HEAD LABEL=adhoc REPEAT=1
  while (( $# )); do case $1 in
    --set) SET=${2:?--set needs a name or file}; shift 2 ;; --harness) REF=${2:?--harness needs a ref}; shift 2 ;;
    --label) LABEL=${2:?--label needs a value}; shift 2 ;; --repeat) REPEAT=${2:?--repeat needs a count}; shift 2 ;;
    *) die "unknown option $1 (usage: harness eval run [--set <name|file>] [--harness <ref>] [--label <L>] [--repeat <N>])" ;; esac; done
  [[ $LABEL =~ ^[A-Za-z0-9._-]+$ ]] || die "label: letters, digits, . _ - only"
  [[ $REPEAT =~ ^[1-9][0-9]*$ ]] || die "--repeat: a whole number from 1"
  # the eval command's own config: the harness defaults and Michael's user config (no project), read in a subshell so
  # nothing it exports reaches the runs; a cap in the environment wins, so a command line can set it from the estimate
  local cap=${EVAL_BUDGET_USD:-}
  read -r EVAL_BUDGET_USD WEEKLY_STOP_AT < <(harness_config /dev/null; echo "$EVAL_BUDGET_USD $WEEKLY_STOP_AT")
  [[ -n $cap ]] && EVAL_BUDGET_USD=$cap
  [[ $EVAL_BUDGET_USD =~ ^[0-9]+(\.[0-9]+)?$ ]] || die "EVAL_BUDGET_USD: dollars, e.g. 10 or 2.5 (not '$EVAL_BUDGET_USD')"
  [[ $WEEKLY_STOP_AT =~ ^[0-9]+$ ]] || die "WEEKLY_STOP_AT: a percentage (not '$WEEKLY_STOP_AT')"
  local sf=$SET tasks=() tf repo dup why rp spent stopped=""
  [[ $SET == */* ]] || sf=$HARNESS_HOME/evals/sets/$SET.txt   # a bare name is a set under evals/sets/, a path a file
  [[ -f $sf ]] || die "no set '$SET' (a file, or evals/sets/<name>.txt)"
  mapfile -t tasks < <(set_tasks "$sf")
  (( ${#tasks[@]} )) || die "set '$SET' names no task"
  # everything that can be checked is checked before any spend: the schema, unique ids, each repo has its base
  EV validate "${tasks[@]}" >&2 || die "set '$SET' has invalid tasks (above); nothing started"
  dup=$(for tf in "${tasks[@]}"; do jq -r .id "$tf"; done | sort | uniq -d | head -1)
  [[ -z $dup ]] || die "task '$dup' is in set '$SET' twice; nothing started"
  for tf in "${tasks[@]}"; do
    case $(jq -r .id "$tf") in harness|state|wt|scratch|ledger) die "task id '$(jq -r .id "$tf")' is one of the eval's own dirs; nothing started" ;; esac
    repo=$(jq -r .repo "$tf"); repo=${repo/#\~/$HOME}
    [[ ! -d $repo ]] || git -C "$repo" cat-file -e "$(jq -r .base "$tf")^{commit}" 2> /dev/null \
      || die "$(jq -r .id "$tf"): $repo has no commit $(jq -r .base "$tf"); nothing started"
  done
  git -C "$HARNESS_HOME" rev-parse -q --verify "$REF^{commit}" > /dev/null || die "no commit '$REF' in $HARNESS_HOME"
  # older drivers read neither HARNESS_CONFIG nor run.env nor HARNESS_CURL (P1-02): the safety lines wouldn't hold
  git -C "$HARNESS_HOME" merge-base --is-ancestor 77546619318521b9d8d264b5eb99451cda81b3fa "$REF" 2> /dev/null \
    || die "$REF predates 7754661 (P1-02), the first driver an eval can isolate; nothing started"
  # the plan's 7-day window as real runs see it (the real state root): past WEEKLY_STOP_AT, nothing is created
  STATE_REAL=${HARNESS_STATE:-${XDG_STATE_HOME:-$HOME/.local/state}/harness} WEEKLY="" BUDGET_TEXT="" NOT_STARTED=()
  if why=$(weekly_over "$STATE_REAL/USAGE_7D"); then die "$why; nothing started"; fi

  STAMP=$(date +%Y%m%d-%H%M%S); E=$(realpath -m "${HARNESS_EVAL_TMP:-/tmp/harness-eval}/$STAMP") SKIPPED=0
  mkdir -p "${E%/*}" && mkdir "$E" 2> /dev/null || die "$E exists (another eval this second?)"
  git -C "$HARNESS_HOME" worktree add -q --detach "$E/harness" "$REF" || die "can't check $REF out into $E/harness"
  # the worktree is registered in the harness repo: remove it whatever happens (INT/TERM exit, so EXIT runs)
  trap '[[ -d $E/harness ]] && git -C "$HARNESS_HOME" worktree remove --force "$E/harness"' EXIT
  trap 'exit 130' INT TERM
  harness_version "$E/harness"; SHA=$HARNESS_VERSION
  R=$(realpath -m "${HARNESS_EVAL_RESULTS:-$HARNESS_HOME/evals/results}/$STAMP-$SHA-$LABEL")
  mkdir -p "$R" "$E/state" && : > "$E/tasks.jsonl" && safety > "$E/config.sh" && write_json || die "can't write $R"
  say "eval $STAMP · set $SET (${#tasks[@]} tasks × $REPEAT) · label $LABEL · budget \$$EVAL_BUDGET_USD"
  say "harness $REF ($SHA) in $E/harness"
  # repeat-major, so a stop leaves each task with as many samples as the others, or one fewer; a running task is
  # never cut (each session has its own cap)
  for (( rp = 1; rp <= REPEAT; rp++ )); do for tf in "${tasks[@]}"; do
    if [[ -z $stopped ]]; then
      if WEEKLY=$(weekly_over "$STATE_REAL/USAGE_7D") || WEEKLY=$(weekly_over "$E/state/USAGE_7D"); then
        stopped=weekly; say "starting no further task: $WEEKLY"
      elif ! spent=$(EV spent "$R"); then stopped=budget; say "starting no further task: can't sum what the tasks spent"
      elif awk -v s="$spent" -v c="$EVAL_BUDGET_USD" 'BEGIN { exit !(s >= c) }'; then   # a cap fails closed
        stopped=budget; say "starting no further task: \$$spent spent, the cap is \$$EVAL_BUDGET_USD"
      fi
    fi
    if [[ -n $stopped ]]; then NOT_STARTED+=("$(unit "$tf" "$rp")"); continue; fi
    share_limit; run_task "$tf" "$rp"
  done; done
  BUDGET_TEXT="budget: \$$(LC_ALL=C printf %.2f "$(EV spent "$R")") of \$$EVAL_BUDGET_USD; ${#NOT_STARTED[@]} tasks not started"
  say "$BUDGET_TEXT"; write_json
  git -C "$HARNESS_HOME" worktree remove --force "$E/harness" && say "removed the harness worktree $E/harness"
  say "results: $R"
  (( SKIPPED == 0 )) || { say "$SKIPPED task(s) skipped (above)"; exit 1; }
  (( ${#NOT_STARTED[@]} == 0 )) || exit 1   # an incomplete eval isn't a result to compare
}

cmd_compare() {
  (( $# == 2 )) || die "usage: harness eval compare <result dir A> <result dir B> (a path, or a name under evals/results/)"
  local d dirs=() root=${HARNESS_EVAL_RESULTS:-$HARNESS_HOME/evals/results}
  for d in "$@"; do
    if [[ -z $d ]]; then die "an empty results dir name"
    elif [[ -d $d ]]; then dirs+=("$(realpath -- "$d")")
    elif [[ $d != */* && -d $root/$d ]]; then dirs+=("$(realpath -- "$root/$d")")
    else die "no results dir '$d' (a path, or a name under $root)"; fi
  done
  EV compare "${dirs[@]}"
}

case ${1:-} in
  run) shift; cmd_run "$@" ;;
  compare) shift; cmd_compare "$@" ;;
  *) printf '%s\n' "usage: harness eval run [--set <name|file>] [--harness <ref>] [--label <L>] [--repeat <N>]" \
       "       harness eval compare <result dir A> <result dir B>" >&2; exit 2 ;;
esac
