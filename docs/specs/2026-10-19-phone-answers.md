# Answering the harness from a phone (2026-10-19)

**Goal.** When a run needs Michael, he understands what it needs from the notification alone, and answers in a minute
from his phone: by editing INBOX.md, or (the main path) in a chat with a Claude session on the box that the harness
starts for him (Remote Control), which briefs him, takes his decision as a chat message and passes it on. Three
milestones, in order: P1, P2, P3. Background: D-H26 (parking) and the 2026-10-19 research
note (`~/research/reports/Coding agent supervision layers.md`, not in this repo).

What exists: `notify "<text>"` in lib/driver.sh calls `NOTIFY_CMD` with the text as `$1` (Michael's is a `curl` to
an ntfy.sh topic with a `Title: harness` header). Parked features are in `<state>/parked.json`; a parking session
writes its question into the run's INBOX.md above `## Answers` and ends with `PARKED: <why>`. `harness answer <run>
<text>` queues an answer that the driver moves into INBOX.md before its next session. Michael runs
`claude remote-control --name desktop --permission-mode auto` in `~/projects` (tmux `rc-host`), so from the Claude
app he can start a session on the box whose working directory sees every project and this harness.

## P1 · Notifications carry the question and the links

1. **Structured notifications.** `notify` takes a message plus optional fields: title, longer body, a click URL,
   up to three view actions, and a priority. They reach the user's command as environment variables
   (`HARNESS_NOTIFY_TITLE`, `HARNESS_NOTIFY_BODY`, `HARNESS_NOTIFY_CLICK`, `HARNESS_NOTIFY_ACTIONS` in ntfy's
   `view, <label>, <url>; …` format, `HARNESS_NOTIFY_PRIORITY`). `$1` stays the one-line message, so an existing
   `NOTIFY_CMD` keeps working unchanged.
2. **Built-in ntfy.** New user settings `NTFY_URL` (topic URL) and `NTFY_TOKEN` (optional access token, sent as
   `Authorization: Bearer`). When `NTFY_URL` is set, the harness posts itself: body as the message, the fields as
   ntfy headers (`Title`, `Click`, `Actions`, `Priority`, `Tags`). The curl binary is `${HARNESS_CURL:-curl}` so
   tests use a stub that records its arguments. When both are set, NTFY_URL wins and NOTIFY_CMD is not called.
   The body is capped at 3500 bytes (ntfy.sh turns longer messages into attachments).
3. **A park notification** (the most important one):
   - title `[<run>] <feature> needs you` · priority high · tag `question`;
   - body: the `PARKED:` line, then the lines the parking session added to INBOX.md (diff against a copy the
     driver saves before every coding session; fall back to the `PARKED:` line alone), then
     `Answer: harness answer <run> "…"`; trimmed to the cap with `…`;
   - click: INBOX.md on the run branch on GitHub; actions: **Edit INBOX** (GitHub's edit URL for that file),
     **Answer with Claude** (`DESK_URL`, a new user setting, only when set), **Progress** (progress.md on GitHub).
   - GitHub URLs come from the project's `origin` (`git@github.com:o/r.git`, `https://github.com/o/r(.git)`); a
     non-GitHub origin gives no URLs (the notification still goes out without them).
