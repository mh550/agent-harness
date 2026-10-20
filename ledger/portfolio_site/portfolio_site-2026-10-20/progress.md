# Progress log: run `portfolio_site-2026-10-20` (Voice Concierge page)

What this file is: the shared memory of this run. Every session reads it at startup and appends its own entry at
the top (newest first) when it finishes: feature id, what landed (files, tests before → after), what it learned,
and anything the next session must know. Keep entries short; put detail in the milestone's plan file.

How to read the feature list (`feature_list.json`, same folder): array order is priority order; a session gets the
first feature whose `passes` is false and whose `after` (feature or milestone ids; by default everything before it)
all pass. A session changes only its own feature's `passes`. Steps are what the verifier re-runs, one evidence row
per step; the last step is always the suite.

How Michael steers: `INBOX.md` in this folder. First line `status: run | pause | stop`; answers to the questions
below go under `## Answers`. The harness pulls before every session; read the Answers before building.

---

### 2026-10-20 verify VC3 · verify VC3

All 5 features hold (26 steps). Note: spec decision ids D43-45 were renumbered (D43-D49) because /talk took them; content is recorded.

| Feature | Step | What you ran or read | What you saw | Holds |
|---|---|---|---|---|
| VC3-01 | 1 | Read docs/notes/evidence-voice-concierge.md; grep Status/latency/1.8 | Source commit d3a9922, Status line quoted with 10-20 00:30 revision; 'Measured numers: none yet'; livekit-agents 1.8 maps onto 2.0; memory practices, mapping table with § refs present | yes |
| VC3-01 | 2 | Read plan sections + projects.ts entry via tsx | Plan has entry draft; entry: 64-char title, ai/systems, featured, order 5, no metrics, Oct 2026, 5 method steps, 6 decisions, lessons [], iterations undefined, /talk demo first, GitHub repo link (gh says PUBLIC) | yes |
| VC3-01 | 3 | Read plan § Diagram, /card link, Navbar, Tests that change | All four sections present (diagram, /card link, Navbar, tests) | yes |
| VC3-01 | 4 | case-study-voice-concierge.test.ts digit rule; grep TODO/[X] in plan | Test green; 0 TODO/[X] hits | yes |
| VC3-01 | 5 | /home/mh550/projects/agent-harness/lib/check.sh | check: green (cached for this tree); also ran full jest: 74 suites, 986 tests pass | yes |
| VC3-02 | 1 | Read entry; ran case-study-voice-concierge.test.ts + data.test.ts | Pass (13-suite subset 313 tests); entry values as listed; order map asserted in data.test.ts | yes |
| VC3-02 | 2 | Read docs/notes/voice-concierge-todo.md | Names metrics array, latency_report.py p50/p95, evidence note, opengraph Latin-glyph test | yes |
| VC3-02 | 3 | npx jest opengraph-image, project-metadata, case-study-data, claims-on-linked-page, card, home, project-page-unchanged | All pass; getTopProjects order unchanged (orders 1,2,3 = agent-harness, linear, home-media) | yes |
| VC3-02 | 4 | curl localhost:7832/projects/voice-concierge; grep; a11y-new-pages.test.tsx | HTTP 200; Key Decisions, Outcome, Links, Talk to my concierge, How it was built present; 5 method labels via test; a11y list line 28 has the slug | yes |
| VC3-02 | 5 | grep D4x in v2 spec | Order decision recorded as default (D-number renumbered, since D43-45 were taken by /talk; noted in spec) - content holds | yes |
| VC3-02 | 6 | check.sh + node .harness/smoke.mjs | Green; smoke PASS all routes incl. /projects/voice-concierge @1280/@390 and /talk | yes |
| VC3-03 | 1 | Read diagrams/index.tsx; ProjectDiagram.test.tsx | Component with Panels (browser, LiveKit Cloud, home box), md:flex ratios, aria-label names browser/token/LiveKit/worker/SQLite; tests pass; measured stacked 300px at 390, side by side at 1280 | yes |
| VC3-03 | 2 | Read src/app/card/page.tsx:58; card.test.tsx | Link href /talk 'Talk to my concierge' w-full under row; test passes (3 /projects links, 2 blank) | yes |
| VC3-03 | 3 | git diff vs main on Navbar.tsx; Navbar.test.tsx | No diff; test passes; spec records Navbar-stays decision (D49) | yes |
| VC3-03 | 4 | grep talk sitemap.ts smoke-routes.txt; sitemap-robots test | Both list /talk; voice-concierge via projects; robots disallows only /evidence,/card/qr; test passes | yes |
| VC3-03 | 5 | check.sh + smoke | Green / all PASS | yes |
| VC3-04 | 1 | ls -la docs/screenshots/v2/VC3-* | 3 files present: 228836, 270772, 41379 bytes (all <400KB) | yes |
| VC3-04 | 2 | Own Playwright script at 390/1280 on both pages | scrollWidth 390 / 1280; panels x45 width 300 stacked at 390, side by side at 1280 (x305/598/813); /card h1 bottom 200, Save contact 384, Talk 496 <844; 0 console/page errors | yes |
| VC3-04 | 3 | node .harness/print-check.mjs ... /projects/voice-concierge | PASS print, exit 0 | yes |
| VC3-04 | 4 | Read plan § What Michael will see | One row per screenshot (3 rows) with on-screen and wrong columns | yes |
| VC3-04 | 5 | check.sh | green | yes |
| VC3-05 | 1 | Read plan § Fact-check and § Review headings/tables | Both sections present; no Critical/Important; fact-check softened claims | yes |
| VC3-05 | 2 | Read plan § Design pass | Present, PASS recorded; h3 count 11 on page, links/focus asserted by tests | yes |
| VC3-05 | 3 | grep review-guide, asset-checklist, CLAUDE.md, README; jest --silent | VC3 entry and Voice Concierge section exist; counts 986 tests/74 suites match CLAUDE.md | yes |
| VC3-05 | 4 | npx jest content-guard, claims-on-linked-page, opengraph-image | pass (inside 313-test run) | yes |
| VC3-05 | 5 | check.sh + smoke | green; smoke all PASS | yes |

### 2026-10-20 08:30 · VC3-05 · passes

- Fact-check (Opus, agent repo `main` at `8bf3f64`, C3 of C8, README "Being built"): 9 claims softened, 1 cut. The outcome no longer says the agent "was built" or that a demo happened ("The agent is still being built."); shortDescription, approach, method.build, builtWith and the diagram caption now state the agent as design; brief § Sentences with digits rows replaced. New test group "claims match what is built". Tests 982 → 986, suites 74.
- Review (Opus): no Critical/Important. Applied: one-list `PanelConnector` via `Arrow dir="responsive"`, ↕/↔ for the two-way streams, `Panel` class join, test titles, ProjectsGrid excludes voice-concierge by slug, dropped exact flex-ratio asserts. Design pass (Sonnet): headings, focus rings, link text, diagram contrast (lowest 4.75:1) all PASS, nothing to fix. Plan gains § Fact-check, § Review, § Design pass; VC3 captures retaken (223/264/40 KB).
- Hand-off: review-guide VC3 entry, asset-checklist § Voice Concierge (20 s memory-panel recording → `public/projects/voice-concierge/`), CLAUDE.md route row + 986/74, README line on /talk.
- Verified: check.sh green; jest 986/74; content-guard + claims + opengraph 77/77; smoke 42 PASS; print PASS.
- Proposed change: VC2's `/talk` copy (`src/lib/data/concierge.ts` `talkPage`) still says "a voice agent I designed and built… It remembers you between visits"; outside VC3's diff, so left. Soften it, or leave it as the live page's copy once the agent runs?
- Question for Michael (still open): is order 5 right for the deep-dive? Re-read the deep-dive once the agent run finishes; if it ships the timer and extraction, "designed to" can become plain past tense.

### 2026-10-20 07:50 · VC3-04 · passes

