// lib/treekey.mjs: the tree's key, the partial map's keys and names, on a fixed file list and on throwaway repos.   node --test tests/unit/treekey.test.mjs
import { test } from "node:test";
import assert from "node:assert/strict";
import { execFileSync } from "node:child_process";
import { createHash } from "node:crypto";
import { chmodSync, mkdirSync, mkdtempSync, readFileSync, rmSync, statSync, symlinkSync, utimesSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { dirname, join } from "node:path";
import { sameAsCli, mainOf } from "./cli-same.mjs";
import { ignoreList, parseMap, treeKey, partialKeys, mapNames } from "../../lib/treekey.mjs";

// the CLI on a git tree (--partial, --names, a dropped entry's stderr) stays in partial-key; the map's first path is any file
// (partial-key's eval named the project rules file, which no unit test names: the key map can't see tests/unit)
test("treekey.mjs exports ignoreList, parseMap, treeKey, partialKeys and mapNames, pure on a fixed file list and blobs", () => {
  const f = ["a", "b", "c"], b = ["1".repeat(40), "2".repeat(40), "3".repeat(40)];
  const k0 = partialKeys(f, b, []);
  assert.equal(k0.full, treeKey(f, b));
  assert.equal(k0.reduced, k0.full);
  assert.deepEqual(k0.lines, []);
  const kb = partialKeys(f, b, [{ path: "b", names: ["x"] }]);
  assert.equal(kb.full, k0.full);
  assert.equal(kb.reduced, treeKey(["a", "c"], [b[0], b[2]]));
  assert.equal(kb.lines.join("|"), `${b[1]} b`);
  assert.equal(partialKeys(f, b, [{ path: "z", names: ["x"] }]).lines.join("|"), "- z");
  const ig = ignoreList({ HARNESS_CHECK_KEY_IGNORE: "./docs/plans/ /abs" });
  assert.equal(ig.join(" "), ".harness/runs docs/plans");
  const pm = parseMap("RULES.md:a::b d:x docs/plans/q.md:y R.md R.md:c ./RULES.md:e:a", ig, p => p === "d");
  assert.equal(pm.dropped.length, 3);
  assert.equal(pm.entries.map(e => `${e.path}=${e.names.join(",")}`).join(" "), "RULES.md=a,b,e R.md=c");
  assert.equal(mapNames(pm.entries, ["R.md", "RULES.md"]).join(" "), "a b e c");
  assert.equal(mapNames(pm.entries, ["nope"]), null);
});

// ---- main(argv, io): git and every path in io.cwd, never the process's (decisions/2026-11-03-resident-helper) ----
const inRepo = async fn => {
  const d = mkdtempSync(join(tmpdir(), "tk-"));
  try {
    const git = (...a) => execFileSync("git", ["-c", "user.name=t", "-c", "user.email=t@example.com", ...a], { cwd: d });
    git("init", "-q");
    mkdirSync(join(d, "sub")); mkdirSync(join(d, ".harness"));
    writeFileSync(join(d, "a.txt"), "a\n"); writeFileSync(join(d, "sub", "b.txt"), "b\n"); writeFileSync(join(d, ".gitignore"), "ign\n");
    git("add", "."); git("commit", "-qm", "x");
    writeFileSync(join(d, "untracked.txt"), "u\n"); writeFileSync(join(d, "ign"), "i\n");
    return await fn(d);
  } finally { rmSync(d, { recursive: true, force: true }); }
};

test("treekey.mjs: main runs git in io.cwd: the key, --partial --names and --pathspec are the bytes the CLI prints inside that repo, from another cwd", () => inRepo(async cwd => {
  const key = (await sameAsCli("treekey.mjs", [], { cwd })).out;
  assert.match(key, /^[0-9a-f]{16}\n$/);
  assert.notEqual((await mainOf("treekey.mjs", [], { cwd: process.cwd() })).out, key, "this process's cwd is another tree");
  await sameAsCli("treekey.mjs", ["--partial", "--names"], { cwd });
  await sameAsCli("treekey.mjs", ["--pathspec"], { cwd });
  // the map's paths too: a directory is dropped by a stat in io.cwd; a blob line per entry
  const env = { HARNESS_CHECK_KEY_MAP: "a.txt:one sub:two sub/b.txt:three" };
  const out = (await sameAsCli("treekey.mjs", ["--partial", "--names"], { cwd, env })).out;
  assert.match(out, /: a\.txt one\n/); assert.doesNotMatch(out, /: sub two/);
  await sameAsCli("treekey.mjs", ["--names", "a.txt"], { cwd, env });
  // the map's file on disk but outside the key: no map, by an existsSync in io.cwd
  writeFileSync(join(cwd, ".harness", "config.sh"), "x\n"); writeFileSync(join(cwd, ".gitignore"), "ign\n.harness/config.sh\n");
  assert.doesNotMatch((await sameAsCli("treekey.mjs", ["--partial", "--names"], { cwd, env })).out, /: a\.txt/);
}));

test("treekey.mjs: main reads the environment from io.env at call time: two --pathspec answers in one process", async () => {
  const { main } = await import("../../lib/treekey.mjs");
  assert.equal(main(["--pathspec"], { env: {} }).out, ".\n:(exclude,literal).harness/runs\n");
  assert.equal(main(["--pathspec"], { env: { HARNESS_CHECK_KEY_IGNORE: "docs" } }).out, ".\n:(exclude,literal).harness/runs\n:(exclude,literal)docs\n");
});

test("treekey.mjs: main's git gets io.env (git config set on the call moves what ls-files leaves out)", () => inRepo(async cwd => {
  const { main } = await import("../../lib/treekey.mjs");
  writeFileSync(join(cwd, "ign2"), "untracked.txt\n");
  const plain = main([], { cwd, env: process.env }).out;
  assert.notEqual(main([], { cwd, env: { ...process.env, GIT_CONFIG_COUNT: "1", GIT_CONFIG_KEY_0: "core.excludesFile", GIT_CONFIG_VALUE_0: join(cwd, "ign2") } }).out, plain);
}));

// ---- where the blobs come from: the index for a clean regular file, hash-object for the rest (decisions/2026-11-03-resident-helper) ----
// a real `git ls-files -z -v --stage -c -m -o --exclude-standard` (git 2.43): an untracked file, a deleted and an edited one, a clean symlink
test("treekey.mjs parseListing: a clean regular file keeps its index blob; a stale, unmerged, symlink, gitlink, assume-unchanged, skip-worktree or untracked row has none; one row per index entry", async () => {
  const { parseListing } = await import("../../lib/treekey.mjs");
  const [A, B, C] = ["78981922613b2afb6025042ff6bd878ac1994e85", "61780798228d17af2d34fce4cfbdf35556832472", "2e65efe2a145dda7ee51d1741299f848e5bf752e"];
  const rows = parseListing([`? d`, `? ? odd`, `H 100644 ${A} 0\tclean`, `H 100755 ${A} 0\tx y`, `H 100644 ${A} 0\tgone`, `C 100644 ${A} 0\tgone`,
    `H 100644 ${B} 0\tedited`, `C 100644 ${B} 0\tedited`, `H 120000 ${C} 0\tlink`, `H 160000 ${C} 0\tsub`, `M 100644 ${A} 1\tboth`, `M 100644 ${B} 2\tboth`, `C 100644 ${B} 2\tboth`,
    `h 100644 ${A} 0\tvalid`, `c 100644 ${A} 0\tvalid`, `h 100644 ${B} 0\tvalid2`, `S 100644 ${A} 0\tsparse`, ``].join("\0"));
  assert.equal(rows.map(r => `${r.path}=${r.blob ?? "-"}`).join("|"),
    `d=-|? odd=-|clean=${A}|x y=${A}|gone=-|edited=-|link=-|sub=-|both=-|both=-|valid=-|valid2=-|sparse=-`);
  assert.equal(parseListing("").length, 0);
  assert.equal(parseListing(`H 100644 ${A} 0\tb�d\0`)[0].blob, null, "a path that didn't survive the decode is the stat's to drop");
});

// the key's definition, independent of lib/treekey.mjs: every listed path outside the prefixes that is a file, sorted, one git hash-object each
const defined = (cwd, ignore = [".harness/runs"], mapped = []) => {
  const sh = (...a) => execFileSync("git", a, { cwd }).toString();
  const files = sh("ls-files", "-co", "--exclude-standard", "-z").split("\0").filter(Boolean)
    .filter(f => !ignore.some(p => f === p || f.startsWith(p + "/")))
    .filter(f => { try { return statSync(join(cwd, f)).isFile(); } catch { return false; } }).sort();
  const blob = new Map(files.map(f => [f, sh("hash-object", "--", f).trim()]));
  const key = list => createHash("sha1").update(list.map(f => `${f}\0${blob.get(f)}\n`).join("")).digest("hex").slice(0, 16);
  return { full: key(files), reduced: key(files.filter(f => !mapped.includes(f))), lines: mapped.map(f => `${blob.get(f) ?? "-"} ${f}`) };
};
// a session's own HARNESS_CHECK_KEY_IGNORE is in process.env: these answers are for the repo's list alone
const plain = (env = {}) => { const e = { ...process.env, ...env }; for (const k of ["IGNORE", "MAP"]) if (!(`HARNESS_CHECK_KEY_${k}` in env)) delete e[`HARNESS_CHECK_KEY_${k}`]; return e; };
const gitIn = cwd => (...a) => execFileSync("git", ["-c", "user.name=t", "-c", "user.email=t@example.com", "-c", "protocol.file.allow=always", ...a], { cwd, stdio: ["ignore", "pipe", "ignore"] }).toString();
const aRepo = async fn => {
  const d = mkdtempSync(join(tmpdir(), "tk-"));
  try { gitIn(d)("init", "-q"); return await fn(d, gitIn(d), (p, s) => { mkdirSync(dirname(join(d, p)), { recursive: true }); writeFileSync(join(d, p), s); }); }
  finally { rmSync(d, { recursive: true, force: true }); }
};

test("treekey.mjs: the key equals its definition after each change to a tree: edits staged and not, deletions, untracked and ignored files, symlinks, a mode, a touch, the run record", () => aRepo(async (cwd, git, put) => {
  const { main } = await import("../../lib/treekey.mjs");
  const at = p => join(cwd, p);
  const names = ["clean", "unstaged", "staged", "both", "deleted", "mode", "touched", "sameSize", "valid", "validGone", "gone2dir", "itaLater", "sub/deep", "é-utf8", "Z-upper"];
  names.forEach(n => put(n, `${n}\n`));
  put(".gitignore", "ignored\n"); put(".harness/runs/r/entry", "r\n"); put(".harness/config.sh", "x=1\n"); put("docs/plans/p.md", "p\n");
  symlinkSync("clean", at("link")); symlinkSync("sub", at("linkdir")); symlinkSync("nowhere", at("dangling"));
  git("add", "-A"); git("commit", "-qm", "x");
  const same = (why, env = {}, ignore) => assert.equal(main([], { cwd, env: plain(env) }).out, defined(cwd, ignore).full + "\n", why);
  same("all clean, the symlinks included (hash-object follows a link to a file; a link to a directory or nowhere is no file)");
  const steps = [
    ["an unstaged edit", () => put("unstaged", "two\n")],
    ["a staged edit", () => { put("staged", "two\n"); git("add", "staged"); }],
    ["a staged edit edited again", () => { put("both", "two\n"); git("add", "both"); put("both", "three\n"); }],
    ["an untracked file", () => put("untracked", "u\n")],
    ["an ignored file", () => put("ignored", "i\n")],
    ["a tracked file deleted from disk", () => rmSync(at("deleted"))],
    ["a tracked symlink retargeted", () => { rmSync(at("link")); symlinkSync("unstaged", at("link")); }],
    ["a file whose only change is its mode", () => chmodSync(at("mode"), 0o755)],
    ["a file touched with unchanged content", () => utimesSync(at("touched"), new Date(), new Date(Date.now() + 5000))],
    ["a same-size edit with its mtime put back", () => { const { atime, mtime } = statSync(at("sameSize")); writeFileSync(at("sameSize"), "SAMESIZE\n"); utimesSync(at("sameSize"), atime, mtime); }],
    ["an edit in the second of its add, the same size", () => { put("racy", "r1\n"); git("add", "racy"); git("commit", "-qm", "r"); put("racy", "r2\n"); }],
    ["a file under .harness/runs", () => put(".harness/runs/r/entry", "r2\n")],
    ["an assume-unchanged file edited", () => { git("update-index", "--assume-unchanged", "valid"); put("valid", "edited\n"); }],
    ["an assume-unchanged file deleted", () => { git("update-index", "--assume-unchanged", "validGone"); rmSync(at("validGone")); }],
    ["a tracked file replaced by a directory", () => { rmSync(at("gone2dir")); put("gone2dir/inner", "in\n"); }],
    ["an intent-to-add", () => { put("ita", "later\n"); git("add", "-N", "ita"); }],
    ["a removal from the index that stays on disk", () => git("rm", "-q", "--cached", "itaLater")],
    ["a nested repository", () => { put("nested/f", "n\n"); const n = gitIn(at("nested")); n("init", "-q"); n("add", "-A"); n("commit", "-qm", "n"); }],
    ["a name that isn't UTF-8", () => writeFileSync(Buffer.concat([Buffer.from(cwd + "/bad-"), Buffer.from([0xff])]), "b\n")],
    ["a skip-worktree file edited", () => { git("update-index", "--skip-worktree", "Z-upper"); put("Z-upper", "edited\n"); }],
    ["all of it committed", () => { git("add", "-A"); git("commit", "-qm", "y"); }],
  ];
  for (const [why, change] of steps) { change(); same(why); }
  // the bytes of what's on disk stayed, so a commit leaves the key where it was: "independent of commits"
  const before = main([], { cwd, env: plain() }).out; put("c", "c\n"); const dirty = main([], { cwd, env: plain() }).out;
  git("add", "c"); git("commit", "-qm", "z"); assert.equal(main([], { cwd, env: plain() }).out, dirty); assert.notEqual(dirty, before);
  // an ignore list
  same("HARNESS_CHECK_KEY_IGNORE", { HARNESS_CHECK_KEY_IGNORE: "docs/plans" }, [".harness/runs", "docs/plans"]);
}));

test("treekey.mjs: a name with a quote or a newline: the definition's key from the index, and edited never a stale key: its own, or the throw check.sh reads as a full run", () => aRepo(async (cwd, git, put) => {
  const { main } = await import("../../lib/treekey.mjs");
  const key = () => main([], { cwd, env: plain() }).out;
  put("plain", "p\n"); put('qu"ote', "q\n"); put("new\nline", "n\n"); git("add", "-A"); git("commit", "-qm", "x");
  const clean = key();
  assert.equal(clean, defined(cwd).full + "\n", "clean: the index's blobs");
  put('qu"ote', "Q\n"); const quote = key();
  assert.notEqual(quote, clean, "a quote's edit moves the key"); assert.equal(quote, defined(cwd).full + "\n");
  put("new\nline", "N\n");
  let edited = null; try { edited = key(); } catch { /* no key: the full run, no marker */ }
  assert.ok(edited === null || edited === defined(cwd).full + "\n", `a newline's edit is no stale key: ${edited}`);
}));

test("treekey.mjs: --partial's full key, reduced key and blob lines equal the definition's, a mapped file clean, edited, absent and deleted", () => aRepo(async (cwd, git, put) => {
  const { main } = await import("../../lib/treekey.mjs");
  ["clean", "edited", "deleted", "other", "sub/s"].forEach(n => put(n, `${n}\n`)); put(".harness/config.sh", "x=1\n");
  git("add", "-A"); git("commit", "-qm", "x");
  put("edited", "two\n"); rmSync(join(cwd, "deleted")); put("sub/t", "t\n");
  const mapped = ["clean", "edited", "deleted", "absent"], env = plain({ HARNESS_CHECK_KEY_MAP: mapped.map(m => `${m}:c`).join(" ") });
  const d = defined(cwd, undefined, mapped);
  assert.equal(main(["--partial"], { cwd, env }).out, [d.full, d.reduced, ...d.lines].join("\n") + "\n");
}));

// `hash-object --stdin-paths` reads from the top while ls-files lists from here, so below the top there was never a key: check.sh's
// "treekey failed: the full run, no marker". An index blob must not turn that into a key of this subdirectory's files alone
test("treekey.mjs: below the repo's top a clean tree still has no key (the throw check.sh reads as a full run, no marker), as a dirty one", () => aRepo(async (cwd, git, put) => {
  const { main } = await import("../../lib/treekey.mjs");
  put("sub/s", "s\n"); put("r", "r\n"); git("add", "-A"); git("commit", "-qm", "x");
  const inSub = { cwd: join(cwd, "sub"), env: plain() }, quiet = () => assert.throws(() => main([], inSub), /could not open 's'/);
  quiet(); put("sub/s", "two\n"); quiet();
}));

test("treekey.mjs: an unmerged path keeps its one row per stage and the worktree's blob, a gitlink is no file, as the definition has them", () => aRepo(async (cwd, git, put) => {
  const { main } = await import("../../lib/treekey.mjs");
  const same = why => assert.equal(main([], { cwd, env: plain() }).out, defined(cwd).full + "\n", why);
  put("both", "base\n"); put("other", "o\n"); git("add", "-A"); git("commit", "-qm", "base");
  const trunk = git("symbolic-ref", "--short", "HEAD").trim();
  git("checkout", "-qb", "side"); put("both", "side\n"); git("commit", "-qam", "side");
  git("checkout", "-q", trunk); put("both", "main\n"); git("commit", "-qam", "main");
  assert.throws(() => git("merge", "side"));
  assert.equal(git("ls-files", "-c", "both").trim().split("\n").length, 3, "the conflict is real");
  same("a merge conflict");
  git("merge", "--abort");
  git("update-index", "--add", "--cacheinfo", `160000,${git("rev-parse", "HEAD").trim()},mod`);
  same("a gitlink with nothing on disk");
  mkdirSync(join(cwd, "mod")); same("a gitlink's empty directory");
}));

test("treekey.mjs: a clean tree starts one git and no hash-object; a dirty one a second, once, for whatever number of files", () => aRepo(async (cwd, git, put) => {
  const { main } = await import("../../lib/treekey.mjs");
  const trace = join(cwd, ".git", "trace"), count = () => {
    writeFileSync(trace, ""); main([], { cwd, env: plain({ GIT_TRACE: trace }) });
    return readFileSync(trace, "utf8").split("\n").flatMap(l => l.match(/trace: built-in: git (\S+)/)?.[1] ?? []).join(" ");
  };
  ["a", "b", "c"].forEach(n => put(n, `${n}\n`)); git("add", "-A"); git("commit", "-qm", "x");
  assert.equal(count(), "ls-files");
  put("a", "two\n"); put("b", "two\n"); put("u", "u\n");
  assert.equal(count(), "ls-files hash-object");
}));
