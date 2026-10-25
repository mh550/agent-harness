# One memory model for the harness and its projects (2026-10-24)

**Superseded 2026-10-25** by `docs/specs/2026-10-25-memory.md`: K1 is its M2, K2 its M3 and K3 its M4. K4 was done
by hand in handoff chunk 3 Part 2 (`prompts/project-catchup.md`). This file stays for the model, the audit and the
detailed checks the new spec cites. Build from the new spec.

**Goal.** Every fact a session (harness-run or interactive) writes goes to the one store whose type fits it, and the
projects' existing files are brought into line once and then kept there by a cheap deterministic lint. The model is
CoALA's four memory types as the field guide applies them (`findings-and-research/Agent Memory Field Guide.md` ch. 1,
5, 11, 12): each type has its own writer, lifetime and trust level. **No new store, no LLM curator, no vector search,
no blocking guard.** Three small harness milestones (K1–K3) and one prompt Michael runs per project (K4).

**Rules.** `CLAUDE.md` binds: work only in the worktree, never touch real runs or real state, fakes mirror reality
(lint fixtures are copied from the real project files cited below, trimmed, never typed from memory), every behaviour
visible in `harness-log.md` and checked in `tests/run.sh` (written first, watched failing), `bash -n` / `node --check`
on every file touched, a decision file per behaviour change, `docs/architecture.md` and `README.md` in the same
milestone. `MERGE_POLICY=pr`. Proceed on the defaults below and record them; never park.

---

## The model (what K1 writes down)

| Type | What it holds | Store | Writer | Lifetime | Bound |
|---|---|---|---|---|---|
| **Working** | what this session sees | the prompt + `context.md` (E4) + auto-loaded `CLAUDE.md` | driver | one session | `CONTEXT_PACK_BYTES`; CLAUDE.md lint cap |
| **Episodic** | what happened, what was tried, what failed | `entries.jsonl` (rendered `progress.md`), `harness-log.md`, retros, plans, `brief.md` | driver, from each session's `entry.json` | append-only, forever | the pack bounds the *view*, not the record |
| **Semantic** | what is true now: decisions, gotchas | the project's **one** decisions file (current rule set); `## Gotchas` in `CLAUDE.md` | sessions, edited **in place**, reviewed in the milestone PR | until overturned (then rewritten in place, one `Updated in place <date>: …` line; history is git) | Gotchas ≤ 15 lines |
| **Procedural** | how to work here | `CLAUDE.md` (all but Gotchas), `.harness/project.md`, prompts, policy, skills | Michael (sessions propose via `proposed_changes` / `questions`) | stable across nights | lint cap |
| *nowhere* | anything derivable from code, git or the suite (test counts, file lists, prop names, constants) | — | — | — | — |

Two corollaries: **night scope** ("tonight", what to drop, queue order) is episodic and belongs in the run brief
(`--brief`), never in CLAUDE.md or project.md; and a **lesson from an incident** becomes a guard in the driver first
and a prompt line only when it can't be one (`Coding agent supervision layers.md`: turn judgments into checks;
Arize: a fact in memory isn't a fact applied).

## What exists (found 2026-10-24)

Harness (on `origin/main`, after E1–E4):

1. **Semantic facts die with the run.** `prompts/initializer.md` sends "where things live, gotchas" to `discoveries`
   affecting `"run"`: semantic content in an episodic, run-scoped store. The next run's initializer starts without it.
2. **No session is told where a fact goes**, only that decisions go "where the project rules say" and that
   `progress.md` is rendered. Interactive sessions in the projects get no rule at all.
3. **The initializer pre-assigns decision numbers in feature steps** that collide with the decisions file
   (rane `progress.md:216`: "its step names D13, which is taken"; `decisions.md:101` the same for D10).

Projects (read-only audit of rane-one-mixxx, hit_list, dj-crate-streaming, portfolio_site, pathways, voice-concierge;
four of them read without grep, so counts there are partial):