- New captures `docs/screenshots/v2/VC3-voice-concierge-390.png` (221 KB), `-1280.png` (260 KB), `VC3-card-390.png` (40 KB), 256-colour PNGs from `$HARNESS_SCRATCH/vc3-shots.mjs` (reduced motion, scrolled first). VC3 plan § What Michael will see filled (measurements + one row per screenshot). No code change; tests 982 → 982, suites 74.
- Measured: deep-dive scrollWidth 390 at 390; diagram panels stacked at 390 (x 45, width 300 each, y 1180/1543/1764), side by side at 1280 (y 962, widths 197/119/162); `/card` at 390×844 h1 bottom 200, Save contact 384, Talk to my concierge 496; 0 console/page errors on both pages at both widths. Print check `PASS print`, exit 0. Smoke 42 PASS; check.sh green; jest 982/74.
- Nothing looked wrong enough to fix; two minor notes in the plan table (token sub-line orphan, short decision titles sit beside their badge in the shared DecisionLog).
- Proposed changes: step 2's "each panel's boundingBox width above 300 px" can't hold: 300 is the figure's content box (342 − 2 border − 2×20 padding), so the panels are full width; read as ≥ 300.
- Next (VC3-05): the diff for review starts at the parent of `ade5c9f` (VC3-01).

### 2026-10-20 07:20 · VC3-03 · passes

- `DiagramKey` + `VoiceConciergeDiagram` in `diagrams/index.tsx` (three panels, five nodes, labelled arrows; a small `PanelConnector` draws each arrow down below md and right from md; `Panel` gains an optional `className` for flex ratios). The entry sets `architectureDiagram: 'voice-concierge'`. `/card` gains "Talk to my concierge" under the LinkedIn/Email/GitHub row. v2 spec D48 (card placement) and D49 (Navbar unchanged). Tests 959 → 982, suites 74.
- Verified: check.sh green; jest 982/74; smoke 42 PASS. Playwright: at 390 panels stacked (300 px wide each, scrollWidth 390); at 1280 side by side (197/119/162 px), arrows → and level with the first nodes; /card at 390: h1 ends at 200, Save contact at 384, Talk at 496; 0 console/page errors. Live sitemap lists /talk and /projects/voice-concierge; robots disallows only /evidence and /card/qr.
- Opus review applied: connector centred on the tallest panel → `md:self-start md:mt-10`; panels squeezed to ~100 px → `md:w-20` connectors + flex ratios; Room sub "one per visit" → "one per session" (the token route names a new room on every Connect; plan updated). Not applied (minor): "both ways" stays in the aria-label only, as the plan says.
- VC3-04: the 390 panels measure exactly 300 px; its step says "above 300 px", so read it as ≥ 300 or measure at the panel's border box. Scroll before full-page captures (ScrollReveal).
- Proposed changes: steps 2–3 name D45/D43 (taken); recorded as D48/D49, as the plan said.

### 2026-10-20 06:40 · VC3-02 · passes

- `projects.ts` gains the voice-concierge entry from the plan (after hit-list, order 5; ghl…cherished shift to 6–10; no metrics, no diagram yet). New `case-study-voice-concierge.test.ts` (shape, six practices, /talk demo + public repo link, digit sentences verbatim in the brief, never-publish strings); `data.test.ts` (10, order map), `case-study-types`, `ProjectsGrid` (Systems filter, no-metric band shows `ai`), `a11y-new-pages` updated. New `docs/notes/voice-concierge-todo.md`; v2 spec `D47 *default*` (order). Tests 942 → 959, suites 73 → 74.
- Agent repo read (public `main`, `53beb41`, C2 merged: store, erasure, TTL, worker, dispatch in the tree; README "Being built"). Its `docs/decisions.md` moved every LLM call to the **Anthropic API** (OpenRouter only a fallback), so techStack says `Anthropic API`, not `OpenRouter`; brief § Providers and the plan updated with the source. `gh repo view` still PUBLIC.
- Verified: check.sh green; jest 959/74; the step-3 jest list green, `getTopProjects(3)` unchanged; `curl /projects/voice-concierge` 200 with the five method labels, Key Decisions with VC-A…VC-F, Outcome, Links, "Talk to my concierge", "How it was built"; smoke 42 PASS incl. the new slug at 1280 and 390.
- Next (VC3-03): add `architectureDiagram: 'voice-concierge'` with the DiagramKey. The smoke 390 capture shows the body blank below the header, as on hit-list: ScrollReveal content outside the viewport, not a bug; VC3-04 must scroll before its full-page capture.
- VC3-05 fact-check: the outcome says the agent "was built" overnight; the agent run was at C2 of C8 when this landed. Re-read its README before the morning.
- Proposed changes: step 5 names D44 (taken); recorded as D47, as the plan said. The plan's test table missed `ProjectsGrid`'s Systems filter test (now noted there).
- Question for Michael: is order 5 right for the deep-dive? (INBOX `## Answers`.)

### 2026-10-20 05:40 · VC3-01 · passes

- New `docs/notes/evidence-voice-concierge.md` (facts with agent-spec § / D / B refs, Status line quoted from `d3a9922`, "no latency numbers measured yet", 1.8 only maps onto 2.0, § Sentences with digits) and `docs/plans/2026-10-20-VC3-voice-concierge-deep-dive.md` (the whole entry as final TS, order, diagram node list + aria-label + caption, `/card` button, Navbar, tests that change, traceability, brand check, risks). Plan only, no code; tests 942 → 942.
- Verified: a script evals the plan's TS entry and splits every string into sentences: all 9 digit-bearing pieces are verbatim in the brief, title 64 chars ASCII, 6 decisions, no `.config/`/`CONCIERGE_`/`API_KEY`/TODO/`[X]`. An Opus fact-check found 4 Important (Forget me privacy overclaim, 2.0 "one memory per person", idle-TTL "across days", design stated as built) + Minor grammar: all applied. check.sh green; jest 942/73; smoke all PASS.
- Repo `mh550/voice-concierge` printed PUBLIC, so the entry links it. INBOX Answers empty → order 5 default (ghl…cherished shift by one; top 3, /card and home unchanged).
- Next session (VC3-02): paste the entry, but first read the agent repo's README/decisions (its `main` held only the spec at plan time) and soften if the agent isn't built. `ProjectsGrid.test.tsx` "every case study shows a metric" must change (no metrics here); `architectureDiagram` waits for VC3-03.
- Proposed changes: VC3-02 step 5 / VC3-03 steps 2–3 name D44, D45, D43, already used by VC1/VC2. The plan records them as D47 (order), D48 (card button), D49 (Navbar, restating D44); please read those steps that way. The diagram's panel A is "Visitor's browser and this site" (the token route is server-side) and panel C "My home box".
- Question for Michael: is order 5 right for the deep-dive (after the four measured case studies)? Answer under INBOX `## Answers`.

### 2026-10-20 05:00 · verify VC2

