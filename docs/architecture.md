# agent-harness — architecture (v3.1)

How the harness works, at the level you need to maintain and extend it. The README is the quick start; the
journal (`journal/`) is the history of why. This file is the system as it is.

## 1. What it is, in one paragraph

A run turns a spec into merged, verified code without anyone watching. One **initializer** session (Fable) writes a
feature list. A **driver** (bash, deterministic, $0) then starts one fresh headless Claude session per feature, in
dependency order, and does all the bookkeeping around them: init, suite, sync, guards, metrics. When every feature of
a milestone passes, an independent **verify** session re-runs every step. A verified milestone is tagged and
**merged into `main` through its own PR**. At the end the driver writes a summary, runs a **retro** session that
proposes harness changes, and records the run in the harness's own **ledger**. Runs are queued, and they share one
view of the plan's usage limit. When a queue ends, one read-only **debrief** session writes Michael a triage note.

## 2. Principles (each one is a decision in `journal/decisions.md` or `journal/decisions/`)

| Principle | Consequence in the code |
|---|---|
| **Fresh context per feature; state lives on disk** (D-H1) | Sessions know only the feature list, `progress.md`, `INBOX.md`, git and the prompt. Nothing is carried in memory between sessions |
| **Agents do judgment; the driver does bookkeeping** (D-H5) | Everything that must happen every time is bash: init, suite, sync, repair, un-pass, verify scheduling, tags, merges, metrics, summary |
| **Guard, don't trust** (D-H3, D-H4) | A session may only flip its own `passes`; a red suite un-passes; a separate verifier re-runs steps with evidence |
| **Not the feature's fault → not the feature's attempt** (D-H9, D-H11) | Limits, API errors and $0 sessions are given back and waited out |
| **Milestones are the unit of merge** (D-H6, D-H13, D-H17) | Only verified milestones reach `main`, in order. Unverified work stays on the run branch |
| **Humans gate policy, not routine** (D-H15, D-H16) | Merges of verified work are automatic. Permissions, policies and project rules change only through Michael |
| **Measure every run; learn from the ledger** (D-H19) | `summary.json`, `retro.md`, `ledger/runs.jsonl`, `harness trends`, calibration fed back to the initializer |

## 3. Components

```
 you ──► bin/harness ──► queue (state/queue/*.args) ──► lib/queue.sh (tmux h-queue)
          │  start/continue/merge                          │ starts runs: MAX_PARALLEL_RUNS, --until, limit window
          ▼                                                ▼
     tmux h-<run>: driver window ──► lib/driver.sh ──────────────────────────────┐
                   log window (tail run.log)   │ per session:                    │ at the end:
                   supervisor (interactive)    │  claude -p <prompt>             │  summary.mjs build/report
                                               │   initializer | coding |        │  retro session
                                               │   verify | retro                │  ledger (harness repo)
                                               │ libs: config.sh check.sh notify │  notify, queue continuation
                                               │  features.mjs metrics.mjs       │
                                               │  treekey.mjs testcount.mjs      │
                                               ▼                                 ▼
                         git worktree ~/worktrees/<p>/<run> ─── origin (GitHub): harness/<run>,
                         branch harness/<run>                    harness-merge/<run>-<m>, tags run/<run>/<m>,
                                                                 milestone PRs → main
```

