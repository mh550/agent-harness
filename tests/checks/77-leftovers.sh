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

main0=$(git -C "$T/origin.git" rev-parse main)
# im: another run's record lands on main during M1's verify (after the lane merged main in), a path the suite's cache key ignores (.harness/runs):
# M1 merges as verified, without a re-base. The record PR is on (RECORD_PR=end), so finish's order shows in the ledger
echo 'RECORD_PR=end' >> "$T/user-config.sh"
STUB_MAIN_TOUCH=verify-M1:.harness/runs/other/x.md STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_LENIENT=1 "$H" start "$T/proj" im --spec SPEC.md --foreground > "$T/im.out" 2>&1
cp "$T/base-config.sh" "$T/user-config.sh"
check "merge_one: a main moved only in ignored paths merges the milestone as verified, its note naming them; no re-base" \
  'hlog im | grep "· M1 merged into main · " > /dev/null && hlog im | grep -F "M1: main changed only in ignored paths" > /dev/null \
  && ! hlog im | grep -E "M1.*(re-base|moved since)" > /dev/null && git -C "$T/origin.git" cat-file -e main:.harness/runs/other/x.md'
check "finish: record_pr runs before ledger, so the ledger copy of harness-log.md holds the record PR note" \
  'grep -F "record PR merged into main" "$T/ledger/proj/im/harness-log.md" > /dev/null'

# gr: main is red when the run starts (BROKEN), A's first session fixes it; the count is pinned from the first green suite only
git -C "$T/origin.git" update-ref refs/heads/main "$main0"
git reset -q --hard "$main0" && touch BROKEN && git add BROKEN && git commit -qm "red main" && git push -q origin main
mkdir -p "$HARNESS_STATE/proj/gr" && echo "CHECK_CMD='test ! -f BROKEN && echo \"1/1 checks passed\"'" > "$HARNESS_STATE/proj/gr/run.env"
STUB_FIX_BROKEN=A STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_LENIENT=1 "$H" start "$T/proj" gr --spec SPEC.md --foreground > "$T/gr.out" 2>&1
git reset -q --hard "$main0"; git -C "$T/origin.git" update-ref refs/heads/main "$main0"
check "run_init: a red first suite pins no test count; the first green one does (tests-start 1, one test count: line, parsed)" \
  '[[ $(cat "$HARNESS_STATE/proj/gr/tests-start") == 1 && $(hlog gr | grep -c "test count: ") == 1 ]] \
  && hlog gr | grep "test count: parsed (" > /dev/null && grep -q "suite red before the session" "$HARNESS_STATE/proj/gr/run.log"'

suite_end
