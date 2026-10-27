<!-- fixture: dj-crate-streaming commit ed75a2d^ path CLAUDE.md, lines 1-27 (line 16 is fixture line 17) -->
# dj-crate-streaming

The parts of Michael's music server we write ourselves (crates app, worker, sourcing, playlist tools) around adopted
Navidrome, slskd and beets. It runs live on this box (compose project `dj`, from `/srv/docker`), beta, one user.

## Code rules
- Simple beats clever: stdlib Python 3.10+. Adopt beets, Navidrome and slskd; don't re-implement them.
- Use what exists: `crates/playlist_edit.py` (guarded index edits), `sourcing/replace.py`, `crates/trash.py` (trash +
  `MOVES.txt`), `scripts/dedupe_copies.py` (the plan → repoint → trash pattern), `scripts/duplicate_report.py`
  (`keep_rank`), `crates/store.py`, `crates/reconcile.py`.
- Safety invariants, each with a test: never trash while any playlist (hidden entries included) still holds the file;
  scan between repoint and trash; recompute groups right before acting; every destructive step has a logged reverse.
- Read `docs/hard-won-facts.md` before touching beets, Navidrome scans or playlists.

## How to verify
- Suite: `.harness/check.sh` (pytest, paths in scratch, live credentials unset): ~1,870 tests, **about 11-12 minutes** (687 s measured). Subset:
  `.harness/check.sh tests/test_trash.py`. Run the files you touch while iterating, the full suite once at the end.
- Needs python3 ≥ 3.10 and `~/.local/bin/pytest` (`pipx install pytest`); without ffmpeg, flac, fpcalc, beet or
  sqlite3 their tests skip. No dev server: tests use the fake Navidrome/slskd in `tests/`; follow those fakes.

## Decisions and plans
- Design: `docs/specs/2026-10-17-amperfy-pivot.md` (wins on conflict), `docs/specs/2026-10-17-m9-remaining-ownership.md`,
  `docs/specs/2026-10-16-ownership-and-identity.md`, `docs/architecture.md`, build list `docs/next-todos.md`.
- Decisions: D1–D23 in `docs/specs/2026-10-13-next-session-design.md`, D24 on in the pivot spec; all settled. A new
  one that is Michael's gets the simplest reversible default, recorded in the pivot spec as `D<n> *default*`.
- Plans: `docs/plans/<date>-<milestone>-<topic>.md`; a flow that trashes files or writes tags needs a reviewed plan.

