# The memory curator: one writer, itemized edits, a gate that earns its switch (agent-harness)

*(Michael's study log, written during a walkthrough on 2026-11-07 of run `agent-harness-2026-11-07-2`, the run that
built it: M1 one writer (PR #125), M2 the curator (PR #126), M3 the gate and the policy (PR #127); 12/12 features,
$59.51, 4.3 h, 16 sessions, suite 1,721 → 1,791 checks. One concept per entry: the idea in plain words, where it lives
in this repo, why it is shaped that way, and the answer taken. Source material for a talk on the harness. Spec:
`docs/specs/2026-11-07-memory-curator.md`; research: `findings-and-research/Agent Memory Field Guide.md`; decisions:
`journal/decisions/2026-11-07-memory-{one-writer,tiers,policy}.md`.)*

## 0. Where this sits in the story

- **Iterations 6 → 8** made the harness safe, then fast, then self-improving: every stop visible, retros into a ledger,
  proposals back into the harness. One file stayed outside all of it: each project's `CLAUDE.md`, the instruction file
  Claude Code loads into every session's prompt. Two specs (2026-10-24 memory model, 2026-10-25 throughput-and-memory)
  put "an LLM curator" out of scope and left the file to a rule and a linter.
- **Today** reverses that, on the same research. The spec was commissioned in the morning and the run built it while
  Michael was away; this walkthrough is the first human review of the design. It is a review of running code: M1 to M3
  merged themselves (`MERGE_POLICY=auto`), and the run recorded nine questions, each with a default taken.
- **What did not happen:** the curator did not run on this run. The live checkout syncs only when no run is alive, so
  the run's `finish` ran the driver it started with at 10:01, before M2 existed (`summary.json` `memory: null`, no
  curator note, `harness memory` empty). The next run on any project is the first real curator run, under
  `MEMORY_POLICY=pr`: a PR left for Michael, nothing applied. Accidentally the cautious ordering.

## 1. The problem: the highest-leverage file had no owner, no gate, and a measured tendency to bloat

- **Concept:** `CLAUDE.md` is not documentation a session chooses to read; it is prompt. Three facts made it the
  weakest point: (1) any coding session could edit any line, unreviewed: `restrict` reverted forbidden edits for every
  role *except* coding sessions, the ones doing the work and most tempted to write a rule after an incident;
  (2) enforcement was advisory and late: `memlint` (120-line cap, 15 Gotchas) ran once per segment before the first
  session, so a breach surfaced on the next segment under another feature, as a note, never a gate: 0 findings in
  31 runs; (3) the files were drifting: hit_list 181 lines, n8n-home 134, portfolio_site 127, three of eight over the
  cap, two at exactly 15 Gotchas.
- **Underneath:** an LLM adds a rule after every incident. Instruction files grow monotonically, and longer ones work
  worse (§6).

## 2. The vocabulary: four kinds of memory, four trust levels (CoALA)

- **Concept:** working (the context window), episodic (what happened: `progress.md`, entries), semantic (facts:
  `## Gotchas`), procedural (how to act: prompts, rules, `CLAUDE.md`). Each fails differently, so each deserves its own
  trust: rules human-curated and reviewed, logs append-only, facts updated and invalidated (a fact that waits for a
  review cycle misleads sessions meanwhile).
- **The load-bearing sentence:** *mixing them in one file means one trust level for things that deserve different
  ones.* `CLAUDE.md` holds facts (Gotchas) and rules (Code rules, How to verify, Live system) in one file, so a session
  that may record a fact had the same write access as one rewriting a safety rule. A fact is cheap to be wrong about and
  expensive to leave stale; a rule is the reverse. One permission cannot honour both.

## 3. The design: split the file by trust, not by topic

