# Verify runs the suite in full: the verified tree's cached green is removed first

*(2026-10-26, run agent-harness-2026-10-26-2, feature F1-03; spec `docs/specs/2026-10-21-retro-fixes.md` R4, plan
`docs/plans/2026-10-26-F1-driver-cli.md` § R4)*

- **Finding:** `check.sh` answers a tree it has seen green from its `green-<key>` marker, and the marker directory is
  `$HARNESS_CHECK_CACHE`, which every session can write. In portfolio_site-2026-10-20-2 and -20-vc4 verifiers judged
  milestones on "check: green (cached …)" lines, never seeing a full run. A marker that is wrong for its tree (written
  by a session, or left by a suite that was green on flaky luck) carried through the post-session check, the verify
  init, the verifier's own `check` and the driver's `green` after a "holds": a red tree was tagged and merged into main.
  The suite reproduces it: on main's driver, run 13c's stale marker gets M1 tagged and merged with `BROKEN` in it.
- **Choice:**
  - `verify()` removes `$STATE/green/green-<key>` (key from `lib/treekey.mjs`) **after `sync_main` and before
    `run_init`**, so the key is the tree being verified (main merged in), and notes `verify <m>: suite cache cleared;
    the suite runs in full on the verified tree` once per verify.
  - `run_init`'s check then runs in full and writes a fresh marker only if green; the verifier's `check` may be
    answered from that fresh marker (same tree, just run), and the driver's `green` after a "holds" is the existing
    guard that turns a red tree into `verify <m>: the suite is red on the verified tree (main merged in); not verified
    (needs Michael)`.
  - An escalated round (`mem_gate || run_init`) doesn't clear again: same tree, a full run moments ago.
  - `prompts/verify.md` step 1 tells the verifier the harness cleared the suite's cached result, so the init output is
    a full run.
  - Check: `tests/run.sh` run 13c (`STUB_STALE_GREEN=B`: B leaves `BROKEN` and an empty marker for that tree), `a stale
    green marker is caught at verify: M1 red, not tagged`; and in run 1, `the verify prompt says the suite runs in full`.
- **Rejected:**
  - **Bypassing the cache for every check during verify** (an env flag to `check.sh`): the verifier's subset and
    repeated full runs would cost a suite run each (10 min on this repo) for no gain over one fresh run on the tree.
  - **Clearing the whole cache directory:** other trees' markers (earlier segments, the merged main) are still right
    and save full runs in coding sessions.
  - **Clearing after every coding session too:** that is every session's suite run twice; the verify is the gate that
    tags and merges, so the full run goes there.
