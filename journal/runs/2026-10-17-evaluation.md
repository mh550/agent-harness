# 2026-10-17 · Evaluation of the first harness v2 night

Two runs, started 10 s apart at 02:24 EDT: [`threads-2026-10-17`](threads-2026-10-17.md) (Pathways) and
[`dj-2026-10-17`](dj-2026-10-17.md) (dj-crate-streaming). This file holds what the night shows about the
harness, the bugs with fixes, the per-project configuration redesign (Part B), and the ranked v3 list.

## The night in numbers

| | Pathways | dj |
|---|---|---|
| Passing / verified | 21/37 · T0, T1, T3 verified (13) | 5/19 · N1 verified (5) |
| Real sessions (not $0 limit failures) | 1 init + 22 coding + 3 verify | 1 init + 6 coding + 1 verify |
| Limit failures counted as attempts | 18 (in 4 min) | 27 (in 2 min) |
| Cost · $ per passing feature | $46.80 · **$2.23** | $22.56 · **$4.51** |
| Coding time per passing feature (wall) | 7 min | 20 min (+ 7.5 min driver re-check) |
| Ended | `MAX_SESSIONS=40` at 05:18 | "no feature left to try" at 05:23 |
| Should have ended | 06:10 reset → resume, ~10:24 deadline *(inferred)* | same |
| Permission denials · feature-list repairs · red un-passes | 0 · 0 · 0 | 0 · 0 · 0 |
| Live-system commands executed | n/a | **none** (transcript scan) |
| Human interventions | 0 | 0 |
| PR | #4: mergeable, but merge **T0–T3 only** | #3: mergeable as code; **don't run trash live** before two fixes |

## What the night shows about harness v2

1. **The core loop works.** 27 consecutive real coding sessions across two projects each did one feature,
   test-first, read the inbox, logged, committed and pushed, without a single repair, red suite or permission
   denial. "Agents do judgment, the driver does bookkeeping" held: nothing the driver was supposed to do every
   time was skipped.
2. **The one failure was the harness's, and it is the oldest lesson in the journal.** Both runs hit the plan's
   five-hour usage limit at 05:13. The detector, built for exactly this (D-H9), was tested only against a stub
   message I made up (`"Claude AI usage limit reached|…"`). The real one says `"You've hit your session limit"`
   and carries `"api_error":"usage_limit_reached"`. 45 sessions were "spent" in six minutes and both runs ended
   with 5 h left. Night 1's rule was "fakes mirror the live API"; the harness's own test fake broke it.
3. **Parallel runs are not free.** Two runs consumed the five-hour window in 2 h 49 min. Iteration 1 (three
   parallel loops) hit the same wall. The harness has per-run isolation (worktrees, ports) but no shared view of
   the one resource every run shares.
4. **Verification is the weakest gate.** Pathways' verify sessions took 29–40 s for 3–5 features (one curled a
   server, one wrote a test, one mostly re-ran the suite). dj's took 10 min, mostly running the suite. Meanwhile
   the real defects were found by today's Opus review: unrecorded decisions, a half-built `/live?graph=`, a
   README promising missing behaviour, and four Important trash-flow gaps in dj. The per-milestone review
   features (T1-05, T3-05, N1-05) are where quality came from; the verify session added little.
5. **The milestone grain is right for merging, the feature grain is too fine.** Pathways features took a
   median 6 min against the 30–90 min the initializer was told to aim for; plan + build + review per milestone
   is a lot of overhead at that size. dj's (14–28 min) were closer.
6. **Metrics lied by half.** "Session time 1.2 h" was 2.54 h. Multi-`result` transcripts (background subagents)
   broke the duration field. Wall-clock time from the driver is the number to trust.
7. **Run scope does not belong in a committed project file.** dj's rules were edited 46 s before the run and
   came out contradictory; the initializer had to resolve "never operate" vs "you can test live" vs "code only".
   It chose code only, which was right, but the night's policy should have been one unambiguous line.
8. **Fable as initializer earned its cost** ($12.22 for both lists, 18 % of the night): zero repairs, steps the
   spot-checks could execute literally, and handover entries the sessions relied on.

