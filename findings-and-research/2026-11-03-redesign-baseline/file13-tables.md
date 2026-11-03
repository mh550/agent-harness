| script | subcommand | caller | count | CPU-s |
|---|---|---|---|---|
| `lib/metrics.mjs` | `usage` | lane (`lib/lane.sh`) | 104 | 2.80 |
| `lib/treekey.mjs` | `--partial` | lane (`lib/check.sh`) | 82 | 2.21 |
| `lib/metrics.mjs` | `limit` | lane (`lib/lane.sh`) | 82 | 2.21 |
| `lib/testcount.mjs` | – | lane (`lib/check.sh`) | 78 | 2.10 |
| `lib/treekey.mjs` | – | lane (`lib/lane.sh`) | 77 | 2.07 |
| `lib/testcount.mjs` | – | lane (`lib/lane.sh`) | 72 | 1.94 |
| `lib/features.mjs` | `passes` | lane (`lib/lane.sh`) | 57 | 1.53 |
| `lib/inbox.mjs` | `answers` | lane (`lib/lane.sh`) | 56 | 1.51 |
| `lib/metrics.mjs` | `final` | lane (`lib/lane.sh`) | 55 | 1.48 |
| `lib/memlint.mjs` | `store-line` | lane (`lib/lane.sh`) | 52 | 1.40 |
| `lib/render.mjs` | – | lane (`lib/lane.sh`) | 52 | 1.40 |
| `lib/features.mjs` | `unpark` | lane (`lib/lane.sh`) | 51 | 1.37 |
| `lib/needs.mjs` | `sweep` | lane (`lib/lane.sh`) | 51 | 1.37 |
| `lib/features.mjs` | `poll` | lane (`lib/lane.sh`) | 51 | 1.37 |
| `node` | `-e (inline)` | stub (`tests/stub-claude.sh`) | 48 | 1.29 |
| `lib/entries.mjs` | `ingest` | lane (`lib/lane.sh`) | 47 | 1.26 |
| `lib/entries.mjs` | `render` | lane (`lib/lane.sh`) | 47 | 1.26 |
| `lib/metrics.mjs` | `append` | lane (`lib/lane.sh`) | 47 | 1.26 |
| `lib/treekey.mjs` | `--partial` | lane (`lib/lane.sh`) | 46 | 1.24 |
| `lib/entries.mjs` | `pack` | lane (`lib/lane.sh`) | 46 | 1.24 |
| `lib/entries.mjs` | `validate` | lane (`lib/lane.sh`) | 46 | 1.24 |
| `lib/metrics.mjs` | `usage` | driver (`lib/driver.sh`) | 44 | 1.18 |
| `lib/needs.mjs` | `sweep` | driver (`lib/driver.sh`) | 42 | 1.13 |
| `lib/features.mjs` | `snapshot` | lane (`lib/lane.sh`) | 40 | 1.08 |
| `lib/treekey.mjs` | – | driver (`lib/driver.sh`) | 34 | 0.91 |
| `lib/testcount.mjs` | – | driver (`lib/driver.sh`) | 32 | 0.86 |
| `lib/notify.mjs` | `urls` | driver (`lib/driver.sh`) | 32 | 0.86 |
| `lib/features.mjs` | `milestones` | driver (`lib/driver.sh`) | 31 | 0.83 |
| `lib/features.mjs` | `bump` | lane (`lib/lane.sh`) | 30 | 0.81 |
| `lib/inbox.mjs` | `repair` | lane (`lib/lane.sh`) | 30 | 0.81 |
| `lib/inbox.mjs` | `question` | lane (`lib/lane.sh`) | 30 | 0.81 |
| `lib/memlint.mjs` | `gotchas` | lane (`lib/lane.sh`) | 30 | 0.81 |
| `lib/features.mjs` | `repair` | lane (`lib/lane.sh`) | 30 | 0.81 |
| `lib/needs.mjs` | `list` | cli (`bin/harness`) | 30 | 0.81 |
| `lib/features.mjs` | `lanes` | driver (`lib/driver.sh`) | 29 | 0.78 |
| `lib/features.mjs` | `deps` | driver (`lib/driver.sh`) | 28 | 0.75 |
| `lib/notify.mjs` | `urls` | lane (`lib/lane.sh`) | 28 | 0.75 |
| `lib/features.mjs` | `kind` | lane (`lib/lane.sh`) | 27 | 0.73 |
| `lib/metrics.mjs` | `summary` | driver (`lib/driver.sh`) | 26 | 0.70 |
| `lib/summary.mjs` | `build` | driver (`lib/driver.sh`) | 24 | 0.65 |
| `lib/summary.mjs` | `report` | driver (`lib/driver.sh`) | 24 | 0.65 |
| `lib/features.mjs` | `pass` | lane (`lib/lane.sh`) | 23 | 0.62 |
| `lib/treekey.mjs` | `--partial` | driver (`lib/check.sh`) | 22 | 0.59 |
| `lib/testcount.mjs` | – | driver (`lib/check.sh`) | 22 | 0.59 |
| `lib/memlint.mjs` | `store-line` | driver (`lib/driver.sh`) | 22 | 0.59 |
| `lib/render.mjs` | – | driver (`lib/driver.sh`) | 22 | 0.59 |
| `lib/metrics.mjs` | `final` | driver (`lib/driver.sh`) | 22 | 0.59 |
| `lib/metrics.mjs` | `append` | driver (`lib/driver.sh`) | 22 | 0.59 |
| `lib/features.mjs` | `summary` | lane (`lib/lane.sh`) | 22 | 0.59 |
| `lib/status.mjs` | `card` | cli (`bin/harness`) | 22 | 0.59 |
| `lib/features.mjs` | `summary` | driver (`lib/driver.sh`) | 20 | 0.54 |
| `lib/features.mjs` | `unparks` | driver (`lib/driver.sh`) | 18 | 0.48 |
| `lib/features.mjs` | `milestone-done` | driver (`lib/driver.sh`) | 18 | 0.48 |
| `lib/features.mjs` | `models` | lane (`lib/lane.sh`) | 18 | 0.48 |
| `lib/inbox.mjs` | `answers` | driver (`lib/driver.sh`) | 17 | 0.46 |
| `lib/features.mjs` | `ids` | lane (`lib/lane.sh`) | 17 | 0.46 |
| `lib/features.mjs` | `repair-verify` | lane (`lib/lane.sh`) | 16 | 0.43 |
| `lib/features.mjs` | `model` | cli (`lib/desk.sh`) | 16 | 0.43 |
| `lib/render.mjs` | – | cli (`lib/desk.sh`) | 16 | 0.43 |
| `lib/features.mjs` | `models` | driver (`lib/driver.sh`) | 14 | 0.38 |
| `lib/features.mjs` | `unpass` | lane (`lib/lane.sh`) | 14 | 0.38 |
| `lib/features.mjs` | `ids` | driver (`lib/driver.sh`) | 14 | 0.38 |
| `lib/overlap.mjs` | `runs` | cli (`bin/harness`) | 12 | 0.32 |
| `lib/memlint.mjs` | – | driver (`timeout`) | 12 | 0.32 |
| `lib/backlog.mjs` | `list` | driver (`lib/driver.sh`) | 12 | 0.32 |
| `lib/summary.mjs` | `suite-runs` | driver (`lib/driver.sh`) | 12 | 0.32 |
| `lib/metrics.mjs` | `limit` | driver (`lib/driver.sh`) | 12 | 0.32 |
| `lib/summary.mjs` | `ledger-line` | driver (`lib/driver.sh`) | 12 | 0.32 |
| `lib/features.mjs` | `evidence` | lane (`lib/lane.sh`) | 11 | 0.30 |
| `lib/features.mjs` | `milestones` | lane (`lib/lane.sh`) | 11 | 0.30 |
| `lib/features.mjs` | `deps` | lane (`lib/lane.sh`) | 11 | 0.30 |
| `lib/metrics.mjs` | `summary` | lane (`lib/lane.sh`) | 11 | 0.30 |
| `lib/features.mjs` | `poll` | driver (`lib/driver.sh`) | 11 | 0.30 |
| `lib/needs.mjs` | `open` | lane (`lib/lane.sh`) | 11 | 0.30 |
| `lib/deploy.mjs` | `slug` | driver (`lib/driver.sh`) | 10 | 0.27 |
| `lib/deploy.mjs` | `status` | driver (`lib/driver.sh`) | 10 | 0.27 |
| `lib/treekey.mjs` | `--partial` | driver (`lib/driver.sh`) | 10 | 0.27 |
| `lib/summary.mjs` | `calibration` | driver (`lib/driver.sh`) | 10 | 0.27 |
| `lib/inbox.mjs` | `repair` | driver (`lib/driver.sh`) | 10 | 0.27 |
| `lib/entries.mjs` | `validate` | driver (`lib/driver.sh`) | 10 | 0.27 |
| `lib/entries.mjs` | `ingest` | driver (`lib/driver.sh`) | 10 | 0.27 |
| `lib/entries.mjs` | `render` | driver (`lib/driver.sh`) | 10 | 0.27 |
| `lib/features.mjs` | `lint` | driver (`lib/driver.sh`) | 10 | 0.27 |
| `lib/features.mjs` | `undeclared` | driver (`lib/driver.sh`) | 10 | 0.27 |
| `lib/needs.mjs` | `fields` | lane (`lib/lane.sh`) | 10 | 0.27 |
| `lib/notify.mjs` | `actions` | lane (`lib/lane.sh`) | 10 | 0.27 |
| `lib/features.mjs` | `summary` | cli (`lib/debrief.sh`) | 10 | 0.27 |
| `lib/summary.mjs` | `flakers` | cli (`lib/debrief.sh`) | 10 | 0.27 |
| `lib/entries.mjs` | `questions` | cli (`lib/debrief.sh`) | 10 | 0.27 |
| `lib/needs.mjs` | `sweep` | cli (`bin/harness`) | 8 | 0.22 |
| `lib/metrics.mjs` | `session-id` | lane (`lib/lane.sh`) | 5 | 0.13 |
| `lib/metrics.mjs` | `cost` | lane (`lib/lane.sh`) | 5 | 0.13 |
| `lib/metrics.mjs` | `append-resume` | lane (`lib/lane.sh`) | 5 | 0.13 |
| `lib/inbox.mjs` | `insert` | lane (`lib/lane.sh`) | 5 | 0.13 |
| `lib/features.mjs` | `unbump` | lane (`lib/lane.sh`) | 5 | 0.13 |
| `lib/features.mjs` | `park` | lane (`lib/lane.sh`) | 5 | 0.13 |
| `lib/entries.mjs` | `session-files` | lane (`lib/lane.sh`) | 5 | 0.13 |
| `lib/features.mjs` | `milestone` | lane (`lib/lane.sh`) | 5 | 0.13 |
| `lib/notify.mjs` | `actions` | driver (`lib/driver.sh`) | 5 | 0.13 |
| `lib/features.mjs` | `grant` | lane (`lib/lane.sh`) | 3 | 0.08 |
| `lib/features.mjs` | `summary` | tests/lib.sh (`tests/checks/13-run-2-michael-sets-desk.sh`) | 3 | 0.08 |
| `lib/parked.mjs` | `report` | cli (`bin/harness`) | 3 | 0.08 |
| `lib/notify.mjs` | `urls` | cli (`lib/desk.sh`) | 3 | 0.08 |
| `lib/features.mjs` | `milestone-done` | lane (`lib/lane.sh`) | 2 | 0.05 |
| `lib/summary.mjs` | `build` | cli (`bin/harness`) | 2 | 0.05 |
| `lib/summary.mjs` | `report` | cli (`bin/harness`) | 2 | 0.05 |
| `lib/summary.mjs` | `trends` | cli (`bin/harness`) | 2 | 0.05 |
| `lib/status.mjs` | `queue` | cli (`bin/harness`) | 2 | 0.05 |
| `lib/backlog.mjs` | `list` | cli (`lib/debrief.sh`) | 2 | 0.05 |
| `lib/features.mjs` | `model` | cli (`lib/debrief.sh`) | 2 | 0.05 |
| `lib/render.mjs` | – | cli (`lib/debrief.sh`) | 2 | 0.05 |
| `lib/metrics.mjs` | `limit` | cli (`lib/debrief.sh`) | 2 | 0.05 |
| `lib/metrics.mjs` | `final` | cli (`lib/debrief.sh`) | 2 | 0.05 |
| `lib/page.mjs` | – | cli (`lib/debrief.sh`) | 2 | 0.05 |
| `lib/features.mjs` | `model` | tests/lib.sh (`lib/prompt.sh`) | 1 | 0.03 |
| `lib/treekey.mjs` | – | tests/lib.sh (`lib/prompt.sh`) | 1 | 0.03 |
| `lib/memlint.mjs` | `store-line` | tests/lib.sh (`lib/prompt.sh`) | 1 | 0.03 |
| `lib/render.mjs` | – | tests/lib.sh (`lib/prompt.sh`) | 1 | 0.03 |
| `lib/summary.mjs` | `report` | tests/lib.sh (`tests/checks/13-run-2-michael-sets-desk.sh`) | 1 | 0.03 |
| `lib/features.mjs` | `next` | driver (`lib/driver.sh`) | 1 | 0.03 |
| `lib/features.mjs` | `unpark` | driver (`lib/driver.sh`) | 1 | 0.03 |
| `lib/features.mjs` | `model` | tests/lib.sh (`tests/checks/13-run-2-michael-sets-desk.sh`) | 1 | 0.03 |
| `lib/features.mjs` | `reset` | cli (`bin/harness`) | 1 | 0.03 |
| `lib/needs.mjs` | `open` | driver (`lib/driver.sh`) | 1 | 0.03 |
| `lib/needs.mjs` | `fields` | driver (`lib/driver.sh`) | 1 | 0.03 |

