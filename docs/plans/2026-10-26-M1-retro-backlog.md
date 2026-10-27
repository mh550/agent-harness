# M1 · The retro backlog (plan, 2026-10-26)

Run `agent-harness-2026-10-25-memory`, feature M1-01. Spec: `docs/specs/2026-10-25-memory.md` § M1 (retro-followups
§E). Brief: M1 first, sessions never write `ledger/` (the driver and the `harness` CLI do), the build never imports the
seed into the real ledger, test-first, a decision file per behaviour change, never park.

Checked against `main` at `fb2cbc3` (this branch's base). `tests/checks/` exists (34 files): new checks go in the two
files named below, each name also on one line of `tests/fixtures/check-names.txt` (`LC_ALL=C sort -u` order).

One feature per item, in this order: M1-02 (pure `lib/backlog.mjs`), M1-03 (CLI + seed file), M1-04 (retro emits,
driver merges), M1-05 (retro prompt carries the backlog, debrief reads it), M1-06 (review). Each check is written
first and watched failing.

## What main already has

- **`retro()`** (`lib/driver.sh:499-511`): `rstart=HEAD`, renders `prompt retro` with `HARNESS_SUMMARY`,
  `HARNESS_STATE`, `HARNESS_LEDGER`, `HARNESS_END_REASON` (`:502`), runs the session (`:504`), then
  `restrict "$rstart" nothing retro` (`:505`) and notes `retro: reverted edits (it is read-only): <paths>` (`:507`).
  The retro's final message goes to `$SCRATCH/retro.md` and is copied into the run record by the driver (`:508-509`).
- **`restrict <base> nothing <who>`** (`lib/driver.sh:87-98`) reverts **every** path changed since `<base>`, the run
  record included: an added file is `git rm`'d and deleted. So anything the retro writes under the run directory is
  gone by the time `finish()` reaches the ledger. Retro sessions run `--permission-mode auto`; read-only is enforced
  only by `restrict`.
- **`ledger()`** (`lib/driver.sh:513-525`): copies the run record to `$LEDGER/<project>/<run>/`, then in a subshell
  holding `flock 9` on `$STATE_ROOT/ledger.lock` appends `runs.jsonl` and, when `LEDGER_COMMIT=1` and `$LEDGER` is in
  a git checkout, `git -C "$LEDGER" add -- … && git -C "$LEDGER" commit -q -m "ledger: …" -- <paths>`.
- **`finish()`** (`lib/driver.sh:527-569`): … `retro` (`:551`), `commit_all "HARNESS: summary and retro"`, `ledger`
  (`:554`), `scratch_done` (`:555`, deletes `$SCRATCH` unless `KEEP_SCRATCH=1`), and the closing
  `[[ -n $(git status --porcelain -- "$RUN_DIR") ]] && commit_all "HARNESS: run end notes"` (`:566`), which commits a
  note written inside `ledger()`.
- **The suite's ledger**: `tests/lib.sh` sets `HARNESS_LEDGER=$T/ledger` (not a git repo) and `LEDGER_COMMIT=0`,
  `KEEP_SCRATCH=1`; `HARNESS_STATE` is the throwaway state root, so `$HARNESS_STATE/ledger.lock` is the lock.
- **The debrief's gatherer** (`lib/debrief.sh:164-165`): `## Earlier retros (newest first; for proposals seen in two
  or more)` and `ls -t "$LEDGER"/*/*/retro.md | head -20 | fence`. `prompts/debrief.md:63-66`
  (`## For the next interactive session`) asks for "retro proposals that appear in **two or more** retros".
- **Prompt variables**: `lib/render.mjs` fills `{{NAME}}` from `HARNESS_NAME`, empty when unset. The retro template
  has no `{{SECTIONS}}` line and no shared static prefix (its run id is on line 3), so a run-specific `{{BACKLOG}}`
  costs no cache.
- **The stub's retro branch** (`tests/stub-claude.sh:154-159`): logs `retro`, `STUB_LEAVE_RETRO`,
  `STUB_RETRO_EDITS=1` (writes `retro-hack.txt`, appends to `progress.md`), then its final message. Check 24 (`retro
  edits reverted`) greps `retro: reverted` and the missing `retro-hack.txt` only, so an extra reverted path is safe.
