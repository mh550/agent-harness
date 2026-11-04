# The suite's tiers: every check file declares `fast` or `slow` on line 2, and `tests/run.sh --tier` runs one tier

*(2026-11-04, run `agent-harness-2026-11-04`, T1-01 (the header, the refusal, `--tier`, the assignment); T1-02 the
fast fixture and per-tier conformance; spec `docs/specs/2026-11-03-suite-tiers.md` T1; plan
`docs/plans/2026-11-03-test-suite-redesign.md` phase 3)*

## Finding

The suite is about 805 s solo at 4 jobs and a coding session runs it 1.3–1.7 times, 58 % of lane time
(`findings-and-research/2026-10-29-run-time-budget.md` §2, §4). Its time is lopsided: in
`findings-and-research/2026-10-30-suite-load-curve/lc-4-solo.out` (one solo full run at 4 jobs), 52 files take 30 s
or less (580 slot-s together) and 34 take 33.6 s or more (2,604 slot-s: the long stub runs `15`, `13`, `08`,
`76`, `46`, `77`, …); no file falls between 29.1 s (`81-partial-key`) and 33.6 s (`72-u3-review`). The runner knew
no grouping but a name match, so a session could only run all of it or guess a subset. Of 85 reds the sessions hit,
35 were in the session's own check file, 38 in a file selected by name and 4 missed by that selection, two of them
`39-memlint-m4` (budget §7).

## Choice

- **The header.** Line 2 of every `tests/checks/*.sh`, right after the shebang, is `# tier: fast` or `# tier: slow`,
  exactly. `tests/run.sh` reads line 2 of every file in its directory (a `TEST_CHECKS` directory too) before anything
  runs, one reader for the refusal and the selection.
- **The refusal** (fail-closed: a file in no tier would be in no gate). Any file without the header, or with a tier the
  runner doesn't know: `no tier header: <path>` per file, in name order, then exit 2, with no file run and no
  scratch made. The whole run is refused, a name subset or a `--tier` run included (*default*: the refusal looks at
  the directory, not only the selected files, so a headerless file is caught by the first run of any kind).
- **`--tier fast|slow`**, before any names: only that tier's files, and with names only those of them whose names
  match. Without `--tier`, every file as before. `--repeat <n>` combines with it in either order, and with `--tier`
  it needs no name: the whole tier n times (*default*). Any other tier word: the usage line, exit 2. The `slowest:`
  line ends `, tier fast`, `, tier slow` or `, tier all` (no `--tier`). Until T1-02's per-tier fixture, a `--tier`
  run's conformance is a subset's (none new, none doubled).
- **The 30 s rule.** **fast** = `00-unit-tier` + every file whose solo slot time at 4 jobs in lc-4-solo.out was 30 s
  or less + `39-memlint-m4` (42.1 s, a real regression caught outside its own feature twice). **slow** = the rest. A
  file lc-4-solo.out never timed is placed by one `TEST_JOBS=4 bash tests/run.sh <file>` run against the same line
  (*default*: alone, as the spec says, so it reads a little low beside a loaded slot; `84-node-memo` at 27.6 s is the
  closest to the line and is the first to re-time). 55 fast files and 33 slow (the table below).
- **Who may move a file.** A session moves a file **fast → slow** when it took over 30 s in two solo runs, with both
  times in one `Updated in place <date>: <file> <t1> s, <t2> s` line under the table. **Slow → fast** only Michael,
  or a session whose spec says so, with a solo time under 30 s and the file absent from the flaker rows of the last
  three runs' `flakes.jsonl`. A new check file declares its tier by the same rule (*default*: one timing of it,
  `TEST_JOBS=4 bash tests/run.sh <file>`); a session that adds a stub run to a fast file re-times it. The runner's own
  check (`tests/checks/33-suite-runner.sh`) lints the fixtures against the headers from T1-02 on.
- **Not decided here:** what stands on which tier (`check.sh --fast`, the driver's gate) is T2's,
  `decisions/2026-11-03-fast-gate`.

## Rejected

- **A tier list in a file beside the checks** (a `tiers.txt`): a second place to keep in step with the files; the
  header travels with the file, a rename keeps it, and a new file without one is refused at once.
- **An untagged file defaulting to slow or fast**: a default tier lets a file into, or out of, a gate without anyone
  choosing; refusing costs one line per new file.
- **Placing files by their check count or by name** (`run-*` slow): the counts don't track time (`08` has 125 checks
  in 203 s, `26-run-13c` 1 in 10.5 s) and neither do the names (`29-run-15` is 22 s, `70-overlap` 34 s).
