// lib/testcount.mjs: the passing-test count lib/check.sh reads from a suite's output.   node --test tests/unit/testcount.test.mjs
import { test } from "node:test";
import assert from "node:assert/strict";
import { testCount } from "../../lib/testcount.mjs";

test("testcount.mjs: the runner's last N/M checks passed is the count", () => {
  assert.equal(testCount("PASS a\n2/2 checks passed\nPASS b\n325/326 checks passed\n"), 325);
  assert.equal(testCount("12 passed, 1 failed"), 12);
  assert.equal(testCount("# pass 7\n"), 7);
  assert.equal(testCount("ok"), null);
});
