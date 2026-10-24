# Progress log — run portfolio_site-2026-10-21-v3 (branch `harness/portfolio_site-2026-10-21-v3`)

What this file is: the shared memory of this harness run. Every session reads it at startup and adds a short
entry **at the top** (newest first): feature id, what landed, what the next session must know. The feature list is
`feature_list.json` in this directory: array order is priority, `after` lists are the real dependencies (inside a
milestone every feature names the one before it, so a stuck milestone never blocks an independent one), and a
session may flip only its own feature's `passes`. Michael steers through `INBOX.md` on this branch (first line
`status: run|pause|stop`; answers under `## Answers`), but he is asleep for this run: **never park**, take the
spec's default, record it as the next `D<n> *default*` and go on. Plans go in `docs/plans/2026-10-21-<milestone>-<topic>.md`.
New defaults go in a new section at the end of `docs/specs/2026-10-18-portfolio-v2.md`, `## v3 decisions
(2026-10-21, from D75)`, numbered consecutively from **D75** (D1–D49 are the v2 spec, D41–D58 the booth spec,
D59–D74 the voice-concierge page spec § 7; they already collide, so never renumber), each naming what it supersedes.

---

### 2026-10-21 · verify P6

| Feature | Step | What you ran or read | What you saw | Holds |
|---|---|---|---|---|
| P6-01 | 1 | grep for script/link/img/@import in the HTML; Chromium via /tmp/render.mjs at 1280 and 390 | 0 matches; 0 console/page/request errors; scrollWidth 1280/1280 and 390/390; footer records the check command | yes |
| P6-01 | 2 | read h2/h3 of options A, B, C; counted refs, token hexes | each option has Hiring manager 10 s, Cost to build, What others have done (3, 4, 5 refs), Risks; mockups use the four tokens and real titles (Agent Harness, Voice Concierge) | yes |
| P6-01 | 3 | curl -sIL on all 46 unique URLs across the three files; read trailing comment and Sources | all 200; comment lists codes; Sources section present | yes |
| P6-01 | 4 | read h2 'Recommendation: B' and h3 'What option A would share with the P5 graph' | both present | yes |
| P6-01 | 5 | `.harness/check.sh` | 1859 passed; `check: lint ok · jest ok · build ok` | yes |
| P6-02 | 1 | grep script/link/@import; Chromium at 1280 and 390; progress.md grep | 0 external refs, 0 errors, no horizontal scroll at 390; progress.md mentions frontend-design | yes |
| P6-02 | 2 | read h3s per direction d1–d3; python recomputed WCAG ratios of the 16 contrast rows per direction | palette 8/8/7 hexes; type, motion (scanlines/reduced motion), concierge+memory colours, VU meter present; 0 stated ratios off by >0.1 | yes |
| P6-02 | 3 | read h2s; grep token-only | Best practices, comparison table, Recommendation: 1 with 'token-only pass first' all present | yes |
| P6-02 | 4 | read trailing comment (18 URLs, all 200); grep img/.png/.jpg | URL codes listed and all 200 on my curl; 0 images | yes |
| P6-02 | 5 | `.harness/check.sh` | same run: green | yes |
| P6-03 | 1 | read table (6 rows) and URL code block; curl all URLs | 6 projects with URL, licence, stack, last activity; all 200 | yes |
| P6-03 | 2 | read '### 1.'–'### 6.' porting sections | concrete steps plus hour ranges (6–10 up to 80–120) with assumptions paragraph | yes |
| P6-03 | 3 | read Recommendation and line 66; ran jest | borrow from WebTUI paired with direction 1; quotes 1859 tests, matching my run | yes |
| P6-03 | 4 | `npx jest src/__tests__/lib/content-guard.test.ts`; grep private/.env | 20 passed; no private links | yes |
| P6-03 | 5 | `.harness/check.sh` | green | yes |
| P6-04 | 1 | read ## Review section; re-curled 46 URLs | script and result recorded; all 200 | yes |
| P6-04 | 2 | read review table (line ~263) and grep of script/link/img | sentences with digits sourced; 0 external script/link/img | yes |
| P6-04 | 3 | ran my own Chromium script | 0 errors, scrollWidth <= innerWidth at 390 for both files | yes |
| P6-04 | 4 | grep '## P6' docs/review-guide.md; read Review section | '## P6 (v3): recommendations' at line 397; findings section says none to fix | yes |
| P6-04 | 5 | `.harness/check.sh` | green | yes |

### 2026-10-21 · P6-04 · passes
- Reviewed the three P6 files; added `## Review (P6-04)` to `docs/notes/2026-10-21-framework-options.md` and `## P6 (v3): recommendations` to `docs/review-guide.md`. No code changed; tests 1859 → 1859.
- URLs: 46 unique, all 200 by `curl -sIL`. HTML files: no external script/link/img/@import.
- Chromium at 1280 and 390: 0 console errors, scrollWidth == innerWidth on both files.
- Numbers traced to projects.ts, skills.ts, evidence notes and `wc`/`find` counts (10/8/4, 17/14/3, 51/9, 734/592/1969, 100/55); all matched; mockup counts carry the "illustrative" tag. No findings to fix.
- `.harness/check.sh`: lint ok · jest ok · build ok.

### 2026-10-21 11:20 · P6-03 · passes

- New `docs/notes/2026-10-21-framework-options.md` (docs only; tests 1859 → 1859). Six foundations with licence, stack, last push and what each gives: daedalOS (MIT, Next 16 Pages Router + styled-components), `@react95/core` (MIT with a Microsoft-imagery carve-out, so GitHub says NOASSERTION), 98.css, NES.css (last push 2024-01-17), M4TT72 Terminal (Svelte 4), WebTUI (pre-1.0 CSS); plus five left out (ryOS is AGPL-3.0) and why no CRT kit. Each has porting steps and an hour range with its assumption (fork daedalOS 60–90 h, fork M4TT72 80–120 h; borrows 6–30 h).
- Recommendation: **borrow**, from WebTUI (box rule and grid copied into `@layer components`, never the whole package: it restyles body and bare buttons), paired with P6-02 direction 1, after its token-only pass; NES.css for one page if Michael picks direction 2.
- Verified: licences/dates via `gh api` and `LICENSE`/`package.json`, versions via `npm view`; all 16 URLs 200 (listed under the table); site counts from `wc`/`grep`/`find` (sources section); `npx jest --silent | tail -5` → 100 suites, 1859 tests; content-guard test 20/20 and the note greps clean of its patterns.
- Opus review: 3 Important (test-file count 101/56 → 100/55; LiveKit only via RoomAudio; WebTUI import restyles globally and its `utils` layer would beat Tailwind utilities) + 8 Minor, all fixed.
- `.harness/check.sh` → `check: lint ok · jest ok · build ok`; `lib/check.sh` green; smoke exit 0 at session start.
- Question for Michael: borrow as recommended, or do you want a daedalOS fork spiked on a branch first?

### 2026-10-21 10:50 · P6-02 · passes

- New `docs/design/2026-10-21-design-directions.html` (docs only; tests 1859 → 1859). Three directions, each with the home hero and the Recent work cards drawn at 1280 and 390 in real copy, a 7–8 token palette with a computed contrast table (memory colours checked on each surface), free fonts with licence sources (IBM Plex; Press Start 2P + Atkinson Hyperlegible; Barlow/Barlow Condensed + Space Mono + DSEG7, all OFL), motion rules, and the concierge panel drawn per direction (tmux pane; CRT bezel; rack module with the Latency tab as VU meters). Then best practices, a comparison table, and **recommendation 1, the terminal**, with a token-only first pass (colours, Plex via next/font, radii incl. bare `--radius`, the hard-coded cyan in NodeGraph/FloatingLogos/OG image/themeColor and their pins).
- Built by `$HARNESS_SCRATCH/p602/build.py` from `template.html` (bitmap and seven-segment SVG, swatches, contrast tables; it fails on any pair under 4.5/3 and curls every URL: 18 × 200 in the trailing comment). The frontend-design skill was used.
- Verified: `p602/p6-02-check.mjs` at 1280 and 390, normal and reduced motion: 0 console errors, 0 external requests, scrollWidth 390/390; `rm-check.mjs`: scanlines 5 shown → 0 under reduce, cursor animation none; `grep -c '<script\|<link \|<img\|url(\|@font-face'` → 0; every screen looked at as a PNG.
- Opus review: 7 Important + 11 Minor, all fixed (vignette removed so the reduced-motion claim and the 5 % texture rule hold; red/blue ratios restated; ProjectCard order change said plainly; token pass gained `--radius`, hard-coded colours, Plex weights; phone text ≥ 15 px; four of the latency rows drawn and why; usher notice now a real target; knobs flagged as a departure from § 11).
- `.harness/check.sh` → `check: lint ok · jest ok · build ok`; `lib/check.sh` green; smoke exit 0 at session start.
- Question for Michael: terminal (1) as recommended, or do you want the cartridge (2) or the desk (3)? If 1, the next step is the token-only PR described at the end of the file (a new D for the fonts).

### 2026-10-21 10:15 · P6-01 · passes

