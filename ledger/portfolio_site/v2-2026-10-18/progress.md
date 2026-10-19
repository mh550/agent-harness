# Progress log — run v2-2026-10-18 (branch `harness/v2-2026-10-18`)

What this file is: the shared memory of this harness run. Every session reads it at startup and adds a short
entry **at the top** (newest first): feature id, what landed, what the next session must know. The feature list is
`feature_list.json` in this directory: array order is priority, `after` lists are the real dependencies, a session
may flip only its own feature's `passes`. Michael steers through `INBOX.md` on this branch (first line
`status: run|pause|stop`; answers under `## Answers`). Plans go in `docs/plans/2026-10-18-<milestone>-<topic>.md`;
new defaults go in the spec's Decisions list as `D<n> *default*` (D15–D27 already appended by the initializer).

---

### 2026-10-19 verify S3

| Feature | Step | What you ran or read | What you saw | Holds |
|---|---|---|---|---|
| S3-01 | 1 | Read `@media print` in globals.css (l.54-127); grep `print:hidden` in components | white bg/black text, nav/footer hidden, pre pre-wrap + max-height none, links underlined; print:hidden on NodeGraph, FloatingLogos (+LoopingVideo, ProjectDetail) | yes |
| S3-01 | 2 | `node .harness/print-check.mjs` on /projects/agent-harness (first case study, projects.ts l.167); `ls` the screenshot | body rgb(255,255,255), visibleNav 0, PASS; docs/screenshots/v2/S3-print-agent-harness.png 235446 B (<400 KB) | yes |
| S3-01 | 3 | `npx jest print-styles.test.ts` | 6/6 pass; asserts block exists, nav/footer display none, pre pre-wrap/max-height none | yes |
| S3-01 | 4 | `lib/check.sh`; `node .harness/smoke.mjs` | check green; smoke all PASS | yes |

### 2026-10-19 02:10 · S3-01 · passes

- One `@media print` block at the end of `src/app/globals.css` (D40 *default*): white page and black text on every element (`*` with `!important`, then `html, body` white after it), borders #bbb, `nav`/`footer` hidden, `#content` top padding dropped, `pre` `pre-wrap` / `overflow: visible` / `max-height: none`, links underlined with external URLs printed after them, `[data-scroll-reveal]` forced to opacity 1 (framer leaves unrevealed sections at opacity 0, which printed blank). `print:hidden` on NodeGraph, FloatingLogos, the LoopingVideo button and both project back links (the bottom one's wrapper). ScrollReveal now adds `data-scroll-reveal`.
- Tests 631 → 643 (56 → 57 suites): new `src/__tests__/lib/print-styles.test.ts` (parses the print block: white/black, `nav`/`footer`, `pre`, `a`, reveal rule) plus render tests in the NodeGraph, FloatingLogos, LoopingVideo, ScrollReveal and ProjectDetail suites. Removing any one marker turns its test red. `project-page-unchanged` snapshots updated on purpose: the only diff is ` data-scroll-reveal="true"` and ` print:hidden` (checked by stripping both and diffing against the old snapshot).
- Verified: new `node .harness/print-check.mjs` (print media, 700 px) on /projects/agent-harness → body rgb(255, 255, 255), 0 visible nav/footer/canvas, 15 reveals all opacity 1, `pre` pre-wrap and not clipped, 0 non-black text, PASS; `/` PASS too. `docs/screenshots/v2/S3-print-agent-harness.png` is that capture reduced to 16 grays: 232 KB (720 KB raw). `lib/check.sh` green; smoke 38/38 PASS. Opus review: 0 Critical; I fixed the dead `html, body` white, the text-match tests and the empty bottom rule. Not done: highlighted diagram nodes print like plain ones; mailto links don't print their address.
- Next session must know: the Turbopack dev cache (`.next/dev`) kept serving the old globals.css even after a restart. Fix: kill the `next-server` on the port (the init's pid file only holds `npx`, so the child survives and the new server dies with EADDRINUSE), `rm -rf .next/dev`, rerun `.harness/init.sh`.
- Questions for Michael: none (D40 is reversible). Proposed changes: in step 2, a full-page PNG of a case study is about 700 KB at any width, so "under 400 KB" needs the 16-gray reduction; say so in the step. In `.harness/init.sh`, kill the process listening on the port rather than the `npx` pid.

### 2026-10-19 verify S2

| Feature | Step | What you ran or read | What you saw | Holds |
|---|---|---|---|---|
| S2-01 | 1 | read `profile.ts:13,29`, `ConferenceNote.tsx`, `card/page.tsx:59`; curl /card on :7800 | `conferenceNote: string` = `''`; component takes `note` prop, returns null if empty; page renders it in Selected work above h2; live /card has no note element | yes |
| S2-01 | 2 | read `card.test.tsx:122-138`, `ConferenceNote.test.tsx:5-7` | default-empty test asserts no `<p>` in section; component test renders 'Met me at a conference? Say hi.' as a P; page test also checks it precedes heading | yes |
| S2-01 | 3 | `grep conferenceNote docs/conference-kit.md` | line 19 tells where to type it in `src/lib/data/profile.ts` | yes |
| S2-01 | 4 | `lib/check.sh`; `node .harness/smoke.mjs` | check green; smoke 0 FAIL | yes |

### 2026-10-19 01:34 · S2-01 · passes

- `profile.conferenceNote: string` (default `''`) in `src/lib/data/profile.ts`; new `src/components/card/ConferenceNote.tsx` takes the note as a prop and renders one `<p>` (trimmed, accent left rule) or nothing; `/card` renders it inside the Selected work section above the h2 (section now `aria-labelledby` its h2). D39 *default* records this. `docs/conference-kit.md` has the line telling Michael where to type it.
- Tests 625 → 631 (55 → 56 suites): component test (renders 'Met me at a conference? Say hi.' as a `<p>`; nothing for '' or spaces), card.test.tsx (no note by default; with `jest.replaceProperty` the note renders inside the section, before the heading), profile.test.ts. Removing the `<ConferenceNote>` line from the page turns the card test red.
- Verified: `lib/check.sh` green; smoke 38/38 PASS; 390 px screenshot with the note filled in is `docs/screenshots/v2/S2-card-note-390.png` (scrollWidth 390); with it empty, no `<p>` in the section. Opus review: 0 Critical, 1 Important (restore leak, now `afterEach`), Minor fixes applied.
- Next session: S3-01 (print stylesheet) is the last stretch feature. Questions for Michael: none needed (D39 is reversible). Proposed changes: none.

### 2026-10-19 14:00 · verify S1

| Feature | Step | What you ran or read | What you saw | Holds |
|---|---|---|---|---|
| S1-01 | 1 | Read `src/app/projects/[slug]/opengraph-image.tsx`; grep fetch/font | exports size 1200×630, contentType image/png, generateStaticParams over projects; ImageResponse with #0a0a0f, title, first metric value+label, "Michael Herron"; no fetch (only comment mentions font) | yes |
| S1-01 | 2 | `npx jest src/__tests__/app/opengraph-image.test.ts`; read lines 88-96 | 14/14 pass; asserts size toEqual {1200,630}, generateStaticParams returns every slug, exports exist | yes |
| S1-01 | 3 | `curl -s -o /tmp/og.png -w ... :7800/projects/agent-harness/opengraph-image`; cmp with docs/screenshots/v2/S1-og-agent-harness.png; viewed image | `200 image/png`; byte-identical to screenshot; 1200×630 PNG, dark bg, title, "55 features passing in one day", Michael Herron | yes |
| S1-01 | 4 | `lib/check.sh`; `node .harness/smoke.mjs` | check green (cached, same tree); smoke all PASS | yes |

### 2026-10-19 13:30 · S1-01 · passes

- New `src/app/projects/[slug]/opengraph-image.tsx` (next/og, 1200×630 PNG, `generateStaticParams` over `projects`): on #0a0a0f it shows the company, the title, the first metric (value in accent, label) and "Michael Herron · Systems & Process Engineer". There is no font fetch. next/og's bundled Latin Noto Sans has no → or ↔, and a missing glyph makes it fetch from Google Fonts, so arrows are drawn as SVG and ≈ becomes ~. Projects without metrics (cherished, mirrored-google-calendars) show their shortDescription. D38 records this. Unknown slugs return 404.
- New `src/__tests__/app/opengraph-image.test.ts` (14 tests): exports, size, every slug, title/metric/name/background for all 9 projects, no fetch/fonts, a 404 digest, and every drawn character checked against the font's own cmap (a mutation that removes the arrow swap turns it red). Tests 611 → 625 (54 → 55 suites). CLAUDE.md routes and count are updated.
- Verified: curl :7800/projects/agent-harness/opengraph-image → `200 image/png`, saved as `docs/screenshots/v2/S1-og-agent-harness.png` (50 KB). I also looked at ghl (↔ and → arrows), paint-estimator and cherished. The page's `og:image` meta points at the route, 1200×630. `lib/check.sh` is green, and the build prerenders all 9 images (`.next-check/server/app/projects/*/opengraph-image.body`). Smoke 38/38 PASS.
- Opus review: 0 Critical, 4 Minor. Fixed: the 404 test now checks the digest, arrows in metric labels are centred, and the `size` prop is renamed. Kept: one shared `alt` for every project; a per-project alt needs `generateImageMetadata`, which changes the URL.
- Question for Michael (no answer needed): should project pages switch `twitter.card` to `summary_large_image` so X/Slack show the new image large (D38)? Proposed changes: none.

### 2026-10-19 13:00 · verify M9

| Feature | Step | What you ran or read | What you saw | Holds |
|---|---|---|---|---|
| M9-01 | 1 | Read docs/asset-checklist.md headings and media lines | Sections: HitList, agent-harness, home-media-server, MAXX (linear-ai-workflow, paint-estimator); each names public/projects/<slug>/ and a `media` entry snippet; HitList has recording/phone screens, agent-harness has attach/INBOX/notification, Amperfy present | yes |
| M9-01 | 2 | Read docs/review-guide.md vs `ls docs/plans` (M1-M8) and src/app | Per-milestone changed/look-at at 390 px for M0-M9; merge order M1 first, states M1 also ships M0 and harness setup | yes |
| M9-01 | 3 | Compared CLAUDE.md routes with find src/app; `npx jest --silent` | All 14 routes present incl. card, card/qr, approach, evidence, vcf, sitemap/robots; Tests: 611 passed, 54 suites matches; profile/approach/competencies listed; content guard section; spec/plans pointers; 'prerenders... not a static export' | yes |
| M9-01 | 4 | `grep -in 'create-next-app\|getting started' README.md`; read README | 0 hits; describes site, npm run dev/test/build, data-driven rule, link to /projects/agent-harness | yes |
| M9-01 | 5 | `git diff --stat HEAD~2 HEAD~1`; jest content guard; check.sh; smoke | Feature commit touches only docs/, CLAUDE.md, README.md, .harness/runs/; jest 611 pass (includes content-guard); check.sh green; smoke no failures | yes |

### 2026-10-19 12:00 · M9-01 · passes

- Wrote `docs/review-guide.md` (merge order M1 first, M1 ships M0 and the harness setup; per-milestone changes and what to check at 390 px), extended `docs/asset-checklist.md` (HitList kept; added agent-harness, Amperfy, MAXX projects, shared media-entry instructions), updated `CLAUDE.md` (spec/plans pointers, profile/approach/competencies modules, content guard) and replaced the `README.md` boilerplate.
- CLAUDE.md's routes table, 611-test count and "prerenders, not a static export" were already correct; checked against `src/app` and `npx jest --silent` (611, 54 suites; unchanged, docs only).
- Verified: README has 0 hits for create-next-app/Getting Started; `.harness/check.sh` green (lint, jest, build), smoke passed at the start.
- Question for Michael: may the MAXX projects get any screenshots at all? The checklist says to ask MAXX first.
- Proposed changes: none.

### 2026-10-19 verify M8

| Feature | Step | What you ran or read | What you saw | Holds |
|---|---|---|---|---|
| M8-01 | 1 | Read Navbar.tsx links array; Navbar.test.tsx lines 20-61 | 7 links Home..Contact in order, shared by desktop+mobile lists; test 'lists the seven links in order' checks both lists + href /approach; no Evidence/Card link test passes | yes |
| M8-01 | 2 | ProjectsGrid.tsx sortByOrder; ProjectsGrid.test.tsx 94-115 (ran, pass) | Titles equal order-sorted list; first metric value found in each non-thumbnail case-study card | yes |
| M8-01 | 3 | Read sitemap.ts, robots.ts, sitemap-robots.test.ts (ran, pass) | 8 routes + every project, from profile.siteUrl; no /evidence or /card/qr; robots disallows both, sitemap URL asserted | yes |
| M8-01 | 4 | curl :7800/sitemap.xml | grep -o <loc>; curl robots.txt | 17 locs (>= 7+9 projects); robots has 'Disallow: /evidence' | yes |
| M8-01 | 5 | node .harness/smoke.mjs; .harness/check.sh | 38 PASS, 0 other; check: lint ok · jest ok (611) · build ok | yes |
| M8-02 | 1 | Read docs/plans/2026-10-18-M8-polish.md | Table page · finding · severity · fix/D-ref covers /card, /card/qr, /approach, /evidence, 3 case studies; D36/D37 exist in spec (could not re-run the skill itself) | yes |
| M8-02 | 2 | Ran a11y-new-pages.test.tsx (pass); read its it() titles; plan contrast table | One-h1/no-skip heading, focus-visible, link-text, chrome focus, useReducedMotion tests present and green; contrast asserted from globals.css | yes |
| M8-02 | 3 | ls $HARNESS_SCRATCH/M8.diff; read plan review sections | M8.diff 141 KB exists; two reviews, 5 Important fixed, leftovers in D36/D37 | yes |
| M8-02 | 4 | smoke + check.sh output; tail of plan | 38/38 PASS both widths, check green; plan ends 'Ready to merge: yes' | yes |

### 2026-10-19 11:00 · M8-02 · passes

- Ran the `web-design-guidelines` pass (fresh `command.md`, Opus reviewer) over /card, /card/qr, /approach, /evidence and the three case studies. Two Opus reviews read `$HARNESS_SCRATCH/M8.diff`, the second after my fixes. Findings and outcomes are in the new `docs/plans/2026-10-18-M8-polish.md`, which ends "Ready to merge: yes". 0 Critical. 5 Important, all fixed:
  - root `viewport` with dark `colorScheme` and `themeColor` (light on /card/qr);
  - hit-list diagram muted sub-labels were 3.9:1, opacity removed;
  - `MetricStrip` read each label twice: now a visible `<dt>`, using `flex-col-reverse justify-end`;
  - that new layout first knocked metric values out of line (`justify-end` fixes it);
  - a reduced-motion hydration mismatch on the /projects filter bar.
- Minor fixes: `focusRing` on Navbar, Footer, skip link, back links, ProjectLinks and the CodeBlock `<pre>`. The ← is aria-hidden. Footer drops its aria-labels and gains sr-only "(opens in new tab)". Gallery videos use `LoopingVideo`. One `sortByOrder()` replaces three sorts. The sitemap tests are stricter, and a Navbar test covers `aria-current` on /approach. Left as defaults: D36 (robots disallow next to noindex) and D37 (curly quotes, `text-balance`, sitemap route walk).
- New `src/__tests__/pages/a11y-new-pages.test.tsx` covers the seven pages: one h1 and no skipped levels; a focus-visible class on every link and button, the chrome included; no vague link text; AA contrast read from `globals.css`; and every `<motion.*>` file calls `useReducedMotion`. Every fix had a test that failed first. Tests 562 → 611 (52 → 54 suites).
- The `project-page-unchanged` snapshots were updated on purpose: the classic pages gain the focus ring, the hidden arrow, the new MetricStrip markup and CodeBlock attributes. A word diff shows no text change.
- Verified: `lib/check.sh` green (lint, 611 jest, build), smoke 38/38 PASS. A Sonnet browser check of 8 pages at 390/1280 found 0 console errors and 0 overflow. 60 Tabs gave every stop a 2 px outline, starting with Skip to content. Metric values sit 21 px from the card top on every card (dd above dt), and reduced motion gives opacity 1 with 0 errors. I looked at the 390 metric strip and the hit-list "Before" panel.
- Next session: M8 is done. Questions for Michael (no answer needed): D36, keep `Disallow` for /evidence and /card/qr, or rely on noindex alone? Proposed changes: none.

### 2026-10-19 09:30 · M8-01 · passes

- Navbar: Approach sits between Projects and Experience, in the desktop list and the mobile menu (`src/components/Navbar.tsx`). `/projects` now sorts cards by `order` (`ProjectsGrid.tsx`). The filters already included Systems and Process, and case studies without a thumbnail already showed their first metric; both are now pinned by tests. New `src/app/sitemap.ts` (the 8 static routes plus 9 projects, built from `profile.siteUrl`, without `/evidence` and `/card/qr`) and `src/app/robots.ts` (disallows both, points to `/sitemap.xml`). The CLAUDE.md routes, components and test count are updated. Tests went from 552 to 562 (51 → 52 suites; new `src/__tests__/app/sitemap-robots.test.ts`). I wrote the tests first and watched them fail: 3 Navbar, 1 order, 1 missing module.
- Verified: on :7800, `curl sitemap.xml | grep -c '<loc>'` = 17 (needs ≥ 16), and robots.txt has `Disallow: /evidence` and `Disallow: /card/qr`. The build prerenders both as static files. Smoke 38/38 PASS. `lib/check.sh` is green. A Sonnet browser check found the seven links on one row at 768, 1024 and 1280 (rightmost edge at 744 of 768, 0 overflow), the mobile menu in the same order, Approach → /approach with aria-current, cards in order 1–9, and 0 console errors. I looked at the 768 nav and 390 menu screenshots.
- Next session (M8-02): the M8 diff is this commit (`git diff 9c3ac7e..HEAD`). At 768 the desktop nav has 24 px to spare, so adding another nav link would need a smaller gap.
- Questions for Michael: none. Proposed changes: none.

### 2026-10-19 verify M7

| Feature | Step | What you ran or read | What you saw | Holds |
|---|---|---|---|---|
| M7-01 | 1 | grep headings of docs/plans/2026-10-18-M7-approach-evidence.md | Principles (6 × 3 examples, 17 linked + 1 D14 unlinked), Approach page, Competencies (6), Evidence page, Tests, What Michael will see (4-row table), Review all present | yes |
| M7-01 | 2 | read plan § Filtered at render time | Table lists examples dropped per missing slug; states pages render with zero broken links | yes |
| M7-01 | 3 | git show --stat of plan commit (HEAD~1 now is a harness-only commit) | Plan commit 4c9cf32/ca14a4a touched plan, spec decisions (docs/) and .harness/runs only | yes |
| M7-01 | 4 | check.sh | green | yes |
| M7-02 | 1 | read src/lib/data/approach.ts; approach-links.test.ts (91 tests in 5 M7 suites pass) | six ids/titles in order; 1–3 examples; resolvedExamples uses resolveProjectLink, drops anchor without caseStudy (tests at :55,:85) | yes |
| M7-02 | 2 | loaded /approach 390+1280 in Playwright; read page.tsx | title 'Approach — Michael Herron', 2 intro sentences, MethodStrip 5 items, 6 h2s, closing link /projects/agent-harness | yes |
| M7-02 | 3 | read approach-links.test.ts + approach.test.tsx:107,117 | asserts anchors, five slugs, slug/caseStudy existence, missing slug renders without link | yes |
| M7-02 | 4 | approach.test.tsx:47,61,37 | six headings, five labels, every /projects/ href slug in projects | yes |
| M7-02 | 5 | smoke-routes.txt; node .harness/smoke.mjs; check.sh | /approach listed; smoke PASS both widths; check green | yes |
| M7-03 | 1 | read competencies.ts + competencies-links.test.ts:48-90 | six titles, 3/4/4/4/3/3 items, 7 MAXX items (all six sections), sources grepped in brand.md | yes |
| M7-03 | 2 | Playwright /evidence; page.tsx | h1 correct, reading + D7 notes, six h2s, robots=noindex, no Navbar link to /evidence | yes |
| M7-03 | 3 | competencies-links.test.ts:96-115 | hrefs checked vs allowed routes/anchors/repo roots; live hrefs are /experience, project slugs, github.com/mh550/portfolio_site | yes |
| M7-03 | 4 | cat docs/notes/maxx-level-4.md | Says where to paste rubric; remapping = competencies.ts only | yes |
| M7-03 | 5 | smoke-routes.txt + smoke run | /evidence listed, PASS at both widths; check green | yes |
| M7-04 | 1 | ls -la docs/screenshots/v2/M7-* | four files, 135/115/209/183 KB, all < 400 KB | yes |
| M7-04 | 2 | read plan table + live DOM | four rows; 17 links on approach (3·3·3·3·2·3), closing line; evidence 21 items, notes present | yes |
| M7-04 | 3 | Playwright goto every hashed link from /approach (11) and /evidence (8) | getElementById non-null for all 19; table lists 3 | yes |
| M7-04 | 4 | Playwright scrollWidth−innerWidth at 390 and 1280 | 0 on both pages, both widths | yes |
| M7-04 | 5 | check.sh | green | yes |
| M7-05 | 1 | read plan Review (Findings, Fact-check 39 rows) | findings with severity; fact-check per example and item | yes |
| M7-05 | 2 | read commit 51a1206; claims-on-linked-page.test.ts passes | fixes with tests; MethodStrip shared by hero and /approach | yes |
| M7-05 | 3 | read plan § Web interface guidelines | table covers heading order, link text, focus, reduced motion; focus test approach.test.tsx:133 passes | yes |
| M7-05 | 4 | tail plan; smoke; check.sh | ends 'Ready to merge: yes'; smoke all PASS; check green | yes |

### 2026-10-19 00:45 · M7-05 · passes

- Reviewed the M7 diff (`$HARNESS_SCRATCH/M7.diff`, 1735 lines) with two Opus reviewers, one for code and one for facts (39 claims traced). Result: 0 Critical, 7 Important (6 fixed, 1 accepted), 13 Minor (11 fixed, 2 left with a reason). The plan's Review section has the finding table, a fact-check row per example and item, a simplification note, the web-guidelines table, and ends "Ready to merge: yes". Tests 508 → 552 (50 → 51 suites).
- Copy fixes, each test first. New `claims-on-linked-page.test.ts`: every number in an example or item also appears on the page its link opens. That test caught "3 clients" (not on the ghl page, now removed) and "D-H1 to D-H24" (the page shows 6 entries; now "a numbered decision ledger"). Other fixes: the first download no longer reads as done, "Wrote the runbooks/specs" → "Designed", the ownership item → `#decide`, the reading note says "linked to the case study, role or repo it comes from", one long sentence split, ai-3 now active voice.
- Code: one `resolveProjectLink` in `projects.ts` (used by `resolvedExamples` and `resolvedItems`), shared `caseStudySectionHeadings`, shared `focusRing` (card, approach, evidence), `MethodStrip` gains a `label` prop (on `/approach` the strip is "The five steps", not a second "How I work"), short link names ("Agent Harness: Diagnose"), a hover state on the `/approach` links, and shared test helpers in `src/__tests__/helpers/projects.ts`.
- Verified: `.harness/check.sh` exits 0 (552 jest, build); smoke 38/38 PASS. A Sonnet browser check passed 7 of 7 at 390 and 1280: 0 errors, 0 overflow, 19/19 hashed links land, focus outline OK. I looked at both 390 shots. The `docs/screenshots/v2/M7-*.png` were re-captured after the copy changes.
- Question for Michael (low stakes; no answer needed to proceed): the MAXX "one spreadsheet per person / bottleneck" and Builder Clarity "for stakeholder visibility" details come from `apprentice-profile.md`, not brand.md's bank. They are kept because the linked pages already publish them. Add them to brand.md, or trim them?
- Proposed change: let `/evidence` link the harness PR list (`github.com/mh550/portfolio_site/pulls?q=is:pr+harness`, AH 99–100) instead of the bare repo root. M7-03's step allows only the four repo roots.

### 2026-10-19 01:15 · M7-04 · passes

- Four screenshots in `docs/screenshots/v2/`: `M7-approach-390.png` (191 KB, 390 × 5815), `M7-approach-1280.png` (213 KB), `M7-evidence-390.png` (111 KB), `M7-evidence-1280.png` (131 KB). All are full pages, so none needed the top-3000 crop. They were taken after scrolling back to the top, so the Navbar sits at the top. The M7 plan's "What Michael will see" table now has four rows and an anchor-landing table.
- Fixed one thing (test first): on `/evidence` at 390 the ↗ after "…that I review and merge" wrapped onto a line by itself. It now follows a no-break space (`src/app/evidence/page.tsx`); there is a new test in `evidence.test.tsx`. Tests 507 → 508 (50 suites).
- Verified: `$HARNESS_SCRATCH/m7-shots.mjs` on :7800 found 0 console errors, scrollWidth − innerWidth = 0 at 390 and 1280 on both pages, nothing in `<main>` below opacity 1, and no clipped text. 19 of 19 hashed links (11 from /approach, 8 from /evidence) returned 200 via `page.goto`, and `getElementById(hash)` found each one. Approach has 6 principles with 3·3·3·3·2·3 links (the D14 example is text only); evidence has 6 competencies with 3·4·4·4·3·3 items. I looked at every screenshot. Smoke on /approach and /evidence: 4/4 PASS. `.harness/check.sh` exits 0 (508 jest), and `lib/check.sh` is green.
- Next session (M7-05): the M7 diff now includes this arrow fix. I did not run a separate review; M7-05 is the review.
- Questions for Michael: none. Proposed changes: none.

### 2026-10-19 00:55 · M7-03 · passes

- `/evidence` is live on the branch (noindex, not in the Navbar). New `src/lib/data/competencies.ts`: `competencies` (6 × 3/4/4/4/3/3 = 21 items, with a MAXX Potential item in all 6), `evidenceIntro` and `resolvedItems` (mirrors `resolvedExamples`). The copy is the plan's word for word (65/65 strings, checked by script). New `src/app/evidence/page.tsx`: repo links open in a new tab with sr-only "(opens in a new tab)". New `docs/notes/maxx-level-4.md` (rubric stub; remapping = editing `competencies.ts` only). `/evidence` added to `smoke-routes.txt` and the CLAUDE.md routes table. Tests 485 → 507 (48 → 50 suites): `competencies-links.test.ts`, `evidence.test.tsx`, and a Navbar no-`/evidence` test.
- Verified: `.harness/check.sh` exits 0 (`evidence.html` prerendered); `lib/check.sh` green; `tsc --noEmit` 0; smoke 38/38 PASS. A Sonnet browser check on :7800 passed all 8 points at 390 and 1280: noindex meta, 6 h2s in order, 21 links (12 distinct), all 20 internal links return 200, all 9 hashes found by `getElementById`, scrollWidth 390, focus outline, 0 console errors. I looked at the 390 shot.
- Opus review: 0 Critical, 0 Important, 7 Minor. Fixed: an empty `ul` when every item drops out (test first), a wrong import-cycle comment, a test helper that shadowed `escape`, and the ↗ arrow rendering as an emoji (now U+FE0E). Left as is: no template-literal href type (the test catches typos), and the context label is not in the link's accessible name (it matches the plan's structure).
- For M7-05: the design item "…3 clients, onboarding from ~2 days to ~6 hours" links `/projects/ghl-jobtread-integration`. That page has the onboarding figure but not "3 clients" (brand.md line 47 and /experience have it). Rule on it there: add the figure to the ghl page or accept it as is. "One spreadsheet per person" was already accepted in M7-01.
- Next session (M7-04): the full-page screenshots in `$HARNESS_SCRATCH/browser-M7-03/` show the fixed Navbar mid-page because they were taken after scrolling. Take the M7 screenshots after scrolling back to the top, or crop them. Don't run `npx prettier`: the repo has no config, and its defaults rewrite to double quotes.
- Question for Michael: none new (D35 from M7-01 still stands). Proposed changes: none.

