# 2026-10-23 → 10-25 — from "where are we?" to a harness that cleans up after itself (many sessions)

Iteration 6 wasn't one conversation. It was about fifteen interactive sessions over 28 hours: discovery sessions that
each ended in a findings file, one long diagnosis session, then plan chunks and one catch-up worker per project. Below
are my messages verbatim, in order, each with what came out of it. Times are EDT.

Source: Claude Code transcripts under `~/.claude/projects/` (extracted with `jq`: human `type: "user"` lines only,
harness sessions and subagents excluded) and the terminal export
`~/projects/2026-10-24-233454-what-is-the-state-of-the-harness-improvement-rela.txt`. Long pasted logs are summarised
in brackets.

## 1. Discovery: what is actually wrong?

**10-23 21:43–22:28, `~/projects`: a run blocked by one deny.**
> The harness has run. What are my todos now, given that?

> Where is the project settings.json you speak of? I checked the user-level settings.json and didn't see the deny
> entry for the docker compose action. You can go ahead with the settings fix-- but I'd like you to relax the denylist
> in your approach so future sessions can make changes to the docker setup as needed.

> I'd like sessions to be able to deploy too, yes. I merged the pr. how should i proceed.

→ n8n-home was stopped at 0/32 by its *project* file's `docker compose` deny. That led to n8n-home PR #1 (allow
`docker compose`, guard only the live instance) and PR #2 (live-staged: sessions may deploy).

**10-23 22:33, `~/projects`: lost across projects.**
> I'm a bit lost with where we're at across our projects that the harness has been running. Review the current state-
> what's been done recently, what landed in the debrief. Note especially the harness itself-- I know we've had 3
> different runs queued there. I need to know what I should do next, specifically to review the work that's been done,
> clear up blockers, etc. What's the overall process for this currently? As you explain things-- you're explanation
> should be technical-- befitting of a software engineer & solutions architect, but it should be tailored to someone
> not familiar with the internal implementator details-- like acronyms, internal labels like 'D16' and 'R13', etc.
> Make it clear and easy to follow.

→ "dj runs S1–S4 (PRs #27–30) and the SoulSync review (#23–26) are done but unmerged."

**10-24 00:42, hit_list: PR sprawl.**
> Ok, now how do I handle the 10 open pull requests for hit list. This is a lot-- consider our current design, and how
> we should proceed. Is there a better way to do this then a separate PR per milestone? If I'm just reviewing the
> overall output, maybe we consolidate them? Maybe we just allow merges, especially for projects like hit_list with no
> production? Even for those with prod, grouping changes into a single PR seems to make sense, as I'd just be reviewing
> one output instead of multiple. Consider how we should proceed for hitlist. I give you permission to go ahead and
> handle the PRs as you see fit.

→ PR #18 (S10, all ten milestones stacked) was merged after checks, and #9–#17 closed as merged with it.
Recommendation: "one PR per run, or direct merges for no-prod projects."

**10-24 00:52, `~/projects`: the OOM, as it happened.**
> The harness, over the last 3 minutes, started hitting max RAM values, given we have a static 10GB of ram used, and a
> 6gb node instance was spawning up and consuming the rest of the memory. Why was this happening? How should we adjust
> our harness to ensure our system resources are preserved in the future?

At 11:57:
> Write these findings to a markdown document, explaining the issue that came up, the root cause, and recommended next
> steps. Put it in @agent-harness/findings-and-research .

→ "Four ~7 GB OOM kills came from a failing `assert.deepEqual` on large arrays in the M5-02 session's test. The harness
has no per-session memory cap." The document ended up on branch `worktree-oom-findings`, not in the folder I named.

