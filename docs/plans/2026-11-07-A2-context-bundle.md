# A2 · Context bundle and ID glossary (plan, 2026-11-07)

Run `agent-harness-2026-11-07-3`, feature A2-01. Spec: `docs/specs/2026-10-22-n8n-events.md` §A2 and its Contracts.
Read against `main` at 201d4a9 (A1 merged), so every line reference below is today's. The bundle is half a contract:
n8n-home is live against it (§4.3 of its `docs/specs/2026-10-22-harness-reporter.md`), and its code pins three things
this plan keeps (read in `~/projects/n8n-home`, never changed):

- `lib/intake.js` `contextPaths`: an event's `context` must be the **absolute path of `context.json`**,
  `<STATE_ROOT>/events/<dir>/context.json`, no `.`/`..`/empty segment; `context.md` is read beside it; `<dir>` must
  match `^[A-Za-z0-9-]{8,64}$` (`ID_GUARD`). Its fixtures (`fixtures/bundles/<event id>/`) name the bundle directory
  by the **event's own id**, and `context.json`'s `id` is that id too.
- `lib/intake.js:32`: **a `debrief` event without a `context` string is refused** (`a debrief needs a context path`),
  so today's A1 debrief event (context null) always falls back to ntfy. A2-04 is what makes the debrief route work.
- `lib/card.js`: reads `runs[].parked[]` (`feature`, `why`, `question`), `glossary[]` (`id`, `kind`, `text`) and
  `unresolved[]` (strings), and puts `context.md` verbatim (cut) into the card prompt.

