// The tracked paths a spec or brief names, and where two runs' meet (decisions/2026-10-27-same-project-starts). Pure.
//
//   overlap.mjs named <tracked file> < text     the tracked paths the text names, one per line (a directory as dir/)
//   overlap.mjs overlap <file a> <file b>       the sorted intersection of two such lists
import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { fileURLToPath } from "node:url";

const PATHY = /[A-Za-z0-9_.-]+(?:\/[A-Za-z0-9_.*<>-]+)+\/?/g;   // path-shaped: at least one /
const GLOB = /[*<>]/;
const RECORD = ".harness/runs/";   // the runs' own records: every run writes there

const clean = (t) => t.trim().replace(/:\d+$/, "").replace(/[.,:;)]+$/, "").replace(/^(\.\/)+/, "");
const TAG = /<\/?(?:a|b|br|code|em|i|kbd|li|p|pre|span|strong|sub|sup|td|th|tt|u)\b[^>]*>/gi;   // HTML, not a <slug> glob

// Every backticked span (one line) and every path-shaped word, inside backticks or not.
export function tokens(text) {
  text = text.replace(TAG, " ");
  const out = [];
  for (const m of text.matchAll(/`([^`\n]+)`/g)) out.push(clean(m[1]));
  for (const m of text.matchAll(PATHY)) out.push(clean(m[0]));
  return out.filter(Boolean);
}

// text, tracked paths → the sorted unique entries the text names: a tracked path it equals; for a word ending in / or
// holding a glob, the directory before its first glob segment as dir/, when that directory is tracked and has two or
// more segments (tests/checks/ yes; tests/ and lib/ no: every run touches those); a word without / names a top-level
// tracked file only. Never anything under .harness/runs/.
export function named(text, tracked) {
  const files = new Set(tracked);
  const found = new Set();
  for (const t of tokens(text)) {
    if (files.has(t)) { found.add(t); continue; }
    const bare = t.replace(/\*+$/, "");   // Markdown emphasis after a file (**lib/x.sh**), else a glob (dir/6*)
    if (files.has(bare)) { found.add(bare); continue; }
    if (!t.includes("/")) continue;
    const segs = t.replace(/\/$/, "").split("/");
    const g = segs.findIndex((s) => GLOB.test(s));
    if (!t.endsWith("/") && g < 0) continue;
    const dir = segs.slice(0, g < 0 ? segs.length : g);
    if (dir.length < 2) continue;
    const d = dir.join("/") + "/";
    if (tracked.some((p) => p.startsWith(d))) found.add(d);
  }
  return [...found].filter((p) => !p.startsWith(RECORD)).sort();
}

// two lists → the sorted intersection: a file meets the same file; a dir/ meets a file under it (the file is reported)
// or a dir/ at or under it (the deeper one)
export function overlap(a, b) {
  const out = new Set();
  for (const x of a) for (const y of b) {
    if (x === y || (y.endsWith("/") && x.startsWith(y))) out.add(x);
    else if (x.endsWith("/") && y.startsWith(x)) out.add(y);
  }
  return [...out].sort();
}

const lines = (f) => readFileSync(f, "utf8").split("\n").filter(Boolean);

function main(argv) {
  const [cmd, ...rest] = argv;
  if (cmd === "named" && rest.length === 1) {
    const out = named(readFileSync(0, "utf8"), lines(rest[0]));
    if (out.length) process.stdout.write(out.join("\n") + "\n");
    return 0;
  }
  if (cmd === "overlap" && rest.length === 2) {
    const out = overlap(lines(rest[0]), lines(rest[1]));
    if (out.length) process.stdout.write(out.join("\n") + "\n");
    return 0;
  }
  process.stderr.write("usage: overlap.mjs named <tracked file> < text | overlap <file a> <file b>\n");
  return 2;
}

if (process.argv[1] && fileURLToPath(import.meta.url) === resolve(process.argv[1])) process.exit(main(process.argv.slice(2)));
