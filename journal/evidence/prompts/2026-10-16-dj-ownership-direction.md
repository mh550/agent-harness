# 2026-10-16 00:05: "Let's do this before M6/M7 and make the plan align"

- **Date:** 2026-10-16 (commit `6ff96e9`, 00:05)
- **Project:** dj-crate-streaming
- **Source:** `~/projects/OVERNIGHT-2.md` "Direction from Michael"; result
  `dj-crate-streaming/docs/specs/2026-10-16-ownership-and-identity.md` (`fe3069b`)
- **Iteration:** 2 (the design pass that the subagent-driven M6–M8 run then built)
- **Why it matters:** Michael stops the queue to have the design fixed first ("ownership of each fact"), and he
  writes "agent-supervised later" into the product itself. M6–M8 then ran subagent-driven, with Opus/Sonnet chosen
  per task in the plans.

## Verbatim, as recorded

> - **2026-10-16 (Michael, review conversation, part 2):** Streams rely on Navidrome's quality selection for now;
>   our own opus/mp3 presets come later (D19). On-demand sourcing (play on a queued, not-owned track) takes the
>   fastest download and is replaced by a better copy later (D20). **Drop the host script; use the background
>   worker container (D18 confirmed)**: manual approval first, automated or agent-supervised later (D23). Asked
>   for: ownership of each fact (and where beets fits in M6/M7), and how songs separate from versions and who owns
>   that choice (the 12" preference is not set in stone). "Let's do this before M6/M7 and make the plan align" →
>   `dj-crate-streaming/docs/specs/2026-10-16-ownership-and-identity.md`, queue M6–M8 rewritten.

## How the plans then encoded delegation (not Michael's words; plan text)

`docs/plans/2026-10-16-m7-identity.md`:

> ### Task 1: `sourcing/identity.py` (model: **Opus**: the parsing rules are the core of the milestone)
> ### Task 2: Fold the plain normalisers into identity (model: **Sonnet**)
> ### Task 9: `apply` and `revert` (model: **Opus**: this is the one code path that writes library tags)
> ### Task 11: Whole-milestone review and `/simplify` (controller; review on **Opus**)

`docs/plans/2026-10-16-m8-lifecycle.md`:

> ### Task 8: copy replacement = repoint everywhere + old copy to trash (model: **Opus**: the one code path that deletes)
> ### Task 9: proposals (model: **Opus**: creation decides what Michael is asked)

ON2 Status log, 2026-10-16 16:15: "**M6 done, M7 code done, M8 under way** (subagent-driven; ledgers in
`dj-crate-streaming/.superpowers/sdd/`)".
