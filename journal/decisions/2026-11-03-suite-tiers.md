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
| `unit-tier` | fast | – | the unit tier (spec: a name the unit tier prints is fast); lc-4-solo timed its two rows then, `01-scheduler-pure` 0.0 s and `02-notifications-pure` 0.1 s |
| `notify-body-cap` | fast | 0.2 | ≤ 30 s |
| `testcount-fixtures` | fast | 0.6 | ≤ 30 s |
| `step-lint` | fast | 0.6 | ≤ 30 s |
| `replay-set` | fast | 0.2 | ≤ 30 s |
| `vercel-guard` | fast | 0.2 | ≤ 30 s |
| `journal-entries` | fast | 2.2 | ≤ 30 s |
| `sync` | fast | 0.4 | ≤ 30 s |
| `verify-refused` | fast | 16.7 | ≤ 30 s |
| `claim-reverted` | fast | 17.3 | ≤ 30 s |
| `merge-policy-default` | fast | 15.1 | ≤ 30 s |
| `verify-retro-read-only` | fast | 14.9 | ≤ 30 s |
| `entry-not-json` | fast | 14.9 | ≤ 30 s |
| `stale-green` | fast | 10.5 | ≤ 30 s |
| `merge-v2-tags` | fast | 18.3 | ≤ 30 s |
| `merge-legacy-record` | fast | 17.7 | ≤ 30 s |
| `resume-reloads-config` | fast | 22.3 | ≤ 30 s |
| `resume-before-list` | fast | 17.3 | ≤ 30 s |
| `tmux-window-end` | fast | 5.0 | ≤ 30 s |
| `check-key` | fast | 16.8 | ≤ 30 s |
| `backlog-cli` | fast | 1.6 | ≤ 30 s |
| `memlint-self` | fast | 0.0 (2026-11-06) | the one check of `39-memlint-m4` that lints this checkout (the regression it caught twice was this check's); timed once on 2026-11-06, alone, ≤ 30 s |
| `lanes-scheduler` | fast | 1.4 | ≤ 30 s |
| `view-formatter` | fast | 1.0 | ≤ 30 s |
| `status-json` | fast | 8.3 | ≤ 30 s |
| `status-view` | fast | 10.1 | ≤ 30 s |
| `status-card` | fast | 5.4 | ≤ 30 s |
| `queue-view` | fast | 4.3 | ≤ 30 s |
| `status-review` | fast | 2.9 | ≤ 30 s |
| `inbox` | fast | 15.3 | ≤ 30 s |
| `needs-record` | fast | 4.9 | ≤ 30 s |
| `needs-cards` | fast | 2.5 | ≤ 30 s |
| `needs-readers` | fast | 1.6 | ≤ 30 s |
| `question-locations` | fast | 28.3 | ≤ 30 s |
| `needs-review` | fast | 4.3 | ≤ 30 s |
| `project-names` | fast | 16.8 | ≤ 30 s |
| `record-after-gc` | fast | 15.8 | ≤ 30 s |
| `gc-units` | fast | 0.3 | ≤ 30 s |
| `show` | fast | 18.9 | ≤ 30 s |
| `same-project-starts` | fast | 11.1 | ≤ 30 s |
| `tty-views` | fast | 17.1 | ≤ 30 s |
| `check-rerun` | fast | 3.1 | ≤ 30 s |
| `merge-sorted` | fast | 16.8 | ≤ 30 s |
| `suite-tools` | fast | 28.4 | ≤ 30 s |
| `continue-busy` | fast | 0.5 | ≤ 30 s |
| `partial-key` | fast | 29.1 | ≤ 30 s |
| `key-map-lint` | fast | 1.7 | ≤ 30 s |
| `spec-must-exist` | fast | 18.3 (2026-11-04) | not in lc-4-solo.out: timed once on 2026-11-04, `TEST_JOBS=4 bash tests/run.sh 83` alone, ≤ 30 s |
| `mutants-runner` | fast | 2.5 (2026-11-06) | new with the slim suite's S1: timed once on 2026-11-06, `TEST_JOBS=4 bash tests/run.sh 94-mutants` alone, ≤ 30 s |
| `xtrace` | fast | 20.7 (2026-11-05) | new with the slim suite's S1 (decisions/2026-11-03-suite-coverage): timed once on 2026-11-05, `TEST_JOBS=4 bash tests/run.sh 93-xtrace` alone, ≤ 30 s |
| `suite-runs` | fast | 13.2 (2026-11-04) | not in lc-4-solo.out: timed once on 2026-11-04, `TEST_JOBS=4 bash tests/run.sh 85` alone, ≤ 30 s |
| `session-gate-check` | fast | 3.6 (2026-11-05) | was `86-fast-gate`; no row until the shape: the kept full run of 2026-11-05, `findings-and-research/2026-11-03-resident-helper/suite-after-files.txt`, solo at 4 jobs, ≤ 30 s |
| `night-words` | fast | 0.1 (2026-11-05) | was `89-night-words`; no row until the shape: the same run, ≤ 30 s |
| `resident-helper-ask` | fast | 14.7 (2026-11-05) | was `91-resident-helper`; no row until the shape: the same run, ≤ 30 s |
| `weekly-budget` | fast | 2.9 (2026-11-06) | cut out of file 15 by the shape (it reads no run of that file); timed once on 2026-11-06, alone, ≤ 30 s |
| `gc-tmux` | fast | 0.5 (2026-11-06) | cut out of file 15 by the shape; timed once on 2026-11-06, alone, ≤ 30 s |
| `memlint-run` | fast | 17.1 (2026-11-06) | `39-memlint-m4`'s two stub runs; slow by Michael's word (Decision 3 of the redesign's dispatch list, 2026-11-05) while the whole memlint file was over the line; fast since 2026-11-06 by Michael's word (Decision 18, the process session), as the rule has it |
| `node-memo` | slow | 27.6 (2026-11-04); 28.0, 27.9 (2026-11-06) | moved fast → slow by Michael's word (Decision 3 of the redesign's dispatch list, 2026-11-05: 31.5 s there, 31.0 s in the kept full run of 2026-11-05, `findings-and-research/2026-11-03-resident-helper/suite-after-files.txt`, solo at 4 jobs); under the line in both solo runs of 2026-11-06 |
| `run-scopes-services-gc` | slow | 202.8 | over 30 s |
| `eval-run` | slow | 58.9 | over 30 s |
| `park-desk` | slow | 205.3 | over 30 s |
| `stop-records` | slow | 54.3 | over 30 s |
| `queue-debrief` | slow | 232.2; 129.7 (2026-11-06, after the cut) | over 30 s; its last two sections are `weekly-budget` and `gc-tmux` since the shape |
| `limit-cuts` | slow | 46.5 | over 30 s |
| `deadline-verifies` | slow | 92.2 | over 30 s |
| `queue-runner-config` | slow | 58.7 | over 30 s |
| `suite-runner` | slow | 25.5; 51.7, 51.7 (2026-11-04) | moved fast → slow by T1-02's two solo `--tier fast` runs: over 30 s in both (its `TEST_FILE_TIMEOUT` fixtures each wait out the runner's 10 s KILL grace) |
| `retro-backlog` | slow | 109.4 | over 30 s |
| `memory-prompts` | slow | 62.6 | over 30 s |
| `gotchas-pack` | slow | 44.2 | over 30 s |
| `test-count-source` | slow | 47.3 | over 30 s |
| `review-gate-model` | slow | 44.6 | over 30 s |
| `review-gate-rounds` | slow | 70.2 | over 30 s |
| `lanes-record-lock` | slow | 34.4 | over 30 s |
| `lanes-run` | slow | 86.2 | over 30 s |
| `lanes-continue` | slow | 123.7 | over 30 s |
| `lanes-two` | slow | 96.8 | over 30 s |
| `lanes-rebase` | slow | 102.6 | over 30 s |
| `lanes-slots` | slow | 54.6 | over 30 s |
| `lanes-record-pr` | slow | 68.0 | over 30 s |
| `needs-driver` | slow | 36.1 | over 30 s |
| `needs-git` | slow | 56.0 | over 30 s |
| `overlap` | slow | 33.8 | over 30 s |
| `u3-review` | slow | 33.6 | over 30 s |
| `flakes-run` | slow | 64.8 | over 30 s |
| `entries-survive` | slow | 131.4 | over 30 s |
| `resolve-session` | slow | 35.4 | over 30 s |
| `leftovers` | slow | 58.4 | over 30 s |
| `resolve-fallbacks` | slow | 120.9 | over 30 s |
| `needs-questions` | slow | 70.1 | over 30 s |
| `suite-length` | slow | 49.5 | over 30 s |
| `red-marker` | slow | 55.8 | over 30 s |
| `session-gate-driver` | fast | 21.5 (2026-11-05) | was `87-fast-gate-run`; no row until the shape. Declared slow by its session (T2-02); under the line in the same run; fast since 2026-11-06 by Michael's word (Decision 18, the process session) |
| `origin-after-gc` | slow | 81.2 (2026-11-05) | was `88-origin-after-gc`; no row until the shape: the same run, over 30 s |
| `origin-outage` | slow | 170.1 (2026-11-05) | was `88-origin-outage`; no row until the shape: the same run, over 30 s |
| `no-deadline` | slow | 37.7 (2026-11-05) | was `89-no-deadline`; no row until the shape: the same run, over 30 s (50–67 s when its session timed it, `decisions/2026-11-04-no-default-end-time`) |
| `fix-rounds` | slow | 64.8 (2026-11-05) | was `90-fix-rounds`; no row until the shape: the same run, over 30 s |
| `resident-helper-run` | slow | 72.0 (2026-11-05) | was `92-resident-helper-run`; no row until the shape: the same run, over 30 s |

