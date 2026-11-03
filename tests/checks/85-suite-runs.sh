#!/usr/bin/env bash
source "$(dirname "$0")/../lib.sh" && suite_setup
# ---- one full run per coding session (C1 fix 4): suite_runs and suite_full on the coding row, the Suite runs row ----
HH=$(cd "$HERE/.." && pwd)

# pure: suiteRuns over coding rows (rows without the field, from before C1-05 or rebuilt from run.log, count nothing),
# and the report's row after Flakes, "0" for none, no row for an older summary
SRP='import { suiteRuns, report } from "'$HERE'/../lib/summary.mjs";
  const c = (f, r, e = false) => ({ kind: "coding", feature: "X", env: e, suite_full: f, suite_runs: r });
  const eq = (a, b) => JSON.stringify(a) === JSON.stringify(b);
  const fx = { run: "r", project: "p", features: { passing: 0, total: 0, verified: 0, merged: 0 }, milestones: [], tests: {},
    flakes: { count: 0, names: {} }, cost: { by_role: {} }, time: { by_role_h: {} }, sessions: {}, features_detail: [] };
  const after = (s, row) => { const l = report(s).split("\n"), i = l.indexOf(row); return i > 0 && l[i - 1].startsWith("| Flakes |"); };
  process.exit(eq(suiteRuns([c(2, 3), c(0, 0), c(1, 4), { kind: "coding" }, { kind: "verify", suite_full: 9 }, c(5, 5, true)]),
      { sessions: 3, full: 3, runs: 7, full_per_session: 1 })
    && eq(suiteRuns([c(2, 3)]), { sessions: 1, full: 2, runs: 3, full_per_session: 2 })
    && eq(suiteRuns([c(1, 1), c(1, 1), c(0, 2)]).full_per_session, 0.7)
    && eq(suiteRuns([{ kind: "init" }]), { sessions: 0, full: 0, runs: 0, full_per_session: 0 })
    && after({ ...fx, suite_runs: suiteRuns([c(2, 3)]) }, "| Suite runs | 2 full per coding session (2 in 1; 3 runs in all) |")
    && after({ ...fx, suite_runs: suiteRuns([]) }, "| Suite runs | 0 |") && !report(fx).includes("Suite runs") ? 0 : 1);'
check "summary.mjs: suiteRuns counts the coding rows that carry suite_full; the Suite runs row after Flakes, 0 for none, none for an older summary" \
  'node --input-type=module -e "$SRP"'

# su: A's first coding session runs the suite in full, edits the tree, in full again and as a subset; B and C run none
STUB_RUN_SUITE2=A STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_LENIENT=1 "$H" start "$T/proj" su --spec SPEC.md --foreground > "$T/su.out" 2>&1
RD=$T/wt/proj/su/.harness/runs/su SU=$HARNESS_STATE/proj/su
row() { jq -sc --arg f "$1" '[.[] | select(.kind == "coding" and .feature == $f)][0] | [.suite_runs, .suite_full]' "$RD/metrics.jsonl"; }
check "suite runs: a session with two full calls and one subset has suite_runs 3 and suite_full 2 on its coding row, and the suite ran 3x note" \
  '[[ $(row A) == "[3,2]" ]] && hlog su | grep -F "· A: suite ran 3x (" > /dev/null'
check "suite runs: a session with no call has suite_runs 0 and suite_full 0" '[[ $(row B) == "[0,0]" && $(row C) == "[0,0]" ]]'
check "suite runs: the run's summary.json suite_runs is { sessions, full, runs, full_per_session } over its coding rows" \
  '[[ $(jq -c .suite_runs "$RD/summary.json") == "{\"sessions\":3,\"full\":2,\"runs\":3,\"full_per_session\":0.7}" ]]'
check "suite runs: the rendered retro prompt carries the run's full runs per coding session" \
  'grep -F "0.7 full per coding session (2 in 3; 3 runs in all)" "$SU/prompt-retro.md" > /dev/null'

# the same run's record with A's coding row alone (the other sessions' rows rebuilt from run.log carry no count)
jq -c 'select(.kind != "coding" or .feature == "A")' "$RD/metrics.jsonl" > "$T/m1" && cp "$T/m1" "$RD/metrics.jsonl"
"$H" report --md su > "$T/rep1.md" 2>&1; COLUMNS=200 HARNESS_TTY=1 NO_COLOR=1 "$H" report su > "$T/rep1.tty" 2>&1
check "suite runs: a run of one such session: full_per_session 2, harness report --md's Suite runs row after Flakes, the TTY card carries the same value" \
  '[[ $(jq -c .suite_runs "$SU/summary.json") == "{\"sessions\":1,\"full\":2,\"runs\":3,\"full_per_session\":2}" ]] \
  && grep -A1 "^| Flakes |" "$T/rep1.md" | grep -xF "| Suite runs | 2 full per coding session (2 in 1; 3 runs in all) |" > /dev/null \
  && grep "suite runs" "$T/rep1.tty" | grep -F "2 full per coding session (2 in 1; 3 runs in all)" > /dev/null'
jq -c 'select(.kind != "coding")' "$RD/metrics.jsonl" > "$T/m0" && cp "$T/m0" "$RD/metrics.jsonl"
check "suite runs: a run whose coding rows carry no count (rebuilt from run.log) reports 0" '"$H" report --md su | grep -xF "| Suite runs | 0 |" > /dev/null'
# metricsRow: the two counts as numbers; empty (lane.sh with no check-runs.log) or absent (every other row) → null
MRN='import { metricsRow, outcome } from "'$HERE'/../lib/metrics.mjs";
  const a = ["s", "o", "run", "coding", "A", "opus", "true", "10", "0", "false", "build", "", "M1"], r = x => metricsRow(outcome([]), x);
  const k = o => JSON.stringify([o.suite_runs, o.suite_full]);
  process.exit(k(r([...a, "3", "2"])) === "[3,2]" && k(r([...a, "0", "0"])) === "[0,0]" && k(r([...a, "", ""])) === "[null,null]" && k(r(a)) === "[null,null]" ? 0 : 1);'
check "metrics.mjs: metricsRow writes suite_runs and suite_full as numbers, null when empty (no check-runs.log) or absent" \
  'node --input-type=module -e "$MRN"'
check "bash -n lib/lane.sh; node --check lib/metrics.mjs lib/summary.mjs" \
  'bash -n "$HH/lib/lane.sh" && node --check "$HH/lib/metrics.mjs" && node --check "$HH/lib/summary.mjs"'
suite_end
