# Answering the harness from a phone (2026-10-19)

**Goal.** When a run needs Michael, he understands what it needs from the notification alone, and answers in a minute
from his phone: by editing INBOX.md, or by asking a Claude session on the box (Remote Control) to look into it and
answer for him once he says yes. Two milestones, in order. Background: D-H26 (parking) and the 2026-10-19 research
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

## Out of scope

Answers arriving through ntfy (an answer becomes an instruction to agents, so it must come through GitHub or a
session signed in as Michael); a Telegram channel; anything under `~/.claude`; changing how parking itself works.