Its fixture bundles (`fixtures/bundles/*/context.{json,md}`, "shaped from the spec, replaced by a captured bundle
once Run A merges") also show the glossary's markdown line `- **<id>** (<kind>): <text> (<source>)`, a final
`Unresolved: <ids>` line, and heading texts that run on into the paragraph under the heading
(`M8: lifecycle (ownership, replacement, play-now). M8 follows …`). This plan builds to those.

**In one paragraph.** A2-02 writes `lib/glossary.mjs`: pure functions that find feature, milestone and decision IDs
in a text and resolve them against a feature list and a project's docs, unit-tested on fixtures copied from
dj-crate-streaming. A2-03 moves the debrief's gatherer, byte for byte, into `lib/context.sh` (`context_runs`), adds
the read-only `harness context <run-id> | --since <ts> [--out <dir>]`, and appends a `## Glossary` (built by a new
`lib/context.mjs` from glossary.mjs) to the bundle's `context.md` and to the debrief's context. A2-04 makes the same
node call write `context.json` in the spec's shape, prunes `events/` bundles older than 30 days, and has
`notify_event` build the bundle before the POST so the event's `context` names a `context.json` that exists. With
`EVENT_URL` unset nothing new runs but the glossary section at the end of the debrief's context.

## 1. A2-02 · lib/glossary.mjs and its fixtures

**Files:** lib/glossary.mjs (new), tests/unit/glossary.test.mjs (new), tests/fixtures/glossary/ (new, §1.3),
tests/fixtures/check-names.txt, check-names-fast.txt.

### 1.1 The rules, verbatim from the spec (§A2 "Glossary, by code (no model)")

- features, `\b[A-Z]{1,2}\d+-\d+\b` (`E2-02`, `N1-03`, `H3-04`) → `feature_list.json` (`description`, first 300
  chars, and its `milestone`);
- milestones, `\b[A-Z]{1,2}\d+\b` not followed by `-\d` (`M8`, `H3`, `N1`, `S1`) → the feature list's milestone ids,
  then headings in the project's docs (`# M9`, `## 9. M8`, `## H1 · …`);
- decisions, `\bD\d+\b` and `\bD-H\d+\b`, **classified before milestones** (`D35`, `D-H32`, `D24 *default*`; a
  project whose milestones start with D resolves against both and keeps what matches) → markdown table rows
  `| D24 | … |` and headings `### D-H1 · …` in the project's `CLAUDE.md`, `README.md`, `docs/**/*.md`,
  `journal/decisions.md`, and `journal/decisions/*.md` titles; the first 300 chars of the row's text, markdown
  stripped;
- an ID written differently in two places → **every match, newest file first**; an ID nothing resolves →
  `unresolved` (**never guessed**); `source` is `<path>:<line>`.

### 1.2 How the code applies them

**Finding (`findIds(text, known = [])` → `[{ id, kind }]`, unique, in order of first appearance).** Three passes,
each masking the spans it took so a later pass can't see inside them:

1. decisions: `/\bD-H\d+\b/g` then `/\bD\d+\b/g` → `kind: "decision"` (masks the `H1` in `D-H1`);
2. features: `/\b[A-Z]{1,2}\d+-\d+\b/g` → `kind: "feature"`;
3. milestones: `/\b[A-Z]{1,2}\d+\b(?!-\d)/g` → `kind: "milestone"` (`N1` of `N1-01` is masked by pass 2 and refused
   by the lookahead anyway).

*default* (an addition the spec doesn't name): `known` is the run's feature ids and milestone ids from its
`feature_list.json`; an exact, word-bounded occurrence of one is taken in pass 2 (a feature id) or pass 3 (a
milestone id) even when the spec's regexes miss its shape. dj's real lists hold `N1F-01`, `S2-05a`, `S2-R1`, `N1F`,
which the verbatim regexes never see (not even as unresolved). This is an exact match against the list, not a guess;
`findIds(text)` with no `known` is the spec's rules alone. The `Q99` of the checks is never in a `known` list.

**Resolving (`resolveIds(ids, { worktree, featureList }, reader = fsReader(worktree))` →
`{ glossary: [{ id, kind, text, source }], unresolved: [id] }`).**

- *Feature* (`kind: "feature"`): the feature-list entry whose `id` equals it. `text` = its `description`, markdown
  stripped, cut at 300 characters (code points), then ` (milestone <m>)` when it has one. `source` =
  `<abs feature_list.json>:<line>`, the line holding `"id": "<id>"` (`/"id":\s*"<id>"/`), else `:1`.
- *Milestone* (`kind: "milestone"`): first the feature list, when any feature has `milestone == id`: `text` =
  `milestone in feature_list.json: <ids of its features, at most 8, then "…"> (<n> features, <k> passing)`, `source` =
  the line of its first feature's `"id"`. Then every doc heading that names it (below), newest file first.
- *Decision* (`kind: "decision"`): every doc table row and heading that names it, newest file first. A `D<n>` also
  runs the milestone resolution and keeps both kinds' matches (`D1` a decision row in docs/decisions.md and a
  milestone in the list: two entries). `D-H<n>` is a decision only.
- **The doc files** (`reader.files()` → `[{ path, mtimeMs }]`, paths relative to the docs root): `CLAUDE.md`,
  `README.md`, `docs/**/*.md`, `journal/decisions.md`, `journal/decisions/*.md` (title line only: the first `# `
  line), and `decisionsStore(worktree)`'s path (lib/memlint.mjs, M2's store) when it lies outside those. No other
  file. **Newest first** = `mtimeMs` descending, ties by path (`LC_ALL=C` order); *default* (a fresh checkout gives
  every file one mtime, so ties fall to path order; git's dates would cost a `git log` per file).
- **A table row** names an ID when its first cell starts with it, word-bounded: `/^\|\s*<ID>(?![\w-])([^|]*)\|(.*)$/`
  (`| D24 |`, `| D36 *default* |`, `| D24 (\`ours:…\`) |`). `text` = the rest of the first cell when not empty
  (`*default*` → `default`), then the remaining cells, trimmed and joined with ` · `, stripped, cut at 300.
- **A heading** names an ID when the ID opens it, after an optional `<n>. `:
  `/^#{1,6}\s+(?:\d+\.\s+)?<ID>(?![\w-])(.*)$/` (`# M9`, `## 9. M8 (built)`, `# M8: lifecycle …`, `## H1 · …`,
  `### D-H1 · …`). `text` = the heading without its `#`s, then `. ` and the lines under it up to the next heading,
  joined with spaces (the heading alone when nothing follows), stripped, cut at 300. A heading that only mentions
  the ID later (`### New with M8`) does not name it.
- **Markdown stripped** (`strip(s)`): `[text](url)` → text; `**`, `__`, backticks and a leading `#`/`>`/list marker
  removed; single `*x*` → x; runs of whitespace → one space; trimmed. Underscores inside words stay.
- `source` paths are absolute (`<docs root>/<path>:<line>`, 1-based). Duplicates (same id, kind and source) once.
- **Unresolved**: an ID with no entry of any kind, in `findIds` order. Nothing near (`Q9`, `Q990`, a heading that
  mentions `Q99` later) is ever taken: every pattern is the ID itself, word-bounded.

**Exports** (one-line usage header; pure apart from `fsReader`): `findIds`, `resolveIds`, `glossaryMarkdown`,
`strip`, `fsReader`. `glossaryMarkdown({ glossary, unresolved }, maxBytes = Infinity)` → `## Glossary`, a blank
line, one `- **<id>** (<kind>): <text> (<source>)` line per entry, then (when any) a blank line and
`Unresolved: <ids joined by ", ">`; `(no IDs found)` when both are empty. Lines are kept whole up to `maxBytes`
(UTF-8); when some don't fit it ends with `… (<n> more; context.json lists every one)`; when not even the heading
fits it returns `""`. CLI: `node lib/glossary.mjs <worktree> <feature_list.json> < text` prints
`JSON.stringify({ glossary, unresolved }, null, 2)` (the worktree is the docs root; `known` from the list).

### 1.3 Fixtures (tests/fixtures/glossary/, copied read-only)

The dj project's checkout is `~/projects/dj-crate-streaming`: `project_dir dj-crate-streaming` resolves a bare name
by the newest run's `PROJECT_DIR` (which a session may not read: it is under `~/.local/state/harness`), else
`$HARNESS_PROJECTS/<name>`, the same checkout. A2-02 records `git -C ~/projects/dj-crate-streaming status
--porcelain` before and after and copies with `cp`/`sed` only. Every file gets one provenance line in
`tests/fixtures/glossary/README.md` (`<fixture> · <source path>:<lines> at <commit> · what was cut or changed`).

| Fixture | From | Holds | Resolves |
|---|---|---|---|
| `feature_list.json` | dj `.harness/runs/dj-2026-10-17/feature_list.json` | the features `N1-01`…`N1-05`, `N1F-01`, `H3-02`, `H3-04` as they are (pretty-printed, 2-space), each `description` cut to 300 chars | `N1-01` (line of its `"id"`), `N1` from the list, `N1F-01` via `known` |
| `feature_list-d.json` | planted | `{"features":[{"id":"D1-01","milestone":"D1",…}]}` (one feature) | `D1` as a milestone |
| `wt/docs/decisions.md` | dj `docs/decisions.md` lines 1–8 (the header), 9–13 (`## D1–D23` and the `D1` row), 37–41 (`## D24 on`, the table head, `D24`) and line 53 (`D36 *default*`); dj at 429dd96 | the D table | `D24`, `D36`, `D1` (row) |
| `wt/docs/research/2026-10-22-soulsync/README.md` | dj, the same file: its table head and line 179 (`\| D24 (\`ours:…\`) \| …`) | a second `D24`, written differently | `D24` twice, newest first |
| `wt/docs/architecture.md` | dj `docs/architecture.md` lines 459–462 (`## 9. M8 (built)` and its paragraph), and line 685's `### New with M8 …` | a numbered heading and a mention that is not a heading's ID | `M8` (one of them) |
| `wt/README.md` | dj `README.md` lines 123–125 (`## M8: lifecycle (ownership, replacement, play-now)` and its paragraph) | `M8` in a second file | `M8` |
| `wt/journal/decisions.md` | this repo's `journal/decisions.md` lines 1–3 and 11–17 (`### D-H1 · Fresh session per feature, …` and its body) | the `### D-H1 · …` shape | `D-H1` |
| `wt/journal/decisions/2026-10-21-one-file-per-decision.md` | this repo, its title line and first paragraph | a decisions/*.md title | nothing (no ID: the title-only rule) |
| `wt/docs/plans/near-miss.md` | planted | `## Q9 · planted near miss`, `## Q990 · planted`, `Q99 is mentioned here, under no heading of its own` | nothing: `Q99` stays unresolved |
| `inbox.md` | dj `.harness/runs/dj-2026-10-17/INBOX.md` lines 1–4 (status, steering comment) and 35–45 (`### H3-02 (2026-10-17): …` and its steps), then `## Answers` | a park INBOX | `H3-02`, `H3-04`, `H3` (from the list) |
| `text.md` | planted, the same words as n8n-home's planted question (its `fixtures/bundles/f1e03cb5-…/context.json` `open_questions[0]`) | `Does N1-01's cleanup still hold under D24's one quality and D-H1, and does M8's replacement wait on Q99?` | `D24`, `N1-01`, `M8`, `D-H1`; `Q99` unresolved |

Sanitised: no secret is in any of them (dj's INBOX names `/srv/docker/.env` and `/etc/restic/env` as paths, with
`<topic>`/`<token>` placeholders, no values); absolute paths in the copied text are kept as text. mtimes are not in
git: the unit tests' reader injects them, the A2-03 check sets them with `touch -d`.

### 1.4 Checks A2-02 writes first (watched failing): tests/unit/glossary.test.mjs

Unit tier (fast). Flat `test("glossary.mjs: …")` calls; names in `tests/fixtures/check-names.txt` and
`check-names-fast.txt` (`LC_ALL=C` sorted). The reader is an object over the fixture tree with given mtimes, so no
test depends on the checkout's clock. Lengths and ids compared, never a `deepEqual` of the whole result.

- `glossary.mjs: findIds takes D24 and D-H1 as decisions, N1-01 as a feature, M8 and Q99 as milestones`
- `glossary.mjs: findIds never takes N1 from N1-01 nor H1 from D-H1`
- `glossary.mjs: findIds takes an id of the feature list the regexes miss` (`N1F-01`, `S2-05a` with `known`; none without)
- `glossary.mjs: resolveIds gives D24 its table row, stripped and cut at 300, with path and line`
- `glossary.mjs: resolveIds gives N1-01 its description and milestone`
- `glossary.mjs: resolveIds gives M8 the headings that open with it, newest file first` (two entries; not `### New with M8`)
- `glossary.mjs: resolveIds gives D-H1 its heading and the text under it`
- `glossary.mjs: an id written in two files gives every match, newest file first` (`D24`; swap the mtimes, the order swaps)
- `glossary.mjs: a D1 that is a decision row and a milestone keeps both`
- `glossary.mjs: a milestone of the feature list comes before its headings`
- `glossary.mjs: Q99 is unresolved and no near match is taken`
- `glossary.mjs: journal/decisions files count by their title line only`
- `glossary.mjs: glossaryMarkdown renders one line per entry under ## Glossary, then Unresolved`
- `glossary.mjs: glossaryMarkdown keeps whole lines within its byte cap and says how many are left`
- `glossary.mjs: the CLI prints the glossary and unresolved for a worktree, a list and stdin` (spawned on the fixture
  tree copied to a tmp dir; `jq`-free: parsed in the test)

`node --check lib/glossary.mjs`; `bash tests/run.sh unit-tier`; then the fast tier.

## 2. A2-03 · lib/context.sh, `harness context`, the glossary section

**Files:** lib/context.sh (new), lib/context.mjs (new), lib/debrief.sh, bin/harness, tests/checks/context-bundle.sh
(new), tests/unit/context.test.mjs (new), tests/fixtures/check-names.txt (and check-names-fast.txt if fast).

### 2.1 The mechanical move (lib/debrief.sh → lib/context.sh)

Moved **verbatim** (same text, same order), lib/debrief.sh today's lines:

| Lines | What | In lib/context.sh |
|---|---|---|
| 47 | `alive` | as is |
| 48–51 | `rec_dir` | as is |
| 71–75 | the run selection loop | `context_since <since>`: prints each state dir (`${d%/}`), one per line |
| 97 | `fence` | as is |
| 98–103 | `capped` | as is |
| 104–144 | `run_context` | as is |
| 145–155 | `rate_info` | as is (reads `RUNS`) |
| 156–160 | `spend` | as is (reads `RUNS`) |
| 161 | `names` | as is (reads `RUNS`) |
| 162–181 | the `{ … } > "$CTX"` block | the body of `context_runs` |
| 182–186 | the `CMAX` cut | the end of `context_runs` |

`context_runs <state dir>…` = `local -a RUNS=("$@")` (bash's dynamic scope: `rate_info`, `spend`, `names` see it),
the block into `"$CTX"`, the CMAX cut. **It takes from its caller** `STATE_ROOT`, `Q`, `H`, `LEDGER`, `SINCE`, `CTX`
(the output file), `WS` (its scratch: `needs.txt`, `s.json`, `q.json`, `c.md`), and the functions `F` and `MET`
(lib/debrief.sh lines 45–46 stay there: the debrief uses them at 244 and 255; the CLI defines the same two). Two
words become variables whose defaults are today's text, so the debrief's bytes don't move: line 163's
`Debrief context` → `${CTX_TITLE:-Debrief context}`, line 165's `the last debrief, or the queue runner's start` →
`${CTX_SINCE_WHY:-the last debrief, or the queue runner's start}`.

lib/debrief.sh then sources lib/context.sh after line 46 and keeps no copy (`grep -c '^run_context()' lib/debrief.sh`
prints 0): lines 71–75 become `mapfile -t RUNS < <(context_since "$SINCE")`, lines 97–186 become
`context_runs "${RUNS[@]}"` and the glossary call (§2.3). `alive`/`rec_dir` keep serving lines 92, 231, 277, 281,
310–311. lib/context.sh is `set -uo pipefail` like the debrief (never `-e`: the moved code's `&&` lines rely on it),
one-line usage header, sourced (functions only: `[[ ${BASH_SOURCE[0]} != "$0" ]] && return 0` after the
definitions) or run (the CLI below).

**Proving the bytes** (A2-03's session, once, before the first edit to lib/debrief.sh): in a throwaway built like
the check's (§2.4), `harness debrief --dry-run` on main's code; after the move the same command; `diff` of the two
context files with line 1 (its minute) cut is empty apart from the appended `## Glossary` section. The entry quotes
the diff command. The lasting guard is check (b) below plus queue-debrief.sh/flakes-run.sh's existing dry-run checks.

### 2.2 `harness context`

bin/harness's header, after the `debrief` lines:

```
#   harness context <run-id> | --since <YYYY-MM-DD HH:MM:SS> [--out <dir>]
#                                                read-only: the context bundle for one run, or every run whose driver
#                                                started since then: context.md (the debrief's gatherer, then a
#                                                ## Glossary of its IDs) and context.json, in <dir>, else
#                                                <state>/events/<uuid>/; prints the directory. Never summary.json
```

Dispatch: `context) shift; exec "$HARNESS_HOME/lib/context.sh" "$@" ;;` (like debrief, sync, backlog). The CLI:

- No argument, an unknown option, `--since` not matching `^[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}$`,
  or both a run and `--since` → `usage: harness context <run-id> | --since <YYYY-MM-DD HH:MM:SS> [--out <dir>]` on
  stderr, exit 2.
- `<run-id>` (bin/harness's `state_of` rule: `^[A-Za-z0-9][A-Za-z0-9._-]*$`, then `$STATE_ROOT/*/<id>/meta.env`) →
  `RUNS=(<state dir>)`, `SINCE` = the run's first `run <id> on` line time in run.log (the awk of debrief line 93),
  `CTX_SINCE_WHY="the run's start"`. None → `harness context: no run '<id>' (see: harness status)`, exit 1.
- `--since <ts>` → `RUNS` from `context_since "$ts"`, `CTX_SINCE_WHY` unset (the debrief's words: check (b)
  diffs the two). No run →
  `harness context: no runs started since <ts>`, exit 1.
- `--id <id>` (for notify; `^[A-Za-z0-9-]{8,64}$`): the bundle's id. Default a fresh uuid
  (`/proc/sys/kernel/random/uuid`; *default*: the harness is Linux-only, systemd and flock).
- `--out <dir>` (created); default `<STATE_ROOT>/events/<id>/`. `WS=$(mktemp -d "<out>/.work.XXXXXX")`, removed on
  exit (trap): **nothing is written outside the out directory**. `CTX=<out>/context.md`,
  `CTX_TITLE=Context`. Then `context_runs "${RUNS[@]}"`, the glossary (§2.3) appended, and the out directory's
  absolute path on stdout (line 1).
- The gatherer it runs is read-only today: `harness status`, `needs`, `trends`, `queue list`, `summary.mjs
  flakers`, `entries.mjs questions`, `backlog.mjs list`; no `harness report`, so no `summary.json` is written. It
  takes no lock (status and needs read without the record lock), so notify can call it under the record lock
  (§3.4) without a deadlock.

### 2.3 The glossary section (lib/context.mjs, new)

`lib/context.sh`'s `context_glossary <state dir>…` writes `$WS/runs.tsv`, one line per run, tab-separated (no field
holds a tab): state dir, run, project, ended (`ended` without its ` · <time>`, or `still running` /
`not running, no end reason`), running (`1`/`0`), features (`F summary`), record (`rec_dir`), worktree (`WT`), docs
root, the run's `harness needs <run> --json` saved as `$WS/needs-<run>.json`. **Docs root** = the worktree when it
is a checkout (`-e $WT/.git`), else `PROJECT_DIR` (*default*: the spec's "else the ledger copy" holds only the
record, so the ledger copy is the feature list's fallback, through `rec_dir`, and the project's own checkout the
docs'). It then runs `node lib/context.mjs bundle "$CTX" "$WS/runs.tsv" --max-bytes <CMAX − size of $CTX>` and
appends its stdout to `$CTX`.

`lib/context.mjs` (one-line usage header; pure functions exported and unit-tested, the CLI around them):

- `runSection(md, run, project)` → the lines from `### <run> (<project>)` up to the next `^### ` or `^## ` line.
- `runText(md, row, needs, inbox)` → that section, the parked items' why and question, the open questions (§3.1):
  the text the run's IDs are found in. Only the run's own section: the gatherer's shared parts (trends, queue,
  runner.log) are other runs' words.
