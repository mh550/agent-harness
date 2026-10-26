#!/usr/bin/env bash
source "$(dirname "$0")/../lib.sh" && suite_setup
# ---- the suite runner: what lib/check.sh reads from its output ----
TC='import { testCount as t } from "'$HERE'/../lib/testcount.mjs"; const r = "PASS a\n2/2 checks passed\nPASS b\n325/326 checks passed\n";
  process.exit(t(r) === 325 && t("12 passed, 1 failed") === 12 && t("# pass 7\n") === 7 && t("ok") === null ? 0 : 1);'
check "testcount.mjs: the runner's last N/M checks passed is the count" 'node --input-type=module -e "$TC"'
# ---- the suite runner: TEST_JOBS files at a time inside the one scope, each file's output whole, timing lines ----
# three tiny check files (TEST_CHECKS points the runner at them): a and c print a line, sleep, print another, so a
# streamed output would interleave them; b is the quickest and smallest, c the slowest, largest and red. A systemd-run on PATH logs any call.
RC=$T/rc; mkdir -p "$RC" "$T/sdbin"
printf '%s\n' 'echo "PASS rc a1"; sleep 1; echo "PASS rc a2"; echo "2/2 checks passed"' > "$RC/01-a.sh"
printf '%s\n' 'echo "PASS rc b1"; echo "1/1 checks passed"' > "$RC/02-b.sh"
printf '%s\n' 'sleep 0.5; echo "PASS rc c1"; sleep 1.5; echo "FAIL rc c2"; echo "1/2 checks passed"; exit 1' > "$RC/03-c.sh"
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
mkdir -p "$T/rh" && printf '%s\n' 'echo "PASS rh a1"; echo "1/1 checks passed"' > "$T/rh/01-a.sh" && printf '%s\n' 'echo "PASS rh h1"; echo "rh about to hang"; sleep 30' > "$T/rh/02-h.sh"
TEST_CHECKS=$T/rh TEST_JOBS=2 timeout -k 5s 3s bash "$HERE/run.sh" > "$T/rh.out" 2>&1; RH=$?
check "suite runner: stopped by a signal, it prints each unfinished file's output so far and names it, then exits non-zero" \
  '[[ $RH != 0 ]] && grep -qx "rh about to hang" "$T/rh.out" && grep -qx "02-h: unfinished when the suite was stopped" "$T/rh.out" \
  && grep -qx "files that did not finish: 02-h" "$T/rh.out"'
suite_end
