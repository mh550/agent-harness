# The resident helper: one warm node process per driver and lane answers the `.mjs` questions over a coproc (2026-11-03)

**Goal.** Phase 2 of `docs/plans/2026-11-03-test-suite-redesign.md`. 93 % of a large check file's 3,139 node starts
are the driver's and its lanes' (49 % of the file's CPU); the memo and the poll collapse of run `agent-harness-2026-11-03`
(C1) took 6.7 % of CPU off against a 20 % target, because most call sites are `$( … )` subshells no memo can serve and
most questions are not pure. Replace the spawn with a **resident helper**: a node process each bash process (the driver,
each lane) starts lazily with `coproc`, asks over its stdin and reads from its stdout, that dies on stdin EOF when the
shell exits; every answer byte for byte what the spawned script printed; a spawn whenever the helper is absent, busy or
broken. One milestone, **H1**. Michael chose node (this design) over a Rust port of the hot path on 2026-11-03
(the plan's question 3); the Rust numbers stay in §Fallback.

**Source.** `docs/specs/2026-11-03-test-suite-redesign.md` (Phase 2); `findings-and-research/2026-11-03-redesign-baseline.md`
§2 (the exec table by script, subcommand and caller; file 13: driver 975 + lane 1,945 of 3,139; `treekey.mjs` 205 per
file at ~190 ms each), §3 (per-request work 0.1 ms in process); `journal/decisions/2026-10-31-fewer-node-starts.md`
(C1's memo: its keys, its subshell limit, its rejected "long-lived node server" paragraph and the reasons: supervise,
restart, version, a socket per run, stale state); `lib/record.sh` (`F`, `Fv`, `F_MEMO`, `MET`, `SUM`), `lib/check.sh`
(`treekey.mjs --partial --names`, `testcount.mjs`), `lib/lane.sh`, `lib/driver.sh`; the scripts in the table:
`lib/features.mjs`, `metrics.mjs`, `treekey.mjs`, `testcount.mjs`, `entries.mjs`, `inbox.mjs`, `memlint.mjs`, `render.mjs`,
`needs.mjs`, `summary.mjs`, `notify.mjs`; `tests/checks/84-node-memo.sh` (the `node` shim that counts execs).

**Rules.** `CLAUDE.md` binds: worktree only; never touch real runs or real state; fakes mirror the live API; every
behaviour test-first in `tests/checks/` (and `tests/unit/` for the pure parts), names in the fixtures; `bash -n`,
`node --check`; one decision file per behaviour; `docs/architecture.md` and `README.md` in the same milestone. **Proceed
on the defaults written here; record them marked *default*; never park.** **No `harness-log.md` or `run.log` line
changes** except the helper's own restart line; every check that compares a log line is the proof the answers are
identical. The invariant stands: the helper caches nothing between requests (the memo in bash stays the only cache,
keyed on content); a request's answer is computed from the files as they are at that moment.

## Depends on

- `main` at or after the merge of phase 3 (`docs/specs/2026-11-03-suite-tiers.md`) and of C1 (the memo, `Fv`, `F poll`,
  `features.mjs` exit 70 on a throw).
- No other suite alive during H1-04's measurement (one lane; the session checks `harness status`).

## H1 · The helper

### H1-01 · Every served script has a `main(argv, io)` and no CLI side effect on import

**Choice.** Each script the helper serves exports `main(argv, io)`: it returns `{ rc, out }` (or a promise of it),
writes nothing to `process.stdout` itself, never calls `process.exit`, and reads the cwd from `io.cwd` where it reads
the cwd at all (`treekey.mjs` runs git in the current directory: it takes `io.cwd`). The CLI tail becomes:
`if (isMain(import.meta.url)) { const { rc, out } = await main(process.argv.slice(2), { cwd: process.cwd() });
process.stdout.write(out); process.exit(rc); }` with one shared `isMain` in a new `lib/cli.mjs` (the guard most scripts
already have in some form; one spelling). A throw inside `main` is the caller's: the CLI tail prints the message to
stderr and exits 70 (as `features.mjs` does since C1); the helper does the same per request. **Served first** (*default*,
the top of the exec table, ~85 % of the driver's starts): `features.mjs`, `metrics.mjs`, `treekey.mjs`, `testcount.mjs`,
`entries.mjs`, `inbox.mjs`; then `memlint.mjs`, `render.mjs`, `needs.mjs`, `summary.mjs`, `notify.mjs` if the feature's
time allows (each one a line in the decision file). A script not served is spawned as today. **No module-level mutable
state** in a served script (a cache, a counter, a lazily filled map): the review reads for it; a script that needs one
is not served until it is removed. Output is captured by `main`'s return, never by hooking `console.log` (*default*:
a hook would catch a library's stray write too).

**Checks (written first)**, in `tests/unit/cli.test.mjs` and the served scripts' unit files: `main` of each served
script, called with the arguments the driver uses on fixture files, returns the bytes the CLI prints (the unit test
runs the CLI with `execFileSync` and compares; the existing stub runs compare the notes); importing a served script
runs nothing (a test imports it with a fake `process.argv` and asserts no output, no exit); `node --check` on every
`.mjs` touched.

### H1-02 · `lib/helper.mjs` and `ask` in `lib/record.sh`

**Choice.**

1. **`lib/helper.mjs`**: reads requests from stdin, one per line: `{"id":<n>,"script":"<name>.mjs","args":[…],"cwd":"…"}`.
   For each, in order (one at a time, never concurrent): `import()` the script from `lib/` (cached by node after the
   first), `await main(args, { cwd })`, then writes the reply as **two parts**: a header line `<id> <rc> <bytes>\n` and
   exactly `<bytes>` bytes of `out`. A throw: rc 70, `out` empty, the message to the helper's stderr (the driver's log).
   An unknown script or a malformed line: a header with rc 64 and the reason on stderr; the caller then spawns. On
   stdin EOF the helper exits 0. It handles `SIGTERM` by exiting. It never writes to stdout except replies.
   *Default:* length-prefixed framing, not JSON replies: bash reads the payload with `LC_ALL=C IFS= read -r -N <bytes>`
   byte-exact and no decoder process is needed (a `jq` per call would be 1 ms, the `base64` another); trailing newlines
   survive (`$( )` strips them as it does today).
2. **`ask <script> <args…>`** in `lib/record.sh`, the one door: if `HARNESS_HELPER=0`, or this shell has no helper and
   cannot start one, or the call is from a background job of the shell that owns the helper (below), spawn `node
   "$HARNESS_HOME/lib/<script>" "$@"` as today. Else: start the helper lazily (`coproc HELPER { exec node
   "$HARNESS_HOME/lib/helper.mjs"; }` in the shell that sourced `record.sh`: `HELPER_SHELL=$$`; a subshell `$( … )` or
   `< <( … )` inherits the coproc FDs and may ask through them, since bash runs one thing at a time in that shell), take
   `flock -n` on `$HARNESS_SCRATCH/helper-$HELPER_SHELL.lock` (a backgrounded job of the same shell asking at the same
   moment gets the lock refused and spawns: never two requests interleaved on one pipe), write the request line, read
   the header with `read -r -t "${HARNESS_HELPER_TIMEOUT:-120}" -u "${HELPER[0]}"`, then the payload, print it, return
   `rc`. **A failed read** (timeout, EOF, a header that is not three fields, a wrong id): kill the helper, log one
   `run.log` line `helper restarted: <why>` (bounded: after three restarts in one process, `HARNESS_HELPER=0` for that
   process and the line `helper off: <why>`), answer this call by a spawn, and start a new helper on the next call.
   The cwd sent is `$PWD` (the driver and the lanes `cd` into worktrees).
3. **The call sites.** `F`, `Fv`, `MET`, `SUM` and every `node "$HARNESS_HOME/lib/<served>.mjs"` in `lib/*.sh` and
   `lib/check.sh` (`treekey.mjs --partial --names`, `testcount.mjs`) go through `ask`. The memo (C1-02) sits in front:
   a hit never asks. `bin/harness` CLI commands (`status`, `needs`, `show`, …) are one process per command and spawn as
   today (*default*: a CLI call is one question; the suite's `cli` class is 162 of 3,139). `check.sh` is run by sessions
   outside the driver's shell too (`$HARNESS_CHECK`): it sources what it needs to `ask`, and with no helper of its own
   (a session's call) it spawns; under the driver's `run_init` it is a child process, not a subshell, so it has no
   helper: *default*, it spawns (two starts per `check.sh` call; a lane's helper would need a socket, rejected below).
4. **Lifecycle.** The helper is a child of the shell that started it; bash closes the coproc's FDs at exit and the
   helper exits on EOF; the shell's existing EXIT traps also `kill` it (belt and braces), and `scope_stop` kills the scope.
   Each lane process (`lib/lane.sh` runs as its own process) has its own; the coordinator has its own. `tests/lib.sh`
   sets nothing: the stub runs exercise the real path. `harness sync` levelling `lib/` while a run is alive changes
   nothing the helper serves (it imported its code at start, as the running bash did).

**Checks (written first)**, in a new `tests/checks/NN-resident-helper.sh` with the `node` shim of `84-node-memo.sh` (it
counts execs and execs the real node) and a check that sources `lib/record.sh` (`HARNESS_HOME=$HH`, `HARNESS_SCRATCH`
set): 20 `ask features.mjs summary <list>` calls (memo off: `F_MEMO` cleared, or distinct lists) start node **once**;
the answers equal the spawned `node lib/features.mjs summary <list>` byte for byte, trailing newline included (`cmp`);
an `ask` of a script that throws returns 70 and the message is on stderr; `ask` of an unserved script spawns; a
`$( ask … )` subshell answers through the parent's helper (node count unchanged); a background job `( ask … ) &` while
the parent holds the lock spawns (count +1, answer identical); the helper killed between two calls (the check kills
`$HELPER_PID`) → the next call answers by a spawn, `helper restarted:` in the log, the call after that through a new
helper; `HARNESS_HELPER=0` → every call spawns (count = calls); a stub `harness start` with the shim: the start's node
starts ≤ 30 (C1-01 counted 402; helper 1 per driver and per lane + the stub's + cli), and `harness-log.md`, `run.log`
and `feature_list.json` identical to the same run with `HARNESS_HELPER=0` (`diff` after stripping timestamps); a
two-lane stub run (`47-lanes-two.sh`'s shape): two helpers alive during the run (`pgrep -f helper.mjs` count 3 with the
coordinator's), none after `ended`; every existing check passes unchanged.

### H1-03 · `treekey.mjs`'s own cost

**Finding.** `treekey.mjs` is 193 ms per call on the loaded box and runs 205 times per large file (`--partial` 128,
plain 77): 30–40 s of a 185 s file, most of it git (`ls-files`, `hash-object` over every tracked and untracked file,
`execFileSync`), which the helper does not remove.

**Choice.** Profile one call (`strace -c`, `--cpu-prof`) and take the cut its profile names, *default*: one `git
ls-files -z --stage` for the tracked blobs (the index already holds their hashes; a file whose stat differs from the
index is re-hashed, as `git status` does: `git ls-files -z --stage --modified` names them) and `hash-object` only for the
untracked and modified files, one call with `--stdin-paths`. The key's value is unchanged for an unchanged tree
(`tests/checks/34-check-key.sh` and `81-partial-key.sh` are the proof); a key that changed for a tree whose content did
not is the failure. Measure: wall of `node lib/treekey.mjs` before and after on this repo (idle: `node -e 0` subtracted),
in the decision file. Target: under 60 ms per call.

### H1-04 · The proof

**Choice.** As C1-04: two solo full suites (`systemd-run --user --scope -p MemoryMax=3G /usr/bin/time -v env TEST_JOBS=4
bash tests/run.sh`), *before* in a scratch worktree of the run's base commit, *after* on the feature's tree, no other
suite alive; plus `strace -f -e trace=execve` of file 13 (`13-run-2-michael-sets-desk`) before and after, node execs by
class (C1-01's `exectable.mjs` under `findings-and-research/2026-11-03-exec-table/`), and one stub start's node count.
Rows in `findings-and-research/2026-11-03-resident-helper.md` beside the baseline's.

| measure | before (baseline §1, §2) | predicted after |
|---|---|---|
| node starts per large file (file 13) | 3,139 | **≤ 300** (cli 162 + stub 48 + checks 9 + helpers ~20 + unserved) |
| node starts per stub `harness start` | 402 | **≤ 30** |
| CPU of file 13 | 170.6 s | **≤ 110 s** (−35 %) |
| full suite solo CPU | 3,136 s | **≤ 2,300 s** (−25 %; the slow tier's stub runs are most of it) |
| full suite solo wall at 4 jobs | 804 s | **≤ 600 s** |
| `treekey.mjs` per call | 193 ms (loaded) | ≤ 60 ms |
| `harness-log.md` lines changed | – | **0** |
| helper restarts per stub run | – | 0 |

A miss is recorded with its number; the feature passes on the table's presence. A wall over 650 s with node starts
under 300 means the remainder is git (7,754 per file) and bash's forks: the plan's phase 4 ground, not this run's.

### H1-review

Sized to the milestone: an Opus reader of the diff; hardest: `ask`'s every failure branch (each must end in a spawn and
a correct answer, never a hang: the read timeout, the lock, the id check), module-level state in any served script, the
framing on an answer that holds a NUL or no trailing newline, and that no served script reads `process.argv` or the
real cwd inside `main`.

## Fallback: Rust, with its numbers

If H1-02's lane and lifecycle checks cannot be made green (a hang the timeout cannot explain, interleaved answers, a
helper that outlives its shell), the alternative with the same gain and no lifecycle is one static binary for the hot
path (`treekey`, `testcount`, the read-only questions of `features` and `metrics`: ~820 lines), measured on this box on
2026-11-03 (`findings-and-research/2026-11-03-redesign-baseline.md` §4): binary start 1.2 ms against node's 27–41 ms;
cold build 3.6 s (debug) / 4.2 s (release) with `serde_json`, incremental 0.14–0.55 s, a second worktree with a shared
`CARGO_TARGET_DIR` 0.17 s; toolchain 2 GB, already on the one box the harness runs on; every output byte for byte, with
a differential check against node on fixtures. That is a decision for Michael with a spec of its own, not this run's
fallback feature.

## Decision and docs

`journal/decisions/2026-11-03-resident-helper.md` (title, provenance, finding (the table), choice with every default,
rejected: a socket or FIFO server shared by the driver and its lanes (one process to supervise and version across
lanes; the per-shell coproc has no shared state and dies with its shell); JSON-framed replies decoded by `jq` (a
process per answer); hooking `console.log`; serving `bin/harness` CLI commands; a helper for `check.sh` under a session
(a socket); the Rust port (above, with numbers); `node --snapshot-blob` to cut the start (unmeasured; the start is what
goes away)). It **updates in place** `journal/decisions/2026-10-31-fewer-node-starts.md`'s rejected "long-lived node
server" paragraph with one `Updated in place <date>: …` line (a per-shell coproc, not a server: the objections it named
and how each is answered). `docs/architecture.md` §3 (`lib/helper.mjs`, `ask`, `lib/cli.mjs`), §4 (`helper-<pid>.lock`
in scratch), §7 (the helper's failure path), §11 (the rows); `README.md` (`HARNESS_HELPER=0` as the off switch, one
sentence).

## Milestones

| M | Contents | After |
|---|---|---|
| H1 | H1-01 `main(argv, io)` in the served scripts and `lib/cli.mjs`; H1-02 `lib/helper.mjs`, `ask`, the call sites, the lifecycle; H1-03 `treekey`'s cut; H1-04 the rows; docs; `2026-11-03-resident-helper`; H1-review | `[]` |

Plan as five or six features, H1-04 the last build feature, then the review. The suite ends green at every milestone.

## Not in this run

Rust; `bin/harness` CLI commands through the helper; `check.sh` under a session through a helper; git's 7,754 execs per
file and bash's own forks (phase 4's purity work and a later finding); any note text; `TEST_JOBS`; the memo's keys.

## After the run (Michael)

- Nothing to configure. `HARNESS_HELPER=0` in `~/.config/harness/config.sh` turns it off for every run if a real run
  shows a `helper off:` line.
- The morning after the next real run on this repo: `grep -c 'helper restarted' <state dir>/run.log` (expected 0), and
  the solo wall from the run's own `check.sh` rows against the table.
