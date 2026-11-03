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
