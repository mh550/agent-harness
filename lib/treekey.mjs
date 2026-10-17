// The identity of the code tree in the current directory: every tracked and untracked (not ignored) file's path and
// content, except the run record (.harness/runs). Independent of commits, so a tree a session checked before
// committing has the same key afterwards. Prints 16 hex chars.
import { execFileSync } from "node:child_process";
import { createHash } from "node:crypto";
import { statSync } from "node:fs";

const git = (args, input) => execFileSync("git", args, { input, maxBuffer: 1 << 28 }).toString();
const files = git(["ls-files", "-co", "--exclude-standard", "-z", "--", ".", ":!.harness/runs"])
  .split("\0").filter(Boolean).filter(f => { try { return statSync(f).isFile(); } catch { return false; } }).sort();
const blobs = files.length ? git(["hash-object", "--stdin-paths"], files.join("\n")).trim().split("\n") : [];
const h = createHash("sha1");
files.forEach((f, i) => h.update(`${f}\0${blobs[i]}\n`));
console.log(h.digest("hex").slice(0, 16));
