# agent-harness — architecture (v3)

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

## 2. Principles (each one is a decision in `journal/decisions.md`)

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
                                               │ libs: config.sh check.sh        │  notify, queue continuation
                                               │  features.mjs metrics.mjs       │
                                               │  treekey.mjs testcount.mjs      │
                                               ▼                                 ▼
                         git worktree ~/worktrees/<p>/<run> ─── origin (GitHub): harness/<run>,
                         branch harness/<run>                    harness-merge/<run>-<m>, tags run/<run>/<m>,
                                                                 milestone PRs → main
```

| Component | Lines | Responsibility |
|---|---|---|
| `bin/harness` | ~330 | CLI: start/continue/merge/queue/status/report/trends/attach/pause/resume/stop/answer/init/gc/debrief. Creates worktrees, ports, state dirs, tmux sessions |
| `lib/driver.sh` | ~370 | The run loop (§5). The only component that runs sessions, commits on the run's behalf, tags and merges |
| `lib/queue.sh` | ~45 | Starts queued runs within the parallel limit, the `--until` time and the usage-limit window; runs `harness debrief` as it exits (§16) |
| `lib/debrief.sh` | ~235 | `harness debrief`: gathers the context in bash, waits out the limit window, one read-only session, the note, checked continuations, the notification (§16) |
| `lib/config.sh` | ~60 | Config layers and conventions (§10) |
| `lib/check.sh` + `treekey.mjs` | ~40 | The suite, cached per content of the code tree. One command for the driver and every session |
| `lib/features.mjs` | ~200 | The feature-list contract: scheduling, gating, repair, kinds, evidence counting |
| `lib/metrics.mjs` | ~100 | Per-session metrics; the "environmental?" decision (limits, API errors, $0) |
| `lib/summary.mjs` | ~230 | Run summary, writeup, ledger rows, trends, calibration |
| `lib/render.mjs` | ~15 | Prompt templating (`{{X}}` ← `HARNESS_X`) and titled sections |
| `prompts/*.md` | | initializer, coding, verify, retro, debrief, supervisor, draft-claude-md; `policy/{build-only,live-staged}.md` |
| `contrib/systemd/` | | `harness-debrief.{service,timer}`: the daily 09:00 `--if-missed` fallback (user units; not installed) |
| `tests/run.sh` + stubs | | End-to-end with stub `claude` and `gh` on a throwaway repo with a bare origin: 65 checks |

## 4. Where state lives

| What | Path | Written by | Read by | Committed? |
|---|---|---|---|---|
| Feature list | `<wt>/.harness/runs/<run>/feature_list.json` | initializer; sessions (own `passes` only); verifier (un-pass only); driver (repair, un-pass) | everyone | yes, run branch |
| Progress log | `…/progress.md` (newest first) | sessions, verifier | sessions, Michael (phone), retro, PR bodies | yes |
| Steering | `…/INBOX.md` (`status: run/pause/stop`, `## Answers`) | Michael (GitHub app), `harness answer` via the driver | driver, sessions | yes |
| Brief | `…/brief.md` | driver, from `--brief` at start/continue | every prompt | yes |
| Driver events | `…/harness-log.md` | driver (`note`) | Michael, summary, retro | yes |
| Metrics | `…/metrics.jsonl` (one row per session) | driver (`metrics.mjs append`) | summary | yes |
| Summary / writeup / retro | `…/summary.json`, `report.md`, `retro.md` | driver at the end | Michael, ledger | yes |
| Driver log | `~/.local/state/harness/<p>/<run>/run.log` | driver (`log`) | status, summary (wall times) | no |
| Transcripts | `…/logs/NN-<id>.jsonl`, `HHMMSS-verify-<m>.jsonl`, `00-init.jsonl`, `zz-retro-*.jsonl` | `claude --output-format stream-json` | metrics, retro, you (`jq`) | no |
| Attempts | `…/attempts.json` | driver (bump, unbump, grant, reset) | scheduler | no |
| Markers | `…/{driver.pid, ended, PAUSE, STOP, verified-<m>, merged-<m>, proposed-<m>, nomerge-<m>, verify-rounds-<m>, tests-start, tests-end, waited-<t>, port, meta.env, run.env, brief.md, inbox.md}` | driver, CLI | driver, CLI, summary | no |
| Shared limit window | `~/.local/state/harness/LIMIT_UNTIL` (epoch) | any driver hitting a limit | every driver, the queue runner, status | no |
| Queue | `~/.local/state/harness/queue/NNNN-<verb>-<name>.args`, `done/`, `runner.log`, `runner.pid`, `runner.until`, `STOP`, `last-debrief` | CLI, driver (continuations), debrief | runner, debrief | no |
| Debrief workspace | `~/.local/state/harness/debrief/<stamp>/{context.md,prompt.md,session.jsonl,final.md,body.md}`, `debrief.lock` | `harness debrief` | you (`--dry-run` prints `context.md`) | no |
| Debrief notes | `<harness>/ledger/debriefs/<YYYY-MM-DD-HHMM>.md` | `harness debrief` (flock, `git commit -- <note>` when `LEDGER_COMMIT=1`) | Michael, the next interactive session | yes, harness repo |
| Scratch | `/tmp/harness/<p>/<run>/` (`init.out`, `check.out`, `check-<key>.out`, `green-<key>`, dev DB, screenshots) | driver, init, check, sessions | sessions, driver | no |
| Live-write lock | `LIVE_LOCK` (default `/tmp/harness/<p>/live.lock`; dj: `/srv/docker/crates/live.lock`, shared with the backup job) | sessions under `live-staged` (`flock -n`), the backup script (`flock -w`) | both | no |
| Ledger | `<harness>/ledger/runs.jsonl`, `ledger/<p>/<run>/{summary.json,retro.md,…}` | driver at the end (flock, `git commit -- <paths>`) | `harness trends`, retro, calibration | yes, harness repo |

## 5. The life of a run

```
harness start ─► worktree + branch ─► driver:
  [resume?] merge main in (and reload the config if it changed) · merge verified (v3) milestones
  [no list] init + suite ─► INITIALIZER ─► feature_list.json, progress.md
  loop:
    stop if: session cap · deadline · STOP/"status: stop"
    pause while: PAUSE/"status: pause"
    wait while: LIMIT_UNTIL is in the future (any run set it)
    verify every complete, unverified milestone (in order) ─► see below; a refused verify waits for the window
    next = first feature: not passing, attempts < MAX_ATTEMPTS, every dependency passing
      none → "done" (all pass) | "blocked on X" (a given-up feature) | "no feature left to try"
    init + suite (cached) ─► CODING SESSION (one feature) ─► commit leftovers
      environmental? (limit, API error, $0 one-turn) → keep its commits, revert its claims (the list, "passes"
        included), give the attempt back, set LIMIT_UNTIL; MAX_LIMIT_HITS in a row → end "usage limit"
      repair the list (only its own passes may change) · un-pass if the suite is red · metrics · push
  VERIFY m: merge main in → session (its code edits are reverted) → refused? deferred, no verdict
      → a new entry with one evidence row per step? no → one re-run on the stronger model → still no → not verified
      → suite green on that tree? → tag run/<run>/<m> (v3) → merge_milestones (PR per milestone, in order)
      a step fails → one more attempt for the feature, then "needs Michael"
  finish: merge what's verified · tests-end · summary.json · RETRO · report.md · ledger · notify · queue a continuation
```

**End reasons** (written to `state/ended`, shown by `harness status`, recorded in the summary):

| Reason | Meaning | What happens next |
|---|---|---|
| `done` | every feature passes | nothing; `harness gc` cleans up once milestones are merged |
| `blocked on X` | X was given up and the rest depend on it | needs Michael: read X's progress entries, answer in INBOX.md, `harness continue` |
| `no feature left to try` | everything left is given up (no dependency chain) | needs Michael |
| `session cap (N)` | the session budget is spent | a continuation is queued (`AUTO_CONTINUE=1`, at most `AUTO_CONTINUE_MAX`=3, within the run's `--until`, given-up features stay given up) |
| `deadline`, `deadline (paused)` | the run's time (`HOURS` or `--until`) is up | nothing automatic: time is your budget. `harness continue` or queue it for another night |
| `usage limit (N sessions refused in a row)` | the plan refused `MAX_LIMIT_HITS` sessions in a row | the run ends so the queue isn't blocked; `harness continue` later |
| `stopped by Michael` | STOP or `status: stop` | `harness continue` when you want |
| `feature-list edits` | MAX_REPAIRS sessions in a row edited the list | a prompt/model problem: look before continuing |
| `initializer failed` / `usage limit before the feature list` | no valid list | fix and `harness continue` (it re-runs the initializer) |
| `driver exited unexpectedly` | the trap fired without a reason (crash, kill) | `harness continue` resumes safely: everything is on disk |

## 6. The feature-list contract

```json
{ "id": "T1-03", "milestone": "T1", "kind": "build", "model": "opus",
  "description": "observable behaviour", "steps": ["verifiable check", "…", "the suite is green"],
  "after": ["T1-02"], "passes": false }
```

- **Order** is priority. **Dependencies**: `after` if present, else *every earlier feature*. So by default one failure
  blocks everything behind it (safe), and the initializer opts independent work out with `after`.
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
| Timeout | `SESSION_TIMEOUT` (exit 124) | counts as a real attempt (the feature is too big) | `metrics.mjs` |
| Verify | milestone complete | independent session; must write a **new** entry with ≥ one row per step, else one re-run on `VERIFY_ESCALATE_MODEL`, else not verified ("needs Michael"); refused by a limit → deferred, never "holds"; suite must be green on the verified tree; a step fails → one more attempt, then "needs Michael" (`MAX_VERIFY_ROUNDS`) | `verify()`, `verify_ready()` |
| Read-only sessions | a verify session changes code, a retro changes anything | reverted by a new commit (`restrict`), logged | `restrict()` |
| Merge order | a later milestone is verified before an earlier one | not merged until the earlier one is (its tag contains the earlier commits) | `merge_milestones` |
| Tainted tag | a milestone's tag contains commits of features in milestones not yet verified (possible with `after`) | held; it is merged by the next verified milestone's merge, which contains it | `tainted-<m>`, `merge_milestones` |
| Verified tree | the merge of the tag into `main` wouldn't produce exactly the tag's tree (main has content it wasn't verified with) | held (the next milestone's verify merges main in first); conflict → "needs Michael" | `merge_one` |
| v2 tags | a tag verified by harness v2 (no "(v3)" in its message) | never merged automatically; `harness merge <run>` merges it (and closes the v2 whole-run PR) | `merge_milestones` |
| Main drift | `main` moved during the run | merged into the run branch before every verify (conflict → that milestone isn't merged) | `sync_main` |
| Session budget | `--max-budget-usd`, `--max-turns` per session | the CLI stops the session | `session()` |

## 8. Branches, tags and PRs — and what `run/*/final` was

| Ref | Created by | Lifetime | Meaning |
|---|---|---|---|
| `harness/<run>` | `harness start` | until `harness gc` | everything the run did, verified or not, plus its run record |
| `run/<run>/<m>` (annotated tag) | driver, after verify holds | permanent | "this commit is milestone `<m>` verified": the exact merge point |
| `harness-merge/<run>-<m>` | driver, `merge_one` | deleted after the merge | a branch at the tag commit, so the PR contains exactly that prefix of the run |
| PR "`<run>: <m> (verified)`" | driver | merged by the driver (`auto`) or left for you (`pr`) | the audit record: features, verify evidence table, cost so far |

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
`MERGE_POLICY`, `MAX_PARALLEL_RUNS`, `NOTIFY_CMD`) → `<project>/.harness/config.sh` (`POLICY=` and real overrides) →
the run's options (`--spec`, `--until`; in `state/run.env`) → **conventions** for what's still unset:

| Setting | Convention |
|---|---|
| `CHECK_CMD` | `.harness/check.sh` · `npm run check` · `npm test` · `python3 -m pytest -q` · `cargo test` · `go test ./...` · `make test` |
| `SMOKE_CMD` | `node .harness/smoke.mjs` · `bash .harness/smoke.sh` · `true` |
| `INIT_CMD` | `.harness/init.sh` · `true` (the driver runs the suite itself, so init only starts servers) |
| port | first free from `BASE_PORT` (7800) |
| run id | `<project>-<date>[-n]` |

**What a project provides**: `CLAUDE.md` (durable rules; read by interactive sessions too, and pasted into every
harness prompt), one `POLICY=` line, and only the scripts that are truly its own (a sandboxed `check.sh`, a dev-server
`init.sh`, a `smoke.mjs`). **What a run provides**: `--spec` files and a `--brief` (scope for this run only).

**Prompt assembly** (`prompt()` → `render.mjs`): the role template (`prompts/<kind>.md`, with `{{X}}` filled from
`HARNESS_X`) + "Brief for this run" + "Project rules (CLAUDE.md)" + legacy `.harness/project.md` if present +
`prompts/policy/<POLICY>.md`. The retro gets the template only.

**Policies**: `build-only` (default: never operate anything live; write live steps down) and `live-staged` (operate
live through the protocol: preflight, stages, stop-and-revert, one writer via `flock`, deploy only from the run's
worktree; the project's `## Live system` section supplies the commands). A policy is text the agent follows **and**
what the permission rules allow; the harness owns the first, Michael the second.

