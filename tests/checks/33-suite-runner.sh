#!/usr/bin/env bash
source "$(dirname "$0")/../lib.sh" && suite_setup
# ---- the suite runner: TEST_JOBS files at a time inside the one scope, each file's output whole, timing lines ----
# three tiny check files (TEST_CHECKS points the runner at them): a and c print a line, sleep, print another, so a
# streamed output would interleave them; b is the quickest and smallest, c the slowest, largest and red. A systemd-run on PATH logs any call.
RC=$T/rc; mkdir -p "$RC" "$T/sdbin"
printf '%s\n' 'echo "PASS rc a1"; sleep 1; echo "PASS rc a2"; echo "2/2 checks passed"' > "$RC/01-a.sh"   # sleep-ok: the fixture's work (output interleaving)
printf '%s\n' 'echo "PASS rc b1"; echo "1/1 checks passed"' > "$RC/02-b.sh"
printf '%s\n' 'sleep 0.5; echo "PASS rc c1"; sleep 1.5; echo "FAIL rc c2"; echo "1/2 checks passed"; exit 1' > "$RC/03-c.sh"   # sleep-ok: the fixture's work
printf '#!/usr/bin/env bash\necho "$*" >> %q\n' "$T/sd-called" > "$T/sdbin/systemd-run" && chmod +x "$T/sdbin/systemd-run"
for j in 1 4 ""; do TEST_CHECKS=$RC TEST_JOBS=$j PATH=$T/sdbin:$PATH bash "$HERE/run.sh" > "$T/rc$j.out" 2>&1; echo $? > "$T/rc$j.rc"; done
rcn() { grep '^PASS ' "$T/rc$1.out" | LC_ALL=C sort; }
check "suite runner: TEST_JOBS=1 and 4 end with the same N/M and PASS names, exit 1 and name the red file" \
  '[[ $(tail -1 "$T/rc1.out") == "4/5 checks passed" && $(tail -1 "$T/rc4.out") == "4/5 checks passed" && $(cat "$T/rc1.rc" "$T/rc4.rc") == $'"'"'1\n1'"'"' ]] \
  && [[ $(rcn 1) == "$(rcn 4)" && $(rcn 1 | wc -l) == 4 ]] && grep -qx "files that exited non-zero: 03-c" "$T/rc1.out" && grep -qx "files that exited non-zero: 03-c" "$T/rc4.out"'
check "suite runner: TEST_JOBS=4 replays each file whole in completion order; the largest file starts first" \
  '[[ $(grep -E "^(PASS|FAIL) " "$T/rc4.out" | tr "\n" ,) == "PASS rc b1,PASS rc a1,PASS rc a2,PASS rc c1,FAIL rc c2," ]] \
  && [[ $(grep -E "^(PASS|FAIL) " "$T/rc1.out" | tr "\n" ,) == "PASS rc c1,FAIL rc c2,PASS rc a1,PASS rc a2,PASS rc b1," ]]'
check "suite runner: a timing line per file, then the slowest three, the wall time and the jobs" \
  'grep -qE "^01-a: 2 checks, [0-9]+\.[0-9] s$" "$T/rc4.out" && grep -qE "^02-b: 1 checks, [0-9]+\.[0-9] s$" "$T/rc4.out" && grep -qE "^03-c: 2 checks, [0-9]+\.[0-9] s$" "$T/rc4.out" \
  && grep -qE "^slowest: 03-c [0-9.]+ s, 01-a [0-9.]+ s, 02-b [0-9.]+ s; wall [0-9.]+ s, 4 jobs$" "$T/rc4.out" && grep -qE "; wall [0-9.]+ s, 1 jobs$" "$T/rc1.out"'
check "suite runner: TEST_JOBS defaults to half the cores, at most 4, at least 1" \
  'n=$(( $(nproc) / 2 )); (( n > 4 )) && n=4; (( n < 1 )) && n=1; grep -qE "; wall [0-9.]+ s, $n jobs$" "$T/rc.out" && [[ $(cat "$T/rc.rc") == 1 ]]'
