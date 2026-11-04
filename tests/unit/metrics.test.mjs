// lib/metrics.mjs: tokens, cache, context peak and orientation from a capture; a resume's row; a row's mem_peak_mb.   node --test tests/unit/metrics.test.mjs
import { test } from "node:test";
import assert from "node:assert/strict";
import { mkdtempSync, readFileSync, writeFileSync, rmSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { fileURLToPath } from "node:url";
import { outcome, events, orientation as or, resumeRow, metricsRow } from "../../lib/metrics.mjs";

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
