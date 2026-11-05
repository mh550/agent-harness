// The identity of the code tree in the current directory (io.cwd): every tracked and untracked (not ignored) file's path and
// content, except the run record (.harness/runs, always) and the path prefixes in HARNESS_CHECK_KEY_IGNORE
// (space-separated; CHECK_KEY_IGNORE, which the driver exports), paths the suite never reads. Independent of commits, so
// a tree a session checked before committing has the same key afterwards. Prints 16 hex chars; --pathspec, the key's
// pathspecs instead; --partial, with HARNESS_CHECK_KEY_MAP (CHECK_KEY_MAP: `<path>:<check>[:<check>…]` entries), the
// full key, the key without the mapped paths, then one `<blob> <path>` per mapped path (`-` when absent), map order;
// no blob line when .harness/config.sh is on disk but outside the key (the map could change unseen);
// --names <path>…, the checks the map names for those paths (exit 1 when one is no entry's path); --partial --names,
// --partial's lines and then one `: <path> <name>…` line per entry, map order (check.sh's one start for both).
// A tracked blob comes from the index, as `git status` trusts it; only what the index can't vouch for is hashed (parseListing).
// Usage: node lib/treekey.mjs [--pathspec | --partial [--names] | --names <path>…]
import { execFileSync } from "node:child_process";
import { createHash } from "node:crypto";
import { existsSync, statSync } from "node:fs";
import { join } from "node:path";
import { captured, isMain, runCli } from "./cli.mjs";

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

// `git ls-files -z -v --stage -c -m -o`'s rows: one per index entry and untracked file, as `-co` lists them. blob is the
// index's for a regular file at stage 0 whose stat or content is the index's, and null where only a hash-object can say:
// what's edited or gone (a second `C` line), an untracked file, a link (hash-object follows it; the index holds the target's
// name), a gitlink, a conflict's stages, an assume-unchanged (`h`) or skip-worktree (`S`) entry git doesn't look at, and a
// path that didn't survive the decode (the stat drops it, as it always has)
export function parseListing(out) {
  const rows = [], stale = new Set();
  for (const line of out.split("\0").filter(Boolean)) {
    if (line.startsWith("? ")) { rows.push({ path: line.slice(2), blob: null }); continue; }
    const tab = line.indexOf("\t"), [tag, mode, blob, stage] = line.slice(0, tab).split(" "), path = line.slice(tab + 1);
    if (tag === "C" || tag === "c") stale.add(path);
    else rows.push({ path, blob: tag === "H" && stage === "0" && mode.startsWith("100") && !path.includes("\ufffd") ? blob : null });
  }
  return rows.map(r => stale.has(r.path) ? { ...r, blob: null } : r);
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

export const main = captured((args, io, say) => {
  const env = io.env ?? process.env, ignore = ignoreList(env), at = p => join(io.cwd, p);
  const spec = [".", ...ignore.map(p => `:(exclude,literal)${p}`)];
  // --pathspec: those pathspecs, one per line, for a git diff over what the key covers (ignored_only, lib/record.sh)
  if (args[0] === "--pathspec") { say(spec.join("\n")); return 0; }
  const isDir = p => { try { return statSync(at(p)).isDirectory(); } catch { return false; } };
  const map = () => { const m = parseMap(env.HARNESS_CHECK_KEY_MAP, ignore, isDir); m.dropped.forEach(l => console.error(l)); return m.entries; };
  if (args[0] === "--names") { const n = mapNames(map(), args.slice(1).map(prefix)); if (!n) return 1; say(n.join(" ")); return 0; }
  const git = (a, input) => execFileSync("git", a, { input, cwd: io.cwd, env, maxBuffer: 1 << 28 }).toString();
  const isFile = p => { try { return statSync(at(p)).isFile(); } catch { return false; } };
  // below the top `hash-object --stdin-paths` reads from the top and ls-files lists from here: hash them all, and fail as ever
  const top = existsSync(at(".git"));
  const rows = parseListing(git(["ls-files", "-z", "-v", "--stage", "-c", "-m", "-o", "--exclude-standard", "--", ...spec]))
    .map(r => top ? r : { ...r, blob: null }).filter(r => r.blob || isFile(r.path)).sort((a, b) => a.path < b.path ? -1 : a.path > b.path ? 1 : 0);
  const hash = rows.filter(r => !r.blob);
  if (hash.length) git(["hash-object", "--stdin-paths"], hash.map(r => r.path).join("\n")).trim().split("\n").forEach((b, i) => { hash[i].blob = b; });
  const files = rows.map(r => r.path), blobs = rows.map(r => r.blob);
  // the bare call never parses the map: no stderr from a bad entry on every $(node treekey.mjs)
  if (args[0] !== "--partial") { say(treeKey(files, blobs)); return 0; }
  // the map's file outside the reduced key (ignored, gitignored) could shrink the map under an equal one: no map then
  let entries = map();
  if (entries.length && !files.includes(CONFIG) && existsSync(at(CONFIG))) {
    console.error(`treekey: CHECK_KEY_MAP not used: ${CONFIG} is outside the key`); entries = [];
  }
  const k = partialKeys(files, blobs, entries);
  say([k.full, k.reduced, ...k.lines, ...(args[1] === "--names" ? entries.map(e => `: ${e.path} ${e.names.join(" ")}`) : [])].join("\n"));
  return 0;
});

if (isMain(import.meta.url)) runCli(main);
