# Overnight runbook — Pathways threads & graphs (OVERNIGHT-3)

You are an unattended Claude Code session on Michael's Pop!_OS home box, driven by a
self-paced `/loop`. Michael is asleep or away and watches from his phone (the GitHub app
on this repo, push notifications, and a second Claude session that can read anything under
`~/projects`). **This file is your memory across loop iterations and context compactions.**
Re-read it at the start of every iteration, do the next unchecked step, tick it, append to
the Status log, commit, and push the branch after each milestone (the GitHub app is how
Michael reads this file).

The design you are implementing is `docs/specs/2026-10-14-threads-and-graphs-design.md`
(model B, §9 plan), **as amended by its §12** (Michael's 2026-10-16 answers, decisions
D20–D24). Where §12 and §4–§6 differ, §12 wins. The previous runbook (Phase 2, fully ticked)
is archived at `docs/runbooks/2026-10-14-overnight.md`.

## Ground rules (non-negotiable)

_Carried over from the Phase 2 runbook; only the branch, milestone names and counts are updated._

1. **Branches only.** Work on `overnight/2026-10-16` in `~/projects/pathways`, created from
   `origin/main` (f2de0e9) at M0. Commit small and often; `git push -u origin
   overnight/2026-10-16` after each milestone. Never commit to, merge into, or push `main`.
   Never force-push. Never rebase a pushed branch. The remote stays
   `git@github.com:mh550/pathways.git`. Merging into `main` happens in the review conversation.
2. **This repo only.** Write only inside `~/projects/pathways` (and `/tmp`). Other
   overnight sessions may own the working trees of `~/projects` and
   `~/projects/dj-crate-streaming`: never run `git checkout/switch/stash/reset/commit` there.
   Read anything under `~/projects` freely.
3. **No sudo.** Anything needing root goes under "Needs Michael" with the exact command.
4. **Michael's sources are read-only.** `/srv/incoming/**` (Serato copies, audio files) and
   `samples/` notes are inputs. Everything written goes to the graph store (`data/*.db`,
   git-ignored), `data/art/`, `/tmp`, or copies inside the repo (`tests/fixtures/`). Never
   modify, rename or delete an original.
5. **No secrets in commits.** Navidrome credentials, if Michael provides them (D15), live
   only in `~/projects/pathways/.env` (git-ignored, chmod 600) as `SUBSONIC_URL/USER/PASS`;
   the CLI loads that file itself. Never `cat`/`echo` it, never source it, never read
   `/srv/docker/.env`. Fixtures may contain track names and laptop paths — nothing else personal.
6. **Simple beats clever.** Zero runtime dependencies stays true. `node:sqlite`,
   `node:http`, vanilla JS. Reuse the existing CSS and the Live view's look. The smallest
   thing that works end to end, then the next.
7. **Decisions.** The design doc's §12 and "Decisions already made" below are decided; do not
   re-open them. A *new* decision that is Michael's gets the simplest reversible default, is
   appended to the design doc's §12 as `D<n> *default*` **and written as a direct question in
   the Status log** (he reads this file from his phone). Don't block.
8. **If Michael messages you**, his message overrides the queue. Record it under
   "Direction from Michael" before acting.
9. **If a tool call is denied by the permission classifier**, try one narrower form (a
   repo CLI command instead of inline code, a read instead of a write), then record it under
   "Needs Michael" with the exact command and move on. Never retry verbatim.
10. **Network is optional.** Nothing in M0–T7 needs the internet except `git push` and
    `npm install`. Navidrome is on localhost:4533 and only usable with D15 credentials;
    without them the Subsonic code is tested on the fake.
11. **Time rule.** If 5.5 h have elapsed and T5 has not started, finish the current
    milestone, then do T7 before anything else. T6 is the first thing to drop.

## Discipline (superpowers skills)

- Before feature code in each milestone: `superpowers:writing-plans` →
  `docs/plans/2026-10-16-t<n>-<topic>.md`, then execute it. One plan per milestone, short.
- All code: `superpowers:test-driven-development`. Keep `npm run check` green
  (typecheck + **122 tests at start**). Tests use `node:test`, temp DBs, no shared state.
