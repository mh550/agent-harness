// `harness show`: where a run's work is (decisions/2026-10-28-show). Read-only: local refs of the project repo (no fetch,
// no lock: the branches live there, so a removed worktree changes nothing), the state dir, the record (else its ledger copy).
//
//   show.mjs <run> [<feature>] [--files] [--json] --project-dir <d> [--main <branch>] --state-root <d> --ledger <d> --queue <d> --runner 0|1
//   stdin: the run's row as status.mjs reads it (bin/harness run_rows)
import { mkdtempSync, readFileSync, rmSync } from "node:fs";
import { tmpdir } from "node:os";
import { isAbsolute, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { spawnSync } from "node:child_process";
import { cardHeader, extraOf, gitOf, readNeeds, readRun, runObject } from "./status.mjs";
import { order as needsOrder, renderCard as needsCard } from "./needs.mjs";
import { compareUrl } from "./notify.mjs";
import { card, context, cut, cutFront, displayWidth, glyph, home, pad, paint, section, when } from "./view.mjs";

const TOP = 12;   // the changes rows shown without --files
const text = p => { try { return readFileSync(p, "utf8"); } catch { return null; } };
const json = p => { try { return JSON.parse(readFileSync(p, "utf8")); } catch { return null; } };
const jsonl = t => (t ?? "").split("\n").filter(Boolean).map(l => { try { return JSON.parse(l); } catch { return null; } }).filter(Boolean);
const RUNS = /^\.harness\/runs\//;   // the record: never a change of the run's code
const alias = m => /(opus|sonnet|haiku|fable)/.exec(m ?? "")?.[1] ?? m ?? "";

/** Pure: `git diff --numstat` and `--name-status` (both --no-renames: one path a row) joined by path; a binary file's
 *  +/− are null. */
export function joinDiff(numstat, nameStatus) {
  const st = new Map();
  for (const l of (nameStatus ?? "").split("\n").filter(Boolean)) { const [s, ...p] = l.split("\t"); st.set(p.join("\t"), s[0]); }
  return (numstat ?? "").split("\n").filter(Boolean).map(l => {
    const [a, d, ...p] = l.split("\t"), path = p.join("\t");
    return { status: st.get(path) ?? "M", path, added: a === "-" ? null : Number(a), deleted: d === "-" ? null : Number(d) };
  }).filter(r => !RUNS.test(r.path));
}

/** Pure: the conflicted paths of `git merge-tree --write-tree --name-only` (exit 1): the lines after the tree OID up to
 *  the blank line before the messages. */
export function mergeTreePaths(out) {
  const ls = (out ?? "").split("\n"), end = ls.indexOf("", 1);
  return [...new Set(ls.slice(1, end < 0 ? ls.length : end).filter(p => p && !RUNS.test(p)))].sort();
}

/** Pure: the run's changes from its branches' ({rows, conflicts}, a row's blob: the path's object at the branch tip,
 *  null when deleted), in order (harness/<run>, then the lanes): a path with the same blob on two branches is one change
 *  (a stacked lane carries its base lane's; two lanes opened on one), counted once; different results are summed, the
 *  letter the first branch's; conflict when any branch's merge-tree lists it. */
export function combine(branches) {
  const rows = new Map(), seen = new Set(), conflicts = new Set(branches.flatMap(b => b.conflicts ?? []));
  for (const b of branches) for (const { blob, ...r } of b.rows) {
    const k = `${r.path}\0${blob ?? ""}`;
    if (blob !== undefined && seen.has(k)) continue;
    seen.add(k);
    const o = rows.get(r.path);
    if (!o) { rows.set(r.path, { ...r }); continue; }
    o.added = o.added == null || r.added == null ? null : o.added + r.added;
    o.deleted = o.deleted == null || r.deleted == null ? null : o.deleted + r.deleted;
  }
  const size = r => (r.added ?? 0) + (r.deleted ?? 0);
  const out = [...rows.values()].map(r => ({ ...r, conflict: conflicts.has(r.path) }))
    .sort((a, b) => size(b) - size(a) || (a.path < b.path ? -1 : a.path > b.path ? 1 : 0));
  return { files: out.length, added: out.reduce((s, r) => s + (r.added ?? 0), 0), deleted: out.reduce((s, r) => s + (r.deleted ?? 0), 0),
    rows: out, conflicts: [...conflicts].sort() };
}

/** Pure: the milestones harness-log.md says were merged into main or proposed for merging, in log order; a merge
 *  after a proposal keeps the proposal's PR when its own note has no URL ("(by its PR)", "(already there)"). */
export function milestonesOf(log) {
  const ms = new Map();
  for (const [, m, url, prop] of (log ?? "").matchAll(/^- .*? · ([A-Za-z0-9_.-]+) (?:merged into \S+(?: · (\S+)| \(.*\))?|proposed for merging · (\S+))$/gm)) {
    const o = ms.get(m) ?? { id: m, status: "proposed", url: null };
    if (prop) { if (o.status !== "merged") ms.set(m, { ...o, url: prop }); } else ms.set(m, { ...o, status: "merged", url: url ?? o.url });
  }
  return [...ms.values()];
}
const prOf = url => /\/pull\/(\d+)\/?$/.exec(url ?? "")?.[1] ?? null;

// ---- I/O: git in the project repo, local refs only ----
function gitIn(dir, gitEnv = {}) {
  return (...a) => { const r = spawnSync("git", ["-C", dir, "-c", "core.quotePath=false", ...a], { encoding: "utf8", maxBuffer: 64 << 20, env: { ...process.env, GIT_OPTIONAL_LOCKS: "0", ...gitEnv } });
    return { ok: r.status === 0, status: r.status, out: r.stdout ?? "" }; };
}

// harness/<run> (a pre-lanes run's code, else its record), then harness-lane/<run>/<m> (an origin copy without a local
// branch counts too), by milestone
function branchesOf(git, run) {
  const refs = git("for-each-ref", "--format=%(refname)", `refs/heads/harness/${run}`, `refs/heads/harness-lane/${run}/`, `refs/remotes/origin/harness-lane/${run}/`)
    .out.split("\n").filter(Boolean);
  const name = r => r.replace(/^refs\/(heads|remotes\/origin)\//, ""), local = new Set(refs.filter(r => r.startsWith("refs/heads/")).map(name));
  return refs.filter(r => r.startsWith("refs/heads/") || !local.has(name(r))).map(r => ({ ref: r, name: name(r), milestone: name(r).split("/")[2] ?? null }))
    .sort((a, b) => (a.milestone == null ? -1 : b.milestone == null ? 1 : a.milestone.localeCompare(b.milestone)));
}

// each branch's diff from its merge-base with main, its rows' blobs at the tip (combine's one-change rule) and the paths
// merge-tree says conflict; null when there is no main ref to compare with (never fetched, or a project dir gone)
function changesOf(git, dir, bs, main) {
  if (!git("rev-parse", "--verify", "-q", main).ok) return null;
  // merge-tree --write-tree writes the merged trees: into a scratch object store (the repo's own as an alternate), so the
  // project's stays as it was
  const common = git("rev-parse", "--path-format=absolute", "--git-common-dir").out.trim(), objs = mkdtempSync(join(tmpdir(), "harness-show-"));
  const scratch = gitIn(dir, { GIT_OBJECT_DIRECTORY: objs, GIT_ALTERNATE_OBJECT_DIRECTORIES: join(common, "objects") });
  try {
    for (const b of bs) {
      const base = git("merge-base", main, b.ref);
      const d = k => base.ok ? git("diff", "--no-renames", k, base.out.trim(), b.ref, "--", ".", ":!.harness/runs").out : "";
      const rows = joinDiff(d("--numstat"), d("--name-status"));
      const blobs = new Map(rows.length ? git("ls-tree", "-r", b.ref, "--", ...rows.map(r => r.path)).out.split("\n").filter(Boolean)
        .map(l => { const t = l.indexOf("\t"); return [l.slice(t + 1), l.slice(0, t).split(" ")[2]]; }) : []);
      b.rows = rows.map(r => ({ ...r, blob: blobs.get(r.path) ?? null }));
      // exit 1: conflicts; 0 none; anything else (no merge base): unknown, no mark
      const mt = rows.length ? scratch("merge-tree", "--write-tree", "--name-only", main, b.ref) : { status: 0 };
      b.conflicts = mt.status === 1 ? mergeTreePaths(mt.out) : [];
    }
  } finally { rmSync(objs, { recursive: true, force: true }); }
  return bs;
}

/** I/O: the facts of one run (readRun's, and git's) as the v1 document; feature: that feature's too. */
export function readShow(row, { projectDir, main = "main", stateRoot = "", ledger = "", queue = "", runner = false, feature = null, now, env = process.env }) {
  const x = readRun(row, { stateRoot, ledger }), git = gitIn(projectDir);
  x.needs = readNeeds(x, { now, runner, queue });
  const r = runObject(x, now), led = p => join(ledger, x.project, x.run, p);
  const log = text(join(x.record, "harness-log.md")) ?? text(led("harness-log.md")) ?? "";
  const origin = git("config", "--get", "remote.origin.url").out.trim();
  const all = branchesOf(git, x.run), bs = changesOf(git, projectDir, all, `refs/remotes/origin/${main}`) ?? [], ch = bs.length || all.length === 0 ? combine(bs) : null;
  const urlOf = b => b?.rows?.length ? compareUrl(origin, main, b.name) : null;
  const own = bs.find(b => b.name === `harness/${x.run}`), g = gitOf(projectDir, `harness/${x.run}`, main);
  const st = x.worktree_exists ? git("-C", x.worktree, "status", "--porcelain", "--untracked-files=normal") : null;
  const tags = new Set(git("for-each-ref", "--format=%(refname:short)", `refs/tags/run/${x.run}/`).out.split("\n").filter(Boolean));
  const doc = {
    v: 1, run: x.run, project: x.project, state: r.state, end_reason: r.end_reason, passing: r.features.passing, total: r.features.total,
    worktree: { path: x.worktree, exists: x.worktree_exists, changed: st?.ok ? st.out.split("\n").filter(Boolean).length : null },
    branch: { name: `harness/${x.run}`, head: g?.head ?? null, ahead: g?.ahead ?? null, behind: g?.behind ?? null },
    // the record where it is now: the worktree's, else (gc removed it) the ledger's copy
    compare: urlOf(own), record: x.worktree_exists || text(led("harness-log.md")) == null ? x.record : join(ledger, x.project, x.run), state_dir: x.state_dir,
    lanes: x.lanes.map(l => { const b = all.find(b => b.milestone === l.milestone);
      return { milestone: l.milestone, branch: `harness-lane/${x.run}/${l.milestone}`, exists: Boolean(b), slot: l.slot, open: l.live, compare: urlOf(b) }; }),
    milestones: milestonesOf(log).map(m => ({ id: m.id, status: m.status, tag: tags.has(`run/${x.run}/${m.id}`) ? `run/${x.run}/${m.id}` : null, pr: m.url })),
    main, changes: ch && { files: ch.files, added: ch.added, deleted: ch.deleted, rows: ch.rows },
    conflicts: ch?.conflicts ?? [],
    needs: needsOrder(x.needs).map(i => ({ ref: i.ref, reason: i.reason, headline: i.card?.headline ?? i.title ?? i.reason })),
  };
  // the compare lines: every run branch with changes, in order
  const urls = bs.map(urlOf).filter(Boolean);
  const head = { r, x, extra: extraOf(x, 0) };
  if (!feature) return { doc, urls, head };
  const list = x.list ?? json(led("feature_list.json"));
  const f = (Array.isArray(list) ? list : list?.features ?? []).find(f => f.id === feature);
  if (!f) return { doc, urls, head, missing: true };
  const metrics = x.metrics.length ? x.metrics : jsonl(text(led("metrics.jsonl")));
  const entries = jsonl(text(join(x.record, "entries.jsonl")) ?? text(led("entries.jsonl")));
  const files = [...new Set(entries.filter(e => e.feature === feature).flatMap(e => Array.isArray(e.files) ? e.files : [])
    .filter(p => typeof p === "string" && p).map(p => isAbsolute(p) ? p : join(x.worktree, p)))].sort();
  // its commits on every run branch and run tag, newest first: "<id>…" or "WIP: <id>…", the id a whole word
  // (since the run started: an id like A or F1 recurs across a project's runs, whose commits main holds; the subject
  // only: --grep matches any line of the message)
  const id = feature.replace(/[.*+?^${}()|[\]\\]/g, "\\$&"), re = new RegExp(`^(WIP: )?${id}([^A-Za-z0-9_-]|$)`);
  const revs = [...all.map(b => b.ref), ...[...tags].map(t => `refs/tags/${t}`)], since = r.started_at ? [`--since=${r.started_at}`] : [];
  const lg = revs.length ? git("log", "--format=%h %s", ...since, "-E", `--grep=^(WIP: )?${id}([^A-Za-z0-9_-]|$)`, ...revs, "--").out : "";
  const commits = lg.split("\n").filter(Boolean).map(l => ({ sha: l.slice(0, l.indexOf(" ")), subject: l.slice(l.indexOf(" ") + 1) })).filter(c => re.test(c.subject));
  const item = needsOrder(x.needs).find(i => i.feature === feature && !i.resolved_at) ?? null;
  doc.feature = { id: f.id, milestone: f.milestone ?? "default", description: f.description ?? "", passes: Boolean(f.passes),
    attempts: x.attempts?.[feature] ?? 0, max_attempts: x.max_attempts, steps: Array.isArray(f.steps) ? f.steps.map(String) : [],
    sessions: metrics.filter(m => m.feature === feature), files, commits, card: item?.card ?? null };
  return { doc, urls, head, item };
}

// ---- the text views (pure) ----
const fieldsOf = (doc, ctx, env, urls) => {
  const sep = ` ${glyph("sep", ctx)} `, room = ctx.width - 13, path = p => ctx.narrow ? cutFront(home(p, env), room, ctx) : home(p, env);
  const w = doc.worktree, b = doc.branch;
  return [
    { label: "worktree", value: w.exists ? `${path(w.path)} (${w.changed ? `${w.changed} changed file${w.changed === 1 ? "" : "s"}` : "clean"})` : "removed" },
    { label: "branch", value: b.head ? `${b.name} @ ${b.head}${b.ahead != null ? `${sep}${b.ahead} ahead, ${b.behind} behind` : ""}` : `${b.name} (gone)` },
    { label: "record", value: doc.record.startsWith(w.path + "/") ? path(doc.record.replace(/\/*$/, "/"))
      : `${ctx.narrow ? cutFront(home(doc.record + "/", env), room - 14, ctx) : home(doc.record + "/", env)} (ledger copy)` },
    { label: "state", value: path(doc.state_dir.replace(/\/*$/, "/")) },
    { label: "lanes", value: doc.lanes.map(l => [l.milestone, l.exists ? l.branch : `${l.branch} (gone)`, `slot ${l.slot ? l.slot.replace(/^.*\/slot-/, "") : "?"}`,
      l.open ? "open" : "closed"].join(sep)) },
    ...doc.milestones.map(m => { const pr = prOf(m.pr);
      return { label: m.status, value: [m.id, m.tag && `tag ${m.tag}`, pr && `PR #${pr}`].filter(Boolean).join(sep), url: pr ? null : m.pr }; }),
    ...urls.map(u => ({ label: "", url: u })),
  ];
};

// the changes rows: status, path (cut at the front), +/−, the conflict mark; narrow: the mark's glyph and the +/− total
function changeRows(rows, ctx) {
  const minus = ctx.glyphs === "ascii" ? "-" : "−", x = glyph("failed", ctx), anyC = rows.some(r => r.conflict);
  const plus = r => r.added == null ? "bin" : r.added || !r.deleted ? `+${r.added}` : "", del = r => r.deleted ? `${minus}${r.deleted}` : "";
  const widest = f => Math.max(0, ...rows.map(r => displayWidth(f(r)))), longest = widest(r => r.path);
  if (ctx.narrow) {
    // the +/− total: + for additions only, ± once anything was deleted (a deleted file is never "+40")
    const tot = r => r.added == null ? "bin" : `${r.deleted ? (ctx.glyphs === "ascii" ? "+-" : "±") : "+"}${r.added + r.deleted}`, tw = widest(tot);
    const pw = Math.min(longest, ctx.width - 7 - (anyC ? 3 : 0) - tw);
    return rows.map(r => `  ${r.status}  ${pad(cutFront(r.path, pw, ctx), pw)}  ${anyC ? `${r.conflict ? paint(x, "red", ctx) : " "}  ` : ""}${pad(tot(r), tw, "right")}`);
  }
  const aw = widest(plus), dw = widest(del), mark = `${x} conflicts`;
  const pw = Math.min(longest, ctx.width - 7 - aw - (dw ? dw + 1 : 0) - (anyC ? displayWidth(mark) + 2 : 0));
  return rows.map(r => `  ${r.status}  ${pad(cutFront(r.path, pw, ctx), pw)}  ${pad(plus(r), aw, "right")}${dw ? " " + pad(del(r), dw, "right") : ""}${
    r.conflict ? "  " + paint(mark, "red", ctx) : ""}`.trimEnd());
}

// items joined by " · ", wrapped at the width under a 2-column indent (a path wider than the line cut at the front)
function joined(items, ctx) {
  const sep = ` ${glyph("sep", ctx)} `, room = ctx.width - 2, out = [];
  let cur = "";
  items.map(p => cutFront(p, room - displayWidth(sep.trimEnd()), ctx)).forEach((p, i, a) => {
    const t = p + (i < a.length - 1 ? sep.trimEnd() : "");
    if (cur && displayWidth(cur) + 1 + displayWidth(t) <= room) cur += " " + t; else { if (cur) out.push(cur); cur = t; }
  });
  return [...out, ...cur ? [cur] : []].map(l => "  " + l);
}

/** Pure: `harness show <run>`'s lines. head: {r, x, extra} for the card's header (status.mjs cardHeader); urls: the
 *  compare URLs; all: --files (every changes row). */
export function renderShow(doc, ctx, { env = {}, head, urls = [], all = false } = {}) {
  const sep = ` ${glyph("sep", ctx)} `, minus = ctx.glyphs === "ascii" ? "-" : "−", c = doc.changes;
  const out = card(cardHeader(head.r, head.x, head.extra, ctx), fieldsOf(doc, ctx, env, urls), ctx);
  if (!c) out.push(cut(`CHANGES vs origin/${doc.main}: unknown (no origin/${doc.main} here: git fetch in the project)`, ctx.width, ctx));
  else if (!c.files) out.push(section(`CHANGES vs origin/${doc.main}`, 0, "", ctx));
  else {
    out.push(section(`CHANGES vs origin/${doc.main}`, null, `${c.files} file${c.files === 1 ? "" : "s"}${sep}+${c.added} ${minus}${c.deleted}`, ctx),
      ...changeRows(all ? c.rows : c.rows.slice(0, TOP), ctx));
    const k = c.rows.length - TOP, more = `+${k} more: harness show ${doc.run} --files`;
    if (!all && k > 0) out.push("  " + (displayWidth(more) + 2 <= ctx.width ? more : `+${k} more: --files`));
  }
  if (doc.conflicts.length) out.push(section(`CONFLICTS with origin/${doc.main}`, doc.conflicts.length, "", ctx), ...joined(doc.conflicts, ctx));
  if (doc.needs.length) out.push(section("NEEDS YOU", doc.needs.length, "", ctx),
    ...doc.needs.map(i => cut(`${paint(glyph("needs", ctx), "yellow", ctx)} ${i.headline}`, ctx.width, ctx)), `  harness needs ${doc.run}`);
  return out;
}

/** Pure: `harness show <run> <feature>`'s lines: the header and rule, the feature's card, then its open needs card. */
export function renderFeature(doc, ctx, { env = {}, head, item = null } = {}) {
  const f = doc.feature, sep = ` ${glyph("sep", ctx)} `, room = ctx.width - 13;
  const sessions = f.sessions.map(m => [m.at ? when(Date.parse(m.at) / 1000, ctx.now) : "?", m.role ?? m.kind, alias(m.model),
    `${Math.round((m.wall_s ?? 0) / 60)} min`, `$${(m.cost_usd ?? 0).toFixed(2)}`, m.result ?? `exit ${m.exit}`].join(sep));
  const out = card(cardHeader(head.r, head.x, head.extra, ctx), [
    { label: "feature", value: [f.id, f.milestone, f.passes ? "passes" : "not passing", `attempt ${f.attempts} of ${f.max_attempts}`].join(sep) },
    { label: "description", value: f.description },
    { label: "steps", value: f.steps.map((s, i) => cut(`${i + 1}. ${s.replace(/\s+/g, " ")}`, room, ctx)) },
    { label: "sessions", value: sessions },
    { label: "files", value: f.files.map(p => ctx.narrow ? cutFront(home(p, env), room, ctx) : home(p, env)) },
    { label: "commits", value: f.commits.map(c => cut(`${c.sha} ${c.subject}`, room, ctx)) },
  ], ctx);
  return item ? [...out, ...needsCard(item, ctx, env)] : out;
}

function main(argv) {
  const o = { _: [] }, flags = new Set(["--json", "--files"]);
  for (let i = 0; i < argv.length; i++) {
    if (flags.has(argv[i])) o[argv[i].slice(2)] = true;
    else if (argv[i].startsWith("--")) o[argv[i].slice(2)] = argv[++i];
    else o._.push(argv[i]);
  }
  const [run, feature = null] = o._;
  if (!run || !o["project-dir"] || o._.length > 2) {
    console.error("usage: show.mjs <run> [<feature>] [--files] [--json] --project-dir <d> (+ --state-root --ledger --queue --runner)");
    return 2;
  }
  const ctx = context({ env: process.env, isTTY: process.stdout.isTTY, columns: process.stdout.columns });
  const row = (() => { try { return readFileSync(0, "utf8"); } catch { return ""; } })().split("\n").find(l => l.split("\t")[0] === run);
  if (!row) { console.error(`harness: no run '${run}' (see: harness status)`); return 1; }
  const s = readShow(row, { projectDir: o["project-dir"], main: o.main || "main", stateRoot: o["state-root"] ?? "", ledger: o.ledger ?? "", queue: o.queue ?? "",
    runner: o.runner === "1", feature, now: ctx.now });
  if (s.missing) { console.error(`harness: no feature '${feature}' in ${run}`); return 1; }
  if (o.json) { process.stdout.write(JSON.stringify(s.doc, null, 2) + "\n"); return 0; }
  const lines = feature ? renderFeature(s.doc, ctx, { env: process.env, head: s.head, item: s.item })
    : renderShow(s.doc, ctx, { env: process.env, head: s.head, urls: s.urls, all: Boolean(o.files) });
  process.stdout.write(lines.join("\n") + "\n");
  return 0;
}

if (process.argv[1] && fileURLToPath(import.meta.url) === resolve(process.argv[1])) process.exit(main(process.argv.slice(2)));
