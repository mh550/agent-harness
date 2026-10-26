#!/usr/bin/env bash
source "$(dirname "$0")/../lib.sh" && suite_setup
# ---- run 14d: `harness merge` on a legacy record (no journal, plan §14 a): it stays byte for byte; its PR quotes its own verify entry ----
echo 'KEEP_SCRATCH=1 LEDGER_COMMIT=0 MAX_PARALLEL_RUNS=1 MERGE_POLICY=off' > "$T/user-config.sh"
STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_LENIENT=1 "$H" start "$T/proj" lgm --spec SPEC.md --foreground > "$T/run14d.out" 2>&1
echo 'KEEP_SCRATCH=1 LEDGER_COMMIT=0 MAX_PARALLEL_RUNS=1' > "$T/user-config.sh"
MW=$T/wt/proj/lgm MR=$T/wt/proj/lgm/.harness/runs/lgm
git -C "$MW" rm -q --ignore-unmatch "$MR/entries.jsonl" "$MR/progress-archive.md"
printf '# progress\n\n### 2026-10-20 11:00 · verify M2\n\n| Feature | Step | Ran | Saw | Holds |\n|---|---|---|---|---|\n| C | 1 | check | legacy-M2-row | yes |\n\n### 2026-10-20 10:00 · verify M1\n\nold\n' > "$MR/progress.md"
git -C "$MW" add -A && git -C "$MW" commit -qm "a pre-E4 record" && git -C "$MW" push -q origin harness/lgm
cp "$MR/progress.md" "$T/lgm-progress.md"
"$H" merge lgm > "$T/run14e.out" 2>&1
check "harness merge leaves a legacy record as it was; its PR quotes the legacy verify entry" 'cmp -s "$MR/progress.md" "$T/lgm-progress.md" && [[ ! -e $MR/entries.jsonl && ! -e $MR/progress-archive.md ]] \
  && ! git -C "$T/origin.git" cat-file -e harness/lgm:.harness/runs/lgm/entries.jsonl 2> /dev/null && on_main run/lgm/M2 \
  && grep -q "^Milestone \*\*M2\*\* of harness run .lgm." "$HARNESS_STATE/proj/lgm/pr-body.md" && grep -qx "| C | 1 | check | legacy-M2-row | yes |" "$HARNESS_STATE/proj/lgm/pr-body.md"'

suite_end