## Harness bugs, each with a fix

Ranked by what they cost last night.

### B1 · The usage-limit detector didn't recognise the real limit message (cost: ~5 h of both runs, 45 sessions burned)
- **Evidence:** at 05:13–05:14 both runs hit the plan's five-hour limit. Every later session returned in under a second:
  `"is_error":true, "api_error_status":429, "api_error":"usage_limit_reached", "terminal_reason":"api_error",
  "result":"You've hit your session limit · resets 6:10am (America/New_York)"` (e.g. `logs/26-T5-02.jsonl`).
  `lib/metrics.mjs:30` matches `/usage limit|rate.?limit|limit reached|…/` against `result` and `subtype` only.
  "session limit" matches none of them, and the structured fields were never read. So the driver counted each as a
  failed attempt: pathways burned 18 sessions in 4 min (T4-09 … T6-02) and hit `MAX_SESSIONS=40`; dj burned 27 in
  2 min and ran out of features. Both stopped at ~05:23 with 5 h of the 8 h budget left and the limit resetting at 06:10.
- **Root cause, worth saying in the interview:** the stub test (`tests/stub-claude.sh:28`) emits
  `"Claude AI usage limit reached|1760700000"`, a message *I guessed*. It is the same failure ON2 wrote a rule
  about after night 1: "Fakes mirror the live API". The fake guessed the shape; the real API said something else.
- **Fix:**
  1. Decide on structure first: `api_error` set, or `api_error_status ∈ {429, 529, 5xx}`, or
     `terminal_reason == "api_error"` → limit/outage. Keep the regex only as a fallback and add `session limit|weekly limit`.
  2. Belt and braces: a session with `total_cost_usd == 0` and `num_turns ≤ 1` never spends an attempt, whatever it says.
  3. Circuit breaker: 3 sessions in a row that end in < 60 s → pause and notify, independent of the message.
  4. Sleep until the reset, not 15/30/60 min: the stream carries `rate_limit_event … "resetsAt":1792231800`; sleep to
     that + 2 min.
  5. Replace the stub's invented line with the real result line from `26-T5-02.jsonl` as a fixture, and add a test
     where the limit hits *mid-session* (the real 22-T4-09 / 06-N2-01 shape: real work, then the limit result).

### B2 · Parallel runs share one plan limit and don't know it
- **Evidence:** two runs started 10 s apart and together spent the five-hour window in 2 h 49 min
  (02:24 → 05:13; ≈ $69 of API-equivalent cost). Iteration 1 hit the same wall with three parallel loops (timeline,
  turning point 5).
- **Fix:** a shared marker `~/.local/state/harness/LIMIT_UNTIL` (epoch from `resetsAt`). Any run that sees a limit
  writes it; every driver checks it before starting a session. Optional: `harness start --after <run-id>` to queue
  runs instead of racing them.

### B3 · "final verified" is printed, tagged and annotated for every run
- **Evidence:** `harness-log.md` ends "final verified and tagged run/threads-2026-10-17/final" with 16/37 features
  unverified; tags `run/threads-2026-10-17/final` and `run/dj-2026-10-17/final` exist with the message
  "final verified". `lib/driver.sh:227` calls `propose final` unconditionally, and `propose` always tags and
  always says "verified".
- **Fix:** split `propose` into `tag_milestone` (only after `verify` holds) and `update_pr` (body only). At the end:
  `update_pr` with "run ended: N/M passing; verified: T0, T1, T3; unverified on the branch: T4-01…T4-08". Tag
  `final` only when every milestone is verified. Delete the two misleading `final` tags (Michael's call; agents
  may not delete tags).

### B4 · `harness status` shows a finished run as "running"
- **Evidence:** `tmux ls` at evaluation time (≈11:00, six hours after both drivers exited) still lists `h-threads-2026-10-17` and `h-dj-2026-10-17`.
  `bin/harness:105` equates "tmux session exists" with "running", and `cmd_start` keeps the driver window open on
  purpose (`exec bash`).
