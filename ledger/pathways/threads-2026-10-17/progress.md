# Progress — run `threads-2026-10-17` (branch `harness/threads-2026-10-17`)

This is the run's log. **Newest entry first.** Every session adds one entry at the top
(`### 2026-10-17 · T4-08 · passes
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

### <date time> · <feature id> · passes|not yet`, then 3–8 lines). Michael reads this on his phone.

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
