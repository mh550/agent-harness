# Lanes leftovers: atomic list writes, a record-only main, the finish order, two lint rules, two checks, the suite-ran note

*(2026-10-29, run `agent-harness-2026-10-29-2`, R3-01 to R3-06; spec `docs/specs/2026-10-28-reliability.md` §R3, plan
`docs/plans/2026-10-29-R3-leftovers.md`, review `docs/plans/2026-10-29-R3-review.md`; the P2 review's Minors 6 to 10
and 12, `docs/plans/2026-10-27-P2-review.md`)*

## Atomic list writes

- **Finding:** `lib/features.mjs` wrote `feature_list.json`, `attempts.json` and `parked.json` in place
  (`writeFileSync`). With lanes, a status view, the coordinator and another lane read those files while a lane writes
  them, and a reader between the truncate and the write sees an empty or half file (`JSON.parse` throws).
- **Choice:** one `writeAtomic(p, text)` beside `json`: write `<p>.<pid>.tmp`, then `renameSync` over `p`; every
  write in `main()` (`park`, `unpark`, `bump`, `unbump`, `grant`, `reset`, `repair`, `pass`/`unpass`) goes through it.
  The pid keeps two writers off one temp file. `lib/entries.mjs`'s `writeAtomic` (`<file>.tmp`, under the record
  lock) stays as it is.
- **Rejected:** a lock around every reader: readers are many (status, the scheduler, `jq` by hand) and none should
  wait on a writer; a rename gives them a whole old or a whole new file without one.

## A main moved only in ignored paths merges as verified (the record-only main)

