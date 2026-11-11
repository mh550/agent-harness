# The review surface, n8n-home's half: the checklist a session there builds from

Spec `docs/specs/2026-11-10-review-surface.md` (§V2-03); written by run `agent-harness-2026-11-10` (V2-03), built in
n8n-home. Its reader is a session in n8n-home, working under that project's live-staged protocol (its `CLAUDE.md`,
`## Live system`). Nothing in n8n-home was changed by this run: the harness side is built, and inert until the last
step here (`EVENT_V2`). The harness sends the memory event as v2 only when both `EVENT_URL` and `EVENT_V2=1` are set
(decisions/2026-11-10-review-surface-event); until then a memory outcome is the ntfy line it always was.

The fixtures this file names are this repo's, made from stub output (never typed); copy them, don't retype them:

| Fixture | What it is |
|---|---|
| `tests/fixtures/n8n-event-v2-memory.json` | the memory event as the driver POSTs it, with the placeholders `<uuid>`, `<ISO 8601>`, `<facts PR url>`, `<rules PR url>` |
| `tests/fixtures/n8n-event-v1.json` | the v1 event, unchanged: every other kind stays v1 |
| `tests/fixtures/requests/merge.json` | the card's **Merge** request (v2), run `r1`'s facts PR |
| `tests/fixtures/requests/close.json` | the card's **Close** request with an empty note (no `why`), the rules PR |
| `tests/fixtures/requests/close-why.json` | **Close** with a note (`why` after `pr`), the facts PR |
| `tests/fixtures/requests/result-v2.json` | the harness's result for a v2 request, as `done/<id>.json` holds it |
| `tests/fixtures/curl-event-422.out` | what the harness reads when the intake refuses the event (it then sends its ntfy line) |

`tests/fixtures/requests/README.md` says how each was made.

## 1. What the intake reads (`lib/intake.js`)

- `eventProblems` takes `v` 1 exactly as today **and** `v` 2 with exactly the 13 v1 keys (`EVENT_KEYS`) plus `memory`,
  for `kind` `memory` only. A v2 of any other kind, a v1 with a `memory` key, or a v2 `memory` without the key: 422 with
  the problem, as every refusal today.
- `ROUTED_KINDS` gains `memory`.
- `memory` is an object with exactly the keys of `tests/fixtures/n8n-event-v2-memory.json`'s `memory`, in that order:
  `pr` (string or null), `rules_pr` (string or null), `policy` (string), `reviewed`, `held`, `failed` (integers ≥ 0),
  `failures` (an array of `{id, section, q, reason}`: `id` a string like `facts/2` or `rules/1`, `section` a string or
  null, `q` an integer 1–4 or null (an op too thin to review), `reason` a string; `[]` whenever `review` is not `ok`),
  `state` (`merged` when the driver merged the facts PR under `MEMORY_POLICY=auto`, else `open`), `review` (`ok`, or
  the reason the reviewer did not run). The shape is `lib/memreview.mjs`'s `card`.
- `context` is null for this kind (the harness sends no bundle for it; null is allowed for every card kind already).
- Copy `tests/fixtures/n8n-event-v2-memory.json` into `fixtures/events/memory.json`, placeholders and all, until a
  captured event replaces it.
- `Route by kind` sends `memory` to a new sub-workflow, **42 memory card** (`workflows/42-memory-card.json`), run
  without waiting as 40 is. Its own workflow (*default*): 40's card is a question with options Claude writes; this one
  is a verdict with two fixed actions and **no LLM call**. Every word on the card is the event's, so the card is code.
- 90's error handler needs no change: a failed 42 re-sends the stored event's own title, body and click (D28), which is
  the ntfy line the harness would have sent.

## 2. The card (42 stores it; 41 `card (GET)` serves it, or 42's own GET: the session's call)

Top to bottom:

1. The event's `title` (`[<run>] memory: <held> held · <failed> failed`, or `… review none`).
2. The body's `memory:` line (the event's `body` up to ` · PR `).
3. One row per `memory.failures[]` entry, red, above every button: `<id> · <section> · q<q> · <reason>`. The reasons
   are in front of Michael before the click (spec §12). `failures` `[]` shows no rows.
4. The `## Review` table: read `HARNESS_LEDGER_DIR/<project>/<run>/memory.md` **when the card is served**, not when it
   is built (the event leaves at the curator step; the harness copies the record to the ledger minutes later), folded;
   the file absent: "not in the ledger yet".
5. `<project> · <run> · <policy> · <held> held · <failed> failed`.
6. Links to both PRs: the event's `click` (the facts PR) and `actions` (`view, Facts PR, <url>; view, Rules PR, <url>`).
7. The actions, each labelled with its PR: for `memory.pr`, **Merge** and **Close**; the same pair for `memory.rules_pr`
   when it is set. **no actions until** `HARNESS_LEDGER_DIR/<project>/<run>/memory.md` exists (item 4's file): until
   then "the actions come when the run's record is in the ledger". The harness checks a `pr` against the ledger row it
   writes with that copy, so a tap before it is refused, and that id's result stands for good. Close has a one-line note field, "why: the next curator reads it" (empty means the close counts as
   an override of the reviewer).
   - `state` `merged`: the facts PR shows "merged by the driver" and no buttons (the driver merges the facts PR alone,
     under `auto`); the rules PR keeps its pair.
   - `review` not `ok`: "no review: merge on GitHub" and Close alone (the harness refuses that merge anyway).

