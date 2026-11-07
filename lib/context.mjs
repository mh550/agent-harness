// The context bundle's glossary: the IDs each run's own section of the gatherer's markdown names, resolved against its
// feature list and its docs (lib/glossary.mjs), merged across the runs (docs/plans/2026-11-07-A2-context-bundle.md §2.3).
//
//   node lib/context.mjs bundle <context.md> <runs.tsv> [--max-bytes <n>] [--json <out> --id <id> --since <ts|"">]
//                                       → the ## Glossary markdown on stdout; with --json, context.json written there too
//   node lib/context.mjs prune <events dir> <keep id> [--days <n>]   → removes the bundles with no file newer than <n>
//                                       days (30; the real clock) but <keep id>, and says how many (§3.2)
//
// runs.tsv (lib/context.sh's context_glossary): one run per line, tab-separated: state dir, run, project, ended,
// running (1/0), features, record, worktree, docs root, needs json (`harness needs <run> --json`).
import { existsSync, readdirSync, readFileSync, rmSync, statSync, writeFileSync, renameSync } from "node:fs";
import { join } from "node:path";
import { answersLine } from "./inbox.mjs";
import { captured, isMain, runCli } from "./cli.mjs";
import { findIds, fsReader, glossaryMarkdown, knownIds, resolveIds } from "./glossary.mjs";

const FIELDS = ["state", "run", "project", "ended", "running", "features", "record", "worktree", "docs", "needs"];