- `mergeResults(results)` → one `{ glossary, unresolved }`: entries in run order, each (id, kind, source) once; an
  ID unresolved in one run and resolved in another is not unresolved.
- `bundle` CLI: per run `findIds(runText, known)` and `resolveIds(…, { worktree: docs root, featureList: <record>/feature_list.json })`,
  merged, printed by `glossaryMarkdown(…, maxBytes)`.

The debrief appends the same section to its own context (*default*: its session then reads the IDs explained, and
the spec's "the dry-run output stays the same apart from the new glossary section"). Under the whole-context cap:
the gatherer is cut as today, the glossary gets what is left (`--max-bytes`), so queue-debrief.sh's "the whole
context is capped too" (`≤ 8000` bytes) stays as it is.

### 2.4 Checks A2-03 writes first: tests/checks/context-bundle.sh

Line 2 `# tier: fast` if `TEST_JOBS=4 bash tests/run.sh context-bundle` takes under 30 s (journal/decisions/2026-11-03-suite-tiers.md),
else `slow`; the estimate is under 30 s (status_stubs, no stub runs, four `harness context` calls of one to three
runs, one `harness debrief --dry-run`). Setup: `suite_setup; status_stubs`; the glossary fixture's `wt/` copied into
`$T/proj` (PROJECT_DIR of every stub run; the parked run's worktree `$T/wt/proj/parked` has no `.git`, so the docs
root is `$T/proj`) with `touch -d` mtimes (the research README a day newer than docs/decisions.md); the fixture's
`N1-01` feature appended to the parked run's `feature_list.json` with `jq`; `text.md`'s sentence added to the parked
run's `INBOX.md` under its `### B:` question (so it is in the run's section and its open questions); `$T/mark`
touched. `$Q/last-debrief` = `<epoch>\t$(at 11000)` (covers `parked`, `givenup`, `running`).

