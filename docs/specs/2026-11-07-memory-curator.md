# The memory curator: one writer for project memory, itemized edits, a tier that gates them (2026-11-07)

**Goal.** `CLAUDE.md` is the highest-leverage and least-tested file in the system: every session reads it as
instruction context, and today **any coding session may edit any line of it**, unreviewed, with only an advisory lint
after the fact. This run gives project memory one writer and a gate. **M1:** coding sessions stop editing `CLAUDE.md`
and write what they learned in their entry (`discoveries` with `affects: ["project"]`, `proposed_changes`); the rule is
mechanical, not advisory, because `restrict` starts covering a coding session's `CLAUDE.md`. **M2:** one Opus
**curator** session at the run's end reads the run's entries and emits **itemized operations** — never a rewritten
file — which the driver validates and applies on its own branch. **M3:** the driver's tier check becomes the
enforcement, the suite's `memlint-self` self-lint retires, and the auto-merge the curator may one day earn is a
measured number in the ledger rather than a judgement. Three milestones in series: M1, then M2, then M3.

**Source.** Row `F3` and **Decision 4** (closed 2026-11-07: (a), Michael — build it on the CoALA deliverables already
in `findings-and-research/`, not researched again) of `docs/plans/2026-11-03-test-suite-redesign-dispatch.md`;
`journal/sessions/2026-11-04-loop-engineering-design.md` §4; `findings-and-research/Agent Memory Field Guide.md`
(lines 77–107 the four CoALA types and their per-type writers, **99–101** the rule this spec is built on, 138–165
background writes, **707–736** ACE's itemized delta updates and context collapse, 820–844 provenance, 867–891 the
one-small-file prescription, 943–967 evaluating for harm, 1031–1055 the ETH `AGENTS.md` study, 1081–1121 memory
poisoning and its five controls) and `findings-and-research/Agent Memory, Mapped.md` (FIG 04, FIG 14);
`docs/specs/2026-10-24-memory-model.md` (its "Out of scope" line) and `docs/specs/2026-10-25-throughput-and-memory-design.md`
(§6's store registry and its rule 2, "one writer kind per store"; line 43's non-goal); `lib/entries.mjs`
(`validate` 48–80, `normalize` 110, `render` 185–188, the pack's `Promote to Gotchas` 289–292 and
`Discoveries for this feature` 308); `lib/memlint.mjs` (the four lints, `gotchasEntries`, `gotchasDiff`,
`currentRules`, `readRules`); `lib/driver.sh` (`retro` 228–254, `record_pr` 280–298 and its `":!$RUN_DIR"` guard 288–289,
`memlint_check` 483–497, the initializer's `restrict` 512, `finish` 313–380); `lib/lane.sh` (`restrict` at verify 155);
`lib/record.sh` (`restrict` 361, `gotchas` 687–691, `pr_open_` 916–920, `merge_one` 927–1000, entry-resume 609, the
comment at 686); `prompts/coding.md` (Finish step 2, 86–97; the entry example 111–120), `prompts/retro.md`,
`prompts/initializer.md:94`, `prompts/parts/where-things-go*.md`; `tests/checks/memlint-self.sh`,
`tests/checks/memlint-run.sh`, `tests/checks/verify-retro-read-only.sh`, `tests/unit/memlint.test.mjs`;
`decisions/2026-10-26-memlint`, `decisions/2026-10-26-resolved-and-project-facts`,
`decisions/2026-10-21-one-file-per-decision`, `decisions/2026-11-05-suite-shape`.

**Rules.** `CLAUDE.md` binds: worktree only; never touch real runs or real state; never a real notification (the stub
curl, as every check); fakes mirror the live API; every behaviour visible in `harness-log.md`, `run.log` or a
command's output and checked test-first in `tests/checks/` (tier by `decisions/2026-11-03-suite-tiers`'s 30 s rule,
its names in `tests/fixtures/check-names.txt` and, fast, `check-names-fast.txt`), a pure function's in `tests/unit/`;
`bash -n`, `node --check`; one decision file per milestone; `docs/architecture.md` and `README.md` in the same
milestone. **Proceed on the defaults written here; record them marked *default*; never park.**
**Two invariants no feature may break.** (1) **The curator never writes a project file.** It emits one JSON file of
operations; the driver is the only writer. A session that edits anything else has it reverted, as the retro does.
(2) **No operation may touch a protected section**, and the protected list is a fixed set of headings, never inferred.

