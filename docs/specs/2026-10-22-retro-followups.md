# Retro follow-ups: test counts, review cost, a retro backlog, semantic memory (2026-10-22)

**Goal.** Four changes that pick up where the in-flight runs stop: a reliable test-count *source* and fix for
continued runs (beyond R1), a measured decision about the milestone review's cost (beyond R2), a tracked backlog so
retros stop re-proposing the same fix, and semantic memory (decisions and answers edited in place) on top of E4.
Each is test-first with a check in `tests/run.sh` written first and watched failing, a `D-H<n>` entry (the next free
numbers at build time — measure and retro will have consumed some; do not hardcode), and its
`architecture.md`/`README.md` lines in the same milestone.

**Rules.** `CLAUDE.md` binds: work only in the worktree, never touch real runs or real state, **fakes mirror the
live API** (fixtures copied from real `check.out`/transcripts, never typed from memory), every behaviour visible in
`harness-log.md` and checked in `tests/run.sh`. Sessions may **not** write `ledger/` — so anything stored there is
written by the **driver** or the **`harness` CLI** (bash), never by a session. `MERGE_POLICY=pr`: open the milestone
PRs, never merge. Proceed on the defaults below and record them; never park.

---

## Depends on (rebase on what is already there)

This run starts **after** both in-flight runs (the queue is one-run-per-project, D-H32, and both are on this repo),
so their PRs may be merged or still open. **Before coding, read the current `main` and both specs, and rebase on
what has landed.** Each item below names the measure/retro pieces it builds on:

| Item | Builds on / must not refight |
|---|---|
| **C** (test counts) | **R1** (`2026-10-21-retro-fixes.md`): per-runner parsers in `lib/testcount.mjs`, `tests-start`/`tests-end` read from `check.out`. **E1** (`2026-10-20-…`): the `summary.json` tests fields and `report.md`. C **extends** R1 (adds a contract as the preferred source and fixes continued-run staleness); it does **not** replace R1's parsers — they stay as the fallback. If R1 isn't merged yet, build C on top of R1's branch/PR, not a parallel reimplementation. |
| **D** (review cost) | **R2** (reviews sized to the milestone: small milestones fold the review in, large ones get one Opus round + a second only on Critical) and **E1/E2** (per-role cost in `summary.json`; the eval set `harness eval` that *judges* any review change). D adds the driver-measured gate and the model-escalation that R2 leaves to the initializer's prose; it is **judged with E2 evals, which Michael runs**. |
| **E** (retro backlog) | the **retro** prompt and `lib/driver.sh`'s `retro()`/`ledger()`; the **debrief**'s "earlier retros … for proposals seen in two or more" (`lib/debrief.sh:164`). Build on E4's single-writer `entry.json` pattern (the driver validates and is the only writer). |
| **F** (semantic memory) | **E4** (`entries.jsonl`, the rendered `progress.md`, and `context.md` the context pack): F adds the semantic (edit-in-place) half and makes E4's context pack carry the project's current rules and drop resolved questions. **Build on E4; do not redo it.** If E4 hasn't merged, F's milestone waits on it (see the table). |

---

## C · A test-count contract, and correct counts on a continued run (extends R1)

**Finding.** R1 fixes the *parsing* (jest/pytest/node/cargo/go), which is the confirmed pain: `testcount.mjs`
reported `6 → 6` for portfolio_site's 1115-test jest suite and `? → ?` for python, and "fix the tests counter"
appears in **6 retros** (v2-2026-10-18, agent-harness-2026-10-19, portfolio_site-2026-10-20, -20-2, -20-vc4,
-21-v3). Two gaps remain beyond parsing:

1. **The source is fragile.** Scraping a human-readable summary line breaks whenever a runner changes its wording or
   a project uses an unlisted runner. A **contract** is sturdier: a project's check may print a line
   `HARNESS_TESTS=<n>` (the harness reads the last such line if present), or the harness reads a runner's structured
   report (`jest --json`, `pytest --report-log`, `go test -json`) where the project opts in. R1's parsers remain the
   fallback when neither is present, logged in `harness-log.md` as "test count: parsed (<runner>)" vs "test count:
   HARNESS_TESTS contract" vs "test count: no match".