| program | driver | lane | cli | stub | tests/lib.sh | ? | all |
|---|---|---|---|---|---|---|---|
| node | 759 | 1674 | 161 | 48 | 9 | 0 | 2651 |
| git | 2528 | 3002 | 1352 | 552 | 320 | 0 | 7754 |
| date | 978 | 1272 | 140 | 0 | 20 | 0 | 2410 |
| cat | 1515 | 432 | 588 | 771 | 72 | 0 | 3378 |
| bash | 142 | 288 | 177 | 809 | 2 | 1 | 1419 |

Top five by execs × unit cost:
1. lib/features.mjs (all subcommands) · lane · lib/lane.sh: 449 × → 12.08 CPU-s
2. lib/metrics.mjs (all subcommands) · lane · lib/lane.sh: 314 × → 8.45 CPU-s
3. lib/features.mjs (all subcommands) · driver · lib/driver.sh: 205 × → 5.51 CPU-s
4. lib/entries.mjs (all subcommands) · lane · lib/lane.sh: 191 × → 5.14 CPU-s
5. lib/metrics.mjs (all subcommands) · driver · lib/driver.sh: 126 × → 3.39 CPU-s
6. lib/treekey.mjs (all subcommands) · lane · lib/lane.sh: 123 × → 3.31 CPU-s
7. lib/inbox.mjs (all subcommands) · lane · lib/lane.sh: 121 × → 3.25 CPU-s
8. lib/treekey.mjs (all subcommands) · lane · lib/check.sh: 82 × → 2.21 CPU-s
