// A run's summary (what got done, why the rest didn't, what it cost) and the cross-run ledger. No dependencies.
//   build <worktree> <run-id> <state dir>   → summary.json on stdout (works for v2 runs too)
//   report <summary.json>…                  → the markdown writeup of one or more runs
//   ledger-line <summary.json> <runs.jsonl> → insert or replace this run's row in the ledger
//   trends <runs.jsonl>                     → every run in one table, plus failure causes across runs
//   calibration <ledger dir> <project>      → one sentence for the initializer: how long features really took
//
// Sources: the committed run record (feature_list.json, metrics.jsonl, harness-log.md), and the local state
// (run.log for wall-clock times, attempts.json, verified-*/merged-*/tests-*/ended markers, logs/*.jsonl).
import { readFileSync, existsSync, readdirSync, writeFileSync } from "node:fs";
import { join, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { schedule, kindOf } from "./features.mjs";
import { events, outcome } from "./metrics.mjs";

const read = (p, d = null) => (existsSync(p) ? readFileSync(p, "utf8") : d);
const jsonl = p => (read(p, "") ?? "").split("\n").filter(Boolean).map(l => JSON.parse(l));
const ts = s => new Date(s.replace(" ", "T")).getTime() / 1000;
const r2 = x => Math.round(x * 100) / 100;
const esc = s => s.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");

/** Pure: the median of the non-null values (mean of the two middles for an even count), rounded; null if none. */
export function median(xs, round = Math.round) {
  const v = xs.filter(x => x != null).sort((a, b) => a - b), m = v.length >> 1;
  return v.length ? round(v.length % 2 ? v[m] : (v[m - 1] + v[m]) / 2) : null;
}

/** Pure: token sums of metrics rows (null counts as 0), cache hit rate over the whole input, the highest context. */
export function tokenTotals(rows) {
  const t = { in: 0, cache_read: 0, cache_write: 0, out: 0 }, by_role = {};
  for (const r of rows) {
    const b = (by_role[r.role] ??= { in: 0, cache_read: 0, cache_write: 0, out: 0 });
    for (const [k, f] of [["in", "tokens_in"], ["cache_read", "cache_read"], ["cache_write", "cache_write"], ["out", "tokens_out"]]) {
      t[k] += r[f] ?? 0; b[k] += r[f] ?? 0;
    }
  }
  const input = t.in + t.cache_read + t.cache_write, peaks = rows.map(r => r.context_peak).filter(x => x != null);
  return { ...t, cache_hit_rate: input ? Math.round((t.cache_read / input) * 1000) / 1000 : null,
    context_peak: peaks.length ? Math.max(...peaks) : null, by_role };
}

/** Pure: sessions and driver segments from run.log. */
export function parseRunLog(text) {
  const sessions = [], segments = [];
  let open = null, seg = null;
  for (const line of text.split("\n")) {
    const m = line.match(/^(\d{4}-\d\d-\d\d \d\d:\d\d:\d\d) (.*)$/);
    if (!m) continue;
    const t = ts(m[1]), msg = m[2];
    if (/^run \S+ on /.test(msg)) { seg = { start: t, end: t }; segments.push(seg); continue; }
    if (seg) seg.end = t;
    let o;
    if (/^initializer · /.test(msg)) open = { kind: "init", feature: null, start: t };
    else if ((o = msg.match(/^session (\d+) · (\S+) · /))) open = { kind: "coding", n: Number(o[1]), feature: o[2], start: t };
    else if ((o = msg.match(/^verify (\S+) · /))) open = { kind: "verify", feature: o[1], start: t };
    else if (/^retro · /.test(msg)) open = { kind: "retro", feature: null, start: t };
    else if ((o = msg.match(/^ {2}(init|coding|verify|retro) exit (\d+)/)) && open) {
      sessions.push({ ...open, wall: t - open.start, exit: Number(o[2]) }); open = null;
    }
  }
  return { sessions, segments };
}

const envRow = r => r.env || (r.cost_usd === 0 && (r.turns ?? 0) <= 1) || (r.kind === "coding" && r.result === "error:success");

export function build(wt, run, state) {
  const dir = join(wt, ".harness/runs", run);
  const list = JSON.parse(read(join(dir, "feature_list.json"), '{"features":[]}')).features;
  const rows = jsonl(join(dir, "metrics.jsonl"));
  const hlog = read(join(dir, "harness-log.md"), "");
  const { sessions, segments } = parseRunLog(read(join(state, "run.log"), ""));
  const att = JSON.parse(read(join(state, "attempts.json"), "{}"));
  const parked = JSON.parse(read(join(state, "parked.json"), "{}"));
  const maxAtt = Number((read(join(state, "max-attempts"), "2") ?? "2").trim());
  const marker = (name) => existsSync(join(state, name));
  const num = (name) => { const v = read(join(state, name)); return v ? Number(v.trim()) : null; };

  // match each logged session to its metrics row (same kind and feature, in order)
  const used = new Set();
  for (const s of sessions) {
    const i = rows.findIndex((r, j) => !used.has(j) && r.kind === s.kind && (s.kind === "init" || s.kind === "retro" || r.feature === s.feature));
    if (i >= 0) { used.add(i); s.row = rows[i]; }
    else if (s.kind === "coding" && existsSync(join(state, "logs"))) {   // a session the v2 driver didn't record
      const f = readdirSync(join(state, "logs")).find(n => n.startsWith(`${String(s.n).padStart(2, "0")}-${s.feature}`));
      const o = f ? outcome(events(join(state, "logs", f))) : null;
      s.row = { kind: "coding", feature: s.feature, cost_usd: o?.cost ?? 0, turns: o?.turns ?? 0, env: !!o?.api_error, final: o?.final ?? "" };
    }
  }
  // v2 rows carry no "env": read the transcript to see whether the session ended on an API error (a usage limit)
  const logs = existsSync(join(state, "logs")) ? readdirSync(join(state, "logs")) : [];
  for (const s of sessions.filter(s => s.kind === "coding" && s.row && !("env" in s.row))) {
    const f = logs.find(n => n.startsWith(`${String(s.n).padStart(2, "0")}-${s.feature}.`));
    if (f && outcome(events(join(state, "logs", f))).api_error) s.row = { ...s.row, env: true };
  }
  const all = sessions.filter(s => s.row).map(s => ({ ...s.row, wall_s: s.row.wall_s ?? s.wall, exit: s.row.exit ?? s.exit, start: s.start }));
  for (const r of rows.filter((_, j) => !used.has(j))) all.push(r);   // rows without a run.log line (shouldn't happen)
  for (const r of all) {
    r.env = envRow(r);
    r.role = r.kind === "coding" ? kindOf(list.find(f => f.id === r.feature) ?? {}) : r.kind;
  }

  const verified = new Set(), merged = new Set();
  for (const m of new Set(list.map(f => f.milestone))) {
    if (marker(`verified-${m}`) || new RegExp(`· ${m} verified`).test(hlog)) verified.add(m);
    if (marker(`merged-${m}`) || new RegExp(`· ${m} merged into`).test(hlog)) merged.add(m);
  }
  // How the run ended: the driver writes "ended" before the summary; older runs only have their log's last
  // "run ended (<reason>): …" line.
  const ended = read(join(state, "ended"))?.trim()
    ?? [...hlog.matchAll(/run ended \((.*?)\): /g)].at(-1)?.[1] ?? "running";
  const endReason = ended.replace(/ · \d{4}-.*$/, "");

  const { blocked } = schedule(list, att, maxAtt, new Set(Object.keys(parked)));
  const blockedBy = new Map(blocked);
  const segStart = segments.at(-1)?.start ?? 0;
  const cause = (f) => {
    if (parked[f.id]) return ["waiting on Michael", parked[f.id].why ?? ""];
    const ss = all.filter(r => r.kind === "coding" && r.feature === f.id);
    const last = ss.at(-1);
    // refusals in an earlier segment explain that segment's end, not this one's (unless this one ended on the limit too)
    const stale = last?.env && (last.start ?? Infinity) < segStart && !/usage limit/.test(endReason);
    if (!ss.length || stale) {
      if (!blockedBy.has(f.id) || !/no feature left|blocked|waiting on Michael/.test(endReason)) return ["not reached", `run ended: ${endReason}`];
      const by = blockedBy.get(f.id);
      return ["blocked", `waits on ${by}, which ${parked[by] ? "is waiting on Michael" : "was given up"}`];
    }
    if (last.env) {
      const cut = ss.some(r => r.env && r.cost_usd > 0);
      return ["usage limit", cut ? "cut off mid-session by the usage limit" : `${ss.filter(r => r.env).length} session(s) refused by the usage limit`];
    }
    if (last.exit === 124) return ["timeout", `session timed out after ${Math.round((last.wall_s ?? 0) / 60)} min`];
    if (/max_turns/.test(last.result ?? "")) return ["max turns", ""];
    if (/budget/.test(last.result ?? "")) return ["budget", ""];
    if (new RegExp(`${f.id} un-passed: suite red`).test(hlog) && !f.passes) return ["red suite", "the suite was red after its session"];
    if (new RegExp(`verify \\S+: ${f.id} failed`).test(hlog)) return ["failed verify", "the verify session found a step that doesn't hold"];
    return ["not done", (last.final ?? "").replace(/\s+/g, " ").slice(0, 200)];
  };

  const cost = all.reduce((s, r) => s + (r.cost_usd ?? 0), 0);
  const byRole = {};
  for (const r of all) byRole[r.role] = r2((byRole[r.role] ?? 0) + (r.cost_usd ?? 0));
  const byModel = {};
  for (const r of all) byModel[r.model ?? "?"] = r2((byModel[r.model ?? "?"] ?? 0) + (r.cost_usd ?? 0));
  const timeByRole = {};
  for (const r of all) timeByRole[r.role] = r2((timeByRole[r.role] ?? 0) + (r.wall_s ?? 0) / 3600);
  const wall = segments.reduce((s, g) => s + (g.end - g.start), 0) / 3600;
  const sessionsH = all.reduce((s, r) => s + (r.wall_s ?? 0), 0) / 3600;
  const passing = list.filter(f => f.passes);
  const featureCost = id => r2(all.filter(r => r.kind === "coding" && r.feature === id).reduce((s, r) => s + (r.cost_usd ?? 0), 0));
  const count = re => (hlog.match(re) ?? []).length;
  const nVerified = passing.filter(f => verified.has(f.milestone)).length;
  const tokens = tokenTotals(all);
  const realCoding = all.filter(r => r.kind === "coding" && !r.env);
  const tried = list.filter(f => realCoding.some(r => r.feature === f.id));
  // rework: a feature the suite or a verify sent back, or that took more than one real session
  const rework = list.filter(f => new RegExp(`(^|\\s)${esc(f.id)} un-passed: suite red|: ${esc(f.id)} failed the re-check`, "m").test(hlog)
    || realCoding.filter(r => r.feature === f.id).length > 1).map(f => f.id);
  const failed = count(/failed the re-check/g);

  return {
    run, project: wt.split("/").at(-2), branch: `harness/${run}`,
    started: segments[0] ? new Date(segments[0].start * 1000).toISOString() : null,
    ended_at: segments.at(-1) ? new Date(segments.at(-1).end * 1000).toISOString() : null,
    end_reason: endReason, continuations: Math.max(0, segments.length - 1),
    features: { total: list.length, passing: passing.length, verified: nVerified,
      merged: passing.filter(f => merged.has(f.milestone)).length },
    milestones: [...new Set(list.map(f => f.milestone))].map(m => {
      const fs = list.filter(f => f.milestone === m);
      return { id: m, features: fs.length, passing: fs.filter(f => f.passes).length, verified: verified.has(m), merged: merged.has(m) };
    }),
    tests: { start: num("tests-start"), end: num("tests-end") },
    cost: { total: r2(cost), per_passing_feature: passing.length ? r2(cost / passing.length) : null, by_role: byRole, by_model: byModel,
      manager: 0 },
    time: { wall_h: r2(wall), sessions_h: r2(sessionsH), driver_h: r2(Math.max(0, wall - sessionsH)), by_role_h: timeByRole },
    tokens,
    per_verified_feature: { cost: nVerified ? r2(cost / nVerified) : null,
      tokens: nVerified ? Math.round((tokens.in + tokens.cache_read + tokens.cache_write + tokens.out) / nVerified) : null },
    orientation: { tokens: median(realCoding.map(r => r.orient_tokens)), turns: median(realCoding.map(r => r.orient_turns)),
      seconds: median(realCoding.map(r => r.orient_s), r2) },
    rework,
    first_attempt_pass_rate: tried.length ? r2(tried.filter(f => f.passes && !rework.includes(f.id)).length / tried.length) : null,
    verify_fail_rate: failed + nVerified ? r2(failed / (failed + nVerified)) : null,
    sessions: { total: all.length, real: all.filter(r => !r.env).length, environmental: all.filter(r => r.env).length },
    guards: { repairs: count(/restored the feature list/g), red_unpass: count(/un-passed: suite red/g),
      verify_failed: count(/failed the re-check/g), limit_waits: count(/hit a limit/g), verify_escalations: count(/re-running on/g),
      merges: count(/merged into/g) },
    features_detail: list.map(f => {
      const [c, detail] = f.passes ? [null, null] : cause(f);
      return { id: f.id, milestone: f.milestone, kind: kindOf(f), model: f.model ?? null, passes: !!f.passes,
        verified: !!f.passes && verified.has(f.milestone), merged: !!f.passes && merged.has(f.milestone),
        sessions: all.filter(r => r.kind === "coding" && r.feature === f.id && !r.env).length,
        refused: all.filter(r => r.kind === "coding" && r.feature === f.id && r.env).length,
        minutes: Math.round(all.filter(r => r.kind === "coding" && r.feature === f.id).reduce((s, r) => s + (r.wall_s ?? 0), 0) / 60),
        cost: featureCost(f.id), cause: c, detail };
    }),
  };
}

const money = x => (x == null ? "–" : `$${x.toFixed(2)}`);
const kilo = x => (x == null ? "–" : x >= 999950 ? `${(x / 1e6).toFixed(1)}M` : x >= 999.95 ? `${(x / 1e3).toFixed(1)}k` : `${x}`);
const rate = x => (x == null ? "–" : x.toFixed(2));

export function report(s) {
  const causes = {};
  for (const f of s.features_detail.filter(f => !f.passes)) causes[f.cause] = (causes[f.cause] ?? 0) + 1;
  const ms = s.milestones;
  const roles = ["init", "plan", "build", "review", "check", "docs", "verify", "retro"].filter(r => s.cost.by_role[r] != null);
  const tests = s.tests.start != null || s.tests.end != null ? `${s.tests.start ?? "?"} → ${s.tests.end ?? "?"}` : "not recorded";
  const lines = [
    `## ${s.run} · ${s.project}`, "",
    `| | |`, `|---|---|`,
    `| Passing | **${s.features.passing}/${s.features.total}** · verified ${s.features.verified} (${ms.filter(m => m.verified).map(m => m.id).join(", ") || "none"}) · merged ${s.features.merged} (${ms.filter(m => m.merged).map(m => m.id).join(", ") || "none"}) |`,
    `| Tests | ${tests} |`,
    `| Spend | **${money(s.cost.total)}** total · **${money(s.cost.per_passing_feature)}** per passing feature |`,
    `| Spend by role | ${roles.map(r => `${r} ${money(s.cost.by_role[r])}`).join(" · ")} · manager (the bash driver) $0.00 |`,
    // summaries written before E1-06 have no tokens or quality keys: no rows for them
    ...(s.tokens ? [`| Tokens | ${kilo(s.tokens.in + s.tokens.cache_read + s.tokens.cache_write)} in (cache hit ${rate(s.tokens.cache_hit_rate)}) · context peak ${kilo(s.tokens.context_peak)} · orientation ${kilo(s.orientation.tokens)} tokens / ${s.orientation.turns ?? "–"} turns (median) · per verified feature ${kilo(s.per_verified_feature.tokens)} tokens, ${money(s.per_verified_feature.cost)} |`,
      `| Quality | first-attempt pass rate ${rate(s.first_attempt_pass_rate)} · rework ${s.rework.join(", ") || "none"} · verify-fail rate ${rate(s.verify_fail_rate)} |`] : []),
    `| Time | ${s.time.wall_h} h wall: sessions ${s.time.sessions_h} h (${Object.entries(s.time.by_role_h).map(([r, h]) => `${r} ${h}`).join(", ")}), driver ${s.time.driver_h} h |`,
    `| Sessions | ${s.sessions.total} (${s.sessions.real} real, ${s.sessions.environmental} refused by limits/API errors) |`,
    `| Ended | ${s.end_reason}${s.continuations ? ` (after ${s.continuations} continuation${s.continuations > 1 ? "s" : ""})` : ""} |`,
    `| Not passing | ${Object.entries(causes).map(([c, n]) => `${c} ${n}`).join(" · ") || "none"} |`,
  ];
  const open = s.features_detail.filter(f => !f.passes);
  if (open.length) {
    lines.push("", "| Feature | Cause | Detail | Sessions | $ |", "|---|---|---|---|---|");
    for (const f of open) lines.push(`| ${f.id} | ${f.cause} | ${(f.detail ?? "").replace(/\|/g, "/")} | ${f.sessions}${f.refused ? ` + ${f.refused} refused` : ""} | ${money(f.cost)} |`);
  }
  return lines.join("\n");
}

function main([cmd, ...a]) {
  if (cmd === "build") { console.log(JSON.stringify(build(resolve(a[0]), a[1], resolve(a[2])), null, 2)); return 0; }
  if (cmd === "report") { console.log(a.map(p => report(JSON.parse(readFileSync(p, "utf8")))).join("\n\n")); return 0; }
  if (cmd === "ledger-line") {
    const s = JSON.parse(readFileSync(a[0], "utf8"));
    const causes = {};
    for (const f of s.features_detail.filter(f => !f.passes)) causes[f.cause] = (causes[f.cause] ?? 0) + 1;
    const row = { run: s.run, project: s.project, started: s.started, ended_at: s.ended_at, end_reason: s.end_reason,
      continuations: s.continuations, ...s.features, tests_start: s.tests.start, tests_end: s.tests.end,
      cost: s.cost.total, per_passing: s.cost.per_passing_feature, by_role: s.cost.by_role, wall_h: s.time.wall_h,
      sessions: s.sessions, guards: s.guards, causes };
    const rows = jsonl(a[1]).filter(r => r.run !== s.run);
    rows.push(row);
    writeFileSync(a[1], rows.map(r => JSON.stringify(r)).join("\n") + "\n");
    return 0;
  }
  if (cmd === "trends") {
    const rows = jsonl(a[0]);
    console.log("| Run | Project | Passing | Tests | $ | $/feature | Wall h | Ended | Not passing |\n|---|---|---|---|---|---|---|---|---|");
    for (const r of rows) console.log(`| ${r.run} | ${r.project} | ${r.passing}/${r.total} (merged ${r.merged}) | ${r.tests_start ?? "?"} → ${r.tests_end ?? "?"} | ${money(r.cost)} | ${money(r.per_passing)} | ${r.wall_h} | ${r.end_reason} | ${Object.entries(r.causes).map(([c, n]) => `${c} ${n}`).join(", ") || "–"} |`);
    const tot = {};
    for (const r of rows) for (const [c, n] of Object.entries(r.causes)) tot[c] = (tot[c] ?? 0) + n;
    const p = rows.reduce((s, r) => s + r.passing, 0), c = rows.reduce((s, r) => s + r.cost, 0);
    console.log(`\n${rows.length} runs · ${p} features passed · ${money(c)} · ${money(p ? c / p : null)} per passing feature · not passing by cause: ${Object.entries(tot).sort((x, y) => y[1] - x[1]).map(([k, n]) => `${k} ${n}`).join(", ") || "none"}`);
    return 0;
  }
  if (cmd === "calibration") {
    const [dir, project] = a, mins = { all: [], project: [] };
    for (const p of existsSync(dir) ? readdirSync(dir) : []) {
      const pd = join(dir, p);
      if (!existsSync(pd) || p.endsWith(".jsonl")) continue;
      for (const r of readdirSync(pd)) {
        const s = JSON.parse(read(join(pd, r, "summary.json"), "null"));
        for (const f of s?.features_detail ?? []) if (f.passes && f.sessions && f.minutes) {
          mins.all.push(f.minutes); if (p === project) mins.project.push(f.minutes);
        }
      }
    }
    const q = (xs, p) => [...xs].sort((x, y) => x - y)[Math.min(xs.length - 1, Math.floor(p * xs.length))];
    const say = (xs, what) => `${what}: ${xs.length} passing features, median ${q(xs, 0.5)} min, 90th percentile ${q(xs, 0.9)} min`;
    console.log(mins.all.length ? [mins.project.length ? say(mins.project, `this project`) : null, say(mins.all, "all projects")]
      .filter(Boolean).join("; ") + ". Size features against these numbers, not guesses." : "no earlier runs are recorded yet.");
    return 0;
  }
  console.error("usage: summary.mjs build|report|ledger-line|trends|calibration …");
  return 2;
}

if (process.argv[1] && fileURLToPath(import.meta.url) === resolve(process.argv[1])) process.exit(main(process.argv.slice(2)));
