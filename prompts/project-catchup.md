<!-- Michael runs one of these per project, in that project's own directory, so its CLAUDE.md and settings load:
       cd ~/projects/<project> && claude "$(cat ~/projects/agent-harness/prompts/project-catchup.md) Part 1."
     then, in a fresh session once Part 1 is reported:
       cd ~/projects/<project> && claude "$(cat ~/projects/agent-harness/prompts/project-catchup.md) Part 2."
     At most three projects at a time (the box has 15.5 GB; suites and hit_list's Supabase stack are heavy). -->
# Bring this project up to the 2026-10-24 model

You are catching one project up: everything verified gets merged, leftovers get cleaned up, and its memory files are
brought in line. You are **not** building features, starting harness runs or deploying anything. The plan and this
project's starting facts are in `~/projects/agent-harness/docs/plans/2026-10-24-handoff.md`. Read its "Policy" section
and this project's row in "Project catch-up" first. The row was true on 2026-10-24, so check every fact against the
live state before you act on it.

**Ground rules**
- **Git:** you may merge PRs (`gh pr merge --merge`), push branches, and delete branches and worktrees that are merged
  or whose work is on `main`. You may never force-push, rewrite `main`, or delete anything unmerged without saying
  what it holds and getting Michael's yes.
- **Production gates:**
  - **portfolio_site:** `main` deploys to production through Vercel. List each PR with its preview URL and what to
    check, then wait for Michael's go before merging anything into `main`.
  - **n8n-home:** a live project (live-staged since 2026-10-24). This catch-up deploys nothing and writes nothing
    under `/srv`; merging code is fine.
  - **dj-crate-streaming:** a live project (live-staged). This catch-up deploys nothing and writes nothing live;
    it sets up the live permissions as the handoff's "dj-crate-streaming goes live" section says.
  - Every other project has no gate.
- **Harness:** what `~/.claude/CLAUDE.md` allows (the read commands, `sync`, and `gc` on this project), never
  starting or steering a run. A run that is waiting on Michael gets its question quoted in your report.
- **Questions:** ask Michael only when a choice is genuinely his: a production merge, deleting unmerged work, an
  ID collision with no obvious answer. Otherwise take the conservative default and say which one you took.

## Part 1: merges and cleanup (stop after the report)

1. **Inventory.** List:
   - open PRs (`gh pr list`), with their base, mergeability and whether they are stacked;
   - `harness status` for this project's runs;
   - `git worktree list`, plus `~/worktrees/<project>/*`;
   - local and remote branches not merged into `main`.

   For each item, say what it is and what you will do.
2. **Merge** the verified PRs in the order the handoff row gives (stacked ones bottom-up). Rebase or fix conflicts on
   the PR branch, never on `main`. Run the project's suite on `main` after the merges.
   - If it's red, fix it on a branch and merge that fix too.
   - If you can't fix it, stop merging and report.
3. **Clean up:**
   - Run `harness gc ~/projects/<project>`.
   - Remove worktrees whose branch is merged. Delete build output first, such as `.next/`, `node_modules` and `.venv`,
     since it's what blocks `gc`.
   - Delete merged branches, locally and on origin.
   - Kill stale `h-<run>` tmux sessions of ended runs.
   - Stop any service a run left up (dev servers, `npx supabase stop`, test containers).
4. **Policy trim: settings and prose.** This project states only what is its own. Everything else lives in
   `~/.claude/settings.json` and `~/.claude/CLAUDE.md` § "Git, merges and permissions". The handoff row's
   "Policy trim" gives the target; check it against the live files and the run logs, then apply it.
   - **How the rules combine** (Claude Code docs, checked 2026-10-24):
     - Denies from every scope merge, and a deny anywhere beats an allow anywhere. A project deny of something the
       user file allows (`git branch -D`, `git worktree remove`, `docker compose`) silently overrides it.
     - In auto mode an allow skips the classifier, whatever its specificity: `Bash(git:*)` and `Bash(gh pr:*)` already
       cover every narrower git and PR allow. Wildcarded interpreter allows (`Bash(python3:*)`) are dropped.
     - Auto mode approves edits in the working directory and read-only commands with no rule, and ignores
       `defaultMode` in a project file.
     - A `Read(...)` deny also blocks `cat` and `sed` on that file, and an `Edit(...)` rule also covers `Write`.
   - **A deny stays only if** the action can't be undone, reaches production or a live system, or touches hardware,
     and the user file doesn't already deny it. Spending API credit, restarting a service or changing a reversible
     setting is one `CLAUDE.md` line at most.
   - **An allow stays only if** the command acts outside the repo or the classifier could block it, and a run
     needed it. What runs were actually refused:

         cat ~/.local/state/harness/<project>/*/logs/*.jsonl | jq -rR 'fromjson? | select(.type=="result")
           | .permission_denials[]? | "\(.tool_name) \((.tool_input.command // .tool_input.file_path // "")[0:100])"'
           | sort | uniq -c | sort -rn

   - **Prose.** In `CLAUDE.md` (`## Off-limits`, ground rules) and `.harness/project.md`, keep the project's own gates:
     the live protocol, hardware, production deploys, public-repo rules. Delete lines that restate the user policy
     (secrets, `sudo`, force-push, merging), "other checkouts are off-limits" and "never run `harness` commands" (the
     user `CLAUDE.md` says both now), and bans tied to a night or a run that has ended.
   - **Files.** A project left with no rules loses `.claude/settings.json` (`git rm`), plus an `AGENT_SETTINGS=` line
     in `.harness/config.sh` that only repeats the default; the driver then runs on user settings alone. `.claude/` is
     a protected path, so auto mode may refuse the change: if it does, put the exact change in your report for Michael.
   - Set `MERGE_POLICY` in `.harness/config.sh` as the Policy section's "Harness merges" says.
   - Report it as a table, `Rule | Why it stays`, then the dropped rules grouped by reason, then any change you'd
     recommend to the user files (don't edit `~/.claude` yourself).

   Commit, push and merge this as its own PR (portfolio_site: open it, and Michael merges).
5. **Pull** the local checkout `~/projects/<project>` to `main` (fast-forward), unless it has uncommitted work. In that
   case, say so and leave it.
6. **Report** in under 25 lines:
   - what you merged (PR numbers);
   - what you deleted;
   - the suite result on `main`;
   - anything waiting on Michael, as exact commands or questions;
   - anything you left and why.

   Then stop. Part 2 is a fresh session.

## Part 2: memory and leaks (stop after the report)

Apply `~/projects/agent-harness/docs/specs/2026-10-24-memory-model.md` §K4 by hand. `memlint` isn't built yet, so use
the spec's audit table and this project's row as the to-do list. Work on a branch, commit in small steps, then open
and merge one PR.

1. **One decisions file** (`docs/decisions.md`, unless one exists), with the header that says it holds the current
   rule set, rewritten in place.
   - Gather the D-tables from the specs into it, keeping each ID.
   - Where IDs collide, prefix them with the source (`v2-D12`) and leave a one-line pointer in the old spec.
   - Rewrite overturned entries in place, adding an `Updated in place <date>: …` line.
2. **Night scope out of procedural files.** Move `OVERNIGHT.md`, `STATUS.md` and dated runbooks to `docs/runbooks/`.
   Delete "tonight / this run" lines from `CLAUDE.md` and `.harness/project.md`.
3. **No stored test counts** in `CLAUDE.md`, the README or the architecture docs.
4. **Gotchas.** A fact that appears in two or more `.harness/runs/*/progress.md` entries and is missing from `CLAUDE.md`
   becomes one line under `## Gotchas` (15 lines at most, each ending `(<run> <date>)`).
5. **CLAUDE.md** gets the spec's `## Where things go` block (K1 §1, in this project's terms; set `DECISIONS=` in
   `.harness/config.sh` if the decisions file isn't `docs/decisions.md`). Cut detail that the code already states.
   Apply Part 1 step 4's **Prose** rule too: n8n-home's and rane-one-mixxx's Part 1 ran before it, and their rows
   list what's left.
6. **This project's leak fixes** from the handoff row (temp dirs that tests never remove, `browser.close()` in a
   `finally`, idle worker counts, an init that leaves a server behind). Test-first where the project has a suite.
7. **Report** in under 20 lines, as in Part 1. Then stop.
