# M3 · Gotchas in place, and the pack carries the current rules (plan, 2026-10-26)

Run `agent-harness-2026-10-25-memory`, feature M3-01. Spec: `docs/specs/2026-10-25-memory.md` § M3 (memory-model K2,
retro-followups §F2 and §F3, and the 2026-10-26 additions: `project` as an `affects` value, a `Promote to Gotchas`
part, `CONTEXT_PACK_BYTES_VERIFY=16384`). Brief: test-first, a decision file per behaviour change, never park; fixtures
copied from real files.

Checked against this branch at `706a001` (M2 verified; `main` at `db2e62f`). New checks go in
`tests/checks/38-run-17-gotchas-and-pack-m3.sh` (new) and `tests/checks/12-journal-pure-e4-entrys.sh`, each name also
one line of `tests/fixtures/check-names.txt` (`LC_ALL=C sort -u` order). Each check is written first and watched
failing.

One feature per item, in this order: M3-02 (Gotchas step and note), M3-03 (resolved questions, `project` facts,
`Promote to Gotchas`), M3-04 (`Current rules`, the verify cap), M3-05 (review).

## What the branch already has

- **The coding loop** (`lib/driver.sh:737-745`): `run_init; context "$id"`, `prompt coding`, `sstart=$(git rev-parse
  HEAD)`, `session coding …`, `commit_all "WIP: …"`, then `journal coding "$id" "$slog" "$mdl" "$sstart"` (every
  session, before the limit branch). After `commit_all` HEAD holds all of the session's work.
- **`context()`** (`lib/driver.sh:284-300`): `entries.mjs pack "$RUN_DIR" "$1" "$CONTEXT_PACK_BYTES"` →
  `$RUN_DIR/context.md`, note `context.md for <id>: <n> bytes[, <k> items left out]`, committed alone. `verify()` calls
  `context "$m"` once per round (`:409`). `session()` copies the pack beside the transcript as `logs/NN-<id>.context.md`
  or `logs/<hhmmss>-verify-<m>.context.md` (`:224`).
- **`pack()`** (`lib/entries.mjs:216-269`, pure): five parts in priority order (`This feature's earlier attempts`:
  dead ends, then `Verify … found` rows, then `Question (…)` items, then entries; `Michael's answers`; `Discoveries for
  this feature` (affects the feature, its milestone or `run`); `What it builds on`; `Lately in the run`). The first
  item that doesn't fit ends the pack; every later item counts in `_<n> items left out at <cap> bytes: entries.jsonl
  has them all._`. `PACK_RESERVE=160` keeps room for that line. The CLI (`pack <run dir> <feature> [<cap>]`, `:314-325`)
  rejects a cap that isn't an integer ≥ 1024.
- **`validate()` / `normalize()`** (`lib/entries.mjs:36-96`): `strings(f)` gives `<f>: not an array of strings`;
  normalize drops unknown keys, so a new field must be added to both.
- **`lib/memlint.mjs`** (M2): `decisionsStore(wt)` → `{path, kind: "dir"|"file", exists}` or null; `storeLine`. This
  repo's store is `journal/decisions` (dir, 47 dated `.md` files, each opening `# <title>`). The real file stores have
  three shapes for a decision line: a heading `## D7 *default*: …` (voice-concierge `docs/decisions.md:77`), a bullet
  `- **D1 *default* · …**` (rane-one-mixxx `docs/decisions.md:7`), a table row `| D24 | **…** | … |`
  (dj-crate-streaming `docs/decisions.md:41`).
- **The stub** (`tests/stub-claude.sh`): coding sessions in a run go 01-A, 02-B, (verify M1 round 1 sets A false),
  03-A, (verify M1 round 2), 04-C (leaves BROKEN, a dead end), 05-C, (verify M2). `entry()` builds entry.json with jq.
  The stub project's `CLAUDE.md` is `# proj\nrules\n` (`tests/lib.sh:48`): no `## Gotchas`, no decisions store.
- **Checks that must keep passing unchanged:** the four `context.md carries the earlier attempt's dead end` checks
  (tests/checks/08, 13, 14, 15: `05-C.context.md` has the dead end and is ≤ 8192 bytes, the verify-M1 pack's first line
  is `# Context pack for \`M1\``), `entries.mjs: the pack keeps a feature's dead end under a flood and respects the cap`
  in tests/checks/12 (ENPK asserts a feature pack lists dead ends before `Verify … found`, and that the second-to-last
  line is the `items left out` line; ENPK2 asserts a milestone pack has both), and tests/checks/29-run-15-resumed-run.sh.

## M3-02 · The Gotchas step and the driver's note (K2)

