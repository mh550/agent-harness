#!/usr/bin/env bash
source "$(dirname "$0")/../lib.sh" && suite_setup
# ---- questions say where (U2-08): the prompts ask for a Files: line and a fixed place in INBOX.md; a question
# without one gets the session's files (the entry's, then its diff), in the journal entry and in the park's card ----
# Plan: docs/plans/2026-10-28-U2-needs-record.md §4.6. Decision: decisions/2026-10-27-question-locations.
nj() { jq -s "${2:-.}" "$HARNESS_STATE/proj/$1"/needs/*.json 2> /dev/null; }   # <run> [<jq over its open items>]
E=$HERE/../lib/entries.mjs N=$HERE/../lib/needs.mjs

check "the prompts ask every question for a Files: line and an INBOX question below the comment block, headed ### <id>: …" \
  '[[ -z $(cd "$HERE/../prompts" && grep -LF "Files: <absolute path>[:<line>]" coding.md verify.md initializer.md) ]] \
  && grep -F "below the comment block" "$HERE/../prompts/coding.md" > /dev/null && grep -F "### <feature id>: <one-line title> (<date time>)" "$HERE/../prompts/coding.md" > /dev/null \
  && grep -F "(recommended)" "$HERE/../prompts/coding.md" > /dev/null'
check "entries.mjs fill: a question without Files: gets the session's files appended (entry's first, absolute, deduplicated, 8 at most, no run dir); the rest byte for byte; a bold or backticked Files: counts" \
  'node --input-type=module -e "
    import { sessionFiles, fillQuestions } from \"$E\";
    const e = { feature: \"A\", kind: \"coding\", outcome: \"not yet\", summary: \"s\", files: [\"lib/a.sh\"], questions: [\"Q one?\", \"Q two? Files: /x/b.md:4\"], dead_ends: [] };
    const fs = sessionFiles(e.files, [\"lib/a.sh\", \"/abs/c.mjs\", ...Array.from({ length: 9 }, (_, i) => \"d\" + i)], \"/wt\");
    const ok1 = fs.length === 8 && fs[0] === \"/wt/lib/a.sh\" && fs[1] === \"/abs/c.mjs\" && fs[2] === \"/wt/d0\";
    const before = JSON.stringify(e), { entry, filled } = fillQuestions(e, fs);
    const ok2 = filled === 1 && entry.questions[0] === \"Q one? Files (harness, from the session): \" + fs.join(\", \") && entry.questions[1] === e.questions[1];
    const ok3 = JSON.stringify({ ...entry, questions: e.questions }) === before && JSON.stringify(e) === before;
    const none = fillQuestions(e, []), ok4 = none.filled === 0 && none.entry === e;
    const md = fillQuestions({ questions: [\"Q? **Files:** /a/b.sh:4\", \"Q? \`Files:\` /a/c.sh\", \"Q? (Files: /a/d.sh)\", \"Should the Files: section stay?\"] }, [\"/wt/x\"]);
    const ok5 = md.filled === 1 && md.entry.questions[3].endsWith(\"Files (harness, from the session): /wt/x\");
    const ok6 = sessionFiles([\".harness/runs/r/INBOX.md\", \"lib/a.sh\"], [], \"/wt\").join() === \"/wt/lib/a.sh\";
    process.exit(ok1 && ok2 && ok3 && ok4 && ok5 && ok6 ? 0 : 1)"'
check "needs.mjs card: a park whose question has no Files: takes session_files as where, files_from session; with Files: the question wins" \
  'node --input-type=module -e "
    import { card } from \"$N\";
    const inbox = (f) => \"status: run\n\n### B: set it (2026-10-28 01:00)\n\" + f + \"\n## Answers\n\";
    const base = { run: \"r\", subject: \"B\", features: [{ id: \"B\", milestone: \"M1\" }], worktree: \"/wt\", session_files: \"/wt/lib/x.sh\n/wt/y.md\" };
    const s = card(\"parked\", { ...base, inbox_text: inbox(\"\") }), q = card(\"parked\", { ...base, inbox_text: inbox(\"Files: /wt/lib/z.sh:48\") });
    const d = card(\"parked\", { ...base, session_files: \"\", inbox_text: inbox(\"\") });
    process.exit(s.files_from === \"session\" && s.where[0].path === \"/wt/lib/x.sh\" && s.where[1].path === \"/wt/y.md\"
      && q.files_from === \"question\" && q.where[0].line === 48 && q.where.every(w => w.path !== \"/wt/lib/x.sh\") && d.files_from === \"driver\" ? 0 : 1)"'

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
  && hlog qs | grep -F "B: 1 question(s) had no Files: line; filled from the session'"'"'s diff" > /dev/null'
