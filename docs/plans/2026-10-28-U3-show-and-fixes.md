# U3 · `harness show`, the remaining views, and the small fixes: plan

Spec: `docs/specs/2026-10-27-status-ux.md` §U3 items 1–7 and its checks, *Before → after* (`harness show`, *The small
fixes*), *Defaults for open questions* 11–12, *The output contract*. U1 (`lib/view.mjs`, `lib/status.mjs`) and U2
(`lib/needs.mjs`, `lib/inbox.mjs`) are on main (`d0403e5`); every site below is named by function and file, never by
line. U3-02 to U3-07 build, U3-08 reviews; this file is U3-01. Nothing here changes code: the suite is as the init left
it (785 checks, green).

Facts checked for this plan (git 2.43, this box), so the builders needn't re-derive them:

- `git diff --numstat --name-status A B` prints **only** the name-status lines (the last format wins). `show` runs two
  diffs, `--numstat` and `--name-status`, both with `--no-renames` (one path per row, so the two join by path); a
  binary file's numstat is `-\t-`, shown as `bin`.
- `git merge-tree --write-tree --name-only <ours> <theirs>` on a conflict exits 1 and prints the tree OID, the
  conflicted paths one per line, a blank line, then the messages (`tests/fixtures/merge-tree-name-only.txt`, U2). Exit
  0: no conflict; any other exit: unknown (no mark, never a crash).
- Since lanes (P1), a run's **code is on its lane branches** `harness-lane/<run>/<m>` (local branches of the project
  repo: the slots are its worktrees) and `harness/<run>` holds the record only; a merged milestone's lane branch goes
  (`lane_branch_gone`) and its tag `run/<run>/<m>` stays. A pre-lanes run has its code on `harness/<run>`. So "a run's
  branches" below is always: `refs/heads/harness/<run>` plus every `refs/heads/harness-lane/<run>/*` (an
  `refs/remotes/origin/harness-lane/<run>/<m>` with no local branch of that name counts too), each diffed outside
  `.harness/runs/`.
- The throwaway project of `tests/lib.sh` has a GitHub-shaped origin (`git@github.com:test/proj.git`, rewritten by
  `insteadOf` to `$T/origin.git`): `notify.mjs compareUrl` gives `https://github.com/test/proj/compare/main...<b>`.
  A plain-path origin needs a second throwaway repo in the check.
