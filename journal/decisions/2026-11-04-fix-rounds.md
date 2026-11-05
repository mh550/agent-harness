# A red verify opens a fix round, not a card: at most `MAX_FIX_ROUNDS` per milestone, each one counted

*(2026-11-04, F1 M3 by hand: `docs/plans/2026-11-04-f1-by-hand.md`; spec `docs/specs/2026-11-04-run-resilience.md` M3.
Built in Michael's hand session. Reviewed by one clean-context Opus reader of the diff: 0 Critical, 1 Important (item 5,
built), 5 Minor (two fixed, three under *Left as they are*).)*

## Finding

A milestone whose features all pass gets a verify session; when its evidence holds, the full suite runs on the slot's
tree (`verify` in `lib/lane.sh`, after `check.sh`'s rerun guard, so a flake is already green there). A red stopped the
milestone: `needs-<m>`, the note `verify <m>: the suite is red on the verified tree (…); not verified (needs Michael)`,
the `verify_red` card and a notification. Since `decisions/2026-11-03-fast-gate` a feature passes on the fast tier, so a
slow-tier red at the verify is the expected way a milestone's own mistake shows. The harness has the names (the
output's `FAIL <name>` lines, its `HARNESS_FAILED=<files>` line) and the fix is one coding session's work. Michael,
2026-11-04: fix it, measure whether one fix per red clears it, and shape the record so a later triage (F2) can split one
red into several issues.

## Choice

1. **The rule.** In a plain `verify`, `result=red` with `fix-rounds-<m>` under `MAX_FIX_ROUNDS` opens a fix round
   instead of the card: no `needs-<m>`, no needs record, no notification. The driver decides, by this rule; no session
   decides whether to loop.
   - `MAX_FIX_ROUNDS=2` (*default*; `lib/config.sh`, `templates/user/config.sh`). `0` is the behaviour before this
     decision, from the first red.
   - `fix-rounds-<m>` is a state counter kept across `continue`s (*default*): `harness continue` clears `needs-*` and
     `verify-rounds-*` and leaves it, so a milestone whose rounds are used gets the card again at its next red.
   - A suite-red verify that opens a round is no verify round: `verify-rounds-<m>` goes back to what it was (the
     evidence held; the verdict was the suite's). At the cap it stays counted, as before.
   - A flake never opens a round: `green` already reran the red once (`decisions/2026-10-29-rerun-guard`).
   - *Default:* a round opens only in a plain verify. `once` (past the deadline: no session can follow) and `rebase`
     (its caller is no lane loop) keep the card.
2. **The round.** `r = fix-rounds-<m> + 1`. `red_names` reads the red once: the files from the tree's `red-<key>`
   marker when it exists, else the output's last `HARNESS_FAILED=` line; the names from every `FAIL <name>` line of
   `check-<key>.out`. The output's last 200 lines go into the record as `fix/<m>-<r>.out`. `features.mjs fix-add`
   appends the fix feature to the record's list under the record lock:

   ```json
   { "id": "<m>-fix<r>", "milestone": "<m>", "kind": "fix", "issue": "all", "round": 1,
     "after": ["<the milestone's last feature in list order>"], "model": "<WORKER_MODEL>",
     "fix_names": ["<FAIL names>"], "fix_files": ["<HARNESS_FAILED files>"], "fix_out": ".harness/runs/<run>/fix/<m>-<r>.out",
     "description": "fix round <r> of <m>: the full suite is red on the verified tree (<k> failing: <up to 5 names>[ +n])",
     "steps": ["`$HARNESS_CHECK <files>` exits 0 (…)", "`$HARNESS_CHECK --fast` exits 0", "`$HARNESS_CHECK` exits 0 (…)"],
     "passes": false }
   ```

   `issue: "all"`: one issue per red for now; a triage session later writes one fix feature per issue, the same shape.
   The note: `verify <m>: the suite is red on the verified tree (<whose>); fix round <r> of <max>: <m>-fix<r> appended
   (<k> failing: <names>)`. `verify` returns 1 and the lane loop's next pick is the fix feature.
3. **The fix session.** A coding session like any other, in the lane's slot, counted against `MAX_SESSIONS`, with
   `MAX_ATTEMPTS` attempts (given up: the `given_up` card and the run ends blocked, as for any feature). Its prompt has
   one line under *This session* through `{{FIX}}` (`fix_line` in `lib/prompt.sh`; no line for any other feature), and
   `prompts/coding.md` says: fix the cause, never a check's assertion. **Its `passes` gate** is `green_fix`
   (`lib/record.sh`): `check.sh <fix_files>`, then the fast tier; the first red stops it and un-passes the feature,
   `<id> un-passed: <check <files>|fast tier> red after the session`. Its metrics row's `role` is `fix`.
4. **The verify again, and the counting.** The fix passes, the milestone is complete, and `verify` runs as ever: hold
   and green tags `<m> verified and tagged … (after fix round <r>)`; red is item 1 again (round `r + 1` or the card).
   Two rows in `metrics.jsonl`, written by `metrics.mjs fix-round`, no session: `fix_round` at the open (`run`,
   `milestone`, `round`, `issue`, `feature`, `failed_before`, `files_before`, `at`) and `fix_result` at the next
   verify's suite verdict (`failed_after`, `fixed`: nothing failed). `fix-open-<m>` holds the round whose result is not
   written yet, so a row is written once per round: a thin or failed verify has no suite verdict and leaves it open, and
   a `continue` that verifies again at the cap writes nothing. `summary.json` gains `fix_rounds: { opened, fixed,
   by_milestone }`; the report gains `Fix rounds` after `Flakes` (`2 opened · 1 fixed (M1 1 of 1, M2 0 of 1)`, `0`, no
   row for an older summary); `Spend by role` lists `fix`. At the cap the note ends `; not verified (needs Michael)
   after <n> fix rounds (<ids>)` and the `verify_red` card's why names each round and what it left red (the pairing by
   milestone and round is one function, `metrics.mjs fixPairs`, for the summary and the card).
5. **A verifier's un-pass of a fix feature on a red suite is the suite's verdict** (the review's Important finding;
   Michael, 2026-11-05: the driver rule). `prompts/verify.md` has the verifier perform every step as written, and a fix
   feature's last step is the full suite: on a tree a round did not clear, a real verifier un-passes it. Left alone that
   is a failed re-check: another attempt for the fix feature under its old prompt line and a gate that is already green,
   then a `verify_recheck` card, with no round 2, no `fix_result` row and no card naming the rounds. So in `verify`: when
   the features the verifier un-passed are all the milestone's fix features and the suite is red, they pass again
   (noted: `verify <m>: the verifier un-passed <ids> on a red suite; the verdict is the suite's (a fix round or the
   card, no re-check)`), the result is `red`, and item 1 runs on the names failing now. An un-pass of any other feature,
   or with a green suite, is a failed re-check as before.

## Where this differs from the spec's text

- **The stub suite's FAIL lines** are plain `FAIL t1` and `FAIL t3`, not `FAIL t1 (BROKEN-SLOW)`: a real line is
  `FAIL <the check's whole name>` (`tests/lib.sh`), many ending in parentheses, and the driver keeps all of it.
- **fx2's second fix session** changes no code and touches `gate-green-once`, so its gate's subset is green once while
  the tree stays red. As written (a session that does nothing "passes its gate") the subset would be red, or green on
  the rerun too, which would make the third verify a flake.
- **The steps carry the literal `$HARNESS_CHECK`**: an absolute path trips the lint's `outside-repo`. The prompt line
  carries the real path.
- **`fix-add` takes an optional trailing `<model>`** (the spec's CLI could not pass `WORKER_MODEL`) and prints
  `<id>\t<k> failing: …`, so the note and the description have one source for those words.
- **A red with no `HARNESS_FAILED=` line** has `fix_files: []`, rendered `whole suite` (as `flakes.jsonl`'s rows): its
  gate is the full suite and its un-pass note the older `un-passed: suite red after the session`. One with no `FAIL`
  line takes its files as the names; with neither, the one name `whole suite`.
- **The fix rows are no sessions**: `metrics.mjs isSession` keeps them out of `summary.mjs build`'s sessions, costs and
  roles, out of `metrics.mjs summary` and out of `harness show <run> <feature>` (not in the spec's file list).
- **`redUnpass`** (`lib/summary.mjs`) also matches `un-passed: check <files> red`, so such a feature's cause is `red
  suite`.
- **`26-run-13c-stale-green`'s run and `87-fast-gate-run`'s `fs` run** set `MAX_FIX_ROUNDS=0` in `run.env`: they assert
  the card at the first red. `85-suite-runs` reads the `Suite runs` row after `Fix rounds`.
- **No extra snapshot after the append**: `materialize_` snapshots `before.json` before every session, so the fix
  session's copy is judged against the list with the fix in it.
- **A fix feature that cannot be appended** (its id is in the list already) opens no round: the note says so, nothing
  of the round is written, and the card comes as before.
- **`verify-rounds-<m>` is written, then put back** when a round opens, as the spec says. Writing it only when no round
  opens would be simpler, but a lane killed during the suite would then lose the round it spent.

## Left as they are (the review's Minor findings; candidates once the rounds have data)

- **A flaky name can ride along in a round.** The names are the first run's (`FAIL` lines, `red-<key>`'s files), as
  the spec says. A check that failed the first run and passed the rerun, beside one that failed both, is in `fix_names`
  and `fix_files`; a second flake in the gate's subset costs the fix feature an attempt.
- **A timeout or memory-cap red opens a round** with the whole suite as its files. A hang the milestone introduced is a
  fix session's work; a loaded box is not, and the driver cannot tell them apart. `MAX_FIX_ROUNDS` bounds the cost.
- **A round opened just before a session cap or an end time** has no session left in that segment: the run ends with
  the fix feature open and no card. It is an open feature like any other; the continuation runs it.
- **The first round is as exposed as the spec's premise**: a verifier that un-passes the milestone's own features for
  their `the suite is green` step gets a failed re-check, never a red. Item 5 covers fix features only. Whether real
  verifiers do that is for the next runs' data (`grep -c "failed the re-check"` beside `grep -c "fix round"`).

## Rejected

- **The verifier deciding to loop.** The verifier is read-only and the rule is the driver's.
- **Un-passing the milestone's features.** They hold; the suite is the milestone's own.
- **Fixing in the verify session.** A verifier that edits code has checked its own work.
- **Unlimited rounds.** `MAX_FIX_ROUNDS` bounds the spend, with `MAX_SESSIONS`.
- **A triage session now** (F2: one fix feature per issue). After the rounds' data: if `fixed` is under 70 % of
  `opened` over the next runs, or a red's names span unrelated files, F2 is next. `issue` and the two rows are its
  shape; nothing of it is built.
