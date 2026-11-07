# The gate replaces the lint: `memlint-self` retired, `MEMORY_POLICY`, and the curator's acceptance counted

*(2026-11-07, run agent-harness-2026-11-07-2, M3 (skeleton and the retirement row by M3-01; the policy row by M3-02,
the counting by M3-03, rejected and the Predictions by M3-04); spec `docs/specs/2026-11-07-memory-curator.md` §M3;
plan `docs/plans/2026-11-07-M3-policy.md`; journal/decisions/2026-11-05-suite-shape.md (where `memlint-self` was cut
out of `39-memlint-m4`); journal/decisions/2026-11-03-trim.md (the rule a removed check follows).)*

- **Finding:** `tests/checks/memlint-self.sh` was the one check that lints the checkout it runs from, "so the one a
  `CLAUDE.md` edit can turn red (a sixteenth Gotchas line did, twice, outside the feature that added it)": a breach
  found by the suite, at the next segment, in a fast file kept in `CHECK_KEY_MAP` for it. Since M1 no coding session's
  `CLAUDE.md` edit survives (decisions/2026-11-07-memory-one-writer), and since M2 the curator's ops are the driver's
  only writes to it, refused whole past the cap (`capCheck`, decisions/2026-11-07-memory-tiers): the breach the check
  caught can no longer be written by a run, and its check runs where the edit happens, for every project, at no suite
  cost. Whether `auto` may merge the curator's PR is a number to read, not a judgement: M3 ships the counter, not the
  switch.
- **Choice:**

  | row | what | by |
  |---|---|---|
  | the retirement | `memlint-self`'s one check made two assertions, each with a successor by the trim's rule (a successor named, the coverage union not smaller): **(a)** `".harness/config.sh"` and `"docs/decisions.md"` on one line each of `lib/memlint.mjs` (the store looked up in one place) → the unit test `memlint: the store lookup is decisionsStore, the one function reading .harness/config.sh and docs/decisions.md, each on one line` (`tests/unit/memlint.test.mjs`: the same line counts, and both literals inside `decisionsStore`'s reach; seen red on a mutant); **(b)** this checkout lints clean → the driver's cap check at the write (`lib/curator.mjs` `capCheck`; `curator.mjs: a 16th Gotchas add without an anchor refuses the tier-1 commit, naming the breach`, `curator.mjs: a result over 120 lines refuses the tier-1 commit`, `memory PR: a 16th Gotchas add without an anchor refuses the tier-1 commit; no branch, no PR`) and, for an edit by hand, the driver's segment-start notes (`driver memlint: two findings are two memlint notes before the initializer's, and the run ends done 3/3`, `tests/checks/memlint-run.sh`). The lines (b) ran (`memlint.mjs`'s `main` and `lint`) are run by the 15 `sameAsCli` unit cases and `memlint-run`'s stub runs. The file is deleted, its name out of both fixtures, `CHECK_KEY_MAP` is `CLAUDE.md:memory-prompts:suite-length:night-words`, and `key-map-lint` and `partial-key` follow. `memlint-run`, the four lints and `harness memlint <project>` stay | M3-01 |
  | the policy | *(M3-02)* | |
  | the counting | *(M3-03)* | |
  | the over-cap projects | *(M3-04)* | |

- **Rejected:** *(M3-04)*
