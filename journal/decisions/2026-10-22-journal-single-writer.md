# Sessions write entry.json; the driver is the journal's only writer (the spec's D-H39)

*(2026-10-22, E4-03 of run agent-harness-2026-10-21-measure; plan `docs/plans/2026-10-21-E4-memory.md` §1, §2, §3.1–§3.4,
§7, §8)*

- **Finding:** a run's memory was `progress.md`, free text the sessions wrote themselves at the top of the file. Nothing
  checked its shape, a session cut off by a limit or refused wrote nothing, and the next session had to read the whole
  file to find the one dead end that mattered to it. E4 needs a record a program can select from (the context pack,
  E4-05) and render (progress.md, E4-04), so its lines must always parse.
- **Choice:** a coding, verify or initializer session writes one JSON object to the run directory's `entry.json`
  (schema in the plan §1.1, shown in its prompt). Right after the session's `WIP` commit (coding, initializer) or
  after `restrict` (verify), and before any of the driver's checks, `journal()` in `lib/driver.sh` calls
  `node lib/entries.mjs ingest`: it validates the file against the session the driver ran (feature or milestone,
  kind), drops unknown keys, stamps `at` (local `YYYY-MM-DD HH:MM`), `session` (the transcript's name) and `model`,
  appends one line to `entries.jsonl` and deletes `entry.json`. A missing or invalid file gets the note
  `<id>: entry.json missing|invalid (<first error>); recorded a minimal entry` and a minimal entry: the files git saw
  change since the session's start commit (the run directory excluded), the final message (≤ 400 characters) as its
  summary, and `minimal: "missing" | "invalid: <first error>"`. Refused and parked sessions are journaled too: the
  journal is the complete record. An entry's `outcome` is the session's claim (a minimal entry's: what the list says
  when the session ends, or `parked` on a `PARKED:` line); the driver's verdicts (list restored, un-passed on a red
  suite, given back after a limit) stay notes in `harness-log.md`. If the append itself fails, `entry.json` moves to
  the scratch directory so the next session's ingest can't take it for its own. No extra commit: the next
  `HARNESS: …` commit records the deletion and the appended line. Until E4-04, sessions also still write progress.md.
- **Rejected:** sessions appending to `entries.jsonl` themselves (two writers, and one malformed line breaks every
  reader); an LLM summarizing the run into memory (out of the spec's scope, and not deterministic); journaling only
  sessions that finish (the refused and cut-off ones are exactly what the next attempt needs to know about); writing
  the driver's verdict into the entry (it would make an entry two writers' text again).
