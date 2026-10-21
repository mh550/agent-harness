# Progress — run `agent-harness-2026-10-21-measure` (agent-harness)

What this file is: the run's log for Michael's phone and for every fresh session. **Newest entry first**, directly
below this header. `feature_list.json` is the plan: array order is priority, `after` is what a feature truly needs,
and the harness gives each session the first feature that isn't passing whose dependencies pass. Steer from
`INBOX.md` on this branch (first line `status: run|pause|stop`; answers under `## Answers`; the harness pulls it
before every session). The brief for this run is `brief.md`; the spec is `docs/specs/2026-10-20-measure-then-memory.md`.

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