**10-24 12:30, `~`: the boot hang and the leftover memory.**
> On my last boot, the first one hung up on the pop os splash screen. I waited 2 minutes, then shut it down. Then, i
> restarted and pressed space to see the pop os logs. The log contents can be seen in the image
> `~/Downloads/boot-logs.webp`. Also, my system resources cleared greatly during the restart. we cleared like 5gb of
> ram. I know that there were orphaned Next.js servers running, probably from testing. There were also many other
> little processes running.
>
> But, I want to understand where the remaining ram usage is coming from-- I see 6 python instances all using like
> half a gigabyte each. I don't think the harness is running, so this is confusing to me. There's also a bunch of
> `2.1.310` instances-- which I thought were claude code instances, but I only have 2 instance of claude code open.
> Additionally, there was a 1gb instance of the claude code URL handler that was using memory for a while.
>
> Your task is to consider this information-- and the context that created it: the server had been running for a
> week, through near-constant harness runs (see `~/project/agent-harness` for the source code, and use the `harness`
> cli command from it to see richer information about recent runs). You should do a thorough system resources usage
> audit, as it relates to both the recent agent harness runs that created the high-usage conditions before the
> restart, and the latent processes that are still running after my restart. Make a writeup that discusses the root
> cause of the issues, what created those conditions as it relates to the harness, containers, and other running
> processes n the machine, and you're recommended next steps in order to improve the issues going forward-- reducing
> the memory footprint in the short term and ensuring garbage collection & a clean memory footprint as the server runs
> its images & coding agents. Also reducing the usage of other system resources as well.
>
> The output should be a clear, concise, actionable writeup in markdown in `~/project/agent-harness/findings-and-research`.

→ `2026-10-24-system-resource-audit.md`. It could not be written where I asked: "This background job is blocked from
writing into your live harness checkout, so the doc is in a git worktree … I couldn't commit or push it."

**10-24 12:39, agent-harness: memory as a model, not a pile.**
> In @./findings-and-research/"Agent Memory Field Guide.md", we detail an approach to memory outlined from psychology.
> I'd like you to take those findings, and consider how we can procedurize these findings on memory to ensure that 1)
> our current projects are adhering to that model of memory , and 2) when claude is generating new content, it
> utilizes those memory concepts and stores information in the appropriate way, given that. We should enable this
> without adding bloat. Consider this also in relation to the most recent issues & improvements we've been considering
> for our harness, which can be found in @findings-and-research as well-- as well as our next queued up runs in the
> harness for harness self-improvement.

→ `docs/specs/2026-10-24-memory-model.md` (K1–K4), on a branch.

## 2. Diagnosis: one pattern behind the symptoms

**10-24 11:52, `~/projects`.**
> What is the state of the harness-improvement-related harness runs that have been recently done in the harness?
> What's blocked? What's not?

→ "Only the measure run (29/29, E4 as PR #10) of the harness-improvement runs completed; the R1–R9 retro-fixes and
the follow-ups specs never ran, and n8n-home is blocked at 0/32 on a denied docker compose permission."

**10-24 12:55: [the four meta issues](../evidence/prompts/2026-10-24-four-meta-issues.md)** (retros in the wrong
place, worktrees blocking writes, permission sprawl, memory).
→ "almost nothing reaches main, or the running harness, unless you carry it there by hand", and a six-step path.

**10-24 13:04–13:26: [go ahead; chunk it; a worker per project](../evidence/prompts/2026-10-24-chunked-handoff.md).**
→ PR #11 (stranded work saved, 13:12), PR #12 (close the loop, 13:39), and `docs/plans/2026-10-24-handoff.md` with
five chunks and `prompts/project-catchup.md`.

## 3. The plan, one chunk per session

**10-24 15:31, agent-harness: chunk 1.**
> Read docs/plans/2026-10-24-handoff.md and do Chunk 1 only, within its limits. Stop at its report.

→ PR #13: the policy templates and `setup/apply-2026-10-24.sh` (`--dry-run` first).

**10-24 16:03 and 16:26: questioning the agent's choices before living with them.**
> 3. Why do we still have denies on the 'git push' actions? In fact, give me the reasoning for each of the items in
> the denylist, in the context of what I've conveyed in the document and in this conversation about what my preferred
> permissions setup for these projects is.

> 1. I'd actually like dj project to be live again-- auto merges, accepting permissions to deploy & make update in
> docker, etc. What should be adjusted to support that?
> […] For the repo-specific changes, I'm not sure how we should make them. Chunk 3 of the original document with your
> instructions is a 1-by-1 cleanup of each repository. Maybe these steps should be added to that process. Look at the
> whole roadmap for the changes outlined in that doc, and make a decision on how we should proceed.

