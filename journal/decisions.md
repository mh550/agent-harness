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

### D-H11 · Detect limits from the structured error, and test against the real message *(accepted 2026-10-17, built in v3)*
- **Problem:** D-H9's regex missed "You've hit your session limit"; 45 sessions were counted as failures in 6 min.
  The stub emitted a message I had guessed.
- **Options:** widen the regex · **read `api_error` / `api_error_status` / `terminal_reason` first, regex as fallback,
  never count a $0 ≤1-turn session, sleep until `resetsAt`, pause after 3 fast failures** · stop the run on any error.
- **Why:** structure doesn't change wording between releases; the $0 rule catches the next unknown error too.
  The stub replays a real result line captured on 10-17 ("fakes mirror the live API", ON2).

### D-H12 · One limit for all runs on the box *(accepted 2026-10-17, built in v3)*
- **Options:** run one project per night · **a shared `LIMIT_UNTIL` marker every driver honours, plus
  `harness start --after <run>`** · a token-bucket scheduler.
- **Why:** two runs spent the five-hour window in 2 h 49 min (10-17), three loops did the same on 10-14. The marker
  is 15 lines; a scheduler is a project.

### D-H13 · The end of a run is reported, not "verified" *(accepted 2026-10-17, built in v3)*
- **Choice:** tag `final` only when every milestone is verified; otherwise update the PR body with what is verified,
  what is on the branch unverified, and the tag to merge. Delete the two `run/*/final` tags from 10-17 (Michael).
- **Why:** the PR is the review surface; a label that says "verified" over unreviewed T4 code invites a bad merge.

### D-H14 · A failed milestone gate blocks later milestones *(accepted 2026-10-17, built in v3)*
- **Options:** keep going in array order (v2) · **skip features whose earlier milestone is given up or failed its
  review; mark it "needs Michael"** · stop the run.
- **Why:** with a real failure, T5 would have been built on unreviewed T4. Independent milestones can still opt out
  by having no dependency (a later milestone id with `"after": []`).

### D-H15 · Per-project configuration: conventions + one policy line + `CLAUDE.md` + a run brief *(accepted 2026-10-17, built in v3)*
- **Options:** keep `.harness/{config.sh,init.sh,project.md}` · initializer drafts `project.md` in the run ·
  reuse `CLAUDE.md` · policy profiles · move generic rules to `prompts/` · **all but the in-run draft, combined**.
- **Choice:** generic rules live in `prompts/`; check/smoke/init/port by convention; `POLICY=build-only|live-staged`
  appends a harness-owned protocol; durable facts (and a `## Live system` fact sheet) live in `CLAUDE.md`, which
  interactive sessions read too; "tonight's" scope goes in `harness start --brief`, recorded in the run record.
  `harness init` drafts a `CLAUDE.md` *before* a run for Michael to edit; it never writes settings.
- **Why:** ~150 lines per project had ~15 project-only lines; the one policy decision was buried in prose and
  came out contradictory on 10-17. An in-run draft would govern a night before anyone reviewed it.
- **Undo:** the driver still appends `.harness/project.md` if present.

### D-H16 · Live systems: staged live operations under a protocol, replacing D-H10's build-only nights *(accepted 2026-10-17, built in v3)*
- **Context:** Michael wants agents to operate dj live (backed up by git and nightly restic). D-H10 forbade it.
- **Choice:** `POLICY=live-staged`: preflight (check green, `sqlite3 .backup` snapshots, last restic run and running
  image noted), stages dry run → `--limit 5` → `--limit 50` → all with checks after each, stop and revert on the
  first problem, one writer (`flock`), deploy only via `scripts/deploy.sh` from the run's worktree with the previous
  image noted; still never Soulseek transfers, `/srv/incoming`, the amperfy account, secrets or history rewrites.
  Allow rules for the needed commands are Michael's to add (text in the evaluation).
- **Gate:** not before the trash-step fixes I1/I2 from the 10-17 review, and one attended run of the protocol.

### D-H17 · The harness merges each verified milestone into main itself *(accepted 2026-10-17, built in v3)*
- **Context:** D-H6 kept a human tap on every merge after the classifier refused an unreviewed push to `main`.
  After the first night Michael asked for merges to be handled by the harness, so mornings aren't a merge queue.
- **Options:** keep one whole-run PR for Michael (v2) · merge the run branch at the end · **one PR per verified
  milestone, created and merged by the driver, in milestone order** · GitHub auto-merge on a PR per run.
- **Choice:** a verified milestone's tag commit is pushed to `harness-merge/<run>-<m>`, a PR opened with the features
  and the verify evidence table, and merged with `--match-head-commit`. Main is merged into the run branch before
  each verify, so what was verified is what merges. Milestones merge strictly in order (a later tag contains the
  earlier commits); a conflict or refusal stops merging and notifies. `MERGE_POLICY=pr` restores the human tap.
- **Why it is still reviewed:** each merge has passed its own review feature (Opus reviewer on the milestone
  diff), an independent verify with one evidence row per step, and a green suite on the merged tree. The human
  review moved from "every merge" to "policy and permissions" (D-H15, D-H16).
- **Partial runs** stop being a choice between "merge as-is" and "run again": verified work is merged as it
  happens; the rest continues (D-H18).

### D-H18 · A queue, serial by default; continuations are queued, not started *(accepted 2026-10-17, built in v3)*
- **Options:** start runs by hand · parallel runs with a shared limit marker only · **a queue with
  `MAX_PARALLEL_RUNS` (default 1), an `--until` time, and the shared limit window**.
