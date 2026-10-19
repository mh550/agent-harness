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

### 2026-10-19 17:55 · P3-02 · passes

- New `lib/desk.sh` (`harness desk <run> [--why "…"]`), `prompts/desk.md` (run and debrief blocks), `tests/fixtures/remote-control-pane.txt`; stub claude's interactive mode (no `-p`/`--print` and a `--remote-control` name → the pane line with `session_TEST<n>`, `.args` with argv + `PWD=`, typed lines to `.in`); `lib/config.sh` `DESK=0 DESK_MODEL=opus`; bin/harness `desk)` dispatch, usage line, help range `2,36p`, `HARNESS_DESK_SESSION/WAIT` in the tmux env pass list. Suite: private tmux server (`unset TMUX TMUX_PANE`, `TMUX_TMPDIR=$T/tmux`), EXIT trap kills `h-desk-test-$$` (and that private server), helpers `win wins in_has desk_of`, and the desk block after run16b. Tests 140 → 147.
- Verified: the 7 new checks were red against HEAD's code (140/147, a `git archive` copy in scratch) and green after; `check.sh` green in 192 s (147/147). Smoke on a private tmux 3.4 server: two desks in one session (both windows 250 wide), a why holding `$(id)` and `·` arrived verbatim in the stub's argv.
- Opus review of the diff: fixed: tmux calls now close fd 9 as well as 8 (debrief.lock, the driver's ledger lock); a window added to an existing session is resized to 250×50 (a narrow client would let the TUI cut the URL); 0.5 s between the typed text and Enter (a burst reads as a paste); no push on a detached HEAD; an unknown DESK_MODEL fails; the stub only plays a desk when it gets `--remote-control`. Not done (minor): clearing HARNESS_NO_RUNNER/SCRATCH_ROOT from a server's env.
- Next session (P3-03): today a desk with no URL kills its window, logs `desk: no session URL within <n> s; killed the window` to run.log and exits 1 with `no desk (…)` on stderr; a lock timeout or missing tmux/claude exits 1 the same way (`fail` in desk.sh). P3-03 turns these into the plain notification + note + exit 0, and adds reuse (no reuse yet: a second `harness desk parky` would open a second window). Desks so far in the suite: TEST1 = parky's.
- Docs (architecture, README, templates/user/config.sh, D-H31 built) are P3-06's, per the feature list.

### 2026-10-19 16:50 · P3-01 · passes

- New `docs/plans/2026-10-19-P3-desk.md` (Milestone base 8f17332): lib/desk.sh flow, exact tmux commands (exact `=` session match, window ids `@N`, command as separate args through `env -u NTFY_TOKEN …`), the URL wait (`capture-pane -p -J -S -`, `${HARNESS_DESK_WAIT:-60}`), send-keys input, state under `<state>/desk/` and `queue/desk/`, prompts/desk.md content, stub interactive mode + fixture, driver/debrief triggers, `DESK=0 DESK_MODEL=opus`, P3-05 housekeeping, 21 named checks in run order (140 → 147 → 152 → 157 → 161), and "For Michael: turning it on". D-H31 is in journal/decisions.md, marked *planned*. P3-06 marks it built.
- Verified: tried on a private tmux 3.4 server under scratch. `-t h-desk` prefix-matches `h-desk-x` (hence `=`). send-keys reaches a cooked-tty reader as one line. A multi-arg command runs without a shell. An Opus review of the plan had 1 Important finding (the stub's `printf | grep -q` under pipefail misreads big prompts) and 9 Minor ones; all are folded in. check.sh green (140/140, 190 s).
- Next session (P3-02): no desk may start before the new desk block after run16b, because parky's must be `session_TEST1`. Tests must `unset TMUX TMUX_PANE` and set `TMUX_TMPDIR=$T/tmux`, or they talk to Michael's tmux server.
- Michael (D-H31 *default*, plan §12): with DESK=1 each event sends two notifications, the driver's own and the desk's with the session link. Want the driver's dropped when a desk starts? The desk starts in `~/projects/<project>` (trusted), not `~/projects` itself. OK?
- Proposed changes: P3-04 step 4 says "run 3 (strict) with DESK=1". Plan check 16 does it as a `continue strict` inside the desk block, so TEST1 stays parky's. P3-04 step 6 should also allow the reuse line `desk: sent to the open desk: <url> (<why>)`. The step's literal `[[ $DESK == 1 ]] && desk … || note …` would note on every DESK=0 event. The plan's helper puts the guard first.

### 2026-10-19 16:00 · verify P2

`check.sh` green (cached); suite output read: 140/140 checks passed, no FAIL line.

| Feature | Step | What you ran or read | What you saw | Holds |
|---|---|---|---|---|
| P2-01 | 1 | `head -5 docs/plans/2026-10-19-P2-answer-desk.md` | line 1 is `Milestone base: 39968f75…` | yes |
| P2-01 | 2 | read plan §2 (lines 37-85) | text layout for parky (since/why/question/running/next) and `--json` fields run, project, feature, since, why, question, running, commands | yes |
| P2-01 | 3 | read plan §2.1 (lines 86-95) | running = driver.pid alive; runner = queue/runner.pid `kill -0`; command pair per case (answer+continue, answer+queue add --continue, answer only) | yes |
| P2-01 | 4 | read plan §5 (lines 147-181) | skill sections, order of commands, never-list, verbatim README install line | yes |
| P2-01 | 5 | read plan §6-7 (lines 183-241) | templates/user/config.sh with NTFY_URL, NTFY_TOKEN, DESK_URL, NOTIFY_CMD, DESK, DESK_MODEL placeholders; check names for P2-02 and P2-03 | yes |
| P2-01 | 6 | bash tests/run.sh output (check.sh run, check-*.out): 140/140 checks passed | 140/140 | yes |
| P2-02 | 1 | ran `parkedReport` via `node --input-type=module -e` with the step's entry | text has `harness answer r "…"` and `harness continue r`; runner:true gives `harness queue add --continue r`; [] gives `nothing parked`; also asserted by test 'parked.mjs: the report names the answer and continue commands' (PASS) | yes |
| P2-02 | 2 | `grep -n parked bin/harness`; read cmd_parked and test 'harness parked is read-only' (run.sh:387) | usage header line 22 lists it; `parked)` case line 343; read-only check uses `find -newer` on state and worktree plus git status; PASS | yes |
| P2-02 | 3 | run.sh:385 (before the answer at :415); suite PASS 'harness parked: id, why, question, both commands' | asserts parky · proj · B, why, question '### B: set the gatus vars…', answer and continue commands | yes |
| P2-02 | 4 | run.sh:388; suite PASS 'harness parked --json parses' | jq asserts .[0].feature=="B", running==false, commands length 2 | yes |
| P2-02 | 5 | run.sh:390; suite PASS 'with a queue runner going, the continue command is a queue add' | runner.pid with $$; output has `queue add --continue parky`, not `continue parky` | yes |
| P2-02 | 6 | run.sh:408; suite PASS 'nothing parked' | `harness parked demo` equals 'nothing parked in demo' (contains 'nothing parked') | yes |
| P2-02 | 7 | `bash -n bin/harness templates/user/config.sh; node --check lib/parked.mjs`; bash tests/run.sh output (check.sh run, check-*.out): 140/140 checks passed | syntax ok; 140/140 | yes |
| P2-03 | 1 | read skills/harness-answer/SKILL.md | frontmatter name: harness-answer; description has "answer the harness" and "what does <project> need?"; commands appear in order parked, status, answer, queue list, queue add --continue, continue | yes |
| P2-03 | 2 | read the safe-checks and Never sections | `grep -c '^NAME=' file`, "by name only, never a value"; off limits .env, secrets, sudo; never-list has never edit INBOX.md/feature lists/policies/CLAUDE.md, never answer without his yes, never run live commands | yes |
| P2-03 | 3 | `grep -n 'ln -s\|parked\|DESK_URL' README.md` | line 84 has the exact `ln -s ~/projects/agent-harness/skills/harness-answer ~/.claude/skills/`; line 42 `harness parked` in commands table; DESK_URL in Steering (lines 82, 86) | yes |
| P2-03 | 4 | read templates/user/config.sh; `bash -n` | all assignments commented, header as in project template; NTFY_URL, NTFY_TOKEN, DESK_URL, NOTIFY_CMD present; syntax ok; also PASS 'the user config template sets nothing' | yes |
| P2-03 | 5 | run.sh:409; suite PASS 'the answer skill exists and names the commands and the never-list' | asserts file, name, 'harness parked', 'harness answer', 'never edit INBOX.md' (grep -i), 'sudo' | yes |
| P2-03 | 6 | bash tests/run.sh output (check.sh run, check-*.out): 140/140 checks passed | 140/140 | yes |
| P2-04 | 1 | read docs/plans/2026-10-19-P2-review.md; `git diff 39968f75..HEAD --stat` | review lists I1-I3, R1 Important and Minors with file:line and resolution; diff covers lib bin tests skills templates (5 files, +254) | yes |
| P2-04 | 2 | read review rows I1, I2, I3, R1 | each names its check (ending, newest question wins, quoted heredoc, same as I2); all present in suite output and PASS. That they were red first rests on the review file and progress note (135/139, 135/140), not re-run | yes |
| P2-04 | 3 | `grep -n D-H30 journal/decisions.md` | line 286 heading plus Finding, Choice, Rejected bullets | yes |
| P2-04 | 4 | `grep -n` docs/architecture.md | §3 bin/harness row lists parked (line 50); lib/parked.mjs row (57); '## 17. Answer desk' with the notification → Answer with Claude → skill → answer → continue flow | yes |
| P2-04 | 5 | README.md lines 42, 84-86, 127 | commands table, install line, DESK_URL and "140 checks"; run.sh has 140 `check` lines | yes |
| P2-04 | 6 | bash -n bin/harness tests/run.sh templates/user/config.sh; node --check lib/parked.mjs; bash tests/run.sh output (check.sh run, check-*.out): 140/140 checks passed | all ok; 140/140 | yes |

### 2026-10-19 15:10 · P2-04 · passes

- Review of the P2 diff (`/tmp/p2.diff`, 267 lines) by Opus, then a second Opus pass over the fixes: `docs/plans/2026-10-19-P2-review.md`, 4 Important (I1–I3, R1) and 7 Minor, none Critical. Fixes in c44ed3e; tests 134 → 140, each new check watched red first (135/139, then 135/140).
- Important fixes: `harness parked` showed a run in `finish` (driver alive, `ended` written, retro running) as "running", with the answer command only, so the answer sat unused after a park. It now shows `ending`. A re-park quoted the old answered question; the newest `### <id>` now wins. The skill passed Michael's words in double quotes, where backticks and `$(…)` run; it now uses a quoted heredoc. A `# comment` in a code fence cut the question short; fences now count.
- Also: `queue/*-continue-<run>.args` → answer only (a session-cap end already queued a continue); `state_of` rejects globs (`harness answer 'park*'` answered a random run); `runner_up()` helper.
- Docs: D-H30 in journal/decisions.md; architecture §3 rows (bin/harness parked, lib/parked.mjs, the skill, the template), §14 runbook row, new §17 "Answer desk"; README Tests count 140. `check.sh` green in 189 s; `bash -n` bin/harness, tests/run.sh, templates/user/config.sh; `node --check lib/parked.mjs`.
- Left open (in the review file): store the park-time question in parked.json (P3 touches the park path); stale-pid reuse in `alive` (M1); no "already answered" marker (M2).
- Michael: runs whose worktree was gc'd stay hidden from `harness parked` (D-H30 *default*). Should they show a "worktree gone" line instead?
- Proposed change: the JSON of `harness parked` gained `ending` and `queued` fields, which the plan's exact field list didn't have. P3's desk prompt should read them.

### 2026-10-19 14:00 · P2-03 · passes

- Added `skills/harness-answer/SKILL.md` (frontmatter + the five sections from plan §5), `templates/user/config.sh` (all assignments commented), README: `harness parked` in the commands table, a "Answering from the phone" bullet under Steering with the install line and DESK_URL. Tests 132 → 134.
- Checks: `the answer skill exists and names the commands and the never-list`, `the user config template sets nothing` (after `nothing parked` in tests/run.sh). I wrote the files before the checks, so the checks were not watched failing. `check.sh` green in 195 s; `bash -n` on the template and run.sh ok.
- Michael: install with `ln -s ~/projects/agent-harness/skills/harness-answer ~/.claude/skills/`.
- Next (P2-04): D-H30, architecture, README Tests count.

### 2026-10-19 13:20 · P2-02 · passes

- Built `harness parked [<run>] [--json]`: new `lib/parked.mjs` (pure questionFor, commandsFor, entriesFor, parkedReport + `report` stdin CLI, never writes), `cmd_parked` in bin/harness (usage line, `parked)` beside `status)`, help range 2,35p). Output matches the plan §2 layout exactly. Tests 125 → 132.
- Checks added (all red first, then green): 2 units (`parked.mjs: the report names…`, `…the question is the feature's INBOX section`) and 5 e2e between `one notification per run end` and `harness answer parky` (id/why/question/both commands, read-only via `find -newer` + `git status`, `--json` jq, queue-runner → `queue add --continue`, `nothing parked in demo`). `check.sh` green: 132/132 in 191 s; `bash -n bin/harness tests/run.sh`, `node --check lib/parked.mjs` ok.
- An Opus review found no Critical issues. I fixed these (tests extended first): runs whose worktree was gc'd are skipped (they used to show every parked id, passing ones included, with a `continue` that can't work); `### <id>` headings win over a heading that only mentions the id; one broken meta.env no longer cuts the list short (`|| true`); a second positional arg is a usage error.
- Not done, for P2-04: D-H30, architecture §3 and the "Answer desk" section, README (per the plan). No harness-log.md note: the command is read-only by design. Possible simplification: entriesFor repeats features.mjs `parked`'s "parked minus passing" filter.
- Michael: should a run whose worktree is gone still be listed with a "worktree gone" line? Right now it's hidden (simplest; D-H30 in P2-04 should record it).

### 2026-10-19 12:40 · P2-01 · passes

- Wrote `docs/plans/2026-10-19-P2-answer-desk.md` (Milestone base 39968f7…): the exact text block and `--json` fields of `harness parked`, the command rule (driver.pid alive → answer only; queue/runner.pid alive → answer + `queue add --continue`; else answer + `continue`), lib/parked.mjs helpers (questionFor, commandsFor, entriesFor, parkedReport) and its stdin CLI, `cmd_parked` in bin/harness (read-only; help range 2,34p → 2,35p), the skill's five sections + frontmatter, templates/user/config.sh content (all commented; DESK/DESK_MODEL as P3 placeholders), and 9 named checks (125 → 132 after P2-02 → 134 after P2-03).
- Plan only: no code or tests changed; suite still 125 checks. Verified: `head -1` of the plan matches the session's start HEAD; `check.sh` green (189 s).
- Next session (P2-02): add the e2e checks between `one notification per run end` and `"$H" answer parky` in tests/run.sh; parky, parkn and parkl are all parked at that point, and demo's worktree is already gc'd (a missing feature list/INBOX counts as empty).
- Choice made in the plan (D-H30 records it in P2-04): while a run is still going, `harness parked` gives only the answer command, because the driver unparks on new answers by itself. Michael: say if you'd rather always see a continue command.

### 2026-10-19 12:03 · verify P1

`check.sh` green; full suite re-run: 125/125. All 5 features hold.

| Feature | Step | What you ran or read | What you saw | Holds |
|---|---|---|---|---|
| P1-01 | 1 | read docs/plans/2026-10-19-P1-notifications.md line 1; `git cat-file -t a462525…` | line 1 `Milestone base: a4625257b22e…`, a commit in this repo (base precedes P1 work) | yes |
| P1-01 | 2 | read plan §2 and §1 | notify signature with title/body/click/actions/priority/tags; five HARNESS_NOTIFY_* in table; '`$1` to NOTIFY_CMD stays exactly `[<run>] <message>`' | yes |
| P1-01 | 3 | read plan §4; `head -2 tests/fixtures/ntfy-publish.txt` | stub-curl record format (one arg per line, `===`) described; fixture line 1 `https://docs.ntfy.sh/publish/`, shows Title/Priority/Tags/Click/Actions/Authorization | yes |
| P1-01 | 4 | read plan §3 | githubUrls, trimBody(cap=3500), actionsHeader, inboxQuestion with signatures as the step lists | yes |
| P1-01 | 5 | read plan §5 table and §1 config row | call sites with title/priority/click for driver and debrief (rows 1–15); `NTFY_URL="" NTFY_TOKEN="" DESK_URL=""` named | yes |
| P1-01 | 6 | read plan §7 incl. insteadOf trick; checks names exist in tests/run.sh via grep | checks for P1-02/03/04 listed by name, insteadOf + remote.origin.url=git@github.com:test/proj.git described; names match run.sh | yes |
| P1-01 | 7 | `bash tests/run.sh` | 125/125 checks passed, 0 FAIL | yes |
| P1-02 | 1 | `ls -l tests/stub-curl.sh`; read it; `grep HARNESS_CURL tests/run.sh`; `head -1` fixture | executable; appends blocks to $STUB_DIR/curl.log; run.sh line 8 exports HARNESS_CURL=$HERE/stub-curl.sh; fixture line 1 docs.ntfy.sh URL | yes |
| P1-02 | 2 | `grep -n notify.sh lib/driver.sh lib/debrief.sh`; `bash -n lib/notify.sh`; read header | one source line each (driver:61, debrief:32); bash -n ok; usage header present | yes |
| P1-02 | 3 | ran the trimBody one-liner (plus 100-byte unchanged case) | exit 0 | yes |
| P1-02 | 4 | read check 'NOTIFY_CMD-only: $1 unchanged, fields as env' (run.sh:100); it passed in the suite | asserts `[stoppy] started: 0/3 passing` as $1 and HARNESS_NOTIFY_TITLE=harness in notify-env.log; matches step (run is stoppy not demo, same assertion) | yes |
| P1-02 | 5 | read check 'NTFY_URL: curl posts the fields…' (run.sh:84) | asserts URL last, `-H`/`Title: harness`, message as --data-binary, notify-cmd.log absent; PASS (Priority covered elsewhere on high notifications) | yes |
| P1-02 | 6 | read check 'NTFY_TOKEN: bearer header…' (run.sh:85) | asserts Authorization: Bearer tok-secret-123 in curl.log and grep -r over run state dir and run record finds nothing; PASS | yes |
| P1-02 | 7 | read check 'a body over the cap is trimmed' (run.sh:60) | 4000-byte body → ≤3500 and >3000 bytes, ends `…`; PASS | yes |
| P1-02 | 8 | read checks 'a failed post is noted…' (:116) and 'a successful post: a line in run.log only' (:86) | harness-log has `notification failed (curl exit 22): harness`; success only in run.log; PASS | yes |
| P1-02 | 9 | `bash -n` on notify.sh driver.sh debrief.sh config.sh run.sh stub-curl.sh; `node --check lib/*.mjs`; `bash tests/run.sh` | all ok; 125/125 checks passed | yes |
| P1-03 | 1 | ran the githubUrls one-liner | exit 0 | yes |
| P1-03 | 2 | ran the inboxQuestion one-liner | exit 0 | yes |
| P1-03 | 3 | `grep -n inbox-before lib/driver.sh`; read notify_park (driver.sh:119-126) | cp at :490 before coding session; body = PARKED line, added lines, `Answer: harness answer <run> "…"` (question empty → PARKED + Answer) | yes |
| P1-03 | 4 | read check 'a park notification: title, question, answer command, click and Edit INBOX action' (run.sh:341) | asserts Title [parky] B needs you, Priority high, Tags question, body lines, Click INBOX blob URL, Edit INBOX and Progress actions; PASS | yes |
| P1-03 | 5 | read check 'Answer with Claude only when DESK_URL is set' (:346) | parky has the action with env-test URL; parkn block has Edit INBOX but no Answer with Claude; PASS | yes |
| P1-03 | 6 | read check 'no URLs for a non-GitHub origin' (:353) | parkl block: Priority high, answer command in body, no Click, no Actions, no github.com; PASS | yes |
| P1-03 | 7 | `grep -n 'NTFY_URL\|DESK_URL' lib/config.sh` | line 22 defaults NTFY_URL/NTFY_TOKEN/DESK_URL on the defaults line | yes |
| P1-03 | 8 | `bash -n lib/driver.sh lib/notify.sh`, `node --check lib/notify.mjs`, `bash tests/run.sh` | all ok; 125/125 checks passed | yes |
| P1-04 | 1 | `grep -n 'notify \|needs_you ' lib/driver.sh` | needs-Michael calls (:116,:125,:219) and `ended` (:372) pass priority and click; verify/conflict via needs_you; routine ones click only | yes |
| P1-04 | 2 | read check 'a waiting-on-Michael run end…' (run.sh:355) | asserts Priority high and Click …/parky/report.md in the `ended (waiting on Michael: B)` block; PASS | yes |
| P1-04 | 3 | read check 'a refused merge…' (:159) | run `later` block: Title, Priority high, Click = the stub PR URL https://example.test/pr/N; PASS | yes |
| P1-04 | 4 | read check 'verify needs Michael: priority high, click = progress.md (GitHub-shaped origin)' (:108) | strict block: Priority high, Click …/harness/strict/…/progress.md; says GitHub-shaped; PASS | yes |
| P1-04 | 5 | read check 'routine notifications keep the default priority' (:87) | demo started and M1 merged blocks have no Priority line (also Click asserted); PASS | yes |
| P1-04 | 6 | read debrief.sh:33,327 and checks :278, :287 | fail()/headline use shared notify; existing NOTIFY_CMD debrief checks pass; with NTFY_URL, headline block has Title harness debrief, no Click; PASS | yes |
| P1-04 | 7 | `bash -n lib/driver.sh lib/debrief.sh`, `bash tests/run.sh` | ok; 125/125 checks passed | yes |
| P1-05 | 1 | `git diff a4625257b22e..HEAD -- lib bin tests prompts > /tmp/p1.diff` (672 lines, 10 files); read docs/plans/2026-10-19-P1-review.md | diff written; review lists I1 and Minors with severity, file:line, resolution (fixed in ba78f9f / skipped because …) | yes |
| P1-05 | 2 | read review I1 row; grep run.sh for the named check | I1 is the only Important; check 'the run end goes out before the retro, once report.md is pushed' named, stated red on pre-fix lib/ (121/125); check exists in run.sh and passes | yes |
| P1-05 | 3 | `grep -n '### D-H29' journal/decisions.md`; read it | present at :258 with Finding/Choice/Rejected | yes |
| P1-05 | 4 | `grep -n` README for NTFY_URL, NTFY_TOKEN, DESK_URL, HARNESS_NOTIFY_*; README:122 vs suite | all named, 'NTFY_URL wins: NOTIFY_CMD is then not called' (:75); Tests line says 125 checks = 125/125 | yes |
| P1-05 | 5 | `grep` docs/architecture.md | §3 rows for lib/notify.sh and lib/notify.mjs; §10 rows for NTFY_URL/NTFY_TOKEN and DESK_URL; §13 notifications row names tests/stub-curl.sh and tests/fixtures/ntfy-publish.txt | yes |
| P1-05 | 6 | `bash -n` on touched .sh, `node --check lib/*.mjs`, `bash tests/run.sh` | all ok; 125/125 checks passed | yes |

### 2026-10-19 12:30 · P1-05 · passes

- **What changed:** Opus read `/tmp/p1.diff` (base `a4625257` → `3a16c96`, 593 lines); the findings and how each was resolved are in `docs/plans/2026-10-19-P1-review.md`. A second Opus pass read the fixes. Nothing Critical; one Important:
  - **I1:** a blocked run end was notified only after the retro, so a crash there sent nothing. `finish` now writes report.md, pushes `HARNESS: run ended (…)` and notifies before the retro.
  - **Minors fixed:** verify and conflict notifications go out after their entry is pushed (`needs_you`; a conflict is reported once per main); `inboxQuestion` with no `## Answers` heading; debrief `Queued`/`Not queued` lines no longer make the headline high; header control bytes stripped; the message capped too; `--retry 2 --retry-max-time 20`.
  - **Docs:** D-H29 is in `journal/decisions.md`; README Notifications; architecture §3/§5/§10/§13/§16.
  - **Tests:** 123 → 125.
- **Verified:** `check.sh` green, 125/125. The 4 new or extended checks were red on a scratch copy with the old `lib/` (121/125): *the run end goes out before the retro, once report.md is pushed*, *verify needs Michael goes out after the verify entry is pushed*, inboxQuestion (old answers), debrief Not-queued priority. `bash -n` passes on all 8 P1 shell files and `node --check` on notify.mjs.
- **Next session (P2-01):** `curl_last` (newest matching block) sits beside `curl_with` (first match) in tests/run.sh. `needs_you <m> <why> <file>` is the milestone needs-Michael call. Not applied: S1, sending the body and token over stdin. It would take the token out of `ps`, but it changes the stub-curl record format; do it with P3, which touches notify again.
- **Questions for Michael:** D-H29 records the default from P1-01: one high `ended` notification instead of `needs Michael:` plus `ended`. It now goes out before the retro. OK? Also, a `DESK_URL` must not contain `,` or `;` (README says so).
- **Proposed changes:** none.

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
