# The review surface: the memory PR's verdict on Michael's phone through n8n, merge and close as the card's two actions (2026-11-10)

**Goal.** Since the memory reviewer run (`agent-harness-2026-11-09`, PR #167 R1, PR #168 R2) every memory PR opens with a
`## Review` section, one line per operation (`holds`, or `fails: <reason>`), and the driver notes the one-line verdict
(`memreview.mjs line`) after both PR notes. Under `MEMORY_POLICY=pr` (every project today) the PR is Michael's, and it
reaches him through GitHub and `harness report` alone: the run's one end notification goes out in `finish` before the
retro, the curator and the reviewer run, so nothing he is told carries the memory outcome. Michael's rule
(`journal/learning/2026-11-07-memory-curator.md` §12): *make approval one click*. This spec is that click. **V1**: one
`memory` event per run with a memory PR, after the reviewer's verdict is written, as a v2 of the n8n events contract
(`"v": 2` on that kind alone; every v1 kind and key unchanged), behind one switch, with the plain ntfy line as the
fallback and as the whole behaviour while the switch or `EVENT_URL` is unset. **V2**: two request verbs the card's two
actions write, `merge` and `close`, each run by `harness requests` with its refusals in the result JSON, a close with a
reason landing as a decline the next curator reads, and the checklist the n8n-home half is built from. Two milestones
in series: V1, then V2.

**Provenance.**

| what | came from |
|---|---|
| the piece itself: the memory PR's tally and its merge or decline actions on the phone, through n8n, as its own piece after the n8n events run, a v2 of the contract on this side and a session in n8n-home for its half | Decision 21 (a), Michael, 2026-11-07 (`docs/plans/2026-11-03-test-suite-redesign-dispatch.md`, row F3d); §13 item 7 of the learning file |
| written after the reviewer run, so the event carries the verdict in its final shape | Decision 26 (a), Michael, 2026-11-09 |
| the kind `memory`, its `title`, `body`, `click` and the `memory` object field, as named | `docs/specs/2026-11-08-memory-reviewer.md` R2-02 §5; `decisions/2026-11-09-memory-graduation` (its F3d bullet); `docs/architecture.md`'s *Routed events* row |
| one text in three places so the note, the `Memory` row and the card cannot differ | R2-02 §5: `memreview.mjs line`, `heldFailed` |
| the overrides the card's two actions land in: a PR merged against a fail, edited or closed against a hold; a closed PR of a run with a declined `--why` row is none | `decisions/2026-11-09-memory-graduation` (R2-02 §2), `lib/summary.mjs` `memoryOverride`, `declinedRuns` |
| v1 goes live first, by Michael's checklist | `docs/plans/2026-10-22-n8n-events-live.md` (not done: `EVENT_URL` is unset in `~/.config/harness/config.sh` on 2026-11-10; no event has ever been routed); dispatch row F3d, session 22 |
| n8n never runs host commands and never writes GitHub; its one write is the request inbox | `docs/specs/2026-10-22-n8n-events.md` A3; n8n-home's `docs/specs/2026-10-22-harness-reporter.md` §4.3, §5 |
| the rules PR is Michael's under every policy | the follow-up's invariant 3 (`decisions/2026-11-08-memory-rules-pr`), the reviewer's invariant 4 |

**Source.** `docs/specs/2026-10-22-n8n-events.md` (the v1 contracts: event, request, result; A1 to A3; its rule *change
nothing without a new `v`*); `docs/plans/2026-10-22-n8n-events-live.md` (Michael's two stages); `lib/notify.mjs`
(`KINDS`, `ROUTED`, `buildEvent`, the `event` CLI; a kind outside v1 exits 2), `lib/notify.sh` (`notify`'s `case $kind`
line, `notify_event`: the bundle, the POST, `event hook failed (<why>): <kind>; sent to ntfy`, the ntfy branch);
`lib/requests.mjs` (`validateRequest`'s rules in order, `resultJson`'s ten keys, `logLine`, the 10 s grace, `ID_RULE`,
`RUN_RULE`), `lib/requests.sh` (`one()`: the claim, the argv call, `result`); `lib/memreview.mjs` (`line`, `heldFailed`,
`verdicts`' `{id, holds, reason, q}`); `lib/record.sh` (`memory_pr`: the dry apply, `memory_review`, `memory_verdict`,
`memory_json`'s keys, the policy branch, `memory_merge`, the `line` note last; `memory_open`'s notes; `memory_tip`: a
closed PR stops the same branch's curator); `lib/driver.sh` (`finish`: the end notification before the retro and the
curator; `curator()`; `memory_review()`); `lib/memory.sh` and `lib/memory.mjs` (`accept|decline <run>/<n> --why`,
`answerRow`: tier 1 is not numbered; `upsert`; `answersText` in `lib/curator.mjs`, `latestAnswers`, `apply`'s
`declined by Michael` drop by key); `lib/summary.mjs` (`memoryRows`, `tierReview`, `memoryState`, `memoryOverride`,
`declinedRuns`, `graduation`); `tests/stub-gh.sh` (`pr view <url> --json state,mergedAt,commits`, `pr merge` with
`--match-head-commit`, `pr close <head>`), `tests/checks/event-hook.sh` (fast), `event-run.sh` (slow), `request-files.sh`
(fast), `memory-review.sh` (slow), `tests/unit/notify.test.mjs`, `requests.test.mjs`, `memreview.test.mjs`,
`memory.test.mjs`, `tests/fixtures/n8n-event-v1.json`, `tests/fixtures/requests/`; n8n-home (read only):
`lib/intake.js` (`EVENT_KEYS`: exactly the 13 v1 keys; `v !== 1` refused; `ROUTED_KINDS`; 422 with the problems, nothing
stored, no ntfy), `lib/card.js` (`buildRequest`: request v1, `REQUEST_KEYS`, ids `1-<hash>` and `2-<hash>` from a
SHA-256 of the event and the answer, D25), `docs/workflows.md` (10 intake, 40 card, 41 card serve, 90 error handler),
`CLAUDE.md` `## Live system` (deploys only through `scripts/deploy.sh` under `flock -n /srv/n8n/live.lock`, workflows
imported inactive unless the repo says active, nothing in the backup window), `docs/plans/2026-10-22-live-checklist.md`
(steps 13 to 16 wait on Run A); `journal/learning/2026-11-07-memory-curator.md` §10 (the measurement points every
Predictions row names) and §12.

**Rules.** `CLAUDE.md` binds: worktree only; never touch real runs or real state; **never a real notification and never a
POST to any URL** (the hook is tested against the `HARNESS_CURL` stub as `event-run.sh` does, `gh` against
`tests/stub-gh.sh`); fakes mirror the live API (an event or request shape is copied into `tests/fixtures/`, never guessed;
n8n-home builds to those files); every behaviour visible in `harness-log.md`, `run.log`, `requests.log` or a command's
output and checked test-first in `tests/checks/` (tier by `decisions/2026-11-03-suite-tiers`'s 30 s rule, names in
`tests/fixtures/check-names.txt` and, fast, `check-names-fast.txt`), a pure function's in `tests/unit/`; a check that
duplicates an assertion replaces it and the old name leaves the fixture in the same commit; `bash -n`, `node --check`;
one decision file per milestone (`journal/decisions/<run date>-review-surface-event.md` for V1,
`<run date>-review-surface-verbs.md` for V2); `docs/architecture.md` and `README.md` in the same milestone as the code.
**Proceed on the defaults written here; record them marked *default*; never park.**

**Four invariants no feature may break.** (1) **Every v1 event is byte-identical to today.** `buildEvent` for the ten v1
kinds prints the 13 keys of `tests/fixtures/n8n-event-v1.json` with `"v": 1`; only the `memory` kind carries `"v": 2`
and the 14th key. (2) **Unset means unchanged.** With `EVENT_URL` unset, or `EVENT_V2` unset, no POST carries a `memory`
event; the kind goes to ntfy (or `NOTIFY_CMD`) as every non-routed kind does today, and the run's end notification is the
same bytes as before this spec. (3) **The driver never merges the rules PR, and nothing here lets it.** A `merge` request
is Michael's hand, run by `harness requests` from a file the card wrote; `memory_merge` is untouched and `merged_by:
driver` stays the driver's alone. (4) **One count.** The card's actions write no row of `ledger/memory.jsonl` and no
state; `harness memory` reads gh's state at listing time as it does today, so a merge against a fail or a close against
a hold is counted once, where it is counted now. The one ledger write a card action may make is a declined row of
`ledger/memory-answers.jsonl`, through `harness memory decline`, as a hand decline would.

## Depends on

- **The reviewer run merged** (it is: PR #167, #168, record PR #170). The event's text is `memreview.mjs line`'s and
  its field `memory_json`'s keys; this spec names them as built (`decisions/2026-11-09-memory-reviewer`,
  `decisions/2026-11-09-memory-graduation`) and turns on no particular spelling of theirs.
- **The order: v1 live, this build, then n8n-home's half.** Michael does the v1 checklist's two stages first
  (`docs/plans/2026-10-22-n8n-events-live.md`: Stage 1 `EVENT_URL`, Stage 2 the request inbox's path unit). This
  build does not need them: it is inert without `EVENT_URL` and `EVENT_V2` and tested against stubs. The order stands
  for two reasons. The first `memory` event must land on an intake that has already taken a v1 event, so a refusal is
  this spec's to read and not v1's; and the n8n-home half's rig fixtures are shaped from this repo's
  `tests/fixtures/` until a captured event exists (its checklist step 16), so n8n-home comes last. The queue command
  may be issued before Michael's stages are done: the run's checks stand on stubs either way.
- V2 after V1 (V2's verbs act on the PR the V1 event names; V2's checks read V1's fixture). V1's first feature `after:
  []`, V2's `["V1"]`.
- Nothing here touches the reviewer's four questions, the graduation rule, `MEMORY_POLICY`'s default, the recurrence
  measure (F3e) or the prune (F3c).

---

## V1 · The event: kind `memory`, v2 of the contract, once per run with a memory PR, the ntfy line otherwise

**Finding.** Three things are true of the memory PR's path to Michael today. (a) `finish` sends the run's one end
notification before the retro and the curator ("the run's one end notification goes out now, not after the retro"), so
the memory outcome is in no notification: he learns of a memory PR from GitHub's own mail or from `harness report`. (b)
The text that would tell him exists and is one function: `memreview.mjs line` (`memory: facts 1 held · 1 failed
(facts/2: 7 files: …, q2) · rules 1 held · PR <url> · rules PR <url>`), noted once after both PR notes; its counts are
`heldFailed`, which the `## Review` section and the report's `Memory` row print too. R2-02 §5 named the event that
carries it (kind `memory`, title `[<run>] memory: <held> held · <failed> failed`, body the line, click the facts PR, one
object field `memory` beside `context`) and sent nothing. (c) The hook that would carry it is live against a contract
that refuses it. n8n-home's intake (`lib/intake.js` `eventProblems`) takes exactly the 13 v1 keys, `v` 1 and one of
four kinds; a `memory` event with a 14th key is a 422 with the problems, stored nowhere, and `notify_event` then notes
`event hook failed (422): memory; sent to ntfy` and sends the ntfy post. That fallback is right once, and wrong as
the steady state until the n8n-home half lands: one failure note in every run's `harness-log.md`, for a refusal the
harness could know about. And no routed event has ever been sent: `EVENT_URL` is unset on the box, so the v1 path has
not been exercised live either.

### V1-01 · The shape: `buildEvent` v2 for the `memory` kind, the `memory` object from the record, the title

**Choice.**

1. **The contract, v2** (recorded in this spec and under `docs/specs/2026-10-22-n8n-events.md`'s *Contracts* by one
   `Updated in place <run date>: v2 adds …` line that points here; n8n-home builds to this file and the fixtures):
   ```json
   { "v": 2, "id": "<uuid>", "at": "<ISO 8601>", "kind": "memory",
     "project": "agent-harness", "run": "agent-harness-2026-11-09", "feature": null,
     "title": "[agent-harness-2026-11-09] memory: 2 held · 1 failed",
     "body": "memory: facts 1 held · 1 failed (facts/2: 7 files: tests/checks/needs-cards.sh, …, q2) · rules 1 held · PR https://github.com/… · rules PR https://github.com/…",
     "priority": "", "click": "<the facts PR, else the rules PR>",
     "actions": "view, Facts PR, <url>; view, Rules PR, <url>", "context": null,
     "memory": { "pr": "<url or null>", "rules_pr": "<url or null>", "policy": "pr|auto",
                 "reviewed": 3, "held": 2, "failed": 1,
                 "failures": [ { "id": "facts/2", "section": "## Gotchas", "q": 2, "reason": "7 files: tests/checks/needs-cards.sh, …" } ],
                 "state": "open|merged", "review": "ok|<why none>" } }
   ```
   The first 13 keys are v1's, in v1's order; `memory` is the 14th. `"v": 2` on this kind alone: every v1 kind keeps
   `"v": 1` and its 13 keys (invariant 1; *default*: the alternative, `"v": 2` on every event once the switch is set,
   changes ten kinds for no gain and makes n8n-home's intake take v2 for events whose shape did not move). `priority`
   is `""` (nothing is blocked; a memory PR waits as a record PR does), `feature` null, `context` null (§V1-02 3).
   `title` is R2-02 §5's with `memory.json`'s `held` and `failed` (`heldFailed`), or `[<run>] memory: review none` when
   `review` is not `ok` (*default*: `0 held · 0 failed` would read as a verdict where there was none). `click` is the
   facts PR, else the rules PR when only that one exists (*default*); `actions` is `notify.mjs actions`' header over
   both PRs (an empty URL is skipped, as today). The `memory` object is R2-02 §5's, as named, plus one key, `review`
   (`memory.json`'s: `ok`, or why none), so the card knows whether a merge is offered without parsing the body
   (*default*; §V2-02 refuses a merge of an unreviewed PR, and the card must not offer what the inbox refuses).
   `failures[]` is one entry per failed op of either tier from the verdicts (`id`, the input item's `section`, the
   failing row's `q`, null for thin or not reviewed, and the `reason` without its ` (q<n>)` suffix, as `line` strips
   it); `state` is `merged` when `merged_by` is `driver` (the `auto` landing), else `open`. The fixture is
   `tests/fixtures/n8n-event-v2-memory.json`, copied from a stub run's `events/<id>/event.json` with placeholders put
   back as the v1 fixture was made, and `n8n-event-v1.json` is unchanged.
2. **`lib/notify.mjs`**: `KINDS` gains `memory`; `ROUTED` is unchanged and a new `ROUTED_V2 = [...ROUTED, "memory"]`
   says which kinds route when the switch is set (§V1-02). `buildEvent` takes `memory=<path>` (a JSON file the
   driver wrote; *default*: a path, as `bundle=` and `context=` are paths, so no JSON crosses bash) and gives the v2
   shape above for `kind=memory`; for any other kind `memory=` is refused (exit 2, `memory= is the memory kind's`),
   so no v1 event can grow a key by a call-site slip. A `memory` event without `memory=` is refused too.
3. **`lib/memreview.mjs card <verdicts.json> <memory.json> <input.json> <policy>`** (pure `card(v, m, items,
   policy)`): the `memory` object above from the files the driver already has (the verdicts' `ops`, `memory.json`'s
   `pr`, `rules_pr`, `reviewed`, `held`, `failed`, `review`, `merged_by`; the input's items for each failure's
   `section`), and `title(m)` for the title. With no verdicts file (a review none) `failures` is `[]` and `review` the
   why. Written by `memory_pr` to `$SCRATCH/memory-event.json` and kept in the run record as `memory-event.json`
   (beside `memory-review.json`), so what was sent is readable after the fact.

**Checks (written first).** Pure, `tests/unit/notify.test.mjs`: `buildEvent` for `kind=memory` with `memory=<file>`
prints the 14 keys of `tests/fixtures/n8n-event-v2-memory.json` in order with `v` 2 and the file's object; every v1 kind's
output is the v1 fixture's 13 keys with `v` 1, byte-identical to before (the existing `buildEvent's keys are the v1
fixture's, in order` extends to say so, replacing that name); `memory=` on a v1 kind and a `memory` kind without it exit 2
and print nothing; `ROUTED` is unchanged and `ROUTED_V2` is it plus `memory`. `tests/unit/memreview.test.mjs`: `card`
builds the object from a verdicts file with one fail (section from the input, `q` 2, reason without the suffix, `state`
open under `pr` and merged with `merged_by` driver), from a review none (`failures` empty, `review` the why), and
`title` prints the counts line or `review none`; `card` as a command prints the object as one JSON line.

**Files.** `lib/notify.mjs` (`KINDS`, `ROUTED_V2`, `buildEvent`, the `event` CLI's `memory=`), `lib/memreview.mjs`
(`card`, `title`, the CLI), `tests/fixtures/n8n-event-v2-memory.json`, `tests/unit/notify.test.mjs`,
`tests/unit/memreview.test.mjs`, `tests/fixtures/check-names.txt`, `check-names-fast.txt`, `docs/architecture.md`
(`lib/notify.mjs`'s row: `ROUTED_V2`, `memory=`; `lib/memreview.mjs`'s row: `card`, `title`; the *Routed events* state
row: v2 and `memory-event.json`), `docs/specs/2026-10-22-n8n-events.md` (the one `Updated in place` line), the V1
decision file.

### V1-02 · The send: once per run with a memory PR, after the verdict, behind `EVENT_V2`; the ntfy line otherwise

**Choice.**

1. **When.** At the end of `memory_pr`, where the `memory:` line is noted today ("after both PR notes, the one line the
   F3d card will carry"): once the verdict is written (`memory_verdict`, or a review none), the landing done, the PRs
   opened or refreshed and `memory_json` written, and only when a PR exists (`url` or `rurl` is `http*`). One `notify`
   call: `notify "$line" title="$(title)" body="$line" click=<facts PR> actions=<both PRs> kind=memory
   memory=$SCRATCH/memory-event.json priority=""`. **None for a run with no PR**: `curator: no operations`, an invalid
   ops file, an apply that failed, a landing that differed from the dry apply, every op dropped (`memory PR: none`), or
   `MEMORY_POLICY=off`, each as today, and no event (no PR, no card). **The run's end notification is
   unchanged** (invariant 2): it goes out where it does, with the bytes it has; this event is a second notification,
   minutes later, from the curator step. A continue that reuses the PR sends one per segment that reached a PR, each
   with its own id (*default*: n8n-home stores events by id and builds one card per event; the newer card is the one
   to act on, and its `state` and counts are the latest segment's as `memory.json` is).
2. **The switch, `EVENT_V2`** (`lib/config.sh` default `""`, `templates/user/config.sh` one commented line under
   `EVENT_URL`). `notify`'s routing line becomes: a kind in `ROUTED` routes when `EVENT_URL` is set; `memory` routes
   when `EVENT_URL` **and** `EVENT_V2=1` are set; otherwise the kind goes to ntfy (or `NOTIFY_CMD`) exactly as every
   non-routed kind does today, **with no POST and no failure note**. Why a switch and not the 422 fallback: n8n-home's
   live intake refuses a v2 event today (the Finding's (c)), and a refusal per run is a `note` in every `harness-log.md`
   for a state the harness can be told once; Michael flips `EVENT_V2=1` as the last step of the n8n-home checklist
   (§V2-03), after that deploy, and the 422 fallback stays what it is for the day the intake is down. Rejected: probing
   the intake (an n8n webhook answers a GET with nothing the harness can read, and a probe per run is a request per
   run); a per-kind list in config (the kinds are the contract's, not a knob); sending the v2 event and swallowing the
   422 silently (a refusal the note does not show is the 2026-10-17 kind of miss).
3. **No bundle for `memory`** (*default*). `notify_event` writes `events/<id>/event.json` and POSTs, and skips the
   context bundle (`context: null`): the card is built from the `memory` field, the body and the PRs, the bundle's
   glossary resolves the IDs of a parked question and the line has none it resolves (`facts/2` is not a glossary ID),
   and the bundle costs up to 60 s inside `finish`, after the retro, the curator and the reviewer have already run. The
   `## Review` table the card may want is in the run record's `memory.md` (the ledger's copy once `ledger` ran, minutes
   after the event; §V2-03 tells the card to read it when served, not when built).
4. **While `EVENT_URL` is unset, or `EVENT_V2` is**: the one ntfy post (or `NOTIFY_CMD` call) with the title, the line
   as its body, the facts PR as its click and both PRs as view actions, as every non-routed kind today. This is what
   every project gets on the day V1 merges, and it is already more than today: no notification carries the memory
   outcome now. A body over 3500 bytes (many failures) is trimmed as every body is (`notify_trim`).
5. **Visible.** `run.log`: `event → n8n: memory <id>` on a 2xx, as every routed kind; `notified: [<run>] memory: …` on
   the ntfy path; the fallback's `event hook failed (…): memory; sent to ntfy` when the POST fails with the switch set.
   `harness-log.md`: no new note on the happy path (the `memory:` line is already there); the failure note as today.
   `memory-event.json` in the run record and `events/<id>/event.json` in the state root.

**Checks (written first).** Stub runs, a new slow file `tests/checks/memory-event.sh` (one file for this spec's stub runs,
so `memory-review.sh` keeps its 119 s; timed alone when made, its row under the tiers decision's table; the stub `curl`
records each POST's URL and body as `event-run.sh`'s does): `STUB_MEMORY_REVIEW=evict-fails` on `stub-cap-evict` under
`pr` with `EVENT_URL` and `EVENT_V2=1` set → one POST to `EVENT_URL` whose body is valid v2 JSON (`v` 2, 14 keys, `kind`
memory, `memory.failures[0].id` `facts/<n>`, `state` open, `review` ok), no ntfy post for it, `event → n8n: memory` in
`run.log` after the `memory:` note, `events/<id>/event.json` and the record's `memory-event.json` equal to the body, and
the run's end notification identical to the same run's with both unset (the stub's record of it, byte for byte); the same
run with `EVENT_URL` set and `EVENT_V2` unset → no POST of a `memory` event, one ntfy post with the title, the line and
both PRs' actions, no `event hook failed` note; with both unset → the same ntfy post; the stub `curl` answering 422 with
the switch set → the POST, then the ntfy post and the one note; `stub-three-ops` under `auto` with `hold` → `state`
merged in the event, sent after the merge note; `stub-proposal` (no PR) and `STUB_MEMORY_REVIEW=none` under `pr` → no
event and no memory ntfy for the first, and for the second one event titled `review none` with `failures` `[]`. The
fixture `n8n-event-v2-memory.json` is diffed against the first run's `event.json` with placeholders (a check, so the
fixture n8n-home copies cannot drift from what the driver sends).

**Files.** `lib/notify.sh` (`notify`'s routing line, `notify_event`'s no-bundle branch for `memory`), `lib/record.sh`
(`memory_pr`: the `card` call, the `notify` call, `memory-event.json` into the record), `lib/config.sh` (`EVENT_V2`),
`templates/user/config.sh`, `tests/checks/memory-event.sh`, `tests/fixtures/check-names.txt`, `docs/architecture.md`
(`lib/notify.sh`'s row; the CURATOR step gains the EVENT line; the config table: `EVENT_V2`; the guards table's *Event
hook fallback* row: the `memory` kind), `README.md` (*Notifications*: the `memory` kind and `EVENT_V2`; *Memory
reviewer*: the card), the V1 decision file (finding · choice · rejected: the probe, the per-kind list, the silent 422,
`"v": 2` on every kind, a bundle for the memory event).

### V1-03 · Review (Opus)

Sized to the milestone: an Opus reader of V1's diff, the review feature last. Hardest: that no v1 event changed a byte
(`buildEvent` on each v1 kind against the v1 fixture, and `event-hook.sh` and `event-run.sh` green with no edit to their
assertions); that `memory` is never POSTed with `EVENT_V2` unset, whatever `EVENT_URL` says (`grep -n ROUTED lib/*.sh
lib/*.mjs`, the routing line read); that the end notification's bytes did not move (the check's byte compare, and
`finish` unread by the diff); that the fixture is a stub run's output with placeholders and not typed; that
`memory-event.json` is written only when a PR exists. Findings are fixed in the same feature; the review's file is
`docs/plans/<run date>-V1-review.md`.

---

## V2 · The verbs: `merge` and `close` from the card, their refusals, a close with a reason as a decline, the n8n-home checklist

**Finding.** The request inbox (A3) turns two verbs into harness commands under one rule set: a request is a file n8n
writes, judged in node (`validateRequest`: `v` 1, the id and run patterns before any path, a real run, the text's
bounds, no NUL), claimed, run as one argv call with no shell, answered by a result file the card polls and one
`requests.log` line without the text. It is the one path from the phone to the box and n8n's one write. The two
verbs it has steer a run (`answer`, `continue`); neither touches a PR, and a memory PR is not a run's state: it is a
ledger row (`ledger/memory.jsonl`, one per PR, with its tier, its review and `merged_by`) and gh's state. What the card
needs is two more verbs on that row's PR, with the refusals the ledger and gh can give, and one answer to the question
the graduation rule already asks: when Michael closes a PR with a reason, is that an override of the reviewer or a
decision with a why? `memoryOverride` answers it today for a run with a declined row of `memory-answers.jsonl` (its
`--why` is the reason; `declinedRuns`), and `harness memory decline` writes such a row only for a numbered item
(`<run>/<n>`: a tier-2 rule or a tier-3 proposal). The facts PR has none (`answerRow`: *tier 1 is not numbered*), so
a close of the facts PR with a reason has nowhere to put it.

### V2-01 · The request and result, v2: `merge` and `close`, the ledger's PR, the reason's bounds

**Choice.**

1. **Request JSON v2**, written by n8n's card (`tests/fixtures/requests/merge.json`, `close.json`, `close-why.json`):
   ```json
   { "v": 2, "id": "<n>-<hash>", "at": "<ISO 8601>", "verb": "merge|close", "run": "<run id>",
     "pr": "<the PR's URL, as the ledger row has it>", "why": "<one line, at most 300 characters; close only, optional>",
     "source": "n8n-card", "event": "<event id or null>" }
   ```
   A v1 request is unchanged (`answer`, `continue`, the two verbs n8n writes today). `v` 2 carries `merge` or `close`
   and nothing else; a v2 `answer` or a v1 `merge` is rejected (*default*: one shape per version, so the validator has
   two branches and n8n-home's `buildRequest` two). `pr` must be the `url` of a row of `ledger/memory.jsonl` whose `run`
   is the request's (the rows are passed to `validate` as `--memory <file>`, read in node); `why` is `WHY_MAX`'s rule
   (`lib/curator.mjs`: one non-blank line, at most 300 characters, the hand decline's) and is refused on a `merge`
   (*default*: a merge against a fail has its reason in the override count, not in a row; the card's merge button has
   no note field).
2. **Result JSON v2**: the ten v1 keys in order, then `pr` (the URL) and `state` (`merged`, `closed`, or null when
   nothing was done), with `runner_started` always false. `requests.log`'s line gains `pr=<url>` after `run=` for a
   v2 request and never carries the why (as it never carries the text).
3. **The refusals** (`ok` false, `exit` null, `refused` the reason; the request moves to `rejected/` as every refusal):
   - `pr <url> is not a memory PR the ledger knows (ledger/memory.jsonl)`: no row has that URL;
   - `pr <url> belongs to run <row's run>, not <request's run>`;
   - `v 2 carries merge or close`, `v is not 1 or 2`, `why must be one line of at most 300 characters`, `a merge takes
     no why`, and v1's rules as they are (the id pattern, no NUL, the 10 s grace, a duplicate id).
   Two more are gh's and the row's, decided in `requests.sh` after the claim (§V2-02): `pr <url> is already merged`,
   `pr <url> is already closed`, and `the review did not run for <url> (<why none>): merge it on GitHub if you mean to`.
   A refusal never quotes the why (A3's rule for text).

**Checks (written first).** Pure, `tests/unit/requests.test.mjs`: a v2 `merge` and `close` with a known PR of the right run
are ok and carry `pr` (and `why` for the close); `v` 2 with `answer`, `v` 1 with `merge`, an unknown PR, a PR of another
run, a `why` of two lines or 301 characters and a `why` on a merge are each rejected with the reason above, and the
reason never holds the why's text; `resultJson` for a v2 request has the twelve keys in order with `runner_started`
false; `logLine` carries `pr=` for a v2 request and never a why; the `validate` CLI takes `--memory` and prints `pr`
as a labelled line. The existing `v 2 is rejected` becomes `v 2 with answer is rejected, v 3 is not 1 or 2` (replacing
that name).

**Files.** `lib/requests.mjs` (`validateRequest`'s v2 branch, `--memory`, `resultJson`, `logLine`),
`tests/fixtures/requests/merge.json`, `close.json`, `close-why.json`, `result-v2.json` (shapes copied from a check's
output), `tests/fixtures/requests/README.md`, `tests/unit/requests.test.mjs`, `tests/fixtures/check-names.txt`,
`check-names-fast.txt`, `docs/architecture.md` (`lib/requests.mjs`'s row; the *Request inbox* state row: v2), the V2
decision file.

### V2-02 · `harness requests` runs them: gh's state first, the review rule, `gh pr merge --merge`, `gh pr close`, the decline rows

**Choice.**

1. **`merge`** → `gh pr view <url> --json state` first (`HARNESS_GH`, as `harness memory` asks it): `MERGED` or
   `CLOSED` is a refusal (§V2-01), an unreadable answer is `ok` false with gh's text as the output (it ran; *default*:
   not a refusal, since the next tap may find GitHub back). Then the row's `review`: not `ok` (a review none, or a row
   from before the reviewer) → refused, *the review did not run* (*default*, for the rules PR too: the card shows a
   verdict, and a one-click merge of a PR with none is the thing invariant 3 was written against; GitHub's own button
   is one tap further). Then `gh pr merge <url> --merge` (no `--match-head-commit`, *default*: the card is Michael's
   hand, as GitHub's button, which has no such guard; `harness memory` reads a commit added after the event as `merged
   edited`, as it would for the button). `ok` is gh's exit, `output` its text, `state` `merged` on success.
   **Invariant 3 holds**: `memory_merge` and `merged_by: driver` are the driver's and untouched; a card merge is
   `harness requests`' call on Michael's request, and `harness memory` reads it as his (`merged_by` null): a merge
   against a fail is the override it is now.
2. **`close`** → the same state check, then `gh pr close <url>`, with `--comment "<why>"` when a why came (*default*:
   the reason lands on GitHub too, where the PR is read, so the ledger and the PR say the same; never
   `--delete-branch`, as `record_pr`: the branch is the record of what was proposed, and `memory_tip`'s rule that a
   closed PR stops the same branch's curator is for the same run's continue, which is what Michael's close means).
   `state` `closed`.
3. **A close with a why is a decline** (where a declined row is meant: `decisions/2026-11-09-memory-graduation`, *a closed
   PR of a run with a declined row is none*):
   - **the rules PR**: `harness memory decline <run>/<n> --why "<why>"` for each `rules/<n>` of the run's
     `memory-result.json` (the ledger's copy, as `harness memory proposals` reads it), one row each, so the next
     curator reads them under *Michael declined* and `apply` drops them by key, never proposed again (N2-03's purpose);
   - **the facts PR**: `harness memory decline <run> --why "<why>"`, a **run-level decline**, new in `lib/memory.sh` and
     `lib/memory.mjs` (`answerRow` with no `n`): one row `{run, project, n: null, tier: 1, verdict: "declined", why,
     file: null, section: null, text: null, key: null, at}`, upserted on `(run, n null)`. `declinedRuns` already reads
     any declined row of the run, so the close reads as *not an override* with no change to `memoryOverride`;
     `answersText` lists it as `- the facts PR of <run>, closed: <why>` under *Michael declined* (the curator reads why
     a whole PR was refused); `apply` matches answers by key and a null key matches nothing (a unit test says so);
     `proposalsView` and `answersTally` count it as a declined answer of the run. The hand form `harness memory decline
     <run> --why` is Michael's too, for a PR he closes on GitHub with a reason he wants the curator to read.
   - **A close without a why writes no row**: `harness memory` counts it as `closed against a hold` when every op held,
     the override it is now (invariant 4; the card's close button has a note field whose emptiness is the choice).
   The decline rows are written after the close succeeded, under the ledger lock as the hand command takes it; a
   decline that fails (no `memory-result.json` in the ledger yet: the run's `ledger()` had not run) is one line in the
   result's `output` and the close stands (*default*: the PR's close is what he asked; the row can be written by hand).
4. **Idempotent as today**: a double tap writes the same id (n8n-home's hash rule), the second is a duplicate and the
   first result stands; a `merge` whose PR gh already merged between the view and the merge is `ok` false with gh's
   text.
5. **The card offers both PRs' merge and close.** The rules PR's merge is Michael's under every policy (the follow-up's
   invariant 3) and the card is his hand: the `merge` verb takes any row's PR, facts or rules, under the same review
   rule, and `docs/architecture.md`'s invariant gains the sentence *a merge request from the card is Michael's hand,
   run by `harness requests`, never `memory_merge`*. Why not facts only: §12's direction is hands-off for code rules
   and verification, the rules PR is where those land, and leaving it two taps away on GitHub while the facts PR is
   one would make the card half a surface. The trade named: the request inbox, n8n's one writable mount (mode 700,
   Michael's uid, the card's form behind its token), can now land a reviewed rules PR as well as steer runs; the
   review rule and the ledger rule bound it to PRs the harness opened and the reviewer held or marked.
   (*default*; the falsifier on a rules PR merged against a fail from the card is where this is read.)
6. **The gh stub** (`tests/stub-gh.sh`) gains gh's real shapes for `pr merge <url> --merge` (no `--match-head-commit`:
   the head branch's tip is merged, `pr-N.merged` touched) and `pr close <url> [--comment <text>]` by URL (`pr-N.closed`
   touched, the comment kept as `pr-N.comment`), each copied from gh 2.45's behaviour as the view's commits were.
7. **Visible.** `requests.log`: `… verb=merge run=<run> pr=<url> ok exit=0` or `refused … why=<reason>`; the result's
   `output` carries gh's text; `harness memory` shows the new state on its next call, and `· <k> answered` on the run's
   line when decline rows were written.

**Checks (written first).** Pure, `tests/unit/memory.test.mjs`: `answerRow` with no `n` gives the run-level row (tier 1,
null key) and `upsert` replaces an earlier run-level row of the run; `answersText` renders it under *Michael declined*
with its why; `tests/unit/curator.test.mjs`: `apply` with a run-level declined row drops no op (a null key matches
nothing); `tests/unit/summary.test.mjs`: `memoryOverride` reads a closed facts PR of a run with a run-level declined row
as no override (extending the existing closed-with-decline test, replacing that name). A new fast file,
`tests/checks/memory-requests.sh` (no stub run: a fixture `ledger/memory.jsonl` with a facts row and a rules row of one
run, their PRs made in the stub gh, `HARNESS_GH` the stub, `HARNESS_NOW` the fake clock, as `request-files.sh` works):
a `merge` of the facts PR merges it in the stub (`pr-N.merged`), its result is `ok` with `state` merged and `requests.log`
has `pr=`; a `merge` of the rules PR merges it the same way and `harness memory` then reads `merged unchanged` for both;
a second `merge` of a merged PR is refused *already merged*; a `close` without a why closes it, writes no
`memory-answers.jsonl` row, and `harness memory` reads `closed against a hold` for a row with every op held; a `close`
of the facts PR with a why closes it with the comment, writes one run-level declined row, and `harness memory` reads no
override; a `close` of the rules PR with a why writes one declined row per `rules/<n>` and `harness memory proposals`
shows each verdict; a `merge` of a PR whose row's `review` is not `ok` is refused *the review did not run*, nothing
merged; an unknown PR and a PR of another run are refused; a duplicate id stands on the first result; the stub gh
refusing the merge (`STUB_REFUSE_MERGE`) gives `ok` false with gh's line as the output and no refusal;
`harness memory decline <run> --why` by hand writes the run-level row and one ledger commit, and without `--why` is one
error line, exit 1.

**Files.** `lib/requests.sh` (`one()`'s v2 branch: the view, the review rule, the gh call, the decline calls),
`lib/requests.mjs` (`validate`'s labelled `pr` and `why` lines), `lib/memory.sh` (`decline <run> --why`, the usage
line), `lib/memory.mjs` (`answerRow` without `n`, `upsert`'s key), `lib/curator.mjs` (`answersText`'s run-level line;
`apply`'s null-key guard if one is needed), `bin/harness` (the usage line), `tests/stub-gh.sh`,
`tests/checks/memory-requests.sh`, `tests/unit/memory.test.mjs`, `tests/unit/curator.test.mjs`,
`tests/unit/summary.test.mjs`, `tests/fixtures/check-names.txt`, `check-names-fast.txt`, `docs/architecture.md`
(`lib/requests.sh`'s row; the guards table's *Request inbox* row: the v2 verbs' rules; the memory invariant's sentence;
`harness memory decline <run>`), `README.md` (*Steering*: the card's two actions; `harness memory decline <run> --why`),
the V2 decision file (finding · choice · rejected: `--match-head-commit` on the card's merge; facts-only merge; a
`--delete-branch`; a why on merge; a second PR state for a close with a reason; a decline that fails stopping the close).

### V2-03 · The n8n-home checklist: `docs/plans/2026-11-10-review-surface-n8n-home.md`

**Choice.** One file for a session in `~/projects/n8n-home` under its live-staged protocol (`CLAUDE.md` `## Live
system`: snapshots, `scripts/deploy.sh --dry-run` then the deploy under `flock -n /srv/n8n/live.lock`, nothing in
03:15–04:30, workflows imported inactive until their rig test passes, never a live MCP write, never `/srv/n8n/.env` or
`data/config`), written in this repo (its reader is that session; nothing is changed in n8n-home by this run), holding:

1. **What its intake reads.** `lib/intake.js` `eventProblems` takes `v` 1 as today **and** `v` 2 with exactly the 13 keys
   plus `memory`, only for `kind` `memory` (a v2 of another kind, or a v1 with a `memory` key, is a 422); `ROUTED_KINDS`
   gains `memory`; `memory` is an object with the keys of `tests/fixtures/n8n-event-v2-memory.json` (`pr`, `rules_pr`,
   `policy`, `reviewed`, `held`, `failed`, `failures[]` of `{id, section, q, reason}`, `state`, `review`), the two URLs
   strings or null, `context` null allowed for this kind (it is for every card kind already). The fixture to copy into
   `fixtures/events/memory.json` is this repo's, placeholders and all, until a captured one replaces it (their step 16).
   `Route by kind` sends `memory` to a new sub-workflow, **42 memory card** (*default*: its own workflow, since 40's
   card is a question with options chosen by Claude and this one is a verdict with two fixed actions and **no LLM
   call**: every word on the card is the event's, so the card is code and costs nothing).
2. **The card's layout** (served by 41 `card (GET)` as the question cards are, or its own GET; the session's call):
   the title line; the body's `memory:` line; under it one row per `failures[]` entry, `<id> · <section> · q<n> · <reason>`,
   red, above the buttons (the reasons in front of him before the click: §12); the `## Review` table read from
   `HARNESS_LEDGER_DIR/<project>/<run>/memory.md` **when the card is served**, not when it is built (the event goes out
   from the curator step; `ledger()` copies the record minutes later), folded, with "not in the ledger yet" when the
   file is absent; `project · run · policy · <held> held · <failed> failed`; links to both PRs (`click`, `actions`);
   then the actions: for the facts PR **Merge** and **Close** (Close with a one-line note field, "why: the next
   curator reads it"; empty means an override is counted), the same pair for the rules PR when `rules_pr` is set, each
   labelled with its PR; a PR whose `state` is `merged` shows "merged by the driver" and no buttons; `review` not `ok`
   shows "no review: merge on GitHub" and Close alone. Private topic rule D9 as for every card: the ntfy says `Tap to
   open the card` unless `NTFY_PRIVATE`.
3. **The two actions' request JSON**, written as 41 writes answers today (`buildRequest`'s v2 branch, D25's ids
   `1-<hash>` from the event id, the verb, the PR and the note, so a double tap writes the same name):
   ```json
   { "v": 2, "id": "1-<40 hex>", "at": "<ISO 8601>", "verb": "merge", "run": "<run>", "pr": "<url>", "source": "n8n-card", "event": "<event id>" }
   { "v": 2, "id": "1-<40 hex>", "at": "<ISO 8601>", "verb": "close", "run": "<run>", "pr": "<url>", "why": "<the note, or absent when empty>", "source": "n8n-card", "event": "<event id>" }
   ```
   The result page polls `done/<id>.json` as today and reads `state`, `refused` and `output` (the result v2 fixture:
   `tests/fixtures/requests/result-v2.json`); a refusal is shown as its text. 90's error handler needs no change: a
   failed 42 re-sends the stored event's own title, body and click, which is the ntfy line (D28).
4. **The order on that side**: the rig tests first (their suite against `fixtures/events/memory.json` and the request
   fixtures), the deploy under the protocol, then **Michael's one step**: `echo 'EVENT_V2=1' >>
   ~/.config/harness/config.sh`, with its *Done when* (the next run with a memory PR: `run.log` says `event → n8n:
   memory <id>`, the card arrives, `ls /srv/n8n/files/events/` lists the id) and its undo (delete the line: the
   harness sends the ntfy line again at once). The step is in this file, not in `docs/plans/2026-10-22-n8n-events-live.md`
   (that one is v1's; its steps are Michael's and not touched here).
5. **What it must not do**: parse the body for anything the `memory` field carries; call `harness`; write anything but
   `HARNESS_REQUESTS_DIR/<id>.json`; offer a merge the field says is refused.

**Checks (written first).** `tests/checks/memory-requests.sh` (fast): the checklist file exists, names the two fixtures
and the result fixture by path, and every fixture path it names exists (a doc check, so a renamed fixture turns it
red); `tests/fixtures/requests/README.md` and `tests/fixtures/README.md` (if one lists the event fixtures) name the v2
files. One check.

**Files.** `docs/plans/2026-11-10-review-surface-n8n-home.md`, `tests/checks/memory-requests.sh`,
`tests/fixtures/requests/README.md`, `tests/fixtures/check-names.txt`, `check-names-fast.txt`, `README.md` (*Steering*:
the pointer to the checklist), the V2 decision file (one line: the n8n-home half is a checklist here, built there).

### V2-04 · Review (Opus)

Sized to the milestone: an Opus reader of V2's diff. Hardest: that no path lets a request merge a PR the ledger does not
know, or one whose review did not run (`validateRequest`'s order read, then `one()`'s branch: the ledger rule in node
before any gh call, the review rule before the merge); that the text and the why reach gh as argv elements only (no
`eval`, no `bash -c`, as A3); that the card's merge leaves `merged_by` null so `harness memory` counts it as Michael's
(`grep -n MERGED_BY lib/*.sh`); that a run-level declined row cannot drop an op in `apply` (the null key) and does not
break `proposalsView` or `latestAnswers`; that the stub gh's `pr merge <url> --merge` and `pr close <url> --comment` are
gh's shapes and not invented; that the checklist's request JSON equals the request fixtures byte for byte but for the
placeholders. The review's file is `docs/plans/<run date>-V2-review.md`.

---

## Milestones

| M | Contents | After | `check_budget` |
|---|---|---|---|
| V1 | the v2 event shape (`KINDS`, `ROUTED_V2`, `buildEvent`'s `memory=`), `memreview.mjs card` and `title`, `memory-event.json`; the send at the end of `memory_pr`, `EVENT_V2`, no bundle for the kind, the ntfy line otherwise; `tests/fixtures/n8n-event-v2-memory.json`; `tests/checks/memory-event.sh` (slow); the `Updated in place` line in the v1 spec; `journal/decisions/<run date>-review-surface-event.md`; architecture and README; V1-03 review | `[]` | 15 |
| V2 | request and result v2 (`merge`, `close`, `pr`, `why`, `--memory`, `logLine`'s `pr=`); `harness requests`' branch (gh's state, the review rule, `gh pr merge --merge`, `gh pr close --comment`, the decline rows); the run-level `harness memory decline <run> --why`; the gh stub's two shapes; the request fixtures; `tests/checks/memory-requests.sh` (fast); the n8n-home checklist; `journal/decisions/<run date>-review-surface-verbs.md`; architecture and README; V2-04 review | `["V1"]` | 25 |

Plan V1 as three features and V2 as four, the review last in each. The suite ends green at every milestone; the fast
tier stands under a coding session's `passes`, the full suite at verify (`decisions/2026-11-03-fast-gate`). A milestone
over its `check_budget` says why in its last coding entry's `checks` field. `memory-event.sh` is slow by the 30 s rule
(stub runs with a curator and a reviewer, as `memory-review.sh` at 119 s); `memory-requests.sh` is fast (fixtures and
the stub gh, no driver), each timed once alone when made (`TEST_JOBS=4 bash tests/run.sh <file>`) and placed by the
reading, with the slow file's row added under the tiers decision's table. The file names hold no other check file's
name (the suite runner's name lint).

## Predictions (for the retro and the supervisor; against the runs after this one)

Every row names the measurement point of `journal/learning/2026-11-07-memory-curator.md` §10 it moves.

| Measure | now | after V1 + V2 (and the n8n-home half) | §10 point |
|---|---|---|---|
| notifications per run with a memory PR that carry the memory outcome | 0 (the end notification goes before the curator) | **1**: the `memory` event, or the ntfy line while `EVENT_URL` or `EVENT_V2` is unset; 0 for a run with no PR | row 1, *merged unchanged / edited / closed / open*: the time from the PR's opening to Michael's verdict is now a time from a notification, not from his next look at GitHub |
| the places the verdict's text is rendered from one function | 3 (the note, `## Review`, the `Memory` row: `heldFailed`) | **4**: the card's body is `line`'s bytes (the check diffs the event's `body` against the `harness-log.md` note) | row 1 and §10's habit line: the number on the phone is the ledger's, so a claim read from the card is not *(inferred)* |
| memory PRs decided (merged or closed) from the card, of those decided, over the first ten after the n8n-home half | 0 of 0 | **at least 7 of 10** (the rest on GitHub: a diff he wanted to read) | row 1: the PR state the rule reads is reached by the surface built for it |
| time from the `memory:` note to the PR's merge or close, median over those ten | unmeasured (hours to days: GitHub mail or `harness report`) | **under 24 h**, read from `memory.jsonl`'s `at` and gh's `mergedAt` or the close time | row 1: the latency behind *open* |
| failures read before the click: card merges that land as `merged against a fail` | n/a | **at most 1 of the first 10 card merges** (the reasons are above the button) | row 1's override column (R2-02 §2): the card is where the override is chosen with the reason in front of him, so its rate is the reviewer's questions' measure, not the surface's |
| closes with a reason, of card closes | n/a | **at least half**: a close with a why is a decline the next curator reads, a close without one is an override | row 2 (*which rule rejects, with reasons*) and `answers:`' declined count (row 4, acceptance per tier): the `--why` rows grow from the card, not only from the hand command |
| rules PRs merged from the card, of rules PRs decided | 0 | **measured, not predicted**; a rules PR merged against a fail from the card more than once in 8 is the falsifier below | row 4, *acceptance per tier and section*: the rules PR's merge rate is read from a surface that shows its verdict |
| `event hook failed … memory` notes per run with the switch set | n/a | **0** on a live intake (a 422 after the n8n-home deploy is a shape drift between the fixture and `eventProblems`) | the spec's Predictions table (§10 row 6): the contract held on both sides |

**Falsifiers.** Michael decides fewer than half of the first ten memory PRs from the card (the card lacks what he reads:
the diff; add the facts commit's diff from `memory.md`'s *Applied* to the card before anything else). A card merge
lands against a fail more than once in ten (the failure rows are not read: move them into the button's label, or make a
merge against a fail a two-tap confirm). The intake refuses the v2 event after the n8n-home deploy (the fixture drifted
from the driver's output: the fixture check in `memory-event.sh` is where it should have been red; capture the live
event into both repos' fixtures). `event hook failed … memory` notes appear with `EVENT_V2=1` while the n8n-home half is
not deployed (the switch was flipped early: the checklist's order is wrong or unread). A double tap merges or closes
twice, or two results exist for one request (the hash id or the duplicate rule broke). A close with a reason is counted
as `closed against a hold` (the run-level row was not written, or `declinedRuns` does not see it). A rules PR is merged
against a fail from the card more than once in 8 (take the rules PR's merge off the card and leave it on GitHub). The
`memory` ntfy line is trimmed on the median run (too many failures per run to fit 3500 bytes: the curator writes too
many ops, which is a curator finding, not the card's).

## Not in this spec

The recurrence measure (F3e) and acceptance per section read from the ledger. The prune of the three over-cap files
(F3c). Any change to the reviewer's four questions, to `memreview.mjs line`'s text, to the graduation rule or its
numbers, or to `memoryOverride`. Turning `MEMORY_POLICY=auto` on anywhere. The v1 live checklist's own steps
(`docs/plans/2026-10-22-n8n-events-live.md`: Michael's). Any code in n8n-home (the checklist is written here; a session
there builds to it under its protocol). A card for the record PR or the milestone PRs (the memory PR is the one whose
judge is Michael without the project's context; the others have the verify). `"v": 2` on any v1 kind, a new verb for
`answer` or `continue`, a probe of the intake, a bundle for the `memory` event. A `--match-head-commit` on the card's
merge. Deleting the memory branch on a close. An LLM call in the memory card.

## After the run (Michael)

- **Before the build, by hand** (the order in *Depends on*): the v1 checklist's two stages,
  `docs/plans/2026-10-22-n8n-events-live.md`: Stage 1 (`EVENT_URL` in `~/.config/harness/config.sh`, `harness context`
  once, the next park as the test) and Stage 2 (the request inbox's path unit: `systemctl --user link …`, `enable
  --now`, one hand-written answer). Neither is needed for the build to merge; both are needed before the first
  `memory` event means anything.
- **On the day V1 merges, nothing to configure**: every run with a memory PR sends one ntfy with the title, the
  `memory:` line and both PRs as actions; a tap opens the facts PR. `EVENT_V2` stays unset.
- **After the n8n-home half is deployed** (its checklist, `docs/plans/2026-11-10-review-surface-n8n-home.md`, last
  step): `EVENT_V2=1` in `~/.config/harness/config.sh`. The next run with a memory PR puts the card on your phone:
  the verdict, each failure with its reason, Merge and Close for each PR. Close with a note when you mean *never
  propose this again*: the note becomes a declined row the next curator reads, and the close is not counted as an
  override; close without one when you mean *the reviewer was wrong*, and `harness memory` counts it.
- **`harness memory decline <run> --why "<text>"`** (no `/<n>`) is the hand form of the same thing for a facts PR you
  close on GitHub.
- **What it costs**: one notification per run with a memory PR, after the end notification, carrying the text the
  `harness-log.md` note and the report's `Memory` row already have; one tap to decide, two with a note.
- **The dispatch list** (`docs/plans/2026-11-03-test-suite-redesign-dispatch.md`): row F3d's status to this spec, its
  run's PRs and this table's results; the n8n-home half's row when that session is queued.
