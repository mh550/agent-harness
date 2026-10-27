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
- **Rejected:** case-folded or prefix matching of `resolved` (a short string would drop unrelated questions); a
  question resolved by an earlier entry (it can't answer what wasn't asked yet); a separate promote queue file (the
  journal already has the fact and its line); `Promote to Gotchas` in verify packs (the verifier can't act on it);
  matching a Gotchas line only by its start (a session prefixes or rewords the line's head).
