#!/usr/bin/env bash
# The project's suite, cached per code tree. The driver and every session use this one command ({{CHECK}}).
#   check.sh             → the full suite. A tree that was green before is not run again ("green (cached …)").
#   check.sh <args…>     → the suite with these arguments (a subset while iterating); never cached.
#   check.sh --fast      → the fast tier (HARNESS_CHECK_FAST_CMD; empty: exactly the bare form), what `passes` stands on.
# Needs HARNESS_CHECK_CMD and HARNESS_SCRATCH (the driver exports both, and HARNESS_CHECK_KEY_IGNORE for the key). The last full run's output is
# $HARNESS_SCRATCH/check.out; the newest tree's is kept as check-<key>.out. A green tree's marker, green-<key> in the
# cache, holds its test count on line 1 (so a cached green still has it after scratch is gone: a continued run) and
# `wall <s>`, the first run's seconds (a whole-suite rerun's after one), on line 2 (every prompt's Suite line, decisions/2026-10-30-suite-length-in-prompt).
# Both forms run under timeout -k 30s HARNESS_CHECK_TIMEOUT (15m), in the scope $HARNESS_SCOPE_PREFIX-check-<pid> capped
# at HARNESS_CHECK_MEMORY_MAX (3G); bare without a prefix or user systemd (decisions/2026-10-25-capped-suites).
# A red full run is rerun once by HARNESS_CHECK_RERUN (auto: the HARNESS_FAILED=<names> files, else the whole suite ·
# failed · suite · off), never after a timeout or a cap kill; its output is check-rerun.out. A green rerun is a flake: one
# row in the cache's flakes.jsonl, the marker the first run's total (decisions/2026-10-29-rerun-guard). A subset never reruns.
# A red full run that was neither (both runs `exit <rc> after`) writes red-<key> beside green-<key>: the exit code, the
# first run's HARNESS_FAILED names, `wall <s>`, the RED line as printed; not after a signal's code (128 up). The next full
# call on that tree answers from it (`check: RED (cached for this code tree: <names | whole suite>)`, the stored line on
# the tree's own check-<key>.out, the stored exit) and runs nothing; a green run removes it; the subset form reads no
# marker; run_init drops one found around a failed init (decisions/2026-10-30-red-marker).
# With HARNESS_CHECK_KEY_MAP (CHECK_KEY_MAP: `<path>:<check>[:<check>…]`, files only those checks read), a green full run
# also writes part-<key>, keyed by the reduced key (treekey --partial: its full key, then its mapped `<blob> <path>` lines). A full
# call on a tree whose only difference from that green tree is in mapped paths runs just their checks, under the same
# timeout, cap and rerun guard, to check-partial.out (a rerun to check-partial-rerun.out): green, it is marked with the
# reference's green-<key> lines; red, with no marker of either kind. Any doubt (a map other than the tree's own
# .harness/config.sh one, the reference gone, another path set) runs in full; a partial writes no part-
# (decisions/2026-10-30-partial-key; the conditions are rows 4–11 of docs/plans/2026-10-30-S2-partial-key.md §3).
# --fast with HARNESS_CHECK_FAST_CMD set (decisions/2026-11-03-fast-gate): a green-<key> or red-<key> answers first as
# above (a full verdict stands for the fast tier), then fast-<key> (`check: fast green (cached …)`); else the fast command
# runs under the same timeout, cap and rerun guard (the HARNESS_FAILED= files through the suite command, else the fast
# tier again) to check-fast.out (a rerun to check-fast-rerun.out). Green writes fast-<key> (the fast run's `<n> tests`,
# `wall <s>`), never green-<key>: a fast-green is never read as a green, and no other call reads fast-<key>. Red writes
# no marker. A flake's row gains "tier": "fast". It never reads the map or part-<key>; check.out and check-<key>.out
# stay the last full run's (every count the driver reads from them is a whole suite's), and a full run's sweep of
# check-*.out spares check-fast*.out.
# Each call that ran or answered appends `<epoch> <full|fast|subset|partial|cached> <seconds>` to $HARNESS_SCRATCH/check-runs.log
# (the lane's "suite ran" note counts a session's from it).
# The flow and every line stay here; the decisions are pure functions in lib/checkdecide (decisions/2026-11-03-purity), one
# question per moment: a green call asks once, a red one three times, a subset only when it was killed.
set -uo pipefail
[[ -z ${HARNESS_XTRACE:-} ]] || source "$(dirname "$0")/xtrace.sh"   # the coverage trace, off unless set (lib/xtrace.sh)
cmd=${HARNESS_CHECK_CMD:-} fast=0 scratch=${HARNESS_SCRATCH:?HARNESS_SCRATCH is not set}
cache=${HARNESS_CHECK_CACHE:-$scratch}   # green-<key> and red-<key> markers, part-<key> sidecars (the driver keeps them in its state dir, not in scratch)
max=${HARNESS_CHECK_MEMORY_MAX:-3G} to=${HARNESS_CHECK_TIMEOUT:-15m}
rerun=${HARNESS_CHECK_RERUN:-auto}
here=$(cd "$(dirname "$0")" && pwd)
tk_given=${HARNESS_CHECK_TK:-} before_given=${HARNESS_CHECK_BEFORE:-}; unset HARNESS_CHECK_TK HARNESS_CHECK_BEFORE   # a lane's answers to this call's first two questions (check_run, lib/record.sh); the suite never sees them
tc() { [[ -s $1 ]] && node "$here/testcount.mjs" "$@"; }   # an empty output has no count: no node start for it
if [[ ${1:-} == --fast ]]; then   # with no fast command the whole suite is the fast tier: the bare form, byte for byte
  shift; (( $# )) && { echo "check: --fast takes no arguments (usage: check.sh [--fast | <args…>])"; exit 2; }
  [[ -n ${HARNESS_CHECK_FAST_CMD:-} ]] && fast=1
fi
# shellcheck source=lib/scope.sh
source "$here/scope.sh"
cd "$(git rev-parse --show-toplevel)" || exit 2
mkdir -p "$scratch" "$cache"
[[ -n $cmd ]] || { echo "check: no suite configured or detected (CHECK_CMD); nothing to run"; exit 0; }
unit=${HARNESS_SCOPE_PREFIX:+$HARNESS_SCOPE_PREFIX-check-$$} scoped=0 pid=""
[[ -n $unit ]] && scope_available && scoped=1
trap '[[ -n $unit ]] && rm -f "$(scope_dir)/$unit".{started,show}' EXIT   # one pair per call otherwise, never reused

# A TERM, INT or HUP (the calling session's scope stopped, a Ctrl-C) takes the suite down with check.sh: a scoped suite
# isn't in the caller's scope, and timeout gives it a process group of its own, so neither gets the caller's signals.
# Hence the suite runs in the background and check.sh waits, which a trapped signal interrupts.
stop() { if (( scoped )); then scope_stop "$unit"; elif [[ -n $pid ]]; then kill -TERM "$pid" 2> /dev/null; wait "$pid"; fi; exit $(( 128 + $1 )); }
trap 'stop 15' TERM; trap 'stop 2' INT; trap 'stop 1' HUP

# bash -c <args…> under the timeout, in the check scope when scoped (stopped after, so nothing it started lives on)
run() {
  local rc
  if (( scoped )); then scope_run "$unit" "" "$max" timeout -k 30s "$to" bash -c "$@" &
  else env -u TMUX -u TMUX_PANE timeout -k 30s "$to" bash -c "$@" & fi   # as scope_run strips them (decisions/2026-11-10-session-env-no-tmux)
  pid=$!; wait "$pid"; rc=$? pid=""
  (( scoped )) && scope_stop "$unit"; return $rc
}

# <full|fast|subset|partial|cached>: this call's row; the epoch is its end (to the microsecond, a dot whatever the locale), so a row
# between a lane's two stamps ended in between
row() { printf '%s\t%s\t%s\n' "$(date +%s.%6N)" "$1" "$(( $(date +%s) - start ))" >> "$scratch/check-runs.log"; }
# <green|fast|red|part>-<key> <line>…: a marker, whole or not at all (a temporary file moved into place), so a concurrent
# call on the tree reads either
mark() { local t=$cache/.${1%%-*}-$$; printf '%s\n' "${@:2}" > "$t" && mv -f "$t" "$cache/$1"; }

start=$(date +%s)
subset() {   # its output is the caller's; only a kill gets a line of its own
  run "$cmd \"\$@\"" _ "$@"; rc=$?
  [[ $rc == 124 || $rc == 137 ]] && echo "check: RED ($(why $rc $(( $(date +%s) - start ))))"
  row subset; exit $rc
}
decide() { node "$here/checkdecide.mjs" "$@"; }
# <rc> <seconds> [<the run's own seconds>] → rf, the facts every question about a red takes; the scope is read only for a 137
facts() {
  local lim cap=0; lim=$(dur_s "$to") || lim=0
  (( $1 == 137 && scoped )) && scope_capped "$unit" "$max" && cap=1
  rf=("$1" "$2" "${3:-$2}" "$to" "$lim" "$cap" "$max")
}
why() { facts "$@"; decide why "${rf[@]}"; }   # what the RED line says
(( $# )) && subset "$@"

# line 1 the tree's key, line 2 the key without the mapped paths, then one `<blob> <path>` per mapped path, then one
# `: <path> <name>…` per map entry (--names: the partial run's checks, without a second start)
if [[ -n $tk_given ]]; then mapfile -t tk <<< "$tk_given"; else mapfile -t tk < <(node "$here/treekey.mjs" --partial --names 2> /dev/null); fi
key=${tk[0]:-} red=${tk[1]:-} blobs=()
for l in "${tk[@]:2}"; do [[ $l == ": "* ]] || blobs+=("$l"); done
[[ $key =~ ^[0-9a-f]{16}$ ]] || key=""   # treekey failed: the full run, no marker
answer=run n="" nm="" line="" ref=""
if [[ -n $key ]]; then
  while read -r k v; do case $k in answer) answer=$v ;; n) n=$v ;; rc) rc=$v ;; names) nm=$v ;; line) line=$v ;; ref) ref=$v ;; esac
  done <<< "${before_given:-$(decide before "$cache" "$fast" "${tk[@]}")}"
