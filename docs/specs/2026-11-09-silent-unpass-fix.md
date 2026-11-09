# A claim that never reached the list: named at the session's end, one told retry, a card that says why (2026-11-09)

**Goal.** A coding session's verdict is the `passes` key of its copy of `feature_list.json` (`lib/lane.sh:495`, `:501`),
and nothing else. A session whose `entry.json` says `outcome: passes` while that key stayed `false` is read as "not yet"
with no line saying so; when it was the re-check's one granted attempt, the feature is given up, the lane closes
`given up (nothing left to try)` and the `given_up` card tells Michael to read entries that say passes
(`findings-and-research/2026-11-09-silent-unpass-diagnosis.md`). This spec lands two rules: **every flip of a session's
`passes` at its end has a note in `harness-log.md` naming the check that flipped it**, and **a feature the re-check sent
back is never given up without its reason in the note and the card.** One milestone, **G1**, four features.

**Source.** The finding above (its §2 table is the path; its §4 traces are the evidence); `lib/lane.sh` 460–540 (the
session-end path), 251–260 (the re-check's grant), 410–420 (the lane's close words); `lib/features.mjs` (`repairList`,
`schedule`, `blockedLines`, `grant`); `lib/entries.mjs` (`ingest`, `journalEntry`); `lib/needs.mjs` (`given_up`);
`lib/prompt.sh` and `prompts/coding.md` (`{{REVIEW_DIFF}}`, `{{?FIX}}` under *This session*; `prompts/verify.md`'s
`{{?THIN}}` block is the pattern of a told round); `tests/stub-claude.sh` (`set_passes`, the `demo` scenario);
`docs/plans/2026-11-03-test-suite-redesign-dispatch.md` *Rules for this effort* (a guard names what it found; a
recoverable gap gets one told retry before a card); the retro proposal `verify-failed-recheck`
(`.harness/runs/agent-harness-2026-11-07-3/retro-proposals.json`).

**Rules.** `CLAUDE.md` binds: worktree only; never touch real runs or real state; fakes mirror the live API; `bash -n`,
`node --check`; a decision file `journal/decisions/2026-11-<dd>-claim-gap.md` (title, provenance, finding · choice ·
rejected); `docs/architecture.md` (§5 the session-end lines, §7 Guards: a *Claim gap* row, the *Attempts* row's
given-up words) and `README.md` in the same milestone. **Proceed on the defaults written here, marked *default*; never
park.** Checks are written first and watched failing; a pure function's behaviour gets a unit test, a driver behaviour
one stub run in the check file named below. The list stays the verdict: nothing here reads a claim as a pass.

## Finding

