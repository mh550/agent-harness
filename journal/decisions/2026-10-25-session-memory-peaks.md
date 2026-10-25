# Each session's memory peak goes in metrics.jsonl, and report.md lists the ones over 2 GB

*(2026-10-25, run agent-harness-2026-10-25-lifecycle, feature L1-04; spec `docs/specs/2026-10-25-resource-lifecycle.md`
§L1 item 5, plan `docs/plans/2026-10-25-L1-capped-sessions.md` §9.2; builds on `decisions/2026-10-25-scoped-sessions`)*

- **Finding:** since L1-03 every session runs in its own capped scope and the driver reads the scope's `MemoryPeak`
  (`S_PEAK`, in MB) before stopping it, then drops it. The caps (5G high, 6G max) are a guess from one audit; without
  the peaks of real sessions there is nothing to tune them, or `CHECK_MEMORY_MAX`, against, and a feature that grows
  towards the cap is invisible until it is killed.
- **Choice:**
  - `metrics.mjs append` takes a 12th argument, the peak in MB, and writes `mem_peak_mb` on every row: a number, or
    null when the session ran uncapped (no user systemd; an empty or `null` argument). Every `MET append` call (init,
    coding, refused coding, verify, refused verify, retro) passes `"$S_PEAK"`. The row is built by the exported
    `metricsRow`, so the suite checks it without a transcript.
  - `report(s, metrics = [])` stays pure: given the run's metrics rows, it adds a `### Memory peaks over 2 GB`
    section, one line `- <feature> · <model> · <peak> MB` per session over 2048 MB (init and retro rows, which have
    no feature, show their role), and leaves the section out when none. `###`, not the plan's `##`: it sits under the
    run's own `## <run> · <project>` heading, and `harness report` prints several runs one after another.
  - The CLI's `report` reads the `metrics.jsonl` beside each `summary.json`. The driver's `report.md` has it there
    (the run directory); `harness report` rebuilds `summary.json` into the state dir, so it copies `metrics.jsonl`
    beside it, which also keeps the section once `gc` has removed the worktree.
- **Rejected:**
  - **A `summary.json` field** (say `mem_peaks`): `summary.json` feeds the ledger and `trends`, whose rows are per run;
    a per-session list belongs with the per-session rows, and the spec asks for no new field.
  - **Reading the peak from the transcript or from `harness-log.md`'s cap note**: the transcript knows nothing of
    memory, and the note only covers sessions that hit the cap.
