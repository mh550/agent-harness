# Test suite redesign: the phase 0 baseline and the language numbers (2026-11-03)

Phase 0.1, 0.2 and 0.4 of `docs/specs/2026-11-03-test-suite-redesign.md`, measured by the planning session on
2026-11-03 between 16:30 and 17:30 while run `agent-harness-2026-11-03` (the C1 milestone of
`docs/specs/2026-10-31-suite-cpu.md`: fix 6's memo and poll collapse, fix 4) was alive on the box (load average 4.3–6.0).
**A solo full run was therefore not possible today**; the solo rows below are the live run's own C1-04 proof, measured
by its session the same afternoon with no other suite alive, read from the lane branch
`harness-lane/agent-harness-2026-11-03/C1` (`journal/decisions/2026-10-31-fewer-node-starts.md`). Nothing of the run was
touched. The first dispatch piece re-measures on `main` once C1 has merged and the box is quiet.

## 1. The solo full suite (phase 0.1)

| tree | date | wall (runner's `wall` line, `TEST_JOBS=4`, solo) | user + sys | checks | red files | source |
|---|---|---|---|---|---|---|
| `d595498` (main before C1) | 2026-11-03 | **854.1 s** | 2,135.85 + 1,225.98 = **3,361.8 s** | 1,102 | none | C1-04 *before* row |
| `5a11f9d` (C1's tree: memo + poll collapse) | 2026-11-03 | **803.8 s** | 1,939.97 + 1,196.14 = **3,136.1 s** | 1,129 | none | C1-04 *after* row |
| `185ad83` | 2026-10-30 | 805.3 s | 3,249 s | 1,077 | none | load curve §1 |
| harness's own runs | 2026-10-30 | 817–835 s | 3,322–3,355 s | 1,081–1,084 | – | run-time budget §11 |

Three slowest files (4 jobs solo, 2026-10-30, `findings-and-research/2026-10-30-suite-load-curve/lc-4-solo.out`):
`15-run-4-same-but-queue-parked-debrief-tmux` 232.2 s (79 checks), `13-run-2-michael-sets-desk` 205.3 s (66),
`08-scope-sh-l1-02-run-capped-services-gc-scratch` 202.8 s (125). The 86 files' slot times add up to 3,184 s; 52 files
take under 30 s each and together 580 slot-s; 34 files take 33 s or more and together 2,604 slot-s.

Per-file slot times (the tier plan reads them): see `lc-4-solo.out`; the 30 s line falls between `81-partial-key`
(29.1 s) and `70-overlap` (33.8 s).

## 2. Where the node starts come from (phase 0.2)

**One stub `harness start`** (file 13's first, by hand in the kept `$T`, C1-01): wall 19.0 s, **20.44 CPU-s**, 4,110
successful execs, **402 node starts = 10.8 CPU-s = 53 % of the start's CPU**. By class: driver 83, lane 309, stub 10,
checks' own lines 0. Top callers by execs × 26.9 ms: `features.mjs` in the lane 122 (`passes` 22, `model` 17,
`milestone-done` 14, `ids` 9, `unpark` 8, `snapshot` 8, `summary` 7), `metrics.mjs` in the lane 48 (`usage` 16, `limit`
13, `final` 9, `append` 8), `treekey.mjs` in the lane 36 (`--partial` 23, plain 13), `features.mjs` in the driver 34,
`entries.mjs` in the lane 32. git 835 execs (0.9 s), date 328 and cat 419 (0.6 s together).

**The whole of file 13** (C1-01's cross-check): 35,647 successful execs, **3,139 node starts = 84.4 CPU-s of 170.6 =
49 % of the file's CPU** (185.0 s wall solo). By class: driver 975, lane 1,945 (**2,920 = 93 %**), cli (`harness
status`, `needs`, the debrief's reads) 162, stub 48, the checks' own lines 9. git 7,754, cat 3,422, date 2,412, bash
1,419. `treekey.mjs` 205 per file (`--partial` 128, plain 77).

**A second file, traced by this session** (`14-run-2b-stop-records`, 12 checks, 54 s solo; under strace 139 s on the
loaded box, user 64.9 + sys 68.6 s): 948 node starts, git 2,519, date 766, cat 756, sed 553, rm 530, flock 487, bash
463. Top node rows: `features.mjs model` 78, `features.mjs summary` 60, `metrics.mjs usage` 52, `treekey.mjs --partial`
51, `treekey.mjs` 42, `needs.mjs sweep` 29, `features.mjs milestones` 28, `metrics.mjs final` 27, `memlint.mjs
store-line` 27, `metrics.mjs append` 26, `features.mjs passes` 25, `metrics.mjs limit` 24, `summary.mjs report` 22,
`summary.mjs build` 20. Raw trace: this session's scratch (not kept; the method is C1-01's, reproducible with
`strace -f -e trace=execve,clone,clone3,vfork,fork -o <f> bash tests/checks/14-*.sh`).

**Per real session.** A real coding session lasts 400–4,700 s (budget §2) and the driver's node starts around it are
the same few hundred a stub session gets (the lane's per-session path: `entries.mjs` ×4, `inbox.mjs`, `metrics.mjs`
×4, `treekey` ×3–5, `features.mjs` ×10–20, plus the 1 s poll loop's `needs.mjs sweep` and the memoized `F poll` per
iteration). At 27 ms each that is 10–20 s per session, under 1 % of the session's wall: **the driver's process starts
cost the suite, not live runs.** The lever is the suite's stub runs, where a 19 s start is 53 % node.

**What C1's batching achieved (the first move of phase 2, built by the live run).** CPU −6.7 % (3,361.8 → 3,136.1 s)
and wall −5.9 % against a −20 % target; user −9.2 %, sys −2.4 %. The memo lives in one bash process and most `$( )`
sites are subshells that cannot keep an entry; the poll collapse touched the idle loop only. The decision's own next
levers: `metrics.mjs`'s calls, `testcount.mjs`, then git (7,754 per file) and bash's own forks. **So batching is spent;
what is left of the driver's node starts needs a process that outlives one question: the resident helper (phase 2).**

## 3. Per-call and per-request costs (phase 0.4), this box, 2026-11-03, load average 5.7

| call | wall per call | note |
|---|---|---|
| `node -e 0` | 36.5 ms (26.9 ms idle, load curve `unit-cost.txt`) | the start alone |
| `node lib/features.mjs model opus` | 44.7 ms | start + import + answer |
| `node lib/features.mjs summary <list>` (6 features, 15.8 KB) | 47.4 ms | |
| `node lib/features.mjs next <list> <att> 3` | 46.0 ms | |
| `node lib/treekey.mjs` | **193 ms** | git ls-files + hash-object over the tree; 205 calls per large file ≈ 30–40 s of its wall |
| `node lib/treekey.mjs --partial` | 191 ms | |
| `git rev-parse HEAD` | 2.0 ms | |
| `date` | 1.2 ms | |
| **in-process, after one import** (2,000 calls) | | |
| `JSON.parse(readFileSync(list))` | **0.096 ms** | the per-request work of a list question |
| `modelId("opus")` | 0.001 ms | |

So with a warm process, a list question costs ~0.1 ms against 45 ms spawned: **start-up is 99.8 % of the cost.**

## 4. The Rust numbers (phase 0.4)

A stand-in crate (`serde_json` only; reads a JSON list, answers one question), built offline from the registry cache on
this box (load average 6; the numbers are upper bounds):

| measure | value |
|---|---|
| cold build, debug | 3.60 s wall (user 4.10, sys 0.82) |
| cold build, release | 4.23 s wall (user 6.71) |
| incremental (touch `main.rs`), debug | 0.14 s |
| incremental (edit `main.rs`), release | 0.55 s |
| a second checkout with a shared `CARGO_TARGET_DIR` | 0.17 s (nothing rebuilt) |
| `target/` size | 56 MB per target dir |
| release binary | 509,080 bytes |
| **binary start + parse the list** | **1.21 ms** per call |
| node, the same work (`node -e` reading the list) | 40.75 ms per call (same loaded box) |
| toolchain on this box | `~/.cargo` 457 MB + `~/.rustup` 1.5 GB, already installed (rustc 1.99.0, cargo 1.99.0) |
| boxes the harness runs on | this one only (Michael, 2026-11-03) |

Hot path to port if Rust were chosen: `lib/treekey.mjs` (86 lines), `lib/testcount.mjs` (40), the read-only questions of
`lib/features.mjs` (484) and `lib/metrics.mjs` (206): about 820 lines, every output byte-for-byte (the checks compare
`harness-log.md` lines), with a differential check against node on fixtures.

**The comparison the spec asked for.** Without a warm process, a Rust binary removes 25–39 ms of each of ~2,900
driver node starts per large file (75–110 CPU-s of 170): the same gain a resident helper gets, with no lifecycle code,
for a port of ~820 lines, a 2 GB toolchain on the one box, a 3.6 s cold / 0.2 s incremental build per worktree (one
`CARGO_TARGET_DIR` shared across the lane slots makes the second one 0.17 s), and a model edit-compile loop of under a
second. With a warm process, the remaining per-request work is 0.1 ms in node; Rust's share of that is not measurable
in a 3,100 CPU-s suite. **Recommendation: stay on node and build the warm process (phase 2's coproc helper); Rust is the
recorded fallback if the helper fails its lane and lifecycle checks, with these numbers so that choice is a decision,
not a study.** The repo's recorded error budget is in bash (the Gotchas list), which phase 4's purity work addresses by
moving logic into the unit tier, in either language.

## 5. Re-baseline on main (2026-11-03, `6622952`)

Measured by the redesign's first dispatch piece (D0) between 17:37 and 18:15 on `origin/main` at `6622952` (C1 merged
as PR #78, the run record as #79, the plan as #80/#81), `harness status` RUNNING 0 and QUEUED 0 before each run, the
runner's own `wall` line for the wall and `/usr/bin/time -v`'s user + sys for the CPU. Raw outputs (the `.out`, `.time`
and the parsed exec tables; not the 34 MB strace) in `findings-and-research/2026-11-03-redesign-baseline/`.

### 5.1 The solo full suite, twice (step 1)

| row | wall (`TEST_JOBS=4`, solo) | user + sys | checks | red files | slowest three | load average before |
|---|---|---|---|---|---|---|
| C1-04 *after* (`5a11f9d`, C1's lane tree, §1) | 803.8 s | 1,939.97 + 1,196.14 = **3,136.1 s** | 1,129 | none | – | – |
| **solo 1** (`6622952`, main) | **776.6 s** | 1,941.79 + 1,171.31 = **3,113.1 s** | 1,141/1,141 | none | `15-run-4-…` 219.9 s, `13-run-2-…` 193.7 s, `08-scope-…` 192.0 s | 0.82, 0.94, 1.64 (17:37) |
| **solo 2** (`6622952`, main) | **794.6 s** | 1,944.83 + 1,173.23 = **3,118.1 s** | 1,141/1,141 | none | `15-run-4-…` 223.4 s, `13-run-2-…` 193.8 s, `08-scope-…` 193.1 s | 3.75, 4.14, 3.26 (17:50, run 1's tail) |

Mean of the two: 785.6 s wall, 3,115.6 CPU-s. Against C1-04's *after* row: CPU −0.7 % and −0.6 %, wall −3.4 % and
−1.1 %, with 12 more checks; against the *before* row (`d595498`): CPU −7.4 % and −7.3 %, wall −9.1 % and −7.0 %. The 18 s between
two identical runs on a quiet box is the run-to-run noise of this method; a phase result under ~3 % of wall or ~1 % of CPU
is inside it. Command as C1-04's: `systemd-run --user --scope -p MemoryMax=3G /usr/bin/time -v env TEST_JOBS=4 bash
tests/run.sh`, each run started after the other had ended (`solo-1.out`, `solo-1.time`, `solo-2.out`, `solo-2.time`).
89 check files now (86 on 10-30).

### 5.2 File 13's execs by class (step 2), beside §2's

`strace -f -s 512 -e trace=execve,clone,clone3,vfork,fork -o file13.strace bash tests/checks/13-run-2-michael-sets-desk.sh`
(66/66; under strace 309.6 s wall, user 153.19 + sys 158.41), parsed by `findings-and-research/2026-11-03-exec-table/
exectable.mjs` and `mdtable.mjs` (`file13-execs.txt`, `file13-tables.md`); then the same file timed without strace
(`file13-plain.time`): **174.3 s wall, user 96.97 + sys 61.82 = 158.8 CPU-s** (§2: 185.0 s, 170.6 CPU-s). Load average
before the trace 1.27 (18:04), before the plain run 1.14 (18:09). 36,740 successful execs (§2: 35,647).

| program | driver | lane | cli | stub | tests/lib.sh | all | §2 (C1-01, before C1's cuts) |
|---|---|---|---|---|---|---|---|
| node | 759 | 1,674 | 161 | 48 | 9 | **2,651** | 3,139 (975 / 1,945 / 162 / 48 / 9) |
| git | 2,528 | 3,002 | 1,352 | 552 | 320 | 7,754 | 7,754 |
| date | 978 | 1,272 | 140 | 0 | 20 | 2,410 | 2,412 |
| cat | 1,515 | 432 | 588 | 771 | 72 | 3,378 | 3,422 |
| bash | 142 | 288 | 177 | 809 | 2 | 1,419 | 1,419 |
| sha1sum | 753 | 1,003 | 0 | 0 | 0 | 1,756 | 86 |

Node: **2,651 starts × 26.9 ms = 71.3 CPU-s = 45 % of the file's 158.8 CPU-s** (§2: 3,139, 84.4 of 170.6, 49 %). The
driver and its lanes start 2,433 of them (92 %; §2: 2,920, 93 %). The cut is all in `features.mjs`: lane 720 → 449,
driver 420 → 205; every other script's count is the one §2 has (`metrics.mjs` lane 314, `treekey.mjs` lane 205,
`entries.mjs` lane 191, `testcount.mjs` lane 150, `metrics.mjs` driver 126, `inbox.mjs` lane 121). The 1,670 new
`sha1sum` execs are the memo's content hashes, one per `F` call on a file argument (0.8 ms each, ~1.3 CPU-s).

Top ten script + subcommand rows (count, caller), beside §2's:

| # | main `6622952` | §2 (C1-01) |
|---|---|---|
| 1 | `metrics.mjs usage` 104, lane | `features.mjs passes` 125, lane |
| 2 | `treekey.mjs --partial` 82, lane (`check.sh`) | `metrics.mjs usage` 104, lane |
| 3 | `metrics.mjs limit` 82, lane | `features.mjs summary` 91, driver |
| 4 | `testcount.mjs` 78, lane (`check.sh`) | `features.mjs model` 90, lane |
| 5 | `treekey.mjs` 77, lane | `features.mjs milestone-done` 83, lane |
| 6 | `testcount.mjs` 72, lane | `treekey.mjs --partial` 82, lane (`check.sh`) |
| 7 | `features.mjs passes` 57, lane | `metrics.mjs limit` 82, lane |
| 8 | `inbox.mjs answers` 56, lane | `testcount.mjs` 78, lane (`check.sh`) |
| 9 | `metrics.mjs final` 55, lane | `features.mjs milestones` 77, driver |
| 10 | `memlint.mjs store-line` 52, lane (`render.mjs` 52 ties) | `treekey.mjs` 77, lane |

`features.mjs` by subcommand, §2 → now: `passes` lane 125 → 57, `model` lane 90 → 0 and driver 76 → 0 (`models` 18 lane +
14 driver fills every alias at once), `milestone-done` lane 83 → 0, `summary` driver 91 → 20 and lane 41 → 22,
`milestones` driver 77 → 31, `ids` lane 49 → 17, `next` lane 35 → 0 and driver 19 → 0, `unpark` driver 30 → 0
(`unparks` 18); new `poll` 51 lane + 11 driver. Unchanged: `unpark` lane 51, `repair` 30, `bump` 30, `lanes` 29, `pass`
23, `kind` 30 → 27, `snapshot` 47 → 40, `deps` 32 → 28, `milestone-done` driver 18. Top callers by count × 26.9 ms:
`features.mjs` lane 449 (12.1 CPU-s), `metrics.mjs` lane 314 (8.4), `features.mjs` driver 205 (5.5), `entries.mjs` lane
191 (5.1), `metrics.mjs` driver 126 (3.4), `treekey.mjs` lane 205 (5.5 across `lane.sh` 123 and `check.sh` 82).

### 5.3 The unit layer (step 3)

`bash tests/run.sh 01-scheduler 02-notifications 03-harness-parked 04-render-pure 05-metrics-pure 06-test-counts
07-step-lint 11-deploy 12-journal 35-backlog 51-view-pure` (the eleven `-pure-` files; load average 1.1 before):
**104/104 checks, 149 successful node execs, user 6.26 + sys 3.09 = 9.35 CPU-s, 3.16 s wall** (`time -v`; the runner's
own wall 2.3 s, 4 jobs; under strace 4.2 s). Node by script (`pure-execs.txt`): `--input-type=module -e` 58,
`backlog.mjs` 32, `entries.mjs` 17, `testcount.mjs` 13, `deploy.mjs` 12, `view.mjs` 6, `metrics.mjs` 3, `features.mjs` 3,
`-e` 2, `render.mjs` 1: 149 × 26.9 ms = 4.0 CPU-s, 43 % of the layer's CPU; the rest is the runner and `tests/lib.sh`'s
per-file throwaway state (1,649 execs in all: `basename` 1,001, `git` 100, `grep` 56, `jq` 54, `cat` 39). Per check: 1.4
node starts and 0.09 CPU-s (the plan's §1 "1 node start each, ~3 CPU-s" counted the `node -e` evals alone). Of note for
the dispatch: the brief's spelling `tests/run.sh 01- 02- … 11- 12-` is a substring match in `tests/run.sh`, so it also
runs `08-scope-sh-l1-02-…`, `21-run-11-…` and `22-run-12-…` (236 checks, 3,186 node starts, 207 CPU-s; `pure-wide.time`);
the eleven files need their names.

### 5.4 What moved against §1–§3, and why

§1's solo row moved little because its *after* row already was C1's tree: wall 803.8 → 776.6/794.6 s and CPU 3,136.1 →
3,113.1/3,118.1 s are within the method's noise, and the 12 extra checks (1,129 → 1,141) are C1-05's 11 and C1-06's 1,
merged after C1-04 measured `5a11f9d`; the three slowest files are the same three, each 10–20 s faster than the 10-30
numbers (`15-run-4-…` 232 → 220/223 s, `13-run-2-…` 205 → 194 s, `08-scope-…` 203 → 192/193 s). §2's file-13 numbers
moved because they were C1-01's finding on the tree *before* C1-02/03's cuts: node 3,139 → 2,651 (−488, −15.5 %), 49 %
→ 45 % of a file whose CPU fell 170.6 → 158.8 s (−6.9 %) and wall 185.0 → 174.3 s; the whole of the cut is
`features.mjs` (−486 starts: the memo, `models`, `poll`, `unparks`), and git 7,754, `date` 2,410, `cat` 3,378 and bash
1,419 did not move, so §2's "next levers" (`metrics.mjs` 440 starts, `testcount.mjs` 204, `treekey.mjs` 271, then git and
bash's own forks) stand as the remainder; `sha1sum` gained 1,670 execs (~1.3 CPU-s) as the memo's price. §3's per-call
costs were not re-measured (no code under them changed). The unit layer's 11 files are 9.35 CPU-s of the suite's 3,116
(0.3 %), so phase 1's gain is wall-shaped (fewer slot-seconds in the 4-job schedule), not CPU-shaped.
