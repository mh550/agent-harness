# Decision log — harness design

One entry per non-obvious choice: options considered, the choice, why, and how to undo it.
Pathways' product decisions (D1–D24) live in that repo's specs. These are the decisions about *how
agents are driven*.

### D-H1 · Fresh session per feature, not one long session (iteration 3)
- **Options:** one `/loop` session with compaction and handoff files (iterations 1–2) · an
  orchestrator plus subagents in one session (iteration 2) · **a new headless session per feature,
  with state on disk**.
- **Why:** every single-session approach eventually hits the context limit; subagents only delay
  it. Fresh sessions make context a constant, and force the state to be explicit (feature list,
  progress log, git).
- **Undo:** the runbooks still work with `/loop`.

### D-H2 · Models: Fable initializes, Opus builds, Sonnet verifies
- **Options:** one model for everything · **by role** · by feature.
- **Choice:** by role, with a per-feature override in the list. The initializer runs once and
  decides the night's quality, so it gets the strongest model (Fable 5.1). Code, UI and reviews
  get Opus 5.5. Docs and verification get Sonnet 5.5, which is cheaper.
- **Check:** `metrics.jsonl` gives $ and pass rate per model, so revisit after a few runs.

### D-H3 · Repair and continue, instead of stopping on feature-list edits
- **Options:** stop the night (v1) · trust the prompt · **revert the edit, keep the session's own
  `passes`, log it, continue; stop after 3 in a row**.
- **Why:** one bad edit should cost one commit, not a night. Repeated edits mean the prompt is
  wrong, and that is worth stopping for.

### D-H4 · Guard against false passes, not just edits
- **Options:** trust the session's `passes` · **un-pass on a red suite + an independent verify
  session per milestone (max 2 rounds)**.
- **Why:** the expensive failure is a feature marked done that isn't. A second agent re-running the
  steps cold is the cheapest independent check. The round cap stops coder/verifier ping-pong,
  which the stub test found.

### D-H5 · The driver does git bookkeeping; agents don't
- **Options:** agents merge and clean up (permissive settings) · **a deterministic driver** ·
  manual.
- **Why:** these operations must happen every time and in the same way: sync, push, tag, PR,
  cleanup. A script does that; a prompt might not. Agents keep permissive permissions for their
  own work, but the harness owns everything that touches shared branches.

### D-H6 · Merging into main: tag + PR per verified milestone (a human merges)
- **Options:** a fast-forward push to `main` after verification · **a PR per verified milestone** ·
  merge at the end of the night.
- **Why:** I wanted it automatic. The auto-mode classifier refused to let an agent build an
  unreviewed push to `main`. The PR keeps one human review per milestone, costs one tap, and
  carries the evidence (harness log, metrics).
- **Undo:** enable GitHub auto-merge on the repo, or set `PR_POLICY=off` and merge by hand.

### D-H7 · Isolation: a git worktree per run
- **Options:** run in my checkout (v1) · a clone per run · **a worktree per run**.
- **Why:** runs and I can work at the same time without touching each other's files. It shares one
  object store, so it's cheap. Each run gets its own branch, port and scratch directory. Permissions
  go in with `--settings`, because project settings are ignored in an untrusted fresh worktree.

### D-H8 · Permissions: allow broadly, deny only what destroys history
- **Choice:**
  - **Allow** git, gh pr, npm, node, edits and read-only shell tools.
  - **Deny** history-destroying commands: force pushes, remote branch deletes, `branch -D`, tag
    deletion, filter-branch/filter-repo, reflog expiry, gc prune and stash drops.
  - **Also deny** worktree removal by agents, `gh repo delete` and DELETE API calls, plus secrets
    and sudo.
- **Caveat:** deny rules match the start of the command text, so they are a speed bump. The real
  guarantees belong on GitHub: branch protection against force pushes and deletion, and a
  narrowly scoped token.

### D-H9 · A usage limit doesn't spend an attempt
- **Problem:** with 2 attempts per feature, a plan usage limit (seen on 10-14, when three loops ran
  at once) would make every session fail within seconds. The whole feature list would be "given
  up" within minutes.
- **Choice:** the driver reads each session's final result. A usage/rate limit or an outage (or no
  result within 2 minutes) gives the attempt back and backs off 15 → 30 → 60 min. After 6 hits in
  a row it pauses the run and notifies. Tested with a stub that hits the limit 3 times, and one that
  hits it forever.

### D-H10 · Live systems get build-only nights
- **Context:** dj-crate-streaming runs Michael's live music server. Its next items end in
  production operations: trash, repoint and tag writes on `/srv/music` and Navidrome.
- **Choice:**
  - unattended runs build and test against fakes only;
  - each item's live run is written as `docs/live-steps/…` for an attended session;
  - the suite runs sandboxed (`.harness/check.sh`: every path in scratch, credentials unset);
  - agent permissions deny docker, deploy, `/srv` and the live service ports;
  - the agent settings live in `.harness/agent-settings.json`, so interactive deploy sessions are unaffected.
- **Also:** dj's suite takes about 7 min. The driver caches a green result per code tree, so a
  session doesn't pay for the same check two or three times.
