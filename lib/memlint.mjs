// The project's memory, read deterministically (no dependencies). M2: where its decisions live; M3: the Gotchas diff and
// the store's current rules (for the pack); M4 adds the lint. decisions/2026-10-26-where-things-go,
// decisions/2026-10-26-gotchas-in-place, decisions/2026-10-26-pack-current-rules.
//
//   store <worktree>       → the decisions store's path (relative to the worktree), or nothing when it has none
//   store-line <worktree>  → the phrase the `## Where things go` block names the store with ({{DECISIONS}})
//   gotchas <before> <after> → `+<added> ~<edited> -<deleted>` of the two CLAUDE.md files' `## Gotchas` lines, or
//                            nothing when they are the same (a missing file has none)
import { readFileSync, readdirSync, existsSync, statSync } from "node:fs";
import { join, resolve } from "node:path";
import { fileURLToPath } from "node:url";

// .harness/config.sh text → the last uncommented DECISIONS= value (quotes and a trailing comment stripped), or null.
// Read, not sourced: the config is bash, but a store path is one plain word.
export function decisionsSetting(text) {
  let v = null;
  for (const line of text.split("\n")) {
    const m = line.match(/^\s*(?:export\s+)?DECISIONS=("([^"]*)"|'([^']*)'|([^\s#;]*))/);
    if (m) v = m[2] ?? m[3] ?? m[4];
  }
  return v ? v.replace(/\/+$/, "") : null;
}

// <worktree> → { path, kind: "dir" | "file", exists } or null: DECISIONS= from .harness/config.sh, else
// docs/decisions.md if it exists, else none. A configured path that isn't there yet is a file unless it ends in / or
// has no extension (journal/decisions: one file per decision).
export function decisionsStore(worktree) {
  const cfg = join(worktree, ".harness/config.sh");
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
export function gotchasLines(text) {
  if (text == null) return [];
  const out = [];
  let inside = false;
  for (const raw of String(text).split("\n")) {
    const line = raw.replace(/\s+$/, "");
    if (/^##? /.test(line)) { inside = line === "## Gotchas"; continue; }
    if (!inside || !line) continue;
    if (/^\s/.test(line) && out.length) out[out.length - 1] += " " + line.trim();
    else out.push(line);
  }
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
  const ls = String(input).split(/\r?\n/), byN = new Map(), id = "D(\\d+)(?![\\d–—-]| *[–—-] *D\\d| +to +D\\d)";
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

function main([cmd, wt, ...rest]) {
  if (cmd === "gotchas" && wt && rest.length === 1) {
    const d = gotchasDiff(readOrNull(wt), readOrNull(rest[0]));
    if (d.added || d.edited || d.deleted) console.log(`+${d.added} ~${d.edited} -${d.deleted}`);
    return 0;
  }
  if (!["store", "store-line"].includes(cmd) || !wt || rest.length) {
    console.error("usage: memlint.mjs store <worktree> | store-line <worktree> | gotchas <before> <after>");
    return 2;
  }
  const s = decisionsStore(wt);
  if (cmd === "store-line") console.log(storeLine(s));
  else if (s) console.log(s.path);
  return 0;
}

if (process.argv[1] && fileURLToPath(import.meta.url) === resolve(process.argv[1])) process.exit(main(process.argv.slice(2)));
