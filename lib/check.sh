#!/usr/bin/env bash
# The project's suite, cached per code tree. The driver and every session use this one command ({{CHECK}}).
#   check.sh             → the full suite. A tree that was green before is not run again ("green (cached …)").
#   check.sh <args…>     → the suite with these arguments (a subset while iterating); never cached.
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
# Each call that ran or answered appends `<epoch> <full|subset|cached> <seconds>` to $HARNESS_SCRATCH/check-runs.log (the
# lane's "suite ran" note counts a session's from it).
set -uo pipefail
cmd=${HARNESS_CHECK_CMD:-} scratch=${HARNESS_SCRATCH:?HARNESS_SCRATCH is not set}
cache=${HARNESS_CHECK_CACHE:-$scratch}   # green-<key> and red-<key> markers (the driver keeps them in its state dir, not in scratch)
max=${HARNESS_CHECK_MEMORY_MAX:-3G} to=${HARNESS_CHECK_TIMEOUT:-15m}
rerun=${HARNESS_CHECK_RERUN:-auto}; [[ $rerun == @(auto|failed|suite|off) ]] || rerun=auto   # an unknown value: one wasted rerun at worst
here=$(cd "$(dirname "$0")" && pwd)
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
  else timeout -k 30s "$to" bash -c "$@" & fi
  pid=$!; wait "$pid"; rc=$? pid=""
  (( scoped )) && scope_stop "$unit"; return $rc
}

# <rc> <seconds> [<the run's own seconds>]: what the RED line says. GNU timeout exits 137, not 124, when it had to KILL, so
# a 137 that took the whole CHECK_TIMEOUT is the timeout; a 137 whose scope peaked at its cap is the kernel's kill there.
why() {
  local lim; lim=$(dur_s "$to") || lim=0
  if (( $1 == 124 )) || (( $1 == 137 && lim > 0 && ${3:-$2} >= lim )); then echo "timed out after $to, exit $1 after $2 s"
  elif (( $1 == 137 && scoped )) && scope_capped "$unit" "$max"; then echo "killed at its $max memory cap, exit 137 after $2 s"
  else echo "exit $1 after $2 s"; fi
}

# <full|subset|cached>: this call's row; the epoch is its end (to the microsecond, a dot whatever the locale), so a row
# between a lane's two stamps ended in between
row() { printf '%s\t%s\t%s\n' "$(date +%s.%6N)" "$1" "$(( $(date +%s) - start ))" >> "$scratch/check-runs.log"; }

