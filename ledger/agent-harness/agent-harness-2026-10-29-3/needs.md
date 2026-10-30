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

## ⚠ S2-01 asked: Default taken: the lint allows a `== "...<root>"` string co…

`agent-harness-2026-10-29-3/3` · since 2026-10-30T05:19:32.495Z

**blocked** nothing waits on it; S2-01's session took the default its question names

**cost** the default stands until you answer

**question** [entries.jsonl:8](https://github.com/mh550/agent-harness/blob/harness/agent-harness-2026-10-29-3/.harness/runs/agent-harness-2026-10-29-3/entries.jsonl?plain=1#L8)

> Default taken: the lint allows a `== "...<root>"` string compare (13:386's `PWD=$HH`) rather than mapping 13 (205 s) for it. Keep it? Files: /home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-10-29-3/slot-1/docs/plans/2026-10-30-S2-partial-key.md

**where** [/home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-10-29-3/slot-1/docs/plans/2026-10-30-S2-partial-key.md](https://github.com/mh550/agent-harness/blob/harness-lane/agent-harness-2026-10-29-3/S2/docs/plans/2026-10-30-S2-partial-key.md) · [/home/mh550/worktrees/agent-harness/agent-harness-2026-10-29-3/.harness/runs/agent-harness-2026-10-29-3/entries.jsonl:8](https://github.com/mh550/agent-harness/blob/harness/agent-harness-2026-10-29-3/.harness/runs/agent-harness-2026-10-29-3/entries.jsonl?plain=1#L8)

- (a) record the answer (in the decision file it names), then harness needs done **(recommended: the default stands until you do)**
- (b) the default is right: harness needs done --why "default stands"

```sh
harness needs done agent-harness-2026-10-29-3/3 --why "<answer>"
```

## ⚠ S2-01 asked: Default taken: a partial's rerun output goes to check-parti…

`agent-harness-2026-10-29-3/4` · since 2026-10-30T05:19:32.556Z

**blocked** nothing waits on it; S2-01's session took the default its question names

**cost** the default stands until you answer

**question** [entries.jsonl:8](https://github.com/mh550/agent-harness/blob/harness/agent-harness-2026-10-29-3/.harness/runs/agent-harness-2026-10-29-3/entries.jsonl?plain=1#L8)

> Default taken: a partial's rerun output goes to check-partial-rerun.out, not the spec's check-rerun.out (which stays the last full run's, beside its check.out). Keep it? Files: /home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-10-29-3/slot-1/docs/plans/2026-10-30-S2-partial-key.md, /home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-10-29-3/slot-1/lib/check.sh:87

**where** [/home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-10-29-3/slot-1/docs/plans/2026-10-30-S2-partial-key.md](https://github.com/mh550/agent-harness/blob/harness-lane/agent-harness-2026-10-29-3/S2/docs/plans/2026-10-30-S2-partial-key.md) · [/home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-10-29-3/slot-1/lib/check.sh:87](https://github.com/mh550/agent-harness/blob/harness-lane/agent-harness-2026-10-29-3/S2/lib/check.sh#L87) · [/home/mh550/worktrees/agent-harness/agent-harness-2026-10-29-3/.harness/runs/agent-harness-2026-10-29-3/entries.jsonl:8](https://github.com/mh550/agent-harness/blob/harness/agent-harness-2026-10-29-3/.harness/runs/agent-harness-2026-10-29-3/entries.jsonl?plain=1#L8)

- (a) record the answer (in the decision file it names), then harness needs done **(recommended: the default stands until you do)**
- (b) the default is right: harness needs done --why "default stands"

```sh
harness needs done agent-harness-2026-10-29-3/4 --why "<answer>"
```

## ⚠ S2-04 asked: 36 and 75 were rewritten (cd into docs/; bash "$HERE/lint-s…

`agent-harness-2026-10-29-3/5` · since 2026-10-30T07:05:27.545Z

**blocked** nothing waits on it; S2-04's session took the default its question names

**cost** the default stands until you answer

**question** [entries.jsonl:11](https://github.com/mh550/agent-harness/blob/harness/agent-harness-2026-10-29-3/.harness/runs/agent-harness-2026-10-29-3/entries.jsonl?plain=1#L11)

> 36 and 75 were rewritten (cd into docs/; bash "$HERE/lint-sleeps.sh") rather than joined to CHECK_KEY_MAP (default: ~125 s kept out of Gotchas-only runs). Keep that, or join them?
> Files: /home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-10-29-3/slot-1/journal/decisions/2026-10-30-partial-key.md, /home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-10-29-3/slot-1/tests/checks/36-run-16-retro-backlog.sh:19

**where** [/home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-10-29-3/slot-1/journal/decisions/2026-10-30-partial-key.md](https://github.com/mh550/agent-harness/blob/harness-lane/agent-harness-2026-10-29-3/S2/journal/decisions/2026-10-30-partial-key.md) · [/home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-10-29-3/slot-1/tests/checks/36-run-16-retro-backlog.sh:19](https://github.com/mh550/agent-harness/blob/harness-lane/agent-harness-2026-10-29-3/S2/tests/checks/36-run-16-retro-backlog.sh#L19) · [/home/mh550/worktrees/agent-harness/agent-harness-2026-10-29-3/.harness/runs/agent-harness-2026-10-29-3/entries.jsonl:11](https://github.com/mh550/agent-harness/blob/harness/agent-harness-2026-10-29-3/.harness/runs/agent-harness-2026-10-29-3/entries.jsonl?plain=1#L11)

- (a) record the answer (in the decision file it names), then harness needs done **(recommended: the default stands until you do)**
- (b) the default is right: harness needs done --why "default stands"

```sh
harness needs done agent-harness-2026-10-29-3/5 --why "<answer>"
```

## ⚠ S2-06 asked: The review's still-open lint holes (an alias of a sub-direc…

`agent-harness-2026-10-29-3/6` · since 2026-10-30T07:59:11.658Z

**blocked** nothing waits on it; S2-06's session took the default its question names

**cost** the default stands until you answer

**question** [entries.jsonl:13](https://github.com/mh550/agent-harness/blob/harness/agent-harness-2026-10-29-3/.harness/runs/agent-harness-2026-10-29-3/entries.jsonl?plain=1#L13)

> The review's still-open lint holes (an alias of a sub-directory followed by `..`, `process.env.ROOT`, a glob outside the quotes, `git -C <R> log -p`) are recorded in decisions/2026-10-30-partial-key, not closed (*default*: none occurs in the tree, and verify runs in full). Close them now? Files: /home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-10-29-3/slot-1/journal/decisions/2026-10-30-partial-key.md, /tmp/harness/agent-harness/agent-harness-2026-10-29-3/lanes/S2/S2-review.md

**where** [/home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-10-29-3/slot-1/journal/decisions/2026-10-30-partial-key.md](https://github.com/mh550/agent-harness/blob/harness-lane/agent-harness-2026-10-29-3/S2/journal/decisions/2026-10-30-partial-key.md) · `/tmp/harness/agent-harness/agent-harness-2026-10-29-3/lanes/S2/S2-review.md` · [/home/mh550/worktrees/agent-harness/agent-harness-2026-10-29-3/.harness/runs/agent-harness-2026-10-29-3/entries.jsonl:13](https://github.com/mh550/agent-harness/blob/harness/agent-harness-2026-10-29-3/.harness/runs/agent-harness-2026-10-29-3/entries.jsonl?plain=1#L13)

- (a) record the answer (in the decision file it names), then harness needs done **(recommended: the default stands until you do)**
- (b) the default is right: harness needs done --why "default stands"

```sh
harness needs done agent-harness-2026-10-29-3/6 --why "<answer>"
```