- (a) `context bundle: one run's context.md is its debrief section and a glossary` — `harness context parked --out
  $T/b1`: the `### parked (proj)` section of `$T/b1/context.md` equals the same section of the debrief's dry-run
  context (`awk` cut, `diff`); its `## Glossary` has `- **D24** (decision):`, `- **N1-01** (feature):`,
  `- **M8** (milestone):`, `- **D-H1** (decision):` lines and `Unresolved:` names `Q99`.
- (b) `context bundle: --since matches the debrief's dry-run context but the glossary` — `harness debrief --dry-run`'s
  context file and `harness context --since "$(at 11000)" --out $T/b2`'s context.md, each with line 1 and everything
  from `^## Glossary` on cut: `diff` empty. (So `--since` keeps the debrief's Covers wording, `CTX_SINCE_WHY` unset;
  only `<run-id>` sets it.)
- (c) `context bundle: writes nothing outside its out directory, never summary.json` — after (a), (b) and (e):
  `find $HARNESS_STATE $T/wt $HARNESS_LEDGER $T/proj -newer $T/mark` prints only paths under `$T/b1`, `$T/b2`,
  `$HARNESS_STATE/events/` and the debrief's own `$HARNESS_STATE/debrief/` (the dry-run's), and
  `find … -name summary.json -newer $T/mark` prints nothing.
