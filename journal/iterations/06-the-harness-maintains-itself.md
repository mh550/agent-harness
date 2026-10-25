# Iteration 6 — The harness maintains itself: discovery, root causes, a cleanup that fixes the cause

**Dates:** 2026-10-23 → 2026-10-25 (`~/projects/agent-harness` PRs #11–#16; catch-up PRs in all seven project repos).
**Sessions:** about fifteen interactive sessions over 28 hours (10-23 21:43 → 10-25 01:05 EDT).
[`sessions/2026-10-24-harness-catchup.md`](../sessions/2026-10-24-harness-catchup.md) has my messages verbatim and
what came out of each.

## Context
A week of harness v3 (iteration 5) ran **22 runs, 2026-10-17 → 10-24, for $1,941.70**. The runs passed 520 features
and added 5,595 tests (`ledger/runs.jsonl`). The harness worked as a builder, but the system around it was
silting up:
- **Only 224 of the 520 passing features were merged.** The rest sat on branches and in stacked PRs, waiting for me.
- **The harness wasn't learning.** Its own improvement work never ran. Retros proposed "cap the per-milestone
  review" **9 times** (17–31 % of each run's cost), and it was never built. The specs that would fix it were queued,
  then hand-moved into `queue/held/`, a folder the runner never reads. For three days the queue reported "empty".
- **The live checkout was 109 commits behind `origin/main`.** E1–E4, merged as PR #10, never ran, and 14 ledger
  commits sat on the checkout unpushed.
- **The box ran out of memory 10 times in a week** (Oct 19: 1, Oct 23: 4, Oct 24: 5). The boot "hung" for a minute
  deleting **~1.07 M leaked files** from `/tmp`. `~/worktrees` held 7.3 GB, 6.6 GB of it `node_modules`, `.next` and
  `.venv`.
- **One deny rule killed a run.** n8n-home died at **0/32 features for $10.82**: its project settings denied
  `docker compose`, which its own first feature needed.
- **Permissions had sprawled to 404 project rules** (177 allows, 227 denies) across seven repos, plus 54 user-level
  rules. Many of them blocked the cleanup I wanted done: `git branch -D`, `git worktree remove`,
  `git push --delete`.

## Trigger
It started as everyday friction. Each discovery session began with a short question of mine and ended in a findings
file, not a fix. Times are EDT; the full sequence is in the [session record](../sessions/2026-10-24-harness-catchup.md).
1. **10-23 21:43, "The harness has run. What are my todos now?"** → n8n-home had stopped at 0/32 on a project-level
   `docker compose` deny. I asked to "relax the denylist in your approach so future sessions can make changes to the
   docker setup as needed".
2. **10-24 00:42, "how do I handle the 10 open pull requests for hit list… Maybe we just allow merges"** → one
   stacked merge for all ten milestones. Per-milestone PRs for a project with no production were pure overhead.
3. **The OOM at 00:49 on 10-24** (run `rane-one-mixxx-2026-10-24`, M5-02), asked about three minutes in →
   `findings-and-research/2026-10-24-oom-from-unbounded-test-diff.md`. Cause: a red-phase test ran `assert.deepEqual`
   on two large unequal arrays, Node built a ~7 GB diff, and the session re-ran it three more times. Nothing bounds a
   session's memory.
4. **11:52, "What is the state of the harness-improvement runs? What's blocked? What's not?"** → one run done, the
   follow-ons never ran, n8n blocked at 0/32.
5. **12:30, the boot "hang" and the ~5 GB a reboot gave back** ("6 python instances all using like half a
   gigabyte… a bunch of `2.1.310` instances") → `findings-and-research/2026-10-24-system-resource-audit.md`.
   Finding: *"leaked by design gaps, not by a single bug. The harness never stops what a run starts."* The audit
   couldn't be saved to the folder I named: the background job was blocked from the live checkout, so it sat
   uncommitted in a worktree.
6. **12:39, procedurize the memory field guide "without adding bloat"** → `docs/specs/2026-10-24-memory-model.md`,
   also on a branch.

The turn came at 12:55. I didn't ask for fixes. I gave four hypotheses of my own (retros in the wrong
place, worktrees blocking writes, permissions too restrictive, memory sprawl) and asked for the meta issue behind
them ([prompt](../evidence/prompts/2026-10-24-four-meta-issues.md)).

## Root causes (the diagnosis)
The session's answer, which I adopted: **"almost nothing reaches main, or the running harness, unless you carry it
there by hand."** My four points were four symptoms of that:

| Symptom I saw | Root cause | Evidence |
|---|---|---|
| Retros pile up and the harness doesn't improve | A retro is episodic (one run) but its proposals are semantic (true across runs). They had no shared store, so nothing turned them into work. | the same proposal in 9 retros; the debrief read the newest 20 as raw text and was cut off before three of them |
| Worktrees "block" writing to the harness folder | Isolation was right, but the **last step was missing**: nothing merged work back out of worktrees. | 5 branches in `.claude/worktrees/`; the resource audit uncommitted in one |
| Permissions stop runs | Policy lived in about 12 places: user settings, seven project files, CLAUDE.md prose, briefs and prompts. **A deny anywhere beats an allow anywhere.** | n8n: user file allowed `docker compose`, project file denied it → 0/32 |
| Memory and resources balloon | **Nothing stopped what a run started** (dev servers, tmux, scratch, Supabase), and facts were written to the wrong store (night scope in CLAUDE.md, gotchas in run folders). | `next-server` surviving 2–5 days; Supabase up 15 h, `supabase_db` recreated 149×; 10 OOM kills |

The over-restrictive policy wasn't neutral either. I had denied branch and worktree deletion to be safe, and those
denies are what produced the branch and worktree sprawl.

## Design: fix it once by hand, then change the harness so it can't recur
| Problem | Manual cleanup (once) | Harness / policy change (so it doesn't recur) | Status |
|---|---|---|---|
| Stranded work on branches | PR #11: the 14 ledger commits, the audit, the OOM finding and the specs merged to main | Sessions merge their own green PRs; user policy: "finish in your worktree, then merge to `main` yourself" | done (PR #11, #12) |
| Live harness 109 commits behind | fast-forwarded by hand | `lib/sync.sh`: the queue runner levels the checkout with origin before each start, only when no run is alive (bash reads scripts while running them) | done (PR #12, `decisions/2026-10-24-close-the-loop`) |
| Runs parked where nothing shows them | the three held entries listed | `harness queue park/unpark`, parked entries and their reasons in `queue list` | done (PR #12) |
| Permission sprawl | one catch-up session per project trimmed its settings and prose: **404 → 51 project rules**, four repos with no settings file at all | One policy home (`~/.claude/CLAUDE.md` § "Git, merges and permissions"); deny only what can't be undone; templates + `setup/apply-2026-10-24.sh`; the project templates no longer ask for restated policy | done (PRs #13–#16; every project's catch-up PR) |
| Resource leaks | stopped voice-concierge's 8 idle workers, deleted finished background jobs, zram 50 %, reboot | `docs/specs/2026-10-25-resource-lifecycle.md`: one memory-capped systemd scope per session and per run's services, stopped on any end; scratch cleanup; `gc --deps` | **planned** (handoff chunk 4) |
| Retros live in run folders | none | Memory spec §E: the driver promotes each retro proposal into **one deduplicated, status-tracked backlog in the harness repo**, and the debrief and new specs read that, not 20 raw retros | **planned** (chunk 4) |
| One given-up feature ends a run | — | R10: skip to every feature that doesn't depend on it; R3: lint feature steps against the settings at init (it would have caught n8n in its first minute) | **planned** (chunk 4) |
| Project memory sprawl | catch-up Part 2 per project (one decisions file, night scope out, gotchas promoted) | memory-model K1–K3: one routing block, gotchas in place, `memlint` | **planned** (Part 2, chunk 4) |

**Order mattered.** Step 1 saved the stranded work and synced the live checkout, so every later fix built on real
current code. The permissions policy came before the per-project cleanup, because the old denies would have blocked
the cleanup itself. Resource caps come before longer and more permissive runs.

## How the work was driven (the method)
- **Chunks sized to one context window.** The plan, `docs/plans/2026-10-24-handoff.md`, is the to-do list. Each
  chunk is one fresh session with a stated limit and a stopping point ("do one chunk, report, and stop"). I asked for
  this explicitly ([prompt](../evidence/prompts/2026-10-24-chunked-handoff.md)).
- **Agent chunks and my chunks.** Agents can't use `sudo` or edit `~/.claude`. Those steps became a 15-minute chunk
  for me, and the agents write the script I run (`--dry-run` first).
- **One worker per project, launched by me, rather than subagents or harness runs.** Three reasons:
  - Subagents can't ask me anything, and a production merge needs my answer.
  - A session in the project's own directory loads that project's rules.
  - A harness run spends $10+ planning before it merges anything.

  Every worker gets the same prompt (`prompts/project-catchup.md`) and runs one part only.
- **Iterate on the prompt, not the output.** The first two workers (n8n-home, rane-one-mixxx) each needed a second
  prompt from me to remove redundancy ([prompt](../evidence/prompts/2026-10-24-redundancy-sweep.md)). I asked a fresh
  session how to continue ([prompt](../evidence/prompts/2026-10-25-fix-the-prompt.md)). It found the gap: the prompt
  said "reduce" without a test for what stays, and it ignored the policy restated in CLAUDE.md prose. Its fix:
  - a written test for when a deny or an allow stays;
  - the run-log query that shows what runs were actually refused;
  - each project's exact target, precomputed in its handoff row.

  **The next five projects then finished Part 1 within 40 minutes, with no second prompt about settings** (PRs
  00:22–00:59 EDT on 10-25). My other messages to them were go-aheads, such as deleting a branch or confirming a
  merge.
  - pathways I paused once (00:28), because four workers running at once pushed memory too high. That's one more
    than the handoff's limit of three, so it was the resource problem again, caused by me.
  - dj-crate-streaming's worker gave me a `harness gc --all-merged` that skipped every `harness/*` branch, and
    caught its own mistake when I pasted the leftovers.
- **Evidence before rules.** Every harness run's `permission_denials` showed that no denial ever fell on a command the
  long project allow lists covered. Those 177 allows had done nothing.

## Evidence
- Harness PRs (merge times EDT): #11 (stranded work, 13:12) · #12 (close the loop, suite **236/236**, 13:39) · #13
  (policy templates and apply script, 15:44) · #14 (dj-crate-streaming live, 16:35) · #15 (policy from the n8n-home
  catch-up, 23:32) on 10-24; #16 (one-pass catch-up prompt, 00:14) on 10-25.
- Catch-up PRs: n8n-home #3 (17:06), #4 (22:42) and rane-one-mixxx #6 (17:01), #7 (22:47) on 10-24, two rounds each.
  Then, after #16, one round each between 00:22 and 00:59 on 10-25:
  - voice-concierge #15, #16;
  - dj-crate-streaming #23–#32 (eight verified milestone PRs merged in order, then the go-live settings);
  - hit_list #19, #20;
  - pathways #14, #15;
  - portfolio_site #29.
- Permission rules, before → after:

  | Scope | Before (allow/deny) | After (allow/deny) |
  |---|---|---|
  | user `~/.claude/settings.json` | 34 / 20 | 6 / 34 (allows: git, gh pr, npm, node, harness, docker compose; denies: a closed list of irreversible actions and secrets) |
  | n8n-home | 52 / 82 | 22 / 5 (live-staged protocol + n8n MCP reads) |
  | rane-one-mixxx | 37 / 43 | 3 / 7 (hardware gate) |
  | voice-concierge | 30 / 37 | no file |
  | pathways | 28 / 29 | no file |
  | portfolio_site | 30 / 36 | 0 / 7 (deploy gate) |
  | dj-crate-streaming | no file | 5 / 2 (live protocol) |
  | hit_list | no file | no file |
  | **projects total** | **404** | **51** |

- **What runs were actually refused**, from every run's `permission_denials`:
  - reads of other projects;
  - Python heredoc file edits;
  - a `docker exec … printenv` (correctly refused: it prints secrets);
  - a `docker compose ps` blocked by dj's old project deny.

  None of them involved a project allow-list entry.
- Box after chunk 2: no tmux server, voice-concierge stopped, zram at 50 % (reboot 16:51 on 10-24). Claude Code's
  pre-warmed `bg-spare` sessions came back within a day (9 processes on 10-25). Capping them is resource-lifecycle
  work, not a one-time cleanup.

## What worked / what broke
- **Worked:** asking for the root pattern rather than four fixes; findings as merged files rather than chat; a plan
  file that sessions tick on `main`; me launching the per-project workers; measuring the prompt by how many follow-ups
  it needed.
- **Broke, then fixed:**
  - My own safety policy was the cause of the sprawl. Denying `branch -D` and `worktree remove` kept agents from
    cleaning up after themselves.
  - The docs check of 10-24 said narrow allows were needed for auto mode. A recheck the same night showed
    `Bash(git:*)` already covers them, because an allow skips the classifier whatever its specificity. The user file
    lost the narrow copies.
  - The first catch-up prompt said "reduce" without a test, so every worker invented its own and needed a second
    round.
  - The worktree guard refused a script that only *mentioned* `git` in a heredoc. The fix was writing the script to
    a file first.
- **Still open:** the resource scopes, the harness-level retro backlog and R10 are specs (chunk 4), not code yet.
  Part 2 (memory tidy) hasn't run in any project.

## Led to
- Chunk 4: three specs queued in order. First resource lifecycle, then the retro fixes plus R10, then memory: the
  harness's own backlog, so retros' proposals land in the harness repo, not in run folders.
- Chunk 5: start the queue. The runner syncs the live checkout before each start, and verified milestones
  self-merge (`MERGE_POLICY=auto`) everywhere except portfolio_site.

## How to tell it (2 minutes)
1. **Problem:** a week of agent runs passed 520 features, but fewer than half reached `main`, the box ran out of
   memory 10 times, and one deny rule killed a run at 0/32.
2. **Diagnosis:** I came with four hypotheses and asked for the pattern behind them. The answer: every handoff waited
   on a human, and policy lived in 12 places where one deny overrides everything.
3. **Fix the cause, not just the mess:** clean up once by hand, and in the same change make the harness keep itself
   clean (auto-sync, visible parking, self-merge, one policy home).
4. **Drive it like a system:** context-sized chunks, a plan file as shared memory, one worker per project. I improved
   the *prompt* until each project took one pass: 404 → 51 permission rules, five projects in 40 minutes.