- **Prompt.** `prompts/coding.md` `## 3. Finish` gains a step after the suite step: *"If this session taught you a
  fact a fresh session would otherwise rediscover, add or edit one line under `## Gotchas` in the project's
  `CLAUDE.md` (create the section if it has none): at most 160 characters, ending `(<run> <date>)`; 15 lines at most:
  at 15, replace the least useful; a wrong line is edited in place; never rewrite the section."* The run id is
  the `Run:` line under *This run*; the date is the session's (no new prompt variable).
- **`gotchasLines(text)`** (pure, exported, `lib/memlint.mjs`): the non-blank lines between a line `## Gotchas` and the
  next `## ` heading (or the end), trailing whitespace trimmed; `[]` when there is no section or `text` is null.
- **`gotchasDiff(before, after)`** (pure, exported): the two `CLAUDE.md` texts (null for a missing file) →
  `{added, edited, deleted}`. `R` = lines of `before` not matched in `after`, `N` = lines of `after` not matched in
  `before` (multiset difference, so a repeated line counts); `edited = min(|R|, |N|)`, `added = |N| − edited`,
  `deleted = |R| − edited`. Reordering is no change. *Default:* a replace (one line out, one in) is an edit, which is
  what the prompt asks for at 15 lines.
- **CLI:** `memlint.mjs gotchas <before file> <after file>` prints `+<a> ~<e> -<d>` when any is non-zero, nothing
  otherwise; a missing file reads as null. Usage line updated.