- Failures you don't understand: `superpowers:systematic-debugging`.
- Before ticking a box: `superpowers:verification-before-completion` — run it, read the
  output, then tick.
- End of each milestone: a code review of the milestone diff (most capable model), fix
  Critical/Important with RED→GREEN tests, then `/simplify` (four angles).
- **Pure rules first** (design §8): "which songs are in a graph", "which pathways are
  context" are pure functions with unit tests before they are wired into `Graph`/`LiveState`.
- **"What Michael will see" check** after T4 and T5: screenshots at 1280 and 390 px, and a
  replay of `tests/fixtures/serato/399.session` at speed 0 against the demo seed (T5) with a
  table in the Status log — start time, deck, status, raw title — artist, match, resolved
  track, graph, cards *in graph* / *context* (thread names) / *elsewhere* count, cued yes/no
  (and whether the cue is in context). Counts alone are not enough; names are what he sees.

### Orchestration (this session is the orchestrator)

- Keep your own context small. **Implementation** → one Opus subagent per milestone (or per
  independent task) with a written spec in the scratchpad: goal, files to read first, exact
  behaviour, tests to write first, what not to touch, a timebox, report ≤ 300 words.
- **Testing and verification** (headless Chromium passes, replay checks, real-data runs) → a
  Sonnet subagent told what to test and why, what PASS looks like, the scratch DB
  (`PATHWAYS_DB=/tmp/pathways-o3/<milestone>.db`) and port (`7791`+, never 7777).
- **Code review and the four `/simplify` angles** → Opus reviewers that read the diff from a
  file in the scratchpad (`git diff <milestone-start>..HEAD > scratchpad/t<n>.diff`) and return
  findings only.
- Independent agents run in parallel in one message; never two agents on the same files.
  Do not read large diffs, transcripts or screenshots yourself when an agent can report the
  conclusion. Verify every claim with one cheap command (`npm run check`, `git status`, a grep)
  before ticking a box.

## Phone updates

- `PushNotification` if the tool is available: under 200 characters, no secrets, at most
  one an hour unless blocked. Start, each milestone, blocked, done. Say in the start push
  that this file (on the branch, in the GitHub app) is the status page.
- If the Artifact tool is available, a private status page is optional; the Status log in
  this file is the source of truth either way. Everything Michael must read lives in this
  repo, pushed.

## Pacing

- More work queued → finish one step, commit, schedule the next wakeup at the minimum.
- Waiting on Michael and nothing else to do → every 30 min.
- Queue done (stretch included) or 8 hours elapsed → wrap-up, final push, stop the loop,
  write the outcome as visible text.

---

## Decisions already made (do not re-ask)

From the design doc (D14, model B) and Michael's §11 answers of 2026-10-16 (design §12):

- **Model B.** Tracks and edges stay global, unchanged; one song = one node, one connection =
  one edge; import stays idempotent; no `graph` = today's behaviour (D17).
- **D20 Threads are optional (Q1).** No `default` thread; songs and pathways can be in zero
  threads. Graph `default` = "Everything", virtual (all songs, all pathways), read-only.
- **D21 *default* Threads hold songs in brainstorm order (Q2, Q5).** `thread_tracks.position` =
  the order songs were added, editable, used as default sort and export order; no canonical
  walk. A thread's pathways = every pathway between two of its songs (derived). "Make a thread
  from these songs" keeps the selection order.
- **D22 *default* Graphs = threads + own songs; pathways induced.** A graph's songs = own songs
  ∪ its threads' songs; its pathways = every pathway with both songs in the graph. Including a
  context pathway = adding its target song. No edge cherry-pick table.
- **D23 Context (Q6 default).** A → B with A in the graph, B not: *context* if a thread holds
  both A and B (chip names the thread), else *elsewhere* (counted). Rendering per design §7.
- **Q3:** deleting a thread or graph removes memberships only; songs and pathways stay.
- **Q4:** no importer thread options; **T2 is dropped**. Threads are made in the app.
- **D24 *default* Navidrome (Q7).** Graph → playlist `Pathways · <graph>` (replace on
  re-export = one-way sync) and playlist → graph. No walk export. CLI only until D15.
