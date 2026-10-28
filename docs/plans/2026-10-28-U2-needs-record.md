# U2 · One needs-you record, cards, `harness needs`, questions with locations: plan

Spec: `docs/specs/2026-10-27-status-ux.md` §U2 items 1–7 and its checks, *Before → after* (`harness needs`), *Defaults
for open questions* 9–15. The event contract: `docs/specs/2026-10-22-n8n-events.md` (event JSON v1). U1 is merged
(`lib/view.mjs`, `lib/status.mjs`, PR #42); lanes P1 and P2 are on main, so every site below is named by function and
file as the code stands at `fc23bf9`, never by line. U2-02 to U2-08 build, U2-09 reviews; this file is U2-01. Nothing
here changes code: the suite is as the init left it (689 checks, green).

Two facts checked for this plan, so the builders needn't re-derive them:

- n8n-home's `4632d1c:.harness/runs/n8n-home-2026-10-22/INBOX.md` is 31 lines, 2504 bytes: the comment opens on line
  2, line 13 reads `## Answers".`, the comment closes on line 14, Q2 starts on line 16 (`**Q2 (B1-05, …`, no `###`
  heading) and line 28 is `## Answers`. Read without touching that checkout (the ground rules forbid git commands in
  another checkout): `git clone -q --no-checkout ~/projects/n8n-home <scratch>/n8n-home && git -C <scratch>/n8n-home
  show 4632d1c:.harness/runs/n8n-home-2026-10-22/INBOX.md > tests/fixtures/inbox-q-in-comment.md`.
- `git merge-tree --write-tree --name-only <ours> <theirs>` on a conflict (git 2.43, this box) exits 1 and prints the
  tree OID, then one conflicted path per line, a blank line, then the `Auto-merging …` / `CONFLICT (content): Merge
  conflict in …` messages. The fixture is that output from a real two-file conflict made in a scratch repo (the
  commands go in the check file's comment); the paths are lines 2 to the first blank line.

## 1. The record (U2-03 writes it, every later feature reads it)

### 1.1 Shape (v1)

One JSON file per item, `<state dir>/needs/<seq>.json`, written to `<seq>.json.tmp` and renamed. Keys in this order
(a check compares the first 13 against the event JSON v1 keys of the n8n spec, in order):

| # | key | value |
|---|---|---|
| 1 | `v` | `1` |
| 2 | `id` | `crypto.randomUUID()`, fixed at open |
| 3 | `at` | ISO 8601 (UTC, `Z`), when first opened |
| 4 | `kind` | `park` · `needs_michael` · `blocked` · `limit` (the v1 enum; never another value) |
| 5 | `project` | the project's directory name (`PROJECT_NAME`) |
| 6 | `run` | the run id |
| 7 | `feature` | the feature id, or `null` |
| 8 | `title` | the notification title (§3.4), sent or not |
| 9 | `body` | the notification body (§3.4): the card at 60 columns, plain (no colour, Unicode glyphs) |
| 10 | `priority` | `high` or `""` |
| 11 | `click` | the GitHub URL of the record's `needs.md` on the record branch, or `null` (no GitHub origin) |
| 12 | `actions` | ntfy's actions header (`notify.mjs actionsHeader`), or `null` |
| 13 | `context` | `null` (the n8n spec's A2 bundle sets it when it exists: default 9) |
| 14 | `ref` | `<run>/<seq>`: stable; what `harness needs done` takes |
| 15 | `key` | `<reason>:<subject>`; unique among the run's open items |
| 16 | `reason` | one of the 15 in §2 |
| 17 | `severity` | `block` · `warn` |
| 18 | `milestone` | the milestone id, or `null` |
| 19 | `seen` | 1 at open; +1 on each refresh |
| 20 | `updated_at` | ISO 8601, the last open or refresh |
| 21 | `card` | §1.2 |
| 22 | `resolved_at` | `null` while open; ISO 8601 once resolved |
| 23 | `resolved_by` | `null` · `sweep` · `michael` (`harness needs done`) |
| 24 | `resolved_why` | `null` · the sweep rule's words (§2, e.g. `feature unparked`, `run removed`) · `--why`'s text (default `done by hand`) |

`seq` is one more than the largest number among `needs/*.json` and `needs/done/*.json`; open runs under the record
lock (§4.1), so two lanes never take one number. A refresh (an open item with the same `key`) rewrites `seen`,
`updated_at`, `title`, `body`, `priority`, `click`, `actions` and `card`; `id`, `at`, `ref` stay.

### 1.2 `card`

| key | type | what |
|---|---|---|
| `headline` | string | one line, no run id (the view prefixes it) |
| `blocked` | string | what waits: the features and milestones, with counts (`B1-05 (B1 live deploy); 29 features wait`) |
| `cost` | string | what waiting costs, one clause (`nothing of B1–B6 merges`) |
| `why` | string | 2 to 4 sentences naming the mechanism and its file (§3) |
| `where` | array | `{path, line, label, url}`: `path` absolute, `line` a number or `null`, `label` a word (`conflict`, `INBOX`, `question`, `log`, `PR`, `worktree`), `url` or `null` |
| `commit` | object | `{main, branch}` short SHAs, either `null` |
| `branch` | string | the branch involved (the lane's, or the record branch), or `null` |
| `question` | object | `parked` only, else `null`: `{file, line, url, text}`; `url` is the blob URL plus `?plain=1#L<line>` |
| `options` | array | `{key, text, recommended, why}`: keys `a`, `b`, `c`; exactly one `recommended: true`, whose `why` says why |
| `commands` | array | full command lines, pasteable (ids never cut) |
| `files_from` | string | `question` (a `Files:` line) · `session` (the fill, U2-08) · `driver` (the driver knew the files) |
| `run_state` | string | `parked` only: parked.mjs's `running:` words (`yes (it takes the answer before its next session)`, `ending (…)`, `no`); `list` recomputes it (§4.3) |

### 1.3 Where things live

- `<STATE_ROOT>/<project>/<run>/needs/<seq>.json`: open items. `needs/done/<seq>.json`: resolved ones (moved by
  rename, `resolved_*` filled). Not on any branch: no record lock is needed to read them, they survive `gc`.
- `<record>/needs.md` (`.harness/runs/<run>/needs.md` on `harness/<run>`): rendered from the open items by
  `needs.mjs md`, rewritten by every `open`, refresh and sweep that changes something, under the record lock,
  committed with the next record commit (`rec_commit`). It is the notifications' `click`. Empty run: one line,
  `Nothing needs Michael in <run>.`. Format: per item `## ⚠ <headline>` (`ref`, since), then each card field as
  `**<label>** <value>`, `where` and `question` as markdown links (`[deploy/compose.yml:48](<url>)`), commands in a
  fenced `sh` block.
- The synthesized items (§2.2) are never stored.

## 2. Reasons, kinds, the openers and the sweep

### 2.1 The 15 reasons

`F blocked` below is `node lib/features.mjs blocked <list> <attempts> <max> [<parked.json>]` (rows
`<id>\t<the given-up or parked feature it waits on>`). Markers are files in the state dir.

| reason | kind · severity · priority | opened by (function, file) | `key` subject | resolved (`needs.mjs sweep`) when |
|---|---|---|---|---|
| `parked` | park · block · high | the park branch of the lane loop (`F park` … `notify_park`), lib/lane.sh | the feature id | the feature is no longer in `parked.json` (unparked), or it passes |
| `given_up` | blocked · block · high | the lane loop after a session whose feature now has `attempts.json[id] >= MAX_ATTEMPTS`, `passes=false`, no park, no escalation round pending, lib/lane.sh | the feature id | `attempts.json[id]` < `$STATE/max-attempts`, or it passes |
| `verify_thin` | needs_michael · block · high | `verify`, its `thin)` arm (`need="verify evidence too thin"`), lib/lane.sh | the milestone | `needs-<m>` is gone, or `verified-<m>` exists |
| `verify_red` | needs_michael · block · high | `verify`, its `red)` arm; `rebase_fail … "suite red after the re-base"` in `rebase`, lib/lane.sh | the milestone | as `verify_thin` |
| `verify_recheck` | needs_michael · block · high | `verify`, its `fail)` arm when `failed` is not empty (the ids → `failed=`); `rebase_fail … "re-base rounds used"` and `rebase`'s `its tag is gone`, lib/lane.sh | the milestone | as `verify_thin` |
| `merge_conflict` | needs_michael · block · high | `merge_one`'s conflict branch (`conflict-<m>`), lib/record.sh; `rebase_fail … "conflicts with main"` and `… "main kept moving"` in `rebase`, lib/lane.sh | the milestone | `merged-<m>` exists, or `conflict-<m>` and `needs-<m>` are both gone |
| `merge_refused` | needs_michael · block · high | `merge_one`'s refusal branch (`refused-<m>`), lib/record.sh | the milestone | `merged-<m>` exists, or `refused-<m>` is gone |
| `main_conflict` | needs_michael · block · high | `sync_main`'s conflict branch, lib/record.sh (from `verify` in a lane; at a resumed start on the record branch) | the lane's milestone (`$LANE`), `record` on the record branch | `main-conflict-<subject>` is gone: written with the `origin/main` SHA on a conflict, removed by `sync_main` when it merges cleanly or main is already in |
| `base_conflict` | needs_michael · block · high | `slot_open`'s three conflict notes (diverged branches, a dependency's tag, the default lane) and `slot_fail`, lib/record.sh | the milestone | `needs-<m>` is gone |
| `feature_list_edits` | needs_michael · block · high | `finish` when its reason is `feature-list edits`, lib/driver.sh | `run` | `ended` is gone (the run was started or continued) |
| `initializer_failed` | needs_michael · block · high | `finish` when its reason is `initializer failed`, lib/driver.sh | `run` | as `feature_list_edits` |
| `driver_crash` | needs_michael · block · high | the EXIT trap of lib/driver.sh when `END_REASON` is still `driver exited unexpectedly (see run.log)` (subject `run`); `reap` in lib/driver.sh for `lane exited unexpectedly` (subject the milestone) | `run`, or the milestone | `run`: `ended` is gone; a milestone: `needs-<m>` is gone |
| `usage_limit` | limit · warn · `""` | `finish` with `usage limit (…)` or `usage limit before the feature list`, lib/driver.sh | `run` | as `feature_list_edits` |
| `weekly_budget` | limit · warn · `""` | `finish` with `weekly budget (…)`, lib/driver.sh | `run` | as `feature_list_edits` |
| `overlap` | needs_michael · warn · `""` | U3 (`harness start`, the queue runner); in the table and the card templates now, no opener in U2 | the other run id | the other branch is merged or gone (U3 fills the rule), or by hand |

Every rule above also holds when **the run is removed**: worktree and record branch both gone → `run removed`.

Stop paths that open **no** record, on purpose: `blocked on …` and `waiting on Michael: …` run ends (the
`given_up`, `parked` and `needs-<m>` items already say it); `unknown POLICY` (the driver exits before any session;
`ended` says it); `deadline`, `session cap`, `stopped by Michael`, `done`, `merge only`, `no feature left to try`
(nothing waits on Michael's action). `cmd_continue` in bin/harness opens nothing: it clears markers and sweeps
(§4.2).

### 2.2 Synthesized items (never stored; `list` only)

- `driver_crash` for a run whose `driver.pid` exists, names no live process, and that has no `ended` (a SIGKILL:
  no trap ran). `key` `driver_crash:run`, `ref` `<run>/crash`, `at` the mtime of `run.log`. Not added when a stored
  `driver_crash:run` is open.
- `parked` for each `parked.json` entry that doesn't pass and has no open `parked:<id>` record: a run parked before
  U2 reached main, and the bridge that keeps `harness parked` whole while U2-04 lands before U2-05 opens records. `ref`
  `<run>/parked:<id>`.

`harness needs done` on a synthesized ref exits 1: `harness: <ref> is derived from the run's state; it resolves when
<the rule>`.

### 2.3 Sweep

`needs.mjs sweep <state dir>…` reads `meta.env` (`WT`, `RUN_ID`) for the record (`<WT>/.harness/runs/<run>/`:
`feature_list.json`) and the state files (`parked.json`, `attempts.json`, `max-attempts`, markers, `ended`), applies
the rules of §2.1 to each open item, moves the resolved ones to `needs/done/` with `resolved_by: "sweep"` and the
rule's words, and re-renders `needs.md` when anything moved. Called:

- lib/lane.sh, in the loop right after `F unpark` (each pick) — `needs_sweep`;
- lib/driver.sh, in the coordinator right after its `F unpark`, and in `finish` right after it writes `ended` (so a
  finish item opened below is never swept by its own finish);
- bin/harness `cmd_continue`, after the `rm -f … needs-* …` and the `ended` removal, before `cmd_start` (so the run's
  `feature_list_edits` … `driver_crash` items resolve with `run continued`); also when `--keep-attempts` skipped the
  marker clear (then only `ended`'s rules fire);
- `harness gc` after it removes a run's worktree and branch (so `run removed` lands without a later driver).

`list` applies `run removed` in memory as well (read-only): a run Michael removed by hand never shows.

## 3. Cards (U2-04): one template per reason, data in `lib/needs.mjs`

A template is `{ headline, blocked, cost, why, where, options, commands }` of functions of the facts (§4.1). `why` is
2 to 4 sentences; it names the mechanism and its file. Placeholders: `<m>` milestone, `<id>` feature, `<run>`, `<wt>`
the worktree (lane slot or record), `<b>` the branch, `<n>` counts from `waits`. Every `blocked` is built the same way:
`<subject> (<its description, cut at 40>); <n> features wait` (+ `in <milestones>` when the waits span milestones;
`nothing else waits` when `waits` is empty).

| reason | headline | cost | why (template) | where | options (★ = recommended) | commands |
|---|---|---|---|---|---|---|
| `parked` | `<id> parked` | `<id> and what waits on it stay unbuilt until you answer` | — (the `question` field replaces it) | the question's `Files:` paths with lines (`files_from: question`), else the session's (U2-08), then `INBOX.md:<line>` | (a) answer in INBOX.md or with `harness answer` ★ (the session asked for exactly this) · (b) leave it parked: other features go on | `parked.mjs commandsFor(run, state)`, unchanged |
| `given_up` | `<id> given up after <n> attempts` | `<n> features wait behind it` | `Each feature gets MAX_ATTEMPTS (<n>) fresh sessions (the lane loop in lib/lane.sh, attempts in attempts.json). <id> used them without passing; the features after it wait (F blocked in lib/features.mjs). Its sessions' entries say what failed.` | `progress.md`, the last session's log (`$STATE/logs/<nn>-<id>.jsonl`) | (a) read its entries, fix or reword the feature, `harness continue` (fresh attempts) ★ (a continue resets attempts) · (b) a brief that drops or splits it, then continue · (c) leave it: the run ends `blocked on <id>` | `harness report <run>` · `harness continue <run>` |
| `verify_thin` | `<m> not verified: evidence too thin` | `<m> doesn't merge; <n> features wait` | `After <m>'s features pass, a verify session re-runs every step and writes an evidence row per step (verify in lib/lane.sh); too few rows after the escalated model means not verified. The features pass; only the evidence is short.` | `progress.md` (the verify entry), the verify log | (a) read the verify entry; if the steps hold, `harness continue` re-verifies ★ (usually a step the verifier couldn't run) · (b) fix the step wording by a brief, continue | `harness continue <run>` |
| `verify_red` | `<m> not verified: suite red on the merged tree` | as above | `The verify merges origin/main into the lane first (sync_main in lib/record.sh), so the suite runs on the tree that would land; it was red there (green in lib/record.sh). Main's newer commits and <m> disagree.` (rebase variant: `after the re-base onto main (rebase in lib/lane.sh)`) | `<wt>`, `check.out` of the lane's scratch, `harness-log.md` | (a) run the suite in `<wt>`, fix, push, continue ★ · (b) continue as is (a flake) | `cd <wt> && <suite>` · `harness continue <run>` |
| `verify_recheck` | `<m>: <ids> failed the re-check` | as above | `The verifier un-passes a feature whose steps don't hold, and the lane retries it once per verify round (MAX_VERIFY_ROUNDS, verify in lib/lane.sh). <ids> failed in the last round.` (variants: the re-base round used; the tag gone) | `progress.md`, the feature list | (a) read the verify entry, fix by a brief, continue ★ · (b) continue as is (fresh attempts) | `harness continue <run>` |
| `merge_conflict` | `<m> conflicts with main (<n> files)` | `<m> doesn't merge; <n> features wait` | `Verified milestones merge into main through a PR (merge_one in lib/record.sh) only when git merge-tree finds no conflict. main moved since <m> was verified and both sides change the files below.` (re-base variant: `rebase in lib/lane.sh`) | the conflicted files (merge-tree `--name-only`) in `<wt>`, compare URL | (a) merge main into `<b>` by hand, resolve, push, `harness merge <run>` ★ (verified work is kept) · (b) a new run from main whose brief names `<b>` · (c) leave it | `cd <wt> && git merge origin/main` · `harness merge <run>` |
| `merge_refused` | `<m>: the merge was refused` | `<m>'s PR is open; <n> features wait` | `merge_one in lib/record.sh asks gh to merge the PR at the verified commit (--match-head-commit); GitHub refused (a branch rule, a check, or the head moved). The PR is open.` | the PR URL (`label: PR`), `run.log` | (a) open the PR, merge it there ★ (the cause is on GitHub) · (b) `harness merge <run>` after fixing the rule | `gh pr view <url>` · `harness merge <run>` |
| `main_conflict` | `main conflicts with the run branch (<n> files)` | `no milestone of this run can merge; <n> features build on a base main has moved past` | `Before each verify the driver merges origin/main into the run branch (sync_main in lib/record.sh), so the tree that is verified is the tree that lands. main gained <runs and milestones>, and both sides change <files>; the driver aborted the merge and carried on.` | the conflicted files in `<wt>`, `main <sha> · branch <b> @ <sha>`, compare URL | (a) merge main into the branch by hand, resolve, push, continue ★ (when the branch holds passing unmerged features) · (b) stop it; a new run from main whose brief names the branch · (c) leave it: sessions go on, nothing merges | `cd <wt> && git merge origin/main` · `harness continue <run>` |
| `base_conflict` | `<m> can't open: its base conflicts (<with>)` | `<m> and <n> features wait` | `A lane starts from main plus every dependency's verified tag main lacks (slot_open in lib/record.sh); merging <with> into it conflicted, so the lane never opened.` (variants: diverged local and origin branch; the slot couldn't be checked out) | the slot `<wt>`, `run.log` | (a) merge `<with>` into `<b>` by hand, push, continue ★ · (b) wait for `<with>` to merge into main, then continue | `cd <wt> && git merge <with>` · `harness continue <run>` |
| `feature_list_edits` | `stopped: sessions kept editing the feature list` | `the run ended; <n> features unbuilt` | `A session may only flip its own passes (F repair in lib/features.mjs restores the rest); MAX_REPAIRS sessions in a row did more, so the lane stopped the run (lib/lane.sh).` | `harness-log.md` (the `restored the feature list` notes), `feature_list.json` | (a) read the notes; a brief that says what the sessions wanted; continue ★ · (b) change the list's wording in a new run | `harness continue <run>` |
| `initializer_failed` | `stopped: the initializer wrote no valid feature list` | `nothing was built` | `A run starts with one initializer session that writes feature_list.json from the spec (the driver's first step, lib/driver.sh); its output didn't parse (F summary).` | the init log (`$STATE/logs/00-init.jsonl`), the spec files | (a) read the init log, fix the spec or brief, continue ★ · (b) write the list by hand on the record branch | `harness continue <run>` |
| `driver_crash` | `the driver stopped without an end` (`lane <m> exited unexpectedly`) | `the run is not going; <n> features unbuilt` | `The driver records why it ended (finish in lib/driver.sh); its EXIT trap wrote the default reason, or (synthesized) no trap ran at all (a SIGKILL). run.log's last lines say what it was doing.` | `run.log` | (a) read run.log's tail, then `harness continue` ★ (state is kept) · (b) leave it | `tail -50 <state>/run.log` · `harness continue <run>` |
| `usage_limit` | `ended on the usage limit` | `<n> features left; nothing runs until it continues` | `<k> sessions in a row were refused (MET limit in lib/metrics.mjs; MAX_LIMIT_HITS), so the run ended rather than wait (lib/lane.sh).` | `run.log` | (a) continue once the window resets ★ · (b) queue it: `harness queue add --continue` | `harness continue <run>` |
| `weekly_budget` | `ended on the weekly budget` | as above | `Past WEEKLY_STOP_AT of the 7-day window (weekly_over in lib/config.sh), the run ends before its next session.` | `run.log` | (a) continue after the window ★ · (b) raise WEEKLY_STOP_AT | `harness continue <run>` |
| `overlap` | `<run> and <other> change the same files` | `the second to merge will conflict` | `harness start compares the branches' changed files (U3).` | the shared files | (a) let the first merge, then continue the second ★ · (b) stop one | `harness status <other>` |

Merge subjects (`main_conflict`'s `<runs and milestones>`, a pure export `mergedBy(subjects, ownRun)`): each line of
`git log --merges --format=%s <merge-base>..origin/main -- <files>`; `^Merge pull request #(\d+) from [^/]+/harness-merge/(.+)-([A-Z]{1,2}\d+)$`
→ run, milestone, PR; the run's own are left out; one run's milestones collapse when consecutive
(`agent-harness-2026-10-25-memory M1–M5 (PRs #32–#36)`), else are listed (`M1, M3 (PRs #32, #34)`); a single one is
`agent-harness-2026-10-25-memory M3 (PR #34)`; any other merge subject is `PR #<n>`; none parsed → `new commits`.

URLs (`notify.mjs urls` and a new `compare <origin> <base> <branch>` → `https://github.com/<o>/<r>/compare/<base>...<branch>`):
a file in a lane slot → its blob URL on the lane branch `#L<line>`; the question → the record branch's INBOX.md
`?plain=1#L<line>`; no GitHub origin → every `url` `null`.

Fixtures: `tests/fixtures/needs/<reason>.json`, 15 files, each the facts object of §4.1 for one case (real-shaped
paths under `/home/u/…`, the n8n-home Q2 for `parked`, the four lanes-run files and the merge subject
`Merge pull request #34 from mh550/harness-merge/agent-harness-2026-10-25-memory-M3` plus #32, #33, #35, #36 for
`main_conflict`).

### 3.1 The text view (`harness needs`, U2-04)

`view.mjs` gains two things: `card(header, fields, ctx, { rule = true })` (no rule between cards of one section) and
`cutFront(s, n, ctx)` (`…/file:line`: at narrow width a path keeps its end). Per item:
`<glyph> <run> · <headline> · since <HH:MM> (<ago>) · <ref>` (narrow: `<glyph> <run> · <headline> · <ago>` and a
`ref` field), then `blocked`, `question` (parked) or `why`, `where` (home as `~`; narrow: `cutFront`), each URL on its
own line, `options`, `do` (the commands, wrapped only at a space or `/`), `run` (parked: `run_state`). Section
`NEEDS YOU <n> · <runs> runs`, block before warn, oldest first; `--all` adds resolved ones from the last 7 days, dim,
`resolved <when> by <who>: <why>`. Footer: `done by hand: harness needs done <ref> · resolved too: harness needs --all`.
Nothing open: `NEEDS YOU 0` and `nothing needs you` (`nothing needs you in <run>` with a run).

### 3.2 The notification bodies (unchanged where checks read them)

| reason | title | body | click | priority | actions |
|---|---|---|---|---|---|
| `parked` | `[<run>] <id> needs you` (today's) | `PARKED: <why>`, blank, the question verbatim (today's `$LS/question`), blank, the card's `blocked`/`where`/`do` at 60 columns, blank, `Answer: harness answer <run> "…"` | `needs.md` | high | today's: Edit INBOX, Answer with Claude (DESK_URL), Progress |
| verify / merge / base / main | `[<run>] <m> needs you` (today's) | the card at 60 columns | `needs.md`; `merge_refused`: the PR (today's) | high | Compare (main/merge conflicts), Progress |
| finish reasons, `driver_crash`, `given_up` | `[<run>] ended: <reason>` (the run-end notification's title, kept) | the card | — | as §2.1 | — |

Who sends: the park and the needs-you paths only, as today (`notify_park`, `needs_you`, `merge_one`'s refusal,
`sync_main` new). `given_up`, the finish reasons and `driver_crash` are **not** notified on their own: the run-end
notification still carries them (default; §8 Q1). The once-only rules stay today's guards, not `open`'s exit code:
`conflict-<m>` (once per main), `refused-<m>` (once per tag commit; `harness merge` always), and the new
`main-conflict-<subject>` (once per `origin/main` commit). `open`'s exit 3 decides only where no guard exists (none
today: a park always notifies).

## 4. The code

### 4.1 `lib/needs.mjs` (U2-03; cards U2-04)

Usage header; imports `node:` built-ins and the harness's pure modules `./view.mjs`, `./inbox.mjs`, `./notify.mjs`
(no others). Pure exports: `REASONS` (the §2.1 table as data), `record(facts, now)`, `refresh(old, facts, now)`,
`sweep(items, state)` → `{keep, resolved}`, `synthesize(state)` → items, `card(reason, facts)`, `mergedBy(lines, run)`,
`renderCard(item, ctx)`, `renderList(items, ctx, opts)`, `markdown(items, run)`. CLI:

- `open <state dir> <run> <project> <reason> <subject> key=value…` → prints the ref; 0 new · 3 refreshed · 1 bad
  reason or facts (stderr `needs.mjs: …`). Writes `needs/<seq>.json` (tmp + rename) and `<record>/needs.md`.
- `sweep <state dir>…` → 0; prints `resolved <ref> (<why>)` per item (the shell notes them).
- `done <state dir> <ref> [--why <text>]` → 0 and `resolved <ref>`; 1 for an unknown, resolved or synthesized ref.
- `list <state dir>… [--all] [--json] [--run <id>]` → the view or the JSON array (block before warn, oldest first).
- `card <reason> <facts.json>` → the card JSON (the unit checks' entry point).
- `md <state dir>` → `needs.md`'s text; `fields <state dir> <ref>` → `title\0body\0click\0priority\0actions` for the
  shell's `notify`.

**Facts** (`key=value…`, all strings; lists newline-separated): `feature`, `milestone`, `list` (the record's
`feature_list.json`), `record` (the record dir), `inbox`, `worktree`, `branch`, `record_branch`, `main_branch`,
`origin` (remote.origin.url), `waits` (feature ids), `why` (a park's), `attempts`, `max_attempts`, `files`, `main`
(SHA), `head` (SHA), `subjects` (merge subjects), `pr` (URL), `with` (the conflicting dependency/branch), `failed`
(ids), `end_reason`, `variant` (`rebase`, `diverged`, `slot`, `moving`, `tag`), `log` (a log path).

### 4.2 `lib/needs.sh` (U2-03), the shell side

```bash
# Usage: source lib/needs.sh; needs_open <reason> <subject> [key=value…] · needs_notify <ref> [<message>] · needs_sweep
#        · needs_waits <feature|milestone>   (needs run_paths' STATE RUN_ID PROJECT_NAME LIST REC RWT RBRANCH, record)
NEEDS_MJS=$HARNESS_HOME/lib/needs.mjs
needs_open() {   # → the ref on stdout; 0 new, 3 refreshed (the caller's guard decides the notification), 1 failed (noted)
  local r=$1 s=$2; shift 2
  record node "$NEEDS_MJS" open "$STATE" "$RUN_ID" "$PROJECT_NAME" "$r" "$s" \
    milestone="${LANE:-}" list="$LIST" record="$REC" inbox="$REC/INBOX.md" worktree="${HARNESS_WT:-$RWT}" \
    branch="${LBRANCH:-$RBRANCH}" record_branch="$RBRANCH" main_branch="$MAIN_BRANCH" \
    origin="$(git config --get remote.origin.url)" waits="$(needs_waits "$s")" "$@"
}
```

`LANE` is empty on the coordinator (`milestone=` then comes from the caller, e.g. `reap`'s `$m`); a later
`key=value` overrides an earlier one. A failed open is `note "needs: could not record <reason> <subject> (exit <n>)"`
and the run goes on (a record never stops a run). `needs_waits`: for a feature, `F blocked "$LIST" "$ATT"
"$MAX_ATTEMPTS" "$PARKED"` rows whose second field is it; for a milestone, the non-passing ids of every milestone whose
`F deps` reach it (closure in a bash loop); for `run`, every non-passing id. `needs_notify <ref>` reads `fields` and
calls `notify` with them. Sourced by lib/driver.sh, lib/lane.sh and bin/harness (which uses only `needs.mjs`
directly: it has no `record`).

The calls, with the bash variables each passes (U2-05, U2-06):

| site | call |
|---|---|
| lane.sh park branch, before `rec_commit "HARNESS: after $id"` | `ref=$(needs_open parked "$id" feature="$id" why="$why")`; `notify_park` after `sync_record` sends `needs_notify "$ref"` |
| lane.sh, given up (same place, `passed=false`, no park) | `needs_open given_up "$id" feature="$id" attempts="$(jq -r --arg id "$id" '.[$id]' "$ATT")" max_attempts="$MAX_ATTEMPTS" log="$slog"` |
| `verify`, before `rec_commit "HARNESS: verify $m"` | `needs_open verify_<thin\|red\|recheck> "$m" milestone="$m" failed="${failed[*]}" variant="${mode}"` |
| `rebase_fail` (via a 5th argument naming the reason) | `needs_open <reason> "$1" milestone="$1" variant=rebase head="$2"` |
| `merge_one` conflict, before its `rec_commit` | `needs_open merge_conflict "$m" milestone="$m" files="$(git merge-tree --write-tree --name-only "origin/$MAIN_BRANCH" "$c" \| sed -n '2,/^$/p')" main="$mn" head="$c"` |
| `merge_one` refusal | `needs_open merge_refused "$m" milestone="$m" pr="$url" head="$c"` (+ `rec_commit` before its notify) |
| `sync_main` conflict, before `merge --abort` | `files=$(git diff --name-only --diff-filter=U)`, `subjects=$(git log --merges --format=%s "$(git merge-base HEAD origin/$MAIN_BRANCH)..origin/$MAIN_BRANCH" -- $files)`; after the abort `needs_open main_conflict "${LANE:-record}" files="$files" subjects="$subjects" main="$(git rev-parse origin/$MAIN_BRANCH)" head="$(git rev-parse HEAD)"` |
| `slot_open` conflicts, `slot_fail` | `needs_open base_conflict "$m" milestone="$m" with="<origin/$b \| $dep \| default>" variant="<diverged\|dependency\|default\|slot>"` |
| `reap` (`lane exited unexpectedly`) | `needs_open driver_crash "$m" milestone="$m" log="$STATE/run.log"` |
| `finish`, after `ended` and `needs_sweep` | `case $1 in "feature-list edits"*) r=feature_list_edits ;; "initializer failed"*) r=initializer_failed ;; "usage limit"*) r=usage_limit ;; "weekly budget"*) r=weekly_budget ;; esac; needs_open "$r" run end_reason="$1"` |
| EXIT trap | `[[ $END_REASON == "driver exited unexpectedly (see run.log)" ]] && needs_open driver_crash run log="$STATE/run.log"` (fd 9 is closed there first, so `record` locks afresh) |

### 4.3 `bin/harness`

- `harness needs [<run>] [--all] [--json]`: the `cmd_parked` loop over `$STATE_ROOT/*/*/` (meta.env, no
  `harness_config`, no `mkdir`) → `node lib/needs.mjs list <state dirs…>` with the runner/queued/running facts the
  parked report takes today (parked cards' `commands` and `run_state` are recomputed from them). Read-only; exit 0.
  `harness needs done <ref> [--why "<text>"]`; `harness needs nope` → exit 1, `harness: no run nope`.
- `harness parked [<run>]` = `harness needs` for text. `harness parked --json` = `parked.mjs report --json` as today,
  each element joined with its open (or synthesized) record's `ref` and `card` (`needs.mjs list --json` piped in).
- `cmd_continue`: `node lib/needs.mjs sweep "$STATE"` after the marker clear (§2.3). `cmd_gc`: the same, after a
  removal.

### 4.4 `lib/inbox.mjs` (U2-02)

Usage header; pure exports, `node:` built-ins only:

- `answersLine(text)` → the 0-based index of the first line equal to `## Answers` (trailing spaces/tabs allowed)
  outside an HTML comment (a `<!--` without `-->` runs to the end); `-1` if none. On the fixture: 27 (line 28).
- `question(text, feature)`: parked.mjs's `questionFor`, cut at `answersLine`, comments removed before the section
  search (as today).
- `questionLine(text, feature)` → the 1-based line in `text` where `question`'s first line is (for the card's
  `question.line` and URL), or `null`.
- `added(before, after)`: notify.mjs's `inboxQuestion`, cut at `answersLine` (both sides).
- `answers(text)` → the text from `answersLine` to the end, **byte-identical** to `sed -n '/^## Answers/,$p'` on every
  INBOX whose first `^## Answers` line is the real one (a unit check hashes the driver's template both ways), so
  `answers_hash` (lib/record.sh) can switch without unparking a single run.
- `insert(text, q)` → `text` with `q` and a blank line above `answersLine` (`take_question_`'s inline node, moved).
- `files(text)` → `[{path, line}]` from `Files:` lines (`Files: /abs/a.sh:48, /abs/b.md`), used by U2-05 and U2-08.
- `repair(before, after)` → `{text, changed, moved}`: the steering comment is the first `<!--`…`-->` of `before`; if
  `after`'s first comment differs, the inserted text is the character span between their longest common prefix and
  suffix (a session that split a line, like n8n's Q1, is undone exactly), trimmed of blank lines; the comment goes back
  to `before`'s bytes and the span goes above `answersLine` of the result.
- CLI: `repair <before> <after>` (rewrites `<after>`; exit 3 changed, 0 not), `answers <file>`, `insert <file>`
  (the question on stdin), `question <before> <after>` (today's `notify.mjs question`, which stays as an alias).

Call sites: `lib/parked.mjs` imports `question`; `lib/notify.mjs` imports `added` (its `inboxQuestion` stays an
exported name); `answers_hash` and `take_question_` (lib/record.sh) call the CLI. The repair runs where the session
wrote: **the session's copy** (`$SLOT/$RUN_DIR/INBOX.md` against `$LS/inbox-before.md`) in lib/lane.sh right after the
session and before `take_question`, so what reaches the record's INBOX.md is the clean question; and the record's
`INBOX.md` after the initializer (it runs in the record worktree; `inbox-before.md` is saved before it). On exit 3:
`note "INBOX.md: <id>'s question was inside the steering comment (hidden on GitHub); moved below it"`. The driver's
heredoc comment says `write answers under the Answers heading at the end of this file`.

### 4.5 Readers (U2-07)

`lib/status.mjs`: `needsItems` reads the records (`list`'s items, via an import of `needs.mjs`), its derived rows go;
the status card's `needs you` field gives the count and headlines. `prompts/desk.md`: `COLUMNS=60 harness needs
{{RUN_ID}}` for `harness parked {{RUN_ID}}` (and `harness needs <run>` for the per-run line). `skills/harness-answer/
SKILL.md` step 1: `harness needs` (`harness parked` its alias). `lib/debrief.sh` `run_context`: a `#### needs` block
from `COLUMNS=80 "$H" needs "$RUN_ID"` right after `#### harness status`. `lib/desk.sh`'s `Or by hand: harness parked
<run>` stays (the alias).

### 4.6 The fill (U2-08)

`lib/entries.mjs` at ingest: a question (entry `questions[]`) with no `Files:` gets ` Files (harness, from the
session): <paths>` appended: the entry's `files` first, then `git diff --name-only <session start> HEAD -- .
':!.harness/runs'`, absolute (the worktree joined), deduplicated, at most 8. The park card: a section without
`Files:` gets the same list as `where` with `files_from: "session"`. One `note "<id>: <n> question(s) had no Files:
line; filled from the session's diff"`.

## 5. Checks and fixtures

### 5.1 New files (one per topic; 56 is taken by U1's review)

| file | feature | what | ≈ checks |
|---|---|---|---|
| `tests/checks/57-inbox.sh` | U2-02 | unit: `answersLine` 27 on the fixture, `question(…, "B1-05")` starts `**Q2 (B1-05` without `<!--`, `added` on an in-comment pair, `repair` restores the comment byte for byte and puts the question above `## Answers`, `answers` hash equal to sed's on the template; one stub run (`STUB_INBOX_IN_COMMENT=A`) for the note and the record's INBOX | 8 |
| `tests/checks/58-needs-record.sh` | U2-03 | the 13 keys, `kind` enum, open twice (0 then 3, `seen: 2`), the REASONS table row per reason, `ref`, sweep per reason on `needs_fixture` dirs (open → resolved), `run removed`, synthesized `driver_crash` and `parked`, `harness needs --json` order, `needs done`, read-only (`find -newer`), `needs nope` | 14 |
| `tests/checks/59-needs-cards.sh` | U2-04 | a card per reason from its fixture (every field filled, no `undefined`, non-empty `why`, one recommended, non-empty `commands`), `mergedBy` single/collapse/own-run-out, `urls compare`, `COLUMNS=60` no line over 60 but URLs, `harness parked --json` keys + `ref`, `card` | 20 |
| `tests/checks/60-needs-driver.sh` | U2-05 | stub runs: park → one record, `question.line`, body `PARKED:` with `do`, `needs.md` committed, `Click:` it; given up → `given_up` with waits, listed by `needs` and `parked`; SIGKILL → synthesized `driver_crash`; `needs done`; `continue` → `done/` | 8 |
| `tests/checks/61-needs-git.sh` | U2-06 | stub `main` commit on the run's file → `main_conflict` (file in `where`, the stub subject's run in `why`), 1 high notification over 2 verifies, resolved after a clean `sync_main`; `merge_one` conflict and refusal records (PR URL); `verify_thin` under `[<run>] M1 needs you` | 7 |
| `tests/checks/62-needs-readers.sh` | U2-07 | status NEEDS YOU and `--json needs` from records, the desk prompt line, the skill's first step, the debrief's `#### needs` block | 5 |
| `tests/checks/63-question-locations.sh` | U2-08 | the prompt text, the entries fill (the rest byte for byte), stub session fill + note, a park's `Files: <path>:48` → `where[0].line` 48 | 5 |

Fixtures: `tests/fixtures/inbox-q-in-comment.md` (§ top, byte for byte), `tests/fixtures/merge-tree-name-only.txt`
(§ top), `tests/fixtures/needs/<reason>.json` × 15 (§3). The per-reason **fixture state dirs** are built, not checked
in (they hold absolute paths): `needs_fixture <reason> open|resolved` in tests/lib.sh writes a state dir with
`meta.env`, a record with `feature_list.json`, one `needs/1.json` and the markers of §2.1 for that state (e.g.
`parked`: `parked.json` with A / without; `main_conflict`: `main-conflict-M1` / none; `driver_crash`: `ended` / none).
New stub flags: `STUB_INBOX_IN_COMMENT=<id>` (tests/stub-claude.sh: the session inserts its question mid-line in the
comment, as n8n-home's Q1), `STUB_GIVE_UP=<id>` if `STUB_LENIENT`-less failing doesn't already give one up (check
first), `STUB_MAIN_TOUCH=<path>` in tests/stub-gh.sh or the check itself (a commit on the origin's main before verify).

### 5.2 Existing checks U2 touches (intent kept)

| check (file) | feature | change |
|---|---|---|
| the three `parked.mjs:` checks (03-) | U2-02 | none: `questionFor` stays exported, on `inbox.mjs`'s cut |
| `harness parked: id, why, question, both commands` (13-) | U2-04 | reads the card: `parky · B parked`, the question line, `harness answer parky` and `harness continue parky` |
| `with a queue runner going, the continue command is a queue add`, `a run still ending: …`, `a run still going: only the answer command` (13-) | U2-04 | `running:  …` → the card's `run` field words; the `--json` halves unchanged |
| `harness parked is read-only`, `harness parked --json parses`, `… unknown or glob run id is an error` (13-) | U2-04 | none |
| `a park notification: title, question, answer command, click and Edit INBOX action` (13-) | U2-05 | the `Click:` assertion reads `…/parky/needs.md`; every other line unchanged (§8 Q3) |
| `no URLs for a non-GitHub origin`, `a failed park post …`, `the park goes out after …` (13-) | U2-05 | none |
| `verify needs Michael: priority high, click = progress.md (GitHub-shaped origin)` (13-) | U2-06 | click → `…/strict/needs.md`; renamed `… click = needs.md …` (the names fixture too) |
| `a refused merge tells Michael and his desk once`, `harness merge says it was refused again …` (13-) | U2-06 | none (the guards stay) |
| the thin-verify check (17-) | U2-06 | none |
| `the desk prompt names the run, its commands and the never-list` (13-) | U2-07 | `harness parked parky` → `harness needs parky` |
| `the answer skill exists and names the commands …` (13-) | U2-07 | adds `harness needs` |
| `--dry-run prints the context, launches nothing` (15-) | U2-07 | finds `#### needs` |
| 53-/54-/56- status checks on the parked, given-up, crashed runs | U2-07 | `status_stubs` writes records (via `needs.mjs open`) where it wrote markers; assertions unchanged |

Every new name goes in `tests/fixtures/check-names.txt` (LC_ALL=C sorted); a renamed one replaces its line.

## 6. Order, and the suite after each

| feature | builds | suite after (≈) |
|---|---|---|
| U2-02 | `lib/inbox.mjs`, parked/notify/record.sh on it, the repair (lane + initializer), the heredoc, `STUB_INBOX_IN_COMMENT`, 57-; starts decision `2026-10-27-question-locations` | 697 |
| U2-03 | `lib/needs.mjs` (record, refresh, sweep, synthesize, open/sweep/done/list/md/fields), `lib/needs.sh` sourced (no caller), `harness needs --json` + `done`, one-line text, `needs_fixture`, 58-; starts decision `2026-10-27-needs-record` | 711 |
| U2-04 | templates + `card` CLI, 15 fixtures, `view.mjs` `cutFront` and `card` `{rule}`, `notify.mjs urls compare`, the card view, `parked` alias + `--json` join, the 13- rewrites, 59- | 731 |
| U2-05 | park, given-up, finish, EXIT-trap opens; `needs_notify`; sweeps (lane, coordinator, finish, continue, gc); `needs.md` committed and clicked; 60- | 739 |
| U2-06 | `sync_main` (+ notify once per main, `main-conflict-*`), `merge_one` (+ `conflict-<m>` cleared on a clean tree), `rebase_fail`, verify's three, `slot_open`/`slot_fail`, `reap`; `needs_you` from the record; merge-tree fixture; 61- | 746 |
| U2-07 | status from records, desk, skill, debrief; 62- | 751 |
| U2-08 | prompts (`Files:`, below the comment block, the heading form), the fill (entries.mjs, the park card), 63-; both decision files complete | 756 |
| U2-09 | review from a diff file, fixes red→green, architecture §3 §4 §7 §17, README | +fixes |

U2-02 and U2-03 are independent of each other (both after U2-01); U2-04 needs U2-03; U2-05 needs U2-02 and U2-04.
The full suite runs ~8 min on this box at TEST_JOBS=4 with other lanes loaded and flakes timing-bound e2e checks:
`TEST_JOBS=2 HARNESS_CHECK_TIMEOUT=25m` is the way to a green full run (U1's discoveries).

## 7. Decisions taken here (defaults; recorded in `2026-10-27-needs-record` from U2-03)

1. `main_conflict`'s key subject is the lane's milestone (`record` on the record branch), not the `origin/main`
   commit: a key per commit would leave one open item per main commit. Once per main commit is the marker
   `main-conflict-<subject>`'s job, as `conflict-<m>` does for `merge_one`.
2. Today's once-only guards decide the notifications; `open`'s exit 3 only refreshes the record.
3. `given_up`, the finish reasons and `driver_crash` get no notification of their own; the run-end notification
   carries them.
4. Notification click: `needs.md` for every needs-you item, the park's included (`merge_refused` keeps the PR).
5. The INBOX repair runs on the session's copy (the slot's) before `take_question`, and on the record's INBOX.md after
   the initializer: with lanes, sessions never write the record's INBOX.md, so that is where the comment breaks.
6. `parked.json` entries without a record are synthesized as `parked` items (the U2-04/U2-05 order, and runs parked
   before U2 reached main).
7. `needs.mjs` may import the harness's own pure modules (`view.mjs`, `inbox.mjs`, `notify.mjs`), not only `view.mjs`.
8. Run-level items resolve when `ended` is gone (`cmd_continue` removes it before its sweep), not when a driver
   starts: the driver may never start after a refused continue.
9. Unmapped stop paths in the spec's table, mapped here: `rebase_fail`'s five causes (conflict and main kept moving →
   `merge_conflict`; suite red → `verify_red`; rounds used and tag gone → `verify_recheck`), `slot_fail` →
   `base_conflict`, a lane that died → `driver_crash` with the milestone as subject.

## 8. Questions for Michael (asked in U2-01's entry; the defaults above hold until answered)

1. Should a given-up feature (and a run that ends on feature-list edits or a crash) send its own high notification as
   it happens, rather than only through the run-end notification? Default: no.
2. Is one `main_conflict` item per lane (refreshed as main moves, notified once per main commit) what you want, rather
   than one per main commit? Default: per lane.
3. The park notification's tap opens `needs.md` instead of `INBOX.md` (Edit INBOX stays an action button). Default:
   `needs.md`.

## 9. Michael's after-run steps

Nothing live (build-only). If the `harness-answer` skill isn't linked yet: `ln -s ~/projects/agent-harness/skills/
harness-answer ~/.claude/skills/` (it is a symlink into the live checkout, so it updates when that checkout syncs).
Then `harness needs` the next time a run parks, and `COLUMNS=60 harness needs <run>` from the phone.