# the failed-files line (N1): a red full run names its red files for check.sh's rerun, a green one names none
mkdir -p "$T/rg" && cp "$RC/01-a.sh" "$RC/02-b.sh" "$T/rg/" && TEST_CHECKS=$T/rg bash "$HERE/run.sh" > "$T/rg.out" 2>&1
check "suite runner: a red full run prints HARNESS_FAILED=<the red files> right after the files-that-exited-non-zero line" \
  '[[ $(grep -x -A1 "files that exited non-zero: 03-c" "$T/rc4.out" | tail -1) == HARNESS_FAILED=03-c && $(grep -c "^HARNESS_FAILED=" "$T/rc1.out") == 1 ]]'
check "suite runner: a green run prints no HARNESS_FAILED= line" '[[ $(tail -1 "$T/rg.out") == "3/3 checks passed" ]] && ! grep "^HARNESS_FAILED=" "$T/rg.out"'
check "suite runner: the parallel runner starts no scope of its own (no systemd-run call)" '[[ ! -e $T/sd-called ]]'
check "lib.sh: a check replayed for its state (REPLAY=1) runs silent and uncounted" \
  '( REPLAY=1 total=0 fails=0; check "rp x" "touch $T/rp-ran" > "$T/rp.out"; check "rp y" false >> "$T/rp.out"
     [[ -f $T/rp-ran && ! -s $T/rp.out && $total == 0 && $fails == 0 ]] )'
# a file whose job dies before it can write its exit status (kill -9 of its parent, the runner's job): its output still
# shows, and it counts as broken
mkdir -p "$T/rk" && printf '%s\n' 'echo "PASS rk a1"; echo "1/1 checks passed"' > "$T/rk/01-a.sh" && printf '%s\n' 'echo "PASS rk k1"; kill -9 $PPID' > "$T/rk/02-k.sh"
TEST_CHECKS=$T/rk TEST_JOBS=2 bash "$HERE/run.sh" > "$T/rk.out" 2>&1; RK=$?
check "suite runner: a file whose job was killed shows its output and makes the runner exit 1" \
  '[[ $RK == 1 ]] && grep -qx "PASS rk k1" "$T/rk.out" && grep -qx "02-k: ended without its exit status (killed?)" "$T/rk.out" && grep -qx "files that exited non-zero: 02-k" "$T/rk.out"'
check "lib.sh: a REPLAY from the environment silences nothing (suite_setup unsets it)" \
  '[[ $(REPLAY=1 bash -c '"'"'source "$1/lib.sh" > /dev/null && suite_setup > /dev/null && check "rq x" false; echo "$fails"'"'"' _ "$HERE") == $'"'"'FAIL rq x\n1'"'"' ]]'
# P0 review: a file that stops before its end (set -u, a stray exit) with no FAIL line must not total "N/N checks passed"
mkdir -p "$T/rx" && printf '%s\n' 'echo "PASS rx a1"; echo "1/1 checks passed"' > "$T/rx/01-a.sh" && printf '%s\n' 'set -u; echo "PASS rx x1"; echo "$undefined_rx"; echo "PASS rx x2"' > "$T/rx/02-x.sh"
TEST_CHECKS=$T/rx TEST_JOBS=2 bash "$HERE/run.sh" > "$T/rx.out" 2>&1; RX=$?
check "suite runner: a file that exits non-zero with no FAIL line counts as one failed check (the total isn't all passed)" \
  '[[ $RX == 1 && $(tail -1 "$T/rx.out") == "2/3 checks passed" ]] && grep -qx "FAIL 02-x: exited 1 before its end, with no FAIL line" "$T/rx.out"'
