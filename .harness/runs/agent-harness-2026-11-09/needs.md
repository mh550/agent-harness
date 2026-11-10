# Needs Michael: agent-harness-2026-11-09

## ⚠ R1-02 asked: Under MEMORY_POLICY=auto, should a continue whose review ho…

`agent-harness-2026-11-09/1` · since 2026-11-10T05:30:28.692Z

**blocked** nothing waits on it; R1-02's session took the default its question names

**cost** the default stands until you answer

**question** [entries.jsonl:3](https://github.com/mh550/agent-harness/blob/harness/agent-harness-2026-11-09/.harness/runs/agent-harness-2026-11-09/entries.jsonl?plain=1#L3)

> Under MEMORY_POLICY=auto, should a continue whose review holds its new facts merge a reused PR that carries an earlier segment's unreviewed commit? Default taken: no (the brief's 'merges only when the review ran and every committed op held'); the spec's §5 and R1-02 step 3 said it merges. Files: /home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-11-09/slot-0/lib/record.sh, /home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-11-09/slot-0/journal/decisions/2026-11-09-memory-reviewer.md

**where** [/home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-11-09/slot-0/lib/record.sh](https://github.com/mh550/agent-harness/blob/harness-lane/agent-harness-2026-11-09/R1/lib/record.sh) · [/home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-11-09/slot-0/journal/decisions/2026-11-09-memory-reviewer.md](https://github.com/mh550/agent-harness/blob/harness-lane/agent-harness-2026-11-09/R1/journal/decisions/2026-11-09-memory-reviewer.md) · [/home/mh550/worktrees/agent-harness/agent-harness-2026-11-09/.harness/runs/agent-harness-2026-11-09/entries.jsonl:3](https://github.com/mh550/agent-harness/blob/harness/agent-harness-2026-11-09/.harness/runs/agent-harness-2026-11-09/entries.jsonl?plain=1#L3)

- (a) record the answer (in the decision file it names), then harness needs done **(recommended: the default stands until you do)**
- (b) the default is right: harness needs done --why "default stands"

```sh
harness needs done agent-harness-2026-11-09/1 --why "<answer>"
```

## ⚠ R1-03 asked: Default taken (I1): under MEMORY_POLICY=auto the driver now…

`agent-harness-2026-11-09/2` · since 2026-11-10T06:06:28.298Z

**blocked** nothing waits on it; R1-03's session took the default its question names

**cost** the default stands until you answer

**question** [entries.jsonl:4](https://github.com/mh550/agent-harness/blob/harness/agent-harness-2026-11-09/.harness/runs/agent-harness-2026-11-09/entries.jsonl?plain=1#L4)

> Default taken (I1): under MEMORY_POLICY=auto the driver now merges a facts PR only when its one commit past main is the commit this segment pushed, so N2-02's continue (a reused PR whose body refresh failed) no longer merges the earlier commit with its own and waits for you. Keep that, or have the next segment's reviewer also read the earlier commit's diff as a carried/<sha12> item so it can merge? Files: /home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-11-09/slot-0/journal/decisions/2026-11-09-memory-reviewer.md, /home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-11-09/slot-0/docs/plans/2026-11-09-R1-review.md, /home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-11-09/slot-0/lib/record.sh

**where** [/home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-11-09/slot-0/journal/decisions/2026-11-09-memory-reviewer.md](https://github.com/mh550/agent-harness/blob/harness-lane/agent-harness-2026-11-09/R1/journal/decisions/2026-11-09-memory-reviewer.md) · [/home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-11-09/slot-0/docs/plans/2026-11-09-R1-review.md](https://github.com/mh550/agent-harness/blob/harness-lane/agent-harness-2026-11-09/R1/docs/plans/2026-11-09-R1-review.md) · [/home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-11-09/slot-0/lib/record.sh](https://github.com/mh550/agent-harness/blob/harness-lane/agent-harness-2026-11-09/R1/lib/record.sh) · [/home/mh550/worktrees/agent-harness/agent-harness-2026-11-09/.harness/runs/agent-harness-2026-11-09/entries.jsonl:4](https://github.com/mh550/agent-harness/blob/harness/agent-harness-2026-11-09/.harness/runs/agent-harness-2026-11-09/entries.jsonl?plain=1#L4)

- (a) record the answer (in the decision file it names), then harness needs done **(recommended: the default stands until you do)**
- (b) the default is right: harness needs done --why "default stands"

```sh
harness needs done agent-harness-2026-11-09/2 --why "<answer>"
```
