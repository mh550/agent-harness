# Unattended night: a flaky red is rerun before it costs a session or a stop, and merge conflicts are resolved by a session, verified, and merged without Michael (2026-10-29)

**Goal.** Two things that stop a night for Michael stop stopping it. **N1:** when the suite goes red, `lib/check.sh`
reruns what failed once before it reports red; a red that passes on the rerun is green, named and counted, and a red
that fails twice is red as today. **N2:** when `main` conflicts with a lane, the driver resolves the merge (a sorted
merge for the lists that always collide, then a `resolve` session for the rest), puts the merged tree through the
verify gate that exists today, and merges it; only a resolution that fails its gate needs Michael. Two milestones,
**in series on purpose** (below).

**Source.** Michael's ask of 2026-10-29 ("I want my agent to be able to handle merge conflicts like this without
needing my approval", and the guard set up "before the night starts"); the flaky-check evidence of the 10-26 and 10-28
runs (N1 *Finding*); the measurements of 2026-10-29 in `decisions/2026-10-29-check-timeout-25m`. The design
conversation is summarized in `docs/specs/2026-10-28-reliability.md` § *Why two runs*.

**Rules.** `CLAUDE.md` binds: worktree only; never touch real runs or real state; fakes mirror the live API (the
fixtures named below are real output, captured 2026-10-29); every behaviour visible in `harness-log.md` (`note`) and
checked test-first in a `tests/checks/` file by topic, names in `tests/fixtures/check-names.txt`; `bash -n` and
`node --check`; a decision file per behaviour change; `docs/architecture.md` and `README.md` in the same milestone.
**Proceed on the defaults written here; record them in the decision files; never park.** The invariants hold and get
a check each: **what lands on `main` is byte for byte what was verified** (a resolved merge reaches `main` only through
a verify round on that tree), and **a check that fails every time still un-passes its feature**.

## Depends on

