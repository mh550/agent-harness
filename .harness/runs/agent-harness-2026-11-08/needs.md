# Needs Michael: agent-harness-2026-11-08

## ⚠ N2-02 asked: Default taken (N2-02): a reused facts PR left open after a …

`agent-harness-2026-11-08/5` · since 2026-11-09T04:54:52.159Z

**blocked** nothing waits on it; N2-02's session took the default its question names

**cost** the default stands until you answer

**question** [entries.jsonl:11](https://github.com/mh550/agent-harness/blob/harness/agent-harness-2026-11-08/.harness/runs/agent-harness-2026-11-08/entries.jsonl?plain=1#L11)

> Default taken (N2-02): a reused facts PR left open after a failed body refresh is merged only by a later segment that pushes a new tier-1 commit; a segment with nothing new refreshes its body but does not merge it, so under auto it can stay open for good. Should a successful bare refresh also merge an already-pushed head? Files: /home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-11-08/slot-1/lib/record.sh:509, /home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-11-08/slot-1/journal/decisions/2026-11-08-memory-session-and-answers.md

**where** [/home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-11-08/slot-1/lib/record.sh:509](https://github.com/mh550/agent-harness/blob/harness-lane/agent-harness-2026-11-08/N2/lib/record.sh#L509) · [/home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-11-08/slot-1/journal/decisions/2026-11-08-memory-session-and-answers.md](https://github.com/mh550/agent-harness/blob/harness-lane/agent-harness-2026-11-08/N2/journal/decisions/2026-11-08-memory-session-and-answers.md) · [/home/mh550/worktrees/agent-harness/agent-harness-2026-11-08/.harness/runs/agent-harness-2026-11-08/entries.jsonl:11](https://github.com/mh550/agent-harness/blob/harness/agent-harness-2026-11-08/.harness/runs/agent-harness-2026-11-08/entries.jsonl?plain=1#L11)

- (a) record the answer (in the decision file it names), then harness needs done **(recommended: the default stands until you do)**
- (b) the default is right: harness needs done --why "default stands"

```sh
harness needs done agent-harness-2026-11-08/5 --why "<answer>"
```

## ⚠ N2-03 asked: The answers match by lineKey, which is factKey's first 40 n…

`agent-harness-2026-11-08/6` · since 2026-11-09T05:20:17.308Z

**blocked** nothing waits on it; N2-03's session took the default its question names

**cost** the default stands until you answer

**question** [entries.jsonl:12](https://github.com/mh550/agent-harness/blob/harness/agent-harness-2026-11-08/.harness/runs/agent-harness-2026-11-08/entries.jsonl?plain=1#L12)

> The answers match by lineKey, which is factKey's first 40 normalized characters: declining 'Never merge a PR before its verify passes and the suite is green' also drops a later 'Never merge a PR before its verify passes; a docs PR may skip it'. The spec asked for lineKey, so it stands (*default*). Should the gate match the whole normalized text instead? That is narrower, and a reworded rule could get through. Files: /home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-11-08/slot-1/lib/curator.mjs:40, /home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-11-08/slot-1/journal/decisions/2026-11-08-memory-session-and-answers.md

**where** [/home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-11-08/slot-1/lib/curator.mjs:40](https://github.com/mh550/agent-harness/blob/harness-lane/agent-harness-2026-11-08/N2/lib/curator.mjs#L40) · [/home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-11-08/slot-1/journal/decisions/2026-11-08-memory-session-and-answers.md](https://github.com/mh550/agent-harness/blob/harness-lane/agent-harness-2026-11-08/N2/journal/decisions/2026-11-08-memory-session-and-answers.md) · [/home/mh550/worktrees/agent-harness/agent-harness-2026-11-08/.harness/runs/agent-harness-2026-11-08/entries.jsonl:12](https://github.com/mh550/agent-harness/blob/harness/agent-harness-2026-11-08/.harness/runs/agent-harness-2026-11-08/entries.jsonl?plain=1#L12)

- (a) record the answer (in the decision file it names), then harness needs done **(recommended: the default stands until you do)**
- (b) the default is right: harness needs done --why "default stands"

```sh
harness needs done agent-harness-2026-11-08/6 --why "<answer>"
```

## ⚠ N2-04 asked: A rule you declined can come back as a tier-1 Gotcha: tier-…

`agent-harness-2026-11-08/7` · since 2026-11-09T05:45:37.437Z

**blocked** nothing waits on it; N2-04's session took the default its question names

**cost** the default stands until you answer

**question** [entries.jsonl:13](https://github.com/mh550/agent-harness/blob/harness/agent-harness-2026-11-08/.harness/runs/agent-harness-2026-11-08/entries.jsonl?plain=1#L13)

> A rule you declined can come back as a tier-1 Gotcha: tier-1 ops are never matched against your answers (the spec's rule), so a later curator that restates a declined `## Code rules` line under `## Gotchas` gets it applied, and merged under MEMORY_POLICY=auto (the write gate still needs a project discovery saying it). Default: unchanged, recorded as a known limit. Should declined rows also drop tier-1 adds and replaces of the same line? Files: /home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-11-08/slot-1/lib/curator.mjs, /home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-11-08/slot-1/docs/plans/2026-11-08-N2-review.md, /home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-11-08/slot-1/journal/decisions/2026-11-08-memory-session-and-answers.md

**where** [/home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-11-08/slot-1/lib/curator.mjs](https://github.com/mh550/agent-harness/blob/harness-lane/agent-harness-2026-11-08/N2/lib/curator.mjs) · [/home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-11-08/slot-1/docs/plans/2026-11-08-N2-review.md](https://github.com/mh550/agent-harness/blob/harness-lane/agent-harness-2026-11-08/N2/docs/plans/2026-11-08-N2-review.md) · [/home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-11-08/slot-1/journal/decisions/2026-11-08-memory-session-and-answers.md](https://github.com/mh550/agent-harness/blob/harness-lane/agent-harness-2026-11-08/N2/journal/decisions/2026-11-08-memory-session-and-answers.md) · [/home/mh550/worktrees/agent-harness/agent-harness-2026-11-08/.harness/runs/agent-harness-2026-11-08/entries.jsonl:13](https://github.com/mh550/agent-harness/blob/harness/agent-harness-2026-11-08/.harness/runs/agent-harness-2026-11-08/entries.jsonl?plain=1#L13)

- (a) record the answer (in the decision file it names), then harness needs done **(recommended: the default stands until you do)**
- (b) the default is right: harness needs done --why "default stands"

```sh
harness needs done agent-harness-2026-11-08/7 --why "<answer>"
```
