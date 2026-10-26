# 2026-10-25/26 · Evaluation of the first queued chain (lifecycle → rane → lanes → retro)

The first night the queue ran a whole chain of improvement runs by itself, with `MAX_PARALLEL_RUNS=2` set for the
first time. Iteration 7 ([`07-throughput-lanes-and-memory-scopes.md`](../iterations/07-throughput-lanes-and-memory-scopes.md))
is the design context.

Sources:
- `harness report <run>` and `harness status`, as of 10-26 13:30;
- the run branches' commit times;
- the 10:15 status session's OOM count, taken from the kernel's kill records.

The retro run was still going when this was written.

## The night in numbers

| | lifecycle | rane-one-mixxx (continuation) | lanes | retro |
|---|---|---|---|---|
| Run | `agent-harness-2026-10-25-lifecycle` | `rane-one-mixxx-2026-10-24` | `agent-harness-2026-10-26` | `agent-harness-2026-10-26-2` |
| Window (EDT) | 10-25 11:50 → 10-26 02:50 | 02:50 → 05:29 | 05:29 → 08:30 | 08:51 → running |
| Passing / verified / merged | **25/25** · 25 · 25 (L1–L5) | **19/19** · 19 · 19 (M5, M6) | **2/17** · 0 · 0 | **12/12** · 6 · 6 (F1) |
| Ended | done | done (after 1 continuation) | **blocked on P0-02** | running (F2 verify left) |
| Spend · per passing feature | $83.17 · $3.33 | $111.08 · $5.85 (whole run) | $22.87 · $11.44 | $35.25 · $2.94 (so far) |
| Wall time · sessions | 15.0 h · 32 | 7.8 h (whole run) · 28 | 3.0 h · 6 | 5.0 h · 14 (so far) |
| First-attempt pass rate · verify-fail rate | 1.00 · 0.00 | 0.89 · 0.05 | 0.67 · – | 1.00 · 0.00 |
| Tests | about 270 → 325 checks (suite) | 868 → 1,262 | 327 → 335 checks, in 29 files | added to the old single file |
| Human interventions | 0 | 1 answer (M5-06, given before the night) | 0 overnight; blocked | 0 |

Session time by role:
- **lifecycle:** build 9.4 h, review 3.2 h, plan 1.1 h, verify 0.6 h. Review was 21 % of spend, and the retro-fixes and
  memory specs cap it (M6: review gated on diff size).
- **rane:** a separate `check` role took 2.7 h and $45.87, 41 % of its spend: hardware test sweeps.

## What the night shows

1. **The resource work holds.** The kernel recorded 136 OOM kills, and all of them were inside the suite's own
   deliberately tiny 64 MB test scopes. **None** was a real session or service, against 10 real kills in the week
   before iteration 6. The highest session peak was 3,855 MB (rane M6-03), under the 6 GB cap. The lifecycle run
   built these caps, and the next three runs ran under them.
2. **The verify-and-merge loop is boring now, which is the goal.** Lifecycle and retro F1 merged every milestone
   themselves on the first verify (PRs #19–#21, #25–#27), with no rework.
3. **One answer is worth a night.** rane-one-mixxx had been parked at 9/19 since 10-24 on one question: the motor
   can't hold deck 2's pitch-fader bottom within ±0.5 %. The answer was to reword the step to pin the sag the tests
   already measured. With that, the run finished 19/19 and the tests grew from 868 to 1,262.
4. **The lanes block was a spec-writing bug, not a harness bug.** "Target: under 2.5 minutes" in the design became
   "under 150 s" in a step. The session hit 165 s and showed that 150 s couldn't be reached: 636 s of CPU-bound file
   time over four jobs, and one 150 s chain of dependent checks. It then did what the harness asks: it didn't pass
   itself, and it asked. With two attempts gone, the driver gave up the feature, and all 14 dependants were blocked.
   The harness behaved as designed. The step was wrong. **Rule: performance numbers are "measured and recorded".**
5. **Serial, even with two runs allowed.** rane and lanes are different projects, so the plan had them side by side.
   Commit times show lanes started at 05:29, the minute rane ended. *(inferred: the runner was started before L5
   (re-read the config each poll) merged at 02:49, so it still held `MAX_PARALLEL_RUNS=1`; its `runner.log` would
   show it.)* The night still tells us nothing about two runs' memory together.
6. **A blocked run doesn't stop the queue, and the next run inherits the gap.** With lanes blocked, the runner started
   retro, which was planned against the split suite but ran on the old one: about 10 min per full run, F1 and F2 one
   after the other. Its checks went into the old file. Merging `main` into the lanes branch now conflicts in four
   files, and the fix is a re-run of the split script. A queue entry's brief can't tell whether the run before it
   delivered.

## What changes because of it

| Finding | Change | Where |
|---|---|---|
| A soft target became a gate | Initializer rule: a performance number in a step is "measured and recorded" unless it protects the box | lanes continuation brief → `prompts/initializer.md` (P2) |
| A hung test file could hold a 15-minute suite | `TEST_FILE_TIMEOUT=10m` per file: one FAIL line | lanes continuation (P2) |
| Sessions that run the full suite repeatedly are invisible | the driver notes `<id>: suite ran <n>x (<s> s)` after each session | lanes continuation (P2) |
| Memory would collide with lanes' driver rewrite | memory parked until after the lanes continuation | queue (master to-do §A) |
| Retro's checks sit in the old suite layout | merge `main` into lanes, re-run `tests/split.sh` against `main`'s `tests/run.sh`, regenerate the fixture | one session (master to-do §B) |
| Two runs at once untested | check `runner.log` for the `MAX_PARALLEL_RUNS` value the runner held; restart the runner on L5's code if needed | open |
| A status report said rane and lanes overlapped 05:50–08:30 | they didn't (commit times); a status summary is a claim to check | — |

## Still to evaluate (after the lanes continuation and the memory run)
- Lanes: P0–P2 merged, the record PR merged, no `harness-lane/*` branches or `lanes/` slots left.
- The memory run: `lanes.max_open` 2, the number of admission waits, `mem_peak_mb` max, and wall time against the
  serial estimate.
- OOM kills over two or three nights, which decides whether `MAX_PARALLEL_RUNS=2` stays.
