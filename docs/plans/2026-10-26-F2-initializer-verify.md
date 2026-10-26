# F2 · Initializer and verify behaviour: R3, R2, R10 change 2, R5 (plan, 2026-10-26)

Run `agent-harness-2026-10-26-2`, feature F2-01. Spec: `docs/specs/2026-10-21-retro-fixes.md` § F2 and R10 change 2.
Brief: F1 and F2 only, build on `main` as it stands, proceed on defaults, never park.

Checked against `main` at `9c1acfc` (F1 merged; this branch's base). `tests/checks/` does **not** exist here: the
suite split is unmerged. Every new check goes in `tests/run.sh` under the `# ---- <title> ----` section named below;
a new topic gets a new marker line, so the split script makes it a file later. If `tests/checks/` exists when a build
session starts (main merged in), the check goes in the file of that topic, under the same title.

One feature per item, in this order: F2-02 (R3, the pure lint), F2-03 (lint wiring + R10 change 2), F2-04 (R2, two
more lint rules + the prompt), F2-05 (R5), F2-06 (review). Each check is written first and watched failing.

## What main already has

- **`undeclared(list)`** (`lib/features.mjs:55-60`, CLI `undeclared` at `:142`): milestones after the first whose
  first feature has no `after`. The driver notes it once per run (`lib/driver.sh:653-657`, marker
  `$STATE/deps-noted`): `dependencies: M2 has no after list, so it waits on every earlier feature (…)`; run 1's check
  `a milestone without an after list is noted` (`tests/run.sh:621`) greps it. The lint reuses `undeclared()`; the
  note stays as it is.
- **`kindOf(f)`** (`lib/features.mjs:86-94`): explicit `kind`, else inferred. R2's rules count kinds with it.
- **No lint, no `{{LINT}}`.** `features.mjs` has no `lint` command (`default:` usage line at `:230`); the initializer
  block (`lib/driver.sh:635-651`, the note and commit at `:649`) notes `feature list written: <summary>` and commits `HARNESS: initializer done`.
- **The initializer's `after` rule** (`prompts/initializer.md:38-46`) asks for `after` on the first feature of every
  milestone *after the first* and says "inside a milestone, leave `after` off unless a feature is independent".
  Item 4 of the milestone pattern (`:59-62`) always asks for a closing review + simplify feature.
- **Prompt variables**: `lib/render.mjs` fills `{{NAME}}` from `HARNESS_NAME` (empty if unset). `prompt_env`
  (`lib/prompt.sh:45-53`) exports what every template sees; the driver and `lib/prompt.sh` (run as a command, for
  `harness eval probes`) both call it. Above `{{SECTIONS}}` is the shared static prefix
  (decisions/2026-10-21-static-first-prompts): nothing run-specific may go there.
- **Deadline branches** (`lib/driver.sh:660-677`): the loop's top checks the session cap, then
  `(( now >= DEADLINE )) && { note "deadline reached"; finish "deadline"; }` (`:662`); the pause wait has
  `note "deadline reached while paused"; finish "deadline (paused)"` (`:670`); after `limit_wait`, a passed deadline
  `continue`s to the top (`:677`). `verify_ready` (`:469-478`) runs only after those, so a milestone that completes in
  the last session before the deadline (or the session cap) is never verified in that segment.
- **`verify()`** (`lib/driver.sh:397-466`) runs up to two sessions per call (`VERIFY_MODEL`, then
  `VERIFY_ESCALATE_MODEL` when the evidence is thin) and, on a failed step with `rounds < MAX_VERIFY_ROUNDS`, grants
  the feature one more attempt (`:453-454`) — which a run at its deadline can't use.
- **`summary.mjs`'s roles** (`lib/summary.mjs:235`): `init plan build review check docs verify retro`, each listed in
  `Spend by role` when it has a cost. Unchanged by R2.

## R3 · Step lint (F2-02, pure)

**Files.** `lib/features.mjs` (export `lint(list)`, `lintNote(findings)`, `RULES`; CLI `lint <list> [--note]`;
usage header + `default:` line), `tests/run.sh`, `journal/decisions/2026-10-26-step-lint.md`, `docs/architecture.md`
§6.

**Output.** `lint(list)` returns `[{ id, step, rule, text }]`; `step` is the 1-based step number, or `"-"` for a
feature- or milestone-level rule. The CLI prints one line per finding, `<id>\tstep <n>\t<rule>\t<text>` (`step -`
for the level rules), and exits **1** with findings, **0** clean (no output). Order: features in list order; within
a feature, its steps in order (per step: no-anchor, outside-repo, self-match), then its level rules (undeclared,
review-small, review-missing). `RULES` is that rule order, also used for the note's counts.

**Rules.** Each takes the step's text as written in the list.

1. **`no-anchor`**: a step with nothing concrete to check. It has an anchor if any of these match:
   a digit `\d`; a backtick span `` `[^`]+` ``; a double-quoted string `"[^"]+"` or `“[^”]+”`; a single-quoted
   string bounded by non-word characters `(^|\W)'[^']+'(\W|$)` (so `doesn't … isn't` is not a quote); a path
   `[\w.~-]*\/[\w.-]+` (also routes like `/api/x`); a file name `\b[\w-]{2,}\.[A-Za-z0-9]{1,6}\b` (`e.g.` and `i.e.`
   don't match: one-letter stem). **Exempt**: a step matching `/^the suite is green\b/i` (the initializer prompt's
   required last step).
   Trips: `works correctly`, `x`, `the page looks right`. Passes: `the suite is green`, `curl :7814/x returns 200`
   (digit, path), `` `harness queue list` prints (requested) ``, `README.md mentions it`.