- **Q8 naming:** options in `docs/naming-options.md`, awaiting Michael's pick. Code names stay
  (`tracks`, `edges`, `threads`, `graphs`); every on-screen noun comes from `ui/words.js` (T4).
  Tonight's on-screen words: song, pathway, thread, graph, set.
- **Carried over, defaults stand:** D15 (no `.env` → Navidrome on the fake), D16 (Mixxx play
  logging unverified), D18 (current-track rule), D19 (artist-less track adopted when the artist
  arrives). All in "Needs Michael".

## Queue

### M0 — Preflight (≈15 min)
- [x] `git fetch origin main`; `overnight/2026-10-16` created from `origin/main` (f2de0e9 =
      PR #1 merge). Node v24.21.0. `npm run check`: typecheck clean, **122/122**.
- [x] Read: STATUS, architecture, the design doc in full, the Phase 2 runbook, `src/db.ts`,
      `src/graph.ts`, `src/server.ts`, `src/live.ts`. No `~/projects/pathways/.env` (D15).
- [x] Archive the Phase 2 runbook → `docs/runbooks/2026-10-14-overnight.md`; write this file;
      design doc §12; `docs/naming-options.md`. Commit `OVERNIGHT-3: runbook`, push.
- [ ] At loop start: `mkdir -p /tmp/pathways-o3`; confirm inputs read-only
      (`ls tests/fixtures/serato/399.session`, `/srv/incoming/serato/_Serato_/database V2`);
      `curl -s 'http://127.0.0.1:4533/rest/ping?v=1.16.1&c=pathways&f=json'` (Navidrome up?);
      re-check for `.env`. Start push notification. Log it.

### T0 — Schema v3 + migration (≈30 min) — design §5 as amended by §12
- [ ] Plan `docs/plans/2026-10-16-t0-schema-v3.md`.
- [ ] `SCHEMA_VERSION = 3`. Tables: `threads(id, name UNIQUE, motif, notes, color, created_at,
      updated_at)`, `thread_tracks(thread_id, track_id, position, added_at, PK(thread_id,
      track_id))`, `graphs(id, name UNIQUE, notes, created_at, updated_at)`,
      `graph_threads(graph_id, thread_id, added_at, PK)`, `graph_tracks(graph_id, track_id,
      position, added_at, PK)`; indexes on the `track_id`/`thread_id` sides; all FKs `ON DELETE
      CASCADE`. `plays` gains `graph_id` (→ graphs, SET NULL) and `via_edge_id` (→ edges, SET
      NULL) via the same column-check pattern as v1 → v2. Seed graph `default` "Everything".
- [ ] Tests first: an in-test v2 DB with tracks/edges/plays migrates (rows kept, tables and
      columns present, `schema_version` 3, re-open idempotent, `default` graph present once);
      deleting a thread/graph removes memberships only; deleting a track removes its memberships.
- [ ] Review + `/simplify`; check green; commit `T0: …`; push; notify.

### T1 — Graph memberships and the pure rules (≈1.5 h)
- [ ] Plan `docs/plans/2026-10-16-t1-memberships.md`.
- [ ] Pure module `src/threads.ts`: `graphSongIds(ownSongs, threadSongs)`, `splitOut(edges,
      inGraph, threadsByTrack)` → `{ out, context: (edge + thread{id,name,color})[],
      elsewhere_count }` per D23; export order (own songs by position, then threads in
      graph order, songs by thread position, de-duplicated). Unit tests first.
- [ ] `Graph`: threads CRUD (`createThread({name, motif?, notes?, color?, track_ids?})` keeping
      `track_ids` order, list with song counts and the graphs using each, get = songs in order +
      derived pathways, update, delete, add/remove songs, reorder); graphs CRUD (`default`
      read-only, `setGraphThreads`, add/remove/reorder own songs); `graphContent(id)` →
      songs + pathways (`default` = everything); `outEdgesIn(graphId, trackId)`;
      `threadsOf(trackId)`. Hex colour and unique-name errors in the existing style.
- [ ] `mergeTracks` moves `thread_tracks` and `graph_tracks` (INSERT OR IGNORE, keep the lower
      position, then delete), like `track_aliases`.
- [ ] Tests on `samples/notes-sample.md`: thread *Good Times bassline* = Good Times, Rapper's
      Delight, Another One Bites the Dust, Le Freak; *French touch filter family* = Voyager,
      Music Sounds Better With You, Get Down Saturday Night; graph *Saturday disco* = both;
      graph *Hip-hop block party* = own songs Good Times + Rapper's Delight → from Good Times:
      out = Rapper's Delight, context = Another One Bites the Dust (thread Good Times bassline),
      elsewhere 0; merge keeps memberships; `default` = today's `outEdges`.
- [ ] Review + `/simplify`; check green; commit; push; notify.

### T2 — ~~Importer `--thread`, `--threads-from-headings`~~ — dropped (Q4)
- [x] Dropped by Michael's answer to Q4: threads are created in the app, not from notes.
      Its 0.75 h goes to T6.

### T3 — API, LiveState split, `?graph=` (≈1.25 h)
- [ ] Plan `docs/plans/2026-10-16-t3-api-live.md`.
- [ ] Routes: `GET/POST /api/threads`, `GET/PATCH/DELETE /api/threads/:id`,
      `POST /api/threads/:id/tracks {track_ids}`, `DELETE /api/threads/:id/tracks/:track_id`,
      `PUT /api/threads/:id/order {track_ids}`; `GET/POST /api/graphs`,
      `GET/PATCH/DELETE /api/graphs/:id` (GET = songs, pathways, threads, context summary),
      `PUT /api/graphs/:id/threads {thread_ids}`, `POST /api/graphs/:id/tracks {track_ids}`,
      `DELETE /api/graphs/:id/tracks/:track_id`. `GET /api/tracks/:id?graph=` adds the
      out/context/elsewhere split. Unknown graph → 404; edits to `default` → 400.
      Membership changes push to open pages without a re-match.
- [ ] `LiveState.snapshot(graphId = "default")`: `out` (in graph), `context` (with thread chip
      data), `elsewhere_count`, `graph: {id, name}`; `cued_edge_id` searched in `out`, then
      `context`. `/api/live?graph=` and the SSE stream use the caller's graph (per subscriber).
      Clients that ignore the new fields keep working.
- [ ] Recorder: `serve --graph <id|name>` (validated at start) stamps `plays.graph_id`; a new
      play fills `via_edge_id` when the previous play's track → this track is a pathway (prefer
      one in the graph); null = a jump.