Updated in place 2026-11-04: 33-suite-runner 51.7 s, 51.7 s (T1-02's two solo `TEST_JOBS=4 bash tests/run.sh --tier fast`
runs, walls 161.9 s and 161.1 s): moved to slow, its header and the fast fixture. Over 30 s in both too:
`39-memlint-m4` 39.8 s, 39.6 s, kept fast (*default*): it is fast by the spec's named exception, not by the 30 s line,
and its time is below the 42.1 s it was placed at.

Updated in place 2026-11-04 (T1-04's review): the full run's fast-list check, the hint's real path and the stricter
option parsing above; line 2 is read exactly (`IFS= read`, so a trailing blank refuses it, as the lint's `sed -n 2p`
does), and a non-file `*.sh` (a directory, a FIFO) is refused without being read.

Updated in place 2026-11-06 (the trim, `decisions/2026-11-03-trim`): four fast files are gone and their rows with them.
`04-render-pure-sections-go`, `05-metrics-pure-tokens-cache` and `18-run-9c-refused-sessions` are unit tests now (the
names unchanged, still fast); `17-run-8-thin-verify`'s one check moved into `61-needs-git`, so its name left the fast
fixture. The lint's three lines are one check of `33-suite-runner` now (two were checks of their own).

Updated in place 2026-11-06 (the shape, `decisions/2026-11-05-suite-shape`): the table lists every check file, under the
name the shape gave it; the text above and the two notes before this one name the files as they were, and that
decision has the old → new table. Eleven rows are new: the nine files whose sessions set a header and wrote no row,
and `weekly-budget` and `gc-tmux`, cut out of file 15 (each timed once, alone). `39-memlint-m4` is `memlint-self` (fast),
`memlint-run` (slow) and 15 unit tests. `84-node-memo` is slow as `node-memo`, and `memlint-run` is slow, by Michael's
word (Decision 3 of the redesign's dispatch list, 2026-11-05), not by two timings over the line: alone on 2026-11-06
`node-memo` took 28.0 s and 27.9 s and `memlint-run` 17.1 s. `tests/run.sh`'s per-file line ends `, tier <fast|slow>`.

Updated in place 2026-11-06 (the process session, Decision 18 of the redesign's dispatch list, Michael): `memlint-run`
(17.1 s alone) and `session-gate-driver` (21.5 s) are fast, as the 30 s rule has them: the reason memlint's stub runs
were slow (the whole file was over the line) went with the shape's split, and the gate's own path through the driver
runs in a coding session's gate again. `node-memo` stays slow: at the line (28 s alone, 31 s inside a full run), it
would change sides with the load. Two header lines and 15 names into the fast fixture.
