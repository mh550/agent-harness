# Fewer node starts: where a stub run's process starts come from, and the cuts C1 makes

*(2026-11-03, run `agent-harness-2026-11-03`, C1-01 (the finding); C1-02 and C1-03 write the choice, C1-04 the
before/after rows; spec `docs/specs/2026-10-31-suite-cpu.md` C1 fix 6; plan `docs/plans/2026-11-03-C1-suite-cpu.md`)*

## Finding

**How it was measured.** `KEEP=1 bash tests/run.sh 13-run-2-michael-sets-desk` (66/66, 186.0 s, kept `$T`
`/tmp/tmp.udNNEx7iBD`), then that file's first `harness start` by hand in the kept `$T`: suite_setup's exports
(`tests/lib.sh`), every `HARNESS_*`/`STUB_*` of the measuring session unset first, `harness start "$T/proj" demo-t
--spec SPEC.md --brief "only A–C" --foreground` (`demo` existed; the load curve's §4 did the same). Twice: once under
`/usr/bin/time -v strace -f -s 512 -e trace=execve,clone,clone3,fork,vfork` (the trace), once under `time -v` alone
(the wall and CPU; strace doubles both). Files in the session's scratch
(`/tmp/harness/agent-harness/agent-harness-2026-11-03/lanes/C1`): `execs.strace`, `stubstart.out`, `stubstart.time`
(under strace), `stubstart-plain.out`, `stubstart-plain.time`; the parser and its output are kept in
`findings-and-research/2026-11-03-exec-table/`. As a cross-check, the whole of file 13 was traced the same way
(`bash tests/checks/13-run-2-michael-sets-desk.sh`, 66/66; `file13.strace`, `file13.time`).

**Caller.** An exec's caller is the image its process ran before the exec (a `$( … )` or `< <( … )` subshell carries
its parent's: `lib/lane.sh`, `lib/driver.sh`), and its class the nearest image up the fork chain that is
`tests/stub-*.sh` (**stub**), `lib/lane.sh` (**lane**), `lib/driver.sh` (**driver**), `bin/harness` or another
`lib/*.sh` run as its own process (**cli**: `harness status`, `desk`, `debrief`, the start's own `bin/harness` before
it execs the driver) or a check file (**tests/lib.sh**: the checks' own lines). `lib/check.sh`, `lib/prompt.sh` and
`git` are attributed through (a lane's `check.sh` is the lane's), and the row names the script that started node.
In the one start the only **cli** image is the start's own `bin/harness` before it execs `lib/driver.sh` (1 node, 41
git, 3 cat, 1 bash), so its tables count it as the driver. CPU-s is count × 26.9 ms
(`node -e 0` on the idle box, `findings-and-research/2026-10-30-suite-load-curve/unit-cost.txt`).

**The one start.** Wall 19.0 s, user 12.93 s + sys 7.51 s = **20.44 CPU-s** (`stubstart-plain.time`; under strace
36.8 s and 40.5 CPU-s). 4,110 successful execs; **402 node starts = 10.8 CPU-s, 53 % of the start's CPU.** The run:
the initializer, three features in two milestones, five coding sessions (A, B, A, C, C),
three verifies (M1 twice, M2), two merges, the retro.

| script | subcommand | caller | count | CPU-s |
|---|---|---|---|---|
| `lib/features.mjs` | `passes` | lane (`lib/lane.sh`) | 22 | 0.59 |
| `lib/features.mjs` | `model` | lane (`lib/lane.sh`) | 17 | 0.46 |
| `lib/metrics.mjs` | `usage` | lane (`lib/lane.sh`) | 16 | 0.43 |
| `lib/treekey.mjs` | `--partial` | lane (`lib/check.sh`) | 15 | 0.40 |
| `lib/features.mjs` | `milestone-done` | lane (`lib/lane.sh`) | 14 | 0.38 |
| `lib/testcount.mjs` | – | lane (`lib/check.sh`) | 13 | 0.35 |
| `lib/treekey.mjs` | – | lane (`lib/lane.sh`) | 13 | 0.35 |
| `lib/metrics.mjs` | `limit` | lane (`lib/lane.sh`) | 13 | 0.35 |
| `lib/testcount.mjs` | – | lane (`lib/lane.sh`) | 11 | 0.30 |
| `node` | `-e (inline)` | stub (`tests/stub-claude.sh`) | 10 | 0.27 |
| `lib/metrics.mjs` | `final` | lane (`lib/lane.sh`) | 9 | 0.24 |
| `lib/features.mjs` | `ids` | lane (`lib/lane.sh`) | 9 | 0.24 |
| `lib/inbox.mjs` | `answers` | lane (`lib/lane.sh`) | 8 | 0.22 |
| `lib/features.mjs` | `unpark` | lane (`lib/lane.sh`) | 8 | 0.22 |
| `lib/needs.mjs` | `sweep` | lane (`lib/lane.sh`) | 8 | 0.22 |
| `lib/treekey.mjs` | `--partial` | lane (`lib/lane.sh`) | 8 | 0.22 |
| `lib/entries.mjs` | `pack` | lane (`lib/lane.sh`) | 8 | 0.22 |
| `lib/features.mjs` | `snapshot` | lane (`lib/lane.sh`) | 8 | 0.22 |
| `lib/memlint.mjs` | `store-line` | lane (`lib/lane.sh`) | 8 | 0.22 |
| `lib/render.mjs` | – | lane (`lib/lane.sh`) | 8 | 0.22 |
| `lib/entries.mjs` | `validate` | lane (`lib/lane.sh`) | 8 | 0.22 |
| `lib/entries.mjs` | `ingest` | lane (`lib/lane.sh`) | 8 | 0.22 |
| `lib/entries.mjs` | `render` | lane (`lib/lane.sh`) | 8 | 0.22 |
| `lib/metrics.mjs` | `append` | lane (`lib/lane.sh`) | 8 | 0.22 |
| `lib/features.mjs` | `model` | driver (`lib/driver.sh`) | 7 | 0.19 |
| `lib/features.mjs` | `summary` | driver (`lib/driver.sh`) | 7 | 0.19 |
| `lib/features.mjs` | `milestones` | driver (`lib/driver.sh`) | 7 | 0.19 |
| `lib/features.mjs` | `summary` | lane (`lib/lane.sh`) | 7 | 0.19 |
| `lib/features.mjs` | `next` | lane (`lib/lane.sh`) | 5 | 0.13 |
| `lib/features.mjs` | `kind` | lane (`lib/lane.sh`) | 5 | 0.13 |
| `lib/features.mjs` | `bump` | lane (`lib/lane.sh`) | 5 | 0.13 |
| `lib/inbox.mjs` | `repair` | lane (`lib/lane.sh`) | 5 | 0.13 |
| `lib/inbox.mjs` | `question` | lane (`lib/lane.sh`) | 5 | 0.13 |
| `lib/memlint.mjs` | `gotchas` | lane (`lib/lane.sh`) | 5 | 0.13 |
| `lib/features.mjs` | `repair` | lane (`lib/lane.sh`) | 5 | 0.13 |
| `lib/metrics.mjs` | `usage` | driver (`lib/driver.sh`) | 4 | 0.11 |
| `lib/needs.mjs` | `sweep` | driver (`lib/driver.sh`) | 4 | 0.11 |
| `lib/features.mjs` | `pass` | lane (`lib/lane.sh`) | 4 | 0.11 |
| `lib/testcount.mjs` | – | driver (`lib/driver.sh`) | 3 | 0.08 |
| `lib/treekey.mjs` | – | driver (`lib/driver.sh`) | 3 | 0.08 |
| `lib/inbox.mjs` | `answers` | driver (`lib/driver.sh`) | 3 | 0.08 |
| `lib/features.mjs` | `unpark` | driver (`lib/driver.sh`) | 3 | 0.08 |
| `lib/features.mjs` | `lanes` | driver (`lib/driver.sh`) | 3 | 0.08 |
| `lib/features.mjs` | `repair-verify` | lane (`lib/lane.sh`) | 3 | 0.08 |
| `lib/features.mjs` | `unpass` | lane (`lib/lane.sh`) | 3 | 0.08 |
| `lib/treekey.mjs` | `--partial` | driver (`lib/check.sh`) | 2 | 0.05 |
| `lib/testcount.mjs` | – | driver (`lib/check.sh`) | 2 | 0.05 |
| `lib/memlint.mjs` | `store-line` | driver (`lib/driver.sh`) | 2 | 0.05 |
| `lib/render.mjs` | – | driver (`lib/driver.sh`) | 2 | 0.05 |
| `lib/metrics.mjs` | `final` | driver (`lib/driver.sh`) | 2 | 0.05 |
| `lib/metrics.mjs` | `append` | driver (`lib/driver.sh`) | 2 | 0.05 |
| `lib/notify.mjs` | `urls` | driver (`lib/driver.sh`) | 2 | 0.05 |
| `lib/features.mjs` | `deps` | driver (`lib/driver.sh`) | 2 | 0.05 |
| `lib/features.mjs` | `milestone-done` | driver (`lib/driver.sh`) | 2 | 0.05 |
| `lib/features.mjs` | `evidence` | lane (`lib/lane.sh`) | 2 | 0.05 |
| `lib/features.mjs` | `milestones` | lane (`lib/lane.sh`) | 2 | 0.05 |
| `lib/features.mjs` | `deps` | lane (`lib/lane.sh`) | 2 | 0.05 |
| `lib/metrics.mjs` | `summary` | lane (`lib/lane.sh`) | 2 | 0.05 |
| `lib/summary.mjs` | `build` | driver (`lib/driver.sh`) | 2 | 0.05 |
| `lib/summary.mjs` | `report` | driver (`lib/driver.sh`) | 2 | 0.05 |
| `lib/overlap.mjs` | `runs` | driver (`bin/harness`) | 1 | 0.03 |
| `lib/deploy.mjs` | `slug` | driver (`lib/driver.sh`) | 1 | 0.03 |
| `lib/deploy.mjs` | `status` | driver (`lib/driver.sh`) | 1 | 0.03 |
| `lib/memlint.mjs` | – | driver (`timeout`) | 1 | 0.03 |
| `lib/treekey.mjs` | `--partial` | driver (`lib/driver.sh`) | 1 | 0.03 |
| `lib/summary.mjs` | `calibration` | driver (`lib/driver.sh`) | 1 | 0.03 |
| `lib/inbox.mjs` | `repair` | driver (`lib/driver.sh`) | 1 | 0.03 |
| `lib/entries.mjs` | `validate` | driver (`lib/driver.sh`) | 1 | 0.03 |
| `lib/entries.mjs` | `ingest` | driver (`lib/driver.sh`) | 1 | 0.03 |
| `lib/entries.mjs` | `render` | driver (`lib/driver.sh`) | 1 | 0.03 |
| `lib/features.mjs` | `lint` | driver (`lib/driver.sh`) | 1 | 0.03 |
| `lib/features.mjs` | `undeclared` | driver (`lib/driver.sh`) | 1 | 0.03 |
| `lib/features.mjs` | `grant` | lane (`lib/lane.sh`) | 1 | 0.03 |
| `lib/metrics.mjs` | `summary` | driver (`lib/driver.sh`) | 1 | 0.03 |
| `lib/backlog.mjs` | `list` | driver (`lib/driver.sh`) | 1 | 0.03 |
| `lib/metrics.mjs` | `limit` | driver (`lib/driver.sh`) | 1 | 0.03 |
| `lib/features.mjs` | `next` | driver (`lib/driver.sh`) | 1 | 0.03 |
| `lib/summary.mjs` | `ledger-line` | driver (`lib/driver.sh`) | 1 | 0.03 |

Beside it, by class (the same start):

| program | driver | lane | stub | tests/lib.sh | all |
|---|---|---|---|---|---|
| node | 83 | 309 | 10 | 0 | 402 |
| git | 250 | 481 | 104 | 0 | 835 |
| date | 105 | 223 | 0 | 0 | 328 |
| cat | 224 | 70 | 125 | 0 | 419 |
| bash | 14 | 55 | 110 | 0 | 179 |

`git`'s 835 execs cost about 0.9 s (1.1 ms each), `date`'s 328 and `cat`'s 419 about 0.6 s together (0.8 ms each):
node is 53 % of the start's CPU, git 4 %, date and cat 3 %.

**Top five callers** by execs × unit cost (node 26.9 ms, git 1.1 ms, `cat`/`date` 0.8 ms; a lane's `check.sh` counted
with the lane), the one start:

1. `lib/features.mjs` in the lane: 122 starts, 3.28 CPU-s (`passes` 22, `model` 17, `milestone-done` 14, `ids` 9,
   `unpark` 8, `snapshot` 8, `summary` 7, …)
2. `lib/metrics.mjs` in the lane: 48 starts, 1.29 CPU-s (`usage` 16, `limit` 13, `final` 9, `append` 8, `summary` 2)
3. `lib/treekey.mjs` in the lane: 36 starts, 0.97 CPU-s (`--partial` 15 in `check.sh` and 8 in `lib/record.sh`'s init
   path before the suite, the plain key 13 in `tests_end` and the prompt's `suite_length`)
4. `lib/features.mjs` in the driver: 34 starts, 0.91 CPU-s (`model` 7, `summary` 7, `milestones` 7, `lanes` 3,
   `unpark` 3, …)
5. `lib/entries.mjs` in the lane: 32 starts, 0.86 CPU-s (`validate`, `ingest`, `render`, `pack`: 8 each, one per
   session)

No `git`, `date` or `cat` row is near the top five: the largest, `git` in the lane (481 execs), is 0.53 CPU-s; the
driver's `cat` (221) 0.18 CPU-s; the lane's `date` (223) 0.18 CPU-s.

**The whole file (the cross-check).** File 13 traced end to end: 35,647 successful execs, **3,139 node starts** (the
load curve's §3 counted 3,138), 84.4 CPU-s of node. Run again without strace (`file13-plain.time`): 185.0 s wall,
user 107.12 + sys 63.48 = 170.6 CPU-s, so **node is 49 % of the file's CPU**. By class:

| program | driver | lane | cli | stub | tests/lib.sh | ? | all |
|---|---|---|---|---|---|---|---|
| node | 975 | 1945 | 162 | 48 | 9 | 0 | 3139 |
| git | 2528 | 3002 | 1352 | 552 | 320 | 0 | 7754 |
| date | 984 | 1272 | 140 | 0 | 16 | 0 | 2412 |
| cat | 1557 | 432 | 590 | 771 | 72 | 0 | 3422 |
| bash | 142 | 288 | 177 | 809 | 2 | 1 | 1419 |

The driver and its lanes start **2,920 of the 3,139** (93 %, 78.5 CPU-s); the harness CLI that checks call
(`status.mjs card` 22, `needs.mjs list` 30, the debrief's and desk's reads) 162; the stub 48 (`node -e` in
`tests/stub-claude.sh`, its list edits); the checks' own lines 9 (`$F summary` 3, a rendered prompt 4, `summary.mjs
report` 1, `$F model` 1). So the falsifier the spec names (node starts that are the stub's or the checks') does not
hold for this file: the cut is in `lib/`. The file's top five are the start's in a different order: `features.mjs` in
the lane 720 (19.4 CPU-s: `passes` 125, `model` 90, `milestone-done` 83, `unpark` 51, `ids` 49, `snapshot` 47,
`summary` 41, `next` 35, …), `features.mjs` in the driver 420 (11.3: `summary` 91, `milestones` 77, `model` 76,
`deps` 32, `unpark` 30, `lanes` 29, `next` 19, `milestone-done` 18, …), `metrics.mjs` in the lane 314 (8.4: `usage`
104, `limit` 82, `final` 55, `append` 47), `treekey.mjs` in the lane 205 (5.5: `--partial` 128, plain 77), `entries.mjs`
in the lane 191 (5.1). `treekey.mjs --names` ran **0** times in the file (check.sh's partial path never ran), and
`inbox.mjs answers` 86 (56 lane, 30 driver: 2.3 CPU-s), seventh.

## Choice

*(C1-03 adds the poll subcommand, the treekey merge and the builtins here, each marked *default*; C1-04 the before and
after rows. The order they cut in, from the finding above, is the plan's: `docs/plans/2026-11-03-C1-suite-cpu.md`.)*

**The memo (C1-02, *default*).** `lib/record.sh`'s `F` answers a pure `features.mjs` subcommand from a bash
associative array (`F_MEMO`, the exit codes in `F_MRC`) that lives in the process only: no file under the state dir,
the scratch or a cache. The key is `<sub>` and each argument joined by `\x1f`, an argument in a file position replaced
by `#<sha1 of the file's content>` (`sha1sum`; `-` when it can't be read): never its path, its mtime or the clock.

- **Memoized**: `model` (the key is the alias; `features.mjs models` fills every alias at once, called by `run_paths`
  in the driver's and each lane's own shell; a `claude-…` id is answered by bash as `modelId` would), and, on the list's
  hash plus the other arguments, `summary`, `milestones`, `snapshot`, `undeclared`, `lint`, `passes`,
  `milestone-done`, `ids`, `deps`, `kind`, `milestone`; `next` and `blocked` also on `attempts.json`'s and
  `parked.json`'s hashes, `parked` on both its files', `evidence` on `progress.md`'s; `unpark` on `parked.json`'s hash
  and the answers, **stored only when it printed nothing** (one that unparked rewrote the file, so the after-hash
  below refuses it too; the rule holds should a writer put the bytes back in between); `answers_hash`
  (`inbox.mjs answers`) on `INBOX.md`'s hash, the same way.
- **Stored** only with an exit code that is an answer (0; 1 for `passes`, `milestone-done`, `evidence`, `lint`;
  a throw in `features.mjs` now exits 70, never 1, so a crash is not kept as "doesn't pass"), only in the shell that
  sourced `lib/record.sh` (`F_MEMO_PID`: a subshell's miss runs node straight, as before, since it couldn't keep the
  entry), and only when the files hash after the start as they did before it (another process's write in between is a miss next
  time, never a stale hit). A hit prints the stored stdout byte for byte (trailing newlines kept) and returns the
  stored code; stderr is not stored (an answer code with output on stderr is node's own error, the same on the same
  content).
- **Not memoized**, node every time: `lanes` (the state dir), `park`, `bump`, `unbump`, `grant`, `reset`, `repair`,
  `repair-verify`, `pass`, `unpass`, and every other script (`MET`, `entries.mjs`, `inbox.mjs insert|repair|question`,
  `notify.mjs`, `needs.mjs`, `treekey.mjs`).
- **The shell it lives in.** bash 5.2 has no current-shell command substitution: an entry stored inside `$( … )`, `<
  <( … )` or a pipeline dies with it, but a subshell reads its parent's. `Fv <var> <sub> <args…>` answers into a
  variable in the current shell (`printf -v`, trailing newlines cut as `$( )` cuts them); C1-02 moved the busiest
  `$(F …)` sites that sit on no `note "` line to it or to a condition in the current shell: `lib/lane.sh`'s `next`,
  `kind` and its verify's `ids` and `milestone-done`, `lib/driver.sh`'s `milestones` in `rebase_due` and
  `deadline_verify`, `lib/record.sh`'s `milestones` and `deps` in `merge_milestones_`. The coordinator's idle poll
  (`F unpark`, `answers_hash`, `F lanes` in their subshells) is C1-03's.

**The poll, the idle coordinator and the treekey merge (C1-03, each *default*).**

- **`features.mjs poll <list> <att> <max> <parked> [<m>]`** prints `summary\t…`, `parked\t…`, `blocked\t…`,
  `next\t…` and, with a lane, `milestone-done\t<its exit code>`: what the five subcommands print for those arguments,
  composed from the same exported functions (`summaryLine`, `parkedLines`, `blockedLines`, `nextLine`,
  `milestoneDone`, `pollLines`); the five stay. `F poll` is memoized as `next` is (the list's, `attempts.json`'s and
  `parked.json`'s hashes), and a stored answer fills the memo for the five under the keys `f_key` gives them
  (`f_poll_seed`), so a `$(F summary …)` on a `note "` line, which C1 may not change, hits it. The coordinator's end
  check runs it once in its own shell, output dropped, and its `F summary`, `F parked`, `F blocked` and `F next` lines,
  as they were before C1, hit the memo it filled (Updated in place 2026-11-03: was read with `mapfile` and parsed by
  label; C1-06's review simplified it, `docs/plans/2026-11-03-C1-review.md`); the lane loop asks it once per iteration
  before `F milestone-done` and `Fv next` (and the `parked`/`blocked` of a lane with nothing left).
- **The idle poll starts node once**, `needs.mjs sweep` (it writes `needs.md`: stays). `unpark_warm` runs in the
  coordinator's own shell before the unchanged `for id in $(record F unpark … "$(answers_hash)")` line: `answers_v`
  keeps `answers_hash`'s entry, and a new pure `unparks` (the ids `unpark` would remove, no write, memoized) that
  finds none fills `unpark`'s entry with the empty answer under the same `parked.json` hash; with something to un-park
  it fills nothing, so that line's `unpark` runs node, un-parks and notes as before. `F lanes` becomes `lanes_v`, the
  coordinator's alone: memoized on the list's, `attempts.json`'s and `parked.json`'s hashes, the max, the state dir and
  a fingerprint of all `laneState` reads (for `default` and each milestone: `verified-<m>`, `needs-<m>`, a non-empty
  `lanes/<m>/review-escalate`, `lanes/<m>/pid` and whether `/proc/<pid>` exists, node's `kill 0` with EPERM alive;
  then `meta.env`'s lines). A pid file that isn't one number is no key (node reads it with `Number()`, `0x1` is 1):
  node every time. Stored only when the key is the same after the start, as `F`'s. `rebase_due`'s milestones hit
  through `lanes_v`'s own `Fv milestones`. A lane's `F lanes` is not memoized (it isn't on an idle path).
- **The treekey merge.** `treekey.mjs --partial --names` adds one `: <path> <name>…` line per map entry after
  `--partial`'s lines; `lib/check.sh` makes that one start and computes the partial run's names in bash (`pnames`, as
  `mapNames`: map order, each once, none when a path is no entry's). File 13 runs no partial (C1-01's table), so it
  saves nothing there; `--names <path>…` stays for the CLI.
- **No builtins.** `date` and `cat` are not in the top five (Finding), so `$EPOCHSECONDS`, `printf '%(%F %T)T'` and
  `$(< file)` stay out of `lib/`.
- **Left for the next fix:** the session-log reads (`metrics.mjs` in the lane, third of the top five: `MET usage`
  twice and `MET limit` two or three times on one finished log) are not collapsed here (C1-03's steps don't name them;
  the plan's §4 default stands for a later feature).

**The proof (C1-04, 2026-11-03).** Two solo full suites, each `systemd-run --user --scope -p MemoryMax=3G
/usr/bin/time -v env TEST_JOBS=4 bash tests/run.sh` run by the session in the background, no other suite alive
(`harness status` before each). *Before*: a scratch worktree of the run's base commit `d595498` (merge-base with
`origin/main`); *after*: the feature's tree at `5a11f9d`. Outputs: `before.out`, `after.out` in the session's scratch
(`/tmp/harness/agent-harness/agent-harness-2026-11-03/lanes/C1`). (The step's `time -v TEST_JOBS=4 bash …` order makes
`time` run `TEST_JOBS=4`; the first launch failed with exit 127 and the spec's `time -v env TEST_JOBS=4 …` was used.)

| row | wall (runner's `wall` line) | user + sys (`time -v`) | checks | red files |
|---|---|---|---|---|
| **before** (`d595498`, 4 jobs solo, 2026-11-03) | 854.1 s | 2135.85 + 1225.98 = **3,361.8 s** | 1102/1102 | none |
| **after** (`5a11f9d`, 4 jobs solo, 2026-11-03) | 803.8 s | 1939.97 + 1196.14 = **3,136.1 s** | 1129/1129 | none |
| load curve §1, 4 jobs solo (10-30) | 805 s | 3,249 s | 1,077 | – |
| run-time budget §11, harness runs (10-30) | 817–835 s | 3,322–3,355 s | 1,081–1,084 | – |

**Target (spec C1 fix 6 point 3): missed, with the numbers.** CPU −20 % against *before* needed 2,689 s; the after row
is 3,136 s, **−6.7 %** (user −9.2 %, sys −2.4 %), and that with 27 more checks. The solo wall bound (≤ 650 s) is missed
too: 803.8 s, −5.9 % against *before* (854.1 s), 1,129 checks. C1-02's and C1-03's cuts (memo, poll, idle poll) stand
on their checks. The plan's §6 guess (11–16 % of file 13's CPU) was already under the target; the measured gain is
under that guess because sys time (the fork/exec cost of each start and of bash itself, about 36 % of CPU) barely
moved. The next levers, as the plan names them: `metrics.mjs`'s collapse (not done, above) and `testcount.mjs`
(150 per file in the lanes, 54 in the driver); beyond node, git (7,754 starts per file) and bash's own forks are the
larger remainder.

## Rejected

- **A disk cache of node answers** (a file per key under the state dir or the scratch, shared across processes): a
  stale answer outlives the process that computed it, and a cache that must be right after any write anywhere is the
  thing `decisions/2026-10-30-partial-key` keeps out (a key covers every input, or the answer is computed). The
  in-process memo dies with the driver or the lane, so the worst a missed input can do is one process's lifetime.
- **Keying on mtime or the path**: a rename-over write (`writeAtomic`) within the mtime's resolution, a `cp` back, a
  restored file and a `git checkout` all keep or reset an mtime without the content agreeing; the same path holds a
  new list after every `pass`. The content hash costs one `sha1sum` (0.8 ms, about 1/30 of a node start).
- **Rewriting the `.mjs` helpers in bash** (C1-03): the scheduling, the lane graph and the step lint are pure functions
  with unit checks in node; a bash copy is a second implementation of every rule that drifts from the first (the
  memo answers from the node code's own output instead), and `jq` would be a process start of its own.
- **A long-lived node server the driver talks to** (C1-03): one start for the run, but a process to supervise, restart
  and version (a stale server answering after `harness sync` changed `lib/`), a socket or FIFO protocol to keep, and
  state that outlives the answer that made it, the thing the in-process memo keeps out.
  Updated in place 2026-11-05: built after all as a per-shell coproc, not a server (`decisions/2026-11-03-resident-helper`):
  supervising is the shell's (it dies on stdin's EOF, with an EXIT trap's kill first), restarting is `ask`'s (a failure
  costs a spawn, three restarts then off); a stale version lasts one run at most, as the running bash does, since each
  driver and lane starts its own; the pipe has one asker at a time under a lock, with no socket; and it keeps no answer
  between requests, so the memo stays the only cache.