# P0 review: a hung file stopped by the caller's timeout (check.sh's, which signals the whole group) shows its output so far
mkdir -p "$T/rh" && printf '%s\n' 'echo "PASS rh a1"; echo "1/1 checks passed"' > "$T/rh/01-a.sh" && printf '%s\n' 'echo "PASS rh h1"; echo "rh about to hang"; sleep 30' > "$T/rh/02-h.sh"   # sleep-ok: a hung file
TEST_CHECKS=$T/rh TEST_JOBS=2 timeout -k 5s 3s bash "$HERE/run.sh" > "$T/rh.out" 2>&1; RH=$?
check "suite runner: stopped by a signal, it prints each unfinished file's output so far and names it, then exits non-zero" \
  '[[ $RH != 0 ]] && grep -qx "rh about to hang" "$T/rh.out" && grep -qx "02-h: unfinished when the suite was stopped" "$T/rh.out" \
  && grep -qx "files that did not finish: 02-h" "$T/rh.out"'
# P2: a file still running after TEST_FILE_TIMEOUT is stopped (its group: the sleep too) and counted as one FAIL line,
# so a hung file costs its timeout, not the whole suite's; its EXIT trap runs (lib.sh traps TERM)
mkdir -p "$T/rt" && printf '%s\n' 'echo "PASS rt a1"; echo "1/1 checks passed"' > "$T/rt/01-a.sh" \
  && printf '%s\n' 'trap "exit 143" TERM; trap "touch $0.trapped" EXIT; echo "PASS rt h1"; echo "rt about to hang"; sleep 60 & echo $! > $0.hang; wait' > "$T/rt/02-h.sh"   # sleep-ok: a hung file
rt0=$(date +%s); TEST_CHECKS=$T/rt TEST_JOBS=2 TEST_FILE_TIMEOUT=2s bash "$HERE/run.sh" > "$T/rt.out" 2>&1; RT=$? rtw=$(( $(date +%s) - rt0 ))
check "suite runner: a file still running after TEST_FILE_TIMEOUT is stopped, shown and counted as one FAIL line" \
  '[[ $RT == 1 && $rtw -lt 20 && $(tail -1 "$T/rt.out") == "2/3 checks passed" ]] && grep -qx "rt about to hang" "$T/rt.out" \
  && grep -qx "FAIL 02-h: still running after TEST_FILE_TIMEOUT=2s; stopped" "$T/rt.out" && [[ -f $T/rt/02-h.sh.trapped ]] && rtp=$(cat "$T/rt/02-h.sh.hang") && wait_for 10 eval "! kill -0 $rtp"'
# F1-05: a stopped or killed file's unprinted names are missing from conformance; those found in its source don't
# count, so HARNESS_FAILED= still names the files and check.sh reruns those, not the whole suite. Each directory holds
# its own check-names.txt (the runner's fixture for a full run of it). sa: 02-h stopped, 03-k killed, each with a name
# it never printed; sb/sd/se: the same stopped file plus a new, a doubled or a missing name in no file's source (a check
# deleted); sc: no file cut short, a missing name.
cn() { mkdir -p "$T/$1" && printf '%s\n' "${@:2}" | LC_ALL=C sort > "$T/$1/check-names.txt"; }
cn sa "sa a1" "sa h1" "sa h2" "sa k1" "sa k2" && printf '%s\n' 'echo "PASS sa a1"' > "$T/sa/01-a.sh" \
  && printf '%s\n' 'echo "PASS sa h1"; sleep 60; echo "PASS sa h2"' > "$T/sa/02-h.sh" && printf '%s\n' 'echo "PASS sa k1"; kill -9 $PPID $$; echo "PASS sa k2"' > "$T/sa/03-k.sh"   # sleep-ok: a hung file
