# The tiers and the files: tier 2 is a PR, the twins are guarded, the cap is per operation

*(2026-11-08, run agent-harness-2026-11-08, N1 (the file and the per-op cap row by N1-03); spec
`docs/specs/2026-11-07-memory-followup.md` §N1; journal/learning/2026-11-07-memory-curator.md §12 (answer 5: keep the
rule, improve not grow, and check it per op) and §13 item 5; decisions/2026-11-07-memory-tiers (the cap it changes).)*

- **Finding:** `capCheck` ran once on `apply`'s whole result, and a breach moved *every* applied tier-1 op to `dropped`
  with `refused: …` and returned the texts unchanged: one anchorless add on a file at 15 Gotchas lost the good ops
  beside it, and an anchored add evicted its anchor even on a file far under the cap. §12 names this as the one place
  the deterministic gate was too rigid; answer 5 keeps the rule (an over-cap file may improve, not grow) and asks for
  the check per op.
- **Choice:**

  | row | what | by |
  |---|---|---|
  | the per-op cap | **The write order**: `apply` makes its writes delete, then replace, then `add` with an anchor, then `add` without, each group in the ops' own order (*default*: "file order" read as memory-ops.json's order, a stable sort), so a delete frees the line an add needs in the same list. **The check**: each tier-1 write runs `capCheck` on that file's text before and after the one op; a breach drops that op alone (`over the cap: ## Gotchas: 16 entries, over 15`, `over the cap: CLAUDE.md: 121 lines, over 120`) and the next op is tried on the text before it. An over-cap file still takes a replace, a delete or an anchored add (grown on that measure, unchanged). **The eviction only past the cap** (Michael's brief, 2026-11-08): an anchored `add` is appended, its anchor line kept, when the appended text passes `capCheck`, and evicts its anchor only when it would not; an anchored add whose anchor a delete or replace in the same list already took still lands as a plain add when it fits (*default*, from the session's review: the order exists so a delete frees the line an add needs); the evicting op carries `evicted`, the line it replaced (*default*), the PR body's *Applied* line reads `(in place of: <line>)` for it as for a `replace`, and `memory_pr` notes `memory: evicted "<line cut to 80>" for add ## Gotchas` (*default* wording). **`refused` retires**: no `refused` field in the result, no *The tier-1 commit was refused* line in the body, no refusal branch and no `memory: tier-1 commit refused (…)` note in `memory_pr`; a cap drop is noted as every drop is (`memory: dropped add ## Gotchas (over the cap: …)`), is under the body's *Dropped* and in the `Memory` row's `dropped`. An `apply` that answers nothing is still `memory: apply failed (see run.log)`. | N1-03 |

- **Rejected:**
  - **Keep the whole-commit refusal, with a clearer note**: the good ops beside a breach are still lost, and the
    curator learns nothing it can act on from one breach for many ops.
  - **Evict on every anchored add** (M2's rule): on a file under both caps it cuts a fact for no reason; the anchor is
    the curator's offer of a line to give up, taken only when the cap needs it.
  - **Order the writes by their position in the file**: the position moves as the writes go (a delete shifts every line
    after it), and the ops' own order is the curator's; a stable sort by kind keeps it within each group.
