#!/usr/bin/env bash
source "$(dirname "$0")/../lib.sh" && suite_setup
# ---- run 15: a resumed run reloads its configuration after merging main (here: a new POLICY) ----
STUB_PHONE_STOP=1 "$H" start "$T/proj" flip --spec SPEC.md --foreground > "$T/run15.out" 2>&1
(cd "$T/proj" && git pull -q origin main && echo "POLICY=live-staged" >> .harness/config.sh && git commit -qam "policy: live-staged" && git push -q origin main)
"$H" continue flip --foreground > "$T/run15b.out" 2>&1
check "resume reloads config merged from main" 'hlog flip | grep -q "configuration reloaded after merging main: policy live-staged"'

suite_end
