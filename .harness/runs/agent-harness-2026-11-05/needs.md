# Needs Michael: agent-harness-2026-11-05

## ⚠ init asked: The spec plans H1-02 as one feature; the list splits it int…

`agent-harness-2026-11-05/1` · since 2026-11-05T15:19:46.405Z

**blocked** nothing waits on it; init's session took the default its question names

**cost** the default stands until you answer

**question** [entries.jsonl:1](https://github.com/mh550/agent-harness/blob/harness/agent-harness-2026-11-05/.harness/runs/agent-harness-2026-11-05/entries.jsonl?plain=1#L1)

> The spec plans H1-02 as one feature; the list splits it into H1-02 (lib/helper.mjs and `ask`, no call site moved) and H1-02b (the call sites, the lifecycle, the helper-on/off log diff), so H1-04 stays the proof and the last build feature, six features in all. It also takes three defaults the spec does not name: a served script reads environment from `io.env`, a stdin-fed call never reaches the helper, and a call site whose stderr is redirected goes through `ask` only where a check shows bytes and destination identical. All are recorded as *default*; say so in INBOX.md if you want otherwise.
> Files: /home/mh550/worktrees/agent-harness/agent-harness-2026-11-05/docs/specs/2026-11-03-resident-helper.md:47, /home/mh550/worktrees/agent-harness/agent-harness-2026-11-05/.harness/runs/agent-harness-2026-11-05/feature_list.json

**where** [/home/mh550/worktrees/agent-harness/agent-harness-2026-11-05/docs/specs/2026-11-03-resident-helper.md:47](https://github.com/mh550/agent-harness/blob/harness/agent-harness-2026-11-05/docs/specs/2026-11-03-resident-helper.md#L47) · [/home/mh550/worktrees/agent-harness/agent-harness-2026-11-05/.harness/runs/agent-harness-2026-11-05/feature_list.json](https://github.com/mh550/agent-harness/blob/harness/agent-harness-2026-11-05/.harness/runs/agent-harness-2026-11-05/feature_list.json) · [/home/mh550/worktrees/agent-harness/agent-harness-2026-11-05/.harness/runs/agent-harness-2026-11-05/entries.jsonl:1](https://github.com/mh550/agent-harness/blob/harness/agent-harness-2026-11-05/.harness/runs/agent-harness-2026-11-05/entries.jsonl?plain=1#L1)

- (a) record the answer (in the decision file it names), then harness needs done **(recommended: the default stands until you do)**
- (b) the default is right: harness needs done --why "default stands"

```sh
harness needs done agent-harness-2026-11-05/1 --why "<answer>"
```

## ⚠ H1-01 asked: The spec's tail wrote and then exited; runCli waits for the…

`agent-harness-2026-11-05/2` · since 2026-11-05T15:36:14.659Z

**blocked** nothing waits on it; H1-01's session took the default its question names

**cost** the default stands until you answer

**question** [entries.jsonl:2](https://github.com/mh550/agent-harness/blob/harness/agent-harness-2026-11-05/.harness/runs/agent-harness-2026-11-05/entries.jsonl?plain=1#L2)

> The spec's tail wrote and then exited; runCli waits for the write and treats EPIPE as no failure, and a throw's partial stdout is dropped (rc 70, no out), both marked *default*. Say in INBOX.md if you want otherwise.
> Files: /home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-11-05/slot-0/lib/cli.mjs:21, /home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-11-05/slot-0/journal/decisions/2026-11-03-resident-helper.md:18

**where** [/home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-11-05/slot-0/lib/cli.mjs:21](https://github.com/mh550/agent-harness/blob/harness-lane/agent-harness-2026-11-05/H1/lib/cli.mjs#L21) · [/home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-11-05/slot-0/journal/decisions/2026-11-03-resident-helper.md:18](https://github.com/mh550/agent-harness/blob/harness-lane/agent-harness-2026-11-05/H1/journal/decisions/2026-11-03-resident-helper.md#L18) · [/home/mh550/worktrees/agent-harness/agent-harness-2026-11-05/.harness/runs/agent-harness-2026-11-05/entries.jsonl:2](https://github.com/mh550/agent-harness/blob/harness/agent-harness-2026-11-05/.harness/runs/agent-harness-2026-11-05/entries.jsonl?plain=1#L2)

- (a) record the answer (in the decision file it names), then harness needs done **(recommended: the default stands until you do)**
- (b) the default is right: harness needs done --why "default stands"

```sh
harness needs done agent-harness-2026-11-05/2 --why "<answer>"
```
