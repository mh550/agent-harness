# The memory reviewer: an independent verify of the curator's operations, its verdict in the PR, the report and the count `auto` is earned by (2026-11-08)

**Goal.** The harness takes no coding session's claim without an independent verify: `lib/lane.sh`'s `verify` runs a
second session that re-runs every step and writes one evidence row per step (`prompts/verify.md`, the `evidence` rows of
`entries.jsonl`). The curator's claims get no such step. Its operations pass one mechanical gate (`lib/curator.mjs`
`apply`: the entry states the line's first 40 characters, the anchor matches one line, the cap) and then land in a PR
whose only judge is Michael, who does not hold the project's context (Decision 27, his words: *"Who knows about the
project is the harness itself that originally wrote the comments, not I."*). This spec adds the missing step. **R1**: one
read-only Opus session at the run's end, after the curator's operations are applied on a copy of the base and before
anything is committed, answers four questions about every operation that would land, with one evidence row each; the
driver renders the verdict into both PR bodies, the notes and the report, and under `MEMORY_POLICY=auto` commits and
merges only what held. **R2**: the verdict and Michael's overrides are counted in `ledger/memory.jsonl` and
`harness memory`, the reviewer's cost and time are in the report under a bound, and the rule that earns `auto` is
rewritten from "about five merged unchanged" to the curator's agreement with the reviewer plus few overrides. Two
milestones in series: R1, then R2.

**Provenance.**

| what | came from |
|---|---|
| the piece itself: an independent review of memory PRs, read-only, at the run's end, with an evidence table | Decision 27 (a), Michael, 2026-11-08 (`docs/plans/2026-11-03-test-suite-redesign-dispatch.md`, row F3f) |
| the case: PR #137 (`memory: agent-harness-2026-11-07-3`) applied one `add` with an anchor while `## Gotchas` had 15 of 15 lines by the curator's count (14 facts and the `<!-- At most 15 lines … -->` comment line, an entry to `sectionEntries` until decisions/2026-11-09-thin-verify-and-comment-lines) and `CLAUDE.md` 97 of 120: the 2026-10-29 Gotcha on locale-bound glyph regexes left, the PR body said `add` and never named it; seven check files match the glyph the line is about (`grep -rlF '(─)' tests/checks`, 2026-11-08: `needs-cards`, `needs-questions`, `queue-view`, `show`, `status-card`, `status-view`, `tty-views`); the supervisor read the tree by hand and put the line back (Decision 23 (a)) | Decisions 23 and 24; `.harness/runs/agent-harness-2026-11-07-3/memory-ops.json` and `memory.md` |
| the four questions | Decision 27's option (a), in the words of the block `## F3f` |
| Opus for a review | answer 2 (`journal/learning/2026-11-07-memory-curator.md` §11) |
| the reviewer's shape: a verify, not a second curator | `prompts/verify.md` ("Do not trust the progress notes. Re-run the steps"; one row per step; fewer rows than steps is a thin check), `lib/entries.mjs` `renderEntry`'s five-column table, `lib/features.mjs` `evidence` |
| the rule that earns `auto` is a number, not a feeling | `decisions/2026-11-07-memory-policy` ("M3 ships the counter, not the switch"); §10's first row and its habit line |

