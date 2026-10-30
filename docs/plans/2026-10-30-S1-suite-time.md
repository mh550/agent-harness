# S1 · The suite's length in the prompt, and a red tree cached like a green one: plan

Spec: `docs/specs/2026-10-30-suite-time.md` §S1 (fix 3, fix 2, S1-review) and its checks. This file is S1-01.
S1-02 builds the `wall` line, its readers, `HARNESS_SUITE_LENGTH` and the prompt's rule; S1-03 the `red-<key>` marker
in `lib/check.sh`; S1-04 the driver side (`run_init fresh`) and the stub runs that prove the retry and the verify
invariant; S1-05 reviews it and writes `docs/architecture.md` and `README.md`. Every site is named by function and
file as the code stands at `40da454`. Nothing here changes code, so the suite is as the init left it (1016 tests, green).

**Dependency line.** The spec needs `main` at or after `4d15739` (R1: `HARNESS_FAILED=`, the rerun guard,
`flakes.jsonl`, `wait_for`): `lib/check.sh` lines 10–12 and 76–93 are the rerun guard, so it is in this base.

## 1. Every reader of a `green-<key>` marker today

The marker is written once, `lib/check.sh:97` (`printf '%s' "${n:+$n$'\n'}" > "$cache/green-$key"`: `<n> tests` and
a newline, or an empty file), and read in three places, each with `cat`:

| Reader | File:line | Today | S1-02 |
|---|---|---|---|
| the cached line | `lib/check.sh:67` (top level, the `green-$key` branch) | `n=$(cat "$cache/green-$key")` | `n=""; read -r n < "$cache/green-$key"` |
| `run_init`'s `tests-start` | `lib/record.sh:461` (`run_init`, the `crc == 0 && ! -f tests-start` branch) | `n=$(cat "$STATE/green/green-$key" 2> /dev/null)` | `n=""; [[ -f $STATE/green/green-$key ]] && read -r n < "$STATE/green/green-$key"` |
| `tests_end` | `lib/record.sh:488` | `n=$(cat "$STATE/green/green-$key")` | `n=""; read -r n < "$STATE/green/green-$key"` (inside its existing `-f` test) |

Each keeps its fallback as it is (`[[ -n $n ]] || n=$(node testcount.mjs …)`). Why `read -r` and not
`cat` once line 2 exists: `$(cat)` of `5 tests\nwall 3` puts a newline into the cached line (so
`34-check-key.sh`'s byte-for-byte match goes red), and `$(cat)` of an empty line 1 (`\nwall 0`, the stub project's
`test ! -f BROKEN` prints no count) is `\nwall 0`, which is non-empty, skips the testcount fallback and makes
`${n%% *}` write `\nwall` into `tests-start`. `read -r` on a one-line or empty marker (an older one, or the
`: >` of `STUB_STALE_GREEN`) returns 1 at EOF and leaves `n` empty, which is today's meaning; nothing runs under
`set -e`, so the 1 is harmless. Afterwards
`grep -n 'cat "\$cache/green-\|cat "\$STATE/green/green-' lib/check.sh lib/record.sh` prints nothing.

No other reader exists: `grep -rn 'green-' lib bin` names only these and `lib/record.sh:454` (the `fresh` `rm`).
Two checks read a marker whole and change with S1-02 to its first line (`sed -n 1p`, a file argument, not a pipe):
`tests/checks/08-scope-sh-l1-02-run-capped-services-gc-scratch.sh:525` (`$(cat "$T/ck2c/green-$ck2k1") == "1 tests"`)
and `tests/checks/73-check-rerun.sh:34` (`$(cat "$T/rr-once/c"/green-*) == "5 tests"`).

## 2. The `wall` line (S1-02)

