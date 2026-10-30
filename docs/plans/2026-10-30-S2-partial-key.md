# S2 · The declared partial map: a change to a mapped path runs only the checks that read it: plan

Spec: `docs/specs/2026-10-30-suite-time.md` §S2 (choice 1–8, its checks, S2-review). This file is S2-01. S2-02 builds
`CHECK_KEY_MAP` and `treekey.mjs --partial`; S2-03 the sidecar and the partial run in `lib/check.sh`; S2-04 the lint and
this repo's final map, with the decision file; S2-05 the driver (`run_init fresh`) and the stub runs; S2-06 reviews it
and writes `docs/architecture.md` and `README.md`. Sites are named by function and file as the code stands at
`adadbce` (S1 merged). Nothing here changes code, so the suite is as the init left it (1044 tests, green).

**The invariant S2 keeps** (spec, *Rules*), within the key: a path under `CHECK_KEY_IGNORE` is out of it before S2
(`37` and `39` read `journal/decisions`, which this repo ignores, so a decision file alone reruns neither: the spec's
*Not in this run*; the decision file repeats it). a tree is never marked green by anything but a green run of every check that
reads what changed in it. The argument, which every condition below serves: the reduced keys equal ⇒ every path in the
key outside the map has the reference tree's content; the reference tree was green in a **full** run (only a full run
writes a sidecar); the mapped paths that differ are *S*; the map names every check file that reads a mapped path (the
lint proves it); so `names(S)` is every check whose input changed. Anything that breaks a link runs in full.

## 1. `treekey.mjs` (S2-02)

Today `lib/treekey.mjs` is a 24-line script: `ignore`, `spec`, the `--pathspec` mode, then `files`, `blobs` and the
hash at top level. It becomes exported pure functions plus a CLI guarded the way `lib/eval.mjs:339` is
(`if (process.argv[1] && fileURLToPath(import.meta.url) === resolve(process.argv[1])) …`), so
`node --input-type=module -e 'import {…} from "<abs>/lib/treekey.mjs"'` runs no git.

