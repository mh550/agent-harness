# Needs Michael: agent-harness-2026-11-08

## ⚠ N1-03 asked: The write order puts anchored adds before plain adds (the s…

`agent-harness-2026-11-08/1` · since 2026-11-08T08:26:38.686Z

**blocked** nothing waits on it; N1-03's session took the default its question names

**cost** the default stands until you answer

**question** [entries.jsonl:2](https://github.com/mh550/agent-harness/blob/harness/agent-harness-2026-11-08/.harness/runs/agent-harness-2026-11-08/entries.jsonl?plain=1#L2)

> The write order puts anchored adds before plain adds (the spec's order, written when an anchored add always evicted). Now that an anchored add appends while it fits, on a file at 14 Gotchas [plain add F2, anchored add F1] appends F1 and drops F2, where plain adds first would land both (F1 then evicting). Default kept: the spec's order. Swap to delete, replace, plain add, anchored add? Files: /home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-11-08/slot-0/lib/curator.mjs:144, /home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-11-08/slot-0/journal/decisions/2026-11-08-memory-rules-pr.md

**where** [/home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-11-08/slot-0/lib/curator.mjs:144](https://github.com/mh550/agent-harness/blob/harness-lane/agent-harness-2026-11-08/N1/lib/curator.mjs#L144) · [/home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-11-08/slot-0/journal/decisions/2026-11-08-memory-rules-pr.md](https://github.com/mh550/agent-harness/blob/harness-lane/agent-harness-2026-11-08/N1/journal/decisions/2026-11-08-memory-rules-pr.md) · [/home/mh550/worktrees/agent-harness/agent-harness-2026-11-08/.harness/runs/agent-harness-2026-11-08/entries.jsonl:2](https://github.com/mh550/agent-harness/blob/harness/agent-harness-2026-11-08/.harness/runs/agent-harness-2026-11-08/entries.jsonl?plain=1#L2)

- (a) record the answer (in the decision file it names), then harness needs done **(recommended: the default stands until you do)**
- (b) the default is right: harness needs done --why "default stands"

```sh
harness needs done agent-harness-2026-11-08/1 --why "<answer>"
```

## ⚠ N1-02 asked: CLAUDE.local.md is unguarded (*default*, the spec's choice)…

`agent-harness-2026-11-08/2` · since 2026-11-08T08:48:52.121Z

**blocked** nothing waits on it; N1-02's session took the default its question names

**cost** the default stands until you answer

**question** [entries.jsonl:3](https://github.com/mh550/agent-harness/blob/harness/agent-harness-2026-11-08/.harness/runs/agent-harness-2026-11-08/entries.jsonl?plain=1#L3)

> CLAUDE.local.md is unguarded (*default*, the spec's choice), but it is ignored only when the project's .gitignore names it; this repo's .gitignore and templates/project/ don't, so a session's write would be committed by git add -A and merge. Guard it in restrict's memory spec, or add it to templates/project/.gitignore? Files: /home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-11-08/slot-0/journal/decisions/2026-11-08-memory-rules-pr.md, /home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-11-08/slot-0/lib/record.sh:366

**where** [/home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-11-08/slot-0/journal/decisions/2026-11-08-memory-rules-pr.md](https://github.com/mh550/agent-harness/blob/harness-lane/agent-harness-2026-11-08/N1/journal/decisions/2026-11-08-memory-rules-pr.md) · [/home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-11-08/slot-0/lib/record.sh:366](https://github.com/mh550/agent-harness/blob/harness-lane/agent-harness-2026-11-08/N1/lib/record.sh#L366) · [/home/mh550/worktrees/agent-harness/agent-harness-2026-11-08/.harness/runs/agent-harness-2026-11-08/entries.jsonl:3](https://github.com/mh550/agent-harness/blob/harness/agent-harness-2026-11-08/.harness/runs/agent-harness-2026-11-08/entries.jsonl?plain=1#L3)

- (a) record the answer (in the decision file it names), then harness needs done **(recommended: the default stands until you do)**
- (b) the default is right: harness needs done --why "default stands"

```sh
harness needs done agent-harness-2026-11-08/2 --why "<answer>"
```

## ⚠ N1-04 asked: Default taken (N1-04): the union cap's drift is a line coun…

`agent-harness-2026-11-08/3` · since 2026-11-08T10:11:42.567Z

**blocked** nothing waits on it; N1-04's session took the default its question names

**cost** the default stands until you answer

**question** [entries.jsonl:5](https://github.com/mh550/agent-harness/blob/harness/agent-harness-2026-11-08/.harness/runs/agent-harness-2026-11-08/entries.jsonl?plain=1#L5)

> Default taken (N1-04): the union cap's drift is a line count (main's growth outside Gotchas since the rules tip's merge-base), not a three-way text merge; and a stale facts tip after main moved can still merge past the cap, as before N1. Keep the line count, and should the facts side get the same drift? Files: /home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-11-08/slot-0/docs/plans/2026-11-08-N1-review.md, /home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-11-08/slot-0/lib/curator.mjs

**where** [/home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-11-08/slot-0/docs/plans/2026-11-08-N1-review.md](https://github.com/mh550/agent-harness/blob/harness-lane/agent-harness-2026-11-08/N1/docs/plans/2026-11-08-N1-review.md) · [/home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-11-08/slot-0/lib/curator.mjs](https://github.com/mh550/agent-harness/blob/harness-lane/agent-harness-2026-11-08/N1/lib/curator.mjs) · [/home/mh550/worktrees/agent-harness/agent-harness-2026-11-08/.harness/runs/agent-harness-2026-11-08/entries.jsonl:5](https://github.com/mh550/agent-harness/blob/harness/agent-harness-2026-11-08/.harness/runs/agent-harness-2026-11-08/entries.jsonl?plain=1#L5)

- (a) record the answer (in the decision file it names), then harness needs done **(recommended: the default stands until you do)**
- (b) the default is right: harness needs done --why "default stands"

```sh
harness needs done agent-harness-2026-11-08/3 --why "<answer>"
```
