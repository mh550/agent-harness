# The memory event: v2 of the n8n contract on the `memory` kind alone, its object from the record, its title

*(2026-11-10, run `agent-harness-2026-11-10` on the spec `docs/specs/2026-11-10-review-surface.md`, milestone V1; Michael's
brief of 2026-11-10 19:21: proceed on every default the spec marks *default*, record each here; the piece is Decision 21
(a) and 26 (a) of `docs/plans/2026-11-03-test-suite-redesign-dispatch.md`, row F3d.)*

- **Finding:** the memory PR's verdict reaches Michael through GitHub and `harness report` alone: the run's one end
  notification goes out in `finish` before the curator and the reviewer run. Its text already exists as one function
  (`memreview.mjs line`), and R2-02 §5 of the reviewer's spec named the event that would carry it (kind `memory`, a
  `memory` object field), but the n8n events contract (`docs/specs/2026-10-22-n8n-events.md`) is v1, whose rule is
  *change nothing without a new `v`*, and n8n-home's intake takes exactly v1's 13 keys with `"v": 1`.
- **Choice (V1-01, the shape):**
  - **`"v": 2` on the `memory` kind alone** (*default*). `lib/notify.mjs` `KINDS` gains `memory`; `buildEvent` gives it
    v1's 13 keys in v1's order with `v` 2, then a 14th key `memory`. Every v1 kind keeps `v` 1, its 13 keys and its
    bytes (the unit test pins their sha256 from before the change). `ROUTED` is unchanged; `ROUTED_V2 = [...ROUTED,
    "memory"]` names what routes once the switch is set (V1-02).
  - **`memory=` is a path** (*default*): a JSON file the driver wrote, as `bundle=` and `context=` are paths, so no JSON
    crosses bash. On any other kind it is refused (exit 2, `memory= is the memory kind's`, nothing on stdout), so no v1
    event can grow a key by a call-site slip; a `memory` event without a readable `memory=` is refused too. An empty
    `memory=` is none (notify_event passes every field to the CLI).
  - **`click` is the facts PR, else the rules PR** when only that one exists (*default*); `actions` is `notify.mjs
    actions`' header over both PRs (`Facts PR`, `Rules PR`; an empty URL skipped).
  - **`review none` in the title** (*default*): `memreview.mjs title` prints `[<run>] memory: <held> held · <failed>
    failed`, or `[<run>] memory: review none` when `review` is not `ok`; `0 held · 0 failed` would read as a verdict
    where there was none.
  - **The `review` key in the object** (*default*): `memreview.mjs card` builds R2-02 §5's `{pr, rules_pr, policy,
    reviewed, held, failed, failures, state}` plus `review` (`ok`, or the why none, as `line` says it: `no verdicts`
    when memory.json says ok and no verdicts file came), so the card knows whether a merge is offered without parsing
    the body. `failures` is one `{id, section, q, reason}` per failed op of either tier (the input item's section; `q`
    null for thin or not reviewed; the reason without its ` (q<n>)`, as `line` strips it), `[]` on a review none;
    `state` is `merged` when `merged_by` is `driver`, else `open`.
  - **The fixture is made, never typed**: `tests/fixtures/n8n-event-v2-memory.json` is `notify.mjs event`'s stdout over
    `memreview.mjs card`'s object from a stub run's record files (`tests/fixtures/memory/event-*.json`), with the id,
    `at` and both PR URLs put back as placeholders; the command is a comment in `tests/unit/notify.test.mjs`, and the
    unit test compares the bytes. `tests/fixtures/n8n-event-v1.json` is unchanged.
- **Rejected:**
  - `"v": 2` on every event once the switch is set: it changes ten kinds for no gain and makes n8n-home's intake take
    v2 for events whose shape did not move.
  - The `memory` object as inline JSON on the command line: JSON across bash, where every other structured input is a
    path.
  - `0 held · 0 failed` as a review none's title.
  - The card reading whether a merge is offered from the body's text.
