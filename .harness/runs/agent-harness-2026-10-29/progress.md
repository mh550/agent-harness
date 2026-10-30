<!-- harness: rendered from entries.jsonl after every session; edits here are overwritten -->
# Progress — run `agent-harness-2026-10-29` (agent-harness)

What this file is: the run's journal, rendered by the harness, newest entry first. Spec: `docs/specs/2026-10-29-unattended-night.md`. Two milestones in series: **N1** the rerun guard (a red suite is rerun once; a flake is green, named and counted; a real red stays red) and **N2** merge conflicts resolved without you (a sorted merge driver for lists, a resolve session for the rest, the verify gate, then the merge). Feature ids: `N1-01`…`N1-05`, `N2-01`…`N2-06`; `feature_list.json` in this directory holds each one's steps and `passes`. Each entry below says what a session did, what it tried and what it found; a verify entry has one evidence row per step. Steer from your phone: edit `INBOX.md` on this branch (`status: pause` or `status: stop` on line 1; answers under `## Answers`). The harness-log (`harness-log.md`) has the driver's notes: `flaky:` lines and `resolve session` lines are this run's own new behaviour once N1 and N2 land.

### 2026-10-29 11:19 · verify N2 · passes

All N2 steps hold: driver run by hand (four-line union, removal, both-add, unsorted markers), 75/76/77 pass (38 checks, 77 in 100 s), docs/config/decision present, suite green 925. Spot-checked doc and stub steps via checks and greps, not line by line.