2. **Continued runs can report a stale count.** `tests-start` is written once, into `<state>` (`driver.sh:189`),
   and `cmd_continue` never removes it (`bin/harness:187`); `tests-end` is written only at `finish()`
   (`driver.sh:377`). So between a `continue` and the next `finish` the summary/status shows the previous segment's
   `tests-end`, and `tests-start` is the first segment's baseline. **Evidence caveat:** the run the task cited,
   `hit_list-2026-10-20`, does **not** actually show this — its `summary.json` is correct (`387 → 656`), the lone
   `387 → 387` is a legitimate docs-only plan entry, and `589` is a correct M5 figure; despite being a continued run
   (`continuations: 1`) its counts are right because each segment reached `finish`. So this is a **latent** bug
   confirmed in the code, not one that has bitten a shipped summary yet; keep the fix small and don't over-claim it.

**Change.**
- `lib/check.sh`/`testcount.mjs`: prefer a `HARNESS_TESTS=<n>` line in `check.out` (or a configured
  `TEST_REPORT=<path+format>` structured report), then R1's per-runner parsers, then the heuristic; log which source
  was used.
- The driver refreshes `tests-end` from the latest green suite **after every session** (not only at `finish`), so
  status and a continued run always show the current count; `tests-start` stays the run's original baseline, and the
  summary labels it "baseline at run start" so a continued run's start is not mistaken for this segment's.

**Decision — extends R1, does not replace it.** R1's parsers are the fallback; the contract is the preferred source;
the staleness fix is independent of both.

**Checks (written first):** a `check.out` fixture with a `HARNESS_TESTS=1115` line yields 1115 (contract wins over a
misleading `6 passed`); with no contract line, R1's jest/pytest parser still wins; with neither, the heuristic and a
"no match" log. A stub continued run (segment 1 ends, segment 2 adds tests) shows `tests-end` moving after a session,
not only at finish, while `tests-start` holds the original baseline. Fixtures are copied from real `check.out` files,
never typed.

---

## D · The milestone review, measured and gated (beyond R2)

**Finding (quantified from the ledger).** Two review layers run on the same code: an **in-session** Opus reviewer
subagent on every build feature (`prompts/coding.md` §2), then a separate **`kind:"review"` milestone feature**
(`prompts/initializer.md`) that re-reads the whole milestone diff, then an independent **verify**.

- Milestone review (summed over `summary.json` `features_detail[kind=="review"].cost`) is **14.0 %–33.6 %** of a
  run; aggregate **$258.35 of $1 055.38 = 24.5 %** across the 12 runs with data. Independent verify adds only 3.4 %
  (it runs on Sonnet; review runs on Opus). "Cap or route per-milestone review" appears in **8 retros** — the single
  most-repeated proposal — and two retros call it "proposed seven/eight times and still unfixed."
- It is **not pure waste.** The milestone pass caught, on top of in-session review, at least **1 Critical** (rane
  M3-06 `wow-flutter.mjs`: a dropout detector that scored worse glitches as *better*, a cross-feature bug the
  per-feature reviews structurally could not see) and **~45 Important** across runs, several of them safety,
  security or data-loss (rane M1-06 unarmed-port MIDI; portfolio_site-vc4 forged-Origin token mint; dj trash/repoint
  data loss).
- But it is **redundant on a measurable minority**: at least **5–6 milestone reviews returned 0 Critical / 0
  Important** (voice-concierge-2026-10-20 C8-02, -21 V6-02; portfolio_site-2026-10-20 VC3-05; hit_list M3-04; dj
  N2-04) — and those are the small milestones (1–3 features) that **R2 already folds in**.
- **In-session review cost can't be isolated** from the ledger: it is a subagent inside the build session, billed
  into `by_role.build`. State this as a limitation — any claim about it must come from E2's token logs, not
  `summary.json`.

**So the recommendation changed from the proposal.** The brief's first option — "skip the milestone review when the
in-session reviews found nothing Critical" — is **unsafe**: the Critical the milestone pass caught (rane) was
precisely what no in-session review could see, and in-session findings aren't recorded where the driver could gate on
them. **Keep the milestone review for multi-feature milestones (R2 already removes it for small ones); make it
cheaper, not absent:**
1. **Gate the model on diff size, measured by the driver.** The driver already has the milestone's commit range;
   it measures the diff (files/lines) and passes a `{{REVIEW_DIFF}}` figure to the review feature. Below a threshold
   (default `REVIEW_OPUS_LINES`, e.g. 400 changed lines) the review runs on **Sonnet**; above it, **Opus**. (Several
   retros propose exactly "route review to Sonnet … Opus costs ~10×.")
2. **Sonnet first, Opus on escalation.** The review runs on Sonnet; it escalates one round to Opus only when it
   reports a Critical or an Important, mirroring verify's existing escalate-on-thin-evidence pattern
   (`VERIFY_ESCALATE_MODEL`). A `REVIEW_ESCALATE_MODEL` config (default `opus`) names the escalation model.