| Pattern | Projects | Evidence |
|---|---|---|
| Overturned decisions left standing beside the new rule | 6/6 | rane `decisions.md:110` (D15 "Superseded in part by D17"), portfolio `docs/specs/2026-10-18-portfolio-v2.md:47-49`, hit_list `APP_SPECIFICATIONS.md:7` `[SUPERSEDED]` kept "for history", dj `next-session-design.md:68-70` |
| Decisions split over several spec files (ID collisions in two) | 5/6 | portfolio `v3/progress.md:11-12` "they already collide, so never renumber"; hit_list D1–16 and D17–32 in two specs |
| Night scope in procedural memory | 5/6 | pathways `.harness/project.md:18-24` ("no rename tonight"), hit_list `OVERNIGHT.md` (539 lines), dj `CLAUDE.md:73-76`, voice `CLAUDE.md:16` |
| Hand-kept test counts, drifting | 5/6 | dj `CLAUDE.md:16` ~1,120 vs 1,523; N5-01 un-passed for "stale test count 1,515 vs 1523" (`progress.md:43`); rane `CLAUDE.md:49` "8" vs 27 |
| Gotchas only in `progress.md`, rediscovered each run | ≥ 3/6 | rane: "pw-record exits 1 after a good recording" 15 times, "tools-usage test" 10 times, in neither CLAUDE.md nor README; voice: the 250-line cap and the scratch-dir rule |
| CLAUDE.md full of code-derivable detail | 2/6 | portfolio 273 lines (`:96-151` component internals), hit_list 145 lines |

The pattern to copy exists: dj's `docs/hard-won-facts.md` ("Learned in the N1–N4 run") and rane's `decisions.md:3-5`
header ("the current rule set… rewritten in place", commit `266f369`).

## Depends on (rebase on what is already there)

