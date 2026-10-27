## Outcome
Not delivered. The run passed 4 of 34 features (B1-01 to B1-04) for $22.45 over 1.3 h across 9 sessions. It stopped on B1-05, the live deploy, because `~/.local/state/harness/requests` doesn't exist. Sessions may not create it, so Michael has to run `install -d -m 700 …` (Q2 in INBOX). B2–B6 (29 features) are marked blocked on B1-05. The run's first start (2026-10-22) ended after 0.6 h and $10.68 with 0/32 passing, blocked on B1-01. The second start passed B1-01 in 2 min.

## Non-passing features by cause
- **B1-05 — permission or classifier denial / environment.** Its last summary says: "bind source ~/.local/state/harness/requests is missing (create_host_path:false, so up -d would fail after removing the running container), and sessions may not write there." The session behaved correctly: it made `deploy.sh` refuse before any live write and recorded the blocker.
- **B2-01 to B6-05 (29 features) — depends on a failed feature.** All carry "waits on B1-05, which is waiting on Michael".

The real dependency is thinner than that. B2 builds the test rig, which runs in a throwaway container and needs no live deploy. One missing directory froze every milestone.

## Harness behaviour
- **Guards:** none fired (repairs 0, red_unpass 0, verify_failed 0, escalations 0). Parking B1-05 as "waiting on Michael" was correct.
- **Wasted money:**
  - The first start (2026-10-22) spent $10.68, of which init was $6.86 on fable. It then gave up, "blocked on B1-01", after 13 min across 2 sessions.
  - B1-01 is a plan feature that burned 3 sessions and $4.77 in total.
  - Orientation cost 487k tokens over 11 turns (121 s) in a run where each session did 2–16 min of work.
- **Dependency graph:** the driver treats "milestone blocked" as one chain. It never tried independent B2 work while B1-05 waited. That cost 5 days of wall-clock time.
- **Verify:** no verify sessions ran (`verified` 0, `verify_fail_rate` null). B1-04 was a review-kind feature, not a verify of the earlier ones, so evidence rows versus steps can't be judged.
- **Merges:** `merges` is 0, with no merge to `main` this run.
- **Preflight gap:** the first run couldn't tell that the deploy needed a host path that sessions can't create. B1-05 found it at session time, after the context bundle was built.

## Proposed harness changes
1. **Preflight blockers at plan or init time** (init/plan prompts and driver). Check that bind-mount sources, request inboxes and other host paths named in the spec exist, or are listed in the live checklist as steps for Michael. Evidence: B1-05 spent $1.02 and 3 min only to find a missing directory that the spec's own §4.3 request inbox implies. No earlier retro proposed this, as far as I checked. I read only the titles of the 10 ledger retros and no contents.
2. **Dependency granularity in the feature list** (feature-list schema and the driver's "blocked" logic). Let a feature declare `needs: live` versus build-only, so build and rig features keep running while a live step is parked. Evidence: 29 features blocked on B1-05, though B2 is rig work in a throwaway container. Not proposed before, as far as I checked.
3. **Cheaper orientation** (context.md generation). 487k orientation tokens over 11 turns, against 130k output tokens for build. Trim the bundle or reuse the cache between consecutive sessions. This is unconfirmed, and I didn't check earlier retros for it.
