#!/usr/bin/env bash
# The context bundle: the debrief's gatherer (moved here from lib/debrief.sh, same bytes) and `harness context`.
#   context.sh <run-id> | --since <YYYY-MM-DD HH:MM:SS> | --from <dir> [--out <dir>] [--id <id>]   sourced: context_since, context_runs, context_glossary
# Run, it writes <out>/context.md (the gatherer's markdown, then a ## Glossary of its IDs) and <out>/context.json (the
# spec's shape; both from one lib/context.mjs call) for one run or every run whose driver started since then, and prints
# <out>; <out> defaults to <state>/events/<id>/, <id> a uuid. --from copies a bundle already written (the debrief's, from
# the context its note was written from) instead of gathering again. A bundle in <state>/events/ then prunes the bundles there
# with no file newer than 30 days (the real clock), one stdout line saying how many.
# Read-only: everything it runs only reads (status, needs, trends, queue list; never `harness report`, so never
# summary.json), it takes no lock, and its scratch is <out>/.work.*, removed on exit. docs/plans/2026-11-07-A2-context-bundle.md §2.
# Sourced (lib/debrief.sh), the caller sets STATE_ROOT, Q, H, LEDGER, SINCE, CTX (the output file), WS (scratch) and F.
set -uo pipefail
: "${HARNESS_HOME:?}"
alive() { local p; p=$(cat "$1/driver.pid" 2>/dev/null) && [[ -n $p ]] && kill -0 "$p" 2>/dev/null; }
rec_dir() {   # state dir → the run's record: in its worktree, else the ledger's copy
  ( source "$1/meta.env"; local r=$WT/.harness/runs/$RUN_ID
    [[ -d $r ]] && echo "$r" || echo "$LEDGER/$(basename "$PROJECT_DIR")/$RUN_ID" )
}
context_since() {   # <YYYY-MM-DD HH:MM:SS> → the state dir of every run whose driver started since then, one per line
  local d
  for d in "$STATE_ROOT"/*/*/; do
    [[ -f $d/meta.env && -f $d/run.log ]] || continue
    awk -v s="$1" '/^[0-9-]+ [0-9:]+ run [^ ]+ on / && ($1 " " $2) >= s { f = 1; exit } END { exit !f }' "$d/run.log" && echo "${d%/}"
  done
}
fence() { echo '~~~'; cat; echo '~~~'; }
capped() {   # bytes file [tail] → the file's head (or tail), with a note when cut
  local n; n=$(wc -c < "$2")
  if [[ ${3:-} == tail ]]; then tail -c "$1" "$2"; else head -c "$1" "$2"; fi
  (( n > $1 )) && printf '\n… (cut: %s of %s bytes shown; the whole file: %s)\n' "$1" "$n" "$2"
  return 0
}
ended_of() {   # state dir → how it ended: the debrief's words (alive first: "still running" while the driver finishes);
  # CTX_ENDED_FIRST=1 (harness context): the ended file first, since the driver writes it before its end's event, alive still
  if [[ -n ${CTX_ENDED_FIRST:-} && -s $1/ended ]]; then cat "$1/ended"
  elif alive "$1"; then echo "still running"
  else cat "$1/ended" 2>/dev/null || echo "not running, no end reason"; fi
}
run_context() {   # state dir → this run's section
  ( source "$1/meta.env"
    local proj rd ended f
    proj=$(basename "$PROJECT_DIR"); rd=$(rec_dir "$1")
    ended=$(ended_of "$1")
    echo; echo "### $RUN_ID ($proj)"; echo
    echo "- ended: $ended"
    echo "- project: $PROJECT_DIR (its docs: CLAUDE.md, README.md, docs/) · branch harness/$RUN_ID"
    echo "- worktree: $WT$( [[ -d $WT ]] || echo ' (removed)') · run record: $rd · local state: $1"
    echo "- started by a queue runner: $( [[ -s $1/runners ]] && echo yes || echo 'no (by hand)') · continuation queued: $(compgen -G "$Q/*-continue-$RUN_ID.args" > /dev/null && echo yes || echo no)"
    echo "- features: $(F summary "$rd/feature_list.json" 2>/dev/null || echo 'no feature list')"
    echo; echo "#### harness status"; N=3 "$H" status "$RUN_ID" 2>&1 | head -c 3000 | fence
    # what waits on Michael: the records' cards, cut at a line with a note (the model can't tell a cut list otherwise)
    echo; echo "#### needs"; COLUMNS=80 "$H" needs "$RUN_ID" > "$WS/needs.txt" 2>&1
    if (( $(wc -c < "$WS/needs.txt") > 4000 )); then head -c 4000 "$WS/needs.txt" | sed '$d'; echo "… (cut at 4000 bytes; the rest: harness needs $RUN_ID)"
    else cat "$WS/needs.txt"; fi | fence
    for f in summary.json:12000 report.md:8000 retro.md:6000 INBOX.md:4000; do
      echo; echo "#### ${f%%:*}"
      if [[ ! -s $rd/${f%%:*} ]]; then echo "(none)"
      elif [[ $f == summary.json:* ]]; then jq -c . "$rd/summary.json" > "$WS/s.json" 2>/dev/null || cp "$rd/summary.json" "$WS/s.json"
        capped "${f##*:}" "$WS/s.json" | fence
      elif [[ $f == INBOX.md:* ]]; then capped "${f##*:}" "$rd/INBOX.md" tail | fence
      else capped "${f##*:}" "$rd/${f%%:*}" | fence; fi
      # the checks that flaked in two or more of the project's last five ledgered runs (a flake once is noise)
      [[ $f == report.md:* ]] && { echo; echo "#### flakes"; node "$HARNESS_HOME/lib/summary.mjs" flakers "$LEDGER/$proj" 2>&1 | fence; }
    done
    # the sessions' questions, from the needs record: open until answered (a later entry's resolved, or needs done); a run
    # with no question item ever (asked before R4) from its entries, those no later entry resolves. 12 at most
    echo; echo "#### Questions for Michael"
    "$H" needs "$RUN_ID" --all --json > "$WS/q.json" 2> /dev/null
    if jq -e 'any(.[]; .reason == "question")' "$WS/q.json" > /dev/null 2>&1; then
      jq '[.[] | select(.reason == "question" and .resolved_at == null)
        | "\(.card.question.text // "" | gsub("\\s+"; " ") | .[0:600]) (\(.ref)\(if .seen > 1 then ", asked \(.seen) times" else "" end))"]' "$WS/q.json"
    else node "$HARNESS_HOME/lib/entries.mjs" questions "$rd" 2> /dev/null | jq '[.[] | "\(.text | gsub("\\s+"; " ") | .[0:600]) (\(.feature), entries.jsonl:\(.line))"]'
    fi | jq -r --arg run "$RUN_ID" 'if length == 0 then "none open" else (.[0:12][] | "- " + .),
      (if length > 12 then "… and \(length - 12) more: harness needs \($run)" else empty end) end' | fence
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
spend() {   # summed by one jq over each record's cost.total (0 without one; raw, and + 0: a computed number, as before)
  local d
  for d in "${RUNS[@]}"; do jq -r '.cost.total // 0' "$(rec_dir "$d")/summary.json" 2>/dev/null || echo 0; done | jq -s 'add + 0'
}
names() { local d; for d in "${RUNS[@]}"; do basename "$d"; done | paste -sd' ' -; }
context_runs() {   # <state dir>… → $CTX: the gatherer's markdown for these runs, every part capped, the whole cut at CMAX
  local -a RUNS=("$@")   # rate_info, spend and names read it (bash's dynamic scope)
  local upto n d why="the last debrief, or the queue runner's start"   # the debrief's words; harness context <run> sets its own
  [[ -n ${CTX_SINCE_WHY:-} ]] && why=$CTX_SINCE_WHY
  {
    echo "# ${CTX_TITLE:-Debrief context} · $(date '+%F %H:%M')"
    echo
    echo "- Covers: every run whose driver started since $SINCE ($why): ${#RUNS[@]} ($(names))"
    echo "- Queue runner now: $( [[ -f $Q/runner.pid ]] && kill -0 "$(cat "$Q/runner.pid")" 2>/dev/null && echo "going (pid $(cat "$Q/runner.pid"))" || echo "not running")"
    echo "- Spend of these runs (summary.json cost.total, summed): \$$(spend)"
    upto=$(cat "$STATE_ROOT/LIMIT_UNTIL" 2>/dev/null || echo 0)
    echo "- Usage-limit window (LIMIT_UNTIL): $( (( upto > $(date +%s) )) && echo "closed until $(date -d "@$upto" '+%F %H:%M')" || echo "open$( (( upto )) && echo " (last closed until $(date -d "@$upto" '+%F %H:%M'))")")"
    echo "- Latest rate-limit info in these runs' sessions: $(rate_info)"
    echo; echo "## harness status (these runs; each one's section below has more)"; echo
    for d in "${RUNS[@]}"; do N=1 "$H" status "$(basename "$d")" 2>&1 | head -1; done | fence
    echo; echo "## harness trends (last 40 lines)"; echo; "$H" trends --md 2>&1 | tail -n 40 | cut -c1-400 | fence
    echo; echo "## harness queue"; echo; "$H" queue list 2>&1 | head -n 60 | cut -c1-400 | fence
    echo; echo "## Queue runner.log since $SINCE (last 200 lines)"; echo
    awk -v s="$SINCE" 'on || (/^[0-9-]+ [0-9:]+ / && ($1 " " $2) >= s) { on = 1; print }' "$Q/runner.log" 2>/dev/null | tail -n 200 | cut -c1-400 | fence
    echo; echo "## Runs"
    for d in "${RUNS[@]}"; do run_context "$d"; done
    echo; echo "## Retro backlog (ledger/retro-backlog.jsonl)"; echo
    node "$HARNESS_HOME/lib/backlog.mjs" list "$LEDGER/retro-backlog.jsonl" --jsonl --max-bytes 6000 2>&1 | fence
  } > "$CTX"
  CMAX=${HARNESS_DEBRIEF_CONTEXT_MAX:-150000}   # the whole context, after each part's own cap (many runs add up)
  if (( $(wc -c < "$CTX") > CMAX )); then
    n=$(wc -c < "$CTX"); head -c $(( CMAX - 300 )) "$CTX" > "$WS/c.md"
    printf '\n\n… (context cut at %s of %s bytes; the rest is in the run records listed above)\n' "$CMAX" "$n" >> "$WS/c.md"; mv "$WS/c.md" "$CTX"
  fi
}
context_glossary() {   # <state dir>… → appends to $CTX a ## Glossary of the IDs each run's section names, in the bytes CMAX
  # leaves; with CTX_JSON (and CTX_ID, CTX_SCOPE_SINCE) set, the same node call writes context.json there: 1 when it can't
  local d left i=0 js=()
  for d in "$@"; do i=$(( i + 1 ))
    ( source "$d/meta.env"
      local rd ended running=0 docs=$PROJECT_DIR
      rd=$(rec_dir "$d"); [[ -e $WT/.git ]] && docs=$WT   # a run's docs: its worktree when it is a checkout, else its project's
      ended=$(ended_of "$d"); [[ $ended == "still running" ]] && running=1   # the same words as its section's
      ended=$(sed 's/ · [0-9-]* [0-9:]*$//' <<< "$ended")
      "$H" needs "$RUN_ID" --json > "$WS/needs-$i.json" 2> /dev/null || echo '[]' > "$WS/needs-$i.json"   # by row: two projects may share a run id
      printf '%s\t' "$d" "$RUN_ID" "$(basename "$PROJECT_DIR")" "${ended:-not running, no end reason}" "$running" \
        "$(F summary "$rd/feature_list.json" 2> /dev/null || echo 'no feature list')" "$rd" "$WT" "$docs" | tr -d '\n'
      echo "$WS/needs-$i.json" )
  done > "$WS/runs.tsv"
  [[ -n ${CTX_JSON:-} ]] && js=(--json "$CTX_JSON" --id "$CTX_ID" --since "${CTX_SCOPE_SINCE:-}")
  left=0   # a malformed HARNESS_DEBRIEF_CONTEXT_MAX: no glossary, as before no cut
  [[ ${CMAX:-} =~ ^[0-9]+$ ]] && left=$(( CMAX - $(wc -c < "$CTX") - 1 ))   # the gatherer is cut as before; the glossary gets what is left
  (( left > 0 || ${#js[@]} )) || return 0
  if node "$HARNESS_HOME/lib/context.mjs" bundle "$CTX" "$WS/runs.tsv" --max-bytes "$(( left > 0 ? left : 0 ))" "${js[@]}" > "$WS/glossary.md" 2> "$WS/glossary.err"; then
    (( left > 0 )) && [[ -s $WS/glossary.md ]] && { echo; cat "$WS/glossary.md"; } >> "$CTX"
  else echo "context: no glossary ($(tail -1 "$WS/glossary.err" | cut -c1-300))" >&2   # the context stands without it
    (( ${#js[@]} )) && return 1; fi
  return 0
}

[[ ${BASH_SOURCE[0]} != "$0" ]] && return 0   # sourced: the functions only

# ---- harness context ----------------------------------------------------------------------------------------------
[[ -z ${HARNESS_XTRACE:-} ]] || source "$HARNESS_HOME/lib/xtrace.sh"   # the coverage trace, off unless set (lib/xtrace.sh)
STATE_ROOT=${HARNESS_STATE:-${XDG_STATE_HOME:-$HOME/.local/state}/harness}; Q=$STATE_ROOT/queue
H=$HARNESS_HOME/bin/harness LEDGER=${HARNESS_LEDGER:-$HARNESS_HOME/ledger}
F() { node "$HARNESS_HOME/lib/features.mjs" "$@"; }
usage() { echo "usage: harness context <run-id> | --since <YYYY-MM-DD HH:MM:SS> [--out <dir>]" >&2; exit 2; }
die() { echo "harness context: $*" >&2; exit 1; }
run="" since="" out="" id="" from="" by=0
while (( $# )); do
  case $1 in
    --since|--out|--id|--from) (( $# >= 2 )) || usage
      case $1 in --since) since=$2 by=1 ;; --out) out=$2 ;; --id) id=$2 ;; --from) from=$2 ;; esac; shift 2 ;;
    -*) usage ;;
    *) [[ -z $run ]] || usage; run=$1; shift ;;
  esac
done
(( by + ${#run} > 0 && ${#from} > 0 )) && usage   # one scope: a run, a time or a bundle
(( by )) && [[ -n $run ]] && usage
(( by )) || [[ -n $run || -n $from ]] || usage
(( by )) && { [[ $since =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}\ [0-9]{2}:[0-9]{2}:[0-9]{2}$ ]] || usage; }
[[ -z $id || $id =~ ^[A-Za-z0-9-]{8,64}$ ]] || usage   # an events/<id>/ name n8n accepts (its ID_GUARD)
if [[ -n $from ]]; then :
elif [[ -n $run ]]; then   # bin/harness's state_of rule
  [[ $run =~ ^[A-Za-z0-9][A-Za-z0-9._-]*$ ]] || die "no run '$run' (run-id: letters, digits, . _ - only)"
  d=$(compgen -G "$STATE_ROOT/*/$run" | head -1)
  [[ -n $d && -f $d/meta.env && -f $d/run.log ]] || die "no run '$run' (see: harness status)"
  RUNS=("$d") CTX_SINCE_WHY="the run's start"
  SINCE=$(awk '/^[0-9-]+ [0-9:]+ run [^ ]+ on / { print $1 " " $2; exit }' "$d/run.log")
  [[ -n $SINCE ]] || die "no start line in $d/run.log"
else
  SINCE=$since; mapfile -t RUNS < <(context_since "$SINCE")
  (( ${#RUNS[@]} )) || die "no runs started since $SINCE"
fi
[[ -n $id ]] || id=$(cat /proc/sys/kernel/random/uuid) || die "no uuid (/proc/sys/kernel/random/uuid)"
[[ -n $out ]] || out=$STATE_ROOT/events/$id
mkdir -p "$out" && out=$(CDPATH='' cd -- "$out" && pwd) || die "cannot write $out"
WS=$(mktemp -d "$out/.work.XXXXXX") || die "cannot write $out"; trap 'rm -rf "$WS"' EXIT   # nothing outside $out
if [[ -n $from ]]; then   # copied as it is: the bundle names the runs its writer read, not the ones started since
  cp -- "$from/context.md" "$from/context.json" "$out/" 2> /dev/null && [[ -s $out/context.json ]] || die "no bundle in $from"
else
  CTX=$out/context.md CTX_TITLE=Context CTX_JSON=$out/context.json CTX_ID=$id CTX_SCOPE_SINCE=$since CTX_ENDED_FIRST=1
  context_runs "${RUNS[@]}"
  context_glossary "${RUNS[@]}" || die "no context.json in $out (the bundle's markdown is there)"
fi
echo "$out"
# the retention (decisions/2026-10-22-context-bundle-glossary): a bundle written among the others prunes the stale ones
ev=$(CDPATH='' cd -- "$STATE_ROOT/events" 2> /dev/null && pwd)
[[ -n $ev && ${out%/*} == "$ev" ]] && node "$HARNESS_HOME/lib/context.mjs" prune "$ev" "${out##*/}"
exit 0