2. **`outside-repo`**: a step naming a path a session can't or mustn't use: a `~` path `(^|[\s`"'(=])~(\/|\s|$)`,
   `$HOME` / `${HOME}`, a parent escape `(^|[\s`"'(=])\.\.\/`, or an absolute path under a system root
   `(^|[\s`"'(=:])\/(home|root|srv|etc|var|opt|usr|mnt|media)\/`. Other absolute paths pass: `/tmp/…` (the scratch
   directory), `/dev/null`, and web routes (`GET /api/x`), which a "starts with /" rule would trip.
   Trips: `read ~/projects/x/.harness/runs/…`, `/home/mh550/…`, `cat ../other/x`. Passes: `lib/driver.sh`,
   `/tmp/harness/…`, `> /dev/null`, `GET /api/health returns 200`.
3. **`self-match`**: a grep-shaped step whose pattern also matches the step's own text in the run record (the C7-05
   park: the step was quoted into progress.md, so its grep matched itself and could never fail). Shape: the step has
   `\b(grep|rg)\b`; the pattern is the `-e` argument, else the first argument after the options (quoted `"…"`/`'…'`,
   or a bare word); the targets are the arguments after it. It trips when **a target is a run-record file that quotes
   steps** — a path containing `.harness/runs/`, or a bare `progress.md`, `progress-archive.md`, `entries.jsonl`,
   `context.md` or `feature_list.json` — **and** the pattern matches the step's own text. `harness-log.md` is not one
   of them: only the driver writes it and it never quotes a step. Matching: `-F` → substring; `-E`/`-P` → a JS
   RegExp; otherwise (BRE) the pattern with `+ ? | ( ) { }` escaped, then a RegExp; `-i` → the `i` flag; an invalid
   RegExp → substring. Trips: `grep -q "M2 verified" .harness/runs/<run>/progress.md`. Passes:
   `grep -c '^verify M1' .harness/runs/<run>/harness-log.md` (not a quoting file, and `^` doesn't match mid-text),
   `grep -q "M1 verified" .harness/runs/<run>/harness-log.md`, `grep -rn "note" lib/`.
4. **`undeclared`**: one finding per milestone `undeclared(list)` returns, on that milestone's first feature,
   `step -`, text `<m>'s first feature has no "after": it waits on every earlier feature`. The first milestone is
   exempt, as in `undeclared()` and the driver's note (its first feature has nothing earlier to wait on).

**Checks** (`# ---- step lint, pure (R3, R2): features.mjs lint, one tripping and one passing step per rule ----`, a
new section right after `# ---- test counts, pure (R1) …` in `tests/run.sh`; `node --input-type=module -e` importing
`lint` as the scheduler section does, comparing lengths and joined rule names, never `deepEqual`):

- `lint: no-anchor trips "works correctly", not "the suite is green" or "curl :7814/x returns 200"`
- `lint: outside-repo trips ~ and /home/ paths, not lib/driver.sh or /tmp/harness/`
- `lint: self-match trips a grep of progress.md for the step's own words, not of harness-log.md or lib/`
- `lint: undeclared trips a later milestone's first feature without after, not the first milestone's`
- `lint: the CLI prints <id> step <n> <rule> <text> lines, exit 1 with findings and 0 clean` (a temp list in `$T`)

Written first: each fails on main's `features.mjs` (the import has no `lint`; the CLI prints the usage line with
exit 2, which the step calls `features.mjs: unknown command`, since `default:` is the unknown-command branch).