- **CLI pattern**: `bin/harness:516-519` `exec`s `lib/debrief.sh`, `lib/sync.sh`, …; `lib/sync.sh` loads config with
  `source "$HARNESS_HOME/lib/config.sh"; harness_config /nonexistent` (gives `LEDGER_COMMIT`). `bin/harness`'s
  `STATE_ROOT=${HARNESS_STATE:-${XDG_STATE_HOME:-$HOME/.local/state}/harness}` is the same directory as the driver's
  `$STATE/../..`.

## Defaults taken (recorded in `journal/decisions/2026-10-26-retro-backlog.md` by M1-04)

- **Unset links are `null`**, not `""`; rows are written with a fixed key order
  `id, title, first_seen, runs_seen, status, spec, pr, note`, one compact JSON object per line, `\n`-terminated.
- **Status order** for listing: `proposed, specced, queued, merged, dropped` (spec: `proposed` first); within a
  status, more `runs_seen` first, then older `first_seen.date`, then `id`.
- **A proposals file is valid** when it is a JSON array of at most 10 objects, each with `id` matching
  `^[a-z0-9]+(-[a-z0-9]+)*$` (at most 60 characters) and a non-empty string `title`; `evidence` is optional (a string).
  Anything else rejects the **whole** file (as E4 rejects a whole `entry.json`). A repeated id within one file counts
  once. `evidence` is not stored in the row: the run's copy of `retro-proposals.json` (in the ledger's run directory)
  keeps it.
