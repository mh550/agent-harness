#!/usr/bin/env bash
source "$(dirname "$0")/../lib.sh" && suite_setup
# ---- a finished run keeps its record after gc (U3-03, decisions/2026-10-27-record-after-gc): finish copies ----
# ---- summary.json and report.md into the state dir; report reads worktree → state → ledger → a no record line ----
STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_LENIENT=1 "$H" start "$T/proj" rg1 --spec SPEC.md --foreground > "$T/rg1.out" 2>&1
S=$HARNESS_STATE/proj/rg1
check "record after gc: finish keeps summary.json, report.md and metrics.jsonl in the state dir, and says so" '
  [[ -s $S/summary.json && -s $S/report.md && -s $S/metrics.jsonl ]] &&
  cmp -s "$S/summary.json" "$T/wt/proj/rg1/.harness/runs/rg1/summary.json" &&
  grep -F "summary.json and report.md kept in the state dir (harness report reads them after gc)" "$S/run.log" > /dev/null'
"$H" report rg1 > "$T/r0.out" 2>&1
"$H" gc "$T/proj" --all-merged > "$T/gc.out" 2>&1
check "record after gc: harness report prints the run's table from the state copy once gc removed the worktree" '
  [[ ! -d $T/wt/proj/rg1 ]] && "$H" report rg1 > "$T/r1.out" 2>&1 && grep "^## rg1 · proj" "$T/r1.out" > /dev/null && diff "$T/r0.out" "$T/r1.out"'
rm -f "$S/summary.json" "$S/metrics.jsonl"
check "record after gc: with the state copy gone, from the ledger copy, after which the state copy exists again" '
  "$H" report rg1 > "$T/r2.out" 2>&1 && diff "$T/r0.out" "$T/r2.out" &&
  cmp -s "$S/summary.json" "$HARNESS_LEDGER/proj/rg1/summary.json" && cmp -s "$S/metrics.jsonl" "$HARNESS_LEDGER/proj/rg1/metrics.jsonl"'
check "record after gc: harness status shows the passing count of a run gc removed" '
  "$H" status --all --json | jq -e "[.finished[] | select(.run == \"rg1\")][0].features | .passing >= 1 and .passing == .total" > /dev/null'
mv "$HARNESS_LEDGER/proj/rg1" "$T/rg1-ledger"; rm -f "$S/summary.json"
check "record after gc: with both gone, a no record line naming the state dir and the ledger dir" '
  "$H" report rg1 > "$T/r3.out" 2>&1 && [[ $(head -1 "$T/r3.out") == "## rg1: no record (worktree removed; nothing in $S or $HARNESS_LEDGER/proj/rg1)" ]]'
mv "$T/rg1-ledger" "$HARNESS_LEDGER/proj/rg1"; rm -rf "$S"
check "record after gc: a run with no state dir is reported from the ledger, copied nowhere; an unknown one is still an error" '
  "$H" report rg1 > "$T/r4.out" 2>&1 && diff "$T/r0.out" "$T/r4.out" && [[ ! -e $S ]] &&
  ! "$H" report nosuch > /dev/null 2> "$T/r5.err" && grep "^harness: no run .nosuch." "$T/r5.err" > /dev/null'
suite_end
