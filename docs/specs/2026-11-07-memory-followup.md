# The memory curator's follow-up: tier 2 as its own PR, the twin files guarded, the cap per operation, a denied session, an `auto` that keeps its audit trail, and answers the next curator reads (2026-11-07)

**Goal.** Run `agent-harness-2026-11-07-2` built the curator (`docs/specs/2026-11-07-memory-curator.md`, M1–M3, PRs
#125–#127) and recorded nine questions, each answered with a default. Michael's walkthrough of 2026-11-07
(`journal/learning/2026-11-07-memory-curator.md`) answered them; this spec builds the six answers that change code
(§13 group A). **N1** gives tier 2 (conventions, workflow) its own branch and PR so its acceptance can be counted, guards
the two files Claude Code loads beside `CLAUDE.md`, and checks the cap per operation instead of refusing a whole commit.
**N2** passes the curator session a deny list, stops `MEMORY_POLICY=auto` from merging a PR whose body refresh failed,
and gives Michael `harness memory accept|decline <run>/<n> --why`, recorded in the ledger and read by the next curator.
Two milestones in series: N1, then N2.

**Provenance (the nine answers, by question number; `journal/learning/2026-11-07-memory-curator.md` §11, bound by the
`Updated in place 2026-11-07` lines of the three decision files).**

| # | answer | here |
|---|---|---|
| 1, 4 | tier 2 on its own branch and PR, a diff Michael merges, counted separately, never reached by `auto`; tier 3 stays text (`decisions/2026-11-07-memory-tiers`) | N1-01 |
| 2 | Opus stays the default for reviews | N1-04 and N2-04 run on Opus |
| 3 | guard `.claude/CLAUDE.md` too; check whether `.claude/rules/*.md` loads the same way (`decisions/2026-11-07-memory-one-writer`) | N1-02 (it does; the page is cited there) |
| 5 | the cap's default stands: an over-cap file may improve, not grow; `capCheck`'s whole-commit refusal becomes per-op (`decisions/2026-11-07-memory-tiers`) | N1-03; the prune by hand is F3c, `docs/plans/2026-11-07-claude-md-prune-checklist.md` |
| 6 | a `proposed_changes` string never gates a tier-1 commit | unchanged; N1-01 keeps the gate as it is |
| 7 | build the deny list: `Bash(git push:*)`, `Bash(gh:*)`; `memory_foreign` stays the second layer (`decisions/2026-11-07-memory-tiers`) | N2-01 |
| 8 | flipped: under `auto` a failed body refresh skips the merge, leaves the PR open with one note (`decisions/2026-11-07-memory-policy`) | N2-02 |
| 9 | the decisions-store lint stays a segment-start note | unchanged |
| 10 | `pr` stays the default; `auto` per project on the count, never box-wide; the one-click review is the n8n flow | unchanged here; the review surface is F3d (not this spec); N2-03 is the accept/decline verb the walkthrough asked for (§12) |

**Source.** `journal/learning/2026-11-07-memory-curator.md` §9 (what was built), §10 (the measurement points every
Predictions row below names), §11–§13; `journal/decisions/2026-11-07-memory-{one-writer,tiers,policy}.md`;
`docs/plans/2026-11-07-memory-followup-handoff.md` §3 A; `docs/plans/2026-11-03-test-suite-redesign-dispatch.md` rows
F3b–F3e, Decisions 21 and 22; `lib/curator.mjs` (`FILES`, `PROTECTED`, `validate`, `tierOf`, `capCheck`, `apply`,
`body`); `lib/driver.sh` (`curator()`, `ro_rescue`, `ledger()`); `lib/record.sh` (`restrict`, `memory_guard`,
`memory_base`, `memory_foreign`, `memory_json`, `memory_pr`, `memory_body`, `memory_open`, `memory_merge`,
`memory_edit`, `memory_wt_gone`, `session()`'s `claude -p … --permission-mode auto` line); `lib/debrief.sh` (the one
session already run under `--disallowedTools`, its `DENY` list); `lib/memory.sh`; `lib/summary.mjs` (`memoryOf`,
`memoryLine`, `memoryRow`, `memoryState`, `memoryShown`, `memoryView`); `lib/memlint.mjs`; `prompts/curator.md`;
`tests/stub-claude.sh` (`# Curator session`, `STUB_CURATOR_OPS`, `STUB_CURATOR_EDITS`), `tests/stub-gh.sh`
(`STUB_GH_DOWN`, `STUB_GH_DOWN_ONLY`, `pr edit`), `tests/fixtures/memory/`; `tests/unit/curator.test.mjs`,
`tests/unit/summary.test.mjs`, `tests/checks/memory-branch.sh`, `memory-one-writer.sh`, `memory-prompts.sh`,
`curator-run.sh`, `memlint-run.sh`. Claude Code's documentation, read 2026-11-07: https://code.claude.com/docs/en/memory
(project memory is `./CLAUDE.md` or `./.claude/CLAUDE.md`; "Rules without `paths` frontmatter are loaded at launch with
the same priority as `.claude/CLAUDE.md`"; "All `.md` files are discovered recursively, so you can organize rules into
subdirectories"), https://code.claude.com/docs/en/cli-reference (`--disallowedTools`, "Deny rules", one quoted rule per
argument; `--settings <file|json>` overrides keys for the session), https://code.claude.com/docs/en/permissions ("Rules
are evaluated in order: deny, then ask, then allow"; "An allow rule can't carve an exception out of a deny rule"; a
matching deny blocks the call whatever a PreToolUse hook returns; a Bash rule "doesn't match the same program invoked in
a different form").

**Rules.** `CLAUDE.md` binds: worktree only; never touch real runs or real state; never a real notification; fakes
mirror the live API (a stub line is a captured shape, never a guess); every behaviour visible in `harness-log.md`,
`run.log` or a command's output and checked test-first in `tests/checks/` (tier by `decisions/2026-11-03-suite-tiers`'s
30 s rule, its names in `tests/fixtures/check-names.txt` and, fast, `check-names-fast.txt`), a pure function's in
`tests/unit/`; a check that duplicates an assertion replaces it and the old name leaves the fixture in the same
commit; `bash -n`, `node --check`; one decision file per milestone (`journal/decisions/<run date>-memory-rules-pr.md`
for N1, `<run date>-memory-session-and-answers.md` for N2); `docs/architecture.md` and `README.md` in the same
milestone as the code. **Proceed on the defaults written here; record them marked *default*; never park.**

