// lib/summary.mjs: a run's cause and rework read from its log, and the report's memory peaks.   node --test tests/unit/summary.test.mjs
import { test } from "node:test";
import assert from "node:assert/strict";
import { redSuite, failedRecheck, build, report } from "../../lib/summary.mjs";

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
