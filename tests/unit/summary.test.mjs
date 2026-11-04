// lib/summary.mjs: a run's cause and rework read from its log, and the report's memory peaks.   node --test tests/unit/summary.test.mjs
import { test } from "node:test";
import assert from "node:assert/strict";
import { mkdtempSync, mkdirSync, readFileSync, writeFileSync, rmSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { fileURLToPath } from "node:url";
import { redSuite, redUnpass, failedRecheck, build, report, reviewSummary, laneSpans, conflicts, resolutions, suiteRuns, suiteRunsLine, flakers } from "../../lib/summary.mjs";

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
  assert.equal(after({ ...fx, flakes: { count: 3, names: { "44-lanes-record": 1, "28-run-14d-harness-merge": 2 } } }), "| Flakes | 3 · 28-run-14d-harness-merge ×2, 44-lanes-record |");
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
