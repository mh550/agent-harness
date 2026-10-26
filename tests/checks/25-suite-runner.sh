#!/usr/bin/env bash
source "$(dirname "$0")/../lib.sh" && suite_setup
# ---- the suite runner: what lib/check.sh reads from its output ----
TC='import { testCount as t } from "'$HERE'/../lib/testcount.mjs"; const r = "PASS a\n2/2 checks passed\nPASS b\n325/326 checks passed\n";
  process.exit(t(r) === 325 && t("12 passed, 1 failed") === 12 && t("# pass 7\n") === 7 && t("ok") === null ? 0 : 1);'
check "testcount.mjs: the runner's last N/M checks passed is the count" 'node --input-type=module -e "$TC"'
suite_end