4. **Other "needs Michael" notifications** (blocked, verify needs Michael, merge refused or conflicted, run end):
   priority high where Michael must act, and a click URL (the INBOX for blocks, the PR for merges, report.md on the
   run branch for a run's end).
5. Tests (stub curl): a park sends title, body containing the session's INBOX question and the answer command,
   click and the Edit INBOX action URL; `NOTIFY_CMD`-only configs still get `$1`; a body over the cap is trimmed;
   no URLs for a non-GitHub origin; `NTFY_TOKEN` is sent as a bearer header and never logged.

## P2 · An answer desk for phone sessions

1. **`harness parked [<run>]`**: every parked feature across runs (or one run): run, project, feature, since,
   why, the INBOX question (as in P1.3), whether the run is still going, and the exact next commands
   (`harness answer <run> "…"`, then `harness continue <run>`; or `harness queue add --continue <run>` when a queue
   runner is going). `--json` prints the same as JSON. Read-only.
2. **A skill for interactive sessions**, shipped in this repo as `skills/harness-answer/SKILL.md` (Michael installs
   it once with `ln -s ~/projects/agent-harness/skills/harness-answer ~/.claude/skills/`; README says so). It tells
   a session Michael opened from his phone how to handle "answer the harness" / "what does dj need?":
   - run `harness parked` and `harness status <run>`; read the run's INBOX.md and newest progress.md entries;
   - check what can be checked safely and say what it found: files, git, `docker ps`, a variable's **name**
     (`grep -c '^NAME=' file` style, never a value), never `.env` contents or other secrets, nothing with `sudo`;
   - propose the answer in one or two sentences, and only after Michael agrees: `harness answer <run> "<text>"`,
     then continue the run (`harness queue add --continue <run>` if `harness queue list` shows a runner going,
     else `harness continue <run>`);
   - never edit INBOX.md, feature lists, policies or CLAUDE.md directly; never answer without Michael's yes; never
     run a project's live commands.
3. **`DESK_URL`** (user setting, documented in README and in `templates/`): the Remote Control environment URL the
   "Answer with Claude" action opens.
4. Tests: `harness parked` on a parked run (the `parky` scenario in tests/run.sh) prints its id, why, question and
   both commands; `--json` parses; a run with nothing parked prints "nothing parked"; the skill file exists and
   names `harness parked`, `harness answer` and the never-list.

## P3 · A desk session starts itself when Michael is needed

When a run needs Michael, the harness starts an interactive Remote Control session on the box, gives it a brief to
prepare, and notifies him with a link that opens that session. He reads the brief there and answers in the chat; the
session turns his decision into an INBOX answer and continues the run.

**Verified by hand on 2026-10-19 (CLI 2.1.303), so build on exactly this:**
- `claude --remote-control "<name>"` inside a tmux window starts an interactive session with Remote Control on. Within
  a few seconds its pane shows a line like
  `/remote-control is active · Continue here, on your phone, or at https://claude.ai/code/session_01YSDT…`.
  That URL opens this session in the Claude app or on claude.ai: it is the notification's click URL.
- A prompt typed into the pane with `tmux send-keys -t <target> -l "<text>"`, then `tmux send-keys -t <target> Enter`,
  is submitted like typed input, and the reply appears in the pane and on the phone.
- The working directory must be one Michael has trusted (`~/projects/<project>` is; a fresh `~/worktrees/…` is not,
  and the trust prompt would block). Start in the project directory and pass the run's worktree with `--add-dir`.
- The session runs in auto mode (Michael's default). The documented alternative (`claude remote-control` server mode)
  takes no initial prompt and gives no per-session URL; don't use it.

1. **`harness desk <run> [--why "<one line>"]`** and **`harness desk --debrief`**: write a desk prompt to
   `<state>/desk/<stamp>.md` (template `prompts/desk.md`), start tmux session `h-desk`, window `<run>` (or `debrief`),
   running `claude --remote-control "desk · <run> · <why>" --model $DESK_MODEL --add-dir <worktree>` in the project
   directory; wait up to 60 s for the session URL in the pane; send `Read <prompt path> and follow it.` + Enter; then
   notify (P1) with title `[<run>] needs you: <why>`, a short body, and click = the session URL. Print the URL.
   - One desk per run: if that window exists and its claude is alive, send the new event into it instead
     (`New since your last brief: <why>. Re-read <new prompt path>.`) and notify with the same URL (kept in
     `<state>/desk/url`).
   - No URL within 60 s: kill the window, log it, and fall back to the P1 notification (nothing is lost).
2. **`prompts/desk.md`**, the desk's job, in this order:
   - Read what the run says it needs: `harness parked <run>`, `harness status <run>`, the run's INBOX.md (questions
     above `## Answers`), the newest progress.md entries, and for `--debrief` the newest `ledger/debrief.md`.
   - Check what can be checked safely, and say what was checked (P2.2's rules: names never values, no `.env`, no
     `sudo`, no live commands).
   - Write Michael **one brief**: a headline (what is waiting, since when, what it holds up); then each open item
     numbered, with the context needed to decide, the options, a recommendation and why. Short enough for a phone;
     the item numbers are what he answers to ("1 yes, 2 the later edit, 3 skip").
   - Wait for his reply. Ask follow-ups if an answer is ambiguous. Then record each decision with
     `harness answer <run> "<his decision, in his words, with the item it answers>"`, read it back to him, and on his
     go continue the run (`harness queue add --continue <run>` when a queue runner is going, else
     `harness continue <run>`). Never answer an item he didn't decide; never edit INBOX.md, feature lists, policies,
     CLAUDE.md or settings directly; never start other runs.
3. **When the driver starts a desk** (`DESK=1`, a new user setting, default 0 until Michael has tried it): when a
   feature parks; when a run ends `blocked on …` or `waiting on Michael: …`; when verify or a merge needs Michael.
   The debrief starts `harness desk --debrief` when its note has a non-empty "Needs Michael" section.
   `DESK_MODEL` defaults to `opus`. A desk failing to start never stops or fails the run.
4. **Housekeeping**: `harness desk --list` (window, run, URL, age) and `harness desk --close <run>|--all`;
   `harness gc` closes desks idle more than 24 h.
5. Tests: tmux is available in tests; use a stub `claude` (`HARNESS_CLAUDE`) that, in interactive mode, prints the
   `/remote-control is active · … https://claude.ai/code/session_TEST<n>` line, then records each line typed into it
   to a file. Check: a park with `DESK=1` starts one desk window, the stub received `Read <prompt> and follow it.`, the
   prompt names the run, its INBOX path and `harness answer`, and the notification's click is the session URL; a
   second event for the same run reuses the window; a stub that never prints a URL leads to the plain notification
   and no window; `--close` kills it. Kill every tmux session the tests create.

## Out of scope

Answers arriving through ntfy (an answer becomes an instruction to agents, so it must come through GitHub or a
session signed in as Michael); a Telegram channel; anything under `~/.claude` (Michael turns on the Claude app's
"Push when Claude decides" himself); changing how parking itself works. Tests never start a real `claude`.
