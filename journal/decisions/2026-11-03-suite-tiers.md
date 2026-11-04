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
- **`--tier fast|slow`**, once, before any names (an option after a name, a second `--tier` or `--tier=<t>`: the
  usage line, exit 2): only that tier's files, and with names only those of them whose names
  match. Without `--tier`, every file as before. `--repeat <n>` combines with it in either order, and with `--tier`
  it needs no name: the whole tier n times (*default*). Any other tier word: the usage line, exit 2. The `slowest:`
  line ends `, tier fast`, `, tier slow` or `, tier all` (no `--tier`).
- **Per-tier conformance** (T1-02). `tests/fixtures/check-names.txt` stays the full list; `check-names-fast.txt` beside
  it, `LC_ALL=C` sorted, holds the names the fast files print (the unit tier's included). A `--tier fast` run checks
  missing, new and doubled against the fast list (a deleted fast check turns the fast run red: `passes` will stand on
  it); a `--tier slow` run against the full list minus the fast one (`comm -23`); a run without `--tier` against the
  full list as before; a names subset, with or without `--tier`, new and doubled only (against its tier's list). The
  line is `conformance: every check of the <tier> tier ran, none new or doubled` for a tier run, the old line for a
  full one; `HARNESS_FAILED=` is unchanged. A `TEST_CHECKS` directory's fast list is its own `check-names-fast.txt`;
  a missing one is empty (*default*: fail-closed, every name of a `--tier fast` run is then new). A `new` name's line
  names the fixture the run compared, by its real path (a `TEST_CHECKS` directory's own), and the fix for a misfiled
  name (`…, and to check-names.txt if it isn't there` for a fast run, `…, and drop it from check-names-fast.txt if it
  is there` for a slow). A full run also holds the fast list to the names the fast files printed, both ways
  (`in the fast fixture, not printed by a fast file:` and `printed by a fast file, not in the fast fixture:` under
  the full conformance line, red): a misfiled name is red in the run verify and merge stand on, not first in a later
  session's fast run (T1-04's review; a `TEST_CHECKS` directory without a fast list has no fast tier to check).
- **The 30 s rule.** **fast** = `00-unit-tier` + every file whose solo slot time at 4 jobs in lc-4-solo.out was 30 s
  or less + `39-memlint-m4` (42.1 s, a real regression caught outside its own feature twice). **slow** = the rest. A
  file lc-4-solo.out never timed is placed by one `TEST_JOBS=4 bash tests/run.sh <file>` run against the same line
  (*default*: alone, as the spec says, so it reads a little low beside a loaded slot; `84-node-memo` at 27.6 s is the
  closest to the line and is the first to re-time). 55 fast files and 33 slow (the table below; 54 and 34 since T1-02 moved `33-suite-runner`).
- **Who may move a file.** A session moves a file **fast → slow** when it took over 30 s in two solo runs, with both
  times in one `Updated in place <date>: <file> <t1> s, <t2> s` line under the table. **Slow → fast** only Michael,
  or a session whose spec says so, with a solo time under 30 s and the file absent from the flaker rows of the last
  three runs' `flakes.jsonl`. A new check file declares its tier by the same rule (*default*: one timing of it,
  `TEST_JOBS=4 bash tests/run.sh <file>`); a session that adds a stub run to a fast file re-times it. The runner's own
  check (`tests/checks/33-suite-runner.sh`) lints the fixtures against the headers: every file has a header, every
  fast name is in the full list, and no fast name's text is in a slow file's source without being in a fast one's
  (*default*: a name belongs to the files whose source holds it, `grep -F`; 1,134 of 1,170 names are literal there,
  and one built at run time is caught by the fast run's own conformance instead). The lint runs in every run of the
  slow tier and the full suite, `33-suite-runner` being slow since T1-02's re-timing.
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
| `33-suite-runner` | slow | 25.5; 51.7, 51.7 (2026-11-04) | moved fast → slow by T1-02's two solo `--tier fast` runs: over 30 s in both (its `TEST_FILE_TIMEOUT` fixtures each wait out the runner's 10 s KILL grace) |
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

Updated in place 2026-11-04: 33-suite-runner 51.7 s, 51.7 s (T1-02's two solo `TEST_JOBS=4 bash tests/run.sh --tier fast`
runs, walls 161.9 s and 161.1 s): moved to slow, its header and the fast fixture. Over 30 s in both too:
`39-memlint-m4` 39.8 s, 39.6 s, kept fast (*default*): it is fast by the spec's named exception, not by the 30 s line,
and its time is below the 42.1 s it was placed at.

Updated in place 2026-11-04 (T1-04's review): the full run's fast-list check, the hint's real path and the stricter
option parsing above; line 2 is read exactly (`IFS= read`, so a trailing blank refuses it, as the lint's `sed -n 2p`
does), and a non-file `*.sh` (a directory, a FIFO) is refused without being read.
