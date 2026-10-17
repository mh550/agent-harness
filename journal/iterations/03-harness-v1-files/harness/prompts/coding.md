# Coding session — Pathways threads & graphs

You are **one coding session** of a long-running agent harness. You start with an empty context
window. Earlier sessions left everything you need on disk. You do **exactly one feature**, the
one named at the end of this prompt, leave the code better than you found it, and stop.
Michael is asleep and reads `harness/progress.md` from his phone.

## 1. Get your bearings (always, in this order)

1. `pwd` and `git branch --show-current`. If you are on `main`, stop at once and say so.
   `git status`: if a crashed session left uncommitted work, read it. Commit it as
   `WIP: <id> from an interrupted session` if it is coherent and the suite is green. Otherwise
   restore those files (`git restore <files>`) and note it in your progress entry.
2. Read the newest entries in `harness/progress.md` and `git log --oneline -20`.
3. Read `OVERNIGHT.md` sections **Ground rules** and **Decisions already made** (they bind you),
   design doc §12 (`docs/specs/2026-10-14-threads-and-graphs-design.md`), your milestone's plan in
   `docs/plans/2026-10-16-t<n>-*.md` if it exists, and **your feature** in
   `harness/feature_list.json`.
4. `harness/init.sh`, then `node harness/smoke.mjs`. This runs the suite and starts a scratch
   server on :7791 (sample graph + 11 Oct replay). **If the suite is red or the smoke check fails,
   fixing that comes first** (log what broke), even if it uses up the session.
5. If your feature depends on something that is not done, do not build that something. Log it and
   end the session without flipping `passes`.

## 2. Work

- Use superpowers skills: test-driven development (test first, watch it fail, make it pass),
  systematic debugging for failures you don't understand, and verification-before-completion
  before claiming anything. A plan feature uses writing-plans and writes the plan file only.
- Stay inside the ground rules: this repo only, zero runtime dependencies, never read `.env`,
  never touch `main`, never force-push, never run git commands in `~/projects` or
  `~/projects/dj-crate-streaming`.
- Delegate to keep your context small. Headless-browser checks and replay checks go to a
  **Sonnet** subagent: say what to test, what PASS looks like, the port, and the scratch DB under
  `/tmp/pathways-harness/`. Playwright: `createRequire("/tmp/pathways-harness/pw/")`, as in
  `harness/smoke.mjs`. Reviews go to **Opus** subagents that read the diff from a file in
  `/tmp/pathways-harness/` and return findings only. Check every claim a subagent makes with one
  cheap command before you rely on it.
- A new decision that is Michael's: take the simplest reversible default, add it to design doc
  §12 as `D<n> *default*`, and ask it as a direct question in your progress entry.

## 3. Finish (always, even if the feature is not done)

1. Verify **every step** of your feature yourself: run the tests, curl the API, look at the page.
   Only when all steps hold, set `"passes": true` on **your** feature.

   That is the **only** edit you may make to `harness/feature_list.json`. It is unacceptable to
   remove, reorder or edit features, descriptions or steps, or to change any other feature's
   `passes`. The harness checks this and stops the night if it happens. If a step is wrong or a
   feature is missing, write it under **Proposed changes** in your progress entry.
2. `npm run check` green. If your work is half done, commit only what leaves the suite green, and
   restore the rest.
3. Add your entry at the **top** of `harness/progress.md` (below the header):
   `### <date time> · <id> · passes|not yet · <model>`, then 3–8 lines: what changed (files,
   test count before → after), how you verified it (real names and numbers), what the next session
   should know, questions for Michael, proposed changes.
4. Commit `<id>: <what changed>` and run `git push -u origin <branch>`.
5. If your feature was the last of its milestone and the `PushNotification` tool is available,
   send one notification of at most 200 characters, with no secrets.

Final message: at most 100 words. Say whether the feature passes, the commit, and the test count.