for d in sb sd se; do cn "$d" "sa a1" "sa h1" "sa h2" && cp "$T/sa/01-a.sh" "$T/sa/02-h.sh" "$T/$d/"; done
printf '%s\n' 'echo "PASS sb n1"' > "$T/sb/03-n.sh" && printf '%s\n' 'echo "PASS sa a1"' > "$T/sd/03-d.sh" && cn se "sa a1" "sa h1" "sa h2" "se gone"
cn sc "sc a1" "sc r1" "sc r2" && printf '%s\n' 'echo "PASS sc a1"' > "$T/sc/01-a.sh" && printf '%s\n' 'echo "FAIL sc r1"; exit 1' > "$T/sc/02-r.sh"
for d in sa sb sd se sc; do ( TEST_CHECKS=$T/$d TEST_JOBS=3 TEST_FILE_TIMEOUT=2s bash "$HERE/run.sh" > "$T/$d.out" 2>&1; echo $? > "$T/$d.rc" ) & done; wait
check "suite runner: a stopped or killed file's unprinted names are missing but not counted, so HARNESS_FAILED= names the files" \
  '[[ $(cat "$T/sa.rc") == 1 && $(grep -x -A2 "missing (in the fixture, not run):" "$T/sa.out" | tail -2) == $'"'"'sa h2\nsa k2'"'"' ]] \
  && grep -qx "missing names in the source of a file stopped or killed are not counted: 02-h 03-k" "$T/sa.out" \
  && grep -qx "PASS conformance: the split suite has every check the single-file suite had" "$T/sa.out" && [[ $(grep "^HARNESS_FAILED=" "$T/sa.out") == "HARNESS_FAILED=02-h 03-k" ]]'
check "suite runner: a new or doubled name, or a missing one in no stopped or killed file's source, still fails conformance with no HARNESS_FAILED=" \
  'ok=1; for d in sb sd se sc; do [[ $(cat "$T/$d.rc") == 1 ]] && grep -qx "FAIL conformance: the split suite has every check the single-file suite had" "$T/$d.out" \
     && ! grep "^HARNESS_FAILED=" "$T/$d.out" > /dev/null && grep -qx "files that exited non-zero: 02-[hr]" "$T/$d.out" || { echo "  ($d)"; ok=0; }; done; (( ok )) \
  && grep -qx "sb n1" "$T/sb.out" && grep -qx "sa a1" "$T/sd.out" && grep -qx "sc r2" "$T/sc.out" && ! grep "not counted" "$T/sc.out" > /dev/null \
  && [[ $(grep -x -A2 "missing (in the fixture, not run):" "$T/se.out" | tail -2) == $'"'"'sa h2\nse gone'"'"' ]] && grep -qx "missing names in the source of a file stopped or killed are not counted: 02-h" "$T/se.out"'
# F1-06 review: check.sh reruns HARNESS_FAILED='s files as a subset, so a name the stopped file never printed (sf n1,
# added past its hang and not to the fixture) would go green there: a subset run is checked against the fixture too
# (none new, none doubled; missing can't be told). sf: 02-h hangs until $0.go exists, 03-d prints 01-a's name again.
cn sf "sf a1" "sf h1" "sf h2" && printf '%s\n' 'echo "PASS sf a1"' > "$T/sf/01-a.sh" \
  && printf '%s\n' 'echo "PASS sf h1"; [[ -e $0.go ]] || sleep 60; echo "PASS sf h2"; echo "PASS sf n1"' > "$T/sf/02-h.sh"   # sleep-ok: a hung file