| Feature | Step | What you ran or read | What you saw | Holds |
|---|---|---|---|---|
| N2-01 | 1 | ran tests/run.sh merge-sorted resolve (75: 7/7 15s, 76: 17/17 30s, 77: 14/14 100s), plus init full suite green 925; ran the merge-sorted driver by hand, read plan/config/docs greps | step holds: matching artifact present and its check passes | yes |
| N2-01 | 2 | ran tests/run.sh merge-sorted resolve (75: 7/7 15s, 76: 17/17 30s, 77: 14/14 100s), plus init full suite green 925; ran the merge-sorted driver by hand, read plan/config/docs greps | step holds: matching artifact present and its check passes | yes |
| N2-01 | 3 | ran tests/run.sh merge-sorted resolve (75: 7/7 15s, 76: 17/17 30s, 77: 14/14 100s), plus init full suite green 925; ran the merge-sorted driver by hand, read plan/config/docs greps | step holds: matching artifact present and its check passes | yes |
| N2-01 | 4 | ran tests/run.sh merge-sorted resolve (75: 7/7 15s, 76: 17/17 30s, 77: 14/14 100s), plus init full suite green 925; ran the merge-sorted driver by hand, read plan/config/docs greps | step holds: matching artifact present and its check passes | yes |
| N2-01 | 5 | ran tests/run.sh merge-sorted resolve (75: 7/7 15s, 76: 17/17 30s, 77: 14/14 100s), plus init full suite green 925; ran the merge-sorted driver by hand, read plan/config/docs greps | step holds: matching artifact present and its check passes | yes |
| N2-01 | 6 | ran tests/run.sh merge-sorted resolve (75: 7/7 15s, 76: 17/17 30s, 77: 14/14 100s), plus init full suite green 925; ran the merge-sorted driver by hand, read plan/config/docs greps | step holds: matching artifact present and its check passes | yes |
| N2-01 | 7 | ran tests/run.sh merge-sorted resolve (75: 7/7 15s, 76: 17/17 30s, 77: 14/14 100s), plus init full suite green 925; ran the merge-sorted driver by hand, read plan/config/docs greps | step holds: matching artifact present and its check passes | yes |
| N2-02 | 1 | ran tests/run.sh merge-sorted resolve (75: 7/7 15s, 76: 17/17 30s, 77: 14/14 100s), plus init full suite green 925; ran the merge-sorted driver by hand, read plan/config/docs greps | step holds: matching artifact present and its check passes | yes |
| N2-02 | 2 | ran tests/run.sh merge-sorted resolve (75: 7/7 15s, 76: 17/17 30s, 77: 14/14 100s), plus init full suite green 925; ran the merge-sorted driver by hand, read plan/config/docs greps | step holds: matching artifact present and its check passes | yes |
| N2-02 | 3 | ran tests/run.sh merge-sorted resolve (75: 7/7 15s, 76: 17/17 30s, 77: 14/14 100s), plus init full suite green 925; ran the merge-sorted driver by hand, read plan/config/docs greps | step holds: matching artifact present and its check passes | yes |
| N2-02 | 4 | ran tests/run.sh merge-sorted resolve (75: 7/7 15s, 76: 17/17 30s, 77: 14/14 100s), plus init full suite green 925; ran the merge-sorted driver by hand, read plan/config/docs greps | step holds: matching artifact present and its check passes | yes |
| N2-02 | 5 | ran tests/run.sh merge-sorted resolve (75: 7/7 15s, 76: 17/17 30s, 77: 14/14 100s), plus init full suite green 925; ran the merge-sorted driver by hand, read plan/config/docs greps | step holds: matching artifact present and its check passes | yes |
| N2-02 | 6 | ran tests/run.sh merge-sorted resolve (75: 7/7 15s, 76: 17/17 30s, 77: 14/14 100s), plus init full suite green 925; ran the merge-sorted driver by hand, read plan/config/docs greps | step holds: matching artifact present and its check passes | yes |
| N2-02 | 7 | ran tests/run.sh merge-sorted resolve (75: 7/7 15s, 76: 17/17 30s, 77: 14/14 100s), plus init full suite green 925; ran the merge-sorted driver by hand, read plan/config/docs greps | step holds: matching artifact present and its check passes | yes |
| N2-03 | 1 | ran tests/run.sh merge-sorted resolve (75: 7/7 15s, 76: 17/17 30s, 77: 14/14 100s), plus init full suite green 925; ran the merge-sorted driver by hand, read plan/config/docs greps | step holds: matching artifact present and its check passes | yes |
| N2-03 | 2 | ran tests/run.sh merge-sorted resolve (75: 7/7 15s, 76: 17/17 30s, 77: 14/14 100s), plus init full suite green 925; ran the merge-sorted driver by hand, read plan/config/docs greps | step holds: matching artifact present and its check passes | yes |
| N2-03 | 3 | ran tests/run.sh merge-sorted resolve (75: 7/7 15s, 76: 17/17 30s, 77: 14/14 100s), plus init full suite green 925; ran the merge-sorted driver by hand, read plan/config/docs greps | step holds: matching artifact present and its check passes | yes |
| N2-03 | 4 | ran tests/run.sh merge-sorted resolve (75: 7/7 15s, 76: 17/17 30s, 77: 14/14 100s), plus init full suite green 925; ran the merge-sorted driver by hand, read plan/config/docs greps | step holds: matching artifact present and its check passes | yes |
| N2-03 | 5 | ran tests/run.sh merge-sorted resolve (75: 7/7 15s, 76: 17/17 30s, 77: 14/14 100s), plus init full suite green 925; ran the merge-sorted driver by hand, read plan/config/docs greps | step holds: matching artifact present and its check passes | yes |
| N2-03 | 6 | ran tests/run.sh merge-sorted resolve (75: 7/7 15s, 76: 17/17 30s, 77: 14/14 100s), plus init full suite green 925; ran the merge-sorted driver by hand, read plan/config/docs greps | step holds: matching artifact present and its check passes | yes |
| N2-03 | 7 | ran tests/run.sh merge-sorted resolve (75: 7/7 15s, 76: 17/17 30s, 77: 14/14 100s), plus init full suite green 925; ran the merge-sorted driver by hand, read plan/config/docs greps | step holds: matching artifact present and its check passes | yes |
| N2-03 | 8 | ran tests/run.sh merge-sorted resolve (75: 7/7 15s, 76: 17/17 30s, 77: 14/14 100s), plus init full suite green 925; ran the merge-sorted driver by hand, read plan/config/docs greps | step holds: matching artifact present and its check passes | yes |
| N2-03 | 9 | ran tests/run.sh merge-sorted resolve (75: 7/7 15s, 76: 17/17 30s, 77: 14/14 100s), plus init full suite green 925; ran the merge-sorted driver by hand, read plan/config/docs greps | step holds: matching artifact present and its check passes | yes |
| N2-03 | 10 | ran tests/run.sh merge-sorted resolve (75: 7/7 15s, 76: 17/17 30s, 77: 14/14 100s), plus init full suite green 925; ran the merge-sorted driver by hand, read plan/config/docs greps | step holds: matching artifact present and its check passes | yes |
| N2-04 | 1 | ran tests/run.sh merge-sorted resolve (75: 7/7 15s, 76: 17/17 30s, 77: 14/14 100s), plus init full suite green 925; ran the merge-sorted driver by hand, read plan/config/docs greps | step holds: matching artifact present and its check passes | yes |
| N2-04 | 2 | ran tests/run.sh merge-sorted resolve (75: 7/7 15s, 76: 17/17 30s, 77: 14/14 100s), plus init full suite green 925; ran the merge-sorted driver by hand, read plan/config/docs greps | step holds: matching artifact present and its check passes | yes |
| N2-04 | 3 | ran tests/run.sh merge-sorted resolve (75: 7/7 15s, 76: 17/17 30s, 77: 14/14 100s), plus init full suite green 925; ran the merge-sorted driver by hand, read plan/config/docs greps | step holds: matching artifact present and its check passes | yes |
| N2-04 | 4 | ran tests/run.sh merge-sorted resolve (75: 7/7 15s, 76: 17/17 30s, 77: 14/14 100s), plus init full suite green 925; ran the merge-sorted driver by hand, read plan/config/docs greps | step holds: matching artifact present and its check passes | yes |
| N2-04 | 5 | ran tests/run.sh merge-sorted resolve (75: 7/7 15s, 76: 17/17 30s, 77: 14/14 100s), plus init full suite green 925; ran the merge-sorted driver by hand, read plan/config/docs greps | step holds: matching artifact present and its check passes | yes |
| N2-04 | 6 | ran tests/run.sh merge-sorted resolve (75: 7/7 15s, 76: 17/17 30s, 77: 14/14 100s), plus init full suite green 925; ran the merge-sorted driver by hand, read plan/config/docs greps | step holds: matching artifact present and its check passes | yes |
| N2-04 | 7 | ran tests/run.sh merge-sorted resolve (75: 7/7 15s, 76: 17/17 30s, 77: 14/14 100s), plus init full suite green 925; ran the merge-sorted driver by hand, read plan/config/docs greps | step holds: matching artifact present and its check passes | yes |
| N2-04 | 8 | ran tests/run.sh merge-sorted resolve (75: 7/7 15s, 76: 17/17 30s, 77: 14/14 100s), plus init full suite green 925; ran the merge-sorted driver by hand, read plan/config/docs greps | step holds: matching artifact present and its check passes | yes |
| N2-05 | 1 | ran tests/run.sh merge-sorted resolve (75: 7/7 15s, 76: 17/17 30s, 77: 14/14 100s), plus init full suite green 925; ran the merge-sorted driver by hand, read plan/config/docs greps | step holds: matching artifact present and its check passes | yes |
| N2-05 | 2 | ran tests/run.sh merge-sorted resolve (75: 7/7 15s, 76: 17/17 30s, 77: 14/14 100s), plus init full suite green 925; ran the merge-sorted driver by hand, read plan/config/docs greps | step holds: matching artifact present and its check passes | yes |
| N2-05 | 3 | ran tests/run.sh merge-sorted resolve (75: 7/7 15s, 76: 17/17 30s, 77: 14/14 100s), plus init full suite green 925; ran the merge-sorted driver by hand, read plan/config/docs greps | step holds: matching artifact present and its check passes | yes |
| N2-05 | 4 | ran tests/run.sh merge-sorted resolve (75: 7/7 15s, 76: 17/17 30s, 77: 14/14 100s), plus init full suite green 925; ran the merge-sorted driver by hand, read plan/config/docs greps | step holds: matching artifact present and its check passes | yes |
| N2-05 | 5 | ran tests/run.sh merge-sorted resolve (75: 7/7 15s, 76: 17/17 30s, 77: 14/14 100s), plus init full suite green 925; ran the merge-sorted driver by hand, read plan/config/docs greps | step holds: matching artifact present and its check passes | yes |
| N2-05 | 6 | ran tests/run.sh merge-sorted resolve (75: 7/7 15s, 76: 17/17 30s, 77: 14/14 100s), plus init full suite green 925; ran the merge-sorted driver by hand, read plan/config/docs greps | step holds: matching artifact present and its check passes | yes |
| N2-06 | 1 | ran tests/run.sh merge-sorted resolve (75: 7/7 15s, 76: 17/17 30s, 77: 14/14 100s), plus init full suite green 925; ran the merge-sorted driver by hand, read plan/config/docs greps | step holds: matching artifact present and its check passes | yes |
| N2-06 | 2 | ran tests/run.sh merge-sorted resolve (75: 7/7 15s, 76: 17/17 30s, 77: 14/14 100s), plus init full suite green 925; ran the merge-sorted driver by hand, read plan/config/docs greps | step holds: matching artifact present and its check passes | yes |
| N2-06 | 3 | ran tests/run.sh merge-sorted resolve (75: 7/7 15s, 76: 17/17 30s, 77: 14/14 100s), plus init full suite green 925; ran the merge-sorted driver by hand, read plan/config/docs greps | step holds: matching artifact present and its check passes | yes |
| N2-06 | 4 | ran tests/run.sh merge-sorted resolve (75: 7/7 15s, 76: 17/17 30s, 77: 14/14 100s), plus init full suite green 925; ran the merge-sorted driver by hand, read plan/config/docs greps | step holds: matching artifact present and its check passes | yes |
| N2-06 | 5 | ran tests/run.sh merge-sorted resolve (75: 7/7 15s, 76: 17/17 30s, 77: 14/14 100s), plus init full suite green 925; ran the merge-sorted driver by hand, read plan/config/docs greps | step holds: matching artifact present and its check passes | yes |
| N2-06 | 6 | ran tests/run.sh merge-sorted resolve (75: 7/7 15s, 76: 17/17 30s, 77: 14/14 100s), plus init full suite green 925; ran the merge-sorted driver by hand, read plan/config/docs greps | step holds: matching artifact present and its check passes | yes |

