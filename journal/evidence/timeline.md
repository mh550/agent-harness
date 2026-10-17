# Timeline: how Michael drove agents, 2026-02 → 2026-10-16

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
