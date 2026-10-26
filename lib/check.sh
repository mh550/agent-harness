#!/usr/bin/env bash
# The project's suite, cached per code tree. The driver and every session use this one command ({{CHECK}}).
#   check.sh             → the full suite. A tree that was green before is not run again ("green (cached …)").
#   check.sh <args…>     → the suite with these arguments (a subset while iterating); never cached.
# Needs HARNESS_CHECK_CMD and HARNESS_SCRATCH (the driver exports both). The last full run's output is
# $HARNESS_SCRATCH/check.out; the newest tree's is kept as check-<key>.out. A green tree's marker, green-<key> in the
# cache, holds its test count, so a cached green still has it after scratch is gone (a continued run).
# Both forms run under timeout -k 30s HARNESS_CHECK_TIMEOUT (15m), in the scope $HARNESS_SCOPE_PREFIX-check-<pid> capped
# at HARNESS_CHECK_MEMORY_MAX (3G); bare without a prefix or user systemd (decisions/2026-10-25-capped-suites).
set -uo pipefail
cmd=${HARNESS_CHECK_CMD:-} scratch=${HARNESS_SCRATCH:?HARNESS_SCRATCH is not set}
cache=${HARNESS_CHECK_CACHE:-$scratch}   # green-<key> markers (the driver keeps them in its state dir, not in scratch)
max=${HARNESS_CHECK_MEMORY_MAX:-3G} to=${HARNESS_CHECK_TIMEOUT:-15m}
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

# <rc> <seconds>: what the RED line says. GNU timeout exits 137, not 124, when it had to KILL, so a 137 that took the
# whole CHECK_TIMEOUT is the timeout; a 137 whose scope peaked at its cap is the kernel's kill there.
why() {
  local lim; lim=$(dur_s "$to") || lim=0
  if (( $1 == 124 )) || (( $1 == 137 && lim > 0 && $2 >= lim )); then echo "timed out after $to, exit $1 after $2 s"
  elif (( $1 == 137 && scoped )) && scope_capped "$unit" "$max"; then echo "killed at its $max memory cap, exit 137 after $2 s"
  else echo "exit $1 after $2 s"; fi
}

start=$(date +%s)
if (( $# )); then   # a subset: its output is the caller's; only a kill gets a line of its own
  run "$cmd \"\$@\"" _ "$@"; rc=$?
  [[ $rc == 124 || $rc == 137 ]] && echo "check: RED ($(why $rc $(( $(date +%s) - start ))))"
  exit $rc
fi

key=$(node "$here/treekey.mjs" 2>/dev/null) || key=""
if [[ -n $key && -f $cache/green-$key ]]; then   # the marker holds the tree's test count (older markers are empty: its output's)
  n=$(cat "$cache/green-$key"); [[ -n $n ]] || n=$(node "$here/testcount.mjs" "$scratch/check-$key.out")
  echo "check: green (cached for this code tree${n:+, $n})"; exit 0
fi
run "$cmd" > "$scratch/check.out" 2>&1; rc=$?
[[ -n $key ]] && cp "$scratch/check.out" "$scratch/check-$key.out" \
  && find "$scratch" -maxdepth 1 -name 'check-*.out' ! -name "check-$key.out" -delete   # the newest tree's only: the markers are in $cache
if (( rc == 0 )); then
  [[ -n $key ]] && node "$here/testcount.mjs" "$scratch/check.out" > "$cache/green-$key"   # "<n> tests" or empty: outlives scratch
  echo "check: green in $(( $(date +%s) - start )) s$(node "$here/testcount.mjs" "$scratch/check.out" | sed 's/^/, /')"
else
  echo "check: RED ($(why $rc $(( $(date +%s) - start )))) — last lines of $scratch/check.out:"; tail -25 "$scratch/check.out"
fi
exit $rc