**Three invariants no feature may break.** (1) **The curator never writes a project file**: it emits `memory-ops.json`;
the driver is the only writer. (2) **No operation touches a protected section**; `PROTECTED` is a fixed list of
headings, never inferred. (3) **The driver never merges tier 2.** A rules PR is Michael's to merge or close under every
`MEMORY_POLICY`; `memory_merge` is never called with its URL.

## Depends on

- `main` at or after `ee37df7` (PR #134: the dispatch list with Decisions 20–22 closed; M1–M3 and A1–A2 are in).
- Run `agent-harness-2026-11-07-3` (the n8n events run) must have ended: one run per project
  (`decisions/2026-10-21-queue-one-run-per-project`), so `harness queue add` holds this run until it does. Its `finish`
  is the first real curator run; its `memory: agent-harness-2026-11-07-3` PR, if one opens, has the pre-N1 body shape,
  which `harness memory` keeps reading (a `memory.jsonl` row without `tier` is a facts row, *default*).
- N2 after N1: N2-02 reworks the merge step N1-01 restructures; N2-03's drop-by-answer rides on N1-03's per-op drop
  path and numbers the proposals N1-01's bodies carry. N1's first feature `after: []`, N2's `["N1"]`.
- Nothing here touches the n8n events contract (`docs/specs/2026-10-22-n8n-events.md`, v1): no new event kind, no
  verb. The memory PRs' one-click review is F3d, after that run (Decision 21 (a)).

---

## N1 · The tiers and the files: tier 2 is a PR, the twins are guarded, the cap is per operation

**Finding.** Three things are true of the curator on `main` today. (a) Tier 2 is body text: `apply` puts a tier-2 op in
`proposed`, `body` renders it under *For you to paste*, and nothing records whether Michael pasted it. §10's fourth
measurement point (acceptance per tier and per section) says it plainly: *impossible while tier 2 is body text (nothing
to count)*. Tier 1 is counted because it is a commit on a branch with a PR whose state `gh` reports; tier 2 needs the
same shape to graduate section by section, which is the hands-off path Michael chose (§12, answer 1). (b) `restrict`'s
`memory` spec and the curator's `FILES` name `CLAUDE.md` and `.harness/project.md`. Claude Code loads `./CLAUDE.md` *or*
`./.claude/CLAUDE.md` as project memory, and every `.claude/rules/**/*.md` without `paths` frontmatter "with the same
priority as `.claude/CLAUDE.md`" (https://code.claude.com/docs/en/memory, read 2026-11-07). A coding session that writes
a rule into `.claude/CLAUDE.md` or `.claude/rules/x.md` binds every later session, unreverted and uncounted: a guard
beside an unguarded twin is no guard (answer 3). No project of the eight has either file today (`ls
~/projects/*/.claude/{CLAUDE.md,rules}` on 2026-11-07: none), so the guard costs nothing now and holds when one appears.
(c) `capCheck` runs once on the result and `apply` then moves *every* applied op to `dropped` with `refused: …` and
returns the texts unchanged: one anchorless add on a file at 15 Gotchas loses the four good ops beside it. §12 names it
as the one place the deterministic gate is too rigid; answer 5 keeps the rule (improve, not grow) and asks for the
check per op.

### N1-01 · Tier 2 lands on its own branch and PR, counted apart; the driver never merges it

**Choice.**

1. **The branch is `harness-rules/<run>`**, not `harness-memory/<run>/rules`: git cannot hold a ref `harness-memory/<run>`
   and a ref beneath it at once (a branch name is a file under `refs/heads/`, so `harness-memory/<run>/rules` would need
   it to be a directory; `git push` fails with *cannot lock ref*). A sibling prefix also keeps every existing reader
   unambiguous: `harness-memory/*` goes on meaning facts in `memory_foreign`, `memory_base`, the no-local-branch check
   and `harness memory`'s state reader. *Default*: the PR is titled `memory rules: <run>`; the commit `memory: <run>: <n>
   rules` (the facts commit stays `memory: <run>: <n> facts`).
2. **`apply` writes two text sets from the same base**: `texts` (tier 1, as today) and `ruleTexts` (tier 2), each the
   base plus its own tier's ops, so the rules commit is cut from the base and not stacked on the facts commit
   (*default*; stacked, the rules PR would carry the facts and could not be merged alone). The result gains `rules` (the
   tier-2 ops written, in order) and `ruleTexts`; `proposed` holds tier 3 only; `applied`, `dropped`, `rederived` as
   today. The write gate is unchanged (a `proposed_changes` string or a `project` discovery gates tier 2; a
   `proposed_changes` string never gates tier 1: answer 6). The protected raw-line check runs on the rules write too
   (invariant 2). **The cap is checked on the union**: tier 1's ops and then tier 2's applied to one shadow text, and a
   tier-2 op that breaches on the shadow is dropped (N1-03's reason), so merging both PRs can never pass 120 lines or 15
   Gotchas (*default*; the commit itself is still cut from the base).
3. **`memory_pr` becomes one path run twice** (`lib/record.sh`): for `facts` (`harness-memory/<run>`, subject `… facts`,
   title `memory: <run>`) and then `rules` (`harness-rules/<run>`, `… rules`, `memory rules: <run>`), each with its own
   base, reuse and foreign-commit check (`memory_base` and `memory_foreign` take the branch and the subject word), its
   own scratch worktree in turn (`memory_wt_gone` between: *default*, one worktree path reused), its own push (never
   forced) and its own PR opened or its body refreshed on a continue. *Default*: the curator session reads the facts
   tip as its base in `$SCRATCH/memory-base/` as today (the rules tip differs only in tier-2 sections, which the session
   may also target; an op whose anchor matches on neither is dropped as today). Facts first, then rules; a failure in
   one is its own note and does not stop the other.
4. **`MEMORY_POLICY=auto` merges the facts PR only.** The rules PR is `memory rules PR opened; left for Michael · <url>`
   under `pr` and `auto` alike; `memory_merge` is never called with its URL (invariant 3). `MERGE_POLICY=off` opens
   neither, as today. A closed rules PR with its branch still on origin stops the rules half with the same
   delete-the-branch note the facts half has.
5. **Bodies and the record.** The facts PR's body: the counts, *Applied (tier 1)*, the tier-3 proposals, *Dropped*, and
   one line `Rules of this run: <rules PR url>` (or `none`). The rules PR's body: the counts, *Rules (tier 2)* (each op
   with its `from` and `why`, as a diff reader wants it), the tier-3 proposals, *Dropped*, and `Facts of this run: <url>`.
   *Default*: tier 3 and the dropped ops appear in both bodies (a reader of either sees the run's whole memory outcome),
   and `memory.md` in the run record is the union. **Every tier-2 op and tier-3 proposal is numbered** `<run>/<n>`,
   rules first then proposals, in `memory-result.json` and in the bodies' headings (`### 3 · \`add\` CLAUDE.md · ## Live
   system (entries.jsonl:7)`): N2-03's verb names them. `memory-result.json` is copied into the run record beside
   `memory-ops.json` (*default*; it is small, and the ledger copies the record).
6. **Counted apart.** `memory.json` gains `rules` (count) and `rules_pr` (URL or null); `summary.json`'s `memory` carries
   both; the report's `Memory` row reads `2 applied · 1 rules · 0 dropped · 1 proposals · PR <url> · rules PR <url|none>`;
   `ledger/memory.jsonl` has one row per PR, keyed by `url` as today, with `tier: facts|rules` and `sections` (the `##`
   headings the PR's ops touched, for §10's per-section count later); `memoryState` reads a rules PR's own commits by
   the `… rules` subject and ignores GitHub's `Merge branch … into harness-rules/<run>` as it does the facts branch's;
   `harness memory` prints the tier in each line (`<run> · <project> · facts · 2/0/1 · <url> · open`, `<run> · <project>
   · rules · 1 · ## Code rules · <url> · open`) and two tally lines, `facts: merged unchanged a · edited b · closed c ·
   open d` and `rules: …` (*default* wording). The notes: `memory: <ops> ops · <a> facts · <r> rules · <d> dropped · <p>
   proposals` (replacing `… <a> applied …`), the facts PR's notes as today, the rules PR's `memory rules PR opened; left
   for Michael · <url>`, `memory rules PR updated · <url>`, `memory rules PR: none (no tier-2 change)`.