3. `summary.mjs` keeps reporting cost by role **and** adds review cost as a % of run and a count of review features
   that found nothing Critical/Important, so the effect is visible and the next retro sees it.

**Any change here is judged with measure's E2 evals (`harness eval compare`), which Michael runs** — the spec must
not claim a cost win it hasn't measured. The build writes the before/after eval commands into `evals/NEXT.md` (E2's
mechanism), comparing a pre-D tag with D on the eval set for $ per verified feature and verify-fail rate.

**Checks (written first):** a stub milestone whose measured diff is below the threshold builds a review feature on
Sonnet; above it, on Opus. A stub review that reports a Critical escalates one round to the escalate model; one that
reports nothing does not escalate. `summary.json` carries the review-cost % and the no-finding count. R2's folding of
small milestones is untouched (a two-feature milestone still yields no `review` kind feature).

---

## E · A tracked retro backlog so proposals aren't re-raised as prose

**Finding.** Retros re-propose the same fix because nothing records that a proposal is already specced, queued or
merged. The retro prompt (`prompts/retro.md`) asks the session to note "whether an earlier retro proposed it already"
by reading the other `retro.md` files — a judgement it makes from scratch each time. Result: **review-cap proposed in
8 retros and the tests-counter in 6**, both already specced (R2, R1) yet re-raised as late as 2026-10-21, the same
day as the retro-fixes spec. The debrief does the same aggregation ad hoc (`lib/debrief.sh:164`, "proposals seen in
two or more"). The largest **unaddressed** repeat is "a parked feature shouldn't block unrelated milestones" (4
retros), specced nowhere — proof the backlog must also make *gaps* visible, not only dedupe.

**Design (driver writes, retro reads — sessions never write `ledger/`).**
- **Store:** `ledger/retro-backlog.jsonl`, one object per proposal: `{id (kebab-case slug), title, first_seen (run
  id + date), runs_seen [run ids], status (proposed|specced|queued|merged|dropped), spec (path), pr (url), note}`.
  It lives in `ledger/` beside `runs.jsonl`, committed by the driver under the existing ledger flock (`driver.sh`
  `ledger()`), so the "sessions may not write `ledger/`" rule holds — the writer is the driver, not the retro
  session.
