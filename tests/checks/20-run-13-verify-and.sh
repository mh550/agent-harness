#!/usr/bin/env bash
source "$(dirname "$0")/../lib.sh" && suite_setup
# ---- run 13: verify and retro may not change code ----
STUB_VERIFY_EDITS=1 STUB_RETRO_EDITS=1 STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_LENIENT=1 "$H" start "$T/proj" meddle --spec SPEC.md --foreground > "$T/run13.out" 2>&1
check "verifier code edits reverted, never merged" 'hlog meddle | grep -q "reverted code edits the verifier may not make" && ! git -C "$T/origin.git" show main:hack-M1.txt > /dev/null 2>&1 && ! git -C "$T/origin.git" show main:CLAUDE.md | grep -q edited'
check "retro edits reverted"              'hlog meddle | grep -q "retro: reverted" && [[ ! -f $T/wt/proj/meddle/retro-hack.txt ]]'
check "a session's edits to the journal are restored (E4 review F1)" 'hlog meddle | grep -q " · verify M1: entries.jsonl edited by the session; restored (the driver is its only writer)$" \
  && ! grep -qx null "$T/wt/proj/meddle/.harness/runs/meddle/entries.jsonl" && hlog meddle | grep -q "M1 verified and tagged"'

suite_end