→ PR #14: dj-crate-streaming goes live. Its settings file and the other repo changes became part of each
project's chunk 3 worker, not a separate pass.

**Chunk 2 (me, no agent).** I ran the apply script with `--dry-run`, then for real. I also stopped voice-concierge's
worker, deleted finished background jobs, set zram to 50 % and rebooted (16:51).

## 4. Catch-up workers, and fixing the prompt they ran on

**10-24 16:57–16:58: n8n-home and rane-one-mixxx, Part 1** (catch-up prompt v1, 6,156 characters). rane-one-mixxx
trimmed its settings once (#6), and n8n-home committed its `.mcp.json` (#3). Neither file came out lean.

**10-24 22:38 and 22:44: [the redundancy sweep](../evidence/prompts/2026-10-24-redundancy-sweep.md)**, a second
prompt to each worker. → n8n-home #4 (52 allows / 82 denies → 22 / 5), rane-one-mixxx #7 (→ 3 / 7).

**10-24 23:13–23:27, n8n-home: why each deny.**
> Explain why these are on the denylist:
> - `git filter-branch` / `filter-repo`, `git reflog expire` / `reflog delete`, `git gc --prune`
>
> Should we have something on the user-level denylist to protect against `rm -rf` at something critical like my
> root folder, if we don't have that already?

> Read the policy sources in the agent-harness templates that need adjusting. Write a copy of your recommended changes
> somewhere you're able to, in the projects repo, for me to review & manually copy over the changes you recommend as I
> see fit.

> Can you give me a script to make the edits, in place, without manual work for me to do? And then the commands I need
> to run? I reviewed your edits in the terminal here

→ `~/projects/proposals/2026-10-24-harness-policy/apply.sh`. It produced harness PR #15 (23:32): the templates
synced, the `rm -r /srv` and docker-prune denies, and the note that Claude Code never auto-approves `rm` of `/` or
`~`.

**10-24 23:50 → 10-25 00:14: [fix the prompt, not the output](../evidence/prompts/2026-10-25-fix-the-prompt.md).**
→ PR #16: catch-up prompt v2 (8,746 characters). It adds a test for when a deny or an allow stays, the run-log
denial query, and each project's target in its handoff row. The user templates gain the secrets denies and the
"Other projects" and "Harness commands" bullets.

**10-25 00:21–00:59: five projects, Part 1, prompt v2.** None needed a second prompt about settings. My remaining
messages were go-aheads and checks:
- voice-concierge: no follow-up at all.
- hit_list: "Yes, you can delete the laptop-2026-10-13 one."
- pathways: "Continue. I interrupted you because system resources were high from running too many agents in parallel.
  That is now resolved." It was the resource problem again, this time from my own parallel workers.
- dj-crate-streaming: "i merged. What are the full harness commands, and the commands for cleanup, checkout, etc."
  Then I pasted 14 local and about 24 remote branches still there. The worker's own diagnosis: "I told you to run
  `harness gc` with `--all-merged`, and that flag actually skips every `harness/*` and `harness-merge/*` branch." It
  ended with only `main`.
- portfolio_site: "Here's the results of those commands. Anything else I should do/address?" `harness gc` had deleted
  29 remote branches and `git push --delete` six more. → "chunk 3 Part 1 is done for every project."

**10-25 01:05: this record.**
> Ok, great. I did that. Now, let's make sure we're logging this process- the discovery prompts (looking into the
> worktree bloat, branch sprawl, processes left orphaned, ballooning memory sprawl, etc), identifying the root causes,
> and then performing manual cleanup that also fixes the harness itself going forward to prevent issues from recurring
> (debrief changes land on the harness folder level instead of laying in run folders, etc). Append information to make
> the narrative and process clear. Put that process in the appropriate spot in the projects folder-- i know we put a
> subfolder somewhere to track this. What I'm tracking is documentation regarding my own meta development process, so
> I can share my findings with my team to present at my apprentice levelup interview.

→ [Iteration 6](../iterations/06-the-harness-maintains-itself.md), this file, four prompt files and the timeline
rows.
