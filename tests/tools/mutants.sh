#!/usr/bin/env bash
# The mutation sample's runner (docs/specs/2026-11-03-slim-suite.md S1-02): each mutant of a sample
# (tests/tools/mutants.mjs pick) written into the tree, the check files that run its line run against it, the tree put back.
#   tests/tools/mutants.sh <sample.jsonl> <out dir> [<id>…]   → per mutant (all of the sample, or the <id>s) the suite's
#       output in <out dir>/<id>.out and one line, printed and appended to <out dir>/results.txt:
#       `<id> caught|survived <file>:<line> <kind> · <n> files · <s> s`; exit 1 when the tree is not clean
# One mutant at a time. The tree must be clean before each (`git diff --quiet`, else nothing runs) and is clean after
# it (`git checkout -- <file>`, checked): a mutant is never committed. Stopped while one is in the tree (TERM, INT,
# HUP), the runner stops the suite and puts the tree back before it goes. Caught: the run is red, by a FAIL line, a
# file that exits non-zero, or one stopped at TEST_FILE_TIMEOUT (a mutant may hang a stub run; 5m here unless set).
# MUTANT_WRAP: a command the suite runs under, split on spaces (a sandbox: a mutant is a harness nobody has read).
# An <id> already in results.txt is skipped, so a stopped sample goes on where it was.
set -uo pipefail
HERE=$(cd "$(dirname "$0")/.." && pwd); root=$(cd "$HERE/.." && pwd)
(( $# >= 2 )) || { echo "usage: tests/tools/mutants.sh <sample.jsonl> <out dir> [<id>…]"; exit 2; }
sample=$1; mkdir -p "$2" || exit 1; out=$(cd "$2" && pwd); shift 2
ids=("$@"); (( ${#ids[@]} )) || mapfile -t ids < <(jq -r .id "$sample")
# the suite runs in the background and is waited for, so a signal's trap runs at once, not when the suite ends
applied="" suite=""
back() { [[ -z $suite ]] || { kill -TERM "$suite" 2> /dev/null; wait "$suite" 2> /dev/null; }
  [[ -z $applied ]] || git -C "$root" checkout -q -- "$applied"; }
trap back EXIT; trap 'exit 143' TERM INT HUP
for id in "${ids[@]}"; do
  grep -q "^$id " "$out/results.txt" 2> /dev/null && continue
  git -C "$root" diff --quiet || { echo "mutants: the tree is not clean before $id; stopped"; exit 1; }
  m=$(jq -c --arg id "$id" 'select(.id == $id)' "$sample"); [[ -n $m ]] || { echo "mutants: no mutant $id in $sample"; exit 2; }
  file=$(jq -r .file <<< "$m"); mapfile -t files < <(jq -r '.files[]' <<< "$m")
  applied=$file; node "$HERE/tools/mutants.mjs" apply "$sample" "$id" > /dev/null || exit 1
  t0=$SECONDS
  # shellcheck disable=SC2086
  TEST_FILE_TIMEOUT=${TEST_FILE_TIMEOUT:-5m} ${MUTANT_WRAP:-} bash "$HERE/run.sh" "${files[@]}" > "$out/$id.out" 2>&1 & suite=$!
  wait "$suite"; rc=$?; suite=""
  git -C "$root" checkout -q -- "$file"; applied=""
  git -C "$root" diff --quiet || { echo "mutants: $file did not go back after $id; stopped"; exit 1; }
  echo "$id $( (( rc )) && echo caught || echo survived) $file:$(jq -r .line <<< "$m") $(jq -r .kind <<< "$m") · ${#files[@]} files · $(( SECONDS - t0 )) s" | tee -a "$out/results.txt"
done
