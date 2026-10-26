# The suite is a runner over check files cut from the single file by its markers, grouped where a section reads another's state

*(2026-10-26, run agent-harness-2026-10-26, feature P0-01; spec `docs/specs/2026-10-26-suite-split.md` S1)*

- **Finding:** `tests/run.sh` was one 1,634-line script: a preamble (lines 1–58) and 50 sections opened by
  `# ---- <title> ----`, 325 checks, about 10 min single-threaded. Cut by its markers into one file per section, each
  starting from the same fresh preamble, 31 files passed alone and 19 failed. The spec expected "a few" sections to
  read an earlier one's state; in fact run 1 (the `demo` run) is read by most of what follows it: its session, svc
  and check scopes in `systemd.log` (L1-03, L2-02, L2-03, L1-05), its worktree and tags (gc), its port (run 2),
  `$T/demo-hlog.md` (run 15e, scratch), its state dir (run 16). The debrief sections append to the state dirs of runs
  2, 4, 5 and 9 and count the queue section's debriefs; the desk briefs parky, strict and later (runs 16, 3, 10);
  services_down reads scope.sh's `$T/meminfo-2g.txt`; the eval money section reads the eval run's `$ED`; run 7 writes
  into a state root only an earlier run creates; tmux (L3-04) calls the queue section's `has_s`. One dependency fails
  no check: L5 calls `settle` (defined by the debrief section) to wait out the queue runner's detached debrief before
  the EXIT trap deletes `$T`; alone, it would print `settle: command not found` and leave that debrief writing into a
  deleted `$T` (found by the review).
- **Choice:**
  - `tests/lib.sh` is the preamble unchanged: `suite_setup` is lines 6–22 and 36–58 as a function, the helpers and
    `GHP` stay at top level, `suite_end` prints the file's `N/M checks passed` and exits 1 on a failure.
  - `tests/split.sh` (kept, run once from `3aa98b5:tests/run.sh`) writes `tests/checks/NN-<slug>.sh`: shebang,
    `source "$(dirname "$0")/../lib.sh" && suite_setup`, the sections' lines byte for byte, `suite_end`. A section that
    failed alone is **grouped** with the one it reads from (27 `later -> earlier` pairs at its top, one line of why
    each), never patched. A group's file name adds its other sections' first words (`06-scope-sh-l1-02-run-capped-
    services-gc-queue-parked-debrief-desk-scratch-tmux.sh`), so `tests/run.sh gc` still finds gc.
  - It writes only into an empty `$SPLIT_OUT` (default `tests/checks`), so re-running it can't delete a file added
    since; a pair whose prefix matches no section, or two, stops it.
  - Result: 50 sections in 24 files. One group holds 25 sections (scope.sh, run 1 and everything that reads it, L5)
    and 253 of the 325 checks; it takes about 400 s alone, more than half of the sequential total. Splitting it further
    means re-running run 1's start in another file, lines that are not in the monolith: that is P0-02's call, with
    the timings in hand.
  - `tests/run.sh` is the runner: no arguments, every file; arguments, the files whose names contain any of them; it
    prints each file's output, then `files that exited non-zero: …` if any, and the total `N/M checks passed`.
    `KEEP=1` keeps each file's `$T` and prints `kept: <dir> (<file>)`. One file after another for now (S2 is P0-02).
    Each file's output goes to a file, then is printed: through a pipe, a process a check left behind would hold the
    runner open.
  - **Conformance:** `tests/fixtures/check-names.txt` is the 325 names from the monolith's own output (this run's
    init), C-sorted. A full run adds the check `conformance: the split suite has every check the single-file suite
    had`, which fails on a name missing, doubled **or new**, and lists each kind. A name ending ` (skipped: …)` counts
    as its base name: scope.sh's real-scope check is named so where there is no user systemd. D1 *default*: a new name fails it
    too (the spec only has the runner "say" it), so the fixture stays the complete list and a check deleted later
    is caught; a session that adds a check adds its line.
  - `lib/testcount.mjs` reads `N/M checks passed` (it read only `N passed` and `N tests passed`), so `check.sh`
    reports this suite's count; the first check of `tests/checks/25-suite-runner.sh`, the runner's own file.
  - The runner sets `LC_ALL=C` only on `sort`/`comm`: exported, it reached the files' tmux server, which then
    mangled the UTF-8 desk window names (12 desk checks failed).
- **Rejected:**
  - **Hoisting the shared helpers into `lib.sh`** (copies of `sd_with`, `gone`, `has_s`, `keep_wts`, `HH`, `HV`):
    tried first; once the state pairs were in, the files that only called a helper were in the run-1 group anyway,
    except tmux (L3-04), a one-second file. Two definitions of each helper for that is not worth it.
  - **Patching a section to build the state it reads:** the spec's rule; it would edit lines the conformance check
    can't see.

## S2: parallel inside the one check scope (P0-02)

*(2026-10-26, run agent-harness-2026-10-26, feature P0-02; spec S2)*

- **Finding:** the P0-01 split left one file of 25 sections and 253 checks that took about 400 s, more than half
  the 589 s total. Timed section by section: services_down 52 s, the desk 70 s, L5 49 s, queue 38 s, debrief "a
  big record" 22 s, run 16 20 s, capped sessions 18 s, runs 5 and 9 16 s each, run 1 13 s. This box has 4 cores
  and 8 threads. The checks are CPU work (git, node, bash), not sleeps: the 400 s file used 318 s of CPU.