7. **`prompts/curator.md`** says where tier 2 goes now (a diff on `harness-rules/<run>` that Michael merges, never the
   driver) and keeps everything else. `tests/fixtures/memory/stub-three-ops.json` is unchanged: its `## Code rules` op
   now lands on the rules branch, which is what the checks below read.

**Checks (written first).** Pure, `tests/unit/curator.test.mjs`: `apply` writes a tier-2 op into `ruleTexts` and not
`texts`, a tier-1 op the reverse, with `proposed` holding tier 3 only; the union shadow drops a tier-2 add that would take
the merged file past 120 lines while each tier alone fits, naming the cap; a rules write that would change a protected
section's raw lines is dropped; `body` renders the facts body, the rules body and the union, the proposals and rules
numbered `<run>/<n>` in one sequence, each body naming the other PR. `tests/unit/summary.test.mjs`: `memoryState` reads
`memory: <run>: 2 rules` commits as the driver's and an Update-branch merge into `harness-rules/<run>` as neither;
`memory-line` writes two rows for a summary with both PRs, each with its `tier` and `sections`, replacing by `url`;
`memoryView` prints the tier per line and one tally line per tier, a row without `tier` counted as facts. Stub runs,
`tests/checks/memory-branch.sh` (slow): the `mp` run's workflow line lands as one commit on `harness-rules/mp` and not on
`harness-memory/mp`, its PR is `memory rules: mp` left for Michael, and its body names the facts PR (this replaces
`memory PR: the workflow line is not committed and is in the PR body with its entries.jsonl line`); the record PR still
opens; the notes count `2 facts · 1 rules`; `harness memory` lists two lines for `mp` with their tiers and two tally
lines, and `memory.jsonl` has two rows for `mp`; `mp`'s continue reuses the open rules PR (`pr edit`) as it reuses the
facts PR; under `MEMORY_POLICY=auto` (`ma`) the facts PR merges and the rules PR is left open with the one note and no
`gh pr merge` of its URL in `gh.log`; a rules branch on origin with a commit the driver would not write stops the rules
half with its note while the facts half still lands; no run leaves a local `harness-rules/*` branch or a registered
scratch worktree (replacing the `harness-memory` wording of that check).

