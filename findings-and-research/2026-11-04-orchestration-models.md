# Orchestration models for loop engineering (2026-11-04)

Written by the research session `docs/plans/2026-11-04-orchestration-models-explore.md` asked for, on 2026-11-04, from a
worktree, read-only on every input. The question (`journal/sessions/2026-11-04-loop-engineering-design.md` §4b): keep
the **deterministic bash driver around stateless headless sessions**, or move to **multi-turn agents that spawn
subagents**, with a long-lived supervisor that hears each coding instance resolve. This repo's numbers are the ten
committed run records `.harness/runs/agent-harness-2026-10-21-measure` … `-2026-11-04` (`summary.json`, 312
`metrics.jsonl` rows, 241 of them coding sessions, 195 with token fields; dates 2026-10-21 → 11-04), the suite-time
findings (`2026-10-29-run-time-budget.md`, `2026-10-30-run-time-budget-dj-hitlist.md`, `2026-11-03-redesign-baseline.md`,
`2026-11-03-suite-tiers.md`) and the journal (iterations 02–04, 08). Web sources were fetched on 2026-11-04 by three
research subagents (Anthropic posts and Claude Code docs; other labs; papers); every one is listed under *Sources*
with its URL and date, and cited here as `[name]`. It builds on `Coding agent supervision layers.md` (verification
layers; not repeated) and `Agent Memory Field Guide.md` (context budgets and caching; not repeated). *(inferred)* marks
what this session concluded rather than read or measured.

## TL;DR

- **Wall time goes to the suite, not to the shape of the sessions.** Over four runs the sessions' own suite runs were
  58 % of lane time and the suite 67 % counting every caller; the model was busy 20 % (`2026-10-29-run-time-budget.md`).
  The driver's gap between two sessions is 5–9 s when the tree is cached and 800–955 s when it runs a full suite (the
  verify's fresh run, a retry's pre-session run). No orchestration model changes those numbers; the fast tier
  (152 s against 805 s) and phase 2's CPU work do. The one wall-time cost an orchestration change removes is the
  **dispatch gap**: the minutes to hours between a milestone event and Michael pasting the next block.
- **Accuracy is already at the ceiling the sources describe.** First-attempt pass rate 1.00 in the last five runs
  (one lane and two), verify-fail rate 0.00; the two runs under 0.70 (0.63 on 10-26, 0.65 on 10-29-2) were the first
  lanes run and the two-lane contention run with 9 flake rows and six re-check failures in one milestone. Every
  measured source puts multi-agent *below* a single agent on sequential coding: −2.1 % to −14.9 % on SWE-bench
  Verified with 4.4–17.2× error amplification [Kim 2025]; −59 % to −70 % at the third bug of a chain when work is
  carried or offloaded to sub-agents [ChainSWE 2026]. The component every source keeps is an **independent, clean-
  context verifier**: it beat the builder's own tests (Holm p = 0.006) and a different *model* added nothing beyond a
  fresh *context* [Sion & April 2026]; self-grading "reliably skew[s] positive" [Anthropic harness 2026].
- **Re-orientation is 40 % of a coding session's tokens and 35 % of its wall, but it is cheap in money.** 97 % of a
  coding session's input is cache reads at 0.05× (Opus 5.5) [Anthropic caching]; the whole coding spend of 195
  sessions was $666, $3.50 per Opus session, and orientation is about a third of that *(inferred)*. A long-lived agent
  saves part of it and pays for the rest with history: in long coding runs cache reads are 78 % of the bill
  [CliffCompaction 2026]; carrying context across tasks gained 0.4 points for more tokens [ChainSWE 2026]. Subagent
  fan-out costs 15× chat [Anthropic multi-agent 2025], +58 % to +515 % coordination tokens [Kim 2025], ~7× for agent
  teams [Claude Code teams].