- `main` at or after `91e9712` (status-ux U1–U3 merged, PRs #42, #43, #45; the needs record of U2 is used below).
- This spec's PR also sets `CHECK_TIMEOUT=25m` in `.harness/config.sh`, so this run's suites have it.

## Why in series (N2 after N1)

This run is built **by today's harness**, which can't resolve a conflict yet: two lanes would both add names to
`tests/fixtures/check-names.txt` and edit `docs/architecture.md` and `README.md`, and one conflict would stop this run
for Michael, so the reliability run behind it would start without N2. In series nothing re-bases and nothing
conflicts. The two-lane test is the next run's, on a harness with both milestones in it. Each milestone's first feature
gets `after` explicitly (N1: `[]`; N2: `["N1"]`).

---

## N1 · The rerun guard: a red is rerun once, a flake is green and counted, a real red stays red

**Finding.** The harness asks "is the suite green?" at four points, all through `$CHECK` (`lib/check.sh`, from the live
checkout) and `green()` (`lib/record.sh`: `"$CHECK" > /dev/null 2>&1`), and a red that was only a flake costs each
differently:

| Where (function) | A red today | Cost of a false red |
|---|---|---|
| after a coding session (`lib/lane.sh`, the `F passes … && ! green` line) | the feature is un-passed | another session: U1-07 on 2026-10-28, `07:19:50 U1-07 un-passed: suite red after the session`, the rerun 39 min |
| before a session (`run_init`) | `suite red before the session (the session is told to fix it first)` | the session chases a red that isn't there (`08:15:44` at verify U1, which passed anyway) |
| at verify (`verify`: `hold && ! green` → `red`) | `needs-<m>`, `verify_red` record, needs Michael | the milestone waits for Michael until morning |
| at a disjoint re-base (`rebase`: `green \|\| rebase_fail …`) | `verify_red`, needs Michael | the same |

The sessions saw it: "flaked 1-2 timing checks per run tonight"; "flaked once each in 28-run-14d-harness-merge and
48-lanes-rebase … both pass alone"; "flakes (46 pr-held, 38 pack bytes, 32 MAX_PARALLEL_RUNS, 08 no user systemd); none
in code U1 changed". The 10-26 retro proposed "rerun the failing check once before un-passing"; the memory retro "re-run
only the flaky suite file". On 2026-10-29 one suite alone failed `the weekly budget ends a run after the session that
crossed it` (file 15), and one of two suites at once failed two checks of `44-lanes-record` (the stub run ended without
the lane branch `harness-lane/rec/M2`), each green on the next run. `tests/run.sh` already prints `files that exited
non-zero: <files>` and takes file names as arguments.

1. **The failed-files line.** A suite may print one line `HARNESS_FAILED=<name> <name>…` (names its own command takes as
   arguments to rerun just them), the twin of the `HARNESS_TESTS=<n>` test-count contract
   (`decisions/2026-10-26-test-count-contract`). **Its promise: every failure of the run is inside a named file**, so
   rerunning the named files green means the whole suite would be green. `tests/run.sh` prints it on a red full run,
   after `files that exited non-zero:`, with the file basenames (`44-lanes-record`), which its argument matching
   takes, **and omits it whenever a failure is outside every file** (the conformance check, which runs only on a full
   run), so `auto` reruns the whole suite then. `README.md` states the promise for other projects' suites.
2. **`check.sh`, full form, on a red** (exit not 0, and not a timeout or a cap kill: those are said as today and not
   rerun, since a rerun would cost the whole timeout again). `CHECK_RERUN` (`lib/config.sh` default `auto`, exported
   by `prompt_env` as `HARNESS_CHECK_RERUN`): `auto` reruns the named files when the output has the line, else the whole
   suite; `failed` only the named files (none named: no rerun); `suite` the whole suite; `off` none. The rerun is
   `$cmd <names>` (or `$cmd`) through `run()`, so the same scope, cap and timeout; its output goes to
   `check-rerun.out` beside `check.out`, which keeps the first run's whole output (never appended to: the generic
   count rule takes the last `N/M checks passed`, and a rerun's would be the subset's). Rerun green: the tree's green
   marker is written as for any green (so later calls are cached), holding the **full run's** count, never the
   subset's: for a count line with a total (`N/M checks passed`), the total; otherwise none (an empty marker, as older
   markers are); the line is `check: green after a rerun (flaky: <names>)<, n tests>` and the exit
   0. Rerun red: `check: RED (… ; red again on a rerun of <names>)` and the tail, exit as the rerun's. The subset form
   (`check.sh <args>`) never reruns: its caller is iterating.
3. **The flake record.** Each rerun-green appends one JSON line to `$HARNESS_CHECK_CACHE/flakes.jsonl` (the state dir's
   `green/` for a run; scratch otherwise): `{"at": "<ISO>", "key": "<tree key>", "names": [...], "rerun": "failed|suite",
   "first": "<the first run's RED reason>", "load": "<loadavg 1 5 15>", "lane": "<HARNESS_LANE or empty>"}`. A
   session's own `{{CHECK}}` calls are recorded the same way. The driver notes new rows after each session, verify and
   re-base (`flakes_note`: `note "flaky: <names> (red, then green on a rerun; load <1-min>)"`, one note per row, rows
   past the last offset noted, kept in `$STATE/flakes-noted`), and before `finish`'s summary.
4. **Counted, never quarantined.** `summary.json` gains `flakes: {count, names: {"<name>": n}}` (new key; existing keys
   unchanged), `report.md` a row `| Flakes | 3 · 28-run-14d-harness-merge ×2, 44-lanes-record |` (`Flakes | 0` when none,
   so its absence means an older run), and the debrief's gatherer a `#### flakes` block: names that flaked in two or
   more of the last five ledgered runs of the project, from the ledger's `summary.json` copies. No check is ever
   skipped or excluded: a quarantined check stops guarding, and an intermittent real bug (P2 review Minor 5: "the 47
   flake" was a coordinator ordering bug) would be hidden for good. Repeated flakers become fix work (the reliability
   run's R1), not exemptions.
5. **Decision and docs.** `journal/decisions/2026-10-29-rerun-guard.md` (finding · choice · rejected: quarantine; a
   rerun inside `tests/run.sh` only, which other projects wouldn't get and the harness couldn't count; rerunning on a
   timeout; one full suite at a time across lanes, per `decisions/2026-10-29-check-timeout-25m`).
   `docs/architecture.md` §3 (`check.sh`), §4 (`green/flakes.jsonl`, `flakes-noted`), §7 (the guard beside the cache);
   `README.md` (`CHECK_RERUN`, the `HARNESS_FAILED=` line for a project's suite, beside `HARNESS_TESTS=`);
   `templates/user/config.sh` (`CHECK_RERUN` commented).

**Checks (written first),** in a new `tests/checks/` file by topic (the suite runner's own checks are in
`33-suite-runner.sh`), each with a stub suite (`HARNESS_CHECK_CMD` a script whose behaviour a counter file sets):
a suite red once then green (`HARNESS_FAILED=a b` on its red) → exit 0, `green after a rerun (flaky: a b)`, the rerun
called with `a b`, a `flakes.jsonl` row, the green marker written with the first run's `N/M` total, not the
rerun's subset count, and `check.out` unchanged by the rerun; **a suite red every time → exit non-zero and
`red again on a rerun`, and in a stub run the feature is un-passed with today's note** (the invariant); a red with no
line under `auto` → the whole suite rerun; under `failed` → none; under `off` → none; a timeout (a stub sleeping past
`HARNESS_CHECK_TIMEOUT=2s`) → `timed out`, no rerun; the subset form never reruns; `tests/run.sh` with one failing stub
file prints `HARNESS_FAILED=<that file>` and none when green; a stub run whose suite flakes once → the `flaky:` note,
`summary.json` `flakes.count == 1`, the report row; the debrief block from two fixture ledger summaries.

## N2 · Merge conflicts resolved without Michael: a sorted merge for lists, a resolve session for the rest, the verify gate, then merge

**Finding.** Every place a lane meets a conflicting `main` stops for Michael:

| Where (function, after U2) | Today |
|---|---|
| `sync_main` (`lib/record.sh`), a lane at the start of its verify | `merge --abort`; `main_conflict` record; the verify goes on without main (`nomerge-<m>`): it can't merge |
| `rebase` (`lib/lane.sh`), main moved under a verified tag | `merge --abort`; `rebase_fail … merge_conflict rebase`; needs Michael |
| `merge_one` (`lib/record.sh`), `git merge-tree` says the tag conflicts with main | `merge_conflict` record, needs Michael; no re-base is tried |
| `slot_open` (`lib/record.sh`), a dependency's tag or the default lane conflicts with main in the lane's base | `base_conflict`, `needs-<m>`; the lane doesn't open |

Two milestones built side by side in this repo always touch `tests/fixtures/check-names.txt`, a `LC_ALL=C` sorted list
of check names, and a real merge of two branches that each add a name between the same two lines is a hard conflict
(`tests/fixtures/git-conflict/names.conflicted.txt`, captured 2026-10-29: `b lane check` vs `b main check` between
`a check` and `c check`). The right merge of such a file is mechanical. Other conflicts (two edits of a paragraph of
`docs/architecture.md`, a function both sides changed) need judgment, and the verify session that exists for
overlapping re-bases (`LANE_REBASE=suite`, `MAX_REBASE_ROUNDS`) is already the gate a judged merge needs.

1. **Layer 1, the sorted merge (no model).** `lib/merge-sorted.sh %O %A %B`: a git merge driver for files that are one
   item per line in `LC_ALL=C` order. The result (written to `%A`, exit 0) is the lines of `%A` and `%B`, minus each line
   in `%O` that either side removed, sorted and unique; a file not sorted on either side (`LC_ALL=C sort -c` fails) exits
   1, so git reports the conflict as usual and layer 2 takes it. Wiring: the project opts in with `.gitattributes`
   (this repo: `tests/fixtures/check-names.txt merge=sorted-union`, committed in this milestone); the harness sets
   `git config --worktree merge.sorted-union.driver "$HARNESS_HOME/lib/merge-sorted.sh %O %A %B"` (and `.name`) in the
   record worktree at start and in each slot at `slot_open` (`extensions.worktreeConfig` is already on, `slot_open`), so
   Michael's own checkout is untouched and a merge in a slot uses the live harness's driver. A merge that layer 1
   settles is a clean merge to every caller: nothing else changes.
2. **Layer 2, the resolve session.** One function, `resolve <who> <what is merged in>`, in a new `lib/resolve.sh`
   (sourced by `lib/lane.sh`), called **instead of `git merge --abort`** in the **lane process** when
   `CONFLICTS=resolve` (the `lib/config.sh` default; `michael` = today's behaviour everywhere): `sync_main` at a lane's
   verify, and `rebase` (with `merge_one`'s conflict routed to it, item 3). **Two places keep today's path:** the
   record branch's own `sync_main` (a resumed start: record-only, its conflict is Michael's), and `slot_open`'s base
   conflicts, which run in the coordinator (`lib/driver.sh`, before the lane process exists): a 30-minute session there
   would block every other lane's reaping, merging and opening, and under `MERGE_POLICY=auto` a dependency's tag is
   normally on `main` already, so these occur only with a held or refused dependency or a diverged branch (rare;
   noted in the decision file as the next step if they show up).
   - The merge is left in progress in the slot. `resolve` lists the conflicted files (`git diff --name-only
     --diff-filter=U`, its format `tests/fixtures/git-conflict/diff-name-only-U.txt`), notes `"<m>: <n> files conflict
     with <what> (<files>); a resolve session"`, renders `prompts/resolve.md`, and runs `session resolve` in the lane's
     scope on `RESOLVE_MODEL` (default `opus`), with `RESOLVE_MAX_TURNS=60`, `RESOLVE_BUDGET_USD=5` and
     `RESOLVE_TIMEOUT=30m` in place of the coding session's limits.
   - **`prompts/resolve.md`** (static first, `decisions/2026-10-21-static-first-prompts`): you are resolving one merge
     in progress; the conflicted files; both sides' commit subjects (`git log --format=%s` of `<merge-base>..HEAD` and
     `<merge-base>..MERGE_HEAD`, path-limited to the files, at most 20 each); the milestone's features (ids,
     descriptions); the rule: keep the intent of both sides, edit only the conflicted files, leave no conflict marker,
     `git add` each file, run only the suite's subset that covers the files (`{{CHECK}} <names>`, the subset form, which
     never reruns; none when the project's suite takes no names) and never the full suite (the verify round after it
     runs that, and 601–857 s of it would not fit the session's timeout), never commit (the driver commits), and end
     with `RESOLVED: <one line per file>` or `UNRESOLVED: <why>`. Its `entry.json` is journaled like a verify's
     (`journal resolve`; stray-file restoring keeps the run record, so the entry survives to the journal).
   - **It is a session for every limit:** a `metrics.jsonl` row of kind `resolve` (spend, the weekly gate, the
     session count and `MAX_SESSIONS` as any session), the memory gate before it, and **no resolve when less than
     `RESOLVE_TIMEOUT` is left before the deadline** (verify's `once` mode included): today's path then.
   - **The driver's checks after the session**, in order: no unmerged path left (`git diff --name-only
     --diff-filter=U` empty); no conflict marker in a conflicted file (`^(<<<<<<<|=======|>>>>>>>)( |$)`); every path
     the session changed is a conflicted path: before the session `resolve` snapshots the index's stage-0 entries
     (`git ls-files -s`, the paths git merged by itself) and the untracked list; afterwards a stage-0 path whose
     content differs is put back from its snapshot blob and a new untracked file is removed, with `note "<m>: the
     resolve session edited <paths> outside the conflict; restored"`; then `git commit --no-edit`
     (the merge commit). A session that ends `UNRESOLVED`, a check that fails, or a refused session (a usage limit:
     `MET limit`) → `git merge --abort` and **today's path at that place**, its needs record's card saying a resolve
     session was tried and why it stopped (one more `card` field, `tried`, in the U2 templates of `main_conflict` and
     `merge_conflict`). **A session refused by a limit (`MET limit`) is deferred, never a stop:** `git merge --abort`,
     `limit_raise` to its reset, no needs record and no `needs-<m>`; in `rebase`, `rebase-<m>` is put back (as a
     refused re-base verify round does today, `rc == 2`) so the lane re-bases after the wait; in `sync_main`, the
     verify goes on without main (`nomerge-<m>`, as today) and its next round tries again. Deferrals are bounded by
     `MAX_LIMIT_HITS` like any refused session.
   - **Bounded:** one resolve session per place per `origin/main` commit,
     marked in `$STATE/resolve-<m>-<sha>`; at most `MAX_RESOLVES=3` per milestone; past it, today's path.
3. **The gate after a resolution** (what makes the invariant hold):
   - `sync_main` at verify: the merge is in; the verify that follows is on the merged tree (its suite in full, its
     session re-checking the milestone's steps), as for any clean merge of main. Nothing new.
   - `rebase`: a resolved merge counts as **overlapping** whatever `LANE_REBASE` says, so it takes the verify round
     (`MAX_REBASE_ROUNDS`) on the merged commit, then the re-tag and merge that exist.
   - `merge_one`: a conflicting `merge-tree` no longer stops there; it returns 3 with `$STATE/moved-<m>` as for a main
     that moved cleanly, so the lane's `rebase` does the merge, the resolution and the round. On the coordinator
     (`harness merge`, `HARNESS_MERGE_ONLY`) it stays today's needs path: no session runs from a CLI command.
   - Before the round, `MAX_REBASE_ROUNDS` is checked: a lane with no round left gets no resolve session (today's
     path), so a resolution never lands unverified.
4. **Visible, not asking.** Each resolution: a `note` (files, model, minutes, the verify round that follows), one row
   in `summary.json` `conflicts: {resolved, escalated, sessions}` (new key), a `report.md` row `| Conflicts | 2 resolved
   by sessions (R2: README.md; R3: docs/architecture.md), 0 to Michael |`, and the milestone's PR body a `Merged main in
   with a resolve session` paragraph listing the files. No needs record and no notification for a resolution that
   passed its gate: Michael asked not to be asked.
5. **Stubs, from real output.** `tests/stub-claude.sh` learns the `resolve` prompt: `STUB_MERGE_RESOLVE=both` (keeps both
   sides' lines in each conflicted file, removes the markers, `git add`, ends `RESOLVED:`), `STUB_MERGE_RESOLVE=markers`
   (leaves a marker), `STUB_MERGE_RESOLVE=stray` (also edits a non-conflicted file), `STUB_MERGE_RESOLVE=give-up` (`UNRESOLVED:`); the name, because `STUB_RESOLVE` already means the M3 `resolved` stub.
   Conflicts in the checks come from real `git merge` in the throwaway repos; the fixtures in
   `tests/fixtures/git-conflict/` (captured 2026-10-29 from `git 2.x` on this box: the merge's stdout, `status
   --porcelain`, `diff --name-only --diff-filter=U`, both conflicted files) are what the stub and `resolve` parse.
6. **Decision and docs.** `journal/decisions/2026-10-29-conflict-resolution.md` (finding · choice · rejected:
   Michael for every conflict; `git merge -X ours/theirs` (drops one side's intent silently); a union driver without
   the three-way removal (brings back a deleted name, and the conformance check would go red); resolving on `main`;
   a resolve session without the verify round; a resolve session in the coordinator for `slot_open`). `docs/architecture.md` §3 (`resolve.sh`, `merge-sorted.sh`, the
   prompt), §5 (the conflict paths), §7 (the gate: a resolved merge is verified), §8 (merge drivers in worktree
   config), §12 (lanes no longer stop on overlap conflicts); `README.md` (`CONFLICTS`, the `RESOLVE_*` settings, the
   `.gitattributes` opt-in for a project's sorted lists); `templates/user/config.sh`.

**Checks (written first),** in new `tests/checks/` files by topic: `merge-sorted.sh` on the fixture pair merges to
`a check`, `b lane check`, `b main check`, `c check`; a name one side deleted stays deleted; an unsorted side exits 1;
in a throwaway repo with the attribute and the worktree config, two branches adding adjacent names merge with exit 0
and no session. A stub run with `MAX_LANES=2` whose two milestones both change one line of `README.md`, with
`STUB_MERGE_RESOLVE=both`: the second lane's re-base conflicts, a resolve session runs, the note names `README.md`, a verify
round runs on the merged commit, the milestone merges, the tree on `main` equals that verified tree (the invariant),
`summary.json` `conflicts.resolved == 1`, no needs record open; the same with `CONFLICTS=michael` → today's
`merge_conflict` record; `STUB_MERGE_RESOLVE=markers` and `give-up` → merge aborted, today's record with `tried`;
`STUB_MERGE_RESOLVE=stray` → the stray file restored with its note and the milestone still merges; a `merge_one` conflict
routes to the re-base (`moved-<m>`); a `slot_open` base conflict with a dependency's tag → today's `base_conflict`
record and no session; a resolve session refused by a stub limit → no needs record, `rebase-<m>` back, and the lane
re-bases and merges after the wait; a third conflict past `MAX_RESOLVES=2` (set in the check) → today's path. `harness merge` on a
conflicting milestone → today's needs path, no session.

---

## Milestones

| M | Contents | After |
|---|---|---|
| N1 | `HARNESS_FAILED=` in `tests/run.sh`; the rerun in `check.sh`; `CHECK_RERUN`; `flakes.jsonl`, `flakes_note`, `summary.json` `flakes`, the report row, the debrief block; docs; `2026-10-29-rerun-guard` | `[]` |
| N2 | `merge-sorted.sh` and `.gitattributes`; `resolve.sh`, `prompts/resolve.md`, the four call sites, the gate, the bounds; `CONFLICTS`, `RESOLVE_*`; summary, report, PR body; stubs; docs; `2026-10-29-conflict-resolution` | `["N1"]` |

Plan each as three to five features, the last a review feature sized to the milestone
(`decisions/2026-10-26-reviews-sized-to-milestone`). The suite ends green at every milestone.

## Not in this run

The test-side causes of the flakes (`wait_for`, barriers, the sleep lint, `--repeat`, the named flakers fixed: the
reliability run's R1); conflicts on the record branch; a conflict session from `harness merge`; any change to
`LANE_REBASE`'s disjoint rule or to `MAX_LANES`; `TEST_JOBS` (`decisions/2026-10-29-check-timeout-25m`).

## After the run (Michael)

- Nothing to configure: `CONFLICTS=resolve` and `CHECK_RERUN=auto` are the defaults. To keep a project asking you
  about conflicts: `CONFLICTS=michael` in its `.harness/config.sh` (portfolio_site's merges into `main` are yours
  anyway under `MERGE_POLICY=pr`; a resolution happens on the lane branch, never on `main`).
- The reliability run, queued behind this one, is the first to use both. The morning after it:
  `grep -E 'flaky:|resolve session' <run dir>/harness-log.md`, and the report's `Flakes` and `Conflicts` rows.
