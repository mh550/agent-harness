#!/usr/bin/env bash
# tier: slow
source "$(dirname "$0")/../lib.sh" && suite_setup
# ---- the suite runner: TEST_JOBS files at a time inside the one scope, each file's output whole, timing lines ----
# three tiny check files (TEST_CHECKS points the runner at them): a and c print a line, sleep, print another, so a
# streamed output would interleave them; b is the quickest and smallest, c the slowest, largest and red. A systemd-run on PATH logs any call.
# tiny <file> <line>…: a fixture check file, its tier header on line 2 (TIER=slow for the slow tier; run.sh refuses one without)
tiny() { local f=$1; shift; printf '%s\n' '#!/usr/bin/env bash' "# tier: ${TIER:-fast}" "$@" > "$f"; }
RC=$T/rc; mkdir -p "$RC" "$T/sdbin"
tiny "$RC/01-a.sh" 'echo "PASS rc a1"; sleep 1; echo "PASS rc a2"; echo "2/2 checks passed"'   # sleep-ok: the fixture's work (output interleaving)
tiny "$RC/02-b.sh" 'echo "PASS rc b1"; echo "1/1 checks passed"'
tiny "$RC/03-c.sh" 'sleep 0.5; echo "PASS rc c1"; sleep 1.5; echo "FAIL rc c2"; echo "1/2 checks passed"; exit 1'   # sleep-ok: the fixture's work
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
  && grep -qE "^slowest: 03-c [0-9.]+ s, 01-a [0-9.]+ s, 02-b [0-9.]+ s; wall [0-9.]+ s, 4 jobs, tier all$" "$T/rc4.out" && grep -qE "; wall [0-9.]+ s, 1 jobs, tier all$" "$T/rc1.out"'
check "suite runner: TEST_JOBS defaults to half the cores, at most 4, at least 1" \
  'n=$(( $(nproc) / 2 )); (( n > 4 )) && n=4; (( n < 1 )) && n=1; grep -qE "; wall [0-9.]+ s, $n jobs, tier all$" "$T/rc.out" && [[ $(cat "$T/rc.rc") == 1 ]]'
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
mkdir -p "$T/rk" && tiny "$T/rk/01-a.sh" 'echo "PASS rk a1"; echo "1/1 checks passed"' && tiny "$T/rk/02-k.sh" 'echo "PASS rk k1"; kill -9 $PPID'
TEST_CHECKS=$T/rk TEST_JOBS=2 bash "$HERE/run.sh" > "$T/rk.out" 2>&1; RK=$?
check "suite runner: a file whose job was killed shows its output and makes the runner exit 1" \
  '[[ $RK == 1 ]] && grep -qx "PASS rk k1" "$T/rk.out" && grep -qx "02-k: ended without its exit status (killed?)" "$T/rk.out" && grep -qx "files that exited non-zero: 02-k" "$T/rk.out"'
check "lib.sh: a REPLAY from the environment silences nothing (suite_setup unsets it)" \
  '[[ $(REPLAY=1 bash -c '"'"'source "$1/lib.sh" > /dev/null && suite_setup > /dev/null && check "rq x" false; echo "$fails"'"'"' _ "$HERE") == $'"'"'FAIL rq x\n1'"'"' ]]'
# P0 review: a file that stops before its end (set -u, a stray exit) with no FAIL line must not total "N/N checks passed"
mkdir -p "$T/rx" && tiny "$T/rx/01-a.sh" 'echo "PASS rx a1"; echo "1/1 checks passed"' && tiny "$T/rx/02-x.sh" 'set -u; echo "PASS rx x1"; echo "$undefined_rx"; echo "PASS rx x2"'
TEST_CHECKS=$T/rx TEST_JOBS=2 bash "$HERE/run.sh" > "$T/rx.out" 2>&1; RX=$?
check "suite runner: a file that exits non-zero with no FAIL line counts as one failed check (the total isn't all passed)" \
  '[[ $RX == 1 && $(tail -1 "$T/rx.out") == "2/3 checks passed" ]] && grep -qx "FAIL 02-x: exited 1 before its end, with no FAIL line" "$T/rx.out"'
