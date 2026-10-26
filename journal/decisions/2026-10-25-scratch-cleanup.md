# A finished run deletes its scratch; installs go to HARNESS_CACHE; an optional age rule for the rest

*(2026-10-25, run agent-harness-2026-10-25-lifecycle, feature L3-02; spec `docs/specs/2026-10-25-resource-lifecycle.md`
§L3 item 1 (B5), plan `docs/plans/2026-10-25-L3-scratch-and-tmux.md` §1–§3, §8; the finding in
`findings-and-research/2026-10-24-system-resource-audit.md` (the boot purge, cause 6))*

- **Finding:** nothing ever deleted `/tmp/harness/<project>/<run>`: `check.out` plus a `check-<key>.out` per code tree,
  pytest sandboxes, `server.log`, screenshots, review diffs, a Playwright `node_modules` reinstalled after every boot.
  `/tmp` is disk-backed here and the daily cleaner removes only files older than 30 days, so a boot's
  `systemd-tmpfiles-setup` purge deleted about 1.07 M leaked files (the root fs went from 2,715,855 to 1,649,372
  inodes) and held the splash screen for about a minute.
- **Choice:**
  - **`finish` deletes the run's scratch** (`scratch_done` in `lib/driver.sh`, after the ledger and before the
    continuation, so the existing "run end notes" commit carries its note). First it copies what the record needs into
    the state dir: `init.out`, `teardown.out` and the last full suite's `check.out` as `check-last.out`. Then
    `scratch_rm` (`lib/prompt.sh`, beside `prompt_vars`, which builds `SCRATCH`) removes the directory only when it is
    exactly `$HARNESS_SCRATCH_ROOT/$PROJECT_NAME/$RUN_ID` with an absolute root and a project and run id that can't be
    empty, `.` or `..`: never `/tmp/harness/<project>/`, which holds a live project's `live.lock`. Anything else is
    refused with a note (`scratch not removed: …`).
  - ***default*: only `finish` deletes.** A crash, a SIGKILL or a stop mid-session leaves scratch for Michael to read;
    a continued run recreates it and its first init rewrites `init.out`.
  - ***default*: `KEEP_SCRATCH=0`**; `1` keeps scratch, with a note `scratch kept (KEEP_SCRATCH=1): …` (the suite's
    base config sets it: its checks read the stub's files in scratch after a run).
  - ***default*: `teardown.out` is kept too**, beside `init.out` and `check-last.out`: a failed teardown's note points
    at it.
  - **`check.sh` keeps one `check-<key>.out`**, the newest tree's; the `green-<key>` markers live in the state dir and
    stay. Going back to an older green tree prints `check: green (cached for this code tree)` without a test count,
    and `finish`'s `tests-end` is then absent (as when the file is missing today).
  - **`HARNESS_CACHE=${XDG_CACHE_HOME:-~/.cache}/harness/<project>`**, exported by `prompt_env` (so the init, every
    session and `check.sh` see it) and created by the driver: installs a project keeps across runs and boots
    (`PLAYWRIGHT_BROWSERS_PATH=$HARNESS_CACHE/ms-playwright`). The harness never deletes it. ***default*: no prompt
    line for it** (the static prompt prefix stays as it is); the README tells projects to use it from their init and
    `CLAUDE.md`.
  - **`templates/user/harness-tmpfiles.conf`**, optional, Michael installs it: `e /tmp/harness - - - 3d` ages out what
    a crashed run left after 3 days untouched (longer than a 72 h run, so a running run's quiet files survive).
    ***default*: it also excludes `live.lock` (`x /tmp/harness/*/live.lock`)**: aging out a held flock file would let
    a second writer in. The rule runs from the user's `systemd-tmpfiles-clean.timer`, which is **disabled on this box**
    (`systemctl --user is-enabled systemd-tmpfiles-clean.timer` printed `disabled`, 2026-10-25), so the install
    command enables it.
- **Rejected:**
  - **A tmpfiles rule alone**: it acts once a day on files idle for days, so every run's files still sit on disk for
    at least 3 days, it does nothing on a box where the user timer is off (this one), and Michael has to install it.
  - **Deleting scratch in the EXIT trap**: a crash or a stop would take the evidence Michael reads next.
  - **`rm -rf "$SCRATCH"` without a guard**: an empty `PROJECT_NAME` or `RUN_ID`, or a changed `HARNESS_SCRATCH_ROOT`,
    would take the project's directory (and `live.lock`) or worse.
  - **Keeping every `check-<key>.out`**: one per tree a session checks, the same file over and over; the cache decision
    lives in the markers, not in the output.
