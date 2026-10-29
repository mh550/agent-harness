#!/usr/bin/env bash
source "$(dirname "$0")/../lib.sh" && suite_setup
# ---- gc's foreign units (U3-03, decisions/2026-10-27-gc-foreign-units): a unit of another project's run, live ----
# ---- or ended, is that project's gc's and is skipped silently; ? only for a unit no run on this box owns ----
sleep 60 & OL=$!   # sleep-ok: olive's live driver
for r in other/olive:$OL other/oend: proj/pend:; do d=$HARNESS_STATE/${r%%:*}; mkdir -p "$d"
  printf 'RUN_ID=%s\nPROJECT_DIR=%s\nWT=%s\n' "${d##*/}" "$T/${r%%/*}" "$T/wt/${r%/*}" > "$d/meta.env"; [[ -n ${r#*:} ]] && echo "${r#*:}" > "$d/driver.pid"; done
echo done > "$HARNESS_STATE/other/oend/ended"; echo done > "$HARNESS_STATE/proj/pend/ended"
mkdir -p "$T/scope"; for u in harness-olive-svc harness-oend-s3 harness-pend-svc; do touch "$T/scope/$u".{alive,running}; done
"$H" gc "$T/proj" --dry-run > "$T/gu1.out" 2>&1
check "gc units: --dry-run with units of another project's runs (live and ended) prints no ? line and no line naming them" '
  ! grep "^?" "$T/gu1.out" > /dev/null && ! grep -e harness-olive -e harness-oend "$T/gu1.out" > /dev/null &&
  grep -x "would: systemctl --user stop harness-pend-svc.scope (pend ended)" "$T/gu1.out" > /dev/null'
touch "$T/scope/harness-x".{alive,running}
"$H" gc "$T/proj" --dry-run > "$T/gu2.out" 2>&1; "$H" gc "$T/proj" > "$T/gu3.out" 2>&1
check "gc units: a unit no run on this box owns prints the ? line with the command, with and without --dry-run, and stays" '
  l="? harness-x.scope: no run on this box owns it (systemctl --user stop harness-x.scope by hand)" &&
  [[ $(grep "^?" "$T/gu2.out") == "$l" && $(grep "^?" "$T/gu3.out") == "$l" ]] &&
  grep -x "+ stopped harness-pend-svc.scope (pend ended)" "$T/gu3.out" > /dev/null &&
  "$HARNESS_SYSTEMCTL" --user list-units "harness-*" --plain --no-legend | cut -d" " -f1 | sort | paste -sd" " | grep -x "harness-oend-s3.scope harness-olive-svc.scope harness-x.scope" > /dev/null'
kill "$OL" 2> /dev/null; wait "$OL" 2> /dev/null
suite_end