- [ ] CLI `threads list|show <name>`, `graphs list|show <name>`. `docs/api.md` updated.
- [ ] Tests: server e2e with `ReplaySource` (speed 0) on the T1 sample graphs; SSE carries the
      split; via_edge on a two-play replay.
- [ ] Review + `/simplify`; check green; commit; push; notify.

### T4 — Editor: graph switcher, Threads and Graphs tabs, context rendering (≈1.75 h)
- [ ] Plan `docs/plans/2026-10-16-t4-editor.md`.
- [ ] `ui/words.js`: every on-screen noun (song, pathway, thread, graph, set, context) in one
      place, so the Q8 rename is one file. Use it in the new UI and the Live view.
- [ ] Graph switcher in the header (Everything default; carried in `?graph=`, remembered per
      browser). Track and Web views show the graph's songs and pathways; context per design §7
      (45 % opacity, dashed left border in the thread colour, chip "<thread> · context", note
      hidden until tap, **+ add to graph** adds the target song); "← N elsewhere". Web view:
      context-only songs as outlines.
- [ ] **Threads** tab: list (colour, song count, graphs using it), create (name, motif, colour),
      thread page with songs in brainstorm order (up/down to reorder, add via the existing
      search picker, remove) and the pathways among them. **Make thread from songs**: tick songs
      in the Track list in the order you think of them → new thread in that order.
- [ ] **Graphs** tab: create, rename, delete; threads as checkboxes; own songs (add via picker,
      remove, reorder); Everything shown read-only. Adding a song through the picker while a
      graph other than Everything is active also adds it to that graph.
- [ ] Headless pass (Sonnet) at 1280/390: no console errors, no horizontal scroll at 390;
      screenshots `docs/screenshots/editor-{switcher,threads,thread-page,graphs,context}-{1280,390}.png`.
- [ ] **What Michael will see** (screenshots + 399 replay table, see Discipline).
- [ ] Review + `/simplify`; check green; commit; push; notify.

