# Context pack for `A2`

Chosen by the harness from entries.jsonl in a fixed order; each item names its line. The full record is entries.jsonl / progress-archive.md.

## This feature's earlier attempts

- Dead end (A2-05, 08-A2-05): an event-run check counting `# Context ·` bundles against routed events — fragile across the file's runs (stale and stub bundles); a cmp of the debrief's context.md with the bundle's says it directly → entries.jsonl:10
- Dead end (A2-04, 07-A2-04): parked[].why from the needs item's .why, as the plan said — a real `harness needs parked --json` has no top-level why; it comes from <state>/parked.json, else the card headline → entries.jsonl:9
- Dead end (A2-03, 06-A2-03): `${CTX_SINCE_WHY:-the queue runner's start}` inside the moved double-quoted echo — the apostrophe in a ${:-} default parses as a quote inside a function body (bash -n: syntax error); a local `why` variable carries the default → entries.jsonl:8
- Dead end (A2-03, 06-A2-03): runSection ending at any `##`/`###` line — the fenced INBOX.md has `### B:` and `## Answers` headings of its own; it now skips ~~~ fences and also stops at every run's known heading (a part cut mid-fence leaves an odd ~~~) → entries.jsonl:8
- Question (A2-04): Default taken: a routed event's context bundle is synchronous, capped at 60 s, before the 5 s POST, and events/ bundles older than 30 days are removed when a new one is written. Keep both? Files: /home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-11-07-3/slot-1/journal/decisions/2026-10-22-context-bundle-glossary.md, /home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-11-07-3/slot-1/lib/notify.sh:55 → entries.jsonl:9
- Question (A2-02): The session's `git push -u origin harness-lane/agent-harness-2026-11-07-3/A2` was denied by the auto-mode classifier (Out-of-Place Publication); commit 62c1210 is local only. Should lane sessions be allowed that push, or does the harness push the lane branch itself? Files: /home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-11-07-3/slot-1/lib/glossary.mjs → entries.jsonl:7
- Question (A2-01): Default taken: the glossary also matches exact ids from the run's feature list that the spec's regexes miss (dj's N1F-01, S2-05a, S2-R1, N1F). Keep that, or stick to the spec's regexes only? Files: /home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-11-07-3/slot-1/docs/plans/2026-11-07-A2-context-bundle.md:60 → entries.jsonl:6
- Question (A2-01): Default taken: the debrief's own context also ends with the ## Glossary section, so its session reads the IDs explained (within the context cap). Keep it, or keep the glossary in harness context bundles only? Files: /home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-11-07-3/slot-1/docs/plans/2026-11-07-A2-context-bundle.md → entries.jsonl:6
- 2026-11-07 18:38 · A2-05 · passes: A2 review (one Opus round): 0 Critical, 2 Important, 6 Minor. Fixed RED→GREEN: I1 the debrief event's bundle is now the debrief's own (context.json from its gather, copied by context.sh --from via notify bundle=); I2 the debrief's ended words are alive-first again (ended_of; CTX_ENDED_FIRST for harness context). Minor fixed: dotted ids, spend, queue/done. Review file, decision, docs.; tests 1853 → 1857; files lib/context.sh, lib/debrief.sh, lib/notify.sh, lib/glossary.mjs, bin/harness, … → entries.jsonl:10
- 2026-11-07 18:05 · A2-04 · passes: context.json (spec key order) now comes from the same lib/context.mjs call as context.md; a bundle written in events/ prunes bundles with no file newer than 30 days and says so; notify_event writes the bundle to events/<id>/ before the POST, so context names an existing context.json; the debrief passes since=$SINCE. A failed bundle: a note, context null. Decision file, docs.; tests 1839 → 1853; files lib/context.mjs, lib/context.sh, lib/notify.sh, lib/notify.mjs, lib/debrief.sh, … → entries.jsonl:9
- 2026-11-07 17:33 · A2-03 · passes: Moved the debrief's gatherer verbatim into lib/context.sh (context_since, context_runs, context_glossary); debrief.sh sources it, no copy. New `harness context <run> | --since <ts> [--out] [--id]` writes context.md (gatherer + ## Glossary via new lib/context.mjs) to events/<uuid>/ by default. The debrief's context gains the glossary. Tests 1831 → 1839.; tests 1831 → 1839; files lib/context.sh, lib/context.mjs, lib/debrief.sh, bin/harness, tests/checks/context-bundle.sh, … → entries.jsonl:8
- 2026-11-07 17:06 · A2-02 · passes: lib/glossary.mjs: findIds (the list's own ids, then three masking passes), resolveIds (feature list; doc rows and headings newest file first; unresolved never guessed), glossaryMarkdown (byte cap, whole lines), strip, knownIds, fsReader and a CLI; 17 unit tests on fixtures copied read-only from dj-crate-streaming; tests 1814 → 1831.; tests 1814 → 1831; files lib/glossary.mjs, tests/unit/glossary.test.mjs, tests/fixtures/glossary/, tests/fixtures/check-names.txt, tests/fixtures/check-names-fast.txt → entries.jsonl:7
- 2026-11-07 16:54 · A2-01 · passes: Wrote docs/plans/2026-11-07-A2-context-bundle.md: glossary rules verbatim and how glossary.mjs applies them, dj fixtures with provenance, the line-by-line move of debrief.sh's gatherer into context.sh, harness context's CLI, context.json's shape, 30-day retention, the hook's bundle before the POST, all checks named with tiers.; tests 1814 → 1814; files docs/plans/2026-11-07-A2-context-bundle.md → entries.jsonl:6

## Discoveries for this feature

- Discovery (A2-04, affects A2-05): The event-run check's spy compares context.md beside context.json, not the plan's second `test -f context.json` (the same file twice). → entries.jsonl:9
- Discovery (A2-04, affects A2-05, run): run_context and context_glossary now read <state>/ended before alive: the driver writes ended (driver.sh:352) before its end notify, while still alive. → entries.jsonl:9
- Discovery (A2-04, affects A2-05): The debrief's bundle reruns context_since at notify time, so a run started during the debrief's session is in scope.runs but not in the note's Covers (accepted, review finding 6). → entries.jsonl:9
- Discovery (A2-04, affects A2-05): A glossary exception now costs context.json too (one node call, as the spec says). For the debrief that means a null context, so ntfy (review finding 5, accepted). → entries.jsonl:9
- Discovery (A2-04, affects A2-05, A4): notify_event's ctx is the directory context.sh prints (cd && pwd), so a trailing-slash HARNESS_STATE never gives n8n a // path (its contextPaths guard). → entries.jsonl:9
- Discovery (A2-03, affects A2-04): context.sh: context_glossary writes $WS/runs.tsv (state, run, project, ended, running, features, record, worktree, docs root, needs json) and $WS/needs-<i>.json for A2-04's context.json; context.mjs parseRow reads it → entries.jsonl:8
- Discovery (A2-03, affects A2-04, A2-05): glossaryMarkdown's cut line says 'context.json lists every one', but the debrief's own context dir never gets a context.json: reword it or write one there → entries.jsonl:8
- Discovery (A2-03, affects A2-05): harness context writes $STATE_ROOT/queue/done (an empty dir) when there is no queue yet: cmd_queue mkdirs before list; context-bundle (c) finds files only (! -type d) → entries.jsonl:8
- Discovery (A2-03, affects A2-04, A2-05): status_stubs's run ids A/B/C are matched as the run's own feature ids (knownIds), so a bare English 'A' resolves to feature A in stub glossaries; real ids (N1-01) don't collide → entries.jsonl:8
- Discovery (A2-03, affects A2-05): capped's cut note names $WS/s.json; in a `harness context` bundle that scratch is removed on exit, so the note's path is gone (debrief bytes kept as they were) → entries.jsonl:8
- Discovery (A2-02, affects A2-03, A2-04): glossary.mjs resolveIds takes featureList {path,text} and a reader {root, files()→[{path,mtimeMs,titleOnly}], read()}; fsReader(root,{mtimes}) is the fs one; knownIds(list) feeds findIds → entries.jsonl:7
- Discovery (A2-02, affects A2-05): Glossary refinements of the plan: D<n>-<digit> is a feature; a heading names an ID only before end/punctuation/a separator (not `## D24 on`, `## D1 – D23`, `## M8.1`); known ids go first → entries.jsonl:7
- Discovery (A2-01, affects A2-04): n8n-home's intake (lib/intake.js contextPaths) needs event.context = absolute <STATE_ROOT>/events/<dir>/context.json, dir = the event id (^[A-Za-z0-9-]{8,64}$); context.md beside it → entries.jsonl:6
- Discovery (A2-01, affects A2-04, run): n8n-home's intake refuses a debrief event whose context isn't a string, so A1's debrief event (context null) always falls back to ntfy until A2-04 → entries.jsonl:6
- Discovery (A2-01, affects A2-04): event-hook.sh (c),(d),(k) compare the whole note file: A2-04 sets HARNESS_CONTEXT to a stub there, or the 'context bundle failed' note turns them red → entries.jsonl:6
- Discovery (A2-01, affects A2-03): queue-debrief.sh 'the whole context is capped too' asserts <= CMAX bytes: the debrief's glossary gets only the bytes the gatherer left (--max-bytes) → entries.jsonl:6
- Discovery (A2-01, affects A2-02): The spec's regexes miss dj ids N1F-01, S2-05a, S2-R1: the plan adds exact matches of the feature list's own ids (known) as a default → entries.jsonl:6
- Discovery (A2-01, affects A2-04): status_stubs pins HARNESS_NOW in the past: events/ retention must use the real clock, or touch -d '31 days ago' reads as recent → entries.jsonl:6
- Discovery (A1-03, affects A2): event-run.sh's five stub runs plus the debrief take ~35 s; events are read from curl.log (Content-Type: application/json calls) and $HARNESS_STATE/events/*/event.json, filtered by .run → entries.jsonl:4
- Discovery (A1-03, affects A2): A park run with EVENT_URL set posts two events: park, then blocked (its end reason 'waiting on Michael: B' is ehigh); A2-04's context bundle check must select by kind → entries.jsonl:4
- Discovery (A1-01, affects run): features.mjs repair compares the list as JSON, so a jq rewrite of feature_list.json that flips only passes is not an edit. → entries.jsonl:2
- Discovery (init, affects run): A1 ships events with `context: null`; A2-04 wires lib/context.sh's bundle into lib/notify.sh's routed post (the spec's A1 text puts the bundle in A1). → entries.jsonl:1
- Discovery (init, affects run): Decision files take the spec's names (journal/decisions/2026-10-22-<slug>.md, the three §A4 lists), not today's date: the spec and n8n-home cite them so. → entries.jsonl:1
- Discovery (init, affects run): tests/fixtures/n8n-event-v1.json already holds the v1 event JSON (needs-record.sh reads its keys): the event builder's key order is checked against it. → entries.jsonl:1
- Discovery (init, affects run): tests/lib.sh exports HARNESS_NO_RUNNER=1 (queue_ensure_runner a silent no-op): A3-03's runner check unsets it for that call or reads `queue start`'s line. → entries.jsonl:1

## Current rules

- The memory curator: itemized operations, a tier the driver derives, a protected list that is fixed → journal/decisions/2026-11-07-memory-tiers.md
- The gate replaces the lint: `memlint-self` retired, `MEMORY_POLICY`, and the curator's acceptance counted → journal/decisions/2026-11-07-memory-policy.md
- One writer for project memory: a coding session's `CLAUDE.md` edit is reverted, a fact goes in the entry → journal/decisions/2026-11-07-memory-one-writer.md
- Supervised efforts for every project: one user-level skill, one dispatch list per effort, plain names throughout → journal/decisions/2026-11-05-supervised-efforts.md
- The suite's shape: check files named for what they test, no name part of another's, two cuts that need no replay, a tier on every line → journal/decisions/2026-11-05-suite-shape.md
- A merge survives an origin outage: bounded retries, a card past them, a tag that isn't claimed, gc holds verified work → journal/decisions/2026-11-04-origin-retries.md
- No run ends on a clock unless asked to: `HOURS` defaults to none, and the night leaves the docs → journal/decisions/2026-11-04-no-default-end-time.md
- A red verify opens a fix round, not a card: at most `MAX_FIX_ROUNDS` per milestone, each one counted → journal/decisions/2026-11-04-fix-rounds.md
- The unit tier: node evals become `node:test` files in one process, reported as the suite's PASS/FAIL lines → journal/decisions/2026-11-03-unit-tier.md
- The trim: 22 checks removed, each with the check that makes its assertions now; five gaps closed; no covered line lost → journal/decisions/2026-11-03-trim.md
- The suite's tiers: every check file declares `fast` or `slow` on line 2, and `tests/run.sh --tier` runs one tier → journal/decisions/2026-11-03-suite-tiers.md
- The trace switch: `HARNESS_XTRACE=<dir>` traces every harness process, off unless set → journal/decisions/2026-11-03-suite-coverage.md
- The resident helper: one warm node process per driver and lane answers the `.mjs` questions over a coproc → journal/decisions/2026-11-03-resident-helper.md
- The purity moves: the bash decision tables become pure functions with a unit test per branch; no note text changes → journal/decisions/2026-11-03-purity.md
- The fast gate: `check.sh --fast` runs the fast tier, marks `fast-<key>`, and a fast-green is never read as a green → journal/decisions/2026-11-03-fast-gate.md
- The check count and the check budget: every verified milestone says what it added to the suite, against a budget when the spec set one; a note, never a gate → journal/decisions/2026-11-03-check-budget.md
- A run never starts on a spec that isn't there: `harness start` and `queue add` refuse a spec absent from the run's base ref → journal/decisions/2026-10-31-spec-must-exist.md
- One full run per coding session, last: the prompt's rule and §3 order, and `Suite runs` in the report → journal/decisions/2026-10-31-one-full-run.md
- Fewer node starts: where a stub run's process starts come from, and the cuts C1 makes → journal/decisions/2026-10-31-fewer-node-starts.md
- The suite's length in every prompt: a green marker's `wall` line, and a timeout rule → journal/decisions/2026-10-30-suite-length-in-prompt.md
- A red tree is cached: `red-<key>`, so the next full call on the tree just found red runs nothing → journal/decisions/2026-10-30-red-marker.md
- A mapped path's change runs only its readers: `CHECK_KEY_MAP`, the `part-<key>` sidecar, the partial run, the lint → journal/decisions/2026-10-30-partial-key.md
- The coordinator opens no lane while a lane that exited is not reaped yet → journal/decisions/2026-10-30-opens-wait-for-reap.md
- The lane guard reverts against the lane's merge-base with main, in the index only → journal/decisions/2026-10-30-lane-guard-base.md
- Timing checks bound CPU time; a stopped file's missing names don't void `HARNESS_FAILED=` → journal/decisions/2026-10-30-cpu-time-bound-and-stopped-files.md

_77 older rules: journal/decisions._
