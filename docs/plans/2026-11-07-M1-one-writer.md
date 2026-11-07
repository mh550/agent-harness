# M1 · The project's memory has one writer, and the rule is mechanical (plan)

*(2026-11-07, run agent-harness-2026-11-07-2, feature M1-01; spec `docs/specs/2026-11-07-memory-curator.md` §M1)*

M1 makes the entry the only route a session has to project memory. M1-02 changes what the pack and the prompts
ask for. M1-03 makes the rule mechanical: `restrict`'s new `memory` spec reverts a coding session's `CLAUDE.md` and
`.harness/project.md`. M1-03 also writes the decision, the docs and the folded review. No feature code in this
feature. Line numbers are as of `486f314`.

## Facts this plan rests on (read off the code, 2026-11-07)

- **`restrict` (`lib/record.sh:361`) has two specs today.** `record` is `. ':!.harness/runs'` and `nothing` is `.`.
  It is called four times: verify (`lib/lane.sh:155`), retro (`lib/driver.sh:245`), initializer
  (`lib/driver.sh:512`) and entry-resume (`lib/record.sh:609`). No coding session is restricted.
- **A coding session's path in its lane** (`lib/lane.sh:447–461`) runs `session` → `commit_all "WIP: …"; sync_lane`
  (450) → the suite-runs note → `journal coding` (457) → `inbox_repair` → `take_question` → `lane_guard` (460) →
  `gotchas` (461). The fast-tier gate (`green_fast`, about 494) comes after, on HEAD's tree.
- **The pack's `Promote to Gotchas` part** is `lib/entries.mjs:289–296`. It walks `nw` (newest first) and keeps the
  *newest* occurrence of each `key`. It drops a fact a `## Gotchas` line `includes` (`carried`, from the `gotchas`
  argument), and a fact a later entry's `resolved` names by `key`. The CLI fills `gotchas` from the worktree's
  `CLAUDE.md` (`lib/entries.mjs:463–464`, `gotchasLines` imported from memlint.mjs).
- **The `gotcha` run of `tests/checks/gotchas-pack.sh`** was read with `KEEP=1` on this tree. Its sessions run in this
  order: A 1 (`01-A`), B 1 (`02-B`), verify M1, A 2 (`03-A`), verify M1, C 1 (`04-C`), C 2 (`05-C`), verify M2,
  retro. `entries.jsonl:1` is the init entry, so A's project fact is `entries.jsonl:2`. Today `02-B` lists the fact.
  `03-A` does not, because B's Gotchas line is in the slot's CLAUDE.md. `04-C` and `05-C` do not either, because M1's
  merge put the line on main.
- **All eight projects have their own `## Where things go` block**, and each sends a fact to `## Gotchas`. So
  `lib/prompt.sh:97–101` gives a coding or initializer prompt no where-things-go part in any real project. Only the
  Finish step and the initializer's paragraph can say the new route there.
- **The initializer's revert note** (`lib/driver.sh:513`, `initializer: reverted edits outside the run record …`)
  has no check today, and no stub knob makes the initializer edit a file.
- **This run is driven by the live checkout at the pre-M1 main.** The live checkout is levelled only when no run is
  alive. So M1's revert never runs in this run, and M2's and M3's sessions may still edit CLAUDE.md here. Its first
  real exercise is the next run started after this one's merge.

---

## M1-02 · The pack's clearing rule, and the prompts rerouted

### Files it edits

