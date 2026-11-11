// lib/summary.mjs: a run's cause and rework read from its log, and the report's memory peaks.   node --test tests/unit/summary.test.mjs
import { test } from "node:test";
import assert from "node:assert/strict";
import { cpSync, existsSync, mkdtempSync, mkdirSync, readFileSync, writeFileSync, rmSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { fileURLToPath } from "node:url";
import { answerRow } from "../../lib/memory.mjs";
import { sameAsCli, mainOf } from "./cli-same.mjs";
import { parseRunLog, redSuite, redUnpass, failedRecheck, build, report, reviewSummary, laneSpans, conflicts, resolutions, suiteRuns, suiteRunsLine, flakers, flakes, fixRounds, fixRoundsLine, helperHealth, helperLine, helperNote, checksDiff, checksLine, memoryState, memoryView, memoryShown, memoryLine, memoryOverride, graduation } from "../../lib/summary.mjs";

const fixture = () => JSON.parse(readFileSync(fileURLToPath(new URL("../fixtures/summary-report.json", import.meta.url)), "utf8"));
// <summary> <prefix> → the report's first line starting with it, and its index
const rowOf = (s, p) => { const ls = report(s).split("\n"), i = ls.findIndex(l => l.startsWith(p)); return { i, row: ls[i] }; };

test("summary.mjs: the fast gate's un-pass note reads as a red suite, beside the older note (T2-02)", () => {
  const h = "- 2026-11-04 04:38 · A un-passed: fast tier red after the session\n- 2026-10-21 12:00 · B un-passed: suite red after the session\n- 2026-11-04 04:39 · C · opus · passes=true\n";
  assert.equal(redSuite(h, "A"), true);
  assert.equal(redSuite(h, "B"), true);
  assert.equal(redSuite(h, "C"), false);
  assert.equal((h.match(new RegExp(redUnpass.source, "g")) || []).length, 2);
});

test("summary.mjs: cause and rework read the log by exact id (E1 review)", () => {
  const h = "- 2026-10-21 12:00 · 11 un-passed: suite red after the session\n- 2026-10-21 12:05 · verify M1: A failed the re-check, back in the queue\n";
  assert.equal(redSuite(h, "1"), false);
  assert.equal(redSuite(h, "11"), true);
  assert.equal(redSuite(h, "c++"), false);
  assert.equal(redSuite(h, "auth(x"), false);
  assert.equal(failedRecheck(h, "A"), true);
  assert.equal(failedRecheck(h, "c++"), false);
  assert.equal(failedRecheck(h, "1"), false);
});

// Run 9c: refused sessions in an earlier segment aren't the cause of a later ending. tests/fixtures/summary-stale/ is the
// record and state a stub run left (STUB_LIMIT_HITS=6, then `harness continue --until-epoch <a minute ago>`), captured
// 2026-11-06: limit/ after the start, deadline/ after the continue. A stub run of its own file until the trim
// (decisions/2026-11-03-trim).
const staleBuild = name => {
  const d = mkdtempSync(join(tmpdir(), "st-")), rec = join(d, "wt/.harness/runs/stale"), st = join(d, "state");
  const fx = f => fileURLToPath(new URL(`../fixtures/summary-stale/${name}/${f}`, import.meta.url));
  try {
    mkdirSync(rec, { recursive: true }); mkdirSync(st);
    for (const f of ["feature_list.json", "metrics.jsonl", "harness-log.md"]) cpSync(fx(f), join(rec, f));
    for (const f of ["run.log", "attempts.json", "max-attempts", "ended"]) cpSync(fx(f), join(st, f));
    return build(join(d, "wt"), "stale", st);
  } finally { rmSync(d, { recursive: true, force: true }); }
};

test("a limit ending: the cause is the usage limit", () => {
  const s = staleBuild("limit");
  assert.equal(s.end_reason, "usage limit (6 sessions refused in a row)");
  assert.equal(s.features_detail[0].cause, "usage limit");
});

test("a later deadline: the earlier refusals aren't the cause", () => {
  const s = staleBuild("deadline");
  assert.equal(s.end_reason, "deadline");
  assert.equal(s.features_detail[0].cause, "not reached");
});

test("summary.mjs: report lists only the sessions over 2 GB", () => {
  const s = build("/nonexistent/p/w", "r", "/nonexistent/s"), keys = JSON.stringify(Object.keys(s));
  const rows = [{ kind: "coding", feature: "A", model: "opus", mem_peak_mb: 1500 }, { kind: "coding", feature: "B", model: "sonnet", mem_peak_mb: 2500 },
    { kind: "init", role: "init", feature: null, model: "opus", mem_peak_mb: null }];
  const R = report(s, rows), none = report(s, rows.slice(0, 1)) + report(s);
  assert.match(R, /\n### Memory peaks over 2 GB\n\n- B · sonnet · 2500 MB/);
  assert.doesNotMatch(R, /1500/);
  assert.doesNotMatch(none, /Memory peaks/);
  assert.equal(JSON.stringify(Object.keys(build("/nonexistent/p/w", "r", "/nonexistent/s"))), keys);
  assert.doesNotMatch(keys, /mem|peak_mb/);
});

test("review gate: reviewSummary gives the review share with one decimal, null without reviews, and counts the reviews that found nothing", () => {
  const list = [{ id: "A", kind: "build" }, { id: "R", kind: "review" }, { id: "S", kind: "review" }, { id: "Q", kind: "review" }];
  const ents = [{ feature: "R", summary: "R: 1 Critical, 0 Important" }, null, { feature: "R", summary: "R: 0 Critical, 0 Important" },
    { feature: "S", summary: "S: 0 Critical, 2 Important" }, { feature: "A", summary: "0 Critical, 0 Important" }];
  const a = reviewSummary(list, [{ role: "build", cost_usd: 2 }, { role: "review", cost_usd: 1 }], ents);
  const b = reviewSummary(list.slice(0, 1), [{ role: "build", cost_usd: 2 }], []);
  const z = reviewSummary(list, [{ role: "review", cost_usd: 0 }], ents);
  assert.equal(a.cost_pct, 33.3);
  assert.equal(a.found_nothing, 0);
  assert.equal(a.reviews, 2);
  assert.equal(b.cost_pct, null);
  assert.equal(b.found_nothing, 0);
  assert.equal(b.reviews, 0);
  assert.equal(z.cost_pct, null);
});

test("reviewSummary: a review counts as finding nothing only when every entry that gives counts reports 0 Critical, 0 Important", () => {
  const list = [{ id: "R", kind: "review" }, { id: "S", kind: "review" }, { id: "Q", kind: "review" }];
  const a = reviewSummary(list, [{ role: "review", cost_usd: 1 }], [{ feature: "R", summary: "R: 1 Critical, 0 Important" }, { feature: "R", summary: "R: 0 Critical, 0 Important" },
    { feature: "S", summary: "S: 0 Critical, 0 Important" }, { feature: "S", summary: "S: not done" }, { feature: "Q", summary: "Q: no counts" }]);
  const b = reviewSummary(list, [], [{ feature: "R", summary: "R: 0 Critical, 0 Important" }, { feature: "R", summary: "R: done" }]);
  assert.equal(a.found_nothing, 1);
  assert.equal(a.reviews, 3);
  assert.equal(b.found_nothing, 1);
  assert.equal(b.reviews, 1);
});

test("lanes summary: laneSpans counts the lanes open at once and sums open-to-close hours, a lane left open closing at its segment's end", () => {
  const log = ["2026-10-27 10:00:00 run r on proj", "2026-10-27 10:00:00 lane M1 opened (slot 0, port 1, from a)", "2026-10-27 10:30:00 lane M2 opened (slot 1, port 2, from a)",
    "2026-10-27 11:00:00 lane M1 closed (x)", "2026-10-27 11:30:00 lane M2 closed (x)", "2026-10-27 11:30:00 lane M3 opened (slot 0, port 1, from a)", "2026-10-27 12:00:00 verify M3 · m",
    "2026-10-27 13:00:00 run r on proj", "2026-10-27 13:00:00 lane M3 opened (slot 0, port 1, from a)", "2026-10-27 13:30:00 lane M3 closed (x)"].map(l => l + "\n").join("");
  const got = laneSpans(log);
  assert.deepEqual(got, { max_open: 2, lane_hours: 3 });
  assert.equal(Object.keys(got).join(), "max_open,lane_hours");
  assert.deepEqual(laneSpans(""), { max_open: 0, lane_hours: 0 });
});

test("summary.mjs: flakes counts a fast flake with no names as the fast tier, a full one as whole suite", () => {
  assert.deepEqual(flakes([{ names: [], tier: "fast" }, { names: [] }, { names: ["a"], tier: "fast" }]),
    { count: 3, names: { "the fast tier": 1, "whole suite": 1, a: 1 } });
});

test("summary.mjs: flakes counts flakes.jsonl's rows by name (whole suite for no names); every fixture key still built", () => {
  const d = mkdtempSync(join(tmpdir(), "u1-"));
  try {
    mkdirSync(join(d, "green"));
    writeFileSync(join(d, "green", "flakes.jsonl"), ['{"names":["a","b"]}', "not json", "null", "[1]", '{"names":[]}', '{"names":["a"]}'].map(l => l + "\n").join(""));
    const fx = Object.keys(fixture()), s = build("/nonexistent/p/w", "r", d), none = build("/nonexistent/p/w", "r", "/nonexistent/s");
    assert.deepEqual(s.flakes, { count: 3, names: { a: 2, b: 1, "whole suite": 1 } });
    assert.equal(Object.keys(s.flakes).join(), "count,names");
    assert.equal(Object.keys(s.flakes.names).join(), "a,b,whole suite");
    assert.deepEqual(none.flakes, { count: 0, names: {} });
    assert.deepEqual(fx.filter(k => !(k in none)), []);
    assert.equal("flakes" in none, true);
    assert.equal(fx.includes("flakes"), false);
  } finally { rmSync(d, { recursive: true, force: true }); }
});

test("report: the Flakes row after Tests (n · name ×k), 0 for none, none for an older summary", () => {
  const fx = fixture(), after = s => { const { i } = rowOf(s, "| Tests | "); return report(s).split("\n")[i + 1]; };
  assert.equal(after({ ...fx, flakes: { count: 3, names: { "lanes-record-lock": 1, "merge-legacy-record": 2 } } }), "| Flakes | 3 · merge-legacy-record ×2, lanes-record-lock |");
  assert.equal(after({ ...fx, flakes: { count: 0, names: {} } }), "| Flakes | 0 |");
  assert.doesNotMatch(report(fx), /Flakes/);
});

test("summary.mjs: flakers names a check in the flakes of two or more of the five newest summaries (one without ended_at oldest) as name ×runs, (none) for none", () => {
  const s = (d, n) => ({ ended_at: d, flakes: { count: 1, names: n } }), old = s(undefined, { o: 1 });
  assert.deepEqual(flakers([old, s("2026-10-01", { o: 1, p: 1 }), s("2026-10-02", { p: 1, q: 1 }), s("2026-10-03", { q: 2 }), {}, s("2026-10-05", {}), s("2026-10-06", { q: 1 })]),
    ["q ×3", "p ×2"]);
  assert.deepEqual(flakers([{}]), ["(none)"]);
});

test("summary.mjs: conflicts counts resolutions, distinct escalated milestones and resolve rows; resolutions names the files; the Conflicts row after Flakes", () => {
  const fx = fixture();
  const log = ["- 2026-10-29 01:00 · M2: main merged in by a resolve session (a.txt, b c.txt; claude-opus-5-5, 3 min); one verify round follows",
    "- 2026-10-29 01:10 · M3: main merged in by a resolve session (d.txt; opus, 0 min); the verify goes on with main merged",
    "- 2026-10-29 01:20 · M4 conflicts with main; not merged (needs Michael)", "- 2026-10-29 01:30 · M4 conflicts with main; not merged (needs Michael)",
    "- 2026-10-29 01:40 · main conflicts with harness-lane/r/M5; carrying on without it (merges into main need Michael)",
    "- 2026-10-29 01:50 · main conflicts with harness/r; carrying on without it (merges into main need Michael)"].join("\n");
  const c = conflicts(log, [{ kind: "resolve" }, { kind: "resolve", env: true }, { kind: "coding" }]), rs = resolutions(log);
  assert.deepEqual(c, { resolved: 2, escalated: 2, sessions: 2 });
  assert.equal(Object.keys(c).join(), "resolved,escalated,sessions");
  assert.deepEqual(rs, [{ milestone: "M2", files: "a.txt, b c.txt" }, { milestone: "M3", files: "d.txt" }]);
  assert.equal(rs.map(r => Object.keys(r).join()).join(" "), "milestone,files milestone,files");
  assert.equal(rowOf({ ...fx, conflicts: c, resolutions: rs }, "| Conflicts | ").row, "| Conflicts | 2 resolved by sessions (M2: a.txt, b c.txt; M3: d.txt), 2 to Michael |");
  assert.equal(rowOf({ ...fx, conflicts: conflicts("", []), resolutions: [] }, "| Conflicts | ").row, "| Conflicts | 0 resolved, 0 to Michael |");
  assert.equal(rowOf(fx, "| Conflicts | ").row, undefined);
  const flakes = { count: 0, names: {} };
  assert.equal(rowOf({ ...fx, flakes, suite_runs: undefined, conflicts: c, resolutions: rs }, "| Conflicts | ").i, rowOf({ ...fx, flakes }, "| Flakes | ").i + 1);
  // the fixture's Suite runs row (T2-03) sits between them
  assert.equal(rowOf({ ...fx, flakes, conflicts: c, resolutions: rs }, "| Conflicts | ").i, rowOf({ ...fx, flakes }, "| Suite runs | ").i + 1);
});

test("summary.mjs: suiteRuns counts the coding rows that carry suite_full, full and fast apart; the Suite runs row after Flakes, 0 for none, none for an older summary", () => {
  const c = (f, r, k, e = false) => ({ kind: "coding", feature: "X", env: e, suite_full: f, suite_runs: r, ...(k == null ? {} : { suite_fast: k }) });
  const fx = { run: "r", project: "p", features: { passing: 0, total: 0, verified: 0, merged: 0 }, milestones: [], tests: {},
    flakes: { count: 0, names: {} }, cost: { by_role: {} }, time: { by_role_h: {} }, sessions: {}, features_detail: [] };
  // <summary> <row> → the line before the row (undefined when the row is missing or first)
  const before = (s, row) => { const l = report(s).split("\n"), i = l.indexOf(row); return i > 0 ? l[i - 1] : undefined; };
  // a row from before T2-03 has no suite_fast: it counts 0 fast
  const all = suiteRuns([c(2, 3, 0), c(0, 0), c(1, 4, 2), { kind: "coding" }, { kind: "verify", suite_full: 9, suite_fast: 9 }, c(5, 5, 5, true)]);
  assert.deepEqual(all, { sessions: 3, full: 3, fast: 2, runs: 7, full_per_session: 1, fast_per_session: 0.7 });
  assert.equal(Object.keys(all).join(), "sessions,full,fast,runs,full_per_session,fast_per_session");
  assert.deepEqual(suiteRuns([c(2, 3, 1)]), { sessions: 1, full: 2, fast: 1, runs: 3, full_per_session: 2, fast_per_session: 1 });
  assert.equal(suiteRuns([c(1, 1, 0), c(1, 1, 0), c(0, 2, 1)]).full_per_session, 0.7);
  assert.deepEqual(suiteRuns([{ kind: "init" }]), { sessions: 0, full: 0, fast: 0, runs: 0, full_per_session: 0, fast_per_session: 0 });
  // the spec's example: 2 full and 16 fast calls in 10 sessions, 20 runs with the subsets
  const ten = suiteRuns([c(2, 4, 0), ...Array.from({ length: 8 }, () => c(0, 2, 2)), c(0, 0, 0)]);
  assert.deepEqual(ten, { sessions: 10, full: 2, fast: 16, runs: 20, full_per_session: 0.2, fast_per_session: 1.6 });
  assert.equal(suiteRunsLine(ten), "0.2 full and 1.6 fast per coding session (2 full, 16 fast in 10; 20 runs in all)");
  assert.match(before({ ...fx, suite_runs: suiteRuns([c(2, 3, 0)]) }, "| Suite runs | 2 full and 0 fast per coding session (2 full, 0 fast in 1; 3 runs in all) |"), /^\| Flakes \|/);
  assert.match(before({ ...fx, suite_runs: suiteRuns([]) }, "| Suite runs | 0 |"), /^\| Flakes \|/);
  // a summary.json from before T2-03: no fast, read as 0
  assert.equal(suiteRunsLine({ sessions: 1, full: 2, runs: 3, full_per_session: 2 }), "2 full and 0 fast per coding session (2 full, 0 fast in 1; 3 runs in all)");
  assert.doesNotMatch(report(fx), /Suite runs/);
});

// ---- fix rounds (decisions/2026-11-04-fix-rounds): the rows counted, the report's row ----
const fxo = (m, r) => ({ kind: "fix_round", run: "r", milestone: m, round: r, issue: "all", feature: `${m}-fix${r}`, failed_before: ["t1"], files_before: ["t1"] });
const fxr = (m, r, after) => ({ kind: "fix_result", run: "r", milestone: m, round: r, issue: "all", failed_after: after, fixed: after.length === 0 });

test("fix rounds: a fix feature's un-pass note (check <files> red) reads as a red suite, beside the fast tier's and the older note", () => {
  const h = "- 2026-11-04 04:38 · M1-fix1 un-passed: check fix-rounds needs-cards red after the session\n- 2026-11-04 04:39 · A un-passed: fast tier red after the session\n"
    + "- 2026-11-04 04:40 · M1-fix2 un-passed: suite red after the session\n- 2026-11-04 04:41 · B · opus · passes=true · checked: nothing un-passed here\n";
  assert.deepEqual(["M1-fix1", "A", "M1-fix2", "B", "M1-fix"].map(id => redSuite(h, id)), [true, true, true, false, false]);
  assert.equal((h.match(new RegExp(redUnpass.source, "g")) || []).length, 3);
});

test("fix rounds: fixRounds pairs each fix_result to its fix_round by milestone and round, per milestone in order", () => {
  assert.deepEqual(fixRounds([]), { opened: 0, fixed: 0, by_milestone: {} });
  const rows = [{ kind: "coding", feature: "A" }, fxo("M1", 1), fxr("M1", 1, []), fxo("M2", 1), fxr("M2", 1, ["t3"])];
  assert.deepEqual(fixRounds(rows), { opened: 2, fixed: 1, by_milestone: { M1: { opened: 1, fixed: 1 }, M2: { opened: 1, fixed: 0 } } });
  // round 2's green is no verdict on round 1; an open round (no result yet) is opened, not fixed; a result with no round counts nothing
  const two = [fxo("M1", 1), fxr("M1", 1, ["t3"]), fxo("M1", 2), fxr("M1", 2, []), fxo("M2", 1), fxr("M3", 1, [])];
  assert.deepEqual(fixRounds(two), { opened: 3, fixed: 1, by_milestone: { M1: { opened: 2, fixed: 1 }, M2: { opened: 1, fixed: 0 } } });
  assert.equal(Object.keys(fixRounds(two).by_milestone).join(), "M1,M2");
});

test("fix rounds: the report's Fix rounds row comes after Flakes (opened · fixed, per milestone), 0 for none, no row for a summary without the key", () => {
  const fx = { ...fixture(), flakes: { count: 0, names: {} } }, after = s => { const { i } = rowOf(s, "| Flakes | "); return report(s).split("\n")[i + 1]; };
  const fr = fixRounds([fxo("M1", 1), fxr("M1", 1, []), fxo("M2", 1), fxr("M2", 1, ["t3"])]);
  assert.equal(fixRoundsLine(fr), "2 opened · 1 fixed (M1 1 of 1, M2 0 of 1)");
  assert.equal(after({ ...fx, fix_rounds: fr }), "| Fix rounds | 2 opened · 1 fixed (M1 1 of 1, M2 0 of 1) |");
  assert.equal(after({ ...fx, fix_rounds: fixRounds([]) }), "| Fix rounds | 0 |");
  assert.equal(after({ ...fx, fix_rounds: fixRounds([fxo("M1", 1), fxr("M1", 1, ["t3"]), fxo("M1", 2), fxr("M1", 2, ["t3"])]) }), "| Fix rounds | 2 opened · 0 fixed (M1 0 of 2) |");
  assert.doesNotMatch(report(fx), /Fix rounds/);
  assert.match(after(fx), /^\| Suite runs \|/);   // as before, for a summary from before fix rounds
});

test("fix rounds: build adds fix_rounds from metrics.jsonl and counts neither row as a session, a role or a cost; Spend by role lists fix", () => {
  const d = mkdtempSync(join(tmpdir(), "fxs-")), wt = join(d, "p", "w"), rec = join(wt, ".harness/runs/r"), st = join(d, "state");
  try {
    mkdirSync(rec, { recursive: true }); mkdirSync(st);
    writeFileSync(join(rec, "feature_list.json"), JSON.stringify({ features: [{ id: "A", milestone: "M1", kind: "build", passes: true },
      { id: "M1-fix1", milestone: "M1", kind: "fix", passes: true }] }));
    writeFileSync(join(rec, "metrics.jsonl"), [{ kind: "coding", role: "build", feature: "A", model: "opus", passes: true, cost_usd: 1, turns: 12, wall_s: 60 }, fxo("M1", 1),
      { kind: "coding", role: "fix", feature: "M1-fix1", model: "opus", passes: true, cost_usd: 0.5, turns: 12, wall_s: 60 }, fxr("M1", 1, [])].map(r => JSON.stringify(r) + "\n").join(""));
    const s = build(wt, "r", st);
    assert.deepEqual(s.fix_rounds, { opened: 1, fixed: 1, by_milestone: { M1: { opened: 1, fixed: 1 } } });
    assert.deepEqual([s.sessions.total, s.cost.by_role, s.cost.by_model, Object.keys(s.time.by_role_h)], [2, { build: 1, fix: 0.5 }, { opus: 1.5 }, ["build", "fix"]]);
    assert.equal(s.features_detail[1].kind, "fix");
    assert.equal(rowOf(s, "| Spend by role | ").row, "| Spend by role | build $1.00 · fix $0.50 · manager (the bash driver) $0.00 |");
    assert.equal(rowOf(s, "| Fix rounds | ").row, "| Fix rounds | 1 opened · 1 fixed (M1 1 of 1) |");
    assert.deepEqual(build("/nonexistent/p/w", "r", "/nonexistent/s").fix_rounds, { opened: 0, fixed: 0, by_milestone: {} });
  } finally { rmSync(d, { recursive: true, force: true }); }
});

// ---- the resident helpers' health in the record (decisions/2026-11-03-resident-helper, updated 2026-11-05) ----
const hlines = (...ls) => ls.map((l, i) => `2026-11-05 10:00:${String(i).padStart(2, "0")} ${l}\n`).join("");
test("helper health: helperHealth counts run.log's helper restarted: and helper off: lines and each distinct reason, zeros for none", () => {
  assert.deepEqual(helperHealth(""), { restarts: 0, off: 0, whys: {} });
  const log = hlines("run r on harness/r in /w · port 1", "helper restarted: the helper went away", "session 1 · A · opus", "helper restarted: no reply in 120 s",
    "helper restarted: the helper went away", "helper off: wrong id: 5 for 7", "  a session said helper restarted: not the driver's line", "run r on harness/r in /w · port 1", "helper restarted: the helper went away")
    + "helper off: no stamp, no line\n";
  const got = helperHealth(log);
  assert.deepEqual(got, { restarts: 4, off: 1, whys: { "the helper went away": 3, "no reply in 120 s": 1, "wrong id: 5 for 7": 1 } });
  assert.equal(Object.keys(got).join(), "restarts,off,whys");
  assert.equal(Object.keys(got.whys).join("|"), "the helper went away|no reply in 120 s|wrong id: 5 for 7");
  // the driver's own note about them is no such line
  assert.deepEqual(helperHealth(hlines("helper: 1 restarted, 0 off in this segment (first: the helper went away); see run.log")), { restarts: 0, off: 0, whys: {} });
});

test("helper health: helperNote is the last segment's count and first reason with see run.log, nothing for a segment with none; the CLI's helper-note prints it", async () => {
  assert.equal(helperNote(""), "");
  assert.equal(helperNote(hlines("run r on harness/r in /w", "session 1 · A · opus")), "");
  assert.equal(helperNote(hlines("run r on harness/r in /w", "helper restarted: no reply in 120 s", "helper restarted: the helper went away", "helper off: bad header: x")),
    "helper: 2 restarted, 1 off in this segment (first: no reply in 120 s); see run.log");
  // an earlier segment's are that segment's: said at its end, or not at all
  const two = hlines("run r on harness/r in /w", "helper restarted: no reply in 120 s", "run r on harness/r in /w", "session 3 · B · opus");
  assert.equal(helperNote(two), "");
  assert.equal(helperNote(two + hlines("helper off: the helper went away")), "helper: 0 restarted, 1 off in this segment (first: the helper went away); see run.log");
  assert.equal(helperNote(hlines("helper restarted: a log with no start line")), "helper: 1 restarted, 0 off in this segment (first: a log with no start line); see run.log");
  const d = mkdtempSync(join(tmpdir(), "hn-"));
  try {
    writeFileSync(join(d, "run.log"), two + hlines("helper restarted: the helper went away"));
    writeFileSync(join(d, "quiet.log"), two);
    assert.equal((await sameAsCli("summary.mjs", ["helper-note", join(d, "run.log")])).out, "helper: 1 restarted, 0 off in this segment (first: the helper went away); see run.log\n");
    assert.deepEqual(await sameAsCli("summary.mjs", ["helper-note", join(d, "quiet.log")]), { rc: 0, out: "" });
    assert.deepEqual(await sameAsCli("summary.mjs", ["helper-note", join(d, "none.log")]), { rc: 0, out: "" });
  } finally { rmSync(d, { recursive: true, force: true }); }
});

test("helper health: the report's Helper row comes before Sessions (0 restarts, or the counts and the reasons, most first), no row for a summary without the key", () => {
  const fx = fixture(), before = s => { const { i } = rowOf(s, "| Sessions | "); return report(s).split("\n")[i - 1]; };
  assert.equal(helperLine({ restarts: 0, off: 0, whys: {} }), "0 restarts");
  assert.equal(helperLine({ restarts: 1, off: 0, whys: { "the helper went away": 1 } }), "1 restart · 0 off (the helper went away)");
  assert.equal(before({ ...fx, helper: { restarts: 0, off: 0, whys: {} } }), "| Helper | 0 restarts |");
  assert.equal(before({ ...fx, helper: { restarts: 3, off: 1, whys: { "no reply in 120 s": 1, "the helper went away": 3 } } }),
    "| Helper | 3 restarts · 1 off (the helper went away ×3, no reply in 120 s) |");
  // a reason is a helper's bytes (a bad header's first 60): a | stays in its cell
  assert.equal(before({ ...fx, helper: { restarts: 1, off: 0, whys: { "bad header: a|b": 1 } } }), "| Helper | 1 restart · 0 off (bad header: a\\|b) |");
  assert.equal(before({ ...fx, lanes: { max_open: 2, lane_hours: 1, wall_hours: 1 }, helper: { restarts: 0, off: 0, whys: {} } }), "| Helper | 0 restarts |");
  assert.doesNotMatch(report(fx), /Helper/);
  assert.match(before(fx), /^\| Time \|/);   // as before, for a summary from before this
});

test("helper health: build adds helper from the state dir's run.log, every segment's; zeros for a run with none or no log", () => {
  const d = mkdtempSync(join(tmpdir(), "hh-"));
  try {
    writeFileSync(join(d, "run.log"), hlines("run r on harness/r in /w", "helper restarted: the helper went away", "run r on harness/r in /w", "helper off: no reply in 120 s"));
    const s = build("/nonexistent/p/w", "r", d);
    assert.deepEqual(s.helper, { restarts: 1, off: 1, whys: { "the helper went away": 1, "no reply in 120 s": 1 } });
    assert.equal(rowOf(s, "| Helper | ").row, "| Helper | 1 restart · 1 off (no reply in 120 s, the helper went away) |");
    writeFileSync(join(d, "run.log"), hlines("run r on harness/r in /w", "session 1 · A · opus"));
    assert.deepEqual(build("/nonexistent/p/w", "r", d).helper, { restarts: 0, off: 0, whys: {} });
    assert.deepEqual(build("/nonexistent/p/w", "r", "/nonexistent/s").helper, { restarts: 0, off: 0, whys: {} });
    assert.equal(Object.keys(fixture()).includes("helper"), false);
  } finally { rmSync(d, { recursive: true, force: true }); }
});

// ---- main(argv, io): the CLI's bytes and exit code; the view from io (decisions/2026-11-03-resident-helper) ----
test("summary.mjs: main gives the CLI's bytes for report --md, suite-runs, ledger-line's file, trends, flakers and calibration", async () => {
  const d = mkdtempSync(join(tmpdir(), "sm-"));
  try {
    const s = fileURLToPath(new URL("../fixtures/summary-report.json", import.meta.url));
    assert.ok((await sameAsCli("summary.mjs", ["report", "--md", s])).out.length > 0);
    await sameAsCli("summary.mjs", ["report", s]);
    await sameAsCli("summary.mjs", ["suite-runs", s]);
    const c = join(d, "c.jsonl"), m = join(d, "m.jsonl");
    assert.deepEqual(await mainOf("summary.mjs", ["ledger-line", s, m], { cwd: d }), { rc: 0, out: "" });
    await sameAsCli("summary.mjs", ["ledger-line", s, c]);
    assert.equal(readFileSync(m, "utf8"), readFileSync(c, "utf8"));
    assert.ok((await sameAsCli("summary.mjs", ["trends", c])).out.startsWith("| Run |"));
    await sameAsCli("summary.mjs", ["trends", c, "--by", "version"]);
    await sameAsCli("summary.mjs", ["flakers", join(d, "none")]);
    await sameAsCli("summary.mjs", ["calibration", join(d, "none"), "p"]);
  } finally { rmSync(d, { recursive: true, force: true }); }
});

test("summary.mjs: main's view is the io's: isTTY and columns from io, never the process's stdout", async () => {
  const s = fileURLToPath(new URL("../fixtures/summary-report.json", import.meta.url));
  const { main } = await import("../../lib/summary.mjs");
  const env = { HARNESS_COLOR: "never", HARNESS_GLYPHS: "unicode" };
  const plain = main(["report", s], { env }), tty = main(["report", s], { env, isTTY: true, columns: 80 });
  assert.notEqual(tty.out, plain.out, "a TTY gets the view, a pipe the markdown");
  assert.equal(plain.out, main(["report", "--md", s], { env, isTTY: true, columns: 80 }).out);
});

test("summary.mjs: checksDiff counts the names a tip adds and removes against a base; a removed and an added name in one hunk of the sorted file pair as replaced; an order mismatch pairs nothing", () => {
  const base = "alpha: holds\ndelta: holds\nmid: holds\nzeta: holds\n";
  // two added, one removed, none beside another: nothing replaced (tests/checks/check-budget.sh's cb1)
  assert.deepEqual(checksDiff(base, "alpha: holds\nbeta: new\ndelta: holds\ngamma: new\nmid: holds\n"), { added: 2, replaced: 0, removed: 1 });
  // a name changed in place (−mid: holds, +mid: holds now, adjacent in the sorted file) is replaced, not added and removed (cb2)
  assert.deepEqual(checksDiff(base, "alpha: holds\nbeta: new\nbeta2: new\ndelta: holds\ngamma: new\ngamma2: new\nmid: holds now\nzeta: holds\n"), { added: 4, replaced: 1, removed: 0 });
  // a hunk of two removed and one added: one pair, one removed; the other way round: one pair, one added
  assert.deepEqual(checksDiff("a\nb\nc\nd\n", "a\nbb\nd\n"), { added: 0, replaced: 1, removed: 1 });
  assert.deepEqual(checksDiff("a\nb\nd\n", "a\nbb\nbc\nd\n"), { added: 1, replaced: 1, removed: 0 });
  // two hunks never pair across a common line
  assert.deepEqual(checksDiff("a\nb\nc\nd\n", "a\nc\ncc\nd\n"), { added: 1, replaced: 0, removed: 1 });
  assert.deepEqual(checksDiff(base, base), { added: 0, replaced: 0, removed: 0 });
  assert.deepEqual(checksDiff("", base), { added: 4, replaced: 0, removed: 0 });
  assert.deepEqual(checksDiff(base, ""), { added: 0, replaced: 0, removed: 4 });
  assert.deepEqual(checksDiff("", ""), { added: 0, replaced: 0, removed: 0 });
  // blank lines and a repeated line are not names: a name is counted once
  assert.deepEqual(checksDiff("a\n\nb\nb\n", "a\n\n\nb\nc\nc\n"), { added: 1, replaced: 0, removed: 0 });
  // the common names in another order (an unsorted fixture): the sets' counts, no pairing
  assert.deepEqual(checksDiff("a\nb\nc\n", "c\nbb\na\n"), { added: 1, replaced: 0, removed: 1 });
});

test("summary.mjs: checksLine prints +a ~b −c with each milestone and its budget (over marked), the suite's count for a project without the fixture, not counted for none; build sums the lanes' checks-<m> files, else the test counts; the Checks row after Suite runs, none for an older summary", async () => {
  const two = { added: 2, replaced: 0, removed: 1, source: "fixture", by_milestone: { M1: { added: 2, replaced: 0, removed: 1, budget: null }, M2: { added: 0, replaced: 0, removed: 0, budget: 3 } } };
  assert.equal(checksLine(two), "+2 ~0 −1 (M1 +2 ~0 −1; M2 +0 ~0 −0, budget 3)");
  assert.equal(checksLine({ added: 4, replaced: 1, removed: 0, source: "fixture", by_milestone: { M1: { added: 4, replaced: 1, removed: 0, budget: 3 } } }), "+4 ~1 −0 (M1 +4 ~1 −0, budget 3, over)");
  assert.equal(checksLine({ added: 3, replaced: 0, removed: 0, source: "fixture", by_milestone: { M1: { added: 3, replaced: 0, removed: 0, budget: 3 } } }), "+3 ~0 −0 (M1 +3 ~0 −0, budget 3)", "at the budget is not over");
  assert.equal(checksLine({ added: 2, source: "counts", from: 3, to: 5 }), "+2 (the suite's count, 3 → 5)");
  assert.equal(checksLine({ added: -1, source: "counts", from: 5, to: 4 }), "−1 (the suite's count, 5 → 4)");
  assert.equal(checksLine({ source: "none" }), "not counted");
  // build: the lanes' files, keyed by the list's milestones; a milestone without one counts nothing and has no row
  const d = mkdtempSync(join(tmpdir(), "u1-")), w = mkdtempSync(join(tmpdir(), "u1w-"));
  try {
    mkdirSync(join(w, ".harness", "runs", "r"), { recursive: true });
    writeFileSync(join(w, ".harness", "runs", "r", "feature_list.json"), JSON.stringify({ features: [{ id: "A", milestone: "M1", passes: true }, { id: "C", milestone: "M2", passes: false }] }));
    writeFileSync(join(d, "checks-M1"), '{"added":2,"replaced":0,"removed":1,"budget":null}\n');
    assert.deepEqual(build(w, "r", d).checks, { added: 2, replaced: 0, removed: 1, source: "fixture", by_milestone: { M1: { added: 2, replaced: 0, removed: 1, budget: null } } });
    writeFileSync(join(d, "checks-M2"), '{"added":0,"replaced":0,"removed":0,"budget":3}\n');
    assert.deepEqual(build(w, "r", d).checks, two);
    // no file: the suite's count, start → end; one of the two unknown: none
    for (const m of ["M1", "M2"]) rmSync(join(d, `checks-${m}`));
    writeFileSync(join(d, "tests-start"), "3\n"); writeFileSync(join(d, "tests-end"), "5\n");
    assert.deepEqual(build(w, "r", d).checks, { added: 2, source: "counts", from: 3, to: 5 });
    rmSync(join(d, "tests-end"));
    assert.deepEqual(build(w, "r", d).checks, { source: "none" });
  } finally { rmSync(d, { recursive: true, force: true }); rmSync(w, { recursive: true, force: true }); }
  const fx = { run: "r", project: "p", features: { passing: 0, total: 0, verified: 0, merged: 0 }, milestones: [], tests: {}, suite_runs: suiteRuns([]),
    flakes: { count: 0, names: {} }, cost: { by_role: {} }, time: { by_role_h: {} }, sessions: {}, features_detail: [] };
  const before = (s, row) => { const l = report(s).split("\n"), i = l.indexOf(row); return i > 0 ? l[i - 1] : undefined; };
  assert.match(before({ ...fx, checks: two }, "| Checks | +2 ~0 −1 (M1 +2 ~0 −1; M2 +0 ~0 −0, budget 3) |"), /^\| Suite runs \|/);
  assert.match(before({ ...fx, checks: { source: "none" } }, "| Checks | not counted |"), /^\| Suite runs \|/);
  assert.equal(report(fx).includes("| Checks |"), false, "a summary from before S3 has no row");
  // the retro prompt's {{CHECKS}} (lib/driver.sh): the same line from a summary.json; nothing for an older one
  const d2 = mkdtempSync(join(tmpdir(), "u1-"));
  try {
    writeFileSync(join(d2, "s.json"), JSON.stringify({ ...fx, checks: two })); writeFileSync(join(d2, "old.json"), JSON.stringify(fx));
    assert.deepEqual(await sameAsCli("summary.mjs", ["checks", join(d2, "s.json")]), { rc: 0, out: "+2 ~0 −1 (M1 +2 ~0 −1; M2 +0 ~0 −0, budget 3)\n" });
    assert.deepEqual(await sameAsCli("summary.mjs", ["checks", join(d2, "old.json")]), { rc: 0, out: "" });
    // checks-diff <base> <tip>: the lane's call, one JSON line
    writeFileSync(join(d2, "b.txt"), "a\nb\nc\nd\n"); writeFileSync(join(d2, "t.txt"), "a\nbb\nd\n");
    assert.deepEqual(await sameAsCli("summary.mjs", ["checks-diff", join(d2, "b.txt"), join(d2, "t.txt")]), { rc: 0, out: '{"added":0,"replaced":1,"removed":1}\n' });
  } finally { rmSync(d2, { recursive: true, force: true }); }
});

// ---- the curator (M2-03): its own session and role, after the retro ----
test("summary.mjs: the curator session counts under its own role in cost by role", () => {
  const log = ["2026-11-07 10:00:00 run r on harness/r in /w · port 7800", "2026-11-07 10:01:00 retro · sonnet", "2026-11-07 10:03:00   retro exit 0 · abc x",
    "2026-11-07 10:03:10 curator · opus", "2026-11-07 10:05:10   curator exit 0 · abc x"].join("\n");
  const { sessions } = parseRunLog(log);
  assert.equal(JSON.stringify(sessions.map(s => [s.kind, s.feature, s.wall])), JSON.stringify([["retro", null, 120], ["curator", null, 120]]));
  const d = mkdtempSync(join(tmpdir(), "cur-")), wt = join(d, "p", "w"), rec = join(wt, ".harness/runs/r"), st = join(d, "state");
  try {
    mkdirSync(rec, { recursive: true }); mkdirSync(st);
    writeFileSync(join(rec, "feature_list.json"), JSON.stringify({ features: [{ id: "A", milestone: "M1", kind: "build", passes: true }] }));
    writeFileSync(join(rec, "metrics.jsonl"), [{ kind: "retro", role: "retro", feature: null, model: "sonnet", passes: true, cost_usd: 0.2, turns: 12 },
      { kind: "curator", role: "curator", feature: null, model: "opus", passes: true, cost_usd: 0.1, turns: 12 }].map(r => JSON.stringify(r) + "\n").join(""));
    writeFileSync(join(st, "run.log"), log + "\n");
    const s = build(wt, "r", st);
    assert.equal(JSON.stringify([s.sessions.total, s.cost.by_role, Object.keys(s.time.by_role_h)]), JSON.stringify([2, { retro: 0.2, curator: 0.1 }, ["retro", "curator"]]));
    assert.equal(rowOf(s, "| Spend by role | ").row, "| Spend by role | retro $0.20 · curator $0.10 · manager (the bash driver) $0.00 |");
  } finally { rmSync(d, { recursive: true, force: true }); }
});

// ---- the curator's acceptance counted (M3-03, decisions/2026-11-07-memory-policy) ----
const memFx = () => ({ run: "r", project: "p", features: { passing: 0, total: 0, verified: 0, merged: 0 }, milestones: [], tests: {},
  cost: { by_role: {} }, time: { by_role_h: {} }, sessions: {}, features_detail: [] });
// gh pr view <url> --json state,mergedAt,commits (tests/fixtures/gh-pr-view-commits.json), its headlines <hs>
const ghPr = (state, ...hs) => {
  const fx = JSON.parse(readFileSync(fileURLToPath(new URL("../fixtures/gh-pr-view-commits.json", import.meta.url)), "utf8"));
  return { ...fx, state, mergedAt: state === "MERGED" ? "2026-11-07T14:00:00Z" : null, commits: hs.map(h => ({ ...fx.commits[0], messageHeadline: h })) };
};

test("summary.mjs memory: build reads memory.json's keys, the rules PR's among them, none with no file", () => {
  const d = mkdtempSync(join(tmpdir(), "mem-"));
  try {
    assert.equal("memory" in build("/nonexistent/p/w", "r", d), false);
    writeFileSync(join(d, "memory.json"), '{"ops":3,"applied":2,"dropped":0,"proposed":1,"pr":"https://example.test/pr/4","rules":1,"rules_pr":"https://example.test/pr/5","sections":{"facts":["## Gotchas"],"rules":["## Code rules"]}}\n');
    assert.equal(JSON.stringify(build("/nonexistent/p/w", "r", d).memory), '{"ops":3,"applied":2,"dropped":0,"proposed":1,"pr":"https://example.test/pr/4","rules":1,"rules_pr":"https://example.test/pr/5","sections":{"facts":["## Gotchas"],"rules":["## Code rules"]}}');
    // a memory.json before N1-01 (no rules key) reads as no rules PR
    // invalid is left out; a file that is no object is none
    writeFileSync(join(d, "memory.json"), '{"ops":0,"applied":0,"dropped":0,"proposed":0,"pr":null,"invalid":"not an array"}\n');
    assert.equal(JSON.stringify(build("/nonexistent/p/w", "r", d).memory), '{"ops":0,"applied":0,"dropped":0,"proposed":0,"pr":null,"rules":0,"rules_pr":null,"sections":{"facts":[],"rules":[]}}');
    writeFileSync(join(d, "memory.json"), "{half");
    assert.equal("memory" in build("/nonexistent/p/w", "r", d), false);
  } finally { rmSync(d, { recursive: true, force: true }); }
});

test("summary.mjs memory: report prints the Memory row, zeros and PR none for a curator that wrote nothing", () => {
  const mem = { ops: 4, applied: 2, dropped: 0, proposed: 1, pr: "https://example.test/pr/4", rules: 1, rules_pr: "https://example.test/pr/5" };
  const s = { ...memFx(), checks: { source: "none" }, memory: mem };
  const { i, row } = rowOf(s, "| Memory | ");
  assert.equal(row, "| Memory | 2 applied · 1 rules · 0 dropped · 1 proposals · PR https://example.test/pr/4 · rules PR https://example.test/pr/5 |");
  assert.equal(rowOf({ ...memFx(), memory: { ...mem, rules: 0, rules_pr: null } }, "| Memory | ").row, "| Memory | 2 applied · 0 rules · 0 dropped · 1 proposals · PR https://example.test/pr/4 · rules PR none |");
  assert.equal(report(s).split("\n")[i - 1], "| Checks | not counted |", "after Checks");
  assert.equal(rowOf({ ...memFx(), memory: { ops: 0, applied: 0, dropped: 0, proposed: 0, pr: null } }, "| Memory | ").row, "| Memory | 0 applied · 0 rules · 0 dropped · 0 proposals · PR none · rules PR none |");
});

test("summary.mjs memory: a summary built before this run has no Memory row", () => {
  const fx = fixture();
  assert.equal("memory" in fx, false);
  assert.equal(report(fx), readFileSync(fileURLToPath(new URL("../fixtures/summary-report.md", import.meta.url)), "utf8").replace(/\n$/, ""));
  assert.doesNotMatch(report(fx), /Memory \|/);
});

test("summary.mjs memory: ledger-line carries memory; memory-line is one memory.jsonl row per memory PR, a continue on the same PR replacing it", async () => {
  const d = mkdtempSync(join(tmpdir(), "meml-"));
  try {
    const mem = { ops: 3, applied: 2, dropped: 0, proposed: 1, pr: "https://example.test/pr/4" };
    writeFileSync(join(d, "s.json"), JSON.stringify({ ...fixture(), memory: mem }));
    await sameAsCli("summary.mjs", ["ledger-line", join(d, "s.json"), join(d, "runs.jsonl")]);
    assert.equal(JSON.stringify(JSON.parse(readFileSync(join(d, "runs.jsonl"), "utf8")).memory), JSON.stringify(mem));
    await sameAsCli("summary.mjs", ["ledger-line", fileURLToPath(new URL("../fixtures/summary-report.json", import.meta.url)), join(d, "old.jsonl")]);
    assert.equal(JSON.parse(readFileSync(join(d, "old.jsonl"), "utf8")).memory, null);
    // memory-line: the ledger's memory.jsonl, one row per memory PR (a continue's on the same PR replaces it), its note on stdout
    const m = join(d, "memory.jsonl");
    assert.deepEqual(await sameAsCli("summary.mjs", ["memory-line", fileURLToPath(new URL("../fixtures/summary-report.json", import.meta.url)), m]), { rc: 0, out: "" });
    assert.equal(existsSync(m), false, "no memory, no row");
    writeFileSync(join(d, "n.json"), JSON.stringify({ ...fixture(), memory: { ...mem, pr: null } }));
    assert.deepEqual(await sameAsCli("summary.mjs", ["memory-line", join(d, "n.json"), m]), { rc: 0, out: "" });
    assert.equal(existsSync(m), false, "no PR, no row");
    // a continue after its PR merged opens a new one: the merged PR's row stays, or harness memory loses it from the count
    writeFileSync(m, '{"run":"other","url":"https://example.test/pr/1"}\n' + JSON.stringify({ run: fixture().run, url: "https://example.test/pr/2" }) + "\n");
    const { out } = await sameAsCli("summary.mjs", ["memory-line", join(d, "s.json"), m]);
    assert.equal(out, `ledger: memory PR ${mem.pr} in memory.jsonl (2 applied · 0 dropped · 1 proposals)\n`);
    await sameAsCli("summary.mjs", ["memory-line", join(d, "s.json"), m]);
    const rows = readFileSync(m, "utf8").trim().split("\n").map(l => JSON.parse(l));
    const run = fixture().run;
    assert.equal(JSON.stringify(rows.map(r => [r.run, r.url])), JSON.stringify([["other", "https://example.test/pr/1"], [run, "https://example.test/pr/2"], [run, mem.pr]]));
    assert.equal(JSON.stringify(Object.keys(rows[2])), '["run","project","tier","url","ops","applied","dropped","proposed","sections","at"]');
    assert.match(rows[2].at, /^\d{4}-\d\d-\d\dT/);
    // both PRs: two rows, each with its tier and the sections its ops touched, each replaced by its url
    const both = { ...mem, rules: 1, rules_pr: "https://example.test/pr/5", sections: { facts: ["## Gotchas"], rules: ["## Code rules"] } };
    writeFileSync(join(d, "b.json"), JSON.stringify({ ...fixture(), memory: both }));
    const two = await sameAsCli("summary.mjs", ["memory-line", join(d, "b.json"), m]);
    assert.equal(two.out, `ledger: memory PR ${mem.pr} in memory.jsonl (2 applied · 0 dropped · 1 proposals)\nledger: memory rules PR https://example.test/pr/5 in memory.jsonl (1 rules · ## Code rules)\n`);
    await sameAsCli("summary.mjs", ["memory-line", join(d, "b.json"), m]);
    const rows2 = readFileSync(m, "utf8").trim().split("\n").map(l => JSON.parse(l)).filter(r => r.run === run);
    assert.equal(JSON.stringify(rows2.map(r => [r.url, r.tier ?? null, r.sections ?? null])), JSON.stringify([["https://example.test/pr/2", null, null], [mem.pr, "facts", ["## Gotchas"]], ["https://example.test/pr/5", "rules", ["## Code rules"]]]));
    assert.equal(JSON.stringify(Object.keys(rows2[2])), '["run","project","tier","url","ops","rules","dropped","proposed","sections","at"]');
  } finally { rmSync(d, { recursive: true, force: true }); }
});

test("summary.mjs memory: memoryState reads unchanged, edited, closed and open from gh's fields", () => {
  assert.equal(memoryState(ghPr("MERGED", "memory: r: 2 facts"), "r"), "merged unchanged");
  assert.equal(memoryState(ghPr("MERGED", "memory: r: 2 facts", "memory: r: 1 facts"), "r"), "merged unchanged", "a continue's second commit is the driver's");
  assert.equal(memoryState(ghPr("MERGED", "memory: r: 2 facts", "tidy the Gotchas"), "r"), "merged edited");
  assert.equal(memoryState(ghPr("MERGED", "memory: r2: 2 facts"), "r"), "merged edited", "another run's headline is no driver commit of this one");
  assert.equal(memoryState(ghPr("MERGED", "memory: r: 2 facts and more"), "r"), "merged edited");
  assert.equal(memoryState(ghPr("CLOSED", "memory: r: 2 facts"), "r"), "closed");
  assert.equal(memoryState(ghPr("OPEN", "memory: r: 2 facts"), "r"), "open");
  assert.equal(memoryState(ghPr("MERGED", "memory: r: 2 facts", "Merge branch 'main' into harness-memory/r"), "r"), "merged unchanged", "GitHub's Update branch edits nothing");
  assert.equal(memoryState(ghPr("MERGED"), "r"), "merged edited", "no driver commit is no unchanged merge");
  // a rules PR: its own commits by the rules subject, GitHub's merge into harness-rules/<run> neither
  assert.equal(memoryState(ghPr("MERGED", "memory: r: 2 rules", "Merge branch 'main' into harness-rules/r"), "r", "rules"), "merged unchanged");
  assert.equal(memoryState(ghPr("MERGED", "memory: r: 2 facts"), "r", "rules"), "merged edited", "a facts commit is no rules PR's own");
  assert.equal(memoryState(ghPr("MERGED", "memory: r: 2 rules"), "r"), "merged edited", "nor a rules commit a facts PR's");
  assert.equal(memoryState(ghPr("MERGED", "memory: r: 2 facts", "Merge branch 'main' into harness-rules/r"), "r"), "merged edited");
  assert.equal(memoryState({ state: "MERGED", commits: "x" }, "r"), "merged edited");
  assert.equal(memoryState(null, "r"), "unknown");
  assert.equal(memoryState({}, "r"), "unknown");
});

test("summary.mjs memory: memoryView prints the tier in each line and one tally line per tier, a row without tier a facts row", async () => {
  const R0 = n => `review: held 0 · failed 0 · overrides 0 (merged against a fail 0 · edited or closed against a hold 0) · unreviewed ${n}`;   // the review: tally of n rows before R2
  const row = (run, n, at) => ({ run, project: "p", url: `https://example.test/pr/${n}`, ops: 3, applied: 2, dropped: 1, proposed: n, at });
  const rows = [row("a", 1, "2026-11-01T10:00:00Z"), row("c", 3, "2026-11-03T10:00:00Z"), row("b", 2, "2026-11-02T10:00:00Z"), row("d", 4, "2026-11-04T10:00:00Z")];
  const gh = { "https://example.test/pr/1": ghPr("MERGED", "memory: a: 2 facts"), "https://example.test/pr/2": ghPr("MERGED", "memory: b: 2 facts", "edit"),
    "https://example.test/pr/3": ghPr("CLOSED"), "https://example.test/pr/4": ghPr("OPEN", "memory: d: 2 facts") };
  assert.equal(memoryView(rows, gh, 10).join("\n"), ["d · p · facts · 2/1/4 · unreviewed · https://example.test/pr/4 · open", "c · p · facts · 2/1/3 · unreviewed · https://example.test/pr/3 · closed",
    "b · p · facts · 2/1/2 · unreviewed · https://example.test/pr/2 · merged edited", "a · p · facts · 2/1/1 · unreviewed · https://example.test/pr/1 · merged unchanged",
    "facts: merged unchanged 1 · edited 1 · closed 1 · open 1", "rules: merged unchanged 0 · edited 0 · closed 0 · open 0", "answers: accepted 0 · declined 0", R0(4)].join("\n"));
  assert.equal(memoryView(rows, gh, 2).join("\n"), ["d · p · facts · 2/1/4 · unreviewed · https://example.test/pr/4 · open", "c · p · facts · 2/1/3 · unreviewed · https://example.test/pr/3 · closed",
    "facts: merged unchanged 0 · edited 0 · closed 1 · open 1", "rules: merged unchanged 0 · edited 0 · closed 0 · open 0", "answers: accepted 0 · declined 0", R0(2)].join("\n"), "at most n, the line over those shown");
  // gh could not say: unknown, counted on its own
  assert.equal(memoryView([rows[0]], {}, 10).join("\n"), `a · p · facts · 2/1/1 · unreviewed · https://example.test/pr/1 · unknown\nfacts: merged unchanged 0 · edited 0 · closed 0 · open 0 · unknown 1\nrules: merged unchanged 0 · edited 0 · closed 0 · open 0\nanswers: accepted 0 · declined 0\n${R0(1)}`);
  assert.equal(memoryView([], {}, 10).join("\n"), "(none)");
  // a rules row: its count and the sections it touched; its state read by the rules subject; counted on the rules line
  const rr = { run: "d", project: "p", tier: "rules", url: "https://example.test/pr/6", ops: 3, rules: 1, dropped: 0, proposed: 0, sections: ["## Code rules"], at: "2026-11-04T10:00:01Z" };
  assert.equal(memoryView([rows[3], rr], { ...gh, "https://example.test/pr/6": ghPr("MERGED", "memory: d: 1 rules") }, 10).join("\n"), ["d · p · rules · 1 · ## Code rules · unreviewed · https://example.test/pr/6 · merged unchanged",
    "d · p · facts · 2/1/4 · unreviewed · https://example.test/pr/4 · open", "facts: merged unchanged 0 · edited 0 · closed 0 · open 1", "rules: merged unchanged 1 · edited 0 · closed 0 · open 0", "answers: accepted 0 · declined 0", R0(2)].join("\n"));
  // a project's rows only; none of it is (none); an equal at lists the later row first; memory-urls asks gh about exactly those shown
  const q = { ...row("e", 5, "2026-11-04T10:00:00Z"), project: "q" };
  assert.equal(memoryView([...rows, q], gh, 10, "q")[0], "e · q · facts · 2/1/5 · unreviewed · https://example.test/pr/5 · unknown");
  assert.equal(memoryView(rows, gh, 10, "none").join("\n"), "(none)");
  assert.equal(memoryShown([...rows, q], 2).map(r => r.run).join(","), "e,d");
  const d = mkdtempSync(join(tmpdir(), "memv-"));
  try {
    writeFileSync(join(d, "m.jsonl"), [...rows, q].map(r => JSON.stringify(r)).join("\n") + "\n{half\n");
    assert.deepEqual(await sameAsCli("summary.mjs", ["memory-urls", join(d, "m.jsonl"), "2"]), { rc: 0, out: "https://example.test/pr/5\nhttps://example.test/pr/4\n" });
    assert.deepEqual(await sameAsCli("summary.mjs", ["memory-urls", join(d, "m.jsonl"), "10", "q"]), { rc: 0, out: "https://example.test/pr/5\n" });
    assert.equal((await sameAsCli("summary.mjs", ["memory", join(d, "m.jsonl"), join(d, "none.jsonl"), "1"])).out, `e · q · facts · 2/1/5 · unreviewed · https://example.test/pr/5 · unknown\nfacts: merged unchanged 0 · edited 0 · closed 0 · open 0 · unknown 1\nrules: merged unchanged 0 · edited 0 · closed 0 · open 0\nanswers: accepted 0 · declined 0\n${R0(1)}\n`);
  } finally { rmSync(d, { recursive: true, force: true }); }
});

// a run's memory-result.json with one rule (mp/1) and one proposal (mp/2), as tests/unit/memory.test.mjs has it
const MEM_RESULT = { ops: 3, applied: [], dropped: [], run: "mp",
  rules: [{ op: "add", file: "CLAUDE.md", section: "## Code rules", text: "stub proposal: run the stub suite before each commit", tier: 2, why: "w", from: "entries.jsonl:2", n: 1 }],
  proposed: [{ op: "add", file: "CLAUDE.md", section: "## Live system", text: "deploy only through scripts/deploy.sh from git", tier: 3, why: "w", from: "entries.jsonl:3", n: 2 }] };

test("summary.mjs memoryView: an answers: tally line after the tiers' and `· n answered` on a listed run's first line; none or no answers file still lists", () => {
  const rows = [{ run: "mp", project: "proj", tier: "facts", url: "u1", applied: 2, dropped: 0, proposed: 1, at: "1" }, { run: "mp", project: "proj", tier: "rules", url: "u2", rules: 1, sections: ["## Code rules"], at: "1" },
    { run: "mo", project: "proj", tier: "facts", url: "u3", applied: 1, dropped: 0, proposed: 0, at: "0" }];
  const a = [answerRow(MEM_RESULT, { run: "mp", project: "proj", n: 1, verdict: "declined", why: "x", at: "2026-11-08T12:00:00.000Z" }).row, answerRow(MEM_RESULT, { run: "mp", project: "proj", n: 2, verdict: "accepted", why: "x", at: "2026-11-08T12:00:00.000Z" }).row];
  const out = memoryView(rows, {}, 10, "", a);
  assert.equal(out[0], "mp · proj · rules · 1 · ## Code rules · unreviewed · u2 · unknown · 2 answered");
  assert.equal(out[1], "mp · proj · facts · 2/0/1 · unreviewed · u1 · unknown");
  assert.equal(out.at(-2), "answers: accepted 1 · declined 1");
  assert.equal(memoryView(rows, {}, 10).at(-2), "answers: accepted 0 · declined 0");
  assert.equal(memoryView(rows, {}, 1, "", a).at(-2), "answers: accepted 1 · declined 1");
  assert.equal(memoryView(rows.slice(2), {}, 10, "", a).at(-2), "answers: accepted 0 · declined 0");   // not a shown run's
  assert.equal(memoryView([], {}, 10, "", a).join("\n"), "(none)");
});


test("summary.mjs memory: build reads the review's keys, cost, wall and model; memoryLine ends with held, failed, dollars and minutes, none (<why>) without a review, nothing for a memory.json without reviewed", () => {
  const d = mkdtempSync(join(tmpdir(), "mem-"));
  try {
    const base = '"ops":3,"applied":2,"dropped":0,"proposed":1,"pr":"https://example.test/pr/4","rules":1,"rules_pr":null';
    writeFileSync(join(d, "memory.json"), `{${base},"reviewed":3,"held":2,"failed":1,"review":"ok","merged_by":"driver","review_cost_usd":0.42,"review_s":250,"review_model":"opus","reviewed_ids":["facts/1","facts/2","rules/1"],"failed_ids":["facts/2:q2"]}\n`);
    const m = build("/nonexistent/p/w", "r", d).memory;
    assert.equal(JSON.stringify([m.reviewed, m.held, m.failed, m.review, m.merged_by, m.review_cost_usd, m.review_s, m.review_model, m.reviewed_ids, m.failed_ids]),
      '[3,2,1,"ok","driver",0.42,250,"opus",["facts/1","facts/2","rules/1"],["facts/2:q2"]]');
    assert.equal(memoryLine(m), "2 applied · 1 rules · 0 dropped · 1 proposals · PR https://example.test/pr/4 · rules PR none · review 2 held · 1 failed · $0.42 · 4 min");
    // a memory.json from R1 (no cost keys): no session cost read, none printed (R2's review, M2)
    writeFileSync(join(d, "memory.json"), `{${base},"reviewed":3,"held":3,"failed":0,"review":"ok","merged_by":null}\n`);
    const r1 = build("/nonexistent/p/w", "r", d).memory;
    assert.equal(JSON.stringify(["review_cost_usd" in r1, "review_s" in r1, r1.review_model, "reviewed_ids" in r1]), "[false,false,null,false]");
    assert.equal(memoryLine(r1).endsWith(" · rules PR none · review 3 held · 0 failed"), true);
    writeFileSync(join(d, "memory.json"), `{${base},"reviewed":3,"held":0,"failed":0,"review":"the reviewer hit a limit","merged_by":null,"review_cost_usd":0.05,"review_s":30,"review_model":"opus"}\n`);
    assert.equal(memoryLine(build("/nonexistent/p/w", "r", d).memory).endsWith(" · rules PR none · review none (the reviewer hit a limit)"), true);
    writeFileSync(join(d, "memory.json"), `{${base}}\n`);
    const old = build("/nonexistent/p/w", "r", d).memory;
    assert.equal(`${Object.keys(old).filter(k => /review|held|failed|merged_by/.test(k)).join(",")}|${memoryLine(old)}`, "|2 applied · 1 rules · 0 dropped · 1 proposals · PR https://example.test/pr/4 · rules PR none");
  } finally { rmSync(d, { recursive: true, force: true }); }
});

test("summary.mjs memory: run.log's memory review line is its session; Spend by role and Time list memory-review after curator", () => {
  const log = ["2026-11-07 10:00:00 run r on harness/r in /w · port 7800", "2026-11-07 10:03:10 curator · opus · deny Bash(git push:*) Bash(gh:*)", "2026-11-07 10:05:10   curator exit 0 · abc x",
    "2026-11-07 10:05:20 memory review · opus · deny Bash(git push:*) Bash(gh:*)", "2026-11-07 10:09:20   memory-review exit 0 · abc x"].join("\n");
  assert.equal(JSON.stringify(parseRunLog(log).sessions.map(s => [s.kind, s.wall])), JSON.stringify([["curator", 120], ["memory-review", 240]]));
  const d = mkdtempSync(join(tmpdir(), "mrv-")), wt = join(d, "p", "w"), rec = join(wt, ".harness/runs/r"), st = join(d, "state");
  try {
    mkdirSync(rec, { recursive: true }); mkdirSync(st);
    writeFileSync(join(rec, "feature_list.json"), JSON.stringify({ features: [{ id: "A", milestone: "M1", kind: "build", passes: true }] }));
    writeFileSync(join(rec, "metrics.jsonl"), [{ kind: "curator", role: "curator", feature: null, model: "opus", passes: true, cost_usd: 0.1, turns: 12 },
      { kind: "memory-review", role: "memory-review", feature: null, model: "opus", passes: true, cost_usd: 0.42, turns: 9 }].map(r => JSON.stringify(r) + "\n").join(""));
    writeFileSync(join(st, "run.log"), log + "\n");
    const s = build(wt, "r", st);
    assert.equal(JSON.stringify([s.sessions.total, s.cost.by_role, s.time.by_role_h]), JSON.stringify([2, { curator: 0.1, "memory-review": 0.42 }, { curator: 0.03, "memory-review": 0.07 }]));
    assert.equal(rowOf(s, "| Spend by role | ").row, "| Spend by role | curator $0.10 · memory-review $0.42 · manager (the bash driver) $0.00 |");
    assert.match(rowOf(s, "| Time | ").row, /\(curator 0\.03, memory-review 0\.07\)/);
    // a summary without the reviewer's cost lists no memory-review
    assert.doesNotMatch(rowOf({ ...s, cost: { ...s.cost, by_role: { curator: 0.1 } } }, "| Spend by role | ").row, /memory-review/);
  } finally { rmSync(d, { recursive: true, force: true }); }
});

test("summary.mjs memory: memory-line writes the review's fields into the facts row and the rules row, each tier's counts from its own ids; an unreviewed summary's rows have none", async () => {
  const d = mkdtempSync(join(tmpdir(), "mrl-"));
  try {
    const m = join(d, "memory.jsonl"), mem = { ops: 4, applied: 2, dropped: 0, proposed: 1, pr: "https://example.test/pr/4", rules: 2, rules_pr: "https://example.test/pr/5",
      sections: { facts: ["## Gotchas"], rules: ["## Code rules"] }, reviewed: 4, held: 2, failed: 2, review: "ok", merged_by: "driver", review_cost_usd: 0.42, review_s: 250,
      review_model: "opus", reviewed_ids: ["facts/1", "facts/2", "rules/3", "rules/4"], failed_ids: ["facts/2:q2", "rules/4:q4"] };
    writeFileSync(join(d, "s.json"), JSON.stringify({ ...fixture(), memory: mem }));
    await sameAsCli("summary.mjs", ["memory-line", join(d, "s.json"), m]);
    const rows = readFileSync(m, "utf8").trim().split("\n").map(l => JSON.parse(l)), pick = r => [r.tier, r.reviewed, r.held, r.failed, r.review, r.failed_ids, r.merged_by, r.review_cost_usd];
    assert.equal(JSON.stringify(rows.map(pick)), JSON.stringify([["facts", 2, 1, 1, "ok", ["facts/2:q2"], "driver", 0.42], ["rules", 2, 1, 1, "ok", ["rules/4:q4"], null, 0.42]]));
    assert.equal(JSON.stringify(rows.map(r => r.fails_dropped)), "[false,false]", "fails_dropped: the facts row's, false unless the landing dropped them");
    writeFileSync(join(d, "f.json"), JSON.stringify({ ...fixture(), memory: { ...mem, fails_dropped: true } }));
    rmSync(m); await sameAsCli("summary.mjs", ["memory-line", join(d, "f.json"), m]);
    assert.equal(readFileSync(m, "utf8").trim().split("\n").map(l => JSON.parse(l).fails_dropped).join(","), "true,false", "the rules PR carries every op: never dropped");
    // no review: each tier's ids reviewed, none held or failed
    writeFileSync(join(d, "n.json"), JSON.stringify({ ...fixture(), memory: { ...mem, held: 0, failed: 0, review: "the reviewer hit a limit", merged_by: null, failed_ids: [] } }));
    rmSync(m); await sameAsCli("summary.mjs", ["memory-line", join(d, "n.json"), m]);
    assert.equal(JSON.stringify(readFileSync(m, "utf8").trim().split("\n").map(l => pick(JSON.parse(l)))),
      JSON.stringify([["facts", 2, 0, 0, "the reviewer hit a limit", [], null, 0.42], ["rules", 2, 0, 0, "the reviewer hit a limit", [], null, 0.42]]));
    // a summary before R2 (no reviewed, or reviewed without its ids): rows without a review key
    for (const old of [{ ops: 3, applied: 2, dropped: 0, proposed: 1, pr: "https://example.test/pr/4" }, { ...mem, reviewed_ids: undefined, failed_ids: undefined }]) {
      writeFileSync(join(d, "o.json"), JSON.stringify({ ...fixture(), memory: old }));
      rmSync(m, { force: true }); await sameAsCli("summary.mjs", ["memory-line", join(d, "o.json"), m]);
      assert.equal(readFileSync(m, "utf8").trim().split("\n").map(l => Object.keys(JSON.parse(l)).filter(k => /review|held|failed|merged_by/.test(k)).length).join(","), old.rules_pr ? "0,0" : "0");
    }
  } finally { rmSync(d, { recursive: true, force: true }); }
});

// R2-02 (decisions/2026-11-09-memory-graduation): the reviewer's columns, Michael's overrides read from the row and gh's
// state, the review: tally, and the auto: line a project earns
const rv = (run, o = {}) => ({ run, project: "p", tier: "facts", url: `https://example.test/pr/${run}`, ops: 3, applied: 2, dropped: 0, proposed: 0,
  reviewed: 2, held: 2, failed: 0, review: "ok", failed_ids: [], merged_by: null, review_cost_usd: 0.1, at: `2026-11-0${o.day ?? 1}T10:00:00Z`, ...o });
const ghOf = (run, s) => (s === "merged unchanged" ? ghPr("MERGED", `memory: ${run}: 2 facts`) : s === "merged edited" ? ghPr("MERGED", `memory: ${run}: 2 facts`, "edit")
  : s === "closed" ? ghPr("CLOSED") : ghPr("OPEN"));
test("summary.mjs memoryView: held and failed columns, unreviewed for an old row or a review none, the two overrides from the row and gh's state, the review: tally line, and a run-level declined row is no override either", () => {
  const rows = [rv("f1", { held: 1, failed: 1, failed_ids: ["facts/2:q2"], day: 8 }), rv("f2", { held: 1, failed: 1, merged_by: "driver", day: 7 }), rv("f3", { day: 6 }),
    rv("f4", { reviewed: 1, held: 1, day: 5 }), rv("f5", { reviewed: 1, held: 1, day: 4 }), { ...rv("f6", { day: 3 }), reviewed: undefined, held: undefined, failed: undefined, review: undefined },
    { ...rv("f7", { day: 2 }), tier: "rules", rules: 1, sections: ["## Code rules"], reviewed: 1, held: 1 }, rv("f8", { held: 0, review: "the reviewer failed (exit 124)", day: 1 })];
  const st = { f1: "merged unchanged", f2: "merged unchanged", f3: "closed", f4: "closed", f5: "merged edited", f6: "open", f7: "open", f8: "open" };
  const gh = Object.fromEntries(rows.map(r => [r.url, ghOf(r.run, st[r.run])]));
  const declined = [{ run: "f4", project: "p", n: 1, tier: 2, verdict: "declined", why: "a duplicate run", key: "k", at: "2026-11-05T11:00:00Z" }];
  const out = memoryView(rows, gh, 10, "", declined), u = r => `https://example.test/pr/${r}`;
  assert.equal(out[0], `f1 · p · facts · 2/0/0 · held 1 · failed 1 · ${u("f1")} · merged unchanged · override: merged against a fail`);
  assert.equal(out[1], `f2 · p · facts · 2/0/0 · held 1 · failed 1 · ${u("f2")} · merged unchanged`, "the driver's auto merge is no override");
  assert.equal(out[2], `f3 · p · facts · 2/0/0 · held 2 · failed 0 · ${u("f3")} · closed · override: closed against a hold`);
  assert.equal(out[3], `f4 · p · facts · 2/0/0 · held 1 · failed 0 · ${u("f4")} · closed · 1 answered`, "a closed PR whose run has a declined row is no override");
  assert.equal(out[4], `f5 · p · facts · 2/0/0 · held 1 · failed 0 · ${u("f5")} · merged edited · override: closed against a hold`);
  assert.equal(out[5], `f6 · p · facts · 2/0/0 · unreviewed · ${u("f6")} · open`);
  assert.equal(out[6], `f7 · p · rules · 1 · ## Code rules · held 1 · failed 0 · ${u("f7")} · open`);
  assert.equal(out[7], `f8 · p · facts · 2/0/0 · unreviewed · ${u("f8")} · open`, "a review none is unreviewed");
  assert.equal(out.slice(8).join("\n"), ["facts: merged unchanged 2 · edited 1 · closed 2 · open 2", "rules: merged unchanged 0 · edited 0 · closed 0 · open 1", "answers: accepted 0 · declined 1",
    "review: held 7 · failed 2 · overrides 3 (merged against a fail 1 · edited or closed against a hold 2) · unreviewed 2"].join("\n"));
  assert.ok(!out.some(l => l.startsWith("auto:")), "no auto: line without a project");
  // under auto a facts PR the driver left open had its fails dropped from the commit: Michael's merge of it is no override
  const fd = rv("fd", { held: 1, failed: 1, fails_dropped: true });
  assert.equal(memoryView([fd], { [fd.url]: ghOf("fd", "merged unchanged") }, 10)[0], `fd · p · facts · 2/0/0 · held 1 · failed 1 · ${u("fd")} · merged unchanged`);
  assert.equal(memoryView(rows.slice(5, 6), {}, 10).at(-1), "review: held 0 · failed 0 · overrides 0 (merged against a fail 0 · edited or closed against a hold 0) · unreviewed 1");
  // the facts PR closed from the card with a why: its run's only declined row is run-level (V2-01), and that is no override either
  const runLevel = [{ run: "f4", project: "p", n: null, tier: 1, verdict: "declined", why: "a duplicate run", file: null, section: null, text: null, key: null, at: "2026-11-05T11:00:00Z" }];
  const rl = memoryView(rows, gh, 10, "", runLevel);
  assert.equal(rl[3], out[3], "the same line as a numbered decline's");
  assert.equal(memoryOverride(rows[3], "closed", new Set(["f4"])), null);
  assert.equal(rl.slice(8).join("\n"), out.slice(8).join("\n"));
  const withP = memoryView(rows, gh, 10, "p", declined);
  assert.equal(withP.length, out.length + 1); assert.match(withP.at(-1), /^auto: not yet \(.* · window 8\)$/);
  assert.equal(memoryView(rows, gh, 10, "none").join("\n"), "(none)");
});

test("summary.mjs graduation: earned over the last 8 reviewed facts PRs at 10 ops, 90 % held and one override; not yet short of any; revisit for a project on auto under 80 %", () => {
  const prs = (ops, o = {}) => ops.map((n, i) => rv(`g${i}`, { reviewed: n, held: n, day: 1, at: `2026-11-${String(10 + i).padStart(2, "0")}T10:00:00Z`, ...o }));
  const fail = (rs, i, k = 1, o = {}) => rs.map((r, j) => (j === i ? { ...r, held: r.held - k, failed: r.failed + k, ...o } : r));
  const states = (rs, s = "open", over = {}) => Object.fromEntries(rs.map(r => [r.url, over[r.run] ?? s]));
  const earn = fail(prs([3, 3, 3, 3, 2, 2, 2, 2]), 0, 1, { merged_by: "driver" }), es = states(earn, "merged unchanged");
  const g = graduation(earn, es, [], "p");
  assert.equal(g.word, "earned");
  assert.equal(g.line, "auto: earned (held 19 of 20 · 95 % · overrides 0 of 8 reviewed PRs · window 8)");
  // the window is the newest 8: an older PR with fails and other projects', rules and unreviewed rows take no place in it
  const old = { ...rv("old", { reviewed: 5, held: 0, failed: 5, at: "2026-10-01T10:00:00Z" }) };
  const noise = [old, { ...rv("q1"), project: "q", held: 0, failed: 2 }, { ...rv("r1"), tier: "rules", held: 0, failed: 2, at: "2026-11-30T10:00:00Z" },
    { ...rv("u1"), reviewed: undefined, held: undefined, failed: undefined, review: undefined, at: "2026-11-30T10:00:00Z" }, rv("n1", { review: "the reviewer hit a limit", held: 0, at: "2026-11-30T10:00:00Z" })];
  assert.equal(graduation([...earn, ...noise], es, [], "p").word, "earned");
  assert.equal(graduation(fail(prs([3, 3, 3, 3, 3, 3, 3, 3]), 0, 3), states(earn), [], "p").word, "not yet", "87 % (21 of 24)");
  assert.equal(graduation(fail(prs([3, 3, 3, 3, 3, 3, 3, 3]), 0, 3), states(earn), [], "p").line, "auto: not yet (held 21 of 24 · 87 % · overrides 0 of 8 reviewed PRs · window 8)");
  assert.equal(graduation(prs([3, 3, 3, 3, 2, 2, 2, 2]), states(earn, "open", { g1: "closed", g2: "merged edited" }), [], "p").word, "not yet", "2 overrides");
  assert.equal(graduation(prs([3, 3, 3, 3, 2, 2, 2, 2]), states(earn, "open", { g1: "closed" }), [], "p").word, "earned", "1 override");
  assert.equal(graduation(prs([2, 1, 1, 1, 1, 1, 1, 1]), {}, [], "p").word, "not yet", "9 reviewed ops");
  assert.equal(graduation(prs([4, 4, 4, 4, 4, 4]), {}, [], "p").word, "not yet", "6 reviewed PRs: the window is not full");
  // the wording of a not yet: an override is Michael's merge over a fail; the driver's is none
  const six = fail(prs([2, 2, 1, 1, 1, 1]), 0), ss = states(six, "open", { g0: "merged unchanged" });
  assert.equal(graduation(six, ss, [], "p").line, "auto: not yet (held 7 of 8 · 87 % · overrides 1 of 6 reviewed PRs · window 8)");
  assert.equal(graduation(fail(prs([2, 2, 1, 1, 1, 1]), 0, 1, { merged_by: "driver" }), ss, [], "p").line, "auto: not yet (held 7 of 8 · 87 % · overrides 0 of 6 reviewed PRs · window 8)");
  // a closed PR whose run has a declined row is no override
  assert.equal(graduation(prs([3, 3, 3, 3, 2, 2, 2, 2]), states(earn, "open", { g1: "closed", g2: "closed" }), [{ run: "g2", project: "p", n: 1, tier: 2, verdict: "declined", why: "x", key: "k", at: "1" }], "p").word, "earned");
  // on auto: under 80 % held is revisit (a word, never a switch); at 80 % or more the same reading as under pr
  const low = fail(prs([3, 3, 3, 3, 2, 2, 2, 2]), 0, 3).map((r, j) => (j === 1 ? { ...r, held: 1, failed: 2 } : r));   // 15 of 20: 75 %
  assert.equal(graduation(low, {}, [], "p", "auto").word, "revisit");
  assert.equal(graduation(low, {}, [], "p", "auto").line, "auto: revisit (held 15 of 20 · 75 % · overrides 0 of 8 reviewed PRs · window 8 · unknown 8)");
  assert.equal(graduation(low, {}, [], "p", "pr").word, "not yet");
  assert.equal(graduation(earn, es, [], "p", "auto").word, "earned");
  // gh could not answer for a PR in the window: its override is unread, so never earned (R2's review, M1)
  assert.equal(graduation(earn, {}, [], "p").line, "auto: not yet (held 19 of 20 · 95 % · overrides 0 of 8 reviewed PRs · window 8 · unknown 8)");
  assert.equal(graduation(earn, { ...es, [earn[3].url]: "unknown" }, [], "p").line, "auto: not yet (held 19 of 20 · 95 % · overrides 0 of 8 reviewed PRs · window 8 · unknown 1)");
  // the per cent is rounded down, so it never reads at a threshold the counts missed (R2's review, M3)
  assert.equal(graduation(fail(prs([4, 4, 4, 4, 4, 3, 3, 3]), 0, 3), states(earn), [], "p").line, "auto: not yet (held 26 of 29 · 89 % · overrides 0 of 8 reviewed PRs · window 8)");
  assert.equal(graduation([], {}, [], "p").line, "auto: not yet (held 0 of 0 · 0 % · overrides 0 of 0 reviewed PRs · window 8)");
});

test("summary.mjs memory: memory with a project and a policy ends with the auto: line, memory-urls also lists the window's PRs past --last", async () => {
  const d = mkdtempSync(join(tmpdir(), "memg-"));
  try {
    const rows = [1, 2, 3].map(i => rv(`w${i}`, { day: i }));
    writeFileSync(join(d, "m.jsonl"), rows.map(r => JSON.stringify(r)).join("\n") + "\n");
    assert.deepEqual(await sameAsCli("summary.mjs", ["memory-urls", join(d, "m.jsonl"), "1", "p"]), { rc: 0, out: ["w3", "w2", "w1"].map(r => `https://example.test/pr/${r}\n`).join("") });
    assert.deepEqual(await sameAsCli("summary.mjs", ["memory-urls", join(d, "m.jsonl"), "1"]), { rc: 0, out: "https://example.test/pr/w3\n" });
    const out = (await sameAsCli("summary.mjs", ["memory", join(d, "m.jsonl"), join(d, "none.jsonl"), "1", "p", join(d, "none.jsonl"), "auto"])).out.trim().split("\n");
    assert.equal(out.at(-1), "auto: not yet (held 6 of 6 · 100 % · overrides 0 of 3 reviewed PRs · window 8 · unknown 3)", "no gh answers: three states unread");
    assert.equal(out.length, 6, "one row, four tally lines, the auto: line");
  } finally { rmSync(d, { recursive: true, force: true }); }
});

// R2's review, I1: a continue reuses its PR, so the PR's row counts every segment that landed a commit on it
test("summary.mjs memory: memory-line on a continue's reused PR sums each landed segment's review, a rerun of one replacing its own; one unreviewed segment makes the row unreviewed", async () => {
  const d = mkdtempSync(join(tmpdir(), "mrm-"));
  try {
    const m = join(d, "memory.jsonl"), pr = "https://example.test/pr/4", base = { ops: 2, applied: 2, dropped: 0, proposed: 0, pr, review_cost_usd: 0.1, review_s: 60, review_model: "opus" };
    const seg = (k, mem) => { writeFileSync(join(d, `s${k}.json`), JSON.stringify({ ...fixture(), continuations: k, memory: { ...base, ...mem } })); return sameAsCli("summary.mjs", ["memory-line", join(d, `s${k}.json`), m]); };
    const row = () => JSON.parse(readFileSync(m, "utf8").trim().split("\n").at(-1)), pick = r => JSON.stringify([r.reviewed, r.held, r.failed, r.review, r.failed_ids, r.fails_dropped]);
    const failed = { reviewed: 2, held: 1, failed: 1, review: "ok", merged_by: null, reviewed_ids: ["facts/1", "facts/2"], failed_ids: ["facts/2:q2"] };
    const held = { applied: 1, reviewed: 1, held: 1, failed: 0, review: "ok", merged_by: null, reviewed_ids: ["facts/1"], failed_ids: [] };
    await seg(0, failed); await seg(1, held);
    assert.equal(readFileSync(m, "utf8").trim().split("\n").length, 1, "one row per PR");
    assert.equal(pick(row()), JSON.stringify([3, 2, 1, "ok", ["facts/2:q2"], false]), "segment 0's failed op is still in the PR");
    assert.equal(row().applied, 1, "the counts stay the latest segment's");
    assert.equal(memoryOverride(row(), "merged unchanged"), "merged against a fail");
    await seg(1, held);
    assert.equal(pick(row()), JSON.stringify([3, 2, 1, "ok", ["facts/2:q2"], false]), "a rerun of one segment replaces its own part");
    await seg(2, { applied: 0, ops: 0 });
    assert.equal(pick(row()), JSON.stringify([3, 2, 1, "ok", ["facts/2:q2"], false]), "a segment that landed nothing leaves the PR's review as it was");
    // auto dropped segment 0's fails; segment 1's fail is in the PR: no fails_dropped for the PR
    rmSync(m); await seg(0, { ...failed, fails_dropped: true }); await seg(1, { ...held, held: 0, failed: 1, failed_ids: ["facts/1:q1"] });
    assert.equal(pick(row()), JSON.stringify([3, 1, 2, "ok", ["facts/2:q2", "facts/1:q1"], false]));
    rmSync(m); await seg(0, { ...failed, fails_dropped: true }); await seg(1, held);
    assert.equal(row().fails_dropped, true, "every segment's fails dropped");
    // segment 0 not reviewed: the PR carries an unreviewed commit, so the row reads unreviewed and no close is against a hold
    rmSync(m); await seg(0, { ...failed, held: 0, failed: 0, failed_ids: [], review: "the reviewer wrote no memory-review.json" }); await seg(1, held);
    assert.equal(row().review, "the reviewer wrote no memory-review.json");
    assert.equal(memoryOverride(row(), "closed"), null);
    assert.match(memoryView([row()], {}, 10)[0], / · unreviewed · /);
    rmSync(m); await seg(0, { ops: 2, applied: 2 }); await seg(1, held);   // a segment before R2's review fields
    assert.equal(memoryOverride(row(), "closed"), null, "an old segment's commit is unreviewed");
  } finally { rmSync(d, { recursive: true, force: true }); }
});
