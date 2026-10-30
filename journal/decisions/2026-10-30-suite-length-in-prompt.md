# The suite's length in every prompt: a green marker's `wall` line, and a timeout rule

*(2026-10-29, run `agent-harness-2026-10-29-3`, S1-02; spec `docs/specs/2026-10-30-suite-time.md` fix 3, plan
`docs/plans/2026-10-30-S1-suite-time.md` §1–§4)*

- **Finding:** the *This run* Suite line said nothing about how long the suite takes, and `CLAUDE.md` said `~3 min 30 s
  … 208 s measured`, a number from 2026-10-26 at 392 checks; the suite is 601 s alone and 857 s paired at 859–925
  checks. The Bash tool's default and foreground maximum are 600 s: in 10-29-2 R1-01's full run was killed at 602 s
  and run again (1,180 s lost), and four more full runs (10-29, 10-29-2) were moved to the background at 601 s and
  polled. `check.sh` measured every full run and threw the number away.
- **Choice:**
  - `lib/check.sh` writes a green tree's marker as two lines: `<n> tests` (or empty), then `wall <s>`, the first
    run's seconds (a rerun of named files is a subset's length; a whole-suite rerun's, below). Every reader takes line 1 with `read -r`
    (`check.sh`'s cached line, `run_init`'s `tests-start`, `tests_end`): `$(cat)` of an empty line 1 is `\nwall 0`,
    which skipped the testcount fallback and wrote `\nwall` into `tests-start`. A one-line marker (an older harness's)
    reads as before.
  - `lib/prompt.sh`'s `suite_length`, run by `prompt_render` for every template that renders `parts/run.md`, gives
    `HARNESS_SUITE_LENGTH`: the `wall` of the cwd tree's `green-<key>`, else of the newest green marker that has
    one (`ls -t`), then the same of the `red-<key>` markers, as `<s> s: give a full run a timeout of at least twice that`; with
    none, `not measured yet; bounded by CHECK_TIMEOUT <the run's>: give a full run a timeout above that`. Each
    template's *This session* block (coding, initializer, verify, resolve) has `Suite: last full run
    {{SUITE_LENGTH}}`, and the *This run* Suite line ends `cached per code tree; its last full run is under *This
    session*)`.
  - *default, against the spec and S1-02 step 4:* the wall is under `# This session`, not in `parts/run.md`'s Suite
    line. The wall differs from session to session (each full run measures a new one), and everything above
    `# This session` is the run's shared prefix (decisions/2026-10-21-static-first-prompts and its E3-05 amendment;
    the 08/13/14/15 checks compare two sessions' prompts through that heading). With it in `parts/run.md`, 08's
    prefix check went red whenever two stub sessions' walls were 0 s and 1 s, and every real run's prompts would
    have differed from the Suite line on.
  - After a whole-suite rerun (a red that named no files) the wall is the rerun's: a red with no names may have
    stopped early, and a short wall would give the next full run a short timeout. A rerun of named files is a
    subset, so then the wall stays the first run's.
  - `prompts/coding.md`'s *The suite* rule: give every full run a timeout of at least twice its last wall; over the
    tool's 10-minute foreground limit, in the background with that timeout, its output to scratch, waiting for its end
    notification: never polled, never without a timeout. `CLAUDE.md`'s suite line points at the run's prompt.
  - *default:* the wall goes in the marker, not a sidecar file: the marker outlives scratch, and the prompt is its one
    new reader.
  - *default:* the rule's background clause (twice the wall is over the foreground limit on this box).
  - *default:* `CLAUDE.md`'s line says `10–11 min on this box on 2026-10-29` without the brief's `at 925 checks`
    (memlint's `derivable-count` rule).
  - *default:* the scan reads `red-*` markers only when no green one has a wall: a red may have stopped early (a
    compile error, a fail-fast runner, a red whole-suite rerun), and its 2 s would advise the retry a 4 s timeout.
  - *default:* `suite_length` runs only for the templates that render `parts/run.md` (`entry-resume` and `retro` pay
    no treekey).
  - *default:* the `not measured yet` phrase names the run's own `CHECK_TIMEOUT` (`15m` by default, `25m` here).
- **Rejected:**
  - **The wall in the cached line** (`check: green (cached …, N tests, M s)`): every init output would carry it, and
    the checks that match that line byte for byte would all change.
  - **A fixed number in `CLAUDE.md`:** the last one was wrong within three days.
  - **The wall in `parts/run.md`'s Suite line** (the spec's placement): it splits the prompts' shared prefix above
    `# This session`, as above.
  - **Reading `tests/run.sh`'s own `wall … s` line:** that is this suite's output alone; `check.sh` times any
    project's suite.

Updated in place 2026-10-30 (S1-05 review, I3): every green marker's wall before any red's; the cwd tree's red used to
come second, so a retry's prompt showed the early-stopping red run's seconds.
