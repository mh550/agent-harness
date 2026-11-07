// The ID glossary, by code (no model): feature, milestone and decision IDs found in a text and resolved against a run's
// feature list and a project's docs (docs/specs/2026-10-22-n8n-events.md §A2, docs/plans/2026-11-07-A2-context-bundle.md §1).
//
//   node lib/glossary.mjs <worktree> <feature_list.json> < text   → JSON { glossary: [{ id, kind, text, source }], unresolved: [id] }
//
// Pure apart from fsReader: every file read goes through a reader { root, files() → [{ path, mtimeMs, titleOnly }],
// read(path) → text | null }, so the unit tests give their own mtimes. Nothing is guessed: every pattern is the ID itself,
// word-bounded, and an ID nothing names is listed under unresolved.
import { existsSync, readdirSync, readFileSync, statSync } from "node:fs";
import { isAbsolute, join, resolve } from "node:path";
import { captured, isMain, readStdin, runCli } from "./cli.mjs";
import { decisionsStore } from "./memlint.mjs";

const CUT = 300;
const cut = s => { const cp = [...s]; return cp.length > CUT ? cp.slice(0, CUT).join("") : s; };

// markdown stripped: links to their text, emphasis and code marks gone, a leading heading/quote/list mark gone, one space
export const strip = s => s
  .replace(/!?\[([^\]]*)\]\([^)]*\)/g, "$1")
  .replace(/\*\*|__|`/g, "")
  .replace(/(^|[^\w*])\*([^*\s][^*]*?)\*(?![\w*])/g, "$1$2")
  .replace(/\s+/g, " ").trim()
  .replace(/^(?:#{1,6}\s+|>\s*|[-*+]\s+|\d+[.)]\s+)/, "")
  .trim();

// the spec's three shapes, decisions first so D-H1 never yields H1. A D<n> followed by -<digit> is a feature's id
// (D1-01 in a project whose milestones start with D), so the decision pattern leaves it to the feature pass.
const PASSES = [
  ["decision", [/\bD-H\d+\b/g, /\bD\d+\b(?!-\d)/g]],
  ["feature", [/\b[A-Z]{1,2}\d+-\d+\b/g]],
  ["milestone", [/\b[A-Z]{1,2}\d+\b(?!-\d)/g]],
];
const esc = s => s.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");

// text, known ([{ id, kind }] from knownIds: the run's own ids the regexes may miss, e.g. N1F-01, S2-05a) →
// [{ id, kind }], unique, in order of first appearance. Each pass masks what it took, so no later pass sees inside it.
export function findIds(text, known = []) {
  let masked = String(text ?? "");
  const hits = [];
  const take = (kind, re) => {
    masked = masked.replace(re, (m, ...a) => {
      const at = a.at(-2);
      hits.push({ at, id: m, kind });
      return " ".repeat(m.length);
    });
  };
  // the list's own ids first, longest first, so no pattern splits one (S2-D1 is never S2 and D1)
  for (const k of [...known].sort((a, b) => b.id.length - a.id.length)) take(k.kind, new RegExp(`(?<![\\w-])${esc(k.id)}(?![\\w-])`, "g"));
  for (const [kind, res] of PASSES) for (const re of res) take(kind, new RegExp(re.source, "g"));
  const seen = new Set();
  return hits.sort((a, b) => a.at - b.at).filter(h => !seen.has(h.id) && seen.add(h.id)).map(({ id, kind }) => ({ id, kind }));
}

const featuresOf = list => { const f = Array.isArray(list) ? list : list?.features; return Array.isArray(f) ? f.filter(x => x && typeof x === "object") : []; };

// a parsed feature list → its feature ids and milestone ids, for findIds' known
export function knownIds(list) {
  const named = x => typeof x === "string" && /\w/.test(x);
  const fs = featuresOf(list).filter(f => named(f.id));
  const ms = [...new Set(fs.map(f => f.milestone).filter(named))];
  return [...fs.map(f => ({ id: f.id, kind: "feature" })), ...ms.map(id => ({ id, kind: "milestone" }))];
}

// A heading names an ID when the ID opens it (after an optional `<n>. `) and what follows is the end, punctuation or a
// separator (` ·`, ` (`, ` —`, `:`): `## 9. M8 (built)`, `## M8: lifecycle`, `### D-H1 · …`. Never `## D24 on (…)` (a
// section of rows) nor `## D1–D23` (a range), nor `### New with M8` (a mention).
const HEADING = /^(#{1,6})\s+((?:\d+\.\s+)?)([\w-]+)(.*)$/;
const RANGE = /^\s*[-–—]\s*[A-Z]{1,2}\d/;   // `D1 – D23`: a range, not D1
const headingTail = t => !RANGE.test(t) && /^(?:$|[:,;)]|\.(?!\d)|\s+(?:[·(—–|:-]|$))/.test(t);
// A table row names an ID when its first cell starts with it: `| D24 |`, `| D36 *default* |`, `| D24 (…) |`; never a range
const ROW = /^\|\s*([\w-]+)([^|]*)\|(.*)$/;
const rowTail = t => !RANGE.test(t) && /^(?:$|[^\w\-–—/])/.test(t);

// one file's text → its named lines: [{ token, type: "heading" | "row", line, text() }], code fences skipped
function index(text, titleOnly) {
  const lines = text.split(/\r?\n/), out = [], code = [];
  let fence = null;   // memlint's rule: a fence closes on the same mark, at least as long, with nothing after it
  for (const l of lines) {
    const f = /^\s*(`{3,}|~{3,})/.exec(l)?.[1];
    code.push(!!fence || !!f);
    if (!fence && f) fence = f;
    else if (fence && f && f[0] === fence[0] && f.length >= fence.length && /^\s*[`~]+\s*$/.test(l)) fence = null;
  }
  for (let i = 0; i < lines.length; i++) {
    const l = lines[i];
    if (code[i]) continue;
    if (titleOnly && !/^#\s/.test(l)) continue;
    const h = HEADING.exec(l);
    if (h && headingTail(h[4])) {
      const under = [];
      if (!titleOnly) for (let j = i + 1; j < lines.length && (code[j] || !/^#{1,6}\s/.test(lines[j])) && under.join(" ").length < 4 * CUT; j++) if (!code[j] && lines[j].trim()) under.push(lines[j]);
      const head = l.replace(/^#{1,6}\s+/, "").trim();
      out.push({ token: h[3], type: "heading", line: i + 1, text: () => cut(strip(under.length ? `${head}. ${under.join(" ")}` : head)) });
    }
    if (titleOnly) break;
    const r = ROW.exec(l);
    if (r && rowTail(r[2])) {
      const cells = [r[2], ...r[3].split("|")].map(c => strip(c)).filter(Boolean);
      out.push({ token: r[1], type: "row", line: i + 1, text: () => cut(cells.join(" · ")) });
    }
  }
  return out;
}

// ids ([{ id, kind }] from findIds), { featureList: { path, text } | null }, reader → { glossary, unresolved }.
// A feature resolves against the list; a milestone against the list, then the doc headings that open with it; a decision
// against the doc rows and headings (a D<n> also as a milestone, both kept). Docs newest file first, then line order.
export function resolveIds(ids, { featureList = null } = {}, reader = { root: "", files: () => [], read: () => null }) {
  let parsed = null;
  try { parsed = featureList?.text ? JSON.parse(featureList.text) : null; } catch { parsed = null; }
  const features = featuresOf(parsed).filter(f => typeof f.id === "string" && f.id);
  const listLines = String(featureList?.text ?? "").split("\n");
  const idLine = id => { const re = new RegExp(`"id":\\s*"${esc(id)}"`), n = listLines.findIndex(l => re.test(l)); return n < 0 ? 1 : n + 1; };
  const listSource = id => `${featureList.path}:${idLine(id)}`;

  let docs = null;   // read once, on the first ID that needs the docs
  const docIndex = () => docs ??= reader.files()
    .slice().sort((a, b) => (b.mtimeMs - a.mtimeMs) || (a.path < b.path ? -1 : a.path > b.path ? 1 : 0))
    .map(f => { const t = reader.read(f.path); return t == null ? null : { path: f.path, named: index(t, !!f.titleOnly) }; })
    .filter(Boolean);
  const docSource = (path, line) => `${reader.root ? join(reader.root, path) : path}:${line}`;
  const fromDocs = (id, kind, types) => docIndex().flatMap(d => d.named
    .filter(n => n.token === id && types.includes(n.type))
    .map(n => ({ id, kind, text: n.text(), source: docSource(d.path, n.line) })));

  const fromList = id => {
    const f = features.find(x => x.id === id);
    if (!f) return [];
    const m = typeof f.milestone === "string" && f.milestone ? ` (milestone ${f.milestone})` : "";
    return [{ id, kind: "feature", text: cut(strip(String(f.description ?? ""))) + m, source: listSource(id) }];
  };
  const milestoneOfList = id => {
    const fs = features.filter(x => x.milestone === id);
    if (!fs.length) return [];
    const names = fs.slice(0, 8).map(x => x.id).join(", ") + (fs.length > 8 ? ", …" : "");
    const passing = fs.filter(x => x.passes === true).length;
    return [{ id, kind: "milestone", text: `milestone in feature_list.json: ${names} (${fs.length} features, ${passing} passing)`, source: listSource(fs[0].id) }];
  };

  const glossary = [], unresolved = [], seen = new Set();
  for (const { id, kind } of ids) {
    let es;
    // a D<n> is a decision and a milestone whichever pass found it (a list milestone D1 is taken as known first)
    if (kind === "feature") es = fromList(id);
    else if (kind === "decision" || /^D\d+$/.test(id)) es = [...fromDocs(id, "decision", ["row", "heading"]), ...(id.startsWith("D-H") ? [] : milestoneOfList(id))];
    else es = [...milestoneOfList(id), ...fromDocs(id, "milestone", ["heading"])];
    const fresh = es.filter(e => { const k = `${e.id}\0${e.source}`; return !seen.has(k) && seen.add(k); });
    if (fresh.length) glossary.push(...fresh); else if (!es.length) unresolved.push(id);
  }
  return { glossary, unresolved };
}

const bytes = s => Buffer.byteLength(s);

// { glossary, unresolved }, maxBytes → the markdown section: `## Glossary`, one `- **<id>** (<kind>): <text> (<source>)`
// line per entry, then `Unresolved: <ids>`. Whole lines only: past the cap it ends `… (<n> more; context.json lists
// every one)`, n the entries and unresolved IDs left out; "" when not even that fits.
export function glossaryMarkdown({ glossary = [], unresolved = [] } = {}, maxBytes = Infinity) {
  const head = "## Glossary\n\n";
  const items = glossary.map(e => ({ s: `- **${e.id}** (${e.kind}): ${e.text} (${e.source})\n`, n: 1 }));
  if (unresolved.length) items.push({ s: `${items.length ? "\n" : ""}Unresolved: ${unresolved.join(", ")}\n`, n: unresolved.length });
  if (!items.length) return bytes(head + "(no IDs found)\n") <= maxBytes ? head + "(no IDs found)\n" : "";
  const full = head + items.map(x => x.s).join("");
  if (bytes(full) <= maxBytes) return full;
  const more = n => `… (${n} more; context.json lists every one)\n`;
  let out = head, left = items.reduce((a, x) => a + x.n, 0);
  for (const x of items) {
    if (bytes(out + x.s + more(left - x.n)) > maxBytes) break;
    out += x.s; left -= x.n;
  }
  return bytes(out + more(left)) <= maxBytes ? out + more(left) : "";
}

// the docs a glossary reads, relative to root: CLAUDE.md, README.md, docs/**/*.md, journal/decisions.md,
// journal/decisions/*.md (title line only) and the project's decisions store (lib/memlint.mjs) when it lies elsewhere
export function fsReader(root, { mtimes = {} } = {}) {
  root = resolve(root);
  const isFile = p => { try { return statSync(join(root, p)).isFile(); } catch { return false; } };
  const mds = (dir, deep) => {
    let es;
    try { es = readdirSync(join(root, dir), { withFileTypes: true }); } catch { return []; }
    return es.flatMap(e => {
      const p = `${dir}/${e.name}`;
      if (e.isDirectory()) return deep ? mds(p, true) : [];
      return e.name.endsWith(".md") && isFile(p) ? [p] : [];
    });
  };
  const files = () => {
    const out = new Map();
    const add = (p, titleOnly = false) => { if (!out.has(p) && isFile(p)) out.set(p, titleOnly); };
    ["CLAUDE.md", "README.md"].forEach(p => add(p));
    mds("docs", true).forEach(p => add(p));
    add("journal/decisions.md");
    mds("journal/decisions", false).forEach(p => add(p, true));
    let store = null;
    try { store = decisionsStore(root); } catch { store = null; }
    if (store?.exists && !isAbsolute(store.path)) {   // a store outside the worktree is not its docs
      if (store.kind === "file") add(store.path);
      else mds(store.path.replace(/\/+$/, ""), false).forEach(p => add(p, true));
    }
    const mtime = p => { try { return statSync(join(root, p)).mtimeMs; } catch { return null; } };   // gone since: dropped
    return [...out].map(([path, titleOnly]) => ({ path, titleOnly, mtimeMs: mtimes[path] ?? mtime(path) })).filter(f => f.mtimeMs != null);
  };
  const read = p => { try { return readFileSync(join(root, p), "utf8"); } catch { return null; } };
  return { root, files, read };
}

export const main = captured(([wt, list, ...rest], io, say) => {
  if (!wt || !list || rest.length) { console.error("usage: glossary.mjs <worktree> <feature_list.json> < text"); return 2; }
  if (!existsSync(wt) || !statSync(wt).isDirectory()) { console.error(`glossary: no such worktree: ${wt}`); return 2; }
  const path = resolve(io.cwd ?? process.cwd(), list);
  let text = null;
  try { text = readFileSync(path, "utf8"); } catch { text = null; }
  let parsed = null;
  try { parsed = text ? JSON.parse(text) : null; } catch { parsed = null; }
  const input = readStdin(io);
  const ids = findIds(input, knownIds(parsed));
  say(JSON.stringify(resolveIds(ids, { featureList: text == null ? null : { path, text } }, fsReader(wt)), null, 2));
  return 0;
});

if (isMain(import.meta.url)) runCli(main);
