# M6 · The milestone review, measured and gated (plan, 2026-10-26)

Run `agent-harness-2026-10-25-memory`, feature M6-01. Spec: `docs/specs/2026-10-25-memory.md` § M6, which is
`docs/specs/2026-10-22-retro-followups.md` § D as written (after R2, droppable). Brief: test-first, a decision file per
behaviour change, never park, never run evals (write `evals/NEXT.md`).

Checked against this branch at `d016fcb` (M5 verified; `main` at `32dccef`). R2
(`decisions/2026-10-26-reviews-sized-to-milestone`) is on main, so M6 keeps its base. New checks go in
`tests/checks/41-run-19-review-gate-m6.sh` (new), each name also one line of `tests/fixtures/check-names.txt`
(`LC_ALL=C sort -u` order). Each check is written first and watched failing.

One feature per item, in this order: M6-02 (measure and route), M6-03 (escalate), M6-04 (summary, ledger, evals),
M6-05 (review).

## What the branch already has

- **The coding loop** (`lib/driver.sh:762-826`): `next=$(F next …)`, then `IFS=$'\t' read -r id mdl milestone <<< "$next"`
  (`:774`; `mdl` is the feature's own model as a full id), the memory gate (`:777`, which may `continue` and pick
  again), `F bump "$ATT" "$id"; F snapshot` (`:779`), `run_init; context "$id"`, `HARNESS_CLOCK=$(clock "attempt N of
  M") … prompt coding` (`:781`), `session coding "$mdl" "$slog" "$id"` (`:786`), `journal coding …` (`:788`). The limit
  branch gives the attempt back with `F unbump` (`:794`); the park branch too (`:822`). `MET append … "$mdl" …
  "$(F kind "$LIST" "$id")"` (`:819`) writes the metrics row with the model and the kind; summary.mjs turns a coding
  row's kind into its role, so a `review` feature's sessions are `by_role.review`.
- **Verify's escalation** (`verify()`, `:418-470`): a `models=("$VERIFY_MODEL" "$VERIFY_ESCALATE_MODEL")` array, one
  round per model, note `verify <m>: evidence short of the steps (…); re-running on <model>`. summary.mjs counts
  `re-running on` as `guards.verify_escalations`, so the review's note must not contain that phrase.
- **`clock()`** (`:208-213`) prints `Clock: … · <arg>`; the coding prompt's `{{CLOCK}}` is that line.
- **The prompt** (`prompts/coding.md:112-116`): `# This session`, `Feature:`, `Milestone:`, `{{CLOCK}}`. `lib/render.mjs`
  fills `{{NAME}}` from env `HARNESS_NAME`, empty when unset; `prompt_render` (`lib/prompt.sh:56-79`) needs no change.
  `session()` copies each prompt beside its transcript as `logs/NN-<id>.prompt.md` (`:223`).
- **Config** (`lib/config.sh:24`): `VERIFY_MODEL=sonnet VERIFY_ESCALATE_MODEL=opus` on one defaults line;
  `MAIN_BRANCH=main` (`:26`). `F model <alias>` gives the full id.
- **R2** (`lib/features.mjs:73-76, 129-140`): lint `review-small` (a review in a milestone of 1–2 build features) and
  `review-missing` (3+ builds, no review). M6 doesn't touch them: a review feature exists only in a milestone of three
  or more build features, so every review the gate sees is one R2 kept.
- **summary.mjs**: `build()` (`:72`) reads the list, metrics.jsonl, harness-log.md and the state; not entries.jsonl.
  `cost.by_role` (`:149`), `rework` (`:164`: a feature with more than one real coding row is rework),
  `guards.verify_escalations` (`/re-running on/g`), `report()` Spend rows (`:235-247`), `ledger-line` (`:265-280`).
- **lib/entries.mjs** is guarded (`:380`), so summary.mjs may import a pure function from it.
- **The stub** (`tests/stub-claude.sh`): the initializer writes A, B (M1) and C (M2, opus); B's first session tampers
  with C, C's first leaves BROKEN; a coding entry's summary is `<id>: stub work (<n>)`; verify M1 round 1 un-passes A
  unless `STUB_LENIENT=1`. `ok <cost>` gives the session's cost (default 0.25).
- **evals/NEXT.md** has sections 1–4; the commands take a git ref (`--harness run/<run>/<m>`). This run's tags
  `run/agent-harness-2026-10-25-memory/M1` … `/M5` exist; `/M5` is the last tree before M6.

## How the diff is measured

```bash
git diff --shortstat "origin/$MAIN_BRANCH...HEAD" -- . ':!.harness/runs'
# " 3 files changed, 12 insertions(+), 4 deletions(-)" → files 3, changed lines 12 + 4 = 16
```

