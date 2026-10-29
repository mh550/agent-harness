// Per-session metrics and session-outcome checks for the driver. No dependencies.
//   append <session.jsonl> <metrics.jsonl> <run> <kind> <feature> <model> <passes> [<wall_s> <exit> <env> <role> <mem_peak_mb> <lane>]
//                                        → one JSON line per session (cost, wall time, turns, tokens, cache hit rate,
//                                          context peak, orientation cost, how it ended, its scope's memory peak)
//   limit <session.jsonl> <wall_s> [<exit>] → exit 0 and print "<reason>\t<reset epoch or 0>" if the session ended on
//                                           something that isn't the feature's fault: a usage/rate limit, an API
//                                           error or outage, or no work at all ($0); exit 1 otherwise
//   final <session.jsonl>                → the session's last result text (the retro uses it)
//   usage <session.jsonl> [<window>]     → "<utilization 0..1> <its reset epoch>" of the window (seven_day, the default,
//                                           or five_hour) from the session's newest rate-limit event that reports it
//                                           (every session on a plan does); exit 1 if none
//   summary <metrics.jsonl>              → one line: sessions, features passed, cost, hours, by kind and model
//   session-id <session.jsonl>           → the session_id of its init event; exit 1 if none
//   cost <session.jsonl>                 → its cost so far (the max total_cost_usd, 0 without a result)
//   append-resume <session.jsonl> <resume.jsonl> <metrics.jsonl> <run> <feature> <model> <role> [<wall_s> <exit> <mem_peak_mb> <lane>]
//                                        → the entry-resume row: what the resume of that session cost (R2)
//
// A session that uses background subagents emits several "result" events: total_cost_usd is cumulative, while
// duration_ms and num_turns are per segment. So cost is the max, turns the sum, and wall time comes from the driver.
// Tokens follow cost: modelUsage is cumulative too (its costUSD sums to total_cost_usd), so they come from one event.
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

/** The session's token totals from its result events (modelUsage summed over models, else usage), or null. */
export function tokens(evs) {
  const of = r => {
    const ms = r.modelUsage && Object.values(r.modelUsage);
    if (ms?.length) {
      const sum = k => ms.reduce((s, m) => s + (m[k] ?? 0), 0);
      return { tokens_in: sum("inputTokens"), cache_read: sum("cacheReadInputTokens"), cache_write: sum("cacheCreationInputTokens"), tokens_out: sum("outputTokens") };
    }
    const u = r.usage;
    return u && { tokens_in: u.input_tokens ?? 0, cache_read: u.cache_read_input_tokens ?? 0, cache_write: u.cache_creation_input_tokens ?? 0, tokens_out: u.output_tokens ?? 0 };
  };
  const total = t => t.tokens_in + t.cache_read + t.cache_write + t.tokens_out;
  return evs.filter(e => e.type === "result").map(of).filter(Boolean).reduce((m, t) => (!m || total(t) > total(m) ? t : m), null);
}

/** The largest single request's input (uncached + cache read + cache write) over the assistant events, or null. */
export function contextPeak(evs) {
  const ins = evs.filter(e => e.type === "assistant" && e.message?.usage).map(e => e.message.usage)
    .map(u => (u.input_tokens ?? 0) + (u.cache_read_input_tokens ?? 0) + (u.cache_creation_input_tokens ?? 0));
  return ins.length ? Math.max(...ins) : null;
}

// The CLI emits one assistant event per content block, each carrying its message's id and usage: a request is a message.id.
const EDITS = new Set(["Edit", "Write", "NotebookEdit"]);
const ms = e => Date.parse(e.timestamp ?? "");

/** What getting its bearings cost a session: the requests up to and including the first one that calls Edit, Write or
 *  NotebookEdit (that request's input is everything orientation read), or the whole session if it never edits. Tokens
 *  are those requests' input + cache read + cache write + output; seconds run from the first timestamped event to the
 *  last timestamped event up to the first edit (the session's last if none), null without timestamps. All null without assistant usage. */