- **Why:** 10-17's two parallel runs spent the five-hour window in 2 h 49 min. Serial runs each get the whole
  window; queueing a night's work is one command per project. A run ending on time, sessions or limits queues
  its own continuation (fresh attempts, same branch); a blocked run does not.

### D-H19 · Every run is measured and retro'd into a ledger the harness learns from *(accepted 2026-10-17, built in v3)*
- **Choice:** the driver writes `summary.json` (automatic cause per non-passing feature), runs a read-only Sonnet
  retro (judgment causes + ≤ 3 proposed harness changes, noting repeats), and appends to `ledger/` in this repo.
  `harness trends` shows all runs; the initializer gets real feature durations as calibration.
- **Why:** the first night's evaluation took a human-directed session with six subagents. Most of it was
  mechanical (costs, causes, wall times) and is now computed; the judgment part is a $0.20 session per run.
  The human step that stays: turning repeated proposals into decisions here, test-first.

### D-H20 · Gating by dependency, with `after` for independent work *(accepted 2026-10-17, built in v3)*
- **Default:** a feature depends on every feature before it; a given-up feature blocks the rest and the run ends
  "blocked on X" (needs Michael). The initializer marks independent work with `after: [ids]`.
- **Why:** v2 moved from a failed T4 review straight to T5, which builds on T4 (D-H14). Conservative by default,
  explicit when it's safe to go on.

### D-H21 · Live writes and the nightly backup exclude each other *(accepted 2026-10-17)*
- **Finding:** the 03:30 restic job (03:39–03:41 on 10-17) ran inside both overnight runs. A live stage during the
  backup's file walk gives a snapshot of a half-applied stage; `snapshot-crates-db.sh` writes the same file a run
  would use as its restore point; navidrome.db is backed up as raw WAL files. Checked: a skipped backup exits 1,
  so `ExecMainStatus=0` means a snapshot was saved.
- **Choice:** (1) now, in the protocol: no live write 03:15–04:30 or while `restic-backup.service` is active;
  restore points named with the run id; (2) a shared lock, `LIVE_LOCK=/srv/docker/crates/live.lock`, which sessions
  take with `flock -n` (skip if busy) and the backup script holds while it snapshots and backs up (a 3-line root
  edit for Michael); (3) dj milestone H1: navidrome.db in the nightly snapshot, worker heartbeat, healthchecks.
- **Rejected:** moving the backup out of the night (the night is when the box is idle); triggering a backup from a
  run (needs root for agents).

### D-H22 · A debrief after every queue, triggered by the queue ending, not by a clock *(accepted 2026-10-17, built in v3)*
- **Finding:** the morning triage (status, retros, inbox, what to queue next) was done by hand in an interactive
  session. A fixed-time "morning session" was the first idea, but queues end at different times (06:10, 23:00), and
  a 07:30 session either runs too early or waits for nothing.
- **Choice:** the queue runner starts `harness debrief` detached as it exits (any path), if it started at least one
  run itself. A debrief covers every run since the last debrief that produced a note, so a refused, failed or
  killed debrief is covered by the next one. `harness debrief` by hand is the fallback.
- **Rejected:** a 09:00 fallback timer (Michael: "we shouldn't rely on the timer"). The review found it couldn't
  find node (nvm loads only in interactive shells) and raced the runner's own debrief. "Since the last successful
  debrief" makes it unnecessary. Also rejected: a queue entry at the end of the queue, which never runs if
  `--until` stops the queue first and would need re-adding every time.

### D-H23 · Debrief history is one file plus git *(accepted 2026-10-17, built in v3)*
- **Choice:** each debrief overwrites `ledger/debrief.md` and commits it. `git log -p ledger/debrief.md` is the
  archive. Michael reads one path, and there's no retention or gc code.
- **Rejected:** dated files keeping the last 3–5 (gc code for no benefit git doesn't already give); a file that
  isn't committed (loses history).

### D-H24 · The debrief's scope: read and report now; widen it along the "is there a gate?" line *(accepted 2026-10-17 for v1; widening proposed)*
- **v1 (now):** the debrief reads and reports. It writes only its note, and *proposes* continuations as
  `CONTINUE:` lines that bash checks (the run is this debrief's, ended on time or a limit, has work left, isn't
  queued or running) and queues with `--keep-attempts`. It never starts the queue. Enforced, not just prompted: the
  session runs in `dontAsk` mode with one commented `ALLOW` list in lib/debrief.sh, plus a deny list, and the git
  state of the ledger, run worktrees and projects is compared before and after, with any change flagged in the
  note.
- **Why strict first:** it runs unattended right after the queue, and nobody looks until morning. The first
  version (a deny list in auto mode) could still write via `sed -i`, `tee` or `git -C … push`. The scope was the
  evaluating session's choice, not Michael's, so this records it as the starting point, not a principle.
- **The principle for widening:** the line that matters is not read vs. write but whether a change passes a gate
  before it counts.
  - **Gated, so safe to allow later:** run branches. Anything written there must pass the suite and a verify
    session before it reaches main, so resolving merge conflicts and writing inbox answers there can be allowed.
  - **Ungated, so never:** main, the live server, policy/CLAUDE.md/permissions, starting runs or the queue (that
    spends the budget).
- **Proposed:** after about a week of reliable notes, widen `ALLOW` to run-branch writes (conflict resolution,
  inbox answers), test-first. Revisit if a note is ever wrong about what happened.