- **Driver:** `gotchas <feature> <start commit>` in `lib/driver.sh`, called in the coding loop right after
  `journal coding … "$sstart"` (so a limited session's edit is noted too): `git show "$2:CLAUDE.md"` and `git show
  HEAD:CLAUDE.md` into `$SCRATCH/gotchas-before.md` / `-after.md` (empty when the commit has none), then
  `note "$1: gotchas +<a> ~<e> -<d>"` when the CLI printed anything. Verify and retro sessions are read-only
  (`restrict` reverts `CLAUDE.md`), so they get no note.
- **Stub flag** `STUB_GOTCHA=<id>`: that feature's first coding session appends `## Gotchas` (when missing) and the
  line `- the stub's work files sit at the repo root, one per feature (<run> <date>)` to `CLAUDE.md`, committed with its
  work. Header comment documents it.
- **Checks** (tests/checks/38):
  - `coding prompt: the Finish step adds one Gotchas line` — the rendered `prompt-coding.md` of a stub run contains
    `## Gotchas`, `160 characters` and `never rewrite the section`.
  - `gotchasDiff: added, edited, deleted and no section` — pure, `node --input-type=module -e`: one added line →
    `+1 ~0 -0`, one changed → `+0 ~1 -0`, one removed → `+0 ~0 -1`, no section either side (and null) → all zero, a
    line outside the section changed → all zero; the CLI prints nothing for no change.
  - `a stub session that adds a Gotchas line is noted` — run with `STUB_GOTCHA=B`: harness-log.md has
    `B: gotchas +1 ~0 -0`.
  - `a session that leaves CLAUDE.md alone gets no gotchas note` — in the same run, exactly one `: gotchas ` line.
- **Docs:** `docs/architecture.md` §7 gains a `Gotchas` row (trigger: the `## Gotchas` lines differ between the
  session's start commit and HEAD; action: the note; where: `gotchas()` in the driver, `gotchasDiff` in
  `lib/memlint.mjs`). Decision file `journal/decisions/<date>-gotchas-in-place.md` (finding · choice · rejected:
  a separate gotchas file, a blocking size guard, an LLM tidy, a line-position diff).

## M3-03 · Resolved questions, `project` facts and `Promote to Gotchas` (§F2, the 2026-10-26 addition)

- **Entry field `resolved`** (an array of strings: the questions this session found answered, in INBOX `## Answers`
  or a decision that settles them, copied as context.md shows them after `Question (<feature>): `). `validate()`:
  `strings("resolved")`, so `resolved: "x"` gives `resolved: not an array of strings`. `normalize()`: kept right
  after `questions` **only when non-empty** (every older entry and every check comparing a normalized entry keeps its
  shape). Any kind may carry it.
- **Matching:** a question `q` of entry `e` is resolved when an entry on a later line (`line > e.line`) has a string
  `r` in `resolved` with `flat(r) === flat(q)` (`flat` folds whitespace runs to one space and trims). Exact after
  flattening; *rejected:* case-folding and prefix matches (a short `resolved` string would drop unrelated questions).
- **pack():** part 1 leaves out a resolved question. `progress.md` and the archive still show it (the record keeps it).
- **`affects: ["project"]`:** validate already accepts any non-empty string; the error text becomes `not a non-empty
  array of feature ids, milestone ids, "run" or "project"`. A `project` discovery is a fact that outlives the run.
- **New part `Promote to Gotchas`** (coding packs only, part 4: after `Discoveries for this feature`, before `What it
  builds on`): the discoveries whose `affects` includes `project`, newest first, each `- <text> → entries.jsonl:<line>`,
  one per distinct first 40 characters (code points of `flat(text)`). A discovery is **carried** (left out, not counted)
  when some line of `gotchasLines` of the worktree's `CLAUDE.md`, flattened, contains those 40 characters (the whole
  text when shorter). In a coding pack a `project` discovery shows here and not under `Discoveries for this feature`;
  a milestone pack has no `Promote to Gotchas` part (a verify can't write `CLAUDE.md`) and its `Discoveries` part is
  unchanged. **Share:** at most `cap / 8` bytes; an item past the share is left out and counted in `items left out`
  without ending the pack (the parts after it still fill).
- **pack() inputs:** `pack(entries, { …, gotchas = [] })`, the lines from `gotchasLines`. The CLI reads
  `<worktree>/CLAUDE.md` where `<worktree>` is the run dir's third parent, **only when** the run dir's parent is `runs`
  and its grandparent `.harness` (eval probe dirs and the checks' `$T/pk`-style dirs read nothing).
- **Prompts:** `prompts/coding.md`'s entry example gains `"resolved": ["Should X default to off?"]` and a
  `project` discovery; its field sentence says `resolved` lists answered questions (copied from context.md) and
  `affects` may be `project` (a fact that outlives the run); the Gotchas step says the `Promote to Gotchas` items of
  context.md are written into `## Gotchas` first. `prompts/parts/where-things-go-readonly.md`: a verify's durable
  fact goes to its entry's `discoveries` with `affects: ["project"]`.
- **Stub flags:** `STUB_ASK=<id>` (that feature's first coding session's entry has `questions: ["Should <id> default
  to off?"]`), `STUB_RESOLVE=<id>` (its later sessions' entries have `resolved: ["Should <id> default to off?"]`),
  `STUB_PROJECT_FACT=<id>` (its first session's entry has the discovery `the stub's work files sit at the repo root,
  one per feature` with `affects: ["project"]`, the same text `STUB_GOTCHA` writes).
- **Checks:**
  - tests/checks/12: `entries.mjs: resolved is an array of strings and normalize keeps it` — `resolved: ["Should X
    default to off?"]` validates and survives `normalize`; `resolved: "x"` gives `resolved: not an array of strings`;
    an entry without it normalizes without the key.
  - tests/checks/12: `entries.mjs: the pack drops a question a later entry resolves` — pure: the question shows with
    no later `resolved`, and not with one (whitespace differences still match; an earlier entry's `resolved` doesn't).
  - tests/checks/38: `a resolved question is gone from the next context.md` — run with `STUB_ASK=C STUB_RESOLVE=C`:
    `05-C.context.md` has `Question (C): Should C default to off?` and the next `*-verify-M2.context.md` has no
    `Question (` line.
  - tests/checks/38: `a project discovery is listed under Promote to Gotchas until CLAUDE.md carries it` — run with
    `STUB_PROJECT_FACT=A STUB_GOTCHA=B`: `02-B.context.md` has `## Promote to Gotchas` and the fact ending
    `→ entries.jsonl:<n>`; `03-A.context.md` (after B wrote the line) has no `Promote to Gotchas` part.
- **Decision file** `journal/decisions/<date>-resolved-and-project-facts.md` (finding · choice · rejected).

## M3-04 · `Current rules` and the verify cap (§F3, the 2026-10-26 addition)

- **`currentRules(store, input)`** (pure, `lib/memlint.mjs`) → `[{text, ref}]`, newest first:
  - **dir store** (`input` = `[{name, text}]`, the `.md` files): sorted by name, descending (the date prefix makes
    that newest first); `text` = the first `# ` line without `# `; `ref` = `<path>/<name>`. A file without a `# ` line
    is skipped.
  - **file store** (`input` = the file's text): a decision line is a heading `^#{2,4} D<n>\b`, a bullet
    `^- \*\*D<n>\b` or a table row `^\| *D<n> *\|`. `text` = `D<n> …` from that line (Markdown `**`, `*` and table
    pipes reduced to text; a heading adds its first non-blank line after it); `ref` = `<path>:<line>`. Sorted by `n`
    descending; a repeated `n` keeps its last line.
  - `readRules(worktree)` (IO): `decisionsStore`, then reads the directory or file; `[]` when there is no store or it
    doesn't exist.
- **New part `Current rules`** (every pack, last, part 7): each `- <text> → <ref>`, an item cut to `RULE_BYTES = 240`.
  **Share:** at most `cap / 4` bytes and never more than the room left. Rules past the share are **not** counted in
  `items left out` (they live in the store, not entries.jsonl); the part ends `_<k> older rules: <path>._` instead. When
  the pack already stopped, the part is left out whole. `pack(entries, { …, rules = [], rulesFrom = "" })`; the CLI
  fills them from `readRules(<worktree>)` under the same `.harness/runs/<run>` guard as the gotchas.
- **Verify cap:** `lib/config.sh` gains `CONTEXT_PACK_BYTES_VERIFY=16384` beside `CONTEXT_PACK_BYTES`;
  `templates/user/config.sh` documents both as commented lines. `context <id> [<cap>]` (default
  `$CONTEXT_PACK_BYTES`); `verify()` calls `context "$m" "$CONTEXT_PACK_BYTES_VERIFY"`. Coding packs stay at
  `CONTEXT_PACK_BYTES`.
- **Failed rows first:** in a milestone pack, part 1's order becomes `Verify … found` rows, then dead ends, then
  questions, then entries. A feature pack keeps dead ends first (ENPK asserts it).
- **Seven parts**, in priority order: earlier attempts · Michael's answers · discoveries · Promote to Gotchas (coding
  only) · what it builds on · lately in the run · current rules.
- **Fixtures:** `tests/fixtures/decisions-rane.md` (rane-one-mixxx `docs/decisions.md` lines 1-16 as committed:
  header, D1-D3 bullets), `tests/fixtures/decisions-voice-concierge.md` (two `## D<n> *default*:` headings with their
  first line, trimmed), `tests/fixtures/decisions-dj.md` (the `| # | Decision | Replaces |` table with D24-D26 rows,
  trimmed). Copied from the files, never typed.
- **Stub flag** `STUB_VERIFY_FAIL_ROW=1`: verify M1 round 1's entry adds `{feature: "A", step: 1, ran: "check", saw:
  "A fails", holds: false}`, and A's coding sessions record a dead end, so the order is tested against a real
  `Dead end` line.
- **Checks:**
  - tests/checks/12: `memlint: currentRules reads a directory store and the three file shapes newest first` — pure,
    on the three fixtures and a two-file directory.
  - tests/checks/38: `context.md lists the decisions store's rules newest first` — the stub project with
    `docs/decisions.md` from `decisions-rane.md` (D1, D2, D3) committed before the run: the next context.md has
    `## Current rules` as its last part with `D3`, `D2`, `D1` in that order.
  - tests/checks/38: `CONTEXT_PACK_BYTES=1024 holds for coding packs and verify packs get their own cap` — the stub
    project's `.harness/config.sh` sets `CONTEXT_PACK_BYTES=1024`: every `NN-*.context.md` ≤ 1024 bytes and one has
    the `items left out` line; a `*-verify-M1.context.md` is over 1024 bytes and ≤ 16384 (the observable form of
    "may exceed 8192": the stub's packs are never that large).
  - tests/checks/38: `a verify pack lists failed rows before dead ends` — run with `STUB_VERIFY_FAIL_ROW=1`: the
    round-2 `*-verify-M1.context.md` has `Verify M1 found (A step 1)` on an earlier line than its first `Dead end`.
- **Docs:** `docs/architecture.md` §4's Context pack row lists the seven parts, the shares and
  `CONTEXT_PACK_BYTES_VERIFY`; §10 names the setting. Decision file `journal/decisions/<date>-pack-current-rules.md`
  (finding · choice · rejected: a model-written summary, counting rules in `items left out`, rules ahead of the
  journal parts, one cap for both kinds).

## M3-05 · Review

As its steps say: the M3 diff from the commit before M3-01 into `$HARNESS_SCRATCH/m3-review.diff`, one Opus subagent,
Critical and Important fixed RED→GREEN, findings in `docs/plans/2026-10-26-M3-review.md`.

## Defaults taken (recorded in each feature's decision file, `D<n> *default*` there)

1. A replaced Gotchas line counts as one edit (`~1`), not `+1 -1`.
2. `resolved` matches a question exactly after whitespace flattening, against later entries only.
3. `Promote to Gotchas` is in coding packs only, shares `cap / 8`, and a `project` discovery leaves `Discoveries for
   this feature` in a coding pack.
4. "Carried" means a Gotchas line contains the discovery's first 40 characters (not only starts with them).
5. `Current rules` items over their `cap / 4` share are summarized by one `older rules` line, not counted as items
   left out; the file-store parser takes the three shapes the projects use.
6. The verify cap is passed by `verify()` as `context`'s second argument; a project raising `CONTEXT_PACK_BYTES`
   above 16384 does not raise the verify cap (set both).

## Step changes proposed (for Michael; the list is not edited)

- M3-03 step 4 should also name `resolved` in `prompts/coding.md`, and M3-03 should write
  `journal/decisions/<date>-resolved-and-project-facts.md` (a behaviour change gets a decision file).
- M3-04 step 3's "byte count may exceed 8192" can't be observed in a stub run (its packs stay small); the check
  above proves the verify cap with `CONTEXT_PACK_BYTES=1024` instead.
