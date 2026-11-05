# The resident helper: one warm node process per driver and lane answers the `.mjs` questions over a coproc

*(2026-11-05, run `agent-harness-2026-11-05`, milestone H1; spec `docs/specs/2026-11-03-resident-helper.md`; plan
`docs/plans/2026-11-03-test-suite-redesign.md` phase 2; begun by H1-01, each later feature adds its part)*

## Finding

93 % of a large check file's 3,139 node starts are the driver's and its lanes' (49 % of the file's CPU;
`findings-and-research/2026-11-03-redesign-baseline.md` §2), and most call sites are `$( … )` subshells no memo can
serve.

**The proof (H1-04, 2026-11-05):** `findings-and-research/2026-11-03-resident-helper.md`, with how each row was read.
*Before* is the run's base `07a31f6`, *after* `de51e2f`; the baseline's suite was 203 checks smaller than *before*.

| measure | baseline | before | after | predicted | result |
|---|---|---|---|---|---|
| node starts per large file (file 13) | 3,139 | 2,665 | **337** | ≤ 300 | **missed, by 37** |
| node starts per stub `harness start` | 402 | 336 | **20** | ≤ 30 | met |
| CPU of file 13 | 170.6 s | 161.3 s | **88.0 s** | ≤ 110 s | met |
| full suite solo CPU | 3,136 s | 3,804.3 s (1332/1332, none red) | **2,107.9 s** (1450/1450, none red) | ≤ 2,300 s | met |
| full suite solo wall at 4 jobs | 804 s | 974.2 s | **608.1 s** | ≤ 600 s | **missed, by 8.1 s** |
| `treekey.mjs` per call, spawned | 193 ms (loaded) | 58.0 ms idle, 65.3 ms in a suite | **49.3 ms** idle, **64.4 ms** in a suite | ≤ 60 ms | met idle; **missed in a suite, by 4.4 ms** |
| `harness-log.md` lines changed | – | – | **0** | 0 | met |
| helper restarts per stub run | – | – | **0** | 0 | met |

Against *before*: CPU −44.6 %, wall −37.6 %. Under a driver or a lane `treekey.mjs` is 9.7 ms through its helper. The wall is
8.1 s over its bound with node starts 37 over theirs, about 1 CPU-s of file 13: by exec count the remainder is git (7,569 per
file) and bash's forks, phase 4's ground.

Writing `main` found one bug the spec's own tail would have had: `process.stdout.write(out); process.exit(rc)` cuts a
piped answer at 65536 bytes when the reader isn't reading yet (`node big.mjs | (sleep 0.3; wc -c)` on node 24 printed
65536 for a 5 MB write, four runs of four), so `runCli` exits from the write's callback.

## Choice

### H1-01: `main(argv, io)` and `lib/cli.mjs`

- **Every served script exports `main(argv, io)`** returning `{ rc, out }`, writing nothing to `process.stdout`, never
  calling `process.exit`. `if (isMain(import.meta.url)) runCli(main);` is the one CLI tail, in `lib/cli.mjs` (a
  function, not the spec's inline block: one spelling, and the wait for the write in one place).
- **Output is captured by `main`'s return**, *default*: `captured(body)` gives the body `say` (`util.format`, what
  `console.log` prints, a number or a `null` included) and `put` (`process.stdout.write`'s raw bytes). Never a hook on
  `console.log`: a library's stray write would join the answer.
- **A throw is 70 with its stack on stderr**, *default*, in all eleven (`features.mjs` alone had it since C1; an
  uncaught throw in the others exited 1, which a caller can read as an answer: `passes`, `limit`, `validate`).
- **A throw's stdout is dropped**, *default*: buffering can't print half an answer, and a spawn then gives what the
  helper gives (rc 70, no `out`). Before, `summary trends` or `needs sweep` could print some lines and then die.
- **`io` is `{ cwd, env, stdin, isTTY, columns }`**; `runCli`'s are lazy getters, so a script that asks nothing starts no
  stdout stream and a deleted cwd stops only a `main` that reads it, as today.
- **The cwd comes from `io.cwd`**: `treekey.mjs`'s git, its stats and its `existsSync`. No other served `main` reads the
  cwd by name; a relative path in its arguments still resolves against the process's (H1-02's to answer).
- **Environment is read at call time from `io.env ?? process.env`**, *default*: `HARNESS_CHECK_KEY_IGNORE`,
  `HARNESS_CHECK_KEY_MAP` and git's environment (`treekey`), `MEMLINT_LINES`, `HARNESS_NOW` and `HOME` (`needs`), the
  `HARNESS_*` a prompt fills (`render`), the view's (`summary`, `needs`).