// the gatherer's markdown, run, project, ends (the other runs' headings and the sections after them) → the lines from
// `### <run> (<project>)` up to the next `### ` or `## ` heading outside its ~~~ fences (a fenced INBOX.md has headings
// of its own), or the next line of ends, fenced or not (a part cut mid-fence leaves an odd ~~~)
export function runSection(md, run, project, ends = []) {
  const lines = String(md ?? "").split("\n"), head = `### ${run} (${project})`, at = lines.indexOf(head);
  if (at < 0) return "";
  const stop = new Set(ends.filter(e => e !== head));
  let end = at + 1, fenced = false;
  for (; end < lines.length; end++) {
    if (stop.has(lines[end])) break;
    if (lines[end] === "~~~") fenced = !fenced;
    else if (!fenced && /^#{2,3} /.test(lines[end])) break;
  }
  return lines.slice(at, end).join("\n");
}

// a run's section, its open needs items → the text its IDs are found in: the section (never the gatherer's shared
// parts, which are other runs' words), then each open item's why and question
export function runText(section, needs = []) {
  const items = Array.isArray(needs) ? needs : [];
  const more = items.flatMap(n => [n?.card?.why, n?.card?.question?.text]).filter(x => typeof x === "string" && x);
  return [section, ...more].join("\n");
}

// [{ glossary, unresolved }] in run order → one: each (id, kind, source) once, and an ID unresolved in one run but
// resolved in another is not unresolved
export function mergeResults(results) {
  const glossary = [], seen = new Set(), unresolved = [];
  for (const r of results) for (const e of r.glossary ?? []) {
    const k = `${e.id}\0${e.kind}\0${e.source}`;
    if (!seen.has(k)) { seen.add(k); glossary.push(e); }
  }
  const resolved = new Set(glossary.map(e => e.id));
  for (const r of results) for (const id of r.unresolved ?? []) if (!resolved.has(id) && !unresolved.includes(id)) unresolved.push(id);
  return { glossary, unresolved };
}

// [{ dir, newestMs }], now, days → the dirs whose newest file is older than <days> days (the bundles retention removes)
export const staleBundles = (dirs, nowMs, days = 30) => dirs.filter(d => d.newestMs < nowMs - days * 86400000).map(d => d.dir);

const squash = (s, max = 600) => [...String(s ?? "").replace(/\s+/g, " ").trim()].slice(0, max).join("");
const unhead = s => squash(String(s ?? "").replace(/^#+\s+/, ""));   // a card's question text is its heading line

// INBOX.md → its open asks: each `### ` block above `## Answers` (lib/inbox.mjs answersLine), outside the steering
// comment, as { line (1-based, its heading's), text (the heading without its #s and the lines under it, squashed) }
export function openAsks(inbox) {
  const lines = String(inbox ?? "").split("\n"), cut = answersLine(inbox ?? "");
  const above = lines.slice(0, cut < 0 ? lines.length : cut), asks = [];
  let inside = false, fence = false, cur = null;
  above.forEach((l, i) => {
    if (inside) { if (l.includes("-->")) inside = false; return; }
    if (l.includes("<!--") && !l.includes("-->")) { inside = true; return; }
    if (/^\s*```/.test(l)) fence = !fence;   // a heading in a code block is text (inbox.mjs headings' rule)
    if (!fence && /^### \d{4}-\d\d-\d\d \d\d:\d\d \(local\)/.test(l)) { cur = null; return; }   // an answer block, not an ask
    if (!fence && /^### /.test(l)) { cur = { line: i + 1, parts: [l.replace(/^#+\s+/, "")] }; asks.push(cur); }
    else if (!fence && /^#{1,2} /.test(l)) cur = null;
    else if (cur) cur.parts.push(l.replace(/<!--.*?-->/g, ""));
  });
  return asks.map(a => ({ line: a.line, text: squash(a.parts.join(" ")) }));
}

const openOf = needs => (Array.isArray(needs) ? needs : []).filter(n => n && n.resolved_at == null);

// INBOX.md, the run's needs items → open_questions (*default*: from the files progress.md is rendered from): the INBOX's
// open asks, then the open question items' text not already among them; at most 12
export function openQuestions(inbox, needs) {
  const out = openAsks(inbox).map(a => a.text);
  for (const n of openOf(needs)) {
    const t = n.reason === "question" ? unhead(n.card?.question?.text) : "";
    if (t && !out.includes(t)) out.push(t);
  }
  return out.slice(0, 12);
}

// the needs items, the state dir's parked.json, INBOX.md → parked[]: each open parked item's feature, its session's
// PARKED reason (parked.json, else the card's headline), and its INBOX ask (the block that names the feature, at the
// card's line or else the first; the INBOX may have changed since the item opened), else the card's question text
export function parkedItems(needs, parked, inbox) {
  const asks = openAsks(inbox);
  return openOf(needs).filter(n => n.reason === "parked").map(n => {
    const q = n.card?.question, f = String(n.feature ?? "").replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
    const names = a => f !== "" && new RegExp(`^${f}(?![\\w-])`).test(a.text);
    const at = asks.find(a => a.line === q?.line && names(a)) ?? asks.find(names);
    const why = squash(parked?.[n.feature]?.why) || squash(String(n.card?.headline ?? "").replace(/^.*? parked: /, "")) || null;
    return { feature: n.feature ?? null, why, question: at?.text || unhead(q?.text) || null };
  });
}

// one runs.tsv row and what its files hold → its context.json run entry, keys in the spec's order
export function runEntry(row, { summary = null, needs = [], parked = null, inbox = "" } = {}) {
  const rec = f => join(row.record, f);
  return {
    run: row.run, project: row.project, ended: row.ended, running: row.running === "1", features: row.features,
    paths: { record: row.record, worktree: row.worktree, state: row.state, report: rec("report.md"), inbox: rec("INBOX.md"), progress: rec("progress.md") },
    summary, parked: parkedItems(needs, parked, inbox), open_questions: openQuestions(inbox, needs),
  };
}

// { id, generatedAt, since }, the run entries, the merged glossary → context.json (docs/specs/2026-10-22-n8n-events.md §A2)
export const contextJson = ({ id, generatedAt, since }, runs, { glossary, unresolved }) => ({
  v: 1, id, generated_at: generatedAt, scope: { runs: runs.map(r => r.run), since: since || null }, runs, glossary, unresolved,
});

// a runs.tsv line → its row ({ state, run, … }); a short line's missing fields are ""
export const parseRow = line => Object.fromEntries(FIELDS.map((k, i) => [k, line.split("\t")[i] ?? ""]));

const readJson = p => { try { return JSON.parse(readFileSync(p, "utf8")); } catch { return null; } };
const readText = p => { try { return readFileSync(p, "utf8"); } catch { return ""; } };
const noDocs = { root: "", files: () => [], read: () => null };

// the gatherer's own headings after the runs (lib/context.sh's context_runs): a run's section never runs past them
const AFTER_RUNS = ["## Retro backlog (ledger/retro-backlog.jsonl)", "## Glossary"];

// one run's row, the gatherer's markdown, every run's heading → { glossary, unresolved }
function resolveRun(row, md, ends) {
  const listPath = join(row.record, "feature_list.json");
  let text = null;
  try { text = readFileSync(listPath, "utf8"); } catch { text = null; }
  let parsed = null;
  try { parsed = text ? JSON.parse(text) : null; } catch { parsed = null; }
  const ids = findIds(runText(runSection(md, row.run, row.project, ends), readJson(row.needs) ?? []), knownIds(parsed));
  const reader = row.docs && existsSync(row.docs) ? fsReader(row.docs) : noDocs;
  return resolveIds(ids, { featureList: text == null ? null : { path: listPath, text } }, reader);
}

// <events dir>, the id kept → [{ dir, newestMs }] of every other bundle: a dir is as new as its newest file (writing
// event.json sets the dir's own mtime), and one with no file as its own mtime
function bundles(events, keep) {
  const newest = p => {
    let m = 0;
    for (const e of readdirSync(p, { withFileTypes: true })) {
      const q = join(p, e.name);
      try { m = Math.max(m, e.isDirectory() ? newest(q) : statSync(q).mtimeMs); } catch { /* gone meanwhile */ }
    }
    return m;
  };
  return readdirSync(events, { withFileTypes: true }).filter(e => e.isDirectory() && e.name !== keep && !e.name.startsWith("."))
    .flatMap(e => {   // an unreadable dir, or one another prune removed meanwhile, is skipped: it never stops the rest
      const p = join(events, e.name);
      try { return [{ dir: e.name, newestMs: newest(p) || statSync(p).mtimeMs }]; } catch { return []; }
    });
}

const USAGE = 'usage: context.mjs bundle <context.md> <runs.tsv> [--max-bytes <n>] [--json <out> --id <id> --since <ts|"">] | prune <events dir> <keep id> [--days <n>]';

export const main = captured(([cmd, ...args], io, say, put) => {
  const usage = () => { console.error(USAGE); return 2; };
  if (cmd === "prune") {
    const [events, keep, ...rest] = args;
    let days = 30;
    if (!events || !keep) return usage();
    if (rest.length) { if (rest[0] !== "--days" || !/^\d+$/.test(rest[1] ?? "") || rest.length > 2) return usage(); days = Number(rest[1]); }
    let gone;
    try { gone = staleBundles(bundles(events, keep), Date.now(), days); for (const d of gone) rmSync(join(events, d), { recursive: true, force: true }); }
    catch (e) { console.error(`context: ${e.message}`); return 1; }
    if (gone.length) say(`events: removed ${gone.length} bundle${gone.length === 1 ? "" : "s"} older than ${days} days`);
    return 0;
  }
  const [ctx, tsv, ...rest] = args;
  if (cmd !== "bundle" || !ctx || !tsv) return usage();
  let max = Infinity, json = null, id = null, since = "";
  for (let i = 0; i < rest.length; i++) {
    if (rest[i] === "--max-bytes" && /^\d+$/.test(rest[i + 1] ?? "")) max = Number(rest[++i]);
    else if (rest[i] === "--json" && rest[i + 1]) json = rest[++i];
    else if (rest[i] === "--id" && rest[i + 1]) id = rest[++i];
    else if (rest[i] === "--since" && i + 1 < rest.length) since = rest[++i];
    else return usage();
  }
  if (json && !id) return usage();
  let md, rows;
  try { md = readFileSync(ctx, "utf8"); rows = readFileSync(tsv, "utf8").split("\n").filter(Boolean).map(parseRow); }
  catch (e) { console.error(`context: ${e.message}`); return 1; }
  const ends = [...rows.map(r => `### ${r.run} (${r.project})`), ...AFTER_RUNS];
  const merged = mergeResults(rows.map(r => resolveRun(r, md, ends)));
  if (json) {
    const runs = rows.map(r => runEntry(r, { summary: readJson(join(r.record, "summary.json")), needs: readJson(r.needs) ?? [],
      parked: readJson(join(r.state, "parked.json")), inbox: readText(join(r.record, "INBOX.md")) }));
    const body = JSON.stringify(contextJson({ id, generatedAt: new Date().toISOString(), since }, runs, merged), null, 2) + "\n";
    try { writeFileSync(`${json}.tmp`, body); renameSync(`${json}.tmp`, json); }   // whole or not at all: n8n reads it
    catch (e) { console.error(`context: ${e.message}`); return 1; }
  }
  put(glossaryMarkdown(merged, max));
  return 0;
});

if (isMain(import.meta.url)) runCli(main);
