Milestone base: 07c836791620086b6e80aafcb817f8860b8f87e4

# E1 · E0, E0b and token/cache/orientation telemetry (plan)

Spec: `docs/specs/2026-10-20-measure-then-memory.md` § E0, § E0b, § E1. This plan fixes the interfaces so E1-02 … E1-09
build one thing; E1-09 (review) diffs from the base above. The brief wins on scope: build-only, nothing live except
the one fixture capture of §5 (the spec's own instruction), never park.

Builders: E1-02 = §2 · E1-03 = §3, §4 · E1-04 = §5, §6 (tokens, cache, peak) · E1-05 = §6 (orientation) ·
E1-06 = §7, §8 · E1-07 = §9 · E1-08 = §11 · E1-09 = the review. Check names are in §10; decisions in §12.

## 1. Files and owners

| File | What | Who |
|---|---|---|
| `lib/driver.sh` | `resumed` flag before the `run <id> on` line; the start block runs `sync_main` (+ config reload) for a resumed run, list or not (§2) | E1-02 |
| `tests/stub-claude.sh` | `STUB_INIT_LIMIT=1`: the initializer replays `fixtures/usage-limit.jsonl`, exit 1 | E1-02 |
| `lib/deploy.mjs` (new) | pure guard helpers + a small CLI (§3) | E1-03 |
| `lib/deploy.sh` (new) | `deploy_status`, `deploy_guard` for bash, sourced by `lib/driver.sh` and `bin/harness` (§3) | E1-03 |
| `bin/harness` | `cmd_init` calls `deploy_guard "$p"` after `harness_config` (§3.3) | E1-03 |
| `lib/driver.sh` | `deploy_check` once per run, after the start block (§3.4) | E1-03 |
| `tests/stub-gh.sh`, `tests/fixtures/gh-deployments.json` (new) | `api repos/<o>/<r>/deployments…` (§4) | E1-03 |
| `tests/fixtures/usage-tokens.jsonl` (new) | the real capture (§5) | E1-04 |
| `lib/metrics.mjs` | `tokens(evs)`, `contextPeak(evs)` exported, used by `outcome()`; `append` writes the keys (§6) | E1-04 |
| `tests/stub-claude.sh` | `ok()` replays the fixture's events (§5.3) | E1-04 |
| `lib/metrics.mjs` | `orientation(evs)` exported; `append` writes `orient_*` (§6) | E1-05 |
| `lib/summary.mjs` | `build` keys (§7), `median` exported, `report` rows (§8) | E1-06 |
| `prompts/retro.md` | names the new summary keys as inputs (§8) | E1-06 |
| `lib/driver.sh` | `$STATE/harness-version`, `$STATE/harness-dirty`, `· harness <sha>[+dirty]` on the `run <id> on` line (§9) | E1-07 |
| `lib/summary.mjs` | `harness` in `build`; ledger-line keys; `trends --by version` (§9) | E1-07 |
| `bin/harness` | `trends) … trends <runs.jsonl> "${@:2}"`; usage header line for `harness trends [--by version]` | E1-07 |
| `docs/architecture.md`, `README.md`, `journal/decisions.md` | §11, §12 | E1-08 (each build feature writes its own D-H entry) |
| `tests/run.sh` | every check in §10, each written first and watched failing | each feature its own |

Usage headers (line 2 of each new file, matching the other lib files):

```
// Deploy guards for hosts that build every branch (Vercel, Netlify). No dependencies.
//   vercel-guard <vercel.json> [create]  → add git.deploymentEnabled "harness/**": false (keeps other keys); prints added|kept|absent
//   netlify-guard <netlify.toml>         → add a [build] ignore for harness/* refs (keeps other keys); prints added|kept|own-ignore
//   status <vercel.json|-> <netlify.toml|-> <.vercel dir 0|1> <deployments.json|->  → one line per unguarded host: vercel|netlify
//   slug <origin url>                    → owner/repo of a GitHub origin, or nothing (exit 1)
```

```bash
# Usage: source lib/deploy.sh; deploy_status <project dir> [<git ref>]   (hosts that build run branches unguarded: vercel|netlify)
#        deploy_guard <project dir>                                     (harness init: writes the guards, says what it did)
```

## 2. E0 · a resumed run merges main before any session

Today (`lib/driver.sh` ~line 431) `sync_main` runs only inside `if [[ -f $LIST ]]`, so a run that ended before its
list (`usage limit before the feature list`) re-runs the initializer on the spec as it was at the first start.

1. **Resumed** is decided **before** this segment logs its own start line (line 413, `log "run $RUN_ID on …"`):
   ```bash
   resumed=0; grep -q " run $RUN_ID on " "$STATE/run.log" 2> /dev/null && resumed=1   # an earlier segment of this run
   ```
   (The tmux log window only `touch`es run.log; only the driver writes the line.)
2. The start block becomes `if [[ -f $LIST ]] || (( resumed )); then` around the existing `before_cfg` / `sync_main` /
   config reload; `merge_milestones` inside it stays guarded by `[[ -f $LIST ]]`. Placement unchanged: after
   `commit_all "HARNESS: start run"` + `sync`, before `HARNESS_MERGE_ONLY` and before `run_init` and the initializer.
3. The log line is `sync_main`'s existing note, `merged main into harness/<run>` (`$MAIN_BRANCH into $BRANCH`), so it
   lands in harness-log.md above the initializer's `feature list written`. A conflict keeps today's behaviour (note,
   carry on).
4. Not for fresh runs: a fresh run starts from `origin/main` already, and `--base <other>` must not get main merged.

## 3. E0b · deploy guards

Run branches are `harness/<run>`; milestone PR heads are `harness-merge/<run>-<m>` (`merge_one`), which the guards
below do **not** match, so each PR still gets one preview and `main` deploys as before.

### 3.1 Pure helpers (`lib/deploy.mjs`, exported)

- `vercelGuarded(text)` → `true` when the JSON's `git.deploymentEnabled === false` (all off) or
  `git.deploymentEnabled["harness/**"] === false`.
- `addVercelGuard(text | null)` → the new text: parse (`null` → `{}`), `git ??= {}`; `deploymentEnabled` absent or
  `true` → `{ "harness/**": false }`; an object → add the key; `false` → unchanged. `JSON.stringify(o, null, 2) + "\n"`.
  Every other key kept as it was (order too: keys are only added).
- `netlifyGuarded(text)` → `true` when the `[build]` table (the line `^\s*\[build\]\s*(#.*)?$` up to the next
  `^\s*\[`) has an `ignore =` line containing `harness/`.
- `addNetlifyGuard(text | null)` → `{ text, how }`: `[build]` with its own `ignore` not mentioning `harness/` →
  unchanged, `how: "own-ignore"` (init says: add the harness/* skip to it by hand); `[build]` without `ignore` → the
  line below inserted right after the header; no `[build]` → `\n[build]\n  ignore = …\n` appended. `[build.environment]`
  and other tables are not `[build]`. The line (TOML basic string; exit 0 cancels a Netlify build):
  ```toml
    ignore = "case \"$BRANCH\" in harness/*) exit 0;; esac; exit 1"
  ```
- `vercelDeployments(apiText)` → `true` when the API answer is a non-empty array and some deployment's JSON matches
  `/vercel/i` (Vercel's GitHub integration creates them as `vercel[bot]`). Bad JSON or `[]` → `false`.
- `slug(originUrl)` → `"owner/repo"` from `githubUrls` of `lib/notify.mjs` (import it; one regex for GitHub origins).

### 3.2 Detection (`deploy_status <dir> [<ref>]` in `lib/deploy.sh`)

Inputs: `vercel.json` and `netlify.toml` from the working tree of `<dir>`, or with `<ref>` from
`git -C <dir> show <ref>:<file>` (absent → `-`); `.vercel/` as a directory in `<dir>` **and** in `$PROJECT_DIR`
when set (it is gitignored, so it lives in Michael's checkout, not the worktree); the API answer from
`"${HARNESS_GH:-gh}" api "repos/<slug>/deployments?per_page=1"` (stdout to a temp file, stderr dropped, a failure =
no answer) only when `slug "$(git -C <dir> config --get remote.origin.url)"` gives one. Then `node deploy.mjs status …`.
A host counts as **deployed from Git** when: Vercel = `vercel.json` exists, or `.vercel/`, or `vercelDeployments`;
Netlify = `netlify.toml` exists. It is **unguarded** when deployed and not `vercelGuarded` / `netlifyGuarded`.

### 3.3 `harness init` (`deploy_guard <dir>`, called by `cmd_init` after `harness_config`)

- Vercel deployed (working tree): `vercel.json` missing or unguarded → write `addVercelGuard`, print
  `added the deploy guard to vercel.json (git.deploymentEnabled "harness/**": false): commit it to main`; guarded →
  `keep    vercel.json (run branches don't deploy)`. Not deployed (no vercel.json, no `.vercel/`, no Vercel
  deployments) → nothing written, nothing printed.
- Netlify (`netlify.toml` exists): `added the deploy guard to netlify.toml ([build] ignore for harness/* refs): commit
  it to main` · `keep    netlify.toml (run branches don't deploy)` · own ignore → `netlify.toml has its own [build]
  ignore: add  case "$BRANCH" in harness/*) exit 0;; esac;  to its front by hand`.

### 3.4 Run start (`deploy_check` in `lib/driver.sh`)

Once per run: skipped when `$STATE/deploy-checked` exists, then touched (a continue never repeats it). Runs after the
start block (§2), after `git fetch -q origin "$MAIN_BRANCH"` (a fresh run doesn't call `sync_main`), with
`deploy_status "$WT" "origin/$MAIN_BRANCH"` (Vercel reads the deployed commit's `vercel.json`, so the guard must be on
main before the run branches off). Per unguarded host one `note`:

- `deploy guard: vercel.json on origin/main has no git.deploymentEnabled "harness/**": false; this run will create a preview deploy per session (harness init adds it)`
- `deploy guard: netlify.toml on origin/main has no [build] ignore for harness/* refs; this run will create a preview deploy per session (harness init adds it)`

and, if any, **one** `notify "no deploy guard (<hosts>): this run will create a preview deploy per session"`. The run
does not stop.

## 4. stub-gh: `api repos/<o>/<r>/deployments`

`tests/fixtures/gh-deployments.json`: the example response of GitHub's REST reference, "List deployments"
(`https://docs.github.com/en/rest/deployments/deployments#list-deployments`, a read-only GET of public docs), copied
as published (an array of deployment objects with `id`, `sha`, `ref`, `environment`, `creator` …). Its creator is
`octocat`, so by §3.1 it is **not** Vercel: the demo run (no vercel.json) logs nothing. `tests/stub-gh.sh`:

```bash
  "api repos/"*)   # the deployments of the repo (read-only): STUB_DEPLOYMENTS=0 → none, =vercel → made by Vercel's app
    case ${STUB_DEPLOYMENTS:-} in 0) echo '[]' ;; vercel) sed 's/"octocat"/"vercel[bot]"/' "$HERE/fixtures/gh-deployments.json" ;;
      *) cat "$HERE/fixtures/gh-deployments.json" ;; esac ;;
```

(`case "$1 $2"` sees `api repos/…`; add `HERE=` at the top. Only a value is substituted, no field invented.) The
existing `grep -c "pr merge" gh.log` check is unaffected by the extra `gh api` lines.

## 5. The fixture (E1-04)

1. **Capture** (once; about a cent; the exception to build-only recorded in D-H34):
   ```bash
   d=$(mktemp -d /tmp/harness/agent-harness/agent-harness-2026-10-21-measure/capture.XXXX) && cd "$d" && git init -q
   claude -p "Write a file named ok.txt containing the word ok, then reply ok." --model haiku \
     --output-format stream-json --verbose --permission-mode auto --max-turns 4 --max-budget-usd 0.25 > raw.jsonl
   ```
2. **Copy into `tests/fixtures/usage-tokens.jsonl`**: the `assistant`, `user` (tool results) and `result` lines, in
   order; drop `system` lines (cwd, tool and plugin lists). Replace `session_id` values with `session_TEST` and the temp
   path with `/tmp/capture`; nothing else changes. Before committing: `grep -ci michael` is 0 and no email address or
   home path appears, and the file has ≥ 1 `assistant` with `message.usage` and a `tool_use` named
   `Write`, and one `result` with `usage` and `modelUsage`.
3. **Fields read** (the names the CLI is expected to use; the builder confirms each in the capture with `jq`, and if a
   name differs, uses the captured one and says so in D-H34; never a guessed one):
   - result `usage`: `input_tokens`, `cache_creation_input_tokens`, `cache_read_input_tokens`, `output_tokens`;
   - result `modelUsage`: `{ "<model id>": { inputTokens, outputTokens, cacheReadInputTokens, cacheCreationInputTokens, costUSD, … } }`;
   - assistant `message.id` and `message.usage` (same four snake_case keys); assistant `message.content[]` blocks
     `{ type: "tool_use", name }`; a `timestamp` on any event (expected: none in stream-json).
4. **`ok()` in `tests/stub-claude.sh`** emits the fixture's `assistant`/`user` lines unchanged and its `result` with
   `total_cost_usd`, `result`, `num_turns` (12) and `duration_ms` (60000) substituted, `usage`/`modelUsage` kept:
   `jq -c --argjson c "${1:-0.25}" --argjson r "\"${2:-done}\"" 'if .type == "result" then .total_cost_usd = $c | .result = $r | .num_turns = 12 | .duration_ms = 60000 else . end'`.
   `--argjson` with the quotes, not `--arg`: callers pass `\\n` escapes (`"…\\nPARKED: …"`) that must still become
   newlines, as they do today. Every other stub line (limits, `STUB_NOWORK`, the debrief) is untouched.

## 6. metrics.jsonl (E1-04, E1-05)

**Combining result events.** A session with background subagents emits several `result` events; `total_cost_usd` is
cumulative, so cost is the max. Tokens follow cost: per result event `t(r)` = the sums over `r.modelUsage`'s models
(`inputTokens`, `cacheReadInputTokens`, `cacheCreationInputTokens`, `outputTokens`; it includes every model the session
used), or `r.usage`'s four fields when `modelUsage` is absent; the session's tokens are `t` of the result event with
the largest total (**max, like cost**, the four numbers from one event). The builder confirms the assumption on the
capture: `Σ modelUsage[*].costUSD == total_cost_usd` (modelUsage is the session's cumulative tracker, as cost is). If
it doesn't hold, tokens are **summed** over result events instead and D-H34 says why. No usage anywhere → `null`.

Keys added to every row by `append` (after `turns`, in this order):

| Key | Formula |
|---|---|
| `tokens_in` | `inputTokens` / `input_tokens` (the uncached input) |
| `cache_read` | `cacheReadInputTokens` / `cache_read_input_tokens` |
| `cache_write` | `cacheCreationInputTokens` / `cache_creation_input_tokens` |
| `tokens_out` | `outputTokens` / `output_tokens` |
| `cache_hit_rate` | `cache_read / (tokens_in + cache_read + cache_write)`, 3 decimals; `null` when the denominator is 0 or tokens are null |
| `context_peak` | max over assistant events of `message.usage.input_tokens + cache_read_input_tokens + cache_creation_input_tokens`; `null` without assistant usage |
| `orient_tokens` | E1-05: Σ `input + cache_read + cache_creation + output` of the assistant messages before the first edit |
| `orient_turns` | E1-05: the count of those messages |
| `orient_s` | E1-05: seconds from the first event's `timestamp` to the first edit's; **`null` when events carry no timestamps** (stream-json has none, expected; recorded in D-H34) |

`orientation(evs)` → `{ tokens, turns, seconds }`: assistant events in stream order, **one message per `message.id`**
(the CLI emits one event per content block with the same id and usage; take the last event's usage), up to but not
including the first message holding a `tool_use` named `Edit`, `Write` or `NotebookEdit`; no such call → every
message. No assistant usage → `{ tokens: null, turns: null, seconds: null }`. `outcome()` keeps its keys and gains
`tokens_in … context_peak` (E1-04) and `orient_tokens … orient_s` (E1-05), so `summary.mjs` and `metrics.mjs append`
read one place.

## 7. summary.json (E1-06)

Rows are summary's `all` (metrics rows matched to run.log); "real" = `!r.env`; null tokens count as 0 in sums.

| Key | Formula |
|---|---|
| `tokens.in`, `.cache_read`, `.cache_write`, `.out` | Σ of the rows' `tokens_in`, `cache_read`, `cache_write`, `tokens_out` |
| `tokens.cache_hit_rate` | `cache_read / (in + cache_read + cache_write)`, 3 decimals, `null` at 0 |
| `tokens.context_peak` | max row `context_peak` (`null` if none) |
| `tokens.by_role.<role>` | `{ in, cache_read, cache_write, out }` per role, as `cost.by_role` |
| `per_verified_feature.cost` | `cost.total / features.verified`, 2 decimals; `null` when nothing is verified |
| `per_verified_feature.tokens` | `(in + cache_read + cache_write + out) / features.verified`, rounded; `null` likewise |
| `orientation.tokens`, `.turns`, `.seconds` | `median` of real coding rows' `orient_tokens`, `orient_turns`, `orient_s` (nulls skipped; none → `null`). `median`: sorted, middle value, mean of the two middles for an even count, rounded |
| `rework` | feature ids in list order with harness-log `<id> un-passed: suite red`, or `: <id> failed the re-check`, or more than one real coding session |
| `first_attempt_pass_rate` | features passing and not in `rework` / features with ≥ 1 real coding session, 2 decimals, `null` at 0 |
| `verify_fail_rate` | `failed / (failed + features.verified)`, 2 decimals, `null` at 0; `failed` = harness-log lines `failed the re-check` (a feature verify sent back) |
| `harness.version`, `harness.dirty` | E1-07: `$STATE/harness-version` (or `null`), `$STATE/harness-dirty` == `1` |

On the demo run: `rework` = `["A", "C"]` (A failed M1's first verify, C left the suite red), `first_attempt_pass_rate`
= `0.33` (B), `verify_fail_rate` = `1 / (1 + 3)` = `0.25`.

## 8. report.md and the retro (E1-06)

Two rows after `Spend by role` (numbers in `k`/`M` with one decimal, `–` for null):

```
| Tokens | 1.2M in (cache hit 0.91) · context peak 84.0k · orientation 31.0k tokens / 6 turns (median) · per verified feature 410.0k tokens, $1.83 |
| Quality | first-attempt pass rate 0.33 · rework A, C · verify-fail rate 0.25 |
```

`in` here is the whole input (`in + cache_read + cache_write`). `prompts/retro.md` adds one sentence under its inputs:
summary.json's `tokens` (cache hit rate, context peak), `orientation`, `rework` and `first_attempt_pass_rate` (with
`verify_fail_rate`) say where a run spent tokens and which features needed rework; use them before guessing.

## 9. The ledger row and `harness trends --by version` (E1-07)

- `lib/driver.sh`, before the `run <id> on` line: `HARNESS_VERSION=$(git -C "$HARNESS_HOME" rev-parse --short HEAD
  2>/dev/null || echo unknown)`, `HARNESS_DIRTY=$([[ -n $(git -C "$HARNESS_HOME" status --porcelain 2>/dev/null) ]] &&
  echo 1 || echo 0)`, written to `$STATE/harness-version` and `$STATE/harness-dirty` at every segment start (the
  latest segment's harness wins in the summary; run.log keeps each), and the line gains
  `· harness $HARNESS_VERSION$( (( HARNESS_DIRTY )) && echo +dirty)` (parseRunLog's `^run \S+ on ` still matches).
- `ledger-line` adds `harness_version`, `harness_dirty` (boolean), `tokens` (`{ in, cache_read, cache_write, out }`),
  `cache_hit_rate`, `context_peak`, `per_verified` (`per_verified_feature`), `orient_tokens` (`orientation.tokens`),
  `first_attempt_pass_rate`, `rework` (the count), `verify_fail_rate`. Old rows lack them: every reader treats a
  missing key as `null`.
- `trends <runs.jsonl> --by version`: groups by `harness_version` + `+dirty` when `harness_dirty` (old rows: `–`), in
  order of first appearance:
  ```
  | Harness | Runs | Passing | $/passing feature | Cache hit (median) | Orientation tokens (median) | First-attempt (median) |
  ```
  Passing = Σ passing / Σ total; $/passing = Σ cost / Σ passing; the medians over the group's non-null run values.
  Plain `trends` is unchanged. `bin/harness`: `trends) node … trends "<ledger>/runs.jsonl" "${@:2}"`.

## 10. Checks added to `tests/run.sh` (each written first and watched failing)

| Feature | Check name |
|---|---|
| E1-02 | `continue after a no-list end merges main first` |
| E1-03 | `deploy.mjs: vercel and netlify guards merge, keep keys and detect` (pure, `node --input-type=module -e`) |
| E1-03 | `init: vercel.json gets git.deploymentEnabled harness/** false, other keys kept` |
| E1-03 | `init: a Vercel project without vercel.json gets one` |
| E1-03 | `init: netlify.toml gets a [build] ignore for harness/* refs, other keys kept` |
| E1-03 | `run start without the deploy guard: one note, one notification` (a separate throwaway project with its own bare origin, so `proj`'s main stays as it is) |
| E1-03 | `run start without the netlify guard: one note, one notification` |
| E1-03 | `run start: Vercel deployments on the repo count (STUB_DEPLOYMENTS=vercel)` |
| E1-03 | `run start with the guard: nothing` (the demo run) |
| E1-04 | `metrics.mjs: tokens, cache rate and context peak from the real fixture` |
| E1-04 | `metrics: coding rows carry tokens, cache rate and context peak` |
| E1-05 | `metrics.mjs: orientation stops at the first Write` |
| E1-05 | `metrics: orientation recorded per session` |
| E1-06 | `summary: tokens, per verified feature, first-attempt rate, rework` |
| E1-06 | `report shows tokens and quality` |
| E1-07 | `ledger row has harness_version and harness_dirty` |
| E1-07 | `trends --by version groups the runs` |

Existing checks that must keep passing and are the nearest to break: `resume reloads config merged from main`
(run 15, §2), `M1 and M2 merged into main by PRs` (gh.log, §4), `trends lists every run` (§9), every check that reads
a stub session's final text (PARKED, retro), §5.4.

## 11. Docs (E1-08)

- `docs/architecture.md` §4: the metrics row keys of §6, `harness-version`/`harness-dirty`, `deploy-checked`; §5: a
  resumed run merges main before any session, the initializer included; §10 "What a project provides": projects
  deployed by a Git-connected host disable run-branch deploys (`harness init` writes the guard, the run start notes its
  absence); §11 point 1 tokens, cache and orientation, point 2 the summary keys of §7, point 3 `harness trends --by version`.
- `README.md`: `harness trends --by version` in the command list; `harness init` adds the deploy guard; `harness
  continue` merges main first.

## 12. Decisions reserved

The last entry in `journal/decisions.md` at the base is D-H31; nothing else has taken numbers since.

| D-H | What | Written by |
|---|---|---|
| D-H32 | E0: a resumed run merges main before any session (rejected: merging on every start, which a `--base` run must not get; merging only before the initializer) | E1-02 |
| D-H33 | E0b: run branches never deploy; init writes the guard, the start notes and notifies once (rejected: stopping the run; pushing less often, which costs Michael the phone view) | E1-03 |
| D-H34 | Telemetry: the fields, tokens combined by max like cost (or sum, if the capture says so), `orient_s` null without timestamps (rejected: timestamping the stream in `session()`, a moving part for one number), the one-time live capture as the exception to build-only, `harness_version`/`harness_dirty` and `trends --by version` | E1-04 (E1-05 … E1-07 add their parts) |