At `lib/lane.sh:467` the driver ingests the session's entry (its `outcome` is the session's own word, `entries.mjs
journalEntry` → `normalize`); at `:489` it repairs the list; at `:495` it reads the list's key, and a `false` skips the
gate block, so the two notes that name an un-pass (`fast tier red`, `<FIX_RED> red`) are never reached; at `:501` the
verdict is read again and at `:521` written as `passes=false`, the same line a session that said "not yet" produces. At
`:533` a feature whose attempts are spent gets the `given_up` card, whose why is fixed text ("Its sessions' entries say
what failed"). The lane's close (`:419`) names only features *waiting on* a given-up one (`blockedLines`), so a given-up
feature with no dependant closes as `given up (nothing left to try)`. In the stub run of the finding the two traces
diverge at `:495` on `F_RC` alone.

## Choice

1. **The claim gap is named** (G1-01). After `F repair` and before the gate, the driver compares the entry it just
   ingested with the list it is about to read. A pure function in `lib/lane.mjs`, `claimGap({ id, outcome, passes })`
   → the note's words, or `""`: words only when `outcome === "passes"` and `passes === false`. *Default* words:
   `<id>: its entry says passes but feature_list.json's passes stayed false; the claim never reached the list (the flip
   is the session's one list edit, prompts/coding.md §3.1)`. The driver writes them with `note`, and writes the same
   words to `$STATE/claim-gap-<id>` (the file is the retry's prompt and the card's why; see 2 and 3). The entry's
   `outcome` comes from the ingest: `entries.mjs ingest` prints one more labelled line, `outcome <word>`, and `journal_`
   keeps it in `$LS/outcome` (the memo pattern of `$LS/question`); a minimal entry's outcome is the driver's own and
   never `passes` with the list at `false`, so it opens no gap. A `parked` or `not yet` entry with the list at `false`,
   and any entry with the list at `true`, is no gap: the gate speaks for those. The final message is not read
   (*rejected*: prose matching; the entry is the session's structured word and the prompt makes `outcome` required).
2. **One told retry** (G1-02). When a gap is found and `$STATE/claim-gap-<id>` did not exist before this session, the
   feature gets one more attempt (`record F grant "$ATT" "$id" "$MAX_ATTEMPTS"`, the re-check's mechanism) and the
   note `<id>: one more attempt, told to set passes (once per run)`; the `passes=` line follows as today. If attempts
   remain anyway, nothing is granted, but the file is still written so the next session is told. The next coding
   session of `<id>` gets the words: `lib/lane.sh` passes `HARNESS_GAP=$(cat "$STATE/claim-gap-$id")` to `prompt coding`
   when the file holds the gap words, `lib/prompt.sh` fills `{{GAP}}`, and `prompts/coding.md` gains under *This
   session* (never above `{{SECTIONS}}`: the same-prefix gotcha in `CLAUDE.md`) a `{{?GAP}}## The session before this
   one` block: "{{GAP}}. Check every step holds on this tree, run the fast tier once, and set `"passes": true` on your
   feature in `feature_list.json`: that key is the one thing the harness reads. Build nothing new." After that
   session ends, whatever its verdict, the file's content becomes `told` (kept: a second gap in the same run grants
   nothing and tells nothing more; *default*: once per feature per run, as the review escalation's
   `review-escalated-<id>`). *Rejected*: taking the entry's `passes` as the flip (the list is the guard's one input,
   D-H3/D-H4, and a session that cannot write one key has not shown the steps hold); a stronger model (a format gap,
   not a judgment gap: rule (ii)).
3. **The give-up names its reason** (G1-03). The card: `needs_open given_up` passes `gap="$(cat "$STATE/claim-gap-$id"
   2>/dev/null)"` and `recheck=1` when `$STATE/recheck-<id>` exists (the verify's `fail` branch touches it beside its
   `F grant`, line 255); `lib/needs.mjs`'s `given_up.why` says, when `recheck` is set, "The verify's re-check sent it
   back (`verify <m>: <id> failed the re-check`), and " and, when `gap` is set, the gap words followed by "its told
   retry did not set it either" when the file says `told`, in place of "Its sessions' entries say what failed" (which
   stays only when neither is set). The lane's close: `features.mjs` gains the pure `givenUpLines(fs, att, max, parked,
   lane)` → `<id>\t<attempts>` per given-up feature of the lane (the mirror of `blockedLines`, subcommand `given-up`), and
   `lib/lane.sh:419` says `given up (<id> after <n> attempts: <last verdict>[; <id2> …])` where the last verdict is the
   claim-gap file's first clause when it exists, else `its last entry: <outcome>` from `$LS/outcome`; the old
   `(nothing left to try)` remains only when the lane has no given-up feature of its own (a dependency outside it).
   The summary's `end_reason` and `harness status`'s line take the same words (they print the lane's exit reason as
   it is; check that nothing cuts them under 100 columns off a TTY: the card-width gotcha).
4. **The stub mirrors the session** (G1-04, with G1-01's checks). `tests/stub-claude.sh` gains `STUB_NO_FLIP=<id>:<n>[,…]`
   (documented in its header): that coding session writes its entry with `outcome: passes` and ends with the final
   message `<id> passes. The commit is pushed.` but never calls `set_passes`: the two-line change of the finding's §3,
   upstreamed. It is the only stub change.

## Checks, written first

Names are for the behaviour. Unit tests go in the module's file under `tests/unit/`; the stub runs in one new fast
file `tests/checks/claim-gap.sh` (`# tier: fast`: the `demo` scenario ends in about 6 s on this box; two runs stay under
the 30 s rule of `decisions/2026-11-03-suite-tiers`). Every new name goes in `tests/fixtures/check-names.txt` and
`check-names-fast.txt`, `LC_ALL=C` sorted. Budget: 10 names (`check_budget: {G1: 10}`).

