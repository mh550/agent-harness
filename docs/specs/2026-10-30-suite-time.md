# Suite time: the session is told how long the suite takes, a red tree is cached like a green one, and a change to a mapped file runs only the checks that read it (2026-10-30)

**Goal.** The three fixes of `docs/plans/2026-10-29-suite-time.md` §2 rows 1–3 that save measured lane-seconds without
weakening a guard or asking a session for judgment. **S1:** every prompt's *This run* line carries the last full run's
wall and a timeout rule, so no full run is killed at the tool's default timeout again (fix 3); and `lib/check.sh`
caches a red tree as it caches a green one, so a retry's pre-session run on the tree the post-session run just found
red answers from the marker instead of running the suite again (fix 2). **S2:** a declared map from a path to the
check files that read it (`CHECK_KEY_MAP`), so a tree that differs from a green tree only in mapped paths runs those
files and inherits the green (fix 1): the CLAUDE.md Gotchas line that cost 1,500–2,500 s per case in 10-29-2 then costs
the memlint check's few seconds. Two milestones, **in series** (S2 changes `check.sh` and `treekey.mjs` on top of S1's
marker format).

**Source.** `docs/plans/2026-10-29-suite-time.md` (§2 rows 1–3, §3 steps 4–6, §4's predictions, repeated at the end so
the run's retro can compare) and its diagnosis `findings-and-research/2026-10-29-run-time-budget.md` (§4 what
invalidated the cache, every case; §6 the guards behind every full run; §7 the escape rate of a subset); Michael's brief
of 2026-10-29 ("write the spec for the first three fixes"). The guards these fixes sit beside: `decisions/2026-10-26-suite-split`
(S3: the key is a deterministic function of the tree; LLM-driven selection rejected), `decisions/2026-10-26-verify-runs-the-suite`
(the verify's `run_init fresh` clears the verified tree's marker), `decisions/2026-10-29-rerun-guard` (a red full run is rerun
once), `decisions/2026-10-29-check-timeout-25m` (601 s alone, 857 s paired; `TEST_JOBS` stays).

**Rules.** `CLAUDE.md` binds: worktree only; never touch real runs or real state; fakes mirror the live API (the stub
suites below print the lines `tests/run.sh` prints: `PASS`/`FAIL`, `HARNESS_FAILED=`, `N/M checks passed`); every
behaviour visible in `harness-log.md` (`note`) or in the session's init output, and checked test-first in a
`tests/checks/` file by topic, names in `tests/fixtures/check-names.txt`; `bash -n` and `node --check`; one decision
file per behaviour; `docs/architecture.md` and `README.md` in the same milestone. **Proceed on the defaults written
here; record them in the decision files, marked *default*; never park.** The invariant, with a check in each
milestone: **a tree is never marked green by anything but a green run of every check that reads what changed in it.**
S1 keeps it as today (a marker comes only from a full run of the whole suite on that tree); S2 keeps it by
construction (the reduced key proves every unmapped path unchanged; the map names every check that reads a mapped
path; a lint proves the map complete).

## Depends on

- `main` at or after `4d15739` (PR #59: the reliability run's R1 merged, so `HARNESS_FAILED=`, the rerun guard,
  `flakes.jsonl` and `wait_for` are in; the marker format S1 extends is the one `decisions/2026-10-29-rerun-guard` left).
