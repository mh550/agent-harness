# Progress log — run portfolio_site-2026-10-20-vc4 (branch `harness/portfolio_site-2026-10-20-vc4`)

What this file is: the shared memory of this harness run. Every session reads it at startup and adds a short
entry **at the top** (newest first): feature id, what landed, what the next session must know. The feature list is
`feature_list.json` in this directory: array order is priority, `after` lists are the real dependencies, a session
may flip only its own feature's `passes`. Michael steers through `INBOX.md` on this branch (first line
`status: run|pause|stop`; answers under `## Answers`). Plans go in `docs/plans/2026-10-20-<milestone>-<topic>.md`;
new defaults go in a new `## 7. Decisions` section of `docs/specs/2026-10-19-voice-concierge-page.md`, numbered
from **D59** (above every D in the v2 spec, D1–D49, and the booth spec, D41–D58, which already collide; never
renumber), each naming the decision it supersedes.

---

### 2026-10-20 16:15 · verify VC5

Suite (all "check.sh; smoke" rows): `lib/check.sh` answered from cache, so I ran `.harness/check.sh` uncached: `check: lint ok · jest ok · build ok`, 81 suites / 1115 tests. **Smoke first FAILED on all 42 loads**: the harness dev server on :7834 (pid 3580214, up since 15:18) answered HTTP 500 on every route after an HMR recompile at 16:00 (when the run files were written): Turbopack's CSS for VoiceWidget's `bottom-[max(1rem,env(safe-area-inset-bottom))]` came out as `env(safe-area-inset-%<binary>)`, "Parsing CSS source code failed". The source has no such text, and the production CSS in `.next-check` holds the correct `bottom:max(1rem,env(safe-area-inset-bottom))`. Two side issues: `init.sh` could not restart the server, because `server.pid` named another pid and the stale server still held the port (EADDRINUSE); and a fresh `next dev` that reused the old `.next` still served 500. Once I killed the stale server and moved `.next` to `$HARNESS_SCRATCH/next-cache-broken`, `init.sh` came up clean and `node .harness/smoke.mjs` printed 42/42 PASS. So I put this down to the dev cache and the environment, not VC5 code. If smoke goes red the same way again, clear `.next`.

