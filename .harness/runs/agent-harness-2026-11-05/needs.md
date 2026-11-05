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
