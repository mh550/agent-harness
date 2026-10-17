# Iteration 1 — Spec first, then an unattended overnight `/loop` with a runbook as memory

**Hypothesis check:** *confirmed, refined.* The design is as hypothesised (one self-paced session, an `OVERNIGHT*.md`
runbook as memory, superpowers skills as discipline, a "What Michael will see" check). Four refinements:
(1) it starts **2026-10-13 03:35** with the umbrella `OVERNIGHT.md` (dj-crate-streaming Phase 0/1), a night
before the Pathways run; (2) on 2026-10-13/14 **three loops ran in parallel** (dj OVERNIGHT-2, Pathways, hit_list);
(3) reviews and `/simplify` already went to **subagents** (Opus reviewer, "4 agents"); (4) the documented
limit problems belong **here**: usage limits on 10-14 and "context usage too high" on 10-15. Michael's answer to those
was an intermediate step, **one thread per milestone with handoff files**.

## Dates

- 2026-10-13 03:35 → 06:38: overnight #1 (`~/projects/OVERNIGHT.md`, dj + umbrella).
- 2026-10-13 evening: planning sessions write specs and runbooks for three projects.
- 2026-10-13 23:04 → 2026-10-15 ~20:10: OVERNIGHT-2 (dj, M0–M5), Pathways Phase 2 (`docs/runbooks/2026-10-14-overnight.md`,
  M0–M6 + stretch, PR #1 merged 2026-10-15 18:13), hit_list (`OVERNIGHT.md`).
- 2026-10-15 08:50 → 14:50: dj switches to "one thread per milestone" (HANDOFF-M4, -M5, -M6).

## Context

- New always-on Pop!_OS desktop (GTX 1070, Docker, Tailscale). Michael watches from the iPhone: Remote Control, push
  notifications, the GitHub app, and "a second Claude session that can read anything under `~/projects`" (every
  runbook's first paragraph).
- Settings for unattended runs (HOME-SETUP.md §3): auto-compact on, Remote Control at startup, **auto permission mode**
  (classifier), deny rules for `sudo`, force-push, pushing `main`, `git reset --hard`.

## Trigger

Moving to a box that can work while Michael sleeps (HANDOFF.md: "get Michael to bed with the overnight loop running").
*(inferred)* Also: in iteration 0 every session needed Michael at the keyboard. No limit problem is recorded before
the move.

## Design

| Part | What it was |
|---|---|
| **Cycle** | (1) **Planning session** with Michael: a design spec whose §0 is a decisions table, each row a default plus "a direct question for Michael" (pathways spec header). (2) **Runbook** (`OVERNIGHT*.md`) generated from it. (3) **Overnight `/loop`**. (4) **Review conversation** next day: merge, answer defaults, set direction. |
| **Memory** | The runbook. "**This file is your memory across loop iterations and context compactions.** Re-read it at the start of every iteration, do the next unchecked step, tick it, append to the Status log, commit." Sections: Ground rules · Discipline · Phone updates · Pacing · Decisions already made · Queue (checkboxes) · Direction from Michael · Needs Michael · Status log (newest first). |
| **Ground rules** | Branches only (`overnight/<date>`, never `main`); no sudo, which goes to "Needs Michael" with the exact command; originals read-only, trash not delete; secrets never printed; no Soulseek downloads without Michael; "Simple beats clever"; new decisions get "the simplest reversible default" and a question, "Don't block"; Michael's message overrides the queue; classifier denial → "one narrower form", then Needs Michael, "Never retry verbatim"; stay in your own repo when other loops run. |
| **Discipline** | superpowers: `writing-plans` → `docs/plans/`, `test-driven-development`, `systematic-debugging`, `verification-before-completion`, `requesting-code-review` (a subagent, "most capable model") at each milestone, then `/simplify` (4 angles). Added after night 1: **"Fakes mirror the live API"** and the **"What Michael will see" check** (ON2). Pathways added a **time rule** (5.5 h → do the asked-for design doc first). |
| **Models** | Main session's model not stated. Reviews on Opus ("most capable model"), Sonnet as fallback when Opus is rate-limited (HANDOFF-M4). Michael switched sessions to Opus by hand (`/model claude-opus-5-5`, HL-RB). |
| **Roles** | One loop session per repo implements everything; reviewer and `/simplify` subagents read the diff; Michael steers from the phone; a separate "review conversation" session merges and folds in answers. |
| **1.5: one thread per milestone** | From 2026-10-15 08:50 (dj): at the end of each milestone, write `HANDOFF-M<next>.md` (start here / where things stand / hard-won facts / open questions / protocol), commit, stop the loop. Michael pastes it into a fresh thread, which restarts the `/loop`. |

## How it was prompted

- [2026-10-13 — kickoff `/loop` line, HANDOFF walkthrough, phone steering](../evidence/prompts/2026-10-13-overnight-loop-kickoff.md)
- [2026-10-13 — answers to the Pathways Phase 2 decisions table](../evidence/prompts/2026-10-13-pathways-phase2-answers.md)
- [2026-10-14/15 — "Try again" and switching to Opus after limits](../evidence/prompts/2026-10-14-try-again-model-switch.md)
- [2026-10-15 — "context usage too high" → one thread per milestone](../evidence/prompts/2026-10-15-one-thread-per-milestone.md)
- [2026-10-15 — review conversations (dj, pathways)](../evidence/prompts/2026-10-15-review-conversations.md)

## Evidence

- **Overnight #1** (ON1, 2026-10-13 03:35–06:38): 31 umbrella + 22 dj commits; tests **37 → 80**; Navidrome +
  crates on HTTPS tailnet; **917 originals → 859 tracks**, 35 genre playlists (908 entries); gluetun + slskd live, **0 downloads**;
  every box ticked; Status log "Done… loop stopped".
- **OVERNIGHT-2** (dj): M1 suite 118 → M4 208 → M5 **249**; 11 Spotify/report playlists imported, 376 retagged,
  28 copies trashed → 831 songs; 831-file verify sweep, 22 fail `crate`; 256 after the review conversation.
- **Pathways Phase 2** (PW-RB): 49 commits over three sittings; tests **30 → 45 → 71 → 80 → 102 → 108 → 122**;
  Serato parser verified on all 22 real sessions ("0 errors, 0 warnings"); 32 routes in `docs/api.md`; 15 Live
  screenshots; Mixxx spike in 37 min of a 45 min timebox; PR #1 merged `f2de0e9`.
- **hit_list**: Expo SDK 54 → 57 in three hops, first green CI; tests **115 → 220** by 2026-10-15 00:52.
- **Reviews found real bugs every time**: ON1 M3 "3 critical (fake slskd encoded the wrong transfer shape…)";
  ON2 M2 live tag damage "found and repaired from originals" (`2b40eb9`); M5 "genuine FLACs with a webp cover were
  rejected at every tier, and `fetch` would have deleted the download". HANDOFF-M4: "Every Opus review so far found
  real bugs, two of them live damage; don't skip it."

## What worked / what broke

**Worked**
- Unattended progress overnight, with every decision written down as a question instead of blocking.
- A runbook in git meant the phone (GitHub app) became the status page, and Michael's one-line messages
  ("Try again") were enough to restart.
- Reality checks became rules after they failed once: fakes built from captured live responses; "Counts are not
  enough; last night 859 = 859 = 859 was true while 92 titles were still wrong on the phone" (ON2).

**Broke**
- **Usage limits with parallel loops.** No commits in any repo 2026-10-14 00:12 → 07:19. ON2: "Opus had hit its
  usage limit at 01:00, so Sonnet reviewed". HL-RB: review subagent "died on a session rate limit"; a later final
  review "cut off by a session limit". *(inferred: three loops shared one plan.)*
- **The time rule misfired.** It measured wall-clock time across the 7 h suspension and skipped M2–M4; reverted on
  "try again" (PW-RB 2026-10-14 08:00, `7388951`).
- **Context exhaustion.** "context usage too high" (ON2 2026-10-15 ~08:50); "The previous thread ran out of context
  after completing M0–M3 and the first M4 step" (HANDOFF-M4).
- **The permission classifier.** It blocked sourcing `.env`, an inline Python playlist edit, a read-only Navidrome
  admin login ("production reads"), and undoing the Tea tent merge (ON2 Needs Michael).
- **Rules broken by the agent's own code.** The dedupe move overwrote 18 trash files ("breaks 'nothing is ever deleted'", ON2).
- **Tests didn't catch device-only bugs.** hit_list's `crypto.getRandomValues()` crash on import (`60f113f`) shipped
  through 374 tests.

## Led to

- **1.5, one thread per milestone** (2026-10-15 08:50): handoffs are context resets with a written brief.
- **Iteration 2, orchestration** (2026-10-15 afternoon): Michael asked hit_list's loop to "delegate implementation to
  an Opus subagent and testing to a Sonnet subagent, each with a clear spec". The main session then keeps only the
  plan, the gates and the log.

## Questions for Michael (from memory)

1. Was the 2026-10-14 00:12 → 07:19 gap across all repos a plan usage limit? Did you start three loops on purpose
   to use the night, and did you notice they shared one limit?
2. What model did the loop sessions themselves run on before you switched to Opus (Fable 5.1, Sonnet)?
3. Who wrote the runbooks: a planning session from your answers, or you editing them? How much of ON1 did you write by hand?
4. How did you actually read progress at night: the GitHub app, the "second Claude session", push notifications?
   Which one mattered?
5. What did "context usage too high" look like on 2026-10-15 (a warning, a slow session, compaction losing rules)?