fi
if [[ $answer == green ]]; then   # the marker holds the tree's test count (older markers are empty: its output's)
  [[ -n $n ]] || n=$(tc "$scratch/check-$key.out")
  # a key ignore list beyond the default (CHECK_KEY_IGNORE, the run record aside) is named, so a docs change's skip is explained
  ki=$(tr -s ' \t' '\n' <<< "${HARNESS_CHECK_KEY_IGNORE:-}" | grep -vx -e '' -e '\.harness/runs' | paste -sd' '); [[ $ki == docs/plans ]] && ki=""
  echo "check: green (cached for this code tree${n:+, $n}${ki:+; key ignores: $ki})"; row cached; exit 0
fi
if [[ $answer == red ]]; then   # the rerun guard already said it isn't a flake: nothing runs on this tree again
  # the tree's own output, check-<key>.out, if it is still the newest tree's: check.out and check-rerun.out may be another's
  echo "check: RED (cached for this code tree: ${nm:-whole suite})"; o=$scratch/check-$key.out
  if [[ -f $o ]]; then echo "${line% — last lines of *} — last lines of $o (this tree's first run):"; tail -25 "$o"
  else echo "${line% — last lines of *} — its output is gone from scratch${nm:+: check.sh $nm shows the failures}"; fi
  row cached; exit "$rc"
