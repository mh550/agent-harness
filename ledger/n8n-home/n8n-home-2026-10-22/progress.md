# Progress log — run `n8n-home-2026-10-22` (branch `harness/n8n-home-2026-10-22`)

What this file is: the shared memory of the agent harness for this run. Each session appends one entry **at the top**
(newest first) when it finishes a feature: what it built, what it learned, what it asks. Nobody edits older entries.

How to read the feature list: `.harness/runs/n8n-home-2026-10-22/feature_list.json`. Array order is priority and
dependency order; the harness hands a session the first feature whose `passes` is false and whose `after` is
satisfied. A session may flip only its own feature's `passes`, and only after the suite is green on the committed
tree (before B2 lands, the stand-in is `bash -n` on every `.sh`, `tests/checks/*.sh`, and `docker compose -f
deploy/compose.yml config -q`). Milestones B1–B6 are spec §8's; each starts with a plan feature and ends with a
review feature; when a milestone passes, the harness verifies it and opens a PR (`MERGE_POLICY=pr`: nothing merges
itself).

How Michael steers: edit `.harness/runs/n8n-home-2026-10-22/INBOX.md` on this branch. First line `status: run | pause |
stop`; answers to the questions below go under `## Answers`. Every session reads it at startup. Defaults taken in his
absence are `D<n> *default*` rows in `docs/decisions.md`; he confirms or changes them there.

---

### 2026-10-22 19:40 · B1-01 · not yet

**Same blocker as last session. No code changed.** `docker compose -f deploy/compose.yml config -q` is still denied by `.claude/settings.json`
(`Bash(docker compose:*)`). I didn't route around it: no `docker run docker/compose`, no edit to settings or to the feature list.
**Re-verified on the tree as committed:** `bash tests/checks/compose.sh` 19 PASS / 0 FAIL. Step 5's key diff matches and `grep -c '=.\+'` gives 0.
The B1 plan has all six sections. The live checklist has 14 `Done when:` lines. `bash -n` passes on both `*.sh`. Steps 1, 5 and 6 hold. Steps 2, 3 and 7 can't be checked from a session.
**For Michael:** the question is now **Q1 in INBOX.md** with options (a)/(b)/(c). I recommend (b). Your brief says never park, so I didn't, but no
session can pass B1-01 until you answer. Every retry repeats this entry.
**Proposed change:** if the harness allows it, carry on with B1-02/B1-03 (their `after` is empty) while B1-01 waits.

### 2026-10-22 19:25 · B1-01 · not yet