- **Fix:** the driver writes `$STATE/driver.pid` at start and `$STATE/ended` (with the reason) at exit; status says
  `running` only if `kill -0 $(cat driver.pid)`, else `ended (<reason>)`.

### B5 · Metrics undercount session time and turns by half
- **Evidence:** the summary says 1.2 h (pathways) and 1.9 h (dj) of session time. The driver's own log says coding
  sessions took **2.54 h** and **1.79 h**, init 0.18/0.16 h, verify 0.03/0.17 h. A session that uses background
  subagents emits several `result` events (pathways `08-T1-05` has 10); `total_cost_usd` is cumulative but
  `duration_ms` and `num_turns` are per segment, and `lib/metrics.mjs:8` keeps only the last one (T1-05: 229 s
  recorded, 7.5 min real; dj N1-02: 21 s recorded, 14.4 min real).
- **Fix:** the driver records wall time itself (`t0` is already there) as `wall_s`; metrics sums `num_turns` over
  all result events and keeps the max cost. The summary reports wall time.

### B6 · The suite runs twice per passing session on slow projects
- **Evidence:** dj: every passing session is followed by 7–8 min of `green()` (0.60 h of 2.98 h wall, 20 %), right
  after the session itself ran the full suite before flipping `passes` (as `project.md` told it to). The session
  ran `.harness/check.sh` directly, which doesn't write the `green-<tree>` marker that `init.sh` and `green()` share.
- **Fix:** export one cached check (`$HARNESS_CHECK`, a tiny wrapper that keys on the tree and writes the marker)
  and tell sessions to run that. dj would have saved ~35 min of 3 h.

### B7 · Verify sessions are too cheap to be independent (pathways)
- **Evidence:** pathways' three verify sessions took 29–40 s, 6–7 turns, $0.16–0.18 each — for 3–5 features with
  5–7 steps each, some needing a browser. Only T3's verifier exercised a running server; T0's re-ran the suite and
  smoke and read notes; T1's wrote one test of its own. None re-ran a UI step. dj's ran 10 min, mostly the
  7-min suite *(see the dj report)*.
- **Fix:** give the verify prompt a per-step checklist to fill (`id · step n · command run · observed`) and have the
  driver reject a verify entry whose step count is below the milestone's total steps (then re-run it once on Opus).
  Allow the verifier subagents for browser steps.

### B8 · The next feature ignores milestone and dependency state
- **Evidence:** after T4-09 (T4's review) failed, the driver moved straight to T5 and T7. With a real failure (not
  the limit) T5 would have built on unreviewed, unverified T4 code. The PR branch already contains T4-01…T4-08,
  unverified, beside three verified milestones.
- **Fix:** `F next` skips a feature whose milestone predecessor is given up, and a milestone whose closing review
  failed blocks the next one (it becomes "needs Michael"). Keep unverified work off the PR's "merge me" path: the
  PR body names the last verified tag as the thing to merge (`git merge run/<id>/T3`).

### B9 · Silent permission source
- **Evidence:** dj's PR #2 (merged 02:23:48, run started 02:24:34) deleted `.claude/settings.json`; `AGENT_SETTINGS`
  pointed at a file that no longer existed and `lib/driver.sh:85` silently dropped `--settings`. Sessions ran on user
  settings only. Nothing went wrong, but nothing recorded it either.
- **Fix:** log at start: "permissions: user settings + <file>" or "user settings only", and copy it into the PR body.

### Smaller
- `MAX_SESSIONS=40` caps sessions, not progress. Real need: pathways used 22 real sessions for 21 features; 37
  features with ≈1.2 sessions each ≈ 45 sessions. Make the cap `3 × features` by default and let `HOURS` and a run
  budget in $ be the real limits.
- `n` counts coding sessions only; verify sessions are uncapped (fine) but uncounted in the log line "session N".
- The progress log's header got split by T1-03 (T1-04 had to move entries, commit `122e110`); one session (T4-08)
  wrote no entry with its id. The driver could check "a heading with `$id` exists" and add a stub entry if not.

## Part B — per-project configuration

### What the two projects actually wrote (line by line)