**This run's own list** (F2-02 step 4) is expected to report findings: F2-02's step 2 quotes the outside-repo
examples (`~/projects/x/…`, `/home/mh550/…`), and steps that quote grep examples over `progress.md` may trip
self-match. The entry records the count and the rules; nothing is edited (the list is the harness's to keep).

## R10 change 2 · The `after` sentence (F2-03)

`prompts/initializer.md:38-46` becomes (the bullet under **`after`**; the sub-bullets go):

> - **`after`** lists what a feature really needs: feature ids, or milestone ids (every feature of that milestone).
>   Without it, a feature waits on **every** feature before it, so one failure, or one feature waiting on Michael,
>   stops everything behind it. Give `after` on any feature that doesn't need its predecessor in the same milestone,
>   and on every milestone's first feature (`[]` when independent): e.g. `"after": ["N1"]`, or `"after": []`. The
>   harness notes every milestone after the first that lacks it, and the lint flags it. On 2026-10-17 one feature
>   waiting on Michael held back four whole milestones that didn't need it.

The check greps the fixed sentence `` `after` on any feature that doesn't need its predecessor in the same milestone,
and on every milestone's first feature (`[]` when independent) `` — one line in the rendered prompt, so the build
session keeps it on one line of the template (wrap before "Give" and after "independent)").

## Lint wiring (F2-03)

**Files.** `lib/prompt.sh` (`prompt_env`), `prompts/initializer.md`, `lib/driver.sh` (the initializer block),
`tests/run.sh` (run 1), `docs/architecture.md` §5 and §6, `README.md`.

- **The prompt variable.** `prompt_env` exports `HARNESS_LINT="node $HARNESS_HOME/lib/features.mjs lint"`: the live
  harness's path, the same for every run, so it may sit in the static part above `{{SECTIONS}}`. The run directory
  stays out of it (that would put a run-specific value in the shared prefix).
- **The prompt line**, in `prompts/initializer.md` just before "Commit `HARNESS: feature list …`":
  > Before you commit, run `{{LINT}} <run directory>/feature_list.json` and fix every line it prints (`<id> step <n>
  > <rule> <text>`: a step with no concrete anchor, a path outside the repo or in `~`, a grep that matches its own
  > words in the run record, a milestone without `after`, a review the milestone's size doesn't call for). No output
  > means clean.
  (the last item lands with F2-04; F2-03 writes the line without it, F2-04 adds it).
- **The driver**, in the initializer block (`lib/driver.sh:649`), right after `note "feature list written: …"` and
  before `commit_all "HARNESS: initializer done"`: `note "$(F lint "$LIST" --note)"`, once per run (the block runs
  only when there was no list). `--note` prints the note body and exits 0:
  `lint: <n> findings (<rule>: <count>, …); the list is not edited — first: <id> step <n> <rule>` (rules in `RULES`
  order, only those with a count), or `lint: clean`. The driver never writes the list. A run whose list predates
  this (a resumed run) gets no lint note.
- **The stub's list** (`tests/stub-claude.sh:59-63`): A steps `x`, `y`; B `y`; C `z`; C has no `after` (unless
  `STUB_INDEPENDENT_M2`). So run 1's note is exactly
  `lint: 5 findings (no-anchor: 4, undeclared: 1); the list is not edited — first: A step 1 no-anchor`
  (M1 has two build features and no review; M2 one: no R2 finding).

**Checks**, all in `# ---- run 1: misbehaving sessions, two milestones; …` (`tests/run.sh:548`), beside
`a milestone without an after list is noted` (`:621`):

