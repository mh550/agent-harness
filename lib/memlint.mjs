// The project's memory, read deterministically (no dependencies). M2: where its decisions live; M3: the Gotchas diff and
// the store's current rules (for the pack); M4: the lint. decisions/2026-10-26-where-things-go,
// decisions/2026-10-26-gotchas-in-place, decisions/2026-10-26-pack-current-rules, decisions/2026-10-26-memlint.
//
//   <worktree>             → one finding per line, `<file>:<line> <check>: <text>`, exit 0 with or without findings (2: no
//                            such worktree). Checks: size (CLAUDE.md over MEMLINT_LINES, default 120), gotchas (its
//                            `## Gotchas` over 15 lines), derivable-count (a stored `<n> tests` in CLAUDE.md or
//                            .harness/project.md), night-scope (`tonight`, `this run`, `this slice`, `as of <date>` there),
//                            decisions (no store, a single-file store without a current-rule-set header, a superseded
//                            entry or file with no `Updated in place` line)
//   store <worktree>       → the decisions store's path (relative to the worktree), or nothing when it has none
//   store-line <worktree>  → the phrase the `## Where things go` block names the store with ({{DECISIONS}})
//   gotchas <before> <after> → `+<added> ~<edited> -<deleted>` of the two CLAUDE.md files' `## Gotchas` lines, or
//                            nothing when they are the same (a missing file has none)
import { readFileSync, readdirSync, existsSync, statSync } from "node:fs";
import { join, resolve } from "node:path";
import { fileURLToPath } from "node:url";

// .harness/config.sh text → the last uncommented DECISIONS= value (quotes and a trailing comment stripped), or null.
// Read, not sourced: the config is bash, but a store path is one plain word.
const CONFIG = ".harness/config.sh", SETTING = /^\s*(?:export\s+)?DECISIONS=("([^"]*)"|'([^']*)'|([^\s#;]*))/;
export function decisionsSetting(text) {
  let v = null;
  for (const line of text.split("\n")) {
    const m = line.match(SETTING);
    if (m) v = m[2] ?? m[3] ?? m[4];
  }
  return v ? v.replace(/\/+$/, "") : null;
}

// <worktree> → { path, kind: "dir" | "file", exists } or null: DECISIONS= from .harness/config.sh, else
// docs/decisions.md if it exists, else none. A configured path that isn't there yet is a file unless it ends in / or
// has no extension (journal/decisions: one file per decision).
export function decisionsStore(worktree) {
  const cfg = join(worktree, CONFIG);
  let path = existsSync(cfg) ? decisionsSetting(readFileSync(cfg, "utf8")) : null;
  if (!path) path = existsSync(join(worktree, "docs/decisions.md")) ? "docs/decisions.md" : null;
  if (!path) return null;
  const abs = resolve(worktree, path), exists = existsSync(abs);
  const kind = exists ? (statSync(abs).isDirectory() ? "dir" : "file") : (/\.[A-Za-z0-9]+$/.test(path) ? "file" : "dir");
  return { path, kind, exists };
}

// store (decisionsStore's value) → the words after "a decision →" in the block
export function storeLine(store) {
  if (!store) return "where the project rules say decisions live";
  return store.kind === "dir" ? `one file per decision in \`${store.path}/\`, never numbered` : `\`${store.path}\``;
}

// CLAUDE.md text (null: no file) → the non-blank lines between `## Gotchas` and the next `# ` or `## ` heading, trimmed
// at the end; an indented line continues the one before (a wrapped bullet is one line)
export const gotchasLines = text => gotchasEntries(text).map(g => g.text);