**Files.** `lib/curator.mjs`, `lib/record.sh` (`memory_base`, `memory_foreign`, `memory_json`, `memory_pr`,
`memory_body`, `memory_open`, `memory_edit`), `lib/driver.sh` (`curator()`: the copy of `memory-result.json`),
`lib/summary.mjs`, `lib/memory.sh`, `prompts/curator.md`, `tests/unit/curator.test.mjs`, `tests/unit/summary.test.mjs`,
`tests/checks/memory-branch.sh`, `tests/fixtures/memory/README.md`, `tests/fixtures/check-names.txt`,
`docs/architecture.md` (components, the Memory curation state row, the branches and PRs table, the CURATOR step),
`README.md` (*Memory curator*, `harness memory`), `templates/user/config.sh` and `templates/project/config.sh`
(`MEMORY_POLICY`'s comment: `auto` merges facts only), `journal/decisions/<run date>-memory-rules-pr.md`.

### N1-02 · `.claude/CLAUDE.md` and `.claude/rules/**/*.md` are project memory and guarded as such

**Choice.**

1. **`restrict`'s `memory` spec** (`lib/record.sh`) becomes `CLAUDE.md .harness/project.md .claude/CLAUDE.md
   .claude/rules` (plain pathspecs from the root; `.claude/rules` is a directory, so every file beneath it, in any
   subdirectory, is reverted: added, edited or deleted). `.claude/settings.json`, `.claude/agents/`, `.claude/skills/`
   and a nested `docs/CLAUDE.md` stay code. `memory_guard`'s note names the file as today (`<feature>: reverted its
   .claude/rules/frontend/api.md edit (project memory is the curator's; say it in the entry)`). *Default*: the whole
   `.claude/rules/` directory, not `*.md` beneath it: Claude Code reads only `.md` files there, but a stray file in a
   rules directory is nothing a coding session should leave either, and one pathspec is one thing to prove.
2. **The curator's `FILES`** (`lib/curator.mjs`) gains `.claude/CLAUDE.md`; `memory_base` copies it to
   `$SCRATCH/memory-base/.claude/CLAUDE.md` when the base has it; `memory_foreign`'s path filter and `apply`'s
   `plain()` take it; the curator prompt names it when present (`{{MEMORY_BASE}}/.claude/CLAUDE.md`). *Default*:
   `.claude/rules/*.md` is guarded but is **not** an operation target in this spec: a rules file's name is the
   project's, not a fixed list, no project has one, and a `file` naming one is refused by `validate` as today (`file …
   is none of CLAUDE.md, .harness/project.md, .claude/CLAUDE.md`).
3. **memlint reads the twin** (`lib/memlint.mjs`): `size`, `gotchas`, `derivable-count` and `run-scope` run on
   `.claude/CLAUDE.md` as on `CLAUDE.md` (*default*: each file on its own cap, 120 lines and 15 Gotchas; one project
   with two prompt files is the finding below, not a shared budget), and one new finding, `twin`, when both exist:
   `.claude/CLAUDE.md:1 twin: CLAUDE.md exists too; Claude Code loads both as project memory`. So the pair is visible
   at every segment start (`memlint_check`) and in `harness memlint <project>`. `capCheck` caps `.claude/CLAUDE.md` as it
   caps `CLAUDE.md`.
4. **Not guarded, by choice**: `CLAUDE.local.md` (per machine, gitignored by Claude Code, so never in the diff `restrict`
   reads; a session's edit there binds that checkout only and dies with the worktree) and `~/.claude/rules/` (the user's,
   as `~/.claude/CLAUDE.md`: never touched by any run). Both are in *Not in this spec*.

**Checks (written first).** `tests/checks/memory-one-writer.sh` (fast): the sourced `restrict … memory` case also adds
`.claude/CLAUDE.md` and `.claude/rules/a/b.md` and edits `.claude/settings.json`: the first two go back, the third stays
(replacing `restrict memory: CLAUDE.md and .harness/project.md go back …`); a stub run where one feature's coding session
writes `.claude/CLAUDE.md` and adds `.claude/rules/r.md` (a new knob, `STUB_DOT_CLAUDE=<id>`) ends done with both
reverted on the branch and on main and two revert notes naming the files. Pure, `tests/unit/curator.test.mjs`: `validate`
accepts `.claude/CLAUDE.md` as a file and refuses `.claude/rules/x.md` naming the three; `capCheck` caps
`.claude/CLAUDE.md` as `CLAUDE.md`; `apply` writes a `## Gotchas` op into `.claude/CLAUDE.md` and never through a
symlinked `.claude/`. `tests/unit/memlint.test.mjs`: `lint` finds `twin` when both exist and nothing when one does, and
lints `.claude/CLAUDE.md`'s size and Gotchas on their own. `tests/checks/memlint-run.sh` (fast): a project with both
files gets the `twin` note before the initializer's, and `harness memlint` prints it. `tests/checks/memory-branch.sh`
(slow): one run on a project whose memory is `.claude/CLAUDE.md` alone lands its facts there (folded into an existing
seed if the file's time allows, else its own run).

**Files.** `lib/record.sh` (`restrict`, `memory_base`, `memory_foreign`), `lib/curator.mjs` (`FILES`, `plain`),
`lib/memlint.mjs`, `prompts/curator.md`, `tests/stub-claude.sh` (`STUB_DOT_CLAUDE`), `tests/checks/memory-one-writer.sh`,
`tests/checks/memlint-run.sh`, `tests/checks/memory-branch.sh`, `tests/unit/curator.test.mjs`,
`tests/unit/memlint.test.mjs`, both fixtures, `docs/architecture.md` (the Project memory guard row names the four
pathspecs; the Memory lint row the `twin` finding), `README.md` (*Memory lint*, the one-writer paragraph), the N1
decision file (one row, with the documentation page cited). This repo's `CLAUDE.md` is untouched: no line there lists the
files.

### N1-03 · The cap is checked per operation: what fits lands, what breaches is dropped with its reason

**Choice.**

1. **`apply` orders the writes before it makes them**: `delete`, then `replace`, then `add` with an anchor (the
   eviction), then `add` without, each group in file order (*default*), so a delete frees the line an add needs in the
   same list. **After each tier-1 write `capCheck` runs on that file's text before and after the one op**; a breach
   reverts that op alone (`dropped` with `over the cap: ## Gotchas: 16 entries, over 15` or `over the cap: CLAUDE.md:
   121 lines, over 120`) and the next op is tried on the text before it. The same per-op check runs on the union shadow
   for tier 2 (N1-01 §2). The rule "grown on that measure" is unchanged: an over-cap file (hit_list at 181) takes a
   `replace`, a `delete` or an anchored `add` and drops an anchorless `add` with `over the cap: CLAUDE.md: 182 lines,
   over 120` (answer 5).
2. **`refused` retires**: the result has no `refused` field, `body` has no *The tier-1 commit was refused* line, and
   `memory_pr` loses its refusal branch and the note `memory: tier-1 commit refused (…)`. The dropped op's reason is the
   note as every dropped op's is (`memory: dropped add ## Gotchas (over the cap: ## Gotchas: 16 entries, over 15)`) and
   is in the PR body's *Dropped* and the report's `Memory` row's `dropped` count. An `apply` that answers nothing is
   still `memory: apply failed (see run.log)`.
3. `tests/fixtures/memory/stub-cap.json` gains a second op that fits beside the 16th add: a `replace` of a seeded
   Gotchas line with B's fact (`{{LINE:B}}`; the `mc` run gets `STUB_FACTS=A,B`), so the check sees one op dropped and one
   landed in the same run.

**Checks (written first).** Pure, `tests/unit/curator.test.mjs`: a 16th Gotchas add without an anchor is dropped naming
the cap and the replace beside it lands (replacing `… refuses the tier-1 commit, naming the breach`); the op that
crosses 120 lines is dropped and the ops before and after it land (replacing `a result over 120 lines refuses the
tier-1 commit`); a delete and an anchorless add in one list on a file at 15 land both, the delete first; a file over the
cap takes its replace and delete and drops its anchorless add naming the cap (extending `a file already over the cap
takes a replace or a delete`); the result has no `refused` key. `tests/checks/memory-branch.sh` (slow): the `mc` run ends
with one `memory: dropped add ## Gotchas (over the cap: …)` note, the replace on `harness-memory/mc`, the PR open with
the dropped op under *Dropped*, no `tier-1 commit refused` note anywhere (replacing `memory PR: a 16th Gotchas add
without an anchor refuses the tier-1 commit; no branch, no PR`).

**Files.** `lib/curator.mjs` (`apply`, `body`), `lib/record.sh` (`memory_pr`), `tests/fixtures/memory/stub-cap.json` and
its README line, `tests/unit/curator.test.mjs`, `tests/checks/memory-branch.sh`, both fixtures,
`docs/architecture.md` (the CURATOR step: "each op under the cap, a breaching one dropped"), `README.md`, the N1
decision file (one row; and one line under `decisions/2026-11-07-memory-tiers`'s cap answer saying N1-03 built it).

### N1-04 · Review (Opus: answer 2)

Sized to the milestone: an Opus reader of N1's diff, the review feature last. Hardest: that the union shadow holds (two
PRs each under the cap cannot merge into a file over it); that no path lets the driver merge the rules PR under `auto`
(grep every `memory_merge` call); that `restrict`'s four pathspecs revert nothing beside them (`.claude/settings.json`
on a run that edits it survives); that every check name N1 removed has a successor named in the decision file (the
trim's rule, `decisions/2026-11-03-trim`); and that `harness memory` on a `memory.jsonl` written before N1 (no `tier`)
still prints. Findings are fixed in the same feature; the review's file is `docs/plans/<run date>-N1-review.md`.

---

## N2 · The policy and the session: a denied curator, an `auto` that keeps its body, answers the next curator reads

**Finding.** (a) The curator is read-only by revert: `restrict … nothing` undoes what it changed in the run's worktree,
and `memory_foreign` refuses a memory branch tip the driver would not have written. Neither reaches a push: a session
under `--permission-mode auto` may run `git push` or `gh` to any ref or PR, and the decision file records it as a known
limit, with the deny list "a proposal for Michael, not built here". He said build it (answer 7). The harness already
runs one session under a deny list, `lib/debrief.sh` (`--permission-mode dontAsk --allowedTools … --disallowedTools
"${DENY[@]}"`, its rules in the `Bash(git push:*)` form), so the flag and the form are in use on this box. (b) Under
`auto`, `memory_pr` refreshes a reused PR's body (`memory_edit`) and then merges whatever the edit said: a failed `gh pr
edit` is one note and the merge goes ahead with a stale body. Michael flipped it (answer 8): the body is the post-merge
audit trail (what applied, what was dropped and why, each line's `from`), so a merge without it is the one case the
driver stops. (c) Tier 2 and tier 3 are the decisions that most need clarity and are the least instrumented (§12): the
proposals are visible, what Michael did with them is not, and nothing stops the next curator from proposing a rule he
declined last week. With N1-01 a tier-2 rule's merge or close is counted; what remains is a verb for what cannot be a
commit (tier 3) and for a rule he took out of a rules PR before merging it, with a `--why` the next curator reads.

### N2-01 · The curator session runs under a deny list the driver passes

**Choice.**

1. **`session()` takes an optional deny list**: `S_DENY` (an array, as `S_TURNS`, `S_BUDGET` and `S_TIMEOUT` are the
   per-call overrides), appended to the `claude -p` line as `--disallowedTools "${S_DENY[@]}"` when set. This is how a
   headless `claude` takes it: the CLI reference lists `--disallowedTools` ("Deny rules", one quoted rule per argument)
   beside `--allowedTools`, and the permissions page's order is deny, then ask, then allow, so the mode (`auto`) and any
   allow in the project's `.claude/settings.json` (`--settings`) cannot admit a denied call. *Default*: `--disallowedTools`
   on the command line rather than a `--settings` JSON with `permissions.deny`: the flag's semantics are documented for
   exactly this, it leaves `AGENT_SETTINGS` meaning what it means, and the argv is what a stub can record.
2. **The curator's list is fixed in `curator()`** (`lib/driver.sh`, beside `MAX_TURNS=40 SESSION_BUDGET_USD=3`):
   `CURATOR_DENY=("Bash(git push:*)" "Bash(gh:*)")`, the two rules of answer 7 in the form `lib/debrief.sh` already
   passes to the real CLI (the prefix form; the current permissions page writes its examples with `*` after a space,
   `Bash(git push *)`, and documents no retirement of the colon form: *default*: one form in the repo, debrief's, and the
   falsifier below watches it). *Default*: not a config knob (a knob can be set empty; this is a floor, and a project
   that needs more adds to the array in a feature), and nothing else in the list: every other write the curator could
   make is reverted by `restrict`, and `memory_foreign` stays the second layer for a push that found another form.
3. **Visible**: the `run.log` line becomes `curator · <model> · deny Bash(git push:*) Bash(gh:*)` and `harness-log.md`
   gets one note per curator session, `curator: session denied Bash(git push:*), Bash(gh:*)`. The prompt
   (`prompts/curator.md`) keeps its "no push, no `gh`" sentence and adds that the driver denies them.
4. **The stub mirrors the CLI** (`tests/stub-claude.sh`): every headless session records its argv in
   `$STUB_DIR/argv/<n>-<kind>.args` (the desk already records `<n>-<name>.args`; the same shape); a new knob
   `STUB_CURATOR_PUSH=1` has the stub curator commit a Gotchas line and push it to `harness-memory/<run>` *unless its argv
   carries `--disallowedTools` with `Bash(git push:*)`*, in which case it does not push (the CLI would refuse the call).
   *Default*: the stub prints no denial event: none has been captured from the real CLI, and a guessed line is what
   `CLAUDE.md` forbids; the check reads the argv and the absence of the push. A capture of the real deny event in a
   curator transcript, when one occurs, goes into `tests/fixtures/` and the stub replays it (a later feature).

**Checks (written first).** `tests/checks/curator-run.sh` (slow): the `cu` run's curator argv has `--disallowedTools`
followed by exactly the two rules, and the same run's coding, verify and retro argv have no `--disallowedTools`
(*default*: the curator alone; the retro's list is in *Not in this spec*); the `run.log` line and the note say so; a run
with `STUB_CURATOR_PUSH=1` ends done with no `harness-memory/<run>` commit from the session (the driver's one commit is
the branch's only commit past main) and the memory PR as the fixture predicts. `tests/checks/queue-debrief.sh`'s existing
`--disallowedTools` assertion is the model; no unit test (no pure function changes).

**Files.** `lib/record.sh` (`session()`), `lib/driver.sh` (`curator()`), `prompts/curator.md`, `tests/stub-claude.sh`
(the argv record, `STUB_CURATOR_PUSH`), `tests/checks/curator-run.sh`, `tests/fixtures/check-names.txt`,
`docs/architecture.md` (the Read-only sessions guard row: "the curator also under `--disallowedTools`"; the CURATOR step),
`README.md`, `journal/decisions/<run date>-memory-session-and-answers.md` (one row; and one `Updated in place` line in
`decisions/2026-11-07-memory-tiers` closing its known limit).

### N2-02 · Under `MEMORY_POLICY=auto`, a failed body refresh skips the merge and leaves the PR open with one note

**Choice.**

1. **`memory_edit` returns its `gh pr edit` status**; in `memory_pr`'s facts path the merge runs only when the body is
   on the PR: a fresh PR (`pr create --body-file`) carries its body, so it merges as today; a reused PR whose `pr edit`
   failed is not merged, with one note `memory PR: its body was not updated (see run.log); not merged
   (MEMORY_POLICY=auto), left open · <url>` in place of today's two (`its body was not updated …` then `merged into
   main`). The branch has been pushed, so the next segment reuses the PR and its head, refreshes the body and merges then
   if the edit succeeds (*default*: no retry of the edit inside the segment; one `gh` call per step is the harness's
   origin rule, and the next segment is the retry).
2. Under `pr` nothing changes (no merge either way). The rules PR is never merged (invariant 3), so the flip concerns the
   facts PR alone.

**Checks (written first).** `tests/checks/memory-branch.sh` (slow): the `ma` run (auto) is continued with one new fact
and `STUB_GH_DOWN=1 STUB_GH_DOWN_ONLY=edit` (the stub already counts the named `gh pr` sub-command): the continue pushes
the second facts commit, `gh.log` has the failed `pr edit` and no `pr merge` of that URL, the one note is in
`harness-log.md`, the PR is open and `harness memory` lists it `open`; a second continue with `gh` up refreshes the body
and merges (`memory PR merged into main · <url>`). Pure: none.

**Files.** `lib/record.sh` (`memory_edit`, `memory_pr`), `tests/checks/memory-branch.sh`, `tests/fixtures/check-names.txt`,
`docs/architecture.md` (the `MEMORY_POLICY` row and the PR table: "merged only with its body on it"), `README.md`
(*Memory curator*: the `auto` sentence), `templates/*/config.sh` (the `auto` comment), the N2 decision file (one row;
`decisions/2026-11-07-memory-policy`'s `Updated in place` line gets one line saying N2-02 built it).

### N2-03 · `harness memory accept|decline <run>/<n> --why "…"`: recorded in the ledger, read by the next curator

**Choice.**

1. **The verbs** (`lib/memory.sh`): `harness memory accept <run>/<n> --why "<text>"` and `harness memory decline <run>/<n>
   --why "<text>"`, for a tier-2 rule or a tier-3 proposal numbered by N1-01 (`memory-result.json` in the ledger's copy
   of the run record, `ledger/<project>/<run>/memory-result.json`, found by `<run>` across projects). `--why` is required,
   one line, at most 300 characters (`WHY_MAX`, the curator's own bound). The verb appends one row to
   `ledger/memory-answers.jsonl` (*default* name): `{run, project, n, tier, verdict, why, file, section, text, key, at}`
   (the item's `text`, `section` and `key` copied from the result so the row stands alone), replacing an earlier row for
   the same `<run>/<n>` (keyed by run and n), and commits it with the ledger's lock and commit as `harness backlog set`
   does, printing `memory: <run>/<n> <verdict>ed · <section> · <text cut to 60>`. An unknown run, an `<n>` the run has
   not, a missing `--why`, or a tier-1 `<n>` is one error line, exit 1. **The verbs are Michael's**, as `backlog set` is:
   they write the ledger; the `harness memory` a session may run (`CLAUDE.md`) is the listing. `harness memory proposals
   <run>` prints the run's numbered items with their tier, section and text, and any verdict already recorded
   (*default*: so Michael need not open the PR to find `<n>`).
2. **Counted**: `harness memory` adds one tally line, `answers: accepted a · declined d` over the shown runs' rows, and
   marks a listed run whose items carry verdicts (`· 2 answered`); `memory-answers.jsonl` rows carry `tier` and
   `section`, so acceptance per tier and per section is readable from the ledger when F3e builds it.
3. **Read by the next curator, twice.** *In the prompt*: `prompts/curator.md` gains `{{MEMORY_ANSWERS}}`, rendered by
   `curator()` from `node lib/curator.mjs answers <answers.jsonl> <project> --max-bytes 4000` (newest first, declined
   first; the retro's `--max-bytes` pattern): `Michael declined (never propose again): - <text> (<run>/<n>): <why>` and
   `Michael accepted (already his to place): - <text> (<run>/<n>)`; an empty or missing file renders `(none yet)`. *In
   the gate*: `apply` takes the answers file as a fifth argument and drops a tier-2 or tier-3 op whose text's `key`
   (the anchor normalizer, `lineKey`) is a declined or accepted item's, with the reason `declined by Michael (<run>/<n>:
   <why cut to 80>)` or `accepted by Michael (<run>/<n>)` (*default*: both verdicts close the item; an accepted tier-3
   line is Michael's to place by hand, and once placed the "already in section" rule would drop it anyway; the key
   alone decides, not the section: the same sentence under another heading is the same rule). The reason reaches the
   body's *Dropped* and the notes as every drop does, so a curator that keeps proposing a declined rule is visible in
   the drop rate (§10 row 2). Tier-1 ops are never matched (a fact is not a rule Michael declines; a wrong fact is a
   `delete` op's job).
4. **Where the file lives**: `ledger/memory-answers.jsonl`, beside `memory.jsonl` and `retro-backlog.jsonl` in `$LEDGER`;
   `curator()` reads it there. *Default*: the run record gets no copy; what the curator was told is in the rendered
   `prompt-curator.md` the state dir keeps for every session, and the ledger holds the rows.

**Checks (written first).** Pure, `tests/unit/curator.test.mjs`: `answers` renders declined then accepted, newest first,
cut at `--max-bytes` with a line saying how many were left out, `(none yet)` for none; `apply` with an answers file drops
a tier-2 op whose key is a declined item's, naming `<run>/<n>` and the why, drops an accepted one naming it, and never
matches a tier-1 op or a different key. `tests/unit/summary.test.mjs` (or a new `tests/unit/memory.test.mjs`, where the
row shape lives): the answers row shape and the `answers:` tally line, a replaced verdict counted once. Stub runs,
`tests/checks/memory-branch.sh` (slow): after `mp`, `harness memory proposals mp` lists its rule as `mp/1` and its
proposal as `mp/2`; `harness memory decline mp/1 --why "the suite runs itself"` writes the row, commits it to the ledger
repo and prints the line; `harness memory` shows the `answers:` tally; a following run on the same project with the same
`STUB_PROPOSE` op has it dropped as `declined by Michael (mp/1: the suite runs itself)` and opens no rules PR (no
tier-2 change), and its `prompt-curator.md` carries the declined line; `harness memory accept mp/9` and `decline mp/1`
without `--why` are one error line each, exit 1. `tests/checks/curator-run.sh` (slow): the rendered curator prompt of a
project with no answers file says `(none yet)` and has no `{{` left.

**Files.** `lib/memory.sh`, `lib/curator.mjs` (`answers`, `apply`'s fifth argument, the two reasons), `lib/driver.sh`
(`curator()`: `HARNESS_MEMORY_ANSWERS`), `lib/record.sh` (`memory_pr`: the answers file to `apply`), `lib/prompt.sh`
(`{{MEMORY_ANSWERS}}`), `prompts/curator.md`, `lib/summary.mjs` or `lib/memory.mjs` (the rows and the tally),
`bin/harness` (the usage lines for `proposals`, `accept`, `decline`), `tests/unit/curator.test.mjs`,
`tests/unit/summary.test.mjs` (or `memory.test.mjs`), `tests/checks/memory-branch.sh`, `tests/checks/curator-run.sh`,
both fixtures, `docs/architecture.md` (the ledger files table: `memory-answers.jsonl`; `lib/memory.sh`'s row; the
CURATOR step), `README.md` (`harness memory`'s row and *Memory curator*), the N2 decision file.

### N2-04 · Review (Opus: answer 2)

Sized to the milestone: an Opus reader of N2's diff. Hardest: that no path merges a PR whose body refresh failed (the
edit's status is read where the merge decides, not noted and forgotten); that the deny list reaches the real `claude`
line in `session()` for the curator and no other role (the stub's argv proves the curator's; `grep -n S_DENY lib/*.sh`
proves the rest); that the accept/decline match is by `key` and cannot drop a tier-1 op or a different sentence; that a
verdict replaced is counted once; and that `harness memory`'s listing still runs with an empty or missing
`memory-answers.jsonl`. The review's file is `docs/plans/<run date>-N2-review.md`.

---

## Milestones

| M | Contents | After | `check_budget` |
|---|---|---|---|
| N1 | `harness-rules/<run>` and the `memory rules: <run>` PR, `apply`'s two text sets and the union cap, `memory_pr` run per tier, `auto` on facts only, the numbered bodies and `memory-result.json` in the record, `memory.json`/`summary.json`/report/`memory.jsonl`/`harness memory` counting apart; `restrict memory` and `FILES` with `.claude/CLAUDE.md` and `.claude/rules`, memlint's twin lints; the per-op cap and `refused` retired; `journal/decisions/<run date>-memory-rules-pr.md`; architecture and README; N1-04 review | `[]` | 50 |
| N2 | `S_DENY` in `session()`, `CURATOR_DENY` in `curator()`, the argv record and `STUB_CURATOR_PUSH`; `memory_edit`'s status gating the `auto` merge; `harness memory proposals\|accept\|decline`, `ledger/memory-answers.jsonl`, `{{MEMORY_ANSWERS}}` and `apply`'s answers drop; `journal/decisions/<run date>-memory-session-and-answers.md`; architecture and README; N2-04 review | `["N1"]` | 30 |

Plan each as four features, the review last. The suite ends green at every milestone; the fast tier stands under a
coding session's `passes`, the full suite at verify (`decisions/2026-11-03-fast-gate`). A milestone over its
`check_budget` says why in its last coding entry's `checks` field.

## Predictions (for the retro and the supervisor; against the runs after this one)

Every row names the measurement point of `journal/learning/2026-11-07-memory-curator.md` §10 it moves.

| Measure | now | after N1 + N2 | §10 point |
|---|---|---|---|
| memory PRs a run with one tier-2 op opens, each with a state `harness memory` counts | 1 (facts; the rule is body text) | **2 (facts and rules), tallied apart; `sections` stored per rules row** | row 4, *acceptance per tier and per section*: from "impossible while tier 2 is body text" to counted per tier now, per section when F3e reads the rows |
| tier-1 ops lost when one op breaches the cap | all of the run's (`refused` whole) | **the breaching ones only; `refused` never set** | row 2, *applied · proposed · dropped · refused with reasons*: the cap becomes a per-op reason (`over the cap`) whose rate can be read and tuned |
| files Claude Code loads as project memory that a coding session may change unreverted | 2 kinds (`.claude/CLAUDE.md`, `.claude/rules/**/*.md`) | **0** | row 2 (every write to project memory passes the ops counts) and the first spec's Predictions row *roles that may write a project's `CLAUDE.md`* (§10 row 6), now true of the twins too |
| a curator session's push to origin | bounded by the permission mode alone (`decisions/2026-11-07-memory-tiers`, known limit) | **denied at the tool call; `memory_foreign` the second layer** | row 1, *merged unchanged / edited*: a session's commit can no longer ride under `unchanged` by wearing the driver's subject |
| an `auto` merge of a memory PR without its refreshed body | possible (noted, merged) | **0; the PR stays open and is counted `open`** | row 2 (the body is where the applied, dropped and reasons live after the merge) and row 1 (the state is honest) |
| a declined rule proposed again | unbounded | **0 by key; dropped `declined by Michael (<run>/<n>: …)`** | row 2 (the drop reason) and row 4 (`memory-answers.jsonl` carries tier and section: the first per-section acceptance numbers for tier 3) |
| `CLAUDE.md` lines, agent-harness | 97 (14 Gotchas) | **97 or fewer by hand; the curator's PRs are Michael's to merge** | the first spec's Predictions table (§10 row 6) |
| `harness memory` tally lines | 1 (facts only, unnamed) | **3: `facts:`, `rules:`, `answers:`** | row 1 and row 4 |

**Falsifiers.** The rules PR is closed unmerged on more than two runs in three (tier-2 proposals are noise: the gate on
`proposed_changes`, not the PR shape, is what to revisit). The per-op cap drops more than a third of a run's tier-1 ops
on an over-cap project (the prune, F3c, is overdue; the drop rate is the signal, not a reason to loosen the cap). A real
curator transcript shows a `git push` or `gh` call that ran (the deny form did not match: switch to the page's `Bash(git
push *)` form and re-check the argv). A declined rule is proposed again (the `key` match is too narrow) or a different
sentence is dropped as declined (too wide). The two PRs of one run conflict on the second merge on more than one run in
five (then stack rules on facts and say so). `harness memory` reads a facts row as rules or the reverse. The union shadow
lets both PRs merge into a file over 120 lines (the cap moved from the write to nowhere).

## Not in this spec

The review surface through n8n: the memory PRs' tally and merge or decline actions on the phone, the run-review card
with the ops beside the record PR (F3d; the events contract is v1 while `agent-harness-2026-11-07-3` builds to it,
Decision 21 (a)). The recurrence measure and acceptance per section read from the ledger (F3e, after three or more
curator runs). The prune of hit_list, n8n-home and portfolio_site (F3c, by hand, one session per project, by
`docs/plans/2026-11-07-claude-md-prune-checklist.md`). `.claude/rules/*.md` as an operation target or a linted file
(guarded only). `CLAUDE.local.md` and `~/.claude/rules/`. A deny list for the retro (its known limit is the same; a
separate question with the same shape, one line to add once this one holds). `MEMORY_POLICY=auto` turned on anywhere
(answer 10: per project, on the count). A classifier above the gate (§13 item 11), a project-start review of pending
proposals and a cross-project memory desk (item 9). Any change to `~/.claude/CLAUDE.md`, `~/.claude/settings.json` or a
project's `.claude/settings.json` by a run.

## After the run (Michael)

- **Nothing to configure.** `MEMORY_POLICY=pr` stays the default. Each run may now leave two PRs: `memory: <run>` (facts;
  under `auto` the driver merges it) and `memory rules: <run>` (a diff you merge or close; never the driver). Both
  bodies carry the same tier-3 proposals and dropped ops, numbered.
- **The counter**: `harness memory` lists facts and rules apart with a tally line each, then `answers:`. The number
  `auto` waits on is still `facts: merged unchanged` per project (about five); the rules tally is the graduation signal
  for tier 2 by section, once F3e reads the `sections` the rows carry.
- **Your verbs** (they write the ledger, so they are yours, not a session's): `harness memory proposals <run>` to see
  `<run>/<n>`; `harness memory accept <run>/<n> --why "…"`; `harness memory decline <run>/<n> --why "…"`. A declined or
  accepted item is never proposed again by the curator (dropped with your why in the PR body).
- **Before each project's next run**, prune its `CLAUDE.md` under the cap by the checklist (F3c); the curator improves an
  over-cap file but never shrinks it, and now drops only the ops that would grow it.
- **The dispatch list** (`docs/plans/2026-11-03-test-suite-redesign-dispatch.md`): row F3b's status to the run's PRs
  and this table's results; F3c's block names this checklist's path (`2026-11-07`).
