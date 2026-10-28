// `harness status`'s data: the run, needs and queue objects from the state dirs, the ledger and the queue, in one node
// process (decisions/2026-10-27-read-views). No dependencies but ./view.mjs, ./needs.mjs (the needs records) and ./overlap.mjs (names).
//
//   view [--all] [--since <d>] [--project <p>] [--verbose <N>] [--json]
//                                                        → the default view (text: four sections and a footer), or v1
//   card <run> [--verbose <N>] [--json]                  → that one run's card (the log tail with N), or its object with v
//   queue                                                → `harness queue list`: QUEUE, PARKED, RUNNING, RECENT
//   entry <n> [--parked]                                 → `harness queue show`: that entry whole, as a card
//   always: --runner 0|1 --queue <dir> --ledger <dir> --state-root <dir> --max-parallel <k> --since-default <d>
//   view and queue: --overlaps <file>, "<entry file>\t<run>\t<path>" per path a queued entry meets (bin/harness)
//   stdin: one line per run, "<run>\t<project>\t<state dir>\t<worktree>\t<record dir>\t<alive 0|1|2>[\t<unit>=<bytes>,…]"
//          (alive 2: ending, the driver is in finish; field 7: the run's live units, when bash collected them)
// Read-only: it reads ended, PAUSE, LIMIT_UNTIL, port, tests-*, run.log, metrics.jsonl, the feature list, attempts.json,
// the verified- and merged- markers, lanes/<m>/, summary.json (state dir → record → ledger copy), needs/ (needs.mjs list)
// and the queue dir; the card asks git for its branch's local refs.
import { existsSync, readFileSync, readdirSync, statSync } from "node:fs";
import { basename, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { execFileSync } from "node:child_process";
import { list as needsList, order as needsOrder } from "./needs.mjs";
import { names } from "./overlap.mjs";
import { ago, card, context, cut, day, displayWidth, duration, endClass, glyph, home, paint, section, rule, table, when } from "./view.mjs";

const text = p => { try { return readFileSync(p, "utf8"); } catch { return null; } };
const json = p => { try { return JSON.parse(readFileSync(p, "utf8")); } catch { return null; } };   // missing or bad: ignored
const mtime = p => { try { return Math.floor(statSync(p).mtimeMs / 1000); } catch { return null; } };
const ls = d => { try { return readdirSync(d).sort(); } catch { return []; } };
const line = p => text(p)?.trim() || null;
const num = p => { const t = line(p); return t && /^-?\d+(\.\d+)?$/.test(t) ? Number(t) : null; };
const iso = e => { const d = new Date(e * 1000); return e == null || isNaN(d) ? null : d.toISOString(); };   // out of range: none
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
    return { milestone: m, live: live(line(l("pid"))), now: line(l("now")), port: num(l("port")), slot: line(l("slot")) }; });
  const markers = ls(state).map(f => /^(verified|merged)-(.+)$/.exec(f)).filter(Boolean)
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
    list: json(join(record, "feature_list.json")), attempts: json(s("attempts.json")),
    max_attempts: num(s("max-attempts")) ?? 2, markers, lanes, summary,
  };
}

// milestones are optional: a feature without one is in lane "default", as features.mjs's laneOf says
const features = x => { const l = x.list; return (Array.isArray(l) ? l : l?.features ?? []).map(f => f.milestone ? f : { ...f, milestone: "default" }); };
// the coding sessions the run counted: a limit-refused one (env) is given back; init, verify and retro rows are no session
const coding = x => x.metrics.filter(r => r.kind === "coding" && !r.env);
// the "session <n> · <id> · <model>" lines still running, oldest first: the driver is alive, the line is this segment's and
// no later "<id> · <model> · passes=" note or "session for <id> hit a limit" note (lane.sh) closed it; log order, not
// times (a row's at and the next line can share a second), and per id (two lanes' sessions overlap)
function liveSessions(x) {
  if (!x.alive) return [];
  const seg = [...x.log.matchAll(/^\S+ \S+ run \S+ on /gm)].at(-1)?.index ?? 0, open = new Map();
  for (const m of x.log.slice(seg).matchAll(/^(\S+ \S+) (?:session (\d+) · (\S+) · (\S+)|(\S+) · \S+ · passes=.*|session for (\S+) hit a limit .*)$/gm)) {
    open.delete(m[3] ?? m[5] ?? m[6]);
    if (m[2]) open.set(m[3], [m[0], m[1], m[2], m[3], m[4]]);   // as the session line's own match: [line, stamp, n, id, model]
  }
  return [...open.values()];
}
const has = (x, kind, m) => x.markers.some(k => k.kind === kind && k.milestone === m);

