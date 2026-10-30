# Suite load curve, CPU split and stub overhead (Phase 2, steps 1–3)

Measured 2026-10-30 11:02–14:30 on this box (8 logical cores, 15 GiB), `harness status` showing RUNNING 0 / QUEUED 0
before every run. Tree: `origin/main` at 185ad83, 1,077 checks (the plan's baseline was 859–925). Plan:
`docs/plans/2026-10-29-suite-time.md` §3. Measuring only; no change under `lib/`, `bin/`, `tests/` or `prompts/`.
Raw files are in `findings-and-research/2026-10-30-suite-load-curve/`; names below are relative to it.

Each run: `systemd-run --user --scope -p MemoryMax=3G /usr/bin/time -v env TEST_JOBS=<j> bash tests/run.sh`, stdout in
`lc-<j>-<role>.out`, time -v in `lc-<j>-<role>.time`, PSI/load every 10 s in `lc-<j>-<role>.psi`. Paired = the same
command in a second worktree at the same moment (roles `a`, `b`). Driver log: `driver.log`. Run 1-paired was skipped as
instructed. The run order was 4 solo, 4 paired, 8 solo, 8 paired, 2 solo, 2 paired, 1 solo; the total stayed inside the
3 h budget (the last run started at 12:56, 1 h 54 min in).

## 1. Load curve

CPU = user + sys from `time -v`. `some avg60` is the `/proc/pressure/cpu` line at the midpoint of the `.psi` samples
(system-wide, so `a` and `b` read the same line). Max RSS is the largest single process (`time -v` reports the biggest
child, not the sum).

| jobs | role | wall s | user s | sys s | CPU s | max RSS KiB | `some avg60` mid | checks passed | red files |
|---|---|---|---|---|---|---|---|---|---|
| 1 | solo | 2,865.8 | 1,776.2 | 1,033.9 | 2,810 | 97,892 | 0.00 | 1077/1077 | none |
| 2 | solo | 1,459.2 | 1,837.9 | 1,038.4 | 2,876 | 97,992 | 0.00 | 1077/1077 | none |
| 2 | a | 1,629.5 | 2,094.6 | 1,169.9 | 3,265 | 97,956 | 0.48 | 1077/1077 | none |
| 2 | b | 1,622.3 | 2,093.2 | 1,170.8 | 3,264 | 97,972 | 0.48 | 1077/1077 | none |
| 4 | solo | 805.3 | 2,091.8 | 1,156.9 | 3,249 | 98,184 | 1.37 | 1077/1077 | none |
| 4 | a | 1,163.2 | 2,625.1 | 1,521.2 | 4,146 | 98,116 | 25.01 | 1077/1077 | none |
| 4 | b | 1,160.2 | 2,627.1 | 1,523.5 | 4,151 | 98,044 | 25.34 | 1076/1077 | 13-run-2-michael-sets-desk (`harness desk --list`) |
| 8 | solo | 598.8 | 2,621.1 | 1,523.0 | 4,144 | 98,272 | 24.47 | 1076/1077 | 46-lanes-continue (the M2 reopen check) |
| 8 | a | 1,191.7 | 2,733.4 | 1,643.4 | 4,377 | 98,020 | 73.59 | 1051/1056 | 53-status-view, 52-status-json, 15-run-4-same-but-queue-parked-debrief-tmux (stopped at TEST_FILE_TIMEOUT=10m), plus the conformance check |
| 8 | b | 1,191.7 | 2,735.4 | 1,640.4 | 4,376 | 98,084 | 73.59 | 1052/1056 | 52-status-json, 15-run-4-… (TEST_FILE_TIMEOUT), plus the conformance check |

The 8-paired totals are 1,056 not 1,077 because the stopped file 15 counts as one FAIL line and the check lines it had
not yet printed are missing. The runner's slowest-three lines (`wall` and per-file times) are at the end of each `.out`.
The three slowest files at 4 jobs solo: 15-run-4 232 s, 13-run-2 205 s, 08-scope 203 s.

## 2. CPU split

`strace -f -c` of each of the three largest files by `ls -S` (`08-scope-sh-l1-02-run-capped-services-gc-scratch`,
`13-run-2-michael-sets-desk`, `15-run-4-same-but-queue-parked-debrief-tmux`), one at a time, `bash tests/checks/<file>.sh`
outside the runner: `strace-<file>.txt` (summary), `strace-<file>.out` (the file's own output), `strace.log` (wall
under strace: 330 s, 330 s, 374 s; the files take 182–208 s without it). The syscall-seconds column is wall time inside
the call summed over every process, so `wait4` and `futex` are parents waiting and not CPU.

| file | all syscalls | `wait4` | `futex` | `execve` | `clone` | `clone3` | `vfork` | `clock_nanosleep` |
|---|---|---|---|---|---|---|---|---|
| 08-scope | 10,186,203 calls | 88,628 | 334,100 | 54,194 (17,968 failed) | 47,130 | 19,936 | 895 | 618 calls, 0.01 s |
| 13-run-2 | 9,738,929 | 87,434 | 337,905 | 54,924 (19,252 failed) | 46,521 | 19,805 | 809 | 461 calls, 0.02 s |
| 15-run-4 | 12,069,041 | 117,330 | 401,782 | 73,952 (27,465 failed) | 62,660 | 22,015 | 750 | 761 calls, 0.04 s |

`perf` is not installed on this box (`which perf` empty), so there is no `perf stat` of the whole run
(task-clock, context switches, cpu-migrations not measured).

## 3. Exec counts by program name

`strace -f -e trace=execve` of the same three files (`strace -c`'s summary has no program names, so this is a second
run; the 18–24 MB raw traces are not kept, the full per-program counts are `exec-counts-<file>.txt`, log `exec.log`). Counts are successful execs by the basename of the path, ENOENT PATH probes
excluded (36,165 / 35,659 / 46,543 successful of 54,115 / 54,892 / 73,966 lines).

| program | 08-scope | 13-run-2 | 15-run-4 |
|---|---|---|---|
| git | 8,344 | 7,597 | 8,441 |
| cat | 3,243 | 3,571 | 6,439 |
| node | 3,128 | 3,138 | 3,516 |
| date | 2,649 | 2,409 | 2,895 |
| sed | 1,744 | 1,765 | 1,906 |
| rm | 1,712 | 1,585 | 1,724 |
| flock | 1,533 | 1,436 | 1,481 |
| bash | 1,491 | 1,425 | 2,164 |
| dirname | 1,106 | 1,062 | (below the top nine) |
| basename | (below) | (below) | 2,756 |

Cost of one exec on the idle box (`unit-cost.txt`, 200 runs each): `node -e 0` 26.9 ms, `git --version` 1.1 ms,
`cat` 0.8 ms, `date` 0.8 ms. So node startup alone is about 84 s (08), 84 s (13) and 95 s (15) of CPU per file, against
those files' 182 / 186 / 208 s of wall in the runner at 4 jobs solo (the per-file CPU was not measured, so a share of CPU is not stated).

## 4. Stub overhead

`KEEP=1 bash tests/run.sh <file>` (`stub-<nn>.out`, which names the kept `$T`), then the file's first `harness start`
line by hand in that `$T`, same stub environment, under `/usr/bin/time -v` (`stubstart-<nn>.out`, `stubstart-<nn>.time`;
script was the file's exports with `--spec SPEC.md --brief "only A–C" --foreground`, run name `demo-t` since `demo`
existed). All three first starts have that same argument shape.

| file | file wall in runner (solo, 1 file) | first `harness start` | user / sys | share of file wall | `harness start` lines in the file |
|---|---|---|---|---|---|
| 08-scope | 182.0 s (125 checks) | 7.6 s | 5.3 / 2.9 s | 4 % | 13 |
| 13-run-2 | 185.5 s (66 checks) | 19.4 s | 13.3 / 7.5 s | 10 % | not counted (first at line 5, more at 237–270 and on) |
| 15-run-4 | 207.7 s (79 checks) | 19.0 s | 13.0 / 7.4 s | 9 % | 10 |

One start is the file's cheapest kind (the full three-feature stub run in 13 and 15; 08's start at line 77 is the same
run); the others in a file are of different lengths, so the product is not a share. Not measured: the sum of all
starts in a file.

