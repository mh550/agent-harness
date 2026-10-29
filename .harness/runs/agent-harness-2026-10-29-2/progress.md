<!-- harness: rendered from entries.jsonl after every session; edits here are overwritten -->
# Progress — run `agent-harness-2026-10-29-2` (agent-harness)

What this file is: the run's journal, rendered by the harness from `entries.jsonl` after every session, newest entry first. Each entry says what one session did, how it verified it, what it tried that failed, and what it asks Michael.

The spec is `docs/specs/2026-10-28-reliability.md`: R1 fixes the flaky checks at their cause (tests wait on conditions, `tests/run.sh --repeat` reproduces a flake), R2 keeps a session's entry (validator as the last step, a long summary trimmed, one resume for a missing entry), R3 closes the lanes-review leftovers and adds two lint rules, R4 gives questions a place to wait in `harness needs`. R1, R2 and R3 run side by side on two lanes; R4 waits for R2.

How to read the feature list (`feature_list.json`): array order is priority; `after` names what a feature really waits on; `passes` flips only when every step holds. Plans: `docs/plans/2026-10-29-R<n>-*.md`; reviews: `docs/plans/2026-10-29-R<n>-review.md`.

To steer: edit `INBOX.md` in this directory on branch `harness/agent-harness-2026-10-29-2` (first line `status: pause` or `status: stop`; answers under `## Answers`). The harness pulls before every session. Questions sessions asked are in `harness needs <run>` once R4 lands; until then in the entries below.

### 2026-10-29 09:19 · R2-01 · passes

Wrote docs/plans/2026-10-29-R2-entries.md: the entry check, the trim (399 + … so readEntries keeps it), the background rule, the resume (entry_resume in record.sh, decided before the ingest, outside the record lock, reusing session() with S_RESUME/S_TURNS/S_TIMEOUT/S_BUDGET), metrics resumeRow, the stubs, 76-entries-survive.sh's check names. N2 not on main.

- **Files:** docs/plans/2026-10-29-R2-entries.md, CLAUDE.md
- **Verified:** Each plan fact checked in code: ingest appends before exit 3; journal_ runs under record's flock; validate rejects a 401-char summary (node); metrics limit refuses the LIMIT_MIDWAY shape (rc 0); fixture costs and modelUsage by jq; N1/N2 grep = 1. Suite green, 886 (cached, plan-only tree).
- **Tests:** 886 → 886
- **Discovery** (affects R2-04): The resume must be decided before the ingest (ingest appends the minimal line before exit 3) and outside record's lock (journal_ holds it; a 10m resume would stall the other lane): entry_resume runs in journal(), not journal_.
- **Discovery** (affects R2-02): A trimmed summary of 400 + … (401) fails validate and readEntries drops it: cut to 399 + … as minimal() does.
- **Discovery** (affects R2-02): validate's header message is the same for a long string and a non-string; R2-02 gives a long one 'header: <n> characters (at most 2000)' and validate exits 2 when only caps fail.
- **Discovery** (affects R2-03, R2-04): summary.mjs counts unmatched metrics rows as sessions; entry-resume rows must be filtered out of sessions and kept in cost (summary.mjs and metrics.mjs summary).
- **Discovery** (affects R2-04): restrict commits a WIP first, so resumed.txt would be in history: drop the resume's uncommitted edits (checkout + clean outside .harness/runs) before restrict.
- **Discovery** (affects R2-04): Check 25 (STUB_BAD_ENTRY=B) gets resumed after R2-04; its note becomes 'still invalid (...) after one resume'. STUB_PARK/STUB_INBOX_IN_COMMENT write no entry and will be resumed too.
- **Proposed change:** R2-01 step 2 says the resume is called from journal_ after an ingest exit 3; the plan calls entry_resume from journal before the ingest on the same condition (validate exit 1, not refused), because the ingest has appended the minimal line by exit 3 and journal_ holds the record lock.
- **Proposed change:** R2-02 step 3 says the cut summary is '400 code points plus …' (401): readEntries would drop it; it should read '400 code points, … last' (399 + …).
- **Proposed change:** R2-03 needs two small CLI additions the steps don't name: metrics.mjs cost <transcript> (the resume's budget) and metrics.mjs append-resume (the row).
- *02-R2-01 · claude-opus-5-5*

### 2026-10-29 09:12 · init · passes

23 features: R1 7 (plan, wait_for/barriers/--repeat, sleep lint, three flaker groups, review), R2 5 (plan, entry check + trim, stub + metrics, the one resume, review), R3 6 (plan, features.mjs writes + two lint rules, merge/finish/test-count, suite-ran note + reviewer model, two lanes checks, review), R4 5 (plan, question items, ingest wiring, readers + skill, review). N1 merged, N2 not.

- **Files:** .harness/runs/agent-harness-2026-10-29-2/feature_list.json
- **Verified:** node lib/features.mjs lint on the list prints nothing (6 no-anchor findings fixed); jq parses it; 23 features, every passes false; milestones R1, R2, R3 first features after [], R4 after [R2].
- **Discovery** (affects run): N2 (conflict resolution) is not on origin main: N2-02 waits on Michael. Only N1 merged (grep -c harness-merge/...-N[12] = 1). A text conflict between two lanes needs Michael as before; each plan says so in one line.
- **Discovery** (affects R1): The flaker features (R1-04..06) run `bash tests/run.sh --repeat 10 <file>` directly in the session, never through the suite command: its CHECK_TIMEOUT is the whole suite's. One file's ten copies take minutes under load; the spec caps repeats at 30 min per flaker, then `not reproduced`.
- **Discovery** (affects R3): lib/entries.mjs already writes progress.md atomically (writeAtomic); R3-02's atomic writes concern lib/features.mjs only.
- **Discovery** (affects run): R2 and R3 both edit lib/record.sh and prompts/coding.md; R2-02 and R3-02 both edit prompts/initializer.md. Whichever merges second takes a re-base verify round; a text conflict needs Michael (no N2).
- *00-init · claude-fable-5-1*
