#!/usr/bin/env bash
source "$(dirname "$0")/../lib.sh" && suite_setup
# ---- the scheduler, pure: "after" may name a milestone (all of its features) ----
DEPS='import { deps } from "'$HERE'/../lib/features.mjs"; const l = [{ id: "A", milestone: "M1" }, { id: "B", milestone: "M1" },
  { id: "C", milestone: "M2", after: ["M1"] }, { id: "D", milestone: "M3", after: ["C", "M9"] }];
  process.exit(deps(l, l[2]).join() === "A,B" && deps(l, l[3]).join() === "C,M9" ? 0 : 1);'
check "after may name a milestone"        'node --input-type=module -e "$DEPS"'

suite_end
