// Session metrics, the raw material for "what did this run cost and produce".
//   append <session.jsonl> <metrics.jsonl> <run> <kind> <feature> <model> <passes>
//       reads the session's final stream-json "result" line, appends one JSON line to metrics.jsonl
//   summary <metrics.jsonl>   → sessions, passes, cost, hours, by kind and model
import { readFileSync, appendFileSync, existsSync } from "node:fs";

function lastResult(file) {
  if (!existsSync(file)) return null;
  const lines = readFileSync(file, "utf8").trim().split("\n").reverse();
  for (const l of lines) {
    try { const j = JSON.parse(l); if (j.type === "result") return j; } catch { /* stderr noise */ }
  }
  return null;
}

const [cmd, ...a] = process.argv.slice(2);
if (cmd === "append") {
  const [session, out, run, kind, feature, model, passes] = a;
  const r = lastResult(session);
  appendFileSync(out, JSON.stringify({
    at: new Date().toISOString(), run, kind, feature: feature || null, model, passes: passes === "true",
    cost_usd: r?.total_cost_usd ?? null, duration_s: r?.duration_ms != null ? Math.round(r.duration_ms / 1000) : null,
    turns: r?.num_turns ?? null, result: r ? (r.is_error ? `error:${r.subtype}` : r.subtype) : "no-result",
  }) + "\n");
} else if (cmd === "summary") {
  const rows = existsSync(a[0]) ? readFileSync(a[0], "utf8").trim().split("\n").filter(Boolean).map(l => JSON.parse(l)) : [];
  const sum = (xs, k) => xs.reduce((s, x) => s + (x[k] ?? 0), 0);
  const group = k => Object.entries(rows.reduce((g, r) => ((g[r[k]] ??= []).push(r), g), {}))
    .map(([name, xs]) => `${name} ${xs.length} ($${sum(xs, "cost_usd").toFixed(2)})`).join(", ");
  console.log(`${rows.length} sessions · ${new Set(rows.filter(r => r.kind === "coding" && r.passes).map(r => r.feature)).size} features passed · `
    + `$${sum(rows, "cost_usd").toFixed(2)} · ${(sum(rows, "duration_s") / 3600).toFixed(1)} h`
    + (rows.length ? ` · by kind: ${group("kind")} · by model: ${group("model")}` : ""));
} else {
  console.error("usage: metrics.mjs append|summary …");
  process.exit(2);
}
