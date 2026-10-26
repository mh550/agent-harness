#!/usr/bin/env bash
source "$(dirname "$0")/../lib.sh" && suite_setup
# ---- run 8: thin verify evidence → one more verify on the stronger model ----
STUB_THIN_VERIFY=1 STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_LENIENT=1 "$H" start "$T/proj" thin --spec SPEC.md --foreground > "$T/run8.out" 2>&1
check "thin evidence escalates the verify" 'hlog thin | grep -q "evidence short of the steps" && grep -q "verify M1 · claude-opus-5-5" "$HARNESS_STATE/proj/thin/run.log"'

suite_end
