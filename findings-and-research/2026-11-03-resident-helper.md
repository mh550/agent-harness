# The resident helper: the proof (H1-04, 2026-11-05)

The measured rows of `docs/specs/2026-11-03-resident-helper.md` H1-04, run `agent-harness-2026-11-05`. *Before* is a
scratch worktree of the run's base commit `07a31f6` (the merge-base with `origin/main`), *after* the feature's tree at
`de51e2f` (H1-01 to H1-03). The baseline is `findings-and-research/2026-11-03-redesign-baseline.md` §1 and §2, measured on
a smaller suite: main grew from 1,129 checks to 1,332 between that row and *before*, so the fair comparison for the gain
is *before*, and the spec's predictions were written against the baseline.

## The table

| measure | baseline | before | after | predicted | result |
|---|---|---|---|---|---|
| node starts per large file (file 13) | 3,139 | 2,665 | **337** | ≤ 300 | **missed, by 37** |
| node starts per stub `harness start` | 402 | 336 | **20** | ≤ 30 | met |
| CPU of file 13 | 170.6 s | 98.86 + 62.40 = 161.3 s | 44.60 + 43.40 = **88.0 s** | ≤ 110 s | met |
| full suite solo CPU | 3,136 s | 2,357.86 + 1,446.48 = 3,804.3 s | 1,080.02 + 1,027.85 = **2,107.9 s** | ≤ 2,300 s | met |
| full suite solo wall at 4 jobs | 804 s | 974.2 s | **608.1 s** | ≤ 600 s | **missed, by 8.1 s** |
| `treekey.mjs` per call, spawned | 193 ms (loaded) | 58.0 ms idle, 65.3 ms in a suite | **49.3 ms** idle, **64.4 ms** in a suite | ≤ 60 ms | met idle; **missed in a suite, by 4.4 ms** |
| `harness-log.md` lines changed | – | – | **0** (of 46) | 0 | met |
| helper restarts per stub run | – | – | **0** | 0 | met |

The suite rows:

| tree | checks | red files | wall (the runner's line) | user + sys (`time -v`) | gate before it |
|---|---|---|---|---|---|
| before, `07a31f6` | 1332/1332 | none | 974.2 s, 4 jobs | 3,804.3 s | clear, load 1.02 1.73 1.90 |
| after, `de51e2f` | 1450/1450 | none | 608.1 s, 4 jobs | 2,107.9 s | clear, load 4.14 4.38 3.59 (the before suite had just ended) |

## What the rows say

- **The gain against *before*: CPU −44.6 %, wall −37.6 %, file 13's CPU −45.4 %.** User fell 54.2 %, sys 28.9 %. The after
  row carries 118 more checks: 60 in file 91, 15 in file 92 (72.0 slot-s), 43 in the unit tier.
- **The wall's miss.** 8.1 s over 600 and under the spec's 650 line, with node starts 37 over theirs as well. 37 starts are
  about 1 CPU-s of file 13's 88 (at the baseline's 26.9 ms), so more of the same cut won't close much; by exec count what
  is left is git (7,569 in file 13) and bash's forks (sys is 1,028 s of the suite's 2,108), **phase 4's ground**. For
  scale, file 92 is new in this milestone: its 72 slot-s at 4 jobs are about 18 s of the wall.
- **The file 13 miss: 337 against 300.** The spec's sum was cli 162 + stub 48 + checks 9 + helpers ~20 + unserved. Measured:

  | class | starts | what |
  |---|---|---|
  | cli | 162 | `harness status`, `needs`, the debrief's reads: unchanged, spawned by choice |
  | stub | 48 | the stub's `node -e`: unchanged |
  | checks' own lines | 9 | unchanged |
  | helpers | 32 | driver 14, lane 18: the file starts more drivers and lanes than the spec's ~20 |
  | the rest of the driver and lanes | 86 | below |

  The 86: `summary.mjs ledger-line` 12, `memlint.mjs` under its timeout 12, `backlog.mjs list` 12, `needs.mjs fields` 11,
  `deploy.mjs status` 10, `deploy.mjs slug` 10, `metrics.mjs final` 8, `inbox.mjs insert` 5, `features.mjs milestone` 5,
  `features.mjs ids` 1. All but the last two kinds are in the decision file's call-site table as spawns, or as a call on a
  pipeline's side; `features.mjs milestone` is the same case, `in_lane` under the `| while` of `lib/lane.sh:375`. The one
  `features.mjs ids` wasn't traced.
