# The silent un-pass after a re-check: A4-01 in run agent-harness-2026-11-07-3 (2026-11-09)

**TL;DR.** The driver did not flip anything. A coding session's verdict is read from one place, the `passes` key of its
copy of `feature_list.json` (`lib/lane.sh:495` and `:501`), and the retry session of A4-01 ended with that key still
`false`: the verify had set it so, and the session's one permitted list edit (`"passes": true`, `prompts/coding.md` §3.1)
never happened. Its `entry.json` said `outcome: passes` and its final message said "A4-01 passes", and neither is
compared with the list, so the lane wrote `passes=false` with no note, spent the re-check's one granted attempt, and
closed `given up (nothing left to try)` with a `given_up` card whose *why* says "its sessions' entries say what failed"
while the entries say passes. Reproduced in a throwaway stub run with the same log shape; the baseline (a retry that
flips the key) verifies and merges. Outcome: **fix**, specified in `docs/specs/2026-11-09-silent-unpass-fix.md`.

## 1. The case

Run `agent-harness-2026-11-07-3` (the n8n events run; its record is on `main` under
`.harness/runs/agent-harness-2026-11-07-3/`). `harness-log.md` lines 78–87:

```
20:28 · A4-01: suite ran 1x (119 s) in the session
20:28 · A4-01 · claude-sonnet-5-5 · passes=true · 3 min · 14/14 passing · tests 1898
20:28 · merged main into harness-lane/agent-harness-2026-11-07-3/A4
20:28 · verify A4: suite cache cleared; the suite runs in full on the verified tree
20:42 · verify A4: A4-01 failed the re-check, back in the queue (one more attempt)
20:42 · context.md for A4-01: 7925 bytes, 11 items left out
20:45 · A4-01: suite ran 1x (120 s) in the session
20:45 · A4-01 · claude-sonnet-5-5 · passes=false · 2 min · 13/14 passing · tests 1898
20:45 · lane A4 closed (given up (nothing left to try))
```

The retry's entry (`entries.jsonl`, `session: "15-A4-01"`) is the session's own (no `minimal` key): `outcome: "passes"`,
summary "Fixed the verify's finding: docs/architecture.md's lib/debrief.sh row said … since=; it passes bundle=$WS",
`verified_how` "… check.sh --fast green 1064 tests". Its `metrics.jsonl` row: `passes: false`, `exit: 0`,
`result: "success"`, `turns: 5`, `wall_s: 136`, final "A4-01 passes. I fixed the one finding from the verify …". The
record's `feature_list.json` has A4-01 `passes: false`. `needs.md` carries the card `⚠ A4-01 given up after 2 attempts`
with the why "Each feature gets MAX_ATTEMPTS (2) fresh sessions … A4-01 used them without passing … Its sessions'
entries say what failed." The retro's proposal `verify-failed-recheck` reads the same lines as "the retry fixed the
finding (outcome passes) but log says passes=false and lane A4 closed given up at the same minute".

## 2. The session-end path, as read

`lib/lane.sh`, from the coding session's exit to its `passes=` line (line numbers of `main` at `9c63080`):

| line | what | can it make `passes=false`? | its note |
|---|---|---|---|
| 463 | `commit_all`, `memory_guard`, `sync_lane` | no (memory paths only) | one per reverted file |
| 467 | `journal coding …` ingests `entry.json`; a *valid* entry keeps its own `outcome` (`entries.mjs journalEntry` → `normalize(e)`); only a missing or invalid one gets the driver's outcome, which `record.sh:852` derives from the list | no | `entry.json … recorded a minimal entry` |
| 468–470 | `inbox_repair`, `take_question`, `lane_guard` | no (`lane_guard` resets the index only; "the copy on disk is what F repair and the claim read") | `a lane commit touched the run record; reverted` |
| 473–485 | a usage limit: the copy goes, the attempt is given back | no row with `passes` | `session for <id> hit a limit` |
| 489 | `F repair "$SLIST" before.json "$id"`: every list edit but the feature's own `passes` is reverted; its flip, kept | no (a reverted foreign flip is named) | `restored the feature list after <id>: …` |
| **495** | **`if F passes "$SLIST" "$id"`: the copy's `passes` key is the claim** | **a `false` here skips the whole gate block; nothing is written** | **none** |
| 496–497 | the gate: `green_fix` for a fix feature, else `green_fast`; a red un-passes | yes | `<id> un-passed: fast tier red after the session` / `… <FIX_RED> red` |
| 501 | `passed=$(F passes "$SLIST" "$id" && echo true \|\| echo false)` | the verdict, read again | none |
| 507–517 | a sonnet review that found something: `passed=false`, one round on the escalation model | yes | `review <id>: sonnet found …; one round on …` |
| 519 | `record F pass`/`F unpass "$LIST"`: the verdict reaches the record | — | — |
| 521 | the `passes=` note | — | this is the line the case shows |
| 533–534 | `passed=false` and attempts ≥ `MAX_ATTEMPTS`: `needs_open given_up` | — | no note here; the card |

