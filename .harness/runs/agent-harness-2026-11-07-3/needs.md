# Needs Michael: agent-harness-2026-11-07-3

## ⚠ A1-03 asked: EVENT_URL may hold a webhook secret but sits on curl's comm…

`agent-harness-2026-11-07-3/1` · since 2026-11-07T21:19:22.952Z

**blocked** nothing waits on it; A1-03's session took the default its question names

**cost** the default stands until you answer

**question** [entries.jsonl:4](https://github.com/mh550/agent-harness/blob/harness/agent-harness-2026-11-07-3/.harness/runs/agent-harness-2026-11-07-3/entries.jsonl?plain=1#L4)

> EVENT_URL may hold a webhook secret but sits on curl's command line (ps, HARNESS_XTRACE traces) as NTFY_URL does; should lib/xtrace.sh's warning name it too, or the POST read the URL from a file (curl -K)? Default: left as is. Files: /home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-11-07-3/slot-0/docs/plans/2026-11-07-A1-review.md, /home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-11-07-3/slot-0/lib/notify.sh:62

**where** [/home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-11-07-3/slot-0/docs/plans/2026-11-07-A1-review.md](https://github.com/mh550/agent-harness/blob/harness-lane/agent-harness-2026-11-07-3/A1/docs/plans/2026-11-07-A1-review.md) · [/home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-11-07-3/slot-0/lib/notify.sh:62](https://github.com/mh550/agent-harness/blob/harness-lane/agent-harness-2026-11-07-3/A1/lib/notify.sh#L62) · [/home/mh550/worktrees/agent-harness/agent-harness-2026-11-07-3/.harness/runs/agent-harness-2026-11-07-3/entries.jsonl:4](https://github.com/mh550/agent-harness/blob/harness/agent-harness-2026-11-07-3/.harness/runs/agent-harness-2026-11-07-3/entries.jsonl?plain=1#L4)

- (a) record the answer (in the decision file it names), then harness needs done **(recommended: the default stands until you do)**
- (b) the default is right: harness needs done --why "default stands"

```sh
harness needs done agent-harness-2026-11-07-3/1 --why "<answer>"
```