### T5 — Live view: context list, chips, cued-in-context (≈45 min)
- [ ] Plan `docs/plans/2026-10-16-t5-live-context.md`.
- [ ] `/live?graph=<id>` passes the graph to `/api/live` and the SSE stream; graph name in the
      header; pathway list = `out`, then `context` under "from thread *X* (not in this graph)",
      dimmed per §7, then "← N elsewhere"; a cued target in context lights up in the dimmed style
      (§7 rule 4). Add pathway / tap look-ahead unchanged.
- [ ] Demo seed `docs/demo/threads-399.sh` (curls a running server; reproducible by Michael):
      the 399 set's songs, a few pathways between them, thread *Tea-tent Latin jazz* and a graph
      that holds only part of it, so the replay shows in-graph, context and elsewhere cards.
- [ ] Headless pass at 1280/390; screenshots `docs/screenshots/live-context-{1280,390}.png`,
      `live-cued-context-{1280,390}.png`.
- [ ] **What Michael will see** (399 replay at speed 0 against the demo seed: the table).
- [ ] Review + `/simplify`; check green; commit; push; notify.

### T6 — Graph ↔ Navidrome, `sets show` with pathways (≈1.5 h; first to drop)
- [ ] Plan `docs/plans/2026-10-16-t6-navidrome.md`.
- [ ] Subsonic client: `getPlaylists`, `getPlaylist`, `createPlaylist` (name + `songId`s; with
      `playlistId` it replaces the songs). Fake server extended with the same four responses
      (Subsonic 1.16.1 shapes; `dj-crate-streaming/fixtures/navidrome_playlist_song_search3.sample.json`
      as the reference for song objects).
- [ ] `pathways graphs export <graph> --navidrome [--dry-run]`: export order from T1, song ids
      from Navidrome `library_ref`s, playlist `Pathways · <graph>` created or replaced; report
      exported and skipped songs by name. `pathways graphs import <playlist> [--graph <name>]`:
      the playlist's songs become the graph's own songs in order (match by `library_ref`, else
      `upsertTrack` like the picker, D19 rules, ref filled).
- [ ] `pathways sets show <ref>`: each step shows the pathway taken (type, note) or "jump".
- [ ] Tests on the fake; a real export of a small graph **only if** `.env` exists (D15) — log
      the playlist name. Otherwise log "fake only".
- [ ] Review + `/simplify`; check green; commit; push; notify.

### T7 — Docs and wrap-up (≈30 min; always, even if stopping early)
- [ ] README: "Threads and graphs" section (editor tabs, `/live?graph=`, CLI, demo seed);
      layout table and test count updated.
- [ ] `docs/api.md` complete for every new route and the new snapshot fields.
- [ ] `docs/STATUS.md` rewritten for this slice ("Review in 10 minutes" with the demo seed and
      the 399 replay, validation with real numbers, gaps). `docs/architecture.md`: the data
      model paragraph (threads, graphs, induced pathways).
- [ ] Design doc §12: any new `D<n> *default*`. Draft `ideas/` updates as a text block in the
      Status log for the review conversation.
- [ ] `npm run check` green; final commit; `git push -u origin overnight/2026-10-16`.
- [ ] Final push notification. Stop the loop and write the outcome as visible text: branch,
      test count, every open question in full, and a reminder that the review conversation
      merges `overnight/2026-10-16` into `main`.

### Stretch (only if T7 is done, in this order)
- [ ] **+ add to graph** from a context card on the Live view (adds the target song).
- [ ] `pathways threads from-set <ref> --name <n>`: a recorded set's songs, in play order, as a
      new thread (the brainstorm-order idea applied to a night).
- [ ] Two-way graph ↔ playlist sync: design note only (design doc §13: what wins on conflict).
- [ ] If Michael has picked names (Q8): apply them in `ui/words.js` and the docs.

---

## Direction from Michael
_(append messages from the phone here, newest first; answers to open D-questions go here too)_