| Feature | Step | What you ran or read | What you saw | Holds |
|---|---|---|---|---|
| VC2-01 | 1 | Read plan § Files, § State machine, § Layout | File table lists every named file; state diagram idle→connecting→waiting→live, offline from 503/fetch/10 s; layout at 390/1280 with a table of block ends above 844 px | yes |
| VC2-01 | 2 | grep plan for each LiveKit signature and attribute name | constructor, registerTextStreamHandler, readAll, sendText, PerformRpcParams, setMicrophoneEnabled, ParticipantConnected/Disconnected, ParticipantKind, remoteParticipants, startAudio, canPlaybackAudio, RoomContext, RoomAudioRenderer, useChat throw note, lk.segment_id/transcription_final/transcribed_track_id all present | yes |
| VC2-01 | 3 | Read plan § Jest vs jest.config.ts lines 13-14 | mapper entries for both packages (plan line 430 quotes them), fake timers, fetch mock, 'no test opens a connection' present | yes |
| VC2-01 | 4 | Read plan § Copy | offline sentence, button labels, six privacy points, latency labels, empty states listed | yes |
| VC2-01 | 5 | grep plan/spec for D42-D46 | Plan names the token-test, chrome/indexable/off-Navbar (renumbered D44 in spec since D43 was taken), visitor id in click handler (D45), no components-styles; wording matches step intent | yes |
| VC2-01 | 6 | `/home/mh550/projects/agent-harness/lib/check.sh` | green (cached, same tree); full jest rerun 942 pass / 73 suites | yes |
| VC2-02 | 1 | Read concierge-contract.test.ts; `npx jest src/__tests__/components/talk src/__tests__/lib/concierge… pages/talk` | parseMemory/parseMetrics fixtures and null-on-bad cases pass | yes |
| VC2-02 | 2 | concierge-latency.test.ts | median 120/100/null and cachedShare cases pass | yes |
| VC2-02 | 3 | concierge-visitor-id.test.ts | persistence, malformed, throwing storage, newUuidV4 pass | yes |
| VC2-02 | 4 | concierge-data.test.ts | six privacy points by keyword, no http/.net/digits; offline sentence exact (line 21 region) pass | yes |
| VC2-02 | 5 | check.sh + full jest | green; 942 pass | yes |
| VC2-03 | 1 | MemoryPanel.test.tsx | passes with fixtures and empty case | yes |
| VC2-03 | 2 | LatencyPanel.test.tsx | passes; null renders en dash, no NaN/null | yes |
| VC2-03 | 3 | Transcript.test.tsx | passes; aria-live polite, non-final marked | yes |
| VC2-03 | 4 | ForgetMeButton.test.tsx | passes; confirm, Erase once, Cancel, busy | yes |
| VC2-03 | 5 | jest talk dir; check.sh | all talk suites pass; check green | yes |
| VC2-04 | 1 | Read page test/sitemap/smoke-routes/a11y test; jest pages/talk | `/talk` in smoke-routes.txt, sitemap.ts, sitemap-robots (9, 9+projects), a11y-new-pages; metadata+one h1 test passes | yes |
| VC2-04 | 2 | TalkSession.test.tsx lines 96, 125, 140 | 503 and rejection show offline + link; id sent equals stored id on second Connect | yes |
| VC2-04 | 3 | TalkSession.test.tsx 177-198 (invocationCallOrder < connect), StrictMode | registers precede connect; unmount = unregister + disconnect once; StrictMode ok | yes |
| VC2-04 | 4 | TalkSession.test.tsx 376-399 | 10_000 ms constant, 9_999 no offline, +1 offline; agent at 3_000 ms cancels and goes live | yes |
| VC2-04 | 5 | TalkSession.test.tsx 453-469 | memory and metrics render; malformed changes nothing, console.error not called | yes |
| VC2-04 | 6 | `grep -rl livekit-client src/app`; jest.config.ts; server.log | grep empty; mapper lines present; dev log has 0 'hydrat'/'warn' after 5 GET /talk | yes |
| VC2-04 | 7 | `curl` status in Playwright run; smoke.mjs | /talk 200; smoke all PASS incl /talk 1280+390; check green | yes |
| VC2-05 | 1 | TalkSession-live.test.tsx 54-90; src data micBlocked | setMicrophoneEnabled true/false; NotAllowedError shows 'Microphone blocked. You can still type.' and stays live | yes |
| VC2-05 | 2 | live test 111-131 | Enter/Send via sendText lk.chat, visitor line, box cleared, whitespace ignored | yes |
| VC2-05 | 3 | live test 182-195 | two chunks of one segment give one final line | yes |
| VC2-05 | 4 | live test 226-266; TalkSession.tsx:363-367 | performRpc once with method concierge.forget_me, responseTimeout 10000; ok clears + Forgotten; rejection re-enables + error | yes |
| VC2-05 | 5 | live test 326-390 | RoomAudioRenderer in RoomContext.Provider; startAudio when blocked; Leave returns idle, panels cleared | yes |
| VC2-05 | 6 | check.sh; smoke.mjs | green; all routes PASS | yes |
| VC2-06 | 1 | `ls -l docs/screenshots/v2/VC2*` | three PNGs exist, 39.6/52.6/42.2 KB (<400 KB); offline capture shown by plan row | yes |
| VC2-06 | 2 | Own Playwright script at 390×844 with no LiveKit env | h1 ends 302, Connect 664 (<844); offline sentence 700, link 747; scrollWidth 390 idle and offline; 0 console/page errors; no /api request | yes |
| VC2-06 | 3 | Same script, Tab sequence at 390 and 1280 | Skip to content → MH → nav links (Open menu at 390) → Connect; each :focus-visible with outline rgb(0, 212, 255) (read after 300 ms) | yes |
| VC2-06 | 4 | Read plan § What Michael will see | table has a row per screenshot with state, contents, issues; D46 fix noted with tests | yes |
| VC2-06 | 5 | check.sh | green | yes |
| VC2-07 | 1 | Read plan § Review | Review table with file/finding/severity/outcome; Critical/Important fixed with tests in TalkSession-review.test.tsx (passes); simplifications listed | yes |
| VC2-07 | 2 | Read plan 'Checks' table; own grep for ts.net/CGNAT/ntfy over talk dirs; offline browser run | StrictMode, release, no-RSC-import, offline-console evidence named with tests that pass; my grep empty; offline console clean | yes |
| VC2-07 | 3 | Read docs/review-guide.md 65-106 | VC1–VC3 section: merge order, 390 look, 'Morning: the live check', env vars, undo via env removal / kill switch | yes |
| VC2-07 | 4 | Read CLAUDE.md Routes/Components/Testing; jest tail | /talk, components/talk, lib/concierge, mocks+mapper documented; 942 tests / 73 suites matches my run | yes |
| VC2-07 | 5 | check.sh; smoke.mjs | green; all routes PASS | yes |

### 2026-10-20 04:10 · VC2-06 · passes