### 2026-10-19 00:30 · M7-02 · passes

- `/approach` is live on the branch. `approach.ts` gains `principles` (6 × 3 examples, copy pasted from the M7 plan, 24/24 strings verbatim by script), `approachIntro`, `approachClosing`, `resolvedExamples` (drops a missing slug, drops an anchor the project doesn't render) and `exampleHref`. New `src/app/approach/page.tsx` (static; link names `<project title>: <section>`; closing link → `/projects/agent-harness`, else `/projects`). `MethodStrip` gains `showLines`: lines visible at every width, steps stacked left-aligned below md with the arrows hidden there; the hero is unchanged. `/approach` is in `smoke-routes.txt`; CLAUDE.md routes updated. Tests 456 → 485 (46 → 48 suites).
- Verified: `.harness/check.sh` run directly exits 0 (lint, 485 jest, build; `approach.html` prerendered); `lib/check.sh` green; `tsc --noEmit` exits 0; smoke 36/36 PASS. A Sonnet browser check on :7800 found 6 h2s, 18 example links (13 distinct hrefs), all 200, with all 11 hashes found by `getElementById`, 0 overflow at 390, every section at opacity 1 after scrolling, 4 arrows hidden at 390 and shown at 1280, the hero strip unchanged, and 0 console errors. I looked at the 390 shot.
- Opus review: 0 Critical, 0 Important, 4 Minor, all fixed (test-first where testable). The fixes: an accent focus outline and a resting underline on the links; a page test for a principle whose examples all filter out; the `withoutProject` test helper throws on an unknown slug; and a comment on the `approach.ts` ↔ `projects.ts` import cycle, which is safe because both sides use the other only inside functions.
- Next session (M7-03): tests remove a project by splicing the real `projects` array and restoring it in `finally`. A `jest.mock` of `@/lib/data/projects` with `requireActual` would recurse through the cycle, so don't use it. Reuse the `FOCUS` link classes from `approach/page.tsx` for `/evidence`.
- Proposed change: none. (`/approach` gets its Navbar link in M8, per the plan.)

### 2026-10-19 00:40 · M7-01 · passes

- New `docs/plans/2026-10-18-M7-approach-evidence.md`: Principles (6 × 3 examples = 18, 17 linked + the D14 "chose not to build" text, every one with its brand/brief line and the case-study string it matches), Approach page (h1 "How I work", 2-sentence intro, `MethodStrip showLines` per D31, closing link to `/projects/agent-harness` else `/projects`), Competencies (6, items 3/4/4/4/3/3, a MAXX Potential item in all 6, each with a `source` phrase), Evidence page (header, reading note, D7 note, noindex), Tests, an empty 4-row What Michael will see, an empty Review. Spec gains **D34** (D14 example has no `projectSlug`) and **D35** (High Cascade coaching labelled Personal). No src/ change; tests 456 → 456.
- Verified: a script found all 21 competency `source` phrases in brand.md / the briefs / the spec with whitespace collapsed (one fixed: brand's `**4+**` bold breaks "sources into Postgres", now "into Postgres"). An Opus fact-check found 2 Critical, 7 Important, 3 Minor; all fixed except one: the "one spreadsheet per person" detail stays, because the linked `linear-ai-workflow` page states it. My MS/HL line numbers were off by 112/216 (I had counted them in a concatenated file); they're recomputed and spot-checked. `lib/check.sh` green; smoke 34/34 PASS at start.
- Next session (M7-02): all five slugs are on the branch, so nothing filters out today. The "Filtered at render time" table lists what drops if one is missing. MAXX items may only claim brand.md lines 43–46. Link names may repeat across principles (2a/6a and others) but then they share the href; the test asserts that rather than unique names.
- Question for Michael: D35 shows the snowboard coaching as a "Communicate and teach" item labelled Personal. Keep it or drop it?

### 2026-10-18 verify M2

All 27 steps re-run; 6 features hold, 0 fail. Live checks on :7800.

| Feature | Step | What you ran or read | What you saw | Holds |
|---|---|---|---|---|
| M2-01 | 1 | `grep -n "^#"` on docs/plans/2026-10-18-M2-positioning.md | All sections present: Metadata, Hero (+MethodStrip, 390 px layout, Motion), Recent work, Experience (+Traceability), About, Skills, Tests, What Michael will see (now filled by M2-05), Review (filled by M2-06, as intended later) | yes |
| M2-01 | 2 | Read plan lines 246-278 (traceability) and 455 | Traceability table maps each number to brand.md lines; "7+ → 4+" recorded (brand.md 42, 48) | yes |
| M2-01 | 3 | `git show --stat bb498b5` | Only docs/plans, docs/specs, .harness/runs files (4 files); no src/ | yes |
| M2-01 | 4 | `lib/check.sh` | green (6 tests, cached for this tree); same tree includes M2-01 | yes |
| M2-02 | 1 | Read src/app/layout.tsx; `jest layout-metadata.test.ts`; curl-style browser read of head on :7800 | metadata from profile; title "Michael Herron — Systems & Process Engineer", description = subline, metadataBase, og:site_name, og:image headshot all present live; 6 tests assert title, description, image path | yes |
| M2-02 | 2 | Browser read of / body at 390; `jest HeroSection.test.tsx` | Eyebrow SYSTEMS & PROCESS ENGINEER, name, tagline, subline, Diagnose→Decide→Build→Verify→Simplify with lines, buttons after; tests assert eyebrow, subline, five labels in order | yes |
| M2-02 | 3 | Browser read of /; `jest home.test.tsx`, `SiteChrome.test.tsx` | h2 "Recent work", h3 Agent Harness / Linear Adoption / music library in order, "See all projects" → /projects, 1 footer on /; tests assert order, href, footer on / (D19) | yes |
| M2-02 | 4 | Playwright 390×844 on :7800: boundingBox of "About Me"; `jest` min-h-svh test | About Me bottom = 701 ≤ 844; HeroSection test "grows with its content: min-h-svh"; measurement is in the plan | yes |
| M2-02 | 5 | `node .harness/smoke.mjs`; `lib/check.sh` | All routes PASS at 1280 and 390 incl. /; check green | yes |
| M2-03 | 1 | `jest experience.test.tsx` + browser read of /experience; grep "7+" experience.ts | Tests assert 2×, ~80%, de facto PM, FCP, DB migrations, 3 clients, ~2 days/~6 hours, ~8 hrs/week, 4+ sources, Agile/Scrum in Linear; page shows them; grep "7+" prints nothing | yes |
| M2-03 | 2 | Read experience.test.tsx "keeps the job titles exactly" and "High Cascade" tests; title diff 5b9e3ff..HEAD | Tests pass; titles unchanged (diff of title: lines empty); High Cascade bullet starts "Mentored 12–18-year-old snowboarders" | yes |
| M2-03 | 3 | grep -i gpa experience.ts + page.tsx; browser text /experience; "shows no GPA" test | No gpa field or text; live page has no "GPA"; test uses queryByText(/GPA/) null | yes |
| M2-03 | 4 | Browser read of /about; aboutIntro in approach.ts; `jest about.test.tsx` | Intro (3 sentences: subline, five steps, delivery) above story; copy in approach.ts; Duke/Colorado asserted; about description now "Duke CS grad…" without old positioning | yes |
| M2-03 | 5 | `lib/check.sh` | green | yes |
| M2-04 | 1 | Browser h2 list on /skills; `jest data.test.ts` (four groups, single featured, ≥4 each) | Process & delivery, Systems & architecture, Build, Operate & verify; 3 tests pass | yes |
| M2-04 | 2 | `jest data.test.ts` "keeps all 39 pre-M2 skills", "adds the new evidence-backed skills"; read test lines 118-120 | Both pass; Docker, restic, SQLite, Expo, Agent orchestration, Specs and decision ledgers present live | yes |
| M2-04 | 3 | `jest skills.test.tsx` (featured panel, other groups outside, spot-check TypeScript/Docker/Linear) | Passes; data.test.ts asserts 4 categories | yes |
| M2-04 | 4 | `lib/check.sh` | green | yes |
| M2-05 | 1 | `ls -la docs/screenshots/v2/M2-*` | All eight present, largest 182 KB (<400 KB) | yes |
| M2-05 | 2 | Playwright 390×844 of /; plan viewport paragraph; M2-home-390-viewport.png exists | Eyebrow, name, tagline, subline, five labels, both buttons stacked without overlap per text order; About Me bottom 701 recorded in plan | yes |
| M2-05 | 3 | Read plan "What Michael will see" table | 8 rows (home, about, skills, experience × 2 widths) with the required observations | yes |
| M2-05 | 4 | Read the "anything wrong" column; timeline fix commit 992ca84 | Issues fixed (timeline line) or listed with reasons | yes |
| M2-05 | 5 | `lib/check.sh` | green | yes |
| M2-06 | 1 | Read plan Review: findings, fact-check at 442, titles section | Findings table, 15-row fact-check, title grep stated; `git diff 5b9e3ff..HEAD -- experience.ts | grep title:` re-run by me prints nothing | yes |
| M2-06 | 2 | `grep -rn "Full-Stack & Integration Engineer" src`; read Review findings | prints nothing; Important findings listed fixed, tests 456 passing in suite | yes |
| M2-06 | 3 | Read plan "Web interface guidelines" section 464-474 | Section covers reduced motion, heading order, contrast of strip; fixes recorded | yes |
| M2-06 | 4 | Tail of plan; `node .harness/smoke.mjs`; `lib/check.sh` | Ends "Ready to merge: yes"; smoke all PASS; check green | yes |

### 2026-10-18 23:49 · M2-06 · passes

- Reviewed the M2 diff (`$HARNESS_SCRATCH/M2.diff`, 5b9e3ff..592c783) with Opus (code + fact-check), Opus (`web-design-guidelines` over /, /about, /skills, /experience) and Sonnet (browser on :7800). Findings: 0 Critical, 8 Important (all fixed), 15 Minor (6 fixed). The plan's Review has the 23-row table, a 15-row fact-check of `experience.ts` against brand.md, and ends with "Ready to merge: yes". The title grep and the `Full-Stack & Integration Engineer` grep both print nothing.
- Fixed test-first: `/card` inherits the root Open Graph block (og:site_name/type now in its unfurl); root twitter has no images; FloatingLogos don't scale on hover under reduced motion and are **hidden below 1280 px (D33 default)**; TimelineLine honours reduced motion; ScrollReveal margin `-80px 0px`; Navbar `aria-current`; "Skip to content" link + `#content` target in SiteChrome; new `LoopingVideo` on /about (44 px pause/play, no autoPlay attr, plays after hydration unless reduced, a blocked play shows "Play video"). Also: smooth scroll guarded + `data-scroll-behavior`, "Differentiator" 60 → 80 % (4.25:1 → passes), "curiousity" typo, the two `tsc --noEmit` errors (now exits 0).
- Tests 440 → 456 (45 → 46 suites). `lib/check.sh` green, and `.harness/check.sh` run directly exits 0. Smoke 34/34 PASS. Browser at 390: 0 logos visible at 390 and 768; under `reduce` every hero element is at opacity 1 at 100 ms and there are 0 rAF calls in 2 s (240 by default). The first Tab focuses the skip link and Enter focuses `#content`. The video plays by default and stays paused under `reduce`. I looked at the 390 hero and /about shots. An Opus review of my own diff found 1 Important (a blocked autoplay left the button saying "Pause"), fixed.
- Left for M8 (all from before M2): touch targets under 44 px (hamburger, menu, Footer links), the "Deep dive →" link names repeat, ProjectCard hover scale under reduced motion, an Experience "Work" heading, the headshot's `quality={100}` warning.
- Question for Michael: D33 hides the floating logos on phones and tablets (they sat behind the hero text). Keep that, or reposition them per breakpoint? Also: the MAXX bullets tell the Linear story twice (bullets 1 and 5). Merge them?
- Proposed change: add `npx tsc --noEmit` to `.harness/check.sh`. Jest strips types and `next build` skips test files, so type errors in tests passed the gate twice in M2.

### 2026-10-18 23:59 · M2-05 · passes

- Eight full-page shots in `docs/screenshots/v2/M2-{home,about,skills,experience}-{390,1280}.png` (51–182 KB, none cropped) plus `M2-home-390-viewport.png`. The plan's What Michael will see table has all 8 rows filled.
- Hero at 390×844 (Sonnet, Playwright :7800, default and reduced motion give the same numbers): eyebrow 159–179, h1 195–315, tagline 331–387, subline 403–475, strip 507–563, View Projects 595–639, **About Me 655–701**. No overlaps, nothing under the 65 px nav, opacity 1 throughout, no horizontal scroll, no console errors.
- **Fixed:** the /experience timeline line never appeared below 1280 px (already broken on `main`). `TimelineLine`'s `margin: '-60px'` insets the IntersectionObserver root on the left too, and the 1 px bar sits at x ≈ 30. Now `'-60px 0px'`; measured opacity 1 and 1795 px tall at 390, 768 and 1280, with and without reduced motion. The new `TimelineLine.test.tsx` failed first ("-60px"). Tests 439 → 440, suites 44 → 45.
- Listed but not changed (reasons are in the plan): on mobile the strip's arrow trails "Build →" at the end of row 1; FloatingLogos sit behind the hero text at 390 (still legible; for M2-06's contrast pass); the About Philosophy blockquote still says "architect automations and integrations" (the plan keeps Philosophy unchanged); a lone "it." on the Verify line at 1280.
- Verified: `lib/check.sh` green; jest 440/440; smoke 34/34 PASS. I looked at all eight shots. Opus review: 0 Critical, 0 Important. Applied: numeric margin comparison, one `resetModules`. Left for M2-06: `ScrollReveal`'s uniform `-80px` margin (harmless for its full-width blocks, but the same trap for a narrow one).
- Housekeeping for Michael: the shared stash stack has an entry `m205-tl-check` (b79e2bc) holding the same one-line TimelineLine change; this session wasn't permitted to drop it. `git stash drop` it when convenient. Questions: none. Proposed changes: none.

### 2026-10-18 23:55 · M2-04 · passes

- `skills.ts` is now four capability groups in plan order: `process` "Process & delivery" (featured, D20, 7), `systems` "Systems & architecture" (12), `build` "Build" (24), `operate` "Operate & verify" (8). That is 51 unique strings: all 39 pre-M2 skills plus 12 new ones, each with the evidence line the plan cites. `/skills` puts Process & delivery in the glow panel ("Differentiator" kept) and stacks the other three full width. The intro and metadata now describe grouping by capability. Chips are now `ul role="list"`/`li`, each list named by its h2 (`aria-labelledby`). The stale `h-full` is gone.
- Tests 435 → 439 (44 suites), in `data.test.ts` (ids and names in order, only `process` featured, ≥ 4 each, the hard-coded 39 plus all 12 new strings, no duplicates) and `skills.test.tsx` (four h2s, featured panel via `closest('div.glow-accent')`, TypeScript/Docker/Linear inside their own group's list, each list's items equal the data, intro and metadata). Every behaviour test failed first. The ≥ 4 / 39-kept / no-duplicate guards already held before the change.
- Verified: `lib/check.sh` green; smoke 34/34 PASS. A Playwright check at 390 and 1280: four h2s in order at opacity 1, only Process & delivery in `.glow-accent`, the lower cards one column (x 24 w 342 at 390; x 152 w 976 at 1280), scrollWidth = clientWidth, no console errors. I looked at the 390 shots: chips wrap cleanly with no list bullets. Note for M2-05: the smoke full-page shot leaves the lower groups blank because ScrollReveal only animates them on scroll. Scroll first; `/tmp/harness/portfolio_site/v2-2026-10-18/skills-check.mjs` does.
- Opus review: 0 Critical, 0 Important, 6 Minor. Applied: all 12 new strings asserted, the group-membership spot-checks, ul/li, `h-full` removed. Left: querying the panel by its CSS class (the plan specifies it) and the metadata literal test.
- CLAUDE.md: skills.ts line and test count updated. Next: M2-05 (all its prerequisites now pass). Questions for Michael: none. Proposed changes: none.

### 2026-10-18 23:30 · M2-03 · passes

- `experience.ts`: the 6 MAXX and 4 Builder Clarity bullets now match the plan word for word (2×, ~80%, de facto PM, Foundational Capability Patterns, git-tracked DB migrations; 3 clients, ~2 days → ~6 hours, ~8 hrs/week, **4+ sources**, Agile/Scrum in Linear). "Pioneered" and "7+" are gone, High Cascade reads "Mentored 12–18-year-old snowboarders" (D9), and `gpa` is removed from `Education` and from the page (D8). Titles, companies and periods are unchanged. The Experience metadata now reads from `profile.name`.
- `approach.ts` exports `aboutIntro` (D32): the subline, the five steps and "I own delivery from requirements to release." `/about` renders it as one `<p>` under the h1, before the story. The About metadata drops "full-stack and integration engineer".
- Tests 420 → 435 (44 suites), in experience, about, approach and data tests. All 14 new behaviour tests failed first ("Colorado" was a spot check and already passed). `lib/check.sh` green; smoke PASS for /about and /experience at both widths (all routes). I looked at both 390 shots: the intro sits above the headshot float, which is intact.
- Opus review of the diff: 0 Critical, 0 Important, 2 Minor (two tests hold by construction; kept because the plan specifies them). It also found that `tsc --noEmit` now reports 2 errors from before this session, in test files: `HeroSection.test.tsx:122` and `case-study-home-media-server.test.ts:38`. `next build` doesn't flag them. Left for M2-06.
- Note for M2-05: the about test logs a `next/image` warning (headshot `quality={100}` isn't in `images.qualities`), from before this session. Smoke ignores it.
- Next: M2-04 (independent). Questions for Michael: none. Proposed changes: none.

### 2026-10-18 23:05 · M2-02 · passes

- Root metadata from `profile` (title "Michael Herron — Systems & Process Engineer", description = subline, Open Graph with siteName and headshot, no title/url; twitter summary). New `MethodStrip` (`ol role="list"` named "How I work", D23/D31). The hero reads eyebrow, tagline and subline from `profile`, adds the strip, uses `min-h-svh pt-24 pb-16` instead of `h-screen`, and honours reduced motion (instant variants with the same hidden state, still FloatingLogos, NodeGraph draws one frame and redraws on resize, no rAF loop). `/` gains Recent work (`getTopProjects(3)`, `ProjectCard headingAs="h3"`, "See all projects"), and the Footer shows on `/` (D19).
- Tests 392 → 420, suites 40 → 44 (new: layout-metadata, MethodStrip, NodeGraph, home). Every new behaviour test failed first. `.harness/check.sh` run directly exits 0; `lib/check.sh` green; smoke 34/34 PASS, `/` PASS at 1280 and 390.
- Measured (Sonnet, Playwright :7800): About Me ends at **701 ≤ 844** at 390×844 and at 666 at 375×667, where the hero grows to 746. No overlaps, scroll diff 0, reduced-motion opacity 1 at 100 ms. The table is in the plan under "390 px layout and the fold". I looked at the 390 shot.
- Opus review of the diff: 0 Critical, 0 Important, 5 Minor. Fixed: `role="list"` on the strip, and a test that the reduced-motion hidden state equals the fade-up one (hydration). Left for M2-06: (1) `/card`'s own openGraph replaces the root block, so the card unfurl lacks og:site_name/type; (2) the root `twitter.images` would mask a future per-page og:image (drop `images`, let Next derive it); (3) FloatingLogos `whileHover` still scales 1.5× under reduced motion. Also for M2-05: below 768 the labels wrap after "Build →", so one arrow trails at the line end.
- Note: `npx tsc --noEmit` reports one error from before this session, in `case-study-home-media-server.test.ts:38` (`extraDiagrams` on a narrowed type). `next build` doesn't flag it.
- Next: M2-03 and M2-04 are independent. Questions for Michael: none. Proposed changes: none.

### 2026-10-18 22:55 · M2-01 · passes

- New `docs/plans/2026-10-18-M2-positioning.md` (plan only, no code). Sections: Files, Metadata (root `metadata` from `profile`; Open Graph carries siteName + headshot but no title/url, so project pages unfurl with their own titles), Hero (eyebrow/tagline/subline from `profile`, `MethodStrip` created by M2-02 per D23, `h-screen` → `min-h-svh`, reduced motion for the fade-ups, FloatingLogos and NodeGraph), Recent work (`getTopProjects(3)`, `ProjectCard headingAs="h3"`, "See all projects", Footer on `/` per D19), Experience (MAXX and Builder Clarity bullets word for word with brand.md lines, `7+` → `4+`, GPA removal, D9 bullet, a traceability table), About (3-sentence intro), Skills (4 groups, 51 strings; a table shows all 39 current skills survive; Process & delivery featured), Tests (per-feature table), an empty 8-row What Michael will see table, an empty Review.
- New defaults in the spec: **D31** (below 768 px the hero strip shows only the labels; the lines appear from md up and screen readers get them at every width, so both buttons stay above a 390×844 fold), **D32** (`aboutIntro` lives in `approach.ts`, because make-qr imports profile.ts under Node type stripping).
- Measured today's hero (Sonnet, Playwright on :7800): at 390×844 the hero is `h-screen` and About Me ends at 619 px; it ends at 545 at 375×667 and at 533 at 1280×800. The planned layout should put About Me near 720 at 390×844, and M2-02 measures the real value.
- An Opus review of the plan found 7 Important and 10 Minor issues, checked and applied. The root Open Graph block would have retitled every project page. The planned reduced-motion test (resetModules + require) would crash on NodeGraph's hooks. NodeGraph would have stayed blank under reduced motion. The card title is not a link (assert "Deep dive"). MAXX "Pioneered … testing" overclaimed (project_descriptions.md 13–25), so it is rewritten. The 12–18 age range comes from D9, not brand.md, and the plan now says so.
- Not added: the skill "Monitoring", because the media-server heartbeat is built but not installed. The site will show "AGILE/Scrum" as a chip next to "Agile/Scrum in Linear" in a bullet; M2-04's hard-coded list forces that.
- Verified: `lib/check.sh` green (392 tests, unchanged); smoke 34/34 PASS at session start; the commit touches only `docs/` and `.harness/runs/`.
- Next: M2-02, M2-03 and M2-04 are independent. Questions for Michael: none. Proposed changes: none.

### 2026-10-18 verify M6

| Feature | Step | What you ran or read | What you saw | Holds |
|---|---|---|---|---|
| M6-01 | 1 | Read plan (502 lines) § entry/metrics/caseStudy; compared with data dump | Plan has all fields, 3 metrics, 6 iterations, lessons, repo link, builtWith; data matches | yes |
| M6-01 | 2 | Read plan `## Traceability` (l.331) | Table maps numbers/dates/ids to brief lines or HL files | yes |
| M6-01 | 3 | Read plan `## Diagrams` (l.192-300) | Nodes for hit-list and form-simplification incl. 5-step scale, aria-label and caption | yes |
| M6-01 | 4 | grep plan 'none will be faked' (l.152); `git show --stat aaa1f93`; docs/asset-checklist.md HitList section | States no screenshots; checklist entries present; commit touches only docs/ and .harness/runs/ | yes |
| M6-01 | 5 | lib/check.sh | green | yes |
| M6-02 | 1 | jest dump of getProjectBySlug('hit-list') | company, categories, order 4, featured, githubUrl exact; metrics 374 / 20+ → 7 / SDK 54 → 57 | yes |
| M6-02 | 2 | Same dump + data shape | method object with 5 strings (type), ids D1 D2 D3 D12 D21 D22, 6 iterations, last has 'specified' + 'not yet built', 5 lessons incl. 7679.1 mi, flexGrow, crypto.getRandomValues, 1 link exact href, builtWith | yes |
| M6-02 | 3 | Dump + `ls public/projects`; case-study-hit-list.test.ts l.86 | media undefined, no demoUrl, no public/projects/hit-list; test asserts it | yes |
| M6-02 | 4 | case-study-hit-list.test.ts l.100-110; `npx jest case-study-hit-list data.test` | Digit-run and decision-id vs brief asserted; data count 9; 141 tests pass | yes |
| M6-02 | 5 | Read docs/asset-checklist.md HitList section | Lists List, Map, Quick Add, detail shots or 15 s recording | yes |
| M6-02 | 6 | lib/check.sh | green | yes |
| M6-03 | 1 | ProjectDiagram.test.tsx KEYS includes both; jest run | DiagramKey, LABELS/CAPTIONS render; tests pass | yes |
| M6-03 | 2 | ProjectDiagram.test.tsx l.142-250; browser text at /projects/hit-list | Words, role=img, labels asserted; scale 'None · Little · Some · Enough · Too much' in order; 7 fields | yes |
| M6-03 | 3 | Data dump + browser computed grid columns | architectureDiagram hit-list, extraDiagrams [form-simplification]; 390: 1 column (300px), 1280: 2 (327px each) | yes |
| M6-03 | 4 | `node .harness/smoke.mjs` | PASS /projects/hit-list at 1280 and 390 (all routes pass) | yes |
| M6-03 | 5 | lib/check.sh | green | yes |
| M6-04 | 1 | `ls -la`, `file` on docs/screenshots/v2/M6-* | 393 KB and 336 KB (<400 KB), full pages 1280x7165, 390x11516 | yes |
| M6-04 | 2 | Read plan 'What Michael will see' (l.317) | Lists metrics, diagram, method, decisions, iterations, form before/after, lessons, single link, no gallery | yes |
| M6-04 | 3 | Playwright at 390 and 1280 | scrollWidth−innerWidth=0 both; scale text intact; plan table states 0 | yes |
| M6-04 | 4 | Read table 'Anything wrong' column | Fixes or reasons listed | yes |
| M6-04 | 5 | lib/check.sh | green | yes |
| M6-05 | 1 | Read plan ## Review (l.401-502) | Findings with severity, 28-row fact table, 'specified, not yet built' sentence present | yes |
| M6-05 | 2 | Read Review; ProjectDiagram M6-05 tests; progress entry | Fixes with tests; web-design-guidelines run recorded | yes |
| M6-05 | 3 | tail of plan; smoke; lib/check.sh | Ends 'Ready to merge: yes'; smoke and check green | yes |

### 2026-10-18 23:55 · M6-05 · passes

- Review of M6 from `$HARNESS_SCRATCH/M6.diff` (`aaa1f93~1..6de6479`, 1,189 lines): Opus on the code, Opus on facts and voice against the brief and the HitList files, Sonnet on the guidelines in a browser. Each finding was checked against the cited lines before acting. The plan's `## Review` has a 28-row fact table, a privacy pass and 16 findings (4 Important, 12 Minor), and ends "Ready to merge: yes".
- Important, fixed test-first: (1) `simplify` and metric 2 said "I cut … Stars became" for a spec that isn't built; they now say "I wrote a spec that cuts …" and "specified Oct 16 … not yet built". (2) "every removed field archived" is false (the Oct 16 spec, line 291: `status` is not archived) → "the old details are archived". (3) The Feb sprints did not build "every screen" (no map view) → "but the map". (4) At 375 px the selected step "Enough" ran past its 42 px cell; with `-mx-2`, `gap-0.5` and no cell padding it fits from 360 up (cells 44/47/50/55 px). It still overflows at 320, which is recorded.
- Minor, fixed: "Michael" removed from the copy, "Every feature and fix" instead of "Every change", the geocoder cap is for backfills only, saves go DB-first in the aria-label, "saved as a draft" instead of the spec's "tags", notes credited as a default. Simplification: an explicit `scale: true` field, one `SPEED_EXAMPLE`, `Sub` takes `className` (snapshots byte-identical), a guarded `speedField()`, and `toBe('20+ → 7')`. The plan copy, a brief Corrections entry and the CLAUDE.md count are updated. Screenshots re-taken (328/384 KB).
- Tests 377 → 392 (40 suites, 6 snapshots unchanged). Every new behaviour test failed first.
- Verified: `.harness/check.sh` run directly exits 0 (lint, 392 tests, build); `lib/check.sh` green; smoke 34/34 PASS. The `web-design-guidelines` rules were fetched fresh and applied to the page (Sonnet) and to `diagrams/index.tsx` (me). I looked at the 390 px architecture diagram and the 375 px scale myself.
- Next: M6 is ready for its verify session. Recorded for the site-wide accessibility pass: link focus ring is the browser default.
- Questions for Michael: none. Proposed changes: none beyond the site-wide accessibility and typography feature already proposed in M5-05.

### 2026-10-18 23:20 · M6-04 · passes

- New `docs/screenshots/v2/M6-hit-list-390.png` (334 KB, 390 × 11425) and `M6-hit-list-1280.png` (382 KB, 1280 × 7165), both full pages as palette PNGs (script `$HARNESS_SCRATCH/m6-shots.mjs`). The plan's "What Michael will see" table in `docs/plans/2026-10-18-M6-hit-list.md` describes both, row by row.
- Fixed (M6-03 flagged it): at 1280 the Before panel stretched to the After panel's height, leaving an empty box. The form grid in `diagrams/index.tsx` now has `md:items-start`, like the other diagrams. New test in `ProjectDiagram.test.tsx`; it failed first. Tests 376 → 377 (40 suites).
- Verified from the DOM at both widths: scrollWidth − innerWidth = 0; no console errors; the metric values `374` / `20+ → 7` / `SDK 54 → 57` each sit on one line (1 column at 390, one row of 3 at 1280, so SDK 54 → 57 fits a third-width card); 6/6 decisions read "Chose … over … because"; the timeline ends with the Oct 16 "Simplification spec" (specified, not yet built); 7 After fields; the scale steps are 45 px (390) and 50 px (1280) wide, with scrollWidth = clientWidth and no ellipsis, and "Too much" wraps to two lines; 0 `img` in `<main>`; one link, to the repo root. I looked at all 8 + 4 slices and the re-shot form crop.
- `lib/check.sh` green; `npx jest` 377/377; smoke exit 0, including `/projects/hit-list` PASS at 1280 and 390.
- Left as is, with reasons in the table: the DecisionLog chip/title wrap (shared layout) and the wrapping letter-spaced panel titles.
- Next (M6-05): review the M6 diff. Questions for Michael: none. Proposed changes: none.

### 2026-10-18 22:50 · M6-03 · passes

- `src/components/projects/diagrams/index.tsx` gains `HitListDiagram` (3 panels: On the phone · Expo Go / Needs a signal / Capture now, details later) and `FormSimplificationDiagram` (Before · 20+ fields in five sections / After · 7 fields, specified Oct 16, an `<ol>` of 7 with the speed scale None · Little · Some · Enough · Too much as plain divs, Enough selected), plus `CAPTIONS`/`LABELS` copied from the M6 plan. `DiagramKey` gains both keys; the hit-list entry sets `detail.architectureDiagram: 'hit-list'` and `caseStudy.extraDiagrams: ['form-simplification']`.
- Tests 342 → 376 (40 suites): ProjectDiagram.test.tsx (both keys added to the role=img and unique-label checks, the words, 7 `li`, the scale order and selection, no truncate or nowrap, no buttons or radios, grid-cols-1 md:grid-cols-2, banned strings), ProjectDetail.test.tsx (positions), case-study-hit-list.test.ts (data wiring). Each failed first (34 + 1 red).
- Verified: `lib/check.sh` green; `npx jest` 376/376; `node .harness/smoke.mjs` 34/34 PASS, including `/projects/hit-list` at 1280 and 390. Sonnet browser check, after scrolling so the reveals fire: scrollWidth − innerWidth = 0 at 390 and 1280. At 390 the form panels are stacked (both x=45); at 1280 they sit side by side (both y=4544). The scale steps are 45 px wide at 390 and none overflows. The architecture diagram sits between The Problem and The Method, the form diagram between How It Evolved and What Broke, with no console errors. I looked at the element shots: "Too much" wraps onto two lines at both widths, which the plan allows.
- Next (M6-04): at 1280 the Before panel stretches to the After panel's height (grid default), which leaves some empty space under Status. It's harmless, but `md:items-start` would remove it if it looks off in the full-page shot.
- Questions for Michael: none. Proposed changes: none.

### 2026-10-18 22:20 · M6-02 · passes

- `src/lib/data/projects.ts` gains the `hit-list` entry right after home-media-server (order 4, `full-stack` + `process`, 3 metrics 374 · 20+ → 7 · SDK 54 → 57, D16 detail, caseStudy with 5 method texts, D1 D2 D3 D12 D21 D22, 6 iterations, 5 lessons, one repo-root link, builtWith). The copy is pasted from `docs/plans/2026-10-18-M6-hit-list.md` as written: a script found all 80 quoted plan strings verbatim in the data. No media, no thumbnail, no demoUrl, no `public/projects/hit-list/`.
- New `docs/asset-checklist.md` with the HitList section: 4 phone shots or a 15 s recording, privacy rules, the destination and the `media` entry shape. New `src/__tests__/lib/case-study-hit-list.test.ts` (13 tests: header, metrics, method, ids, iterations, lessons, link, builtWith, no media, checklist, digit runs and ids found in the brief, privacy, "specified, not yet built"). `data.test.ts` now expects 9 projects with `'hit-list': 4` (getTopProjects(3) unchanged, so /card is unchanged). `case-study-types` expects process = [agent-harness, hit-list]. `ProjectsGrid` gains Process and Full-Stack filter tests.
- Tests 326 → 342 (39 → 40 suites). Each new test failed first. `.harness/check.sh` run directly: exit 0 (lint, 342 tests, 6 snapshots, build). `lib/check.sh`: green. Smoke: 34/34 PASS, including `/projects/hit-list` at 1280 and 390.
- At 390, a Sonnet browser check scrolled the page so the reveals fire. It found scrollWidth − innerWidth = 0, the h2s Problem → Method → Decisions → Evolved → Broke → Outcome → Links, 0 images in main, one GitHub link (the repo root), and no console errors. I looked at the decision and lesson shots myself.
- Next (M6-03): add the `hit-list` and `form-simplification` DiagramKeys and diagrams, then set `detail.architectureDiagram` and `caseStudy.extraDiagrams` (left unset here). When real shots are added, replace the "no media" test, as the checklist says.
- Note: Prettier already reports `projects.ts` as unformatted at HEAD. It is not part of the suite, so I didn't reformat it.
- Questions for Michael: none. Proposed changes: none.

### 2026-10-18 · M6-01 · passes

- New `docs/plans/2026-10-18-M6-hit-list.md`: the hit-list entry field by field (order 4, 3 metrics 374 · 20+ → 7 · SDK 54 → 57), five method texts, decisions D1 D2 D3 D12 D21 D22 (HitList's own ledger ids) as chose/over/because/cost with a grammar check, 6 iterations (Feb 12–14 → Oct 16, the last saying "specified, not yet built"), 5 lessons, one repo-root link, builtWith, D16 summaries; a 39-row Traceability table (brief lines and HL `OVERNIGHT.md`/spec/README lines); the `hit-list` and `form-simplification` node lists with the five-step scale drawn, aria-labels and captions; the asset-checklist section M6-02 creates (no media, none faked); the tests M6-02/03 write.
- `docs/notes/evidence-hit-list.md` gains `## Corrections`: the Edit data loss was found while planning, not in review; the loop ran Oct 14 00:03 → Oct 15 00:51; the crash was Oct 15; the "What Michael will see" table predated the 7679.1 mi bug.
- Verified: an Opus fact-check against the brief and the HL files (6 Important, 9 Minor, all applied and re-checked against the cited lines). Among them: "took it to my phone" overclaimed (the README says the first phone run was next), the outcome's 374/crash ordering, the verify claims narrowed (real SQLite only for DB code from M3 on; tables only on screen milestones), D21/D26 credited as defaults, D3/D12 comma grammar, and privacy in the asset checklist (towns in untitled labels). `.harness/check.sh` run directly: green (lint, 39 suites / 326 tests, 6 snapshots, build); `lib/check.sh` green. Tests 326 → 326 (plan only). Smoke 32/32 PASS at start.
- Next (M6-02): paste the copy as written, place the entry after home-media-server, create `docs/asset-checklist.md`. `getTopProjects(3)` and `/card` don't change. M6-04 must check that "SDK 54 → 57" fits a third-width metric card at 1280.
- Note: at the start I ran read-only `git log/status/branch` in `~/projects/hit_list` (a breach of "no git in other checkouts"; nothing changed). After that I used only cat/grep.
- Questions for Michael: none. Proposed changes: none.

### 2026-10-18 verify M5

All 26 steps re-run; no feature flipped.

| Feature | Step | What you ran or read | What you saw | Holds |
|---|---|---|---|---|
| M5-01 | 1 | Read `docs/plans/2026-10-18-M5-home-media-server.md` (entry table, metrics, detail, caseStudy sections); grep of the caseStudy part | All fields match (slug, title, company, categories, order 3, featured, githubUrl, techStack, 4 metrics 831/1,405/1,359/Trash not delete); D7 D3 D24 D27 D18 D38/39 present; '859 = 859 = 859' and 'guessed fake' present; repo link, builtWith, outcome/problem/approach/challenges summaries (detail D16) present | yes |
| M5-01 | 2 | Read '## Traceability' table (rows 831, 22 GB, 1,405, 1,359 …) and its source column | Each row cites a brief line, a named DJ docs file at origin/main 8d99309, or the AH ledger | yes |
| M5-01 | 3 | Read '## Terminal excerpt'; ran `git -C dj-crate-streaming show origin/main:docs/download-validation.md` and diffed by eye against the plan block | Source lines 60–65 identical except `/srv/incoming/…` → `incoming/…`; no hostname/IP/token/username | yes |
| M5-01 | 4 | Read '## Media' and '## Diagram' sections | Three files named with 'Demo data' captions; m6-*.png stated never used; nodes Phone→Private network (HTTPS)→Navidrome→crates service→Worker→Library, nightly snapshot + backup, aria-label and caption given | yes |
| M5-01 | 5 | `grep -c Soulseek` on plan copy; `git show --stat 1c1d89e` | Copy names it once ('Soulseek' once in projects.ts); the commit touches docs/ (plan, spec, evidence note) and .harness/runs/ only | yes |
| M5-01 | 6 | `/home/mh550/projects/agent-harness/lib/check.sh` | green (cached for this tree) | yes |
| M5-02 | 1 | Temp jest dump of `getProjectBySlug('home-media-server')` (removed after) | company 'Personal · home server', categories [systems, full-stack], order 3, featured true, githubUrl correct, 4 metrics with 831, 1,405, 1,359, 'reversible' in the label | yes |
| M5-02 | 2 | Same dump | 5 method strings, decision ids [D7,D3,D24,D27,D18,D38/39], 5 iterations, 7 lessons incl. '859 = 859 = 859' and 'guessed fake' in `broke`, one repo link, builtWith set | yes |
| M5-02 | 3 | `cmp` of the 3 PNGs vs dj-crate-streaming/docs/screenshots; `ls -l`; dump of detail.media; ran case-study-home-media-server.test.ts | Byte-identical; 59,407 / 90,401 / 107,924 B (<120 KB); captions contain 'Demo data'; no m6* file; test passes | yes |
| M5-02 | 4 | Dump of codeSnippets; `grep -rn 'ts.net\|100\.\|/srv\|ntfy\|m6-'` on data, diagrams, public | One snippet language 'text', title has 'verify', code has 'cutoff ≈16 kHz' and 'BAD', no '/srv'; grep returns nothing (exit 1); entry test passes | yes |
| M5-02 | 5 | Ran jest on case-study-home-media-server, data.test.ts (8 projects, order, getTopProjects) + dump | 5 suites / 103 tests pass; 8 projects; getTopProjects(3) = agent-harness, linear-ai-workflow, home-media-server | yes |
| M5-02 | 6 | `lib/check.sh` + full smoke | green; 32 smoke PASS lines, no FAIL | yes |
| M5-03 | 1 | Read diagrams/index.tsx lines 346/358/379; ProjectDiagram.test.tsx passes | 'media-server' in DIAGRAMS, CAPTIONS, LABELS (DiagramKey covered by the all-keys test) | yes |
| M5-03 | 2 | Ran ProjectDiagram.test.tsx (media-server words, role=img, aria-label, banned strings) | Passes; plan lists words Phone, HTTPS, Navidrome, crates service, Worker, verify, beets, Library, snapshot, backup; browser shows role=img with aria-label | yes |
| M5-03 | 3 | Dump `architectureDiagram`; ProjectDetail.test.tsx line 78; h2 order in browser | 'media-server'; test asserts diagram after The Problem, before The Method; passes | yes |
| M5-03 | 4 | `node .harness/smoke.mjs` | PASS /projects/home-media-server @1280 and @390 | yes |
| M5-03 | 5 | `lib/check.sh` | green | yes |
| M5-04 | 1 | `ls -l docs/screenshots/v2` | M5-home-media-server-390.png 399,139 B, -1280.png 301,133 B, both under 400 KB; plan table says full page | yes |
| M5-04 | 2 | Read plan '## What Michael will see'; headless chromium check of page text | Table covers metric strip, diagram, method, decisions, iterations, lessons, 3 shots with demo-data captions, verify block, repo link; page has BAD, 'cutoff ≈16 kHz' and 3 'demo data' | yes |
| M5-04 | 3 | Headless chromium at 390: scrollWidth−innerWidth; pre; image lefts | 0; pre scrollWidth 1193 > clientWidth 340, overflow-x auto; three images share left=25 (one column); table states 0 | yes |
| M5-04 | 4 | Read table 'Anything wrong' column; ran MetricStrip.test.tsx | Fix for 2×2 strip recorded, other items listed with reasons; tests pass | yes |
| M5-04 | 5 | `lib/check.sh` | green | yes |
| M5-05 | 1 | Read plan '### M5-05' Review: fact table, findings table | 34-row fact table, 13 findings with severity (1 Important, 12 Minor); diff recorded as 1c1d89e~1..039ebde | yes |
| M5-05 | 2 | Privacy grep from the step; `grep -o Soulseek projects.ts`; read Review privacy pass | grep exit 1 (no output); Soulseek once in the data | yes |
| M5-05 | 3 | Read findings 1 and 13; ran the touched tests (MediaGallery, MetricStrip, ProjectDiagram, entry test) | Important finding fixed with test; web-design-guidelines run recorded (alt, figcaption, heading order checked; rest logged as site-wide); tests pass | yes |
| M5-05 | 4 | `grep -n 'Ready to merge'`; smoke; check.sh | Line 455 'Ready to merge: yes'; smoke all PASS; check green | yes |

### 2026-10-18 23:59 · M5-05 · passes

- Review of M5 from `$HARNESS_SCRATCH/M5.diff` (`1c1d89e~1..039ebde`, 1,241 lines): Opus on the code, Opus on facts and voice against the brief and the DJ docs, Sonnet on the guidelines in a browser. The plan's `## Review` has a 34-row fact table, a privacy pass and 13 findings (1 Important, 12 Minor), and ends "Ready to merge: yes".
- Important, fixed test-first: lesson 7, the diagram and its aria-label presented the lock-protected nightly backup and its heartbeat as live. DJ `docs/backup-plan.md` lines 59–61 say the pre-H2 job, with no lock, stays installed until Michael runs the install. The page now says "built and waits for my install" / "(install pending)", and the brief has a `## Corrections` entry.
- Minor, fixed: dropped "since Oct 14" (no doc confirms that run), "backups confirmed" became "nightly backup job already running", and D24 "built and used" became "built and tested". In `MediaGallery`, a sized video no longer turns on the 3-column grid, the two wrappers are merged into one, and `sizes` dropped to 240/384 px. Test hygiene: the 7/8 boundary in `MetricStrip`, a "7 projects" test name, a dead ternary, an unguarded `match()!`, a shadowed `it`, and a test that the aria-label names all 13 components.
- Tests 309 → 326 (39 suites). Every new behaviour test failed first. `project-page-unchanged` passes, and all 6 snapshots are untouched.
- Verified: `.harness/check.sh` is green (lint, 326 tests, build), and `lib/check.sh` is green. Smoke: 32/32 PASS. The privacy grep returns nothing (exit 1), and "Soulseek" appears once. I looked at the diagram at 390 myself (scroll difference 0). I ran the `web-design-guidelines` skill with the rules fetched fresh.
- Recorded for a site-wide accessibility pass (each changes the pinned snapshot or the layout): `focus-visible` on links, 44 px touch targets for the back links, a skip link, an explicit `tabIndex` on the `<pre>` scroller, and curly quotes.
- Questions for Michael: none. Proposed changes: a site-wide accessibility and typography feature (the items above, plus M4-05 findings 11–12).

### 2026-10-18 23:35 · M5-04 · passes

- Screenshots: `docs/screenshots/v2/M5-home-media-server-390.png` (390 KB, 390 × 13561) and `-1280.png` (294 KB, 1280 × 7615). Both are full pages, captured with `reducedMotion: 'reduce'` as palette PNGs via sharp; the 1280 one uses 128 colours to stay under 400 KB. No top-3000 crop was needed. The plan has a new "What Michael will see" table, one row per shot (script: `$HARNESS_SCRATCH/m5-shots.mjs`).
- Fixed what I found: at 1280 the four-up `MetricStrip` wrapped "Trash, not delete" onto 3 lines and stretched every card. A four-metric strip now stays 2 × 2 when any value is longer than 7 characters ("≈ $2.53" is the longest that fits a quarter card), so agent-harness keeps its single row. Tests 307 → 309 (39 suites): 2 in `MetricStrip.test.tsx`, and I watched the 2 × 2 one fail first. `project-page-unchanged` passes untouched.
- Verified in my DOM pass and again by an independent Sonnet browser check. At 390: scrollWidth − innerWidth = 0; `pre` 1193 > 340 with `overflow-x: auto`, showing BAD and "cutoff ≈16 kHz"; the gallery is 1 column, uncropped (2.05), and every caption says "Demo data"; metrics are 1 column. At 1280: metrics 2 × 2 with every value on one line, and the gallery is 1 row of 3. No console errors; 0 hidden elements; "Soulseek" appears once in the visible text. `.harness/check.sh` run directly is green (lint, 309 tests, 6 snapshots, build). Smoke: 32/32 PASS before and after.
- Left as is, with the reasons in the table: (1) `DecisionLog` puts short titles beside the id chip and wraps long ones below it at 390 (the shared layout, the same on the GHL and agent-harness pages). (2) `03-wanted.png`'s own UI text says "Soulseek", which M5-01 accepted and D11 forbids editing.
- Next (M5-05): the review diff should include `MetricStrip.tsx` (the 2 × 2 rule). The M4 screenshots are still accurate: agent-harness's strip doesn't change.
- Questions for Michael: none. Proposed changes: none.

### 2026-10-18 23:05 · M5-03 · passes

- `DiagramKey` gains `'media-server'`; `MediaServerDiagram` in `src/components/projects/diagrams/index.tsx` uses only Node/Sub/Arrow/Panel. It has three panels (Listening · Home server · Docker Compose · Every night), stacked at 390 and side by side, top-aligned, from md. Its entries in `DIAGRAMS`/`CAPTIONS`/`LABELS` are the plan's copy, verbatim. The home-media-server entry sets `detail.architectureDiagram: 'media-server'`.
- Tests 288 → 307 (39 suites). ProjectDiagram: the new key joins the D17 a11y `it.each`; 10 word tests; banned `.ts.net`/`100.`/`/srv`/`http://` checked in the text, label and caption; no download-source name; 3 stacked panels. ProjectDetail: on the real entry, the diagram (found by its caption) sits after The Problem and before #method. case-study-home-media-server: the entry's diagram key.
- Verified: `.harness/check.sh` run directly is green (lint, 307 tests, 6 snapshots, build). Smoke: 32/32 PASS at the start and after the change; `/projects/home-media-server` PASS at 1280 and 390. A Sonnet browser check (reduced motion) passed: panels stacked at 390 and in one row at 1280, scroll diff 0, no node overflow, no console errors. I looked at both diagram shots myself.
- Opus review: no Critical or Important findings, 2 Minor, both applied. The test's figure lookup now uses the caption, because a gallery caption also says "Navidrome". The label said "everything is backed up", but the brief says only "backup to a separate disk", so it now reads "an encrypted backup goes to a second disk; the heartbeat is green only when that backup is fresh". The plan was updated to match.
- Next session (M5-04): capture with `reducedMotion: 'reduce'`. An element screenshot at 390 puts the fixed navbar over the top of the diagram, so scroll it below the nav or take a full-page shot. At 1280 the long arrow labels wrap, left-aligned. I tried a `text-center` on `Arrow`'s label, but it changes the pinned classic-page snapshots, so I reverted it. Fixing it means updating those snapshots on purpose.
- Questions for Michael: none. Proposed changes: none.

### 2026-10-18 22:40 · M5-02 · passes

- New entry `home-media-server` in `src/lib/data/projects.ts` (order 3, after linear-ai-workflow), pasted from the M5 plan as written: 4 metrics (831 · 1,405 · 1,359 · "Trash, not delete"), 5 method texts, decisions D7/D3/D24/D27/D18/D38/39, 5 iterations, 7 lessons, 1 repo link, builtWith. The verify excerpt was taken from the DJ file's bytes (lines 60–65) with the one `/srv/incoming/` → `incoming/` swap. Three demo PNGs copied to `public/projects/home-media-server/` (59/90/108 KB, `cmp` identical). D29 is built: `ProjectMedia.width/height`; `MediaGallery` shows sized images uncropped, and an all-portrait list uses `sm:grid-cols-3`; unsized items render as before.
- Tests 265 → 288 (37 → 39 suites): new `case-study-home-media-server.test.ts` (fields, media under public/, no `m6*`, byte-identical media and excerpt vs the DJ checkout with `it.skip` when it is absent, `DJ_CRATE_DIR`; banned strings; Soulseek exactly once; digit runs and ids vs the brief) and `MediaGallery.test.tsx`; updated data (8 projects, top 3), case-study-types (systems), ProjectsGrid (Systems filter). `card.test.tsx` and `project-page-unchanged` pass untouched; /card now lists home-media-server third.
- Verified: `.harness/check.sh` run directly is green (lint, 288 tests, build); smoke 32/32 PASS. Sonnet browser check with reduced motion: 0 errors, 0 opacity-0, scroll diff 0 at 390. The `<pre>` scrolls inside itself (1193 vs 340 px). 3 images loaded, ratio 2.05 (uncropped), one column at 390 and one row at 1280, every figcaption says "Demo data". I looked at the gallery shot myself.
- Next session (M5-03): add `'media-server'` to `DiagramKey`/`LABELS`/`CAPTIONS` and set `detail.architectureDiagram` on this entry (left unset here). The smoke's full-page screenshots are blank below the fold (ScrollReveal waits for in-view): M5-04 must capture with `reducedMotion: 'reduce'`, as M4-04 did.
- Note: the brief writes "D38 / D39", so the id test expands `D38/39` into D38 and D39 and checks each.
- Questions for Michael: none. Proposed changes: `lib/check.sh` printed "green … 6 tests" for a suite that runs 288 (its test-count parse looks wrong; the direct run shows 288).

### 2026-10-18 22:10 · M5-01 · passes

- New `docs/plans/2026-10-18-M5-home-media-server.md`: the full entry field by field (4 metrics, 5 method texts, decisions D7/D3/D24/D27/D18/D38/39 with chose/over/because/cost, 5 iterations, 7 lessons incl. "859 = 859 = 859" and "A guessed fake", 1 repo link, builtWith), a 42-row Traceability table, the verify excerpt, Media (3 demo shots, captions, alt text; m6-*.png never used), the `media-server` diagram's nodes/aria-label/caption, the tests M5-02/03 write, a brand check. Docs only: tests 265 → 265.
- Verified: the excerpt is byte-identical (`cmp`) to DJ `docs/download-validation.md` lines 60–65 at origin/main `8d99309` after the one `/srv/incoming/` → `incoming/` swap; copy strings contain "Soulseek" once and none of `.ts.net`, `100.`, `/srv`, `ntfy`, `m6-`, `http://`; all 3 captions say "demo data". An Opus fact-check found 3 Important (overclaimed "Nothing deleted", 46 vs 45 playlists, "deduplicated") + 13 Minor + 4 wrong line citations: all applied. check.sh green; smoke 30/30 PASS at start.
- New defaults in the spec: **D29** (the shots are 840 × 1720 portrait; `MediaGallery`'s 4:3 `object-cover` would show their empty middles, so `ProjectMedia` gains optional `width`/`height`, uncropped, `sm:grid-cols-3` when all are portrait; M5-02 builds it) and **D30** (metric 4 reads "Trash, not delete" / "code never deletes a library file; every removal is a reversible move", refining D18). Brief corrected: 45 playlists → 10, not 46 (`## Corrections`).
- Next session (M5-02): the source repo's local `main` is 103 commits behind; read with `git -C … show origin/main:<path>`. As of Oct 17 the download path never ran live; the copy says so (D7 cost, outcome). Avoid "1,100." at a sentence end (the `100.` ban).
- Questions for Michael: none. Proposed changes: M5-02 step 1 / M5-01 step 1 say metric 4 is "nothing deleted"; per D30 it is "Trash, not delete" (the M5-02 test only checks `reversible`, which still holds).

### 2026-10-18 verify M4

| Feature | Step | What you ran or read | What you saw | Holds |
|---|---|---|---|---|
| M4-01 | 1 | Read plan sections: entry table, metrics, caseStudy method/decisions/iterations/lessons/links/builtWith, detail | All fields present: slug, title, company, 4 metrics, 5 methods, 6 decision ids, 6 iterations, 5 lessons, 2 links, builtWith, approach/challenges one-liners | yes |
| M4-01 | 2 | Read `## Traceability` table | ~35 rows each mapping a number/date to a brief line or AH file; none cite journal/raw | yes |
| M4-01 | 3 | Read `## Code excerpt` | lib/driver.sh lines 170–182 (13 lines) verbatim, title stated | yes |
| M4-01 | 4 | Read `## Diagrams` | agent-harness nodes/arrows incl. INBOX, notifications, limit marker; harness-evolution 6 stages with aria-label, caption, grid-cols-1 md:grid-cols-6 stacking | yes |
| M4-01 | 5 | Read `## Brand check`; `git show --stat` of a6b769a (M4-01 commit) | Brand table all yes; commit touched only docs/ and .harness/ paths (5 files) | yes |
| M4-01 | 6 | `check.sh` (agent-harness lib/check.sh) | green | yes |
| M4-02 | 1 | `npx jest case-study-agent-harness.test.ts` 'header fields' + '4 metrics' tests, read assertions | 18/18 pass; asserts title, company, categories, order 1, featured, githubUrl, metric values contain 55/52/374/2.53 | yes |
| M4-02 | 2 | Same test file: method, decisions ids, iterations, lessons, links, builtWith tests | Assertions match step (5 methods, exact ids, 6 iterations Sep/Oct, 5 lessons, link label+href, 'Claude Code agents' + 'I designed the process') | yes |
| M4-02 | 3 | Same file: snippet test; `itWithSource` verbatim test | 1 snippet ≤25 lines, title lib/driver.sh; verbatim test ran (✓, not skipped) with agent-harness present; uses it.skip when absent | yes |
| M4-02 | 4 | Same file: traceability tests | digit runs [55,52,374,2.53] and decision ids matched in brief; bans .ts.net, ntfy, journal/raw | yes |
| M4-02 | 5 | `data.test.ts` (toHaveLength(7), getTopProjects) ; `curl localhost:7800/projects/agent-harness` | data tests pass; HTTP 200; h2s: The Problem, The Method, Key Decisions, How It Evolved, What Broke, Outcome, In the Code, Links (DecisionLog heading 'Key Decisions') | yes |
| M4-02 | 6 | check.sh | green incl. content-guard | yes |
| M4-03 | 1 | Read projects.ts DiagramKey and diagrams/index.tsx | DiagramKey includes both keys; components in index.tsx using Node/Panel primitives, no new files/deps | yes |
| M4-03 | 2 | Read index.tsx:327-352 `LABELS: Record<DiagramKey,string>`, `role="img" aria-label={LABELS[diagram]}`; ProjectDiagram.test.tsx | it.each over all 7 keys asserts one role=img, non-empty aria-label, figcaption outside; passes | yes |
| M4-03 | 3 | projects.ts entry; diagrams/index.tsx:283; evolution test | architectureDiagram 'agent-harness', extraDiagrams ['harness-evolution']; `grid grid-cols-1 md:grid-cols-6`; test checks six stages in order with when+short | yes |
| M4-03 | 4 | ProjectDiagram.test.tsx architecture words test | it.each CLI, driver, initializer, session, suite, verify, PR, main, INBOX; pass | yes |
| M4-03 | 5 | `node .harness/smoke.mjs` | PASS /projects/agent-harness @1280 and @390 (all routes pass) | yes |
| M4-03 | 6 | check.sh | green | yes |
| M4-04 | 1 | `ls -l` + PNG header dims of docs/screenshots/v2/M4-* | 4 files exist: 361 KB, 311 KB, 163 KB, 37 KB, all <400 KB; full-page sizes (390×11285 etc.) | yes |
| M4-04 | 2 | Read plan `## What Michael will see` | One row per screenshot; 390 row states single-column metrics, stacked evolution, code scrolls inside itself (scrollWidth diff 0), 'Chose … over … because'; 390 page cross-checked: smoke reports no horizontal scroll | yes |
| M4-04 | 3 | Viewed M4-card-390.png; curl /card | Selected work first item is 'Agent Harness: overnight software delivery with verification gates' | yes |
| M4-04 | 4 | Read 'Anything wrong' column | Issues found were fixed (metric strip 2×2, panel top-align) or listed with reason | yes |
| M4-04 | 5 | check.sh | green | yes |
| M4-05 | 1 | Read plan `### M4-05` Review | Findings with severity (5 Important, 8 Minor); 38-row fact table; excerpt re-diffed identical; (M4.diff is in scratch, not re-inspected) | yes |
| M4-05 | 2 | Read Voice section + builtWith; test 'spent'/'attempted' | builtWith credits Claude Code agents; overclaims rewritten; tests pin them (pass) | yes |
| M4-05 | 3 | Read findings table, jest runs of the new tests (case-study-agent-harness, ProjectDiagram) | Important 1–5 fixed with tests; Iteration.short in data, not component; tests pass. ScrollReveal test not re-run individually but full check green | yes |
| M4-05 | 4 | Read 'Web Interface Guidelines' paragraph | Heading order, link text, reduced motion checked on /projects/agent-harness; reduced-motion fixed; rest recorded | yes |
| M4-05 | 5 | grep 'Ready to merge'; smoke; check.sh | 'Ready to merge: yes' at plan line 418; smoke all PASS; check green | yes |

All 28 steps hold.

### 2026-10-18 21:20 · M4-05 · passes

- Review of M4 (`$HARNESS_SCRATCH/M4.diff`, 1,075 lines). Three agents reviewed it: Opus on code, Opus on facts and voice, Sonnet on the web guidelines in a browser. I checked every finding myself. 5 Important and 8 Minor; the plan's Review section has the 38-row fact table and ends "Ready to merge: yes".
- Important, fixed test-first: (1) **site-wide reduced motion hid content.** `ScrollReveal` swapped to a plain div, so the server's inline `opacity:0` stayed (15 blocks on this page, 8 on /about, plus a hydration error). It is now the same `motion.div`, revealed with `duration: 0`. (2) Lesson 5 claimed `after` lists fix blocking (by default every feature still waits on all earlier ones). (3) "71 features attempted" → "planned" (14 never ran); correction added to the brief. (4) The diagram's short lines moved from a component array into `Iteration.short`, and the aria-label is built from the data. (5) The excerpt test now `it.skip`s when the repo is absent and reads its path from `AGENT_HARNESS_DIR`.
- Minor copy fixes: "spent" → "counted as failed attempts", "On one project, verify sessions took 29–40 s", past tense in iterations 2–3, builtWith "ran each night and reviewed its results", challenges "each broke something". The plan copy was updated to match. Excerpt re-diffed against `a586f59` and the working copy: identical.
- Tests 261 → 265 (37 suites). check.sh green; smoke 30/30 PASS. With Playwright `reducedMotion: 'reduce'` at 390: 0 elements at opacity 0 and 0 console errors on /projects/agent-harness, /about and /. Looked at the evolution diagram at 390 and 1280 (unchanged).
- Recorded, not fixed (they change the pinned classic snapshot or are site-wide): the MetricStrip `<p>` inside the `dl` reads the label twice, and 2-metric pages leave an empty third column; no explicit `focus-visible` styles; MediaGallery autoplay video has no pause control or reduced-motion check.
- Questions for Michael: none. Proposed changes: a small site-wide a11y feature for the three recorded items (MetricStrip `dt`, focus-visible, video pause); it would update the `project-page-unchanged` snapshot on purpose.

### 2026-10-18 20:45 · M4-04 · passes

- Screenshots: `docs/screenshots/v2/M4-agent-harness-390.png` (303 KB), `-1280` (353 KB), `M4-projects-390` (159 KB), `M4-card-390` (36 KB). All are full pages saved as palette PNGs via sharp (already in node_modules through Next). No top-3000 crop was needed. The plan's "What Michael will see" table has one row per screenshot.
- Fixed two things I found: (1) at 1280 the 4th metric (≈ $2.53) sat alone under a row of 3. `MetricStrip` with 4 metrics is now `sm:grid-cols-2 md:grid-cols-4` with `text-balance` labels; 3-metric pages are unchanged. (2) The "Around it" panel was stretched to "One run"'s height and was mostly empty, so the agent-harness diagram now uses `md:items-start`. Tests 257 → 261 (36 → 37 suites): new `MetricStrip.test.tsx` (3), plus 1 in `ProjectDiagram.test.tsx` (I watched it fail on the old class). `project-page-unchanged` passes untouched.
- Verified in the DOM (my script `$HARNESS_SCRATCH/m4-shots.mjs`, then again by an independent Sonnet browser check). At 390: metrics in 1 column, each value on one line; evolution 6 rows; `pre` 1288 > 340 with overflow-x auto; page scrollWidth − innerWidth = 0; all 6 decisions read "Chose … over … because". At 1280: metrics 1 row of 4, evolution 1 row. /projects first card and /card's first Selected work item are both agent-harness. 0 console errors. Smoke 30/30 PASS; check.sh green.
- Left as is, with the reason in the table: the "Around it" sub-label "…every run waits on it" leaves "it" alone on a line at 390. Fixing it means changing the shared `Sub` primitive, which the pinned classic pages also render.
- Next (M4-05): review the diff from M4-01 on; this session's code diff is small (MetricStrip, one diagram class).
- Questions for Michael: none. Proposed changes: none.

### 2026-10-18 20:25 · M4-03 · passes

- `src/components/projects/diagrams/index.tsx`: `AgentHarnessDiagram` (panels "One run" and "Around it", stacked at 390, side by side from `md`) and
  `HarnessEvolutionDiagram` (`ol grid grid-cols-1 md:grid-cols-6`, reads `when`/`label` from the entry's iterations, plus the exported
  `HARNESS_EVOLUTION_WHY` (six lines of 8 words or fewer); ↓ arrows below `md` only). Nodes, captions and aria-labels are copied word for word from the M4-01 plan § Diagrams.
  `DiagramKey` gains both keys. The entry sets `architectureDiagram: 'agent-harness'` and `extraDiagrams: ['harness-evolution']`.
- Tests 242 → 257 (36 suites): ProjectDiagram.test iterates all 7 keys (one role=img, a non-empty aria-label, a figcaption outside it, every label distinct), checks the 9
  architecture words (CLI/PR/INBOX case-sensitive) and the six stages in order with their when and why lines, the why array's length = iterations' length, and the grid classes;
  case-study-agent-harness checks the two diagram fields.
- Verified: check.sh green; full smoke has 0 non-PASS lines; `smoke … /projects/agent-harness` PASS at 1280 and 390. Sonnet in a browser: at 390 both diagrams stack, scrollWidth − innerWidth = 0;
  at 1280 the six cards sit in one row at y = 4780, each 102 px wide. Fixed the one overflow it found: "Orchestrator" was 91 px in an 88 px card; now `md:px-1.5` and a 13 px label from `md`, and an in-browser probe finds no overflow.
  Opus review: 0 Critical/Important; both Minor fixed (a non-null data read instead of a silent empty diagram, and the why array is now readonly). I looked at evo-390, evo-1280 and arch-390 in $HARNESS_SCRATCH.
- Note on step 2: `role="img"` + aria-label sit on the figure's inner div, not the `<figure>` itself, so the figcaption stays visible outside the image (D17, set in M3). This meets the step's intent; the step's wording says "on its figure".
- Next (M4-04): screenshots. The architecture diagram is tall at 390 (about 1,400 px across both panels). At 1280 the evolution cards wrap to 2–3 lines; this is legible.
- Questions for Michael: none. Proposed changes: reword M4-03 step 2 to "inside its figure" (D17).

### 2026-10-18 20:20 · M4-02 · passes

- `src/lib/data/projects.ts`: the agent-harness entry, first in the array (order 1, featured), copy pasted from the M4-01 plan
  (a script confirmed all plan copy strings are in it verbatim); the excerpt is `lib/driver.sh` 170–182 read from the file at
  agent-harness `a586f59` (as `String.raw`, no `${`/backtick/backslash in it). `detail.architectureDiagram` and `extraDiagrams` are
  **not** set: the DiagramKeys don't exist yet, M4-03 adds both.
- Tests 228 → 242 (34 → 36 suites): new `case-study-agent-harness.test.ts` (13: fields, 4 metrics, method, decision ids, 6 iterations,
  5 lessons, links, builtWith, excerpt ≤ 25 lines + verbatim in the live file (ran, not skipped), digit runs 55/52/374/2.53 and ids in the
  brief, no `.ts.net`/ntfy/journal/raw); data.test 6 → 7, top-3 = agent-harness/linear/ghl; case-study-types: systems/process =
  [agent-harness]; ProjectsGrid Systems shows the card, empty state moved to new `ProjectsGrid.empty.test.tsx` (mocked empty list).
- Verified: check.sh green (fresh run); `/projects/agent-harness` 200 with h2s Problem…Key Decisions…Links; smoke 30/30 PASS; Sonnet
  at 390: all sections in order, scrollWidth − innerWidth 0, the four metric values one line each, code block scrolls inside itself.
- Next (M4-04): the smoke full-page screenshot is blank below the metric strip (ScrollReveal never fires in a full-page capture):
  scroll the page before capturing (the Sonnet script is in $HARNESS_SCRATCH/shot.mjs).
- Questions for Michael: none. Proposed changes (harness): check.sh's test counter prints "6 tests" for this suite (jest --silent); real count 242.

### 2026-10-18 20:09 · M4-01 · passes

- New `docs/plans/2026-10-18-M4-agent-harness.md`: final copy field by field (entry, 4 metrics, 5 method texts, D-H1/2/4/5/11/17,
  6 iterations (D27 resolved: row 1b folded into row 1, matching the six diagram stages), 5 lessons, 2 links, builtWith),
  Traceability table (every number → brief line or agent-harness file, ledger sums rechecked), code excerpt
  `lib/driver.sh` 170–182 (13 lines, diffed byte-for-byte against the source), both diagrams' nodes/labels/captions, brand check,
  and the tests M4-02/M4-03 must write or update (data.test 6→7, top-3 becomes agent-harness/linear/ghl, case-study-types, ProjectsGrid Systems empty state).
- Opus fact-check of the copy: 2 Important fixed (Oct 17 was "the first harness v2 night" finishing on v3, not "the first v3 night";
  lesson 5 had presented "block only on declared dependencies" as built, `lib/features.mjs` shows it is still proposed) + 3 Minor.
  Corrected the brief's Numbers heading (`docs/notes/evidence-agent-harness.md`, note under `## Corrections`; line numbers unchanged).
- Tests 228 → 228 (plan only); check.sh green; smoke all PASS.
- Next (M4-02): paste the copy as written; copy the excerpt from the file, not the plan. The verbatim test will break whenever
  driver.sh changes: re-copy, don't loosen it.
- Questions for Michael: none. Proposed changes: none.

### 2026-10-18 · verify M3

| Feature | Step | What you ran or read | What you saw | Holds |
|---|---|---|---|---|
| M3-01 | 1 | Read docs/plans/2026-10-18-M3-case-study-template.md headings | Has Types (spec interfaces + extraDiagrams, D17), Components, Page order, Testing (fixture, ProjectDetail, ghl unchanged proof), What Michael will see (table), Review (now filled by M3-05) | yes |
| M3-01 | 2 | Read plan Files table and Testing section | Lists fixture, ProjectDetail, case-study component tests, ProjectsGrid, snapshot test; ProjectsGrid test exists and was updated | yes |
| M3-01 | 3 | `git show --stat c3056df` | Only docs/plans/ and .harness/runs/ files touched | yes |
| M3-01 | 4 | check.sh; `npx jest --silent`, `tsc --noEmit`, eslint; `node .harness/smoke.mjs` | check green; 228/228 tests, 34 suites; tsc ok; eslint clean; smoke no non-PASS lines | yes |
| M3-02 | 1 | Read projects.ts diff vs c3056df; `npx tsc --noEmit` | Decision/Iteration/Lesson/ProjectLink/CaseStudy match spec + extraDiagrams; Project.caseStudy?; categories include systems, process; tsc passes; diff is additions only (no project entry changed) | yes |
| M3-02 | 2 | Read ProjectsGrid.tsx FILTERS and ProjectsGrid.test.tsx lines 21-38 | FILTERS All, Integration, Full-Stack, AI, Systems, Process; test asserts that order, Systems click shows 'No projects in this category yet.' | yes |
| M3-02 | 3 | Read src/__tests__/lib/case-study-types.test.ts | Full-caseStudy fixture and no-caseStudy literal, @ts-expect-error checks (tsc ok); jest passes | yes |
| M3-02 | 4 | check.sh / jest / tsc / eslint | green, 228 pass | yes |
| M3-03 | 1 | Read MethodSteps.test.tsx tests; ls case-study dir | 'ordered list with the five step ids in order' and 'label above the project's text' tests pass | yes |
| M3-03 | 2 | Read DecisionLog.test.tsx | Tests: #decisions section, every field, omits over/cost when absent, null on empty | yes |
| M3-03 | 3 | Read IterationTimeline.test.tsx and LessonList.test.tsx | Both assert section ids, row/pair content in order, empty (and undefined for iterations) renders nothing | yes |
| M3-03 | 4 | Read ProjectLinks.tsx and ProjectLinks.test.tsx | it.each over repo/live/doc/demo checks label, aria-hidden glyph, target=_blank rel; internal '/' uses next/link without target; text glyphs, no new dependency | yes |
| M3-03 | 5 | `grep -l 'use client' case-study/*`; eslint | No matches; eslint clean | yes |
| M3-04 | 1 | git diff of src/app/projects/[slug]/page.tsx; read ProjectDetail.tsx usage | page.tsx shrank by 144 lines to slug resolve + notFound + ProjectDetail; ProjectDetail takes {project} | yes |
| M3-04 | 2 | Read ProjectDetail.test.tsx order tests (lines 25-135) | Tests assert header, Problem, diagram, method, decisions, iterations, extraDiagrams, lessons, Outcome, code/media, links, builtWith order; no approach/challenges | yes |
| M3-04 | 3 | Read ProjectDetail.test.tsx lines 1-60 | h2 order, ids diagnose..simplify/decisions/iterations/lessons, builtWith, absence of 'The Approach' and 'Challenges' asserted; passes | yes |
| M3-04 | 4 | Read ProjectDetail.test.tsx lines 145-160 | ghl h2s equal ['The Problem','The Approach','Challenges','Outcome','In the Code']; no case-study ids; project-page-unchanged snapshots (6) pass | yes |
| M3-04 | 5 | Read project-metadata.test.ts | Asserts title 'GoHighLevel ↔ JobTread Integration — Michael Herron' and description = shortDescription; passes | yes |
| M3-04 | 6 | `node .harness/smoke.mjs`; check.sh | All routes incl. every /projects/<slug> PASS at 1280 and 390; check green | yes |
| M3-05 | 1 | ls /tmp/harness/.../M3.diff; read plan ## Review | M3.diff exists (29 KB); Review table has 7 Minor, 0 Critical/Important, all fixed | yes |
| M3-05 | 2 | ls -la docs/screenshots/v2/M3-*; read 'What Michael will see' | 390 = 286 KB, 1280 = 318 KB (<400 KB); table describes contents and 'nothing added or missing' | yes |
| M3-05 | 3 | Read ProjectLinks.tsx, CaseStudySection usage, plan Review | Shared CaseStudySection and DiagramReveal; vercel-react-best-practices consulted (plan line 247) | yes |
| M3-05 | 4 | Read plan Components section; grep CLAUDE.md | Components marked updated to shipped props; CLAUDE.md names case-study/ and ProjectDetail | yes |
| M3-05 | 5 | check.sh, jest, smoke | green; 228 pass; smoke all PASS | yes |

### 2026-10-18 23:59 · M3-05 · passes

- Review of `git diff 78010ea..HEAD -- src ':!src/__tests__'` ($HARNESS_SCRATCH/M3.diff, Opus): 0 Critical/Important, 7 Minor, all
  fixed test-first. Problem/Outcome are `CaseStudySection`s (#problem, #outcome, now in `getCaseStudyAnchors`), shared
  `sectionHeadingClass` + `DiagramReveal`, ProjectLinks keeps `#…`/`mailto:`/`tel:` in the tab, IterationTimeline index key, new
  `src/__tests__/lib/case-study-data.test.ts` (githubUrl/demoUrl must be in caseStudy.links, href shapes, unique decision ids).
  219 → 228 tests (34 suites). Findings table + vercel-react-best-practices notes under the plan's `## Review`.
- Verified: the classic-page snapshot passed untouched after the refactor; I checked that the a4fcd74 snapshot minus the
  role="img" wrapper equals the pre-a4fcd74 one byte for byte. `docs/screenshots/v2/M3-ghl-jobtread-integration-{390,1280}.png`
  (286/318 KB, scrolled so 0 elements below opacity 1; I looked at both). check.sh green, tsc clean, smoke 28/28.
- Next (M4–M6): author data against the plan's `## Components` (rewritten to match the shipped props, plus authoring rules:
  `because`/lessons carry their own full stops, the template adds no punctuation). A new DiagramKey needs DIAGRAMS, CAPTIONS, LABELS.
  CLAUDE.md Architecture now names ProjectDetail and case-study/.
- Proposed changes: still open from M3-04: the reduced-motion hydration bug in `ScrollReveal` (body invisible for
  reduced-motion visitors) deserves its own feature before launch.
- Questions for Michael: none.

### 2026-10-18 23:45 · M3-04 · passes

- New `src/components/projects/ProjectDetail.tsx` (server) holds the page body; `page.tsx` only resolves slug → `notFound()` or
  `<ProjectDetail>` (metadata/params byte-identical). Case-study mode follows the plan's 13 steps (D16/D17), no header
  GitHub/Live links. `getCaseStudyAnchors()` in projects.ts gates sections (no empty `space-y` gaps). D17: `ProjectDiagram`
  wraps the diagram in `role="img"` + a per-key `LABELS` record. 189 → 219 tests (5 new suites).
- Verified: `project-page-unchanged` snapshot of the 6 pages written *before* the refactor, passed untouched after it (sha
  match). It was then updated once, deliberately, for D17: a script showed the only diff is 5 `role="img"` wrappers (cherished
  has no diagram). Fixture exposed temporarily on dev, then reverted. Sonnet screenshots at 390/1280: h2 order right, all
  10 ids, no h-scroll. Opus review: 0 Critical/Important, 4 Minor fixed (index key on extraDiagrams, Live Demo assert,
  distinct labels, figure lookup). check.sh green (219), smoke 28/28.
- Next (M3-05): screenshots need scrolling or the reveals stay at opacity 0 (smoke's full-page shots are blank below the
  metrics). Fold into the plan: the case-study role line is `-mt-4 mb-6` between description and chips.
- Proposed changes: (1) pre-existing bug: with `prefers-reduced-motion: reduce`, `ScrollReveal` renders a plain div on the
  client but SSR emits the `motion.div` with `opacity:0`, so React logs a hydration mismatch and **the page body stays
  invisible**. Probably every page, for every reduced-motion visitor. Worth a small feature (e.g. always render `motion.div`
  and set `initial={false}` when reduced). (2) The harness's check summary says "6 tests"; the real count is 219 (it reads
  the snapshot line).
- Questions for Michael: none.

### 2026-10-18 23:10 · M3-03 · passes

- New `src/components/projects/case-study/`: `CaseStudySection` (shared section + h2, `aria-labelledby`, `scroll-mt-24`),
  `MethodSteps` (#method, `<li id>` diagnose…simplify, label as h3), `DecisionLog` (#decisions), `IterationTimeline`
  (#iterations), `LessonList` (#lessons), `ProjectLinks` (#links). All server components, null on empty. 161 → 189 tests
  (6 new suites in `src/__tests__/components/case-study/`).
- Verified: tests red (module not found) then green; Opus review of the diff found 2 Important (`//host` and `/\host`
  hrefs counted as internal; the test couldn't catch it), fixed test-first, plus Minor fixes (index keys, U+FE0E on ●/▶ for
  iOS, the lesson arrow turns down on mobile, label/text spaces, method label as h3, stricter order/exact-text asserts).
  ESLint + `tsc --noEmit` clean; no `"use client"`; check.sh green (189); smoke 28/28 PASS. No page mounts these yet, so there are no screenshots.
- Next (M3-04): mount them in `ProjectDetail` in the plan's order. Write the snapshot test before touching page.tsx.
  Differences from the plan's Components table, for M3-05 to fold in: internal = `/^\/(?![/\\])/`, not `startsWith('/')`;
  MethodSteps labels are `<h3>` with an aria-hidden `01`…`05` prefix.
- Questions for Michael: none. Proposed changes: none.

### 2026-10-18 22:45 · M3-02 · passes

- `projects.ts` exports `Decision`, `Iteration`, `Lesson`, `ProjectLink`, `CaseStudy` (spec fields + `extraDiagrams?:
  DiagramKey[]`, D17) and `Project.caseStudy?`; `ProjectCategory` gains `systems`, `process`; no project entry changed.
  `ProjectsGrid` FILTERS gain Systems, Process after AI. 154 → 161 tests.
- New: `src/__tests__/fixtures/case-study-project.ts` (`fixtureProject`, full caseStudy per the M3 plan, not in
  `projects`) and `src/__tests__/lib/case-study-types.test.ts` (fixture + minimal literal, 7 `@ts-expect-error` lines
  that make `tsc` fail if the types loosen, systems/process → []). ProjectsGrid test: six filters in order, Systems → empty state.
- Verified: tests red then green; `npx tsc --noEmit` failed before the types (TS2305/TS2578), passes after; check.sh
  green (161); smoke 28/28 PASS; /projects at 390: filters wrap to two rows, no horizontal scroll.
- Next (M3-03): import `fixtureProject` for component tests. Note: the "systems returns []" assertion must change
  when M4–M6 add a systems/process project.
- Questions for Michael: none. Proposed changes: none.

### 2026-10-18 22:20 · M3-01 · passes

- Wrote docs/plans/2026-10-18-M3-case-study-template.md (plan only, no code; 154 → 154 tests): Types (spec verbatim +
  `extraDiagrams`, D17), Components (props, anchors, empty cases, one shared `CaseStudySection`), Page order (13 steps,
  D16/D17), Testing (fixture in `src/__tests__/fixtures/`, test files to create/update), empty WMWS and Review.
- Verified: plan has all six required sections; check.sh green (154); smoke all routes PASS at 1280 and 390.
- Next (M3-04) must know: write the snapshot test `project-page-unchanged.test.tsx` *before* moving page.tsx, so the
  "renders exactly as today" proof is real. The plan also gives M3-04 `getCaseStudyAnchors()` (for M7's link test) and
  the D17 `role="img"` on `ProjectDiagram` — no M3 feature step named the D17 a11y change.
- Proposed changes: M3-02 step 3 says "compiles under ts-jest"; Jest here is next/jest (SWC, no type check) — the real
  check is `npx tsc --noEmit` / `next build`. M3-04 should list the D17 diagram a11y and the snapshot test as steps.
- Questions for Michael: none.

### 2026-10-18 verify M1

check.sh green (154 tests); smoke all routes PASS at 1280 and 390.

| Feature | Step | What you ran or read | What you saw | Holds |
|---|---|---|---|---|
| M1-01 | 1 | `grep '^## '` on docs/plans/2026-10-18-M1-card.md; read Layout at 390 | Sections Layout at 390, Chrome, vCard, QR, Tests, What Michael will see, Review all present; 112 px, 44 px, 844 mentioned | yes |
| M1-01 | 2 | grep the plan for the slugs and "change automatically" | Selected-work section names the three slugs; line 36 says they change automatically as case studies merge | yes |
| M1-01 | 3 | `git diff --stat 18a6003~1 18a6003` | docs/plans/ file plus .harness/runs files only, no code | yes |
| M1-01 | 4 | check.sh | green (cached, 154 tests) | yes |
| M1-02 | 1 | read src/lib/vcard.ts; ran vcard.test.ts | exports buildVCard; "builds the exact vCard for the real profile" and the CRLF test pass; curl output shows the exact lines in order | yes |
| M1-02 | 2 | vcard.test.ts escaping cases | "escapes comma, semicolon and newline in N and FN" and "doubles a backslash in the location" pass | yes |
| M1-02 | 3 | vcard.test.ts "has no phone line (D5)" | passes; curl body has no TEL | yes |
| M1-02 | 4 | read route.ts; ran vcf-route.test.ts | force-static and GET present; 5 tests assert 200, both headers, body equals buildVCard | yes |
| M1-02 | 5 | `curl -si localhost:7800/michael-herron.vcf` | 200, content-type text/vcard; charset=utf-8, content-disposition inline; filename="michael-herron.vcf", body starts BEGIN:VCARD | yes |
| M1-02 | 6 | check.sh | green | yes |
| M1-03 | 1 | read package.json and lock | qrcode and @types/qrcode only in devDependencies (dependencies has none); "qr" script present; lock mentions qrcode | yes |
| M1-03 | 2 | read scripts/make-qr.mjs; `npm run qr` twice, `git status --short`, xxd of PNG | imports profile.ts, margin 2, M, colours, width 1024; exit 0 both times; status clean; IHDR 0x400 x 0x400 | yes |
| M1-03 | 3 | qr.test.ts | "committed qr.svg encodes ${profile.siteUrl}/card?src=qr" and "qr.png is 1024 × 1024" pass | yes |
| M1-03 | 4 | `git ls-files public/card` | qr.png, qr.svg | yes |
| M1-03 | 5 | check.sh | green | yes |
| M1-04 | 1 | read SiteChrome.tsx; SiteChrome.test.tsx | client component; hides chrome on /card and /card/*, no footer on /; no ConditionalFooter file; tests cover /card, /card/qr, /, /about (plus /cardigan) | yes |
| M1-04 | 2 | read src/app/card/page.tsx | 112 px next/image, h1, positioning, subline, Save contact, LinkedIn/Email/GitHub, h2 Selected work from getTopProjects(3), Full portfolio, Show QR, min-h-[44px] | yes |
| M1-04 | 3 | read metadata; card.test.tsx "metadata title and description" | title, description, openGraph.images and twitter.images with headshot, card 'summary' | yes |
| M1-04 | 4 | card.test.tsx (13 tests pass) | assert name, positioning, hrefs, 3 project links equal getTopProjects(3) in order, no nav | yes |
| M1-04 | 5 | smoke-routes.txt; smoke on /card; `curl /card | grep -c '<nav'` | file lists /card and /card/qr; PASS at 1280 and 390; grep count 0 | yes |
| M1-04 | 6 | check.sh | green | yes |
| M1-05 | 1 | read src/app/card/qr/page.tsx | bg-white text-black min-h-screen, img /card/qr.svg, alt names michael-herron.vercel.app/card, width min(80vw,420px), name, positioning, Back to /card, robots index false | yes |
| M1-05 | 2 | card-qr.test.tsx (7 tests pass) | img src/alt, back href, text, robots, no nav asserted | yes |
| M1-05 | 3 | smoke on /card /card/qr | PASS both at both widths; routes file has both | yes |
| M1-05 | 4 | read docs/conference-kit.md; grep for phone-like numbers | 40 lines, three sections, content as required, no phone number; content-guard test in suite passes | yes |
| M1-05 | 5 | check.sh | green | yes |
| M1-06 | 1 | `ls -l docs/screenshots/v2` | M1-card-390 75 KB, M1-card-1280 99 KB, M1-card-qr-390 10 KB, all under 400 KB | yes |
| M1-06 | 2 | Playwright at 390x844 against :7800 | h1 bottom 200, Save contact bottom 384, both ≤ 844; same numbers in the plan | yes |
| M1-06 | 3 | Playwright heights at 390 | Save 48, LinkedIn 44, Email 44, GitHub 44, Full portfolio 44, Show QR 44; listed in the plan | yes |
| M1-06 | 4 | read plan table | three rows (page, on screen, anything wrong) | yes |
| M1-06 | 5 | Playwright at 1280 | main x 380, width 520, centered | yes |
| M1-06 | 6 | check.sh | green | yes |
| M1-07 | 1 | read plan ## Review | review of the diff with Critical/Important/Minor items one line each | yes |
| M1-07 | 2 | read Review; ran card/card-qr/vcard tests | no Critical/Important; Minor fixes name their tests and those pass | yes |
| M1-07 | 3 | read Review; Playwright heading list, nav count | h1 then h2 only; focus outline test passes; Review records the checks and fixes | yes |
| M1-07 | 4 | `grep -rn 'mherron734\|Systems & Process Engineer' src --include=*.tsx` excluding tests | no hits | yes |
| M1-07 | 5 | grep CLAUDE.md and plan | routes table has /card, /card/qr, /michael-herron.vcf; plan line 353 "Ready to merge: yes" | yes |
| M1-07 | 6 | smoke all routes; check.sh | all PASS; green | yes |

### 2026-10-18 21:55 · M1-07 · passes

- Opus review of `$HARNESS_SCRATCH/M1.diff` (2473db6..HEAD, 1395 lines): 0 Critical, 0 Important, 13 Minor. Fixed 8
  test-first: arrow aria-hidden on "Full portfolio", sr-only "(opens in new tab)" on LinkedIn/GitHub, all 9 /card links
  pinned to `focus-visible:outline-2`, "Back to card" sr-only on /card/qr, QR img width/height 420, `escape` →
  `escapeText`, a 75-octet vCard line test, Footer.tsx + contact/page.tsx now read `profile` (grep clean). 150 → 154.
- The rest are listed with reasons in the plan's Review section, along with the web-design-guidelines results.
  Contrast is AA everywhere (lowest is muted text on the card surface, 5.4:1). A Chromium keyboard pass at 390
  reached all 9 /card links, each with a 2px cyan outline. The plan ends "Ready to merge: yes"; CLAUDE.md routes now list /card,
  /card/qr, /michael-herron.vcf.
- Verified: smoke 28/28 PASS; check.sh green (154); 390 screenshots of /card, /card/qr, /contact unchanged visually.
- Note: the footer/contact LinkedIn href is now the canonical `https://www.linkedin.com/in/mherron734/`. A PNG
  byte-compare test was tried and dropped (≈ 8 s under Jest). M1 is complete; next is M3 per the brief's order.
- Questions: none. Proposed changes: none.

### 2026-10-18 21:25 · M1-06 · passes

- New `docs/screenshots/v2/M1-card-390.png` (75 KB, 390 × 844 viewport), `M1-card-1280.png` (99 KB, full page),
  `M1-card-qr-390.png` (10 KB); the plan's "What Michael will see" table and Measurements line are filled. No code
  changed; 150 → 150 tests.
- Measured with Playwright (`$HARNESS_SCRATCH/m1-measure.mjs`) against :7800: h1 bottom 200, Save contact bottom 384
  (fold 844); heights Save contact 48, LinkedIn/Email/GitHub/Full portfolio/Show QR 44 each, /card/qr Back 44; main at
  1280 = 520 px wide, 380 px each side; QR 312 px at 390; scroll overflow at 390 = 0. Smoke 28/28 PASS; check.sh green.
- Nothing looked wrong. The `next dev` "N" badge was hidden with injected CSS before the shots (production has none).
- Next: M1-07 (review) is unblocked; its Minor list from M1-04 (aria-hidden arrow on "Full portfolio →", sr-only
  "opens in new tab") is still open. Questions: none. Proposed changes: none.

### 2026-10-18 21:05 · M1-05 · passes

- New `src/app/card/qr/page.tsx` (static server component: white `min-h-screen` main, plain `<img src="/card/qr.svg">`
  at `min(80vw, 420px)`, alt built from `profile.siteUrl`'s host, h1 name + positioning below, `← Back` to `/card` with
  the arrow aria-hidden, `robots: { index: false }`, title `QR — Michael Herron`). New `card-qr.test.tsx` (6).
  `/card/qr` appended to `.harness/smoke-routes.txt`. New `docs/conference-kit.md` (40 lines, 3 sections). 144 → 150.
- Verified: the test failed first (module missing); a 420 → 400 px mutation fails the width assertion; `curl :7800/card/qr`
  → 200, `<nav` 0, `<meta name="robots" content="noindex"/>`; `/card/qr.svg` 200 image/svg+xml; smoke `/card` and
  `/card/qr` PASS at 1280 and 390, full smoke 28/28; all 11 content-guard regexes run over the kit: 0 hits; check.sh
  green (150). 390 screenshot: QR ≈ 280 px square centered, name, positioning and Back below, no overflow.
- Opus review: 0 Critical/Important. Took 5 Minors: name is now an h1 (test checks h1 and DOM order img → name →
  positioning, failed first); kit says "featured, lowest order", that the PNG test checks only size, and that Android
  needs one more tap. Left: none.
- Next: M1-06 (screenshots + measurements) is unblocked. Questions: none. Proposed changes: none.

### 2026-10-18 20:40 · M1-04 · passes

- New `src/components/SiteChrome.tsx` (plan code verbatim; hides Navbar, `pt-16` and Footer on `/card` and `/card/*`,
  no Footer on `/`), `ConditionalFooter.tsx` deleted, `layout.tsx` renders `<SiteChrome>` and adds `metadataBase`
  (D24). New static `src/app/card/page.tsx` (headshot 112 px, h1, positioning, subline, Save contact, LinkedIn/Email/
  GitHub, getTopProjects(3), Full portfolio →, Show QR; metadata per plan). `.harness/smoke-routes.txt` = `/card`.
  D28 *default* appended to the spec. Tests: SiteChrome.test.tsx (5) + card.test.tsx (11). 128 → 144.
- Verified: both suites failed first (modules missing), then passed; `curl :7800/card` → 200, `<nav` count 0, `<footer`
  0, title "Michael Herron — Systems & Process Engineer", og:image absolute; `/about` still has its nav; the build
  prerenders `.next-check/server/app/card.html`; smoke `/card` PASS at 1280 and 390, full smoke 26/26 PASS; check.sh
  green (144). 390 screenshot: Save contact ends ≈ 384 px, all three projects visible, nothing wraps or overflows.
- Opus review: 0 Critical/Important. Minor, left for M1-07: "Full portfolio →" reads the arrow aloud (wrap it in
  aria-hidden and update the test's name); LinkedIn/GitHub `target=_blank` without an sr-only "opens in new tab";
  the no-`<nav>` page test is trivially true (SiteChrome test + curl are the real guard); the button test pins only
  `min-h-[44px]`.
- Next: M1-05 (/card/qr + conference kit) is unblocked; append `/card/qr` to `.harness/smoke-routes.txt`.
- Questions: none. Proposed changes: none.

### 2026-10-18 20:05 · M1-03 · passes

- New `scripts/make-qr.mjs` (imports profile.ts per D21, writes `public/card/qr.svg` as returned and a 1024 px
  `qr.png`; margin 2, ECC M, #0a0a0f on #ffffff; paths from `import.meta.url`), `npm run qr`, devDeps qrcode 1.5.4 +
  @types/qrcode 1.5.6 (lock `dev: true`, `dependencies` untouched), new `src/__tests__/lib/qr.test.ts` (2). 126 → 128.
- Verified: test failed first (ENOENT), then passed; changing siteUrl makes the SVG test fail (mutation checked);
  `npm run qr` twice, and once from /tmp, leaves `git status` unchanged; the PNG decodes with jsQR (scratch install) to
  `https://michael-herron.vercel.app/card?src=qr` at 1024×1024; check.sh green (128); smoke 24/24 PASS.
- An Opus review found 0 Critical/Important; took the Minor "Node ≥ 22.18" note (script header). Left the
  MODULE_TYPELESS warning (plan says don't add `"type": "module"`).
- Next: M1-04 (/card) is independent; M1-05 needs M1-03 + M1-04 and can use `/card/qr.svg` now.
- Questions: none. Proposed changes: none.

### 2026-10-18 19:45 · M1-02 · passes

- New `src/lib/vcard.ts` (`buildVCard(profile)`: vCard 3.0, CRLF everywhere, RFC 6350 escaping of N/FN/TITLE/ADR, no
  TEL, no PHOTO) and `src/app/michael-herron.vcf/route.ts` (force-static GET, `text/vcard; charset=utf-8`,
  `inline; filename="michael-herron.vcf"`). Tests: new vcard.test.ts (9) + app/vcf-route.test.ts (5, node env). 112 → 126.
- Verified: check.sh green (126); the build prerenders `.next-check/server/app/michael-herron.vcf.{body,meta}` with both
  headers and CRLF bytes (od -c); `curl -si :7800/michael-herron.vcf` shows both headers, body starts BEGIN:VCARD; smoke 24/24 PASS.
- An Opus review caught a real bug: `';'` was replaced by `'\;'` written with one backslash (a no-op in TS), and the test
  literal had the same slip, so it passed. Fixed test-first; added a `;`-in-ADR case and a backslash-before-comma
  ordering case. Reverting the fix makes 2 tests fail (mutation checked).
- Next: M1-03 and M1-04 are independent. M1-04 still appends D28 *default* (no PHOTO, inline disposition, no ScrollReveal).
- Questions: none. Proposed changes: none.

### 2026-10-18 19:05 · M1-01 · passes

- New `docs/plans/2026-10-18-M1-card.md` (plan only, no code): Files, Selected work (linear-ai-workflow,
  ghl-jobtread-integration, paint-estimator today; they change by themselves as case studies merge), Layout at 390
  (element table with estimated bottoms, fold 844), Choices, Chrome (SiteChrome code per D15), vCard (exact CRLF output,
  escaping rules, the test fixture as both file text and TS literals), QR, Tests (6 files, ~30 named cases), an empty
  What Michael will see table, and an empty Review section. Tests 112 → 112.
- Verified: I installed qrcode 1.5.4 in scratch and checked the facts the plan relies on: the code is 33 modules, the
  PNG is exactly 1024², two runs give byte-identical PNGs, and the SVG trips no content-guard pattern. Node 24 imports
  profile.ts from .mjs, printing only a MODULE_TYPELESS warning. check.sh is green (112), smoke is all PASS.
- An Opus review found 0 Critical and 2 Important issues (TS-literal backslashes in the escape test, next/image
  rewriting `src` in Jest), both now fixed in the plan, plus 6 Minor, all applied.
- Next session (M1-02/03/04 are independent): follow the plan. M1-04 appends **D28 *default*** to the spec (no
  ScrollReveal on /card, no vCard PHOTO, inline disposition) and adds `metadataBase` (D24).
- Proposed change: none.

### 2026-10-18 verify M0 · verify M0

check.sh green (112 tests, cached); smoke all PASS at 1280 and 390.

| Feature | Step | What you ran or read | What you saw | Holds |
|---|---|---|---|---|
| M0-01 | 1 | Read src/lib/data/profile.ts, index.ts (`export * from './profile'`), profile.test.ts | All 10 values match exactly; test asserts toEqual on the full object plus each key | yes |
| M0-01 | 2 | Read content-guard.test.ts PATTERNS, listFiles, tree test; compared with the spec regexes | Walks src/ and public/ with the listed extensions, skips itself, reports file:line pattern. Covers all 11 patterns the step enumerates (the step says "12" but lists 11, as does the spec) | yes |
| M0-01 | 3 | `npx jest src/__tests__/lib/content-guard.test.ts` | 20/20 pass: a sample per pattern (15 samples) asserted with the right pattern name, clean-sample test passes | yes |
| M0-01 | 4 | Tree test in content-guard.test.ts; `git log -- content-guard.test.ts` | Tree test green; file has a single commit (6e45680), so nothing was loosened afterwards | yes |
| M0-01 | 5 | `/home/mh550/projects/agent-harness/lib/check.sh` | green (112 tests) | yes |
| M0-02 | 1 | grep order/featured in projects.ts; `npx tsc --noEmit` | orders linear 2, ghl 5, paint 6, ringcentral 7, mirrored 8, cherished 9; both mirrored and cherished featured:false; `order: number` required; tsc exit 0 | yes |
| M0-02 | 2 | Read projects.ts getTopProjects, index.ts barrel (`export *`), data.test.ts lines 51-97 | Test asserts getTopProjects(3) slugs, (10) excludes cherished, order values unique; lib suites 55/55 pass | yes |
| M0-02 | 3 | Read approach.ts, approach.test.ts | 5 steps in order with the right labels, lines 38-67 chars, first person; barrel re-exports; test asserts ids, labels, 20-90 length | yes |
| M0-02 | 4 | `git diff f86ad9f..HEAD --stat` | Changes only in src/lib/data, src/__tests__ (incl. ScrollReveal.test.tsx, a test), .harness/runs, docs; no component edits; content-guard.test.ts has one commit | yes |
| M0-02 | 5 | `/home/mh550/projects/agent-harness/lib/check.sh` | green | yes |

### 2026-10-18 18:40 · M0-02 · passes

- `Project.order` (required) set per D12 on the 6 projects; `cherished` is now `featured: false` (mirrored stays
  false, D25). `getTopProjects(n)` in `projects.ts` (featured, by order, first n, n ≤ 0 → []). New
  `src/lib/data/approach.ts` (`methodSteps`, 5 first-person lines of 38–67 chars), both from the barrel. Tests: data.test.ts +6,
  new approach.test.ts (5). Jest 101 → 112, 14 → 15 suites.
- `npx tsc --noEmit` failed before this session on every test file (the repo has no `@types/jest`). Fixed without new
  deps: `src/__tests__/jest-globals.d.ts` declares the globals from `@jest/globals` + jest-dom matchers, and
  ScrollReveal.test uses `requireActual<object>`. tsc now exits 0.
- Verified: check.sh green (112 tests), smoke 24/24 PASS, tsc 0, content guard unchanged since M0-01 (`git diff 6e45680`).
  Opus review of the whole M0 diff: no bugs. I took 4 of its 6 suggestions (exact-slug assertion for getTopProjects(10), clamp negative n,
  two comments in the .d.ts).
- Next sessions: the `projects` array is **not** in `order` order and `ProjectsGrid` renders it as-is. M8 must
  sort the index by `order` and keep non-featured projects (don't use `getTopProjects` there). M1/M2 use
  `getTopProjects(3)`, which today gives linear-ai-workflow, ghl-jobtread-integration and paint-estimator.

### 2026-10-18 18:24 · M0-01 · passes

- Added `src/lib/data/profile.ts` (typed `Profile`, values from brand.md "Contact facts"), re-exported from
  `src/lib/data/index.ts`; `src/__tests__/lib/profile.test.ts` (11 tests); `src/__tests__/lib/content-guard.test.ts`
  (20 tests: 15 in-memory samples, a clean near-miss sample, a file:line test, a sample-coverage test, a walk test,
  and the tree scan). Jest 70 → 101 tests, 12 → 14 suites. No content files changed: the tree was already clean.
- Verified: `check.sh` green (101 tests); smoke PASS on all 18 route×width; I planted `TODO` in `src/zz-plant.ts`,
  a Spotify playlist URL in `public/zz-plant.svg` and a symlinked `public/zz-link.MD`, and the guard failed
  naming `src/zz-plant.ts:2 TODO`, `public/zz-plant.svg:1 Spotify playlist` and `public/zz-link.MD:1 TODO`
  (all planted files removed). An Opus review checked the regexes against the spec character by character and
  found no problems. I took two of its minor suggestions: the walk follows symlinks, and extensions are compared
  in lower case.
- Next session: the guard's patterns and samples live only in the test file, which skips itself. Keep
  `TODO`, `[X]` and `lorem ipsum` out of every other file in `src/` and `public/`, including test strings.
- Proposed change: the M0-01 steps say "12 spec M0 patterns" and "12 samples", but the spec (and the step's own
  list) has **11** patterns. The guard has the spec's 11 patterns exactly, plus 15 samples that cover all 11.

## 2026-10-18 · Initializer (Fable)

### Feature counts

| Milestone | Features | Ids | Needs |
|---|---|---|---|
| M0 guardrails + profile | 2 | M0-01…02 | — |
| M1 `/card` + QR (Monday) | 7 | M1-01…07 | M0 |
| M3 case-study template | 5 | M3-01…05 | M0 only |
| M4 agent-harness | 5 | M4-01…05 | M3 only |
| M5 home-media-server | 5 | M5-01…05 | M3 only |
| M6 hit-list | 5 | M6-01…05 | M3 only |
| M2 positioning | 6 | M2-01…06 | M1 |
| M7 `/approach` + `/evidence` | 5 | M7-01…05 | M3 only |
| M8 nav, index, polish | 2 | M8-01…02 | M2 + M7 |
| M9 docs hand-off | 1 | M9-01 | M1 only (runs when nothing earlier is runnable) |
| S1 OG images · S2 card note · S3 print CSS | 3 | S1-01, S2-01, S3-01 | M3 / M1 / M3 |

46 features. M0 has no plan or review feature (lean, per the brief); M3's screenshot check is folded into its
review (M3-05); M8's a11y pass and review are one feature (M8-02).

### Where things live (read before coding)

- Data: `src/lib/data/{projects,skills,experience}.ts` + barrel `index.ts`. M0 adds `profile.ts`, `approach.ts`;
  M7 adds `competencies.ts`. **Everything new is re-exported from the barrel** (`@/lib/data`).
- `Project` type is in `projects.ts` (slug, title, company, shortDescription, categories, techStack, githubUrl?,
  demoUrl?, featured, thumbnail?, metrics?, detail{problem, approach, challenges, outcome, architectureDiagram?,
  media?, codeSnippets?}). Six projects today; `cherished` and `mirrored-google-calendars` are already
  `featured: false`. `ProjectCategory` = integration | full-stack | ai | education.
- Page `src/app/projects/[slug]/page.tsx` renders four fixed sections (The Problem, The Approach, Challenges,
  Outcome) + diagram after Approach + "In the Code" + "A Closer Look". `generateMetadata` already returns
  `"<title> — Michael Herron"` / shortDescription. M3 extracts the body into `ProjectDetail` (D16).
- Diagrams: `src/components/projects/diagrams/index.tsx`, one file, HTML/Tailwind primitives (`Node`, `Arrow`,
  `Panel`), a `DIAGRAMS` map and a `CAPTIONS` map; the `figure` has a figcaption but **no `role="img"` /
  `aria-label` yet** (D17 adds a `LABELS` map). New diagrams: new files in that folder, registered in the maps.
- Reusables: `ScrollReveal`, `MetricStrip` (dl, renders null when empty), `MediaGallery` (next/image, 4:3,
  captions), `CodeBlock` (`{title, language, code}`), `ProjectCard` (shows `metrics[0]` in the preview band when
  there is no thumbnail), `TimelineLine`.
- Layout: `src/app/layout.tsx` = `<Navbar/>` + `<div className="pt-16">{children}</div>` + `ConditionalFooter`
  (client, hides the footer on `/`). The hero uses `-mt-16 h-screen` to cancel that padding. D15: replace with
  `SiteChrome`.
- Navbar links are a `links` array at the top of `src/components/Navbar.tsx`; `usePathname` for the active state.
- Design tokens in `src/app/globals.css` (`--color-background #0a0a0f`, `--color-accent #00d4ff`, `--color-muted`,
  `--color-surface`, `--color-surface-alt`); use `text-[var(--color-accent)]` etc. Geist via next/font.

### Testing gotchas

- Jest 30 + ts-jest via `next/jest`, jsdom, `@/` alias, framer-motion mapped to `src/__mocks__/framer-motion.tsx`.
  The mock only defines `motion.{div,span,p,h1,h2,section,nav,ul,li,button,a}`: **add any new `motion.<tag>` you
  use (ol, article, figure, …) to the mock** or the test crashes.
- Async server pages: call the component (`await Page({ params: Promise.resolve({ slug }) })`) and `render()` the
  returned element, or test the extracted body component with a prop (D16).
- Route handlers and anything using `Response`/`Headers`: put `/** @jest-environment node */` at the top of the
  test file (jsdom has no `Response`).
- `next/navigation` is mocked per test file: `jest.mock('next/navigation', () => ({ usePathname: () => '/' }))`.
- Canvas: `HTMLCanvasElement.prototype.getContext = jest.fn(() => null)` before rendering the hero.
- `src/__tests__/lib/data.test.ts` pins the project count (6 today): bump it in every milestone that adds a project.
- The content guard (M0-01) walks `src/` **and `public/`**: SVG/JSON/MD there are scanned too. The `[X]` and `TODO`
  patterns are literal; keep them out of comments and test sample strings outside the guard's own file.
- Suite: `.harness/check.sh` (eslint + jest + `next build` into `.next-check`), ~1 min. Subset: `npx jest <path>`.

### Dev server, smoke and screenshots

- `.harness/init.sh` leaves `next dev` on `$HARNESS_PORT` (7800 in this run; `${HARNESS_PORT:-7831}` otherwise).
  First load of a route compiles it: slow, and the smoke script allows 120 s.
- `node .harness/smoke.mjs [base] [path …]` → PASS/FAIL per route and width, full-page PNGs in `$HARNESS_SCRATCH`
  as `smoke-<name>-<width>.png`. With no paths it reads `.harness/smoke-routes.txt` (**does not exist yet; M1-04
  creates it**, one path per line) plus every `/projects/<slug>` linked from `/projects`.
- "What Michael will see" screenshots: copy from `$HARNESS_SCRATCH` into `docs/screenshots/v2/<M>-<page>-<width>.png`
  (create the folder) or capture directly. Full pages of the home hero can exceed 400 KB: then capture a
  `clip` of the top 3000 px or `fullPage: false`, and say so in the plan's table.
- Ad-hoc Playwright (bounding boxes, viewport-only shots, `emulateMedia`): Playwright is installed outside the
  repo at `$HARNESS_PW` (`/tmp/harness/pw`). In a `.mjs` script:
  `const { chromium } = createRequire('/tmp/harness/pw/')('playwright')`. Keep such scripts in `$HARNESS_SCRATCH`,
  not in the repo.

### Sources outside the repo (read-only, only these paths)

- agent-harness: `/home/mh550/projects/agent-harness/` — `README.md`, `docs/architecture.md`, `journal/README.md`
  (has a case-study outline), `journal/decisions.md`, `journal/evidence/timeline.md`, `journal/iterations/`,
  `journal/runs/`, `ledger/runs.jsonl`, `lib/driver.sh` (verified-tree merge check in `merge_milestone`, ~l.170–195),
  `lib/metrics.mjs` (limit detection, the `LIMIT` regex ~l.50). **Never `journal/raw/`.**
- dj-crate-streaming: `/home/mh550/projects/dj-crate-streaming/` — local `main` is behind; read docs with
  `git -C /home/mh550/projects/dj-crate-streaming show origin/main:<path>`. `docs/download-validation.md` exists
  locally (verify block under "Reading the result"; it contains `/srv/incoming/…`, see D18). Screenshots
  `docs/screenshots/01-playlists.png` (59 KB), `02-crate-toggled.png` (90 KB), `03-wanted.png` (108 KB). Never `m6-*`.
- hit_list: `/home/mh550/projects/hit_list/` — `README.md`, `APP_SPECIFICATIONS.md`, `OVERNIGHT.md`,
  `docs/specs/2026-10-13-overnight-design.md`, `docs/specs/2026-10-16-simplification-design.md`. No screenshots.
- Pathways and `mh550/projects` are private: never link or name their URLs.

### Other facts

- Node 24.21, Next 16.1.6, React 19.2, Tailwind 4, framer-motion 12. `qrcode` 1.5.4 and `@types/qrcode` 1.5.6 are
  on the registry; `npm i -D` them in M1-03 (the only approved new package). Lockfile changes make init reinstall.
- Policy is build-only: nothing is deployed, no live service is touched. The only "live" step in this run is
  Michael scanning the QR after he merges M1: it is written in `docs/conference-kit.md` (M1-05), not performed.
- Existing content already passes the 12 guard patterns (grep checked by the initializer).
- The pre-M2 skills list (39 strings) is in `src/lib/data/skills.ts` on this commit; M2-04's test hard-codes it.

### Questions for Michael (defaults chosen; nothing waits)

1. Skills page h1: stays "Tech Stack" after the regroup unless the M2 plan finds a better plain title (D20 names
   only the featured group). Reversible in one data/page edit.
2. Agent-harness iterations: 6 or 7 rows (row 1b folded or kept), D27. Reversible in the data file.
3. The home page footer returns once Recent work exists (D19). If you preferred the footer-less hero, flip one
   line in `SiteChrome`.
4. `conferenceNote` (S2) ships empty; type a line in `profile.ts` when you want it shown.
