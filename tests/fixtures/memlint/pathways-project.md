<!-- fixture: pathways commit 4cafb65^ path .harness/project.md, lines 1-24 (line n is fixture line n+1) -->
# Project rules — Pathways (threads & graphs slice)

_Appended to every harness prompt. Binding on every session. Full context: `OVERNIGHT.md`._

## Ground rules
- **Stay in this worktree.** Never run git commands in `~/projects` or `~/projects/dj-crate-streaming`
  (other sessions own them). Write only inside this worktree and your scratch directory.
- **No sudo.** Anything needing root goes in your progress entry as a question for Michael, with the exact command.
- **Read-only inputs:** `/srv/incoming/**` and `samples/`. Never modify, rename or delete an original.
- **No secrets.** Never read, print or source `.env`. Never read `/srv/docker/.env`.
- **Simple beats clever.** Zero runtime dependencies (`node:sqlite`, `node:http`, vanilla JS). Playwright lives
  outside the repo (`$HARNESS_PW`, default `/tmp/harness/pw`). Reuse the existing CSS and the Live view's look.
- **Decisions:** `OVERNIGHT.md` → "Decisions already made" and the design doc's §12 (D20–D24) are settled.
  §12 wins over §4–§6. A new decision that is Michael's gets the simplest reversible default, added to the design
  doc's §12 as `D<n> *default*`, and asked as a direct question in your progress entry.

## The spec
- **Queue:** `OVERNIGHT.md` → "Queue": M0 (done), T0, T1, T3, T4, T5, T6, T7, then stretch. **T2 is dropped.**
  Use T0…T7 and `stretch` as milestone ids.
- **Design:** `docs/specs/2026-10-14-threads-and-graphs-design.md` (§12 above all). On-screen words: `docs/naming-options.md`
  (no rename tonight; every on-screen noun comes from `ui/words.js`, built in T4).
- **Plans:** each milestone's first feature writes `docs/plans/2026-10-16-t<n>-<topic>.md`.
- **Order:** T6 (graph ↔ Navidrome) is the first to drop. Put its features after T7's docs features if time looks short.
  With no `.env` (D15), Navidrome is tested on the fake only.
