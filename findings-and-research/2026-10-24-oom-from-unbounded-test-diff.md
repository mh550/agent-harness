# Memory exhaustion during run rane-one-mixxx-2026-10-24 (M5-02)

Date: 2026-10-24, 00:49–00:51 EDT. Host: pop-os (15 GB RAM). Status: investigated, nothing changed yet.

## What was observed

For about two minutes the box hit maximum RAM. A baseline of roughly 10 GB was already in use, and node
processes of 6.5–7.6 GB each started, grew until nothing was left, and died. The kernel log shows four
OOM kills of node processes (comm `MainThread`) about 25 s apart:

| Time | Victim anon-RSS | Triggered by the agent running |
|---|---|---|
| 00:49:31 | 6.5 GB | `lib/check.sh` (the full suite) |
| 00:49:55 | 7.3 GB | `node --test tests/platter-run.test.mjs` |
| 00:50:19 | 7.5 GB | `timeout 120 node tests/platter-run.test.mjs` |
| 00:50:46 | 7.6 GB | the same, output redirected to a file |

Collateral: the first OOM (00:49:24) killed `codium`; voice-concierge logged event-loop stalls of up to
1.9 s during the pressure; the journal reported "Under memory pressure, flushing caches". The
"docker-…scope" names in some kill lines are the cgroup of the process that invoked the OOM killer, not
the victims. The victims were in `session-11.scope`. No container was involved.

## Root cause

The M5-02 coding session works test-first. At 00:48 it appended a deliberately failing (red-phase) test to
`tests/platter-run.test.mjs`. The test used `assert.deepEqual` on two large arrays of platter updates that
differed because the feature (`--deck`) was not built yet.

When `deepEqual` fails, Node builds a textual diff of both values. For arrays of thousands of objects
that diff grew to about 7 GB. The session read this as a hang ("the hang is Node's assertion diff choking
on two large unequal arrays", its own diagnosis at 00:51) and re-ran the same file three more times, each
time reproducing the blow-up. At 00:51 it made the comparisons cheap on failure and the suite went green
in 21 s (886 tests).

The test was the trigger. The reason it nearly took the machine down is that **nothing bounds a session's
memory**:

- `lib/driver.sh` `session()` runs `timeout "$SESSION_TIMEOUT" claude -p …`, which limits wall time only.
- `lib/check.sh` runs the suite with a bare `bash -c "$cmd"`: no memory limit, and no time limit.
- Every child a session starts (tests, dev servers, scripts) can claim all of the machine's RAM.

The box also had little headroom to begin with:

- zram swap was 14.5 of 15.5 GB used, and disk swap 2.3 of 4 GB.
- Six `next dev` servers from old portfolio worktrees had run 2–5 days.
- About 14 `claude bg-spare` processes were alive, one for almost 5 days.
- The n8n and DJ docker stack and voice-concierge were running.

## Evidence

- `journalctl -k` between 00:49 and 00:51: the four `Out of memory: Killed process … (MainThread)` lines.
- Session transcript `~/.claude/projects/-home-mh550-worktrees-rane-one-mixxx-rane-one-mixxx-2026-10-24/9c50f5b8-….jsonl`,
  04:48–04:53 UTC: the red-phase test, the failing/killed runs (exit 137), the diagnosis, the fix.
- Re-check: every test file in the final tree, run one at a time under a 1.5 GB cgroup cap
  (`systemd-run --user --scope -p MemoryMax=1500M -p MemorySwapMax=0`), stayed under the cap. The final
  suite is not memory-hungry; only the intermediate red-phase test was.

## Recommended next steps

1. **Cap each session in a cgroup** (`driver.sh`, `session()`): wrap the launch in
   `systemd-run --user --scope -p MemoryHigh=5G -p MemoryMax=6G -p MemorySwapMax=2G`. A runaway is then
   killed inside the session's cgroup instead of the kernel picking victims across the whole machine.
2. **Cap and time-limit the test command** (`check.sh`): run `$cmd` in its own scope at about 2 GB with a
   `timeout` of about 10 minutes, so a runaway test fails by itself and the session survives.
3. **Check free memory before starting a session.** Wait or park the run when `MemAvailable` is under
   about 6 GB, the same way usage-limit waits (`LIMIT_WAITS`) work. Log peak RSS per session.
4. **Tell sessions** (worker prompt, and a lint if cheap): never `deepEqual` large arrays in a red-phase
   test (compare length, a hash, or the first mismatch); on exit 137 or a hang, do not retry the same
   command: bound it or bisect with `--test-name-pattern`.
5. **Reduce the baseline**: stop stale `next dev` servers, reap long-idle `claude bg-spare` processes, and
   reconsider zram sizing on a 15 GB machine, since 15 GB of compressed swap hides how little real
   headroom there is.

Per `CLAUDE.md`, a behaviour change here needs a `journal/decisions/<date>-<slug>.md` file, an update to
`docs/architecture.md` and `README.md`, a check in `tests/run.sh` written first (for example: a memory hog
under a stub session is killed inside its cap and the driver logs it), and work in a worktree.
