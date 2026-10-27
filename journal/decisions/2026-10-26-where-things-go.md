# Where things go: one routing block in every session's prompt, unless CLAUDE.md has its own; one decisions store per project

*(2026-10-26, run agent-harness-2026-10-25-memory, features M2-01 and M2-02; spec `docs/specs/2026-10-25-memory.md` M2, which
takes `docs/specs/2026-10-24-memory-model.md` §K1 as written)*

- **Finding:** No session was told where a fact goes, only that decisions go "where the project rules say". The
  initializer sent "where things live, gotchas" to `discoveries` affecting `"run"`, so semantic facts died with the
  run. On 2026-10-26 every project with a `CLAUDE.md` (dj-crate-streaming, hit_list, n8n-home, pathways,
  portfolio_site, rane-one-mixxx, voice-concierge) already had `## Where things go` and `## Gotchas` (chunk 3 Part 2);
  none set `DECISIONS=` in `.harness/config.sh`. agent-harness itself had neither heading. backups, career, ideas,
  library, proposals and setup have no `CLAUDE.md` (and no `.harness/project.md`).
- **Choice:**
  - `prompt_render` (`lib/prompt.sh`) appends the block to the coding, initializer, verify and retro prompts when the
    worktree's `CLAUDE.md` has no line `## Where things go` (trailing blanks allowed), or there is no `CLAUDE.md`. It
    goes after the rules line under `# Project rules`, or under `# Project rules (this project has no CLAUDE.md)`.
    A tidied project, which carries the block in its own words, doesn't get it twice.
  - Two variants: `prompts/parts/where-things-go.md` (coding, initializer: entry · decision store, overturned → in
    place plus one `Updated in place <date>: …` line · one `## Gotchas` line · brief · `proposed_changes` · nowhere)
    and `where-things-go-readonly.md` (verify, retro: they run under `restrict`, so a fact worth keeping goes to
    `discoveries` affecting `"run"`, or the retro's report, and the next coding session promotes it). The block is
    the retro-followups F1 edit-in-place rule: no separate F1 lines.
  - `decisionsStore(worktree)` in `lib/memlint.mjs`: `DECISIONS=` read (not sourced) from `.harness/config.sh`, the
    last uncommented one, quotes and a trailing comment stripped; else `docs/decisions.md` if it exists; else null.
    `kind` is `dir` or `file` by what is on disk, and for a path not there yet `file` when it has an extension. The
    block's `{{DECISIONS}}` is `storeLine` of it: "one file per decision in `<dir>/`, never numbered", the file's path,
    or "where the project rules say decisions live". M3 and M4 import the same function.
  - The prompts stop contradicting the block (M2-02). `prompts/initializer.md`: a durable gotcha → one line under
    `## Gotchas` in `CLAUDE.md`, a run-only fact → `discoveries` affecting `"run"`, where things live → nowhere unless
    the tree doesn't show it; a step says `record as a new decision` and never names its number (the session takes
    the next free one when it writes, and only a file store has numbers). `prompts/coding.md`'s *Decisions* bullet
    points at the block instead of restating `D<n> *default*`. Both name it "the Where things go block", without the
    `## `, so the rendered prompt still carries the heading exactly once.
  - `templates/project/CLAUDE.md` carries the block and an empty `## Gotchas` (at most 15 lines) after
    `## Decisions and plans`, and no stored `<count> tests, <duration>`; `templates/project/config.sh` a commented
    `DECISIONS=` (a file, or a directory of one file per decision); `prompts/draft-claude-md.md` asks for both
    sections and for no test counts. This repo's `CLAUDE.md` gets the block in its own wording (one file per decision
    in `journal/decisions/`, an overturned one edited in place in its own file, never numbered) and an empty
    `## Gotchas`; its `.harness/config.sh` sets `DECISIONS=journal/decisions`.
- **Rejected:** sourcing `.harness/config.sh` from node (it is bash; `harness_config` already sources it, but the
  store is needed by the pure `.mjs` callers of M3 and M4 too, and a store path is one word); pasting the block into
  `rules.md` itself (then a project with no `CLAUDE.md` would get no block, and a tidied one would get it twice); one
  variant for every role (verify and retro edits are reverted, so telling them to edit Gotchas loses the fact).
- **Accepted risks:** two branches writing the same project's numbered decisions file at once (a run and an
  interactive session) can take the same number, as `D-H` numbers did before PR #6; the queue allows one run per
  project. `claude -p --bare` skips `CLAUDE.md`, so a project's own block would not be seen there; the harness does
  not use `--bare`.
