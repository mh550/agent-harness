# One writer for project memory: a coding session's `CLAUDE.md` edit is reverted, a fact goes in the entry

*(2026-11-07, run agent-harness-2026-11-07-2, features M1-02 and M1-03; spec `docs/specs/2026-11-07-memory-curator.md`
§M1; plan `docs/plans/2026-11-07-M1-one-writer.md`.)*

- **Finding:** the project's memory had many writers and no guard. Every coding session's Finish step asked for one
  `## Gotchas` line, and the 120-line and 15-Gotchas caps were enforced by one repo's suite check alone, red outside
  the feature that caused it. `restrict` never covered coding sessions, so "how to work here → Michael's" in
  `## Where things go` was advisory. memlint found 0 findings in 31 runs: an inventory, not a safety net, and it says
  nothing about edits nobody looked at. The pack also hid a fact from `Promote to Gotchas` as soon as a `## Gotchas`
  line of the worktree's `CLAUDE.md` held it, so the session that wrote the line decided what every later one saw.
- **Choice:**
  - `restrict <base> memory <who>` (`lib/record.sh`) reverts changes since `<base>` to exactly `CLAUDE.md` and
    `.harness/project.md` at the repo root (plain pathspecs from the root: a nested `docs/CLAUDE.md` is code). An
    added file is removed, an edited or deleted one comes back. `record` and `nothing` are unchanged, and so is every
    other role's call: verify `record`, retro `nothing`, the initializer `record`, entry-resume `record`.
  - `memory_guard <start> <who>` (`lib/record.sh`, beside `lane_guard`) calls it once per coding session in
    `lib/lane.sh`, between the WIP commit and `sync_lane`, so the revert commit is pushed with the session's work and
    `journal coding`'s file list and the fast gate see the tree that merges. *Default:* its base is the lane's
    merge-base with main, `<start>` when there is none, as `lane_guard`'s (decisions/2026-10-30-lane-guard-base): a
    session that merges main itself keeps main's `CLAUDE.md` lines.
  - *Default:* one note per reverted file, `<feature>: reverted its CLAUDE.md edit (project memory is the curator's;
    say it in the entry)` (or `.harness/project.md`); none for a session that touched neither. `prompts/coding.md`
    Finish step 2 and `docs/architecture.md` §7 use the same words.
  - *Default:* `gotchas()` and its `<feature>: gotchas +a ~e -d` note retire: after the revert, a coding session's
    `CLAUDE.md` diff is always empty. `memlint.mjs gotchas` (the CLI), `gotchasDiff` and `gotchasLines` stay (memlint's
    lints use them; the curator of M2 may).
  - The pack's clearing rule (M1-02, `lib/entries.mjs`): a `project` fact is listed once, at its first entry that no
    later entry lists in `resolved` (matched by `key`, the first 40 characters of the loose form); `CLAUDE.md` is never
    read for it. *Default:* the share stays `Math.floor(cap / 8)` and the title stays `Promote to Gotchas`.
  - The prompts (`prompts/coding.md`, `prompts/initializer.md`, the three `prompts/parts/where-things-go*.md`),
    `templates/project/CLAUDE.md`, `prompts/draft-claude-md.md` and this repo's `CLAUDE.md` send a durable fact to the
    entry's `discoveries` with `affects: ["project"]` and a workflow line to `proposed_changes`, never to `CLAUDE.md`.
  - Stub knobs `STUB_TOUCH_CODE`, `STUB_PROJECT_MD`, `STUB_INIT_GOTCHA` and `STUB_README_ONLY` (was
    `STUB_GOTCHA_ONLY`); checks in `tests/checks/memory-one-writer.sh`. `partial-key.sh`'s driver-partial checks map
    `README.md` now: a `CLAUDE.md`-only session tree no longer exists.
- **Rejected:** the `nothing` spec for coding sessions (a coding session must write code, tests, docs and decisions);
  an advisory prompt line alone (what `## Where things go` already was); `<start>` as the base (a session's own merge
  of main would take main's `CLAUDE.md` lines out on the lane branch, and the milestone's merge then out of main: in
  M2 a merged memory PR makes exactly that change); blocking the session or the gate on the edit (the revert costs
  nothing, and a stop would cost a night).
