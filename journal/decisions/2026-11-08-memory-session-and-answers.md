# The memory session and the answers: a denied curator, an `auto` that keeps its body, answers the next curator reads

*(2026-11-08, run agent-harness-2026-11-08, N2 (the deny-list row by N2-01, the body-refresh row by N2-02, the answers row by N2-03); spec
`docs/specs/2026-11-07-memory-followup.md` §N2; journal/learning/2026-11-07-memory-curator.md §11 answer 7 (build the
deny list: `Bash(git push:*)`, `Bash(gh:*)`; `memory_foreign` stays the second layer) and §13 item 3; Claude Code's
https://code.claude.com/docs/en/cli-reference (`--disallowedTools`, "Deny rules", one quoted rule per argument;
`--settings <file|json>`) and https://code.claude.com/docs/en/permissions ("Rules are evaluated in order: deny, then
ask, then allow"; an allow rule can't carve an exception out of a deny rule), both read 2026-11-07;
decisions/2026-11-07-memory-tiers (the known limit this closes).)*

- **Finding:** the curator was read-only by revert alone: `restrict … nothing` undoes what it changes in the run's
  worktree and `memory_foreign` refuses a memory branch tip the driver would not have written, but neither reaches a
  push. A session under `--permission-mode auto` may run `git push` or `gh` against any ref or PR; the tiers decision
  recorded it as a known limit, and Michael said build the deny list (answer 7). `lib/debrief.sh` already runs one
  session under `--disallowedTools "${DENY[@]}"` with rules in the `Bash(git push:*)` form, so the flag and the form
  are in use on this box.
- **Choice (N2-01):**
  - `session()` (lib/record.sh) takes an optional `S_DENY` array, as `S_TURNS`, `S_BUDGET` and `S_TIMEOUT` are per-call
    overrides, and appends `--disallowedTools "${S_DENY[@]}"` last on the one `claude -p` line when it is set and
    non-empty (last: the flag takes every argument after it up to the next option). *Default*: the flag on the command
    line over a `--settings` JSON with `permissions.deny`: the flag's semantics are documented for exactly this, it
    leaves `AGENT_SETTINGS` meaning what it means, and the argv is what the stub records. Deny is evaluated before allow,
    so neither the mode nor a project's `.claude/settings.json` allow admits a denied call.
  - `curator()` (lib/driver.sh) fixes `CURATOR_DENY=("Bash(git push:*)" "Bash(gh:*)")` beside its `MAX_TURNS=40
    SESSION_BUDGET_USD=3` and passes it as `S_DENY`; the curator is the only caller (`grep -n S_DENY lib/*.sh`). The
    coding, verify, retro and every other session get no `--disallowedTools` from `session()` (*default*: the curator
    alone; a retro list is not in this spec). *Default*: not a config knob, since a knob can be set empty and this is a
    floor; a project that needs more adds to the array in a feature. Nothing else in the list: every other write the
    curator could make is reverted by `restrict`, and `memory_foreign` stays the second layer for a push that found
    another form (a Bash rule does not match the same program invoked differently).
  - The colon form, `Bash(git push:*)`, as `lib/debrief.sh` passes it (*default*: one form in the repo). The current
    permissions page writes its examples as `Bash(git push *)` and documents no retirement of the colon form.
    **Falsifier:** a real curator transcript that shows a `git push` or `gh` call run, not refused, under this list, or a
    CLI release note retiring the colon form: then both lists move to the space form in one feature.
  - Visible: the `run.log` line `curator · <model> · deny Bash(git push:*) Bash(gh:*)` and one `harness-log.md` note
    per curator session, `curator: session denied Bash(git push:*), Bash(gh:*)`, given after the restrict (a note before
    it would be reverted). `prompts/curator.md` keeps its "No push, no `gh`" sentence and adds that the driver denies
    both, so such a call is refused.
  - The stub mirrors the CLI: every headless session records its argv in `$STUB_DIR/argv/<n>-<kind>.args` (the desk's
    `<n>-<name>.args` shape, the prompt as `<prompt>`, then `PWD=` and `HARNESS_RUN_ID=`); `STUB_CURATOR_PUSH=1` has the
    stub curator commit a Gotchas line and push it to `harness-memory/<run>` unless its argv carries `--disallowedTools`
    with `Bash(git push:*)`. *Default*: the stub prints no denial event, since none has been captured from the real CLI
    and a guessed line is what `CLAUDE.md` forbids; the check reads the argv and the absence of the push. A captured
    deny event goes into `tests/fixtures/` and the stub replays it, in a later feature.
  - Checks (tests/checks/curator-run.sh, slow): `curator: the curator session alone runs under --disallowedTools, with
    Bash(git push:*) and Bash(gh:*) and nothing else`, `curator: its run.log line names the deny list and harness-log.md
    has one note saying so`, `curator: a curator that would push is denied; harness-memory/<run> holds the driver's one
    commit and its memory PR opens as stub-three-ops predicts` (the `cd` run). Without the push rule all three are red
    (probed 2026-11-08). No unit test: no pure function changed.