- **`treekey.mjs`.** In a driver or a lane the call goes through its helper now: **9.7 ms** (median of 20 `ask treekey.mjs`,
  idle, load 1.10). File 13's spawned `treekey.mjs` went from 272 to 1 (`prompt.sh` run as a command); a session's
  `check.sh` still spawns its own. The spawned row's in-a-suite pair is one sample of 20 calls each, 300 s into the
  suite, at different loads (4.44 before, 3.07 after), and shows no gain from H1-03's cut (65.3 against 64.4 ms; above `node
  -e 0`, 31.0 against 30.9 ms) where the idle pair does (32.7 against 22.8 ms). I did not look further: under a lane that
  spawned path is no longer the one that runs.
- **What the helper adds: `flock`.** `ask` takes the lock by an exec per call, so file 13's `flock` went from 1,447 to 3,706
  while node fell by 2,328. All execs together barely moved, 38,175 to 37,513: the CPU fell because node's start is
  the expensive one. At H1-02's 0.9 ms a `flock`, the 2,259 more are about 2 s of file 13, the next cheap cut if one is wanted.
- **One stub start** by file 92's shim: 336 before, 321 with `HARNESS_HELPER=0` on the after tree (`check.sh` no longer
  counts an empty output), 20 on: 3 helpers, 10 of the stub's `node -e`, 2 of `deploy`, and `overlap`, `backlog`, `memlint`,
  `metrics final`, `ledger-line` one each.

## How each row was read

- **Lines changed:** `start1.sh` ran one stub start per tree and setting, each with its own `mktemp`, so the diff strips file
  92's stamps and commit hashes and also the temp directory's name. Helper on against helper off: `harness-log.md` 0 of 46
  lines, `run.log` 0 of 76, `feature_list.json` 0 of 38; on against the *before* tree, 0 of each too. File 92's own check
  (`a stub start through the helpers: the same harness-log.md, run.log and feature_list.json as helper off`) passed in the
  after suite.
- **Restarts:** `grep -c 'helper restarted'` and `helper off` over file 13's 10 `run.log` files (the after strace run, `KEEP=1`)
  and the one stub start's: 0 and 0. The full suite isn't counted: file 91 kills helpers on purpose.
- **File 13's CPU** is `env time -v bash tests/run.sh 13-run-2-michael-sets-desk`, plain, 67/67 in both trees (runner's wall
  176.6 s and 112.6 s). Its 4 runs were one at a time, the gate clear before each. The strace runs were 67/67 too.
- **`treekey.mjs`** is `tk.sh`: median of 20 spawned calls, `node -e 0` beside it, this repo's `HARNESS_CHECK_KEY_IGNORE`. The
  in-a-suite samples ran outside the suite's scope with a 5 s gap between calls, about 2 CPU-s not in the `time -v` row.

## Where this differs from the feature's steps

- **The strace line.** The step's `strace -f -e trace=execve` truncates each argument at 32 characters and traces no fork, so
  `exectable.mjs` could give neither a subcommand nor a class. I used its own usage line, C1's: `-f -s 512 -e
  trace=execve,clone,clone3,fork,vfork`.
- **The strace runs** had `TEST_FILE_TIMEOUT=1150s` (they took 322 s and 284 s, the default 10 m was never near), and the
  after one `KEEP=1` for its `run.log` files. The plain runs have neither.
- Every gate was clear with no wait: `harness status` showed this run alone and none queued, `pgrep` no other suite.

## Files

Under `findings-and-research/2026-11-03-resident-helper/`: `file13-<before|after>-execs.txt` (`exectable.mjs`'s output),
`file13-<before|after>.time`, `suite-<before|after>.time`, `suite-<before|after>-files.txt` (`<file> <checks> <slot-s>`),
`start-<before|after-off|after-on>-nodes.txt`, `proof.log` (every gate and the `treekey.mjs` lines), and the scripts `chain.sh`
(the runs in order), `gate.sh`, `start1.sh`, `tk.sh`, `tkask.sh`. The strace files (36 and 30 MB) and the full outputs stayed in
the session's scratch, `/tmp/harness/agent-harness/agent-harness-2026-11-05/lanes/H1`: `file13-before.strace`,
`file13-after.strace`, `before.out`, `after.out`.
