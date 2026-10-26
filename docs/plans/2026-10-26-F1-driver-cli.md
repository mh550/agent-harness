# F1 · Driver and CLI correctness: R1, R4, R6, R7, R11 (plan, 2026-10-26)

Run `agent-harness-2026-10-26-2`, feature F1-01. Spec: `docs/specs/2026-10-21-retro-fixes.md` § F1. Brief: F1 and
F2 only, independent lanes, build on `main` as it stands, never park.

Checked against `main` at `d53c73a` (this worktree's base). `tests/checks/` does **not** exist here: the suite split
(`docs/specs/2026-10-26-suite-split.md`) is unmerged. Every new check goes in `tests/run.sh` under the
`# ---- <title> ----` section named below; a new topic gets a new marker line so the split script makes it a file
later. If `tests/checks/` exists when a build session starts (main merged in), the check goes in the file of that
topic instead, under the same title.

One feature per item, in this order: F1-02 (R1), F1-03 (R4), F1-04 (R6 + R11), F1-05 (R7, which reuses F1-04's
`--automatic`), F1-06 (review). Each check is written first and watched failing on the code as it was.

## What main already has

- **R8 is done; nothing to build.** `lib/driver.sh:104` sets `END_REASON="driver exited unexpectedly (see run.log)"`
  before anything can fail, and the EXIT trap at `lib/driver.sh:108` writes `$END_REASON · <date>` to `ended`
  (`finish` overwrites `END_REASON` at `:485`). The spec's `:82-83` is stale; these are the lines. R7's decision file
  (`2026-10-26-stop-reason.md`) cites them, since R7 is the other half of "why did this run end".
- **R1 is half done.** `lib/testcount.mjs:5-9`: `testCount` returns node:test's `# pass N` / `ℹ pass N` first,
  else the **last** `N passed` / `N tests passed` in the text. So pytest (`5 passed in 0.12s`) and jest
  (`Tests: 1115 passed, 1115 total` after `Test Suites: 12 passed, 12 total`) already give the right number in the
  usual order; cargo gives the last crate's count, not the sum; go (`--- PASS` lines, `ok pkg 0.01s`) gives nothing.
  No note is written when nothing matches. Callers: `lib/check.sh:57,64,65` (the green marker and the green line),
  `lib/driver.sh:294` (`tests-start`, in `run_init`), `lib/driver.sh:491` (`tests-end`, in `finish`).
- **R4 not done.** `verify()` (`lib/driver.sh:375-379`) runs `sync_main`, then `run_init`, whose `$CHECK` is
  answered from `$STATE/green/green-<key>` when the tree has a marker; the verifier's own `check` and the driver's
  `green` after a "holds" (`:411`) hit the same marker.
- **R6 not done.** `cmd_queue add --continue` (`bin/harness:297-300`) writes `continue <run> --queued …`;
  `cmd_continue` (`bin/harness:212-217`) skips any `--queued` continuation of a run whose `ended` starts with
  `stopped by Michael`. Writers of continuations: the driver's `finish()` (`lib/driver.sh:519`, `queue add --continue
  "$RUN_ID" --keep-attempts [--until-epoch …]`, only after a session cap), the debrief (`lib/debrief.sh:275`, only for
  runs that ended on time or a usage limit, `continue_check` at `:258-268`), the desk and Michael (the CLI).
- **R7 not done.** `cmd_control stop` (`bin/harness:326`) touches an empty `STOP`; `control()` (`lib/driver.sh:165-170`)
  returns `stop` for `STOP` or a `status: stop…` line; the one stop site is `lib/driver.sh:647`
  (`note "stopped by Michael"; finish "stopped by Michael"`). The retro prompt has no end reason.
- **R11 not done.** `queue_add` (`bin/harness:108-113`) numbers from `ls "$Q"` only; `queue park`
  (`bin/harness:309-313`) is a plain `mv "$f" "$Q/held/"`.

## R1 · Real test counts (F1-02)

**Files.** `lib/testcount.mjs`, `lib/driver.sh` (`run_init`), five fixtures, `tests/run.sh`,
`journal/decisions/2026-10-26-real-test-counts.md`, `docs/architecture.md` (the `testcount.mjs` mentions: §3 line 41
and the `check.sh + treekey.mjs` row), `README.md` (a line where the report's `tests start → end` is described; add
one under the run-report lines if there is none).

**testCount, in order** (first that matches wins; each is pure and unit-checked):
1. node:test: `^(?:ℹ|#) pass (\d+)` (as now).
2. cargo: the **sum** of every `^test result: \w+\. (\d+) passed;` (one line per test binary, doc-tests included).
   Before the generic rule: cargo's lines also say `N passed`.
3. jest/vitest: `^\s*Tests:\s+(?:\d+ \w+, )*(\d+) passed` (the `Tests:` line, never `Test Suites:`).
4. go: the count of `^\s*--- PASS: ` lines (subtests, indented, count too). Needs `go test -v`; without `-v` go prints
   only `ok <pkg> <time>` and the result is no match (the decision file says so).
5. generic (pytest, mocha, others): the last `(\d+) (?:tests? )?passed` (as now).

**Fixtures** (`tests/fixtures/`, added once, never hand-edited after; line 1 is a `#` comment naming the source,
which must not itself contain a count):

| File | Runner | Where its text comes from | Expect |
|---|---|---|---|
| `check-node-test.txt` | node:test | generated here: `node --test` (node v24.21.0) on a scratch dir with 3 passing tests, output as printed | 3 |
| `check-pytest.txt` | pytest | generated here: `~/.local/bin/pytest` (pytest 9.1.1; `python3 -m pytest` is not installed) on 4 passing tests in `/tmp` | 4 |
| `check-cargo.txt` | cargo | generated here: `cargo test` (cargo 1.99.0) on a scratch crate with 2 unit tests and 1 doc-test, so two `test result: ok. N passed;` lines (plus the `running N tests` and `Doc-tests` lines) | 3 (2 + 1) |
| `check-jest.txt` | jest | **not installed**: copied from jest's summary format, `Test Suites: 2 passed, 2 total` then `Tests: 7 passed, 7 total`, `Snapshots:`, `Time:`, `Ran all test suites.`; line 1 cites `https://github.com/jestjs/jest/blob/main/packages/jest-reporters/src/getSummary.ts` (the code that prints those lines; confirm the path before citing it) | 7, not 2 |
| `check-go.txt` | go | **not installed**: `go test -v` output as documented, `=== RUN   TestX`, `--- PASS: TestX (0.00s)` ×3, `PASS`, `ok  	example.com/pkg	0.01s`; line 1 cites `https://pkg.go.dev/testing` and `https://github.com/golang/go/blob/master/src/testing/testing.go` (the `--- PASS: %s (%s)` format) | 3 |

The generated ones are made in the scratch directory (`/tmp/harness/agent-harness/agent-harness-2026-10-26-2/`),
never in the repo, and copied with the comment line prepended; the generating commands go in the entry's
`verified_how`. Real runs' `check.out` can't be used (CLAUDE.md: never read `~/.local/state/harness`).

**Driver.** In `run_init`, after `$CHECK` and the `tests-start` line: when this segment's suite wrote
`$SCRATCH/check.out` (a cached green writes none) and `testcount.mjs` finds nothing in it, and `$STATE/testcount-nomatch`
is absent, `note "test count: no match in the suite's output (tests start/end stay unknown)"` and touch
`$STATE/testcount-nomatch` (once per run, across segments). `tests-start`/`tests-end` keep reading `check.out` and
the green marker as now.

- The demo run (`run 1`, CHECK_CMD `test ! -f BROKEN`, no output): **exactly one** note (empty output has no count;
  Michael should see that the report's `? → ?` is the suite's, not a bug).
- The scrub run (`# pass 7`, both segments): **no** note; the second segment is cached green with an empty scratch
  (no `check.out`), which is not a no-match.
- A suite that prints text with no count: a short run `nocount` (run.env `CHECK_CMD='echo "lint: clean"'`, started and
  continued with `--until-epoch $(( $(date +%s) - 1 ))` the way the scrub run is): exactly one note over both
  segments. That's what proves "once per run".
- Risk: every stub run now has this note. A check that counts harness-log.md lines exactly would move; grep for one
  before calling the check done.

**Checks.**
- New section `# ---- test counts, pure (R1): one fixture per runner ----`, after the `metrics, pure` section (before
  `scope.sh (L1-02)`): `testCount: node:test fixture gives 3`, `testCount: pytest fixture gives 4`,
  `testCount: jest fixture gives the Tests: count (7), not Test Suites:`, `testCount: cargo fixture gives the sum of its
  test result lines (3)`, `testCount: go fixture gives its --- PASS count (3)`, each through
  `node lib/testcount.mjs tests/fixtures/<f>` (prints `<n> tests`). Before the code: cargo and go fail (2 and
  nothing), the other three pass; the entry's `verified_how` records that.
- In `# ---- scratch (L3-02) …`, after the scrub checks (the demo, scrub and nocount runs have all ended by then):
  `test count: no match is noted once per run (demo: no output; nocount: text with no count), never for a counted or cached suite (scrub)`.

## R4 · Verify never trusts the cache (F1-03)

**Files.** `lib/driver.sh` (`verify()`), `prompts/verify.md` (step 1), `tests/stub-claude.sh`, `tests/run.sh`,
`journal/decisions/2026-10-26-verify-runs-the-suite.md`, `docs/architecture.md` (§7 Guards, the Verify row; §4's
Suite cache row: "removed before each verify").

**Driver.** In `verify()`, after `sync_main` and before `run_init`: `rm -f "$STATE/green/green-$(node
"$HARNESS_HOME/lib/treekey.mjs")"` and `note "verify $m: suite cache cleared; the suite runs in full on the verified
tree"`. `run_init`'s `$CHECK` then runs the suite in full on that tree (the "Init output" the verifier sees is a full
run), and writes a fresh marker only if it is green; the verifier's `check` may then be answered from that fresh
marker, which is fine: it is the same tree, just run. The driver's `green` after a "holds" (`:411`) is the existing
guard that turns a red tree into `verify <m>: the suite is red on the verified tree (main merged in); not verified
(needs Michael)`. Escalated rounds (`mem_gate || run_init`) don't clear again: same tree, full run moments ago.

**Prompt.** `prompts/verify.md` step 1 becomes: "Run the suite and the smoke check (both under *This run*). The
harness cleared the suite's cached result for this tree before this session, so the suite runs in full: the init
output below is a full run, not a cached one." (The check greps `cleared the suite's cached result`.)

**Stub flag.** `STUB_STALE_GREEN=<id>` (header comment of `tests/stub-claude.sh`): that feature's coding session
creates `BROKEN` in the worktree (the demo suite, `test ! -f BROKEN`, goes red) and writes an empty marker (what a suite with no count leaves) into
`$HARNESS_CHECK_CACHE/green-$(node "$HERE/../lib/treekey.mjs")` for that tree, then marks its feature passing. The
driver's post-session check is answered from the stale marker, so the feature stays passing (the R4 hole).

**Checks.** New section `# ---- run 13c: a stale green marker (R4): verify runs the suite in full ----`, after
`run 13b`: a run `stale` with `STUB_STALE_GREEN=B STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_LENIENT=1`:
- `a stale green marker is caught at verify: M1 red, not tagged` — harness-log.md has `verify M1: suite cache cleared`
  and `verify M1: the suite is red on the verified tree`; `git -C "$T/origin.git" tag -l "run/stale/M1"` is empty.
  Run against main's driver first (no `rm`): it fails (M1 is tagged); the entry's `verified_how` says so.
- In the `run 1` section: `the verify prompt says the suite runs in full` — `$HARNESS_STATE/proj/demo/prompt-verify.md`
  contains `cleared the suite's cached result`.

## R6 · Requested continuations run (F1-04)

**Files.** `bin/harness` (`cmd_queue add`, `cmd_queue list`, `cmd_continue`, the usage header), `lib/driver.sh`
(`finish()`), `lib/debrief.sh` (its `queue add`), `tests/run.sh`,
`journal/decisions/2026-10-26-requested-continuations.md`, `docs/architecture.md` §12 (and §9's table row, §16's
`CONTINUE:` line), `README.md` (the `queue add --continue` line).

**The mark.** `harness queue add --continue <run> [options]` writes `continue`, `<run>`, `--queued`, `--requested`,
then the options: a continuation anyone queues through the CLI (Michael, the desk, the n8n request inbox) is a decision
to resume. A new option `--automatic` (consumed by `queue add`, never written) leaves `--requested` out. The two
automatic writers pass it:
- `finish()` at `lib/driver.sh:519`: `queue add --continue "$RUN_ID" --automatic --keep-attempts …`. It only fires
  after a session cap, so it is never a stopped run's; it is marked automatic so `queue list` says what it is.
- the debrief (`lib/debrief.sh:275`): `"$H" queue add --continue "$run" --automatic "${args[@]}"`. Its brief already
  says "not Michael's words"; `continue_check` already refuses runs that weren't ended by time or a usage limit.

`cmd_continue` takes `--requested` (`requested=1`) and skips only `(( queued && ! requested ))` with `ended` matching
`^stopped by Michael` (message unchanged: `skipping queued continuation of <run>: Michael stopped it`). A requested
one goes on as `harness continue` would. `harness queue list` appends ` (requested)` to an entry whose lines include
`--requested` and ` (automatic)` to a `continue` entry without it (start entries get neither). The "already queued"
guard is unchanged (an automatic one already queued for that run satisfies a request: it is not a stopped run's).

**Existing setups that must stay automatic.** Two checks queue a continuation of a fake stopped run (`stoppy-o`, an
`ended` of `stopped by Michael` and an empty `meta.env`) and rely on it starting nothing: the queue section's
`queue holds an entry whose project has a live run, starts the next one` (`tests/run.sh` ~1020) and the L5 section
(~1598). Queue those with `--automatic` so they keep doing what they test; with a request, `cmd_continue` would go on
into an empty `meta.env`.

**Checks** (queue section, `# ---- queue: start queues behind a running run; …`):
- Adapt `a runner that started nothing (a skipped continuation): no debrief`: its setup line becomes
  `"$H" queue add --continue stoppy --automatic`; name and assertions unchanged; it still passes.
- New `a requested continuation of a run Michael stopped starts; an automatic one is skipped (both logged)`: two fake
  stopped runs (`stopreq`, `stopauto`, each with `ended` `stopped by Michael` and a `meta.env` naming its own `STATE`,
  `RUN_ID` and a `PROJECT_DIR` that isn't a checkout, so `cmd_start` dies at once), one queued plain, one `--automatic`;
  the runner in the foreground; runner.log has `starting: harness continue stopreq` and no `skipping queued
  continuation of stopreq`, and has `skipping queued continuation of stopauto: Michael stopped it`. Also: the
  requested entry's file has `--queued` and `--requested` lines; the automatic one has `--queued` and no `--requested`.
- New `queue list marks continuations (requested) or (automatic)`: with both queued, `harness queue list` shows
  `… stopreq … (requested)` and `… stopauto … (automatic)`.
- The driver's own form. No check runs `finish()`'s continuation today (`continuation queued (` appears in no
  check). New `the driver's continuation after a session cap is automatic`: a run `capped` with
  `$HARNESS_STATE/proj/capped/run.env` holding `MAX_SESSIONS=1` (run.env is sourced as config, as the scrub run's
  CHECK_CMD is; AUTO_CONTINUE=1 is the default), `STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_LENIENT=1`; it ends `session cap
  (1)`, harness-log.md has `continuation queued (1 of 3`, and `$Q/*-continue-capped.args` has `--queued` and
  `--keep-attempts` and no `--requested`; `queue list` shows it `(automatic)`. Remove the entry after.
- The debrief's form: the existing `continuation queued: keeps attempts, brief marked as the debrief's`
  (`tests/run.sh` ~1235) gains `! grep -qx -- --requested "$f"`; its name stays.

## R7 · A stop records why (F1-05)

**Files.** `bin/harness` (`cmd_control stop`, usage header), `lib/driver.sh` (a `stop_why` helper, the stop site at
`:647`, `retro()`), `prompts/retro.md`, `tests/stub-claude.sh` (`STUB_PHONE_STOP`, new `STUB_CLI_STOP`),
`tests/run.sh`, `journal/decisions/2026-10-26-stop-reason.md`, `docs/architecture.md` §4 (the Markers row: `STOP`
holds the optional reason) and `README.md` § Steering.

**CLI.** `harness stop <run> [--why "<text>"]`: `STOP` holds the reason's first line (empty without `--why`, as now).

**Driver.** `stop_why()` → the first line of `$STATE/STOP` if non-empty, else the rest of INBOX.md's `status: stop…`
line after `stop` (leading spaces, `:` and `-` dropped); one line, cut at 200 characters. At `:647`:
`w=$(stop_why); note "stopped by Michael${w:+: $w}"; finish "stopped by Michael${w:+: $w}"`. So harness-log.md says
`stopped by Michael: the spec changed` and `ended` starts with it; without a reason both say `stopped by Michael` as
before. `control()` is unchanged (`stop*` already matches `stop the spec changed`). `cmd_continue`'s
`^stopped by Michael` guard matches the longer string. `services_down` gets finish's whole reason (its note reads
`services stopped (stopped by Michael: the spec changed)`).

**Retro.** `retro()` renders with `HARNESS_END_REASON=$END_REASON`; `prompts/retro.md` gets, after the `Run:` line:
`It ended: {{END_REASON}}. A reason after "stopped by Michael:" is his; judge the run against it.`

**Stub flags.** `STUB_PHONE_STOP=1` keeps writing `status: stop`; any other value writes `status: stop <value>`.
New `STUB_CLI_STOP=<text>`: the initializer session runs `"$HERE/../bin/harness" stop "$HARNESS_RUN_ID" --why "<text>"`.
Both documented in the stub's header.

**Checks.** New section `# ---- run 2b: a stop with a reason (R7), from the CLI and from the phone ----`, after `run 2`
(run 2 itself keeps `STUB_PHONE_STOP=1`: its checks are the no-reason phone path and stay as they are):
- runs `stopcli` (`STUB_CLI_STOP="the spec changed"`) and `stopphone` (`STUB_PHONE_STOP="the spec changed"`); both
  stop after the initializer.
- `harness stop --why: the reason in harness-log.md and ended` — `hlog stopcli` has `· stopped by Michael: the spec
  changed$`; `ended` starts with `stopped by Michael: the spec changed`.
- `status: stop <text> from the phone: the same note and ended` — the same for `stopphone`.
- `a stop without a reason is recorded as before` — run 2's `ended` starts with `stopped by Michael · ` and its
  harness-log.md line ends `· stopped by Michael` (the existing `phone stop honoured before any coding session`
  still passes).
- `the retro prompt carries the end reason` — `$HARNESS_STATE/proj/stopphone/prompt-retro.md` contains `stopped by
  Michael: the spec changed`; `prompts/retro.md` contains `{{END_REASON}}`.
- `a stop reason keeps the continuation guard and the summary` — `jq -r .end_reason` of stopphone's `summary.json` is
  `stopped by Michael: the spec changed`; `harness continue stopphone --queued` prints `skipping queued continuation
  of stopphone: Michael stopped it`; a requested `queue add --continue stopphone` entry has `--requested` (F1-04's
  form).

## R11 · Queue numbering past parked entries; park never overwrites (F1-04)

**Files.** `bin/harness` (`queue_add`, `cmd_queue park`), `tests/run.sh`,
`journal/decisions/2026-10-26-queue-numbering-and-park.md`, `docs/architecture.md` §12 (the **Parked entries**
paragraph), `README.md` (the `queue park` row).

**Code.** `queue_add` takes the highest `NNNN-` over `"$Q"/*.args` **and** `"$Q"/held/*.args` (`ls "$Q" "$Q/held"`
with the held dir created first, or a glob over both). `queue park`: when `$Q/held/$(basename "$f")` exists,
`die "$(basename "$f") already parked (harness queue unpark it or rm queue/held/$(basename "$f"))"`, before any
`mv` and before the `.why` is written; `die` exits non-zero with `harness: …`.

**Checks** (`# ---- parked entries: …` section):
- `queue add numbers past a parked entry` — with `$Q/held/0004-start-proj.args` (and its `.why`) in place and no
  top-level entries, `harness queue add "$T/proj" --spec SPEC.md` prints `queued: 0005-start-proj.args`.
- `queue park refuses to overwrite a parked entry; both survive` — with `$Q/held/0006-start-proj.args` holding
  `held-marker` and a top-level `0006-start-proj.args` written by hand, `harness queue park 1` exits non-zero with
  `harness: 0006-start-proj.args already parked`, the top-level file is still there, and the held one still holds
  `held-marker`. Clean `$Q` and `$Q/held` after.

## The lines each behaviour writes

| Item | harness-log.md (`note`) | elsewhere |
|---|---|---|
| R1 | `test count: no match in the suite's output (tests start/end stay unknown)` (once per run) | — |
| R4 | `verify <m>: suite cache cleared; the suite runs in full on the verified tree` (each verify); a red tree then gives the existing `verify <m>: the suite is red on the verified tree (main merged in); not verified (needs Michael)` | — |
| R6 | the existing `continuation queued (<n> of <max>; it starts when the queue runs)` becomes `continuation queued (<n> of <max>, automatic; it starts when the queue runs)` | runner.log: `starting: harness continue <run>` (requested) or `skipping queued continuation of <run>: Michael stopped it` (automatic); `queue list`: `(requested)` / `(automatic)` |
| R7 | `stopped by Michael: <why>` (or `stopped by Michael`), and `run ended (stopped by Michael: <why>): …` | `ended`, summary.json `end_reason`, the retro prompt |
| R11 | none: the queue is no run (no run is alive to hold the line) | `queue add`'s `queued: <NNNN>-…` past parked numbers; `harness: <name> already parked (…)` on stderr, exit 1 |

## Decision files (one per behaviour; R6 and R11 separate)

| File | Item | Cites |
|---|---|---|
| `journal/decisions/2026-10-26-real-test-counts.md` | R1 | the five fixtures, the match order, go needs `-v`, the once-per-run note |
| `journal/decisions/2026-10-26-verify-runs-the-suite.md` | R4 | `lib/check.sh`'s cache (decisions/2026-10-25-capped-suites) |
| `journal/decisions/2026-10-26-requested-continuations.md` | R6 | the `--automatic` writers (finish, debrief) |
| `journal/decisions/2026-10-26-stop-reason.md` | R7 | R8 done: `lib/driver.sh:104` and `:108` |
| `journal/decisions/2026-10-26-queue-numbering-and-park.md` | R11 | the 2026-10-25 n8n-events overwrite |

Each: title, provenance (run, feature, spec item), then finding · choice · rejected.

## Defaults taken here (Michael may overrule; none blocks the build)

- D1 *default*: the driver's and the debrief's continuations are marked `--automatic`; every other `queue add
  --continue` is requested. Rejected: an env variable (invisible in the entry), and making `--requested` the opt-in
  (the CLI path is the one Michael uses, so it must be the default).
- D2 *default*: a suite with **no output** also gets `test count: no match` (once per run): the demo stub's suite is
  one. Rejected: staying silent on empty output (then `? → ?` in a report has no explanation).
- D3 *default*: go is counted from `--- PASS` lines only, so it needs `go test -v`; plain `go test` is a no-match
  (noted). Rejected: counting `ok <pkg>` lines (packages, not tests).

## Review (F1-06)

An Opus subagent read `git diff main...HEAD -- lib bin prompts tests docs README.md journal/decisions` (1283 lines,
from `/tmp/harness/agent-harness/agent-harness-2026-10-26-2/F1-review.diff`). Each finding was confirmed against the code
before it was fixed; each Important one has a check that failed on the old code and passes now (all in `tests/run.sh`).

| Severity | Where | Finding | Done |
|---|---|---|---|
| Important | `lib/driver.sh` `demote_requests` | The order was when the driver acted on the stop (between sessions), not when Michael gave it: a request queued after `harness stop` was demoted too and never started | demote only entries no newer than `STOP` (else INBOX.md); check `a request queued after the stop (before the driver acts on it) stays requested` (new stub flag `STUB_CLI_REQUEST`) |
| Important | `bin/harness` `queue add --continue` | A request over a queued automatic entry only added `--requested`: it kept the driver's `--until-epoch` (a past deadline: the run ends at once) or the debrief's options and dropped the request's own | the request replaces the entry, options included; check `a request replaces a queued automatic continuation's options with its own (no stale --until-epoch)` |
| Important | `bin/harness` `cmd_continue` | A phone stop's `status: stop` stayed in INBOX.md, so any continuation (requested or by hand) stopped again at its first `control()` | `harness continue` of a run Michael stopped sets that line back to `status: run`; the driver notes it; check `harness continue of a run stopped from the phone: INBOX.md's status: stop goes back to run, so it doesn't stop again` |
| Important | `lib/page.mjs` main, `lib/summary.mjs` report/trends | A `\|` in a stop reason: page.mjs split `<summary.json>\|<state>` at the last `\|`, so the card vanished; the table rows broke | split at the first `\|`; table cells escape it; check `a stop reason with \| keeps its card on the debrief page and is one cell in report.md and trends` |
| Minor | `lib/summary.mjs` | The stop note in harness-log.md still fed the cause regexes: `status: stop B failed the re-check` made B rework | harness-log.md is read with each reason cut; check `a stop reason's words are never read as a feature's cause (A failed the re-check)` |
| Minor | `lib/driver.sh` `verify` | The cache marker was keyed before the init; an init that rewrites a file leaves the session's marker in place | `run_init fresh` clears it after the init, just before the suite; run 13c still catches a stale marker |
| Minor | docs, decision | vitest prints `Tests  N passed (N)` with no colon: counted by the last rule, not the jest one | docs and the decision file say so; no rule change without a real vitest fixture |
| Minor | `lib/driver.sh:311` | The no-match note fires once, also on a red suite that crashed before any test; a later green run then sets tests-start | not fixed: the note says what was seen then; the report's numbers come from tests-start/end, which stay right |
| Minor | `lib/driver.sh` `stop_why` | Trailing punctuation stays (`status: stop "spec changed"` → `spec changed"`) | not fixed: it is Michael's text, shown as typed |
| Minor | `bin/harness` `queue add` | The upgrade races the runner moving the entry to done/; parked (`held/`) automatic entries aren't upgraded, so a request adds a second entry | not fixed: the race is a second wide; a parked entry is set aside by Michael, a new request beside it is what he asked for |
| Simplification | `lib/driver.sh` loop | `[[ $c == stop ]]` tested twice | one block |
| Simplification | `lib/page.mjs`, `lib/summary.mjs` | the same `stopped by Michael` strip in both | not done: two one-line regexes in files that share no module today |