- **stdin comes through `io`**, *default*: `readStdin(io)` (`inbox.mjs insert`, `notify.mjs trim`) throws when the call
  has none, so a helper's request pipe is never read as a question's text.
- **The view's TTY comes through `io`**, *default*: `io.isTTY` and `io.columns`, so an answer never depends on where the
  helper's stdout goes.
- **A reader that has gone is no failure**, *default*: EPIPE ends the wait and the script exits its own `rc`, with
  nothing on stderr, as `console.log` ignored it (`process.stdout.write`'s callers used to die with a stack).
- **No module-level mutable state** in a served script (no module-level `let` or `var`, no filled container; the `/g`
  regexes are read by `matchAll` and `replace`, which don't keep `lastIndex`); `tests/unit/cli.test.mjs` greps for the
  `let` and `var` and for `process.argv|exit|cwd|stdout`, `console.log`, `readFileSync(0`.

**The eleven, *default*: all served.** Each has `main`, the shared tail and a test comparing `main` to its CLI:

| script | served | note |
|---|---|---|
| `features.mjs` | yes | top of the exec table |
| `metrics.mjs` | yes | |
| `treekey.mjs` | yes | `io.cwd`, `io.env` |
| `testcount.mjs` | yes | a CLI tail that ran at the module's top level is now a `main` |
| `entries.mjs` | yes | |
| `inbox.mjs` | yes | `insert` reads stdin through `io` |
| `memlint.mjs` | yes | `MEMLINT_LINES` from `io.env` |
| `render.mjs` | yes | `HARNESS_*` from `io.env` |
| `needs.mjs` | yes | `HARNESS_NOW`, `HOME` from `io.env`; `isTTY`, `columns` from `io` |
| `summary.mjs` | yes | `isTTY`, `columns`, the view's environment from `io` |
| `notify.mjs` | yes | `trim` reads stdin through `io` |

### H1-02: `lib/helper.mjs` and `ask`

**Measured on this box (2026-11-05, 92 exported names, one small list, `features.mjs summary`):** of a call's 3 ms,
`flock` is 0.9 ms (an exec) and the environment's enumeration 1 ms. H1-04 has the suite's numbers.

| 300 calls | wall | per call |
|---|---|---|
| `ask` | 927 ms | 3.1 ms |
| `x=$(ask)` | 1,126 ms | 3.8 ms |
| `HARNESS_HELPER=0 ask` (a spawn) | 9,845 ms | 32.8 ms |

**The reply and the request**

- **Length-prefixed framing**, *default*: `<id> <rc> <bytes>\n` and exactly `<bytes>` bytes, read by `read -r -N` under
  a local `LC_ALL=C`; no decoder process, and trailing newlines survive (`$( )` strips them as it does today).
- **A NUL in an answer: the helper declines it (rc 64) and `ask` spawns**, *default*: `read` drops a NUL, so no framing
  gets one into a bash variable. `main` has run by then and the spawn runs it again: the one served answer with NULs,
  `needs.mjs fields`, only reads.
- **rc 64 declines**, with no bytes: an unknown script, a malformed line, a failed `import`, a cwd that is gone, a
  stdin-fed call, a NUL. The caller spawns and the helper stays good. No served `main` returns 64; one that did would
  be spawned too, so the answer would still be the spawn's.
- **The id is `$SRANDOM`**, *default*, not the spec's counter: a counter in a `$( )` dies with it, so a parent would send
  the same id again, and a killed asker's reply left in the pipe would then pass the id check.
- **The cwd is `process.chdir(req.cwd)` per request**, *default*: a served `main` resolves a relative path argument
  against the process's, not `io.cwd`. Requests are one at a time, so nothing else sees it.
- **The request carries the whole exported environment**, *default*, the spec's `{id, script, args, cwd}` plus `env`,
  and the helper makes `process.env` equal to it per request (not only `io.env`: git started by `needs` and `overlap`
  inherits it). A list of the names the scripts read would go stale silently, and spawning when the environment differs
  from the helper's would spawn for every call once the driver exports anything after the start. The encoding is
  kept in the shell while names and values are the same; invalid UTF-8 in an argument decodes as in an argv (checked).
- **The names pass through a file in scratch**, *default*, `helper-<shell>.names` (no fork; names only, never a value,
  under the lock). Not in the lock file: a refused asker's open truncates that.
- **A stdin-fed call declines, with no table of subcommands**, *default*: `readStdin` throws `NoStdin` before `main`
  does anything, the helper declines silently, and the spawn gets the asker's stdin.
- **A TTY on `ask`'s stdout spawns**, *default*: the helper's `main` sees none, and `summary`'s and `needs`'s views
  colour by it. Off a TTY the two see the same.

**The lock, the timeout, the bound**

- **`flock -n` on `$HARNESS_SCRATCH/helper-<shell>.lock`**, *default*, from before the request to after the reply: a job
  of the same shell asking at that moment is refused and spawns; it never waits. A scratch directory that is missing
  or unset spawns.
- **`<shell>` is `$BASHPID` at source time, not the spec's `$$`**, *default*: two subshells that each source `record.sh`
  share a `$$` and would share one lock over two helpers.
- **Only the shell that sourced `record.sh` starts or replaces a helper**, *default*: a coproc started in a subshell dies
  with it. So a `$( ask )` before this shell has a helper spawns; `run_paths` starts it where the driver and the lane
  begin (H1-02b).
- **A `( )`, a pipeline's side and a job spawn**: bash closes the coproc's descriptors there and leaves the variables
  (5.2's manual, and file 91 on this bash), so `ask` tests `-p /proc/self/fd/<n>`, a stat and no fork.
- **`HARNESS_HELPER_TIMEOUT`, 120 s per read**, *default*, as the spec. A `main` slower than that (a writer included) is
  killed and spawned: it may run twice, the price of never hanging.
- **A request of 60000 bytes or more spawns**, *default*: the write is the one step with no timeout, and only a request
  that fits a pipe's empty 64 KB can't block on a helper that stopped reading.
- **A write to a dead helper is an error, not this shell's SIGPIPE**, *default*: `trap '' PIPE` around that one
  `printf`. Without it a helper dying between the check and the write would kill the driver.
- **Three restarts per process, then off**, *default*: failures 1 to 3 are `helper restarted: <why>`, the fourth
  `helper off: <why>` and `HARNESS_HELPER=0` for that process (four helpers started at most). A failure costs its call
  a spawn; the next call starts the successor. The tally is a file, `helper-<shell>.restarts`, one line per helper by
  pid: a `$( )` that met the failure can't tell its parent, and one death is one line however many shells see it.
- **The kill**: `kill -9` and `wait` in the owner; a plain `kill` in a subshell, whose parent reaps (no "Killed" on its
  stderr). `lib/helper.mjs` has no TERM handler, so TERM kills it even in a loop, the spec's "handles SIGTERM by
  exiting" by the default action. Only a pid bash still holds is killed: `HELPER_LIVE`'s may be another process's by
  then.
- **A helper keeps no inherited descriptor but 0, 1 and 2**, *default*: one started under `record` would hold the record
  lock (fd 9) for its whole life. Bash already sets the coproc's own pipes close-on-exec for children.

### H1-02b: the call sites, the lifecycle

**A served script's stderr goes where the call sends it.** Replaces H1-02's "the helper's stderr": the helper's fd 2 is a
file, `helper-<shell>.err` in scratch, and `ask` hands what a request left there to its own fd 2 before it prints the
answer, so `2> /dev/null`, `2>> run.log`, `2> "$err"` and `2>&1` all keep their destination, and `2>&1`'s order is the
spawn's (`main` writes stderr while it runs and its answer at the end). *Default*, because about 30 call sites redirect
it, `needs_sweep` (every coordinator poll) among them; a table of spawns would have kept most of the starts. A file, not
a hook on `console.error`: a git a script runs inherits it too. A declined request's stderr is dropped (the spawn says it
again); a failed helper's goes to the shell's stderr (a crash's last words). So a helper's own stderr lands where the
driver's or the lane's does, unless the call that met it redirected its own.

**The helper starts in `run_paths`**, after `load_config` (`HARNESS_HELPER=0` in a config file counts) and before
`f_models`: most call sites are `$( )`, which can't start one. The driver's and the lane's EXIT traps kill it
(`helper_stop`), the coordinator's before it writes `ended`; a SIGKILLed shell's helper ends on stdin's EOF.

**`check.sh` under a lane no longer spawns for its key or for an empty output's count**, *default*, beyond the spec's
"`check.sh` spawns": the spec's own numbers left it out. It is 17 `treekey.mjs` and 15 `testcount.mjs` starts of a stub
start's 52 with everything else wired, so the start's bound of 30 can't hold with both. The lane asks its helper for
what `check.sh` would ask first and passes it down (`HARNESS_CHECK_TK`, unset before anything else runs, so a suite and
a check.sh under it never see it). Nothing happens between the two but `check.sh`'s own start, and only from the tree's
top (`-e .git`), where `check.sh` takes the key. An empty suite output has no count, so it asks nothing (a stub suite's;
a real suite's output still spawns one, after the suite). A session's `check.sh` spawns as before.

**The call-site table.** `grep -n 'node ' lib/*.sh`, every served script; *default* for each "stays a spawn".

| call site | what | through |
|---|---|---|
| `record.sh` `F`, `Fv`, `f_memo`, `f_models`, `lanes_v` | `features.mjs`, behind the memo | `ask` |
| `record.sh` `MET`, `SUM` | `metrics.mjs`, `summary.mjs` | `ask` |
| `record.sh` `park_actions`, `driver.sh` the verify card's `actions` | `notify.mjs actions` | `ask` |
| `record.sh` `answers_v` | `inbox.mjs answers 2> /dev/null \| sha1sum` | `ask`: answered into a variable first (a pipeline's side spawns), its trailing newlines kept so the hash in `parked.json` doesn't change |
| `record.sh` `inbox_repair` | `inbox.mjs repair 2>> run.log`, its exit code 3 | `ask` |
| `record.sh` `take_question_` | `inbox.mjs question 2> /dev/null` | `ask` |
| `record.sh` `take_question_` | `inbox.mjs insert`, fed on stdin | **spawn**: only a spawn has the asker's stdin |
| `record.sh` the entry's `validate 2>&1`, `ingest`, `render 2>&1`, `pack > file 2> file` | `entries.mjs` | `ask` |
| `record.sh` `gotchas` | `memlint.mjs gotchas` | `ask` |
| `record.sh` `run_init`'s `--partial 2> /dev/null` in `< <( )`, `green_count`'s `testcount.mjs 2> /dev/null`, `--source`, `treekey.mjs` | | `ask` |
| `record.sh` `HARNESS_CHECK_KEY_IGNORE=… treekey.mjs --pathspec` in `< <( )` | environment on the call | `ask`: the request carries it (file 91) |
| `lane.sh` `red_names` `treekey.mjs 2> /dev/null`, `entries.mjs findings`, `session-files` | | `ask` |
| `driver.sh` finish's `treekey.mjs` | | `ask` |
| `driver.sh` `memlint.mjs` under `timeout 60` | a store on a hung mount | **spawn**: the 60 s is the point; a helper stuck there would hold every later question for its 120 s |
| `prompt.sh` `suite_length`'s `treekey.mjs`, `memlint.mjs store-line`, `render.mjs` with `HARNESS_*` on the call | | `ask` in a driver or lane (the request carries them; one over 60000 bytes spawns); run as a command (`lib/prompt.sh <state> …`) it has no helper and `ask` is a plain spawn |
| `needs.sh` `needs_open`, `needs_sweep` | `needs.mjs open`, `sweep 2>> run.log`, under `record` | `ask` |
| `needs.sh` `needs_notify` | `needs.mjs fields`: NULs | **spawn**: the helper would decline every one and pay twice |
| `notify.sh` `gh_url` | `notify.mjs urls 2> /dev/null` | `ask` in a driver or lane; `notify.sh` alone (`bin/harness`, `desk.sh`, `debrief.sh`) has a plain spawn under that name |
| `notify.sh` `notify_trim` | `notify.mjs trim`, fed on stdin | **spawn** |
| `check.sh` `treekey.mjs` | a child process of a lane, or a session's: it has no helper (a socket, rejected) | **spawn**, unless its parent asked: `check_run` in `record.sh` (`green`, `green_fast`, `run_init`) hands it the answer in `HARNESS_CHECK_TK` |
| `check.sh` `testcount.mjs` | | **spawn**, none for an empty output |
| `prompt.sh` as a command, `desk.sh`, `debrief.sh`, `eval.sh`, `bin/harness` | one question per process | **spawn** |
| `deploy.sh`, `backlog.mjs`, `page.mjs`, `eval.mjs`, `config.sh`'s `node -e` | not served | **spawn** |
| `record.sh` `ask` itself, `helper_start`; the plain `ask` of `prompt.sh` and `notify.sh` | the one spawn, and the helper's start | **spawn** |

A call on a pipeline's side or in a `( )` spawns whatever it names (`metrics.mjs final`, `summary.mjs ledger-line` in a
stub start): one start each, left as they are.

**A stub start's node starts: 336 helper off, 20 on**, 2026-11-05: 3 helpers, 10 of the stub's `node -e`, `overlap`, 2 of
`deploy`, `backlog`, `memlint` under its timeout, `metrics final`, `ledger-line`.

### H1-03: `treekey.mjs` takes tracked blobs from the index

**What one call costs** (`strace -c -f`, `--cpu-prof`, this repo, 1,224 tracked files; the helper does not remove any of
it): of the 33 ms above node's own start, the most is `spawnSync` waiting on `hash-object` over every file the key
covers, the rest the second git and a `stat` per file. Node's start is the helper's to take; the second git and the
hashing are this cut's.

**The cut**, *default* for the spec's three git calls: **one `git ls-files -z -v --stage -c -m -o --exclude-standard`**
gives each file's tag, mode, blob and stage, a `C` line for what is edited or gone (git's own stat check, racy timestamps
included) and `? <path>` for what is untracked. `hash-object --stdin-paths` runs once, only for the rest, and not at all
on a clean tree. `parseListing` is the pure part. `-v`, not `-t`: it marks assume-unchanged too.

**What keeps a hash-object, because the index can't vouch for it**, *default* for each: a link (the index holds the
target's name, hash-object follows it to the content, and a link to a directory or nowhere is no file); a gitlink; a
conflict's stages (one row per stage, as `-co` lists them); an assume-unchanged or skip-worktree entry (`git status`
doesn't look at them, the key always has); a path that isn't valid UTF-8 (the decode loses it, the stat drops it, as
before).

**Below the repo's top there is still no key**, *default*: `hash-object --stdin-paths` reads from the top while `ls-files`
lists from the cwd, so it always failed there and `check.sh` read that as "the full run, no marker". An index blob would
have turned it into a key of that subdirectory's files alone, which a marker could then trust. With no `.git` in the cwd
every row is hashed, the old path exactly.

**Trusting the index is trusting `git status`.** A same-size edit with its mtime put back is still caught (ctime; a test).
What `core.trustctime=false` would miss, `git status` misses too.

**A file committed un-normalized has a different key from before, once**, *default*, left as it is: under `text=auto` a
CRLF blob in the index stays that blob (`git status` calls it clean), where the old hash-object normalized it. The new key
is stable and moves on an edit, so the price is one suite rerun on such a tree. Checked on a throwaway repo; a clean filter
keeps its key.

**Measured** (2026-11-05, this repo, median of 20, `HARNESS_CHECK_KEY_IGNORE` as this repo sets it; "above idle" takes off
`node -e 0`; "in process" is `main` called directly, a helper's cost):

| tree | load | `node -e 0` | before | after | above idle, before → after | git per call | in process, before → after |
|---|---|---|---|---|---|---|---|
| clean, index written since the checkout | 1.37 | 27.6 ms | 59.1 ms | 49.8 ms | 31.5 → 22.2 ms | 2 → 1 | 17.3 → 6.3 ms |
| one edit, one untracked file | 1.50 | 25.7 ms | 60.7 ms | 52.8 ms | 35.0 → 27.1 ms | 2 → 2 | 17.4 → 8.3 ms |
| this worktree, two edits | 1.54 | 27.6 ms | 60.2 ms | 53.2 ms | 32.6 → 25.6 ms | 2 → 2 | 18.2 → 8.6 ms |
| fresh checkout, index in the files' second | 1.32 | 24.9 ms | 58.3 ms | **139.0 ms** | 33.4 → **114.1 ms** | 2 → 1 | 17.4 → **94.9 ms** |

**The target, under 60 ms per call: met** on every tree a run spends its time on, and it was already met on an idle box
(the spec's 193 ms was the loaded one; H1-04 has the suite's number). **Missed, 139 ms, on a fresh checkout until the index
is next written.** Stock git compares the index's timestamp to a file's mtime by the second, so a checkout that lands in
the index's second is racily clean and `-m` reads every file, those the pathspecs leave out as well (the listing applies
them after the check). The next index write ends it (`git status` writes one, as does a slot's `update-index` in
`lib/record.sh`, a session's first `git add`). About 80 ms once or twice per worktree, against 11 ms saved on each of 205
calls per large file.

## Rejected

Filled in by H1-05 from the spec's list. For H1-01: hooking `console.log` (above); the spec's inline tail in each script
(it cuts a pipe at 64 KB, and eleven copies of the fix); top-level `await` in the tail (`runCli` returns a promise
nobody needs to wait on, so no served module is an async module). For H1-02: the spec's `$$` and counter id (above); a
table in `ask` of the subcommands that read stdin (a new one would silently read as a throw; `NoStdin` needs no table);
`mapfile < <(compgen -e)` (a fork, 1.7 ms against 0.2 ms through the file). For H1-03: `git update-index --refresh` before
the listing (it ends the racy case, but a question would then write the index and take `index.lock`, which can fail a
session's `git add`); the spec's separate `--stage` and `--modified` calls (a second git for what one prints); `git diff-files`
for the stale rows (a second git, and the same racy read: 94 ms on the fresh checkout).