Three dots: from the merge base with main, so a milestone already merged (its PR's merge commit has the branch commit
as parent) drops out, and only work main doesn't have counts. `.harness/runs` (the journal, the list, the logs) is
left out. A pure-ish helper in the driver, `review_diff` → `<files> <lines>`, parses the line with awk (`N files`,
then the numbers before `insertion` and `deletion`; an empty diff is `0 0`). `origin/$MAIN_BRANCH` is the ref `sync`
and `sync_main` last fetched: stale only toward a larger diff (the safe side, Opus). If the git command fails (no
such ref) the review runs on Opus and the note says `review <id>: diff not measured (<why>); opus`.

## Where the model is chosen

In the loop, after `IFS=$'\t' read -r id mdl milestone` and after the memory gate's line (`:777`, so a gate wait doesn't
note twice), before `F bump`: when `F kind "$LIST" "$id"` is `review` and this isn't an escalation round,

```bash
read -r rfiles rlines < <(review_diff)
if (( rlines < REVIEW_OPUS_LINES )); then mdl=$(F model sonnet); rside="under $REVIEW_OPUS_LINES; sonnet"
else mdl=$(F model opus); rside="at or over $REVIEW_OPUS_LINES; opus"; fi
note "review $id: $rlines changed lines, $rside"
HARNESS_REVIEW_DIFF="Review diff: $rfiles files, $rlines changed lines (git diff --shortstat origin/$MAIN_BRANCH...HEAD, the run directory left out); $rside"
```

For any other feature `HARNESS_REVIEW_DIFF=""`, so the line renders empty. `prompts/coding.md`'s `# This session` gets
`{{REVIEW_DIFF}}` on the line after `{{CLOCK}}`. The feature's own `model` is overridden for reviews (the initializer
writes `opus` on them); that is the point of the gate.

## How a Sonnet review escalates

After the session's post-processing (`MET append`, the `<id> · <model> · passes=…` note, the park branch), for a review
session that ran on `$(F model sonnet)`, wasn't parked or refused, and whose feature has no `$STATE/review-escalated-<id>`
marker:

- **Detect.** `node lib/entries.mjs findings "$RUN_DIR" "$id" "$SCRATCH/entry-final"` prints `<c>\t<i>`: the pure
  `reviewFindings(text)` (exported from `lib/entries.mjs`) matches `/\b(\d+)\s+Critical\b/i` and `/\b(\d+)\s+Important\b/i`
  in the summary of the feature's last entry in entries.jsonl (the one `journal` just wrote), else in the session's
  final message; a missing one of the two counts as 0; neither → `null`, exit 1.
- **Escalate** when `c + i > 0`: note `review <id>: sonnet found <c> Critical, <i> Important; one round on <REVIEW_ESCALATE_MODEL>`,
  `F unpass "$LIST" "$id"` (the milestone isn't done, so `verify_ready` waits for the round; the Opus round owns the
  verdict), touch `review-escalated-<id>` (once per feature per run), and write `$STATE/review-escalate` as
  `<id>\t<c>\t<i>`.
