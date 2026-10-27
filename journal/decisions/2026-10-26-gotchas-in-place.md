# Gotchas in place: the coding session edits one `## Gotchas` line, the driver notes the diff

*(2026-10-26, run agent-harness-2026-10-25-memory, feature M3-02; spec `docs/specs/2026-10-25-memory.md` M3, which takes
`docs/specs/2026-10-24-memory-model.md` §K2 as written; plan `docs/plans/2026-10-26-M3-gotchas-and-pack.md`)*

- **Finding:** M2 gave every session a `## Where things go` block that sends a fact a fresh session would rediscover
  to one line under `## Gotchas`, but no step of the coding prompt asked for it and nothing showed when it happened.
  A semantic fact still ended in `discoveries` affecting `"run"` and died with the run, and a session that rewrote the
  section wholesale would go unseen.
- **Choice:**
  - `prompts/coding.md` `## 3. Finish`, step 3: add or edit one line under `## Gotchas` in `CLAUDE.md` (create the
    section when missing): at most 160 characters, ending `(<run> <date>)` (the run id from the `Run:` line, so no
    new prompt variable); 15 lines at most, at 15 replace the least useful; a wrong line is edited in place; never
    rewrite the section.
  - `gotchasLines` / `gotchasDiff` (pure, `lib/memlint.mjs`) compare the section's non-blank lines as multisets:
    `edited = min(out, in)`, the rest added or deleted; reordering is no change. *D1 default:* a replace (one line
    out, one in) is one edit (`~1`), which is what the prompt asks for at 15 lines. `memlint.mjs gotchas <before>
    <after>` prints `+<a> ~<e> -<d>`, nothing when equal.
  - `gotchas()` in `lib/driver.sh` runs after `journal coding`, from the session's start commit and HEAD (`git show
    <commit>:CLAUDE.md`), and notes `<feature>: gotchas +<a> ~<e> -<d>` in `harness-log.md`. Verify and retro get
    none: `restrict` reverts their `CLAUDE.md`.
  - Stub flag `STUB_GOTCHA=<id>`; checks in `tests/checks/38-run-17-gotchas-and-pack-m3.sh`.
  - **The M3 review (M3-05), merged with M3:** an indented line continues the bullet before it (a wrapped bullet
    is one line, `+1` not `+2`, and one string for the pack's carried test), and a `# ` heading ends the section as a
    `## ` one does (`docs/plans/2026-10-26-M3-review.md`).
- **Rejected:** a separate gotchas file (a second place to read; `CLAUDE.md` is loaded into every session already); a
  blocking size guard (a 16th line or a long one is noted by review, not worth stopping a night's run); an LLM tidy of
  the section (a rewrite is exactly what the rule forbids, and it isn't deterministic); a line-position diff (a moved
  line would read as an edit and a deleted line shift every one after it).
