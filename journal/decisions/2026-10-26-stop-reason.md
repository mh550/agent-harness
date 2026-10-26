# A stop records why: `harness stop --why` and `status: stop <why>`

*(2026-10-26, run agent-harness-2026-10-26-2, feature F1-05; spec `docs/specs/2026-10-21-retro-fixes.md` R7 (and R8),
plan `docs/plans/2026-10-26-F1-driver-cli.md` § R7)*

- **Finding:** the hit_list-2026-10-20 retro could only say "no stop reason was recorded": `harness stop` touched an
  empty `STOP`, `status: stop` carried nothing, and the driver wrote a bare `stopped by Michael` to harness-log.md and
  `ended`. A retro or debrief judging such a run can't tell a stop for a changed spec from a stop for a bad night.
  The other half of "why did this run end", R8, is already done on main: `lib/driver.sh:104` sets
  `END_REASON="driver exited unexpectedly (see run.log)"` before anything can fail, and the EXIT trap at
  `lib/driver.sh:108` writes `$END_REASON · <date>` to `ended` (`finish` overwrites `END_REASON` with its reason).
  Nothing was built for R8.
- **Choice:**
  - `harness stop <run> --why "<text>"` writes the reason, on one line (newlines and tabs become spaces, trimmed),
    into the run's `STOP`; without `--why` `STOP` is empty, as before. An empty `--why` or any other argument is
    refused and nothing is written.
  - INBOX.md's `status: stop <text>` (the first `status:` line, the one `control()` reads) carries the reason after
    `stop` and whatever separates it (spaces, `:`, `,`, `;`, `-`, `—`), from its first letter or digit on.
    `status: stopped`, a bare `status: stop` or `status: stop -` give none.
  - `stop_why()` in `lib/driver.sh` takes `STOP`'s line first (the box is the later, more deliberate word), else the
    INBOX text, cut at 200 characters, and returns `stopped by Michael[: <why>]`; the stop site notes it and passes
    it to `finish`. So harness-log.md, `ended`, summary.json's `end_reason`, the end notification and the services
    note (`services stopped (stopped by Michael: <why>)`, `HARNESS_TEARDOWN_WHY`) all carry it.
  - The reason is Michael's free text, so nothing reads its words as the end's kind: `lib/summary.mjs` strips only
    the trailing ` · YYYY-MM-DD HH:MM:SS` from `ended` (a reason may hold ` · 2026-11`) and matches its causes'
    keywords (`usage limit`, `blocked`, …) on `stopped by Michael` alone; `lib/page.mjs`'s card tone does the same
    (`stopped by Michael: blocked, failed` is muted, not a warning). summary.mjs reads harness-log.md with each
    `stopped by Michael: <why>` cut to `stopped by Michael`, so `status: stop B failed the re-check` makes no cause or
    rework of B; a `|` in a reason is escaped in report.md's and trends' table cells, and page.mjs splits its
    `<summary.json>|<state>` arguments at the first `|` (F1-06 review: the card vanished). `harness pause|resume`
    refuse extra arguments.
    Left alone: the reason is cut at 200 characters by bash, which counts bytes in a non-UTF-8 locale, so a long
    non-ASCII reason may be split inside a character there.
  - `retro()` renders with `HARNESS_END_REASON=$END_REASON`, and `prompts/retro.md` says `It ended: {{END_REASON}}`,
    with Michael's reason to judge the run against.
  - Unchanged on purpose: `control()` (`stop*` already matched `stop <text>`) and `cmd_continue`'s
    `^stopped by Michael` guard (decisions/2026-10-26-requested-continuations), which matches the longer string.
  - Checks: `tests/run.sh` run 2b (stub flags `STUB_CLI_STOP=-|<why>` and `STUB_PHONE_STOP=<why>`): the CLI reason,
    the CLI without one (and the refused usages), the phone reason, an odd separator and ` · 2026-` in a reason, the
    retro prompt, the continuation guard and `end_reason`, and the page's tone (pure, `card`).
- **Rejected:**
  - **A separate `STOP_WHY` file:** one marker holding its own reason keeps `STOP`'s meaning (present = stop) and
    is cleared by the same `rm -f` in start and continue.
  - **The INBOX reason winning over `STOP`'s:** the phone line may be stale (an old `status: stop` left in place);
    the CLI reason was typed for this stop.
  - **A free-form multi-line reason:** `ended` is one line (`<reason> · <date>`) and summary.mjs strips the date
    with a one-line pattern; a reason that needs paragraphs belongs in INBOX.md's answers.
