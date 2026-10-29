# R4 · Questions wait in `harness needs` until answered: plan

Spec: `docs/specs/2026-10-28-reliability.md` §R4 items 1–5 and its checks. This file is R4-01. R4-02 builds the
`question` reason in `lib/needs.mjs` (key, refresh, move forward, card, sweep), R4-03 the opens at ingest in
`journal_` and the stub flags, R4-04 the readers (`harness needs`, `harness status`, the debrief) and the skill's
answer step, and R4-05 reviews it and writes the decision and the docs. Every site is named by function and file as
the code stands at `4d15739`. Nothing here changes code, so the suite is as the init left it (976 checks, green).

**Dependency line.** `git log --oneline origin/main | grep -c 'harness-merge/agent-harness-2026-10-29-2-R2'` prints
**1** (`53bdc66 Merge pull request #56 … -R2`): R2 is merged, so its `journal_` (the trim notes, `ENTRY_RESUMED`) and
`entries.mjs` (`fillQuestions`, the summary cut) are in this lane's base. R1 is merged too (`4d15739`, PR #59).

Facts checked for this plan, so the builders needn't re-derive them:

- **`journal_` holds the record lock.** It runs as `record journal_ …` (`lib/record.sh`), and `record` is re-entrant
  (`REC_HELD`), so a `needs_open` called inside it takes no second lock. The ingest has appended the entry by the time
  it returns 0, and under the lock the appended entry is the last line of `entries.jsonl`.
- **The question text in `entries.jsonl` is the filled one.** `entries.mjs fillQuestions` appends
  ` Files (harness, from the session): <absolute paths>` to a question that has no `Files:` line. Those paths hold the
  worktree, which is different in every run. A key over the raw text would differ between runs for a short question
  (the stub's `Should A default to off?` is 24 characters, so the fill falls inside the first 80), and the move
  forward would never match. So the key is built from the question with the fill removed (§2).
- **`inbox.mjs files(text)` already parses both labels**, `Files:` and `Files (harness, from the session):`, into
  `{path, line}`. The question card's `where` uses it as the parked card does.
- **Two checks list every reason.** `tests/checks/58-needs-record.sh`'s `needs REASONS: kind, severity and priority
  for each of the 15 reasons, as the plan's table` compares `Object.entries(N.REASONS)` with a literal string. In
  `tests/checks/59-needs-cards.sh`, `needs card <r>` runs once per fixture in `tests/fixtures/needs/`, and `needs
  cards: 15 fixtures, one per reason, …` compares the fixture names with its `REASONS` line. Its `FILLED` test also
  says `.question != null` only for `parked`. Adding `question` turns both red, so R4-02 updates them (§2.6).
- **Only A and C get a second coding session in a default stub run.** C's first leaves `BROKEN` (unless
  `STUB_NO_RED`), and M1's first verify un-passes A (unless `STUB_LENIENT`). `STUB_RESOLVE=<id>` lists `Should <id>
  default to off?` in `resolved` on sessions `n != 1`. So in `STUB_ASK=A STUB_ASK_AGAIN=B`, B has no later session
  to resolve from, and `STUB_RESOLVE=B` would name B's question anyway. **`STUB_RESOLVE=A` does what R4-03 step 3
  means without new stub semantics.** A1 asks, B1 asks again (`seen` 2), the verify un-passes A, and A2 (a later
  entry than B1's) lists `Should A default to off?` in `resolved`. See *Proposed changes*.
- **`needs_sweep` runs** before each lane's pick (`lib/lane.sh`), before the coordinator's opens and at `finish`
  (`lib/driver.sh`), so by a run's end every sweep rule has been applied.
- **No notification path is involved.** `needs_open` only records. A notification goes out only where a caller runs
  `needs_notify <ref>` (parks, verify and merge stops), and `journal_` won't call it. `priority ""` documents that.

## 1. The reason

`lib/needs.mjs` `REASONS` gains `question: R("needs_michael", "warn", "")`, appended last, after `overlap`. That makes
16 reasons. The header comment `// The 15 reasons` becomes 16. `question` is in neither `RUN_LEVEL`, `FEATURE_SUBJECT`
nor `MILESTONE_SUBJECT`.

## 2. The key, the open, the refresh and the move forward (R4-02)

### 2.1 The key