- **Rejected (N2-01):** a `--settings` JSON carrying `permissions.deny` (two meanings for one flag, and a file the stub
  would have to parse); a `CURATOR_DENY` config knob (a floor that can be emptied is not one); `--permission-mode
  dontAsk` with an allowlist, as the debrief runs (the curator reads with `jq` and arbitrary commands; an allowlist is a
  larger change than answer 7 asked for); the deny list on every session (the coding and verify sessions push their
  own branches by design).
- **Finding (N2-02):** under `MEMORY_POLICY=auto` `memory_pr` merged the facts PR whenever its segment pushed a tier-1
  commit, whether or not `memory_edit`'s `gh pr edit` had put this segment's body on a reused PR: the merge went into
  `main` with an older body, which is the audit trail of what was merged (Michael's flip of M3-02's question,
  decisions/2026-11-07-memory-policy).
- **Choice (N2-02):**
  - `memory_edit` returns `gh pr edit`'s status; `memory_pass` returns 1 when it pushed a commit to a reused PR whose
    edit failed. `memory_pr` merges the facts PR only when that status is 0: a fresh PR (`pr create --body-file`)
    carries its body and merges as before; a reused PR whose edit failed gets one note in place of the two
    (`its body was not updated …` and `merged into main`): `memory PR: its body was not updated (see run.log); not
    merged (MEMORY_POLICY=auto), left open · <url>`. The edit's own failure note is held back for this one case (its
    `quiet` argument), so the segment says it once.
  - *Default*: no retry of the edit inside the segment (one `gh` call per step is the harness's origin rule); the
    branch is pushed and the PR open, so the next segment reuses both and refreshes the body; since R1-03 of
    agent-harness-2026-11-09 it no longer merges then (the driver merges only a PR whose one commit past main is the
    segment's own), so the PR waits for Michael.
  - *Default*: the second facts edit, the one that names a rules PR opened after the facts body was written, does not
    decide the merge: a failed first edit stays unmerged even when the second succeeds (one rule, and the first
    failure keeps its note), and a failed second edit after a good first one still merges, since this segment's body is
    on the PR and only the other PR's URL is missing, which its own note says.
  - Under `pr` nothing changes (no merge either way, the edit's failure note as before); the rules PR is never merged
    (invariant 3), so this concerns the facts PR alone.
  - Checks (tests/checks/memory-branch.sh, slow): `memory PR: under MEMORY_POLICY=auto a reused PR whose body refresh
    failed gets its commit but no merge, with one note` and `memory PR: the next segment refreshes the reused PR's body
    and merges it at the commit it pushed` (now `memory PR: under auto the next segment refreshes the reused PR's body
    and leaves it open: …`), on two continues of the `mw` run (`STUB_GH_DOWN=1 STUB_GH_DOWN_ONLY=edit`,
    then gh up), each adding one fact (`tests/fixtures/memory/stub-fact-b.json`, `stub-fact-c.json`). Both red before
    the change (the first continue merged). No unit test: no pure function changed.
- **Rejected (N2-02):** a retry of the edit inside the segment (a second `gh` call for one step, and the next segment
  retries anyway); merging a reused PR that is already pushed on a bare body refresh with no new tier-1 commit (a new
  behaviour the spec does not ask for: only a new tier-1 commit merges, as before); clearing `PASS_HEAD` on a failed
  edit to stop the merge (it would hide the pushed commit from the decision that reads it).
- **Finding (N2-03):** tier 2 and tier 3 were the least instrumented decisions: a rules PR's merge or close is counted
  (N1-01), but a tier-3 proposal is no commit, a rule Michael took out of a rules PR before merging leaves no trace, and
  nothing stopped the next curator from proposing a rule he declined last week (§12 of the learning file).
- **Choice (N2-03):**
  - `harness memory accept|decline <run>/<n> --why "<text>"` (lib/memory.sh, the work in lib/memory.mjs) is Michael's
    verdict on a numbered rule or proposal of `ledger/<project>/<run>/memory-result.json` (found by `<run>` across the
    ledger's projects; two projects with one run id is an error line). One row of `ledger/memory-answers.jsonl`
    (*default* name, beside `memory.jsonl` and `retro-backlog.jsonl`): `{run, project, n, tier, verdict, why, file,
    section, text, key, at}`, `verdict` `accepted` or `declined`, the item's `text`, `section` and `key` copied so the
    row stands alone; an earlier row for the same item (`<run>/<n>` and its `key`: *default*, since a continue numbers
    its items from 1 again, so an old number may name another item, whose answer then sits beside the first's) is
    replaced (written whole, renamed), under the ledger's
    lock and, with `LEDGER_COMMIT=1`, one ledger commit of that file (`ledger: memory decline <run>/<n>`), as `harness
    backlog set` is. It prints `memory: <run>/<n> declined · <section> · <text cut to 60>`. An unknown run, an `<n>`
    the run has not (tier 1 is never numbered, so a tier-1 `<n>` is one of these), a missing `--why`, or a why that is
    not one line of at most 300 characters (`WHY_MAX`) is one error line, exit 1, and no row. **The verbs are
    Michael's** (they write the ledger), as `backlog set` is; `harness memory` and `harness memory proposals <run>`
    (the numbered items with their tier, file, section, text and any verdict: *default*, so he need not open the PR to
    find `<n>`) are the listings.
  - *Default*: `<n>` is the numbering of the run's last segment, the one the ledger's `memory-result.json` holds (each
    segment numbers from 1); an answer to an earlier segment's item is given before the run is continued.
  - *Default*: both verdicts close the item. `apply` (lib/curator.mjs) takes the project's rows (`--answers <file>
    --project <p>`, flags because the fifth positional is the rules base) and drops a tier-2 or tier-3 op whose line is
    an answered item's, after the gate and the dedupe and before the tier-3 proposal: `declined by Michael (<run>/<n>:
    <why cut to 80>)` or `accepted by Michael (<run>/<n>)` (an accepted line is his to place by hand; once placed, the
    "already in section" rule drops it anyway). The reason reaches both bodies' *Dropped* and the notes as every drop
    does, so a curator that keeps proposing a declined rule shows in the drop rate.
  - The line alone decides, not the section: the same sentence under another heading is the same rule. The row's `key`
    is `lineKey` (the anchor normalizer: marker and suffix cut, `factKey`'s first 40 characters) of the op's text, the
    item's identity beside `<run>/<n>`; the match is the whole normalized line (`factText` of the text, marker and
    suffix cut), since two rules can share their first 40 characters (N2-04's review: declining `Never pipe a
    multi-write producer into grep -q …` dropped `… into grep -m …`). A delete's is its anchor's, marked `delete `
    (*default*), so declining a deletion never drops an add of that line. Tier-1 ops are never matched: a fact is not
    a rule Michael declines; a wrong fact is a `delete` op's job. Known limit (N2-04's review): a declined rule a later
    curator restates under `## Gotchas` is tier 1 and lands (under `auto` merged); the write gate still needs a
    `project` discovery saying it. A declined line already committed on an open rules PR stays there: decline it by
    taking it out of that PR too.
  - The next curator is told: `prompts/curator.md`'s `## What Michael declined and accepted` carries
    `{{MEMORY_ANSWERS}}`, which `curator()` renders (`memory_answers` in lib/prompt.sh, `curator.mjs answers <file>
    <project> --max-bytes 4000`): `Michael declined (never propose again):` then `Michael accepted (already his to
    place):`, newest first, each `- <text> (<run>/<n>)` (a decline with `: <why>`; a delete's as `delete: <line>`), cut oldest first with a line saying
    how many were left out; `(none yet)` for no rows. *Default*: the run record gets no copy of the answers: what the
    curator was told is in the state dir's `prompt-curator.md`, and the ledger holds the rows.
  - Counted: `harness memory` adds `answers: accepted <a> · declined <d>` over the shown runs' latest rows (a replaced
    verdict counted once) after the two tier lines, and marks a run's first line ` · <k> answered`; with no
    `memory-answers.jsonl` the listing runs as before with `answers: accepted 0 · declined 0`. The rows carry `tier` and
    `section`, so acceptance per tier and per section is readable from the ledger when F3e reads them.
  - Checks: tests/unit/curator.test.mjs (`answers`, `apply`'s drop, its CLI), tests/unit/memory.test.mjs (the row, the
    replace, the tally, the proposals view, memoryView's line), tests/checks/memory-branch.sh (slow: `proposals`,
    `decline` and its commit, the error lines, the later run `mn` dropping the declined rule with no rules PR and its
    prompt carrying the line), tests/checks/curator-run.sh (`(none yet)`). The spec's `mp/2` proposal does not exist:
    `stub-three-ops` has no tier-3 op (N1's `0 proposals`), so the checks name `mp/1` alone.
- **Rejected (N2-03):** a verdict matched by section (the same rule under another heading would come back); a copy of
  the answers in the run record (the ledger and the rendered prompt already hold it); a verdict on a tier-1 fact (the
  delete op is the tool); a session writing the answers file (the verbs are Michael's).
- **Rejected (N2-04's review):** matching a verdict on the 40-character `key` (two rules sharing a prefix are one: the
  whole normalized line decides); matching tier-1 ops against declined rows (the spec's rule: a fact is never his to
  decline; the Gotchas hole is a known limit above, asked of Michael).
- **The checks (N2):** `tests/fixtures/check-names.txt` gains 19 names and loses none (`git diff $(git merge-base HEAD
  origin/main) -- tests/fixtures/check-names.txt`: `grep -c '^+[^+]'` 19, `grep -c '^-[^-]'` 0), within the budget of
  30: N2-01 3 (curator-run), N2-02 2 (memory-branch), N2-03 14 (8 unit, 6 stub), N2-04 none new (two of N2-03's unit
  names reworded in place for the asserts the review added: a sentence sharing the 40-character key, a torn answers
  line).
Updated in place 2026-11-09: `CURATOR_DENY` is one top-level array of `lib/driver.sh`, and the memory reviewer is its
second reader (`S_DENY` in `memory_review()`): decisions/2026-11-09-memory-reviewer.
Updated in place 2026-11-10: under `auto` a reused facts PR is merged only when its one commit past main is this
segment's own; the N2-02 continue that refreshed a failed body and merged the earlier commit with its own now leaves the
PR open (decisions/2026-11-09-memory-reviewer, R1-03's review, I1: a `Memory-review: held` trailer any session could
write was the only thing vouching for the earlier commit).