- With `MERGE_POLICY=auto` (the suite's base config) a stub run's verified milestone merges and its lane branch goes:
  a `show`/overlap check that needs unmerged code uses `MERGE_POLICY=pr`, or a run stopped before its milestone
  verifies.
- `tests/checks/08-scope-sh-…-gc-scratch.sh` (and its replay in `13-run-2-michael-sets-desk.sh`) asserts today's
  `? harness-oth-svc.scope (no run of this project)` (an ended run of another project) and `? harness-nosuch-svc.scope
  (no run of this project)`. U3-03 changes those two expectations (the first line goes, the second gets the new text);
  the check's name stays.
- `lib/status.mjs` already reads a run's `summary.json` from the record, then the state, then
  `<ledger>/<project>/<run>/summary.json` (`readRun`), so `harness status` shows a gc'd run's passing count today;
  `cmd_report` is the one reader that stops at the worktree and the state.

## 1. Project names (U3-02, bug c)

`project_dir <arg>` in `bin/harness`, beside `toplevel`, prints an absolute directory or dies:

1. `git -C "$arg" rev-parse --show-toplevel` succeeds → that top level (today's behaviour: `.`, a relative or
   absolute path, a subdirectory). A bare name that is also a repository under the current directory resolves here.
2. `$arg` has no `/` → the `PROJECT_DIR` of the newest run of that name: `$STATE_ROOT/<arg>/*/meta.env`, newest by
   the file's mtime (`meta.env` is rewritten at every start), its `PROJECT_DIR` read in a subshell (`source`) as the
   other readers do; taken only if it is still a git repository (its top level).
3. `$arg` has no `/` → `${HARNESS_PROJECTS:-$HOME/projects}/<arg>` when it is a git repository (its top level).
4. Else: `harness: no project '<arg>': not a git repository here, no run of a project named <arg>, no
   <projects>/<arg> (projects with runs: <a>, <b>, …)` and exit 1 — `<projects>` with the home directory as `~`; the
   list is the sorted directory names under `$STATE_ROOT` that hold a `*/meta.env` (never `queue`), `none` when empty.
   A name with a `/` that isn't a repository skips 2 and 3 and gets the same message.

Callers (each replaces `toplevel "$1"`): `cmd_init`, `cmd_start`, `cmd_queue add` (the entry stores the resolved
absolute path, so the runner's `entry_project` and `status.mjs queueEntry` still take its basename), `cmd_gc`, the
`memlint` arm of the dispatcher. `cmd_status --project <p>` (and `-p`): `project_dir` in a subshell, its basename
passed to `status.mjs`; when it fails and `<p>` has no `/`, `<p>` itself (a read-only filter: a project whose checkout
is gone keeps its old runs listable, today's behaviour). `toplevel` stays for nothing else and goes if unused.

## 2. A finished run keeps its record after gc (U3-03, bug b)

**`finish`** (`lib/driver.sh`): after the last `SUM report "$REC/summary.json" > "$REC/report.md"` (the one after the
retro) and before `rec_commit "HARNESS: summary and retro"`: `cp -f "$REC/summary.json" "$REC/report.md" "$STATE/"`
and `metrics.jsonl` beside them (`report`'s memory peaks read `metrics.jsonl` next to `summary.json`), then `note
"summary.json and report.md kept in the state dir (harness report reads them after gc)"`. A failed copy is noted
(`could not keep …`) and never ends `finish`.

**`cmd_report`** (`bin/harness`), per run id, in this order:

1. the worktree exists → the rebuild into `$STATE/summary.json` and the `metrics.jsonl` copy, as today;
2. else `$STATE/summary.json`;
3. else `${HARNESS_LEDGER:-$HARNESS_HOME/ledger}/<project>/<run>/summary.json` (`<project>` = `basename
   $PROJECT_DIR`): copied into `$STATE` with its `metrics.jsonl` (if any) on this first read, then reported;
4. else `## <run>: no record (worktree removed; nothing in <state dir> or <ledger dir>/<project>/<run>)` — both paths
   with the home directory as `~`.

A run id with no state dir at all (state removed by hand) but a ledger copy (`<ledger>/*/<run>/summary.json`) is
reported from the ledger without a copy (nowhere to copy to); one with neither keeps `state_of`'s `no run` error.

## 3. gc's foreign units (U3-03, bug d)

`cmd_gc`'s unit loop collects every run that `scope_owns` the unit, of any project, as today, then:

- no owner on the box → `? <unit>: no run on this box owns it (systemctl --user stop <unit> by hand)` (the same line
  under `--dry-run`);
- owners, none of this project → skipped silently, live or ended (that project's gc handles it);
- an owner of this project → today's rule unchanged (a live owner of any project keeps it; else `would:` / `+
  stopped` / `! could not stop`).

## 4. `harness show <run> [<feature>] [--files] [--json]` (U3-04)

`cmd_show` in `bin/harness`: `state_of`, then `run_rows 0 <run> | node lib/show.mjs <run> [<feature>] [--files]
[--json] --state-root … --ledger … --queue …` (no `harness_config` writes, no fetch, no lock: `GIT_OPTIONAL_LOCKS=0`
as `status.mjs gitOf`). `lib/show.mjs` (usage header) reads with `status.mjs readRun`/`runObject`/`readNeeds` and git
in `PROJECT_DIR` (the branches live there, so a removed worktree changes nothing); its renderers are pure exports
taking the facts (`renderShow(doc, ctx, env)`, `renderFeature(doc, ctx, env)`), checked in node.

**The header** is the run card's: `status.mjs` gets an exported `cardHeader(r, x, extra, ctx)`, the header line
`renderCard` builds today (moved out, `renderCard` calling it: its output byte for byte), then a full-width rule.

**Fields** (`view.mjs card`, label column 11, the order below; a field with no value is left out):

| label | value |
|---|---|
| `worktree` | the path (`~`), then `(clean)` or `(<n> changed files)` (`git -C <wt> status --porcelain --untracked-files=normal`, lines counted); `removed` when gone |
| `branch` | `harness/<run> @ <short head> · <a> ahead, <b> behind` (`rev-list --left-right --count refs/remotes/origin/main...refs/heads/<b>`); `(gone)` when the ref is |
| `compare` | none: the URL goes on its own indented line after the fields (the contract's URL rule): `compareUrl(origin, "main", <b>)` for each run branch with changes (`harness/<run>`, then each lane branch), only when `compareUrl` gives one (GitHub-shaped origin) |
| `record` | `<wt>/.harness/runs/<run>/` (`~`, cut at the front at narrow width) |
| `state` | the state dir (`~`) |
| `lanes` | when `$STATE/lanes/*` exists: one line per lane, `<m> · harness-lane/<run>/<m> · slot <k>` (`<k>` from the slot path in `lanes/<m>/slot`, as `status.mjs laneLine` cuts it; the path itself in `--json`), `· open` while its pid lives (`readRun`'s `live`), `· closed` else |
| `merged` / `proposed` | one line per milestone with a `merged into main · <url>` / `<m> proposed for merging · <url>` note in `harness-log.md` (the record's, else the ledger copy's): `<m> · tag run/<run>/<m> · PR #<n>` (`#<n>` from a `/pull/<n>` URL, else the URL on its own line); a `merged into main (already there)` / `(by its PR)` note gives the tag alone |

**`CHANGES vs origin/main · <n> files · +<a> −<d>`** (a `view.mjs section`): per run branch B (§ facts), `base=$(git
merge-base origin/main B)`, then `git diff --no-renames --numstat $base B -- . ':!.harness/runs'` and `--name-status`
the same, joined by path; across branches a path's +/− are summed and its status letter is the first branch's
(`harness/<run>` first, then lanes by milestone). Rows: status letter, path (cut at the front: `cutFront`), `+<a>`
`−<d>` right-aligned, `✗ conflicts` on a path that `git merge-tree --write-tree --name-only origin/main B` lists for
any B (paths under `.harness/runs/` never). Sorted by `a + d` descending, then path; the 12 largest, then `+<k> more:
harness show <run> --files`; `--files` prints every row. Narrow (< 72): status, path, the mark glyph alone, `+<a+d>`
(the mockup's 60-column form). No branch or no changes: `CHANGES vs origin/main 0`.

**`CONFLICTS with origin/main <n>`** when n > 0: the paths joined with ` · `, word-wrapped at the width.
**`NEEDS YOU <n>`** when n > 0: one line per open item (`readNeeds`, the status card's order), `⚠ <headline>`, then
`  harness needs <run>`.

**The feature form** (`show <run> <id>`; an unknown id: `harness: no feature '<id>' in <run>`, exit 1): the header and
rule, then a card: `feature` `<id> · <milestone> · passes|not passing · attempt <a> of <max>` (`attempts.json`,
`max-attempts`), `description` (word-wrapped), `steps` (numbered `1.` …, each cut to the width), `sessions` (one line
per `metrics.jsonl` row of the feature: `<at as when()> · <role> · <model alias> · <wall_s as min> · $<cost> ·
<result|exit>`), `files` (the union of its `entries.jsonl` rows' `files`, absolute: relative ones joined to the
worktree; `~` in text), `commits` (`git log --format='%h %s' --grep '^<id>\b\|^WIP: <id>' <every run branch> <every
tag run/<run>/*>`, the id regex-escaped, newest first, deduplicated), then its open needs card when it has one
(`needs.mjs renderCard`). A gc'd run: the list from the ledger copy's `feature_list.json`; commits from the tags.

**`--json`** (`"v": 1`, no glyphs, absolute paths): `{v, run, project, state, end_reason, passing, total, worktree:
{path, exists, changed}, branch: {name, head, ahead, behind}, compare, record, state_dir, lanes: [{milestone, branch,
slot, open, compare}], milestones: [{id, status: "merged"|"proposed", tag, pr}], changes: {files, added, deleted,
rows: [{status, path, added, deleted, conflict}]}, conflicts: [path], needs: [{ref, reason, headline}]}`, rows never
cut; the feature form adds `feature: {id, milestone, description, passes, attempts, max_attempts, steps, sessions:
[metrics rows as stored], files, commits: [{sha, subject}], card}`. Key paths listed in a fixture
`tests/fixtures/show-json-keys.txt`, compared by the check as `status-json-keys.txt` is.

## 5. Same-project starts (U3-05, bug e first half)

A helper `project_busy <project name> [<except run>]` in `bin/harness`: the id of the first run under
`$STATE_ROOT/<name>/` other than `<except>` whose driver is `alive` or which has a `lane_live` lane; status 1 when none.

- **`cmd_start`**, without `--now` and not `--foreground`, before the `MAX_PARALLEL_RUNS` branch and with or without a
  run id: `project_busy "$(basename "$p")" "$run"` → `queue_add start <p> [<run>] <its options>` (the same argument
  list the `MAX_PARALLEL_RUNS` branch builds), `echo "<R> is running on <project>: queued (the runner starts it when
  that run ends; --now starts it anyway)"`, `queue_ensure_runner`, return 0.
- **`cmd_continue`**: the same test **before it changes any state** (attempts reset, markers, `ended`): unless the
  rest has `--now` or `--foreground`, a busy project queues `continue <run> --queued --requested <rest>` (as `queue
  add --continue` writes it; an existing entry for the run is replaced the same way), prints the message, ensures the
  runner, returns 0. Done in `cmd_start` alone, a continue would have removed `ended` and queued a run that reads as
  crashed meanwhile.
- The runner's own starts pass `--now`, so they are unchanged; it keeps holding entries by project
  (`busy_projects`). `harness merge` runs `--foreground`: unchanged.
- `note`: the start writes no record (nothing has started), so the message is the visible trace, plus a
  `queued behind <R>` line in `runner.log` when the runner is ensured. The CLAUDE.md "visible in harness-log.md" rule
  is met by the run's first line once it starts (`run <id> on …`), recorded in the decision as such.

## 6. Overlaps (U3-05 `lib/overlap.mjs`, U3-06 the wiring; bug e second half)

**`lib/overlap.mjs`** (pure, usage header, node stdlib only):

- `named(text, tracked)` → sorted unique entries of `tracked` the text names. Tokens: every backticked span, and every
  bare word matching `[A-Za-z0-9_.-]+(/[A-Za-z0-9_.*<>-]+)+/?` (path-shaped: at least one `/`), stripped of trailing
  `.,:;)` and a `:<line>` suffix. A token names: the tracked path equal to it; or, when it ends in `/` or holds a glob
  (`*`, `<`), the directory before the first glob segment, as `dir/`, when some tracked path starts with it and the
  directory has **two or more segments** (`tests/checks/` yes, `tests/` and `lib/` no: every run touches those); a
  token without `/` names only a top-level tracked file of that exact name (`CLAUDE.md`, `README.md`). Never anything
  under `.harness/runs/`.
- `overlap(a, b)` → the sorted intersection, where a file equals a file, and a `dir/` entry meets a file under it (the
  file is reported) or the same `dir/`.
- A CLI for bash: `node lib/overlap.mjs named <tracked file> < text` and `overlap <file a> <file b>` (one entry per
  line in and out).

**Which runs, which files** (a helper `overlaps <project dir> <new run or ""> <spec files> <brief text>` in
`bin/harness`, printing `<R>\t<file>` lines):

- tracked = `git -C <p> ls-tree -r --name-only origin/main`; the new run's names = `named` over each spec file's text
  (`<p>/<f>`, else `git show origin/main:<f>`) plus the brief.
- each other run R of the project (`$STATE_ROOT/<name>/*/meta.env`, R ≠ the new run) that is alive (`alive` or
  `lane_live`), or ended with a non-empty `git diff --name-only $(merge-base origin/main B) B -- . ':!.harness/runs'`
  over its branches B (§ facts): R's files = that diff's union plus `named` over R's `SPEC_FILES` (its `run.env`) and
  `$STATE/brief.md`. An ended run with nothing unmerged is never compared.
- an overlap = `overlap(new, R)` non-empty.

**What an overlap does** (never holds, with or without `--now`):

- `cmd_start` (by hand, by `continue`, or by the runner, whose output is `runner.log`), once the run id is known and
  `meta.env` written, before the driver starts: per R, `warning: overlaps <R> on <f1>, <f2>, …` (at most 6 names, then
  `and <k> more`) on stderr, then an `overlap` record (needs_michael · warn · empty priority, `REASONS` as U2 left it)
  on the new run (subject R) and on R (subject the new run), each `node lib/needs.mjs open <state> <run> <project>
  overlap <subject> files=<newline list> second=<the new run> worktree=… record=… list=… inbox=… origin=…` under
  `flock <that state>/record.lock` (the lock `record()` takes: a live R's lanes open records under it too). A
  refreshed key (`overlap:<subject>`, exit 3) is fine. The new run's open is noted in its `harness-log.md` by the
  driver's first commit (the `needs.md` re-render); R's is noted in R's log by bin/harness (`- <date> · needs: overlap
  with <new run> opened`), committed with R's next record commit.
- `queue add` (a `start` entry; `--continue` too, the run's spec and brief): the same warning, no record (the new run
  has no state dir yet; the records come at its start).
- `status.mjs queueEntry`'s `overlap` (`[]` since U1) is filled: `status.mjs` gets the overlaps from bash (`cmd_queue
  list` and `cmd_status` pass `--overlaps <file>`, the `overlaps` helper's lines per entry, computed for queued
  entries only) and `queue list` shows `⚠ overlaps <R> on <files>` as the entry's sub-line; `status --json`'s queue
  entry `overlap` lists `{run, files}`. (A key path in `status-json-keys.txt` changes: the fixture is updated.)
- the template: `TEMPLATES.overlap` (U2) gets `second` in its why (`<second> merges second: its merge conflicts on
  these files unless <first> is merged first and it continues from there`), its `U3` placeholder words go.
- **sweep**: `needs.mjs rule`'s `overlap` (U2's `return null`) → `other run merged` when R has no branch changes left
  (the same diff, empty) and `other run gone` when R's state dir or all its branches are gone; `this run merged` when
  the run's own branches have none left. `readState` computes these for open overlap items only (`st.overlaps: {<R>:
  "open"|"merged"|"gone"}`, git in `PROJECT_DIR`), so `rule` stays pure; `harness needs done <ref>` resolves one by hand
  as any other.

## 7. The TTY forms (U3-07)

Whether a view is for a person: `view.mjs context` (`HARNESS_TTY=1|0`, else `process.stdout.isTTY`), and in bash a
helper `tty_out() { [[ ${HARNESS_TTY:-} == 1 ]] || { [[ ${HARNESS_TTY:-} != 0 ]] && [[ -t 1 ]]; }; }`.

- **`harness report [<run>…] [--md]`**: `summary.mjs report` gets `--md` (markdown, as today) and, without it, renders
  `reportView(s, metrics, ctx)` when `ctx.tty`: a `view.mjs card` with header `<run> · <project>` and the markdown
  table's rows as fields (`passing`, `tests`, `spend`, `by role`, `review`, `tokens`, `quality`, `time`, `lanes`,
  `sessions`, `ended`, `not passing`; `**` dropped), then the not-passing features as a `view.mjs table` (id, cause,
  detail flex, sessions, $), then the memory peaks as a section. Off a TTY or with `--md`: `report()`'s string,
  unchanged. `finish`'s two `SUM report` calls pass `--md` (a file is no TTY, but `HARNESS_TTY=1` in a test or a
  shell must never reach `report.md`). The `## <run>: no record …` line is the same in both forms.
- **`harness trends [--all] [--md] [--by version]`**: on a TTY without `--md`, `trendsView(rows, {all}, ctx)`: a
  `view.mjs table` of the newest 15 rows by `ended_at` (run, project, passing `p/t`, tests, `$`, `$/f`, wall h, ended
  flex, not passing), then `<k> older: harness trends --all` when rows were left out, then the total line over **all**
  rows (the markdown's last line's text). `--all`: every row. `--by version` keeps its markdown in both forms (a
  default; a short table nobody reads at the terminal yet). Off a TTY: today's bytes; `--all` changes nothing there.
- **`harness gc <p> --dry-run`** on a TTY: `cmd_gc` re-runs itself with `GC_SECTIONS=1` piped into `node lib/view.mjs
  gc`; under `GC_SECTIONS=1` each step first prints a marker line `\x1e<SECTION>` (`UNITS` before the unit loop,
  `TMUX` before `tmux_reap`, `DESKS` before the desk gc, `WORKTREES` before the worktree loop and slots, `DEPS` before
  `--deps`, `BRANCHES` before the record-only tails and the branch passes). `view.mjs gcView(text, ctx, env)` (pure)
  groups the lines under `section(<title>, <lines>, "", ctx)` headers in that order (an empty one is one line), the
  home directory as `~`, and ends with a rule and `would remove <w> worktrees, <b> branches; keeps <k>` (`w`: `would:
  git -C … worktree remove` lines; `b`: distinct branch names in `would: git … branch -d|-D <b>` and `would: git … push
  -q origin --delete <b>` lines; `k`: lines starting `keeps `). Off a TTY, a real gc, and every run without
  `--dry-run`: no markers, today's lines in today's order (`runner.log` and the checks read them).

## 8. Checks and fixtures

Check files (one per topic, new numbers after `64-needs-review.sh`; every name in `tests/fixtures/check-names.txt`,
`LC_ALL=C` sorted, copied from the PASS lines):

| file | feature | checks (intent) |
|---|---|---|
| `65-project-names.sh` | U3-02 | from `$T` (outside `proj`): `harness gc proj --dry-run` and `harness status --project proj` resolve by the runs' `PROJECT_DIR`; with no run of `proj2` and `HARNESS_PROJECTS=$T/projects` holding a `proj2` repo, `harness queue add proj2 --brief x` queues its absolute path; `harness gc nope` exits 1 and its stderr names the three places and `proj`; `harness start proj …` from `$T` starts in `$T/proj` |
| `66-record-after-gc.sh` | U3-03 | a stub run ends; `state/summary.json` and `report.md` exist; `harness gc proj --all-merged` removes its worktree; `harness report <run>` prints its `## <run> · proj` table from the state copy; with that file removed, from the ledger copy, after which the state copy exists again; with both gone, the `no record (worktree removed; …)` line naming both paths; `harness status` shows its `n/n passing` |
| `67-gc-units.sh` | U3-03 | `gc --dry-run` with a stub unit of another project's live run prints no `?` line; with an unowned `harness-x.scope` prints `? harness-x.scope: no run on this box owns it (systemctl --user stop harness-x.scope by hand)`; the `would:` lines as before (and 08's check rewritten for the two `?` lines) |
| `68-show.sh` | U3-04 | a stub run (`MERGE_POLICY=pr`) whose session changed 2 files: `show` lists both with `+`/`−`; a stub `main` commit on one marks it `✗ conflicts` and `CONFLICTS with origin/main 1`; the compare URL with the GitHub-shaped origin and none with a plain-path origin (a second throwaway repo); `show <run> A` lists A's commits and entry files; `COLUMNS=60` lines ≤ 60 columns except `https://` lines; `--json` parses with `v` 1 and its key paths equal `show-json-keys.txt`; `--files` lists past 12 (a run with 13 files) |
| `69-same-project-starts.sh` | U3-05 | `harness start proj --brief x` while a stub run of `proj` is alive (a `sleep` pid in `driver.pid`) queues the entry and prints the message; `--now` starts it; `harness continue <ended run>` while another is alive queues `continue <run> --queued --requested` and leaves its `ended` in place |
| `70-overlap.sh` | U3-05, U3-06 | `named` on `tests/fixtures/overlap-spec.md` with `git ls-files` (this repo) finds `tests/run.sh`, `lib/treekey.mjs`, `lib/check.sh`, every entry tracked or a tracked `dir/` of two segments, no `tests/` or `lib/`; `overlap` unit cases (file/file, dir/file, none); then (U3-06) a queued entry whose brief names a file an ended stub run's unmerged branch changed shows `⚠ overlaps` in `queue list` and `status --json`'s `overlap`; `--now` start prints the warning, starts, and `harness needs` lists 2 (one per run); the records resolve on `sweep` once the other branch is gone, and by `harness needs done <ref>` |
| `71-tty-views.sh` | U3-07 | `summary.mjs report --md` of `tests/fixtures/summary-report.json` equals `tests/fixtures/summary-report.md`, and `harness report` off a TTY equals it too; `HARNESS_TTY=1` has no `\|` table row; `trends` with 17 ledger rows under `HARNESS_TTY=1` shows 15 rows and `2 older: harness trends --all`, and off a TTY is the old markdown; `gc --dry-run` with `HARNESS_TTY=1` has the six headers and the footer, and without it the old lines in the old order (the TTY form's lines, markers and headers removed, equal the plain form's in order) |
| `72-u3-review.sh` | U3-08 | one check per Critical/Important finding, red before its fix |

Fixtures: `tests/fixtures/overlap-spec.md` (a byte copy of `docs/specs/2026-10-26-suite-split.md`, its source named in
the check's comment); `tests/fixtures/summary-report.json` (a real `summary.json`: the ledger copy of a finished run of
this repo, `git show` from main, or `summary.mjs build` of a finished stub run, whichever the builder can name as its
source) and `tests/fixtures/summary-report.md` (today's `summary.mjs report` of it, made **before** U3-07 changes
`summary.mjs`); `tests/fixtures/show-json-keys.txt`. `status-json-keys.txt` changes in U3-06 (the queue entry's
`overlap` elements). The end-reasons check is untouched: U3 adds no end reason.

## 9. Order, and the suite after each

| feature | builds | after |
|---|---|---|
| U3-02 | `project_dir`, its six callers, 65-; decision `2026-10-27-project-names` | U3-01 |
| U3-03 | `finish`'s copy, `cmd_report`'s order, the unit rule, 66- and 67-, 08's two `?` expectations; decisions `2026-10-27-record-after-gc`, `2026-10-27-gc-foreign-units` | U3-02 |
| U3-04 | `cmd_show`, `lib/show.mjs`, `status.mjs cardHeader`, 68-, `show-json-keys.txt` | U3-03 |
| U3-05 | `project_busy`, `cmd_start`/`cmd_continue` queueing, `lib/overlap.mjs` + CLI, 69- and 70-'s pure half; decision `2026-10-27-same-project-starts`, the in-place line | U3-04 |
| U3-06 | the `overlaps` helper, the warning at start and queue add, the records on both runs, `queueEntry.overlap`, the template and sweep rule, 70-'s wiring half | U3-05 |
| U3-07 | `report`/`trends` views and `--md`, `gc --dry-run` sections, `tty_out`, the two report fixtures first, 71- | U3-06 |
| U3-08 | review from a diff file, fixes red → green in 72-, README, architecture §3 §12 §14, `bin/harness` usage header, the four decisions complete | U3-07 |

Serial: all edit `bin/harness`. The full suite took ~8 min at `TEST_JOBS=4` tonight with other lanes loaded and flaked
timing-bound e2e checks; `TEST_JOBS=2 HARNESS_CHECK_TIMEOUT=25m` is the way to a green full run (U1's and U2's
discoveries). While iterating, a subset: `bash tests/run.sh 65`.

## 10. Decision files (one per behaviour change; never numbered; `finding · choice · rejected`)

- `2026-10-27-project-names` (U3-02): the resolver's order; a name before `~/projects`; `--project` falling back to the
  bare name. Rejected: a project registry file (one more thing to keep in step); resolving by `basename` of the cwd.
- `2026-10-27-record-after-gc` (U3-03): `finish` copies into the state dir; `report` reads worktree → state → ledger
  (copied on first read) → a `no record` line naming both places. Rejected: gc refusing to remove an unreported run's
  worktree (the end-of-queue gc runs unattended; the copy costs two files).
- `2026-10-27-gc-foreign-units` (U3-03): another project's unit is silent; `?` only for no owner on the box, with the
  command. Rejected: stopping an unowned unit (nobody can say what it is).
- `2026-10-27-same-project-starts` (U3-05, completed in U3-06): a plain start or continue queues behind a live run of
  its project (the check in `cmd_continue` before its state changes); `--now`, `--foreground` and the runner's starts
  don't; overlaps warn and record on both runs and never hold; `named`'s two-segment directory rule and the
  `.harness/runs/` exclusion; overlap records resolve when either side's branch changes are on main or the other run
  is gone. Rejected: holding a start on an overlap (defaults 11: an ended run's unmerged branch must not block a
  night); comparing whole spec texts (no file names, no signal); `tests/`-level directories (every run would overlap).
- `journal/decisions/2026-10-21-queue-one-run-per-project.md` gets one line: `Updated in place 2026-10-27: a plain
  harness start or continue now queues behind a live run of its project too (decisions/2026-10-27-same-project-starts);
  --now still starts it.`

## 11. Defaults taken here (recorded in the decision files above; asked in U3-01's entry)

1. A bare name resolves through the runs before `$HARNESS_PROJECTS` (the runs know where the project actually is).
2. `trends --by version` keeps its markdown on a TTY.
3. Overlap directory names count only at two or more segments.
4. An overlap record resolves when **either** run's changes are on main (after that, a real conflict is
   `merge_conflict`'s card, not a prediction).
5. `show`'s changes sum a path's +/− across a run's lane branches (two lanes rarely change one file; the conflict mark
   is per branch).

## 12. Michael's after-run steps (none live)

- `cd ~ && harness gc agent-harness --dry-run` (the name resolves), and on a terminal the grouped form;
  `harness report agent-harness-2026-10-25-memory` (from the ledger copy; the state copy appears).
- `harness show <a run with unmerged work>` at 80 and `COLUMNS=60`.
- The next time two runs of one project are queued or started by hand: the `queued behind` message and, for a spec
  naming the same files, the `warning: overlaps` line and the two `overlap` items in `harness needs`.
