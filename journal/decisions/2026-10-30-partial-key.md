# A mapped path's change runs only its readers: `CHECK_KEY_MAP`, the `part-<key>` sidecar, the partial run, the lint

*(2026-10-30, run `agent-harness-2026-10-29-3`, S2-02 to S2-04; spec `docs/specs/2026-10-30-suite-time.md` S2, plan
`docs/plans/2026-10-30-S2-partial-key.md`)*

- **Finding:** `CLAUDE.md` is in the suite cache key (`decisions/2026-10-26-suite-split` S3 keeps every path a check
  reads), and every coding session adds a Gotchas line to it after its last full run. The post-session suite then
  missed the cache and ran in full: 2,500 s and 2,100 s of lane time for R2-01 and R1-02 in 10-29-2, 1,531 s for
  R1-01's line that didn't ship. Only a few check files read this repo's `CLAUDE.md` (`39-memlint-m4`,
  `37-memory-prompts-m2`, and `79-suite-length`, which the spec's list missed). A subset chosen by name escaped 0 to
  2.4 % of reds (spec §7); a declared map of a path to its readers, proven by a lint, misses none of the kind found.
- **Choice:**
  - `CHECK_KEY_MAP` (`lib/config.sh`, default empty; exported by `prompt_env` as `HARNESS_CHECK_KEY_MAP`): space-separated
    `<path>:<check>[:<check>…]` entries, each check a full file stem (`tests/run.sh` matches by substring). An entry is
    dropped with one stderr line when it has no name, is not a path in the tree (*default*, a fourth reason beside
    the spec's three), is under an ignored prefix, or is a directory; a duplicate path's names are merged into its
    first entry (*default*).
  - `treekey.mjs --partial` prints the full key, the reduced key (the key of every file no entry maps) and one
    `<blob> <path>` line per mapped path in map order (`-` when absent); its functions are exported and pure.
    `--names <path>…` prints the names the map gives those paths (*default*: one parser for check.sh).
  - `lib/check.sh`'s full form: a green full run writes `part-<reduced>` (line 1 the green tree's full key, then its
    blob lines; *default*: none without a map). A tree with no green or red marker of its own whose reduced key has a
    sidecar, whose reference `green-<line 1>` is still there, whose path set is the map's, and whose differing paths
    are all mapped runs just their checks (`check: green (partial: <names>, <s> s; cached for the rest)`) to
    `check-partial.out` (a rerun to `check-partial-rerun.out`, *default*), under the same scope, timeout and rerun
    guard (`CHECK_RERUN=suite` reruns the subset, *default*). Any other case runs in full (the plan's §3 table). A
    partial green writes `green-<full>` with the reference's count and wall and removes `red-<full>`; a partial red
    writes no marker of either kind (*default*: the next call on that tree runs the partial again, a red it can't cache), and a flake row carries
    `partial` and never-empty `names` (*default*). A partial writes no sidecar. No new `harness-log.md` note
    (*default*): the partial's line is in `init.out`, so in the next prompt's *Init output*.
  - The tree's own map decides (*default*, row 4a): the map after sourcing the tree's `.harness/config.sh` must equal
    the exported one, else a full run; and no partial when `.harness/config.sh` is outside the reduced key (*default*,
    S2-03's review: its map could change under an equal reduced key). S2-06's review found three ways past check.sh's
    own ignore-list test (the map mapping its own file, a gitignored config, an ignore spelled `.harness//`), so
    treekey decides it: `--partial` prints no blob line (no map) when the config is on disk but not among the reduced
    key's files, and `parseMap` drops an entry under `.harness/` (`the map's own`).
  - `run_init fresh` (verify, a disjoint re-base) removes `part-<reduced>` with the two markers (S2-05), so a verified
    tree always runs in full.
  - **The lint** (`tests/checks/82-key-map-lint.sh`, S2-04): for each entry and each check file the entry doesn't
    name, (a) a line holding a root expression and naming the path or its basename, or naming `../<basename>`, and
    (b) a root expression left bare once the allowed forms are cut out, is `<file>:<line> reads <path>, not in
    CHECK_KEY_MAP`. Bare (S2-06's review): not followed by `/<name>`, or followed by a `.` or `..` segment, or by a glob,
    brace or variable whose literal part before it could lead to the path (`<R>/$f`, `<R>/*.md`; not
    `<R>/evals/$t/x.json`); `${HH:-…}` is a root like `$HH`. A map name no check file holds is
    `<path>:<name> matches no check file` (`tests/run.sh` is red on it every time). The root expressions are widened beyond the spec's `$HERE/..`
    (*default*): `$HH`, `$HARNESS_HOME`, `$(cd <R> && pwd)`, `$(readlink -f <R>)`, `$(dirname "$0")/../..`,
    `--show-toplevel`, the `"$HERE"`/`dirname`/`%/*` spellings, and file-wide aliases (`79-suite-length.sh:87` reads
    `"$HH/CLAUDE.md"` on a line that sets nothing). The allowed forms: `HARNESS_HOME=<R>`, `git -C <R>` with
    `log`/`rev-parse`/`cat-file`/`worktree`/`ls-files` only, `harness_config <R>`, an alias assignment (the spec's
    `readlink -f` and `cd && pwd` forms are allowed as such, not inline), and `== "…<R>"` inside `[[ ]]` (*default*, a sixth form
    for `13-run-2-michael-sets-desk.sh:386`'s string compare). Each says in the check file why it reads no file.
  - What the lint can't see, so what an entry may be: a read by the code under test (`lib/`, `bin/`) or by a helper
    every check sources (`tests/*.sh`), or a root built some other way. An entry is only for a file nothing but
    check-file lines read from this checkout: `CHECK_KEY_MAP`'s template comment says so. Nor a file the proof
    itself reads (a check file, `tests/run.sh`, `lib/treekey.mjs`): a change to it would run only its own names, not
    the lint. Still open after S2-06 (contrived, none in the tree): an alias of a sub-directory followed by `..`, a
    root alias read without `$` (`process.env.ROOT`), a glob outside the quotes (`"<R>/CLAUDE.m"?`), and `git -C <R> log -p`.
  - **This repo's map, its final form** (S2-04): `CHECK_KEY_MAP="CLAUDE.md:39-memlint-m4:37-memory-prompts-m2:79-suite-length"`.
    Per file the lint found on the day:
    - `39-memlint-m4.sh`, `37-memory-prompts-m2.sh`: joined (they read `CLAUDE.md`).
    - `79-suite-length.sh`: joined (line 87 greps `"$HH/CLAUDE.md"`, rule (a)).
    - `36-run-16-retro-backlog.sh`: rewritten, not joined: its three `cd "$HERE/.." && $H backlog import "$SEED"`
      lines now `cd` into `docs/` (`DOCS=$HERE/../docs`) and import `specs/<seed>`, still a path relative to the
      caller's directory, as before (about 100 s of check time kept out of every Gotchas-only run). Not
      `$HERE/../docs/specs`: `34-check-key`'s rule bars a check naming a path the key ignores.
    - `75-suite-tools.sh`: rewritten, not joined: line 69's `cd "$HERE/.." && bash tests/lint-sleeps.sh` is
      `bash "$HERE/lint-sleeps.sh"`, the same default file list (the lint finds its files from its own path).
    - `81-partial-key.sh`: rewritten: line 56 compared `CHECK_KEY_MAP` with a `CLAUDE.md:…` string beside
      `harness_config "$HERE/.."` (rule (a) on a string); the expected prefix moved to its own line (`M0=…`).
    - `13-run-2-michael-sets-desk.sh:386`: neither, the sixth allowed form (205 s under load: mapping it for a
      string compare is the wrong cost).
  - *default:* not linted: `tests/lib.sh`, `tests/stub-*.sh`, `tests/run.sh` (every check sources or runs them, so a
    hit there can't be mapped; none names `CLAUDE.md` beside a root today), and a bare `..` argument after a `cd`
    into `tests/` (four strings and comments today, none a read).
- **Rejected:**
  - a name-based subset for every post-session run: the median subset is 73 % of the files, and its escape rate
    isn't zero;
  - an LLM choosing the subset: `decisions/2026-10-26-suite-split` S3's rejection stands (the key is a deterministic
    function of the tree);
  - directory entries in the map: a directory's readers are every check that lists it, which the lint can't prove,
    and a new file in it would be a silent miss;
  - the map read by the subset form: a subset is the caller's choice and is never cached;
  - a partial run writing the sidecar: a chain of partials would compare against a tree no full run saw;
  - the allow-list growing per command (`cd "<R>" && $H backlog`, `bash tests/lint-sleeps.sh`): each form is one
    more way to read the root unseen; a found file joins the map or its line stops passing the bare root.
