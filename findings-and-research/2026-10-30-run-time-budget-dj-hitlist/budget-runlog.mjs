// budget.mjs for runs older than lib/scope.sh (2026-10-25): the journal holds no harness-<run>-* scope for them, so
// sessions come from run.log's start and exit lines, the sessions' suite runs from their stream logs (a backgrounded
// call ends at its task's task_updated end_time), and the harness's own suites from the green-<key> markers (check.sh
// touches one at the end of every green full run; a red full run leaves none). The buckets are budget.mjs's.
//   node budget-runlog.mjs <state-dir>/<run>… [--json]      (--json is budget.mjs's shape: totals.mjs reads it)
// node ≥ 20, standard library only. Read-only on every input. No CPU: only a scope recorded it.
import { readFileSync, readdirSync, existsSync, statSync } from "node:fs";
import { join, basename } from "node:path";

const args = process.argv.slice(2), asJson = args.includes("--json");
const dirs = args.filter(a => a !== "--json");
if (!dirs.length) { console.error("usage: node budget-runlog.mjs <state-dir>/<run>… [--json]"); process.exit(2); }

const local = s => new Date(s.replace(" ", "T")).getTime();   // run.log stamps are the box's local time
const sum = a => a.reduce((s, x) => s + x, 0);
const clip = (a, b, lo, hi) => Math.max(0, Math.min(b, hi) - Math.max(a, lo));
const merge = iv => { const s = [...iv].sort((x, y) => x[0] - y[0]), out = []; for (const [a, b] of s) { if (out.length && a <= out.at(-1)[1]) out.at(-1)[1] = Math.max(out.at(-1)[1], b); else out.push([a, b]); } return out; };
const unionLen = iv => sum(merge(iv).map(([a, b]) => b - a));
const fmt = s => `${Math.round(s)}`;
const hms = ms => new Date(ms).toTimeString().slice(0, 8);
// a suite call: the harness's check.sh, the project's own (dj: .harness/check.sh = pytest), or its parts (hit_list:
// expo lint, tsc, jest). Full: check.sh with no subset argument, or hit_list's CHECK_CMD spelled out.
// Only at a command position: `grep … lib/check.sh` or `pgrep -af pytest` reads, it doesn't run.
const AT = String.raw`(?:^|[;&|(\n]|\$\()\s*(?:[A-Z_]+=\S*\s+|timeout\s+\S+\s+|bash\s+|python3 -m\s+)*(?:\S*\/)?`;
const SUITE = new RegExp(AT + String.raw`(?:lib\/check\.sh|\.harness\/check\.sh|\{\{CHECK\}\}|pytest\b|npx (?:jest|tsc|expo lint)\b|npm (?:run )?test\b)`);
// Any check.sh run in the command with no argument (a subset then the full suite is one call). budget.mjs's own test
// reads `check.sh 2>&1` as a subset (the 2 passes [A-Za-z0-9]) and a chain as a subset when any check.sh in it has one.
const FULL = new RegExp(AT + String.raw`(?:lib|\.harness)\/check\.sh(?=\s*(?:\d*>|\||;|&&|\)|$))`, "m");
const isFull = cmd => FULL.test(cmd)
  || /npx expo lint && npx tsc --noEmit && npx jest( --silent)?\s*($|[|;&>2)])/.test(cmd);

