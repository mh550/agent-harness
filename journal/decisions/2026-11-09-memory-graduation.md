# The memory reviewer counted: its cost and time beside its verdict, the ledger's rows by tier, and the rule that earns `auto`

*(2026-11-09, run agent-harness-2026-11-09, R2 (the fields and the report by R2-01, `harness memory`'s columns, the
overrides, the rule and the card's text by R2-02); spec
`docs/specs/2026-11-08-memory-reviewer.md` §R2; the run's brief (2026-11-09 22:45: proceed on the defaults the spec marks
*default*, never park); R1's names as built: decisions/2026-11-09-memory-reviewer.)*

- **Finding:** after R1 every memory PR carries a second reader's verdict on each operation, and the report already
  shows what the curator costs by role. Nothing yet says what the reviewer costs beside what it found, the ledger's
  `memory.jsonl` rows carry no verdict for `harness memory` to count, and the run.log parser knew no `memory review · `
  line, so the session was matched to its metrics row only by being left over.
- **Choice (R2-01):**
  - `memory.json` gains the session's `review_cost_usd` (its transcript's cost, `metrics.mjs cost`, as the metrics row
    reads it), `review_s` (its wall, `S_WALL`) and `review_model` (the resolved model id), `0`, `0` and null when no
    session ran (nothing to review, an input that failed), plus `reviewed_ids` (the input's ids) and `failed_ids` (the
    failed ones with their question, `facts/2:q2`; a bare id for an op not reviewed or reviewed too thin, which fails on
    no question). `memreview.mjs verdicts` gives each op its failing row's `q` for that, its `reason` unchanged.
    `summary.json`'s `memory` carries every key; a `memory.json` without `reviewed` gets none of them.
  - *Default*: the cost and time in the `Memory` row, `· review 3 held · 0 failed · $0.42 · 4 min` (minutes rounded),
    not a row of their own: one row per concern, and the reviewer is the memory concern's. `· review none (<why>)`
    when no review happened, and nothing after `rules PR …` for a summary written before R1, so an old report prints as
    before. `Spend by role` lists `memory-review` after `curator`; `Time` follows run.log, where the reviewer's line
    comes after the curator's.
  - *Default*: the bound is the session's `$3` and 40 turns (R1-01) and the spec's Predictions row (the reviewer at or
    under the curator's cost on the median run, its wall under 6 minutes). A run whose reviewer cost more than its
    curator gets one note after the review's counts, `memory review: cost $<r> over the curator's $<c>`, never a stop:
    the falsifier reads the notes, and one dear review is not a reason to leave a PR unreviewed.
  - `ledger/memory.jsonl`'s rows gain `reviewed`, `held`, `failed`, `review`, `failed_ids`, `merged_by` and
    `review_cost_usd`; the facts row and the rules row of one run each count their own tier's ops from the input's
    `facts/*` or `rules/*` ids (none held or failed without a review). *Default*: `merged_by` is the facts row's alone
    (`driver` or null); the rules row's is always null, since the driver never merges the rules PR (invariant 3) and a
    copied `driver` would hide Michael's merge of it from R2-02's override reading. `review_cost_usd` is the one
    session's, in both rows: never summed across a run's two rows. A row whose summary has `reviewed` but no ids (a run
    between R1 and R2) gets no review fields and reads as unreviewed, rather than a split it cannot make.
  - `parseRunLog` reads `memory review · ` and `  memory-review exit <n>` as one `memory-review` session, matched to its
    metrics row as the curator's is.
- **Choice (R2-02):**
  - **The columns.** Each `harness memory` line carries its row's review after its counts, `held <h> · failed <f>`, and
    `unreviewed` in their place for a row written before R2 or one whose review did not happen (`review` not `ok`): a
    review none is no verdict, so it is counted with the unreviewed (*default*). A fourth tally line follows the three
    that stay as they were: `review: held h · failed f · overrides o (merged against a fail m · edited or closed against
    a hold e) · unreviewed u`, over the shown rows.
  - **Michael's overrides**, read at listing time from the row and gh's state, never written back (`memoryOverride`,
    where `merged_by` is read): *merged against a fail* is a PR merged unchanged with a failed op and `merged_by` not
    `driver` (under `auto` the driver merged a commit the fails were dropped from: no override), and not of a commit
    `auto`'s landing dropped them from whoever merged it (`fails_dropped` in `memory.json` and the facts row, R2-02's
    review: a PR the driver left open that Michael merges holds no failed op); *closed against a hold*
    is a PR merged edited or closed whose every reviewed op held. The line ends `· override: merged against a fail` or
    `· override: closed against a hold`, the spec's two words, an edited PR's included (*default*). *Default*: a closed
    PR counts, with no second state for "closed, not an override"; the one exception is a closed PR whose run has a
    declined row in `ledger/memory-answers.jsonl` (its `--why` is the reason). Tier 1 is never numbered, so no decline
    row can name the facts tier: any declined row of the run is read as the reason (*default*), for either tier's PR.
  - **The rule that earns `auto`** (`graduation`, the `auto:` line `harness memory <project>` prints last; none without
    a project, since the rule is per project): over the project's last **8** reviewed facts PRs (a facts row with the
    review's fields, `review` ok and at least one op reviewed), at least **10** operations reviewed, at least **90 %**
    of them held and at most **one** override → `earned`, else `not yet`; *default*: the window must be full, 8 PRs, so
    a project with few runs is `not yet` however clean. Why the numbers: 8 is the old rule's five plus three, so one
    reviewer failure (`none`, outside the window) does not empty it; 10 ops is the least count at which 90 % allows one
    fail (the runs on record carry one to three ops each), so a project that teaches little takes longer, which is
    right; 90 % is one failed op in ten, the rate at which a wrong line reaching `main` under `auto` is rarer than one
    Michael lets through by hand (PR #137: one of one); one override because an override is the one event that says the
    questions are wrong, and the falsifier triggers at a third. The hold counts are the ledger's rows; only the override
    needs gh's state. A project on `auto` by its config (`harness memory <path>` reads the user's and the project's
    config; a bare name the user's alone, *default*) reads `revisit` under **80 %** held: a word, never a switch,
    since turning `auto` off is Michael's. Wording: `auto: not yet (held 7 of 8 · 87 % · overrides 1 of 6 reviewed PRs ·
    window 8)` (the per cent rounded down, R2-03; the thresholds compared exactly). This replaces decisions/2026-11-07-memory-policy's
    "about five merged unchanged" (its `Updated in place 2026-11-09` line); `merged unchanged` stays a column.
  - **The card's text** is `memreview.mjs line <verdicts.json> <memory.json>`, one function: `memory: facts 1 held · 1
    failed (facts/2: 7 files: …, q2) · rules 1 held · PR <url> · rules PR <url|none>`, `memory: review none (<why>) · PR …`
    when no verdict came, nothing before the review or with nothing reviewed. The driver notes it once, after both PR
    notes (R1-02's counts note stays first); its `held · failed` counts are `heldFailed`, the one renderer the `## Review`
    section and the report's `Memory` row's tail also print. *Default*: the facts tier's failed count always shows (it
    is what `auto` merges), the rules tier's only when one failed, as the spec's example reads. A path that ends
    before any PR (the landing differs from the dry apply, an apply that failed) notes no such line: no PR, no card.
  - **For F3d** (a v2 of `docs/specs/2026-10-22-n8n-events.md`, not written here) this run names and sends nothing: a
    routed kind `memory`, its `title` `[<run>] memory: <held> held · <failed> failed`, its `body` this line, its `click`
    the facts PR, and one object field `memory` beside `context`: `{pr, rules_pr, policy, reviewed, held, failed,
    failures: [{id, section, q, reason}], state}`. The v1 contract and `lib/notify.mjs`'s kind list are unchanged.
- **Choice (R2-03, R2's review: `docs/plans/2026-11-09-R2-review.md`, 0 Critical, 1 Important, 8 Minor):**
  - **A reused PR's row counts every segment** (I1). A continue reuses its facts PR, so the PR carries every segment's
    commits; `memory-line` replaced its row with the last segment's review alone, so a merge over segment 1's fail read
    as no override and a close over segment 1's unreviewed commit as `closed against a hold`. `memoryMerge` now keeps
    each segment's part under `segments` (keyed by the summary's `continuations`, so a rerun of one segment's `ledger()`
    replaces its own part), counts only segments that landed a commit on the PR (`applied`, or `rules` for the rules row,
    over 0), sums `reviewed`/`held`/`failed` and joins `failed_ids`; one landed segment without a review makes the row
    unreviewed (its `review` that segment's why); `fails_dropped` is true only when every failed op was dropped. The
    counts and sections stay the latest segment's, as before (`1/3/0` after mp's continue).
  - *Default*: a PR in the `auto:` window that gh gave no state for (offline, unauthenticated) is an override unread:
    never `earned`, the line ending `· unknown <k>` (M1); `revisit` reads the rows alone, so it stands.
  - The per cent is rounded down (M3), so `90 %` never sits beside a `not yet` the exact compare gave (26 of 29).
  - A `memory.json` from R1 (`reviewed` but no cost or wall) prints no `$0.00 · 0 min` (M2): a session ran, and its
    cost is in `Spend by role`.
  - An input that failed (`memreview.mjs input` threw) lands every op unreviewed, so `line` prints `memory: review none
    (the review input failed (see run.log)) · PR …` (M5); only `nothing to review` prints nothing.
  - R1-02's counts note (`memory review: <n> reviewed · <h> held · <f> failed`) keeps its own text in bash, and the
    rules tier's part of `line` its own (its failed count only when one failed): the three uses this decision names
    (the `memory:` note, `## Review`, the report's tail) are `heldFailed` (M6).
  - Not changed: `harness memory .` or `..` reads the user's config alone (M7: a path is a name with a `/`, the default
    above; a fix wants its own stub check of a project config, left for a later run); the reviewer's cost note at
    equal cents (`$0.45 over the curator's $0.45`, M3's second half: it is over at full precision).
- **Checks** (decisions/2026-11-03-trim): R2 removed two names, each kept by its successor:
  - `harness memory: the run's facts and rules PRs are a line each with its tier, then one tally line per tier; the
    facts PR merged unchanged after its merge` → `harness memory: the run's facts and rules PRs are a line each with its
    tier and its review's held and failed, then one tally line per tier and the review: tally; the facts PR merged
    unchanged after its merge, and with a project the auto: line` (memory-branch.sh, the same check extended).
  - `summary.mjs memory: build reads the review's keys and memoryLine ends with the review's counts; nothing for a
    memory.json without reviewed` → `summary.mjs memory: build reads the review's keys, cost, wall and model;
    memoryLine ends with held, failed, dollars and minutes, none (<why>) without a review, nothing for a memory.json
    without reviewed` (unit).
  - R2's count: 16 names added, 2 removed (R2-01 and R2-02 15, R2-03 one: `summary.mjs memory: memory-line on a
    continue's reused PR sums …`), against the budget of 25.
- **Rejected:** a `Review` row of its own for cost and time (two rows for one concern); a stop or an unmerged PR on a
  dear reviewer (the cost is read, not enforced, until the Predictions are); the run's whole review counts in both
  ledger rows (the rules PR's held and failed would count the facts' ops); parsing the question out of the reason's
  `(q<n>)` (the verdict knows it); a sub-command in `lib/metrics.mjs` (`cost` already reads a transcript's cost). For the rule (R2-02): a window of 5 PRs (one reviewer failure empties a fifth of it); 95 % (one fail
  in twenty: a project with three ops a run would wait seven runs past its first fail); zero overrides (one mistaken
  click would bar a project for 8 PRs); a hard switch that turns `auto` off under 80 % (the policy is Michael's, the
  line only reads it); a second PR state for "closed, not an override" (the decline's `--why` already says it). For R2-03: a per-commit map in place of the per-segment one (the segment is what `ledger()` reruns, and one segment makes one facts commit); a sum of the counts and sections too (they are the curator's work in that segment, which the line has always shown).
