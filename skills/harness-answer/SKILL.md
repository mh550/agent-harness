---
name: harness-answer
description: Use when Michael asks to "answer the harness", "what does <project> need?", or opens a session from a harness notification's "Answer with Claude". Finds what the harness waits on, checks what can be checked safely, proposes answers, and passes them on only after his yes.
---

# Answering the harness

Michael is likely on his phone: keep every message short, numbered, and easy to answer with "1 yes, 2 skip".

## What to run first

1. `harness needs` (or `harness needs <run>`; `harness parked` is its alias): a card per item that waits on Michael
   (parked features with their question, verify and merge stops, given-up features: why, where, since when and the
   commands), then the questions sessions asked in their entries (`question` cards, after every stop);
   `harness needs <run> --json` gives each item's `card.commands` whole.
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

- **An overlap card open** (two runs on the same files): say which run merges first, and whether the commands you
  propose keep that order.
- **An edit Michael makes himself** (a feature-list `jq` the run proposed): run it to stdout first, never into the file,
  and show him the text it gives before he runs it.

## Question items

A `question` card (`<feature> asked: …`) is a judgment call a session already made: it took the default its question
names and went on, so nothing waits on it and no run needs a continue. Propose an answer like any other item, the
default among the options. After his yes:

1. If the question's `Files:` names a decision file (`journal/decisions/<date>-<slug>.md`), add one line to it in the
   run's worktree: `Updated in place <date>: Michael <his answer>` (today's date; his words). If it names none, and
   his answer is not "the default stands", pass it on with `harness answer <run>` as below (no continue: nothing
   waits on it), so it reaches `## Answers` and the run's next sessions read it; `needs done` alone keeps the answer
   only in the closed item, and a session that never sees it may ask again.
2. Close the item: `harness needs done <ref> --why "<his answer>"` (the card's `do` line; the default stands:
   `--why "default stands"`). Quote his words as for `harness answer` below.

A later session's entry that lists the question in `resolved` closes it too; one asked again in a later run of the
project moves there (`asked <n> times`), so answer it once, in the newest run.

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

Then read it back to him. Then continue the run once. A run still going needs no continue; one `ending` (its driver is
wrapping up) needs it once `harness status <run>` shows it ended (the card's `run` line, or `--json`'s `card.run_state`,
says which). First look in `harness status` for another live run of the same project (running, paused or ending; the
card's `run` line names it too):
- **None:** `harness queue list`; with a runner going, `harness queue add --continue <run>`, otherwise
  `harness continue <run>`.
- **One, R:** don't choose alone. Any continue without `--now` waits until R ends, maybe for hours, and R then merges
  first. Ask him, numbered:
  1. `harness queue add --continue <run>`: waits for R to end; R merges first.
  2. `harness continue <run> --now`: runs beside R; this run merges first if it finishes first.
  3. He stops R himself; once `harness status` shows it ended, a plain continue starts. Pausing R doesn't free the
     project.

**Then check it took:** `harness status <run>` again (and `harness queue list` after a queue add). Say whether the run
started, or is held and why (`held: <project> busy (R)`). An ambiguous reply gets a follow-up question, not a guess.

## Facts that matter

- `harness pause` keeps the driver alive, waiting (`lib/driver.sh:528-533`); `harness stop` ends it after the current
  session (`lib/driver.sh:527`).
- `harness continue` refuses a run whose driver is alive, a paused one too (`bin/harness:367`).
- Without `--now` (or `--foreground`), `harness continue` queues itself behind a live run of the same project
  (`bin/harness:372-381`); the queue runner holds its entries the same way (`lib/queue.sh:29`).
- `harness sync` by hand doesn't check whether a run is alive; only the queue runner does (`lib/sync.sh:3-4`). Suggest
  it only when `harness status` shows no run alive.
- A driver keeps the harness it started with: it reads its scripts as it runs, so a merged harness fix reaches a run
  only through a sync with nothing alive, then a continue (`lib/sync.sh:3-4`).

## Never

- Never edit INBOX.md, feature lists, policies or CLAUDE.md directly.
- Never answer without Michael's yes, or an item he didn't decide; never let his words reach the shell unquoted.
- Never run a project's live commands, and never `sudo`.
- Never start, stop, pause or merge runs; the one `continue` above is the only run command besides `answer`. You may
  suggest `harness stop` or `harness pause` for Michael to run himself.
