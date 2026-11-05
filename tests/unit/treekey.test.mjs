// lib/treekey.mjs: the tree's key, the partial map's keys and names, on a fixed file list (no git).   node --test tests/unit/treekey.test.mjs
import { test } from "node:test";
import assert from "node:assert/strict";
import { execFileSync } from "node:child_process";
import { mkdirSync, mkdtempSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { sameAsCli, mainOf } from "./cli-same.mjs";
import { ignoreList, parseMap, treeKey, partialKeys, mapNames } from "../../lib/treekey.mjs";

// the CLI on a git tree (--partial, --names, a dropped entry's stderr) stays in 81-partial-key; the map's first path is any file
// (81's eval named the project rules file, which no unit test names: the key map can't see tests/unit)
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