fi
if [[ $answer == fast ]]; then echo "check: fast green (cached for this code tree${n:+, $n})"; row cached; exit 0; fi
# collapsed whitespace, so a map spelled over two lines or with double spaces is the same map
ws() { local a; read -ra a <<< "$(tr -s '[:space:]' ' ' <<< "$1")"; echo "${a[*]}"; }
# Row 4a of the partial table, the one that needs a shell: only the tree's own map may choose a subset (the lint proves
# that one); the exported one is the driver's at its start. Asked last, for a call that would otherwise go partial.
own_map() {
  local tmap; tmap=$(unset CHECK_KEY_MAP; set +u; [[ -f .harness/config.sh ]] && source .harness/config.sh > /dev/null 2>&1 < /dev/null; echo "${CHECK_KEY_MAP:-}")
  [[ $(ws "$tmap") == "$(ws "${HARNESS_CHECK_KEY_MAP:-}")" ]]
}

# The rerun guard on a red run (rc) whose output is <out>: once more by CHECK_RERUN, never after a timeout or a cap kill
# (a rerun would cost the whole timeout again, or be killed again), to <rerun out>: the files of its HARNESS_FAILED=
# line as arguments (the subset form's way: never spliced into the command), else <rest…> through $sc (none: the whole
# suite, or the fast tier for --fast).
# Sets first (the first run's reason), names, how (failed, or suite: the rest), out and r0; rc becomes the rerun's.
guard() {
  local k v
  facts $rc $(( $(date +%s) - start ))
  while read -r k v; do case $k in first) first=$v ;; how) how=$v ;; names) read -ra names <<< "$v" ;; esac
  done < <(decide guard "${rf[@]}" "$rerun" "$1")
  [[ -n $how ]] || return 0
  local c=$sc args=("${@:3}"); [[ $how == failed ]] && c=$cmd args=("${names[@]}")
  out=$2 r0=$(date +%s); run "$c \"\$@\"" _ "${args[@]}" > "$out" 2>&1; rc=$?
}
# [<the partial's names>]: a flake's flakes.jsonl row (green, named and counted, never quarantined); --fast's says its tier
flake() {
  local load tier=""; load=$(cut -d' ' -f1-3 /proc/loadavg 2> /dev/null); (( fast )) && tier=fast
  jq -nc --arg at "$(date -u +%FT%TZ)" --arg key "$key" --arg rerun "$how" --arg first "$first" --arg load "$load" --arg lane "${HARNESS_LANE:-}" \
    --arg partial "$*" --arg tier "$tier" '{at: $at, key: $key, names: $ARGS.positional, rerun: $rerun, first: $first, load: $load, lane: $lane}
    + (if $partial == "" then {} else {partial: ($partial | split(" "))} end) + (if $tier == "" then {} else {tier: $tier} end)' \
    --args "${names[@]}" >> "$cache/flakes.jsonl"
}
# what a red rerun adds to the RED line
again() { case $how in failed) echo "; red again on a rerun of ${names[*]}" ;; partial) echo "; red again on a rerun of ${pn[*]}" ;;
  suite) if (( fast )); then echo "; red again on a rerun of the fast tier"; else echo "; red again on a rerun of the whole suite"; fi ;; esac; }