# P0 review: a hung file stopped by the caller's timeout (check.sh's, which signals the whole group) shows its output so far
mkdir -p "$T/rh" && tiny "$T/rh/01-a.sh" 'echo "PASS rh a1"; echo "1/1 checks passed"' && tiny "$T/rh/02-h.sh" 'echo "PASS rh h1"; echo "rh about to hang"; sleep 30'   # sleep-ok: a hung file
TEST_CHECKS=$T/rh TEST_JOBS=2 timeout -k 5s 3s bash "$HERE/run.sh" > "$T/rh.out" 2>&1; RH=$?
check "suite runner: stopped by a signal, it prints each unfinished file's output so far and names it, then exits non-zero" \
  '[[ $RH != 0 ]] && grep -qx "rh about to hang" "$T/rh.out" && grep -qx "02-h: unfinished when the suite was stopped" "$T/rh.out" \
  && grep -qx "files that did not finish: 02-h" "$T/rh.out"'
# P2: a file still running after TEST_FILE_TIMEOUT is stopped (its group: the sleep too) and counted as one FAIL line,
# so a hung file costs its timeout, not the whole suite's; its EXIT trap runs (lib.sh traps TERM)
mkdir -p "$T/rt" && tiny "$T/rt/01-a.sh" 'echo "PASS rt a1"; echo "1/1 checks passed"' \
  && tiny "$T/rt/02-h.sh" 'trap "exit 143" TERM; trap "touch $0.trapped" EXIT; echo "PASS rt h1"; echo "rt about to hang"; sleep 60 & echo $! > $0.hang; wait'   # sleep-ok: a hung file
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
cn sa "sa a1" "sa h1" "sa h2" "sa k1" "sa k2" && tiny "$T/sa/01-a.sh" 'echo "PASS sa a1"' \
  && tiny "$T/sa/02-h.sh" 'echo "PASS sa h1"; sleep 60; echo "PASS sa h2"' && tiny "$T/sa/03-k.sh" 'echo "PASS sa k1"; kill -9 $PPID $$; echo "PASS sa k2"'   # sleep-ok: a hung file
for d in sb sd se; do cn "$d" "sa a1" "sa h1" "sa h2" && cp "$T/sa/01-a.sh" "$T/sa/02-h.sh" "$T/$d/"; done
tiny "$T/sb/03-n.sh" 'echo "PASS sb n1"' && tiny "$T/sd/03-d.sh" 'echo "PASS sa a1"' && cn se "sa a1" "sa h1" "sa h2" "se gone"
cn sc "sc a1" "sc r1" "sc r2" && tiny "$T/sc/01-a.sh" 'echo "PASS sc a1"' && tiny "$T/sc/02-r.sh" 'echo "FAIL sc r1"; exit 1'
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
cn sf "sf a1" "sf h1" "sf h2" && tiny "$T/sf/01-a.sh" 'echo "PASS sf a1"' \
  && tiny "$T/sf/02-h.sh" 'echo "PASS sf h1"; [[ -e $0.go ]] || sleep 60; echo "PASS sf h2"; echo "PASS sf n1"'   # sleep-ok: a hung file
sfr() { TEST_CHECKS=$T/sf TEST_JOBS=3 TEST_FILE_TIMEOUT=2s bash "$HERE/run.sh" "${@:2}" > "$T/sf-$1.out" 2>&1; echo $? > "$T/sf-$1.rc"; }
sfr full; touch "$T/sf/02-h.sh.go"; sfr rerun 02-h; sfr ok 01-a; cp "$T/sf/01-a.sh" "$T/sf/03-d.sh"; sfr dup 01-a 03-d
SFC="conformance: every check a subset ran is in the fixture, once"
check "suite runner: a subset run fails on a name not in its fixture (a stopped file's rerun) or a name twice; a conforming one passes" \
  '[[ $(grep "^HARNESS_FAILED=" "$T/sf-full.out") == "HARNESS_FAILED=02-h" && $(cat "$T/sf-rerun.rc") == 1 ]] \
  && [[ $(grep -x -A1 "new (add each to tests/fixtures/check-names.txt):" "$T/sf-rerun.out") == *$'"'"'\nsf n1'"'"' ]] && grep -qx "FAIL $SFC" "$T/sf-rerun.out" \
  && [[ $(cat "$T/sf-ok.rc") == 0 ]] && grep -qx "PASS $SFC" "$T/sf-ok.out" && [[ $(tail -1 "$T/sf-ok.out") == "2/2 checks passed" ]] \
  && [[ $(cat "$T/sf-dup.rc") == 1 ]] && [[ $(grep -x -A1 "doubled (two checks of one name):" "$T/sf-dup.out") == *$'"'"'\nsf a1'"'"' ]] && grep -qx "FAIL $SFC" "$T/sf-dup.out"'
