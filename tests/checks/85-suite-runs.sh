#!/usr/bin/env bash
# tier: fast
source "$(dirname "$0")/../lib.sh" && suite_setup
# ---- one full run per coding session (C1 fix 4): suite_runs and suite_full on the coding row, the Suite runs row ----

# su: A's first coding session runs the suite in full, edits the tree, in full again and as a subset; B and C run none
STUB_RUN_SUITE2=A STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_LENIENT=1 "$H" start "$T/proj" su --spec SPEC.md --foreground > "$T/su.out" 2>&1
RD=$T/wt/proj/su/.harness/runs/su SU=$HARNESS_STATE/proj/su
row() { jq -sc --arg f "$1" '[.[] | select(.kind == "coding" and .feature == $f)][0] | [.suite_runs, .suite_full, .suite_fast]' "$RD/metrics.jsonl"; }
check "suite runs: a session with two full calls and one subset has suite_runs 3, suite_full 2 and suite_fast 0 on its coding row, and the suite ran 3x note" \
  '[[ $(row A) == "[3,2,0]" ]] && hlog su | grep -F "· A: suite ran 3x (" > /dev/null'
check "suite runs: a session with no call has suite_runs 0, suite_full 0 and suite_fast 0" '[[ $(row B) == "[0,0,0]" && $(row C) == "[0,0,0]" ]]'
# the line is the record's summary.json suite_runs as suiteRunsLine prints it (lib/driver.sh): its six values over the coding rows
check "suite runs: the rendered retro prompt carries the run's full and fast runs per coding session" \
  'grep -F "0.7 full and 0 fast per coding session (2 full, 0 fast in 3; 3 runs in all)" "$SU/prompt-retro.md" > /dev/null'

# the same run's record with A's coding row alone (the other sessions' rows rebuilt from run.log carry no count)
jq -c 'select(.kind != "coding" or .feature == "A")' "$RD/metrics.jsonl" > "$T/m1" && cp "$T/m1" "$RD/metrics.jsonl"
"$H" report --md su > "$T/rep1.md" 2>&1; COLUMNS=200 HARNESS_TTY=1 NO_COLOR=1 "$H" report su > "$T/rep1.tty" 2>&1
check "suite runs: a run of one such session: full_per_session 2, harness report --md's Suite runs row after Flakes, the TTY card carries the same value" \
  '[[ $(jq -c .suite_runs "$SU/summary.json") == "{\"sessions\":1,\"full\":2,\"fast\":0,\"runs\":3,\"full_per_session\":2,\"fast_per_session\":0}" ]] \
  && grep -A1 "^| Flakes |" "$T/rep1.md" | grep -xF "| Fix rounds | 0 |" > /dev/null \
  && grep -A1 "^| Fix rounds |" "$T/rep1.md" | grep -xF "| Suite runs | 2 full and 0 fast per coding session (2 full, 0 fast in 1; 3 runs in all) |" > /dev/null \
  && grep "suite runs" "$T/rep1.tty" | grep -F "2 full and 0 fast per coding session (2 full, 0 fast in 1; 3 runs in all)" > /dev/null'
# a run whose coding rows carry no count at all reports 0: the unit tier's (summary.test.mjs, suiteRuns)
suite_end
