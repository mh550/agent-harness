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
