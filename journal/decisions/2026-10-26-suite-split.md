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
