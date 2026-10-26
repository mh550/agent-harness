# Queue numbers count parked entries; a park never overwrites one

*(2026-10-26, run agent-harness-2026-10-26-2, feature F1-04; spec `docs/specs/2026-10-21-retro-fixes.md` R11, plan
`docs/plans/2026-10-26-F1-driver-cli.md` § R11)*

- **Finding:** `queue_add` took the next number from the top-level `queue/*.args` only, so with the queue empty and
  `held/0004-start-proj.args` parked, the next entry was `0001-…`, and once the numbers caught up a new entry could
  share a parked one's name. `queue park` was a plain `mv` into `held/`, which silently replaced a parked entry of the
  same name (and its `.why`): a parked run lost without a trace.
- **Choice:**
  - `queue_add` takes the highest `NNNN-` over `queue/` **and** `queue/held/` (created first), so a new entry never
    reuses a parked entry's number.
  - `queue park <n>` refuses when `held/<name>` exists, before the `mv` and the `.why`:
    `harness: <name> already parked (harness queue unpark it or rm queue/held/<name>)`, exit 1; both files stay.
  - Nothing goes to a harness-log.md: the queue belongs to no run. The output of `queue add` and the error are the
    record.
  - Checks (`tests/run.sh`, the parked entries section): `queue add numbers past a parked entry`, `queue park refuses
    to overwrite a parked entry; both survive`.
- **Rejected:**
  - **Renaming on park (a suffix or a new number):** `unpark` already renumbers; a park that renames hides that two
    entries clashed, which only happens when something wrote a queue file by hand.
  - **Overwriting with a warning:** the parked entry is the one with a reason attached; losing it is the failure.