The ntfy follows D9 as every card: `Tap to open the card` on the public topic, the `memory:` line only with
`NTFY_PRIVATE`.

## 3. The two actions' request JSON (`buildRequest`'s v2 branch)

Written as 41 writes answers: one write of `JSON.stringify(request) + "\n"` to `HARNESS_REQUESTS_DIR/<id>.json`, the id
D25's `1-<h>`, `h` the first 40 hex of a SHA-256 of the event id, the verb, the PR, the note and the attempt (1 at
first), so a double tap writes the same name and the harness ignores an id it has handled. A handled id is never run
again, so the result page offers **Try again** (the attempt plus one, a new id) when the result is `ok` false with
`refused` null (gh ran and failed: GitHub may be back) or refused `pr <url> is not a memory PR the ledger knows …`. The key order is the fixtures'
(`v,id,at,verb,run,pr[,why],source,event`); each line below is `tests/fixtures/requests/merge.json` and
`tests/fixtures/requests/close-why.json` with the values made placeholders:

```json
{"v":2,"id":"1-<40 hex>","at":"<ISO 8601>","verb":"merge","run":"<run>","pr":"<the PR's url>","source":"n8n-card","event":"<event id>"}
```

```json
{"v":2,"id":"1-<40 hex>","at":"<ISO 8601>","verb":"close","run":"<run>","pr":"<the PR's url>","why":"<the note>","source":"n8n-card","event":"<event id>"}
```

- `pr` is the URL exactly as the event's `memory.pr` or `memory.rules_pr` has it (the harness matches it against its
  ledger's row for that run).
- A close with an empty note has no `why` key (`tests/fixtures/requests/close.json`); a merge never has one (refused
  `a merge takes no why`).
- `why`: one line, at most 300 characters, no control character (the harness refuses `why must be one line of at most
  300 characters`); the card's note field holds one line and counts to 300.
- The v1 branch (`answer`, `continue`) is unchanged: `v` 2 carries `merge` or `close` and nothing else.

The result page polls `HARNESS_REQUESTS_DIR/done/<id>.json` as today (1 s steps, up to 14 s) and reads `state`
(`merged`, `closed`, or null when nothing was done), `refused` (the reason, shown as its text) and `output` (gh's own
line when gh refused, folded), per `tests/fixtures/requests/result-v2.json`: the ten v1 keys, then `pr` and `state`.
The refusals it can show, word for word from the harness: `pr <url> is already merged`, `pr <url> is already closed`,
`the review did not run for <url> (<why>): merge it on GitHub if you mean to`, `pr <url> is not a memory PR the ledger
knows (ledger/memory.jsonl)`, `pr <url> belongs to run <run>, not <run>`.

## 4. The order on that side

1. **Rig tests first**, in a worktree: the intake's suite against `fixtures/events/memory.json` (a v2 memory event
   taken, a v2 park and a v1 event with `memory` refused, every v1 fixture still taken), 42's card built from it (the
   rows, the states, no LLM node), `buildRequest`'s v2 branch giving the bytes of the three request fixtures (copied
   into the rig) from their values, the result page reading `result-v2.json`.
2. **The deploy under the live-staged protocol**, as its `## Live system` says: the backup status and window (none
   from 03:15 to 04:30), the snapshots, then `flock -n /srv/n8n/live.lock scripts/deploy.sh --dry-run` and
   `flock -n /srv/n8n/live.lock scripts/deploy.sh` on a pushed commit, 42 imported inactive until its rig test
   passes, then **Check**. No live MCP write, no editor click; never `.env` or `data/config`.
3. **Michael's one step**, after that deploy:
   ```
   echo 'EVENT_V2=1' >> ~/.config/harness/config.sh
   ```
   **Done when** the next run with a memory PR shows `event → n8n: memory <id>` in its `run.log`, the card arrives,
   and n8n's stored events (`files/events/`) list that id. A refusal instead shows `event hook failed (…): memory; sent
   to ntfy` in `harness-log.md`, and the ntfy line arrives as before.
   **Undo:** delete the line. The harness sends the ntfy line again at once; nothing else changes.

This step lives here, not in `docs/plans/2026-10-22-n8n-events-live.md` (v1's; its steps are Michael's and stand).

## 5. What it must not do

- Parse the `body` (or the title) for anything the `memory` field carries: the card reads `memory`.
- Call `harness`, or run any command on the box: the request file is the one way in.
- Write anything but `HARNESS_REQUESTS_DIR/<id>.json` on the harness's side (the ledger is read, never written).
- Offer a merge the field says is refused: no Merge when `state` is `merged` or `review` is not `ok`.
- Call an LLM for the memory card: every word on it is the event's or the ledger's.