| Component | Lines | Responsibility |
|---|---|---|
| `bin/harness` | ~350 | CLI: start/continue/merge/queue/status/parked/report/trends/attach/pause/resume/stop/answer/init/gc/debrief. Creates worktrees, ports, state dirs, tmux sessions |
| `lib/driver.sh` | ~370 | The run loop (§5). The only component that runs sessions, commits on the run's behalf, tags and merges. The session command line (`session()`): `claude -p <prompt> --model <m> --permission-mode auto [--settings <wt>/.claude/settings.json] --strict-mcp-config [--mcp-config <wt>/.mcp.json] --max-turns … --max-budget-usd … --output-format stream-json --verbose`, under `timeout -k 30s SESSION_TIMEOUT` in its scope. `--strict-mcp-config` always, `--mcp-config` only when the worktree has a `.mcp.json`: a session loads its project's committed MCP servers and no others (run.log's `MCP servers:` line at the run start; decisions/2026-10-25-strict-mcp-and-deepequal-rule) |
| `lib/queue.sh` | ~50 | Starts queued runs within the parallel limit (one per project), the `--until` time and the usage-limit window; skips parked entries; syncs the live checkout when no run is alive; starts `harness debrief`, detached, as it exits (§12, §16) |
| `lib/sync.sh` | ~40 | The live checkout level with origin: merged PRs in, the driver's ledger commits out, only when safe (§12) |
| `lib/debrief.sh` | ~280 | `harness debrief`: gathers the context in bash, waits out the limit window, one read-only session, the note, checked continuations, the notification (§16) |
| `lib/config.sh` | ~60 | Config layers and conventions (§10) |
| `lib/notify.sh` | ~50 | `notify "<message>" [title= body= click= actions= priority= tags=]` for the driver and the debrief: posts to `NTFY_URL` through `${HARNESS_CURL:-curl}` (bearer `NTFY_TOKEN`), else runs `NOTIFY_CMD` with `$1` + `HARNESS_NOTIFY_*`; always returns 0, a failed post is a note. `gh_url <path> [blob\|edit]`: that file on the run branch on GitHub, or nothing |
| `lib/notify.mjs` | ~75 | Pure helpers for it: `githubUrls` (GitHub origins only), `trimBody` (3500 bytes, `…`), `actionsHeader` (ntfy `view, <label>, <url>; …`), `inboxQuestion` (the lines a session added above `## Answers`) |
| `lib/parked.mjs` | ~110 | `harness parked` (§17): pure `questionFor`, `commandsFor`, `entriesFor`, `parkedReport`, and a `report` CLI over the state dirs bash names on stdin. Never writes |
| `lib/check.sh` + `treekey.mjs` | ~60 | The suite, cached per content of the code tree. One command for the driver and every session. Full and subset runs alike go under `timeout -k 30s $CHECK_TIMEOUT` (15m) in the scope `harness-<run>-check-<pid>` (`MemoryMax=CHECK_MEMORY_MAX`, 3G, no `MemoryHigh`; the prefix, cap and timeout come from `prompt_env`, so a session's call caps like the driver's), stopped after; bare without a prefix or user systemd. A TERM to `check.sh` stops the scope with it. A kill gets its own RED line: `check: RED (killed at its 3G memory cap, exit 137 after <n> s)` or `check: RED (timed out after 15m, exit <rc> after <n> s)` (decisions/2026-10-25-capped-suites) |
| `lib/scope.sh` | ~70 | Capped transient systemd user scopes (decisions/2026-10-25-scoped-sessions): `scope_run <unit> <high> <max> <cmd…>` (`systemd-run --user --scope --collect`, `MemoryHigh`/`MemoryMax`/`MemorySwapMax`, `OOMPolicy=continue`, a wrapper inside the scope that records `MemoryPeak` and `TasksCurrent` before it exits), `scope_stop`, `scope_peak` (MB), `scope_left`, `scope_capped`, `scope_unit` (`harness-<run>-<role>`, the run id reduced to `[A-Za-z0-9_-]`), `dur_s` (`15m` → 900), `mem_available_gb` (`MemAvailable` of `${HARNESS_MEMINFO:-/proc/meminfo}`, whole GB) and `mem_gate` (§7). Bare when the probe `systemd-run --user --scope --quiet true` fails |
| `lib/entries.mjs` | ~330 | The journal (decisions/2026-10-22-journal-single-writer, -rendered-progress, -context-pack): pure `journalEntry`, `stamp`, `render`, `pack`; verbs `ingest` (validate `entry.json`, stamp, append to `entries.jsonl`), `render` (progress.md, progress-archive.md) and `pack` (context.md within `CONTEXT_PACK_BYTES`) |
| `lib/features.mjs` | ~200 | The feature-list contract: scheduling, gating, repair, kinds, evidence counting |
| `lib/metrics.mjs` | ~100 | Per-session metrics; the "environmental?" decision (limits, API errors, $0) |
| `lib/summary.mjs` | ~230 | Run summary, writeup, ledger rows, trends, calibration |
| `lib/prompt.sh` | ~50 | The driver's prompt assembly (`prompt_vars`, `prompt_env`, `prompt_render`), sourced by the driver; run as `prompt.sh <state dir> <template> <feature>` it renders a run's prompt the way its driver would (eval probes use it) |
| `lib/eval.sh` | ~260 | `harness eval run\|compare\|probes` (§11): replays `evals/` tasks with a ref's own driver on throwaway clones in `/tmp/harness-eval/<stamp>/`, under `EVAL_BUDGET_USD` and the 7-day window; compare; probes |
| `lib/eval.mjs` | ~335 | Pure helpers: task validation, `spent`, `loadResult`, `METRICS`, `compare`/`compareText` (verdicts with the repeat spread as noise), probe `questions`/`score` |
| `lib/render.mjs` | ~35 | Prompt templating (`{{X}}` ← `HARNESS_X`), titled sections placed at a `{{SECTIONS}}` line (`assemble`) |
| `lib/page.mjs` | ~130 | The debrief page: a card per run from summary.json, then the note (escaped), one self-contained HTML file |
| `lib/desk.sh` | ~240 | `harness desk <run> [--why …]` \| `--debrief` (§17): a Remote Control `claude` in tmux session `h-desk`, window `<run>`, in the project directory; the pane's session URL is the notification's click; one desk per run (a later event is typed into the open one); a desk that can't start is a note and the plain notification, exit 0. `--list`, `--close <run>\|--all`, `--gc` (from `harness gc`: idle for 24 h) |
| `prompts/desk.md` | ~80 | The desk's instructions (a run block and a debrief block): read `harness parked`/status/INBOX/progress, check safely, one numbered brief, `harness answer` and the continue only after Michael's yes, the never-list |
| `skills/harness-answer/SKILL.md` | ~45 | The answer desk's instructions for an interactive session Michael opens (§17); installed by a symlink into `~/.claude/skills/` |
| `templates/user/config.sh` | ~15 | The documented `~/.config/harness/config.sh` (every line commented) |
| `templates/user/{settings.permissions.json,CLAUDE.md,config.merge-policy.sh}` | | The permissions policy (`decisions/2026-10-24-permissions-policy`): the user settings, the `~/.claude/CLAUDE.md` section that is its one home, and `MERGE_POLICY=auto` |
| `setup/apply-2026-10-24.sh` | ~110 | Installs those three (`--dry-run` shows every diff; backs up to `~/projects/backups/`) and moves the n8n MCP servers to n8n-home's `.mcp.json`; Michael runs it, the harness never does |
| `prompts/*.md` | | initializer, coding, verify, retro, debrief, supervisor, draft-claude-md, desk; `policy/{build-only,live-staged}.md`; `parts/run.md` (*This run*) and `parts/rules.md` (the line naming `CLAUDE.md`) |
| `tests/run.sh` + stubs | | End-to-end with stub `claude`, `gh` and `curl` on a throwaway repo with a bare origin, desks on a private tmux server: 226 checks |

## 4. Where state lives

| What | Path | Written by | Read by | Committed? |
|---|---|---|---|---|
| Feature list | `<wt>/.harness/runs/<run>/feature_list.json` | initializer; sessions (own `passes` only); verifier (un-pass only); driver (repair, un-pass) | everyone | yes, run branch |
| Session entry | `…/entry.json` (the run directory, transient) | each session, once, at the end | driver (`entries.mjs ingest`), which validates, stamps `at`/`session`/`model`, appends to `entries.jsonl` and deletes it; a missing or invalid one becomes a minimal entry built from git, with a note | no (removed on ingest) |
| Journal | `…/entries.jsonl` (one line per session: feature, outcome, what changed, evidence, dead ends, discoveries) | driver only (`ingest`) | `render`, `pack`, retro, evals | yes |
| Context pack | `…/context.md` (at most `CONTEXT_PACK_BYTES`; five parts in priority order: this feature's earlier attempts, dead ends, failed verify rows and questions; Michael's answers; discoveries that name it, its milestone or the run; the latest entry of each feature in its `after`; the last 3 entries; each item ends `→ entries.jsonl:<line>`); a copy in `logs/*.context.md` | driver (`entries.mjs pack`) before every coding and verify session, committed `HARNESS: context pack for <id>` | the session, first (prompts say `Read context.md first`); `eval probes` | yes |
| Progress log | `…/progress.md` (newest first: 15 in full, then one line each) and `…/progress-archive.md` (every entry in full; a continued legacy run's old progress.md at its end) | driver (`entries.mjs render` after every journal append, decisions/2026-10-22-rendered-progress); a legacy run's sessions until it is continued | sessions, Michael (phone), retro, PR bodies (the archive), verify's `F evidence` | yes |
| Steering | `…/INBOX.md` (`status: run/pause/stop`, `## Answers`) | Michael (GitHub app), `harness answer` via the driver | driver, sessions | yes |
| Brief | `…/brief.md` | driver, from `--brief` at start/continue | every prompt | yes |
| Driver events | `…/harness-log.md` | driver (`note`) | Michael, summary, retro | yes |
| Metrics | `…/metrics.jsonl` (one row per session: kind, role, model, cost, wall/api seconds, turns, `tokens_in cache_read cache_write tokens_out cache_hit_rate context_peak`, `orient_tokens orient_turns orient_s`, exit, result, `mem_peak_mb`) | driver (`metrics.mjs append`) | summary, report (memory peaks) | yes |
| Summary / writeup / retro | `…/summary.json`, `report.md`, `retro.md` | driver at the end; `harness report` rebuilds `summary.json` into the state dir with a copy of `metrics.jsonl` beside it | Michael, ledger | yes |
| Scopes | transient systemd user units, not files: `harness-<run>-s<n>.scope` per session, `harness-<run>-check-<pid>.scope` per suite, `harness-<run>-svc.scope` for what the init starts (§7; `systemctl --user list-units 'harness-*'`). **Nothing of a scope persists**: `--collect` unloads it once empty, and the driver and `check.sh` stop it when their command returns (the svc scope lives on while the init's servers do, until the next `run_init` stops it). What stays is the record: `state/scope-seq` (the last `<n>`, so a resumed segment never reuses a name), the wrapper's `<scratch>/scopes/<unit>.{started,show}` (`MemoryPeak`, `TasksCurrent` at exit; scratch), `mem_peak_mb` in `metrics.jsonl` and the cap/leftover notes in `harness-log.md` | `systemd-run` via `scope_run`; driver, `check.sh` | driver (`scope_peak`, `scope_left`, `scope_capped`) | no |
| Driver log | `~/.local/state/harness/<p>/<run>/run.log` | driver (`log`) | status, summary (wall times) | no |
| Transcripts | `…/logs/NN-<id>.jsonl`, `HHMMSS-verify-<m>.jsonl`, `00-init.jsonl`, `zz-retro-*.jsonl`, each with its prompt beside it (`*.prompt.md`) | `claude --output-format stream-json`; the driver copies the prompt | metrics, retro, you (`jq`) | no |
| Harness version | `~/.local/state/harness/<p>/<run>/{harness-version,harness-dirty}` (last harness commit outside `ledger/`, and whether the tree has changes outside it; `lib/version.sh`; rewritten each segment, shown on the `run <id> on` line, copied into `summary.json` and the ledger row) | driver | summary, `harness trends --by version` | no |
| Attempts | `…/attempts.json` | driver (bump, unbump, grant, reset) | scheduler | no |
| Parked features | `…/parked.json` (`id → {answers, why, at}`; `answers` = hash of INBOX.md from `## Answers` on) | driver (park after a `PARKED:` session; unpark when the hash changes) | scheduler, summary, `harness parked` | no |
| Markers | `…/{driver.pid, ended, PAUSE, STOP, verified-<m>, merged-<m>, proposed-<m>, nomerge-<m>, verify-rounds-<m>, tests-start, tests-end, waited-<t>, port, meta.env, run.env, brief.md, inbox.md}` | driver, CLI | driver, CLI, summary | no |
| Shared limit window | `~/.local/state/harness/LIMIT_UNTIL` (epoch) | any driver hitting a limit | every driver, the queue runner, status | no |
| 7-day window | `~/.local/state/harness/USAGE_7D` (`<utilization 0..1> <reset epoch>`, from the newest session's rate-limit event) | every session (driver) | every driver, the queue runner (`weekly_over`) | no |
| Queue | `~/.local/state/harness/queue/NNNN-<verb>-<name>.args`, `held/` (parked entries and their `.why`), `done/`, `runner.log`, `runner.pid`, `STOP`, `last-debrief` (when the last note was produced, and the "since" of the next), `debrief.out` | CLI, driver (continuations), debrief | runner, debrief | no |
| Debrief workspace | `~/.local/state/harness/debrief/<stamp>/{context.md,prompt.md,session.jsonl,final.md,body.md}`, `debrief.lock` | `harness debrief` | you (`--dry-run` prints `context.md`) | no |
| Debrief note and page | `<harness>/ledger/debrief.md` and `debrief.html`, overwritten each time (history: `git log -p`) · `<state>/runners` marks the runs a queue runner started | `harness debrief` (flock, `git commit -- <note>` when `LEDGER_COMMIT=1`) · `harness start` | Michael, the next interactive session | yes, harness repo |
| Desk | `~/.local/state/harness/<p>/<run>/desk/{<stamp>.md,url,last-event}` (the prompt per event, the session URL while the desk is open, the epoch of its last event) · the debrief's in `queue/desk/` · `desk.lock` (one desk start at a time) · tmux session `h-desk`, a window per run and `debrief` | `harness desk` (the driver, the debrief, you) | `harness desk` (reuse, `--list`), `harness gc` (24 h idle) | no |
| Eval results | `<harness>/evals/results/<stamp>-<sha>-<label>/<task>[/r<N>]/{summary.json,commits.json,probe-prompt.md,probes.json,…}` (git-ignored) | `harness eval run`, `eval probes` | `eval compare`, Michael | no |
| Eval workspace | `/tmp/harness-eval/<stamp>/{harness,<task clones>}` (the ref's worktree, a clone per task sealed at `base`: only `main`, no source tag or later object; a private state dir) | `harness eval run` (`harness` removed at the end and by an EXIT trap; the clones and run worktrees stay for `eval probes`) | `harness eval run`, `eval probes`, Michael (`rm -rf`) | no |
| Scratch | `/tmp/harness/<p>/<run>/` (`init.out`, `teardown.out`, `check.out`, `check-<key>.out`, `green-<key>`, dev DB, screenshots) | driver, init, check, sessions | sessions, driver | no |
| Live-write lock | `LIVE_LOCK` (default `/tmp/harness/<p>/live.lock`; dj: `/srv/docker/crates/live.lock`, shared with the backup job) | sessions under `live-staged` (`flock -n`), the backup script (`flock -w`) | both | no |
| Ledger | `<harness>/ledger/runs.jsonl`, `ledger/<p>/<run>/{summary.json,retro.md,…}` | driver at the end (flock, `git commit -- <paths>`) | `harness trends`, retro, calibration | yes, harness repo |

## 5. The life of a run

```
harness start ─► worktree + branch ─► driver:
  [resume?] merge main in before any session, the initializer included (and reload the config if it changed) · merge verified (v3) milestones
  [no list] init + suite ─► INITIALIZER ─► feature_list.json, entry.json ─► entries.jsonl ─► progress.md (rendered)
  loop:
    stop if: session cap · deadline · STOP/"status: stop"
    pause while: PAUSE/"status: pause"
    unpark every feature parked under different INBOX answers
    wait while: LIMIT_UNTIL is in the future (any run set it)
    verify every complete, unverified milestone (in order) ─► see below; a refused verify waits for the window
    stop if: the 7-day window (USAGE_7D) is past WEEKLY_STOP_AT → "weekly budget (…)"
    next = first feature: not passing, not parked, attempts < MAX_ATTEMPTS, every dependency passing
      none → "done" (all pass) | "blocked on X" (a given-up feature) and/or "waiting on Michael: Y" (parked)
             | "no feature left to try"
    init + suite (cached) ─► context.md (pack for this feature) ─► CODING SESSION (one feature) ─► commit leftovers
      ingest entry.json ─► entries.jsonl ─► render progress.md + progress-archive.md (after every session, verify included)
      environmental? (limit, API error, $0 one-turn) → keep its commits, revert its claims (the list, "passes"
        included), give the attempt back, set LIMIT_UNTIL; MAX_LIMIT_HITS in a row → end "usage limit"
      repair the list (only its own passes may change) · un-pass if the suite is red · metrics · push
      not passing and the final message says "PARKED: <why>" → attempt given back, parked until the answers change
  VERIFY m: merge main in → context.md → session (its code edits are reverted) → refused? deferred, no verdict
      → a new entry with one evidence row per step? no → one re-run on the stronger model → still no → not verified
      → suite green on that tree? → tag run/<run>/<m> (v3) → merge_milestones (PR per milestone, in order)
      a step fails → one more attempt for the feature, then "needs Michael"
  finish: merge what's verified · tests-end · services down · summary.json · report.md, pushed · notify · RETRO ·
          report.md again · ledger · queue a continuation
  EXIT trap (every exit, a TERM included): stop the running session's scope · services down · write ended · rm driver.pid
  services down <why>: .harness/teardown.sh (TEARDOWN_CMD) · stop harness-<run>-svc · note "services stopped (<why>)";
          once per started init, silent when this segment ran none
```

**End reasons** (written to `state/ended`, shown by `harness status`, recorded in the summary):

| Reason | Meaning | What happens next |
|---|---|---|
| `done` | every feature passes | nothing; `harness gc` cleans up once milestones are merged |
| `blocked on X` | X was given up and the rest depend on it | needs Michael: read X's progress entries, answer in INBOX.md, `harness continue` |
| `waiting on Michael: Y` | Y is parked (its session said `PARKED:`) and what's left depends on it (may follow `blocked on X; `) | answer in INBOX.md (phone or `harness answer`), then `harness continue`: changed answers unpark it |
| `no feature left to try` | everything left is given up (no dependency chain) | needs Michael |
| `weekly budget (…)` | the plan's 7-day window passed `WEEKLY_STOP_AT` | nothing automatic; the queue won't start runs either until the window resets |
| `session cap (N)` | the session budget is spent | a continuation is queued (`AUTO_CONTINUE=1`, at most `AUTO_CONTINUE_MAX`=3, within the run's `--until`, given-up features stay given up) |
| `deadline`, `deadline (paused)` | the run's time (`HOURS` or `--until`) is up | nothing automatic: time is your budget. `harness continue` or queue it for another night |
| `usage limit (N sessions refused in a row)` | the plan refused `MAX_LIMIT_HITS` sessions in a row | the run ends so the queue isn't blocked; `harness continue` later |
| `stopped by Michael` | STOP or `status: stop` | `harness continue` when you want |
| `feature-list edits` | MAX_REPAIRS sessions in a row edited the list | a prompt/model problem: look before continuing |
| `initializer failed` / `usage limit before the feature list` | no valid list | fix and `harness continue` (it re-runs the initializer) |
| `driver exited unexpectedly` | the trap fired without a reason (crash, kill) | the trap stopped the session's scope and the services first (`services stopped (driver exited)` in `run.log`; not after a SIGKILL); `harness continue` resumes safely: everything is on disk |

## 6. The feature-list contract

```json
{ "id": "T1-03", "milestone": "T1", "kind": "build", "model": "opus",
  "description": "observable behaviour", "steps": ["verifiable check", "…", "the suite is green"],
  "after": ["T1-02"], "passes": false }
```

- **Order** is priority. **Dependencies**: `after` if present, else *every earlier feature*. So by default one failure
  blocks everything behind it (safe), and the initializer opts independent work out with `after`. `after` may name
  feature ids or milestone ids (every feature of that milestone before this one). The initializer must give the
  first feature of every milestone after the first an `after` (`[]` if independent); the driver notes once per run
  which milestones lack one (D-H25).
- **Parked** (D-H26): a session that can't go on without Michael ends with `PARKED: <why>`. The feature is skipped
  like a given-up one (only its dependants wait) without spending an attempt, until INBOX.md's answers change.
- **kind** ∈ plan · build · review · check · docs. It drives cost-by-role and nothing else (inferred for v2 lists).
- **model**: alias (`fable`, `opus`, `sonnet`, `haiku`) or a full `claude-…` id.
- **Write rules**, enforced by `features.mjs repair` after every session: a coding session may change only its own
  feature's `passes`; a verify session may only turn its milestone's `passes` true → false. Anything else (text, steps,
  order, additions, removals) is reverted from the pre-session snapshot and logged; 3 sessions in a row → stop.
- There is deliberately **no way for an agent to add features mid-run**. New work comes from Michael: a brief on
  `continue` (the next initializer-less sessions read it), or a new run.

## 7. Guards

| Guard | Trigger | Action | Where |
|---|---|---|---|
| Edit repair | list differs from the snapshot beyond the allowed flip | revert, log; stop after `MAX_REPAIRS` in a row | `features.mjs repair`, driver loop |
| Red suite | a session flips `passes` but `check.sh` fails | un-pass, log | driver loop |
| Attempts | `MAX_ATTEMPTS` real sessions without passing | given up → dependants blocked | `features.mjs schedule` |
| Environmental session | the session's **final** result has `api_error` / `api_error_status ≥ 429` / `terminal_reason: api_error`; regex fallback; `$0` and ≤ 1 turn; no result within 120 s | commits kept, claims reverted (list back to the snapshot), attempt given back; `LIMIT_UNTIL` = rejected window's `resetsAt` + 2 min (else 15/30/60 min); the run ends after `MAX_LIMIT_HITS` in a row | `metrics.mjs environmental`, driver |
| Timeout | `SESSION_TIMEOUT` (exit 124; 137 when `timeout -k 30s` had to KILL) | counts as a real attempt (the feature is too big) | `metrics.mjs` |
| Session scope | every session (init, coding, verify, retro) runs as `timeout -k 30s $SESSION_TIMEOUT claude …` inside the transient user scope `harness-<run>-s<n>` (`<n>` from `state/scope-seq`, never reused in a run) with `MemoryHigh=SESSION_MEMORY_HIGH` (5G), `MemoryMax=SESSION_MEMORY_MAX` (6G), `MemorySwapMax=SESSION_SWAP_MAX` (1G), `OOMPolicy=continue` | the scope is stopped when claude returns (what it backgrounded goes with it: note `<kind> session left <n> process(es) running; stopped with its scope`); the cap reached → the kernel kills at it, exit 137, note `<who>: the session hit its memory cap (6G)`, the attempt is the feature's; no user systemd → one note per segment, `no user systemd: sessions and suites run uncapped`, and sessions run bare; systemd refusing one scope after the probe passed (a `MemoryMax` it can't parse, the bus gone) → that session runs bare, note `<kind> session ran uncapped: systemd-run failed (exit <rc>)` (`SCOPE_BARE`; systemd's error is in the transcript) | `session()`, `lib/scope.sh`, `metrics.mjs environmental` |
| Suite scope | every `check.sh` run (the driver's and a session's, full or subset) runs as `timeout -k 30s $CHECK_TIMEOUT bash -c <CHECK_CMD>` inside the transient user scope `harness-<run>-check-<pid>` with `MemoryMax=CHECK_MEMORY_MAX` (3G), `MemorySwapMax` 1G, `OOMPolicy=continue`, no `MemoryHigh` | the scope is stopped after the suite returns; exit 124, or 137 after the whole `CHECK_TIMEOUT` (timeout had to KILL) → `check: RED (timed out after 15m, exit <rc> after <n> s)`; a 137 whose scope peaked at the cap (`scope_capped`) → `check: RED (killed at its 3G memory cap, exit 137 after <n> s)`; both are red like any failure (a subset prints only these lines after its own output); a TERM, INT or HUP to `check.sh` (the calling session's scope stopped, a Ctrl-C) stops the check scope too (the suite runs in the background of a trapped `wait`); no prefix or no user systemd → bare, under the same timeout | `lib/check.sh`, `lib/scope.sh` |
| Services scope | every `run_init` (before the initializer, each coding session and each verify) first stops `harness-<run>-svc` (systemd refuses a unit name still loaded), then runs `timeout -k 10s $INIT_TIMEOUT bash -c <INIT_CMD>` (10m) inside it with `MemoryMax=SVC_MEMORY_MAX` (3G), `MemorySwapMax` 1G, `OOMPolicy=continue`, no `MemoryHigh` | the init's stdin is `/dev/null`; once the init returns, what it backgrounded (a dev server) stays in the scope, capped, until the next `run_init` stops it; an init that times out takes its whole process group with it (servers it had started included); `(init exit <rc>)` in `init.out` as before; systemd refusing the unit after a good probe → bare, with the note `init ran uncapped: <why>`; no user systemd → bare and silent (the run's one `no user systemd` note) (decisions/2026-10-25-services-scope) | `run_init` in `lib/driver.sh`, `lib/scope.sh` |
| Services teardown | `finish` (after the last suite run, before the summary: `services stopped (<reason>)`) and the driver's EXIT trap (`services stopped (driver exited)`), when this segment ran an init (`SVC_UP`) | `services_down <why>`: the project's `TEARDOWN_CMD` (default `.harness/teardown.sh` when executable) in the worktree under `timeout -k 10s 2m`, stdin `/dev/null`, with `HARNESS_PORT`, `HARNESS_SCRATCH`, `HARNESS_RUN_ID`, `HARNESS_TEARDOWN_WHY=<why>`, output appended to `teardown.out` in scratch; then `scope_stop harness-<run>-svc`; one note per started init (finish's call clears `SVC_UP`, so the trap after it is silent); a failing hook is in the note (`teardown exit <rc>, see …`), never fatal. The trap ignores further TERM/INT/HUP, then first stops the running session's scope (`S_UNIT`): bash runs it at once on a TERM while `claude` would live on (a bare session, without user systemd, does live on to its timeout). The memory gate stops the services too, so `verify()` re-runs the init after a wait (`mem_gate || run_init`) (decisions/2026-10-25-teardown-hook) | `services_down`, the trap and `session()` in `lib/driver.sh` |
| Memory gate | before every init, coding and verify session (not the retro), `MemAvailable` (`${HARNESS_MEMINFO:-/proc/meminfo}`) under `MEM_MIN_AVAILABLE_GB` (5) | note `memory: <n> GB available, under MEM_MIN_AVAILABLE_GB=5; waiting up to 30m`, `services_down memory` (a no-op until L2), then poll every 5 minutes (`HARNESS_MEM_POLL` s) up to `MEM_WAIT_MAX` (30m): back over it → `memory: <n> GB available after <s> s; starting the session`; still under → `memory still at <n> GB after 30m; starting the session anyway (its cap protects the box)`. The wait is not the session's wall time; an unreadable meminfo is no gate. The gate runs where the session is decided, not in `session()`: for a coding session after the feature is picked and before its attempt is bumped and its prompt (with the clock) rendered, and after a wait the loop starts over (deadline, `status: stop`/pause, the pick) with the gate skipped once; for a verify round before its prompt; for the initializer before `init` (decisions/2026-10-25-memory-gate) | `mem_gate` in `lib/scope.sh` (exit 1 after a wait), the driver loop, `verify()` |
| Verify | milestone complete | independent session; must write a **new** entry with ≥ one row per step, else one re-run on `VERIFY_ESCALATE_MODEL`, else not verified ("needs Michael"); refused by a limit → deferred, never "holds"; suite must be green on the verified tree; a step fails → one more attempt, then "needs Michael" (`MAX_VERIFY_ROUNDS`) | `verify()`, `verify_ready()` |
| Read-only sessions | a verify session changes code, a retro changes anything | reverted by a new commit (`restrict`), logged | `restrict()` |
| Journal writer | a session edits `entries.jsonl` or `progress-archive.md` | restored from the session's start commit before its entry is appended, note `<id>: <file> edited by the session; restored`; readers skip any line that isn't a valid entry and keep line numbers | `journal()`, `entries.mjs readEntries` |
| Merge order | a later milestone is verified before an earlier one | not merged until the earlier one is (its tag contains the earlier commits) | `merge_milestones` |
| Tainted tag | a milestone's tag contains commits of features in milestones not yet verified (possible with `after`) | held; it is merged by the next verified milestone's merge, which contains it | `tainted-<m>`, `merge_milestones` |
| Verified tree | the merge of the tag into `main` wouldn't produce exactly the tag's tree (main has content it wasn't verified with) | held (the next milestone's verify merges main in first); conflict → "needs Michael" | `merge_one` |
| v2 tags | a tag verified by harness v2 (no "(v3)" in its message) | never merged automatically; `harness merge <run>` merges it (and closes the v2 whole-run PR) | `merge_milestones` |
| Main drift | `main` moved during the run | merged into the run branch before every verify (conflict → that milestone isn't merged) | `sync_main` |
| Session budget | `--max-budget-usd`, `--max-turns` per session | the CLI stops the session | `session()` |
| Weekly budget | the newest session reported the 7-day window ≥ `WEEKLY_STOP_AT` (default 85 %, 0 = off) | the run ends before its next coding session; the queue starts no run | `weekly_over` (config.sh), driver loop, queue.sh |
| Parking | a not-passing session's final message has a `PARKED:` line | attempt given back; skipped until the INBOX answers change | driver loop, `features.mjs park/unpark` |
| Desk | `DESK=1` and a park, a blocked or waiting run end, verify or a merge needing Michael | a desk failing to start never stops or fails the run: `desk()` drops the output, notes a non-zero exit and returns 0; `desk.sh` itself exits 0 with a note and the plain notification when there is no tmux, no URL in time, or the lock is held | `desk()` (driver), `plain()` (desk.sh) |

## 8. Branches, tags and PRs — and what `run/*/final` was

| Ref | Created by | Lifetime | Meaning |
|---|---|---|---|
| `harness/<run>` | `harness start` | until `harness gc` | everything the run did, verified or not, plus its run record |
| `run/<run>/<m>` (annotated tag) | driver, after verify holds | permanent | "this commit is milestone `<m>` verified": the exact merge point |
| `harness-merge/<run>-<m>` | driver, `merge_one` | deleted after the merge | a branch at the tag commit, so the PR contains exactly that prefix of the run |
| PR "`<run>: <m> (verified)`" | driver | merged by the driver (`auto`) or left for you (`pr`, the default) | the audit record: features, verify evidence table, cost so far |

**Why merge "to the T3 tag".** A run branch is linear: T0's commits, then T1's, T3's, then T4's. A tag marks a point
on that line. Merging the T3 tag merges T0+T1+T3 and nothing after, so the unreviewed T4 commits stay on the
branch. v3 does this itself for every verified milestone, in order. The ordering rule ("stop at the first unverified
milestone") exists because merging a later tag would carry every earlier commit, verified or not.

**`run/<run>/final`.** In v2, the end of every run called `propose final`, which **tagged the branch head as
`run/<run>/final` with the message "final verified"**, whatever had been verified, and refreshed the whole-run PR.
On 10-17 that labelled 16 unverified Pathways features and 14 unbuilt dj features as "final verified". The two tags
(`run/threads-2026-10-17/final`, `run/dj-2026-10-17/final`) point at bookkeeping commits and nothing uses them.
v3 has no `final` tag: the end of a run is a summary, not a verification. Delete them when convenient (agents may not
delete tags):
`git push origin :refs/tags/run/threads-2026-10-17/final && git tag -d run/threads-2026-10-17/final` (same for dj).

**v2 whole-run PRs** (pathways#4, dj-crate-streaming#3) are closed with an explanatory comment by `harness merge
<run>`, which is also the only way their v2-verified milestones reach `main` (an explicit decision, because v2's
verify was weaker). A plain resume leaves both alone.

**The merge invariant.** A merge happens only when `git merge-tree origin/main <tag>` produces *exactly the tag's
tree*: what lands on main is byte-for-byte what was verified. Merging an earlier milestone through a PR adds a merge
commit to main but no content, so the next tag still satisfies it. Anything else is held until a later verify has
seen it.

## 9. Partial runs: the pattern

A run ends partial for one of three reasons, and each has one answer:

| Why it's partial | What's already done | What the harness does | What you do |
|---|---|---|---|
| Out of sessions | verified milestones are already **in main** | queues a continuation (same branch, main merged in first; given-up features stay given up) | nothing, if a queue runner is going; else `harness queue start` |
| Out of time, or the plan refused 6 sessions in a row | same | nothing automatic | `harness continue <run>` or `harness queue add --continue <run>` |
| Blocked: a feature was given up | same | ends with "blocked on X" and notifies; nothing is queued | read X's last progress entry; answer in INBOX.md or give a `--brief`; `harness continue <run>` |
| Verify failed twice, or a merge was refused/conflicted | verified milestones before it are in main | "needs Michael" note + notification; later milestones wait | fix or answer; `harness continue` (or `harness merge` once a refused merge is fixed) |

So "merge as-is" and "run again" stop being choices: **verified milestones are merged as they happen; everything
else continues.** Unverified work is never merged and never thrown away.

## 10. Configuration

Layers, later wins (`lib/config.sh`): harness defaults → `~/.config/harness/config.sh` (yours: models, limits,
`MERGE_POLICY`, `CONTEXT_PACK_BYTES`, `MAX_PARALLEL_RUNS`, `NOTIFY_CMD`, `NTFY_URL`, `NTFY_TOKEN`, `DESK_URL`, `DESK`, `DESK_MODEL`) → `<project>/.harness/config.sh` (`POLICY=` and real overrides) →
the run's options (`--spec`, `--until`; in `state/run.env`) → **conventions** for what's still unset:

| Setting | Convention |
|---|---|
| `MERGE_POLICY` | `pr` (default): a verified milestone opens its PR and waits for you. `auto`: the driver also merges each one (`gh pr merge --match-head-commit`, so the verified tree lands); Michael's user config sets it (`decisions/2026-10-24-permissions-policy`), and a project whose `main` reaches production without a gate sets `pr` in `<project>/.harness/config.sh` (portfolio_site, n8n-home). `off`: no PR. `harness merge <run>` lands verified milestones under `auto` or `pr`, and does nothing under `off` |
| `NTFY_URL` / `NTFY_TOKEN` | empty: notifications go to `NOTIFY_CMD` (or nowhere). Set: the harness posts to that ntfy topic itself, the token as `Authorization: Bearer` (never logged), and `NOTIFY_CMD` is not called |
| `DESK_URL` | empty: no **Answer with Claude** action on a park's notification |
| `DESK` / `DESK_MODEL` | `0` / `opus`: no desk starts by itself (`harness desk` by hand still works). `DESK=1`: the driver and the debrief start one whenever a run needs Michael (§17), on `DESK_MODEL` |
| `SESSION_MEMORY_HIGH` / `SESSION_MEMORY_MAX` / `SESSION_SWAP_MAX` | `5G` / `6G` / `1G`: each session's scope (§7): throttled above the first, killed at the second, at most the third in swap |
| `CHECK_MEMORY_MAX` / `CHECK_TIMEOUT` | `3G` / `15m`: each `check.sh` run's scope (§7): killed at the first, TERM after the second and KILL 30 s later; `check.sh` reads them as `HARNESS_CHECK_MEMORY_MAX` / `HARNESS_CHECK_TIMEOUT` |
| `INIT_TIMEOUT` / `SVC_MEMORY_MAX` | `10m` / `3G`: `run_init`'s `timeout -k 10s` around the init's foreground, and the `MemoryMax` of the services scope `harness-<run>-svc` its servers stay in (§7) |
| `TEARDOWN_CMD` | `.harness/teardown.sh` when that file is executable in the worktree, else empty: run by `services_down` under `timeout 2m` before the services scope stops (§7; template `templates/project/teardown.sh`) |
| `MEM_MIN_AVAILABLE_GB` / `MEM_WAIT_MAX` | `5` / `30m`: the memory gate before each session (§7): under the first (whole GB of `MemAvailable`) the driver waits up to the second, then starts the session anyway |
| `CONTEXT_PACK_BYTES` | `8192`: the cap on `context.md`; lower-priority items are cut whole, counted in `_<k> items left out_`. The CLI refuses a value that isn't a whole number ≥ 1024, and the driver then points the session at the full record |
| `CHECK_CMD` | `.harness/check.sh` · `npm run check` · `npm test` · `python3 -m pytest -q` · `cargo test` · `go test ./...` · `make test` |
| `SMOKE_CMD` | `node .harness/smoke.mjs` · `bash .harness/smoke.sh` · `true` |
| `INIT_CMD` | `.harness/init.sh` · `true` (the driver runs the suite itself, so init only starts servers) |
| port | first free from `BASE_PORT` (7800) |
| run id | `<project>-<date>[-n]` |

**What a project provides**: `CLAUDE.md` (durable rules; read by interactive sessions too, and loaded by Claude Code
in every session, which runs in the worktree; the prompt names it once), one `POLICY=` line, and only the scripts that
are truly its own (a sandboxed `check.sh`, a dev-server `init.sh`, a `smoke.mjs`).
A project deployed by a Git-connected host that builds every branch (Vercel, Netlify)
disables run-branch deploys on `main`: `harness init` writes the guard (`vercel.json` `git.deploymentEnabled`
`"harness/**": false`; a `netlify.toml` `[build] ignore` that exits 0 for `harness/*`), and a run start without it on
`origin/main` notes it and notifies once (`lib/deploy.sh`; milestone PR heads `harness-merge/*` still get a preview).
**What a run provides**: `--spec` files and a `--brief` (scope for this run only).

**Prompt assembly** (`prompt()` → `prompt_render` → `render.mjs`, decisions/2026-10-21-static-first-prompts), in
this order: (1) the static part of `prompts/<kind>.md`: a fixed first line (`# Coding session`, `# Verify session` or
`# Initializer session`), then the role, rules and finish, with no placeholders; (2) at its `{{SECTIONS}}` line the
policy (`prompts/policy/<POLICY>.md`); (3) the run-level parts: *This run* (`prompts/parts/run.md`: run id,
worktree, branch, run directory, port, scratch, suite, init, smoke, spec), "Brief for this run" (pasted as written,
so a `{{X}}` in it stays text), `prompts/parts/rules.md` (one line naming `CLAUDE.md`, which Claude Code loads
itself, when the worktree has one; decisions/2026-10-21-no-double-claude-md) and legacy `.harness/project.md` if
present; (4) the template's *This session* part: `` Feature: `<id>` `` / `Milestone: <m>` (coding), `Milestone:` /
`Features:` (verify) or `Earlier runs' feature sizes:` (initializer), the clock line, the init output. Sections are
one blank line apart. Two sessions of a run share every byte up to *This session*. The clock line (`{{CLOCK}}`,
driver `clock`, coding and verify only; decisions/2026-10-21-clock-and-bounded-init-output) is `Clock: <now> · run
<elapsed> of <total>, ends <HH:MM> · this session: $<budget> budget, <turns> turns, <timeout> timeout · attempt N of
MAX_ATTEMPTS` (or `verify round N of MAX_VERIFY_ROUNDS`); the run is this driver's segment, `T0` to `DEADLINE`. A
probe rendered by `lib/prompt.sh` says it is outside a run. The retro (`# Retro`, its run on line 3) gets the
template and the rules line. `{{INIT_OUTPUT}}` is the last 40 lines of `$SCRATCH/init.out` (init and suite output)
and then `full output: <path>`. The coding and verify templates open their bearings with `Read context.md first` (the pack in the run directory, written by the driver just before the session, §4), so it is not pasted into the prompt. Each session's prompt is kept beside its transcript (`logs/*.prompt.md`).

**Policies**: `build-only` (default: never operate anything live; write live steps down) and `live-staged` (operate
live through the protocol: preflight, stages, stop-and-revert, one writer via `flock`, deploy only from the run's
worktree; the project's `## Live system` section supplies the commands). A policy is text the agent follows **and**
what the permission rules allow; the harness owns the first, Michael the second.

**Permissions.** Headless sessions run in auto mode under your user settings (`~/.claude/settings.json`, where the
history-destroying denies live). A project may add `.claude/settings.json` (passed with `--settings`, because a fresh
worktree is untrusted). The harness never writes either, and agents can't (the auto-mode classifier blocks
"Self-Modification"). The driver logs which applied at start. What agents may do (merge, push, delete merged branches
and worktrees, `docker compose`) and the closed deny list live in `~/.claude/CLAUDE.md` § "Git, merges and
permissions" and the user settings, installed from `templates/user/` by `setup/apply-2026-10-24.sh`. A project file
holds only its own gates and the narrow allows its runs need (portfolio_site's deploy gate, n8n-home's and
dj-crate-streaming's live protocols, rane-one-mixxx's hardware); the others have none.

## 11. Measurement and the improvement loop

1. **Per session**: `metrics.jsonl` row: kind, role, model, cost (max of cumulative results), wall time (driver),
   API time and turns (summed over result events), **tokens** (in, out, cache read/write; `cache_hit_rate`),
   `context_peak`, **orientation** (`orient_tokens/turns/s`: requests up to and including the first edit), exit, `env`, final text,
   and **`mem_peak_mb`**: the session scope's `MemoryPeak` in MB, null when it ran uncapped
   (`decisions/2026-10-25-session-memory-peaks`).
2. **Per run**: `summary.json` (features, milestones verified/merged, tests start→end, cost by role and model, time
   by role, **tokens**, cost and tokens per verified feature, median orientation, first-attempt pass rate, rework, verify-fail rate, `harness` version and dirty flag, sessions real/refused, guard counts, every non-passing feature with an automatic cause), `report.md`
   (the writeup: `harness report <run>`; its `Memory peaks over 2 GB` section lists `<feature> · <model> · <peak> MB`
   per session over 2048 MB, read from the `metrics.jsonl` beside `summary.json`, which carries no peak), and `retro.md` (a Sonnet session classifies "not done" features into
   spec / size / dependency / permission / environment / model / harness causes and proposes ≤ 3 harness changes,
   noting repeats from earlier retros).
3. **Across runs**: `ledger/runs.jsonl` + `harness trends` ($ per feature, causes, end reasons over time);
   `harness trends --by version` groups runs by the harness version that ran them, to compare a change before and after.
4. **Back into runs**: the initializer gets a calibration line from the ledger (median and p90 minutes per passing
   feature, this project and all) to size features against reality.
5. **Into the harness**: you read the retros/trends (or ask a session to), turn a repeated proposal into a decision
   (a file in `journal/decisions/`), implement it test-first, and **turn the failing transcript into a stub fixture** (as
   `tests/fixtures/usage-limit.jsonl` was), so the fake never drifts from the real API again.
6. **Replay evals**: `evals/tasks/*` are real past features with their `base` commit; `harness eval run` replays a set
   with a chosen harness ref's own driver, on clones with no real remote, config, state or notification, sealed at `base`
   (`decisions/2026-10-21-eval-run-isolation`, `decisions/2026-10-21-eval-clone-sealed-at-base`), capped by
   `EVAL_BUDGET_USD` and the 7-day window (`decisions/2026-10-21-eval-budget-window-repeat`). `harness eval compare` sets
   two results side by side; a verdict is "within noise" inside the spread of `--repeat` runs, "one sample" without
   (`decisions/2026-10-21-eval-compare-verdicts`); per verified feature is pooled over every repeat
   (`decisions/2026-10-21-eval-per-verified-pooled`). `harness eval probes` asks one tool-less Haiku turn what a task's
   handoff should answer, scored by match (`decisions/2026-10-21-eval-probes`). Evals cost money and are Michael's to run
   (`evals/NEXT.md`); D-H35.

## 12. Queue and parallelism

`MAX_PARALLEL_RUNS` (user config, default 1) bounds live drivers. `harness start` beyond it **queues** the run (its
id is chosen when it starts) and ensures the runner (tmux `h-queue`); `--now` bypasses. A queued continuation is
skipped if you stopped the run; `harness continue` refuses a run whose driver is alive. `harness queue add …` queues without starting;
`harness queue start --until 07:30` runs the queue and gives every run it starts that deadline. The runner never
starts a run while `LIMIT_UNTIL` is in the future, and starts **one run per project at a time**: an entry whose
project has a live driver is held in its place (logged once, `holding <entry> (<project>)`) and the next entry for a
free project starts instead (`decisions/2026-10-21-queue-one-run-per-project`); `harness start --now` still bypasses. With 1, nights are serial: each run gets
the whole plan window.
The runner exits when the queue is empty and nothing it started runs, when it is past `--until` with nothing running,
or on `harness queue stop`; whichever, if it started at least one run (marked in `<state>/runners`), it then starts
`harness debrief` once, detached with `setsid`, so a new runner replacing tmux `h-queue` can't kill it (§16).

**Parked entries** (`harness queue park <n> [<why>]`) move to `queue/held/` with a `.why` file: the runner skips them
and says how many at start-up, `harness queue list` shows each with its reason, and `unpark <n>` puts one back at the
end of the queue, renumbered.

**Live sync** (`lib/sync.sh`, `LIVE_SYNC=1`): before each start with **no driver alive**, the runner levels the
checkout that holds the ledger (the live harness) with origin: it fetches, rebases the driver's unpushed ledger
commits onto `origin/main` and pushes them (never forced), or fast-forwards. It acts only on `MAIN_BRANCH` with no
rebase/merge going, no modified tracked file, and no local commit outside `ledger/`; otherwise it logs why and changes
nothing. Only with nothing alive, because a driver reads its scripts as it runs; the runner's own body is one `{ … }`
block, parsed before it runs, for the same reason. `harness sync` does the same by hand
(`decisions/2026-10-24-close-the-loop`).

## 13. Extending it

| You want to… | Change | Test |
|---|---|---|
| a new policy | `prompts/policy/<name>.md`; projects opt in with `POLICY=<name>` | a run with `POLICY=<name>` checks the prompt contains it |
| a new guard | the driver loop after `repair`/`green`; log with `note` (phone-visible); count it in `summary.mjs` guards | a stub misbehaviour flag + a check in `tests/run.sh` |
| a new end reason | `finish "<reason>"`; teach `summary.mjs` cause/auto-continue if it should continue | a run that ends that way |
| a new session kind | a template in `prompts/`, a `session <kind>` call, a `MET append … <role>`; extend `parseRunLog` for `"<kind> · model"` lines | stub branch on the prompt's exact first line |
| scheduling rules | `features.mjs schedule()` (pure; unit-testable with node) | a feature list in the stub initializer |
| a new stack | `detect_check` / `detect_smoke` in `config.sh` | `harness init` on a sample repo prints the detection |
| notifications | a call site: `notify "<msg>" title=… priority=high click="$(gh_url …)"` in the driver (the plan's call-site table in `docs/plans/2026-10-19-P1-notifications.md`); a delivery path: `lib/notify.sh` (`NTFY_URL` built in; `NOTIFY_CMD` gets `$1` + `HARNESS_NOTIFY_*`) | `tests/stub-curl.sh` records each call as a block in `$STUB_DIR/curl.log` (`STUB_CURL_FAIL=1` → exit 22); the request shape is `tests/fixtures/ntfy-publish.txt` (from docs.ntfy.sh); `curl_with`/`curl_body` in `tests/run.sh` |
| memory and process limits | `lib/scope.sh` (`scope_run` around the command, `scope_stop` after it) | `tests/stub-systemd-run.sh` / `tests/stub-systemctl.sh` (through `HARNESS_SYSTEMD_RUN` / `HARNESS_SYSTEMCTL`) log each call as a block in `$STUB_DIR/systemd.log` and keep unit state in `$STUB_DIR/scope/`; their shapes are the real captures `tests/fixtures/systemctl-*.txt`, `systemd-no-bus.txt` (`STUB_NO_SYSTEMD=1`); `sd_with`/`sd_count` in `tests/run.sh`. Free memory reads `HARNESS_MEMINFO` (the suite's default: the real capture `tests/fixtures/meminfo.txt`, 9 GB; the gate's run uses a copy with only `MemAvailable` rewritten to 2 GB) and polls every `HARNESS_MEM_POLL` s (1 in the suite). The suite's one real scope is `harness-test-<pid>-*` at 64M, stopped in its check |
| a new failure signal from the CLI | `metrics.mjs environmental()`; capture the real transcript lines as a fixture | stub replays the fixture |

Rules of thumb: keep the driver the only writer of refs and merges; keep agents' write surface to code, the run
record and their own `passes`; make every new behaviour visible in `harness-log.md`; add a stub check before trusting it.

## 14. Recovery runbook

| Situation | Do |
|---|---|
| What is waiting on me? | `harness parked` (every run) or `harness parked <run>`: the question and the two commands that answer it |
| Driver died (machine reboot, kill) | `harness continue <run>`: worktree, list, attempts and markers are on disk |
| Paused after limit hits | `harness status` shows the window; `harness resume <run>` after it, or let the queue continuation run |
| Merge refused (branch protection) or conflicted | fix on GitHub or in the worktree; `harness merge <run>` |
| A feature keeps failing | read its progress entries; answer in INBOX.md; `harness continue <run> --brief "<guidance>"` |
| The list itself is wrong | stop the run; edit `feature_list.json` yourself (only agents are guarded) and commit; continue |
| Need to see a session | `jq -r 'select(.type=="assistant")…' ~/.local/state/harness/<p>/<run>/logs/NN-<id>.jsonl` |

## 15. Known limits (candidates for v4)

- Verify evidence is counted, not judged: a verifier can write plausible rows. The real quality gate is still the
  milestone's review feature; an occasional Opus audit of verify entries would measure this.
- The scheduler is linear-by-default; a richer `after` graph from the initializer would allow parallel sessions
  within one run (worktree per feature), which the driver doesn't do.
- The weekly gate reacts to the last session's figure; it doesn't forecast a night's spend (a run that starts at
  80 % can still use most of the rest before the next reading).
- `harness gc` deletes a run branch whose unmerged commits only touch `.harness/runs/` (the ledger keeps the whole
  run record) unless its driver is alive or a continuation is queued.
- The suite cache (`state/green/green-<key>`) is a file a determined session could create; the key ignores
  gitignored files. Verify and review are the backstop.
- A milestone held because main moved, with no later milestone to carry it, waits for you (`harness merge` after a
  `harness continue` that adds a milestone, or a manual PR).

## 16. Debrief

After a queue, one short session reviews what happened and tells Michael, so nobody opens a session to triage.
It replaces a fixed-time morning session: the queue's end triggers it; `harness debrief` by hand is the fallback.

```
queue runner exits (empty · past --until · queue stop), having started ≥ 1 run (<state>/runners)
  ─► setsid -f harness debrief  (output: queue/debrief.out)
harness debrief [--dry-run]:
  preflight: node, jq, git, flock, claude (sources nvm.sh, adds ~/.local/bin; else logs "missing: …" and exits 1)
  flock debrief.lock (a second debrief says it waits, waits, then covers only what is left)
  since = queue/last-debrief (the first time: the newest "runner up"); the next "since" is taken now, before
    runs = every driver started since (run.log): a run starting during the wait or the session is covered next time
    none → nothing to do, no session
  LIMIT_UNTIL in the future: wait (≤ 5 h; HARNESS_LIMIT_SLEEP in tests), else exit (the next debrief covers it)
  context.md (bash, $0, each part capped): status · trends · queue · runner.log since · per run: ended · summary.json
     · report.md · retro.md · INBOX.md · progress.md questions · needs-Michael lines · limit window · rate-limit info
     · the whole capped at 150 KB; pasted into the prompt with render.mjs --raw ({{X}} in it stays literal)
     (--dry-run: print it and stop)
  DEBRIEF SESSION (DEBRIEF_MODEL=sonnet, 40 turns, $3, SESSION_TIMEOUT; prompt on stdin; --permission-mode dontAsk,
     --allowedTools ALLOW, --disallowedTools DENY; --add-dir ledger, queue/, each run's state dir, worktree and project)
  refused by a usage limit → LIMIT_UNTIL updated; died at startup, not "success", no text → failed (no window):
     exit 1, one notification line, last-debrief untouched: the next one covers these runs
  git status + refs of the ledger, worktrees and projects: before vs after → a warning section in the note
  "CONTINUE: <run> :: <brief>" lines → checked → harness queue add --continue <run> --keep-attempts --brief "Suggested by
     the debrief …" (or "Not queued: why")
  ─► ledger/debrief.md (overwritten) · last-debrief · ledger/debrief.html (lib/page.mjs: a card per run from its
     summary.json and how it stands now, then the note, escaped; committed with the note) · notify (title `harness debrief`, high when Needs Michael has anything): 3 lines + the
     note's path · DEBRIEF_PAGE_CMD "$page" (optional: copy it somewhere a phone can open it)
  commit (LEDGER_COMMIT=1) only if the harness checkout is on MAIN_BRANCH with no rebase/merge/cherry-pick going, only
     that file; a failed commit is unstaged again ("written but not committed" in runner.log)
```

**Since the last success.** `queue/last-debrief` holds the time the last successful debrief gathered its context (or
the start of a run that was still going then, so its end is seen next time). It is written only after a note is
produced, so a refused, failed or killed debrief changes nothing and the next one covers its runs too.

**The note**: Headline (≤ 3 lines; the notification): what landed on main, what is blocked and why, spend against
the usage window. **Runs**: 3–6 lines each. **Needs Michael**: policy, permission and product questions, sudo steps,
inbox questions the docs can't answer. **Draft answers**: only where the project's docs answer, quoting the doc path;
Michael pastes them into INBOX.md himself. **For the next interactive session**: merge conflicts on run branches,
held or refused merges, retro proposals seen in two or more retros (candidate harness PRs). v1 lists; it resolves
nothing and opens no PR. One file, overwritten; `git log -p ledger/debrief.md` is the archive.

**Continuations.** The session may only *ask*; bash queues, and only a run of this debrief that ended on its
deadline or a usage limit, isn't running, has work left (`summary.json`) and isn't already queued. It is queued with
`--keep-attempts` (given-up features stay given up; verify holds stay) and a brief labelled as the debrief's
suggestion. Nothing starts: it waits for the next `harness queue start`.

**Read-only, and the never-list.** The debrief never edits files (in particular INBOX.md, policies, CLAUDE.md,
settings), answers for Michael, starts/continues/merges/stops runs or starts the queue, merges or edits PRs, pushes,
commits, or runs anything live. Enforced in layers:

| | How |
|---|---|
| `--permission-mode dontAsk` + `--allowedTools ALLOW` | only these run: Read, Grep, Glob; `cd ls cat head tail wc grep jq date`; `git log/show/diff/status/rev-parse/rev-list/merge-base/for-each-ref/ls-files`, `git branch --list/-a/-v/-vv/-av/--show-current`; `gh pr view/list/checks`; `harness status/trends/queue list`. Left out on purpose: `rg` and `git grep` (`--pre`, `-O` run programs), plain `git branch`, `harness report` (rewrites summary.json). **The scope lives in one commented array (`ALLOW`) in `lib/debrief.sh`**: widen it there. Checked against the real CLI (haiku, 2026-10-17, $0.004): a read in an added state dir works; Write, a shell redirect and `git … --output=` are denied |
| `--disallowedTools DENY` (wins over ALLOW) | `Edit`, `Write`, `NotebookEdit`; `git diff/log/show --output`; every state-changing `harness` command and `harness report` (bare and by full path); `git push/commit/merge/rebase/reset/checkout/switch/restore/stash/tag/worktree`, `git branch -d/-D/-f/-m`; `gh pr merge/create/close/edit/review/comment/ready`, `gh api/repo/release/workflow`; `sudo ssh scp rsync docker systemctl kubectl tmux kill pkill rm mv cp curl wget npm npx` |
| After the session | compared with before: the ledger directory's files; the worktrees of runs that have ended and the projects: files, HEAD, local branches and tags (not remote refs, not the harness repo's commits, not a still-running run's worktree). Any change is logged and flagged in the note |
| The prompt | the same list in words, including what prefix rules can't express (`git -C …`, shell redirection, a project's `## Live system` commands) |
| Bash | continuations are queued only by bash, after the checks above |

**Cost.** One Sonnet session per queue that started a run, at most 40 turns and $3 (the retro's caps); the context is
capped at a few tens of KB, so expect well under $1. With nothing to cover there is no session. The note's second line
records the model and the session's cost.

## 17. Answer desk

A parked feature waits on a question only Michael can answer, usually while he is away from the box. The answer desk
is the path from the notification to an answer the driver takes, without a branch switch in the GitHub app.

```
session ends "PARKED: <why>", question above ## Answers in INBOX.md
  ─► driver: parked.json[id] = {answers: hash, why, at}; the park notification (§10 NTFY_URL): question, the
     harness answer command, Edit INBOX / Progress, and Answer with Claude when DESK_URL is set
  ─► Answer with Claude opens DESK_URL (Michael's Remote Control environment) → an interactive session on the box
  ─► the harness-answer skill (Michael: "answer the harness" / "what does <project> need?"):
       harness parked · harness status <run> · the run's INBOX.md and newest progress.md entries
       checks what is safe (files, git, a variable's name with grep -c, never a value, no .env, no sudo)
       proposes the answer in one or two sentences; nothing is done before Michael's yes
  ─► harness answer <run> "<text>"  (state/inbox.md; the driver appends it under ## Answers before the next session)
  ─► the run takes it: still going → its next loop unparks (the answers hash changed), nothing else to run
     ended (or ending, once it has) → harness queue add --continue <run> when a queue runner is going, else
     harness continue <run>
```

**`harness parked [<run>] [--json]`** (`cmd_parked` gathers, `lib/parked.mjs` reports): one block per parked feature
that isn't passing (`parked.json` minus passing ids), oldest first: `<run> · <project> · <feature>`, since (local
time and age), why, the question (`questionFor`: the newest `### <id>` section of INBOX.md above `## Answers`, then the
newest heading that mentions the id, else everything sessions wrote there), running, and the next commands
(`commandsFor`). Running is `yes` while `driver.pid` is alive and `ended` isn't written (only the answer: the driver
takes it before its next session), `ending` when both are (the driver is in `finish`: merge, suite, retro; no next
session, so answer now and continue once it has ended), else `no`; a queue runner is `queue/runner.pid` alive. A
queued continuation (`queue/*-continue-<run>.args`; a session-cap end queues its own) gets only the answer command:
it takes the answer when it starts. Headings inside ``` fences don't end a question. A run whose worktree is gone (gc'd) is skipped: there is nothing
to answer or continue there. `--json`: the same as an array of `{run, project, feature, since, why, question,
running, ending, queued, commands[]}`. Nothing parked: `nothing parked` (`… in <run>`). It never writes: no `harness_config`, no
`mkdir`; a broken `meta.env` skips that run only.

**The skill only asks.** It runs commands that already exist, Michael's words passed through a quoted heredoc so
nothing in them is run or expanded; its never-list (never edit INBOX.md, feature lists,
policies or CLAUDE.md directly; never answer without Michael's yes; never run a project's live commands) is text
the session follows, and Michael's yes is the gate. The harness ships the file; Michael installs it once
(`ln -s ~/projects/agent-harness/skills/harness-answer ~/.claude/skills/`).

**The desk starts itself** (`lib/desk.sh`, D-H31). With `DESK=1` the driver calls `harness desk <run> --why …` when a
feature parks (`<id> parked: <why>`), verify or a merge needs Michael (`<m> needs Michael: …`, `<m>: merge refused`)
and the run ends blocked or waiting (`ended: …`); the debrief calls `harness desk --debrief` when its note's
`## Needs Michael` isn't empty. Michael can run either by hand at any time.

```
harness desk <run> --why "<one line>"            (desk.lock: one start at a time, ≤ HARNESS_DESK_WAIT + 10 s)
  ─► <state>/desk/<stamp>.md from prompts/desk.md (run id, why, INBOX and progress paths; no config value)
  ─► window <run> in tmux h-desk open, its claude alive, desk/url kept?
       yes → its screen shows a dialog (the CLI's words: "Esc to cancel", "Enter to select", …) or can't be read?
             type nothing, note it, notify "answer its dialog first" · else type "New since your last brief: <why>.
             Re-read <prompt>." · notify, click = the same URL · done
  ─► tmux new-window|new-session -c ~/projects/<project> (trusted) -- env -u NTFY_TOKEN … claude --remote-control
       "desk · <run> · <why>" --model <DESK_MODEL id> --add-dir <worktree>
  ─► capture-pane until https://claude.ai/code/session_… (≤ HARNESS_DESK_WAIT, 60 s)
       none / claude exited → kill the window · note "desk: …; plain notification" · the plain notification · exit 0
  ─► desk/url · type "Read <prompt> and follow it." · note "desk started: <url> (<why>)" · notify
     "[<run>] needs you: <why>", priority high, click = the session URL · print the URL
```

Every tmux target is exact (`=h-desk`, window ids `@N`): a name would match by prefix. tmux runs `claude` as separate
arguments with no shell, so the `why` (session-written text) is never run; typed lines go in with `send-keys -l`
(literal, never a key name) and Enter half a second later. The desk's note goes to `harness-log.md` through the run
record: the driver commits it at once (`HARNESS: desk`; the retro's revert would drop it otherwise), `desk.sh` commits
it itself when the run's driver is gone. `--debrief` uses window `debrief`, `queue/desk/`, `queue/runner.log` and the
harness checkout as its directory. A refused merge is noted, notified and sent to the desk once per tag commit while the run goes;
`harness merge` says it every time and starts no desk (Michael is at the terminal). Every tmux call runs under `timeout 10`: a wedged server can't hold the driver.
Housekeeping: `harness desk --list` (window, run, URL, age), `--close <run>|--all`, and `harness gc <project>` closes
the project's desks (and the debrief's) idle for 24 h first, then keeps the worktree of a run whose desk is still open. With `DESK=1` Michael gets two
notifications per event: the driver's own (unchanged; it needs no desk) and the desk's.
