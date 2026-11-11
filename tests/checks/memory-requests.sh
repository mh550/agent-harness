#!/usr/bin/env bash
# tier: fast
source "$(dirname "$0")/../lib.sh" && suite_setup
# ---- the review surface's verbs (docs/specs/2026-11-10-review-surface.md V2): a memory PR's merge and close from the
# card, and the run-level decline a close with a why writes (harness memory decline <run> --why) ----
# No stub run: the ledger is built here as a run's ledger() leaves it, its memory-result.json from curator.mjs apply over
# tests/fixtures/memory's corrected ops and entries (the driver's own call), its memory-answers.jsonl a ledger commit.
status_stubs
L=$HARNESS_LEDGER
cp "$T/base-config.sh" "$T/user-config.sh" && echo 'LEDGER_COMMIT=1' >> "$T/user-config.sh"
mkdir -p "$L/proj/r1" "$T/mw" && printf '# proj\n\n## Gotchas\n\n- a seeded gotcha (seed 2026-11-01)\n' > "$T/mw/CLAUDE.md"
node "$HERE/../lib/curator.mjs" apply "$HERE/fixtures/memory/corrected.ops.json" "$T/mw" r1 "$HERE/fixtures/memory/corrected.entries.jsonl" \
  | jq -c 'del(.ruleTexts)' > "$L/proj/r1/memory-result.json"   # as driver.sh's ledger copy writes it
git init -q -b main "$L" && git -C "$L" config user.name t && git -C "$L" config user.email t@t
git -C "$L" add -A && git -C "$L" commit -qm "ledger: r1"
lines() { git -C "$L" log --oneline | wc -l; }

# by hand: the facts PR of r1 closed on GitHub with a reason the next curator should read
n0=$(lines)
"$H" memory decline r1 --why 'these facts are stale' > "$T/d1.out" 2> "$T/d1.err"; d1=$?
check "harness memory decline <run> --why: one run-level row in memory-answers.jsonl and one ledger commit" \
  '(( d1 == 0 )) && [[ $(cat "$T/d1.out") == "memory: r1 declined · the facts PR · these facts are stale" && ! -s $T/d1.err ]] \
  && jq -e -s "length == 1 and (.[0] | keys_unsorted == [\"run\",\"project\",\"n\",\"tier\",\"verdict\",\"why\",\"file\",\"section\",\"text\",\"key\",\"at\"]
       and .run == \"r1\" and .project == \"proj\" and .n == null and .tier == 1 and .verdict == \"declined\" and .why == \"these facts are stale\"
       and .file == null and .section == null and .text == null and .key == null)" "$L/memory-answers.jsonl" > /dev/null \
  && (( $(lines) == n0 + 1 )) && [[ $(git -C "$L" log -1 --format=%s) == "ledger: memory decline r1" && -z $(git -C "$L" status --porcelain) ]]'

cp "$L/memory-answers.jsonl" "$T/answers-before"; n1=$(lines)
"$H" memory decline r1 > "$T/d2.out" 2> "$T/d2.err"; d2=$?
check "harness memory decline <run> without --why: one usage: line on stderr, exit 1, no row written" \
  '(( d2 == 1 )) && [[ ! -s $T/d2.out && $(wc -l < "$T/d2.err") == 1 ]] && grep -x "memory: usage: harness memory decline <run>/<n> --why \"<text>\" | decline <run> --why \"<text>\"" "$T/d2.err" > /dev/null \
  && cmp "$T/answers-before" "$L/memory-answers.jsonl" && (( $(lines) == n1 ))'

suite_end
