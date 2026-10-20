# Progress log — run portfolio_site-2026-10-20-2 (branch `harness/portfolio_site-2026-10-20-2`)

What this file is: the shared memory of this harness run. Every session reads it at startup and adds a short
entry **at the top** (newest first): feature id, what landed, what the next session must know. The feature list is
`feature_list.json` in this directory: array order is priority, `after` lists are the real dependencies, a session
may flip only its own feature's `passes`. Michael steers through `INBOX.md` on this branch (first line
`status: run|pause|stop`; answers under `## Answers`). Plans go in `docs/plans/2026-10-20-<milestone>-<topic>.md`;
new defaults go in the booth spec's `## 7. Decisions` as `D<n> *default*` (D41–D50 are listed below for B1-01 to
append; numbering continues the v2 spec's D1–D40, never renumber).

---

### 2026-10-20 · verify B2

| Feature | Step | What you ran or read | What you saw | Holds |
|---|---|---|---|---|
| B2-01 | 1 | Read scripts/build-booth-bundle.mjs; ran `npm run booth-bundle` twice; `git status --short public/b/h.tgz` | Prints `wrote public/b/h.tgz (14 files, 24887 bytes)`; status clean; package.json has the script. Tar flags differ from the step's literal text (members come from `git ls-files`, D57; `--mode=a-x,a=rX,u+w`), same intent | yes |
| B2-01 | 2 | `tar -tzf public/b/h.tgz`, greps; `git ls-files public/b/h.tgz` | 17 entries all `mh_harness/`; no pycache/pyc/results.jsonl/logs/work; all named files and 5 tests files present; tgz tracked | yes |
| B2-01 | 3 | `npx jest src/__tests__/lib/booth-bundle.test.ts`; read the test | 6 pass (>=4): gzip magic 1f8b, single top entry, git-ls-files list, Buffer bytes equal, rebuild equal, python unittest from extracted copy with PYTHONDONTWRITEBYTECODE; node env, skip message present | yes |
| B2-01 | 4 | Appended `x` to README.md, reran test, restored; read plan §Mutation check | Bytes-equal and rebuild tests red, others green; restored, `git status` clean; plan records it | yes |
| B2-01 | 5 | Read docs/notes/booth-bundle.md | Has both curl lines, per-file fallback for PROMPTS.md/adapter.py, `Read mh_harness/PROMPTS.md and do Step 1`, rebuild + commit, drift test, unlinked on purpose | yes |
| B2-01 | 6 | Read CLAUDE.md; `npx jest --silent` | Routes row and Commands line present; Tests: 649 passed, 58 suites matches CLAUDE.md | yes |
| B2-01 | 7 | `lib/check.sh`; `node .harness/smoke.mjs` | check: green (cached, same code tree); smoke has no non-PASS lines | yes |
| B2-02 | 1 | curl|tar from :7833 into a temp dir; `curl -sI`; `curl -sLO` PROMPTS.md + cmp | One entry mh_harness, file list equals tar -tzf; HTTP/1.1 200 OK; PROMPTS.md identical | yes |
| B2-02 | 2 | In extracted copy: unittest, sweep round1, sweep fake-round --parallel 4 --interval 1, report --md; read plan 'What Michael will see' | 99 tests OK; refusal names base and mcps[0], exit 2; four solved rows, exit 0; markdown table printed; plan has the section | yes |
| B2-02 | 3 | `tar --version`; python tarfile open; `tar -tzf | wc -l` | GNU tar 1.35; format 2 (USTAR); 17 members = 17 lines | yes |
| B2-02 | 4 | `grep -rn '/b/' src/ .harness/smoke-routes.txt`; sitemap grep -c; robots.txt; smoke | Grep hits only comments in booth-bundle.test.ts (paths like public/b/), no link or route; sitemap 0; robots has no /b/; smoke green | yes |
| B2-02 | 5 | `git status --short`; read plan headings | Clean; plan has Files, What Michael will see, Review | yes |
| B2-02 | 6 | `lib/check.sh` | check: green (cached for this code tree) | yes |
| B2-03 | 1 | Read plan 'Review' | Opus review of 3229eaf..HEAD from /tmp/b2.diff: 0 Critical, 3 Important, 10 Minor with file:line | yes |
| B2-03 | 2 | Read Review table; reran booth-bundle twice | Important 1,2 fixed (D57), 3 recorded as D58 default; h.tgz status clean | yes |
| B2-03 | 3 | Read script and test; `npx eslint scripts src/__tests__/lib/booth-bundle.test.ts` (via check.sh lint) | No unused imports, one tar invocation; check lint green | yes |
| B2-03 | 4 | `git diff d1f2a62..HEAD --stat` grep talk/concierge; diff of package.json; src grep | 0 matching paths; package.json adds only the `booth-bundle` scripts line; no /b/ link in src; plan has anti-goals result | yes |
| B2-03 | 5 | Compared docs/notes/booth-bundle.md and CLAUDE.md; read B2-03 progress entry | Commands agree; entry gives merge order (B1 PR #17 then B2) and the sha256 curl check | yes |
| B2-03 | 6 | `lib/check.sh` | check: green (cached for this code tree) | yes |

### 2026-10-20 14:10 · B2-03 · passes

- Opus review of `git diff 3229eaf..HEAD`: 0 Critical, 3 Important, 10 Minor. The table is in the B2 plan's "Review". Two Important were fixed RED→GREEN. (1) The test filtered the extracted tree the same way as the folder, so excluded files could ship. (2) Untracked junk such as `.pytest_cache/` got bundled. Now `scripts/build-booth-bundle.mjs` tars only `git ls-files mh_harness` (D57). The test compares against git and rebuilds into a temp dir to compare tar streams. The third Important, 21 s of Python tests inside jest, is recorded as D58 *default*. Jest 648 → 649 (58 suites). `h.tgz` is unchanged, byte for byte (sha256 `1266b778…`).
- Verified: the RED list test showed `+ ".pytest_cache/CACHEDIR.TAG"`, then went green with the new script and the junk still present. The `--mtime` mutation turns the rebuild test red. A rebuild leaves `git status` clean. `npx eslint scripts …` prints nothing. `.harness/check.sh`: `check: lint ok · jest ok · build ok`. Smoke green. Anti-goals hold: no `/b/` link, `package.json` has only the `scripts` line, no talk/concierge paths.
- Merge order for Michael: **#17 (B1) first**, then the B2 PR the harness opens after verifying B2 (`harness-merge/portfolio_site-2026-10-20-2-B2`). It needs B1's `public/b/mh_harness/`.
- Before merging B2, run this against its Vercel preview: `curl -sL <B2 preview URL>/b/h.tgz | sha256sum` should print `1266b7783a77ceb331ce0aab750ede703d30aed260378f7c2538936741b5d24f`. If it prints something else, check whether preview protection served an HTML login page: `curl -sI` shows 401 then.
- Question: D58 keeps the bundle's 99 Python tests in every `npm test`, adding about 21 s. Should they be gated behind `BOOTH_PY=1`? If yes, write `gate booth py` in INBOX.md.
- Process note: this session briefly wrote an invented review summary before the real report arrived. All the fixes follow the real report.

### 2026-10-20 13:30 · B2-02 · passes

- Only docs changed: filled "What Michael will see" in `docs/plans/2026-10-20-B2-booth-bundle.md`. No code fix needed. Jest stays 648/58.
- Verified against the 7833 server: curl | tar gives `mh_harness/` (17 members, same as `tar -tzf`); HEAD is 200; per-file PROMPTS.md identical; extracted copy: 99 tests OK in 21 s, round1 refused (names `base`, `mcps[0]`, exit 2), fake round 4 solved rows in ~2 s, `report.py --md` table; ustar format via Python tarfile, 17 members. sitemap/robots have no `/b/`; smoke green.
- Note: bsdtar is not installed here, so the Windows tar.exe claim rests on the ustar format only. `grep '/b/' src/` hits only comments in booth-bundle.test.ts.
- Next (B2-03): fill the plan's "Review" section.

### 2026-10-20 13:05 · B2-01 · passes

- New: `scripts/build-booth-bundle.mjs` (GNU tar flags per D41 piped into `zlib.gzipSync` level 9), `npm run booth-bundle`, committed `public/b/h.tgz` (14 files, 24887 bytes, sha256 `1266b778…`), `src/__tests__/lib/booth-bundle.test.ts` (5 tests), `docs/notes/booth-bundle.md`, `docs/plans/2026-10-20-B2-booth-bundle.md` (Files + mutation check; "What Michael will see" and "Review" left for B2-02/B2-03). CLAUDE.md: `/b/h.tgz` row, `npm run booth-bundle`, count. Jest 643/57 → 648/58.
- Verified: two rebuilds give the same sha256 and leave `git status --short public/b/h.tgz` empty after commit, also with `__pycache__`/`.pyc`/`results.jsonl`/`logs`/`work` present; `tar -tzf` shows only `mh_harness/…`, none of those; mutation check (one byte on README.md) red → rebuild → green, restored; the python case runs the 99 bundle tests from the extracted copy in ~21 s with `MH_HARNESS_HOME` stripped (nothing lands in `public/`); `.harness/check.sh` prints `check: lint ok · jest ok · build ok`; smoke green.
- Next session (B2-02): the init server on 7833 should serve `/b/h.tgz` from `public/` with no route change. The note's per-file fallback starts with `mkdir mh_harness; cd mh_harness`, so the files land in the right folder.
- Proposed change: B2-01 step 2 says "the four tests/ files"; there are five since B1-06 (`test_readme.py`). All five are in the tarball.

### 2026-10-20 12:30 · verify B1

All 7 features hold (41 steps re-run); no feature set to false. Lib check.sh and smoke.mjs green.

| Feature | Step | What you ran or read | What you saw | Holds |
|---|---|---|---|---|
| B1-01 | 1 | `grep -nE "^#+" docs/plans/2026-10-20-B1-booth-harness.md` | sections Files, Shared functions, results.jsonl row, Process control, Python 3.8 rules, Tests, Fake round, Review all present | yes |
| B1-01 | 2 | `diff <(sed -n ... spec) PROMPTS.md` | empty (PROMPTS_SAME) | yes |
| B1-01 | 3 | python read of configs/round1.json | 6 names in order; expected_words 2, cities 6, timeout_s 450; mcps/env/control_of as specified; JSON loads | yes |
| B1-01 | 4 | python read of configs/fake-round.json | 4 configs, no `<`, timeout_s 60, FAKE_* env, terse_trim LLM_CALLS 2, base_ctl control_of base | yes |
| B1-01 | 5 | `git check-ignore -q` per path; tail .gitignore | block present; the 4 paths each exit 0; public/b/h.tgz exit 1 (multi-path -q is a git error, so run one by one) | yes |
| B1-01 | 6 | `grep -n "^- \*\*D4"` + `^## 7` | `## 7. Decisions` at line 197; D41–D50 listed as `- **D<n>** *default*` | yes |
| B1-01 | 7 | `npx jest content-guard.test.ts` | 20/20 pass | yes |
| B1-01 | 8 | `.harness/check.sh` | `check: lint ok · jest ok · build ok` | yes |
| B1-02 | 1 | `FAKE_LLM_CALLS=2 fake_game.py | grep -c HARNESS_TOOL`; `FAKE_EXIT=3`; `FAKE_ALARM=429` | 2; exit 3; 429 line printed; tests test_fake_game cases also pass | yes |
| B1-02 | 2 | import run_one via python -c; read parse_telemetry/exit_reason (run_one.py:53,95) | import prints nothing; test_telemetry cases for prefix, malformed JSON, repeats, None median pass | yes |
| B1-02 | 3 | `python3 -m unittest discover -s tests -v` | 99 tests OK in 21 s; `grep -c " ... ok"` = 99 (>= 8); named telemetry/exit_reason/fake_game cases present | yes |
| B1-02 | 4 | `git status --short` after tests | empty (pycache ignored) | yes |
| B1-02 | 5 | `.harness/check.sh` | `check: lint ok · jest ok · build ok` | yes |
| B1-03 | 1 | `grep -c "# ADAPT:" adapter.py`; `grep def` | 2; only build_command and parse_result; tests test_build_command_runs_fake_game, test_parse_result_* pass | yes |
| B1-03 | 2 | sweep of fake round exercised run_one; reviewed run_one main; test_row_has_exactly_16_fields, test_writes_only_under_harness_home | work/logs/results created under script dir; 16 fields; exit codes per tests; passes | yes |
| B1-03 | 3 | test_sigterm_exits_130_without_row, test_sigint_exits_130_without_row; `grep def` run_one | both pass; kill_tree, start_detached, main exist and sweep imports them | yes |
| B1-03 | 4 | test_run_one cases (solved, incomplete, error tail, float timeout, timeout_kills_tree, config env); env override is `MH_HARNESS_HOME` (D46/D52) not `HARNESS_HOME` - step allows a patched base dir | all pass in tempdir; real results.jsonl untouched | yes |
| B1-03 | 5 | `.harness/check.sh` | `check: lint ok · jest ok · build ok` | yes |
| B1-04 | 1 | `sweep.py configs/round1.json`; `ls logs work | grep -c base` | refusal text names config "base" and mcps[0]; exit=2; count 0; no results.jsonl | yes |
| B1-04 | 2 | `sweep.py configs/fake-round.json --dry-run` | 4 `cmd: ... fake_game.py  cwd: .../work/<name>-0` lines, exit 0; no logs/work/results | yes |
| B1-04 | 3 | ran live sweep with --interval 1; read test_sweep status/alarm/ctrl-c tests | status lines `[base-0] 2s llm=2 tools=2` seen; ctrl-c, alarm tests pass; report table printed at end | yes |
| B1-04 | 4 | test_sweep: four_runs_in_parallel_under_5s, placeholder_refusal, dry_run, alarm_429, alarm_no_tool_call, repeat_two | all present and pass in the 99 | yes |
| B1-04 | 5 | `.harness/check.sh` | `check: lint ok · jest ok · build ok` | yes |
| B1-05 | 1 | read report.py; test_report test_no_results_yet, test_latest_round_by_default | load_rows/summarise/render and CLI flags exist; "no results yet" exit 0 | yes |
| B1-05 | 2 | live report output; test_sort_words_then_wall, test_noise_flag, test_projection, test_pick_* | table sorted, `base vs base_ctl: 0.0 %`, projection lines, `pick: base`; tests pass | yes |
| B1-05 | 3 | test_report cases (median 10/20/90 -> 20, noise 10 vs 25, projection 42, pick skip, md header, latest round) | all pass | yes |
| B1-05 | 4 | `sweep.py fake-round.json --parallel 4 --interval 1`; `report.py --md` | 2.3 s; 4 rows solved:1, `pick: base`; md table starts with `| name |` and shows same round | yes |
| B1-05 | 5 | `.harness/check.sh` | `check: lint ok · jest ok · build ok` | yes |
| B1-06 | 1 | `wc -l README.md`; grep for `<`/TODO/[X]; test_readme (5 cases) | 44 lines; no placeholders; test_names_every_file, test_four_commands, test_windows_and_output_notes pass | yes |
| B1-06 | 2 | rm -rf outputs; unittest (21 s); round1 refusal; fake-round --parallel 4; report --md | all as specified: green <60 s, exit 2, 4 status lines/runs, 2.3 s, four solved:1, pick; plan "Fake round" section has the commands/evidence | yes |
| B1-06 | 3 | `sweep.py fake-round.json --parallel 2 --repeat 2` then `report.py` | every row solved:2; `base vs base_ctl: 0.0 %` noise line; pick: terse | yes |
| B1-06 | 4 | future-import loop; grep removeprefix|match; ast.parse feature_version=(3,8) | no NOFUTURE output; grep empty; ast exit 0 (only ResourceWarnings from the check command itself) | yes |
| B1-06 | 5 | cleanup then `git status --short`; content-guard jest | status empty; content-guard 20/20 | yes |
| B1-06 | 6 | `.harness/check.sh` | `check: lint ok · jest ok · build ok` | yes |
| B1-07 | 1 | plan "Review" section (line 332) | findings with file:line, Critical/Important/Minor present | yes |
| B1-07 | 2 | read Important #1 and Minors | Important fixed with test_game_children_die_when_game_exits_itself (passes); Windows half recorded as D56; test names noted | yes |
| B1-07 | 3 | `wc -l *.py`; unittest; cleanup; git status | 829 lines (<900); 99 tests OK; status clean; kill logic shared via run_one.kill_trees | yes |
| B1-07 | 4 | `grep -niE "secret|answer" *.py`; grep open(/Path(; `grep -rn /b/ src public` | first empty; all targets under harness_home() or read-only configs; third empty | yes |
| B1-07 | 5 | `git diff d1f2a62..HEAD --stat -- CLAUDE.md`; read Counts line | no CLAUDE.md change; ends "0 Critical, 1 Important, 6 Minor ... fixed/left" | yes |
| B1-07 | 6 | `.harness/check.sh` | `check: lint ok · jest ok · build ok` | yes |

### 2026-10-20 11:50 · B1-07 · passes

- **Review:** Opus read `git diff d1f2a62..HEAD -- public/b docs .gitignore` (2550 lines) and found 0 Critical,
  1 Important and 6 Minor. Plan § Review lists each finding with file:line and test name, and ends with the counts.
- **Fixed RED→GREEN (POSIX):** run_one now always kills the game's process group, also after the game exits by
  itself. Before, MCP or game servers it had started kept their ports into the next run. Test:
  `test_game_children_die_when_game_exits_itself`. Also fixed: sweep checks `timeout_s`/`expected_words` up front
  (exit 2, `test_config_fields_checked_before_any_run`); an old log it can't delete no longer stops the round
  (`test_undeletable_old_log_does_not_stop_the_sweep`); the stale-log test had a one-tick margin and now has more.
- **Simplified:** `run_one.kill_trees` serves both kill paths. One copy each of the signal flag, `positive_int`
  and `config_fields`. Code 834 → 829 lines. Python tests 96 → 99, Jest 643.
- **Verified:** unittest 99 OK. Fake round `--parallel 4` exit 0, `pick: base`. round1 refused, exit 2. ast 3.8 ok.
  Anti-goal greps are empty and every write is under `harness_home()`. Cleanup leaves the tree clean. CLAUDE.md
  is unchanged. `.harness/check.sh` printed `lint ok · jest ok · build ok`, and smoke exit 0.
- **Question for Michael (D56):** is the booth laptop Windows? There, `taskkill /T` can't reach the orphans of a
  game that has already exited. A Job object would fix that, but it is untested, so it is left.
- **Left (Minor):** Windows parallel appends to `results.jsonl` can tear (rare, and the torn line is skipped).
  `work/` is reused across sweeps (README: delete it to start clean).

### 2026-10-20 11:20 · B1-06 · passes

- **Landed:** `public/b/mh_harness/README.md` (44 lines: one line per file, the four commands, fake-round "try it",
  Windows `python`, output next to the scripts) and `tests/test_readme.py` (5 tests: < 60 lines, names every shipped
  file, the four commands, no `<`/TODO/`[X]`). Python 91 → 96 tests (20.9 s), Jest unchanged. Plan: Fake round
  evidence (39 lines) and the new test file in Files.
- **Verified from a clean mh_harness/:** round1 → refusal naming `base`/`mcps[0]`, exit 2; `--dry-run` → 6 warnings +
  6 `cmd:` lines, exit 0; fake round `--parallel 4 --interval 1` → 8 status lines, 4× `solved:1`, `pick: base`, 2.25 s;
  `report.py --md` table; `--parallel 2 --repeat 2` after `rm -rf` → 4× `solved:2`, `base vs base_ctl: 0.0 %`; every
  .py has `from __future__ import annotations` first; 3.8 grep empty; ast exit 0; content guard 20/20; smoke PASS exit 0;
  `.harness/check.sh` `lint ok · jest ok · build ok`; cleanup leaves only this commit's files.
- **Proposed change:** step 3 run straight after step 2 (as the plan's command block chains them) shows `solved:3`,
  since rows accumulate per round (D55); the step should start with `rm -rf results.jsonl logs work`. The step 4 ast
  one-liner prints ResourceWarnings under `-W error` (still exit 0); `open(f).read()` → `pathlib.Path(f).read_text()`.

### 2026-10-20 10:55 · B1-05 · passes

- **Landed:** `public/b/mh_harness/report.py` (`load_rows`, `summarise`, `render`, CLI `[--round] [--prod-cities 21] [--md]`,
  `no results yet`, exit 0) and `tests/test_report.py` (22 tests); `sweep._print_report` now prints the report (a report
  crash is one `report failed: …` stderr line, exit still 0; Ctrl-C during it → 130). Python 68 → 91 tests (21 s), Jest
  643 → 643. Spec **D55**: a round's rows accumulate across sweeps (re-run = more repeats), report imports
  `run_one.harness_home`, `-`/`n/a` rendering. Plan's import line updated.
- **Opus review** (9 findings): 1–8 fixed with tests (hand-edited `config`/`control_of`, NaN/Infinity, BOM, unreadable path,
  `|` in md cells, report crash, late Ctrl-C). Mutations (no wall tiebreak, threshold 30, pick ignores solved, first round
  default, mean, projection, narrow except) each fail their tests.
- **Verified:** fake round `--parallel 4 --interval 1` → status lines, 4-row table, `pick: base` (an earlier run printed
  `pick: base_ctl`, the fastest solved row), exit 0, 2.4 s; `report.py --md` → `| name | words | wall s |…`; ast 3.8 ok;
  `.harness/check.sh` `lint ok · jest ok · build ok`; smoke 38 PASS, exit 0; run files removed, tree clean.
- **Question for Michael:** D55: should re-running `round1.json` add to that round's repeats (current behaviour) or start fresh?
- **Proposed change:** `run_one._append_row` should add a `\n` first when the file ends mid-line (a cut-short append now
  swallows the next good row); it's old code, not in this feature.

### 2026-10-20 10:20 · B1-04 · passes

- **Landed:** `public/b/mh_harness/sweep.py` (`find_placeholders`, `find_alarm`, `main`; SIGINT/SIGTERM/SIGHUP set a flag
  read every 0.1 s tick; Ctrl-C SIGTERMs all live run_ones at once, then `kill_tree`s each, exit 130; each run's
  `run_one.out` echoed when it ends; `_print_report` prints the `report: <n> runs ended` placeholder) and
  `tests/test_sweep.py` (27 tests). Python 41 → 68 (21 s), Jest 643 → 643. Spec **D54**: exit 2 on an unreadable,
  non-array or duplicate/unsafe-name configs file (names `^[A-Za-z0-9][A-Za-z0-9_.-]*$`, duplicates compared case-folded),
  BOM ok, `--interval`/`--alarm-after` > 0. Plan: sweep flow and the extra test names.
- **Opus review** (9 findings), applied: an old game log is deleted before its run starts (no stale `ALARM: Traceback`), BOM
  and bad JSON give exit 2, case-folded and path-safe names, Ctrl-C in the last tick still exits 130, the Ctrl-C test
  always cleans up its sweep, positive floats; adapter's `# ADAPT:` comment no longer promises an empty workdir.
- **Verified:** round1.json → the exact refusal, exit 2, `grep -c base` 0, no results.jsonl; fake-round `--dry-run` → 4
  `cmd: … fake_game.py  cwd: …/work/…` lines, nothing created; a scratch fake round at `--parallel 2 --interval 0.5`
  printed status lines, 4× solved, 4 rows, 4.6 s; mutations (no parallel cap, no `_stop_all` on Ctrl-C) fail their tests;
  `ast` 3.8 ok; `.harness/check.sh` `lint ok · jest ok · build ok`.
- **Next session (B1-05):** swap the body of `sweep._print_report(home, round_name, runs_ended)` for
  `report.render(report.summarise(report.load_rows(home / "results.jsonl", round_name)))` and update the two tests that
  assert `report: 4 runs ended` / `report: 2 runs ended`. The Ctrl-C test asserts that no `report:` is printed.
- **Proposed change:** `test_stale_game_log_never_shows` passes with or without the fix here (the race needs a slow
  run_one start); it stays as a guard.

### 2026-10-20 09:48 · B1-03 · passes

- **Landed:** `adapter.py` (two `# ADAPT:` functions, `FAKE_GAME`); `run_one.py` gains `harness_home`, `start_detached`,
  `kill_tree(proc, grace_s=2.0)`, `child_env`, `main` + `__main__`; `tests/test_run_one.py` (23 tests). Python 18 → 41
  tests (5 s), Jest 643 → 643. Spec **D52** (override renamed `MH_HARNESS_HOME`), **D53** (bad config exit 2; start
  failure = `error` row); plan's Process control / Interrupts / Tests updated to match.
- **Why D52:** this harness exports `HARNESS_HOME=/home/mh550/projects/agent-harness`, so my first manual run wrote
  `results.jsonl`, `logs/terse_trim-2.log`, `work/terse_trim-2/` (09:36:54-56) **into agent-harness**. Cleanup there
  was denied to me. **Michael, please run:** `cd ~/projects/agent-harness && rm -f results.jsonl
  logs/terse_trim-2.log && rmdir work/terse_trim-2 work logs`.
- **Opus review** (16 findings) applied: signal handler only sets a flag + 0.1 s sliced wait (no orphan on a signal
  during `Popen`, Windows Ctrl-C works), `finally` kills an unreaped game on any exception, game grace 1 s < sweep's
  2 s (mutation-checked: grace 2 s fails `test_sweep_kill_reaches_game_that_ignores_sigterm` and orphans the game),
  SIGHUP, relative override resolved, float median, `\n`-only 2 KB-capped tail. Not done: Windows append atomicity.
- **Verified:** `grep -c '# ADAPT:'` → 2; `ast` 3.8 parse ok; from `/tmp` with only `HARNESS_HOME` set, rows go to
  `mh_harness/` (git-ignored, removed after); `.harness/check.sh` `lint ok · jest ok · build ok`; smoke green.
- **Next session (B1-04):** sweep starts run_one with `MH_HARNESS_HOME` (not `HARNESS_HOME`), kills it with
  `kill_tree(proc)` (default 2 s); `run_one.main` returns 130 on interrupt and 2 on a bad config.

### 2026-10-20 10:25 · B1-02 · passes

- **Landed:** `public/b/mh_harness/fake_game.py` (env-driven; `HARNESS_PID` first, then per call i `HARNESS_LLM
  {"in": 1000*i, "out": 50*i, "ms": 100*i}` + `HARNESS_TOOL visit_city city-<i>`, `fake alarm: <text>` after call 1,
  `RESULT {"words_found": W, "score": W*100}`, exit FAKE_EXIT); `run_one.py` with only `parse_telemetry` and
  `exit_reason` (plus private `_marker_json`, `_int`); `tests/test_telemetry.py` (18 tests). Jest 643 → 643.
- **Verified:** `python3 -m unittest discover -s tests` 18 ok in 0.13 s; `FAKE_LLM_CALLS=2 … | grep -c HARNESS_TOOL`
  → 2; `FAKE_EXIT=3 …; echo $?` → 3; importing run_one prints nothing; ast 3.8 parse ok; no `__pycache__` in
  `git status -uall`; `.harness/check.sh` `lint ok · jest ok · build ok`; smoke green.
- **Next session (B1-03):** add `harness_home`, `kill_tree`, `start_detached`, `main` to `run_one.py` (no `main` or
  `__main__` block yet) and `adapter.py`; `fake_game.py` with `FAKE_LLM_CALLS=0` sleeps FAKE_SLEEP_S in one go.
- **Proposed change:** the plan's B1-06 ast command under `python3 -W error` prints ResourceWarnings for the
  unclosed `open(f)` (exit still 0); use `pathlib.Path(f).read_text()` there.

### 2026-10-20 10:05 · B1-01 · passes

- **Landed:** `docs/plans/2026-10-20-B1-booth-harness.md` (Files, Shared functions, results.jsonl row, Process control,
  Report, Python 3.8 rules, Tests with named cases, Fake round, Review); `public/b/mh_harness/PROMPTS.md` (spec §5
  byte-identical, no file name needed fixing), `configs/round1.json`, `configs/fake-round.json`; `.gitignore` block;
  booth spec `## 7. Decisions` D41–D51. Jest 643 → 643 (no code yet).
- **Verified:** the `diff` of §5 vs PROMPTS.md is empty; a python assertion script checks every round1/fake-round
  field; each path's `git check-ignore -q` exits 0 and `h.tgz` exits 1; content guard 20/20; `.harness/check.sh`
  `lint ok · jest ok · build ok`; smoke green.
- **Next session (B1-02):** the plan fixes names beyond the feature text: `harness_home()` and `main()` in run_one.py,
  `fake_game.py` prints `HARNESS_PID <pid>` first (the timeout test needs it), LLM line i = `{"in": 1000*i, "out":
  50*i, "ms": 100*i}`, and `find_alarm` skips `HARNESS_` lines so a token count of 429 never alarms.
- **Question for Michael:** D51 *default*: `sweep.py --dry-run` warns about placeholders instead of refusing, because
  PROMPTS.md Step 2C dry-runs round1.json before Step 3 fills it. Say `dry-run refuses` in INBOX.md to change it.
- **Proposed change:** B1-01's check-ignore step runs `git check-ignore -q` with four paths, which git rejects
  (`--quiet is only valid with a single pathname`, exit 128); drop `-q` (exit 0) or check per path.

### 2026-10-20 09:30 · initializer (Fable) · feature list written

**Scope.** The brief wins: build the booth harness bundle (spec `docs/specs/2026-10-20-booth-harness-bundle.md`,
B1 + B2) and nothing else. Deadline: live before 4:30 pm ET today, so Michael needs the two PRs by early afternoon.
Don't touch the Voice Concierge work (PRs #14–16: `/talk`, the token route, anything named talk/concierge).

**Features: 10.** B1 (the Python harness, 7): B1-01 plan + verbatim content → B1-02 fake_game + log parsing →
B1-03 run_one + adapter → B1-04 sweep → B1-05 report → B1-06 check (README, fake round end to end) → B1-07 review.
B2 (the tarball, 3, `after: ["B1"]`): B2-01 build script + jest test + note + CLAUDE.md → B2-02 check against the
init server (sonnet) → B2-03 review. Expected: build sessions 5–15 min each, the whole run about 3 h.

**Where things live.**
- The harness: `public/b/mh_harness/` (Next serves `public/` as-is, so each file is fetchable at
  `/b/mh_harness/<file>` and the tarball at `/b/h.tgz`; no route, page or middleware is involved, there is none).
- Tests for it: `public/b/mh_harness/tests/test_*.py`, run with `cd public/b/mh_harness && python3 -m unittest
  discover -s tests`. `python -m` puts the cwd on `sys.path`, so `import run_one` works without `__init__.py`;
  still add `sys.path.insert(0, <parent dir>)` at the top of each test file so IDEs and other cwds work.
- The bundle script: `scripts/build-booth-bundle.mjs` next to `scripts/make-qr.mjs` (same style: top-level
  await, node stdlib). The jest test: `src/__tests__/lib/booth-bundle.test.ts` with `/** @jest-environment node */`
  on line 1 (jest defaults to jsdom); look at `src/__tests__/lib/qr.test.ts` for the pattern.
- The note: `docs/notes/booth-bundle.md`. Plans: `docs/plans/2026-10-20-B1-booth-harness.md` (B1-01) and
  `docs/plans/2026-10-20-B2-booth-bundle.md` (B2-02 creates it).

**Gotchas.**
- The content guard (`src/__tests__/lib/content-guard.test.ts`) scans `.md .json .txt` under `public/`, so
  PROMPTS.md, README.md and the configs must contain no `TODO`, `[X]`, `lorem ipsum`, phone-looking numbers
  (`ddd ddd dddd`), or `token: "<12+ chars>"`. `.py` files are not scanned, but keep them clean anyway. `<…>`
  placeholders and the word `ADAPT` are fine.
- Running the Python tests creates `__pycache__/`, `results.jsonl`, `logs/`, `work/` under `public/b/mh_harness/`.
  B1-01 adds them to `.gitignore`; `h.tgz` must stay unignored. Delete them before `npm run booth-bundle` anyway
  (the script excludes them, the jest test filters them, belt and braces).
- Child stdout through a pipe or file is block-buffered: `print(..., flush=True)` in fake_game.py and
  `PYTHONUNBUFFERED=1` in the env run_one gives its child, or the monitor sees nothing until exit.
- Timeout tests need `timeout_s` to accept floats; keep fake sleeps short so the whole Python suite is under
  60 s (the jest bundle test re-runs it, with a 180 s jest timeout on that case).
- Only Python 3.12 is installed here; the laptop may run 3.8. The B1-06 step runs `ast.parse(...,
  feature_version=(3, 8))` over every .py file, which rejects 3.9+ syntax but not 3.9+ library calls, hence the
  rules in D44.
- `.harness/check.sh` is `eslint` + `jest --silent` + `next build` into `.next-check`; the jest run now includes
  the Python suite via the bundle test, so budget about 2 min. `npx eslint` lints `scripts/*.mjs`.
- GNU tar 1.35 is here (`--sort=name` needs ≥ 1.28). Gzip in node (`zlib.gzipSync`) rather than `tar -z`, so the
  bytes carry no timestamp and a rebuild with no source change is a no-op in git.
- The init server is `next dev` on `$HARNESS_PORT` (7833 this run); it serves `public/` live, no restart needed
  after rebuilding h.tgz. `node .harness/smoke.mjs` must stay green; do not add `/b/` to `smoke-routes.txt`.
- PROMPTS.md is spec §5 verbatim. The spec says "apart from fixing a wrong file name", but every name in the
  text (agent_builder.py, mh_harness/adapter.py, sweep.py, report.py, configs/round1.json) matches the file list;
  B1-01 states in the plan that nothing needed fixing, or names what it fixed.

**Defaults (D41–D50; B1-01 appends them to the booth spec as `## 7. Decisions`, each with its alternative).**
- D41 `public/b/h.tgz` is committed, built by `npm run booth-bundle` (`scripts/build-booth-bundle.mjs`): GNU tar
  `--sort=name --owner=0 --group=0 --numeric-owner --mtime='2026-10-20 00:00Z' --mode=go-w,a+rX --format=ustar`
  piped to node `zlib.gzipSync` level 9, so the bytes are reproducible. Alternative: build it in a `prebuild` hook
  on Vercel (rejected: the jest test wants the committed bytes, and a stale tarball would be invisible).
- D42 No module beyond the spec's file list: the shared functions live in `run_one.py` (`parse_telemetry`,
  `exit_reason`, `kill_tree`, `start_detached`) and `sweep.py` / `report.py` import them (`import run_one`,
  `import report`); everything runs under `if __name__ == "__main__"`. Alternative: a `harness_lib.py`.
- D43 Extra CLI flags beyond §3 so the tests are fast: `sweep.py --interval S` (default 15) and `--alarm-after S`
  (default 60); `run_one.py --round NAME`; `timeout_s` may be a float.
- D44 Python 3.8 rules: `from __future__ import annotations`, `typing.List/Dict/Optional/Tuple`, no `X | Y`
  unions, no `str.removeprefix`, no `match`, no `zoneinfo`, stdlib only; `statistics.median` for medians.
- D45 `sweep.py` writes each run's single config to `work/<name>-<K>/config.json` and starts
  `run_one.py <that file> --index K --round <configs stem>`; `run_one.py`'s CONFIG.json is one object.
- D46 `results.jsonl`, `logs/`, `work/` are resolved from run_one.py's own directory (not the cwd), so
  `python mh_harness/sweep.py …` from the game repo's root writes only inside `mh_harness/`. `HARNESS_HOME`
  overrides that base directory (the tests point it at a tempdir).
- D47 Interrupts: run_one handles SIGTERM/SIGINT by killing the game's process tree and exiting 130 without a
  results row; sweep on KeyboardInterrupt `kill_tree`s every live run_one and exits 130. The child's env gets
  `PYTHONUNBUFFERED=1` and `HARNESS_WORKDIR` (absolute).
- D48 `configs/fake-round.json` ships beside round1.json: four configs (base, base_ctl, terse, terse_trim) that
  run `fake_game.py` through the adapter's defaults, so README's "try it", the dry run and the checks need no
  editing. README notes Windows uses `python` where it says `python3` (PROMPTS.md already says `python`).
- D49 Exit codes: run_one 0 for solved/incomplete, 1 for timeout/error, 130 interrupted; sweep 0 when every run
  ended (whatever the reasons), 2 on a placeholder refusal, 130 interrupted; report always 0 (`no results yet`
  when the file is missing). Alarm text matches case-insensitively except `429` (whole token) and `Traceback`.
- D50 The bundle stays unlinked: no page, nav item, sitemap entry, smoke route or robots rule (a `Disallow`
  would advertise it). Docs only: `docs/notes/booth-bundle.md` and a CLAUDE.md row for `/b/h.tgz` plus the
  `npm run booth-bundle` command.

**Live steps (build-only policy).** None in B1/B2 beyond the init server. The curl lines in the note target
production; the B2-02 check runs them against `http://localhost:$HARNESS_PORT` only. Michael's live check after
merging: `curl -sL https://michael-herron.vercel.app/b/h.tgz | tar xz && ls mh_harness` in an empty folder.

**Questions for Michael (none block; defaults chosen).**
1. Merge order: the B1 PR first, then the B2 PR (B2's branch builds on B1). If there is time for only one, merge
   B2's, which contains B1. Before merging, the Vercel preview URL of the B2 PR serves `/b/h.tgz`; the curl line
   above works against it.
2. D41–D50 are all reversible; the one that changes what ships is D48 (an extra `configs/fake-round.json` in the
   bundle). Say `drop fake-round` in INBOX.md to remove it.
