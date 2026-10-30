// Totals over budget.mjs --json: the bucket shares per run and over all runs, full-suite runs per coding session by
// outcome, the harness's own suites by where they ran, and the journal's load curve binned by overlap.
//   node totals.mjs budget.json
import { readFileSync } from "node:fs";
const { runs, concurrency } = JSON.parse(readFileSync(process.argv[2], "utf8"));
const sum = a => a.reduce((s, x) => s + x, 0), r0 = x => Math.round(x);
const KEYS = ["model", "session_suite", "session_other", "harness_before", "harness_after", "verify", "waiting", "idle"];
const all = Object.fromEntries(KEYS.map(k => [k, 0])); let allTotal = 0;
for (const r of runs) {
  const t = sum(r.lanes.map(l => l.total)), b = Object.fromEntries(KEYS.map(k => [k, sum(r.lanes.map(l => l.buckets[k]))]));
  for (const k of KEYS) all[k] += b[k]; allTotal += t;
  console.log(`${r.run}: lane-seconds ${r0(t)} · ${KEYS.map(k => `${k} ${Math.round(b[k] / t * 100)}%`).join(" · ")}`);
  const coding = r.sessions.filter(s => s.kind === "coding");
  const calls = coding.flatMap(s => s.suiteCalls.filter(c => c.full)), by = o => calls.filter(c => c.outcome === o).length;
  console.log(`  coding sessions ${coding.length}: full-suite scopes inside them ${sum(coding.map(s => s.fullRuns))} (${(sum(coding.map(s => s.fullRuns)) / coding.length).toFixed(1)} per session), session suite s ${r0(sum(coding.map(s => s.suite)))} (${r0(sum(coding.map(s => s.suite)) / coding.length)} per session), model s ${r0(sum(coding.map(s => s.model)))}`);
  console.log(`  the sessions' check.sh full calls by outcome: cached ${by("cached")}, green ${by("green")}, flake ${by("flake")}, red ${by("red")}, moved to background at the tool timeout ${by("moved")}, other (output cut by the call) ${by("other")}`);
  const hc = r.harnessChecks.filter(c => !c.rerun), w = o => hc.filter(c => c.where === o);
  console.log(`  harness suites (full runs, reruns aside): before a session ${w("before").length} (${r0(sum(w("before").map(c => c.wall)))} s), after ${w("after").length} (${r0(sum(w("after").map(c => c.wall)))} s), verify ${w("verify").length} (${r0(sum(w("verify").map(c => c.wall)))} s); reruns ${r.harnessChecks.filter(c => c.rerun).length}`);
  const suiteAll = sum(r.sessions.map(s => s.suite)) + sum(r.harnessChecks.map(c => c.wall)), cpu = sum(r.checksAll.map(c => c.cpu ?? 0));
  console.log(`  suite wall, every caller (sessions' suite + the harness's scopes, reruns in): ${r0(suiteAll)} lane-s (${Math.round(suiteAll / t * 100)}%); CPU in check scopes ${(cpu / 3600).toFixed(1)} CPU-h; per 20 coding sessions ${r0(suiteAll / coding.length * 20)} lane-s, ${(cpu / 3600 / coding.length * 20).toFixed(1)} CPU-h`);
  const passed = coding.filter(s => s.passes === true).length, un = coding.filter(s => s.unpassed).length;
  console.log(`  sessions that ended passes=true ${passed}, un-passed for a red suite ${un}, post-session cache hits (a passing session with no harness suite after it) ${coding.filter(s => s.passes === true && !r.harnessChecks.some(c => c.where === "after" && c.lane === s.lane && Math.abs(c.start - s.end) < 15000)).length}`);
}
console.log(`\nall runs: lane-seconds ${r0(allTotal)} · ${KEYS.map(k => `${k} ${Math.round(all[k] / allTotal * 100)}%`).join(" · ")}`);
// the load curve: full suites only (over 400 s wall or over 1500 s CPU: a 200 s rerun is a subset), by overlap bin
const full = concurrency.filter(c => c.cpu > 1500 || c.wall > 400);
for (const [lo, hi, label] of [[0, 0.01, "alone"], [0.01, 0.5, "overlap under 0.5"], [0.5, 0.9, "0.5–0.9"], [0.9, 9, "0.9 and over"]]) {
  const b = full.filter(c => c.overlap >= lo && c.overlap < hi && c.unit.includes("2026-10-29"));
  if (b.length) console.log(`2026-10-29 runs, ${label}: n ${b.length}, wall median ${r0(b.map(c => c.wall).sort((x, y) => x - y)[b.length >> 1])} s, cpu median ${r0(b.map(c => c.cpu).sort((x, y) => x - y)[b.length >> 1])} s, wall max ${r0(Math.max(...b.map(c => c.wall)))}`);
}
