## Where things go

This session is read-only: the harness reverts your edits to the code, `CLAUDE.md` and the decisions store.
- A durable fact (a gotcha a fresh session would rediscover, still true after this run) → your entry's `discoveries` with `affects: ["project"]` (a retro: your report). No session writes `CLAUDE.md` or `.harness/project.md`.
- A decision that changed → your entry's `discoveries`, affecting `"run"` (a retro: your report). The next coding session moves it into the decisions store ({{DECISIONS}}).
- The run's scope → the run's brief, which is Michael's.
- How to work here → Michael's: say it in `proposed_changes` (a retro: a proposal).
- Anything the code, git or the suite can tell (test counts, file lists, constants) → nowhere.