how="" names=() first="" sc=$cmd
if (( fast )); then   # the fast tier: its own output and marker, no partial; a red is never cached (decisions/2026-11-03-fast-gate)
  sc=$HARNESS_CHECK_FAST_CMD out=$scratch/check-fast.out
  rm -f "$scratch/check-fast-rerun.out"   # it belongs to the check-fast.out beside it
  run "$sc" > "$out" 2>&1; rc=$? w=$(( $(date +%s) - start ))
  if (( rc )); then guard "$out" "$scratch/check-fast-rerun.out"; [[ $how == suite ]] && w=$(( $(date +%s) - r0 )); fi
  s=$(( $(date +%s) - start ))
  if (( rc == 0 )); then
    n=$(tc "$scratch/check-fast.out" ${how:+--total})
    [[ -n $key ]] && mark "fast-$key" "$n" "wall $w"
    if [[ -n $how ]]; then flake; flaky=${names[*]}; echo "check: fast green after a rerun (flaky: ${flaky:-the fast tier})${n:+, $n}"
    else echo "check: fast green in $s s${n:+, $n}"; fi
  else   # the tail is the whole tier's first run (a rerun's is a few files')
    echo "check: RED (fast: $(why $rc $s $(( $(date +%s) - ${r0:-$start} )))$(again)) — last lines of $scratch/check-fast.out:"
    tail -25 "$scratch/check-fast.out"
  fi
  row fast; exit $rc
