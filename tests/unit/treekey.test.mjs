// lib/treekey.mjs: the tree's key, the partial map's keys and names, on a fixed file list (no git).   node --test tests/unit/treekey.test.mjs
import { test } from "node:test";
import assert from "node:assert/strict";
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