**Permissions.** Headless sessions run in auto mode under your user settings (`~/.claude/settings.json`, where the
history-destroying denies live). A project may add `.claude/settings.json` (passed with `--settings`, because a fresh
worktree is untrusted). The harness never writes either, and agents can't (the auto-mode classifier blocks
"Self-Modification"). The driver logs which applied at start.

## 11. Measurement and the improvement loop

1. **Per session**: `metrics.jsonl` row: kind, role, model, cost (max of cumulative results), wall time (driver),
   API time and turns (summed over result events), exit, `env`, final text.
2. **Per run**: `summary.json` (features, milestones verified/merged, tests start→end, cost by role and model, time
   by role, sessions real/refused, guard counts, every non-passing feature with an automatic cause), `report.md`
   (the writeup: `harness report <run>`), and `retro.md` (a Sonnet session classifies "not done" features into
   spec / size / dependency / permission / environment / model / harness causes and proposes ≤ 3 harness changes,
   noting repeats from earlier retros).
3. **Across runs**: `ledger/runs.jsonl` + `harness trends` ($ per feature, causes, end reasons over time).
4. **Back into runs**: the initializer gets a calibration line from the ledger (median and p90 minutes per passing
   feature, this project and all) to size features against reality.
5. **Into the harness**: you read the retros/trends (or ask a session to), turn a repeated proposal into a decision
   (`journal/decisions.md`), implement it test-first, and **turn the failing transcript into a stub fixture** (as
   `tests/fixtures/usage-limit.jsonl` was), so the fake never drifts from the real API again.

