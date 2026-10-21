# Measure first, then fix the harness's memory (2026-10-20)

**Goal.** Make every harness change *measurable*, then use the measurement to land the context and memory changes the
2026-10-19 research recommends, each one with before and after numbers. The research: Michael's
`~/projects/career/ato-2026/agent-memory-briefing.md` §5 and `research-notes.md`.

**Prerequisite.** The phone-answers PRs (#1 P1, #2 P2, #3 P3) are merged and pulled. This run starts from that `main`.

**Order**: E1 → E2 → E3 → E4. E1 and E2 build the instruments. E3 and E4 are the changes those instruments judge.
Running the evals costs real money, so **Michael runs them**, not the overnight run. The run builds everything and
writes him the commands (§E2.5).

## What exists (the gaps found 2026-10-19)

1. **No token or cache numbers.** `lib/metrics.mjs` records cost, turns, API and wall time, but not input tokens or
   cache reads and writes. So "did this change make sessions cheaper or more focused?" can't be answered.
2. **CLAUDE.md is in every prompt twice.** `prompt()` pastes it as "Project rules (CLAUDE.md)"
   (`lib/driver.sh:138`), and `claude -p` auto-loads it again, because the driver runs in the worktree
   (`cd "$WT"`, line 24).
3. **Prompts aren't ordered for the cache.** Each template opens with the feature id (`# Coding session — <id>`), so
   no prompt bytes are shared between sessions. The stable parts (rules, policy) come after volatile ones.
4. **progress.md is unbounded and is the agents' main memory.** The last four runs' files are 57–145 KB. Sessions are
   told to read "the newest entries", but nothing selects or bounds them. Failed approaches and discoveries that
   change other features are prose inside free-text entries.
5. **No way to judge a harness change.** Retros propose changes; nothing re-runs a fixed set of tasks to show a change
   helped (Anthropic's guidance is 20–50 tasks drawn from real failures).

## E1 · Token, cache and orientation telemetry

1. **Per session**, from the stream-json transcript, `metrics.mjs append` adds:
   - **Token totals:** `tokens_in`, `cache_read`, `cache_write`, `tokens_out`, read from the `usage` (and per-model
     `modelUsage`) fields of the result events, summed the way `cost` already handles several result events.
   - **`cache_hit_rate`** = `cache_read / (tokens_in + cache_read + cache_write)`.
   - **`context_peak`**: the largest per-request input total seen on an assistant message.
   - **Orientation cost**: the tokens, turns and seconds before the session's first `Edit`, `Write` or `NotebookEdit`
     tool call (or the whole session if it never edits). This is the price of "getting your bearings". E4 should
     push it down.
2. **Fixtures mirror the real CLI.** Capture one real transcript with
   `claude -p "reply ok" --model haiku --output-format stream-json --verbose` (about a cent). Copy its result and
   assistant events into `tests/fixtures/usage-tokens.jsonl`, and build the stub's output from it. Never invent the
   fields (`CLAUDE.md`: fakes mirror the live API).
3. **`summary.json`** adds:
   - totals and per-role sums of the above;
   - **$ and tokens per verified feature**;
   - median orientation cost;
   - **first-attempt pass rate**;
   - **rework**: features that were un-passed by verify or a red suite, or needed more than one attempt;
   - **verify-fail rate**.

   `report.md` shows them, and the retro prompt points at them.
4. **The ledger row** adds `harness_version` (`git -C <harness> rev-parse --short HEAD` at run start) and
   `harness_dirty` (an uncommitted tree). `harness trends --by version` groups the new metrics by harness version.
5. **Tests:** a stub session replaying the fixture yields the expected token, cache and orientation numbers. The
   summary and the ledger row carry them. Trends groups by version.

## E2 · A replay set and `harness eval`

1. **The set.** Each task lives in `evals/tasks/<id>/task.json`: `{id, project, repo (local path or URL), base
   commit, features: [feature-list entries, 1–3, with steps], check_cmd?, policy, model?, why}`. Tasks come from
   **real past runs** in the project repos. Their run records under `.harness/runs/*/` are committed in pathways,
   dj-crate-streaming, portfolio_site and hit_list (read-only sources). Choose:
   - features that passed first time (does a change keep the easy ones easy?);
   - features that needed retries or were given up (does a change fix the hard ones?);
   - at least one feature that depends on an earlier one in the same task (does the handoff carry what's needed?).

   **Propose 8–12 tasks** in `evals/README.md` with the reason for each. Michael prunes and grows the set over time.
   No task may need a live system or a secret.
2. **`harness eval run [--set default] [--harness <ref>] [--label L] [--repeat N]`.**
   - It checks out the harness at `<ref>` (default `HEAD`) into a temporary worktree, so two versions can be compared
     without merging either.
   - For each task, it clones the repo at the base commit into `/tmp/harness-eval/<stamp>/<task>`, with a local bare
     origin as `tests/run.sh` does.
   - It writes the task's features as the run's `feature_list.json`, so no initializer session runs.
   - It runs that harness version's driver with `MERGE_POLICY=none` (or the equivalent: nothing reaches any real
     remote, no PRs). The usual per-session caps apply, plus `EVAL_BUDGET_USD` for the whole eval. The eval stops
     starting tasks once it's spent.
   - It refuses to start when `USAGE_7D` is past `WEEKLY_STOP_AT`.
   - Each task's `summary.json` and metrics go to `evals/results/<stamp>-<sha>-<label>/`. The run never touches the
     real project checkouts, `~/worktrees`, or real run state.
3. **`harness eval compare <resultA> <resultB>`.** For each task and in total it compares:
   - pass rate (pass^N with `--repeat N`);
   - $ and tokens per verified feature;
   - cache hit rate;
   - orientation cost;
   - context peak;
   - wall time;
   - rework.

   It prints a table and a one-line verdict per metric: better, worse, or within noise. Noise is the spread across
   repeats; with a single repeat it says "one sample".
4. **Handoff probes** (`harness eval probes <task-result>`, cheap). This checks whether a fresh session's starting
   context carries what it needs, Factory-style.
   - For a finished eval task, bash derives probe questions from the record, for example: "Which files did `<feature>`
     change?", "What did the last attempt at `<feature>` fail on?", "What does `<feature>` depend on?". The answers
     come from git and the feature list.
   - It asks one Haiku session, given **only** what the next coding session would get (its prompt, plus the context
     pack once E4 lands), to answer them.
   - It scores the answers by exact or contains match. No LLM judge in v1.
5. **Tests** run against the stub `claude`: a two-task set runs end to end, results land in the right place, and
   `compare` prints the table. The budget cap stops the eval, `--harness <ref>` really runs that ref's driver, and
   nothing reaches a real remote.
6. **The commands for Michael.** The run ends by writing `evals/NEXT.md`: the baseline command (harness at the
   pre-E3 tag), the E3 and E4 comparisons, and the expected cost.

## E3 · Prompt and context hygiene (measured with E1 and E2)

1. **No double CLAUDE.md.**
   - Sessions that run in the worktree (initializer, coding, verify, retro) no longer get CLAUDE.md pasted in, because
     Claude Code loads it. The prompt keeps one line naming the file.
   - The debrief runs elsewhere: check its working directory, and keep pasting only where the file isn't auto-loaded.
   - Test: the coding prompt doesn't contain CLAUDE.md's text.
2. **Static first, volatile last.**
   - Each template splits into a static part (role, ground rules, how to finish) and a volatile part (feature id,
     milestone, brief, INBOX answers, init output).
   - Prompt order: the static part, then the policy, then the run-level part (spec list, brief), then the per-session
     part.
   - The first line stays a fixed per-kind heading (`# Coding session`, with no id), which `tests/stub-claude.sh` keys
     on.
   - Test: two coding prompts of one run share a byte-identical prefix that includes the policy.
3. **Time and budget awareness.** One line in the volatile part: run elapsed / deadline, this session's budget and
   turn cap, and attempt N of `MAX_ATTEMPTS`. Carlini's note: "Claude can't tell time."
4. **Model-facing suite output.** The "Init output" section holds at most the last 40 lines of init and suite output,
   plus the path to the full log in scratch.
5. **A decision entry** (`D-H<n>`) per change, and `architecture.md` §10 (prompt assembly) updated.

## E4 · Bounded episodic memory: a journal plus a context pack

The model: LiveKit Agents 2.0 splits the full record from the model's view. The *journal* is append-only and
complete. The *history* is curated for the model. progress.md stays for Michael's phone but stops being the agents'
memory interface.

1. **Entries.** A session (coding or verify) writes its entry as JSON to `<run>/entry.json` before finishing. Schema
   in `lib/entries.mjs`:
   - `feature`, `kind`, `outcome` (`passes` · `not yet` · `parked`);
   - `summary` (≤ 400 characters);
   - `files` (the paths it changed);
   - `verified_how`, `tests_before`, `tests_after`;
   - `dead_ends` (what was tried and why it failed);
   - `discoveries` (each with `affects`: feature ids or `"run"`);
   - `questions`, `proposed_changes`;
   - for verify, `evidence` rows.

   **The driver is the single writer.** It validates `entry.json` (bad JSON or a missing entry is logged and
   recorded as a minimal entry from git and the final message), stamps the time, session id and model, appends it to
   `<run>/entries.jsonl` and deletes `entry.json`.
2. **progress.md is rendered, not written.** The driver regenerates it from `entries.jsonl` after every session:
   newest first, the last 15 entries in full (verify evidence tables included), then one line per older entry linking
   to `progress-archive.md`. That file is also rendered and complete. The phone view keeps its shape.
3. **The context pack.** Before each session, the driver writes `<run>/context.md`, capped by `CONTEXT_PACK_BYTES`
   (default 8 KB). Selection is deterministic, with a fixed priority order:
   1. this feature's earlier attempts, dead ends and questions;
   2. the INBOX answers;
   3. discoveries whose `affects` names this feature or `"run"`;
   4. the latest entry of each feature in its `after`;
   5. the last 3 entries of the run.

   Each item ends with a reference to its entry (`entries.jsonl` line), so anything trimmed can be read in full.
   No LLM summarizes anything.
4. **The prompts change**: "Read `context.md` first; the full record is `entries.jsonl` / `progress-archive.md` if you
   need more." Sessions write `entry.json` instead of editing progress.md.
5. **Old runs keep working.** A run without `entries.jsonl` behaves exactly as today. Continuing an old run starts a
   journal from that point, and its progress.md is kept as `progress-archive.md`.
6. **Tests:**
   - the stub writes entries and the driver appends them;
   - a malformed entry is recorded as minimal, and the run goes on;
   - progress.md renders 15 entries plus the archive lines;
   - the context pack respects the cap and the priority order (a feature's dead end survives a flood of other
     entries);
   - a legacy run is untouched.
7. **What this should move** (Michael checks with E2 after merging): orientation cost and context peak down; probe
   score not worse; pass rate not worse.

## E0 · A bug found 2026-10-20 (fix it first, in E1)

`harness continue` on a run that ended **before its feature list existed** (here: `usage limit before the feature
list`) re-ran the initializer **without merging `main` first**. The run worktree kept the spec as it was at the
original start, so the initializer planned from a stale spec, even though `main` had a revised one
(voice-concierge-2026-10-19, 00:06). Fix: a resume merges `main` in before any session, the initializer included,
and logs it. Test: revise the spec on main after a no-list end, continue, and check that the initializer's worktree
has the new spec.

## E0b · Deploy-aware pushes (found 2026-10-19)

**Finding.** The driver pushes the run branch after every session, which is right: Michael follows `progress.md` on
GitHub. But portfolio_site is linked to Vercel, and Vercel builds a preview for **every push to every branch**. The
v2 run's sessions, verifies and merge branches passed the free plan's cap:

```
Resource is limited - try again in 24 hours (more than 100, code: "api-deployments-free-per-day")
```

The cap is shared with production, so a busy night can block the next morning's real deploy.

**Fix** (the approach: run branches never deploy; each verified milestone's PR branch deploys once, so the PR still
gets its preview; `main` deploys as before):

1. **Detection.** `harness init` and the start of every run check whether the project is deployed from Git by a host
   that builds every branch: `vercel.json`, a `.vercel/` directory, or Vercel deployments on the repo
   (`gh api repos/<o>/<r>/deployments?per_page=1`, read-only). Netlify (`netlify.toml`) gets the same treatment, with
   its own config.
2. **The guard.** For Vercel, the check is that `vercel.json` has `git.deploymentEnabled` with `"harness/**": false`.
   - `harness init` adds that key to a missing or incomplete `vercel.json` (merging the JSON, keeping other keys) and
     says so.
   - At the start of a run, a missing guard is a `note` in `harness-log.md` plus one notification ("this run will
     create a preview deploy per session"). The run doesn't stop.
   - The guard must be on the run branch itself (Vercel reads the deployed commit's `vercel.json`). So `main` must
     have it before the run starts, and the start check reads `origin/main`.
3. **Docs.** An `architecture.md` §10 line under "What a project provides": projects deployed by a Git-connected
   host disable run-branch deploys.
4. **Tests:** `harness init` on a fixture with a `vercel.json` (with and without other keys) writes the guard and
   keeps the other keys; a run start without the guard logs the note and notifies once; with the guard, nothing.

Applied by hand on 10-20 for portfolio_site: `vercel.json` on main (`740c540`), merged into
`harness/portfolio_site-2026-10-20` while it was paused.

## Out of scope (candidates for later, noted for the retro)

- An LLM "curator" doing delta edits to a playbook (ACE, Letta sleep-time). Deterministic selection comes first.
- Sprint contracts: the verifier agrees each feature's criteria before coding.
- Re-ablation of components on each model upgrade. E2 makes it possible; deciding what to ablate is Michael's call.

## Milestones

| M | Contents | After |
|---|---|---|
| E1 | §E1 | — |
| E2 | §E2 | E1 |
| E3 | §E3 | E1 (not E2's internals) |
| E4 | §E4 | E3 (prompt templates) |

Each milestone gets its `D-H<n>` entries, its `architecture.md` and `README.md` updates, and its checks in
`tests/run.sh`, written first and watched failing. The suite must stay green.
