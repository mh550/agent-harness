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

## Rejected

*(C1-03 adds its own here.)*

- **A disk cache of node answers** (a file per key under the state dir or the scratch, shared across processes): a
  stale answer outlives the process that computed it, and a cache that must be right after any write anywhere is the
  thing `decisions/2026-10-30-partial-key` keeps out (a key covers every input, or the answer is computed). The
  in-process memo dies with the driver or the lane, so the worst a missed input can do is one process's lifetime.
- **Keying on mtime or the path**: a rename-over write (`writeAtomic`) within the mtime's resolution, a `cp` back, a
  restored file and a `git checkout` all keep or reset an mtime without the content agreeing; the same path holds a
  new list after every `pass`. The content hash costs one `sha1sum` (0.8 ms, about 1/30 of a node start).