- **The retro emits structured proposals**, not just prose (E4's `entry.json` pattern): alongside `retro.md` it
  writes `<run>/retro-proposals.json` — a list of `{id, title, evidence}`. The retro prompt is given the **current
  backlog** (bash passes `HARNESS_BACKLOG=$LEDGER/retro-backlog.jsonl`, as it already passes `HARNESS_LEDGER`), so it
  reuses an existing `id` when re-raising and coins a new slug only for a genuinely new proposal; the prompt says to
  reference a backlog id and its status rather than re-arguing a `specced`/`queued`/`merged` item.
- **The driver merges proposals into the backlog** in `finish()` right after `retro` and within the ledger commit:
  a new `id` is appended as `proposed`; a known `id` gets this run added to `runs_seen` (status unchanged). The
  driver validates `retro-proposals.json` (bad JSON → logged, skipped, the run goes on), exactly as E4 validates
  `entry.json`. The retro session never touches the backlog file itself.
- **Status transitions are a CLI command, not a session:** `harness backlog list`, and `harness backlog set <id>
  <status> [--spec <path>] [--pr <url>] [--note …]` — bash, so it may write `ledger/` (flock + commit). Michael (or
  an interactive harness session running the CLI) moves an item to `specced`/`queued`/`merged` when he specs, queues
  or merges it. `harness backlog list` shows id, title, status, count of runs seen, and links.
- **The debrief reads the backlog** (bash adds `retro-backlog.jsonl` to `context.md`) and its "For the next
  interactive session" section lists open `proposed` items by `runs_seen` count and flags items re-raised though
  already `specced`/`queued` — replacing the ad-hoc retro-scanning.

**Checks (written first):** a stub retro emitting a new proposal id appends a `proposed` row; a second stub run
emitting the same id adds its run to `runs_seen` without duplicating the row or changing status; a malformed
`retro-proposals.json` is logged and the run finishes; `harness backlog set <id> specced --spec <p>` flips the status
and `harness backlog list` shows it; the retro prompt, given a backlog with that id as `specced`, is handed the
status (assert the rendered prompt contains the backlog line). The backlog file is only ever written by the driver or
the CLI, never by the retro session (assert `restrict` still reverts a retro that tries to edit it).

---

## F · Semantic memory: decisions and answers edited in place (on top of E4)

**Finding (confirmed) and caveat.** Episodic memory (progress.md, INBOX, E4's journal) is append-only; semantic
memory — a project's decisions file, CLAUDE.md — should hold the *current* rule, edited in place.

- **Decisions drift — confirmed.** rane-one-mixxx's `docs/decisions.md` carried the overturned **D9** night-time
  port rule ("the real Rane ONE port stays unbound until Michael says otherwise") alongside **D13** (2026-10-20),
  which said in its own text that it *superseded* D9 — the two coexisting for about a day. D9's entry was never
  edited; a session reading "the newest rule" could still hit the dead one. Michael fixed it **by hand on 2026-10-21
  in commit `266f369`**, which rewrote D9 (and D4) **in place** to the D13 rule with a `(Updated in place
  2026-10-21: … superseded by D13 …)` line, reworded D13 from "Supersedes" to "Lifted … (both updated in place)",
  and added a header saying the file is the **current rule set**, overturned entries rewritten in place with one
  "(Updated in place <date>: …)" line, history in git. **That commit is the exact template for this spec's
  convention.**
- **Resolved items lingering — confirmed in a different shape than the task stated.** The task's claim that an
  INBOX-answered question stayed in progress.md's "Questions for Michael" and was re-asked, "fixed by hand in
  `266f369`", does **not** hold: `266f369` touches only `decisions.md`. What is real is that the resolved **D9** kept
  appearing as an open `*default*`/"still open" item in progress.md entries *after* D13 overturned it — the same
  drift surfacing in the questions list — and the 2026-10-21 resume brief had to restate standing INBOX answers by
  hand. So the "mark resolved items resolved" need is genuine; the specific commit attribution is not. The rane
  **retro never mentions any of this** — semantic drift is a silent failure the harness doesn't currently surface,
  which is why it needs a prompt rule plus E4's context pack, not a retro.

**Change (build on E4; do not redo it).**
1. **A changed decision is rewritten in place.** The coding and initializer prompts gain a rule: when a decision in
   the project's semantic file (where the project rules say decisions live) is overturned, **edit the existing entry
   in place** to the new rule and append one `Updated in place <date>: <what changed and which decision overturned
   it>` line — do **not** leave the dead rule standing beside a new one. (Model it on rane `266f369`.) This is
   semantic memory; the append-only journal/progress record stays as E4 leaves it.
2. **Answered questions are marked resolved**, so E4's context pack drops them: when a "question for Michael" is
   answered (INBOX `## Answers`, or a decision settling it), the session marks that item resolved in its entry, and
   the context-pack selector (E4 §3) excludes resolved questions from "this feature's … questions".
3. **E4's context pack includes the project's current rules.** The deterministic context pack (`context.md`) adds a
   bounded slice of the semantic file's current decisions (the headings and their current one-line rule, newest
   first, within `CONTEXT_PACK_BYTES`), so a fresh session sees the live rule set without reading the whole file and
   without hitting an overturned rule. No LLM summarizes it — it is the file's own current lines.

**Checks (written first):** the coding/initializer prompt text contains the edit-in-place rule (assert the rendered
prompt); a stub session that resolves a question has it dropped from the next session's `context.md`; the context
pack includes the semantic file's current decision lines and respects `CONTEXT_PACK_BYTES`; a legacy run with no E4
journal is untouched (same guard E4 ships). Because F edits prompts and the E4 context-pack selector, its checks sit
beside E4's and must not regress them.

---

## Milestones

| M | Contents | After |
|---|---|---|
| C | §C (test-count contract + continued-run staleness) | R1, E1 (rebase; don't reimplement the parsers) |
| D | §D (milestone review gated on diff size; Sonnet-first/Opus-escalate; review-cost in summary) | R2, E1; **judged by Michael with E2 evals** |
| E | §E (retro backlog: `ledger/retro-backlog.jsonl`, retro emits/reads, driver writes, `harness backlog` CLI, debrief reads) | retro()/ledger()/debrief; E4's single-writer pattern |
| F | §F (decisions edited in place; answers resolved; context pack carries current rules) | **E4 (hard dependency — do not start F until E4's journal/context pack is on main)** |

Each milestone gets its `D-H<n>` entries (next free at build time; do not hardcode — measure/retro consume some),
its `architecture.md`/`README.md`/prompt/`templates/user/config.sh` lines in the same milestone, and its checks in
`tests/run.sh` written first and watched failing. The suite must end green. `MERGE_POLICY=pr`: open the PRs, never
merge. C and E are independent of each other and of F; D is independent but only *judged* after E2; F depends on E4.
