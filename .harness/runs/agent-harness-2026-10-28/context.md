# Context pack for `U1-02`

Chosen by the harness from entries.jsonl in a fixed order; each item names its line. The full record is entries.jsonl / progress-archive.md.

## Discoveries for this feature

- Discovery (init, affects run): P1 and P2 of the lanes run are on origin/main (PRs #40 and #41): lib/lane.sh and lib/record.sh exist. The spec's check `git log --oneline origin/main | grep -c 'agent-harness-2026-10-26: P[12]'` prints 0 only because the merge subjects read `Merge pull request #40 from mh550/harness-merge/agent-harness-2026-10-26-P1`. The list is planned against the merged code; U1's lane rows build on P2-06's lane lines in cmd_status. → entries.jsonl:1
- Discovery (init, affects run): Driver sites by function, as the code stands: sync_main, needs_you, notify_park, merge_one, slot_open (the base-conflict note) in lib/record.sh; verify, the park branch and the given-up end in lib/lane.sh; finish, the EXIT trap and the coordinator loop in lib/driver.sh; cmd_status, cmd_report, cmd_queue, cmd_parked, cmd_gc, cmd_start, cmd_continue in bin/harness. → entries.jsonl:1
- Discovery (init, affects run): tests/checks/ ends at 50-lanes-record-pr.sh (new files from 51); tests/fixtures/check-names.txt has 601 names and the suite 602 checks. The init's full suite took 477 s on this box tonight, not the 208 s CLAUDE.md quotes: budget for it when a feature runs the suite more than once. → entries.jsonl:1
- Discovery (init, affects run): The step lint's outside-repo rule flags a tilde path and $HOME in step text; steps say 'the home directory shortened to a tilde' for the view's `home` rule. A grep in command position on progress.md, entries.jsonl, feature_list.json or context.md whose pattern matches the step itself is flagged too; harness-log.md greps are fine. → entries.jsonl:1

## What it builds on

- 2026-10-28 01:40 · U1-01 · passes: Wrote docs/plans/2026-10-28-U1-read-views.md: view.mjs API (15 functions, glyphs, width/colour/override rules, end classes), status.mjs stdin/args/files read and the v1 --json keys, the 9 existing checks the new text touches with their rewrites, the stub-state helper, check files 51-55 and the U1-02..07 order. Code unchanged; suite cached green.; tests 602 → 602; files docs/plans/2026-10-28-U1-read-views.md → entries.jsonl:2

## Lately in the run

- 2026-10-28 01:32 · init · passes: 24 features: U1 7 (plan, view.mjs, status.mjs + --json, the default view, the card, queue list/show, review), U2 9 (plan, inbox.mjs, the needs record, cards, session-side paths, git-side paths, readers, question locations, review), U3 8 (plan, project names, record after gc + gc units, show, same-project starts + overlap.mjs, overlap wiring, TTY views, review). Serial: U1 → U2 → U3.; files .harness/runs/agent-harness-2026-10-28/feature_list.json, .harness/runs/agent-harness-2026-10-28/entry.json → entries.jsonl:1

## Current rules

- The review gate: a milestone review's model by its measured diff, one Opus round after a Sonnet finding → journal/decisions/2026-10-27-review-gate.md
- Merging the memory run into lanes: main's driver changes in their lane-era homes, the review round per lane → journal/decisions/2026-10-27-p1-main-merge.md
- Lane branches go when their PR merges; gc reaps lane branches, leftover slots and a killed run's lane units → journal/decisions/2026-10-27-lane-branches-and-slots.md
- Where things go: one routing block in every session's prompt, unless CLAUDE.md has its own; one decisions store per project → journal/decisions/2026-10-26-where-things-go.md
- Verify runs the suite in full: the verified tree's cached green is removed first → journal/decisions/2026-10-26-verify-runs-the-suite.md
- Verify before the deadline: one session per complete milestone, then finish → journal/decisions/2026-10-26-verify-before-deadline.md
- A test-count contract: a suite's own `HARNESS_TESTS=<n>` line wins over scraping its summary → journal/decisions/2026-10-26-test-count-contract.md
- The suite is a runner over check files cut from the single file by its markers, grouped where a section reads another's state → journal/decisions/2026-10-26-suite-split.md
- A stop records why: `harness stop --why` and `status: stop <why>` → journal/decisions/2026-10-26-stop-reason.md
- Step lint: four pure rules over the feature list, reported and never applied → journal/decisions/2026-10-26-step-lint.md
- Reviews sized to the milestone: small milestones fold the review into their last build feature → journal/decisions/2026-10-26-reviews-sized-to-milestone.md
- The retro backlog: the retro proposes as data, the driver is the only writer → journal/decisions/2026-10-26-retro-backlog.md
- Resolved questions leave the pack; `project` facts wait under `Promote to Gotchas` until a Gotchas line carries them → journal/decisions/2026-10-26-resolved-and-project-facts.md

_45 older rules: journal/decisions._