```js
/** Pure: a question's key subject: the text without the harness's fill (entries.mjs FILL) and without a trailing
 *  `Files:` line, whitespace folded, lower-cased, its first 80 characters (code points). */
export function questionKey(text)
```

The item's `key` is `question:${questionKey(text)}`. The fill marker ` Files (harness, from the session): ` is cut at
its last occurrence, as `entries.mjs unfilled` does. Export `unfilled` from `lib/entries.mjs` (pure, already there)
rather than copy the string. A session's own `Files:` line is cut only when it starts a line
(`/\n\s*[*_`]*Files\b[^\n]*$/`): a question that names its files in the sentence keeps them. Then `.replace(/\s+/g, "
").trim().toLowerCase()`, then `[...s].slice(0, 80).join("")`.

### 2.2 `open` for a question

The CLI is unchanged: `needs.mjs open <state> <run> <project> question "<text>" [key=value…]`. `open()` treats
`question` as follows:

- `facts.text = subject` (the whole text, filled or not), and `subject = questionKey(text)`. Every later step (the
  same-key lookup `${reason}:${subject}`, `record()`'s `key`) then works unchanged. An empty key (the text was blank)
  throws `no subject` as today (exit 1).
- Facts journal_ passes (§3): `asker=<entry's feature>` (for a verify entry its milestone, for init `init`), and
  `feature=<id>` only for a coding entry. Also `line=<entries.jsonl line>`, plus `needs_open`'s usual
  `record=`/`worktree=`/`origin=`/`record_branch=`. No `files=`: the card reads the paths from the text.

### 2.3 Same run: refresh

The lookup finds an open item with the same key in `<state>/needs/`. `refresh()` is called as for every reason (exit
3, `seen + 1`, a later `updated_at`, the card rebuilt from the new facts). The card's `question.line` therefore
becomes the newest asking entry's line, which the sweep (§2.5) compares with. `refresh` spreads `old`, so `asked_in`
stays.

### 2.4 A later run of the same project: the move forward

No open item with that key in this run. Then, **for `question` only**, `open()` looks in the sibling state dirs:
`dirname(state)/*/needs/*.json`, every dir but its own (a project's runs are `$HARNESS_STATE/<project>/<run>/`, the
layout `overlapsOf` already uses with `join(state, "..", r)`). It takes the open items (no `resolved_at`) with the same
key:

- none: a new item as for any reason, `seen: 1`, `asked_in: [run]`;
- one or more: the new item gets `seen = max(old.seen) + 1` and `asked_in` = the olds' `asked_in` (or `[old.run]`)
  in order, deduplicated, then `run`. Each old one goes through `resolveTo(oldState, {...old, resolved_at,
  resolved_by: "sweep", resolved_why: \`asked again in ${run}\`})`. That is a rename into the old run's
  `needs/done/`, the only write into another run's state dir, and needs.mjs alone makes it. The old run's `needs.md`
  is **not** rewritten: it lives in that run's record worktree (another checkout), and its own next open, sweep or
  `done` re-renders it.
- the exit is 0 (a new item in this run) and stdout is the new ref.

Pure part, for the check: `export function moveForward(olds, item, run, now)` → `{ item, resolved }` (the new item
with `seen`/`asked_in`, the olds with `resolved_*` filled). `open()` does the reads and the renames.

**Accepted race.** The old run's lock isn't held. If that run refreshes the same question at the same moment, its
write can recreate the file just renamed, and the question is then open in both runs. The next ask in either moves
it again. `resolveTo`'s ENOENT already covers a rename lost to a concurrent sweep.

`record()` sets `asked_in: [run]` on every new question item. Other reasons get no `asked_in` key, so their records
and `status --json` stay byte-identical.

### 2.5 The card (`TEMPLATES.question`) and the sweep rule

The card, from the facts. `F.text` is the text, `F.asker` the asking id and `F.line` the line:

| field | value |
|---|---|
| `headline` | `` `${F.asker} asked: ${cut60(firstLine(unfilled(text)))}` `` |
| `blocked` | `` `nothing waits on it; ${F.asker}'s session took the default its question names` ``. A template's own `blocked` (a new optional key) replaces `blockedOf(F)`: the subject is a key, not a feature. |
| `cost` | `the default stands until you answer` |
| `why` | `A session never parks on a judgment call: it takes the default and asks in its entry's questions, and journal_ (lib/record.sh) opens one item per question. A later entry's resolved, or harness needs done, closes it.` |
| `question` | `{ file: <record>/entries.jsonl, line: F.line, url: <record branch blob of .harness/runs/<run>/entries.jsonl>?plain=1#L<line>, text }`, the shape parked's has. `renderCard` then shows the `question` row (the text reflowed: `own_` keeps a `Files` line on its own) in place of `why`. |
| `where` | one `fileRow(F, path, line, "file")` per `inboxFiles(text)` path, then `{ path: <record>/entries.jsonl, line, label: "entry", url }` |
| `options` | (a) `record the answer (in the decision file it names), then harness needs done` (recommended: `the default stands until you do`), (b) `the default is right: harness needs done --why "default stands"` |
| `commands` | `` [`harness needs done ${F.run}/${F.seq} --why "<answer>"`] ``. `record()` passes `seq` through to `card()`'s facts already. |
| `files_from` | `"question"` |

Asked several times: `renderCard` gains a row `{ label: "asked", value: i.seen > 1 ? \`${i.seen} times${i.asked_in?.length > 1 ? \` (${i.asked_in.join(", ")})\` : ""}\` : null }` after `question`. It shows only on question items, since other reasons have no `asked_in` and their refreshed `seen` is not shown today. Limit it to `i.reason === "question"`. `markdown()` labels the question link with `basename(q.file)` instead of the literal `INBOX.md` (parked's stays `INBOX.md`). `title()`: `[<run>] question from <asker>`.

The sweep rule: `case "question": return st.answered?.[i.ref] ?? null;`. `readState(state, open)` fills `answered`
only when `open` holds a question item. It reads `<rec>/entries.jsonl` once and, per item, calls the shared matcher
below with the item's `card.question.line` and text. It gives `` `answered in ${e.feature}'s entry` `` for the first
later entry that lists the item in `resolved`. A record without `entries.jsonl` gives `{}`.

The shared matcher, so pack and sweep agree on what "answered" means
(`decisions/2026-10-26-resolved-and-project-facts`): move `pack`'s `res`/`same`/`settled` out of `pack()` in
`lib/entries.mjs` into

```js
/** Pure: the first entry after line `line` whose `resolved` names question `text` (exact after folding, the filled or
 *  the unfilled words, or a prefix of 40+ characters ending in …), or null. entries: readEntries' objects, each with .line. */
export function resolvedBy(entries, line, text)
```

`pack`'s `settled` becomes `q => !!resolvedBy(es, q.line, q.text)`. The context-pack checks (12's and 38's `resolved` ones) guard the
refactor and stay green unchanged.

`list()`'s sweep of a removed run already resolves questions as `run removed`: a gc'd run's questions go with it.

### 2.6 The two registries

- `58-needs-record.sh`: the REASONS-table check's literal gains ` question:needs_michael:warn:`. Its name says 16
  reasons (`needs REASONS: kind, severity and priority for each of the 16 reasons, as the plan's table`), and
  `check-names.txt` gets the rename. The file's own `REASONS` variable (the fixture runs, the sweep and `--json`
  order checks) stays at the 15: the question's store, sweep and order are 78's.
- `59-needs-cards.sh`: `question` is added to its `REASONS`, with `tests/fixtures/needs/question.json` (the facts
  `journal_` passes, real-shaped under `/home/u` like the others; the text is one of the memory run's questions with a
  `Files:` line). `FILLED`'s parked test becomes `(.question != null) == ("$r" | IN("parked", "question"))`. The
  count check's name becomes `needs cards: 16 fixtures, one per reason, …`.

## 3. Where the items open: `journal_` (R4-03)

In `lib/record.sh` `journal_`, after the ingest's notes and before the render. Only when `rc == 0`: a minimal entry
(rc 3) has no questions, and a failed append has no line.

```bash
  # each question the entry asks waits in harness needs until answered (docs/plans/2026-10-29-R4-questions.md §3)
  (( rc == 0 )) && questions_ "$1" "$2" "$3"
```

```bash
questions_() {   # who kind id: one question item per question of the entry just appended (the last line, under the lock)
  local l q n=0 res; l=$(grep -c '' "$REC/entries.jsonl")
  while IFS= read -r -d '' q; do
    needs_open question "$q" asker="$3" line="$l" $([[ $2 == coding ]] && echo "feature=$3") > /dev/null; n=$(( n + 1 ))
  done < <(tail -n 1 "$REC/entries.jsonl" | jq -j '.questions[]? | strings | select(test("\\S")) | . + "\u0000"')
  (( n )) && note "$3: $n question(s) for Michael recorded (harness needs)"
  res=$(tail -n 1 "$REC/entries.jsonl" | jq '.resolved // [] | length'); (( res )) && needs_sweep
  return 0
}
```

The NUL-separated read keeps a question's newlines. A refreshed or moved item counts in `n`: the note says the
entry's questions were recorded, not that they were new. An entry with `resolved` sweeps at once, so an answered
question leaves `harness needs` with the entry that answers it, before the next pick. `needs_open`'s own failure note
(`needs: could not record question …`) stays as it is. A record never stops a run.

## 4. The readers (R4-04)

- **`harness needs`** (`needs.mjs list` → `renderList`): the order is U2's (`order`: block before warn, oldest
  first), so question cards come after every block card. The header counts them apart: `NEEDS YOU <others> · <n>
  question(s)[ · <runs> runs]`. `section(title, count, hint)` takes `[q && n_(q, "question"), runs > 1 &&
  …].filter(Boolean).join(sep)` as its hint. With no question it reads as it does today (13's and 58's `NEEDS YOU 0`
  lines stay).
- **`harness status`** (`lib/status.mjs`): `doc.needs` keeps every item (`status --json`, with `reason` telling them
  apart). The view splits it. NEEDS YOU's rows are the non-question items, and its line is `NEEDS YOU <others> · <q>
  question(s) · harness needs` (`NEEDS YOU 1 · 3 questions · harness needs`, `NEEDS YOU 0 · 2 questions · harness
  needs`; none: `NEEDS YOU 3 · harness needs` as 53 pins). In `runObject`, `needs` becomes the non-question count
  (the run card's `needs you` row, the `waiting`/`ending` look), and it gains `questions: <n>`. A question never
  makes a run look stopped. The run card's `needs you` row lists the non-question items. When there are questions it
  gets one more line, `<n> question(s): harness needs <run>`.
- **The debrief** (`lib/debrief.sh`, the gatherer): the `#### Questions for Michael in progress.md (newest first)`
  block and its `grep -i 'question'` are replaced by

  ```bash
  echo; echo "#### Questions for Michael"
  "$H" needs "$RUN_ID" --json 2> /dev/null | jq -r '[.[] | select(.reason == "question")] | if length == 0 then "none open"
    else .[] | "- \(.card.question.text | gsub("\\s+"; " ") | .[0:600]) (\(.ref)\(if .seen > 1 then ", asked \(.seen) times" else "" end))" end' | fence
  ```

  The `#### needs` block above it (`harness needs <run>` as text) shows their cards too.
- **No notification.** Nothing in §3 calls `needs_notify`. The check reads `$T/curl.log` (`curl_count`).
- **`skills/harness-answer/SKILL.md`**: a section `## Question items` after *Proposing*. A `question` card is a
  default a session already took. Propose an answer like any other. On Michael's yes, if the question's `Files:`
  names a decision file (`journal/decisions/…`), add one line to it: `Updated in place <date>: Michael <answer>`.
  Then run `harness needs done <ref> --why "<answer>"`. The default stands: `--why "default stands"`. Michael
  installs it with the one command the entry gives (`cp -r skills/harness-answer ~/.claude/skills/`).

## 5. Checks: `tests/checks/78-needs-questions.sh`

78 is also `78-continue-busy.sh`'s number: the runner takes any `tests/checks/*.sh`, and 75 and 76 already share a
number. Every name is one line in `tests/fixtures/check-names.txt` (`LC_ALL=C` sorted). The names are written first
and watched failing:

R4-02 (pure and CLI on fixture state dirs; `needs_fixture question open|resolved [<at>] [<run>]`, below):

- `needs questions: questionKey folds whitespace, lower-cases, drops the harness's fill and a Files: line, cuts at 80`
- `needs questions: open makes one warn item, key question:<the key>, no priority, seen 1, asked_in its run`
- `needs questions: the same text again in the run exits 3, one item, seen 2, a later updated_at`
- `needs questions: asked in a later run of the project, the item moves forward (seen +1, asked_in both, the old in its done/ as asked again in <run>)`
- `needs questions: list shows the question card after a block card, its text, a where row per Files: path and the entries.jsonl line`
- `needs questions: done --why resolves a question with that why`
- `needs questions: a later entry's resolved resolves it at the sweep (answered in <feature>'s entry), an earlier one doesn't`

R4-03 (stub runs):

- `needs questions: an entry with two questions opens two question items with their Files:, noted`
- `needs questions: harness needs prints both question cards`
- `needs questions: the same question in a later session is one item, seen 2`
- `needs questions: a later entry's resolved closes it by the run's end`
- `needs questions: a second run's ask moves the first run's open item forward`

R4-04:

- `needs questions: harness needs lists the parked card before the question card`
- `needs questions: status counts questions apart (NEEDS YOU 1 · 3 questions, 0 · 2 questions), the run card keeps the block count`
- `needs questions: no notification carries a question`
- `needs questions: the debrief gatherer lists the open questions under #### Questions for Michael`
- `needs questions: the answer skill records the answer in place and runs needs done`

Two stub runs in this one file share origin's main: `git update-ref` it between them (the Gotchas line). The second
run's check starts the second run **after** the first has ended (`tended`), with `STUB_ASK=A` in both.

### Fixtures and stub flags

- **`needs_fixture`** (`tests/lib.sh`) learns `question`. Its subject is `Should A keep the old cache? (default:
  kept) Files: /srv/q/lib/a.sh:12`. Its record's `entries.jsonl` holds one coding entry of A asking it (line 1), and
  it opens with `asker=A feature=A line=1 record=<rec>`. `open` adds nothing. `resolved` appends a second entry (B,
  `resolved: [<the text>]`), so the sweep resolves it `answered in B's entry`. Pure checks reuse it with the `<run>`
  argument (`needs_fixture question open "" q-a`, then `q-b` for the second run of the same project `proj`).
- **Stub flags**, beside the existing `STUB_ASK=<id>` (that feature's first coding entry asks `Should <id> default to
  off?`) and `STUB_RESOLVE=<id>` (its later entries list that in `resolved`). R4-03 adds both to the header comment:
  - `STUB_ASK_TWO=<id>`: that feature's first coding entry asks two questions, `Should <id> keep the old cache?
    (default: kept) Files: /srv/q/lib/a.sh:12` and `Should <id> log at debug? (default: info) Files:
    /srv/q/lib/b.sh`. Absolute paths, so the check compares the item's `card.where[].path` as written.
  - `STUB_ASK_AGAIN=<id>`: that feature's first coding entry asks `Should ${STUB_ASK} default to off?` (STUB_ASK's
    question, same words). It does nothing without `STUB_ASK`.
  - In the stub's `entry … jq` both are `--arg`s. `questions` becomes the concatenation of STUB_ASK's, ASK_TWO's and
    ASK_AGAIN's arrays (an entry may carry more than one).

## 6. The decision and the docs (R4-05)

`journal/decisions/2026-10-29-questions-wait.md`: the finding (eight questions sat for days, one asked three times),
the choice (§1–§4), and what was rejected: a push per question (eight pushes a night for things that don't stop
anything), parking on a question (a judgment call would stop work a default lets go on), and detecting an answer from
a decision file's text (no reliable link from a question to a line; the skill writes the line *and* runs `done`). Also
`docs/architecture.md` §4 (the needs record: question items, the key, the move forward) and §17 (the answer desk, the
skill's answer step), and `README.md`'s steering section (`harness needs` questions, and how to resolve them).

## Proposed changes (for the run's feature list)

- **R4-03 step 3** says `adding STUB_RESOLVE=B (B's later entry …)`. In a default stub run B has one coding session
  only, and `STUB_RESOLVE=B` names B's question, not A's. The check that does what the step means is `STUB_ASK=A
  STUB_ASK_AGAIN=B STUB_RESOLVE=A`. A's second session (after M1's verify un-passes A) is later than B's entry and
  lists `Should A default to off?`. The builder should use that, and say so in its entry.
- **R4-04 step 2** quotes `NEEDS YOU 1 · 3 questions`. The line is `NEEDS YOU 1 · 3 questions · harness needs` (the
  hint stays, as 53 pins it). The check matches the prefix.