- `the initializer prompt has the resolved lint command`: `grep -qF "node $(cd "$HERE/.." && pwd)/lib/features.mjs lint" "$HARNESS_STATE/proj/demo/prompt-initializer.md"` (`HARNESS_HOME` is `cd … && pwd`, `bin/harness:59`).
- `the initializer prompt asks for after on independent features and on every milestone's first` (`grep -qF` of the
  sentence above in the same file).
- `the driver notes the lint once after the initializer`: `hlog demo` has exactly one `lint:` line, it ends with the
  note above, and `dependencies: M2 has no after list` still appears.
- `the driver never edits the list: the initializer's feature_list.json is byte for byte the stub's`: in
  `$T/origin.git`, the list at the commit `HARNESS: feature list` (the stub's, `stub-claude.sh:67`) `cmp`s equal to
  the list at `HARNESS: initializer done` on `harness/demo` (found with `git log --format=%H --grep=… -1`).
- pure, in the step-lint section: `lint: the note counts by rule and names the first finding; clean says clean`
  (`lintNote` on a two-rule finding list and on `[]`).

## R2 · Reviews sized to the milestone (F2-04)

**Prompt** (`prompts/initializer.md` milestone pattern, item 4 becomes):

> 4. the review, sized to the milestone. A milestone with one or two build features folds its review into the last
>    build feature's steps (`an Opus subagent reviews the diff; Critical/Important findings fixed`) instead of a
>    separate review feature. A milestone of three or more build features keeps one closing **review + simplify**
>    feature: an Opus reviewer reads the milestone diff from a file, one round by default and a second only when the
>    first found something Critical; Critical/Important findings are fixed RED→GREEN; simplification passes are
>    applied; docs touched by the milestone are updated.

and the lint line gains "a review the milestone's size doesn't call for".

**Lint rules** (in `lint()`, milestone-level, `step -`; build and review counted with `kindOf`; features with no
milestone are skipped):

5. **`review-small`**: a milestone with one or two `build` features and a `review` feature: one finding on each
   review feature, text `<m> has <n> build feature(s): fold the review into <last build id>'s steps`.
6. **`review-missing`**: a milestone with three or more `build` features and no `review` feature: one finding on the
   milestone's last feature, text `<m> has <n> build features and no review feature`.

A milestone of plan/docs/check features only gets neither.

**Checks**: pure (step-lint section) `lint: review-small for a review in a two-build milestone; review-missing for
five builds without one; neither for five with one or docs only`; run 1: `the initializer prompt sizes reviews to the
milestone` (`grep -q "folds its review"` in `prompt-initializer.md`); `Spend by role` keeps `review`: the existing
`harness report prints the writeup` (`:618`) still passes, plus `the report lists the review role when a review ran`
(the demo has no review feature, so this one feeds summary.mjs a summary with `cost.by_role.review` set, through its
exported renderer if it has one, else greps `"review"` in the roles line `lib/summary.mjs:235`). **The spec's own
check** ("a stub spec with a two-feature milestone yields no review feature") can't be made with the stub
initializer, which writes a fixed list: the lint rules and the prompt grep stand in for it (the decision file says so).

This run's own list: F1 and F2 each have four build features and one review → no `review-small`/`review-missing`.

## R5 · Verify before the deadline ends a run (F2-05)

**Files.** `lib/driver.sh` (`verify`, `verify_ready`, the two deadline branches), `tests/run.sh`,
`journal/decisions/2026-10-26-verify-before-deadline.md`, `docs/architecture.md` §5 and §7, `README.md`.

- **`verify <m> [once]`**: `once` means one session and no second chance. `models=("$VERIFY_MODEL")` only (no
  escalation), and the round limit is this round (`local maxr=$MAX_VERIFY_ROUNDS; [[ ${2:-} == once ]] &&
  maxr=$rounds`), used in the clock (`verify round $rounds of $maxr`) and in the fail branch: `rounds < maxr` is
  false, so a failed step is `verify <m>: <id> failed the re-check in round <r> of <r>; <m> needs Michael (see
  progress.md)` and `needs-<m>`, never an attempt granted that no session would use. The thin branch notes
  `verify <m>: evidence still short of the steps (<short>) after one verify at the deadline; not verified (needs
  Michael)` (the `after $VERIFY_ESCALATE_MODEL` wording stays for the normal path). Bounded by `SESSION_TIMEOUT`
  through `session()` as every verify is. A limit-refused verify returns 2 as today (`verify <m> refused …;
  deferred …`); the deadline path doesn't wait, it finishes.
- **`verify_ready [once]`** passes `once` on, and before each verify in `once` mode notes
  `deadline reached: <m> complete but unverified; one verify before the end`. Same filter as today: complete, not
  `verified-<m>`, not `needs-<m>`.
- **The branches** (`:662` and `:670`): `note "deadline reached"` (unchanged: the tmux checks grep it), then
  `verify_ready once`, then `finish "deadline"` / `finish "deadline (paused)"`. A verify that holds merges through
  `merge_milestones` as today (`M1 merged into main · <url>`). The `:677` branch already goes to `:662`.
  The paused branch verifies too, as F2-05 step 1 says (a pause stops new feature work; this one session makes work
  already done mergeable) — a default, asked of Michael in the entry.
- **One per milestone, once per segment**: the branch runs `verify_ready once` once and `finish` exits the driver.

**Deterministic scenario** (a new section `# ---- run 9e: the deadline verifies a complete milestone once (R5) ----`
after run 9c, `tests/run.sh:1002-1007`; runs `dlok`, `dlstrict`, `dlthin`): for each,
`mkdir -p "$HARNESS_STATE/proj/<r>" && echo MAX_SESSIONS=2 > "$HARNESS_STATE/proj/<r>/run.env"` (run.env outlasts
start, as the `capped` check does at `:1086`), then
`STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_LENIENT=1 "$H" start "$T/proj" <r> --spec SPEC.md --foreground`: sessions A and B
pass, the loop's top ends `session cap (2)` before `verify_ready`, so M1 is complete with no `run/<r>/M1` tag. Then
`"$H" continue <r> --until-epoch $(( $(date +%s) - 1 )) --foreground` (no `--keep-attempts`: `needs-*` and
`verify-rounds-*` are cleared, so the round is 1) with:

- `dlok`: `STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_LENIENT=1`. Check `the deadline verifies a complete milestone once
  and merges it`: `hlog` has `deadline reached: M1 complete but unverified; one verify before the end`,
  `M1 verified and tagged run/dlok/M1`, `M1 merged into main`; `on_main run/dlok/M1`; `ended` starts `deadline`;
  `grep -c '^verify M1' "$T/scratch/proj/dlok/sessions.log"` is 1 (`KEEP_SCRATCH=1` in the base config keeps it).
- `dlstrict`: `STUB_STRICT_VERIFIER=1 STUB_NO_TAMPER=1 STUB_NO_RED=1` (no `STUB_LENIENT`, which overrides strict at
  `stub-claude.sh:139`). Check `a failed verify at the deadline is not retried: M1 needs Michael`: `verify M1: A failed
  the re-check in round 1 of 1; M1 needs Michael`, `ended` starts `deadline`, one `^verify M1` line, no tag.
- `dlthin`: `STUB_THIN_VERIFY=1 STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_LENIENT=1`. Check `thin evidence at the deadline is
  not escalated: one verify, M1 not verified`: one `^verify M1` line, `hlog` has `after one verify at the deadline;
  not verified`, no tag.

The section ends with `rm -f "$HARNESS_STATE"/queue/*-continue-dl*.args`: the first segments' session caps queue
automatic continuations (`lib/driver.sh:543`), which the queue section must not find.

**Existing deadline checks unchanged** (F2-05 step 4): run 9c's `a later deadline …` (nothing passes), the scrub run
(`:1590`, initializer then deadline), `nocount` (`:1601`) and the tmux runs (`:1645-1658`) have no complete
milestone, so `verify_ready once` does nothing and their logs and end reasons are as before.

Written first: `dlok`'s check fails on main (no note, no tag: the deadline finishes before `verify_ready`); `dlstrict`
and `dlthin` fail on main for the same reason, and on a version without `once` with `round 1 of 2` / two verify
lines.

## Decision files and docs

| Feature | Decision file | Docs |
|---|---|---|
| F2-02 | `journal/decisions/2026-10-26-step-lint.md` (finding: the C7-05 park, a grep that matched its own quoted step; the measure run's E2-02, a step that needed `~/projects/*/.harness/runs`; choice: the four rules above, the driver notes and never edits; rejected: the driver fixing or rejecting the list, an LLM judging steps, linting descriptions) | `docs/architecture.md` §6 lists the rules |
| F2-03 | (same file, wiring paragraph) | §5: `[no list] … INITIALIZER (runs the lint, fixes it) ─► lint note ─► …`; §6: the initializer runs the lint before committing; README one line |
| F2-04 | `journal/decisions/2026-10-26-reviews-sized-to-milestone.md` (finding: review cost up to 24 % of a run, the six runs the spec cites; choice; rejected: no reviews for small milestones, a reviewer per feature, the spec's stub-initializer check) | §6 the rule; README one line |
| F2-05 | `journal/decisions/2026-10-26-verify-before-deadline.md` (finding: voice-concierge-2026-10-20, twice; choice: one session, no escalation, no granted attempt; rejected: `MAX_VERIFY_ROUNDS` at the deadline (unbounded overrun of `--until`), extending the deadline, verifying at the session cap) | §5 (the deadline line), §7 Verify row, README § Steering "After a partial run" |

## Defaults taken (Michael may change them)

- **D1 *default*** (outside-repo): absolute paths trip only under `/home /root /srv /etc /var /opt /usr /mnt /media`,
  plus `~`, `$HOME` and `../`; other absolute paths (routes, `/tmp`, `/dev/null`) pass.
- **D2 *default*** (self-match): `harness-log.md` is not a quoting file; only files sessions or the renderer write
  step text into count.
- **D3 *default*** (R5): the paused deadline branch also runs the one verify, as F2-05 step 1 says.
- **D4 *default*** (undeclared): the first milestone's first feature is not flagged, though the new `after` sentence
  asks for `[]` there too: the lint matches the driver's existing note.

## Review (F2-06)

One Opus round over `git diff origin/main...HEAD -- lib bin prompts tests docs README.md journal/decisions` (904
lines: F2 alone; the local `main` ref was behind origin, so `main...HEAD` would have repeated F1). No Critical, so no
second round.

- **Important** · `lib/driver.sh:668,676` · the deadline verify ran before `control()`, so a STOP or `status: stop`
  got one more (verify) session and its services back up. **Fixed**: `deadline_verify` notes `…; stopped by Michael,
  so no verify before the end`. Check `a stop at the deadline comes first: no verify, M1 left for a continue` (red
  before: one verify session ran).
- **Minor** · `lib/driver.sh:668` · a usage-limit window at the deadline started a verify only to be refused, leaving a
  `deferred until` note nothing acts on. **Fixed** in the same helper (`…; the usage limit holds until HH:MM, so no
  verify before the end`). Check `a usage-limit window at the deadline: no verify session to be refused, …` (red
  before).
- **Minor** · `lib/features.mjs:81` · `outside-repo` trips routes and live paths under the system roots (`GET
  /media/hero.jpg`, `/srv/n8n/live.lock`). **Documented, not changed**: architecture §6 and the step-lint decision now
  say so, and the initializer prompt lets a step that is right as written stay; an exemption for routes would need a
  route grammar the lint doesn't have.
- **Minor** · `lib/features.mjs:92-111` · `selfMatch` misread a backtick right after `rg`, a glued `progress.md|wc`,
  and `--regexp=M2`. **Fixed**: bare words stop at `| ; &` and backticks, `--regexp=` is read. Check `lint: self-match
  ends the command at a closing backtick or a glued |, and reads --regexp=` (red before). Not fixed: `grep -T` (GNU's
  takes no value, rg's `-T` does; the lint keeps rg's reading).
- **Minor** · `tests/run.sh` · the paused deadline branch had no check. **Added** `a deadline while paused verifies a
  complete milestone once too` (green from the start: coverage, not a fix).
- **Minor** · `tests/run.sh:664` · `the report lists the review role when a review ran` can't fail from an R2 change.
  **Kept**: it pins the role reports read for folded reviews; R2's behaviour is covered by the review-small /
  review-missing checks.
- **Minor** · `docs/architecture.md:461` · "the real quality gate is still the milestone's review feature". **Fixed**:
  the review feature or the last build feature's review steps.
- **Simplify** · `lib/driver.sh:401` · `${2:-} == once` tested three times in `verify()`. **Applied**: `models` and
  `last` are set once; the thin break is `$model == ${models[-1]}`, the note `after $last`.