- **Finding:** `merge_one` re-based a verified milestone whenever `main`'s merge with it differed from the verified
  tree at all. A main that moved only in `.harness/runs/` (another run's record PR) or `docs/plans` cost a re-base
  verify round (a full suite and an Opus verify) for a tree the suite's cache would call the same.
- **Choice:** `ignored_only <m> <commit> <tree> <main>` (`lib/record.sh`): when the merged tree and the verified one
  differ only in `.harness/runs` and the `CHECK_KEY_IGNORE` prefixes (the pathspecs `lib/treekey.mjs --pathspec`
  prints, `:(exclude,literal)<p>`, the very ones the key leaves out; an empty, `.`, absolute or `..` entry dropped;
  output that is no such list is a re-base), the milestone goes on to its push and PR with no re-base, noted once per
  main: `<m>: main changed only in ignored paths (<up to 3 paths>); its verify stands`. The invariant, restated: **what lands is byte for byte what was
  verified outside the paths the suite's cache key ignores**; the cache already treats those paths as not the code, so
  a verify of the merged tree would be served the same green. That holds only while the suite reads nothing under
  those paths: a check in `tests/checks/34-check-key.sh` fails on any file under `tests/`, `lib/` or `bin/` that names
  one (`$HERE/../<prefix>`), and `tests/checks/58-needs-record.sh`'s n8n event keys moved from `docs/specs` into
  `tests/fixtures/n8n-event-v1.json` for it (the R3 review's Important 1).
- **Rejected:** dropping the tree test (a main that moved in code must re-base, that is the invariant); a
  glob pathspec (the cache key's prefixes are literal, and a `*` in a config entry would widen what is ignored); a
  separate `MERGE_IGNORE` list, or a second copy of the prefix rules in bash (two definitions that must agree: one
  would drift).

## `finish`: the record PR before the ledger

- **Finding:** `finish` ran `ledger` before `record_pr`, so the ledger's copy of the run record (`cp -r "$REC/."`)
  never held the `record PR` note (P2 Minor 9).
- **Choice:** the order is: the slots removed, summary and report, the notification, the retro, the continuation,
  `record_pr` and its commit, then `ledger`, then `scratch_done` (after `ledger`, which reads the retro's
  `retro-proposals.json` from scratch), then one `HARNESS: ledger notes` record commit for the `backlog:` note.
- **Rejected:** keeping the order and copying the note into the ledger by hand: a second writer of the ledger's
  copy. Cost, accepted: the `backlog:` note (written after `ledger`'s copy, as before) lands on the record branch
  after the record PR merged, so only the record branch has it; gc's `record_only` diffs outside `.harness/runs` only,
  so the extra commit doesn't keep the branch. A hung `gh` or `git fetch` in `record_pr` (no timeout of its own) now
  holds the ledger row back, and a driver killed there loses it (the R3 review's Minor 3, left).

## Lint `unit-collision`

- **Finding:** `lib/lane.sh` names every lane unit from `LANEU=${M//[^A-Za-z0-9_]/_}`, so `M1-x`, `M1.x` and `M1_x`
  are one unit name: two such lanes open at once would share `harness-<run>-<LANEU>-s<n>` scopes and stop each
  other's (P2 Minor 10).
- **Choice:** a step-lint rule (`unitCollisions`, `lib/features.mjs`): milestone ids grouped by the same mapping, one
  finding per id of a group of two or more, on its milestone's first feature, `step -`:
  `<id> shares lane unit name <name> with <the others> (lib/lane.sh LANEU): rename one`. Reported, never applied
  (decisions/2026-10-26-step-lint).
- **Rejected:** a hash or the raw id in the unit name: systemd unit names allow few characters, and a readable
  `harness-<run>-M1_x-s3` is what `harness status` and `harness gc` print; renaming a milestone at lint time is one
  edit, a collision found at run time is two lanes' units.

## Two checks for P2 Minor 12, and no bug

- **Finding:** two behaviours P2 left unchecked: `harness gc --dry-run` naming a leftover slot and a merged lane
  branch without removing them, and two `merge_milestones` of one milestone at once.
- **Choice:** checks only, no code change: `tests/checks/49-lanes-slots.sh` (`would:` lines for the slot and
  `harness-lane/sp/M1`, both still there after, then removed by the real gc) and `tests/checks/77-leftovers.sh` (two
  concurrent `merge_milestones M1` on one state and clone: one `M1 merged into main` note, one `pr merge`). Both were
  green at once: `merge_milestones` holds `flock 8` on `state/merge.lock`, and the second finds `merged-M1`.
- **Rejected:** a second lock inside `merge_one`: the one lock is what keeps the note single (without it the two race
  on the `harness-merge` push), and one is enough.

## `<id>: suite ran <n>x (<s> s) in the session`

- **Finding:** nothing said how often, or how long, a session ran the suite itself; the run-time budget showed the
  suite at 67 % of lane time, the sessions' own runs 58 % (P2 Minor 7; `findings-and-research/2026-10-29-run-time-budget.md`
  on main).
- **Choice:** `lib/check.sh` appends `<epoch.µs>\t<full|subset|cached>\t<s>` to `$HARNESS_SCRATCH/check-runs.log` on
  every exit that ran or answered (a full run's seconds include its rerun; "no suite configured" writes none); the
  lane stamps the time around `session coding` and notes the rows strictly between the stamps that are not `cached`:
  `<id>: suite ran <n>x (<s> s) in the session`, for every coding session (a refused one and an escalated round too).
  The lane's own `run_init` and `green` calls fall outside the stamps.
- **Rejected:** parsing the session's transcript for `$HARNESS_CHECK` calls (a subagent's or a script's calls are
  invisible there, and their time isn't); counting cached answers (they cost nothing, and would hide the real runs).

## Lint `unreproducible`

- **Finding:** steps pinned numbers one run printed (`395 tests`, `< 150 s`, `this run's check.out`): another box,
  another load or one more check turns such a step false while the work holds, and a verify then fails a sound
  feature.
- **Choice:** a per-step rule beside `no-anchor`: a comparison word, a number and a time unit; two digits or more (or
  `N/M`) followed by `tests` or `checks`; `this run's … check*.out`. One finding per step whatever the hits:
  `a number another box or run won't reproduce: cite the command that prints it, or a bound with room (“<match>”)`.
  `prompts/initializer.md` says to state a count as the command that prints it (`tests/run.sh` prints `N/M checks
  passed`) and a time bound as a budget with room. Known reports by design: a file's own count of two digits or more,
  and a bound that has room (`below 5 s`): the rule can't measure room; it is reported, never applied.
- **Rejected:** flagging every number (sizes, caps and timeouts are reproducible); applying the rule (the step's
  author knows whether the bound has room).