- New `docs/design/2026-10-21-projects-showcase-options.html` (docs only; tests 1859 → 1859). Three options for `/projects`, each drawn at 1280 × 800 and 390 × 844 in the site tokens with real titles, metrics and iteration texts: (A) one graph for projects and stack, Agent Harness selected with its 9 `skills.ts` edges and a side panel / bottom sheet; (B) case-file grid, company tab, a cover standing in for each project's `architectureDiagram`, `metrics[0]` band, today's category chips; (C) a dated log of the 17 `caseStudy.iterations`. Each has a 10-second read, cost (fields reused, new components), 3–5 references and risks; then a comparison table, **recommendation B** (fastest read for hiring managers, cheapest, covers from 9 existing diagrams), and what A shares with the P5 graph (data, `lib/graph`, selection model, List view; D99's d3-force caveat).
- Verified: frontend-design skill used. `grep -c '<script src\|<link [^>]*href="http'` → 0, no images/fonts fetched; one-off Playwright run (`node $HARNESS_SCRATCH/p6-01-check.mjs <file>`, command in the file's footer): 1280 and 390 both 0 console errors, 0 external requests, scrollWidth 1280/1280 and 390/390. All 12 reference URLs answer 200 with `curl -sIL -o /dev/null -w '%{http_code}'` (codes in the trailing comment). Sources list at the end of the file.
- An Opus review checked every number and code claim against the repo: 0 untraced numbers, 2 Important + 3 Minor, all fixed (Tailscale → Edge functions as the 6th infra node; the GoHighLevel cover now uses its diagram's own nodes, not techStack; Mirrored Google Calendars and Cherished have no metrics either; D99 d3-force caveat added to A; band wording uses `metrics[0]`, "14 of 17 in October").
- `.harness/check.sh` → `check: lint ok · jest ok · build ok`; `lib/check.sh` green; smoke exit 0 at session start.
- Question for Michael: does B (case files) match what you want for `/projects`, or do you prefer A on `/skills` later? Next step if B: render three diagrams at card width and look at 390.

### 2026-10-21 verify P5

| Feature | Step | What you ran or read | What you saw | Holds |
|---|---|---|---|---|
| P5-01 | 1 | read plan headings (grep '^## ') | Data, Layout, Math, Render, Interaction, Accessibility and list view, Tests, What Michael will see, Review, Decisions all present | yes |
| P5-01 | 2 | read plan § Data, Zapier/Pipedream/ICONS lines; skills-data.test.ts | six clusters, nodes table, Zapier kept weight 1, Pipedream no logo; test 'holds all 33 § 8 names', 'drops Ruby, R, ...', 'every featured project ≥2 edges' pass; ICONS has all 9 keys | yes |
| P5-01 | 3 | read plan § Math; grep d3-force | layoutGraph, viewBoxFor, clampView, zoomAt, panBy, fitCluster, curvePath named; D99 no d3-force with reconsider conditions | yes |
| P5-01 | 4 | read plan § Interaction/Accessibility | wheel rule, ±, Reset, arrows, drag, chip row, project chips, hover, Esc, reduced motion, #skill-<id> links, list as print view all present | yes |
| P5-01 | 5 | read plan § Tests and Decisions | test files listed with assertions; D98–D104 allocated (restructure, no d3-force, wheel, node link) in v2 spec | yes |
| P5-01 | 6 | check.sh + eslint + jest | all suite: eslint clean, jest 100 suites/1859 tests pass, check.sh green (cached), smoke PASS | yes |
| P5-02 | 1 | skills-data.test.ts (verbose); grep skillCategories src | exports clusters/nodes/edges; edge endpoints, logo keys, cluster, unique ids, weights, 33 § 8 names tests pass; skillCategories only in a comment | yes |
| P5-02 | 2 | grep ICONS scripts/logos.mjs; `node scripts/logos.mjs`; git status; paths.test.ts | all 9 keys present (plus cplusplus etc.); regenerated 25 logos, git status clean; paths.test 'exactly the 25 keys' passes | yes |
| P5-02 | 3 | graph-math.test.ts (verbose) | deterministic, no overlap at 1280/390, clampView bounds, zoomAt keeps point fixed, fitCluster 4 4 348 308 = cluster ±12, curvePath M…C regex all pass | yes |
| P5-02 | 4 | npx jest --silent; skills page | no failing suite; /skills renders (smoke PASS) | yes |
| P5-02 | 5 | check.sh | all suite: eslint clean, jest 100 suites/1859 tests pass, check.sh green (cached), smoke PASS | yes |
| P5-03 | 1 | read SkillGraph.tsx, SkillGraph.test.tsx | svg has role=none with a hidden-span name, not role=img+<title> (deliberate P5-07 review #5/D103 change, recorded); nodes are <a href=#skill-id> with aria-label, logo/dot, label; intra-edge path count test passes; cross edges only on hover/selection. Intent holds, literal wording superseded | yes |
| P5-03 | 2 | skills.test.tsx; SkillGraph.tsx l.641,483 | List view aria-pressed toggle; every node name in list under cluster h2; list 'hidden print:block', graph print:hidden (tests pass); print-check PASS shows list | yes |
| P5-03 | 3 | read app/skills/page.tsx; a11y-new-pages.test.tsx | h1 Tech Stack, graph-angle description, Differentiator only in a comment; a11y test passes | yes |
| P5-03 | 4 | SkillGraph.test 'never tweens the view' with mockReduced true/false | no transition class/style on svg either way; passes | yes |
| P5-03 | 5 | check.sh + smoke | all suite: eslint clean, jest 100 suites/1859 tests pass, check.sh green (cached), smoke PASS | yes |
| P5-04 | 1 | SkillGraph.tsx l.425-441; tests 'Zoom in/out…', wheel tests | Zoom in/out/Reset view buttons change viewBox; plain wheel unchanged and not prevented; ctrl/focus zooms; pass | yes |
| P5-04 | 2 | tests 'focusable and described', 'arrow keys pan', 'pointer drag'; skills-check ArrowRight | tabIndex 0 role=group, described by help line; arrows and drag pan; viewBox 0 0 1052 700 → 24 0 1052 700 | yes |
| P5-04 | 3 | tests 'starts on the first cluster', 'row of cluster chips'; skills-check 390 | narrow view 4 4 348 308, chip row 'flex sm:hidden' (breakpoint is 640 per D102, covers 390); chip click pans, aria-pressed moves | yes |
| P5-04 | 4 | grep -rl 'lib/graph' src/components; jest components/skills | only SkillGraph.tsx; green | yes |
| P5-04 | 5 | check.sh + smoke | all suite: eslint clean, jest 100 suites/1859 tests pass, check.sh green (cached), smoke PASS | yes |
| P5-05 | 1 | project chip tests; skills-check chip | chips aria-pressed in order, data-active/dim, chain paths, Open case study, second click and Esc clear; pass | yes |
| P5-05 | 2 | tests 'hovering or focusing…', 'hover with a project selected keeps' | data-hover cross edges add/remove; selection kept; pass | yes |
| P5-05 | 3 | skills.test 'selecting Agent Harness…'; grep motion-safe; skills-check | N=9 ≥3 active, link /projects/agent-harness; fade is 'motion-safe:transition-opacity' | yes |
| P5-05 | 4 | CLAUDE.md /skills row and skills.ts line; plan § Interaction | both describe the graph and chips; plan interaction notes present | yes |
| P5-05 | 5 | check.sh + smoke | all suite: eslint clean, jest 100 suites/1859 tests pass, check.sh green (cached), smoke PASS | yes |
| P5-06 | 1 | ls/wc docs/screenshots/v3/P5-* | four PNGs exist: 187 KB, 69 KB, 341 KB, 191 KB, all <400 KB; reran skills-check.mjs, regenerated in scratch | yes |
| P5-06 | 2 | node .harness/skills-check.mjs; plan § What Michael will see | exit 0 'skills-check: ok'; no h-scroll 390; Tab reaches controls then 'Harness engineering'; ArrowRight changes viewBox; N=9; labels inside cluster rects; recorded in plan | yes |
| P5-06 | 3 | print-check.mjs … /skills; read capture | PASS exit 0, 280 KB; image shows definition list, no svg | yes |
| P5-06 | 4 | node .harness/smoke.mjs | every route PASS | yes |
| P5-06 | 5 | check.sh | all suite: eslint clean, jest 100 suites/1859 tests pass, check.sh green (cached), smoke PASS | yes |
| P5-07 | 1 | git log grep 'after P5-01' (dc29efb); plan § Review | diff base resolvable; 12 review rows with severity, file:line, resolution | yes |
| P5-07 | 2 | read § Review resolutions; tests 'P5-07 #1/#2'; eslint | 2 Important fixed test-first (named tests pass), Minors fixed or reasoned, simplification pass recorded; eslint clean | yes |
| P5-07 | 3 | grep docs/review-guide.md, CLAUDE.md, v2 spec | '## P5 (v3)' at l.367; CLAUDE.md matches code (hidden span, print:hidden toolbar, D104); D98–D104 in spec | yes |
| P5-07 | 4 | check.sh + smoke | all suite: eslint clean, jest 100 suites/1859 tests pass, check.sh green (cached), smoke PASS | yes |

### 2026-10-21 · P5-07 · passes

- An Opus review of `$HARNESS_SCRATCH/P5.diff` (3850 lines): 0 Critical, 2 Important, 8 Minor, plus the P5-05/06 notes; one row each in the plan § Review. Fixed test-first: a press released outside the graph before the slop no longer pans on hover or swallows the next click (`buttons === 0` drops it); List view rows without a project edge drop the untrue "From my roles" (D104); the toolbar row is `print:hidden`; controls' transitions are `motion-safe:`; the group's name is a `hidden` span, not a root svg `<title>` (no whole-drawing tooltip); help line adds "0 resets". Simplification: `GraphData.edges` dropped, 10 module-internal constants un-exported, `skills.ts`'s test-only edge-helper re-export gone (no graph function was unused). Tests 1856 → 1859.
- Verified: `.harness/check.sh` → `check: lint ok · jest ok · build ok`, `lib/check.sh` green, `npx eslint .` clean, smoke exit 0 (41 PASS). A Sonnet run in Chromium on :7835: `skills-check: ok` (N = 9, 390 first view `4 4 348 308`, 0 console errors), print-check PASS with no button visible under print media; the review's plausible Tab-scroll finding is not a defect (390: Tab Copilot Studio → TypeScript, scrollY 390 → 390, view re-centred, node inside the container). Captures refreshed in `docs/screenshots/v3/P5-skills-*.png` (all < 400 KB).
- Docs: `docs/review-guide.md` gains `## P5 (v3)`; CLAUDE.md (SkillGraph line, test count) and D104 in the v2 spec.
- Left with reasons (plan § Review): the pre-hydration wide drawing at 390, the double focus ring, a node's name and tooltip being the same text, no skip link (List view is the shortcut), the pill over one label at scroll 0.
- Questions for Michael: (D104) should a project-less row name its source ("Coursework", "This site", "Home server")? D98's two (MongoDB off? the 15 core nodes) still stand.

### 2026-10-21 · P5-06 · passes

- New `.harness/skills-check.mjs` (Chromium, 1280×800 and 390×844; prints how much of the graph the first-visit callout and pill cover, then closes the callout) → `docs/screenshots/v3/P5-skills-{1280,selected-1280,390,list-390}.png` (182/186/67/357 KB). Plan § What Michael will see filled; CLAUDE.md § How to verify gains the Skills line. No src change: tests 1856 → 1856.
- Verified: `skills-check: ok`, exit 0, 0 console errors: 51 labels inside their cluster rects, none overlapping; Tab from the h1 → 8 project chips → Zoom in/out/Reset view/List view → graph → "Harness engineering"; ArrowRight `0 0 1052 700` → `24 0 1052 700`; Agent Harness N = 9 active, 42 dimmed, 3 cross paths, Open case study → /projects/agent-harness; 390 first view `4 4 348 308` (Agentic systems pressed), scrollWidth 390, List view 51 rows. `print-check.mjs … /skills` PASS, capture shows the list only. `lib/check.sh` green, `.harness/check.sh` → `check: lint ok · jest ok · build ok`; smoke exit 0 (41 PASS).
- For P5-07: the List view toggle still prints (its row isn't `print:hidden`); at scroll 0 the fixed pill covers a label (Tailwind CSS at 1280, Copilot Studio at 390) and the first-visit callout covers 184×66 / 256×66 px of the graph until closed.

### 2026-10-21 · P5-05 · passes

- `/skills` project chips: `SkillGraph.tsx` gains a "Highlight a project's stack" row above the toolbar (featured projects with an edge, in `order`, short titles, `aria-pressed`; scrolls below `sm`, wraps from it; leaves with the zoom controls in list view). A selection marks `nodesOf` nodes `data-active`, every other node and edge `data-dim` (`opacity-25`, full again on hover/focus, `motion-safe:transition-opacity`), draws the `projectChain`'s cross pairs `data-cross data-active`, shows "<title> · N skills · Open case study" and an `aria-live` line; a second click or Esc (on the section, not from the list view) clears it ("Highlight cleared."); below 640 a project with no whole cell in view fits its first cluster. Page intro + metadata now say "pick a project". CLAUDE.md /skills row, skills.ts and SkillGraph lines; plan § Interaction "Built". Tests 1837 → 1856.
- Verified: `lib/check.sh` → check green; smoke exit 0 (41 PASS). In Chromium on :7835 (script `$HARNESS_SCRATCH/p505/check.mjs`), run again after the review fixes: 0 console errors. Agent Harness gives 9 active nodes, 42 dimmed and 3 cross paths. Opacity is 0.25 dimmed and 1 when hovered or keyboard-focused. Esc clears everything. At 390: scrollWidth 390, chips 44 px, row 1792/358 scrolling. The music-library chip moves the viewBox `4 4 348 308` → `352 4 348 308`. Reduced motion: transition 0s.
- An Opus review: 0 Critical/Important, 10 Minor; fixed test-first: list-view Esc, clear announced, whole-cell in-view, singular, `partOf` simplification. Left with reasons in the plan: Safari Esc after a mouse click, "Open case study" on classic pages, hover paths not dimmed.
- Next (P5-06): `.harness/skills-check.mjs` can start from the scratch script above. For P5-07: at 390 the longest chip nearly fills its scrolling row and two chip rows stack above the graph; the chips' `transition-colors` (shared `control`) isn't `motion-safe:`.
- Note: a stash entry `p505-check` (my own, applied back; dropping it was denied) is on the shared stash stack; safe to drop.

### 2026-10-21 · P5-04 · passes

- `/skills` pans and zooms: `SkillGraph.tsx` holds the view as state (reset on a viewport change with the previous-value pattern), the toolbar is the below-640 "Jump to a group" cluster row (`flex sm:hidden`, `aria-pressed` = `clusterAt(view centre)`), + / − / Reset (aria-labels Zoom in / Zoom out / Reset view, 44 px) and List view; the container is `tabIndex 0`, `aria-describedby="skill-graph-help"` ("Arrow keys pan, plus and minus zoom. Drag to move."); arrows `panBy`, `+ = - 0` zoom/reset (not with Ctrl/⌘/Alt or IME); pointer drag with capture and a swallowed post-drag click; one non-passive `wheel` listener (zooms only with focus inside or Ctrl/⌘, and never prevents a wheel that zooms nothing); focus on an out-of-view node centres it. Below 640 the first view is `fitCluster('agentic')` = `4 4 348 308`. Tests 1807 → 1837 (SkillGraph.test.tsx, PointerEvent shimmed as a MouseEvent there).
- Verified: `lib/check.sh` → check green; smoke exit 0 (41 PASS); `grep -rl 'lib/graph' src/components` → only SkillGraph.tsx. A Sonnet run in Chromium on :7835: no console/hydration errors; 1280 Zoom in → `105.2 70 841.6 560`, Reset → `0 0 1052 700`; a plain wheel with focus on body scrolled the page (scrollY 0 → 300) with the viewBox unchanged, and with the graph focused it zoomed without scrolling; a 100 px drag moved x by 60.99 units (expected 60.99); a drag ending on a node didn't open the list, a click did; Tab order: nav → Zoom in, Zoom out, Reset view, List view, graph, nodes. 390: `4 4 348 308`, scrollWidth 390, the Data chip → `294.13 312 433.87 384` and pressed. 800: chip row hidden, `0 0 704 1008`.
- An Opus review: 2 Important (a drag starting on a node mixed `centerOn` with a stale start view; a focused graph swallowed every wheel, including sideways swipes and at a zoom limit) and 5 Minor + 4 test gaps, all fixed test-first except the narrow hydration jump (server renders the wide aspect, ~77 px at 390; left for P5-07). Notes in the plan § Render "Built in P5-04".
- Next (P5-05): project chips go above the toolbar; Esc clears the selection; below 640 a selection with no node in view should `fitCluster` its chain's first cluster. `reveal` skips while a pointer is down (`drag.current`), and `viewRef` is the view for handlers.
- Proposed change: P5-04 step 3 "≤ 390 / above 390" and "`hidden sm:…`" → "below 640 / from 640" and "`flex sm:hidden`" (D102, as P5-01 proposed).

### 2026-10-21 · P5-03 · passes

- `/skills` draws the graph: new `src/components/skills/SkillGraph.tsx` (`"use client"`; `useSyncExternalStore` over two `matchMedia` queries, server snapshot 'wide' → 3 or 2 columns; svg `role="none"` in the one `role="group"` named by its `<title>` (D103); cluster containers `g[data-cluster-box]`, then intra edges, then per-cluster `role="group"` node links `#skill-<id>` with logo or dot, label tspans, own `<title>`; a node's cross edges on hover/focus only) and a List view toggle (`#skill-list`: `h2` + `dl` per cluster, Core/Regular/Occasional · since · Used in links or "From my roles"; `hidden print:block`, graph `print:hidden`). A node click, a load with `#skill-<id>` or a hashchange opens the list and focuses the row. `page.tsx`: `max-w-6xl`, short project titles built on the server, new intro/metadata; `Logo` gains `x`/`y`/`size`; edge helpers moved to `src/lib/graph/edges.ts` (re-exported). a11y-new-pages covers /skills. Tests 1777 → 1807.
- Verified: `lib/check.sh` → check green (lint · jest · build); smoke exit 0 (41 PASS, /skills at 1280 and 390); a Sonnet browser run: no console errors or hydration warnings, viewBox 0 0 1052 700 / 0 0 704 1008, no horizontal scroll at 390, 51 labels inside their cluster rects with no overlaps, Tab from List view reaches "Harness engineering" with a cyan ring, hover draws 3 cross paths for harness-engineering, click python → list open, `#skill-python` focused, print shows the list only.
- An Opus review: 1 Important (stale focus target after a hashchange with the list open) and 12 Minor. All fixed test-first except #13 (next/link pushState fires no hashchange, for P5-05). Notes in the plan § Render "Built in P5-03".
- Next (P5-04): the first view is still `fitAll` at every width (at 390 the 2-column drawing is about 0.5 px a unit, labels about 6 px); P5-04 adds the narrow `fitCluster('agentic')` start, view state, `tabIndex`, the help line + `aria-describedby`, pan and zoom. The intro/metadata add "pick a project" when P5-05 builds the chips.
- Proposed change (repeat of P5-01's): P5-03 step 1's `<svg role="img">` should read svg `role="none"` inside the `role="group"` container (D103). For P5-07: Chrome shows the node's focus as a double ring (the shared `focusRing` outline outside the cell rect's stroke). Keep both, or drop one.

### 2026-10-21 · P5-02 · passes

- `src/lib/data/skills.ts` is the graph (6 `clusters`, 51 `nodes`, 43 node edges + 58 `project:<slug>` edges from a per-project table; helpers `projectSlug`, `projectsOf`, `nodesOf`); `skillCategories` is gone (data.test's D20 block removed). `src/lib/graph/layout.ts` (`layoutGraph`, `labelLines`, `curvePath`, `edgePaths`, `projectChain`, `clusterAt`, `columnsFor`, `LABEL_DY`, `NARROW_ASPECT`) and `view.ts` (`clampView`, `zoomAt`, `panBy`, `fitCluster`, `fitAll`, `centerOn`, `clientToDrawing`, `contains`, `viewBoxFor`, `wheelFactor`), pure. `scripts/logos.mjs` + 13 keys → `paths.ts` 25 (Java/C++/MCP titles); FloatingLogos test now compares its own twelve. `/skills` lists the new clusters until P5-03 draws the graph (no Differentiator). Tests 1646 → 1777 (new `skills-data.test.ts`, `graph-math.test.ts`).
- Verified: `.harness/check.sh` → `check: lint ok · jest ok · build ok`; smoke exit 0 (/skills PASS at 1280 and 390); `node scripts/logos.mjs` twice → identical file; fitCluster('agentic') at 390 = `4 4 348 308`, bounds 1052×700 / 704×1008 as the plan says.
- An Opus review checked the data against the plan's tables (exact match). It found 1 Important: `zoomAt` drifted at the zoom limits. Fixed test-first: the factor is capped before the fixed point is computed. It also found Minors: non-finite aspect/factor guards; data tests now hold the plan's project table and core-node list; SQL added to the plan's no-project list; curvePath's normal direction documented; the API P5-03..05 need added (`name`/`weight` on NodePoint, `LABEL_DY`, `NARROW_ASPECT`, `columnsFor`, edge helpers). § Math records them. `GraphData.edges` is still unused by `layoutGraph` (the plan's type; kept).
- Next (P5-03): render from `layoutGraph(…, columns from the matchMedia snapshot via columnsFor)`; the svg aspect below 640 is `NARROW_ASPECT`; the list view's "Used in" is `projectsOf`, a chip's nodes `nodesOf`; `clusterAt` is null in gaps (no chip pressed).
- Questions for Michael: D98's two questions still stand (MongoDB off? the 15 weight-3 core nodes, now pinned in `skills-data.test.ts`).

### 2026-10-21 · P5-01 · passes

- Plan `docs/plans/2026-10-21-P5-skills-graph.md`: Data (6 clusters, 51 nodes each with cluster/weight/logo/since/source, 43 node↔node edges, project edges ≥ 3 per featured project, 13 new simple-icons keys incl. javascript, expo, modelcontextprotocol beyond the step's list; Pipedream has none), Layout (ASCII 1280 = 3 columns, 1052 × 700 units; 390 = 2 columns, 704 × 1008, first view `4 4 348 308` at 1.03 px a unit), Math (`src/lib/graph/layout.ts` + `view.ts` signatures), Render, Interaction table, Accessibility, Tests, empty What Michael will see / Review tables, Decisions. D98–D103 appended to the v2 spec. Docs only: tests 1646 → 1646.
- Verified: an Opus review of the plan recomputed every layout number (all correct) and found 4 Important / 9 Minor issues, all applied: `touch-action: pan-y pinch-zoom`; jsdom has no `matchMedia`/`setPointerCapture` and zero-size rects (guards specified); `pointercancel` and a post-drag click suppression; Linux project edges and LiveKit's `since` removed as unsourced; MCP gets a mark; clampView lets a tall phone view zoom out to the whole drawing. `.harness/check.sh` → `check: lint ok · jest ok · build ok`; smoke exit 0.
- Next (P5-02): build from § Data and § Math; `skillCategories` goes (readers: skills page, skills.test, data.test's D20 block).
- Questions for Michael: (D98) MongoDB is in Cherished's `techStack` but the step drops it: keep it off? Are the weight-3 "core" nodes right (Harness/Context engineering, Agent memory, Claude Code, TypeScript, Python, React, React Native, Next.js, PostgreSQL, Supabase, Multi-tenant, Docker Compose, Git/GitHub, Specs)?
- Proposed changes: P5-03 step 1 `<svg role="img">` → svg `role="none"` inside a `role="group"` container (D103: `img` hides the node links from screen readers); P5-04 step 3 "≤ 390 / above 390" and "`hidden sm:…`" → "below 640 / from 640" and "`flex sm:hidden`" (D102); P5-03 step 4 is trivially true now, since view changes are instant at every motion setting (D103).

### 2026-10-21 · verify P4

| Feature | Step | What you ran or read | What you saw | Holds |
|---|---|---|---|---|
| P4-01 | 1 | read docs/plans/2026-10-21-P4-contact.md headings | Layout (ASCII 1280 + height table), Glyphs, Tests, What Michael will see, Review, Decisions (D97, authored LinkedIn/mail in extra.ts); extra.ts comment says no siLinkedin | yes |
| P4-01 | 2 | read src/app/contact/page.tsx; `grep -c 'Whether you have\|Currently based\|always up for'` | h1 Let's Talk, one <p> `{location} · {availability}.`, `grid sm:grid-cols-3`, 3 `<a>` tiles each with one Logo svg; grep prints 0 | yes |
| P4-01 | 3 | read contact.test.tsx + profile.test.ts; ran `npx jest src/__tests__/pages` | asserts h1, one p text, 3 links/hrefs, names, target/rel, one svg per tile, removed texts absent; profile.test covers availability; 150 pass | yes |
| P4-01 | 4 | read a11y-new-pages.test.tsx; ran it; read metadata | /contact in pages list (one h1, focus-visible, no vague links); muted contrast case (4.5:1; I computed 5.71); description mentions agentic systems engineer | yes |
| P4-01 | 5 | `lib/check.sh`; `node .harness/smoke.mjs` | check green (cached, same tree); smoke all PASS incl. /contact at 1280 and 390, /approach redirect | yes |
| P4-02 | 1 | `node .harness/contact-check.mjs` (HARNESS_PORT=7835) | `scrollHeight <= innerHeight: true (800<=800)` at 1280, same at 390; panel closed; tile boxes vs pill printed, no intersection; exit ok | yes |
| P4-02 | 2 | `ls -l`/`file` the PNGs; read plan § What Michael will see | 1280×800 40 KB and 390×844 33 KB viewport PNGs; section describes tiles, glyphs, line, pill position | yes |
| P4-02 | 3 | smoke; `print-check.mjs http://localhost:7835 /contact …` | smoke all PASS; print-check PASS exit 0 (white bg, no nav/footer/canvas) | yes |
| P4-02 | 4 | `lib/check.sh` | check: green | yes |
| P4-03 | 1 | read plan § Review | 9 findings rows with severity, file:line, resolution; simplification pass recorded; diff range base exists ('HARNESS: after P4-01' commit) | yes |
| P4-03 | 2 | read Review resolutions; `npx eslint src`; tests | Important #1/#2 fixed with tests in contact.test.tsx (no aria-label, sr-only note, wbr); Minors resolved with reasons; eslint clean | yes |
| P4-03 | 3 | grep review-guide.md, CLAUDE.md, v2 spec | `## P4 (v3)` at review-guide:341; CLAUDE.md row 'one screen, three tiles'; D97 at spec line 669 | yes |
| P4-03 | 4 | `lib/check.sh`; smoke | check green; smoke every route PASS | yes |

Result: 3 hold, 0 fail.

---

### 2026-10-21 · P4-03 · passes

- Opus review of P4 (`$HARNESS_SCRATCH/P4.diff` per the step, plus `P4-full.diff` from P4-01's parent): 0 Critical, 2 Important, 7 Minor; all rows in `docs/plans/2026-10-21-P4-contact.md` § Review. Fixed test-first: tile names come from their text with an `sr-only` "(opens in new tab)" like the rest of the site (no `aria-label`; Chrome aria snapshot: "Email mherron734@gmail.com", "LinkedIn linkedin.com/in/mherron734 (opens in new tab)"); `<wbr>` after each `@` and `/` so the 640–767 px three-column tiles wrap "mherron734@ / gmail.com" instead of mid-word. `contact-check.mjs`: names from the label, try/finally (dead port → `contact-check: 1 FAIL`, exit 1), screenshot dir resolved from the repo root.
- Docs: `## P4 (v3)` in `docs/review-guide.md`; CLAUDE.md `/contact` row "one screen, three tiles"; D97 gains the brand-guidelines note. Captures re-taken (same geometry). Tests 1642 → 1646.
- Verified: `.harness/check.sh` → `check: lint ok · jest ok · build ok`; `node .harness/smoke.mjs` exit 0 (0 FAIL); `contact-check.mjs` ok (Footer 776/844, 710/800); print-check /contact PASS.
- Question for Michael (D97): LinkedIn's brand guidelines ask people not to recreate the "in" mark; keep the hand-drawn one or swap in their official asset (one path in `extra.ts`)?
- Proposed change: P4-03 step 1's base (`HARNESS: after P4-01`'s parent) is the WIP commit after P4-01's code, so its diff holds only P4-02; a build milestone's review should diff from the parent of its first `P<n>-01:` commit (`--grep='^P4-01:'`). P5-07 is fine as written (P5-01 is the plan, its code starts at P5-02).

### 2026-10-21 · P4-02 · passes

- New `.harness/contact-check.mjs`: loads /contact as a first visitor at 390×844 and 1280×800, prints `scrollHeight <= innerHeight: true` (844 ≤ 844, 800 ≤ 800), the Footer's bottom edge (776 → 68 px spare; 710 → 90 px spare, since scrollHeight never goes below the viewport), panel closed (0 dialogs, pill aria-expanded false), pill and tile boxes (pill 238,780–374,828 vs last tile bottom 491 at 390; 1128,736–1264,784 vs GitHub tile 813–1128 × 287–429 at 1280: no intersection), no callout (Footer in sight), no console errors; exit 0.
- Captures `docs/screenshots/v3/P4-contact-390.png` (32 KB) and `P4-contact-1280.png` (39 KB), viewport only; I looked at both. Described in `docs/plans/2026-10-21-P4-contact.md` § What Michael will see. CLAUDE.md § How to verify names the script.
- Verified: `node .harness/smoke.mjs` exit 0 (0 FAIL, /contact PASS at both widths); `print-check.mjs … /contact` → PASS print, exit 0; `.harness/check.sh` → `check: lint ok · jest ok · build ok`. Tests 1642 → 1642 (a check feature: no app code changed).
- Next (P4-03, review): diff is the script, the plan section, the two PNGs and one CLAUDE.md bullet.

### 2026-10-21 · P4-01 · passes

- /contact is one screen (D97): `src/app/contact/page.tsx` = h1, one line `profile.location · profile.availability`, a `grid sm:grid-cols-3` of three `<a>` tiles (glyph, label, value); eyebrow, subheader, closing note gone. New `profile.availability`; new `src/components/logos/extra.ts` (authored LinkedIn "in" and mail, `fill-rule: evenodd`; simple-icons 16.9.0 has no LinkedIn); `Logo` takes either key. Plan `docs/plans/2026-10-21-P4-contact.md` (height budget per element). Tests 1629 → 1642 (contact.test rewritten, Logo extra cases, profile `availability`, /contact in a11y-new-pages).
- Verified: `.harness/check.sh` → `check: lint ok · jest ok · build ok`; `node .harness/smoke.mjs` exit 0; a Sonnet browser pass on :7835: scrollHeight = innerHeight at 390×844 (844) and 1280×800 (800), also at 640×900 and 820×1180, no tile overflow, pill (238,780 at 390) clear of the tiles; I looked at the 390 capture and the LinkedIn glyph (holes cut).
- Next (P4-02): the numbers above came from a throwaway script in scratch; `.harness/contact-check.mjs` still has to be written. scrollHeight reports innerHeight when content is shorter; the real spare is the Footer bottom: 776 of 844 at 390, 710 of 800 at 1280.
- Question for Michael: the LinkedIn "in" is hand-drawn (D97), not LinkedIn's artwork. Keep it, or swap in their official asset from LinkedIn's brand page?

### 2026-10-21 · verify P3

All 10 P3 features hold (56 steps). `passes` unchanged.

| Feature | Step | What you ran or read | What you saw | Holds |
|---|---|---|---|---|
| P3-01 | 1 | read plan headings (`grep ^##`) | all 14 sections present (Ownership 12 … Decisions 630); What Michael will see and Review tables filled by later features | yes |
| P3-01 | 2 | plan § Contract v2 (line 115) | section exists; parser behaviour pinned by concierge-contract.test.ts v2 cases | yes |
| P3-01 | 3 | plan §§ Panel 164, Widget 248, Callout 283 | present; ConciergePanel.tsx has z-[45], lg:w-[420px], inset-x-0 matching | yes |
| P3-01 | 4 | plan §§ Memory view 311, Cache 390, Busy retry 420, Usher 457 | present; design-tokens.test.ts passes (contrast) | yes |
| P3-01 | 5 | plan §§ Copy 503, Tests 523, Decisions 630 | present; D85–D96 in v2 spec cited by plan | yes |
| P3-01 | 6 | `/home/mh550/projects/agent-harness/lib/check.sh` | `check: green (cached for this code tree, 6 tests)`; eslint no output | yes |
| P3-02 | 1 | concierge-contract.test.ts | passes: "reads the v2 fixture", "about_agent missing/\"a string\"/7/null/[] → null", "v: 2 but no about_visitor", "keeps an events type outside the seven named ones as its string" | yes |
| P3-02 | 2 | concierge-contract.test.ts + read lines 403-416 | names test passes; isAllowedHref cases include //evil, /about?x, /about#y; parseNavigate non-JSON → null; 1 KiB drop (usher test) | yes |
| P3-02 | 3 | concierge-memory-cache.test.ts | passes: "never throws out of save, load or clear", "round-trips a v2 body through parseMemory", other-id/corrupt cases | yes |
| P3-02 | 4 | CLAUDE.md lib/concierge line; plan | names contract v2, parseNavigate, isAllowedHref, memoryCache.ts | yes |
| P3-02 | 5 | check.sh | green | yes |
| P3-03 | 1 | `grep -c "new lk.Room"` on TalkSession.tsx / ConciergeProvider.tsx; ConciergeProvider.test.tsx | 0 / 1; "throws outside a ConciergeProvider" passes; TalkSession.tsx 29 lines | yes |
| P3-03 | 2 | `grep -rln concierge/env src/components`; SiteChrome tests | prints nothing; configured comes from layout.tsx prop | yes |
| P3-03 | 3 | ConciergeProvider.test.tsx | "a live call survives TalkSession unmounting and remounting", "pagehide disconnects the room", "two Connects in a row … make one Room" pass | yes |
| P3-03 | 4 | full jest run (talk/, talk.test, SiteChrome, a11y-new-pages) | all pass, 0 failing suites | yes |
| P3-03 | 5 | CLAUDE.md components; v2 spec D85 | ConciergeProvider and updated TalkSession/SiteChrome lines present | yes |
| P3-03 | 6 | check.sh + `node .harness/smoke.mjs` | green; every route PASS at 1280 and 390 | yes |
| P3-04 | 1 | ConciergePanel.tsx:45 + ConciergePanel.test.tsx | role dialog aria-modal false, z-[45], lg:w-[420px], inset-x-0 bottom sheet; header/log/message box order test passes | yes |
| P3-04 | 2 | ConciergePanel.test.tsx | "Minimize closes and hands focus back", "Esc inside…", "Minimize keeps the Room and the call" pass | yes |
| P3-04 | 3 | VoiceWidget/SiteChrome tests | "collapsed: aria-expanded false and no aria-controls"; "no inert, no focus trap, no scroll lock" pass | yes |
| P3-04 | 4 | SiteChrome/a11y-new-pages tests | panel open one dialog passes; not on /talk or /card* | yes |
| P3-04 | 5 | check.sh + smoke | green; no horizontal scroll at 390 | yes |
| P3-05 | 1 | VoiceWidget.test.tsx; ConciergeProvider agentSpeaking tests | "speaking: each bar moves, only under motion-safe", names "Ask my site: speaking/listening" pass | yes |
| P3-05 | 2 | VoiceWidget.test.tsx "collapse at 390 px" | collapse after scroll, above 390 never collapses, pass | yes |
| P3-05 | 3 | Callout.test.tsx | exact line + Close, stored key hides, throwing storage OK, Esc, motion-safe pass | yes |
| P3-05 | 4 | Navbar.test.tsx | "lists the six links in order in the desktop list and the mobile menu" passes; /talk still in smoke routes | yes |
| P3-05 | 5 | talkWidget in src/lib/data/concierge.ts:130-138; Footer test; CLAUDE.md | label/listening/speaking/callout in data; docs updated | yes |
| P3-05 | 6 | check.sh + smoke | green | yes |
| P3-06 | 1 | design-tokens.test.ts; globals.css | passes (each token ≥ 4.5:1); CLAUDE.md lists them | yes |
| P3-06 | 2 | MemoryStrip.test.tsx | "pulses once the chips whose count changed, and only those", "pulses only through motion-safe", v1 dashes pass | yes |
| P3-06 | 3 | PanelTabs.test.tsx | tablist Memory/Latency/Privacy, ArrowRight/Left/Home/End pass | yes |
| P3-06 | 4 | MemoryView.test.tsx | v1+v2 cases; Events at most 12, rejected colour, episodes "in progress" pass | yes |
| P3-06 | 5 | MemoryView/ForgetMe tests; concierge-data.test.ts; concierge.ts:32-92 | disabled button with hint pre-call; "Forget me" spelling test passes; hint exact | yes |
| P3-06 | 6 | ConciergePanel/TalkSession/a11y tests | strip+tabs in both via MemorySection; a11y outline passes | yes |
| P3-06 | 7 | check.sh + smoke | green | yes |
| P3-07 | 1 | ConciergeProvider.test.tsx | "loads the cached body…", "shows the cached body greyed with as of", MemoryView asOf stale tests pass; concierge-check memory-cached-390 OK | yes |
| P3-07 | 2 | sessionReducer.test.ts; TalkSession-live; ConciergeProvider retry tests | closing transitions, 5 s retry, 60 s even with clock set back, Leave cancels all pass | yes |
| P3-07 | 3 | greps; concierge.ts:15-18; case-study-voice-concierge.test.ts | no hit in src for "specs in, verified…" or "pack"; hits only in evidence brief before/after table; intro text matches; test passes | yes |
| P3-07 | 4 | ran dummy-env dev server + `node .harness/talk-busy-check.mjs`; read header | closing scenarios (header: 5 s POSTs, 60 s busy, Leave) ran; then `.harness/init.sh` restart; output artifacts I created removed | yes |
| P3-07 | 5 | check.sh + smoke | green | yes |
| P3-08 | 1 | usher.test.tsx | "registers the navigate handler before connect() and unregisters all four topics", "follows an allowed project href with one push and one notice naming the short title" pass | yes |
| P3-08 | 2 | usher.test.tsx | 8 s limit, /projects/unknown no push, /talk, Guide me off, "drops a body over 1 KiB" pass | yes |
| P3-08 | 3 | ConciergePanel.test.tsx; GuideMe tests | switch default on, click off, stored off unchecked, throwing storage on pass; no switch on /talk | yes |
| P3-08 | 4 | Transcript.test.tsx | "renders a notice line muted and unattributed" passes | yes |
| P3-08 | 5 | CLAUDE.md usher text; plan § Usher; D94 | present | yes |
| P3-08 | 6 | check.sh | green | yes |
| P3-09 | 1 | ran `node .harness/concierge-check.mjs /tmp/p3shots` on dummy-env server, then `.harness/init.sh` and smoke | 54 OK, exit 0; smoke all PASS after restart | yes |
| P3-09 | 2 | `ls -l docs/screenshots/v3/P3-*` | all 9 named PNGs exist, largest 312886 B < 400 KB | yes |
| P3-09 | 3 | report.txt from my run | no horizontal scroll, focus on title then pill, no console errors, callout absent on 2nd load: all OK | yes |
| P3-09 | 4 | plan § What Michael will see lines 550-578 | one row per capture; states live state not captured with named Jest tests | yes |
| P3-09 | 5 | check.sh | green | yes |
| P3-10 | 1 | plan § Review; git log | rows P3-05-1…P3-10-6 present with severity/file/resolution; P3-10 review commits exist | yes |
| P3-10 | 2 | git log | Important fix 81bb8d6 (test-first per message) and Minor b46fef4 each own commit | yes |
| P3-10 | 3 | `wc -l TalkSession.tsx`; `npx eslint` | 29 lines; eslint clean | yes |
| P3-10 | 4 | grep docs | review-guide.md:293 "## P3 (v3)"; VC2 "As of P3" at line 14; D85/D92 as-built | yes |
| P3-10 | 5 | check.sh + smoke | green | yes |

### 2026-10-21 08:10 · P3-10 · passes

- Opus review of `P3.diff` (from 'HARNESS: after P2-04', 11 129 lines): 0 Critical, 1 Important, 5 Minor. Important fixed test-first in its own commit `81bb8d6`: `new lk.Room({ disconnectOnPageLeave: false })` (LiveKit's own `beforeunload` listener ended a live call on a `mailto:` click; the mock now mimics it). Minor: retry deadline on `performance.now()` (`b46fef4`, test-first); 4 kept with reasons (plan § Review P3-10-2…6). A Sonnet docs-vs-code pass found one stale `panelTitle` in D87, fixed.
- Simplification: `TalkSession.tsx` 471 → 42 → 29 lines; new `concierge/MemorySection.tsx` shared by drawer and `/talk`; duplicated copy (`panelTitle`, `memoryView.tabs`, `memoryView.cachedShare`) and dead `memory.fact.channel/source/confidence` removed; Forget me looks in `buttons.ts`; every reducer action is dispatched (none dead). Tests 1627 → 1629 (97 suites).
- Docs: `docs/review-guide.md` § P3 (v3) (morning check on a preview: pill → drawer → name → Guide me follow → Forget me; look-at; undo), VC2 plan "As of P3" note, D85/D92 *As built (P3-10)*, CLAUDE.md.
- Verified: `.harness/check.sh` → `check: lint ok · jest ok · build ok`; smoke exit 0 (41 PASS); new tests failed first (`beforeunload` disconnected; phase stayed `closing` with the clock set back).
- Questions for Michael: no view shows a fact's `confidence` since MemoryPanel went (P3-06): fine? D84, D92 (now also the second-tab case), D93, D94, D96 still open.
- Proposed change (carried): `HeroSection` (`'use client'`) imports the `@/lib/data` barrel, so `/` ships projects.ts; import `@/lib/data/<file>`.

### 2026-10-21 07:30 · P3-09 · passes

- New `.harness/concierge-check.mjs` (fresh context per scenario, token POSTs fulfilled by `page.route`, next dev's badge hidden) and `.harness/fixtures/memory-v2.json` (the `memoryV2` fixture as JSON, pinned by new `src/__tests__/harness/concierge-check-fixture.test.ts`). Nine captures in `docs/screenshots/v3/` (28–313 KB): `P3-home-callout-{390,1280}`, `P3-projects-open-{1280,390}`, `P3-projects-minimized-1280`, `P3-memory-cached-390`, `P3-closing-1280`, `P3-talk-{1280,390}`. Plan § What Michael will see: one row per capture + the Jest tests that cover the live state (VoiceWidget speaking, MemoryStrip pulse, usher). CLAUDE.md How to verify. Tests 1625 → 1627 (97 suites).
- Verified: dev server restarted with dummy `LIVEKIT_*` → script exit 0, report 54 OK / 0 FAIL (focus on `concierge-panel-title` after opening and `concierge-pill` after Esc, scrollWidth 390 with the panel open, callout gone on a second load, the 429 line the only console error, no token POST without Connect); `init.sh` restarted the plain server, smoke exit 0; `.harness/check.sh` → `check: lint ok · jest ok · build ok`. I looked at every capture.
- Seen in the captures: at 390 with a v2 cached body the transcript keeps ~130 px above the 25 vh tab area (P3-06's open question: room enough). The bottom sheet covers the whole page below `lg` (the D94 question still stands).
- Next (P3-10): review; the 390 sheet's Forget-me hint sat under next dev's badge only in dev (production has none).
- Questions for Michael: none new (D84, D92, D93, D94, D96 still open).

### 2026-10-21 07:15 · P3-08 · passes

- Usher (D94): `ConciergeProvider` registers `concierge.navigate` (four topics, all unregistered at teardown) and calls `router.push` only with Guide me on, `isAllowedHref`, from `session.agentIdentity`, not the page already shown, 8 s (`performance.now`) after its last follow and after the visitor's own link click/back-forward, never from `/talk`; then a `who: 'notice'` line "Taking you to <name>". New `lib/concierge/usher.ts` (`usherTargets`, `usherName`, `USHER_INTERVAL_MS`; layout → SiteChrome → provider), `GuideMeSwitch.tsx` (role=switch, `concierge.guide_me`, sr-only hint), Transcript renders notices muted/italic/unattributed, `talkWidget` copy. Tests 1589 → 1625 (96 suites; new `usher.test.tsx`, `helpers/navigation.ts` mocks `next/navigation` in the 11 provider-rendering files).
- Verified: usher/Transcript/layout/review tests failed first; `.harness/check.sh` green (lint · jest · build); smoke exit 0 (41 PASS). Sonnet browser check on :7835, all PASS at 1280 and 390: switch 107×40 after Connect, Tab from Connect lands on it, click → 'off' stored, survives reload, Space → 'on', scrollWidth 390 with the panel open, no switch on /talk, no console errors; I looked at the 390 capture.
- Opus review: 0 Critical, 0 Important, 6 Minor, all fixed (plan § Review P3-08-1…6): the visitor's own navigation wins, sender identity checked, monotonic clock, Footer imported the `@/lib/data` barrel so SiteChrome shipped projects.ts on every page incl. /card (now `@/lib/data/profile`; the guard follows imports transitively), a vacuous /talk test, the plan's ref names + switch hint.
- Next (P3-09): the live usher can't be captured without an agent; `usher.test.tsx` covers it. The Guide me row sits under CallControls in the panel.
- Questions for Michael: (1) D94: below `lg` the bottom sheet covers the page, so a phone visitor sees the notice, not the page it opened; minimize the sheet on a follow at that width? D84, D93, D96, D92 still open.
- Proposed change: `/` and `/projects` still ship projects.ts to the client (`/projects` needs it; on `/` the hero's MethodStrip → `approach.ts` → `resolveProjectLink` in projects.ts); resolving `loopSteps` links on the server would drop it from `/`.

### 2026-10-21 07:40 · P3-07 · passes

- Cache (D91): `ConciergeProvider` reads `concierge.memory.<id>` after mount (only for an existing id; never makes one), saves each live body's raw text, clears it on Forget me's `{ok:true}` and ignores the agent's last empty body; `status.ts` `shownMemory` feeds `MemoryStrip` (`asOf` prop) and the Memory tab (`data-stale`, muted via `**:`, "as of <time>"). Busy retry (D92): `closing` phase + `closed` action + `isActive`; a loop in `connect()` re-POSTs every 5 s, one in flight, to 60 s; Leave/pagehide/unmount abort the request and end the wait. Copy (D93): intro both paragraphs, deep-dive `builtWith`, VC-A "knowledge pack" → "what it knows about my work"; evidence § P3 note. Tests 1496 → 1589 (95 suites).
- Verified: new tests failed first; `.harness/check.sh` → `check: lint ok · jest ok · build ok`; smoke exit 0 (41 PASS); `.harness/talk-busy-check.mjs` on a dummy-env server: 34/34 OK (12 POSTs, gaps 5003–5019 ms, max 1 open, busy line at 60 s, focus on Connect, no POST after Leave); cached view at 390: "as of", muted rgb(136,136,160), rejected row keeps #f87171, scrollWidth 390.
- Opus review: 0 Critical, 1 Important (browser copy never expired, privacy note silent) fixed as **D96 *default*** (expiry by `retention_days`, a 7th privacy line), 8 Minor: 7 fixed (abort, wake, rejected red, strip name "as of", `storage` event, placeholder, test pins), 1 asked (below). Plan § Review rows P3-07-1…9.
- Gotcha: Tailwind turns `_` in an arbitrary variant into a space; `[data-type=gate_rejected]` built fine in production but made the dev server 500 (now `data-rejected`). Turbopack cached the bad CSS until `rm -rf .next/dev`.
- Next (P3-08): `STREAM_TOPICS` is where `concierge.navigate` joins; the provider's `Session` now has `requests`/`wake`. talk-busy-check's old busy-visitor screenshots in docs/screenshots/v2 are stale (that state no longer exists); P3-09 captures the closing state.
- Questions for Michael: (1) D96: on a shared browser the cached memory shows before Connect and only a live call erases it; add a local "Clear this browser's copy" button, or drop the pre-call view? (2) D92: `reason: 'visitor'` is per network address, so a neighbour on conference Wi-Fi sees "Closing your earlier conversation…"; have the route check the room's visitor_id, or soften the line? D84, D93 still open.

### 2026-10-21 06:45 · P3-06 · passes

- New `concierge/MemoryStrip.tsx` (five chips with counts, `–` titled "not reported by this agent version" from a v1 body, a changed count pulses once `motion-safe:`, chips wrap), `PanelTabs.tsx` (WAI-ARIA tabs Memory · Latency · Privacy; `compact` in the drawer caps the panel at 25 vh / 40 vh at lg), `MemoryView.tsx` (About you: Profile/Episodes/Events; About the agent: Knowledge/Working/Cache; v1 fallback; Forget me always at its foot, disabled with "Connect to erase what it remembers"). Six `--color-mem-*` tokens in globals.css (+ `design-tokens.test.ts`, ratio helper in `src/__tests__/helpers/contrast.ts`). `MemoryPanel` and its test removed; `LatencyPanel` has no heading of its own; ForgetMeButton's confirm step handles Esc. Both the drawer and `/talk` render strip + tabs in a `section` with an `sr-only` h2. Tests 1407 → 1496 (92 → 95 suites).
- Verified: new tests failed first; `.harness/check.sh` → `check: lint ok · jest ok · build ok`; smoke exit 0 (41 PASS). Browser (Sonnet script + my re-run on :7835): dot colours rgb(0,212,255)…rgb(244,114,182), arrows/Home/End, Forget me disabled + hint, Esc → focus on the pill, scrollWidth 390 with the drawer open, tab cap 320 px at 1280×800 and 211 px at 390×844, /talk keeps its Privacy section, no console errors.
- Gotcha for the next session: the dev server on :7835 served a stale Tailwind theme (new `--color-mem-*` missing) from Turbopack's persistent cache, even after `init.sh`, whose `kill` of the npx pid left the `next-server` child on the port. Fix: kill the `next-server` pid (`ss -ltnp | grep :7835`), `rm -rf .next/dev`, rerun `init.sh`. The production build was always right.
- Opus review: 0 Critical, 1 Important (focus lost when Forget me goes disabled at call end: already handled by CallControls' call-ended effect; drawer tests added), 9 Minor: 8 fixed test-first, 1 kept (the aria-live forget line inside a tab panel). Plan § Review rows P3-06-1…10; D90 *As built*.
- Next (P3-07): the cached body goes into `MemoryStrip`/`PanelTabs` through `state.memory`'s fallback; `MemoryView` has no `data-stale` yet. P3-09 should capture a v2 body at 390 to confirm the 25 vh cap leaves the transcript room.
- Proposed change: P3-06's step said `overflow-x-auto` strip in the plan; the chips wrap instead (keyboard users can't scroll a container with nothing focusable). Questions for Michael: none new (D84, D93, the 390/402 px collapse still open).

### 2026-10-21 06:20 · P3-05 · passes

- `VoiceWidget` is the "Ask my site" pill (D87): three-rect bars glyph moving only while the agent speaks (`motion-safe:`, `@keyframes concierge-bar`), live dot, names "Ask my site: listening/speaking" when `phase === 'live'`, collapses to the glyph at ≤ 390 px once scrolled (`data-collapsed`), `id="concierge-pill"`. Provider gains `agentSpeaking` (ActiveSpeakersChanged; 500 ms hold before off; off on Reconnecting/agent leaving/Leave/Connect/pagehide) and `calloutSeen`/`dismissCallout` (read after mount; openPanel and Connect dismiss). New `concierge/Callout.tsx` (D88). Navbar six links (D89); Footer `pb-24` at every width; `talkWidget` copy (`liveLabel` gone); mock gains `setSpeakers`, `RoomEvent.ActiveSpeakersChanged/Reconnecting`. Tests 1342 → 1407 (91 → 92 suites, new `Callout.test.tsx`).
- Verified: new tests failed first (49, then 16 for the review fixes); `.harness/check.sh` → `check: lint ok · jest ok · build ok`; smoke exit 0 (41 PASS). Sonnet browser checks on :7835, 9/9 then 6/6 PASS: pill 136×48 at 16 px from the corner (1280), 48×48 collapsed after scroll at 390, callout above the pill, scrollWidth 390, Close → key '1' and focus on the pill, Esc dismisses, no callout at the page bottom, footer links clear the pill at 1280 and 390, nav = 6 links, no console errors.
- Opus review: 0 Critical, 2 Important (Close dropped focus to body; the bubble covered the Footer links), 10 Minor; all fixed test-first except three kept with reasons (plan § Review rows P3-05-5, -8, -9). Callout now shows only at scrollY 0 with the footer out of view (D88 *As built*).
- Docs: D87/D88/D89 *As built* in the v2 spec; plan § Widget/§ Callout built, § Review rows; CLAUDE.md (routes /talk row, Navbar, Footer, SiteChrome, VoiceWidget, components/concierge, mock helpers, test count). No new D (next free D96).
- Next (P3-06): the pill reads `phase === 'live'` only; MemoryStrip/PanelTabs go under the MessageBox in ConciergePanel. `tsc` over tests reports one pre-existing `jest.Mock` type error in ConciergeProvider.test.tsx (not in the build).
- Question for Michael: the spec's 390 px collapse misses iPhone 15/16 (393 px) and 16 Pro (402 px); widen to `max-width: 402px`? Proposed change (carried): `new Room({ disconnectOnPageLeave: false })`.

### 2026-10-21 05:40 · P3-04 · passes

- New `src/components/concierge/ConciergePanel.tsx` (non-modal `role="dialog"` drawer: h2 title focused on open, Minimize, `CallControls`, deep-dive link when offline/busy, `Transcript fill` + `MessageBox`; 420 px right at `lg`, bottom sheet under the Navbar below, `z-[45]`, in the DOM only while open) and `DeepDiveLink.tsx` (shared with `/talk`). Provider gains `panel`/`openPanel`/`minimizePanel`. `VoiceWidget` is a `<button aria-expanded>` toggling it (refocuses itself on close, `invisible` while open); `SiteChrome` renders panel then widget after the Footer, neither on `/talk` (reaching it closes the panel) or `/card*`. Tests 1303 → 1342 (90 → 91 suites, new `ConciergePanel.test.tsx`; VoiceWidget, SiteChrome, a11y-new-pages updated).
- Verified: new tests failed first (22, then 7 for the review fixes); `.harness/check.sh` → `check: lint ok · jest ok · build ok`; smoke exit 0 (41 PASS). Sonnet browser check on :7835, 9/9 PASS at 1280 and 390: drawer x860 w420 top64 at 1280, x0 w390 top64 at 390, scrollWidth = viewport, focus to title / back to widget on Esc and Minimize, open across /projects → /about, absent on /talk and /card, no console errors. My own check at 740×300: the sheet scrolls (331 > 235) and Send is reachable.
- Opus review: 0 Critical, 1 Important (the deep-dive link opened its page under the sheet: now minimizes), 7 Minor. Fixed: widget invisible while open; `/talk` closes the panel; neutral live label "Live call with my concierge"; sheet scrolls on short screens, log `overscroll-contain`; Esc ignored during IME composition; stronger tests (Tab not trapped, Esc from a focused control, live Esc focus, dropped call refocuses Connect in the panel). Deferred to P3-10: CallControls' "call ended → focus Connect" rule can pull focus into the drawer if the visitor's focus was on `<body>` from clicking page text.
- Docs: D86 *As built* in the v2 spec (Esc contract: inner handlers `preventDefault`); plan § Panel marked built; CLAUDE.md (SiteChrome, VoiceWidget, `components/concierge/`, /talk route row, test count). No new D (next free D96).
- Next (P3-05): the pill replaces the disc inside the same `<button>`; keep `expanded`/`onToggle`/`invisible`; Footer `pb-24` at every width is still to do; `talkWidget.liveLabel` goes when the listening/speaking names land. Questions for Michael: none new (D84, D93 still open). Proposed change carried from P3-03: `new Room({ disconnectOnPageLeave: false })`.

### 2026-10-21 05:05 · P3-03 · passes

- New `src/components/concierge/`: `ConciergeProvider.tsx` (reducer, session ref, the one Room, the six actions moved from TalkSession, `RoomAudio`, `pagehide` teardown, bfcache `pageshow` reset; `useConcierge()` throws outside), `CallControls.tsx` (Connect/Leave + focus rule, mic, Turn on sound, status), `status.ts`, `buttons.ts`. `TalkSession.tsx` 471 → 51 lines, markup over the context. `SiteChrome` wraps the chrome in the provider (not `/card*`) with `configured` from `layout.tsx`; `/talk`'s page no longer imports `env.ts`. Tests 1252 → 1303 (87 → 90 suites: `ConciergeProvider.test.tsx`, `status.test.ts`, `layout-concierge.test.tsx`; every TalkSession test renders through `renderTalk()` in `src/__tests__/helpers/concierge.tsx`).
- Verified: provider tests failed first (module missing); `.harness/check.sh` → `check: lint ok · jest ok · build ok`; smoke exit 0 (41 PASS); `grep -c 'new lk.Room'` → TalkSession 0, provider 1; `grep -rln concierge/env src/components` → nothing. Sonnet browser check on :7835: Connect (offline, 0 token requests) → Navbar About → Talk, client-side (window marker kept): the offline line survived; a reload cleared it; no console errors.
- Opus review: 0 Critical, 1 Important, 8 Minor. Important (a call outlives `/talk` with no visible way to Leave until P3-04) fixed test-first: the widget gets `live` (name "Live call with my concierge: back to it", red dot). Minors fixed: `pageshow` resets only a call `pagehide` ended; listener-ref and StrictMode-connect tests; a SiteChrome `/talk` → `/about` test; renamed unmount tests + remount-mid-connect case; server-only guard covers `rooms` and every `'use client'` file; `status.test.ts`; stale comments. One deferred (below).
- Docs: D85 *As built* in the v2 spec; CLAUDE.md (SiteChrome, `components/talk/`, new `components/concierge/`, VoiceWidget live, test count); plan § Ownership marked built. No new D (next free D96).
- Next (P3-04): `CallControls` is ready for the panel header; `talkWidget.liveLabel` and `VoiceWidget`'s `live` are a stopgap the button/pill replaces (keep a live state visible). The "suspended inside an act scope" console line in the talk tests predates P3-03.
- Proposed change (P3-04 or P3-10): livekit-client's own `disconnectOnPageLeave` (default on) also ends a call on `beforeunload`, which a `mailto:` click can fire; now that the provider owns page-leave, consider `new Room({ disconnectOnPageLeave: false })`. Questions for Michael: none new (D84, D93 still open).

### 2026-10-21 · P3-02 · passes

- `contract.ts`: contract v2. `MemoryBody` gains optional `v`, `about_visitor`, `about_agent`, `retention_days` (types `Episode`, `MemoryEvent`, `AboutVisitor`, `AboutAgent`); a v1 body parses unchanged with no v2 keys (a lone `"v": 1` stays v1). Also `TOPIC.navigate`, `RPC_GET_MEMORY`, `MEMORY_EVENT_TYPES`, `parseNavigate` (1 KiB cap; `parseObject` takes the limit) and `isAllowedHref`. New `memoryCache.ts` (`saveMemory`/`loadMemory`/`clearMemory`, `memoryCacheKey`, `MemoryStorage`), and `readVisitorId` in `visitorId.ts`, which never writes. Fixtures `memoryV2`, `memoryV2NoAgent` (+ JSON). Tests 1167 → 1252 (86 → 87 suites; new `concierge-memory-cache.test.ts`).
- Verified: watched each new test fail first (57 contract failures, then the cache module missing); `.harness/check.sh` → `check: lint ok · jest ok · build ok`; smoke exit 0 (41 PASS). The only existing contract case that changed is 'contract constants' (`navigate`, `RPC_GET_MEMORY`).
- Opus review of the diff: 0 Critical, 0 Important, 4 Minor. All four fixed test-first: a `v` below 2 on its own no longer turns on the v2 shape; `saveMemory` won't save a body `parseMemory` rejects, so a bad body can't replace a good cached one; ids that aren't UUID v4 are ignored; the storage type is now `MemoryStorage`, not the DOM's `CacheStorage`.
- Docs: CLAUDE.md `lib/concierge/` line and test count; plan § Contract v2 and § Cache marked built; *As built* notes on D91 and D95. No new decisions (next free is still D96).
- Next (P3-03): nothing calls the v2 fields, `parseNavigate` or the cache yet. `saveMemory` takes the raw body text, so P3-07 should hand `readBody`'s text through as the plan says.
- Questions for Michael: none new (D84, D93 still open). Proposed changes: none.

### 2026-10-21 · P3-01 · passes

- New `docs/plans/2026-10-21-P3-concierge-in-site.md`, all 14 sections: Ownership (the `ConciergeProvider` context table, what moves out of TalkSession.tsx function by function, `configured` from layout.tsx as a prop, `pagehide`/bfcache, StrictMode), Contract v2 (a parse table for every § 7 field; v1 bodies parse unchanged with no v2 keys), Panel/Widget/Callout (ASCII layouts at 1024+ and 390, focus order, z-[45]), Memory view (six `--color-mem-*` tokens, every one ≥ 6.17:1 on all three surfaces), Cache, Busy retry (`closing` transition table), Usher, Copy before/after, Tests per feature. D85–D95 are recorded in the v2 spec § v3 decisions; the next free number is D96. No code changed: 1167 tests, 86 suites, before and after.
- Verified: `.harness/check.sh` → `check: lint ok · jest ok · build ok`; smoke 0 FAIL; a grep for every item the steps name. An Opus review of the plan against P3-01…P3-08 found 16 issues (1 Critical, 7 Important), all fixed in the plan.
- Next session (P3-02): the existing 'contract constants' test pins `TOPIC` with `toEqual`. Add `navigate` there; it is the only existing contract case that changes. `readVisitorId` must not write.
- For P3-03 on: once P3-08 adds `useRouter`, every provider render needs `next/navigation` mocked (plan § Tests). `calloutSeen` lives in the provider, so the callout stays hidden after Minimize. Project slugs and titles reach the provider as `usherTargets` from layout.tsx, so `projects.ts` stays out of the client bundle.
- Question for Michael (D93): keep the new second intro paragraph ("Talk or type. The Latency tab shows…, and Forget me on the Memory tab erases…"), or cut the intro to the spec's first paragraph?
- Proposed change: none. P3-04's "`h-dvh` or `max-h-dvh`" is met by `top-16 … max-h-dvh`, so the sheet starts under the z-50 Navbar.

### 2026-10-21 verify · verify P2

| Feature | Step | What you ran or read | What you saw | Holds |
|---|---|---|---|---|
| P2-01 | 1 | `grep '^## ' docs/plans/2026-10-21-P2-experience.md`; read Decisions | Data, Links, Layout, Tests, What Michael will see, Review, Decisions present; D82 Earlier list (reversible) | yes |
| P2-01 | 2 | Read experience.ts; python check that every ≥40-char string in it occurs in spec § 8 | Bullet type exact; 6 role + 4 project bullets all found in spec; titles/periods/repos/hrefs as stated; earlierRoles no bullets; 6 coursework | yes |
| P2-01 | 3 | Read bullet links in experience.ts; experience-data.test 'are exactly the four links of the § 3 table' | Four links with exactly the stated hrefs; test asserts the table | yes |
| P2-01 | 4 | Read experience-data.test.ts (11 tests: verbatim, link once, slug resolves, public repos, titles) | Assertions match the step; all pass | yes |
| P2-01 | 5 | Read BulletWithLinks.test.tsx (plain, internal, external, mid-sentence, missing span) | Covers all four required cases; passes | yes |
| P2-01 | 6 | `npx jest --testPathPatterns 'experience|BulletWithLinks|content-guard|a11y-new|card'` | 10 suites, 135 tests pass (content-guard, experience page included) | yes |
| P2-01 | 7 | Ran lib/check.sh; `npx eslint` | check green (cached for this tree); eslint exit 0 | yes |
| P2-02 | 1 | Read experience/page.tsx and experience.test.tsx 'orders the h2s', links, Earlier, coursework tests | Order h1, roles, Projects, Earlier, Education; tests assert hrefs, deep-dive/repo links, no list in Earlier, six coursework; pass | yes |
| P2-02 | 2 | Read a11y-new-pages.test.tsx line 25; ran it | /experience included; passes; page uses sectioned h2/h3 with no skipped levels | yes |
| P2-02 | 3 | `git diff --stat <after P1-08>..HEAD -- src/app/card src/__tests__/pages/card.test.tsx` | empty: /card untouched; card tests pass | yes |
| P2-02 | 4 | grep CLAUDE.md for experience.ts and /experience rows | Names Bullet, resumeProjects, earlierRoles; Routes row says 'roles with linked bullets, resume projects, Earlier, education' | yes |
| P2-02 | 5 | lib/check.sh; `node .harness/smoke.mjs` | check green; smoke 0 FAIL, all routes PASS incl. /experience at 1280 and 390 | yes |
| P2-03 | 1 | `ls -l docs/screenshots/v3/P2-*` | 1280: 279741 B, 390: 263128 B, both under 400 KB | yes |
| P2-03 | 2 | Read plan § What Michael will see; own Playwright at 390 on dev server | Plan lists links/Projects/Earlier/coursework; measured max li right edge 366 ≤ 390, 0 overflowing li, page scrollWidth 390, 4 links underlined with the right hrefs | yes |
| P2-03 | 3 | `node .harness/print-check.mjs http://localhost:7835 /experience …/print-experience.png` | PASS print, exit 0, linksNotUnderlined 0, nav/footer hidden | yes |
| P2-03 | 4 | lib/check.sh; smoke | green; smoke all PASS | yes |
| P2-04 | 1 | Read plan § Review table; git log since P1-08 | 9 findings each with severity, file:line, resolution; digit claims traced to § 8 (my own check found all bullets in the spec) | yes |
| P2-04 | 2 | `git log --oneline` 025c040 (Important #2 fix), tests named in plan | Important fix in its own commit with tests; Minors fixed or reasoned; finding 1 recorded as D84 | yes |
| P2-04 | 3 | Read Role in experience.ts; `npx eslint` | Role.type gone, textLink shared; eslint clean | yes |
| P2-04 | 4 | Read docs/review-guide.md '## P2 (v3)', CLAUDE.md, spec D82–D84 | Section present with look-at and merge notes; CLAUDE.md matches code; D82–D84 in v2 spec | yes |
| P2-04 | 5 | lib/check.sh; smoke | green; smoke all PASS | yes |

### 2026-10-21 04:45 · P2-04 · passes

- Review: an Opus reviewer read `$HARNESS_SCRATCH/P2.diff` (1145 lines). It found 0 Critical, 2 Important and 7 Minor. All ten new bullets match § 8 character for character, so every number traces. The table is in the plan's § Review.
- Fixed test-first (025c040): new-tab links on /experience (the repo lines, any external bullet link) now carry an sr-only "(opens in new tab)", like Footer and /card. Two tests were red before the fix.
- Simplification (1b251bb): `Role.type` dropped (nothing read it). New `components/textLink.ts` is the one link class for /evidence, /experience and BulletWithLinks. The Projects test now reads the rendered `li`s. The vestigial "Pioneered" test and a duplicate title test are gone. One test added: a missing link span renders as plain text. Tests 1168 → 1167 (86 suites).
- The other Important finding (the agent harness's third § 8 bullet, "189 features passed in 4 days at ~$3 each", is left out) I re-rated Minor. § 3 says "two bullets each", so it became **D84** *default* and is not a code change. **Michael: add that bullet? And should the project periods use `–` like the roles (they keep § 8's `-` now)?**
- Docs: the v2 spec has D84, and docs/review-guide.md has `## P2 (v3)` (what to look at, undo). CLAUDE.md now has the textLink, the D84 and new-tab notes and the 1167 count.
- Verified: `.harness/check.sh` printed `check: lint ok · jest ok · build ok`. smoke.mjs exit 0 (41 PASS). print-check PASS on /experience and /evidence. curl /experience shows the sr-only cue.
- Next: P2 is done. The D83 and D84 questions stay open for Michael.

### 2026-10-21 04:20 · P2-03 · passes

- Changed: added `docs/screenshots/v3/P2-experience-1280.png` (273 KB) and `-390.png` (257 KB) from the dev server on :7835. Filled in the § What Michael will see table in `docs/plans/2026-10-21-P2-experience.md` (one row per capture plus a print row). CLAUDE.md's captures note now mentions P2. No code changed: tests stay at 1168 (86 suites).
- Verified: `.harness/check.sh` printed `check: lint ok · jest ok · build ok`. smoke.mjs exit 0 (41 PASS). captures.mjs reported scroll 0 at 390. The longest bullet (music server, 211 chars) has its box at x 24→366 and scrollWidth = clientWidth = 342. `print-check.mjs … /experience` printed `PASS print` with linksNotUnderlined 0.
- Michael: the bullet links are foreground text with an accent underline (50 %), not accent-coloured text. This is the /evidence look, and the plan row says so. If you want the phrases in accent, it's one class in `BulletWithLinks.tsx`.
- Next (P2-04): the 390 capture shows the fixed VoiceWidget over the Builder Clarity heading and the Next dev "N". Both are artefacts of a full-page dev capture, not layout bugs. The third agent-harness bullet from § 8 is still left out (see P2-02).

### 2026-10-21 04:05 · P2-02 · passes

- `/experience` now renders: h1 · the two roles (bullets via `BulletWithLinks`) · h2 Projects (name h3 → deep-dive, `github.com/…` repo line → GitHub in a new tab, period, two bullets) · h2 Earlier (one `<p>` per role, title · company · period, no `<ul>`) · h2 Education (six resume coursework items). Projects/Earlier/Education are `section`s labelled by their h2. The page now has local `Bullets`, `Divider` and `PERIOD` helpers, so roles and projects share one bullet list.
- Tests: 1160 → 1168 (86 suites). `experience.test.tsx` covers the h2 order, the four bullet links, the deep-dive and repo links (via `within` the Projects section), Earlier with no `ul`, and the coursework. `a11y-new-pages.test.tsx` now includes `/experience`.
- Verified: `.harness/check.sh` printed `lint ok · jest ok · build ok`. smoke.mjs exit 0, every route PASS. I looked at captures.mjs full-page shots at 1280 and 390: no scroll, links underlined. Nothing under src/app/card or card.test.tsx changed. CLAUDE.md: Routes row and Data Layer line updated, test count 1168.
- Next (P2-03): the captures go to docs/screenshots/v3 (`node .harness/captures.mjs docs/screenshots/v3 P2 /experience` gives `P2-experience-*.png`, ~270 KB each). Resume § 8 has a third agent-harness bullet (189 features, ~$3 each) that P2-01 left out because the feature says two bullets each. P2-04 could ask Michael about it.

### 2026-10-21 · P2-01 · passes

- `experience.ts` now carries resume v4 (§ 8) word for word. `Bullet` (string or `{ text, links }`) and `bulletText`; `roles` holds only MAXX and Builder Clarity, three bullets each, with the four § 3 links. New: `resumeProjects` (agent harness, music server: href, repo, period, two bullets each) and `earlierRoles` (Tahoma, High Cascade: no bullets, D82). Coursework is the six resume items. New `components/experience/BulletWithLinks.tsx` (Server Component); `/experience` renders the bullets through it. Plan: `docs/plans/2026-10-21-P2-experience.md`.
- Tests: 1146 → 1160 (84 → 86 suites). New `experience-data.test.ts` (holds the § 8 strings) and `BulletWithLinks.test.tsx`. Updated `experience.test.tsx` and `data.test.ts` (2 roles). `claims-on-linked-page` now reads the projects and earlier roles too.
- Verified: `.harness/check.sh` printed `lint ok · jest ok · build ok`; smoke.mjs passed every route; curl /experience showed the four links with the right hrefs.
- Next session (P2-02): the page doesn't render `resumeProjects` or `earlierRoles` yet, so Tahoma and High Cascade are missing from /experience until then. `Role.type` is still unused (P2-04 decides). The M2-03 High Cascade age-range test is gone along with that bullet.
- D83 *default*: six /evidence items cite /experience lines that the resume dropped (Capability Patterns, migrations ×2, de facto PM, Agile/Scrum, mentoring). They keep their link. The mentoring item lost "12–18" so the claims check holds. **Michael: keep, relink or drop these six?** D82: is the Earlier list OK?

### 2026-10-21 verify · verify P1

Re-ran check.sh (green), full jest (84 suites, 1146 tests), smoke.mjs (all PASS), logos-check, print-check, captures.mjs; read the code and tests named below. All 8 features hold.

| Feature | Step | What you ran or read | What you saw | Holds |
|---|---|---|---|---|
| P1-01 | 1 | step 1 check | ls plan + grep '^## ': Positioning, Loop strip, Logos, About, Approach fold, Site-wide strings, Tests, What Michael will see, Review, Decisions all present; Positioning table lists brand.md/HeroSection etc. | yes |
| P1-01 | 2 | step 2 check | Plan § Loop strip (lines 29-92) has LoopStep type, 5 rows; they match spec §2 table lines 50-54 verbatim (grep); mapping matches approach.ts | yes |
| P1-01 | 3 | step 3 check | Plan § Logos (93-179) read: 12 marks, generator, devDependency, Logo, positions; logos-check overlaps 0 | yes |
| P1-01 | 4 | step 4 check | Plan § Approach fold: names next.config redirects(), stub fallback, file list; built version = redirects (curl 308) | yes |
| P1-01 | 5 | step 5 check | v2 spec D75-D81 present, each with Superseded lines on D1/D23/D32/D39 | yes |
| P1-01 | 6 | step 6 check | check.sh green (cached, same code tree) + full `npx jest --silent`: 84 suites, 1146 tests pass; smoke all PASS | yes |
| P1-02 | 1 | step 1 check | profile.ts:19,21 strings exact; vcard.ts TITLE from positioning; the listed jest files + case-study/approach/MethodStrip/home/about suites: 17 suites 153 tests pass; vcf-route.test asserts 'TITLE:Agentic Systems Engineer' | yes |
| P1-02 | 2 | step 2 check | approach.ts loopSteps ids/labels/lines/principles read vs spec §2 (match); methodSteps unchanged; case-study-anchors + components/case-study green | yes |
| P1-02 | 3 | step 3 check | home.test.tsx:17-22 asserts Spec..Learn and no /Diagnose/; MethodStrip/HeroSection tests pass; grep approachIntro in src: none | yes |
| P1-02 | 4 | step 4 check | aboutIntro in approach.ts = subline + labels joined; about.test.tsx:64-71 asserts subline and labels in order; approach.test.ts:45-72 five ids unique, principle exists | yes |
| P1-02 | 5 | step 5 check | v2 spec D76, D77 present (lines 454, 460); plan § Decisions present | yes |
| P1-02 | 6 | step 6 check | check.sh green (cached) and smoke.mjs all PASS incl. every route | yes |
| P1-03 | 1 | step 1 check | ran `node scripts/logos.mjs` twice: 'git status --porcelain src/components/logos' empty; header names 16.9.0, CC0, brand guidelines; 12 keys verified; package.json scripts.logos present | yes |
| P1-03 | 2 | step 2 check | package.json devDependencies simple-icons 16.9.0, not in dependencies; grep from 'simple-icons' in src empty; npm ls shows 16.9.0 | yes |
| P1-03 | 3 | step 3 check | Logo.tsx viewBox 0 0 24 24, <title> or aria-hidden; paths.test.ts, Logo.test.tsx pass (3+2 tests, both modes) | yes |
| P1-03 | 4 | step 4 check | FloatingLogos renders 12 via Logo (rendered home HTML has the 12 titles; test asserts names by accessible name, none of Zapier/Supabase/Linear/Pipedream/React/Vercel, hidden xl:, reduced motion); no pipedreamPath. Names come from svg <title> not aria-label (equivalent accessible name) | yes |
| P1-03 | 5 | step 5 check | `node .harness/logos-check.mjs` printed 12 boxes, logos: 12, overlaps: 0; smoke passes | yes |
| P1-03 | 6 | step 6 check | CLAUDE.md lines 44, 89, 154 cover npm run logos, paths.ts, simple-icons devDependency D78 | yes |
| P1-03 | 7 | step 7 check | check.sh green (cached); 84 jest suites pass | yes |
| P1-04 | 1 | step 1 check | curl /about: section#how-i-work aria-labelledby, h2 'How I work' between story and Philosophy, 5 /projects/ links; about.test.tsx:97-139 asserts section, 5 items/links, resolveProjectLink | yes |
| P1-04 | 2 | step 2 check | intro = aboutIntro (captures.mjs intro text); about.test.tsx:84 Philosophy 'I build and connect things'; old-angle guard test passes | yes |
| P1-04 | 3 | step 3 check | bullets file: 14 top-level bullets, 0 non-bullet prose lines, order Duke/Builder Clarity/MAXX/harness+concierge/next, all end with (source), 2 '(failure story)', no phone number | yes |
| P1-04 | 4 | step 4 check | jest content-guard, about, a11y-new-pages, claims-on-linked-page: 4 suites 115 tests pass | yes |
| P1-04 | 5 | step 5 check | check.sh green (cached) and smoke.mjs all PASS | yes |
| P1-05 | 1 | step 1 check | curl -sI /approach: HTTP/1.1 308, location: /about#how-i-work | yes |
| P1-05 | 2 | step 2 check | src/app/approach and approach.test.tsx absent (ls); approach-redirect.test.ts asserts source/destination/permanent true; passes | yes |
| P1-05 | 3 | step 3 check | Navbar.tsx 7 links in order, grep -c "'/approach'" = 0; Navbar.test.tsx:22,51 pin the list (desktop + mobile menu) | yes |
| P1-05 | 4 | step 4 check | grep /approach in sitemap.ts, smoke-routes.txt, a11y test, competencies-links: none (sitemap-robots test is src/__tests__/app/); approach.ts keeps principles/resolvedExamples/exampleHref; approachClosing absent | yes |
| P1-05 | 5 | step 5 check | CLAUDE.md rows /approach, /about (How I work), MethodStrip two users present; review-guide.md '## P0–P1 (v3)' at line 222 | yes |
| P1-05 | 6 | step 6 check | check.sh green (cached), smoke PASS incl. '/approach → /about#how-i-work' | yes |
| P1-06 | 1 | step 1 check | grep old-angle phrases in src public: no hits (rc=1); grep 'Agentic Systems Engineer' profile.ts: one line (19) | yes |
| P1-06 | 2 | step 2 check | layout-metadata.test.ts:6 pins title; plan § Site-wide strings table lists before/after per page; skills/projects descriptions rewritten | yes |
| P1-06 | 3 | step 3 check | card.test.tsx:14, card-qr.test.tsx:25, vcf-route.test.ts:28 assert new string; live /michael-herron.vcf has TITLE:Agentic Systems Engineer; /card has no 'Glad we met'; opengraph-image.test.ts passes | yes |
| P1-06 | 4 | step 4 check | brand.md § Positioning has '### v3 (2026-10-21)' with strings + loop, 10-18 text kept as history | yes |
| P1-06 | 5 | step 5 check | git diff --stat of the snapshots dir since P0-01: empty (no hunks to explain; plan § Tests says so); full jest 84/84 suites green | yes |
| P1-06 | 6 | step 6 check | CLAUDE.md rows / and /about, Data Layer loopSteps next to methodSteps, MethodStrip loopSteps, spec line names 2026-10-21 spec: all read | yes |
| P1-06 | 7 | step 7 check | check.sh green (cached) | yes |
| P1-07 | 1 | step 1 check | six PNGs exist in docs/screenshots/v3/ all < 400 KB (max 363 KB), taken by captures.mjs | yes |
| P1-07 | 2 | step 2 check | plan § What Michael will see: table of 6 captures + /approach + print rows, with eyebrow, strip, logos overlaps 0, about links; my own captures.mjs run: eyebrow AGENTIC SYSTEMS ENGINEER, strip 1 row@1280 / 2 rows@390, 5 About hrefs identical, gladWeMet false | yes |
| P1-07 | 3 | step 3 check | curl -sI /approach location /about#how-i-work, row in table; print-check.mjs /about exit 0 (PASS print) | yes |
| P1-07 | 4 | step 4 check | smoke.mjs all PASS (no horizontal scroll at 390 on /, /about, /card) | yes |
| P1-07 | 5 | step 5 check | check.sh green (cached) | yes |
| P1-08 | 1 | step 1 check | plan § Review: 12 rows with severity, file:line, resolution; cites P1.diff and P0-01.diff files | yes |
| P1-08 | 2 | step 2 check | No Critical/Important; git log shows 4 'P1-08 review #n' commits for fixes (#1,#3,#7,#9), Minor others fixed or reasoned (rows 2,10-12) | yes |
| P1-08 | 3 | step 3 check | Simplification pass paragraph in plan; `npx eslint .` prints nothing | yes |
| P1-08 | 4 | step 4 check | CLAUDE.md, review-guide § P0–P1 (v3), asset-checklist exist; v2 spec § v3 decisions holds D75-D81 consecutively | yes |
| P1-08 | 5 | step 5 check | check.sh green (cached) + smoke all PASS | yes |

### 2026-10-21 09:40 · P1-08 · passes

Opus review of `P1.diff` (after P0-01..HEAD, 2866 lines) + `P0-01.diff` (2588) from scratch: **0 Critical, 0 Important**, 7 Minor, 5 Nit, all in the plan's § Review table. Fixed test-first in their own commits: #1 FloatingLogos now draws with `Logo` (it had no user; new test red first), #3 the old-angle guard also catches the 10-18 subline (red first on about.test:78, now built from parts), #9 MethodStrip test asserts every `methodSteps` line absent, #7 booth lines out of `.gitignore`. Docs: "Superseded by D7x (v3)" lines on D1/D23/D32/D39 (v2 spec) and D60 (VC page spec); D77/D79 built notes record the deletions; review guide § P0–P1 has P0-01…P1-08 bullets and D75–D81; CLAUDE.md count and Logo line. Simplification: four types in approach.ts no longer exported (nothing imports them); no duplicated strings. **D81** *default*: `principles` stays whole as data (corrects the v3 spec's reason: /evidence and the case studies don't read it). Tests 1145 → 1146, 84 suites.
Verified: `.harness/check.sh` → `check: lint ok · jest ok · build ok`; `npx eslint .` and `tsc --noEmit` clean; smoke exit 0, 41 PASS + `/approach → /about#how-i-work`; logos-check → logos: 12, overlaps: 0; 1280 home screenshot looked at (logos unchanged).
Next session: P1 is done; next free decision **D82**.
Question for Michael (repeats P1-05's, now D81): keep the six principle titles/summaries and the thirteen unrendered examples in `approach.ts`, or trim them? Also left for you: the Philosophy quote's pre-v3 wording (spec says it stays) and the D77 mapping (Context and Build links match their steps loosely).

### 2026-10-21 08:50 · P1-07 · passes

Six P1 captures in `docs/screenshots/v3/` (home/about/card × 1280/390, 97–354 KB; three quantized from 476/528/514 KB), taken with the new `.harness/captures.mjs` (scrolls each page through so ScrollReveal sections show, prints eyebrow, strip rows, How I work links, "Glad we met", scroll). Plan § What Michael will see filled: one row per capture + `/approach` and print rows + an observation. `print-check.mjs` failed on /about with `nonBlackText: 1`: the `<source>` in the video has no computed style (colour `""`); the check now skips empty colours (never run on /about before). CLAUDE.md How to verify names captures.mjs. Tests 1145 / 84 suites, unchanged.
Verified: hero strip at 390 on **2** rows (`ol` 342 × 56), 1 row at 1280; eyebrow `AGENTIC SYSTEMS ENGINEER`; five How I work links/hrefs printed; card `Agentic Systems Engineer`, no "Glad we met"; `logos-check` → logos: 12, overlaps: 0; `curl -sI /approach` → 308, `location: /about#how-i-work`; print-check /about exit 0 (capture looked at); smoke exit 0, 41 PASS; `.harness/check.sh` → `check: lint ok · jest ok · build ok`. All six captures looked at.
Next session (P1-08): next free decision **D81**. Full-page captures put the fixed VoiceWidget and the Next dev "N" over a line of the /about story at 390 (capture artifact, noted in the plan).
Proposed change for P1-08/P6: /about's Philosophy still reads "I find where processes break down, then architect automations and integrations to fix them", the pre-v3 angle; the old-angle guard doesn't catch that wording.

### 2026-10-21 08:20 · P1-06 · passes

`/skills` and `/projects` metadata descriptions rewritten for the agentic angle (plan § Site-wide strings; every other page's description was read and holds or follows `profile`). The grep's last hit was a ProjectsGrid test title, renamed. New `lib/positioning-strings.test.ts` (old-angle phrases on no non-binary file in src/public, spacing/hyphen/`&amp;` variants) and `pages/projects.test.tsx`; OG test pins the alt with the new positioning; card-qr asserts the literal. brand.md heading is now `### v3 (2026-10-21)`. CLAUDE.md: spec line names the v3 spec, `/` and `/about` rows, approach.ts line, count. Plan § Tests: rows added, snapshot row says unchanged. Tests 1140 → 1145, 82 → 84 suites.
Verified: skills/projects tests red first; positioning-strings red against the old ProjectsGrid title and a planted `Systems &amp; Process` svg; `git diff --stat <after P0-01>..HEAD` on __snapshots__ empty; grep empty; `.harness/check.sh` → `check: lint ok · jest ok · build ok`; smoke exit 0, 41 PASS. Opus review: 2 Minor + 2 Nit, all fixed (no "integration platforms" overclaim, skills description cut to ~105 chars, wider regex, binary deny-list instead of a text allow-list).
Next session (P1-07): next free decision **D81**. No new questions.
Proposed change: `/projects`' visible lede ("integrations, full-stack apps, and tools") still has no agentic word; outside P1-06's metadata scope, P6's copy notes could pick it up.

### 2026-10-21 07:45 · P1-05 · passes

`/approach` is a 308 to `/about#how-i-work` from `next.config.ts` `redirects()` (hash kept under `curl -sI`, so no `permanentRedirect` stub; plan § Approach fold says so). Deleted `src/app/approach/page.tsx`, `approach.test.tsx`, `approachIntro`, `approachClosing`. Navbar has seven links; sitemap, smoke-routes, a11y-new-pages, competencies-links ROUTES and sitemap-robots drop `/approach` (sitemap test now pins the exact eight static URLs). New `approach-redirect.test.ts`; `.harness/smoke.mjs` also checks the 308 + Location on no-argument runs. CLAUDE.md (route row, Navbar, MethodStrip, approach.ts, test count), review-guide `## P0–P1 (v3)` (merge note, undo), D79 marked built. Tests 1155 → 1140, 82 suites (the page's own tests went with it).
Verified: redirect + Navbar tests red first (2 failing); `.harness/check.sh` → `check: lint ok · jest ok · build ok`; smoke exit 0, every route PASS plus `/approach → /about#how-i-work`; Sonnet browser check at 390 and 1280: 308 → 200, `#how-i-work` top 96 px, seven links in order, About aria-current, no console errors, no horizontal scroll; 390 screenshot looked at. Opus review: 3 Minor, all fixed (comments said /evidence reads `principles`, it doesn't; claims test comment; smoke had no runtime redirect check).
Next session (P1-06): next free decision **D81**.
Question for Michael: since D79 only five principle examples show (first sentence each, on /about How I work); the six principle titles/summaries and the other twelve examples are on no page but still in `approach.ts` (and checked by claims-on-linked-page). Keep them as data, or should P1-08 delete them?

### 2026-10-21 07:20 · P1-04 · passes

`/about` has `<section id="how-i-work" aria-labelledby="how-i-work-heading">` (h2 How I work, `scroll-mt-24`) between the story and Philosophy: `MethodStrip showLines label="The loop" examples=…`, one link per step from the new `loopStepExample(step)` in `approach.ts` (first linkable example of the step's principle → `{ href, text: first sentence }`, throws if none). `MethodStrip` gains an optional `examples` prop (hero passes none, unchanged). New `docs/notes/about-narrative-bullets.md`: 14 sourced bullets, 2 failure stories. Tests: about (+6), MethodStrip (+2), approach lib (+3), a11y-new-pages now covers `/about`: 1141 → 1155 tests, 82 suites. D80 marked built in the v2 spec and plan; CLAUDE.md /about row, MethodStrip line, test count.
Verified: about tests red first (5 failing); `.harness/check.sh` → `check: lint ok · jest ok · build ok`; step-4 jest command 4 suites/123 tests green; smoke exit 0, 42 PASS; Sonnet browser check: `/about#how-i-work` at 390 puts the h2 at top 96 under a 65 px navbar, no horizontal scroll, five steps in one row at 1280, accent focus outline, no console errors; 390 screenshot looked at. Opus review: 2 Important + 5 Minor, all fixed (bullets said "first two overnight runs" for Oct 17 → "first two harness v2 runs"; facts only in § 8 now cite it too; dropped sub-bullets with sources outside the allowed set; a redundant claims test removed).
Next session (P1-05): How I work is ready for the `/approach` redirect target. Note: full-page smoke screenshots don't trigger ScrollReveal, so sections below the fold look empty in them; scroll the section into view to look at it. Next free decision: **D81**.
Question for Michael: the Covid/Colorado detour in the current story has no note under docs/notes/, so the bullets leave it out; it stays on the page. Keep it in the rewrite?
Proposed change: at md+ the five columns in `max-w-3xl` are ~131 px wide, so the longer link texts wrap to ~6 lines of 12 px; P6's design notes could consider a wider section or a stacked layout.

### 2026-10-21 06:30 · P1-03 · passes

`scripts/logos.mjs` (`npm run logos`) writes `src/components/logos/paths.ts` (`logoPaths`, 12 keys, `LogoKey`; header: simple-icons 16.9.0, CC0, brand guidelines apply); `Logo.tsx` (title or `decorative`); `FloatingLogos` reads `logoPaths` in four columns outside the text column (plan § Logos); `pipedreamPath` and `public/pipedream.svg` gone; `simple-icons` moved to devDependencies at exactly 16.9.0. New `.harness/logos-check.mjs`. Tests: paths.test, Logo.test (new), FloatingLogos.test (12 names, none of the dropped six): 1122 → 1141 tests, 80 → 82 suites. CLAUDE.md Commands/Components/Code rules, D78 marked as built in the spec and plan.
Content guard: siPostgresql's path contains `1.582.553.9942` (compact SVG for 1.582 .553 .9942), which matched the US phone pattern. Fixed the content, not the guard: the generator adds separating spaces only in paths that trip the pattern (same 976 tokens, checked by tokenizing both) and throws if a path still trips it. Only postgresql is respaced.
Verified: tests red first; `.harness/check.sh` → `check: lint ok · jest ok · build ok`; `npm run logos` twice → `git diff` on src/components/logos clean; `npm ls simple-icons` 16.9.0; `grep "from 'simple-icons'" src` empty; `node .harness/logos-check.mjs` → logos: 12, overlaps: 0 at 1280×720/800/900 (hero text, navbar, VoiceWidget); smoke exit 0, 42 PASS; 1280 home screenshot looked at. Opus review of the diff: no findings.
Next session (P1-04): next free decision **D81**. No new questions.
Proposed change (repeat of P1-01's): step 3's "path starting with 'M'" is tested as `/^[Mm]/` (siClaude starts with `m`).

### 2026-10-21 05:45 · P1-02 · passes

`profile.ts`: positioning "Agentic Systems Engineer", v3 subline (tagline unchanged). `approach.ts`: `LoopStepId`, `LoopStep`, `loopSteps` (five rows verbatim from v3 spec § 2, principles per plan); `aboutIntro[1]` = "I work the way my harness runs: Spec, Context, Build, Verify, Learn."; `methodSteps` untouched. `MethodStrip` maps `loopSteps`. Tests updated/added in profile, vcard, vcf-route, layout-metadata, card, HeroSection, MethodStrip, home, about, approach (lib + page's strip loop now reads `loopSteps`): 1111 → 1122 tests, 80 suites. brand.md § Positioning has a `### v3` subsection (10-18 kept as history); D76/D77 marked as built in the v2 spec and plan; CLAUDE.md MethodStrip line.
Verified: tests red first (11 suites failing), then `.harness/check.sh` green (lint · jest · build); smoke exit 0, 42 PASS; case-study-anchors + case-study suites 35 pass, unedited; 390 px home and about screenshots read the new strings and loop; `grep -rni 'Systems & Process\|I find where work breaks' src public` → nothing.
Next session (P1-03): the old logos still overlap the strip at 1280 (pipedream next to the buttons, the lightning bolt left of Spec); the loop lines made the strip ~82 px tall as planned, so measure with the new tree. `approachIntro` stays until P1-05 (the /approach page reads it). Next free decision: **D81**. No new questions.

### 2026-10-21 05:10 · P1-01 · passes

Wrote `docs/plans/2026-10-21-P1-angle.md` (Positioning table of 10 files before/after, Loop strip type + five rows + step→principle links resolved on this tree, 12 logos with export names, generator, header and 12 positions measured at 1280×720/800/900, About, Approach fold, Site-wide strings, Tests table per feature, empty What Michael will see / Review tables, Decisions) and recorded **D76–D80** *default* in the v2 spec § v3 decisions. Docs only: 1111 tests / 80 suites, unchanged.
Verified: `.harness/check.sh` → `check: lint ok · jest ok · build ok`; smoke exit 0 at start; Opus review of the plan: 2 Important, 4 Minor and 2 Nit findings, fixed in the plan except Important #2 (below).
Next session (P1-02): `approach.test.tsx`'s method-label loop must switch to `loopSteps` in P1-02 (the /approach page lives until P1-05) or the suite goes red; about.test's intro assertion is P1-02's. Next free decision: **D81**.
Question for Michael: Spec and Context both link to `/projects/agent-harness#decisions` under the specified rule (different link texts). Keep that, or give Context a different principle?
Proposed change: P1-03 step 3 says each logo path starts with 'M'; `siClaude.path` starts with a lowercase `m` (valid relative moveto). Please read that step as `/^[Mm]/`.

### 2026-10-21 04:00 · verify P0

| Feature | Step | What you ran or read | What you saw | Holds |
|---|---|---|---|---|
| P0-01 | 1 | `git ls-files` on booth paths; `grep booth-bundle package.json`; `grep booth|/b/h.tgz CLAUDE.md`; `grep suites CLAUDE.md` | all empty; CLAUDE.md line 40 says 80 suites (test count 1115 there vs 1111 actual, not a step) | yes |
| P0-01 | 2 | `head -1` on the three booth spec/plan files | each starts 'Removed 2026-10-21 (P0-01): …' | yes |
| P0-01 | 3 | grep profile.ts; `npx jest card.test.tsx components/card`; read card.test.tsx:139 | `conferenceNote: ''`; 3 suites/37 tests pass; line 139 asserts queryByText(/Glad we met/) not in document | yes |
| P0-01 | 4 | diffed projects.ts excerpt vs driver.sh lines 204–220; jest case-study-agent-harness; grep Corrections | verbatim, 17 lines, ends `|| return 3`; suite passes, none skipped; dated 2026-10-21 Corrections line present | yes |
| P0-01 | 5 | tail of v2 spec; grep '^## v3 decisions' | section at line 444, first entry D75 *default*, names D50 and D39, reversible via git revert | yes |
| P0-01 | 6 | `.harness/check.sh`; `npx jest`; `node .harness/smoke.mjs` (twice) | 'check: lint ok · jest ok · build ok'; 80 suites/1111 tests pass; smoke exit 0, no FAIL lines | yes |

### 2026-10-21 03:00 · P0-01 · passes

Removed the booth (public/b, build script, its test, booth-bundle.md, npm script, CLAUDE.md route/command rows); added "Removed" lines to the three booth spec/plan files. `profile.conferenceNote` is now `''`; card.test asserts "Glad we met" is absent. Re-copied `merge_one` (17 lines) into the agent-harness excerpt, plus a Corrections line. Recorded D75 *default* in a new v3 section of the v2 spec.
Verified: `lib/check.sh` green; jest 81 → 80 suites, 1117 → 1111 tests, 0 failing; case-study-agent-harness 18 passed, none skipped; smoke passes every route.
Next session: D76 is the next free decision number. No questions.

### 2026-10-21 02:30 · initializer

**Scope.** `docs/specs/2026-10-21-portfolio-v3.md` in its § 12 order, per Michael's brief (`brief.md`): P0 cleanup,
P1 angle, P2 experience, P3 concierge in the site, P4 contact, P5 skills graph, P6 design recommendations (docs).
Build-only: never deploy, never touch the LiveKit env (a dummy env on the local dev server is fine), never push
`main`. The agent half (contract v2, spec § 7) is being built in parallel in `mh550/voice-concierge`: the page must
accept v1 and v2 bodies and treat every v2 field as optional.

**Features: 37.** P0 1 · P1 8 · P2 4 · P3 10 · P4 3 · P5 7 · P6 4. First three: P0-01, P1-01, P1-02.
Dependencies as § 12 says: P1 after P0; P2, P3, P4 and P5 each after P1 only; P6 after nothing (its three docs
features carry `after: []`, so they run whenever the queue ahead is blocked, and last otherwise). Earlier runs of
this project did 10–15 features in 2–3.4 h at $2–3.5 each (`~/projects/agent-harness/ledger/runs.jsonl`), so this
list is about 8–9 h.

**The suite is RED at the start of this run**, and P0-01 fixes it: `src/__tests__/lib/case-study-agent-harness.test.ts`
compares the agent-harness page's code excerpt with `/home/mh550/projects/agent-harness/lib/driver.sh`, and
`merge_one` there changed (its conflict branch now writes `$STATE/conflict-$m` and calls `needs_you`). Re-copy the
block from the comment line `# Merge one verified milestone` through the line ending `|| return 3` (lines 204–220
today, at most 25 lines) into `codeSnippets[0].code` of the agent-harness entry in `src/lib/data/projects.ts`.
Baseline: 81 suites / 1117 tests (1 failing); after P0-01 (booth test deleted): 80 suites.

**Where things live (read CLAUDE.md first; this is what it does not say yet).**
- Positioning: `profile.ts` (`positioning`, `subline`) feeds `layout.tsx`'s `<title>`, `HeroSection` eyebrow,
  `/card`, `/card/qr`, `vcard.ts` (`TITLE:`), the OG image. Tests that pin the old strings: `profile.test.ts`,
  `vcard.test.ts`, `vcf-route.test.ts`, `layout-metadata.test.ts`, `card.test.tsx`, `HeroSection.test.tsx`,
  `MethodStrip.test.tsx`, `home.test.tsx`, `about.test.tsx`, `approach*.test.ts(x)`, `competencies-links.test.ts`,
  and the snapshot `src/__tests__/app/__snapshots__/project-page-unchanged.test.tsx.snap`.
- The method: `approach.ts` has `methodSteps` (Diagnose…Simplify; the case studies' section ids, `MethodStepId`,
  `getCaseStudyAnchors` in `projects.ts`, `/evidence`) and `aboutIntro`. P1 adds `loopSteps` (Spec, Context, Build,
  Verify, Learn) **next to** it; `MethodStrip` (hero and the new `/about#how-i-work`) reads `loopSteps`; the
  case-study `MethodSteps` component keeps `methodSteps`. `approach.ts` imports `projects.ts` and vice versa: use
  them only inside functions, never at module load.
- `/approach` references: `Navbar.tsx`, `sitemap.ts`, `.harness/smoke-routes.txt`, CLAUDE.md, tests
  `Navbar.test.tsx`, `approach.test.tsx` (delete), `a11y-new-pages.test.tsx` (imports the page), `sitemap-robots.test.ts`,
  `competencies-links.test.ts` (ROUTES), `claims-on-linked-page.test.ts` (reads the data only; keeps working).
  `principles`, `resolvedExamples`, `exampleHref` stay: `/evidence` and `claims-on-linked-page` use them.
- Logos: `simple-icons` is **already a runtime dependency** (`^16.9.0`, imported directly by `FloatingLogos.tsx`
  since the original site). P1-03 moves it to devDependencies at exactly `16.9.0` and generates
  `src/components/logos/paths.ts` with `scripts/logos.mjs`. Installed 16.9.0 has siClaude, siLivekit, siPython,
  siTypescript, siGnubash, siSqlite, siPostgresql, siDocker, siLinux, siNextdotjs, siN8n, siGithub, siReact,
  siNodedotjs, siVercel, siTailscale, siSupabase, siOpenjdk, siCplusplus, siLinear, siZapier, siTailwindcss, siAnthropic;
  **no siLinkedin and no siPipedream** (simple-icons dropped LinkedIn). P4 draws the LinkedIn glyph by hand
  (`src/components/logos/extra.ts`) and records a D. Check a key with
  `node -e "console.log(!!require('simple-icons').siX)"` before using it.
- Experience: `experience.ts` has `roles: Role[]` (bullets are plain strings) and `education`; `experience.test.tsx`
  (14 tests) pins the current bullets. The resume v4 text is only in the v3 spec § 8: copy from there, never add the
  phone number (the content guard and brand.md forbid it).
- Concierge today: `TalkSession.tsx` (~480 lines, `'use client'`) owns the Room, the reducer (`sessionReducer.ts`,
  phases idle/connecting/waiting/live/ended/offline/busy), the three text-stream handlers registered before
  `connect()`, the mic (asked for only once the agent joins, D65), Forget me (RPC) and `MessageBox` (lk.chat). It is
  rendered by `src/app/talk/page.tsx` with `configured={conciergeEnv() !== null}`; `env.ts` and `rooms.ts` import
  `server-only`, so **a client file importing them fails `next build`**: P3-03 passes `configured` from
  `layout.tsx` (a Server Component) into `SiteChrome` as a prop. LiveKit loads on Connect (`import('livekit-client')`
  in the click handler, D45) and `RoomAudio` via `next/dynamic`; keep both out of the first load.
- Jest LiveKit: `src/__mocks__/livekit-client.ts` exports `Room` (= `MockRoom`, `Room.setup` hook, `Room.instances`),
  `lastRoom()`, `resetRooms()`, `pushText(room, topic, text, identity?)`, `addAgent(room, identity)`, `restart(room)`,
  `removeParticipant(room, identity)`, `RoomEvent`, `ConnectionState`, `ParticipantKind`; `@livekit/components-react`
  is mocked too. Under fake timers click with `fireEvent` and flush inside one `act` (see `TalkSession.test.tsx`).
  92 tests across `TalkSession*.test.tsx` render `<TalkSession>` directly: P3-03 gives them a provider wrapper
  helper (`src/__tests__/helpers/concierge.tsx`) rather than rewriting them.
- `SiteChrome.tsx` returns bare children on `/card*`; everything else (skip link, Navbar, `#content`, Footer,
  VoiceWidget except on `/talk`) renders inside it, so the `ConciergeProvider` goes there. The Navbar is `z-50`, the
  widget `z-40`; the Footer has `pb-24 xl:pb-8` to clear the widget (D61).
- Design tokens: `globals.css` `@theme inline` (`--color-background #0a0a0f`, `--color-surface #12121a`,
  `--color-accent #00d4ff`, `--color-muted #8888a0`). P3-06 adds the six `--color-mem-*` tokens there; a11y-new-pages
  has a contrast-ratio helper worth reusing. One `@media print` block at the end (pinned by `print-styles.test.ts`).
- Skills today: `skills.ts` = `skillCategories` (four groups, `process` featured, D20) read by `/skills` and
  `skills.test.tsx`; check `data.test.ts` before deleting the export.
- Contact today: `src/app/contact/page.tsx` has a subheader, three stacked cards and a closing note; the spec cuts
  the subheader and the note and makes three equal tiles in one screen.

**Harness gotchas.**
- Dev server: `.harness/init.sh` starts `next dev` on `$HARNESS_PORT`; `node .harness/smoke.mjs` loads every route at
  1280 and 390 (screenshots to `$HARNESS_SCRATCH`). If smoke suddenly returns 500 on every route after an HMR
  recompile, kill the server, move `.next` aside and rerun `init.sh` (seen on 2026-10-20 with a Tailwind
  `env(safe-area-inset-bottom)` arbitrary value).
- `.harness/check.sh` builds into `.next-check`; about 1 min. `playwright-cli` is not installed: Playwright lives in
  `/tmp/harness/pw` (see `smoke.mjs`'s `createRequire`); write one-off checks the way `talk-busy-check.mjs` does.
- Dummy env for concierge checks (P3-07, P3-09): restart the harness server with `LIVEKIT_URL=wss://livekit.invalid`
  and any key and secret, fulfil every token POST with `page.route`, then run `.harness/init.sh` again to restore the
  plain server. Nothing reaches LiveKit.
- Screenshots go to `docs/screenshots/v3/<milestone>-<page>-<width>.png`, under 400 KB each (reduce with PIL
  `quantize(16)` if needed, as `print-check.mjs`'s header describes), and every check feature lists them in its plan's
  "What Michael will see" table.
- Reviews read the milestone diff from a file: `git diff $(git log -1 --format=%H --grep='HARNESS: after <last id of
  the previous milestone>')..HEAD -- . ':!docs/screenshots' > $HARNESS_SCRATCH/<M>.diff`. Milestones can land out of
  order on this branch (P6 may run early), so if the range picks up another milestone's files, narrow it with paths.
- `docs/review-guide.md` gets a `## <M> (v3)` section per milestone (the review feature writes it); the voice-concierge
  evidence note's § Sentences with digits must list every new sentence with a digit on the deep-dive.
- Models: Opus for plans, builds, checks and reviews; Sonnet for P0-01 (mechanical) and P6-04 (URL and number
  verification). P6-01..03 are design work with research, not plain docs, so they run on Opus.

**Decisions this run makes for Michael (all the spec's defaults, recorded from D75; reversible).**
1. Positioning 'Agentic Systems Engineer' and the new subline (spec § 2); the tagline stays.
2. The loop strip's one example link per step uses a fixed step→principle mapping (P1-01 proposes spec→decisions-explicit,
   context→automate-bookkeeping, build→simplify-after-use, verify→verify-what-the-human-sees, learn→fakes-mirror-reality).
3. `/approach` → 308 to `/about#how-i-work`; after P1 the Navbar has seven links, after P3-05 six (Home, About, Skills,
   Projects, Experience, Contact): the spec's "seven" counted Approach.
4. Tahoma Films and the snowboard coaching stay as a one-line "Earlier" list on `/experience`.
5. The LinkedIn glyph on `/contact` is hand-drawn (simple-icons has none); simple-icons becomes a devDependency.
6. The widget stays on `/evidence` (D61's open question, unchanged).
7. The P3 check cannot capture a live call (no agent offline): the live state is covered by Jest only.
8. P5 uses a hand layout, no `d3-force`, unless the plan proves 390 px cannot fit (then record the pin).

**Questions for Michael (nothing waits on them).** Do you want the loop-step example links as mapped in 2? Is the
Navbar at six links right, or should Talk come back once the pill exists? Should `/evidence` lose the widget?
