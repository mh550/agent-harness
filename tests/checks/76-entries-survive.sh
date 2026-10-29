#!/usr/bin/env bash
source "$(dirname "$0")/../lib.sh" && suite_setup
# ---- entries that survive (R2): the session checks its own entry, ends with no background work, and a long summary is
# trimmed at the ingest instead of dropping the entry (docs/plans/2026-10-29-R2-entries.md) ----
STUB_LONG_SUMMARY=A STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_LENIENT=1 "$H" start "$T/proj" longsum --spec SPEC.md --foreground > "$T/longsum.out" 2>&1
for t in coding verify initializer; do bash "$HERE/../lib/prompt.sh" "$HARNESS_STATE/proj/longsum" "$t" A > "$T/prompt-$t.md" 2> "$T/prompt-$t.err"; done
check "entries survive: {{ENTRY_CHECK}} renders as lib/entries.mjs validate in the coding, verify and initializer prompts" 'ok=1; for t in coding verify initializer; do
    grep -E "node [^ ]*/lib/entries\.mjs validate " "$T/prompt-$t.md" > /dev/null && ! grep -F "{{ENTRY_CHECK}}" "$T/prompt-$t.md" > /dev/null || { echo "no entry check in $t"; ok=0; }; done; (( ok ))'
check "entries survive: the coding, verify and initializer prompts say no background work at the end" 'ok=1; for t in coding verify initializer; do
    grep -E "Never end your turn while a background task or subagent is still running" "$HERE/../prompts/$t.md" > /dev/null || { echo "no rule in $t"; ok=0; }; done; (( ok ))'
check "entries survive: STUB_LONG_SUMMARY=A keeps A's entry whole with the cut-to-400 note" 'hlog longsum | grep -E " · A: entry\.json summary 410 characters; cut to 400 and kept$" > /dev/null \
  && jq -se "map(select(.feature == \"A\"))[0] | (.minimal | not) and (.summary | length) == 400 and (.summary | startswith(\"A: x\")) and (.summary | endswith(\"…\"))" \
    "$T/wt/proj/longsum/.harness/runs/longsum/entries.jsonl" > /dev/null'

suite_end
