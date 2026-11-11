# The card's verbs: request v2 `merge` and `close` on a memory PR the ledger knows, a close with a reason as a decline

*(2026-11-10, run `agent-harness-2026-11-10` on the spec `docs/specs/2026-11-10-review-surface.md`, milestone V2; Michael's
brief of 2026-11-10 19:21: proceed on every default the spec marks *default*, record each here; the piece is Decision 21
(a) and 26 (a) of `docs/plans/2026-11-03-test-suite-redesign-dispatch.md`, row F3d.)*

- **Finding:** the request inbox (A3, decisions/2026-10-22-request-inbox) is the one path from the phone to the box and
  n8n's one write, and its two verbs (`answer`, `continue`) steer a run; neither touches a PR. A memory PR is a row of
  `ledger/memory.jsonl` and gh's state, not a run's state. A close with a reason has nowhere to land for the facts PR:
  `harness memory decline` writes a row only for a numbered item (`<run>/<n>`), and tier 1 is not numbered.
- **Choice (V2-01, the request and result):**
  - **One shape per version** (*default*): request `v` 2 carries `merge` or `close` and nothing else, `v` 1 `answer` or
    `continue` as before; a v2 `answer` is refused `v 2 carries merge or close`, a v1 `merge` `verb is not answer or
    continue`, any other `v` `v is not 1 or 2`. The validator has two branches and n8n-home's `buildRequest` two. v2
    passes v1's rules it shares first (JSON and the 10 s grace, no NUL, the id, the duplicate, the run's pattern and a
    real run).
  - **The ledger rule in node:** `pr` must be the `url` of a `ledger/memory.jsonl` row whose `run` is the request's
    (`validate --memory <file>`, read by `requests.mjs`), else `pr <url> is not a memory PR the ledger knows
    (ledger/memory.jsonl)` or `pr <url> belongs to run <row's run>, not <request's run>` (`belongs to another run` when
    the row's run fails the run rule: a hand-edited ledger value is never echoed).
  - **A `pr` passes a URL's shape before it is quoted** (*default*, not in the spec): `^https://<host>/<path>$` of URL
    characters, at most 200, else `pr is not a PR URL (https://<host>/<path>, at most 200 characters)` naming no value,
    since A3's rule is that a reason never quotes a value that failed its rule and the two ledger refusals quote `pr`.
  - **A why on a merge is refused** (*default*): `a merge takes no why`; a merge against a fail has its reason in the
    override count, not in a row, and the card's merge button has no note field. A close's `why` is the hand decline's
    rule (`WHY_MAX`: one non-blank line, at most 300 characters, and no control or line-separator character, *default*:
    `curator.mjs badWhy`, shared by both, since the why reaches the curator's prompt, a terminal and gh's `--comment`), refused `why must be one line of at most 300
    characters`, never quoted; an empty `why` is none, as an empty brief is.
  - **Result v2:** the ten v1 keys in order, then `pr` and `state` (`merged`, `closed` or null), `runner_started`
    always false; `requests.mjs result --pr <url|-> [--state …]` writes it. `requests.log`'s line gains `pr=<url>`
    after `run=` and never carries the why. `validate` prints `pr`, the row's `review` and `why 1|0` as labelled lines
    for a v2 request and writes the why to `<out>/why` as it writes the text, so bash parses no JSON (V2-02 reads them).
  - **The run-level decline** (*default*, the row's shape): `harness memory decline <run> --why "<text>"`
    (`memory.mjs answer … -`, `answerRow` with no `n`) writes `{run, project, n: null, tier: 1, verdict: "declined", why,
    file: null, section: null, text: null, key: null, at}`, upserted on `(run, n null)`, one ledger commit `ledger:
    memory decline <run>`. A decline only (`accept` names an item). `latestAnswers` keeps it as its run's one item of n
    null, so `declinedRuns` reads a closed PR of that run as no override with no change to `memoryOverride`;
    `answersText` renders it `- the facts PR of <run>, closed: <why>` under *Michael declined*; `apply` leaves it out of
    its matches (a null key names no line, so it drops no op); `proposalsView` ends with `<run> · the facts PR ·
    declined: <why>` and `answersTally` and `· <k> answered` count it once. Without `--why` it is the usage line, exit 1.
- **Rejected:**
  - one validator branch for both versions, a v2 `answer` taken (two shapes for one verb: n8n-home would have to choose);
  - a why on a merge kept in a row (the merge's reason is the override the count already reads);
  - a run-level row with a key (`run:<run>`): a key is what `apply` matches, so a made-up one could match a line;
  - numbering the facts PR's ops so a close declines each (`tier 1 is not numbered`: a fact is never Michael's to
    decline, and the curator would read each fact as refused for good).
- **Checks (V2-01, `+14 ~2 −0`):** `requests.mjs: v 2 is rejected` → `requests.mjs: v 2 with answer is rejected, v 3 is
  not 1 or 2`; `summary.mjs memoryView: held and failed columns, … and the review: tally line` → `…, the review: tally
  line, and a run-level declined row is no override either`. `tests/checks/request-files.sh`'s v2 answer now expects
  `v 2 carries merge or close` (its name unchanged: v 2 is still rejected there).
