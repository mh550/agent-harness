#!/usr/bin/env bash
source "$(dirname "$0")/../lib.sh" && suite_setup
# ---- run 13b: B's entry.json isn't JSON: the driver records a minimal entry from git and B's final message (E4-03) ----
STUB_BAD_ENTRY=B STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_LENIENT=1 "$H" start "$T/proj" badentry --spec SPEC.md --foreground > "$T/run13b.out" 2>&1
check "a malformed entry is recorded as minimal and the run goes on" 'hlog badentry | grep -q " · B: entry.json still invalid (not JSON: .*) after one resume; recorded a minimal entry$" \
  && jq -se "map(select(.feature == \"B\"))[0] | .outcome == \"passes\" and any(.files[]; . == \"B-badentry.txt\") and all(.files[]; startswith(\".harness\") | not) and .summary == \"done\" and (.minimal | startswith(\"invalid: not JSON\"))" \
    "$T/wt/proj/badentry/.harness/runs/badentry/entries.jsonl" > /dev/null && [[ ! -e $T/wt/proj/badentry/.harness/runs/badentry/entry.json ]] \
  && grep -q "^done" "$HARNESS_STATE/proj/badentry/ended"'

suite_end
