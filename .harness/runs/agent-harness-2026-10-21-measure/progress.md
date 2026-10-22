# Progress — run `agent-harness-2026-10-21-measure` (agent-harness)

What this file is: the run's log for Michael's phone and for every fresh session. **Newest entry first**, directly
below this header. `feature_list.json` is the plan: array order is priority, `after` is what a feature truly needs,
and the harness gives each session the first feature that isn't passing whose dependencies pass. Steer from
`INBOX.md` on this branch (first line `status: run|pause|stop`; answers under `## Answers`; the harness pulls it
before every session). The brief for this run is `brief.md`; the spec is `docs/specs/2026-10-20-measure-then-memory.md`.

### 2026-10-22 03:58 · E4-07 · passes

- **What changed:** `docs/plans/2026-10-21-E4-review.md` (12 findings, 2 Important). Fixes: `lib/entries.mjs` has one reader, `readEntries`, which gives null for any line that isn't a valid entry and keeps line numbers, so render and pack never crash on a damaged line. `ingest` adds a missing final newline before appending. A summary can't open a code fence or HTML block, and the pack's title is capped. `lib/driver.sh` `journal()` restores `entries.jsonl` and `progress-archive.md` when a session edited them (note `<id>: <file> edited by the session; restored`), and a refused coding session's minimal entry is `not yet`. `context()` commits context.md alone. `pr_body` matches `verify <m>` on a word boundary. `vcount` lost its dead progress.md fallback. `prompts/retro.md` points at the archive and entries.jsonl. Also updated: the decision file `journal-single-writer` (amended), architecture §3/§4/§7 and README.
- **Tests 222 → 226:** `entries.mjs: a damaged journal line is skipped, never fused or fatal`, `a refused session's minimal entry is not yet…`, `a session's edits to the journal are restored`, `harness merge leaves a legacy record as it was; its PR quotes the legacy verify entry` (new run `lgm`). RED 222/226 (the last one under a temporary mutation), then 226/226. `check.sh` green in 421 s.
- **Step 2 by command** (scratch `step2/legacy.sh`): `harness merge` on a legacy record leaves progress.md byte-identical with no entries.jsonl; a `status: stop` continue leaves progress.md byte-identical (the journal starts, per plan §14); `pr_body` quotes the legacy verify M2 entry; `harness report` works (it reads summary.json).
- **Proposed changes:** (F10) verify's evidence count should count distinct steps from the newest verify entry and refuse a hold on any `holds: false` row; this predates E4 and is Michael's call. (F8) `eval run` should build the probe pack with the run's own `CONTEXT_PACK_BYTES` if a project ever sets it.
- **Not covered:** `pr_body` reading the archive past 15 entries; the stale-entry.json and append-failure paths (by hand only).
- **Questions:** none.

### 2026-10-22 09:00 · E4-06 · passes

- **What changed:** docs only. `docs/architecture.md`: §3 lists `lib/entries.mjs` (and the suite count is 222); §4 has rows for entry.json, entries.jsonl and context.md; §5's flow shows context.md before coding and verify and the ingest/render after each session; §10 lists `CONTEXT_PACK_BYTES` and the prompt-assembly paragraph names context.md. `README.md` steering: progress.md is rendered from the journal and is still the phone view; sessions write entry.json; context.md read first. `evals/NEXT.md`: what the E4 comparison should show (orientation and context peak down, probe score up, pass rate not worse) and that probes paste the pack.
- **Tests 222 → 222:** no code change; `check.sh` green in 363 s.
- **Step 4 note:** D-H39, D-H40 and D-H41 exist once each as decision files (`decisions/2026-10-22-journal-single-writer`, `-rendered-progress`, `-context-pack`), not in `journal/decisions.md`, which CLAUDE.md closes at D-H34. **Proposed change:** reword that step to say "decision files".
- **Not covered:** architecture §4 still has no `progress-archive.md` row of its own (it sits in the progress-log row, which was already there).
- **Questions:** none.

### 2026-10-22 08:10 · E4-05 · passes

- **What changed:** `lib/entries.mjs` has a pure `pack(entries, { feature, list, answers, cap })` and the `pack <run dir> <feature> [<cap>]` verb (plan §5). It has five parts in strict priority order, items of at most 1024 bytes each ending `→ entries.jsonl:<line>` (real file lines, even past a bad line) or `→ INBOX.md`, and a `_<k> items left out_` line. `lib/config.sh`: `CONTEXT_PACK_BYTES=8192`. New `context()` in `lib/driver.sh`: it runs before every coding session (after the init) and every verify round, notes `context.md for C: N bytes[, k items left out]` and commits `HARNESS: context pack for <id>`. `session()` copies the pack to `logs/*.context.md`. If the pack fails, context.md points at the full record instead. `prompts/coding.md` and `verify.md` open their bearings with `Read context.md first; …`; coding step 2 no longer mentions progress.md; parts/run.md lists context.md. `lib/eval.sh` (plan §9): `eval run` saves the pack of the task's next feature and copies entries.jsonl, and `eval probes` pastes the pack after the probe prompt. New decision file: `decisions/2026-10-22-context-pack` (D-H41).
- **Tests 219 → 222:** `entries.mjs: the pack keeps a feature's dead end under a flood and respects the cap`, `context.md carries the earlier attempt's dead end` and `eval probes: the probe reads the run's context pack` (the third is the plan §10 one). All three failed on the pre-change tree with the new tests (208/222 in a scratch copy; that copy's other 11 eval failures come from the copy itself, a fresh repo).
- **Verified:** `check.sh` green in 365 s, 222/222.
- **Review fixes:** an Opus review found no Critical and 2 Important problems, both fixed. A typo'd cap (`8k` gives NaN) lifted the cap: the CLI now refuses a cap that isn't a whole number ≥ 1024, so the driver falls back. The unit cases were too loose: a second case now covers the `after` milestone expanding, dedupe, the strict cut, a milestone target and 4-byte characters at four caps. Minor fixes: left-out entries are counted once; a discovery may name the feature's own milestone; `## Answers` is matched by prefix as `answers_hash` does; the pack is committed at once (a session committing only its files left a WIP behind); the probe check asserts line order.
- **Kept as the plan has it:** the answers item isn't held to 1024 bytes (Michael's word outranks discoveries; recorded in D-H41). A milestone pack's "What it builds on" is empty, because its features are already in part 1.
- **Next session (E4-06):** docs. Architecture §3–§5 and §10 and README don't mention context.md, `CONTEXT_PACK_BYTES` or `logs/*.context.md` yet. evals/NEXT.md: the probes now see context.md for refs from this commit on.
- **Questions:** none new. **Proposed change:** none.

### 2026-10-22 06:40 · E4-04 · passes

