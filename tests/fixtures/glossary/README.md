# Glossary fixtures (lib/glossary.mjs, tests/unit/glossary.test.mjs)

Copied read-only on 2026-11-07 (A2-02) from `~/projects/dj-crate-streaming` at 429dd96 and from this repo; nothing
was changed but the cuts named here. No secret is in any of them: the INBOX names `/srv/docker/.env` and
`/etc/restic/env` as paths, with `<topic>`/`<token>` placeholders. `wt/` is a project's docs root; mtimes are not in
git, so the unit tests' reader gives each file its own.

- `feature_list.json` · dj `.harness/runs/dj-2026-10-17/feature_list.json` at 385d31c · its `run` and the features N1-01…N1-05, N1F-01, H3-02, H3-04 only, each `description` cut to 300 characters
- `feature_list-d.json` · planted · one feature `D1-01` of milestone `D1` (a project whose milestones start with D)
- `wt/docs/decisions.md` · dj `docs/decisions.md`:1-13,37-41,53 at 38ef992 · the header, `## D1–D23` with its table head and the `D1` row, `## D24 on` with its table head, `D24` and `D36 *default*`
- `wt/docs/research/2026-10-22-soulsync/README.md` · dj, the same path, lines 1 and 172-175,179 at 385d31c · the title, the `### Michael's decisions` table head and the `D24 (…)` row (a second D24, written differently)
- `wt/docs/architecture.md` · dj `docs/architecture.md`:459-462,685 at 385d31c · `## 9. M8 (built)` and its paragraph, and the `### New with M8 …` heading (a mention, not the heading's id)
- `wt/README.md` · dj `README.md`:123-125 at 385d31c · `## M8: lifecycle (…)` and its paragraph
- `wt/journal/decisions.md` · this repo's `journal/decisions.md`:1-3,11-17 at d75a3f4 · the header and `### D-H1 · …` with its body
- `wt/journal/decisions/2026-10-21-one-file-per-decision.md` · this repo, the same path, its title line and first paragraph at d75a3f4 · a decisions/*.md file (title only counts)
- `wt/docs/plans/near-miss.md` · planted · `## Q9 · …`, `## Q990 · …` and a `Q99` under no heading of its own
- `inbox.md` · dj `.harness/runs/dj-2026-10-17/INBOX.md`:1-4,35-45 at 385d31c, then `## Answers` · a park INBOX naming H3-02 and H3-04
- `text.md` · planted · the words of n8n-home's planted question (its `fixtures/bundles/f1e03cb5-…/context.json` `open_questions[0]`) without its "(planted …)" prefix
