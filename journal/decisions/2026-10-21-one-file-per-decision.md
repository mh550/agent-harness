# Decisions are one file each, named by date and slug, not numbered

*(2026-10-21, Michael: "address the root cause of the numbering")*

- **Finding:** `D-H<n>` was "the next free number" at the end of `journal/decisions.md`. A run picks that number from
  the `main` it branched from, and appends at the file's end. Two branches open at once (a run and a fix on `main`,
  or two queued runs under `MERGE_POLICY=pr`) therefore take the same number and edit the same lines. On 2026-10-21
  the measure run's D-H32 to D-H34 collided with PR #4's D-H32: the driver's sync of `main` conflicted, E1 was
  verified but opened no PR, and every later milestone would have hit it too (fixed by hand in PR #6).
- **Choice:** a new decision is a new file, `journal/decisions/<YYYY-MM-DD>-<slug>.md` (title, provenance line, then
  finding · choice · rejected). Its id is the file name, cited as `decisions/<date>-<slug>`. Two branches never edit
  the same lines and never share an id, so parallel and queued runs merge cleanly. A spec that says "a `D-H<n>`
  entry" now means such a file. `journal/decisions.md` keeps D-H1 to D-H34 as they are; an in-flight run that still
  appends a `D-H<n>` there merges cleanly as long as `main` never edits that file's end again.
- **Rejected:** run-scoped numbers such as `D-H<run>-<n>` (no shared ids, but still one file whose end every branch
  edits); numbers assigned by the driver at merge time (code for a naming problem, and the PR text would change
  after review); renumbering by hand after each merge (that is what failed).
