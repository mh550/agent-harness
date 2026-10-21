# Progress — run `agent-harness-2026-10-21-measure` (agent-harness)

What this file is: the run's log for Michael's phone and for every fresh session. **Newest entry first**, directly
below this header. `feature_list.json` is the plan: array order is priority, `after` is what a feature truly needs,
and the harness gives each session the first feature that isn't passing whose dependencies pass. Steer from
`INBOX.md` on this branch (first line `status: run|pause|stop`; answers under `## Answers`; the harness pulls it
before every session). The brief for this run is `brief.md`; the spec is `docs/specs/2026-10-20-measure-then-memory.md`.

### 2026-10-21 · verify E1

Init green; `bash tests/run.sh` run fresh: 189/189 checks passed, no FAIL. `bash -n` on lib/*.sh tests/*.sh bin/harness and `node --check` on lib/*.mjs clean. Check names below are the PASS lines of that run.

| Feature | Step | What you ran or read | What you saw | Holds |
|---|---|---|---|---|
| E1-01 | 1 | read docs/plans/2026-10-21-E1-telemetry.md (line 1, headings §1–§12, §5, §10, §12) | line 1 `Milestone base: 07c8367…`; sections for files/owners per E1-02…09, E0 (§2), E0b (§3), fixture capture + fields (§5), metrics/summary keys (§6–7), ledger + trends (§9), check names (§10), D-H32/33/34 (§12) | yes |
| E1-01 | 2 | read plan lines 169–175, 189 | tokens combine by max like cost, falls back to sum if capture says so; `orient_s` null without timestamps, recorded in D-H34 | yes |
| E1-01 | 3 | `git show --stat ef0cca2` | plan file only plus the harness's own feature_list/progress bookkeeping; no code | yes |
| E1-01 | 4 | `bash tests/run.sh` | 189/189 | yes |
| E1-02 | 1 | read tests/stub-claude.sh diff | `STUB_INIT_LIMIT` in initializer branch cats fixtures/usage-limit.jsonl and `exit 1` before the list is written | yes |
| E1-02 | 2 | read tests/run.sh:337–338; suite PASS line | check `continue after a no-list end merges main first` asserts ended starts `usage limit before the feature list`, `grep -q revised …/SPEC.md`, and awk: `merged main` line precedes `feature list written`; PASS | yes |
| E1-02 | 3 | read progress entry line 69 | quotes `FAIL continue after a no-list end merges main first` (168/169) before the driver change | yes |
| E1-02 | 4 | read lib/driver.sh:416,437–441; suite | `resumed` set from earlier `run <id> on` line; `if [[ -f $LIST ]] \|\| (( resumed ))` runs sync_main before initializer; `resume reloads config merged from main` PASS | yes |
| E1-02 | 5 | `grep -c '^### D-H32' journal/decisions.md`; read entry | 1; finding · choice · rejected | yes |
| E1-02 | 6 | `bash -n`; full suite | clean; 189/189 | yes |
| E1-03 | 1 | read run.sh:137–138; suite | check `init: vercel.json gets …` asserts framework nextjs kept, `deploymentEnabled["harness/**"]==false`, stdout "added the deploy guard"; PASS | yes |
| E1-03 | 2 | read run.sh:139–141; suite | `.vercel/`-only repo gets file; bare repo gets none and no output; PASS | yes |
| E1-03 | 3 | read run.sh:350–351,352; suite | one `preview deploy per session` note in hlog (and after continue: 2 initializer-refused, still 1), exactly one curl post; PASS | yes |
| E1-03 | 4 | read run.sh:359–360; suite | demo hlog has no `preview deploy`, curl_count 0; PASS | yes |
| E1-03 | 5 | read tests/stub-gh.sh diff, fixtures/gh-deployments.json keys, lib/deploy.sh | stub answers `api repos/…` from fixture (id, sha, ref, environment present), `STUB_DEPLOYMENTS=0` → `[]`; detection uses vercel.json, .vercel/, read-only gh api, netlify.toml (now `per_page=20` after review, check updated) | yes |
| E1-03 | 6 | run.sh:144–145 and :353–354; suite | init adds `[build] ignore` that exits 0 for BRANCH=harness/x, exits 1 for main, other keys kept; run start notes netlify absence once; both PASS | yes |
| E1-03 | 7 | read architecture.md:252–255, `grep -c '^### D-H33'` | line on Git-connected hosts disabling run-branch deploys present; D-H33 count 1 | yes |
| E1-03 | 8 | `bash -n`; suite | clean; 189/189 | yes |
| E1-04 | 1 | `jq` on tests/fixtures/usage-tokens.jsonl; `grep -ci michael` | 3 assistant events with message.usage, one with tool_use `Write`, result with usage + modelUsage, session ids test-ised, 0 hits for michael; D-H34 records the capture exception | yes |
| E1-04 | 2 | `node -e` import `outcome`,`orientation` on fixture | tokens_in 4, cache_read 35768, cache_write 13651, tokens_out 219, cache_hit_rate 0.724 (=35768/49423), context_peak 24881 (jq max matches); row written by append | yes |
| E1-04 | 3 | read run.sh:93–96; suite | check asserts literals 4/35768/13651/219/0.724/24881, all match my jq numbers; PASS | yes |
| E1-04 | 4 | read stub-claude.sh `ok()`; run.sh:162; suite | `ok()` replays fixture with cost/result substituted; check asserts tokens_in>0, rate 0..1, context_peak>0 on coding rows; PASS | yes |
| E1-04 | 5 | read progress line 52; suite | FAIL lines quoted (177/179); 189/189 | yes |
| E1-05 | 1 | read lib/metrics.mjs orientation; ran it on fixture | `{tokens:24547,turns:1,seconds:0.233}`; 24547 = 2+13312+11228+5 by hand; stops at the Write request; fixture does carry timestamps | yes |
| E1-05 | 2 | read run.sh:97–104; suite | literals 24547/1/0.233, no-edit 49432/2, no-timestamps seconds null, no-usage null; PASS | yes |
| E1-05 | 3 | read run.sh:163; metrics output; suite | rows carry orient_tokens/turns/s; check asserts >0, >=1; PASS | yes |
| E1-05 | 4 | read progress line 43; suite | FAIL lines quoted (179/181); 189/189 | yes |
| E1-06 | 1 | read lib/summary.mjs 28–44, 168–187 | tokens totals + by_role, cache_hit_rate, context_peak, per_verified_feature {cost,tokens}, orientation median, first_attempt_pass_rate, rework, verify_fail_rate all present | yes |
| E1-06 | 2 | read run.sh:166; suite | asserts tokens.in>0, per_verified_feature.cost>0, rework==["A","C"], first_attempt 0.33, verify_fail>0; PASS | yes |
| E1-06 | 3 | read summary.mjs:239–240, run.sh:167; suite | `Tokens` and `Quality` rows greped in `harness report demo`; PASS | yes |
| E1-06 | 4 | read prompts/retro.md:9–10 | names tokens, orientation, rework, first_attempt_pass_rate, verify_fail_rate | yes |
| E1-06 | 5 | read progress line 35; suite | FAIL lines quoted (181/183); 189/189 | yes |
| E1-07 | 1 | read driver.sh:416–420, lib/version.sh, summary.mjs:186, ledger fields | writes harness-version/dirty (skipped for merge-only), logs on `run <id> on` line, summary `harness:{version,dirty}`; uses last non-ledger commit (refined from plain rev-parse, D-H34) | yes |
| E1-07 | 2 | read run.sh:169–171; suite | asserts ledger row harness_version==HV and boolean harness_dirty, run.log and marker; PASS | yes |
| E1-07 | 3 | read run.sh:278–280; suite | `trends --by version` rows per version, header; plain trends has no Harness column; `trends lists every run` PASS | yes |
| E1-07 | 4 | read progress line 26; suite | FAIL lines quoted (183/185); 189/189 | yes |
| E1-08 | 1 | read architecture.md §4 rows 80,84, §5 line 102, §11 lines 275–283 | metrics keys, version marker, resumed run merges main before any session, tokens/cache/orientation, summary keys, trends --by version | yes |
| E1-08 | 2 | read README.md:41,44,46 | trends --by version, init deploy guard, continue merges main first | yes |
| E1-08 | 3 | `grep -c '^### D-H3[234]'` | 1 each | yes |
| E1-08 | 4 | `bash tests/run.sh` | 189/189 | yes |
| E1-09 | 1 | read docs/plans/2026-10-21-E1-review.md | lists M1–M8, S9–S10, R1–R5 with severity and resolution; diff from plan base 07c8367; states Opus reviewer read the diff (cannot independently confirm the subagent, doc is complete) | yes |
| E1-09 | 2 | read review table, progress line 12 | no Critical/Important; Minors fixed with quoted FAIL lines (184/189) and commits 65cf82f, 3f42aec | yes |
| E1-09 | 3 | `bash -n` all shell files, `node --check` all lib/*.mjs | all clean | yes |
| E1-09 | 4 | `bash tests/run.sh` | 189/189 | yes |

### 2026-10-21 18:50 · E1-09 · passes

- **What changed:** `docs/plans/2026-10-21-E1-review.md` (new: 8 Minor + 2 simplifications from the Opus review of `07c8367..32fbde5`, 5 Minor from a second Opus pass on the fixes, each with its resolution). Fixes: `lib/summary.mjs` exports `redSuite`/`failedRecheck` (escaped, exact-id; `cause()` and `rework` share them, so id `c++` no longer throws and empties `summary.json`); `lib/features.mjs` escapes the id; `lib/driver.sh` doesn't rewrite `harness-version` under `harness merge`; `lib/deploy.mjs`: true `harness/…` Vercel keys and `deploy-preview`/`branch-deploy`/`"harness/…"` Netlify context ignores count as unguarded, `vercel-guard` says `by-hand` rather than a false "added"; `lib/deploy.sh` reads `per_page=20` deployments. D-H33 updated. Tests 186 → 189.
- **Watched failing:** 184/189 with `FAIL deploy.mjs: a true harness/ key or a context ignore isn't guarded (E1 review)`, `FAIL summary.mjs: cause and rework read the log by exact id (E1 review)`, `FAIL harness merge keeps the harness version of the run (E1 review)` and the two `per_page` run-start checks; round 2's assertions `DREV FAIL` standalone.
- **Verified:** suite 189/189 twice; `check.sh` green in 276 s; `bash -n` on `lib/*.sh bin/harness tests/*.sh`, `node --check` on every `lib/*.mjs`. Nothing Critical or Important was found.
- **Left, with reasons (in the review file):** orientation's output share is understated (stream snapshot, already a D-H34 limit); root `vercel.json` vs a Vercel Root Directory; a context ignore under a bare `[context]` table.
- **Next:** E1 is complete; E2 per the spec.

### 2026-10-21 18:20 · E1-08 · passes

- **What changed:** `docs/architecture.md` §4 (metrics row keys, harness-version/dirty state files), §5 (resumed run merges main before any session, initializer included), §11 points 1–3 (tokens/cache/orientation, new summary keys, `trends --by version`); `README.md` (`trends [--by version]`, init deploy guard, continue merges main). Tests 186 → 186 (docs only).
- **Verified:** `grep -c '^### D-H3[234]' journal/decisions.md` is 3 (one each, already written by E1-02..07); `check.sh` green in 277 s.
- **Next:** E1-09.

### 2026-10-21 17:55 · E1-07 · passes

- **What changed:** `lib/version.sh` (new) `harness_version <dir>`; `lib/driver.sh` writes `$STATE/harness-version`/`harness-dirty` per segment and ends the `run <id> on` line with `· harness <sha>[+dirty]`; `lib/summary.mjs`: `harness { version, dirty }` in `build`, `ledger-line` adds `harness_version`, `harness_dirty` and the telemetry keys of plan §9 (null when absent), pure `byVersion` behind `trends <runs.jsonl> --by version` (other args exit 2); `bin/harness trends` passes its args and its usage line names `--by version`. D-H34 gains "Across harness versions (E1-07)". Tests 183 → 186.
- **Watched failing:** `FAIL ledger row has harness_version and harness_dirty`, `FAIL trends --by version groups the runs` (183/185); `FAIL harness version skips ledger commits` against the step's `rev-parse HEAD` logic.
- **Verified:** `trends --by version` on hand-made rows: `–` / `abc1234` / `abc1234+dirty` groups, medians 0.60 cache hit and 12.3k orientation tokens match hand math; in the suite, 32 demo rows are 1 group `<sha>+dirty | 32 | 56/84`. `bash -n`, `node --check`; `check.sh` green in 277 s, 186/186. An Opus review found one real flaw (below), fixed.
- **Default taken (D-H34), a deviation from step 1's `rev-parse --short HEAD`:** the version is the last commit **outside `ledger/`**, and dirty ignores `ledger/` too. The driver and debrief commit the ledger into the harness checkout (15 of main's last 30 commits are `ledger:`), so HEAD would make every run its own "version". Question for Michael: fine to treat ledger commits as not-a-version?
- **Next session (E1-08) must know:** README/architecture still lack `trends --by version`, `harness-version`/`harness-dirty` state files and `lib/version.sh` (plan §11 gives docs to E1-08).
- **Proposed change:** step 1 of E1-07 should read "the last commit outside ledger/" rather than `rev-parse --short HEAD`.

### 2026-10-21 17:20 · E1-06 · passes

- **What changed:** `lib/summary.mjs`: `median` and `tokenTotals` exported (pure); `build` adds `tokens` (+ `by_role`), `per_verified_feature` { cost, tokens }, `orientation` { tokens, turns, seconds } (medians of real coding rows), `rework`, `first_attempt_pass_rate`, `verify_fail_rate` as plan §7; `report` gains `Tokens` and `Quality` rows after `Spend by role` (only for summaries that have the keys, so older ledger summaries print as before). `prompts/retro.md` names the keys as inputs. D-H34 gains "The run's numbers (E1-06)". Tests 181 → 183.
- **Watched failing** on a scratch copy: `FAIL summary: tokens, per verified feature, first-attempt rate, rework`, `FAIL report shows tokens and quality` (181/183).
- **Verified:** the new `build` on the saved demo state: tokens in 40 / cache_read 357680 / cache_write 136510 / out 2190, hit 0.724, peak 24881, per verified feature $1.08 / 165473 tokens, orientation 24547 / 1 / 0.23 s, rework [A, C], first-attempt 0.33, verify-fail 0.25 (= plan §7). `node --check`, `bash -n`; `check.sh` green in 276 s, 183/183. Opus review: no bugs; its `1000.0k` rounding note fixed.
- **Next session (E1-07) must know:** a run whose metrics rows predate E1-04 sums its tokens as 0, not null (plan: "null tokens count as 0"), so a ledger row for such a run would carry `tokens.in` 0; E1-07 may want to treat 0 input as "not recorded".
- **Proposed change:** `cause()` in `summary.mjs` (older code) builds its `un-passed: suite red` / `failed` regexes from an unescaped, unanchored id (`A` matches `BA un-passed`); the new `rework` code escapes and anchors. A one-line fix for E1-09's simplify pass.

### 2026-10-21 16:45 · E1-05 · passes

- **What changed:** `lib/metrics.mjs` `orientation(evs)` exported → `{ tokens, turns, seconds }`; `outcome()` and `append` write `orient_tokens orient_turns orient_s` after `context_peak`; 2 checks in `tests/run.sh`; D-H34 gains an "Orientation (E1-05)" paragraph and a widened known limit. Tests 179 → 181.
- **Watched failing** on a copy with only the checks: `FAIL metrics.mjs: orientation stops at the first Write`, `FAIL metrics: orientation recorded per session` (179/181).
- **Verified:** by hand from the fixture: full capture 24547 tokens (2+11228+13312+5) / 1 turn / 0.233 s; without its `Write` 49432 / 2 / 1.441 s; no timestamps → seconds null; no usage → all null. `node --check`, `bash -n`; `check.sh` green in 275 s, 181/181. Opus review: no bugs, two low edge cases; the timestamp-less edit event one is fixed (timed by the last stamped event before it, asserted).
- **Default taken (D-H34), a deviation from the step's "before":** orientation counts requests **up to and including** the first edit. With "before", the real capture (its first request is the `Write`) gives 0/0, so every stub session would show none and step 3 (`orient_tokens > 0`) could only hold with a hand-made stub event; and the edit request's input is what orientation read. +1 request per session, the same for every run.
- **Next session (E1-06) must know:** every stub coding row is 24547 / 1 / 0.233, so the median orientation on demo is those numbers. `orient_s` is a number with ms precision.
- **Proposed change / question for Michael:** step 1 of E1-05 and plan §6 say "before the first edit" and `orient_s` null; should orientation exclude the edit request instead? It's a one-line change in `orientation()` plus a stub orientation event.

### 2026-10-21 15:55 · E1-04 · passes

- **What changed:** `tests/fixtures/usage-tokens.jsonl` (new: the real capture, haiku, CLI 2.1.306, $0.0032; assistant/user/result lines, `session_TEST`, `/tmp/capture`; system lines and the rate_limit_event dropped); `lib/metrics.mjs` `tokens()`/`contextPeak()` exported, `outcome()` + `append` write `tokens_in cache_read cache_write tokens_out cache_hit_rate context_peak` after `turns`; `tests/stub-claude.sh` `ok()` replays the fixture (cost/result/turns/duration substituted, `--argjson` as plan §5.4); 2 checks; D-H34. Tests 177 → 179.
- **Watched failing** on a copy without the code: `FAIL metrics.mjs: tokens, cache rate and context peak from the real fixture`, `FAIL metrics: coding rows carry tokens, cache rate and context peak` (177/179).
- **Verified:** jq on the fixture gives 4 / 35768 / 13651 / 219, rate 0.724, peak 24881 (the literals in the check); `Σ modelUsage.costUSD` = `total_cost_usd` = 0.00319778 → tokens by **max**, as planned. `bash -n`, `node --check`; `check.sh` green in 275 s, 179/179. Opus review: no bugs; two doubts recorded in D-H34 (max is inferred from a single-result capture; `context_peak` counts subagent events too).
- **Next session (E1-05) must know:** stream-json events **do** carry ISO `timestamp` on assistant and user lines (the plan expected none), so `orient_s` can be measured; the fixture's first message is two events with one `message.id` (thinking, then `Write`), 0.23 s apart. Every stub session replays those same timestamps.
- **Proposed change:** plan §5.3/§6 says `orient_s` is null without timestamps "(expected: none)"; E1-05 should measure it instead. No change to the list.

### 2026-10-21 16:20 · E1-03 · passes

- **What changed:** new `lib/deploy.mjs` (pure guards: `vercelGuarded`/`addVercelGuard`/`vercelMergeable`, `netlifyGuarded`/`addNetlifyGuard`, `vercelDeployments`, `slug`, `unguarded` + CLI) and `lib/deploy.sh` (`deploy_status`, `deploy_guard`); `bin/harness` `cmd_init` calls `deploy_guard`; `lib/driver.sh` `deploy_check` once per run (`$STATE/deploy-checked`) after the start block, reading `origin/main`, one note per host + one notify; `tests/stub-gh.sh` answers `api repos/…/deployments` with `tests/fixtures/gh-deployments.json` (GitHub's published `deployment-items` example from github/rest-api-description, unchanged; `STUB_DEPLOYMENTS=0|vercel`); `tests/run.sh` 8 checks (plan §10) and `hlog <run> [<project>]`; D-H33; architecture §10 line. Tests 169 → 177.
- **Watched failing:** all 8 new checks FAIL on a copy without the code (169/177). The first green attempt failed 3 run-start checks only in the full suite: an earlier section drops `NTFY_URL` from the user config, so the section now uses the base config and restores it after.
- **Verified:** `bash -n` on the 5 shell files, `node --check lib/deploy.mjs`; `check.sh` green in 273 s, 177/177. An Opus review of the diff found 10 issues. Fixed: `[ build ]`, inline/dotted `build` and a quoted `"ignore"` key; Vercel detection by `creator.login == vercel[bot]` instead of any "vercel" in the JSON; the exact Netlify guard; non-object vercel.json; Vercel's "any matching `true` wins" rule; the hand-fix hint's quotes; the once-per-run check now counts 2 initializer refusals. Each has a pure assertion.
- **Next session must know:** the deploy section uses its own projects (`dproj`: `vp np dp gp`, bare origins behind `git@github.com:test/<name>.git`), and `dstart` runs end at once via `STUB_INIT_LIMIT=1`. Demo's harness-log is saved to `$T/demo-hlog.md` before gc. README for E0b is E1-08's, per the plan.
- **Known limits (recorded in D-H33):** a `--base <ref>` run is still checked against `origin/main`, as the spec says; Netlify's `exit 1` replaces its own skip for an unchanged base directory; `netlify.toml` alone counts as a host that builds every branch.
- **Proposed change:** none to the list. Question for Michael: should `deploy_check` read the run branch's base (`--base`) rather than `origin/main`? The default stays as the spec says.

### 2026-10-21 15:35 · E1-02 · passes

- **What changed:** `lib/driver.sh`: `resumed` is set before this segment logs `run <id> on …` (an earlier segment's line in `$STATE/run.log`); the start block (`sync_main` + config reload) now runs `if [[ -f $LIST ]] || (( resumed ))`, `merge_milestones` still only with a list. `tests/stub-claude.sh`: `STUB_INIT_LIMIT=1` makes the initializer replay `fixtures/usage-limit.jsonl`, exit 1. `tests/run.sh`: run 15b, check `continue after a no-list end merges main first`. `journal/decisions.md`: D-H32. Tests 168 → 169.
- **Watched failing** before the driver change: `FAIL continue after a no-list end merges main first` (168/169); the log showed `initializer` then `feature list written` with the first `merged main into harness/nolist` only after feature A. My first awk took the *last* merge line (also red after the fix); it now takes the first of each, and I re-ran it on both runs' logs: old driver exit 1, new driver exit 0.
- **Verified:** `bash -n` on the three files; `check.sh` green in 265 s, 169/169, including `resume reloads config merged from main` (run 15).
- **Next session must know:** the check copies `ended` to `$T/run15c.ended` before the continue (the continue rewrites it). Later checks gc the `nolist` worktree, so inspect it with `KEEP=1` and before gc. Docs (architecture/README) for E0 are E1-08's, as the plan says.

### 2026-10-21 15:10 · E1-01 · passes

- **What changed:** `docs/plans/2026-10-21-E1-telemetry.md` (new, base `07c8367`), 12 numbered sections: owners per file/feature, E0 (a `resumed` flag read from run.log *before* this segment's `run <id> on` line; the start block's `sync_main` + config reload run for a resumed run with or without a list), E0b (`lib/deploy.mjs` pure guards + `lib/deploy.sh`, vercel.json JSON merge, netlify `[build] ignore` for `harness/*`, origin/main read at run start, once per run via `$STATE/deploy-checked`, stub-gh deployments fixture), fixture capture command and fields, metrics keys, summary formulas, ledger + `trends --by version`, 17 check names, D-H32/33/34. No code. Tests 168 → 168.
- **Verified:** `head -1` = `Milestone base: 07c8367…`; `git status` shows only the plan; `check.sh` green, 168/168 checks passed.
- **Next session must know:** tokens combine by **max** (like cost), taken from `modelUsage` (fallback `usage`); E1-04 confirms with `Σ modelUsage.costUSD == total_cost_usd` on the capture and switches to sum if not. `orient_s` = null without timestamps. Orientation dedupes assistant events by `message.id`. Stub `ok()` must use `--argjson r "\"$2\""` so `\\n` in PARKED finals still become newlines (§5.4). The default gh-deployments fixture (creator octocat) must *not* count as Vercel, or the demo run logs a guard note.
- **Milestone PR heads** are `harness-merge/<run>-<m>`: the guards don't match them, so each PR still gets one preview.
- **Proposed change:** E1-03's step list doesn't name the check for Vercel detection via the API (`STUB_DEPLOYMENTS=vercel`); the plan adds it (§10).

### 2026-10-21 14:30 · initializer · feature list written (29 features)

**Counts per milestone.** E1 (E0 + E0b + telemetry): 9 · E2 (replay set, `harness eval`): 8 · E3 (prompt hygiene): 5
· E4 (journal + context pack): 7. Order E1 → E2 → E3 → E4 as the brief says; E3 waits only on E1 (the spec's
table), E4 on E3, E4-06 (docs, writes the final `evals/NEXT.md`) on E2 too. Every milestone: plan → builds (pure rules
before wiring, test first) → docs (Sonnet) → review + simplify (Opus, reads the diff from a file in scratch).

**Scope decisions taken here (the brief wins; defaults recorded, nothing parked).**
- `MERGE_POLICY=pr` is the project's config: verified milestones open PRs; Michael merges.
- Evals are built and documented, never run (`evals/NEXT.md` carries the commands). The tags the harness will create
  are predictable: `run/agent-harness-2026-10-21-measure/E2`, `/E3`, `/E4`; NEXT.md uses them as `--harness` refs.
- D-H numbers reserved: D-H32 E0 · D-H33 E0b · D-H34 telemetry (+ harness_version) · D-H35 evals · D-H36 no double
  CLAUDE.md · D-H37 static first · D-H38 clock line + bounded init output · D-H39 journal, single writer · D-H40
  rendered progress.md · D-H41 context pack. The last entry today is D-H31; each plan feature re-checks for collisions
  (the retro-fixes spec may land in parallel and take numbers: if so, shift and say so in the plan).

**Where things live (read before building).**
- `lib/driver.sh` (551 lines): `prompt()` ~line 138 assembles prompts (`render.mjs` + titled sections: brief,
  CLAUDE.md, `.harness/project.md`, policy); `session()` runs `claude -p … --output-format stream-json`; the main loop
  from ~line 455; `verify()` ~line 290 counts `### … verify <m>` headers in progress.md and calls `F evidence` on it;
  `pr_body()` quotes the verify entry from progress.md with awk. `sync_main` today runs only when the list exists
  (`if [[ -f $LIST ]]` ~line 430): that is the E0 bug.
- `lib/metrics.mjs`: `events()`, `outcome()` (cost = max over result events, turns summed), `environmental()`;
  `append` writes the metrics row. `lib/summary.mjs`: `build()` → summary.json, `report()`, `ledger-line`, `trends`,
  `calibration`. `lib/features.mjs`: every list operation (`next`, `repair`, `evidence`, …), header lists the verbs.
- `tests/run.sh` (168 checks, ~4 min): `check "<name>" '<bash expr>'`; runs named `demo`, `walled`, `legacy`, `flip`
  … against `tests/stub-claude.sh` (keys on the prompt's first line; `STUB_*` env vars script misbehaviour; `ok()`
  prints the result event) and `tests/stub-gh.sh` (PRs are files; `pr merge` merges into the bare origin).
  `tests/stub-curl.sh` logs every post to `$T/curl.log`. Helpers: `hlog <run>`, `list <run>`, `curl_count`,
  `on_main`. Fixtures mirror the live API (`tests/fixtures/usage-limit.jsonl` is a real 2026-10-17 capture).
- `bin/harness`: subcommand dispatch at the bottom (`case ${1:-help}`), `cmd_init`, `cmd_start` (a worktree from
  `origin/<branch>` when the branch exists, else from `--base`/origin/main), `cmd_continue`. Usage header lines 2–38
  are the help text. `lib/config.sh`: defaults and layers; `weekly_over` reads `USAGE_7D`.
- Prompts: `prompts/{initializer,coding,verify,retro,debrief,desk,supervisor}.md`, policies in `prompts/policy/`.
  The debrief (`lib/debrief.sh`) renders its own prompt in its workspace, not in a worktree.
- Docs: `docs/architecture.md` (§4 state table, §10 configuration + prompt assembly, §11 measurement),
  `journal/decisions.md` (`### D-H<n> · title *(accepted <date>…)*`, finding · choice · rejected), plan files
  `docs/plans/<date>-<milestone>-<topic>.md` starting with `Milestone base: <sha>` (see the 2026-10-19 P1 files).
- The project's suite is `bash tests/run.sh` (`.harness/config.sh`); run `{{CHECK}}` as the prompt says.

**Gotchas.**
- Never touch `~/projects/agent-harness` (the live harness), `~/.local/state/harness`, `ledger/`, `journal/raw/`,
  other `~/worktrees/*`. Eval task sources are read-only: `~/projects/{dj-crate-streaming,portfolio_site}/.harness/runs/`
  exist on main; pathways and hit_list have none on main (`git log --all -- .harness/runs` may find them on branches).
- The stub's result event has no `usage`; E1-04 captures a real one (haiku, about a cent) and makes `ok()` replay it.
  That capture is the one live call in this run; it is the spec's instruction and the fixture rule's requirement.
- `MERGE_POLICY=off` already exists: the eval uses it (the spec's "none"). `gh_url` returns nothing for non-GitHub
  origins, so a local bare origin yields no links and no `gh` calls; set `HARNESS_GH=false` anyway.
- `harness eval run` adds a git worktree of this repo under `/tmp/harness-eval/…`; tests must remove it (`git worktree
  remove`) or the real repo keeps a stale entry. Never let the eval read the real state root in tests
  (`HARNESS_STATE` is set by `tests/run.sh`).
- E3 changes the first line of every prompt; the stub extracts the feature id from it today
  (`# Coding session — \`id\``). Change the stub in the same feature or every run check fails.
- E4: `verify()` and `pr_body()` read progress.md. Render it before those reads, keep the five-column table shape, or
  verification breaks silently (evidence rows counted = 0 → escalation → "not verified").
- Existing check `brief, rules and policy in the prompt` greps `Project rules (CLAUDE.md)`; E3-02 rewrites it.

**Questions for Michael (defaults taken; answer in INBOX.md to change them).**
1. The fixture capture (E1-04) spends about a cent on a real haiku call under a build-only policy. Default: do it,
   once, and record it in D-H34. Say `no capture` to have the builder use the usage fields from a transcript you
   provide instead.
2. Netlify guard shape: default is a `[build] ignore` command in netlify.toml that exits 0 for `harness/*` refs,
   other keys kept. Vercel's is `git.deploymentEnabled { "harness/**": false }` as the spec says.
3. Eval tasks come from dj-crate-streaming and portfolio_site records (and whatever pathways/hit_list keep on
   branches). Default: 8–12 tasks from those, all forced build-only, none needing a live system.
4. `harness trends --by version` columns: runs, passing/total, $/feature, median cache hit rate, median orientation
   tokens, first-attempt rate. Default as listed; change in E1-07's plan section if you want others.