**Source.** `journal/learning/2026-11-07-memory-curator.md` §4 (the mechanism), §10 (the measurement points every
Predictions row below names), §11 (the answers), §12 ("Make approval one click"; "Tier 2/3 … the least instrumented"),
§13 items 7 and 8; `docs/specs/2026-11-07-memory-curator.md` (M2 §2–§6, M3 §3, its Predictions); `docs/specs/2026-11-07-memory-followup.md`
(N1-01: two PRs, `harness-memory/<run>` and `harness-rules/<run>`, `memory-result.json` in the record with every tier-2
op and tier-3 proposal numbered `<run>/<n>`; N1-03: the cap per operation, `refused` retired; N2-01: `S_DENY` in
`session()`, `CURATOR_DENY`; N2-02: no merge without a refreshed body; N2-03: `apply`'s answers argument,
`ledger/memory-answers.jsonl`); `lib/curator.mjs` (`validate`, `tierOf`, `matchAnchor`, `capCheck`, `apply`, `body`,
`plain`); `lib/driver.sh` (`curator()`, `ro_rescue`, `finish`'s order: the end notification, the retro, the curator, the
summary; `ledger()`); `lib/record.sh` (`restrict`, `memory_guard`, `memory_base`, `memory_foreign`, `memory_json`,
`memory_pr`, `memory_body`, `memory_open`, `memory_merge`, `memory_edit`, `memory_wt_gone`, `session()`); `lib/summary.mjs`
(`memoryOf`, `memoryLine`, `memoryRow`, `memoryState`, `memoryShown`, `memoryView`, `reportRows`' roles list, `build`);
`lib/memory.sh`; `lib/entries.mjs` (`validate`'s evidence rows, `renderEntry`); `lib/metrics.mjs` (`append`, `limit`);
`prompts/curator.md`, `prompts/verify.md`; `docs/specs/2026-10-22-n8n-events.md` (the v1 contracts: the event's `kind`,
`title`, `body`, `click`, `actions`; nothing here changes them); `tests/stub-claude.sh` (`# Curator session`,
`STUB_CURATOR_OPS`, `STUB_CURATOR_EDITS`, the limit replay), `tests/stub-gh.sh`, `tests/fixtures/memory/`,
`tests/unit/curator.test.mjs`, `tests/unit/summary.test.mjs`, `tests/checks/memory-branch.sh`, `curator-run.sh`.

**Rules.** `CLAUDE.md` binds: worktree only; never touch real runs or real state; never a real notification; fakes mirror
the live API (a stub line is a captured shape, never a guess); every behaviour visible in `harness-log.md`, `run.log` or
a command's output and checked test-first in `tests/checks/` (tier by `decisions/2026-11-03-suite-tiers`'s 30 s rule,
its names in `tests/fixtures/check-names.txt` and, fast, `check-names-fast.txt`), a pure function's in `tests/unit/`; a
check that duplicates an assertion replaces it and the old name leaves the fixture in the same commit; `bash -n`,
`node --check`; one decision file per milestone (`journal/decisions/<run date>-memory-reviewer.md` for R1,
`<run date>-memory-graduation.md` for R2); `docs/architecture.md` and `README.md` in the same milestone as the code.
**Proceed on the defaults written here; record them marked *default*; never park.**

**Four invariants no feature may break.** (1) **The reviewer writes nothing but its one file.** It emits
`memory-review.json`; every other edit is reverted (`restrict … nothing`, as the curator's) and it runs under the
curator's deny list; the driver is the only writer of a project file, a branch or a PR. (2) **The reviewer never changes
an operation.** It holds or fails one; a failed operation is dropped by the driver with the reviewer's reason, never
rewritten. (3) **No review, no merge.** Under `MEMORY_POLICY=auto` the facts PR merges only when the review ran and
every operation in the commit held; a reviewer that failed, timed out or wrote nothing leaves the PR open. (4) **The
follow-up's invariants stand**: the curator never writes a project file, no operation touches a protected section, the
driver never merges the rules PR.

## Depends on

- **The follow-up run (`agent-harness-2026-11-08`, spec `docs/specs/2026-11-07-memory-followup.md`) merged.** The
  reviewer judges both of its PRs (facts and rules), keys its rows by N1-01's `<run>/<n>` numbers in `memory-result.json`,
  runs under N2-01's `S_DENY`, and passes its verdict to `apply` beside N2-03's answers file. One run per project
  (`decisions/2026-10-21-queue-one-run-per-project`), so `harness queue add` holds this run until that one ends; the
  brief says so. `main` at or after that run's record PR.
- **Where the follow-up's defaults moved**, the run reads the names as built (its two decision files,
  `journal/decisions/<date>-memory-rules-pr.md` and `<date>-memory-session-and-answers.md`) and uses them; this spec
  names the follow-up's defaults (`harness-rules/<run>`, `memory rules: <run>`, `CURATOR_DENY`, `memory-result.json`'s
  numbering, `apply`'s fifth argument) and nothing here turns on a particular spelling.
- R2 after R1 (R2 counts what R1 writes). R1's first feature `after: []`, R2's `["R1"]`.
- Nothing here touches the n8n events contract (`docs/specs/2026-10-22-n8n-events.md`, v1): no new kind, no verb. R2-02
  names the text and the field the review surface (F3d) will carry, in this spec and `docs/architecture.md` only.

---

## R1 · The reviewer: one read-only session, four questions per operation, the verdict where the operation is

**Finding.** Three things are true of a memory PR on `main` today. (a) The driver's gate answers one question
mechanically, *is the line stated by its entry* (`gateWhy`: the first 40 characters, case and markup aside), and the
rest of what makes an operation right or wrong is unexamined: whether the incident the line describes is in the record
(a line composed from several entries passes the gate when one entry starts the same way); whether a line that goes
(`replace`, `delete`, the anchored `add`) is still what some check or script depends on; whether an eviction was due at
all (the first PR's was not: 14 of 15, 97 of 120, and Decision 24's sentence in the follow-up's brief makes an
under-cap anchored add a plain add, which is the driver fixing its own rule, not a review); whether the line already
exists under another heading or in `~/.claude/CLAUDE.md`, which every session of every project reads (`apply`'s
`already in` rule looks at one section of one file). (b) The one reader who could answer them is Michael, who said he
cannot: judging PR #137 took `grep -rlF '(─)' tests/checks` and a read of the entry at `entries.jsonl:12`, which the
supervisor did by hand, once. (c) The harness already has the shape for this. A verify session is given the claims
(`feature_list.json`'s steps), told to trust none of them, and made to write one row per step with what it ran and saw;
the driver counts the rows and treats fewer rows than steps as a thin check (`lib/features.mjs` `evidence`,
`prompts/verify.md` step 4). A read-only session with one output file, its other edits reverted and the file rescued
around the revert, is the curator's own shape (`ro_rescue`, `restrict … nothing`). Nothing new in kind is needed; what is
new is the object (operations, not steps) and where the verdict goes (a PR body, a merge decision, a count).

### R1-01 · The session: read-only, denied, after the dry apply, one input file, one output file

**Choice.**

1. **A new session role, `memory-review`** (`prompts/memory-review.md`; `memory_review()` in `lib/driver.sh`, called
   from `memory_pr`'s path between the dry apply and the landing, R1-02 §1). Model `MEMORY_REVIEW_MODEL=opus` in
   `lib/config.sh` beside `CURATOR_MODEL` (answer 2: Opus for reviews; *default*, a knob so a project may run it on
   Sonnet once the falsifiers are read). `MAX_TURNS=40 SESSION_BUDGET_USD=3`, the curator's (*default*: the bound R2-01
   reports against; `SESSION_TIMEOUT` as every session). Transcript `$LOGS/zz-memory-review-<HHMMSS>.jsonl`, its prompt
   beside it as `session()` does; one `log "memory review · <model> · deny …"` line after the curator's; a metrics row
   with role `memory-review` (`record MET append … memory-review …`, as the curator's), so `Spend by role` and `Time`
   carry it with no further change.
2. **Read-only in the curator's three ways.** It runs in `$RWT` (the record branch at `finish`: `main` plus the run's
   record) from `rstart=$(git rev-parse HEAD)`; `ro_rescue "$rstart" memory-review.json memory-review` rescues its one
   file and reverts everything else with the note `memory review: reverted edits (it is read-only): <paths>`; the
   session runs under the follow-up's deny list (`S_DENY=("${CURATOR_DENY[@]}")`: `Bash(git push:*)`, `Bash(gh:*)`;
   *default*: the same two rules and the same array, the floor the follow-up set, nothing added: every other write is
   reverted). The `run.log` line and one note say so (`memory review: session denied Bash(git push:*), Bash(gh:*)`).
3. **Its input is what would land, not the raw operations.** Before the session the driver runs `apply` for each tier on
   a copy of the base (`$SCRATCH/memory-base/`, which `memory_base` already fills, copied to
   `$SCRATCH/memory-after-facts/` and `-after-rules/`; `apply`'s `plain()` reads a plain directory as it reads a
   worktree) and writes `$RUN_DIR/memory-review-input.json`: one item per operation that would be committed, the tier-1
   `applied` ops as `facts/1`, `facts/2`, … in `apply`'s order and the tier-2 `rules` ops as `rules/<n>` with N1-01's
   `<run>/<n>` number, each with its `op`, `file`, `section`, `anchor`, `text`, `why`, `from`, the base and after file
   paths, and the gate's own reading of the cap on the base (`gotchas: 14, lines: 97`), so the reviewer has the driver's
   claim to check, as a verify has the progress notes. *Default*: the gate runs first and the reviewer sees only what
   passed it. The alternative, reviewing `memory-ops.json` raw, spends the reviewer on operations the gate drops anyway
   and shows it a tree the driver would not write (an anchored add under the cap lands as a plain add since Decision 24).
   Tier-3 proposals are **not** reviewed (*default*: they are text for Michael and land nowhere; a falsifier watches
   whether he wants them read too). An op the gate dropped is not in the input and keeps the gate's reason.
4. **Its only output is `$RUN_DIR/memory-review.json`**: `{ "rows": [ { "id": "facts/1", "q": 1, "ran": "…",
   "saw": "…", "holds": true }, … ], "summary": "<at most 400 characters>" }`, four rows per id (`q` 1 to 4, R1-02 §1),
   the verify's `ran` / `saw` / `holds` shape, `ran` the command or the file and line read, `saw` what came back, cut to
   the entry row caps (`lib/entries.mjs`'s). The prompt tells it the harness counts the rows and that an op with fewer
   than four fails as thin, as `prompts/verify.md` tells the verify. The file is validated by R1-02's `validate`; an
   invalid one is refused whole with its first reason, as the curator's is.
5. **What it may read, and how**: `memory-review-input.json`; `entries.jsonl` with `jq` by line number (`from`);
   `progress.md` and `progress-archive.md` for the incident; the base and after texts in `$SCRATCH/memory-*`; the tree in
   `$RWT` with `git grep` (never `.harness/runs/`: the record quotes every line it curates); `~/.claude/CLAUDE.md`,
   read-only, for question 4 (it is the one file outside the checkout the prompt names; the user-level denies on
   secrets stand as for every session). Never a transcript, never another run's record. The prompt's last line: at most
   60 words, how many held, how many failed and why.
6. **Skipped when there is nothing to review** (*default*): both tiers' dry `apply` left `applied` and `rules` empty
   (every op dropped or proposed, or no ops): no session, no input file, one note `memory review: nothing to review`,
   `memory.json`'s `reviewed: 0` and `review: "nothing to review"`, and `memory_pr` goes on as today (proposals and
   dropped ops reach the bodies). The curator's own skip (`curator: no operations`) is upstream of this and unchanged.
7. **The stub** (`tests/stub-claude.sh`, `# Memory review session`): writes `memory-review.json` from the input file,
   four holding rows per id, under `STUB_MEMORY_REVIEW=hold` (the default when the knob is set); `evict-fails` fails
   `q: 2` of every `add` that carries an anchor and every `delete`, with `ran: git grep -nF -e '<first backticked span
   of the anchor>' -- . ':!.harness/runs'` and `saw: 7 files`, the first PR's shape; `thin` writes three rows for the
   first id; `none` writes no file; `bad` writes `{not json`; `limit` replays the captured rate-limit shape the stub
   already uses for other sessions; `STUB_MEMORY_REVIEW_EDITS=1` also edits `CLAUDE.md` and `lib/`. The stub records
   its argv as the follow-up's N2-01 has every session do.

**Checks (written first).** `tests/checks/memory-review.sh` (slow; one file for this spec's stub runs, so
`memory-branch.sh` and `curator-run.sh` keep their times): a run whose curator writes `stub-three-ops` ends done with one
`zz-memory-review-*` transcript, a `memory-review` metrics row, its `run.log` line after the curator's and before the
first `memory PR` note, and its argv carrying `--disallowedTools` with exactly the two rules; `memory-review-input.json`
in the run record lists `facts/1`, `facts/2` and `rules/<n>` with the base and after paths and the cap reading;
`memory-review.json` is kept in the run record; a reviewer that edits `CLAUDE.md` and `lib/` has the edits reverted with
one note, its `memory-review.json` kept and the record PR opened; a run whose every op is dropped or proposed
(`stub-proposal`) runs no reviewer (no `memory-review` in the stub's `sessions.log`), notes `nothing to review` and
opens no PR as today; the rendered prompt names the input file, the four questions, the thin rule and `~/.claude/CLAUDE.md`
read-only, with no `{{` left (`tests/checks/curator-run.sh` has the curator's twin of this: fold both into one
`memory-prompts.sh` check if the time allows; *default*: here). Pure, `tests/unit/memreview.test.mjs`: `input` builds the
items from two `apply` results in order, `facts/<i>` then `rules/<n>` with the follow-up's numbers, and from empty
results an empty list (the skip).

**Files.** `prompts/memory-review.md`, `lib/driver.sh` (`memory_review()`, the call in `finish`'s curator step),
`lib/record.sh` (`memory_pr`: the dry apply into `$SCRATCH/memory-after-*`, the input file, the session before the
landing; `memory_json`'s new keys), `lib/config.sh` (`MEMORY_REVIEW_MODEL`), `templates/user/config.sh` and
`templates/project/config.sh` (its comment), `lib/memreview.mjs` (new: `input`; R1-02 adds the rest), `lib/prompt.sh`
(the role), `tests/stub-claude.sh` (`STUB_MEMORY_REVIEW`, `STUB_MEMORY_REVIEW_EDITS`), `tests/checks/memory-review.sh`,
`tests/unit/memreview.test.mjs`, `tests/fixtures/check-names.txt`, `docs/architecture.md` (components: `lib/memreview.mjs`,
`prompts/memory-review.md`; the Read-only sessions guard row; the CURATOR step gains the REVIEW lines; the Memory
curation state row: `memory-review-input.json`, `memory-review.json`), `README.md` (*Memory curator* gains *Memory
reviewer*), `journal/decisions/<run date>-memory-reviewer.md`.

### R1-02 · The verdict: four questions, one row each, rendered as the verify's; held ops land, failed ones are dropped under `auto`

**Choice.**

1. **The four questions**, each one row per operation, in this order; the prompt gives the reviewer the minimum it must
   run for each, and `ran` names it:
   - **Q1, stated and recorded.** The `from` entry states the whole line as its own finding (not its first 40
     characters: the whole claim, in the entry's `discoveries` for tier 1 or `proposed_changes` for tier 2), and the
     incident is in the record: the entry's `summary`, `dead_ends` or `verified_how`, or the feature's section of
     `progress.md`, shows the thing happened to this run. `ran`: `jq -c 'select(input_line_number == <n>)' entries.jsonl`
     and the `grep -n` on `progress.md`. Fails: a line composed from several entries; a line whose incident no entry
     describes (a fact the session read somewhere and restated).
   - **Q2, no live referents.** For a `replace`, a `delete` and an `add` with an anchor (the eviction), the line that
     goes has nothing in the tree that still depends on it: every backticked span of the anchor and every path, flag,
     function or glyph it names is grepped as a fixed string, `git grep -nF -e '<span>' -- . ':!.harness/runs'
     ':!journal' ':!ledger' ':!docs/plans'` (*default*: the record, the journal, the ledger and the plans quote facts,
     they do not depend on them; code, checks, prompts, scripts and `docs/architecture.md` do), and `ran` names the
     grep with its spans. A hit is a live referent. For a `replace`, the row holds when the new text keeps every subject
     that has referents (a sharpened line) and fails when it drops one; for an eviction or a `delete` any hit fails it,
     with `saw` naming the files (PR #137's eviction: `7 files: tests/checks/needs-cards.sh, …`). An `add` without an
     anchor: the row holds with `ran: n/a (nothing goes)`.
   - **Q3, the cap and the anchor.** An eviction is due only at the cap: `## Gotchas` has 15 entries or the file 120
     lines **on the base**, counted by the reviewer (`sed -n '/^## Gotchas/,/^## /p' <base>/CLAUDE.md | grep -c '^- '`,
     `wc -l`), never from the input file's reading; a `replace` or `delete` names a line that is on the base (`grep -nF`
     of the anchor's first 40 characters). Decision 24 makes the driver turn an under-cap anchored add into a plain add;
     this row is the independent check that it did (the verify re-runs a suite the session says passed).
   - **Q4, no duplicate.** The new line says nothing another line of the same file already says, under any heading, and
     nothing `~/.claude/CLAUDE.md` says (the user file every session reads): the reviewer greps a distinctive phrase of
     the line and reads the hits (`grep -niF '<phrase>' CLAUDE.md ~/.claude/CLAUDE.md`). A `delete`: holds with `n/a`.
   An op **holds** when its four rows hold. It **fails** with the first failing row's `saw` as the reason, or with
   `review too thin (<k> of 4 rows)` when it has fewer than four, or `not reviewed` when it has none (*default*: thin is
   a fail, not an escalation to a stronger model as the verify's is; Opus is already the review model, and a fail leaves
   the op in front of Michael under `pr`).
2. **`lib/memreview.mjs`** (new, pure, unit-tested; the `.mjs` name is one word like `memlint.mjs`): `validate <review.json>
   <input.json>` (the shape above; an `id` not in the input, a `q` outside 1–4, a missing `holds`, a doubled `(id, q)` or
   over 4 × items rows refuse the file whole with the first reason); `verdicts <review.json> <input.json>` → one JSON
   line `{reviewed, held, failed, ops: [{id, holds, reason}]}`; `render <verdicts.json> <review.json>` → the `## Review`
   section: one line per op, `- facts/1 holds` or `- facts/2 **fails**: 7 files match \`(─)\`: tests/checks/needs-cards.sh, …
   (q2)`, then the evidence table in the verify's shape, `| Op | Q | What you ran or read | What you saw | Holds |`,
   through an `evidenceTable(rows)` exported from `lib/entries.mjs` that `renderEntry` uses too (one renderer, so the
   two tables cannot drift; `renderEntry`'s output is unchanged, a unit test says so). The review section comes right
   after the body's head, before *Applied*; when the body is over `BODY_MAX`, the review's table is the first part
   `body` trims and its one-line verdicts are never trimmed (`memory.md` and `memory-review.json` in the record keep
   everything). A run whose review did not happen renders `## Review` as one line, `none: <why>` (`nothing to review`,
   `the reviewer wrote no memory-review.json`, `memory-review.json invalid: <reason>`, `the reviewer hit a limit`,
   `the reviewer failed (exit <n>)`).
3. **The verdict reaches the commit through `apply`.** `apply` takes the verdicts file as its sixth argument (after
   N2-03's answers); when the policy drops failed ops (§4), a failed op is dropped at the point where it would be written,
   with the reason `review: <reason> (<id>)`, after every other step, so no op the reviewer did not see can land in its
   place (the duplicate-key choice and the cap arithmetic ran on the full list; *default*: a drop by verdict, not a
   removal from the input list, for exactly that reason). The landing is then the real `apply` in the scratch worktree
   (`$SCRATCH/memory`, as today) with the same ops, answers and verdicts; `apply` is deterministic, so a unit test
   asserts the landing equals the dry run minus the failed ops.
4. **What lands, by policy.** Under **`pr`** the facts commit and the rules commit carry every op the gate applied,
   failed ones included, and the `## Review` section marks each: the PR stays Michael's with the verdict in front of
   him, and the diff he reads is the curator's (*default*; dropping failed ops under `pr` too would make the PR the
   reviewer's and leave nothing for R2's override count to read). Under **`auto`** the facts commit carries the held ops
   only: the failed ones are dropped by §3 with the reviewer's reason, listed under `## Review` as failed and counted
   as `failed` (not `dropped`: `dropped` keeps the gate's meaning, §10 row 2), and the PR merges as today
   (`--match-head-commit`, a refreshed body first: N2-02). A facts PR whose every op failed under `auto` opens with the
   review and nothing to commit (`memory PR: none (no tier-1 change after the review); the body is in memory.md`, or the
   reused PR's body refreshed). The **rules PR** carries every op under both policies with the verdict beside it: it is
   Michael's under every policy (follow-up invariant 3).
5. **A reviewer that fails leaves the PR open under both policies with one note, never merging** (*default*; invariant
   3): no file, an invalid file, a limit (`MET limit`, the curator's reading), a non-zero exit or a timeout → the bodies
   carry `## Review` `none: <why>`, every op lands in the commits as under `pr`, and under `auto` `memory_merge` is not
   called: `memory PR: no review (<why>); not merged (MEMORY_POLICY=auto), left open · <url>`. The next segment's curator
   reuses the PR and its review runs again on what is new.
6. **Visible.** Notes, in order after the curator's: `memory review: <reviewed> reviewed · <held> held · <failed> failed`
   (`memory review: none (<why>)` when it did not happen), then one per failed op, `memory review: facts/2 fails: <reason>`,
   then under `auto` the drops as every drop is noted. The one-line summary is also the text R2-02 gives the card.
   `memory.json` gains `reviewed`, `held`, `failed`, `review` (`"ok"` or the why none) and `merged_by` (`driver` when
   `memory_merge` merged it, else `null`); `summary.json`'s `memory` carries them; the report's `Memory` row gains
   `· review <held> held · <failed> failed` (R2-01 adds the cost and time).
7. **`prompts/curator.md`** gains two sentences: a reviewer checks every operation against the record and the tree, and
   an eviction, replace or delete of a line the tree still depends on fails it; so a `replace` that keeps the subject
   beats an eviction. Nothing else changes for the curator.

**Checks (written first).** Pure, `tests/unit/memreview.test.mjs`: `validate` passes a four-row file and refuses an unknown
id, a `q` of 5, a doubled `(id, q)` and a non-boolean `holds`, each naming the row; `verdicts` holds an op with four
holding rows, fails one on its first failing row's `saw` naming the question, fails one with three rows as thin and one
with none as not reviewed; `render` writes one line per op and the table in the verify's five columns, and `none: <why>`
for no review; a body over `BODY_MAX` loses the review's table before any other part and never its lines; `apply` with a
verdicts file drops a failed op at its write with `review: <reason> (<id>)` and leaves the duplicate-key choice as the
full list made it (the earlier op of the same key does not land); the landing equals the dry run minus the failed ops.
`tests/unit/entries.test.mjs`: `evidenceTable` renders the verify's table and `renderEntry`'s output is byte-identical to
before. Stub runs, `tests/checks/memory-review.sh` (slow): `STUB_MEMORY_REVIEW=hold` on `stub-three-ops` under `pr`: both
PR bodies carry `## Review` with one `holds` line per op and the five-column table, `memory.md` too, the note counts
`3 reviewed · 3 held · 0 failed`, `memory.json` has the keys; `STUB_MEMORY_REVIEW=evict-fails` on `stub-cap-evict` under
`pr`: the eviction's line reads `**fails**` with the grep in its row, the facts commit still carries it, the note names
it, the PR is open and left for Michael; the same under `auto`: the facts commit on `harness-memory/<run>` lacks the
failed op and holds the held one, the PR merges, `memory.json` reads `failed 1` with `dropped` unchanged from the `pr`
run, and the `## Review` section lists the failed op with the reason; `thin` fails the first op as thin and the rest
hold; `none`, `bad` and `limit` each open the PR with `## Review` `none: <why>`, one note, and under `auto` no `pr merge`
of that URL in `gh.log`; a continued run after `none` runs the review again and merges when it holds; the rules PR's
body carries the verdict and the driver never merges it (`gh.log`). The old `curator-run.sh` check `its notes before the
record PR's` extends to the review's notes (replacing that name).

**Files.** `lib/memreview.mjs` (`validate`, `verdicts`, `render`), `lib/entries.mjs` (`evidenceTable`), `lib/curator.mjs`
(`apply`'s sixth argument and the `review:` reason; `body`'s review part and its trim order), `lib/record.sh`
(`memory_pr`: the verdicts into both applies, the policy branch of §4, the no-review branch of §5, `memory_json`),
`lib/driver.sh` (`memory_review()`), `lib/summary.mjs` (`memoryOf`'s keys, `memoryLine`), `prompts/memory-review.md`,
`prompts/curator.md`, `tests/stub-claude.sh`, `tests/unit/memreview.test.mjs`, `tests/unit/entries.test.mjs`,
`tests/unit/curator.test.mjs`, `tests/unit/summary.test.mjs`, `tests/checks/memory-review.sh`, `tests/checks/curator-run.sh`,
`tests/fixtures/check-names.txt`, `docs/architecture.md` (the CURATOR step: REVIEW, the policy table's `auto` row "merged
only when the review ran and every committed op held"; the PR table's bodies), `README.md` (*Memory reviewer*: the four
questions, what lands by policy), `templates/*/config.sh` (`MEMORY_POLICY`'s `auto` comment), the R1 decision file
(finding · choice · rejected: raw ops reviewed; thin as escalation; failed ops dropped under `pr`; tier 3 reviewed).

### R1-03 · Review (Opus: answer 2)

Sized to the milestone: an Opus reader of R1's diff, the review feature last. Hardest: that no path merges a facts PR
without a review that held every committed op (`grep -n memory_merge lib/*.sh`, each call's guard read); that the
reviewer's session can write nothing the driver keeps but `memory-review.json` (the rescue, the revert, the deny list
on its argv and no other role's); that a failed op dropped by verdict cannot let an op the reviewer never saw land (the
duplicate-key case); that `renderEntry` is unchanged; that the stub's review file has the shape the prompt asks the real
session for (the prompt's example and the stub's output compared). Findings are fixed in the same feature; the review's
file is `docs/plans/<run date>-R1-review.md`.

---

## R2 · The count: the reviewer's columns, Michael's overrides, the rule that earns `auto`, the cost under a bound

**Finding.** §10's first measurement point is `merged unchanged / edited / closed / open` per memory PR: *what Michael
did*, read from GitHub, "the number `auto` waits on", about five `merged unchanged` per project
(`decisions/2026-11-07-memory-policy`). It measures the curator against Michael. With R1 there is a second reader whose
verdict is on every operation before Michael sees it, so three things become countable that were not: whether the
curator agrees with the reviewer (held against failed, per op), whether Michael agrees with the reviewer (a PR merged
unchanged though an op failed; a PR edited or closed though every op held), and what the second reader costs. The old
rule had one weakness Decision 23 showed: PR #137 would have counted as `merged unchanged` had Michael clicked merge,
and the count would have moved toward `auto` on a loss of memory. A rule built on the reviewer's hold rate and few
overrides cannot be moved that way: the eviction fails Q2 and Q3, and a merge over it is an override, which counts
against. The report shows the curator's cost and time by role (`Spend by role`, `Time`); the reviewer's row arrives with
R1-01's metrics role, and what is missing is the bound the Predictions hold it to and the cost beside the verdict.

### R2-01 · The fields and the report: `memory.json`, `summary.json`, `ledger/memory.jsonl`, the `Memory` row with cost and time

**Choice.**

1. **`memory.json`** (R1-02 §6) is complete with `review_cost_usd` and `review_s` (the session's cost from its transcript
   and its wall seconds, `MET` as the retro's row is read; `0` and `0` when no session ran), and `review_model`.
   `summary.json`'s `memory` carries every key; `build` leaves them out for a `memory.json` written before R1 (no
   `reviewed` key), as it leaves `memory` out with no file.
2. **The `Memory` row** (`memoryLine`): `2 applied · 1 rules · 0 dropped · 1 proposals · PR <url> · rules PR <url|none> ·
   review 3 held · 0 failed · $0.42 · 4 min` (`review none (<why>)` when it did not run; no review part at all for a
   summary without `reviewed`, so an old report prints as before). `Spend by role` and `Time` list `memory-review` with
   the other roles (the roles list in `reportRows` gains it after `curator`). *Default*: cost and time in the `Memory`
   row rather than a row of their own: one row per concern, and the reviewer is the memory concern's.
3. **The bound**: the session's `$3` and 40 turns (R1-01 §1), and the Predictions row below (the reviewer's cost at or
   under the curator's on the median run, its wall under 6 min). A run whose reviewer cost more than its curator gets
   one note, `memory review: cost $<r> over the curator's $<c>` (*default*: a note, never a stop; the falsifier reads
   the notes).
4. **`ledger/memory.jsonl`** rows (`memoryRow`, `memory-line`) gain `reviewed`, `held`, `failed`, `review`,
   `failed_ids` (the ids with their question, `["facts/2:q2"]`), `merged_by` and `review_cost_usd`; a facts row and a
   rules row of one run carry the counts of their own tier's ops (the input's `facts/*` and `rules/*`). A row written
   before R2 has none of them and reads as *unreviewed* (R2-02).

**Checks (written first).** Pure, `tests/unit/summary.test.mjs`: `build` reads the new keys and leaves them out for an
old `memory.json`; `memoryLine` prints the review tail, `none (<why>)`, and nothing for a summary without `reviewed`;
`reportRows`' roles include `memory-review` when the summary has its cost; `memory-line` writes the fields into both
tiers' rows by tier. Stub runs, `tests/checks/memory-review.sh` (slow): after the `hold` run, `harness report` prints the
`Memory` row with the review tail and `Spend by role` with `memory-review`; `memory.jsonl` has the fields in the facts
row and the rules row; a run whose stub reviewer's transcript carries a cost above the stub curator's (a fixture knob,
`STUB_MEMORY_REVIEW_COST=<usd>`, the stub's `result` line) gets the one note.

**Files.** `lib/record.sh` (`memory_json`), `lib/summary.mjs` (`memoryOf`, `memoryLine`, `memoryRow`, `reportRows`,
`build`), `lib/metrics.mjs` if the cost read needs a sub-command, `tests/stub-claude.sh` (`STUB_MEMORY_REVIEW_COST`),
`tests/unit/summary.test.mjs`, `tests/checks/memory-review.sh`, `tests/fixtures/check-names.txt`, `docs/architecture.md`
(the ledger files table: `memory.jsonl`'s fields; the report's row), `README.md` (`harness report`'s `Memory` row).

### R2-02 · `harness memory`: the reviewer's columns, the overrides, the rule that earns `auto`, and the text the card carries

**Choice.**

1. **The columns** (`memoryView`, `lib/memory.sh`): each line gains the review, `<run> · <project> · facts · 2/0/1 · held 2 ·
   failed 0 · <url> · merged unchanged`; a row without the fields prints `unreviewed` in their place.
2. **Michael's overrides**, read at listing time from the row and `gh`'s state, never written back (as the state is):
   - **merged against a fail**: state `merged unchanged`, `failed > 0`, and `merged_by` not `driver` (under `auto` the
     driver's merge of a commit the failed ops were dropped from is no override).
   - **edited or closed against a hold**: state `merged edited` or `closed`, `reviewed > 0`, `failed = 0`.
   The line ends `· override: merged against a fail` or `· override: closed against a hold` when one applies.
   A `closed` PR may be closed for another reason (a duplicate run); the count takes it, and the falsifier on the
   override rate is where that shows (*default*: no second state for "closed, not an override"; Michael's `--why` on a
   decline, N2-03, is the place for a reason, and a closed facts PR with one is read as not an override: the row of
   `memory-answers.jsonl` whose `run` matches and whose `tier` is `facts`).
3. **The tally lines**: today's three stay as they are (`facts: merged unchanged a · edited b · closed c · open d`,
   `rules: …`, `answers: …`) and one more follows, `review: held h · failed f · overrides o (merged against a fail m ·
   edited or closed against a hold e) · unreviewed u`, over the shown rows.
4. **The rule that earns `auto`**, rewritten. Today: about five `merged unchanged` per project
   (`decisions/2026-11-07-memory-policy`, the curator spec's *After the run*). From this run: **a project earns `auto`
   when, over its last 8 reviewed facts PRs, at least 10 operations were reviewed, at least 90 % of them held, and
   Michael overrode the reviewer at most once.** The numbers and why: *8 PRs* is the old rule's five plus the three
   that let one reviewer failure (`none`) fall outside the window without emptying it; *10 operations* is the smallest
   count at which 90 % allows one fail (the runs on record carry one to three ops each: PR #137 had one applied, the
   stub fixtures two or three), so a project that teaches little takes longer to earn it, which is right; *90 %* is one
   failed op in ten, the rate at which a wrong line reaching `main` under `auto` is rarer than a wrong line Michael
   would let through by hand (PR #137: one of one); *one override in 8* because an override is
   the one event that says the questions are wrong, and the falsifier below triggers at a third. `harness memory <project>`
   prints the reading as its last line, `auto: not yet (held 7 of 8 · 88 % · overrides 1 of 6 reviewed PRs · window 8)`
   or `auto: earned (held 19 of 20 · 95 % · overrides 0 of 8 · window 8)`; without a project it prints no `auto:` line
   (the rule is per project, answer 10). A project already on `auto` reads the same line as a health check: under 80 %
   held over the window, the line says `revisit` (*default*: a word, never a switch; turning `auto` off is Michael's).
   **Which existing rows keep their meaning**: all of them. `merged unchanged / edited / closed / open` go on saying
   what Michael did with the PR (§10 row 1); `applied · dropped · proposed` and the drop reasons go on saying what the
   gate did (§10 row 2: a review drop under `auto` is `failed`, never `dropped`); `rules:` and `answers:` (the follow-up)
   are untouched. What changes is only which numbers the graduation line reads: the reviewer's hold rate and the
   overrides, with `merged unchanged` demoted from the rule to a column, since Decision 23 showed it can move on a loss.
5. **The text the card carries.** Today no notification carries the memory outcome: the run's one end notification goes
   out before the retro and the curator (`finish`, "the run's one end notification goes out now"), so the memory PR
   reaches Michael through GitHub and `harness report` alone. This spec names the text and the field for F3d and sends
   nothing. The text is R1-02 §6's note, one line: `memory: facts 2 held · 1 failed (facts/2: 7 files match \`(─)\`, q2) ·
   rules 1 held · PR <url> · rules PR <url>`, built by `memreview.mjs line <verdicts.json> <memory.json>` and used in three
   places so they cannot differ: the `harness-log.md` note, the `Memory` row's review tail (its counts) and the F3d
   card's text. **For F3d** (a v2 of `docs/specs/2026-10-22-n8n-events.md`, not written here): a new routed kind
   `memory`, its `title` `[<run>] memory: <held> held · <failed> failed`, its `body` this line, its `click` the facts PR,
   and one new object field `memory` beside `context`: `{ "pr": "<url>", "rules_pr": "<url or null>", "policy":
   "pr|auto", "reviewed": 3, "held": 2, "failed": 1, "failures": [ { "id": "facts/2", "section": "## Gotchas", "q": 2,
   "reason": "…" } ], "state": "open|merged" }`, so the card can show accept and override as its two actions with the
   reasons in front of him (§12, "Make approval one click"). The v1 contract and `lib/notify.mjs event`'s kind list are
   unchanged by this run; `docs/architecture.md` carries the sentence.

**Checks (written first).** Pure, `tests/unit/summary.test.mjs` (or `tests/unit/memory.test.mjs` if the follow-up made
one): `memoryView` prints the held and failed columns, `unreviewed` for an old row, the `review:` tally line with the two
override kinds, a driver-merged row with a fail as no override, a closed facts PR with a decline row as no override;
`graduation(rows, states, answers, project)` returns `earned` for 8 PRs with 20 reviewed, 19 held, 0 overrides, `not yet`
at 88 % or at 2 overrides or at 9 reviewed ops, `revisit` for an `auto` project under 80 %, and the line's wording;
`memreview.mjs line` renders the card text and the note from the same verdicts. Stub runs, `tests/checks/memory-review.sh`
(slow): after the `hold`, `evict-fails` and `auto` runs on one project, `harness memory` lists each run's lines with
their columns, the `review:` tally counts the `pr` run's eviction as a fail and, once the stub `gh` reports that PR
merged unchanged, as `merged against a fail`, the `auto` run's merge as no override, and `harness memory <project>` ends
`auto: not yet (…)` naming the window; the `harness-log.md` note of the `evict-fails` run equals `memreview.mjs line`'s
output for its record (the card text is the note). `tests/checks/memory-branch.sh`: the existing `harness memory …
merged unchanged after its merge` check extends to the columns (replacing that name).

**Files.** `lib/summary.mjs` or `lib/memory.mjs` (`memoryView`, `graduation`, the override reading), `lib/memory.sh` (the
answers file read for §2, the `auto:` line), `lib/memreview.mjs` (`line`), `lib/record.sh` (the note from `line`),
`bin/harness` (the usage line), `tests/unit/summary.test.mjs` (or `memory.test.mjs`), `tests/unit/memreview.test.mjs`,
`tests/checks/memory-review.sh`, `tests/checks/memory-branch.sh`, `tests/fixtures/check-names.txt`, `docs/architecture.md`
(`harness memory`'s row; the graduation rule where the architecture names `auto`; one sentence under the n8n events
section naming the F3d kind and field as this spec's), `README.md` (`harness memory`'s row, *Memory reviewer*'s rule),
`journal/decisions/<run date>-memory-graduation.md` (the rule, its numbers, the rejected numbers), and one `Updated in
place <run date>: …` line in `decisions/2026-11-07-memory-policy` where it says five merged unchanged. The learning file
`journal/learning/2026-11-07-memory-curator.md` is Michael's log and is not edited (*default*); this spec is where §10's
rule is rewritten, and the decision file is where it binds.

### R2-03 · Review (Opus: answer 2)

Sized to the milestone: an Opus reader of R2's diff. Hardest: that the override reading cannot count the driver's own
`auto` merge against Michael (`merged_by` read where the override is decided); that an old `memory.jsonl` row and an old
`summary.json` print as before (`unreviewed`, no review tail); that the three uses of the card text come from one
function; that the graduation line's three numbers are the ledger's, not `gh`'s alone (the hold counts are rows, the
override needs the state); that every check name removed has its successor in the decision file (`decisions/2026-11-03-trim`).
The review's file is `docs/plans/<run date>-R2-review.md`.

---

## Milestones

| M | Contents | After | `check_budget` |
|---|---|---|---|
| R1 | the `memory-review` role, `prompts/memory-review.md`, `MEMORY_REVIEW_MODEL`, the deny list and the rescue; the dry apply into `$SCRATCH/memory-after-*`, `memory-review-input.json`, `memory-review.json`; `lib/memreview.mjs` (`input`, `validate`, `verdicts`, `render`), `evidenceTable` in `lib/entries.mjs`; `apply`'s verdicts argument and the `review:` reason; the `## Review` section in both bodies and `memory.md`; the notes; what lands by policy and the no-review rule; the stub's `STUB_MEMORY_REVIEW`; `journal/decisions/<run date>-memory-reviewer.md`; architecture and README; R1-03 review | `[]` | 35 |
| R2 | `memory.json`'s cost, time and model; the `Memory` row's review tail; `memory-review` in the roles; the over-the-curator note; `memory.jsonl`'s fields; `harness memory`'s columns, the override reading, the `review:` tally and the `auto:` line; `memreview.mjs line` for the note and the card text, the F3d kind and field named in the architecture; `journal/decisions/<run date>-memory-graduation.md` and the `Updated in place` line; architecture and README; R2-03 review | `["R1"]` | 25 |

Plan each as three features, the review last. The suite ends green at every milestone; the fast tier stands under a
coding session's `passes`, the full suite at verify (`decisions/2026-11-03-fast-gate`). A milestone over its
`check_budget` says why in its last coding entry's `checks` field. `memory-review.sh` is a slow file by the 30 s rule
(stub runs); it is timed once alone when it is made and its row added under the tiers decision's table.

## Predictions (for the retro and the supervisor; against the runs after this one)

Every row names the measurement point of `journal/learning/2026-11-07-memory-curator.md` §10 it moves.

| Measure | now | after R1 + R2 | §10 point |
|---|---|---|---|
| operations landing in a memory PR with an independent read before Michael's | 0 of every op | **every committed op, 4 rows each** (`reviewed` = `applied` + `rules` on every run with one) | row 1, *merged unchanged / edited / closed*: a second reading sits between the curator and Michael, so his count stops being the only judgement |
| the first PR's case: an eviction under the cap of a line seven check files depend on | applied, `add` in the body, caught by hand | **fails Q2 and Q3; under `pr` marked in the body, under `auto` dropped with the grep as the reason** | row 2, *applied · dropped · refused with reasons*: a new reason family `review: …` whose rate is read per question |
| a memory PR merged by the driver without a review that held every committed op | possible (`auto` merges what the gate passed) | **0** | row 1: the `auto` state is honest, and §10's habit line (a claim without one of these numbers is *(inferred)*) |
| the numbers the graduation rule reads | 1 (`merged unchanged`, ≈ 5) | **3 (held ≥ 90 % of ≥ 10 ops, overrides ≤ 1, window 8)**; today's columns keep their meaning | row 1 and the Predictions row of the first spec (§10 row 6): the rule is a reading of the ledger, printed by `harness memory <project>` |
| `harness memory` tally lines | 3 after the follow-up (`facts:`, `rules:`, `answers:`) | **4 (`review:`), and the `auto:` line per project** | row 1 and row 4 |
| the reviewer's cost and wall per run, median over the first five reviewed runs | – | **at or under the curator's cost; under 6 min wall**; in the `Memory` row and `Spend by role` | the spec's Predictions table (§10 row 6), the row the falsifier on a dearer reviewer reads |
| operations failing Q1 that the gate passed, of those reviewed | – | **measured, not predicted**: above a third is the gate's 40-character rule being too loose (tighten the gate, not the review) | row 2: which rule rejects, and whether the mechanical gate or the review is the right place for it |
| staleness churn (`replace` / `delete` / evictions) reviewed for live referents | 0 of them | **all of them, with the grep named in the row** | row 5, *staleness churn*: the curator's most valuable op becomes its most checked, so a `delete` of a live line is a fail, not a loss |

**Falsifiers.** The reviewer holds every operation across three consecutive runs with operations (it checks nothing:
plant a known-bad op through the stub's `evict-fails` on a real-shaped fixture and read whether the prompt's minimum
greps are in the rows). Its grep for referents misses a line a check depends on (a held eviction whose anchor's span is
in `tests/` on `main`: the exclusion list or the span rule is wrong). The reviewer is dearer than the curator on the
median run, or over 6 min wall (the questions ask too much reading; cut Q4's `~/.claude/CLAUDE.md` read to a grep, or
the input file carries the greps pre-run). Michael overrides the reviewer on more than a third of reviewed PRs (the
questions are the wrong ones: read the overrides' `--why` rows before changing a question). Operations fail as thin on
more than one in ten (the prompt, not the reviewer). The `auto:` line says `earned` for a project whose next memory PR
Michael would have edited (the window or the 90 % is too lax: the first thing to try is 95 %). A facts PR merges under
`auto` with a `## Review` that is `none` (invariant 3 broke).

## Not in this spec

The review surface through n8n: the `memory` event kind, the card with accept and override, the n8n-home half (F3d; this
spec names the text and the field, sends nothing, and changes no line of the v1 contract). The recurrence measure and
acceptance per section read from the ledger (F3e). The prune of the three over-cap files by hand (F3c). Anything the
follow-up builds (the two PRs, the per-op cap, the deny list, the answers verb). Reviewing tier-3 proposals (text for
Michael; a falsifier watches). Escalating a thin review to a stronger model (Opus is the review model; thin is a fail).
A reviewer for the rules PR's merge (it is Michael's under every policy). Turning `auto` on anywhere (answer 10: per
project, on the reading). Any change to `~/.claude/CLAUDE.md` (the reviewer reads it; nothing writes it), to
`.claude/settings.json`, or to the n8n events contract.

## After the run (Michael)

- **Nothing to configure.** `MEMORY_POLICY=pr` stays the default; each memory PR now opens with a `## Review` section at
  the top: one line per operation (`holds`, or `fails: <reason>`) and the evidence table. Read the failed lines first;
  the diff is still the curator's. `MEMORY_REVIEW_MODEL=opus` is the default; a project may set `sonnet` once the
  falsifiers have been read for a few runs.
- **The counter**: `harness memory` lists each PR with `held` and `failed`, marks your overrides, and ends with
  `review: …`. `harness memory <project>` ends with the `auto:` line: `earned` when the last 8 reviewed facts PRs hold at
  least 90 % of at least 10 operations with at most one override; `not yet` otherwise, with the numbers. That line, not
  "about five merged unchanged", is what `MEMORY_POLICY=auto` waits on.
- **Under `auto`** the driver merges only what held, drops what failed with the reviewer's reason in the body, and leaves
  the PR open when the reviewer did not run. The rules PR stays yours under every policy, with the verdict beside it.
- **What it costs**: the `Memory` row of each report ends with the review's held, failed, dollars and minutes; the
  prediction is at or under the curator's cost. If it runs over on the median, the falsifier says what to cut first.
- **The dispatch list** (`docs/plans/2026-11-03-test-suite-redesign-dispatch.md`): row F3f's status to the run's PRs and
  this table's results; F3d's block, when it is written, takes the `memory` kind and field from R2-02 §5.
