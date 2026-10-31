# Needs Michael: agent-harness-2026-10-30

## ⚠ init asked: The run was queued on `docs/specs/2026-10-30-suite-cpu-and-…

`agent-harness-2026-10-30/1` · since 2026-10-30T21:05:18.434Z

**blocked** nothing waits on it; init's session took the default its question names

**cost** the default stands until you answer

**question** [entries.jsonl:1](https://github.com/mh550/agent-harness/blob/harness/agent-harness-2026-10-30/.harness/runs/agent-harness-2026-10-30/entries.jsonl?plain=1#L1)

> The run was queued on `docs/specs/2026-10-30-suite-cpu-and-flakes.md`, which is on no branch of the repo (fetched every ref; the live checkout is clean). I planned only what the title's flakes half supports from the data (F1: 6 features, fixes at the cause as R1 did, nothing in lib/check.sh or the driver's design); the CPU half (plan fixes 6 and 7: fewer process starts, the 8-job token) needs your spec. Options: (a) (recommended) let F1 run tonight, commit the spec, then queue a run on it: `harness queue add agent-harness --spec docs/specs/2026-10-30-suite-cpu-and-flakes.md --brief "F1 of agent-harness-2026-10-30 did the flakes; build the CPU half"`; (b) stop this run now if the flakes half isn't wanted: set `INBOX.md`'s first line to `status: stop` on branch harness/agent-harness-2026-10-30; (c) if the spec was meant to be suite-time.md: nothing to do, S1 and S2 are on main since run agent-harness-2026-10-29-3.
> Files: /home/mh550/worktrees/agent-harness/agent-harness-2026-10-30/docs/specs/, /home/mh550/worktrees/agent-harness/agent-harness-2026-10-30/.harness/runs/agent-harness-2026-10-30/feature_list.json, /home/mh550/worktrees/agent-harness/agent-harness-2026-10-30/docs/plans/2026-10-29-suite-time.md:56, /home/mh550/worktrees/agent-harness/agent-harness-2026-10-30/findings-and-research/2026-10-30-suite-load-curve.md

