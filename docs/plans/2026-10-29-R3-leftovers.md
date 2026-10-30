# R3 · Leftovers: the lanes review, Michael's build items, and a lint for numbers nobody can reproduce: plan

Spec: `docs/specs/2026-10-28-reliability.md` §R3 items 1–12 and its checks. This file is R3-01. R3-02 builds the atomic
writes and both lint rules, R3-03 the record-only main, the finish order and the green-only test count, R3-04 the
`suite ran` note, the reviewer's model and review-gate Minor 8, R3-05 P2 Minor 12's two checks, and R3-06 reviews and
writes the decision file, the in-place lines and the docs. Every site is named by function and file as the code stands
at `53bdc66` (R2 merged). Nothing here changes code.

**Dependency line.** `git log --oneline origin/main | grep -cE 'harness-merge/agent-harness-[0-9-]+-N[12]$'` prints
**2** (`e9fb31e … -N1`, `645d87e … -N2`): both guards are on origin's main, so the init's "1: N1 only" is stale. A text
conflict between this lane and another (R1 is the one still open; R2 merged before R3 opened, so its `lib/record.sh`
and `prompts/coding.md` edits are in this lane's base) is a resolve session's (N2, `lib/resolve.sh`), and
`tests/fixtures/check-names.txt` merges through the sorted merge driver; only a resolve session that fails goes to
Michael. Each lane merging after another still takes one re-base verify round.

New checks go in two files: `tests/checks/07-step-lint-pure-r3.sh` (exists: pure lint checks) and a new
`tests/checks/77-leftovers.sh` for the stub runs and the sourced-shell checks (it sorts beside the existing
`77-resolve-fallbacks.sh`; the number is the spec's). The gc check goes in `tests/checks/49-lanes-slots.sh`. Every
name gets its line in `tests/fixtures/check-names.txt` (`LC_ALL=C` sorted, copied from the PASS lines).

| # | Item | Function, file at HEAD | Feature | Check file |
|---|---|---|---|---|
| 1 | Atomic list writes (P2 Minor 6) | `main()`'s `park`, `unpark`, `bump`, `unbump`, `grant`, `reset`, `repair`, `pass`/`unpass` cases, `lib/features.mjs` | R3-02 | `tests/checks/77-leftovers.sh` |
| 2 | A `main` moved only in `CHECK_KEY_IGNORE` paths (P2 Minor 8) | `merge_one`, `lib/record.sh` (the `$tree != $c^{tree}` test) | R3-03 | `tests/checks/77-leftovers.sh` |
| 3 | `record_pr` before `ledger` (P2 Minor 9) | `finish`, `lib/driver.sh` | R3-03 | `tests/checks/77-leftovers.sh` |
| 4 | Lint `unit-collision` (P2 Minor 10) | `lint`, `RULES`, header comment, `lib/features.mjs`; the mapping is `LANEU` in `lib/lane.sh` | R3-02 | `tests/checks/07-step-lint-pure-r3.sh` |
| 5 | `gc --dry-run` and concurrent `merge_milestones` (P2 Minor 12) | `cmd_gc` (`slot_gc`, `rm_wt`, the BRANCHES step), `bin/harness`; `merge_milestones`, `lib/record.sh` | R3-05 | `tests/checks/49-lanes-slots.sh`, `tests/checks/77-leftovers.sh` |
| 6 | `<id>: suite ran <n>x (<s> s) in the session` (P2 Minor 7) | `lib/check.sh` (every exit path); the coding branch of `lib/lane.sh` around `session coding` | R3-04 | `tests/checks/77-leftovers.sh` |
| 7 | The reviewer on the session's model | `prompts/coding.md` §2; `prompt coding` call in `lib/lane.sh` | R3-04 | `tests/checks/77-leftovers.sh` |
| 8 | Test count pinned from a green suite only | `run_init`, `lib/record.sh` | R3-03 | `tests/checks/77-leftovers.sh` |
| 9 | Review-gate Minor 8 | the coding branch's tail, `lib/lane.sh` | R3-04 | `tests/checks/42-run-20-review-gate-rounds-m6.sh` |
| 10 | Lint `unreproducible` | `lint`, `RULES`, `lib/features.mjs`; `prompts/initializer.md` | R3-02 | `tests/checks/07-step-lint-pure-r3.sh` |
| 11 | §4/§12 prose | `docs/architecture.md` §4 *Where state lives*, §12 *Queue and parallelism*; `README.md` configuration and lint | R3-06 | (docs; the suite) |
| 12 | Decisions | `journal/decisions/2026-10-29-lanes-leftovers.md`; in-place lines in `2026-10-27-review-gate.md`, `2026-10-26-test-count-contract.md` | R3-06 | (docs) |

## 1. Atomic list writes (R3-02)

**Where.** `lib/features.mjs` has eight `writeFileSync(a, json(…))` call lines in `main()` (`park`, `unpark`, `bump`, `unbump`,
`grant`, `reset`, `repair`/`repair-verify`, `pass`/`unpass`) and `writeFileSync` on the import line (line 42).

**What.** One helper beside `json`:

```js
import * as fs from "node:fs";   // the one write (writeAtomic): the named import below doesn't name it
const writeAtomic = (p, text) => { const t = `${p}.${process.pid}.tmp`; fs.writeFileSync(t, text); fs.renameSync(t, p); };
```

and every call becomes `writeAtomic(a, json(…))`. The step's `grep -c 'writeFileSync' lib/features.mjs` counts
**lines**, so the named import must drop `writeFileSync` (hence the namespace import) or the count is 2. The pid in the
name keeps two lanes' writers from sharing one temp file (`lib/entries.mjs`'s `writeAtomic` uses `<file>.tmp`; it runs
under the record lock, so it stays as it is: the spec's "and the progress render" is already built).

**Check (77).** A writer loop (`node lib/features.mjs bump "$f" A`, 200 times) in the background beside a reader loop
(`node -e 'JSON.parse(fs.readFileSync(f))'` until the writer is done, a flag file on the first throw). PASS: no flag,
the file's `A` is 200. Watched failing first: with the old in-place write, the reader throws within the 200 on this box
in the red phase (if it doesn't reproduce, the entry says so; the check still guards the helper).

## 2. A `main` moved only in ignored paths merges without a re-base (R3-03)

**Where.** `merge_one`, `lib/record.sh`, the test

```bash
if [[ ${2:-} != --open && $tree != "$(git rev-parse "$c^{tree}")" ]]; then   # main has content the lane wasn't verified with
```

**What.** Inside that branch, before the `moved-<m>` lines: build the pathspec `(. ':!.harness/runs' ':!<p>' …)` from
`read -ra` of `${CHECK_KEY_IGNORE:-.harness/runs}` (config is loaded in both callers: the lane and the driver,
`harness merge` included; the default covers a sourced test shell), and when `git diff --quiet "$c" "$tree" -- "${spec[@]}"`
holds, note and fall through to the push and PR:

```
<m>: main changed only in ignored paths (<the paths>); merged as verified
```

The note contains neither `re-base` nor `moved since` (the step's check greps both as absent). The invariant restated
(R3-06's decision file): what lands is byte for byte what was verified outside the paths the suite's cache key ignores.
`.harness/runs` is in the pathspec whether or not the config lists it, as `check.sh`'s key treats it.

**Check (77).** A stub run with `STUB_MAIN_TOUCH=A:.harness/runs/other/x.md` (`main_touch` in `tests/stub-claude.sh`
lands that commit on origin's main during A's first session): `harness-log.md` has `M1 merged into main` and
`ignored paths`, and no line matching `M1.*(re-base|moved since)`. Red at HEAD: today the same run notes the re-base.

## 3. `finish`: `record_pr` before `ledger` (R3-03)

**Where.** `finish`, `lib/driver.sh`: today `… rec_commit "HARNESS: summary and retro"; sync_record` → `ledger` →
`scratch_done "$key"` → the continuation block → its commit → `record_pr` → its commit → `log "run kept in …"`.

**What.** `ledger` and `scratch_done` move to after `record_pr`'s commit, in that order (`ledger` reads
`$SCRATCH/retro-proposals.json`, which `scratch_done` removes), followed by one more
`[[ -n $(git status --porcelain -- "$RUN_DIR") ]] && { rec_commit "HARNESS: ledger notes"; sync_record; }` for its
`backlog:` note. Then the ledger's copy (`cp -r "$REC/."`) holds the `record PR` note. Cost, accepted: the `backlog:`
note lands on the record branch after the record PR merged, so main's copy of `harness-log.md` lacks it (the ledger's
and the record branch's have it); gc's `record_only` (`bin/harness`) diffs outside `.harness/runs` only, so the extra
record commit doesn't keep the branch.

**Check (77).** A stub run with `RECORD_PR=end` appended to `$T/user-config.sh` (as `tests/checks/50-lanes-record-pr.sh`
does): `$T/ledger/proj/<run>/harness-log.md` has `record PR`. Red at HEAD.

## 4. Lint `unit-collision` (R3-02)

**Where.** `lint` and `RULES` in `lib/features.mjs`; its header comment's rule list (top of file and the block above
`RULES`). The mapping it mirrors: `LANEU=${M//[^A-Za-z0-9_]/_}` (`lib/lane.sh` line 33), which names every lane unit
(`scope_unit "$RUN_ID" "$LANEU"` → `harness-<run>-<LANEU>-s<n>`, `…-svc`).

**What.** A pure `unitCollisions(list)`: group the milestone ids by `m.replace(/[^A-Za-z0-9_]/g, "_")`; for each group of
two or more, one finding per id, on that milestone's first feature, step `-`, text
`<id> shares lane unit name <name> with <the others> (lib/lane.sh LANEU): rename one`. `unit-collision` joins `RULES`
(so `lintNote` counts it). Features without a milestone are lane `default` and aren't milestone ids: left out.

**Checks (07).** `M1-x`, `M1.x`, `M1_x` → three findings, each naming the other two; `M1`, `M2` → none.

## 5. P2 Minor 12's checks (R3-05)

### `gc --dry-run` lists a leftover slot and a lane branch (49)

**The slot's path.** R3-05 step 1 names `$T/wt/proj/<run>-slots/slot-1`; slots live at
`<WT_ROOT>/<project>/lanes/<run>/slot-<k>` (`slot_gc` in `cmd_gc`, `bin/harness`; `tests/checks/49-lanes-slots.sh`
uses `$T/wt/proj/lanes/gk/slot-0`). The check uses the real layout, `$T/wt/proj/lanes/<run>/slot-1`; the step's path is
a proposed change in this entry. A slot under the step's path would be an ordinary worktree to gc (`harness/*` branch
test), not a slot.

**Which branch gc names.** Only a lane branch merged into `origin/main` (the BRANCHES step's `harness-lane/` pass:
`branch -D` here, `push -q origin --delete` on origin); an unmerged one is kept silently. So the check sits in the `sp`
block (MERGE_POLICY=pr; M1's PR merged from a clone, `harness-lane/sp/M1` still here and on origin), just before its
`"$H" gc "$T/proj"`: add a clean detached worktree `git -C "$T/proj" worktree add -q --detach "$T/wt/proj/lanes/sp/slot-1" main`,
run `"$H" gc "$T/proj" --dry-run` (off a TTY: plain `would:` lines), and assert one line
`would: git -C … worktree remove --force $T/wt/proj/lanes/sp/slot-1`, one `would: git -C … push -q origin --delete
harness-lane/sp/M1`, the directory still there and `git -C "$T/origin.git" ls-remote … harness-lane/sp/M1` still
listing it. The real gc after it then removes both (the existing check, plus `! -e …/slot-1`). Grep the two lines by
their text (`grep -F`), not by counting lines naming the branch: the local `branch -D` line names it too.

### Two `merge_milestones M1` at once merge it once (77)

The `uenv` pattern of `tests/checks/44-lanes-record.sh`: a bare origin and a clone, a commit tagged
`run/u/M1` with a subject containing `(v3` ahead of main, a one-feature list (M1, passing), `STATE` with no
`lanes/M1/pid`, `GH=$HERE/../tests/stub-gh.sh` (its `pr merge` really merges into the bare origin, `$T/gh.log`),
`MERGE_POLICY=auto`, and stand-ins for `note` (appending `<date> · <text>` to `$REC/harness-log.md`), `log`, `notify`,
`lane_alive` (false), `lane_branch_gone`, `needs_open`, `rec_commit`, `sync_record`. Two subshells `( uenv;
merge_milestones M1 ) &` started together, `wait`. PASS: `grep -c 'M1 merged into main' harness-log.md` = 1 and one
`pr merge` line for M1 in `$T/gh.log`. Expected green at once: `merge_milestones` takes `flock 8` on
`$STATE/merge.lock` and the second finds `merged-M1`. If it is red, the cause is fixed in `lib/record.sh`, quoted
before and after in the entry (R3-05 step 3).

## 6. `<id>: suite ran <n>x (<s> s) in the session` (R3-04)

**`lib/check.sh`.** A function `row <full|subset|cached>` appending
`printf '%s\t%s\t%s\n' "$(date +%s)" "$1" "$(( $(date +%s) - start ))" >> "$scratch/check-runs.log"`, called on each
exit path that ran or answered: the subset exit (`subset`), the cached-green exit (`cached`), the full run's end
(`full`, its seconds including a rerun). `start` is already set above all three (line 52), so `cached` gets
about 0 s. "No suite configured" writes no row. The epoch is the call's end, so a row between two stamps belongs
to a call that ended inside the session.

**`lib/lane.sh`.** Around `session coding "$mdl" "$slog" "$id"` (outside `session()`, which R2 edited): `t0=$(date +%s)`
before, `t1=$(date +%s)` after, then

```bash
read -r sn ss < <(awk -F'\t' -v a="$t0" -v b="$t1" '$1 >= a && $1 <= b && $2 != "cached" { n++; s += $3 } END { print n + 0, s + 0 }' "$SCRATCH/check-runs.log" 2> /dev/null || echo "0 0")
note "$id: suite ran ${sn}x ($ss s) in the session"
```

right after the session's `commit_all`/`sync_lane` line, so every coding session (a refused one and an escalated
round too) gets one. `$SCRATCH` is the lane's (`$SCRATCH/lanes/$M`), the same `HARNESS_SCRATCH` the session's own
`$HARNESS_CHECK` calls write to; the lane's own `run_init` and `green` calls write rows too, but outside the stamps.

**Stub (`tests/stub-claude.sh`).** `STUB_RUN_SUITE=<id>`: that feature's first coding session runs `"$HARNESS_CHECK"`
once (full) and `"$HARNESS_CHECK" x` once (a subset; the stub project's `CHECK_CMD` ignores arguments), before its
commit. Documented in the stub's header like the other `STUB_*` lines.

**Check (77).** `STUB_RUN_SUITE=A`: `harness-log.md` has `A: suite ran 2x (` and `B: suite ran 0x (0 s)`. Note: the
live harness judges a real run with the live checkout's `check.sh` (`CHECK=$HARNESS_HOME/lib/check.sh`), so a real
night writes `check-runs.log` only after R3 is on main and the queue runner has synced.

## 7. The reviewer on the session's model (R3-04)

**Where.** `prompts/coding.md` §2: "Reviews go to **Opus** subagents that read a diff from a file in your scratch
directory and return findings only." becomes "Reviews go to subagents on your own model (`{{MODEL}}`) that …".
`lib/render.mjs` fills `{{X}}` from `HARNESS_X`, so `lib/lane.sh` sets `HARNESS_MODEL=$mdl` on the `prompt coding` line
(beside `HARNESS_FEATURE=$id …`), `$mdl` being the session's model id after the review gate's sizing. A review at or
over `REVIEW_OPUS_LINES` is an Opus session already, so its reviewers are Opus. The verify and initializer prompts are
unchanged.

**Check (77).** In any stub run's state dir, the copy `logs/01-A.prompt.md` (A's first session; `plog` in 42 shows the
lookup) contains `subagents on your own model (\`claude-sonnet-5-5\`)`, and A's metrics row's model is the same id.

## 8. The test count pinned only from a green suite (R3-03)

**Where.** `run_init`, `lib/record.sh`: `"$CHECK" >> "$SCRATCH/init.out" 2>&1 || log "  suite red before the session …"`,
then the `tests-start` block and the `testcount-source` block, both today regardless of the suite's exit.

**What.** Keep the exit (`local crc=0; "$CHECK" … || { crc=$?; log …; }`) and guard both blocks with `(( crc == 0 ))`.
A rerun-green is exit 0 and its count is already the first run's total (the `check-rerun.out` branch and
`testcount.mjs --total` in `check.sh`): N1's file split holds, nothing to change there. A red first suite then pins
nothing; the next `run_init` (each coding session's, the verify's) with a green suite pins both. A cached green with
no `check.out` waits as today.

**Stub run (77).** `BROKEN` committed on the project's main before the run, `CHECK_CMD='test ! -f BROKEN && echo "1/1
checks passed"'` in the run's `run.env` (sourced last by `harness_config`, `lib/config.sh`), and the new
`STUB_FIX_BROKEN=A` (A's first coding session removes `BROKEN` and commits). PASS: `$STATE/tests-start` is `1`,
`harness-log.md` has exactly one `test count:` line and it is `test count: parsed (…)`, not the `no match` one. Red at
HEAD: the init's red suite notes `no match` and pins `none`.

## 9. Review-gate Minor 8 (R3-04): cheap, built

The lines at `53bdc66`, `lib/lane.sh`, from the record flip to the gate's un-pass:

```bash
  if [[ $passed == true ]]; then record F pass "$LIST" "$id"; else record F unpass "$LIST" "$id"; fi
  record MET append "$slog" "$REC/metrics.jsonl" "$RUN_ID" coding "$id" "$mdl" "$passed" "$S_WALL" "$S_EXIT" false "$kind" "$S_PEAK" "$LANE"
  note "$id · $mdl · passes=$passed · $(( S_WALL / 60 )) min · $(F summary "$LIST")$( [[ -f $STATE/tests-end ]] && echo " · tests $(cat "$STATE/tests-end")")"
  if [[ $passed == false ]] && why=$(MET final "$slog" | sed -n 's/^[[:space:]*`>-]*PARKED:[[:space:]]*//p' | head -1) && [[ -n $why ]]; then
    [[ $esc ]] || record F unbump "$ATT" "$id"; record F park "$PARKED" "$id" "$(answers_hash)" "$why"   # waiting on Michael is not the feature's fault (an escalation round took none)
    note "$id parked (waiting on Michael): $why"
  else why=""; fi
  nref=""
  if [[ $esc ]]; then rm -f "$LS/review-escalate"   # the round ran; its verdict stands
  elif [[ -z $why && $mdl == "$(F model sonnet)" && $kind == review && ! -e $STATE/review-escalated-$id ]]; then
    # a sonnet review that found something gets one round on REVIEW_ESCALATE_MODEL, once per feature; un-passed first,
    # so its verify waits for that round's verdict (decisions/2026-10-27-review-gate). Its entry is in the record now.
    if rf=$(node "$HARNESS_HOME/lib/entries.mjs" findings "$REC" "$id" "$SCRATCH/entry-final"); then
      IFS=$'\t' read -r rc ri <<< "$rf"
      if (( rc + ri > 0 )); then
        note "review $id: sonnet found $rc Critical, $ri Important; one round on $REVIEW_ESCALATE_MODEL"
        record F unpass "$LIST" "$id"; touch "$STATE/review-escalated-$id"
```

**Finding at HEAD.** Since P1 moved the session tail into `lib/lane.sh`, one `rec_commit "HARNESS: after $id
(passes=$passed)"` follows all of it, so no run can end between the `passes=` note and the un-pass any more: the
committed list already says `passes: false` for an escalated review. What is left of Minor 8 is order and truth: the
`passes=true` note and a metrics row `passes: true` for a session the gate un-passes on the next lines.

**The move (a move of lines plus one assignment).** In order:

1. `why`: the `PARKED:` test as today but without its `record F unbump`/`record F park`/`note` (they move to 4).
2. The gate block (`if [[ $esc ]] … fi`) moved up here; where it escalates, `passed=false` replaces
   `record F unpass "$LIST" "$id"` (the flip in 3 records it).
3. The record flip, the `MET append` row and the `passes=` note, unchanged lines (now `passes=false` for an escalated
   review).
4. The park's records and note.

`nref=""` and the needs records stay after. Effects: an escalated review's first row is `passes: false`, so
`metrics.mjs`'s first-attempt rate counts it as not passing first time (truthful); `features passed` still counts it
once its round passes; `summary.mjs`'s `rounds()` and rework are unchanged. `summary.json`'s cause has no
pending-round case either way (it would say `not done`); a `review round pending` cause is out of R3's scope and goes
in the entry's `proposed_changes`.

**Check (42).** In the `rlimit` or `rcap` run (`STUB_REVIEW_FINDINGS=1,0`): the line number of `review R: sonnet found`
is below that of the first `R · ` line with `passes=` in `harness-log.md`, and that `passes=` line says `passes=false`.
Red at HEAD (the note comes first, `passes=true`). Builders grep `tests/checks/` for `R · .*passes=true` before the move:
any check pinning the old order changes with it.

## 10. Lint `unreproducible` (R3-02)

**Where.** `lint` and `RULES` in `lib/features.mjs`, a per-step rule beside `no-anchor`; the header comments;
`prompts/initializer.md`'s step bullet (`**Steps are verifiable** …`) and its lint paragraph.

**The patterns** (tried on the examples below with `node`, all as listed):

```js
const UNIT = String.raw`(?:ms|s|secs?|seconds?|m|mins?|minutes?|h|hrs?|hours?)`;
// a time bound: a comparison word, then a number and a time unit
const TIME = new RegExp(String.raw`(?:<=?|≤|\b(?:under|within|below|less than|no more than|at most|in at most)\s)\s*~?\d+(?:\.\d+)?\s*${UNIT}(?![\w-])`, "i");
// a count of tests or checks one run printed: two digits or more, or an N/M pair
const COUNT = /(?<![\w./-])(?:\d{2,}(?:\/\d+)?|\d+\/\d+)\s+(?:tests?|checks?)\b/i;
// one run's output file
const RUNOUT = /\bthis run['’]s\b[^.;]{0,40}?\bcheck[\w-]*\.out\b/i;
```

| Match (one finding) | Must not match |
|---|---|
| `< 150 s` | `the suite is green` |
| `<150 s` | `TEST_FILE_TIMEOUT=10m` |
| `under 2 minutes` | `--repeat 10` |
| `in at most 30 s` | `at most 400 characters` |
| `395 tests` | `a budget of 30 minutes` |
| `this run's check.out` | `` `tests/run.sh` prints `N/M checks passed` `` |
| `this run's scratch check.out (395 tests)` (one finding, not two) | `3 checks in tests/checks/07-step-lint-pure-r3.sh` |
| `963/963 checks passed` | `ENTRY_RESUME_TIMEOUT (10m)`, `the 25-minute CHECK_TIMEOUT`, `a 10m timeout` |
| `the suite finishes in under 4 min` | `within 2 lines of the note`, `R3-04 adds 2 checks` |

**Known reports, by design** (reported, never applied, `decisions/2026-10-26-step-lint`): a file's own count of two
digits or more (`12 checks` in a file) is flagged too, because the fix is the same (cite `tests/run.sh <file>`'s
`N/M`); a bound with room is flagged as well (`below 5 s` in R1-02 step 4), since the rule can't measure room. On this
run's list the rule reports three steps: R1-02 step 4 (`below 5 s`), R3-01 step 3 and R3-02 step 3 (they quote the
examples). One finding per step whatever the number of hits.

