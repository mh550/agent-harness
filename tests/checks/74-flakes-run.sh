#!/usr/bin/env bash
source "$(dirname "$0")/../lib.sh" && suite_setup
# ---- the rerun guard in stub runs (N1-03): a flake is noted and its feature stays passed; a real red still un-passes ----
# Two stub runs, each from the first main (origin's main is set back between runs). inv: the stub's default C (BROKEN
# on its first try), the default CHECK_CMD: red twice, so C un-passes as before the guard; it is also the run with no
# flake (C is M2's; its check-rerun.out goes at the next full suite, so its rerun-red is read where it is kept: the
# `check: RED` line C's second prompt carries from its init). fl: a CHECK_CMD red exactly once, on the first suite call after A's first session (mkdir is the atomic once).
# flakes_note alone: a row that isn't JSON is passed over, a half-written last line waits for the next call
mkdir -p "$T/fn/green"; printf '%s\n' '{"names":["a","b"],"load":"0.52 0.61 0.70"}' 'not json' 'null' '{"names":[],"load":""}' > "$T/fn/green/flakes.jsonl"
printf '{"names":["c"],"load":"1.5' >> "$T/fn/green/flakes.jsonl"
fn=$( source "$HERE/../lib/record.sh"; STATE=$T/fn; note() { echo "note: $*"; }; flakes_note; echo "at $(cat "$T/fn/flakes-noted")"; flakes_note
  printf ' 2 3"}\n' >> "$T/fn/green/flakes.jsonl"; flakes_note; echo "at $(cat "$T/fn/flakes-noted") of $(wc -c < "$T/fn/green/flakes.jsonl")" )
FN='note: flaky: a b (red, then green on a rerun; load 0.52)
note: flaky: whole suite (red, then green on a rerun; load ?)
at 81
note: flaky: c (red, then green on a rerun; load 1.5)
at 114 of 114'
check "flakes_note: one note per whole row past flakes-noted (whole suite for no names), a row that isn't JSON passed over" '[[ $fn == "$FN" ]]'

# summary.json's flakes and report's Flakes row (N1-04), pure: from a state dir's green/flakes.jsonl, a row that isn't JSON passed over
mkdir -p "$T/sf/green"; printf '%s\n' '{"names":["a","b"]}' 'not json' 'null' '[1]' '{"names":[]}' '{"names":["a"]}' > "$T/sf/green/flakes.jsonl"
SFL='import { build } from "'$HERE'/../lib/summary.mjs"; import { readFileSync } from "node:fs";
  const fx = Object.keys(JSON.parse(readFileSync("'$HERE'/fixtures/summary-report.json", "utf8")));
  const s = build("/nonexistent/p/w", "r", "'$T'/sf"), none = build("/nonexistent/p/w", "r", "/nonexistent/s");
  process.exit(JSON.stringify(s.flakes) === JSON.stringify({ count: 3, names: { a: 2, b: 1, "whole suite": 1 } })
    && JSON.stringify(none.flakes) === JSON.stringify({ count: 0, names: {} })
    && fx.every(k => k in none) && "flakes" in none && !fx.includes("flakes") ? 0 : 1);'
check "summary.mjs: flakes counts flakes.jsonl's rows by name (whole suite for no names); every fixture key still built" 'node --input-type=module -e "$SFL"'
RFL='import { report } from "'$HERE'/../lib/summary.mjs"; import { readFileSync } from "node:fs";
  const fx = JSON.parse(readFileSync("'$HERE'/fixtures/summary-report.json", "utf8"));
  const after = (s, row) => { const ls = report(s).split("\n"), i = ls.findIndex(l => l.startsWith("| Tests | ")); return ls[i + 1] === row; };
  const three = { ...fx, flakes: { count: 3, names: { "44-lanes-record": 1, "28-run-14d-harness-merge": 2 } } };
  process.exit(after(three, "| Flakes | 3 · 28-run-14d-harness-merge ×2, 44-lanes-record |")
    && after({ ...fx, flakes: { count: 0, names: {} } }, "| Flakes | 0 |") && !report(fx).includes("Flakes") ? 0 : 1);'
check "report: the Flakes row after Tests (n · name ×k), 0 for none, none for an older summary" 'node --input-type=module -e "$RFL"'

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
rd() { echo "$T/wt/proj/$1/.harness/runs/$1"; }
check "flakes run: summary.json flakes and report.md's Flakes row (1 · whole suite); the invariant run's Flakes 0" \
  'jq -e ".flakes.count == 1 and .flakes.names[\"whole suite\"] == 1" "$(rd fl)/summary.json" > /dev/null \
  && grep -Fx "| Flakes | 1 · whole suite |" "$(rd fl)/report.md" > /dev/null && grep -Fx "| Flakes | 0 |" "$(rd inv)/report.md" > /dev/null'