## Depends on

- `main` at or after `f498c10` (the six check rules in `CLAUDE.md`; the dispatch list with Decision 4 closed).
- F1 merged (PRs #97–#99) and phase 4 merged (PR #120): both are in.
- M2 after M1 (M2's curator consumes the entry fields M1 makes the only route); M3 after M2 (M3 retires the self-lint
  and can only do so once M2's tier check exists). M1's first feature `after: []`, M2's `["M1"]`, M3's `["M2"]`.
- **This spec reverses a recorded non-goal.** `docs/specs/2026-10-24-memory-model.md` ("Out of scope: an LLM curator…")
  and `docs/specs/2026-10-25-throughput-and-memory-design.md:43` both ruled an LLM curator out, citing the same field
  guide. M1 adds the `Updated in place <date>: …` line to the decision file that holds that choice and says why it
  turned: the cap was enforced only by one repo's suite check, at about 2,500 s a breach and red outside the feature
  that caused it; `restrict` never covered coding sessions, so the "Michael's" rule in `## Where things go` was
  advisory; and `memlint` found 0 findings in 31 runs, which makes it inventory, not safety. What the guide forbids is
  not a curator but a *rewriter* — hence invariant (1) and M2's operations.

---

## M1 · The project's memory has one writer, and the rule is mechanical

**Finding.** Three things are true together today. `prompts/coding.md`'s Finish step 2 (86–97) tells a coding session
to promote a durable fact into `## Gotchas` in place. `restrict` is called at exactly four places — verify
(`lib/lane.sh:155`), the retro (`lib/driver.sh:245`), the initializer (`lib/driver.sh:512`) and entry-resume
(`lib/record.sh:609`) — so a **coding session is the one role that is never restricted**, and `## Where things go`'s
rule that workflow lines are "Michael's" is a sentence in a prompt, not a gate. And `lib/memlint.mjs` runs once per
segment *before* the first session (`lib/driver.sh:497`), so a breach a session causes is reported on the next
segment, under a different feature. The field guide's rule for this (99–101): "Procedural memory (rules) should be
human-curated and reviewed. Episodic memory (logs) should be append-only. Semantic memory (facts) needs updates and
invalidation. Mixing them in one file means one trust level for things that deserve different ones."

**Choice.**

1. **A coding session's `CLAUDE.md` is reverted** (`lib/lane.sh`, beside the slot's commit path): a new `restrict`
   spec `memory` reverts changes to the project's `CLAUDE.md` and `.harness/project.md` and nothing else, so code,
   tests, docs and decision files are untouched. One note per occurrence, `"<feature>: reverted its CLAUDE.md edit
   (project memory is the curator's; say it in the entry)"`. *Default*: the spec is `memory`, not `nothing` — a
   coding session must stay free to write everything else.
2. **The prompt stops asking for the edit** (`prompts/coding.md` Finish step 2): a durable fact becomes a
   `discoveries` row with `affects: ["project"]`; a convention or workflow line becomes a `proposed_changes` string.
   The ≤160-character shape and the `(<run> <date>)` suffix stay, because the curator re-uses them verbatim.
   `prompts/initializer.md:94` is rerouted the same way — today it asks for a `## Gotchas` write that
   `lib/driver.sh:512`'s `restrict` already reverts, which is a standing contradiction.
3. **The pack stops waiting on a write that will not come** (`lib/entries.mjs` 289–292). The `Promote to Gotchas`
   part filters a fact out once a `## Gotchas` line holds its first 40 characters; with no session writing the file,
   nothing ever clears, so every later coding session of the run is shown the same facts. The clearing rule becomes:
   a fact leaves the part when a later entry lists it in `resolved`, **or** when any entry of this run already
   carries an identical-by-`key` fact (the existing `loose`/`key` normalizer, reused). *Default*: the part keeps its
   `Math.floor(cap/8)` bound.
4. **`## Where things go` says the new route** (`prompts/parts/where-things-go.md` and its `-readonly`/`-override`
   variants, and this repo's own `CLAUDE.md` line): a fact → the entry's `discoveries`, scope `project`; how to work
   here → the entry's `proposed_changes`; neither → `CLAUDE.md`, ever, by a session.

**Checks (written first).** A stub run whose coding session edits `CLAUDE.md` ends with that file unchanged on the
branch, one `reverted its CLAUDE.md edit` note naming the feature, and the run still `done`; the same session's
change to a test file and a decision file survives; a stub run whose coding session writes a `project` discovery and
a `proposed_changes` string has both in `progress.md` and in `entries.jsonl` and no `CLAUDE.md` diff; a second coding
session of the same run is not shown a fact an earlier entry `resolved`, and is not shown a fact a sibling entry
already carries; the initializer's `## Gotchas` write is reverted and its note says so.

### M1-review
Folded into M1's last feature: the diff is prompts, one `restrict` spec and one pack filter, and the risk is a
`restrict` spec too wide. The reviewer's one job is to prove `memory` reverts nothing but the two files, on a run
whose session also touched `lib/`, `tests/` and `journal/decisions/`.

---

## M2 · The curator: itemized operations, applied by the driver, never by the session

**Finding.** The guide measured what happens when an LLM maintains a memory file by rewriting it (707–736): brevity
bias and context collapse, and ACE's answer is a **curator role that emits itemized delta updates** to a playbook,
with grow-and-refine and de-duplication — "I'd never let an LLM rewrite a whole memory file repeatedly… Small
anchored edits can be validated, diffed and reverted." Two mechanical facts fix where the session can run.
`record_pr` (`lib/driver.sh:288–289`) refuses to open the run's record PR when the record branch holds any change
outside `$RUN_DIR/`: `more=$(git diff --name-only "$mb" HEAD -- . ":!$RUN_DIR")`, non-empty → one note and return. By
the time the retro runs, `slot_close` has removed every lane slot and the coordinator sits in `$RWT` on
`harness/<run>`. **So a curator that edited `CLAUDE.md` where the retro runs would silently kill the record PR.**

**Choice.**

1. **A new session role, `curator`** (`prompts/curator.md`, `lib/driver.sh` beside `retro`): Opus, after the retro and
   before `record_pr`, `MAX_TURNS=40`, `SESSION_BUDGET_USD=3` (*default*, the retro's), transcript
   `$LOGS/zz-curator-<HHMMSS>.jsonl`, one `log "curator · <model>"` line. It is **not** the retro: the retro reviews
   the harness and proposes harness changes to the backlog; the curator reviews nothing and proposes only project
   memory. Both are read-only in the same way — `restrict "$cstart" nothing curator`, with its one output file
   rescued to `$SCRATCH` first and back after, exactly as `retro-proposals.json` is.
2. **Its only output is `$RUN_DIR/memory-ops.json`**: an array of operations, each
   `{op, file, section, anchor, text, tier, why, from}`. `op` is one of `add`, `replace`, `delete`; `anchor` is the
   existing line a `replace`/`delete` names, matched by the `key` normalizer so whitespace and emphasis do not
   defeat it; `from` is provenance — `entries.jsonl:<line>`, derived, which is the convention the pack already
   prints. No schema change to `proposed_changes`: a plain string keeps its provenance through its entry's line
   (field guide 820–844: "Every memory should carry its provenance… Without that you can't audit, correct or safely
   delete").
3. **The tier decides what happens to an operation, and the driver decides the tier** — never the session, whose
   `tier` field is a claim the driver re-derives and logs when it disagrees:
   - **tier 1, facts** — `## Gotchas` and a project's named fact sections: **applied**, on the curator's branch.
   - **tier 2, conventions and workflow** — every other section: carried to the **PR** for Michael.
   - **tier 3, protected** — **proposals only, in the PR body, never an operation.** The protected set is this fixed
     list of headings, by `decisions/…-memory-tiers`: `## Live system`, `## Off-limits`, `## On-limits`,
     `## Hardware facts`, `## Hardware and Mixxx rules`, and agent-harness's `## This repo runs Michael's harness
     runs`. **Matched by prefix, not equality**: rane-one-mixxx's real headings are
     `## Hardware facts (verified 2026-10-19 on Michael's desktop)` and
     `## Hardware and Mixxx rules (binding on every session)`, and a dated or parenthesised suffix must not defeat the
     guard. An operation naming a protected section is dropped with a note, not applied.
4. **Its own branch and its own PR** (`lib/record.sh`, a `memory_pr` beside `record_pr`): the driver applies the
   accepted operations on `harness-memory/<run>` cut from `origin/<main>`, commits them one commit per tier, and opens
   a PR titled `memory: <run>` with a body that lists every operation with its `from`, every tier-3 proposal, and
   every dropped operation with its reason. `pr_open_` hard-codes `"$RUN_ID: … (verified)"` and `record_pr` matches
   its PR by title, so this needs its own opener; it reuses an open PR on the same head the way `pr_open_` does.
5. **The result is bounded, and smaller by default.** Before the commit the driver re-runs `lib/memlint.mjs` on the
   result: over 120 lines or over 15 `## Gotchas` entries and the **tier-1 commit is refused whole**, with one note
   naming the first breach. Past the cap an `add` is only accepted when it carries a `replace`'s anchor — so the
   curator evicts rather than grows. The ETH study (1031–1055) is why: context files "generally didn't raise success"
   and added more than 20 % cost, and longer files reduce adherence. `gotchasDiff`'s existing multiset rule already
   reads one line out plus one in as a single **edit**, which is the shape this wants.
6. **A run with nothing to say writes nothing**: an empty `memory-ops.json`, one `note "curator: no operations"`, no
   branch and no PR. *Default*: the curator still runs, so the no-op case is measured.

**Checks (written first).** A stub run whose entries carry two project facts and one workflow proposal ends with a
`harness-memory/<run>` branch, a tier-1 commit holding both facts in `## Gotchas` with their `(<run> <date>)` suffix,
the workflow line **not** applied but present in the PR body with its `entries.jsonl:<n>`, and a `memory: <run>` PR;
the run's own record PR still opens (the guard is not tripped); an operation naming `## Live system` is dropped with
a note and appears in the body as a proposal; an operation whose `anchor` matches no line is dropped with a note; a
curator session that edits `CLAUDE.md` itself has the edit reverted and `memory-ops.json` kept; a 16th Gotchas line
with no anchor refuses the tier-1 commit with one note and leaves the file unchanged; an empty operations file writes
`curator: no operations`, no branch, no PR; `MEMORY_POLICY=off` runs no curator at all. Pure cases in
`tests/unit/curator.test.mjs`: the tier of every section of all eight projects' real headings, anchor matching under
the `key` normalizer, the cap arithmetic including the anchor exemption, and the body's rendering.

**Harm cases, written as checks** (field guide 943–967 — "A memory feature that raises recall but also raises
wrong-memory rate can be a net loss"): a fact stated in one entry and **corrected** in a later entry of the same run
yields one operation carrying the correction, not two contradictory lines; a fact no entry states yields no
operation; and **a line that arrived inside a tool result or a file the session read, rather than as its own
finding, is not written** — the guide's write-gate control (1081–1121), and the reason tier 1 is the only ungated
write and is bounded to one section plus a cap.

### M2-review
Sized to the milestone: an Opus reader of the diff. Hardest: that the driver re-derives the tier rather than trusting
the session's field, that no path lets the curator's own process write a project file, and that the record PR's guard
stays untripped on a run where the curator did work.

---

## M3 · The gate replaces the lint, and auto-merge is earned by a number

**Finding.** `tests/checks/memlint-self.sh` is the one check that lints the checkout it runs from, "so the one a
`CLAUDE.md` edit can turn red (a sixteenth Gotchas line did, twice, outside the feature that added it)". It is a fast
file, it is in `CHECK_KEY_MAP` (`key-map-lint`), and the dispatch row's plan was always that the curator's tier check
is its successor. Three of the eight projects are already over the 120-line cap today — hit_list 181, n8n-home 134,
portfolio_site 127 — and three sit exactly at 15 Gotchas (agent-harness, hit_list, portfolio_site), so the next fact
in any of them forces an eviction. The F3 row's "`restrict` covers verify and retro only" was wrong in two ways and
M1 fixes both.

**Choice.**

1. **`memlint-self` retires** and its assertion moves to the write: the driver's check in M2 §5 is what keeps the cap
   now, and it runs where the edit happens, for every project, at no suite cost. The file goes, its names leave both
   fixtures in the same commit, `CHECK_KEY_MAP` in `.harness/config.sh` loses its entry, and `key-map-lint` follows.
   `memlint-run` and the four lints **stay**: they are the deterministic reader for a file Michael or an older run
   wrote, and `harness memlint <project>` stays the way to ask.
2. **`MEMORY_POLICY=pr|auto|off`**, beside `RECORD_PR` in `lib/config.sh`, *default* **`pr`**: tier 1 is applied and
   the PR is opened and left for Michael. `auto` merges the tier-1 commit's PR itself; `off` runs no curator. It is
   deliberately separate from `MERGE_POLICY` — a project may merge verified code automatically and still want its
   instruction file reviewed by hand.
3. **Acceptance is counted, so `auto` is a reading rather than a feeling** (`lib/summary.mjs`, `ledger/`): each run
   records `memory: {ops, applied, dropped, proposed, pr}` in `summary.json`, a `Memory` row in `harness report`, and
   the ledger gains one row per memory PR with its state. `harness backlog`-style, a `harness memory` subcommand
   lists the last n runs' memory PRs and what became of them. The row Michael reads before turning `auto` on: how
   many memory PRs merged unchanged, how many he edited first, how many he closed.
4. **The three over-cap projects are not this run's job**: the curator refuses to grow them and will evict on its
   first operation, which is the intended behaviour. `## After the run` names the one command to see where they stand.

**Checks (written first).** The fast fixture loses `memlint-self`'s name and `key-map-lint` passes without it; a stub
run with `MEMORY_POLICY=pr` opens the PR and notes it left for Michael, with `auto` merges it, with `off` writes no
curator note at all; `summary.json` carries the `memory` object and `harness report` prints the `Memory` row with
zeros for a run whose curator wrote nothing; a summary built before this run has no `memory` field and the report
omits the row; `harness memory` lists a run's PR and its state. Pure cases in `tests/unit/summary.test.mjs`.

### M3-review
Sized to the milestone: a Sonnet reader. Hardest: that removing a check file loses no assertion (every one of
`memlint-self`'s is made by the driver's check or a unit test, named in the decision file, by the trim's rule).

---

## Milestones

| M | Contents | After | `check_budget` |
|---|---|---|---|
| M1 | the `memory` `restrict` spec and its note; `prompts/coding.md` Finish step 2 and `prompts/initializer.md:94` rerouted; the pack's clearing rule (`resolved`, or a sibling entry's identical `key`); `prompts/parts/where-things-go*.md` and this repo's line; the `Updated in place` line on the reversed non-goal; `journal/decisions/2026-11-07-memory-one-writer.md`; architecture and README; M1-review folded in | `[]` | 30 |
| M2 | `prompts/curator.md`; the `curator` role in `lib/driver.sh` with its `restrict` and its rescued output; `memory-ops.json`'s shape and validator; the driver's tier derivation and the fixed protected list; `lib/record.sh`'s `memory_pr` and the `harness-memory/<run>` branch; the cap refusal and the anchor exemption; the harm cases; `tests/unit/curator.test.mjs`; `journal/decisions/2026-11-07-memory-tiers.md`; architecture and README; M2-review | `["M1"]` | 60 |
| M3 | `memlint-self` retired with `CHECK_KEY_MAP` and `key-map-lint`; `MEMORY_POLICY` in `lib/config.sh` and the template; `summary.json`'s `memory` object, the `Memory` report row and the ledger row; `harness memory`; `journal/decisions/2026-11-07-memory-policy.md`; architecture and README; M3-review | `["M2"]` | 35 |

Plan each as three or four features, the last the review feature (M1's folded into its last build). The suite ends
green at every milestone, and the full suite runs at each verify.

## Predictions (for the retro and the supervisor; against the runs after this one)

| Measure | now | after M1 + M2 + M3 |
|---|---|---|
| roles that may write a project's `CLAUDE.md` | 4 (coding, and by hand the initializer, verify, entry-resume — the last three reverted) | **1 (the driver, from the curator's operations)** |
| `CLAUDE.md` lines, agent-harness | 96 | **96 or fewer** |
| projects over the 120-line cap | 3 of 8 | **3 or fewer, and none grown by a run** |
| a `## Gotchas` breach found | by the suite, next segment, ~2,500 s | **at the write, by the driver, 0 suite cost** |
| fast-tier check files | 56 | **55** (`memlint-self` retired) |
| memory PRs merged unchanged, of those opened | – | **measured, not predicted: the number `auto` waits on** |
| a whole-file rewrite of `CLAUDE.md` by a session | possible | **0: no path exists** |

Falsifiers: the curator's operations are mostly `add` and `CLAUDE.md` grows run on run (brevity bias is not the
failure here, bloat is); a tier-2 PR is opened on more than one run in three with nothing in it Michael keeps; the
driver's tier derivation disagrees with the session's claimed `tier` on more than a tenth of operations (the prompt is
unclear, not the code); a fact reaches `## Gotchas` that came from a tool result rather than the session's own work;
the record PR fails to open on a run where the curator worked; `memlint`'s four lints start finding breaches the
driver's check let through.

## Not in this run

Embeddings, a facts collection with reconciliation, or any store beyond the one small file — the guide's chapter 5
prescription (867–891) is "start with one small file", and this run is that file's writer and gate, nothing more. A
replay set that judges whether a curated `CLAUDE.md` actually changes a session's behaviour (the guide's second Arize
lesson, "a fact being in memory doesn't mean the agent applies it", and gap 6 of its harness read): that needs the
eval track, and `evals/results/` is still empty. Auto-merge turned on: M3 ships the counter, not the switch.
Curating `journal/decisions/` or `docs/`: out of scope, the decisions store has its own rules. Any change to the user
file `~/.claude/CLAUDE.md` or to a `.claude/settings.json`: never, by this or any run.

## After the run (Michael)

- **Nothing to configure**: `MEMORY_POLICY` defaults to `pr`, so the first runs after this one apply facts and leave
  you a `memory: <run>` PR per run. `MEMORY_POLICY=off` in a project's `.harness/config.sh` opts it out entirely.
- After about five runs, read `harness memory` and decide whether `auto` is earned: the row to look at is memory PRs
  merged unchanged against those you edited or closed.
- Where the over-cap projects stand, any time: `for p in ~/projects/*/; do harness memlint "$p"; done`
  (hit_list 181, n8n-home 134 and portfolio_site 127 lines today; the curator will evict rather than grow them, but it
  will not shrink them on its own).
