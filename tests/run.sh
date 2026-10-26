#!/usr/bin/env bash
# The suite: every tests/checks/*.sh (each from its own fresh throwaway state, tests/lib.sh), added up.
#   tests/run.sh [<name>…]   → all check files, or those whose names contain any <name>; PASS/FAIL per check, then the
#                              total `N/M checks passed`, exit 1 on any failure (KEEP=1 keeps each file's $T and names it)
# A full run also checks conformance: its check names are tests/fixtures/check-names.txt, none missing, new or doubled.
set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
files=()
for f in "$HERE"/checks/*.sh; do
  (( $# )) || { files+=("$f"); continue; }
  for a; do [[ $(basename "$f") == *"$a"* ]] && { files+=("$f"); break; }; done
done
(( ${#files[@]} )) || { echo "no check file matches: $*"; echo "0/0 checks passed"; exit 1; }
out=$(mktemp -d); trap 'rm -rf "$out"' EXIT
broken=()
for f in "${files[@]}"; do
  b=$(basename "$f" .sh)
  bash "$f" > "$out/$b.out" 2>&1 || broken+=("$b")   # a file, not a pipe: a process a check leaves can't hold the runner
  cat "$out/$b.out"
  [[ ${KEEP:-} ]] && echo "kept: $(sed -n '1s/^tmp: //p' "$out/$b.out") ($b)"
done
cat "$out"/*.out | sed -n 's/^\(PASS\|FAIL\) //p' > "$out/names"
total=$(grep -c '' "$out/names") fails=$(cat "$out"/*.out | grep -c '^FAIL ')

# conformance: the names this run produced against the fixture (a subset run produces only its own)
if (( ! $# )); then
  sed -i 's/ (skipped: [^)]*)$//' "$out/names"   # a check skipped where its tool is missing (no user systemd) keeps its name
  fx=$HERE/fixtures/check-names.txt; LC_ALL=C sort -u "$out/names" > "$out/uniq"   # C order, as the fixture (never exported: tmux needs UTF-8)
  missing=$(LC_ALL=C comm -23 "$fx" "$out/uniq") new=$(LC_ALL=C comm -13 "$fx" "$out/uniq") doubled=$(LC_ALL=C sort "$out/names" | uniq -d)
  [[ -n $missing ]] && printf 'missing (in the fixture, not run):\n%s\n' "$missing"
  [[ -n $new ]] && printf 'new (add each to tests/fixtures/check-names.txt):\n%s\n' "$new"
  [[ -n $doubled ]] && printf 'doubled (two checks of one name):\n%s\n' "$doubled"
  name="conformance: the split suite has every check the single-file suite had"; total=$((total + 1))
  if [[ -z $missing$new$doubled ]]; then echo "PASS $name"; else echo "FAIL $name"; fails=$((fails + 1)); fi
fi

(( ${#broken[@]} )) && echo "files that exited non-zero: ${broken[*]}"
echo "$(( total - fails ))/$total checks passed"
(( fails == 0 && ${#broken[@]} == 0 ))
