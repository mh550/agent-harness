<!-- harness: rendered from entries.jsonl after every session; edits here are overwritten -->
# Progress — run `agent-harness-2026-10-25-memory` (agent-harness)

What this file is: the harness renders it from `entries.jsonl` after every session, newest entry first (15 in full, then one line each; `progress-archive.md` has every entry). Don't edit it: write to `INBOX.md`.

The run builds `docs/specs/2026-10-25-memory.md`, M1–M6 in its order, per Michael's brief of 2026-10-26 18:54 (`brief.md`): the retro backlog first; sessions never write `ledger/`; the seed file is never imported into the real ledger; evals are written to `evals/NEXT.md`, never run.

`feature_list.json`: 23 features in priority order; `passes` flips as each is verified by its session, `after` says what each waits on (M1, M2, M5 and M6 start independently; M3 and M4 wait on M2). A milestone whose features all pass is verified by an independent session and merged into `main`. Per milestone: M1 6 · M2 3 · M3 5 · M4 2 · M5 2 · M6 5.

Steer from the GitHub app: edit `INBOX.md` on this branch. First line `status: pause` or `status: stop [why]`; answers to questions go under `## Answers` (every session reads them; a parked feature is retried once answers change). Each entry's **Question for Michael** lines are what the sessions need from you; each took the simplest reversible default meanwhile.

### 2026-10-26 23:10 · verify M4 · passes

M4-01 and M4-02 hold: suite green (474 tests), memlint subset 19/19, fixtures re-linted by hand give the stated findings, docs and decision file present, review recorded in entries.

| Feature | Step | What you ran or read | What you saw | Holds |
|---|---|---|---|---|
| M4-01 | 1 | node lib/memlint.mjs <tmp worktrees>, /nonexist, header read | findings in file:line check: text form; exit 0; missing dir exit 2; 121-line CLAUDE.md gives size, 16 Gotchas gives gotchas; header lists checks | yes |
| M4-01 | 2 | head -1 of the 4 fixtures | each first line names repo, commit, path as specified | yes |
| M4-01 | 3 | lint on fixtures; bash tests/run.sh memlint | dj: derivable-count line 17; pathways: night-scope tonight; old rane: decisions D15 Superseded, none for header; tidy rane: none; no store: decisions: no store; 19/19 pass | yes |
| M4-01 | 4 | 121-line and 16-Gotchas worktrees; node --check; test 39 store-lookup check | size and gotchas findings; node --check ok; decisionsStore check passes | yes |
| M4-01 | 5 | node lib/memlint.mjs . in this worktree | no output, exit 0 | yes |
| M4-01 | 6 | init.out | green, 474 tests | yes |
| M4-02 | 1 | tests/checks/39 driver memlint check | 2 memlint notes before feature list written, run done 3/3 | yes |
| M4-02 | 2 | tests/checks/39 failing memlint check | one memlint: failed (exit 1) note, run goes on to done 3/3 | yes |
| M4-02 | 3 | tests/checks/39 harness memlint check | same two lines from $T/proj, exit 0, usage in bin/harness header | yes |
| M4-02 | 4 | grep README, architecture.md, ls journal/decisions | README line 69-73, arch §7 row line 264, §3 row line 70, decisions/2026-10-26-memlint.md exist | yes |
| M4-02 | 5 | entries.jsonl:20 summary | Opus review recorded: 0 Critical, 2 Important fixed RED to GREEN | yes |
| M4-02 | 6 | init.out | suite green 474 tests | yes |

- *230904-verify-M4 · claude-sonnet-5-5*

### 2026-10-26 23:03 · M4-02 · passes