git -C "$T/origin.git" update-ref refs/heads/main "$main0"

# ts: the run's first suite (its init's) red once with a count, then green: tests-start is the marker's total, 5, not 3
check_cmd "flaky first suite" "if mkdir $T/flaked-ts 2> /dev/null; then echo '3/5 checks passed'; exit 1; fi; echo '5/5 checks passed'; test ! -f BROKEN"
STUB_NO_TAMPER=1 STUB_LENIENT=1 STUB_NO_RED=1 "$H" start "$T/proj" ts --spec SPEC.md --foreground > "$T/ts.out" 2>&1
check "flakes run: tests-start after a flake on the first suite is the marker's total, not the red run's passes" \
  '[[ -d $T/flaked-ts && $(cat "$HARNESS_STATE/proj/ts/tests-start") == 5 ]] && hlog ts | grep -F "flaky: whole suite" > /dev/null'
git -C "$T/origin.git" update-ref refs/heads/main "$main0"

# fe: finish's own suite flakes. C's one attempt leaves its tree red (BROKEN), so finish's suite of it is uncached; with
# `ended` written it is red once, then green on the rerun: its row is noted like any other, and counted once
check_cmd "flaky end" "if [ -e $T/state/proj/fe/ended ]; then if mkdir $T/flaked-fe 2> /dev/null; then exit 1; fi; exit 0; fi; test ! -f BROKEN"
mkdir -p "$HARNESS_STATE/proj/fe" && echo MAX_ATTEMPTS=1 > "$HARNESS_STATE/proj/fe/run.env"
STUB_NO_TAMPER=1 STUB_LENIENT=1 "$H" start "$T/proj" fe --spec SPEC.md --foreground > "$T/fe.out" 2>&1
check "flakes run: a flake on finish's own suite is noted too, and summary.json counts it once" \
  '[[ -d $T/flaked-fe && $(hlog fe | grep -cE "flaky: whole suite \(red, then green on a rerun; load [0-9.]+\)$") == 1 ]] \
  && jq -e ".flakes.count == 1" "$(rd fe)/summary.json" > /dev/null'

# the debrief's flakes block: the names in two or more of the project's last five ledgered summaries (its own ledger here)
for r in 1:2026-10-01:'{"x":1,"y":1}' 2:2026-10-02:'{"x":2}' 3:2026-10-03:; do IFS=: read -r n d fl <<< "$r"; mkdir -p "$T/dl/proj/r$n"
  jq -n --arg d "${d}T00:00:00Z" --argjson f "${fl:-null}" '{run: "r\($d)", ended_at: $d} + (if $f then {flakes: {count: 1, names: $f}} else {} end)' > "$T/dl/proj/r$n/summary.json"; done
HARNESS_LEDGER=$T/dl "$H" debrief --dry-run > "$T/dl.out" 2>&1
FW='import { flakers } from "'$HERE'/../lib/summary.mjs";
  const s = (d, n) => ({ ended_at: d, flakes: { count: 1, names: n } }), old = s(undefined, { o: 1 });
  const ls = flakers([old, s("2026-10-01", { o: 1, p: 1 }), s("2026-10-02", { p: 1, q: 1 }), s("2026-10-03", { q: 2 }), {}, s("2026-10-05", {}), s("2026-10-06", { q: 1 })]);
  process.exit(JSON.stringify(ls) === JSON.stringify(["q ×3", "p ×2"]) && JSON.stringify(flakers([{}])) === JSON.stringify(["(none)"]) ? 0 : 1);'
check "debrief: the flakes block names a check that flaked in two of the last five ledgered runs (×2), not one in one" \
  'C=$(head -1 "$T/dl.out"); [[ -f $C ]] && [[ $(awk "/^#### / { if (p) { print; exit } if (\$0 == \"#### report.md\") p = 1 }" "$C") == "#### flakes" ]] \
  && grep -A3 -x "#### flakes" "$C" > "$T/dl.block" && grep -Fx "x ×2" "$T/dl.block" > /dev/null && ! grep "^y" "$T/dl.block" > /dev/null \
  && node --input-type=module -e "$FW"'
suite_end
