# Retro fixes: the proposals seen in two or more retros (2026-10-21)

*Updated in place 2026-10-25 (handoff chunk 4): re-checked against `main` at `36745bf`. R8 is done, R9 moved to
`docs/specs/2026-10-25-resource-lifecycle.md` §L4 (the same `cmd_gc` loop), R1 is partly built, R10 is new (F3), and R11 is a queue bug found while queueing this run.
The run starts after the resource-lifecycle run, from `main` as it stands.*

**Goal.** Land the small harness changes that the 10-17 → 10-21 retros and the debriefs kept proposing, each one
test-first with a check in `tests/run.sh`, a decision file, and its `architecture.md`/`README.md` lines. The run
numbers in brackets say where each was seen.

**Rules.** `CLAUDE.md` binds: work only in the worktree, never touch real runs or state, fakes mirror the live API,
every behaviour visible in `harness-log.md`. Before building an item, check it against `main` (the resource-lifecycle
run lands just before this one and touches `lib/driver.sh`, `lib/check.sh`, `cmd_gc` and `lib/queue.sh`): build on
what is there, and record in the decision file anything already done. Proceed on the defaults below and record them;
never park.

## F1 · Driver and CLI correctness

- **R1 · Real test counts** [v2-2026-10-18, portfolio_site-2026-10-20, -20-2, -20-vc4]. `lib/testcount.mjs` reported
  `6 → 6` for portfolio_site, whose suite is 1115 jest tests, and `? → ?` for python projects. *Status 2026-10-25:*
  `testCount` now reads node:test's `# pass N` and otherwise the last `N passed` / `N tests passed` in the output,
  which covers pytest and jest's `Tests:` line in the usual order. Still to do: prove it on real output (one
  fixture per runner, copied from real runs' `check.out`, including a portfolio_site jest run whose `Test Suites:`
  line also says `passed`), add cargo's `test result: ok. N passed` and go's `--- PASS` count, and log
  `test count: no match` in `harness-log.md` when nothing matches. `tests-start`/`tests-end` keep reading `check.out`.
  The memory spec's §C (a `HARNESS_TESTS=<n>` contract and continued-run staleness) builds on this; don't build it here.
- **R4 · Verify never trusts the cache** [portfolio_site-2026-10-20-2, -20-vc4]. Before a verify session the driver
  removes the tree's `green-<key>` marker, so the verifier's `check` runs the suite on the tree it is judging, and the
  verify prompt says the suite will run in full. One check: a stub that leaves a stale green marker is caught.
- **R6 · Michael's queued continuations run** (found 2026-10-21). `harness queue add --continue <run>` queues
  `continue … --queued`, and `cmd_continue --queued` skips a run whose `ended` starts with `stopped by Michael`. That
  guard exists for the driver's own automatic continuations; a continuation Michael (or the n8n request inbox) queues
  is a decision to resume. Fix: the CLI's `queue add --continue` marks the entry as requested (`--requested`), and
  only unmarked (automatic) continuations are skipped; `harness queue list` shows which is which. Check: a stopped
  run with a requested continuation starts; with an automatic one it is skipped, both logged.
- **R7 · A stop records why** [hit_list-2026-10-20 retro: "no stop reason was recorded"]. `harness stop <run>
  [--why "<text>"]` writes the reason into `harness-log.md` and `ended` ("stopped by Michael: <why>"); `status: stop`
  in INBOX.md takes an optional reason on the same line. The retro prompt reads it. Checks for both paths.
- **R11 · Parking never overwrites a parked entry** (found 2026-10-25, handoff chunk 4). `queue_add` numbers a new
  entry from the top-level `queue/*.args` only (`bin/harness:104-109`), and `queue park` does a plain
  `mv "$f" "$Q/held/"`. So with `held/0004-start-agent-harness.args` parked and nothing active, a new entry is again
  `0004-start-agent-harness.args`, and parking it silently replaced the parked one (it happened to the old n8n-events
  entry on 2026-10-25, which was being replaced anyway). Fix: `queue_add` numbers past the highest number in
  `queue/` and `queue/held/`, and `park` refuses (dies, nothing moved) when the target exists. Checks: an entry added
  while a higher-numbered one is parked gets the next number; parking onto an existing name is refused and both
  entries survive.
- **R8 · The 10-19 driver exits.** *Done:* the EXIT trap writes `driver exited unexpectedly (see run.log)` when it
  fires with no reason (`lib/driver.sh:82-83`). Nothing to build; cite it in R7's decision file.
- **R9 · gc finishes past build output.** *Moved 2026-10-25* to the resource-lifecycle spec, §L4.

## F2 · Initializer and verify behaviour