- **A line other than 30 s**: the measured gap between 29.1 s and 33.6 s is where the line costs nothing to draw;
  the fast tier's prediction (about 150 s at 4 jobs, under the spec's 180 s target) holds with it.

## The table

Solo slot time: `findings-and-research/2026-10-30-suite-load-curve/lc-4-solo.out` (one solo full run, 4 jobs), or
the one 2026-11-04 timing where that output has none.

| File | Tier | Solo slot time (s) | Reason |
|---|---|---|---|
| `00-unit-tier` | fast | – | the unit tier (spec: a name the unit tier prints is fast); lc-4-solo timed its two rows then, `01-scheduler-pure` 0.0 s and `02-notifications-pure` 0.1 s |
| `03-harness-parked-pure-report` | fast | 0.2 | ≤ 30 s |
| `04-render-pure-sections-go` | fast | 0.1 | ≤ 30 s |
| `05-metrics-pure-tokens-cache` | fast | 0.3 | ≤ 30 s |
| `06-test-counts-pure-r1` | fast | 0.6 | ≤ 30 s |
| `07-step-lint-pure-r3` | fast | 0.6 | ≤ 30 s |
| `09-replay-set-e2-every` | fast | 0.2 | ≤ 30 s |
| `11-deploy-guards-pure-and` | fast | 0.2 | ≤ 30 s |
| `12-journal-pure-e4-entrys` | fast | 2.2 | ≤ 30 s |
| `17-run-8-thin-verify` | fast | 16.7 | ≤ 30 s |
| `18-run-9c-refused-sessions` | fast | 15.4 | ≤ 30 s |
| `20-sync-live-checkout-level` | fast | 0.4 | ≤ 30 s |
| `21-run-11-verify-refused` | fast | 16.7 | ≤ 30 s |
| `22-run-12-session-claims` | fast | 17.3 | ≤ 30 s |
| `23-run-12b-nothing-sets` | fast | 15.1 | ≤ 30 s |
| `24-run-13-verify-and` | fast | 14.9 | ≤ 30 s |
| `25-run-13b-bs-entry` | fast | 14.9 | ≤ 30 s |
| `26-run-13c-stale-green` | fast | 10.5 | ≤ 30 s |
| `27-run-14-v2-style` | fast | 18.3 | ≤ 30 s |
| `28-run-14d-harness-merge` | fast | 17.7 | ≤ 30 s |
| `29-run-15-resumed-run` | fast | 22.3 | ≤ 30 s |
| `30-run-15b-run-that` | fast | 17.3 | ≤ 30 s |
| `31-tmux-l3-03-when` | fast | 5.0 | ≤ 30 s |
| `33-suite-runner` | fast | 25.5 | ≤ 30 s |
| `34-check-key` | fast | 16.8 | ≤ 30 s |
| `35-backlog-pure-m1` | fast | 1.6 | ≤ 30 s |
| `39-memlint-m4` | fast | 42.1 | over the line, fast by the spec: it caught a real regression outside its own feature twice (budget §7: the Gotchas cap) |
| `43-lanes-scheduler` | fast | 1.4 | ≤ 30 s |
| `51-view-pure` | fast | 1.0 | ≤ 30 s |
| `52-status-json` | fast | 8.3 | ≤ 30 s |
| `53-status-view` | fast | 10.1 | ≤ 30 s |
| `54-status-card` | fast | 5.4 | ≤ 30 s |
| `55-queue-view` | fast | 4.3 | ≤ 30 s |
| `56-status-review` | fast | 2.9 | ≤ 30 s |
| `57-inbox` | fast | 15.3 | ≤ 30 s |
| `58-needs-record` | fast | 4.9 | ≤ 30 s |
| `59-needs-cards` | fast | 2.5 | ≤ 30 s |
| `62-needs-readers` | fast | 1.6 | ≤ 30 s |
| `63-question-locations` | fast | 28.3 | ≤ 30 s |
| `64-needs-review` | fast | 4.3 | ≤ 30 s |
| `65-project-names` | fast | 16.8 | ≤ 30 s |
| `66-record-after-gc` | fast | 15.8 | ≤ 30 s |
| `67-gc-units` | fast | 0.3 | ≤ 30 s |
| `68-show` | fast | 18.9 | ≤ 30 s |
| `69-same-project-starts` | fast | 11.1 | ≤ 30 s |
| `71-tty-views` | fast | 17.1 | ≤ 30 s |
| `73-check-rerun` | fast | 3.1 | ≤ 30 s |
| `75-merge-sorted` | fast | 16.8 | ≤ 30 s |
| `75-suite-tools` | fast | 28.4 | ≤ 30 s |
| `78-continue-busy` | fast | 0.5 | ≤ 30 s |
| `81-partial-key` | fast | 29.1 | ≤ 30 s |
| `82-key-map-lint` | fast | 1.7 | ≤ 30 s |
| `83-spec-must-exist` | fast | 18.3 (2026-11-04) | not in lc-4-solo.out: timed once on 2026-11-04, `TEST_JOBS=4 bash tests/run.sh 83` alone, ≤ 30 s |
| `84-node-memo` | fast | 27.6 (2026-11-04) | not in lc-4-solo.out: timed once on 2026-11-04, `TEST_JOBS=4 bash tests/run.sh 84` alone, ≤ 30 s |
| `85-suite-runs` | fast | 13.2 (2026-11-04) | not in lc-4-solo.out: timed once on 2026-11-04, `TEST_JOBS=4 bash tests/run.sh 85` alone, ≤ 30 s |
| `08-scope-sh-l1-02-run-capped-services-gc-scratch` | slow | 202.8 | over 30 s |
| `10-harness-eval-run-e2` | slow | 58.9 | over 30 s |
| `13-run-2-michael-sets-desk` | slow | 205.3 | over 30 s |
| `14-run-2b-stop-records` | slow | 54.3 | over 30 s |
| `15-run-4-same-but-queue-parked-debrief-tmux` | slow | 232.2 | over 30 s |
| `16-run-6-limit-cuts` | slow | 46.5 | over 30 s |
| `19-run-9e-deadline-verifies` | slow | 92.2 | over 30 s |
| `32-l5-queue-runner-re` | slow | 58.7 | over 30 s |
| `36-run-16-retro-backlog` | slow | 109.4 | over 30 s |
| `37-memory-prompts-m2` | slow | 62.6 | over 30 s |
| `38-run-17-gotchas-and-pack-m3` | slow | 44.2 | over 30 s |
| `40-run-18-test-counts-m5` | slow | 47.3 | over 30 s |
| `41-run-19-review-gate-m6` | slow | 44.6 | over 30 s |
| `42-run-20-review-gate-rounds-m6` | slow | 70.2 | over 30 s |
| `44-lanes-record` | slow | 34.4 | over 30 s |
| `45-lanes-run` | slow | 86.2 | over 30 s |
| `46-lanes-continue` | slow | 123.7 | over 30 s |
| `47-lanes-two` | slow | 96.8 | over 30 s |
| `48-lanes-rebase` | slow | 102.6 | over 30 s |
| `49-lanes-slots` | slow | 54.6 | over 30 s |
| `50-lanes-record-pr` | slow | 68.0 | over 30 s |
| `60-needs-driver` | slow | 36.1 | over 30 s |
| `61-needs-git` | slow | 56.0 | over 30 s |
| `70-overlap` | slow | 33.8 | over 30 s |
| `72-u3-review` | slow | 33.6 | over 30 s |
| `74-flakes-run` | slow | 64.8 | over 30 s |
| `76-entries-survive` | slow | 131.4 | over 30 s |
| `76-resolve-session` | slow | 35.4 | over 30 s |
| `77-leftovers` | slow | 58.4 | over 30 s |
| `77-resolve-fallbacks` | slow | 120.9 | over 30 s |
| `78-needs-questions` | slow | 70.1 | over 30 s |
| `79-suite-length` | slow | 49.5 | over 30 s |
| `80-red-marker` | slow | 55.8 | over 30 s |
