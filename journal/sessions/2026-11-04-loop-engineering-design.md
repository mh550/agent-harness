# 2026-11-04: from "why didn't T2 merge?" to the first steps of loop engineering (one supervisor session)

The test-suite redesign's supervisor session (D0, `docs/plans/2026-11-03-test-suite-redesign-supervisor.md`), on the
day after phase 3's run (`agent-harness-2026-11-04`). It started as a status check and became a design conversation
about how far the loop should run without me. My messages are below, verbatim and in order (pasted logs summarised in
brackets), each followed by what came out of it. The concepts are listed at the end, one sentence each with this
repo's example, for when I talk about these refinements.

## 1. Why T2 didn't merge itself

> I want to consider why T2 didn't merge itself at all, as I thought our harness should now do that by default.
> Additionally, explain the open 'needs' in detail for me to understand.

- T2 was verified and tagged at 06:17 but never merged. My `run.log` grep showed GitHub failing from 06:07 to 06:18:
  every record-branch push failed, the T2 tag push came back `! [remote rejected] … (failure)`, and three
  `T2: fetch of main failed; merged later` lines followed. `merge_one` returned on the failed fetch with a `run.log`
  line only. `lane_done`'s last branch (`lib/lane.sh:236`) then said "needs Michael: its merge" without opening a card,
  so `harness status` showed `NEEDS YOU 0`. At 06:19 gc removed the run with T2 still unmerged.
