# Context pack for `R4`

Chosen by the harness from entries.jsonl in a fixed order; each item names its line. The full record is entries.jsonl / progress-archive.md.

## This feature's earlier attempts

- Dead end (R4-04, 21-R4-04): grep -x "NEEDS YOU 1 · 1 question (─)*" — BRE takes the parens literally: grep -Ex with (─)+ → entries.jsonl:37
- Question (R4-05): Default taken: the harness-answer skill passes an answer to a question that names no decision file on with `harness answer <run>` (no continue), so the run's next sessions read it under ## Answers. Should `harness needs done --why` on a question do that itself instead, so a hand-run done reaches the sessions too? Files: /home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-10-29-2/slot-0/skills/harness-answer/SKILL.md:46, /home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-10-29-2/slot-0/docs/plans/2026-10-29-R4-review.md → entries.jsonl:39
- Question (R4-02): The question key is the first 80 characters (R4-02 step 1). The review found two different questions with a shared preamble get one key: the memory run's M1-01 "Defaults taken in the plan (to be recorded in journal/decisions/2026-10-26-retro-backlog.md by M1-04): …" questions collide, so the second refreshes over the first and one resolved closes both. Default kept: 80 characters as specified. Should the key be a hash of the whole folded text instead (the move forward still works; a reworded question is then a new item)? Files: /home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-10-29-2/slot-0/lib/needs.mjs:62, /home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-10-29-2/slot-0/docs/plans/2026-10-29-R4-questions.md → entries.jsonl:26
- 2026-10-29 21:09 · resolve R4 · passes: CLAUDE.md Gotchas: main (R3-01) replaced the stub --resume line with the {{X}}-above-{{SECTIONS}} line to keep the section within 15 lines; the lane (R4-04) edited the glyph-regex line in place (grep -E "(─)+", BRE parens literal). Kept main's swap and the lane's edited glyph line: 14 lines, no markers, memlint clean.; files CLAUDE.md → entries.jsonl:40
- 2026-10-29 21:09 · R4-05 · passes: R4 review: 0 Critical, 4 Important, 6 Minor (one Opus round). Fixed RED→GREEN: same-80-char twin questions (twinKey #n), skill passes an undecided-file answer via harness answer, immediate sweep now checked, debrief capped at 12 with a pre-R4 fallback (entries.mjs questions). Decision questions-wait, architecture §3/§4/§16/§17, README Questions.; tests 994 → 999; files lib/needs.mjs, lib/entries.mjs, lib/debrief.sh, lib/record.sh, skills/harness-answer/SKILL.md, … → entries.jsonl:39
- 2026-10-29 20:35 · R4-04 · passes: Readers count questions apart: harness needs (NEEDS YOU 1 · 1 question; question cards after stops), harness status (NEEDS YOU 1 · 3 questions · harness needs; run object needs + questions; card '3 questions: harness needs <run>'), debrief's #### Questions for Michael from needs --json. Skill gains ## Question items. Install: cp -r skills/harness-answer ~/.claude/skills/; tests 989 → 994; files lib/needs.mjs, lib/status.mjs, lib/debrief.sh, skills/harness-answer/SKILL.md, tests/checks/78-needs-questions.sh, … → entries.jsonl:37
- 2026-10-29 19:56 · R4-03 · passes: journal_ (lib/record.sh) now opens one question item per question of the entry it ingests (questions_: the filled text, asker, line, feature for coding), notes '<id>: <n> question(s) for Michael recorded (harness needs)' and sweeps at once when the entry has resolved. Stub learns STUB_ASK_TWO and STUB_ASK_AGAIN. 78 gains 5 stub-run checks.; tests 984 → 989; files lib/record.sh, tests/stub-claude.sh, tests/checks/78-needs-questions.sh, tests/fixtures/check-names.txt → entries.jsonl:30
- 2026-10-29 19:22 · R4-02 · passes: needs.mjs has the question reason: questionKey (fill and Files: lines cut, folded, 80 code points), open refreshes in the run (exit 3) or moves an open item forward from a sibling run (seen +1, asked_in, old in its done/), a warn card, the sweep resolves on a later entry's resolved (entries.mjs resolvedBy, shared with pack).; tests 976 → 984; files lib/needs.mjs, lib/entries.mjs, tests/checks/78-needs-questions.sh, tests/lib.sh, tests/checks/58-needs-record.sh, … → entries.jsonl:26
- 2026-10-29 18:52 · R4-01 · passes: Wrote docs/plans/2026-10-29-R4-questions.md: the question reason, a key that drops the harness's Files fill (worktree paths differ per run), refresh, the move forward through sibling state dirs, card and sweep rule (resolvedBy shared with pack), journal_'s questions_ after the ingest, readers, the skill step, 17 check names, needs_fixture question, STUB_ASK_TWO/AGAIN. No code changed.; tests 976 → 976; files docs/plans/2026-10-29-R4-questions.md → entries.jsonl:25

## Discoveries for this feature

- Discovery (R4-05, affects run): a question item's key may end #<n> (twinKey, lib/needs.mjs): another question of the same entry with the same first 80 characters → entries.jsonl:39
- Discovery (R4-05, affects run): 47-lanes-two flaked once in this session's full run (green on check.sh's rerun) → entries.jsonl:39
- Discovery (R4-04, affects R4-05): status --json run objects gain `questions` (tests/fixtures/status-json-keys.txt has finished[]/running[].questions); `needs` is now the non-question count; doc.needs keeps every item → entries.jsonl:37
- Discovery (R4-04, affects R4-05): 78's debrief check runs `harness debrief --dry-run` over all four stub runs (no runner.log: the last 24 h) and reads each run's #### Questions for Michael block; qr's says `none open` → entries.jsonl:37
- Discovery (R4-04, affects R4-05): R4-05 still owns architecture §4/§17 and README's steering section; this session only touched the status.mjs row, the harness needs view paragraph and the debrief line in README → entries.jsonl:37
- Discovery (R3-06, affects run): Since attempt 1 the R3 diff changed only by merging origin/main (one conflict, CLAUDE.md Gotchas; stub-claude.sh headers kept both): no new R3 code to review, so no second reviewer round → entries.jsonl:36
- Discovery (R3-01, affects run): A resolve that keeps both sides' Gotchas lines can push the section past 15 (the comment line counts): drop one in the resolve, or 39-memlint-m4 goes red → entries.jsonl:31
- Discovery (R4-03, affects R4-04, R4-05): 78's needs_fixture runs (q-*) are runs of proj: the stub runs rm them first, or a stub question of the same text (ASK_TWO's cache one is the fixture default) moves their item forward → entries.jsonl:30
- Discovery (R4-03, affects R4-04): 78 runs four stub runs (qa ASK_TWO, qr ASK+AGAIN+RESOLVE=A, qm1/qm2 ASK=A), ~70 s; R4-04's no-notification check can reuse qa's curl.log instead of a fifth run → entries.jsonl:30
- Discovery (R3-06, affects run): The suite must read nothing under CHECK_KEY_IGNORE paths (34's guard): a merge now skips its re-base on them; copy a spec's shape into tests/fixtures instead → entries.jsonl:27
- Discovery (R3-06, affects run): lib/treekey.mjs --pathspec prints the key's pathspecs; ignored_only (lib/record.sh) uses them and takes only output starting with '.' → entries.jsonl:27
- Discovery (R3-06, affects run): Promote item 'tests/lib.sh now holds tended, held…' still not on R3's branch (R1 not on origin main): left for a session with R1 in → entries.jsonl:27
- Discovery (R3-06, affects run): 40-run-18-test-counts-m5 'a continued run refreshes tests-end' flaked once in a full run (green on the rerun) → entries.jsonl:27
- Discovery (R4-02, affects R4-03, R4-04): needs_fixture question (tests/lib.sh) puts every fixture run under one project proj: an open of the same text in another run moves it forward; give each its own NF_Q=<text> → entries.jsonl:26
- Discovery (R4-02, affects R4-03): journal_ must pass the question as entries.jsonl stores it (filled): the sweep compares card.question.text with resolved items as pack does, and a pack-cut resolved copied from the filled words would not match the unfilled text → entries.jsonl:26
- Discovery (R4-02, affects R4-03): An open with no line= is never resolved by the sweep (no later to tell): journal_ must pass line=<entries.jsonl line> → entries.jsonl:26
- Discovery (R4-02, affects R4-04): A question item counts in harness status NEEDS YOU until R4-04 splits it out; nothing opens one before R4-03 → entries.jsonl:26
- Discovery (R4-01, affects R4-02): Adding a reason turns 58 (REASONS table literal, '15 reasons' in its name) and 59 (one fixture per reason in tests/fixtures/needs, FILLED's parked-only .question) red: plan §2.6 lists the edits → entries.jsonl:25
- Discovery (R4-01, affects R4-03): In a default stub run only A (verify un-passes it) and C (BROKEN first) get a second coding session: STUB_RESOLVE=A, not B, resolves STUB_ASK=A's question after STUB_ASK_AGAIN=B → entries.jsonl:25
- Discovery (R4-01, affects R4-02, R4-03): entries.jsonl questions carry the fill ' Files (harness, from the session): <abs paths>': a key over the raw first 80 characters would differ per run for a short question; questionKey cuts it (entries.mjs unfilled, to export) → entries.jsonl:25
- Discovery (R4-01, affects R4-04): status line stays 'NEEDS YOU <n> · harness needs' (53 pins it): with questions it reads 'NEEDS YOU 1 · 3 questions · harness needs' → entries.jsonl:25
- Discovery (R3-05, affects run): Promote item 'tests/lib.sh now holds tended, held…' does not hold on R3's branch (R1-07's lib.sh is not merged here; 47/48/49/76/77-resolve define held and ats themselves): left for a session on a branch with R1 in → entries.jsonl:24
- Discovery (R3-04, affects R3-06, run): 08-scope flaked twice in this session's full runs (gatestop memory gate; M2's lane never started, 2/3 passing): R1-06's fixes (HARNESS_COUNT_HOLD, gatestop at 2 GB) are not on this lane's base → entries.jsonl:22
- Discovery (R1-07, affects run): The coordinator's opens skip a milestone whose lanes/<m>/pid is still there (exited, unreaped); HARNESS_COUNT_HOLD leaves state/count-hold while holding, so a check can act inside the window → entries.jsonl:21
- Discovery (R1-07, affects run): 13-run-2-michael-sets-desk (harness desk --list) not reproduced: --repeat 10 was 10/10 green, 718 s → entries.jsonl:21
- Discovery (R3-03, affects R3-05, run): To test a main that moved after a milestone's verify, use STUB_MAIN_TOUCH=verify-<m>:<path>: a touch in a coding session is merged into the lane before the verify → entries.jsonl:20
- Discovery (R1-06, affects R1-07, run): Every stub run is M1 (A, B) then M2 (C, after M1): any check on a run's 3/3, M2's tag or its packs can hit R1-04's lane-count race; HARNESS_COUNT_HOLD=1 on that start holds the window every time → entries.jsonl:19
- Discovery (R1-06, affects R1-07, run): pgrep in a check is box-wide (sibling copies, other lanes' suites): match this copy's process by grep -zqF "HARNESS_SCRATCH=$T/" /proc/<pid>/environ (08's init_left) → entries.jsonl:19
- Discovery (R3-02, affects R3-06, run): 13/14-run-2 pin the initializer's lint sentence ending `milestone's size doesn't call for). No output means clean.`: a new lint item goes before the review one → entries.jsonl:18
- Discovery (R3-02, affects R1-07, run): Under this box's load (~21) the full suite took 1237 s and 08-scope and 48-lanes-rebase (a non-fast-forward push to origin main) flaked once each, green on the rerun → entries.jsonl:18
- Discovery (R1-05, affects run): Merging origin/main brought R2 in: its stub-claude.sh header comments conflicted with R1-02's STUB_BARRIER comment. Both are kept; the suite went from 944 to 973 checks. → entries.jsonl:17
- Discovery (R3-01, affects R3-02, run): unreproducible flags 3 steps of this run's list (R1-02 step 4 'below 5 s', R3-01 step 3, R3-02 step 3 quoting the examples): expected, reported never applied → entries.jsonl:16
- Discovery (R2, affects run): N2 is on origin main now (grep -c ...-N[12]$ = 2; 645d87e, in R2's HEAD): the R2/R1 plans' 'needs Michael' dependency line is stale → entries.jsonl:15
- Discovery (R2-05, affects run): Left by the review (Minor): the resume ignores a stop/lanes-end/deadline (bounded 10m, $1), and a refused resume is not fed to limit_raise → entries.jsonl:11
- Discovery (R1-03, affects R1-07, run): 13-run-2-michael-sets-desk 'harness desk --list' flakes under the full suite's load (R2-02 and R1-03 each saw it once, green on the rerun); not in the plan's flaker table → entries.jsonl:10
- Discovery (R1-03, affects run): origin/main came with 16 Gotchas lines (memlint red on main itself); this lane dropped the end-reasons line when it merged main → entries.jsonl:10
- Discovery (R1-02, affects run): ## Gotchas holds 14 bullets at most: memlint counts its <!-- --> comment line among the 15 → entries.jsonl:8
- Discovery (R2-01, affects run): 39-memlint-m4 lints this worktree's CLAUDE.md: a 16th Gotchas line turns the suite red; replace a line, never add past 15 → entries.jsonl:4
- Discovery (R1-01, affects run): N2 is not on origin main (1 of N1/N2 merged): an overlap conflict between lanes needs Michael → entries.jsonl:3
- Discovery (init, affects run): N2 (conflict resolution) is not on origin main: N2-02 waits on Michael. Only N1 merged (grep -c harness-merge/...-N[12] = 1). A text conflict between two lanes needs Michael as before; each plan says so in one line. → entries.jsonl:1
- Discovery (init, affects run): R2 and R3 both edit lib/record.sh and prompts/coding.md; R2-02 and R3-02 both edit prompts/initializer.md. Whichever merges second takes a re-base verify round; a text conflict needs Michael (no N2). → entries.jsonl:1

## Lately in the run

- 2026-10-29 20:47 · verify R3 · passes: All six R3 features hold: suite green at 993, memlint clean, 45/45 on the R3 check files, plan/decision/in-place lines/README/architecture present, grep -c writeFileSync = 1, check-names sorted. → entries.jsonl:38

## Current rules

- The suite waits on a condition or a barrier, never on the clock; a flake is reproduced with --repeat and fixed at its cause → journal/decisions/2026-10-29-tests-wait-not-sleep.md
- The rerun guard: a red full suite is rerun once; a flake is green, named and counted, never quarantined → journal/decisions/2026-10-29-rerun-guard.md
- Questions wait in `harness needs` until answered: one item per question, moved forward, no push → journal/decisions/2026-10-29-questions-wait.md
- Lanes leftovers: atomic list writes, a record-only main, the finish order, two lint rules, two checks, the suite-ran note → journal/decisions/2026-10-29-lanes-leftovers.md
- The coordinator ends a run only when the lane count its opens used saw no lane → journal/decisions/2026-10-29-lane-count-end-check.md
- Entries that survive: the session checks its own, a long summary is cut and kept, one resume for a missing one → journal/decisions/2026-10-29-entries-survive.md
- A parked run's continue advice names another live run of its project and gives Michael the choice → journal/decisions/2026-10-29-continue-advice-busy-project.md
- Merge conflicts resolved without Michael: a sorted merge for lists first, then a resolve session, verified → journal/decisions/2026-10-29-conflict-resolution.md
- This repo's suite gets a 25-minute check timeout; TEST_JOBS stays at its default → journal/decisions/2026-10-29-check-timeout-25m.md
- `harness show`: where a run's work is, from local refs, one change counted once → journal/decisions/2026-10-28-show.md
- A plain start or continue queues behind a live run of its project; overlaps are named, never held → journal/decisions/2026-10-27-same-project-starts.md
- The review gate: a milestone review's model by its measured diff, one Opus round after a Sonnet finding → journal/decisions/2026-10-27-review-gate.md
- A finished run keeps its record after gc: report reads worktree → state → ledger → journal/decisions/2026-10-27-record-after-gc.md
- Read views: one formatter, `lib/view.mjs`, that every read view renders through → journal/decisions/2026-10-27-read-views.md

_61 older rules: journal/decisions._