| Export | Pure | What |
|---|---|---|
| `ignoreList(env)` | yes | today's `ignore` from `HARNESS_CHECK_KEY_IGNORE` (`prefix`, `ok`, `.harness/runs` first) |
| `parseMap(str, ignore, isDir)` | yes (`isDir` passed in: the CLI's is `statSync(p).isDirectory()`, false when absent) | `{entries: [{path, names}], dropped: [<stderr line>]}`, below |
| `treeKey(files, blobs)` | yes | today's hash: sha1 over `${f}\0${blob}\n` in the sorted file order, first 16 hex |
| `partialKeys(files, blobs, entries)` | yes | `{full, reduced, lines}`: `full = treeKey(files, blobs)`; `reduced = treeKey` of the pairs whose file is no entry's path; `lines` = one `<blob> <path>` per entry in map order, `-` for a path not in `files` |
| `mapNames(entries, paths)` | yes | the union of the names of the entries whose path is in `paths`, in map order (entry order, then name order, first occurrence kept); `null` when a path is no entry's |

**`parseMap`.** `str` is `HARNESS_CHECK_KEY_MAP`, entries split on whitespace, each `<path>:<name>[:<name>…]` split on
`:`. The path goes through today's `prefix()` (`./CLAUDE.md` is `CLAUDE.md`, a trailing `/` stripped but remembered).
An entry is **dropped**, with one stderr line `treekey: CHECK_KEY_MAP entry <entry> dropped: <why>`, when:

| Why | Test |
|---|---|
| `no check name` | no non-empty name after the path (`CLAUDE.md`, `CLAUDE.md:`, `CLAUDE.md::`) |
| `not a path in the tree` (*default*, the spec's three plus `ok()`'s own rule) | `!ok(path)`: empty, `.`, absolute, or a `..` segment |
| `under the ignored prefix <p>` | `path === p` or `path.startsWith(p + "/")` for a `p` of `ignore` (it is out of the key already) |
| `a directory` | the entry ended in `/`, or `isDir(path)` |

Empty names inside a kept entry are filtered (`CLAUDE.md:a::b` is `a b`). A **duplicate path** (*default*): its names are
merged into the first entry's, which keeps its place: dropping the second would drop its names, and a name lost is a
check not run. Without an entry kept, the result is as without a map.

**The CLI** (`HARNESS_CHECK_KEY_MAP` from the environment; the driver exports it, §4):

- bare: unchanged, one line, `treeKey(files, blobs)`. It does not parse the map (no stderr from a bad entry on every
  `$(node treekey.mjs)` call): `run_init` and the stub hooks keep calling it.
- `--pathspec`: unchanged.
- `--partial`: line 1 `full`, line 2 `reduced`, then `lines` (the dropped lines on stderr). Without a map (empty, or
  every entry dropped) lines 1 and 2 are equal and nothing follows. Line 1 equals the bare call's on the same tree:
  the full key never depends on the map.
- `--names <path>…` (*default*, a fourth mode the spec doesn't name): `mapNames` on the parsed map, one line,
  space-separated; exit 1 and no line when a path is no kept entry's. It is how `check.sh` turns *S* into arguments
  with the one parser (no second, bash, reading of the map that could disagree on `./`, a duplicate or a drop), and
  its exit 1 is condition 9 of §3.

The usage header names `--partial`, `--names` and `HARNESS_CHECK_KEY_MAP`. The `git hash-object` blobs are the ones the
full key already computes; no second git call.

## 2. The sidecar `part-<reduced>` (S2-03)

Written by `check.sh`'s full form after a **green full run** (a first-run green or a flake), beside `green-<full>`, in
the same atomic way (`> "$cache/.part-$$" && mv -f … "$cache/part-$reduced"`), when the map has a kept entry:

```
<full key of this green tree>
<blob> <path>        one per kept entry, map order: treekey --partial's lines 3…, verbatim
```

Never written: by a red full run (an older sidecar for the reduced key stays: it still names a green tree), by a
partial run (so a reference is always a full-run tree: any mapped path differing from *it* runs its files), without a
map (*default*: other projects' caches stay as they are), or with an empty key.

## 3. `check.sh`'s full form: the conditions, in order (S2-03)

The key line (`lib/check.sh:71`) becomes one call: `part=$(node "$here/treekey.mjs" --partial 2>/dev/null)`, `key` its
line 1, `red` (the reduced key) its line 2, the rest the blob lines. Each row below is tried in order; the first that
holds decides. Rows 1–3 are today's; rows 4–10 are the partial path, placed after the `red-<key>` branch
(`lib/check.sh:78–86`) and before `rm -f "$scratch/check-rerun.out"` (line 87). **Every row of the partial path that
holds falls through to the full run**; only row 11 runs a partial.

| # | Condition | What runs |
|---|---|---|
| 0 | arguments given (the subset form) | the subset, as today: exits at line 68 before any key, map, sidecar or marker is read |
| 1 | `key` empty (treekey failed) | the full run, no marker, as today |
| 2 | `green-<key>` present | the cached green, as today |
| 3 | `red-<key>` present | the cached red, as today |
| 4 | no map: `HARNESS_CHECK_KEY_MAP` blank, or `--partial` printed no line 3 (every entry dropped) | full run |
| 4a | the tree's own map is not the exported one: `CHECK_KEY_MAP` after sourcing the tree's `.harness/config.sh` in a subshell with it unset (empty when the file is absent or doesn't set it; whitespace collapsed) differs from `HARNESS_CHECK_KEY_MAP` (*default*; review finding) | full run: the driver loads the config at its start (`lib/lane.sh:45`, `lib/driver.sh:403` after a main merge), so a session that changes this repo's map (or deletes its line) leaves the exported map stale, and a map from the user config or `run.env` is linted by nothing; the lint proves the **tree's** map, so only that map may choose a subset. The stub runs put their map in the throwaway project's `.harness/config.sh` |
| 5 | `part-<red>` absent | full run |
| 6 | its line 1 not 16 hex, or `green-<line 1>` absent (the reference gone: a `run_init fresh`, a scratch-less cache) | full run |
| 7 | its path set ≠ the map's: the paths of its lines 2… (sorted) differ from the paths of `--partial`'s lines 3… (sorted), or a line is not `<blob> <path>` (`<40 hex or -> <path>`) | full run (the map grew, shrank or renamed an entry since the reference) |
| 8 | *S* empty: no mapped path's blob differs (only a hash collision or a hand-planted sidecar gets here: the full key would equal line 1, row 2) | full run |
| 9 | `node treekey.mjs --names <S>` exits non-zero (a path of *S* is no entry's: can't happen after row 7; checked anyway) | full run |
| 10 | its line is empty (no name: `parseMap` drops such an entry, so can't happen; checked anyway) | full run |
| 11 | otherwise | **the partial run**: `run "$cmd \"\$@\"" _ <names>` (the subset form's way: names as arguments, never spliced), under the same scope, cap and timeout, output to `$scratch/check-partial.out` |

*S* is computed in bash from the two blob lists: for each path, the sidecar's blob against `--partial`'s; a `-` on
either side that the other lacks is a difference.

**The rerun guard on a partial** (as a full run's, on the subset): a red whose `why` is `exit <rc> after …` (not a
timeout, not a cap kill) is rerun once per `CHECK_RERUN`: `auto` the `HARNESS_FAILED=` names, else the partial's names
again; `failed` the names only; `suite` the partial's names again (*default*: a partial's "whole suite" is its subset;
a full run is not what the guard is for); `off` none. The rerun's output goes to `$scratch/check-partial-rerun.out`
(*default*, where the spec says `check-rerun.out`: `check.sh:87` keeps a `check-rerun.out` with the `check.out` it
belongs to, and both stay the last full run's). Every output name here matches `check-*.out`, so the next full run's
`find … -delete` (line 90) clears them, and `lib/driver.sh:315` copies them back with a lane's scratch.

**What a partial writes.**

- **Green** (first run or rerun): `green-<key>` with the **reference's two lines** (`cp "$cache/green-$ref"` to
  `.green-$$`, then `mv -f`: the reference's count and wall, never the partial's subset count or seconds),
  `rm -f "$cache/red-$key"`; no `part-`, no `check.out`, no `check-<key>.out` (every count the driver reads is a full
  run's: `green_count` reads the marker first; a reference whose line 1 is empty, an older or planted marker, gives
  an empty one, which the driver reads as today's unknown count). The line:
  - `check: green (partial: <names>, <s> s; cached for the rest)`;
  - after a rerun: `check: green after a rerun (partial: <names>; flaky: <failed names, else the partial's names>), <n>`
    with `<n>` the reference's line 1 (`<n> tests`; nothing when it is empty), and one `flakes.jsonl` row:
    today's keys plus `partial: [<names>]`, `rerun` `failed` or `partial`, `names` the `HARNESS_FAILED=` names, else
    the partial's names (*default*: never empty, so `lib/summary.mjs:flakes` and `_flakes_note` never read a partial
    flake as "whole suite").
- **Red**: `check: RED (partial: <names>; <why>[; red again on a rerun of <names>]) — last lines of <out>:` and
  `tail -25` of the last run's output, exit the last run's code; **no marker of either kind** (*default*, the spec's:
  the red marker is for a 900 s run, a partial is seconds). A timeout or cap kill is said as `why` says it, no rerun,
  no marker.
- `row partial` in `check-runs.log` for every partial run (green or red). `lib/lane.sh:329` counts every non-`cached`
  row as a run, so a session's "suite ran" note counts it, which is right: it ran.

A **full run**, unchanged otherwise, writes `part-<red>` (§2) on green, after `green-<key>`. The usage header names
`part-<key>`, `check-partial.out`, `check-partial-rerun.out`, `CHECK_KEY_MAP` and the `partial` row.

## 4. Config and the driver

- **`lib/config.sh`** (S2-02): `CHECK_KEY_MAP=""` beside `CHECK_KEY_IGNORE` in `harness_config`'s defaults, with a
  comment: `<path>:<check>[:<check>…]` entries; a change to such a path alone runs only those checks.
  `HARNESS_CONFIG=/dev/null harness_config /nonexistent` leaves it empty.
- **This repo's `.harness/config.sh`** (S2-02): `CHECK_KEY_MAP="CLAUDE.md:39-memlint-m4:37-memory-prompts-m2"`; S2-04
  extends it to the lint's final form (§5). `tests/run.sh` matches by substring, so each name is a file's full stem
  (`75-suite-tools`, not `75`: `75-merge-sorted` shares the number).
- **`lib/prompt.sh` `prompt_env`** (line 48): `HARNESS_CHECK_KEY_MAP=$CHECK_KEY_MAP` beside
  `HARNESS_CHECK_KEY_IGNORE`.
- **`templates/project/config.sh`** (S2-02): `# CHECK_KEY_MAP="CLAUDE.md:<check>"` under `# CHECK_KEY_IGNORE`, one line:
  an entry is a file only check-file lines read (not the code under test, not a shared test helper) and every check file that reads it; a check that reads it and isn't listed lets a stale green
  through, so the project's suite needs a lint that proves the list (this repo's `82-key-map-lint`).
- **`lib/record.sh` `run_init fresh`** (S2-05, line 458): `rm -f "$STATE/green/green-$key" "$STATE/green/red-$key"`
  gains `"$STATE/green/part-$red"`, with `red` line 2 of `node "$HARNESS_HOME/lib/treekey.mjs" --partial` run once
  for both (the existing `key=$(node … treekey.mjs)` call, line 453, becomes that call's line 1). Without the removal the verify's
  run on a tree differing from its reference in mapped paths alone would be a partial run, and
  `decisions/2026-10-26-verify-runs-the-suite` says the verified tree runs in full. The `(( rc || prev ))` line, the
  post-session `green()` (`lib/record.sh:79`) and `lib/lane.sh` don't change (`git diff main -- lib/lane.sh` empty):
  a partial green is `check.sh` exiting 0, and a partial red is a red.
- **Visible** (spec 7, *default*): no new `harness-log.md` note; the partial's line is in `init.out` and so in the next
  prompt's *Init output*.

## 5. The lint (S2-04): `tests/checks/82-key-map-lint.sh`

A function in the check file, `keymaplint <checks dir> <map>`, prints one line per miss and nothing when the map is
complete; the checks call it on copies and on `$HERE/checks` with this repo's map, read through
`harness_config "$HERE/.."` (an allowed form). For each kept entry `<path>:<names>` (`p` and its basename `b`) and each
`*.sh` in the directory whose stem no name of the entry matches as a substring (as `tests/run.sh` would), each line is
tested against two rules; a hit is `<file>:<line> reads <p>, not in CHECK_KEY_MAP`.

**Root expressions** `R` (where the spec's rules say `$HERE/..`), widened because S1 added a form the spec's rules miss:

- `$HERE/..`, `${HERE}/..`, `"$HERE"/..`, `'"$HERE"'/..` (the `node -e` idiom of `12-journal-pure-e4-entrys.sh:122`),
  `$(dirname "$HERE")`, `${HERE%/*}`;
- `$HH`, `${HH}`: `tests/lib.sh:87` sets it to the repo root for every check file;
- `$(cd "<R>" && pwd)` and `$(readlink -f "<R>")`: the spec's allowed forms 5 and 3, read as what they are, the
  root canonicalized (as allowed forms, `ROOT=$(readlink -f "$HERE/..")` then `grep x "$ROOT/CLAUDE.md"` escaped
  both rules: review finding);
- `$HARNESS_HOME`, `${HARNESS_HOME}`, `$(dirname "$0")/../..`, and any `$(…)` holding `rev-parse --show-toplevel`
  (*default*, review finding: forms no check uses today, each another name for a checkout's root; free to include);
- `$v`, `${v}` for each **alias** `v` of the file: a name assigned exactly an `R` anywhere in the file
  (`[local ]v=<R>` followed by a space, `;`, `)`, a quote or the end of the line): `37`'s `r=$HERE/..`, `79`/`80`'s
  `HH=$(cd "$HERE/.." && pwd)`. File-wide, not "on that line" as the spec has it: `79-suite-length.sh:87` reads
  `"$HH/CLAUDE.md"` on a line that sets nothing, and the spec's rule passes it. Over-approximate on purpose: a loop
  variable sharing an alias's name (`37:47`'s `for r in …`) counts too.

**Rule (a), names the path.** A line holds an `R` and names `p` or `b` (fixed string), or names `../<b>` (any depth of
`../`, with or without an `R`: a relative read after a `cd` into `tests/` or a subshell's `cd "$HERE"`). The allowed
forms don't apply: `git -C "$HERE/.." show HEAD:CLAUDE.md` reads it. Full-line comments are skipped (sound: a comment
runs nothing).

**Rule (b), passes the root bare.** After the allowed forms are cut out of the line, an `R` is left that is not followed
by `/` (the spec's quote, space, `)` or end of line, widened to anything but `/`: `|`, `;`, `}` end a word as well).
The **allowed forms** (each says why it reads no memory file; they live in the check file as a list with that line):

| Form | Why |
|---|---|
| `HARNESS_HOME=<R>`, `HARNESS_HOME=${X:-<R>}` | the harness run from this checkout reads its `lib/`, `prompts/`, `templates/`, `bin/`, never its own repo's `CLAUDE.md` |
| `git -C "<R>" <log\|rev-parse\|cat-file\|worktree\|ls-files>` | git metadata and names, never a work-tree file's content (today: 5 `log`, 2 `worktree`, 1 `ls-files`). `git -C "<R>"` with any other subcommand (`grep`, `diff`, `show`, `status`) is a hit: those read the work tree (review finding) |
| `harness_config "<R>"` | `.harness/config.sh` only |
| an alias assignment `[local ]v=<R>` (`<R>` including `$(cd "<R>" && pwd)` and `$(readlink -f "<R>")`) | a string; the alias's uses are linted in turn. The spec's `(cd "$HERE/.." && pwd)` used inline as an argument is now a bare root (it is one) |
| `== "…<R>"` with `…` free of quotes, `$(` and backticks (*default*, a sixth form the spec doesn't list) | the right side of a `[[ … == … ]]` is a string no command reads: `13-run-2-michael-sets-desk.sh:386`'s `$(tail -1 "$A") == "PWD=$HH"` (13 is 205 s under load; mapping it for a string compare is the wrong cost) |

**On today's tree** (prototyped in scratch over `tests/checks/` with `CLAUDE.md`):

| File | Rule | Line(s) | Reads |
|---|---|---|---|
| `37-memory-prompts-m2.sh` | (a), (b) | 59, 64, 65 (a); 47, 48, 66 (b, the alias `r`) | `CLAUDE.md`, the decisions store |
| `39-memlint-m4.sh` | (b) | 58 (`$M "$HERE/.."`) | `CLAUDE.md` and the store |
| `79-suite-length.sh` | (a) | 87 (`"$HH/CLAUDE.md"`) | `CLAUDE.md`: S1-02's static check (not in the spec's list) |
| `36-run-16-retro-backlog.sh` | (b) | 20, 21, 30 (`cd "$HERE/.." && $H backlog import`) | the state root and a seed |
| `75-suite-tools.sh` | (b) | 69 (`cd "$HERE/.." && bash tests/lint-sleeps.sh`) | `tests/` |

Without the sixth form `13:386` is a sixth hit; nothing else is. **The final map** (*default*, the spec's: a found file
joins the map rather than the allow-list growing per command):
`CHECK_KEY_MAP="CLAUDE.md:39-memlint-m4:37-memory-prompts-m2:79-suite-length:36-run-16-retro-backlog:75-suite-tools"`.
The cost: the five files are about 290 s of check time under load (from S1's suite output: 42 + 64 + 50 + 109 + 29),
run `TEST_JOBS` at a time, against a full run's 600–900 s; the spec's "about 30 s" for joining 36 and 75 is 138 s by
these figures, which tips the trade toward rewriting their lines. S2-04 may instead rewrite `36`'s and `75`'s lines to run
from a path that is not the bare root (the lint then proves it) and records which it did per file in the decision file.

**Not linted** (*default*, the spec's scope is `tests/checks/`): the shared helpers `tests/lib.sh`, `tests/stub-*.sh`,
`tests/run.sh`. Every check file reads them, so a hit there can't be mapped; today none names `CLAUDE.md` beside a root
expression (their `CLAUDE.md` is the stub project's, in its cwd), and their own `$HERE/..` uses are `git -C` and the
`HH` alias. Every check file starts in the throwaway project (`tests/lib.sh:34`, `cd "$T/proj"`), so a relative path
reaches the repo only after a `cd` into it: into the root is rule (b), into a subdirectory (`63:10`'s
`cd "$HERE/../prompts"`, `75-merge-sorted:34`'s `cd "$HERE"`) is followed by `/` or not an `R`, and a later
`../CLAUDE.md` is rule (a)'s `../<b>`. A bare `..` argument after such a `cd` is not linted (*default*: the rule hits
four strings and comments today, `08:532`, `34:18`, `51:50`, `77:28`, and none of them reads anything).

**What the lint proves, and what it doesn't** (review finding; the decision file and the template say it): that no
check file's own lines read a mapped path through a root expression it knows. It can't see a read by the code under
test (`lib/`, `bin/`) or by a helper every check sources (`tests/*.sh`), nor a root built some other way (an
adversarial file can always hide one). So a map entry is only for a file that nothing but check-file lines read
from this checkout: `CLAUDE.md` here (the harness's code reads a *project's* `CLAUDE.md`, the stub project's in the
suite, never its own; `grep -rn 'HARNESS_HOME/CLAUDE' lib bin prompts` prints nothing; `bin/harness:193` copies `templates/project/CLAUDE.md`). The template's comment says
an entry is such a file.

**82 itself.** Its negative fixtures (`grep x "$HERE/../CLAUDE.md"`, `mytool "$HERE/.."`) would be hits on 82's own
lines if written inline: they live in `tests/fixtures/key-map-lint/` (`reads-claude.sh`, `bare-root.sh`, one
`allowed-<n>.sh` per allowed form), copied into the copy of `tests/checks/` by each case.

## 6. The checks, by feature

| Feature | File | What it adds |
|---|---|---|
| S2-02 | `tests/checks/81-partial-key.sh` (new) | the treekey cases on a throwaway repo, the exported functions, the config default |
| S2-03 | `81-partial-key.sh` | the check.sh cases, with an argument-recording stub suite |
| S2-04 | `tests/checks/82-key-map-lint.sh` (new), `tests/fixtures/key-map-lint/` | the lint on copies and on this repo |
| S2-05 | `81-partial-key.sh`, `tests/stub-claude.sh` (`STUB_GOTCHA_ONLY=<id>`) | the two stub runs |

**81, treekey (S2-02).** A throwaway repo `pk` as `34-check-key.sh`'s `ky` (`git init`, `CLAUDE.md`, `README.md`,
`lib/a.sh`, `docs/plans/p.md`, one commit); `pk() { ( cd "$T/pk" && HARNESS_CHECK_KEY_MAP=$1 node "$HERE/../lib/treekey.mjs" "${@:2}" ); }`;
map `M="CLAUDE.md:memlint README.md:readme"`.

- `pk "$M" --partial` before and after `echo x >> CLAUDE.md`: line 1 (16 hex) differs, line 2 equal, lines 3–4 are
  `<blob> CLAUDE.md` then `<blob> README.md` and only line 3 differs;
- `CLAUDE.md:memlint gone.md:g`: line 4 is `- gone.md`;
- `pk "" --partial`: two equal lines, nothing more; `pk "$M"` (bare) is one line equal to `--partial`'s line 1;
- dropped entries, one stderr line each, keys as with `$M` alone: `docs/plans/p.md:x` (`under the ignored prefix
  docs/plans`, with `HARNESS_CHECK_KEY_IGNORE=docs/plans`), `lib:x` and `lib/:x` (`a directory`), `README.md` and
  `README.md:` (`no check name`), `/etc/x:y` (`not a path in the tree`); stdout byte-equal to `$M`'s;
- `CLAUDE.md:a CLAUDE.md:b` → `--names CLAUDE.md` prints `a b`; `--names README.md` with `$M` prints `readme`,
  `--names x.md` exits 1;
- the pure functions by `node --input-type=module -e` on a fixed list (`["a","b","c"]`, blobs `["1…","2…","3…"]`):
  `partialKeys` with no entries has `full === reduced`, with entry `b` has `reduced === treeKey(["a","c"], …)` and
  `lines` `["2… b"]`, with entry `z` (absent) `lines` `["- z"]`; `parseMap`'s `dropped` count per bad entry (with an
  `isDir` stub); `mapNames`' map order and its `null`;
- `( source lib/config.sh && HARNESS_CONFIG=/dev/null harness_config /nonexistent && [[ -z $CHECK_KEY_MAP ]] )`;
  `harness_config "$HERE/.."` gives this repo's value; `grep -c HARNESS_CHECK_KEY_MAP lib/prompt.sh` is 1;
  `grep -q '^# CHECK_KEY_MAP=' templates/project/config.sh`.

**81, check.sh (S2-03).** One stub suite `$T/pk-suite.sh` in the shape of `73-check-rerun.sh`'s `rr-suite.sh` (a case
directory per case, `PK=$T/pk-<case>`: counter `n`, every call's arguments in `args`, each output in `out<n>`) that
prints what `tests/run.sh` prints: per argument `PASS <a>` and `<k>/<k> checks passed`, bare `PASS t1`, `PASS t2`,
`2/2 checks passed`; `PK_RED=<name>` makes a call whose arguments include it (or the bare call) print `FAIL <name>`,
`HARNESS_FAILED=<name>`, exit 1; `PK_RED_ONCE=1` only on its first such call. `pc() { (cd "$T/pk" && PK=… HARNESS_SCRATCH=$T/pk-$1/s HARNESS_CHECK_CACHE=$T/pk-$1/c HARNESS_CHECK_KEY_MAP=$M HARNESS_CHECK_CMD="bash $T/pk-suite.sh" "$HERE/../lib/check.sh" "${@:2}"); }`.
The repo is reset (`git checkout -- . && git clean -fdq`) between cases; each case has its own cache.

- green full run: `green-<full>` is `2 tests` / `wall N`; `part-<reduced>` is the full key then the two blob lines;
- `CLAUDE.md` diff: `args` line 2 is `memlint`; output `check: green (partial: memlint, <s> s; cached for the rest)`,
  exit 0; `check-partial.out` has `PASS memlint`; `check.out` still the first run's (`cmp` with `out1`); `green-<new>`
  byte-equal to `green-<old>`; the next call `check: green (cached for this code tree, 2 tests)`, counter unchanged;
  `check-runs.log` has a `partial` row;
- `lib/a.sh` diff: `args` empty (full); both mapped paths: `memlint readme`;
- `PK_RED=memlint`: `args` lines `memlint`, `memlint`; `check: RED (partial: memlint; exit 1 after <s> s; red again on a
  rerun of memlint)`, exit 1, no `green-<new>`, no `red-<new>`; with `PK_RED_ONCE=1`: one `flakes.jsonl` row with
  `partial == ["memlint"]`, the line `check: green after a rerun (partial: memlint; flaky: memlint), 2 tests`;
- `rm` the reference `green-<old>` → full; a map `CLAUDE.md:memlint README.md:readme SPEC.md:spec` after a green under
  `$M` → full (path sets differ); a partial green writes no `part-` (the `part-*` list unchanged);
- `pc <case> memlint` on the diffed tree: `args` `memlint`, no `partial` in the output, no new marker;
- `HARNESS_CHECK_TIMEOUT=2s` with a `PK_HANG=memlint` that sleeps (`# sleep-ok`): `timed out after 2s` in the line, one
  call, no marker.

**81, stub runs (S2-05)**, with the counting `CHECK_CMD` of S1 (`79`/`80`'s `cs.sh`, extended to print a `PASS` per
argument) in the run's `run.env`, `CHECK_KEY_MAP="CLAUDE.md:memlint"` in the run's config:

- both runs set the map in the throwaway project's `.harness/config.sh` (committed before `harness start`), not
  `run.env`: row 4a runs any other in full;
- `pkedit`: `STUB_EDIT=CLAUDE.md` (as `34`'s `kyplan`): the second session's saved `init.out`
  (`$T/init-pkedit-2.out`) has `check: green (partial: memlint,`; `cs-pkedit.log` has a no-argument line, then one
  `memlint` line with the edited tree's key; `tests-end` equals `tests-start` (`2`).
- `pkverify`: `STUB_NO_RED=1 STUB_GOTCHA_ONLY=C` (new stub hook: C's first coding session passes with the Gotchas line
  as its only change, no `work-C.txt`), so the post-session `green()` on C's tree is a partial (its key's `cs` line is
  `memlint`). Then `harness-log.md` has `verify M1: suite cache cleared; the suite runs in full on the verified tree`,
  and `cs-pkverify.log` has a no-argument line with that key after the `memlint` one. *The state dir's `green/` has no
  `part-` for that reduced key afterwards* (S2-05 step 2) can't hold as written: the verify's own full green writes
  `part-<reduced>` again. The check reads it as S1's plan §9 read its marker: `part-<reduced>`'s line 1 is the
  verified tree's key (the verify's full run's), not the pre-C tree's.

**82 (S2-04).** A copy of `tests/checks/` in `$T/lc`; with `reads-claude.sh` copied in, `keymaplint "$T/lc" "$MAP"`
prints `reads-claude.sh:<n> reads CLAUDE.md, not in CHECK_KEY_MAP` (and fails the check the way a real miss would);
with `bare-root.sh` the same for its line; with the map extended by `reads-claude` and `bare-root`, nothing; each
`allowed-<n>.sh` alone, nothing; on `$HERE/checks` with the committed map, nothing.

Every new check name goes into `tests/fixtures/check-names.txt`, copied from the `PASS` lines of
`bash tests/run.sh <file>` and re-sorted with `LC_ALL=C sort`.

## 7. Decision and docs

- **`journal/decisions/2026-10-30-partial-key.md`** (S2-04 writes it whole; S2-02/03 may start it): finding (spec §S2:
  the 2,500 s, 2,100 s and 1,531 s CLAUDE.md misses of 10-29-2; the two readers; the escape rate of a name-based
  subset) · choice (§1–§5 here) · rejected: a name-based subset for every post-session run (plan fix 5: the median
  subset is 73 % of the files, its escape rate isn't zero); an LLM choosing the subset (`decisions/2026-10-26-suite-split`
  S3's rejection stands); directory entries in the map (a directory's readers are every check that lists it: the lint
  can't prove that, and a new file in it would be a silent miss); the map read by the subset form (a subset is the
  caller's choice and is never cached); a partial run writing the sidecar (a chain of partials would compare against a
  tree no full run saw). *Defaults*, each marked: the fourth drop reason; duplicate paths merged; `--names`;
  `check-partial-rerun.out`; `CHECK_RERUN=suite` reruns the subset; no sidecar without a map; the flake row's
  `partial` and its never-empty `names`; no marker after a partial red; no new note; the root expressions widened to
  `$HH`, `$HARNESS_HOME`, `$(cd … && pwd)`, the `dirname "$0"` and `--show-toplevel` forms and file-wide aliases
  (79); the `== "…<R>"` form (13:386); row 4a, the tree's own map against the exported one; the map's final form and, per
  file, whether `36` and `75` joined it or were rewritten.
- **`journal/decisions/2026-10-26-suite-split.md`**, under S3, one line and nothing else:
  `Updated in place 2026-10-30: the rejected "list of paths the suite does read" is now a map of paths to their
  readers (CHECK_KEY_MAP, decisions/2026-10-30-partial-key): every unlisted path stays in the key, and a lint proves
  the map names every check that reads a mapped path.`
- `docs/architecture.md` §3/§4/§7/§10, `README.md`, `templates/project/config.sh`: S2-06 (the template line S2-02).

## 8. Where the feature list and this plan differ

- S2-03 step 3's sidecar mismatch and step 2's red: as §3; the rerun output name is `check-partial-rerun.out`, not
  the spec's `check-rerun.out` (§3, *default*).
- S2-04 step 2 names `36` and `75` as rule (b)'s finds; the lint also finds `79` (rule (a), through `$HH`), which the
  spec's literal rule (a) misses, and would find `13:386` without the sixth allowed form.
- S2-05 step 2's "no `part-` sidecar for that reduced key afterwards": §6, read as the verified tree's own sidecar.
- §3 row 4a (the tree's `.harness/config.sh` map against the exported one) is not in the spec: without it a stale
  exported map runs a subset the tree's lint didn't prove. S2-03 gets one more case for it: a tree whose
  `.harness/config.sh` sets a map other than `HARNESS_CHECK_KEY_MAP` runs in full on a `CLAUDE.md` diff.
- Beside the spec, marked *default* in §1/§5: a fourth drop reason (`not a path in the tree`); rule (b) fires on an `R`
  followed by anything but `/`; the root expressions add `$HH`, `$HARNESS_HOME`, the `"$HERE"`/`dirname`/`%/*` spellings,
  `$(dirname "$0")/../..`, `--show-toplevel`, and the spec's allowed forms 3 and 5 become root expressions (so they
  are allowed only as an alias assignment); `git -C` is allowed with five subcommands only; rule (a) also fires on
  `../<b>`; the `== "…"` form.
- `run_init` (S2-05) takes its key from `--partial`'s line 1 instead of the bare call: the same key (§1), one node
  call for both the key and the reduced key. Every other bare caller stays one line.
- S2-05 needs one stub hook the list doesn't name, `STUB_GOTCHA_ONLY=<id>`, and S1's counting suite to print a `PASS`
  per argument.
