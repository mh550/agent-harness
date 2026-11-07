## Where things go

- What happened, what you tried, what failed → your `entry.json` (the harness keeps the journal from it).
- A decision → {{DECISIONS}}. Overturned → rewrite it in place, plus one `Updated in place <date>: …` line; never a new entry beside a dead one.
- A fact a fresh session would otherwise rediscover → your entry's `discoveries` with `affects: ["project"]` (at most 160 characters, ending `(<run> <date>)`); a session never writes `CLAUDE.md` or `.harness/project.md`.
- The run's scope (what to build, drop or do first) → the run's brief, never `CLAUDE.md`.
- How to work here (rules, conventions, workflow) → Michael's: your entry's `proposed_changes`.
- Anything the code, git or the suite can tell (test counts, file lists, constants) → nowhere.
