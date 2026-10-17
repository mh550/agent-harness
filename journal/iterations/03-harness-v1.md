# Iteration 3 — Harness v1: initializer + one fresh session per feature (inside the app repo)

**Dates:** 2026-10-16, evening (Pathways commit `889f5fe` on `harness/2026-10-16`; files snapshotted in
[`03-harness-v1-files/`](03-harness-v1-files/)).

## Context
The Pathways threads & graphs slice was planned as OVERNIGHT-3 (iteration 2): one long `/loop`
session acting as orchestrator, delegating to subagents. It had not started yet.

## Trigger
I read Anthropic's ["Effective harnesses for long-running agents"](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents)
and asked how to follow it ([prompt](../sessions/2026-10-16-harness-design.md#1-the-switch)). Its core
idea answers the problem behind iterations 1–2. Every one of those approaches lived inside **one
context window that keeps growing**: compaction, handoff files and subagents only delay the limit.
The article's answer is to **end the session after each feature** and carry state on disk instead.

## Design
- **Two prompts, same tools.** An *initializer* (Fable 5.1, run once) turns the runbook's queue
  into `harness/feature_list.json`. Each entry has a verifiable step list, a model and
  `passes: false`. A *coding* prompt runs once per feature in a **fresh** headless session
  (`claude -p`, Opus or Sonnet per feature).
- **The article's artifacts, adapted:**
  - the feature list (JSON, because models are less likely to mangle it than Markdown);
  - `progress.md` (the article's `claude-progress.txt`, newest first so it reads well on a phone);
  - `init.sh` (suite, Playwright, a scratch server with the sample graph and a real Serato set replayed);
  - `smoke.mjs` (editor and Live view in headless Chromium at 1280/390 px);
  - git, with a commit and push per feature.
- **Session routine:** `pwd`, read progress and `git log`, run `init.sh` and the smoke test, fix a
  broken state first, do one feature test-first, verify every step, flip only its own `passes`,
  log, commit, push.
- **Driver:** `run.sh`, a ~60-line bash loop with a deadline, a session cap, 2 attempts per
  feature and an **edit guard**. If a session changes anything in the list beyond its own
  `passes`, the night stops.
- **Permissions:** `.claude/settings.json` with auto mode plus an allowlist of the commands
  sessions need, and denies for force-push, pushes to `main`, `.env`, sudo.
- **Models:** my choice was Fable for the initializer (one run, the highest leverage), then Opus
  for code, UI and reviews and Sonnet for docs and verification, per feature.

## How it was prompted
- [The switch](../sessions/2026-10-16-harness-design.md#1-the-switch): "follow the process in the
  article … what's the best way to try this out?"
- [Set it up](../sessions/2026-10-16-harness-design.md#2-set-it-up): tidy git first, auto mode plus an
  allowlist, and my model split ("Fable for the initializer, then sonnet/opus for the workers").

## Evidence
- The edit guard was tested on a fake list. It caught a flip of another feature's `passes` and an
  edited step; a legitimate own-flip passed.
- `init.sh` and `smoke.mjs` ran: suite green (122), smoke 4/4 at 1280/390, and the replay reached
  the set's end state (*Woman of the World* current, *All Night Long* cued).
- Two tiny real headless calls confirmed the model IDs (`claude-fable-5-1`, `claude-sonnet-5-5`)
  and every CLI flag the driver uses.
- **Finding:** headless sessions **ignore a project's allowlist until the folder is trusted**
  interactively ("Ignoring 31 permissions.allow entries…: this workspace has not been trusted").

## What worked / what broke
- ✅ It is faithful to the article, small (5 files), and every piece was checked once.
- ❌ **The auto-mode classifier blocked the git hygiene I asked for:**
  - merging PR #2 ("Merge Without Review");
  - deleting merged branches ("Git Destructive");
  - raising transcript retention in my settings ("Self-Modification");
  - a subagent mining Claude transcripts ("Sensitive-Source Provenance").
  These were the walls, not context.
- ❌ **The edit guard stops the whole night** for one bad edit: a poor trade for an unattended run.
- ❌ **It runs in place**, in my checkout of the app repo. Two runs, or me working in the repo at
  the same time, would collide.
- ❌ It is **not reusable**: the driver, prompts and logs live in Pathways, and the prompts hard-code
  Pathways details.
- ❌ `init.sh` is run by the *agent* (as in the article), so a session could skip it.
- ❌ No way to steer or unblock it remotely except attaching to tmux.

## Led to
[Iteration 4](04-harness-v2.md). My review questions were about permissions (permissive, deny only
history-destroying actions), the edit guard, merges and cleanup, remote control, and reuse across
projects. They are captured in [the session log](../sessions/2026-10-16-harness-design.md#3-review).