- **Tier 1, facts:** `## Gotchas` and named project-fact sections. Applied automatically (bounded, capped,
  provenance-stamped). **Tier 2, conventions and workflow:** every other ordinary section; never written
  automatically, reaches Michael as a proposal with provenance. **Tier 3, protected:** `## Live system`, `## Off-limits`,
  `## On-limits`, `## Hardware facts`, `## Hardware and Mixxx rules`, this repo's `## This repo runs Michael's harness
  runs`: proposals only, ever; an op naming one is dropped, not applied.
- **In the repo:** `PROTECTED` in `lib/curator.mjs`, matched by prefix (rane's heading is `## Hardware facts (verified
  2026-10-19 …)`; equality would have missed it); the M2 review added a second guard, an op whose raw lines fall inside
  a protected section is dropped whatever heading it names.
- **The shape:** the harness can only ever write facts. Rules and safety are read-only to it, enforced by heading, not
  by asking nicely.

## 4. The mechanism, end to end

1. A coding session learns something and writes it in its entry: a durable fact as a `discoveries` row scoped
   `project`, a how-to-work-here thought as a `proposed_changes` string. The entry is the source of record.
2. An edit to `CLAUDE.md` anyway is reverted: `restrict <base> memory <who>` (`lib/record.sh`, `memory_guard`) reverts
   exactly `CLAUDE.md` and `.harness/project.md`, nothing else, one note per file.
3. At `finish`, after the retro and before the record PR, one read-only Opus session, the curator (`curator()` in
   `lib/driver.sh`; `MAX_TURNS=40`, `SESSION_BUDGET_USD=3`, like the retro; a turn is one tool round trip, not a human
   reply). Everything it changes is reverted except one file.
4. That file is `memory-ops.json`: at most 50 ops, each `add` | `replace` | `delete` with `file`, `section`, `anchor`
   (the existing line), `text` (≤160 chars), a claimed `tier`, `why`, and `from: entries.jsonl:<n>` (provenance). Never a
   rewritten file.
5. The driver validates and applies (`lib/curator.mjs`): `validate` rejects a malformed op; `apply` re-derives each
   op's tier from its heading, ignoring the claim; tier 1 is written in a detached scratch worktree and becomes one
   commit on `harness-memory/<run>`; tier 2 and 3 become text in the `memory: <run>` PR body and the record's
   `memory.md`. The result says `applied · proposed · dropped · rederived · refused`.
6. The caps are enforced at the write (`capCheck`: 120 lines, 15 Gotchas), before the commit exists.

- **The property:** the LLM only ever produces a list of small, anchored, attributed changes; a deterministic program
  decides which may exist. Trust lives in the driver, not the prompt. Every step leaves a measurable trace, which is
  what an acceptance counter needs.

## 5. Why itemized operations and not "let the model edit the file"

- **Concept:** the one place the research changed the design rather than decorated it. When an LLM maintains a memory
  file by rewriting it: **brevity bias** (it compresses away detail it does not currently find important; a gotcha
  about an untouched path is simply not re-emitted) and **context collapse** (over repeated rewrites specifics become
  generalities; each pass looks fine, the drift shows only across many). The guide: *"I'd never let an LLM rewrite a
  whole memory file repeatedly… Small anchored edits can be validated, diffed and reverted."* ACE's generator /
  reflector / curator split applies itemized deltas: here the coding sessions, the retro, the curator.
- **Consequences:** every change is a diff; every change has provenance; deletion is explicit (a `delete` with a `why`,
  the direct counter to brevity bias); tier enforcement is mechanical (a tier cannot be re-derived from a rewritten
  file, it can from an op with a `section`); a bad op is dropped, not smuggled into a rewrite. And rejections are
  per-op with a reason, so a gate that is too tight can be tuned; a rewriter gives nothing to tune.

## 6. Why the file must not grow

- **Concept:** a study of `AGENTS.md`-style files found they generally did not raise task success, added over 20 % to
  cost, helped only where a project does something non-standard, and that longer files reduce adherence while
  contradictions are resolved arbitrarily. hit_list at 181 lines is not over a cap; it is past the point where its own
  rules are followed less well *because* there are more of them.
- **The default:** net-zero-or-smaller. Past the cap an `add` is accepted only with an anchor naming the line it
  replaces; the curator evicts, it does not grow. The curator's most valuable op is `delete`; staleness churn is a
  health signal. The caps are the product, not a limit on it (whether 120 and 15 are the right numbers predates the
  research; a hard cap at the write is what the evidence supports). The "only helps where non-standard" finding is an
  argument for cross-project curation: a fact four projects carry belongs once in `~/.claude/CLAUDE.md` or the prompts.

## 7. Five engineering constraints (the answers to "why not just…")

1. **Why a separate branch:** the driver refuses a record PR whose branch holds any change outside the run's directory;
   the retro runs on that branch; a curator editing `CLAUDE.md` there would have killed the record PR on every run that
   proposed anything, with one log note to show.
2. **Why a scratch worktree:** the lane worktrees are torn down when a milestone merges; at `finish` no per-feature
   workspace exists.
3. **Why `proposed_changes`:** the field existed and nothing read it but the progress renderer; the curator is its
   first reader, and provenance is the entry line, no new schema field.
4. **Why M1 rewrote the context pack:** its clearing rule was "drop a fact once `CLAUDE.md` holds it"; with no session
   writing the file, nothing would clear. Now a fact is listed once at its first unresolved entry and the pack never
   reads `CLAUDE.md`, which also lets a memory PR sit unmerged without confusing the next run.
5. **Why not in the retro:** the retro reviews the harness (advisory); the curator reviews the project's memory (tier 1
   lands). Same enforcement, different scope, different trust; one session would wear both hats on every line.

- The separation constraint 1 forced is what makes `MEMORY_POLICY=auto` possible: the driver can merge the memory PR
  without touching the record.

## 8. What this reverses, and the one sentence it rests on

- The 10-24 and 10-25 specs read the guide as "never let an LLM maintain the file". Today's reading: *what the guide
  warns against is a rewriter, not a curator*; the guide's own recommended architecture has a curator in it, and the
  difference is entirely the unit of change. Three facts changed since: the cap was enforced by one repo's suite at
  ~2,500 s a breach; `restrict` never covered coding sessions; the linter found nothing in 31 runs while three files
  drifted past the cap. The earlier premise ("the LLM is the risk, a rule and a linter will hold") was tested for two
  weeks and did not hold, because nothing was holding.
- **Provenance:** the reversal was a judgment call by the morning's spec session, supported by the research, not
  demanded by it, and not Michael's until this walkthrough. He accepted it.

## 9. What got built, and where it diverged from the spec

- **M1:** `restrict memory` + `memory_guard`; the pack's new clearing rule, no `CLAUDE.md` read; prompts send facts to
  the entry; `gotchas()` retired. **M2:** `lib/curator.mjs` (22 unit tests with harm fixtures, fence-aware, CRLF and
  symlink handling), `prompts/curator.md`, `curator()` in `finish`, `memory_pr` (scratch worktree, one tier-1 commit,
  the PR reused on a continue), `MEMORY_POLICY`, `CURATOR_MODEL=opus`; review hardening: `memory_foreign`, raw-line
  protection, `memory.json` removed after the curator, body quieting. **M3:** `MEMORY_POLICY=pr|auto|off` (`auto` merges
  at the pushed head with `--match-head-commit`, only a new tier-1 commit); the acceptance counter (`ledger/memory.jsonl`,
  `harness memory` asking gh at listing time: `merged unchanged · edited · closed · open`); `memlint-self` retired, its
  assertion now `capCheck` plus, after the review, memlint's line lints inside `apply`. The decision file's own words:
  *M3 ships the counter, not the switch*; `auto` is earned at about five `merged unchanged`.
- **Divergences:** `auto` was thought missing at the walkthrough's start and was in fact built by M3-02. Tier 2 is
  body-only where the spec's "one commit per tier" could be read as a second commit: the main open question (§11).
- **Prediction misses:** this repo's `CLAUDE.md` is 97 lines against ≤96 (a rerouted line wrapped); the over-cap three
  are unchanged, no run wrote them.

## 10. The measurement points, and why each one

| measure | where | what it tells | why it is the right one |
|---|---|---|---|
| **merged unchanged / edited / closed / open**, per memory PR | `ledger/memory.jsonl`, `harness memory` | whether the curator's tier-1 output is what Michael would have written | it is what Michael *did*, read from GitHub: deterministic, free, and the number `auto` waits on. A judged score (a model rating the PR) was rejected as a second opinion on the thing the count measures |
| **applied · proposed · dropped · refused**, per run, with reasons | `summary.json` `memory`, the report's `Memory` row, the PR body | how much the gate rejects, and which rule does it | a high drop rate is a gate too tight; because rejection is per-op with a reason, the rule can be loosened one at a time (the all-or-nothing cap refusal is the first candidate) |
| **recurrence**: a fact that landed in Gotchas still appearing in later runs' `dead_ends` / `discoveries` | the entries (`factKey` in `lib/entries.mjs` already normalises) · *to build* | whether the memory actually prevented the incident | the only direct measure of "did the revision help"; also the evidence that would let a *rule* graduate: the incident it was written for stopped recurring |
| **acceptance rate per tier and per section** | `harness memory` once tier 2 is a PR of its own · *to build* | which kinds of change Michael accepts without edits | the graduation signal for tier 2: `## How to verify` may earn auto before `## Code rules`; impossible while tier 2 is body text (nothing to count) |
| **staleness churn**: `replace` / `delete` of facts earlier runs added | the ops, per section | which sections go stale fast (need the automatic path) versus accrete (need pruning) | the counter to brevity bias made visible: a curator that only adds is the thing the research warns against |
| the spec's **Predictions** table | `journal/decisions/2026-11-07-memory-policy.md` | whether the design did what the spec said, on the tree | predicted before, filled after, misses kept (97 vs ≤96) |

