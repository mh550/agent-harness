# Needs Michael: agent-harness-2026-11-03-2

## ⚠ U1-02 asked: Default: a check that was an eval plus a CLI run now keeps …

`agent-harness-2026-11-03-2/1` · since 2026-11-04T01:41:53.795Z

**blocked** nothing waits on it; U1-02's session took the default its question names

**cost** the default stands until you answer

**question** [entries.jsonl:3](https://github.com/mh550/agent-harness/blob/harness/agent-harness-2026-11-03-2/.harness/runs/agent-harness-2026-11-03-2/entries.jsonl?plain=1#L3)

> Default: a check that was an eval plus a CLI run now keeps its old name on the part the name describes and the other part gets a new fixture name (4 new names in U1-02). Keep that, or should both parts stay under one name (the CLI run spawned from the unit test)?
> Files: /home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-11-03-2/slot-0/journal/decisions/2026-11-03-unit-tier.md, /home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-11-03-2/slot-0/tests/checks/12-journal-pure-e4-entrys.sh

**where** [/home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-11-03-2/slot-0/journal/decisions/2026-11-03-unit-tier.md](https://github.com/mh550/agent-harness/blob/harness-lane/agent-harness-2026-11-03-2/U1/journal/decisions/2026-11-03-unit-tier.md) · [/home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-11-03-2/slot-0/tests/checks/12-journal-pure-e4-entrys.sh](https://github.com/mh550/agent-harness/blob/harness-lane/agent-harness-2026-11-03-2/U1/tests/checks/12-journal-pure-e4-entrys.sh) · [/home/mh550/worktrees/agent-harness/agent-harness-2026-11-03-2/.harness/runs/agent-harness-2026-11-03-2/entries.jsonl:3](https://github.com/mh550/agent-harness/blob/harness/agent-harness-2026-11-03-2/.harness/runs/agent-harness-2026-11-03-2/entries.jsonl?plain=1#L3)

- (a) record the answer (in the decision file it names), then harness needs done **(recommended: the default stands until you do)**
- (b) the default is right: harness needs done --why "default stands"

```sh
harness needs done agent-harness-2026-11-03-2/1 --why "<answer>"
```