## 12. Queue and parallelism

`MAX_PARALLEL_RUNS` (user config, default 1) bounds live drivers. `harness start` beyond it **queues** the run (its
id is chosen when it starts) and ensures the runner (tmux `h-queue`); `--now` bypasses. A queued continuation is
skipped if you stopped the run; `harness continue` refuses a run whose driver is alive. `harness queue add …` queues without starting;
`harness queue start --until 07:30` runs the queue and gives every run it starts that deadline. The runner never
starts a run while `LIMIT_UNTIL` is in the future. With 1, nights are serial: each run gets the whole plan window.
The runner exits when the queue is empty and nothing it started runs, when it is past `--until` with nothing running,
or on `harness queue stop`; whichever, if it started at least one run, it then runs `harness debrief` once (§16).

## 13. Extending it

| You want to… | Change | Test |
|---|---|---|
| a new policy | `prompts/policy/<name>.md`; projects opt in with `POLICY=<name>` | a run with `POLICY=<name>` checks the prompt contains it |
| a new guard | the driver loop after `repair`/`green`; log with `note` (phone-visible); count it in `summary.mjs` guards | a stub misbehaviour flag + a check in `tests/run.sh` |
| a new end reason | `finish "<reason>"`; teach `summary.mjs` cause/auto-continue if it should continue | a run that ends that way |
| a new session kind | a template in `prompts/`, a `session <kind>` call, a `MET append … <role>`; extend `parseRunLog` for `"<kind> · model"` lines | stub branch on the prompt's first line |
| scheduling rules | `features.mjs schedule()` (pure; unit-testable with node) | a feature list in the stub initializer |
| a new stack | `detect_check` / `detect_smoke` in `config.sh` | `harness init` on a sample repo prints the detection |
| notifications | `NOTIFY_CMD` (gets the message as `$1`), e.g. ntfy.sh | — |
| a new failure signal from the CLI | `metrics.mjs environmental()`; capture the real transcript lines as a fixture | stub replays the fixture |