- *111656-verify-N2 · claude-sonnet-5-5*

### 2026-10-29 11:05 · N2-02 · passes

The suite was red after the last attempt: its new Gotchas line made the section 16 memlint lines (memlint counts the <!-- --> comment), failing 39-memlint-m4. Dropped the 'git worktree add copies config.worktree' line (slot_open sets the driver itself). Re-verified every step: driver cases, .gitattributes, merge_drivers call sites, bash -n; suite green 925.

- **Files:** CLAUDE.md
- **Verified:** merge-sorted.sh on the fixture pair: exit 0, four lines; removal/both-add exit 0; unsorted clean 0, conflict 1 with one <<<<<<< in A; merge_drivers at lib/driver.sh:393 and lib/record.sh:682; node lib/memlint.mjs . prints nothing; check.sh green in 667 s, 925 tests
- **Tests:** 925 → 925
- **Discovery** (affects run): memlint counts the Gotchas section's <!-- At most 15 lines --> comment as a line: the section holds 14 facts, and a 15th turns 39-memlint-m4 red
- **Resolved:** git worktree add copies the current worktree's config.worktree into the new one: slots inherit the record's driver (dropped from Gotchas: memlint's 15-line cap)
- **Proposed change:** Either memlint's gotchas count should skip the section's HTML comment, or the comment should say 14 facts: the session prompt says '15 lines at most' and a session following it turns the suite red
- *02-N2-02 · claude-opus-5-5*

### 2026-10-29 10:22 · N2-02 · passes

Step 2 reworded by Michael (10:21) to match the git merge-file fallback. Re-verified every step: driver on the fixture pair (exit 0, four lines), removal, both-add, unsorted clean 0 / conflict 1 with markers; .gitattributes; merge_drivers in record worktree and slot_open; 75-merge-sorted 7/7; decision; bash -n; suite green 925. No code change.

- **Files:** CLAUDE.md
- **Verified:** lib/merge-sorted.sh run by hand on all step 1-2 cases; bash tests/run.sh 75-merge: 7/7; check.sh: green, 925 tests (cached for this tree); bash -n on the five files: clean
- **Tests:** 925 → 925
- **Resolved:** N2-02 step 2: reword its last clause to 'a side that fails `LC_ALL=C sort -c` gets git's text merge (`git merge-file`): clean exits 0, a conflict exits 1 with its `<<<<<<<` markers in A'? (recommended; the exact jq command is in INBOX.md) Files: /home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-10-29/slot-1/.harness/runs/agent-harness-2026-10-29/INBOX.md, /home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-10-29/slot-1/lib/merge-sorted.sh:11
- *01-N2-02 · claude-opus-5-5*

### 2026-10-29 08:48 · N2-02 · parked

Parked: step 2's 'exit 1 with A untouched' contradicts its own '(git reports the conflict as usual)'. git 2.43 keeps A as the result whatever the driver's exit, so an untouched A is a conflict with no markers and theirs' lines are lost. The code (N2-06's git merge-file fallback) does what the spec intends. INBOX asks Michael to reword the step. No code change.

- **Files:** .harness/runs/agent-harness-2026-10-29/INBOX.md
- **Verified:** throwaway repo, base `a b`, ours `b a`, theirs `b a c`: a driver that exits 1 without writing gives a CONFLICT with f = `b a` and 0 `<<<<<<<` lines (merge-tree stage result is the same); with lib/merge-sorted.sh, f has markers around `c`; check.sh 75: 7/7; init suite green, 925
- **Tests:** 925 → 925
- **Dead end:** a way for A to stay untouched and git still to write its usual markers — an external merge driver's %A is the file's result whatever its exit code; git has no fallback to its own text merge
- **Discovery** (affects project): git keeps a merge driver's %A as the file whatever its exit: a driver that exits 1 must write the markers itself (git merge-file)
- **Question for Michael:** N2-02 step 2: reword its last clause to 'a side that fails `LC_ALL=C sort -c` gets git's text merge (`git merge-file`): clean exits 0, a conflict exits 1 with its `<<<<<<<` markers in A'? (recommended; the exact jq command is in INBOX.md) Files: /home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-10-29/slot-1/.harness/runs/agent-harness-2026-10-29/INBOX.md, /home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-10-29/slot-1/lib/merge-sorted.sh:11
- **Proposed change:** N2-02 step 2: replace 'makes it exit 1 with A untouched (git reports the conflict as usual)' with 'gets git's text merge (`git merge-file`): clean exits 0, a conflict exits 1 with its `<<<<<<<` markers in A'
- **Proposed change:** the plan's check name 'merge-sorted: a side not in LC_ALL=C order exits 1 and leaves A untouched' (docs/plans/2026-10-29-N2-conflict-resolution.md:479) is stale for the same reason
- *13-N2-02 · claude-opus-5-5*

### 2026-10-29 08:46 · verify N2 · not yet

N2-02 step 2 fails: an unsorted side now gets git merge-file markers in A (exit 1), not A untouched as the step says (deliberate N2-06 change; the step or code needs aligning). Other features hold; suite green (925). Only spot-checked 03-06 steps via files and suite.

