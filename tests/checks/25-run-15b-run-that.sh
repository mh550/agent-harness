#!/usr/bin/env bash
source "$(dirname "$0")/../lib.sh" && suite_setup
# ---- run 15b: a run that ended before its feature list merges main before the initializer re-runs (E0) ----
STUB_INIT_LIMIT=1 "$H" start "$T/proj" nolist --spec SPEC.md --foreground > "$T/run15c.out" 2>&1; cp "$HARNESS_STATE/proj/nolist/ended" "$T/run15c.ended"; rm -f "$HARNESS_STATE/LIMIT_UNTIL"   # continue rewrites ended
(cd "$T/proj" && git pull -q origin main && echo "revised spec" > SPEC.md && git commit -qam "spec: revised" && git push -q origin main)
STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_LENIENT=1 "$H" continue nolist --foreground > "$T/run15d.out" 2>&1
check "continue after a no-list end merges main first" 'grep -q "^usage limit before the feature list" "$T/run15c.ended" && grep -q revised "$T/wt/proj/nolist/SPEC.md" \
  && hlog nolist | awk "/merged main into harness\/nolist/ && !m { m = NR } /feature list written/ && !f { f = NR } END { exit !(m && f && m < f) }"'

suite_end
