# The pack ends with the decisions store's current rules; a verify's pack gets its own cap, failed rows first

*(2026-10-26, run agent-harness-2026-10-25-memory, feature M3-04; spec `docs/specs/2026-10-25-memory.md` M3, which takes
`docs/specs/2026-10-24-retro-followups.md` §F3 and the 2026-10-26 addition (`CONTEXT_PACK_BYTES_VERIFY=16384`); plan
`docs/plans/2026-10-26-M3-gotchas-and-pack.md`)*

- **Finding:** a session learned the project's rules only if it went looking in the decisions store, so a rule taken
  three sessions ago was re-decided or contradicted. And the verify packs of the lifecycle run left 25–29 items out at
  8 KB, with the failed evidence rows (what the next round most needs) behind the dead ends.
- **Choice:**
  - `memlint.mjs currentRules(store, input)` (pure) and `readRules(worktree)` (IO) read the store `decisionsStore`
    names. A directory store: each `.md` file's first `# ` line, by file name descending (the date prefix, so newest
    first), `→ <path>/<name>`. A file store: the three decision-line shapes the projects use (copied into
    `tests/fixtures/decisions-{rane,voice-concierge,dj}.md`): a heading `## D<n>` plus its first non-blank line
    (voice-concierge), a bullet `- **D<n>` with its wrapped lines (rane-one-mixxx), a table row `| D<n> |`
    (dj-crate-streaming); emphasis dropped, cells joined by ` · `, `→ <path>:<line>`, by n descending. A repeated n
    keeps its last line (dj's `## D24 on` group heading gives way to the `| D24 |` row); a range such as `D1–D6` is a
    group heading, not a decision. A table row's id cell may carry `*default*` (`| D36 *default* |`, most of dj's
    newest rows); CRLF files read the same; an undated `.md` in a directory store sorts after the dated ones, and
    within one day the order is by slug (the names carry no time). Not read (left for M4's lint): unnumbered
    headings such as voice-concierge's `## LLM provider: …` and its `B<n>` rulings, so the part is the numbered rules,
    not every rule.
  - `pack()` gains a seventh part, `Current rules`, last. *D1 default:* it takes at most cap/4 bytes and never more than
    the room left; each item is cut to 240 bytes (its ref to 120); the rules that don't fit become one line `_<k> older rules:
    <path>._` and are **not** counted in `items left out` (they live in the store, not entries.jsonl); a pack that
    already stopped has no rules part. The CLI fills it under the same `<worktree>/.harness/runs/<run>` guard as the
    Gotchas (so an eval probe's clone shows it too).
  - `CONTEXT_PACK_BYTES_VERIFY=16384` (`lib/config.sh`, documented in `templates/user/config.sh`): `context <id>
    [<cap>]`, and `verify()` passes it. *D2 default:* a project raising `CONTEXT_PACK_BYTES` above 16384 doesn't raise
    the verify cap (set both). In a milestone pack part 1 lists the failed `Verify … found` rows before the dead ends;
    a feature pack keeps its dead ends first.
  - Stub flag `STUB_VERIFY_FAIL_ROW=1`: A's coding entries record a dead end and verify M1 round 1 adds a failing row
    for A step 1 (a long `saw`, as real rows quote output).
- **The M3 review (M3-05), merged with M3:** a range written `D1—D6`, `D1 – D6` or `D1 to D6` is a group, as `D1–D6`
  was, and a heading never replaces a bullet or a row of the same n (a group heading such as dj's `## D24 on` placed
  after its row would have); all seven real stores parse as before (`docs/plans/2026-10-26-M3-review.md`).
- **Rejected:** a model-written summary of the store (not deterministic, and it drifts from the rule's text); counting
  the rules past their share in `items left out` (that line points at entries.jsonl, which doesn't have them); rules
  ahead of the journal parts (the feature's own history matters more to its next session, and the store is one read
  away); one cap for both kinds (a verify reads every feature of its milestone, a coding session one).
