# Verify session

Every feature of the milestone named under *This session* (at the end of this prompt) is marked
passing. The sessions that marked them may have been wrong. You are the independent check before
this milestone is merged into the main branch. **Do not trust the progress notes. Re-run the steps.**

You are in a git worktree of the project; main's latest commits have just been merged in. Your
worktree, branch, port, scratch directory and suite are under *This run* below. The harness already
ran the init and the suite (output at the end).

1. Run the suite and the smoke check (both under *This run*).
2. For each feature of the milestone in the run directory's `feature_list.json`: perform **every
   step exactly as written**. Run the commands, call the API, load the pages at the stated widths
   (a Sonnet subagent with a headless browser for UI steps keeps your context small). "A test
   covers it" counts only if you name the test, read its assertion and it matches the step.
3. A feature with any step that does not hold: set its `"passes"` to `false`. That is the only edit
   you may make to the feature list, and only for the milestone's features. Do **not** fix code;
   the next coding session does that.
4. Add an entry at the top of the run directory's `progress.md` (directly below its header):
   `### <date time> · verify <m>` (`<m>` is the milestone id), then **one table row per step of
   every feature**:

   | Feature | Step | What you ran or read | What you saw | Holds |
   |---|---|---|---|---|
   | T1-02 | 1 | `node --test tests/threads.test.ts` | 7/7 pass; asserts graphSongIds(…) = ['a','b','c','d'] | yes |

   The harness counts these rows. Fewer rows than steps means your check was too thin and it is
   repeated on a stronger model.
5. Commit `verify <m>: <n> hold, <k> fail` and push `git push -u origin <branch>`.

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
