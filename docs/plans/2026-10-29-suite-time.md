# Suite time: the plan, with its predictions written first

Diagnosis: `findings-and-research/2026-10-29-run-time-budget.md` (the numbers below cite its sections). Written
2026-10-29 ~19:00 while `agent-harness-2026-10-29-2` is alive with R1 in verify round 1 and R3-04 in session 13; R1
and R3-04 are measured here, not redone. No driver or CLI change is made by this plan; Phase 2 and the fixes wait on
the run's end and on a pushed branch each.

The unit throughout is **lane-seconds per run**, a run being a two-lane night of about 20 coding sessions like
10-29-2 (56,000 lane-s so far, 34,000 of them suite). "Per run" savings are what the four measured runs would have
saved, not a forecast; the forecasts are in §1 and §4.

## 1. Predictions, before any change

### 1a. R1's effect (wait_for, the sleep lint, the flaker fixes), before R1 merges

Baseline, from the runs before R1 (§3, §5 of the findings): solo suite 624 s wall / 2,452 CPU-s at 859–925 checks;
paired 904 s / 3,220 CPU-s; 9 flake rows in 20 two-lane sessions (0.45 per session; `08` ×3, `13` ×2, `28` ×2,
`32`, `46`, `47`, `48`, `52`, `74`); features un-passed for a red suite 4 in 71 sessions, none for a flake.

R1 fixes `44`, `46`, `48` (one coordinator race, R1-04), `15`'s weekly-budget check and `28` (R1-05), `32`, `38`, `08`
(R1-06), and replaces fixed-iteration polls with `wait_for` (R1-02, R1-03). It does not touch `13`, `47`, `52`, `74`,
nor the Gotchas/memlint path, and adds ~60 checks (886 → 944 at R1-04).

