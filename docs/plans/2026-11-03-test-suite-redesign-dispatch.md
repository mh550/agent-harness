# Test suite redesign: the dispatch list (2026-11-03)

*(Deliverable 2 of `docs/specs/2026-11-03-test-suite-redesign.md`. One block per piece of work, in order; each is a bash
command Michael pastes as is from `~/projects/agent-harness`. A spec to build is a harness run; exploration, measurement
and review are `claude` sessions whose prompt is complete in the block. The supervisor
(`docs/plans/2026-11-03-test-suite-redesign-supervisor.md`, started by D0) keeps the **Status** column below current
and tells Michael which block is next. Plan: `docs/plans/2026-11-03-test-suite-redesign.md`.)*

## Status

| # | piece | kind | needs | status | result |
|---|---|---|---|---|---|
| D0 | the supervisor | `claude` session | – | running | session 1, 2026-11-03: C1 merged (PR #78), box quiet; D1 given to Michael. Session 2, 2026-11-03 19:10: D1 merged (PR #82) and held; box quiet (RUNNING 0, QUEUED 0, runner off, load 1.03); D2 given to Michael with `harness queue start --until 07:30` (the runner was off). Session 3, 2026-11-04 00:27: D2 merged (PR #84, record PR #85) and its deciding measures held; box quiet (RUNNING 0, QUEUED 0, runner off, load 1.16); D3 given to Michael with `harness queue start --until 07:30` Session 4, 2026-11-04: D3 ended with T2 verified but unmerged (GitHub outage 06:07–06:18, a silent merge fallback, gc); Michael landed T2 (PR #89); D3 checked and merged; Michael chose a fix run (F1) before D4 and dropped `--until` as the default advice. Session 6, 2026-11-04 16:24: F1's run ended at 15:27 at 1/12 (the tmux server under the queue runner and the driver exited; cause not found); Michael chose the split: F1 and D6 by hand, D4 a harness run; M1-01 saved as `origin/f1/M1-01`; procedure `docs/plans/2026-11-04-f1-by-hand.md`, block F1b given to Michael. Session 7, 2026-11-05 09:19: F1's three hand milestones merged (PRs #97, #98, #99) and checked against block F1b; the live checkout level with origin (`bb3a418`); box quiet (RUNNING 0, QUEUED 0, runner off, load 0.84); D4 given to Michael with `harness queue start` (the runner was off). Session 8, 2026-11-05 14:10: the resident helper run (D4, `agent-harness-2026-11-05`) ended done and merged (PR #104, record PR #105); five of its eight predictions held, two deciding ones missed narrowly (the large check file's node starts 337 against 300 or fewer, the solo wall 608.1 s against 600 s or less) and one that does not decide held idle and missed under load, so the diagnosis block is filled in (`## D4x`) and whether it runs is Decision 1; box quiet (RUNNING 0, QUEUED 0, runner off, load 1.57); the lane-time measurement (D5) given to Michael; this list gained its Names, Decisions and Log sections |
| D1 | re-baseline on `main` | `claude` measurement | C1 merged, box quiet | measured: `findings-and-research/2026-11-03-redesign-baseline.md` §5 | PR #82, tree `6622952`, RUNNING 0 before each run. Solo wall 776.6 / 794.6 s (−3.4 % / −1.1 % of C1-04's 803.8 s: within 5 %, held), CPU 3,113.1 / 3,118.1 s, 1,141 checks, no red; file 13 node 2,651 (§2: 3,139); the eleven pure files 149 node starts, 9.35 CPU-s, 3.16 s wall (§5.3: the runner and `tests/lib.sh` included; the evals alone are 60 of the 149). Phase 1's before row is §5.3, not the spec's 108 / 4–6 s |
| D2 | phase 1: unit tier | harness run (`2026-11-03-unit-tier.md`) | D1 | merged: PR #84 | run `agent-harness-2026-11-03-2` (6/6, first-attempt 1.00, $26.68, 3.6 h wall, 1 full suite per session; record PR #85); table in `findings-and-research/2026-11-03-unit-tier.md`, decision `journal/decisions/2026-11-03-unit-tier.md`. **Held**: the tier 1 node start and 0.24 s wall (supervisor on `0bbd5c1`: `00-unit-tier.sh` 0.26 s three times, 124/124); solo full suite 805.4 → 798.3 s (−0.9 %) and 3,147.5 → 3,172.7 CPU-s (+0.8 %, 22 more checks); names 1,140 → 1,164, 0 removed (`git diff ff8558f 0bbd5c1`); 2 `node --input-type=module` lines left (82-key-map-lint, 84-node-memo, each with its reason under *Kept evals*). **Prediction wrong, not a miss** (the spec's before row counted the evals alone; D1 corrected it to §5.3 before the run): the eleven files' CPU 9.34 → 8.84 s (spec: 4–6 → < 1 s) and their node starts 176 → 117 (the −59 are the evals; the 104 left are CLI-behaviour checks the spec keeps in bash); corrected prediction: the layer's bash files keep ~8–9 CPU-s (the runner, `tests/lib.sh`, the CLI checks) until phase 4's push-down. Defaults against the spec's wording: the tier is `tests/unit/*.test.mjs` (a directory argument is red on node 24, which this box runs), and `CLAUDE.md`'s check sits in `79-suite-length.sh`, not `33-suite-runner.sh`. No Dx dispatched; D2x below holds the filled block if Michael wants the write-up |
| D2x | phase 1 diagnosis (the Dx block, filled) | `claude` | Michael's call | held | not dispatched: the cause and the corrected prediction are already written with numbers (`2026-11-03-unit-tier.md` verdict column, baseline §5.3–§5.4); paste `## D2x` only for a session to write the diagnosis file |
| D3 | phase 3: tiers | harness run (`2026-11-03-suite-tiers.md`) | D2 merged | merged: PR #87 (T1), PR #89 (T2) | run `agent-harness-2026-11-04` (8/8, first-attempt 1.00, $28.43, 5.5 h wall). T1 merged by the run (PR #87); T2 verified 06:17 but not merged: GitHub rejected pushes and fetches 06:07–06:18 (run.log: record pushes, the T2 tag `remote rejected (failure)`, three `fetch of main failed`), `lane_done` fell through to `needs Michael: its merge` with no card, and gc removed the run at 06:19; Michael landed T2 by hand (PR #89, `--match-head-commit 625a9e6`; main had moved only in CHECK_KEY_IGNORE paths). Table in `findings-and-research/2026-11-03-suite-tiers.md`. **Held**: fast tier solo wall 152.8 / 151.5 s (≤ 180 s); full suite 809.9 / 794.1 s (unchanged from 804 s). **Off the range, not a deciding measure**: fast checks 537 against 560–620 (−23; the wall is on the prediction). Checks on `45826e4`: every one of the 90 check files has a `# tier:` line 2 (55 fast, 35 slow); `check-names-fast.txt` 560 names; `prompts/coding.md:23` has `run the fast tier once, last`; the invariant paragraph is in `decisions/2026-11-03-fast-gate` (line 35) and `86-fast-gate.sh` names the planted cases (`a bare call on a fast-green tree runs the suite bare`, `87-fast-gate-run.sh`: `run_init fresh removes a planted fast-<key>`). Gaps: the assignment table in `decisions/2026-11-03-suite-tiers` lists 88 of 90 files (T2's `86-fast-gate`, `87-fast-gate-run` missing); `39-memlint-m4` (41 s) and `84-node-memo` (31.5 s) over the 30 s line in the fast tier. Defaults against the spec (Michael 2026-11-04): two fast-gate files, kept; lengths under *This session*, kept; finish's final `green` stays full, kept; memlint's tier under review; a slow-tier red at verify should open a fix feature (≤ 2 rounds) instead of stopping: a spec, see F1. Fast tier on main not re-run by the supervisor (the run's full verify stands) |
| F1 | run resilience: merge retries, no default end time, verify-red fix loop | `claude` spec session; a harness run to M1-01, then by hand: one session per milestone (Michael 2026-11-04) | D3 merged | merged: PR #97 (M1), PR #98 (M2), PR #99 (M3) | **By hand, merged 2026-11-05** (block F1b; the run's M1-01 came in by merge): M1 PR #97 (`182a94b`; full suite `1274/1274`, 897 s), M2 PR #98 (`fb9eab7`; `1291/1291`, 926.8 s), M3 PR #99 (`bb3a418`; `1332/1332`, 940.9 s; fast tier `581/581`, 150.9 s). Checks on `bb3a418` (supervisor, session 7): the three decision files on main (`2026-11-04-origin-retries`, `-no-default-end-time`, `-fix-rounds`), `docs/architecture.md` and `README.md` in each PR; names 1,223 → 1,273 → 1,290 → 1,331, 113 added and 5 removed, each removal a rename whose successor is on main (M1: the two `16` → `17 reasons` / `17 fixtures` names the spec asks for, and `u3 review: … so the runner's gc removes it` → `… and the runner's gc holds it only for its verified milestone`; M2: the two `night scope` → `run scope` names of the spec's item 6); every reviewer finding listed with what was done (M1 0 Critical / 4 Important / 13 Minor, M2 0 / 0 / 4, M3 0 / 1 / 5); M2: the files the spec names hold `--until` only as an option and `tonight` only in memlint's own rule; M3: `fix rounds fx4: MAX_FIX_ROUNDS=0 opens the verify_red card at the first red, its note and why as before` and `fx3` (a flake opens no round) are in the fixture; `lib/config.sh` has `HOURS=""`, `ORIGIN_WAITS="5 15 30 60 120"`, `MAX_FIX_ROUNDS=2`. The live checkout is at `bb3a418` = origin/main. **Defaults against the spec, Michael's to call**: `ORIGIN_TRY_TIMEOUT=120` s per try (new) makes one merge step's worst case 950 s against the 230 s bound in the spec's falsifier; M1's review finding 4 left (a run ending with a re-base pending has a note and no card); gc's hold is `harness/<run>` only, not every branch of the run; under `MERGE_POLICY=pr` a proposed milestone's worktree stays until its PR merges; `89-no-deadline` is slow (50–67 s) against the predicted fast, its lint in a new fast `89-night-words`; `88` split into `88-origin-outage` and `88-origin-after-gc`; M3: fix features a verifier un-passed on a red suite pass again and the round-or-card rule runs (Michael's choice in the session), while a verifier that un-passes the milestone's own features still ends in a failed re-check, not a red. F1's Predictions are read off D4–D6, per run: `grep -c "fix round"` beside `grep -c "failed the re-check"` in `harness-log.md`, `jq .fix_rounds` of `summary.json`, `grep -c "succeeded on try"`. Left of the procedure's step 4 (Michael): `harness gc ~/projects/agent-harness --all-merged` (the dead run's worktree, its lane slot and `origin/f1/M1-01` are still there). Before that: **Run ended 2026-11-04 15:27 at 1/12** ($9.67, 1.0 h wall, `driver exited unexpectedly`): M1-01 passed (`a956311`, 11 files, tests 1224 → 1233; saved as `origin/f1/M1-01`), then the tmux server holding the queue runner and the run's session exited 7 min into M1-02's session (journal: the two `tmux-spawn` scopes and the lane's scope stop at 15:27:25–26; `tmux ls`: no server; no cause in the journal; not the suite: `tests/lib.sh:10` unsets `TMUX`). M1-01's session ran the full suite bare beside the fast tier: suite 1,023 s of 1,738 s (59 %). **By hand from M1-02** (Michael 2026-11-04): block `## F1b`, procedure `docs/plans/2026-11-04-f1-by-hand.md`, the run's feature list and entries copied to `docs/plans/2026-11-04-f1-by-hand/`; M1, M2, M3 not started. Open for Michael: what ended the tmux server; a driver that outlives its tmux server is not in F1's spec. spec merged 2026-11-04 (PR #92, `docs/specs/2026-11-04-run-resilience.md`: ORIGIN_WAITS 5 15 30 60 120 s, a `merge_failed` card, HOURS empty by default, `kind: fix` features, MAX_FIX_ROUNDS 2); queued by Michael with no `--until`. Michael 2026-11-04, before D4: (M1) a merge that fails on a transient origin error is retried, then a needs card, never silent; gc keeps a verified, unmerged run; `harness merge` after gc; (M2) no 8 h default deadline (`lib/config.sh:12` `HOURS=8`), the overnight framing and `--until` advice out of README, architecture, CLAUDE.md, prompts, templates; (M3) a full-suite red at verify opens a fix feature, at most 2 rounds per milestone, then today's card. Block `## F1` below writes the spec; its session names the `harness queue add` |
| F2 | fix triage: a read-only session groups a red verify's failures into issues, one fix feature each | spec, later | F1 merged and its M3 counters over D4–D6 | not started | Michael's idea, 2026-11-04; deferred until data says one fix per red is not enough: of the fix rounds after F1, ≥ 30 % that leave the red standing, or reds whose failing names span unrelated subsystems. Limits proposed: one triage per red (opus, no code edits, JSON out, the driver checks every failing name is in exactly one issue, else one issue), at most 3 issues, one fix session per issue (2 attempts), 2 rounds per milestone and at most 6 fix sessions per milestone in all; before an issue's session the driver reruns its failing names and closes it without one if an earlier fix already cleared them; all inside MAX_SESSIONS and the weekly budget |
| F3 | the memory curator: coding sessions record findings, one opus session at the run's end curates `CLAUDE.md` and the project's memory, the driver enforces tiers | spec, then a harness run | F1 merged | proposed (Michael to confirm) | revised 2026-11-04 from a Gotchas-only guard at Michael's ask (`journal/sessions/2026-11-04-loop-engineering-design.md` §4): sessions stop editing `CLAUDE.md` and write `discoveries` / `proposed_changes` in their entries (the context pack carries facts within a run); a curator session (not the retro, which reviews the harness and stays read-only) consolidates them; tiers checked by the driver: facts (Gotchas, project facts) applied, conventions and workflow lines in a `memory: <run>` PR with each change's provenance, Michael's to merge until accepted PRs earn auto-merge, protected sections (live system, permissions, never-rules) proposals only; size caps (120 lines, 15 Gotchas) on the curator's result. Today only this repo's `39-memlint-m4` self-lint enforces the cap, and coding sessions may edit any line (`restrict` covers verify and retro only). If confirmed it goes before D4, and D6 drops the self-lint with the curator's tier check as its successor |
| D4 | phase 2: resident helper | harness run (`2026-11-03-resident-helper.md`) | D3 merged; F1 merged (by hand, block F1b) and the live checkout level with it (`harness sync`) | merged: PR #104; missed: the large check file's node starts (337 against ≤ 300) and the solo wall (608.1 s against ≤ 600 s) | **The resident helper run (`agent-harness-2026-11-05`) ended done and merged 2026-11-05 13:46**: 6 of 6 features passing, each at its first attempt, $30.91, 3.85 h wall, no fix round, no verify red; its one milestone (H1) is PR #104, the run's record PR #105. Its proof feature (H1-04) measured *before* on the run's base `07a31f6` (1,332 checks) and *after* on `de51e2f` (1,450 checks), one solo suite each with the gate clear; the table is in `findings-and-research/2026-11-03-resident-helper.md`, the choices in `journal/decisions/2026-11-03-resident-helper.md`. Against the spec's Predictions table, row by row. **Held (5):** node starts per stub `harness start` 336 → 20 (≤ 30); the large check file's CPU 161.3 → 88.0 s (≤ 110 s); the solo suite's CPU 3,804.3 → 2,107.9 s (≤ 2,300 s; −44.6 % where −25 % was predicted); `harness-log.md` lines changed 0 of 46 (0); helper restarts per stub run 0 (0). **Missed (2, both deciding rows):** node starts in the large check file (file 13, `13-run-2-michael-sets-desk`) 2,665 → 337 against ≤ 300, over by 37 (12 %); the solo suite's wall at 4 jobs 974.2 → 608.1 s against ≤ 600 s, over by 8.1 s (1.4 %). **Held idle, missed under load (1, not a deciding row):** a spawned `treekey.mjs` call 49.3 ms on an idle box and 64.4 ms inside a suite against ≤ 60 ms (under a driver or a lane that call now goes through the helper, 9.7 ms). **What the data says about the two** (supervisor, recounted from the raw exec tables in `findings-and-research/2026-11-03-resident-helper/`): the 337 are 162 from `harness` CLI commands, 48 from the stub and 9 from the checks' own lines, all three unchanged by design, plus 118 from the driver and its lanes (2,446 before: −95 %), which are 32 helper starts where the spec guessed about 20 and 86 calls the decision file's call-site table leaves as spawns (a call on a pipeline's side, `memlint` under its timeout, stdin-fed calls, scripts not served); the review names seven call sites that would close the gap for about 1 CPU-s of the file's 88. The wall's bound was set from the baseline's 804 s suite of 1,129 checks; the suite measured has 1,450 checks and took 974.2 s before, so the gain is −37.6 %, and 8.1 s is less than the 18 s by which two solo runs of one tree differed at the re-baseline (776.6 and 794.6 s, D1). By the rule written here before the run (the absolute rows decide unless Michael confirms the ratio reading) both misses go to a diagnosis: block `## D4x`, filled in; whether it runs is **Decision 1**. **The block's other checks, on `7867c85`:** no note text changed (the block's grep prints two line pairs, `entries.mjs render` and `memlint.mjs gotchas`, whose quoted note text is identical on both sides: only the call in front went from `node …` to `ask …`; the helper's own lines, `helper restarted: <why>` and `helper off: <why>`, are a `printf` into `run.log`); check names 1,331 → 1,454, 123 added and none removed, fast names 580 → 688; every one of the 97 check files has its tier line (57 fast, 40 slow; `91-resident-helper` fast, 60 checks in 14.7 s; `92-resident-helper-run` slow, 15 checks in 72.0 s); the review (`docs/plans/2026-11-05-H1-review.md`) found 0 Critical, 1 Important (a writer ran twice when the helper declined an answer holding a NUL: fixed, its check seen red then green) and 7 Minor (4 fixed, 3 left with a reason each). **Not checkable on this run:** `helper restarted` in the run's own `run.log` cannot be anything but 0, since the harness that drove the run (`f6f5960`, in its `summary.json`) has no `lib/helper.mjs`; the count is read on the first real run started after the live checkout holds PR #104 (**Decision 6**). **Defaults against the spec, Michael's to call:** under a lane, `check.sh` no longer spawns for the tree's key: the lane asks its helper and hands the key down in `HARNESS_CHECK_TK` (the spec said `check.sh` spawns as today; the session's question card closed when gc removed the run: **Decision 2**). Recorded as *default* in the decision file and left for his read: all eleven scripts served; the request carries the whole environment; `$SRANDOM` ids and `$BASHPID` in place of the spec's counter and `$$`; a served script's stderr passed through a file so every redirect keeps its destination; every served script now exits 70 on a throw and drops its partial output (ten of the eleven exited 1 before); `treekey.mjs` trusts the index as `git status` does (a stale key only under `core.trustctime=false` or `core.checkStat=minimal`, which no harness path sets; 139 ms per call on a fresh checkout until its index is next written; a CRLF blob committed before `text=auto` gets a new key once). **The run-resilience counters (F1), read off this run:** fix rounds 0 opened; `failed the re-check` 0; `succeeded on try` 0 (no merge step needed a retry); 6 record-branch push streaks between 11:00 and 11:05, each recovered within a minute (12 log lines; the retro proposes collapsing them); the tmux server stayed up. Before the run (session 7): needs satisfied 2026-11-05 (D3 and F1 merged, the live checkout at `bb3a418`); block given to Michael (session 7), not yet queued. Stays a harness run (Michael 2026-11-04): D5 reads its lane time and the `helper restarted` count comes from its run.log; the first run on F1's driver (no end time, `MAX_FIX_ROUNDS=2`; what ended the tmux server under F1's run on 2026-11-04 is still not known). **The before row moved since the spec** (supervisor 2026-11-05, said before the run): the suite is 1,332 checks in 95 files (39 slow) and F1's hand sessions' full runs took 897, 926.8 and 940.9 s at 4 jobs (the sessions' own runs, not the solo method), against the 804 s and 3,136 CPU-s the spec's ≤ 600 s and ≤ 2,300 CPU-s were set from; F1 added four slow files (`88-origin-outage`, `88-origin-after-gc`, `89-no-deadline`, `90-fix-rounds`) and file 13 was 2,651 node starts at D1, not 3,139. H1-04 measures its own before on the run's base, so the node rows (file 13 ≤ 300, a stub start ≤ 30) stand as written, and the wall and CPU rows are read both ways: the spec's absolute, and the ratio it stood for (−25 % of H1-04's before). Which reading decides is Michael's; unconfirmed, the absolute rows decide and a miss goes to Dx |
| D4x | the resident helper's diagnosis (the Dx block, filled in): what the two missed rows mean and whether anything is to fix | `claude` | Michael's call (Decision 1) | held | written 2026-11-05 (session 8), not dispatched: the miss, the measured values and where to look are in block `## D4x`. The supervisor's reading, his to accept or to have checked by this session: the node-starts row is a prediction that undercounted the helpers and the calls left as spawns (corrected: ≤ 340 for file 13, or ≤ 300 once the review's seven call sites are wired), and the wall row is met as a ratio (−37.6 % against the −25 % the 600 s stood for) and missed as an absolute by less than the run-to-run spread |
| D5 | the tiers' lane-time numbers (phase 3's measurement, read off the resident helper run): how much of a session's time the suite still takes | `claude` measurement | D4 ended | not started | **needs satisfied 2026-11-05 (the resident helper run ended 13:46; RUNNING 0, QUEUED 0); block given to Michael (session 8).** So far, from the run's report and log, not D5's method: 0.2 full suite runs per coding session (1 in 6, against ≤ 0.2: on the line), 1.2 fast runs per session (predicted 1.5–2.5: under), 0 verify reds (≤ 1), 0 un-passes; the sessions' own suite runs took 1,662 s of the lane's 12,420 s, about 13 % (a rough read: D5's share counts every caller, the verify's full run included), most of it one session (H1-02b, two runs, 828 s); a fast run inside a session took 158 s before the helper was wired (H1-01) and 101 s after (H1-05). Earlier note: after F1's M3 a verify red opens a fix round: D5 counts fix rounds beside verify reds; one session under the tiers already measured: F1's M1-01 (run `agent-harness-2026-11-04-2`), 1 full and 1 fast run in the session, suite 1,023 s of 1,738 s (59 % against the predicted 20–30 %): D5 says whether D4's sessions also run the full suite bare |
| D6 | phase 4: slim suite | by hand, one session per milestone (Michael 2026-11-04; was a harness run) (`2026-11-03-slim-suite.md`) | D4 merged | not started | by hand like F1 (`docs/plans/2026-11-04-f1-by-hand.md`); the supervisor writes its session prompt when D4 has ended. Proposed for its brief (supervisor 2026-11-04, Michael to confirm): split `39-memlint-m4` (its 16 pure cases to `tests/unit/memlint.test.mjs`, the self-lint one-liner stays a fast gate until F3's tier check replaces it (Michael to confirm F3), the two stub runs slow; CHECK_KEY_MAP and `82-key-map-lint` follow); `84-node-memo` to slow; rows for `86-fast-gate`, `87-fast-gate-run` in the tiers assignment table; file names that don't read as a tier (`fast-gate` is the feature, not the tier: e.g. `86-session-gate`, `87-run-session-gate`) and the runner's per-file line printing the tier (Michael: yes, 2026-11-04). Session 8, 2026-11-05: the resident helper is merged, so what the slim suite starts from is 1,454 check names in 97 files (57 fast, 40 slow) and a solo suite of 608.1 s and 2,107.9 CPU-s at 1,450 checks; its −15 % of names is counted from the names at its base. It waits on the lane-time measurement (D5) being read and on Decisions 1 and 3. The hand sessions' prompt is written in the supervisor session that follows D5, with those answers in it; unlike F1 there is no feature list from a run's initializer, so each milestone's session plans its features from the spec with Michael at its first step (proposed) |
| D7 | phase 5: every project | `claude` design | D6 merged | not started | – |
| Dx | a diagnosis (template) | `claude` | a missed prediction | as needed | – |

A row's status is one of `not started`, `queued`, `running`, `ended: <run>`, `merged: PR #<n>`, `measured: <file>`,
`missed: <measure>`, `done`. The supervisor writes it with the evidence (a PR number, a findings file, a number).

## Names

*(Added 2026-11-05, session 8. One line per code and coined term, in the words the supervisor uses with Michael. Rows of
the Status table written before this table keep their wording.)*

| name | what it is |
|---|---|
| D0 | the supervisor: the session that checks what finished, updates this list and names the next command |
| D1 | the re-baseline: the suite's solo wall, CPU and node starts measured on `main` before any phase |
| D2 | phase 1, the unit tier: the pure checks moved into `tests/unit/` under one node process |
| D2x | the unit tier's diagnosis, filled in and held (never run) |
| D3 | phase 3, the tiers: every check file fast or slow, a session's `passes` on the fast tier, the full suite at verify |
| D4 | phase 2, the resident helper: one warm node process per driver and lane answers the `.mjs` questions |
| D4x | the resident helper's diagnosis, filled in and held until Decision 1 |
| D5 | the tiers' lane-time measurement: the sessions' suite share of lane time, read off the resident helper run |
| D6 | phase 4, the slim suite: a coverage map, a trim with no coverage lost, checks pushed down into unit tests |
| D7 | phase 5, every project: a design (no code) of which parts of this suite travel to the other projects |
| Dx | the diagnosis template: a session that says why a prediction missed and ends in re-measure, fix, or prediction wrong |
| F1 | run resilience: merges retried through an origin outage, no default end time, a red verify opens a fix round |
| F1b | F1 built by hand, one interactive session per milestone |
| F2 | fix triage: a read-only session groups a red verify's failures into issues (deferred until fix rounds show a need) |
| F3 | the memory curator: one session at a run's end curates `CLAUDE.md` from the sessions' findings (proposed) |
| C1 | the milestone before this effort that cut node starts with a memo (run `agent-harness-2026-11-03`) |
| U1 | the unit tier's one milestone (its features U1-01 … ) |
| T1, T2 | the tiers' two milestones: the runner and the assignment; then the gate (`check.sh --fast`) and the prompt |
| H1 | the resident helper's one milestone; H1-04 is its proof feature (the before and after table), H1-05 its review |
| S1–S4 | the slim suite's four milestones: the coverage map; the trim; the `checks:` line and budget; the purity moves |
| M1–M3 | run resilience's three milestones: origin retries; no default end time; fix rounds |
| the fast tier | the check files under 30 s solo plus the unit tier: what a coding session runs (`bash tests/run.sh --tier fast`) |
| the slow tier | the rest: stub runs of whole harness runs; it runs with the full suite at verify |
| the resident helper | `lib/helper.mjs`, started once per driver and lane shell and asked through `ask` in `lib/record.sh`; `HARNESS_HELPER=0` turns it off |
| a node start | one `node` process started; the cost the helper removes (27–41 ms each) |
| file 13 | `tests/checks/13-run-2-michael-sets-desk.sh`, the large check file every exec count is taken on |
| a stub start | one `harness start` in the suite, with `tests/stub-claude.sh` and `tests/stub-gh.sh` standing in for `claude` and `gh` |
| the solo suite | `bash tests/run.sh` at 4 jobs with no other suite or run alive; its wall and CPU are the plan's two headline numbers |
| a quiet box | `harness status` shows RUNNING 0 and QUEUED 0 and no other suite runs: the condition for any timing |
| a fix round | after a red full suite at verify, the driver appends a fix feature and verifies again (at most `MAX_FIX_ROUNDS`, 2) |
| lane time | the wall time a lane spends from its first session to its verify; the suite's share of it is what the tiers cut |
| a deciding row | a row of a spec's Predictions table set in bold: a miss there goes to a diagnosis before the next phase |

## Decisions

*(Added 2026-11-05, session 8: the open questions lifted out of the rows above, numbered; Michael answers by number. A
closed one keeps its number with his answer and the date.)*

| # | question | what waits on it | options and the supervisor's recommendation | status |
|---|---|---|---|---|
| 1 | The resident helper missed two deciding rows narrowly (file 13's node starts 337 against ≤ 300; the solo wall 608.1 s against ≤ 600 s). Run the diagnosis session (D4x), or accept them as predictions that were wrong? | the slim suite (D6) | (a) accept: record the corrected rows (file 13 ≤ 340 as built; the wall −25 % of the run's own before, met at −37.6 %) and go on; (b) paste block `## D4x` for a session to check the measurement and write the diagnosis file; (c) accept, and add the review's seven call sites to the slim suite's brief so file 13 lands under 300. **Recommended: (a)**: the run's findings file already itemises both causes from the exec tables and the supervisor's recount agrees, so a diagnosis session would re-derive them; (c) buys about 1 CPU-s of an 88 s file | open |
| 2 | Under a lane, `check.sh` now takes the tree's key from the lane's helper (`HARNESS_CHECK_TK`) instead of spawning `treekey.mjs` itself, a default beyond the spec that the resident helper run asked about. Keep it? | nothing | (a) keep; (b) restore the two spawns and raise the stub start's bound from 30 to about 52 node starts. **Recommended: (a)**: the review read this path and found nothing, the key is asked from the tree's top right before `check.sh` starts, and the helper-on and helper-off logs are identical | open |
| 3 | The slim suite's brief (D6), proposed 2026-11-04: split `39-memlint-m4` (its 16 pure cases to a unit test, the self-lint one-liner a fast gate, the two stub runs slow); move `84-node-memo` to the slow tier; add `86-fast-gate` and `87-fast-gate-run` to the tiers' assignment table; rename the two fast-gate files so their names do not read as a tier (the runner printing each file's tier is already a yes). Confirm? | the slim suite's hand-session prompt | yes to all, or name the ones to drop. **Recommended: yes to all** | open |
| 4 | The memory curator (F3): confirm it as a piece, and where it goes (it was proposed to run before the resident helper; that run is done)? | whether the slim suite keeps memlint's self-lint or hands it to the curator's tier check | (a) after the slim suite, which keeps the self-lint as a fast gate until then; (b) before it; (c) drop. **Recommended: (a)** | open |
| 5 | Run resilience (F1) left defaults against its spec: each origin try may take 120 s (`ORIGIN_TRY_TIMEOUT`), so one merge step's worst case is 950 s against the spec's 230 s; a run that ends with a re-base pending has a note and no needs card (its review's finding 4); gc holds only `harness/<run>`; `89-no-deadline` is slow. Accept, or a fix? | nothing | accept all, or name one for a follow-up spec. No recommendation beyond: the first two are the ones a real outage would show | open |
| 6 | Two of this list's checks do not measure what they name. (i) `git diff <base> main -- lib/*.sh \| grep '^[-+].*note "'` (blocks D4 and D6) also prints a line whose call changed and whose note text did not. (ii) `grep -c 'helper restarted'` on the resident helper run's own `run.log` cannot fail: that run was driven by a harness without the helper. Change them? | (ii): the first real run after the live checkout holds PR #104 | (i) compare the note texts removed with those added, which prints nothing when no text changed (tried on this run's diff: nothing): `d=$(git diff <base> main -- lib/*.sh); diff <(sed -n 's/^-.*\(note ".*\)$/\1/p' <<< "$d" \| sort) <(sed -n 's/^+.*\(note ".*\)$/\1/p' <<< "$d" \| sort)`; (ii) Michael runs `grep -c 'helper restarted\|helper off' ~/.local/state/harness/<project>/<run>/run.log` on the first run of any project that starts after the sync and pastes the count (expected 0 for a run that ended normally). **Recommended: both** | open |
| 7 | What ended the tmux server under the run-resilience run on 2026-11-04 15:27 (the queue runner and the driver exited; cause not found)? | nothing; it is why F1 and the slim suite are by hand | no action proposed: the resident helper run went 3.85 h on the same driver with no repeat (one run is not evidence it is gone) | open |

## Log

*(Added 2026-11-05, session 8. One entry per supervisor session, newest first; sessions 1 to 7 are in the D0 row.)*

- **2026-11-05 14:10, session 8.** The resident helper run (`agent-harness-2026-11-05`, D4) ended done at 13:46: 6/6,
  $30.91, 3.85 h, PR #104 (the milestone), PR #105 (the record). Checked against its block and the spec's Predictions
  table: 5 rows held, 2 deciding rows missed narrowly (file 13's node starts, the solo wall), 1 other held idle and
  missed under load (the spawned `treekey.mjs` call); details in the D4 row. Wrote block `## D4x` (the diagnosis, filled in,
  held on Decision 1) and gave Michael the lane-time measurement (D5), which waits on neither. Found: the block's
  `helper restarted` check could not fail on this run and its note-text grep prints unchanged notes (Decision 6); the
  run's three question cards were closed by gc with the run, so its one real question came here as Decision 2; the
  retro session's edits to files it may not change were reverted by the driver's guard (commit `f39e11d`); H1-02b's
  session peaked at 4,266 MB; `origin/f1/M1-01` is gone and `origin/harness/agent-harness-2026-11-04-2` (the dead
  run-resilience run's record branch) is still on origin. The live checkout was 49 commits behind origin when this
  session started (the runner is off, so nothing levelled it), which is why Michael's start command read the
  supervisor prompt from before PR #101; `harness sync` at this session's end levels it.

---

## D0 · Start the supervisor

Produces: a Fable session that reads this list and the plan, finds each piece's results, verifies the numbers, and
gives you the next block. Start it any time, and again each morning; it keeps no state but this file's Status table.
The supervisor checks: nothing (it is the checker).

```bash
cd ~/projects/agent-harness && claude --model claude-fable-5-1 "$(cat docs/plans/2026-11-03-test-suite-redesign-supervisor.md)"
```

---

## D1 · Re-baseline on `main` after C1 merged, with the box quiet

Produces: §5 "Re-baseline on main" appended in place to `findings-and-research/2026-11-03-redesign-baseline.md` (solo
wall, CPU, checks, the three slowest files, node execs by class for file 13, the eval files' node starts), merged by
PR. Model: Fable (the write-up compares four sources; a smaller model would be fine for the runs alone).
The supervisor checks: the section exists with the five rows and `harness status` showed RUNNING 0 at its start; the
solo wall is within 5 % of C1-04's after row (803.8 s) at the then check count, else the box was not quiet (rerun).

```bash
cd ~/projects/agent-harness && claude --model claude-fable-5-1 "$(cat <<'EOF'
You are the re-baseline session for the test suite redesign of this repo (agent-harness). CLAUDE.md binds: enter a worktree before writing anything (the live checkout is off limits); never touch real runs or real state; never send a notification; no `harness` command but `status`, `report`, `parked`, `sync`.

Read first: docs/plans/2026-11-03-test-suite-redesign.md (§1, §6), findings-and-research/2026-11-03-redesign-baseline.md (§1, §2: the rows you add a sibling to), journal/decisions/2026-10-31-fewer-node-starts.md (C1-04's method, the one you repeat), findings-and-research/2026-11-03-exec-table/README.md and exectable.mjs (the parser for the exec counts by class).

Preconditions, in this order: `harness status` shows RUNNING 0 and QUEUED 0 (if not, stop and say so: this measurement needs the box to itself); `git log origin/main --oneline -5` shows run agent-harness-2026-11-03's C1 merged (a `C1` merge PR). Your worktree is on origin/main.

Do, in your worktree, writing outputs to your scratch directory:
1. Two solo full suites, one after the other: `systemd-run --user --scope -p MemoryMax=3G /usr/bin/time -v env TEST_JOBS=4 bash tests/run.sh > <scratch>/solo-<n>.out 2> <scratch>/solo-<n>.time` (the runner's own `wall … s` line is the wall; user+sys from time -v is the CPU; the check count from the last line; the `slowest:` line). Give the Bash call a timeout of at least 2,400,000 ms or run it in the background and wait for its end notification; never poll.
2. `strace -f -e trace=execve,clone,clone3,vfork,fork -o <scratch>/file13.strace bash tests/checks/13-run-2-michael-sets-desk.sh > <scratch>/file13.out 2>&1`, then `node findings-and-research/2026-11-03-exec-table/exectable.mjs` over it (read its README for the arguments) for node execs by class (driver, lane, cli, stub, tests/lib.sh) and by script+subcommand, and the counts of git, cat, date, bash.
3. The unit layer: `strace -f -e trace=execve -o <scratch>/pure.strace bash tests/run.sh 01- 02- 03- 04- 05- 06- 07- 11- 12- 35- 51-` and count successful `node` execs; `/usr/bin/time -v` of the same command for its CPU.
4. Append to findings-and-research/2026-11-03-redesign-baseline.md a section `## 5. Re-baseline on main (<date>, <commit>)` with: a table of the two solo runs (wall, user+sys, checks, red files, slowest three) beside C1-04's after row; the file-13 class table and top ten script+subcommand rows beside §2's; the unit layer's node count and CPU; the load average before each run; and one paragraph saying which of §1–§3's numbers moved and why (a merged C1 feature, a check count change). Keep the raw .out/.time/.strace summaries (not the raw strace) under findings-and-research/2026-11-03-redesign-baseline/.
5. Commit on your branch, push, open a PR titled "findings: re-baseline on main for the test suite redesign", merge it (`gh pr merge --merge`), delete the branch, remove your worktree.

Rules: measure, do not fix; change nothing under lib/, bin/, tests/ or prompts/. Report at the end: the two walls, the CPU, the node count for file 13 by class, and the PR number.
EOF
)"
```

---

## D2 · Phase 1: the unit tier (a harness run)

Produces: run `agent-harness-<date>` building `docs/specs/2026-11-03-unit-tier.md` (U1: the reporter, `00-unit-tier.sh`,
`tests/unit/`, the move, the table in `findings-and-research/2026-11-03-unit-tier.md`, the decision file, docs), merged
by the run's PR. The queue runner is going (`harness status` says so); if it is not, `harness queue start` (no `--until`: runs are not tied to a time of day, Michael 2026-11-04).
The supervisor checks: `harness report <run>` 100 % passing and merged; the findings table has the before/after rows
and the unit layer's node starts are 1; `git diff <base> main -- tests/fixtures/check-names.txt` shows only added
names; `grep -c 'node --input-type=module' tests/checks/*.sh` on main is under 10 (the kept evals listed in the
decision file); `node --test --test-isolation=none tests/unit/` runs green in under 1.5 s on main.

```bash
cd ~/projects/agent-harness && harness queue add ~/projects/agent-harness --spec docs/specs/2026-11-03-unit-tier.md --brief "Phase 1 of docs/plans/2026-11-03-test-suite-redesign.md: build the unit tier spec in full as one milestone U1, four to six features, the measurement feature (U1-05) before the review feature. Proceed on the spec's defaults, mark them *default* in the decision file, never park. Every moved check keeps its name: the full run's conformance is the proof. The measurement needs no other suite alive: check harness status before each timed run."
```

---

## D2x · Phase 1's diagnosis, filled in (held: paste only if the supervisor's `prediction wrong` reading is not enough)

Produces: `findings-and-research/2026-11-04-unit-tier-diagnosis.md`, merged by PR. The supervisor (session 3) did not
dispatch it: the spec's CPU row (4–6 s → < 1 s) and starts row (108 → 1) were made for the evals alone, D1 corrected
the before row to §5.3 (149 starts, 9.35 CPU-s, the evals 60 of the starts) before the run, and the run's findings
file names the cause with numbers (the runner, `tests/lib.sh`'s per-file state and the CLI checks kept in bash are the
CPU; the evals' 59 starts went to 1). The tier itself met every prediction. D3 does not wait on this block.

```bash
cd ~/projects/agent-harness && claude --model claude-fable-5-1 "$(cat <<'EOF'
You are a diagnosis session for the test suite redesign of this repo (agent-harness). CLAUDE.md binds: enter a worktree before writing anything; never touch real runs or real state; no `harness` command but `status`, `report`, `parked`, `sync`; never send a notification. Read-only on every input; the state dir of an ENDED run may be read as findings-and-research/2026-10-29-run-time-budget.md's method does.

The miss: phase 1 (docs/specs/2026-11-03-unit-tier.md) predicted the CPU of the pure files = 4–6 s → < 1 s and the node starts of the unit layer = 108 → 1 (its Predictions table) and the run agent-harness-2026-11-03-2 measured 8.84 CPU-s and 117 node starts for the eleven files' successors (set B), 0.30 CPU-s and 1 start for the tier alone (findings-and-research/2026-11-03-unit-tier.md, ## Table).

Read first: the phase's spec and its Predictions table; the findings file with the measured row and the raw files beside it; the run's decision file(s) under journal/decisions/ and `harness report agent-harness-2026-11-03-2 --md`; docs/plans/2026-11-03-test-suite-redesign.md §4 (the phase's row and the one after it); findings-and-research/2026-11-03-redesign-baseline.md (the baseline the prediction was made against: §5.3 is the layer's corrected before row).

Do: (1) check the measurement itself (was the box quiet: the load average and `harness status` the session recorded; the same tree before and after; the same check count or the difference accounted); (2) if the measurement stands, find the cause in the code or the run with evidence (a profile, an exec count, a diff, a log line: run `strace`, `time -v`, the exec-table parser or a subset of the suite yourself, in your worktree, never a real run); (3) write findings-and-research/2026-11-04-unit-tier-diagnosis.md: the miss, what you checked, the cause with its evidence, and exactly one outcome: `re-measure` (why the number is not trustworthy and the exact command to repeat), `fix` (a spec section appended in place to the phase's spec under `## Fix after agent-harness-2026-11-03-2`, buildable by a fresh session: finding, choice with defaults, checks written first, its own prediction), or `prediction wrong` (the corrected prediction and why the gain is bounded there). Do not build the fix.

Commit on your branch, push, open a PR titled "findings: unit tier diagnosis after agent-harness-2026-11-03-2", merge it, delete the branch, remove your worktree. Report: the cause in two sentences, the outcome, and the PR number.
EOF
)"
```

---

## D3 · Phase 3: tiers (a harness run, two milestones in series)

Produces: run building `docs/specs/2026-11-03-suite-tiers.md` (T1 the runner and the assignment; T2 `check.sh --fast`,
the driver's calls, the prompt), two PRs, `findings-and-research/2026-11-03-suite-tiers.md` with the tier timings, two
decision files. Needs D2 merged (the fast tier starts from `00-unit-tier`).
The supervisor checks: both milestones merged; the fast tier's solo wall in the findings file ≤ 180 s and its check
count; every file in `tests/checks/` has a tier header on main (`for f in tests/checks/*.sh; do sed -n 2p "$f"; done |
sort | uniq -c`); `tests/fixtures/check-names-fast.txt` exists and `bash tests/run.sh --tier fast` is green on main
(ask Michael to run it, or trust the run's verify); `prompts/coding.md` has `run the fast tier once, last`; the
assignment table lists every file with a time and a reason. Lane-time numbers come from D5, not this run.

```bash
cd ~/projects/agent-harness && harness queue add ~/projects/agent-harness --spec docs/specs/2026-11-03-suite-tiers.md --brief "Phase 3 of docs/plans/2026-11-03-test-suite-redesign.md: build the tiers spec in full, milestones T1 then T2 in series (T2's first feature after T1), three to five features each, the review feature last in each. Proceed on the spec's defaults, mark them *default* in the decision files, never park. The gate: passes stands on a fast-tier green; verify and merge stand on the full suite; a fast-green is never read as a green. T1's timing feature needs no other suite alive: check harness status first."
```

---

## F1 · Run resilience: the spec (a `claude` session), then its run

Produces: `docs/specs/2026-11-04-run-resilience.md` (three milestones in series), merged by PR, and the `harness queue add`
command for its run, which goes before D4. Michael asked for it on 2026-11-04 after D3's T2 sat verified and unmerged.
The supervisor checks: the spec on main with M1–M3, each feature's checks named and written first; then the run like D2
(100 % passing, every milestone merged, the decision files' defaults against this block).

```bash
cd ~/projects/agent-harness && claude --model claude-fable-5-1 "$(cat <<'EOF'
You write one spec for agent-harness. CLAUDE.md binds: enter a worktree before writing; never touch real runs or real state; never send a notification; no `harness` command but status, report, parked, sync.

Write docs/specs/2026-11-04-run-resilience.md in the shape of docs/specs/2026-11-03-suite-tiers.md (provenance, finding, milestones and features, defaults marked *default*, predictions and falsifiers). Three milestones in series, M1 then M2 then M3, three or four features each, the review feature last in each. For every feature, the checks to write first in tests/checks/ (tier by journal/decisions/2026-11-03-suite-tiers.md's 30 s rule) or tests/unit/, and the files it touches. Fakes mirror the live API: copy the real lines below verbatim.

M1 · merges that survive a GitHub outage. The incident (run agent-harness-2026-11-04): T2 was verified at 06:17 and never merged. run.log: from 06:07:42 every record-branch push failed ("push of harness/agent-harness-2026-11-04 failed", run.log only); at 06:17:54 GitHub rejected the tag push (" ! [remote rejected] run/agent-harness-2026-11-04/T2 -> run/agent-harness-2026-11-04/T2 (failure)") while harness-log.md said "T2 verified and tagged run/agent-harness-2026-11-04/T2"; merge_one's fetch failed at 06:18:01, 06:18:04, 06:18:10 ("T2: fetch of main failed; merged later": the lane's merge_own, then the driver's finish merge_milestones), and lane_done (lib/lane.sh:236) fell through to "lane T2 closed (T2 needs Michael: its merge)" with no needs record and no notification (harness needs showed 0). GitHub was back by 06:18:41. At 06:19 gc removed the run with T2 verified and unmerged (its question cards closed "by sweep: run removed"). Reading bin/harness, `harness merge <run>` on a gc'd run reaches cmd_start with no worktree and dies on "a new run needs --spec" (.harness/config.sh has no SPEC_FILES): confirm it on a throwaway run before you state it. Spec: (1) transient origin failures (fetch, branch push, tag push, gh pr create/merge) in merge_one and verify's tag are retried with bounded backoff (a few minutes in all); one that outlasts it is a `note`, opens a needs card (a new kind, its command `harness merge <run>`) and notifies through the stubbed notify; lane_done never says "needs Michael" without a card; (2) "verified and tagged" is noted only when the tag reached origin, otherwise the note says the tag is local only; (3) record-branch push failures: one note when a streak starts and one when it ends; (4) gc keeps a run that has a verified, unmerged milestone, and `harness merge` works on a run whose worktree is gone (from the local tag and the record on main).

M2 · no default end time (Michael, 2026-11-04: runs go regardless of the time of day). Today every start or continue segment ends "deadline" 8 h in (lib/config.sh:12 `HOURS=8`, lib/driver.sh:53 `DEADLINE=$(( T0 + HOURS * 3600 ))`; a deadline end never continues by itself, lib/driver.sh:348-353); the queue runner already has none (lib/queue.sh:20 `UNTIL=${1:-0}`). Spec: no deadline unless `--until` or a set HOURS asks for one (*default*: HOURS empty or 0 = none, documented in templates/user/config.sh); a run is still bounded by MAX_SESSIONS, attempts, the weekly budget and usage-limit waits, and the spec says so. Docs in the same milestone: the overnight framing and `--until` as the normal way out of README.md (:33, :42, :45, :57, :178, :182, :189, :251, :300, :343), docs/architecture.md (:284, :582, :698, :724), CLAUDE.md (:7 "This repo runs Michael's nights", :70 "Tonight's scope": Michael's request, 2026-11-04), prompts/parts/where-things-go.md:6, prompts/parts/where-things-go-readonly.md:6, prompts/draft-claude-md.md:8,14, templates/project/CLAUDE.md:22, templates/user/config.sh:29, comments at lib/queue.sh:81, lib/driver.sh:274, bin/harness:533, and memlint's night-scope message (lib/memlint.mjs:143-165: the rule stays, its words say "run scope"). `--until` stays documented as an option. Specs, plans and decision files are history: leave them; this milestone's decision file says what changed.

M3 · a red verify is fixed, not parked (Michael, 2026-11-04: a measured step toward an agentic loop). Today a verify whose full suite is red (lib/lane.sh verify: `red`, the verify_red card, variant `own` for a slow-tier red the fast gate let through, else main merged in) stops the milestone for Michael. Spec: instead, the driver appends a fix feature to the milestone (its steps name the failing checks, HARNESS_FAILED names and the output file), the lane's next session takes it, its passes stands on the failing files green plus the fast tier, then the milestone verifies again; at most MAX_FIX_ROUNDS (*default* 2) per milestone, then today's verify_red card and notification; a flake (a green rerun) never opens one; each round is a note and is counted in summary.json and `harness report` (fix rounds opened, fixed); a fix session counts against MAX_SESSIONS. No LLM decides whether to loop: the driver does, by the rule. Shape it for a later triage step (not built now): the fix feature carries an `issue` field (this milestone: one issue per red, `all`), and each round records the failing names before and after its fix in metrics.jsonl, so a triage session can later split one red into several fix features without a format change, and the rounds show whether one fix per red clears it.

Merge the spec by PR titled "specs: run resilience" (gh pr merge --merge), delete the branch, remove the worktree. Report the spec path and the `harness queue add ~/projects/agent-harness --spec … --brief "…"` command you suggest (milestones in series, proceed on defaults marked *default*, never park; no `--until`).
EOF
)"
```

---

## F1b · F1 by hand: one interactive session per milestone (M1, M2, M3)

Produces: the three milestones of `docs/specs/2026-11-04-run-resilience.md`, each built by one interactive session
with Michael at the terminal and merged by its own PR (`F1 M<n> by hand: …`), with its decision file
(`2026-11-04-origin-retries`, `-no-default-end-time`, `-fix-rounds`). M1 starts from M1-01's commit (`origin/f1/M1-01`,
built by run `agent-harness-2026-11-04-2`). The procedure, the steps that are Michael's and the session's rules:
`docs/plans/2026-11-04-f1-by-hand.md`. Needs: the milestone before it on main; `harness status` RUNNING 0, QUEUED 0.
The supervisor checks, per milestone: the PR merged and its body's full-suite line (`N/N checks passed`); the decision
file on main and its defaults against the spec; `git diff <base> main -- tests/fixtures/check-names.txt` adds only,
and holds the names the milestone's features list (`docs/plans/2026-11-04-f1-by-hand/feature_list.json`); the
reviewer's findings each with what was done; architecture and README in the same PR; M2: no `--until` advice or
overnight framing left where the spec names it; M3: `MAX_FIX_ROUNDS=0` is today's behaviour. After M3: `harness sync`
done (Michael pastes `git -C ~/projects/agent-harness log --oneline -1`), then D4.

Once, before M1:

```bash
harness needs done agent-harness-2026-11-04-2/1 --why "F1 built by hand: docs/plans/2026-11-04-f1-by-hand.md"
```

Each milestone, in order (change the last line to `Milestone: M2`, then `Milestone: M3`):

```bash
cd ~/projects/agent-harness && git fetch -q origin && claude --model claude-opus-5-5 "$(git show origin/main:docs/plans/2026-11-04-f1-by-hand-session.md)

Milestone: M1"
```

---

## D4 · Phase 2: the resident helper (a harness run)

Produces: run building `docs/specs/2026-11-03-resident-helper.md` (H1: `main(argv, io)` in the served scripts,
`lib/helper.mjs`, `ask`, the lifecycle, `treekey`'s cut, the before/after rows in
`findings-and-research/2026-11-03-resident-helper.md`), one PR. Needs D3 merged. This run is also the first real run
under the tiers: D5 reads its lane time.
The supervisor checks: merged; the rows: node starts per file 13 ≤ 300 and per stub start ≤ 30, CPU of the solo suite
≤ 2,300 s, wall ≤ 600 s (a miss → Dx before D6); `git diff <base> main -- lib/*.sh | grep '^[-+].*note "'` is empty
(no note text changed) except the helper's own line; `grep -c 'helper restarted' ~/.local/state/harness/agent-harness/<run>/run.log`
is 0 (ask Michael to run it: the supervisor never reads the state dir).

```bash
cd ~/projects/agent-harness && harness queue add ~/projects/agent-harness --spec docs/specs/2026-11-03-resident-helper.md --brief "Phase 2 of docs/plans/2026-11-03-test-suite-redesign.md: build the resident helper spec in full as one milestone H1, five or six features, H1-04 (the proof) the last build feature, then the review. Proceed on the spec's defaults, mark them *default* in the decision file, never park. Every answer byte for byte the spawned script's: a stub run with HARNESS_HELPER=0 and without must give identical logs. No note text changes. H1-04 needs no other suite alive: check harness status first."
```

---

## D4x · The resident helper's diagnosis, filled in (held: paste only if Decision 1's answer is (b))

Produces: `findings-and-research/<the session's date>-resident-helper-diagnosis.md`, merged by PR: whether the two
missed rows stand as measured, their cause with evidence, and one outcome (`re-measure`, `fix`, or `prediction wrong`
with the corrected prediction). The supervisor (session 8) did not dispatch it: the run's findings file already
itemises both causes from the exec tables, and the supervisor's recount of the raw tables agrees (the D4 row).
The supervisor checks: the file names a cause with evidence and ends in one of the three outcomes; a `fix` becomes a
new block under the D4 row. The slim suite (D6) waits on this block or on Decision 1's answer (a) or (c).

```bash
cd ~/projects/agent-harness && claude --model claude-fable-5-1 "$(cat <<'EOF'
You are a diagnosis session for the test suite redesign of this repo (agent-harness). CLAUDE.md binds: enter a worktree before writing anything; never touch real runs or real state; no `harness` command but `status`, `report`, `parked`, `sync`; never send a notification. Read-only on every input; the state dir of an ENDED run may be read as findings-and-research/2026-10-29-run-time-budget.md's method does.

The miss: phase 2 (docs/specs/2026-11-03-resident-helper.md) predicted, in its H1-04 table, node starts per large file (file 13, tests/checks/13-run-2-michael-sets-desk.sh) = 3,139 → ≤ 300 and the full suite's solo wall at 4 jobs = 804 s → ≤ 600 s, and the run agent-harness-2026-11-05 measured 337 node starts (2,665 before, on the run's base 07a31f6) and 608.1 s (974.2 s before; 1,332 checks before, 1,450 after) (findings-and-research/2026-11-03-resident-helper.md, ## The table). The other rows held: a stub start 20 node starts (≤ 30), file 13's CPU 88.0 s (≤ 110 s), the solo suite's CPU 2,107.9 s (≤ 2,300 s), 0 log lines changed, 0 helper restarts. One row that does not decide also missed under load: a spawned treekey.mjs call 64.4 ms inside a suite (≤ 60 ms; 49.3 ms idle).

Read first: the phase's spec and its Predictions table (H1-04); the findings file with the measured rows and the raw files beside it (findings-and-research/2026-11-03-resident-helper/: file13-<before|after>-execs.txt, suite-<before|after>.time, suite-<before|after>-files.txt, proof.log, chain.sh); the run's decision file journal/decisions/2026-11-03-resident-helper.md (the call-site table: which calls stay spawns and why) and `harness report agent-harness-2026-11-05 --md`; docs/plans/2026-11-05-H1-review.md (## Flagged by earlier sessions: the seven call sites that would bring file 13 under 300); docs/plans/2026-11-03-test-suite-redesign.md §4 (phase 2's row and phase 4's); findings-and-research/2026-11-03-redesign-baseline.md (the baseline the prediction was made against: §1, §2, and §5, where two solo runs of one tree took 776.6 and 794.6 s); the D4 row and Decision 1 of docs/plans/2026-11-03-test-suite-redesign-dispatch.md (the supervisor's recount: 337 = cli 162 + stub 48 + the checks' 9 + 32 helpers + 86 calls left as spawns).

Do: (1) check the measurement itself (was the box quiet: the load average and the gate lines in proof.log; one solo suite per tree, the after one started the second the before one ended; the trees differ by 118 checks, 15 of them file 92's 72 slot-s: say what the wall would be on the same check set, and whether 8.1 s is inside the run-to-run spread of a solo suite on this box, with two solo suites of origin/main if that is what it takes: `harness status` RUNNING 0 and QUEUED 0 first, `systemd-run --user --scope -p MemoryMax=3G /usr/bin/time -v env TEST_JOBS=4 bash tests/run.sh`, one after the other, never two at once); (2) if the measurement stands, find the cause in the code or the run with evidence (the exec tables by class and by script and subcommand, a diff, a log line: run `strace`, `time -v`, the exec-table parser or a subset of the suite yourself, in your worktree, never a real run), and trace the one `features.mjs ids` start the run left untraced; (3) write findings-and-research/<today's date>-resident-helper-diagnosis.md: the miss, what you checked, the cause with its evidence, and exactly one outcome: `re-measure` (why the number is not trustworthy and the exact command to repeat), `fix` (a spec section appended in place to the phase's spec under `## Fix after agent-harness-2026-11-05`, buildable by a fresh session: finding, choice with defaults, checks written first, its own prediction), or `prediction wrong` (the corrected prediction and why the gain is bounded there). Do not build the fix.

Commit on your branch, push, open a PR titled "findings: resident helper diagnosis after agent-harness-2026-11-05", merge it, delete the branch, remove your worktree. Report: the cause in two sentences, the outcome, and the PR number.
EOF
)"
```

---

## D5 · Phase 3's lane-time numbers, read off the phase 2 run

Produces: §Measured appended in place to `findings-and-research/2026-11-03-suite-tiers.md`: the sessions' suite share
of lane time, suite lane-seconds per 20 sessions, full and fast runs per coding session, `red on the verified tree`
count, un-passes, against the spec's prediction table; merged by PR. Needs D4's run ended (`harness status` FINISHED).
Model: Fable (the budget scripts need their method read and their caveats applied).
The supervisor checks: the section has every row of the prediction table with a measured value and held/missed; the
share is 20–30 % or the miss is explained by the run's shape (one lane, few sessions, a pause).

```bash
cd ~/projects/agent-harness && claude --model claude-fable-5-1 "$(cat <<'EOF'
You are the lane-time measurement session for phase 3 (tiers) of the test suite redesign of this repo (agent-harness). CLAUDE.md binds: enter a worktree before writing anything; never touch real runs or real state; no `harness` command but `status`, `report`, `parked`, `sync`; never send a notification. Read-only on every input. You may read ~/.local/state/harness/agent-harness/<run>/run.log and logs/*.jsonl of the ENDED run named below and the user journal, as findings-and-research/2026-10-29-run-time-budget.md's method does; never a live run's.

Read first: docs/specs/2026-11-03-suite-tiers.md (the Predictions table: every row is one you measure), findings-and-research/2026-10-29-run-time-budget.md (§Sources and method, §10, §11: the method and its two fixed problems), findings-and-research/2026-10-29-run-time-budget/budget.mjs, totals.mjs, escapes.mjs (the scripts; read their heads), findings-and-research/2026-11-03-suite-tiers.md (you append to it).

The run to measure: the most recent FINISHED agent-harness run in `harness status` whose spec was docs/specs/2026-11-03-resident-helper.md (`harness report <run>` names it); confirm with `harness status <run>`. If no such run has ended, stop and say so.

Do: reproduce §11's commands for that run (journalctl --user --since <the run's start> -o json … | grep harness- > $T/journal.jsonl; node budget.mjs …; node totals.mjs …; node escapes.mjs …) and read `harness report <run> --md` for the `Suite runs` row (full and fast per coding session) and the run's harness-log.md for `red on the verified tree`, `un-passed: fast tier red`, `suite ran` lines and `check-runs.log`-derived kinds. Then append to findings-and-research/2026-11-03-suite-tiers.md a section `## Measured (<run>, <date>)`: the prediction table with a measured column and held/missed per row, one line per miss saying what the data shows, the per-20-session scaling stated (n sessions), and the method's caveats that apply (one lane, few sessions). Keep the scripts' outputs beside the budget scripts as `*-output-<date>-tiers.txt`.

Commit on your branch, push, open a PR titled "findings: phase 3 tiers, the lane-time numbers from <run>", merge it, delete the branch, remove your worktree. Report: the share, the lane-s per 20, full and fast per session, verify reds, and the PR number.
EOF
)"
```

---

## D6 · Phase 4: the slim suite (a harness run, four milestones in series)

*By hand since 2026-11-04 (Michael): the command below is the harness form, kept for its brief's text; the supervisor
writes the hand sessions' prompt (the shape of `docs/plans/2026-11-04-f1-by-hand-session.md`) when D4 has ended.*

Produces: run building `docs/specs/2026-11-03-slim-suite.md` (S1 coverage map and mutation sample in
`findings-and-research/2026-11-03-suite-coverage.md`; S2 the trim, renames and push-down; S3 the `checks:` line and
`check_budget`; S4 the purity moves), four PRs, three decision files, the proposed `CLAUDE.md` rules in S3's entry.
Needs D4 merged (and D5 read, so a tiers miss is diagnosed first).
The supervisor checks: four milestones merged; the coverage file's tables; the trim decision file's rows each name a
successor; the names count on main is ≤ 85 % of the count at the run's base (`wc -l tests/fixtures/check-names.txt`
at both commits); the coverage union line in the decision file is ≥ before; `git diff <base> main -- lib/*.sh | grep
'^[-+].*note "'` is empty for S4; the S3 entry's `proposed_changes` holds the rules (`harness report` or the record's
entries.jsonl on main); the retro's `checks:` line exists in the run's retro.md.

```bash
cd ~/projects/agent-harness && harness queue add ~/projects/agent-harness --spec docs/specs/2026-11-03-slim-suite.md --brief "Phase 4 of docs/plans/2026-11-03-test-suite-redesign.md: build the slim-suite spec in full, milestones S1, S2, S3, S4 in series, two to four features each, review features as the spec says. Proceed on the spec's defaults, mark them *default*, never park. A removed check names its successor in the decision file and the coverage union never shrinks; no note text changes in S4; the CLAUDE.md rules go in the entry's proposed_changes, not into CLAUDE.md. S1's measurement runs need no other suite alive: check harness status first."
```

---

## D7 · Phase 5: every project (a design session, no code)

Produces: `docs/specs/2026-11-xx-every-project-testing.md` (the date of the session), a short design merged by PR.
Model: Fable. Needs D6 merged (the design reuses what phases 1–4 built).
The supervisor checks: the file exists on main with the four cases, the reusable/per-project split, the runner
question answered with a reason, the rules, and each live project's `CLAUDE.md` rules cited as binding.

```bash
cd ~/projects/agent-harness && claude --model claude-fable-5-1 "$(cat <<'EOF'
You are the phase 5 design session of the test suite redesign (agent-harness). CLAUDE.md binds: enter a worktree before writing anything; never touch real runs or real state; no `harness` command but `status`, `report`, `parked`, `sync`; never send a notification. Read other projects, change nothing in them. Write no code: a design.

Read first: docs/specs/2026-11-03-test-suite-redesign.md (Phase 5), docs/plans/2026-11-03-test-suite-redesign.md (§4 Phase 5, §6), the four phase specs under docs/specs/2026-11-03-*.md and their decision files under journal/decisions/ (what was built: the unit tier, the tiers and CHECK_FAST_CMD, the helper, the checks: line and check_budget), journal/learning/2026-10-30-test-engineering.md (entries 7, 8, 10), tests/run.sh and tests/lib.sh (what a bash suite kit would carry), templates/project/ (what a project already gets). Then each case, read-only: ~/projects/pathways (CLAUDE.md, .harness/config.sh, tests/), ~/projects/dj-crate-streaming (CLAUDE.md with its ## Live system: binding; .harness/config.sh; tests/), ~/projects/hit_list (CLAUDE.md, .harness/config.sh: `npx expo lint && npx tsc --noEmit && npx jest --silent`; its jest config), ~/projects/n8n-home (CLAUDE.md with ## Live system: binding; tests/checks, tests/fakes, tests/lib.sh). Also findings-and-research/2026-10-30-run-time-budget-dj-hitlist.md (dj's suite 59 % of lane time at 580–930 s; hit_list's 17 % at 8–30 s).

Write docs/specs/2026-11-<dd>-every-project-testing.md (today's date), under 200 lines: (1) for each of the four projects, its suite today (runner, size, time if known, share of lane time if measured) and its live-system rules that bind any change; (2) which parts of agent-harness's suite travel and how: the bash runner with tiers and conformance as a kit under templates/project/tests/ for bash suites (n8n-home), the tier convention for native runners (pytest markers and -m, jest projects or testPathPattern, bun/vitest for pathways: name the exact subset command per project as its CHECK_FAST_CMD), the stubs' "mirror the live API" rule as a CLAUDE.md line, the per-run counts and the checks: line the harness already gives; (3) one shared runner or one per language: answer with a reason; (4) the rules that keep each suite growing well: tiers from day one, a count in every run's log, a trim pass per iteration, a budget per milestone, a pure function gets a unit test; (5) per project, the first step and its cost (dj: a read-only `pytest --durations=25` profile is the first step of any dj night; hit_list: nothing until its suite is over a minute; pathways: …; n8n-home: the kit), and what Michael must decide before any of it is queued. Cite file paths for every claim about a project.

Commit on your branch, push, open a PR titled "specs: every project's testing, the phase 5 design", merge it, delete the branch, remove your worktree. Report: the file path, the runner answer in one line, and the PR number.
EOF
)"
```

---

## Dx · A diagnosis before the next phase (template; the supervisor fills the brackets)

Produces: `findings-and-research/2026-11-<dd>-<phase>-diagnosis.md`, merged by PR: what the data says about the miss,
the cause with evidence, and one of: a fix spec section (appended to the phase's spec, for a `harness queue add` the
supervisor then writes as a new block), a re-measure (the box was not quiet), or "the prediction was wrong, the
measure stands" with the corrected prediction. Model: Fable.
The supervisor checks: the file names a cause with evidence (a number, a log line, a diff), not a guess, and ends in one
of the three outcomes; then the supervisor adds the follow-up block to this list under the phase's row.

```bash
cd ~/projects/agent-harness && claude --model claude-fable-5-1 "$(cat <<'EOF'
You are a diagnosis session for the test suite redesign of this repo (agent-harness). CLAUDE.md binds: enter a worktree before writing anything; never touch real runs or real state; no `harness` command but `status`, `report`, `parked`, `sync`; never send a notification. Read-only on every input; the state dir of an ENDED run may be read as findings-and-research/2026-10-29-run-time-budget.md's method does.

The miss: phase [N] ([spec file]) predicted [measure] = [predicted value] (its Predictions table) and the run [run id] measured [measured value] ([findings file], [table or section]).

Read first: the phase's spec and its Predictions table; the findings file with the measured row and the raw files beside it; the run's decision file(s) under journal/decisions/ and `harness report [run id] --md`; docs/plans/2026-11-03-test-suite-redesign.md §4 (the phase's row and the one after it); findings-and-research/2026-11-03-redesign-baseline.md (the baseline the prediction was made against).

Do: (1) check the measurement itself (was the box quiet: the load average and `harness status` the session recorded; the same tree before and after; the same check count or the difference accounted); (2) if the measurement stands, find the cause in the code or the run with evidence (a profile, an exec count, a diff, a log line: run `strace`, `time -v`, the exec-table parser or a subset of the suite yourself, in your worktree, never a real run); (3) write findings-and-research/2026-11-<dd>-[phase]-diagnosis.md: the miss, what you checked, the cause with its evidence, and exactly one outcome: `re-measure` (why the number is not trustworthy and the exact command to repeat), `fix` (a spec section appended in place to the phase's spec under `## Fix after [run id]`, buildable by a fresh session: finding, choice with defaults, checks written first, its own prediction), or `prediction wrong` (the corrected prediction and why the gain is bounded there). Do not build the fix.

Commit on your branch, push, open a PR titled "findings: [phase] diagnosis after [run id]", merge it, delete the branch, remove your worktree. Report: the cause in two sentences, the outcome, and the PR number.
EOF
)"
```
