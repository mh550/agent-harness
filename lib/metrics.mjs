// Per-session metrics and session-outcome checks for the driver. No dependencies.
//   append <session.jsonl> <metrics.jsonl> <run> <kind> <feature> <model> <passes> [<wall_s> <exit> <env> <role>]
//                                        → one JSON line per session (cost, wall time, turns, how it ended)
//   limit <session.jsonl> <wall_s> [<exit>] → exit 0 and print "<reason>\t<reset epoch or 0>" if the session ended on
//                                           something that isn't the feature's fault: a usage/rate limit, an API
//                                           error or outage, or no work at all ($0); exit 1 otherwise
//   final <session.jsonl>                → the session's last result text (the retro uses it)
//   usage <session.jsonl>                → "<7-day utilization 0..1> <its reset epoch>" from the session's newest
//                                           rate-limit event (every session on a plan reports it); exit 1 if none
//   summary <metrics.jsonl>              → one line: sessions, features passed, cost, hours, by kind and model
//
// A session that uses background subagents emits several "result" events: total_cost_usd is cumulative, while
// duration_ms and num_turns are per segment. So cost is the max, turns the sum, and wall time comes from the driver.
import { readFileSync, appendFileSync, existsSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { resolve } from "node:path";

export function events(file) {
  if (!existsSync(file)) return [];
  const out = [];
  for (const l of readFileSync(file, "utf8").split("\n")) {
    if (!l.startsWith("{")) continue;
    try { out.push(JSON.parse(l)); } catch { /* stderr noise */ }
  }
  return out;
}

export function outcome(evs) {
  const results = evs.filter(e => e.type === "result");
  const last = results.at(-1) ?? null;
  // How the session ended is what counts: the last substantive result (an empty zero-turn result after it is a
  // background task finishing). An API error in an earlier segment that the session got past is not one.
  const ending = [...results].reverse().find(r => (r.num_turns ?? 0) > 0 || r.result?.trim() || r.api_error || r.is_error) ?? last;
  const apiError = [ending].find(r => r && (r.api_error || r.terminal_reason === "api_error" || r.api_error_status >= 429));
  // The window that refused us: rate_limit_info with status "rejected" (other windows' resetsAt can be days away).
  const resets = [...evs.map(e => JSON.stringify(e)).join("\n").matchAll(/"status":"rejected","resetsAt":(\d{10})/g)].map(m => Number(m[1]));
  return {
    results: results.length,
    cost: results.reduce((m, r) => Math.max(m, r.total_cost_usd ?? 0), 0),
    turns: results.reduce((s, r) => s + (r.num_turns ?? 0), 0),
    api_s: Math.round(results.reduce((s, r) => s + (r.duration_ms ?? 0), 0) / 1000),
    is_error: !!ending?.is_error,
    subtype: ending?.subtype ?? null,
    api_error: apiError ? (apiError.api_error ?? `status ${apiError.api_error_status ?? "?"}`) : null,
    api_error_status: apiError?.api_error_status ?? null,
    reset: resets.length ? Math.min(...resets) : 0,
    final: [...results].reverse().map(r => r.result).find(t => t && t.trim()) ?? "",
  };
}

// Fallback for results without structured fields (older CLIs, wrappers) and for sessions that died before a result.
const LIMIT = /usage limit|session limit|weekly limit|rate.?limit|limit reached|overloaded|quota|credit balance|\b529\b|ECONNRESET|ETIMEDOUT|ENOTFOUND|network error/i;

/** Why a session ended on something that isn't the feature's fault, or null. */
export function environmental(evs, wall, exit) {
  const o = outcome(evs);
  if (Number(exit) === 124) return null;                       // the driver's timeout: the feature was too big
  if (o.api_error) return o.final || `API error: ${o.api_error}`;
  if (o.results && o.is_error && LIMIT.test(`${o.final} ${o.subtype}`)) return o.final.slice(0, 160);
  if (o.results && o.cost === 0 && o.turns <= 1) return `no work done ($0, ${o.turns} turn${o.turns === 1 ? "" : "s"}): ${o.final.slice(0, 120)}`;
  if (!o.results) {
    const tail = evs.slice(-30).map(e => JSON.stringify(e)).join("\n");
    if (LIMIT.test(tail)) return tail.match(LIMIT)[0];
    if (Number(wall) < 120) return `no result after ${wall} s`;
  }
  return null;
}

function main([cmd, ...a]) {
  if (cmd === "append") {
    const [session, out, run, kind, feature, model, passes, wall, exit, env, role] = a;
    const o = outcome(events(session));
    appendFileSync(out, JSON.stringify({
      at: new Date().toISOString(), run, kind, role: role || kind, feature: feature || null, model, passes: passes === "true",
      cost_usd: o.cost, wall_s: wall ? Number(wall) : null, api_s: o.api_s, turns: o.turns, exit: exit ? Number(exit) : null,
      env: env === "true", result: o.results ? (o.is_error ? `error:${o.subtype}` : o.subtype) : "no-result",
      api_error: o.api_error, final: o.final.slice(0, 400),
    }) + "\n");
    return 0;
  }
  if (cmd === "limit") {
    const [session, wall, exit] = a, evs = events(session), why = environmental(evs, wall, exit);
    if (!why) return 1;
    console.log(`${why.replace(/\s+/g, " ").slice(0, 160)}\t${outcome(evs).reset}`);
    return 0;
  }
  if (cmd === "usage") {
    const w = events(a[0]).filter(e => e.type === "rate_limit_event").map(e => e.rate_limit_info?.unifiedWindows?.seven_day)
      .filter(x => x && typeof x.utilization === "number").at(-1);
    if (!w) return 1;
    console.log(`${w.utilization} ${w.resetsAt ?? 0}`);
    return 0;
  }
  if (cmd === "final") { console.log(outcome(events(a[0])).final); return 0; }
  if (cmd === "summary") {
    const rows = existsSync(a[0]) ? readFileSync(a[0], "utf8").trim().split("\n").filter(Boolean).map(l => JSON.parse(l)) : [];
    const sum = (xs, k) => xs.reduce((s, x) => s + (x[k] ?? 0), 0);
    const real = rows.filter(r => !(r.env || (r.cost_usd === 0 && (r.turns ?? 0) <= 1)));
    const group = k => Object.entries(rows.reduce((g, r) => ((g[r[k]] ??= []).push(r), g), {}))
      .map(([name, xs]) => `${name} ${xs.length} ($${sum(xs, "cost_usd").toFixed(2)})`).join(", ");
    const hours = rows.some(r => r.wall_s != null) ? sum(rows, "wall_s") / 3600 : sum(rows, "duration_s") / 3600;
    console.log(`${rows.length} sessions (${real.length} real) · ${new Set(rows.filter(r => r.kind === "coding" && r.passes).map(r => r.feature)).size} features passed · `
      + `$${sum(rows, "cost_usd").toFixed(2)} · ${hours.toFixed(1)} h`
      + (rows.length ? ` · by kind: ${group("kind")} · by model: ${group("model")}` : ""));
    return 0;
  }
  console.error("usage: metrics.mjs append|limit|usage|final|summary …");
  return 2;
}

if (process.argv[1] && fileURLToPath(import.meta.url) === resolve(process.argv[1])) process.exit(main(process.argv.slice(2)));
