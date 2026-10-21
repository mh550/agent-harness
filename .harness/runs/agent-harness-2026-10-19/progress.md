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

### 2026-10-19 15:56 · verify P3

Re-ran independently: `lib/check.sh` green; `bash tests/run.sh` **168/168** (all 29 desk checks PASS); a scratch copy
(`git archive HEAD`) with the I1 dialog guard and the I2 refused-once guard taken out: **165/168**, red on exactly the
three review checks named for them. No stub desk or test tmux server left afterwards. 37 steps, 37 hold.

| Feature | Step | What you ran or read | What you saw | Holds |
|---|---|---|---|---|
| P3-01 | 1 | `head -1 docs/plans/2026-10-19-P3-desk.md`; `git log` | `Milestone base: 8f1733211c96…` = `HARNESS: P2 verified`, the commit just before P3-01's c163ee9 | yes |
| P3-01 | 2 | read plan §2.2–§3 | `new-session -d -s "$S" -n "$W" -c "$PROJECT_DIR"` with `S=${HARNESS_DESK_SESSION:-h-desk}` running `claude --remote-control "desk · <run> · <why>" --model <id> --add-dir <worktree>`; loop `capture-pane -p -J -S -` grepping `https://claude\.ai/code/session_[A-Za-z0-9]+` up to `${HARNESS_DESK_WAIT:-60}`; `send-keys -t <id> -l "…"` then `send-keys … Enter` (target = the session:window resolved once to `@N`, reasoned in §3); reuse when the window exists and `#{pane_dead}` is 0 | yes |
| P3-01 | 3 | read plan §4, §2.7 | `<state>/desk/<stamp>.md`, `desk/url`, `desk/last-event` (epoch, content); `--debrief`: `$STATE_ROOT/queue/desk`, window `debrief`, cwd `$HARNESS_HOME` | yes |
| P3-01 | 4 | read plan §6, §9 | no `-p` → fixture line with `session_TEST<n>`, n from `$STUB_DIR/desk/count`; stdin lines appended to `<name>.in` until EOF; `STUB_DESK_NO_URL=1` prints nothing, reads stdin; 21 checks listed per feature P3-02..05; EXIT trap `tmux kill-session -t "=$HARNESS_DESK_SESSION"` | yes |
| P3-01 | 5 | read plan §7, §8 | table: park `$id parked: $why`, finish `blocked on*`/`waiting on Michael*` → `ended: $1`, `needs_you` → `$1 needs Michael: $2`, refused merge `$m: merge refused`; the `[[ $DESK == 1 ]] && desk … \|\| note …` shape with the guard split out (explained); config `DESK=0 DESK_MODEL=opus` | yes |
| P3-01 | 6 | `bash tests/run.sh` | 168/168 checks passed, exit 0 | yes |
| P3-02 | 1 | read `tests/stub-claude.sh:16-27`, fixture, `tests/run.sh:7-9`; ran the stub by hand in scratch with 2 stdin lines | printed `/remote-control is active · … https://claude.ai/code/session_TEST1`; `1-desk_parky_B_parked_a_b.in` held both lines, `.args` argv + `PWD=`; `STUB_DESK_NO_URL=1` printed nothing; fixture line 1 names claude 2.1.303 pane 2026-10-19 and matches spec line 76; suite exports `HARNESS_DESK_SESSION=h-desk-test-$$`, trap kills it | yes |
| P3-02 | 2 | read `lib/desk.sh:1-3`, `bin/harness:23-24,363`, `lib/config.sh:23` | usage header present; `desk) shift; exec …/lib/desk.sh`; header lists `harness desk <run> [--why "…"]`; `DESK=0 DESK_MODEL=opus`; check `DESK=0 by default, DESK_MODEL=opus` PASS | yes |
| P3-02 | 3 | rendered `prompts/desk.md` by hand for parky (render.mjs + desk.sh's sed); check `the desk prompt names the run, its commands and the never-list` | run id, `harness parked parky`, `harness status parky`, INBOX.md path, progress.md newest entries, by name only/.env/sudo/no live commands, numbered brief `1 yes, 2 …`, `harness answer parky`, queue add --continue/continue rule, never-list (undecided item, INBOX.md/feature lists/policies/CLAUDE.md/settings, start/stop/merge runs); 0 `{{` | yes |
| P3-02 | 4 | check `harness desk: one window, the Read line, the prompt, the notification click` (run.sh:438) | asserts exit 0, stdout `…session_TEST1`, `$(wins) == parky`, `.in` = `Read $DP1 and follow it.`, DP1 names parky, INBOX.md path, `harness answer parky`, `desk/url` = URL; PASS | yes |
| P3-02 | 5 | check `the desk notification` (run.sh:442) | `curl_last` block: `Title: [parky] needs you: B parked: set the gatus vars`, `Priority: high`, `Click: …session_TEST1`; PASS | yes |
| P3-02 | 6 | check `the desk's claude: --remote-control, the model id, --add-dir the worktree, in the project directory` (run.sh:444) | `.args` has `--remote-control`, the name, `--model` `claude-opus-5-5` (`$F model opus`), `--add-dir $T/wt/proj/parky`, last line `PWD=$T/proj`; PASS | yes |
| P3-02 | 7 | check `harness desk notes 'desk started:' in the run record` (run.sh:449); `lib/desk.sh:132,248` | hlog has `desk started: https://claude.ai/code/session_TEST1 (B parked: set the gatus vars)`, worktree clean; PASS | yes |
| P3-02 | 8 | `bash -n lib/desk.sh bin/harness tests/stub-claude.sh`; suite | all ok; 168/168 | yes |
| P3-03 | 1 | check `a second event reuses the desk window` (run.sh:452) | exit 0, one `parky` window, `.in` last line `New since your last brief: C parked: db url. Re-read $DP2.` (DP2 ≠ DP1), Click same TEST1, one `desk started:`; PASS | yes |
| P3-03 | 2 | check `no URL in time: no window, the plain notification` (run.sh:457) | exit 0, no stdout, no `stoppy` window, hlog `desk: no session URL within 2 s; killed the window; plain notification`, `Title: [stoppy] needs you: x`, no `Click: https://claude.ai`; PASS | yes |
| P3-03 | 3 | check `a dead desk is replaced` (run.sh:464) | after `tmux kill-window` (by window id), new desk prints TEST3, one `parky`, new `.in` starts `Read … and follow it.`, no `New since`; PASS | yes |
| P3-03 | 4 | check `harness desk --debrief` (run.sh:468) | exit 0, window `debrief`, newest `queue/desk/*.md` names `ledger/debrief.md` and `Needs Michael`, `Title: [debrief] needs you`; PASS | yes |
| P3-03 | 5 | `bash -n lib/desk.sh`; suite | ok; 168/168 | yes |
| P3-04 | 1 | check `DESK=1: a park starts one desk, the run end reuses it` (run.sh:485); origin is `git@github.com:test/proj.git` (run.sh:368) | desky ends `waiting on Michael: B`, `desky` once, `.in` = `Read …` then `New since your last brief: ended: waiting on Michael: B. Re-read …`, `desk started:` once; PASS | yes |
| P3-04 | 2 | check `DESK=0: no desk` (run.sh:427), placed before any desk | no `*/desk` dirs, no windows, no stub desk counter, no desk lines in any harness-log.md after parky parked and ended; PASS | yes |
| P3-04 | 3 | check `a desk that cannot start never changes the run` (run.sh:491) | deskno (DESK=1, NO_URL, WAIT=2) ends `waiting on Michael: B`, `[deskno] B needs you` in curl.log, `no session URL…plain notification` ×2, no window, 2/3 passing, clean worktree; PASS | yes |
| P3-04 | 4 | check `verify needs Michael starts a desk` (run.sh:495) | strict (continue, DESK=1, strict verifier) gets window `strict`, `.in` `Read <prompt>`, prompt contains `M1 needs Michael: A fails verification`; PASS (as a `continue`, per plan §9) | yes |
| P3-04 | 5 | check `the debrief starts a desk when Needs Michael is non-empty` (run.sh:500); `lib/debrief.sh:330` | `_Nothing._` → no `debrief` window; `STUB_DEBRIEF_NEEDS=1` → window; 2 `desk started:` in runner.log; PASS | yes |
| P3-04 | 6 | read `lib/driver.sh:121-129` desk(); hlogs via checks above; `bash -n lib/driver.sh lib/debrief.sh lib/desk.sh` | triggers note `desk started: <url> (<why>)` / `desk: … plain notification`; desk() returns 0 always, no `set -e`; syntax ok; 168/168 | yes |
| P3-05 | 1 | check `harness desk --list` (run.sh:505) | 5 lines for 5 windows: `parky parky <url> N min`, desky/strict same, `debrief (debrief) <url> N min`, `odd - - -`; PASS | yes |
| P3-05 | 2 | check `harness desk --close <run>` (run.sh:509) | `closed desk desky`, exit 0, window gone; `no desk for parkn` exit 0; PASS | yes |
| P3-05 | 3 | check `harness gc closes idle desks` (run.sh:515) | strict last-event 25 h ago → `closed idle desk strict`, window gone; parky (23 h) and debrief stay; dry run says `would close`; PASS | yes |
| P3-05 | 4 | check `harness desk --all` (run.sh:519) | `closed every desk (3)`, `tmux has-session` fails, second `--all` says `no desks`; suite exit 0 (trap tolerant); PASS | yes |
| P3-05 | 5 | `bin/harness:23-24`; `bash -n lib/desk.sh bin/harness` | header lists `--debrief`, `--list \| --close <run>\|--all`; ok | yes |
| P3-06 | 1 | `git diff 8f17332..HEAD -- lib bin tests prompts templates > /tmp/p3.diff` (734 lines, 11 files) read; `docs/plans/2026-10-19-P3-review.md` | findings I1, I2, M3–M10, R1–R8 each with severity, file:line, resolution; three questions answered no / no / no with reasons | yes |
| P3-06 | 2 | review names checks for I1, I2, R1, R2; scratch copy with I1+I2 guards removed → suite; R2 old regex tried standalone | 165/168: FAIL exactly `an open desk showing a dialog gets nothing typed`, `a refused merge tells Michael and his desk once`, `harness merge says it was refused again, and starts no desk`; `Do you want to` matches the desk's own question (R2 check red) | yes |
| P3-06 | 3 | `journal/decisions.md:310` | `### D-H31`: finding (by-hand 2.1.303 facts) · choice (claude --remote-control in tmux window, pane URL as click, one desk per run, DESK=0 until tried) · rejected (`claude remote-control` server mode; answers through ntfy) | yes |
| P3-06 | 4 | `docs/architecture.md` §3/§4/§7/§10/§17 | §3 lib/desk.sh, prompts/desk.md, tests "168 checks"; §4 `<state>/desk/` + `queue/desk/`; §7 "a desk failing to start never stops or fails the run"; §10 DESK_URL, DESK/DESK_MODEL; §17 "The desk starts itself" path; 168 = suite total | yes |
| P3-06 | 5 | `README.md:88-98,138`; `templates/user/config.sh:14-16` | Steering: phone notification, DESK=1, `harness desk --list`, `--close <run>\|--all`; Tests line 168 checks; template has `# DESK=0`, `# DESK_MODEL=opus` | yes |
| P3-06 | 6 | plan §"For Michael: turning it on" (lines 461-483) | stages by hand `harness desk <run> --why test` (DESK=0) → DESK=1 one night → always; checks per stage (phone opens session, brief reads INBOX, answer lands); undo `DESK=0`, `harness desk --all` | yes |
| P3-06 | 7 | `bash -n` on the 8 shell files changed since base; `node --check lib/*.mjs` (none changed in P3); suite | all ok; 168/168 | yes |

### 2026-10-19 16:20 · verify P3

| Feature | Step | What you ran or read | What you saw | Holds |
|---|---|---|---|---|
| P3-01 | 1 | read docs/plans/2026-10-19-P3-desk.md line 1 | 'Milestone base: 8f17332…', git rev-parse resolves it | yes |
| P3-01 | 2 | read plan §2: tmux new-session -s/-n/-c, claude --remote-control, capture-pane loop with the URL regex and HARNESS_DESK_WAIT:-60, send-keys -l then Enter, reuse via pane_dead | all present (lines 103-133, 183-184) | yes |
| P3-01 | 3 | read plan state-files table and §2.7 | desk/<stamp>.md, desk/url, desk/last-event, queue/desk/ and window 'debrief' in HARNESS_HOME described | yes |
| P3-01 | 4 | read plan stub section and §9 check list; tests/stub-claude.sh | no -p mode, fixture line, count, .in files, STUB_DESK_NO_URL, EXIT trap all specified and built | yes |
| P3-01 | 5 | read plan §7 and §8 | trigger points with why texts, desk() helper that never changes the run, DESK=0 DESK_MODEL=opus defaults | yes |
| P3-01 | 6 | `bash tests/run.sh` | full suite: 168/168 checks passed (my own run); no FAIL lines | yes |
| P3-02 | 1 | read tests/stub-claude.sh, tests/fixtures/remote-control-pane.txt, tests/run.sh:8-9; check 'the stub claude's interactive mode…' | fixture line 1 names source (claude 2.1.303, 2026-10-19); stub prints session_TEST<n>, appends stdin; trap kills session; PASS | yes |
| P3-02 | 2 | grep bin/harness, lib/config.sh; check 'DESK=0 by default, DESK_MODEL=opus' | desk) dispatches to lib/desk.sh, usage lists desk <run> [--why], defaults DESK=0 DESK_MODEL=opus; PASS | yes |
| P3-02 | 3 | read prompts/desk.md and check 'the desk prompt names the run, its commands and the never-list' | asserts each named item, no {{ placeholders; PASS | yes |
| P3-02 | 4 | check 'harness desk: one window, the Read line, the prompt, the notification click' | asserts exit 0, session_TEST1 output, one window 'parky', Read line, INBOX path, url file; PASS | yes |
| P3-02 | 5 | check 'the desk notification' | asserts Title, Priority: high, Click: session_TEST1; PASS | yes |
| P3-02 | 6 | check "the desk's claude: --remote-control, the model id, --add-dir…" | asserts argv --remote-control, opus model id, --add-dir worktree, PWD=project dir; PASS | yes |
| P3-02 | 7 | check "harness desk notes 'desk started:'…"; bash -n on all shell files; suite | line asserted exactly; bash -n clean; 168/168 | yes |
| P3-03 | 1 | check 'a second event reuses the desk window' | one 'parky' window, last .in line 'New since your last brief: C parked: db url. Re-read …', same click URL; PASS | yes |
| P3-03 | 2 | check 'no URL in time: no window, the plain notification' | exit 0, no window, log line with '2 s', plain title, no claude.ai Click; PASS | yes |
| P3-03 | 3 | check 'a dead desk is replaced' | fresh window, Read line, no 'New since'; PASS | yes |
| P3-03 | 4 | check 'harness desk --debrief' | window 'debrief', prompt in queue/desk names ledger/debrief.md and Needs Michael, title '[debrief] needs you'; PASS | yes |
| P3-03 | 5 | bash -n lib/desk.sh; suite | clean; 168/168 | yes |
| P3-04 | 1 | check 'DESK=1: a park starts one desk, the run end reuses it' | desky ends 'waiting on Michael: B', one window, Read then 'New since…ended: waiting on Michael: B', one 'desk started:'; PASS | yes |
| P3-04 | 2 | check 'DESK=0: no desk' (placed before the by-hand desk checks) | no desk dirs/windows/log lines; PASS | yes |
| P3-04 | 3 | check 'a desk that cannot start never changes the run' | still 'waiting on Michael: B', plain park notification, 'no session URL' logged; PASS | yes |
| P3-04 | 4 | check 'verify needs Michael starts a desk' | window 'strict', Read line, prompt names 'M1 needs Michael: A fails verification'; PASS | yes |
| P3-04 | 5 | check 'the debrief starts a desk when Needs Michael is non-empty' | no window without the flag, window with STUB_DEBRIEF_NEEDS=1; PASS | yes |
| P3-04 | 6 | grep harness-log assertions in the checks; bash -n driver/debrief/desk; suite | 'desk started:' and 'desk: … plain notification' asserted; bash -n clean; 168/168 | yes |
| P3-05 | 1 | check 'harness desk --list' | 5 lines with window, run, URL, 'N min', '-' for no URL; PASS | yes |
| P3-05 | 2 | check 'harness desk --close <run>' | 'closed desk desky', window gone; 'no desk for parkn' exit 0; PASS | yes |
| P3-05 | 3 | check 'harness gc closes idle desks' | 25 h strict closed ('closed idle desk strict'), fresh parky stays; PASS | yes |
| P3-05 | 4 | check 'harness desk --all' | all closed, has-session fails, trap tolerant; PASS | yes |
| P3-05 | 5 | harness help grep in the --list check; bash -n desk.sh bin/harness; suite | usage lists --list, --close|--all, --debrief; clean; 168/168 | yes |
| P3-06 | 1 | read docs/plans/2026-10-19-P3-review.md; base 8f17332 resolves | findings table with severity, file, resolution; three questions answered No/No/No | yes |
| P3-06 | 2 | read review header and finding rows | each Important/Critical names its red-before-fix check (suite 163/167 then 168/168; R rows) | yes |
| P3-06 | 3 | grep journal/decisions.md | '### D-H31' with Finding, Choice, Rejected (server mode; answers through ntfy) | yes |
| P3-06 | 4 | grep docs/architecture.md | §3 desk.sh/prompts, §4 desk/ and queue/desk, §7 guard text, §10 DESK/DESK_MODEL/DESK_URL, §17; table says 168 checks, run.sh has 168 | yes |
| P3-06 | 5 | grep README.md, templates/user/config.sh | desk paragraph with DESK=1, --list/--close; template has DESK, DESK_MODEL; Tests line 168 | yes |
| P3-06 | 6 | read end of the P3 plan | 'For Michael: turning it on' in 3 stages with checks and undo (DESK=0, desk --all) | yes |
| P3-06 | 7 | bash -n on every .sh, node --check every .mjs; suite | all clean; 168/168 | yes |

### 2026-10-19 15:45 · P3-06 · passes

- Review: `/tmp/p3.diff` (8f17332..HEAD, 642 lines) was read by an Opus reviewer, and this session's fixes by a second one. Everything is in `docs/plans/2026-10-19-P3-review.md`: 4 Important (I1, I2, R1, R2), 18 Minor, nothing Critical. The three questions are answered no, no, no. Tests 162 → 168.
  - I1: an open desk showing a dialog gets nothing typed. The typed Enter would have picked "Yes" for Michael. `DIALOG` holds the CLI's words, taken from the claude 2.1.303 binary's strings, in `tests/fixtures/permission-menu.txt`. The stub gained `STUB_DESK_MENU=1`.
  - I2/R1: a refused merge is told once per tag commit while the run goes. `harness merge` says so every time and starts no desk. `continue` clears `refused-*`.
  - R2: the regex doesn't match the desk's own questions.
  - gc closes idle desks first, then keeps the worktree of a run whose desk is open (P3-05's question).
  - tmux runs under `timeout --foreground 10`. A failed type no longer kills a live desk.
- Docs: architecture §3/§4/§7/§10/§17 (desk.sh, prompts/desk.md, state, the guard, DESK/DESK_MODEL/DESK_URL, the self-starting path, 168 checks), README Steering + Tests, `templates/user/config.sh`, D-H31 accepted/built, and the plan's "For Michael" stage 1 now tries the dialog guard.
- Verified: the first round's 4 new checks were red (163/167). R1's check was red on a scratch copy with only its fix reverted. R2's check was run standalone: FAIL on the old regex. All green after: `check.sh` 168/168. `bash -n` on every P3 .sh and `node --check` on lib/*.mjs pass.
- **For Michael:** the dialog guard matches the CLI's words, not a captured pane. Please do stage 1 of "turning it on" with a second event while the desk shows a permission dialog before you set DESK=1. Not changed: a by-hand desk during a retro loses its harness-log line (run.log keeps it), and real curl's bearer token is visible in `ps` (pre-P3).

### 2026-10-19 15:20 · P3-05 · passes

- `lib/desk.sh` gained housekeeping (before the run path):
  - `--list` prints one `printf '%-12s %-26s %-50s %s'` line per window: window, run (`(debrief)` for the debrief, `-` for a window that isn't a desk), URL (or `-`), age from `desk/last-event` (`<n> min|h|d`, or `-`). With no windows it prints `no desks`.
  - `--close <run>` kills the windows of that name by id and removes `desk/url`. It prints `closed desk <run>`, or `no desk for <run>`, and exits 0.
  - `--all` runs `kill-session` and prints `closed every desk (n)` (`no desks` when there are none).
  - `--gc <project> [--dry-run]` closes desks idle for over 24 h that still have a window open, the debrief's included. It prints `closed idle desk <run>`, or `would close …` on a dry run.
  - `bin/harness`: `cmd_gc` runs `desk.sh --gc` after its branch work, under `|| echo …`, so gc never fails on it. New usage line `harness desk --list | --close <run>|--all`; the help range is now `2,38p`.
  - Tests 158 → 162.
- Verified: the 4 new checks were red first (158/162) and green after. `check.sh` green in 238 s (162/162). In the kept state, `--list` showed parky/debrief/desky/strict with session_TEST5/10/6/9 at `0 min` and `odd - - -`. gc printed `closed idle desk strict` only; parky (23 h) stayed and stoppy (25 h, no window) was skipped. No tmux server was left after the suite.
- Opus review: no Critical or Important findings. Fixed:
  - `--close`, `--all` and non-dry `--gc` take `desk.lock`, so they can't kill a window a desk start is using.
  - `--close` matches the window name through `ENVIRON`, not `awk -v` (backslashes).
  - `--gc` exits 0 quietly on project names that run ids can't have.
  - `--all` logs `desk: closed every desk (n, …)` to `queue/runner.log`.
- Closes are logged only to run.log and runner.log, not to harness-log.md: a commit there would re-dirty the worktree gc just cleaned. Recorded as built in plan §10. **For P3-06:** gc can remove a finished run's worktree while that run's desk is still open (parky in the suite); the desk then loses its `--add-dir`. Should gc skip worktrees with an open desk, or close the desk with them? Docs (architecture, README, D-H31 built) are still P3-06's.

### 2026-10-19 14:48 · P3-04 · passes

- `lib/driver.sh`: a `desk "<why>"` helper (DESK=1 only; `harness desk <run> --why …`, output dropped, `9>&-`, a non-zero exit becomes the note `desk: could not start (exit n): …`, always returns 0). Called after a park's notification (`B parked: …`), in `needs_you` (`M1 needs Michael: A fails verification`, `… conflicts with main`), on a refused merge (`M1: merge refused`), and in `finish` for `blocked on…`/`waiting on Michael…` (`ended: …`, typed into the park's open desk). `lib/debrief.sh`: with DESK=1 and a non-empty "Needs Michael", it runs `harness desk --debrief` (failure → runner.log line). Usage headers updated. Tests 153 → 158 (the plan said 157; P3-03 added one more).
- **Deviation from plan §7:** the helper commits its own note at once (`HARNESS: desk` + sync). In `finish` the retro's `restrict` comes next. It commits leftovers as WIP and reverts everything since its base, which would drop the run-end desk note. Check 14 asserts that note.
- Verified: the 4 new driver/debrief checks were red before the code (154/158) and green after. `check.sh` green in 236 s (158/158). In kept state: desky's `.in` = `Read …` then `New since your last brief: ended: waiting on Michael: B. Re-read …`. deskno has 2 × `desk: no session URL within 2 s; killed the window; plain notification`, ended `waiting on Michael: B`, worktree clean. The debrief with `_Nothing._` started no desk. "DESK=0: no desk" can't go red on today's code, but its predicate is false on the kept post-desk state.
- Check 16 ("verify needs Michael") is a `continue strict` with DESK=1 inside the desk block, as P3-01 proposed, so parky's desk stays TEST1. Desks after P3-04: TEST6 desky, TEST7/8 deskno (no URL), TEST9 strict, TEST10 debrief.
- Opus review: no Critical/Important. Fixed: an empty `kill-window -t`, and a vacuous no-desk debrief check. **For P3-06 (Minor, not fixed):** (1) a refused merge re-notifies, and now re-briefs the desk, on every `merge_milestones` pass, and also under `harness merge` while Michael is at the terminal. Suggest a `refused-$m` once-guard and no desk when `HARNESS_MERGE_ONLY`. (2) The park `why` is session-written text typed into Michael's desk (sanitised, literal); say so in D-H31. (3) Plan §7's `desk()` snippet should show the commit (above). (4) `feature-list edits`/`initializer failed` ends start no desk (plan §7 as written). Should they, Michael?

### 2026-10-19 14:35 · P3-03 · passes

- `lib/desk.sh`: one desk per run. An open window (named the run, pane alive, `<state>/desk/url` kept) gets `New since your last brief: <why>. Re-read <new prompt>.` typed in, the same URL as the click, and the note `desk: sent to the open desk: <url> (<why>)`; if typing fails it starts a new desk. Any other window of that name is killed and replaced. No URL in time, claude exiting early, no tmux/claude, the lock or a tmux failure → `desk: <reason>; plain notification` (click = INBOX on GitHub), exit 0. `--debrief` → window `debrief`, cwd `$HARNESS_HOME`, state `queue/desk/`, log `queue/runner.log`, `--add-dir` worktrees + ledger. The run record is committed (3 tries) when the driver is gone. tmux runs under `env -u NTFY_TOKEN`. `bin/harness`: the usage line has `--debrief`, and `start` refuses run ids `desk`/`debrief`. Tests 147 → 153.
- Verified: checks 9–12 were red before the code (148/152). `check.sh` is green in 203 s (153/153). A smoke with `HARNESS_CLAUDE=false` printed `claude exited before it showed a session URL; …; notified`, exit 0. Desks in the suite: TEST1 parky, TEST2 stoppy (no URL, killed), TEST3 parky again, TEST4 debrief, TEST5 parky after a stale `sleep` window.
- Opus review: fixed: send-keys failure, NTFY_TOKEN in the tmux server's env, `desk` run-id collision, a clearer reason when claude exits early, `--add-dir` only for existing dirs, commit retry, "notified" only when a channel is set, and stronger checks (exit codes 1/2, plain body, stale window, `--add-dir` ledger, `ls -t`).
- **Open (Important, not fixed), for Michael / P3-06:** typing into an open desk is blind. If the desk is showing a permission menu (say, waiting on his approval of `harness continue`), the typed line and its Enter could pick "1. Yes" for him. A safe guard needs a real pane capture of Claude Code's permission menu as a fixture (we don't invent formats). Can you capture one (`tmux capture-pane -p -J -t h-desk:<run>` while a desk asks for permission) into `tests/fixtures/`? Until then the default (D-H31 as planned) types blind, and DESK stays 0.
- Next session (P3-04): the debrief desk prompt defaults its event to `the debrief names what needs you`. A second `harness desk --debrief` reuses window `debrief` the same way. Window ids in checks after P3-03: parky's live desk is TEST5.

### 2026-10-19 13:55 · P3-02 · passes

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
