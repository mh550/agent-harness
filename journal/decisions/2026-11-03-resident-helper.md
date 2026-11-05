# The resident helper: one warm node process per driver and lane answers the `.mjs` questions over a coproc

*(2026-11-05, run `agent-harness-2026-11-05`, milestone H1; spec `docs/specs/2026-11-03-resident-helper.md`; plan
`docs/plans/2026-11-03-test-suite-redesign.md` phase 2; begun by H1-01, each later feature adds its part)*

## Finding

93 % of a large check file's 3,139 node starts are the driver's and its lanes' (49 % of the file's CPU;
`findings-and-research/2026-11-03-redesign-baseline.md` §2), and most call sites are `$( … )` subshells no memo can
serve. The measured table is H1-04's.

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
  with it. So a `$( ask )` before this shell has a helper spawns; H1-02b starts it (`helper_start`) where the driver
  and the lane begin.
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

## Rejected

Filled in by H1-05 from the spec's list. For H1-01: hooking `console.log` (above); the spec's inline tail in each script
(it cuts a pipe at 64 KB, and eleven copies of the fix); top-level `await` in the tail (`runCli` returns a promise
nobody needs to wait on, so no served module is an async module). For H1-02: the spec's `$$` and counter id (above); a
table in `ask` of the subcommands that read stdin (a new one would silently read as a throw; `NoStdin` needs no table);
`mapfile < <(compgen -e)` (a fork, 1.7 ms against 0.2 ms through the file).
