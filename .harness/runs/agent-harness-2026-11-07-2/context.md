# Context pack for `M3`

Chosen by the harness from entries.jsonl in a fixed order; each item names its line. The full record is entries.jsonl / progress-archive.md.

## This feature's earlier attempts

- Dead end (M3-03, 11-M3-03): the [] check in curator-run expecting cu's memory PR listed open — curator-run's project CLAUDE.md has no Gotchas or Code rules: cu's three ops all drop, no PR; harness memory there prints (none) → entries.jsonl:14
- Dead end (M3-02, 10-M3-02): running the red phase while editing lib/ — tests/lib.sh's HH is the worktree itself, so a red run sees edits made mid-run; stopped it, reverted lib, reran → entries.jsonl:13
- Dead end (M3-01, 09-M3-01): counting occurrences of the literals in the unit test — lib/memlint.mjs:37 holds "docs/decisions.md" twice on one line; the old grep -c counted lines, so the test counts lines → entries.jsonl:12
- Question (M3-04): The decisions-store half of memlint-self's 'this checkout lints clean' now has no suite check (journal/ is outside the suite key), only the segment-start memlint note and harness memlint (default). Keep it that way, or add a unit test reading journal/decisions and take journal/ out of CHECK_KEY_IGNORE? Files: /home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-11-07-2/slot-0/journal/decisions/2026-11-07-memory-policy.md, /home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-11-07-2/slot-0/docs/plans/2026-11-07-M3-review.md → entries.jsonl:15
- Question (M3-02): Default taken: under MEMORY_POLICY=auto a memory PR is merged even when its body refresh (gh pr edit) failed, and a merge whose answer is lost is noted as refused (both as record_pr does; the review's two Minor findings). Keep, or skip the merge after a failed edit? Files: /home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-11-07-2/slot-0/lib/record.sh:458, /home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-11-07-2/slot-0/journal/decisions/2026-11-07-memory-policy.md → entries.jsonl:13
- 2026-11-07 14:52 · M3-04 · passes: M3 review (fable, one round): 0 Critical, 2 Important, 5 Minor. I1: memlint-self's 'lints clean' lost its derivable-count and run-scope half; apply now drops such a tier-1 op. I2: memory.jsonl is keyed by url, so a continue's new PR no longer erases a merged one. Doc drift fixed, co check anchored. Decision completed (over-cap, rejected, Predictions, budget 18+/2-). Full suite green, 1791.; tests 1790 → 1791; files lib/curator.mjs, lib/summary.mjs, tests/unit/curator.test.mjs, tests/unit/summary.test.mjs, tests/checks/curator-run.sh, … → entries.jsonl:15
- 2026-11-07 14:14 · M3-03 · passes: Counting: summary.json's memory (memory.json's five keys), the report's Memory row after Checks, the ledger row's memory, ledger/memory.jsonl (ledger(), memory-line, committed under LEDGER_COMMIT=1), and harness memory [--last n] [project] (lib/memory.sh: gh pr view <url> --json state,mergedAt,commits per row, never stored). stub-gh answers pr view by URL. Review: 9 Minor fixed.; tests 962 → 968; files lib/summary.mjs, lib/memory.sh, lib/driver.sh, bin/harness, tests/stub-gh.sh, … → entries.jsonl:14
- 2026-11-07 13:52 · M3-02 · passes: MEMORY_POLICY=pr|auto|off: auto merges the memory PR at the pushed tier-1 head (memory_merge, --match-head-commit; refused → left open, one note), an unknown value is one note and runs as pr, off writes no curator/memory note. Config, both templates, architecture §10 row, README, decision policy row. Review: under auto a PR opened with no new tier-1 commit had no note; fixed red→green.; tests 962 → 962; files lib/config.sh, lib/driver.sh, lib/record.sh, templates/project/config.sh, templates/user/config.sh, … → entries.jsonl:13
- 2026-11-07 13:39 · M3-01 · passes: M3 plan written (docs/plans/2026-11-07-M3-policy.md). memlint-self retired: its grep is a unit test in memlint.test.mjs (red on a mutant, conformance red before the fixture), its self-lint the curator's capCheck at the write plus memlint-run's notes. File deleted, names swapped in both fixtures, CHECK_KEY_MAP, key-map-lint, partial-key, README follow. Decision skeleton memory-policy.; tests 962 → 962; files docs/plans/2026-11-07-M3-policy.md, journal/decisions/2026-11-07-memory-policy.md, journal/decisions/2026-11-03-suite-tiers.md, tests/unit/memlint.test.mjs, tests/checks/memlint-self.sh, … → entries.jsonl:12