- **The habit:** a claim about memory quality without one of these numbers goes in as *(inferred)*.

## 11. The answers taken (nine questions; the run took a default for each and went on)

| # | asked by | question | answer |
|---|---|---|---|
| 1, 4 | init, M2-01 | tier 2 body-only, or a commit | **own branch and PR**, a diff Michael merges, counted separately, never reached by `auto`; tier 3 stays text; one-click approval via n8n/ntfy |
| 2 | init | M3-04's review on Sonnet (the spec) or Opus (the rule) | Fable for this run's M3 review (budget available); **Opus stays the default for reviews**; handled in another session |
| 3 | M1-03 | guard `.claude/CLAUDE.md` too | **yes**: Claude Code loads it as project memory; a guard beside an unguarded twin is no guard |
| 5 | M2-01 | the cap on an already-over-cap file | **default**: improve, not grow; todo, prune the three by hand first |
| 6 | M2-02 | may a `proposed_changes` string land in Gotchas | **default**: never; a classifier may revisit on evidence, never as the gate |
| 7 | M2-05 | a deny list on the curator session | **build it**: `Bash(git push:*)`, `Bash(gh:*)`; detect (`memory_foreign`) stays as the second layer |
| 8 | M3-02 | `auto` merges after a failed body refresh | **flipped**: skip the merge, leave the PR open; the body is the audit trail |
| 9 | M3-04 | the decisions-store lint with no suite successor | **default**: a segment-start note is proportionate |
| 10 | (raised in the walkthrough) | should tier 1 auto-apply at all | **`pr` stays the default**; `auto` per project on the count, never box-wide |

