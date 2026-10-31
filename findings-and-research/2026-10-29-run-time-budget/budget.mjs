// Where a harness run's wall-clock time goes, per lane, from three clocks the harness doesn't add up itself:
//   1. the user journal: every harness-<run>[-<lane>]-(s<n>|check-<pid>|svc) scope's Started / Consumed (CPU) lines;
//   2. the run's run.log in its state dir (lanes opened/closed, sessions, pauses, limits, un-passes, flakes);
//   3. the stream logs (state/logs/*.jsonl): tool_use → tool_result per call, duration_ms vs duration_api_ms.
// Every second of a lane's open window lands in one bucket: model, session suite, session other tools, harness before
// a session (init + pre-session suite), harness after it (post-session suite, journal), verify (its suites and sessions),
// waiting (pause, usage limit, needs Michael, stopped), idle (nothing of the above: the unexplained remainder).
//   journalctl --user --since <date> -o json | grep '"MESSAGE":"[^"]*harness-' > journal.jsonl
//   node budget.mjs journal.jsonl ~/.local/state/harness/agent-harness <run>… [--json]
// node ≥ 20, standard library only. Read-only on every input.
import { readFileSync, readdirSync, existsSync } from "node:fs";
import { join } from "node:path";

const args = process.argv.slice(2), asJson = args.includes("--json");
const [journalPath, stateRoot, ...runs] = args.filter(a => a !== "--json");
if (!journalPath || !stateRoot || !runs.length) { console.error("usage: node budget.mjs <journal.jsonl> <state-root> <run>… [--json]"); process.exit(2); }

const ROLE = /^(?:([A-Za-z0-9_]+)-)?(s\d+|check-\d+|svc)$/;   // lib/scope.sh scope_owns: [<lane>-](s<n>|check-<pid>|svc)
const cpuS = s => { let t = 0; for (const [, n, u] of s.matchAll(/([\d.]+)(h|min|s|ms)/g)) t += Number(n) * { h: 3600, min: 60, s: 1, ms: 0.001 }[u]; return t; };
const san = r => r.replace(/[^A-Za-z0-9_-]/g, "-");
const local = s => new Date(s.replace(" ", "T")).getTime();   // run.log stamps are the box's local time
const sum = a => a.reduce((s, x) => s + x, 0);
const clip = (a, b, lo, hi) => Math.max(0, Math.min(b, hi) - Math.max(a, lo));
// the union length of [a,b] intervals, and the union itself (sorted, merged)
const merge = iv => { const s = [...iv].sort((x, y) => x[0] - y[0]), out = []; for (const [a, b] of s) { if (out.length && a <= out.at(-1)[1]) out.at(-1)[1] = Math.max(out.at(-1)[1], b); else out.push([a, b]); } return out; };
const unionLen = iv => sum(merge(iv).map(([a, b]) => b - a));
const fmt = s => `${Math.round(s)}`;
const hms = ms => new Date(ms).toTimeString().slice(0, 8);

// ---- 1. scopes from the journal, assigned to the longest matching run prefix (run X's units never claim run X-2's)
const prefixes = runs.map(r => [r, `harness-${san(r)}-`]).sort((a, b) => b[1].length - a[1].length);
const open = new Map(), scopes = [];
for (const line of readFileSync(journalPath, "utf8").split("\n")) {
  if (!line) continue;
  let e; try { e = JSON.parse(line); } catch { continue; }
  const ts = Number(e.__REALTIME_TIMESTAMP) / 1000, m = e.MESSAGE ?? "";
  let mm;
  if ((mm = m.match(/^Started (harness-\S+)\.scope/))) {
    const unit = mm[1], p = prefixes.find(([, pre]) => unit.startsWith(pre)); if (!p) continue;
    const role = unit.slice(p[1].length).match(ROLE); if (!role) continue;
    open.set(unit, { run: p[0], unit, lane: role[1] ?? "run", kind: role[2] === "svc" ? "svc" : role[2].startsWith("check") ? "check" : "session", start: ts, end: null, cpu: null, stopped: false });
  } else if ((mm = m.match(/^Stopped (harness-\S+)\.scope/))) {
    const s = open.get(mm[1]); if (s) s.stopped = true;
  } else if ((mm = m.match(/^(harness-\S+)\.scope: Consumed (.+?) CPU time/))) {
    const s = open.get(mm[1]); if (!s) continue;
    s.end = ts; s.cpu = cpuS(mm[2]); scopes.push(s); open.delete(mm[1]);
  }
}
// still running (a live run). An ended run's check scope with no Consumed line is a stub suite's: a session ran
// lib/check.sh by hand with a stub HARNESS_CHECK_CMD, under its own HARNESS_SCOPE_PREFIX; the sub-second scope logged no CPU (§10)
for (const s of open.values()) { if (s.kind === "check" && existsSync(join(stateRoot, s.run, "ended"))) continue; s.end = Date.now(); s.openEnded = true; scopes.push(s); }
scopes.sort((a, b) => a.start - b.start);