- The six question cards were already closed ("by sweep: run removed"), with the defaults standing.
- I landed T2 by hand (PR #89): main had moved only in paths the suite's cache key ignores, so the verify still held.

## 2. The five questions, the end time, the bugs

> 1. I'm okay with splitting it. But the naming is now unclear. […] How do the 'subsets' of tests we're looking to
>    implement on feature-level development tie into this?
> 2. I'm not sure about keeping memlint in the fast tier. […] Let's even think critically on if memlint is even serving
>    the agent-harness at all.
> 4. I'd actually like to open the fix feature automatically and send it back to coding […] My plan for the
>    orchestrator and the projects that I develop with it, is to move towards 'loop engineering' where the whole
>    process is agentic from end to end, but I want to move towards this in a measured way.
>
> I also notice that conversations keep mentioning the 'overnight' nature of the harness, and recommending me harness
> start commands with the '--until 7:30' flag. This is now deprecated […]

- **Tiers.** There are three layers: a subset while iterating (`bash tests/run.sh <name>`, plus `CHECK_KEY_MAP`
  partial runs), the fast tier once and last per session (~150 s, the gate `passes` stands on), and the full suite at
  every verify (~800 s). The confusion is in the names: `86-fast-gate.sh` is fast and `87-fast-gate-run.sh` is slow.
  "fast gate" names the feature they test, not their tier. Renames go into phase 4 (D6): yes.
- **memlint.** It is advisory. It has fired in 0 of 31 run logs. What "caught regressions twice" was the one line
  that lints this repo's own `CLAUDE.md`, which turned the Gotchas cap into a hard gate here, at ~2,500 s per breach.
  Its two stub runs are where the check's ~40 s goes. The split goes into D6: pure cases to `tests/unit`, the stub
  runs to slow.
- **The end time is in code.** `HOURS=8` (`lib/config.sh:12`) ends every segment 8 h in, and a deadline end never
  continues by itself.
- All of it became **F1, run resilience** (`docs/specs/2026-11-04-run-resilience.md`, PR #92, now running as
  `agent-harness-2026-11-04-2`): M1 merges that survive a GitHub outage, M2 no default end time, M3 a red verify that
  opens a fix feature instead of stopping.

## 3. Self-lint, triage, and the first todo list

> How do you recommend we approach self-lint being a gate vs. leaving a cap advisory like other projects?
>
> For the fix loop: what about having an opus/fable session review the failures, identifying if they're the same
> issue or different, and then dispatch coding sessions for the fixes-- thus decoupling the issues/failures from the
> fixes. Is this a good idea? Should we do it now or in the future? If so, what would sensible limits be?

- **Triage: yes, but later (F2).** There is no data yet on how often verify fails or whether failures cluster. A
  single fix session given every failing name already does implicit triage. M3 records an `issue` field and the
  failing names before and after each round, so triage can be added without a format change. Its trigger: ≥ 30 % of
  fix rounds leave the failure standing, or failures span unrelated parts of the code.
- **F2's limits:**
  - one triage session per failure (opus, read-only, JSON out, checked by the driver);
  - at most 3 issues, one fix session per issue with 2 attempts;
  - 2 rounds per milestone and at most 6 fix sessions per milestone in all;
  - before an issue's session, the driver reruns its failing checks and closes it without a session if an earlier
    fix already cleared them.

## 4. Who should curate CLAUDE.md, and how this compares to a multi-turn orchestrator

> 4a. Why don't the coding sessions track their findings & gotchas, and then a 'review' session takes those findings,
> identifies if anything should changes in the CLAUDE.md, rules, workflow, & other memory specific ot the project, and
> then makes those changes? I don't want to be quite so rigid with my changes […] I think an LLM might be the right
> tool for this job.
>
> 4b. One thing I'm considering is how my orchestrator approach compares to this approach […] where instead we have
> multi-turn agents that spawn subagents. Where our supervisor gets an update as each coding instance is resolved, and
> coding instances could spawn subagents for triage / implementation/ verification (but using bash to do so). […]

- **4a, the curator (F3, revised).** Sessions record findings in their entries (they already do: `discoveries`,
  `affects: ["project"]`, `proposed_changes`). One opus session at the run's end consolidates them into project memory.
  It is not the retro: the retro reviews the harness and stays read-only. The driver enforces three tiers of authority:
  - facts (`## Gotchas`, project facts) are applied directly;
  - conventions and workflow lines go into a `memory: <run>` PR with each change's provenance, mine to merge until a
    measured run of accepted PRs earns auto-merge;
  - protected sections (live-system, permission and "never" rules) are only ever proposals.

  The point of the tiers: instruction files are the highest-leverage and least-tested thing in the system, and an LLM
  curator tends to add a rule after every incident.
- **4b.** The exploration prompt is `docs/plans/2026-11-04-orchestration-models-explore.md`. Iteration 2 already tried
  the multi-turn orchestrator: "a crash, limit or compaction of the orchestrator still stops everything"
  (`journal/iterations/02-orchestrator-and-subagents.md`).

## Concepts, one sentence each, with this repo's example

- **Every stop is visible.** A fallback that says "needs Michael" must open a card. T2's `lane_done` fallback didn't,
  and a verified milestone sat unmerged under `NEEDS YOU 0`.
- **Transient failures get bounded retries, then a human.** A 10-minute GitHub outage shouldn't strand verified work:
  F1's `ORIGIN_WAITS` (5 15 30 60 120 s), then a `merge_failed` card.
- **Never garbage-collect unmerged verified work.** gc removed the run with T2 unmerged, and `harness merge` after gc
  dies on "a new run needs --spec".
- **A budget, not a clock.** A run is bounded by sessions, attempts, the weekly budget and usage limits, not by the
  time of day (F1 M2 drops `HOURS=8`).
- **Two gates at two moments.** A session's `passes` stands on the fast tier (~150 s); a merge stands on the full suite
  (~800 s); a fast-green is never read as a green.
- **Name a test by what it tests, not by its tier.** `87-fast-gate-run.sh` reads as fast and is slow.
- **Put a gate where the edit happens.** The Gotchas cap was a suite check in one repo, at ~2,500 s a breach. A
  driver-side check after the session that edited `CLAUDE.md` costs nothing and covers every project.
- **Advisory checks that nobody reads are inventory, not safety.** memlint: 0 findings in 31 runs.
- **The driver decides to loop, an LLM does the fixing.** F1 M3: a red verify opens a fix feature by rule, capped at 2
  rounds, counted in the report.
- **Symptoms are not issues.** Triage maps failing checks to causes, so one cause gets one fix session (F2, data-gated).
- **Rounds are not sessions.** A round is fail → triage → fixes → verify, and "fail" is the verify's outcome, not a
  session. A typical round is 3 sessions.
- **Tiered authority for self-modification.** Facts are applied, conventions go through a PR, protected rules are only
  ever proposed. Trust is earned by measured acceptance.
- **Deterministic skeleton, agentic steps.** The bash driver owns the known path (start, verify, merge, retry, stop),
  and LLM sessions own judgment inside bounded steps. A long-lived orchestrator was iteration 2's single point of
  failure.
- **Spawned work the harness can't see escapes its guards.** A `claude -p` started by a session through bash has no
  cost row, usage-limit wait, memory scope or `restrict`. Spawning belongs to the driver; in-session isolation belongs
  to Claude Code's own subagents.
