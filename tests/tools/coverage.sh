#!/usr/bin/env bash
# The coverage measurement (docs/specs/2026-11-03-slim-suite.md S1-01): the suite, once, with every check file's bash
# traced and its node covered, reduced to one set per check file (tests/tools/coverage.mjs: what a set is).
#   tests/tools/coverage.sh <sets dir> [<name>…]   → <sets dir>/<check file>.txt for every check file run (all of them,
#       or those tests/run.sh matches by <name>); with no <name> also <sets dir>/unit-<name>.txt per tests/unit file,
#       run alone; the suite's own output in <sets dir>/_suite.out, its last line printed. Exit: the suite's.
#   COVERAGE_RAW=<dir> tests/tools/coverage.sh --reduce <sets dir>   → the sets again from kept raw traces, no suite
# One suite: tests/run.sh runs once, TEST_JOBS files at a time as ever, with TEST_XTRACE_DIR set (tests/lib.sh). A
# check that goes red only under the trace is in _suite.out; its file's set is what ran all the same.
# The raw traces (about 10 GB for a full run) go to COVERAGE_RAW (default: a mktemp -d under TMPDIR), each file's
# removed once reduced; KEEP=1 keeps them and names the directory. A raw directory named for no check file (a check
# that runs check files of its own, suite-runner's) is reduced to <sets dir>/_stray-<name>.txt, which no table reads.
set -uo pipefail
HERE=$(cd "$(dirname "$0")/.." && pwd); dir=${TEST_CHECKS:-$HERE/checks}
only=0; [[ ${1:-} == --reduce ]] && { only=1; shift; }
(( $# )) || { echo "usage: tests/tools/coverage.sh [--reduce] <sets dir> [<name>…]"; exit 2; }
mkdir -p "$1" || exit 1; out=$(cd "$1" && pwd); shift
(( only )) && [[ ! -d ${COVERAGE_RAW:-} ]] && { echo "coverage.sh --reduce: COVERAGE_RAW names no directory"; exit 2; }
raw=${COVERAGE_RAW:-$(mktemp -d)}; mkdir -p "$raw" || exit 1; rc=0
(( only )) && KEEP=1
# cov-exit.cjs: node writes its coverage on an exit of its own only; the harness ends its helper with TERM
(( only )) || { TEST_XTRACE_DIR=$raw NODE_OPTIONS="--require=$HERE/tools/cov-exit.cjs" bash "$HERE/run.sh" "$@" > "$out/_suite.out" 2>&1; rc=$?; }
reduce() { node "$HERE/tools/coverage.mjs" reduce "$raw/$1" > "$out/$2.txt" || exit 1; [[ ${KEEP:-} ]] || rm -rf "${raw:?}/$1"; }
for d in "$raw"/*/; do [[ -d $d ]] || continue; b=$(basename "$d")
  if [[ -f $dir/$b.sh || $b == unit-* ]]; then reduce "$b" "$b"; else reduce "$b" "_stray-$b"; fi; done
if (( ! $# && ! only )); then
  for f in "$HERE"/unit/*.test.mjs; do b=unit-$(basename "$f" .test.mjs)
    NODE_V8_COVERAGE=$raw/$b/v8 node --test --test-isolation=none "$f" > /dev/null 2>&1 || echo "coverage: $b ended red"
    reduce "$b" "$b"; done
fi
if [[ ${KEEP:-} ]]; then echo "kept: $raw"; else rmdir "$raw" 2> /dev/null; fi
(( only )) || tail -1 "$out/_suite.out"; exit "$rc"