- **No escalation** when `0 Critical, 0 Important` (nothing to note beyond the session's line), and when neither count is
  found: note `review <id>: no "<n> Critical, <n> Important" in its summary or final message; not escalated`.
- **The round.** At the next pick, before `F next`, a `$STATE/review-escalate` file wins: `id` from it, `milestone=$(F
  milestone "$LIST" "$id")`, `mdl=$(F model "$REVIEW_ESCALATE_MODEL")`, `esc=1`, no diff note, **no `F bump`** (costs no
  attempt), and the clock says `clock "Review round 2 of 2 (escalated: sonnet found <c> Critical, <i> Important)"`
  instead of `attempt N of M`. `HARNESS_REVIEW_DIFF` keeps the measured line. The file is removed after the session,
  except when it hit a limit (the round runs again after the wait; the limit branch skips `F unbump` when `esc=1`).
  The deadline, stop and pause checks still come first, as for any session.
- **Never** for a review that ran on Opus (diff at or over the threshold, or the round itself), whatever it reports.

The escalated session is an ordinary coding session for the same feature: same journal, `logs/NN-<id>.jsonl`, a
metrics row with model opus and kind review. Two metrics rows for the feature, `attempts.json` still says 1.

## Config

`lib/config.sh`: `REVIEW_OPUS_LINES=400 REVIEW_ESCALATE_MODEL=opus` (own line, a why comment, next to the verify models);
`templates/user/config.sh` documents both beside `VERIFY_ESCALATE_MODEL`.

## summary.json, report.md and the ledger

- `build()` adds `review: { cost_pct, found_nothing }`: `cost_pct` is `by_role.review / cost.total × 100` with one
  decimal, `null` when no review session ran (or the total is 0); `found_nothing` is the number of review features
  whose last entries.jsonl entry's summary gives `reviewFindings` → `0, 0` (imported from `lib/entries.mjs`).
- `rework` stops counting the escalation round: a feature's real coding rows minus its `one round on` notes must be
  more than one (else every escalated review reads as rework and lowers `first_attempt_pass_rate`).
- `report()` gets a row after `Spend by role`, only when `s.review?.cost_pct != null`:
  `| Review share | <pct> % of the run's cost · <n> of <m> reviews found nothing Critical or Important |`.
- `ledger-line` adds `review_cost_pct: s.review?.cost_pct ?? null`; `harness trends` keeps its columns.

## The stub

Documented in its header comment, as the other `STUB_*` flags:

- `STUB_REVIEW_LIST=1`: the initializer writes A (sonnet), B, D (build) and R (`"kind": "review"`, `"model": "opus"`),
  all in M1; no C, so B's tamper is skipped when the list has no C (guard the node one-liner).
- `STUB_BIG_DIFF=1`: A's first session also commits `big-A.txt`, 500 lines (`seq 500`).
- `STUB_REVIEW_FINDINGS=<c>,<i>`: every R session's entry summary is `R: stub review (<n>): <c> Critical, <i> Important, 0 Minor`.

## The checks (tests/checks/41-run-19-review-gate-m6.sh)

Three stub runs, all `STUB_REVIEW_LIST=1 STUB_LENIENT=1`: `rsmall` with `STUB_REVIEW_FINDINGS=1,0`, `rnone` with
`0,0`, `rbig` with `STUB_BIG_DIFF=1` and `1,0`. Names (one line each in check-names.txt):

| Feature | Check |
|---|---|
| M6-02 | `review gate: a review under REVIEW_OPUS_LINES runs on sonnet, noted with its changed lines` |
| M6-02 | `review gate: a review at or over REVIEW_OPUS_LINES runs on opus` (rbig) |
| M6-02 | `review gate: the review's prompt copy has its Review diff line, a build session's has none` |
| M6-03 | `review gate: a sonnet review reporting 1 Critical gets one round on opus at no attempt` (rsmall: two R rows, sonnet then opus; the note; attempts.json R = 1) |
| M6-03 | `review gate: a review reporting 0 Critical, 0 Important is not escalated and the run ends done` (rnone) |
| M6-03 | `review gate: a review on opus never escalates; the escalation round's clock says Review round 2 of 2` (rbig one R row; rsmall's second R prompt copy) |
| M6-04 | `review gate: reviewFindings reads <n> Critical and <n> Important, null without either` (pure) |
| M6-04 | `review gate: summary.json and report.md carry review.cost_pct and review.found_nothing; the ledger row has review_cost_pct` (rnone found_nothing 1, rsmall 0; rsmall's rework has no R) |

`tests/checks/07-step-lint-pure-r3.sh` (R2) passes unchanged; the checks in `tests/checks/14-run-2b-stop-records.sh`
that read summary.json pass.

## evals/NEXT.md (M6-04)

`## 5. M6: the review gate`, for Michael to run by hand, never by the build (`git status --porcelain -- evals/results`
stays empty):

```bash
EVAL_BUDGET_USD=35 harness eval run --set default --harness run/agent-harness-2026-10-25-memory/M5 --label pre-m6
EVAL_BUDGET_USD=35 harness eval run --set default --harness run/agent-harness-2026-10-25-memory/M6 --label m6
harness eval compare pre-m6 m6
```

What it should show: $ per verified feature down, verify-fail rate not up. No cost claim stands before he runs them.
README.md's `## Evals` points at the section.

## Docs and the decision (M6-03, M6-04)

`docs/architecture.md` §7 gets a `Review gate` row (trigger: a `review` feature picked; model: by measured diff;
escalation: one Opus round on a Critical/Important, no attempt, once per feature; notes as above) and the config list
gains the two keys; `journal/decisions/<date>-review-gate.md` (finding · choice · rejected) records the defaults below
and names `review.cost_pct` and `review.found_nothing`.

## Defaults taken (D-defaults, recorded in the decision file by M6-03)

1. **The Opus round un-passes the feature first** and owns the verdict, so verify can't run on the Sonnet verdict
   while the round is pending. Cost: a deadline that falls between the two sessions leaves the review unpassed.
2. **Once per feature per run.** A later attempt of an escalated review is sized by its diff again and never escalates.
3. **No counts found → no escalation**, noted. Rejected: escalating on silence (the stub's and many real summaries
   would always escalate).
4. **A failed diff measure → Opus** (the safe side), noted.
5. **The review session's reviewer subagent is unchanged**: `prompts/coding.md` §2 still says reviews go to Opus
   subagents. A Sonnet review session that delegates to Opus saves less; changing that prompt line is Michael's call
   (asked in the entry), not this milestone's.

## Rejected

- Measuring from the milestone's first commit (needs a per-milestone start marker the driver doesn't keep; the merge
  base is what main lacks, which is what a review should read).
- Re-using verify's `models` loop for the review: the coding loop's limit, park and repair handling would have to be
  duplicated inside it; a pending-round file lets the round go through the same loop.
- Skipping the milestone review when in-session reviews found nothing (§ D: unsafe; the rane Critical was cross-feature).