# ---- tiers (T1-01): line 2 of every check file is `# tier: fast` or `# tier: slow`; `--tier` runs one tier's files ----
# tr: 01-f and 02-g fast, 03-s slow, with its own check-names.txt. tn: 02-n headerless, 03-m a tier no runner knows,
# 01-a and both of those touch $0.ran when run (nothing may run on a refusal)
tc() { printf '%s\n' "${@:2}" | LC_ALL=C sort > "$T/$1/check-names-fast.txt"; }   # a directory's fast fixture
cn tr "tr f1" "tr g1" "tr s1" && tc tr "tr f1" "tr g1" && tiny "$T/tr/01-f.sh" 'echo "PASS tr f1"' && tiny "$T/tr/02-g.sh" 'echo "PASS tr g1"' && TIER=slow tiny "$T/tr/03-s.sh" 'echo "PASS tr s1"'
trr() { TEST_CHECKS=$T/tr TEST_JOBS=2 bash "$HERE/run.sh" "${@:2}" > "$T/tr-$1.out" 2>&1; echo $? > "$T/tr-$1.rc"; }
trp() { grep '^PASS tr ' "$T/tr-$1.out" | LC_ALL=C sort | tr '\n' ,; }
trr fast --tier fast; trr slow --tier slow; trr fastg --tier fast 02-g; trr slowf --tier slow 01-f; trr bad --tier medium
trr rep --repeat 2 --tier fast; trr rep2 --tier slow --repeat 2 03
check "tiers: --tier fast runs the two fast files and not the slow one, --tier slow the slow one only, exit 0" \
  '[[ $(cat "$T/tr-fast.rc" "$T/tr-slow.rc") == $'"'"'0\n0'"'"' && $(trp fast) == "PASS tr f1,PASS tr g1," && $(trp slow) == "PASS tr s1," ]] \
  && ! grep -E "^03-s:" "$T/tr-fast.out" > /dev/null && ! grep -E "^0[12]-[fg]:" "$T/tr-slow.out" > /dev/null'
check "tiers: --tier fast <name> runs the one fast file whose name matches; a slow file's name under --tier fast matches none" \
  '[[ $(cat "$T/tr-fastg.rc") == 0 && $(trp fastg) == "PASS tr g1," && $(cat "$T/tr-slowf.rc") == 1 ]] && grep -qx "no check file matches: --tier slow 01-f" "$T/tr-slowf.out"'
check "tiers: --tier with no tier the runner knows prints the usage, exit 2, runs nothing" \
  '[[ $(cat "$T/tr-bad.rc") == 2 ]] && grep -q "^usage: tests/run.sh" "$T/tr-bad.out" && ! grep "^PASS " "$T/tr-bad.out" > /dev/null'
check "tiers: the slowest: line ends , tier fast, , tier slow, or , tier all for a run without --tier" \
  'grep -qE "^slowest: .*; wall [0-9.]+ s, 2 jobs, tier fast$" "$T/tr-fast.out" && grep -qE "^slowest: .*; wall [0-9.]+ s, 2 jobs, tier slow$" "$T/tr-slow.out" \
  && grep -qE "^slowest: .*; wall [0-9.]+ s, 4 jobs, tier all$" "$T/rc4.out"'
