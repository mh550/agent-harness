<!-- The dispatch list of one effort. Copy it to docs/plans/<YYYY-MM-DD>-<effort>-dispatch.md in the effort's project,
fill the brackets and delete the comments. How it is written and read: the `supervise` skill (agent-harness,
skills/supervise/). Everything here follows its Plain names section: a reader with no other file open can follow it. -->

# [The effort's name]: dispatch list ([date])

**Goal.** [Two or three plain sentences: what is wrong or wanted today, what will be true when the effort is done, and
the measure or acceptance that will show it.]

**Sources.** [The plan and spec files, each with a clause on what it holds.]

**Start the supervisor** (after a piece ends, or any time to see where things stand):

```bash
cd ~/projects/[project] && claude --model claude-fable-5-1 "/supervise docs/plans/[this file]"
```

## Status

| # | piece | kind | needs | status | result |
|---|---|---|---|---|---|
| 1 | [its name: what it does, in a clause] | [harness run · claude session · hand session · Michael] | – | not started | – |
| 2 | […] | […] | [by name: the baseline (1) merged] | not started | – |

<!-- Only pieces of the effort get a row: an idea for later is a Decisions item until Michael takes it.
status is one of: not started · given <date> (Michael has the command) · running: <run id> · ended short: <why> ·
missed: <what> · done (the supervisor's checks are in the result) · dropped.
result is one line, the evidence first: a PR, a file, the deciding number against what was expected. The longer
account goes in the Log. -->

## Decisions (Michael's)

<!-- Numbered once and for good, so "2: yes" means the same in any session. Open ones first. An open one: the
question in plain words, what waits on it, the options, the supervisor's recommendation. A decided one keeps its
answer and date: it is the effort's record of why. -->

1. **Open** · [the question] · waits on it: […] · options: […] · recommended: […]
2. **Decided [date]** · [the question]: [Michael's answer]

## Names

<!-- Every code, abbreviation and coined term this effort uses, in the words Michael would use. -->

| name | what it is |
|---|---|
| [M1] | [the first milestone of the …: …] |

## Rules for this effort

<!-- Only what CLAUDE.md does not already say. -->

- **Binds beyond `CLAUDE.md`:** […]
- **Order:** one piece at a time[, except …].
- **Check hardest:** [per piece or phase, the thing most likely to be wrong while the status looks green]
- **When a check misses:** [a diagnosis piece before the next one · measure again · Michael decides]
- **Done when:** [every row done, and …]

## Pieces

### 1 · [its name]

**What and why.** [One or two plain sentences.]
**Produces.** [The files, the PR, the number.]
**The supervisor checks.** [Commands and expected values; which of them Michael runs and pastes back.]
**Takes.** [About how long, attended or not, the cost if known.]

```bash
[the exact command Michael pastes]
```

## Log

<!-- Newest first. One entry per supervisor session: the date, what finished and its numbers, what Michael was given,
what was noticed. -->
