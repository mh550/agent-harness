// lib/show.mjs: harness show's pure parts (joinDiff, mergeTreePaths, combine, milestonesOf) and the feature form's render.   node --test tests/unit/show.test.mjs
import { test } from "node:test";
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { joinDiff, mergeTreePaths, combine, milestonesOf, renderFeature } from "../../lib/show.mjs";

test("show: the pure parts: joinDiff joins by path (binary +/− null, .harness/runs/ left out), mergeTreePaths reads the real output, combine counts one blob once (stacked or fanned-out lanes), milestonesOf keeps a proposal's PR", () => {
  const j = joinDiff("3\t1\tlib/a.sh\n-\t-\tpic.png\n2\t0\t.harness/runs/r/x\n", "M\tlib/a.sh\nA\tpic.png\nA\t.harness/runs/r/x\n");
  assert.deepEqual(j, [{ status: "M", path: "lib/a.sh", added: 3, deleted: 1 }, { status: "A", path: "pic.png", added: null, deleted: null }]);
  assert.deepEqual(j.map(x => Object.keys(x).join()), ["status,path,added,deleted", "status,path,added,deleted"]);
  // git merge-tree --name-only's real output (tests/fixtures/merge-tree-name-only.txt)
  assert.deepEqual(mergeTreePaths(readFileSync(new URL("../fixtures/merge-tree-name-only.txt", import.meta.url), "utf8")), ["f.txt", "work-A.txt"]);
  const r = (x, blob) => [{ status: "A", path: x, added: 5, deleted: 0, blob }];
  const c = combine([{ rows: r("a", "1"), conflicts: [] }, { rows: [...r("a", "1"), ...r("b", "2")], conflicts: ["b"] }, { rows: [...r("a", "1"), ...r("b", "3")], conflicts: [] }]);
  assert.equal(c.files, 2);
  assert.equal(c.added, 15);
  assert.equal(c.rows[0].path, "b");
  assert.equal(c.rows[0].added, 10);
  assert.equal(c.rows[0].conflict, true);
  assert.equal(c.rows[1].added, 5);
  assert.equal("blob" in c.rows[0], false);
  assert.deepEqual(c.conflicts, ["b"]);
  const m = milestonesOf("- 2026-10-28 17:56 · M1 proposed for merging · https://github.com/o/r/pull/7\n- 2026-10-28 18:00 · record PR merged into main · https://x/pull/9\n- 2026-10-28 18:01 · M1 merged into main (by its PR)\n- 2026-10-28 18:02 · M2 merged into main · https://github.com/o/r/pull/8\n");
  assert.deepEqual(m, [{ id: "M1", status: "merged", url: "https://github.com/o/r/pull/7" }, { id: "M2", status: "merged", url: "https://github.com/o/r/pull/8" }]);
  assert.deepEqual(m.map(x => Object.keys(x).join()), ["id,status,url", "id,status,url"]);
});

test("show: an entry resume's metrics row is listed as an entry resume, never a second coding session", () => {
  const s = (kind, role) => ({ role, kind, model: "opus", wall_s: 60, cost_usd: 1, result: "success" });
  const doc = { feature: { id: "A", milestone: "M1", description: "a", passes: false, attempts: 1, max_attempts: 2, steps: [], sessions: [s("coding", "build"), s("entry-resume", "coding")], files: [], commits: [], card: null } };
  const out = [].concat(renderFeature(doc, { width: 200, now: 0 }, { head: { r: { run: "x", features: {} }, x: {}, extra: [] } })).join("\n");
  assert.match(out, / · entry resume · opus · /);
  assert.doesNotMatch(out, / · coding · /);
});
