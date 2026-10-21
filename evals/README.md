# Replay evals

A fixed set of tasks taken from real past runs, so that two harness versions can be run on the same work and
compared (`docs/specs/2026-10-20-measure-then-memory.md` § E2, `docs/plans/2026-10-21-E2-evals.md`, D-H35).
Each task is `evals/tasks/<id>/task.json`: 1–3 features copied verbatim from the source run's `feature_list.json`,
the commit the source session started from (`base`), and why the task is in the set. `evals/sets/default.txt` lists
the tasks `--set default` runs. Evals cost money: they are Michael's to run.

## Rules for a task

- **Build-only, nothing live.** `policy` is always `build-only`, whatever the source project's POLICY. No task needs
  a live system, a secret or a `.env` value, and `grep -ril 'live\|secret\|\.env' evals/tasks` prints nothing. The
  grep matches substrings too ("deliver", "alive", "process.env"); features are never reworded to pass it, so a
  feature that hits it stays out of the set.
- **Verbatim.** Features (with their `after`) are copied as they stood at `base`; `spec` and `brief` are the source
  run's spec path and `brief.md` as of `base`. The source run's own record under `.harness/runs/` stays in `base`.
- **`base`** is the full sha of the parent of the source session's first commit, named in `why`.
- **Valid.** `node lib/eval.mjs validate evals/tasks` exits 0 (each error names its field; an unknown key is an
  error, the id equals its directory), and every id in `evals/sets/default.txt` has a task. The suite checks both.

## The tasks

| id | project | source run | category | why |
|---|---|---|---|---|
| `ah-e1-02-resume-merge` | agent-harness | agent-harness-2026-10-21-measure (E1-02) | first-time pass | a small driver fix behind a new stub mode, watched failing first; one session, 20 min, $1.03 |
| `ah-e1-05-orientation` | agent-harness | agent-harness-2026-10-21-measure (E1-05) | first-time pass | a pure function over a committed fixture with exact numbers; the cheapest kind of task, 12 min, $1.59 |
| `ah-e1-06-07-summary-trends` | agent-harness | agent-harness-2026-10-21-measure (E1-06, E1-07) | depends on an earlier feature | by order, no `after`: E1-07's ledger row and `trends --by version` carry the summary keys E1-06 adds; 15 + 31 min, $3.72 |
| `ah-p3-05-desk-housekeeping` | agent-harness | agent-harness-2026-10-19 (P3-05) | first-time pass | CLI housekeeping over the suite's throwaway tmux, from an older harness and spec; 17 min, $2.06 |
| `ah-p1-03-04-park-then-notify` | agent-harness | agent-harness-2026-10-19 (P1-03, P1-04) | depends on an earlier feature | by order, no `after`: P1-04's click URLs and actions reuse P1-03's `gh_url` and notify fields; 26 + 17 min, $5.54 |

How a task is categorised:

- **first-time pass**: every feature passed in its first real session and its milestone held verify (does a change
  keep the easy ones easy?);
- **retried or given up**: a feature with more than one real coding session (`metrics.jsonl`, `env` false), a red
  suite un-pass or a verify re-check failure in `harness-log.md`, or one given up (does a change fix the hard ones?);
- **depends on an earlier feature**: 2–3 features where a later one's `after` names an earlier feature **of the same
  task** by id (does the handoff carry what the next session needs?). *By order* (D-H35 default): a later feature with
  no `after` whose steps build on code the earlier one adds, the harness running them in array order; its `why` names
  what it reuses. Both agent-harness depends-on tasks are of this kind.

## Still to add

The spec asks for 8–12 tasks with at least two **retried or given up** and at least one **depends-on** task whose
`after` names a feature of the same task by id. agent-harness's own runs can't supply either: every feature there
passed on its first session (`metrics.jsonl`; no un-pass or re-check failure in `harness-log.md`), and the one in-task
`after` (10-19 P2-03 → P2-01) hits the grep ("alive", `.env`, secrets). The spec's sources are pathways,
dj-crate-streaming, portfolio_site and hit_list. Both E2-02 sessions had their reads refused by the permission
classifier: a mirror clone and `git` reads in the first, a plain `ls` of `~/projects/<p>/.harness/runs` in the second
(D-H35). The candidates the E2-01 survey found, to check against the rules above:

- retried: portfolio_site `portfolio_site-2026-10-20` VC2-01 and VC2-06, `…-vc4` VC5-01/03/04 (each passed on a
  second session); dj-crate-streaming `dj-2026-10-17` has 14 two-session features, most with live steps (likely out);
- depends-on with an in-task `after`: portfolio_site `v2-2026-10-18` M1-01 → M1-02; `…-2026-10-21-v3` P1-01 → P1-02
  → P1-03, though P1-01 and P1-03 name LiveKit, so the grep rules them out; pathways and hit_list run branches, unread.

Two retried tasks and one or two depends-on tasks from these bring the set to 8–9.