## 5. The plan's predictions (§3 step 1)

**Solo 1/2/4/8 jobs ≈ 2,400 / 1,250 / 620 / 520 s: did not hold.** Measured 2,866 / 1,459 / 805 / 599 s: +19 %, +17 %,
+30 %, +15 %. The shape held in part: 1→2 jobs halves the wall (ratio 0.51), 2→4 cuts it by 45 % (0.55), 4→8 by 26 %
(0.74, where the plan assumed 0.84). The suite is 1,077 checks now against 859–925 in the baseline, which accounts for
part of the absolute gap. The 8-job solo run had one red file (46-lanes-continue), which costs its rerun time on top.
It was not under 520 s.

**Paired at 4 ≈ 900 s each: did not hold.** Measured 1,163 s and 1,160 s (+29 %), 44 % above the solo 805 s. At 8 jobs the
pair took 1,192 s each, twice the solo 599 s, and file 15 hit the 10-minute file timeout in both copies. At 2 jobs the
pair took 1,626 s against 1,459 s solo (+11 %).

**CPU ≈ 2,450 s solo rising to ≈ 3,200 s paired at 4 jobs: the rise held, the base did not.** `time -v` user+sys alone
at 4 jobs is 3,249 s, not 2,450 s; paired it is 4,146 / 4,151 s. The paired/solo ratio is 1.28 against the predicted
1.31. (The journal's 2,452 CPU-s and `time -v`'s user+sys are different measures, which is not tested here.) CPU also
rises with jobs when solo: 2,810 s at 1 job, 2,876 at 2, 3,249 at 4, 4,144 at 8.

**`some` pressure 0–10 % solo at 4 jobs, 50–80 % paired: solo held, paired did not.** Solo at 4 jobs: 1.37 % at the
midpoint. Paired at 4 jobs: 25.0 % and 25.3 %. The 50–80 % band was
reached only at 8 jobs paired (73.6 %); 8 jobs solo read 24.5 %.

Red files, for the paired-flake count the plan's step 10 reads: 0 red files in 4 solo, 2 solo, 2 paired, 1 solo; 1 in
4 paired (13-run-2, in copy `b` only); 1 in 8 solo; 3 and 2 in 8 paired (the two status timing checks, file 15's
timeout, and the conformance check).
