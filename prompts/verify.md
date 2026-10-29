# Verify session

Every feature of the milestone named under *This session* (at the end of this prompt) is marked
passing. The sessions that marked them may have been wrong. You are the independent check before
this milestone is merged into the main branch. **Do not trust the progress notes. Re-run the steps.**

You are in a git worktree of the project; main's latest commits have just been merged in. Your
worktree, branch, port, scratch directory and suite are under *This run* below. The harness already
ran the init and the suite (output at the end).

Read context.md first; the full record is entries.jsonl / progress-archive.md (all in the run directory).
It says what the milestone's sessions tried. It is not evidence: re-run every step yourself.

1. Run the suite and the smoke check (both under *This run*). The harness
   cleared the suite's cached result for this tree before this session, so the suite runs in full:
   the init output below is a full run, not a cached one.
2. For each feature of the milestone in the run directory's `feature_list.json`: perform **every
   step exactly as written**. Run the commands, call the API, load the pages at the stated widths
   (a Sonnet subagent with a headless browser for UI steps keeps your context small). "A test
   covers it" counts only if you name the test, read its assertion and it matches the step.
3. A feature with any step that does not hold: set its `"passes"` to `false`. That is the only edit
   you may make to the feature list, and only for the milestone's features. Do **not** fix code;
   the next coding session does that.
4. Write the run directory's `entry.json`, your entry in the run's journal: one JSON object with
   **one `evidence` row per step of every feature** of the milestone (`holds` true or false). The
   harness validates it, adds it to `entries.jsonl`, deletes it and renders it into `progress.md` as
   a table for Michael's phone (don't edit progress.md yourself). Required: `feature` (the milestone
   id), `kind` (`"verify"`), `outcome` (`passes` when every feature holds, else `not yet`) and
   `summary` (at most 400 characters). For example:

   ```json
   { "feature": "M1", "kind": "verify", "outcome": "not yet", "summary": "T1-02 holds; T1-03 step 2 fails: …",
     "evidence": [{ "feature": "T1-02", "step": 1, "ran": "node --test tests/threads.test.ts",
                    "saw": "7/7 pass; asserts graphSongIds(…) = ['a','b','c','d']", "holds": true },
                  { "feature": "T1-03", "step": 2, "ran": "curl :7804/x", "saw": "500", "holds": false }] }
   ```

   A question for Michael goes in `questions` (in `INBOX.md` only when the milestone can't be
   checked without him: below the comment block, directly above the `## Answers` line, headed
   `### <milestone>: <one-line title> (<date time>)`), with a line `Files: <absolute path>[:<line>], …`
   naming what he should open first (the failing step's code or test; the branch when it isn't
   this run's); one without it gets the files your session changed, filled in by the harness.

   The harness counts these rows. Fewer rows than steps means your check was too thin and it is
   repeated on a stronger model. A missing or invalid `entry.json` leaves only a minimal entry,
   with no rows. Then run `{{ENTRY_CHECK}} <run directory>/entry.json <milestone> verify` and fix
   every line it prints; it prints nothing when the entry is valid.
5. Commit `verify <m>: <n> hold, <k> fail` and push `git push -u origin <branch>`.

Never end your turn while a background task or subagent is still running: wait for it, or stop it
and say so in your entry.

The project's policy comes right after these instructions. It binds you.

Final message: at most 80 words.

{{SECTIONS}}

---

# This session

Milestone: {{MILESTONE}}
Features: {{FEATURES}}
{{CLOCK}}

## Init output

```
{{INIT_OUTPUT}}
```
