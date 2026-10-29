# Timeline: how Michael drove agents, 2026-02 → 2026-10-29

Built only from git history and committed docs in `~/projects` (umbrella), `pathways`,
`dj-crate-streaming`, `hit_list`. Times are commit times (EDT) unless a runbook's Status log is quoted.
Status-log times sometimes run ~30 min off the commit times; commit times win where they differ.
*(inferred)* marks anything not stated in a file.

Abbreviations: **dj** = dj-crate-streaming · **umb** = `~/projects` · **ON1** = `~/projects/OVERNIGHT.md` ·
**ON2** = `~/projects/OVERNIGHT-2.md` · **PW-RB** = `pathways/docs/runbooks/2026-10-14-overnight.md` ·
**HL-RB** = `hit_list/OVERNIGHT.md` · **ON3** = `pathways/OVERNIGHT.md` at `cd3eacb`.

## Runs and sessions

| Date (EDT) | Project | Driver | Model(s) if stated | What was asked (one line) | Outcome (real numbers) | Notable problems |
|---|---|---|---|---|---|---|
| 2026-02-12 → 02-14 | hit_list | interactive *(inferred)*, laptop | not stated | Write the app spec, then "first few sprints for the MVP" (`6ee5d86`) | `APP_SPECIFICATIONS.md` "refined… ambiguity resolved through discussion"; Sprints 1–4 committed 15:03–15:11 on 02-13 (`db09540`…`bb96cc2`); Metro/web fixes 02-13/14 | Bundling fixes (expo-sqlite WASM, `@types/jest` pin) |
| 2026-09-17 (evening) | umb `ideas/` | interactive planning | not stated | Specs/research/decisions for DJ, Pathways, Mixxx; roadmap tuned to Michael's inputs (~10 h/week, Pathways most exciting, employer-shareable mockup) | `ideas/ROADMAP.md` "Michael's inputs (2026-09-17)"; Pathways mockup shipped first; `ideas/` backed up 22:05 | — |
| 2026-09-17 22:18–22:33 | pathways, dj | **"autonomous session"** (single session; Claude implements and tests) | not stated | "Continued per the roadmap" (PROGRESS.md): build Pathways Phase 1; DJ sourcing prototype | Pathways `6b38e83` (24 files, 2,204 lines) + `9dfe745` (README, STATUS, screenshots); **30 tests**; headless-browser pass. dj `71536d1` scorer/verifier prototype | STATUS.md: "built against the spec's one example plus my reconstruction"; real notes never arrived (still open on 10-16) |
| 2026-09-17 → 09-23 | umb `ideas/flyer` | interactive Q&A rounds 1–5 in `decisions.md` | not stated | Invite sender; Michael answers inline ("Michael: *"…"*") | Scoped down to **no build** (iOS Shortcut) on 09-23 | — |
| 2026-09-17 ~23:54 → 09-18 00:29 (transcript: "done Friday 12:14 AM", "12:29 AM") | dj + `ideas/` | **interactive** (transcript `ideas/dj-crate-streaming/convo-1.txt`) | **Fable 5.1 · Claude Max** (transcript banner) | 8 clarifications on Phase 0 docs, then "proceed with implementation work… use your best judgement" | One turn "Churned for 20m 20s": **4 background research agents** + Claude built the crate layer itself (`0fdf5de`, 27 new tests, 35 total). Second turn 3m 49s → `d7f1812`, **37 tests**, Docker image built and served | None recorded; 7 "· summarized" collapses in the transcript |
| 2026-10-13 02:25 | umb | laptop session writes for the next agent | not stated | Move to the Pop!_OS box and run unattended overnight | `27efc89` (75 files): `HOME-SETUP.md`, `HANDOFF.md` (agent-to-agent brief), `OVERNIGHT.md`, setup scripts; settings: auto-compact on, Remote Control, auto permission mode, deny rules | — |
| 2026-10-13 ~02:30–03:30 | umb | interactive desktop setup agent | not stated | "Read HANDOFF.md and walk me through it." | Box set up; bedtime direction recorded in ON1 (`ccd1734`, `e9f8300`) | Bedtime note wrong: all four VPN/Soulseek secrets *were* set (ON1 06:29) |
| **2026-10-13 03:35–06:38** | dj + umb (**ON1**) | **`/loop` overnight #1** | not stated; reviews by "a subagent", `/simplify` "4 agents" | M0 preflight → M1 media server → M2 library → M3 sourcing slice → M4 live slskd → stretch | **31 umb + 22 dj commits**; tests **37 → 80**; Navidrome + crates live on HTTPS tailnet; 917 originals → **859 tracks**, 35 genre playlists; slskd live, **0 downloads**; every box ticked | M3 review: **3 critical bugs the fake slskd had hidden**; "859 = 859 = 859" counts looked right while titles were wrong on the phone (quoted in ON2) |
| 2026-10-13 15:33–23:56 | dj, pathways, hit_list | interactive planning sessions ("planning session, evening; Michael away") | not stated | Design next nights; Michael answers §0 decision tables | dj spec rev 1→4 (`e6d912e`…`42e224b`); **ON2** `2bca0c2`; pathways spec + runbook `695cd39`, rev 2 `5e598eb`; hit_list spec + runbook `5b075e5`, rev 2 `77f0eaf` | — |
| **2026-10-13 23:04 → 10-15 08:12** | dj (**ON2** M0–M3) | `/loop` (one of **three parallel overnight loops**) | Opus reviews; **Sonnet reviewed M1 because "Opus had hit its usage limit"** | Playlists from Spotify, tag cleanup, dedupe | **29 umb + 38 dj commits**; suite **80 → 118** (M1) → 190; 11 playlists imported, 376 retagged, 359 re-filed, 28 copies trashed → **831 songs** | **No commits in any repo 00:12 → 07:19 on 10-14**; two "Try again" restarts; live tag damage by beets found by review and repaired; dedupe overwrote 18 trash files; classifier denials |
| **2026-10-14 00:03 → 10-15 00:47** | pathways (**PW-RB** M0–M4) | `/loop` | "most capable model" reviews | Phase 2: Serato parser, now-playing, Live view, library picker, art | **10 + 29 commits**; tests **30 → 45 → 71 → 80 → 102**; parser verified on all 22 real sessions | "Suspended 00:14 → 07:18"; the 5.5 h **time rule fired on wall-clock** and skipped M2–M4; reverted on Michael's "try again" (`7388951`) |
| **2026-10-14 00:03 → 10-15 00:52** | hit_list (**HL-RB**) | `/loop` | Opus reviews; Michael switched the session to Opus at 23:39 | Expo SDK 54→57, real-SQLite tests, photos, maps | **16 + 52 commits**; tests **115 → 220**; first green CI | M2 review subagent "died on a session rate limit"; final review "cut off by a session limit" |
| 2026-10-15 ~08:50 | dj | Michael in the session | — | "context usage too high" → **one thread per milestone** | `HANDOFF-M4.md` (`4802009`) + protocol in ON2 Pacing | The loop thread had run out of context after M0–M3 (HANDOFF-M4 line 4) |
| 2026-10-15 08:17–09:20 | dj (ON2 M4) | fresh thread from `HANDOFF-M4.md`, then `/loop` | Opus review | Quality tiers | 6 umb + 7 dj commits; suite **190 → 208**; `HANDOFF-M5.md` | One live search-only rank, 0 transfers |
| 2026-10-15 13:05–14:19 | dj (ON2 M5) | fresh thread from `HANDOFF-M5.md` | Opus review | Download validation | 5 umb + 9 dj commits; suite **208 → 249**; 831-file sweep (22 fail `crate`); `RECAP-M1-M5.md`, `HANDOFF-M6.md` | Review found a critical: webp covers would have made `fetch` delete good FLACs |
| 2026-10-15 16:10–16:20 | dj + umb | **review conversation** (interactive) | — | Answers to 12 open questions; "system/solution design direction" | Merge to `main` in both repos (`0f87804`, `b89bb58`); suite 256; `REVIEW-2026-10-15.md`, `TODO-MICHAEL.md` | — |
| 2026-10-15 16:17–18:13 | pathways (PW-RB M4 review → M6 → stretch) | `/loop` resumed | **"Opus implementer"** (Mixxx), **"Sonnet tester"** (M4 headless re-check) | Finish Phase 2 | 10 commits; tests **102 → 108 → 122**; 32 routes in `docs/api.md`; PR #1 merged 18:13 (`f2de0e9`) | Stretch 3 blocked on Navidrome creds (D15) |
| **2026-10-15 17:39–20:10** | hit_list | `/loop`, main session acts as orchestrator | Opus implementer, **Sonnet writes RED tests**, Opus review, `/simplify` "4 Sonnet reviewers; cleanup by Opus" | "delegate implementation to an Opus subagent and testing to a Sonnet subagent, each with a clear spec" | **40 commits**; tests **220 → 374** (37 suites), CI green; "Every item: tests first by a Sonnet subagent, code by an Opus subagent, Opus review, fixes" | — |
| 2026-10-15 23:37 → 10-16 00:53 | hit_list | review conversation (interactive) | — | On-device bug + D13–D15; simplification spec | 9 commits (`60f113f` uuid → expo-crypto fix; `353c27d` spec) | Device crash (`crypto.getRandomValues()`) that 374 tests had missed |
| 2026-10-16 00:05 | dj + umb | review conversation, part 2 | — | Ownership of facts; songs vs versions; worker container | `fe3069b` design doc; `6ff96e9` queue M6–M8 rewritten | — |
| **2026-10-16 01:05–21:18** | dj (ON2 M6–M8) | **"subagent-driven"** (ON2 16:15); a controller session *(loop vs. interactive not stated)* | M7/M8 plans assign **Opus or Sonnet per task** with reasons; reviews on Opus | Worker + approvals + beets filing; identity; lifecycle + play-now | **108 dj commits**; suite **256 → 785** (16:15) → "about 1,100" (README); M6 live, M7 reviewed twice, identity proposal over 831 files | Rebuild denied by the classifier as "production deploy" (`971f6a7`); no `HANDOFF-M7.md` was written although the protocol required one *(inferred: one controller thread ran M6–M8)* |
| 2026-10-16 09:44 | pathways (**ON3**) | **orchestrator runbook**, written but **never run as a loop** | Opus implementers, Sonnet testers, Opus reviewers reading diffs from files | Threads & graphs (T0–T7) | `cd3eacb`: ON3 + archived PW-RB + naming options; T0–T7 boxes all unchecked | Superseded the same day at 21:11 by `harness/` (`889f5fe`, iteration 3, out of scope here) |

