# Progress · run agent-harness-2026-10-19

What this file is: the log every session of this run writes to, **newest entry first**. Each coding session adds
one `### <date time> · <feature id>` entry: what it built, what it checked, what it left open, and direct questions
for Michael. Verify sessions add `### … · verify <milestone>` entries with one evidence row per step.

How to read the feature list (`feature_list.json`): array order is priority order; a feature runs when it isn't
passing and everything in its `after` (feature ids or whole milestones) passes; a feature without `after` waits on
every feature before it. A session changes only its own feature's `passes`. Steps are what the verifier re-runs.

How Michael steers: edit `INBOX.md` on branch `harness/agent-harness-2026-10-19` (first line `status: pause|stop`;
answers under `## Answers`), or `harness answer agent-harness-2026-10-19 "<text>"`. The driver pulls before every
session; every session reads INBOX.md first. Answers override earlier plans.

---

### 2026-10-19 11:45 · P1-04 · passes

- **What changed:** `lib/driver.sh`: rows 2–12 of the plan's §5 table. Verify thin/red/fail, the merge conflict and the refused merge are `[<run>] <m> needs you` at priority high. Their click is progress.md, harness-log.md or the PR. A proposed merge is `<m> ready to merge` and a merge sends `merged`; both get the PR as click and no priority. `started:` gets progress.md as click. `finish` sends the run's one end notification: `[<run>] ended: <reason>` with report.md as click, and high plus Edit INBOX/Progress actions for blocked, waiting, feature-list edits and initializer failed. The separate `needs Michael: …`, `ended: …`, `stopped: …` and `initializer failed` notifications are dropped. Each `notify` call fits on one line, so the step-1 grep shows its fields. `lib/debrief.sh`: `tell()` is gone and `fail` and the headline call `notify` with title `harness debrief`. The headline goes high when the note's `## Needs Michael` has anything but Nothing/None, and it has no click. `tests/stub-claude.sh`: the stub note gains `## Needs Michael` / `_Nothing._`, and `STUB_DEBRIEF_NEEDS` fills it. Run 12 (claim) now runs with `MERGE_POLICY=pr` to cover the proposed row. Tests 114 → 123.
- **Verified:** `check.sh` green in 189 s, 123/123. The 9 new checks were all red before the code (114/123), then green. In a kept dir I read the parky-end, strict, later (`Click: https://example.test/pr/13`), claim, demo `started:` and debrief needs-Michael blocks; each matches §5. `grep -n 'notify ' lib/driver.sh | grep 'needs Michael\|ended'`: every line has `priority=` and `click=`.
- **Review (Opus), fixed:** the routine check's merged-Click test could never fail (`${Bm##*· }` kept the ntfy URL line, so `grep -x` had a second pattern that always matched). It now extracts the PR URL; tested against a block without Click, which fails. The debrief filter also accepts `_Nothing._`, `None.` and emphasis, and the default stub note now exercises it.
- **For P1-05 (D-H29):** the dropped notifications mean a blocked, waiting or weekly end now reaches Michael only after `finish` has run the merge, the suite, the retro and the ledger, which takes minutes, not "one line later". A crash during the retro now sends nothing. Either word D-H29 that way, or move the end notify before the retro (its click, report.md, is written after the retro). Also: a `CONTINUE:` line the debrief model puts inside `## Needs Michael` makes the headline high.
- **Proposed changes:** step 3 names `Click: https://example.test/pr/1`. In the suite run 10's PR is a later number (13 today), so the check matches the PR URL from the message (as the plan's `pr/<n>` says).
- **Questions:** none.

### 2026-10-19 11:15 · P1-03 · passes