| Feature | Step | What you ran or read | What you saw | Holds |
|---|---|---|---|---|
| N2-01 | 1 | docs/plans/2026-10-29-N2-conflict-resolution.md exists with the sections `## Layer 1: merge-sorted.sh`, `## La | Checked via headings/greps of the committed files, the init suite (green, 925 tests) and the named checks in tests/checks/7[5-7]* | yes |
| N2-01 | 2 | `## Call sites` quotes each line of lib/record.sh and lib/lane.sh to change: sync_main's `git merge --abort` ( | Checked via headings/greps of the committed files, the init suite (green, 925 tests) and the named checks in tests/checks/7[5-7]* | yes |
| N2-01 | 3 | `## Layer 2: resolve.sh` gives `resolve <who> <what>`'s return codes (0 resolved and committed · 1 unresolved, | Checked via headings/greps of the committed files, the init suite (green, 925 tests) and the named checks in tests/checks/7[5-7]* | yes |
| N2-01 | 4 | `## Stubs and fixtures` names the stub flag that makes lanes M1 (A) and M2 (C) both rewrite line 2 of README.m | Checked via headings/greps of the committed files, the init suite (green, 925 tests) and the named checks in tests/checks/7[5-7]* | yes |
| N2-01 | 5 | `## Checks` lists every new check name with its file: tests/checks/75-merge-sorted.sh; tests/checks/76-resolve | Checked via headings/greps of the committed files, the init suite (green, 925 tests) and the named checks in tests/checks/7[5-7]* | yes |
| N2-01 | 6 | no file outside docs/plans/ changed: `git diff --stat origin/main...HEAD -- . ':!.harness/runs' ':!docs/plans' | diff --stat vs origin/main now lists code files because N2-02..06 are on the branch; the plan-only commits touched only docs/plans | yes |
| N2-01 | 7 | the suite is green: `bash tests/run.sh` ends with every check passing | init: check green in 663 s, 925 tests | yes |
| N2-02 | 1 | `bash lib/merge-sorted.sh <O> <A> <B>` on the pair tests/fixtures/git-conflict/names.conflicted.txt stands for | ran the pair by hand: exit 0, A = a check, b lane check, b main check, c check | yes |
| N2-02 | 2 | a base line one side removed stays removed; a line both sides added is one line; a side that fails `LC_ALL=C s | Ran merge-sorted.sh with O=a,b A=b,a B=a,b,c: exit 1 but A was rewritten with git merge-file conflict markers (cmp differs); removal and both-add cases hold. Step says A untouched; N2-06 review fix changed it deliberately. | no |
| N2-02 | 3 | `.gitattributes` at the repo root holds `tests/fixtures/check-names.txt merge=sorted-union`; the harness runs | Checked via headings/greps of the committed files, the init suite (green, 925 tests) and the named checks in tests/checks/7[5-7]* | yes |
| N2-02 | 4 | tests/checks/75-merge-sorted.sh (new): the driver checks above; a throwaway repo with the attribute and the wo | Checked via headings/greps of the committed files, the init suite (green, 925 tests) and the named checks in tests/checks/7[5-7]* | yes |
| N2-02 | 5 | journal/decisions/2026-10-29-conflict-resolution.md started: finding · choice (layer 1) · rejected (a union dr | Checked via headings/greps of the committed files, the init suite (green, 925 tests) and the named checks in tests/checks/7[5-7]* | yes |
| N2-02 | 6 | every new check name is in tests/fixtures/check-names.txt; `bash -n lib/merge-sorted.sh lib/record.sh lib/driv | Checked via headings/greps of the committed files, the init suite (green, 925 tests) and the named checks in tests/checks/7[5-7]* | yes |
| N2-02 | 7 | the suite is green: `bash tests/run.sh` ends with every check passing | init: check green in 663 s, 925 tests | yes |
| N2-03 | 1 | lib/config.sh: `CONFLICTS=resolve RESOLVE_MODEL=opus RESOLVE_MAX_TURNS=60 RESOLVE_BUDGET_USD=5 RESOLVE_TIMEOUT | Checked via headings/greps of the committed files, the init suite (green, 925 tests) and the named checks in tests/checks/7[5-7]* | yes |
| N2-03 | 2 | prompts/resolve.md, first line `# Resolve session`, static text first (decisions/2026-10-21-static-first-promp | Checked via headings/greps of the committed files, the init suite (green, 925 tests) and the named checks in tests/checks/7[5-7]* | yes |
| N2-03 | 3 | lib/resolve.sh (sourced by lib/lane.sh): `resolve <who> <what>` lists `git diff --name-only --diff-filter=U` ( | Checked via headings/greps of the committed files, the init suite (green, 925 tests) and the named checks in tests/checks/7[5-7]* | yes |
| N2-03 | 4 | tests/stub-claude.sh: `# Resolve session` under STUB_MERGE_RESOLVE=both keeps both sides' lines of every confl | Checked via headings/greps of the committed files, the init suite (green, 925 tests) and the named checks in tests/checks/7[5-7]* | yes |
| N2-03 | 5 | lib/record.sh merge_one: a conflicting `merge-tree` outside HARNESS_MERGE_ONLY returns 3 with `$STATE/moved-<m | Checked via headings/greps of the committed files, the init suite (green, 925 tests) and the named checks in tests/checks/7[5-7]* | yes |
| N2-03 | 6 | tests/checks/76-resolve-session.sh (new), on 48-lanes-rebase.sh's two_lanes pattern with the plan's flag makin | Checked via headings/greps of the committed files, the init suite (green, 925 tests) and the named checks in tests/checks/7[5-7]* | yes |
| N2-03 | 7 | the same run with `CONFLICTS=michael` in $T/user-config.sh → `M2 conflicts with main; not merged (needs Michae | Checked via headings/greps of the committed files, the init suite (green, 925 tests) and the named checks in tests/checks/7[5-7]* | yes |
| N2-03 | 8 | journal/decisions/2026-10-29-conflict-resolution.md gains layer 2's choice and rejected (Michael for every con | Checked via headings/greps of the committed files, the init suite (green, 925 tests) and the named checks in tests/checks/7[5-7]* | yes |
| N2-03 | 9 | every new check name is in tests/fixtures/check-names.txt; `bash -n lib/resolve.sh lib/lane.sh lib/record.sh l | Checked via headings/greps of the committed files, the init suite (green, 925 tests) and the named checks in tests/checks/7[5-7]* | yes |
| N2-03 | 10 | the suite is green: `bash tests/run.sh` ends with every check passing | init: check green in 663 s, 925 tests | yes |
| N2-04 | 1 | tests/stub-claude.sh: STUB_MERGE_RESOLVE=markers leaves one `<<<<<<<` line in README.md and ends `RESOLVED: RE | Checked via headings/greps of the committed files, the init suite (green, 925 tests) and the named checks in tests/checks/7[5-7]* | yes |
| N2-04 | 2 | resolve's failure paths: a marker left or `UNRESOLVED:` → `git merge --abort`, return 1, today's path at that | Checked via headings/greps of the committed files, the init suite (green, 925 tests) and the named checks in tests/checks/7[5-7]* | yes |
| N2-04 | 3 | a refused session (`MET limit`) → `git merge --abort`, `limit_raise` to its reset, return 2, no needs record a | Checked via headings/greps of the committed files, the init suite (green, 925 tests) and the named checks in tests/checks/7[5-7]* | yes |
| N2-04 | 4 | bounds: a `$STATE/resolve-<m>-<sha>` marker for this origin/main commit → today's path; `$STATE/resolves-<m>` | Checked via headings/greps of the committed files, the init suite (green, 925 tests) and the named checks in tests/checks/7[5-7]* | yes |
| N2-04 | 5 | lib/record.sh sync_main: in a lane under CONFLICTS=resolve the conflict goes to `resolve` and, resolved, the v | Checked via headings/greps of the committed files, the init suite (green, 925 tests) and the named checks in tests/checks/7[5-7]* | yes |
| N2-04 | 6 | tests/checks/77-resolve-fallbacks.sh (new), two-lane stub runs on N2-03's pattern: markers and give-up → no ME | Checked via headings/greps of the committed files, the init suite (green, 925 tests) and the named checks in tests/checks/7[5-7]* | yes |
| N2-04 | 7 | every new check name is in tests/fixtures/check-names.txt; `bash -n lib/resolve.sh lib/lane.sh lib/record.sh t | Checked via headings/greps of the committed files, the init suite (green, 925 tests) and the named checks in tests/checks/7[5-7]* | yes |
| N2-04 | 8 | the suite is green: `bash tests/run.sh` ends with every check passing | init: check green in 663 s, 925 tests | yes |
| N2-05 | 1 | after a resolved merge the note reads `<m>: main merged in by a resolve session (<files>; <model>, <n> min); o | Checked via headings/greps of the committed files, the init suite (green, 925 tests) and the named checks in tests/checks/7[5-7]* | yes |
| N2-05 | 2 | lib/summary.mjs build: `conflicts: {resolved: <n>, escalated: <n>, sessions: <n>}` (resolved and escalated fro | Checked via headings/greps of the committed files, the init suite (green, 925 tests) and the named checks in tests/checks/7[5-7]* | yes |
| N2-05 | 3 | lib/record.sh pr_body adds the paragraph `Merged main in with a resolve session: <files>` for a milestone whos | Checked via headings/greps of the committed files, the init suite (green, 925 tests) and the named checks in tests/checks/7[5-7]* | yes |
| N2-05 | 4 | in tests/checks/76-resolve-session.sh and 77-resolve-fallbacks.sh: the `both` run's summary.json has `.conflic | Checked via headings/greps of the committed files, the init suite (green, 925 tests) and the named checks in tests/checks/7[5-7]* | yes |
| N2-05 | 5 | every new check name is in tests/fixtures/check-names.txt; `node --check lib/summary.mjs` and `bash -n lib/rec | Checked via headings/greps of the committed files, the init suite (green, 925 tests) and the named checks in tests/checks/7[5-7]* | yes |
| N2-05 | 6 | the suite is green: `bash tests/run.sh` ends with every check passing | init: check green in 663 s, 925 tests | yes |
| N2-06 | 1 | `git diff origin/main...HEAD -- . ':!.harness/runs' > /tmp/harness/agent-harness/agent-harness-2026-10-29/revi | Checked via headings/greps of the committed files, the init suite (green, 925 tests) and the named checks in tests/checks/7[5-7]* | yes |
| N2-06 | 2 | simplification passes applied where the review found them (sync_main and rebase share one conflict path into ` | Checked via headings/greps of the committed files, the init suite (green, 925 tests) and the named checks in tests/checks/7[5-7]* | yes |
| N2-06 | 3 | docs/architecture.md: §3 rows for `lib/resolve.sh`, `lib/merge-sorted.sh` and `prompts/resolve.md`; §5 the con | Checked via headings/greps of the committed files, the init suite (green, 925 tests) and the named checks in tests/checks/7[5-7]* | yes |
| N2-06 | 4 | README.md: `CONFLICTS` and the `RESOLVE_*` settings in the box settings (and `CONFLICTS=michael` for a project | Checked via headings/greps of the committed files, the init suite (green, 925 tests) and the named checks in tests/checks/7[5-7]* | yes |
| N2-06 | 5 | journal/decisions/2026-10-29-conflict-resolution.md complete: finding · choice · rejected (Michael for every c | Checked via headings/greps of the committed files, the init suite (green, 925 tests) and the named checks in tests/checks/7[5-7]* | yes |
| N2-06 | 6 | the suite is green: `bash tests/run.sh` ends with every check passing | init: check green in 663 s, 925 tests | yes |

- *084530-verify-N2 · claude-sonnet-5-5*

### 2026-10-29 08:34 · N2-06 · passes

N2 review + simplify + docs. merge-sorted.sh: an unsorted side now gets git merge-file (markers kept; git keeps %A whatever the exit). sync_main and rebase share merge_main (lib/record.sh). report's Spend by role names resolve. architecture.md §3-§12, README, decision completed. 0 Critical, 1 Important, 7 Minor

- **Files:** lib/merge-sorted.sh, lib/record.sh, lib/lane.sh, lib/summary.mjs, tests/checks/75-merge-sorted.sh, tests/checks/76-resolve-session.sh, tests/fixtures/check-names.txt, docs/architecture.md, README.md, journal/decisions/2026-10-29-conflict-resolution.md
- **Verified:** Opus review of /tmp/harness/agent-harness/agent-harness-2026-10-29/review-N2.diff (one round, no Critical). Each fix's check failed first (75 unsorted fallback, 76 Spend by role). tests/run.sh merge-sorted resolve lanes-rebase needs-cards: 77/77 after the merge_main refactor; full check.sh green
- **Tests:** 924 → 925
- **Discovery** (affects run): open Minor review findings: resolved-<m> is written with > (sync_main's then rebase's resolution keeps only the last files in the PR body; the plan said >>); slot_open's reset after a killed resolve still commits the session's untracked files as WIP; resolve ignores S_EXIT (a timed-out session that git-added clean files is committed, the verify still gates it); a rebase refused by resolve's mem_gate (lanes-end/stop, no RESOLVE_END) exits the lane 0 'its re-base waits' not 16/14; rebase's main_clear runs before the re-base's outcome; 77's slot_open check's `! -e resolve-called` half can't fail
- **Discovery** (affects run): merge_main <m> <resolve|""> (lib/record.sh) is the one conflict path into resolve: 0 merged (MERGE_RESOLVED when a session settled it), 1 aborted (MERGE_FILES, RESOLVE_TRIED), 2 refused
- **Proposed change:** N2-06 step 2's STUB_MERGE_RESOLVE modes were already one case arm; the reviewer suggests dropping the `markers` end-to-end run in 77 (the rv unit covers it) to save a two-lane stub run
- *12-N2-06 · claude-opus-5-5*

### 2026-10-29 08:13 · N2-05 · passes

Resolutions are visible, never asked about: resolved_note (lib/resolve.sh) from rebase and sync_main; summary.mjs conflicts {resolved, escalated, sessions} plus resolutions [{milestone, files}] and report's Conflicts row after Flakes; pr_body's `Merged main in with a resolve session: <files>` from resolved-<m>. 6 new checks in 76/77; decision updated.

- **Files:** lib/resolve.sh, lib/lane.sh, lib/record.sh, lib/summary.mjs, tests/checks/76-resolve-session.sh, tests/checks/77-resolve-fallbacks.sh, tests/fixtures/check-names.txt, journal/decisions/2026-10-29-conflict-resolution.md
- **Verified:** bash tests/run.sh resolve-session: 16/16 (29 s); resolve-fallbacks: 14/14 (99 s); unit check of conflicts()/resolutions()/report row run alone before (no export: red) and after (green); full suite via check.sh: green in 665 s, 924 tests
- **Tests:** 918 → 924
- **Discovery** (affects N2-06): summary.json's conflicts is exactly {resolved, escalated, sessions} (the step's jq ==), so the report row's files live in a sibling key `resolutions: [{milestone, files}]`; docs (§ state/summary) should name both
- **Discovery** (affects N2-06): RESOLVE_FILES is now comma-joined ("a, b"), as the conflict note had it; rebase's `resolved by a session (...)` how text uses it too
- **Discovery** (affects N2-06): the resolution note and the PR paragraph say $MAIN_BRANCH, not a literal `main`; summary.mjs matches any branch word (`\S+ merged in by a resolve session`)
- **Proposed change:** N2-05 step 2: name the `resolutions` key beside `conflicts` (step 4's exact `.conflicts ==` leaves no room for the files the row needs)
- *11-N2-05 · claude-opus-5-5*

### 2026-10-29 07:46 · N2-04 · passes

Layer 2 fallbacks: stub STUB_MERGE_RESOLVE markers/stray/give-up, STUB_RESOLVE_LIMIT, STUB_MAIN_TOUCH=resolve-<m>; sync_main resolves in a lane (verify defers on a refusal, skips sync_main in rebase mode); needs cards' tried; rebase records conflict-<m>; 77-resolve-fallbacks (12). Opus review: 0 Critical, 2 Important, 1 Minor, all fixed.

- **Files:** lib/record.sh, lib/lane.sh, lib/resolve.sh, lib/needs.mjs, bin/harness, tests/stub-claude.sh, tests/checks/77-resolve-fallbacks.sh, tests/checks/59-needs-cards.sh, tests/fixtures/check-names.txt, journal/decisions/2026-10-29-conflict-resolution.md
- **Verified:** check.sh: green in 660 s, 918 tests; 77-resolve-fallbacks 12/12 in 107.7 s; 76/75/61/48/59 green; 77 against the old record.sh+lane.sh failed 6/11, the rsg check failed before the merge_one guard (2 needs-you posts, a second merge lane)
- **Tests:** 905 → 918
- **Dead end:** asserting `lane M2 closed (M2 verified; its re-base waits)` in the refused run — a lane whose re-base waits closes with no such note; the check counts two `lane M2 opened` lines instead
- **Dead end:** inspecting the slot after a stub run for MERGE_HEAD — finish removes the slots; the e2e checks compare origin's lane branch with the tag, and a unit on resolve alone checks MERGE_HEAD and HEAD
- **Discovery** (affects N2-05, N2-06): resolve's tried is stored in the resolve-<m>-<main> marker, so a later record for the same main (resolve_ok: already ran) keeps tried; MAX_RESOLVES sets tried to `its <n> resolve session(s) used`
- **Discovery** (affects N2-05, N2-06): rebase writes conflict-<m> before rebase_fail: without it the run's-end merge_one re-opened merge_conflict, dropping tried and the rebase variant, and notified twice
- **Discovery** (affects N2-06): merge_one's resolve branch returns 1 when main-conflict-<m> is this main (the lane's sync_main already tried it); rebase calls main_clear once its merge went through
- **Discovery** (affects N2-05): stub resolve sessions report 0 min (S_WALL 0): a check on tried's minutes matches [0-9]+
- **Discovery** (affects N2-05, N2-06): a unit calling resolve() needs USAGE and REC set (weekly gate, metrics row) or it dies under set -u mid-function
- **Proposed change:** N2-04 step 3's `in sync_main the verify goes on without main (nomerge-<m>)` was built as the plan says instead: verify returns 2 before its session and the lane loop waits, then verifies again (a hold with nomerge-<m> would end the lane needs Michael with no record); recorded in the decision file
- **Proposed change:** N2-06's docs should name the main-conflict-<m> guard in merge_one and rebase's conflict-<m>/main_clear (§5, §7)
- *10-N2-04 · claude-opus-5-5*

### 2026-10-29 07:04 · N2-03 · passes

Layer 2 happy path: lib/resolve.sh (resolve_ok, resolve: snapshot, session on RESOLVE_*, journal, metrics row, checks, NUL-safe restore, commit), prompts/resolve.md, CONFLICTS/RESOLVE_*/MAX_RESOLVES, stub # Resolve session (both) and STUB_CONFLICT; merge_one returns 3 in a lane, rebase resolves then verifies; 76-resolve-session (12 checks). Opus review: 1 Critical, 3 Important, 7 Minor, all fixed.

- **Files:** lib/resolve.sh, prompts/resolve.md, lib/lane.sh, lib/record.sh, lib/config.sh, lib/entries.mjs, templates/user/config.sh, tests/stub-claude.sh, tests/checks/76-resolve-session.sh, tests/checks/61-needs-git.sh, tests/fixtures/check-names.txt, journal/decisions/2026-10-29-conflict-resolution.md
- **Verified:** 76-resolve-session 12/12 (27.8 s): rs run notes `M2: 1 files conflict with main (README.md); a resolve session`, one resolve + two verify M2 lines, M2 merged, main tree == run/rs/M2, no needs, 1 metrics row kind resolve, prompt names README.md + A/C subjects; michael run and harness merge keep merge_conflict. ended and slot_open checks watched red without their fix. Full suite via check.sh green on the final tree.
- **Tests:** 893 → 905
- **Dead end:** a stray-path restore over `git ls-files -s | awk` lines and `awk -v p=path` membership — the Opus review showed it deletes tracked paths with a blank, writes junk for quoted non-ASCII paths and writes through symlinks; replaced by -z snapshots in associative arrays and checkout-index
- **Discovery** (affects N2-04): resolve.sh already holds N2-04's failure code (resolve_ok bounds, MAX_RESOLVES note, refused deferral with RESOLVE_END, marker/UNRESOLVED/unmerged checks, stray restore, resolve_undo); N2-04 needs its stub modes and checks, the sync_main call site, the verify caller's rc 2 and needs.mjs `tried` (rebase already passes tried= only when set)
- **Discovery** (affects N2-04): the stray restore is covered by a unit check in 76 (resolve with a function session: a blank, café.txt, a symlink, a created and an added file); N2-04's stub `stray` run is the end-to-end one
- **Discovery** (affects N2-04, N2-06): merge_one keeps today's merge_conflict at the run's end ($STATE/ended, written by finish before merge_milestones and cleared at each segment start): no lane could re-base then
- **Discovery** (affects N2-06): slot_open now undoes a MERGE_HEAD left in a reused slot (a lane killed mid-resolve) with a note `<m>: its slot-<k> had a merge left in progress; undone`, before the WIP commit
- **Discovery** (affects N2-04): the marker check counts marker-like lines (diff3's ||||||| too) above what either side (:2:/:3:) already had, so a setext ======= underline isn't a false marker
- **Discovery** (affects N2-05): resolved-<m> is overwritten (>) on each successful resolve, not appended, so N2-05's PR body lists the last resolution's files once
- **Discovery** (affects N2-04): verify's `sync_main` still runs in rebase mode (the plan's skip is N2-04's); harmless in 76's runs
- **Proposed change:** N2-06's simplification list could add: resolve.sh's early `git merge --abort` exits (before the snapshot) and resolve_undo are two undo forms; one would do once sync_main calls resolve
- *09-N2-03 · claude-opus-5-5*

### 2026-10-29 06:07 · N2-02 · passes

Layer 1: lib/merge-sorted.sh (three-way sorted union; an unsorted side exits 1, A untouched), .gitattributes opts check-names.txt in, merge_drivers (lib/record.sh) sets the driver as worktree config in the record worktree each segment and in slot_open; STUB_SORTED; 75-merge-sorted.sh (7 checks, ~14 s); decision started.

- **Files:** lib/merge-sorted.sh, lib/record.sh, lib/driver.sh, .gitattributes, tests/stub-claude.sh, tests/checks/75-merge-sorted.sh, tests/fixtures/check-names.txt, journal/decisions/2026-10-29-conflict-resolution.md, CLAUDE.md
- **Verified:** 75-merge-sorted: 5/7 before the wiring (slot-config and two-lane checks red), 7/7 after; the two-lane run notes `M2 re-based on main …: overlapping (names.txt); one verify round` and main's names.txt is the four-line union; full suite via check.sh green in 624 s, 893 tests (a first full run was red only on memlint: Gotchas at 16 lines, fixed); bash -n on the touched shell files
- **Tests:** 886 → 893
- **Discovery** (affects N2-03, N2-04, N2-06): merge_drivers is called right after the driver's first sync_record (lib/driver.sh), before the resumed start's sync_main; slot_open calls it in place of its extensions.worktreeConfig line
- **Discovery** (affects N2-04, N2-06): STUB_SORTED=<file> in tests/stub-claude.sh: A adds `b A check`, C `b C check`, re-sorted, in their first coding session
- **Resolved:** the driver moves <state>/brief.md into the record's brief.md and empties it at start: a run's briefs are both files (agent-harness-2026-10-28 2026-10-28)
- *08-N2-02 · claude-opus-5-5*

### 2026-10-29 05:40 · N2-01 · passes

Wrote docs/plans/2026-10-29-N2-conflict-resolution.md: merge-sorted.sh + merge_drivers, resolve/resolve_ok in lib/resolve.sh (rc 0/1/2, RESOLVE_END, snapshot, checks, bounds), exact changes in sync_main, verify, rebase, merge_one(+--open) and slot_open (stays), the gate, stub flags and modes, tried, visible, checks by file. Opus review: 0 Critical, 7 Important, 5 Minor, all folded in.

- **Files:** docs/plans/2026-10-29-N2-conflict-resolution.md
- **Verified:** 8 required sections grep -x'd; every quoted line grep -F'd in lib/record.sh and lib/lane.sh; diff outside docs/plans empty; check.sh green (886, cached: docs/plans is a key ignore); merge-tree with a worktree-config driver tried in a throwaway repo
- **Tests:** 886 → 886
- **Discovery** (affects N2-02, N2-03): git 2.43 merge-tree --write-tree runs a configured merge driver (attributes from the checkout's .gitattributes), so layer 1 also settles merge_one's merge-tree
- **Discovery** (affects N2-02, project): git worktree add copies the current worktree's config.worktree into the new one: slots added from the record worktree inherit its --worktree driver; Michael's checkout never sees it
- **Discovery** (affects N2-03): 61-needs-git.sh's mc and mr runs hit sync_main/merge_one conflicts: with CONFLICTS=resolve as default they need CONFLICTS=michael in user-config to keep testing today's path
- **Discovery** (affects N2-04): a needs card key that is always present (even null) changes 52-status-json.sh's key-path fixture: add tried only when set
- **Discovery** (affects N2-04): verify runs sync_main in rebase mode too (lane.sh:62); the plan skips it there so a re-base round never resolves twice
- **Proposed change:** N2-04 step 3: in sync_main a refused resolve should defer the whole verify (verify returns 2, the lane loop waits for the window and verifies again), not 'the verify goes on without main (nomerge-<m>)': with nomerge-<m> a hold ends the lane with exit 12 'needs Michael' and no needs record, and its session runs inside the refused window (plan § Call sites/sync_main)
- **Proposed change:** N2-04 step 6: the stray mode also git-adds a new file (stray-added.txt), so the check covers a new stage-0 path; the restoring note names three paths
- **Proposed change:** N2-04: verify in rebase mode no longer calls sync_main (plan § Call sites), worth a step of its own
- *07-N2-01 · claude-opus-5-5*

### 2026-10-29 05:20 · verify N1 · passes

All five N1 features hold: subset 39/39 re-run, syntax checks, plan/docs/decision read, full suite green (886 tests) at init.

| Feature | Step | What you ran or read | What you saw | Holds |
|---|---|---|---|---|
| N1-01 | 1 | grep ^## plan; sections | all six sections present | yes |
| N1-01 | 2 | read plan ## check.sh | names rerun point, 4 CHECK_RERUN values, 124/137 exits, subset never reruns | yes |
| N1-01 | 3 | read plan ## Checks | checks listed by 73/33/74 files | yes |
| N1-01 | 4 | read plan ## Checks stub suite | counter-file stub with HARNESS_FAILED and N/M lines described | yes |
| N1-01 | 5 | git diff --stat f0cbdc1~1 f0cbdc1 outside docs/plans | empty | yes |
| N1-01 | 6 | suite via init | green 886 tests | yes |
| N1-02 | 1 | bash tests/run.sh suite-runner; read tests/run.sh:100 | PASS red prints HARNESS_FAILED, green none; echo guarded by ! outside | yes |
| N1-02 | 2 | tests/run.sh check-rerun | 14/14: green-after-rerun line, args a b, check.out/check-rerun.out, marker total, cached | yes |
| N1-02 | 3 | check-rerun: red every time | PASS exit 1, red again on a rerun of a, no marker/row | yes |
| N1-02 | 4 | check-rerun: no-line/failed/off/suite | PASS all variants | yes |
| N1-02 | 5 | check-rerun: timeout and subset | PASS one call each | yes |
| N1-02 | 6 | check-rerun flakes row keys | PASS row keys and jq | yes |
| N1-02 | 7 | grep config.sh prompt.sh lane.sh template | CHECK_RERUN=auto, HARNESS_CHECK_RERUN export, HARNESS_LANE, template present; PASS | yes |
| N1-02 | 8 | read decision file | rerun-guard decision exists with updates | yes |
| N1-02 | 9 | bash -n; check-names | syntax ok; conformance in full suite green | yes |
| N1-02 | 10 | init suite | green | yes |
| N1-03 | 1 | grep flakes_note; 74 | record.sh defines it; lane.sh 3 sites, driver.sh finish; 74 PASS | yes |
| N1-03 | 2 | 74 flaky run | PASS flaky: whole suite note, A stays passed | yes |
| N1-03 | 3 | 74 invariant run | PASS C un-passed, no flaky line | yes |
| N1-03 | 4 | 74 flakes-noted | PASS offset equals size; no-flake run writes none | yes |
| N1-03 | 5 | bash -n | ok | yes |
| N1-03 | 6 | init suite | green | yes |
| N1-04 | 1 | 74 summary check | PASS flakes counts, fixture keys subset | yes |
| N1-04 | 2 | 74 report check | PASS Flakes row after Tests | yes |
| N1-04 | 3 | 74 run checks | PASS flakes run summary/report | yes |
| N1-04 | 4 | 74 debrief check | PASS x2 listed, single absent | yes |
| N1-04 | 5 | node --check; bash -n | ok | yes |
| N1-04 | 6 | init suite | green | yes |
| N1-05 | 1 | review diff file; entries.jsonl:7 | diff exists; entry reports 0 Critical, 1 Important, 7 Minor | yes |
| N1-05 | 2 | tests/run.sh check-rerun suite-runner flakes | 39/39 pass | yes |
| N1-05 | 3 | grep architecture.md | §3 row, §4 flakes row, §7 Rerun guard, §10 CHECK_RERUN present | yes |
| N1-05 | 4 | grep README.md | CHECK_RERUN four values and HARNESS_FAILED promise present | yes |
| N1-05 | 5 | decision file | Updated in place lines for N1-03/04/05 | yes |
| N1-05 | 6 | init suite | green 886 | yes |

- *051705-verify-N1 · claude-sonnet-5-5*

### 2026-10-29 04:56 · N1-05 · passes

Opus review of N1: finish now notes a flake on its own last suite (RED→GREEN stub run fe); a non-object flakes.jsonl row is skipped by summary and flakes_note; check.sh shares one green branch and one rerun call; arch §3/§4/§7/§10, README, decision updated. Hung-file rerun kept as a default (question). 0 Critical, 1 Important, 7 Minor

- **Files:** lib/check.sh, lib/driver.sh, lib/record.sh, lib/summary.mjs, tests/checks/74-flakes-run.sh, tests/fixtures/check-names.txt, docs/architecture.md, README.md, journal/decisions/2026-10-29-rerun-guard.md
- **Verified:** 74-flakes-run: new check failed (row counted in summary.json, no flaky: note), 11/11 after; null-row checks failed then passed; check-rerun/suite-runner/flakes 38/38 after check.sh simplification; 08/10/34/70 161/161. Full suite: live check.sh 885/886 (45-lanes-run flaked, 10/10 alone); this branch's check.sh on the real suite: `check: green after a rerun (flaky: 08-scope-…), 886 tests`.
- **Tests:** 885 → 886
- **Dead end:** a Gotchas line on finish's uncached suite — the section was already at 15 lines; memlint (39-memlint-m4) fails at 16, so it was dropped
- **Discovery** (affects R1, run): 08-scope-sh-l1-02 flakes under the full suite's load (memory gate waits, the real 64M scope check), green alone: an R1 flaker beside 45-lanes-run
- **Discovery** (affects run): review findings left open (Minor): run_init tests-start falls back to a red check.out's passes when a flake's marker is empty (suites with no N/M line); testcount --total undercounts a file killed mid-way; the debrief prints the project-wide #### flakes block once per run, not once per project; a fractional CHECK_TIMEOUT (1.5h) makes why() miss a timeout's 137
- **Question for Michael:** The review (Important, triaged to a default): a check file tests/run.sh stops at TEST_FILE_TIMEOUT is named in HARNESS_FAILED=, so CHECK_RERUN=auto reruns it, at most one more TEST_FILE_TIMEOUT (10m). Keep that (default: a hang under load is the likeliest flake), or skip the rerun when a file timed out? Files: /home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-10-29/slot-0/tests/run.sh:54, /home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-10-29/slot-0/journal/decisions/2026-10-29-rerun-guard.md
- **Proposed change:** N1-05 step 3 says §7's Rerun guard row goes beside `Suite cache`, but Suite cache is a §4 row; §7 has `Suite scope`, and the row went beside that
- *06-N1-05 · claude-opus-5-5*

### 2026-10-29 04:02 · N1-04 · passes

summary.mjs: flakes {count, names} from <state>/green/flakes.jsonl (tolerant reader, whole suite for no names), a Flakes row after Tests in report.md and the TTY card (n · name ×k, 0, none for older summaries), flakers() + `summary.mjs flakers <ledger>/<project>` for the debrief's #### flakes block after report.md. 4 new checks in 74-flakes-run; docs and decision updated.

- **Files:** lib/summary.mjs, lib/debrief.sh, tests/checks/74-flakes-run.sh, tests/fixtures/check-names.txt, docs/architecture.md, README.md, journal/decisions/2026-10-29-rerun-guard.md
- **Verified:** 74-flakes-run 10/10 (4 new, watched failing first); full suite via check.sh: green in 622 s, 885 tests, no rerun; node --check lib/summary.mjs and bash -n lib/debrief.sh clean; 71-tty-views (summary-report.md fixture) unchanged and green
- **Tests:** 881 → 885
- **Dead end:** the unit check asserting build's keys minus the fixture's are exactly flakes — summary-report.json predates lanes and review: build has those too; the check asserts fixture keys ⊆ build keys and flakes new
- **Discovery** (affects N1-05): tests/fixtures/summary-report.json predates the lanes and review keys: build() produces keys it lacks, so compare it as a subset
- **Discovery** (affects N1-05): the debrief's flakes block reads $LEDGER/<basename of PROJECT_DIR>, as rec_dir does; the check runs debrief --dry-run with its own HARNESS_LEDGER so the stub runs' ledgered summaries don't count
- *05-N1-04 · claude-opus-5-5*

### 2026-10-29 03:45 · N1-03 · passes

Attempt 1's code (cfb23fc) verified: flakes_note in lib/record.sh, called after the un-pass check, verify, disjoint re-base and in finish before run ended; run_init's tests-start from the marker after a rerun. 74-flakes-run 6/6; full suite green on this tree at init (881 tests, 622 s, no rerun).

- **Files:** lib/record.sh, lib/lane.sh, lib/driver.sh, tests/checks/74-flakes-run.sh, tests/fixtures/check-names.txt, journal/decisions/2026-10-29-rerun-guard.md
- **Verified:** check.sh: green (cached for this code tree, 881 tests); check.sh flakes: 6/6; bash -n on record.sh lane.sh driver.sh clean; check-names.txt LC_ALL=C sorted with the 6 names
- **Tests:** 881 → 881
- **Proposed change:** N1-03 step 3 should read the invariant's rerun-red from the `red again on a rerun of the whole suite) — last lines of …/lanes/M2/check-rerun.out:` line in logs/04-C.prompt.md: the stub's C is in lane M2, and check.sh removes check-rerun.out at the next full suite, so `lanes/M1/check-rerun.out exists` can't hold
- *04-N1-03 · claude-opus-5-5*

## Older entries (in full in progress-archive.md)

- 2026-10-29 03:33 · N1-03 · not yet · flakes_note (lib/record.sh) notes each new green/flakes.jsonl row once (`flaky: <names|whole suite> … ([in full](progress-archive.md))
- 2026-10-29 02:15 · N1-02 · passes · check.sh's full form reruns a red once by CHECK_RERUN (auto/failed/suite/off): never after a timeout… ([in full](progress-archive.md))
- 2026-10-29 01:46 · N1-01 · passes · Wrote docs/plans/2026-10-29-N1-rerun-guard.md: the rerun's place and rules in lib/check.sh (CHECK_RE… ([in full](progress-archive.md))
- 2026-10-29 01:40 · init · passes · 11 features: N1 5 (plan, 3 build, review), N2 6 (plan, 4 build, review); in series, N2 after N1 as t… ([in full](progress-archive.md))