| File | Change |
|---|---|
| `lib/entries.mjs` `pack` (289–296, the doc comment 255–264) | The clearing rule below. The `carried` test goes, and so does the `gotchas` parameter (see *Defaults*). |
| `lib/entries.mjs` CLI `pack` (455–466) | The `CLAUDE.md` read (`let gotchas …`, 463–464) and the `gotchasLines` import go. `inRun` stays for `readRules`. |
| `prompts/coding.md` §3 Finish step 2 (92–99), step 3's "after the `## Gotchas` line" (101), the `resolved` sentence (126–128), line 23's "`CLAUDE.md` included" | Rewritten as below. |
| `prompts/initializer.md` entry paragraph (92–95) | A durable gotcha goes to `discoveries` with `affects: ["project"]`, and a convention or workflow line to `proposed_changes`. A run-only fact goes to `discoveries` affecting `"run"` (unchanged). Same 160-character shape. It never goes to `CLAUDE.md`, whatever the project's own block says. |
| `prompts/parts/where-things-go.md` | The fact line becomes "→ your entry's `discoveries` with `affects: ["project"]` (at most 160 characters, ending `(<run> <date>)`); a session never writes `CLAUDE.md` or `.harness/project.md`". "How to work here" becomes "→ your entry's `proposed_changes`". |
| `prompts/parts/where-things-go-readonly.md` | The sentence "The next coding session finds it under `Promote to Gotchas` and writes it into `## Gotchas`." goes. The fact stays in `discoveries` with `affects: ["project"]`. |
| `prompts/parts/where-things-go-override.md` | Adds `.harness/project.md` beside `CLAUDE.md`, and says a convention goes in `proposed_changes`. Its lead stays `**Read-only session.**`, so the check that only verify and retro carry it stays true. |
| `templates/project/CLAUDE.md` block (21, 23) | The fact line → "the session's entry (`discoveries`, `affects: ["project"]`); never written here by a session". "How to work here" → "Michael's: the entry's `proposed_changes`". `## Gotchas` and its comment stay (the curator writes it in M2). |
| `prompts/draft-claude-md.md` (8) | The drafted block's fact line says the same route as the template. It is the template's sibling: a project drafted after M1 must not get the old line. |
| `CLAUDE.md` (this repo) `## Where things go`, the fact line | → "your `entry.json`'s `discoveries` with `affects: ["project"]`, never this file (a coding session's edit is reverted)". The other lines stay. This is the one CLAUDE.md edit M1 makes. The live harness doesn't revert it in this run. |
| `tests/stub-claude.sh` | The knobs below, each with its header line. |

**Finish step 2, as M1-02 writes it** (M1-03 adds the revert sentence, so the prompt never claims a guard before it
exists):