Rules of thumb: keep the driver the only writer of refs and merges; keep agents' write surface to code, the run
record and their own `passes`; make every new behaviour visible in `harness-log.md`; add a stub check before trusting it.

## 14. Recovery runbook

| Situation | Do |
|---|---|
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
- The limit window is plan-wide but the queue doesn't budget across a night (e.g. stop starting runs at 80 % of the
  7-day window, which `rate_limit_info.unifiedWindows` reports).
- `harness gc` deletes a run branch whose unmerged commits only touch `.harness/runs/` (the ledger keeps the whole
  run record) unless its driver is alive or a continuation is queued.
- The suite cache (`state/green/green-<key>`) is a file a determined session could create; the key ignores
  gitignored files. Verify and review are the backstop.
- A milestone held because main moved, with no later milestone to carry it, waits for you (`harness merge` after a
  `harness continue` that adds a milestone, or a manual PR).

## 16. Debrief

After a queue, one short session reviews what happened and tells Michael, so nobody opens a session to triage.
It replaces a fixed-time morning session: the queue's end triggers it, and a daily timer is the fallback.

```
queue runner exits (empty · past --until · queue stop), having started ≥ 1 run ─► rm runner.pid ─► harness debrief
daily 09:00 timer ─► harness debrief --if-missed
  ├ runner alive: > 1 h past its --until (runner.until) → debrief, headline "Queue looks stuck"; else nothing
  ├ no "runner up" in runner.log, or last-debrief is newer than it → nothing
  └ that runner started no run → nothing; else debrief
harness debrief:
  flock debrief.lock (one at a time) · LIMIT_UNTIL in the future: wait (≤ 5 h; HARNESS_LIMIT_SLEEP in tests), else exit
  context.md (bash, $0): status · trends · queue · runner.log since "runner up" · per run whose driver started since:
     ended · summary.json · report.md · retro.md · INBOX.md · progress.md questions · needs-Michael lines · LIMIT_UNTIL
     · the newest rate_limit_event · earlier retros' paths                          (--dry-run: print it and stop)
  DEBRIEF SESSION (DEBRIEF_MODEL=sonnet, 40 turns, $3, SESSION_TIMEOUT, --disallowedTools <never-list>,
     --add-dir ledger + each run's worktree and project) ─► its final message
  refused by a limit / no note → exit 1, no last-debrief (the timer retries)
  "CONTINUE: <run> :: <brief>" lines → checked here → harness queue add --continue <run> --brief … (or "Not queued: why")
  ─► ledger/debriefs/<YYYY-MM-DD-HHMM>.md (committed like the ledger) · queue/last-debrief · NOTIFY_CMD: 3 lines + path
```

