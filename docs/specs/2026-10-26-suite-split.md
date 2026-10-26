# Suite split: `tests/run.sh` becomes a runner over independent check files, run in parallel (2026-10-26)

**Goal.** The harness's own suite (about 310 checks, one 1,470-line file, about 8 minutes single-threaded) runs as
independent files under `tests/checks/`, in parallel inside the one check scope, in about a quarter of the time,
with the same check names and the same `N/M checks passed` ending. A session iterates on one file and runs
everything once. The move is a script with a conformance check, not a rewrite of any test.

**Source.** `docs/specs/2026-10-25-throughput-and-memory-design.md` §5 (approved 2026-10-26). Built
interactively by one session, right after the lifecycle run has merged (its L4 and L5 checks are in the file), and
before the lanes run is queued. Milestones S1–S3; S4 is optional.

**Rules.** `CLAUDE.md` binds: worktree only; never touch real runs or state; `bash -n` on every shell file;
every check keeps its name; the suite must end green before the PR merges. No LLM judgement is part of the running
of the suite: the runner, the split and the conformance check are deterministic scripts.

**What is not changed.** The checks themselves (their commands and assertions), the stubs, the fixtures,
`lib/check.sh`'s contract (`check.sh` full and cached, `check.sh <args>` a subset, never cached), and the
`PASS`/`FAIL`/`N/M checks passed` lines `testcount.mjs` reads.

---

## S1 · The split: a library, a runner, one file per section, proven equal

**Finding.** `tests/run.sh` is one script: a preamble (lines 1–58: temp dir, private tmux socket, exported stub
environment, helpers `check`, `hlog`, `list`, `on_main`, `curl_*`, `win*`, `in_has`, `desk_of`, the base user
config, the throwaway project with a bare origin) and then about 45 sections, each opened by a `# ---- <title> ----`
line. Most sections are self-contained; a few read what an earlier section left (`run 15e` reads `$T/demo-hlog.md`
from `run 1`; the eval sections share `$ED`; the debrief sections share a runner log). Everything runs in one `$T`.

1. **`tests/lib.sh`**: the preamble as a sourced library. `suite_setup` creates `$T`, the private tmux socket, the
   stub environment, the base config and the throwaway project (one call, identical to today's lines 6–58, so every
   file starts from the same state); the helpers as they are; `suite_end` prints `N/M checks passed` for the file and
   exits 1 on a failure. `HERE` stays the `tests/` directory.
2. **`tests/split.sh`** (kept in the repo, run once): partitions `tests/run.sh` by its `# ----` markers into
   `tests/checks/NN-<slug>.sh` (NN in file order, slug from the title's first words), each file `#!/usr/bin/env bash`
   + `source "$(dirname "$0")/../lib.sh" && suite_setup` + the section's lines + `suite_end`. It never edits a
   check line. A section that depends on an earlier one's state is **grouped** with it (a list of `title → title`
   pairs at the top of `split.sh`, found by running each file alone: a file that fails alone but passes in the
   monolith is grouped, never patched), so every file passes standalone.
3. **`tests/run.sh`** becomes the runner: with no arguments, every `tests/checks/*.sh`; with arguments, the files
   whose names match any argument (`tests/run.sh gc` runs `*gc*`), which is what `check.sh <args>` passes through
   already. It collects each file's `PASS`/`FAIL` lines in order of completion and ends with the total
   `N/M checks passed`, exit 1 on any failure. `KEEP=1` keeps every file's `$T`.
4. **Conformance.** `tests/fixtures/check-names.txt` is the sorted list of check names from the last single-file
   suite (generated once from the monolith at the commit before the split; the fixture, not a hand-typed list). A
   check in the runner, `conformance: the split suite has every check the single-file suite had`, compares the names
   the runner collected against it: none missing, none duplicated. New checks later are added to the fixture by the
   session that adds them (one line) and the runner says which names are new when they are not there.
5. `CLAUDE.md` § How to verify: the suite's real duration, and the subset form by file name.

**Checks (written first):** `bash tests/run.sh` ends `N/M checks passed` with M equal to the monolith's count and
the conformance check passing; `tests/run.sh parked` runs only the parked file(s) and ends with their count; every
`tests/checks/*.sh` passes when run alone from a fresh shell; `bash -n` on all of them; `KEEP=1` leaves one `$T` per
file.

## S2 · Parallel, inside the one check scope

**Finding.** Every check file builds its own throwaway repo, state root, scratch and tmux socket, so files share
nothing and can run at once. But systemd scopes don't nest: a `systemd-run --scope` from inside the suite's check
scope (`harness-<run>-check-<pid>`, `CHECK_MEMORY_MAX=3G`, L1-05) makes a **sibling** scope outside the cap and
outside `scope_stop`'s reach. So the parallelism lives inside the one scope, and the cap bounds the whole suite.

