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
  counts). A line counts when any character of it that is no white space ran; it is marked partial (`~` in the sets)
  when another character of it did not. Only lines that hold code are kept (no comment, blank line or closing brace).
- **the unit tier** is the check file `00-unit-tier`; its 21 test files were also each run alone
  (`unit-<name>.txt`), as rows of their own that never count as a check file.
- **the run**: 1,489 of 1,489 checks passed under the trace, in 681.5 s wall and 2,563.9 CPU-s (plain: 599.4 s and
  2,108.1 CPU-s, so the trace costs 14 % wall and 22 % CPU, not the two suites of CPU the spec allowed for). The run's
  one red line was the conformance check, on a unit test this session had renamed after adding its name to the
  fixture; the fixture was put right before the commit. A first run, before that rename, passed 1490/1490 in 696.2 s;
  its sets were reduced with an earlier reducer and are not the ones here. The raw traces of a full run are 8.8 GB.

## What the map says

- **6,888 lines of `lib/` and `bin/` hold code** (3,180 of bash, 3,708 of node). **6,783 of them, 98.5 %, are run by
  at least one check file** (3,104 of bash, 3,679 of node); **105 by none** (76 of bash, 29 of node; Table 5: mostly
  error branches, each listed).
- **3,364 lines, 49 %, are run by 20 or more check files** (Table 4): the stub start's path, which every scenario
  pays. 1,008 lines are run by exactly one check file (Table 1's last column says whose).
- **13 check files run nothing another file does not also run whole** (Table 3). Eight are small files of pure
  functions whose lines the unit tier or a scenario also runs; five are stub-run scenarios of about 2,900 lines each
  that lie inside a larger scenario. That a file's lines lie inside another's says the code it runs is run elsewhere,
  not that its assertions are made elsewhere: S2 reads the assertions.
- **44 of the 98 check files have no line of their own** (Table 1, `only this file` = 0), the 13 among them.
- **The unit tier alone runs 2,752 of the 3,679 node lines the suite runs**; 120 of those are run by no other check file.
- **500 node lines are only ever run in part** (a branch on the line that no check file takes, or a one-line function
  never called): `2026-11-03-suite-coverage/_partial-only.txt`.

## The five tables

Generated by `node tests/tools/coverage.mjs tables findings-and-research/2026-11-03-suite-coverage`. A line is a line of
`lib/` or `bin/harness` that holds code; "run" is run by a check file, as the method above counts it.

### Table 1 · per check file: the lines of `lib/` and `bin/` it runs

| check file | tier | bash lines | node lines | all | only this file |
|---|---|---:|---:|---:|---:|
| `13-run-2-michael-sets-desk` | slow | 2071 | 2524 | 4595 | 152 |
| `15-run-4-same-but-queue-parked-debrief-tmux` | slow | 1937 | 2451 | 4388 | 77 |
| `72-u3-review` | slow | 1660 | 2417 | 4077 | 0 |
| `08-scope-sh-l1-02-run-capped-services-gc-scratch` | slow | 1611 | 2173 | 3784 | 34 |
| `32-l5-queue-runner-re` | slow | 1639 | 2135 | 3774 | 3 |
| `78-needs-questions` | slow | 1374 | 2380 | 3754 | 1 |
| `74-flakes-run` | slow | 1416 | 2238 | 3654 | 0 |
| `90-fix-rounds` | slow | 1409 | 2235 | 3644 | 21 |
| `36-run-16-retro-backlog` | slow | 1432 | 2160 | 3592 | 29 |
| `70-overlap` | slow | 1293 | 2260 | 3553 | 7 |
| `14-run-2b-stop-records` | slow | 1411 | 2098 | 3509 | 2 |
| `60-needs-driver` | slow | 1328 | 2102 | 3430 | 0 |
| `88-origin-after-gc` | slow | 1454 | 1956 | 3410 | 24 |
| `68-show` | fast | 1213 | 2178 | 3391 | 46 |
| `77-resolve-fallbacks` | slow | 1404 | 1951 | 3355 | 13 |
| `49-lanes-slots` | slow | 1418 | 1930 | 3348 | 3 |
| `44-lanes-record` | slow | 1333 | 2005 | 3338 | 17 |
| `40-run-18-test-counts-m5` | slow | 1346 | 1991 | 3337 | 1 |
| `61-needs-git` | slow | 1342 | 1990 | 3332 | 0 |
| `63-question-locations` | fast | 1257 | 2057 | 3314 | 1 |
| `76-resolve-session` | slow | 1390 | 1916 | 3306 | 0 |
| `48-lanes-rebase` | slow | 1349 | 1943 | 3292 | 9 |
| `65-project-names` | fast | 1387 | 1893 | 3280 | 0 |
| `47-lanes-two` | slow | 1306 | 1972 | 3278 | 7 |
| `88-origin-outage` | slow | 1336 | 1932 | 3268 | 4 |
| `57-inbox` | fast | 1258 | 1996 | 3254 | 2 |
| `38-run-17-gotchas-and-pack-m3` | slow | 1253 | 1988 | 3241 | 0 |
| `87-fast-gate-run` | slow | 1301 | 1939 | 3240 | 0 |
| `66-record-after-gc` | fast | 1360 | 1877 | 3237 | 4 |
| `83-spec-must-exist` | fast | 1221 | 2005 | 3226 | 6 |
| `19-run-9e-deadline-verifies` | slow | 1306 | 1915 | 3221 | 10 |
| `81-partial-key` | fast | 1272 | 1942 | 3214 | 31 |
| `76-entries-survive` | slow | 1275 | 1927 | 3202 | 4 |
| `92-resident-helper-run` | slow | 1317 | 1880 | 3197 | 15 |
| `71-tty-views` | fast | 1326 | 1846 | 3172 | 18 |
| `45-lanes-run` | slow | 1255 | 1910 | 3165 | 3 |
| `50-lanes-record-pr` | slow | 1401 | 1743 | 3144 | 0 |
| `30-run-15b-run-that` | fast | 1255 | 1887 | 3142 | 0 |
| `46-lanes-continue` | slow | 1346 | 1762 | 3108 | 19 |
| `26-run-13c-stale-green` | fast | 1177 | 1912 | 3089 | 0 |
| `42-run-20-review-gate-rounds-m6` | slow | 1298 | 1755 | 3053 | 2 |
| `29-run-15-resumed-run` | fast | 1302 | 1730 | 3032 | 3 |
| `39-memlint-m4` | fast | 1249 | 1778 | 3027 | 5 |
| `77-leftovers` | slow | 1266 | 1739 | 3005 | 0 |
| `37-memory-prompts-m2` | slow | 1248 | 1733 | 2981 | 2 |
| `27-run-14-v2-style` | fast | 1267 | 1704 | 2971 | 8 |
| `85-suite-runs` | fast | 1222 | 1746 | 2968 | 3 |
| `34-check-key` | fast | 1061 | 1900 | 2961 | 0 |
| `16-run-6-limit-cuts` | slow | 1227 | 1732 | 2959 | 0 |
| `79-suite-length` | slow | 1237 | 1722 | 2959 | 0 |
| `80-red-marker` | slow | 1237 | 1722 | 2959 | 0 |
| `89-no-deadline` | slow | 1236 | 1721 | 2957 | 0 |
| `75-merge-sorted` | fast | 1247 | 1706 | 2953 | 8 |
| `18-run-9c-refused-sessions` | fast | 1099 | 1846 | 2945 | 0 |
| `41-run-19-review-gate-m6` | slow | 1212 | 1733 | 2945 | 1 |
| `25-run-13b-bs-entry` | fast | 1221 | 1714 | 2935 | 0 |
| `22-run-12-session-claims` | fast | 1217 | 1712 | 2929 | 0 |
| `75-suite-tools` | fast | 1218 | 1707 | 2925 | 0 |
| `28-run-14d-harness-merge` | fast | 1223 | 1701 | 2924 | 0 |
| `21-run-11-verify-refused` | fast | 1211 | 1707 | 2918 | 6 |
| `24-run-13-verify-and` | fast | 1205 | 1701 | 2906 | 0 |
| `17-run-8-thin-verify` | fast | 1203 | 1701 | 2904 | 0 |
| `23-run-12b-nothing-sets` | fast | 1193 | 1701 | 2894 | 0 |
| `84-node-memo` | fast | 1169 | 1689 | 2858 | 1 |
| `00-unit-tier` | fast | 0 | 2752 | 2752 | 120 |
| `69-same-project-starts` | fast | 934 | 1536 | 2470 | 5 |
| `31-tmux-l3-03-when` | fast | 793 | 1522 | 2315 | 2 |
| `93-xtrace` | fast | 0 | 2002 | 2002 | 0 |
| `56-status-review` | fast | 133 | 1552 | 1685 | 0 |
| `53-status-view` | fast | 134 | 1468 | 1602 | 1 |
| `52-status-json` | fast | 137 | 1376 | 1513 | 0 |
| `54-status-card` | fast | 133 | 1354 | 1487 | 0 |
| `55-queue-view` | fast | 109 | 1350 | 1459 | 8 |
| `62-needs-readers` | fast | 116 | 1003 | 1119 | 0 |
| `64-needs-review` | fast | 115 | 845 | 960 | 2 |
| `58-needs-record` | fast | 35 | 911 | 946 | 2 |
| `59-needs-cards` | fast | 43 | 881 | 924 | 0 |
| `78-continue-busy` | fast | 43 | 803 | 846 | 0 |
| `10-harness-eval-run-e2` | slow | 236 | 375 | 611 | 203 |
| `12-journal-pure-e4-entrys` | fast | 113 | 415 | 528 | 12 |
| `91-resident-helper` | fast | 55 | 379 | 434 | 2 |
| `86-fast-gate` | fast | 182 | 114 | 296 | 0 |
| `73-check-rerun` | fast | 164 | 103 | 267 | 2 |
| `43-lanes-scheduler` | fast | 66 | 151 | 217 | 0 |
| `67-gc-units` | fast | 150 | 0 | 150 | 0 |
| `09-replay-set-e2-every` | fast | 0 | 145 | 145 | 1 |
| `35-backlog-pure-m1` | fast | 0 | 138 | 138 | 11 |
| `51-view-pure` | fast | 0 | 134 | 134 | 16 |
| `07-step-lint-pure-r3` | fast | 0 | 125 | 125 | 0 |
| `89-night-words` | fast | 0 | 101 | 101 | 0 |
| `82-key-map-lint` | fast | 54 | 39 | 93 | 0 |
| `03-harness-parked-pure-report` | fast | 25 | 64 | 89 | 0 |
| `20-sync-live-checkout-level` | fast | 86 | 0 | 86 | 19 |
| `11-deploy-guards-pure-and` | fast | 0 | 78 | 78 | 0 |
| `05-metrics-pure-tokens-cache` | fast | 0 | 75 | 75 | 0 |
| `06-test-counts-pure-r1` | fast | 0 | 51 | 51 | 0 |
| `04-render-pure-sections-go` | fast | 0 | 46 | 46 | 0 |
| `33-suite-runner` | slow | 0 | 0 | 0 | 0 |
| **the union of all 98** | | **3104** | **3679** | **6783** | |

The unit tier's files, each run alone (rows of `00-unit-tier` above, split):

| unit test file | node lines | lines no stub-run or CLI check file runs |
|---|---:|---:|
| `backlog` | 35 | 0 |
| `cli` | 757 | 20 |
| `coverage` | 0 | 0 |
| `deploy` | 95 | 0 |
| `entries` | 440 | 5 |
| `eval` | 207 | 4 |
| `features` | 298 | 34 |
| `inbox` | 160 | 16 |
| `memlint` | 146 | 6 |
| `metrics` | 167 | 1 |
| `needs` | 946 | 2 |
| `notify` | 107 | 4 |
| `overlap` | 52 | 0 |
| `page` | 55 | 0 |
| `parked` | 137 | 17 |
| `render` | 48 | 0 |
| `show` | 666 | 0 |
| `summary` | 659 | 0 |
| `testcount` | 51 | 0 |
| `treekey` | 90 | 0 |
| `view` | 180 | 14 |
| **the union of all 21** | **2752** | **120** |

### Table 2 · per source file: how many check files run each line

| source file | lines that can run | run by a check file | by 1 | by 2–4 | by 5–19 | by 20 or more | by none |
|---|---:|---:|---:|---:|---:|---:|---:|
| `bin/harness` | 539 | 526 | 78 | 126 | 222 | 100 | 13 |
| `lib/backlog.mjs` | 142 | 138 | 11 | 83 | 4 | 40 | 4 |
| `lib/backlog.sh` | 25 | 22 | 22 | 0 | 0 | 0 | 3 |
| `lib/check.sh` | 141 | 141 | 34 | 19 | 9 | 79 | 0 |
| `lib/cli.mjs` | 27 | 27 | 0 | 1 | 2 | 24 | 0 |
| `lib/config.sh` | 80 | 77 | 0 | 3 | 1 | 73 | 3 |
| `lib/debrief.sh` | 214 | 213 | 53 | 1 | 159 | 0 | 1 |
| `lib/deploy.mjs` | 83 | 80 | 8 | 29 | 0 | 43 | 3 |
| `lib/deploy.sh` | 26 | 23 | 4 | 8 | 0 | 11 | 3 |
| `lib/desk.sh` | 159 | 155 | 139 | 7 | 9 | 0 | 4 |
| `lib/driver.sh` | 370 | 361 | 41 | 11 | 51 | 258 | 9 |
| `lib/entries.mjs` | 308 | 308 | 8 | 35 | 15 | 250 | 0 |
| `lib/eval.mjs` | 221 | 218 | 55 | 163 | 0 | 0 | 3 |
| `lib/eval.sh` | 161 | 152 | 152 | 0 | 0 | 0 | 9 |
| `lib/features.mjs` | 312 | 311 | 34 | 18 | 31 | 228 | 1 |
| `lib/helper.mjs` | 39 | 38 | 2 | 0 | 4 | 32 | 1 |
| `lib/inbox.mjs` | 141 | 139 | 21 | 14 | 42 | 62 | 2 |
| `lib/lane.sh` | 341 | 335 | 38 | 69 | 66 | 162 | 6 |
| `lib/memlint.mjs` | 149 | 146 | 13 | 35 | 0 | 98 | 3 |
| `lib/merge-sorted.sh` | 8 | 8 | 8 | 0 | 0 | 0 | 0 |
| `lib/metrics.mjs` | 150 | 150 | 6 | 8 | 13 | 123 | 0 |
| `lib/needs.mjs` | 573 | 569 | 8 | 53 | 93 | 415 | 4 |
| `lib/needs.sh` | 12 | 12 | 0 | 0 | 4 | 8 | 0 |
| `lib/notify.mjs` | 48 | 48 | 7 | 10 | 7 | 24 | 0 |
| `lib/notify.sh` | 32 | 31 | 0 | 2 | 1 | 28 | 1 |
| `lib/overlap.mjs` | 116 | 114 | 6 | 24 | 3 | 81 | 2 |
| `lib/page.mjs` | 101 | 101 | 6 | 0 | 95 | 0 | 0 |
| `lib/parked.mjs` | 59 | 59 | 17 | 20 | 7 | 15 | 0 |
| `lib/prompt.sh` | 65 | 64 | 11 | 1 | 13 | 39 | 1 |
| `lib/queue.sh` | 70 | 67 | 9 | 24 | 34 | 0 | 3 |
| `lib/record.sh` | 723 | 708 | 65 | 85 | 80 | 478 | 15 |
| `lib/render.mjs` | 24 | 24 | 0 | 0 | 0 | 24 | 0 |
| `lib/resolve.sh` | 91 | 87 | 8 | 79 | 0 | 0 | 4 |
| `lib/review.sh` | 5 | 5 | 0 | 5 | 0 | 0 | 0 |
| `lib/scope.sh` | 55 | 55 | 17 | 3 | 6 | 29 | 0 |
| `lib/show.mjs` | 187 | 185 | 46 | 139 | 0 | 0 | 2 |
| `lib/spec.sh` | 19 | 19 | 2 | 5 | 3 | 9 | 0 |
| `lib/status.mjs` | 351 | 349 | 7 | 41 | 168 | 133 | 2 |
| `lib/summary.mjs` | 381 | 379 | 23 | 23 | 26 | 307 | 2 |
| `lib/sync.sh` | 24 | 24 | 19 | 0 | 5 | 0 | 0 |
| `lib/testcount.mjs` | 27 | 27 | 0 | 0 | 0 | 27 | 0 |
| `lib/tmux.sh` | 17 | 16 | 0 | 5 | 9 | 2 | 1 |
| `lib/treekey.mjs` | 66 | 66 | 0 | 12 | 0 | 54 | 0 |
| `lib/version.sh` | 3 | 3 | 0 | 0 | 0 | 3 | 0 |
| `lib/view.mjs` | 203 | 203 | 30 | 27 | 41 | 105 | 0 |
| `lib/xtrace.sh` | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| **all** | **6888** | **6783** | **1008** | **1188** | **1223** | **3364** | **105** |

### Table 3 · check files whose lines all lie inside another's (candidates to merge)

| check file | its lines | inside (smallest first) |
|---|---:|---|
| `04-render-pure-sections-go` | 46 | `93-xtrace`, `31-tmux-l3-03-when`, `69-same-project-starts`, `00-unit-tier`, `84-node-memo`, `23-run-12b-nothing-sets`, and 62 more |
| `06-test-counts-pure-r1` | 51 | `86-fast-gate`, `91-resident-helper`, `93-xtrace`, `31-tmux-l3-03-when`, `69-same-project-starts`, `00-unit-tier`, and 63 more |
| `05-metrics-pure-tokens-cache` | 75 | `00-unit-tier`, `25-run-13b-bs-entry`, `76-entries-survive`, `57-inbox`, `63-question-locations`, `44-lanes-record`, and 3 more |
| `11-deploy-guards-pure-and` | 78 | `12-journal-pure-e4-entrys` |
| `82-key-map-lint` | 93 | `86-fast-gate`, `81-partial-key` |
| `89-night-words` | 101 | `93-xtrace`, `31-tmux-l3-03-when`, `69-same-project-starts`, `00-unit-tier`, `84-node-memo`, `23-run-12b-nothing-sets`, and 61 more |
| `07-step-lint-pure-r3` | 125 | `00-unit-tier`, `84-node-memo` |
| `67-gc-units` | 150 | `49-lanes-slots`, `08-scope-sh-l1-02-run-capped-services-gc-scratch`, `13-run-2-michael-sets-desk` |
| `17-run-8-thin-verify` | 2904 | `61-needs-git` |
| `75-suite-tools` | 2925 | `37-memory-prompts-m2`, `39-memlint-m4`, `29-run-15-resumed-run`, `92-resident-helper-run`, `61-needs-git`, `14-run-2b-stop-records`, and 4 more |
| `25-run-13b-bs-entry` | 2935 | `76-entries-survive`, `08-scope-sh-l1-02-run-capped-services-gc-scratch`, `13-run-2-michael-sets-desk` |
| `18-run-9c-refused-sessions` | 2945 | `15-run-4-same-but-queue-parked-debrief-tmux` |
| `16-run-6-limit-cuts` | 2959 | `76-entries-survive`, `15-run-4-same-but-queue-parked-debrief-tmux` |

### Table 4 · lines run by 20 or more check files (every scenario pays them)

| source file | lines | which |
|---|---:|---|
| `bin/harness` | 100 | 90-92,94,96,98,100,102,104,112-113,126-128,130,133-134,144-145,150,178-180,184,216,307-311,314,316-320,322-324,326-327,330,332,336-340,342-343,345,349-352,354-356,359,361,363-366,368-369,371,373-379,381,385-386,467-470,472-474,481,486-487,498-501,503-507,509,876,878,882 |
| `lib/backlog.mjs` | 40 | 15-17,19-22,25-26,29,31,41,44,62,79,87-89,98,120-122,126-128,135,139,141-142,144-146,174-177,184-185,200,203 |
| `lib/check.sh` | 79 | 39-48,51-57,63,67-68,70-71,77-80,85,88,90-91,99-100,102-104,106-107,109-111,113-114,116,118,122,143,145,166-170,174-176,187,190-191,208,227-230,232-235,237-240,242-243,246,248-249,252-253,255 |
| `lib/cli.mjs` | 24 | 3-6,8,11-16,22-24,26-29,36-39,44-45 |
| `lib/config.sh` | 73 | 13-16,20,23-46,48-53,55-69,71,73-76,83-85,87,89,91-93,98-101,107,118-121,123 |
| `lib/deploy.mjs` | 43 | 7-10,12,14,16-17,22,29,33,43,49-51,53,57-58,60,67,82-84,87-89,93-97,100,102-103,120-127,135 |
| `lib/deploy.sh` | 11 | 5,10-13,16-21 |
| `lib/driver.sh` | 258 | 35,37,39,41,43,45-46,48,50-56,58-59,62-63,71-74,76,90-91,93,96-99,106-115,117-118,120,125-127,129,144-146,148,150-153,155-163,174-178,180,186-187,189-190,196-199,202,228-229,231,233-236,240-241,243,245-251,255-256,258-261,265-266,280,304,306-307,312-315,317-318,320-325,330-332,334-342,345-346,349-350,352-355,358-360,362,365-367,374-376,379-383,387,389-395,403,407,411-414,417-420,425,427,454,465-469,477,481,487-493,496-497,500,502-510,512-515,519-523,526-529,531-535,537-542,547-552,554-556,563-567,569-570,574,577-586,594,597-598,610 |
| `lib/entries.mjs` | 250 | 22-26,28-31,33-36,38,40-41,47-56,58-63,65-69,73-75,77-82,84-86,89,91,93,96-99,103-107,109-112,116,122,124,132-140,143,147-149,153-157,159,161,163-165,168-173,175-187,190-191,197-198,200-202,206-207,211-215,217,221-225,229-232,235-236,238-239,245,261-277,279-281,284-287,293-300,302-307,309-317,323,327-329,334,345-346,355,364,366,371,377,381,391-393,396,398,400-406,408-414,416-422,429-436,438-445,447,450-456,475 |
| `lib/features.mjs` | 228 | 52-55,57-58,60,67-69,75,78-80,87-89,100-107,116-121,129-137,139,143-146,162-163,165,167-168,175-176,210,215-219,221,224-226,230-234,236,240,244-249,251,253,256-266,268-270,275-279,286-290,292-298,300,302-304,308,317,327-330,338-343,347,349,351,353,355-357,360-363,370-373,375-376,380-382,389-398,400-404,407,414-424,428-429,441,443-445,447-449,451,453-458,460-461,468-472,474,476-482,484-488,509-518,523-528,530,532-534,541 |
| `lib/helper.mjs` | 32 | 5,7-9,11,17-19,22-28,32-35,41,43,47-48,50-55,57-58,61 |
| `lib/inbox.mjs` | 62 | 8-9,11,16-21,25-26,31-33,36-37,78,81,86-93,98,101,111,123-129,131,164-172,174,176,186-191,195-197,203-206,214 |
| `lib/lane.sh` | 162 | 17-18,20,22,24,26,28,30-35,38-40,43,45-49,94-103,105-106,108,110-115,119-129,137-142,144-146,150-151,155-156,161,165-168,172,174-175,181-184,186-189,221,226,228-231,242,297,303,320,325,331-342,351-353,356,358-360,365-366,371-372,381,385-388,402-406,408-414,417,419-425,429,447,450,456-458,460-467,480-483,489,494,497-498 |
| `lib/memlint.mjs` | 98 | 15-17,21-26,28,34-38,40-41,45-47,52,55-63,66,71-75,79-80,84,87,95,125-127,137-138,141-142,144-146,149-150,154-165,167,174-176,197,202-206,208-213,216-221,223-224,226-229,231,235-236,238,241 |
| `lib/metrics.mjs` | 123 | 29-30,32-37,39,43-48,51,53-54,58-61,65-66,72-78,80-85,89-91,94-95,97-113,118,121-127,132,137-147,150,155,164,177-180,182,186-188,194,196-197,201,208-210,212-214,218-223,225,229-243,249 |
| `lib/needs.mjs` | 415 | 18-29,32-42,44-45,47-49,52-57,63,70,79-86,88,93,118-124,127,133-139,141,144-145,150-157,161-164,166-173,175-182,184-191,193-195,197,201-205,207-210,214-217,219-222,224-229,231-233,235-240,242-245,247-251,253-261,263-266,270-274,276-283,285-291,293-296,298-301,303-309,311-317,319-325,328-336,341-343,345-349,354-359,364,373-379,381-383,386-387,390-394,396-402,406,412,416-419,427,441-445,447,453-456,460,463,465,468,470-471,474,477,489,494-501,503-515,518-520,526,537-542,545,548-567,569,573-578,580-582,586,599-611,615-617,624-626,628,631-633,636,647-651,654-657,660-662,664-669,672,676-678,711-719,722-728,730-734,736,738,752,779 |
| `lib/needs.sh` | 8 | 6,8,11,15-16,28-30 |
| `lib/notify.mjs` | 24 | 8-10,13,25-26,29-31,33-36,40,46,48-49,59-64,77 |
| `lib/notify.sh` | 28 | 8-9,12-21,24-25,27-34,36,43,49-50,55-56 |
| `lib/overlap.mjs` | 81 | 9-12,14-17,19-20,23-28,35-38,51,56,66,71-73,78-83,88-93,95,99-104,106,108-109,111-115,118,124-129,133,141-149,154,156-158,163,168,172-174,176,182 |
| `lib/parked.mjs` | 15 | 6-10,12,15,24,33,36,39,46,56,74,91 |
| `lib/prompt.sh` | 39 | 8,11-12,29-34,36,47-48,63-64,66-68,70,72-74,76,83-84,90-91,93,96-98,102-103,105,107-110,113,117 |
| `lib/record.sh` | 478 | 10,14,17,20-21,23-24,28-29,34,36-45,50,52-54,60-66,73-74,83-85,88-89,93,99-105,108,114-120,123-128,135-151,153-154,182-183,185-186,189-191,193,197-201,203-204,206-207,213-220,225-226,232-240,243-245,250-252,260-268,270-272,275-279,281-282,286-287,290-292,301-308,310-312,316-318,332,351-354,359,369-371,404,410,415,449,451-452,454-458,460,466-467,469-470,474-477,494-495,517,520-521,527-528,532,541-543,545-548,550,552,554-555,558,560-562,564-565,568-570,579-583,619-624,626,628,630-633,638-639,643-644,647-649,651,653-654,656,658-660,663-665,671-673,676-678,685-689,695,704-706,712,722-728,732,735-741,745-748,753-756,758,761,769-772,781-782,786-788,790-792,794-795,830-837,848-849,851,855-858,868,904,908,910,914-916,927-929,931,934,938-939,942,948,969-970,977,982-987,989,991-993,1008-1010,1013-1018,1024,1026,1030,1034-1035,1041,1043,1053-1058,1061-1067,1070-1074,1080-1081,1085-1087,1095-1097,1100,1105-1106,1115-1118,1122-1123,1129-1131,1141-1145,1147-1149,1151-1152,1155,1160,1162-1165,1167,1169,1178-1181,1191-1193,1203-1210,1218-1219,1225-1228,1233-1234,1237-1241,1247-1249,1252,1259-1262,1270-1272,1284-1285,1288,1294-1298,1300-1306,1310-1311,1314 |
| `lib/render.mjs` | 24 | 9-10,12-13,16-19,21-24,27-35,37-38,41 |
| `lib/scope.sh` | 29 | 11,13,17-18,22,35,42-47,49-50,59-61,66-67,73-75,80-81,92-93,102,121-122 |
| `lib/spec.sh` | 9 | 8-11,26-30 |
| `lib/status.mjs` | 133 | 16-22,24-32,34-35,37,39-40,43-52,55-64,69,71,75-78,84,88-89,91,94-97,100-103,107-109,111,114-118,120-122,127-137,139-141,147,159,161-165,167-170,179,234,242,281-282,300,322,347,370,393-394,397,406,419-424,426-427,431-437,448-450,472-473,484-486,489 |
| `lib/summary.mjs` | 307 | 17-23,25-26,28-33,37-39,42-44,48-53,56-58,62-77,80,86-92,95,99-111,113-114,119-122,127-129,135-138,142,148-152,157-158,164-167,171-172,176,181-183,186,190-192,197-200,205,213-215,217-226,229-232,240-241,245,247-251,253-256,260-263,265-271,273-275,277,284-285,288,291-307,310-312,314-323,325-357,362-364,368,384-392,394,396,398,400-404,406-408,410,412-415,419-420,424-427,429,431-434,436-438,443,464,468,491-497,499-508,510-519,521,533,537-544,549-553,559 |
| `lib/testcount.mjs` | 27 | 4-5,9,11-14,16-23,26,30-32,35-41,44 |
| `lib/tmux.sh` | 2 | 6,11 |
| `lib/treekey.mjs` | 54 | 12-16,20-24,28-30,41,49-55,57,60-63,67-71,75,80-82,84-89,91-96,98,100-101,104-106,109 |
| `lib/version.sh` | 3 | 6-8 |
| `lib/view.mjs` | 105 | 7-9,11-14,16,19-28,31-33,36-38,42-46,48-51,54-55,58-66,68,72-79,82-84,111,146-149,152,154,157-159,164-168,171,176-187,189,192-195,198,203,208-210,214,220,232-234,237-239,246,251,297 |
| **all** | **3364** | |

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
| **all** | **105** | |

In no table: 38 lines no trace can name (what each script runs before its trace starts, its option line to its guard, and `lib/xtrace.sh` itself).

## What the map can't see

- **Run is not asserted on.** A line a check file runs may be a line no check would miss: that is what the mutation
  sample below measures.
- **A check file, not a check.** The sets are per check file; which check of a file runs a line is not recorded.
- **bash numbers multi-line statements its own way** (5.2.21, tried on small scripts; `tests/fixtures/coverage/` holds
  one real trace of each shape). A command continued with `\` is numbered at its first line; a multi-line `[[ … ]]`,
  quoted string or array `=( … )` at its last; a command inside a multi-line `$( … )` one line too high; the commands
  of a `<( … )` that feeds a loop at their function's header line; a trap's commands from line 1. The reducer
  (`shScan`, `shAttribute` in `tests/tools/coverage.mjs`) therefore counts a statement that spans lines as its first
  line (93 such statements hold 252 lines), counts `done < <(…)` under its loop's own line, and drops a number that
  lands on a line with no command instead of giving it to a neighbour (about ten numbers per stub-run file). What
  stays uncertain: the 48 `\` continuation lines that begin with `&&`, `||` or `|` are counted when bash names them,
  which in one shape it also does for the command before; and a command in a multi-line `$( )` numbered one too high
  can land on the next statement, which nearly always ran anyway.
- **The scanner is a guess at bash's grammar** (quotes, parentheses, backslashes, here-documents), not a parser. It
  was read against every statement it believes spans five lines or more and against a sample of Table 5; a statement
  it misreads shows up as lines falsely listed in Table 5, never as lines falsely run.
- **38 lines can't be traced at all**: what each of the twelve scripts runs before its trace starts (its
  `set -…o pipefail` line to its guard) and `lib/xtrace.sh` itself. They are in no table.
- **A node line is run when any part of it ran.** `const f = x => …` on one line is run once its module loads, called
  or not; a branch never taken on a line that ran is not seen. The 500 lines only ever run in part are listed; the
  mutation sample marks a mutant on a partial line.
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
- `_line-counts.txt`: `<file>:<line> <how many check files run it>` for each of the 6,783 lines.
- `_partial-only.txt`: the 500 node lines no check file runs whole.

`node tests/tools/coverage.mjs covering <sets dir> <file> <line>` names the check files that run a line.
