# What each check file runs, and which checks catch nothing: the suite's coverage map and mutation sample (2026-11-05)

*(The slim suite's S1, built by hand on 2026-11-05/06 (`docs/plans/2026-11-05-slim-suite-by-hand.md`); spec
`docs/specs/2026-11-03-slim-suite.md` S1-01 and S1-02. Base tree `829a7b6`; `lib/` and `bin/` measured as at `7b4176c`
(the base plus the trace switch, `decisions/2026-11-03-suite-coverage`). The raw sets: the directory beside this file,
`2026-11-03-suite-coverage/`. Tools: `tests/tools/coverage.sh`, `coverage.mjs`, `mutants.sh`, `mutants.mjs`.)*

## The before row

Every later session of the slim suite repeats these with the same commands; S4's last run is the after row.

| measure | before S1 (`829a7b6`) | the command |
|---|---:|---|
| check names (the full fixture) | 1,463 | `wc -l < tests/fixtures/check-names.txt` |
| fast names (the fast tier's fixture) | 692 | `wc -l < tests/fixtures/check-names-fast.txt` |
| unit tests | 196 | `node --test --test-isolation=none tests/unit/*.test.mjs`, its `tests` line |
| check files, fast tier | 57 | `awk 'FNR == 2' tests/checks/*.sh \| sort \| uniq -c` |
| check files, slow tier | 40 | the same |
| lines that start a stub run | 198 in 64 files | `grep -hE '"\$H" start' tests/checks/*.sh \| grep -vcE '^\s*#'` (files: `grep -lE '"\$H" start' tests/checks/*.sh \| wc -l`) |
| full suite, solo: checks | 1464/1464 passed | the solo method, below: the output's last line |
| full suite, solo: wall | 599.4 s at 4 jobs | the runner's `wall … s` line |
| full suite, solo: CPU | 2,108.1 CPU-s (1,081.3 user + 1,026.7 system) | `User time` + `System time` of `time -v` |

The solo method (`harness status` showed RUNNING 0 and QUEUED 0, no other suite running):

```bash
systemd-run --user --scope -p MemoryMax=3G /usr/bin/time -v env TEST_JOBS=4 bash tests/run.sh > before.out 2> before.time
```

What the stub-start count counts: every line of a check file, comments left out, that holds `"$H" start` (`$H` is
`bin/harness`, `tests/lib.sh`). It is a line count, not a count of runs: a line in a loop or a function starts more
than one run, and `harness continue`, a start by the queue runner and a start through tmux by another name are not in
it. The three slowest files of the before run: `88-origin-outage` 170.6 s, `15-run-4-same-but-queue-parked-debrief-tmux`
147.3 s, `13-run-2-michael-sets-desk` 121.3 s.

## How the map was measured

One run of the whole suite with every check file's bash traced and its node covered, then one reduction per check file:

```bash
KEEP=1 COVERAGE_RAW=<raw dir> bash tests/tools/coverage.sh <sets dir>      # the suite, once, TEST_JOBS=4, in the solo method's scope
COVERAGE_RAW=<raw dir> bash tests/tools/coverage.sh --reduce <sets dir>   # the sets again from the kept traces (after a reducer fix)
node tests/tools/coverage.mjs tables <sets dir>                           # the five tables below
```

- **bash**: `TEST_XTRACE_DIR=<raw dir>` makes `tests/lib.sh` give each check file `HARNESS_XTRACE=<raw dir>/<check file>`,
  so every harness process the file starts, and the check file's own shell (about 80 check lines source a `lib/` file
  and call into it there), writes `set -x` lines led by `+<source file>:<line>: `. A line counts when its source path
  lies under this checkout's root and is `bin/harness` or a `lib/*.sh`.
