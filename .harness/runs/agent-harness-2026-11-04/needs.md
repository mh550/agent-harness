# Needs Michael: agent-harness-2026-11-04

## ⚠ init asked: The spec names one check file `NN-fast-gate.sh` for T2; the…

`agent-harness-2026-11-04/1` · since 2026-11-04T06:06:45.843Z

**blocked** nothing waits on it; init's session took the default its question names

**cost** the default stands until you answer

**question** [entries.jsonl:1](https://github.com/mh550/agent-harness/blob/harness/agent-harness-2026-11-04/.harness/runs/agent-harness-2026-11-04/entries.jsonl?plain=1#L1)

> The spec names one check file `NN-fast-gate.sh` for T2; the list plans two (86-fast-gate.sh, fast tier, the check.sh cases; 87-fast-gate-run.sh, the stub run, tier by the 30 s rule) so the check.sh cases run in the fast tier. Default taken: two files. Say so in INBOX.md if you want one.
> Files: /home/mh550/worktrees/agent-harness/agent-harness-2026-11-04/docs/specs/2026-11-03-suite-tiers.md:170, /home/mh550/worktrees/agent-harness/agent-harness-2026-11-04/.harness/runs/agent-harness-2026-11-04/feature_list.json

**where** [/home/mh550/worktrees/agent-harness/agent-harness-2026-11-04/docs/specs/2026-11-03-suite-tiers.md:170](https://github.com/mh550/agent-harness/blob/harness/agent-harness-2026-11-04/docs/specs/2026-11-03-suite-tiers.md#L170) · [/home/mh550/worktrees/agent-harness/agent-harness-2026-11-04/.harness/runs/agent-harness-2026-11-04/feature_list.json](https://github.com/mh550/agent-harness/blob/harness/agent-harness-2026-11-04/.harness/runs/agent-harness-2026-11-04/feature_list.json) · [/home/mh550/worktrees/agent-harness/agent-harness-2026-11-04/.harness/runs/agent-harness-2026-11-04/entries.jsonl:1](https://github.com/mh550/agent-harness/blob/harness/agent-harness-2026-11-04/.harness/runs/agent-harness-2026-11-04/entries.jsonl?plain=1#L1)

- (a) record the answer (in the decision file it names), then harness needs done **(recommended: the default stands until you do)**
- (b) the default is right: harness needs done --why "default stands"

```sh
harness needs done agent-harness-2026-11-04/1 --why "<answer>"
```