export function orientation(evs) {
  const msgs = new Map(), ts = [];
  for (const e of evs) {
    if (!Number.isNaN(ms(e))) ts.push(ms(e));
    if (e.type !== "assistant" || !e.message?.usage) continue;
    msgs.set(e.message.id ?? msgs.size, e.message.usage);
    if (e.message.content?.some(c => c.type === "tool_use" && EDITS.has(c.name))) break;
  }
  if (!msgs.size) return { tokens: null, turns: null, seconds: null };
  const u = [...msgs.values()];
  return {
    tokens: u.reduce((s, x) => s + (x.input_tokens ?? 0) + (x.cache_read_input_tokens ?? 0) + (x.cache_creation_input_tokens ?? 0) + (x.output_tokens ?? 0), 0),
    turns: u.length,
    seconds: ts.length ? (ts.at(-1) - ts[0]) / 1000 : null,
  };
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
  const t = tokens(evs), seen = t && t.tokens_in + t.cache_read + t.cache_write, or = orientation(evs);
  return {
    results: results.length,
    cost: results.reduce((m, r) => Math.max(m, r.total_cost_usd ?? 0), 0),
    turns: results.reduce((s, r) => s + (r.num_turns ?? 0), 0),
    tokens_in: t?.tokens_in ?? null, cache_read: t?.cache_read ?? null, cache_write: t?.cache_write ?? null, tokens_out: t?.tokens_out ?? null,
    cache_hit_rate: seen ? Math.round(t.cache_read / seen * 1000) / 1000 : null,
    context_peak: contextPeak(evs),
    orient_tokens: or.tokens, orient_turns: or.turns, orient_s: or.seconds,
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
  if ([124, 137].includes(Number(exit))) return null;          // the driver's timeout (137: after -k) or the memory cap: the feature was too big
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

/** Pure but for the clock: a session's metrics.jsonl row from its outcome and append's arguments. mem_peak_mb is the
 *  scope's peak in MB, null when the session ran uncapped (decisions/2026-10-25-session-memory-peaks). */
export function metricsRow(o, [, , run, kind, feature, model, passes, wall, exit, env, role, peak, lane]) {
  return {
    at: new Date().toISOString(), run, kind, role: role || kind, feature: feature || null, model, passes: passes === "true",
    cost_usd: o.cost, wall_s: wall ? Number(wall) : null, api_s: o.api_s, turns: o.turns,
    tokens_in: o.tokens_in, cache_read: o.cache_read, cache_write: o.cache_write, tokens_out: o.tokens_out,
    cache_hit_rate: o.cache_hit_rate, context_peak: o.context_peak,
    orient_tokens: o.orient_tokens, orient_turns: o.orient_turns, orient_s: o.orient_s, exit: exit ? Number(exit) : null,
    env: env === "true", result: o.results ? (o.is_error ? `error:${o.subtype}` : o.subtype) : "no-result",
    api_error: o.api_error, final: o.final.slice(0, 400), mem_peak_mb: peak && peak !== "null" ? Number(peak) : null,
    lane: lane || null,   // the milestone whose lane ran the session (lanes P1-04); null for the initializer and the retro
  };
}

/** The session_id of a transcript's first init event, or null. */
export function sessionId(evs) {
  return evs.find(e => e.type === "system" && e.subtype === "init")?.session_id ?? null;
}

/** Pure but for the clock: the entry-resume row of a session's resume. A resume of the same session id reports the
 *  session's figures plus its own (total_cost_usd and modelUsage are cumulative), so cost and tokens are the resume's
 *  minus the session's; an unknown id (no init event, the CLI's error_during_execution) or no result (a timeout or a
 *  kill: nothing cumulative to subtract from, so cost 0, never minus the session's) keeps the resume's own. Turns,
 *  api_s and wall time are per run already. a: append-resume's arguments. */
export function resumeRow(sessionEvs, resumeEvs, [, , , run, feature, model, role, wall, exit, peak, lane]) {
  const o = outcome(resumeEvs), s = outcome(sessionEvs), id = sessionId(resumeEvs);
  if (id && id === sessionId(sessionEvs) && o.results) {
    const less = k => (o[k] == null ? null : o[k] - (s[k] ?? 0));
    Object.assign(o, { cost: o.cost - s.cost, tokens_in: less("tokens_in"), cache_read: less("cache_read"), cache_write: less("cache_write"), tokens_out: less("tokens_out") });
    const seen = o.tokens_in + o.cache_read + o.cache_write;
    o.cache_hit_rate = o.tokens_in != null && seen > 0 ? Math.round(o.cache_read / seen * 1000) / 1000 : null;
  }
  return metricsRow(o, ["", "", run, "entry-resume", feature, model, "false", wall, exit, "false", role, peak, lane]);
}

function main([cmd, ...a]) {
  if (cmd === "append") {
    appendFileSync(a[1], JSON.stringify(metricsRow(outcome(events(a[0])), a)) + "\n");
    return 0;
  }
  if (cmd === "limit") {
    const [session, wall, exit] = a, evs = events(session), why = environmental(evs, wall, exit);
    if (!why) return 1;
    console.log(`${why.replace(/\s+/g, " ").slice(0, 160)}\t${outcome(evs).reset}`);
    return 0;
  }
  if (cmd === "usage") {
    const w = events(a[0]).filter(e => e.type === "rate_limit_event").map(e => e.rate_limit_info?.unifiedWindows?.[a[1] ?? "seven_day"])
      .filter(x => x && typeof x.utilization === "number").at(-1);
    if (!w) return 1;
    console.log(`${w.utilization} ${w.resetsAt ?? 0}`);
    return 0;
  }
  if (cmd === "append-resume") {
    appendFileSync(a[2], JSON.stringify(resumeRow(events(a[0]), events(a[1]), a)) + "\n");
    return 0;
  }
  if (cmd === "session-id") { const id = sessionId(events(a[0])); if (!id) return 1; console.log(id); return 0; }
  if (cmd === "cost") { console.log(outcome(events(a[0])).cost); return 0; }
  if (cmd === "final") { console.log(outcome(events(a[0])).final); return 0; }
  if (cmd === "summary") {
    const rows = existsSync(a[0]) ? readFileSync(a[0], "utf8").trim().split("\n").filter(Boolean).map(l => JSON.parse(l)) : [];
    const sum = (xs, k) => xs.reduce((s, x) => s + (x[k] ?? 0), 0);
    const ss = rows.filter(r => r.kind !== "entry-resume");   // a resume's row is cost, never a session (R2)
    const real = ss.filter(r => !(r.env || (r.cost_usd === 0 && (r.turns ?? 0) <= 1)));
    const group = k => Object.entries(rows.reduce((g, r) => ((g[r[k]] ??= []).push(r), g), {}))
      .map(([name, xs]) => `${name} ${xs.length} ($${sum(xs, "cost_usd").toFixed(2)})`).join(", ");
    const hours = rows.some(r => r.wall_s != null) ? sum(rows, "wall_s") / 3600 : sum(rows, "duration_s") / 3600;
    console.log(`${ss.length} sessions (${real.length} real) · ${new Set(rows.filter(r => r.kind === "coding" && r.passes).map(r => r.feature)).size} features passed · `
      + `$${sum(rows, "cost_usd").toFixed(2)} · ${hours.toFixed(1)} h`
      + (rows.length ? ` · by kind: ${group("kind")} · by model: ${group("model")}` : ""));
    return 0;
  }
  console.error("usage: metrics.mjs append|append-resume|limit|usage|final|summary|session-id|cost …");
  return 2;
}

if (process.argv[1] && fileURLToPath(import.meta.url) === resolve(process.argv[1])) process.exit(main(process.argv.slice(2)));
