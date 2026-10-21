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

### D-H25 · Milestones declare what they build on *(accepted 2026-10-19, built in v3.1)*
- **Finding:** three retros in a row asked to "block only on declared dependencies". On 10-17 dj's H3-04 waited on
  Michael, and N2–N5 (14 features) never ran behind it although none of them needed it. With no `after`, a feature
  depends on every feature before it, and the initializer had left `after` off.
- **Choice:** keep the safe default (unlisted means "everything before me"), but make the boundary explicit: the
  initializer must give the first feature of every milestone after the first an `after`, and `after` may name
  milestones (`"after": ["N1"]`). The driver notes once per run which milestones still have none.
- **Rejected:** "same milestone only" as the default (it would build M2 on an M1 that failed, with nothing saying so).

### D-H26 · A feature waiting on Michael parks; it doesn't spend attempts or stop independent work *(accepted 2026-10-19, built in v3.1)*
- **Finding:** H3-04 spent two sessions ($2.43) re-checking an INBOX answer that hadn't come, then counted as given
  up. Both 10-17 retros proposed parking.
- **Choice:** a session that can't go on without Michael ends its final message with `PARKED: <what it needs>`. The
  driver gives the attempt back and parks the feature (`state/parked.json`, keyed to a hash of INBOX.md from
  `## Answers` on). Parked features are skipped like given-up ones, so only what depends on them waits. Any change
  to the answers (the phone, `harness answer`) unparks them. When nothing else can run, the run ends
  `waiting on Michael: <ids>` (with `blocked on …` if a given-up feature is also in the way).
- **Rejected:** pausing the run until an answer arrives (it would hold the queue all night).