// ---- the stream log: top-level tool intervals; a backgrounded (or moved) call runs to its task's end_time
function streamLog(file) {
  const uses = new Map(), tools = [], results = [], taskOf = new Map(), endOf = new Map(), statusOf = new Map();
  let first = null;
  const lines = readFileSync(file, "utf8").split("\n").filter(Boolean).map(l => { try { return JSON.parse(l); } catch { return null; } }).filter(Boolean);
  for (const e of lines) if (e.type === "system" && e.task_id) {
    if (e.subtype === "task_started" && e.tool_use_id) taskOf.set(e.tool_use_id, e.task_id);
    if (e.subtype === "task_updated" && e.patch?.end_time) endOf.set(e.task_id, e.patch.end_time);
    if (e.subtype === "task_notification" && e.status) statusOf.set(e.task_id, e.status);
  }
  for (const e of lines) {
    const ts = e.timestamp ? Date.parse(e.timestamp) : NaN;
    if (!Number.isNaN(ts)) first ??= ts;
    if (e.type === "result") results.push({ duration_ms: e.duration_ms ?? 0, duration_api_ms: e.duration_api_ms ?? 0 });
    const content = e.message?.content; if (!Array.isArray(content) || e.parent_tool_use_id) continue;
    for (const c of content) {
      if (e.type === "assistant" && c.type === "tool_use") {
        const cmd = c.name === "Bash" ? String(c.input?.command ?? "") : "";
        const suite = c.name === "Bash" && SUITE.test(cmd);
        uses.set(c.id, { id: c.id, name: c.name, ts, suite, full: suite && isFull(cmd), bg: !!c.input?.run_in_background, cmd: cmd.slice(0, 100) });
      } else if (e.type === "user" && c.type === "tool_result" && uses.has(c.tool_use_id)) {
        const u = uses.get(c.tool_use_id), text = Array.isArray(c.content) ? c.content.map(x => x.text ?? "").join("\n") : String(c.content ?? "");
        const task = taskOf.get(u.id), tEnd = task ? endOf.get(task) : undefined;
        const detached = /Command running in background|moved to the background/.test(text);
        const n = text.match(/(\d+)\/(\d+) checks passed|Tests:\s+(?:(\d+) failed, )?\d+ passed/);
        const outcome = /check: green \(cached/.test(text) ? "cached" : detached ? "background"
          : /check: RED|^FAILED |\d+ failed/m.test(text) ? "red" : /check: green in|\d+ passed/.test(text) ? "green" : n ? "green" : "other";
        const end = detached ? (tEnd ?? NaN) : Math.max(ts, tEnd ?? 0);
        if (/check: green in \d+ s|check: RED \(exit/.test(text)) u.full = true;   // check.sh's own line: a full run whatever the command looked like
        tools.push({ ...u, end, resultTs: ts, s: Number.isNaN(end) || Number.isNaN(u.ts) ? 0 : (end - u.ts) / 1000, outcome,
          taskStatus: task ? statusOf.get(task) ?? null : null, greenIn: Number(text.match(/check: green in (\d+) s/)?.[1] ?? NaN) });
      }
    }
  }
  const api = results.length ? Math.max(...results.map(r => r.duration_api_ms)) / 1000 : null;
  return { file, first, tools, api_s: api, duration_s: sum(results.map(r => r.duration_ms)) / 1000 };
}

// ---- one run
function analyse(st) {
  const run = basename(st);
  const lines = readFileSync(join(st, "run.log"), "utf8").split("\n").map(l => l.match(/^(\d{4}-\d\d-\d\d \d\d:\d\d:\d\d) (.*)$/)).filter(Boolean).map(m => ({ ts: local(m[1]), msg: m[2] }));
  const logs = existsSync(join(st, "logs")) ? readdirSync(join(st, "logs")).filter(f => f.endsWith(".jsonl")).map(f => streamLog(join(st, "logs", f))) : [];
  const markers = existsSync(join(st, "green")) ? readdirSync(join(st, "green")).filter(f => f.startsWith("green-")).map(f => statSync(join(st, "green", f)).mtimeMs) : [];
  const windows = []; { let a = null;   // a pre-lane run is one lane, "run", from each start to its end
    for (const l of lines) { if (/^run \S+ on /.test(l.msg)) a = l.ts; else if (/^run ended/.test(l.msg) && a) { windows.push({ lane: "run", a, b: l.ts }); a = null; } } }
  const waits = [];
  for (let i = 0; i < lines.length; i++) { const l = lines[i], m = l.msg; let w = null;
    if (/^paused/.test(m)) w = /resumed|run ended|stopped by/;
    else if (/hit a limit|usage-limit window|refused \(|deferred until/.test(m)) w = /^session \d+ · |^verify \S+ · |^run ended/;
    else if (/^waiting on Michael|parked \(waiting on Michael\)/.test(m)) w = /^run ended|^lane \S+ opened/;
    if (!w) continue; const j = lines.findIndex((x, k) => k > i && w.test(x.msg)); waits.push({ a: l.ts, b: j < 0 ? lines.at(-1).ts : lines[j].ts }); }
  // sessions: a start line to the next exit line of its kind
  const START = [[/^session \d+ · (\S+) · /, "coding", "coding"], [/^verify (\S+) · claude/, "verify", "verify"], [/^resolve (\S+) · /, "resolve", "resolve"], [/^initializer · /, "init", "init"], [/^retro · /, "retro", "retro"]];
  const sessions = [];
  for (let i = 0; i < lines.length; i++) for (const [re, kind, ex] of START) { const m = lines[i].msg.match(re); if (!m) continue;
    const j = lines.findIndex((x, k) => k > i && new RegExp(`^  ${ex} exit `).test(x.msg)); if (j < 0) continue;
    const feature = m[1] ?? null, start = lines[i].ts, end = lines[j].ts;
    const tag = kind === "coding" ? `-${feature}.jsonl` : kind === "verify" ? `-verify-${feature}.jsonl` : kind === "resolve" ? `-resolve-${feature}.jsonl` : kind === "init" ? "00-init.jsonl" : "zz-retro";
    const stream = logs.filter(l => l.first && Math.abs(l.first - start) < 600000 && l.file.includes(tag)).sort((x, y) => Math.abs(x.first - start) - Math.abs(y.first - start))[0] ?? null;
    const calls = stream ? stream.tools.filter(t => t.suite && t.outcome !== "cached" && t.s > 0) : [];
    for (const t of calls.filter(t => t.full)) {   // a backgrounded full run is green when a marker was touched at its end
      if (t.outcome === "background") t.outcome = t.taskStatus === "stopped" ? "killed" : markers.some(m => Math.abs(m - t.end) < 5000) ? "green" : t.taskStatus === "failed" ? "red" : "other"; }
    const suiteIv = calls.map(t => [t.ts, Math.min(t.end, end)]).filter(([a, b]) => b > a);
    const suite = unionLen(suiteIv) / 1000;
    const other = stream ? (unionLen([...suiteIv, ...stream.tools.filter(t => !t.suite && t.s > 0 && !Number.isNaN(t.resultTs)).map(t => [t.ts, Math.min(t.resultTs, end)])]) - unionLen(suiteIv)) / 1000 : 0;
    const wall = (end - start) / 1000, model = Math.max(0, wall - suite - other);
    const pl = lines.find(l => l.ts >= end && l.ts - end < 120000 && /^\S+ · claude-\S+ · passes=/.test(l.msg))?.msg ?? "";
    // full runs: the green ones are the markers touched inside the session (check.sh's own record; a call can hide one
    // behind a wait loop), the rest the full calls that ended without one (killed, red, cut off)
    const greenMarkers = markers.filter(m => m > start + 2000 && m < end).length;
    const full = calls.filter(t => t.full && t.outcome !== "green");
    sessions.push({ run, lane: "run", kind, feature, start, end, wall, suite, other, model, api_s: stream?.api_s ?? null, duration_s: stream?.duration_s ?? null,
      stream: stream ? basename(stream.file) : null, fullRuns: greenMarkers + full.length, greenMarkers, greenCalls: calls.filter(t => t.full && t.outcome === "green").length, cachedHits: stream ? stream.tools.filter(t => t.outcome === "cached").length : 0,
      suiteCalls: stream ? stream.tools.filter(t => t.suite).map(t => ({ s: Math.round(t.s), full: t.full, outcome: t.outcome, start: t.ts, end: t.end, greenIn: t.greenIn, cmd: t.cmd })) : [],
      passes: /passes=true/.test(pl) ? true : /passes=false/.test(pl) ? false : null,
      unpassed: lines.some(l => l.ts >= end && l.ts - end < 1800000 && l.msg.startsWith(`${feature} un-passed`)) });
    break; }
  sessions.sort((a, b) => a.start - b.start);
  // the harness's own suites: markers outside every session and not the end of a session's own (outliving) run
  const inSession = m => sessions.some(s => m > s.start + 2000 && m < s.end);   // the driver logs a session's start right after its pre-session suite
  const sessionEnds = sessions.flatMap(s => s.suiteCalls.filter(c => c.full).map(c => c.end));
  const hm = markers.filter(m => windows.some(w => m >= w.a && m <= w.b) && !inSession(m) && !sessionEnds.some(e => Math.abs(e - m) < 5000)).sort((a, b) => a - b);
  const harnessChecks = hm.map((m, i) => {
    const w = windows.find(w => m >= w.a && m <= w.b);
    const prev = sessions.filter(s => s.end <= m).sort((x, y) => y.end - x.end)[0];
    const next = sessions.filter(s => s.start >= m - 2000).sort((x, y) => x.start - y.start)[0];
    const start = Math.max(w.a, prev?.end ?? 0, i ? hm[i - 1] : 0);   // an upper bound: from the gap's start (or the marker before)
    let where = "before";
    if (prev && start - prev.end < 15000 && prev.end > w.a) where = prev.kind === "verify" ? "verify" : prev.kind === "coding" ? "after" : "before";
    else if (next?.kind === "verify") where = "verify";
    return { run, lane: "run", unit: `${run}-marker-${i}`, kind: "check", start, end: m, wall: (m - start) / 1000, cpu: null, where, rerun: false, prev: prev?.feature ?? prev?.kind ?? null, next: next?.feature ?? next?.kind ?? null };
  });
  const lanes = windows.map(w => {
    const inW = s => s.end > w.a && s.start < w.b;
    const ss = sessions.filter(inW), hc = harnessChecks.filter(inW);
    const b = { model: 0, session_suite: 0, session_other: 0, harness_before: 0, harness_after: 0, verify: 0, waiting: 0, idle: 0 };
    for (const s of ss) { const f = clip(s.start, s.end, w.a, w.b) / (s.end - s.start) || 0;
      if (s.kind === "verify" || s.kind === "resolve") b.verify += s.wall * f; else { b.model += s.model * f; b.session_suite += s.suite * f; b.session_other += s.other * f; } }
    for (const c of hc) b[c.where === "verify" ? "verify" : c.where === "after" ? "harness_after" : "harness_before"] += clip(c.start, c.end, w.a, w.b) / 1000;
    const covered = merge([...ss, ...hc].map(x => [Math.max(x.start, w.a), Math.min(x.end, w.b)]));
    const gaps = []; let t = w.a; for (const [a, c] of covered) { if (a > t) gaps.push([t, a]); t = Math.max(t, c); } if (t < w.b) gaps.push([t, w.b]);
    const idle = [];
    for (const [a, c] of gaps) {
      const wait = unionLen(waits.map(x => [Math.max(a, x.a), Math.min(c, x.b)]).filter(([p, q]) => q > p)) / 1000, len = (c - a) / 1000 - wait;
      b.waiting += wait;
      const after = [...ss, ...hc].some(x => Math.abs(x.end - a) < 1500), before = [...ss, ...hc].some(x => Math.abs(x.start - c) < 1500);
      if (len <= 0) continue;
      if (len <= 300 && (after || before)) { if (after && !before) b.harness_after += len; else if (before && !after) b.harness_before += len; else { b.harness_after += len / 2; b.harness_before += len / 2; } }
      else { b.idle += len; idle.push({ from: hms(a), to: hms(c), s: Math.round(len) }); }
    }
    return { lane: w.lane, from: hms(w.a), to: hms(w.b), live: false, total: (w.b - w.a) / 1000, buckets: b, idle: idle.sort((x, y) => y.s - x.s).slice(0, 5), sessions: ss.length };
  });
  return { run, laned: false, lanes, sessions, harnessChecks, runLevel: [], flakes: 0, markers: markers.length };
}

// ---- every full suite run (sessions' and the harness's) against the others of every run given: solo or paired
function concurrency(out) {
  const all = out.flatMap(r => [...r.sessions.flatMap(s => s.suiteCalls.filter(c => c.full && c.outcome !== "cached" && c.s > 0).map(c => ({ unit: `${r.run} ${s.feature ?? s.kind}`, start: c.start, end: c.end, greenIn: c.greenIn, outcome: c.outcome }))),
    ...r.harnessChecks.map(c => ({ unit: `${r.run} harness-${c.where}`, start: c.start, end: c.end, outcome: "green", bound: true }))]);
  return all.map(c => {
    const others = all.filter(o => o !== c && o.start < c.end && o.end > c.start);
    return { unit: c.unit, start: hms(c.start), wall: (c.end - c.start) / 1000, cpu: null, greenIn: c.greenIn ?? null, outcome: c.outcome, upperBound: !!c.bound,
      overlap: Math.round(sum(others.map(o => clip(o.start, o.end, c.start, c.end))) / (c.end - c.start) * 100) / 100, with: [...new Set(others.map(o => o.unit.split(" ")[0]))] };
  });
}

const out = dirs.map(analyse);
if (asJson) { console.log(JSON.stringify({ runs: out, concurrency: concurrency(out) }, null, 1)); process.exit(0); }
for (const r of out) {
  console.log(`\n== ${r.run} (no lanes: the run is one lane)  green markers ${r.markers}`);
  for (const l of r.lanes) {
    const b = l.buckets, pc = k => `${fmt(b[k])} s (${Math.round(b[k] / l.total * 100)}%)`;
    console.log(`lane ${l.lane} ${l.from}–${l.to}: ${fmt(l.total)} s, ${l.sessions} sessions`);
    console.log(`  model ${pc("model")} · session suite ${pc("session_suite")} · session other tools ${pc("session_other")} · harness before ${pc("harness_before")} · harness after ${pc("harness_after")} · verify ${pc("verify")} · waiting ${pc("waiting")} · idle ${pc("idle")}`);
    if (l.idle.length) console.log(`  largest idle: ${l.idle.map(i => `${i.from}–${i.to} ${i.s} s`).join(", ")}`);
  }
  console.log("sessions (wall · suite · other tools · model · stream duration_ms · duration_api_ms · full runs · suite calls):");
  for (const s of r.sessions) console.log(`  ${s.kind} ${s.feature ?? ""} ${hms(s.start)} wall ${fmt(s.wall)} suite ${fmt(s.suite)} other ${fmt(s.other)} model ${fmt(s.model)} · dur ${s.duration_s == null ? "?" : fmt(s.duration_s)} api ${s.api_s == null ? "?" : fmt(s.api_s)} · full ${s.fullRuns} cached ${s.cachedHits}${s.passes == null ? "" : ` passes=${s.passes}`}${s.unpassed ? " UN-PASSED" : ""}${s.suiteCalls.some(c => c.full) ? ` · full: ${s.suiteCalls.filter(c => c.full).map(c => `${c.outcome}/${c.s}s`).join(" ")}` : ""}`);
  console.log("harness suites outside sessions (where · wall from the gap's start to the green marker, an upper bound):");
  for (const c of r.harnessChecks) console.log(`  ${c.where} ${hms(c.start)}–${hms(c.end)} ${fmt(c.wall)} s${c.prev ? ` after ${c.prev}` : ""}${c.next ? ` before ${c.next}` : ""}`);
}
console.log("\nfull suite runs (wall s; check.sh's own 'green in' s; mean other full runs overlapping; the runs they overlapped):");
for (const c of concurrency(out)) console.log(`  ${c.start} ${c.unit} ${c.outcome} wall ${fmt(c.wall)}${c.upperBound ? " (bound)" : ""}${Number.isNaN(c.greenIn) || c.greenIn == null ? "" : ` green-in ${c.greenIn}`} overlap ${c.overlap}${c.with.length ? ` with ${c.with.join(",")}` : ""}`);