**where** [/home/mh550/worktrees/agent-harness/agent-harness-2026-10-30/docs/specs/](https://github.com/mh550/agent-harness/blob/harness/agent-harness-2026-10-30/docs/specs/) · [/home/mh550/worktrees/agent-harness/agent-harness-2026-10-30/.harness/runs/agent-harness-2026-10-30/feature_list.json](https://github.com/mh550/agent-harness/blob/harness/agent-harness-2026-10-30/.harness/runs/agent-harness-2026-10-30/feature_list.json) · [/home/mh550/worktrees/agent-harness/agent-harness-2026-10-30/docs/plans/2026-10-29-suite-time.md:56](https://github.com/mh550/agent-harness/blob/harness/agent-harness-2026-10-30/docs/plans/2026-10-29-suite-time.md#L56) · [/home/mh550/worktrees/agent-harness/agent-harness-2026-10-30/findings-and-research/2026-10-30-suite-load-curve.md](https://github.com/mh550/agent-harness/blob/harness/agent-harness-2026-10-30/findings-and-research/2026-10-30-suite-load-curve.md) · [/home/mh550/worktrees/agent-harness/agent-harness-2026-10-30/.harness/runs/agent-harness-2026-10-30/entries.jsonl:1](https://github.com/mh550/agent-harness/blob/harness/agent-harness-2026-10-30/.harness/runs/agent-harness-2026-10-30/entries.jsonl?plain=1#L1)

- (a) record the answer (in the decision file it names), then harness needs done **(recommended: the default stands until you do)**
- (b) the default is right: harness needs done --why "default stands"

```sh
harness needs done agent-harness-2026-10-30/1 --why "<answer>"
```

## ⚠ F1-01 asked: Default taken: the two 'under 1 s (best of 3)' status check…

`agent-harness-2026-10-30/2` · since 2026-10-30T21:09:06.130Z

**blocked** nothing waits on it; F1-01's session took the default its question names

**cost** the default stands until you answer

**question** [entries.jsonl:2](https://github.com/mh550/agent-harness/blob/harness/agent-harness-2026-10-30/.harness/runs/agent-harness-2026-10-30/entries.jsonl?plain=1#L2)

> Default taken: the two 'under 1 s (best of 3)' status checks keep their 1000 ms bound but measure CPU time (user+sys) instead of wall. OK, or would you rather keep wall and accept their rare red at 8-job paired load? Files: /home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-10-30/slot-0/docs/plans/2026-10-30-F1-flakes.md

**where** [/home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-10-30/slot-0/docs/plans/2026-10-30-F1-flakes.md](https://github.com/mh550/agent-harness/blob/harness-lane/agent-harness-2026-10-30/F1/docs/plans/2026-10-30-F1-flakes.md) · [/home/mh550/worktrees/agent-harness/agent-harness-2026-10-30/.harness/runs/agent-harness-2026-10-30/entries.jsonl:2](https://github.com/mh550/agent-harness/blob/harness/agent-harness-2026-10-30/.harness/runs/agent-harness-2026-10-30/entries.jsonl?plain=1#L2)

- (a) record the answer (in the decision file it names), then harness needs done **(recommended: the default stands until you do)**
- (b) the default is right: harness needs done --why "default stands"

```sh
harness needs done agent-harness-2026-10-30/2 --why "<answer>"
```

## ⚠ F1-01 asked: Default taken: when a file is stopped or killed, conformanc…

`agent-harness-2026-10-30/3` · since 2026-10-30T21:09:06.208Z

**blocked** nothing waits on it; F1-01's session took the default its question names

**cost** the default stands until you answer

**question** [entries.jsonl:2](https://github.com/mh550/agent-harness/blob/harness/agent-harness-2026-10-30/.harness/runs/agent-harness-2026-10-30/entries.jsonl?plain=1#L2)

> Default taken: when a file is stopped or killed, conformance's 'missing' names no longer suppress HARNESS_FAILED= (new/doubled still do), so check.sh reruns the broken files, not the whole suite; a check dropped elsewhere in the same tree is then caught only by the next full run. OK? Files: /home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-10-30/slot-0/docs/plans/2026-10-30-F1-flakes.md

**where** [/home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-10-30/slot-0/docs/plans/2026-10-30-F1-flakes.md](https://github.com/mh550/agent-harness/blob/harness-lane/agent-harness-2026-10-30/F1/docs/plans/2026-10-30-F1-flakes.md) · [/home/mh550/worktrees/agent-harness/agent-harness-2026-10-30/.harness/runs/agent-harness-2026-10-30/entries.jsonl:2](https://github.com/mh550/agent-harness/blob/harness/agent-harness-2026-10-30/.harness/runs/agent-harness-2026-10-30/entries.jsonl?plain=1#L2)

- (a) record the answer (in the decision file it names), then harness needs done **(recommended: the default stands until you do)**
- (b) the default is right: harness needs done --why "default stands"

```sh
harness needs done agent-harness-2026-10-30/3 --why "<answer>"
```

## ⚠ F1-02 asked: Default taken: beside the 1 s CPU bound, 52 and 53 keep a 5…

`agent-harness-2026-10-30/4` · since 2026-10-30T21:47:56.049Z

**blocked** nothing waits on it; F1-02's session took the default its question names

**cost** the default stands until you answer

**question** [entries.jsonl:3](https://github.com/mh550/agent-harness/blob/harness/agent-harness-2026-10-30/.harness/runs/agent-harness-2026-10-30/entries.jsonl?plain=1#L3)

> Default taken: beside the 1 s CPU bound, 52 and 53 keep a 5 s wall bound from the same `time` call, so a status that stalls without CPU (a lock, a git or gh wait) still fails; the load curve's worst wall was 1.4 s. Keep the 5 s wall bound, or drop it to the CPU bound alone as the plan's default had it? Files: /home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-10-30/slot-0/tests/checks/52-status-json.sh:73, /home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-10-30/slot-0/docs/plans/2026-10-30-F1-flakes.md:51

**where** [/home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-10-30/slot-0/tests/checks/52-status-json.sh:73](https://github.com/mh550/agent-harness/blob/harness-lane/agent-harness-2026-10-30/F1/tests/checks/52-status-json.sh#L73) · [/home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-10-30/slot-0/docs/plans/2026-10-30-F1-flakes.md:51](https://github.com/mh550/agent-harness/blob/harness-lane/agent-harness-2026-10-30/F1/docs/plans/2026-10-30-F1-flakes.md#L51) · [/home/mh550/worktrees/agent-harness/agent-harness-2026-10-30/.harness/runs/agent-harness-2026-10-30/entries.jsonl:3](https://github.com/mh550/agent-harness/blob/harness/agent-harness-2026-10-30/.harness/runs/agent-harness-2026-10-30/entries.jsonl?plain=1#L3)

- (a) record the answer (in the decision file it names), then harness needs done **(recommended: the default stands until you do)**
- (b) the default is right: harness needs done --why "default stands"

```sh
harness needs done agent-harness-2026-10-30/4 --why "<answer>"
```

## ⚠ F1-06 asked: Default taken (decisions/2026-10-30-cpu-time-bound-and-stop…

`agent-harness-2026-10-30/5` · since 2026-10-31T01:48:00.943Z

**blocked** nothing waits on it; F1-06's session took the default its question names

**cost** the default stands until you answer

**question** [entries.jsonl:8](https://github.com/mh550/agent-harness/blob/harness/agent-harness-2026-10-30/.harness/runs/agent-harness-2026-10-30/entries.jsonl?plain=1#L8)

> Default taken (decisions/2026-10-30-cpu-time-bound-and-stopped-files §2): a subset tests/run.sh is red on a check name the fixture lacks, so a session's subset is red until it adds the new name (the CLAUDE.md flow already says to add it). Keep, or check conformance only in check.sh's rerun? Files: /home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-10-30/slot-0/tests/run.sh:117, /home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-10-30/slot-0/journal/decisions/2026-10-30-cpu-time-bound-and-stopped-files.md

**where** [/home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-10-30/slot-0/tests/run.sh:117](https://github.com/mh550/agent-harness/blob/harness-lane/agent-harness-2026-10-30/F1/tests/run.sh#L117) · [/home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-10-30/slot-0/journal/decisions/2026-10-30-cpu-time-bound-and-stopped-files.md](https://github.com/mh550/agent-harness/blob/harness-lane/agent-harness-2026-10-30/F1/journal/decisions/2026-10-30-cpu-time-bound-and-stopped-files.md) · [/home/mh550/worktrees/agent-harness/agent-harness-2026-10-30/.harness/runs/agent-harness-2026-10-30/entries.jsonl:8](https://github.com/mh550/agent-harness/blob/harness/agent-harness-2026-10-30/.harness/runs/agent-harness-2026-10-30/entries.jsonl?plain=1#L8)

- (a) record the answer (in the decision file it names), then harness needs done **(recommended: the default stands until you do)**
- (b) the default is right: harness needs done --why "default stands"

```sh
harness needs done agent-harness-2026-10-30/5 --why "<answer>"
```