1. The runner starts files `TEST_JOBS` at a time (default `min(nproc / 2, 4)`, at least 1), as plain background
   jobs with `wait -n`; **no inner scopes**. Each file's output goes to `$T/<file>.out` and is replayed in
   completion order, so lines never interleave.
2. The runner prints one timing line per file (`<file>: <n> checks, <s> s`) and a last line with the slowest
   three and the wall time, so the next split is measured, not guessed.
3. Memory: this repo's `.harness/config.sh` sets `CHECK_MEMORY_MAX=4G` only if a parallel run shows a kill
   (`check: RED (killed at its 3G memory cap …)`) or a peak near 3 GB in `check-last.out`; otherwise it stays at
   the default and the decision file says what the peak was. The one or two checks that start a real 64M scope
   (L1's rule) stay as they are: siblings by design, stopped by their own cleanup.
4. Target: under 2.5 minutes wall on this box with `TEST_JOBS=4`; the figure goes into `CLAUDE.md` and the
   decision file. If a file dominates (the desk or debrief sections), it is split further at its own markers.

**Checks:** with `TEST_JOBS=1` and `TEST_JOBS=4` the runner ends with the same `N/M` and the same set of `PASS`
names; no `systemd-run` call appears in the stub log during a parallel run beyond the ones the L1 checks make
today; a file that fails makes the runner exit 1 and name the file; the timing line is printed.

## S3 · The suite cache key ignores what the suite never reads

**Finding.** `lib/treekey.mjs` hashes every tracked and untracked file except `.harness/runs`, so a plan feature
(a new `docs/plans/*.md`) or a decision file changes the key and the next session's pre-suite runs in full for
nothing. The cache is `green-<key>` in `$STATE`; the key is a cache, not a gate.

1. `CHECK_KEY_IGNORE`: space-separated path prefixes left out of the key. Harness default `.harness/runs
   docs/plans`; a project extends it in `.harness/config.sh`; this repo's sets `CHECK_KEY_IGNORE=".harness/runs
   docs/plans docs/specs journal findings-and-research ledger"`. `treekey.mjs` reads it from `HARNESS_CHECK_KEY_IGNORE`
   (the driver exports it beside `HARNESS_CHECK_CMD`) and adds a `:!<prefix>` pathspec per entry.
2. `check.sh`'s cached line says so once: `check: green (cached for this code tree, N tests; key ignores:
   docs/plans …)` only when the ignore list is non-default, so a reader knows why a docs change didn't run it.
3. `templates/project/config.sh` gains the commented line; `docs/architecture.md` §4 (the suite cache row) and
   `README.md` say it.

**Checks:** two trees that differ only under an ignored prefix have the same key; a change under `lib/` changes it;
a run whose stub session adds only `docs/plans/x.md` gets a cached green before its next session (the `check: green
(cached …` line in `init.out`), and one that edits a tracked file does not.

## S4 · Optional: run the files that cover what changed

**Finding.** After S1–S2 a full run costs about two minutes, so this is a convenience, not a bottleneck fix. It is
deterministic and small, so it is here for the builder to take if S1–S3 land early.

1. Each check file may declare `# covers: lib/queue.sh bin/harness` on its second line. `tests/run.sh --for
   <path>…` runs the files whose `covers` list has a prefix of any given path, plus files with no `covers` line.
   `tests/run.sh --for "$(git diff --name-only main...)"` is the one-liner for a session's own changes.
2. The coding prompt's subset line names it as the subset to iterate on, with the full suite still run once before
   `passes` (unchanged).

**Checks:** `--for lib/queue.sh` runs the queue file and the uncovered files only; a path no file covers runs the
uncovered files only; `--for` never changes the `PASS` names a full run would produce for the files it picks.

---

## Milestones

| M | Contents | After |
|---|---|---|
| S1 | `tests/lib.sh`, `tests/split.sh`, the runner, the files, the conformance fixture and check, `CLAUDE.md` | — |
| S2 | parallel jobs in the one scope, timing lines, the memory figure | S1 |
| S3 | `CHECK_KEY_IGNORE` in `treekey.mjs`, `check.sh`, config, templates, docs | [] (independent) |
| S4 | `--for` selection by `# covers:` (optional) | S1 |

One interactive session, one PR, merged by the session when the suite is green. Its decision file:
`journal/decisions/2026-10-26-suite-split.md` (finding · choice · rejected: per-file scopes, a test framework
rewrite, LLM-driven selection).

**Why no rewrite and no framework.** The checks are already a deterministic program that takes a harness checkout
(its own location) and a throwaway project it builds. What is slow is one process and one file, not the checks. A
move by markers with a conformance fixture keeps every assertion byte for byte and proves it; a framework would be
a rewrite of 310 checks for the same result.
