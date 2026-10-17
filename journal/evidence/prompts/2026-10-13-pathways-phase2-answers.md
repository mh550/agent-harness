# 2026-10-13 (late evening): Michael's answers to the Pathways Phase 2 spec

- **Date:** 2026-10-13, late evening (spec rev 2 committed 23:56, `5e598eb`)
- **Project:** pathways
- **Source:** `pathways/docs/specs/2026-10-13-overnight-design.md` §0 "Status / Michael's answer" column and §8;
  `pathways/docs/runbooks/2026-10-14-overnight.md` "Direction from Michael" (archived by `cd3eacb`)
- **Iteration:** 1 (planning session → spec §0 decisions table → overnight runbook)
- **Why it matters:** this is how Michael "prompts" in iteration 1. He doesn't write the task; he answers a
  decisions table that the planning session drafted with defaults. Short or uncertain answers are allowed
  ("I don't know, consider what's best."), and the spec turns them into settled defaults the loop must not re-open.

## Direct quotes recorded in §0

> D9 (branch policy with several overnight threads) — Michael: "I don't know, consider what's best." Default above.

> D11 (tapping a pathway on the Live view) — Michael: "I don't know what you mean." Default: follow Serato.

> D13 — Michael: no; graphs are connection-rich collections, not the whole library; the core idea is playlists and
> separating musical motifs.

> D4 — Michael: one current for sure; also show the other deck, treated differently if previous vs newly loaded;
> track both decks' pointers; consider the visual design.

> D5 — Michael: yes to fetching; consider whether art belongs in intake/ingestion; MusicBrainz as fallback at most.

## Runbook "Direction from Michael" (verbatim)

> - **2026-10-13 late evening (to the planning session; folded into spec rev 2 §0/§8):**
>   Live + Serato OK; Serato is hard to test on Linux; feel free to experiment with Mixxx (not
>   installed). Real session fixtures fine. Add songs by searching Navidrome; multiple graphs
>   (graph = mega-playlist, playlist = pathway through it). One current track plus the other
>   deck shown, previous vs newly loaded treated differently; track both decks. Art fetch yes,
>   but consider ingestion as the right place. Rust long-term, no change tonight. Node is on
>   the Serato laptop. Branching: decide what's best with several overnight threads. Library
>   is not nodes. **Core idea: reusable threads strung into graphs, thread context visible —
>   think about modularity overnight → M5.**

## What the planning session added in response (spec §5)

> **Time rule:** if 5.5 h have elapsed and M5 has not started, finish the current milestone, then do M5 and M6
> before anything else — the design doc is the one deliverable Michael asked for in his own words.

(That rule later misfired on wall-clock time after the 7 h suspension; see the timeline.)
