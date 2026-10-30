# Needs Michael: agent-harness-2026-10-29-3

## ⚠ S1-02 asked: S1-02 put the suite's wall under # This session (a `Suite: …

`agent-harness-2026-10-29-3/1` · since 2026-10-30T02:50:02.680Z

**blocked** nothing waits on it; S1-02's session took the default its question names

**cost** the default stands until you answer

**question** [entries.jsonl:3](https://github.com/mh550/agent-harness/blob/harness/agent-harness-2026-10-29-3/.harness/runs/agent-harness-2026-10-29-3/entries.jsonl?plain=1#L3)

> S1-02 put the suite's wall under # This session (a `Suite: last full run …` line) rather than in run.md's This run Suite line, because the latter split the prompts' shared prefix that 08/13/14/15 check (default; decision file). Keep it there, or move it to run.md and relax the prefix checks to stop at the Suite line?
> Files: /home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-10-29-3/slot-0/journal/decisions/2026-10-30-suite-length-in-prompt.md, /home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-10-29-3/slot-0/prompts/coding.md:132

**where** [/home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-10-29-3/slot-0/journal/decisions/2026-10-30-suite-length-in-prompt.md](https://github.com/mh550/agent-harness/blob/harness-lane/agent-harness-2026-10-29-3/S1/journal/decisions/2026-10-30-suite-length-in-prompt.md) · [/home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-10-29-3/slot-0/prompts/coding.md:132](https://github.com/mh550/agent-harness/blob/harness-lane/agent-harness-2026-10-29-3/S1/prompts/coding.md#L132) · [/home/mh550/worktrees/agent-harness/agent-harness-2026-10-29-3/.harness/runs/agent-harness-2026-10-29-3/entries.jsonl:3](https://github.com/mh550/agent-harness/blob/harness/agent-harness-2026-10-29-3/.harness/runs/agent-harness-2026-10-29-3/entries.jsonl?plain=1#L3)

- (a) record the answer (in the decision file it names), then harness needs done **(recommended: the default stands until you do)**
- (b) the default is right: harness needs done --why "default stands"

```sh
harness needs done agent-harness-2026-10-29-3/1 --why "<answer>"
```

## ⚠ S1-05 asked: Review minor M5 left: 79's rw check can't tell the rerun's …

`agent-harness-2026-10-29-3/2` · since 2026-10-30T04:46:57.216Z

**blocked** nothing waits on it; S1-05's session took the default its question names

**cost** the default stands until you answer

**question** [entries.jsonl:6](https://github.com/mh550/agent-harness/blob/harness/agent-harness-2026-10-29-3/.harness/runs/agent-harness-2026-10-29-3/entries.jsonl?plain=1#L6)

> Review minor M5 left: 79's rw check can't tell the rerun's wall from start-to-end (a slow-first/instant-rerun inverse case would). And I1's residue: a session on a tree cached red by something outside the key (a port, a tool) has no form that runs the full suite on it; should check.sh get an escape hatch (e.g. HARNESS_CHECK_FRESH=1 skipping the red lookup), default: none? Files: /home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-10-29-3/slot-0/lib/check.sh:77, /home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-10-29-3/slot-0/journal/decisions/2026-10-30-red-marker.md

**where** [/home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-10-29-3/slot-0/lib/check.sh:77](https://github.com/mh550/agent-harness/blob/harness-lane/agent-harness-2026-10-29-3/S1/lib/check.sh#L77) · [/home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-10-29-3/slot-0/journal/decisions/2026-10-30-red-marker.md](https://github.com/mh550/agent-harness/blob/harness-lane/agent-harness-2026-10-29-3/S1/journal/decisions/2026-10-30-red-marker.md) · [/home/mh550/worktrees/agent-harness/agent-harness-2026-10-29-3/.harness/runs/agent-harness-2026-10-29-3/entries.jsonl:6](https://github.com/mh550/agent-harness/blob/harness/agent-harness-2026-10-29-3/.harness/runs/agent-harness-2026-10-29-3/entries.jsonl?plain=1#L6)

- (a) record the answer (in the decision file it names), then harness needs done **(recommended: the default stands until you do)**
- (b) the default is right: harness needs done --why "default stands"

```sh
harness needs done agent-harness-2026-10-29-3/2 --why "<answer>"
```