// ---- 2. the stream logs: per session, tool intervals and the result's two durations
// A full call runs check.sh with no subset argument in at least one segment of a chained command. Each segment (split at
// && || ; newline) loses its redirections (`2>&1`, `> f`, `&>f`) and everything from its first pipe, then check.sh must end it.
const isFullCall = cmd => cmd.split(/&&|\|\||;|\n/).some(seg => /check\.sh$/.test(seg.replace(/\s*(\d*|&)>>?&?\s*\S*/g, " ").replace(/(?<!\|)\|(?!\|).*$/, "").trim()));

function streamLog(file) {
  const uses = new Map(), tools = [], results = [];
  let first = null, last = null, edits = [], lastSuite = null;
  for (const line of readFileSync(file, "utf8").split("\n")) {
    if (!line) continue; let e; try { e = JSON.parse(line); } catch { continue; }
    const ts = e.timestamp ? Date.parse(e.timestamp) : NaN;
    if (!Number.isNaN(ts)) { first ??= ts; last = ts; }
    if (e.type === "result") results.push({ duration_ms: e.duration_ms ?? 0, duration_api_ms: e.duration_api_ms ?? 0, turns: e.num_turns ?? 0 });
    const content = e.message?.content; if (!Array.isArray(content) || e.parent_tool_use_id) continue;   // a subagent's calls sit inside its Agent call
    for (const c of content) {
      if (e.type === "assistant" && c.type === "tool_use") {
        const cmd = c.name === "Bash" ? String(c.input?.command ?? "") : "";
        const suite = c.name === "Bash" && /lib\/check\.sh|tests\/run\.sh|\{\{CHECK\}\}/.test(cmd);
        const full = suite && isFullCall(cmd);
        uses.set(c.id, { id: c.id, name: c.name, ts, suite, full, bg: !!c.input?.run_in_background, timeout: c.input?.timeout ?? null, cmd: cmd.slice(0, 100), file: c.input?.file_path ?? null });
      } else if (e.type === "user" && c.type === "tool_result" && uses.has(c.tool_use_id)) {
        const u = uses.get(c.tool_use_id); const text = (Array.isArray(c.content) ? c.content.map(x => x.text ?? "").join("\n") : String(c.content ?? ""));
        const n = text.match(/(\d+)\/(\d+) checks passed/);   // the runner's total, when the call let it through
        const outcome = /check: green \(cached/.test(text) ? "cached" : /moved to the background/.test(text) ? "moved" : /green after a rerun/.test(text) ? "flake"
          : /check: RED|^FAIL |files that exited non-zero/m.test(text) ? "red" : /check: green in/.test(text) ? "green" : n ? (n[1] === n[2] ? "green" : "red") : "other";
        const t = { ...u, end: ts, s: Number.isNaN(ts) || Number.isNaN(u.ts) ? 0 : (ts - u.ts) / 1000, cached: outcome === "cached", moved: outcome === "moved", outcome, out: text.slice(0, 160) };
        tools.push(t);
        if (t.full && !t.cached) lastSuite = t;
        if (["Edit", "Write", "MultiEdit", "NotebookEdit"].includes(u.name) && u.file) edits.push({ ts: u.ts, file: u.file });
      }
    }
  }
  const api = results.length ? Math.max(...results.map(r => r.duration_api_ms)) / 1000 : null;   // cumulative across a resumed session's results
  return { file, first, last, tools, results, duration_s: sum(results.map(r => r.duration_ms)) / 1000, api_s: api,
    editsAfterSuite: lastSuite ? edits.filter(x => x.ts > lastSuite.ts).map(x => x.file.replace(/^.*?\/(slot-\d+|agent-harness-[\w-]+)\//, "")) : [] };
}

// ---- 3. one run
function analyse(run) {
  const st = join(stateRoot, run), log = readFileSync(join(st, "run.log"), "utf8").split("\n");
  const lines = log.map(l => l.match(/^(\d{4}-\d\d-\d\d \d\d:\d\d:\d\d) (.*)$/)).filter(Boolean).map(m => ({ ts: local(m[1]), msg: m[2] }));
  const my = scopes.filter(s => s.run === run);
  const logs = existsSync(join(st, "logs")) ? readdirSync(join(st, "logs")).filter(f => f.endsWith(".jsonl")).map(f => streamLog(join(st, "logs", f))) : [];
  const laned = my.some(s => s.lane !== "run");
  // lane windows: opened → closed (several per lane across segments); a pre-lane run is one lane, "run", from each start to its end
  const windows = [];
  if (laned) {
    const openAt = new Map();
    for (const l of lines) { let m;
      if ((m = l.msg.match(/^lane (\S+) opened/))) openAt.set(m[1], l.ts);
      else if ((m = l.msg.match(/^lane (\S+) closed/)) && openAt.has(m[1])) { windows.push({ lane: m[1], a: openAt.get(m[1]), b: l.ts }); openAt.delete(m[1]); } }
    for (const [lane, a] of openAt) windows.push({ lane, a, b: Date.now(), live: true });
  } else {
    let a = null; for (const l of lines) { if (/^run \S+ on /.test(l.msg)) a = l.ts; else if (/^run ended/.test(l.msg) && a) { windows.push({ lane: "run", a, b: l.ts }); a = null; } }
    if (a) windows.push({ lane: "run", a, b: Date.now(), live: true });
  }
  // waiting windows at run level: a pause until the next resume/end, a limit until the next session, needs Michael until the run ends
  const waits = [];
  for (let i = 0; i < lines.length; i++) { const l = lines[i], m = l.msg; let w = null;
    if (/^paused/.test(m)) w = /resumed|run ended|stopped by/;
    else if (/hit a limit|usage-limit window|refused \(|deferred until/.test(m)) w = /^session \d+ · |^verify \S+ · |^run ended/;
    else if (/^waiting on Michael|parked \(waiting on Michael\)/.test(m)) w = /^run ended|^lane \S+ opened/;
    if (!w) continue; const j = lines.findIndex((x, k) => k > i && w.test(x.msg)); waits.push({ a: l.ts, b: j < 0 ? Date.now() : lines[j].ts, why: m.slice(0, 60) }); }
  // the log line that started this scope: the lane's own feature first (two lanes start a session in the same second), then the nearest
  const mine = (msg, lane) => lane === "run" ? (/^(initializer|retro) /.test(msg) ? 1 : 0) : (new RegExp(`^session \\d+ · ${lane}-|^(verify|resolve) ${lane} `).test(msg) ? 1 : 0);
  const sessionLine = (ts, lane) => lines.filter(l => Math.abs(l.ts - ts) < 30000 && /^session \d+ · |^verify \S+ · claude|^resolve \S+ · |^initializer · |^retro · /.test(l.msg))
    .sort((x, y) => (mine(y.msg, lane) - mine(x.msg, lane)) || (Math.abs(x.ts - ts) - Math.abs(y.ts - ts)))[0];
  const passLine = (lane, ts) => lines.find(l => l.ts >= ts && l.ts - ts < 120000 && /^\S+ · claude-\S+ · passes=/.test(l.msg));
  const sessions = my.filter(s => s.kind === "session").map(s => {
    const sl = sessionLine(s.start, s.lane)?.msg ?? "", m = sl.match(/^session \d+ · (\S+) · (\S+)/);
    const kind = m ? "coding" : /^verify/.test(sl) ? "verify" : /^resolve/.test(sl) ? "resolve" : /^initializer/.test(sl) ? "init" : /^retro/.test(sl) ? "retro" : "session";
    const feature = m ? m[1] : (sl.match(/^(verify|resolve) (\S+)/)?.[2] ?? null);
    const tag = kind === "coding" ? `-${feature}.jsonl` : kind === "verify" ? `-verify-${feature}.jsonl` : kind === "resolve" ? `-resolve-${feature}.jsonl` : kind === "init" ? "00-init.jsonl" : kind === "retro" ? "zz-retro" : null;
    const stream = logs.filter(l => l.first && Math.abs(l.first - s.start) < 600000 && (!tag || l.file.includes(tag))).sort((x, y) => Math.abs(x.first - s.start) - Math.abs(y.first - s.start))[0] ?? null;
    const checks = my.filter(c => c.kind === "check" && c.lane === s.lane && c.start >= s.start - 1000 && c.start < s.end);
    const fg = stream ? stream.tools.filter(t => t.suite && !t.bg && !t.moved && !t.cached && t.s > 0).map(t => [t.ts, t.end]) : [];
    const suite = unionLen([...checks.map(c => [Math.max(c.start, s.start), Math.min(c.end, s.end)]), ...fg]) / 1000;
    const suiteIv = [...checks.map(c => [Math.max(c.start, s.start), Math.min(c.end, s.end)]), ...fg];   // parallel tool calls overlap: unions, never sums
    const other = stream ? (unionLen([...suiteIv, ...stream.tools.filter(t => !t.suite && t.s > 0).map(t => [t.ts, t.end])]) - unionLen(suiteIv)) / 1000 : 0;
    const wall = (s.end - s.start) / 1000, model = Math.max(0, wall - suite - other);
    const pl = passLine(s.lane, s.end)?.msg ?? "";
    return { ...s, kind, feature, wall, suite, other, model, api_s: stream?.api_s ?? null, duration_s: stream?.duration_s ?? null, checks: checks.length,
      fullRuns: checks.filter(c => c.end - c.start > 120000).length, cachedHits: stream ? stream.tools.filter(t => t.cached).length : 0,
      suiteCalls: stream ? stream.tools.filter(t => t.suite).map(t => ({ s: Math.round(t.s), full: t.full, outcome: t.outcome, timeout: t.timeout, cmd: t.cmd })) : [],
      editsAfterSuite: stream?.editsAfterSuite ?? [], passes: /passes=true/.test(pl) ? true : /passes=false/.test(pl) ? false : null,
      unpassed: lines.some(l => l.ts >= s.end && l.ts - s.end < 1800000 && l.msg.startsWith(`${feature} un-passed`)) };
  });
  // the harness's own suites: checks outside every session, by what they sit next to
  const harnessChecks = my.filter(c => c.kind === "check" && !sessions.some(s => s.lane === c.lane && c.start >= s.start - 1000 && c.start < s.end)).map(c => {
    const prev = sessions.filter(s => s.lane === c.lane && s.end <= c.start + 1000).sort((x, y) => y.end - x.end)[0];
    const next = sessions.filter(s => s.lane === c.lane && s.start >= c.end - 1000).sort((x, y) => x.start - y.start)[0];
    const cleared = lines.some(l => /suite cache cleared/.test(l.msg) && l.ts <= c.start + 1000 && c.start - l.ts < 60000);
    let where = "before";
    if (prev && c.start - prev.end < 15000) where = prev.kind === "verify" ? "verify" : "after";
    else if (cleared || next?.kind === "verify") where = "verify";
    else if (!next && !laned) where = "after";
    const rerun = my.some(o => o !== c && o.unit === c.unit && o.end <= c.start + 1000);   // the same unit started again: check.sh's rerun
    return { ...c, where, rerun, prev: prev?.feature ?? null, next: next?.feature ?? null, wall: (c.end - c.start) / 1000 };
  });
  // the budget per lane window
  const lanes = windows.map(w => {
    const inW = s => s.lane === w.lane && s.end > w.a && s.start < w.b;
    const ss = sessions.filter(inW), hc = harnessChecks.filter(inW);
    const b = { model: 0, session_suite: 0, session_other: 0, harness_before: 0, harness_after: 0, verify: 0, waiting: 0, idle: 0 };
    for (const s of ss) { const f = clip(s.start, s.end, w.a, w.b) / (s.end - s.start) || 0;
      if (s.kind === "verify" || s.kind === "resolve") b.verify += s.wall * f; else { b.model += s.model * f; b.session_suite += s.suite * f; b.session_other += s.other * f; } }
    for (const c of hc) { const t = clip(c.start, c.end, w.a, w.b) / 1000; b[c.where === "verify" ? "verify" : c.where === "after" ? "harness_after" : "harness_before"] += t; }
    // gaps: the window minus sessions and harness checks
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
    const total = (w.b - w.a) / 1000;
    return { lane: w.lane, from: hms(w.a), to: hms(w.b), live: !!w.live, total, buckets: b, idle: idle.sort((x, y) => y.s - x.s).slice(0, 5), sessions: ss.length };
  });
  const runLevel = my.filter(s => s.lane === "run" && laned);   // init, retro and the driver's own suites outside every lane
  return { run, laned, lanes, sessions, harnessChecks, runLevel: runLevel.map(s => ({ unit: s.unit, kind: s.kind, start: hms(s.start), wall: (s.end - s.start) / 1000, cpu: s.cpu })),
    flakes: existsSync(join(st, "green", "flakes.jsonl")) ? readFileSync(join(st, "green", "flakes.jsonl"), "utf8").split("\n").filter(Boolean).length : 0,
    checksAll: my.filter(s => s.kind === "check").map(s => ({ unit: s.unit, lane: s.lane, start: s.start, end: s.end, wall: (s.end - s.start) / 1000, cpu: s.cpu, stopped: s.stopped })) };
}

// ---- 4. the load curve the journal already holds: every check scope over 120 s against how many other check scopes (any run) overlapped it
function concurrency(all) {
  return all.filter(c => c.kind === "check" && c.end - c.start > 120000).map(c => {
    const others = all.filter(o => o !== c && o.kind === "check" && o.start < c.end && o.end > c.start);
    const overlap = sum(others.map(o => clip(o.start, o.end, c.start, c.end))) / (c.end - c.start);
    return { unit: c.unit, start: hms(c.start), wall: (c.end - c.start) / 1000, cpu: c.cpu, overlap: Math.round(overlap * 100) / 100 };
  });
}

const out = runs.map(analyse);
if (asJson) { console.log(JSON.stringify({ runs: out, concurrency: concurrency(scopes) }, null, 1)); process.exit(0); }
for (const r of out) {
  console.log(`\n== ${r.run}${r.laned ? "" : " (no lanes: the run is one lane)"}  flakes ${r.flakes}`);
  for (const l of r.lanes) {
    const b = l.buckets, pc = k => `${fmt(b[k])} s (${Math.round(b[k] / l.total * 100)}%)`;
    console.log(`lane ${l.lane} ${l.from}–${l.to}${l.live ? " (live)" : ""}: ${fmt(l.total)} s, ${l.sessions} sessions`);
    console.log(`  model ${pc("model")} · session suite ${pc("session_suite")} · session other tools ${pc("session_other")} · harness before ${pc("harness_before")} · harness after ${pc("harness_after")} · verify ${pc("verify")} · waiting ${pc("waiting")} · idle ${pc("idle")}`);
    if (l.idle.length) console.log(`  largest idle: ${l.idle.map(i => `${i.from}–${i.to} ${i.s} s`).join(", ")}`);
  }
  console.log("sessions (wall · suite · other tools · model · stream duration_ms · duration_api_ms · suite calls):");
  for (const s of r.sessions) console.log(`  ${s.lane} ${s.kind} ${s.feature ?? ""} ${hms(s.start)} wall ${fmt(s.wall)} suite ${fmt(s.suite)} other ${fmt(s.other)} model ${fmt(s.model)} · dur ${s.duration_s == null ? "?" : fmt(s.duration_s)} api ${s.api_s == null ? "?" : fmt(s.api_s)} · full ${s.fullRuns} cached ${s.cachedHits}${s.passes == null ? "" : ` passes=${s.passes}`}${s.unpassed ? " UN-PASSED" : ""}${s.editsAfterSuite.length ? ` edits after suite: ${[...new Set(s.editsAfterSuite)].join(" ")}` : ""}${s.suiteCalls.length ? ` · calls: ${s.suiteCalls.map(c => `${c.full ? "F" : "s"}:${c.outcome}${c.full ? "/" + c.s + "s" : ""}`).join(" ")}` : ""}`);
  console.log("harness suites outside sessions (where · wall · cpu · rerun):");
  for (const c of r.harnessChecks) console.log(`  ${c.lane} ${c.where} ${hms(c.start)} ${fmt(c.wall)} s cpu ${fmt(c.cpu)} s${c.rerun ? " rerun" : ""}${c.prev ? ` after ${c.prev}` : ""}${c.next ? ` before ${c.next}` : ""}`);
  if (r.runLevel.length) console.log(`run-level scopes: ${r.runLevel.map(s => `${s.kind} ${s.start} ${fmt(s.wall)} s`).join(", ")}`);
}
console.log("\nload curve from the journal (full suites: wall s, CPU s, mean other suites overlapping):");
for (const c of concurrency(scopes)) console.log(`  ${c.start} ${c.unit.replace(/^harness-agent-harness-/, "")} wall ${fmt(c.wall)} cpu ${fmt(c.cpu)} overlap ${c.overlap}`);