### D-H27 · The summary reads how the run ended, not guesses *(accepted 2026-10-19, built in v3.1)*
- **Finding:** both 10-17 summaries had the wrong end reason (pathways "session cap" for done; dj "no feature left
  to try" for blocked), and dj's N2–N5 were labelled "usage limit" from refusals two segments earlier. Cause:
  `finish` built summary.json before the exit trap wrote `state/ended`, so the summary fell back to fixed regexes
  over every segment's log lines.
- **Choice:** `finish` writes `ended` first. The fallback (older runs) is the log's last "run ended (…)" line. A
  refusal from an earlier segment is not the cause of a later ending unless that ending was the limit too.

### D-H28 · Budget the plan's 7-day window; the debrief is also a page *(accepted 2026-10-19, built in v3.1)*
- **Finding:** after 10-17 the 7-day window stood at 97%, leaving nothing for interactive work until it reset. Every
  session's stream carries `rate_limit_event.unifiedWindows.seven_day.utilization` (checked on the 10-18 run).
  jcode's overnight mode (evaluated 2026-10-19, not adopted) showed two ideas worth taking: a usage preflight and a
  generated review page.
- **Choice:** the driver records the newest session's 7-day figure box-wide (`state/USAGE_7D`). Past
  `WEEKLY_STOP_AT` (default 85%), the queue starts no run and a run ends `weekly budget (…)` before its next coding
  session (verifies of finished milestones still run). The debrief also writes `ledger/debrief.html`: one card per
  run built from summary.json (the numbers are the harness's, not the model's) above the note, committed with it;
  `DEBRIEF_PAGE_CMD` gets its path.
- **Rejected:** waiting for the 7-day reset inside a run (days, not minutes); the model writing the page's numbers.

### D-H29 · Notifications carry the question and the links; the harness posts to ntfy itself *(accepted 2026-10-19, built in P1 of run agent-harness-2026-10-19)*
- **Finding:** a park or a block reached Michael's phone as one line (`[<run>] needs Michael: B · <why>`). The
  question was in INBOX.md on the run branch, three taps and a branch switch away in the GitHub app, so answering
  from the phone meant finding the file first. `NOTIFY_CMD` got only `$1`, so it couldn't add a title, a priority or
  a link even when the driver knew them. A blocked run end also sent two notifications (`needs Michael: …` at
  once, then `ended (…)` after the merge, the suite and the retro).
- **Choice:** `lib/notify.sh`: `notify "<message>" [title= body= click= actions= priority= tags=]`, shared by the
  driver and the debrief. With `NTFY_URL` (and optional `NTFY_TOKEN`, a bearer header that is never logged) the
  harness posts to ntfy itself through `${HARNESS_CURL:-curl}` and `NOTIFY_CMD` is not called; otherwise
  `NOTIFY_CMD` gets `$1` exactly as before plus `HARNESS_NOTIFY_{TITLE,BODY,CLICK,ACTIONS,PRIORITY}`, so existing
  commands keep working. Pure helpers in `lib/notify.mjs` (`githubUrls`, `trimBody` at 3500 bytes, `actionsHeader`,
  `inboxQuestion`). A park is `[<run>] <id> needs you` at priority high: the PARKED line, the lines the session added
  to INBOX.md (the driver copies it before each coding session) and the `harness answer` command, with INBOX.md on
  GitHub as click and Edit INBOX / Answer with Claude (`DESK_URL`) / Progress as actions. Every other needs-Michael
  notification is high with a click (progress.md, harness-log.md or the PR). A run sends one end notification,
  `[<run>] ended: <reason>` with report.md as click, high plus Edit INBOX / Progress when Michael must act; the
  separate `needs Michael: blocked …` line is gone. Routine ones (started, merged, paused) keep the default
  priority. A non-GitHub origin gives no URLs; a failed post is a `notification failed (curl exit <n>)` note and the
  run goes on.
- **When the end notification goes:** `finish` writes report.md from the first summary, pushes it with
  `HARNESS: run ended (…)` and notifies right then, before the retro (minutes, and a crash there would lose it).
  The retro's summary rewrites report.md at the same URL. Verify and merge-conflict notifications likewise go out
  after the entry they link to is pushed.
- **Rejected:** keeping NOTIFY_CMD the only path and documenting an ntfy recipe (every user would rebuild header
  quoting, the token and the cap); calling both NTFY_URL and NOTIFY_CMD (two notifications for one event); the
  question in the title (a phone shows one line of it; the body holds 3500 bytes before ntfy.sh makes it an
  attachment).

### D-H30 · An answer desk: `harness parked`, the harness-answer skill, `DESK_URL` *(accepted 2026-10-19, built in P2 of run agent-harness-2026-10-19)*
- **Finding:** after D-H29 a park reached the phone with its question, but answering still meant knowing which runs
  were parked, which INBOX section belonged to which feature, and whether to `harness continue` or `harness queue add
  --continue` (a plain continue beside a queue runner races it for `MAX_PARALLEL_RUNS`). A Claude session opened from
  the phone had to rediscover all of that, and nothing told it what it must not do.
- **Choice:** `harness parked [<run>] [--json]`, read-only (no `harness_config`, no `mkdir`): one block per parked,
  not-passing feature, oldest first, with run, project, since, why, the feature's INBOX question, whether the run is
  going, and the exact next commands. A going run (`driver.pid` alive) gets only `harness answer`: its driver takes
  the answer before its next session and unparks by itself; a run whose driver is alive but has written `ended` (it is
  in `finish`, retro included: no next session) is `ending`, answered now and continued once it has ended; an ended
  run gets `harness queue add --continue` when `queue/runner.pid` is alive, else `harness continue`; a run with a
  continuation already queued (a session-cap end queues its own) gets only the answer. The question is the feature's
  newest `### <id>` section (a re-park asks below the answered one). Runs whose
  worktree was gc'd are skipped (nothing left to answer or continue). The logic is pure in `lib/parked.mjs`.
  `skills/harness-answer/SKILL.md`, shipped here and symlinked by Michael, tells an interactive session to run
  `harness parked`, check only what is safe (a variable's name, never its value; no `.env`, no sudo), propose, and run
  `harness answer` (his words through a quoted heredoc, never shell-expanded) and the continue only after his yes.
  `DESK_URL` (Michael's Remote Control environment URL) puts **Answer with Claude** on a park's notification.
  `templates/user/config.sh` documents the user settings, every line commented.
- **Rejected:** always printing a continue command (a second driver for a going run is refused, and would only
  confuse); listing gc'd runs with a "worktree gone" line (nothing can be done there; *default*, Michael may want it
  back); a skill that edits INBOX.md itself (the driver's merge of `harness answer` is the one writer besides the
  GitHub app); installing the skill into `~/.claude` from the harness (Michael's directory, CLAUDE.md rules).

### D-H31 · The desk starts itself: a Remote Control claude in tmux, one per run, the pane's URL as the click *(accepted 2026-10-19, built in P3 of run agent-harness-2026-10-19; DESK=0 until Michael has tried it)*
- **Finding:** after D-H30 answering from the phone still meant Michael opening a session himself (Answer with Claude
  → `DESK_URL`) and asking it what the harness needs; the session started cold. By hand on 2026-10-19 (CLI 2.1.303),
  `claude --remote-control "<name>"` in a tmux window prints `/remote-control is active · … at
  https://claude.ai/code/session_…` within seconds, that URL opens the session on the phone, and text typed with
  `tmux send-keys -l` + `Enter` is submitted like input. A fresh worktree isn't trusted (its prompt blocks); the
  project directory is.
- **Choice:** `harness desk <run> [--why …]` (`lib/desk.sh`) writes a prompt (`prompts/desk.md`: read `harness parked`,
  status, INBOX, progress; check safely; one numbered brief; `harness answer` and the continue only after his reply),
  starts window `<run>` in tmux session `h-desk` running `claude --remote-control "desk · <run> · <why>" --model
  $DESK_MODEL --add-dir <worktree>` in the project directory, waits ≤ 60 s for the session URL in the pane, types
  `Read <prompt> and follow it.`, and notifies with the URL as the click. One desk per run: a later event is typed into
  the live window. No URL in time: the window is killed and a plain notification goes out. The driver starts one on a
  park, a blocked or waiting run end, verify or a merge needing Michael; the debrief when its note needs him. `DESK=0`
  by default. A desk never changes a run: the driver's helper notes a failure and returns 0, and commits the desk's note
  at once (the retro's revert would drop it). Built with the P3 review (`docs/plans/2026-10-19-P3-review.md`): an open
  desk whose screen shows a dialog (the CLI's own words: `No, and tell Claude what to do differently`, `Esc to cancel`,
  `Enter to select`, `Esc to close`; not `Do you want to`, which the desk itself asks) gets nothing typed, since the
  typed Enter would answer it for Michael; the notification says to answer it first. A refused merge tells Michael and
  his desk once per tag commit while the run goes; `harness merge` says it every time and starts no desk (he is at
  the terminal). `harness gc` keeps the worktree of a run whose desk is open. `harness desk --list|--close <run>|--all`;
  gc closes desks idle for 24 h. The `why` a desk is typed is session-written text (a park's `PARKED:` line): one line,
  control characters gone, 200 chars, typed with `send-keys -l` after a fixed prefix and never run; it is no new trust
  boundary (a session can already write INBOX.md, which the desk reads). *Defaults* (plan §12): the driver's own
  notification still goes out, so DESK=1 means two per event; the start is synchronous.
- **Rejected:** `claude remote-control` server mode (no initial prompt, no per-session URL); answers through ntfy (an
  answer is an instruction to agents: it must come through GitHub or a session signed in as Michael); starting in the
  worktree (the trust prompt blocks); matching tmux targets by name (`-t h-desk` matches `h-desk-x` by prefix: exact
  `=` and window ids instead).

### D-H32 · A resumed run merges main before any session, the initializer included *(accepted 2026-10-21, built in E1 of run agent-harness-2026-10-21-measure)*
- **Finding:** `harness continue` on a run that ended before its feature list (`usage limit before the feature list`)
  re-ran the initializer without merging `main`: `sync_main` and the configuration reload sat inside `if [[ -f $LIST ]]`.
  The worktree kept the spec as it was at the first start, so the initializer planned from a stale spec while `main`
  had the revised one (voice-concierge-2026-10-19, 00:06).
- **Choice:** the driver decides `resumed` before it logs this segment's `run <id> on …` line (an earlier segment's line
  in `$STATE/run.log`; only the driver writes it). The start block runs for a resumed run or a run with a list:
  `sync_main` (its note `merged main into harness/<run>` lands in harness-log.md above `feature list written`) and the
  configuration reload; `merge_milestones` still needs the list. A conflict keeps today's behaviour (note, carry on).
  Check: `continue after a no-list end merges main first` (stub `STUB_INIT_LIMIT=1` replays the real limit capture).
- **Rejected:** merging main on every start (a fresh run already branches from `origin/main`, and a `--base <other>` run
  must not get main merged); merging only right before the initializer (a resumed run with a list already merges at the
  start, and one place for both keeps the config reload in step).

### D-H33 · Run branches never deploy: `harness init` writes the Vercel/Netlify guard, a run start without it notes and notifies once *(accepted 2026-10-21, built in E1 of run agent-harness-2026-10-21-measure)*
- **Finding:** the driver pushes the run branch after every session (Michael follows `progress.md` on GitHub), and
  Vercel builds a preview for every push to every branch. portfolio_site's v2 run passed the free plan's cap
  (`more than 100, code: "api-deployments-free-per-day"`), a cap shared with production, so a busy night can block the
  next morning's real deploy. Netlify builds every branch the same way.
- **Choice:** `lib/deploy.mjs` (pure: `vercelGuarded`/`addVercelGuard`, `netlifyGuarded`/`addNetlifyGuard`,
  `vercelDeployments`, `slug`, `unguarded`) and `lib/deploy.sh` (`deploy_status`, `deploy_guard`). A host deploys from
  Git when: Vercel = `vercel.json`, a `.vercel/` directory (worktree or project checkout), or a deployment on the repo
  made by Vercel (`gh api repos/<o>/<r>/deployments?per_page=20`, read-only; the newest 20, since another app may have made the newest); Netlify = `netlify.toml`. `harness init`
  merges `git.deploymentEnabled: { "harness/**": false }` into `vercel.json` (creating it; other keys and their order
  kept) and inserts `ignore = "case \"$BRANCH\" in harness/*) exit 0;; esac; exit 1"` into `netlify.toml`'s `[build]`
  (a `[build]` ignore of the project's own, or `build` set as an inline table or dotted keys, is left alone and init
  says what to add by hand), and says what it did. Vercel counts as guarded only if no `true` key also matches a run
  branch or starts with `harness/` (Vercel deploys when any matching key is `true`; init then says "by hand" rather
  than "added"); Netlify only if no `deploy-preview`, `branch-deploy` or `"harness/…"` context has an ignore of its own (it
  overrides `[build]`'s there; init still adds ours to `[build]` and says the rest is by hand); a deployment counts as Vercel's by its `creator.login`
  `vercel[bot]` (or the app slug `vercel`), never by a repo name. The
  driver checks once per run (`$STATE/deploy-checked`; a continue doesn't repeat it), after the start block, reading
  `origin/main` (Vercel reads the deployed commit's file, so the guard must be on main before the run branches off):
  one `note` per unguarded host (`… this run will create a preview deploy per session (harness init adds it)`) and one
  `notify`. The run goes on. Milestone PR heads (`harness-merge/<run>-<m>`) don't match the guards: each PR keeps one
  preview, `main` deploys as before. Stub: `tests/stub-gh.sh` answers the deployments call with GitHub's published
  example (`tests/fixtures/gh-deployments.json`, creator `octocat`; `STUB_DEPLOYMENTS=0` → `[]`, `=vercel` → creator
  `vercel[bot]`). Checks: `deploy.mjs: vercel and netlify guards merge, keep keys and detect`, three `init: …`, four
  `run start …`.
- **Rejected:** stopping the run without the guard (the work is still worth doing; the cost is preview builds);
  pushing less often (Michael loses the phone view of progress); guarding by host config through the hosts' APIs (a
  token and a live call per project; the repo file is reviewable and travels with the branch).
- **Known limits:** the ignore's `exit 1` replaces Netlify's own skip for an unchanged base directory (monorepos build
  on every main push after init); `netlify.toml` counts as building every branch even where branch deploys are off (a
  harmless note); a `--base <ref>` run is still checked against `origin/main`, as the spec says; init writes
  `vercel.json` at the repo root, which a Vercel project with another Root Directory doesn't read (the E1 review,
  `docs/plans/2026-10-21-E1-review.md` M6); a true key like `**-preview` is matched against `harness/run` only; a context ignore written under a bare `[context]`
  table (`deploy-preview.ignore = …`) isn't seen.

### D-H34 · Telemetry: tokens, cache hit rate and context peak per session, from a real capture *(accepted 2026-10-21, built in E1 of run agent-harness-2026-10-21-measure; E1-05 … E1-07 add their parts)*
- **Finding:** `metrics.jsonl` had cost, turns and time but no tokens, so "did this change make sessions cheaper or
  more focused?" had no answer. The stub's result line was hand-written, with no `usage` at all.
- **Choice:** `lib/metrics.mjs` `tokens(evs)` and `contextPeak(evs)` (exported, used by `outcome()`); `append` writes
  `tokens_in`, `cache_read`, `cache_write`, `tokens_out`, `cache_hit_rate` (`cache_read / (tokens_in + cache_read +
  cache_write)`, 3 decimals) and `context_peak` (the largest `input + cache_read + cache_creation` of one assistant
  request) after `turns`; `null` when the session carries no usage. Per result event the four numbers are the sums
  over `modelUsage`'s models (`inputTokens`, `cacheReadInputTokens`, `cacheCreationInputTokens`, `outputTokens`), else
  `usage`'s snake_case four; the session takes the event with the largest total (**max, like cost**): on the capture
  `Σ modelUsage[*].costUSD` = `total_cost_usd` = 0.00319778, so modelUsage tracks what cost tracks. The capture has a
  single result event, so that it stays cumulative across background-subagent segments is inferred, not seen; a
  multi-result transcript would settle it. Every field name was confirmed in the capture. `tokens_out` comes from the result, not the assistant events: theirs is the streamed
  partial (5 and 4 vs 219).
- **The one live call (the exception to build-only, as the spec asks):** on 2026-10-21, in an empty temp git repo,
  `claude -p "Write a file named ok.txt containing the word ok, then reply ok." --model haiku --output-format
  stream-json --verbose --permission-mode auto --max-turns 4 --max-budget-usd 0.25` (CLI 2.1.306, $0.0032). Its
  `assistant`, `user` and `result` lines are `tests/fixtures/usage-tokens.jsonl`, in order, with `session_id` →
  `session_TEST` and the temp path → `/tmp/capture`; `system` lines (hooks, cwd, tool and plugin lists) and the
  `rate_limit_event` (Michael's real utilization) dropped. `tests/stub-claude.sh` `ok()` replays it with cost, result
  text, `num_turns` 12 and `duration_ms` 60000 substituted, so every stub session carries tokens. Checks: `metrics.mjs:
  tokens, cache rate and context peak from the real fixture` (4 / 35768 / 13651 / 219, 0.724, 24881, computed with jq)
  and `metrics: coding rows carry tokens, cache rate and context peak`.
- **For E1-05:** stream-json events **do** carry `timestamp` (ISO, on `assistant` and `user` lines; the plan expected
  none), so `orient_s` can be measured rather than `null`. The CLI emits one `assistant` event per content block, the
  same `message.id` and `usage` on each (the capture's first message: a thinking block, then the `Write`). A stub
  session replays the capture's timestamps, so every stub session shows the same 0.23 s to its `Write`.
- **Orientation (E1-05):** `orientation(evs)` → `{ tokens, turns, seconds }`, written as `orient_tokens`,
  `orient_turns`, `orient_s`. A request is one `message.id`; orientation is the requests **up to and including** the
  first that calls `Edit`, `Write` or `NotebookEdit` (every request if none); tokens are their `input + cache_read +
  cache_creation + output`, turns their count; seconds run from the first timestamped event to the last one up to and
  including the first edit (the session's last if it never edits), `null` without timestamps; all three `null` without assistant usage. On the
  capture: 24547 tokens, 1 turn, 0.233 s; without its `Write`: 49432, 2, 1.441. *Default, a deviation from the
  feature's wording ("before" the first edit):* the edit request's input is everything orientation read (the last
  file read is paid for only there), its timing is already in `orient_s`, and "before" gives 0 tokens / 0 turns on the
  real capture, so every stub session would show none and the demo check (`orient_tokens > 0`) could not hold without
  a hand-made orientation event in the stub. It adds one request per session to both numbers, the same for every run,
  so comparisons across harness versions are unaffected.
- **The run's numbers (E1-06):** `summary.mjs build` adds `tokens` (the four sums over every row, null as 0;
  `cache_hit_rate` over the whole input; the highest `context_peak`; `by_role`), `per_verified_feature` { cost, tokens }
  (over `features.verified`, null at 0), `orientation` (the `median` of real coding rows' `orient_*`, nulls skipped;
  even counts take the mean of the two middles, rounded: integers for tokens and turns, 2 decimals for seconds),
  `rework` (ids in list order: harness-log `<id> un-passed: suite red` or `: <id> failed the re-check`, or more than
  one real coding session), `first_attempt_pass_rate` (passing and not rework / features with a real coding session)
  and `verify_fail_rate` (`failed the re-check` lines / those + verified features). `report` gains a `Tokens` and a
  `Quality` row after `Spend by role`, only for summaries that have the keys (older ledger summaries keep their
  rows); `prompts/retro.md` names the keys as inputs. Demo: rework A, C; first-attempt 0.33; verify-fail 0.25.
  *Rejected:* rework from `attempts.json` (local state only; the committed harness-log and metrics carry it).
- **Across harness versions (E1-07):** every driver segment writes `$STATE/harness-version` and
  `$STATE/harness-dirty` (`lib/version.sh` `harness_version`) and ends its `run <id> on` line with `· harness <sha>[+dirty]`; the latest segment's harness is the
  summary's `harness { version, dirty }` (`dirty` null when the state has no marker: a run from before). `ledger-line`
  adds `harness_version`, `harness_dirty` and the telemetry (`tokens`, `cache_hit_rate`, `context_peak`,
  `per_verified`, `orient_tokens`, `first_attempt_pass_rate`, `rework` as a count, `verify_fail_rate`), each null
  for a summary without it. `trends --by version` (pure `byVersion`) is one row per `<sha>[+dirty]` in order of first
  appearance, older rows as `–`: runs, Σ passing / Σ total, Σ cost / Σ passing, and the medians (unrounded before
  printing) of cache hit rate, orientation tokens and first-attempt rate over the group's non-null runs. A dirty
  harness is its own group: its numbers are not that commit's. Plain `trends` is unchanged; other arguments exit 2.
  *Default, a deviation from the feature's `rev-parse --short HEAD`:* the version is `git log -1 --format=%h -- .
  ':(exclude)ledger'` (the last commit outside `ledger/`; `unknown` outside git) and dirty means `git status
  --porcelain` over the same paths is non-empty. The driver commits `ledger/` into the harness after every run
  (`LEDGER_COMMIT=1`) and the debrief after every queue, so HEAD moves without the code changing (15 of main's last 30
  commits are `ledger:`), and a run's uncommitted ledger copy would mark the next run's harness dirty: with HEAD every
  run would be its own version. Check: `harness version skips ledger commits` (a throwaway repo).
  *Rejected:* grouping by the first segment's harness (a run continued after a merge was mostly driven by the newer
  one); a version from `package.json`/tags (the repo has neither; the sha is what Michael pulls).
- **Known limit:** `context_peak` and orientation count every assistant event, a subagent's (`parent_tool_use_id`
  set) too, if the CLI streams them (a subagent's edit would end orientation). Assistant `output_tokens` are the
  streamed partial (see above), so orientation's output share is understated.
- **Rejected:** summing tokens over result events (modelUsage is cumulative: a session with background subagents would
  count its first segment twice); context peak from the result's `usage.iterations` (only the last request's);
  a hand-written stub `usage` (fakes mirror the live API).

### D-H35 · The eval set: replay tasks from real runs, validated, build-only *(accepted 2026-10-21, built in E2 of run agent-harness-2026-10-21-measure; E2-02 writes the task set, E2-03 … E2-06 add their parts)*
- **Finding:** nothing re-runs fixed tasks, so no harness change can be judged against the one before it.
- **Choice (the set, E2-02):** `evals/tasks/<id>/task.json` holds 1–3 features copied verbatim from a source run's
  `feature_list.json` as of `base`, the commit that run's session started from (the parent of its first commit, named
  in `why`), plus the run's spec and brief as of `base`. `lib/eval.mjs validateTask` returns one error per problem,
  each starting with its field (`features: required`, `policy: must be build-only`, `base: a full commit sha`, an
  unknown key); `node lib/eval.mjs validate evals/tasks` also requires the id to equal its directory and at least one
  task. Policy is always `build-only`, and no task text matches `grep -ril 'live\|secret\|\.env'`: features can't be
  reworded, so a feature that hits it is left out. The source run's record stays in `base` (its session saw it).
  Check: `eval: every task.json validates and a bad one is rejected`.
  *Default (E2-02):* the first four tasks come from agent-harness's own runs (`agent-harness-2026-10-19`,
  `agent-harness-2026-10-21-measure`), all first-time passes. The spec names pathways, dj-crate-streaming,
  portfolio_site and hit_list as the sources, but this session's permission classifier refused reads of their git
  history (a mirror clone in scratch included), and agent-harness's runs have no retried feature and no in-task
  `after` that passes the grep. The retried and depends-on tasks wait on that access (evals/README.md § Still to add).
  *Default (E2-02, second session):* a plain `ls` of those records was refused too, so the set grows from
  agent-harness only. A **depends-on by order** task counts in its category: the later feature has no `after`, but its
  steps build on code the earlier one adds (the harness runs them in array order), and `why` names what is reused.
  Two such tasks: 10-19 P1-03 → P1-04 (`gh_url`) and E1-06 → E1-07 (the summary keys in the ledger row), the second
  replacing the single E1-06 task so no feature is replayed twice per set run. Set: 5 tasks (3 first-time, 2
  depends-on by order).
- **Rejected:** an LLM judge (v1 is deterministic); synthetic tasks (no real failures in them); rewording a feature to
  pass the grep (the replay would no longer be the source's task); `git -C` in project checkouts for the records (a
  read-only mirror in scratch is the route for the remaining sources, once its reads are allowed); stripping the
  source run's record from `base` (its session saw it); padding the set to 8 with more agent-harness first-time
  passes (it skews the set to easy tasks and leaves less room under 12 for the retried ones); calling a task with a
  milestone `after` (P3-01 → P2) a depends-on task (the dependency is outside the task).
