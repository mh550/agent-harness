# The memory curator: itemized operations, a tier the driver derives, a protected list that is fixed

*(2026-11-07, run agent-harness-2026-11-07-2, M2 (skeleton by M2-01; the choice completed by M2-04, rejected and the
invariants by M2-05); spec `docs/specs/2026-11-07-memory-curator.md` §M2; plan `docs/plans/2026-11-07-M2-curator.md`;
`findings-and-research/Agent Memory Field Guide.md` lines 707–736 (ACE's itemized delta updates, context collapse),
820–844 (provenance), 1031–1055 (the ETH `AGENTS.md` study), 1081–1121 (memory poisoning and the write gate).)*

- **Finding:** after M1 (decisions/2026-11-07-memory-one-writer) no session writes project memory, so a project fact
  stays in its entry and never reaches `CLAUDE.md`. The guide's answer for an LLM that maintains a memory file is a
  curator that emits **itemized operations**, never a rewritten file: "Small anchored edits can be validated, diffed
  and reverted" (ACE, 707–736). Every memory needs its provenance (820–844), a longer context file is followed less
  and costs more (1031–1055), and a line that arrived in a tool result must not be written as the agent's own finding
  (1081–1121). Where the curator may run is fixed by `record_pr`'s guard (`record_pr` in `lib/driver.sh`, its `":!$RUN_DIR"` diff): a change on
  `harness/<run>` outside `$RUN_DIR/` kills the run's record PR, so the curator must not write where the retro runs.
- **Choice:**
  - **The protected list, fixed and matched by prefix** on the heading text after `## `: `Live system`,
    `Off-limits`, `On-limits`, `Hardware facts`, `Hardware and Mixxx rules`, `This repo runs Michael's harness runs`.
    A prefix, so rane-one-mixxx's `## Hardware facts (verified 2026-10-19 on Michael's desktop)` and
    `## Hardware and Mixxx rules (binding on every session)` are protected with their suffixes. A new protected
    heading is added to this list, never inferred.
  - **The tier rule, derived by the driver** (`tierOf` in `lib/curator.mjs`) from the heading alone; the session's
    `tier` field is a claim, counted when it disagrees and never read for a decision. Tier 3 is the protected list
    (a proposal in the PR body, never applied); tier 1 is `## Gotchas` (*default*: the one fact section all eight
    projects have); tier 2 is every other heading (in the PR body, never committed, *default*). The eight projects'
    headings and their tiers: `tests/fixtures/memory/headings.txt`.
  - **The operations' shape**: `memory-ops.json`, an array of `{op, file, section, anchor, text, tier, why, from}`;
    `op` add, replace or delete; `file` `CLAUDE.md` or `.harness/project.md` (*default*); `from`
    `entries.jsonl:<n>`; a `## Gotchas` text at most 160 characters ending `(<run> <date>)` (*default*); an invalid
    file refused whole with its first reason (*default*, as the retro's proposals).
  - **Anchors** match one line of the section by the `key` normalizer of `lib/entries.mjs`, exported and imported,
    never copied (*default*); zero or two matches drop the op, naming the anchor.
  - **The write gate**: an op's text must be a `project` discovery or a `proposed_changes` string of the
    entry its `from` names, not resolved later (*default*); a `delete` is exempt, its anchor must exist. The gate runs
    before the protected test (M2-02), so a tier-3 proposal reaches Michael only when an entry states it, and before
    the dedupe, so among the ops of one `key` that pass it the latest `from` is kept (an op naming no entry never
    eclipses one that does). Anchors, the dedupe and "already there" compare by `key` after a leading list marker
    (`- `, `* `, `1. `) and the `(<run> <date>)` suffix are cut. *Tightened by M2-02's review:* the gate compares the
    whole text, not its `key`: the op's text (suffix aside) is the stated item's or a cut of it at least 40
    characters long (or the whole item), so no unstated tail rides on a stated first 40 characters; and a
    `proposed_changes` string (Michael's: how to work here) gates a tier-2 or tier-3 op, never a tier-1 commit
    (*default*).
  - **The protected text, by raw lines** (M2-05's review): after each write the protected sections' lines (each from
    its raw `## ` line to the next, fences ignored, so an unclosed fence can't hide one) must be as they were; a write
    that changes them is dropped, `would change the protected section <heading>`, whatever entry its anchor matched.
    The tier rule says what an op may target; this says what its write may touch (invariant 2 on a malformed file).
  - **The file as text**: a heading inside a ``` or ~~~ fence is no heading (`sectionEntries`, `headingLines` in
    `lib/memlint.mjs`), a fenced block is one entry; a section heading that appears twice drops the op (which one is
    meant is Michael's); a CRLF file keeps its line ends; a symlinked `CLAUDE.md` or `.harness/` is no file (apply
    never reads or writes through a link); `why` is one line, a `section` at most 200 characters, and an `@login` outside a fence in the body (the section names included, M2-05) is broken
    with a zero-width space so the PR notifies no one.
  - **The cap**: `lintText` re-run on the result; over 120 lines or 15 `## Gotchas` entries, and grown on that
    measure (*default*), refuses the tier-1 commit whole with one note. An `add` past the cap passes only with an
    anchor, the line it evicts.
  - **`memory_pr`, as built (M2-04, `lib/record.sh`)**, called by `curator()` after its restrict and the rescue:
    - **The base** (`memory_base`, before the session, which reads its texts in `$SCRATCH/memory-base/`):
      `origin/<main>`, unless origin has `harness-memory/<run>` and main lacks its tip. Then it is that tip when the
      branch's `memory: <run>` PR is open (reused: `MEM_URL`) or the branch has no PR at all (a push whose `pr create`
      failed: the PR opens on it now). A closed PR, or one titled otherwise, stops the curator with one note,
      `memory PR: none (harness-memory/<run> is on origin and main lacks it, its PR CLOSED; delete the branch to
      curate again)` (*default*: never a branch over one Michael closed, never a force-push). A tip main has taken
      (a merged PR whose branch stayed) is cut from main again, the push a fast-forward of it. GitHub or origin not
      answering is no answer: one note, no curator, rather than a wrong base. A reused tip is the driver's own or
      nothing (M2-05's review: a session could push there, out of `restrict`'s reach): every commit past main must be
      `memory: <run>: <n> facts`, no merge, touching `CLAUDE.md` or `.harness/project.md` only (`memory_foreign`);
      else `memory PR: none (harness-memory/<run> has a commit the driver would not write, <sha> "<subject>" (<paths>);
      delete the branch to curate again)` and no curator. A reused tip without a PR gets its PR even when this
      segment commits nothing (`memory_open`). *Known limit:* a squash-merged memory
      PR whose branch stayed reads as "main lacks it" and stops with the delete-the-branch note.
    - **The worktree**: `git worktree add --detach $SCRATCH/memory <base>` (*default*: detached, so no local
      `harness-memory/<run>` is left behind), removed after every path (`--force`, then a prune), so gc never meets a
      stale registration. `curator.mjs apply` writes only there; the record branch's tree (`$RWT`) is never checked
      out or written, so `record_pr`'s `":!$RUN_DIR"` guard stays untripped (tests/checks/memory-branch.sh's record-PR
      check).
    - **One commit** of the tier-1 ops, `memory: <run>: <n> facts`, of the files apply changed only, pushed to
      `harness-memory/<run>` (never forced: on a reused head it moves forward). Tier 2 and 3 are never committed.
    - **The PR**: `gh pr create --base <main> --head harness-memory/<run> --title "memory: <run>" --body-file`, left
      for Michael (`MEMORY_POLICY=pr`, *default*); on a reused head `pr edit --body-file`, also when this segment
      commits nothing (its proposals still reach him), the body this segment's over the earlier segments' while
      both fit under 60000 bytes (*default*), so the PR's first commit stays explained.
      The body (`curator.mjs body`: the counts, the applied ops, tier 2 to paste, the tier-3 proposals, every dropped
      op with its reason and `from`) is kept as `memory.md` in the run record (*default*), so tier 2 and 3 reach
      Michael through the record PR even when no memory PR opens.
    - **The cap refusal**: a breach refuses the tier-1 commit whole: no commit, no push, no PR, one note `memory:
      tier-1 commit refused (<breach>)` and `memory PR: none (no tier-1 change); the body is in memory.md`
      (*default*). The same add with an anchor evicts that line and lands as one edit. `MERGE_POLICY=off` pushes
      and opens nothing, noted the same way (*default*, as `record_pr`). An `apply` that answers nothing is
      `memory: apply failed (see run.log)`, treated as refused.
    - **The notes**, each outcome once in `harness-log.md`: `memory: <ops> ops · <applied> applied · <dropped>
      dropped · <proposed> proposals` (*default* wording), one `memory: dropped <op> <section> (<reason>)` per dropped
      op (the refused ones aside: their one note covers them), `memory: tier re-derived for <n> ops`, then the PR's
      `memory PR opened; left for Michael (MEMORY_POLICY=pr) · <url>`, `memory PR updated · <url>` or why none.
    - **`$STATE/memory.json`**: `{ops, applied, dropped, proposed, pr}` (the PR's URL or `null`; `invalid` beside
      them for a refused file), for M3's summary (*default*).
  - **`MEMORY_POLICY=pr|off`** in `lib/config.sh` beside `RECORD_PR` (`pr` *default*; `off` runs no curator and
    writes no note; `auto` is M3's), **`CURATOR_MODEL=opus`** (*default*).
- **Rejected:**
  - **A rewritten file.** A curator that returns a whole `CLAUDE.md` can drop or reword any line unseen, and a diff of a
    rewrite can't be validated op by op (ACE's context collapse, 707–736): operations only, applied by the driver.
  - **An inferred protected set** (headings that "look like rules", or a list read from the project). Whatever infers
    it can be talked out of it; the list is fixed in `PROTECTED`, and a new protected heading is a change to it.
  - **A trusted `tier` field.** The session's `tier` is a claim: a tier-3 op claimed as tier 1 would commit into
    `## Live system`. `tierOf` decides from the heading; a disagreement is counted (`rederived`), never followed.
  - **A curator that commits tier 2.** A line under a workflow heading is how-to-work, Michael's
    (the routing block, `decisions/2026-10-26-where-things-go`): it reaches him in the PR body to paste, never as a commit.
  - **A curator that writes where the retro runs.** A change on `harness/<run>` outside `$RUN_DIR/` stops the record
    PR (`record_pr`'s `":!$RUN_DIR"` guard), so the apply works in a detached scratch worktree, never in `$RWT`.
  - **A local or force-pushed memory branch.** A local `harness-memory/<run>` is one more ref for gc to reason about,
    and a force-push could drop a commit Michael already reviewed: detached worktree, fast-forward pushes only.
  - **A curator for every stub run.** The suite's base config and every from-scratch test config set
    `MEMORY_POLICY=off`: a curator session in every stub run would move other files' session counts and notes.
- **The spec's two invariants, and the checks that prove them:**
  1. *The curator never writes a project file.* `curator: a curator's edits to CLAUDE.md and lib/ are reverted with
     one note, its memory-ops.json kept and the record PR opened` (tests/checks/curator-run.sh: the stub curator edits
     both, `restrict … nothing` reverts them, and the record PR's guard holds); `memory PR: a memory branch with a
     commit the driver would not write stops the curator with one note; nothing pushed` (a push outside `restrict`'s
     reach is never a base); `memory PR: the run's record PR opens too` (tests/checks/memory-branch.sh: the record branch has no
     change outside the record, so the guard held) and `memory PR: the commit changes CLAUDE.md alone` (the driver's
     one commit, on `harness-memory/<run>`); `curator.mjs: main apply writes the worktree's CLAUDE.md and prints one
     JSON line` (apply writes only under the worktree it is given, never through a symlink).
  2. *No operation touches a protected section.* `curator.mjs: an op on a protected section is dropped and carried as a
     proposal`, `curator.mjs: an op whose write would change a protected section's lines is dropped` (the unclosed
     fence), `curator.mjs: tierOf protects a heading by prefix, its dated or parenthesised suffix aside`,
     `curator.mjs: tierOf gives every heading of the eight projects its fixture tier`, `curator.mjs: apply derives the
     tier from the heading and counts a claim that disagrees` (tests/unit/curator.test.mjs), and the stub run's
     `memory PR: an op on Live system is dropped with a note and carried as a proposal; an unmatched anchor is dropped
     naming it` (tests/checks/memory-branch.sh).
- **Known limit** (M2-05's review): `restrict` reverts what the curator changes in the run's worktree; a write
  elsewhere (another checkout, a push) is bounded only by the session's permission mode, as every read-only role's
  is. The memory branch is guarded (`memory_foreign`); a deny list for the curator's session (`git push`, `gh`) is a
  proposal for Michael, not built here.
- **Checks:** M2 adds 47 check names (23 `curator.mjs:` unit tests, 8 `curator:`, 15 `memory PR:`, 1 `summary.mjs:`;
  M2-05's review added three and renamed one of M2-03's in place), replaces and removes none against main: within its
  budget of 60.
