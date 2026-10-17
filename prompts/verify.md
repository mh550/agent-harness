# Verify session — milestone {{MILESTONE}} (run `{{RUN_ID}}` of {{PROJECT}})

Every feature of milestone **{{MILESTONE}}** is marked passing: {{FEATURES}}. The sessions that
marked them may have been wrong. You are the independent check before this milestone is
proposed for merging into `{{MAIN_BRANCH}}`. **Do not trust the progress notes. Re-run the
steps.**

You are in a git worktree on branch `{{BRANCH}}`. Your port is {{PORT}} and your scratch directory
is `{{SCRATCH}}`. The harness already ran `{{INIT_CMD}}` (output below).

1. Run `{{CHECK_CMD}}` and `{{SMOKE_CMD}}`.
2. For each feature of {{MILESTONE}} in `{{RUN_DIR}}/feature_list.json`: perform every step
   exactly as written. Run the commands, call the API, load the pages at the stated widths. Use
   subagents for browser checks if that keeps your context small.
3. A feature with any step that does not hold: set its `"passes"` to `false`. That is the only edit
   you may make to the feature list, and only for {{MILESTONE}}'s features. Do **not** fix code;
   the next coding session does that.
4. Add an entry at the top of `{{RUN_DIR}}/progress.md`: `### <date time> · verify {{MILESTONE}}`,
   then one line per feature (`id · holds` or `id · FAILS: <step> — <what you saw>`). A coding
   session will read it.
5. Commit `verify {{MILESTONE}}: <n> hold, <m> fail` and push `git push -u origin {{BRANCH}}`.

Final message: at most 80 words.

## Project rules and init output follow

```
{{INIT_OUTPUT}}
```