check "tiers: --repeat combines with --tier: the tier's matching files n times, no file of the other tier" \
  '[[ $(cat "$T/tr-rep.rc" "$T/tr-rep2.rc") == $'"'"'0\n0'"'"' ]] && grep -qx "01-f: 2/2 green" "$T/tr-rep.out" && grep -qx "02-g: 2/2 green" "$T/tr-rep.out" \
  && ! grep "^03-s" "$T/tr-rep.out" > /dev/null && [[ $(grep -c " green$" "$T/tr-rep2.out") == 1 ]] && grep -qx "03-s: 2/2 green" "$T/tr-rep2.out"'
mkdir -p "$T/tn" && tiny "$T/tn/01-a.sh" 'echo "PASS tn a1"; touch $0.ran' && printf '%s\n' '#!/usr/bin/env bash' 'echo "PASS tn n1"; touch $0.ran' > "$T/tn/02-n.sh" \
  && printf '%s\n' '#!/usr/bin/env bash' '# tier: medium' 'echo "PASS tn m1"; touch $0.ran' > "$T/tn/03-m.sh"
for a in "" "--tier fast" "01-a"; do TEST_CHECKS=$T/tn bash "$HERE/run.sh" $a > "$T/tn${a//[ -]/}.out" 2>&1; echo $? > "$T/tn${a//[ -]/}.rc"; done
check "tiers: a check file without a tier header on line 2 is refused: no tier header: <path> per file in name order, exit 2, nothing run" \
  'ok=1; for o in tn tntierfast tn01a; do [[ $(cat "$T/$o.rc") == 2 && $(cat "$T/$o.out") == "no tier header: $T/tn/02-n.sh"$'"'"'\n'"'"'"no tier header: $T/tn/03-m.sh" ]] || { echo "  ($o)"; ok=0; }; done \
  && (( ok )) && ! ls "$T"/tn/*.ran 2> /dev/null'
# ---- per-tier conformance (T1-02): --tier fast against check-names-fast.txt, --tier slow against the full fixture minus it ----
# tr (above) conforms in both tiers. tm: a fast name (tm f2) and a slow one (tm s2) deleted from their files. tx: a red
# fast file, its tier conforming (HARNESS_FAILED= as before)
cn tm "tm f1" "tm f2" "tm g1" "tm s1" "tm s2" && tc tm "tm f1" "tm f2" "tm g1" && tiny "$T/tm/01-f.sh" 'echo "PASS tm f1"' \
  && tiny "$T/tm/02-g.sh" 'echo "PASS tm g1"' && TIER=slow tiny "$T/tm/03-s.sh" 'echo "PASS tm s1"'
cn tx "tx f1" "tx r1" "tx s1" && tc tx "tx f1" "tx r1" && tiny "$T/tx/01-f.sh" 'echo "PASS tx f1"' \
  && tiny "$T/tx/02-r.sh" 'echo "FAIL tx r1"; exit 1' && TIER=slow tiny "$T/tx/03-s.sh" 'echo "PASS tx s1"'
tdr() { TEST_CHECKS=$T/$1 TEST_JOBS=2 bash "$HERE/run.sh" "${@:3}" > "$T/td-$2.out" 2>&1; echo $? > "$T/td-$2.rc"; }
trr all
tdr tm fast --tier fast; tdr tm slow --tier slow; tdr tm all; tdr tm fsub --tier fast 01-f; tdr tm sub 01 03; tdr tx xfast --tier fast
miss() { sed -n '/^missing (in the fixture, not run):$/,/^\(PASS\|FAIL\) conformance/p' "$T/td-$1.out" | sed '1d;$d' | tr '\n' ,; }
CF="conformance: every check of the fast tier ran, none new or doubled" CS="conformance: every check of the slow tier ran, none new or doubled"
check "tier conformance: a fast name missing from a --tier fast run fails the fast tier's conformance naming it, with no HARNESS_FAILED=" \
  '[[ $(cat "$T/td-fast.rc") == 1 && $(miss fast) == "tm f2," ]] && grep -qx "FAIL $CF" "$T/td-fast.out" && ! grep "^HARNESS_FAILED=" "$T/td-fast.out" > /dev/null'