| File | Pathways (lines) | dj (lines) | Generic (same in both, or a harness default restated) | Truly project-specific |
|---|---|---|---|---|
| `config.sh` | 22 | 21 | 17 of 22 lines restate driver defaults exactly (`HOURS=8`, `MAX_SESSIONS=40`, `MAX_ATTEMPTS=2`, the models, the timeouts, `PR_POLICY`, `MAIN_BRANCH`, `NOTIFY_CMD=""`) | `SPEC_FILES` (per *run*, not per project), `CHECK_CMD`, `SMOKE_CMD`, `BASE_PORT` (only needed because ports are allocated from it) |
| `init.sh` | 26 | 20 | Both run the whole suite and print green/RED. dj's even re-implements the driver's tree-key cache. The driver runs `CHECK_CMD` anyway, so this is duplicated work | Pathways: Playwright location, the scratch server with the sample graph and the 399 replay. dj: tool presence checks (`ffmpeg`, `beet`, …) |
| `project.md` | 48 | 52 | Stay in this worktree · no sudo · no secrets/`.env` · decision protocol (simplest reversible default, record as `D<n> *default*`, ask in the progress entry) · a plan file per milestone · review + simplify features · "What Michael will see" | **Durable facts:** code rules (zero deps / stdlib, use-what-exists list, safety invariants), how to verify (suite length, dev server, smoke), where decisions live, read-only inputs. **Run scope:** "Tonight: items 1–4", "T2 is dropped", milestone ids, which milestone to drop first, real names to use in steps. **Policy:** build-only vs live |
| `.claude/settings.json` | 63 | 0 (deleted 02:23) | The history-destroying denies are already in `~/.claude/settings.json` (force push, `branch -D`, `tag -d`, filter-repo, reflog expire, gc prune, sudo, `.env`) | Pathways: three allows (`bin/pathways`, `PATHWAYS_DB=/tmp/harness/…`, `node .harness/smoke.mjs`) |
| other | `smoke.mjs` | `check.sh` (sandbox) | — | both genuinely project-specific |

So of ~150 lines per project, about 15 are durable project facts that only the project can say, about 10 are run scope, one is policy, and the rest is either a harness default or a generic rule that belongs in `prompts/`.

Two more observations from the night:
- **Run scope in a committed project file is a trap.** dj's `project.md` on `main` says "Tonight: items 1–4, code only". The next run inherits "tonight" unless someone edits `main` first. Michael edited it 46 s before the run and the result was half-edited (see the dj report).
- **The live-ops edit failed because the policy is free text in the middle of other rules.** The heading still says "build and test, never operate", the new bullets say "you can test out your changes live", and the spec section says "code only". The initializer resolved the conflict conservatively ("Nothing tonight writes to the live box"). That was the right call, but it should never have had to make it.

### Options weighed

| Option | For | Against | Verdict |
|---|---|---|---|
| **Conventions** (detect stack, test command, spec) | Zero lines for the common case: `package.json` → `npm run check` or `npm test`; `pytest.ini`/`pyproject` → `pytest -q`; port from a free-port scan | Can't detect a sandbox (dj's `check.sh` exists *because* the plain suite could touch `/srv`); the spec is per run, not discoverable | **Yes**, for check/smoke/port defaults, with an override |
| **Initializer drafts `project.md`** | No hand-writing; the first PR carries it for approval | It runs *inside* the run it governs: the rules that bind tonight's sessions would be unreviewed until morning. Fine for a brand-new project's first, build-only run; wrong for a live system | **Only as a bootstrap** when no `CLAUDE.md` exists, and only under `build-only` |
| **Reuse `CLAUDE.md` / runbooks** | Claude Code loads `CLAUDE.md` in every session, interactive ones too, so Michael's own sessions get the same rules. dj's runbook (`docs/worker.md`) already holds the exact staged commands | Neither repo has a `CLAUDE.md` yet; one-time migration | **Yes**: durable facts go in `CLAUDE.md`; runbooks are linked, not copied |
| **Policy profiles** (`POLICY=live-staged` / `build-only`) | One line decides the most dangerous question; the protocol text is written and tested once, in the harness; the driver can also act on it (live-write lock, notify before stage "all") | A profile can't know dj's backup command or check command | **Yes**, with the project supplying a short "Live system" fact sheet the profile refers to |
| **Move generic rules into `prompts/`** | Removes ~60% of each `project.md`; fixes them everywhere at once | None real | **Yes** |

