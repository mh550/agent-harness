# The queue runs one run per project at a time

*(2026-10-21, Michael: "adjust the harness to account for this"; PR #4)*

- **Finding:** with `MAX_PARALLEL_RUNS=3`, the queued `agent-harness-2026-10-21-measure` and `-retro` runs would have
  started side by side on the same repo: two branches from one `main`, both editing `summary.mjs`, the driver and the
  queue, and Michael left to untangle two sets of conflicting PRs. Nothing in the runner looked at which project an
  entry was for.
- **Choice:** the runner picks the first queued entry whose project has no live driver (the project of a `start` is
  its directory name, of a `continue` its run's state dir); held entries keep their place and are logged once per
  change. `harness start --now` is untouched: starting a second run on a busy repo by hand is still possible.
- **Rejected:** a per-project limit in config (nobody has asked for two runs on one repo; one is the safe default);
  stopping at a held head entry (it would idle a free slot while other projects wait).