| Measure | before | predicted after R1 merges, next two-lane run | why |
|---|---|---|---|
| solo suite wall | 624 s | **600–660 s** | the suite is CPU-bound at 3.9 cores (sleeps were ~25 s of the largest file's 147 s on 10-26); `wait_for` returns earlier than a fixed sleep, worth 0–5 %; R1's 60 checks add ~5 % |
| CPU per solo suite | 2,452 s | **2,400–2,650 s** | unchanged per check; +5 % checks |
| paired suite wall | 904 s | **850–1,000 s** | same ratio to solo |
| flakes per two-lane run (20 sessions) | 9 rows, 14 names | **3–6 rows** | the rows whose names R1 fixed were 4 of 9; `13`, `47`, `52`, `74` stay (5 rows had one of them); if R1's fixes don't hold under load, 7–9 |
| features un-passed for a red suite, per 20 sessions | 2 (both memlint) | **1–2** | R1 doesn't change the Gotchas path; a flake un-pass stays at 0 while the rerun guard holds |
| features thrown out for a flake | 0 | **0** | |

Falsifiers: a solo wall under 560 s (sleeps mattered more than measured); flakes at 9 or more (the fixes were
symptom-level); any un-pass whose first red is a flaker's name on the rerun too (the guard's one rerun isn't enough).

### 1b. R3-04's effect (suite runs counted per session)

No time change; it gives the next run the number this plan lacks: full runs per session as the harness counts them.
Prediction: **1.6–2.0 per coding session** (measured 1.5–2.1 from the scopes, §4), of which the share "cached" is
10–20 %.

### 1c. The next two real runs with nothing from §3 applied (R1 and R3-04 merged)

| Measure | predicted |
|---|---|
| non-session share of lane time (harness before + after + verify + waiting + idle) | **15–25 %** with no pause (10-29-2: 27 % with a 12 % pause; 10-28: 10 %; 10-29: 18 %) |
| suite wall per run (every caller) | **28,000–38,000 lane-s** per 20 sessions, 55–65 % of lane time |
| CPU per run in suites | **70–95 CPU-hours** (≈ 45 full runs × 2,450–3,200 CPU-s + reruns) |
| flakes per run | 3–6 (§1a) |
| un-passes from a red suite | 1–2, memlint/Gotchas the likeliest cause |
| main green after milestone merges | **100 %** (four runs: 0 reds; the verify's full run is the gate) |
| tool-timeout hits ("moved to the background") | 2–5 per run while the prompt says nothing about the suite's length |

## 2. Fixes, ranked by measured lane-seconds saved per run

| # | Fix | saves per run (measured) | guard weakened → what replaces it | applies to |
|---|---|---|---|---|
| 1 | **A declared partial map for the cache key** (`CHECK_KEY_MAP="CLAUDE.md:memlint README.md:… docs/architecture.md:…"` in `.harness/config.sh`): when the tree differs from a green tree only in mapped files, check.sh runs the mapped subset and, if green, writes the marker; otherwise the full run as now. | **~6,000 s** in 10-29-2 (R1-01's 1,531 s, R2-01's and R1-02's post-session runs 1,731 s, their retries' duplicate runs 1,946 s, the two retry sessions ~930 s); 0 in 10-28, 0 in 10-29 | "the full suite before any pass": kept for every tree whose diff isn't fully covered by the map; for covered diffs the guard becomes "the checks that read those files", a deterministic function of the tree (the suite-split decision's rule), the map reviewed in the same PR as a change to what a check reads. Cost of a wrong map: a stale green, so the map names only files the suite reads in one place (memlint, the README check). | **agent-harness** (CLAUDE.md is both key-bearing and prompt-encouraged to change); dj and hit_list's suites read no CLAUDE.md: no gain there |
| 2 | **Cache a red tree too** (`red-<key>` with its first-run names and output): `run_init` before a retry answers from it (`check: RED (cached for this code tree: <names>)`), the session is told the same as now | **1,950 s** (10-29-2), **824 s** (10-29), 0 (10-28) | none: the rerun guard already ran the tree twice; a flake that was red twice stays red, which is today's outcome. The marker is cleared when the full suite next runs on that key (it never will: the key changes with the fix). | every project; most where a retry follows a red |
| 3 | **Tell the session how long the suite takes and give the call a timeout**: the prompt's *This run* line carries the last full run's wall (`suite: … last full run 904 s`) and a rule "pass `timeout` ≥ 2× that to the call"; CLAUDE.md's "3.5 min" corrected by the harness's own number | **1,180 s** measured once (R1-01); the four "moved" runs cost 0–300 s each of polling turns (not measured) | none | every project whose suite is over 5 min: agent-harness, dj (end-to-end), not hit_list |
| 4 | **One full run per session, not two**: the prompt's "run it in full once before you flip passes" becomes "iterate on subsets; run it in full once, last, after your final edit of any file including CLAUDE.md; a flake is rerun by check.sh, don't rerun it yourself"; R3-04's count makes it visible | *hypothesis*: 1.5–2.1 → 1.2–1.4 full runs per session = **5,000–11,000 s** per 20 sessions; the data can't split "red then fixed then full again" (needed) from "ran it early to see" (not) | none for the harness; the session's own habit | every project |
| 5 | **Targeted subsets per feature, the full suite at the milestone**: the post-session `green` runs the name-matched subset (§7's rule: the check files that name a changed file plus the session's own check files); the verify's `run_init fresh` stays the full run; a red there un-passes the milestone's features whose files the red check names (else all of them) and a resolve-style session fixes it | *estimate from §7*: the 22 of 60 sessions with subsets under half the suite save 50–75 % of their in-session suite time; the rest save little: **7,000–9,000 s** per 20 sessions on agent-harness's profile; up to 60 % of suite time on a profile with real module boundaries | "a red suite un-passes the feature": replaced by "a red subset un-passes it, and the milestone's full run un-passes it later"; the escape rate is 0–2.4 % per feature (§7) and the milestone run catches it before the tag; `tests_end` per session becomes the milestone's count. The suite-split decision's "deterministic function of the tree" holds (a name rule, not a model). | **dj and hit_list first** (module boundaries, suites that don't start the whole product per check); agent-harness last (median subset 73 % of the files) |
| 6 | **Fewer process starts in the suite**: cache the driver's pure `node` questions (`F model`, the list queries keyed on the list's content) and the one-millisecond utilities in the hot loops; measure with `strace -c` / `perf` first | *hypothesis from the 10-26 strace*: node startup was ~50 % of a file's CPU and the driver's calls ~8 % of them; a 20–30 % CPU cut would be **6,000–10,000 s** per run and would lower the paired wall and the flake rate with it | none (the driver's behaviour is unchanged; the checks prove it) | every project runs the driver, so every project's suite inherits the gain; the share is highest where the checks are stub runs (agent-harness) |
| 7 | **A box-wide suite token** (one full suite at a time, `flock` in check.sh) | **negative for time**: two paired suites finish together in ~904 s, two in series in ~1,248 s (§3; the 25m decision's 857 vs 1,202); CPU per suite −25 %; flakes *maybe* −50 % (9 of 9 rows had another suite running, but 1 at load 1.4) → ~1,000 s of reruns saved against ~5,000 s of waiting per run | the rerun guard stays; nothing else | not recommended as is. **Variant to test in Phase 2:** the token holder runs at `TEST_JOBS=8`; if a solo 8-job run is ≤ 520 s, two serial runs cost what two paired runs cost today, with lower load, which is the only lever on the flake rate the data supports |
| 8 | **Spin-wait fixes** | **0**: none found (§3); R1's `wait_for` covers the polls | | |

Not in the list: `TEST_JOBS=2` in sessions (already rejected; worth a line in the prompt so no session proposes it
again: 10-28 paid ~20,000 s for it), and clearing the cache after coding sessions (rejected in
`decisions/2026-10-26-verify-runs-the-suite`; §4 shows the cache is right when it hits).

The sum of 1–3 (measured, no guard weakened, no prompt judgement involved) is **~9,000 s per two-lane run, 16 % of
lane time, 26 % of suite time**, before 4–6.

## 3. Phase 2: measurements and the order of work (after the run ends)

Only while `harness status` shows no live run; each step in a worktree of its own, pushed and merged as a PR.

1. **The controlled load curve** (the task's): `bash tests/run.sh` alone and with a second copy in another worktree,
   at `TEST_JOBS` 1, 2, 4 **and 8** (for fix 7's variant), each under `/usr/bin/time -v` in a `systemd-run --user
   --scope -p MemoryMax=3G` unit, `/proc/pressure/cpu` sampled every 10 s, `flakes` = the red files of the first run.
   Twelve runs, about 2.5 h. Record wall, user+sys CPU, pressure `some avg60` at the midpoint, red files. Prediction:
   solo 1/2/4/8 jobs ≈ 2,400 / 1,250 / 620 / 520 s; paired at 4 ≈ 900 s each; CPU rises from ~2,450 s solo to ~3,200 s
   paired at 4 jobs; `some` pressure 0–10 % solo at 4 jobs, 50–80 % paired.
2. **The CPU split of one solo run** (`strace -f -c` on the largest three files, `perf stat` on the whole): node
   starts, git, forks, sleeps. Decides fix 6's size before any code.
3. **Stub-overhead runs inside `tests/run.sh`'s throwaway environment**: time `harness start` of the stub project alone
   against a file's assertions, three files; the share tells whether fix 6 is the driver's calls or the checks'.
4. **Fix 3** (the prompt line and the timeout rule; CLAUDE.md's number): a prompt change, one check in `tests/checks`
   that the *This run* line carries the last full run's wall. Smallest, no guard.
5. **Fix 2** (the red marker): `check.sh` + `run_init`, one check: a red tree's second `check.sh` answers from the
   marker; a decision file.
6. **Fix 1** (the partial map): `check.sh` + `treekey.mjs` (a second key over the unmapped files), the config line,
   checks: a CLAUDE.md-only diff from a green tree runs memlint alone and inherits green; a `lib/` diff runs in full;
   a wrong map entry (a mapped file a check outside the map reads) is caught by the check that lists what each check
   file reads. A decision file that amends `decisions/2026-10-26-suite-split` S3 in place.
7. **Fix 4** (the prompt's one-full-run rule) with R3-04's count as the measure, one run later.
8. **Fix 6** if step 2 says node startup is still a third or more of the CPU.
9. **Fix 5** on dj or hit_list first, with their escape rate measured the same way (`escapes.mjs` over their runs)
   before the subset replaces the post-session full run; agent-harness only if its median subset falls under half.
10. **Fix 7's variant** only if step 1's 8-job solo run is under 520 s and the paired flake count in step 1 is 2 or
    more.

## 4. Predictions for the next real runs after fixes 1–3 land

| Measure | now (10-29-2) | after 1–3 |
|---|---|---|
| non-session share of lane time (no pause) | 15–25 % | **10–18 %** (the duplicate pre-retry runs gone; post-session misses on CLAUDE.md gone) |
| suite wall per run, every caller | 34,000 lane-s per 20 sessions | **26,000–30,000** |
| CPU per run in suites | 70–95 CPU-h | **60–80 CPU-h** |
| solo suite wall | 624 s | unchanged, 600–680 s (the suite keeps growing ~5 % per run) |
| flakes per run | 3–6 after R1 | 3–6 (fixes 1–3 don't touch load) |
| un-passes from a red suite | 1–2 | **0–1**: a Gotchas line over the cap is caught by the mapped memlint run in the session's own check, 2 s, not 900 s later |
| features thrown out for a red suite after a retry | 0 | 0 |
| main green after milestone merges | 100 % | 100 % |
| tool-timeout hits | 2–5 | **0–1** |

After fix 4 (if the hypothesis holds): suite wall per run 18,000–24,000 lane-s; after fix 6: solo suite wall
450–520 s. Both are hypotheses until steps 2 and 7 measure them.

## 5. Project suite profiles

- **agent-harness**: end-to-end, every check file starts the driver on a stub project; 925 checks, 624 s solo,
  CPU-bound on 4 cores; the key-bearing file sessions edit most (CLAUDE.md) is read by one check. Fixes 1, 2, 3, 6
  fit; 5 fits poorly; 7 only as the 8-job variant.
- **dj-crate-streaming**: a live system with an end-to-end suite of its own shape and a 15m timeout; its runs are
  single-lane. Fixes 2, 3 (if the suite is over 5 min), 5 (module boundaries), 4.
- **hit_list**: a short unit suite; the suite is not where its lane time goes (unmeasured here: run `budget.mjs` on its
  runs before assuming). Fixes 2 and 4 at most.
- The findings' `budget.mjs` runs on any project's state dir; the first Phase 2 step for dj and hit_list is that
  table, not a fix.
