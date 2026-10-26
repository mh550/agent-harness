#!/usr/bin/env bash
source "$(dirname "$0")/../lib.sh" && suite_setup
# ---- run 11: a verify refused by the usage limit is deferred, never a "holds" ----
STUB_VERIFY_LIMIT=1 STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_LENIENT=1 "$H" start "$T/proj" vlimit --spec SPEC.md --foreground > "$T/run11.out" 2>&1
check "refused verify: deferred, then verified, then merged" 'hlog vlimit | grep -q "verify M1 refused" && [[ $(hlog vlimit | grep -n "verify M1 refused" | cut -d: -f1) -lt $(hlog vlimit | grep -n "M1 verified and tagged" | cut -d: -f1) ]] && on_main run/vlimit/M1 \
  && jq -se "map(select(.kind == \"verify\" and .minimal == \"missing\")) | length == 1 and .[0].outcome == \"not yet\"" "$T/wt/proj/vlimit/.harness/runs/vlimit/entries.jsonl" > /dev/null'

suite_end
