#!/usr/bin/env bash
# The project's suite, cached per code tree. The driver and every session use this one command ({{CHECK}}).
#   check.sh             → the full suite. A tree that was green before is not run again ("green (cached …)").
#   check.sh <args…>     → the suite with these arguments (a subset while iterating); never cached.
# Needs HARNESS_CHECK_CMD and HARNESS_SCRATCH (the driver exports both). The last full run's output is
# $HARNESS_SCRATCH/check.out; each tree's output is kept as check-<key>.out.
set -uo pipefail
cmd=${HARNESS_CHECK_CMD:-} scratch=${HARNESS_SCRATCH:?HARNESS_SCRATCH is not set}
cache=${HARNESS_CHECK_CACHE:-$scratch}   # green-<key> markers (the driver keeps them in its state dir, not in scratch)
here=$(cd "$(dirname "$0")" && pwd)
cd "$(git rev-parse --show-toplevel)" || exit 2
mkdir -p "$scratch" "$cache"
[[ -n $cmd ]] || { echo "check: no suite configured or detected (CHECK_CMD); nothing to run"; exit 0; }
if (( $# )); then bash -c "$cmd \"\$@\"" _ "$@"; exit; fi

key=$(node "$here/treekey.mjs" 2>/dev/null) || key=""
if [[ -n $key && -f $cache/green-$key ]]; then
  echo "check: green (cached for this code tree$(node "$here/testcount.mjs" "$scratch/check-$key.out" | sed 's/^/, /'))"; exit 0
fi
start=$(date +%s)
bash -c "$cmd" > "$scratch/check.out" 2>&1; rc=$?
[[ -n $key ]] && cp "$scratch/check.out" "$scratch/check-$key.out"
if (( rc == 0 )); then
  [[ -n $key ]] && touch "$cache/green-$key"
  echo "check: green in $(( $(date +%s) - start )) s$(node "$here/testcount.mjs" "$scratch/check.out" | sed 's/^/, /')"
else
  echo "check: RED (exit $rc after $(( $(date +%s) - start )) s) — last lines of $scratch/check.out:"; tail -25 "$scratch/check.out"
fi
exit $rc