**The finding.** `{ id, step, rule: "unreproducible", text }` with text
`a number another box or run won't reproduce: cite the command that prints it, or a bound with room (“<the match>”)`.

**The prompt.** `prompts/initializer.md`, the `**Steps are verifiable**` bullet gains: "State a count as the command
that prints it (`tests/run.sh` prints `N/M checks passed`), never a number one run printed, and a time bound as a
budget with room (a timeout), never a measured wall time." The lint paragraph's list gains "a number another box or run
won't reproduce". R3-02 step 4's check: `grep -F 'N/M checks passed' prompts/initializer.md`.

**Checks (07).** The five spec examples flagged; `the suite is green`, `TEST_FILE_TIMEOUT=10m`, `--repeat 10`, `at most
400 characters` not; the finding's text begins with the message.

## 11. Docs (R3-06)

`docs/architecture.md` §4 (*Where state lives*): the lanes prose P2-06 never wrote: the `lane <m> · …` line `harness
status <run>` prints per open lane (`laneLine`, `lib/status.mjs`: milestone, now, port, slot, units) and `summary.json`'s
`lanes: {max_open, lane_hours, wall_hours}` (`lib/summary.mjs`); `$HARNESS_SCRATCH/check-runs.log` beside the other
scratch files. §12 (*Queue and parallelism*): `unit-collision`'s reason, the record-only main (merge without a re-base),
the merge lock's once-only merge. `README.md`'s configuration section: `CHECK_KEY_IGNORE`'s role in a merge, and
`check-runs.log`; its lint list names `unit-collision` and `unreproducible`.

## 12. Decisions (R3-06)

`journal/decisions/2026-10-29-lanes-leftovers.md` (items 1–6 and 10, finding · choice · rejected; the record-only main
restates the invariant). In-place lines: `journal/decisions/2026-10-27-review-gate.md` (`Updated in place 2026-10-29:
built …` the reviewer on the session's model, judged by the ledger's `review_cost_pct` and verify-fail rate, and Minor
8's move), `journal/decisions/2026-10-26-test-count-contract.md` (the green-only pin).

## Live steps

None: build-only, all against stubs and throwaway repos. What a real night shows after R3 merges and the runner syncs:
`grep -E 'suite ran|ignored paths|unit-collision|unreproducible' <run dir>/harness-log.md`.