**The note**: Headline (≤ 3 lines; the notification): what landed on main, what is blocked and why, spend against
the usage window. **Runs**: 3–6 lines each. **Needs Michael**: policy, permission and product questions, sudo steps,
inbox questions the docs can't answer. **Draft answers**: only where the project's docs answer, quoting the doc path;
Michael pastes them into INBOX.md himself. **For the next interactive session**: merge conflicts on run branches,
held or refused merges, retro proposals seen in two or more retros (candidate harness PRs). v1 lists; it resolves
nothing and opens no PR.

**Continuations.** The session may only *ask*; bash queues, and only a run of this debrief that ended on its
deadline or a usage limit, isn't running, has work left (`summary.json`) and isn't already queued. Nothing starts:
the continuation waits for the next `harness queue start`.

**The never-list.** The debrief never: edits files (in particular INBOX.md, policies, CLAUDE.md, settings), answers
for Michael, starts/continues/merges/stops runs or starts the queue, merges or edits PRs, pushes, commits, or runs
anything live. Enforced two ways:

| | How |
|---|---|
| Flags (`--disallowedTools`, in `lib/debrief.sh`) | `Edit`, `Write`, `NotebookEdit`; `harness start/continue/merge/gc/init/answer/pause/resume/stop/debrief/queue add/start/stop/rm/clear` (bare and by full path); `git push/commit/merge/rebase/reset/checkout/switch/restore/stash/tag/worktree`, `git branch -d/-D/-f/-m`; `gh pr merge/create/close/edit/review/comment/ready`, `gh api/repo/release/workflow`; `sudo ssh scp rsync docker systemctl kubectl tmux kill pkill rm mv cp curl wget npm npx` |
| The prompt | the same list in words, plus what prefix rules can't catch (`git -C … push`, shell redirection, a project's `## Live system` commands) |
| Bash | continuations are queued only by bash, after the checks above; the session has no way to queue anything else |

The flags are prefix rules, so they are a fence, not a proof; the session also runs under your user settings in
auto mode like every other session, where the history-destroying denies live.

**Cost.** One Sonnet session per queue that started a run, at most 40 turns and $3 (the retro's caps); the context is
a few tens of KB, so expect well under $1. `--if-missed` costs nothing when there is nothing to do. The note's
second line records the model and the session's cost.

**Fallback timer.** `contrib/systemd/harness-debrief.{service,timer}`: user units, daily 09:00 local
(`Persistent=true`), `harness debrief --if-missed` in a login shell. Not installed by the harness; the enable commands
are in the README ("Debrief").

