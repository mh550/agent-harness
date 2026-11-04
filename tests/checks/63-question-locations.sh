#!/usr/bin/env bash
source "$(dirname "$0")/../lib.sh" && suite_setup
# ---- questions say where (U2-08): the prompts ask for a Files: line and a fixed place in INBOX.md; a question
# without one gets the session's files (the entry's, then its diff), in the journal entry and in the park's card ----
# Plan: docs/plans/2026-10-28-U2-needs-record.md §4.6. Decision: decisions/2026-10-27-question-locations.
nj() { jq -s "${2:-.}" "$HARNESS_STATE/proj/$1"/needs/*.json 2> /dev/null; }   # <run> [<jq over its open items>]
# the fill (entries.mjs) and the card's where (needs.mjs) on literal input: tests/unit/needs.test.mjs

check "the prompts ask every question for a Files: line and an INBOX question below the comment block, headed ### <id>: …" \
  '[[ -z $(cd "$HERE/../prompts" && grep -LF "Files: <absolute path>[:<line>]" coding.md verify.md initializer.md) ]] \
  && grep -F "below the comment block" "$HERE/../prompts/coding.md" > /dev/null && grep -F "### <feature id>: <one-line title> (<date time>)" "$HERE/../prompts/coding.md" > /dev/null \
  && grep -F "(recommended)" "$HERE/../prompts/coding.md" > /dev/null'

main0=$(git -C "$T/origin.git" rev-parse main)
# a stub run: A asks in its entry (no Files:) and also changes lib/x.sh; B parks with Files: <path>:48 in INBOX.md
STUB_ASK=A STUB_ASK_TOUCH=lib/x.sh STUB_PARK=B STUB_PARK_FILES="/srv/q/lib/y.sh:48" STUB_INDEPENDENT_M2=1 STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_LENIENT=1 \
  "$H" start "$T/proj" ql --spec SPEC.md --foreground > "$T/ql.out" 2>&1
QA=$(jq -rs '[.[] | select(.feature == "A" and .kind == "coding") | .questions[]?][0] // ""' "$T/wt/proj/ql/.harness/runs/ql/entries.jsonl")
check "the journal fills an entry question without Files: from the session (its files, then lib/x.sh from its diff, absolute); noted" \
  '[[ $QA =~ ^"Should A default to off? Files (harness, from the session): "(/[^,]*)/work-A.txt", "(/[^,]*)/lib/x.sh$ ]] && [[ ${BASH_REMATCH[1]} == "${BASH_REMATCH[2]}" ]] \
  && hlog ql | grep -F "A: 1 question(s) had no Files: line; filled from the session'"'"'s diff" > /dev/null'
check "a park whose INBOX question has Files: <path>:48: the record's where[0] is that path at line 48, files_from question" \
  '[[ $(nj ql ".[] | select(.reason == \"parked\") | [.card.where[0].path, .card.where[0].line, .card.files_from] | join(\" \")" | jq -r .) == "/srv/q/lib/y.sh 48 question" ]]'

# a park without Files: whose session changed lib/z.sh: the card's where is the session's, noted
git -C "$T/origin.git" update-ref refs/heads/main "$main0"
STUB_PARK=B STUB_PARK_TOUCH=lib/z.sh STUB_INDEPENDENT_M2=1 STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_LENIENT=1 \
  "$H" start "$T/proj" qs --spec SPEC.md --foreground > "$T/qs.out" 2>&1
check "a park without Files: gets the session's files as the card's where (files_from session, absolute lib/z.sh); noted" \
  'W=$(nj qs ".[] | select(.reason == \"parked\") | [.card.files_from, .card.where[0].path] | join(\" \")" | jq -r .) && [[ $W =~ ^"session /".*"/lib/z.sh"$ ]] \
  && [[ $(hlog qs | grep -cF "B: its INBOX question had no Files: line; the park card'"'"'s where is the session'"'"'s files") == 1 ]]'
