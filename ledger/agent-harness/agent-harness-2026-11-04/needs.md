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

## ⚠ T1-02 asked: 39-memlint-m4 was over 30 s in both re-timings (39.8 s, 39.…

`agent-harness-2026-11-04/2` · since 2026-11-04T07:34:03.706Z

**blocked** nothing waits on it; T1-02's session took the default its question names

**cost** the default stands until you answer

**question** [entries.jsonl:3](https://github.com/mh550/agent-harness/blob/harness/agent-harness-2026-11-04/.harness/runs/agent-harness-2026-11-04/entries.jsonl?plain=1#L3)

> 39-memlint-m4 was over 30 s in both re-timings (39.8 s, 39.6 s). I kept it fast (*default*) because the spec names it fast by exception, not by the 30 s line. Keep it fast, or move it to slow? Files: /home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-11-04/slot-0/journal/decisions/2026-11-03-suite-tiers.md

**where** [/home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-11-04/slot-0/journal/decisions/2026-11-03-suite-tiers.md](https://github.com/mh550/agent-harness/blob/harness-lane/agent-harness-2026-11-04/T1/journal/decisions/2026-11-03-suite-tiers.md) · [/home/mh550/worktrees/agent-harness/agent-harness-2026-11-04/.harness/runs/agent-harness-2026-11-04/entries.jsonl:3](https://github.com/mh550/agent-harness/blob/harness/agent-harness-2026-11-04/.harness/runs/agent-harness-2026-11-04/entries.jsonl?plain=1#L3)

- (a) record the answer (in the decision file it names), then harness needs done **(recommended: the default stands until you do)**
- (b) the default is right: harness needs done --why "default stands"

```sh
harness needs done agent-harness-2026-11-04/2 --why "<answer>"
```

## ⚠ T2-03 asked: Default taken: the full and fast lengths are rendered under…

`agent-harness-2026-11-04/3` · since 2026-11-04T10:25:42.427Z

**blocked** nothing waits on it; T2-03's session took the default its question names

**cost** the default stands until you answer

**question** [entries.jsonl:9](https://github.com/mh550/agent-harness/blob/harness/agent-harness-2026-11-04/.harness/runs/agent-harness-2026-11-04/entries.jsonl?plain=1#L9)

> Default taken: the full and fast lengths are rendered under *This session* (coding prompt), with run.md's fast Suite line saying `its last full and fast runs are under *This session*`, instead of the spec's `last full run …; last fast run …` inside run.md, to keep the shared prompt prefix (decisions/2026-10-30-suite-length-in-prompt). Keep it? Files: /home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-11-04/slot-1/prompts/parts/run.md, /home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-11-04/slot-1/journal/decisions/2026-11-03-fast-gate.md

**where** [/home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-11-04/slot-1/prompts/parts/run.md](https://github.com/mh550/agent-harness/blob/harness-lane/agent-harness-2026-11-04/T2/prompts/parts/run.md) · [/home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-11-04/slot-1/journal/decisions/2026-11-03-fast-gate.md](https://github.com/mh550/agent-harness/blob/harness-lane/agent-harness-2026-11-04/T2/journal/decisions/2026-11-03-fast-gate.md) · [/home/mh550/worktrees/agent-harness/agent-harness-2026-11-04/.harness/runs/agent-harness-2026-11-04/entries.jsonl:9](https://github.com/mh550/agent-harness/blob/harness/agent-harness-2026-11-04/.harness/runs/agent-harness-2026-11-04/entries.jsonl?plain=1#L9)

- (a) record the answer (in the decision file it names), then harness needs done **(recommended: the default stands until you do)**
- (b) the default is right: harness needs done --why "default stands"

```sh
harness needs done agent-harness-2026-11-04/3 --why "<answer>"
```

## ⚠ T2-04 asked: A slow-tier red at verify still stops the milestone for Mic…

`agent-harness-2026-11-04/4` · since 2026-11-04T10:56:10.901Z

**blocked** nothing waits on it; T2-04's session took the default its question names

**cost** the default stands until you answer

**question** [entries.jsonl:10](https://github.com/mh550/agent-harness/blob/harness/agent-harness-2026-11-04/.harness/runs/agent-harness-2026-11-04/entries.jsonl?plain=1#L10)

> A slow-tier red at verify still stops the milestone for Michael (verify_red, needs Michael), now with the cause named (default). Should it instead go back to a coding session (a fix feature) automatically? Files: /home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-11-04/slot-1/lib/lane.sh:132, /home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-11-04/slot-1/journal/decisions/2026-11-03-fast-gate.md

**where** [/home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-11-04/slot-1/lib/lane.sh:132](https://github.com/mh550/agent-harness/blob/harness-lane/agent-harness-2026-11-04/T2/lib/lane.sh#L132) · [/home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-11-04/slot-1/journal/decisions/2026-11-03-fast-gate.md](https://github.com/mh550/agent-harness/blob/harness-lane/agent-harness-2026-11-04/T2/journal/decisions/2026-11-03-fast-gate.md) · [/home/mh550/worktrees/agent-harness/agent-harness-2026-11-04/.harness/runs/agent-harness-2026-11-04/entries.jsonl:10](https://github.com/mh550/agent-harness/blob/harness/agent-harness-2026-11-04/.harness/runs/agent-harness-2026-11-04/entries.jsonl?plain=1#L10)

- (a) record the answer (in the decision file it names), then harness needs done **(recommended: the default stands until you do)**
- (b) the default is right: harness needs done --why "default stands"

```sh
harness needs done agent-harness-2026-11-04/4 --why "<answer>"
```

## ⚠ T2-04 asked: With a fast tier, finish's final `green` (lib/driver.sh:320…

`agent-harness-2026-11-04/5` · since 2026-11-04T10:56:10.964Z

**blocked** nothing waits on it; T2-04's session took the default its question names

**cost** the default stands until you answer

**question** [entries.jsonl:10](https://github.com/mh550/agent-harness/blob/harness/agent-harness-2026-11-04/.harness/runs/agent-harness-2026-11-04/entries.jsonl?plain=1#L10)

> With a fast tier, finish's final `green` (lib/driver.sh:320) runs the full suite uncached (~800 s here) when a run ends mid-milestone (limit, stop, deadline), since the last slot tree has only fast-<key>. Keep it full (default, the spec's), or let finish accept a fast-green there? Files: /home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-11-04/slot-1/lib/driver.sh:320

**where** [/home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-11-04/slot-1/lib/driver.sh:320](https://github.com/mh550/agent-harness/blob/harness-lane/agent-harness-2026-11-04/T2/lib/driver.sh#L320) · [/home/mh550/worktrees/agent-harness/agent-harness-2026-11-04/.harness/runs/agent-harness-2026-11-04/entries.jsonl:10](https://github.com/mh550/agent-harness/blob/harness/agent-harness-2026-11-04/.harness/runs/agent-harness-2026-11-04/entries.jsonl?plain=1#L10)

- (a) record the answer (in the decision file it names), then harness needs done **(recommended: the default stands until you do)**
- (b) the default is right: harness needs done --why "default stands"

```sh
harness needs done agent-harness-2026-11-04/5 --why "<answer>"
```

## ⚠ T2 asked: T2-03: keep the full/fast lengths under This session instea…

`agent-harness-2026-11-04/6` · since 2026-11-04T11:16:14.205Z

**blocked** nothing waits on it; T2's session took the default its question names

**cost** the default stands until you answer

**question** [entries.jsonl:11](https://github.com/mh550/agent-harness/blob/harness/agent-harness-2026-11-04/.harness/runs/agent-harness-2026-11-04/entries.jsonl?plain=1#L11)

> T2-03: keep the full/fast lengths under This session instead of run.md literally (recorded default in decisions/2026-11-03-fast-gate)?

**where** [/home/mh550/worktrees/agent-harness/agent-harness-2026-11-04/.harness/runs/agent-harness-2026-11-04/entries.jsonl:11](https://github.com/mh550/agent-harness/blob/harness/agent-harness-2026-11-04/.harness/runs/agent-harness-2026-11-04/entries.jsonl?plain=1#L11)

- (a) record the answer (in the decision file it names), then harness needs done **(recommended: the default stands until you do)**
- (b) the default is right: harness needs done --why "default stands"

```sh
harness needs done agent-harness-2026-11-04/6 --why "<answer>"
```
