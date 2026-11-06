# The suite's shape: check files named for what they test, no name part of another's, two cuts that need no replay, a tier on every line

*(2026-11-06, the slim suite's S2b built by hand (`docs/plans/2026-11-05-slim-suite-by-hand.md`, the shape session); spec
`docs/specs/2026-11-03-slim-suite.md` S2, item 2 (items 1 and 3 were the trim's, `decisions/2026-11-03-trim`); Decisions
3, 10, 13, 14 and 15 of the redesign's dispatch list (`docs/plans/2026-11-03-test-suite-redesign-dispatch.md`). Base
tree `74e3e6d`.)*

## Finding

- **A check file's name was its history.** `tests/split.sh` cut the single-file suite at its section titles and named
  each file by a number and the title's first words: `15-run-4-same-but-queue-parked-debrief-tmux`,
  `03-harness-parked-pure-report` (one check, on a notification body's cap), `23-run-12b-nothing-sets`. Files added
  since took the next number and a feature id (`39-memlint-m4`, `31-tmux-l3-03-when`). The runner orders by size
  (`ls -S`), never by name, so the number ordered nothing.
- **The number did one thing nobody had written down: it kept every name from being part of another's.**
  `tests/run.sh <name>` matches by substring, and `lib/check.sh`'s rerun of a red passes the red files' names
  (`HARNESS_FAILED=`) back as arguments. With `86-fast-gate` and `87-fast-gate-run` each name picks one file. As
  `fast-gate` and `fast-gate-run`, a red in the first (fast, 4 s) would rerun the second too (slow, 22 s), from the
  session's fast gate, and `tests/run.sh fast-gate` could not run the first alone.
- **A split buys no wall time.** In the last kept solo run with per-file times (2026-11-05,
  `findings-and-research/2026-11-03-resident-helper/suite-after-files.txt`) the files' slot times add up to 2,404 s
  over a 608 s wall at 4 jobs: the slots are packed, and the longest file (170 s) is nowhere near the wall. A split that
  replays earlier sections for their state adds a stub start per replayed run, to the CPU and to the count of lines
  that start a stub run: the two rows of the spec's Predictions table already on course to miss (Decision 16).
- **Two sections of file 15 read no run of it.** The weekly-budget run (`run 17`) and gc's reaping of tmux sessions
  (`tmux (L3-04)`) came last in `15-run-4-same-but-queue-parked-debrief-tmux` and took from the file only the plain
  user config its debrief sections end on, the queue directory's name (`$Q`) and a one-line function (`has_s`). Every
  other section of it stands on the runs before it (the queue's first runner run, `stoppy`, `gated`, `limited`,
  `walled`), as the sections of files 08 and 13 stand on theirs.
- **The memlint check file was three things**, and fast only by a named exception (42.1 s, over the 30 s line): 15
  checks ran the CLI on fixture worktrees, one linted this checkout (the check that caught a sixteenth Gotchas line
  twice, outside the feature that added it), three stood on two stub runs.
- **Two check names held a check file's name**: `the unit tier: TEST_XTRACE_DIR=<dir> puts node's coverage in
  <dir>/00-unit-tier/v8` and `CLAUDE.md names the node floor 22.8 and the unit tier: tests/unit, node --test, bash
  tests/run.sh 00-unit` (the second also asserts that line of `CLAUDE.md`).
- **The coverage tool told a unit file's set by its name's prefix** (`unit-<name>.txt`), so a check file called
  `unit-tier` would have left the check-file tables and the union as a unit row called `tier`.
- **The real 64 MB scope check said nothing when red** (red about one run in five since 2026-10-26; it cost the trim
  session a second full suite), so nobody knows which way it fails.
- **Nine check files had a tier header and no row in the tiers' table** (their sessions wrote none).

## Choice

**The names.** A check file is named for what it tests, in the words a person would look for: no number, no feature
id, no run number. A file that collects one review's findings keeps the review's name (`status-review`,
`needs-review`, `u3-review`, `leftovers`): it has no single unit, and sorting its checks into other files would move
checks. **No name is part of another's**, so `tests/run.sh <file>` and a red file's rerun pick that file alone: where
two files share a subject, both say which side they test (`session-gate-check` and `session-gate-driver`,
`resident-helper-ask` and `resident-helper-run`, `review-gate-model` and `review-gate-rounds`, `lanes-record-lock` and
`lanes-record-pr`, `testcount-fixtures` and `test-count-source`, `memlint-self` and `memlint-run`). A lint keeps it so:
`name lint: no check file's name is part of another's …` (in `suite-runner`, on the real tree and on a planted pair).

**The two files Decision 3 asked to rename** so their names do not read as a tier: `86-fast-gate` is
`session-gate-check` (`check.sh --fast`, the gate a session's `passes` stands on) and `87-fast-gate-run` is
`session-gate-driver` (the driver's side of it). Their checks keep their names (`fast gate: …`, `fast gate run: …`):
no check name changes for a rename.

**The runner's per-file line ends with the file's tier**: `<file>: <n> checks, <s> s, tier <fast|slow>`, the file's
own tier whatever the run (Michael, 2026-11-04; check: `tiers: each file's timing line ends with its tier …`).
`tests/tools/mutants.mjs` reads the line with or without the tier (an output kept from before has none).

**Splits: only where no replay is needed.** `weekly-budget` (3 checks, 2.9 s alone) and `gc-tmux` (4 checks, 0.5 s
alone) are cut out of file 15, every section line byte for byte, each with the two setup lines that give it what it
had there; the rest is `queue-debrief` (72 checks, 129.7 s alone; 79 checks and about 138 s before). Both new files
are fast by the 30 s rule, each timed once alone. **The proof that the cut loses nothing**: file 15 traced before the
cut and its three parts after (`tests/tools/coverage.sh <dir> <names>`, S1's method): 4,148 lines of `lib/` and `bin/`
before, 4,148 after. Two lines are run by none of the three any more (`bin/harness` 869–870, gc's sweep of the needs
of a run whose worktree is gone: file 15's gc met real ended runs, the cut-out file's meets fabricated ones); five
other check files of the trim's traced suite run them (`coverage.mjs covering`), so the suite's union loses nothing.
Two lines are newly run (`lib/driver.sh` 575–576, the lane-count hold, which depends on timing). The spec's four-way
cut of file 15 (`queue`, `parked`, `debrief`, `tmux`) is not made: `parked` and `debrief` read the queue's first
runner run, and the debrief sections read five earlier runs. Files 08 and 13 are renamed whole for the same reason.

**The memlint check file in three (Decision 3, item 1).** Its 15 module cases are unit tests in
`tests/unit/memlint.test.mjs` under the same names, each still the CLI's own bytes and exit code (`sameAsCli`), on a
worktree under the OS temp dir; each was seen red against a broken module (four mutations of `lib/memlint.mjs`, one at
a time, the file restored after each). The lint of this checkout stays a bash check in a fast file of its own,
`memlint-self` (it reads the root's `CLAUDE.md`, so it is the name in `CHECK_KEY_MAP`). The two stub runs and
`harness memlint` are `memlint-run`, slow. The dispatch list counted 16 module cases; there are 15, the sixteenth
`memlint:` check being the self-lint.

**`node-memo` is slow (Decision 3, item 2), and `memlint-run` is slow, by Michael's word, not by the 30 s line.**
Alone on 2026-11-06 `node-memo` took 28.0 s and 27.9 s (31.5 s and 31.0 s in the full runs the decision was made on)
and `memlint-run` 17.1 s. Slow is the safe side, and only Michael moves a file slow → fast
(`decisions/2026-11-03-suite-tiers`); `session-gate-driver` (21.5 s in the kept run of 2026-11-05, declared slow by
its session) is the third such file.

**The tiers' table lists every check file (Decision 3, item 3)**: 98 rows, under the new names, each row's tier its
file's header (the table in `decisions/2026-11-03-suite-tiers`, edited in place: it is the live assignment).

**Nothing put back into the fast tier (Decision 13).** The thin-evidence escalation and the lane's exit after refused
sessions stay with the slow files that run them; no stub start was added for them.

**No push-down but memlint's (Decision 14).**

**The real 64 MB scope check says what it got when red (Decision 15)**: the wrapper's exit status, what it printed
against what was wanted, the units left, the kept stderr, each line indented so none reads as a PASS or FAIL. Its
assertion is byte for byte what it was. Seen once on a forced red (a throwaway copy at 512 MB): `the wrapper exited 0
…, printed <rc=0 peak=268 | capped> (wanted <rc=137 peak=64 | capped>)`.

**Two check names changed with the file name they hold** (the Finding's two; `00-unit-tier` and `00-unit` are
`unit-tier` in each). Every other name is what it was.

**`tests/tools/coverage.mjs` reads `unit-tier` as a check file's set**, as it read `00-unit-tier` (unit test:
`coverage.mjs: the unit tier's check file (unit-tier) is a check file's set, never a unit row, as 00-unit-tier was`).
A `tests/unit/tier.test.mjs` would write its own set over the check file's (`coverage.sh` names a unit file's set
`unit-<name>`): no such file exists. `tests/tools/mutants.mjs`'s `pick` had the same prefix rule (the review's
finding): it would have left the unit tier's lines out of a sample's pool and the unit tier out of the files run
against a mutant, so a mutant only unit tests catch would have read as survived. It reads `unit-tier.txt` as a check
file's set now (its unit test first, red with `pool: 0 lines`).

**The name lint runs with `suite-runner`, in the slow tier** (*default*: beside the tier lint): a new file whose name
collides is red at verify, not in the session's fast gate.

**What follows a rename, and what does not.** Every live mention has the new name: `CHECK_KEY_MAP`
(`CLAUDE.md:memlint-self:memory-prompts:suite-length:night-words`) and the key map lint's expectation and fixtures,
comments in check files, unit tests, stubs and tools, sample runner output in unit tests, `README.md`,
`docs/architecture.md`, `templates/project/config.sh`, and three lines of `CLAUDE.md` (file names only). History keeps
the old names: `journal/` (but the tiers' table), `findings-and-research/` (the coverage sets are named for the files
as they were), `docs/specs/`, `docs/plans/`, `.harness/runs/`, `evals/`, `tests/split.sh` (the record of the first
split) and `tests/fixtures/check-agent-harness.txt` (a recording of the runner's output, dated on its first line). A
run's `flakes.jsonl` from before the shape names the files as they were: the table below is the bridge.

Defaults against the spec and the procedure: splits only where no replay is needed (the spec weighs a replay against
"the file's gain in parallel slot time", which is none while the slots are packed); two new check names in the runner's
file and one new unit test, where the procedure expected one new name; two check names changed, where it expected none;
the tiers' table carries the new names though it sits in a decision file; 15 memlint cases moved, not 16.

## The numbers

| measure | after the trim (`74e3e6d`) | after the shape | the command |
|---|---:|---:|---|
| check names (the full fixture) | 1,489 | 1,492 | `wc -l < tests/fixtures/check-names.txt` |
| fast names | 726 | 705 | `wc -l < tests/fixtures/check-names-fast.txt` |
| unit tests | 228 | 244 | the unit tier's `tests` line |
| checks in fast check files | 498 | 461 | fast names less unit tests |
| checks in slow check files | 763 | 787 | names less fast names |
| check files (fast, slow) | 95 (55, 40) | 98 (56, 42) | `awk 'FNR == 2' tests/checks/*.sh \| sort \| uniq -c` |
| lines that start a stub run | 199 in 63 files | 199 in 65 files | S1's `grep` (the findings file) |
| the fast tier, 4 jobs | 727/727 in 103.3 s | 706/706 in 91.9 s and 100.3 s (two runs) | `bash tests/run.sh --tier fast` (the bound is 180 s) |

**The full fixture**: three names added (the runner's two checks, the coverage tool's unit test), two changed, none
removed. **The fast fixture**, 726 → 705: 29 names left with the two files that are slow now (`node-memo` 26,
`memlint-run` 3), 7 came with the two files cut out of file 15 (`weekly-budget` 3, `gc-tmux` 4), 1 is the new unit
test, and one of the two changed names is fast. The 15 memlint names stay fast as unit tests. The full suite's last
line, wall and CPU are in the PR's body (the suite runs once, last, after this file is written).

## The names, old → new

The last column says what a file changed beyond its name: nothing (byte for byte), or the lines the
reference rewrite and this session changed in it.

| was | is | tier | changed beyond the name |
|---|---|---|---|
| `00-unit-tier` | `unit-tier` | fast | the unit tier's path; comments |
| `03-harness-parked-pure-report` | `notify-body-cap` | fast | – |
| `06-test-counts-pure-r1` | `testcount-fixtures` | fast | – |
| `07-step-lint-pure-r3` | `step-lint` | fast | – |
| `08-scope-sh-l1-02-run-capped-services-gc-scratch` | `run-scopes-services-gc` | slow | the 64 MB scope check's red prints what it got |
| `09-replay-set-e2-every` | `replay-set` | fast | – |
| `10-harness-eval-run-e2` | `eval-run` | slow | – |
| `11-deploy-guards-pure-and` | `vercel-guard` | fast | – |
| `12-journal-pure-e4-entrys` | `journal-entries` | fast | – |
| `13-run-2-michael-sets-desk` | `park-desk` | slow | – |
| `14-run-2b-stop-records` | `stop-records` | slow | – |
| `15-run-4-same-but-queue-parked-debrief-tmux` | `queue-debrief` (slow), `weekly-budget` (fast), `gc-tmux` (fast) | | the cut: its last two sections are the two new files |
| `16-run-6-limit-cuts` | `limit-cuts` | slow | – |
| `19-run-9e-deadline-verifies` | `deadline-verifies` | slow | – |
| `20-sync-live-checkout-level` | `sync` | fast | – |
| `21-run-11-verify-refused` | `verify-refused` | fast | – |
| `22-run-12-session-claims` | `claim-reverted` | fast | – |
| `23-run-12b-nothing-sets` | `merge-policy-default` | fast | – |
| `24-run-13-verify-and` | `verify-retro-read-only` | fast | – |
| `25-run-13b-bs-entry` | `entry-not-json` | fast | – |
| `26-run-13c-stale-green` | `stale-green` | fast | comments naming other files |
| `27-run-14-v2-style` | `merge-v2-tags` | fast | – |
| `28-run-14d-harness-merge` | `merge-legacy-record` | fast | – |
| `29-run-15-resumed-run` | `resume-reloads-config` | fast | – |
| `30-run-15b-run-that` | `resume-before-list` | fast | – |
| `31-tmux-l3-03-when` | `tmux-window-end` | fast | – |
| `32-l5-queue-runner-re` | `queue-runner-config` | slow | – |
| `33-suite-runner` | `suite-runner` | slow | the unit tier's path; the two new checks; comments |
| `34-check-key` | `check-key` | fast | – |
| `35-backlog-pure-m1` | `backlog-cli` | fast | – |
| `36-run-16-retro-backlog` | `retro-backlog` | slow | comments naming other files |
| `37-memory-prompts-m2` | `memory-prompts` | slow | – |
| `38-run-17-gotchas-and-pack-m3` | `gotchas-pack` | slow | – |
| `39-memlint-m4` | `memlint-self` (fast), `memlint-run` (slow), 15 tests in `tests/unit/memlint.test.mjs` | | the split in three |
| `40-run-18-test-counts-m5` | `test-count-source` | slow | – |
| `41-run-19-review-gate-m6` | `review-gate-model` | slow | – |
| `42-run-20-review-gate-rounds-m6` | `review-gate-rounds` | slow | – |
| `43-lanes-scheduler` | `lanes-scheduler` | fast | – |
| `44-lanes-record` | `lanes-record-lock` | slow | – |
| `45-lanes-run` | `lanes-run` | slow | comments naming other files |
| `46-lanes-continue` | `lanes-continue` | slow | – |
| `47-lanes-two` | `lanes-two` | slow | – |
| `48-lanes-rebase` | `lanes-rebase` | slow | – |
| `49-lanes-slots` | `lanes-slots` | slow | comments naming other files |
| `50-lanes-record-pr` | `lanes-record-pr` | slow | – |
| `51-view-pure` | `view-formatter` | fast | – |
| `52-status-json` | `status-json` | fast | – |
| `53-status-view` | `status-view` | fast | comments naming other files |
| `54-status-card` | `status-card` | fast | – |
| `55-queue-view` | `queue-view` | fast | – |
| `56-status-review` | `status-review` | fast | comments naming other files |
| `57-inbox` | `inbox` | fast | – |
| `58-needs-record` | `needs-record` | fast | comments naming other files |
| `59-needs-cards` | `needs-cards` | fast | – |
| `60-needs-driver` | `needs-driver` | slow | – |
| `61-needs-git` | `needs-git` | slow | comments naming other files |
| `62-needs-readers` | `needs-readers` | fast | comments naming other files |
| `63-question-locations` | `question-locations` | fast | – |
| `64-needs-review` | `needs-review` | fast | comments naming other files |
| `65-project-names` | `project-names` | fast | – |
| `66-record-after-gc` | `record-after-gc` | fast | – |
| `67-gc-units` | `gc-units` | fast | – |
| `68-show` | `show` | fast | comments naming other files |
| `69-same-project-starts` | `same-project-starts` | fast | – |
| `70-overlap` | `overlap` | slow | – |
| `71-tty-views` | `tty-views` | fast | – |
| `72-u3-review` | `u3-review` | slow | – |
| `73-check-rerun` | `check-rerun` | fast | – |
| `74-flakes-run` | `flakes-run` | slow | – |
| `75-merge-sorted` | `merge-sorted` | fast | – |
| `75-suite-tools` | `suite-tools` | fast | – |
| `76-entries-survive` | `entries-survive` | slow | – |
| `76-resolve-session` | `resolve-session` | slow | comments naming other files |
| `77-leftovers` | `leftovers` | slow | – |
| `77-resolve-fallbacks` | `resolve-fallbacks` | slow | comments naming other files |
| `78-continue-busy` | `continue-busy` | fast | – |
| `78-needs-questions` | `needs-questions` | slow | – |
| `79-suite-length` | `suite-length` | slow | one check's name and assertion (`00-unit` → `unit-tier`); comments |
| `80-red-marker` | `red-marker` | slow | comments naming other files |
| `81-partial-key` | `partial-key` | fast | the key map's string; comments |
| `82-key-map-lint` | `key-map-lint` | fast | the key map's string; comments |
| `83-spec-must-exist` | `spec-must-exist` | fast | – |
| `84-node-memo` | `node-memo` | slow | its tier: fast → slow |
| `85-suite-runs` | `suite-runs` | fast | – |
| `86-fast-gate` | `session-gate-check` | fast | comments naming other files |
| `87-fast-gate-run` | `session-gate-driver` | slow | comments naming other files |
| `88-origin-after-gc` | `origin-after-gc` | slow | – |
| `88-origin-outage` | `origin-outage` | slow | – |
| `89-night-words` | `night-words` | fast | comments naming other files |
| `89-no-deadline` | `no-deadline` | slow | comments naming other files |
| `90-fix-rounds` | `fix-rounds` | slow | comments naming other files |
| `91-resident-helper` | `resident-helper-ask` | fast | comments naming other files |
| `92-resident-helper-run` | `resident-helper-run` | slow | comments naming other files |
| `93-xtrace` | `xtrace` | fast | the unit tier's path; a check's name; comments |
| `94-mutants-runner` | `mutants-runner` | fast | – |

## Rejected

- **Keeping the numbers, or a number per topic**: they order nothing, and a name a person has to look up is the
  history the spec asks to drop. What they did do (keep names apart) the lint does now, by rule.
- **An exact match in the runner** (a name that is a whole file name picks that file only) instead of the name rule:
  it changes what `tests/run.sh <name>` means for every caller, and the spec keeps the substring match.
- **The spec's four-way cut of file 15, and cuts of files 08 and 13**: each part would replay the runs it reads (a
  stub start or more per part), for no wall time.
- **Naming the unit tier's file something that does not start `unit-`** to spare the coverage tool a line:
  `unit-tier` is what everyone calls it, and the tool's rule was the fragile part.
- **`memlint-run` and `node-memo` fast because they are under 30 s today**: Decision 3 is Michael's, slow → fast is
  his to say, and `node-memo` has been on both sides of the line (27.6, 31.0, 31.5, 28.0, 27.9 s).
- **Rewriting history** (decision files, findings, specs, the coverage sets' file names) to the new names: a record
  says what was true when it was written; the table above reads it.
- **Recording `tests/fixtures/check-agent-harness.txt` again** with the new names and line: it is a dated sample of
  the runner's output for the test-count rule, which reads its last line only.
- **A fast check again for the two lane paths the trim took out of the fast tier** (Decision 13, (b)): the tiers
  assign by time, and the purity session's unit tests of the lane's verdict bring the thin-evidence branch back
  without a stub start.
