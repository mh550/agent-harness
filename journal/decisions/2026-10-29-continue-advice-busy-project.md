# A parked run's continue advice names another live run of its project and gives Michael the choice

*(2026-10-29, an interactive session from Michael's handoff; account in `journal/runs/2026-10-29-hiccups.md`)*

- **Finding:** the parked card's `do` line (`lib/parked.mjs commandsFor`) and the harness-answer skill said "with a
  runner going, `harness queue add --continue <run>`, otherwise `harness continue <run>`". Both checked only the race
  for `MAX_PARALLEL_RUNS`, not the per-project hold: the runner holds an entry while another run of its project is
  alive (`busy_projects`, decisions/2026-10-21-queue-one-run-per-project), and since
  decisions/2026-10-27-same-project-starts a plain `harness continue` queues itself the same way (`project_busy`); only
  `--now` or `--foreground` skips it. On 2026-10-29 run `agent-harness-2026-10-29` parked at 08:48, the queue started
  `-2` (20 files of overlap) at 08:49, and the advice queued run 1 behind all 23 of `-2`'s features, reversing the
  merge order meant. Nothing said so; Michael caught it. Later the advice assumed `harness continue` and `harness sync`
  work on a paused run: a paused driver stays alive, so `continue` refuses it, and a manual sync checks for nothing
  alive.
- **Choice:** `commandsFor` takes `busy`, the first other live run R of the project (`lib/overlap.mjs busyRun`:
  `liveRun`, the driver or a lane, as `project_busy`); `harness needs`, its `--json` `card.commands`, `harness parked
  --json` and `harness status` pass it. With R, the commands are the answer and two continues, each with its order as
  a shell comment: `harness queue add --continue <run> # waits for R to end; R merges first` and `harness continue
  <run> --now # runs beside R; this run merges first if it finishes first`; `runState` adds `; R is running on this
  project: pick one continue`. Without R the commands are as before. The skill looks for R in `harness status` before
  any continue and, with one, asks Michael (queue, `--now`, or he stops R himself); checks `harness status <run>`
  after acting and says whether the run started or is held; keeps a "facts that matter" block with file:line (pause
  keeps the driver alive, stop ends it, `continue` refuses a live run, a manual sync only with nothing alive, `--now`
  skips the hold, a driver keeps the harness it started with); says which run merges first when an overlap card is
  open; runs a feature-list `jq` Michael will run to stdout first; and may suggest `stop` or `pause`, never run them.
  The desk prompt asks Michael which continue when a card offers two, and runs only his pick.
- **Rejected:** picking for him (`--now` by default, or the queue): which run should merge first is his call, and
  either one silently is the bug. Only the hold's text in `runState`, commands unchanged: the desk runs
  `card.commands` as given, and a plain continue looks right and waits for hours. A `busy` key in `harness parked
  --json`'s elements: the commands and `card.run_state` carry it, and the keys stay as readers expect.