`tests/unit/lane.test.mjs` (`claimGap`):

- `a session whose entry says passes with the list at false is a claim gap, named with the id`
- `no claim gap when the list agrees with the entry (passes/true, not yet/false, parked/false)`
- `no claim gap for an entry that says not yet while the list says true (the gate's case)`

`tests/unit/features.test.mjs` (`givenUpLines`):

- `given-up lines name each given-up feature of the lane with its attempts, parked and passing ones left out`

`tests/unit/needs.test.mjs` (`given_up`):

- `the given-up card's why carries the re-check and the claim gap in place of "its entries say what failed"`

`tests/checks/claim-gap.sh`, run 1 (`STUB_NO_FLIP=A:2 STUB_NO_TAMPER=1 STUB_NO_RED=1`, the `demo` scenario: verify M1
round 1 un-passes A, A's retry claims without flipping, the told retry flips):

- `a claim that never reached the list is named at the session's end` (`hlog` has the G1-01 words for A, between
  `A: suite ran` and `A · … · passes=false`)
- `the claim gap gets one told retry, its prompt carrying the same words` (`A attempt 3` in `sessions.log`; the third
  A session's recorded prompt, `$STUB_DIR/argv/<n>-coding.args`, holds `The session before this one` and the words)
- `the told retry's flip passes and the milestone verifies and merges` (`verify M1 2` in `sessions.log`; `run/<run>/M1`
  tagged)

Run 2 (`STUB_NO_FLIP=A:2,A:3`, the told retry fails to flip too):

- `a second claim gap grants nothing: the lane closes naming the feature, its attempts and the gap`
  (`lane M1 closed (given up (A after 3 attempts: its entry says passes but feature_list.json's passes stayed false …))`)
- `the given-up card says the re-check sent it back and the told retry did not set passes` (`needs.md`'s why)

## Prediction

On the case's shape (a re-check's retry whose entry says passes with the key at `false`), `harness-log.md` gains the gap
note at the session's end, then a third session of about two minutes on the feature's model (sonnet for A4-01: about
$0.20) that sets the key; the verify runs its second round and the milestone merges. `given up (nothing left to try)`
never again names a feature of the lane's own: every such close names the feature, its attempts and its last verdict,
and its card says the same. Falsifier: told retries that again fail to flip. One in a run is the session's; three in
a week make `prompts/coding.md` §3.1's wording the next suspect (the same words would then move to the top of *Finish*).

## The retro proposal

`verify-failed-recheck` ("re-verify only the failed steps on the retry's fix instead of closing the lane") is answered
in its evidence and refused in its title: the baseline stub run of the finding shows the lane re-verifying (round 2)
and merging as soon as the retry's flip reaches the list; the lane closed because the flip never did. Close the
proposal with this spec's and the finding's paths as the reason; build no partial re-verify.

## Shape

One `claude` session, one PR, this spec as its brief: it changes `lib/lane.sh`, `lib/lane.mjs`, `lib/features.mjs`,
`lib/entries.mjs`, `lib/needs.mjs`, `lib/prompt.sh`, `prompts/coding.md`, `tests/stub-claude.sh`, one new check file and
three unit files, the fixtures, the decision file, `docs/architecture.md` and `README.md`. It runs alone (it changes
`lib/` and adds check names: *Rules for this effort*), runs `bash tests/run.sh --tier fast` while iterating and once last,
and before it ends also `bash tests/run.sh claim-gap park-desk stop-records` (the files that replay the `demo` re-check;
`lane.sh` changed). Not a harness run: four features of one shape, under three hours, and a run of this project would
hold the box against the suite's own stub runs.