## Turning points

1. **Spec-first predates the overnight loop.** hit_list's Feb 2026 spec was "refined… ambiguity resolved through
   discussion" (`APP_SPECIFICATIONS.md` at `6ee5d86`). By 2026-09-17 every idea had `spec.md` / `research.md` /
   `decisions.md`, and Michael answered open questions inline (`ideas/README.md`: "Michael answers open questions
   inline in this file"). Pathways Phase 1 (`6b38e83`) was built by an "autonomous session" from that spec.
2. **Iteration 0 already delegated research.** convo-1.txt (Fable 5.1, 2026-09-18): "Next I'll launch four
   research agents… while I review the existing Pathways stack" → "4 background agents launched". The model wrote
   and tested the code itself (35 → 37 tests, Docker build verified).
3. **Going unattended was about the box and the night, not a recorded limit.** `27efc89` (2026-10-13) moved
   everything to the desktop. HOME-SETUP.md: "auto-compact **on** (a long night outgrows the context window)",
   "**auto** permission mode", and the kickoff
   `/loop Follow ~/projects/OVERNIGHT.md: re-read it, do the next unchecked step, tick it, log it, commit.`
   ON1: "**This file is your memory across loop iterations and context compactions.**"
4. **The first overnight night made reality checks into rules.** ON2 (written 2026-10-13 evening): "Last night three
   critical bugs hid behind a fake that guessed the shape" → **"Fakes mirror the live API"**; "last night
   859 = 859 = 859 was true while 92 titles were still wrong on the phone" → **"What Michael will see" check**.
5. **Parallel loops ran into the plan's usage limit.** On the night of 2026-10-13/14, dj, pathways and hit_list each ran
   their own loop (each runbook: "Another overnight session owns the working trees of…"). Every repo is silent
   00:12 → 07:19. ON2: "Opus had hit its usage limit at 01:00, so Sonnet reviewed". HL-RB 23:39: "the M2 review
   subagent died on a session rate limit". PW-RB: "suspended 00:14 → 07:18". *(inferred: one shared plan limit.)*
6. **Context exhaustion → one thread per milestone.** ON2, 2026-10-15 ~08:50: "context usage too high. **New
   protocol: one thread per milestone.**" HANDOFF-M4: "The previous thread ran out of context after completing M0–M3
   and the first M4 step." (`4802009`, `1509b33`, `a6a8c91`.)
7. **Michael asks for orchestration.** HL-RB, 2026-10-15 afternoon: "Also asked: delegate implementation to an Opus
   subagent and testing to a Sonnet subagent, each with a clear spec." First executed at hit_list `e6e5157` (17:42):
   "RED tests by a Sonnet subagent…, implementation by an Opus subagent, gates re-run here." Pathways' loop was
   already using an "Opus implementer" and a "Sonnet tester" between 16:17 and 16:40 the same day, with no recorded
   instruction.
8. **The orchestrator design gets written down.** dj M7/M8 plans (`48d8050`, `d4c1000`, 2026-10-16) tag each task
   "(model: **Opus**: the one code path that writes library tags)" / "(model: **Sonnet**)". ON3 (`cd3eacb`) adds
   "### Orchestration (this session is the orchestrator)": "Keep your own context small."
9. **Orchestration hits permission walls rather than context walls.** `971f6a7`: "rebuild needs Michael's
   permission (classifier: production deploy)". `889f5fe` Needs Michael: "The auto-mode classifier blocks agents
   from merging."
10. **Iteration 2 in Pathways was overtaken in 11.5 h.** ON3 `cd3eacb` (09:44) → `889f5fe` (21:11): "**Driver
    (changed 2026-10-16): the long-running harness in `harness/`**… replaces the self-paced `/loop`."

## 2026-10-17 → 10-25: harness v3 nights, then the harness maintains itself (iterations 5–6)

Added 2026-10-25 from `ledger/runs.jsonl`, `gh pr list` in every repo (merge times converted to EDT) and the session
transcripts quoted in `sessions/2026-10-24-harness-catchup.md`. The v3 nights themselves have no rows of their own
yet; their totals head this section.

| Date (EDT) | Project | Driver | Model(s) if stated | What was asked (one line) | Outcome (real numbers) | Notable problems |
|---|---|---|---|---|---|---|
| **2026-10-17 → 10-24** | all seven | **harness v3** (queue, driver, verify, self-merge) | per role, in `ledger/` | the queued nights | **22 runs, $1,941.70, 520 features passing, 5,595 tests added; 224 merged** | the harness's own follow-on runs parked in `queue/held/` and never ran; the live checkout fell 109 commits behind; 10 OOM kills; n8n-home 0/32 on a deny |
| 10-23 21:43–22:28 | n8n-home | interactive | — | "What are my todos now?" → "relax the denylist… sessions… deploy too" | n8n-home PR #1 (allow `docker compose`), #2 (live-staged) | a project deny overrode the user allow |
| 10-24 00:42 | hit_list | interactive | — | "how do I handle the 10 open pull requests… Maybe we just allow merges" | PR #18 merged with all ten milestones stacked; #9–#17 closed with it | one PR per milestone on a project with no production |
| 10-24 00:52 → 11:57 | rane-one-mixxx run | interactive, during the run | — | "a 6gb node instance was spawning up… Why?" | `findings-and-research/2026-10-24-oom-from-unbounded-test-diff.md` | four ~7 GB `assert.deepEqual` diffs; no memory cap per session; the finding ended up on a branch |
| 10-24 11:52 → 13:40 | agent-harness | interactive, then step 1 and step 3 | Sonnet 5.5 (transcript banner) | state of the harness runs → [four meta issues](prompts/2026-10-24-four-meta-issues.md) → [chunk it](prompts/2026-10-24-chunked-handoff.md) | PR #11 (stranded work, 13:12), PR #12 (sync, park, self-merge; suite **236/236**, 13:39); the five-chunk handoff | — |
| 10-24 12:30 | box | interactive background job | — | the boot hang, "6 python instances", "a bunch of `2.1.310` instances" | `2026-10-24-system-resource-audit.md`: ~1.07 M leaked `/tmp` files, 8 idle voice-concierge workers, `bg-spare` sessions, 7.3 GB of worktrees | couldn't write to the live checkout; left uncommitted in a worktree |
| 10-24 12:39 | agent-harness | interactive | — | procedurize the memory field guide "without adding bloat" | `docs/specs/2026-10-24-memory-model.md` (K1–K4) | on a branch until PR #11 |
| 10-24 15:31 → 16:44 | agent-harness | handoff chunk 1 | — | "do Chunk 1 only, within its limits" | PR #13 (templates + apply script, 15:44), PR #14 (dj live, 16:35) | — |
| 10-24 15:50–16:51 | box | **Michael** (chunk 2) | — | apply the policy; free the box | apply script run at 15:50 and 16:44 (backups in `backups/apply-2026-10-24-*`); voice-concierge stopped; zram 50 %; reboot 16:51 | `bg-spare` sessions back within a day |
| 10-24 16:57 → 23:32 | n8n-home, rane-one-mixxx | catch-up workers, prompt **v1** (6,156 chars) | — | Part 1, then [a redundancy sweep](prompts/2026-10-24-redundancy-sweep.md) as a second prompt | n8n-home #3, #4 (52/82 → 22/5); rane-one-mixxx #6, #7 (37/43 → 3/7); harness PR #15 (templates from the sweep) | two rounds each: "reduce" had no test |
| 10-24 23:50 → 10-25 00:14 | agent-harness | interactive background job | Opus 5.5 | [fix the prompt, not the output](prompts/2026-10-25-fix-the-prompt.md) | PR #16: catch-up prompt **v2** (8,746 chars), targets per project | — |
| **10-25 00:21 → 00:59** | voice-concierge, dj, hit_list, pathways, portfolio_site | five catch-up workers, prompt v2 | — | Part 1 | voice-concierge #15–16, dj #23–#32, hit_list #19–20, pathways #14–15, portfolio_site #29; project rules **404 → 51** in total; 35 stale remote branches deleted in portfolio_site alone | no second prompt about settings; pathways paused for memory (four workers at once, one over the limit of three); dj's `--all-merged` skipped `harness/*` |

### Turning points

11. **A week of good runs hid a stalled system.** 520 features passed but only 224 were merged. The harness's own
    improvement runs sat in a folder the runner never reads, and the live checkout was 109 commits behind (decision
    `2026-10-24-close-the-loop`).
12. **Four symptoms, one cause.** Retros in run folders, worktrees "blocking" writes, permission sprawl and memory
    sprawl all came from one pattern: "almost nothing reaches main, or the running harness, unless you carry it there
    by hand" ([prompt](prompts/2026-10-24-four-meta-issues.md)).
13. **The safety policy caused the mess.** Denies on `git branch -D`, `worktree remove` and `push --delete` were
    meant to be safe, and they are why branches and worktrees piled up. One `docker compose` deny cost a whole run.
    The new rule: deny only what can't be undone (`decisions/2026-10-24-permissions-policy`).
14. **The prompt is the product.** Two workers needed a second round; the fix went into the shared prompt (a test, a
    query, a target per project), and the next five finished in 40 minutes without one.

## 2026-10-25 → 10-26: the first queued chain, and throughput (iteration 7)

Added 2026-10-26 from `harness report`/`harness status`, the run branches' commit times, `gh pr list` (merge times
converted to EDT) and the session transcripts quoted in `sessions/2026-10-25-throughput-design.md`.