- **node**: `NODE_V8_COVERAGE=<raw dir>/<check file>/v8`, node's own per-process coverage (character ranges with
  counts). A line counts when code of it ran; it is marked partial (`~` in the sets) when other code of it did not.
  Code is every character but white space, the punctuation `;,(){}[]`, and the declaration in front of a function no
  process of the check file ever called (`export `, `const f = `, `name: `, which a module's load "runs"). Only lines
  that hold code are kept (no comment, blank line, closing brace or bare `else`).
- **the unit tier** is the check file `00-unit-tier`; its 21 test files were also each run alone
  (`unit-<name>.txt`), as rows of their own that never count as a check file.
- **the run**: 1,489 of 1,489 checks passed under the trace, in 681.5 s wall and 2,563.9 CPU-s (plain: 599.4 s and
  2,108.1 CPU-s, so the trace costs 14 % wall and 22 % CPU, not the two suites of CPU the spec allowed for). The run's
  one red line was the conformance check, on a unit test this session had renamed after adding its name to the
  fixture; the fixture was put right before the commit. A first run, before that rename, passed 1490/1490 in 696.2 s;
  its sets were reduced with an earlier reducer and are not the ones here. The raw traces of a full run are 8.8 GB.
- **the sets here are that run's traces reduced a third time**, after the milestone's review (a reader's hand trace
  of `03-harness-parked-pure-report` and `20-sync-live-checkout-level`) found two defects in the reducer: a node line
  counted as run when only its punctuation or the declaration of a never-called function had (18 of 68 node lines in
  the hand-traced file), and four bash lines read as holding no command. Both are fixed and under unit tests on a
  real trace and a real V8 document (`tests/fixtures/coverage/`).

## What the map says

- **6,885 lines of `lib/` and `bin/` hold code** (3,184 of bash, 3,701 of node). **6,779 of them, 98.5 %, are run by
  at least one check file** (3,108 of bash, 3,671 of node); **106 by none** (76 of bash, 30 of node; Table 5: mostly
  error branches, each listed).
- **3,072 lines, 45 %, are run by 20 or more check files** (Table 4): the stub start's path, which every scenario
  pays. 1,042 lines are run by exactly one check file (Table 1's last column says whose).
- **12 check files run nothing another file does not also run whole** (Table 3). Seven are small files of pure
  functions whose lines the unit tier or a scenario also runs; five are stub-run scenarios of about 2,600 lines each
  that lie inside a larger scenario. That a file's lines lie inside another's says the code it runs is run elsewhere,
  not that its assertions are made elsewhere: S2 reads the assertions.
- **43 of the 98 check files have no line of their own** (Table 1, `only this file` = 0), the 12 among them.
- **The unit tier alone runs 2,625 of the 3,671 node lines the suite runs**; 134 of those are run by no other check file.
- **496 node lines are only ever run in part** (a branch on the line that no check file takes, or a callback in a
  call that ran): `2026-11-03-suite-coverage/_partial-only.txt`.

## The five tables

Generated by `node tests/tools/coverage.mjs tables findings-and-research/2026-11-03-suite-coverage`. A line is a line of
`lib/` or `bin/harness` that holds code; "run" is run by a check file, as the method above counts it.

### Table 1 · per check file: the lines of `lib/` and `bin/` it runs

| check file | tier | bash lines | node lines | all | only this file |
|---|---|---:|---:|---:|---:|
| `13-run-2-michael-sets-desk` | slow | 2075 | 2316 | 4391 | 152 |
| `15-run-4-same-but-queue-parked-debrief-tmux` | slow | 1940 | 2210 | 4150 | 77 |
| `72-u3-review` | slow | 1662 | 2146 | 3808 | 0 |
| `08-scope-sh-l1-02-run-capped-services-gc-scratch` | slow | 1613 | 1917 | 3530 | 34 |
| `78-needs-questions` | slow | 1376 | 2131 | 3507 | 2 |
| `32-l5-queue-runner-re` | slow | 1641 | 1817 | 3458 | 3 |
| `74-flakes-run` | slow | 1418 | 1966 | 3384 | 0 |
| `90-fix-rounds` | slow | 1411 | 1968 | 3379 | 21 |
| `36-run-16-retro-backlog` | slow | 1434 | 1864 | 3298 | 29 |
| `70-overlap` | slow | 1294 | 1980 | 3274 | 8 |
| `60-needs-driver` | slow | 1330 | 1881 | 3211 | 0 |
| `14-run-2b-stop-records` | slow | 1413 | 1784 | 3197 | 2 |
| `88-origin-after-gc` | slow | 1456 | 1713 | 3169 | 24 |
| `77-resolve-fallbacks` | slow | 1405 | 1716 | 3121 | 13 |
| `61-needs-git` | slow | 1344 | 1775 | 3119 | 0 |
| `68-show` | fast | 1214 | 1885 | 3099 | 50 |
| `44-lanes-record` | slow | 1335 | 1756 | 3091 | 17 |
| `49-lanes-slots` | slow | 1419 | 1663 | 3082 | 3 |
| `63-question-locations` | fast | 1258 | 1809 | 3067 | 1 |
| `76-resolve-session` | slow | 1392 | 1653 | 3045 | 0 |
| `48-lanes-rebase` | slow | 1351 | 1677 | 3028 | 9 |
| `40-run-18-test-counts-m5` | slow | 1348 | 1677 | 3025 | 1 |
| `88-origin-outage` | slow | 1338 | 1674 | 3012 | 4 |
| `57-inbox` | fast | 1259 | 1730 | 2989 | 2 |
| `87-fast-gate-run` | slow | 1302 | 1680 | 2982 | 0 |
| `38-run-17-gotchas-and-pack-m3` | slow | 1254 | 1725 | 2979 | 0 |
| `47-lanes-two` | slow | 1307 | 1656 | 2963 | 7 |
| `19-run-9e-deadline-verifies` | slow | 1308 | 1650 | 2958 | 10 |
| `81-partial-key` | fast | 1273 | 1681 | 2954 | 31 |
| `65-project-names` | fast | 1388 | 1561 | 2949 | 0 |
| `76-entries-survive` | slow | 1276 | 1659 | 2935 | 4 |
| `92-resident-helper-run` | slow | 1318 | 1601 | 2919 | 15 |
| `66-record-after-gc` | fast | 1361 | 1540 | 2901 | 4 |
| `83-spec-must-exist` | fast | 1223 | 1675 | 2898 | 6 |
| `45-lanes-run` | slow | 1256 | 1639 | 2895 | 3 |
| `71-tty-views` | fast | 1327 | 1548 | 2875 | 20 |
| `30-run-15b-run-that` | fast | 1257 | 1609 | 2866 | 0 |
| `50-lanes-record-pr` | slow | 1404 | 1436 | 2840 | 0 |
| `26-run-13c-stale-green` | fast | 1178 | 1644 | 2822 | 0 |
| `46-lanes-continue` | slow | 1349 | 1458 | 2807 | 19 |
| `42-run-20-review-gate-rounds-m6` | slow | 1300 | 1450 | 2750 | 2 |
| `39-memlint-m4` | fast | 1250 | 1472 | 2722 | 6 |
| `29-run-15-resumed-run` | fast | 1304 | 1416 | 2720 | 3 |
| `77-leftovers` | slow | 1267 | 1434 | 2701 | 0 |
| `34-check-key` | fast | 1062 | 1629 | 2691 | 0 |
| `37-memory-prompts-m2` | slow | 1249 | 1425 | 2674 | 2 |
| `85-suite-runs` | fast | 1223 | 1440 | 2663 | 3 |
| `18-run-9c-refused-sessions` | fast | 1101 | 1561 | 2662 | 0 |
| `27-run-14-v2-style` | fast | 1270 | 1389 | 2659 | 8 |
| `16-run-6-limit-cuts` | slow | 1228 | 1425 | 2653 | 0 |
| `79-suite-length` | slow | 1238 | 1413 | 2651 | 0 |
| `80-red-marker` | slow | 1238 | 1413 | 2651 | 0 |
| `89-no-deadline` | slow | 1237 | 1411 | 2648 | 0 |
| `75-merge-sorted` | fast | 1248 | 1391 | 2639 | 8 |
| `41-run-19-review-gate-m6` | slow | 1213 | 1422 | 2635 | 1 |
| `00-unit-tier` | fast | 0 | 2625 | 2625 | 134 |
| `25-run-13b-bs-entry` | fast | 1222 | 1403 | 2625 | 0 |
| `22-run-12-session-claims` | fast | 1218 | 1400 | 2618 | 0 |
| `28-run-14d-harness-merge` | fast | 1225 | 1386 | 2611 | 0 |
| `75-suite-tools` | fast | 1219 | 1392 | 2611 | 0 |
| `21-run-11-verify-refused` | fast | 1212 | 1395 | 2607 | 6 |
| `24-run-13-verify-and` | fast | 1206 | 1386 | 2592 | 0 |
| `17-run-8-thin-verify` | fast | 1204 | 1386 | 2590 | 0 |
| `23-run-12b-nothing-sets` | fast | 1194 | 1386 | 2580 | 0 |
| `84-node-memo` | fast | 1170 | 1378 | 2548 | 1 |
| `69-same-project-starts` | fast | 936 | 1208 | 2144 | 5 |
| `31-tmux-l3-03-when` | fast | 794 | 1192 | 1986 | 2 |
| `93-xtrace` | fast | 0 | 1680 | 1680 | 0 |
| `56-status-review` | fast | 133 | 1279 | 1412 | 0 |
| `53-status-view` | fast | 134 | 1193 | 1327 | 3 |
| `52-status-json` | fast | 137 | 1085 | 1222 | 0 |
| `54-status-card` | fast | 133 | 1070 | 1203 | 0 |
| `55-queue-view` | fast | 109 | 1039 | 1148 | 9 |
| `62-needs-readers` | fast | 116 | 742 | 858 | 1 |
| `58-needs-record` | fast | 35 | 760 | 795 | 2 |
| `59-needs-cards` | fast | 43 | 743 | 786 | 0 |
| `64-needs-review` | fast | 115 | 606 | 721 | 2 |
| `78-continue-busy` | fast | 43 | 522 | 565 | 0 |
| `10-harness-eval-run-e2` | slow | 236 | 324 | 560 | 207 |
| `12-journal-pure-e4-entrys` | fast | 113 | 365 | 478 | 12 |
| `91-resident-helper` | fast | 55 | 294 | 349 | 3 |
| `86-fast-gate` | fast | 182 | 108 | 290 | 0 |
| `73-check-rerun` | fast | 164 | 95 | 259 | 2 |
| `43-lanes-scheduler` | fast | 66 | 129 | 195 | 0 |
| `67-gc-units` | fast | 150 | 0 | 150 | 0 |
| `35-backlog-pure-m1` | fast | 0 | 137 | 137 | 13 |
| `51-view-pure` | fast | 0 | 124 | 124 | 16 |
| `07-step-lint-pure-r3` | fast | 0 | 95 | 95 | 0 |
| `09-replay-set-e2-every` | fast | 0 | 88 | 88 | 1 |
| `20-sync-live-checkout-level` | fast | 86 | 0 | 86 | 19 |
| `89-night-words` | fast | 0 | 85 | 85 | 0 |
| `82-key-map-lint` | fast | 54 | 30 | 84 | 0 |
| `03-harness-parked-pure-report` | fast | 25 | 46 | 71 | 0 |
| `05-metrics-pure-tokens-cache` | fast | 0 | 57 | 57 | 0 |
| `11-deploy-guards-pure-and` | fast | 0 | 49 | 49 | 0 |
| `06-test-counts-pure-r1` | fast | 0 | 45 | 45 | 0 |
| `04-render-pure-sections-go` | fast | 0 | 41 | 41 | 0 |
| `33-suite-runner` | slow | 0 | 0 | 0 | 0 |
| **the union of all 98** | | **3108** | **3671** | **6779** | |

The unit tier's files, each run alone (rows of `00-unit-tier` above, split):

| unit test file | node lines | lines no stub-run or CLI check file runs |
|---|---:|---:|
| `backlog` | 20 | 0 |
| `cli` | 371 | 20 |
| `coverage` | 0 | 0 |
| `deploy` | 76 | 1 |
| `entries` | 383 | 7 |
| `eval` | 166 | 7 |
| `features` | 291 | 35 |
| `inbox` | 157 | 19 |
| `memlint` | 139 | 6 |
| `metrics` | 161 | 1 |
| `needs` | 786 | 2 |
| `notify` | 96 | 4 |
| `overlap` | 39 | 0 |
| `page` | 51 | 0 |
| `parked` | 108 | 19 |
| `render` | 43 | 0 |
| `show` | 281 | 1 |
| `summary` | 532 | 0 |
| `testcount` | 46 | 1 |
| `treekey` | 86 | 0 |
| `view` | 180 | 14 |
| **the union of all 21** | **2625** | **134** |

### Table 2 · per source file: how many check files run each line

| source file | lines that can run | run by a check file | by 1 | by 2–4 | by 5–19 | by 20 or more | by none |
|---|---:|---:|---:|---:|---:|---:|---:|
| `bin/harness` | 541 | 528 | 78 | 126 | 224 | 100 | 13 |
| `lib/backlog.mjs` | 141 | 137 | 13 | 98 | 4 | 22 | 4 |
| `lib/backlog.sh` | 25 | 22 | 22 | 0 | 0 | 0 | 3 |
| `lib/check.sh` | 141 | 141 | 34 | 19 | 9 | 79 | 0 |
| `lib/cli.mjs` | 27 | 27 | 0 | 1 | 4 | 22 | 0 |
| `lib/config.sh` | 80 | 77 | 0 | 3 | 1 | 73 | 3 |
| `lib/debrief.sh` | 215 | 214 | 53 | 1 | 160 | 0 | 1 |
| `lib/deploy.mjs` | 83 | 80 | 9 | 41 | 0 | 30 | 3 |
| `lib/deploy.sh` | 26 | 23 | 4 | 8 | 0 | 11 | 3 |
| `lib/desk.sh` | 159 | 155 | 139 | 7 | 9 | 0 | 4 |
| `lib/driver.sh` | 370 | 361 | 41 | 11 | 51 | 258 | 9 |
| `lib/entries.mjs` | 308 | 308 | 10 | 42 | 20 | 236 | 0 |
| `lib/eval.mjs` | 220 | 217 | 62 | 155 | 0 | 0 | 3 |
| `lib/eval.sh` | 161 | 152 | 152 | 0 | 0 | 0 | 9 |
| `lib/features.mjs` | 311 | 310 | 35 | 22 | 32 | 221 | 1 |
| `lib/helper.mjs` | 39 | 38 | 3 | 0 | 4 | 31 | 1 |
| `lib/inbox.mjs` | 141 | 139 | 24 | 14 | 46 | 55 | 2 |
| `lib/lane.sh` | 341 | 335 | 38 | 69 | 66 | 162 | 6 |
| `lib/memlint.mjs` | 148 | 145 | 14 | 38 | 0 | 93 | 3 |
| `lib/merge-sorted.sh` | 8 | 8 | 8 | 0 | 0 | 0 | 0 |
| `lib/metrics.mjs` | 150 | 149 | 6 | 12 | 16 | 115 | 1 |
| `lib/needs.mjs` | 573 | 569 | 10 | 93 | 202 | 264 | 4 |
| `lib/needs.sh` | 12 | 12 | 0 | 0 | 4 | 8 | 0 |
| `lib/notify.mjs` | 48 | 48 | 7 | 11 | 10 | 20 | 0 |
| `lib/notify.sh` | 32 | 31 | 0 | 2 | 1 | 28 | 1 |
| `lib/overlap.mjs` | 116 | 114 | 7 | 28 | 4 | 75 | 2 |
| `lib/page.mjs` | 101 | 101 | 6 | 0 | 95 | 0 | 0 |
| `lib/parked.mjs` | 59 | 59 | 19 | 22 | 10 | 8 | 0 |
| `lib/prompt.sh` | 65 | 64 | 11 | 1 | 13 | 39 | 1 |
| `lib/queue.sh` | 70 | 67 | 9 | 24 | 34 | 0 | 3 |
| `lib/record.sh` | 724 | 709 | 65 | 85 | 80 | 479 | 15 |
| `lib/render.mjs` | 24 | 24 | 0 | 0 | 0 | 24 | 0 |
| `lib/resolve.sh` | 91 | 87 | 8 | 79 | 0 | 0 | 4 |
| `lib/review.sh` | 5 | 5 | 0 | 5 | 0 | 0 | 0 |
| `lib/scope.sh` | 55 | 55 | 17 | 3 | 6 | 29 | 0 |
| `lib/show.mjs` | 185 | 183 | 51 | 132 | 0 | 0 | 2 |
| `lib/spec.sh` | 19 | 19 | 2 | 5 | 3 | 9 | 0 |
| `lib/status.mjs` | 351 | 349 | 10 | 42 | 188 | 109 | 2 |
| `lib/summary.mjs` | 380 | 378 | 25 | 29 | 31 | 293 | 2 |
| `lib/sync.sh` | 24 | 24 | 19 | 0 | 5 | 0 | 0 |
| `lib/testcount.mjs` | 27 | 27 | 1 | 0 | 0 | 26 | 0 |
| `lib/tmux.sh` | 17 | 16 | 0 | 5 | 9 | 2 | 1 |
| `lib/treekey.mjs` | 66 | 66 | 0 | 14 | 1 | 51 | 0 |
| `lib/version.sh` | 3 | 3 | 0 | 0 | 0 | 3 | 0 |
| `lib/view.mjs` | 203 | 203 | 30 | 30 | 46 | 97 | 0 |
| `lib/xtrace.sh` | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| **all** | **6885** | **6779** | **1042** | **1277** | **1388** | **3072** | **106** |

### Table 3 · check files whose lines all lie inside another's (candidates to merge)

| check file | its lines | inside (smallest first) |
|---|---:|---|
| `04-render-pure-sections-go` | 41 | `93-xtrace`, `31-tmux-l3-03-when`, `69-same-project-starts`, `84-node-memo`, `23-run-12b-nothing-sets`, `17-run-8-thin-verify`, and 62 more |
| `06-test-counts-pure-r1` | 45 | `86-fast-gate`, `91-resident-helper`, `93-xtrace`, `31-tmux-l3-03-when`, `69-same-project-starts`, `84-node-memo`, and 63 more |
| `05-metrics-pure-tokens-cache` | 57 | `00-unit-tier`, `25-run-13b-bs-entry`, `76-entries-survive`, `57-inbox`, `63-question-locations`, `44-lanes-record`, and 3 more |
| `82-key-map-lint` | 84 | `86-fast-gate`, `81-partial-key` |
| `89-night-words` | 85 | `93-xtrace`, `31-tmux-l3-03-when`, `69-same-project-starts`, `84-node-memo`, `23-run-12b-nothing-sets`, `17-run-8-thin-verify`, and 61 more |
| `07-step-lint-pure-r3` | 95 | `84-node-memo`, `00-unit-tier` |
| `67-gc-units` | 150 | `49-lanes-slots`, `08-scope-sh-l1-02-run-capped-services-gc-scratch`, `13-run-2-michael-sets-desk` |
| `17-run-8-thin-verify` | 2590 | `61-needs-git` |
| `75-suite-tools` | 2611 | `37-memory-prompts-m2`, `29-run-15-resumed-run`, `39-memlint-m4`, `92-resident-helper-run`, `61-needs-git`, `14-run-2b-stop-records`, and 4 more |
| `25-run-13b-bs-entry` | 2625 | `76-entries-survive`, `08-scope-sh-l1-02-run-capped-services-gc-scratch`, `13-run-2-michael-sets-desk` |
| `16-run-6-limit-cuts` | 2653 | `76-entries-survive`, `15-run-4-same-but-queue-parked-debrief-tmux` |
| `18-run-9c-refused-sessions` | 2662 | `15-run-4-same-but-queue-parked-debrief-tmux` |

### Table 4 · lines run by 20 or more check files (every scenario pays them)

| source file | lines | which |
|---|---:|---|
| `bin/harness` | 100 | 90-92,94,96,98,100,102,104,112-113,126-128,130,133-134,144-145,150,178-180,184,216,307-311,314,316-320,322-324,326-327,330,332,336-340,342-343,345,349-352,354-356,359,361,363-366,368-369,371,373-379,381,385-386,467-470,472-474,481,486-487,498-501,503-507,509,876,878,882 |
| `lib/backlog.mjs` | 22 | 15-17,19-21,25,87,89,126-128,139,144,146,174-177,184-185,203 |
| `lib/check.sh` | 79 | 39-48,51-57,63,67-68,70-71,77-80,85,88,90-91,99-100,102-104,106-107,109-111,113-114,116,118,122,143,145,166-170,174-176,187,190-191,208,227-230,232-235,237-240,242-243,246,248-249,252-253,255 |
| `lib/cli.mjs` | 22 | 3-6,8,11-12,14-16,22-24,26-29,36-39,44 |
| `lib/config.sh` | 73 | 13-16,20,23-46,48-53,55-69,71,73-76,83-85,87,89,91-93,98-101,107,118-121,123 |
| `lib/deploy.mjs` | 30 | 7-10,12,43,57,82-84,87-89,93-97,100,102-103,120-127,135 |
| `lib/deploy.sh` | 11 | 5,10-13,16-21 |
| `lib/driver.sh` | 258 | 35,37,39,41,43,45-46,48,50-56,58-59,62-63,71-74,76,90-91,93,96-99,106-115,117-118,120,125-127,129,144-146,148,150-153,155-163,174-178,180,186-187,189-190,196-199,202,228-229,231,233-236,240-241,243,245-251,255-256,258-261,265-266,280,304,306-307,312-315,317-318,320-325,330-332,334-342,345-346,349-350,352-355,358-360,362,365-367,374-376,379-383,387,389-395,403,407,411-414,417-420,425,427,454,465-469,477,481,487-493,496-497,500,502-510,512-515,519-523,526-529,531-535,537-542,547-552,554-556,563-567,569-570,574,577-586,594,597-598,610 |
| `lib/entries.mjs` | 236 | 22-26,28-31,33-36,38,40,47-56,58-63,65-69,73-75,77-82,84-86,89,91,96-99,103-107,109-112,122,124,132-140,143,147-149,153-157,159,163-165,168-173,175-187,190-191,197-198,200-202,207,211-215,217,221-225,229-232,235-236,238-239,261-277,279-280,286-287,293-300,302-307,309-317,323,327-329,334,345-346,377,391-393,396,398,400-406,408-414,416-422,429-436,438-445,447,450-456,475 |
| `lib/features.mjs` | 221 | 52-55,57-58,60,67-69,75,78-80,87-89,100-102,104-107,116-121,129-137,139,143-146,162-163,165,175-176,210,215-219,221,224-226,230-234,236,240,244-249,251,253,256-266,268-270,275-279,286-290,292-298,300,302-304,327-330,338-343,347,349,351,353,355-357,360-363,370-373,375-376,380-382,389-398,400-404,407,414,416-424,428-429,441,443-445,447-449,453-458,460-461,468-472,474,476-482,484-488,509-518,523-528,530,532-534,541 |
| `lib/helper.mjs` | 31 | 5,7-9,17-19,22-28,32-35,41,43,47-48,50-55,57-58,61 |
| `lib/inbox.mjs` | 55 | 8-9,11,16-21,25-26,31-33,36-37,86-93,98,123-129,164-172,186-191,195-197,203-206,214 |
| `lib/lane.sh` | 162 | 17-18,20,22,24,26,28,30-35,38-40,43,45-49,94-103,105-106,108,110-115,119-129,137-142,144-146,150-151,155-156,161,165-168,172,174-175,181-184,186-189,221,226,228-231,242,297,303,320,325,331-342,351-353,356,358-360,365-366,371-372,381,385-388,402-406,408-414,417,419-425,429,447,450,456-458,460-467,480-483,489,494,497-498 |
| `lib/memlint.mjs` | 93 | 15-17,21-26,28,34-38,41,45-46,52,55-62,66,71-75,79-80,84,125-127,137-138,141-142,144-146,149-150,154-165,167,174-176,197,202-206,208-213,216-221,223-224,226-229,231,235-236,238,241 |
| `lib/metrics.mjs` | 115 | 29-30,32-37,39,43-48,54,58-61,65-66,72-78,80-85,89-91,94-95,97-113,118,121-127,132,137-147,150,182,186-188,194,196-197,201,208-210,212-214,218-223,225,229-243,249 |
| `lib/needs.mjs` | 264 | 18-29,32-42,44-45,47-49,52,54,56,79-86,88,118-124,133-135,138-139,141,151,166-167,175,179,184,188,193,207,219,231,242,253,263,274,276,285,293,303,311,319,328,341-343,345-349,354-359,364,373-379,381-383,386,390-394,396-402,412,416-419,427,441-445,447,453-455,460,463,465,468,471,474,489,494-501,503-515,518-520,537-542,545,548-567,569,573-578,580-581,599-611,615-617,624-626,628,631-633,636,647-651,654-657,660-662,664-669,672,676-678,711-717,719,722-723,725-728,730-734,736,738,752,779 |
| `lib/needs.sh` | 8 | 6,8,11,15-16,28-30 |
| `lib/notify.mjs` | 20 | 8-10,29-31,33-36,46,48-49,59-64,77 |
| `lib/notify.sh` | 28 | 8-9,12-21,24-25,27-34,36,43,49-50,55-56 |
| `lib/overlap.mjs` | 75 | 9-12,14-17,20,23-28,35-38,51,71-73,78-83,88-93,95,99-104,106,108-109,111-115,124-129,141-149,156-158,163,168,172-174,176,182 |
| `lib/parked.mjs` | 8 | 6-10,12,15,91 |
| `lib/prompt.sh` | 39 | 8,11-12,29-34,36,47-48,63-64,66-68,70,72-74,76,83-84,90-91,93,96-98,102-103,105,107-110,113,117 |
| `lib/record.sh` | 479 | 10,14,17,20-21,23-24,28-29,34,36-45,50,52-54,60-66,73-74,83-85,88-89,93,99-105,108,114-120,123-128,135-151,153-154,182-183,185-186,189-191,193,197-201,203-204,206-207,213-220,225-226,232-240,243-245,250-252,260-268,270-272,275-279,281-282,286-287,290-292,301-308,310-312,316-318,332,351-354,359,369-371,404,410,415,449,451-452,454-458,460,466-467,469-470,474-477,494-495,517,520-521,527-528,532,541-543,545-548,550,552,554-555,558,560-562,564-565,568-570,579-583,619-624,626,628,630-633,638-639,643-644,647-649,651,653-654,656-660,663-665,671-673,676-678,685-689,695,704-706,712,722-728,732,735-741,745-748,753-756,758,761,769-772,781-782,786-788,790-792,794-795,830-837,848-849,851,855-858,868,904,908,910,914-916,927-929,931,934,938-939,942,948,969-970,977,982-987,989,991-993,1008-1010,1013-1018,1024,1026,1030,1034-1035,1041,1043,1053-1058,1061-1067,1070-1074,1080-1081,1085-1087,1095-1097,1100,1105-1106,1115-1118,1122-1123,1129-1131,1141-1145,1147-1149,1151-1152,1155,1160,1162-1165,1167,1169,1178-1181,1191-1193,1203-1210,1218-1219,1225-1228,1233-1234,1237-1241,1247-1249,1252,1259-1262,1270-1272,1284-1285,1288,1294-1298,1300-1306,1310-1311,1314 |
| `lib/render.mjs` | 24 | 9-10,12-13,16-19,21-24,27-35,37-38,41 |
| `lib/scope.sh` | 29 | 11,13,17-18,22,35,42-47,49-50,59-61,66-67,73-75,80-81,92-93,102,121-122 |
| `lib/spec.sh` | 9 | 8-11,26-30 |
| `lib/status.mjs` | 109 | 16-22,24-31,34-35,37,40,43-52,55-64,69,71,75-78,84,88-89,91,94-97,100-103,107-109,111,114-118,121-122,127-137,139-141,159,161,163,281-282,322,419-424,426-427,431-435,437,449-450,473,484-486,489 |
| `lib/summary.mjs` | 293 | 17-23,25-26,28,30-33,37-39,42-44,48-53,56-58,62-77,80,86-87,89-92,95,99-111,113-114,119-122,127-129,135-138,148-152,157-158,164-167,171-172,176,181-183,186,190-192,197-200,213-215,217-226,229-232,240-241,245,247-251,253-256,260,262-263,265-271,273-275,277,288,291-307,310-312,314-323,325-357,362-364,384-392,394,396,398,400-404,406-408,410,412-415,420,424-427,429,431-434,436-438,491-497,499-508,510-519,521,533,537-544,551-553,559 |
| `lib/testcount.mjs` | 26 | 4-5,9,11-14,16-23,30-32,35-41,44 |
| `lib/tmux.sh` | 2 | 6,11 |
| `lib/treekey.mjs` | 51 | 12-16,20-24,28-30,41,49-55,57,60-63,67-71,80-82,84,86-88,91-96,98,100-101,104-106,109 |
| `lib/version.sh` | 3 | 6-8 |
| `lib/view.mjs` | 97 | 7-9,11-14,16,19-28,31-33,36-38,42-46,48-51,54-55,58-66,68,72-79,82-84,146-149,152,154,157-158,164-168,171,176-187,189,192-194,208-210,232-234,237-239,246,297 |
| **all** | **3072** | |

### Table 5 · lines no check file runs (dead, or untested)

| source file | lines | which (bash: by function) |
|---|---:|---|
| `bin/harness` | 13 | cmd_init: 196-197 · cmd_start: 312,315,346-347,357 · cmd_show: 518 · cmd_queue: 599-600 · cmd_control: 608 · cmd_gc: 705 · (top level): 894 |
| `lib/backlog.mjs` | 4 | 92,196-198 |
| `lib/backlog.sh` | 3 | write: 20,26,29 |
| `lib/config.sh` | 3 | detect_check: 86,88,90 |
| `lib/debrief.sh` | 1 | rate_info: 154 |
| `lib/deploy.mjs` | 3 | 129-131 |
| `lib/deploy.sh` | 3 | deploy_guard: 30,36-37 |
| `lib/desk.sh` | 4 | commit_record: 162 · (top level): 206-208 |
| `lib/driver.sh` | 9 | lanes_orphans: 200 · ledger: 257,269,271 · record_pr: 281,296 · finish: 361 · (top level): 458 · deploy_check: 473 |
| `lib/eval.mjs` | 3 | 333-335 |
| `lib/eval.sh` | 9 | set_tasks: 38 · share_limit: 91 · run_task: 143-144 · cmd_run: 157,185,208 · cmd_compare: 232 · (top level): 283 |
| `lib/features.mjs` | 1 | 194 |
| `lib/helper.mjs` | 1 | 29 |
| `lib/inbox.mjs` | 2 | 23,156 |
| `lib/lane.sh` | 6 | red_names: 59 · rebase: 247,285 · (top level): 328,398-399 |
| `lib/memlint.mjs` | 3 | 131-133 |
| `lib/metrics.mjs` | 1 | 53 |
| `lib/needs.mjs` | 4 | 200,211,267,269 |
| `lib/notify.sh` | 1 | notify: 38 |
| `lib/overlap.mjs` | 2 | 178-179 |
| `lib/prompt.sh` | 1 | scratch_rm: 20 |
| `lib/queue.sh` | 3 | entry_project: 79-80,92 |
| `lib/record.sh` | 15 | helper_failed: 163 · green_fix: 326 · slept_until: 512 · journal: 634-635 · journal_: 661 · context_: 708-709 · sync_record_: 1083 · slot_open: 1172-1174,1196-1198 |
| `lib/resolve.sh` | 4 | resolve: 45,48,79-80 |
| `lib/show.mjs` | 2 | 241-242 |
| `lib/status.mjs` | 2 | 428-429 |
| `lib/summary.mjs` | 2 | 242-243 |
| `lib/tmux.sh` | 1 | tmux_reap: 24 |
| **all** | **106** | |

In no table: 39 lines no trace can name (what each script runs before its trace starts, its option line to its guard, and `lib/xtrace.sh` itself).

## What the map can't see

- **Run is not asserted on.** A line a check file runs may be a line no check would miss: that is what the mutation
  sample below measures.
- **A check file, not a check.** The sets are per check file; which check of a file runs a line is not recorded.
- **bash numbers multi-line statements its own way** (5.2.21, tried on small scripts; `tests/fixtures/coverage/` holds
  one real trace of each shape). A command continued with `\` is numbered at its first line; a multi-line `[[ … ]]`,
  quoted string or array `=( … )` at its last; a command inside a multi-line `$( … )` one line too high; the commands
  of a `<( … )` that feeds a loop at their function's header line; a trap's commands from line 1. The reducer
  (`shScan`, `shAttribute` in `tests/tools/coverage.mjs`) therefore counts a statement that spans lines as its first
  line (94 such statements hold 254 lines), counts `done < <(…)` under its loop's own line, and drops a number that
  lands on a line with no command instead of giving it to a neighbour (about ten numbers per stub-run file). What
  stays uncertain: the 48 `\` continuation lines that begin with `&&`, `||` or `|` are counted when bash names them,
  which in one shape it also does for the command before; and a command in a multi-line `$( )` numbered one too high
  can land on the next statement, which nearly always ran anyway.
- **The scanner is a guess at bash's grammar** (quotes, parentheses, backslashes, here-documents, `case … esac`),
  not a parser. It was read against every statement it believes spans five lines or more and against a sample of
  Table 5, and the review found four command lines it had read as holding none (a subshell's closing line, a command
  after `done < <(…);`): those vanished from the run lines and from Table 5 alike, so such a misreading is silent.
  The four are fixed; another shape may remain. The other way round, a number bash puts one line too high can credit
  the next statement.
- **39 lines can't be traced at all**: what each of the twelve scripts runs before its trace starts (its
  `set -…o pipefail` line to its guard) and `lib/xtrace.sh` itself. They are in no table.
- **A node line is run when code on it ran, whole or not.** A branch never taken on a line that ran is not seen, and
  `xs.map(x => …)` is run once `xs.map(` ran, though the callback never did: both are marked partial. The 496 lines
  only ever run in part are listed; the mutation sample marks a mutant on a partial line. What counts as the
  declaration of a never-called function is a pattern (`export`, `const f =`, `name:`), not a parse.
- **A node process ended by KILL writes no coverage.** node writes it on an exit of its own only. The harness ends its
  resident helper with TERM, so the measurement preloads `tests/tools/cov-exit.cjs`, which turns a TERM into an exit
  (seen: no file without it, one with it, status 143 both ways); a `kill -9` (the helper's hung-request path, which
  no check reaches) still loses the file. With the preload a node busy in a synchronous call ends only when the call
  returns; no check went red over it.
- **A copy of the harness outside the checkout is not counted.** Two check files run one: `10-harness-eval-run-e2`
  (the eval's worktree of the harness at a base commit) and `92-resident-helper-run` (a copy under its temp
  directory). Their rows in Table 1 understate what they run by those lines.
- **`93-xtrace` traces its own runs to its own directory** (it sets and unsets the variable itself), so its row
  shows no bash line though it runs two whole stub runs. `33-suite-runner` runs the runner, not the harness: 0 lines.
- **Counts, not times.** How long a line takes is not measured; the before row's wall and CPU are the suite's.

## The raw sets (for S2)

`findings-and-research/2026-11-03-suite-coverage/`:

- `<check file>.txt` (98) and `unit-<name>.txt` (21): the lines that file runs, one source file per line,
  `lib/record.sh 12-40,44,51-80`; `~lib/summary.mjs 17,23` names the node lines among them that ran only in part.
- `_union.txt`: every check file's lines together, the set S2's coverage proof compares against
  (`node tests/tools/coverage.mjs union <sets dir> > after.txt; node tests/tools/coverage.mjs missing _union.txt after.txt`
  prints the lines lost and exits 1 when there are any).
- `_line-counts.txt`: `<file>:<line> <how many check files run it>` for each of the 6,779 lines.
- `_partial-only.txt`: the 496 node lines no check file runs whole.

`node tests/tools/coverage.mjs covering <sets dir> <file> <line>` names the check files that run a line.
