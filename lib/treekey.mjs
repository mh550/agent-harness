// The identity of the code tree in the current directory: every tracked and untracked (not ignored) file's path and
// content, except the run record (.harness/runs, always) and the path prefixes in HARNESS_CHECK_KEY_IGNORE
// (space-separated; CHECK_KEY_IGNORE, which the driver exports), paths the suite never reads. Independent of commits, so
// a tree a session checked before committing has the same key afterwards. Prints 16 hex chars.
import { execFileSync } from "node:child_process";
import { createHash } from "node:crypto";
import { statSync } from "node:fs";

const git = (args, input) => execFileSync("git", args, { input, maxBuffer: 1 << 28 }).toString();
// literal prefixes: a glob (`*.md`) would leave out files the suite reads, `.` the whole tree (one key for every tree)
const prefix = p => p.replace(/^(\.\/)+/, "").replace(/\/+$/, "");
const ignore = [...new Set([".harness/runs", ...(process.env.HARNESS_CHECK_KEY_IGNORE ?? "").split(/\s+/).map(prefix).filter(p => p && p !== ".")])];
const files = git(["ls-files", "-co", "--exclude-standard", "-z", "--", ".", ...ignore.map(p => `:(exclude,literal)${p}`)])
  .split("\0").filter(Boolean).filter(f => { try { return statSync(f).isFile(); } catch { return false; } }).sort();
const blobs = files.length ? git(["hash-object", "--stdin-paths"], files.join("\n")).trim().split("\n") : [];
const h = createHash("sha1");
files.forEach((f, i) => h.update(`${f}\0${blobs[i]}\n`));
console.log(h.digest("hex").slice(0, 16));