- (d) `context bundle: an unknown run exits 1, no argument prints the usage and exits 2` — `harness context nosuch`:
  exit 1, stderr has `no run 'nosuch'`; `harness context`: exit 2, `usage: harness context`; `--since yesterday`: exit 2.
- (e) `context bundle: with no --out it writes events/<uuid>/ and prints that directory` — stdout line 1 matches
  `^$HARNESS_STATE/events/[0-9a-f-]{36}$` and holds context.md; no `.work.*` left in it.
- (f) `context bundle: the debrief's own context ends with the glossary` — the dry-run context's last section is
  `## Glossary` and names `D24`.

**tests/unit/context.test.mjs** (unit tier): `context.mjs: runSection cuts one run's section from the gatherer's
markdown`; `context.mjs: mergeResults keeps each source once and drops an id another run resolved`.

Also run: `bash tests/run.sh context-bundle queue-debrief flakes-run` (both debrief files: slow, they read the
dry-run context), `bash -n lib/context.sh lib/debrief.sh bin/harness`, `node --check lib/context.mjs`.

## 3. A2-04 · context.json, the retention, the hook's bundle

**Files:** lib/context.mjs, lib/context.sh, lib/notify.sh, lib/notify.mjs, lib/debrief.sh (its notify call),
tests/checks/context-bundle.sh, tests/checks/event-run.sh, tests/checks/event-hook.sh (setup line), tests/stub-context.sh
(new), tests/fixtures/context-bundle.json (new), tests/unit/context.test.mjs, tests/unit/notify.test.mjs, the check-name
lists, journal/decisions/2026-10-22-context-bundle-glossary.md (new), docs/architecture.md, README.md.

