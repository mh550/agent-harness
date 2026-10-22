# An eval's clone holds only `main` = base: no tag, branch, reflog or object of the source past it

*(2026-10-21, E2-08 of run agent-harness-2026-10-21-measure, review finding F1 in `docs/plans/2026-10-21-E2-review.md`;
amends `decisions/2026-10-21-eval-run-isolation`)*

- **Finding:** a local `git clone` copies the source's tags and its whole object store, and `git remote remove origin`
  drops only the remote-tracking refs. `~/projects/agent-harness` carries `run/<run>/<M>` tags for the milestones the
  default tasks replay (P1, P3, E1). A replayed session that ran `git tag` or `git log --all` could `git show` the
  finished answer, which makes every score a contaminated one.
- **Choice:** after `checkout -B main <base>` and `remote remove origin`, `lib/eval.sh seal` deletes every ref but
  `refs/heads/main` (`for-each-ref` → `update-ref --stdin`), expires every reflog and runs `git gc --prune=now`, so
  the objects only those refs reached are gone too. The clone is still made from the full source (a base on any ref
  resolves); the source is only read (a local clone hardlinks its packs, and gc writes a new one). The cost is one
  repack per task (seconds for a 16 MB repo). Checked by `eval run: a clone holds nothing of its source past base`.
- **Rejected:** `git clone --no-tags --single-branch` (keeps the later objects in the store and loses a base that is
  only on a run branch); fetching only `<base>` into an empty repo (needs `uploadpack.allowAnySHA1InWant` or
  protocol v2 behaviour on the source); leaving it to the prompt ("don't read tags"), which is not isolation.
