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

## Rejected

Filled in by H1-05 from the spec's list. For H1-01: hooking `console.log` (above); the spec's inline tail in each script
(it cuts a pipe at 64 KB, and eleven copies of the fix); top-level `await` in the tail (`runCli` returns a promise
nobody needs to wait on, so no served module is an async module).