- **Choice:**
  - `tests/run.sh` starts the files `TEST_JOBS` at a time (default half the cores, 1 to 4; 4 here) as plain background
    jobs with `wait -n`, never through systemd-run: scopes don't nest, and one started from inside the check scope
    would sit outside its cap. Each file writes to its own `.out`, which is printed whole when the file ends, with
    `<file>: <n> checks, <s> s`. Before the total: `files that exited non-zero: …`, then `slowest: <three>; wall
    <s> s, <jobs> jobs`. The `N/M checks passed` total stays the last line (`testcount.mjs` reads the last one).
    `TEST_CHECKS` points it at another directory: the runner's own checks use three tiny files.
  - **Largest file first** (`ls -S`): a file's size is a fair guess at its time. In name order, L5 (43 s) started
    last and the wall was 182 s.
  - **The big file is cut in three** by `tests/split.sh` with a second list, `REPLAYS_`: a file can replay an
    earlier section for its state. The replayed lines go in byte for byte between `REPLAY=1` and `REPLAY=`, and
    `lib.sh`'s `check` runs them silently without counting them; they count in their own file. A replay costs that
    section's time again (run 1 is 13 s), but it breaks a chain that grouping would turn into one file.
    `06-…-gc-scratch` (scope.sh, run 1, the capped and services sections, gc, run 15e, scratch: 122 s),
    `11-run-2-…-desk` (replays run 1 and gc; runs 2, 3, 10, 16 and the desk: 135 s) and
    `12-run-4-…-debrief-tmux` (replays runs 1 and 2; runs 4, 5, 9, queue, parked, the three debriefs, run 17,
    tmux: 151 s). L5 is a file of its own (44 s).
  - The parallel run exposed dependencies that sharing one file had hidden: run 16's "nothing parked" needs demo's
    worktree gc'd (a replay of gc), the desk briefs stoppy (run 2 grouped with the desk), the desk calls the debrief
    section's `ran`, L5 its `settle`, and the debrief section calls `ran demo` (run 1 replayed there). `ran`, `settle`
    and `HH` are copied into `lib.sh` (the same lines; the debrief section still defines them), the only helpers
    hoisted: 20 s and 44 s off the longest chain.
  - **Measured** (`time KEEP=1 TEST_JOBS=4 bash tests/run.sh` in a 3G user scope): **165 s wall**, 333/333 checks at the time. The
    slowest file is `12-run-4-same-but-queue-parked-debrief-tmux` at 151 s, then the desk file at 135 s and
    scope/run 1 at 122 s. The file times add up to 637 s: the 589 s of single-file work, about 33 s of replays, and some contention.
    The suite through `lib/check.sh` after review: `check: green in 165 s`, 335/335 (slowest 146 s). `TEST_JOBS=1`:
    599 s. Its one red check was scope.sh's real 64M scope, which went red once out of five runs: the cgroup OOM kill
    also took the `bash -c` wrapper, so the scope's `.show` was empty. That is a flaky L1 check, not the split.
  - **Memory:** the whole suite's scope peaked at 369, 390 and 381 MB in three parallel runs (`memory.peak`). That
    is far from the 3 GB cap and there was no kill, so `.harness/config.sh` keeps the default `CHECK_MEMORY_MAX`.
  - **The 150 s target is not reached, and with these checks it can't be.** Four jobs can't finish 637 s of work in
    under 159 s. The debrief file is one chain by state: queue (38 s), then the runner, then since, then a big
    record, plus runs 4, 5 and 9, whose state "since" reads, plus runs 1 and 2 replayed. So no number of jobs gets
    it under about 150 s. The remaining cuts are small: run 17 and tmux (L3-04) read only the queue section's `$Q`
    and `has_s` (6 s). It runs longer than half the wall time and is not split further: every section in it reads
    the one before, and the only way to shorten it is to rewrite checks.
  - **The runner after review:** a file's `.end` (its exit status and time) is written to a temp file and renamed into
    place, so the runner never reads half of one. A file whose job dies before writing `.end` still has its output
    printed, and it counts as broken. `suite_setup` unsets `REPLAY`. Conformance compares the checks directory by its
    real path.
  - **Known and left:** `settle` (the debrief sections' copy and `lib.sh`'s) waits for any debrief process on the
    host. Files 12 and 27 now overlap, so each may wait out the other's detached debrief, up to its 30 s cap, which
    it ignores. That can't be fixed without editing the section, and it never showed in four parallel runs. A
    replay pulls in only the sections it names: file 12 replays runs 1 and 2 without the gc between them, and file 11
    lists run 1 and gc for run 16 separately. `REPLAYS_` is an explicit list, checked by the file's own checks.
- **Rejected:**
  - **Per-file scopes** (`systemd-run` per job): siblings outside the check scope's cap and outside `scope_stop`.
  - **A higher default `TEST_JOBS`:** two lanes may each run a suite at once (MAX_LANES 2 in Michael's config), and
    half the cores each fills the box. It also wouldn't help: the debrief chain still takes about 150 s.
  - **Grouping instead of replaying:** that was P0-01's single 400 s file.
  - **Printing replayed failures:** the replayed check is counted in its own file, and state that is wrong fails
    this file's own checks. A replay that leaves out a section can fail a check by design (run 2 without run 1 fails
    its curl.log check), so a line on every run that means nothing would teach readers to ignore the line.