Driver notes memlint findings as `memlint: …` at every segment start (60 s, stdout only, a failure is one `memlint: failed` note, never a stop); `harness memlint <project|path>`. Opus review of M4: 0 Critical, 2 Important fixed RED→GREEN (a stack-trace failure note; a header under a ## section flagged) plus 4 Minor. Tests 469 → 474.

- **Files:** lib/driver.sh, bin/harness, lib/memlint.mjs, tests/checks/39-memlint-m4.sh, tests/checks/08-scope-sh-l1-02-run-capped-services-gc-scratch.sh, tests/fixtures/check-names.txt, README.md, docs/architecture.md, journal/decisions/2026-10-26-memlint.md
- **Verified:** tests/checks/39-memlint-m4.sh 19/19 (3 driver/CLI checks and 2 review checks watched failing first); full suite via lib/check.sh; bash -n driver.sh, bin/harness; node --check lib/memlint.mjs
- **Tests:** 469 → 474
- **Dead end:** memlint stderr merged into the findings (2>&1) — a node warning became a finding note, and a crash's note was `node:fs:483` (review); stderr now goes to $SCRATCH/memlint.err
- **Discovery** (affects run): tests/checks/08's step-lint check counted `lint: ` lines, which `memlint: ` notes also match; it now greps `· lint: `. A future note ending in `lint:` needs the same care.
- **Discovery** (affects M4, run): Review Minor left as heuristics (D-defaults in decisions/2026-10-26-memlint): `# ` lines inside code fences end the Where-things-go/Gotchas section; `this run fails` and `2 checks` are flagged; a table store's `Updated in place` on the successor row doesn't clear the superseded row; `no store` cites .harness/config.sh:1 even when absent.
- **Question for Michael:** The memlint notes repeat every segment (a continue too) until the file is tidied: keep that, or note only findings that are new since the run's last segment?
- *16-M4-02 · claude-opus-5-5*

### 2026-10-26 22:48 · M4-01 · passes

lib/memlint.mjs <worktree> lints CLAUDE.md, .harness/project.md and the decisionsStore store: size, gotchas, derivable-count, night-scope, decisions; one `<file>:<line> <check>: <text>` per line, exit 0 (2: no worktree). 6 fixtures from pre-tidy and tidy commits. This repo's CLAUDE.md lost `395 checks`. Opus review: 0 Critical/Important, 5 Minor fixed RED→GREEN. Tests 455 → 469.

- **Files:** lib/memlint.mjs, tests/checks/39-memlint-m4.sh, tests/fixtures/memlint/, tests/fixtures/check-names.txt, journal/decisions/2026-10-26-memlint.md, CLAUDE.md
- **Verified:** bash tests/run.sh 39-memlint 14/14 (11 written first and watched failing, 3 more for the review's findings, each red first); full suite via check.sh green in 312 s, 469 tests; node lib/memlint.mjs . prints nothing; node --check lib/memlint.mjs passes
- **Tests:** 455 → 469
- **Dead end:** bare `superseded` / `overturned` / `replaced by` as supersession markers (K3's list as written) — flags rane's own header (`when a decision is overturned`), voice-concierge D11 (`the rows they superseded`) and 3 of this repo's decision files (`replaced by` in prose); now passive or tagged forms only (decision D3)
- **Discovery** (affects M4-02): memlint exports lint(worktree, maxLines), lintText, lintStore, gotchasEntries; CLI `node lib/memlint.mjs <dir>` exits 0 with findings, 2 on a missing dir, 1 (stack) on an unreadable file: M4-02's `memlint: failed` note keys on non-zero exit.
- **Discovery** (affects M4-02, run): On 2026-10-26 the projects' checkouts give exactly two findings, both size: hit_list CLAUDE.md 181 lines and portfolio_site 127 (MEMLINT_LINES 120). M4-02's README line can say so.
- **Discovery** (affects run): Fixture sources were read from bare clones in the scratch dir (git clone --bare ~/projects/<p>), never by git commands in the projects' checkouts.
- **Question for Michael:** memlint defaults D1-D4 in journal/decisions/2026-10-26-memlint.md (plural counts incl. `checks`; month-name dates; passive/tagged supersession markers only; no-store reported at .harness/config.sh:1): keep them?
- **Proposed change:** M4-02: architecture §7's memlint row and README can cite the two live findings (hit_list and portfolio_site CLAUDE.md over 120 lines) as what Michael will see first
- *15-M4-01 · claude-opus-5-5*

### 2026-10-26 22:27 · verify M3 · passes

All five M3 features hold: full suite green (455), 38-run-17 12/12 and 12-journal 15/15 re-run, docs/decisions/plan present, bash -n and node --check ok.

| Feature | Step | What you ran or read | What you saw | Holds |
|---|---|---|---|---|
| M3-01 | 1 | re-ran/read: plan exists, defines gotchasDiff/note/driver placement (grep docs/plans/2026-10-26-M3-gotchas-and-pack.md §M3-02) | holds as described | yes |
| M3-01 | 2 | re-ran/read: plan fixes resolved field and pack drop (§M3-03 lines 87-95) | holds as described | yes |
| M3-01 | 3 | re-ran/read: plan fixes Promote to Gotchas, Current rules, VERIFY cap (§M3-03/04) | holds as described | yes |
| M3-01 | 4 | re-ran/read: plan names stub flags, check file 38, existing checks | holds as described | yes |
| M3-01 | 5 | re-ran/read: suite green: init 455 tests | holds as described | yes |
| M3-02 | 1 | re-ran/read: coding.md Finish step 3 Gotchas; check `coding prompt: the Finish step adds one Gotchas line` PASS | holds as described | yes |
| M3-02 | 2 | re-ran/read: check `gotchasDiff: added, edited, deleted and no section` PASS | holds as described | yes |
| M3-02 | 3 | re-ran/read: checks `a stub session that adds a Gotchas line is noted` and `a session that leaves CLAUDE.md alone gets no gotchas note` PASS | holds as described | yes |
| M3-02 | 4 | re-ran/read: architecture.md line 264 Gotchas row; decisions/2026-10-26-gotchas-in-place.md exists | holds as described | yes |
| M3-02 | 5 | re-ran/read: suite green | holds as described | yes |
| M3-03 | 1 | re-ran/read: check `entries.mjs: resolved is an array of strings and normalize keeps it` PASS (15/15 in 12-journal) | holds as described | yes |
| M3-03 | 2 | re-ran/read: check `a resolved question is gone from the next context.md` PASS | holds as described | yes |
| M3-03 | 3 | re-ran/read: check `a project discovery is listed under Promote to Gotchas until CLAUDE.md carries it` PASS | holds as described | yes |
| M3-03 | 4 | re-ran/read: coding.md lines 70,89,97 and where-things-go-readonly.md line 4 name project / Promote to Gotchas; check `coding and verify prompts name resolved…` PA | holds as described | yes |
| M3-03 | 5 | re-ran/read: suite green | holds as described | yes |
| M3-04 | 1 | re-ran/read: check `context.md lists the decisions store rules newest first` PASS | holds as described | yes |
| M3-04 | 2 | re-ran/read: check `CONTEXT_PACK_BYTES=1024 holds…` PASS | holds as described | yes |
| M3-04 | 3 | re-ran/read: config.sh line 30, templates/user/config.sh line 23; check `a verify pack lists failed rows before dead ends` PASS | holds as described | yes |
| M3-04 | 4 | re-ran/read: dead-end checks and 29 legacy checks pass in the full suite (455 green) | holds as described | yes |
| M3-04 | 5 | re-ran/read: architecture.md line 89 seven parts + verify cap; pack-current-rules decision exists | holds as described | yes |
| M3-04 | 6 | re-ran/read: suite green | holds as described | yes |
| M3-05 | 1 | re-ran/read: docs/plans/2026-10-26-M3-review.md records 0 Critical, 2 Important, 9 Minor | holds as described | yes |
| M3-05 | 2 | re-ran/read: Important fixes have RED/GREEN check `entries.mjs: a Gotchas line carries a fact in any case or markup…` PASS | holds as described | yes |
| M3-05 | 3 | re-ran/read: review doc exists; architecture §4/§7, decisions present | holds as described | yes |
| M3-05 | 4 | re-ran/read: bash -n and node --check all ok (run) | holds as described | yes |
| M3-05 | 5 | re-ran/read: suite green | holds as described | yes |

- *222650-verify-M3 · claude-sonnet-5-5*

### 2026-10-26 22:22 · M3-05 · passes

Opus review of the M3 diff (706a001..HEAD): 0 Critical, 2 Important, 9 Minor; no second round. Fixed both Important (a Gotchas line carries a fact in any case/markup/wrap; `resolved` dismisses a promoted fact) and 7 Minor RED→GREEN; docs and the three M3 decision files updated. Tests 451 → 455.

- **Files:** lib/entries.mjs, lib/memlint.mjs, prompts/coding.md, tests/checks/12-journal-pure-e4-entrys.sh, tests/checks/38-run-17-gotchas-and-pack-m3.sh, tests/fixtures/check-names.txt, docs/architecture.md, README.md, docs/plans/2026-10-26-M3-review.md, journal/decisions/2026-10-26-gotchas-in-place.md, journal/decisions/2026-10-26-resolved-and-project-facts.md, journal/decisions/2026-10-26-pack-current-rules.md
- **Verified:** Each new check was watched failing, then passing: `entries.mjs: a Gotchas line carries a fact in any case or markup, resolved dismisses a fact or a question as context.md shows it` (Important 1, 2; Minor 3, 4), `gotchasLines: a wrapped bullet is one line and any # or ## heading ends the section` (1, 6), `entries.mjs pack: an unreadable CLAUDE.md leaves the Gotchas out, never the pack` (5), `memlint: currentRules skips ranges written with any dash or to, and a heading never replaces a row` (7; old memlint gives d.md:13,9,5,3,1). All 7 ~/projects/*/docs/decisions.md give the same currentRules output before and after (md5). bash -n on driver.sh, prompt.sh, stub-claude.sh, checks 12 and 38; node --check on entries.mjs and memlint.mjs. Full suite: check.sh green in 257 s, 455 tests.
- **Tests:** 451 → 455
- **Discovery** (affects M4): memlint gotchasLines now joins an indented continuation line onto its bullet and ends the section at a `# ` heading too; entries.mjs pack matches a promoted fact to a Gotchas line by its first 40 characters lowercased with backticks, * and _ removed (key/loose in pack).
- **Discovery** (affects M4): currentRules: a heading never replaces a bullet or table row of the same D<n>, and D1—D6 / D1 – D6 / D1 to D6 are group headings; M4's lint can reuse the same id regex.
- **Proposed change:** The debrief (lib/debrief.sh:124) still lists questions a later entry resolved; it could skip them now that progress.md renders `Resolved:` items (review finding 4, left).
- *14-M3-05 · claude-opus-5-5*

### 2026-10-26 22:07 · M3-04 · passes

context.md ends with `Current rules` (memlint currentRules/readRules: dir store by dated name, file store's D<n> headings, bullets, table rows incl. `*default*`; ≤cap/4, rest one older-rules line). Verify packs use CONTEXT_PACK_BYTES_VERIFY=16384 with failed rows first. Stub STUB_VERIFY_FAIL_ROW, 3 fixtures, decision file, arch/README. Tests 445 → 451.

- **Files:** lib/memlint.mjs, lib/entries.mjs, lib/driver.sh, lib/config.sh, templates/user/config.sh, tests/stub-claude.sh, tests/checks/12-journal-pure-e4-entrys.sh, tests/checks/38-run-17-gotchas-and-pack-m3.sh, tests/fixtures/decisions-rane.md, tests/fixtures/decisions-voice-concierge.md, tests/fixtures/decisions-dj.md, tests/fixtures/check-names.txt, +3 more
- **Verified:** check.sh green, 451 tests (256 s); new checks watched red first; readRules on the real stores gives rane 24, voice-concierge 23, dj 53 (newest D53); an Opus review fuzzed pack() 20k times with no cap breach; its Important finding (dj `| D36 *default* |` rows dropped) fixed red→green along with CRLF, undated dir files, per-file read errors, ref length
- **Tests:** 445 → 451
- **Dead end:** appending CONTEXT_PACK_BYTES=1024 to $T/proj's config after the gotcha run and pushing — that run had merged PRs into origin main, so the push was refused; pull --ff-only first
- **Dead end:** proving `items left out` at 1024 with the stub's default entries — the stub's packs stay under 864 bytes; STUB_VERIFY_FAIL_ROW's row has a long `saw`, as real rows quote output
- **Discovery** (affects M4, M3-05): memlint.mjs exports currentRules(store, input) and readRules(worktree) → [{text, ref}] newest first; M4's lint can reuse the D<n> line parser (heading, bullet with wrapped lines, table row with an optional `*default*` in the id cell).
- **Discovery** (affects M3-05, M4): Current rules leaves out unnumbered headings (voice-concierge `## LLM provider: …`) and B<n> rulings; in a pack that already stopped (most real verify packs at 8 KB did) the part is omitted whole.
- **Discovery** (affects M3-05, run): In tests/checks/38, a change to $T/proj after a stub run must `git pull -q --ff-only origin main` first: the run merged its PRs into origin main.
- **Question for Michael:** Should Current rules also list unnumbered decision headings (voice-concierge's `## LLM provider: Anthropic direct (Michael, …)`), or is numbering them M4's lint's job? Default taken: numbered only.
- **Proposed change:** M3-04 step 3's `context.md for M1:` byte count exceeding 8192 can't be observed in a stub run; the check proves the verify cap with CONTEXT_PACK_BYTES=1024 (verify pack > 1024 and ≤ 16384, harness-log count > 1024) instead
- *13-M3-04 · claude-opus-5-5*

### 2026-10-26 21:46 · M3-03 · passes

entries.mjs: `resolved` (array of strings, kept only when non-empty) drops a question a later entry names (whitespace-folded); `project` discoveries go to a coding-only `Promote to Gotchas` part (cap/8 share, long facts cut, dedup by first 40 chars) until a CLAUDE.md Gotchas line holds them. Stub flags STUB_ASK/RESOLVE/PROJECT_FACT, prompts, arch, README, decision file. Tests 439 → 445.

- **Files:** lib/entries.mjs, tests/stub-claude.sh, tests/checks/12-journal-pure-e4-entrys.sh, tests/checks/38-run-17-gotchas-and-pack-m3.sh, tests/fixtures/check-names.txt, prompts/coding.md, prompts/parts/where-things-go-readonly.md, prompts/parts/where-things-go-override.md, docs/architecture.md, README.md, journal/decisions/2026-10-26-resolved-and-project-facts.md
- **Verified:** lib/check.sh full run green, 445 tests (248 s); the 6 new checks watched failing first (the two stub-run checks and the prompt check against HEAD's entries.mjs/prompts, the long-fact case before its fix); Opus review of the diff: 1 Important fixed (a long project fact was dropped, now cut to its share)
- **Tests:** 439 → 445
- **Dead end:** Promote items as whole strings checked only against the cap/8 share — a fact over ~1000 bytes (or ~80 at cap 1024) never fit and, being filtered out of Discoveries, vanished from every coding pack; items are now cut to the share's room (≥ 32 bytes)
- **Discovery** (affects M3-04): pack() parts may carry a third element, a byte share: an item past it is counted in items left out without stopping the pack; Promote to Gotchas items are {fact, ref} objects cut to the share's room. M3-04's Current rules (cap/4) can reuse the share slot.
- **Discovery** (affects M3-04, M3-05): lib/eval.sh:134 packs from <clone>/.harness/runs/<run>, which passes the CLAUDE.md guard, so an eval probe's context.md includes Promote to Gotchas (and will include Current rules): the plan said probes read none.
- **Question for Michael:** The eval probe's context.md now reads the clone's CLAUDE.md Gotchas (it shows what the session would read). Keep that, or make probes read none as the plan said?
- **Proposed change:** M3-03 step 2 names `logs/NN-<id>.context.md`, but after STUB_RESOLVE=C's 05-C passes there is no later C coding session; the check reads the next session's pack, `logs/<hhmmss>-verify-M2.context.md`, as the plan says.
- *12-M3-03 · claude-opus-5-5*

### 2026-10-26 21:23 · M3-02 · passes

Finish step 3 in prompts/coding.md: one ## Gotchas line (≤160 chars, ends (<run> <date>), 15 max, edit in place, no rewrite). memlint.mjs gains gotchasLines/gotchasDiff (multiset; a replace is ~1) and `gotchas <before> <after>`; driver gotchas() after journal coding notes `<id>: gotchas +a ~e -d`. STUB_GOTCHA flag, arch §7 row, decision file. Tests 435 → 439.

- **Files:** prompts/coding.md, lib/memlint.mjs, lib/driver.sh, tests/stub-claude.sh, tests/checks/38-run-17-gotchas-and-pack-m3.sh, tests/fixtures/check-names.txt, docs/architecture.md, README.md, journal/decisions/2026-10-26-gotchas-in-place.md
- **Verified:** 4 new checks in tests/checks/38 written first, all 4 FAIL, then PASS; full bash tests/run.sh 439/439 (248 s) and lib/check.sh green, 439 tests; bash -n on driver.sh, stub-claude.sh, check 38; node --check memlint.mjs
- **Tests:** 435 → 439
- **Discovery** (affects M3-03, M3-04): tests/checks/38 runs one stub run `gotcha` (STUB_GOTCHA=B); M3-03/M3-04 checks can add their own runs below it. With KEEP_SCRATCH=1 the stub's sessions.log is at $T/scratch/proj/<run>/sessions.log.
- **Discovery** (affects M3-03): coding.md Finish steps are now 1 suite-verify, 2 suite, 3 Gotchas, 4 entry.json, 5 commit; the M3-03 Promote-to-Gotchas sentence belongs in step 3.
- *11-M3-02 · claude-opus-5-5*

### 2026-10-26 21:11 · M3-01 · passes

Wrote docs/plans/2026-10-26-M3-gotchas-and-pack.md: gotchasLines/gotchasDiff (+a ~e -d, a replace is one edit) and the driver's gotchas() after journal coding; resolved (exact after flattening, later entries only); Promote to Gotchas (coding packs, cap/8); Current rules (last, cap/4, three file shapes); verify cap 16384, failed rows first; stub flags; check names.

- **Files:** docs/plans/2026-10-26-M3-gotchas-and-pack.md
- **Verified:** Each step's terms checked against the plan text; line refs re-grepped (pack lib/entries.mjs:216-269, CLI :314-325, coding loop lib/driver.sh:737-745); check.sh green, 435 tests (cached: plans are outside the key).
- **Tests:** 435 → 435
- **Discovery** (affects M3-04, M4): Real decisions.md stores have three decision-line shapes: `## D7 *default*: …` headings (voice-concierge), `- **D1 · …**` bullets (rane-one-mixxx), `| D24 | … |` table rows (dj-crate-streaming); M3-04's parser and fixtures cover all three.
- **Discovery** (affects M3-03, M3-04): pack CLI must read CLAUDE.md and the decisions store only when the run dir sits at <wt>/.harness/runs/<run>; tests/checks/12 calls `pack` on $T/pk and $T/jr/legacy, whose third parent is outside the throwaway tree.
- **Discovery** (affects M3-02): Gotchas-step text cannot use {{RUN}} (no such prompt variable); the run id is on the `Run:` line under *This run*.
- **Question for Michael:** Promote to Gotchas is in coding packs only (a verify cannot write CLAUDE.md), and a project raising CONTEXT_PACK_BYTES above 16384 does not raise the verify cap: OK as defaults?
- **Proposed change:** M3-03 step 4 should also name `resolved` in prompts/coding.md, and M3-03 should write journal/decisions/<date>-resolved-and-project-facts.md (a behaviour change gets a decision file).
- **Proposed change:** M3-04 step 3's 'byte count may exceed 8192' cannot be observed in a stub run; the plan proves the verify cap with CONTEXT_PACK_BYTES=1024 (verify pack > 1024, coding packs ≤ 1024) instead.
- *10-M3-01 · claude-opus-5-5*

### 2026-10-26 21:06 · verify M2 · passes

All 3 features hold: suite green (435 tests, full run), 37-memory-prompts-m2 15/15 re-run, prompts/templates/docs/decision file read and match each step.

| Feature | Step | What you ran or read | What you saw | Holds |
|---|---|---|---|---|
| M2-01 | 1 | node --check lib/memlint.mjs; read checks 10-19 of 37-memory-prompts-m2 | ok; decisionsStore exported, store prints journal/decisions; dir/file/null checks PASS | yes |
| M2-01 | 2 | cat prompts/parts/where-things-go*.md | both ~7 lines under ## Where things go, {{DECISIONS}} store line, readonly sends to discoveries | yes |
| M2-01 | 3 | read prompt.sh 57-66, check at line 27/31 | appends block when no heading/no CLAUDE.md; once-each and discoveries checks PASS | yes |
| M2-01 | 4 | checks at lines 36 and 40 | heading 0 times with heading; once each with no CLAUDE.md; PASS | yes |
| M2-01 | 5 | grep check-names.txt; bash tests/run.sh memory-prompts | 15 names listed; 15/15 pass; entries.jsonl names checks | yes |
| M2-01 | 6 | init suite output | green, 435 tests | yes |
| M2-02 | 1 | grep initializer.md; routing check line 50 | old phrase absent; Gotchas/discoveries wording present; no D<n>; check PASS | yes |
| M2-02 | 2 | read coding.md, draft-claude-md.md, templates/project/* | Decisions bullet points at block; draft asks block+Gotchas, no test count; template block+empty Gotchas; commented DECISIONS= | yes |
| M2-02 | 3 | read CLAUDE.md, .harness/config.sh, node lib/memlint.mjs store . | block and empty Gotchas present; DECISIONS=journal/decisions; prints journal/decisions | yes |
| M2-02 | 4 | read decision file and M2 entry | Opus review Important finding fixed (read-only override) and recorded in decision file/entry | yes |
| M2-02 | 5 | read journal/decisions/2026-10-26-where-things-go.md | Finding/Choice/Rejected; seven projects, none set DECISIONS=; both accepted risks | yes |
| M2-02 | 6 | init suite output | green | yes |
| M2-03 | 1 | read docs/architecture.md Memory model | 6x4 table, six rules as specified | yes |
| M2-03 | 2 | grep README.md | line 63-64 name block, Gotchas 15 lines in place, DECISIONS=, append only when heading lacking | yes |
| M2-03 | 3 | grep -c Memory model docs/architecture.md | 2; Principles row cites decisions/2026-10-26-where-things-go | yes |
| M2-03 | 4 | init suite output | green | yes |

- *210433-verify-M2 · claude-sonnet-5-5*

### 2026-10-26 21:00 · M2-03 · passes

docs/architecture.md gains a Memory model section (scope × bucket table, rules 1–6) and a Principles row citing decisions/2026-10-26-where-things-go; README names the routing block, Gotchas and DECISIONS=.

- **Files:** docs/architecture.md, README.md
- **Verified:** grep -c 'Memory model' docs/architecture.md = 2; check.sh green, 435 tests
- **Tests:** 435 → 435
- *09-M2-03 · claude-sonnet-5-5*

### 2026-10-26 20:55 · M2-02 · passes

A background wait I had left running for the review was stopped at its time limit. It doesn't matter: the review had already come back and its findings were handled. M2-02 passes. The last commit is `7ec5b20`, pushed. The full suite is green, and tests went from 429 to 435.

- **Files:** .harness/config.sh, CLAUDE.md, journal/decisions/2026-10-26-where-things-go.md, lib/prompt.sh, prompts/coding.md, prompts/draft-claude-md.md, prompts/initializer.md, prompts/parts/where-things-go-override.md, templates/project/CLAUDE.md, templates/project/config.sh, tests/checks/37-memory-prompts-m2.sh, tests/fixtures/check-names.txt
- *08-M2-02 · claude-opus-5-5 · recorded by the harness: entry.json invalid: summary: 417 characters (at most 400)*

### 2026-10-26 20:21 · M2-01 · passes

lib/memlint.mjs: decisionsStore() (DECISIONS= from .harness/config.sh, else docs/decisions.md, else null), storeLine, CLI store/store-line. prompt_render appends prompts/parts/where-things-go.md (coding, initializer) or -readonly.md (verify, retro) unless CLAUDE.md has a `## Where things go` line; no CLAUDE.md gets it too. Decision file written. Tests 420 → 429.

- **Files:** lib/memlint.mjs, lib/prompt.sh, prompts/parts/where-things-go.md, prompts/parts/where-things-go-readonly.md, tests/checks/37-memory-prompts-m2.sh, tests/fixtures/check-names.txt, journal/decisions/2026-10-26-where-things-go.md, docs/architecture.md
- **Verified:** bash tests/run.sh 37-memory: 1/9 before (all of decisionsStore's checks failed on the missing memlint.mjs, and 'where things go: … carry the block once when CLAUDE.md lacks the heading', '… read-only variant …', '… with no CLAUDE.md … once each, the store from DECISIONS=' failed; the heading-present 0-times check passed vacuously), 9/9 after; read the rendered blocks of a KEEP=1 run (wt1 coding, wt3 verify, wt1 retro); node --check, bash -n; full suite via check.sh green, 429 tests incl. the check-names conformance check.
- **Tests:** 420 → 429
- **Dead end:** committing to $T/proj and pushing between stub runs — rejected: each run merges into origin main; `git pull -q --ff-only origin main` first
- **Discovery** (affects M2-02): The three-prompt checks grep -c `## Where things go`: any template line quoting that heading counts. M2-02's coding.md Decisions bullet must name the block without the `## ` prefix (e.g. 'the Where things go block below') or the counts go to 2.
- **Discovery** (affects M2-02, M2-03): journal/decisions/2026-10-26-where-things-go.md exists already with the seven-project census and both accepted risks; M2-02 edits it in place (initializer/coding/template wording) rather than creating it.
- **Discovery** (affects M3, M4): `node lib/memlint.mjs store-line <wt>` gives the block's {{DECISIONS}} phrase; decisionsStore returns {path, kind: dir|file, exists} or null. M3 and M4 import it.
- *07-M2-01 · claude-opus-5-5*

### 2026-10-26 20:10 · verify M1 · passes

All six M1 features hold. Full suite green (420 tests, init run); re-ran harness backlog list/set/import/errors against a throwaway ledger, bash -n and node --check, read plan, decision, review, README, architecture, prompts, stub and checks.

| Feature | Step | What you ran or read | What you saw | Holds |
|---|---|---|---|---|
| M1-01 | 1 | read the named file/check assertions; suite 420/420 green; bash -n and node --check | Output and file contents match the step; matching check in tests/checks/35/36 passes in the full suite | yes |
| M1-01 | 2 | read the named file/check assertions; suite 420/420 green; bash -n and node --check | Output and file contents match the step; matching check in tests/checks/35/36 passes in the full suite | yes |
| M1-01 | 3 | read the named file/check assertions; suite 420/420 green; bash -n and node --check | Output and file contents match the step; matching check in tests/checks/35/36 passes in the full suite | yes |
| M1-01 | 4 | read the named file/check assertions; suite 420/420 green; bash -n and node --check | Output and file contents match the step; matching check in tests/checks/35/36 passes in the full suite | yes |
| M1-01 | 5 | read the named file/check assertions; suite 420/420 green; bash -n and node --check | Output and file contents match the step; matching check in tests/checks/35/36 passes in the full suite | yes |
| M1-02 | 1 | read the named file/check assertions; suite 420/420 green; bash -n and node --check | Output and file contents match the step; matching check in tests/checks/35/36 passes in the full suite | yes |
| M1-02 | 2 | read the named file/check assertions; suite 420/420 green; bash -n and node --check | Output and file contents match the step; matching check in tests/checks/35/36 passes in the full suite | yes |
| M1-02 | 3 | read the named file/check assertions; suite 420/420 green; bash -n and node --check | Output and file contents match the step; matching check in tests/checks/35/36 passes in the full suite | yes |
| M1-02 | 4 | read the named file/check assertions; suite 420/420 green; bash -n and node --check | Output and file contents match the step; matching check in tests/checks/35/36 passes in the full suite | yes |
| M1-02 | 5 | read the named file/check assertions; suite 420/420 green; bash -n and node --check | Output and file contents match the step; matching check in tests/checks/35/36 passes in the full suite | yes |
| M1-02 | 6 | read the named file/check assertions; suite 420/420 green; bash -n and node --check | Output and file contents match the step; matching check in tests/checks/35/36 passes in the full suite | yes |
| M1-02 | 7 | read the named file/check assertions; suite 420/420 green; bash -n and node --check | Output and file contents match the step; matching check in tests/checks/35/36 passes in the full suite | yes |
| M1-03 | 1 | bin/harness backlog list/set/import/bad args with a temp HARNESS_LEDGER, LEDGER_COMMIT=0; read check names in 36-run-16 file | Output and file contents match the step; matching check in tests/checks/35/36 passes in the full suite | yes |
| M1-03 | 2 | bin/harness backlog list/set/import/bad args with a temp HARNESS_LEDGER, LEDGER_COMMIT=0; read check names in 36-run-16 file | Output and file contents match the step; matching check in tests/checks/35/36 passes in the full suite | yes |
| M1-03 | 3 | bin/harness backlog list/set/import/bad args with a temp HARNESS_LEDGER, LEDGER_COMMIT=0; read check names in 36-run-16 file | Output and file contents match the step; matching check in tests/checks/35/36 passes in the full suite | yes |
| M1-03 | 4 | bin/harness backlog list/set/import/bad args with a temp HARNESS_LEDGER, LEDGER_COMMIT=0; read check names in 36-run-16 file | Output and file contents match the step; matching check in tests/checks/35/36 passes in the full suite | yes |
| M1-03 | 5 | bin/harness backlog list/set/import/bad args with a temp HARNESS_LEDGER, LEDGER_COMMIT=0; read check names in 36-run-16 file | Output and file contents match the step; matching check in tests/checks/35/36 passes in the full suite | yes |
| M1-03 | 6 | read the named file/check assertions; suite 420/420 green; bash -n and node --check | Output and file contents match the step; matching check in tests/checks/35/36 passes in the full suite | yes |
| M1-04 | 1 | read the named file/check assertions; suite 420/420 green; bash -n and node --check | Output and file contents match the step; matching check in tests/checks/35/36 passes in the full suite | yes |
| M1-04 | 2 | read the named file/check assertions; suite 420/420 green; bash -n and node --check | Output and file contents match the step; matching check in tests/checks/35/36 passes in the full suite | yes |
| M1-04 | 3 | read the named file/check assertions; suite 420/420 green; bash -n and node --check | Output and file contents match the step; matching check in tests/checks/35/36 passes in the full suite | yes |
| M1-04 | 4 | read the named file/check assertions; suite 420/420 green; bash -n and node --check | Output and file contents match the step; matching check in tests/checks/35/36 passes in the full suite | yes |
| M1-04 | 5 | read the named file/check assertions; suite 420/420 green; bash -n and node --check | Output and file contents match the step; matching check in tests/checks/35/36 passes in the full suite | yes |
| M1-04 | 6 | read the named file/check assertions; suite 420/420 green; bash -n and node --check | Output and file contents match the step; matching check in tests/checks/35/36 passes in the full suite | yes |
| M1-04 | 7 | read the named file/check assertions; suite 420/420 green; bash -n and node --check | Output and file contents match the step; matching check in tests/checks/35/36 passes in the full suite | yes |
| M1-05 | 1 | read the named file/check assertions; suite 420/420 green; bash -n and node --check | Output and file contents match the step; matching check in tests/checks/35/36 passes in the full suite | yes |
| M1-05 | 2 | read the named file/check assertions; suite 420/420 green; bash -n and node --check | Output and file contents match the step; matching check in tests/checks/35/36 passes in the full suite | yes |
| M1-05 | 3 | read the named file/check assertions; suite 420/420 green; bash -n and node --check | Output and file contents match the step; matching check in tests/checks/35/36 passes in the full suite | yes |
| M1-05 | 4 | read the named file/check assertions; suite 420/420 green; bash -n and node --check | Output and file contents match the step; matching check in tests/checks/35/36 passes in the full suite | yes |
| M1-05 | 5 | read the named file/check assertions; suite 420/420 green; bash -n and node --check | Output and file contents match the step; matching check in tests/checks/35/36 passes in the full suite | yes |
| M1-05 | 6 | read the named file/check assertions; suite 420/420 green; bash -n and node --check | Output and file contents match the step; matching check in tests/checks/35/36 passes in the full suite | yes |
| M1-06 | 1 | read the named file/check assertions; suite 420/420 green; bash -n and node --check | Output and file contents match the step; matching check in tests/checks/35/36 passes in the full suite | yes |
| M1-06 | 2 | read the named file/check assertions; suite 420/420 green; bash -n and node --check | Output and file contents match the step; matching check in tests/checks/35/36 passes in the full suite | yes |
| M1-06 | 3 | read the named file/check assertions; suite 420/420 green; bash -n and node --check | Output and file contents match the step; matching check in tests/checks/35/36 passes in the full suite | yes |
| M1-06 | 4 | read the named file/check assertions; suite 420/420 green; bash -n and node --check | Output and file contents match the step; matching check in tests/checks/35/36 passes in the full suite | yes |
| M1-06 | 5 | read the named file/check assertions; suite 420/420 green; bash -n and node --check | Output and file contents match the step; matching check in tests/checks/35/36 passes in the full suite | yes |

- *200939-verify-M1 · claude-sonnet-5-5*

### 2026-10-26 20:05 · M1-06 · passes

Opus review of the M1 diff (1065 lines): 0 Critical, 5 Important, 9 Minor; no second round. Fixed all 5 Important and Minor 6-8 test-first: forward-only import, one-line 200-char titles, a cap keeping every id·status, JSONL skip + {more:n}, LEDGER_COMMIT=1 run check, no symlinked proposals, unlistable store noted. Stray .tmp removed. Tests 413 → 420.

- **Files:** lib/backlog.mjs, lib/driver.sh, tests/stub-claude.sh, tests/checks/35-backlog-pure-m1.sh, tests/checks/36-run-16-retro-backlog.sh, tests/fixtures/check-names.txt, docs/plans/2026-10-26-M1-review.md, journal/decisions/2026-10-26-retro-backlog.md, docs/architecture.md, README.md, .tmp (removed)
- **Verified:** Each new check red then green: `backlog import: a re-import keeps a later status and the links the row lacks (status never moves back)`, `backlog merge: a title's newlines and control characters fold to one space, at most 200 characters`, `backlog validate: the why line of a huge bad id stays under 300 bytes`, `backlog list: past --max-bytes every row keeps its id and status, full lines first`, `backlog list --jsonl: a row too big is skipped, not the rest; a cut list ends with a {"more": n} line`, `backlog run: a symlinked retro-proposals.json is not followed, and a store that will not list is noted`; `backlog run: with LEDGER_COMMIT=1 the run's ledger commit carries retro-backlog.jsonl with its proposal` red with the paths+= line removed, green restored. bash -n on the six named files, node --check lib/backlog.mjs. check.sh green in 229 s, 420 tests.
- **Tests:** 413 → 420
- **Dead end:** noting an unlistable store before the retro session — restrict reverts harness-log.md edits made after rstart; the note is now written after restrict
- **Discovery** (affects run): Any note() written in retro() between rstart and restrict is reverted with the retro's edits: write it after restrict (as S_NOTES are).
- **Discovery** (affects M2, M3): backlog.mjs exports oneLine (whitespace and control characters folded, 200 chars): reuse it for any retro-written text that reaches a prompt.
- **Question for Michael:** Review finding 10 (left): `harness backlog set/import` can race lib/sync.sh's rebase since sync takes no ledger.lock. Add it to the backlog (e.g. `sync-ledger-lock`) or fix in a later run?
- *06-M1-06 · claude-opus-5-5*

## Older entries (in full in progress-archive.md)

- 2026-10-26 19:47 · M1-05 · passes · M1-05 passes, in commit `8623944`, pushed to the run branch. - **Retro:** its prompt now has a `## B… ([in full](progress-archive.md))
- 2026-10-26 19:39 · M1-04 · passes · retro() copies the retro's retro-proposals.json to scratch before restrict (skipped from the reverte… ([in full](progress-archive.md))
- 2026-10-26 19:29 · M1-03 · passes · Added lib/backlog.sh (harness backlog [list] | set | import, writes under flock on $STATE_ROOT/ledge… ([in full](progress-archive.md))
- 2026-10-26 19:23 · M1-02 · passes · Added lib/backlog.mjs (pure exports STATUSES, parseRows, formatRows, validateProposals, mergeProposa… ([in full](progress-archive.md))
- 2026-10-26 19:16 · M1-01 · passes · Wrote docs/plans/2026-10-26-M1-retro-backlog.md: row schema and defaults, lib/backlog.mjs's exported… ([in full](progress-archive.md))
- 2026-10-26 19:12 · init · passes · 23 features: M1 6 (plan, backlog.mjs, CLI + seed, retro emits and driver merges, retro prompt + debr… ([in full](progress-archive.md))