In `lib/check.sh`'s full form, `w=$(( $(date +%s) - start ))` right after the first run (line 73, before the
`check-$key.out` copy and the rerun guard): the first run's seconds, never the rerun's (a rerun is a subset's length).
The write at line 97 becomes `printf '%s\nwall %s\n' "$n" "$w" > "$cache/green-$key"`: line 1 `<n> tests` or empty,
line 2 `wall <s>`. A flake's marker is the first run's total and the first run's wall, as its count already is. The
cached line (line 70) is unchanged: `check: green (cached for this code tree, N tests)`. The usage header (lines 6–7)
says the marker is two lines.

## 3. `HARNESS_SUITE_LENGTH` in the prompt (S1-02)

The spec's `prompt()` is `lib/record.sh:246`, which only calls `prompt_render`; the variable goes in `lib/prompt.sh`'s
`prompt_render`, so the driver's prompt and the command form (`lib/prompt.sh <state dir> coding <feature>`, which
`harness eval probes` uses too) render it the same way.

- A new function in `lib/prompt.sh`, `suite_length` (one-line usage comment): the key of the cwd's tree
  (`node "$HARNESS_HOME/lib/treekey.mjs"`, with the exported `HARNESS_CHECK_KEY_IGNORE`), the cache
  `${HARNESS_CHECK_CACHE:-$STATE/green}`; the `wall` of `green-<key>`, else of `red-<key>` (S1-03's; absent until then,
  so S1-02 reads both names), else of the newest file among `green-*` and `red-*` in the cache that has a `wall` line
  (`ls -t`, the first with one), else none. The `wall` is the line matching `^wall [0-9]+$`
  (`sed -n 's/^wall \([0-9][0-9]*\)$/\1/p'`): a green marker's line 2, a red marker's line 3; neither marker's other
  lines can match. It prints `<s> s: give a full run a timeout of at least twice that`, or with none
  `not measured yet; bounded by CHECK_TIMEOUT $HARNESS_CHECK_TIMEOUT: give a full run a timeout above that` (the
  config's value: `15m` by default, `25m` in this repo's `.harness/config.sh`, which is the spec's `25m`).
- `prompt_render`, the `else` branch that adds `parts/run.md` (line 71–77): `HARNESS_SUITE_LENGTH=$(suite_length)`
  is set on the render line (line 79) with `HARNESS_DECISIONS` and `HARNESS_INIT_OUTPUT`, computed only when that
  branch ran (*default*: `entry-resume` and `retro` render no `parts/run.md` and so pay no treekey).
- `prompts/parts/run.md`'s Suite line becomes
  `` Suite: `{{CHECK}}` (runs `{{CHECK_CMD}}`, cached per code tree; last full run {{SUITE_LENGTH}}) · init: `{{INIT_CMD}}` · smoke: `{{SMOKE_CMD}}` ``.
  `parts/run.md` is a section, rendered at the template's `{{SECTIONS}}` line, so the variable is under it, never
  above (decisions/2026-10-21-static-first-prompts; the 08/13/14/15 same-prefix checks stay green).
- The initializer prompt is rendered after the driver's first `run_init` (`lib/driver.sh:480–481`), so it has the
  init tree's marker; verify and resolve prompts get the line too.

## 4. The rule and `CLAUDE.md` (S1-02)

- `prompts/coding.md` line 19–21, *The suite*: after `Run it in full once before you flip \`passes\`.` add
  `Give every full run a timeout of at least twice its last wall (under *This run*). When that is over the Bash tool's
  foreground limit (10 min), run it in the background with that timeout, its output to a file in your scratch
  directory, and wait for its end notification before reading it: never poll it, never run it without a timeout.`
  (`grep -c 'never poll it' prompts/coding.md` prints 1).
- `CLAUDE.md` line 34: `(~3 min 30 s on this box: 208 s measured with \`TEST_JOBS=4\`, the default here; end-to-end`
  becomes `(see the run's prompt for its length; 10–11 min on this box on 2026-10-29; end-to-end`; its
  wrap stays as it is; no `<n> checks` (memlint's `derivable-count`). `bash tests/run.sh 39-memlint` stays green.

## 5. The `red-<key>` marker (S1-03)

Four lines, in order:

1. the exit code `check.sh` is about to return (the final `rc`: the rerun's, when there was one);
2. the first run's `HARNESS_FAILED=` names (`${names[*]}`, empty when the line was absent);
3. `wall <s>`: the first run's seconds (the `w` of §2);
4. the `check: RED (…) — last lines of <out>:` line as printed (its scratch path included).

Where each part sits in `lib/check.sh` (top level, full form):

- **The lookup**, right after the `green-<key>` branch (lines 66–71) and before line 72's `rm -f check-rerun.out`:
  `if [[ -n $key && -f $cache/red-$key ]]`: read the four lines (`{ read -r rc; read -r nm; read -r _; read -r line; } <`),
  print `check: RED (cached for this code tree: ${nm:-whole suite})`, then `$line`, `row cached`, `exit "$rc"`. It runs
  nothing, reruns nothing and writes no `check.out` (it exits before line 73). The subset form (lines 59–63) exits
  before any marker is read, as today. A marker of another key is never read: any edit makes a new key.
- **The removal**: in the green branch (line 95–97), `rm -f "$cache/red-$key"` beside the `green-$key` write (it
  cannot exist for a green key unless planted, and a planted one must not survive).
- **The write**: in the red branch (lines 105–108), after the rerun guard (lines 78–93) has run. The RED line is built
  into a variable first (`last=$(why $rc $s …)`, `line="check: RED ($last$again) — last lines of $out:"`), printed, the
  tail printed, then, only when `[[ -n $key && $first == "exit "* && $last == "exit "* ]]`,
  `printf '%s\n' "$rc" "${names[*]}" "wall $w" "$line" > "$cache/red-$key"`. The condition is `why` saying
  `exit <rc> after <s> s` for both runs: a `timed out after …` (124, or 137 after the whole `CHECK_TIMEOUT`) may be
  the box's load, a `killed at its … memory cap` the scope's, so neither is cached and the next call runs.
- The usage header (lines 1–14) names `red-<key>`, its four lines, and that only the full form reads it.

`row cached` keeps the lane's "suite ran" note honest: `lib/lane.sh:329` counts rows whose kind is not `cached`.

## 6. The driver (S1-04)

- `lib/record.sh:454`, `run_init fresh`: `rm -f "$STATE/green/green-$key" "$STATE/green/red-$key"`. The verify's
  `run_init fresh` (`lib/lane.sh:72`, after the note `verify $m: suite cache cleared; the suite runs in full on the
  verified tree`) and the re-base's (`lib/lane.sh:190`) then always run the suite in full.
- Nothing else in `run_init` changes: a cached red exits non-zero, so line 455 logs `suite red before the session (the
  session is told to fix it first)` as today, and `init.out` (which the prompt's *Init output* carries) holds the
  `cached for this code tree: <names>` line and the stored RED line. A cached red writes no `check.out`, so
  `tests-start` is still set from the first green run with output (lines 459–464). `green()` (`lib/record.sh:79`) sees
  a cached red as a red: the un-pass is unchanged. `git diff main -- lib/record.sh` touches only line 454 and the two
  `read -r` readers.

## 7. The checks, by feature

| Feature | File | What it adds |
|---|---|---|
| S1-02 | `tests/checks/34-check-key.sh` (edit) | after `ck`'s green full run, `sed -n 1p` of the marker is `2 tests` and `sed -n 2p` matches `^wall [0-9]+$`; a one-line marker `2 tests` planted by the check (`printf '2 tests\n'`) still gives `check: green (cached for this code tree, 2 tests)` byte for byte |
| S1-02 | `tests/checks/79-suite-length.sh` (new) | stub runs and the command form of `lib/prompt.sh`, below |
| S1-02 | `08-scope-sh-l1-02-…sh:525`, `73-check-rerun.sh:34` (edit) | their whole-marker `cat` becomes `sed -n 1p` |
| S1-03 | `tests/checks/80-red-marker.sh` (new) | the unit cases of check.sh, with a copy of 73's counting suite |
| S1-04 | `tests/checks/80-red-marker.sh` (edit) | the two stub runs: the retry and the verify invariant |
| S1-04 | `tests/stub-claude.sh` (edit) | `STUB_PLANT_MARKERS=<id>`, beside `STUB_STALE_GREEN` |

**Counting a stub run's suite calls.** The stub project's suite (`tests/lib.sh:36`, `CHECK_CMD="test ! -f BROKEN"`)
prints and records nothing. A stub-run check writes `$HARNESS_STATE/proj/<run>/run.env` before `harness start` (as
`40-run-18-test-counts-m5.sh:5` and `77-leftovers.sh:44` do; `bin/harness` keeps a run.env's lines) with
`CHECK_CMD='bash <T>/cs.sh'`, a counting suite in the shape of `73-check-rerun.sh`'s `rr-suite.sh` that prints what
`tests/run.sh` prints: it appends `<treekey> <args>` to `<T>/cs-<run>.log` (`node $HARNESS_HOME/lib/treekey.mjs`: the
exported `HARNESS_CHECK_KEY_IGNORE` makes it `check.sh`'s key), then, while `BROKEN` exists, `FAIL t1`,
`HARNESS_FAILED=t1`, `1/2 checks passed`, exit 1, else `PASS t1`, `PASS t2` (or one `PASS` per argument) and
`2/2 checks passed`, exit 0. Calls on a tree are the log's lines with its key; a no-argument line is a full run.

**79-suite-length.sh** (S1-02; it fails before S1-02 because no prompt has the phrase):

- one stub run (`sl`) with the counting suite: `$HARNESS_STATE/proj/sl/prompt-coding.md` and `prompt-initializer.md`
  have `last full run <s> s: give a full run a timeout of at least twice that` with `<s>` the `wall` of a marker in the
  run's `green/` (every wall of a stub suite is `0`, so the next item pins the lookup itself); `tests-start` and
  `tests-end` are `2` (from a two-line marker; with `cat` and an empty line 1 they would not be);
- the lookup by the command form (`bash lib/prompt.sh "$HARNESS_STATE/proj/sl" coding <id>`, as `14-run-2b:20` does)
  after the check rewrites markers: the worktree tree's `green-<key>` set to `2 tests` / `wall 4321` renders `4321 s`;
  that one removed and another marker given `wall 77` and the newest mtime (`touch -d`) renders `77 s`; every `wall`
  line removed renders `not measured yet; bounded by CHECK_TIMEOUT 15m: give a full run a timeout above that`;
- a stub run (`sn`) whose first suite is a cached green from a planted one-line marker: its run.env's `INIT_CMD`
  writes `2 tests` to `$HARNESS_CHECK_CACHE/green-<key of the cwd>` when absent (the init runs before `run_init`
  takes the key and writes outside the tree, so the key is the suite's; the init sees `HARNESS_CHECK_CACHE` from
  `load_config`'s `prompt_env`), so no suite runs in full before the initializer: its `prompt-initializer.md` has
  `not measured yet; bounded by CHECK_TIMEOUT`;
- the static parts: `grep -c 'never poll it' prompts/coding.md` is 1, `grep -q "see the run's prompt" CLAUDE.md`, no
  `208 s` in `CLAUDE.md`.

**80-red-marker.sh** (S1-03), the counting suite of `73-check-rerun.sh` copied (a counter and a mode per case
directory, `rr()`, `calls()`), modes: `always` (red every call, `HARNESS_FAILED=a`), `late` (red on calls 1–3, green
from 4), `noline` (red, no `HARNESS_FAILED=` line), `hang`, `oom` (73's), `green`:

- `always` twice (the first run and its rerun): `red-<key>` lines are `1`, `a`, `^wall [0-9]+$`, and the `check: RED (`
  line the call printed; no `green-<key>`; the counter 2;
- the next full call prints `check: RED (cached for this code tree: a)` then the stored line, exits 1, writes no
  `check.out` (removed before the call), the counter still 2, a `cached` row in `check-runs.log`; `rr <case> always a`
  (the subset form) runs (counter 3) and prints no `cached`;
- `late`: calls 1–2 red, 3 a subset, 4 a full call that the suite would pass: the cached red, counter 3;
- `noline` red twice: `cached for this code tree: whole suite`;
- `HARNESS_CHECK_TIMEOUT=2s` with `hang`, and `HARNESS_SCOPE_PREFIX=harness-rr` with `oom`: no `red-<key>`, and the
  next call runs the suite (the counter moves);
- `green` with a planted `red-<key>`: green, the planted marker gone.

**80-red-marker.sh** (S1-04), two stub runs with the counting suite:

- the retry (`rm`): the stub's default C (`BROKEN` on its first try, `tests/stub-claude.sh:269`); `harness-log.md`
  has `C un-passed: suite red after the session`, the retry's `init.out` (the run's scratch, kept by `KEEP_SCRATCH=1`)
  has `check: RED (cached for this code tree:`, the log `suite red before the session`, and `cs-rm.log` has exactly
  two lines with the red tree's key (the full run and the rerun guard's `t1`), none from the retry's `run_init`. The
  red tree's key is the key of the log's lines whose run printed `FAIL` (the suite can log `red` beside the key);
- the verify invariant (`pv`): `STUB_PLANT_MARKERS=<the milestone's last feature>` makes that feature's first coding
  session, after its commit and push, write for its committed tree `red-<key>` (`1`, `t1`, `wall 7`,
  `check: RED (planted)`) and `green-<key>` (`99 tests`, `wall 7`) into `$HARNESS_CHECK_CACHE`, and the key to
  `$STUB_DIR/planted-$HARNESS_RUN_ID`. The post-session `green()` then answers cached green (so no call on that key
  before the verify); afterwards `harness-log.md` has `verify M1: suite cache cleared; the suite runs in full on the
  verified tree`, `red-<key>` is gone, `green-<key>` is the verify's own (`2 tests` and its wall, not the planted
  `99 tests`), and `cs-pv.log` has a no-argument line with that key.

Every new check name goes into `tests/fixtures/check-names.txt`, copied from the `PASS` lines of
`bash tests/run.sh <file>` and re-sorted with `LC_ALL=C sort`.

## 8. The decision files

- **`journal/decisions/2026-10-30-suite-length-in-prompt.md`** (S1-02): finding (the tool's 600 s default against a
  601–925 s suite, the five 10-29/10-29-2 timeouts, `CLAUDE.md`'s stale `208 s`) · choice (§2–§4) · rejected: the wall
  in the cached line (every init output would carry it, and the exact-match checks); a fixed number in `CLAUDE.md` (it
  was wrong within three days); reading `tests/run.sh`'s own `wall … s` line (this suite's only). *Defaults*: the wall
  goes in the marker, not a sidecar (the marker outlives scratch, and the prompt is its one caller); the background
  clause of the rule (twice the wall is over the foreground limit here); `CLAUDE.md`'s line without the brief's
  `at 925 checks` (memlint's `derivable-count`); the fallback scan includes `red-*` markers (a red tree's wall is the
  suite's length as much as a green one's); `suite_length` runs only for templates that render `parts/run.md`; the
  `not measured yet` phrase names the run's own `CHECK_TIMEOUT`.
- **`journal/decisions/2026-10-30-red-marker.md`** (S1-03, with S1-04's `run_init fresh` line added there): finding
  (the 953 s, 993 s and 824 s pre-retry runs on a tree run twice minutes before) · choice (§5, §6) · rejected: caching a
  timeout or a cap kill; clearing the red marker on a timer; a red marker that stores the whole output. *Defaults*:
  the whole first-run output is not stored (`check.out` and `check-<key>.out` hold it for the run's lifetime); the
  stored exit code is the final run's, the names the first run's; the stored RED line keeps its scratch path.

## 9. What the feature list says and the code says otherwise

- S1-04 step 2's "both markers are gone from the state dir's `green/` afterwards": the verify's own green run writes
  `green-<key>` again, so the check reads it as §7 does: `red-<key>` absent and `green-<key>` the verify's, not the
  planted one.
- S1-02 step 2's "`<s>` equal to the `wall` line of the run's `green-<key>` marker": a stub suite's walls are all `0`,
  so the lookup is pinned by the command-form cases of §7 rather than by the run's own number.
- The docs (`docs/architecture.md` §3, §4, §7 and the prompt's variables; `README.md`) are S1-05's, per the feature
  list, within the milestone as `CLAUDE.md` asks.