- **Changed:** the verifier failed step 2 (offline Connect logged Chromium's "Failed to load resource … 503" console error). Fixed test-first, recorded as **D46** *default*. New `src/lib/concierge/env.ts` `conciergeEnv()` is the one LiveKit env check, used by the token route (unchanged behaviour, 503 without env) and by `/talk`'s page, which passes `TalkSession configured={…}`. Without the env, Connect goes offline at once: no fetch, no LiveKit import, no visitor id stored. Tests 933 → 942, suites 72 → 73 (`lib/concierge-env.test.ts`, plus new cases in `TalkSession.test.tsx` and `pages/talk.test.tsx`). Also updated: the plan (§ What Michael will see and the state table), review-guide morning step 2 (the redeploy also rebuilds `/talk`), and CLAUDE.md.
- **Verified:** I retook the captures (Sonnet subagent, `vc2-shots.mjs`, :7832, no env); the files are byte-identical at 39/51/41 KB. At 390×844 the h1 ends at 300 and Connect at 664; offline, the sentence ends at 700 and the link at 747. `scrollWidth` is 390 idle and offline. **0 console and 0 page errors in both states, no `/api` request.** My own spot check (`$HARNESS_SCRATCH/vc206-check.mjs`) agrees. Every Tab stop shows a 2 px `rgb(0, 212, 255)` outline at 390 and 1280. `check.sh` green; smoke exit 0. An Opus review found no Critical or Important issues; I fixed one Minor (the page test now clears localStorage).
- **Next session must know:** `/talk` is prerendered, so `configured` is fixed at build. Adding the env on Vercel needs a redeploy, which Vercel needs for env changes anyway.
- **Question for Michael:** D46: OK to skip the token request when the server has no LiveKit env? Undo: drop the prop (it defaults to `true`).
- **Proposed (Minor, not done):** add `import 'server-only'` to `env.ts`. This needs the `server-only` package, a new dependency, so it needs your OK. Also assert in a test that `livekit-client` is never imported on an unconfigured Connect.

### 2026-10-20 03:40 · VC2-01 · passes

- **Changed:** `docs/plans/2026-10-20-VC2-talk-page.md` 223 → 738 lines. VC2-05's commit (409bc23) had cut the plan from 595 to 148 lines. I restored § Layout, LiveKit calls, Jest, Contract types, Copy, Decisions, Tests per feature and Risks from 049f6a6, then corrected them to the code as built. Changes: the `import('livekit-client')` + `next/dynamic` RoomAudio calls, 5 room listeners incl. `Reconnected`, `isForgotten`, the measured fold numbers at 390, the copy now matching `concierge.ts`, `Room.setup`/`restart` in the mock, `utf8Bytes` rather than `TextEncoder`, fake timers with `fireEvent`. No code change; tests unchanged at 933/72.
- **Verified:** I re-grepped every quoted signature in `node_modules` (livekit-client 2.23.0, components-react 2.9.24, components-core 0.12.15, still exact) and grepped the plan for each step's terms. An Opus review checked each quote and claim against the source: 2 wrong, 3 overstated, all fixed. `check.sh` green; smoke 40/40.
- **Next session must know:** don't rewrite this plan wholesale. Append "As built" notes instead; the verifier greps it.
- **Proposed change (VC2-01 step 5):** it names the `/talk` chrome decision D43, but VC1-03 took D43 (lower-cased ids). It is recorded as D44 and the visitor id as D45; the plan says so. Suggested wording: "D44 (/talk keeps the site chrome…)".

### 2026-10-20 verify · verify VC2

| Feature | Step | What you ran or read | What you saw | Holds |
|---|---|---|---|---|
| VC2-01 | 1 | read `docs/plans/2026-10-20-VC2-talk-page.md` (223 lines, 5 sections) | file table, component tree and state machine present; the "Layout" section (order, what is above 844 px) is gone; it had 13 sections at b55f3ce (590 lines), 5 at HEAD (a later commit deleted 459 lines) | no |
| VC2-01 | 2 | grep the plan for registerTextStreamHandler, TextStreamReader, PerformRpcParams, ParticipantKind, lk.segment_id, lk.transcribed_track_id | no "LiveKit calls" section and no quoted signatures; line 10 refers to a § that does not exist; lk.* attributes unnamed | no |
| VC2-01 | 3 | grep the plan for moduleNameMapper, fake timers, Jest section | no Jest section in the plan (deleted); the mapper is only in jest.config.ts and the mocks exist | no |
| VC2-01 | 4 | grep the plan for the copy list (Erase, Cancel, six privacy points) | no Copy section in the plan (deleted); copy exists only in src/lib/data/concierge.ts | no |
| VC2-01 | 5 | grep the plan for D42, D43, components-styles; grep spec | no "Decisions to record" section in the plan; D42–D45 are in the v2 spec (lines 161–173) | no |
| VC2-01 | 6 | `check.sh` | green (6 tests, cached for this tree) | yes |
| VC2-02 | 1 | `npx jest src/__tests__/lib/concierge-contract.test.ts` and read it | pass; fixtures parse; non-JSON returns null without throwing (tests listed in verbose run) | yes |
| VC2-02 | 2 | `npx jest src/__tests__/lib/concierge-latency.test.ts` | pass; "gives the last value and the running median…", "even-count median is the mean of the two middles", "cached_tokens / prompt_tokens rounded to 2 decimals" | yes |
| VC2-02 | 3 | `npx jest src/__tests__/lib/concierge-visitor-id.test.ts` | pass; stores under concierge.visitor_id, persists across two calls, replaces malformed, getItem/setItem throwing and blocked storage give a valid id | yes |
| VC2-02 | 4 | `npx jest src/__tests__/lib/concierge-data.test.ts`; read lines 44–67 | pass; privacyNote length 6, destructured by keyword (what/where/how long/id/forget/livekit); no `http`; offline sentence exact; deep-dive link asserted | yes |
| VC2-02 | 5 | check.sh; `npx jest --silent` | green; 72 suites, 933 tests pass | yes |
| VC2-03 | 1 | `npx jest src/__tests__/components/talk` MemoryPanel tests | pass: "a new visitor", visit count, name, "Nothing remembered yet" for empty | yes |
| VC2-03 | 2 | LatencyPanel.test.tsx | pass: full turn with medians and cached share; last turn beside the median; null renders an en dash | yes |
| VC2-03 | 3 | read Transcript.tsx lines 14–60 and Transcript.test.tsx | role log with aria-live="polite", aria-busy for non-final, non-final line italic and marked; tests pass | yes |
| VC2-03 | 4 | ForgetMeButton.test.tsx | pass: confirm on first click, Erase once even on a double click, Cancel returns. Busy now uses aria-disabled, not `disabled` (VC2-07 focus fix); behaviour is still blocked while busy | yes |
| VC2-03 | 5 | grep focusRing/h2 in talk components; jest talk dir; check.sh | focusRing imported in Transcript, ForgetMeButton and the others; talk suites pass; check green | yes |
| VC2-04 | 1 | read page.tsx; grep smoke-routes, sitemap.ts, sitemap-robots test, a11y-new-pages test | metadata title and description right; /talk in all four; both counts 9 (+projects); a11y list has /talk; talk.test.tsx passes | yes |
| VC2-04 | 2 | TalkSession.test.tsx | pass: 503, other non-OK, fetch rejection and 200 without url/token show the offline line plus the deep-dive link; POSTs the stored visitor id; storage-throws case | yes |
| VC2-04 | 3 | TalkSession.test.tsx | pass: handlers registered before connect; unmount gives 3 unregisters and 1 disconnect; StrictMode registers each topic once | yes |
| VC2-04 | 4 | TalkSession.test.tsx fake timers | pass: offline 10000 ms after connect() resolves; agent at 3000 ms cancels the timer and goes live | yes |
| VC2-04 | 5 | TalkSession.test.tsx | pass: memory body renders in the panel, metrics in the latency panel, malformed body changes nothing and logs no console.error | yes |
| VC2-04 | 6 | jest.config.ts lines 13–14; `grep -rl livekit-client src/app`; `grep -ciE hydrat server.log` | both mappers present; grep empty; 0 hydration lines in the dev server log | yes |
| VC2-04 | 7 | `node .harness/smoke.mjs`; `curl -w %{http_code} /talk` on :7832; check.sh | PASS /talk @1280 and @390, 0 failures; curl prints 200; check green | yes |
| VC2-05 | 1 | TalkSession-live.test.tsx | pass: mic on and mute/unmute; NotAllowedError shows the blocked message and the session stays live with typing on | yes |
| VC2-05 | 2 | TalkSession-live.test.tsx, review test | pass: Enter sends on lk.chat, line appended as visitor, box cleared; whitespace ignored; double Enter sends once | yes |
| VC2-05 | 3 | TalkSession-live.test.tsx | pass: two streams with one lk.segment_id give one line, lk.transcription_final marks it final | yes |
| VC2-05 | 4 | TalkSession-live.test.tsx; read TalkSession.tsx lines 361–365 | performRpc called once with method, payload and responseTimeout FORGET_TIMEOUT_MS (10 s); {ok:true} clears memory and shows Forgotten; failure path tested | yes |
| VC2-05 | 5 | read RoomAudio.tsx; tests | RoomContext.Provider with RoomAudioRenderer; startAudio retried on user gestures; Leave tests pass; no animation added | yes |
| VC2-05 | 6 | check.sh; smoke | green; every route PASS | yes |
| VC2-06 | 1 | `ls -la docs/screenshots/v2 | grep talk` | VC2-talk-390.png 39 KB, -1280 52 KB, -offline-390 42 KB, all under 400 KB. Not retaken by me (the live offline sentence was seen through my own Playwright run below) | yes |
| VC2-06 | 2 | own Playwright script at 390×844 against :7832 | h1 bottom 303, Connect bottom 664 (both <844); scrollWidth 390 idle and offline; 0 page errors; idle 0 console errors, but offline logs 1 console error ("Failed to load resource … 503") so "0 console errors in either state" does not hold as written (the plan admits it) | no |
| VC2-06 | 3 | Playwright Tab loop at 1280×800, 350 ms wait per stop | Skip to content, MH, Home…Contact, Connect in that order; each is :focus-visible with outline rgb(0, 212, 255) solid | yes |
| VC2-06 | 4 | read plan § What Michael will see | three rows, one per screenshot, with the three columns; no layout bug listed | yes |
| VC2-06 | 5 | check.sh | green | yes |
| VC2-07 | 1 | read plan § Review | two tables with file, finding, severity, outcome; Important items marked fixed with test names; TalkSession-review.test.tsx passes | yes |
| VC2-07 | 2 | read plan § Review checks; ran StrictMode tests; the grep | StrictMode tests pass; release tests pass; no server import of livekit; offline path checked in my Playwright run; ts.net/CGNAT/ntfy grep empty | yes |
| VC2-07 | 3 | `grep -n` docs/review-guide.md | "VC1–VC3: Voice Concierge" at line 65 and "Morning: the live check" at line 84 | yes |
| VC2-07 | 4 | grep CLAUDE.md; `npx jest --silent` | /talk row, talk and lib/concierge lines, mocks documented; counts 933 tests / 72 suites match the run | yes |
| VC2-07 | 5 | check.sh and smoke | green; all routes PASS | yes |

### 2026-10-20 02:15 · VC2-07 · passes

- **Changed:** Opus review of all of VC2 (`git diff d4c7d58..HEAD`), with a § Review table in `docs/plans/2026-10-20-VC2-talk-page.md`. **Important, fixed test-first:** (1) Connect and Leave are now one button, so focus survives every phase change; Forget me uses `aria-disabled`, and focus goes to Connect when a call ends. (2) LiveKit is out of `/talk`'s first load: `import('livekit-client')` on Connect plus the new `RoomAudio.tsx` via `next/dynamic`; the 151 KB gz chunk is gone from the page manifest. Also fixed: double-click and held-Enter guards, failed send keeps the draft, double Enter sends once, the draft is cleared per session, reconnect without the agent ends the call, "Connect again to retry" copy, no `@/lib/data` barrel in talk files. Simplified: reducer `agentIdentity`, `session.forgetting`, `release()`, `inRoom`, `TURN_PATH_FIELDS`. Tests 916 → 933, suites 71 → 72 (new `TalkSession-review.test.tsx`).
- **Docs:** `docs/review-guide.md` § VC1–VC3 (merge order, what to look at at 390, the morning live check, undo). CLAUDE.md gains the talk/RoomAudio, `lib/concierge/` and LiveKit-mock lines, plus the counts.
- **Verified:** `check.sh` green (`.harness/check.sh` run directly: 933 tests, lint, build); smoke 40/40. The new StrictMode test shows one 10 s timer and 1 listener per event, with all released on unmount. Mutation runs turn the timer, focus, double-click and Enter-repeat tests red. Leak grep empty. Chromium (Sonnet) at 390/1280: Enter on Connect gives the exact offline line with focus kept on Connect, 0 page errors, `scrollWidth` 390, and LiveKit is fetched only after Enter. A second Opus pass over the fixes found 1 Important (double Enter) and 3 Minors; all fixed. I looked at the 390 capture.
- **Left (Minor, in the table):** the mic label ignores device or server mutes; a mic prompt granted after Leave keeps LiveKit's track for up to 15 s.
- **Next (VC3):** `/projects/voice-concierge` is still a 404 from the offline link.
- **Proposed change (harness):** `lib/check.sh` reports "6 tests" for this project. It reads Jest's `Snapshots: 6` line, not `Tests: 933`.

### 2026-10-20 03:05 · VC2-06 · passes

- **Changed:** three captures in `docs/screenshots/v2/` (`VC2-talk-390.png` 39 KB, `VC2-talk-1280.png` 51 KB, `VC2-talk-offline-390.png` 41 KB, all full page) and the plan's new § What Michael will see (numbers + one row per capture). No code changes: no layout bug found. Tests unchanged at 916/71.
- **Verified** (script `$HARNESS_SCRATCH/vc2-shots.mjs`, port 7832, no LiveKit env): at 390 × 844 the h1 ends at 300 px and Connect at 664. Offline, the sentence ends at 700 and "Read how it works" at 747, all above the fold. `scrollWidth` is 390 idle and offline. 0 page errors; Tab goes Skip → MH → Navbar (Open menu at 390) → Connect, every stop `:focus-visible` with a 2 px `rgb(0, 212, 255)` outline. `check.sh` green; smoke 40/40. I looked at all three captures.
- **Gotcha for later checks:** Tailwind 4's `transition-colors` also fades `outline-color`. Reading it right after Tab gives the text colour (mid-fade), so wait about 300 ms first.
- **Next session must know:** the offline link `/projects/voice-concierge` 404s until VC3-02 builds the deep-dive. VC3-04 should click it.
- **Proposed change (VC2-06 step 2):** offline has exactly one console line, Chromium's own `Failed to load resource: … 503` for the token POST. W1 requires the 503 and page code can't silence it, so I counted it apart from app errors (0). Suggested step wording: "0 console errors other than the browser's network line for the 503 token POST".

### 2026-10-20 02:45 · VC2-05 · passes

- **Changed:** `TalkSession.tsx` now has the mic toggle (it turns on after `connect()`), `MessageBox.tsx` (new, `lk.chat`), the Forget me RPC (`isForgotten()` in `contract.ts`), `RoomContext.Provider` + `RoomAudioRenderer`, `startAudio()` and a **Turn on sound** button from `AudioPlaybackStatusChanged`. `sessionReducer` gains `micOn/micBlocked/audioBlocked/forget`. New `TalkSession-live.test.tsx` (33 tests); the components-react mock records its context room. Tests 860 → 916, suites 70 → 71.
- **Verified:** `check.sh` green; smoke 40/40. Smoke first caught a 12 px horizontal scroll at 390: the grid had no column below `lg`, so it grew to the input's intrinsic width. Fixed with `grid-cols-1`; `scrollWidth` is now 390. `curl /talk` gives 200 with the message box in the server HTML, and the dev log is clean. I looked at the 390 screenshot.
- **Review (Opus):** 0 Critical, 3 Important, all fixed test-first: (1) overlapping mic presses (`micWanted` + `micSeq`; only the newest answer is shown); (2) LiveKit sets `canPlaybackAudio` false only after a refused `play()`, so the after-connect check alone almost never fires: added the event listener and the button; (3) the old-session Forget me test didn't exercise the guard: added Erase A → Leave → Connect B → Erase B → A's reply. A mutation run shows it fails without the guard. Minor fixed: a second RPC while one is in flight sends nothing.
- **Left for VC2-07 (Minor):** a failed `sendText` still shows the typed line; focus falls to `<body>` when the agent ends the call after Forget me; the mic label ignores track mutes from the device; the draft survives Leave; a failed RPC after the call drops shows "try again" with no button until you reconnect.
- **Question for Michael:** the mic is turned on as soon as the room connects, while waiting for the agent (as the plan says). If the concierge is offline, visitors get a mic prompt for nothing. Should it wait until the agent joins? That's a one-line move to `agentArrived`.

### 2026-10-20 01:55 · VC2-04 · passes

- **Changed:** new `src/app/talk/page.tsx` (Server Component, no LiveKit import), `src/components/talk/TalkSession.tsx` (Connect → token route → one `Room`, 3 handlers before `connect()`, 10 s agent wait, offline + deep-dive link, teardown on Leave/unmount) and `sessionReducer.ts`. Jest mocks: `src/__mocks__/livekit-client.ts` (`MockRoom.setup`, `pushText`, `addAgent`, `restart`) and `livekit-components-react.tsx`, mapped in `jest.config.ts`. `/talk` is in the smoke routes, the sitemap (9 routes) and the a11y test. Added spec D44/D45 and CLAUDE.md rows. Tests 764 → 860, suites 67 → 70.
- **Verified:** `check.sh` green. Smoke passes 40/40, including `/talk` @1280/@390, and `curl /talk` gives 200. `grep -rl livekit-client src/app` is empty, and the dev log shows no hydration warnings. A Sonnet browser run checked the offline state: clicking Connect gives a POST with a v4 id and a 503, then the exact offline line and the link. A second Connect sends the same id. `scrollWidth` is 390. At 390 the Connect bottom is at 664 px and the link is above the fold. The only console errors are the browser's own "Failed to load resource 503" lines, from the click (smoke doesn't click).
- **Review (Opus):** 2 Important, 3 Minor, all fixed. (1) A full reconnect unwinds every participant (`Room.handleRestarting`) and was ending the call. The agent-left check now runs a microtask later and skips it while `Reconnecting`. (2) Added tests for Leave/unmount during the fetch and during `connect()`, plus server disconnects while live and while waiting. A mutation run confirmed these tests fail when the guards are removed. Minor: `pushText` waits long enough for `for await`; open transcript lines settle on a call's end or on the same speaker's next segment, so the log is never left `aria-busy`; the mock's `disconnect()` emits nothing when already disconnected.
- **Next (VC2-05):** the mic toggle, MessageBox, Forget me RPC, `RoomContext.Provider`, `RoomAudioRenderer` and `startAudio` are not built yet. Mic auto-enable after connect isn't either. The `lk.transcription` handler is built and tested for one segment in two chunks. Under fake timers, click with `fireEvent` and use `flush()` (20 microtasks inside one `act`). With userEvent, React's scheduler is faked and updates never render.
- **Proposed change:** VC2-04 step 2 says `getOrCreateVisitorId(window.localStorage)`. The code uses `browserStorage()` (D45, VC2-02's note), because reading `window.localStorage` throws when storage is blocked. The test still proves that the id sent is the one in localStorage.
- **Question for Michael:** a transcript line is final when its stream closes, unless `lk.transcription_final` is exactly `"false"` (plan § lk.transcription). Please confirm the agent sends `"true"` on its own speech, or nothing.

### 2026-10-20 01:20 · VC2-03 · passes

- **Changed:** new `src/components/talk/{MemoryPanel,LatencyPanel,Transcript,ForgetMeButton,TalkPanel}.tsx` and `format.ts` (en dash for every null), 4 test files in `src/__tests__/components/talk/`, a third metrics fixture `metricsCompacted`, and panel copy (`talkPage.memory`, `talkPage.speakers`, `latencyLabels.turn/yes/no`). Tests 725 → 764, suites 63 → 67.
- **Verified:** `check.sh` green; `npx jest src/__tests__/components/talk` 39/39; smoke 38/38 at start (no page renders these yet, so there are no screenshots until VC2-04). Opus review: 0 Critical, 3 Important, all fixed. Focus is no longer lost after Erase (the test fails without the fix). The transcript log is `aria-busy` while a line is non-final, so partial speech isn't read out. Erase is `bg-red-700` for AA contrast. 6 of 7 Minors fixed: word separators, summary shown without facts, empty name, duplicate fact ids, `useId`, no auto-scroll after the reader scrolls up. Kept the date test on the component's own `Intl` options (the plan's choice).
- **Next (VC2-04/05):** import `TranscriptLine` from `Transcript.tsx`; pass `MessageBox` as `Transcript`'s children. Panel heading ids are fixed (`talk-memory`, `talk-latency`, `talk-transcript`), one of each per page. `ForgetMeButton` gives focus back to Forget me only when `busy` clears. Make the status line ("Forgotten", or the error) a live region in TalkSession.
- **Defaults:** "History compacted" reads Yes if any turn this visit reported `true`. The memory preload is shown once, from the first turn that reported it. Background extraction shows only after some turn reports it.

### 2026-10-20 01:10 · VC2-02 · passes

- **Changed:** new `src/lib/concierge/contract.ts` (§4 types, `TOPIC`, `RPC_FORGET_ME`, `parseMemory`/`parseMetrics`), `latency.ts` (`LATENCY_FIELDS`, `median`, `summarise`, `cachedShare`) and `src/lib/data/concierge.ts` (`talkPage`, `privacyNote`, `latencyLabels`, exported from the barrel). `visitorId.ts` gains `VISITOR_ID_KEY`, `newUuidV4`, `getOrCreateVisitorId` and `browserStorage()`. New fixtures in `src/__tests__/fixtures/concierge.ts` and 3 new test files. Tests 680 → 725, suites 60 → 63.
- **Verified:** `check.sh` green; smoke 38/38; `tsc --noEmit` shows no concierge errors. An Opus review found 0 Critical issues. Fixed 1 Important (`afterEach` returned a value, a TS error) and 4 Minor: lone surrogates now count as 3 UTF-8 bytes, there are tests for 3-byte and 4-byte characters, the fallback test asserts `getRandomValues` ran, and `browserStorage()` handles a throwing `window.localStorage` getter. Not fixed: `turn` accepts 0 (§4 says only int).
- **Next (VC2-04):** call `getOrCreateVisitorId(browserStorage())`, not `getOrCreateVisitorId(window.localStorage)`, because reading the property throws when storage is blocked. The plan's state table and D45 now say this. The 15 KiB check counts UTF-8 bytes by hand, because jsdom has no `TextEncoder`. Parsers drop the whole body on missing `facts`/`id`/`slot`/`value` or a non-integer `turn`; any other odd field reads as `null` (a missing `visitor` gives `{name:null, visits:0}`).
- **Copy, question for Michael:** I changed the plan's intro line "a voice agent I built on LiveKit" to "I designed and built on LiveKit, with Claude Code agents writing much of the code", per brand.md § Voice (credit honestly). OK, or keep the short version?

### 2026-10-20 · VC2-01 · passes

- **Changed:** new `docs/plans/2026-10-20-VC2-talk-page.md` (plan only, no code). It covers the file table, the component tree, the 6-phase state machine with a transition table, the 390/1280 layout and what sits above 844 px. It quotes every LiveKit signature from the installed `.d.ts`, plus the duplicate-handler throw (esm.mjs line 27472). It also fixes the Jest mock surface and helpers, the `concierge.ts` copy and the contract types. Tests unchanged at 680/60.
- **Verified:** `check.sh` green; smoke 38/38. Cheap checks: `livekit-server-sdk` dist never imports `livekit-client`, so the Jest mapper leaves VC1's tests alone; the Navbar has 7 links; `ParticipantKind.AGENT = 4`.
- **Next (VC2-02):** the parsers read a bad numeric field as null but reject the whole body on missing `facts`/`id`/`slot` or a non-integer `turn`. `lk.transcription` is read with `for await` and keyed by `lk.segment_id`. Visitor vs agent comes from `identity === localParticipant.identity`, the same check components-react makes.
- **Design defaults in the plan:** the Room and the visitor id are created in the Connect click handler, never in an effect. The mic turns on after `connect()` resolves. Forget me shows only while live. `concierge.get_memory` is never called.
- **Question for Michael:** should the mic turn on automatically after Connect, or wait for a tap? The plan auto-enables it, to match "Connect, say your name". Also, is `/talk` off the Navbar (D44) right?
- **Proposed change:** VC2-01 step 5 calls the `/talk`-chrome default D43, but VC1-03 already used D43 for lower-casing ids, so the plan names it D44 and the visitor-id timing D45. D42 already exists, and "no components-styles" is already in D41.

### 2026-10-20 · verify VC1

| Feature | Step | What you ran or read | What you saw | Holds |
|---|---|---|---|---|
| VC1-01 | 1 | read package.json; `npm view` each pkg; `npm ci` in a temp copy; ls node_modules/@livekit; grep lock for components-styles | deps pin livekit-client 2.23.0, components-react 2.9.24, server-sdk 2.19.1 = npm latest; no ^/~; npm ci clean; no styles pkg (0 hits); plan § explains why | yes |
| VC1-01 | 2 | read spec D41 (line 156) | D41 *default* names the 3 packages, pins, reason (spec §3, Michael 10-19) | yes |
| VC1-01 | 3 | read plan quotes + decoded token; ls protocol/dist | AccessToken.d.ts, RoomConfiguration/RoomAgentDispatch quoted; decoded payload has sub, video.room, roomConfig.agents[0].agentName, exp, nbf (no iat, noted). livekit_room_pb.d.ts absent in installed protocol (declared in dist/index.d.ts); plan states this | yes |
| VC1-01 | 4 | read plan behaviour table + tests section | 503/400/200, room, identity, ttl 600, grants, metadata, emptyTimeout 30, runtime/dynamic, env per request, spec §5 tests and 'x'.repeat(32) guard advice all present | yes |
| VC1-01 | 5 | check.sh + `npx jest --silent` | check green; jest 60 suites/680 tests pass | yes |
| VC1-02 | 1 | read concierge-token-route.test.ts lines 55-90; ran it | no env → 503 toEqual {offline:true}; it.each of each var missing → 503; test passes | yes |
| VC1-02 | 2 | read test cases lines 90-116 | it.each: not-a-uuid, v1, 37-char, missing body, non-JSON → 400 {error:'bad_request'}, no token | yes |
| VC1-02 | 3 | read tests 118-200; ran; read route.ts | keys url+token, url=env, sub/room/roomJoin/nbf+600/agentName/metadata/emptyTimeout 30, distinct rooms, no key/secret in text; real SDK (no mocks in this file) | yes |
| VC1-02 | 4 | read visitorId.ts and concierge-visitor-id.test.ts; route imports it | isUuidV4 accepts either case v4; tests reject v1, bad variant, wrong length, non-strings; passes | yes |
| VC1-02 | 5 | read route.ts; curl POST on :7832 | runtime='nodejs', dynamic='force-dynamic', env read in handler; curl → HTTP 503 {"offline":true} | yes |
| VC1-02 | 6 | check.sh; `node .harness/smoke.mjs` (twice) | check green; smoke all PASS, exit 0 | yes |
| VC1-03 | 1 | read plan § Review (line 215) | 9-row table (file·finding·severity·outcome); Important flaky nbf fixed with frozen clock; commit e81219d adds tests | yes |
| VC1-03 | 2 | `grep -rn LIVEKIT src/components src/app --include=*.tsx`; `grep -rl LIVEKIT_API .next-check/static`; read route.ts and sdk test | both greps empty; error bodies are literals; room/identity from validated id + randomBytes; 37/10000-char ids rejected before SDK (regex anchored, spy test) | yes |
| VC1-03 | 3 | `npx jest content-guard.test.ts` | passes with route tests present | yes |
| VC1-03 | 4 | read CLAUDE.md; `npx jest --silent | tail` | route row, D41 packages in Code rules; counts 680 tests/60 suites match | yes |
| VC1-03 | 5 | check.sh | green | yes |

### 2026-10-20 00:36 · VC1-03 · passes

- **Review:** Opus read `VC1.diff` (652 lines). No Critical findings. 1 Important: the token test's `exp - nbf === 600` was flaky,
  because the SDK reads the clock twice (a throwaway test got 599). Now fixed with a frozen clock. Plan § Review has the 9-row table and the four leak/id checks with evidence.
- **Changed:** `route.ts` lower-cases the id (D43 *default*); `isUuidV4` is now a type guard and `readVisitorId` is one line.
  New `concierge-token-route-sdk.test.ts` (500 path, no SDK call on bad ids); new tests cover extra body fields and lower-casing.
  CLAUDE.md gains the route row, D41 packages and the counts. Tests 674 → 680, suites 59 → 60.
- **Verified:** `check.sh` green (fresh `.next-check`); `grep LIVEKIT` in tsx and `.next-check/static` both empty; content guard 20/20;
  curl :7832 → `{"offline":true}` 503; smoke 38/38.
- **Next (VC2-01):** the client must send `crypto.randomUUID()` (already lower-case). `isUuidV4` narrows to `string`.
- **Question for Michael:** D43, keep lower-casing ids? Also, the route has no Origin check or rate limit, so anyone can mint tokens,
  and each joined room dispatches the paid agent (capped at 10 min). Should a later milestone add an Origin allowlist?

### 2026-10-20 · VC1-02 · passes

- **Changed:** new `src/app/api/concierge/token/route.ts` (POST only; 503 `{offline:true}` checked before the body,
  400 `{error:'bad_request'}`, 200 `{url, token}`, 500 `{error:'token_failed'}`; `Cache-Control: no-store` on all) and
  `src/lib/concierge/visitorId.ts` (`isUuidV4`). Tests first: `src/__tests__/app/concierge-token-route.test.ts`
  (real SDK, real signing, `TokenVerifier` check) and `src/__tests__/lib/concierge-visitor-id.test.ts`. 643 → 674 tests, 57 → 59 suites.
- **Recorded:** D42 *default* in the v2 spec (route test signs with the real SDK; only `livekit-client`/components get mocked, in VC2).
  The plan's test paths now match the feature's file names.
- **Verified:** `check.sh` green; curl on :7832 → `{"offline":true}` HTTP 503 (GET → 405); smoke 38/38; route absent
  from `.next-check/prerender-manifest.json`; `grep -rl LIVEKIT_API .next-check/static` empty.
- **Next (VC1-03):** review the diff; CLAUDE.md still needs the route row, D41 packages and counts (674 tests, 59 suites).

### 2026-10-20 · VC1-01 · passes

- **Changed:** `package.json`/`package-lock.json` pin `livekit-client` 2.23.0, `@livekit/components-react` 2.9.24,
  `livekit-server-sdk` 2.19.1 (latest per `npm view`; `components-styles` not installed). D41 *default* in the v2 spec.
  New `docs/plans/2026-10-20-VC1-token-route.md`: quoted types, a decoded minted token, the route table, tests, live steps. Tests 643 → 643.
- **Verified:** `npm ci` clean (741 packages); `check.sh` green (57 suites, 643 tests, lint and build ok); smoke 38/38.
  A throwaway Jest test (node env) minted and decoded a real token, then was deleted.
- **Next session (VC1-02):** the route test needs `/** @jest-environment node */` (under jsdom, jose resolves to its browser ESM build).
  The token has `nbf`, **no `iat`**; dispatch `metadata` is a JSON *string*. Running `npm ci` kills the dev server; restart with `.harness/init.sh`.
- **Proposed change:** VC1-01 step 3 names `@livekit/protocol/dist/gen/livekit_room_pb.d.ts`, which doesn't exist. The
  types are in `dist/index.d.ts` (server SDK's nested copy 1.51.0; the top-level copy is 1.52.1, with the same declarations).

## 2026-10-20 · Initializer (Fable)

**Scope (the brief wins):** VC1–VC3 of `docs/specs/2026-10-19-voice-concierge-page.md` only. The agent itself is
being built tonight in a parallel run at `~/projects/voice-concierge` (public repo `mh550/voice-concierge`,
confirmed PUBLIC by `gh repo view` at init). §4 of the page spec is the shared contract, word for word; build to
that text, not to the agent repo's live files, which may still move tonight. No LiveKit environment exists in the
suite, the smoke or the dev server: every page must render its offline state cleanly. PRs only; Michael merges.

**Features:** 15. VC1 token route + deps: 3 (plan+deps, build, review). VC2 `/talk`: 7 (plan, pure rules, panels,
page + session, interaction, check, review). VC3 deep-dive + entry points: 5 (plan + evidence note, data entry,
diagram + card link, check, review). Dependencies: VC2 after VC1; VC3 after VC1 (independent of VC2); inside each
milestone, sequential. First three: VC1-01, VC1-02, VC1-03.

**Baseline:** 643 tests, 57 suites, `.harness/check.sh` green in ~1 min; `node .harness/smoke.mjs` 38/38. Dev
server for this run: `http://localhost:$HARNESS_PORT` (7832 at init). Next 16.1.6, React 19.2, Jest 30, Node 24.

### Where things live

- Content is data: `src/lib/data/*.ts`, barrel `index.ts`. New here: `src/lib/data/concierge.ts` (page copy,
  privacy note) and the `voice-concierge` entry in `projects.ts`. Components render data; tests assert against the
  data, except where the spec gives an exact string (the offline sentence is one).
- Pure logic for the page goes in `src/lib/concierge/` (`visitorId.ts`, `contract.ts`, `latency.ts`): no DOM, no
  LiveKit imports, fully unit-tested. The route (`src/app/api/concierge/token/route.ts`) and the client component
  both import `isUuidV4` from there.
- Client code only in `src/components/talk/`. `TalkSession.tsx` is the one `"use client"` owner of the Room; the
  panels are presentational. `src/app/talk/page.tsx` stays a Server Component (metadata, h1, privacy note).
- Site chrome: `SiteChrome.tsx` strips Navbar/Footer only on `/card*`; `/talk` keeps both (default D43).
- Case-study template: `components/projects/ProjectDetail.tsx` + `case-study/*`; props and copy rules in
  `docs/plans/2026-10-18-M3-case-study-template.md` § Components. Diagrams: one file,
  `components/projects/diagrams/index.tsx`, with `DIAGRAMS`, `CAPTIONS`, `LABELS` keyed by `DiagramKey`
  (`projects.ts`); `ProjectDiagram.test.tsx` lists every key in `KEYS` and asserts one `role="img"` with a unique
  label and a figcaption.
- Plan files: `docs/plans/2026-10-20-VC1-token-route.md`, `…-VC2-talk-page.md`,
  `…-VC3-voice-concierge-deep-dive.md`. Decisions: append `D41 *default*` onward to the v2 spec's Decisions list;
  never renumber. Screenshots: `docs/screenshots/v2/VC<n>-<page>-<width>.png`, under 400 KB.
- Diff base for a milestone review: the parent of its first feature commit
  (`git log --format=%H --grep='^VC2-01' | tail -1`, then `^`). Feature commits start with `<id>:`.

### LiveKit facts checked at init (re-check against the installed types; never guess a signature)

- Versions on npm tonight: `livekit-server-sdk` 2.19.1, `livekit-client` 2.23.0, `@livekit/components-react`
  2.9.24 (peer `livekit-client ^2.20.1`, `react >=18`). Pin exactly (`npm i -E …`). `init.sh` re-runs `npm ci`
  when `package-lock.json` is newer than `node_modules`, so a lockfile change costs one reinstall per session.
- `livekit-server-sdk` re-exports `RoomConfiguration` and `RoomAgentDispatch` from `@livekit/protocol`;
  `AccessToken` has `ttl` (number = seconds, or a string), `addGrant(VideoGrant)`, a `roomConfig` setter and
  `async toJwt()`. Signing is pure (jose, HS256): the route test can mint and decode a real token with a fake key
  and secret, no network. Decode the payload in the test with `Buffer.from(seg, 'base64url')`.
- `livekit-client`: `Room.registerTextStreamHandler(topic, (reader, participantInfo) => …)` /
  `unregisterTextStreamHandler(topic)`; `reader.readAll()`; `reader.info.attributes` carries the
  `lk.*` transcription attributes; `LocalParticipant.sendText(text, { topic })`; `performRpc({ destinationIdentity,
  method, payload, responseTimeout })`; `setMicrophoneEnabled(bool)`; `Participant.kind === ParticipantKind.AGENT`
  (re-exported from `@livekit/protocol`). Registering a second handler on a topic that already has one throws, so
  do not combine your own `lk.transcription`/`lk.chat` handlers with `useTranscriptions`/`useChat`.
- `@livekit/components-react` is `sideEffects: false`; use `RoomContext.Provider value={room}` +
  `RoomAudioRenderer` for agent audio. `@livekit/components-styles` is not needed for that (default: leave it out).
- Browser autoplay: call `room.startAudio()` after the Connect click if `room.canPlaybackAudio` is false.
- Room and participant kinds, text streams and RPC all exist in the mock only: `src/__mocks__/livekit-client.ts`
  and `src/__mocks__/livekit-components-react.tsx`, wired through `moduleNameMapper` in `jest.config.ts` exactly
  like the existing framer-motion mock. No test may open a connection.

### Gotchas

- **Content guard** (`src/__tests__/lib/content-guard.test.ts`) scans `src/` and `public/`, including tests. Its
  secret pattern is `/(api[_-]?key|token|secret)\s*[:=]\s*['"][A-Za-z0-9_\-]{12,}/i`, so
  `process.env.LIVEKIT_API_SECRET = 'xxxxxxxxxxxx'` or a fixture `token: 'eyJhbGci…'` fails the suite. Build fakes
  from expressions (`'x'.repeat(32)`, `['a','b'].join('.')`). Also no `TODO`, no `[X]`, no phone-shaped numbers
  (`919 555 0123`), no `.ts.net`, no `ntfy.sh/`. Fix the content, never the guard.
- **Hydration and lint.** eslint-config-next 16 flags setState inside a mount effect. Read the visitor id from
  `localStorage` inside the Connect click handler, not on mount; the server and client renders then match and
  `next build` prerenders `/talk` without a `window` reference. If `livekit-client` turns out not to be SSR-safe at
  import time, lazy-load it inside the connect handler (`await import('livekit-client')`; `jest.mock` still applies).
- **Tests that count.** `data.test.ts` pins 9 projects and the full D12 order map; `sitemap-robots.test.ts` pins 8
  static routes and `8 + projects.length` URLs; `card.test.tsx` expects exactly 3 `/projects/` links and 2
  `target=_blank` links; `project-page-unchanged.test.tsx` snapshots the six classic pages (do not touch
  `ProjectDetail` markup); `opengraph-image.test.ts` renders every project's OG image and checks each glyph of the
  title and shortDescription (or first metric) against the bundled font's cmap: Latin only, `→`/`↔` are drawn as
  SVG, `≈` becomes `~`. `claims-on-linked-page.test.ts` pins 17 + 20 claims on `/approach` and `/evidence`: do not
  edit `approach.ts` or `competencies.ts`.
- **`a11y-new-pages.test.tsx`** renders each new page and requires one h1 first, no skipped heading levels, a
  `focus-visible:outline` class on every link/button (`focusRing` from `components/focusRing.ts`), and no link named
  only "here", "more" or an arrow. Add `/talk` and `/projects/voice-concierge` to its `pages` list.
- **Smoke** discovers project slugs from `/projects` and reads `.harness/smoke-routes.txt` for static pages: add
  `/talk` there (VC2-04). It fails on any console error, so a LiveKit warning logged at page load would fail it.
- **Print** (`globals.css` `@media print`, pinned by `print-styles.test.ts`): hide decorative extras with
  `print:hidden`; don't add a second print block.
- **Build-only policy.** Never set LiveKit env vars anywhere, never create `.env*`, never read
  `~/.config/voice-concierge/env`. The live check is written for Michael in `docs/review-guide.md` (VC2-07).
- **Agent repo reads** are limited to `~/projects/voice-concierge/docs/spec.md`, `docs/decisions.md` and
  `README.md`, read-only. It is being rewritten tonight: quote its Status line with the revision time in
  `docs/notes/evidence-voice-concierge.md` so the deep-dive's claims have a dated source.
- **Order of merges.** VC3's card link and the deep-dive's Links point at `/talk`, which VC2 builds. Both are on one
  branch, so by the time VC3 runs the page exists; the review guide tells Michael to merge VC1 → VC2 → VC3.

### Defaults chosen (record each as `D<n> *default*` in the v2 spec when the feature builds it)

- **D41** the three runtime packages at exact pins (VC1-01).
- **D42** the token route test signs a real token with the real SDK and fake env, then decodes it; the spec's
  "tests mock the SDK" is applied to `livekit-client` and `@livekit/components-react` in Jest (VC1-02 / VC2-04).
- **D43** `/talk` keeps the site chrome (Navbar, skip link, Footer), is indexable and in the sitemap, and stays off
  the Navbar: the v2 spec fixes the Navbar at seven links and the page spec allows it only if those rules permit.
  Reachable from `/card`, the deep-dive and the sitemap (VC3-03).
- **D44** the `voice-concierge` project is `featured: true, order: 5` (after HitList); `ghl-jobtread-integration`
  and later shift by one. `/card`'s Selected work and the home Recent work stay as they are; the card gets its own
  button (VC3-02). Michael can change this in INBOX.
- **D45** the `/card` button "Talk to my concierge" sits directly under the LinkedIn / Email / GitHub row (VC3-03).
- The visitor id is created at Connect time, not on mount; `@livekit/components-styles` is not installed.

### Questions for Michael (defaults apply until answered in INBOX.md § Answers)

1. **Where should Voice Concierge sit in the project order?** Default: 5th (after HitList), so `/card`'s three
   Selected work entries and the home page's Recent work do not change. Answer `order 2` to make it the second
   project everywhere (it would then replace Home media server on the card's Selected work, next to the new
   "Talk to my concierge" button).
2. **Should `/talk` be in the Navbar?** Default: no (the Navbar stays at seven links); it is linked from `/card`,
   the deep-dive and the sitemap. Answer `navbar yes` and VC3-03 adds it between Projects and Approach.
3. **Deep-dive title.** Default: "Voice Concierge: a voice agent that remembers returning visitors". Say another.