- **What changed:** `lib/notify.mjs` gains `githubUrls` (ssh/https/ssh:// GitHub forms; null for anything else or an empty branch) and `inboxQuestion` + `urls`/`question` CLI; `lib/notify.sh` gains `gh_url <path> [blob|edit]` (reads `remote.origin.url` and `$BRANCH`); `lib/driver.sh` copies INBOX.md to `$STATE/inbox-before.md` before every coding session and has `notify_park`: title `[<run>] <id> needs you`, high, tag question, body = PARKED line + the session's INBOX lines + `Answer: harness answer <run> "…"`, click = INBOX blob, actions Edit INBOX / Answer with Claude (DESK_URL) / Progress. `tests/stub-curl.sh` gains `STUB_CURL_SPY`. The suite's origin is now GitHub-shaped (`url.<local>.insteadOf`). Tests 107 → 114.
- **Verified:** check.sh green in 188 s, 114/114. The GitHub-shaped origin alone was 107/107 (separate run first). Each new check was watched red on a scratch copy without its code (3 park checks, githubUrls empty-branch, notify-after-push, failed-post commit). In a kept dir I read the parky/parkn/parkl curl.log blocks: they match the plan to the character.
- **Review (Opus), fixed:** the park notification now goes out *after* `commit_all … ; sync`, so its links show the question (check: `the park goes out after the run branch is pushed`). A failed park post's note is committed and synced at once instead of riding in the next `WIP:` commit (check: `a failed park post is noted and committed at once`). A stale inbox-before.md is emptied if the copy fails, and `gh_url` uses `$BRANCH` (a detached HEAD gave `blob//`).
- **Minors left for P1-05:** a `,` or `;` in a branch name or DESK_URL would split ntfy's Actions header (quote or drop such URLs). The `inboxQuestion` unit doesn't cover a `before` without `## Answers`. parkn and parkl stay behind as ended runs in the throwaway env.
- **Next session (P1-04):** the run 16 config is base + DESK_URL; it goes back to plain `LEDGER_COMMIT=0 MAX_PARALLEL_RUNS=1` after the unpark check. For parky's `ended (waiting on Michael: B)` block, `curl_with` finds it. Under `pipefail`, `git log | grep -q` fails with SIGPIPE: use `grep … > /dev/null`. `grep` here is ugrep (`$` in a pattern is an anchor: use `-F`).
- **Questions / proposed changes:** none.

### 2026-10-19 10:45 · P1-02 · passes

- **What changed:** new `lib/notify.sh` (`notify "<msg>" [title= body= click= actions= priority= tags=]`; NTFY_URL → stub-able `${HARNESS_CURL:-curl}` post with Title/Priority/Tags/Click/Actions/Bearer headers, NOTIFY_CMD skipped; else NOTIFY_CMD with `$1` unchanged + five `HARNESS_NOTIFY_*`), `lib/notify.mjs` (`trimBody`, `actionsHeader` + `trim`/`actions` CLI), `tests/stub-curl.sh`, `tests/fixtures/ntfy-publish.txt`. driver.sh sources it with `NOTIFY_TAG=$RUN_ID`; debrief.sh sources it (its `tell()` stays on NOTIFY_CMD until P1-04). config.sh defaults `NTFY_URL NTFY_TOKEN DESK_URL`; `HARNESS_CURL` is in bin/harness's tmux env list. Tests 98 → 107.
- **Verified:** check.sh green in 180 s, 107/107. The 8 plan checks plus 1 from review were each watched failing first (98/106 before the code). Kept-dir spot check: the demo `started:` block is `-H Title: harness`, `-H Authorization: Bearer …`, `--data-binary [demo] started: 0/3 passing`, URL last. The token appears nowhere but curl.log and the configs.
- **Review (Opus) found one Important bug, fixed:** a failed run-end post notes into harness-log.md after the last commit, which leaves the worktree dirty so `harness gc` skips it. `finish` now commits and syncs the run record after its notify when it changed. New check: `a failed run-end post is committed: the worktree stays clean for gc`. Two checks that could pass vacuously were tightened. Minors left for P1-05: a body that starts with `@` gets a leading space (curl would read `@file`); `$(…)` drops a body's trailing newlines.
- **Next session (P1-03/04):** until P1-04, the debrief still notifies through NOTIFY_CMD even when NTFY_URL is set (the suite's base config now sets both, so `$T/notify-cmd.log` gets debrief lines). `curl_with <key>`/`curl_body <key>` are in tests/run.sh beside `on_main`; the base config is `$T/base-config.sh` (run 2 rewrites the config and restores it from there).
- **Proposed changes:** none.

### 2026-10-19 · P1-01 · passes

- **What changed:** new `docs/plans/2026-10-19-P1-notifications.md` (Milestone base `a4625257b22e…` = HEAD at session start). It fixes `notify "<msg>" [title= body= click= actions= priority= tags=]` in `lib/notify.sh` (with `NOTIFY_TAG=$RUN_ID` so `$1` stays `[<run>] <msg>`), the five `HARNESS_NOTIFY_*` variables, the exact curl argv (URL last, `--data-binary` before it), the four `lib/notify.mjs` helpers + CLI, `tests/stub-curl.sh` (`===` blocks, `STUB_CURL_FAIL=1` → exit 22) and the fixture text copied from docs.ntfy.sh/publish, a 15-row call-site table (driver + debrief), and the checks for P1-02/03/04 by name. No code changed; tests 98 → 98.
- **Verified:** check.sh green in 179 s, 98/98 checks passed. The insteadOf trick checked by hand in scratch: `git remote get-url` gives the local path, `git config --get remote.origin.url` the GitHub URL, push lands in the bare repo.
- **Next session (P1-02) must know:** the GitHub-shaped origin goes on line 25 of tests/run.sh for the whole suite (P1-03 does it; run the suite once right after that one line). Default title is `harness`; routine notifications pass no priority. `HARNESS_CURL` must be added to bin/harness's tmux env list (not visible in the suite).
- **Decision for Michael (default taken, D-H29 records it in P1-05):** a run that ends needing Michael today sends two notifications in the same second (`needs Michael: …` then `ended (…)`); the plan drops the first, so one high-priority `ended` goes out with click = report.md and Edit INBOX / Progress actions. Parks still notify on their own with the INBOX as click. OK?
- **Proposed changes:** P1-02's NTFY_URL step mentions a `Priority:` line on the `started:` block; P1-04 requires routine notifications to have none. The plan resolves it: `started:` has `Title: harness` and no Priority (the step allows "or the fields the plan fixed").

### 2026-10-19 · initializer

**Feature counts.** P1 (notifications carry the question and the links): 5 = plan, 3 build, review.
P2 (answer desk for phone sessions): 4 = plan, build, docs, review. P3 (a desk session starts itself): 6 = plan,
4 build, review. 15 in all. `after`: P2-01 waits on P1, P3-01 on P2, P2-03 (the skill, docs-only) only on P2-01.
Decision numbers reserved: D-H29 (P1), D-H30 (P2), D-H31 (P3); the next free one today is D-H29.

**Scope** (Michael's brief, 2026-10-19 10:06, wins over the spec): P1, P2, then P3 from
`docs/specs/2026-10-19-phone-answers.md`. Tests use a stub curl, the stub claude and throwaway tmux sessions. Policy
is build-only: never start a real `claude`, never post to any URL, never touch `~/.claude`, `~/.config/harness`,
`~/.local/state/harness` or the live checkout `~/projects/agent-harness`.

**Where things live (read before building).**
- `bin/harness` (~330 lines): the CLI. Subcommands dispatch at the bottom (`case ${1:-help}`); the usage header
  (lines 2–34) is what `harness` with no argument prints, so new commands go there too. `debrief` is
  `exec lib/debrief.sh "$@"`: do `desk` the same way (`lib/desk.sh`). `state_of <run>` finds a run's state dir;
  `alive <state dir>` says whether its driver runs; the queue runner's pid is `$Q/runner.pid`.
- `lib/driver.sh` (~490 lines): the run loop. `notify()` is one line at the top: `bash -c "$NOTIFY_CMD" _ "[$RUN_ID] $*"`.
  Call sites to extend: `started:` (after the initializer), `paused`, `refused (…)`, the park (`needs Michael: $id · $why`,
  in the loop after `F park`), the run end (`needs Michael: ${ends[*]}` then `finish`), `ended (…)` in `finish`,
  verify's `thin|red|fail` cases (`$m needs Michael: …`), `merge_one` (`conflicts`, `verified · review`, `merged`,
  `merge refused`). `note` writes `harness-log.md` (phone-readable, committed); `log` writes run.log only.
  The park: the session ends with a last line `PARKED: <why>`; `MET final` extracts it; `F park` records
  `{answers, why, at}` in `$STATE/parked.json`. Save the INBOX copy for the diff in the loop right before `session coding`.
- `lib/debrief.sh`: `tell()` is its own one-line notify; after P1 it should use the shared one. The note's sections
  come from `prompts/debrief.md` (`## Needs Michael`, "Nothing." when empty). It runs `claude -p … --permission-mode dontAsk`
  with an allowlist; `tmux` and `curl` are on its DENY list, which is right: the desk is started by bash after
  the session, from the note's text, not by the model.
- `lib/config.sh`: defaults on one line in `harness_config`; the user file is `${HARNESS_CONFIG:-~/.config/harness/config.sh}`
  (tests point `HARNESS_CONFIG` at `$T/user-config.sh` and rewrite it between scenarios). Add `NTFY_URL NTFY_TOKEN
  DESK_URL` (P1) and `DESK DESK_MODEL` (P3) there. `bin/harness` passes a fixed list of `HARNESS_*` variables into
  tmux-started drivers (`cmd_start`, the `for v in …` loop): add `HARNESS_CURL`, `HARNESS_DESK_SESSION`,
  `HARNESS_DESK_WAIT` to it or they are lost in tmux mode (tests run `--foreground`, so a miss there won't show in
  the suite: check it by reading).
- `lib/features.mjs`: pure, every command takes paths; `model <alias>` maps opus → `claude-opus-5-5`. `F parked
  <parked.json> <list>` prints `id\twhy`. Pure helpers for this run go in new files (`lib/notify.mjs`,
  `lib/parked.mjs`), exported and checked with `node --input-type=module -e`, usage header on line 1.
- `lib/render.mjs`: `{{X}}` ← `HARNESS_X`. `prompts/desk.md` renders the same way (set `HARNESS_RUN_ID`,
  `HARNESS_RUN_DIR`, `HARNESS_WT`, `HARNESS_WHY`, … before calling it).
- `tests/run.sh` (~290 lines, 98 checks, ~3 min): `check "<name>" '<bash expression>'`. Scenarios are runs of the
  throwaway project `$T/proj` with a bare `$T/origin.git`; `hlog <run>` prints a run's harness-log.md; stub behaviour
  is switched by `STUB_*` variables read by `tests/stub-claude.sh` (one `case` per prompt kind, keyed on the
  prompt's first line). The parking scenario is run 16 (`parky`, `STUB_PARK=B`): the stub inserts
  `### B: set the gatus vars, then answer` above `## Answers`, pushes, and ends `PARKED: set the gatus vars`; the run
  ends `waiting on Michael: B`; then `harness answer` + `harness continue --keep-attempts` finishes it. New P2/P3
  checks that need a parked run go between the first parky run and the `harness answer` line (or use a new run).
  Run 10 (`later`, `STUB_REFUSE_MERGE=1`) is the refused merge; run 3 (`strict`) is "verify needs Michael".
  The notify log already used by the debrief checks: `NOTIFY_CMD='printf "%s\n===\n" "$1" >> $T/notify.log'` and
  `msg_with <key>`; the stub curl log should use the same `===` block format so `msg_with`-style helpers carry over.
- **A GitHub-shaped origin in tests** (verified today): `git config url.$T/origin.git.insteadOf git@github.com:test/proj.git`
  then `git remote add origin git@github.com:test/proj.git` keeps fetch/push local while
  `git config --get remote.origin.url` returns the GitHub URL (`git remote get-url` returns the rewritten local path,
  so URL derivation must read `git config --get remote.origin.url`). Worktrees share the project's config, so it
  holds inside `$T/wt/proj/<run>`. Switch the existing `$T/proj` origin to this form once (before run 1), or give
  only the runs that need URLs a second project; the former is less code but makes "no URLs for a non-GitHub origin"
  need its own small project.
- **tmux in tests**: tmux 3.4 is installed; the suite today starts no tmux session (`HARNESS_NO_RUNNER=1`,
  `--foreground`). The desk session name must be overridable (`HARNESS_DESK_SESSION`, default `h-desk`) because a
  real `h-desk` may exist on this box while the suite runs; tests use `h-desk-test-$$` and kill it in the EXIT trap.
  The real pane line to copy into `tests/fixtures/remote-control-pane.txt` is in the spec (P3, verified by hand on
  CLI 2.1.303): `/remote-control is active · Continue here, on your phone, or at https://claude.ai/code/session_01YSDT…`.
  `claude --version` here is 2.1.303. Never run it from tests: `HARNESS_CLAUDE` is the stub everywhere, including
  inside the tmux window (pass it on the command line of the window, since tmux has the server's environment).
- **ntfy's request shape** is public (docs.ntfy.sh/publish): POST to the topic URL, the message as the body, headers
  `Title`, `Priority` (`high`), `Tags` (`question`), `Click`, `Actions` (`view, <label>, <url>; view, …`),
  `Authorization: Bearer <token>`. Copy the documented example into `tests/fixtures/ntfy-publish.txt` with the
  source URL on line 1; the stub curl only records argv. Keep bodies under 3500 bytes (longer become attachments).
- Docs that change with every milestone: `README.md` (commands table, Steering, Tests count), `docs/architecture.md`
  (§3 components incl. the check count, §4 state, §7 guards, §10 configuration, §13 extending), `journal/decisions.md`
  (one `D-H<n>` per milestone, finding · choice · rejected). The review feature of each milestone owns them.

**Gotchas.**
- `set -uo pipefail` everywhere (bin/harness is `-euo`); `bash -n` and `node --check` on everything touched.
- Don't block the driver on a desk: the URL wait is at most 60 s and every desk call is `… || note "…"`.
- `tmux send-keys -l` for literal text, then a separate `Enter`; target `session:window`.
- Prompts must never carry secrets: the desk prompt names files and commands, not values; NTFY_TOKEN is only ever a
  curl argument (and the stub's log lives in `$T`, which is deleted).
- The debrief session's `--disallowedTools` stays as is; the desk for the debrief is started by `lib/debrief.sh` after
  the session returns, from the note's `## Needs Michael` section.
- The suite must stay ~3 min: the no-URL fallback checks use `HARNESS_DESK_WAIT=2`, never the 60 s default.

**Questions for Michael** (each has a default; answer in INBOX.md or `harness answer` if you want otherwise).
1. Desk session name and model: default tmux session `h-desk`, one window per run, `DESK_MODEL=opus`. OK?
2. `DESK=0` stays the default after this run (spec says so); you turn it on in `~/.config/harness/config.sh`. The
   P3 plan will end with the staged try-out steps. OK?
3. The run-end notification's click is `report.md` on the run branch (spec P1.4). For a run that ends *waiting on
   Michael* the INBOX is arguably more useful; default here: report.md for every end (as specified), INBOX for
   parks and blocks. Say if you want INBOX for waiting ends too.
4. Where `harness desk --debrief` keeps its prompt: `<state>/queue/desk/` (there is no run). OK?
