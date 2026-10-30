// The identity of the code tree in the current directory: every tracked and untracked (not ignored) file's path and
// content, except the run record (.harness/runs, always) and the path prefixes in HARNESS_CHECK_KEY_IGNORE
// (space-separated; CHECK_KEY_IGNORE, which the driver exports), paths the suite never reads. Independent of commits, so
// a tree a session checked before committing has the same key afterwards. Prints 16 hex chars; --pathspec, the key's
// pathspecs instead; --partial, with HARNESS_CHECK_KEY_MAP (CHECK_KEY_MAP: `<path>:<check>[:<check>…]` entries), the
// full key, the key without the mapped paths, then one `<blob> <path>` per mapped path (`-` when absent), map order;
// no blob line when .harness/config.sh is on disk but outside the key (the map could change unseen);
// --names <path>…, the checks the map names for those paths (exit 1 when one is no entry's path).
// Usage: node lib/treekey.mjs [--pathspec | --partial | --names <path>…]
import { execFileSync } from "node:child_process";
import { createHash } from "node:crypto";
import { existsSync, statSync } from "node:fs";
import { resolve } from "node:path";
import { fileURLToPath } from "node:url";

// literal prefixes: a glob (`*.md`) would leave out files the suite reads, `.` the whole tree (one key for every tree);
// an absolute or `..` entry is dropped (git rejects a pathspec outside the repo, and `docs/../lib` would leave out lib)
const prefix = p => p.replace(/^(\.\/)+/, "").replace(/\/+$/, "");
const CONFIG = ".harness/config.sh";   // where CHECK_KEY_MAP is set: never mapped, never outside a reduced key
const ok = p => p && p !== "." && !p.startsWith("/") && !p.split("/").includes("..");
export const ignoreList = env =>
  [...new Set([".harness/runs", ...(env.HARNESS_CHECK_KEY_IGNORE ?? "").split(/\s+/).map(prefix).filter(ok)])];

// CHECK_KEY_MAP's entries, a duplicate path's names merged into its first entry (a name lost is a check not run);
// a dropped entry (one under .harness/ too: the map's own file) is one line in `dropped`, and a map with none kept is as no map
export function parseMap(str, ignore, isDir) {
  const entries = [], dropped = [];
  for (const entry of (str ?? "").split(/\s+/).filter(Boolean)) {
    const [raw, ...rest] = entry.split(":"), path = prefix(raw), names = rest.filter(Boolean);
    const under = ignore.find(p => path === p || path.startsWith(p + "/"));
    const why = !names.length ? "no check name" : !ok(path) ? "not a path in the tree"
      : under ? `under the ignored prefix ${under}` : path.startsWith(".harness/") ? "under .harness/, the map's own"
      : raw.endsWith("/") || isDir(path) ? "a directory" : "";
    if (why) { dropped.push(`treekey: CHECK_KEY_MAP entry ${entry} dropped: ${why}`); continue; }
    const seen = entries.find(e => e.path === path);
    if (seen) seen.names.push(...names.filter(n => !seen.names.includes(n)));
    else entries.push({ path, names: [...new Set(names)] });
  }
  return { entries, dropped };
}

export function treeKey(files, blobs) {
  const h = createHash("sha1");
  files.forEach((f, i) => h.update(`${f}\0${blobs[i]}\n`));
  return h.digest("hex").slice(0, 16);
}

// full: the tree's key; reduced: the key of the files no entry maps; lines: each entry's blob, `-` when absent
export function partialKeys(files, blobs, entries) {
  const mapped = new Set(entries.map(e => e.path)), keep = files.map(f => !mapped.has(f));
  const blob = new Map(files.map((f, i) => [f, blobs[i]]));
  return { full: treeKey(files, blobs), reduced: treeKey(files.filter((_, i) => keep[i]), blobs.filter((_, i) => keep[i])),
    lines: entries.map(e => `${blob.get(e.path) ?? "-"} ${e.path}`) };
}

// the names of the entries whose path is in paths, in map order, each once; null when a path is no entry's
export function mapNames(entries, paths) {
  if (paths.some(p => !entries.some(e => e.path === p))) return null;
  return [...new Set(entries.filter(e => paths.includes(e.path)).flatMap(e => e.names))];
}

function main(args) {
  const ignore = ignoreList(process.env);
  const spec = [".", ...ignore.map(p => `:(exclude,literal)${p}`)];
  // --pathspec: those pathspecs, one per line, for a git diff over what the key covers (ignored_only, lib/record.sh)
  if (args[0] === "--pathspec") { console.log(spec.join("\n")); return 0; }
  const isDir = p => { try { return statSync(p).isDirectory(); } catch { return false; } };
  const map = () => { const m = parseMap(process.env.HARNESS_CHECK_KEY_MAP, ignore, isDir); m.dropped.forEach(l => console.error(l)); return m.entries; };
  if (args[0] === "--names") { const n = mapNames(map(), args.slice(1).map(prefix)); if (!n) return 1; console.log(n.join(" ")); return 0; }
  const git = (a, input) => execFileSync("git", a, { input, maxBuffer: 1 << 28 }).toString();
  const files = git(["ls-files", "-co", "--exclude-standard", "-z", "--", ...spec])
    .split("\0").filter(Boolean).filter(f => { try { return statSync(f).isFile(); } catch { return false; } }).sort();
  const blobs = files.length ? git(["hash-object", "--stdin-paths"], files.join("\n")).trim().split("\n") : [];
  // the bare call never parses the map: no stderr from a bad entry on every $(node treekey.mjs)
  if (args[0] !== "--partial") { console.log(treeKey(files, blobs)); return 0; }
  // the map's file outside the reduced key (ignored, gitignored) could shrink the map under an equal one: no map then
  let entries = map();
  if (entries.length && !files.includes(CONFIG) && existsSync(CONFIG)) {
    console.error(`treekey: CHECK_KEY_MAP not used: ${CONFIG} is outside the key`); entries = [];
  }
  const k = partialKeys(files, blobs, entries);
  console.log([k.full, k.reduced, ...k.lines].join("\n"));
  return 0;
}

if (process.argv[1] && fileURLToPath(import.meta.url) === resolve(process.argv[1])) process.exit(main(process.argv.slice(2)));