`F` (`lib/record.sh:184`) memoizes `passes` on the sha1 of the list's bytes, so a stale memo cannot answer for a list
whose key changed; `ask` falls back to a node spawn when the resident helper fails, so a helper failure cannot read as
`false` without a `helper …` line in `run.log`. `pack_and_copy` (`record.sh:1443`) copies the record into the slot
before every session and snapshots it as `before.json`; after the verify's `record F unpass` (line 171) that copy has
the feature at `false`, so a retry starts at `false` and must write `true` itself.

The re-check: `verify()` applies the verifier's un-passes to the record (line 171), and in the `fail` branch (lines
251–260) grants each un-passed feature exactly one attempt (`F grant "$ATT" "$id" "$MAX_ATTEMPTS"`: attempts become
`MAX_ATTEMPTS - 1`) with the note `verify <m>: <id> failed the re-check, back in the queue (one more attempt)`. The
give-up: `features.mjs schedule` treats a feature with `attempts >= max` as given up; `blockedLines` lists only the
features *waiting on* a given-up one, so a given-up feature with no dependants makes the lane's exit
`given up (nothing left to try)` (line 419): the id and the reason are not in the words.

So the driver has exactly one path to `passes=false` with none of its notes: the copy's list says `false` at line 495.
Every other way (repair, the fast tier, a fix red, a review round, a limit) writes a line. The entry's `outcome` is
read by nothing on this path.

## 3. What I ran

Two stub runs in `tests/lib.sh`'s throwaway environment, traced with `HARNESS_XTRACE` (`TEST_XTRACE_DIR`), on the
suite's `demo` scenario (the one `park-desk.sh`, `stop-records.sh`, `queue-debrief.sh` and `run-scopes-services-gc.sh`
replay for "verifier caught A, re-queued"): A passes, B passes, verify M1 round 1 un-passes A, A is retried.

- **baseline**: `tests/stub-claude.sh` as on `main`. The retry (`A attempt 2`) runs `set_passes A true`, writes its
  entry with `outcome: passes`, commits.
- **noflip**: a copy of the stub in my scratch directory with one change, `STUB_NO_FLIP=A:2`: that one session skips
  `set_passes`, writes the same entry (`outcome: passes`) and ends with the final message "A passes. The commit is
  pushed." Nothing else differs (the diff is two lines; the copy symlinks `tests/fixtures`, `bin` and `lib` so the stub
  finds them through `$HERE`). Nothing under `tests/` was changed.

Both ran at once, under a minute, with `harness status` showing no run of this project alive or queued before and
after.

## 4. The cause, with the evidence

**It reproduces.** The noflip run's `harness-log.md` (its `$T` was `/tmp/tmp.XN7Ku66J0Q`, kept with `KEEP=1`):

```
17:36 · verify M1: A failed the re-check, back in the queue (one more attempt)
17:36 · context.md for A: 513 bytes
17:36 · A: suite ran 0x (0 s) in the session
17:36 · A · claude-sonnet-5-5 · passes=false · 0 min · 1/3 passing
17:36 · lane M1 closed (given up (nothing left to try))
17:36 · blocked: the remaining features wait on A (given up; needs Michael)
```

