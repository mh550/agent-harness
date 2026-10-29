# Reliability: flakes fixed at their cause, entries that survive, questions that wait in one place, and the leftovers, on two lanes (2026-10-28)

**Goal.** The things that cost the last runs time without failing them get fixed. **R1** finds and fixes the causes
of the flaky checks (the tests' clock assumptions, and any real race they expose). **R2** stops a session's journal
entry from being lost to a missing file or a long summary. **R3** closes the leftovers of the lanes review, Michael's
2026-10-28 build items and a step lint for numbers nobody can reproduce. **R4** gives the questions sessions answer
with a default one place to wait for Michael. **R1, R2 and R3 run side by side on purpose:** this is the first real
two-lane night, on a harness that resolves its own merge conflicts.

**Source.** The candidate list of 2026-10-28 (`HANDOFF-2026-10-28.md`, not committed) as settled with Michael on
2026-10-28/29: A (flakes), B (entries), D (leftovers) side by side, C's lint folded into D, E included after B;
Michael's answers of 2026-10-28 (PR #44: the reviewer follows the session's model; the test count is pinned only from
a green suite; review-gate Minor #8 if cheap); the measurements in `decisions/2026-10-29-check-timeout-25m`; the
evidence quoted per milestone.

**Rules.** `CLAUDE.md` binds: worktree only; never touch real runs or real state; fakes mirror the live API (the
fixtures named below are real output); every behaviour visible in `harness-log.md` (`note`) and checked test-first in a
`tests/checks/` file by topic, names in `tests/fixtures/check-names.txt`; `bash -n` and `node --check`; a decision file
per behaviour change; `docs/architecture.md` and `README.md` in the same milestone. **Proceed on the defaults written
here; record them in the decision files; never park.**

## Why two runs (read this first)

The harness that judges a run is the live checkout (`~/projects/agent-harness` on `main`): `CHECK=$HARNESS_HOME/lib/
check.sh` (`lib/prompt.sh`), the driver and `lib/lane.sh`. Each lane's code is tested in its own slot (its suite runs
there, against the slot's `bin/harness`), but the judge is fixed for the whole run: a lane's own `check.sh` judging the
lane would let a session edit its verdict, and bash reads a script while it runs it, so the queue runner syncs the live
checkout only between runs (`lib/queue.sh`, `lib/sync.sh`). So what protects a night must be merged before it starts.
The guards this night needs (a flake rerun, conflict resolution) are therefore a run of their own,
`docs/specs/2026-10-29-unattended-night.md` (N1, N2), queued **before** this one; the runner's sync between the two
gives this run a harness with both.

## Depends on

- **The unattended-night run (N1 and N2) merged.** The initializer checks first: `git log --oneline origin/main | grep
  -cE 'harness-merge/agent-harness-[0-9-]+-N[12]$'` (2 = both). With both: plan as written. Without one: the plan says
  so in one line and is written anyway; without N2 an overlap conflict between lanes needs Michael as before, without
  N1 a flake costs what it did. Never park on it.
- `main` at or after `91e9712` (status-ux U1–U3; the needs record of U2, which R4 extends).
- `CHECK_TIMEOUT=25m` in `.harness/config.sh` (this spec's PR).

## Lanes on purpose, and what overlaps

R1, R2 and R3 each have a first feature with `"after": []`; R4's first feature has `"after": ["R2"]` (both change what
happens to an entry at ingest, in `lib/entries.mjs` and `journal`). With `MAX_LANES=2`, two of R1–R3 open together and
the third when a lane closes. The code files are kept apart (R1: `tests/`; R2: `lib/entries.mjs`, `journal`/`session`
in `lib/record.sh`, the prompts' entry steps, `tests/stub-claude.sh`; R3: `lib/features.mjs`, `merge_one`/`run_init`,
`finish`, the review gate, `prompts/coding.md` §2), but **file names overlap anyway**, and that is accepted: every
milestone adds names to `tests/fixtures/check-names.txt` (merged by N2's sorted driver) and updates
`docs/architecture.md` and `README.md` (`CLAUDE.md` requires it in the same milestone); R2 and R3 both edit
`lib/record.sh` and `prompts/coding.md`. So each lane that merges after another takes one re-base verify round, and a
text conflict a resolve session (N2). That is the second thing this night tests. Keep each milestone's edits to the
shared docs in its closing review feature, in the sections it owns (below), so conflicts stay small.

| Shared file | R1 writes | R2 writes | R3 writes | R4 writes |
|---|---|---|---|---|
| `docs/architecture.md` | §7 test-suite guards, §15 | §4 the journal, §5 the session's end | §4 lanes prose (P2-06), §12 | §4 needs record, §17 |
| `README.md` | the suite (how to reproduce a flake) | entries | config and lint | `harness needs` questions |

---

## R1 · The flakes, fixed where they start

**Finding.** Checks that pass alone fail under load or now and then: 28-run-14d-harness-merge, 48-lanes-rebase (10-28,
"both pass alone"); 46 pr-held, 38 pack bytes, 32 MAX_PARALLEL_RUNS, 08 no user systemd (10-28, "none in code U1
changed"); 15 `the weekly budget ends a run after the session that crossed it` (2026-10-29, one suite alone); 44
`lanes record: a session's question above ## Answers …` and `harness start --base: …` (2026-10-29, two suites at once;
`fatal: Not a valid object name harness-lane/rec/M2`: that stub run ended without the lane branch, so the driver took
another path under load). The test library waits on the clock: `in_has` gives a tmux line 2 s (`seq 20` × 0.1 s), the
debrief wait 30 s (`seq 150` × 0.2 s), `ran()` orders log lines with `sleep 1`, and eight check files hold 3 to 16
`sleep`s each (`grep -c sleep tests/checks/*.sh`). A flake can also be the only symptom of a real race: P2 review
Minor 5, "the 47 flake", was a coordinator ordering bug, fixed in the driver. N1's guard only keeps a flake from
costing a session; this milestone removes them.

1. **`wait_for <max seconds> <command…>`** in `tests/lib.sh`: runs the command every 0.1 s until it succeeds (0) or the
   time is up (1, after printing `wait_for: <command> still failing after <max> s`). Defaults generous (30 s; 60 s for a
   whole stub run's end): a passing check returns the moment its condition holds, so a long limit costs nothing.
   `in_has` and the debrief wait are rewritten on it; every fixed-iteration poll in `tests/` becomes a `wait_for`.
2. **Barriers, not sleeps, for order.** Where a check needs one event before another (a lane exits before the other
   opens, a session ends while a merge runs), the stub waits for a file the check creates (`stub_wait <name>` /
   `stub_go <name>` in `tests/lib.sh`, files under `$T/barriers/`). The existing `STUB_SLOW_*` sleeps that stand in for
   work stay (they are the work), each with `# sleep-ok: <why>`.
3. **The sleep lint**: a check that fails on a `sleep` in `tests/checks/*.sh` or `tests/lib.sh` without `# sleep-ok:`
   on its line (stub scripts exempt), printing each `file:line`.
4. **`tests/run.sh --repeat <n> <name>…`**: runs each named file `n` times, `TEST_JOBS` copies at once (load by
   design), each from its fresh state, and prints `<file>: <k>/<n> green` plus the FAIL lines of the red copies; exit 1
   when any copy was red. This is how a flake is reproduced, and how its fix is shown (`10/10 green` under load, in the
   feature's entry `verified_how`).
5. **Each named flaker:** reproduced with `--repeat 10` (stopping at the first red copy; one file's copies take
   minutes, file 15 about 3.5 min each under load, so at most 30 minutes of repeats per flaker, then noted as not
   reproduced), run directly in the session (its scope caps it; not through `{{CHECK}}`, whose timeout is the
   suite's). Plan the flakers as two or three features after the tools' feature, grouped by file. Each is its cause written in the
   milestone's plan file (a table: check, cause, fix, before → after), fixed **at the cause**: a test's clock
   assumption → items 1–2; a real race in `lib/` or `bin/` → fixed there with a check of its own that fails before
   the fix (a barrier-ordered stub run), and a decision file if behaviour changes. The `44-lanes-record` path above is
   investigated first: a missing lane branch is a driver outcome, not a test's timing.
6. **Decision and docs.** `journal/decisions/2026-10-29-tests-wait-not-sleep.md` (finding · choice · rejected:
   longer sleeps; `TEST_JOBS=2` per `decisions/2026-10-29-check-timeout-25m`; quarantine per
   `decisions/2026-10-29-rerun-guard`). `docs/architecture.md` §7 and §15, `README.md` (the suite: `--repeat`).

**Checks (written first):** `wait_for` returns 0 as soon as a file appears (well under its limit) and 1 with its line
when it never does; a stub barrier orders two background jobs the same way 20 times; the sleep lint fails on a fixture
file with a bare `sleep 1` and passes with `# sleep-ok: x`; `--repeat 3` on a stub check file that fails every other
copy prints `2/3 green` or `1/3 green` and exits 1, and `3/3 green` and 0 for a steady one; each fixed flaker's own
check unchanged in name and passing `--repeat 10` (recorded in the entry, not in the suite: the suite runs once).

## R2 · Entries that survive: the session checks its own, the driver trims a long summary, one resume for a missing one

**Finding.** Each session writes `entry.json`; `journal` → `entries.mjs ingest` validates it into `entries.jsonl`, which
renders `progress.md` and the next session's `context.md`. A missing or invalid entry becomes a **minimal** one (the
final message and the files git saw change): its `dead_ends`, `discoveries`, `questions` and `resolved` are lost, the
parts the next session reads first. 2026-10-28: `U1-03: entry.json missing; recorded a minimal entry`, `U1-05:
entry.json invalid (summary: 410 characters (at most 400))`; 2026-10-26: `P2-01: entry.json invalid (summary: 413
characters (at most 400))`; the 10-26 retro's first finding: P1-03 lost about 50 minutes when its session ended while a
background review was still pending, so no entry was written and the next session started without it. The prompts say
"at most 400 characters" (`prompts/coding.md`, `verify.md`, `initializer.md`), but nothing checks before the session
ends.

1. **The session checks its entry.** `prompt_env` exports `HARNESS_ENTRY_CHECK` (`node $HARNESS_HOME/lib/entries.mjs
   validate`, the twin of `HARNESS_LINT`); `prompts/coding.md`, `verify.md` and `initializer.md` ask the session to run
   `{{ENTRY_CHECK}} <run directory>/entry.json <feature> <kind>` as its last step and fix every line it prints.
2. **A long summary is trimmed, not dropped.** At ingest, an entry whose only errors are `summary: <n> characters (at
   most 400)` (and the same for `header`'s cap) is kept whole with the field cut to fit (`…` last), and noted `"<id>:
   entry.json summary <n> characters; cut to 400 and kept"`. Any other error is a minimal entry as today.
3. **No background work at the end.** The prompts' finish steps: never end the turn while a background task or
   subagent is still running; wait for it, or stop it and say so in the entry.
4. **One resume for a missing or invalid entry.** After a coding, verify or init session whose entry would be minimal
   (and that was not refused by a limit: `MET limit`), the driver resumes it once: `claude -p "<the resume prompt>"
   --resume <session id>` with the session's model, settings and MCP flags, in the session's scope role (a new
   `s<n>`), with `ENTRY_RESUME_TURNS=8`, `ENTRY_RESUME_TIMEOUT=10m`, and `--max-budget-usd` = the session's
   `total_cost_usd` so far **plus** `ENTRY_RESUME_BUDGET_USD=1`. A resumed session's `total_cost_usd` and `modelUsage`
   are **cumulative** over every run of that session id (fixtures: 0.0031 → 0.0055 → 0.0058 across `first.jsonl`,
   `resumed.jsonl`, `resumed-again-under-cap.jsonl`), and a cap below the spend so far did not stop a one-turn resume
   (`resumed-again-under-cap.jsonl`, `--max-budget-usd 0.003`); whether the CLI checks the cap against the cumulative
   figure between turns is unmeasured, so the cap is set to work either way. The session id is the
   `session_id` of the transcript's `system`/`init` line; a resumed session **keeps the same id** and its own
   transcript (`tests/fixtures/claude-resume/first.jsonl` and `resumed.jsonl`, captured 2026-10-29 from `claude -p …
   --output-format stream-json --verbose` and `--resume`: 6 and 4 lines, the resume answering from the first's
   context). The resume prompt (`prompts/entry-resume.md`): the validator's lines (or "it is missing"), "write
   `<run dir>/entry.json` and nothing else; run `{{ENTRY_CHECK}}`; end". After it: `restrict` reverts anything but the
   run record (as for a verify); the ingest runs again; still bad → minimal, with `note "<id>: entry.json still
   <why> after one resume; recorded a minimal entry"`; good → `note "<id>: entry.json written on a resume"`. Its cost is
   a `metrics.jsonl` row of kind `entry-resume` holding **only the difference** (the resume's cumulative cost minus the
   session's; tokens likewise), counted in spend, not as a session in `MAX_SESSIONS`. The resume
   transcript sits beside the session's (`<nn>-<id>.resume.jsonl`).
5. **Stubs.** `tests/stub-claude.sh` prints an `init` line with a `session_id` as the fixture does, accepts `--resume
   <id>` (an unknown id answered as the real CLI does, `tests/fixtures/claude-resume/unknown-id.out`, captured
   2026-10-29: `No conversation found with session ID: <id>` on stderr, one `result` line with `subtype:
   "error_during_execution"`, exit 1), and learns `STUB_NO_ENTRY=<id>` (writes none) and
   `STUB_RESUME_ENTRY=good|bad`.
6. **Decision and docs.** `journal/decisions/2026-10-29-entries-survive.md` (finding · choice · rejected: dropping the
   400 cap; resuming more than once; resuming a refused session; writing the entry from the transcript by code).
   `docs/architecture.md` §4 (the journal: trim, resume) and §5 (the session's end); `README.md` (entries).

**Checks (written first):** `{{ENTRY_CHECK}}` renders in the three prompts; a 410-character summary is kept with every
other field and the note; a summary over 400 **and** a bad `outcome` → minimal as today; `STUB_NO_ENTRY=A` with
`STUB_RESUME_ENTRY=good` → one resume with `--resume <the init line's id>`, the entry in `entries.jsonl` with its
`dead_ends`, the note, an `entry-resume` metrics row, the session count unchanged; `STUB_RESUME_ENTRY=bad` → minimal and
the "after one resume" note; a limit-refused session → no resume; a resume that edits a code file → reverted.

## R3 · Leftovers: the lanes review, Michael's build items, and a lint for numbers nobody can reproduce

**Finding.** `docs/plans/2026-10-26-P2-review.md` left Minors 6–10 and 12 open; Michael's answers of 2026-10-28 (PR #44,
in `decisions/2026-10-27-review-gate`, `2026-10-26-test-count-contract`, and `docs/plans/2026-10-26-M6-review.md` row 8)
made three build items; verify steps have cited numbers no verifier could reproduce: the 10-26 P0-02 gate of `<150 s`
(the suite's wall time on one box under one load), and the memory run's M5-01 citing "this run's scratch check.out (395
tests)" while the fixture held 474 (the debrief saw both, in two retros).

1. **Atomic list writes (P2 Minor 6).** Every `writeFileSync` of the feature list, attempts and parked files in
   `lib/features.mjs` (and the progress render in `lib/entries.mjs`) writes `<file>.<pid>.tmp` and `renameSync`s it, so
   another lane's unlocked read never sees half a file.
2. **A `main` moved only where the suite never looks costs no suite (P2 Minor 8).** In `merge_one`'s tree test, a
   `main` that moved since the tag only in `CHECK_KEY_IGNORE` paths (the run record, and in this repo also `ledger/`,
   `journal/`, `docs/plans`, `docs/specs`: a record PR, a ledger or debrief commit) counts as unmoved: `git diff
   --quiet <tag> <merged tree> -- . <':!<path>' per ignored path>`, and the milestone merges without a re-base. The
   invariant is restated in the decision file: what lands is byte for byte what was verified **outside the paths the
   suite's cache key ignores** (which by definition can't change the suite's verdict).
3. **`finish`: the record PR before the ledger (P2 Minor 9),** so the ledger's copy has the record-PR note.
4. **Unit names that collide (P2 Minor 10).** A lane's unit prefix is `LANEU=${M//[^A-Za-z0-9_]/_}` (`lib/lane.sh`),
   so milestones `M1-x`, `M1.x` and `M1_x` share units (and `scope_unit` maps its run id with `[^A-Za-z0-9_-]` → `-`).
   `features.mjs lint` gains `unit-collision`: two milestone ids that map to one name under `LANEU`'s mapping.
5. **The checks P2 Minor 12 named:** `harness gc --dry-run` lists a leftover slot and a lane branch without removing
   them; two `merge_milestones` of one milestone at once (two stub lanes through the merge lock) merge it once.
6. **`<id>: suite ran <n>x (<s> s) in the session` (P2 Minor 7, planned in `docs/plans/2026-10-26-P2-two-lanes.md` §6
   and never built):** `check.sh` appends `<epoch>\t<full|subset|cached>\t<seconds>` to `$HARNESS_SCRATCH/check-runs.log`;
   the lane stamps just before and after its `session coding` call (in `lib/lane.sh`, not inside `session()`, which R2
   edits); the lane notes the count and seconds of full and subset runs between the
   stamps after each coding session.
7. **The reviewer follows the session's model** (Michael, 2026-10-28, `decisions/2026-10-27-review-gate` default 5):
   `prompts/coding.md` §2's "Reviews go to **Opus** subagents" becomes "to subagents on your own model
   (`{{MODEL}}`)"; a review at or over `REVIEW_OPUS_LINES` is an Opus session already. The decision file gets its
   `Updated in place` line; judge it by the ledger's `review_cost_pct` and verify-fail rate.
8. **The test count is pinned only from a green suite** (a rerun-green suite of N1 counts as green; its count is the
   first run's, which N1 keeps in `check.out` with the rerun's output in `check-rerun.out`, never appended, so the
   generic rule's last `N/M checks passed` is the full run's: N1's plan settles that file split, and this item checks
   it) (Michael, 2026-10-28, `decisions/2026-10-26-test-count-contract`):
   in `run_init`, `tests-start` and `testcount-source` are written only when that `$CHECK` exited 0, so a red first
   suite (which may print no count) no longer records `none` for the whole run; a later green one pins them.
9. **Review-gate Minor #8, if cheap** (`docs/plans/2026-10-26-M6-review.md` row 8): the review gate's un-pass runs
   before the `passes=` note and the metrics row, so a run ending between the two sessions shows the pending round in
   `summary.json`'s cause. If it isn't a move of lines in the lane's session tail, say so in the entry and leave it.
10. **The lint for numbers (C):** `features.mjs lint` gains `unreproducible`: a step with a time bound (`< 150 s`,
    `under 2 minutes`, `in at most 30 s`) or a count of tests or checks tied to one run's output (`395 tests`, `this
    run's check.out`) gets one finding, "a number another box or run won't reproduce: cite the command that prints it,
    or a bound with room". Reported, never applied, like the others (`decisions/2026-10-26-step-lint`). The initializer
    prompt says to state counts as commands (`tests/run.sh` prints `N/M checks passed`) and time bounds as budgets with
    room.
11. **Docs:** `docs/architecture.md` §4 and §12, the prose P2-06 never wrote: the `lane <m> · …` line of `harness status
    <run>` and `summary.json` `lanes: {max_open, lane_hours, wall_hours}`.
12. **Decisions:** `journal/decisions/2026-10-29-lanes-leftovers.md` for items 1–6 and 10; items 7–9 as `Updated in
    place 2026-10-29: built …` lines in the decision files Michael's answers are in.

**Checks (written first):** a list rewritten while a reader loops never reads as invalid JSON (a stub writer and reader
200 times); a record-only main → `merged` with no re-base note; the ledger copy of a stub run has the record-PR note;
lint `unit-collision` on `M1-x`/`M1.x`/`M1_x`; the two `gc --dry-run` lines; one merge for two concurrent `merge_milestones`;
`STUB_RUN_SUITE=A` → `A: suite ran 2x (`, B's `suite ran 0x (0 s)`; the coding prompt renders the model in the review
line; a red first suite then a green one → `tests-start` from the green and `test count: parsed (…)` noted once; the
review gate's un-pass before the note (if built); lint `unreproducible` on `< 150 s` and `395 tests`, none on `the suite
is green`.

## R4 · Questions where a session took a default wait in `harness needs` until answered

**Finding.** Sessions never park on a judgment call: they take a default and write the question in their entry's
`questions` (U2-08 made each name its files). Those questions reach the run's `progress.md` and the debrief, which greps
`progress.md` for "question" (`lib/debrief.sh`, the first 12 lines), and nowhere else; `harness needs` (U2) holds only
stops. Eight questions from the memory run sat for days; one ("should the review session's reviewer subagent follow the
session's model?") was asked three times; on 2026-10-28 Michael answered seven from a hand-built checklist (PR #44).

1. **A `question` reason** in `lib/needs.mjs` `REASONS`: kind `needs_michael`, severity `warn`, priority `""` (no push).
   Opened at ingest, one item per entry question, by `journal_` through `needs_open question <subject>` with the
   question text, its `Files:` paths, the default the session took (the question's own text says it; nothing parsed
   beyond U2-08's `Files:`), the entry's run, feature and `entries.jsonl` line.
2. **One open item per question across sessions and runs:** `key` = `question:<the first 80 characters, whitespace
   folded, lower-cased>`. Asked again in the same run: the item is refreshed (`seen`, `updated_at`). Asked again in a
   later run of the same project while an earlier run holds it open: **the item moves forward**: the new run opens it
   with `seen` = the old `seen` + 1 and `asked_in: [<runs>]`, and the old one is resolved `asked again in <run>` (a
   rename into that run's `needs/done/`, the only write into another run's state dir, through `needs.mjs`). So the
   three-times question is one open item with `seen: 3`, in the newest run, where a later entry's `resolved` can close
   it.
3. **Resolved by:** `harness needs done <ref> [--why "<answer>"]` (U2); a later entry's `resolved` listing it (the
   existing match, `decisions/2026-10-26-resolved-and-project-facts`), applied by the sweep; and the `harness-answer`
   skill, which already reads `harness needs`: its SKILL.md learns to record Michael's answer as an `Updated in place
   <date>: Michael …` line in the decision file the question names and run `harness needs done <ref> --why`.
4. **Readers.** `harness needs` lists `warn` items after `block` ones (U2's order); `harness status`'s NEEDS YOU counts
   them apart (`NEEDS YOU 1 · 3 questions`), so a question never hides a stop; the debrief's `Needs Michael` reads
   the open question items instead of the grep; no notification.
5. **Decision and docs.** `journal/decisions/2026-10-29-questions-wait.md` (finding · choice · rejected: a push per
   question; parking on a question; detecting an answer from a decision file's text). `docs/architecture.md` §4 and
   §17; `README.md` (`harness needs` questions, resolving them).

**Checks (written first):** an entry with two questions → two `question` items with their `Files:`; the same question
in a later session → one item, `seen: 2`; a later entry's `resolved` → the item resolved at the next sweep; `harness
needs done` with `--why`; `harness status` shows `· 2 questions` apart from block items and no notification was sent
(the ntfy stub's log empty); the debrief's gatherer lists the open questions.

---

## Milestones

| M | Contents | After |
|---|---|---|
| R1 | `wait_for`, barriers, the sleep lint, `--repeat`; every named flaker reproduced and fixed at its cause; docs; `2026-10-29-tests-wait-not-sleep` | `[]` |
| R2 | `{{ENTRY_CHECK}}`; the summary trim; the background-work rule; one resume (`--resume`, its fixture, caps, metrics); stubs; docs; `2026-10-29-entries-survive` | `[]` |
| R3 | atomic writes; record-only main; finish order; `unit-collision`; Minor 12's checks; the `suite ran` note; reviewer model; test-count pin; review-gate Minor #8 if cheap; lint `unreproducible`; §4/§12 prose; `2026-10-29-lanes-leftovers` and the in-place lines | `[]` |
| R4 | the `question` reason, key and refresh, resolution, readers; the answer skill; docs; `2026-10-29-questions-wait` | `["R2"]` |

Plan each as three to five features, the last a review feature sized to the milestone. The suite ends green at every
milestone.

## Not in this run

The n8n events spec (`docs/specs/2026-10-22-n8n-events.md`, next); feature-level lanes (throughput design §4.9);
suite-split S4 (`--for`); conflicts on the record branch; changes to `TEST_JOBS` or `MAX_LANES`; any edit to
`CLAUDE.md`'s *How to verify* (Michael's; see below).

## Before the run (Michael)

1. Merge this spec's PR (it carries both specs, `CHECK_TIMEOUT=25m` and its decision).
2. Queue both runs, the unattended night first:
   `harness queue add ~/projects/agent-harness --spec docs/specs/2026-10-29-unattended-night.md`, then
   `harness queue add ~/projects/agent-harness --spec docs/specs/2026-10-28-reliability.md`, then `harness queue
   start`. One run per project holds this one until the first ends; the runner syncs the live checkout between them.
3. Check the two settings a second lane needs, in `~/.config/harness/config.sh` (sessions may not read it): `grep -E
   '^(MAX_LANES|LANE_RESERVE_GB)=' ~/.config/harness/config.sh` → `MAX_LANES=2` and `LANE_RESERVE_GB=2`. The code's
   defaults are `MAX_LANES=1` and `LANE_RESERVE_GB=4` (`lib/config.sh`): with either missing this run is serial and the
   two-lane test doesn't happen. Then memory for a second lane: 7 GB available (`MEM_MIN_AVAILABLE_GB` 5 + `LANE_RESERVE_GB` 2 × 1 open lane); the box
   showed 8.1–8.7 GB on 2026-10-28/29. A lane also waits while the five-hour window is over `LANE_OPEN_BELOW_5H` (70 %).
   Either refusal is `lane <m> waiting: <reason>` in the log, once per reason.

## After the run (Michael)

- `harness report <run>`: `Lanes | at most 2 open at once`, the `Flakes` and `Conflicts` rows; `grep -E 'waiting:|flaky:|
  resolve session|re-based' <run dir>/harness-log.md`.
- `CLAUDE.md` *How to verify* says the suite takes "~3 min 30 s … 208 s measured": on 2026-10-29 it took 601 s alone
  (859 checks). Update or drop the figure (`decisions/2026-10-29-check-timeout-25m`).
- The eval baseline postponed from 2026-10-28 (`EVAL_BUDGET_USD=35 harness eval run --set default --harness
  run/agent-harness-2026-10-28/U3 --label baseline-2026-10-28`) can run any time no run is alive.
