---
name: harness-answer
description: Use when Michael asks to "answer the harness", "what does <project> need?", or opens a session from a harness notification's "Answer with Claude". Finds what the harness waits on, checks what can be checked safely, proposes answers, and passes them on only after his yes.
---

# Answering the harness

Michael is likely on his phone: keep every message short, numbered, and easy to answer with "1 yes, 2 skip".

## What to run first

1. `harness parked` (or `harness parked <run>`): every parked feature, with the question, since when, and the commands.
2. For each run listed, `harness status <run>`.
3. Read that run's INBOX.md above `## Answers` and the newest two entries of its progress.md, both in
   `~/worktrees/<project>/<run>/.harness/runs/<run>/`.

## What you may check

Read-only, and say what you checked:
- files, `git log` and `git status` in the run's worktree; `docker ps`.
- whether a variable is set, **by name only**: `grep -c '^NAME=' file` (`grep -cE '^(export )?NAME=' file` for shell
  files). Never print or look at a value.

Off limits: `.env` contents, tokens, keys and any other secret; anything with `sudo`; the project's live commands
(deploys, migrations, writes to a service).

## Proposing

One brief first: what is waiting, and since when. Then each open item, numbered: what you checked, the options, and your
recommendation in one or two sentences. Michael answers by number.

## Acting, only after his yes

For each item he decided, pass his words on through a quoted heredoc, so no backtick, `$` or quote in them is run or
expanded:

```bash
harness answer <run> "$(cat <<'HARNESS_ANSWER_END'
<his decision in his words, naming the item it answers>
HARNESS_ANSWER_END
)"
```

(If a line of his text is exactly `HARNESS_ANSWER_END`, pick another end word.)

Then read it back to him. Then continue the run once: `harness queue list`; with a runner going,
`harness queue add --continue <run>`, otherwise `harness continue <run>`. A run still going needs no continue; one
`ending` (its driver is wrapping up) needs it once `harness status <run>` shows it ended (`harness parked` says
which). An ambiguous reply gets a follow-up question, not a guess.

## Never

- Never edit INBOX.md, feature lists, policies or CLAUDE.md directly.
- Never answer without Michael's yes, or an item he didn't decide; never let his words reach the shell unquoted.
- Never run a project's live commands, and never `sudo`.
- Never start, stop or merge runs; the one `continue` above is the only run command besides `answer`.
