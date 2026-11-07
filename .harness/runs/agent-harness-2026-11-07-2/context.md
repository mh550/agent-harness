# Context pack for `M3-02`

Chosen by the harness from entries.jsonl in a fixed order; each item names its line. The full record is entries.jsonl / progress-archive.md.

## Discoveries for this feature

- Discovery (M3-01, affects M3-02, M3-03): The spec's and M3-02/M3-03's tests/checks/memory-pr.sh is tests/checks/memory-branch.sh (renamed in M2-05); the off check to replace is in curator-run.sh → entries.jsonl:12
- Discovery (M3-01, affects M3-02): curator() today notes 'curator: none (MEMORY_POLICY=<v> is neither pr nor off)' and skips; M3-02 replaces it with the treated-as-pr note. memory_open's note hardcodes MEMORY_POLICY=pr → entries.jsonl:12
- Discovery (M3-01, affects run): This session followed the branch's CLAUDE.md (facts to the entry) and wrote no ## Gotchas line, as M1-03 and M2-04/05 did; the Promote to Gotchas items stay for the curator → entries.jsonl:12
- Discovery (M2-05, affects M3): A tier-3 op counts in both dropped and proposals (ops = applied + tier 2 + dropped): M3's summary.memory must not add dropped and proposed → entries.jsonl:10
- Discovery (M2-05, affects run): This session followed the branch's CLAUDE.md (facts to the entry) and wrote no ## Gotchas line, as M1-03 and M2-04 did; the Promote to Gotchas items stay for the curator → entries.jsonl:10
- Discovery (M2-05, affects M3, run): tests/checks/memory-pr.sh is now memory-branch.sh: memory-pr was part of memory-prompts (name lint); resident-helper-run's helper-note grep now counts finish's retro/curator lines and the one (( rc )) SUM build → entries.jsonl:10
- Discovery (M2-04, affects M2-05, M3): memory_base: a tip main lacks is reused when its PR is OPEN or there is none (gh pr view's 'no pull requests found'); CLOSED or another title stops the curator with one note; a gh or origin failure is one note, no curator. A squash-merged memory PR whose branch stayed reads as not taken (documented limit) → entries.jsonl:9
- Discovery (M2-04, affects M3): $STATE/memory.json is removed at the top of curator() and written by memory_pr on every path past the rescue: {ops, applied, dropped, proposed, pr} (+ invalid); absent when the curator stopped early or wrote no file → entries.jsonl:9
- Discovery (M2-04, affects run): This session followed the branch's CLAUDE.md (facts to the entry) and wrote no ## Gotchas line, as M1-03 did; the Promote to Gotchas items stay for the curator → entries.jsonl:9
- Discovery (M2-03, affects M2-04, M3): memory_pr ends at the validate: invalid → 'curator: memory-ops.json invalid: <why>', [] → 'curator: no operations', a non-empty valid file → nothing yet. M2-04 adds steps 2–8, memory.json (step 8) included: M2-03 writes none. → entries.jsonl:8
- Discovery (M2-03, affects M2-05, M3): finish runs the curator only when MEMORY_POLICY != off and feature_list.json exists; it rebuilds summary.json once after the retro and the curator (rc flag), not after each one. → entries.jsonl:8
- Discovery (M2-01, affects M2-03, M3): tests/lib.sh base config must set MEMORY_POLICY=off (RETRO=1 is on in every stub run): a default-on curator moves counts in many check files → entries.jsonl:6
- Discovery (M1-03, affects M2, run): This session followed the branch's CLAUDE.md (facts to the entry) and wrote no ## Gotchas line; the Promote to Gotchas item about 'Where things go' bare stays for M2's curator → entries.jsonl:4
- Discovery (M1-03, affects M2, M3): memory_guard's base is the merge-base: an earlier unguarded CLAUDE.md edit on a lane (a run in flight at deploy) is reverted at the next coding session and noted against its feature → entries.jsonl:4
- Discovery (M1-01, affects run, M2, M3): This run's driver is the pre-M1 live checkout: M1's revert never runs here, and M2/M3 sessions see a Finish step asking for a Gotchas line while their branch's CLAUDE.md says the entry → entries.jsonl:2
- Discovery (M1-01, affects M1, M2, M3): checks-diff pairs a renamed check as replaced only when the new name sorts into the old one's hunk; elsewhere it counts as added + removed → entries.jsonl:2
- Discovery (init, affects M2, M3): retro() in lib/driver.sh:228 is the template for curator(): restrict … nothing with retro-proposals.json rescued to $SCRATCH (not a symlink, at most 65536 bytes, changed since the start commit) and S_NOTES noted after the restrict. finish() calls retro, then SUM build/report, then record_pr, then ledger: the curator goes between the retro and record_pr, and memory.json must exist before the final SUM build for M3's summary.memory. → entries.jsonl:1
- Discovery (init, affects run): Earlier runs' coding sessions took 12–77 min (median about 30); S4's review feature took 75 min. The full suite was 640 s at init: a full-suite step gets a 1,500,000 ms timeout. → entries.jsonl:1

## Promote to Gotchas

- restrict covers only the session's checkout: a read-only role's push or out-of-tree write is bounded only by its permission mode; memory_foreign guards the memory branch → entries.jsonl:10
- stub-gh keeps pr create's --body-file as prs/pr-N.body and has a pr edit case that rewrites it (record_pr's reuse now refreshes it too) → entries.jsonl:9
- Check files that write user-config.sh from scratch (not cp base-config.sh) must carry MEMORY_POLICY=off, or their runs get a curator: the nine that exist now do. lib/eval.sh's safety() sets it too. → entries.jsonl:8
- restrict commits the dirty tree, then reverts all since its base: a read-only role run after another in finish must rec_commit first (agent-harness-2026-11-07-2 2026-11-07) → entries.jsonl:6
- From M1 on a coding session's CLAUDE.md/.harness/project.md edit is reverted by memory_guard: a check needing a CLAUDE.md-only session tree must map another file (README.md:readme) → entries.jsonl:4