// the same, as [{ line, text }] with each entry's first line number (1-based), for the lint
export function gotchasEntries(text) {
  if (text == null) return [];
  const out = [];
  let inside = false;
  String(text).split("\n").forEach((raw, i) => {
    const line = raw.replace(/\s+$/, "");
    if (/^##? /.test(line)) { inside = line === "## Gotchas"; return; }
    if (!inside || !line) return;
    if (/^\s/.test(line) && out.length) out[out.length - 1].text += " " + line.trim();
    else out.push({ line: i + 1, text: line });
  });
  return out;
}

// two CLAUDE.md texts → { added, edited, deleted } of their Gotchas lines. A multiset difference, so reordering is no
// change; a line out and a line in pair up as one edit (a replace at 15 lines is what the prompt asks for).
export function gotchasDiff(before, after) {
  const left = new Map();
  for (const l of gotchasLines(before)) left.set(l, (left.get(l) || 0) + 1);
  let fresh = 0;
  for (const l of gotchasLines(after)) {
    if (left.get(l) > 0) left.set(l, left.get(l) - 1);
    else fresh++;
  }
  const gone = [...left.values()].reduce((a, b) => a + b, 0), edited = Math.min(gone, fresh);
  return { added: fresh - edited, edited, deleted: gone - edited };
}

// a decision id: D<n>, but not the first of a range such as `D1–D6`, `D1 — D6` or `D1 to D6` (a group, not a decision)
const DID = "D(\\d+)(?![\\d–—-]| *[–—-] *D\\d| +to +D\\d)";

// a decision line's Markdown reduced to text: emphasis marks gone, whitespace folded
const plain = s => s.replace(/\*+/g, "").replace(/\s+/g, " ").trim();

// store (decisionsStore's value) and its contents → [{ text, ref }], newest first (decisions/2026-10-26-pack-current-rules).
// A dir store: input = [{ name, text }] of its .md files, each its first `# ` line, by name descending (the date
// prefix). A file store: input = its text; a decision line is a heading `## D<n>` (plus its first non-blank line), a
// bullet `- **D<n>` (with its wrapped lines) or a table row `| D<n> |` (a range such as `D1–D6`, `D1 — D6` or `D1 to D6` is a
// group, not a decision), by n descending, a repeated n keeping its last line, except that a heading never replaces a
// bullet or a row (dj's `## D24 on` group heading).
export function currentRules(store, input) {
  if (store.kind === "dir") {
    // dated names newest first, then any undated one (a README.md must not rank as the newest rule)
    const k = n => (/^\d{4}-\d{2}-\d{2}-/.test(n) ? "1" : "0") + n;
    return [...input].sort((a, b) => (k(a.name) < k(b.name) ? 1 : k(a.name) > k(b.name) ? -1 : 0)).flatMap(({ name, text }) => {
      const t = String(text).split("\n").find(l => /^# /.test(l));
      return t ? [{ text: plain(t.slice(2)), ref: `${store.path}/${name}` }] : [];
    });
  }
  const ls = String(input).split(/\r?\n/), byN = new Map(), id = DID;
  ls.forEach((l, i) => {
    let m, text;
    if ((m = l.match(new RegExp(`^#{2,4} +(${id}.*)$`)))) {
      const next = ls.slice(i + 1).find(x => x.trim());
      text = plain(m[1]) + (next && !/^#/.test(next) ? ` — ${plain(next)}` : "");
    } else if ((m = l.match(new RegExp(`^- \\*\\*(${id}.*)$`)))) {   // a bullet with its wrapped (indented) lines
      let j = i + 1, t = m[1];
      while (j < ls.length && /^\s+\S/.test(ls[j]) && t.length < 600) t += " " + ls[j++];
      text = plain(t);
    }
    else if ((m = l.match(new RegExp(`^\\| *(${id}[^|]*?) *\\|(.*)$`)))) text = [plain(m[1]), ...m[3].split("|").map(plain).filter(Boolean)].join(" · ");   // `| D36 *default* |` too
    else return;
    const heading = /^#/.test(l), had = byN.get(Number(m[2]));
    if (heading && had && !had.heading) return;
    byN.set(Number(m[2]), { text, ref: `${store.path}:${i + 1}`, heading });
  });
  return [...byN.entries()].sort((a, b) => b[0] - a[0]).map(([, { text, ref }]) => ({ text, ref }));
}

// <worktree> → its decisions store's current rules ([] when it has none or the store isn't there yet)
export function readRules(worktree) {
  const s = decisionsStore(worktree);
  if (!s?.exists) return [];
  const abs = resolve(worktree, s.path);
  const read = f => { try { return readFileSync(f, "utf8"); } catch { return null; } };   // unreadable: skipped, never a failed pack
  if (s.kind === "file") { const t = read(abs); return t === null ? [] : currentRules(s, t); }
  let names = [];
  try { names = readdirSync(abs).filter(n => n.endsWith(".md")); } catch { return []; }
  return currentRules(s, names.map(name => ({ name, text: read(join(abs, name)) })).filter(x => x.text !== null));
}

const readOrNull = f => (existsSync(f) ? readFileSync(f, "utf8") : null);

// ---- the lint (M4): findings are notes, the driver never stops for one (decisions/2026-10-26-memlint) ----
export const GOTCHAS_MAX = 15;
const MON = "(?:jan(?:uary)?|feb(?:ruary)?|mar(?:ch)?|apr(?:il)?|may|june?|july?|aug(?:ust)?|sep(?:t(?:ember)?)?|oct(?:ober)?|nov(?:ember)?|dec(?:ember)?)\\b";
// night scope belongs in the run's brief; a count the suite can tell belongs nowhere
const NIGHT = [/\btonight\b/i, /\bthis run\b/i, /\bthis slice\b/i,
  new RegExp(`\\bas of (?:\\d{4}-\\d{2}-\\d{2}|\\d{1,2} ${MON}|${MON})`, "i")];
const COUNT = /(?<![\w.,-])~?\d[\d,]*\+? (?:tests|checks|passing|specs)\b/i;
// a supersession marker is passive or tagged, so prose ("when a decision is overturned", "its origin replaced by a
// clone", voice-concierge's "the rows they superseded") isn't one
const SUPERSEDED = /\bsuperseded (?:in part )?by\b|\[superseded\]|\b(?:is|was|been|now) superseded\b|^\W*superseded\b|\boverturned by\b|\breplaced by \**`?(?:D\d+|decisions\/)/i;
const UPDATED = /updated in place/i, HEADER = /current rule set|(?:rewritten|edited|updated) in place/i;

// a memory file's text → [{ file, line, check, text }]: size and gotchas for CLAUDE.md (claude), derivable-count and
// night-scope for any. The `## Where things go` section is the routing rule itself ("tonight's scope → the brief").
export function lintText(file, text, { maxLines = 120, claude = false } = {}) {
  const out = [], ls = String(text).replace(/\n$/, "").split("\n"), f = (line, check, t) => out.push({ file, line, check, text: t });
  if (claude && ls.length > maxLines) f(maxLines + 1, "size", `${ls.length} lines, over ${maxLines} (MEMLINT_LINES)`);
  const g = claude ? gotchasEntries(text) : [];
  if (g.length > GOTCHAS_MAX) f(g[GOTCHAS_MAX].line, "gotchas", `${g.length} lines, over ${GOTCHAS_MAX}`);
  let routing = false;
  ls.forEach((l, i) => {
    if (/^##? /.test(l)) routing = /^## Where things go\s*$/.test(l);
    if (routing) return;
    let m;
    if ((m = l.match(COUNT))) f(i + 1, "derivable-count", `"${m[0]}" (the suite can tell: store no count)`);
    for (const re of NIGHT) if ((m = l.match(re))) { f(i + 1, "night-scope", `"${m[0]}" (night scope goes in the run's brief)`); break; }
  });
  return out;
}

// store (decisionsStore's value), its contents as currentRules takes them (null: not there) and the DECISIONS= line →
// [{ file, line, check: "decisions", text }]. A file store's preamble (before its first decision line or `## ` heading)
// says it is the current rule set; an entry (from a decision line or heading to the next) or a dir store's file that
// carries a supersession marker also has an `Updated in place` line.
export function lintStore(store, input, at = 1) {
  const out = [], f = (file, line, text) => out.push({ file, line, check: "decisions", text });
  if (!store) f(CONFIG, 1, "no store (no DECISIONS= in .harness/config.sh and no docs/decisions.md)");
  else if (input == null) f(CONFIG, at, `store ${store.path} not found`);
  else if (store.kind === "dir") {
    for (const { name, text } of input) {
      const ls = String(text).split("\n"), i = ls.findIndex(l => SUPERSEDED.test(l));
      if (i >= 0 && !UPDATED.test(text)) f(`${store.path}/${name}`, i + 1, 'superseded with no "Updated in place" line');
    }
  } else {
    const ls = String(input).split(/\r?\n/), start = new RegExp(`^(?:## |#{3,4} +${DID}|- \\*\\*${DID}|\\| *${DID})`);
    const starts = ls.flatMap((l, i) => (start.test(l) ? [i] : []));
    if (!HEADER.test(ls.slice(0, starts[0] ?? ls.length).join("\n")))
      f(store.path, 1, "no current-rule-set header (say the file is the current rule set, rewritten in place)");
    starts.forEach((s, k) => {
      const body = ls.slice(s, starts[k + 1] ?? ls.length), i = body.findIndex(l => SUPERSEDED.test(l));
      if (i < 0 || body.some(l => UPDATED.test(l))) return;
      const name = ls[s].match(/^(?:#+ +|- \*\*|\| *)(D\d+)/)?.[1] ?? ls[s].replace(/^#+\s*/, "").slice(0, 40);
      f(store.path, s + i + 1, `${name} superseded with no "Updated in place" line`);
    });
  }
  return out;
}

// <worktree> → its findings: CLAUDE.md, .harness/project.md, then the decisions store. A missing file has none; an
// unreadable one throws (the caller notes `memlint: failed`).
export function lint(worktree, maxLines = 120) {
  const out = [];
  for (const [file, claude] of [["CLAUDE.md", true], [".harness/project.md", false]]) {
    const t = readOrNull(join(worktree, file));
    if (t != null) out.push(...lintText(file, t, { maxLines, claude }));
  }
  const s = decisionsStore(worktree), abs = s && resolve(worktree, s.path);
  let input = null, at = 1;
  if (s?.exists && s.kind === "file") input = readFileSync(abs, "utf8");
  else if (s?.exists) input = readdirSync(abs, { withFileTypes: true }).filter(e => e.isFile() && e.name.endsWith(".md")).map(e => e.name).sort().map(name => ({ name, text: readFileSync(join(abs, name), "utf8") }));
  else if (s) (readOrNull(join(worktree, CONFIG)) ?? "").split("\n").forEach((l, i) => { if (SETTING.test(l)) at = i + 1; });
  return out.concat(lintStore(s, input, at));
}

function main([cmd, wt, ...rest]) {
  if (cmd && wt === undefined && !["store", "store-line", "gotchas"].includes(cmd)) {
    if (!existsSync(cmd) || !statSync(cmd).isDirectory()) { console.error(`memlint: no such worktree: ${cmd}`); return 2; }
    const n = Number(process.env.MEMLINT_LINES);
    for (const x of lint(cmd, Number.isInteger(n) && n > 0 ? n : 120)) console.log(`${x.file}:${x.line} ${x.check}: ${x.text}`);
    return 0;
  }
  if (cmd === "gotchas" && wt && rest.length === 1) {
    const d = gotchasDiff(readOrNull(wt), readOrNull(rest[0]));
    if (d.added || d.edited || d.deleted) console.log(`+${d.added} ~${d.edited} -${d.deleted}`);
    return 0;
  }
  if (!["store", "store-line"].includes(cmd) || !wt || rest.length) {
    console.error("usage: memlint.mjs <worktree> | store <worktree> | store-line <worktree> | gotchas <before> <after>");
    return 2;
  }
  const s = decisionsStore(wt);
  if (cmd === "store-line") console.log(storeLine(s));
  else if (s) console.log(s.path);
  return 0;
}

if (process.argv[1] && fileURLToPath(import.meta.url) === resolve(process.argv[1])) process.exit(main(process.argv.slice(2)));
