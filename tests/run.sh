#!/usr/bin/env bash
# The suite: every tests/checks/*.sh (each from its own fresh throwaway state, tests/lib.sh), TEST_JOBS at a time, added up.
#   tests/run.sh [<name>…]   → all check files, or those whose names contain any <name>; each file's PASS/FAIL lines whole
#                              with a timing line, then the slowest three and the wall time, then the total
#                              `N/M checks passed`, exit 1 on any failure (KEEP=1 keeps each file's $T and names it)
# TEST_JOBS (default half the cores, 1 to 4) files run at once as plain background jobs: inside the caller's check scope,
# never a scope of their own (scopes don't nest; one would escape the cap). TEST_CHECKS: another checks directory.
# TEST_FILE_TIMEOUT (default 10m, a sleep duration): a file still running then is stopped (TERM to its process group,
# KILL 10 s later) and counted as one FAIL line, so a hung file costs its timeout, not the whole suite's.
# A full run of tests/checks also checks conformance: its check names are tests/fixtures/check-names.txt, none missing, new or doubled.
set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd); dir=${TEST_CHECKS:-$HERE/checks}
jobs=${TEST_JOBS:-}
[[ $jobs =~ ^[1-9][0-9]*$ ]] || { jobs=$(( $(nproc) / 2 )); (( jobs > 4 )) && jobs=4; (( jobs < 1 )) && jobs=1; }
files=()
for f in "$dir"/*.sh; do
  (( $# )) || { files+=("$f"); continue; }
  for a; do [[ $(basename "$f") == *"$a"* ]] && { files+=("$f"); break; }; done
done
[[ -e ${files[0]:-} ]] || { echo "no check file matches: $*"; echo "0/0 checks passed"; exit 1; }
mapfile -t files < <(ls -S "${files[@]}")   # largest first: its size is a fair guess at its time, and a long file started last sets the wall time
out=$(mktemp -d); trap 'for w in "$out"/*.wd; do [[ -f $w ]] && kill "$(cat "$w")"; done 2> /dev/null; rm -rf "$out"' EXIT   # a watchdog a killed job left
us() { echo "${EPOCHREALTIME/[.,]/}"; }   # microseconds, whatever the locale's decimal point
s1() { printf '%d.%d' $(( $1 / 1000000 )) $(( $1 % 1000000 / 100000 )); }   # microseconds as seconds, one decimal
t0=$(us)

# one file: its output to a file, not a pipe (a process a check leaves can't hold the runner), then "<rc> <µs>" beside it
# (written whole: replay may list it the moment it appears). setsid: the file leads a process group of its own (the
# watchdog and stopped() signal it whole) while its parent stays this subshell (not timeout(1)'s, which would also cut
# it off from the caller's group signals); <file>.pgid names it
to=${TEST_FILE_TIMEOUT:-10m}
one() { local b s rc p w; b=$(basename "$1" .sh) s=$(us)
  setsid bash "$1" > "$out/$b.out" 2>&1 & p=$!; echo "$p" > "$out/$b.pgid"
  ( z=""; trap 'kill "$z" 2> /dev/null; exit 0' TERM; sleep "$to" & z=$!; wait "$z" || exit 0
    : > "$out/$b.timedout"; kill -TERM -- "-$p"; sleep 10 & z=$!; wait "$z"; kill -KILL -- "-$p" ) > /dev/null 2>&1 & w=$!; echo "$w" > "$out/$b.wd"
  wait "$p"; rc=$?; [[ -e $out/$b.timedout ]] || kill "$w" 2> /dev/null   # timed out: its KILL still reaches what outlived the TERM
  wait "$w" 2> /dev/null; rm -f "$out/$b.wd"
  echo "$rc $(( $(us) - s ))" > "$out/$b.end.tmp" && mv "$out/$b.end.tmp" "$out/$b.end"; }
broken=() done_=() timing=() lost=0
# a file that exited non-zero with no FAIL line (set -u, a stray exit) stopped before its later checks: one failed check,
# so the total never reads all passed while a file is red
no_fail() { grep -q '^FAIL ' "$out/$1.out" 2> /dev/null || { echo "FAIL $1: $2 before its end, with no FAIL line"; lost=$((lost + 1)); }; }
# print every finished file not printed yet, whole, in the order they finished (.end's mtime)
replay() {
  local e b rc t
  for e in $(ls -tr "$out"/*.end 2> /dev/null); do
    b=$(basename "$e" .end); [[ " ${done_[*]} " == *" $b "* ]] && continue
    done_+=("$b"); read -r rc t < "$e"
    cat "$out/$b.out"
    [[ ${KEEP:-} ]] && echo "kept: $(sed -n '1s/^tmp: //p' "$out/$b.out") ($b)"
    echo "$b: $(grep -cE '^(PASS|FAIL) ' "$out/$b.out") checks, $(s1 "$t") s"; timing+=("$t $b")
    if [[ -e $out/$b.timedout ]]; then broken+=("$b"); echo "FAIL $b: still running after TEST_FILE_TIMEOUT=$to; stopped"; lost=$((lost + 1))
    elif (( rc )); then broken+=("$b"); no_fail "$b" "exited $rc"; fi
  done
}
# stopped by a signal (check.sh's timeout signals the whole group): each unfinished file's output so far, named, so a hung
# file shows its last line; the EXIT trap then deletes $out
stopped() {
  local f b left=()
  for f in "${files[@]}"; do
    b=$(basename "$f" .sh); [[ " ${done_[*]} " == *" $b "* || ! -e $out/$b.out ]] && continue
    kill -TERM -- "-$(cat "$out/$b.pgid" 2> /dev/null)" 2> /dev/null   # its own group: the caller's signal didn't reach it
    cat "$out/$b.out"; echo "$b: unfinished when the suite was stopped"; left+=("$b")
  done
  (( ${#left[@]} )) && { sleep 2; for b in "${left[@]}"; do kill -KILL -- "-$(cat "$out/$b.pgid" 2> /dev/null)" 2> /dev/null; done   # the caller's KILL doesn't reach them either
    echo "files that did not finish: ${left[*]}"; }; exit 143
}
trap stopped TERM INT HUP
running=0
for f in "${files[@]}"; do
  (( running >= jobs )) && { wait -n; running=$((running - 1)); replay; }
  one "$f" & running=$((running + 1))
done
while (( running )); do wait -n; running=$((running - 1)); replay; done
for f in "${files[@]}"; do   # a job that died before its .end (killed): its output so far, and it counts as broken
  b=$(basename "$f" .sh); [[ " ${done_[*]} " == *" $b "* ]] && continue
  cat "$out/$b.out" 2> /dev/null; echo "$b: ended without its exit status (killed?)"; broken+=("$b"); no_fail "$b" killed
done

cat "$out"/*.out | sed -n 's/^\(PASS\|FAIL\) //p' > "$out/names"
total=$(( $(grep -c '' "$out/names") + lost )) fails=$(( $(cat "$out"/*.out | grep -c '^FAIL ') + lost ))

# conformance: the names this run produced against the fixture (a subset run produces only its own)
if (( ! $# )) && [[ $(cd "$dir" && pwd -P) == "$(cd "$HERE/checks" && pwd -P)" ]]; then
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
echo "slowest: $(printf '%s\n' "${timing[@]}" | sort -rn | head -3 | while read -r t b; do printf '%s %s s, ' "$b" "$(s1 "$t")"; done | sed 's/, $//'); wall $(s1 $(( $(us) - t0 ))) s, $jobs jobs"
echo "$(( total - fails ))/$total checks passed"
(( fails == 0 && ${#broken[@]} == 0 ))
