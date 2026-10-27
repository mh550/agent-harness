<!-- fixture: voice-concierge commit 99091b5 path docs/decisions.md, lines 1-12, 44-50, 223-237 -->
# Decisions

Newest last. `*default*` = a default a session took that Michael hasn't confirmed. This file is the current rule
set: when a decision is overturned, its entry is rewritten in place to the rule that holds now, with one
"Updated in place <date>: …" line naming what replaced it. History is in git.

Michael's decisions D1–D6 and the builder's calls B1–B12 came from `docs/spec.md` §3; later ones are numbered from
D7, and unnumbered entries are Michael's answers. A new one takes the next free `D<n>` (`D<n> *default*` for a
default): the finding, the choice, what was rejected.

## D1–D6 and B1–B12 (Michael and the builder, 2026-10-19; from spec §3)

- **B3** · Memory is **slot-based facts plus one visit summary**, always loaded (small, about 1–2 KB). No vector search:
  the best-practice "start with one small file".
- **B4** · Writes happen **in the background** through a separate extractor, as delta operations. The only hot-path
  writes are the explicit, user-requested `remember` / `forget` tools.
- **B5** · Facts are **invalidated, not overwritten** (`valid_to`, `superseded_by`); "forget me" really deletes.
- **B6** · Retention: a thread expires after **30 days idle** and is purged at worker start and daily.
- **B7** · Abuse limits: **the agent** ends a session after 10 min (a timer, then shutdown; room config has no
## D11 *default*: `forget` deletes facts, not the turn text in the journal (2026-10-20, C4-04)

**Finding.** The journal keeps every turn's text (`user_turn`, `agent_turn`; spec §4.2, C5-03's "nothing lost"). When a
visitor says "forget where I work", the `forget` tool really deletes the company facts and the rows they superseded
(B5), but the journal row "I work at Acme." stays until the idle TTL (30 days) or "Forget me" erases the thread.

**Choice.** Keep the turn text. `forget` deletes facts only, and the writer blocks the window from re-adding them this
session. Reversible: a later feature can redact the matching `user_turn` payloads in the same `apply_fact_ops` batch.

**Rejected.** Redacting now. It needs a new op in `fact_ops`/`store.py` (store.py is at 247 of 250 lines) and a rule
for which turns "mention" a value, and it breaks C5's every-turn journal guarantee.

**Question for Michael.** Should "forget X" also scrub X's turns from the journal (stronger privacy, a gap in the
history), or is the TTL plus "Forget me" enough?