| Spec | Overlap | What to do |
|---|---|---|
| `2026-10-22-retro-followups.md` **F** | F1 (edit-in-place rule in coding/initializer prompts), F2 (resolved questions leave the pack), F3 (the decisions file's current lines in the pack) | **F is not built yet** (2026-10-24). K1's block **contains** F1's rule, so whichever lands second replaces the other's prompt lines with the block (one rule, one place). F3 and memlint check 4 both need "the project's decisions store": **one** function, `decisionsStore(worktree)` in `lib/memlint.mjs` (*builder's call*: it reads `DECISIONS=` from `.harness/config.sh`, else `docs/decisions.md` if it exists, else none), which F3 imports. K3 reports projects with no store; K4 creates it. |
| `2026-10-22-retro-followups.md` **E** | the retro backlog is the harness's own semantic store (edited in place by status) | nothing to change; "skip parked features" (4 retros) belongs there. |
| `2026-10-22-n8n-events.md` **A2** | the ID glossary | derive it from the project's decisions file and feature list; no glossary store of its own. A note for that run, not a change here. |
| OOM finding (`findings-and-research/2026-10-24-oom-from-unbounded-test-diff.md`) | its step 4 is a lesson | its own spec: cgroup caps first (the guard), the one prompt line second. Not in this spec. |
| `2026-10-22-tmux-and-queue-hygiene.md` | none | — |

---

## K1 · One routing rule, in every session's view

1. **The block** (about 7 lines, wording the builder's, content fixed):
   `## Where things go` — what happened, tried, failed → your `entry.json` · a decision → the decisions file named
   below; overturned → rewrite the entry in place plus one `Updated in place <date>: …` line, never a new entry beside
   a dead one · a fact a fresh session would otherwise rediscover → one line in CLAUDE.md `## Gotchas`, edited in place
   · tonight's scope → the brief, never CLAUDE.md · how to work here → Michael's (say it in `proposed_changes`) ·
   anything the code, git or the suite can tell → nowhere (no test counts, file lists or constants).
2. **Where it lives.** `templates/project/CLAUDE.md` gains the block and an empty `## Gotchas` (max 15 lines) after
   `## Decisions and plans`, and loses its stored test count (`<count> tests, <duration>`); `prompts/draft-claude-md.md`
   asks for both and stops asking for a count. `templates/project/config.sh` gains a commented `DECISIONS=` (a file,
   or a directory of one-file-per-decision). `prompts/parts/rules.md` appends the block **only when the project's
   CLAUDE.md has no `## Where things go` heading**, and also when there is no CLAUDE.md at all (pathways), so projects
   not yet tidied get it and tidied ones don't pay for it twice. This repo's own `CLAUDE.md` gets it too, in the
   harness's wording: decisions are one file each in `journal/decisions/`, an overturned one is edited in place in its
   own file, never numbered (`decisions/2026-10-21-one-file-per-decision`); the harness's `DECISIONS=journal/decisions`.
   A decision store that is a directory has no numbers, so the numbering rule below applies only to a single file.
3. **Who may edit Gotchas.** Coding and initializer sessions. Verify and retro sessions run under `restrict`, which
   reverts any such edit, so their variant of the block says: a fact worth keeping goes in your entry's
   `discoveries` (affecting `"run"`), and the next coding session promotes it. `restrict` is unchanged.
4. **Prompts stop contradicting it.** `initializer.md`: durable gotchas → `## Gotchas`; run-only facts →
   `discoveries` `"run"`; "where things live" → nowhere unless it isn't obvious from the tree. A step never names a new
   decision number: it says "record as a new decision", and the session takes the next free number from the file when
   it writes. `coding.md`'s *Decisions* bullet points at the block instead of restating it.
   **Known risk, accepted** (recorded in K1's decision file): two branches writing the same project's numbered file at
   once (a run and an interactive session) can take the same number, as `D-H` numbers did before PR #6. The queue
   allows one run per project; K4's prompt refuses to start while a run on that project is in flight.
5. `docs/architecture.md` gains a short **Memory model** section: the table above, mapped onto §4's rows.
6. **Checks:** a coding, initializer and verify prompt for a project whose CLAUDE.md lacks the heading contains the
   block once (verify's variant without the Gotchas edit); with the heading, not at all; with no CLAUDE.md, once. The
   initializer prompt no longer sends gotchas to `discoveries`.

## K2 · Gotchas promoted, in place, visible

1. `coding.md` *Finish* gains one step: if you hit something a fresh session would hit again (it appears in an
   earlier entry's dead ends or discoveries in `context.md`, or it cost you real time) and `## Gotchas` doesn't have
   it, add one line (≤ 160 characters, ending `(<run> <date>)`); if a line there is now wrong, edit it; at 15 lines,
   replace the least useful. Never rewrite the section wholesale (ACE: whole rewrites collapse detail).
2. The driver compares the `## Gotchas` section at the session's start and end commits and logs
   `note "<feature>: gotchas +<a> ~<e> -<d>"` when it changed; nothing else. Review is the milestone PR diff.
3. **Checks:** a stub session that adds a gotcha line yields that note; one that touches nothing yields none; the
   coding prompt contains the step.

## K3 · Memory lint: deterministic, notes only

1. `lib/memlint.mjs` (pure, exported, usage header; CLI `memlint <worktree>` printing one finding per line). Four
   checks, on `CLAUDE.md`, `.harness/project.md` and the decisions file CLAUDE.md names:
   1. **Size:** CLAUDE.md over `MEMLINT_LINES` (default 120); `## Gotchas` over 15 lines.
   2. **Derivable counts:** a stored test count (`<n> tests` / `<n> passing` style) in CLAUDE.md or project.md.
   3. **Night scope** in CLAUDE.md or project.md (`tonight`, `this run`, `this slice`, `as of <date>`; the list in the
      file).
   4. **Decisions:** `decisionsStore()` finds no store; a single-file store lacks a current-rule-set header; an entry
      (or, for a directory store, a file) carries a supersession marker (`supersed`, `[SUPERSEDED]`, `replaced by`,
      `overturned`) with no `Updated in place` line. A closed legacy file (the harness's `journal/decisions.md`) is not
      the store and isn't checked.
2. **Where it runs.** At run start, beside the deploy-guard check: each finding is a `note "memlint: …"` in
   `harness-log.md`; the run never stops for it. `harness memlint <project>` prints the same for Michael. The retro
   already reads `harness-log.md`, so a project that drifts shows up there without a retro change.
3. **Checks:** fixtures trimmed from the real files above (dj `CLAUDE.md:16`, pathways `project.md:18-24`, rane
   `decisions.md:3-5` and `:110`) each yield their finding; rane's header plus a rewritten entry yields none; a run
   start on a fixture project logs the notes and carries on.

## K4 · Bring the six projects into line once (Michael runs it)

`prompts/memory-tidy.md`, used like `draft-claude-md.md` but interactively, one project per sitting, because some
choices are Michael's: `cd ~/projects/<p> && claude "$(cat ~/projects/agent-harness/prompts/memory-tidy.md)"`. It
works on a branch, commits in small steps and opens a PR. In order:

1. Run `node ~/projects/agent-harness/lib/memlint.mjs .` and keep it open as the to-do list.
2. **One decisions file** (`docs/decisions.md` unless one exists), with rane's header. Gather every D-table from the
   specs into it **keeping each ID**; where IDs collide, ask Michael (default: prefix with the source, e.g. `v2-D12`,
   and leave a one-line pointer in the old spec). Overturned entries are rewritten in place.
3. **Night scope out of procedural files:** `OVERNIGHT.md`, `STATUS.md` and dated runbooks move to `docs/runbooks/`
   (episodic); "tonight" lines leave CLAUDE.md and project.md.
4. **No stored test counts** in CLAUDE.md, README or architecture docs.
5. **Gotchas promoted:** grep the committed `.harness/runs/*/progress.md` "next session must know" lines and
   discoveries; a fact seen in two or more entries and absent from CLAUDE.md becomes a `## Gotchas` line (dj may point
   at `docs/hard-won-facts.md` instead).
6. **CLAUDE.md cut** to the template's sections plus the block; detail the code already states is deleted, not moved.
7. memlint is clean, or each remaining finding is a decision Michael made, noted in the PR.

The spec's audit table is where to start each project; the prompt itself names no project.

---

## Out of scope

- An LLM curator, embeddings, or a facts collection with reconciliation (field guide ch. 5: start with one small file).
- Changing the journal or the context pack (E4) beyond what F does.
- Claude Code's own memory under `~/.claude`: the block can be pasted into Michael's user `CLAUDE.md` by him if he
  wants interactive sessions outside these repos to follow it.
- Retros that describe an earlier segment of a continued run (rane, hit_list): a real episodic bug; a backlog item.
- **Known risk, recorded in K1's decision file:** `claude -p --bare` skips CLAUDE.md and is documented to become the
  `-p` default. Since `decisions/2026-10-21-no-double-claude-md` stopped pasting CLAUDE.md, that change would silently
  drop procedural memory and Gotchas from every session. On a Claude Code upgrade, check, and restore the paste if so.

## How Michael judges it

By reading what already exists; this spec adds no `summary.json` field or trends column. The `memlint:` notes in each
run's `harness-log.md` (or `harness memlint <project>`) fall to zero after K4 and stay there; rediscovered gotchas stop
recurring in entries; `wc -l CLAUDE.md` doesn't creep; E1's median orientation cost doesn't rise
(`harness trends --by version`). No cost claim without E2.

## Milestones

| M | Contents | After |
|---|---|---|
| K1 | §K1 (the block, template, prompts, architecture Memory model) | F if it landed first (rebase; replace F1's lines) |
| K2 | §K2 (gotcha promotion + driver note) | K1 |
| K3 | §K3 (memlint + run-start notes + `harness memlint`) | K1 |
| K4 | §K4 (`prompts/memory-tidy.md`, README lines; Michael runs it per project) | K3 |

Each milestone gets its decision file (`journal/decisions/<date>-<slug>.md`), its `architecture.md` / `README.md`
lines and its checks in `tests/run.sh`, written first and watched failing. The suite must end green.
