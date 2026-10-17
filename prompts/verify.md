# Verify session — milestone {{MILESTONE}} (run `{{RUN_ID}}` of {{PROJECT}})

Every feature of milestone **{{MILESTONE}}** is marked passing: {{FEATURES}}. The sessions that
marked them may have been wrong. You are the independent check before this milestone is merged
into `{{MAIN_BRANCH}}`. **Do not trust the progress notes. Re-run the steps.**

You are in a git worktree (`{{WT}}`) on branch `{{BRANCH}}`; main's latest commits have just been
merged in. Your port is {{PORT}} and your scratch directory is `{{SCRATCH}}`. The harness already ran
the init and the suite (output below).

1. Run `{{CHECK}}` and `{{SMOKE_CMD}}`.
2. For each feature of {{MILESTONE}} in `{{RUN_DIR}}/feature_list.json`: perform **every step
   exactly as written**. Run the commands, call the API, load the pages at the stated widths (a
   Sonnet subagent with a headless browser for UI steps keeps your context small). "A test covers
   it" counts only if you name the test, read its assertion and it matches the step.
3. A feature with any step that does not hold: set its `"passes"` to `false`. That is the only edit
   you may make to the feature list, and only for {{MILESTONE}}'s features. Do **not** fix code;
   the next coding session does that.
4. Add an entry at the top of `{{RUN_DIR}}/progress.md` (directly below its header):
   `### <date time> · verify {{MILESTONE}}`, then **one table row per step of every feature**:

   | Feature | Step | What you ran or read | What you saw | Holds |
   |---|---|---|---|---|
   | T1-02 | 1 | `node --test tests/threads.test.ts` | 7/7 pass; asserts graphSongIds(…) = ['a','b','c','d'] | yes |

   The harness counts these rows. Fewer rows than steps means your check was too thin and it is
   repeated on a stronger model.
5. Commit `verify {{MILESTONE}}: <n> hold, <m> fail` and push `git push -u origin {{BRANCH}}`.

Final message: at most 80 words.

## Init output

```
{{INIT_OUTPUT}}
```
