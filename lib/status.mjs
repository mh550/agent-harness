// `harness status`'s data: the run, needs and queue objects from the state dirs, the ledger and the queue, in one node
// process (decisions/2026-10-27-read-views). No dependencies but ./view.mjs.
//
//   view [--all] [--since <d>] [--project <p>] [--verbose <N>] [--json]
//                                                        → the default view (text: four sections and a footer), or v1
//   card <run> --json                                    → that one run's object, with v
//   always: --runner 0|1 --queue <dir> --ledger <dir> --state-root <dir> --max-parallel <k> --since-default <d>
//   stdin: one line per run, "<run>\t<project>\t<state dir>\t<worktree>\t<record dir>\t<alive 0|1|2>[\t<unit>=<bytes>,…]"
//          (alive 2: ending, the driver is in finish; field 7: the run's live units, when bash collected them)
// Read-only: it reads ended, PAUSE, LIMIT_UNTIL, port, tests-*, run.log, metrics.jsonl, the feature list, attempts.json,
// parked.json, the milestone markers, lanes/<m>/, summary.json (state dir → record → ledger copy) and the queue dir.
import { existsSync, readFileSync, readdirSync, statSync } from "node:fs";
import { basename, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { ago, context, cut, displayWidth, duration, endClass, glyph, home, paint, section, rule, table } from "./view.mjs";

const text = p => { try { return readFileSync(p, "utf8"); } catch { return null; } };
const json = p => { try { return JSON.parse(readFileSync(p, "utf8")); } catch { return null; } };   // missing or bad: ignored
const mtime = p => { try { return Math.floor(statSync(p).mtimeMs / 1000); } catch { return null; } };
const ls = d => { try { return readdirSync(d).sort(); } catch { return []; } };
const line = p => text(p)?.trim() || null;
const num = p => { const t = line(p); return t && /^-?\d+(\.\d+)?$/.test(t) ? Number(t) : null; };
const iso = e => e == null ? null : new Date(e * 1000).toISOString();
const secs = s => s == null ? null : Date.parse(s) / 1000;
const r2 = n => Math.round(n * 100) / 100;
// log's "YYYY-MM-DD HH:MM:SS" (local time) → epoch seconds
const stamp = s => { const m = /^(\d{4})-(\d\d)-(\d\d) (\d\d):(\d\d):(\d\d)/.exec(s ?? "");
  return m ? new Date(+m[1], m[2] - 1, +m[3], +m[4], +m[5], +m[6]).getTime() / 1000 : null; };
// kill -0's answer: EPERM is a live process someone else owns
const live = pid => { if (!/^\d+$/.test(pid ?? "")) return false; try { process.kill(Number(pid), 0); return true; } catch (e) { return e.code === "EPERM"; } };
// scope_unit (lib/scope.sh): harness-<run>[-<milestone>], whose roles are s<n>, check-<pid>, svc
const unitOf = (run, m) => `harness-${run.replace(/[^A-Za-z0-9_-]/g, "-")}${m ? "-" + m.replace(/[^A-Za-z0-9_]/g, "_") : ""}`;
const ROLE = /^(s\d+|check-\d+|svc)$/;

/** The one I/O step: everything status shows about one run, read from its files (each missing file tolerated). */
export function readRun(row, { stateRoot = "", ledger = "" } = {}) {
  const [run, project, state, worktree, record, alive = "0", units = ""] = row.split("\t");
  const s = p => join(state, p);
  const lanes = ls(s("lanes")).map(m => { const l = p => join(state, "lanes", m, p);
    return { milestone: m, live: live(line(l("pid"))), now: line(l("now")), port: num(l("port")), slot: line(l("slot")), need: line(l("need")) }; });
  const markers = ls(state).map(f => /^(verified|merged|needs|refused|conflict)-(.+)$/.exec(f)).filter(Boolean)
    .map(([f, kind, m]) => ({ kind, milestone: m, at: mtime(s(f)) }));
  const rows = (text(join(record, "metrics.jsonl")) ?? text(s("metrics.jsonl")) ?? "").split("\n").filter(Boolean)
    .map(l => { try { return JSON.parse(l); } catch { return null; } }).filter(Boolean);
  const a = Number(alive) || 0;
  // an ended run's: finish writes the record's; the state dir's is the last harness report's (an earlier segment's
  // after a continue), the ledger's what is left once gc removed the worktree
  const summary = a || !existsSync(s("ended")) ? null : [join(record, "summary.json"), s("summary.json"), join(ledger, project, run, "summary.json")]
    .map(json).find(Boolean) ?? null;
  return {
    run, project, state_dir: state, worktree, record, alive: a, worktree_exists: existsSync(worktree),
    units: units.split(",").filter(Boolean).map(u => { const i = u.lastIndexOf("="); return { unit: u.slice(0, i), bytes: Number(u.slice(i + 1)) }; }),
    ended: text(s("ended")), ended_mtime: mtime(s("ended")), pause: existsSync(s("PAUSE")), driver_pid: existsSync(s("driver.pid")),
    limit_until: num(join(stateRoot, "LIMIT_UNTIL")), port: num(s("port")), tests: { start: num(s("tests-start")), end: num(s("tests-end")) },
    log: text(s("run.log")) ?? "", log_mtime: mtime(s("run.log")), metrics: rows,
    list: json(join(record, "feature_list.json")), attempts: json(s("attempts.json")), attempts_mtime: mtime(s("attempts.json")),
    max_attempts: num(s("max-attempts")) ?? 2, parked: json(s("parked.json")), markers, lanes, summary,
  };
}

const features = x => { const l = x.list; return Array.isArray(l) ? l : l?.features ?? []; };
const has = (x, kind, m) => x.markers.some(k => k.kind === kind && k.milestone === m);

// "<reason> · YYYY-MM-DD HH:MM:SS" as finish and the EXIT trap write it; a bare reason is dated by the file
function ended(x) {
  if (x.ended == null) return null;
  const t = x.ended.trim(), m = / · (\d{4}-\d\d-\d\d \d\d:\d\d:\d\d)$/.exec(t);
  return m ? { reason: t.slice(0, m.index), at: stamp(m[1]) } : { reason: t, at: x.ended_mtime };
}

function state(x, now) {
  if (x.alive === 2) return "ending";
  if (x.alive === 1) return x.pause ? "paused" : x.limit_until > now ? "limit_wait" : "running";
  return x.ended != null ? "ended" : "crashed";   // no end reason and no live driver: killed, or never got going
}

/** Pure: what waits on Michael in this run (U1 derives it; U2's records replace the source). A gc'd run has none. */
export function needsItems(x, now) {
  if (!x.worktree_exists) return [];
  const fs = features(x), passing = new Set(fs.filter(f => f.passes).map(f => f.id));
  const ms = id => fs.find(f => f.id === id)?.milestone ?? null;
  const item = (reason, kind, feature, milestone, at, headline) => ({ run: x.run, project: x.project, feature, milestone, reason, kind,
    severity: "block", at, title: `[${x.run}] ${feature ?? milestone ?? ""}`.trimEnd() + " needs you", card: { headline } });
  const parked = Object.entries(x.parked ?? {}).filter(([id]) => !passing.has(id));
  const out = parked.map(([id, v]) => item("parked", "park", id, ms(id), v?.at ?? null, `${id} parked: ${String(v?.why ?? "").split("\n")[0]}`));
  // a live lane's feature is on its last attempt (the lane bumps attempts.json before the session), not given up
  const working = new Set(x.alive ? x.lanes.filter(l => l.live && l.now).map(l => l.now.split(" · ")[0]) : []);
  for (const [id, n] of Object.entries(x.attempts ?? {}))
    if (n >= x.max_attempts && !passing.has(id) && !parked.some(([p]) => p === id) && !working.has(id))
      out.push(item("given_up", "blocked", id, ms(id), iso(x.attempts_mtime), `${id} given up (${n} attempts)`));
  for (const k of x.markers) {
    if (has(x, "merged", k.milestone)) continue;
    const m = k.milestone, at = iso(k.at);
    if (k.kind === "needs") out.push(item("needs_michael", "needs_michael", null, m, at, `${m} needs you: ${x.lanes.find(l => l.milestone === m)?.need ?? "see harness-log.md"}`));
    if (k.kind === "refused") out.push(item("merge_refused", "needs_michael", null, m, at, `${m} merge refused`));
    if (k.kind === "conflict") out.push(item("merge_conflict", "needs_michael", null, m, at, `${m} conflicts with main`));
  }
  // one run-level item at most, and none when a feature or milestone item covers the run ("waiting on Michael: B" is B's)
  const st = state(x, now), e = ended(x);
  if (!out.length && st === "ended" && ["waiting", "failed"].includes(endClass(e.reason))) out.push(item("run_end", "needs_michael", null, null, iso(e.at), e.reason));
  if (!out.length && st === "crashed" && x.driver_pid) out.push(item("driver_crash", "needs_michael", null, null, iso(x.log_mtime), "driver gone without an end reason"));
  return out;
}

const byNeed = (a, b) => (a.severity === b.severity ? 0 : a.severity === "block" ? -1 : 1) || (a.at ?? "~").localeCompare(b.at ?? "~");

/** Pure: the run object of `harness status --json` (v1) from readRun's facts. */
export function runObject(x, now) {
  const st = state(x, now), e = st === "ended" ? ended(x) : null, sum = x.summary;
  const starts = [...x.log.matchAll(/^(\S+ \S+) run \S+ on /gm)].map(m => stamp(m[1]));
  const sess = [...x.log.matchAll(/^(\S+ \S+) session (\d+) · (\S+) · (\S+)$/gm)].at(-1);
  // the run's count of sessions (spec default 3): metrics rows plus the one running, never $STATE/sessions (the
  // driver resets it each segment)
  const running = x.alive && sess && stamp(sess[1]) >= (starts.at(-1) ?? 0) ? 1 : 0;
  const session = x.metrics.length + running || null;
  const fs = features(x), passing = fs.filter(f => f.passes);
  const live = fs.length ? { passing: passing.length, total: fs.length, verified: passing.filter(f => has(x, "verified", f.milestone)).length,
    merged: passing.filter(f => has(x, "merged", f.milestone)).length } : { passing: null, total: null, verified: null, merged: null };
  const f = sum?.features;
  // the units a lane's milestone prefixes go under it (P2-06's lane lines); the rest are the run's own
  const mb = u => ({ unit: u.unit, memory_mb: Math.floor((u.bytes + 524288) / 1048576) });
  const taken = new Set();
  const open = x.lanes.filter(l => l.live).map(l => {
    const p = unitOf(x.run, l.milestone) + "-", us = x.units.filter(u => u.unit.startsWith(p) && ROLE.test(u.unit.slice(p.length)));
    us.forEach(u => taken.add(u.unit));
    return { milestone: l.milestone, now: l.now, port: l.port, slot: l.slot, units: us.map(mb) };
  });
  const sl = sum?.lanes;
  return {
    run: x.run, project: x.project, state: st, end_reason: e?.reason ?? null,
    end_class: e ? endClass(e.reason) : st === "crashed" ? "failed" : null,
    started_at: iso(starts[0] ?? null) ?? sum?.started ?? null,
    ended_at: e ? iso(e.at) : st === "crashed" ? iso(x.log_mtime) : null,
    feature: sess?.[3] ?? null, session, model: sess?.[4] ?? null,
    features: f ? { passing: f.passing ?? null, total: f.total ?? null, verified: f.verified ?? null, merged: f.merged ?? null } : live,
    cost_usd: sum?.cost?.total ?? (x.metrics.length ? r2(x.metrics.reduce((s, r) => s + (r.cost_usd ?? 0), 0)) : null),
    tests: sum?.tests ? { start: sum.tests.start ?? null, end: sum.tests.end ?? null } : x.tests,
    port: x.port, branch: `harness/${x.run}`, worktree: x.worktree, worktree_exists: x.worktree_exists, record: x.record,
    state_dir: x.state_dir, needs: needsItems(x, now).length,
    lanes: sl || open.length ? { max_open: sl?.max_open ?? null, lane_hours: sl?.lane_hours ?? null, wall_hours: sl?.wall_hours ?? null, open } : null,
    units: x.units.filter(u => !taken.has(u.unit)).map(mb),
  };
}

/** Pure: RUNNING (every live driver, oldest start first) and FINISHED (ended or crashed, newest first: the window's,
 *  but at least the 3 newest and at most 10; --all every one) with the count left out. */
export function sections(runs, { now, since = "24h", all = false }) {
  const done = r => r.state === "ended" || r.state === "crashed";
  const running = runs.filter(r => !done(r)).sort((a, b) => (a.started_at ?? "~").localeCompare(b.started_at ?? "~"));
  const ended = runs.filter(done).sort((a, b) => (b.ended_at ?? "").localeCompare(a.ended_at ?? "") || a.run.localeCompare(b.run));
  if (all) return { running, finished: ended, older: 0 };
  const from = now - duration(since, now);
  const inside = ended.filter(r => r.ended_at && secs(r.ended_at) >= from).length;
  const finished = ended.slice(0, Math.min(10, Math.max(3, inside)));
  return { running, finished, older: ended.length - finished.length };
}

// The text view (U1-04): every string through view.mjs. The class's glyph and colour; the words say it too.
const LOOK = { done: ["done", "green"], stopped: ["stopped", "dim"], waiting: ["needs", "yellow"], failed: ["failed", "red"] };
const alias = m => /(opus|sonnet|haiku|fable)/.exec(m ?? "")?.[1] ?? m ?? "";
const hhmm = e => { const d = new Date(e * 1000); return `${String(d.getHours()).padStart(2, "0")}:${String(d.getMinutes()).padStart(2, "0")}`; };
// P2-06's lane line, its text unchanged (the old cmd_status printed it; 47-'s check reads it)
export const laneLine = l => `lane ${l.milestone} · ${l.now ?? "starting"} · port ${l.port ?? "?"} · slot ${l.slot ? l.slot.replace(/^.*\/slot-/, "") : "?"} · ${
  l.units.length ? "MemoryCurrent " + l.units.map(u => `${u.unit} ${u.memory_mb} MB`).join(", ") : "no units"}`;

/** Pure: `harness status`'s lines. doc: the v1 document; runs: run → its object (a NEEDS row's passing and cost);
 *  extra: run → {seg (the segment's start), tail (the last N run.log lines), limit (LIMIT_UNTIL)}; verbose: -v or N. */
export function renderView(doc, { runs = new Map(), extra = new Map(), verbose = false, all = false, project = null, env = {} }, ctx) {
  const g = (name, style) => paint(glyph(name, ctx), style, ctx), sep = ` ${glyph("sep", ctx)} `;
  const money = c => c == null ? "" : `$${Math.round(c)}`;
  const pass = r => r?.features?.total != null ? `${r.features.passing ?? 0}/${r.features.total}` : "";
  const age = t => t == null ? "" : ago(Date.parse(t) / 1000, ctx.now);
  // a log line's text: control bytes (a tab, an ESC) as spaces, so the width holds and no escape reaches a pipe; a path
  // that starts with the home directory as ~ (view.mjs's home rule), one that merely contains it left alone
  const h = (env.HOME ?? "").replace(/\/+$/, ""), at0 = h && new RegExp(`(^|[\\s=:'"(])${h.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")}(?=/|\\s|$)`, "g");
  const clean = t => String(t ?? "").replace(/[\x00-\x1f\x7f]/g, " ");
  const tilde = t => at0 ? clean(t).replace(at0, "$1~") : clean(t);
  const row = (gl, r, what, at, sub = []) => ({ id: `${gl} ${r.run}`, what: clean(what), pass: pass(r), cost: money(r.cost_usd), age: age(at), sub });
  const needs = doc.needs.map(i => row(g("needs", "yellow"), runs.get(i.run) ?? { run: i.run }, i.card.headline, i.at));
  const running = doc.running.map(r => {
    const x = extra.get(r.run) ?? {}, open = r.lanes?.open ?? [];
    const gl = r.state === "paused" ? g("paused", "dim") : r.state === "ending" && r.needs ? g("needs", "yellow") : g("running", "cyan");
    const what = r.state === "paused" ? "paused" : r.state === "limit_wait" ? `waiting for the usage limit until ${hhmm(x.limit)}`
      : r.state === "ending" ? "ending" : open.length > 1 ? `${open.length} lanes` : [r.feature, r.session && `session ${r.session}`, alias(r.model)].filter(Boolean).join(sep);
    const sub = verbose ? [...open.map(laneLine), ...r.units.map(u => `${u.unit} · MemoryCurrent ${u.memory_mb} MB`), ...(x.tail ?? []).map(tilde)]
      : open.length > 1 ? open.map(l => `lane ${l.milestone}${sep}${(l.now ?? "starting").split(" · ").join(sep)}`) : [];
    return row(gl, r, what, x.seg != null ? new Date(x.seg * 1000).toISOString() : r.started_at, sub);
  });
  const finished = doc.finished.map(r => { const [name, style] = LOOK[r.end_class] ?? LOOK.failed;
    return row(g(name, style), r, r.end_reason ?? "crashed", r.ended_at); });
  // one set of columns for the three run sections, so they line up; narrow: the cost joins the long field below
  const widest = k => Math.max(0, ...[...needs, ...running, ...finished].map(r => displayWidth(r[k])));
  const cols = [{ key: "id", cut: false, min: widest("id") }, { key: "what", flex: true },
    { key: "pass", align: "right", min: widest("pass") }, ...(ctx.narrow ? [] : [{ key: "cost", align: "right", min: widest("cost") }]),
    { key: "age", align: "right", min: widest("age") }];
  // narrow: the long field cut first, so the cost after it stays on the line
  const below = r => r.cost ? `${cut(r.what, ctx.width - 2 - displayWidth(sep + r.cost), ctx)}${sep}${r.cost}` : r.what;
  const rows = rs => table(ctx.narrow ? rs.map(r => ({ ...r, what: r.what ? below(r) : r.cost })) : rs, cols, ctx);
  // QUEUED: the waiting entries as `harness queue list` rows, the first three; the rest and the parked ones counted
  const waiting = doc.queued.filter(q => !q.parked), parked = doc.queued.length - waiting.length;
  const qrows = waiting.slice(0, 3).map(q => ({
    n: `${g("queued", "dim")} ${q.n}`, verb: q.verb, who: (q.run ?? `${q.project} (new run)`) + (q.mark ? ` (${q.mark})` : ""),
    what: [q.spec.map(f => f.split("/").pop()).join(" "), q.brief_head != null && `brief "${q.brief_head}${q.brief_chars > 30 ? glyph("cut", ctx) : ""}"${
      q.brief_chars > 30 ? ` (+${q.brief_chars - 30} chars)` : ""}`].filter(Boolean).join(sep),
    age: age(q.added_at), sub: q.held ? [`held: ${q.held.project} busy (${q.held.run})`] : [] }));
  const more = [waiting.length > 3 && `+${waiting.length - 3} more`, parked && `${parked} parked`].filter(Boolean).join(sep);
  const runner = doc.runner.up ? "runner going" : ctx.narrow ? "runner off" : "runner off (harness queue start)";
  const span = all ? "all" : /^\d{4}-/.test(doc.since) ? `since ${doc.since}` : `last ${doc.since}`;
  const out = [
    section("NEEDS YOU", needs.length, "harness needs", ctx), ...rows(needs),
    section("RUNNING", running.length, "", ctx), ...rows(running),
    section("QUEUED", waiting.length, runner, ctx),
    ...table(qrows, [{ key: "n", cut: false }, { key: "verb", cut: false }, { key: "who", cut: false }, { key: "what", flex: true }, { key: "age", align: "right" }], ctx),
    ...(more ? [cut(`${more}: harness queue list`, ctx.width, ctx)] : []),
    finished.length ? section("FINISHED", null, `${span}${sep}${finished.length}`, ctx) : cut(`FINISHED${sep}${span}${sep}0`, ctx.width, ctx),
    ...rows(finished),
  ];
  if (doc.older) {
    // the hints keep the project; --since 3d only where it shows more than the window does
    const k = `${doc.older} older run${doc.older === 1 ? "" : "s"}: harness status --all${project ? ` -p ${project}` : ""}`;
    const wider = (() => { try { return duration(doc.since, ctx.now) < 3 * 86400; } catch { return false; } })();
    const foot = (ctx.narrow ? [] : [wider && "--since 3d", "one run: harness status <run>"]).filter(Boolean)   // each hint only if it fits
      .reduce((t, h) => displayWidth(t + sep + h) <= ctx.width ? t + sep + h : t, k);
    out.push(rule(ctx), cut(foot, ctx.width, ctx));
  }
  return out;
}

const VALUED = new Set(["--spec", "--brief", "--brief-file", "--until", "--until-epoch", "--base"]);

/** Pure: a queue entry from its .args lines (one argument per line, as queue_add writes them). projects: run → project
 *  (for a continue, as queue.sh's entry_project); busy: project → its live run (the runner's busy_projects rule). */
export function queueEntry(args, { n, added, now = added, parked = false, why = null, projects = new Map(), busy = new Map() }) {
  const [verb, first] = args;
  const pos = verb === "start" && args[2] && !args[2].startsWith("--") ? 3 : 2;
  const run = verb === "continue" ? first ?? null : pos === 3 ? args[2] : null;
  const project = verb === "start" ? basename(first ?? "") || null : projects.get(run) ?? null;
  const o = {};
  for (let i = pos; i < args.length; i++) if (VALUED.has(args[i])) o[args[i]] = args[++i] ?? ""; else o[args[i]] = true;
  const brief = typeof o["--brief"] === "string" ? [...o["--brief"]] : null;
  let until = null;
  const u = o["--until"] ?? "";
  if (/^\d+$/.test(o["--until-epoch"] ?? "")) until = Number(o["--until-epoch"]);
  else if (/^\d{9,}$/.test(u)) until = Number(u);
  else if (/^\d{1,2}:\d\d$/.test(u) && now != null) {   // HH:MM: the next such time, as to_epoch reads it when the entry starts
    const d = new Date(now * 1000), [h, m] = u.split(":").map(Number);
    d.setHours(h, m, 0, 0); if (d.getTime() / 1000 <= now) d.setDate(d.getDate() + 1); until = d.getTime() / 1000;
  }
  const holder = parked ? null : busy.get(project);
  return {
    n, verb, project, run, spec: typeof o["--spec"] === "string" ? o["--spec"].split(/[\s,]+/).filter(Boolean) : [],
    brief_head: brief ? brief.slice(0, 30).join("") : null, brief_chars: brief ? brief.length : null, until: iso(until),
    mark: verb === "continue" ? (o["--requested"] ? "requested" : "automatic") : null, added_at: iso(added),
    held: holder ? { project, run: holder } : null, overlap: [], parked, why,
  };
}

// the queue as `harness queue list` numbers it: the waiting entries 1…, then the parked ones 1… (queue/held/)
function readQueue(dir, opts) {
  const one = (d, parked) => ls(d).filter(f => f.endsWith(".args")).map((f, i) => queueEntry((text(join(d, f)) ?? "").replace(/\n$/, "").split("\n"),
    { ...opts, n: i + 1, added: mtime(join(d, f)), parked, why: parked ? line(join(d, f.replace(/\.args$/, ".why"))) : null }));
  return [...one(dir, false), ...one(join(dir, "held"), true)];
}

function main(argv) {
  const o = { _: [] }, flags = new Set(["--json", "--all"]);
  for (let i = 0; i < argv.length; i++) {
    if (flags.has(argv[i])) o[argv[i].slice(2)] = true;
    else if (argv[i].startsWith("--")) o[argv[i].slice(2)] = argv[++i];
    else o._.push(argv[i]);
  }
  const [cmd, want] = o._;
  if (!["view", "card"].includes(cmd) || (cmd === "card" && (!want || !o.json))) {
    console.error("usage: status.mjs view [--all] [--since <d>] [--project <p>] [--verbose <N>] [--json] | card <run> --json  (+ --runner --queue --ledger --state-root --max-parallel --since-default)");
    return 2;
  }
  const ctx = context({ env: process.env, isTTY: process.stdout.isTTY, columns: process.stdout.columns }), now = ctx.now;
  const rows = (() => { try { return readFileSync(0, "utf8"); } catch { return ""; } })().split("\n").filter(Boolean);
  const facts = rows.map(r => readRun(r, { stateRoot: o["state-root"] ?? "", ledger: o.ledger ?? "" }));
  const out = d => { process.stdout.write(JSON.stringify(d, null, 2) + "\n"); return 0; };
  if (cmd === "card") {
    const x = facts.find(f => f.run === want);
    if (!x) { console.error(`harness: no run '${want}' (see: harness status)`); return 1; }
    return out({ v: 1, ...runObject(x, now) });
  }
  const since = o.since ?? o["since-default"] ?? "24h";
  try { duration(since, now); } catch (e) { console.error(`harness: ${e.message}`); return 1; }
  const projects = new Map(facts.map(x => [x.run, x.project])), busy = new Map();
  for (const x of facts) if (x.alive && !busy.has(x.project)) busy.set(x.project, x.run);
  const mine = p => !o.project || p === o.project;
  const keep = facts.filter(x => mine(x.project));
  const objs = keep.map(x => runObject(x, now)), s = sections(objs, { now, since, all: Boolean(o.all) });
  const doc = {
    v: 1, generated_at: iso(now), since, runner: { up: o.runner === "1", max_parallel_runs: /^(0|[1-9]\d*)$/.test(o["max-parallel"] ?? "") ? Number(o["max-parallel"]) : 1 },
    needs: keep.flatMap(x => needsItems(x, now)).sort(byNeed), running: s.running,
    queued: o.queue ? readQueue(o.queue, { projects, busy, now }).filter(q => mine(q.project)) : [], finished: s.finished, older: s.older,
  };
  if (o.json) return out(doc);
  const n = /^\d+$/.test(o.verbose ?? "") ? Number(o.verbose) : null;
  const extra = new Map(keep.filter(x => x.alive).map(x => [x.run, {
    seg: [...x.log.matchAll(/^(\S+ \S+) run \S+ on /gm)].map(m => stamp(m[1])).at(-1) ?? null, limit: x.limit_until,
    tail: n ? x.log.split("\n").filter(Boolean).slice(-n) : [] }]));
  const lines = renderView(doc, { runs: new Map(objs.map(r => [r.run, r])), extra, verbose: n != null, all: Boolean(o.all), project: o.project ?? null, env: process.env }, ctx);
  process.stdout.write(lines.join("\n") + "\n");
  return 0;
}

if (process.argv[1] && fileURLToPath(import.meta.url) === resolve(process.argv[1])) process.exit(main(process.argv.slice(2)));