- **2026-10-16 (before the loop), answers to the design doc's §11:**
  1. "I don't know what the database design should be. The user should be able to have threads,
     and view pathways / graphs without threads. The thread would be a more saturated/global
     version of a set of edges in a graph, whose data is persisted across pathways." → D20, D22.
  2. "A thread is a set at its core, but could carry a canonical walk. There is some ordering
     inherent in the thread, but it's rather dynamic and flexible." → D21.
  3. Yes (delete thread = memberships only).
  4. "The normal eventual flow will not be import-based — I will be creating threads within the
     app itself. So we don't need to worry about creating threads from the import at all." → T2 dropped.
  5. "A pathway is just a path through the graph. I don't think we'd be adding new pathways —
     rather, we'd be adding songs and threads — sometimes converting groups of songs into
     threads. As I brainstorm I have a natural ordering to the songs that come to mind. So the
     original creation of the thread has an ordering inspiring it, but its core ideas are
     unordered." → D21 (songs in brainstorm order), naming collision noted in `docs/naming-options.md`.
  6. Agreed with the default (context from touching threads only). → D23.
  7. "I don't really see us exporting a pathway. I see the most common flow of us adding a graph
     to Navidrome. Or vice versa. Maybe we find a way to sync them." → D24, T6 rewritten.
  8. "Help me brainstorm different naming options for the terminology across the whole
     application." → `docs/naming-options.md` (five option sets; recommended: song · link ·
     thread · map · path/set).
  Also: T6 drops first; "What Michael will see" after T4 and T5; implementation, testing and
  review delegated to subagents.

## Needs Michael
_(exact commands / decisions, newest first)_

- **Q8 naming:** pick a row (or one word per column) in `docs/naming-options.md`. The main
  collision: you say "pathway" for a path through the graph; the app says it for one connection.
- **D21/D22 check:** threads are songs (in the order you add them) and a graph's connections
  are all pathways between its songs — no per-connection membership. Right, or do you want to
  mark single connections as in/out of a thread?
- **D15 — Navidrome user for pathways** (T6 real runs): in the Navidrome web UI create user
  `pathways` (not admin), then
  `printf 'SUBSONIC_URL=http://127.0.0.1:4533\nSUBSONIC_USER=pathways\nSUBSONIC_PASS=<the password>\n' > ~/projects/pathways/.env && chmod 600 ~/projects/pathways/.env`.
- **D16 — verify Mixxx play logging:** `flatpak run org.mixxx.Mixxx`, finish first-run setup,
  play two tracks ~20 s each, then
  `bin/pathways serve --mixxx ~/.var/app/org.mixxx.Mixxx/.mixxx/mixxxdb.sqlite` and open
  http://localhost:7777/live (second track current, first *just played*?).
- **D18 current-track rule** (default stands): does a briefly played, pulled-back track stay
  "current" on your rig? (`docs/architecture.md` §5.)
- **D19 artist adoption** (default stands): an artist-less *Glide* is adopted by *Glide — Pleasure*
  when the artist arrives. Keep, or keep them apart? (`docs/architecture.md` §6.)
- **Laptop live test:**
  `git clone git@github.com:mh550/pathways.git && cd pathways && npm install && npm run cli -- serve --serato "C:\Users\micha\Music\_Serato_"`,
  then `http://localhost:7777/live` on a second screen or the phone over Tailscale.
- **Real notes:** still only `samples/notes-sample.md` on this box; paste a chunk into Import →
  Dry run, or drop the file in `samples/`.
- **At the end of the review conversation:** merge `overnight/2026-10-16` into `main`.

## Status log
_(newest first: time · step · result · commit)_

- **2026-10-16 · M0 (runbook) · done.** State as expected: `main` @ f2de0e9 (PR #1 merge),
  checkout was clean on `overnight/2026-10-14`; branch `overnight/2026-10-16` created from
  `origin/main`; Node v24.21.0; `npm run check` typecheck clean, **122/122**; no `.env` (D15).
  Phase 2 runbook archived to `docs/runbooks/2026-10-14-overnight.md`. Michael's §11 answers
  folded into design §12 as D20–D24: threads optional and song-based (brainstorm order),
  graphs = threads + songs with induced pathways, T2 dropped, T6 = graph ↔ Navidrome.
  Naming brainstorm in `docs/naming-options.md`. Commit `OVERNIGHT-3: runbook`. Next: wait for
  Michael's `/loop`; then M0's last box and T0.
- _(the overnight session starts here)_