- **R2 · Reviews sized to the milestone** [v2-2026-10-18, agent-harness-2026-10-19, rane-one-mixxx-2026-10-19,
  portfolio_site-2026-10-20, -20-2, voice-concierge-2026-10-20: review cost was up to 24 % of a run]. Initializer
  rule: a milestone with one or two build features folds its review into the last build feature's steps ("an Opus
  subagent reviews the diff; Critical/Important findings fixed") instead of a separate review feature; larger
  milestones keep one review feature, with one Opus review round by default and a second only when the first found
  something Critical. `summary.mjs` keeps reporting cost by role so the effect is visible. Check: a stub spec with a
  two-feature milestone yields no `review` kind feature; a five-feature one yields one. (The memory spec's §D gates
  the review's model on the diff size; it builds on this.)
- **R3 · Step lint at init** [rane-one-mixxx-2026-10-19, portfolio_site-2026-10-20, voice-concierge-2026-10-20,
  agent-harness-2026-10-21-measure]. A pure `features.mjs lint <list>` that flags: a step with no concrete anchor (no
  path, command, number, route, width or quoted string); a step naming a path outside the repo or in `~` (the measure
  run's E2-02 needed `~/projects/*/.harness/runs`, which its session couldn't read); a grep-shaped step whose pattern
  also matches the step's own text in the run record (the C7-05 park); a milestone after the first without `after`
  (reuse `undeclared`, which the driver already notes at `lib/driver.sh:562`). The initializer runs it before
  committing and fixes what it flags; the driver runs it once after the initializer and `note`s what is left (it
  never edits the list). Checks per rule.
- **R5 · Merge before the deadline stops a run** [voice-concierge-2026-10-20, twice]. When the deadline or `--until`
  ends a run, a milestone whose features all pass but that is not yet verified gets one verify session (bounded by
  `SESSION_TIMEOUT`) before `finish`, and is merged if it holds; `harness-log.md` says so. Check: a stub run whose
  deadline lands after a milestone completes ends with that milestone verified and merged.

## F3 · A given-up feature doesn't end the run

- **R10 · Carry on past a given-up feature** [agent-harness-2026-10-21-measure proposal 1, voice-concierge-2026-10-20
  proposal 2, voice-concierge-2026-10-21, n8n-home-2026-10-22, threads; "a parked feature shouldn't block unrelated
  milestones" is the most repeated proposal nobody had specced]. The measure run ended "blocked on E2-02" with 17
  features never tried, though E2-03…06 and E3-02…05 didn't need E2-02.
  - **Finding.** The scheduler already does the right thing given the dependencies: `schedule()`
    (`lib/features.mjs:64-83`) picks the first feature that isn't given up and whose dependencies pass, and the
    driver ends only when `next` is empty (`lib/driver.sh:587-596`). What ends runs early is the implicit dependency:
    a feature with no `after` depends on **every** feature before it in the whole list (`deps()`, `:47-52`). So E3-02,
    whose milestone's first feature declared `after: ["E1"]`, still waited on all of E2.
  - **Change 1, the default.** A feature with no `after` depends on the earlier features **of its own milestone**,
    plus (for a milestone's first feature) every feature before it, as today. Transitively that is today's order
    when a milestone's first feature has no `after`, so nothing that was safe becomes unsafe; when it declares one,
    the rest of the milestone inherits that declaration instead of reaching past it. Features with no milestone keep
    today's rule.
  - **Change 2, the initializer.** `prompts/initializer.md` asks for `after` on any feature that doesn't need its
    predecessor in the same milestone (the measure run's E2-03…06), and on every milestone's first feature
    (`[]` when it is independent). R3's lint flags the missing ones.
  - **Change 3, visible.** When a feature is given up and other features are still runnable, the driver logs
    `note "<id> given up (<why>); carrying on: <n> runnable, <ids> wait on it"` once, and the run goes on. The end
    reason stays `blocked on <ids>` only when nothing is runnable, and its `harness-log.md` line lists what was done
    after the give-up. A milestone with a given-up feature is never verified or merged (unchanged).
  - **Checks (written first):** `deps()` unit checks for the new default (same milestone; a milestone's first
    feature; no milestone); a stub run in which the first feature of one milestone is given up runs an independent
    later milestone to verified and merged, logs the carrying-on note, and ends `blocked on <id>`; a stub run where
    everything later depends on the given-up feature ends at once, as today; the measure run's real
    `feature_list.json` (`.harness/runs/agent-harness-2026-10-21-measure/`, trimmed into `tests/fixtures/`, its E3
    `after` lines as they were before the run's edit) schedules E3-02 once E3-01 passes with E2-02 given up.
  - **Decision file:** this changes the rule that "array order is dependency order" (the `deps()` comment): say so,
    and that it is narrowed, not dropped.

## Milestones

| M | Contents | After |
|---|---|---|
| F1 | R1, R4, R6, R7, R11 | — |
| F2 | R2, R3, R5 | [] (independent of F1) |
| F3 | R10 | [] (independent; R3's milestone lint is in F2, so F3's initializer line refers to `after` only) |

Each with its checks written first and watched failing, its decision file (`journal/decisions/<date>-<slug>.md`), and
the docs touched in the same milestone. The suite must end green.
