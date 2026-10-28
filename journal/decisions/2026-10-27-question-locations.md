# Questions where Michael sees them: one INBOX parser, the steering comment repaired

*(2026-10-28, run agent-harness-2026-10-28, feature U2-02; spec `docs/specs/2026-10-27-status-ux.md` §U2 (bug a),
plan `docs/plans/2026-10-28-U2-needs-record.md` §4.4 and §7.5. Started by U2-02 (the parser and the repair); U2-08
adds the questions' locations (`Files:`, the fill) and completes it.)*

- **Finding:** n8n-home's INBOX.md at `4632d1c` (now `tests/fixtures/inbox-q-in-comment.md`): a session wrote its Q1
  inside the steering comment, splitting the template's `under "## Answers".` mid-line. GitHub renders none of a
  comment, so Michael never saw Q1, and every reader cut at the first `/^## Answers/` line: line 13, `## Answers".`,
  inside the comment, not the heading on line 28. `parked.mjs` (`questionFor`), `notify.mjs` (`inboxQuestion`),
  `answers_hash` and `take_question_` (lib/record.sh) and the context pack (`entries.mjs`) each had their own cut.
- **Choice:**
  - `lib/inbox.mjs`, pure: `answersLine` is the first line that is exactly `## Answers` (trailing blanks and a CR
    allowed) and does not start inside an HTML comment, read as GitHub renders one: a `<!--` starting a line runs to
    its `-->` or the end of the file, one inside a line counts only when a `-->` follows, one in backticks is text (a
    question that mentions `<!--` must not hide the heading and freeze the answers hash). `question`, `added`,
    `answers` and `insert` cut there; parked.mjs, notify.mjs (their exported names kept), record.sh and the pack call
    it. `answers` is byte for byte the old `sed -n '/^## Answers/,$p'` on an INBOX whose comment was never split, so
    no run unparks from the switch; one whose comment was split hashes from its real heading from now on.
  - `repair(before, after)`: the steering comment is `before`'s first comment, found in `after` from its first line
    to its last (a `-->` in the session's question is not its end), else at the same offset; gone, nothing happens.
    A pure insertion (the two comments' longest common prefix and suffix cover `before`'s) is moved whole, placed
    along a repeated run where it keeps lines, then words, whole (`"## ` + `Questions…## ` is `"` + `## Questions…`);
    an insertion among edits of the comment moves its runs outside the two comments' longest common subsequence of
    12 or more visible characters. Either way the comment goes back to its bytes and the text goes above
    `## Answers`. **(*default*)** A comment the session only reworded is left alone: nothing moves, no note. `added`
    reads the repaired text without comments, so the question is the question alone.
  - Where it runs: on the copy the session wrote, before anything reads it. A lane's session writes its slot's copy,
    so `inbox_repair` (lib/record.sh) runs on `$SLOT/$RUN_DIR/INBOX.md` against `$LS/inbox-before.md` right after
    the session, before `take_question` carries the question into the record; the initializer writes the record's
    INBOX.md itself, so it runs there against `$STATE/inbox-before.md`. On a change:
    `INBOX.md: <id>'s question was inside the steering comment (hidden on GitHub); moved below it`.
  - The driver's template comment no longer contains `## Answers`: it says to write answers under the Answers
    heading at the end of the file, so there is nothing in it to split.
- **Rejected:** repairing only the record's INBOX.md (the step's first wording): with lanes a session never writes it,
  and `take_question` would already have copied the comment's fragments in. Matching the heading by line diff alone:
  a split line leaves both halves as "added" lines, comment text included. Dropping the comment from the template:
  it is how Michael learns the steering words on his phone.