> 2. Project memory is not yours to write: leave the project's `CLAUDE.md` and `.harness/project.md` alone,
>    whatever their own `## Where things go` says. A fact this session taught you that a fresh session would
>    otherwise rediscover goes in your entry's `discoveries` with `affects: ["project"]`: at most 160 characters,
>    ending `(<run> <date>)` (the run id from the `Run:` line under *This run*, today's date). A convention or
>    workflow line (how to work here) goes in `proposed_changes`. Read context.md's `Promote to Gotchas` part
>    first: a fact listed there is already recorded, so don't state it again. Put one that no longer holds in your
>    entry's `resolved`, copied as context.md shows it.

Step 3 becomes "…the fast tier's one run now (`<suite> --fast`), after your last edit, so the tree you tested is…".
The `ord` check in `suite-length.sh` still finds `Promote to Gotchas` in §3 before `3. The suite green`. After the
rewrite, `grep -c 'under \`## Gotchas\`'` prints 0 for both `prompts/coding.md` and `prompts/initializer.md`.

### The clearing rule (as `tests/unit/entries.test.mjs` asserts it)

The pack shows a `project` discovery `d` of entry `e` (a coding pack only, as today) when all of these hold:

1. No entry with a line after `e.line` has a `resolved` item whose `key` equals `key(d.text)`. `key` is the existing
   normalizer (`loose` lowercases, drops `` ` ``, `*` and `_`, and collapses spacing; `key` takes the first 40
   characters of that). `resolvedText` keeps stripping the `- ` lead and ` → entries.jsonl:<n>`.
2. No *earlier* entry carries a fact with the same `key` that is itself unresolved by rule 1. So the fact is listed
   once, at its first unresolved statement: the line a curator's `from` will name. Within one entry, the first
   occurrence counts.
3. **Nothing reads `CLAUDE.md`.** A `gotchas` value in the options object changes nothing.

Order: newest first (as today, by the entry's line). The share stays `Math.floor(cap / 8)` (*default*). The title
stays `Promote to Gotchas` (*default*: the curator promotes them in M2; `suite-length.sh`'s `ord` and the prompts
name it). A rename would change the pack, `prompts/coding.md`, `suite-length.sh`'s `ord`, and the checks below that
match `## Promote to Gotchas`.

Implementation sketch: a pass over `es` in file order builds `first: Map<key, line>` from the unresolved project facts.
The newest-first list then keeps `{d, e}` only where `first.get(key(d.text)) === e.line`, plus a per-entry `seen` set
so one entry's duplicate counts once.

### Stub knobs (in `tests/stub-claude.sh`, each with its header line)

| Knob | Behaviour | Header line (near line 38) |
|---|---|---|
| `STUB_PROJECT_FACT=<id>[,<id>…]` (extended) | Each listed feature's first session's entry has the fact. Today it takes one id; the jq test becomes `($fact | split(",") | index($id))`. | `STUB_PROJECT_FACT=<id>[,<id>…]: each one's first session's entry has the discovery STUB_GOTCHA writes, affecting "project" (M3-03; a list, M1-02)` |
| `STUB_RESOLVE_FACT=<id>` (new) | That feature's first coding session's entry lists the fact's text in `resolved`. | `STUB_RESOLVE_FACT=<id>: that feature's first coding session's entry lists STUB_PROJECT_FACT's fact in resolved (M1-02)` |
| `STUB_PROPOSE=<id>` (new) | That feature's first coding session's entry carries `proposed_changes: ["stub proposal: run the stub suite before each commit"]`. | `STUB_PROPOSE=<id>: that feature's first coding session's entry carries one proposed_changes string (M1-02)` |

### Checks, written first and watched failing

**`tests/unit/entries.test.mjs` (unit tier, fast; names in both fixtures).** Flat `test("entries.mjs pack: …")`;
compare lengths and lines, never a `deepEqual` of a pack.

| Name | Asserts | Replaces |
|---|---|---|
| `entries.mjs pack: Promote to Gotchas lists project facts newest first within cap/8, whatever CLAUDE.md's Gotchas hold` | the old test's count, order, part placement, cap/8 share, cut, `items left out`, and no part in a milestone pack. Passing `gotchas: [<the fact's line>]` leaves the fact listed. | `entries.mjs: Promote to Gotchas lists project facts until a Gotchas line carries them` |
| `entries.mjs pack: a later entry's resolved dismisses a fact in any case, markup or spacing, or a question as context.md shows it` | the old test's question and `resolved` assertions; entry 3's `resolved` with other case, backticks and spacing drops entry 2's fact; a `resolved` before the fact drops nothing | `entries.mjs: a Gotchas line carries a fact in any case or markup, resolved dismisses a fact or a question as context.md shows it` |
| `entries.mjs pack: a fact restated by key is listed once, at its first unresolved entry; another key is listed too` | entries 2 and 4 with one `key` → one line, `→ entries.jsonl:2`; resolved at 3 and restated at 4 → `:4`; a different key → its own line | new |

**`tests/checks/gotchas-pack.sh` (slow).** A second stub run, `facts`, runs from main as the file leaves it:
`STUB_PROJECT_FACT=A,B STUB_RESOLVE_FACT=C STUB_PROPOSE=A`, no `STUB_GOTCHA`. Its main's head is taken before the run
(`m0=$(git -C "$T/origin.git" rev-parse main)`). Comparing against origin/main *after* the run proves nothing,
because a merged CLAUDE.md edit would be on both sides. The `gotcha` run keeps `STUB_GOTCHA=B` until M1-03. The
`facts` pack names below assume the `gotcha` run's session order. Confirm them once with `KEEP=1 bash tests/run.sh
gotchas-pack` (it prints `kept: <dir>`; the packs are in `<dir>/state/proj/facts/logs/`).

| Name | Asserts | Replaces |
|---|---|---|
| `coding and verify prompts: a fact to discoveries affecting project, a workflow line to proposed_changes, a stale one to resolved; no Gotchas write` | the rendered `prompt-coding.md`'s §3 names `discoveries`, `affects: ["project"]`, `proposed_changes`, `160 characters`, `(<run> <date>)`, `Promote to Gotchas` and `resolved`, and has no ``under `## Gotchas` ``; the entry example's `resolved`/`affects` strings; the verify prompt's durable fact (as the old check) | `coding prompt: the Finish step adds one Gotchas line` and `coding and verify prompts name resolved, project facts and Promote to Gotchas` |
| `a project discovery is listed under Promote to Gotchas once, at its first entry, until a later entry resolves it` | `facts` run: `02-B` and `03-A` list the fact once, `→ entries.jsonl:2` (B's restatement at :3 is not listed); `04-C` lists it; `05-C` has no part (C 1 resolved it); `01-A` has none | `a project discovery is listed under Promote to Gotchas until CLAUDE.md carries it` |
| `a coding entry's project fact and proposed change reach entries.jsonl and progress.md; CLAUDE.md stays main's` | `facts` ends `done`; `jq` over entries.jsonl finds A's discovery with `affects: ["project"]` and its `proposed_changes`; progress.md shows both; `git -C "$T/origin.git" diff --quiet "$m0" main -- CLAUDE.md` and the same on `run/facts/M1` | new |
| — | removed: `entries.mjs pack: an unreadable CLAUDE.md leaves the Gotchas out, never the pack` (its subject, the CLI's CLAUDE.md read, goes; the pack's other reads are unit-tested) | removed |

**`tests/checks/memory-prompts.sh` (slow).**

| Name | Asserts | Replaces |
|---|---|---|
| `routing: the rendered initializer prompt sends a durable fact to discoveries affecting project, a run-only fact affecting run, no decision number` | `prompt-initializer.md` names `discoveries`, `affects: ["project"]`, `proposed_changes`, has no ``under `## Gotchas` ``, keeps the run-only and `record as a new decision` clauses | `routing: the rendered initializer prompt sends gotchas to ## Gotchas, run-only facts to discoveries, no decision number` |
| `where things go: the block and its read-only variant send a fact to discoveries affecting project, no Gotchas write` | wt1's coding block and verify block name `affects: ["project"]`; neither has ``under `## Gotchas` ``; the read-only one has no `writes it into` | new |
| `routing: the template, the drafting prompt and this repo's Where things go send a fact to the entry, never to CLAUDE.md by a session` | the three texts' fact lines name `discoveries` and none says ``one line under `## Gotchas` `` | new |

These stay true as written: `where things go: the coding, initializer and verify prompts carry the block once …`
(it greps `Gotchas` in the coding prompt, and `Promote to Gotchas` is there); `where things go: the verify prompt has
the read-only variant …`; `… verify and retro keep the read-only rule …`; `routing: coding.md points at the block,
draft-claude-md.md asks for the block and Gotchas …` (the drafted file still has a `## Gotchas` section); `routing:
the project template has the block and an empty Gotchas …`; `routing: this repo has the block …`;
`suite-length.sh`'s two Finish-order checks.

---

## M1-03 · The `memory` spec, the decision, the docs, the folded review

### The spec's exact shape

- `restrict <base> memory <who>` reverts changes since `<base>` to exactly two paths at the repo root: `CLAUDE.md`
  and `.harness/project.md`. In `restrict`: `[[ $2 == memory ]] && spec=(CLAUDE.md .harness/project.md)`. These are
  plain pathspecs, so a nested `docs/CLAUDE.md` doesn't match. Every caller's cwd is the worktree root, as the `.`
  of the other specs already assumes. An added file is removed, an edited or deleted one comes back from `<base>`,
  as today's loop does. `record` and `nothing` are unchanged.
- **The caller is a new `memory_guard <start> <who>` in `lib/record.sh`, beside `lane_guard`**, called once per coding
  session in `lib/lane.sh` on line 450, between `commit_all` and `sync_lane`. So the revert commit is pushed with the
  session's work, before `journal coding`. `journal coding`'s file list (a diff from `sstart`) and the fast gate then
  see the reverted tree, which is the tree that merges.
- **The base is the lane's merge-base with main, `$sstart` when that fails** (*default*, as `lane_guard`'s,
  `decisions/2026-10-30-lane-guard-base`). If a session merges `origin/main` itself and main's CLAUDE.md moved, that
  CLAUDE.md change is main's. With `$sstart` as the base, the revert would take main's lines out on the lane branch,
  and the milestone's merge would then take them out of main. In M2's world a merged memory PR makes exactly that
  change. Every earlier coding edit in the lane was reverted, so the merge-base's CLAUDE.md is the session's start's
  in every other case. The feature's step names `restrict "$sstart" memory "$id"` in lib/lane.sh. This plan puts that
  call in `memory_guard`, with the base so chosen, so a sourced check can test it (`proposed_changes`).
- **Notes**: one per reverted file, `<feature>: reverted its <file> edit (project memory is the curator's; say it in
  the entry)` with `<file>` `CLAUDE.md` or `.harness/project.md` (*default*). The commit is restrict's own `HARNESS:
  reverted edits a <id> session may not make`. A session that touched neither gets no note and no commit
  (`commit_all` skips an empty index).
- **`gotchas()` retires** (*default*, as the feature says). After the revert, a coding session's CLAUDE.md diff is
  always empty. `lib/record.sh:684–693` and `lib/lane.sh:461` go. `memlint.mjs gotchas` (the CLI) and
  `gotchasDiff`/`gotchasLines` stay: memlint's lints use `gotchasLines`, and M2's cap check may read an edit through
  `gotchasDiff`. M3 decides the CLI's fate if M2 doesn't use it. `journal/decisions/2026-10-26-gotchas-in-place.md`
  gets one line: `Updated in place 2026-11-07: a coding session no longer edits ## Gotchas; restrict's memory spec
  reverts it and gotchas() and its note are gone (decisions/2026-11-07-memory-one-writer).`
- **Cost**: a session that edits CLAUDE.md anyway makes HEAD's tree differ from the one it tested, so the gate pays
  one more fast run, or a partial one where `CHECK_KEY_MAP` maps CLAUDE.md (this repo). It tests what merges.

### Stub knobs

| Knob | Behaviour | Header line |
|---|---|---|
| `STUB_TOUCH_CODE=<id>` (new) | That feature's first coding session also writes `lib/stub-<id>.sh`, `tests/stub-<id>.txt` and `journal/decisions/stub-<id>.md`, committed with its work. | `STUB_TOUCH_CODE=<id>: that feature's first coding session also writes a file under lib/, tests/ and journal/decisions/ (M1-03)` |
| `STUB_PROJECT_MD=<id>` (new) | That feature's first coding session appends `<id> fact` to `.harness/project.md` (creating it), committed. | `STUB_PROJECT_MD=<id>: that feature's first coding session edits .harness/project.md (M1-03)` |
| `STUB_INIT_GOTCHA=1` (new) | The initializer appends a `## Gotchas` line to CLAUDE.md, uncommitted, as `prompts/initializer.md:94` asked before M1. | `STUB_INIT_GOTCHA=1: the initializer adds a ## Gotchas line to CLAUDE.md, uncommitted (M1-03)` |
| `STUB_README_ONLY=<id>` (renames `STUB_GOTCHA_ONLY`) | Passes with one README.md line as its only change. | `STUB_GOTCHA_ONLY`'s line, reworded |
| `STUB_GOTCHA=<id>` (kept) | As today; its header says the edit is reverted after M1. | — |

### Checks, written first and watched failing

**New file `tests/checks/memory-one-writer.sh`, `# tier: fast`.** One stub run, `mem`:
`STUB_GOTCHA=A STUB_TOUCH_CODE=A STUB_PROJECT_MD=B STUB_INIT_GOTCHA=1`, with `m0` taken before it. That is about 10 s
(the `facts`-sized run), plus sourced `restrict`/`memory_guard` checks of about 1 s on a `git init` throwaway, as
`lanes-record-lock.sh`'s lane_guard block does. Well under 30 s. If the measured wall says otherwise, the line says
`slow`, by `decisions/2026-11-03-suite-tiers`. Names in both fixtures.

| Name | Asserts |
|---|---|
| `memory: a coding session's CLAUDE.md edit is reverted with one note, and the run ends done` | `mem` ends `done`; `git diff --quiet "$m0" run/mem/M1 -- CLAUDE.md` and the same for origin's main; harness-log.md has exactly one `A: reverted its CLAUDE.md edit (project memory is the curator's; say it in the entry)` |
| `memory: the same session's lib, tests and journal/decisions edits stay on the branch and merge` | `run/mem/M1` and origin's main hold `lib/stub-A.sh`, `tests/stub-A.txt` and `journal/decisions/stub-A.md` |
| `memory: a coding session's .harness/project.md edit is reverted the same way` | B's: the file as at `m0` (absent), one `B: reverted its .harness/project.md edit (…)` |
| `memory: a session that leaves CLAUDE.md and .harness/project.md alone gets no revert note` | no `C: reverted its` and no second `A: reverted its` (A's attempt 2) |
| `memory: the initializer's Gotchas write stays reverted with its outside-the-record note` | `initializer: reverted edits outside the run record (the record branch holds the record only): CLAUDE.md`; the record branch's CLAUDE.md as `m0`'s |
| `restrict memory: CLAUDE.md and .harness/project.md go back, added, edited or deleted; docs/CLAUDE.md, lib/ and .harness/config.sh stay` | sourced, on a throwaway repo; restrict's printed list is exactly the two paths |
| `memory_guard: after a session's own merge of main, main's CLAUDE.md lines stay; only the session's own edit goes` | sourced, as lane_guard's merge check: main gains a CLAUDE.md line, the session merges main and adds its own line; after `memory_guard`, `HEAD:CLAUDE.md` equals `origin/main:CLAUDE.md` |

**What M1-03 replaces or removes elsewhere**

| File | Name | Becomes |
|---|---|---|
| `gotchas-pack.sh` | `a stub session that adds a Gotchas line is noted` | removed; made by `memory: a coding session's CLAUDE.md edit is reverted …` (its note replaces the gotchas note) |
| `gotchas-pack.sh` | `a session that leaves CLAUDE.md alone gets no gotchas note` | removed; made by `memory: a session that leaves … gets no revert note` |
| `gotchas-pack.sh` | the `gotcha` run's `STUB_GOTCHA=B` | dropped (nothing reads it now) |
| `partial-key.sh` (fast) | `driver partial: a session that edits only CLAUDE.md gets a partial init (memlint alone after the full run); tests-end is the full count` | `driver partial: a session that edits only a mapped file gets a partial init (its check alone after the full run); tests-end is the full count` — the stub project's map is `README.md:readme` and `STUB_EDIT=README.md`. The revert would leave this session's tree unchanged, so the partial path would never run. |
| `partial-key.sh` (fast) | `driver partial: verify's run_init fresh removes the verified tree's part-; its suite runs in full (no arguments), after B's partial` | stays by name. Its run takes `STUB_README_ONLY=B` and its awk reads `readme` for `memlint`. Same reason. |
| `verify-retro-read-only.sh`, `lanes-run.sh` | all | stay (restrict's `record`/`nothing` unchanged; run in step 6) |
| `gotchas-pack.sh` | `memlint.mjs gotchas: the CLI prints …` | stays (the CLI stays) |

### The decision, the docs, the reversed non-goal

- `journal/decisions/2026-11-07-memory-one-writer.md`: title; provenance (this run, the spec's M1, this plan); the
  finding (the spec's three facts); the choice with every *default* marked: the `memory` spec and its two paths,
  `memory_guard`'s base, the note's words, the pack's clearing rule (earliest unresolved, no CLAUDE.md read, cap/8,
  the title), the `gotchas` note retired, the prompts rerouted; rejected: the `nothing` spec for coding sessions (a
  coding session must write code, tests, docs and decisions), an advisory prompt line alone (what `## Where things
  go` was: 0 findings in 31 runs say nothing about edits nobody looked at), `$sstart` as the base (the self-merge
  case above).
- `journal/decisions/2026-10-22-context-pack.md:35`, under its `**Rejected:** an LLM curator …` bullet, one line:
  `Updated in place 2026-11-07: an LLM curator is now built (docs/specs/2026-11-07-memory-curator.md): the 120-line
  and 15-Gotchas cap was enforced by one repo's suite check alone, red outside the feature that caused it; restrict
  never covered coding sessions, so "Michael's" in Where things go was advisory; memlint found 0 findings in 31 runs,
  inventory rather than safety. What the field guide forbids is a rewriter, not a curator: this one emits itemized
  operations the driver validates and applies (decisions/2026-11-07-memory-one-writer).`
  The two specs that ruled it out stay as written (history).
- `docs/architecture.md`: §3's `lib/record.sh` row (`restrict` gains `memory`, `memory_guard`, `gotchas` gone) and
  `lib/lane.sh` row (the coding path's `memory_guard`); `lib/entries.mjs`'s row if it names the Gotchas read; §4's
  Context pack and Session entry rows (the clearing rule); §4 *Memory model*, the Project row's semantic cell (no
  session writes `## Gotchas`) and rule 2 (sessions write their entry, passes and code; project memory has one writer:
  none in M1, the driver from the curator's operations in M2); §7 Guards: the `Read-only sessions` row's sibling, a
  `Project memory` row replacing the `Gotchas` row (trigger: a coding session's diff touches the two files; action:
  the revert and its note; `memory_guard()`, `restrict()`).
- `README.md`: line 85's `CLAUDE.md` row (a session doesn't write it); the *Memory lint* paragraph (116–124) gains one
  sentence: a coding session's `CLAUDE.md` or `.harness/project.md` edit is reverted and noted; a fact goes in the
  entry's `discoveries` with `affects: ["project"]`.
- `prompts/coding.md` Finish step 2 gains: "The harness reverts an edit to either and notes `<feature>: reverted its
  CLAUDE.md edit (project memory is the curator's; say it in the entry)`." These words are the architecture's §7 row.

### The folded M1 review

An Opus subagent reads `git diff $(git merge-base HEAD origin/main) -- lib prompts tests docs journal CLAUDE.md
templates > $HARNESS_SCRATCH/M1.diff`, with one job. It must prove that `memory` reverts nothing but the two files, on
the `mem` run (whose session touched `lib/`, `tests/` and `journal/decisions/`), and that no other role's `restrict`
call changed (verify's `record`, retro's `nothing`, the initializer's `record`, entry-resume's `record`). Also read:
`memory_guard`'s base on a self-merge, and the pathspecs at the repo root. Critical and Important findings are fixed
test-first. Its findings and what was done become a `## M1 review` section at the end of this file.

---

## Check names against the budget (M1: 30)

`checks +a ~b −c` pairs a removed and an added name only when they fall in one hunk of the sorted fixture. So a
replacement that sorts away from its old name counts as one added and one removed. The table counts the worst case.

| Feature | New names | Old names out | Notes |
|---|---|---|---|
| M1-02 | 9 (3 unit, 3 gotchas-pack, 3 memory-prompts) | 6 | 6 of the 9 replace; 1 removed outright |
| M1-03 | 8 (7 memory-one-writer, 1 partial-key rename) | 3 | 2 gotchas-pack removed, 1 renamed |
| M1 | **17 added at most** (≤ 30) | 9 | net +8 names in check-names.txt |

The fast fixture: +3 unit −2 unit, +7 memory-one-writer, ±1 partial-key, so net +8 at most.

## Risks the sessions should know

- After M1 merges, no coding session of a later run can change a project's `CLAUDE.md`, this repo's included. A spec
  that needs a CLAUDE.md line (a code rule, a gotcha) gets it through M2's curator PR or from Michael. The spec
  intends this.
- In this run the live driver is pre-M1, so M2's and M3's sessions still read a Finish step that asks for a Gotchas
  line while their branch's `CLAUDE.md` (from main, after M1) says otherwise. Nothing reverts either edit until the
  next run. An M2 or M3 session should follow its branch's `CLAUDE.md`, put facts in its entry, and leave the
  `## Gotchas` lines alone.
- The pack's sibling rule shows the *first* wording of a fact. A real correction should `resolve` the old fact and
  state the new one, which rule 1 then lists at the new line.

---

## M1 review

*(2026-11-07, M1-03; an Opus subagent read `git diff $(git merge-base HEAD origin/main) -- lib prompts tests docs
journal CLAUDE.md templates README.md` with one job: prove `memory` reverts nothing but the two files, and that no
other role's `restrict` call changed.)*

**Both claims hold. 0 Critical, 0 Important, 3 Minor.**

- **`memory` reverts only the two files.** On a copy of the `mem` run, the only `HARNESS: reverted edits …` commits on
  `run/mem/M1` are `M CLAUDE.md` (A) and `D .harness/project.md` (B). The net diff from `m0` keeps
  `journal/decisions/stub-A.md`, `lib/stub-A.sh`, `tests/stub-A.txt` and the work files. `memory_guard` runs only in
  the slot root (after `lane_cd`), so the pathspecs are root-exact. `--no-renames` turns a renamed `CLAUDE.md` into a
  restored D. restrict's leading `commit_all` is a no-op there.
- **No other call changed.** verify `record` (lane.sh:155), retro `nothing` (driver.sh:245), the initializer `record`
  (driver.sh:512) and entry-resume `record` (record.sh:611) are unchanged. lib/driver.sh is untouched.
- **Placement.** `commit_all` → `memory_guard; sync_lane` → `journal coding` → `lane_guard` → the limit branch → the
  fast gate. A limited session's edit is reverted and pushed too. The journal's file list is a net diff, so it drops
  `CLAUDE.md`.
- **Minor 1 (not fixed).** A session that merges a ref ahead of a stale `origin/main` (a local `main` with an unpushed
  `CLAUDE.md` line) has that line reverted and noted against it. This is contrived: the lanes fetch before every merge
  of main, and a session merging main itself is already noted by `lane_guard`.
- **Minor 2 (not fixed; recorded).** The base is the merge-base, so an earlier unguarded `CLAUDE.md` edit on the lane is
  reverted at the next coding session and noted against that session's feature. That covers a run in flight when M1
  deploys, and a driver killed between a session's end and the guard. A lane with no further coding session merges
  such an edit, because verify's `restrict record` keeps it. This is accepted: the first run after the merge starts
  clean.
- **Minor 3 (asked).** Claude Code also loads `.claude/CLAUDE.md` as project memory, and the spec names only
  `CLAUDE.md` and `.harness/project.md`. Adding it is a scope question for Michael (the entry's `questions`).
