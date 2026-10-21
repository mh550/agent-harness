# Retro fixes: the proposals seen in two or more retros (2026-10-21)

**Goal.** Land the small harness changes that the 10-17 → 10-20 retros and the 10-20 debrief kept proposing, each
one test-first with a check in `tests/run.sh`, a `D-H<n>` entry, and its `architecture.md`/`README.md` lines. The
debrief's list (`ledger/debrief.md`, 2026-10-20 16:46, "For the next interactive session") is the source; the run
numbers in brackets say where each was seen. Starts from `main` after the phone-answers PRs (#1–#3) and, if it has
landed, the measure-then-memory run; otherwise from `main` as it is (the two don't overlap except `summary.mjs`
fields, which E1 adds and R1 reads: rebase on what is there).

**Rules.** `CLAUDE.md` binds: work only in the worktree, never touch real runs or state, fakes mirror the live API,
every behaviour visible in `harness-log.md`. Proceed on the defaults below and record them; never park.

## F1 · Driver and CLI correctness

- **R1 · Real test counts** [v2-2026-10-18, portfolio_site-2026-10-20, -20-2, -20-vc4]. `lib/testcount.mjs` reports
  `6 → 6` for portfolio_site, whose suite is 1115 jest tests, and `? → ?` for python projects. Read the total from
  the suite's own output: jest's `Tests: N passed`, pytest's `N passed`, `node --test`'s `# pass N`, cargo's
  `test result: ok. N passed`, go's per-package `ok` lines (count `--- PASS`), and fall back to the current heuristic
  only when none matches, saying so in `harness-log.md`. `check.sh` keeps the suite output (`check.out` already
  exists); `tests-start`/`tests-end` read it. Fixture: real output lines from each runner in `tests/fixtures/`
  (copy them from real runs' `check.out` files, never typed from memory).
- **R4 · Verify never trusts the cache** [portfolio_site-2026-10-20-2, -20-vc4]. Before a verify session the driver
  removes the tree's `green-<key>` marker, so the verifier's `check` runs the suite on the tree it is judging, and the
  verify prompt says the suite will run in full. One check: a stub that leaves a stale green marker is caught.
- **R6 · Michael's queued continuations run** (found 2026-10-21). `harness queue add --continue <run>` queues
  `continue … --queued`, and `cmd_continue --queued` skips a run whose `ended` starts with `stopped by Michael`. That
  guard exists for the driver's own automatic continuations; a continuation Michael queues by hand is a decision to
  resume. Fix: the CLI's `queue add --continue` marks the entry as requested (`--requested`), and only unmarked
  (automatic) continuations are skipped; `harness queue list` shows which is which. Check: a stopped run with a
  requested continuation starts; with an automatic one it is skipped, both logged. (Tonight's workaround: the
  `ended` files of `rane-one-mixxx-2026-10-19` and `hit_list-2026-10-20` were rewritten so their first line no
  longer starts with `stopped by Michael`; undo nothing, just make the flag the real mechanism.)
- **R7 · A stop records why** [hit_list-2026-10-20 retro: "no stop reason was recorded"]. `harness stop <run>
  [--why "<text>"]` writes the reason into `harness-log.md` and `ended` ("stopped by Michael: <why>"); `status: stop`
  in INBOX.md takes an optional reason on the same line. The retro prompt reads it. Checks for both paths.
- **R8 · The 10-19 driver exits** are explained, no change: `voice-concierge-2026-10-19` and
  `portfolio_site-2026-10-19` were superseded by the 10-20 runs started by hand at 00:10 while the 10-19 initializer
  was running; their tmux sessions were killed. Record the finding as the `D-H` note under R7 (a kill should still
  leave an `ended` line: have the driver's trap write `killed` when it fires without a reason, if it doesn't already).

## F2 · Initializer and verify behaviour

- **R2 · Reviews sized to the milestone** [v2-2026-10-18, agent-harness-2026-10-19, rane-one-mixxx-2026-10-19,
  portfolio_site-2026-10-20, -20-2, voice-concierge-2026-10-20: review cost was up to 24 % of a run]. Initializer
  rule: a milestone with one or two build features folds its review into the last build feature's steps ("an Opus
  subagent reviews the diff; Critical/Important findings fixed") instead of a separate review feature; larger
  milestones keep one review feature, with one Opus review round by default and a second only when the first found
  something Critical. `summary.mjs` keeps reporting cost by role so the effect is visible. Check: a stub spec with a
  two-feature milestone yields no `review` kind feature; a five-feature one yields one.
- **R3 · Step lint at init** [rane-one-mixxx-2026-10-19, portfolio_site-2026-10-20, voice-concierge-2026-10-20]. A pure
  `features.mjs lint <list>` that flags: a step with no concrete anchor (no path, command, number, route, width or
  quoted string); a step naming a path outside the repo or in `~`; a grep-shaped step whose pattern also matches the
  step's own text in the run record (the C7-05 park); a milestone after the first without `after`. The initializer
  runs it before committing and fixes what it flags; the driver runs it once after the initializer and `note`s what
  is left (it never edits the list). Checks per rule.
- **R5 · Merge before the deadline stops a run** [voice-concierge-2026-10-20, twice]. When the deadline or `--until`
  ends a run, a milestone whose features all pass but that is not yet verified gets one verify session (bounded by
  `SESSION_TIMEOUT`) before `finish`, and is merged if it holds; `harness-log.md` says so. Check: a stub run whose
  deadline lands after a milestone completes ends with that milestone verified and merged.

## Milestones

| M | Contents | After |
|---|---|---|
| F1 | R1, R4, R6, R7, R8 | — |
| F2 | R2, R3, R5 | [] (independent of F1) |

Each with its checks written first and watched failing, `D-H<n>` entries, and the docs touched in the same milestone.