### Recommendation: **conventions + one policy line + `CLAUDE.md` + a run brief**

1. **Harness owns the generic rules.** Move into `prompts/coding.md` (and initializer/verify): stay in the worktree; no secrets; the decision protocol; a plan file per milestone at `docs/plans/<date>-<milestone>-<topic>.md`; review + simplify; a "What Michael will see" feature after each UI milestone.
2. **Conventions fill `config.sh`.** Every limit defaults in the driver. `CHECK_CMD` is detected (`.harness/check.sh` if present, else `npm run check`/`npm test`/`pytest -q`); `SMOKE_CMD` is `.harness/smoke.*` if present; `INIT_CMD` is `.harness/init.sh` if present, else nothing. The driver runs the (cached) check itself and pastes the result, so `init.sh` shrinks to "start the dev server", or disappears.
3. **One policy line:** `POLICY=build-only` (default) or `POLICY=live-staged`. The harness appends `prompts/policy/<policy>.md`. The policy text is generic; it points at the project's `## Live system` section in `CLAUDE.md` for the commands.
4. **Durable project facts live in `CLAUDE.md`** (≈20–40 lines): what the repo is, code rules, how to verify, where decisions live, read-only inputs, and for live projects a `## Live system` fact sheet. The harness passes `CLAUDE.md` into the prompt explicitly too, so it doesn't depend on whether headless sessions in an untrusted worktree load it *(inferred that they do; one headless call settles it)*.
5. **Run scope moves to `harness start`:** `harness start <project> <run-id> --spec docs/next-todos.md --brief "items 1–4 only; milestones N1–N4, N5 wrap-up"`. The driver writes it to `.harness/runs/<run-id>/brief.md` (committed, visible in the PR). Nothing about "tonight" is ever committed to `main`.
6. **Bootstrap:** `harness init` writes nothing but `CLAUDE.md` if missing, drafted by one Sonnet session from the README, docs and runbooks, for Michael to edit and commit. (The initializer-drafts option, but before the run, not inside it.)
7. **Permissions stay Michael's and stay small.** The harness never writes settings. User-level `~/.claude/settings.json` holds the policy (it already has every history-destroying deny). A project adds a settings file only for allows that its own commands need, passed with `--settings`. `harness init` *prints* the suggested lines; it does not write them. A live-staged project needs a few allows Michael adds himself (below).

### What the two projects shrink to

