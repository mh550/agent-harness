# No run ends on a clock unless asked to: `HOURS` defaults to none, and the night leaves the docs

*(2026-11-04, F1 M2 by hand: `docs/plans/2026-11-04-f1-by-hand.md`; spec `docs/specs/2026-11-04-run-resilience.md` M2.
Built in Michael's hand session. Reviewed by one clean-context Sonnet reader of the diff.)*

## Finding

Every `harness start` or `continue` segment ended `deadline` eight hours in: `lib/config.sh` `HOURS=8`, `lib/driver.sh`
`DEADLINE=$(( T0 + HOURS * 3600 ))`, cut shorter by `--until` (`DEADLINE_AT`). A deadline end never continues by itself
(only a session cap queues a continuation) and gives each complete, unverified milestone one verify first. The queue
runner already had no end of its own. Michael, 2026-11-04: runs go regardless of the time of day; the night is not the
unit. Yet the docs, prompts and templates framed a run as a night (`README.md`'s `Queue a night's work at once`,
`--spec OVERNIGHT.md`, `The morning after:`; `docs/architecture.md`'s `queue it for another night`; `CLAUDE.md`'s `This
repo runs Michael's nights` and `Tonight's scope`, the same line in `prompts/parts/where-things-go*.md`,
`prompts/draft-claude-md.md` and `templates/project/CLAUDE.md`; comments in `lib/queue.sh`, `lib/driver.sh` and
`bin/harness`; memlint's `night-scope`).

Setting `DEADLINE=0` alone was not safe: every reader tested `now >= DEADLINE`, so 0 meant "now". `limit_wait`'s cap
computed a negative wait and **skipped** a usage-limit window, `resolve_ok` refused every resolve session, and the
poll loop would have ended the run `deadline` at once.

## Choice

1. **`HOURS` defaults to none.** `HOURS=""` in `lib/config.sh` (*default*: the empty string), `# HOURS=` in
   `templates/user/config.sh`. Empty or `0`: no end time. A whole number: that many hours. `run_deadline <T0>`
   (`lib/config.sh`) is the rule: `DEADLINE=0`; a whole number over 0 → `T0 + HOURS * 3600`; `DEADLINE_AT` set → it, or
   the earlier of the two. `run.log`'s first line gains `· ends <HH:MM>` or `· no end time`. `HARNESS_DEADLINE=0` reaches
   the lanes.
2. **A bad `HOURS` is refused** (*default*: as a bad `MAX_PARALLEL_RUNS` is refused by the runner; a typo must not
   silently become no deadline or eight hours): `hours_ok` (`lib/config.sh`), `HOURS=<v> in the config is not a whole
   number of hours`, exit 1. `cmd_start` refuses before a queue entry or a worktree comes of it (a given run's `run.env`
   counts); the driver refuses too, before it runs anything, for a config edited after `cmd_start` read it. `08` is
   refused: a leading 0 is no number in bash arithmetic.
3. **Every reader takes 0 as none.** `past_deadline` (`lib/record.sh`) is the one test for the driver's two and the
   lane's three; `limit_wait` caps the wait at the deadline only when there is one; `resolve_ok` refuses for the
   deadline only with one; `deadline_verify` is unreached without one. `clock()`: `run 3h10m of 8h, ends 03:55`
   unchanged with a deadline, `run 3h10m (no end time)` without (*default* wording). The end reason `deadline` stays.
4. **What still bounds a run:**

   | Bound | What it ends or caps |
   |---|---|
   | `MAX_SESSIONS` (`auto`: 3 per feature + 5) | the segment, `session cap (N)`; a continuation is queued |
   | `MAX_ATTEMPTS` | a feature, then `given_up` |
   | `MAX_VERIFY_ROUNDS` | a milestone's verify rounds, then needs Michael |
   | `MAX_REBASE_ROUNDS` | a re-based lane's verify rounds, then needs Michael |
   | `MAX_RESOLVES` | a milestone's resolve sessions, then needs Michael |
   | `MAX_FIX_ROUNDS` (M3's, when it lands) | a milestone's fix rounds, then the `verify_red` card |
   | `MAX_LIMIT_HITS` and the limit waits | the run after that many refused sessions in a row |
   | `WEEKLY_STOP_AT` | the run, `weekly budget (…)` |
   | `AUTO_CONTINUE_MAX` | continuations a session cap queues |
   | `SESSION_TIMEOUT`, `SESSION_BUDGET_USD` | one session |
   | `stop`, `pause`, `--until` | Michael's |

   A run without a deadline ends on one of these; nothing else changes in when it ends.
5. **`--until` stays an option, documented as one.** `harness start --until HH:MM`, `continue --until` and `queue start
   --until` keep their behaviour and their rows; the README's quick start no longer shows it as the way a queue ends.
6. **The framing goes from the memory the sessions read and the docs.** Memlint's rule stays (`tonight`, `this run`,
   `this slice`, `as of <date>`); its check id is `run-scope` and its finding `"<match>" (run scope goes in the run's
   brief)` (*default*: the id is one of its words). Specs, plans and decision files are history and keep their nights.
   A lint holds the rest: `grep` for the night words over `README.md`, `docs/architecture.md`, `CLAUDE.md`, `prompts/`,
   `templates/`, `lib/`, `bin/`, allowed by file and word in exactly two files: `lib/memlint.mjs` (the patterns it looks
   for) and `prompts/project-catchup.md` (a catch-up's rule about deleting such lines).

**Against the spec, said plainly:**

- The lint and memlint's new-id check are in their own fast file, `tests/checks/89-night-words.sh`, not
  `89-no-deadline`. The spec predicted `89` fast; timed, it is 50–67 s, so slow by `decisions/2026-11-03-suite-tiers`.
  In the slow tier a stray word in a prompt would pass every feature and go red only at a verify. The new file reads
  `CLAUDE.md`, so it joins `CHECK_KEY_MAP`, and `82-key-map-lint`'s pin moves with it.
- `prompts/project-catchup.md` has three matching lines, not the spec's two: 106 (`Night scope`, `OVERNIGHT.md`, a real
  file name in other projects) with 75 and 107. All three stay.
- Lines past the spec's inventory reworded the same way: `docs/architecture.md`'s `a same-night harness continue` and
  `With 1, nights are serial`, `lib/memlint.mjs`'s comments, `README.md`'s memlint line (`tonight`, an example, dropped).
- The limit window of `nd2` is planted 50 s ahead, not 3: still `(0 min)` with `HARNESS_LIMIT_SLEEP=0`, and a loaded
  box's init can't outlast it.
- The `run.log` line's new tail breaks the anchored `· harness <sha>$` in `08`, `13`, `14` and `15`: those four now
  require the tail (not in the spec's list for them, which named only the clock regex).
- Two check names change with the id (`night-scope` → `run-scope`, `night scope` → `run scope`), so
  `tests/fixtures/check-names*.txt` isn't adds-only in this milestone, as the spec's item 6 asks.
- `MAX_FIX_ROUNDS` is in the table above but not in §7's `Bounds` row or the template's list: it doesn't exist until
  M3, which adds it to both.

## Rejected

- A longer default: any number is still a clock.
- Ending on the five-hour window's reset: the limit waits already shape that.
- A continuation queued by a deadline end: there is no deadline to continue past, and `--until` runs stay as they are.
- Keeping the night words in the sessions' memory files with the lint off.
- The old id `night-scope` with new words: the id is one of its words, and a reader sees it in every finding.
- `DEADLINE=<far future>` instead of 0: every reader would stay as it was, and the clock and `run.log` would say a date
  nobody set.
- A silent fallback for a bad `HOURS` (eight hours, or none): a typo would set the run's whole time budget unseen.
- The lint in `89-no-deadline` as the feature list had it: see above.

## Left, each failing on the safe side

The review's four Minors (0 Critical, 0 Important); none changed:

- The allow-list is by file and word, as the spec asks, not by line: a new `night` in `prompts/project-catchup.md` passes.
- A bad `HOURS` blocks `harness merge` too, which needs no deadline: a clear line, and a one-line fix. A bad value committed
  only on the run branch passes `cmd_start` (it reads the project checkout's config) and stops at the driver, with a
  `run.log` line and no `ended`, as an unknown `POLICY` does.
- `hours_ok` takes any digit string. From 16 digits (`9999999999999999`, checked) `T0 + HOURS * 3600` wraps negative, and
  the run ends `deadline` at once: visible, no work lost. A cap would make the refusal's words untrue for a large number.
- `nd2`'s 50 s window: a box whose init outlasts it turns that check red rather than passing it wrongly.