| Feature | Step | What you ran or read | What you saw | Holds |
|---|---|---|---|---|
| VC5-01 | 1 | `grep -n '^#'` plan; read § Route behaviour table | All 12 named sections present (What Michael will see / Review since filled by VC5-06/07); table rows 1–7: 403 forbidden → 503 env → 400 bad_request → 503 listRooms → 429 visitor → 429 site (default 2, invalid → 2) → 200 room `concierge-<addr10>-<12 hex>` | yes |
| VC5-01 | 2 | read § Origin rules (plan:130-155) | site origin, regex `^portfolio-site-[a-z0-9-]+-mh550s-projects(-[a-z0-9]+)?\.vercel\.app$` from the real PR #16 host, dev-only localhost/127.0.0.1 any port, null forbidden, `new URL` whole-origin compare | yes |
| VC5-01 | 3 | read § Address hash (plan:157-181) | first trimmed XFF entry or 'unknown'; HMAC-SHA256(LIVEKIT_API_SECRET) first 10 hex; room `concierge-<addr10>-<randomBytes(6) hex>`; "this address's" = prefix `concierge-<addr10>-`; never logged/returned (own JWT exception recorded as D70) | yes |
| VC5-01 | 4 | read § Modules (plan:183-218) | origin.ts/limits.ts/rooms.ts with the exact signatures; limits test file with `jest.mock('@/lib/concierge/rooms')` factory and the SWC spyOn reason; token-route.test.ts mock-free (200s moved, D69 records the override) | yes |
| VC5-01 | 5 | read § Mic timing, § /talk busy states | setMic(true) moves into agentArrived, toggle live-only as a decision (D65); `{type:'busy', reason}` → phase busy, reason kept, Connect shown, no retry; both copy strings exact; other non-OK offline | yes |
| VC5-01 | 6 | read § Live check (plan:309-363); `ls ~/projects/voice-concierge` | staged curls (no Origin 403, evil 403, preview 503), two tabs → another-tab line, site cap with second device, room list per stage, undo (CONCIERGE_MAX_ROOMS, revert route commit); agent repo caveat; ls shows only CLAUDE.md docs knowledge README.md | yes |
| VC5-01 | 7 | read plan § Decisions; spec `## 7. Decisions` (spec:90-176); plan § CLAUDE.md text | D63–D67 present with what each supersedes/extends (plus D68–D73); CLAUDE.md row drafted (plan:369-375) and equal to CLAUDE.md's token row | yes |
| VC5-02 | 1 | `grep -n 'setMic(session, true)' src/components/talk/TalkSession.tsx` | exactly one line, 272, inside `agentArrived` (268-273), called from onParticipantConnected (275) and the post-connect scan (322) | yes |
| VC5-02 | 2 | read TalkSession-live.test.tsx:55-113; TalkSession.test.tsx:100-116, 475-503; ran jest on src/__tests__/components/talk | `mic` not called after connect, `[[true]]` after addAgent; micCalls()==[] on configured=false, 503 and the 10 000 ms timeout path; toggle tests pass; 18 suites / 369 tests pass | yes |
| VC5-02 | 3 | read TalkSession-live.test.tsx:116-129; concierge.ts:33-34; talk.test.tsx and a11y-new-pages.test.tsx in the full jest run | queryByRole 'Mute microphone'/'Unmute microphone' null while Waiting, exactly 1 once agent joined; TalkSession.tsx:430 `phase === 'live'`; talk and a11y green | yes |
| VC5-02 | 4 | plan § Mic timing vs TalkSession.tsx:266-324; review-guide.md:106-109 | as-built note matches code line for line; morning step 2 says the browser asks for the mic once the concierge has joined (not before) | yes |
| VC5-02 | 5 | `.harness/check.sh`; `node .harness/smoke.mjs` | check: lint ok · jest ok · build ok; smoke 42/42 PASS after the dev-server restart (see note above) | yes |
| VC5-03 | 1 | read concierge-origin.test.ts; jest | every listed case asserted with the stated result (null, site, .evil suffix, http, real preview, abc123 preview, evil-…, suffix preview, localhost:7834 / 127.0.0.1:3000 dev true/false, 'null', non-URL no throw); pass | yes |
| VC5-03 | 2 | read concierge-limits.test.ts; jest | addressOf first trimmed/'unknown'; bucket = test's createHmac slice(0,10), differs by secret, no address; roomNameFor regex and differs; verdicts null/visitor/site/null(max 5)/visitor-over-site/non-concierge ignored; maxRooms '3'→3, '0' '-1' 'abc' undefined →2; pass | yes |
| VC5-03 | 3 | package.json:23; `npm ls server-only`; package-lock.json:9918; `head -1` env.ts rooms.ts; `grep -L "import 'server-only'" …` | `"server-only": "0.0.1"` in dependencies; npm ls server-only@0.0.1; lock entry 0.0.1; both line 1 `import 'server-only';`; grep -L printed nothing; rooms.ts maps `RoomServiceClient(...).listRooms()` to `{name}` (now wired by VC5-04, as planned) | yes |
| VC5-03 | 4 | read TalkSession-import.test.tsx; `grep -rl livekit-client src/app` | hoisted counting `jest.mock('livekit-client')` factory: mockLoads 0 after configured={false} Connect, 1 with a Room on a configured Connect. It sits in a sibling file, not TalkSession.test.tsx: the step's "equivalent module-registry spy", with the reason in plan § server-only. grep empty | yes |
| VC5-03 | 5 | CLAUDE.md Code rules; plan § server-only (plan:249-285) | "`server-only` is approved at `0.0.1` exact (D67): `env.ts` and `rooms.ts` import it"; plan lists exactly those two modules | yes |
| VC5-03 | 6 | `.harness/check.sh`; smoke | lint/jest/build ok; 42/42 PASS (after restart) | yes |
| VC5-04 | 1 | read route.ts:35-82; `grep -n console src/app/api/concierge/token/route.ts` | order: isAllowedOrigin(origin,{siteUrl: profile.siteUrl, dev: NODE_ENV!=='production'}) 403 → conciergeEnv 503 → readVisitorId 400 → listLiveRooms try/catch 503 → roomsVerdict 429 → roomNameFor(addressBucket(addressOf(headers), apiSecret)); every reply via `reply()` with no-store; grep empty | yes |
| VC5-04 | 2 | read concierge-token-route.test.ts; jest | no jest.mock; SITE_ORIGIN default on every case; no Origin → 403 forbidden with no env; evil.example → 403 with env; localhost:7834 → 503 offline; with `jest.replaceProperty(process,'env',{NODE_ENV:'production'})` → 403; 200 cases moved to the limits file (D69 recorded); pass | yes |
| VC5-04 | 3 | read concierge-token-route-limits.test.ts; jest | node env, rooms factory mock, real SDK: [] → 200, video.room matches ROOM and the bucket equals the HMAC of '203.0.113.9' from '203.0.113.9, 10.0.0.1'; sub/grants/dispatch metadata as VC1; own bucket → 429 visitor; two others → 429 site; three + MAX=4 → 200; reject → 503 offline; no XFF → bucketOf('unknown'); body text and console spies contain neither address nor bucket; pass | yes |
| VC5-04 | 4 | read concierge-token-route-sdk.test.ts; jest | bad ids → 400 with addGrant/toJwt spies and listLiveRooms not called; 403 (evil, http site, 'null') reaches none; pass | yes |
| VC5-04 | 5 | plan § Route behaviour vs route.ts; CLAUDE.md token row | rows 1–7 and the 500 row match the code line by line; the row names the 403, the 429 visitor/site and room `concierge-<addr10>-<12 hex>` (D73) in one sentence | yes |
| VC5-04 | 6 | `.harness/check.sh`; smoke | green; 42/42 PASS (after restart) | yes |
| VC5-05 | 1 | concierge.ts:44-45; sessionReducer.ts:65,78-79; sessionReducer.test.ts:17,23,66-91 | strings exact; busy only from connecting, connect allowed from busy, leave → initial; tests: busy from connecting keeps reason, ignored elsewhere incl. live, connect from busy → connecting with busyReason null, inRoom('busy') false | yes |
| VC5-05 | 2 | TalkSession.tsx:71-87,218-221,397-406; TalkSession.test.tsx:180-236 | 429 busy only with error 'busy' + reason visitor/site; status shows the matching line, Connect focused, MockRoom.instances 0, advanceTimersByTime(15_000) → fetchMock 1 call, micCalls() []; reason 'other' / other error / no body → offline | yes |
| VC5-05 | 3 | `grep -F` the sentence in projects.ts (escaped `\'`) and evidence-voice-concierge.md:153; jest case-study-voice-concierge + content-guard | sentence at the end of caseStudy.method.build (projects.ts:800) names origin-only, 1 per address, 2 site-wide, 5 sessions/day, 10 min, about $45/week; verbatim row with source (VC4 spec § VC5.2 Michael 2026-10-20; concierge/limits.py); both tests pass | yes |
| VC5-05 | 4 | read voice-concierge-todo.md § Cost protection (line 48) | three-layer table: route (CONCIERGE_MAX_ROOMS default 2, origin.ts/limits.ts/route.ts), agent 5/day and 10 min (concierge/limits.py), provider caps about $45/week (billing); what to change where | yes |
| VC5-05 | 5 | `.harness/check.sh`; smoke | green; 42/42 PASS (after restart) | yes |
| VC5-06 | 1 | dummy-env `next dev -p 7899` (NEXT_DIST_DIR=.next-check), `node .harness/talk-busy-check.mjs $HARNESS_SCRATCH/vc506shots`; ls docs/screenshots/v2/VC5*; read plan § What Michael will see; looked at the busy-visitor 390 capture | statuses 'You already have a conversation open in another tab.' / 'The concierge is busy right now. Try again in a few minutes.', Connect visible, bottom 664 (390×844) / 489 (1280), scrollWidth 390/1280; my captures 56/57/73 KB; committed files 57/58/74 KB (<400 KB); plan records the same numbers | yes |
| VC5-06 | 2 | same run (report OK lines) | 1 then 2 POSTs after 2 clicks over 15 s each (busy and 503), getUserMedia 0, mic toggle 0, console errors only "Failed to load resource … 429/503", 0 page errors | yes |
| VC5-06 | 3 | the three curls on :7834 (no env) | 403, 403 (evil.example), 503 (Origin http://localhost:7834); `-i`: 403 has cache-control no-store and `{"error":"forbidden"}` | yes |
| VC5-06 | 4 | same run, focus report | activeElement BUTTON 'Connect', :focus-visible true, outline solid rgb(0, 212, 255), in all four scenarios | yes |
| VC5-06 | 5 | read plan § What Michael will see (plan:383-408) | table rows for the 4 captures and the 3 curl lines (state · on screen/printed · what looks wrong); no bug found, the offline full-stop asked as a question | yes |
| VC5-06 | 6 | `.harness/check.sh`; smoke | green; 42/42 PASS (after restart) | yes |
| VC5-07 | 1 | `$HARNESS_SCRATCH/VC5.diff` (166 KB); plan § Review; `grep -rn 'LIVEKIT_\|server-only' src/components src/lib/data`; route.ts; rooms test; sessionReducer.ts:104-107; `npx tsc --noEmit` | table answers every question; my reading agrees (only signing after both checks; no console; requestTimeout 5 + failover false pinned by concierge-rooms.test.ts; whole-origin compare; busy only from connecting; mic only in agentArrived, guarded). grep empty; tsc exit 0. The Important burst finding: fixed by D72, then reverted by D73 because D72 put two people on one NAT in one room. Kept as an accepted known limit (plan:98-115), as the spec's room form and VC5-03/04 steps require | yes |
| VC5-07 | 2 | review-guide.md:151-215 and :101-109 | § VC5 "mic timing and cost protection": changes, staged check (curl → 403, two tabs → another-tab line, CONCIERGE_MAX_ROOMS stage), LiveKit room list per stage, undo per piece; morning step 2 asks for the mic once the concierge joins | yes |
| VC5-07 | 3 | CLAUDE.md routes row, lib/concierge line, Code rules, Testing, Commands; full jest | names origin.ts, limits.ts, rooms.ts and the 403/503/400/503/429 order, server-only exact pin D67, limits test + rooms factory mock; "1115 tests, 81 suites" = jest 1115 / 81 | yes |
| VC5-07 | 4 | spec § 7 (D59–D73); vc4 spec `## Built (2026-10-20 …)` | each decision names what it supersedes (D67 "extends D41", D69 "refines D42 / overrides VC5-01 step 4"); Built note lists D59–D73 and the two confirmations (agent doesn't parse room names; preview regex) | yes |
| VC5-07 | 5 | `.harness/check.sh`; smoke | green; 42/42 PASS (after restart) | yes |

40 hold, 0 fail.

### 2026-10-20 · verify VC5

| Feature | Step | What you ran or read | What you saw | Holds |
|---|---|---|---|---|
| VC5-01 | 1 | grep '^#' on the VC5 plan | all listed sections present; Route behaviour table rows 1-7 in the stated order | yes |
| VC5-01 | 2 | read § Origin rules, grep regex | regex and real preview host present; whole-origin URL parse rule | yes |
| VC5-01 | 3 | read § Address hash | first XFF entry/'unknown', HMAC 10 hex, room concierge-<addr10>-<12 hex> (D73) | yes |
| VC5-01 | 4 | read § Modules/Tests; ls src/lib/concierge | origin/limits/rooms modules named; limits test file strategy described | yes |
| VC5-01 | 5 | read § Mic timing and § busy states; concierge.ts:44-45 | busy copy exact; mic moves to agentArrived | yes |
| VC5-01 | 6 | read § Live check | curl stages, room list checks, undo, agent room-name caveat present | yes |
| VC5-01 | 7 | read spec § 7 D59-D73; CLAUDE.md token row | decisions present with supersedes; row drafted and in CLAUDE.md | yes |
| VC5-02 | 1 | grep -n 'setMic(session, true)' TalkSession.tsx | one line (272), inside agentArrived | yes |
| VC5-02 | 2 | read TalkSession-live.test.tsx:55-113, TalkSession.test.tsx micCalls asserts; ran jest | mic not called after connect, [[true]] after addAgent; micCalls()==[] offline paths; pass | yes |
| VC5-02 | 3 | read TalkSession-live.test.tsx:118-128 | no mic button while waiting, exactly one once agent joined; pass | yes |
| VC5-02 | 4 | read plan § Mic timing; review-guide.md:108 | matches code; guide says prompt once concierge joined | yes |
| VC5-02 | 5 | check.sh (green, cached); smoke all PASS; full jest | 81 suites / 1115 tests pass | yes |
| VC5-03 | 1 | jest concierge-origin.test.ts | passes; step's cases covered | yes |
| VC5-03 | 2 | jest concierge-limits.test.ts | passes (HMAC, room regex, verdicts, maxRooms) | yes |
| VC5-03 | 3 | grep package.json, npm ls server-only, grep -L | "server-only": "0.0.1", ls 0.0.1, grep -L prints nothing | yes |
| VC5-03 | 4 | read TalkSession-import.test.tsx; grep -rl livekit-client src/app | mockLoads 0 unconfigured, 1 configured; src/app grep empty | yes |
| VC5-03 | 5 | CLAUDE.md:150; plan § server-only | D67 named; modules listed | yes |
| VC5-03 | 6 | check.sh; smoke | green | yes |
| VC5-04 | 1 | read route.ts; grep console | order 403,503,400,503,429,200; no-store via reply(); no console | yes |
| VC5-04 | 2 | jest concierge-token-route tests; curl :7834 | 403/403/503 as asserted; pass | yes |
| VC5-04 | 3 | jest concierge-token-route-limits.test.ts | pass; 200/429/503 and no-leak cases | yes |
| VC5-04 | 4 | jest concierge-token-route-sdk.test.ts | pass; 400/403 reach no SDK or listLiveRooms | yes |
| VC5-04 | 5 | read plan § Route behaviour; CLAUDE.md:32 | rows match code; token row names 403/429/room name | yes |
| VC5-04 | 6 | check.sh; smoke | green | yes |
| VC5-05 | 1 | concierge.ts:44-45; sessionReducer.test.ts busy cases | strings exact; busy from connecting only, ignored from live, connect from busy | yes |
| VC5-05 | 2 | TalkSession.test.tsx:180-234 | both reasons, unknown reason offline, 1 fetch over 15 s, no mic; pass | yes |
| VC5-05 | 3 | projects.ts:800; evidence-voice-concierge.md:153; jest case-study-voice-concierge, content-guard | sentence verbatim in evidence row with source; pass | yes |
| VC5-05 | 4 | voice-concierge-todo.md § Cost protection | three layers table present | yes |
| VC5-05 | 5 | check.sh; smoke | green | yes |
| VC5-06 | 1 | ran .harness/talk-busy-check.mjs on a temporary dummy-env dev server (:7899); ls docs/screenshots/v2/VC5*; read plan table | captures 55-74 KB; Connect bottom 664/489, scrollWidth recorded; plan matches | yes |
| VC5-06 | 2 | same run | 1 POST per click over 15 s, getUserMedia 0, only 429/503 console lines, 0 page errors | yes |
| VC5-06 | 3 | curl on :7834 (no env) | 403, 403, 503 {offline:true} | yes |
| VC5-06 | 4 | same run focus report | activeElement Connect, outline rgb(0, 212, 255) | yes |
| VC5-06 | 5 | read plan § What Michael will see | one row per screenshot and curl line | yes |
| VC5-06 | 6 | check.sh; smoke | green | yes |
| VC5-07 | 1 | read plan § Review; grep LIVEKIT_/server-only in components,data | table + answers to all questions; fixes had tests; grep empty; signing only after both checks | yes |
| VC5-07 | 2 | read review-guide.md § VC5 | staged check, room list, undo; mic after join | yes |
| VC5-07 | 3 | CLAUDE.md; `npx jest --silent` | token row, lib/concierge line, server-only, limits test named; 1115 tests/81 suites match | yes |
| VC5-07 | 4 | spec § 7 and vc4 spec Built note | D59-D73 with supersedes; Built note lists defaults and two confirmations | yes |
| VC5-07 | 5 | check.sh; smoke | green | yes |

40 hold, 0 fail. (An older scratch report showed FAILs only because :7834 has no LiveKit env; on a dummy-env server it passes.)

### 2026-10-20 19:55 · VC5-04 · passes

- Docs only (route code and its tests already D73 since VC5-03): `docs/review-guide.md` § VC5 (Changed: room `concierge-<10 hex>-<12 random hex>`, D73; stage 2 room list and "D73's check"; the agent room-name note; Undo now "back to D72" via reverting VC5-03; decisions D63–D73) and the Built note of `docs/specs/2026-10-20-vc4-order-widget-limits.md` (D72 superseded by D73, room form). Tests 1115 → 1115 (81 suites).
- Verified each step: route order 403→503→400→503→429→200, `no-store` on every reply, `grep -n console route.ts` empty; token-route test 403 cases incl. NODE_ENV production seam; limits test ROOM `-[0-9a-f]{12}$`, bucket = test's HMAC of `203.0.113.9`, unknown bucket, MAX=4 → 200, list reject → 503, no address/bucket in bodies or console; sdk test: bad id and 403 reach neither SDK nor `listLiveRooms`; plan § Route behaviour rows 5/7 and CLAUDE.md token row match.
- `.harness/check.sh` → `check: lint ok · jest ok · build ok`; smoke exit 0, 42 PASS; curls on :7834: no Origin 403, evil 403, localhost 503.
- Next: every VC5 feature now passes; `grep -rn D72` outside the spec's § 7 and the plan's history is only "superseded" mentions.
- Question for Michael (still open): D73, a room per Connect (spec's form) vs D72 one room per address.

### 2026-10-20 19:35 · VC5-03 · passes

- D73 in code: `src/lib/concierge/limits.ts` `roomNameFor` is `concierge-<bucket>-<randomBytes(6) hex>` again and `roomsVerdict` matches `startsWith(concierge-<bucket>-)`; D72 comment gone. Tests first: `concierge-limits.test.ts` 3 failed, then 23/23 passed (name regex `-[0-9a-f]{12}$`, two calls differ, `concierge-<b>-x` → visitor, bare `concierge-<b>` and `concierge-<b>x-…` are not this address's).
- Suite stayed green only by also doing plan § D73 rework's VC5-04 test part now: `concierge-token-route-limits.test.ts` ROOM regex `-<12 hex>`, `roomOf` seeds `concierge-<bucket>-000000000000`, the D72 burst test replaced by "two calls from one address, two rooms with the same bucket". CLAUDE.md token row (`concierge-<addr10>-<12 hex>`, D73) and count updated. Tests 1114 → 1115 (81 suites).
- Verified: `.harness/check.sh` → `check: lint ok · jest ok · build ok` (1115 tests); smoke exit 0, 42 PASS; `npm ls server-only` 0.0.1; `grep -L "import 'server-only'"` env.ts rooms.ts empty; `grep -rl livekit-client src/app` empty; origin + import tests 11/11.
- Next session (VC5-04): left for it per plan: `docs/review-guide.md` § VC5 (Changed, stage 2's D72 check, Undo) and the Built note in `docs/specs/2026-10-20-vc4-order-widget-limits.md` (D72 → D73). The route test changes are already done.
- Proposed changes: VC5-03 step 3 "rooms.ts … is not yet called by the route" is stale since VC5-04 wired it; step 4 names TalkSession.test.tsx but the test lives in `TalkSession-import.test.tsx` (own module registry).
- Question for Michael: D73 still open (random room suffix vs D72 one room per address).

### 2026-10-20 19:10 · VC5-01 · passes

- Verify failed VC5-01/03/04 on one cause: D72 (room `concierge-<addr10>`, no random part) contradicts Michael's spec (`concierge-<addr10>-<random>`) and the steps. Took **D73 *default***: the spec's form again. Reason: under D72 two people on one NAT (conference Wi-Fi) who press Connect before the first join creates the room share a room and hear each other; the forged-Origin burst is a cost limit the agent and provider caps bound.
- Docs only: plan `docs/plans/2026-10-20-VC5-mic-limits-server-only.md` (route rows 5/7, known limits, § Address hash, CLAUDE.md draft, Review, D72 marked superseded, D73, new § D73 rework); spec § 7 D72 superseded + D73. Tests 1114 → 1114.
- Verified: every step read against the plan; `.harness/check.sh` → `check: lint ok · jest ok · build ok` (1114 tests); smoke 42/42 PASS.
- Next session (VC5-03, then VC5-04): code is still D72's. Follow plan § D73 rework exactly: `limits.ts` roomNameFor + `startsWith(concierge-<bucket>-)` + tests (VC5-03); route-limits test regex/burst test, CLAUDE.md token row, review guide § VC5 (lines ~164, 194, 212) and the vc4 spec Built note (lines 81, 86–87) (VC5-04).
- Question for Michael: D73: keep the spec's random room suffix, or go back to D72 (one room per address) and accept the shared-room race?

### 2026-10-20 18:30 · verify VC5

Steps failing for VC5-01/03/04 are one cause: D72 (room name `concierge-<addr10>` without random suffix) is a deliberate security fix but the feature steps were not updated to it. The next session should update the steps' wording or revert D72, with Michael's choice.

| Feature | Step | What you ran or read | What you saw | Holds |
|---|---|---|---|---|
| VC5-01 | 1 | read plan § Mic timing, Route behaviour table, Origin rules, Address hash, Modules, /talk busy states, server-only, Tests, Live check, What Michael will see, Review, Decisions | all sections exist; table order and codes match, BUT row 5/7 read `concierge-<addr10>` (was `-*` / `-<12 hex>` until D72), so the step's room-name text no longer holds | no |
| VC5-01 | 2 | read plan § Origin rules vs src/lib/concierge/origin.ts | regex `^portfolio-site-[a-z0-9-]+-mh550s-projects(-[a-z0-9]+)?\.vercel\.app$`, dev localhost/127.0.0.1, null → false, whole-origin compare via `new URL` | yes |
| VC5-01 | 3 | read plan § Address hash vs limits.ts | first XFF entry/`unknown`, HMAC-SHA256 10 hex all match; Plan/step says the room name has a random suffix (`concierge-<addr10>-<12 hex>`); D72 (VC5-07) changed it to `concierge-<addr10>` with no suffix (step says `randomBytes(6)` suffix, code has none) | no |
| VC5-01 | 4 | read plan § Modules; ls tests | origin.ts/limits.ts/rooms.ts, limits test file with `jest.mock` of rooms, token-route test mocks nothing; Modules table still lists `randomBytes` import (stale) but names hold | yes |
| VC5-01 | 5 | read § Mic timing, § /talk busy states; data/concierge.ts | mic moved to agentArrived, toggle live-only, busy action/copy matches (lines 44-45) | yes |
| VC5-01 | 6 | read § Live check, D63–D67 in spec | curl no Origin/evil/preview, two tabs, CONCIERGE_MAX_ROOMS, undo, agent-room-name caveat all present; D63–D67 at spec lines 126–143 | yes |
| VC5-01 | 7 | `.harness/check.sh` (cached green) + `node .harness/smoke.mjs`; `npx jest --silent` | check: green; smoke all PASS; 81 suites, 1114 tests pass | yes |
| VC5-02 | 1 | `grep -n 'setMic(session, true)' TalkSession.tsx` | one line (272), inside agentArrived | yes |
| VC5-02 | 2 | read TalkSession-live.test.tsx 61–113, TalkSession.test.tsx micCalls | 0 calls after connect without agent, `[[true]]` after addAgent, 0 on offline/unconfigured paths; pass in jest run | yes |
| VC5-02 | 3 | grep tests for 'Mute microphone'; jest run | button absent while waiting, present when live (D65); talk and a11y tests pass | yes |
| VC5-02 | 4 | read plan § Mic timing; docs/review-guide.md line 108 | plan matches code; guide says mic asked once concierge has joined | yes |
| VC5-02 | 5 | `.harness/check.sh` (cached green) + `node .harness/smoke.mjs`; `npx jest --silent` | check: green; smoke all PASS; 81 suites, 1114 tests pass | yes |
| VC5-03 | 1 | read concierge-origin.test.ts + origin.ts; jest | origin.ts logic yields every listed true/false case (no-throw on non-URL); suite passes | yes |
| VC5-03 | 2 | read concierge-limits.test.ts line 10,47 + limits.ts | addressOf/addressBucket/roomsVerdict/maxRooms hold; BUT roomNameFor test asserts `/^concierge-[0-9a-f]{10}$/` and no 'two calls differ' (D72), contradicting the step's `-[0-9a-f]{12}` regex | no |
| VC5-03 | 3 | `grep -n server-only package.json`; `npm ls server-only`; `grep -L` | `"server-only": "0.0.1"` exact; npm ls 0.0.1; grep -L prints nothing; rooms.ts exists | yes |
| VC5-03 | 4 | read TalkSession-import.test.tsx; `grep -rl livekit-client src/app` | counting jest.mock proves 0 loads unconfigured, 1 configured; grep empty | yes |
| VC5-03 | 5 | read CLAUDE.md Code rules; plan § server-only | server-only named (D67); modules listed | yes |
| VC5-03 | 6 | `.harness/check.sh` (cached green) + `node .harness/smoke.mjs`; `npx jest --silent` | check: green; smoke all PASS; 81 suites, 1114 tests pass | yes |
| VC5-04 | 1 | read route.ts; `grep -n console route.ts` | order 403→503→400→503→429→200 as stated, no-store on all, no console (grep empty) | yes |
| VC5-04 | 2 | read concierge-token-route.test.ts; ran curls on :7834 | no Origin 403, evil 403, localhost 503 (dev); tests pass | yes |
| VC5-04 | 3 | read concierge-token-route-limits.test.ts lines 19,83-91,156 | ROOM regex is `^concierge-([0-9a-f]{10})$` (no 12-hex suffix) and test title still says `-<12 hex>`; other cases (429s, 200 with MAX=4, 503, unknown bucket) pass; step's `-<12 hex>` regex does not hold (D72) | no |
| VC5-04 | 4 | read concierge-token-route-sdk.test.ts | bad id and 403 reach no SDK or listLiveRooms call; passes | yes |
| VC5-04 | 5 | read plan § Route behaviour + CLAUDE.md token row | matches code (room names updated per D72) | yes |
| VC5-04 | 6 | `.harness/check.sh` (cached green) + `node .harness/smoke.mjs`; `npx jest --silent` | check: green; smoke all PASS; 81 suites, 1114 tests pass | yes |
| VC5-05 | 1 | read data/concierge.ts 44-45; sessionReducer.test.ts | both sentences present; reducer busy cases pass | yes |
| VC5-05 | 2 | read TalkSession.test.tsx 179-232 | both reasons, unknown reason → offline, fetch count 1 after 15 s, no Room, mic 0; pass | yes |
| VC5-05 | 3 | read projects.ts line 800; evidence note; jest | protection sentence in build copy; digit sentences covered by case-study and content-guard tests (pass) | yes |
| VC5-05 | 4 | `grep -n 'Cost protection' docs/notes/voice-concierge-todo.md` | § at line 48 | yes |
| VC5-05 | 5 | `.harness/check.sh` (cached green) + `node .harness/smoke.mjs`; `npx jest --silent` | check: green; smoke all PASS; 81 suites, 1114 tests pass | yes |
| VC5-06 | 1 | Read VC5-talk-busy-visitor-390.png; sizes via PIL; read plan table | 3 PNGs 56/58/75 KB, 390×844 / 1280×800; visitor line + Connect visible; plan rows exist | yes |
| VC5-06 | 2 | reran .harness/talk-busy-check.mjs on :7834 (no dummy env; a second server on 7835 failed on the .next lock); read TalkSession.test.tsx 200 | rerun: 0 token requests because Connect skips the route without env (D46), so it can't re-prove 1/Connect; Jest: 429 → fetch called once over 15 s, getUserMedia 0, 0 errors in rerun; prior run documented in plan | yes |
| VC5-06 | 3 | curl x3 on :7834 | 403, 403, 503 | yes |
| VC5-06 | 4 | rerun script focus line | focus Connect, outline rgb(0, 212, 255), focusVisible true | yes |
| VC5-06 | 5 | read plan § What Michael will see lines 394-400 | one row per screenshot and curl line, with the 3 columns | yes |
| VC5-06 | 6 | `.harness/check.sh` (cached green) + `node .harness/smoke.mjs`; `npx jest --silent` | check: green; smoke all PASS; 81 suites, 1114 tests pass | yes |
| VC5-07 | 1 | read plan § Review; grep LIVEKIT_/server-only in src/components src/lib/data | review table with answers present; grep finds only copy text unrelated to env (no `LIVEKIT_` or server-only import) | yes |
| VC5-07 | 2 | read docs/review-guide.md 151+, line 108 | § VC5 present with staged check, room list, undo; mic line updated | yes |
| VC5-07 | 3 | read CLAUDE.md; jest tail | rows/lines name origin/limits/rooms, order, server-only, limits test and mock; count 1114 tests/81 suites matches | yes |
| VC5-07 | 4 | read spec § 7 and vc4 spec Built note | D59–D72 each in spec, Built note at line 69 | yes |
| VC5-07 | 5 | `.harness/check.sh` (cached green) + `node .harness/smoke.mjs`; `npx jest --silent` | check: green; smoke all PASS; 81 suites, 1114 tests pass | yes |


### 2026-10-20 17:50 · VC5-07 · passes

- Opus review of `git diff e409a14^..HEAD`: no Critical. **Important, fixed (D72 *default*):** a forged-Origin shell could mint N tokens from one address before any room existed (each got a random room) → N agents. `roomNameFor` is now `concierge-<addr10>` (no random part), and `roomsVerdict` matches that exact name, so a burst of tokens shares one room and one agent dispatch (the token's roomConfig applies only to the join that creates the room). Tests first: 10 failed, then passed. Simplification: `mic`/`micBlocked` apply only when `live` (2 failed, then passed). `tsc --noEmit` went from 4 test-file errors to 0. Tests 1113 → 1114 (81 suites).
- Docs: plan § Review table and 7 answers, the known-limits note and D72; review guide § VC5 (what changed, the 4-stage live check, the room list, undo for each piece); CLAUDE.md token row (room per address) and count; D61/D68/D70/D71 now name what they supersede; the VC4 spec has a dated Built note with D59–D72 and the two things to confirm.
- Verified: `.harness/check.sh` → `check: lint ok · jest ok · build ok`; smoke exit 0 (42 PASS) at start and end; `grep -rn 'LIVEKIT_\|server-only' src/components src/lib/data` empty; SDK 2.19.1 `AbortSignal.timeout(timeout * 1e3)` checked.
- Not fixed: `TalkSession-review.test.tsx` › "a draft from a call that ended…" still logs "A component suspended inside an act scope". It fires during the `disconnected` emit and comes from a jsdom timer after `user.type`. It is test noise from before VC5 and doesn't fail anything.
- Questions for Michael: **D72**: keep one room per address? Side effect: two people behind one NAT who press Connect in the same second share a room. Undo is in `limits.ts` alone. Still open: D64 (preview regex vs exact `VERCEL_URL`), D68, D70 (TTL 60 s?), D71 (another-tab wording), and the offline line's missing full stop.
- Confirm on the live check: the agent doesn't parse room names (now `concierge-<10 hex>`), and the preview regex matches your previews.

### 2026-10-20 17:05 · VC5-06 · passes

- New `.harness/talk-busy-check.mjs` (Playwright, `page.route` fulfils every token POST) and four captures in `docs/screenshots/v2/`: `VC5-talk-busy-visitor-390.png` 56 KB, `VC5-talk-busy-site-390.png` 57 KB, `VC5-talk-busy-visitor-1280.png` 73 KB, `VC5-talk-offline-503-390.png` 55 KB. Plan § What Michael will see filled (7 rows: 4 captures, 3 curl lines). No code change; tests 1113 → 1113 (81 suites).
- How: `/talk` only fetches with LiveKit env (D46), so I restarted the 7834 dev server with dummy values (`wss://livekit.invalid`), ran the script (30 OK, 0 FAIL), then put the plain server back. Measured: Connect bottom y 664 at 390×844 (above the fold), 489 at 1280; scrollWidth 390; 1 POST per Connect over 15 s (2 presses → 2); getUserMedia 0; no mic toggle; focus stays on "Connect", `:focus-visible`, outline `rgb(0, 212, 255)`; only Chromium's 429/503 resource line in the console.
- curl on the plain server: no Origin → 403, `Origin: https://evil.example` → 403, `Origin: http://localhost:7834` → 503.
- Verified: `check: lint ok · jest ok · build ok` (1113/81); smoke exit 0 (42 PASS) at start and end.
- Next session: `kill $(cat server.pid)` leaves next-server running (the pid is the npx wrapper). Kill the pid holding the port (`ss -ltnp`) before restarting, or the new server dies with EADDRINUSE and you test the old one.
- Question for Michael (copy): "The concierge is offline right now" has no full stop; both busy lines have one. Add it (spec W2 wording + one pinned test)? D71 still open.

### 2026-10-20 16:30 · VC5-05 · passes

- `sessionReducer.ts`: `BusyReason`, phase `busy` (from `connecting` only), `busyReason` (null in `initialSession`); Connect/Leave reset it; `inRoom('busy')` false. `TalkSession.tsx`: `fetchCredentials` returns `{kind:'ok'}` | `{kind:'busy', reason}` (429 + `error:'busy'` + visitor|site only) | null; busy releases the session and dispatches, no timer, no refetch; the status line is one `statusLine` value; deep-dive link under busy too (D66). Copy `busyVisitor`/`busySite` in `concierge.ts`. Tests 1079 → 1113 (81 suites).
- Content: protection sentence appended to the voice-concierge `caseStudy.method.build`, verbatim row in `evidence-voice-concierge.md` § Sentences with digits, pinned by a new test; `voice-concierge-todo.md` § Cost protection (three layers, where to change each). Plan § /talk busy states has "As built (VC5-05)"; CLAUDE.md count and phases line.
- Verified: `.harness/check.sh` → `check: lint ok · jest ok · build ok`; smoke exit 0 (42 PASS) at start and end. Busy tests run 15 s of fake timers with `fetchMock` at 1 call, 0 `MockRoom` instances, no mic calls; a 429 with `reason:'other'`, another error or no body, and a busy body on a 503, read offline. Mutation: dropping the `session.alive` check after the fetch fails the new late-429 test.
- Opus review: no Critical. Applied: late-429-after-Leave and late-429-into-second-Connect tests; the focus test now starts on `<body>` (exercises the refocus effect); todo note names `127.0.0.1`. Not taken: the page line "accepts only this site's origin" (previews are the site's; the step's wording).
- Pre-existing, for VC5-07: `TalkSession-review.test.tsx` logs "A component suspended inside an act scope" (also on HEAD before this change).
- Question for Michael (D71): "You already have a conversation open in another tab." is also shown for ~30 s after Leave (D68) and to a second person on the same NAT (conference Wi-Fi). Keep it, or "A conversation from your network is still open. Try again in a minute."?
- Next (VC5-06): with no LiveKit env `/talk` never fetches (`configured={false}`), so a browser can't reach busy on the dev server; screenshots of it need the component rendered with `configured` and a stubbed route.

### 2026-10-20 15:50 · VC5-04 · passes

- `route.ts` now checks Origin (403 `forbidden`, before env, D63) → env (503) → body (400) → `listLiveRooms` (503, error dropped) → `roomsVerdict` (429 `busy` visitor|site) → token for `roomNameFor(bucket)`; no `console`, `profile` from `@/lib/data`, `node:crypto` import gone. Tests 1052 → 1079 (80 → 81 suites): new `concierge-token-route-limits.test.ts` (rooms mocked by factory, real SDK; the VC1 200 cases moved here, D69); `concierge-token-route.test.ts` still mocks nothing, sends the site Origin, adds 6 × 403/dev/prod cases (`jest.replaceProperty` for production); the sdk test shows a bad id and a 403 reach neither SDK spy nor `listLiveRooms`.
- Docs: CLAUDE.md token row (the plan's draft), a Testing note and the count; plan § Route behaviour has "As built (VC5-04)"; the VC1 plan's table is marked superseded in part.
- Verified: `check: lint ok · jest ok · build ok`; smoke exit 0 (42 PASS) at start and end; `grep -n console route.ts` empty. On `next dev` :7834 with no env, no Origin and `https://evil.example` → 403, `http://localhost:7834` and the site origin → 503. Mutations: logging the bucket fails 3 tests; dropping the 429 fails 5.
- Opus review: no Critical or Important issues. Applied: the route comment now says the bucket is in the caller's own token (D70); the no-leak test also decodes the JWT and checks the address isn't in it.
- For VC5-07: `npx tsc --noEmit` reports 3 errors that came in before this change (`booth-bundle.test.ts:92` `MH_HARNESS_HOME`, `concierge-rooms.test.ts:21,39` `mockResolvedValue` typed `never`). `next build` passes anyway; fix them in the cleanup pass.
- Next session (VC5-05): `/talk` busy states. A 403 from the route reads as offline today (any non-OK reply).
- D64 question still open (preview regex vs exact `VERCEL_URL`/`VERCEL_BRANCH_URL`); the route passes only `siteUrl` and `dev`, so switching needs only the extra `opts`.

### 2026-10-20 15:20 · VC5-03 · passes

- New `src/lib/concierge/origin.ts` (`isAllowedOrigin`), `limits.ts` (`addressOf`, `addressBucket`, `roomNameFor`, `roomsVerdict`, `maxRooms`, pure) and `rooms.ts` (`import 'server-only'`, `listLiveRooms` with `requestTimeout: 5, failover: false`, not wired yet). `env.ts` line 1 is `import 'server-only';`. `server-only@0.0.1` is an exact dependency (lockfile updated). CLAUDE.md Code rules name it (D67), and the `lib/concierge/` line names the new modules. Tests 1017 → 1052 (76 → 80 suites): `concierge-origin`, `concierge-limits`, `concierge-rooms` and `TalkSession-import.test.tsx`.
- The import test has its own file, as the plan says (step 4 allows an equivalent). It reaches the mock through `jest.requireActual`: a static import of `@/__mocks__/livekit-client` is the same module path as the mapped `livekit-client`, so it would run the counting factory. Mutation check: moving the `configured` guard below the import makes the zero case fail (1).
- Verified: `check: lint ok · jest ok · build ok`; smoke exit 0 (42 PASS) at start and end; `grep -L` on env/rooms prints nothing; `grep -rl livekit-client src/app` is empty; `npm ls server-only` → 0.0.1.
- Opus review: no Critical issues. Applied: `maxRooms` now also requires `Number.isSafeInteger` (a 20-digit value or Infinity would switch the cap off), plus tests for `'03'`, `:443` and a trailing-dot host.
- Question for Michael (D64, important): the preview regex also matches a Vercel project someone else names `portfolio-site-evil-mh550s-projects` (its `<name>.vercel.app` host), so a page there could spend tokens through its visitors' browsers. Should the allowlist be exactly `https://$VERCEL_URL` + `https://$VERCEL_BRANCH_URL` instead? **Proposed change:** if yes, VC5-03 step 1's `portfolio-site-abc123-…` → true case goes, and VC5-04 passes those two env values into `opts`.
- Next session (VC5-04): wire `listLiveRooms` + `roomsVerdict` into the route in the plan's order. `[::1]` is not a dev origin (browse `localhost`).

### 2026-10-20 14:55 · VC5-02 · passes

- `TalkSession.tsx`: `setMic(session, true)` moved into `agentArrived` (one line, :254; both arrivals go through it, guarded by `agentIdentity`), and the mic toggle renders only when `phase === 'live'` (D65). Tests 1012 → 1017 (76 suites): five new mic tests in `TalkSession-live.test.tsx` (none after connect alone, `[[true]]` after addAgent, agent already present, one per Room across Leave/Connect, a second agent and a reconnect add nothing, no toggle while waiting) plus `micCalls()` = [] on configured=false, 503, rejected connect() and the 10 s timer in `TalkSession.test.tsx`.
- Two helpers that added the agent in a sync `act` (`liveRoom`, the 3 000 ms test) became `await act(async …)`: the mic's answer now lands after the arrival, and without this React logged an act warning.
- Docs: plan § Mic timing has an "As built (VC5-02)" note; review guide morning step 2 says the browser asks for the mic once the concierge has joined; the VC2 plan's state-table rows and its VC2-05 note are marked superseded by D65; CLAUDE.md count is now 1017.
- Verified: `.harness/check.sh` → `check: lint ok · jest ok · build ok`; smoke exit 0 (42 PASS). The Opus reviewer found no Critical or Important issues. I applied its Minor test gaps.
- Next session (VC5-03) / VC5-07 Minors not taken: the reducer still accepts `mic`/`micBlocked` in connecting/waiting, which can no longer happen (trim it in VC5-07's simplification pass). While the browser's prompt is open the toggle reads "Unmute microphone" but a press mutes (`micWanted` is true); this is old behaviour that every session now hits. Consider disabling the toggle until the first answer.

### 2026-10-20 14:40 · VC5-01 · passes

- New plan `docs/plans/2026-10-20-VC5-mic-limits-server-only.md` (Mic timing, Route behaviour table 403→503→400→503→429 visitor→429 site→200, Origin rules with the preview regex checked against PR #16's host, Address hash, Modules, /talk busy states, server-only, Tests per feature, staged Live check, CLAUDE.md draft, empty What Michael will see/Review, Decisions). D63–D70 appended to `docs/specs/2026-10-19-voice-concierge-page.md` § 7. No code; tests unchanged at 1012/76.
- Verified: `.harness/check.sh` → `check: lint ok · jest ok · build ok`; smoke exit 0 (every route at 1280 and 390). An Opus reviewer checked the plan against the code. Fixes it led to, each confirmed in source: next/jest already maps `server-only` (no mapper of our own); `next dev` fills `x-forwarded-for`; `NODE_ENV` is readonly in TS, so use `jest.replaceProperty`; rooms mocks need `mockResolvedValue([])`; the livekit-client import test goes in its own file (isolateModules + render breaks hooks).
- Next session (VC5-02): mic → `agentArrived`, toggle only when `live` (D65). VC5-03: the import test is `TalkSession-import.test.tsx`, not `TalkSession.test.tsx` (see plan § server-only).
- Questions for Michael: (D68) after Leave the address reads "another tab" until LiveKit closes the room (≥20 s; minutes if the agent keeps the room). Keep counting every listed room (fail closed), or only rooms with a `visitor-` participant? (D70) A shell that forges Origin can mint many tokens and join them all at once, so only the provider caps bound it. Cut the token TTL from 600 s to about 60 s? (D64) Does the preview regex match your current previews? Also confirm `mh550/voice-concierge` doesn't parse room names (no agent code is checked out locally).
- Proposed changes: VC5-01 step 3 says addr10 never appears in a response, but the visitor's own JWT carries their room name; the plan narrows this to "never in plain text" (D70). VC5-03 step 4 names `TalkSession.test.tsx`; the plan puts the test in `TalkSession-import.test.tsx` (step 4 allows an equivalent).

### 2026-10-20 18:00 · verify VC4

All 6 features hold (35 steps).

| Feature | Step | What you ran or read | What you saw | Holds |
|---|---|---|---|---|
| VC4-01 | 1 | read plan headings + § Order table | all 8 sections present; order table 1–10 matches; getTopProjects(3) = agent-harness, voice-concierge, ghl-jobtread-integration stated | yes |
| VC4-01 | 2 | read plan § Voice widget | file, next/link, aria-label, svg, safe-area bottom, h-14, z-40, focusRing, print:hidden, motion-safe pulse, Footer pb-24 xl:pb-8 all specified | yes |
| VC4-01 | 3 | read plan § Intro wording and concierge.ts/projects.ts | intro first sentence verbatim, link shape, builtWith keeps 'Claude Code agents' and names harness | yes |
| VC4-01 | 4 | grep spec § 7 and v2 spec | ## 7 Decisions with D59–D62; 'Superseded by D60 (VC4).' after D44 and D49 | yes |
| VC4-01 | 5 | read plan § Tests; ran npx jest --silent | table lists data.test, case-study, Navbar tests by name; suite now 1012 tests/76 suites (later milestones add tests; plan-time count was for that commit) | yes |
| VC4-01 | 6 | check.sh (cached green) + node .harness/smoke.mjs | green; every route PASS at 1280 and 390 | yes |
| VC4-02 | 1 | grep order in projects.ts; read data.test.ts lines 54–83; jest | orders 1..10 exactly as listed; map test, uniqueness, getTopProjects(3) assertions present; jest green | yes |
| VC4-02 | 2 | read case-study test line 30, card.test:65, home.test:38; git diff main..HEAD -- '*.snap' | order toBe(2); hrefs[1]=/projects/voice-concierge in both; no .snap diff | yes |
| VC4-02 | 3 | read Navbar.tsx links, Navbar.test.tsx; grep -c | 8 links, Talk fifth; /talk test marks Talk; grep count 1; live menu lists 8 links in order | yes |
| VC4-02 | 4 | grep spec/CLAUDE.md | D44 and D49 followed by 'Superseded by D60 (VC4)'; CLAUDE.md /talk row says on the Navbar (D60); only /evidence is 'off the Navbar' | yes |
| VC4-02 | 5 | grep docs/review-guide.md | 'order 5' line says VC4 moved it to order 2 (D59) | yes |
| VC4-02 | 6 | check.sh + smoke | green / all PASS | yes |
| VC4-03 | 1 | read VoiceWidget.tsx and VoiceWidget.test.tsx | link /talk, aria-label, aria-hidden svg, fixed right-4, print:hidden, h-14 w-14, safe-area bottom, motion-safe:animate-pulse; tests assert these and no bare animate- | yes |
| VC4-03 | 2 | read SiteChrome.tsx and SiteChrome.test.tsx 70–95 | widget after Footer when pathname !== '/talk'; it.each / /about /projects/agent-harness present, /talk absent, /card and /card/qr absent; live: widget count 1 on /,/about,/projects, 0 on /talk,/card | yes |
| VC4-03 | 3 | a11y-new-pages.test:86 and VoiceWidget.test 'adds no heading and no landmark' | navigation count unchanged (1), widget adds none; jest green | yes |
| VC4-03 | 4 | Footer.tsx + Footer.test:48; own Playwright at 390 | pb-24 xl:pb-8 asserted; scrollWidth 390 on / /about /projects; widget box x318 y772 56x56 clear of footer links | yes |
| VC4-03 | 5 | read plan § Voice widget and spec D61 | classes, label, pathname rule match code; D61 names component and exclusions | yes |
| VC4-03 | 6 | check.sh + smoke | green / all PASS | yes |
| VC4-04 | 1 | read concierge.ts intro; grep 'writing much of the code' src/ | new first sentence verbatim, link /projects/agent-harness in data; grep empty | yes |
| VC4-04 | 2 | read talk.test.tsx 43–60, concierge-data.test:17; live /talk | link 'my agent harness' href /projects/agent-harness asserted; full intro text asserted; no-digit and no 'Claude Code agents writing' asserted; live href correct | yes |
| VC4-04 | 3 | read projects.ts builtWith and Links; jest | builtWith names harness, keeps 'Claude Code agents', says harness ran build sessions; link 'The agent harness that built it' (kind doc) present; evidence-verbatim test passes (jest green) | yes |
| VC4-04 | 4 | read evidence-voice-concierge.md and spec D62 | dated '## VC4 note (2026-10-20)' with source; D62 quotes final intro | yes |
| VC4-04 | 5 | check.sh + smoke | green / all PASS | yes |
| VC4-05 | 1 | ls -la docs/screenshots/v2/VC4-* | six named PNGs exist, 53–300 KB each, under 400 KB; /card live order confirmed agent-harness, voice-concierge, ghl-jobtread | yes |
| VC4-05 | 2 | own Playwright 390x844 on /about bottom, five pages | widget y772 h56 (bottom 828 = 844-16); no intersect with GitHub/LinkedIn/Email; scrollWidth 390 on / /about /projects /talk /card; 0 console/page errors | yes |
| VC4-05 | 3 | Playwright emulate reducedMotion on / | reduce -> animation-name none; no-preference -> pulse | yes |
| VC4-05 | 4 | Playwright Tab x22 on / at 1280 | order: Skip, MH, 8 nav links Talk fifth, page links, footer, widget; widget :focus-visible outline rgb(0, 212, 255) 2px | yes |
| VC4-05 | 5 | node .harness/print-check.mjs http://localhost:7834 / …/p.png | PASS print, exit 0; widget print:hidden (class asserted in test) | yes |
| VC4-05 | 6 | read plan § What Michael will see | six rows, one per screenshot, plus measurements | yes |
| VC4-05 | 7 | check.sh + smoke | green / all PASS | yes |
| VC4-06 | 1 | read plan § Review | 14-row table covering name, z-index, Footer, reduced motion, eight links at 390, intro honesty; Minor fixes with tests; no Critical/Important | yes |
| VC4-06 | 2 | grep -rniE tailnet/CGNAT/ntfy on VoiceWidget.tsx concierge.ts; jest content-guard | grep empty; full jest 1012 pass incl. content-guard | yes |
| VC4-06 | 3 | read CLAUDE.md lines 26–31, 41, 81–86; npx jest --silent | eight-link Navbar line, VoiceWidget line, /talk row, '1012 tests, 76 suites' matches jest output | yes |
| VC4-06 | 4 | read docs/review-guide.md § VC4: order, Navbar, widget | what changed, 390 look-at list, captures; undo notes present | yes |
| VC4-06 | 5 | check.sh + smoke | green / all PASS | yes |

### 2026-10-20 16:25 · VC4-06 · passes

- **Review** (Opus, `$HARNESS_SCRATCH/VC4.diff` = `git diff f9e8a58..HEAD`, 1356 lines, both skills): plan § Review is a
  14-row table; widget name, z-index vs Navbar/menu/skip link, Footer clearance (`xl` is the first breakpoint ≥ 1248),
  reduced motion, eight links at 390/768 and the intro's honesty all hold. Nothing Critical or Important.
- **Minor fixes taken**: Navbar mobile menu `max-h-[calc(100dvh-4rem)] overflow-y-auto` (new test failed first; at
  740×360 the menu is 295 px and scrolls to Contact, at 390×844 unchanged, 304 px); talk test splits class tokens;
  VoiceWidget test pins `motion-safe:[animation-iteration-count:2]`; `/talk` keys paragraphs by `introText(p)`;
  SiteChrome excludes `talkWidget.href`, not a `'/talk'` literal. Tests 1011 → 1012, 76 suites.
- **Docs**: review guide § "VC4: order, Navbar, widget" (changes, what to look at at 390, captures, undo per piece);
  CLAUDE.md /talk row, VoiceWidget line (where it shows), counts.
- Verified: `.harness/check.sh` → `check: lint ok · jest ok · build ok`; smoke exit 0, 42 PASS; the ts.net/CGNAT/ntfy
  grep on VoiceWidget.tsx and concierge.ts is empty, content guard green.
- **Question for Michael**: `builtWith` says "a second run is writing the agent" (present tense); change it once the
  agent run is done? Not taken (optional): a visible hover/focus label on the mic disc; an `@theme` pulse token.
- **Proposed change**: step 3's "the /talk Routes row … has the widget" read as "mentions the widget"; the row says
  the widget on other pages links here and is not shown on `/talk` (D61).

### 2026-10-20 15:40 · VC4-05 · passes

- **Screenshots** (new, 53–300 KB): `docs/screenshots/v2/VC4-home-390.png`, `VC4-home-1280.png`, `VC4-about-footer-390.png`,
  `VC4-card-390.png`, `VC4-menu-390.png`, `VC4-talk-390.png`; plan § What Michael will see has one row per screenshot
  plus the numbers. No layout bug found, so no code change; tests stay 1011, 76 suites.
- Measured (Playwright on 7834, script `$HARNESS_SCRATCH/vc405/run.mjs`): `/about` bottom at 390×844, widget 318,772
  56×56 (bottom 828), footer links y 726.5–745.5, 0 intersections; scrollWidth 390 on / /about /projects /talk /card,
  0 console/page errors; pulse `none` under reduce, `pulse` ×2 otherwise; Tab order Skip, MH, 8 links (Talk 5th), page
  links, footer, widget at tab 22, outline `rgb(0, 212, 255)` 2px offset 4; `/card` top 3 agent-harness,
  voice-concierge, ghl; print-check `/` exit 0, widget `display: none`. Navbar at 768: one row, 82 px spare.
- Gotcha for later checks: read `outline-color` ~200 ms after Tab; `transition-colors` (Tailwind 4) animates it from
  currentColor, so a same-frame read gives `rgb(10, 10, 15)` on the widget. Not a bug.
- Captures hide Next's dev-only "N" indicator (`nextjs-portal{display:none}`); production has none.
- Verified: `.harness/check.sh` → `check: lint ok · jest ok · build ok` (1011 passed); smoke exit 0, 42 PASS.
- Next (VC4-06): the Opus review + simplify of the VC4 diff (`git diff f9e8a58..HEAD`).

### 2026-10-20 15:05 · VC4-04 · passes

- **Intro (D62)**: `concierge.ts` gains `IntroParagraph` + `introText`; `talkPage.intro[0]` is `{ before, link: { label:
  'my agent harness', href: '/projects/agent-harness' }, after }` ("A voice agent I designed on LiveKit and built with
  my agent harness: specs in, verified milestones out. It remembers you between visits."). `talk/page.tsx` renders it
  with `next/link` (accent, underline, `focusRing`). `grep -rn 'writing much of the code' src/` is empty.
- **Deep-dive**: `voice-concierge` `builtWith` is the plan's sentence ("My agent harness ran the build sessions…");
  `caseStudy.links[2]` = "The agent harness that built it" → `/projects/agent-harness`, kind `doc`.
- Docs: evidence brief § VC4 note (before/after table), D62 marked built, CLAUDE.md (intro shape, 1011 tests).
- Tests: talk +1 (link name/href/focusRing; paragraphs by `textContent`), concierge-data +1, case-study +1 (full
  `builtWith`), links test gains the third entry. 1008 → 1011, 76 suites; 5 failed before the code, 0 after.
- Verified: `.harness/check.sh` → `check: lint ok · jest ok · build ok`; smoke exit 0, 42 PASS; live HTML on 7834 shows
  the anchor inside the `<p>` and the deep-dive link; 390 px `/talk` screenshot checked. Opus review: no findings.
- Next (VC4-05): screenshots. Pre-existing, not mine: `npx tsc --noEmit` flags `booth-bundle.test.ts:92`
  (`MH_HARNESS_HOME` not on the env type); the build is unaffected (tests are outside it).

### 2026-10-20 14:25 · VC4-03 · passes

- **Widget (D61)**: new `src/components/VoiceWidget.tsx` (next/link to `/talk`, aria-label from `talkWidget` in
  `concierge.ts`, aria-hidden SVG mic, `fixed right-4 bottom-[max(1rem,env(safe-area-inset-bottom))] z-40 h-14 w-14`,
  `print:hidden`, `focusRing` + `focus-visible:outline-offset-4`, ring with `motion-safe:animate-pulse` ×2).
  `SiteChrome` renders it after the Footer unless `pathname === '/talk'` (`/card*` never reaches it). Footer
  `py-8` → `pt-8 pb-24 xl:pb-8`.
- Tests: new `VoiceWidget.test.tsx` (7), SiteChrome +6 (`/`, `/about`, `/projects/agent-harness` present and after
  the footer; `/talk`, `/card`, `/card/qr` absent), Footer +1, a11y chrome +1 (one nav, one contentinfo, no
  region/heading). 993 → 1008 tests, 75 → 76 suites; 5 failed before the code, 0 after.
- Review (Opus): the offset-2 focus outline sat on the ring's 2–4 px band (60% → 100% cyan only); fixed with
  `outline-offset-4` (Chromium computes 4px; capture shows a separate outer ring). Plan § Focus and D61 updated.
- Browser (Sonnet, 7834): 56×56 at 390/1280, right edge 374 at 390, scrollWidth 390; absent on /talk, /card,
  /card/qr; no overlap with `footer a` on /about bottom at 390/640/768/1024/1279/1280/1440; reduced motion
  `animation-name: none`, otherwise `pulse` ×2; last tab stop after "Email"; print `display: none`.
- Verified: `.harness/check.sh` → `check: lint ok · jest ok · build ok`; smoke exit 0, 42 PASS.
- Next (VC4-04): intro wording. CLAUDE.md lists VoiceWidget and the new count.

### 2026-10-20 13:50 · VC4-02 · passes

- **Order (D59)** in `projects.ts`: 1 agent-harness, 2 voice-concierge, 3 ghl, 4 ringcentral, 5 home-media-server,
  6 linear-ai-workflow, 7 hit-list, 8 paint-estimator, 9 mirrored, 10 cherished. Top 3 on `/` and `/card` is now
  agent-harness, voice-concierge, ghl-jobtread-integration (live `/card` HTML shows those three in that order).
- **Navbar (D60)**: `{ href: '/talk', label: 'Talk' }` fifth of eight; `/talk` marks only Talk (desktop + mobile).
- Tests: data.test (D59 map, both getTopProjects lists), case-study voice-concierge 2 / home-media-server 5 /
  hit-list 7, home + card assert link 2 is `/projects/voice-concierge`, Navbar eight links + new `/talk` test.
  992 → 993 tests, 75 suites; no `.snap` change. Saw 12 failures before the code change, 0 after.
- Docs: CLAUDE.md (`/talk` row "on the Navbar, D60", Navbar line, D59 note on `/projects/[slug]`, test count),
  review guide VC3 bullets (order 5 → D59, new top 3; question answered). v2 D44/D49 already end "Superseded by D60".
- Verified: `.harness/check.sh` → `check: lint ok · jest ok · build ok`; smoke exit 0, 42 PASS.
- Next (VC4-03): the widget; the Navbar width at 768 with eight links is still VC4-05's to look at.

### 2026-10-20 13:27 · VC4-01 · passes

- **Plan** `docs/plans/2026-10-20-VC4-order-widget-nav.md`: § Order (before/after table; top 3 becomes agent-harness,
  voice-concierge, ghl-jobtread-integration on `/` and `/card`), § Navbar (Talk fifth of eight), § Voice widget (full
  TSX; `talkWidget` data in `concierge.ts`; opacity pulse ×2 under `motion-safe:` only, not `animate-ping`, which
  would overflow at 390), § Intro wording (`IntroParagraph = string | {before, link, after}`; `builtWith` stays a
  string + a third Links entry, kind `doc`), § Tests (every breaking test by file and name), empty Review/See tables.
- **Decisions**: voice-concierge spec gains `## 7. Decisions` D59–D62; v2 spec D44/D49 end "Superseded by D60 (VC4).",
  D47 "Superseded by D59 (VC4)."
- **Footer default** (D61): `pt-8 pb-24 xl:pb-8`, not `pb-24 sm:pb-8`: at 390 the links are centred and never meet
  the widget; the overlap is from `sm` to below `xl`, where the links row sits at the right edge.
- **Next sessions**: init note had paint-estimator 8 / ringcentral 7; the file says paint 7 / ringcentral 8 (the plan
  follows the file). hit-list and home-media-server tests pin `order` 4 and 3 too (now 7 and 5), listed in § Tests.
- Verified: jest 992 tests / 75 suites (no code change), `.harness/check.sh` → `check: lint ok · jest ok · build ok`,
  smoke exit 0 (42 PASS).
- Question for Michael: should `/evidence` (noindex) also lose the widget? Default: it keeps it.

### 2026-10-20 · initializer

**Scope.** The spec `docs/specs/2026-10-20-vc4-order-widget-limits.md` (Michael's answers of 10-20) and his brief:
build VC4 then VC5, sensible defaults recorded in the spec, no questions, build-only, don't touch `public/b/`.
The base has VC1–VC3 and B1–B2 (PRs #14–#18, all merged). Suite at start: 992 tests, 75 suites, green; dev server
on `$HARNESS_PORT` (7834 at init).

**Features: 13.** VC4 (content and navigation): 6 — plan, order + Navbar, widget, intro wording, check, review.
VC5 (mic timing, limits, server-only): 7 — plan, mic, pure rules + server-only, route wiring, /talk busy lines +
deep-dive protection line, check, review. VC5-01 has `after: ["VC4"]` (the spec: one PR per milestone, in order).
Earlier VC features took 5–20 minutes each; these are sized the same.

**Where things live (read before building).**
- Order: `order` on each entry of `src/lib/data/projects.ts` (today 1 agent-harness, 2 linear-ai-workflow,
  3 home-media-server, 4 hit-list, 5 voice-concierge, 6 ghl, 7 ringcentral, 8 paint-estimator, 9 mirrored,
  10 cherished). `getTopProjects(3)` = first three **featured** by order → feeds `/` Recent work and `/card`
  Selected work (both tests derive from it). Pinned explicitly in `src/__tests__/lib/data.test.ts` (the order map,
  getTopProjects lists) and `case-study-voice-concierge.test.ts` (`order` 5). The `.snap` file is per-slug and has
  no order. `docs/review-guide.md` VC3 bullets say "order 5 … top 3 unchanged": update them.
- Navbar: `src/components/Navbar.tsx` `links` array (desktop `ul` and mobile menu both map it);
  `Navbar.test.tsx` pins seven names twice (lines 22 and 51) and a current-page test. v2 spec D44/D49 and CLAUDE.md
  say "off the Navbar": supersede, don't delete.
- Site chrome: `src/components/SiteChrome.tsx` (`"use client"`, reads `usePathname`) already excludes `/card*`; the
  widget goes there, with `/talk` excluded too. `SiteChrome.test.tsx` mocks `next/navigation` per test.
  `focusRing` is `src/components/focusRing.ts`. Tailwind 4: use `motion-safe:` for the pulse, `print:hidden`,
  `bottom-[max(1rem,env(safe-area-inset-bottom))]`. Footer (`src/components/Footer.tsx`) is a centred column at
  390: name, then GitHub · LinkedIn · Email. Navbar is `z-50`; keep the widget below it (`z-40`).
- Intro copy: `talkPage.intro` is a `string[]` rendered as `<p>` in `src/app/talk/page.tsx`; `talk.test.tsx` checks
  each sentence by text. The link to `/projects/agent-harness` needs a data shape change (plan decides). The
  deep-dive's `builtWith` (`projects.ts` ~line 873) is a plain string rendered by `ProjectDetail.tsx` line ~190;
  `case-study-voice-concierge.test.ts` line 76 expects `/Claude Code agents/` in it. **Every sentence with a digit in
  the voice-concierge entry must be verbatim in `docs/notes/evidence-voice-concierge.md` § Sentences with digits**
  (test at line 113): the protection sentence (5 sessions, 10 minutes, $45, 2 rooms) goes in the brief first.
- Token route: `src/app/api/concierge/token/route.ts` (env → 400 → sign). `src/lib/concierge/env.ts` is the
  shared env check (D46). Tests: `concierge-token-route.test.ts` (node env, **mocks nothing**, D42) and
  `concierge-token-route-sdk.test.ts` (spies on the real SDK). Both build `Request`s with no Origin header: every
  case must gain `Origin: https://michael-herron.vercel.app` once the allowlist lands.
- LiveKit SDK: `RoomServiceClient(host, apiKey, secret).listRooms(names?)` (`livekit-server-sdk` 2.19.1); its Twirp
  client rewrites `wss://` → `https://` itself, so `env.url` is the host. It uses global `fetch` (Node 24 here,
  Vercel fine). Mocking: next/jest's SWC output defines exports as getters, so `jest.spyOn(module, 'fn')` can fail;
  use `jest.mock('@/lib/concierge/rooms')` in a new test file instead.
- `server-only`: not installed yet (`npm i -E server-only@0.0.1`). next/jest already maps `^server-only$` to an
  empty mock (`node_modules/next/dist/build/jest/jest.js` line 173), so Jest needs no config change; `next build`
  needs the package. `/talk`'s page imports `env.ts` and is a Server Component, which is fine.
- TalkSession: `setMic(session, true)` is called right after `room.connect()` (line ~`onPlayback(); unlockAudio;
  setMic`). `agentArrived` is the function to move it into. Mic toggle renders in `waiting` and `live`.
  `fetchCredentials` returns null on any non-OK: the 429 reasons need a richer return. Reducer: `sessionReducer.ts`,
  phases `idle|connecting|waiting|live|ended|offline`. Tests: `TalkSession.test.tsx` (fetch mock, `reply(status,
  body)` helper, fake timers flushed in one `act`), `TalkSession-live.test.tsx` (mic, `addAgent(room)`),
  `src/__mocks__/livekit-client.ts` (`MockRoom.setup`, `localParticipant.setMicrophoneEnabled` is a jest.fn).
- Vercel preview host, read from PR #16's Vercel comment:
  `portfolio-site-git-harness-merg-e67481-mh550s-projects-e64e7e0b.vercel.app`. Production origin is
  `profile.siteUrl` = `https://michael-herron.vercel.app`.
- The agent repo checkout `~/projects/voice-concierge` holds only docs today (no `concierge/*.py`), so "the agent
  doesn't parse room names" cannot be checked locally; the plan records it for Michael (public repo
  `github.com/mh550/voice-concierge`; a read-only shallow clone into a temp dir is allowed if a session wants to).
- Screenshots: Playwright lives in `$HARNESS_PW/node_modules/playwright` (see `.harness/smoke.mjs` line 9); captures
  go to `docs/screenshots/v2/VC4-*.png` / `VC5-*.png`, under 400 KB. Print check: `node .harness/print-check.mjs`.
- Counts in CLAUDE.md (992 tests, 75 suites) must be updated by the review features.

**Gotchas.**
- Never create `.env*`, never set `LIVEKIT_*` in the dev server; every check sees the offline state. The /talk 429
  check therefore intercepts the route with Playwright's `page.route`.
- Origin before env (D63 default) means `curl -X POST` without Origin gets 403 even on the harness server, which
  makes the shell check verifiable here.
- Content guard (`content-guard.test.ts`) fails on TODO/placeholder words and US phone numbers: write the busy
  copy exactly as the spec gives it.
- `project-page-unchanged.test.tsx` snapshots the classic pages: don't touch their data.

**Defaults taken (Michael can overrule in INBOX `## Answers`; each is one-line reversible).**
1. Decisions for VC4/VC5 go in a new `## 7. Decisions` of the voice-concierge spec, numbered from D59.
2. Origin is checked before the env check (403 before 503), so nothing about the env leaks to a foreign caller.
3. No `x-forwarded-for` → bucket `unknown` (all local tabs share one room slot; matches "another tab" locally).
4. Preview regex `^portfolio-site-[a-z0-9-]+-mh550s-projects(-[a-z0-9]+)?\.vercel\.app$`, https only.
5. The mic toggle shows only once the agent is live (it was visible while waiting).
6. The widget is excluded on `/talk` and `/card*` only; `/evidence` keeps it.
7. The "how it's protected" sentence is appended to the deep-dive's Build method line (not a new section).

**Questions for Michael (none block a feature).**
- Does the agent read the room name anywhere (`concierge/*.py`)? The route now names rooms
  `concierge-<addr10>-<random>`. Default assumes no.
- Is `CONCIERGE_MAX_ROOMS` = 2 right for the conference week, and should it be set in Vercel at all (unset = 2)?
- Should `/evidence` (noindex) also lose the widget? Default: it keeps it.
