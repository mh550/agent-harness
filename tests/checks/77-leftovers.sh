#!/usr/bin/env bash
source "$(dirname "$0")/../lib.sh" && suite_setup
# ---- R3's leftovers (docs/plans/2026-10-29-R3-leftovers.md): atomic list writes, … ----
# a writer bumps one attempts file 200 times beside a reader that parses it in a loop: an in-place write (truncate, then
# write) shows the reader an empty or half file now and then; a temp file renamed over it never does
f=$T/attempts.json; echo '{}' > "$f"; rm -f "$T/atomic-done" "$T/atomic-bad"
node -e 'const fs = require("fs"), [f, done, bad] = process.argv.slice(1);
  for (;;) { const stop = fs.existsSync(done); try { JSON.parse(fs.readFileSync(f, "utf8")); } catch (e) { fs.writeFileSync(bad, String(e)); break; } if (stop) break; }' \
  "$f" "$T/atomic-done" "$T/atomic-bad" & R=$!
for i in $(seq 200); do $F bump "$f" A; done; touch "$T/atomic-done"; wait "$R"
check "features.mjs writes atomically: 200 bumps beside a parsing reader, which never throws; no temp file left" '
  [[ ! -e $T/atomic-bad && $(jq -r .A "$f") == 200 ]] && ! ls "$T"/attempts.json.*.tmp > /dev/null 2>&1 \
    && [[ $(grep -c writeFileSync "$HERE/../lib/features.mjs") == 1 ]]'

suite_end
