// What waits on Michael: one record per item, <state dir>/needs/<seq>.json, resolved into needs/done/ (plan:
// docs/plans/2026-10-28-U2-needs-record.md §1, §2; decisions/2026-10-27-needs-record). Only node: built-ins and ./view.mjs.
//
//   open <state dir> <run> <project> <reason> <subject> [key=value…]  → the ref; 0 new, 3 refreshed (same key open), 1 bad
//                                              (facts: feature, milestone, list, why, attempts, failed, end_reason, main, head, …)
//   sweep <state dir>…                         → "resolved <ref> (<why>)" per item its reason's rule resolves (moved to done/)
//   done <state dir> <ref> [--why <text>]      → "resolved <ref>"; 1 for an unknown, resolved or synthesized ref
//   list <state dir>… [--all] [--json] [--run <id>]  → the open items, block before warn, oldest first (read-only; --all:
//                                                 and those resolved in the last 7 days), with the synthesized ones
// HARNESS_NOW (epoch seconds) stands in for the clock. A state dir's meta.env names its worktree and project (WT, RUN_ID,
// PROJECT_DIR); the record's feature_list.json is in the worktree.
import { existsSync, mkdirSync, readFileSync, readdirSync, renameSync, statSync, writeFileSync } from "node:fs";
import { basename, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { execFileSync } from "node:child_process";
import { randomUUID } from "node:crypto";
import { context, glyph } from "./view.mjs";

// The 15 reasons (plan §2.1): kind is the v1 event enum's, severity block or warn, priority ntfy's.
const R = (kind, severity, priority, headline) => ({ kind, severity, priority, headline });
const runEnd = "ended";   // the run-level reasons' title: the run-end notification's
export const REASONS = {
  parked: R("park", "block", "high", (s, f) => `${s} parked${f.why ? ": " + f.why.split("\n")[0] : ""}`),
  given_up: R("blocked", "block", "high", (s, f) => `${s} given up${f.attempts ? ` (${f.attempts} attempts)` : ""}`),
  verify_thin: R("needs_michael", "block", "high", s => `${s} not verified: evidence too thin`),
  verify_red: R("needs_michael", "block", "high", s => `${s} not verified: suite red on the merged tree`),
  verify_recheck: R("needs_michael", "block", "high", (s, f) => `${s}: ${f.failed ? f.failed + " failed" : "the re-check failed"}`),
  merge_conflict: R("needs_michael", "block", "high", s => `${s} conflicts with main`),
  merge_refused: R("needs_michael", "block", "high", s => `${s}: the merge was refused`),
  main_conflict: R("needs_michael", "block", "high", () => "main conflicts with the run branch"),
  base_conflict: R("needs_michael", "block", "high", s => `${s} can't open: its base conflicts`),
  feature_list_edits: R("needs_michael", "block", "high", () => "stopped: sessions kept editing the feature list"),
  initializer_failed: R("needs_michael", "block", "high", () => "stopped: the initializer wrote no valid feature list"),
  driver_crash: R("needs_michael", "block", "high", s => s === "run" ? "the driver stopped without an end" : `lane ${s} exited unexpectedly`),
  usage_limit: R("limit", "warn", "", () => "ended on the usage limit"),
  weekly_budget: R("limit", "warn", "", () => "ended on the weekly budget"),
  overlap: R("needs_michael", "warn", "", (s, f) => `${f.run} and ${s} change the same files`),
};
const RUN_LEVEL = new Set(["feature_list_edits", "initializer_failed", "usage_limit", "weekly_budget"]);
const FEATURE_SUBJECT = new Set(["parked", "given_up"]), MILESTONE_SUBJECT = /^(verify_|merge_|main_conflict|base_conflict|driver_crash)/;

const isoAt = epoch => new Date(epoch * 1000).toISOString();
const nowOf = env => /^\d+$/.test(env.HARNESS_NOW ?? "") ? Number(env.HARNESS_NOW) : Date.now() / 1000;
const nul = v => v === undefined || v === "" ? null : v;

// The card until U2-04's templates fill it: every key there, the headline from the reason's table row.
function card(reason, subject, f) {
  return { headline: REASONS[reason].headline(subject, f), blocked: "", cost: "", why: "", where: [],
    commit: { main: f.main?.slice(0, 7) || null, branch: f.head?.slice(0, 7) || null }, branch: nul(f.branch), question: null,
    options: [], commands: [], files_from: "driver", run_state: null };
}
const title = (reason, subject, f, c) => RUN_LEVEL.has(reason) || reason === "driver_crash" && subject === "run"
  ? `[${f.run}] ${runEnd}: ${f.end_reason || c.headline}` : `[${f.run}] ${subject} needs you`;

/** Pure: a new item from the facts ({run, project, reason, subject, seq, feature, milestone, …}) at epoch seconds now. */
export function record(facts, now) {
  const { run, project, reason, subject, seq } = facts, r = REASONS[reason];
  if (!r) throw new Error(`unknown reason ${reason}`);
  if (!subject) throw new Error("no subject");
  const c = card(reason, subject, facts), at = isoAt(now);
  return { v: 1, id: randomUUID(), at, kind: r.kind, project, run, feature: nul(facts.feature), title: title(reason, subject, facts, c),
    body: c.headline, priority: r.priority, click: nul(facts.click), actions: nul(facts.actions), context: null,
    ref: `${run}/${seq}`, key: `${reason}:${subject}`, reason, severity: r.severity, milestone: nul(facts.milestone),
    seen: 1, updated_at: at, card: c, resolved_at: null, resolved_by: null, resolved_why: null };
}

/** Pure: an open item seen again; what the facts say now replaces what they said, id, at and ref stay. */
export function refresh(old, facts, now) {
  const n = record({ ...facts, seq: old.ref.slice(old.ref.lastIndexOf("/") + 1) }, now);
  return { ...old, title: n.title, body: n.body, priority: n.priority, click: n.click, actions: n.actions, card: n.card,
    seen: (old.seen ?? 1) + 1, updated_at: n.updated_at };
}

const subjectOf = i => i.key.slice(i.key.indexOf(":") + 1);
// The rule that resolves an open item (plan §2.1), its words, or null. st: { removed, ended, passing, parked, attempts,
// max_attempts, markers }
function rule(i, st) {
  const s = subjectOf(i), has = m => st.markers.includes(m), passes = st.passing.includes(s);
  if (st.removed) return "run removed";
  switch (i.reason) {
    case "parked": return passes ? "feature passes" : s in (st.parked ?? {}) ? null : "feature unparked";
    case "given_up": return passes ? "feature passes" : (st.attempts?.[s] ?? 0) < st.max_attempts ? "attempts reset" : null;
    case "verify_thin": case "verify_red": case "verify_recheck":
      return has(`verified-${s}`) ? "milestone verified" : has(`needs-${s}`) ? null : `needs-${s} cleared`;
    case "merge_conflict": return has(`merged-${s}`) ? "milestone merged" : has(`conflict-${s}`) || has(`needs-${s}`) ? null : "conflict cleared";
    case "merge_refused": return has(`merged-${s}`) ? "milestone merged" : has(`refused-${s}`) ? null : "refusal cleared";
    case "main_conflict": return has(`main-conflict-${s}`) ? null : "main merged cleanly";
    case "base_conflict": return has(`needs-${s}`) ? null : `needs-${s} cleared`;
    case "driver_crash": return s !== "run" ? has(`needs-${s}`) ? null : `needs-${s} cleared` : st.ended ? null : "run continued";
    case "overlap": return null;   // U3 fills the rule; until then by hand, or the run removed
    default: return RUN_LEVEL.has(i.reason) && !st.ended ? "run continued" : null;
  }
}

/** Pure: the open items split into those that stay and those the state resolves (resolved_* filled, by sweep). */
export function sweep(items, st, now = Date.now() / 1000) {
  const keep = [], resolved = [];
  for (const i of items) {
    const why = rule(i, st);
    if (why) resolved.push({ ...i, resolved_at: isoAt(now), resolved_by: "sweep", resolved_why: why }); else keep.push(i);
  }
  return { keep, resolved };
}

/** Pure: the items the state implies and no open record holds (never stored): a SIGKILLed driver (driver.pid names no
 *  live process, no ended) and each parked.json feature that doesn't pass. st: { run, project, removed, driver
 *  ("live" · "dead" · null), ended, passing, parked, log_mtime } */
export function synthesize(st, open) {
  if (st.removed) return [];
  const keys = new Set(open.map(i => i.key)), out = [];
  const one = (reason, subject, ref, at, f = {}) => {
    const i = record({ run: st.run, project: st.project, reason, subject, seq: 0, ...f }, 0);
    return { ...i, id: ref, at, updated_at: at, ref };
  };
  for (const [id, v] of Object.entries(st.parked ?? {}))
    if (!st.passing.includes(id) && !keys.has(`parked:${id}`))
      out.push(one("parked", id, `${st.run}/parked:${id}`, v?.at ?? isoAt(st.log_mtime ?? 0), { feature: id, why: String(v?.why ?? "") }));
  if (st.driver === "dead" && !st.ended && !keys.has("driver_crash:run"))
    out.push(one("driver_crash", "run", `${st.run}/crash`, isoAt(st.log_mtime ?? 0)));
  return out;
}

const SEV = { block: 0, warn: 1 };
/** Pure: block before warn, oldest first (a stable sort: ties keep their order). */
export const order = items => [...items].sort((a, b) => SEV[a.severity] - SEV[b.severity] || Date.parse(a.at) - Date.parse(b.at));

// ---- the I/O side ----
const json = p => { try { return JSON.parse(readFileSync(p, "utf8")); } catch { return null; } };
const text = p => { try { return readFileSync(p, "utf8"); } catch { return null; } };
const seqOf = f => /^(\d+)\.json$/.exec(f)?.[1];
const files = d => { try { return readdirSync(d).filter(seqOf).sort((a, b) => seqOf(a) - seqOf(b)); } catch { return []; } };
const items = d => files(d).map(f => json(join(d, f))).filter(i => i?.key);
// meta.env as bin/harness writes it (printf %q): a backslash escapes the next character
function meta(state) {
  const m = {};
  for (const l of (text(join(state, "meta.env")) ?? "").split("\n")) {
    const x = /^([A-Z_]+)=(.*)$/.exec(l);
    if (x) m[x[1]] = x[2].replace(/^'(.*)'$/, "$1").replace(/\\(.)/g, "$1");
  }
  return m;
}
const alive = pid => { if (!/^\d+$/.test(pid)) return false; try { process.kill(Number(pid), 0); return true; } catch (e) { return e.code === "EPERM"; } };
// worktree and record branch both gone (gc, or by hand): nothing of the run is left to act on
function removed(m) {
  if (!m.WT || existsSync(m.WT)) return false;
  if (!m.PROJECT_DIR || !existsSync(m.PROJECT_DIR)) return true;
  try { execFileSync("git", ["-C", m.PROJECT_DIR, "rev-parse", "-q", "--verify", `refs/heads/harness/${m.RUN_ID}`], { stdio: "ignore" }); return false; }
  catch { return true; }
}
/** The facts sweep and synthesize take, read from a state dir and its run's record. */
export function readState(state) {
  const m = meta(state), run = m.RUN_ID || basename(state), list = json(join(m.WT ?? "", ".harness/runs", run, "feature_list.json"));
  const fs = Array.isArray(list) ? list : list?.features ?? [], pid = text(join(state, "driver.pid"))?.trim();
  let log_mtime = 0; try { log_mtime = statSync(join(state, "run.log")).mtimeMs / 1000; } catch {}
  return { run, project: m.PROJECT_DIR ? basename(m.PROJECT_DIR) : basename(resolve(state, "..")), removed: removed(m),
    ended: existsSync(join(state, "ended")), passing: fs.filter(f => f.passes).map(f => f.id),
    parked: json(join(state, "parked.json")) ?? {}, attempts: json(join(state, "attempts.json")) ?? {},
    max_attempts: Number(text(join(state, "max-attempts"))) || 2, markers: (() => { try { return readdirSync(state); } catch { return []; } })(),
    driver: pid === undefined ? null : alive(pid) ? "live" : "dead", log_mtime };
}

const write = (p, o) => { writeFileSync(`${p}.tmp`, JSON.stringify(o, null, 2) + "\n"); renameSync(`${p}.tmp`, p); };
// moved by rename first (never open and resolved at once), then rewritten in place with resolved_* filled
function resolveTo(state, i) {
  const d = join(state, "needs", "done"), f = `${i.ref.slice(i.ref.lastIndexOf("/") + 1)}.json`;
  mkdirSync(d, { recursive: true }); renameSync(join(state, "needs", f), join(d, f)); write(join(d, f), i);
}

function open(state, run, project, reason, subject, kv, now) {
  const facts = {};
  for (const a of kv) { const k = a.indexOf("="); if (k > 0) facts[a.slice(0, k)] = a.slice(k + 1); }
  Object.assign(facts, { run, project, reason, subject });
  // a feature's reasons name it, a milestone's name the milestone (the coordinator has no LANE); a feature's milestone
  // is its list's
  if (!facts.feature && FEATURE_SUBJECT.has(reason)) facts.feature = subject;
  if (!facts.milestone && MILESTONE_SUBJECT.test(reason) && !["run", "record"].includes(subject)) facts.milestone = subject;
  if (!facts.milestone && facts.feature && facts.list) { const l = json(facts.list);
    facts.milestone = (Array.isArray(l) ? l : l?.features ?? []).find(f => f.id === facts.feature)?.milestone ?? ""; }
  const d = join(state, "needs"), old = items(d).find(i => i.key === `${reason}:${subject}`);
  if (old) { const n = refresh(old, facts, now); write(join(d, `${old.ref.slice(old.ref.lastIndexOf("/") + 1)}.json`), n); return [3, n.ref]; }
  const seq = 1 + Math.max(0, ...[...files(d), ...files(join(d, "done"))].map(f => Number(seqOf(f))));
  const i = record({ ...facts, seq }, now);   // throws before anything is written
  mkdirSync(d, { recursive: true }); write(join(d, `${seq}.json`), i);
  return [0, i.ref];
}

function list(states, { all = false, now }) {
  const out = [];
  for (const state of states) {
    const st = readState(state), d = join(state, "needs"), open = items(d);
    const { keep, resolved } = st.removed ? sweep(open, st, now) : { keep: open, resolved: [] };
    out.push(...keep, ...synthesize(st, keep));
    if (all) out.push(...resolved, ...items(join(d, "done")).filter(i => Date.parse(i.resolved_at) >= (now - 7 * 86400) * 1000));
  }
  return order(out);
}

function main([cmd, ...args], env = process.env) {
  const now = nowOf(env), die = m => { console.error(`needs.mjs: ${m}`); return 1; };
  const flag = k => { const i = args.indexOf(k); if (i < 0) return null; const v = args[i + 1] ?? ""; args.splice(i, 2); return v; };
  if (cmd === "open") {
    const [state, run, project, reason, subject, ...kv] = args;
    if (!state || !run) return die("usage: open <state dir> <run> <project> <reason> <subject> [key=value…]");
    try { const [rc, ref] = open(state, run, project, reason, subject, kv, now); console.log(ref); return rc; } catch (e) { return die(e.message); }
  }
  if (cmd === "sweep") {
    for (const state of args) {
      const { resolved } = sweep(items(join(state, "needs")), readState(state), now);
      for (const i of resolved) { resolveTo(state, i); console.log(`resolved ${i.ref} (${i.resolved_why})`); }
    }
    return 0;
  }
  if (cmd === "done") {
    const why = flag("--why"), [state, ref] = args;
    if (!state || !ref) return die("usage: done <state dir> <ref> [--why <text>]");
    if (/\/(crash|parked:.+)$/.test(ref))
      return die(`${ref} is derived from the run's state; it resolves when ${ref.endsWith("/crash") ? "the run is continued (harness continue)" : "the feature is unparked or passes"}`);
    const i = items(join(state, "needs")).find(x => x.ref === ref);
    if (!i) return die(`no open item ${ref}`);
    resolveTo(state, { ...i, resolved_at: isoAt(now), resolved_by: "michael", resolved_why: why || "done by hand" });
    console.log(`resolved ${ref}`);
    return 0;
  }
  if (cmd === "list") {
    const run = flag("--run") ?? "", json_ = args.includes("--json"), all = args.includes("--all");
    const xs = list(args.filter(a => !a.startsWith("--")), { all, now });
    if (json_) { process.stdout.write(JSON.stringify(xs, null, 2) + "\n"); return 0; }
    const ctx = context({ env, isTTY: process.stdout.isTTY, columns: process.stdout.columns });
    // one line per item until U2-04's cards
    const line = i => `${glyph("needs", ctx)} ${i.run} · ${i.card.headline} · ${i.ref}${i.resolved_at ? ` · resolved by ${i.resolved_by}: ${i.resolved_why}` : ""}`;
    process.stdout.write(xs.length ? xs.map(line).join("\n") + "\n" : `nothing needs you${run ? " in " + run : ""}\n`);
    return 0;
  }
  console.error("usage: needs.mjs open|sweep|done|list …");
  return 2;
}

if (process.argv[1] && fileURLToPath(import.meta.url) === resolve(process.argv[1])) process.exit(main(process.argv.slice(2)));