### 3.1 context.json (built by lib/context.mjs, no JSON in bash)

`node lib/context.mjs bundle "$CTX" "$WS/runs.tsv" --max-bytes <n> --json <out>/context.json --id <id> --since <ts|"">`
writes the JSON (then prints the markdown as before; one node call, so the two never disagree). The keys, in the
spec's order (a unit test pins `Object.keys` as a string):

```json
{ "v": 1, "id": "<the bundle's id>", "generated_at": "<ISO, real clock>",
  "scope": { "runs": ["<run>", …], "since": "<ts given with --since, else null>" },
  "runs": [{ "run", "project", "ended", "running": false, "features": "<F summary>",
             "paths": { "record", "worktree", "state", "report", "inbox", "progress" },
             "summary": <the record's summary.json parsed, or null>,
             "parked": [{ "feature", "why", "question" }], "open_questions": ["…"] }],
  "glossary": [{ "id", "kind": "decision|feature|milestone", "text", "source": "<path>:<line>" }],
  "unresolved": ["<id>", …] }
```

- `paths`: `record` = `rec_dir`; `worktree` = `WT` (even when removed); `state` = the state dir; `report`, `inbox`,
  `progress` = `<record>/report.md`, `INBOX.md`, `progress.md` (absolute; present or not).
- `parked`: the run's open needs items whose `reason` is `parked`, from `$WS/needs-<run>.json`: `feature` =
  `.feature`, `why` = `.why`, `question` = `.card.question.text` (the A2-04 session reads one real `harness needs
  parked --json` on status_stubs first and maps from what it prints: this is the intended mapping, not a guessed
  shape).
