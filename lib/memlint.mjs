// The project's memory, read deterministically (no dependencies). M2: where its decisions live; M3: the Gotchas diff;
// M4 adds the lint. decisions/2026-10-26-where-things-go, decisions/2026-10-26-gotchas-in-place.
//
//   store <worktree>       → the decisions store's path (relative to the worktree), or nothing when it has none
//   store-line <worktree>  → the phrase the `## Where things go` block names the store with ({{DECISIONS}})
//   gotchas <before> <after> → `+<added> ~<edited> -<deleted>` of the two CLAUDE.md files' `## Gotchas` lines, or
//                            nothing when they are the same (a missing file has none)
import { readFileSync, existsSync, statSync } from "node:fs";
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

// CLAUDE.md text (null: no file) → the non-blank lines between `## Gotchas` and the next `## ` heading, trimmed at the end
export function gotchasLines(text) {
  if (text == null) return [];
  const out = [];
  let inside = false;
  for (const raw of String(text).split("\n")) {
    const line = raw.replace(/\s+$/, "");
    if (/^## /.test(line)) { inside = line === "## Gotchas"; continue; }
    if (inside && line) out.push(line);
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
