# 2026-10-16 — from an orchestrator runbook to a reusable harness (one conversation)

One Claude Code conversation, run as a remote session on the home box. It went from writing the
OVERNIGHT-3 runbook (iteration 2) to harness v1 (iteration 3) to harness v2 (iteration 4). Below
are my messages verbatim, each with what came out of it.

## 0. The kickoff (iteration 2: the orchestrator runbook)

> Context for this session.
> - Project: ~/projects/pathways (GitHub mh550/pathways, private). The checkout is on branch overnight/2026-10-14, fully merged into main via PR #1 (main @ f2de0e9). Suite 122/122, typecheck clean, Node 24, zero runtime deps.
> - Phase 2 (Live view, Serato now-playing, library picker + art, set recorder, Mixxx spike) is done and on main. Read docs/STATUS.md and docs/architecture.md first for the state of the system; docs/api.md is the HTTP/SSE contract.
> - Tonight's chunk: implement threads and graphs from docs/specs/2026-10-14-threads-and-graphs-design.md (model B: edges stay global, threads = edge memberships, graphs = thread compositions plus cherry-picks). Its §9 is the one-night plan, T0–T7 (~7.75 h): schema v3 + migration, Graph memberships, importer --thread / --threads-from-headings, API + LiveState out/context/elsewhere_count + ?graph=, editor graph switcher + Threads/Graphs tabs + context rendering (§7), Live view context, sets show with pathways + sets export (T6 drops first if short), docs and wrap-up.
> - §11 of that doc has 8 questions with defaults in bold. Take the defaults unless answered here:
>
> 1. I don't know what the database design should be. The user should be able to have threads, and view pathways / graphs without threads. The thread would be a more saturated/global version of a set of edges in a graph, who's data is persisted across pathways.
> 2. A thread is a set at its core, but could carry a canonical walk. There is some ordering inherent in the thread, but it's rather dynamic and flexible. I'm unsure.
> 3. Yes
> 4. The normal eventual flow will not be import-based-- rather, I will be creating threads within the app itself as opposed to in my notes app at all. So we don't need to worry about creating threads from the import at all-- complexity that's not worth it.
> 5. I'm confused by this-- a pathway is just a path through the graph. I don't think we'd be adding new pathways-- rather, we'd be adding songs and threads-- sometimes converting groups of songs into threads. I think this comment reveals the ordering-- as I brainstorm I have a natural ordering to the songs that come to mind. So the original creation of the thread has an ordering inspiring it, but it's core ideas are unordered. This informs #2 as well.
> 6. Agreed with your defaults.
> 7. For our app, I don't really see us exporting a pathway. I see the most common flow of us adding a graph to Navidrome. Or vice versa. Maybe we find a way to sync them.
> 8. Help me brainstorm different naming options for the terminology across the whole application.
>
> - The old runbook ~/projects/pathways/OVERNIGHT.md is the Phase 2 one, fully ticked. Its "Ground rules", "Discipline", "Phone updates" and "Pacing" sections carry over unchanged. Tonight's runbook replaces it: archive the old one to docs/runbooks/2026-10-14-overnight.md, then write a new OVERNIGHT.md with the same structure (ground rules, discipline, phone updates, pacing, decisions already made, queue M0 + T0–T7 + stretch, Direction from Michael, Needs Michael, Status log) built from §9 and the §11 defaults. Each T-milestone gets a plan file docs/plans/<date>-t<n>-<topic>.md before code, TDD throughout, a code review and /simplify at the end of each milestone, and a "What Michael will see" check (screenshots at 1280/390 px, replay of tests/fixtures/serato/399.session) after T4 and T5.
> - Still open, defaults taken, carried over to Needs Michael: D15 (no ~/projects/pathways/.env yet, so Navidrome stays on the fake and T6's export is CLI-only until credentials exist), D16 (Mixxx play logging unverified; Michael opens Mixxx once on the desktop), D18 (current-track rule), D19 (artist-less track adopted when the artist arrives), the laptop live run, and the real notes (still only samples/notes-sample.md on this box).
> - Git: other overnight sessions may be running on this box. Never run git checkout / switch / stash / reset / commit in ~/projects or ~/projects/dj-crate-streaming. All your git activity stays inside ~/projects/pathways on overnight/2026-10-16, created from origin/main at M0. Never touch main, never force-push, never rebase a pushed branch. Merging into main happens in the review conversation, not tonight.
> Now: read docs/STATUS.md, docs/architecture.md, the threads-and-graphs design doc in full (especially §4–§7, §9, §11), the old OVERNIGHT.md, src/db.ts, src/graph.ts, src/server.ts and src/live.ts; run git status and git log --oneline -3 in ~/projects/pathways and git fetch origin main to confirm the state above; create overnight/2026-10-16 from origin/main; archive the old runbook and write the new OVERNIGHT.md as described; run npm run check; commit "OVERNIGHT-3: runbook" and push. Report in five lines or fewer whether anything differs from the state above, then stop and wait for Michael's /loop command.
> Delegation, to keep your own context window small: you are the orchestrator. Delegate implementation to an Opus 5.5 subagent (one per milestone or per independent task) with a written spec in your scratchpad: goal, files to read first, exact behaviour, tests to write first, what not to touch, a timebox, and a report limit of 300 words. Delegate testing and verification (headless Chromium passes, replay checks, real-data runs) to a Sonnet 5.5 subagent with a clear statement of what to test and why, what PASS looks like, and the scratch DB and port to use. Delegate code reviews and the four /simplify angles to Opus 5.5 reviewers that read the diff from a file in your scratchpad and return findings only. Run independent agents in parallel in one message and never two agents on the same files. Do not read large diffs, transcripts or screenshots yourself when an agent can report the conclusion; verify agents' claims with one cheap command (npm run check, git status, a grep) before ticking a box. Keep OVERNIGHT.md's Status log as the record Michael reads from his phone: tick the box, log the result with real names and numbers, commit, push after each milestone, one push notification per milestone.

**What came out:**
- the OVERNIGHT-3 runbook (`cd3eacb`, snapshot in `../iterations/02-overnight-3-runbook.md`);
- design §12, where my answers turned threads into song-based sets in brainstorm order and made
  the edges of a graph induced from its songs (D20–D24);
- `docs/naming-options.md`.

**Worth noticing:** this prompt already does harness work by hand. It states facts to confirm, has
a stop condition, a report limit, roles per model, and the rule "verify agents' claims with one
cheap command".

## 1. The switch

> I'd like to adjust my development approach-- instead following the process as described in https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents . How can I set this up? Do I need to use the claude code cli directly, or code that uses the Anthropic agent SDK, or can I just use the Claude app as I have been? What's the best way to try this out?

**Answer in short:**
- Use the CLI headless (`claude -p`) in a shell loop on the box. That is the most faithful to the
  article, with sessions back to back.
- The app works with scheduled tasks that start a fresh session each time, but those run at most hourly.
- The Agent SDK is only worth it for custom control.
- Pilot on tonight's work rather than a toy.

## 2. Set it up

> Yes, set it up. But tidy up git first-- consider merging to main first, and then spinning up a new branch for the session tonight. Add key commands to the permissions allowlist, but we'll also use auto mode-- ensure we configure it to use that. Which models do you think we should use for the steps? I'm thinking Fable for the initializer, then sonnet/opus for the workers. What do you think?

**What came out:** harness v1 (`889f5fe`). The classifier blocked merging PR #2 and deleting
branches. A real headless call showed that untrusted folders ignore project allowlists.

## 3. Review

> What are best practices for people running loops like this, in terms of the following:
> * permissions (like allowing git merges / commits, and running other commands), to enable effective long running tasks? I'd like a more permissive approach-- allowing pushes to main, merges, and other actions-- only actions that truly removes history from git should be disallowed. Because my
> * The edit guard, like what you implemented. Is that a good idea-- as it completely stops the night's progress?
>
> Last, what are the commands to merge the PR from the cli? Also, explain each of the tmux commands so I know in detail how they work and what's happening when I run them.

> My thoughts:
>
> 1. I agree with your permissions> I removed the two 'git push origin main' and 'git push origin HEAD:main' commands from the user-level claude settings file. I also agree with the worktree-- lets make sure this is part of our harness approach & setup.
> 2. Which edit guard approach do you recommend, and why?
> 3. Can we add merges & branch cleanup into our harness workflow? if so, how do you recommend we go about this?
> 4. What are best practices for running remote controllable claude sessions within this harness framework we've been discussing? I want to be able to monitor progress as needed & clear blockers if they come up. Should I use tmux, or something else? Should I adjust my use of tmux?
> 5. Explain some questions I still have about the harness: where is the harness stored? When does init.sh run-- when is it called?
> 6. I want to make the easily reusable across different tasks. How should I go about this? For example, the harness should write it's session's progress to the particular project folder it's being used in rather than it-- so that multiple sessions using the same harness don't conflict.
>
> I need to make a resource: for my 'level up' interview at work, but in general as well: for my portfolio, future job apps & showing my work/progress to potential connections, etc-- I want to show my thought process around this project in addition to the deliverable. Consider how I can track the design & build process-- but most importantly, of my iteration on my meta-engineering of going from spec creation + subagent delegation (to preserve context after running into token limits when using Fable as a direct implementor/testor), to now true harness & loop engineering following best practices. How should we track this thinking, so that we can make a compelling resource out of it? How should we track the existing progress in my agent engineering & processes used to prompt the results thusfar? Let's also capture the original harness design you made as one iteration of thinking, and then this upgraded multi-session harness as a subsequent iteration, for the thought-process tracking.

**What came out:**
- harness v2 (`~/projects/agent-harness`, and Pathways `7d0c1eb`, PR #3);
- this journal;
- the evidence timeline and iteration drafts 00–02, reconstructed from git and docs by a subagent.
  Its first attempt was blocked from reading Claude transcripts, so it used repo evidence only.