## 12. Michael's reasoning trail (what he pushed on, and where it landed)

- **"I want this as hands-off as possible; code rules, verification and where-things-go should be LLM-editable."**
  Landed as: the tiers are about who *approves*, not who *drafts* (the curator already drafts tier 2); hands-off comes
  from extending M3's acceptance counter to tier 2, per section, not from loosening the tiers. Tier 3 stays "raise it to
  me". Body text cannot graduate, so tier 2 becomes a PR (answer 1).
- **"Where in the chain, besides the runs?"** A per-run curator is the right place to *collect* (a fact surfaces inside
  a run) and the wrong place to *decide rules* (a rule is a cross-run pattern). Candidates, in order: a project-start
  review by the initializer of the pending proposals; a standing memory desk across all eight projects (de-duplicating
  a rule four projects proposed into `~/.claude/CLAUDE.md` or the prompts); outcome-validated graduation (recurrence).
- **"Can the deterministic program be too rigid?"** Yes, in one found place: `capCheck`'s refusal drops the whole
  tier-1 commit when one op breaches (`lib/curator.mjs` `apply`). Everything else demotes or records rather than loses.
  Fix: per-op.
- **"Tier 2/3 are the decisions that most need clarity, and they are the least instrumented."** The proposals are
  visible (PR body, `memory.md`); what Michael did with them is not. Two fixes: tier 2 as its own PR (merge = accepted),
  and an accept / decline verb with `--why` for what cannot be a commit (tier 3), whose `--why` the next curator reads.