## What it builds on

- 2026-11-07 13:39 · M3-01 · passes: M3 plan written (docs/plans/2026-11-07-M3-policy.md). memlint-self retired: its grep is a unit test in memlint.test.mjs (red on a mutant, conformance red before the fixture), its self-lint the curator's capCheck at the write plus memlint-run's notes. File deleted, names swapped in both fixtures, CHECK_KEY_MAP, key-map-lint, partial-key, README follow. Decision skeleton memory-policy.; tests 962 → 962; files docs/plans/2026-11-07-M3-policy.md, journal/decisions/2026-11-07-memory-policy.md, journal/decisions/2026-11-03-suite-tiers.md, tests/unit/memlint.test.mjs, tests/checks/memlint-self.sh, … → entries.jsonl:12

## Lately in the run

- 2026-11-07 13:30 · verify M2 · passes: All five M2 features hold: full suite green (1775), unit 477/477, curator-run/memory-branch/lanes-record-pr/retro-backlog/verify-retro-read-only 51/51, syntax checks pass, docs/decision/review present, 47 names within budget 60. → entries.jsonl:11
- 2026-11-07 13:17 · M2-05 · passes: M2 review: 0 Critical, 4 Important, 6 Minor. Fixed RED→GREEN: memory_foreign refuses a foreign harness-memory tip; quiet+cap section in the body; a reused tip without PR gets one (memory_open); a write changing a protected section's raw lines is dropped. ro_rescue shared by retro/curator; decision completed; architecture/README document the curator.; tests 961 → 962; files lib/curator.mjs, lib/record.sh, lib/driver.sh, prompts/curator.md, tests/unit/curator.test.mjs, … → entries.jsonl:10

## Current rules

- The memory curator: itemized operations, a tier the driver derives, a protected list that is fixed → journal/decisions/2026-11-07-memory-tiers.md
- The gate replaces the lint: `memlint-self` retired, `MEMORY_POLICY`, and the curator's acceptance counted → journal/decisions/2026-11-07-memory-policy.md
- One writer for project memory: a coding session's `CLAUDE.md` edit is reverted, a fact goes in the entry → journal/decisions/2026-11-07-memory-one-writer.md

_97 older rules: journal/decisions._

_1 items left out at 8192 bytes: entries.jsonl has them all._
