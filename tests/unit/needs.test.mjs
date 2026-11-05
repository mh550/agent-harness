// lib/needs.mjs: the needs record's reasons, sweep, synthesized items, cards, mergedBy, waitsOn and question keys.   node --test tests/unit/needs.test.mjs
import { test } from "node:test";
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import * as N from "../../lib/needs.mjs";
import * as V from "../../lib/view.mjs";

// tests/fixtures/needs/<reason>.json: the facts a card is built from (59-needs-cards.sh)
const fixture = r => JSON.parse(readFileSync(new URL(`../fixtures/needs/${r}.json`, import.meta.url), "utf8"));

// ---- 58-needs-record.sh ----
test("needs REASONS: kind, severity and priority for each of the 17 reasons, as the plan's table", () => {
  assert.equal(Object.entries(N.REASONS).map(([r, x]) => [r, x.kind, x.severity, x.priority].join(":")).join(" "),
    "parked:park:block:high given_up:blocked:block:high verify_thin:needs_michael:block:high verify_red:needs_michael:block:high verify_recheck:needs_michael:block:high merge_conflict:needs_michael:block:high merge_refused:needs_michael:block:high merge_failed:needs_michael:block:high main_conflict:needs_michael:block:high base_conflict:needs_michael:block:high feature_list_edits:needs_michael:block:high initializer_failed:needs_michael:block:high driver_crash:needs_michael:block:high usage_limit:limit:warn: weekly_budget:limit:warn: overlap:needs_michael:warn: question:needs_michael:warn:");
  // a warn reason's priority is the empty string, not missing (78-needs-questions.sh read it as JSON)
  assert.deepEqual(N.REASONS.question, { kind: "needs_michael", severity: "warn", priority: "" });
});

test("needs sweep (pure): passes, verified-<m> and merged-<m> resolve too; a re-base failure waits on needs-<m> while verified; a milestone driver_crash waits on needs-<m>; a conflict while needs-<m> stays", () => {
  const it = (reason, sub) => N.record({ run: "r", project: "p", reason, subject: sub, seq: 1 }, 0);
  const st = o => ({ removed: false, ended: false, passing: ["B"], parked: {}, attempts: {}, max_attempts: 2, markers: [], ...o });
  const w = (i, s) => { const { keep, resolved } = N.sweep([i], s); return resolved.length ? resolved[0].resolved_why : (keep.length ? "kept" : "?"); };
  const cases = [
    ["parked", "B", { parked: { B: {} } }, "feature passes"],
    ["given_up", "B", { attempts: { B: 5 } }, "feature passes"],
    ["given_up", "C", { attempts: { C: 2 } }, "kept"],
    ["given_up", "C", { attempts: { C: 1 } }, "attempts reset"],
    ["verify_thin", "M1", { markers: ["verified-M1"] }, "milestone verified"],
    ["verify_red", "M1", { markers: ["needs-M1", "verified-M1"] }, "kept"],
    ["verify_red", "M1", { markers: ["needs-M1", "merged-M1"] }, "milestone merged"],
    ["main_conflict", "M1", { markers: ["main-conflict-M1", "merged-M1"] }, "milestone merged"],
    ["main_conflict", "record", { markers: ["main-conflict-record"] }, "kept"],
    ["merge_refused", "M1", { markers: ["refused-M1", "merged-M1"] }, "milestone merged"],
    ["merge_conflict", "M1", { markers: ["needs-M1"] }, "kept"],
    ["merge_conflict", "M1", { markers: ["conflict-M1", "merged-M1"] }, "milestone merged"],
    ["driver_crash", "M2", { ended: true, markers: ["needs-M2"] }, "kept"],
    ["driver_crash", "M2", { ended: true }, "needs-M2 cleared"],
    ["driver_crash", "run", { ended: true }, "kept"],
    ["overlap", "x", { ended: true }, "kept"],
    ["verify_red", "M1", { removed: true, markers: ["needs-M1"] }, "run removed"],
  ];
  assert.deepEqual(cases.map(([r, s, o]) => `${r} ${s}: ${w(it(r, s), st(o))}`), cases.map(([r, s, , x]) => `${r} ${s}: ${x}`));
});

