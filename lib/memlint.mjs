// The project's memory, read deterministically (no dependencies). M2: where its decisions live; M4 adds the lint.
// decisions/2026-10-26-where-things-go.
//
//   store <worktree>       → the decisions store's path (relative to the worktree), or nothing when it has none
//   store-line <worktree>  → the phrase the `## Where things go` block names the store with ({{DECISIONS}})
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

function main([cmd, wt, ...rest]) {
  if (!["store", "store-line"].includes(cmd) || !wt || rest.length) {
    console.error("usage: memlint.mjs store <worktree> | store-line <worktree>");
    return 2;
  }
  const s = decisionsStore(wt);
  if (cmd === "store-line") console.log(storeLine(s));
  else if (s) console.log(s.path);
  return 0;
}

if (process.argv[1] && fileURLToPath(import.meta.url) === resolve(process.argv[1])) process.exit(main(process.argv.slice(2)));
