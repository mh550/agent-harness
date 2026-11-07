# Decisions

The current rule set for dj-crate-streaming. When a decision is overturned, its entry is rewritten in place to the
rule that holds now, with one "Updated in place <date>: …" line naming what replaced it; history is in git. Newest
last; a new one takes the next free number. `*default*` = taken as the simplest reversible default, for Michael to
confirm. Gathered on 2026-10-25 from `docs/specs/2026-10-13-next-session-design.md` §0 (D1–D23) and
`docs/specs/2026-10-17-amperfy-pivot.md` (D24 on), with each ID kept.

## D1–D23 (the 2026-10-13 design)

| # | Decision | Status |
|---|---|---|
| D1 | Amperfy for listening *for now*; not locked in. Our own client is the home for cross-platform search, so the long-run phone app is ours. (Updated in place 2026-10-25: the "quality tier picker" it was also the home for went with D24.) | Michael |
## D24 on (the 2026-10-17 pivot and later)

| # | Decision | Replaces |
|---|---|---|
| D24 | **One download quality.** A file is acceptable when it is lossless (flac preferred, then wav / aiff / alac) or lossy at **256 kbps or more** (mp3 or m4a). ogg, opus, wma and anything lower are refused. Verification is strict for every download (a re-encoded fake is rejected). A lossy file at or above the floor is kept; "flac preferred" only steers which candidate wins when we download, it never queues an upgrade by itself. | D9 tiers as a user choice, D15 (imports default to medium), D17 (floors), the M8 ruling on listening-tier upgrades |
| D36 *default* | **The cleanup's trash step runs only with the worker stopped**, holding `<dirname(CRATES_DB)>/worker.lock`, so beets has one writer (`plan` and `repoint` run beside the daemon). | refines D18 (one beets writer) for D31; instead of M9 §3's worker replacement jobs |
