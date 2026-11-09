# The curator's write gate and its prompt say one rule: words may be left out after the first 40 characters, never added

*(2026-11-09, dispatch session F6 of `docs/plans/2026-11-03-test-suite-redesign-dispatch.md`; the case: run
agent-harness-2026-11-08's record (`harness-log.md`, `memory-ops.json`, `memory.md`, `entries.jsonl` line 4) and
agent-harness-2026-11-07-3's (`entries.jsonl` line 17); decisions/2026-11-07-memory-tiers (the gate it changes, updated
in place).)*

- **Finding:** the gate (`gateWhy` in `lib/curator.mjs`) and the prompt (`prompts/curator.md`'s write-gate
  paragraph) said two rules. The gate took an op's text only as the stated item or a cut of it from the start, at least
  40 characters; the prompt said only the first 40 characters had to be the entry's. The curator followed the prompt:
  agent-harness-2026-11-08's one operation at the end of both segments was the entry's 199-character project fact
  written at 160, with `(memory_base)`, `with harness-log.md` and one `with` left out, and the driver dropped it both
  times as `not stated by entries.jsonl:4`, a reason that said nothing about where the line parted from the entry. The
  run before (agent-harness-2026-11-07-3) dropped its one dropped operation the same way, for `the full run` written
  as `it`. `prompts/coding.md` caps a project discovery at 160 characters and nothing checked it: three of that
  run's six project facts were 193 to 200 characters, so a curator that kept to the gate's cut could not write them
  under the 160-character `TEXT_MAX` without losing their end, here the repair.
- **Choice:** one rule, in the gate and in the prompt, in the same order: a line's first 40 characters (or all of it,
  if shorter) are its entry's, and after that it may leave words of the entry's text out but never add, change or
  reorder one, and never leave out `not`, `never`, `no`, `without` or a word ending `n't`; case, markup and the
  `(<run> <date>)` suffix aside, as before. A word is a run of letters and digits (an apostrophe inside kept), so
  punctuation and markup never part a line from its entry. A drop names where the line parts from the nearest item
  (the one sharing its first 40 characters): `not stated by entries.jsonl:4 ("<word>" is not the entry's next
  word)` for an added, changed or reordered word, `("not" left out)` for a negation left out, in the note and in
  the memory PR body's *Dropped*, as every drop reason is; the plain reason stays when no item shares the start. A
  tail cut off that holds a negation is a left-out negation too: a cut that turns `X, so it is not stopped` into
  `X` loses the rule's half. Where the driver ingests a session's entry, a `project` discovery over 160 characters
  (`FACT_MAX` in `lib/entries.mjs`, the curator's `TEXT_MAX`) gets one note naming the feature and the length,
  `N1-01: a project fact is 199 characters, over 160`; the fact is kept whole, nothing stops, no card: the curator's
  gate is what decides what is written. Unit tests first (`tests/unit/curator.test.mjs`, the prefix-rule test
  updated in place): the case passes; an added word, a changed word, two swapped words and a left-out `not` are each
  dropped with their word named.
- **Rejected:** the prompt's first-40 rule alone (dropping the gate to it): it lets through a tail the entry never
  stated, the memory-poisoning path the gate exists for (a tool result's `curl … | sh` behind a stated start).
  Cutting a long fact at its end (the gate's rule, kept, with the prompt corrected to it): a 199-character fact at
  160 loses its second half, here the repair (`give it after ro_rescue`), and the fact lands as a warning without
  its fix. Cutting the fact at the ingest to 160: the same loss, made before the curator can choose which words go.