| Date (EDT) | Project | Driver | Model(s) if stated | What was asked (one line) | Outcome (real numbers) | Notable problems |
|---|---|---|---|---|---|---|
| 10-25 01:52 → 02:04 | agent-harness | handoff chunk 4 | — | three specs and the queue, no code; gc's slash bug and parked reasons folded in | PR #18: resource lifecycle, retro fixes, memory specs; n8n-events parked with its reason | — |
| 10-25 11:49 → 11:50 | agent-harness | chunk 5 (Michael) | — | "Give each of the commands to me in a clear, concise way" | queue tidied, `harness queue start`; lifecycle run starts 11:50 | — |
| **10-25 11:50 → 10-26 02:50** | agent-harness | **harness v3** run `…-2026-10-25-lifecycle` | per role (Sonnet verify/retro, Opus build) | L1–L5: capped scopes, service stop points, scratch + tmux reaper, gc from the runner, config reload | **25/25, all verified and merged by the harness** (PRs #19–#21, #25, #26); **$83.17**, $3.33/feature; 15 h, 32 sessions; first-attempt 1.00 | took 15 h for 25 features |
| 10-25 14:23 → 16:32 | agent-harness | interactive (status, then measurement) | — | "Is there any way we can improve the parallelization… avoid creating duplicate/cleanup work" ([prompt](prompts/2026-10-25-improve-parallelization.md)) | measured: usage window 12 %, the suite ~8 min = 31 % of session time, driver serial; recommended split suite → lanes → 2 runs | the session briefly ran the suite in the live lifecycle worktree (stopped in ~2 min) |
| 10-25 22:00 → 22:27 | agent-harness | interactive design session | — | build it, with anti-goals and a CoALA bucket × scope memory model ([prompt](prompts/2026-10-25-parallel-without-new-work.md)) | PR #22: throughput-and-memory design + rollout plan; a cold builder-check agent raised 6 questions (4 settled in the design) | — |
| 10-25 23:53 | agent-harness (live checkout) | unknown | — | — | `main` fast-forwarded by a `git pull --rebase` while the lifecycle run was alive (reflog) | breaks "never pull while a run is alive"; no harm |
| 10-26 00:12 → 00:46 | agent-harness | design session | — | approve, with questions ([prompt](prompts/2026-10-26-approve-with-questions.md)); six decisions answered | PR #23 (suite-split + lanes specs; retro F3 dropped, memory amended); PR #24 (split folded into lanes as P0); master to-do in `~/Downloads` | — |
| 10-26 02:50 → 05:29 | rane-one-mixxx | harness v3 continuation | — | answer M5-06 (pin deck 2's sag), continue | **19/19** (from 9/19, parked since 10-24); tests **868 → 1,262**; $111.08 for the whole run | ran alone though `MAX_PARALLEL_RUNS=2` was set *(inferred: runner predates L5's config reload)* |
| 10-26 05:29 → 08:30 | agent-harness | harness v3 run `…-2026-10-26` (lanes) | — | P0 suite split, P1, P2 | P0-01 passes (one file → 29 files, 327 checks, conformance-checked); P0-02: **589 s → 165 s** with `TEST_JOBS=4`, 390 MB peak; **blocked at 2/17**, $22.87, nothing merged | step 5 said "under 150 s"; the floor is ~159 s; two attempts, 14 dependants blocked |
| 10-26 08:51 → running | agent-harness | harness v3 run `…-2026-10-26-2` (retro) | Opus build | F1 (driver/CLI fixes), F2 (initializer/verify) | **12/12** by 13:30; F1 verified and merged (PR #27, 11:37); $35.25 so far; first-attempt 1.00 | ran on the old single-file suite (~10 min per run), F1 and F2 serial; its checks now conflict with the split in 4 files |
| 10-26 10:28 | agent-harness | interactive status | — | "What's the status of the agent harness runs we queued last night?" | the 10:15 status: lanes blocked; **0 real OOM kills** (136 kernel kills, all in the suite's 64 MB test scopes) | claimed rane and lanes overlapped 05:50–08:30; commit times say they didn't |
| 10-26 12:55 → 13:10 | agent-harness | design session | — | unblock lanes with "sensible defaults around time limits" ([prompt](prompts/2026-10-26-unblock-with-sensible-limits.md)) | park memory (driver conflict); branch fix plan (re-run `tests/split.sh` on `main`); rule: performance numbers are "measured and recorded"; master to-do "UPDATE 13:10" | — |

### Turning points

15. **The harness became safe before it became fast.** The lifecycle run made every session and suite memory-capped
    and every run's leftovers cleaned by code. Iteration 6's hand cleanup became behaviour, and the next night had no
    real OOM kill.
16. **Measure before parallelizing.** I expected usage limits and serial runs to be the bottleneck. The measurement
    showed the harness's own 8-minute test suite took 31 % of session time and the driver was serial by construction
    ([prompt](prompts/2026-10-25-improve-parallelization.md)).
17. **Anti-goals as the design brief.** "A system that doesn't create more work" became the design's anti-goals: no
    hand-fixed conflict, no orphaned worktree, branch or data, one writer per store. Lanes keep the two invariants
    (what merges is what was verified; the driver is the record's one writer), and memory became one CoALA bucket ×
    scope table.
18. **The harness builds its own parallelism, and the whole chain was queued to run unattended.** The suite split
    became P0 of the lanes run, so no human step sat between runs (`decisions/2026-10-26-lanes-first-rollout`).
19. **A soft target written as a gate.** "About 2.5 minutes" became "under 150 s", and an honest session that
    wouldn't pass itself at 165 s blocked 14 features. The fix is a rule, not just an answer: performance numbers in
    steps are "measured and recorded" unless they protect the box.

## 2026-10-26 → 10-29: lanes land, stops made visible, the unattended night, a chain that broke (iterations 7–8)

Added 2026-10-29 from `harness report <run>`, `harness status --all --json` (start and end times converted to EDT),
`harness show`, `gh pr list --state merged` (merge times EDT), the ledger commit subjects in `git log origin/main`, the
specs and decisions of those days, and `runs/2026-10-29-hiccups.md`.

| Date (EDT) | Project | Driver | Model(s) if stated | What was asked (one line) | Outcome (real numbers) | Notable problems |
|---|---|---|---|---|---|---|
| 10-26 08:30 → 13:34 | agent-harness | harness v3 run `…-2026-10-26-2` (retro), its end | Opus build | F1, F2 | **12/12**; F1 #27 (11:37), F2 #28 (13:33); $35.25, $2.94/feature; 5.03 h, 14 sessions; first-attempt 1.00 | `status --json` gives the start as 08:30 (the row above says 08:51); its report still says `Ended running` |
| 10-26 13:37 | agent-harness | interactive | — | write iteration 7 | PR #29 | — |
| 10-26 afternoon → 10-28 01:11 | agent-harness | the lanes run `…-2026-10-26`, 4 continuations | per role | P0 split, P1 lanes serial, P2 two lanes | **17/17**; P0 #30 (10-26 16:51), P1 #40 (10-27 20:32), P2 #41 (10-28 01:11); $127.95, $7.53/feature; 14.24 h wall, 31 sessions; first-attempt 0.82; tests 419 → 602 | built at the same time as the memory run, both rewriting `lib/driver.sh`, no warning; a merge session moved memory's driver changes into lane-era files (`decisions/2026-10-27-p1-main-merge`) |
| 10-26 17:23 | agent-harness | interactive research | — | orchestrator landscape and sandboxing | PR #31 (findings) | — |
| **10-26 18:54 → 10-27 01:47** | agent-harness | harness v3 run `…-2026-10-25-memory` | per role | M1–M6: retro backlog, gotchas in place, pack rules, memlint, test counts, review gate | **23/23**, M1–M6 #32–#37; $58.05, $2.52/feature; 6.89 h, 33 sessions; first-attempt 0.96; tests 395 → 501 | ran on the serial driver (P1 not merged yet), so not the first lane run as planned |
| 10-27 01:03 → 20:44 | n8n-home | harness v3 continuation of `n8n-home-2026-10-22` | per role | B1–B6 | 4/34 → **34/34** (ledger commits); whole run $169.39, 52 sessions, 2 continuations, first-attempt 0.85 | overlap with the lanes run *(inferred from commit times)* |
| 10-27 morning → 10:43 | agent-harness | interactive spec session | — | "what needs me" on one screen: what I saw (24 runs / 105 lines of status, `nothing parked` with two runs blocked) | PR #38: `docs/specs/2026-10-27-status-ux.md` (U1–U3, five bugs) | — |
| 10-27 16:39 | agent-harness | interactive fix | — | checks SIGPIPE-ing under pipefail | PR #39 | — |
| **10-28 01:12 → 22:39** | agent-harness | harness run `…-2026-10-28` (first run on lanes) | per role | U1 read views, U2 the needs record, U3 `show` and same-project starts | **24/24**; U1 #42 (08:30), U2 #43 (15:52), U3 #45 (22:38); $139.12, $5.80/feature; 21.46 h, 30 sessions (1 refused by a limit); first-attempt 0.96; tests 602 → 859; at most 1 lane open | — |
| 10-28 20:02 → 22:39 | agent-harness | interactive | — | my answers to the open defaults | PR #44 (reviewer follows the session's model; test count pinned only from a green suite) | — |
| 10-28 evening → 10-29 01:17 | agent-harness | interactive spec session | — | "handle merge conflicts like this without needing my approval", guard in place "before the night starts" | PR #47: unattended-night (N1, N2) and reliability (R1–R4) specs; suite measured 00:05–01:00: 601 s alone, 857 s two at once; `CHECK_TIMEOUT=25m` | two lanes would have left 43 s of the old 15-min timeout |
| **10-29 01:19 → 11:20** | agent-harness | harness run `…-2026-10-29`, 1 continuation | per role | N1 rerun guard, N2 conflict resolution, in series | **11/11**; N1 #48 (05:21), N2 #51 (11:19); $54.36, $4.94/feature; 8.49 h, 21 sessions; first-attempt 0.82; verify-fail 0.08; tests 859 → 925; 0 flakes | parked at 10/11 at 08:49 (record #49): N2-02's step contradicted git 2.43; reworded by me, re-verified with no code change |
| 10-29 08:49 → 11:37 | agent-harness | harness run `…-2026-10-29-2` (reliability, two lanes) | per role | R1–R4 side by side | paused at 3/23 (~$14), stopped; record #53 (11:37); **4/23**, $18.67, 2.8 h wall, 8 sessions, 4.8 lane hours; 2 flakes named | started on 3470da3, without N2; the continue after the sync failed: gc had deleted its worktree and branch (#53 made it look merged) |
| 10-29 morning *(inferred)* → 10:39 | agent-harness | two assisting interactive sessions | — | answer N2-02; what to do about -2 | PR #50: `runs/2026-10-29-hiccups.md` | one advised a continue that the one-run-per-project hold would have queued behind -2; I caught it |
| 10-29 late morning | agent-harness | interactive design session | — | let the harness improve itself in a chain of runs without breaking | proposal: `--after` series, pinned installs, mid-run upgrade, adoption gate, edge/stable channels, rollback ([iteration 8](../iterations/08-unattended-nights-to-self-improvement.md)); not chosen, no spec yet | — |
| 10-29 12:33 | agent-harness | `…-2026-10-29-2` running again | — | — | 4/23, two lanes; `harness show` lists a conflict with `origin/main` in `CLAUDE.md` | — |

### Turning points

20. **Visibility before autonomy.** Before removing any stop, every stop got one record and one card that says where
    and what to type. `harness parked` had said `nothing parked` while two runs were blocked on me.
21. **Remove only the mechanical stops, and keep the gate.** A flake is rerun once; a conflict in a sorted list is a
    merge driver; anything else is a resolve session. The merged tree still goes through verify, so what lands on
    `main` is still what was verified.
22. **Measure the guard before the night.** The 15-min suite timeout would have left 43 s with two lanes. Measured at
    midnight, set to 25 min for this repo only.
23. **Ended isn't merged.** A chain of self-improvement runs assumed run 2 would start on run 1's code. Run 1 parked,
    the queue started run 2 on the old harness, and moving it took four commands that still failed. Upgrading the
    harness is a release problem: installs, a gate, channels, rollback (proposed, not built).