check "tier conformance: a slow name missing from a --tier slow run is red naming it; a fast name absent from it is not missing" \
  '[[ $(cat "$T/td-slow.rc") == 1 && $(miss slow) == "tm s2," ]] && grep -qx "FAIL $CS" "$T/td-slow.out"'
check "tier conformance: a run without --tier checks the full list as before" \
  '[[ $(cat "$T/td-all.rc") == 1 && $(miss all) == "tm f2,tm s2," ]] && grep -qx "FAIL conformance: the split suite has every check the single-file suite had" "$T/td-all.out"'
check "tier conformance: a names subset, with or without --tier, checks new and doubled only" \
  '[[ $(cat "$T/td-fsub.rc" "$T/td-sub.rc") == $'"'"'0\n0'"'"' ]] && grep -qx "PASS $SFC" "$T/td-fsub.out" && grep -qx "PASS $SFC" "$T/td-sub.out" \
  && ! grep "^missing" "$T/td-fsub.out" "$T/td-sub.out" > /dev/null'
check "tier conformance: a green --tier fast or --tier slow run prints its tier's PASS line; a green full run keeps the full line" \
  '[[ $(cat "$T/tr-fast.rc" "$T/tr-slow.rc" "$T/tr-all.rc") == $'"'"'0\n0\n0'"'"' ]] && grep -qx "PASS $CF" "$T/tr-fast.out" && grep -qx "PASS $CS" "$T/tr-slow.out" \
  && grep -qx "PASS conformance: the split suite has every check the single-file suite had" "$T/tr-all.out"'
check "tier conformance: a red --tier fast run whose failures are all inside named files prints HARNESS_FAILED= as before" \
  '[[ $(cat "$T/td-xfast.rc") == 1 ]] && grep -qx "PASS $CF" "$T/td-xfast.out" && [[ $(grep "^HARNESS_FAILED=" "$T/td-xfast.out") == "HARNESS_FAILED=02-r" ]]'