fi
if [[ $answer == partial ]] && own_map; then   # 11: the checks that read what differs, the subset form's way (names as arguments)
  read -ra pn <<< "$nm"
  rm -f "$scratch/check-partial-rerun.out"   # it belongs to the check-partial.out beside it
  run "$cmd \"\$@\"" _ "${pn[@]}" > "$scratch/check-partial.out" 2>&1; rc=$?
  out=$scratch/check-partial.out
  (( rc )) && guard "$out" "$scratch/check-partial-rerun.out" "${pn[@]}"   # a partial's "whole suite" is its subset
  [[ $how == suite ]] && how=partial
  s=$(( $(date +%s) - start ))
  if (( rc == 0 )); then   # the reference's count and wall: every count the driver reads is a full run's
    n=""; read -r n < "$cache/green-$ref" 2> /dev/null   # the reference gone since row 6 (a run_init fresh): green, no marker
    cp "$cache/green-$ref" "$cache/.green-$$" 2> /dev/null && mv -f "$cache/.green-$$" "$cache/green-$key" && rm -f "$cache/red-$key"
    if [[ -n $how ]]; then
      (( ${#names[@]} )) || names=("${pn[@]}")   # never empty: a partial flake is never "whole suite"
      flake "${pn[@]}"; echo "check: green after a rerun (partial: ${pn[*]}; flaky: ${names[*]})${n:+, $n}"
    else echo "check: green (partial: ${pn[*]}, $s s; cached for the rest)"; fi
  else   # no marker of either kind: the red marker is for a long run, a partial takes seconds
    echo "check: RED (partial: ${pn[*]}; $(why $rc $s $(( $(date +%s) - ${r0:-$start} )))$(again)) — last lines of $out:"; tail -25 "$out"
  fi
  row partial; exit $rc
fi
rm -f "$scratch/check-rerun.out"   # a check-rerun.out always belongs to the check.out beside it
run "$cmd" > "$scratch/check.out" 2>&1; rc=$? w=$(( $(date +%s) - start ))   # the suite's length: a rerun's is a subset's
[[ -n $key ]] && cp "$scratch/check.out" "$scratch/check-$key.out" \
  && find "$scratch" -maxdepth 1 -name 'check-*.out' ! -name "check-$key.out" ! -name 'check-fast*.out' -delete   # the newest tree's only: the markers are in $cache
# the first run's output stays whole in check.out
out=$scratch/check.out rc0=$rc line=""
if (( rc )); then
  guard "$out" "$scratch/check-rerun.out"
  [[ $how == suite ]] && w=$(( $(date +%s) - r0 ))   # a red with no names says nothing of the suite's length; its whole rerun does
fi
s=$(( $(date +%s) - start ))
if (( rc == 0 )); then   # the marker ("<n> tests" or empty, then the wall) outlives scratch; a flake's count is its first run's total
  n=$(tc "$scratch/check.out" ${how:+--total})
  [[ -n $key ]] && mark "green-$key" "$n" "wall $w" && rm -f "$cache/red-$key"
  # the sidecar: a full run's green only, so a partial's reference is always a tree every check ran on
  [[ -n $key && $red =~ ^[0-9a-f]{16}$ ]] && (( ${#blobs[@]} )) && mark "part-$red" "$key" "${blobs[@]}"
  if [[ -n $how ]]; then   # a flake: green, named and counted
    [[ -n $key && -z $n ]] && rm -f "$scratch/check-$key.out"   # no total: unknown beats the red run's passes
    flake; flaky=${names[*]}; echo "check: green after a rerun (flaky: ${flaky:-whole suite})${n:+, $n}"
  else echo "check: green in $s s${n:+, $n}"; fi
else
  last="" keep=0; facts $rc $s $(( $(date +%s) - ${r0:-$start} ))
  while read -r k v; do case $k in last) last=$v ;; keep) keep=$v ;; esac
  done < <(decide last "${rf[@]}" "$first" "$rc0" "$key")
  line="check: RED ($last$(again)) — last lines of $out:"
  echo "$line"; tail -25 "$out"
  (( keep )) && mark "red-$key" "$rc" "${names[*]}" "wall $w" "$line"
fi
row full; exit $rc
