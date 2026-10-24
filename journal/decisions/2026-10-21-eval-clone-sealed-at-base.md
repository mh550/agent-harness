# An eval's clone holds only `main` = base: no tag, branch, reflog or object of the source past it

*(2026-10-21, E2-08 of run agent-harness-2026-10-21-measure, review finding F1 in `docs/plans/2026-10-21-E2-review.md`;
amends `decisions/2026-10-21-eval-run-isolation`)*

- **Finding:** a local `git clone` copies the source's tags and its whole object store, and `git remote remove origin`
  drops only the remote-tracking refs. `~/projects/agent-harness` carries `run/<run>/<M>` tags for the milestones the
  default tasks replay (P1, P3, E1). A replayed session that ran `git tag` or `git log --all` could `git show` the
  finished answer, which makes every score a contaminated one.
- **Choice:** after `checkout -B main <base>` and `remote remove origin`, `lib/eval.sh seal` does the following:
  - it deletes every ref but `refs/heads/main` (`for-each-ref` → `update-ref --stdin`) and expires every reflog;
  - it drops the copied `pack/*.keep` marks and runs `git repack -ad`, which also copies in what the alternates lent;
  - it removes `info/alternates` and runs `git prune --expire=now`.

  After that, the objects only those refs reached are gone too. The clone is still made from the full source (a base
  on any ref resolves). The source is only read: the clone's copies or hardlinks are its own files. The cost is one
  repack per task, seconds for a 16 MB repo. The seeded `progress.md` names the project and base, not the source's
  path. Checked by `eval run: a clone holds nothing of its source past base` (a later branch, a tag, a kept pack,
  the path).
- **Known limit:** sealing the clone isn't a sandbox. A replayed session runs as Michael, so it can still read
  `~/projects/<project>` itself, whose tags hold the answer; agent-harness's own CLAUDE.md names that checkout. It
  can also read `$HARNESS_HOME`, the ref's worktree, which shares the harness repo's tags. Going there means
  looking outside the project for the answer, not orienting in it, so the eval can't prevent it. A score that seems
  too good is worth a look at the session's tool calls.
- **Also, same review:** a task whose `repo` is not a directory is refused before anything is created (it used to
  pass the check and fail as "clone failed" after earlier tasks had spent). The eval's ports also skip every port file
  in the real state root, not only those in its own.
- **Rejected:** `git clone --no-tags --single-branch` (keeps the later objects in the store and loses a base that is
  only on a run branch); fetching only `<base>` into an empty repo (needs `uploadpack.allowAnySHA1InWant` or
  protocol v2 behaviour on the source); leaving it to the prompt ("don't read tags"), which is not isolation.