# the lint, on the real tree (read only): the headers and the two fixtures agree. tierlint <checks dir> <full fixture>
# <fast fixture> [<more fast sources>…]: one line per inconsistency, exit 1 on any. A name belongs to the files whose
# source holds its text (most names are literal; one built at run time is told by the fast run's conformance instead)
tierlint() { local d=$1 full=$2 ff=$3 fs=("${@:4}") ss=() f m bad=0
  for f in "$d"/*.sh; do case $(sed -n 2p "$f") in "# tier: fast") fs+=("$f") ;; "# tier: slow") ss+=("$f") ;; *) echo "no tier header: $f"; bad=1 ;; esac; done
  m=$(LC_ALL=C comm -23 "$ff" "$full"); [[ -n $m ]] && { sed 's/^/fast name not in the full fixture: /' <<< "$m"; bad=1; }
  while IFS= read -r m; do grep -qF -- "$m" "${fs[@]}" && continue   # in a slow file's source and in no fast one's
    echo "fast name from a slow file: $m ($(grep -lF -- "$m" "${ss[@]}" | xargs -n1 basename | tr '\n' ' ' | sed 's/ $//'))"; bad=1
  done < <(grep -ohFf "$ff" "${ss[@]}" | LC_ALL=C sort -u)
  return $bad; }
FX=$HERE/fixtures UNIT=("$HERE"/unit/*.test.mjs)
check "tier lint: every tests/checks/*.sh has a tier header on line 2" \
  'ok=1; for f in "$HERE"/checks/*.sh; do [[ $(sed -n 2p "$f") =~ ^"# tier: "(fast|slow)$ ]] || { echo "  ($f)"; ok=0; }; done; (( ok ))'
check "tier lint: every name of check-names-fast.txt is in check-names.txt" \
  '[[ -s $FX/check-names-fast.txt && -z $(LC_ALL=C comm -23 "$FX/check-names-fast.txt" "$FX/check-names.txt") ]]'
check "tier lint: every name of check-names-fast.txt comes from a file whose header says fast" \
  'tierlint "$HERE/checks" "$FX/check-names.txt" "$FX/check-names-fast.txt" "${UNIT[@]}" > "$T/lint.out"; [[ $? == 0 && ! -s $T/lint.out ]] || { cat "$T/lint.out"; false; }'
# planted on a copy of the fixtures: a slow file's name (the first whose text no fast file holds) in the fast list
mkdir -p "$T/lf" && cp "$FX/check-names.txt" "$FX/check-names-fast.txt" "$T/lf/" && mapfile -t LS < <(grep -lx "# tier: slow" "$HERE"/checks/*.sh) && mapfile -t LFS < <(grep -lx "# tier: fast" "$HERE"/checks/*.sh)
PL=""; while IFS= read -r m; do grep -qF -- "$m" "${LFS[@]}" "${UNIT[@]}" || { PL=$m; break; }; done < <(grep -ohFf <(LC_ALL=C comm -23 "$FX/check-names.txt" "$FX/check-names-fast.txt") "${LS[@]}" | LC_ALL=C sort -u)
{ cat "$T/lf/check-names-fast.txt"; echo "$PL"; } | LC_ALL=C sort > "$T/lf/fast" && mv "$T/lf/fast" "$T/lf/check-names-fast.txt"
tierlint "$HERE/checks" "$T/lf/check-names.txt" "$T/lf/check-names-fast.txt" "${UNIT[@]}" > "$T/lf.out"; LF=$?
check "tier lint: a planted fast name whose file says slow turns the lint red naming it (on a copy of the fixtures)" \
  '[[ -n $PL && $LF == 1 ]] && grep -qxF -- "fast name from a slow file: $PL ($(grep -lF -- "$PL" "${LS[@]}" | xargs -n1 basename | tr "\n" " " | sed "s/ \$//"))" "$T/lf.out"'
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
# u5: no test file; u6: a process.exit(0) at the second file's import (node exits 0, its output lost); u7: lib/testcount.mjs
# imported beside a file holding a HARNESS_TESTS= line (argv[2] under one process); u8: a test that prints a PASS line
mkdir -p "$UT"/u{5,6,7,8}
printf '%s\n' "$UH" 'test("a", () => {});' > "$UT/u6/a.test.mjs"; printf '%s\n' "$UH" 'process.exit(0);' 'test("b", () => {});' > "$UT/u6/b.test.mjs"
printf '%s\n' "$UH" "import { total } from \"$HERE/../lib/testcount.mjs\";" 'test("a", () => { assert.equal(total("1/2 checks passed"), 2); });' > "$UT/u7/a.test.mjs"
printf '%s\n' "$UH" 'const s = `' 'HARNESS_TESTS=5' '`;' 'test("b", () => {});' > "$UT/u7/b.test.mjs"
printf '%s\n' "$UH" 'test("a", () => { console.log("PASS ghost"); });' > "$UT/u8/a.test.mjs"
for u in u5 u6 u7 u8; do TEST_UNIT_DIR=$UT/$u bash "$HERE/checks/00-unit-tier.sh" > "$UT/$u.out" 2> "$UT/$u.err"; echo $? > "$UT/$u.rc"; done
check "unit tier: no test file, a process.exit(0) at import or a test printing a PASS line is red with the tier's own FAIL line" \
  '[[ $(cat "$UT/u5.rc") == 1 && $(cat "$UT/u6.rc") == 1 && $(cat "$UT/u8.rc") == 1 ]] && grep -qx "FAIL unit tier: no \*.test.mjs in $UT/u5" "$UT/u5.out" \
  && grep -qx "FAIL unit tier: node --test ended without its summary (a process.exit?)" "$UT/u6.out" \
  && grep -qx "FAIL unit tier: 2 PASS/FAIL lines for 1 tests (a test wrote to stdout?)" "$UT/u8.out" && [[ $(tail -1 "$UT/u8.out") == "2/3 checks passed" ]]'
check "unit tier: lib/testcount.mjs imported beside another test file prints nothing of its own" \
  '[[ $(cat "$UT/u7.rc") == 0 && $(cat "$UT/u7.out") == $'"'"'PASS a\nPASS b\n2/2 checks passed'"'"' ]]'
suite_end
