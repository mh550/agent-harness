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

# check.sh: one row per call that ran or answered (full, cached, subset), the epoch first; no suite configured, none
CR=$T/cr; mkdir -p "$CR/repo" && git -C "$CR/repo" init -q && echo x > "$CR/repo/x" && git -C "$CR/repo" add x && git -C "$CR/repo" commit -qm x
(cd "$CR/repo" && export HARNESS_SCRATCH=$CR/s HARNESS_CHECK_CACHE=$CR/c HARNESS_CHECK_CMD=true HARNESS_CHECK_KEY_IGNORE="" HARNESS_SCOPE_PREFIX=""; "$HERE/../lib/check.sh"; "$HERE/../lib/check.sh"; "$HERE/../lib/check.sh" x
  HARNESS_CHECK_CMD="" "$HERE/../lib/check.sh") > /dev/null 2>&1
check "check.sh: appends <epoch> <full|cached|subset> <seconds> to check-runs.log on each call; no suite configured, no row" \
  '[[ $(cut -f2 "$CR/s/check-runs.log" | paste -sd " " -) == "full cached subset" ]] && ! grep -vP "^[0-9]+(\.[0-9]+)?\t(full|cached|subset)\t[0-9]+$" "$CR/s/check-runs.log" > /dev/null'

# sr: A's first coding session runs the suite in full and as a subset; B's none. A is a sonnet feature: its reviewers too
STUB_RUN_SUITE=A STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_LENIENT=1 "$H" start "$T/proj" sr --spec SPEC.md --foreground > "$T/sr.out" 2>&1
git reset -q --hard "$main0"; git -C "$T/origin.git" update-ref refs/heads/main "$main0"
check "lane: each coding session's suite calls are noted from check-runs.log, cached ones aside (A: 2x, B: 0x (0 s))" \
  'hlog sr | grep -F "· A: suite ran 2x (" > /dev/null && hlog sr | grep -F "· B: suite ran 0x (0 s) in the session" > /dev/null'
check "coding prompt: reviews go to subagents on the session's own model (A's prompt, its metrics row, prompt.sh's render: claude-sonnet-5-5)" \
  'p=$(ls "$HARNESS_STATE/proj/sr/logs/"*-A.prompt.md | head -1) && grep -F "subagents on your own model (\`claude-sonnet-5-5\`)" "$p" > /dev/null \
  && bash "$HERE/../lib/prompt.sh" "$HARNESS_STATE/proj/sr" coding A 2> /dev/null | grep -F "subagents on your own model (\`claude-sonnet-5-5\`)" > /dev/null \
  && [[ $(jq -r "select(.feature == \"A\" and .kind == \"coding\") | .model" "$T/wt/proj/sr/.harness/runs/sr/metrics.jsonl" | sort -u) == claude-sonnet-5-5 ]]'

suite_end