the same six lines as the case, with no note between the session's end and `passes=false`. Its `entries.jsonl` has
A's second entry `outcome: "passes"`, `minimal: null`; its `metrics.jsonl` row `passes: false, exit: 0,
result: "success", final: "A passes. The commit is pushed."`; its `needs.md` the card `⚠ A given up after 2 attempts`
with the why "… Its sessions' entries say what failed." `run.log` (the throwaway's state, lines 30–37) adds nothing
between `coding exit 0 · 4fbeca7 A: stub work (2)` and the `passes=false` line: no `helper`, no repair, no gate.

The baseline's same stretch:

```
17:36 · verify M1: A failed the re-check, back in the queue (one more attempt)
17:36 · A · claude-sonnet-5-5 · passes=true · 0 min · 2/3 passing
17:36 · verify M1: suite cache cleared; the suite runs in full on the verified tree
17:36 · lane M1 closed (M1 merged)
```

so with the key flipped, the re-check's retry is verified (round 2) and merged: the lane never needed to "re-verify
only the failed steps"; it re-verifies the milestone as soon as every feature passes again.

**The line.** The lane process's trace, the retry's session (third `lane.sh:489` in each trace; paths cut):

noflip (`xtrace-noflip/repro/1083140.xtrace`, lines 88985–90507):

```
+lib/lane.sh:489: out=                                   ← F repair: nothing reverted
+lib/lane.sh:489: repairs=0
+lib/lane.sh:495: F passes …/slot-0/.harness/runs/demo/feature_list.json A
+lib/record.sh:217: F_RC=1                               ← the copy says false
+lib/lane.sh:499: flakes_note                            ← lines 496–497 (the gate) never ran
+lib/lane.sh:500: tests_end
++lib/lane.sh:501: F passes …/slot-0/.harness/runs/demo/feature_list.json A
++lib/record.sh:217: F_RC=1
++lib/lane.sh:501: echo false
+lib/lane.sh:501: passed=false
+lib/lane.sh:519: record F unpass …/demo/.harness/runs/demo/feature_list.json A
+lib/lane.sh:533: ((  2 >= MAX_ATTEMPTS  ))
+lib/lane.sh:534: needs_open given_up A feature=A attempts=2 max_attempts=2 log=…/logs/03-A.jsonl
+lib/lane.sh:536: rec_commit 'HARNESS: after A (passes=false)'
```

baseline (`xtrace-baseline/repro/1083199.xtrace`, lines 88886–91686):

```
+lib/lane.sh:495: F passes …/slot-0/.harness/runs/demo/feature_list.json A
+lib/record.sh:217: F_RC=0                               ← the copy says true
+lib/lane.sh:496: [[ build == fix ]]
+lib/lane.sh:497: green_fast                             ← the gate runs, green
++lib/lane.sh:501: echo true
+lib/lane.sh:501: passed=true
+lib/lane.sh:519: record F pass …/demo/.harness/runs/demo/feature_list.json A
+lib/lane.sh:533: [[ true == false ]]
+lib/lane.sh:536: rec_commit 'HARNESS: after A (passes=true)'
```

The two traces diverge at `lib/lane.sh:495` on `F_RC`, and nowhere before it: same repair result, same entry, same
commit shape. The one input that differs is the `passes` key of the session's copy of the list.

**The cause, in words.** The harness's contract is that the list is the feature's verdict and the session's one list
edit is the flip (`prompts/coding.md` §3.1: "Only when all hold … set `"passes": true` on it. That is the **only** edit
you may make to `feature_list.json`"). The driver reads that key and nothing else (`lane.sh:495`, `:501`). The journal
has the session's `outcome` in hand four lines earlier (`journal`, line 467, `entries.mjs ingest`) and never compares it
with the key; so a session that does the work, says `passes` in its entry and its final message, and never writes the
key, is read as "not yet" with no line saying so. In the case, that session was the re-check's one granted attempt
(`attempts = MAX_ATTEMPTS - 1` after `F grant`), so its `false` spent the last attempt and `schedule` gave the feature
up; `blockedLines` had no dependant to name, so the lane closed `given up (nothing left to try)`, and the `given_up`
card's fixed why ("its sessions' entries say what failed") pointed Michael at two entries that both say passes.

**What I could not read.** The real session's transcript (`logs/15-A4-01.jsonl` in the run's state) is the only thing
that shows *why* the key stayed false: the session never edited `feature_list.json` (the likely case: 5 turns, 136 s,
120 of them the fast tier), edited it outside its slot, or wrote a shape `repair` kept (a shape it reverts is named). If
Michael wants that last step closed, the lines to ask for are: in
`~/.local/state/harness/agent-harness/agent-harness-2026-11-07-3/logs/15-A4-01.jsonl`, every `tool_use` line whose
input names `feature_list.json` (expected: none); and in that run's `run.log`, the lines between `session 15 · A4-01`
and `A4-01 · claude-sonnet-5-5 · passes=false` (expected: `coding exit 0 · <sha> …`, `A4-01: suite ran 1x`, nothing
else; a `helper` or `features.mjs` line there would point at the resident helper instead). Neither changes the fix: the
driver's silence on a claim that never reached the list is the fault whatever the session did.

## 5. Outcome: fix

The verdict `passes=false` is right by the contract: the harness cannot count a claim it cannot read, and the list is
the one place it reads. What is wrong is the shape of the guard's answer, against both rules of the effort
(`docs/plans/2026-11-03-test-suite-redesign-dispatch.md`, *Rules for this effort*):

- *A guard names what it found.* The gap between the entry's `outcome: passes` and the list's `passes: false` is in
  the driver's hands at line 467 and is never said. The `passes=false` line reads as the session's own "not yet"; the
  retro misread it as a verify that closed the lane; the card's why contradicts the entries it points at.
- *A recoverable gap gets one retry told what to repair before any card.* The work was done and committed (`7f22baa`,
  then the retry's fix of the `since=` row); the finding the re-check raised was fixed; what was missing was one JSON
  key. The lane spent $0.17 on the session and then ended a $57 run on it ("no feature left to try"), with A4 never
  merged. A told retry costs one short session and is in the rules.

`docs/specs/2026-11-09-silent-unpass-fix.md` specifies: the gap named at the session's end (the note, the card and the
retry's prompt carry the same words), one told retry per feature per run, and a lane close and a `given_up` card that
name the feature, its attempts and its last verdict, so "given up (nothing left to try)" never again stands alone for a
feature the re-check sent back. It is one `claude` session (it changes `lib/lane.sh`, so it runs alone). It answers the
retro proposal `verify-failed-recheck`'s evidence and shows its title to be a misdiagnosis: the lane re-verifies as soon
as the retry's flip reaches the list (the baseline's `verify M1 2`); nothing about "re-verifying only the failed steps" is
needed. The proposal should be closed against this finding.
