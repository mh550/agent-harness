# The check count and the check budget: every verified milestone says what it added to the suite, against a budget when the spec set one; a note, never a gate

*(2026-11-06, the slim suite's S3 built by hand (`docs/plans/2026-11-05-slim-suite-by-hand.md`, the process session);
spec `docs/specs/2026-11-03-slim-suite.md` S3. Base tree `fd16092` (the shape, PR #117, and the dispatch list's
status). The rules proposed for `CLAUDE.md` are at the end, verbatim as the PR body carries them: Michael's to accept.)*

## Finding

The suite grew from 335 to 1,129 checks in two weeks and stands at 1,492 names after the trim and the shape, and
nothing in a run's record said how many names the run added, replaced or removed. The trim (`2026-11-03-trim`) read
every check and found the repetition small but real: a check whose one assertion is the first term of its neighbour's,
a count asserted once alone and once with its source, parse-only checks of files other checks run, pure functions
asserted through stub runs. Each came from a feature that added its checks beside the old ones, because no step of a
run asked what the feature's checks replaced. The retro had `suite_runs` and `fix_rounds` to judge a run by and no
figure for the suite's growth; a spec had no way to say how many checks a milestone should need.

What the record can tell: this repo keeps every check name in one C-sorted file (`tests/fixtures/check-names.txt`,
which `tests/run.sh`'s conformance check holds to the names the files print), so a milestone's additions, removals and
in-place changes are a diff of that file between the milestone's base and its verified tree. A project without such a
file has only the suite's count.

## Choice

**The count, at the verified verdict.** When a milestone's verify holds (`lib/lane.sh`, `checks_note`), the lane diffs
the fixture at the milestone's base against its tree (`summary.mjs checks-diff`, pure `checksDiff`), writes
`state/checks-<m>` (`{added, replaced, removed, budget}`) and notes `<m>: checks +a ~b −c`. `summary.json` gains
`checks` (the milestones' files summed, `source: "fixture"`, `by_milestone`), `harness report` a `Checks` row after
`Suite runs` (`+2 ~0 −1 (M1 +2 ~0 −1; M2 +0 ~0 −0, budget 3)`, `, over` after a budget exceeded), the retro prompt `{{CHECKS}}` and an Outcome line
`checks: …`. A project without the fixture gets `+<n>` from the test counts (`+2 (the suite's count, 3 → 5)`,
`source: "counts"`); a run with neither `not counted`. The fixture's path is the project config `CHECK_NAMES`, default
`tests/fixtures/check-names.txt` (*default*: the spec named the path and no setting; a project whose names live
elsewhere sets it).

**Replaced.** The spec's `~b` has no definition in a set diff. A removed and an added name in the same hunk of the
sorted file (a run of changed lines between two names both sides hold, or between one and the file's edge) pair as one
replaced; the rest are added and removed. That is what `git diff` of the fixture shows a reader for a name changed in
place (the shape's two changed names were exactly this), and it needs no rule about the names' text. The hunks are
read by position in the files, so an unsorted side pairs where its lines fall; common names in another order on the two
sides pair nothing. The spec's own example, two added and one removed with nothing beside, gives
`{added: 2, replaced: 0, removed: 1}`. (The review checked twelve hand-made pairs against the function, every count
the same; two of its cases, a change at the file's edge and an unsorted tip, are the two sentences above.)

**The base.** The lane's merge-base with main as it merged it, or the tag of a milestone the lane opened from
(`run/<run>/<dep>`) when that is later than the merge-base: a dependency verified but not yet on main. Known limits: a
lane that opened from two dependency tags counts the second one's own names too, and a dependency's tag moved by a
re-base after this lane opened from it is no ancestor of HEAD any more, so the lane falls back to the merge-base and
counts that dependency's names (one dependency, on main before the next verifies, is the usual case; the lane's
starting commit is not recorded). The fixture is read only when `CHECK_NAMES` names a blob on that side: an empty name
(a project opting out) or a directory would make `git show <commit>:<name>` print a tree listing (the review's finding).

**The budget.** The feature list's top-level map `"check_budget": {"<m>": <n>}` (*default*: the spec said "a
milestone's `check_budget` in the feature list" and the list has no milestone objects, so the map sits beside
`features`; `repairList` rebuilds from the initializer's list, so a session's edits never drop it). The planner's spec
may set it, the initializer copies it (`prompts/initializer.md`), `features.mjs budget <list> <m>` reads it (an
integer ≥ 0, else none). With a budget the note reads `<m>: checks +a ~b −c against a budget of <b>`; over it,
`(over budget: <reason>)`, the reason from the `checks` field of the newest coding entry of the milestone's features
(*default*: a new optional string field of a coding entry, validated and kept by `lib/entries.mjs`, named in
`prompts/coding.md`; `entries.mjs checks-reason`, which gives it on one line and at most 200 characters, since the note
quotes it), `none given` without one. A run with no milestone's count (a project without the fixture or with
`CHECK_NAMES=""`, or none verified) has no note: its figure is the suite's count, not a milestone's.

**A note, never a gate** (the spec's default, `decisions/2026-10-26-suite-split`, P0-02 attempt 3): the count is
measured and recorded; nothing is un-passed or held on it.

**Counted at the verified verdict only** (*default*): a milestone that never verifies writes no file; its names never
reach main. A re-base's verify round recounts against the merged main, the same numbers.

**One fixture** (*default*): `tests/fixtures/check-names.txt` alone, never `check-names-fast.txt` beside it (every fast
name is in the full file: the two would count each fast name twice).

**Checks** (`tests/checks/check-budget.sh`, slow, three stub runs): the spec's five, and the suite's temp-file hygiene
(below). Unit tests for `checksDiff`, `checksLine`, `build`'s `checks`, `budgetOf`, the entry's `checks` field and
`checksReason`, each with the CLI's bytes.

**Also in this milestone, by Michael's word at the plan step** (Decisions 18 and 19 of the redesign's dispatch list):
`memlint-run` and `session-gate-driver` are fast-tier files (`2026-11-03-suite-tiers`, its Updated in place line);
`CLAUDE.md`'s *How to verify* describes the runner's per-file line with its tier. And a leak the supervisor found the
same day: the gh stub's `pr merge` left its clone under `/tmp` (88,652 of them since 2026-10-25, 161 GB, 73 million
files, the reason the box's daily cleaner took 40 minutes). `tests/lib.sh` exports `TMPDIR=$T/tmp`, so every `mktemp`
of a stub or of the harness under test goes with the file's throwaway state, and the gh stub and the phone-stop clone
remove theirs; `check-budget` asserts the merges' clones landed there and are gone.

## Rejected

- **A gate on the count** (un-pass, or a hold for Michael, over the budget): a number measured in one run is no
  contract (`decisions/2026-10-26-suite-split`); the spec's default and this file agree.
- **One diff for the whole run at finish**, between the run's base and tip: the record branch carries no code and
  main's diff would hold other runs' merges; per milestone at the verify, summed, is the same figure with a base the
  lane knows.
- **Replaced by the name's `<topic>:` prefix**: two independent checks of one topic, one added and one removed, would
  read as a replacement; the hunk rule reads only what `git diff` shows.
- **Counting at every verify round**: a failed re-check sends the milestone back to coding, which may add more; the
  verified tree is the one whose names reach main.
- **Both fixtures**: double counting (above).
- **A check for the prompt texts** (the initializer's `check_budget` bullet, the coding prompt's `checks` field): prompt
  wording is not a driver behaviour; the retro prompt's line has its stub check because the driver fills it.
- **A lenient `checks` field** (a number or an array kept, or dropped silently): a bad value fails the entry's validation
  as any bad field does, and the coding prompt's `ENTRY_CHECK` catches it before the session ends (the review raised
  the cost; the schema's rule stands).

## Proposed rules for CLAUDE.md

Verbatim, for Michael to accept into *Code rules* or *How to verify* (none is in `CLAUDE.md` now):

- A new behaviour in a pure function gets a unit test in `tests/unit/`, never a stub run.
- A stub run is added only for a driver behaviour no unit test can see, and goes in the check file named for its unit.
- A check that duplicates an existing assertion replaces it: the old name leaves the fixture in the same commit.
- A feature's checks are named for the behaviour, not for the feature id.
- Every retro reports the checks added, replaced and removed (`checks: +a ~b −c`, the record's `Checks` row).
- A spec may give each milestone a check-count budget (`check_budget`); a milestone over it says why in its last coding
  entry's `checks` field, and the verify note carries the reason.
