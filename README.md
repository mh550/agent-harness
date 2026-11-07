# agent-harness

A small, reusable harness for **long-running coding agents**, after Anthropic's
["Effective harnesses for long-running agents"](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents).
An initializer session turns a spec into a feature list (and runs the step lint over it: steps with nothing to check,
paths outside the repo, greps that match their own words, numbers another box or run won't reproduce (`unreproducible`), reviews out of size with their milestone, milestone ids that share a lane unit name (`unit-collision`); the driver notes what is left); then **one fresh Claude Code session per feature** does the
work, test-first. A deterministic bash driver does the bookkeeping around them: it verifies each finished milestone
independently, **opens a PR into `main` for each verified milestone, and merges it itself only in projects that
opt in with `MERGE_POLICY=auto`**, waits out usage limits, and records every run in a ledger that the next runs
learn from.

Zero dependencies beyond `bash`, `git` (≥ 2.38), `node`, `jq`, `tmux`, `flock`, `claude` and `gh`.
**How it works, in depth: [`docs/architecture.md`](docs/architecture.md).** Why it is the way it is: [`journal/`](journal/README.md).

## Quick start

```bash
ln -s ~/projects/agent-harness/bin/harness ~/.local/bin/harness     # once
harness init ~/projects/myapp            # CLAUDE.md template + .harness/config.sh (POLICY=build-only); prints what it detected
# fill in CLAUDE.md, commit to main, then:
harness start ~/projects/myapp --spec docs/todo.md --brief "items 1–3 only"   # or: harness start myapp (a name, from anywhere)
harness status                           # one screen: what needs you, what runs, what's queued, what finished (24h)
harness show <run>                       # where its work is: branches, changes vs main with conflicts, PRs, what needs you
harness report                           # the writeup: passing, tests, spend total / per feature / by role, causes, memory peaks over 2 GB
                                         # (tests: counted for node:test, pytest, jest/vitest, cargo and go test -v; a suite with no count is said once in harness-log.md)
```

A `<project>` argument (`start`, `init`, `queue add`, `gc`, `memlint`, `status --project`) is a path in a git
repository or a bare name: the `PROJECT_DIR` of that project's newest run, else `$HARNESS_PROJECTS/<name>`
(default `~/projects`); one that is none of these is refused with the places looked and the projects that have runs
(decisions/2026-10-27-project-names).

Queue work at once (runs go one after another by default; `MAX_PARALLEL_RUNS` in your config, which the
runner re-reads every poll, so an edit applies without a restart and lowering it stops no running run; the queue
never runs two runs of one project at once, so a second entry for a busy repo waits while later ones go ahead; a plain
`harness start` or `harness continue` of a project with a live run is queued behind it too, `--now` starts it anyway;
a start or `queue add` whose spec or brief names files another unmerged run of the project changes, or names too, says
`warning: overlaps <run> on <files>` and goes on: `queue list` marks the entry `⚠ overlaps`, and a start opens a
`harness needs` item on both runs until one of them is merged or gone):

```bash
harness queue add ~/projects/pathways --spec docs/specs/reader.md --brief "T5, T7, then T6"
harness queue add ~/projects/hit_list --spec docs/next.md
harness queue add --continue dj-2026-10-17   # a request: it starts even if you stopped the run (a stop after it wins; it replaces a queued one)
harness queue start                      # tmux h-queue; runs go one after another until the queue is empty (--until HH:MM: no run starts after it, and each one stops by then)
```

When the runner exits (queue empty, past `--until`, or `harness queue stop`) and it started at least one run, it
collects as it drains: `harness gc <project> --all-merged --deps` for each project it started a run in (its lines
in `queue/runner.log`, prefixed `gc <project>:`; no git prompt, killed after `HARNESS_GC_TIMEOUT` (10m); a failed gc is logged and never stops what follows). Then it runs
**`harness debrief`**, detached: one short read-only Sonnet session that reads what happened and overwrites
`ledger/debrief.md`. The notification (ntfy or `NOTIFY_CMD`) carries its three-line headline and the note's path (see [Debrief](#debrief)).

| Command | What |
|---|---|
| `harness start` · `continue` · `merge` · `stop` · `pause` · `resume` · `answer` | one run (`start` of a new run refuses at once, exit 1, a `--spec` or `SPEC_FILES` path absent from `origin/main` or its `--base`: `spec <path>: not in origin/main (fetched now); commit and push it, or name its ref with --base`; a resume and `--brief` alone are not checked; `merge` asks for no spec and works with the run's worktree gone: it makes one, restores the record from `origin/main` or the ledger and fetches a missing tag, or says `no record` and leaves nothing behind) |
| `harness queue [list]` · `queue show <n> [--parked]` · `queue add` · `queue start [--until]` · `queue stop` · `rm` · `clear` | the queue (`list` marks each continuation `(requested)`, yours, or `(automatic)`, the driver's or the debrief's: an automatic one is skipped for a run you stopped; a brief shows its first 30 characters, `show` prints the entry whole; `queue add` refuses a spec absent from `origin/main` or `--base` as `start` does, and the runner checks a start entry's spec again at dequeue: one gone by then is parked, never started, its reason the same line, a `parked <entry>: …` line in `queue/runner.log`, and the runner goes on to the next entry) |
| `harness queue park <n> [<why>]` · `queue unpark <n>` | set an entry aside: `queue list` shows it with its reason, the runner skips it; unpark puts it back at the end; new entries are numbered past parked ones, and a park never overwrites one of the same name |
| `harness sync` | the live harness checkout level with origin (merged PRs in, ledger commits pushed); the queue runner does this itself whenever no run is alive (`LIVE_SYNC=0` turns it off) |
| `harness backlog [list]` · `backlog set <id> <status> [--spec] [--pr] [--note]` · `backlog import <file.jsonl>` | the retro backlog, `ledger/retro-backlog.jsonl`: one row per retro proposal across runs, `proposed` first, most seen first; `set` moves one (`proposed` · `specced` · `queued` · `merged` · `dropped`), `import` merges rows by id; writes hold the ledger lock and are a ledger commit (`LEDGER_COMMIT`) (see [Retro backlog](#retro-backlog)) |
| `harness status [--all] [--since <d>] [--project <p>] [-v] [--json]` · `status <run> [-v] [--json]` | look: one screen, NEEDS YOU, RUNNING, QUEUED and FINISHED (runs ended in the last `STATUS_SINCE`, default `24h`, never fewer than the 3 newest, never more than 10), then how many are hidden; `--all` lists every run, `--since 3d` widens the window, `--project` keeps one project's; `-v` (or `N=<lines>`) adds a running run's units with `MemoryCurrent`, one line per open lane (`lane <m> · <feature> · session <n> · port <p> · slot <k> · MemoryCurrent <unit> <MB> MB, …`) and the last `N` `run.log` lines; `<run>` prints that run's card (state, now or ended, milestones, lanes, spend, branch, worktree, needs you, next); `--json` the v1 document (`tests/fixtures/status-json-keys.txt`). It fits the terminal (`COLUMNS`, else 100 off a TTY), colours only on a TTY (`NO_COLOR=1` turns it off) and falls back to ASCII glyphs outside a UTF-8 locale |
| `harness show <run> [<feature>] [--files] [--json]` | look: where a run's work is, from local refs (no fetch): worktree (clean or changed), branch with ahead/behind `origin/main`, record, state, lanes and slots, merged or proposed milestones with tag and PR, the GitHub compare URL of each run branch with changes, `CHANGES vs origin/main` (status, path, +/−, `✗ conflicts` where `git merge-tree` says main conflicts; the 12 largest, `--files` all), `CONFLICTS`, `NEEDS YOU`; with a feature id: its steps, sessions, files and commits, and its needs card; `--json` v1 (`tests/fixtures/show-json-keys.txt`) |
| `harness report [--md]` · `trends [--all] [--md] [--by version]` · `attach` | look (on a terminal `report` is a card and a not-passing table, `trends` the newest 15 runs as columns with `<k> older: harness trends --all` and the total; off one, or with `--md`, both are the markdown; `report` reads a run's worktree, else the copy `finish` keeps in its state dir, else the ledger's, so a run gc removed still reports; `report`'s `Lanes` row: the most lanes open at once and lane hours against wall hours; its `Flakes` row: the suite runs that went green only on check.sh's rerun, by check file (`3 · <name> ×2, <name>`, `0` for none); its `Suite runs` row: full and fast suite runs per coding session (`0.2 full and 1.6 fast per coding session (2 full, 16 fast in 10; 20 runs in all)`, `0` for none; the coding prompt asks for one fast-tier run, last); its `Helper` row: the resident helpers that restarted or went off, with each reason (`0 restarts`, or `2 restarts · 1 off (the helper went away ×2, no reply in 120 s)`); `trends --by version`: runs grouped by harness version, medians of cost, cache hit, orientation) |
| `harness needs [<run>] [--all] [--json]` · `needs done <run>/<n> [--why "<text>"]` | every open item that waits on Michael (a park, a give-up, a failed verify or merge, a run that stopped on its own) as a card: what waits on it, the question or why (the mechanism and its file), where (files with lines, GitHub links), options with one recommended, the commands; block before warn, oldest first; `COLUMNS=60` for the phone; `--all` adds those resolved in the last 7 days; `done` resolves one by hand (read-only but for `done`); each item is a JSON file, `<STATE_ROOT>/<project>/<run>/needs/*.json` (resolved ones in `needs/done/`), what n8n reads |
| `harness parked [<run>] [--json]` | `harness needs` for text; `--json`: each parked feature (run, project, feature, since, why, question, running, ending, queued, commands) with its needs item's `ref` and `card` (read-only) |
| `harness debrief [--dry-run]` | the triage note for every run since the last one (`--dry-run`: print the gathered context only) |
| `harness eval run` · `compare` · `probes` | replay a fixed task set under a harness version and compare two results (see [Evals](#evals); costs money) |
| `harness init` · `gc [--all-merged] [--deps] [--dry-run]` | set up a project (adds the Vercel/Netlify deploy guard so run branches never deploy), clean up merged runs (their clean worktrees, run worktrees only (`harness/<run>`: a worktree on any other branch is a `keeps` line, and so is a run with a verified milestone whose tag is not on `origin/main`: `keeps <wt>: <m> verified, not merged (harness merge <run>)`, its branch and its card kept too, until the tag is on main or `harness merge` lands it), clean counting untracked files whatever the config, ignored build output and all: `worktree remove --force`, then `rm -rf` only once git has let go of it (a locked one stays), a failure a `! could not remove <wt>: <why>` line and gc goes on; and the merged `harness/` and `harness-merge/` branches, local and on origin; `--all-merged`: every branch merged into `origin/main`, whatever its name, except `main`, the origin's default branch and a running run's; local deletes are `branch -d`, a refused one is a `! failed:` line and gc goes on; `--deps`: the `DEPS_DIRS`, default `node_modules .next .next-check .venv`, in the worktrees of ended runs, merged or not, never the project's checkout or a live or queued run's, each a `+ freed <n> MB in <wt>: <dirs>` line), stop the systemd units a killed driver left (`harness-<run>-*` of runs with no live driver; another project's are its gc's, one no run owns is listed `?` with the command to stop it) and kill the tmux sessions `h-<run>` of its ended runs (never `h-queue`, the desk, a live or paused run's); `--dry-run` on a terminal groups its lines under `UNITS`, `TMUX`, `DESKS`, `WORKTREES`, `DEPS` and `BRANCHES` and ends `would remove <n> worktrees, <n> branches; keeps <n>` (off one, the plain lines) |

`harness continue` merges `main` into the run branch (the record) before any session, so a resumed run never works on
a stale base, and reopens each unfinished milestone on its lane branch `harness-lane/<run>/<m>`: the origin's when it
is ahead (a fix you pushed there by hand), both merged when the box's and the origin's diverged. A run from before
lanes, whose `harness/<run>` carries code `main` doesn't have, is refused (exit 1, plus a high-priority notification)
with three ways forward: `harness merge <run>` for its verified milestones; a new run with `--brief "finish <what is
left>; harness/<run> is the source"`; or finishing it by hand on that branch. A branch that holds only the record
continues as a lanes run. Under `MERGE_POLICY=pr`, a verified milestone whose dependency's PR still waits for you opens
its own PR from the dependency's tag and waits (`<m> verified; its PR waits for <dep> to merge`); `harness merge <run>`
then lands every proposed milestone, dependencies first, re-basing in a slot each whose `main` moved since its verify
(the same rule as in a run).

## What a project needs

| File | What | Required |
|---|---|---|
| `CLAUDE.md` | durable rules: code rules, how to verify, off-limits; a `## Where things go` block (what goes in which store: your entry, a decision file, a plan, `CLAUDE.md`) and `## Gotchas` (15 lines, edited in place, facts a fresh session would rediscover; no session writes it: a coding session puts a fact in its entry's `discoveries` with `affects: ["project"]`, and the harness reverts its edit to `CLAUDE.md`); the harness appends its own routing block to the prompts only when `CLAUDE.md` lacks the `## Where things go` heading; `## Live system` for live projects. Claude Code loads it in every session; the harness prompt names it, it doesn't paste it | yes (template: `harness init`, or `harness init --draft` to have Claude draft it) |
| `.harness/config.sh` | `POLICY=build-only` or `POLICY=live-staged`, plus real overrides only; `DECISIONS=<path>` names the decisions store (a directory of one file each, or one file) when it isn't `docs/decisions.md` | recommended |
| `.mcp.json` | the MCP servers runs may use. Sessions run with `--strict-mcp-config`, so a committed `.mcp.json` (passed as `--mcp-config <worktree>/.mcp.json`) is what run worktrees load; without one they get none, whatever your user config holds | no |
| `.harness/check.sh` · `init.sh` · `smoke.mjs` | only if the conventions don't fit: a sandboxed suite, a dev server, a browser smoke test | no |
| `.gitattributes` | `<path> merge=sorted-union` for a sorted one-item-per-line list two lanes both add to (this repo: `tests/fixtures/check-names.txt`): the harness's merge driver (`lib/merge-sorted.sh`, set in its own worktrees only) takes both sides' lines, minus those either side removed, so the merge never conflicts there; your checkout merges it as text | no |
| `.harness/teardown.sh` (executable) | what stopping the run's services scope can't reach, e.g. `npx supabase stop` or `docker compose down` (containers live under `dockerd`): see below | no |

**Test counts.** A suite may print a line `HARNESS_TESTS=<n>` (a whole line from column 0, no colour or prefix; the
last one wins): the harness takes it over scraping
the runner's summary (node:test, cargo, jest, `go test -v`, then the last `N passed`), and `harness-log.md` says once
per run which it used: `test count: HARNESS_TESTS contract`, `parsed (<runner>)` or `no match`. The run's first count
is its baseline (`tests-start`); the latest tree's (`tests-end`) is refreshed after every session, so `harness status`,
`harness report` and each session's line in `harness-log.md` show it mid-run, and report.md's Tests cell reads
`<start> → <end> (baseline at run start → end)`.

**Check counts.** A suite that keeps its check names in a file, one per line, C-sorted (`CHECK_NAMES`, default
`tests/fixtures/check-names.txt`, as this repo's `tests/run.sh` enforces), gets each verified milestone's diff of it
counted at the verify: `harness-log.md` says `<m>: checks +<added> ~<replaced> −<removed>` (a removed and an added name
in one run of changed lines of the sorted file count as one replaced, the way `git diff` shows a name changed in place), the
run's `summary.json` has `checks` summed over its milestones, `harness report` a `Checks` row after `Suite runs`
(`+2 ~0 −1 (M1 +2 ~0 −1; M2 +0 ~0 −0, budget 3)`) and the retro prompt its `{{CHECKS}}`. A spec may give a milestone a
**check budget**, the number of names it may add: the initializer copies it into the feature list's top-level
`check_budget` map (`{"M1": 3}`), the note reads `<m>: checks +4 ~1 −0 against a budget of 3 (over budget: <why>)`
when it is exceeded, the reason from the `checks` field of the milestone's last coding entry (`none given` without
one), and nothing stops: a count is measured and recorded, never a gate. A project without the file (or with
`CHECK_NAMES=""`), and a run that verified no milestone, get `+<n>` from the test counts instead (`+2 (the suite's
count, 3 → 5)`; decisions/2026-11-03-check-budget).

**Failed files.** A red suite may print a line `HARNESS_FAILED=<name> <name>…` (a whole line from column 0, the last one
wins): the names, taken as arguments by the suite, of the files that failed. Its promise: every failure of the run is
inside a named file. A suite omits the line when one isn't (this repo's `tests/run.sh` leaves it out on a red
conformance check or a FAIL in a file that exited 0), and `CHECK_RERUN=auto` then reruns the whole suite.

**Memory lint.** `harness memlint <project>` prints what `lib/memlint.mjs` finds in a project's memory files, one
`<file>:<line> <check>: <text>` per line: `size` (`CLAUDE.md` over `MEMLINT_LINES`, 120), `gotchas` (over 15 lines),
`derivable-count` (a stored `<n> tests`), `run-scope` (a line tied to one run: `this run`, `as of <date>`) and `decisions` (no
store, no current-rule-set header, a superseded entry without an `Updated in place` line). Every run segment starts
with the same lint as `memlint: …` notes in `harness-log.md`; they never stop the run. A coding session's edit to
`CLAUDE.md` or `.harness/project.md` is reverted and noted (`<feature>: reverted its CLAUDE.md edit (project memory is
the curator's; say it in the entry)`): a fact goes in the entry's `discoveries` with `affects: ["project"]`, a
workflow line in `proposed_changes` (decisions/2026-11-07-memory-one-writer). Run `harness memlint
<project>` for each project to confirm chunk 3 Part 2's tidy held: on 2026-10-26 the projects with a `CLAUDE.md`
give two `size` findings (hit_list's, 181 lines; portfolio_site's, 127) and nothing else, agent-harness once the memory
run's tidy of its own `CLAUDE.md` and `DECISIONS=` is on main; a directory without a decisions store gives `decisions:
no store`.

**Memory curator.** At a run's end, after the retro, one read-only session (`CURATOR_MODEL`, opus; `prompts/curator.md`)
reads the run's entries and writes `memory-ops.json`: itemized operations (`add`, `replace`, `delete`) on a section of
`CLAUDE.md` or `.harness/project.md`, each naming the entry it comes from. It edits nothing else (its edits are
reverted). The driver applies them (`lib/curator.mjs`) in a scratch worktree at `origin/main`, never in the run's
checkout: the tier comes from the heading, never from the session (`## Gotchas` is tier 1 and committed; any other
heading is tier 2, a line for you to paste; `Live system`, `Off-limits`, `On-limits`, `Hardware facts`, `Hardware and
Mixxx rules` and `This repo runs Michael's harness runs` are tier 3, a proposal only); an op whose text no entry states
as a `project` fact is dropped; a result over 120 lines or 15 Gotchas is refused unless the add evicts a line. Tier 1 is
one commit on `harness-memory/<run>`, and its `memory: <run>` PR is left for you; its body (also `memory.md` in the run
record) lists what was applied, what to paste, the proposals and every dropped op with its reason. A `harness continue`
adds to the open PR. `harness-log.md` says `memory: <n> ops · <a> applied · <d> dropped · <p> proposals` and the PR's
fate. `MEMORY_POLICY=off` runs no curator (decisions/2026-11-07-memory-tiers).

Everything else is detected or defaulted: the suite (`npm run check`/`npm test`/pytest/…, run by `lib/check.sh` in
its own scope capped at 3G under a 15m timeout: `CHECK_MEMORY_MAX`, `CHECK_TIMEOUT`; a red full run rerun once, never after a timeout or a cap kill, by `CHECK_RERUN`: `auto` (the `HARNESS_FAILED=` files, else the whole suite) · `failed` (the named files only) · `suite` (the whole suite) · `off`, a rerun that goes green counted as a flake in `harness-log.md`, `summary.json` and report.md's `Flakes` row; cached per code tree, whose key
leaves out `CHECK_KEY_IGNORE`, default `.harness/runs docs/plans`, so a plan alone doesn't rerun it; a red full run
that was no timeout or cap kill is cached too, as `red-<key>`, so a retry's pre-session run on the tree just found red
answers `check: RED (cached for this code tree: <names>)` without running it a third time; a `CHECK_KEY_MAP` in `.harness/config.sh` (`CLAUDE.md:<check>[:<check>…]`, space-separated entries: a file and every check file that reads it) makes a change to such files alone run just their checks, `check: green (partial: <names>, <s> s; cached for the rest)`, against the last green full run of the rest of the tree; an entry must name every reader, and only check-file lines may read it (not the code under test, not a shared test helper), so a project with a map needs a lint proving that over its checks, as this repo's `tests/checks/key-map-lint.sh` does (a check file outside the entry that names the path beside the repo root, or passes the bare root to a command, fails it); each verify clears its
tree's cached green and red (and its partial sidecar) so the suite runs in full on what it judges; every prompt says how long the last full run
took, `Suite: last full run <s> s: give a full run a timeout of at least twice that` (the green marker's `wall` line); two tiers by `CHECK_FAST_CMD` (empty: the whole suite is the fast tier, and nothing changes; this repo sets `bash tests/run.sh --tier fast`): a feature's `passes` stands on the fast tier (`check.sh --fast` before and after each coding session, its green marked `fast-<key>`, never read as a green; a red after the session un-passes it, `<id> un-passed: fast tier red after the session`), while the verify, a re-base and the run's end run the full suite, so a slow-tier red meets the verify's `red on the verified tree` path, never a merge; the prompts then name both commands and both lengths (`Suite: last fast run <s> s`; decisions/2026-11-03-fast-gate); the same list decides a merge: a verified
milestone whose `main` moved only in those paths merges as verified, without a re-base round, noted `<m>: main changed
only in ignored paths (…); its verify stands`; every call that ran or answered appends one row to
`$HARNESS_SCRATCH/check-runs.log`, `<epoch> <full|fast|subset|partial|cached> <seconds>`, which each coding session's
`<id>: suite ran <n>x (<s> s) in the session` note in `harness-log.md` counts, cached answers aside), smoke, init (run in the run's
services scope `harness-<run>-svc`, capped at 3G, under a 10m timeout; what it leaves running when it returns stays in the
scope until the run's services stop (below) or the next init stops it: `SVC_MEMORY_MAX`, `INIT_TIMEOUT`), port, models, limits
(a session waits up to 30m while the box has under 5 GB available, then starts anyway: `MEM_MIN_AVAILABLE_GB`,
`MEM_WAIT_MAX`). Run scope is never committed: it's `--spec` and `--brief` on `start`/`continue`.

**The resident helper.** A driver and each lane answer most `.mjs` questions from one warm node process instead of a node start per question, byte for byte the same; `HARNESS_HELPER=0` (in the environment or `~/.config/harness/config.sh`) turns it off. A helper that fails is restarted (three times per process, then off for it) and every answer still comes, by a node start; the run's record says so: `summary.json`'s `helper` (`restarts`, `off`, each reason with its count), `harness report`'s `Helper` row, and one line in `harness-log.md` at the end of a segment that had any (`helper: 1 restarted, 0 off in this segment (first: the helper went away); see run.log`). No card and no notification: the run is only slower.

**Scratch and cache.** Each run gets `HARNESS_SCRATCH` (`/tmp/harness/<project>/<run>`) for its outputs, sandboxes,
logs and screenshots; a run that finishes deletes it (`KEEP_SCRATCH=1` keeps it), after copying `init.out`,
`teardown.out` and the last suite output (`check-last.out`) into its state dir. Installs that should outlive a run
and a reboot go under `HARNESS_CACHE` (`~/.cache/harness/<project>`, never deleted): put Playwright browsers there
(`PLAYWRIGHT_BROWSERS_PATH=$HARNESS_CACHE/ms-playwright` in the init) and anything similar, not in scratch.

**Teardown.** When a run ends (a `status: stop` included), when its driver is killed (a TERM, or an error that ends
it), when it pauses, before a usage-limit wait of more than `SVC_IDLE_STOP_MIN` minutes (10) and before a memory wait,
the harness stops the run's services (the next session's init starts them again): it runs the project's `.harness/teardown.sh` if that file is executable then (or `TEARDOWN_CMD`), in the
worktree under `timeout 2m` (KILL 10 s later) with `HARNESS_PORT`, `HARNESS_SCRATCH`, `HARNESS_RUN_ID` and `HARNESS_TEARDOWN_WHY` set,
then stops `harness-<run>-svc`, and notes `services stopped (<why>)` in `harness-log.md`. The scope stop alone takes
everything the init started itself; a project whose init starts containers (Supabase, `docker compose`) adds its own
hook to stop them (template: `templates/project/teardown.sh`). It runs only when the segment ran an init, its output
goes to `teardown.out` in the scratch directory, and a failing hook is noted, never fatal. A TERM during an init stops
the init first; a TERM during a teardown waits for it rather than starting a second. A SIGKILLed driver runs no
hook: `harness gc <project>` stops the units it left (run the teardown by hand for its containers:
`HARNESS_RUN_ID=<run> .harness/teardown.sh` in the worktree).

## What a run is

| | Where |
|---|---|
| Worktree, branch | `~/worktrees/<project>/<run-id>` on `harness/<run-id>` (from `origin/main`): the run record only, written by the driver alone. Code goes on a lane branch per milestone, `harness-lane/<run-id>/<m>` |
| Lanes | each milestone runs as a lane: its own process (`lib/lane.sh`), its features in order, then its verify and merge, in a slot worktree `~/worktrees/<project>/lanes/<run-id>/slot-<k>` with its own port and scratch. `MAX_LANES` (default 1: one milestone after another) caps the lanes open at once; a second lane opens only with headroom: `MemAvailable` at least `MEM_MIN_AVAILABLE_GB` + `LANE_RESERVE_GB` (4) per open lane, and the newest session's five-hour window (`USAGE_5H`) under `LANE_OPEN_BELOW_5H` (70 %) until it resets, else `lane <m> waiting: <reason>` once per reason and a retry every poll (decisions/2026-10-26-parallel-runs-headroom). Slot 0's lane uses the run's port, a lane in slot 1 and up the first free one from `BASE_PORT`; a slot is reused by the next lane (`checkout -B`), so its ignored install and build directories carry over, and `finish` removes every slot. A merged milestone's lane branch is deleted when its PR merges (under `pr`, once `harness gc` sees it merged); an unverified one stays. `harness gc <project>` removes the slots a killed driver left once no lane process of the run lives, and stops their lane units. When another lane's merge moved `main` under a verified milestone, its lane re-bases
it: `main` merged into the verified commit; files disjoint from the milestone's (`LANE_REBASE=suite`, the default)
run the suite in full on the merged tree and, green, move the tag there (`<m> re-based on main <sha>: <n> files,
disjoint, suite green; re-tagged`); overlapping files, or `LANE_REBASE=verify`, get one verify round
(`MAX_REBASE_ROUNDS`, 1) first; a red suite or the rounds used need you
(decisions/2026-10-26-lane-rebase-disjoint). A conflict with `main` (the re-base's merge, or the verify's) goes to a
resolve session under `CONFLICTS=resolve` (the default): it edits only the conflicted files, the driver checks no marker
is left and commits the merge, and the milestone merges only after a verify round on that tree (`<m>: main merged in
by a resolve session (<files>; <model>, <n> min); one verify round follows`; report.md's `Conflicts` row counts them);
a session that gives up, a check it fails or `MAX_RESOLVES` used need you, its card saying what it tried
(decisions/2026-10-29-conflict-resolution). `harness-log.md` says `lane <m> opened (slot <k>, port <n>, from <sha>)` and `lane <m> closed (<reason>)`, the reason by the lane's exit code: 0 `<m> merged` · `proposed` · `verified; its PR waits` · `verified; its re-base waits` (done) · 10 `given up <ids>` · 11 `parked <ids>` · 12 `<m> needs Michael: <why>` (verify, merge, a conflict, its slot, or `lane exited unexpectedly`) · 13 `session cap`, `usage limit`, `weekly budget` (ends the run) · 14 `stopped` · 15 `deadline` · 16 `the run is ending (<why>)` (another lane ended it) |
| Run record (committed) | `.harness/runs/<run-id>/`: `feature_list.json` · `entries.jsonl` (the journal: one entry per session; sessions write `entry.json`, only the driver appends, and a session's edit to it is undone) · `progress.md` (rendered from it for the phone; 15 in full) · `progress-archive.md` (every entry) · `INBOX.md` · `brief.md` · `harness-log.md` · `metrics.jsonl` · `summary.json` · `report.md` · `retro.md` · `retro-proposals.json` · `memory-ops.json` and `memory.md` (the curator's operations and its PR's body) |
| Fix rounds | a verify whose full suite is red (after the rerun guard, so never a flake) opens a fix round instead of asking you: the driver appends a fix feature `<m>-fix<r>` to the milestone (the failing checks' names and files, the red's output saved as `fix/<m>-<r>.out` in the run record), the lane's next session fixes the cause (it passes on `check.sh <the red's files>`, then the fast tier), and the verify runs again: `<m> verified and tagged … (after fix round <r>)`. At most `MAX_FIX_ROUNDS` (2) per milestone, kept across `harness continue`; then, or with `MAX_FIX_ROUNDS=0` at the first red, the `verify_red` card as before, naming each round and what it left red. `harness-log.md` says `verify <m>: the suite is red on the verified tree (…); fix round <r> of 2: <m>-fix<r> appended (<k> failing: <names>)`; report.md's `Fix rounds` row counts them (`2 opened · 1 fixed (M1 1 of 1, M2 0 of 1)`), and `Spend by role` lists `fix` (decisions/2026-11-04-fix-rounds) |
| Reviews | sized to the milestone: one or two build features fold the review into the last one's steps (a reviewer subagent reads the diff; the coding prompt puts reviewers on the session's own model, `{{MODEL}}`); three or more keep one review feature, which the driver runs on Sonnet under `REVIEW_OPUS_LINES` (400) changed lines of what the lane's branch has and main doesn't (main fetched first) and on Opus at or over; a Sonnet review whose entry summary reports `<n> Critical, <n> Important` above 0 gets one more round on Opus, at no attempt, and any later attempt stays on Opus (decisions/2026-10-27-review-gate). The lint flags `review-small` and `review-missing` |
| Merges | per verified milestone: tag `run/<run-id>/<m>`, PR from `harness-merge/<run-id>-<m>` (never carrying `.harness/runs/`: a lane change there goes back to main's first, noted), left for you to merge (`MERGE_POLICY=pr`, the default; `auto` lets the driver self-merge — Michael's user config sets it, and a project whose `main` deploys sets `pr` back; `off`). An origin that fails or hangs is retried with bounded backoff (`ORIGIN_WAITS`, `ORIGIN_TRY_TIMEOUT`; a GitHub refusal never is); past the tries you get a note, a `merge_failed` card and a high-priority notification, and `harness merge <run>` picks it up once origin is back. `harness-log.md` says `verified and tagged` only for a tag origin took, else `tag … is local only`. When the run ends, its record (`.harness/runs/<run-id>/`) reaches main through one PR of its own, `<run-id>: run record` from `harness/<run-id>`: merged under `auto`, left for you under `pr`, none with `RECORD_PR=off`; `finish` deletes nothing, and the queue's end-of-queue `harness gc` deletes the record branch and its worktree once its record PR is no longer open (the ledger keeps the record) |
| Local state | `~/.local/state/harness/<project>/<run-id>/`: `run.log`, transcripts, attempts, `driver.pid`, `ended` |
| Ledger | `ledger/runs.jsonl` and `ledger/<project>/<run-id>/` in this repo · `harness trends` |
| Memory | each session in the transient user scope `harness-<run-id>-s<n>` (throttled at 5G, killed at 6G, 1G swap: `SESSION_MEMORY_HIGH`, `SESSION_MEMORY_MAX`, `SESSION_SWAP_MAX`), each suite in `harness-<run-id>-check-<pid>`; stopped when they return, so nothing a session started outlives it. Peaks go in `metrics.jsonl` (`mem_peak_mb`) and `report.md` (over 2 GB). No user systemd: uncapped, with a note |

A run has no end time unless you give it one, and it goes regardless of the time of day. It ends when its features
are done, blocked or waiting on you, at its session cap (a continuation is queued, `AUTO_CONTINUE`), at the weekly
budget, after `MAX_LIMIT_HITS` refused sessions in a row, or when you stop it. `run.log`'s first line says `· no end
time` or `· ends <HH:MM>`. The bounds: `docs/architecture.md` §7.

### After the run (box settings, yours)

- With the scopes in, `systemd-oomd` can kill the offending `harness-*` scope instead of the desktop: enabling it with
  `ManagedOOMMemoryPressure=kill` on the user slice is a box setting, your call (`findings-and-research/2026-10-24-system-resource-audit.md` §3C.2).
- `systemctl --user list-units 'harness-*'` shows what each run holds right now (nothing when no run is alive).
- **Two lanes:** set `MAX_LANES=2` in `~/.config/harness/config.sh` before the next run starts (the code's default
  stays 1; the driver reads the config at run start). After the run: `grep -c "lane .* waiting"
  <run dir>/harness-log.md` (how often admission held a lane back), `jq .lanes <run dir>/summary.json` (`max_open`,
  `lane_hours`, `wall_hours`), `mem_peak_mb` in `metrics.jsonl`, no OOM lines in `journalctl --user -b`, and
  `systemctl --user list-units 'harness-*'` empty. Under `MERGE_POLICY=pr` the record PR (`<run>: run record`) is
  yours to merge too. `MAX_PARALLEL_RUNS=2` only after a run at two lanes shows the headroom
  (decisions/2026-10-26-parallel-runs-headroom).
- **Conflicts:** `CONFLICTS=resolve` (the default) sends a lane's conflict with main to one resolve session:
  `RESOLVE_MODEL` (opus), `RESOLVE_MAX_TURNS` (60), `RESOLVE_BUDGET_USD` (5), `RESOLVE_TIMEOUT` (30m; none starts
  with less left before a deadline, when the run has one), at most `MAX_RESOLVES` (3) per milestone and one per main commit; a refused one
  waits for the window like any session. `CONFLICTS=michael` in a project's `.harness/config.sh` (or yours) keeps
  every conflict yours, as before. The record branch's conflicts, a lane base's, `harness merge` and one the run's end
  meets are always yours. After the run: `jq .conflicts <run dir>/summary.json` (`resolved`, `escalated`,
  `sessions`) and `grep 'resolve session' <run dir>/harness-log.md`.
- A crashed or stopped run leaves its scratch in `/tmp/harness`. The optional age rule removes it after 3 days
  untouched (never `live.lock`); the user tmpfiles timer it needs is off by default, so the one command enables it:
  `mkdir -p ~/.config/user-tmpfiles.d && cp templates/user/harness-tmpfiles.conf ~/.config/user-tmpfiles.d/harness.conf && systemd-tmpfiles --user --create && systemctl --user enable --now systemd-tmpfiles-clean.timer`

## Steering

- **An end time, if you want one:** `harness start --until HH:MM`, `harness continue --until HH:MM` or `harness queue
  start --until HH:MM` (every run it starts stops by then; none starts after it), or `HOURS=<n>` in a config for every
  run. At that time the lanes stop between sessions and each complete, unverified milestone gets one verify. Without
  one, nothing ends a run on the clock.
- **Phone:** `progress.md` is rendered from the journal (`entries.jsonl`) after every session and is still the phone view; sessions write `entry.json`, the driver appends it. Steer by editing `.harness/runs/<run>/INBOX.md` on the run branch in the GitHub app: first line `status: pause` or
  `status: stop`, optionally with why (`status: stop the spec changed`); answers under `## Answers`. The driver pulls before every session.
- **Why a stop:** either reason ends up in harness-log.md, `ended`, summary.json's `end_reason` and the retro prompt as
  `stopped by Michael: <why>` (the `--why` one wins when both are set); without one, `stopped by Michael` as before.
  `harness continue` (or a queued request) of a run stopped from the phone sets its `status: stop` line back to
  `status: run`, so the continuation doesn't stop again at once.
- **Entries:** each session ends by running the entry check (`{{ENTRY_CHECK}}`, `node lib/entries.mjs validate`) on
  its `entry.json` and fixing what it prints, and never ends its turn on a running background task. A summary over
  400 characters (or a header over 2000), the entry's only fault, is cut to fit and the entry kept (`<id>: entry.json
  summary <n> characters; cut to 400 and kept`). A missing or otherwise invalid entry of a session no usage limit
  refused gets **one resume** of that session (`claude --resume`, 8 turns, 10 min, `$1` over its cost) to write it,
  and nothing else; its cost is an `entry-resume` row in `metrics.jsonl`, never a session. Still none: the minimal
  entry from git, as before (decisions/2026-10-29-entries-survive).
- **Box:** `harness pause|resume|stop|answer <run>` (`harness stop <run> --why "<text>"` records why), `harness attach <run>` (tmux: driver · log · supervisor). When the driver exits, the
  supervisor window closes, the driver window's scrollback goes to `<state>/tmux-driver.txt` (its last 2000 lines, tmux's `history-limit`;
  `run.log` beside it has everything), and the session `h-<run>`
  closes after `TMUX_KEEP_HOURS` (24; `0` = at once), or sooner: `harness gc <project>` and the queue runner, as it
  exits, kill the sessions of ended runs.
- **What a session reads:** `context.md` first (a bounded pack the driver writes before each coding and verify session: your answers, the feature's earlier dead ends and open questions (a later entry's `resolved` drops one), facts to promote into `## Gotchas` (until a line there or a later `resolved` carries them), recent entries, and last the decisions store's current rules, newest first; a verify's pack is larger, `CONTEXT_PACK_BYTES_VERIFY`, its failed rows first); the `--brief` (and `--spec` paths) go into every session's prompt; `CLAUDE.md` is loaded by
  Claude Code itself (the prompt names it in one line, it doesn't paste it), so a rule edited on the run branch reaches
  the next session. Each session's prompt is kept beside its transcript (`logs/*.prompt.md`).
- **Notifications:** start, merges, needs-Michael, parks, limits, end. In `~/.config/harness/config.sh` either
  - `NTFY_URL` (an ntfy topic URL, e.g. a private ntfy.sh topic) and optionally `NTFY_TOKEN` (sent as
    `Authorization: Bearer`, never logged): the harness posts itself, with a title, priority high where you must
    act, a click URL (INBOX.md, progress.md, report.md on the run branch on GitHub, or the PR) and view actions.
    **`NTFY_URL` wins: `NOTIFY_CMD` is then not called.**
  - or `NOTIFY_CMD`: it gets the one-line message as `$1` as always, plus `HARNESS_NOTIFY_TITLE`,
    `HARNESS_NOTIFY_BODY`, `HARNESS_NOTIFY_CLICK`, `HARNESS_NOTIFY_ACTIONS` (ntfy's `view, <label>, <url>; …`) and
    `HARNESS_NOTIFY_PRIORITY` (`high` or empty) in its environment.

  A park's notification carries the question the session wrote in INBOX.md (body capped at 3500 bytes), the
  `harness answer` command, and Edit INBOX / Progress actions; `DESK_URL` (e.g. a Claude Code environment URL; no `,` or
  `;` in it, they split ntfy's Actions header) adds **Answer with Claude**. A non-GitHub origin sends the same without URLs.
- **Permissions:** the policy (agents merge, push and clean up; only the irreversible is denied; production is gated
  per project) lives in `~/.claude/CLAUDE.md` § "Git, merges and permissions" and the user settings. Install or
  refresh both from `templates/user/` with `bash setup/apply-2026-10-24.sh --dry-run`, then without `--dry-run`.
- **Answering from the phone:** install the skill once, `ln -s ~/projects/agent-harness/skills/harness-answer ~/.claude/skills/`.
  Ask a Claude session "answer the harness": it runs `harness needs`, checks what it safely can (variable names, never
  values), proposes, and runs `harness answer` only after your yes. When another run of the same project is alive it
  asks before continuing: queue behind it (it merges first) or `--now` beside it. Set `DESK_URL` (above) to get **Answer with Claude**
  on a park's notification; `templates/user/config.sh` documents every user setting.
- **The desk:** with `DESK=1` in `~/.config/harness/config.sh` (off by default) the harness starts the session for you
  whenever a run needs you (a park, a blocked or waiting end, verify or a merge needing you, a debrief with something
  under Needs Michael): a Remote Control `claude` in tmux session `h-desk`, one window per run, on `DESK_MODEL` (opus).
  On the phone you get a second notification, `[<run>] needs you: <why>`; tapping it opens that session in the Claude
  app, already briefed: it has read `harness needs`, the INBOX and the progress log and sends one numbered brief. Answer
  there; it runs `harness answer` and the continue only after your yes. A later event for the same run is typed into the
  same session. By hand: `harness desk <run> [--why "…"]`, `harness desk --debrief`; `harness desk --list` (window, run,
  URL, age), `harness desk --close <run>|--all`; `harness gc <project>` closes desks idle for 24 h (and keeps the
  worktree of a run whose desk is open). A desk showing a dialog gets nothing typed in: answer it first. A desk that can't
  start (no tmux, no URL within a minute) is a line in `harness-log.md` and the plain notification; it never changes
  the run. Turning it on in stages: `docs/plans/2026-10-19-P3-desk.md`, "For Michael: turning it on".
- **After a partial run:** nothing, usually: verified milestones are already merged and a continuation is queued.
  A run that hits an end time it was given gives each complete, unverified milestone one verify session, so finished work
  merges in that run (not when you stopped it or a usage-limit window holds: the continuation verifies it); one that
  fails it needs Michael.
  "Blocked" or "needs Michael" runs: answer, then `harness continue <run> [--brief …]`.
- **Waiting on you:** a session that needs something only you can give (a secret, a sudo step) asks in INBOX.md and
  ends `PARKED: …`. A question written inside the steering comment (GitHub hides it) is moved below it, with a note. Every question
  (in INBOX.md or an entry's `questions`) names the files to open on a `Files:` line; one without it gets the files the
  session changed, filled in by the harness (`Files (harness, from the session): …`, noted). The feature waits without spending attempts while independent work goes on; the run ends
  `waiting on Michael: <ids>` when nothing else can run. Any new answer unparks it on `harness continue`. The park's
  notification carries the question, what waits on it, where and the commands; tapping it opens `needs.md` in the
  run record, every open item there as a card. A milestone that needs you (a thin or failed verify, one still red after its fix rounds, a conflict with
  main a resolve session couldn't settle or `CONFLICTS=michael` keeps yours, a refused merge, a lane base that won't merge) notifies the same way, its card as the body; main conflicting
  with a lane is said once per main commit, and resolves itself once main merges cleanly. A card's commands fix a
  branch in a worktree of their own (never the run's slot or record worktree) and push it. After a merge conflict,
  `harness merge <run>` takes the branch with main merged in as the milestone's tip. `harness needs done` refuses a
  park: it resolves when you answer and continue.
- **Questions:** a session never parks on a judgment call: it takes the default and asks in its entry's `questions`
  (with a `Files:` line). Each one waits in `harness needs` as a `question` card (`⚠ <run> · <id> asked: …`, its
  files and its `entries.jsonl` line) after every stop, counted apart (`NEEDS YOU 1 · 3 questions`, in `harness
  status` too), with no notification and nothing waiting on it; the debrief lists them under `#### Questions for
  Michael` (12 at most). The same question asked again is one card: `seen` grows in its run, and asked in a later run of the
  project it moves there (`asked 3 times (<runs>)`). It closes when you run `harness needs done <ref> --why
  "<answer>"` (`--why "default stands"` keeps the default), when a later session's entry lists it in `resolved`, or
  through the answer skill ("answer the harness"), which on your yes writes `Updated in place <date>: Michael …` in
  the decision file the question names (naming none: passes it on with `harness answer`, so later sessions read it)
  and runs the `done` (decisions/2026-10-29-questions-wait).
- **Weekly budget:** past `WEEKLY_STOP_AT` (default 85 %) of the plan's 7-day window, as sessions report it, the queue
  starts no run and a running one stops before its next coding session.

## Retro backlog

Every retro proposal across runs, deduplicated by id, with a status: `ledger/retro-backlog.jsonl`, one JSON row each
(`id`, `title`, `first_seen`, `runs_seen`, `status`, `spec`, `pr`, `note`). Only the harness writes it: the driver and
`harness backlog`, never a session. Each retro writes its proposals (at most three, `{id, title, evidence}`) to the
run's `retro-proposals.json`; at the run's end the driver merges them in, under the ledger lock and in the ledger
commit: a new id is a `proposed` row, a known id gains the run in `runs_seen`, and a malformed file is noted in
harness-log.md (`backlog: retro-proposals.json invalid: …`) and skipped whole. Mark what became work with `harness backlog set <id> specced --spec <path>` (or
`queued`, `merged --pr <url>`, `dropped --note "<why>"`); `harness backlog` lists it, open proposals first. Each retro
is shown that list, so it reuses an id and cites a specced or queued item's status instead of re-arguing it; the
debrief reads it to rank the open proposals.

**Seed it once, by hand, on the live checkout** (the build that added the backlog never ran this; it writes the real
ledger): `harness backlog import docs/specs/2026-10-25-memory.backlog-seed.jsonl`. It prints `backlog: imported 8
rows (8 new, 0 updated)`, makes one `ledger: backlog import …` commit, and is idempotent by id: a second import never moves a row back to an
earlier status nor clears a link `set` gave it. To look first:
`node lib/backlog.mjs list docs/specs/2026-10-25-memory.backlog-seed.jsonl` (writes nothing); to undo, `git revert`
that commit.

## Debrief

`harness debrief` replaces the hand triage after a queue. The queue runner starts it, detached, as it exits
(queue empty, past `--until`, or `harness queue stop`), if it started a run; run it by hand any time. It covers every
run whose driver started since the last debrief that produced a note, so a debrief that was refused, failed or killed
is caught up by the next one. Bash gathers the context (status, trends, the queue, the runner's log, and per run: end
reason, summary, report, the checks that flaked in two or more of the project's last five ledgered runs, retro, INBOX.md, the open question items (`harness needs --json`), the usage-limit window; and the retro backlog), then one Sonnet session writes the
note: a headline (what landed on main, what's blocked, spend against the usage window), 3–6 lines per run, **Needs
Michael**, draft answers the project's docs support (it never writes to INBOX.md), and **For the next interactive
session** (merge conflicts, the retro backlog's open `proposed` items most seen first, and items re-raised though
already `specced` or `queued`). It can ask for a continuation of a run that
ran out of time or hit the usage limit (`CONTINUE: <run> :: <brief>`); the harness checks it and queues it with
`--automatic --keep-attempts` (an automatic continuation: skipped if you stop the run first); nothing starts.

- **The page**: `ledger/debrief.html` beside the note: a card per run (passing, verified, merged, milestones,
  spend, tests, what isn't done and why), built by `lib/page.mjs` from each run's `summary.json`, not by the model,
  then the note. `DEBRIEF_PAGE_CMD` (user config) gets its path, e.g. to copy it where your phone can open it.
- **The note** is one file, `ledger/debrief.md`, overwritten each time and committed with the ledger (`LEDGER_COMMIT`),
  only while the harness checkout is on `main` with no rebase or merge going: the archive is
  `git log -p ledger/debrief.md`. The notification (title `harness debrief`; high when the note's Needs Michael
  isn't empty) carries its three-line headline and the path, or one line if it failed.
- **Read-only**: the session runs in `dontAsk` mode with an allowlist of read-only tools (one commented array in
  `lib/debrief.sh`, where the scope can be widened) plus the never-list as `--disallowedTools`; anything that still
  changes in the ledger, run worktrees or projects while it runs is flagged in the note. See `docs/architecture.md` §16.
- **Cost.** One Sonnet session per queue (`DEBRIEF_MODEL`), at most 40 turns and $3 like the retro; the context is
  capped at a few tens of KB, so a typical debrief is well under $1. Nothing to cover: no session, $0. A closed
  usage-limit window is waited out up to 5 h; past that, the next debrief (or yours, by hand) covers these runs.
- `harness debrief --dry-run` prints the gathered context and launches nothing.

## Evals

A **task** is 1–3 features copied from a real past run, with the commit they started from (`evals/tasks/<id>/task.json`);
`evals/sets/default.txt` lists the ones `--set default` runs (5 tasks, all agent-harness so far; the categories
still to add are in `evals/README.md`). Two harness versions run the same tasks and are compared.

```bash
harness eval run [--set default] [--harness <ref>] [--label <L>] [--repeat <N>]   # replay on throwaway clones; nothing posted or merged
harness eval compare <A> <B>       # pass rate, $ and tokens per verified feature, cache, orientation, context peak, wall time, rework; B's verdict against A
harness eval probes <task result>  # one tool-less Haiku turn answers the handoff questions; prints score <n>/<m>
```

Results go to `evals/results/<stamp>-<sha>-<label>/` (git-ignored). The ref's worktree lives in
`/tmp/harness-eval/<stamp>/harness` and is removed at the end. The throwaway clones (each sealed at its base: no tag
or later commit of the source) and the runs' worktrees stay beside it for `eval probes`; `rm -rf
/tmp/harness-eval/<stamp>` once you're done with them. **Evals are real sessions and cost money** (about $28 per
eval of the default set); they are Michael's to run, a harness run never does. The commands, in order, with the
cost: `evals/NEXT.md`; its `## 5. M6: the review gate` compares the harness before the review gate (tag `…/M5`) with M6
(`summary.json`'s `review.cost_pct` and `review.found_nothing` say what the reviews cost and how many found nothing
Critical or Important in any round).

## Tests

```bash
tests/run.sh          # end-to-end with stub claude/gh/curl on a throwaway repo with a bare origin: 395 checks (~3 min 30 s)
tests/run.sh gc       # only the tests/checks/ files whose names contain "gc"
TEST_JOBS=1 tests/run.sh   # one file at a time (default: half the cores, 1 to 4)
KEEP=1 bash tests/run.sh --repeat 10 lanes-two   # reproduce a flake: that file 10 times, TEST_JOBS copies at once
node --test --test-isolation=none tests/unit/*.test.mjs   # the unit tier alone (spec reporter), under a second
bash tests/run.sh unit-tier   # the unit tier as the suite runs it: PASS/FAIL lines and N/M
bash tests/run.sh --tier fast   # the fast tier only (every file whose line 2 is `# tier: fast`), its own conformance
bash tests/run.sh --tier slow   # the slow tier only; `--tier <t> <name>…` and `--tier <t> --repeat <n>` combine
bash tests/tools/coverage.sh <sets dir>   # the coverage map: the suite once, traced; one set of lines per check file (about 12 min, 9 GB of raw traces)
node tests/tools/coverage.mjs tables <sets dir>   # its five tables (what each check file runs, what nothing runs)
bash tests/tools/mutants.sh <sample.jsonl> <out dir>   # a mutation sample (mutants.mjs pick <sets dir> <seed>): each mutant against the check files that run its line
```
Line 2 of every `tests/checks/*.sh` declares its tier, `# tier: fast` or `# tier: slow`, by the 30 s rule of
`journal/decisions/2026-11-03-suite-tiers.md`; the runner refuses a file without one (`no tier header: <file>` per
file, exit 2, nothing run). A `--tier fast` run checks its names against `tests/fixtures/check-names-fast.txt`, a
`--tier slow` run against `check-names.txt` minus that list, a full run against all of `check-names.txt`; only a
full run's green is the suite's green.
The unit tier (`tests/unit/<module>.test.mjs`, one node process) tests the pure functions of `lib/*.mjs` under
`node --test`; `--test-name-pattern "<regex>"` picks tests, and `tests/checks/unit-tier.sh` puts its tests into
every full run under their names in `tests/fixtures/check-names.txt` (decisions/2026-11-03-unit-tier). Three modules
hold decisions that used to be bash, each answering a branch and never a note's words (decisions/2026-11-03-purity):
`lib/checkdecide.mjs` the suite runner's cache and rerun, `lib/lane.mjs` the lane's verdict and exit table and how a run
ends, `lib/queue.mjs` the queue entry's format, beside `lib/inbox.mjs`, which now reads INBOX.md's `status:` line too.
A check file is named for what it tests (`queue-debrief`, `memlint-run`, `session-gate-check`), with no number, and no
file's name is part of another's: `tests/run.sh <file>` and the rerun of a red file then pick that file alone (the name
lint in `suite-runner` is red on a pair; `journal/decisions/2026-11-05-suite-shape.md` has the names the files had before).
Each `tests/checks/*.sh` sources `tests/lib.sh` (a fresh `$T`, private tmux server, stub environment and throwaway
project) and runs alone; `tests/fixtures/check-names.txt` lists every check name and a full run fails on one missing,
new or doubled (a subset run, on one new or doubled). The runner starts the files `TEST_JOBS` at a time, largest first, as plain background jobs inside the
caller's check scope, prints each file's output whole when it finishes with a `<file>: <n> checks, <s> s, tier <fast|slow>`
line (the file's own tier), and ends with the slowest three, the wall time and the total. A file that exits non-zero with no `FAIL` line counts as one
failed check; stopped by a signal (check.sh's timeout), the runner prints each unfinished file's output so far and names it.
A file still running after `TEST_FILE_TIMEOUT` (10m) is stopped, its process group with it, and counted as one
`FAIL <file>: still running after TEST_FILE_TIMEOUT=<t>; stopped`.
A name of a stopped file's checks that never ran is not counted as missing, so only that file reruns (as a subset, so a name it never printed is still checked against the fixture). A timing check bounds the command's CPU time (user+sys), not its wall, which grows with the box's load; a wall limit stays beside it for a stall.
A check waits on a condition, never on the clock: `wait_for <max s> <command…>` (`tests/lib.sh`) polls every 0.1 s
and gives up after `<max>` s with `wait_for: <command> still failing after <max> s`; `stub_go`/`stub_wait <name>` (and
`STUB_BARRIER=<id>:<name>` for a stub coding session) order two events. The sleep lint (`tests/lint-sleeps.sh`, part
of the suite) fails on a `sleep` in `tests/checks/*.sh` or `tests/lib.sh` without `# sleep-ok: <why>`. To reproduce a
flake, run `bash tests/run.sh --repeat 10 <file>`: it prints `<file>: <k>/10 green` and each red copy's FAIL lines
(`KEEP=1` keeps and names each red copy's `$T`); fix it at its cause, with a check red before the fix
(decisions/2026-10-29-tests-wait-not-sleep).
The stubs replay real CLI output where it matters (`tests/fixtures/usage-limit.jsonl`, captured 2026-10-17).
**Coverage and mutation, by hand.** `bash tests/tools/coverage.sh <sets dir>` runs the suite once with every check file's bash
traced and node's own coverage on, and leaves one set per check file: the lines of `lib/` and `bin/` it runs
(`node tests/tools/coverage.mjs tables <sets dir>` prints the map's five tables; `union` and `missing` compare two maps).
The trace is the harness's own switch: with `HARNESS_XTRACE=<dir>` any harness command or run writes bash's `set -x` lines to
`<dir>/<pid>.xtrace` (off unless set; a traced run's first log note says where it goes; a trace holds tokens in the clear,
so its files are mode 600 and the directory is yours to delete). `node tests/tools/mutants.mjs pick
<sets dir> <seed>` draws a mutation sample and `bash tests/tools/mutants.sh <sample.jsonl> <out dir>` runs it: each small
change against the check files that run its line, the tree put back after each. Neither is part of the suite or of a run;
the first map and sample are `findings-and-research/2026-11-03-suite-coverage.md` (decisions/2026-11-03-suite-coverage).
**Removing a check.** A check goes only when every assertion it makes is made by a check or unit test that stays, and
it is named with that successor in a decision file; then the map is run again and `coverage.mjs missing <union before>
<union after>` prints nothing. The first trim, row by row: decisions/2026-11-03-trim. A check of what a `lib/*.mjs`
CLI prints belongs in `tests/unit/` (`sameAsCli` holds `main`'s bytes and exit code to the spawned CLI's).
