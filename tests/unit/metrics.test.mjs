// lib/metrics.mjs: tokens, cache, context peak and orientation from a capture; a resume's row; a row's mem_peak_mb.   node --test tests/unit/metrics.test.mjs
import { test } from "node:test";
import assert from "node:assert/strict";
import { mkdtempSync, readFileSync, writeFileSync, rmSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { fileURLToPath } from "node:url";
import { execFileSync } from "node:child_process";
import { outcome, events, orientation as or, resumeRow, metricsRow, fixRound, fixResult, isSession } from "../../lib/metrics.mjs";

const fixture = name => fileURLToPath(new URL(`../fixtures/${name}`, import.meta.url));

test("metrics.mjs: tokens, cache rate and context peak from the real fixture", () => {
  const o = outcome(events(fixture("usage-tokens.jsonl"))), n = outcome([{ type: "result", total_cost_usd: 0 }]);
  assert.equal(o.tokens_in, 4);
  assert.equal(o.cache_read, 35768);
  assert.equal(o.cache_write, 13651);
  assert.equal(o.tokens_out, 219);
  assert.equal(o.cache_hit_rate, 0.724);
  assert.equal(o.context_peak, 24881);
  assert.equal(n.tokens_in, null);
  assert.equal(n.cache_hit_rate, null);
  assert.equal(n.context_peak, null);
});

// The capture's first message (thinking, then Write, one message.id) is the first edit, so it alone counts; without the
// Write event both messages count, timed to the last event. No usage → null; no timestamps → seconds null; an edit event
// without one is timed by the last stamped event before it.
test("metrics.mjs: orientation stops at the first Write", () => {
  const evs = events(fixture("usage-tokens.jsonl"));
  const noEdit = evs.filter(e => !e.message?.content?.some(c => c.name === "Write")), noTs = evs.map(({ timestamp, ...e }) => e);
  assert.deepEqual(or(evs), { tokens: 24547, turns: 1, seconds: 0.233 });
  assert.equal(Object.keys(or(evs)).join(), "tokens,turns,seconds");   // the eval compared JSON.stringify, so key order too
  assert.deepEqual(or(noEdit), { tokens: 49432, turns: 2, seconds: 1.441 });
  assert.deepEqual(or(noTs), { tokens: 24547, turns: 1, seconds: null });
  assert.deepEqual(or(evs.map((e, i) => i === 1 ? noTs[1] : e)), { tokens: 24547, turns: 1, seconds: 0 });
  assert.deepEqual(or([{ type: "result" }]), { tokens: null, turns: null, seconds: null });
  assert.equal(Object.keys(or([{ type: "result" }])).join(), "tokens,turns,seconds");   // its own literal, so its order too
});

// A resume (R2): its entry-resume row holds the resume's cumulative figures minus the session's (total_cost_usd and
// modelUsage are cumulative over a session id), checked against the figures the bash check had jq read from the files:
// `map(select(.type == "result"))[-1].total_cost_usd` of each, and the resume's result `.usage.input_tokens`
const results = name => readFileSync(fixture(`claude-resume/${name}`), "utf8").split("\n").filter(l => l.trim()).map(l => JSON.parse(l)).filter(e => e.type === "result");
const resumed = (a, b) => {
  const want = results(b).at(-1).total_cost_usd - results(a).at(-1).total_cost_usd, tin = results(b)[0].usage.input_tokens;
  const r = resumeRow(events(fixture(`claude-resume/${a}`)), events(fixture(`claude-resume/${b}`)), ["", "", "", "run", "A", "opus", "coding", "30", "0", "null", "M1"]);
  assert.equal(results(b).length, 1, "one result line in the resume's capture");
  assert.equal(r.kind, "entry-resume");
  assert.equal(r.role, "coding");
  assert.equal(r.feature, "A");
  assert.equal(r.lane, "M1");
  assert.equal(r.cost_usd, want);
  assert.ok(r.cost_usd > 0, `cost_usd ${r.cost_usd}`);
  assert.equal(r.tokens_in, tin);
  assert.equal(r.passes, false);
};

test("metrics: an entry-resume row from first.jsonl and resumed.jsonl holds the total_cost_usd difference jq computes", () => resumed("first.jsonl", "resumed.jsonl"));

test("metrics: resumed-again-under-cap.jsonl against resumed.jsonl gives a positive difference", () => resumed("resumed.jsonl", "resumed-again-under-cap.jsonl"));

test("metrics: a resume that ended without a result line (a timeout, a kill) costs 0, never minus the session's", () => {
  // resumed.jsonl without its "type":"result" lines (the bash check's grep -v), under a temp directory
  const d = mkdtempSync(join(tmpdir(), "unit-metrics-")), noResult = join(d, "resumed-no-result.jsonl");
  try {
    writeFileSync(noResult, readFileSync(fixture("claude-resume/resumed.jsonl"), "utf8").split("\n").filter(l => !l.includes('"type":"result"')).join("\n"));
    const r = resumeRow(events(fixture("claude-resume/first.jsonl")), events(noResult), ["", "", "", "run", "A", "opus", "coding", "30", "124", "null", ""]);
    assert.equal(r.cost_usd, 0);
    assert.equal(r.kind, "entry-resume");
  } finally { rmSync(d, { recursive: true, force: true }); }
});

test("metrics.mjs: append writes mem_peak_mb as a number or null", () => {
  const r = p => metricsRow(outcome([]), ["s", "o", "run", "coding", "A", "opus", "true", "10", "0", "false", "build", p]).mem_peak_mb;
  assert.equal(r("2048"), 2048);
  assert.equal(r(""), null);
  assert.equal(r("null"), null);
  assert.equal(r(undefined), null);
});

test("metrics.mjs: metricsRow writes suite_runs, suite_full and suite_fast as numbers, null when empty (no check-runs.log) or absent", () => {
  const a = ["s", "o", "run", "coding", "A", "opus", "true", "10", "0", "false", "build", "", "M1"], r = x => metricsRow(outcome([]), x);
  const k = o => [o.suite_runs, o.suite_full, o.suite_fast];
  assert.deepEqual(k(r([...a, "3", "2", "1"])), [3, 2, 1]);
  assert.deepEqual(k(r([...a, "0", "0", "0"])), [0, 0, 0]);
  assert.deepEqual(k(r([...a, "", "", ""])), [null, null, null]);
  assert.deepEqual(k(r(a)), [null, null, null]);
  assert.equal(Object.keys(r(a)).slice(-3).join(), "suite_runs,suite_full,suite_fast");
});

// ---- fix rounds (decisions/2026-11-04-fix-rounds): the two rows a round writes, no session ----
test("fix rounds: fixRound is the row at a round's open and fixResult the next verify's suite verdict, fixed exactly when nothing failed", () => {
  const o = fixRound({ run: "r", milestone: "M1", round: "2", issue: "all", feature: "M1-fix2", names: ["t3"], files: ["t3"] });
  assert.deepEqual({ ...o, at: null }, { kind: "fix_round", run: "r", milestone: "M1", round: 2, issue: "all", feature: "M1-fix2", failed_before: ["t3"], files_before: ["t3"], at: null });
  assert.equal(Object.keys(o).join(), "kind,run,milestone,round,issue,feature,failed_before,files_before,at");
  assert.match(o.at, /^\d{4}-\d\d-\d\dT\d\d:\d\d:\d\d\.\d{3}Z$/);
  const red = fixResult({ run: "r", milestone: "M1", round: 2, issue: "all", names: ["t3", "t4"] }), green = fixResult({ run: "r", milestone: "M1", round: 2, issue: "all", names: [] });
  assert.deepEqual({ ...red, at: null }, { kind: "fix_result", run: "r", milestone: "M1", round: 2, issue: "all", failed_after: ["t3", "t4"], fixed: false, at: null });
  assert.equal(Object.keys(red).join(), "kind,run,milestone,round,issue,failed_after,fixed,at");
  assert.deepEqual([green.failed_after, green.fixed], [[], true]);
});

test("fix rounds: the CLI fix-round appends one row per call to a metrics.jsonl path; isSession is false for both kinds and summary counts neither", () => {
  const d = mkdtempSync(join(tmpdir(), "fxm-")), p = join(d, "metrics.jsonl"), M = fileURLToPath(new URL("../../lib/metrics.mjs", import.meta.url));
  const run = (...a) => execFileSync(process.execPath, [M, ...a], { encoding: "utf8", stdio: ["ignore", "pipe", "pipe"] });
  try {
    writeFileSync(p, JSON.stringify({ kind: "coding", role: "build", feature: "A", model: "opus", passes: true, cost_usd: 0.25, turns: 12, wall_s: 60 }) + "\n");
    run("fix-round", p, "open", "r", "M1", "1", "all", "M1-fix1", "t1", "a check (x)", "--", "t1", "59-needs");
    run("fix-round", p, "result", "r", "M1", "1", "all", "t3");
    run("fix-round", p, "result", "r", "M1", "2", "all");
    const rows = readFileSync(p, "utf8").trim().split("\n").map(l => JSON.parse(l));
    assert.equal(rows.length, 4);
    assert.deepEqual([rows[1].kind, rows[1].round, rows[1].feature, rows[1].failed_before, rows[1].files_before], ["fix_round", 1, "M1-fix1", ["t1", "a check (x)"], ["t1", "59-needs"]]);
    assert.deepEqual([rows[2].kind, rows[2].failed_after, rows[2].fixed, rows[3].failed_after, rows[3].fixed], ["fix_result", ["t3"], false, [], true]);
    assert.deepEqual(rows.map(isSession), [true, false, false, false]);
    assert.equal(run("summary", p), "1 sessions (1 real) · 1 features passed · $0.25 · 0.0 h · by kind: coding 1 ($0.25) · by model: opus 1 ($0.25)\n");
    assert.throws(() => run("fix-round", p, "nope", "r", "M1", "1", "all"), /usage: metrics\.mjs fix-round/);
  } finally { rmSync(d, { recursive: true, force: true }); }
});