sfr() { TEST_CHECKS=$T/sf TEST_JOBS=3 TEST_FILE_TIMEOUT=2s bash "$HERE/run.sh" "${@:2}" > "$T/sf-$1.out" 2>&1; echo $? > "$T/sf-$1.rc"; }
sfr full; touch "$T/sf/02-h.sh.go"; sfr rerun 02-h; sfr ok 01-a; cp "$T/sf/01-a.sh" "$T/sf/03-d.sh"; sfr dup 01-a 03-d
SFC="conformance: every check a subset ran is in the fixture, once"
check "suite runner: a subset run fails on a name not in its fixture (a stopped file's rerun) or a name twice; a conforming one passes" \
  '[[ $(grep "^HARNESS_FAILED=" "$T/sf-full.out") == "HARNESS_FAILED=02-h" && $(cat "$T/sf-rerun.rc") == 1 ]] \
  && [[ $(grep -x -A1 "new (add each to tests/fixtures/check-names.txt):" "$T/sf-rerun.out") == *$'"'"'\nsf n1'"'"' ]] && grep -qx "FAIL $SFC" "$T/sf-rerun.out" \
  && [[ $(cat "$T/sf-ok.rc") == 0 ]] && grep -qx "PASS $SFC" "$T/sf-ok.out" && [[ $(tail -1 "$T/sf-ok.out") == "2/2 checks passed" ]] \
  && [[ $(cat "$T/sf-dup.rc") == 1 ]] && [[ $(grep -x -A1 "doubled (two checks of one name):" "$T/sf-dup.out") == *$'"'"'\nsf a1'"'"' ]] && grep -qx "FAIL $SFC" "$T/sf-dup.out"'
# ---- the unit tier: tests/checks/00-unit-tier.sh runs tests/unit (TEST_UNIT_DIR: another directory) under the reporter ----
# u1: one test passes, one fails on an assert diff; u2: passing only; u3: a file that exits at import (no FAIL line from
# node: the check file's own); u4: a file that throws at import (node's FAIL <file> or the check file's line: both red)
UT=$T/ut; mkdir -p "$UT"/u{1,2,3,4}; UH='import { test } from "node:test"; import assert from "node:assert/strict";'
printf '%s\n' "$UH" 'test("a", () => {});' 'test("b", () => { assert.equal(1, 2); });' > "$UT/u1/a.test.mjs"
printf '%s\n' "$UH" 'test("a", () => { assert.equal(1, 1); });' > "$UT/u2/a.test.mjs"
printf '%s\n' "$UH" 'process.exit(3);' 'test("a", () => {});' > "$UT/u3/a.test.mjs"
printf '%s\n' "$UH" 'throw new Error("u4 at import");' 'test("a", () => {});' > "$UT/u4/a.test.mjs"
for u in u1 u2 u3 u4; do TEST_UNIT_DIR=$UT/$u bash "$HERE/checks/00-unit-tier.sh" > "$UT/$u.out" 2> "$UT/$u.err"; echo $? > "$UT/$u.rc"; done
check "unit tier: a passing and a failing test print PASS a, FAIL b, the indented assert diff, then its own N/M line, exit 1" \
  '[[ $(cat "$UT/u1.rc") == 1 && $(sed -n 1p "$UT/u1.out") == "PASS a" && $(sed -n 2p "$UT/u1.out") == "FAIL b" && $(tail -1 "$UT/u1.out") == "1/2 checks passed" ]] \
  && sed "1,2d;\$d" "$UT/u1.out" > "$UT/u1.mid" && [[ -s $UT/u1.mid ]] && ! grep -v "^  " "$UT/u1.mid" > /dev/null && grep -E "^  .*1.*2" "$UT/u1.mid" > /dev/null'
check "unit tier: a passing-only file prints PASS a and its N/M line, exit 0" \
  '[[ $(cat "$UT/u2.rc") == 0 && $(cat "$UT/u2.out") == $'"'"'PASS a\n1/1 checks passed'"'"' ]]'
check "unit tier: node --test exiting non-zero with no FAIL line prints the unit tier FAIL line; a throw at import is red too" \
  '[[ $(cat "$UT/u3.rc") == 1 && $(cat "$UT/u4.rc") == 1 ]] && grep -qx "FAIL unit tier: node --test exited 3 with no FAIL line" "$UT/u3.out" \
  && [[ $(tail -1 "$UT/u3.out") == "0/1 checks passed" ]] && grep -E "^FAIL (unit tier: node --test exited [0-9]+ with no FAIL line|$UT/u4/a.test.mjs)$" "$UT/u4.out" > /dev/null'
check "unit tier: tests/unit/reporter.mjs passes node --check" 'node --check "$HERE/unit/reporter.mjs"'
suite_end