- No run alive on the box when this one starts (the queue sees to it; the plan's §3 says the same). This run's own
  suites measure nothing: the plan's Phase 2 load curve is a separate step.

## Why in series (S2 after S1)

S2 reads and writes the markers S1 reshapes (`green-<key>` gains a second line; `red-<key>` is new) and changes the
same two files (`lib/check.sh`, `lib/record.sh`'s `run_init`). Built side by side, the two lanes would conflict in
`check.sh` on every feature and in `docs/architecture.md`'s cache rows; a resolve session for that is a session wasted.
S1's first feature gets `after: []`, S2's `["S1"]`.

---

## S1 · The suite's length in the prompt, and a red tree cached like a green one

### Fix 3: the session is told how long the suite takes, and gives the call a timeout to match

**Finding** (findings §4 *The tool timeout*). `prompts/parts/run.md`'s *This run* line says `Suite: … (runs …, cached
per code tree)` and nothing about length; `CLAUDE.md` line 34 says `~3 min 30 s on this box: 208 s measured`, a number
from 2026-10-26 at 392 checks; the suite is 601 s alone and 857 s paired at 859–925 checks. The Claude Code Bash tool's
default timeout is 600 s and its foreground maximum 600 s. In 10-29-2, R1-01's full run was killed at 602 s after
36.5 CPU-minutes and run again (1,180 s lost); R1-02, R2-02, R2-03 and N2-06 (10-29) were "moved to the background"
at 601 s and the session waited on polling turns for each. The harness measures every full run (`check.sh`'s `s`) and
throws the number away.

**Choice.**

1. **The green marker carries the wall.** `check.sh` writes `green-<key>` as two lines: line 1 as today (`<n> tests`
   or empty), line 2 `wall <s>`, the full run's own seconds (the first run's, before any rerun: a rerun is a subset's
   length). Every reader of a marker reads its first line only (`read -r n < marker`, never `cat`): `check.sh`'s cached
   line, `run_init`'s `tests-start`, `tests_end`. An older one-line marker reads as before. The cached line itself is
   unchanged (`check: green (cached for this code tree, N tests)`: `34-check-key.sh` matches it byte for byte, and the
   number belongs in the prompt, not in a line every session's init output carries). *Default:* the wall goes in the
   marker, not in a sidecar, because the marker already outlives scratch (`decisions/2026-10-29-rerun-guard`) and the
   one caller that needs the number is the prompt.
2. **The prompt.** `prompt()` (`lib/prompt.sh`) sets one more variable before rendering, `HARNESS_SUITE_LENGTH`: from
   the current tree's marker (`green-<key>`, or S1's `red-<key>` below, which carries the wall too) when it has a
   `wall` line, else from the newest marker in `$STATE/green/` that has one (by mtime: a continued run's first session
   has the last segment's number), else empty. `prompts/parts/run.md`'s Suite line becomes
   `Suite: \`{{CHECK}}\` (runs \`{{CHECK_CMD}}\`, cached per code tree; last full run {{SUITE_LENGTH}}) · init: …`,
   where the phrase is `601 s: give a full run a timeout of at least twice that` or, with nothing measured yet, `not
   measured yet; bounded by CHECK_TIMEOUT 25m: give a full run a timeout above that`. `parts/run.md` is rendered into
   every prompt but `entry-resume` and `retro`, so the initializer, verify and resolve sessions get the line too.
3. **The rule.** `prompts/coding.md`'s *The suite* ground rule gains: "Give every full run a timeout of at least twice
   its last wall (under *This run*). When that is over the Bash tool's foreground limit (10 min), run it in the
   background with that timeout, its output to a file in your scratch directory, and wait for its end notification
   before reading it: never poll it, never run it without a timeout." *Default:* the background clause, because on
   this repo twice the wall is over the foreground limit, and the plan's "pass `timeout` ≥ 2× that" alone can't be
   followed in a foreground call.
4. **`CLAUDE.md` line 34:** `(~3 min 30 s on this box: 208 s measured with \`TEST_JOBS=4\`, the default here; end-to-end`
   becomes `(see the run's prompt for its length; 10–11 min on this box on 2026-10-29; end-to-end`. *Default, a
   deviation from the brief's wording:* the brief's `at 925 checks` is left out because `lib/memlint.mjs`'s
   `derivable-count` regex matches `<n> checks` and `39-memlint-m4.sh`'s `this worktree prints nothing` would go red;
   the count is the suite's to tell (`decisions/2026-10-26-memlint`).
5. **Decision and docs.** `journal/decisions/2026-10-30-suite-length-in-prompt.md` (finding · choice · rejected: the
   wall in the cached line (every init output would carry it, and the exact-match checks); a fixed number in
   `CLAUDE.md` (it was wrong within three days); reading `tests/run.sh`'s own `wall … s` line (this suite's only)).
   `docs/architecture.md` §3 (`check.sh`: the marker's second line), §4 (the *Suite cache* row), the prompt's
   variables; `README.md`'s suite paragraph.

**Checks (written first)**, in `tests/checks/34-check-key.sh` (the marker's shape) and a stub run in a new file by topic
(`NN-suite-length.sh`): after a green full run the marker's line 1 is the count and line 2 `wall <s>` with `s` an
integer; a one-line marker planted by the check still gives the cached line, `tests-start` and `tests-end` their count;
a stub run's rendered `prompt-coding.md` has `last full run <s> s: give a full run a timeout of at least twice that`
with the `s` of the run's marker, and its initializer prompt the same line; a stub run whose first suite is a cached
green from a planted one-line marker renders `not measured yet; bounded by CHECK_TIMEOUT`; `grep -q "see the run's
prompt" CLAUDE.md` and no `208 s`; `prompts/coding.md` has the background clause; `39-memlint-m4.sh`'s
`this worktree prints nothing` still passes.

### Fix 2: a red tree is cached, so the retry doesn't run the suite on the tree just found red

**Finding** (findings §4 case 2, §6). A red full run writes nothing; the next full call on the same tree runs the suite
again. Every retry after a post-session red pays it: `run_init` before the retry session ran 953 s (R2-01) and 993 s
(R1-02) in 10-29-2 and 824 s (N2-02) in 10-29 on a tree the harness had run twice minutes before (the first run and
the rerun guard's rerun). The retry session's first act, told "suite red before the session", is often another full
run before it edits anything. The rerun guard has already answered the one question a second run could: the red was
not a flake.

**Choice.**

1. **The red marker.** When a full run ends red and neither run was a timeout or a cap kill (`why` says `exit <rc>
   after <s> s`, not `timed out` or `killed at`: a timeout may be the box's load, a cap kill the scope's), `check.sh`
   writes `red-<key>` beside `green-<key>` in `$HARNESS_CHECK_CACHE`, four lines: the exit code it is about to return;
   the first run's `HARNESS_FAILED=` names (empty when the line was absent); `wall <s>` (the first run's seconds, as
   the green marker's); the `check: RED (…)` line as printed. A green run removes `red-<key>` (it can't exist for a
   green key, but a planted one must not survive). *Default:* the whole first-run output is not stored; `check.out`
   and `check-<key>.out` still hold it in scratch for the run's lifetime, and the marker's names and RED line are what
   the session acts on.
2. **The cached answer.** The full form, finding no `green-<key>` but a `red-<key>`, prints
   `check: RED (cached for this code tree: <names | whole suite>)` and on the next line the stored RED line, and exits
   with the stored code. It runs nothing, reruns nothing (the rerun guard ran), writes no output file. The subset form
   (`check.sh <args>`) never reads either marker: its caller is iterating on the tree. A marker is never consulted for
   a different key: any edit makes a new key, and the suite runs.
3. **The driver.** `run_init`'s `suite red before the session (the session is told to fix it first)` log line stays as
   it is: the cached line is in `init.out`, which the prompt's *Init output* carries, so the session sees the names.
   `run_init fresh` (verify, disjoint re-base) removes `red-<key>` with `green-<key>`: the verified tree always runs in
   full. `green()` after a session sees the cached red as a red: the un-pass is unchanged. `run_init`'s baseline
   logic is unchanged (a cached answer writes no `check.out`; `tests-start` is set from the first run that wrote one).
4. **Decision and docs.** `journal/decisions/2026-10-30-red-marker.md` (finding · choice · rejected: caching a timeout
   or a cap kill; clearing the red marker on a timer; a red marker that stores the whole output). `docs/architecture.md`
   §3, §4 (*Suite cache*: `red-<key>`), §7 (the guard table: a cached red un-passes as a red); `README.md`.

**Checks (written first)**, in a new `tests/checks/NN-red-marker.sh` with the stub suite of `73-check-rerun.sh` (a
counter and a mode per case): red twice with `HARNESS_FAILED=a` → `red-<key>` with lines `1`, `a`, `wall <s>`, the RED
line, and no green marker; the next full call → `check: RED (cached for this code tree: a)`, the stored RED line, exit
1, the stub not called again (the counter still 2); a subset call on the same tree runs the stub (counter 3) and prints
no `cached`; a mode that would be green on call 4 still gets the cached red (the key is the tree's, not the suite's);
a red with no `HARNESS_FAILED` line → `cached for this code tree: whole suite`; a timeout (`HARNESS_CHECK_TIMEOUT=2s`)
and a cap kill → no `red-<key>`, the next call runs; a green run removes a planted `red-<key>`; a stub run whose session
leaves the suite red (the stub's red tree) → the post-session run is red and un-passes (today's note), the retry's
`init.out` has the `cached for this code tree` line and the log `suite red before the session`, and the stub suite's
counter shows no third run on that tree; **the invariant:** a stub run at verify with a planted `red-<key>` and a
planted `green-<key>` for the verified tree → `run_init fresh` removes both and the suite runs in full.

### S1-review

One review feature sized to the milestone (`decisions/2026-10-26-reviews-sized-to-milestone`): an Opus reader of the
milestone's diff, findings fixed in the same feature; the marker's readers (`check.sh`, `run_init`, `tests_end`,
`prompt()`) are what to read for a `cat` that survived.

---

## S2 · The declared partial map: a change to a mapped path runs only the checks that read it

**Finding** (findings §4 case 1, §7; plan §2 row 1). `CLAUDE.md` is in the key (`decisions/2026-10-26-suite-split` S3
keeps every path a check reads) and every coding session is told to add a Gotchas line to it after its last full run
(`prompts/coding.md` §3 step 3). The post-session `green` then misses the cache and runs the suite in full, and when
the line is over the 15-line cap, `39-memlint-m4` goes red and the feature is un-passed: 2,500 s and 2,100 s of lane
time for R2-01 and R1-02 in 10-29-2, 1,531 s for R1-01's line that didn't ship; about 6,000 lane-s in that run, 0 in
10-28 and 10-29. The checks that read this repo's `CLAUDE.md` are two: `39-memlint-m4.sh` (`memlint.mjs` over
`$HERE/..`, so `CLAUDE.md` and the decisions store) and `37-memory-prompts-m2.sh` (line 64: `sed` and `grep` on
`$r/CLAUDE.md`, `r=$HERE/..`). *The brief's map of `39-memlint-m4` alone would mark a tree green without running
`37`: the lint below is what makes the map trustworthy, and it finds `37`.* The escape rate of a name-based subset is
0–2.4 % (§7), and both misses were of the kind a declared map catches. The suite-split decision rejected "a list of
paths the suite *does* read" because a new directory would be left out silently; the map is the opposite: a list of
paths with their readers, every unlisted path still in the key.

**Choice.**

1. **`CHECK_KEY_MAP`** in `lib/config.sh` (default empty), the project layer sets it, `prompt_env` exports it as
   `HARNESS_CHECK_KEY_MAP` beside `HARNESS_CHECK_KEY_IGNORE`. Space-separated entries `<path>:<name>[:<name>…]`: a
   file path relative to the tree, then the check-file names the suite's command takes as arguments (`tests/run.sh`
   matches by substring: `39-memlint-m4`). An entry is dropped with one stderr line when its path is under an ignored
   prefix, is a directory, or has no name (a stale green is worse than a slow one: S3's rule). The template
   `templates/project/config.sh` has it commented. This repo's `.harness/config.sh`:
   `CHECK_KEY_MAP="CLAUDE.md:39-memlint-m4:37-memory-prompts-m2"`, plus whatever the lint (item 5) finds on the day.
2. **`treekey.mjs --partial`** prints three things, one per line: the full key (as the bare call prints it: the bare
   call is unchanged, every `$(node treekey.mjs)` caller stays one line); the **reduced key**, the same hash over the
   tree with the mapped paths left out; then one `<blob> <path>` line per mapped path, in map order, `-` for a path
   absent from the tree (the blobs are `git hash-object`'s, already computed for the full key). Without a map the two
   keys are equal and no blob line follows. The key functions are exported and unit-checked with
   `node --input-type=module -e`.
3. **The sidecar.** A green full run writes, beside `green-<full key>`, `part-<reduced key>`: line 1 the full key of
   that green tree, then its `<blob> <path>` lines. It is the green tree's content of the mapped paths, so a later tree
   can tell which mapped paths differ. A partial run never writes one (comparing against the original full-run tree
   stays sound: any mapped path that differs from it runs its files).
4. **`check.sh`, full form**, after the green and red markers are looked up and before the full run: with a map, when
   `green-<full>` is absent, `part-<reduced>` exists, its line 1 names a `green-<ref>` that exists, and its path set
   equals the map's path set (else: **sidecar mismatch, the full run**), the mapped paths whose blob differs from the
   sidecar's are the set *S*; *S* empty or holding a path not in the map → the full run (can't happen with the reduced
   keys equal; checked anyway). Otherwise the **partial run**: `<cmd> <the union of S's names, in map order>` through
   `run()` (same scope, cap and timeout), its output to `check-partial.out` (never `check.out` or `check-<key>.out`,
   which stay the last full run's: every count the driver reads from them is a full run's). The rerun guard applies
   as to a full run, on the subset: red and not a timeout or cap kill → one rerun of the `HARNESS_FAILED=` files, else
   of the subset again, output in `check-rerun.out`; a green rerun is a `flakes.jsonl` row as any.
   - **Green:** `green-<full>` is written with the **reference tree's** two lines (`green-<ref>`'s count and wall: the
     partial's count is its subset's and its wall is seconds), `red-<full>` removed, and the line is
     `check: green (partial: <files>, <s> s; cached for the rest)` (after a flake: `check: green after a rerun (partial:
     <files>; flaky: <names>), <n> tests`), exit 0.
   - **Red:** `check: RED (partial: <files>; exit <rc> after <s> s[; red again on a rerun of …]) — last lines of
     <out>:` and the tail, exit as the run did; **no marker of either kind** (*default:* the red marker is for a
     900 s run; a partial is seconds, and the retry's pre-session run redoing it costs nothing).
   - A timeout or a cap kill in a partial run is said as today's `why` says it, no rerun, no marker.
   - The subset form (`check.sh <args>`) never reads the map, the sidecar or any marker.
5. **The lint: what each check file reads.** A check in `tests/checks/` (the suite's own, beside `33-suite-runner.sh`'s)
   that fails when a check file reads a mapped path and isn't in its entry: for each entry of this repo's
   `CHECK_KEY_MAP`, a check file *reads* the path when (a) a line of it names the path (or its basename) beside a
   path into this repo (`$HERE/..`, or a variable set to it on that line, as `37`'s `r=$HERE/.. && … "$r/CLAUDE.md"`),
   or (b) a line passes the repo root bare (`$HERE/..` followed by a quote, a space, `)` or the end of the line, not
   `/`) to anything but the forms the lint lists as not reading the memory files, each with one line of why:
   `HARNESS_HOME=$HERE/..` (the harness run from this checkout reads `lib/`, `prompts/`, `templates/`, `bin/`, never
   its own repo's `CLAUDE.md`), `git -C "$HERE/.."` (git metadata), `readlink -f "$HERE/.."`,
   `harness_config "$HERE/.."` (`.harness/config.sh`) and `(cd "$HERE/.." && pwd)`. Every file the rule finds must be
   in the entry; the check lists each miss as `<file>:<line> reads <path>, not in CHECK_KEY_MAP`. The rule
   over-approximates on purpose: on today's tree it finds `39` (rule b: `$M "$HERE/.."`), `37` (rule a), and by rule
   (b) `36-run-16-retro-backlog.sh` (`cd "$HERE/.." && $H backlog import`) and `75-suite-tools.sh`
   (`cd "$HERE/.." && bash tests/lint-sleeps.sh`), which read the state root, a seed and `tests/`, not `CLAUDE.md`.
   *Default:* a file the rule finds joins the map rather than the allow-list growing per command: a wider map runs more
   than needed (about 30 s of the two) and stays sound; a narrower allow-list is the judgment the gate must not rest
   on. The session may instead rewrite such a line not to pass the root (the lint is then the proof), and records
   which. The map's final form is whatever makes the lint green on the day, listed in the decision file.
6. **The driver.** `run_init fresh` removes `green-<full>`, `red-<full>` **and `part-<reduced>`** for the tree as the
   init left it: with the full marker gone but the sidecar in place, the verify's run would be a partial run on a tree
   whose only change is a mapped path, and `decisions/2026-10-26-verify-runs-the-suite` says the verified tree runs
   in full. Nothing else in `lib/lane.sh`'s verify path changes. The post-session `green()` and the pre-session
   `run_init` need no change: a partial green is `check.sh` exiting 0.
7. **Visible.** `check.sh`'s line names the files and says `cached for the rest`; the driver's `run_init` writes the
   init output as today, and the post-session `green` is silent as today, so the session's `harness-log.md` line after
   a partial green is unchanged: *default*, no new note (the suite's own line is in `init.out`, and a note per
   partial run would be one per session). The cached line's `key ignores:` suffix is unchanged.
8. **Decision and docs.** `journal/decisions/2026-10-30-partial-key.md` (finding · choice · rejected: a name-based
   subset for every post-session run (plan fix 5: the median subset is 73 % of the files here, and its escape rate is
   not zero); an LLM choosing the subset (S3's rejection stands); directory entries in the map; the map read by the
   subset form; a partial run writing the sidecar). One `Updated in place 2026-10-30: …` line in
   `decisions/2026-10-26-suite-split` under S3 (the rejected "list of paths the suite does read" is now a map of paths
   to their readers, the lint its guard against the silent miss, every unlisted path still in the key).
   `docs/architecture.md` §3 (`check.sh`, `treekey.mjs --partial`), §4 (*Suite cache*: `part-<key>`, `check-partial.out`
   in the *Scratch* row), §7 (the cache guard: the invariant and the lint), §10 (`CHECK_KEY_MAP`); `README.md`
   (`CHECK_KEY_MAP`, how a project declares an entry and what the lint demands of it); `templates/project/config.sh`.

**Checks (written first)**, in a new `tests/checks/NN-partial-key.sh` with a throwaway repo (as `34-check-key.sh`'s `ky`)
whose stub suite records its arguments (as `73-check-rerun.sh`'s) and a map `CLAUDE.md:memlint README.md:readme`:
`treekey.mjs --partial` on two trees that differ only in `CLAUDE.md` prints different full keys, the same reduced key,
and blob lines that differ at `CLAUDE.md` only; without a map, two equal keys and no blob line; a dropped entry
(ignored prefix, directory, no name) is one stderr line and leaves the keys as without it; a green full run writes
`green-<full>` (two lines) and `part-<reduced>` (the full key, then the blob lines); **a `CLAUDE.md`-only diff from the
green tree runs the stub with exactly `memlint` and prints `check: green (partial: memlint, <s> s; cached for the
rest)`, exit 0, `green-<full>` holding the green tree's count and wall, and the next call on it cached green**; **a
`lib/` diff runs in full** (the stub called with no arguments); a diff of both mapped paths runs `memlint readme` in map
order; **a `CLAUDE.md` diff whose `memlint` is red** (the stub red on `memlint`, `HARNESS_FAILED=memlint`) is rerun
once on `memlint`, red again → `check: RED (partial: memlint; …; red again on a rerun of memlint)`, exit 1, **no
`green-` and no `red-` marker**; the same red once then green → a partial flake row and the green line; **the sidecar
mismatch runs in full**: a `part-` whose reference marker is gone, and one whose path set is not the map's (the map
grew an entry), each → the stub called with no arguments; the subset form on the diffed tree runs the subset and reads
nothing; a stub run (`STUB_EDIT=CLAUDE.md` after a green init, as `34-check-key.sh`'s runs) whose session edits only
`CLAUDE.md` → the next session's `init.out` has `partial:` and the suite's call log shows the mapped file alone, and
the run's `tests-end` is the full count; **the invariant** at verify: a stub run with the map whose verified tree
differs from the last green tree in `CLAUDE.md` only → `run_init fresh` removed `part-<reduced>` too and the verify's
suite ran in full (the stub called with no arguments, the note `suite cache cleared` as today); **the lint**: on this
repo it passes with the map as committed, and on a copy of `tests/checks/` with one more file that `grep`s
`"$HERE/../CLAUDE.md"`, and one that passes the bare root to a new command, it fails naming each file and line;
`CHECK_KEY_MAP` default empty in `lib/config.sh`, this repo's value in `.harness/config.sh`, exported by `lib/prompt.sh`,
commented in the project template.

### S2-review

One review feature sized to the milestone: an Opus reader of the diff, findings fixed in the same feature; what to
read hardest is the partial path's conditions in `check.sh` (every branch that must fall through to the full run), the
sidecar's path-set comparison, and `run_init fresh`'s three removals.

---

## Milestones

| M | Contents | After |
|---|---|---|
| S1 | fix 3: the marker's `wall` line, `HARNESS_SUITE_LENGTH`, `parts/run.md`'s Suite line, `coding.md`'s timeout rule, `CLAUDE.md` line 34; fix 2: `red-<key>`, the cached RED answer, `run_init fresh` clearing it; docs; `2026-10-30-suite-length-in-prompt`, `2026-10-30-red-marker`; S1-review | `[]` |
| S2 | fix 1: `CHECK_KEY_MAP`, `treekey.mjs --partial`, `part-<key>`, the partial run in `check.sh`, `run_init fresh` clearing the sidecar, the lint, this repo's map; docs; `2026-10-30-partial-key` and the S3 line; S2-review | `["S1"]` |

Plan each as three to five features, the last the review feature above (`decisions/2026-10-26-reviews-sized-to-milestone`).
The suite ends green at every milestone.

## Predictions (plan §4, repeated here so the run's retro can compare)

For the next real two-lane runs after S1 and S2 land, against 10-29-2:

| Measure | now (10-29-2) | after fixes 1–3 |
|---|---|---|
| non-session share of lane time (no pause) | 15–25 % | **10–18 %** (the duplicate pre-retry runs gone; post-session misses on CLAUDE.md gone) |
| suite wall per run, every caller | 34,000 lane-s per 20 sessions | **26,000–30,000** |
| CPU per run in suites | 70–95 CPU-h | **60–80 CPU-h** |
| solo suite wall | 624 s | unchanged, 600–680 s (the suite keeps growing ~5 % per run) |
| flakes per run | 3–6 after R1 | 3–6 (fixes 1–3 don't touch load) |
| un-passes from a red suite | 1–2 | **0–1**: a Gotchas line over the cap is caught by the mapped memlint run, seconds, not 900 s later |
| features thrown out for a red suite after a retry | 0 | 0 |
| main green after milestone merges | 100 % | 100 % |
| tool-timeout hits ("moved to the background", a kill at 600 s) | 2–5 | **0–1** |

The plan's measured sum for fixes 1–3 is about 9,000 lane-s per two-lane run (16 % of lane time, 26 % of suite time).
Falsifiers: a partial green followed by a red verify on the same tree with only mapped paths changed (the map or the
lint is wrong); a tool-timeout kill in a session that had the line (the rule isn't followed: a prompt problem, fix 4's
territory); a retry's `run_init` running the suite on a cached-red tree (the key changed under it: find what).

## Not in this run

Fixes 4–7 of the plan (the one-full-run prompt rule, the name-based post-session subset, fewer process starts, the
box-wide token and its 8-job variant); `TEST_JOBS` (`decisions/2026-10-29-check-timeout-25m`); any subset for the
post-session green beyond what the map declares; anything in `lib/lane.sh`'s verify path (`run_init fresh` is
`lib/record.sh`'s, and that is the one call changed); the plan's Phase 2 measurements (steps 1–3). Known and left, for
a later map entry or ignore-list change, not this run: `39-memlint-m4` also reads the decisions store under
`journal/decisions`, which `CHECK_KEY_IGNORE` leaves out of the key, so a decision file alone never reruns memlint.

## After the run (Michael)

- Nothing to configure for other projects: `CHECK_KEY_MAP` is empty by default and every behaviour of S1 is on for
  every project. dj-crate-streaming's suite (over 5 min) gets the prompt line and the red marker; hit_list's gets the
  red marker.
- The morning after the next real run on this repo: `grep -rE 'partial:|cached for this code tree: ' <state dir>`
  (the rendered prompts' *Init output* and `init.out` are there) and `grep -c 'un-passed: suite red'
  <run dir>/harness-log.md`, against the table above.