**Pathways**
```bash
# .harness/config.sh
SMOKE_CMD="node .harness/smoke.mjs"       # (detectable too; kept explicit)
```
- `.harness/init.sh`: the 8 lines that seed the scratch DB and start the replay server (suite and Playwright lines go: the driver runs the check; Playwright moves to the harness's shared `$HARNESS_PW`).
- `.harness/smoke.mjs`: unchanged.
- `CLAUDE.md` (new, ≈25 lines, from today's `project.md`): zero runtime deps; `ui/words.js` owns on-screen nouns; decisions in design §12 (`D<n> *default*`); `/srv/incoming` and `samples/` are read-only; suite is `npm run check` (211 tests); dev server and replay end state; Playwright via `createRequire($HARNESS_PW)`.
- Run brief at start: `--spec "OVERNIGHT.md docs/specs/2026-10-14-threads-and-graphs-design.md" --brief "Queue T4-09 onward; T6 drops first; use the sample-notes names in steps"`.
- `.claude/settings.json`: at most three allows (`bin/pathways`, `node .harness/smoke.mjs`, `PATHWAYS_DB=/tmp/harness/…`), possibly none: dj's run had no project settings at all and hit zero denials in six build sessions *(inferred that Pathways would too; one run without `--settings` settles it)*.

From 5 files / ~160 lines to 1 config line + init + smoke + a `CLAUDE.md` that also serves interactive sessions.

**dj-crate-streaming**
```bash
# .harness/config.sh
POLICY=live-staged
```
- `.harness/check.sh`: unchanged (the sandbox is the one thing conventions must never guess). `CHECK_CMD` is detected from it.
- `.harness/init.sh`: deleted (tool checks move into `check.sh`'s first lines or `CLAUDE.md`; the cache is the driver's).
- `CLAUDE.md` (new, ≈35 lines): stdlib only; the use-what-exists list; the four safety invariants; hard-won facts link; suite ~7 min; decisions D1–D39 in the pivot spec; plus the `## Live system` section drafted below.
- Run brief at start: `--spec "docs/next-todos.md docs/specs/2026-10-17-amperfy-pivot.md" --brief "items 2–4 (N1 is built, PR #3); live stages allowed for N1 per CLAUDE.md"`.
- Permissions Michael adds himself (proposed text, not applied):
  ```json
  { "permissions": { "allow": [
      "Bash(scripts/deploy.sh:*)",
      "Bash(scripts/snapshot-crates-db.sh)",
      "Bash(docker compose ps:*)", "Bash(docker image ls:*)",
      "Bash(docker compose exec -T worker python3 -m scripts.:*)",
      "Bash(docker compose run --rm worker python3 -m scripts.:*)",
      "Bash(docker compose exec -T crates python3 -m crates.cli:*)",
      "Bash(docker compose stop worker)", "Bash(docker compose up -d worker)"
    ], "deny": [
      "Bash(*fetch*--approve*)", "Edit(//srv/incoming/**)", "Write(//srv/incoming/**)", "Read(//srv/docker/.env)"
  ] } }
  ```
  (The denies already sit in user settings; repeated here only if the file is ever used without them.) Whether an allow rule is enough to get past the classifier's "production deploy" block (seen on 10-16, `971f6a7`) is untested: **one attended deploy under these settings answers it**.

From 6 files / ~185 lines (with the deleted settings) to 1 config line + `check.sh` + `CLAUDE.md`.

### Draft: dj's live-operations section (for `CLAUDE.md`, under `POLICY=live-staged`)

The generic half goes in the harness as `prompts/policy/live-staged.md`; the project half is dj's fact sheet. Both are written out here so Michael can apply them as one block today (paste into `.harness/project.md`, replacing "The one rule that shapes this night") and split them later.

```markdown
## Live operations (policy: live-staged)

This repo runs Michael's live music server (Navidrome, the `crates` and `worker` containers, `/srv/music`,
`/srv/_trash`). It is a beta with one user, backed up by git and a nightly restic run. Sessions **may operate it
live**, but only through this protocol. Build and test first (fakes, `tmp_path`, `.harness/check.sh`); a live
stage is the last step of a feature, never a way to debug.

### Before the first live write of a session
1. The suite is green on the commit you will run, and the tree is clean (deploy refuses a dirty tree).
2. **check** is green:
   `docker compose run --rm worker sh -c 'python3 -m scripts.export_playlists export && python3 -m scripts.export_playlists check'`
   (from `/srv/docker`; a check without a fresh export reports "stale").
3. Snapshots: `scripts/snapshot-crates-db.sh` and
   `sqlite3 /srv/docker/navidrome/navidrome.db ".backup /srv/docker/navidrome/navidrome.db.pre-<run-id>.snap"`.
4. Note in your progress entry: the last restic run
   (`systemctl show restic-backup.service -p ExecMainExitTimestamp -p ExecMainStatus`; status must be 0 and the
   run less than 26 h old, else stop and ask), the running images (`docker image ls dj-crates`,
   `docker compose ps`), and the snapshot paths.

### Deploying
- Only with `scripts/deploy.sh` from **this run's worktree**, on a pushed commit. First record the image tag that is
  running now; that tag is the rollback (`GIT_SHA=<old> docker compose ... up -d --no-build`, see the script header).
- After a deploy: `docker compose ps` healthy, **check** green, one Subsonic ping. Any failure → roll back, log, stop.

### Stages (every write)
`--dry-run` → `--limit 5` → `--limit 50` → all. After **each** stage: the tool's own exit code and report, then
**check**. Read every refusal before the next stage. The exact commands per flow are in `docs/worker.md`
(duplicate cleanup: "1. Before" to "4. Trash"). A flow without a dry run, a `--limit` and a reverse log is not run
live: write its live steps in your progress entry instead.

### On the first problem
Stop. Undo with the flow's reverse log (`repoint-<time>.jsonl`, `/srv/_trash/<day>/MOVES.txt`, `trash-<time>.jsonl`),
run **check** until green, roll back the image if you deployed, and log what happened at the top of progress.md
with the exact commands you ran. Don't flip `passes`; don't retry in the same session.

### One live writer at a time
Wrap every live write in `flock -n /tmp/harness/dj-crate-streaming/live.lock <command>`. If the lock is taken,
another run or Michael is writing: don't wait, log it and end the session. The tools' own `/data/worker.lock`
still applies on top.

### Still never
- Soulseek transfers (`fetch --approve`, D7) or anything that starts a download.
- Writes under `/srv/incoming` (not backed up).
- The `amperfy` account or its playlists.
- Secrets: `/srv/docker/.env`, `/etc/restic/env`; never print credentials.
- `sudo`, restic itself (`restore`, `forget`, `prune`), or editing `/srv/docker/compose*`.
- Rewriting git history, or deploying from `~/projects/dj-crate-streaming` (other sessions use it).
```

## Ranked changes for harness v3

| # | Change | Why (evidence) | Size |
|---|---|---|---|
| 1 | **Limit detection on structure** (`api_error`, `api_error_status`, `terminal_reason`), a $0/≤1-turn session never spends an attempt, sleep until `resetsAt`, a 3-fast-failures circuit breaker; the stub replays the **real** result line | B1: lost ~5 h × 2 runs | ~30 lines + test fixture |
| 2 | **Shared limit marker across runs** (`LIMIT_UNTIL`) and `harness start --after <run>` to queue | B2: two runs spent the 5 h window in 2 h 49 min | ~15 lines |
| 3 | **Honest end of run**: no `final` tag or "verified" unless every milestone is; the PR body names the last verified tag to merge and lists unverified features on the branch | B3, B8: PR #4 carries unreviewed T4 under a "final verified" label | ~20 lines |
| 4 | **Milestone gating**: a failed closing review/verify blocks later milestones ("needs Michael") instead of building on top | B8 | ~15 lines |
| 5 | **A verify that can't be skimmed**: per-step evidence table, driver rejects an entry with fewer rows than steps; browser steps via a Sonnet subagent; Opus for UI milestones | B7: 29–40 s verifies; the real defects were found by review | prompt + ~15 lines |
| 6 | **Config by convention + `POLICY=` + `CLAUDE.md` + `--brief`** (Part B) | 150+ lines per project, 1 line project-specific; dj's half-edited policy | prompts + ~40 lines + migration of 2 repos |
| 7 | **One cached check** (`$HARNESS_CHECK`) used by init, sessions and the driver | B6: 35 of 179 min of dj's night | ~10 lines |
| 8 | **Wall-clock metrics** (driver-timed `wall_s`, summed turns) | B5: "1.2 h" was 2.54 h | ~10 lines |
| 9 | **`harness status` from the driver pid** + `ended (<reason>)` | B4 | ~8 lines |
| 10 | **Coarser features**: initializer told the night's real pace (median 6 min) and to merge plan+build where a milestone is small; caps from features (`3 × n`) and $ budget rather than `MAX_SESSIONS=40` | Pathways sizes; the 40 cap | prompt + 5 lines |
| 11 | Log the permission source at start and in the PR (B9); stub a progress entry when a session wrote none | B9; T4-08 | small |

Items 1–3 are the ones to fix before the next unattended night. 1 alone would have roughly doubled what both runs
delivered *(inferred from the night's pace: ~7 min/feature Pathways, ~20 min dj, 4 more hours)*.