- **A new row's title** is the proposal's; a known id keeps its title (Michael's `set --note` or an import changes
  what is shown, a retro doesn't).
- **Seed rows** carry `first_seen: {run: "seed", date: "2026-10-25"}`, `runs_seen: []`, and in `note` the retro count
  the spec gives where it gives one (`proposed in 8 retros` for review-cost, `6 retros` for test-counts, `4 retros`
  for carry-on-past-given-up).
- **No proposals file after a retro** (`RETRO=1`): one note, `backlog: the retro wrote no retro-proposals.json`.
  `RETRO=0`: nothing.
- **The reverted-edits note leaves out `retro-proposals.json`**: it is the retro's one sanctioned output and the driver
  puts it back into the run record at once (as it does `retro.md`), so the ledger's copy of the run keeps the evidence.

## Item 1 · M1-02: `lib/backlog.mjs`, pure (checks in `tests/checks/35-backlog-pure-m1.sh`)

The row: `{id, title, first_seen: {run, date}, runs_seen: [run ids], status, spec, pr, note}`, status one of
**`proposed | specced | queued | merged | dropped`**, `id` a kebab-case slug.

Exported, pure (no fs; unit-checkable with `node --input-type=module -e`):

| function | does |
|---|---|
| `STATUSES` | `["proposed", "specced", "queued", "merged", "dropped"]` (also the list order) |
| `parseRows(text)` → rows | JSONL → rows; blank lines skipped; a bad line throws `line <n>: <why>` |
| `formatRows(rows)` → text | rows → JSONL in the fixed key order |
| `validateProposals(text)` → `{ok, proposals}` \| `{ok: false, why}` | the shape above; `why` is one line (`not JSON: …`, `item 2 has no id`, `item 1 id "Foo Bar" is not a kebab-case slug`, …) |
| `mergeProposals(rows, proposals, run, date)` → `{rows, added, seen}` | a new id appended as `proposed` with `first_seen {run, date}`, `runs_seen [run]`; a known id gets `run` added to `runs_seen` once, status, title and links unchanged |
| `setStatus(rows, id, status, {spec, pr, note})` → rows | throws `unknown id <id>` / `status must be one of …`; only the given links change |
| `orderRows(rows)` → rows | the list order above |
| `importRows(rows, incoming, date)` → `{rows, added, updated}` | by id: new → appended (validated id and status; a missing `first_seen` becomes `{run: "import", date}`, missing `runs_seen` `[]`); known → takes `status, spec, pr, note`, keeps `first_seen` and `title`, `runs_seen` the union in first-seen order |
| `listLines(rows, {maxBytes})` → text | one line per ordered row, `<id> · <status> · seen <n> · <title>` then ` · spec <s>`, ` · pr <u>`, ` · note <t>` when set; `(empty)` for none; past `maxBytes`, whole lines only and `… (<n> more rows)` |

CLI (header lines like `lib/features.mjs`'s; every command takes explicit paths; writes go to `<store>.tmp` then
`rename`, so a reader never sees half a file; the driver and `lib/backlog.sh` hold the lock, not the `.mjs`):

```
merge <store> <proposals.json> <run> <date>   → "backlog: <a> new, <s> seen again", exit 0; invalid →
                                                "backlog: retro-proposals.json invalid: <why>", exit 1, store untouched
set <store> <id> <status> [--spec <p>] [--pr <u>] [--note <t>] → "backlog: <id> → <status>", exit 0; error: one line, exit 1
list <store> [--jsonl] [--max-bytes <n>]      → listLines (or the ordered rows as JSONL); a missing store is (empty)
import <store> <file.jsonl>                    → "backlog: imported <n> rows (<a> new, <u> updated)"; a bad line: exit 1
validate <proposals.json>                      → exit 0, or the why line and exit 1
```

Checks (names exact; each one line in `check-names.txt`):
- `backlog merge: a new id becomes one proposed row first seen in its run` (`new-thing`, run `r1`, `2026-10-26`)
- `backlog merge: a known id adds its run to runs_seen once, status unchanged` (`r2`, then `r2` again)
- `backlog validate: bad JSON, a missing id or a non-slug id exits 1 with one line, rows unchanged` (`{not json`)
- `backlog set: specced --spec flips the status and records the spec; an unknown id or status exits 1`
- `backlog list: proposed first, then more runs_seen first within a status`
- `backlog import: 8 rows into an empty store, then again 8 (idempotent by id)`
- `backlog import: a known id takes status, spec, pr and note, keeps first_seen, unions runs_seen`

A red-phase check compares counts, ids or one field, never two whole files with `deepEqual`.

## Item 2 · M1-03: `harness backlog` and the seed (checks in `tests/checks/36-run-16-retro-backlog.sh`)

`bin/harness` dispatches `backlog) shift; exec "$HARNESS_HOME/lib/backlog.sh" "$@" ;;` and its header lists:

```
harness backlog [list]                                   the retro backlog (ledger/retro-backlog.jsonl): proposed first, most seen first
harness backlog set <id> <status> [--spec <path>] [--pr <url>] [--note <text>]
                                                         move an item: proposed|specced|queued|merged|dropped
harness backlog import <file.jsonl>                      merge rows by id (the seed: docs/specs/2026-10-25-memory.backlog-seed.jsonl)
```

`lib/backlog.sh` (one-line usage header, `set -uo pipefail`): `LEDGER=${HARNESS_LEDGER:-$HARNESS_HOME/ledger}`,
`STORE=$LEDGER/retro-backlog.jsonl`, `STATE_ROOT` as `bin/harness` computes it, config by
`harness_config /nonexistent`. `list` reads without the lock (writes are atomic renames). `set` and `import` run
`node lib/backlog.mjs …` inside `( flock 9 …; commit ) 9> "$STATE_ROOT/ledger.lock"`; the import path is resolved
before anything else (relative to the caller's directory). Commit only when `LEDGER_COMMIT=1` and `$LEDGER` is in a
git checkout: `git -C "$LEDGER" add -- retro-backlog.jsonl && git -C "$LEDGER" commit -q -m "ledger: backlog <set
<id> <status> | import <file>>" -- retro-backlog.jsonl`, else nothing and exit 0. A missing or extra argument, an
unknown subcommand: one usage line, exit 1, the store byte-identical. `mkdir -p "$LEDGER"` before a write.

**The seed** `docs/specs/2026-10-25-memory.backlog-seed.jsonl`, exactly the spec's table (spec fields as written):

| id | title | status | spec |
|---|---|---|---|
| `test-counts` | real test counts per runner | queued | retro-fixes R1, this spec M5 |
| `review-cost` | size and route the milestone review | queued | retro-fixes R2, this spec M6 |
| `step-lint` | lint feature steps at init | queued | retro-fixes R3 |
| `carry-on-past-given-up` | a given-up feature doesn't end the run | queued | retro-fixes R10 |
| `verify-fresh-suite` | verify never trusts the cache | queued | retro-fixes R4 |
| `merge-before-deadline` | verify and merge a finished milestone at the deadline | queued | retro-fixes R5 |
| `no-retry-on-denial` | don't retry a session that stopped on a permission question with nothing changed | proposed | — (`null`) |
| `session-memory-cap` | cap and stop each session's processes | queued | resource-lifecycle L1–L2 |

Seven `queued`, one `proposed`. README gives Michael the one command, run on the live checkout:
`harness backlog import docs/specs/2026-10-25-memory.backlog-seed.jsonl`, and says the build never ran it.

Checks:
- `harness backlog set flips test-counts to specced and list shows the spec` (store seeded by a `printf` row,
  `--spec docs/specs/2026-10-21-retro-fixes.md`)
- `harness backlog import of the seed file gives 8 rows, and 8 again on a second import`
- `harness backlog set with an unknown id, a bad status or a missing argument exits 1, store byte-identical` (`cmp`)
- `harness backlog with no store prints (empty)`
- after the file: `git status --porcelain -- ledger/` in this worktree empty is the M1-03 step's own command, not a
  check (the suite's ledger is `$T/ledger`).

## Item 3 · M1-04: the retro emits, the driver merges

**Where the driver reads `retro-proposals.json`.** The retro writes `$RUN_DIR/retro-proposals.json` (its one file).
`restrict` then deletes it, so:

1. **In `retro()`, after the session and before `restrict`** (`lib/driver.sh:504-505`): `rm -f
   "$SCRATCH/retro-proposals.json"` (a `KEEP_SCRATCH` copy from an earlier segment), then copy the run directory's
   file to **`$SCRATCH/retro-proposals.json`** (`$SCRATCH` is `HARNESS_SCRATCH`) when it exists and differs from the
   copy committed at `rstart` (`git show "$rstart:$RUN_DIR/retro-proposals.json"`; a continued run's earlier
   proposals are not merged twice).
2. `restrict "$rstart" nothing retro` reverts everything, the proposals file included; the reverted-edits note leaves
   that one path out. Then `cp "$SCRATCH/retro-proposals.json" "$RUN_DIR/"`, as `retro.md` is copied (`:509`); the
   `HARNESS: summary and retro` commit carries it and `ledger()`'s `cp -r` puts it in the ledger's run directory.
3. **In `finish()`, inside `ledger()`'s `flock 9` block, before the ledger commit**: when
   `$SCRATCH/retro-proposals.json` exists,
   `note "$(node "$HARNESS_HOME/lib/backlog.mjs" merge "$LEDGER/retro-backlog.jsonl" "$SCRATCH/retro-proposals.json" "$RUN_ID" "$(date +%F)")"`:
   one line either way (`backlog: <a> new, <s> seen again` or `backlog: retro-proposals.json invalid: <why>`), the
   store untouched when invalid, the run goes on. `retro-backlog.jsonl`, when it exists, joins the `git add` and
   `git commit --` paths. The merge happens before `scratch_done` (`:555`) deletes the scratch copy. With `RETRO=1`
   and no file: `backlog: the retro wrote no retro-proposals.json`. The note lands in `harness-log.md` after the
   ledger copy and is committed by the `run end notes` commit (`:566`).

**`prompts/retro.md`**: "do not edit, create, commit or push anything" becomes "… anything, except one file:
`{{RUN_DIR}}/retro-proposals.json`", with its shape: a JSON list of `{id, title, evidence}`, at most three items (the
ranked proposals of `## Proposed harness changes`), ids kebab-case.

**The stub**: `tests/stub-claude.sh`'s retro branch gains **`STUB_RETRO_PROPOSALS=<id>[,<id>…]`**: writes
`[{"id": "<id>", "title": "stub proposal <id>", "evidence": "stub retro"}, …]` to
`$HARNESS_RUN_DIR/retro-proposals.json`; `STUB_RETRO_PROPOSALS=bad` writes `{not json`. `STUB_RETRO_EDITS=1` also
writes `ledger/retro-backlog.jsonl` inside the worktree. Both documented in the stub's header comment.

Checks (in `36-run-16-retro-backlog.sh`, one shared `$T`, so the second run sees the first's ledger):
- `backlog run: a retro proposal lands as a proposed row, noted 1 new, 0 seen again`
  (`STUB_RETRO_PROPOSALS=no-retry-on-denial`; `first_seen.run` is the run id)
- `backlog run: the same id from a second run adds it to runs_seen, noted 0 new, 1 seen again`
- `backlog run: a malformed retro-proposals.json is noted, the run finishes, the backlog unchanged`
  (`backlog: retro-proposals.json invalid`, `runs.jsonl` has the run, `cmp` of the store before and after)
- `backlog run: restrict reverts a retro's edit to the backlog, and the merge still lands`
  (`STUB_RETRO_EDITS=1`: the `retro: reverted edits` line names `ledger/retro-backlog.jsonl`, the file is gone from the
  worktree, and the proposal's row is in `$T/ledger/retro-backlog.jsonl`)

The check-file name says `run-16` (given by the feature list); `run 16` is already the parking run's label in
`13-run-2-michael-sets-desk.sh:261`, so these checks say `backlog run`, not `run 16`.

Decision file `journal/decisions/2026-10-26-retro-backlog.md`: finding (spec M1's), choice (the driver and the CLI are
the only writers; proposals travel as data through the scratch directory past `restrict`; a bad file is skipped whole
as E4 skips a bad `entry.json`; the defaults above), rejected (the retro editing the backlog: a session never writes
`ledger/`; parsing proposals out of `retro.md`'s prose; an LLM curator).

## Item 4 · M1-05: the retro sees the backlog, the debrief reads it

- **`retro()`** exports `HARNESS_BACKLOG=$(node lib/backlog.mjs list "$LEDGER/retro-backlog.jsonl" --max-bytes 6000)`
  beside the other variables at `lib/driver.sh:502`. Lines start `<id> · <status> · seen <n>`; `(empty)` with no store.
- **`prompts/retro.md`** gains `## Backlog` (before "Write, …") with `{{BACKLOG}}` in a fence and three rules: reuse
  an existing id when you re-raise one; for a `specced`, `queued` or `merged` item cite its status (and spec or PR)
  instead of re-arguing it; coin a new slug only for a new proposal. `## Proposed harness changes` asks for each
  change's backlog id instead of "whether an earlier retro proposed it already (say which run)"; the `Earlier runs`
  read line keeps `runs.jsonl` and drops the `*/*/retro.md` glob (the backlog replaces it).
- **The only debrief lines that change**: the `## Earlier retros` gatherer block, `lib/debrief.sh:164-165` (on
  `main`), becomes
  `echo; echo "## Retro backlog (ledger/retro-backlog.jsonl)"; echo` and
  `node "$HARNESS_HOME/lib/backlog.mjs" list "$LEDGER/retro-backlog.jsonl" --jsonl --max-bytes 6000 | fence`
  (two lines, in place, so A2's later move of the gatherer stays mechanical; no `ls` of `retro.md` files); and
  `prompts/debrief.md`'s **`## For the next interactive session`** section (`:63-66`): merge conflicts and held or
  refused merges as now, then the open `proposed` items of the Retro backlog, most `runs_seen` first (id, title, times
  seen), and any item a run of this queue re-raised (its run in `runs_seen`) though already `specced` or `queued`
  (with its spec): no longer "retro proposals that appear in two or more retros". Nothing else in either file.
- Docs: `docs/architecture.md` §4 gains the row (`<harness>/ledger/retro-backlog.jsonl` · writers: the driver's
  `finish()` (`ledger()`) and `harness backlog` · readers: the retro prompt (`{{BACKLOG}}`), the debrief · committed:
  yes, harness repo); §16 says the debrief reads the backlog; README's `## Debrief` ("retro proposals seen in two or
  more retros") says the backlog's open items and re-raised ones; README and the `bin/harness` header gain
  `harness backlog`.

Checks:
- `backlog run: the rendered retro prompt carries test-counts · specced` (ledger seeded with `test-counts` as
  `specced` before the run; grep `$HARNESS_STATE/proj/<run>/prompt-retro.md`)
- `debrief --dry-run gathers the retro backlog, not Earlier retros`

## Item 5 · M1-06: review

`git diff 2ad459f..HEAD -- . ':!.harness/runs' > $HARNESS_SCRATCH/m1-review.diff` (2ad459f: the commit before
M1-01), one Opus reviewer reading it from the file, findings only; Critical and Important fixed RED → GREEN; findings
and fixes in `docs/plans/2026-10-26-M1-review.md`; `bash -n` on `lib/driver.sh lib/backlog.sh lib/debrief.sh
bin/harness tests/stub-claude.sh tests/checks/36-run-16-retro-backlog.sh`, `node --check lib/backlog.mjs`.

## Live step (build-only policy: for Michael, never run by the build)

On the live checkout, after M1 is merged and no run is alive:
1. Dry look: `node lib/backlog.mjs list docs/specs/2026-10-25-memory.backlog-seed.jsonl` (reads the seed as a store;
   writes nothing) → 8 lines, `no-retry-on-denial · proposed` first.
2. `harness backlog import docs/specs/2026-10-25-memory.backlog-seed.jsonl` → `backlog: imported 8 rows (8 new, 0
   updated)` and one `ledger: backlog import …` commit; `harness backlog` lists 8.
3. Undo: `git revert <that commit>` in the live checkout (the store is one committed file), or
   `harness backlog set <id> dropped --note "<why>"` for one row.