**Built (all done and verified, except one check).** `deploy/compose.yml` now has the five harness/files bind mounts at host-equal paths: long syntax with
`create_host_path: false` (D11 *default*, new), plus `N8N_RESTRICT_FILE_ACCESS_TO` (the five paths, `;`-joined, without the data dir), the nine D2
keys and `env_file` `required: false`. New: `deploy/.env.example` (7 keys, no values), `docs/plans/2026-10-22-B1-compose.md`,
`docs/plans/2026-10-22-live-checklist.md` (steps 0–12, §7 order, §7a items marked [done]) and `tests/checks/compose.sh`.
**Checks: 0 → 19.** `bash tests/checks/compose.sh` was 6 PASS / 11 FAIL before the change and 19 PASS / 0 FAIL after. Six mutated copies (volume
type, quoted read_only, a second service with docker.sock, an extra mount, an extra sandbox path, a value in `.env.example`) each FAIL as they should.
Step 5's literal grep/diff and `bash -n` on every `*.sh` pass. Compose plugin is 2.40.3, which supports `env_file.required`. An Opus review found
5 Important and 3 Minor issues; all are fixed except "jq in a check" (jq is a system tool on the box, not an npm package).
**Why not passing:** steps 2–3 (and half of 7) require `docker compose -f deploy/compose.yml config [-q]`, and `.claude/settings.json` denies
`Bash(docker compose:*)`. A deny beats any allow, and I did not route around it. A PyYAML parse confirms the structure, but that is not the render.
**Question for Michael (the run stalls on B1-01 until one is done):** (a) run checklist step 0 yourself and flip B1-01 if it shows what the step
says; or (b) in `.claude/settings.json`, replace the deny `Bash(docker compose:*)` with denies on `docker compose -f /srv*`, `-p n8n*`, `up*`,
`exec*`, `run*` and `down*`, and allow `Bash(docker compose -f deploy/compose.yml config:*)`; or (c) change B1-01..B2-01's stand-in from
"`docker compose … config -q`" to "`bash tests/checks/compose.sh`" in feature_list.json. I'd pick (b): later B1 features need the same check.
**Next session must know:** (1) 2.x blocks `process.env` by default (the image's `process-env-access.rule.js`). Whether `$env.KEY` in Set-node
expressions survives that is **unproven**. B2's first rig check must prove it; the plan's Environment section has the fallback. (2) The B1-02
deploy flow needs `/srv/n8n/workflows` visible inside the container for `exec … import:workflow`; it is not mounted yet (plan, Deploy flow step 4).
`tests/checks/compose.sh` asserts exactly six mounts, so update it with the mount. (3) `deploy.sh` should `env -u` the six interpolated keys so
`/srv/n8n/.env` wins over Michael's shell.
**Proposed changes:** (b) or (c) above. B1-02's step list should include adding the workflows mount.

### 2026-10-22 · initializer

**Feature counts:** B1 compose project 4 · B2 test rig 6 · B3 memory 4 · B4 desk report 8 · B5 phone card 6 ·
B6 error workflow + canvas 4 = **32 features**. First up: `B1-01`, `B1-02`, `B1-03`. Rough cost at $2–4.70 per
passing feature (spec §9): $65–150.

**Read before coding, every session:** `CLAUDE.md`; spec `docs/specs/2026-10-22-harness-reporter.md` §0 (scope,
verified facts; §0.2 wins), §4.3 (contracts), and the section for your milestone; `docs/decisions.md` D1–D10 (the
defaults this plan rests on); your milestone's plan in `docs/plans/`. Run A's spec (the harness side of the
contracts: event, request, result, **context bundle shape**, glossary rules) is read with

    gh api 'repos/mh550/agent-harness/contents/docs/specs/2026-10-22-n8n-events.md?ref=spec/2026-10-22-n8n-events' -H 'Accept: application/vnd.github.raw'

never by checking anything out in `~/projects/agent-harness`. Its `context.json` shape: `{v, id, generated_at,
scope: {runs, since}, runs: [{run, project, ended, running, features, paths: {record, worktree, state, report, inbox,
progress}, summary, parked: [{feature, why, question}], open_questions}], glossary: [{id, kind, text, source}],
unresolved: []}`; `context.md` is the gatherer's markdown plus `## Glossary`. The result file the harness writes is
`requests/done/<id>.json` = `{v, id, at, verb, run, ok, exit, output, runner_started, refused}`.

**Where things live (nothing but `deploy/compose.yml` exists yet):**
- `deploy/compose.yml` (B1 extends it), `deploy/.env.example`, `deploy/systemd/` (snapshot timer, not installed).
- `scripts/deploy.sh` (Michael-only; D10), `scripts/n8n-snapshot.sh`, `scripts/sync-code-nodes.mjs` + `scripts/code-nodes.json` (D6).
- `workflows/*.json` deploys; planned files and fixed ids: `10-event-intake`, `20-desk-report` (serving may be
  `21-report-serve`), `30-memory`, `40-phone-card` (answering may be `41-card-serve`), `90-error-handler`. Pick ids
  of 16–24 letters/digits (`HarnessEventIntake01`-style worked in the spike) and keep them forever: the rig and
  `deploy.sh` publish by id. Webhook paths are fixed: `harness-event`, `report-now`, `report`, `report-check`,
  `card`, `card-answer`.
- `tests/run.sh` (the suite; `.harness/check.sh` runs it), `tests/lib.sh`, `tests/checks/*.sh` (one PASS/FAIL line
  per check), `tests/fakes/server.mjs` (+ `responses/`), `tests/unit/*.test.mjs` (`node --test`), `tests/workflows/`
  (test-only workflows, D8). `fixtures/harness/` (sanitised real files), `fixtures/events/`, `fixtures/bundles/`,
  `fixtures/credentials.json`, `fixtures/README.md`.
- `lib/*.js`: Code-node logic as plain functions (D6): `memory.js`, `report.js`, `card.js`.
- Docs: `docs/plans/2026-10-22-<milestone>-<topic>.md`, `docs/plans/2026-10-22-live-checklist.md` (every live step
  for Michael, in order, with `Done when:`), `docs/workflows.md`, `docs/memory.md`, `docs/decisions.md`, `README.md`.

**Verified in a throwaway container on 2026-10-22 (image `docker.n8n.io/n8nio/n8n:2.42.5`, already pulled):**
- `n8n import:workflow --separate --input=<dir>` imports but leaves workflows **unpublished** ("Deactivating
  workflow …"); `n8n update:workflow --all --active=true` is deprecated and does nothing; `n8n publish:workflow
  --id=<id>` publishes (needs n8n not running, or a restart); then `n8n start` → the webhook answers 200 about 4 s
  after `/healthz` is 200 (healthz itself ~6–20 s after start). Run import and publish as separate `docker run --rm`
  invocations on the same data dir, then start the long-lived container (D1). `n8n list:workflow` prints `id|name`.
  Other CLI: `import:credentials`, `export:credentials --decrypted` (use it once to learn the import shape),
  `export:workflow`, `user-management:reset`.
- `--network host` + `N8N_LISTEN_ADDRESS=127.0.0.1` + `N8N_PORT=<random>` works; the container's node user is uid
  1000 = mh550, so a plain `mktemp -d` scratch dir is writable without chmod. Set `N8N_DIAGNOSTICS_ENABLED=false`,
  `N8N_VERSION_NOTIFICATIONS_ENABLED=false`; no owner account is needed for production webhooks.
- Security defaults in the image: `restrictFileAccessTo = '~/.n8n-files'`, `blockFileAccessToN8nFiles = true`,
  `blockFilePatterns` blocks any path with a `.git` segment (worktree `.harness/runs/...` paths are fine). The rig must
  set `N8N_RESTRICT_FILE_ACCESS_TO` to the scratch mounts exactly as the compose does for the live paths.
- Webhook HTML responses are wrapped in a sandboxed iframe (`n8n-core/dist/html-sandbox.js`) whose sandbox is
  `allow-downloads allow-forms allow-modals allow-orientation-lock allow-pointer-lock allow-popups
  allow-popups-to-escape-sandbox allow-presentation allow-scripts allow-top-navigation-by-user-activation
  allow-top-navigation-to-custom-protocols`. Forms and scripts work; the content is `srcdoc`, so **relative URLs
  break: every link and form action must be absolute** (`$env.PUBLIC_BASE_URL`). A check must assert on the body
  text, not on the outer HTML being the report itself.

**Gotchas for workers:**
- Code nodes in 2.x run in a task runner: do not rely on `$env`, `require`, `fs` or `crypto` inside Code. Read
  `$env.*` in a `Config` Set node's expressions and pass values along as fields; read/write files with the Read/Write
  Files from Disk node; make UUIDs with the Crypto node ("Generate") or build ids from `$execution.id` + timestamp
  (the request id regex is `^[A-Za-z0-9-]{8,64}$`). If a Code node does need `$env`, prove it in the rig first.
- Anthropic (spec §0.2): `POST <LLM_BASE_URL>/v1/messages`, headers `x-api-key`, `anthropic-version`; body `model`,
  `max_tokens`, `system`, `messages`, `output_config: {format: {type: "json_schema", schema: {...}}}`; **never**
  `temperature`/`top_p`/`top_k`/`tool_choice`/`thinking` (the fake returns 400 on them, like the real API since
  2026-10-21). Cost at $2/$10 per Mtok from `usage`. Use the HTTP Request node, not the Anthropic Chat Model node.
- Credentials: reference them by **name** (`Anthropic API key`, `ntfy token`); n8n's import re-links by type+name
  when the id is unknown (B2-05 proves it; if it does not, fall back to fixed credential ids in both the fixture and
  the checklist and record the change in `docs/decisions.md` D2).
- Mounting a parent read-only and a child read-write (`~/.local/state/harness` ro, `…/requests` rw) is fine in
  Docker: list the child after the parent.
- `docker compose` is denied for every session (settings deny rule) and must never appear under `tests/`; the rig
  uses `docker run`/`docker rm -f` on `n8n-test-*` names only. Never name `n8n-n8n-1`. `docker compose -f
  deploy/compose.yml config -q` is the one allowed compose use (B1) and needs `env_file: - path: .env  required: false`.
- Fixture sources (read-only): `~/projects/agent-harness/ledger/runs.jsonl` and
  `ledger/<project>/<run>/{summary.json,report.md,progress.md,INBOX.md,feature_list.json,harness-log.md,metrics.jsonl}`
  for `dj-crate-streaming/dj-2026-10-17` (33 features, 4 continuations, "For Michael" INBOX sections, 40
  question-ish lines in progress.md), `dj-crate-streaming/dj-crate-streaming-2026-10-21`,
  `agent-harness/agent-harness-2026-10-21-measure`; the run record also sits at
  `~/worktrees/dj-crate-streaming/dj-2026-10-17/.harness/runs/dj-2026-10-17/`; decision table rows `| D1 | … |` in
  `~/worktrees/dj-crate-streaming/dj-2026-10-17/docs/specs/2026-10-13-next-session-design.md`. No
  `parked.json` exists for ended runs (state dirs hold `attempts.json`, `inbox.md`, `logs/`), so the bundles'
  `parked[]` are shaped from the INBOX/progress questions. A secret scan of the dj ledger dir found nothing, but
  scan what you copy (`ntfy.sh/`, `tk_…`, `sk-ant-`, `ghp_`, emails).
- Tools on the box: node 24.21 (`node --test`, `crypto.randomUUID`), docker 29, sqlite3, jq, python3,
  `systemd-analyze`, firefox, and Playwright's browsers at `~/.cache/ms-playwright/chromium_headless_shell-1248/`
  and `chromium-1248/` (use the binaries directly for screenshots; no npm packages). `n8n-docs` MCP
  (`validate_workflow`, `validate_node`, node docs) is allowed and expected before importing any workflow JSON;
  the instance MCP is read-only.
- Timing: budget the suite at under 4 minutes; wait for files/ntfy with a polling helper and a hard timeout, never a
  bare `sleep`. Every check prints `PASS <name>` or `FAIL <name>: <why>`; the suite ends with `<n> passed, <m>
  failed` and exits 1 on any FAIL.
- Nothing live, ever: no deploy, no `sudo`, no writes under `/srv`, `~/.local/state/harness`, `~/projects`,
  `~/worktrees/*` (other than this worktree), no real ntfy or Anthropic calls. Live steps go into
  `docs/plans/2026-10-22-live-checklist.md` as commands with `Done when:`.

**Questions for Michael (defaults taken, all reversible; see `docs/decisions.md`):**
1. Secrets as n8n credentials matched by name (`Anthropic API key`, `ntfy token`), non-secret config via env (D2).
   Alternative: everything in `.env`. Changing it later touches the HTTP Request nodes and the checklist only.
2. The phone card is a webhook-served HTML form, not an n8n Form node (D5). If you prefer the n8n Form look for the
   application screenshot, say so; only `40-phone-card` changes.
3. Memory as three JSONL files under `/srv/n8n/files/memory/` rather than Data Tables (D3).
4. `scripts/deploy.sh` imports and publishes the workflows and restarts n8n on every deploy (seconds of downtime;
   D10). Alternative: import by hand in the editor.
5. Public-topic mode sends only the run name and a link until you set `NTFY_PRIVATE=true` (D9).