/** What waits on Michael in this run: its needs records and the synthesized items, as `harness needs` lists them (a
 *  parked card's commands as of now). A state dir needs.mjs can't read costs that run its items, never the view. */
export function readNeeds(x, { now, runner = false, queue = "" }) {
  try { return needsList([x.state_dir], { now, runner, queue }); } catch { return []; }
}
const headline = i => i.card?.headline ?? i.title ?? i.reason ?? "?";   // a record without its card (by hand) still shows

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

/** Pure: the run object of `harness status --json` (v1) from readRun's facts. */
export function runObject(x, now) {
  const st = state(x, now), e = st === "ended" ? ended(x) : null, sum = x.summary;
  const starts = [...x.log.matchAll(/^(\S+ \S+) run \S+ on /gm)].map(m => stamp(m[1]));
  // what it does now: the newest session still running, else the newest one
  const sess = liveSessions(x).at(-1) ?? [...x.log.matchAll(/^(\S+ \S+) session (\d+) · (\S+) · (\S+)$/gm)].at(-1);
  // the run's count of sessions (spec default 3): its coding rows plus the ones running, never $STATE/sessions (the
  // driver resets it each segment)
  const session = coding(x).length + liveSessions(x).length || null;
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
    state_dir: x.state_dir, needs: x.needs?.length ?? 0,
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
// a run's glyph: its end class once ended (crashed: failed), else paused, ending with an item, running
const glyphOf = (r, ctx) => { const [name, style] = r.state === "ended" ? LOOK[r.end_class] ?? LOOK.failed : r.state === "crashed" ? LOOK.failed
  : r.state === "paused" ? ["paused", "dim"] : r.state === "ending" && r.needs ? ["needs", "yellow"] : ["running", "cyan"];
  return paint(glyph(name, ctx), style, ctx); };
const alias = m => /(opus|sonnet|haiku|fable)/.exec(m ?? "")?.[1] ?? m ?? "";
const hhmm = e => day(e).slice(11);
// P2-06's lane line, its text unchanged (the old cmd_status printed it; 47-'s check reads it)
export const laneLine = l => `lane ${l.milestone} · ${l.now == null ? "starting" : clean(l.now)} · port ${l.port ?? "?"} · slot ${l.slot ? l.slot.replace(/^.*\/slot-/, "") : "?"} · ${
  l.units.length ? "MemoryCurrent " + l.units.map(u => `${u.unit} ${u.memory_mb} MB`).join(", ") : "no units"}`;
const clean = t => String(t ?? "").replace(/[\x00-\x1f\x7f]/g, " ");
// a log line's text: control bytes (a tab, an ESC) as spaces, so the width holds and no escape reaches a pipe; a path
// that starts with the home directory as ~ (view.mjs's home rule), one that merely contains it left alone
function logText(env) {
  const h = (env.HOME ?? "").replace(/\/+$/, ""), at0 = h && new RegExp(`(^|[\\s=:'"(])${h.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")}(?=/|\\s|$)`, "g");
  return t => at0 ? clean(t).replace(at0, "$1~") : clean(t);
}

/** Pure: `harness status`'s lines. doc: the v1 document; runs: run → its object (a NEEDS row's passing and cost);
 *  extra: run → {seg (the segment's start), tail (the last N run.log lines), limit (LIMIT_UNTIL)}; verbose: -v or N. */
export function renderView(doc, { runs = new Map(), extra = new Map(), verbose = false, all = false, project = null, env = {} }, ctx) {
  const g = (name, style) => paint(glyph(name, ctx), style, ctx), sep = ` ${glyph("sep", ctx)} `;
  const money = c => c == null ? "" : `$${Math.round(c)}`;
  const pass = r => r?.features?.total != null ? `${r.features.passing ?? 0}/${r.features.total}` : "";
  const age = t => t == null ? "" : ago(secs(t), ctx.now);
  const tilde = logText(env);
  const row = (gl, r, what, at, sub = []) => ({ id: `${gl} ${r.run}`, what: clean(what), pass: pass(r), cost: money(r.cost_usd), age: age(at), sub });
  const needs = doc.needs.map(i => row(g("needs", "yellow"), runs.get(i.run) ?? { run: i.run }, headline(i), i.at));
  const running = doc.running.map(r => {
    const x = extra.get(r.run) ?? {}, open = r.lanes?.open ?? [];
    const what = r.state === "paused" ? "paused" : r.state === "limit_wait" ? `waiting for the usage limit until ${hhmm(x.limit)}`
      : r.state === "ending" ? "ending" : open.length > 1 ? `${open.length} lanes` : [r.feature, r.session && `session ${r.session}`, alias(r.model)].filter(Boolean).join(sep);
    const sub = verbose ? [...open.map(laneLine), ...r.units.map(u => `${u.unit} · MemoryCurrent ${u.memory_mb} MB`), ...(x.tail ?? []).map(tilde)]
      : open.length > 1 ? open.map(l => `lane ${l.milestone}${sep}${clean(l.now ?? "starting").split(" · ").join(sep)}`) : [];
    return row(glyphOf(r, ctx), r, what, x.seg != null ? new Date(x.seg * 1000).toISOString() : r.started_at, sub);
  });
  const finished = doc.finished.map(r => row(glyphOf(r, ctx), r, r.end_reason ?? "crashed", r.ended_at));
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
  const qrows = waiting.slice(0, 3).map(q => queueRow(q, { n: `${g("queued", "dim")} ${q.n}`, age: age(q.added_at) }, ctx));
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

/** Pure: `harness status <run>`'s card. r: the run object; x: readRun's facts; extra: {seg, tail, limit} as renderView's;
 *  git: {head, ahead, behind} from the worktree's local refs, or null; verbose: -v or N (the log tail, the last field). */
/** Pure: the card's header line, "<glyph> <run> · <project> · <state> · <p>/<t> passing · <since>" (harness show's too). */
export function cardHeader(r, x, extra, ctx) {
  const sep = ` ${glyph("sep", ctx)} `, live = !["ended", "crashed"].includes(r.state), now = ctx.now;
  const since = (e => e == null ? null : ago(e, now))(live ? extra?.seg ?? (r.started_at && secs(r.started_at)) : r.ended_at && secs(r.ended_at));
  return [`${glyphOf(r, ctx)} ${r.run}`, r.project, live ? { limit_wait: "waiting for the usage limit" }[r.state] ?? r.state : r.state === "crashed" ? "crashed" : r.end_class,
    r.features.total != null && `${r.features.passing ?? 0}/${r.features.total} passing`,
    since && (since === "now" ? (live ? "started now" : "now") : `${live ? "started " : ""}${since} ago`)].filter(Boolean).join(sep);
}

export function renderCard(r, x, { extra = {}, git = null, verbose = false, env = {} }, ctx) {
  const sep = ` ${glyph("sep", ctx)} `, live = !["ended", "crashed"].includes(r.state), now = ctx.now;
  const at = secs, header = cardHeader(r, x, extra, ctx);
  // now: the newest session line, its attempt (the driver bumps attempts.json before the session) and its minutes in
  const sess = liveSessions(x).at(-1), a = x.attempts?.[r.feature];
  const doing = [r.feature, r.session && `session ${r.session}`, a && `attempt ${a} of ${x.max_attempts}`, alias(r.model),
    sess && `${Math.max(0, Math.floor((now - stamp(sess[1])) / 60))} min in`].filter(Boolean).join(sep);
  const state = r.state === "paused" ? "paused" : r.state === "limit_wait" ? `waiting for the usage limit until ${hhmm(extra.limit)}` : r.state === "ending" ? "ending" : "";
  // milestones: the list's, in its order, else (a gc'd run) the summary's
  const fs = features(x), ms = fs.length ? [...new Set(fs.map(f => f.milestone))].map(m => { const mf = fs.filter(f => f.milestone === m);
    return { id: m, passing: mf.filter(f => f.passes).length, features: mf.length, merged: has(x, "merged", m), verified: has(x, "verified", m) }; })
    : x.summary?.milestones ?? [];
  const tick = glyph("done", ctx), arrow = ctx.glyphs === "ascii" ? "->" : "→";
  const wall = x.summary?.time?.wall_h ?? (r.started_at ? ((r.ended_at ? at(r.ended_at) : now) - at(r.started_at)) / 3600 : null);
  const t = r.tests ?? {}, items = x.needs ?? [], open = live ? r.lanes?.open ?? [] : [];
  const gone = !r.worktree_exists && x.summary != null;   // gc removes a worktree and keeps the summary; else it never was
  const fields = [
    { label: "now", value: live ? [state, doing].filter(Boolean).join(sep) : null },
    { label: "ended", value: live ? null : `${r.ended_at ? when(at(r.ended_at), now) + sep : ""}${clean(r.end_reason ?? "driver gone without an end reason")}` },
    { label: "milestones", value: ms.map(m => `${m.id} ${m.merged ? `${tick} merged ` : m.verified ? `${tick} verified ` : ""}${m.passing}/${m.features}`).join(sep) },
    { label: "lanes", value: open.length ? `${open.length} open` : null, lines: open.map(laneLine) },
    { label: "spend", value: [r.cost_usd != null && `$${r.cost_usd.toFixed(2)}`, r.session && `${r.session} session${r.session === 1 ? "" : "s"}`,
      wall != null && `${wall.toFixed(1)} h wall`, (t.start != null || t.end != null) && `tests ${t.start ?? "?"} ${arrow} ${t.end ?? "?"}`,
      live && r.port != null && `port ${r.port}`].filter(Boolean).join(sep) },
    { label: "branch", value: !r.worktree_exists ? `${r.branch} (worktree ${gone ? "removed" : "missing"})` : git?.head ? `${r.branch} @ ${git.head}${
      git.ahead != null ? `${sep}${git.ahead} ahead, ${git.behind} behind` : ""}` : r.branch },
    { label: "worktree", value: r.worktree_exists ? home(r.worktree, env) : gone ? "removed by gc" : `${home(r.worktree, env)} (missing)` },
    // the count and the open items' headlines (past three, +<k> more), then the command that shows their cards
    { label: "needs you", value: items.length ? [`${paint(glyph("needs", ctx), "yellow", ctx)} ${items.length}${sep}${clean(headline(items[0]))}`,
      ...items.slice(1, 3).map(i => clean(headline(i))), ...(items.length > 3 ? [`+${items.length - 3} more`] : []), `harness needs ${r.run}`] : null },
    { label: "units", value: live ? r.units.map(u => `${u.unit}${sep}${u.memory_mb} MB`) : null },
    { label: "next", value: live ? [`harness attach ${r.run}`] : [`harness report ${r.run}`, ...(r.worktree_exists ? [`harness continue ${r.run}`] : [])] },
    { label: "log", value: verbose ? `last ${extra.tail?.length ?? 0} lines of run.log` : null, lines: verbose ? (extra.tail ?? []).map(logText(env)) : [] },
  ];
  return card(header, fields.filter(f => verbose || f.label !== "log"), ctx);
}

const VALUED = new Set(["--spec", "--brief", "--brief-file", "--until", "--until-epoch", "--base"]);
const SHOWN = new Set([...VALUED, "--requested"].filter(k => k !== "--base"));   // the options the show card has a field for

// an entry's .args lines → its verb, its first argument (a start's project path, a continue's run), its run and options;
// rest: the options no field of the show card names, as given
function entryArgs(args) {
  const [verb, first] = args;
  const pos = verb === "start" && args[2] && !args[2].startsWith("--") ? 3 : 2;
  const o = {}, rest = [];
  for (let i = pos; i < args.length; i++) {
    const k = args[i], v = VALUED.has(k) ? args[++i] ?? "" : true;
    o[k] = v; if (!SHOWN.has(k)) rest.push(k, ...(v === true ? [] : [v]));
  }
  return { verb, first, run: verb === "continue" ? first ?? null : pos === 3 ? args[2] : null, o, rest };
}

/** Pure: a queue entry from its .args lines (one argument per line, as queue_add writes them). projects: run → project
 *  (for a continue, as queue.sh's entry_project); busy: project → its live run (the runner's busy_projects rule);
 *  overlap: [{run, files}], the runs it meets (bin/harness's overlaps). */
export function queueEntry(args, { n, added, now = added, parked = false, why = null, projects = new Map(), busy = new Map(), overlap = [] }) {
  const { verb, first, run, o } = entryArgs(args);
  const project = verb === "start" ? basename(first ?? "") || null : projects.get(run) ?? null;
  const brief = o["--brief"] ? [...o["--brief"]] : null;   // a --brief with no value is no brief
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
    held: holder ? { project, run: holder } : null, overlap, parked, why,
  };
}

// an entry's lines, a CR at their end dropped (a file edited elsewhere)
const argsOf = f => (text(f) ?? "").replace(/\r?\n$/, "").split(/\r?\n/);
// the queue as `harness queue list` numbers it, each entry paired with its lines and file (one read, so show never
// pairs one entry's fields with the next one's file): the waiting entries 1…, then the parked ones 1… (queue/held/)
function readQueue(dir, opts) {
  const one = (d, parked) => ls(d).filter(f => f.endsWith(".args")).map((f, i) => { const args = argsOf(join(d, f));
    return [queueEntry(args, { ...opts, n: i + 1, added: mtime(join(d, f)), parked, why: parked ? line(join(d, f.replace(/\.args$/, ".why"))) : null,
      overlap: parked ? [] : opts.overlaps?.get(f) ?? [] }), { args, file: join(d, f) }]; })
    .filter(([q]) => q.added_at);   // gone between the listing and the read: the runner took it
  return [...one(dir, false), ...one(join(dir, "held"), true)];
}

// a queue entry as a table row: n, verb, the run (or "<project> (new run)") with its mark, the spec basenames and the
// brief's head (below: the brief on a line of its own, so its count is never cut), age; held and why as sub-lines
function queueRow(q, { n = String(q.n), age = "", below = false }, ctx) {
  const more = q.brief_chars > 30, sep = ` ${glyph("sep", ctx)} `;
  const brief = q.brief_head != null && `brief "${q.brief_head}${more ? glyph("cut", ctx) : ""}"${more ? ` (+${q.brief_chars - 30} chars)` : ""}`;
  const spec = q.spec.map(f => f.split("/").pop()).join(" ");
  return { n, verb: q.verb, who: (q.run ?? `${q.project ?? "?"} (new run)`) + (q.mark ? ` (${q.mark})` : ""),
    what: (below ? [spec] : [spec, brief]).filter(Boolean).join(sep), age,
    sub: [below && brief, q.held && `held: ${q.held.project} busy (${q.held.run})`, ...(q.overlap ?? []).map(x => `${glyph("needs", ctx)} overlaps ${x.run} on ${names(x.files)}`),
      q.parked && `why: ${clean(q.why ?? "no reason recorded")}`].filter(Boolean) };
}

/** Pure: `harness queue list`'s lines. doc: {runner, queued} as the v1 document's; running: the live runs' ids;
 *  recent: runner.log's last lines. */
export function renderQueue(doc, { running = [], recent = [], env = {} }, ctx) {
  const sep = ` ${glyph("sep", ctx)} `, tilde = logText(env), k = doc.runner.max_parallel_runs;
  const waiting = doc.queued.filter(q => !q.parked), parked = doc.queued.filter(q => q.parked);
  const cols = [{ key: "n", align: "right", min: 2, cut: false }, { key: "verb", cut: false }, { key: "who", cut: false }, { key: "what", flex: true }, { key: "age", align: "right" }];
  const rows = qs => table(qs.map(q => queueRow(q, { age: ago(secs(q.added_at), ctx.now), below: true }, ctx)), cols, ctx);
  const runner = doc.runner.up ? `runner ${paint(glyph("running", ctx), "cyan", ctx)} going` : "runner off";
  // every live run named: the ids fold under the title, never cut (an id wider than the line alone is)
  const run = ["RUNNING"];
  for (const id of running.length ? running : ["0"]) {
    const l = run.at(-1) + " " + id;
    if (displayWidth(l) <= ctx.width) run[run.length - 1] = l; else run.push(" ".repeat(7) + " " + id);
  }
  const out = [section("QUEUE", waiting.length, [runner, ctx.narrow ? `max ${k}` : `MAX_PARALLEL_RUNS=${k}`].join(sep), ctx), ...rows(waiting),
    ...(parked.length ? [section(`PARKED ${parked.length} (skipped; harness queue unpark <n>)`, null, "", ctx), ...rows(parked)] : ["PARKED 0"]),
    ...run.map(l => cut(l, ctx.width, ctx))];
  if (recent.length) out.push(section("RECENT", null, "", ctx), ...recent.map(l => {   // the time of day only: the log's lines are the runner's last hours
    const m = /^\d{4}-\d\d-\d\d (\d\d:\d\d):\d\d (.*)$/.exec(l);
    return cut(m ? ` ${m[1]}  ${tilde(m[2])}` : ` ${tilde(l)}`, ctx.width, ctx); }));
  if (doc.queued.length) out.push(rule(ctx), cut("one entry in full: harness queue show <n>", ctx.width, ctx));
  return out;
}

/** Pure: `harness queue show <n> [--parked]`'s card: the entry q, its .args lines, the file, the project's path. */
export function renderEntry(q, { args, file, project = null, env = {} }, ctx) {
  const sep = ` ${glyph("sep", ctx)} `, { o, rest } = entryArgs(args), at = secs(q.added_at), a = ago(at, ctx.now);
  const header = [`${paint(glyph("queued", ctx), "dim", ctx)} ${q.parked ? "parked " : ""}${q.n}`, clean(q.verb || "?"),
    clean(q.run ?? `${q.project ?? "?"} (new run)`), a === "now" ? a : `${a} ago`].join(sep);
  const str = k => typeof o[k] === "string" && o[k] ? clean(o[k]) : null;   // a time to_epoch reads, a path: as given
  const tilde = logText(env);   // a path that starts with the home directory, as the log lines
  return card(header, [
    { label: "verb", value: clean(q.verb || "?") },
    { label: "project", value: home(project ?? q.project ?? "?", env) },
    { label: "run", value: q.run ?? "(new run)" },
    { label: "spec", value: q.spec.map(f => home(f, env)).join(" ") || null },
    { label: "brief", value: (b => b && tilde(b))(str("--brief") ?? (str("--brief-file") && `from ${str("--brief-file")}`)) },
    { label: "until", value: q.until ? day(secs(q.until)) : str("--until") ?? str("--until-epoch") },
    { label: "mark", value: q.mark },
    { label: "held", value: q.held && `${q.held.project} busy (${q.held.run})` },
    { label: "why", value: q.parked ? clean(q.why ?? "no reason recorded") : null },
    { label: "options", value: rest.length ? clean(rest.join(" ")) : null },
    { label: "added", value: when(at, ctx.now) },
    { label: "file", value: home(file, env) },
  ], ctx);
}

// a run's segment start (the last "run <id> on" line), its LIMIT_UNTIL and the last n run.log lines
export const extraOf = (x, n) => ({ seg: [...x.log.matchAll(/^(\S+ \S+) run \S+ on /gm)].map(m => stamp(m[1])).at(-1) ?? null,
  limit: x.limit_until, tail: n ? x.log.split("\n").filter(Boolean).slice(-n) : [] });

// the card's branch: its commit, ahead and behind origin/main as last fetched; local refs only (no fetch, no lock taken)
export function gitOf(wt, branch, main = "main") {
  const git = (...a) => execFileSync("git", ["-C", wt, ...a], { encoding: "utf8", stdio: ["ignore", "pipe", "ignore"], env: { ...process.env, GIT_OPTIONAL_LOCKS: "0" } }).trim();
  let head; try { head = git("rev-parse", "--short", "--verify", "-q", `refs/heads/${branch}`); } catch { return null; }
  try { const [behind, ahead] = git("rev-list", "--left-right", "--count", `refs/remotes/origin/${main}...refs/heads/${branch}`).split(/\s+/).map(Number);
    return { head, ahead, behind }; } catch { return { head, ahead: null, behind: null }; }
}

// a printf %q word back to its text: '…', $'…' (octal bytes and C escapes, as %q writes a non-ASCII path under LC_ALL=C)
// or backslash-escaped
export function unquote(w) {
  if (w == null) return null;
  const ansi = /^\$'(.*)'$/s.exec(w);
  if (ansi) {
    const C = { n: 10, t: 9, r: 13, e: 27, a: 7, b: 8, f: 12, v: 11 }, bytes = [];
    for (const [t, oct, hex, c] of ansi[1].matchAll(/\\(?:([0-7]{1,3})|x([0-9a-fA-F]{1,2})|(.))|[^\\]+/gs))
      if (oct) bytes.push(parseInt(oct, 8)); else if (hex) bytes.push(parseInt(hex, 16));
      else if (c) bytes.push(...(C[c] != null ? [C[c]] : Buffer.from(c))); else bytes.push(...Buffer.from(t));
    return Buffer.from(bytes).toString("utf8");
  }
  return /^'(.*)'$/s.test(w) ? w.slice(1, -1) : w.replace(/\\(.)/gs, "$1");
}

function main(argv) {
  const o = { _: [] }, flags = new Set(["--json", "--all", "--parked"]);
  for (let i = 0; i < argv.length; i++) {
    if (flags.has(argv[i])) o[argv[i].slice(2)] = true;
    else if (argv[i].startsWith("--")) o[argv[i].slice(2)] = argv[++i];
    else o._.push(argv[i]);
  }
  const [cmd, want] = o._;
  if (!["view", "card", "queue", "entry"].includes(cmd) || (cmd === "card" && !want) || (cmd === "entry" && !/^[1-9]\d*$/.test(want ?? ""))) {
    console.error("usage: status.mjs view [--all] [--since <d>] [--project <p>] [--verbose <N>] [--json] | card <run> [--verbose <N>] [--json] | queue | entry <n> [--parked]  (+ --runner --queue --ledger --state-root --max-parallel --since-default)");
    return 2;
  }
  const ctx = context({ env: process.env, isTTY: process.stdout.isTTY, columns: process.stdout.columns }), now = ctx.now;
  const rows = (() => { try { return readFileSync(0, "utf8"); } catch { return ""; } })().split("\n").filter(Boolean);
  const facts = rows.map(r => readRun(r, { stateRoot: o["state-root"] ?? "", ledger: o.ledger ?? "" }));
  const needsOf = x => { x.needs = readNeeds(x, { now, runner: o.runner === "1", queue: o.queue ?? "" }); return x; };   // view and card only
  const n = /^\d+$/.test(o.verbose ?? "") ? Number(o.verbose) : null;
  const out = d => { process.stdout.write(JSON.stringify(d, null, 2) + "\n"); return 0; };
  if (cmd === "card") {
    const x = facts.find(f => f.run === want);
    if (!x) { console.error(`harness: no run '${want}' (see: harness status)`); return 1; }
    const r = runObject(needsOf(x), now);
    if (o.json) return out({ v: 1, ...r });
    const lines = renderCard(r, x, { extra: extraOf(x, n), git: r.worktree_exists ? gitOf(x.worktree, r.branch) : null, verbose: n > 0, env: process.env }, ctx);   // N=0: no tail, as tail -n 0
    process.stdout.write(lines.join("\n") + "\n");
    return 0;
  }
  const projects = new Map(facts.map(x => [x.run, x.project])), busy = new Map();
  for (const x of facts) if (x.alive && !busy.has(x.project)) busy.set(x.project, x.run);
  const runner = { up: o.runner === "1", max_parallel_runs: /^(0|[1-9]\d*)$/.test(o["max-parallel"] ?? "") ? Number(o["max-parallel"]) : 1 };
  const overlaps = new Map();   // entry file → [{run, files}], in the order bash found them
  for (const l of (o.overlaps ? text(o.overlaps) ?? "" : "").split("\n")) {
    const [f, run, path] = l.split("\t"); if (!path) continue;
    const xs = overlaps.get(f) ?? []; overlaps.set(f, xs);
    const x = xs.find(y => y.run === run) ?? (xs.push({ run, files: [] }), xs.at(-1)); x.files.push(path);
  }
  const read = () => o.queue ? readQueue(o.queue, { projects, busy, now, overlaps }) : [], queued = () => read().map(([q]) => q);
  if (cmd === "queue") {
    const recent = (text(join(o.queue ?? "", "runner.log")) ?? "").split("\n").filter(Boolean).slice(-5);
    const lines = renderQueue({ runner, queued: queued() }, { running: facts.filter(x => x.alive).map(x => x.run), recent, env: process.env }, ctx);
    process.stdout.write(lines.join("\n") + "\n");
    return 0;
  }
  if (cmd === "entry") {   // numbered as queue list numbers it: queue rm's and unpark's <n>
    const parked = Boolean(o.parked), [q, { args, file } = {}] = read().find(([e]) => e.parked === parked && e.n === Number(want)) ?? [];
    if (!q) { console.error(`harness: no ${parked ? "parked" : "queue"} entry ${want} (see: harness queue list)`); return 1; }
    // a start's project is its path; a continue's, its run's PROJECT_DIR (meta.env, as printf %q wrote it)
    const meta = q.verb === "continue" ? text(join(facts.find(x => x.run === q.run)?.state_dir ?? "/nonexistent", "meta.env")) : null;
    const pd = unquote(/^PROJECT_DIR=(.*)$/m.exec(meta ?? "")?.[1]);
    const lines = renderEntry(q, { args, file, project: q.verb === "start" ? args[1] : pd ?? null, env: process.env }, ctx);
    process.stdout.write(lines.join("\n") + "\n");
    return 0;
  }
  const since = o.since ?? o["since-default"] ?? "24h";
  try { duration(since, now); } catch (e) { console.error(`harness: ${e.message}`); return 1; }
  const mine = p => !o.project || p === o.project;
  const keep = facts.filter(x => mine(x.project)).map(needsOf);
  const objs = keep.map(x => runObject(x, now)), s = sections(objs, { now, since, all: Boolean(o.all) });
  const doc = {
    v: 1, generated_at: iso(now), since, runner,
    needs: needsOrder(keep.flatMap(x => x.needs)), running: s.running,
    queued: queued().filter(q => mine(q.project)), finished: s.finished, older: s.older,
  };
  if (o.json) return out(doc);
  const extra = new Map(keep.filter(x => x.alive).map(x => [x.run, extraOf(x, n)]));
  const lines = renderView(doc, { runs: new Map(objs.map(r => [r.run, r])), extra, verbose: n != null, all: Boolean(o.all), project: o.project ?? null, env: process.env }, ctx);
  process.stdout.write(lines.join("\n") + "\n");
  return 0;
}

if (process.argv[1] && fileURLToPath(import.meta.url) === resolve(process.argv[1])) process.exit(main(process.argv.slice(2)));