## Michael's answers

- ### 2026-11-07 14:02 (local) Question 2 (M3-04 review model): set M3-04, the M3 review, to `fable` for this run — we have the budget. In general, Opus stays the default model for reviews; the spec's "a Sonnet reader" does not override the initializer's rule. — Michael, 2026-11-07 → INBOX.md

## Discoveries for this feature

- Discovery (M3-04, affects run): curator.mjs apply drops a tier-1 op whose text lintText finds a derivable-count or run-scope in (reason '<check>: <text>'); tier 2/3 untouched → entries.jsonl:15
- Discovery (M3-04, affects run): Prediction missed: agent-harness CLAUDE.md is 97 lines (predicted 96 or fewer): M1-02's rerouted Where-things-go line wraps to two → entries.jsonl:15
- Discovery (M3-03, affects M3-04): The [] stub check went into curator-run.sh on its existing ce run (no new run), not memory-branch.sh; memory-branch.sh now sets LEDGER_COMMIT=1 with a git-init'ed $T/ledger → entries.jsonl:14
- Discovery (M3-03, affects M3-04): finish now removes $STATE/memory.json right after ended (it was the top of curator()): a continue without a curator counts none. No stub run covers that path yet → entries.jsonl:14
- Discovery (M3-03, affects M3-04): memoryState: unchanged = every headline 'memory: <run>: <n> facts' (GitHub's Update-branch merge neutral, no commits = edited); a commit of Michael's titled like the driver's reads unchanged (known limit, in the decision) → entries.jsonl:14
- Discovery (M3-03, affects M3-04, project): stub-gh answers pr view <url> --json state,mergedAt,commits: base..head in $STUB_DIR/origin.git, base kept at pr create (agent-harness-2026-11-07-2 2026-11-07) → entries.jsonl:14
- Discovery (M3-02, affects M3-03, M3-04): memory_open [merge]: under auto it notes nothing when the merge's note follows, else 'memory PR opened; left open (MEMORY_POLICY=auto: no new tier-1 commit to merge) · <url>'; pr's note unchanged → entries.jsonl:13
- Discovery (M3-02, affects M3-03, M3-04): memory-branch.sh now has 10 runs (ma auto, mr refused, mw auto without tier 1): its final worktree count is 11; mp (MERGE_POLICY=auto from base-config, MEMORY_POLICY=pr) carries the independence check → entries.jsonl:13
- Discovery (M3-02, affects M3-03, M3-04): `bash tests/run.sh memory-pr` matches memory-prompts, not memory-branch (substring of the file name): M3-02/M3-03's step commands miss the memory checks → entries.jsonl:13
- Discovery (M3-01, affects M3-02, M3-03): The spec's and M3-02/M3-03's tests/checks/memory-pr.sh is tests/checks/memory-branch.sh (renamed in M2-05); the off check to replace is in curator-run.sh → entries.jsonl:12
- Discovery (M3-01, affects M3-02): curator() today notes 'curator: none (MEMORY_POLICY=<v> is neither pr nor off)' and skips; M3-02 replaces it with the treated-as-pr note. memory_open's note hardcodes MEMORY_POLICY=pr → entries.jsonl:12
- Discovery (M3-01, affects M3-03): stub-gh pr view takes a head branch, not a URL, and answers no mergedAt/commits: M3-03 adds both (gh's documented JSON shape, a fixture naming its source) → entries.jsonl:12
- Discovery (M3-01, affects M3-03, M3-04): A continue adds a second driver commit to a reused memory PR: the plan reads 'merged unchanged' as every commit headline starting 'memory: <run>: ', not 'one commit' (default) → entries.jsonl:12
- Discovery (M3-01, affects M3-04): Fast-tier check files are 58 after the retirement (grep -l '^# tier: fast' tests/checks/*.sh), not the spec's 55: its 'now 56' was older → entries.jsonl:12
- Discovery (M3-01, affects run): This session followed the branch's CLAUDE.md (facts to the entry) and wrote no ## Gotchas line, as M1-03 and M2-04/05 did; the Promote to Gotchas items stay for the curator → entries.jsonl:12
- Discovery (M2-05, affects M3): A tier-3 op counts in both dropped and proposals (ops = applied + tier 2 + dropped): M3's summary.memory must not add dropped and proposed → entries.jsonl:10
- Discovery (M2-05, affects M3, project): restrict covers only the session's checkout: a read-only role's push or out-of-tree write is bounded only by its permission mode; memory_foreign guards the memory branch → entries.jsonl:10
- Discovery (M2-05, affects run): This session followed the branch's CLAUDE.md (facts to the entry) and wrote no ## Gotchas line, as M1-03 and M2-04 did; the Promote to Gotchas items stay for the curator → entries.jsonl:10
- Discovery (M2-05, affects M3, run): tests/checks/memory-pr.sh is now memory-branch.sh: memory-pr was part of memory-prompts (name lint); resident-helper-run's helper-note grep now counts finish's retro/curator lines and the one (( rc )) SUM build → entries.jsonl:10
- Discovery (M2-04, affects M2-05, M3): memory_base: a tip main lacks is reused when its PR is OPEN or there is none (gh pr view's 'no pull requests found'); CLOSED or another title stops the curator with one note; a gh or origin failure is one note, no curator. A squash-merged memory PR whose branch stayed reads as not taken (documented limit) → entries.jsonl:9
- Discovery (M2-04, affects M3): $STATE/memory.json is removed at the top of curator() and written by memory_pr on every path past the rescue: {ops, applied, dropped, proposed, pr} (+ invalid); absent when the curator stopped early or wrote no file → entries.jsonl:9
- Discovery (M2-04, affects run): This session followed the branch's CLAUDE.md (facts to the entry) and wrote no ## Gotchas line, as M1-03 did; the Promote to Gotchas items stay for the curator → entries.jsonl:9
- Discovery (M2-03, affects M2-04, M3): memory_pr ends at the validate: invalid → 'curator: memory-ops.json invalid: <why>', [] → 'curator: no operations', a non-empty valid file → nothing yet. M2-04 adds steps 2–8, memory.json (step 8) included: M2-03 writes none. → entries.jsonl:8
- Discovery (M2-03, affects project, M2-04, M3): Check files that write user-config.sh from scratch (not cp base-config.sh) must carry MEMORY_POLICY=off, or their runs get a curator: the nine that exist now do. lib/eval.sh's safety() sets it too. → entries.jsonl:8
- Discovery (M2-03, affects M2-05, M3): finish runs the curator only when MEMORY_POLICY != off and feature_list.json exists; it rebuilds summary.json once after the retro and the curator (rc flag), not after each one. → entries.jsonl:8
- Discovery (M2-01, affects M2-03, M3): tests/lib.sh base config must set MEMORY_POLICY=off (RETRO=1 is on in every stub run): a default-on curator moves counts in many check files → entries.jsonl:6
- Discovery (M1-03, affects M2, run): This session followed the branch's CLAUDE.md (facts to the entry) and wrote no ## Gotchas line; the Promote to Gotchas item about 'Where things go' bare stays for M2's curator → entries.jsonl:4
- Discovery (M1-03, affects M2, M3): memory_guard's base is the merge-base: an earlier unguarded CLAUDE.md edit on a lane (a run in flight at deploy) is reverted at the next coding session and noted against its feature → entries.jsonl:4
- Discovery (M1-01, affects run, M2, M3): This run's driver is the pre-M1 live checkout: M1's revert never runs here, and M2/M3 sessions see a Finish step asking for a Gotchas line while their branch's CLAUDE.md says the entry → entries.jsonl:2
- Discovery (M1-01, affects M1, M2, M3): checks-diff pairs a renamed check as replaced only when the new name sorts into the old one's hunk; elsewhere it counts as added + removed → entries.jsonl:2
- Discovery (init, affects M2, M3): retro() in lib/driver.sh:228 is the template for curator(): restrict … nothing with retro-proposals.json rescued to $SCRATCH (not a symlink, at most 65536 bytes, changed since the start commit) and S_NOTES noted after the restrict. finish() calls retro, then SUM build/report, then record_pr, then ledger: the curator goes between the retro and record_pr, and memory.json must exist before the final SUM build for M3's summary.memory. → entries.jsonl:1
- Discovery (init, affects run): Earlier runs' coding sessions took 12–77 min (median about 30); S4's review feature took 75 min. The full suite was 640 s at init: a full-suite step gets a 1,500,000 ms timeout. → entries.jsonl:1

## Current rules

- The memory curator: itemized operations, a tier the driver derives, a protected list that is fixed → journal/decisions/2026-11-07-memory-tiers.md
- The gate replaces the lint: `memlint-self` retired, `MEMORY_POLICY`, and the curator's acceptance counted → journal/decisions/2026-11-07-memory-policy.md
- One writer for project memory: a coding session's `CLAUDE.md` edit is reverted, a fact goes in the entry → journal/decisions/2026-11-07-memory-one-writer.md
- Supervised efforts for every project: one user-level skill, one dispatch list per effort, plain names throughout → journal/decisions/2026-11-05-supervised-efforts.md
- The suite's shape: check files named for what they test, no name part of another's, two cuts that need no replay, a tier on every line → journal/decisions/2026-11-05-suite-shape.md
- A merge survives an origin outage: bounded retries, a card past them, a tag that isn't claimed, gc holds verified work → journal/decisions/2026-11-04-origin-retries.md
- No run ends on a clock unless asked to: `HOURS` defaults to none, and the night leaves the docs → journal/decisions/2026-11-04-no-default-end-time.md
- A red verify opens a fix round, not a card: at most `MAX_FIX_ROUNDS` per milestone, each one counted → journal/decisions/2026-11-04-fix-rounds.md
- The unit tier: node evals become `node:test` files in one process, reported as the suite's PASS/FAIL lines → journal/decisions/2026-11-03-unit-tier.md
- The trim: 22 checks removed, each with the check that makes its assertions now; five gaps closed; no covered line lost → journal/decisions/2026-11-03-trim.md
- The suite's tiers: every check file declares `fast` or `slow` on line 2, and `tests/run.sh --tier` runs one tier → journal/decisions/2026-11-03-suite-tiers.md
- The trace switch: `HARNESS_XTRACE=<dir>` traces every harness process, off unless set → journal/decisions/2026-11-03-suite-coverage.md
- The resident helper: one warm node process per driver and lane answers the `.mjs` questions over a coproc → journal/decisions/2026-11-03-resident-helper.md
- The purity moves: the bash decision tables become pure functions with a unit test per branch; no note text changes → journal/decisions/2026-11-03-purity.md
- The fast gate: `check.sh --fast` runs the fast tier, marks `fast-<key>`, and a fast-green is never read as a green → journal/decisions/2026-11-03-fast-gate.md
- The check count and the check budget: every verified milestone says what it added to the suite, against a budget when the spec set one; a note, never a gate → journal/decisions/2026-11-03-check-budget.md
- A run never starts on a spec that isn't there: `harness start` and `queue add` refuse a spec absent from the run's base ref → journal/decisions/2026-10-31-spec-must-exist.md
- One full run per coding session, last: the prompt's rule and §3 order, and `Suite runs` in the report → journal/decisions/2026-10-31-one-full-run.md
- Fewer node starts: where a stub run's process starts come from, and the cuts C1 makes → journal/decisions/2026-10-31-fewer-node-starts.md
- The suite's length in every prompt: a green marker's `wall` line, and a timeout rule → journal/decisions/2026-10-30-suite-length-in-prompt.md
- A red tree is cached: `red-<key>`, so the next full call on the tree just found red runs nothing → journal/decisions/2026-10-30-red-marker.md
- A mapped path's change runs only its readers: `CHECK_KEY_MAP`, the `part-<key>` sidecar, the partial run, the lint → journal/decisions/2026-10-30-partial-key.md

_78 older rules: journal/decisions._
