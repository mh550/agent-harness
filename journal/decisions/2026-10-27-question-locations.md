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
  - **Where a question points (U2-08).** Every question for Michael carries a line `Files: <absolute path>[:<line>],
    …` (the branch too when it isn't the run's): prompts/coding.md (*Decisions*, *Waiting on Michael*), verify.md and
    initializer.md ask for it, and an INBOX question goes below the comment block, directly above the `## Answers`
    line, headed `### <feature id>: <one-line title> (<date time>)` with what is blocked, why, `Files:`, options with
    one `(recommended)` and the exact commands. A question without the line is filled from the session, never
    refused: `entries.mjs sessionFiles` (the entry's `files` first, then `git diff --name-only <session start> HEAD --
    . ':!.harness/runs/<run>'`, absolute, deduplicated, at most 8). At ingest `fillQuestions` appends ` Files
    (harness, from the session): …` to each entry question without one; nothing else of the entry changes. A park
    whose INBOX question has none gets the same list as its card's `where`, `files_from: "session"` (the lane passes
    `session_files=`). The run directory's paths are left out (a lane's copy goes). `inbox.mjs files` reads the label
    bold, in backticks or in parentheses too, and an item only when it has a `/` or `.` and no blank, so `**Files:**`
    counts and "the Files: section" doesn't. Either fill notes `<id>: <n> question(s) had no Files: line; filled from the session's diff`.
  - **The review (U2-09).**
    - The `## Answers` heading may go on after a blank, `:` or `(` (`## Answers (Michael)`, as the old sed prefix
      allowed), never after `".`.
    - `repair` moves an insertion only when it has 12 or more non-blank characters: a reword of the comment stays.
    - The lane's park note says that the card's `where` is the session's files; the entry's fill keeps its own note.
- **Rejected:** refusing a question without `Files:` (the session is over by then: the question would be lost, or a
  feature re-run for want of a line). A model filling the paths (a second session, guesses; the diff is what the
  session touched, and the harness has it). Rewriting the session's text otherwise (the fill only appends, so what
  the session said is there byte for byte). Repairing only the record's INBOX.md (the step's first wording): with lanes a session never writes it,
  and `take_question` would already have copied the comment's fragments in. Matching the heading by line diff alone:
  a split line leaves both halves as "added" lines, comment text included. Dropping the comment from the template:
  it is how Michael learns the steering words on his phone.

Updated in place 2026-10-28: U2-08's question locations (prompts, the fill) complete it.
Updated in place 2026-10-28: U2-09's review (the heading rule, the repair floor, the park note).