- `open_questions` (*default*, from the files progress.md is rendered from, not progress.md itself, which may be
  stale or absent: status_stubs's runs have none): the INBOX's open asks (each `### ` block between the steering
  comment and `## Answers`, lib/inbox.mjs's `answersLine`, whitespace collapsed, at most 600 chars), then the open
  needs `question` items' `.card.question.text` not already among them; at most 12.
- No `jq -n` in lib/context.sh (`grep -c 'jq -n' lib/context.sh` prints 0).

### 3.2 Retention (*default*: 30 days, on write)

After a bundle is written whose out directory's parent is `$STATE_ROOT/events` (the default, or a `--out` there:
notify's), `node lib/context.mjs prune "$STATE_ROOT/events" <keep id>` removes every other `events/<dir>/` with no
file modified in the last 30 days (by the real clock, never `HARNESS_NOW`: status_stubs pins that to the past), and
prints `events: removed <n> bundle older than 30 days` / `… bundles …` when `n > 0` (stdout, after the directory
line). A dir is judged by its files' mtimes, not its own (writing `event.json` sets the dir's). Pure part:
`staleBundles([{ dir, newestMs }], nowMs, days = 30)`, unit-tested. A `--out` elsewhere prunes nothing (it would
write outside its out directory).

### 3.3 Checks A2-04 writes first

**tests/checks/context-bundle.sh** (its tier stays as A2-03 set it, retimed):

- `context bundle: context.json has the spec's shape for one run` — `$T/b1/context.json` passes the feature's `jq -e`
  verbatim (`.v == 1 and (.id | type) == "string" and .generated_at != null and .scope.runs == ["parked"] and
  .scope.since == null and (.runs | length) == 1 and .runs[0].paths.record != null and .runs[0].parked[0].feature ==
  "B" and ([.glossary[].id] | index("D24")) != null and .unresolved == ["Q99"]`) and `grep -c 'jq -n'
  lib/context.sh` is 0. Risk named: the parked run's section must hold no other ID that nothing resolves (`M1`
  resolves from the list); if it does, the session fixes the planted state, not the assertion, and says what it
  found.
- `context bundle: context.json for --since names its time and every run since it` — `$T/b2`'s `.scope.since` is
  `$(at 11000)`, `.scope.runs` the three runs, sorted as `context_since` lists them.
- `context bundle: a run's summary is its summary.json, or null without one`
- `context bundle: open_questions carries the parked run's INBOX question` (`set the gatus vars` and the planted text)
- `context bundle: a new bundle removes events older than 30 days and says so` — `events/old/event.json`
  `touch -d '31 days ago'`, `events/recent/event.json` `touch -d '1 day ago'`; `harness context parked` (default out):
  `old` gone, `recent` kept, stdout has `events: removed 1 bundle older than 30 days`.

**tests/checks/event-run.sh** (slow; reuses its park run, EVENT_URL set, stub 200; `STUB_CURL_SPY` records
`test -f "$ctx"` and `test -f "${ctx%/*}/context.json"` for the event POST's body's `.context` at call time):

- `event run: a park event's context.json exists when the POST is made, event.json beside it` — `.context` matches
  `^$HARNESS_STATE/events/<id>/context.json$` with `<id>` the event's `id`; both spy tests 0; its `scope.runs ==
  ["<run>"]`; `runs[0].open_questions` holds the parked question; `events/<id>/event.json` there.
- `event run: the hook notes the old bundles it removed` — an `events/stale/event.json` 31 days old planted before
  the park run: gone after, and the run's harness-log.md has `events: removed 1 bundle older than 30 days`.
- `event run: the debrief event's bundle covers the debrief's runs` — `scope.runs` equals the debrief context's
  Covers runs; `scope.since` its SINCE.
- `event run: a bundle that fails sends the event with a null context, noted` — `HARNESS_CONTEXT=false` (the knob:
  the bundle command, as `HARNESS_CURL` is curl's): the POST's `.context == null`, the note
  `context bundle failed for park; event sent without it`, the event still sent once.

**Unit**: `notify.mjs event: a given id= is the event's id` (a v1 id shape; anything else ignored, a fresh uuid);
`context.mjs: staleBundles keeps a dir with any file newer than 30 days`; `context.mjs: context.json's keys are the
spec's, in order`; `context.mjs: open questions are the INBOX's open asks, then the open question items`.