- **"A decision model like jev in the orchestrator?"** Above the gate, never as it: routing a session's model (the
  biggest cost lever: `WORKER_MODEL=opus` for everything), risk-scoring an op's text as fact-or-rule beside the heading
  proxy, triaging the entry stream for the same proposal said four ways. The deterministic gate stays the readable floor.
- **"Make approval one click."** The memory PR's ntfy notification carries the tally and merge / decline actions; the
  n8n run-review flow (live, with an improvement run in the harness) shows the memory PR's ops beside the record PR.

## 13. Follow-up work (not built in this run; a spec's worth)

1. Tier 2 on its own branch and PR, counted separately; `auto` never reaches it (answer 1).
2. `.claude/CLAUDE.md` (and `.claude/rules/*.md` if it loads) in `restrict memory` and the curator's `FILES` (answer 3).
3. The curator session's deny list (answer 7).
4. `auto` skips the merge after a failed `gh pr edit` (answer 8).
5. `capCheck` per-op: apply what fits, drop the breaching ops with the reason (§12).
6. An accept / decline verb with `--why` for tier 2 and 3 proposals, read by the next curator (§12).
7. ntfy actions on the memory PR notification (tally, merge, decline) and the n8n run-review card (answers 1, 10).
8. The recurrence metric from the entries (§10); then acceptance per tier and section.
9. A project-start review of pending proposals; a cross-project memory desk (§12).
10. Prune hit_list, n8n-home and portfolio_site under the cap by hand, one session per project, before the first
    curator run (answer 5).
11. A jev-style classifier for model routing, above the gate (§12), measured against the cost rows.

## Provenance of the choices, since it matters

| choice | came from |
|---|---|
| four memory types, one trust level each; ops not rewrites; the file must not grow | the research (`Agent Memory Field Guide.md`, CoALA, ACE, the `AGENTS.md` study) |
| three tiers; the protected list; one writer; the curator at `finish`; the counter before the switch | the morning's spec session (judgment calls, research-supported) |
| reversing the 10-24 / 10-25 "no LLM curator" | the spec session; accepted by Michael today |
| body-only tier 2; `.claude/CLAUDE.md` unguarded; the cap rule; `proposed_changes` never tier 1; no deny list; merge after a failed edit; the lint left as a note | defaults taken by the build sessions, each recorded as a question |
| prefix matching; raw-line protection; `memory_foreign`; `memory.jsonl` keyed by url; memlint's line lints in `apply` | the M2 and M3 reviews |
| the answers in §11 and the follow-ups in §13 | Michael, this walkthrough |
