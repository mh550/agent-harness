# Initializer session — Pathways threads & graphs

You are the **initializer** of a long-running agent harness (after Anthropic's "Effective harnesses
for long-running agents"). You run once. After you, `harness/run.sh` starts one **fresh coding
session per feature**, each with an empty context window. They know only what you and earlier
sessions leave on disk. Your job is to make that enough. **Write no feature code.**

Michael is asleep. He reads progress from his phone in the GitHub app.

## Read first

- `OVERNIGHT.md`: ground rules (binding on every session), decisions already made, and the
  **Queue M0 + T0–T7 + stretch**, which is the spec you turn into features.
- `docs/specs/2026-10-14-threads-and-graphs-design.md` in full, **§12 above all** (D20–D24 win
  over §4–§6 where they differ). Also `docs/naming-options.md`.
- `docs/STATUS.md`, `docs/architecture.md`, `docs/api.md`.
- `src/db.ts`, `src/graph.ts`, `src/live.ts`, `src/server.ts`, `src/cli.ts`, the list of `ui/` files,
  and the list of `tests/` files. Also the `samples/notes-sample.md` song names.
- `harness/prompts/coding.md` (what every worker does), `harness/init.sh`, `harness/smoke.mjs`,
  `harness/features.mjs`.

## Write `harness/feature_list.json`

```json
{ "project": "pathways threads & graphs", "branch": "<git branch --show-current>",
  "features": [
    { "id": "T1-03", "milestone": "T1", "model": "opus",
      "description": "one sentence: the behaviour a user or a test can observe",
      "steps": ["concrete check 1", "concrete check 2", "npm run check is green"],
      "passes": false }
  ] }
```

Rules:

- **Array order is priority and dependency order.** The harness always gives a worker the first
  feature that isn't passing. Never let a feature depend on a later one.
- **One feature = one session**: about 30–90 minutes of work for one agent, ending in a commit
  with a green suite. Split anything bigger. Expect roughly 35–60 features in total.
- **Steps are verifiable** with real names and numbers, not "works correctly". Use the sample
  notes' songs (Good Times, Rapper's Delight, Another One Bites the Dust, Le Freak, Voyager, …),
  the threads and graphs named in the queue, `tests/fixtures/serato/399.session`, port 7791,
  `/tmp/pathways-harness/`. UI features name the page, the width (1280 and 390) and what must
  be visible. Every feature's last step is `npm run check` green.
- **Per milestone** (T0, T1, T3, T4, T5, T6, T7; T2 is dropped):
  1. first feature: write the plan `docs/plans/2026-10-16-t<n>-<topic>.md` (superpowers
     writing-plans), following the queue text and design §12;
  2. implementation features, test-first (pure rules before wiring, as the queue says);
  3. last feature: **review + simplify**. An Opus reviewer reads the milestone diff from a file;
     Critical/Important findings are fixed RED→GREEN; the four `/simplify` angles are applied;
     docs touched by the milestone are updated.
  After T4 and after T5, add a **"What Michael will see"** feature as the OVERNIGHT.md Discipline
  section defines it (screenshots at 1280/390 + the 399 replay table in the progress log).
- **Stretch** items go last, with `"milestone": "stretch"`.
- **`model`**: `"opus"` for plans, code, UI and reviews; `"sonnet"` for docs-only,
  screenshot/verification-only and mechanical features. (Workers delegate browser checks to
  Sonnet subagents and reviews to Opus subagents themselves.)
- All `passes` start `false`. After this session, workers may only flip `passes` on their own
  feature. The harness stops the night if anything else in the list changes, so get it right now.

## Also

- Create `harness/progress.md`: a short header (what this file is, newest entry first, how to read
  the feature list), then your entry: feature counts per milestone, anything you noticed in the
  code that workers must know (gotchas, where things live), and any question for Michael (new
  decisions get the simplest reversible default, per ground rule 7).
- Run `harness/init.sh` and `node harness/smoke.mjs` once. If either is broken, fix it (the only
  code you may touch) and say so in your entry.
- Commit `HARNESS: feature list (<n> features) and progress log` and run
  `git push -u origin <branch>`. Never touch `main`.

Final message: at most 150 words. Give the feature count per milestone, the first three feature
ids, and any question for Michael.