New files: `tests/stub-context.sh` (the `HARNESS_CONTEXT` stand-in, §4's event-hook row) and
`tests/fixtures/context-bundle.json` (its context.json, written by the real code, provenance in the stub's header).
Also run: `bash tests/run.sh context-bundle event-run queue-debrief`, `bash -n lib/notify.sh lib/context.sh
lib/debrief.sh`, `node --check` on lib/notify.mjs, lib/context.mjs.

### 3.4 The hook (lib/notify.sh `notify_event`)

Before today's `ev=$(ask notify.mjs event …)` (line 55):

```bash
E=${HARNESS_STATE:-${XDG_STATE_HOME:-$HOME/.local/state}/harness}/events ctx="" out=""
id=$(cat /proc/sys/kernel/random/uuid 2> /dev/null)
if [[ -n $since ]]; then sc=(--since "$since"); else sc=("${RUN_ID:-}"); fi
if [[ -n $id && -n ${sc[0]} ]] && out=$(timeout 60 "${HARNESS_CONTEXT:-${NOTIFY_MJS%/*}/context.sh}" "${sc[@]}" \
     --out "$E/$id" --id "$id" < /dev/null 2> /dev/null 8>&- 9>&-) && [[ -s $E/$id/context.json ]]; then
  ctx=$E/$id/context.json
  grep '^events: removed ' <<< "$out" | while IFS= read -r l; do notify_say "$l"; done
else notify_say "context bundle failed for $kind; event sent without it"; fi
```

then `ask notify.mjs event id="$id" context="$ctx" …` (buildEvent takes a given `id=` of v1's shape, A2-04 unit
test; an empty one gets a fresh uuid as today). `notify_say` is the `note`-else-`log` pair notify_event already
has at its end, made a function. `notify` gains one field, `since=` (the debrief passes `since="$SINCE"` at
lib/debrief.sh:343: the debrief has no `RUN_ID`, and n8n refuses a debrief without a context). event.json is
written into the same `events/<id>/`. *default*: the bundle is synchronous and capped at 60 s (`timeout`), before
the 5 s POST; a slow or failed bundle costs at most that and a note, and `notify` still returns 0 with the POST or
the ntfy post sent. The bundle never runs for a kind that isn't routed or with `EVENT_URL` unset.

### 3.5 Decision file and docs

- `journal/decisions/2026-10-22-context-bundle-glossary.md` (the spec's name): finding · choice · rejected as A2-04
  step 5 lists. *default* each: the 30-day retention on write; the synchronous bundle and its 60 s cap; newest file
  by mtime; the docs root (worktree, else the project's checkout); `known` ids; open_questions from INBOX and the
  needs record; the debrief's own glossary section; the uuid from /proc. Rejected: a glossary by the model, a
  glossary store of its own, a bundle n8n builds through harness commands.
- docs/architecture.md: §3 rows for lib/context.sh, lib/context.mjs, lib/glossary.mjs; §4 `events/<id>/`
  (event.json, context.md, context.json) and the retention; the command list `harness context`; §16 Debrief names
  `context_runs`. README.md `## Debrief`: one `harness context` paragraph.

## 4. Existing checks A2 could touch

| File | Assertion | Verdict |
|---|---|---|
| tests/checks/queue-debrief.sh:277 | `--dry-run prints the context, launches nothing` | stays: the context gains a section at its end |
| tests/checks/queue-debrief.sh:332 | `the whole context is capped too` (≤ 8000 bytes) | stays: the glossary gets only the bytes left |
| tests/checks/queue-debrief.sh:176, 298, 318 | `### <run> (proj)` in the prompt / dry-run | stays: the moved `run_context` |
| tests/checks/flakes-run.sh:69 | the `#### flakes` block after `#### report.md` | stays: moved verbatim |
| tests/checks/event-run.sh | the debrief event (A1-03) | stays; with A2-04 its event gains a context |
| tests/checks/event-hook.sh | sourced `notify` cases, EVENT_URL set; (c), (d), (k) compare the whole note file (`[[ $(cat eh-c.note) == "event hook failed (500): …" ]]`) | stays, its setup gains one line: the case wrapper sets `HARNESS_CONTEXT=$HERE/../tests/stub-context.sh` (new: copies `tests/fixtures/context-bundle.json`, a `context.json` the real code wrote on status_stubs's `parked`, and an empty context.md into `--out`), so no `context bundle failed` note joins theirs. Without it `RUN_ID=r1` has no state dir and the bundle fails |
| tests/unit/notify.test.mjs | buildEvent's keys, the CLI | stays; one test added |

No check is replaced: nothing asserts the bundle today. A2's new names: 15 + 2 unit (A2-02, A2-03), 6 in
context-bundle.sh (A2-03), 5 + 4 + 4 (A2-04).

## 5. Not in A2

The request inbox (A3), README's Notifications section and the live checklist (A4), any n8n-home change (its
fixture bundles are replaced by a captured one on its own checklist, item 11). Nothing under `~/.config`, `/srv`,
`~/.claude` or `~/.local/state/harness`; no real request.
