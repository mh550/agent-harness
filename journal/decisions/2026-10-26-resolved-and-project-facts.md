# Resolved questions leave the pack; `project` facts wait under `Promote to Gotchas` until a Gotchas line carries them

*(2026-10-26, run agent-harness-2026-10-25-memory, feature M3-03; spec `docs/specs/2026-10-25-memory.md` M3, which takes
`docs/specs/2026-10-24-retro-followups.md` §F2 and the 2026-10-26 addition (`project` as an `affects` value); plan
`docs/plans/2026-10-26-M3-gotchas-and-pack.md`)*

- **Finding:** a question stayed in every later context.md of its feature after Michael answered it or a decision
  settled it: the pack had no way to know, so sessions re-read and re-asked it. And a fact that outlives the run had
  nowhere to go from a read-only verify: `discoveries` affecting `"run"` died with the run, and a coding session saw it
  only if it happened to name its feature.
- **Choice:**
  - An entry may carry `resolved` (an array of strings, any kind): the questions the session found answered, copied
    as context.md shows them. `validate` gives `resolved: not an array of strings`; `normalize` keeps it after
    `questions` only when non-empty, so older entries keep their shape. *D1 default:* a question is resolved when an
    entry on a **later** line lists it, **exactly after folding whitespace**; the record (progress.md, the archive)
    still shows it.
  - `affects` may be `"project"`: a fact that outlives the run. The pack's new part `Promote to Gotchas` (coding packs
    only, after `Discoveries for this feature`) lists those discoveries newest first, one per distinct first 40
    characters, each `→ entries.jsonl:<line>`, and leaves out one a line of the worktree's `## Gotchas` contains
    (*D2 default:* contains its first 40 characters, the whole text when shorter). *D3 default:* the part shares at
    most cap/8 bytes; a fact longer than the room left in the share is cut to it (with `…`, so a long fact still
    shows), and one that finds under 32 bytes left is counted in `items left out` without ending the pack; in a coding pack
    a `project` fact shows there and not under `Discoveries`; a milestone pack has no such part (a verify can't write
    `CLAUDE.md`).
  - `entries.mjs pack` reads `<worktree>/CLAUDE.md` only when the run dir is `<worktree>/.harness/runs/<run>` (a run,
    or an eval probe's clone, which then shows what the session would read; the plan said a probe reads none).
  - `prompts/coding.md` names `resolved` and `project` in its entry example and field sentence; Finish step 3 writes
    the `Promote to Gotchas` items into `## Gotchas`; the read-only `Where things go` part sends a verify's durable
    fact to `discoveries` with `affects: ["project"]`. Stub flags `STUB_ASK`, `STUB_RESOLVE`, `STUB_PROJECT_FACT`.
- **The M3 review (M3-05), merged with M3:** the real projects' Gotchas lines open with a capital and backticks,
  so a fact counts as carried when a line holds its first 40 characters with case, backticks, `*`, `_` and spacing
  set aside; the prompt asks to keep a fact's opening words. A fact also leaves when a later entry's `resolved`
  holds it (same 40-character key): a stale fact, or one a session dropped from a full section, would otherwise come
  back forever and evict another line, so step 3 now writes only the items that still hold. A `resolved` string is
  read as context.md shows the item (`- `, `Question (<id>): ` and ` → entries.jsonl:<n>` dropped; one ending `…`,
  over 40 characters, matches as a prefix of the question), progress.md shows it as `Resolved:`, and the CLI's
  `CLAUDE.md` read is guarded like the store's (`docs/plans/2026-10-26-M3-review.md`).
- **Rejected:** case-folded matching of `resolved`, or a prefix match of a string not cut with `…` or of 40
  characters or fewer (a short string would drop unrelated questions); a
  question resolved by an earlier entry (it can't answer what wasn't asked yet); a separate promote queue file (the
  journal already has the fact and its line); `Promote to Gotchas` in verify packs (the verifier can't act on it);
  matching a Gotchas line only by its start (a session prefixes or rewords the line's head).

Updated in place 2026-10-26: the M3 review (M3-05) widened what carries or dismisses a promoted fact and how a
`resolved` string is read (the review bullet above); prefix matching of a cut question is allowed past 40 characters.