test("needs sweep: merge_failed: merged-<m> resolves milestone merged, its marker gone origin back, else kept", () => {
  const i = N.record({ run: "r", project: "p", reason: "merge_failed", subject: "M1", seq: 1, what: "fetch of main" }, 0);
  const w = markers => N.sweep([i], { removed: false, ended: true, passing: [], parked: {}, attempts: {}, max_attempts: 2, markers }).resolved[0]?.resolved_why ?? "kept";
  assert.deepEqual([w(["merged-M1", "merge-failed-M1"]), w([]), w(["merge-failed-M1", "needs-M1"])], ["milestone merged", "origin back", "kept"]);
});

test("needs merge_failed: the item carries what, tries, secs, tag_local and head, a refresh their new values; a card without a step says so", () => {
  const f = { run: "r", project: "p", reason: "merge_failed", subject: "M1", seq: 1, what: "fetch of main", tries: "6", secs: "230", tag_local: "1", head: "abc123" };
  const i = N.record(f, 0);
  assert.deepEqual([i.what, i.tries, i.secs, i.tag_local, i.head, i.card.headline, i.card.commands],
    ["fetch of main", 6, 230, true, "abc123", "M1: merge failed at fetch of main (origin unreachable)", ["harness merge r"]]);
  const r = N.refresh(i, { ...f, what: "merging its PR", tag_local: "", pr: "https://github.com/o/r/pull/9" }, 60);
  assert.deepEqual([r.what, r.tag_local, r.seen], ["merging its PR", false, 2]);
  assert.equal(r.card.options.filter(o => o.text.includes("merge the PR")).length, 1);
  assert.equal(N.record({ ...f, what: "unknown" }, 0).card.headline, "M1: its merge stopped with no reason recorded");
  assert.equal(N.record({ ...f, reason: "merge_refused" }, 0).what, undefined);   // only on merge_failed: other records stay as they were
});

test("needs merge_refused without a PR (a hook declined a push): the card names the step and no PR row", () => {
  const c = N.card("merge_refused", { run: "r", subject: "M1", what: "push of harness-merge/r-M1", state: "/s" });
  assert.ok(c.why.includes("push of harness-merge/r-M1") && !c.why.includes("The PR is open"));
  assert.deepEqual(c.where.map(w => w.label), ["log"]);
  assert.deepEqual(c.commands, ["harness merge r"]);
});

// the eval half of 58's "needs list: no synthesized item once a record is open for it …" (its CLI half stays there)
test("needs.mjs synthesize: a driver_crash only for a dead driver without ended; ended, a live driver or no driver.pid make none", () => {
  const s = { run: "r", project: "p", removed: false, passing: [], parked: {}, log_mtime: 0 };
  assert.equal(N.synthesize({ ...s, driver: "dead", ended: true }, []).length, 0);
  assert.equal(N.synthesize({ ...s, driver: "live", ended: false }, []).length, 0);
  assert.equal(N.synthesize({ ...s, driver: "dead", ended: false }, []).length, 1);
  assert.equal(N.synthesize({ ...s, driver: null, ended: false }, []).length, 0);
});

// ---- 59-needs-cards.sh ----
test("mergedBy: one merge is <run> M3 (PR #34), five of one run collapse, gaps are listed, the run's own are left out, others are PR #<n>, none is new commits", () => {
  const m = (pr, r, x) => `Merge pull request #${pr} from mh550/harness-merge/${r}-${x}`, mem = "agent-harness-2026-10-25-memory";
  assert.equal(N.mergedBy(m(34, mem, "M3"), "own"), `${mem} M3 (PR #34)`);
  assert.equal(N.mergedBy([36, 35, 34, 33, 32].map((p, i) => m(p, mem, `M${5 - i}`)).join("\n"), "own"), `${mem} M1–M5 (PRs #32–#36)`);
  assert.equal(N.mergedBy([m(34, mem, "M3"), m(32, mem, "M1")], "own"), `${mem} M1, M3 (PRs #32, #34)`);
  assert.equal(N.mergedBy([m(40, "own", "P1"), m(34, mem, "M3")], "own"), `${mem} M3 (PR #34)`);
  assert.equal(N.mergedBy(m(40, "own", "P1"), "own"), "new commits");
  assert.equal(N.mergedBy(["Merge pull request #12 from someone/fix-typo", m(34, mem, "M3")], "own"), `PR #12; ${mem} M3 (PR #34)`);
  assert.equal(N.mergedBy("", "own"), "new commits");
});

