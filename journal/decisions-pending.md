# Decisions waiting for a number

An entry here is decided and built, but its `D-H<n>` is not assigned yet: a run in flight is appending its own
`D-H<n>` entries to the end of `decisions.md` on its branch, and an entry added on `main` at the same place makes
that run's milestone merges conflict (2026-10-21: the queue entry below, PR #4, against
`agent-harness-2026-10-21-measure`). Once that run's PRs have merged, move each entry to the end of `decisions.md`
with the next free number and delete it here.

### D-H(pending) · The queue runs one run per project at a time *(2026-10-21, Michael: "adjust the harness to account for this")*
- **Finding:** with `MAX_PARALLEL_RUNS=3`, the queued `agent-harness-2026-10-21-measure` and `-retro` runs would have
  started side by side on the same repo: two branches from one `main`, both editing `summary.mjs`, the driver and the
  queue, and Michael left to untangle two sets of conflicting PRs. Nothing in the runner looked at which project an
  entry was for.
- **Choice:** the runner picks the first queued entry whose project has no live driver (the project of a `start` is
  its directory name, of a `continue` its run's state dir); held entries keep their place and are logged once per
  change. `harness start --now` is untouched: starting a second run on a busy repo by hand is still possible.
- **Rejected:** a per-project limit in config (nobody has asked for two runs on one repo; one is the safe default);
  stopping at a held head entry (it would idle a free slot while other projects wait).
