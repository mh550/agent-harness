# Progress — run `threads-2026-10-17` (branch `harness/threads-2026-10-17`)

This is the run's log. **Newest entry first.** Every session adds one entry at the top
(`### <date time> · <feature id> · passes|not yet`, then 3–8 lines). Michael reads this on his phone.

- **Feature list:** `.harness/runs/threads-2026-10-17/feature_list.json`. Array order = priority and
  dependency order. A session works on the first feature whose `passes` is `false` and may flip only
  that flag. Milestones: T0 schema → T1 memberships + pure rules → T3 API/Live split → T4 editor →
  T5 Live view → T7 docs → T6 Navidrome (first to drop) → stretch.
- **Steer:** edit `.harness/runs/threads-2026-10-17/INBOX.md` on this branch. First line `status: pause`
  or `status: stop`; answers to the questions below under `## Answers`. The harness pulls it before every
  session; every session reads it first.
- **Spec:** `OVERNIGHT.md` (queue + rules), `docs/specs/2026-10-14-threads-and-graphs-design.md` (§12 wins),
  `docs/naming-options.md`. Project rules are appended to every prompt.

---
### 2026-10-17 verify stretch

| Feature | Step | What you ran or read | What you saw | Holds |
|---|---|---|---|---|
| S-01 | 1 | read `ui/live-render.js:151`, `ui/live.js:69-92` | `<button class="btn sadd" data-addgraph=…>+ add to graph</button>` after the `.ptap`; live.js POSTs `/api/graphs/<id>/tracks {track_ids:[…]}` | yes |
| S-01 | 2 | `tests/live-render.test.ts:180-183`; `node --test` on it | Rico card matches data-addgraph, tap closes before button; exactly 1 data-addgraph; Everything snapshot has none; pass | yes |
| S-01 | 3 | `node .harness/flows.mjs`, S-01 flow (Sunday tea tent, headless, 390 px) | PASS: songs = before(4)+1 incl. Rico, no .context card left, button ≥ 44 px, no horizontal scroll | yes |
| S-01 | 4 | `git show f451a91 --stat`; `npm run check` via check.sh | docs/api.md untouched; README gains one sentence; check green, 257 tests | yes |
| S-02 | 1 | read `src/graph.ts:418`, `src/cli.ts:29,212-221`; ran `threads from-set replay-399 --name …` on the scratch dev DB | prints name, song count, unmatched skipped ("0 songs 7 unmatched plays skipped": the dev DB's plays are unmatched; scratch only); HELP lists it | yes |
| S-02 | 2 | `tests/graph-threads.test.ts:151-170`, ran it | 6 songs in started_at order (Leroy, Rico, Woman, What's Going On, Coffy, Glide), Woman once; 'no set: nope'; duplicate name throws; pass | yes |
| S-02 | 3 | `README.md:103`; check.sh | command in the README list; green | yes |
| S-03 | 1 | read design doc §13 (lines 423-458) | 36 lines; D24 restated; add/remove/reorder cases; last-writer rule *default* (D34); `synced_at`, `changed` timestamp; "Not built in this run" | yes |
| S-03 | 2 | `OVERNIGHT.md:333` | Needs Michael line points at §13: "which side wins when both changed?" | yes |
| S-03 | 3 | `git show --stat 22d0aa0` | only docs, OVERNIGHT, harness files; no code; check green | yes |
| S-04 | 1 | read `ui/live.css`; `tests/live-context-render.test.ts:115-119` | `.pcard.context .sadd` opacity .75 + dashed; cued/open → 1 + solid; test passes | yes |
| S-04 | 2 | `tests/live-render.test.ts` pass; flows.mjs S-01 flow | 10/10 flows PASS, add flow still turns the card into an in-graph pathway | yes |
| S-04 | 3 | headless playwright, 390 px, `/live?graph=<Soul hour>` on :7791 | Rico (non-cued): button opacity 0.75×ancestors, dashed, 44 px; title 0.45; card opacity 1; scrollWidth 390/390. Cued All Night Long: 1 / solid. Screenshots `live-cued-context-{390,1280}.png` re-shot in 9fe8c8f | yes |
| S-04 | 4 | `design.md:414` (D35); check.sh | D35 present with Michael's 2026-10-17 answer; green | yes |

### 2026-10-17 22:50 · S-04 · passes
`ui/live.css`: a dimmed Live context card no longer has `opacity:.45` on the card itself, because that multiplied into its button. It fades piece by piece instead, to `--f:45%`: background and borders through `color-mix`, and the tap target `.ptap` through opacity. **+ add to graph** sits at `.75` with a dashed border (full on hover and focus). A cued or opened card sets `--f:100%` and the button turns solid, with the cued accent border kept. §12 **D35** records Michael's answer. Test: `tests/live-context-render.test.ts` +1, a CSS check over `live.css` that includes the cued and open rules (a mutation check confirmed it fails when the cued border rule is dropped). check.sh green, 256 → 257 tests; smoke 4/4; flows 10/10, including S-01's add flow.
Verified headless (Sonnet, :7791, 390 px, `/live?graph=<Soul hour>`; `?graph=Soul%20hour` works too). On the non-cued Rico Suave card, the button's opacity multiplied over its ancestors is 0.75, with a dashed border, 44 px tall; the title is at 0.45; the card's own opacity is 1, its left border is dashed in the thread colour at alpha .45. On the cued All Night Long card, title and button are at 1 and the button border is solid. Width 390/390, no page errors. Both `live-cued-context-{390,1280}.png` are re-shot; I looked at the 390 one.
Opus review: 0 Critical. I fixed its Important point (the test was too tied to formatting and missed the cued and open rules) and one Minor point (`.ptap` now fades in step with the colours). Still open, all Minor: `color-mix` needs Chrome 111 / Safari 16.2 / Firefox 113; the fade is a hair off the old whole-card fade (115 vs 113 of 255 for white text); on a phone, a tapped button stays at hover brightness until the next tap.
Not changed: the editor's context card uses `btn small` (not `.sadd`), so per step 1 it keeps the old look, button at 45 % with the card.
**Question for Michael:** should the editor's context-card button get the same 75 %, dashed look? Default: no (unchanged). Proposed changes: none.

### 2026-10-17 22:10 · S-03 · passes
Design only. `docs/specs/2026-10-14-threads-and-graphs-design.md` gains §13 (36 lines): D24's one-way export restated; rule **D34 *default*** (last writer wins per song membership, order from the side edited last, dry-run diff first); what it needs (`getPlaylist` changed timestamp, `graphs.synced_at`, a stored base snapshot); three worked examples on Leroy / Rico / Glide / Coffy (added on one side, removed on one side, reordered on both); limits; "not built in this run". `OVERNIGHT.md` "Needs Michael" gains the line pointing at §13. No code changed; check.sh green, 256 → 256 tests.
Verified: `awk` count of §13 = 36 lines (< 60); D34 was unused elsewhere (grep); `git diff --stat` shows only the two docs plus the run files.
Next session must know: S-04 (add button at ~75 % with dashed border on dimmed context cards) is next.
Question for Michael: which side wins when both changed? (Default: the later edit, per above.) Proposed changes: none.

### 2026-10-17 21:30 · S-02 · passes
Michael kept D33 (INBOX): play order = `started_at`. No code change; §12 D33 now reads as decided (*default* dropped, the load-order alternative removed). check.sh green, 256 → 256 tests; smoke 4/4.
Verified on a fresh DB built in the right order (sample import, `threads-399.sh` seed, then `serve --replay 399.session --speed 0`): `sets show replay-399` lists 7 plays, all exact; `threads from-set replay-399 --name 'Sunday as played'` → `Sunday as played  6 songs  0 unmatched plays skipped`, and `threads show` lists Leroy's Latin Lament, Rico Suave Bossa Nova, Woman of the World (once), What's Going On, Coffy Is The Color, Glide, the corrected step 2 order. `sunday AS played` again → `already exists` (exit 1); `nope` → `error: no set: nope` (exit 1); a bare `from-set` → usage. HELP and README l.103 list the command. The two S-02 tests (graph-threads, cli-threads) pass.
Next session must know: S-03 (§13 two-way sync note, design only, one worked example per conflict case) is next, then S-04 (the add button at ~75 % with a dashed border).
Questions: none. Proposed changes: none.

### 2026-10-17 20:50 · S-02 · not yet
No code changes this session; S-02 is still blocked on one question. Rechecked on its own: in the 399 replay against `demoSeed()`, Leroy's Latin Lament is row 403 and started 19:55Z (15:55 local); Rico Suave is row 402 and started 20:05Z. So step 1 ("started_at order") and step 2's example (Rico first) cannot both hold. INBOX has no answer yet.
Every other step holds: `threads from-set nope --name X` → `error: no set: nope` (exit 1); a bare `from-set` prints usage; HELP and README l.103 list the command; check.sh green, 256 tests (unchanged); smoke 4/4.
Next session must know: there is nothing left to build. Once Michael answers, either flip `passes` (if he keeps D33) or change one `ORDER BY` in `Graph.threadFromSet` to `source_row` and swap the two titles in `tests/graph-threads.test.ts` l.161–162 (if he picks load order). Until then, a new session on S-02 adds nothing. **Harness:** please hold S-02 for Michael (or skip to S-03) rather than re-running it.
**Question for Michael (same as 20:25):** a thread made from a set: order by when each song **started** (Leroy, then Rico; D33 today) or by Serato **load** order (Rico, then Leroy)? Reply under `## Answers` in INBOX.md.
Proposed change: S-02 step 2 order → "Leroy's Latin Lament, Rico Suave Bossa Nova, Woman of the World, What's Going On, Coffy Is The Color, Glide" (matches step 1 and `sets show`).

### 2026-10-17 20:25 · S-02 · not yet
Built: `Graph.threadFromSet(ref, name)` in `src/graph.ts` returns `{thread, songs, skipped}`. It creates a new thread from the set's matched songs in `getSet` order (`started_at`), each song once at its first play; plays with no song are skipped and counted. An unknown set gives `no set: <ref>`, and a duplicate name is refused by createThread. `pathways threads from-set <ref> --name <n>` (`--name` may come anywhere; a bare `--name` or an extra word prints usage) prints `Sunday as played  6 songs  0 unmatched plays skipped`. Also: HELP, a README CLI sentence, §12 **D33 *default***. Tests: `tests/graph-threads.test.ts` +1 (the 399 replay into `demoSeed()` plus one unmatched play: 6 songs, skipped 1), `tests/cli-threads.test.ts` +1. check.sh green, 254 → 256 tests; smoke 4/4.
Verified: on a fresh DB (sample, demo seed, then the 399 replay at speed 0), `sets list` shows 7 plays, 7 matched, and `threads show` lists Leroy's Latin Lament, Rico Suave, Woman of the World (once), What's Going On, Coffy, Glide, with their 5 pathways. Opus review of the diff: 0 Critical, 0 Important. I fixed its Minor points (argument order, extra words, a CLI test that would also pass with row order). Still open (Minor): a set where nothing matched makes an empty thread.
**Why it does not pass:** step 2 expects Rico Suave **before** Leroy's Latin Lament, but step 1 (and OVERNIGHT, "in play order") says `started_at` order. In 399.session Leroy started at 15:55 and Rico at 16:05; Rico was only *loaded* first (Serato row 402, Leroy 403). `sets show replay-399` also lists Leroy first. I built `started_at` order and recorded it as D33. Every other step holds.
Next session must know: the dev DB's `replay-399` plays are all unmatched, because init replays before the demo seed lands. So `from-set` there gives `0 songs  7 unmatched plays skipped`. To see real songs, build a DB in this order: sample, seed, replay.
**Question for Michael:** for a thread made from a set, should "play order" be when each song **started** (Leroy, then Rico: D33, today) or the Serato **load** order (Rico, then Leroy: one `ORDER BY source_row` in `threadFromSet`)?
Proposed change: in S-02 step 2, change the order to "Leroy's Latin Lament, Rico Suave Bossa Nova, Woman of the World, What's Going On, Coffy Is The Color, Glide". With that change the feature passes as built.

### 2026-10-17 16:08 · S-01 · passes
Live context cards get **+ add to graph** (`<button class="btn sadd" data-addgraph="<to_id>">`, aria-label names the song). A button can't hold a button, so a Live context card is now `<div class="pcard context">` around its tap target `<button class="ptap" data-track>` and the add button (the editor's context card was already a div). `ui/live.js` POSTs `/api/graphs/<id>/tracks {track_ids:[to_id]}` and reloads the snapshot; a tap on the card's padding still looks ahead. Files: `ui/live-render.js`, `ui/live.js`, `ui/live.css`, `tests/live-render.test.ts` (+1), `tests/live-context-render.test.ts` (div shape), `.harness/flows.mjs` (+1 flow; the D31 flow taps `.ptap`), README Live paragraph +1 sentence, the four `live-context*`/`live-cued-context*` screenshots re-shot. `docs/api.md` unchanged. check.sh green, 253 → 254 tests; smoke 4/4; flows 10/10.
Verified: the render test (Sunday tea tent, Woman of the World playing: only the Rico Suave context card has `data-addgraph`, and its tap target closes before the add button; the Everything snapshot has none). Sonnet headless check on :7791 at 390 px: button 44 px tall, no horizontal scroll before or after; after the click there are 0 `.pcard.context`, Rico shows as a normal card, the hero is still Woman of the World, and GET `/api/graphs/<tea>` has 5 songs. Dev DB put back to 4 songs (checked).
Opus review: 0 Critical, 0 Important. Fixed: padding taps, aria-label, flow cleanup in `finally`, stale screenshots. Open (Minor): the add button is dimmed with the card (opacity .45), so it reads faint on a dark booth screen until the card is cued or opened (see `docs/screenshots/live-cued-context-390.png`).
Question for Michael: should "+ add to graph" on a dimmed context card be shown at full brightness? (Today it is dimmed with the card. It would be one CSS rule.) Proposed changes: none.

### 2026-10-17 · verify T6

| Feature | Step | What you ran or read | What you saw | Holds |
|---|---|---|---|---|
| T6-01 | 1 | `wc -l` the plan; `git show --stat 52221a1` | file exists, 128 lines now (117 at creation); written in the T6-01 commit; writing-plans format (Goal/Spec/Tasks) | yes |
| T6-01 | 2 | read plan lines 20–32 | table of getPlaylists/getPlaylist/createPlaylist/replacePlaylist with .view call and response paths (playlists.playlist[], playlist.entry[], .playlist); replace via createPlaylist playlistId | yes |
| T6-01 | 3 | read plan Task 1 (l.36–52) | fake extended in tests/helpers/subsonic-fake.ts with three responses in 1.16.1 shapes, entry shape copied from the dj-crate sample | yes |
| T6-01 | 4 | read plan Tasks 2–3 | export order, subsonic:<id>, 'Pathways · ' name, create/replace, report line, import rules (ref then D19, create graph, replace own songs) all specified | yes |
| T6-01 | 5 | read plan l.77–105, 117–128 | sets show '→ type: note' or jump specified; every real step marked "fake only" with staged live commands | yes |
| T6-01 | 6 | `git show --stat 52221a1`; `npm run check` via check.sh | plan commit touches only docs/plans + .harness run files (feature_list, progress); check green (253 tests) | yes |
| T6-02 | 1 | read src/library.ts l.131–205 | four methods present; call() throws `subsonic <method>: <message>`; songIds sent as repeated songId (in a POST body, noted as a proposed change) | yes |
| T6-02 | 2 | `node --test tests/subsonic-playlists.test.ts tests/subsonic.test.ts`; read the test file | all pass; asserts empty → [], create songCount 2, getPlaylist refs in order, replace → songCount 1, wrong password rejects | yes |
| T6-02 | 3 | read same tests | `fake.seen` params: getAll("songId") equals ids, p absent, t and s present | yes |
| T6-02 | 4 | suite 222 → 253 overall; subsonic-playlists has 10 tests; check.sh | green | yes |
| T6-03 | 1 | `bin/pathways graphs export default --navidrome` with no SUBSONIC_* and no .env; read src/sync.ts | exit 1 `error: Navidrome is not configured (D15): …`; with a fake: `Pathways · Everything: exported 0, skipped 17 (no Navidrome ref)` + skipped titles; `--dry-run` prefix `dry run:` | yes |
| T6-03 | 2 | `node --test tests/sync.test.ts` (33 tests incl. subsonic ones pass) | Hip-hop → [gt, rd], skipped []; Saturday disco exported 2, skipped 5, Another One Bites first; re-export created false, one playlist; dry-run creates nothing, same counts | yes |
| T6-03 | 3 | CLI against the fake on a copy of dev.db: `graphs export default --navidrome`, `graphs export nope --navidrome`; test "default (Everything) exports…" | default allowed; nope → exit 1 `error: no graph: nope` | yes |
| T6-03 | 4 | read progress T6-03 entry | says "fake only" / no .env, nothing contacted :4533 | yes |
| T6-03 | 5 | check.sh; test count 222 → 253 | green, +≥4 | yes |
| T6-04 | 1 | read src/sync.ts importPlaylistToGraph; test "--graph names the graph…Everything is refused" | ref match then D19 upsert, replaces own songs, creates graph; Everything refused (test asserts) | yes |
| T6-04 | 2 | sync.test.ts Soul hour import tests (ref match, title match fills ref, new; 2nd import unchanged; `--graph`) | pass, assertions match the step | yes |
| T6-04 | 3 | fresh DB: sample import, demo seed, replay at speed 0 `--graph 'Sunday tea tent'`, `sets show replay-399`; tests/sets-show.test.ts | 7 plays: `→ Vocal: …` (Coffy), `→ Bassline: …` (Glide), 5 `jump`; formatSetLine tests pass for both forms | yes |
| T6-04 | 4 | `bin/pathways help`; `git log -- docs/api.md` | HELP lists both commands; api.md last changed in T7-02 (dd5c386), unchanged by T6 | yes |
| T6-04 | 5 | check.sh | green, 248 tests after T6-04 (+8) | yes |
| T6-05 | 1 | read progress T6-05 entry | Opus review of t6.diff (db64f11..HEAD, 1,152 lines) with findings listed (credential echo, redirect, ordering, Everything guard…) | yes |
| T6-05 | 2 | read entry; tests "redirect is an error", "fetch failure never names the URL", "an import names the own songs it removes" | 3 Important each fixed with a named test, all pass | yes |
| T6-05 | 3 | read entry "/simplify, by angle" | Reuse, Simplification, Efficiency, Altitude each name concrete changes | yes |
| T6-05 | 4 | grep README.md l.105–110, docs/STATUS.md l.9,51, design doc D24 | README and STATUS have both commands and "fake only until `.env` (D15)"; D24 has *Built (T6)* sentence | yes |
| T6-05 | 5 | `/home/mh550/projects/agent-harness/lib/check.sh`; `node .harness/smoke.mjs` | check green (253 tests); smoke 4/4 PASS | yes |


### 2026-10-17 17:20 · T6-05 · passes
Opus review of `t6.diff` (`git diff db64f11..HEAD -- src tests docs`, 1,152 lines): 0 Critical, 3 Important, all fixed RED→GREEN. (1) Behind an http→https redirect, fetch re-sent `createPlaylist` as a GET with no body, so Navidrome stored an empty playlist while the CLI printed "exported N". Fix: POSTs use `redirect: "error"`, and export throws `Navidrome kept K of N songs in "<name>"` when the returned `songCount` differs. (2) A `SUBSONIC_URL` without a scheme made fetch print the whole URL (user, token and salt). Every Subsonic fetch now goes through `SubsonicLibrary.fetch`, which reports `subsonic <method>: <cause code>` (checked: `subsonic getPlaylists: ERR_INVALID_URL`). (3) `graphs import 'Pathways · X'` silently dropped X's own songs that had no ref. `ImportResult.removed` now lists them, and the CLI prints `  removed: <song>`. Minor, still open: an artist-less Navidrome song title-matches a track of any artist and takes its ref (in STATUS limitations). Checked clean: ordering, the Everything guard (by name, case, whitespace, `Pathways · `), owner/readonly, and tests never reach the real `.env`.
/simplify, by angle. **Reuse**: `typeLabel` moved to `src/sets.ts` (`formatSetLine` uses it); one `navidrome()` CLI helper instead of two config checks; the Everything pre-check in sync.ts dropped (`setGraphTracks` refuses it inside the transaction); one `spawnAsync` in `cli-threads.test.ts`. **Simplification**: `ExportResult` is `{name, playlistId, …}` (the CLI no longer rebuilds the name), one return path in export, `PlaylistSongs` type. **Efficiency**: new index `idx_tracks_library_ref` (import looked up each song by full scan); a Set for repeats. **Altitude**: `Graph.transaction` is a SAVEPOINT (no depth counter; a caught inner failure undoes only its own writes; it nests inside the importer's dry-run BEGIN). Skipped: dropping `matched` (it's in the T6-04 step), `getSet` attaching `via` (would change `/sets/:id`), a songs-only `graphContent`, and `arg()` returning "true".
Docs: README "Threads and graphs" (Navidrome sync bullet, fake only until `.env` (D15)), `docs/STATUS.md` (T6 row, `sets show replay-399` line, limitations, counts), §12 D24 "Built (T6)" sentence. check.sh green, 248 → 253 tests; smoke 4/4.
**Fake only**: no `.env`, nothing contacted :4533. Questions: none new (D15 still open). Proposed changes: none.

### 2026-10-17 16:05 · T6-04 · passes
`src/sync.ts` `importPlaylistToGraph` (playlist id or name in any case; graph = `--graph` or the name without `Pathways · `, trimmed, created if missing; Everything refused; ref match first, else `upsertTrack` (D19); repeats keep first; empty playlist refused; all writes in one transaction). `src/graph.ts`: `findTrackByRef`, `setGraphTracks`, `transaction` nests. New `src/sets.ts` `formatSetLine` + `localTime`. `src/cli.ts`: `graphs import <playlist> [--graph <name>]` (rejects `--dry-run` and unquoted extra words), `sets show` through `formatSetLine`, HELP. `docs/api.md` unchanged. check.sh green, 240 → 248 tests; smoke 4/4.
Verified: Soul hour fake playlist (Voyager, Ain't No Stoppin Us Now, Good Times by ref `gt`) → graph Soul hour, 3 own songs in that order, 1 created, Voyager's ref filled; re-import by id → same ids, created []; `--graph 'Sunday closers'`; `Everything`/`default` refused before any write. Real run on a fresh seeded DB (`import` + `threads-399.sh` + `serve --replay 399.session --speed 0 --graph 'Sunday tea tent'`): `sets show replay-399` → 7 plays, `→ Vocal: Soul vocal into jazz-funk` (Coffy), `→ Bassline: Bass groove hands off` (Glide), 5 `jump`.
Opus review: 0 Critical, 2 Important, both fixed RED→GREEN. (1) The import wrote tracks before the graph name was checked, and the writes were not atomic: a playlist named `Pathways · ` filled refs, then threw. Now the name is trimmed and resolved first, and everything runs in one transaction. (2) `graphs import … --dry-run` did a real import; it now exits 1. Minor fixes: the prefix is matched in any case, a multi-line note stays on one line, unquoted words → usage.
Minor, open for T6-05: a ref match fills no artist or BPM; a title match on a track that holds a `serato:` ref counts as matched, but re-export skips it; the CLI opens or creates the `--db` file before Navidrome answers (export does the same).
**Fake only**: no `.env` (D15), nothing contacted :4533. Questions: none new. Proposed changes: the step text says `formatSetLine` is in cli.ts or sets.ts; it is in `src/sets.ts`, because importing cli.ts runs `main`.

### 2026-10-17 15:10 · T6-03 · passes
New `src/sync.ts`: `PLAYLIST_PREFIX`, `exportGraphToNavidrome(graph, nav, ref, {dryRun})` → `{playlist, exported, skipped, created}` (graphContent order; `subsonic:` refs only; ids de-duplicated, first place kept; replaces only the user's own, writable playlist of that exact name; two → error; nothing to export or dry run → no write). `src/cli.ts`: `graphs export <ref> --navidrome [--dry-run]` (+HELP), a `flag()` helper for boolean flags (`import --dry-run notes.md` used to swallow `notes.md`), `PATHWAYS_ENV_FILE` overrides the repo `.env`. `src/library.ts`: `subsonicFromEnv`, `Playlists.user`. Tests: new `tests/sync.test.ts` (9), `tests/cli-threads.test.ts` +1 (spawned CLI vs the fake). check.sh green, 230 → 240 tests; smoke 4/4.
Verified: Hip-hop block party → `Pathways · Hip-hop block party` songIds `[gt, rd]`, skipped 0; Saturday disco → exported 2, skipped 5 (Another One Bites the Dust first); re-export → created false, one playlist; dry run → 0 playlists, same counts; `default` → `Pathways · Everything` (exported 2, skipped 7); `nope` → exit 1 `error: no graph: nope`; no or half-set `SUBSONIC_*` → exit 1 `Navidrome is not configured (D15)…`.
Opus review: 1 Critical, 2 Important, all fixed RED→GREEN. Critical: spawned CLI tests still loaded the repo `.env`, so once D15's `.env` exists `npm run check` would have written a playlist to the real Navidrome. Every spawn in `cli-threads.test.ts` now sets `PATHWAYS_ENV_FILE` to an absent file. Important: the owner match is now case-insensitive; de-dup and mixed own-songs+threads order are tested. Minor fixed: `graphs export --navidrome` with no ref → usage; the CLI test restores the shared fixture DB's refs. Minor open (for T6-05 README): two exports running at once can both create, then every later run says "2 … delete one".
**Fake only**: no `.env` on this box (D15); nothing contacted :4533. `.harness/init.sh` and `flows.mjs` still load the repo `.env` for `serve` (read-only library search) — fine, but worth knowing.
Next session (T6-04): reuse `subsonicFromEnv` and the `runAsync`/`PATHWAYS_ENV_FILE` pattern for `graphs import`; HELP already lists `graphs export`, add `graphs import`.
Questions: none new. Proposed changes: the created line reads `(new playlist; a renamed graph exports to a new one)`, not the plan's wording (noted in the plan).

### 2026-10-17 15:20 · T6-02 · passes
`src/library.ts`: `SubsonicLibrary` gains `getPlaylists`, `getPlaylist`, `createPlaylist({name, songIds})` and `replacePlaylist(playlistId, songIds)` (createPlaylist.view with `playlistId`), plus an exported `Playlists` interface and `PlaylistInfo {id, name, songCount, owner, readonly}`; `search` and playlists share `toHit`. New `tests/helpers/subsonic-fake.ts` (fake Navidrome in 1.16.1 shapes: search3, getCoverArt, in-memory playlists, md5 token check, `seen` request log); `tests/subsonic.test.ts` uses it (its 5 tests still pass); new `tests/subsonic-playlists.test.ts` (8 tests). check.sh green, 222 → 230 tests; smoke 4/4.
Opus review: 0 Critical, 1 Important, fixed RED→GREEN. With a GET, every `songId` went in the URL: exporting `default` (~1,000 songs ≈ 40 KB) would hit a proxy's 8 KB limit, and the HTML 414 page would surface as a bare SyntaxError. Now the `songId`s go in a POST form body (auth stays in the query; `songId` still repeated, in order), and an answer that isn't JSON throws `subsonic <method>: HTTP <status>`. The fake answers 414 to URLs over 8 KB, and a 1,000-song test covers this. Minor findings: `owner` and `readonly` were added (done); the fake's missing-`playlistId` error code is commented.
Next session (T6-03): ids in the export are de-duplicated (keeping the first) in `src/sync.ts`. The transport and the fake keep order and repeats exactly as given. Match playlists by name only among `owner` = the configured user and `!readonly`. In the fake, unknown song ids get placeholder entries; real Navidrome probably drops them (unverified).
Fake only: no `.env` (D15), nothing contacted :4533. The live step should confirm that Navidrome accepts the POST form body for createPlaylist (Navidrome parses forms; not verified live).
Questions: none new. Proposed changes: T6-02 step 1 says "repeated songId params"; they are still repeated, but in the POST body, not the URL.

### 2026-10-17 14:31 · T6-01 · passes
Wrote `docs/plans/2026-10-16-t6-navidrome.md` (117 lines, superpowers:writing-plans): the four `SubsonicLibrary` playlist methods with their response paths, a shared `tests/helpers/subsonic-fake.ts` (1.16.1 shapes, song objects copied in shape from dj-crate-streaming's `navidrome_playlist_song_search3.sample.json`, request log), `src/sync.ts` export/import rules, `sets show` → `<type>: <note>` / `jump`, a review-focus list and the staged live step for Michael. Only docs/ changed; check.sh green, 222 → 222 tests; smoke 4/4.
Next session (T6-02) must know: `.harness/init.sh`'s `dev.db` replays the 399 set *before* the demo seed, so it has 0 `via_edge_id`s. For the T6-04 `sets show` check, seed a fresh DB first (as `docs/STATUS.md` "Review in 10 minutes" does): 2 pathways (Coffy, Glide), 5 jumps.
Plan rules beyond the steps (small and reversible, not new D's): export writes nothing when no song has a Navidrome ref (it never empties a playlist); two Navidrome playlists with the same name → error instead of guessing; renaming a graph exports to a new playlist and leaves the old one.
Fake only: no `.env` (D15), nothing contacted :4533.
Questions: none new (D15 still open). Proposed changes: none.

### 2026-10-17 verify T7

check.sh green (cached, 222 tests); smoke 4/4. `flows.mjs`: one run had 1 FAIL (Live "+ add to graph" D29, flaky), then 3 reruns 9/9 — flake noted, not a T7 step. Own replay on :7793 (fresh DB, `samples/notes-sample.md` + `threads-399.sh`, `--graph 'Sunday tea tent'`).

| Feature | Step | What you ran or read | What you saw | Holds |
|---|---|---|---|---|
| T7-01 | 1 | `wc -l docs/plans/2026-10-16-t7-docs.md`; read it | exists, 22 lines (<60), table of docs and what each must say | yes |
| T7-01 | 2 | read README.md l.83–140 | thread/graph two sentences (l.97–99), CLI `threads/graphs list\|show`, `serve --graph`, switcher, Threads tab, Graphs tab, Make thread from songs, `/live?graph=`, demo command + both URLs (l.132–135), screenshot names (l.138–140) | yes |
| T7-01 | 3 | read README Layout/Data model; `ls tests/*.test.ts`; `grep tests README.md` | rows for src/threads.ts, ui/words.js with existing test files (all 10 named tests exist); l.174–176 names the five v3 tables; only count is "222 tests" (l.214) | yes |
| T7-01 | 4 | `npm test` count vs progress T7-01 entry | `ℹ pass 222`; progress entry says "`npm test` → 222 pass", README 222 | yes |
| T7-01 | 5 | `npm run check --silent` / check.sh | green, 222 tests | yes |
| T7-02 | 1 | read src/server.ts l.211–250 vs docs/api.md l.115–146, 65–81, 229–263, 283–285, 298–314 | threads 8 routes and graphs 9 routes (incl. `PUT threads`) all have table rows; `?graph=` on tracks/:id, live, now, events with `404 graph not found`; Sets graph_id/via_edge_id; `SCHEMA_VERSION = 3` (db.ts:25) with all five tables' columns | yes |
| T7-02 | 2 | read docs/architecture.md l.30–41 | threads in brainstorm order, graphs (threads + own songs, induced), D23 context rule, virtual Everything, `src/threads.ts` pure rules | yes |
| T7-02 | 3 | grep `D<n> *default*` in design §12 vs progress.md | D21,D22,D24–D32 each with a sentence; includes D25, D26 and the D27/D30–D32 named in progress | yes |
| T7-02 | 4 | `git show --stat dd5c386` | only docs/api.md (+ harness files); check green | yes |
| T7-03 | 1 | read STATUS.md header + Review section; ran the commands on :7793 | header: run, branch, 222 tests, SCHEMA_VERSION 3; commands as specified. Live: Sunday tea tent → Woman of the World, cued All Night Long in `out`, Rico Suave in `context`, elsewhere_count 1; Soul hour → Glide out, cued All Night Long in `context`, elsewhere 0; both `/live?graph=` 200 | yes |
| T7-03 | 2 | read STATUS.md "What's done", "Validation performed" | T0,T1,T3,T4,T5,T7 rows (T6 "not started") with files and existing tests; T4-08 and T5-03 tables and 222 count present | yes |
| T7-03 | 3 | compare STATUS "Gaps" with progress.md l.636–646 | Q8, D15, D16, D18, D19, D21/D22, D25, D26 (+D27–D32, demo seed) all present with a simplest answer; wording expanded rather than strictly verbatim, substance matches | yes |
| T7-03 | 4 | read progress T7-03 entry | "ideas/ updates" block, 17 lines (<25): threads as brainstorm-ordered sets, graphs induced, context rendering, Navidrome as graph sync target | yes |
| T7-03 | 5 | `git show --stat 8a00e81`; check.sh | docs/STATUS.md + harness files only; green | yes |

### 2026-10-17 T7-03 · passes
Rewrote `docs/STATUS.md` for this slice (header: run threads-2026-10-17, branch, 222 tests, SCHEMA_VERSION 3): "Review in 10 minutes" (seed against a first `serve`, then the 399 replay with `--graph 'Sunday tea tent'`, both `/live?graph=` URLs and what to look for), "What's done" table T0/T1/T3/T4/T5/T7 (T6 not started), "Validation performed" with the T4-08 and T5-03 replay tables copied, "Gaps / needs Michael" (18 items: Q8, D15, D16, D18, D19, D21/D22, D25–D32, seed content, migration race, laptop, merge). No code changed; check.sh green, 222 tests. Proposed changes: none. Questions: none new.

```
ideas/ updates (for ~/projects/ideas, from the threads-2026-10-17 run)
- Threads = brainstorm-ordered song sets (D21): a thread is the songs in the order you add them
  (thread_tracks.position), not a set of connections. Reorder rewrites 1..n.
- Graphs = induced subgraphs (D22): a graph holds threads + own songs; its pathways are every
  pathway between its songs. No per-connection membership. Everything (id "default") is the whole library.
- Pathways stay global (model B); threads and graphs are memberships over songs.
- Context rendering: for the song playing, pathways are split in graph / context (far end shares a
  thread with it, dimmed, chip "thread · context") / elsewhere (count only, "<- N elsewhere").
  A song outside the graph shows none (D30). A cued context card lights up (full opacity, CUED).
- Live follows ?graph=<id|name> (D25); plays are stamped with graph_id and via_edge_id, so a recorded
  set remembers which graph it was played in and which pathway it followed.
- Brainstorm -> set loop: build a thread by ordering songs, play with the Live view in a graph,
  the replay shows pathways followed vs jumps (399: 2 pathways, 5 jumps).
- Navidrome as the graph sync target (T6, not built): graph -> playlist one-way (re-export =
  sync), playlist -> graph on import; CLI only until D15 credentials exist; tested on a fake.
- Open for the review: Q8 naming (the "pathway" collision), D30 (hide vs show outside pathways),
  D26 chip choice, D31/D32 Live taps.
```

### 2026-10-17 T7-02 · passes
Audit of docs against `src/server.ts`: api.md already had every route (threads: 8 rows = list/create/get/patch/delete/tracks add/tracks delete/order; graphs: 9 rows = those + `PUT threads`), `?graph=` on tracks/:id, live, now and events, Sets `graph_id`/`via_edge_id`, SCHEMA_VERSION = 3; architecture §1a covers threads, graphs, D23, Everything, `src/threads.ts`; §12 lists D20–D32. Gaps fixed (docs/api.md only): schema line now has `created_at, updated_at` for `threads` and `graphs`; `GET /api/live?graph=` states the 404 rule.
Verified: `git diff --stat` only docs/api.md; check.sh green, 222 tests (unchanged). Proposed changes: none. Questions: none.

### 2026-10-17 T7-01 · passes
Wrote `docs/plans/2026-10-16-t7-docs.md` (22 lines). README: added the CLI bullet (`threads|graphs list|show`, `serve --graph`, D27), `--graph` in the serve usage, Layout rows for `src/threads.ts`, `ui/words.js`, `ui/editor-render.js` with their tests, and the test count 122 → 222. The Threads-and-graphs section, demo seed with both `/live?graph=` URLs, screenshot names (all exist) and the five v3 tables were already there from T4/T5.
Verified: `npm test` → 222 pass, 0 fail; README's only count is 222; `check.sh` green.
Note: `docs/STATUS.md` still says 117 tests (dated 2026-10-15 snapshot, left as history). Proposed change: none.

### 2026-10-17 20:30 · verify T5

check.sh green (222 tests), smoke 4/4, flows.mjs 9/9. Own Playwright run on :7791 and own replay on :7792 (fresh DB, `--graph 'Sunday tea tent'`, seeded first). Note: the plan/feature text expects 3 pathways in the replay; the DB shows 2 (`via_edge_id` set only on Coffy and Glide) — Leroy was played before Rico, so the expectation was wrong, the table is right.

| Feature | Step | What you ran or read | What you saw | Holds |
|---|---|---|---|---|
| T5-01 | 1 | `wc -l` on docs/plans/2026-10-16-t5-live-context.md; read header | 84 lines (<150); names superpowers:writing-plans | yes |
| T5-01 | 2 | read plan Task 2 renderCards spec | out cards, ctxrule per thread, `pcard context` + tchip `<thread> · context`, note hidden, `← N elsewhere`, cued context keeps both chips (rule 4) | yes |
| T5-01 | 3 | read plan Task 2 renderNow + Task 3 live.html/live.js | hero counts out.length, graph chip when id≠default, #graphName by LIVE, ?graph= to api/events, 404 → "Unknown graph" | yes |
| T5-01 | 4 | read plan Task 2 tests + Task 4 | Sunday tea tent (1 out, 1 context, ← 1 elsewhere), Soul hour (1 out, 2 context, ANL cued in context), screenshots in Task 4 | yes |
| T5-01 | 5 | `git diff --name-only 35ab123 f1adcc8 0c4c56a eef1d16 \| grep -v ^docs/`; `npm run check --silent` | only .harness/runs files outside docs/; check green | yes |
| T5-02 | 1 | read ui/live-render.js diff; headless on :7791 both graphs | one card() for both kinds; ctxrule per thread; `pcard context`, chip "X · context"; `pcard context cued` + CUED chip (Soul hour); graph chip; words from words.js | yes |
| T5-02 | 2 | read ui/live.css diff; computed styles at 1280/390 | context opacity .45, dashed border; cued → opacity 1; card height 92/118 px (≥44) | yes |
| T5-02 | 3 | headless: header text, Soul hour #addPath, `/live?graph=nope` | header "LIVE · Sunday tea tent"; no #addPath in Soul hour; nope → pill "Unknown graph" | yes |
| T5-02 | 4 | `node --test tests/live-context-render.test.ts`; read test names | 7/7 pass: Sunday, Soul hour, Everything, escaped names/colours, context-only/elsewhere-only, D31 | yes |
| T5-02 | 5 | smoke; headless `/live?graph=<Sunday id>` at 1280 and 390 | smoke 4/4; 1 .pcard.context, header "Sunday tea tent", no non-404 console errors, scrollWidth 390 | yes |
| T5-02 | 6 | test count: 214 (plan) → 222 now; `npm run check --silent` | +8 tests, green | yes |
| T5-03 | 1 | headless both graphs at 1280 and 390 | no console errors except art 404; scrollWidth 390 at 390 | yes |
| T5-03 | 2 | read docs/screenshots/live-cued-context-390.png; checked the other three exist; DOM text for both graphs | Soul hour: Glide, ANL dashed full CUED under Night closers, Rico dimmed under Tea-tent, no elsewhere; Sunday: `← 1 elsewhere`, Rico dimmed | yes |
| T5-03 | 3 | own replay :7792; `select … from plays` and `/api/live?graph=` for both graphs | 7 plays; via_edge only on Coffy and Glide (2 pathways, 5 jumps, Rico→Leroy is reversed in play order); Soul hour cued in context (Night closers); progress table has all 7 rows + Soul hour row and explains the 2-vs-3 difference | yes |
| T5-03 | 4 | read the T5-03 entry | "Proposed changes" lists 3 items | yes |
| T5-03 | 5 | `npm run check --silent` | green | yes |
| T5-04 | 1 | read the T5-04 entry; diff 806fdb4..HEAD | review findings (2 Important, 3 Minor) listed with the five angles; diff matches them | yes |
| T5-04 | 2 | read tests/live-graph.test.ts diff (D32 test), flows 9/9, T5-03 proposals in entry | rename/delete flow and "+ add to graph" flow pass; hero chip "1 pathway · 2 in context" seen live; other proposals rebutted/kept with reasons | yes |
| T5-04 | 3 | read the entry's per-angle list; diff of live-render.js, live.css | reuse/simplification/efficiency/altitude each named; graphName(), single `border-left-style:dashed` rule seen in diff | yes |
| T5-04 | 4 | grep docs/api.md and README.md | api.md has graph/context/elsewhere_count/in_graph + example snapshot (l.219–246); README l.116–121 links /live?graph= and both screenshots | yes |
| T5-04 | 5 | smoke; `npm run check --silent` | 4/4; green | yes |


### 2026-10-17 19:40 · T5-04 · passes

Opus review of `git diff 806fdb4..HEAD -- src tests docs ui` ($HARNESS_SCRATCH/t5.diff): escaping and cued-in-context precedence clean; 2 Important + 3 Minor, fixed test-first: (I) `/live?graph=<name>` broke after a rename (taps, Back to Serato, the Add pathway refresh and reconnects went out under the old name → 404): live.js now pins `?graph=` to `snap.graph.id` after the first snapshot; (I) "Add pathway" showed when the pathway existed but was *elsewhere* (or the playing song outside the graph), re-posting it: `cued_edge_id` now also searches elsewhere (src/live.ts) and the strip says **+ add to graph** (joins only, no picker) — **D32 *default*** in §12; (m) "Unknown graph" now also clears the header name and hero, and a click's "graph not found" 404 goes there too; (m) editor's opened context note was 45 % opacity (style.css). Rebutted: no retry after a 404 (plan's choice; the editor link is the way out); one shared context stylesheet (two pages, deliberately different sizes).
T5-03 proposals: hero chip now "1 pathway · 2 in context" (fixed); step-3 wording is feature-list text (still proposed); tap hint kept (a context tap does look ahead, D31 open); 45 % dimming kept (§7 rule 2).
Simplify — reuse: `graphName(snap)` for hero chip + header, `fetchSnapshot()` for 4 GETs; simplification: context border via `--edge` = thread colour, one `border-left-style:dashed` rule instead of three selectors; efficiency: grouping without re-spreading arrays; altitude: `renderCards(snap, opened)` draws opened notes (no DOM pass after render). Docs: api.md example snapshot + Live page description, README Live section links `/live?graph=` and both screenshots (retaken: new hero chip).
Verified: 220 → 222 tests, check green; smoke 4/4; flows 8 → 9/9 (the Live join flow now asserts "+ add to graph", no picker, pathway count unchanged; new rename/delete flow; both FAIL on the old live.js); Sonnet headless on :7791, both graphs at 1280/390: 9/9 (dashed border kept on hover/cued, 0 px overflow, chips exact).
Also repaired the progress header (T5-03 had landed inside it). **Question for Michael — D32 *default***: an elsewhere pathway to the cued song gives "+ add to graph" in Live. OK, or hide the button? D31 still open.

### 2026-10-17 18:30 · T5-03 · passes

Screenshots only (no code; 220 tests unchanged, check green, smoke 4/4): `docs/screenshots/live-context-{1280,390}.png` (Sunday tea tent) and `live-cued-context-{1280,390}.png` (Soul hour), full page, Playwright on the init server :7791. Both graphs at both widths: 0 px horizontal overflow, no console errors besides art 404s. I opened them: tea = All Night Long full + CUED, dashed rule "from thread Tea-tent Latin jazz (not in this graph)" over a dimmed Rico Suave, "← 1 elsewhere"; Soul hour = Glide, All Night Long (dashed, full opacity, CUED, chip "Night closers · context") under its Night closers rule, Rico Suave dimmed under Tea-tent Latin jazz, no elsewhere line.

Replay on :7792 (fresh DB, notes sample + threads-399.sh, `--replay 399.session --speed 0 --graph …`); start times NY:

| start | deck | status | raw title — artist | match | resolved | graph | in graph / context / elsewhere | cued | via_edge |
|---|---|---|---|---|---|---|---|---|---|
| 15:55:26 | d1 | played | Leroy's Latin Lament: Lonnie Dreams/… — War | exact | Leroy's Latin Lament… | Sunday tea tent | 0 out, 1 in / 0 / 0 | – | none (jump) |
| 16:05:38 | d2 | played | Rico Suave Bossa Nova feat. Azymuth — J Dilla | exact | Rico Suave Bossa Nova… | Sunday tea tent | 0 out, 1 in / 0 / 0 | – | none |
| 16:10:59 | d1 | played | Woman of the World — Donald Byrd | exact | Woman of the World | Sunday tea tent | 1 out / 1 (Tea-tent Latin jazz) / 1 | – | none |
| 16:17:28 | d2 | played | What's Going On — Marvin Gaye | exact | What's Going On | Sunday tea tent | 1 out / 0 / 0 | – | none |
| 16:23:26 | d2 | played | Coffy Is The Color — Roy Ayers | exact | Coffy Is The Color | Sunday tea tent | 0 out, 1 in / 0 / 1 | – | pathway ea3205f3 (What's Going On→Coffy) |
| 16:44:27 | d1 | played | Glide — Pleasure | exact | Glide | Sunday tea tent | 0 out, 2 in / 0 / 0 | – | pathway d99f1ef7 (Coffy→Glide) |
| 18:24:00 | d1 | current | Woman of the World — Donald Byrd | exact | Woman of the World | Sunday tea tent | 1 out / 1 (Tea-tent Latin jazz) / 1 | yes, All Night Long (in graph) | none |
| 18:24:00 | d1 | current | same, `--graph 'Soul hour'` (live snapshot) | exact | Woman of the World | Soul hour | 1 out (Glide) / 2 (Night closers: All Night Long; Tea-tent Latin jazz: Rico Suave) / 0 | yes, All Night Long (in context, Night closers) | none |

Only 2 pathways were followed, not the brief's 3: Rico Suave→Leroy's Latin Lament exists as an edge, but Leroy was played *before* Rico, so it is not a pathway in play order; 5 plays are jumps. The 18:24:00 vs live `started_at` 18:23:55 difference is the known pre-T4 one. Re-running the replay with a second `--graph` on the same DB does not re-stamp existing plays (plays unique per source row); the Soul hour row is from `/api/live?graph=`.

**Proposed changes**
- Step 3 should say 2 pathways, 5 jumps (Rico→Leroy is played in reverse).
- Hero chip says "1 pathway" in Soul hour though three cards show (1 in graph + 2 context); and the unchanged tap hint "Tap a pathway to look ahead" covers dimmed cards too. T5-04 could count only in-graph pathways explicitly or label "1 pathway · 2 in context".
- The dimmed Rico Suave card is low contrast on a phone (title ~45 % opacity); fine as "not in this graph", but hard to read at a glance.

### 2026-10-17 15:10 · T5-02 · passes

`/live?graph=` now shows the graph: header `LIVE · Sunday tea tent` (`#graphName`, ellipsis) and a hero chip "graph Sunday tea tent"; the list is in-graph cards, then one dashed "from thread *X* (not in this graph)" rule per thread over dimmed `.pcard.context` cards (thread chip, note hidden), then "← N elsewhere". A cued context card lights up (opacity 1, dashed border kept). Files: `ui/live-render.js` (one `card()` for both kinds; `elsewhereLine` moved here, re-exported by editor-render.js), `ui/live.css`, `ui/live.html`, `ui/live.js`, new `tests/helpers/demo-seed.ts` (in-process demo seed + drift test against threads-399.sh), `tests/live-context-render.test.ts`. Tests 214 → 220, check green; smoke 4/4; `.harness/flows.mjs` 8/8 (new D31 flow).
Verified headless on :7791 (Sonnet + my own checks): tea → 1 context card (opacity 0.45, dashed rgb(34,211,207), also on hover), rule text exact, "← 1 elsewhere", 0 px overflow at 390; Soul hour → All Night Long `context cued` opacity 1 with cued chip, 2 rules, no Add pathway; `?graph=nope` and a graph deleted while open → pill "Unknown graph" for good (1–2 event requests), stale cards replaced by "Unknown graph. Pick one in the editor."; a 60-char name → 0 overflow at 390 (the first run found 99 px from the hero chip; fixed by letting chips wrap).
Opus review fixed: Live's look-ahead and Back to Serato dropped `?graph=` (the reply was Everything's snapshot, so the graph name, rules and elsewhere disappeared after a tap; a pre-T5 bug, now covered by the D31 flow); an opened context note was at 45 % opacity (now 1).
Next (T5-03): screenshots + replay table; the init server's graph names and notes are restored as seeded.
No new questions; D31 (first tap shows the note, second looks ahead) is still open from T5-01.

### 2026-10-17 13:59 · T5-01 · passes

Plan written: `docs/plans/2026-10-16-t5-live-context.md` (84 lines, superpowers:writing-plans). Tasks 1–3 = T5-02 (in-process demo seed `tests/helpers/demo-seed.ts` with a drift test against `threads-399.sh`; `renderCards` out → one "from thread X (not in this graph)" rule per thread + `.pcard.context` cards → "← N elsewhere"; graph chip in the hero; `#graphName` next to LIVE; "Unknown graph" on a 404 that also stops the 2 s reconnect loop), Task 4 = T5-03, Task 5 = T5-04. Docs only; suite unchanged at 214 tests, green; smoke 4/4.
Verified the plan's numbers on the init server :7791: Sunday tea tent → out All Night Long (cued), context Rico Suave [Tea-tent Latin jazz], 1 elsewhere; Soul hour → out Glide, context All Night Long [Night closers] (cued) + Rico Suave [Tea-tent], 0 elsewhere; Everything → 3 out.
Next session (T5-02): `elsewhereLine` moves from editor-render.js to live-render.js (re-exported); `.pcard.cued`/`:hover` override `border-left-color`, so the context rule must reset the whole dashed border.
**Question for Michael — D31 *default*** (recorded in §12): in Live, the first tap on a dimmed context card shows its note; the second tap looks ahead. OK, or should every tap look ahead at once (notes never shown in Live)?

### 2026-10-17 · T4-08 · passes

Fixed the verifier's failure: retook all ten `docs/screenshots/editor-{switcher,context,threads,thread-page,graphs}-{1280,390}.png` as full-page shots on the init server :7791 (script in scratch). They now show the current tagline "Songs, pathways, threads and graphs". The 390 px context shot shows All Night Long, the dimmed Rico Suave card with chip "Tea-tent Latin jazz · context", and "← 1 elsewhere"; the 390 px thread page shows all 4 songs and 3 pathway cards. I opened both. All ten pages: scrollWidth − innerWidth = 0, no console errors. Smoke 4/4, check green (214 tests, unchanged). The replay table and proposals from the earlier T4-08 entry still stand (verified in the verify T4 entry).

### 2026-10-17 18:00 · verify T4

All 51 steps re-run on the current tree (check/smoke green; T1-fixture server :7795 for the UI steps, init server :7791, replay :7792, `.harness/flows.mjs`). All hold; no `passes` changed.

| Feature | Step | What you ran or read | What you saw | Holds |
|---|---|---|---|---|
| T4-01 | 1 | `wc -l` plan; `git log --diff-filter=A` | 129 lines; line 11 "Written with: superpowers:writing-plans"; added in 8302516 | yes |
| T4-01 | 2 | read plan lines 22–33 | `words` keys incl. everything, plural, cap, words.d.ts, strings to switch in live-render/live.html/index.html/app.js | yes |
| T4-01 | 3 | read plan Shared interfaces + Task 2 | `#graphSwitch` from /api/graphs, Everything first, ?graph= + localStorage 'pathways.graph', aside list, `/api/tracks/:id?graph=` | yes |
| T4-01 | 4 | read plan line 47, Task 3 step 1 (line 74) | `.pcard.context` opacity/dashed border, `.tchip` "<thread> · context", note hidden until `open`, `+ add to graph` POST, `.elsewhere`, Web dashed outlines | yes |
| T4-01 | 5 | read plan Tasks 4–5 (lines 92–105) | Threads list/page, Graphs tab, Select mode + Make thread → POST /api/threads, + New track also joins active graph | yes |
| T4-01 | 6 | read plan Tasks 6–7 | seed script `docs/demo/threads-399.sh`, headless and `editor-*-{1280,390}` screenshot names | yes |
| T4-01 | 7 | `git show --stat 8302516`; `lib/check.sh` | plan + design §12 in docs/ (plus harness bookkeeping files); check green, 214 tests | yes |
| T4-02 | 1 | read ui/words.js/.d.ts; `node --test tests/words.test.ts` | keys as specified, plural/cap; tests "plural picks the word for the count", "cap and the fixed words" pass | yes |
| T4-02 | 2 | `grep words ui/live-render.js`; `node --test tests/live-render.test.ts`; `git diff 2eb85c8 HEAD --stat -- tests/live-render.test.ts` | imports ./words.js; all live-render tests pass; test file not edited | yes |
| T4-02 | 3 | `grep outHead ui/live.js ui/live.html`; `grep -c pathway ui/app.js` | live.js:7 sets heading from `cap(words.pathways)`; Track/Web tabs unchanged. app.js has 26 `pathway` hits but all are the localStorage key, comments, or `d.pathways` data fields (no on-screen literal) | yes |
| T4-02 | 4 | step's grep on ui/*.js, minus words.* | only comments, the 'pathways.graph' key, variable/data names and the product name "Pathways" remain | yes |
| T4-02 | 5 | `node .harness/smoke.mjs` | PASS editor/live @1280 and @390 (4/4) | yes |
| T4-02 | 6 | `lib/check.sh` | green (214 tests) | yes |
| T4-03 | 1 | Playwright :7795: `/?graph=<HH>`; switcher; stored `bogus` id; URL vs localStorage | options Everything, Hip-hop block party, Saturday disco; value=HH id; localStorage written; unknown stored id → `default`, 0 errors; URL beat localStorage 'default' | yes |
| T4-03 | 2 | same page, read aside and `#stats` | aside = Good Times, Rapper's Delight; pill "2 songs · 1 pathway · Hip-hop block party"; Everything lists all (flows.mjs PASS) | yes |
| T4-03 | 3 | click Good Times; inspect cards; click context card; click `+ add to graph` | 1 `.pcard` Rapper's Delight; 1 `.pcard.context` Another One…, `--thread:#f59e0b`, chip "Good Times bassline · context", note display:none until click then class `open`; after add: 2 normal out cards (+1 in card); no `.elsewhere` | yes |
| T4-03 | 4 | computed styles; `git diff main..HEAD --stat -- ui/live.css` | opacity 0.45, border-left dashed; live.css untouched | yes |
| T4-03 | 5 | headless run above at 390 px | exactly the counts the step names; scrollWidth 390 = viewport; 0 console errors | yes |
| T4-03 | 6 | `tests/editor-render.test.ts`; smoke; check | renderer extracted (ui/editor-render.js) and its tests pass; smoke 4/4; check green | yes |
| T4-04 | 1 | read ui/app.js:285–303 and editor-render.js; Web view in HH centred on Good Times | context lines `stroke-dasharray 6 4` opacity .45 in thread colour; context node fill none dashed ring; `.elsewhere` caption exists; no elsewhere/outside-incoming drawn | yes |
| T4-04 | 2 | Everything, Web of Voyager | 6 `g.node`, 6 `line` | yes |
| T4-04 | 3 | click `g.node.context`; open Track tab | re-centred on "Another One Bites the Dust"; its Track view (in graph HH) shows the D30 line "Not in this graph, so its pathways are hidden · + add to graph" plus its in-card (D30, recorded after this step, replaces "own split") | yes |
| T4-04 | 4 | Web tab at 1280/390 | 3 `g.node`, one `.node.context` "Another One Bites the Dust"; 2 `line` (one `6 4` dashed, .45); 390 scrollWidth 390; 0 errors; shot web-context-1280.png in scratch | yes |
| T4-04 | 5 | smoke; `lib/check.sh` | 4/4; green | yes |
| T4-05 | 1 | Threads tab on :7795 | rows "French touch filter family 3 songs · in: Saturday disco", "Good Times bassline 4 songs · in: Saturday disco" (swatch, motif cell in markup) | yes |
| T4-05 | 2 | read ui/app.js:372–390; ran flow | create form name/motif/colour, POST /api/threads, `fail(e)` shows server 400; Select-mode flow created a thread and opened its page | yes |
| T4-05 | 3 | read bindSongRows / renderThreadPage; plan lines 92–93 | ↑↓ PUT order with full list, ✕ DELETE, + Add song via openPicker, "Pathways in this thread" cards, Delete thread (confirm) | yes |
| T4-05 | 4 | Playwright: open Good Times bassline; ↓ on Good Times; ✕ on Le Freak; 390 px | 4 rows in order, 4 pathway cards; after ↓ Rapper's Delight, Good Times…; after ✕ 3 rows, `/api/tracks` still 9; scrollWidth 390; 0 errors; threads-{1280,390}.png in scratch | yes |
| T4-05 | 5 | smoke; check | 4/4; green | yes |
| T4-06 | 1 | Graphs tab: list, Everything page, HH page tick/untick | list Everything 9·15, Hip-hop 2·1, Saturday disco 7·11 (checked via /api/graphs before my own Le Freak removal and after restoring it); tick Good Times bassline → 4 songs/4 pathways; untick → 2/1; Everything page text "holds every song and pathway and cannot be edited", 0 buttons/inputs | yes |
| T4-06 | 2 | on HH: + New track → picker free text "Brand New Song by Nobody" | aside lists it immediately; HH own_songs has it too | yes |
| T4-06 | 3 | Select, click Le Freak, Voyager, Good Times; Make thread (prompt "Chic family") | badges 1 Le Freak, 2 Voyager, 3 Good Times (clicks in that order); button hidden after; Threads tab opened | yes |
| T4-06 | 4 | `GET /api/threads/<new>`; 390 px for Graphs | songs Le Freak, Voyager, Good Times; scrollWidth 390; 0 errors; graphs-{1280,390}.png in scratch | yes |
| T4-06 | 5 | smoke; check | 4/4; green | yes |
| T4-07 | 1 | read docs/demo/threads-399.sh; ran against :7791 | 69-line bash+curl+node -e; creates 8 songs/7 pathways/2 threads/2 graphs (asserted by demo-seed test: titles, colours, own songs, no threads) | yes |
| T4-07 | 2 | re-ran the script on :7791 (exit 0) | "…: exists" lines only, ends with both graph ids and both `/live?graph=` URLs; test asserts no "created" in 2nd run | yes |
| T4-07 | 3 | `node --test tests/demo-seed.test.ts` (2 tests pass); read lines 30–61 | counts [8,7,2,3]; tea: current WotW exact, out [All Night Long] cued, context [Rico Suave/Tea-tent Latin jazz], elsewhere 1; soul: out [Glide], context 2, elsewhere 0, cued = context edge | yes |
| T4-07 | 4 | init output; `GET /api/graphs` on :7791 | "seed: ok"; Everything 17·22, Soul hour, Sunday tea tent present | yes |
| T4-07 | 5 | README lines 83, 119–127 | seed command and `/live?graph=` URLs present | yes |
| T4-07 | 6 | `git show --stat a2bdf71`; check | new tests/demo-seed.test.ts (2 tests); 214 tests green | yes |
| T4-08 | 1 | Playwright on :7791 at 1280 and 390 for `/`, `/?graph=<tea>#WotW`, Threads, Tea-tent thread page, Graphs | scrollWidth = viewport on all 10; 0 console errors (404s ignored) | yes |
| T4-08 | 2 | `ls`/`file` docs/screenshots/editor-*; viewed context-390 and thread-page-1280 | all 10 files exist (1280 and 390 wide, full-page); context shot shows All Night Long full, Rico Suave dimmed with "Tea-tent Latin jazz · context", "← 1 elsewhere" | yes |
| T4-08 | 3 | fresh DB on :7792: import sample, seed, restart `--replay 399.session --speed 0 --graph 'Sunday tea tent'`; read `/api/sets/replay-399`, `/api/live?graph=`, `/api/tracks/<id>?graph=` | 7 plays, all exact, graph_id = tea; live current WotW, out [All Night Long], cued set, context Rico, elsewhere 1 | yes |
| T4-08 | 4 | compared with progress T4-08 table | 7 rows, columns present; per-row counts match my read (e.g. WotW 1 out/1 context/1 elsewhere; Coffy 1 in/0/1; Glide 2 in; via_edge for Coffy, Glide). Last start is 18:24:00 not 18:23:55: the entry notes it (live `started_at` = 18:23:55, play row 18:24:00) | yes |
| T4-08 | 5 | read entry "Proposed changes" and T4-09 handling | four proposals listed (not fixed in T4-08) | yes |
| T4-08 | 6 | `lib/check.sh` | green | yes |
| T4-09 | 1 | `ls -la $HARNESS_SCRATCH/t4.diff`; read T4-09 entry "Review (Opus)" | t4.diff exists (117 KB); 12 findings listed incl. XSS/localStorage/race/idempotence areas | yes |
| T4-09 | 2 | read entry; `node .harness/flows.mjs`; D30/D25 in §12 | Important 1–4 fixed (tests + flows 7/7 PASS), proposals fixed (tagline "Songs, pathways, threads and graphs" seen in UI; aside capped; Review title) or kept with reason; D30 *default* recorded | yes |
| T4-09 | 3 | read entry "Simplify" | names per angle: reuse (esc, joinGraph, bindRows, bindCreate, pageFailed, `.sw`), simplification (pickGraph), altitude (in_graph), efficiency (seed) | yes |
| T4-09 | 4 | read README "Threads and graphs" (line 95+) | switcher, tabs, Make thread, seed command, two `/live?graph=` URLs (checked live: both work by name), screenshot names | yes |
| T4-09 | 5 | smoke; check | 4/4; green | yes |

### 2026-10-17 14:05 · verify T4

51 steps re-run by an Opus verifier (the first verify T4 entry, below, had been written into this file's header, so the harness did not see it; it is moved below this one unchanged and the header is restored). Three Sonnet subagents with Playwright drove the UI steps: T4-03/T4-04 on a fresh T1-fixture server :7795 (notes sample + both threads + Saturday disco + Hip-hop block party posted via the API), T4-05/T4-06 on :7796 (same fixture, reset between mutating runs), T4-08 on the init server :7791 and a replay server :7792. I ran the seed on a fresh empty server :7797 and `flows.mjs` (:7794) myself. **8 hold, 1 fails: T4-08** (step 2). `docs/screenshots/editor-context-390.png` shows only the header, aside and the song card. All Night Long, the dimmed Rico Suave card with its chip and "← 1 elsewhere" are all missing. Also, all ten `editor-*` screenshots predate T4-09: they still show the old "Phase 1 · graph + notes importer + editor" tagline and the uncapped aside. Fix: retake the ten (390 px context and thread page scrolled to the cards or full-page).

| Feature | Step | What you ran or read | What you saw | Holds |
|---|---|---|---|---|
| T4-01 | 1 | `wc -l docs/plans/2026-10-16-t4-editor.md`; `grep writing-plans` | 129 lines (< 250); line 11 "**Written with:** superpowers:writing-plans (T4-01)" | yes |
| T4-01 | 2 | read plan lines 22–33 | `words` object with the 13 keys (everything: "Everything"), `plural`, `cap`, `ui/words.d.ts` signature, and the strings to switch in live-render.js, live.html/live.js, index.html, app.js | yes |
| T4-01 | 3 | read plan Task 2 step 1, Shared interfaces (line 37) | `<select id="graphSwitch">` from GET /api/graphs, Everything first; `?graph=` via replaceState + localStorage 'pathways.graph'; aside `state.songs`; Track/Web fetch `GET /api/tracks/:id?graph=` | yes |
| T4-01 | 4 | read plan line 47, Task 2 step 3, Task 3 step 1 | `.pcard.context{opacity:.45;border-left:2px dashed var(--thread)}`, `.tchip` "<thread> · context", note hidden until `open`, `+ add to graph` → POST /api/graphs/:id/tracks {track_ids:[to_id]}, `.elsewhere` "← N elsewhere", Web context node fill none dashed, line dashed at .45 | yes |
| T4-01 | 5 | read plan Tasks 4–5 (lines 90–105) | Threads list/page (↑↓, addSongVia → openPicker, remove, derived pathways); Graphs tab (create/rename/delete, checkboxes, own songs, Everything read-only); Select → numbered ticks → `Make thread (n)` → POST /api/threads {name, track_ids}; `+ New track` joins the active graph | yes |
| T4-01 | 6 | read plan Task 6 (line 109) and Task 7 (line 119) | seed docs/demo/threads-399.sh with init line; T4-08 headless pages and `editor-{switcher,threads,thread-page,graphs,context}-{1280,390}.png` | yes |
| T4-01 | 7 | `git show --stat 8302516`; `npm run check --silent` | plan + design §12 (docs/) plus the harness's own feature_list/progress bookkeeping; check green, 214 pass 0 fail | yes |
| T4-02 | 1 | read ui/words.js, ui/words.d.ts; `node --test tests/words.test.ts` | exports match; .d.ts declares words/plural/cap; test asserts plural(1,…)==='pathway', plural(3,…)==='pathways', keys = the 13; 2/2 pass | yes |
| T4-02 | 2 | `grep words ui/live-render.js`; `git diff 2eb85c8 HEAD -- tests/live-render.test.ts`; ran it | imports ./words.js; hero chip `plural(snap.out.length, words.pathway, words.pathways)`, empty states use words; "← N lead here" kept as is (no noun; plan says so); test file unchanged since T3-05; words+live-render 11/11 pass | yes |
| T4-02 | 3 | read ui/live.js:4–7, index.html tabs, app.js:623–624; `grep -c pathway ui/app.js` | live.js sets `#outHead` = cap(words.pathways)+" from this track"; tab labels Track/Web stay, Threads/Graphs set from words at load; 26 hits in app.js: all words.* or comments, the localStorage key and the `pathways` variable names | yes |
| T4-02 | 4 | the step's grep, minus `words.*` lines | left: comments (live-render.js:4,116,119; editor-render.js:17,39,40,53,94; app.js:310), `'pathways.graph'` key (app.js:67,78) and variable names (`detail.pathways`, `d.pathways`); no hard-coded on-screen use | yes |
| T4-02 | 5 | `node .harness/smoke.mjs` | PASS editor @1280, @390, live @1280, @390 (4/4) | yes |
| T4-02 | 6 | `lib/check.sh`; `npm run check --silent` | green; 214 tests, 214 pass, 0 fail | yes |
| T4-03 | 1 | Playwright :7795: option list, selectOption, URL + localStorage, stored Saturday disco vs `?graph=<Hip-hop>`, stored 'zzz' | options Everything, Hip-hop block party, Saturday disco; select → `?graph=<id>` + localStorage; URL wins; 'zzz' → value 'default', 0 console errors | yes |
| T4-03 | 2 | `/?graph=<Hip-hop>` aside + `#stats`; then Everything | aside = Good Times, Rapper's Delight (= GET /api/graphs/:id songs); pill "2 songs · 1 pathway · Hip-hop block party"; Everything: 9 songs, pill "9 tracks · 15 pathways · 1 saved labels" as before | yes |
| T4-03 | 3 | Good Times in Hip-hop, requests captured | UI GETs `/api/tracks/<GT>?graph=<hiphop>`; context card `pcard context` style `--edge:#b76bff;--thread:#f59e0b`; `.tchip` "Good Times bassline · context"; note display none → click → `open`, block → click → none; `+ add to graph` POSTs `/api/graphs/<hiphop>/tracks {"track_ids":["<AO>"]}` and re-renders as a normal card; elsewhere_count 0 → no line; Rapper's Delight (count 1) shows `← 1 elsewhere` | yes |
| T4-03 | 4 | read ui/style.css:72–77, editor-render.js:33; `git log -- ui/live.css` | `.pcard.context{opacity:.45;border-left:2px dashed var(--thread)}`, `.tchip` with inline background thread colour + `inkFor` ink, `.elsewhere{color:var(--dimmer)}`; live.css last changed in the Stretch commit 6891453 (before T4) | yes |
| T4-03 | 5 | headless step 5 on a fresh :7795 at 1280 and 390 | "Pathways from here" list: 1 normal card (Rapper's Delight), 1 `.pcard.context` chip exactly "Good Times bassline · context", 0 `.elsewhere`; after `+ add to graph` 2 normal, 0 context; 390: same counts, scrollWidth ≤ 390, 0 console errors | yes |
| T4-03 | 6 | `node --test tests/editor-render.test.ts`; smoke; check | renderer extracted (ui/editor-render.js), 18/18 pass; smoke 4/4; check green 214 | yes |
| T4-04 | 1 | Hip-hop Web tab on Good Times; read SVG; `/api/tracks/<GT>` in; other songs for the caption | context line `stroke=#f59e0b stroke-dasharray="6 4" opacity=".45"`; `g.node.context` circle fill none, stroke #f59e0b, dasharray "4 3"; no elsewhere drawn; caption "← 1 elsewhere" on Rapper's Delight (Hip-hop), "← 2 elsewhere" on Voyager (Saturday disco); in-edges from Voyager and Le Freak (outside) not drawn | yes |
| T4-04 | 2 | Everything, Web, Voyager centred | 6 `g.node`, 6 `line`, no caption, 0 errors | yes |
| T4-04 | 3 | click the context node, then its Track view | re-centred on Another One Bites the Dust (2 nodes, 1 line), caption "Not in this graph, so its pathways are hidden · + add to graph"; Track view: "No pathways from here in this graph." + the same line (D30), 1 incoming card ← Good Times; 0 errors | yes |
| T4-04 | 4 | headless step 4 on a fresh :7795 at 1280 and 390 | 3 `g.node` (Rapper's Delight, `node context` Another One Bites the Dust, Good Times); 2 lines, 1 dashed (#f59e0b, 6 4, .45); 390 same counts, no h-scroll, 0 errors; `$HARNESS_SCRATCH/web-context-1280.png` written | yes |
| T4-04 | 5 | smoke; check | 4/4; green 214 | yes |
| T4-05 | 1 | Threads tab on :7796; read editor-render.js `threadRow` | tab label set from `cap(words.threads)`; `#view-threads`; rows "French touch filter family 3 songs · in: Saturday disco" (swatch rgb(56,189,248)), "Good Times bassline 4 songs · in: Saturday disco" (rgb(245,158,11)); motif rendered by `threadRow` when set (fixture threads have none) | yes |
| T4-05 | 2 | create form; duplicate 'Good Times bassline'; create 'Test thread' | colour `type=color` default #22d3cf (PALETTE[2]); duplicate → toast `a thread named "Good Times bassline" already exists` (server 400); create POSTs /api/threads {name, motif, color} and opens its page | yes |
| T4-05 | 3 | thread page, every request captured | ↑/↓ → `PUT /api/threads/:id/order` with all 4 ids; ✕ → `DELETE /api/threads/:id/tracks/<LeFreak>`; + Add song → picker → `POST /api/tracks {"title":"Voyager"}` (upsert, still 9 tracks) → `POST /api/threads/:id/tracks`, row appears; "Pathways in this thread (4)" with 4 cards; name/motif/colour each PATCH, confirmed by GET; Delete thread → confirm "…Its songs and pathways stay." → DELETE; tracks 9 → 9 | yes |
| T4-05 | 4 | headless step 4 on a fresh :7796 at 1280 and 390 | "Good Times bassline 4 songs · in: Saturday disco"; rows Good Times, Rapper's Delight, Another One Bites the Dust, Le Freak; 4 pathway cards; ↓ Good Times → UI and API Rapper's Delight, Good Times, …; ✕ Le Freak → 3 rows, GET /api/tracks 9; 390 no h-scroll, 0 errors; threads-{1280,390}.png in scratch | yes |
| T4-05 | 5 | smoke; check | 4/4; green 214 | yes |
| T4-06 | 1 | Graphs tab, create/rename/delete 'Test graph', checkboxes, own songs, Everything page | rows Everything 9 songs · 15 pathways, Hip-hop block party 2 songs · 1 pathway, Saturday disco 7 · 11; POST /api/graphs; PATCH rename (GET confirms); checkbox → `PUT …/threads {"thread_ids":[GT]}` then `[GT,FT]`; own songs + Add song (POST /api/tracks → POST /api/graphs/:id/tracks), ↓ PUT order, ✕ DELETE; Delete graph → confirm → DELETE, tracks 9, threads 2; Everything page "Everything holds every song and pathway and cannot be edited." with 0 buttons/inputs/selects | yes |
| T4-06 | 2 | `/?graph=<Saturday disco>`, + New track "Brand New Song by Some Artist" | `POST /api/tracks` then `POST /api/graphs/<disco>/tracks`; aside 7 → 8 rows at once; song in own_songs | yes |
| T4-06 | 3 | Select: Le Freak, Voyager, Good Times; click Voyager again; Make thread 'Chic family' | badges 1/2/3 in click order; unticking renumbers; `Make thread (n)` follows the count; prompt "Name for the new thread:"; `POST /api/threads {"name":"Chic family","track_ids":[click order],…}`; Threads tab opens on it; label back to Select, badges gone | yes |
| T4-06 | 4 | headless step 4 on a fresh :7796 at 1280 and 390 | list counts exact; tick Good Times bassline → GET 4 songs / 4 pathways; untick → 2 / 1; Everything 0 controls; Chic family songs Le Freak, Voyager, Good Times; 390 no h-scroll on list, graph page, Everything, selection; 0 errors; graphs-{1280,390}.png in scratch | yes |
| T4-06 | 5 | smoke; check; `node .harness/flows.mjs` | 4/4; green 214; flows 7/7 PASS | yes |
| T4-07 | 1 | `bash docs/demo/threads-399.sh http://localhost:7797` on an empty DB; read API and the script; `strings 399.session` | exit 0; 8 songs with the session's raw titles/artists; 7 pathways: vibe, vibe, bass, vibe, vibe, vocal, bass with short notes; Tea-tent Latin jazz #22d3cf = Woman, Rico Suave, Leroy's, Samba Cantina; Night closers #e879f9 = Woman, All Night Long; Sunday tea tent own = Woman, What's Going On, Coffy, All Night Long; Soul hour own = Woman, What's Going On, Coffy, Glide; 0 threads each; curl + `node -e`, the only "jq" is the "no jq" comment | yes |
| T4-07 | 2 | ran it a second time | exit 0; 0 "created" lines, 19 lines all "exists"; ends with both graph ids and the two `/live?graph=<id>` URLs | yes |
| T4-07 | 3 | read tests/demo-seed.test.ts; `node --test` it | asserts stats 8/7, 2 threads, 3 graphs after two runs; snapshot(tea): current Woman of the World exact, out [All Night Long], cued_edge_id = out[0], context [[Rico Suave, Tea-tent Latin jazz]], elsewhere 1; snapshot(soul): out [Glide], context [[All Night Long, Night closers],[Rico Suave, Tea-tent Latin jazz]], elsewhere 0, cued = Woman→All Night Long = context[0]; 2/2 pass | yes |
| T4-07 | 4 | read .harness/init.sh:27–30; the harness's init output; `GET :7791/api/graphs`; seed.log tail | runs the seed after the stats wait, prints "seed: ok" (tail on failure); init output "seed: ok"; graphs Everything, Soul hour, Sunday tea tent | yes |
| T4-07 | 5 | read README.md:83–86 | Threads demo lines: run the seed, it prints the two `/live?graph=<id>` URLs, editor `/?graph=` | yes |
| T4-07 | 6 | `git show --stat a2bdf71`; check | tests/demo-seed.test.ts adds 2 tests (209 → 211); check green 214 | yes |
| T4-08 | 1 | Playwright on :7791 at 1280 and 390: `/`, `/?graph=<tea>` Track view of Woman of the World, Threads tab, Tea-tent Latin jazz page, Graphs tab | all 10: 0 console errors (art 404s ignored), scrollWidth = innerWidth | yes |
| T4-08 | 2 | `ls docs/screenshots/editor-*`; opened all 10 | all 10 exist. **editor-context-390.png shows only the header, aside and song card: no All Night Long card, no dimmed Rico Suave, no "Tea-tent Latin jazz · context" chip, no "← 1 elsewhere".** context-1280 shows all of it; thread-page-390 is cut after song 2; all 10 still show the pre-T4-09 tagline "Phase 1 · graph + notes importer + editor" (live UI now: "Songs, pathways, threads and graphs") | **no** |
| T4-08 | 3 | fresh DB, import sample, serve :7792, seed, restart `--replay 399.session --speed 0 --graph 'Sunday tea tent'`; GET /api/sets, /api/sets/replay-399, /api/live?graph=, /api/tracks/<id>?graph= per play | log "Recording into graph: Sunday tea tent"; replay-399: 7 plays, 7 exact, all stamped Sunday tea tent; live current Woman of the World, other All Night Long d2, cued Woman→All Night Long, elsewhere 1 | yes |
| T4-08 | 4 | rebuilt the 7-row table; compared with the T4-08 entry row by row | all 7 rows match (times, decks, raw titles, exact, graph, cards out/context/elsewhere, cued, via pairs; via ids differ per DB). Last row 18:24:00 · d1 · current · Woman of the World — Donald Byrd · exact · Sunday tea tent · 1 / 1 (Tea-tent Latin jazz) / 1 · cued yes (in graph). 18:24:00 vs the expected 18:23:55: the play row stores the event time (`src/live.ts:50`, `iso(ev.at)`), the snapshot the Serato load time (`started_at` 1791757435 = 18:23:55). The entry discloses this; it is pre-T4 behaviour | yes |
| T4-08 | 5 | read the T4-08 entry | "Proposed changes": old tagline; context cards two screens down at 390; two chips on context cards; Review pill global; none fixed in T4-08 | yes |
| T4-08 | 6 | check | green 214 | yes |
| T4-09 | 1 | `ls -l $HARNESS_SCRATCH/t4.diff`; read the T4-09 entry | t4.diff 116,911 B (13:18); entry lists Opus findings 1–12: no Critical, Important 1–4 (D25 names, Live link, editor/Live outside songs, Live Add pathway), Minor 5–12 | yes |
| T4-09 | 2 | read §12 D30; `grep in_graph/outsideText`; `node .harness/flows.mjs`; README:116–117, 126–127 + `GET /api/live?graph=<name>`; T4-08 proposals vs the live UI | D30 *default* at design:391; editor (`outsideLine`, app.js:244) and Live (`renderCards`, live-render.js:124) both use `outsideText()` from the server's `in_graph`; flows 7/7 PASS (D25 name, Live link, D29 Live and editor, D30, Select order, deleted graph); README now says Live draws only in-graph cards until T5, matching the API (tea: out All Night Long, context Rico, elsewhere 1; Soul: out Glide, cue in context); proposals: tagline fixed (live UI shows the new one), aside capped, chips rebutted, Review count titled; 6, 9, 12 left with reasons | yes |
| T4-09 | 3 | `grep` app.js, style.css; read the entry | `joinGraph`/`bindRows`/`bindCreate`/`pageFailed` used 13× in app.js; `esc` imported from live-render (app.js:5); one base `.sw` rule (style.css:101); entry names reuse, simplification, altitude, efficiency (seed) | yes |
| T4-09 | 4 | read README "Threads and graphs" | switcher, Threads tab, Graphs tab, Make thread from songs, D30, seed command, `/live?graph=Sunday%20tea%20tent` and `/live?graph=Soul%20hour`, `docs/screenshots/editor-*` names | yes |
| T4-09 | 5 | smoke; check | 4/4; green 214 | yes |

### 2026-10-17 13:41 · verify T4 (first pass: written inside the header, so not counted; moved here unchanged)

50 steps re-run (Playwright on a throwaway T1-fixture server :7794, a fresh seed server :7795, a replay server :7796, the init server :7791). All hold. One note: T4-08 last row start 18:24:00 vs expected 18:23:55 (live current says 18:23:55, the play row 18:24:00).

| Feature | Step | What you ran or read | What you saw | Holds |
|---|---|---|---|---|
| T4-01 | 1 | `wc -l docs/plans/2026-10-16-t4-editor.md`; read header | 129 lines (<250); line 11 'Written with: superpowers:writing-plans' | yes |
| T4-01 | 2 | read the words.js section + grep | words.js object, plural, cap, words.d.ts and the strings to switch (live-render, live.html/js, index.html, app.js) are specified | yes |
| T4-01 | 3 | grep graphSwitch / pathways.graph / `GET /api/tracks/:id?graph` | switcher spec (Everything first, ?graph=, localStorage key, aside list, Track/Web fetch) present | yes |
| T4-01 | 4 | grep context/tchip/elsewhere/dashed | `.pcard.context` opacity/dashed border, tchip, '+ add to graph' POST, '← N elsewhere', Web dashed context all specified | yes |
| T4-01 | 5 | read Tasks 4–5 + Shared interfaces | Threads tab, Graphs tab, Select mode with numbered ticks → POST /api/threads, + New track into the active graph all specified | yes |
| T4-01 | 6 | grep threads-399; read Task 7 | demo seed (T4-07) and headless/screenshot names (T4-08) specified | yes |
| T4-01 | 7 | `git show --stat 8302516` | plan + spec edit under docs/, plus harness bookkeeping (feature_list/progress) only; check green 214 | yes |
| T4-02 | 1 | `node --test tests/words.test.ts`; read ui/words.js, words.d.ts | 2/2 pass; asserts plural(1,…)==='pathway', plural(3,…)==='pathways', keys = the 13 words; .d.ts matches | yes |
| T4-02 | 2 | `node --test tests/live-render.test.ts` (with 3 other files, 31/31 pass); grep ui/live-render.js | imports ./words.js; chip/empty states use words.*; test unchanged and green | yes |
| T4-02 | 3 | read ui/live.js:7, grep app.js | live.js sets outHead = cap(words.pathways)+' from this track'; app.js 'pathway' hits are import, words.* uses, comments, localStorage key | yes |
| T4-02 | 4 | the step's grep over ui/*.js | only comments, localStorage key 'pathways.graph' and words.* lines; no hard-coded on-screen use | yes |
| T4-02 | 5 | `node .harness/smoke.mjs` | PASS editor/live @1280/@390 (4/4) | yes |
| T4-02 | 6 | `.harness/../lib/check.sh` | green, 214 tests | yes |
| T4-03 | 1 | Playwright on fixture server (T1 fixture, :7794): options, selectOption, URL/ls, stored 'zzz' | options Everything, Hip-hop block party, Saturday disco; select → ?graph=<id> + localStorage; ?graph= wins over stored; stored 'zzz' → value 'default', 0 console errors | yes |
| T4-03 | 2 | /?graph=<Hip-hop> aside + pill; /?graph=default | aside = Good Times, Rapper's Delight; pill '2 songs · 1 pathway · Hip-hop block party'; Everything lists 9, pill as before | yes |
| T4-03 | 3 | Good Times in Hip-hop: computed style, chip, tap, '+ add to graph' | context card opacity .45, dashed left border, style `--thread:#f59e0b`, note display none until tap → class 'open'; chip text; add POSTed (graph 2→3 songs) | yes |
| T4-03 | 4 | read ui/style.css, `git log -- ui/live.css` | `.pcard.context`, `.tchip`, `.elsewhere` present; live.css unchanged since before T4 | yes |
| T4-03 | 5 | headless T4-03 step 5 at 1280 and 390 | 1 normal out card (Rapper's Delight), 1 .pcard.context with .tchip 'Good Times bassline · context', 0 .elsewhere; after add 2 normal out cards (+1 incoming card); 390 scrollWidth ok, 0 errors | yes |
| T4-03 | 6 | smoke + check; tests/editor-render.test.ts (18 tests) | smoke 4/4, check green 214 | yes |
| T4-04 | 1 | Web tab on Good Times in Hip-hop; read g.node.context markup | context node has inner circle fill=none, stroke #f59e0b, dasharray 4 3; context line dasharray '6 4' opacity .45; no elsewhere drawn; web '← 1 elsewhere' caption seen on Woman of the World (Sunday tea tent) | yes |
| T4-04 | 2 | Voyager in Everything, Web tab | 6 g.node, 6 line | yes |
| T4-04 | 3 | click context node, open its Track view | re-centred on Another One Bites the Dust; its Track view for the same graph says 'No pathways from here in this graph. Not in this graph…'; 0 errors | yes |
| T4-04 | 4 | headless Good Times in Hip-hop, Web | 3 g.node, 1 `node context` 'Another One Bites the Dust — Queen', 2 lines of which 1 dashed; 390 no h-scroll, 0 errors; web-context-1280.png written | yes |
| T4-04 | 5 | smoke + check | 4/4; green 214 | yes |
| T4-05 | 1 | Threads tab on fixture server | rows 'French touch filter family 3 songs · in: Saturday disco', 'Good Times bassline 4 songs · in: Saturday disco'; 2 swatches | yes |
| T4-05 | 2 | create duplicate name; colour input | toast: a thread named "Good Times bassline" already exists; colour input type=color default #22d3cf; creating 'Disco <i>edits</i>' opened a page (delete button usable), no `<i>` element | yes |
| T4-05 | 3 | thread page: buttons present, delete | ↑↓✕ per row, #threadAdd, #threadDel, name/motif/colour inputs, pathways list; Delete thread removed the thread only (tracks 9 → 9). '+ Add song' picker flow not clicked here; covered by T4-06 picker run on the graph page (+ New track) and flows.mjs | yes |
| T4-05 | 4 | headless step 4 at 1280/390 | 4 rows in order Good Times, Rapper's Delight, Another One…, Le Freak; 4 pathway cards; ↓ on Good Times → API order Rapper's Delight, Good Times, …; ✕ Le Freak → 3 rows, tracks 9; ↑ disabled row 1, ↓ disabled last; 390 ok; threads-{1280,390}.png written | yes |
| T4-05 | 5 | smoke + check | 4/4; green 214 | yes |
| T4-06 | 1 | Graphs tab; Everything page; Hip-hop page | rows Everything 9 songs · 15 pathways, Hip-hop block party 2 · 1, Saturday disco 7 · 11; Everything page text 'Everything holds every song and pathway and cannot be edited.' with 0 controls; hip page has rename, checkboxes, own songs ↑↓✕, + Add song, Delete graph; rename PATCH verified via API | yes |
| T4-06 | 2 | + New track 'Thinking of You by Sister Sledge' in Saturday disco | appeared in aside at once; pill 7→8 songs; API graph songs 8 | yes |
| T4-06 | 3 | Select mode: Le Freak, Voyager, Good Times; Make thread 'Chic family' | badges 1/2/3 in click order; button 'Make thread (3)'; Threads tab opened on the new thread; API songs Le Freak, Voyager, Good Times; label back to Select | yes |
| T4-06 | 4 | headless step 4 at 1280/390 | tick Good Times bassline → 4 songs/4 pathways; untick → 2/1; Everything page 0 controls; selection ok; 390 no h-scroll, 0 errors; graphs-{1280,390}.png written | yes |
| T4-06 | 5 | smoke + check; `node .harness/flows.mjs` | 4/4; green 214; flows 7/7 PASS (deleted-graph, Select order) | yes |
| T4-07 | 1 | ran `bash docs/demo/threads-399.sh http://localhost:7795` on a fresh DB, then read API | 8 songs with exact raw titles, 7 pathways (types vibe/vibe/bass/vibe/vibe/vocal/bass with notes), threads Tea-tent Latin jazz #22d3cf (4 songs) and Night closers #e879f9 (2), graphs Sunday tea tent / Soul hour with the 4 own songs each and no threads; curl+node only, no jq | yes |
| T4-07 | 2 | ran it a second time | exit 0; every line 'exists'; tracks 17, edges 22 (9+8, 15+7); ends with both ids and two /live?graph= URLs | yes |
| T4-07 | 3 | read tests/demo-seed.test.ts:30-61; ran it (in the 31/31 batch) | asserts 8/7/2/3, created/exists counts on 2nd run, snapshot(tea): current exact, out [All Night Long] cued, context [Rico + Tea-tent Latin jazz], elsewhere 1; snapshot(soul): out [Glide], context 2, elsewhere 0, cued = context edge; passes | yes |
| T4-07 | 4 | init output + `GET :7791/api/graphs`; read .harness/init.sh:28-29 | 'seed: ok'; graphs Everything, Soul hour, Sunday tea tent | yes |
| T4-07 | 5 | read README.md:83-86, 119-127 | Threads demo paragraph + run/open commands for both /live?graph= URLs | yes |
| T4-07 | 6 | test files | demo-seed.test.ts adds 2 tests; check green 214 | yes |
| T4-08 | 1 | Playwright on :7791 for / , /?graph=<tea>, Threads tab, Tea-tent thread page, Graphs tab at 1280 and 390 | 0 console errors (excluding art 404), scrollWidth ≤ viewport on all five at both widths | yes |
| T4-08 | 2 | `ls -l docs/screenshots/editor-*`; viewed the data | all 10 files exist (switcher, threads, thread-page, graphs, context × 1280/390); live Track view of Woman of the World shows All Night Long full, Rico Suave dimmed with 'Tea-tent Latin jazz · context', '← 1 elsewhere' | yes |
| T4-08 | 3 | fresh DB, import sample, seed, restart with `--replay 399.session --speed 0 --graph 'Sunday tea tent'` on :7796; GET sets/replay-399, /api/live?graph=, /api/tracks/<id>?graph= | 7 plays; live: current Woman of the World exact, out [All Night Long] cued, context [Tea-tent Latin jazz/Rico Suave], elsewhere 1. (Starting the server with --graph before the seed fails with 'no graph', as the step's order implies) | yes |
| T4-08 | 4 | compared the progress T4-08 table with my reproduction | 7 rows; every row's cards/context/elsewhere/via matches mine (via ids differ per run). Last row start is 18:24:00 not the expected 18:23:55: my run also gives 18:24:00 for the play row (live current is 18:23:55); the entry discloses it | yes |
| T4-08 | 5 | read 'Proposed changes' in the T4-08 entry | four items listed, not fixed in that session | yes |
| T4-08 | 6 | check | green 214 | yes |
| T4-09 | 1 | `ls t4.diff`; read the T4-09 entry | t4.diff 117 KB in scratch; entry lists Opus findings 1–12 (XSS, localStorage, race, reorder covered by existing checks) | yes |
| T4-09 | 2 | read the entry; ran flows.mjs; read D30 in the spec | Critical/Important fixed (D25 names, Live link, D30, Live Add pathway) and the four T4-08 proposals handled or rebutted; flows 7/7 PASS (first run showed failures only because my own server sat on its port 7794) | yes |
| T4-09 | 3 | grep ui/app.js, style.css; read entry | joinGraph/bindRows/bindCreate/pageFailed exist (13 uses), esc imported from live-render, single `.sw` rule; entry names changes per angle | yes |
| T4-09 | 4 | read README.md:95-132 | 'Threads and graphs' section: switcher, tabs, Make thread, seed command, both /live?graph= URLs, screenshot names | yes |
| T4-09 | 5 | smoke + check | 4/4; green 214 | yes |

### 2026-10-17 14:10 EDT · T4-09 · passes

- **Changed:** D30 *default* in §12: a song outside the graph shows none of its pathways there; `outEdgesIn` and the Live snapshot now carry `in_graph`, and the editor (`outsideLine`) and Live (`renderCards`) show the same `outsideText()` sentence. Live used to say "No pathways from this track yet". The editor accepts graph names in `?graph=` (D25, `pickGraph`). The header **Live** link keeps the active graph. Live's Add pathway in a graph joins both songs (D29 extended, recorded). The README's `/live?graph=` claims are corrected (Live draws only in-graph cards until T5) and the switcher, D30 and demo are described. New `.harness/flows.mjs`: 7 headless flows on its own server. T4-08's proposals: tagline from words.js, aside capped at 45vh ≤820 px (title y=642 at 390), Review count titled "in the whole library". Tests **211 → 214**.
- **Verified:** RED first: 3 new tests failed. `flows.mjs` against the old renderers fails D25 and D30, and all 7 pass on the new code. Sonnet check on :7791: Sunday tea tent by name → its id; 1 context card (Rico Suave), "← 1 elsewhere"; Glide → "Not in this graph…"; `/live?graph=` cued All Night Long; 390 scrollWidth 390, `.library` 298 px. Smoke 4/4; check green 214.
- **Review (Opus, `t4.diff`):** no Critical findings. *Important, fixed:* D25 names (1), Live link drops the graph (2), editor/Live disagree on outside songs (3), Live Add pathway is never satisfied in a graph (4). *Minor, fixed:* `fromCard` `$'` replace (5), a deleted active graph's page now refreshes the switcher (7), `refresh` re-reads the library while searching (8), a DELETE reply no longer closes another page (11), the seed's idempotence limits are documented (10). *Left:* (6) inert cleared by a redraw during a write: rare (needs a pathway retype mid-write). (9) Live's "← N lead here" is global by T3's test; for T5. (12) An unknown `?graph=` falls back quietly, as the plan says.
- **Simplify:** *reuse:* app.js imports `esc` from live-render; `joinGraph`, `bindRows`, `bindCreate`, `pageFailed` are shared by Threads/Graphs; one `.sw` CSS rule. *Simplification:* `pickGraph` is one `find`. *Altitude:* the outside line reads the server's `in_graph`, not a UI recompute. *Efficiency:* the seed still runs ~20 `node -e`; that's fine for a demo.
- **Next (T5):** `renderCards` returns early on `in_graph === false`. Context cards in Live are T5-02. Run `node .harness/flows.mjs` after UI changes.
- **Questions for Michael:** D30: should a song outside the graph show its pathways (as context/elsewhere) instead of hiding them? Is it right that Live's Add pathway joins songs to the graph (D29)?
- **Proposed changes:** T4-08's "context card shows both chips" is kept (the type badge is the pathway's type, and T5-02 specifies the same).
- Log: T4-08 and the verify T1/T3 entries had been written inside this file's header; I moved them below it, unchanged.

### 2026-10-17 · T4-08 · passes
Screenshots only (no code): docs/screenshots/editor-{switcher,threads,thread-page,graphs,context}-{1280,390}.png (switcher = context state, Track view of Woman of the World in Sunday tea tent). Playwright on :7791 (init seed): `/`, `/?graph=<Sunday tea tent>`, Threads, Tea-tent Latin jazz page, Graphs: 0 console errors (art 404s ignored), 0px horizontal scroll at 390. Replay on :7792 (fresh DB, notes sample + threads-399.sh, `--replay 399.session --speed 0 --graph 'Sunday tea tent'`). 211 tests, unchanged.

| start (NY) | deck | status | raw title — artist | match | resolved | graph | in graph / context / elsewhere | cued | via_edge |
|---|---|---|---|---|---|---|---|---|---|
| 15:55:26 | d1 | played | Leroy's Latin Lament… — War | exact | Leroy's Latin Lament | Sunday tea tent | 0 out, 1 in / 0 / 0 | – | none |
| 16:05:38 | d2 | played | Rico Suave Bossa Nova feat. Azymuth — J Dilla | exact | Rico Suave Bossa Nova | Sunday tea tent | 0 out, 1 in / 0 / 0 | – | none |
| 16:10:59 | d1 | played | Woman of the World — Donald Byrd | exact | Woman of the World | Sunday tea tent | 1 out / 1 (Tea-tent Latin jazz: Rico Suave) / 1 | – | none |
| 16:17:28 | d2 | played | What's Going On — Marvin Gaye | exact | What's Going On | Sunday tea tent | 1 out / 0 / 0 | – | none |
| 16:23:26 | d2 | played | Coffy Is The Color — Roy Ayers | exact | Coffy Is The Color | Sunday tea tent | 1 in / 0 / 1 | – | d7ac022b… (pathway) |
| 16:44:27 | d1 | played | Glide — Pleasure | exact | Glide | Sunday tea tent | 2 in / 0 / 0 | – | 13d9b48c… (pathway) |
| 18:24:00 | d1 | current | Woman of the World — Donald Byrd | exact | Woman of the World | Sunday tea tent | 1 out / 1 (Tea-tent Latin jazz) / 1 | yes, All Night Long (in graph; Rico is context, not cued) | none |

Notes: the brief expected last start 18:23:55 and the recorded play says 18:24:00 (live `started_at` 1791757435 is 18:23:55; the play row uses another timestamp). Status column for earlier plays is my label: /api/sets rows have no status, only the live pair does. Rows 1–2 show "0 out" because the graph only has the edges Woman→Rico/ANL.

**Proposed changes**
- Header subtitle still reads "Phase 1 · graph + notes importer + editor".
- At 390 px the track list sits above the track card, so the context cards (the point of the view) are about two screens down.
- Context card shows both "Tea-tent Latin jazz · context" and a "Great match" chip; fine but busy.
- Graph in Everything's Review pill shows 5 in every graph (global count).

### 2026-10-17 12:00 · verify T3

- T3-01 · holds (plan 162 lines, routes/errors/snapshot/recorder/CLI covered)
- T3-02 · holds (live dev server: 404 unknown graph, 400 default edit, 400 bad colour; threads-server tests green)
- T3-03 · holds (/api/live?graph=nope 404, default → Everything/[]/0; live-graph + SSE tests green; ui js untouched)
- T3-04 · holds (serve --graph nope → "no graph: nope", exit 1; cli-threads, live-graph tests green; docs present)
- T3-05 · holds (check green 190, smoke 4/4, review recorded)

### 2026-10-17 11:00 · verify T1

- T1-01 · holds (plan 125 lines, signatures/methods/rules/fixture, D25+D26 present)
- T1-02 · holds (threads.ts type-only import; tests green)
- T1-03 · holds (re-ran fixture: orders, counts, errors, merge, resolve refs all match)
- T1-04 · holds (7 songs/11 pathways, splits, Everything guards, listGraphs, getGraph, deletes all match)
- T1-05 · holds (architecture.md §1a, review/simplify recorded; check green 163, smoke 4/4)

### 2026-10-17 09:20 EDT · T4-07 · passes

- **Changed:** new `docs/demo/threads-399.sh` (bash + curl, `node -e` for JSON, no jq; bash 3.2-safe): the 399 set's 8 songs with their exact raw titles, 7 pathways with notes, threads *Tea-tent Latin jazz* (#22d3cf) and *Night closers* (#e879f9), graphs *Sunday tea tent* and *Soul hour* (own songs only). It prints one `created`/`exists` line per object, then both graph ids and both `/live?graph=` URLs. On an HTTP error it prints the server's `{error}` and exits non-zero. New `tests/demo-seed.test.ts`; `.harness/init.sh` now seeds (`seed: ok`); 3 README lines under the replay demo; `.gitattributes` `*.sh eol=lf`. `ui/style.css`: `.library{min-width:0}`. At 390 px the long *Leroy's Latin Lament…* title widened the aside by 221 px; smoke caught it. Tests **209 → 211**.
- **Verified:** RED first (no such file), then green. Second run: 19 `exists`, 0 `created`, same ids. With the 399 replay, the dev server gives *Sunday tea tent*: Woman of the World (exact), out All Night Long (cued), context Rico Suave (Tea-tent Latin jazz), 1 elsewhere. *Soul hour*: out Glide, context All Night Long (Night closers) + Rico Suave, 0 elsewhere, cue in context. A proxy that fails `POST /api/graphs` with 500 makes the script exit 1 with `POST /api/graphs: {"error":"boom"}`. Init by hand: `seed: ok`, graphs Everything 17/22, Soul hour 4/3, Sunday tea tent 4/2. No 390 px overflow on `/?graph=` or `/live?graph=` for either graph. Smoke 4/4; check green 211/211.
- **Review (Opus, `t4-07.diff`):** no Critical findings. *Fixed:* a graph POST failing inside `$(group …)` still exited 0 (it now sets `$GID`); `curl -sf` hid errors; `declare -A` needs bash 4; JSON quoting; CRLF on Windows checkouts. *Left:* on Windows, `bash` in the test may resolve to WSL; each run starts about 20 short `node -e` processes.
- **Next (T4-08):** init's `dev.db` now holds the notes sample + the 399 seed (17 songs / 22 pathways, 2 threads, 3 graphs); the T1 seed is no longer loaded. Ids are in `$HARNESS_SCRATCH/seed.log`.
- **Questions for Michael:** none new (D27, D28, D29 still open).
- **Proposed changes:** none.

### 2026-10-17 08:30 EDT · T4-06 · passes

- **Changed:** `ui/editor-render.js` + `.d.ts` gain pure `counts`, `graphRow`, `everythingPage` (no controls), `threadChecks`, `toggled`, `tick`. `ui/index.html` adds the Graphs tab, `#view-graphs` and the aside's `#selectMode`/`#makeThread`. `ui/app.js` adds `renderGraphs` (list + `#newGraph`), `renderGraphPage`/`drawGraphPage` (rename, thread checkboxes, own songs ↑↓✕ + Add, Delete graph), selection mode (ticks in click order → `POST /api/threads` → the new thread page), and `+ New track` joins the active graph. The thread page's write code is now shared: `pageWriter`, `bindSongRows`, `refocus`; `refresh({threads})` → `refresh({redraw})`. `ui/style.css`: 7 rules. Tests **204 → 209**.
- **Verified:** RED first (5 missing exports), then green. Headless (Sonnet, port 7791, T1 seed), re-run by me on the final code, A–J all PASS with 0 console errors: list Everything 9 songs · 15 pathways / Hip-hop block party 2 · 1 / Saturday disco 7 · 11; ticking Good Times bassline in Hip-hop gives 4 songs · 4 pathways, unticking gives 2 · 1; Everything page has 0 buttons/inputs; Make thread "Chic family" from Le Freak, Voyager, Good Times → API order Le Freak, Voyager, Good Times; New track Thinking of You in Saturday disco → pill 8 songs at once; deleting the active graph → switcher Everything, 9 songs; 390 px scrollWidth 390. I also checked that clicking an own song opens it and that New track Voyager in Saturday disco adds no own song. Screenshots `$HARNESS_SCRATCH/{graphs,graph-page}-{1280,390}.png`, `select-{1280,390}.png`. Smoke 4/4; check green 209/209.
- **Review (Opus, `t4-06.diff`):** no Critical findings. *Important, fixed:* own-song titles on the graph page weren't clickable; New track made a song that was already in the graph through a thread an own song. *Minor, fixed:* a failed graph join still opens the new track; no double Make thread; a graph switch ends selection mode and deleted tracks leave it; the checkboxes keep the graph's thread order and append new ticks (D24); a new thread's colour comes from the thread count; a write never leaves the page `inert`.
- **Next (T4-07):** `dev.db` holds the T1 seed in its original order. Library search is disabled on the dev server, so picker checks use the free-text row ("Title by Artist", Enter).
- **Questions for Michael:** none new (D27, D28, D29 still open).
- **Proposed changes:** none.

### 2026-10-17 07:20 EDT · T4-05 · passes

- **Changed:** `ui/editor-render.js` + `.d.ts` gain the pure `threadRow`, `songRows` (↑/↓ disabled at the ends, aria-labels name the song), `moved(ids, i, d)` and `colorInput`. `ui/index.html` adds the Threads tab (label from `cap(words.threads)`) and `#view-threads`. `ui/app.js` adds `renderThreads` (list + `#newThread` form, default colour from `PALETTE`), `renderThreadPage`/`drawThreadPage` (rename/motif/colour PATCH on change, ↑↓✕, `+ Add song` through `addSongVia`, pathways through `fromCard`, which Review now shares too, and Delete thread). Each write makes the page `inert`, redraws it from the reply, puts focus back, and then runs `refresh({threads:false})` in the background. `ui/style.css`: `.trow/.srow/.back/.threadhead`, and `.tabs` now wraps, because the extra tab made the header 50 px too wide at 390 (smoke caught it). Tests **200 → 204**.
- **Verified:** I saw the tests fail first (missing exports, then `<span class="sw">` and the aria-labels), then pass. Headless (Sonnet, port 7791, T1 seed), checks A–Q all pass: the Good Times bassline row reads "4 songs · in: Saturday disco"; the page lists Good Times, Rapper's Delight, Another One Bites the Dust, Le Freak with 4 `.pcard`; ↓ on row 1 gives Rapper's Delight first (DOM and API agree); ↓ on row 3 swaps rows 3 and 4; ✕ Le Freak leaves 3 rows and 9 tracks; a duplicate name shows the toast `a thread named "good times bassline" already exists`; `Disco <i>edits</i>` stays literal and `#view-threads i` is null; PATCH motif/name and delete work; scrollWidth is 390 at 390 px; a double click is swallowed while the page is inert, so there is no 400; focus returns to the moved song's ↓; Space and Enter work; an emptied name is refused locally; the colour input is 46 px wide. I added Voyager through the picker myself (5 rows, API agrees, 0 errors), then removed it. Screenshots: `$HARNESS_SCRATCH/threads-{1280,390}.png` and `threads-page-{1280,390}.png`. Console: only the deliberate 400. Smoke 4/4; check green 204/204.
- **Review (Opus, `t4-05.diff`):** no Critical findings. *Important, fixed:* the page redrew only after a full refresh, so a second ↑/↓ used the old list (a 400 or a lost move); the `<i>` swatch broke the plan's XSS check; focus was lost after every action. *Minor, fixed:* Space on rows, a real `<button class="back">`, focusable song titles, an empty name checked locally, motif trimmed on create, no double submit, only "thread not found" falls back to the list, picker adds check that the thread is still open, the colour input has its own label and size, long names wrap. *Minor, left:* the thread page has no URL (a reload shows the list); the `fromCard` "from X →" text wraps tightly at 390 (same as Review).
- **Next (T4-06):** reuse `songRows`/`moved`/`addSongVia` and the `drawThreadPage` write pattern (inert → redraw from reply → background `refresh({threads:false})`) for the graph page. `dev.db` still holds the T1 seed (2 threads, 2 graphs, original order).
- **Questions for Michael:** none new (D27, D28, D29 still open).
- **Proposed changes:** none.

### 2026-10-17 06:15 EDT · T4-04 · passes

- **Changed:** `ui/editor-render.js` + `.d.ts` gain pure `webParts(detail, songIds)` (out targets solid, context targets carry their thread, `in` only from the graph's songs, one node per song) and `outsideLine(id)`. `ui/app.js` `renderWeb()` builds on `webParts`: context lines have the thread colour, `stroke-dasharray="6 4"`, opacity .45 and no arrow; context nodes are `g.node.context` with a `fill="none"` dashed ring; there is a `← N elsewhere` caption, a legend ring per context thread, and a `<title>` with the full name on every node. Both views show "Not in this graph, so its pathways are hidden · + add to graph" when the open song is outside the graph (shared `bindInclude`). `ui/style.css`: 3 rules. Tests **197 → 200**.
- **Verified:** RED first (`webParts` and then `outsideLine` missing), then green. In Everything, Voyager had 6 nodes / 6 lines before and after (my own Playwright count, 0 errors). Headless (Sonnet, port 7791, T1 seed), 0 page/console errors: Hip-hop block party, Good Times, Web → 3 `g.node`, 1 `.context` (title "Another One Bites the Dust — Queen"), 2 lines, 1 dashed at .45 with no marker. Voyager in Saturday disco shows "← 2 elsewhere" with 4 nodes / 4 lines, which matches the API. Clicking the context node centres AOBTD, and the outside line appears in Web and Track. Its button adds the song: the graph has 3 songs (I checked with curl) and the pill reads "3 songs · 3 pathways". At 390 px the scrollWidth is 390. Screenshot `$HARNESS_SCRATCH/web-context-1280.png`. Smoke 4/4; check green 200/200.
- **Review (Opus, `t4-04.diff`):** no Critical findings. *Important, fixed:* re-centring on a context node opens a song outside the graph, where D23 drops all its pathways out, so it looked empty. Both views now show the outside line. *Minor, fixed:* the caption explains dashed lines; the legend shows the thread; `node(n)` takes `webParts`' objects; `.d.ts` types `nodes[].t` as `E["to"]` and `WebThread` is shared with `contextCard`. *Minor, left:* the line and ring attribute strings stay in app.js, so they have no unit test (they are checked headless); a context line's hover title shows the note, while the Track view hides the note until tapped.
- **Next (T4-05):** I re-ran init, so `dev.db` is clean (9 songs, no threads); seed with `$HARNESS_SCRATCH/seed-t1.mjs`. `bindInclude(root)` is now shared. Reuse it for any "+ add to graph".
- **Questions for Michael:** should a song outside the active graph show its pathways out as elsewhere, so the count is non-zero? Today the server's `splitOut` drops them all, and the UI only says "Not in this graph". D27, D28 and D29 are still open.
- **Proposed changes:** none.

### 2026-10-17 05:30 EDT · T4-03 · passes

- **Changed:** new `ui/editor-render.js` + `.d.ts` (pure: `pickGraph`, `graphPill`, `contextCard`, `elsewhereLine`) and `tests/editor-render.test.ts` (+5). `ui/index.html` gains `<select id="graphSwitch">`; `ui/app.js`: `loadGraphs`/`setGraph`/`keepGraph` (`?graph=` + localStorage `pathways.graph` in try; URL wins; unlisted → Everything), `loadAside` replaces `loadTracks` (graph songs, searched client-side), `trackUrl` (always `?graph=`), context cards + `← N elsewhere`, "into here" only from songs in the graph, `state.seq` race guard, `recover()` (a graph deleted elsewhere → Everything). `ui/style.css`: switcher, `.pcard.context`, `.tchip`, `.elsewhere`; `ui/live.css` untouched. Tests **192 → 197**.
- **Verified:** RED first (cannot find `ui/editor-render.js`), then green. Headless (Sonnet, port 7791, fresh init + T1 seed `/tmp/harness/pathways/threads-2026-10-17/seed-t1.mjs`), all PASS, 0 pageerrors: `/?graph=<Hip-hop>` → options Everything / Hip-hop block party / Saturday disco, pill "2 songs · 1 pathway · Hip-hop block party", aside 2 songs; Good Times → 1 normal card (Rapper's Delight), 1 `.pcard.context` (Another One Bites the Dust, chip "Good Times bassline · context", opacity 0.45, note shown only after tap), no `.elsewhere`; "+ add to graph" → 2 normal cards, 0 context, pill "3 songs · 3 pathways" (AOBTD → Good Times joins too). Stored "zzz" → Everything, 9 songs; `?graph=` beats a stored Saturday disco; a Saturday disco → Everything double switch shows Good Times without context; `#<Voyager>` in Hip-hop opens with no active row; 390 px scrollWidth 390. Smoke 4/4; check green 197/197.
- **Review (Opus, `t4-03.diff`):** no Critical findings. *Important, fixed* (re-checked headless as J/K): `refresh()` wrote a stale `state.detail` before its seq check; a graph deleted in another tab gave unhandled 404 rejections (now `recover()`: J: DELETE Saturday disco, click Voyager → switcher Everything, 9 songs, only the 404 fetch log); D29 missed the open song being outside the graph (K: Voyager → Le Freak in Hip-hop adds both). *Minor, fixed:* `setGraph` bumps seq; the aside has its own search seq; `keepGraph` keeps other query params (L); a search no longer refetches the library. *Minor, left:* a null thread colour is `#66718a` (the value of `--dimmer`, since `inkFor` needs hex).
- **Next (T4-04):** `state.detail` already has `out`/`context`/`elsewhere_count`, and `state.songIds` is null in Everything. Filter `in` by `state.songIds` the way `renderTrack` does. The dev DB now holds headless leftovers, so re-run init.
- **Questions for Michael:** D29 now also adds the open song when it is outside the graph (I wrote it into §12 D29). OK? D27, D28 and D29 are still open.
- **Proposed changes:** none.

### 2026-10-17 04:30 EDT · T4-02 · passes

- **Changed:** new `ui/words.js` (`words`, `plural`, `cap`), `ui/words.d.ts`, `tests/words.test.ts` (+2). `ui/live-render.js` (imports `./words.js`: hero chip, the 3 empty states, hint, "Add pathway", "Not in your graph yet."), `ui/live.html` + `ui/live.js` (`#outHead` set from words), `ui/app.js` is now an ES module (`type="module"`): it imports words and gets `openPicker`/`parseFreeText` straight from `/picker.js` (the inline `window.*` module in index.html is gone), and every pathway/song noun in its stats, headings, toasts, confirms, titles, Review/Web/import texts comes from words. `docs/api.md` lists `/words.js`. Tests **190 → 192**. `tests/live-render.test.ts` is not edited.
- **Verified:** RED first (cannot find `ui/words.js`), then green. The feature grep returns only `words.*` uses and 2 comments. Smoke 4/4. Headless (Sonnet, port 7791), all PASS with 0 console errors: `#stats` "9 tracks · 15 pathways · 1 saved labels"; Good Times shows 2 out cards; adding "Test Song" gives the toasts "Pathway added" then "That pathway already exists"; delete via "Delete pathway" + confirm, then the track via the API (count back to 9, I checked with curl); the `#newTrack` picker opens and closes with Esc; Web shows 5 nodes; Review shows "Untyped / ambiguous pathways (5)"; Live `#outHead` = "Pathways from this track" at 1280 and 390; no horizontal scroll at 390. `npm run check` green 192/192.
- **Review (Opus, `t4-02.diff`):** no Critical or Important findings, and all rendered strings are unchanged. *Minor, left:* with a static import, a failed `/picker.js` load now stops the whole editor (before, only "+ New track" failed with a toast). The plan chose this. Static prose in `ui/index.html` (the Import help: "song", "pathways"; the tagline "graph") and the old "track"/"Edges" copy stay hard-coded (D28, and HTML can't import).
- **Next (T4-03):** import `safeColor`/`inkFor` from `/live-render.js` in app.js, which works now that it is a module. Use `words.song(s)` for new copy.
- **Questions for Michael:** none new (D27, D28, D29 still open).
- **Proposed changes:** for the Q8 rename, set the Import help paragraph and the header tagline in `ui/index.html` from words (give them ids, as `#outHead` has).

### 2026-10-17 03:54 EDT · T4-01 · passes

- **Changed:** new `docs/plans/2026-10-16-t4-editor.md` (129 lines, written with superpowers:writing-plans). Task 1–8 = T4-02…T4-09. Design §12 gains D28 and D29. No code changed. Tests **190 → 190**.
- **Plan in short:** `ui/words.js` (words + `plural` + `cap`, `.d.ts`; the exact strings that switch in live-render.js/live.html/live.js/app.js). `app.js` becomes an ES module and imports words, `safeColor`/`inkFor` and the picker directly. One fetch path: `GET /api/tracks/:id?graph=` always. Shared names: `state.graph/songs/songIds/seq/thread/graphPage/picking`, `loadGraphs`, `setGraph`, `loadAside`, `songRows`/`bindSongRows`/`moved`, `addSongVia`, `fromCard`. CSS classes and DOM ids are pinned. Review Focus: XSS via names, the switch-while-loading race, a deleted/stored/throwing graph id, reorder at the ends, opening a song outside the graph. Each one has a headless check in the task that owns it.
- **Verified:** grepped the plan for each item the feature steps require (graphSwitch, `pathways.graph`, the `.pcard.context` rule, tchip/open/elsewhere, `track_ids:[to_id]`, stroke-dasharray, `PUT …/order`, Select/tick/Make thread, `#newTrack`, threads-399.sh, the 10 screenshot names, "cannot be edited"): all present. `git status` shows only docs/ changed. `npm run check` green 190/190; smoke 4/4.
- **Next (T4-02):** the switch of app.js to a module must keep smoke 4/4. Headless checks re-run `.harness/init.sh` first (fresh dev.db, 9 songs). After T4-07 the seed adds 8 songs.
- **Questions for Michael:** **D28**: should the editor's old "track" copy ("+ New track", "Search tracks…") become "song" now, or wait for the Q8 rename? (Default: wait.) **D29**: in a graph, should adding a pathway also add its target song to the graph? (Default: yes, otherwise the new pathway only shows as "← 1 elsewhere".) D27 is still open.
- **Proposed changes:** T4-03 could gain a step for D29 (the plan puts it in Task 2, Step 4).

### 2026-10-17 04:45 EDT · T3-05 · passes

- **Changed:** `src/graph.ts` (plays INSERT stores `(SELECT id FROM graphs WHERE id = ?)`; a non-string name → "a thread/graph needs a name"; `outEdgesIn('default')` shortcut), `src/live.ts` (`refresh` pushes even with nothing shown; `setManual`/`follow(graphId)`), `src/server.ts` (non-object body → 400 `body must be a JSON object`; extra path segments → 404 no route; `texts()`: motif/notes/color must be string or null; `graphRef` unexported), `src/cli.ts` (refactors only), `docs/api.md`. +4 tests in `tests/live-graph.test.ts` / `tests/threads-server.test.ts`. Tests **186 → 190**.
- **Review (Opus, `t3.diff` = `343dc25..HEAD`, 1357 lines):** **Critical**: when the `serve --graph` graph was deleted while the server ran, every later play hit a FOREIGN KEY failure and the view froze → **fixed** RED→GREEN (it now records null). *Minor, fixed* RED→GREEN: a deleted graph's SSE stream stayed open while nothing was shown; `POST /api/threads {}` and `motif:{}` returned internal messages; a `null` body gave a 500; `DELETE /api/tracks/:id/art` deleted the whole track (an old bug); docs (PUT bodies, `bad set id`). *Minor, left*: under `/api/live`, `?graph=zzz` returns 404 "graph not found" before "no route". No Important findings. A second Opus pass on the fix diff found only docs wording (fixed).
- **Simplify:** *reuse*: `song()` replaces 6 hand-written title — artist strings in cli.ts. *Quality*: `n` → `plural` (a loop variable shadowed it), `printSongsAndPathways` shared by `threads show`/`graphs show`, `graphRef` unexported, a redundant type annotation dropped. *Efficiency*: tap/follow build one snapshot instead of two; Everything skips the members/threads queries. *Altitude*: that shortcut lives in `Graph`; nothing else moved.
- **Verified:** RED first (7 failing, 3 of them a cascade from the art-route bug deleting Voyager). Reverting each Live fix turns a test red. Each of the 17 Threads/Graphs routes in docs/api.md is exercised by a call in `tests/threads-server.test.ts` (grep tally), so there is no gap. After an init restart: smoke 4/4, `npm run check` green 190/190.
- **Next (T4):** `POST /api/live/now?graph=` replies for that graph via `setManual(input, graphId)`.
- **Questions for Michael:** none new (D27 still open).
- **Proposed changes:** none.

### 2026-10-17 04:10 EDT · T3-04 · passes

- **Changed:** `src/graph.ts`: `PlayRow` gets `graph_id`/`via_edge_id`, and `recordPlay` derives `via_edge_id` (the oldest pathway previous → this; previous = the play just before it in set order, same source + session_ref). `src/live.ts`: `new LiveState(g, {graphId})` stamps `graph_id`. `src/cli.ts`: `serve --graph <ref>` (`error: no graph: nope` and exit 1 before listening; a bare `--graph` gives `usage: --graph <id|name>`; banner `Recording into graph: <name>`), `threads list|show`, `graphs list|show`, and HELP, all in the plan's exact format. `docs/api.md`: Threads + Graphs sections, `?graph=` on tracks, Play `graph_id`/`via_edge_id`. New `tests/cli-threads.test.ts` (4, spawns `bin/pathways`) and +5 recorder tests in `tests/live-graph.test.ts`; `threadsFixture(dbPath)`. Tests **177 → 186**.
- **Verified:** RED first (7 failing), then green. Good Times → Rapper's Delight in Hip-hop block party gives that edge plus Hip-hop's id; Good Times → Summer Madness gives null. Without a graph, `graph_id` is null and via is still filled. `threads show "good times BASSLINE"` and `graphs list`/`show "Hip-hop block party"` deep-equal the plan output. A spawned `serve --graph "hip-hop BLOCK party" --replay 399.session --speed 0` stamps all 7 plays with Hip-hop's id. Two mutations (drop `graphId` in serve, drop the bare-flag guard) each turned a test red. I scripted a check of every docs claim against Graph. After restarting init: smoke 4/4, `npm run check` green 186/186.
- **Review (Opus, `t3-04.diff`):** no Critical. *Important*: "previous" was the last play *stored*, not the one before in set order, and replay `at` comes from each row's `updated_at`, so it can go backwards → **fixed** RED→GREEN (`started_at <= ?`). *Minor, fixed*: a bare `--graph` meant the graph "true"; the docs had empty `?graph=` on tracks wrong; the `--graph` success path had no test. *Minor, left*: a play stored out of order doesn't recompute the via of the play after it; `NewPlay.graph_id` is optional (so the old callers compile).
- **Next (T3-05):** diff base for the T3 review is `977f444` (or the plan's `343dc25`). The 399 set has 0 matched songs on the dev seed, so `via_edge_id` stays null there.
- **Questions for Michael:** none new (D27 still open).
- **Proposed changes:** none.

### 2026-10-17 03:45 EDT · T3-03 · passes

- **Changed:** `src/live.ts`: `snapshot(graphId = "default")` adds `graph:{id,name}`, `out`/`context`/`elsewhere_count` from `outEdgesIn`, and `cued_edge_id` searched in out, then context. Subscribers are bare callbacks now. `src/server.ts`: each SSE stream resolves `?graph=` before `writeHead` (404 JSON), pushes `live.snapshot(id)` for its own graph and ends when the graph is deleted. `GET /api/live` and also `POST`/`DELETE /api/live/now` reply for `?graph=`. Also changed: `docs/api.md` (D17 line, LiveSnapshot, SSE), the `ui/live-render.d.ts` comment, new `tests/live-graph.test.ts` (4), +2 SSE tests in `tests/threads-server.test.ts`, `tests/live-server.test.ts` now expects `?graph=anything` → 404, and `live`/`live-view` subscribers call `snapshot()` themselves. Tests **171 → 177**.
- **Verified:** RED first (6 failing), then green. Hip-hop from Good Times with Another One Bites the Dust loaded: out [Rapper's Delight], context [AOBTD · Good Times bassline #f59e0b], elsewhere 0, cued = the context edge. Everything: out 2, context [], cued in out. Saturday disco from Voyager: 3 out / 2 elsewhere. Two streams (Hip-hop, default) after tapping Good Times give 1/1 and 2/0. Three mutations each turned a test red: cued out-only, SSE ignores the graph, no end on delete. The SSE tests have a 5 s timeout so a regression fails instead of hanging. `ui/live.js` and `live-render.js` are untouched. Init restarted on :7791, smoke 4/4, curl `/api/live` → graph Everything, `?graph=nope` → 404. `npm run check` green 177/177.
- **Review (Opus, `t3-03.diff`):** no Critical. *Important*: a tap or follow replied with Everything over the page's own graph push → **fixed** RED→GREEN on the server (`/api/live/now?graph=`, 404 before the tap). *Important*: a `?graph=` that is deleted or unknown makes `/live` 404 and reconnect forever → **left for T5** (`ui/live.js` is off limits here). *Minor, fixed*: errors other than a deleted graph are now logged instead of swallowed; one `stop()` runs on end and on close, plus a `writableEnded` guard on pushes and pings; the test decoder uses `{stream:true}`.
- **Next (T5):** `ui/live.js` must send `q` on `POST`/`DELETE /api/live/now` (line 73–74), fix its stale D17 comment (line 6), and fall back to Everything when `?graph=` is a 404. Renderers must show context cards, because `cued_edge_id` may now point at a context edge, which today hides the cued card and the Add pathway button in a non-default graph. A stream on a deleted graph ends at the *next* push (`refresh` doesn't push while nothing is shown).
- **Questions for Michael:** none new (D27 still open).
- **Proposed changes:** T5 needs a step for the four `ui/live.js` items above.

### 2026-10-17 03:40 EDT · T3-02 · passes

- **Changed:** `src/server.ts` gets the 17 thread/graph routes of the T3 plan plus `?graph=` on `GET /api/tracks/:id`, using the helpers `ref` (D25 lookup, 404 `<kind> not found: <ref>`), exported `graphRef` (null/"" → Everything), `edit` (Graph's plain Errors become 400 with T1's text), `decode` (400 on a malformed escape; art and sets now use it too) and `ids`/`optIds` (400 `track_ids must be a list of ids`). New `tests/threads-server.test.ts` (8 tests, the T1 fixture built over HTTP). Tests **163 → 171**.
- **Verified:** RED first (`no route: POST /api/threads`), then 8/8. Saturday disco 7 songs / 11 pathways / 2 threads; Hip-hop context_summary [Good Times bassline, songs_out 2]; `PATCH /api/graphs/default` → 400 `the Everything graph cannot be edited`; Good Times `?graph=Hip-hop block party` → out [Rapper's Delight], context [Another One Bites the Dust · Good Times bassline], elsewhere 0. Refresh spy: 1 push, 0 `resolveTrack` calls. Each of four mutations turned a test red (rematch always on, `edit` passthrough, no decode, no 404 on remove). curl on :7791 after restart; smoke 4/4; `npm run check` green 171/171.
- **Review (Opus, `t3-02.diff`):** *Important*: `?graph=` was decoded twice (`100%25%20disco` → 400) → **fixed** RED→GREEN (`ref` takes a decoded string; path segments decode at the call site). *Minor*: create skipped the `track_ids`/`thread_ids` list check (a string gave `FOREIGN KEY constraint failed`) → **fixed** RED→GREEN. *Minor*: a flaky `updated_at` ms comparison → **dropped** (the push count covers it). *Minor, left*: `edit` also turns TypeErrors from malformed bodies (`{}` → `…reading 'trim'`) into 400 with an internal message; extra segments after `:track_id` are ignored; a name `.`/`..` can't be addressed by URL (WHATWG normalises it). T3-05 can take these.
- **Next (T3-03):** `graphRef(g, url.searchParams.get("graph"))` is ready. Don't decode its value again, because searchParams already did.
- **Questions for Michael:** none new (D27 is still open).
- **Proposed changes:** none.

### 2026-10-17 03:20 EDT · T3-01 · passes

- **Changed:** new `docs/plans/2026-10-16-t3-api-live.md` (162 lines, superpowers:writing-plans): the 18-row route table (body, 200 shape, 404 unknown ref / 400 via an `edit()` wrapper that turns T1's exact Error texts into 400s), `LiveSnapshot` with `graph:{id,name}`, `context`, `elsewhere_count`, bare-callback subscribers + per-stream `live.snapshot(id)`, the recorder (`via_edge_id` derived inside `Graph.recordPlay`), CLI output lines from the real fixture, the docs/api.md sections, 5 Review Focus tests. Design §12 gains **D27 *default***. Tests **163 → 163** (docs only).
- **Verified:** `npm run check` green 163/163; `git status` shows only `docs/`; I ran the fixture to copy the real type names and artists (Bassline / Untyped, The Sugarhill Gang, Queen) and the `default` row (`name: 'Everything'`) into the plan; grep finds every OVERNIGHT T3 route in it. Smoke 4/4 at start.
- **Next (T3-02):** membership writes need **no** new refresh code: the existing `rematch: res0 === "tracks" || …` line already gives `rematch:false` for `/api/threads` and `/api/graphs`. Today a plain `Error` from Graph becomes a 500, so the `edit()` wrapper is required, not optional. `seg` needs a 5th element for `…/tracks/:track_id`.
- **Plan notes:** `in_count` stays global. A graph deleted under an open SSE stream ends that stream only.
- **Question for Michael (D27):** with `pathways serve --graph "Saturday disco"`, should `/live` without `?graph=` open Saturday disco? The default for now is no: `--graph` only stamps plays, and `/live` follows its URL (Everything when the URL has no `?graph=`).
- **Proposed changes:** T3-04 step 1 says to prefer an edge "with both songs in the graph", but that choice never comes up: every edge previous→current joins the same two songs, so they are all in the graph or none are. The plan stores the oldest edge. The wording could drop the clause.

### 2026-10-17 03:08 EDT · T1-05 · passes

- **Changed:** `src/graph.ts` (T1 refactor, 689 → 705 lines), `src/threads.ts` (1 line), `docs/architecture.md` (new §1a "The data model", one paragraph), `tests/graph-graphs.test.ts` (+3 asserts in an existing test). Tests **163 → 163**.
- **Review (Opus, `t1.diff` = `cce63d7..HEAD -- src tests docs`):** no Critical or Important findings. Positions after remove, merge collisions with via_edge repoint, the Everything guards, SQL injection (table names come only from the `"thread"|"graph"` literal, refs are bound) and N+1 in listThreads/listGraphs all came back clean. *Minor*: a graph named `default` could never be reached by name, because D25 tries the id first → **fixed** RED→GREEN: `freeName` now refuses a name that equals another row's id (`a graph named "default" would shadow the id of another graph`). *Minor, left as is*: the case-insensitive name check runs outside the write transaction (needs two writers at once); `localeCompare` (D26 chip) vs SQLite `NOCASE` (lists) differ for non-ASCII names; Everything's song order has no id tiebreak (same as listTracks); `reorderMembers` checks the permutation before its transaction; `outEdgesIn` with an unknown track returns an empty split (T3 decides 404).
- **Simplify, per angle.** *Reuse*: new private `row`/`must`/`byRef` (generic by kind) back threadRow/graphRow, mustThread/mustGraph and the two resolve*Ref; `members(kind)` serves getThread and graph own songs; `pathwaysAmong` serves getThread and `content`; `removeMember(kind)`; a `push` helper for Map-of-lists. *Simplification*: updateThread uses a per-field `pick` (no `Object.fromEntries` cast); getGraph's context_summary is now one `GROUP BY … HAVING` query (the songs_in/songs_out Map is gone); `byName` lost a dead branch; listThreads groups graphs in a Map. *Efficiency*: `addMembers` reads MAX(position) once (it ran one scan per row); `assertTracks` is one `json_each` query; graphMembers reads every thread's songs in one query (it ran one per thread); `content` seeds `hydrate` with the tracks it already loaded. *Altitude*: the three `id === "default"` branches (getGraph, graphContent, outEdgesIn) are gone; `graphMembers` alone defines Everything (every thread, every song in listTracks order), and the general code gives the same outputs. Skipped: moving context_summary into pure `threads.ts` (the SQL form above is shorter) and a separate membership-only query for outEdgesIn (about 5 ms).
- **Verified:** `npm run check` green, 163/163. Each of six mutations turned the thread/graph tests red (1–4 failures each): no shadow check, HAVING weakened, position bumped for ignored songs, thread songs unordered, Everything branch removed, assertTracks never throws. I restarted init on the new code; smoke 4/4 PASS.
- **Next (T3):** entry times above T1-05 are not wall-clock time (their commits are at about 03:00 EDT). On 'default', `outEdgesIn` now loads every track id. The result is the same as before (deep-equal to `outEdges()`), at the cost of one extra query per Live track change. `songs[i]` and `pathways[j].from` are now the same object inside `content()` results, so don't mutate them.
- **Questions for Michael:** none.
- **Proposed changes:** none.

### 2026-10-17 10:15 · T1-04 · passes

- **Changed:** `src/graph.ts` gets `GraphRow` and the graphs section: `createGraph`, `listGraphs`, `getGraph`, `updateGraph`, `deleteGraph`, `setGraphThreads`, `addGraphTracks`, `removeGraphTrack`, `reorderGraph`, `graphContent`, `outEdgesIn` and `resolveGraphRef`. Private helpers `graphMembers`/`content` (songs via `json_each`) and `mustEditableGraph` (the Everything guard) go with them, and a module-level `threadRef()` that `threadsOf` now uses too. `graphsFixture()` goes in `tests/helpers/threads-fixture.ts`. New `tests/graph-graphs.test.ts` (12 tests). Tests **151 → 163**.
- **Verified:** the file failed first (`createGraph is not a function`), then passed 12/12. Saturday disco has 7 songs in export order and 11 pathways. Hip-hop block party from Good Times splits out=[Rapper's Delight], context=[Another One Bites the Dust · Good Times bassline #f59e0b], elsewhere 0. Disco from Voyager splits out 3, context [], elsewhere 2. `listGraphs` gives Everything 9/15, Hip-hop 2/1, Disco 7/11. Each of these mutations turned a test red: `UNION ALL` in the count CTE, the Everything guard removed, the context_summary filter weakened, threads ordered by name, Everything sorted by title. `npm run check` is green 163/163; smoke 4/4 PASS.
- **Step wording:** `outEdgesIn(Saturday disco, Voyager).out` keeps `outEdges()` order, which sorts by connection type, so Good Times comes first. The step lists the 3 songs without an order, and the test compares them as a set.
- **Review (Opus, `t1-04.diff`):** no Critical/Important. *Minor*: test gaps → **fixed**: Everything's songs now match `listTracks()` order, plus checks for `outEdgesIn` on an unknown graph and `deleteGraph` setting `plays.graph_id` to NULL. *Minor*: `outEdgesIn` with an unknown track or a song outside the graph returns an empty split instead of throwing → left for T3 to decide (404 vs empty). *Minor*: `listGraphs` uses correlated subqueries over the CTE rather than `GROUP BY`, and `graphMembers` runs one query per thread in the graph → T1-05 simplify.
- **Next (T1-05):** the review diff starts at `fb28539`. Candidates for simplify: `getThread` pathways could reuse `content()`; `listThreads` and `listGraphs` could switch to `GROUP BY`.
- **Questions for Michael:** none.
- **Proposed changes:** none.

### 2026-10-17 09:40 · T1-03 · passes

- **Changed:** `src/graph.ts` gets `ThreadRow`/`Song` and the threads section (`createThread`, `listThreads`, `getThread`, `updateThread`, `deleteThread`, `addThreadTracks`, `removeThreadTrack`, `reorderThread`, `threadsOf`, `resolveThreadRef`). It also gets private helpers `freeName`/`assertTracks`/`addMembers`/`reorderMembers`, which take `"thread"|"graph"` so T1-04 can reuse them. `mergeTracks` moves `thread_tracks` **and** `graph_tracks` at the lower position (the tracks delete cascades drop's rows) and repoints `plays.via_edge_id` to the clashing edge (T0-03 finding 3). `allEdges` orders by `created_at, rowid`. New `tests/helpers/threads-fixture.ts` and `tests/graph-threads.test.ts` (13 tests). Tests **138 → 151**.
- **Verified:** the test file failed first (`g.createThread is not a function`), then passed 13/13. Good Times bassline has 4 songs at 1..4 and 4 pathways; French touch has 3 and 4. Merging Le Freak into Good Times leaves 3 songs with Good Times at 1. Three mutations (no lower-position update, no via_edge repoint, position always 1) each turned tests red. `npm run check` is green 151/151, and smoke is 4/4 PASS.
- **Review (Opus, diff of this feature):** *Important*: `updateThread(id, { motif: undefined })` wiped the motif → **fixed** test-first (RED `[…, null, null]`, then GREEN). *Minor*: `COLLATE NOCASE` folds only ASCII letters, so "Été" and "ÉTÉ" are two threads → left as is. *Minor*: merge ties on `added_at` → **rebutted**: keep takes drop's position and drop's row is deleted, so no two rows share a position. *Minor*: `listThreads` uses correlated subqueries rather than `GROUP BY`; it is still one statement → T1-05 may revisit.
- **Next (T1-04):** reuse `freeName("graph", …)`, `addMembers("graph", …)` and `reorderMembers("graph", …)`. `mergeTracks` already moves `graph_tracks`, so T1-04 only needs its test. `threadsOf` returns plain objects, because node:sqlite rows have a null prototype and fail `deepStrictEqual` against `{…}` literals.
- **Questions for Michael:** none.
- **Proposed changes:** none.

### 2026-10-17 09:05 · T1-02 · passes

- **Changed:** new `src/threads.ts` (34 lines, `import type` only): `ThreadRef`, `SplitOut`, `graphSongIds` (a `Set` over own songs then thread songs = D24 export order) and `splitOut` (keeps input order; from ∉ graph → dropped; to ∈ graph → out; shared thread → context with the D26 pick by `localeCompare(name)`, then id; else elsewhere). New `tests/threads.test.ts`, 7 tests. Tests **131 → 138**.
- **Verified:** the new file failed first (`ERR_MODULE_NOT_FOUND`), then passed 7/7: `['a','b'],[['b','c'],['d','a']]` → `a,b,c,d`; `[],[]` → `[]`; A→B/A→C/A→D → out [A→B], context [A→C, Good Times bassline], elsewhere 1; all endpoints in → 3/0/0; from E ∉ graph dropped; Zebra + Alpha → Alpha. A mutation (reversed sort) turned the D26 test red. `npm run check` green, 138/138. Smoke 4/4 PASS.
- **Next (T1-03/04):** `splitOut` looks up **both** ends in `threadsByTrack`, so `outEdgesIn` must map the from song *and* each to song to its threads. Restricting the map to the threads that hold the from song (the plan's wording) is enough.
- **Questions for Michael:** none.
- **Proposed changes:** none.

### 2026-10-17 08:40 · T1-01 · passes

- **Changed:** new `docs/plans/2026-10-16-t1-memberships.md` (125 lines, writing-plans): pure `src/threads.ts` signatures (`graphSongIds`, `splitOut`, `ThreadRef`, `SplitOut`), a table of all 22 `Graph` methods with return shapes, position/merge/guard rules with exact error messages, the `threadsFixture()`/`graphsFixture()` helpers, and one task per T1-02…T1-05. Design doc §12 gains **D25** and **D26** *default*. Nothing outside `docs/`; tests **131 → 131**.
- **Verified:** I counted the sample notes' 15 edges by hand against every number in T1-03/T1-04 (threads 4+4 pathways, Saturday disco 7 songs/11, Voyager out 3/elsewhere 2, Hip-hop block party context Another One Bites the Dust, songs_out 2). All hold. `npm run check` 131/131 green, smoke 4/4 PASS.
- **Next (T1-02…04):** `listThreads`/`listGraphs` sort by name, so French touch comes before Good Times bassline (T1-03's "4 and 3" means per thread, not list order). Threads in a graph keep the order `setGraphThreads` got them (`added_at, rowid`); that is what puts Good Times bassline first in Saturday disco's export order. `mergeTracks` also repoints `plays.via_edge_id` to the surviving edge (T0-03 finding 3), in Task 2.
- **Questions for Michael:** (B) D25: names unique **ignoring case**, so "saturday DISCO" always finds one graph; a second graph called "Saturday Disco" is refused. OK? (C) D26: chip shows the alphabetically first thread when several hold both songs. OK?
- **Proposed changes:** none.

### 2026-10-17 08:10 · verify T0

- T0-01 · holds (plan 90 lines, names tables/indexes/test/fixture/seed; its commit touched only docs/plans plus harness files)
- T0-02 · holds (check green 131 tests, smoke 4/4, schema-v3 tests 9/9, fixture 14 CREATEs, idempotent, FK deletes)
- T0-03 · holds (indexes, addMissingColumns, review dispositions in progress, api.md/README text present)

### 2026-10-17 07:40 · T0-03 · passes

- **Changed (commit `fb28539`):** `src/db.ts` → a new `addMissingColumns(db, table, cols)` does both column upgrades (v1→v2 tracks, v2→v3 plays), and `migrate()` now creates `idx_plays_graph`/`idx_plays_via_edge` after the ALTERs. `tests/schema-v3.test.ts` gets 2 new tests (FK rejection; v2 *file* `openDb` twice) and new checks for indexes/FKs. `docs/api.md` Schema → `SCHEMA_VERSION = 3` plus a v3 paragraph; `README.md` "Data model" now has one threads/graphs sentence. Tests **129 → 131**.
- **Review (Opus, `t0.diff` from `8245182..HEAD`):** (1) *Important*, no index on the new `plays` FK columns, so every graph/edge delete scanned `plays`. **Fixed** test-first: RED "missing idx_plays_graph", then GREEN; `EXPLAIN QUERY PLAN` now shows `SEARCH … USING COVERING INDEX`. (2) *Important*, two processes migrating one v2 DB at the same moment → "duplicate column name". **Rebutted:** the same race has existed since v1→v2, `init.sh` runs import before serve, and it fails loudly at startup; the next open succeeds. Nothing is corrupted. (3) *Minor*, `mergeTracks` deletes clashing edges, which NULLs `plays.via_edge_id` instead of moving it to the surviving edge → **T1 should repoint it** when it touches `mergeTracks`. (4) *Minor*, an older build writes `schema_version` back to 2 → left as is (it was already like this before T0).
- **/simplify:** reuse: the two copies of `PRAGMA table_info` + ALTER became `addMissingColumns`. Simplification: same change; the `playRefs` map is gone. Efficiency: the two `plays` indexes; otherwise nothing to simplify. Altitude: nothing to simplify. The test file got only the `playFks`/`indexes` helpers.
- **Verified:** `npm run check` green, 131/131. Smoke 4/4 PASS. A copy of the init `dev.db` opened twice → v3, 9 tracks / 15 edges, 1 graph row.
- **Next (T1-01):** the T0 review commit is `fb28539`; T1's review diff starts there. If you change `mergeTracks`, include finding (3).
- **Questions for Michael:** (A) Should two pathways processes starting on an old DB at the same moment be safe (wrap `migrate()` in `BEGIN IMMEDIATE`, 2 lines)? Default: no change.
- **Proposed changes:** none.

### 2026-10-17 07:05 · T0-02 · passes

- **Changed:** `src/db.ts` → `SCHEMA_VERSION = 3`; the five tables and three indexes are in `SCHEMA`, with CASCADE on every membership FK. `migrate()` adds `plays.graph_id`/`via_edge_id` (SET NULL) using the `PRAGMA table_info` check, then seeds `graphs('default','Everything')` with `INSERT OR IGNORE`. New: `tests/fixtures/schema-v2.sql` (14 CREATEs, captured before the edit) and `tests/schema-v3.test.ts` (7 tests). `tests/live-store.test.ts` now asserts v3. Tests **122 → 129**.
- **Verified:** the new file failed first ("no such table: threads"), then passed 7/7. `npm run check` green, 129/129. A copy of the init server's v2 `dev.db` (9 tracks / 15 edges / 7 plays) migrated to v3 with the same counts. It has one `default` row, and that is still true after a second open. Smoke 4/4 PASS.
- **Next (T0-03):** the diff base is `8245182`. The running init server still runs the old code, so restart it to see v3 live. Nothing calls the new tables yet; T1 adds `mergeTracks` moving memberships.
- **Questions for Michael:** none.
- **Proposed changes:** none.

### 2026-10-17 02:37 · T0-01 · passes

- **Changed:** new `docs/plans/2026-10-16-t0-schema-v3.md` (90 lines, writing-plans). Nothing in `src/` or `tests/` changed; tests still **122 → 122**.
- **Plan:** follows §12, so no `thread_edges`, no `graph_items` and no `default` thread. It covers the five tables with exact columns and FKs, the 3 indexes, `plays.graph_id`/`via_edge_id` (SET NULL) added with the `PRAGMA table_info` check, the seed `INSERT OR IGNORE graphs('default','Everything')` and `SCHEMA_VERSION = 3`.
- **Verified:** I ran the plan's fixture-capture command against today's v2 `openDb`. It printed 14 `CREATE` statements (7 tables, 7 indexes) with no `graph_id`, and that SQL loads into a bare `DatabaseSync`. `npm run check` green, 122/122. Smoke 4/4 PASS.
- **Next session (T0-02):** capture `tests/fixtures/schema-v2.sql` **before** editing `src/db.ts`. Don't put an index on the new `plays` columns into `SCHEMA`: on a v2 DB it runs before the `ALTER` and fails. `tests/live-store.test.ts:24-25` asserts version 2 and must change to 3. The plan adds 7 tests (122 → 129).
- **Questions for Michael:** none new. `position INTEGER NOT NULL` on both song-membership tables is a plain reading of D21/D22, not a new decision.
- **Proposed changes:** none.

### 2026-10-17 06:40 · initializer (Fable) · feature list written

**Counts:** 37 features — T0 3 · T1 5 · T3 5 · T4 9 · T5 4 · T7 3 · T6 5 · stretch 3.
First three: T0-01 (schema plan), T0-02 (schema v3 + migration test), T0-03 (T0 review).
Start state: `main` @ 94b204e merged into this branch at 8245182; `npm run check` green, **122 tests**;
init server on :7791 with the sample graph and the 399 replay at its end state.

**Two deliberate deviations from OVERNIGHT.md's queue.**
1. The demo seed `docs/demo/threads-399.sh` moved from T5 to T4 (feature T4-07) and `.harness/init.sh`
   runs it, so T4's "What Michael will see" table has real matches and T5's screenshots come straight
   from the init server. Nothing else moved.
2. T7 has no separate plan session: T7-01 writes a short plan file and the README in one Sonnet session.
   The "headless pass" and "What Michael will see" boxes of T4 and T5 are one Sonnet feature each
   (T4-08, T5-03): same browser, same screenshots.

**Where things live (read before coding).**
- `src/db.ts` — `SCHEMA` string + `migrate()`; `SCHEMA_VERSION = 2` today. The v1→v2 column-check pattern
  (`PRAGMA table_info`, then `ALTER TABLE … ADD COLUMN`) is the model for `plays.graph_id` / `via_edge_id`.
  Tests open `openDb(":memory:")`. `node:sqlite` only.
- `src/graph.ts` — class `Graph`: tracks (`upsertTrack`, `mergeTracks` moves `track_aliases` and `plays`
  — copy that for `thread_tracks`/`graph_tracks`), edges (`outEdges`, `inEdges`, `allEdges` → `EdgeWithTracks`
  with `from`, `to`, `type`), `isHexColor`/`assertHexColor` (reuse for thread colours), `transaction()`.
  Ids are `randomUUID()`; the graph `default` is the one fixed id.
- `src/live.ts` — `LiveState`: `snapshot()` reads `outEdges(cur.track.id)` fresh each time; `cued_edge_id`
  = out edge whose `to_id` is the loaded other deck's track. `subscribe(fn)` currently pushes one snapshot
  to every subscriber — T3-03 makes it per-graph (subscribers call `live.snapshot(graphId)` themselves).
  `refresh({rematch})` is called by `server.ts` after every non-GET `/api/*` call; `rematch` is true only for
  `tracks`, `import` and `POST edges`, so new `threads`/`graphs` routes already push without a re-match.
- `src/server.ts` — one `api()` function switching on `res0 = seg[1]`, `id = seg[2]`, `sub = seg[3]`.
  `HttpError(status, msg)` for 400/404. SSE at `/api/live/events` (per-connection `push`). `?graph=` is read
  and echoed as a string today (`graph: "anything"` in `tests/live-server.test.ts` — T3-03 changes that test:
  unknown ref → 404, `graph` becomes `{id, name}`).
- `src/cli.ts` — `arg(flag, args)` helper, `switch (cmd)`; `serve` builds `LiveState` + `ReplaySource(file,
  {speed})`. `bin/pathways` runs it with `--experimental-strip-types`. `PATHWAYS_DB` env picks the DB.
- `ui/app.js` (editor, classic script, `state.view`, `setView`, `open(id, view)`, `card(e, dir)`, `renderWeb`,
  `#tabs button[data-view]`, `window.openPicker` from `ui/picker.js`), `ui/index.html` (header: logo · `#stats`
  pill · Live link · tabs; aside `.library` with `#search`, `#tracklist`, `#newTrack`), `ui/style.css`.
- `ui/live.js` + `ui/live-render.js` (pure renderers, unit-tested in `tests/live-render.test.ts`; `.d.ts`
  siblings make them typecheck — any new `ui/*.js` imported by a test needs a `.d.ts`), `ui/live.css`,
  `ui/live.html` (static heading "Pathways from this track" — words.js must set it).
- Tests: `node:test`, one file per module, in-memory DBs; e2e tests start `createApp()` on port 0
  (`tests/live-server.test.ts` is the template, including the SSE reader). `tsconfig` includes `src/**`,
  `tests/**` only.
- Harness: port **7791**, scratch `/tmp/harness/pathways/threads-2026-10-17/` (`dev.db`, `server.log`,
  `check.log`), Playwright at `/tmp/harness/pw` via `createRequire(process.env.HARNESS_PW + "/")`
  (`.harness/smoke.mjs` shows the pattern: 4 checks, 1280/390). `.harness/init.sh` rebuilds the scratch DB
  before every session (import sample → serve with `--replay 399.session --speed 0`).

**Sample data (`samples/notes-sample.md`): 9 songs, 15 pathways.** Good Times (Chic), Le Freak (Chic),
Voyager (Daft Punk), Summer Madness (Kool & The Gang), Get Down Saturday Night (Oliver Cheatham), Another One
Bites the Dust (Queen), Thinking of You (Sister Sledge), Music Sounds Better With You (Stardust), Rapper's
Delight (The Sugarhill Gang). Edges: Voyager→{Get Down, Summer Madness, MSBWY, Thinking of You, Good Times};
MSBWY→Voyager; Good Times→{Rapper's Delight, Another One}; Rapper's Delight→Get Down; Another One→Good Times;
Get Down→{MSBWY, Le Freak}; Le Freak→Good Times; Summer Madness→Thinking of You; Thinking of You→Get Down.
So: thread *Good Times bassline* (Good Times, Rapper's Delight, Another One, Le Freak) has 4 derived pathways;
*French touch filter family* (Voyager, MSBWY, Get Down) has 4; graph *Saturday disco* = both threads = 7 songs,
11 pathways; *Hip-hop block party* = own songs Good Times + Rapper's Delight → from Good Times: out Rapper's
Delight, context Another One (Good Times bassline), elsewhere 0; from Voyager in Saturday disco: out 3,
elsewhere 2 (Summer Madness, Thinking of You).

**399 set (`tests/fixtures/serato/399.session`, 7 plays, 8 songs, end state current Woman of the World d1,
deck 2 All Night Long cued, not played).** Play order: Rico Suave Bossa Nova feat. Azymuth (J Dilla) 15:44 ·
Leroy's Latin Lament: Lonnie Dreams/The Way We Feel/ La Fiesta/Lament (War) 15:46 · Woman of the World
(Donald Byrd) 16:08 · What's Going On (Marvin Gaye) 16:13 · Coffy Is The Color (Roy Ayers) 16:23 · Glide
(Pleasure) 16:25 · Woman of the World 18:23 (America/New_York). Samba Cantina (Paul Desmond) was loaded, never
played. The demo seed (T4-07) uses these exact raw titles so `resolveTrack` matches `exact`.

**Contracts every session must honour (also in the T1/T3/T4 plans).**
- Pure rules first: `src/threads.ts` (`graphSongIds`, `splitOut`, `ThreadRef = {id,name,color}`) has no DB
  import; `Graph.outEdgesIn` and `LiveState.snapshot` call it.
- `position` = `MAX+1` on add; reorder takes the full ordered list and rewrites 1..n; lists `ORDER BY
  position, added_at`; merge keeps the lower position.
- Refs: `/api/threads/:ref`, `/api/graphs/:ref`, `?graph=`, `--graph` accept the id or the exact name
  (case-insensitive) — **D25 default** (T1-01 writes it into design §12). Unknown → 404 (HTTP) / exit 1 (CLI).
  Edits to `default` → 400 "the Everything graph cannot be edited".
- Context chip when several threads hold both songs: the thread whose name sorts first; `GET
  /api/graphs/default` lists every thread — **D26 default**.
- Snapshot additions: `graph: {id,name}`, `context: (EdgeWithTracks & {thread})[]`, `elsewhere_count`.
  Old clients ignore them. In Everything, `context` is `[]` and `elsewhere_count` 0.
- Every on-screen noun from `ui/words.js` (T4-02). Tonight's words: song, pathway, thread, graph, set, context.
- Diff ranges for review features: `git diff <previous milestone's review commit>..HEAD`. **Every session
  names its commit hash in its progress entry** so the next review can find its range.

**Gotchas.**
- `ALTER TABLE plays ADD COLUMN graph_id TEXT REFERENCES graphs(id) ON DELETE SET NULL` is legal in SQLite
  only because the default is NULL; keep it that way.
- `tests/live-server.test.ts` asserts `snap.graph === "anything"` and `/api/live?graph=anything` succeeds —
  T3-03 must change that test on purpose (unknown graph → 404).
- `init.sh` replays 399 **before** the seed exists, so the recorded `plays` rows of the init server stay
  unmatched; the "What Michael will see" features start a second server on `$HARNESS_PORT+1` that seeds
  first, then replays with `--graph`. The live decks on :7791 still re-match after the seed (POST /api/tracks
  triggers `refresh({rematch:true})`).
- `ui/live.js` already sends `?graph=` to `/api/live` and the SSE URL; T5 only has to render.
- Playwright: `page.goto(url, { waitUntil: "load" })`, not `networkidle` (the SSE stream never idles).
- Smoke counts art 404s as fine; any other console error fails it.

**Questions for Michael** (defaults taken; answer in `INBOX.md` → `## Answers`):
1. **Q8 naming** — still today's words (song · pathway · thread · graph · set). Pick a row in
   `docs/naming-options.md` and the stretch applies it in `ui/words.js`. Default: no rename.
2. **D25** — graphs and threads are addressed by name as well as id (`/live?graph=Sunday%20tea%20tent`).
   OK, or ids only?
3. **D26** — when two threads hold both songs of a context pathway, the chip names the one that sorts first
   by name. OK, or list all of them?
4. **Demo seed content** — threads *Tea-tent Latin jazz* (Woman of the World, Rico Suave Bossa Nova, Leroy's
   Latin Lament, Samba Cantina) and *Night closers* (Woman of the World, All Night Long); graphs *Sunday tea
   tent* and *Soul hour*. Made up from the 11 Oct set so every card state shows; rename freely.
5. Still open from before: D15 (`.env` for Navidrome — T6 runs on the fake without it), D16, D18, D19,
   the D21/D22 check. Defaults stand.
