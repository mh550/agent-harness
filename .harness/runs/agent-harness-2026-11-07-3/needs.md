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

## ⚠ A2-01 asked: Default taken: the glossary also matches exact ids from the…

`agent-harness-2026-11-07-3/2` · since 2026-11-07T21:54:18.424Z

**blocked** nothing waits on it; A2-01's session took the default its question names

**cost** the default stands until you answer

**question** [entries.jsonl:6](https://github.com/mh550/agent-harness/blob/harness/agent-harness-2026-11-07-3/.harness/runs/agent-harness-2026-11-07-3/entries.jsonl?plain=1#L6)

> Default taken: the glossary also matches exact ids from the run's feature list that the spec's regexes miss (dj's N1F-01, S2-05a, S2-R1, N1F). Keep that, or stick to the spec's regexes only? Files: /home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-11-07-3/slot-1/docs/plans/2026-11-07-A2-context-bundle.md:60

**where** [/home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-11-07-3/slot-1/docs/plans/2026-11-07-A2-context-bundle.md:60](https://github.com/mh550/agent-harness/blob/harness-lane/agent-harness-2026-11-07-3/A2/docs/plans/2026-11-07-A2-context-bundle.md#L60) · [/home/mh550/worktrees/agent-harness/agent-harness-2026-11-07-3/.harness/runs/agent-harness-2026-11-07-3/entries.jsonl:6](https://github.com/mh550/agent-harness/blob/harness/agent-harness-2026-11-07-3/.harness/runs/agent-harness-2026-11-07-3/entries.jsonl?plain=1#L6)

- (a) record the answer (in the decision file it names), then harness needs done **(recommended: the default stands until you do)**
- (b) the default is right: harness needs done --why "default stands"

```sh
harness needs done agent-harness-2026-11-07-3/2 --why "<answer>"
```

## ⚠ A2-01 asked: Default taken: the debrief's own context also ends with the…

`agent-harness-2026-11-07-3/3` · since 2026-11-07T21:54:18.443Z

**blocked** nothing waits on it; A2-01's session took the default its question names

**cost** the default stands until you answer

**question** [entries.jsonl:6](https://github.com/mh550/agent-harness/blob/harness/agent-harness-2026-11-07-3/.harness/runs/agent-harness-2026-11-07-3/entries.jsonl?plain=1#L6)

> Default taken: the debrief's own context also ends with the ## Glossary section, so its session reads the IDs explained (within the context cap). Keep it, or keep the glossary in harness context bundles only? Files: /home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-11-07-3/slot-1/docs/plans/2026-11-07-A2-context-bundle.md

**where** [/home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-11-07-3/slot-1/docs/plans/2026-11-07-A2-context-bundle.md](https://github.com/mh550/agent-harness/blob/harness-lane/agent-harness-2026-11-07-3/A2/docs/plans/2026-11-07-A2-context-bundle.md) · [/home/mh550/worktrees/agent-harness/agent-harness-2026-11-07-3/.harness/runs/agent-harness-2026-11-07-3/entries.jsonl:6](https://github.com/mh550/agent-harness/blob/harness/agent-harness-2026-11-07-3/.harness/runs/agent-harness-2026-11-07-3/entries.jsonl?plain=1#L6)

- (a) record the answer (in the decision file it names), then harness needs done **(recommended: the default stands until you do)**
- (b) the default is right: harness needs done --why "default stands"

```sh
harness needs done agent-harness-2026-11-07-3/3 --why "<answer>"
```

## ⚠ A2-02 asked: The session's `git push -u origin harness-lane/agent-harnes…

`agent-harness-2026-11-07-3/4` · since 2026-11-07T22:06:59.351Z

**blocked** nothing waits on it; A2-02's session took the default its question names

**cost** the default stands until you answer

**question** [entries.jsonl:7](https://github.com/mh550/agent-harness/blob/harness/agent-harness-2026-11-07-3/.harness/runs/agent-harness-2026-11-07-3/entries.jsonl?plain=1#L7)

> The session's `git push -u origin harness-lane/agent-harness-2026-11-07-3/A2` was denied by the auto-mode classifier (Out-of-Place Publication); commit 62c1210 is local only. Should lane sessions be allowed that push, or does the harness push the lane branch itself? Files: /home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-11-07-3/slot-1/lib/glossary.mjs

**where** [/home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-11-07-3/slot-1/lib/glossary.mjs](https://github.com/mh550/agent-harness/blob/harness-lane/agent-harness-2026-11-07-3/A2/lib/glossary.mjs) · [/home/mh550/worktrees/agent-harness/agent-harness-2026-11-07-3/.harness/runs/agent-harness-2026-11-07-3/entries.jsonl:7](https://github.com/mh550/agent-harness/blob/harness/agent-harness-2026-11-07-3/.harness/runs/agent-harness-2026-11-07-3/entries.jsonl?plain=1#L7)

- (a) record the answer (in the decision file it names), then harness needs done **(recommended: the default stands until you do)**
- (b) the default is right: harness needs done --why "default stands"

```sh
harness needs done agent-harness-2026-11-07-3/4 --why "<answer>"
```

## ⚠ A2-04 asked: Default taken: a routed event's context bundle is synchrono…

`agent-harness-2026-11-07-3/5` · since 2026-11-07T23:05:09.340Z

**blocked** nothing waits on it; A2-04's session took the default its question names

**cost** the default stands until you answer

**question** [entries.jsonl:9](https://github.com/mh550/agent-harness/blob/harness/agent-harness-2026-11-07-3/.harness/runs/agent-harness-2026-11-07-3/entries.jsonl?plain=1#L9)

> Default taken: a routed event's context bundle is synchronous, capped at 60 s, before the 5 s POST, and events/ bundles older than 30 days are removed when a new one is written. Keep both? Files: /home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-11-07-3/slot-1/journal/decisions/2026-10-22-context-bundle-glossary.md, /home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-11-07-3/slot-1/lib/notify.sh:55

**where** [/home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-11-07-3/slot-1/journal/decisions/2026-10-22-context-bundle-glossary.md](https://github.com/mh550/agent-harness/blob/harness-lane/agent-harness-2026-11-07-3/A2/journal/decisions/2026-10-22-context-bundle-glossary.md) · [/home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-11-07-3/slot-1/lib/notify.sh:55](https://github.com/mh550/agent-harness/blob/harness-lane/agent-harness-2026-11-07-3/A2/lib/notify.sh#L55) · [/home/mh550/worktrees/agent-harness/agent-harness-2026-11-07-3/.harness/runs/agent-harness-2026-11-07-3/entries.jsonl:9](https://github.com/mh550/agent-harness/blob/harness/agent-harness-2026-11-07-3/.harness/runs/agent-harness-2026-11-07-3/entries.jsonl?plain=1#L9)

- (a) record the answer (in the decision file it names), then harness needs done **(recommended: the default stands until you do)**
- (b) the default is right: harness needs done --why "default stands"

```sh
harness needs done agent-harness-2026-11-07-3/5 --why "<answer>"
```

## ⚠ A3-01 asked: A duplicate request id (default): moved to requests/rejecte…

`agent-harness-2026-11-07-3/6` · since 2026-11-08T00:07:02.173Z

**blocked** nothing waits on it; A3-01's session took the default its question names

**cost** the default stands until you answer

**question** [entries.jsonl:12](https://github.com/mh550/agent-harness/blob/harness/agent-harness-2026-11-07-3/.harness/runs/agent-harness-2026-11-07-3/entries.jsonl?plain=1#L12)

> A duplicate request id (default): moved to requests/rejected/, the first result left as it is, a refused log line; no second result. Keep, or write the duplicate's refusal somewhere n8n reads? Files: /home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-11-07-3/slot-0/docs/plans/2026-11-07-A3-request-inbox.md:101

**where** [/home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-11-07-3/slot-0/docs/plans/2026-11-07-A3-request-inbox.md:101](https://github.com/mh550/agent-harness/blob/harness-lane/agent-harness-2026-11-07-3/A3/docs/plans/2026-11-07-A3-request-inbox.md#L101) · [/home/mh550/worktrees/agent-harness/agent-harness-2026-11-07-3/.harness/runs/agent-harness-2026-11-07-3/entries.jsonl:12](https://github.com/mh550/agent-harness/blob/harness/agent-harness-2026-11-07-3/.harness/runs/agent-harness-2026-11-07-3/entries.jsonl?plain=1#L12)

- (a) record the answer (in the decision file it names), then harness needs done **(recommended: the default stands until you do)**
- (b) the default is right: harness needs done --why "default stands"

```sh
harness needs done agent-harness-2026-11-07-3/6 --why "<answer>"
```

## ⚠ A3-01 asked: A rejected request's result has exit: null (default: no com…

`agent-harness-2026-11-07-3/7` · since 2026-11-08T00:07:02.191Z

**blocked** nothing waits on it; A3-01's session took the default its question names

**cost** the default stands until you answer

**question** [entries.jsonl:12](https://github.com/mh550/agent-harness/blob/harness/agent-harness-2026-11-07-3/.harness/runs/agent-harness-2026-11-07-3/entries.jsonl?plain=1#L12)

> A rejected request's result has exit: null (default: no command ran; n8n's card shows refused first). Keep null, or an integer like 2? Files: /home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-11-07-3/slot-0/docs/plans/2026-11-07-A3-request-inbox.md:101

**where** [/home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-11-07-3/slot-0/docs/plans/2026-11-07-A3-request-inbox.md:101](https://github.com/mh550/agent-harness/blob/harness-lane/agent-harness-2026-11-07-3/A3/docs/plans/2026-11-07-A3-request-inbox.md#L101) · [/home/mh550/worktrees/agent-harness/agent-harness-2026-11-07-3/.harness/runs/agent-harness-2026-11-07-3/entries.jsonl:12](https://github.com/mh550/agent-harness/blob/harness/agent-harness-2026-11-07-3/.harness/runs/agent-harness-2026-11-07-3/entries.jsonl?plain=1#L12)

- (a) record the answer (in the decision file it names), then harness needs done **(recommended: the default stands until you do)**
- (b) the default is right: harness needs done --why "default stands"

```sh
harness needs done agent-harness-2026-11-07-3/7 --why "<answer>"
```