test("needs cards (review): own default-lane merges left out, a re-merge keeps its newest PR; a fence and tabs stay on their lines; a bad at is since ?; no run is exit 1", () => {
  const m = (pr, h) => `Merge pull request #${pr} from mh550/harness-merge/${h}`, c = V.context({ env: { HARNESS_GLYPHS: "unicode", COLUMNS: "60" } });
  const q = "### B: set these\nfirst line\nsecond line\n```bash\nexport A=1\n\tindented\n```\nFiles: lib/a.sh:3";
  const k = N.card("parked", { run: "r", subject: "B", inbox_text: q + "\n\n## Answers\n", worktree: "/w" });
  const out = N.renderCard({ run: "r", ref: "r/1", at: "", reason: "parked", card: k }, c, {}).join("\n");
  assert.equal(N.mergedBy([m(40, "own-default"), m(39, "own-M1")], "own"), "new commits");
  assert.equal(N.mergedBy([m(43, "x-M3"), m(38, "x-M3")], "own"), "x M3 (PR #43)");
  assert.equal(N.mergedBy(m(7, "x-default"), "own"), "x default (PR #7)");
  assert.match(out, /first line second line\n/);
  assert.match(out, /```bash\n/);
  assert.match(out, / {4}indented/);
  assert.doesNotMatch(out, /\t/);
  assert.match(out, /r\/1 · since \?/);
  assert.equal(k.where[0].path, "/w/lib/a.sh");
  assert.equal(k.where[0].line, 3);
  // the card CLI exits 1 on this throw (`node lib/needs.mjs card overlap <facts without run>`)
  assert.throws(() => N.card("overlap", { subject: "x" }), /a card needs run and subject/);
});

test("waitsOn: a feature's and a milestone's unfinished dependants through after, every unfinished one for run", () => {
  const fs = [{ id: "A", milestone: "M1", passes: true }, { id: "B", milestone: "M1" }, { id: "C", milestone: "M2", after: ["M1"] },
    { id: "D", milestone: "M3", after: ["A"] }, { id: "E", milestone: "M3", after: ["C"] }];
  assert.deepEqual(N.waitsOn(fs, "B"), ["C", "E"]);
  assert.deepEqual(N.waitsOn(fs, "M1"), ["C", "D", "E"]);
  assert.deepEqual(N.waitsOn(fs, "run"), ["B", "C", "D", "E"]);
  assert.deepEqual(N.waitsOn(fs, "Z"), []);
});

test("needs cards: merge_conflict and main_conflict show tried in the card, the notification body and needs.md", () => {
  const t = "a resolve session (opus, 4 min): UNRESOLVED: stub gives up", now = Date.parse("2026-10-27T01:10:00Z") / 1000;
  for (const r of ["merge_conflict", "main_conflict"]) {
    const f = fixture(r), a = N.record({ ...f, seq: 1, tried: t }, now), b = N.record({ ...f, seq: 2 }, now), body = N.bodyOf(a, now);
    assert.equal(a.card.tried, t, r);
    assert.match(body, /^ {2}tried {6}a resolve session \(opus, 4 min\)/m);
    assert.ok(N.markdown([a], a.run).includes("**tried** " + t), r);
    assert.equal("tried" in b.card, false, r);
    assert.doesNotMatch(N.bodyOf(b, now), /tried/);
    assert.doesNotMatch(N.markdown([b], b.run), /tried/);
  }
});

test("needs.mjs card: a park whose question has no Files: takes session_files as where, files_from session; with Files: the question wins", () => {
  const inbox = f => "status: run\n\n### B: set it (2026-10-28 01:00)\n" + f + "\n## Answers\n";
  const base = { run: "r", subject: "B", features: [{ id: "B", milestone: "M1" }], worktree: "/wt", session_files: "/wt/lib/x.sh\n/wt/y.md" };
  const s = N.card("parked", { ...base, inbox_text: inbox("") }), q = N.card("parked", { ...base, inbox_text: inbox("Files: /wt/lib/z.sh:48") });
  const d = N.card("parked", { ...base, session_files: "", inbox_text: inbox("") });
  assert.equal(s.files_from, "session");
  assert.equal(s.where[0].path, "/wt/lib/x.sh");
  assert.equal(s.where[1].path, "/wt/y.md");
  assert.equal(q.files_from, "question");
  assert.equal(q.where[0].line, 48);
  assert.deepEqual(q.where.filter(w => w.path === "/wt/lib/x.sh"), []);
  assert.equal(d.files_from, "driver");
});

// ---- 64-needs-review.sh ----
test("needs review: mergedBy names a run whose id starts with the run's own (agent-harness-2026-10-25-memory in agent-harness-2026-10-25)", () => {
  assert.equal(N.mergedBy("Merge pull request #34 from mh550/harness-merge/agent-harness-2026-10-25-memory-M3\nMerge pull request #30 from mh550/harness-merge/agent-harness-2026-10-25-M1", "agent-harness-2026-10-25"),
    "agent-harness-2026-10-25-memory M3 (PR #34)");
});

// ---- 78-needs-questions.sh ----
test("needs questions: questionKey folds whitespace, lower-cases, drops the harness's fill and a Files: line, cuts at 80", () => {
  assert.equal(N.questionKey("  Should  A\n default\tto OFF?  "), "should a default to off?");
  assert.equal(N.questionKey("Should A default to off? Files (harness, from the session): /w/run-1/lib/a.sh"), "should a default to off?");
  assert.equal(N.questionKey("Should A?\n**Files:** /x/a.sh:3, /x/b.sh"), "should a?");
  assert.equal(N.questionKey("Should A?\nFiles: /x/a.sh\n\n"), "should a?");
  assert.equal(N.questionKey("Should A? Files: /x/a.sh"), "should a? files: /x/a.sh");
  assert.equal(N.questionKey("Q? (default: x)\nFiles: /w/run-1/a.sh\nBranch: harness/run-1"), "q? (default: x) branch: harness/run-1");
  assert.equal(N.questionKey("X".repeat(100)), "x".repeat(80));
  assert.equal([...N.questionKey("é".repeat(100))].length, 80);
  assert.equal(N.questionKey(" \n "), "");
  // 78's $Q, whose record key that file's open check compares as a literal
  assert.equal(N.questionKey("Should A keep the old cache? (default: kept) Files: /srv/q/lib/a.sh:12"), "should a keep the old cache? (default: kept) files: /srv/q/lib/a.sh:12");
});

// the eval half of 78's "asked in a later run of the project, the item moves forward …" (its CLI half stays there)
test("needs.mjs moveForward: two earlier items of the key become one, seen summed, asked_in every run's, both resolved as asked again in the new run", () => {
  const { item, resolved } = N.moveForward([{ run: "r1", seen: 2, asked_in: ["r0", "r1"], ref: "r1/3" }, { run: "r2", seen: 1, ref: "r2/1" }], { seen: 1, asked_in: ["r3"] }, "r3", 0);
  assert.equal(item.seen, 3);
  assert.deepEqual(item.asked_in, ["r0", "r1", "r2", "r3"]);
  assert.equal(resolved.length, 2);
  assert.deepEqual(resolved.map(r => [r.resolved_why, r.resolved_by]), [["asked again in r3", "sweep"], ["asked again in r3", "sweep"]]);
});

test("needs questions: questionKey drops only a Files: label line, and asked_in ends with the newest asker", () => {
  assert.equal(N.questionKey("Pick one:\nFiles over 1 MB: keep? (default: keep)"), "pick one: files over 1 mb: keep? (default: keep)");
  assert.deepEqual(N.moveForward([{ run: "r2", seen: 2, asked_in: ["r1", "r2"], ref: "r2/1" }], { seen: 1, asked_in: ["r1"] }, "r1", 0).item.asked_in, ["r2", "r1"]);
});

// ---- 70-overlap.sh ----
test("overlap: the sweep rule: other run gone, other run merged, this run merged, else kept (no git facts: kept)", () => {
  const i = { key: "overlap:R", reason: "overlap", ref: "x/1" };
  const w = st => N.sweep([i], { markers: [], passing: [], ...st }).resolved[0]?.resolved_why ?? "kept";
  assert.equal(w({ overlaps: { R: "gone" } }), "other run gone");
  assert.equal(w({ overlaps: { R: "merged" } }), "other run merged");
  assert.equal(w({ overlaps: { R: "open" }, self: "merged" }), "this run merged");
  assert.equal(w({ overlaps: { R: "open" }, self: "open" }), "kept");
  assert.equal(w({ ended: true }), "kept");
});

// ---- 87-fast-gate-run.sh: the verify's red on the lane's own tree (main had nothing new) ----
test("needs verify_red own: a slow-tier red the fast gate let through, never main's disagreement", () => {
  const own = N.card("verify_red", { ...fixture("verify_red"), variant: "own" }), red = N.card("verify_red", fixture("verify_red"));
  assert.equal(own.headline, "P2 not verified: suite red on the verified tree");
  assert.match(own.why, /fast tier/); assert.doesNotMatch(own.why, /main's newer commits/);
  assert.equal(red.headline, "P2 not verified: suite red on the merged tree"); assert.match(red.why, /main's newer commits and P2 disagree/);
});

// ---- 90-fix-rounds.sh: the card after the fix rounds names each round and what it left red ----
test("fix rounds: the verify_red card with a rounds field names each round's id and what it left red and stays filled; without it the card reads as today", () => {
  const fx = { ...fixture("verify_red"), variant: "own" }, plain = N.card("verify_red", fx);
  const rounds = [{ id: "P2-fix1", round: 1, failed_after: ["t3"] }, { id: "P2-fix2", round: 2, failed_after: ["t3", "a check (x)", "t5", "t6"] }];
  const c = N.card("verify_red", { ...fx, rounds }), s = N.card("verify_red", { ...fx, rounds: JSON.stringify(rounds) });   // the shell passes JSON text
  assert.equal(c.why, `${plain.why} 2 fix rounds ran first (MAX_FIX_ROUNDS, verify in lib/lane.sh): P2-fix1 left t3 red, P2-fix2 left t3, a check (x), t5 +1 red.`);
  assert.equal(s.why, c.why);
  // 59-needs-cards.sh's FILLED rule on the why: 2 to 4 sentences, nothing undefined; nothing else of the card moves
  const sentences = w => [...w.matchAll(/[.!?](\s|$)/g)].length;
  assert.deepEqual([sentences(plain.why), sentences(c.why)], [2, 3]);
  assert.doesNotMatch(JSON.stringify(c), /undefined|NaN|\[object/);
  assert.deepEqual({ ...c, why: plain.why }, plain);
  // one round on the merged-tree variant, a round with no verdict, a round that left nothing: said as they are
  const one = N.card("verify_red", { ...fixture("verify_red"), rounds: [{ id: "P2-fix1", failed_after: null }, { id: "P2-fix2", failed_after: [] }] });
  assert.match(one.why, /disagree\. 2 fix rounds ran first \(MAX_FIX_ROUNDS, verify in lib\/lane\.sh\): P2-fix1 had no suite verdict, P2-fix2 left nothing red\.$/);
  assert.match(N.card("verify_red", { ...fx, rounds: [{ id: "P2-fix1", failed_after: ["t1"] }] }).why, / 1 fix round ran first \(MAX_FIX_ROUNDS, verify in lib\/lane\.sh\): P2-fix1 left t1 red\.$/);
  // no rounds, an empty list or text that is no JSON: today's card
  for (const r of [undefined, "", "[]", [], "{not json"]) assert.equal(N.card("verify_red", { ...fx, rounds: r }).why, plain.why);
});
