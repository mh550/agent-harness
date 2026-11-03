# Needs Michael: agent-harness-2026-11-03

## ⚠ Q1-02 asked: Default taken: an absolute --spec outside the project is ch…

`agent-harness-2026-11-03/1` · since 2026-11-03T17:33:08.366Z

**blocked** nothing waits on it; Q1-02's session took the default its question names

**cost** the default stands until you answer

**question** [entries.jsonl:3](https://github.com/mh550/agent-harness/blob/harness/agent-harness-2026-11-03/.harness/runs/agent-harness-2026-11-03/entries.jsonl?plain=1#L3)

> Default taken: an absolute --spec outside the project is checked as given and so refused (the run reads its worktree). Should one outside the project be allowed unchecked instead? Files: /home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-11-03/slot-0/journal/decisions/2026-10-31-spec-must-exist.md, /home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-11-03/slot-0/lib/spec.sh:29

**where** [/home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-11-03/slot-0/journal/decisions/2026-10-31-spec-must-exist.md](https://github.com/mh550/agent-harness/blob/harness-lane/agent-harness-2026-11-03/Q1/journal/decisions/2026-10-31-spec-must-exist.md) · [/home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-11-03/slot-0/lib/spec.sh:29](https://github.com/mh550/agent-harness/blob/harness-lane/agent-harness-2026-11-03/Q1/lib/spec.sh#L29) · [/home/mh550/worktrees/agent-harness/agent-harness-2026-11-03/.harness/runs/agent-harness-2026-11-03/entries.jsonl:3](https://github.com/mh550/agent-harness/blob/harness/agent-harness-2026-11-03/.harness/runs/agent-harness-2026-11-03/entries.jsonl?plain=1#L3)

- (a) record the answer (in the decision file it names), then harness needs done **(recommended: the default stands until you do)**
- (b) the default is right: harness needs done --why "default stands"

```sh
harness needs done agent-harness-2026-11-03/1 --why "<answer>"
```

## ⚠ C1-05 asked: Default taken: the TEST_JOBS=2 sentence sits in the shared …

`agent-harness-2026-11-03/2` · since 2026-11-03T21:17:23.366Z

**blocked** nothing waits on it; C1-05's session took the default its question names

**cost** the default stands until you answer

**question** [entries.jsonl:9](https://github.com/mh550/agent-harness/blob/harness/agent-harness-2026-11-03/.harness/runs/agent-harness-2026-11-03/entries.jsonl?plain=1#L9)

> Default taken: the TEST_JOBS=2 sentence sits in the shared prompts/coding.md (every project's sessions read it), not a project file. Keep it there? Files: /home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-11-03/slot-1/prompts/coding.md:24, /home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-11-03/slot-1/journal/decisions/2026-10-31-one-full-run.md

**where** [/home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-11-03/slot-1/prompts/coding.md:24](https://github.com/mh550/agent-harness/blob/harness-lane/agent-harness-2026-11-03/C1/prompts/coding.md#L24) · [/home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-11-03/slot-1/journal/decisions/2026-10-31-one-full-run.md](https://github.com/mh550/agent-harness/blob/harness-lane/agent-harness-2026-11-03/C1/journal/decisions/2026-10-31-one-full-run.md) · [/home/mh550/worktrees/agent-harness/agent-harness-2026-11-03/.harness/runs/agent-harness-2026-11-03/entries.jsonl:9](https://github.com/mh550/agent-harness/blob/harness/agent-harness-2026-11-03/.harness/runs/agent-harness-2026-11-03/entries.jsonl?plain=1#L9)

- (a) record the answer (in the decision file it names), then harness needs done **(recommended: the default stands until you do)**
- (b) the default is right: harness needs done --why "default stands"

```sh
harness needs done agent-harness-2026-11-03/2 --why "<answer>"
```