- **Reliability is where the two designs differ most.** This driver has been killed, limited and resumed from disk
  (`harness continue`; 1 usage-limit wait and 1 environmental session in 312 rows); iteration 2's orchestrator was
  the single point of failure ("a crash, limit or compaction of the orchestrator still stops everything"), and the
  people who ran large multi-agent fleets in 2026 report the same wall (Cursor's flat peers at "the effective
  throughput of two or three"; Gas Town "fell apart at the seams") [Cursor 2026; Yegge 2026].
- **Recommendation:** keep the stateful single-turn skeleton; make the supervisor **event-driven and stateless** (the
  driver invokes a short read-only *steward* session on each milestone event; it proposes, bash checks, Michael's
  one-word yes dispatches; auto-dispatch is earned by measured acceptance); keep F1 as it is; build F2's triage and
  F3's curator as **driver-spawned single-turn sessions**; use Claude Code's **built-in subagents inside** sessions
  and **ban bash-spawned `claude -p`**, which escapes every guard; hold `MAX_LANES=1` on this box until the suite's
  CPU falls. §6 orders the steps; §7 is the experiment.

## 1. This harness, measured

| Measure | Value | Source |
|---|---|---|
| Coding session wall (n = 241) | median 1,603 s · p25 1,017 · p75 2,338 · max 4,732 | `metrics.jsonl` `wall_s` |
| Model-active share of a coding session | 68 % of wall (`api_s` 1,211 of 1,769 s mean) | `metrics.jsonl` |
| Orientation (requests up to the first edit), Opus (n = 190) | 40.1 % of token traffic · 34.9 % of wall · 30 of 51 turns · 2.0 M tokens mean | `metrics.jsonl` `orient_*` |
| Lane time, four runs 10-28 → 10-29-3 | model 20 % · sessions' suite 58 % · suite all callers 67 % · harness before 2 %, after 6 % · verify 3 % · waiting 4 % | `2026-10-29-run-time-budget.md` TL;DR |
| The same on dj and hit_list | suite 62 % of lane time (dj) · 17 % (hit_list, whose suite is 8–30 s) | `2026-10-30-run-time-budget-dj-hitlist.md` |
| Driver gap between two sessions in a lane | 5–9 s (cached tree) · 802–955 s (a full suite ran) · 6,211–8,165 s (a pause) | `metrics.jsonl` `at` − `wall_s`, runs 11-03, 11-03-2, 11-04, 10-29-2 |
| Suite, solo, `TEST_JOBS=4` | full 794–810 s (1,181 checks) · fast tier 152 s (537) · two at once 857 s each | `2026-11-03-suite-tiers.md`; iteration 08 |
| Last feature passes → milestone merged | 17 min (T1 of 11-04: 03:52 → 04:09, the full suite most of it) | `.harness/runs/agent-harness-2026-11-04/harness-log.md` |
| Verify session (n = 39) | median 145 s · mean $0.27 · Sonnet | `metrics.jsonl` |
| Initializer (n = 14) | 594 s · $5.45 · Fable · 13–18 % of a run's cost | `metrics.jsonl`; `summary.json` `cost.by_role` |
| First-attempt pass rate, by run | 0.63 (10-26) · 0.96 · 0.65 (10-29-2, two lanes) · 0.82 · 1.00 × 5 (10-29-3 → 11-04) | `summary.json` `first_attempt_pass_rate` |
| Verify-fail rate | 0.00 in eight runs · 0.08 (10-29) · 0.21 (10-29-2: R3's six features failed the re-check) | `summary.json` `verify_fail_rate` |
| Features needing more than one session | 16 of 143 (two or more runs' rework lists; 8 of them in 10-29-2) | `summary.json` `features_detail`, `rework` |
| Flake rows | 9 in the two-lane run 10-29-2 · 0 in the one-lane runs beside it · 1 in 10-30 | `harness-log.md` `flaky:`; budget §11 |
| Review | 11.8–29.2 % of a run's cost · 1 of 17 reviews found nothing | `summary.json` `review` |
| Cost | $3.57–4.71 per passing feature in the last five runs ($8.76 on 10-26) · $3.50 per Opus coding session | `summary.json`; `metrics.jsonl` |
| Cache | run cache-hit rate 0.963–0.976 · coding cache writes 2.8 % of cached tokens · context peak mean 135 k (Opus), max 314 k | `summary.json` `tokens`; `metrics.jsonl` |
| Limits and crashes | `limit_waits` 1 in ten runs · 1 environmental session of 312 · every driver death resumed with `harness continue` | `summary.json` `guards`; `docs/architecture.md` §14 |
| Iteration 2's orchestrator (10-15/16) | hit_list +154 tests in ~2.5 h; dj 108 commits in a day; broke on: one session holds the loop, permission walls, design churn | `journal/iterations/02-orchestrator-and-subagents.md` |

## 2. The five designs compared

- **A · this harness today.** Stateful single-turn: a bash driver, one fresh `claude -p` per feature with its state in
  files (`feature_list.json`, `entries.jsonl`, `context.md`, git), an independent verify per milestone, PR merges,
  lanes per milestone, a human-started supervisor session that keeps a Status table and hands Michael blocks to paste.
- **B · a long-lived multi-turn supervisor.** One agent session alive for the run (or the plan), woken with an update
  as each coding instance resolves, deciding and dispatching the next piece itself.
- **C · coding sessions that spawn `claude -p` through bash** for triage, implementation and verification.
- **D · coding sessions that use Claude Code's built-in subagents** (the Agent tool; what `prompts/coding.md:76-79`
  already asks for reviews and browser checks).
- **E · the hybrid this file recommends.** A's driver and sessions; the supervisor as a short stateless session the
  driver invokes on milestone events; D inside sessions; F2's triage and F3's curator as driver-spawned sessions.

## 3. Comparison on questions 1–4 and 6

| | A · today | B · long-lived supervisor | C · bash-spawned `claude -p` | D · built-in subagents | E · hybrid |
|---|---|---|---|---|---|
| **Speed: where wall goes** | suite 67 % of lane time, model 20 %; driver gap 5–9 s cached / 800–955 s on a full suite; verify → merge 17 min; the dispatch gap is Michael's (minutes to hours) | changes no session's wall; removes the dispatch gap; its own turn per event is a verify's size (145 s median) *(inferred)*; synchronous waits were Anthropic's own bottleneck [Anthropic multi-agent 2025] | each spawn is a cold session: ~554 s of orientation here before its first edit; serial inside the parent's wall unless backgrounded; fan-out cut wall "up to 90 %" only on parallel research [Anthropic multi-agent 2025] | non-fork subagents start cold too ("may need time to gather context"); `-p` waits up to 10 min for background ones [Claude Code subagents; headless] | A's walls; the dispatch gap closed by an event-driven steward |
| **Accuracy: pass, verify, rework** | first-attempt 1.00 in the last five runs; verify-fail 0.00; 16 of 143 features reworked, 8 in the two-lane run | iteration 2's Opus reviews caught real bugs, but the loop died with the session; MAST: 23.5 % of multi-agent failures are verification, 32 % inter-agent misalignment [Cemri 2025] | sequential coding handed to sub-agents: −70 % at chain position 3 [ChainSWE 2026]; SWE-bench −2.1 to −14.9 % for every multi-agent variant [Kim 2025] | same for writers; for read-only reviewers it works: a clean-context review agent finds ~2 bugs per PR, 58 % severe [Cognition 2026] | A's gates, F1's fix loop (≤ 2 rounds), reviewers as D |
| **Context rot** | every session starts at zero; packs capped 8 KiB (16 for verify); context peak mean 135 k | grows per event; recall falls with length on trivial tasks [Chroma 2025]; 11 of 13 models under 50 % of baseline at 32 k [NoLiMa 2025]; successful bug-fix trajectories stay under 20–30 k tokens [Raju 2026]; compaction's summary is ~20 k tokens [Claude Code caching 2026] | the child is clean; the parent still carries the whole feature | subagents run "in clean context windows" and return 1,000–2,000-token summaries [Anthropic context 2025] | as A |
| **Compounding errors** | the feature list is the ledger: a false `passes` is un-passed by the fast gate and re-checked by verify; "context-budget renewal does not remove regression pressure" unless obligations are tracked [LoopsBench 2026], which `passes` + verify do | per-step accuracy falls as the model's own earlier errors fill the context; a healed history restores it [Sinha 2025]; self-correction without new evidence hurts (GSM8K 95.5 → 89.0) [Huang 2023] | error amplification 17.2× independent, 4.4× centralized [Kim 2025]; compounding lives in repository state, not the transcript [ChainSWE 2026] | same amplification without a central check; the coding prompt's "check each claim with one cheap command" is that check | A's verify; fix rounds counted (`fix_result`) |
| **Self-verification bias** | verify is a separate session; weakness: evidence counted, not judged (`docs/architecture.md` §15) | a supervisor grading work it dispatched is self-grading: "reliably skew positive" [Anthropic harness 2026]; self-preference 0.71–0.91 on GPT-4 [Panickssery 2024] | a child verifying its parent gets the parent's delegation message: biased by the spec [Cognition 2026] | same; "no shared context beforehand" is what made Devin Review work [Cognition 2026] | A's verify; fresh context beats builder's tests (p = 0.006), another provider adds nothing [Sion & April 2026] |
| **Conflicting decisions** | one writer per lane; the driver owns merges; 3 CLAUDE.md conflicts in 10-29-2, all resolved by sessions then verified | one decider (Cognition's principle 2 holds) and one point of failure | "actions carry implicit decisions"; children "wrongly assume they share parent state" [Cognition 2025; 2026] | same; Claude Code's own subagents don't see the parent's history [Claude Code subagents] | A; a steward that proposes cannot conflict with the driver *(inferred)* |
| **Tokens and cost** | $3.50 per Opus coding session; orientation 40 % of tokens, ~⅓ of cost *(inferred)*; cache hit 0.96–0.98; 1 h TTL on the main conversation under a subscription | saves later orientations; pays a longer prefix per turn: cache reads 78 % of a long run's bill [CliffCompaction 2026]; carried context 36.9 % vs fresh 36.5 % resolve, more tokens [ChainSWE 2026]; compaction "is itself a large request" | a new cold prefix (CLAUDE.md, policy) per spawn, no cache shared with the parent; 15× chat [Anthropic multi-agent 2025] | non-fork: separate cache; fork: shared; teams ~7× [Claude Code caching; teams]; spend lands in the parent's `total_cost_usd` | A plus one steward per event (a debrief's size: Sonnet, under $1) |
| **Crash, limit, compaction** | `harness continue` from disk; limit on the structured error, attempt given back; no compaction ever (fresh per feature) | iteration 2: "a crash, limit or compaction of the orchestrator still stops everything"; Anthropic resumes from checkpoints, not restarts, and made the harness stateless with a durable log [Anthropic multi-agent 2025; Managed Agents 2026] | a child's limit refusal is a Bash error to the parent: `metrics.mjs limit` never sees it, the attempt is charged to the feature | `--max-budget-usd` and the 10-min wait cover them; `SubagentStop`/`StopFailure` hooks exist | as A |
| **Reproducible, stub-testable** | 1,181 checks on stub `claude`/`gh`/`curl`; fixtures from real transcripts | a stub must replay a conversation, not a prompt → result pair; grade the end state, not the path [Anthropic evals 2026] | the stub binary is on PATH for the child too, but no check sees a child | inside one stub call; visible only through `parent_tool_use_id` events | A; the steward is one more stubbed kind, as the debrief is |
| **Human gates on the irreversible** | 16 needs reasons, cards, `MERGE_POLICY`, the classifier, auto mode | today it only hands Michael commands; acting would need the debrief's `--allowedTools`/`--disallowedTools` shape; gates on retry caps and irreversible actions [OpenAI guide 2025] | runs under user settings only: `--settings` isn't passed and an untrusted worktree ignores the project's own file (iteration 03) *(inferred)*; no `--strict-mcp-config` | the parent's permissions and settings | A's gates; the steward proposes, bash checks, Michael says yes |
| **Visibility** | `harness status`/`needs`/`show`, a metrics row per session, lane `now` | a Status table updated by PR once per session; a live agent's state is its transcript | none: no row, no scope note, no lane line | summed into the row (`lib/metrics.mjs:19`), `--forward-subagent-text`, transcripts under `~/.claude/projects/…/subagents/` | A plus `steward:` notes in `harness-log.md` |
| **Q6 · stateful single-turn vs multi-turn** | single-turn: each call stateless, the loop in code, the state in files | multi-turn: the loop in the model's context | single-turn sessions with inner multi-turn fan-out | single-turn sessions with inner clean windows | single-turn throughout |

**On Q6, the verdict of the sources.** Anthropic's own practice is single-turn with state in files three times over
(the harness post, 2,000 fresh `claude -p` sessions building a C compiler, a stateless harness over a durable session
log) [Anthropic harness 2025; compiler 2026; Managed Agents 2026]; OpenAI's Symphony runs a fresh worktree per task
and reworks by starting over [OpenAI harness 2026]; Cursor's judge ends a cycle and "the next iteration then starts
fresh", and "periodic fresh starts are still needed to combat drift" [Cursor 2026]; Devin's children get "a clean
slate" per VM and scheduled Devins carry memory in notes [Cognition Devins 2026]. The one dissent is instructive:
Anthropic's March 2026 harness used context resets because Sonnet 4.5 showed "context anxiety", and dropped them for
one continuous compacting session once Opus 4.5 did not [Anthropic harness 2026]. So resets are partly a workaround
for a model weakness that improves, and the right way to decide is their ablation: remove one component at a time
and measure. §7 is that ablation for this repo. The caveat on the other side: a reset loop with no ledger scored
lowest in LoopsBench (7.84 %) because nothing tracked completed obligations [LoopsBench 2026]; this harness's ledger
is the feature list, the entries and the verify, which is why it does not share that result *(inferred)*.

## 4. Question 7: subagents three ways

| | bash-spawned `claude -p` from a session | Claude Code built-in subagent (Agent tool) | a session the driver spawns |
|---|---|---|---|
| What it sees | its prompt, `CLAUDE.md` of the cwd, the tree; not the parent's prompt sections (policy, *This run*, where-things-go), not `context.md` unless told | a delegation message the parent writes, `CLAUDE.md`, a git-status snapshot; never the parent's history (a fork sees all of it) [Claude Code subagents] | the full prompt assembly, the pack, the brief, `INBOX.md`, the init output |
| Cost row | none; its spend is outside the parent's `total_cost_usd` | inside the parent's `total_cost_usd` and `modelUsage` (`usage` undercounts) [Claude Code SDK cost]; summed by `lib/metrics.mjs` (cost = max, turns = sum) | its own row: kind, role, model, cost, tokens, orientation, exit |
| Usage-limit wait | its refusal is a tool error; the parent's attempt burns; `LIMIT_UNTIL` not set | the parent's stream carries the rate-limit events; same plan limits [Claude Code subagents] | `metrics.mjs limit` on the structured error; attempt given back; the box-wide window |
| Memory scopes | writes anything it likes; `restrict`/`lane_guard` still revert what the tree shows (they diff the tree, not the writer) | the parent's write surface; `restrict` as for the parent | the role's scope: coding writes code and its `passes`; verify and retro are read-only by `restrict` |
| `restrict`, `lane_guard` | hold (tree-based) | hold | hold |
| Permissions and MCP | user settings only; no `--settings` (an untrusted worktree ignores the project's file, iteration 03) *(inferred)*; no `--strict-mcp-config`; needs its own `--permission-mode` or it hangs on prompts in `-p` | the parent's mode, settings and MCP config | `--permission-mode auto --settings <wt>/.claude/settings.json --strict-mcp-config` (`lib/record.sh:405`) |
| Memory and scope caps | the parent's systemd scope (a child process), so the 6G cap and the stop hold | the same scope | its own scope `harness-<run>-s<n>`, `mem_peak_mb` recorded |
| Caps on fan-out | none the harness sees | depth 3, 20 concurrent, `--max-budget-usd` stops them [Claude Code subagents; headless] | `MAX_SESSIONS`, `MAX_ATTEMPTS`, the weekly budget, `admit` |
| Cost | a cold prefix per spawn plus the orientation (~554 s here); 15× chat for a research-style fan-out [Anthropic multi-agent 2025] | a cold prefix per non-fork; 1–2 k tokens back; ~7× for teams [Claude Code teams] | one session's price ($3.50 Opus coding, $0.27 verify) and one row |
| Verdict | **ban it**: it escapes every account and gate and buys nothing D doesn't | **inside a session**, for reads, reviews and browser checks (what the coding prompt says today); never a writer | **for anything the harness must count or guard**: triage (F2), fixes (F1 M3), the curator (F3), the steward (§6) |

## 5. Best practice, and where the sources disagree

- **Single agent first; add agents on measured failure.** "Maximize a single agent's capabilities first" [OpenAI guide
  2025]; "the simplest solution possible" [Anthropic agents 2024]; "most coding work" named as a poor multi-agent fit
  [Anthropic multi-agent 2025]; "Most coding tasks" are write-heavy and share context [LangChain Chase 2025]; "Don't
  default to more agents" [Kim 2025].
- **Fresh, bounded runs with state in files.** One feature per session, a JSON list the model is less likely to mangle,
  a startup ritual, a clean mergeable state [Anthropic harness 2025]; "3–10, maybe 20 steps max" and a stateless
  reducer [12-Factor 2025]; `IMPLEMENTATION_PLAN.md` as "shared state between otherwise isolated loop executions"
  [Huntley 2025]; one worktree and process per task [OpenAI harness 2026; Cursor 2026; Cognition Devins 2026].
- **Writes single-threaded, reads parallel, review in a clean context.** Cognition's 2025 rule ("share context … actions
  carry implicit decisions") and its 2026 update ("multi-agent systems work best today when writes stay single-
  threaded") [Cognition 2025; 2026]; Cursor's planner/worker/judge with workers that "don't coordinate" and an
  integrator that "created more bottlenecks than it solved" [Cursor 2026]; the compiler's 16 agents paid off only on
  separable tasks with a near-perfect verifier and "didn't help" on one shared bottleneck [Anthropic compiler 2026].
- **Verification is the binding constraint, and it must execute.** "Generation is not the bottleneck anymore.
  Verification is." [Osmani 2026]; self-correction works only with reliable external feedback [Kamoi 2024]; grade the
  final state [Anthropic evals 2026]; keep an independent final gate whatever the model [Jain 2026]; the harness's
  own supervision-layers finding says the same (items 1–3 there).
- **Instruction files short, invariants enforced.** A ~100-line `AGENTS.md` as a table of contents, "enforced. Not
  documented." [OpenAI harness 2026]; "a bloated AGENTS.md pollutes every future loop's context" [Huntley 2025];
  context files can lower success and raise cost by 20 % [Augment 2026]. This is F3's reason to exist and its risk.
- **Caching shapes the harness.** Claude Code is "built around prompt caching" and alerts on hit rate [Claude Code
  caching blog 2026]; a fresh session gets first-turn hits on ~90 % of a stable prefix when cwd and system prompt
  don't change [Weinberger 2026]: keep the worktree path and the prompt's static part identical across sessions.

**Where they disagree.**
- *Long-lived vs fresh.* Cognition (2025) and LangChain keep one thread alive with a compressor or checkpoints;
  everyone who ran unattended for days resets per task. Anthropic ran both and let the model decide (resets dropped
  when Opus 4.5 stopped wrapping up early) [Anthropic harness 2026]. Nobody defends an unbounded session.
- *Multi-agent.* Measured results are negative on sequential coding [Kim 2025; ChainSWE 2026; Tran & Kiela 2026] and
  positive on decomposable, read-mostly work (+80.8 % on a finance task [Kim 2025], +90.2 % on research [Anthropic
  multi-agent 2025]). Practitioners who scaled fleets (Cursor, Yegge, Cognition) all ended at hierarchy with no peer
  talk, serialized merges and fresh workers; two of three call their own earlier swarms a failure.
- *Supervision.* OpenAI's Frontier team reviews mostly post-merge and gates releases with a human smoke test; Yegge
  says human review "can't" keep up and remains "the bottleneck"; Jules, Devin and Böckeler keep plan approval or
  output review. The common ground: humans tune the harness and approve the irreversible; agents verify before a
  human sees anything [OpenAI harness 2026; Yegge 2026; Fowler Böckeler 2026].

## 6. Recommendation: the next steps toward loop engineering

Each step is one harness run (or one spec session plus a run), in this order. The principle is the one Michael's
concept list already states: *deterministic skeleton, agentic steps*; what changes is who hears a milestone event.

1. **F1 (running): unchanged.** M3's fix loop is the driver deciding to loop and a stateless session fixing; its
   `fix_round`/`fix_result` rows are the data F2 and the steward read. Nothing in this finding changes its spec.
2. **S2 · the steward: an event-driven, stateless supervisor, proposal-first.** The driver invokes one read-only
   session (`prompts/steward.md`, the debrief's shape: `--permission-mode dontAsk`, `--allowedTools`/`--disallowedTools`,
   `--add-dir` the plan and the record, Sonnet by default) at three events: a milestone merged, a verify red past
   `MAX_FIX_ROUNDS`, a run's end. Its input: the dispatch list's Status table and blocks, the phase spec's Predictions
   table, `harness report <run> --md`, the findings file the block names. Its output: the Status row (a `plans:
   dispatch status` PR the session opens, as D0 does by hand today) and one line, `NEXT: <block id>` with the block's
   command, or `WAIT: <why>`. Bash checks the block's `needs` (its PRs merged into `origin/main`, `harness status`
   RUNNING 0 and QUEUED 0 for the project) and opens a `dispatch` needs card (`harness needs`, a notification) with the
   exact command. Michael's action shrinks from reading and pasting to `harness needs done <ref>` or the paste; the
   card records accepted, edited or refused. Checks: a stub steward with planted `NEXT:` lines; a `NEXT:` for a block
   whose `needs` fail opens no card; the steward edits nothing but its PR branch (`restrict`); one steward per event,
   none while the usage window holds. This changes **D0** (the supervisor stops being a session Michael starts) and
   the dispatch rows of **F2** and **F3** (their `needs` become the steward's to check).
3. **S3 · auto-dispatch under tiered authority.** Once S2's cards show ≥ 90 % accepted unedited over ten events, a
   `DISPATCH: <block>` line queues the block itself (`harness queue add`, as the debrief queues continuations), under
   bash rules: the block exists in the dispatch list on `origin/main`, its spec is on main (`lib/spec.sh` already
   refuses otherwise), one dispatch per event, never `--now`, never a new spec, never a production-gated project
   (`MERGE_POLICY=pr`). A refused or edited proposal resets the count. This is F3's "trust earned by measured
   acceptance" applied to dispatch.
4. **S4 · count built-in subagents, ban bash spawning.** A `subagents` field on each metrics row (the stream's
   `parent_tool_use_id` events: count and their share of the row's cost), a note `<id>: <n> subagents ($<c>)`, and a
   transcript scan for a Bash tool call that starts `claude` (`-p` or not) → note `<id>: started claude itself; its
   spend and limits are outside the record` and a `question` item; `prompts/coding.md`, `verify.md` and
   `initializer.md` say it once ("never start `claude` yourself; use subagents"). This is the data §4's verdict rests
   on and the guard it needs.
5. **S5 · F2 triage, as planned, data-gated.** A driver-spawned, read-only, JSON-out single-turn session per red
   (`issue` groups checked by the driver: every failing name in exactly one issue), never a subagent of the fix
   session. Its trigger stands (≥ 30 % of fix rounds leave the red, or names spanning unrelated subsystems); S2's
   steward reads `fix_result` rows and proposes it when the trigger fires.
6. **S6 · F3 curator, as planned,** with S3's rule reused: the `memory: <run>` PR's acceptance rate (merged unedited)
   is the measured gate for its conventions tier to earn auto-merge; protected sections stay proposals for good.
7. **S7 · lanes paced by the suite.** `MAX_LANES=1` on this box until phase 2 (D4) lands and a solo full suite is
   under the fast tier's three-fold; then a box-wide suite token (one full suite at a time across lanes) before a
   second lane opens. Evidence: 9 flake rows and 0.65 first-attempt at two lanes against 0 and 1.00 at one; two lanes'
   suites burn 1.7× the CPU (iteration 08).
8. **Later: verify that executes** (`Coding agent supervision layers.md` items 1–3: frozen tests, tripwires, driver-run
   evidence rows), the one accuracy change the sources all point at; not an orchestration change.

**Should the supervisor become event-driven?** Yes, as S2: the harness already is event-driven at every point that
matters (a milestone's verify, its merge, a needs card, the debrief at a queue's end); the supervisor is the one
loop still clocked by Michael's attention. It should be *stateless* (the Status table is its memory, as today), *read-
only* (the debrief's enforcement layers), *short* (a verify's size), and *proposing* until measured. **What stays
Michael's:** starting a run on a new spec (money and scope), answering parked questions, merges into production-gated
projects, permission and policy changes and the protected sections of `CLAUDE.md`, deleting unmerged work, and every
`block`-severity needs reason (`lib/needs.mjs` `REASONS`). What moves to the loop, in order: the next block of a
dispatch list already approved (S2 → S3), fix rounds (F1), triage (F2), facts in memory (F3's first tier).

## 7. The experiment: fresh session per feature against one resumed session per milestone

The ablation Anthropic's 2026 post recommends, on this repo's own replay set: `harness eval run --set default` (5
tasks, 7 features, ~$28 per eval, `evals/NEXT.md`) with `--repeat 2`, two drivers from one commit. **Control:** today's
driver. **Variant:** `SESSION_MODE=resume`: the next feature of a milestone starts with `--resume <the lane's last
session id>` (the mechanism `entry_resume` uses, `lib/record.sh:392`), the pack still written, the prompt's *This
session* part sent as the new turn, every guard unchanged. Michael runs it (evals are his, `evals/NEXT.md`), when no
run is alive. Predictions, in the shape of `docs/specs/2026-11-03-*.md`:

| Measure | fresh (now: the ten runs' rows) | resumed per milestone (predicted) |
|---|---|---|
| orientation tokens per coding session, features 2+ of a milestone | 2.0 M mean (Opus) | **−50 to −70 %** (the pack, `CLAUDE.md` and the tree are already in context) |
| orientation share of wall | 35 % | 10–20 % |
| wall per coding session | 1,603 s median | −10 to −20 % |
| `context_peak` per session | 135 k mean, 314 k max | 200 k+ by the third feature; **≥ 1 compaction** per milestone of four features |
| cache-hit rate | 0.963–0.976 | ≥ 0.95 (the 1 h TTL covers the gaps) |
| cost per verified feature | $3.57–4.71 | within **±15 %**: fewer orientation reads, a longer prefix re-read every turn |
| first-attempt pass rate | 1.00 (last five runs) | **0.85–0.95**, the misses on the third and fourth feature of a milestone |
| verify-fail rate | 0.00 | 0.05–0.15 |
| un-passes `fast tier red after the session` per 20 sessions | ~0 | 1–2 |
| `repair` (a list edit beyond the session's own `passes`) per 20 sessions | 0 | ≥ 1 *(speculative: a longer session loses the "only your own `passes`" rule)* |

Falsifiers: resumed sessions match fresh ones on first-attempt and verify-fail at ≥ 10 % lower cost per verified
feature → the per-feature split is a model workaround, as Anthropic found, and a per-milestone session becomes an
option worth a spec; resumed sessions lose ≥ 0.15 of first-attempt pass rate → the split stays and the orientation
cost is paid for. Either way the orientation row says what the pack should carry so that a fresh session orients in
fewer than 30 turns, which is a change to `context.md`, not to the orchestration.

## Sources

- [Anthropic agents 2024] Building effective agents, https://www.anthropic.com/research/building-effective-agents, 2024-12-19.
- [Anthropic multi-agent 2025] How we built our multi-agent research system, https://www.anthropic.com/engineering/multi-agent-research-system, 2025-06-13.
- [Anthropic context 2025] Effective context engineering for AI agents, https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents, 2025-09-29.
- [Anthropic harness 2025] Effective harnesses for long-running agents, https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents, 2025-11-26.
- [Anthropic evals 2026] Demystifying evals for AI agents, https://www.anthropic.com/engineering/demystifying-evals-for-ai-agents, 2026-01-09.
- [Anthropic compiler 2026] Building a C compiler with a team of parallel Claudes, https://www.anthropic.com/engineering/building-c-compiler, 2026-02-05.
- [Anthropic harness 2026] Harness design for long-running application development, https://www.anthropic.com/engineering/harness-design-long-running-apps, 2026-03-24.
- [Managed Agents 2026] Scaling Managed Agents: decoupling the brain from the hands, https://www.anthropic.com/engineering/managed-agents, 2026-04-08.
- [Claude Code caching blog 2026] Lessons from building Claude Code: prompt caching is everything, https://claude.dev/blog/lessons-from-building-claude-code-prompt-caching-is-everything/, 2026-04-30.
- [Claude Code subagents] https://code.claude.com/docs/en/sub-agents; [Claude Code teams] https://code.claude.com/docs/en/agent-teams; [headless] https://code.claude.com/docs/en/headless; [Claude Code SDK cost] https://code.claude.com/docs/en/agent-sdk/cost-tracking; [Claude Code caching] https://code.claude.com/docs/en/prompt-caching; all read 2026-11-04 (undated pages).
- [Anthropic caching] Prompt caching, https://platform.claude.com/docs/en/build-with-claude/prompt-caching, read 2026-11-04: write 1.25× (5 min) / 2× (1 h), read 0.1× (0.05× Opus 5.5 and Sonnet 5.5, 0.025× Fable 5.1).
- [Cognition 2025] Don't build multi-agents, https://cognition.ai/blog/dont-build-multi-agents, 2025-06-12.
- [Cognition 2026] Multi-agents: what's actually working, https://cognition.com/blog/multi-agents-working, 2026-04-22.
- [Cognition Devins 2026] Devin can now manage Devins (2026-03-19) and schedule Devins (2026-03-20), https://cognition.com/blog.
- [OpenAI guide 2025] A practical guide to building agents, https://cdn.openai.com/business-guides-and-resources/a-practical-guide-to-building-agents.pdf, 2025-04.
- [OpenAI harness 2026] Harness engineering: leveraging Codex in an agent-first world, https://openai.com/index/harness-engineering/, 2026-02-11 (direct fetch refused; read through InfoQ 2026-02-21 and the Latent Space interview, https://latent.space/p/harness-eng/, 2026-04).
- [LangChain Chase 2025] How and when to build multi-agent systems, https://blog.langchain.com, 2025-06-16; [LangChain bench 2025] Benchmarking multi-agent architectures, https://www.langchain.com/blog/benchmarking-multi-agent-architectures, 2025-06-10.
- [Kim 2025] Towards a science of scaling agent systems (Google Research, DeepMind), https://arxiv.org/abs/2512.08296, 2025-12-09 (v3 2026-04-08).
- [Cursor 2026] Scaling long-running autonomous coding, https://cursor.com/blog/scaling-agents, 2026-01-14.
- [Yegge 2026] Gas Town, https://yegge.ai/gastown (2026-01-01), and The shape of things to come, https://yegge.ai/essays, 2026-08.
- [Huntley 2025] How to Ralph Wiggum, https://github.com/ghuntley/how-to-ralph-wiggum, 2025-07-14 onward.
- [12-Factor 2025] 12-factor agents, https://github.com/humanlayer/12-factor-agents, 2025.
- [Fowler Böckeler 2026] Harness engineering for coding agent users, https://martinfowler.com, 2026-04-02; [Jain 2026] Are harnesses worth the cost?, https://martinfowler.com, 2026-10-13.
- [Augment 2026] Your agent's context is a junk drawer, https://www.augmentcode.com/blog, 2026-02-27 (updated 2026-06-18).
- [Osmani 2026] The factory model, https://addyosmani.com, 2026-02-25.
- [Chroma 2025] Context rot, https://www.trychroma.com/research/context-rot, 2025-07-14.
- [NoLiMa 2025] https://arxiv.org/abs/2502.05167, 2025-02-07.
- [Raju 2026] The limits of long-context reasoning in automated bug fixing, https://arxiv.org/abs/2602.16069, 2026-02-17.
- [Sinha 2025] The illusion of diminishing returns: measuring long-horizon execution in LLMs, https://arxiv.org/abs/2509.09677, 2025-09-11.
- [ChainSWE 2026] https://arxiv.org/abs/2607.02606, 2026-07-01.
- [Huang 2023] Large language models cannot self-correct reasoning yet, https://arxiv.org/abs/2310.01798, 2023-10-03.
- [Kamoi 2024] When can LLMs actually correct their own mistakes?, https://arxiv.org/abs/2406.01297, 2024-06-03.
- [Panickssery 2024] LLM evaluators recognize and favor their own generations, https://arxiv.org/abs/2404.13076, 2024-04-15.
- [Sion & April 2026] Who verifies the builder?, https://zenodo.org/records/23442776, 2026-10-17 (pre-registered preprint; per-condition rates not on the record page).
- [Cemri 2025] Why do multi-agent LLM systems fail? (MAST), https://arxiv.org/abs/2503.13657, 2025-03-17 (v3 2025-10-26).
- [Tran & Kiela 2026] Single-agent LLMs outperform multi-agent systems under equal thinking token budgets, https://arxiv.org/abs/2604.02460, 2026-04-02.
- [LoopsBench 2026] https://arxiv.org/abs/2608.00267, 2026-07-31.
- [CliffCompaction 2026] https://arxiv.org/abs/2609.26779, 2026-09-22.
- [Weinberger 2026] Prompt-induced waste in coding agents, https://arxiv.org/abs/2608.01347, 2026-08-02 (v6 2026-09-10).
- Also read, not cited above: METR Time Horizon 1.1 (https://metr.org/blog/2026-01-29-time-horizon-1-1/, 2026-01-29: Opus 4.5's 50 % horizon 320 min, the 80 % horizon about a quarter of it) and Toby Ord's half-life note (https://www.tobyord.com/writing/half-life, 2025-05-07): the reason features are sized to the 80 % horizon, not the 50 %.