start=$(date +%s)
if (( $# )); then   # a subset: its output is the caller's; only a kill gets a line of its own
  run "$cmd \"\$@\"" _ "$@"; rc=$?
  [[ $rc == 124 || $rc == 137 ]] && echo "check: RED ($(why $rc $(( $(date +%s) - start ))))"
  row subset; exit $rc
fi

key=$(node "$here/treekey.mjs" 2>/dev/null) || key=""
if [[ -n $key && -f $cache/green-$key ]]; then   # the marker holds the tree's test count (older markers are empty: its output's)
  n=""; read -r n < "$cache/green-$key"; [[ -n $n ]] || n=$(node "$here/testcount.mjs" "$scratch/check-$key.out")
  # a key ignore list beyond the default (CHECK_KEY_IGNORE, the run record aside) is named, so a docs change's skip is explained
  ki=$(tr -s ' \t' '\n' <<< "${HARNESS_CHECK_KEY_IGNORE:-}" | grep -vx -e '' -e '\.harness/runs' | paste -sd' '); [[ $ki == docs/plans ]] && ki=""
  echo "check: green (cached for this code tree${n:+, $n}${ki:+; key ignores: $ki})"; row cached; exit 0
fi
if [[ -n $key && -f $cache/red-$key ]]; then   # the rerun guard already said it isn't a flake: nothing runs on this tree again
  rc="" nm="" line=""; { read -r rc; read -r nm; read -r _; read -r line; } < "$cache/red-$key"
  [[ $rc =~ ^[1-9][0-9]*$ ]] || rc=1   # a marker caught mid-write (or planted) is still a red
  # the tree's own output, check-<key>.out, if it is still the newest tree's: check.out and check-rerun.out may be another's
  echo "check: RED (cached for this code tree: ${nm:-whole suite})"; o=$scratch/check-$key.out
  if [[ -f $o ]]; then echo "${line% — last lines of *} — last lines of $o (this tree's first run):"; tail -25 "$o"
  else echo "${line% — last lines of *} — its output is gone from scratch${nm:+: check.sh $nm shows the failures}"; fi
  row cached; exit "$rc"
fi
rm -f "$scratch/check-rerun.out"   # a check-rerun.out always belongs to the check.out beside it
run "$cmd" > "$scratch/check.out" 2>&1; rc=$? w=$(( $(date +%s) - start ))   # the suite's length: a rerun's is a subset's
[[ -n $key ]] && cp "$scratch/check.out" "$scratch/check-$key.out" \
  && find "$scratch" -maxdepth 1 -name 'check-*.out' ! -name "check-$key.out" -delete   # the newest tree's only: the markers are in $cache
# the rerun guard: a red that isn't a timeout or a cap kill (a rerun would cost the whole timeout again, or be killed
# again) runs once more, the named files or the whole suite; the first run's output stays whole in check.out
out=$scratch/check.out how="" names=() rc0=$rc line=""
if (( rc )); then
  first=$(why $rc $(( $(date +%s) - start )))
  read -ra names <<< "$(sed -n 's/^HARNESS_FAILED=//p' "$scratch/check.out" | tail -1)"
  if [[ $first != @("timed out"|"killed at")* ]]; then
    case $rerun in
      auto) how=suite; (( ${#names[@]} )) && how=failed ;;
      failed) (( ${#names[@]} )) && how=failed ;;
      suite) how=suite ;;
    esac
  fi
  if [[ -n $how ]]; then   # the names as arguments, the subset form's way: never spliced into the command
    out=$scratch/check-rerun.out r0=$(date +%s) args=(); [[ $how == failed ]] && args=("${names[@]}")
    run "$cmd \"\$@\"" _ "${args[@]}" > "$out" 2>&1; rc=$?
    [[ $how == suite ]] && w=$(( $(date +%s) - r0 ))   # a red with no names says nothing of the suite's length; its whole rerun does
  fi
fi
s=$(( $(date +%s) - start ))
if (( rc == 0 )); then   # the marker ("<n> tests" or empty, then the wall) outlives scratch; a flake's count is its first run's total
  n=$(node "$here/testcount.mjs" "$scratch/check.out" ${how:+--total})
  [[ -n $key ]] && printf '%s\nwall %s\n' "$n" "$w" > "$cache/.green-$$" && mv -f "$cache/.green-$$" "$cache/green-$key" \
    && rm -f "$cache/red-$key"   # a whole file or none: a concurrent call on the tree reads either
  if [[ -n $how ]]; then   # a flake: green, named and counted
    [[ -n $key && -z $n ]] && rm -f "$scratch/check-$key.out"   # no total: unknown beats the red run's passes
    load=$(cut -d' ' -f1-3 /proc/loadavg 2> /dev/null)
    jq -nc --arg at "$(date -u +%FT%TZ)" --arg key "$key" --arg rerun "$how" --arg first "$first" --arg load "$load" --arg lane "${HARNESS_LANE:-}" \
      '{at: $at, key: $key, names: $ARGS.positional, rerun: $rerun, first: $first, load: $load, lane: $lane}' --args "${names[@]}" >> "$cache/flakes.jsonl"
    flaky=${names[*]}; echo "check: green after a rerun (flaky: ${flaky:-whole suite})${n:+, $n}"
  else echo "check: green in $s s${n:+, $n}"; fi
else
  case $how in failed) again="; red again on a rerun of ${names[*]}" ;; suite) again="; red again on a rerun of the whole suite" ;; *) again="" ;; esac
  last=$(why $rc $s $(( $(date +%s) - ${r0:-$start} ))); line="check: RED ($last$again) — last lines of $out:"
  echo "$line"; tail -25 "$out"
  # cached only when neither run was a timeout (the box's load), a cap kill (the scope's) or a signal's code (a kill the
  # scope didn't see, a TERM: the box's, not the tree's): those the next call runs
  [[ -n $key && $first == "exit "* && $last == "exit "* ]] && (( rc0 < 128 && rc < 128 )) \
    && printf '%s\n' "$rc" "${names[*]}" "wall $w" "$line" > "$cache/.red-$$" && mv -f "$cache/.red-$$" "$cache/red-$key"
fi
row full; exit $rc
