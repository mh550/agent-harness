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
    stay. **A marker now holds its tree's test count** (`<n> tests`, or empty when the output has none), and both the
    cached line and `finish`'s `tests-end` read it first, the tree's output second (older markers are empty). Found by
    the feature's review: a continued segment starts with an empty scratch, so a tree cached green from the last
    segment had no output to count, and `finish` deleted the right `tests-end`. Going back to an older tree keeps its
    count the same way.
  - **Eval runs keep their scratch** (`KEEP_SCRATCH=1` in `lib/eval.sh`'s safety lines): `eval probes` renders the
    next coding prompt after the task's run has ended, and that prompt carries the init output from scratch. The
    eval's scratch is under its own throwaway directory. (Same review.)
  - **`harness merge` removes the scratch directory the driver created for it** when it is empty (`rmdir`), since it
    runs no init or session and never reaches `finish`. (Same review.)
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

## L3-05: the L3 review's scratch fixes

*(2026-10-25, run agent-harness-2026-10-25-lifecycle, feature L3-05; review `docs/plans/2026-10-25-L3-review.md` #3–#7)*

- **Finding:** `scratch_rm` compared strings only, so a symlinked project or run directory under the scratch root
  passed and `rm -rf` reached its target. `scratch_done` deleted scratch even when a copy into the state dir had
  failed. A partial `rm` failure was noted as "not this run's scratch directory". `check-last.out` was the last suite
  that *ran*, possibly an earlier tree's red output when the final tree was cached green. The note claimed files a
  segment never copied. The set-aside `entry-stale-*`/`entry-failed-*` files lived in scratch, so finish deleted the
  evidence of a failed journal append.
- **Choice:**
  - `scratch_rm` also requires `realpath -m` of the target to be `realpath -m <root>/<project>/<run>` (no symlink on
    the way), runs `rm -rf --one-file-system`, and returns 2 on a refusal, else `rm`'s status.
  - `scratch_done <tree key>` moves to `lib/prompt.sh` beside the guard (unit-checked). `check-last.out` is the final
    tree's `check-<key>.out` when scratch has it, else `check.out`. A failed copy keeps scratch (`scratch kept:
    copying <f> into <state> failed`). The note lists what it kept (`in the state dir: init.out check-last.out`, or
    `nothing`), and a failed `rm` says `scratch not fully removed: … (rm exit <n>)`.
  - The set-aside entries go to the state dir. The teardown note names both places `teardown.out` lives.
- **Rejected:**
  - ***default*: requiring the scratch root to be under `/tmp`**: `HARNESS_SCRATCH_ROOT` is the operator's setting,
    and the exact `<root>/<project>/<run>` shape with a real path is what makes the delete this run's own.
  - Removing a stale `check-last.out` when a segment copied none: it is the last suite output there is; the note now
    says what this segment kept.
