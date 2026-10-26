#!/usr/bin/env bash
source "$(dirname "$0")/../lib.sh" && suite_setup
# ---- run 12b: nothing sets MERGE_POLICY → the default is pr, so a verified milestone is proposed, never merged ----
echo 'KEEP_SCRATCH=1 LEDGER_COMMIT=0 MAX_PARALLEL_RUNS=1' > "$T/user-config.sh"   # no MERGE_POLICY in any layer: the harness default decides
STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_LENIENT=1 "$H" start "$T/proj" defpr --spec SPEC.md --foreground > "$T/run12b.out" 2>&1
cp "$T/base-config.sh" "$T/user-config.sh"
check "default MERGE_POLICY proposes a verified milestone, never merges it" 'hlog defpr | grep -q "M1 proposed for merging" && ! on_main run/defpr/M1'

suite_end
