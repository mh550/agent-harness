#!/usr/bin/env bash
source "$(dirname "$0")/../lib.sh" && suite_setup
# ---- the rerun guard in stub runs (N1-03): a flake is noted and its feature stays passed; a real red still un-passes ----
# Two stub runs, each from the first main (origin's main is set back between runs). inv: the stub's default C (BROKEN
# on its first try), the default CHECK_CMD: red twice, so C un-passes as before the guard; it is also the run with no
# flake (C is M2's; its check-rerun.out goes at the next full suite, so its rerun-red is read where it is kept: the
# `check: RED` line C's second prompt carries from its init). fl: a CHECK_CMD red exactly once, on the first suite call after A's first session (mkdir is the atomic once).
# flakes_note alone: a row that isn't JSON is passed over, a half-written last line waits for the next call
mkdir -p "$T/fn/green"; printf '%s\n' '{"names":["a","b"],"load":"0.52 0.61 0.70"}' 'not json' '{"names":[],"load":""}' > "$T/fn/green/flakes.jsonl"
printf '{"names":["c"],"load":"1.5' >> "$T/fn/green/flakes.jsonl"
fn=$( source "$HERE/../lib/record.sh"; STATE=$T/fn; note() { echo "note: $*"; }; flakes_note; echo "at $(cat "$T/fn/flakes-noted")"; flakes_note
  printf ' 2 3"}\n' >> "$T/fn/green/flakes.jsonl"; flakes_note; echo "at $(cat "$T/fn/flakes-noted") of $(wc -c < "$T/fn/green/flakes.jsonl")" )
FN='note: flaky: a b (red, then green on a rerun; load 0.52)
note: flaky: whole suite (red, then green on a rerun; load ?)
at 76
note: flaky: c (red, then green on a rerun; load 1.5)
at 109 of 109'
check "flakes_note: one note per whole row past flakes-noted (whole suite for no names), a row that isn't JSON passed over" '[[ $fn == "$FN" ]]'

main0=$(git -C "$T/origin.git" rev-parse main)
STUB_NO_TAMPER=1 STUB_LENIENT=1 "$H" start "$T/proj" inv --spec SPEC.md --foreground > "$T/inv.out" 2>&1
git -C "$T/origin.git" update-ref refs/heads/main "$main0"
check "flakes run: a red every time still un-passes C with today's note after a rerun (the invariant)" \
  'hlog inv | grep -F "C un-passed: suite red after the session" > /dev/null && ! hlog inv | grep -F "flaky:" > /dev/null \
  && grep -F "red again on a rerun of the whole suite) — last lines of $T/scratch/proj/inv/lanes/M2/check-rerun.out:" "$HARNESS_STATE/proj/inv/logs/04-C.prompt.md" > /dev/null \
  && grep "^done" "$HARNESS_STATE/proj/inv/ended" > /dev/null \
  && grep -F "C attempt 2" "$T/scratch/proj/inv/sessions.log" > /dev/null'
check "flakes run: a run with no flake writes no flaky: line and no flakes.jsonl" \
  '! hlog inv | grep -F "flaky:" > /dev/null && [[ ! -e $HARNESS_STATE/proj/inv/green/flakes.jsonl && ! -e $HARNESS_STATE/proj/inv/flakes-noted ]]'

# <subject> <command>: the project's CHECK_CMD, committed on the first main and pushed
check_cmd() { git reset -q --hard "$main0" && local cc; cc=$(printf 'CHECK_CMD=%q' "$2")
  sed -i "s|^CHECK_CMD=.*|$(sed 's/[|&\\]/\\&/g' <<< "$cc")|" .harness/config.sh && git commit -qam "$1" && git push -q origin main; }
check_cmd "flaky suite" "if [ \"\$(git log -1 --format=%s)\" = \"A: stub work (1)\" ] && mkdir $T/flaked 2> /dev/null; then exit 1; fi; test ! -f BROKEN"
STUB_NO_TAMPER=1 STUB_LENIENT=1 STUB_NO_RED=1 "$H" start "$T/proj" fl --spec SPEC.md --foreground > "$T/fl.out" 2>&1
check "flakes run: a suite red once after A's session is noted flaky: whole suite with its load, and A stays passed" \
  '[[ -d $T/flaked && $(hlog fl | grep -cE "flaky: whole suite \(red, then green on a rerun; load [0-9.]+\)$") == 1 ]] \
  && ! hlog fl | grep -F "A un-passed: suite red" > /dev/null && grep "^done" "$HARNESS_STATE/proj/fl/ended" > /dev/null'
check "flakes run: flakes-noted holds flakes.jsonl's size after the note" \
  'S=$HARNESS_STATE/proj/fl; [[ $(grep -c "" "$S/green/flakes.jsonl") == 1 && $(cat "$S/flakes-noted") == "$(wc -c < "$S/green/flakes.jsonl")" ]]'
git -C "$T/origin.git" update-ref refs/heads/main "$main0"

# ts: the run's first suite (its init's) red once with a count, then green: tests-start is the marker's total, 5, not 3
check_cmd "flaky first suite" "if mkdir $T/flaked-ts 2> /dev/null; then echo '3/5 checks passed'; exit 1; fi; echo '5/5 checks passed'; test ! -f BROKEN"
STUB_NO_TAMPER=1 STUB_LENIENT=1 STUB_NO_RED=1 "$H" start "$T/proj" ts --spec SPEC.md --foreground > "$T/ts.out" 2>&1
check "flakes run: tests-start after a flake on the first suite is the marker's total, not the red run's passes" \
  '[[ -d $T/flaked-ts && $(cat "$HARNESS_STATE/proj/ts/tests-start") == 5 ]] && hlog ts | grep -F "flaky: whole suite" > /dev/null'
suite_end