- **What changed:** `journal()` in `lib/driver.sh` now ends with `entries.mjs render`, so progress.md and progress-archive.md are rewritten after every append (initializer, coding, verify). The new `vcount` counts verify entries in `entries.jsonl` (plan §3.5); `F evidence` reads the rendered file. `pr_body` reads the archive and now matches `verify <m> ` exactly (M1 no longer matches M10). A legacy start-up block runs after `harness merge`'s exit: it copies progress.md to progress-archive.md, creates an empty `entries.jsonl`, notes `journal started; progress.md kept as progress-archive.md` and commits. Prompts: coding, verify, initializer and both policies no longer mention a progress entry (live-staged's rollback log goes to `entry.json`). parts/run.md lists the new files. The stub stops writing progress.md. New decision file: `decisions/2026-10-22-rendered-progress` (D-H40). README and architecture: the run-record and state rows.
- **Tests 217 → 219:** `progress.md is rendered from the journal` and `a legacy run is untouched, then continued into a journal`. Both failed first (217/219).
- **Verified:** `check.sh` green in 353 s, 219/219.
- **Review fixes:** an Opus review found no Critical problems and 2 Important ones, both fixed. The policy prompts still said "progress entry" and "top of progress.md". The legacy check never rendered the converted record; it now renders once and asserts the archive ends with the marker plus the old bytes and the header is `# progress`. Minor fixes: a minimal verify entry is now `not yet`, not "passes" from the untouched list (this amends D-H39; added to run 11's check, watched failing at 218/219); `vcount` defaults to 0; README updated.
- **Next session (E4-05):** the context pack. parts/run.md doesn't list `context.md` yet, so add it with the pack. coding.md step 2 still says "the newest entries in progress.md"; E4-05 replaces it with the context.md line.
- **Not covered (for E4-07):** a merge-only start-up on an unconverted legacy record (plan §14 a). Run 14 can't test it, because `harness merge` there would merge its v2 tags first. Also no check yet forces `pr_body` onto the archive (demo has fewer than 15 entries). And `F evidence` counts rows but ignores `holds: false` (predates E4).
- **Questions:** none new. **Proposed change:** none.

### 2026-10-22 05:05 · E4-03 · passes

- **What changed:** `lib/entries.mjs` gets the `ingest` verb and two pure exports, `journalEntry` and `stamp`. `lib/driver.sh` gets `journal()`. It runs right after the `WIP` commit (coding, init) and after `restrict` (verify), so it comes before the limit branches and `F repair`. It validates `entry.json` and stamps `at`/`session`/`model`, then appends the line to `entries.jsonl` and deletes `entry.json`. If the file is missing or invalid, it writes the note `<id>: entry.json missing|invalid (…); recorded a minimal entry` and records a minimal entry built from git and the final message. `prompts/coding.md`, `verify.md` and `initializer.md` now ask for `entry.json` (with the example), and still ask for progress.md. The stub writes entries, including C's dead end and `STUB_BAD_ENTRY`. New decision file: `decisions/2026-10-22-journal-single-writer` (D-H39).
- **Tests 215 → 217:** `entries: the driver appends each session's entry` and `a malformed entry is recorded as minimal and the run goes on`. Both failed first (215/217). The first check was then tightened and watched failing again on the demo run.
- **Verified:** `check.sh` green in 352 s, 217/217. I also ran `ingest` by hand: missing, `{not json`, wrong feature, extra keys dropped, and the read-only `entries.jsonl` case (exit 1, `entry.json` left).
- **Review fixes:** an Opus review found 1 Important problem, now fixed. Verify tagged the milestone before the journal's changes were committed, so the merged tree kept `entry.json` and lacked the verify's line. Verify now commits `HARNESS: journal verify <m>` right after `journal`. Minor fixes: a stale `entry.json` is moved aside with a note before any session, minimal `files` use `core.quotePath=false`, and the init prompt states the 2000-character header cap.
- **Next session (E4-04):** journal entries now accumulate alongside the sessions' own progress.md. E4-04 renders progress.md from them and drops the progress.md instructions from the prompts and the stub. The badentry check expects `B-badentry.txt` rather than `work-B.txt`, because main already has `work-B.txt` from run demo with the same content (plan §10 amended). Not fixed: after a usage limit the retried session reuses the transcript name (`n` is given back), so two entries can share `session`. That predates this feature.
- **Not tested:** the failed-append path (the note, then `entry.json` moved to `$SCRATCH/entry-failed-*.json`) has no suite check, because it needs an unwritable `entries.jsonl` mid-run. I checked it by hand only.
- **Questions:** none new. **Proposed change:** none.

### 2026-10-22 04:10 · E4-02 · passes

- **What changed:** new `lib/entries.mjs` (plan §1, §2, §4). It has the pure functions `validate` (one `<field>: <what>` error per problem, plus a feature/kind match check), `validateText` (`not JSON: …`), `normalize`, `minimal` (399 code points + `…`, or `(no final message)`), `renderEntry`, `renderProgress(entries, { full: 15, header })`, `renderArchive(entries, header, legacy)`, `headerOf` and `legacyOf`, and the CLI verbs `validate` and `render`. `render` writes through a temp file and a rename, and does nothing when there is no `entries.jsonl`. Entry text is flattened onto one line. A line starting `### `, `|` or `<!-- harness:` gets a leading `\`, so no entry can fake a header, an evidence row or the legacy marker. No driver change.
- **Tests 213 → 215:** `entries.mjs: validate accepts the schema and names what is wrong` and `entries.mjs: progress renders 15 in full and the rest as archive lines`. Together they cover the unit cases plus the CLI: `validate` on `{not json` and on `outcome: "done"`, and `render` on a legacy dir (left untouched) and on a dir with a journal.
- **Verified:** both checks failed first (module missing). Two mutations each turned the render check red: no guard, and a guard without `|`. The legacy tail survived two renders byte for byte (checked by hand in scratch). An Opus review of the diff found 2 Minor problems, both fixed. An init `header` could fake a `### … verify M1` line through `\r`/U+2028, because `features.mjs`'s `/^### /m` breaks lines there too; `headerOf` now turns those into `\n`. And the render check didn't actually test the row escaping. The check was tightened and watched failing first. `check.sh` green in 316 s, 215/215.
- **Next session (E4-03):** add the `ingest` verb (reuse `validateText`, `normalize` and `minimal`; stamp `at`/`session`/`model`/`minimal`, which `normalize` keeps), then `journal()` in the driver. `renderEntry` takes no `line` argument; the plan's §2 table lists one, but nothing in the rendered shape uses it.
- **Proposed change:** none. **Questions:** none new (the defaults in plan §15 stand).

### 2026-10-22 03:20 · E4-01 · passes

- **What changed:** `docs/plans/2026-10-21-E4-memory.md` (only file; first line `Milestone base: 0e2cc33…`). It covers the entry schema (§1: session fields, stamped `at`/`session`/`model`, the minimal entry), the `lib/entries.mjs` API and CLI verbs `validate`/`ingest`/`render`/`pack` (§2), and `journal()` with its exact driver points: coding after the `WIP` commit and before `F repair`; verify after `restrict`; the initializer after its `WIP` commit (§3). It also has the rendered shapes (§4), the pack algorithm (§5, `CONTEXT_PACK_BYTES=8192`, `→ entries.jsonl:<n>`), the legacy rule (§6), prompts, stub, checks 213 → 222 (§10) and D-H39/40/41 (§13).
- **Verified:** every item of step 1 checked by grep against the plan. An Opus review against the code found 4 Important and 6 Minor problems, all fixed in the plan. The main ones: the verify count now comes from `entries.jsonl`, `pr_body` reads the archive, and the pack scans verify rows. `check.sh` green, 213/213.
- **Next session (E4-02):** builds §1, §2 (pure functions plus `validate`/`render`) and §4. No driver change.
- **Proposed change (E4-04 step 1):** verify's `before`/after count should read `entries.jsonl`, not the rendered progress.md (plan §3.5). Otherwise an earlier verify entry dropping out of the 15, or a just-continued legacy run, looks like "no new verify entry" and wastes an escalated verify. Also, `pr_body` should read `progress-archive.md`.
- **Proposed change (E4-07 step 2):** "a start-up that ends at once" can only mean `harness merge`. E4-04 needs `harness continue` on a finished legacy run to start the journal (plan §14).
- **Questions for Michael (defaults in plan §15):** refused sessions get a journal entry; an entry's outcome is the session's claim; the eval probe gets context.md pasted in (§9, needed for E4's probe score to move at all). Overrule in INBOX.md if any is wrong.

### 2026-10-22 · verify E3

check.sh: green. `bash tests/run.sh` re-run by me: 213/213, 0 FAIL; `bash -n` on lib/*.sh tests/*.sh bin/*, `node --check` on lib/*.mjs clean. Note: the specs' "journal/decisions.md has D-H36/37/38" is satisfied by the decision files CLAUDE.md prescribes (that file is closed at D-H34).

| Feature | Step | What you ran or read | What you saw | Holds |
|---|---|---|---|---|
| E3-01 | 1 | read docs/plans/2026-10-21-E3-prompts.md | line 1 `Milestone base: 29b3d67…` (valid commit); §1 section order, §3 fixed first lines + `Feature:`/`Milestone:` stub lines, §0 debrief finding (nothing changes), §8 changed check `brief, rules and policy in the prompt`, §5 `logs/NN-<id>.prompt.md`, §7 exact clock wording, §6 40-line rule, §11 D-H36/37/38 | yes |
| E3-01 | 2 | `git show --stat f1a350a`; full suite | plan file is the only non-bookkeeping file (plus feature_list/progress the harness edits); suite 213/213 | yes |
| E3-02 | 1 | read lib/prompt.sh `prompt_render`, prompts/parts/rules.md, rendered prompt of this session | no `Project rules (CLAUDE.md)` paste; `# Project rules` + one line naming `CLAUDE.md`; `.harness/project.md` still passed when present; lib/debrief.sh untouched by the E3 diff | yes |
| E3-02 | 2 | tests/run.sh:354-355; suite output | `coding prompt names CLAUDE.md but doesn't paste it` asserts `grep -q CLAUDE.md` and `! grep -qx rules` on proj/demo/prompt-coding.md; PASS. `brief, rules and policy in the prompt` updated to `# Project rules` + `` `CLAUDE.md` ``; PASS | yes |
| E3-02 | 3 | prompt.sh `tail -n 40` + `full output:`; tests/run.sh:586 | check `init output is capped at 40 lines with the log path` (INIT_CMD `seq 1 100`): exactly 41 lines, last = `full output: …/init.out`, the 40 equal tail of init.out, has 100, lacks 1; PASS | yes |
| E3-02 | 4 | `ls journal/decisions`; read no-double-claude-md and clock-and-bounded-init-output; commit 49fb29d | both checks added with the change (commit 49fb29d, 206→208); D-H36 and D-H38's init-output half exist as decision files (journal/decisions.md is closed per CLAUDE.md); suite 213/213 | yes |
| E3-03 | 1 | head -3 of prompts/{coding,verify,initializer,retro}.md; grep `{{`; prompts/parts/run.md | first lines `# Coding session`, `# Verify session`, `# Initializer session`, `# Retro`; no placeholders before `{{SECTIONS}}`; run values in parts/run.md after policy; session ids/clock/init output after `# This session` | yes |
| E3-03 | 2 | read tests/stub-claude.sh:32-107 | `case $first` matches exact first lines; id/milestone read by awk only below `# This session` from `Feature: \`` / `Milestone:`; full suite 213/213 | yes |
| E3-03 | 3 | lib/driver.sh `session()` line 174; tests/run.sh:356-364; suite | `cp prompt.md ${3%.jsonl}.prompt.md`; check `two coding prompts share a byte-identical prefix that includes the policy`: cmp offset of A vs B > offset of `Policy: build-only` (and > `# This session`); PASS | yes |
| E3-03 | 4 | `ls journal/decisions`; read static-first-prompts.md; suite | decision file for D-H37 exists; suite ends 213/213 | yes |
| E3-04 | 1 | lib/driver.sh `clock()` and call sites (lines 275, 531) | HARNESS_CLOCK set for coding (`attempt N of MAX_ATTEMPTS`) and verify (`verify round N of MAX_VERIFY_ROUNDS`) with now, run elapsed/total, deadline, budget, turns, timeout; templates place `{{CLOCK}}` in the This session part | yes |
| E3-04 | 2 | tests/run.sh:366-368; suite | check `the prompt says the time, the budget and the attempt`: C's later prompt matches the full line incl. `$20 budget, 250 turns`, `ends HH:MM`, `attempt 2 of 2`; exactly one `*-verify-M1.prompt.md` has `verify round 2 of 2`; PASS | yes |
| E3-04 | 3 | read clock-and-bounded-init-output.md (clock half); suite | D-H38 clock half documented; suite 213/213 | yes |
| E3-05 | 1 | read docs/plans/2026-10-21-E3-review.md | F1–F10 each with severity and resolution; no Critical/Important; minors fixed with RED→GREEN mutations recorded (207/213 then 213/213). Reviewer being an Opus subagent is stated there; I can't re-observe it | yes |
| E3-05 | 2 | read docs/architecture.md §10 (lines 254-280) and README.md:54,76 | Prompt assembly lists static → policy → run-level → per-session, fixed first lines, one CLAUDE.md line, clock line, 40-line init output; What a project provides says loaded by Claude Code, named once; README row and steering section match | yes |
| E3-05 | 3 | `ls journal/decisions`; grep D-H3[6-8] | one file each for D-H36, D-H37, D-H38 (clock-and-bounded-init-output covers 38); journal/decisions.md itself has none by CLAUDE.md's rule | yes |
| E3-05 | 4 | `bash -n` on lib/*.sh tests/*.sh bin/*; `node --check lib/*.mjs`; `bash tests/run.sh` | no errors; 213/213 checks passed | yes |

### 2026-10-22 00:40 · E3-05 · passes

- **What changed:** an Opus review of `E3.diff` (29b3d67..HEAD) found no Critical or Important issues and ten Minor ones, recorded in `docs/plans/2026-10-21-E3-review.md`. Fixes: the brief is pasted as written (`render.mjs --raw` now covers only the next file, so a `{{X}}` in a brief no longer fills session values into the shared prefix); sections are one blank line apart; `clock` is simpler; the initializer's wording on where the brief is; architecture §3 row and §10 **Prompt assembly** rewritten as the numbered order; README steering gets **What a session reads**. The prefix, clock and init-output checks are tightened. `decisions/2026-10-21-static-first-prompts` amended.
- **Tests 211 → 213:** `render.mjs: --raw applies to the next file only` and `a brief is pasted as written: its {{X}} isn't filled` are new.
- **Verified:** one RED run with three temporary mutations (`{{CLOCK}}` in parts/run.md, ` timeout` dropped, `tail -n 5`) went 207/213 with exactly the six expected FAIL lines. The first green run failed the reviewer's `grep -qx 62` (off by one: the tail starts at 63), so the check now compares with `init.out`'s tail. By hand on a kept run: tail 40 passes, 5 and 39 fail. After: `check.sh` green in 325 s, 213/213.
- **D-H36/37/38:** each is the title of exactly one file in `journal/decisions/`; `journal/decisions.md` is closed at D-H34 (CLAUDE.md). **Proposed change:** E3-05 step 3 should say `journal/decisions/`, not `journal/decisions.md`.
- **Proposed change (F4, again):** a probe that falls back outside the worktree sees no CLAUDE.md, so it isn't comparable with a pre-E3 baseline. `eval run` should save CLAUDE.md into the result, `probes` should paste it in that fallback, and `compare` should print probe notes.
- **Next:** E3 is ready for verify; E4 comes next.

### 2026-10-22 00:15 · E3-04 · passes

- **What changed:** `lib/driver.sh` gains `clock <tail>` (and `T0`, so `DEADLINE = T0 + HOURS*3600`); coding and verify prompts get `HARNESS_CLOCK`, placed by a `{{CLOCK}}` line after the id lines of *This session* in `prompts/coding.md`/`verify.md`: `Clock: 2026-10-21 23:58 · run 0h00m of 8h, ends 07:58 · this session: $20 budget, 250 turns, 100m timeout · attempt 2 of 2` (verify: `verify round 2 of 2`). Initializer and retro get none. `lib/prompt.sh` run as a command (eval probes) writes `Clock: <now> · outside a run (no deadline, budget or attempt)` rather than a blank line. Decision: clock half appended to `decisions/2026-10-21-clock-and-bounded-init-output` (D-H38); architecture §10 names the line.
- **Tests 210 → 211:** new `the prompt says the time, the budget and the attempt` (05-C.prompt.md: `attempt 2 of 2`, `$20 budget`, `250 turns`, `ends HH:MM`; exactly one `*-verify-M1.prompt.md` with `verify round 2 of 2`). `noinit` in the probe check now also drops `^Clock: ` lines (probe and driver clocks differ by design).
- **Verified:** the check failed first (210/211, no clock line). After: 211/211 twice (`bash tests/run.sh`, then `check.sh` green in 317 s). In a kept run: 01-A/02-B/04-C attempt 1, 03-A and 05-C attempt 2 (03-A is the verifier's re-queue), verify M1 rounds 1 and 2, M2 round 1; 00-init and the retro have no Clock line. `T0`/`DEADLINE` formatting checked by hand: 8h → `of 8h`, a DEADLINE_AT cut → `of 6h40m`.
- **Next session (E3-05):** the clock is the one place two prompts of a run differ besides ids and init output; the shared prefix check is untouched. No `harness-log.md` note for the line (the prompt copies are the record; reasoning in the decision file).
- **Proposed change:** none.

### 2026-10-22 02:45 · E3-03 · passes

- **What changed:** coding, verify and initializer templates start with a fixed line (`# Coding session` …) and a static part with no placeholders; a `{{SECTIONS}}` line marks where `prompt_render` puts the policy, then new `prompts/parts/run.md` (*This run*: run id, worktree, branch, run dir, port, scratch, suite, spec, `none` when empty), the brief, the CLAUDE.md line, `.harness/project.md`; *This session* (`` Feature: `<id>` ``/`Milestone:`, or `Milestone:`/`Features:`; `Earlier runs' feature sizes:` for the initializer; init output) comes last. Retro: `# Retro`, run on line 3. `render.mjs` exports a pure `assemble()`. `tests/stub-claude.sh` matches first lines exactly and reads id/milestone below `# This session`. `session()` copies each prompt to `logs/<log>.prompt.md`; `summary.mjs` now matches `NN-<id>.jsonl` exactly. Decision: `decisions/2026-10-21-static-first-prompts` (D-H37). architecture §10 prompt assembly, §4 transcripts row, component and extension rows updated.
- **Tests 208 → 210:** new `two coding prompts share a byte-identical prefix that includes the policy` and `render.mjs: assemble puts the sections at the {{SECTIONS}} line`; updated `eval probes: the probe prompt is the driver's coding prompt` (first line + `Feature: \`T2b\``).
- **Verified:** the prefix check failed first (208/209, with the prompt copies in place). After: `check.sh` green in 315 s, 210/210. In a kept suite run, 01-A vs 02-B first differ at byte 6413 (line 119, `Feature:`), policy at 5084, brief 6187, `# This session` 6386.
- **Next session (E3-04):** put `{{CLOCK}}` after the id lines in coding.md/verify.md's *This session* part; the `C` second-session prompt is `logs/05-C.prompt.md` in run demo, verify ones `logs/*-verify-M1.prompt.md`.
- **Gotcha:** the eval checks run `eval run --harness HEAD`, i.e. the *committed* driver with the working-tree stub. A stub change that needs new templates fails 7 eval checks until it is committed. Commit, then run the suite.
- **Proposed change (E3-05):** sections are still joined with a double blank line (titled sections end in `\n`, then `\n\n`), as before; harmless, could be trimmed in the review.

### 2026-10-22 01:40 · E3-02 · passes

- **What changed:** `lib/prompt.sh` `prompt_render` no longer pastes CLAUDE.md. When the worktree has one, it passes the new `prompts/parts/rules.md` (`# Project rules` and one line saying Claude Code loads `CLAUDE.md`), for the retro too. `.harness/project.md` is still pasted, and the debrief is unchanged. `{{INIT_OUTPUT}}` is now `tail -n 40` of init.out followed by `full output: <path>` (it was `tail -c 4000`). The coding.md and initializer.md wording points at the loaded file. Decisions: `decisions/2026-10-21-no-double-claude-md` (D-H36) and `decisions/2026-10-21-clock-and-bounded-init-output` (the init-output half of D-H38; E3-04 adds the clock half to the same file). I also corrected the two architecture §10 sentences and the README `CLAUDE.md` row so they stay true; E3-05 still rewrites §10.
- **Tests 206 → 208:** 2 new checks (`coding prompt names CLAUDE.md but doesn't paste it`, `init output is capped at 40 lines with the log path`, which uses a `dproj ip` project with `INIT_CMD="seq 1 100"`) and 1 updated check (`brief, rules and policy in the prompt`, which now looks for a `# Project rules` line and `` `CLAUDE.md` ``).
- **Verified:** all 3 checks failed first (205/208). After the change: `bash tests/run.sh` 208/208, and `check.sh` green in 314 s (208/208). I rendered a coding and a retro prompt in scratch: the 40 init lines (21–60 of 60) plus the path, the rules line, and no pasted `rules` line.
- **Next session (E3-03):** the edits go in `lib/prompt.sh`'s `prompt_render` (E2-06 moved `prompt()` there), not in driver.sh.
- **Proposed change (for E3-05):** plan §12 asked E2-06 to paste CLAUDE.md into the probe prompt when the run's worktree is gone. It doesn't do that; it only notes `CLAUDE.md not auto-loaded`. After E3-02, such a probe sees no rules at all, while a baseline probe saw them pasted, so the two scores aren't comparable in that fallback. Fix: `eval run` saves the worktree's CLAUDE.md into the result dir, and `probes` pastes it in the fallback.

### 2026-10-21 verify E2

Suite re-run: 206/206. No step failed.

| Feature | Step | What you ran or read | What you saw | Holds |
|---|---|---|---|---|
| E2-01 | 1 | read docs/plans/2026-10-21-E2-evals.md head and `grep -c` of required terms | line 1 `Milestone base: 7b69ed3…`; sections task.json/validateTask, source records, lib/eval.sh, HARNESS_STATE, MERGE_POLICY=off, HARNESS_GH=false, EVAL_BUDGET_USD, WEEKLY_STOP_AT, one sample, probes, D-H35 all present | yes |
| E2-01 | 2 | grep POLICY/build-only in the plan | §2.3 table lists each source's POLICY; §2.4 policy rule: eval tasks always build-only, no live system or secret; §3.3 forces POLICY=build-only | yes |
| E2-01 | 3 | `git show --stat 4e3ef4d`; full suite | commit changed the plan plus harness bookkeeping (feature_list, progress); no code touched; suite 206/206 | yes |
| E2-02 | 1 | jq -e from the step on each of 5 tasks | all 5 ok; 5 within 5–12; bases are commits; spot-checked E1-05 feature ids/after | yes |
| E2-02 | 2 | read evals/README.md | table has id, project, source run, category, why; missing categories listed under 'To add when other projects' records are readable' | yes |
| E2-02 | 3 | `grep -ril 'live\|secret\|\.env' evals/tasks` | no output (rc 1); README states the rule | yes |
| E2-02 | 4 | `node lib/eval.mjs validate evals/tasks`; read check at tests/run.sh:115 | `5 task(s) valid` rc 0; check `eval: every task.json validates and a bad one is rejected` PASS in suite | yes |
| E2-02 | 5 | `bash tests/run.sh` | 206/206 checks passed | yes |
| E2-03 | 1 | read bin/harness eval dispatch, check at run.sh:177–184; `git worktree list` | eval dispatched to lib/eval.sh; stub run covers worktree, clone, seeded branch, flags | yes |
| E2-03 | 2 | check `eval run: two stub tasks end to end` (ev_files) and `git worktree list | grep -c harness-eval` | result files asserted; 0 harness-eval worktrees left | yes |
| E2-03 | 3 | suite PASS line `eval run: two stub tasks end to end, results in place` | PASS; asserts dir ends `-$HS-test` | yes |
| E2-03 | 4 | suite PASS line `eval run: --harness <ref> runs that ref's driver` | PASS; asserts eval.json sha, harness_dir under $T/evaltmp | yes |
| E2-03 | 5 | suite PASS line `eval run: nothing reaches a remote` | PASS; ev_local plus gh.log/curl.log line counts unchanged | yes |
| E2-03 | 6 | `bash -n lib/eval.sh`; suite | syntax ok; 206/206 (failing-first per progress not re-run) | yes |
| E2-04 | 1 | `grep EVAL_BUDGET_USD lib/config.sh`; check at run.sh:198 | `EVAL_BUDGET_USD=10` present; asserts `budget: $0.35 of $0.3; 1 tasks not started` | yes |
| E2-04 | 2 | suite PASS `eval: the budget cap stops starting tasks` | PASS | yes |
| E2-04 | 3 | suite PASS `eval: refuses past WEEKLY_STOP_AT` (run.sh:206) | PASS; asserts exit 1, `7-day window at 90%`, no results dir | yes |
| E2-04 | 4 | suite PASS `eval: --repeat 2 runs each task twice` | PASS; result list t1/r1,t2/r1,t1/r2,t2/r2 | yes |
| E2-04 | 5 | suite | 206/206 | yes |
| E2-05 | 1 | read EVCMP in run.sh:120–137, lib/eval.mjs compare | compare exports rows with verdicts incl. one sample; spread noise; pass^N; totals row | yes |
| E2-05 | 2 | suite PASS `eval.mjs: compare verdicts` | PASS; asserts within noise/better/worse directions and one sample | yes |
| E2-05 | 3 | suite PASS `eval compare prints the table` (run.sh:239) | PASS; `pass rate` line and verdict lines | yes |
| E2-05 | 4 | suite | 206/206 | yes |
| E2-06 | 1 | read probes questions in docs/eval.mjs; suite PASS `eval probes: questions derived, answers scored` | PASS; ≥2 questions in probes.json | yes |
| E2-06 | 2 | suite PASS `eval probes: the probe prompt is the driver's coding prompt` | PASS; asserts `# Coding session — \`T2b\`` | yes |
| E2-06 | 3 | same check ev_probe | score line asserted | yes |
| E2-06 | 4 | stub-claude `# Probe session` handler via the probes check | `score 1/2` PASS | yes |
| E2-06 | 5 | suite | 206/206 | yes |
| E2-07 | 1 | read evals/NEXT.md | baseline, e3, e4 run commands, compare, probes, cost ≈$28 per eval with stated estimate, 'overnight run never runs these' sentence | yes |
| E2-07 | 2 | grep README.md and bin/harness | `## Evals` section at README:139; command list names `harness eval run|compare|probes` | yes |
| E2-07 | 3 | grep docs/architecture.md; grep D-H35 journal/decisions.md | §3, §4 rows, §11 point 6 present; D-H35 appears once (line 464) | yes |
| E2-07 | 4 | suite | 206/206 | yes |
| E2-08 | 1 | read docs/plans/2026-10-21-E2-review.md | findings F1–F15 with severity and action listed | yes |
| E2-08 | 2 | read review FAIL lines | 198/205 then 202/205 FAIL lines quoted, fixes committed | yes |
| E2-08 | 3 | `grep -nE '(gh |curl|NTFY|push)' lib/eval.sh` | hits are NTFY blanking, stub logging, local pushes to the bare origin; review §Confirmations matches | yes |
| E2-08 | 4 | `bash -n` on 5 shell files, `node --check lib/eval.mjs`, suite | all ok; 206/206 | yes |

### 2026-10-22 00:50 · E2-08 · passes

- **What changed:** two Opus reviews (E2's diff, then my fixes), recorded in `docs/plans/2026-10-21-E2-review.md`. Tests 201 → 205. Fixes are in `lib/eval.sh`, `lib/eval.mjs`, `tests/run.sh`, `tests/stub-claude.sh`, README, architecture §4/§11, two new decision files (`eval-clone-sealed-at-base`, `eval-per-verified-pooled`) and an amendment line in `eval-run-isolation`. Commits `18aae96` and `8dbe359`.
- **Important, fixed:**
  - F1: replay clones kept the source's `run/*` tags and later objects, i.e. the finished answers. They are now sealed at base (refs, reflogs, `.keep` packs and alternates gone).
  - R1: the seeded progress.md named the source path; it no longer does.
  - F2/R3: `$`/tokens per verified feature dropped repeats that verified nothing. They are now Σ/Σ over every repeat, and compare names each such repeat.
  - Plus 9 Minor fixes, among them a missing repo refused before any spend, `*.txt` sets, real-run ports, `HARNESS_EVAL=1` on probes, and HUP.
- **Verified:** the new checks failed first (198/205, then 202/205 against `18aae96`), then passed. `check.sh` green, 205/205 (310 s). The grep `gh |curl|NTFY|push` on `lib/eval.sh` gives 4 hits, all local or neutralised (review §Confirmations). The `queue holds an entry…` timing check flaked once more (it is outside E2) and then passed twice.
- **Next session:** E2 is done. Every replay leaves its clones in `/tmp/harness-eval/<stamp>/`, kept for probes (`rm -rf` by hand).
- **Questions for Michael (defaults taken):**
  - (1) compare's pass-rate verdict keeps the spec's spread rule, so [1,1,1] → [1,1,0] reads "within noise" while the row shows `pass^3 1` vs `pass^3 0`. Should pass^N alone decide instead?
  - (2) A replayed session can still read `~/projects/<project>` and `$HARNESS_HOME`, both of which have the answer tags. I recorded this as a known limit rather than sandboxing. OK?
- **Proposed change:** the driver should trap INT/TERM/HUP and pass the signal to its `timeout` pid (`lib/driver.sh:166`). Today a Ctrl-C or hangup on a `--foreground` run or an eval kills the driver but leaves the claude session running unsupervised (review R2).

### 2026-10-21 23:59 · E2-07 · passes

- **What changed:** new `evals/NEXT.md` (baseline, e3, e4 commands with `EVAL_BUDGET_USD=35`; compare baseline→e3, e3→e4, baseline→e4; probes per task result; cost; "the overnight run never runs these"); README `Evals` section and a command-table row; architecture §3 (`lib/prompt.sh`, `lib/eval.sh`, `lib/eval.mjs`), §4 (results and `/tmp/harness-eval` rows), §11 point 6. Tests 201 → 201 (docs only).
- **Cost:** 7 features × $2.50 × 1.3 + 5 tasks × $1.00 ≈ $28 per eval, ≈ $83 for three; probes ≈ $0.05 each.
- **Verified:** `check.sh` green (305 s) on the committed tree. `bin/harness` help already named `eval run|compare|probes` (printed from the header). D-H35 already exists once in `journal/decisions.md` (E2-02), so I did not touch that closed file.
- **Next session (E2-08):** review `git diff 7b69ed3..HEAD`. Run NEXT.md's evals only when no harness run is going.
- **Question for Michael:** none. **Proposed change:** none.

### 2026-10-21 21:40 · E2-06 · passes

- **What changed:**
  - New `lib/prompt.sh`: the driver's prompt assembly (`prompt_vars`, `prompt_env`, `prompt_render`), now sourced by `lib/driver.sh`; no prompt byte changed. Run as `lib/prompt.sh <state dir> <template> <feature>`, it renders a run's prompt the way its driver would.
  - `eval run` now saves `commits.json` and `probe-prompt.md` (rendered by the **ref's** `lib/prompt.sh`) for each task.
  - New `harness eval probes <task result dir>`. It asks three kinds of question: which files each other feature changed, what the target depends on, and what the last failed attempt failed on. It sends them to one `PROBE_MODEL=haiku` session with no tools, one turn and a $0.50 cap. The answers are scored exact/contains/miss into `probes.json`, and it prints `score <n>/<m>`.
  - `eval.mjs` gains `target`, `parseCommits`, `questions`, `score` and their CLI.
  - Also: the stub's `# Probe session` branch, `bin/harness` help, and `journal/decisions/2026-10-21-eval-probes.md`. Tests 199 → 201.
- **Verified:**
  - Both checks failed first (no `questions` export; no probe prompt), then passed.
  - A mutation that renders the probe prompt without the eval's roots fails the prompt-equality check.
  - `check.sh` green, 201/201 (304 s), on the final tree. One earlier full run failed `queue holds an entry…` once, a timing check unrelated to this diff (queue code untouched); it passed on the re-run.
- **Review:** an Opus review found 3 Important issues, all fixed with tests written first:
  - prefix false matches (`F1` was found in `F10`);
  - the fails key was a markdown or status line;
  - a failed probe session was recorded as a real 0/m. It now exits 1 and keeps the old probes.json.
  - Of the Minor findings I fixed: the timeout, writing probes.json only once scored, the temp-dir trap, `Q01` and restated questions, an unknown feature, and asserting every flag. Documented, not fixed: init output, `--settings`, rename paths.
- **Next session (E2-07):** the docs should list `lib/prompt.sh` in architecture §3 (plan §8). They should also say that today's probes will score near 0: the probe sees the prompt but not progress.md. E4's context.md is what should raise the score.
- **Question for Michael (default taken):** a failed probe session (limit or API error) is no score (exit 1) rather than 0/m. OK?
- **Proposed change:** none.

### 2026-10-21 23:20 · E2-05 · passes

- **What changed:**
  - `lib/eval.mjs` gains `loadResult(dir)` (`spent` uses it too) and the exported `METRICS` (eight, with paths confirmed in `summary.mjs build`). It also gains `completeRepeats`, the pure `compare(A, B)` → rows `{task, metric, a, b, verdict, a_values, b_values}` with a `total` row per metric, `compareText` and a `compare` CLI.
  - `lib/eval.sh compare <A> <B>` takes a path or a name under `evals/results/`. `bin/harness` help gains the command.
  - `journal/decisions/2026-10-21-eval-compare-verdicts.md` records the decision.
  - Tests 197 → 199: `eval.mjs: compare verdicts` and `eval compare prints the table`.
- **Verified:**
  - Both checks failed first (`FAIL eval.mjs: compare verdicts`: no export named compare; `FAIL eval compare prints the table`), then passed on an eval-only subset (20/20).
  - Five mutations of `eval.mjs` were each caught by the unit check: verdict direction, the noise test, one sample, pass^N becoming a mean, and the totals over incomplete repeats.
  - `check.sh` green, 199/199 (302 s), on the final tree.
- **Review:** an Opus review found 2 Important and 5 Minor issues; I fixed all 7.
  - Important 1: a run that started but wrote no `summary.json` was silently dropped. Its unit dir now loads as `{missing}`, counts as not passing and is named in the output.
  - Important 2: the partial-repeat totals and the Σcost/Σverified totals were untested. Both have checks now, and the fixture's numbers are consistent.
  - Minor: the total pass rate uses only complete repeats; an empty id list is guarded; a note says when A and B have different N; a missing sha/label prints `?`; `realpath --` is used and an empty argument is refused. The simplification (each metric carries its own format and sum) is applied.
- **Next session (E2-06):** compare reads `{missing}` markers; probes don't need them. The README Evals section and architecture §3/§4/§11 are E2-07's job.
- **Questions for Michael (defaults taken):** (1) `no data` is a fifth verdict, used when a side has no value, for example $ per verified feature when nothing verified. OK? (2) "one sample" counts a side's non-null values, not its repeats. OK?
- **Proposed change:** none.

### 2026-10-21 21:55 · E2-04 · passes

- **What changed:** `lib/config.sh` gets `EVAL_BUDGET_USD=10`. `lib/eval.sh run` also changes:
  - Before each task it sums the results' `summary.json` costs with the new `eval.mjs spent` (`<task>/` and `<task>/r<N>/`). At or over the cap it starts nothing more; if the sum fails, it also stops.
  - Before anything is created, it refuses if `$HARNESS_STATE/USAGE_7D` is past `WEEKLY_STOP_AT`. Between tasks it checks that file and the eval's own `USAGE_7D`, and copies a later real `LIMIT_UNTIL` into the eval's state.
  - `--repeat N` runs repeat-major into `<task>/r<N>`, as runs `eval-<task>-r<N>` on fresh clones.
  - `eval.json` gains `repeat`, `budget {cap, spent, not_started, text}` and `weekly`. Any task not started makes the eval exit 1.
  - The runs' safety lines carry the eval's `WEEKLY_STOP_AT`. The user config is read in a subshell, so its exports don't reach the runs. Task ids `harness|state|wt|scratch|ledger` are refused.
  - `weekly_over` no longer prints "No such file" for a missing `USAGE_7D` (the redirect order was wrong).
  - Also: `bin/harness` help, and `journal/decisions/2026-10-21-eval-budget-window-repeat.md`. Tests 194 → 197.
- **Verified:** the three new checks failed first (3/6 on an eval-only subset), then passed. The full suite (`check.sh`) is green, 197/197 (301 s), on the final tree.
  - By hand: a user config with `WEEKLY_STOP_AT=95` and `USAGE_7D` at 0.96 is refused with "stop at 95%"; a task id `state` dies before anything is created.
  - An Opus review found 0 Critical and 1 Important issue: the eval and its runs used different `WEEKLY_STOP_AT` values; fixed. Of its Minor findings I fixed 2, 5, 6, 7, 8 and 9. Not fixed: 3, the cap counts only tasks whose `summary.json` was copied (a driver that died before `finish` spends unseen); 4, a far-future real `LIMIT_UNTIL` makes each remaining task idle until its deadline.
- **Next session (E2-05):** a results dir holds `<task>/summary.json` (one repeat) or `<task>/r<N>/summary.json`. After a budget or weekly stop the last repeat can be partial, so per-repeat totals must allow for that. `eval.mjs` has `spent()` and a private `summaries(dir)` walker that `loadResult` can reuse. The docs (README Evals section, architecture §3/§4) are E2-07's job.
- **Question for Michael (default taken):** `EVAL_BUDGET_USD=0` starts no task: it is a cap, not an off switch like `WEEKLY_STOP_AT=0`. OK?

### 2026-10-21 20:45 · E2-03 · passes

- **What changed:** new `lib/eval.sh run` (`harness eval run [--set] [--harness] [--label]`; dispatched and listed in `bin/harness`, whose help now prints the whole header). It adds a detached worktree of the ref, which is removed at the end. Each task runs on a fresh clone at `base` with a local bare origin and a pushed `harness/eval-<task>` branch seeded by the new `eval.mjs seed`, so the initializer is skipped. The ref's `bin/harness start --foreground` runs with every root under the eval dir, gh/curl set to `false`, and the safety lines in both the user config and `run.env`. Results go to `evals/results/<stamp>-<sha>-<label>/` (gitignored) along with `eval.json`. Also new: `tests/fixtures/eval-tasks/{t1,t2}` and `journal/decisions/2026-10-21-eval-run-isolation.md` (a file, not a D-H entry). Tests 191 → 194.
- **Verified:** I watched all three checks fail first (0/3, no `eval`). A mutation run with `MERGE_POLICY=off` removed failed `nothing reaches a remote`, and so did one with the `run.env` lines removed. The test repo's own config sets `MERGE_POLICY=auto`, an `NTFY_URL` and `BASE_PORT=7831`, so that check now covers the `run.env` layer and the ports. `check.sh` green, 194/194 (285 s). `git worktree list` shows no evaltmp entry. A duplicate id, a missing base, a pre-7754661 ref and an unknown set each die before anything is created (checked by hand).
- **Review:** an Opus review found 0 Critical and 3 Important issues, all fixed. (1) A project's `BASE_PORT` beat the eval's, so the eval now writes each run's port from 7900. (2) No test covered the `run.env` layer. (3) An old ref would ignore the isolation, so refs before 7754661 are refused. I also fixed Minor 4–8, 10, 11 and 12. Not fixed: Minor 9 (Ctrl-C stops only after the current task), which is documented in the decision file.
- **Next session (E2-04):** `run_task` is one unit, so add `--repeat` through `$d=$E/<task>/r<N>`, and the budget check goes before each `run_task`. The eval checks run the committed driver (`--harness HEAD`). The test's sha is `harness_version`'s, which equals `rev-parse --short HEAD` unless the tip is a ledger-only commit.
- **Deviations from the plan:** the clone is at `$E/<task>/<project>` (plan §3.1, one segment deeper than the step says). The suite's EXIT trap removes only its own eval worktrees instead of running `git worktree prune`, because prune would touch every stale worktree of the shared repo.
- **Questions for Michael (defaults taken):** (1) Should results stay uncommitted (gitignored; keep one with `git add -f`)? (2) Should eval runs use the harness defaults rather than your `~/.config/harness/config.sh`? Your `~/.claude` hooks still load, with `HARNESS_EVAL=1` set. (3) Eval ports start at 7900. OK?

### 2026-10-21 20:10 · E2-02 · passes

- **What changed:** this session followed Michael's answer (f02a5a4: agent-harness only, 5 to 12 tasks). `evals/README.md`: § Still to add is now § To add when other projects' records are readable. It names the two missing categories: retried or given up, and depends-on with an in-task `after`. It explains why agent-harness can't supply either, lists the candidates, and says how to add a task. D-H35 in `journal/decisions.md` records the answer. No task, code or check changed. Tests 191 → 191.
- **Verified:** `check.sh` green, 191/191 (279 s; `PASS eval: every task.json validates and a bad one is rejected`). Step 1's `jq -e` passes on all 5 tasks. Every feature (E1-02, E1-05, E1-06, E1-07, P1-03, P1-04, P3-05) is byte-identical to `git show <base>:…/feature_list.json`. `grep -ril 'live\|secret\|\.env' evals/tasks` prints nothing. `node lib/eval.mjs validate evals/tasks` says "5 task(s) valid" (exit 0), and `validateTask({id:'x'})` names `features: required`.
- **Next session must know:** the only retried feature in this repo's records is this one, E2-02. It needed three sessions because reads were refused, and it builds the set, so it is left out (README says so). E2-03… use the stub tasks, not this set.
- **Proposed change:** D-H35 still sits at the end of the closed `journal/decisions.md`, along with D-H32–34 from this run (allowed for in-flight runs). D-H36–38, reserved by E3-01, should be files in `journal/decisions/`, not new entries there.

### 2026-10-21 22:30 · E3-01 · passes

- **What changed:** `docs/plans/2026-10-21-E3-prompts.md` (new, plan only; base `29b3d67`). It fixes the prompt order: static part 1 with **no placeholders**, then the policy, then *This run* (run id, worktree, run dir, port, scratch, suite, spec), the brief, the one `# Project rules` line naming CLAUDE.md, and project.md, then *This session* (`` Feature: `<id>` ``, `Milestone: <m>`, the clock line, init output). It also covers: a `{{SECTIONS}}` line in render.mjs (pure `assemble`); exact first lines with stub awk parsing after `# This session`; `logs/NN-<id>.prompt.md` copied in `session()`; the last 40 lines of init output plus `full output: <path>`; the exact clock wording; 4 new checks plus the changed `brief, rules and policy in the prompt`; D-H36/37/38. The debrief finding: it runs in `$STATE_ROOT/debrief/<stamp>`, nothing is auto-loaded there and it pastes nothing, so it stays as is. Tests 190 → 190.
- **Verified:** `check.sh` green twice, 190/190 (275 s, then 280 s on the final plan). `git status` shows only the plan file. I tried the plan's stub awk, its init-output snippet and the `cmp`/`grep -b` offsets on samples, and all work. An Opus review found 1 Critical and 4 Important issues, all folded in. The Critical one: run id/port/scratch were before the policy, against E3-03 step 1. The Important ones: the retro needs the CLAUDE.md line; land the prompt copy before the prefix check; no path filter on the E3 diff; E2's probes need CLAUDE.md pasted outside the worktree. Its 8 Minor findings are fixed too, among them `summary.mjs:88` `startsWith` also matching `.prompt.md`, now in E3-03's scope.
- **Next sessions:** E3-03 changes templates and stub in one commit. Caveat in D-H37: API caching hits at content-block boundaries, so a shared byte prefix inside one `-p` text block may not be a cache hit. E2's eval measures it.
- **Run is about to block (Proposed change, Michael):** E3-02 … E3-05 have no `after`, so they wait on E2-02 … E2-08, and E2-02 is out of attempts. Add `"after": ["E3-01"]` on E3-02, or answer E2-02's INBOX question and `harness continue`.

### 2026-10-21 21:30 · E2-02 · not yet

- **What changed:** `evals/tasks/`: two depends-on tasks, `ah-p1-03-04-park-then-notify` (10-19 P1-03 → P1-04, base dfd0429) and `ah-e1-06-07-summary-trends` (E1-06 → E1-07, base 9480d72). The second replaces `ah-e1-06-summary-quality`, so E1-06 isn't replayed twice. The set now has 5 tasks: 3 first-time passes and 2 depends-on. `evals/sets/default.txt`, the README table and § Still to add, and D-H35 (a second *default*: "depends-on by order") are updated. The `eval:` check also asserts that every id in default.txt has a task (watched failing with a bogus id). Tests 190 → 190.
- **Verified:** `check.sh` green, 190/190 (277 s). `validate evals/tasks` says "5 task(s) valid". Step 1's `jq -e` passes on all 5, and the `live|secret|.env` grep prints nothing. Each base equals `git rev-parse <first commit>^`, and the features were built by `jq` straight from `git show <base>:…/feature_list.json`. The rebuilt E1-06 matches the old task's exactly.
- **Why not passing:** steps 1–2 still need ≥8 tasks, ≥2 retried, and one in-task `after`. agent-harness has no retried feature, and its one in-task `after` (P2-01/P2-03) hits the grep. This session the classifier refused even `ls ~/projects/portfolio_site/.harness/runs` ("PII Data Handling"); I didn't work around it.
- **Question for Michael (D-H35 *default*):** to unblock, allow reads of the source records for the next E2-02 session. For example, add Bash allow rules `ls ~/projects/*/.harness/runs*`, `jq * ~/projects/*/.harness/runs/*` and `git clone -q --mirror /home/mh550/projects/*`. Or answer "agent-harness only" in INBOX.md, and amend steps 1–2 to accept the 5-task set.
- **Next session:** with reads allowed, add 2 retried tasks plus 1–2 with an in-task `after` (candidates in evals/README.md § Still to add) for 8–9. Otherwise E2-03…E2-06 don't need more tasks.

### 2026-10-21 20:45 · E2-02 · not yet

- **What changed:** `lib/eval.mjs` (new): `validateTask` returns one error per problem, each starting with its field, and `node lib/eval.mjs validate <dir|file>…` rejects a missing task.json, an id that isn't its directory's name and an empty set. New: `evals/tasks/` with 4 tasks, `evals/sets/default.txt`, `evals/README.md` (rules, table, § Still to add), and D-H35 in `journal/decisions.md` (the set part; E2-03 extends it). The suite gains `eval: every task.json validates and a bad one is rejected`, watched failing first ("FAIL eval: …": no eval.mjs, then no evals/tasks). Tests 189 → 190.
- **Verified:** `check.sh` green, 190/190 (277 s). All four tasks pass step 1's `jq -e`; the `live|secret|.env` grep prints nothing. An Opus review confirmed each `base` is the parent of the feature's first commit and each feature equals `git show <base>:…/feature_list.json` exactly. It raised 7 Minor findings and no Critical or Important ones; all 7 are fixed.
- **Why not passing:** steps 1–2 need 8–12 tasks and at least 2 per category. The 4 tasks are all first-time passes from agent-harness's own runs (E1-02, E1-05, E1-06; 10-19 P3-05). The auto-mode permission classifier refused this session's reads of the other projects' history: `ls ~/projects/<p>/.harness/runs`, a mirror clone of dj-crate-streaming/pathways/hit_list, and `git` reads of the portfolio_site mirror ("Credential Exploration", "PII Data Handling"). I didn't work around it, and I deleted the mirror. agent-harness's runs have no retried feature and no in-task `after` that passes the grep.
- **Question for Michael (D-H35 *default*):** pick one. (a) Allow the reads: add Bash allow rules for `git clone -q --mirror /home/mh550/projects/*` and `git -C /tmp/harness/agent-harness/*` in this session's settings. The next E2-02 session then adds ≥2 retried and ≥2 depends-on tasks from portfolio_site/pathways/hit_list (candidates in evals/README.md § Still to add). (b) Answer "agent-harness only" in INBOX.md. E2-02's steps would then need amending, since the categories can't be filled.
- **Next session:** E2-03 … E2-06 don't need more tasks (they use the stub tasks t1/t2), so the run can go on past E2-02. Never edit tests/run.sh while the suite runs: bash reads it as it goes, and one run here died with a syntax error.
- **Proposed change:** E2-02 step 1 could say "8–12 once the source reads are allowed" or accept agent-harness tasks. The plan's §1 table puts D-H35 under E2-03; E2-02 wrote it first.

### 2026-10-21 19:40 · E2-01 · passes

- **What changed:** `docs/plans/2026-10-21-E2-evals.md` (new, plan only; base `7b69ed3`). It covers the task.json schema and validator, the source records and each project's POLICY (dj-crate-streaming is live-staged, the other three build-only; eval tasks always run build-only), the eval layout under `/tmp/harness-eval/<stamp>`, seeding `origin/harness/<run>` so the initializer is skipped, the isolation env plus `run.env` safety lines, the results layout plus `eval.json`, the budget and 7-day window, compare's 8 metrics and noise rule, probes (questions, `lib/prompt.sh` shared with the driver, scoring), the stub tasks t1/t2, 11 check names and D-H35. Tests 189 → 189.
- **Verified:** `check.sh` ran green twice (275 s each, 189/189), the second time on the final plan. `git status` shows only the plan file. An Opus review of the plan found 4 Important and 9 Minor issues, all folded in. Examples: the "nothing reaches a remote" check couldn't fail with `HARNESS_GH=false` forced (now `HARNESS_EVAL_GH`); `--harness HEAD` can't tell the drivers apart without a `{{CHECK}}` path assert; probes now read `commits.json` and `probe-prompt.md` from the results, so they survive `/tmp` being cleared.
- **Next sessions must know:** the eval checks run the **committed** driver (`--harness HEAD`), so commit before the full suite. Stub task ids avoid A/B/C (the stub misbehaves on those). Portfolio_site v3 (P1-01 → P1-02) has a same-task feature `after`; the older runs' `after` lists name milestones.
- **Defaults taken (D-H35, E2-03 writes it), questions for Michael:** (1) `evals/results/` is gitignored, so untracked results don't make every run `+dirty`; commit one with `git add -f`. OK? (2) Eval runs use harness defaults, not your `~/.config/harness/config.sh`; they still load your `~/.claude` hooks, with `HARNESS_EVAL=1` set so a hook can skip them. OK?
- **Proposed change:** E2-01 step 1 names `git -C ~/projects/<p> log --all -- .harness/runs` for pathways and hit_list. The ground rules forbid git commands in other checkouts, so the plan reads from a mirror clone in scratch instead (`git clone --mirror`, read-only).

### 2026-10-21 · verify E1

Init green; `bash tests/run.sh` run fresh: 189/189 checks passed, no FAIL. `bash -n` on lib/*.sh tests/*.sh bin/harness and `node --check` on lib/*.mjs clean. Check names below are the PASS lines of that run.

| Feature | Step | What you ran or read | What you saw | Holds |
|---|---|---|---|---|
| E1-01 | 1 | read docs/plans/2026-10-21-E1-telemetry.md (line 1, headings §1–§12, §5, §10, §12) | line 1 `Milestone base: 07c8367…`; sections for files/owners per E1-02…09, E0 (§2), E0b (§3), fixture capture + fields (§5), metrics/summary keys (§6–7), ledger + trends (§9), check names (§10), D-H32/33/34 (§12) | yes |
| E1-01 | 2 | read plan lines 169–175, 189 | tokens combine by max like cost, falls back to sum if capture says so; `orient_s` null without timestamps, recorded in D-H34 | yes |
| E1-01 | 3 | `git show --stat ef0cca2` | plan file only plus the harness's own feature_list/progress bookkeeping; no code | yes |
| E1-01 | 4 | `bash tests/run.sh` | 189/189 | yes |
| E1-02 | 1 | read tests/stub-claude.sh diff | `STUB_INIT_LIMIT` in initializer branch cats fixtures/usage-limit.jsonl and `exit 1` before the list is written | yes |
| E1-02 | 2 | read tests/run.sh:337–338; suite PASS line | check `continue after a no-list end merges main first` asserts ended starts `usage limit before the feature list`, `grep -q revised …/SPEC.md`, and awk: `merged main` line precedes `feature list written`; PASS | yes |
| E1-02 | 3 | read progress entry line 69 | quotes `FAIL continue after a no-list end merges main first` (168/169) before the driver change | yes |
| E1-02 | 4 | read lib/driver.sh:416,437–441; suite | `resumed` set from earlier `run <id> on` line; `if [[ -f $LIST ]] \|\| (( resumed ))` runs sync_main before initializer; `resume reloads config merged from main` PASS | yes |
| E1-02 | 5 | `grep -c '^### D-H32' journal/decisions.md`; read entry | 1; finding · choice · rejected | yes |
| E1-02 | 6 | `bash -n`; full suite | clean; 189/189 | yes |
| E1-03 | 1 | read run.sh:137–138; suite | check `init: vercel.json gets …` asserts framework nextjs kept, `deploymentEnabled["harness/**"]==false`, stdout "added the deploy guard"; PASS | yes |
| E1-03 | 2 | read run.sh:139–141; suite | `.vercel/`-only repo gets file; bare repo gets none and no output; PASS | yes |
| E1-03 | 3 | read run.sh:350–351,352; suite | one `preview deploy per session` note in hlog (and after continue: 2 initializer-refused, still 1), exactly one curl post; PASS | yes |
| E1-03 | 4 | read run.sh:359–360; suite | demo hlog has no `preview deploy`, curl_count 0; PASS | yes |
| E1-03 | 5 | read tests/stub-gh.sh diff, fixtures/gh-deployments.json keys, lib/deploy.sh | stub answers `api repos/…` from fixture (id, sha, ref, environment present), `STUB_DEPLOYMENTS=0` → `[]`; detection uses vercel.json, .vercel/, read-only gh api, netlify.toml (now `per_page=20` after review, check updated) | yes |
| E1-03 | 6 | run.sh:144–145 and :353–354; suite | init adds `[build] ignore` that exits 0 for BRANCH=harness/x, exits 1 for main, other keys kept; run start notes netlify absence once; both PASS | yes |
| E1-03 | 7 | read architecture.md:252–255, `grep -c '^### D-H33'` | line on Git-connected hosts disabling run-branch deploys present; D-H33 count 1 | yes |
| E1-03 | 8 | `bash -n`; suite | clean; 189/189 | yes |
| E1-04 | 1 | `jq` on tests/fixtures/usage-tokens.jsonl; `grep -ci michael` | 3 assistant events with message.usage, one with tool_use `Write`, result with usage + modelUsage, session ids test-ised, 0 hits for michael; D-H34 records the capture exception | yes |
| E1-04 | 2 | `node -e` import `outcome`,`orientation` on fixture | tokens_in 4, cache_read 35768, cache_write 13651, tokens_out 219, cache_hit_rate 0.724 (=35768/49423), context_peak 24881 (jq max matches); row written by append | yes |
| E1-04 | 3 | read run.sh:93–96; suite | check asserts literals 4/35768/13651/219/0.724/24881, all match my jq numbers; PASS | yes |
| E1-04 | 4 | read stub-claude.sh `ok()`; run.sh:162; suite | `ok()` replays fixture with cost/result substituted; check asserts tokens_in>0, rate 0..1, context_peak>0 on coding rows; PASS | yes |
| E1-04 | 5 | read progress line 52; suite | FAIL lines quoted (177/179); 189/189 | yes |
| E1-05 | 1 | read lib/metrics.mjs orientation; ran it on fixture | `{tokens:24547,turns:1,seconds:0.233}`; 24547 = 2+13312+11228+5 by hand; stops at the Write request; fixture does carry timestamps | yes |
| E1-05 | 2 | read run.sh:97–104; suite | literals 24547/1/0.233, no-edit 49432/2, no-timestamps seconds null, no-usage null; PASS | yes |
| E1-05 | 3 | read run.sh:163; metrics output; suite | rows carry orient_tokens/turns/s; check asserts >0, >=1; PASS | yes |
| E1-05 | 4 | read progress line 43; suite | FAIL lines quoted (179/181); 189/189 | yes |
| E1-06 | 1 | read lib/summary.mjs 28–44, 168–187 | tokens totals + by_role, cache_hit_rate, context_peak, per_verified_feature {cost,tokens}, orientation median, first_attempt_pass_rate, rework, verify_fail_rate all present | yes |
| E1-06 | 2 | read run.sh:166; suite | asserts tokens.in>0, per_verified_feature.cost>0, rework==["A","C"], first_attempt 0.33, verify_fail>0; PASS | yes |
| E1-06 | 3 | read summary.mjs:239–240, run.sh:167; suite | `Tokens` and `Quality` rows greped in `harness report demo`; PASS | yes |
| E1-06 | 4 | read prompts/retro.md:9–10 | names tokens, orientation, rework, first_attempt_pass_rate, verify_fail_rate | yes |
| E1-06 | 5 | read progress line 35; suite | FAIL lines quoted (181/183); 189/189 | yes |
| E1-07 | 1 | read driver.sh:416–420, lib/version.sh, summary.mjs:186, ledger fields | writes harness-version/dirty (skipped for merge-only), logs on `run <id> on` line, summary `harness:{version,dirty}`; uses last non-ledger commit (refined from plain rev-parse, D-H34) | yes |
| E1-07 | 2 | read run.sh:169–171; suite | asserts ledger row harness_version==HV and boolean harness_dirty, run.log and marker; PASS | yes |
| E1-07 | 3 | read run.sh:278–280; suite | `trends --by version` rows per version, header; plain trends has no Harness column; `trends lists every run` PASS | yes |
| E1-07 | 4 | read progress line 26; suite | FAIL lines quoted (183/185); 189/189 | yes |
| E1-08 | 1 | read architecture.md §4 rows 80,84, §5 line 102, §11 lines 275–283 | metrics keys, version marker, resumed run merges main before any session, tokens/cache/orientation, summary keys, trends --by version | yes |
| E1-08 | 2 | read README.md:41,44,46 | trends --by version, init deploy guard, continue merges main first | yes |
| E1-08 | 3 | `grep -c '^### D-H3[234]'` | 1 each | yes |
| E1-08 | 4 | `bash tests/run.sh` | 189/189 | yes |
| E1-09 | 1 | read docs/plans/2026-10-21-E1-review.md | lists M1–M8, S9–S10, R1–R5 with severity and resolution; diff from plan base 07c8367; states Opus reviewer read the diff (cannot independently confirm the subagent, doc is complete) | yes |
| E1-09 | 2 | read review table, progress line 12 | no Critical/Important; Minors fixed with quoted FAIL lines (184/189) and commits 65cf82f, 3f42aec | yes |
| E1-09 | 3 | `bash -n` all shell files, `node --check` all lib/*.mjs | all clean | yes |
| E1-09 | 4 | `bash tests/run.sh` | 189/189 | yes |

### 2026-10-21 18:50 · E1-09 · passes

- **What changed:** `docs/plans/2026-10-21-E1-review.md` (new: 8 Minor + 2 simplifications from the Opus review of `07c8367..32fbde5`, 5 Minor from a second Opus pass on the fixes, each with its resolution). Fixes: `lib/summary.mjs` exports `redSuite`/`failedRecheck` (escaped, exact-id; `cause()` and `rework` share them, so id `c++` no longer throws and empties `summary.json`); `lib/features.mjs` escapes the id; `lib/driver.sh` doesn't rewrite `harness-version` under `harness merge`; `lib/deploy.mjs`: true `harness/…` Vercel keys and `deploy-preview`/`branch-deploy`/`"harness/…"` Netlify context ignores count as unguarded, `vercel-guard` says `by-hand` rather than a false "added"; `lib/deploy.sh` reads `per_page=20` deployments. D-H33 updated. Tests 186 → 189.
- **Watched failing:** 184/189 with `FAIL deploy.mjs: a true harness/ key or a context ignore isn't guarded (E1 review)`, `FAIL summary.mjs: cause and rework read the log by exact id (E1 review)`, `FAIL harness merge keeps the harness version of the run (E1 review)` and the two `per_page` run-start checks; round 2's assertions `DREV FAIL` standalone.
- **Verified:** suite 189/189 twice; `check.sh` green in 276 s; `bash -n` on `lib/*.sh bin/harness tests/*.sh`, `node --check` on every `lib/*.mjs`. Nothing Critical or Important was found.
- **Left, with reasons (in the review file):** orientation's output share is understated (stream snapshot, already a D-H34 limit); root `vercel.json` vs a Vercel Root Directory; a context ignore under a bare `[context]` table.
- **Next:** E1 is complete; E2 per the spec.

### 2026-10-21 18:20 · E1-08 · passes

- **What changed:** `docs/architecture.md` §4 (metrics row keys, harness-version/dirty state files), §5 (resumed run merges main before any session, initializer included), §11 points 1–3 (tokens/cache/orientation, new summary keys, `trends --by version`); `README.md` (`trends [--by version]`, init deploy guard, continue merges main). Tests 186 → 186 (docs only).
- **Verified:** `grep -c '^### D-H3[234]' journal/decisions.md` is 3 (one each, already written by E1-02..07); `check.sh` green in 277 s.
- **Next:** E1-09.

### 2026-10-21 17:55 · E1-07 · passes

- **What changed:** `lib/version.sh` (new) `harness_version <dir>`; `lib/driver.sh` writes `$STATE/harness-version`/`harness-dirty` per segment and ends the `run <id> on` line with `· harness <sha>[+dirty]`; `lib/summary.mjs`: `harness { version, dirty }` in `build`, `ledger-line` adds `harness_version`, `harness_dirty` and the telemetry keys of plan §9 (null when absent), pure `byVersion` behind `trends <runs.jsonl> --by version` (other args exit 2); `bin/harness trends` passes its args and its usage line names `--by version`. D-H34 gains "Across harness versions (E1-07)". Tests 183 → 186.
- **Watched failing:** `FAIL ledger row has harness_version and harness_dirty`, `FAIL trends --by version groups the runs` (183/185); `FAIL harness version skips ledger commits` against the step's `rev-parse HEAD` logic.
- **Verified:** `trends --by version` on hand-made rows: `–` / `abc1234` / `abc1234+dirty` groups, medians 0.60 cache hit and 12.3k orientation tokens match hand math; in the suite, 32 demo rows are 1 group `<sha>+dirty | 32 | 56/84`. `bash -n`, `node --check`; `check.sh` green in 277 s, 186/186. An Opus review found one real flaw (below), fixed.
- **Default taken (D-H34), a deviation from step 1's `rev-parse --short HEAD`:** the version is the last commit **outside `ledger/`**, and dirty ignores `ledger/` too. The driver and debrief commit the ledger into the harness checkout (15 of main's last 30 commits are `ledger:`), so HEAD would make every run its own "version". Question for Michael: fine to treat ledger commits as not-a-version?
- **Next session (E1-08) must know:** README/architecture still lack `trends --by version`, `harness-version`/`harness-dirty` state files and `lib/version.sh` (plan §11 gives docs to E1-08).
- **Proposed change:** step 1 of E1-07 should read "the last commit outside ledger/" rather than `rev-parse --short HEAD`.

### 2026-10-21 17:20 · E1-06 · passes

- **What changed:** `lib/summary.mjs`: `median` and `tokenTotals` exported (pure); `build` adds `tokens` (+ `by_role`), `per_verified_feature` { cost, tokens }, `orientation` { tokens, turns, seconds } (medians of real coding rows), `rework`, `first_attempt_pass_rate`, `verify_fail_rate` as plan §7; `report` gains `Tokens` and `Quality` rows after `Spend by role` (only for summaries that have the keys, so older ledger summaries print as before). `prompts/retro.md` names the keys as inputs. D-H34 gains "The run's numbers (E1-06)". Tests 181 → 183.
- **Watched failing** on a scratch copy: `FAIL summary: tokens, per verified feature, first-attempt rate, rework`, `FAIL report shows tokens and quality` (181/183).
- **Verified:** the new `build` on the saved demo state: tokens in 40 / cache_read 357680 / cache_write 136510 / out 2190, hit 0.724, peak 24881, per verified feature $1.08 / 165473 tokens, orientation 24547 / 1 / 0.23 s, rework [A, C], first-attempt 0.33, verify-fail 0.25 (= plan §7). `node --check`, `bash -n`; `check.sh` green in 276 s, 183/183. Opus review: no bugs; its `1000.0k` rounding note fixed.
- **Next session (E1-07) must know:** a run whose metrics rows predate E1-04 sums its tokens as 0, not null (plan: "null tokens count as 0"), so a ledger row for such a run would carry `tokens.in` 0; E1-07 may want to treat 0 input as "not recorded".
- **Proposed change:** `cause()` in `summary.mjs` (older code) builds its `un-passed: suite red` / `failed` regexes from an unescaped, unanchored id (`A` matches `BA un-passed`); the new `rework` code escapes and anchors. A one-line fix for E1-09's simplify pass.

### 2026-10-21 16:45 · E1-05 · passes

- **What changed:** `lib/metrics.mjs` `orientation(evs)` exported → `{ tokens, turns, seconds }`; `outcome()` and `append` write `orient_tokens orient_turns orient_s` after `context_peak`; 2 checks in `tests/run.sh`; D-H34 gains an "Orientation (E1-05)" paragraph and a widened known limit. Tests 179 → 181.
- **Watched failing** on a copy with only the checks: `FAIL metrics.mjs: orientation stops at the first Write`, `FAIL metrics: orientation recorded per session` (179/181).
- **Verified:** by hand from the fixture: full capture 24547 tokens (2+11228+13312+5) / 1 turn / 0.233 s; without its `Write` 49432 / 2 / 1.441 s; no timestamps → seconds null; no usage → all null. `node --check`, `bash -n`; `check.sh` green in 275 s, 181/181. Opus review: no bugs, two low edge cases; the timestamp-less edit event one is fixed (timed by the last stamped event before it, asserted).
- **Default taken (D-H34), a deviation from the step's "before":** orientation counts requests **up to and including** the first edit. With "before", the real capture (its first request is the `Write`) gives 0/0, so every stub session would show none and step 3 (`orient_tokens > 0`) could only hold with a hand-made stub event; and the edit request's input is what orientation read. +1 request per session, the same for every run.
- **Next session (E1-06) must know:** every stub coding row is 24547 / 1 / 0.233, so the median orientation on demo is those numbers. `orient_s` is a number with ms precision.
- **Proposed change / question for Michael:** step 1 of E1-05 and plan §6 say "before the first edit" and `orient_s` null; should orientation exclude the edit request instead? It's a one-line change in `orientation()` plus a stub orientation event.

### 2026-10-21 15:55 · E1-04 · passes

- **What changed:** `tests/fixtures/usage-tokens.jsonl` (new: the real capture, haiku, CLI 2.1.306, $0.0032; assistant/user/result lines, `session_TEST`, `/tmp/capture`; system lines and the rate_limit_event dropped); `lib/metrics.mjs` `tokens()`/`contextPeak()` exported, `outcome()` + `append` write `tokens_in cache_read cache_write tokens_out cache_hit_rate context_peak` after `turns`; `tests/stub-claude.sh` `ok()` replays the fixture (cost/result/turns/duration substituted, `--argjson` as plan §5.4); 2 checks; D-H34. Tests 177 → 179.
- **Watched failing** on a copy without the code: `FAIL metrics.mjs: tokens, cache rate and context peak from the real fixture`, `FAIL metrics: coding rows carry tokens, cache rate and context peak` (177/179).
- **Verified:** jq on the fixture gives 4 / 35768 / 13651 / 219, rate 0.724, peak 24881 (the literals in the check); `Σ modelUsage.costUSD` = `total_cost_usd` = 0.00319778 → tokens by **max**, as planned. `bash -n`, `node --check`; `check.sh` green in 275 s, 179/179. Opus review: no bugs; two doubts recorded in D-H34 (max is inferred from a single-result capture; `context_peak` counts subagent events too).
- **Next session (E1-05) must know:** stream-json events **do** carry ISO `timestamp` on assistant and user lines (the plan expected none), so `orient_s` can be measured; the fixture's first message is two events with one `message.id` (thinking, then `Write`), 0.23 s apart. Every stub session replays those same timestamps.
- **Proposed change:** plan §5.3/§6 says `orient_s` is null without timestamps "(expected: none)"; E1-05 should measure it instead. No change to the list.

### 2026-10-21 16:20 · E1-03 · passes

- **What changed:** new `lib/deploy.mjs` (pure guards: `vercelGuarded`/`addVercelGuard`/`vercelMergeable`, `netlifyGuarded`/`addNetlifyGuard`, `vercelDeployments`, `slug`, `unguarded` + CLI) and `lib/deploy.sh` (`deploy_status`, `deploy_guard`); `bin/harness` `cmd_init` calls `deploy_guard`; `lib/driver.sh` `deploy_check` once per run (`$STATE/deploy-checked`) after the start block, reading `origin/main`, one note per host + one notify; `tests/stub-gh.sh` answers `api repos/…/deployments` with `tests/fixtures/gh-deployments.json` (GitHub's published `deployment-items` example from github/rest-api-description, unchanged; `STUB_DEPLOYMENTS=0|vercel`); `tests/run.sh` 8 checks (plan §10) and `hlog <run> [<project>]`; D-H33; architecture §10 line. Tests 169 → 177.
- **Watched failing:** all 8 new checks FAIL on a copy without the code (169/177). The first green attempt failed 3 run-start checks only in the full suite: an earlier section drops `NTFY_URL` from the user config, so the section now uses the base config and restores it after.
- **Verified:** `bash -n` on the 5 shell files, `node --check lib/deploy.mjs`; `check.sh` green in 273 s, 177/177. An Opus review of the diff found 10 issues. Fixed: `[ build ]`, inline/dotted `build` and a quoted `"ignore"` key; Vercel detection by `creator.login == vercel[bot]` instead of any "vercel" in the JSON; the exact Netlify guard; non-object vercel.json; Vercel's "any matching `true` wins" rule; the hand-fix hint's quotes; the once-per-run check now counts 2 initializer refusals. Each has a pure assertion.
- **Next session must know:** the deploy section uses its own projects (`dproj`: `vp np dp gp`, bare origins behind `git@github.com:test/<name>.git`), and `dstart` runs end at once via `STUB_INIT_LIMIT=1`. Demo's harness-log is saved to `$T/demo-hlog.md` before gc. README for E0b is E1-08's, per the plan.
- **Known limits (recorded in D-H33):** a `--base <ref>` run is still checked against `origin/main`, as the spec says; Netlify's `exit 1` replaces its own skip for an unchanged base directory; `netlify.toml` alone counts as a host that builds every branch.
- **Proposed change:** none to the list. Question for Michael: should `deploy_check` read the run branch's base (`--base`) rather than `origin/main`? The default stays as the spec says.

### 2026-10-21 15:35 · E1-02 · passes

- **What changed:** `lib/driver.sh`: `resumed` is set before this segment logs `run <id> on …` (an earlier segment's line in `$STATE/run.log`); the start block (`sync_main` + config reload) now runs `if [[ -f $LIST ]] || (( resumed ))`, `merge_milestones` still only with a list. `tests/stub-claude.sh`: `STUB_INIT_LIMIT=1` makes the initializer replay `fixtures/usage-limit.jsonl`, exit 1. `tests/run.sh`: run 15b, check `continue after a no-list end merges main first`. `journal/decisions.md`: D-H32. Tests 168 → 169.
- **Watched failing** before the driver change: `FAIL continue after a no-list end merges main first` (168/169); the log showed `initializer` then `feature list written` with the first `merged main into harness/nolist` only after feature A. My first awk took the *last* merge line (also red after the fix); it now takes the first of each, and I re-ran it on both runs' logs: old driver exit 1, new driver exit 0.
- **Verified:** `bash -n` on the three files; `check.sh` green in 265 s, 169/169, including `resume reloads config merged from main` (run 15).
- **Next session must know:** the check copies `ended` to `$T/run15c.ended` before the continue (the continue rewrites it). Later checks gc the `nolist` worktree, so inspect it with `KEEP=1` and before gc. Docs (architecture/README) for E0 are E1-08's, as the plan says.

### 2026-10-21 15:10 · E1-01 · passes

- **What changed:** `docs/plans/2026-10-21-E1-telemetry.md` (new, base `07c8367`), 12 numbered sections: owners per file/feature, E0 (a `resumed` flag read from run.log *before* this segment's `run <id> on` line; the start block's `sync_main` + config reload run for a resumed run with or without a list), E0b (`lib/deploy.mjs` pure guards + `lib/deploy.sh`, vercel.json JSON merge, netlify `[build] ignore` for `harness/*`, origin/main read at run start, once per run via `$STATE/deploy-checked`, stub-gh deployments fixture), fixture capture command and fields, metrics keys, summary formulas, ledger + `trends --by version`, 17 check names, D-H32/33/34. No code. Tests 168 → 168.
- **Verified:** `head -1` = `Milestone base: 07c8367…`; `git status` shows only the plan; `check.sh` green, 168/168 checks passed.
- **Next session must know:** tokens combine by **max** (like cost), taken from `modelUsage` (fallback `usage`); E1-04 confirms with `Σ modelUsage.costUSD == total_cost_usd` on the capture and switches to sum if not. `orient_s` = null without timestamps. Orientation dedupes assistant events by `message.id`. Stub `ok()` must use `--argjson r "\"$2\""` so `\\n` in PARKED finals still become newlines (§5.4). The default gh-deployments fixture (creator octocat) must *not* count as Vercel, or the demo run logs a guard note.
- **Milestone PR heads** are `harness-merge/<run>-<m>`: the guards don't match them, so each PR still gets one preview.
- **Proposed change:** E1-03's step list doesn't name the check for Vercel detection via the API (`STUB_DEPLOYMENTS=vercel`); the plan adds it (§10).

### 2026-10-21 14:30 · initializer · feature list written (29 features)

**Counts per milestone.** E1 (E0 + E0b + telemetry): 9 · E2 (replay set, `harness eval`): 8 · E3 (prompt hygiene): 5
· E4 (journal + context pack): 7. Order E1 → E2 → E3 → E4 as the brief says; E3 waits only on E1 (the spec's
table), E4 on E3, E4-06 (docs, writes the final `evals/NEXT.md`) on E2 too. Every milestone: plan → builds (pure rules
before wiring, test first) → docs (Sonnet) → review + simplify (Opus, reads the diff from a file in scratch).

**Scope decisions taken here (the brief wins; defaults recorded, nothing parked).**
- `MERGE_POLICY=pr` is the project's config: verified milestones open PRs; Michael merges.
- Evals are built and documented, never run (`evals/NEXT.md` carries the commands). The tags the harness will create
  are predictable: `run/agent-harness-2026-10-21-measure/E2`, `/E3`, `/E4`; NEXT.md uses them as `--harness` refs.
- D-H numbers reserved: D-H32 E0 · D-H33 E0b · D-H34 telemetry (+ harness_version) · D-H35 evals · D-H36 no double
  CLAUDE.md · D-H37 static first · D-H38 clock line + bounded init output · D-H39 journal, single writer · D-H40
  rendered progress.md · D-H41 context pack. The last entry today is D-H31; each plan feature re-checks for collisions
  (the retro-fixes spec may land in parallel and take numbers: if so, shift and say so in the plan).

**Where things live (read before building).**
- `lib/driver.sh` (551 lines): `prompt()` ~line 138 assembles prompts (`render.mjs` + titled sections: brief,
  CLAUDE.md, `.harness/project.md`, policy); `session()` runs `claude -p … --output-format stream-json`; the main loop
  from ~line 455; `verify()` ~line 290 counts `### … verify <m>` headers in progress.md and calls `F evidence` on it;
  `pr_body()` quotes the verify entry from progress.md with awk. `sync_main` today runs only when the list exists
  (`if [[ -f $LIST ]]` ~line 430): that is the E0 bug.
- `lib/metrics.mjs`: `events()`, `outcome()` (cost = max over result events, turns summed), `environmental()`;
  `append` writes the metrics row. `lib/summary.mjs`: `build()` → summary.json, `report()`, `ledger-line`, `trends`,
  `calibration`. `lib/features.mjs`: every list operation (`next`, `repair`, `evidence`, …), header lists the verbs.
- `tests/run.sh` (168 checks, ~4 min): `check "<name>" '<bash expr>'`; runs named `demo`, `walled`, `legacy`, `flip`
  … against `tests/stub-claude.sh` (keys on the prompt's first line; `STUB_*` env vars script misbehaviour; `ok()`
  prints the result event) and `tests/stub-gh.sh` (PRs are files; `pr merge` merges into the bare origin).
  `tests/stub-curl.sh` logs every post to `$T/curl.log`. Helpers: `hlog <run>`, `list <run>`, `curl_count`,
  `on_main`. Fixtures mirror the live API (`tests/fixtures/usage-limit.jsonl` is a real 2026-10-17 capture).
- `bin/harness`: subcommand dispatch at the bottom (`case ${1:-help}`), `cmd_init`, `cmd_start` (a worktree from
  `origin/<branch>` when the branch exists, else from `--base`/origin/main), `cmd_continue`. Usage header lines 2–38
  are the help text. `lib/config.sh`: defaults and layers; `weekly_over` reads `USAGE_7D`.
- Prompts: `prompts/{initializer,coding,verify,retro,debrief,desk,supervisor}.md`, policies in `prompts/policy/`.
  The debrief (`lib/debrief.sh`) renders its own prompt in its workspace, not in a worktree.
- Docs: `docs/architecture.md` (§4 state table, §10 configuration + prompt assembly, §11 measurement),
  `journal/decisions.md` (`### D-H<n> · title *(accepted <date>…)*`, finding · choice · rejected), plan files
  `docs/plans/<date>-<milestone>-<topic>.md` starting with `Milestone base: <sha>` (see the 2026-10-19 P1 files).
- The project's suite is `bash tests/run.sh` (`.harness/config.sh`); run `{{CHECK}}` as the prompt says.

**Gotchas.**
- Never touch `~/projects/agent-harness` (the live harness), `~/.local/state/harness`, `ledger/`, `journal/raw/`,
  other `~/worktrees/*`. Eval task sources are read-only: `~/projects/{dj-crate-streaming,portfolio_site}/.harness/runs/`
  exist on main; pathways and hit_list have none on main (`git log --all -- .harness/runs` may find them on branches).
- The stub's result event has no `usage`; E1-04 captures a real one (haiku, about a cent) and makes `ok()` replay it.
  That capture is the one live call in this run; it is the spec's instruction and the fixture rule's requirement.
- `MERGE_POLICY=off` already exists: the eval uses it (the spec's "none"). `gh_url` returns nothing for non-GitHub
  origins, so a local bare origin yields no links and no `gh` calls; set `HARNESS_GH=false` anyway.
- `harness eval run` adds a git worktree of this repo under `/tmp/harness-eval/…`; tests must remove it (`git worktree
  remove`) or the real repo keeps a stale entry. Never let the eval read the real state root in tests
  (`HARNESS_STATE` is set by `tests/run.sh`).
- E3 changes the first line of every prompt; the stub extracts the feature id from it today
  (`# Coding session — \`id\``). Change the stub in the same feature or every run check fails.
- E4: `verify()` and `pr_body()` read progress.md. Render it before those reads, keep the five-column table shape, or
  verification breaks silently (evidence rows counted = 0 → escalation → "not verified").
- Existing check `brief, rules and policy in the prompt` greps `Project rules (CLAUDE.md)`; E3-02 rewrites it.

**Questions for Michael (defaults taken; answer in INBOX.md to change them).**
1. The fixture capture (E1-04) spends about a cent on a real haiku call under a build-only policy. Default: do it,
   once, and record it in D-H34. Say `no capture` to have the builder use the usage fields from a transcript you
   provide instead.
2. Netlify guard shape: default is a `[build] ignore` command in netlify.toml that exits 0 for `harness/*` refs,
   other keys kept. Vercel's is `git.deploymentEnabled { "harness/**": false }` as the spec says.
3. Eval tasks come from dj-crate-streaming and portfolio_site records (and whatever pathways/hit_list keep on
   branches). Default: 8–12 tasks from those, all forced build-only, none needing a live system.
4. `harness trends --by version` columns: runs, passing/total, $/feature, median cache hit rate, median orientation
   tokens, first-attempt rate. Default as listed; change in E1-07's plan section if you want others.
