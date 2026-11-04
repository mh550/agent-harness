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

test("testCount: the last HARNESS_TESTS= line wins, and only a whole line counts", () => {
  assert.equal(testCount("HARNESS_TESTS=3\n# pass 9\nHARNESS_TESTS=5\n"), 5);
  assert.equal(testCount("echo HARNESS_TESTS=8\n# pass 2\n"), 2);
});

test("testCount: a HARNESS_TESTS= line with trailing text or a count past 2^53 is no contract, a CRLF one is", () => {
  assert.equal(testCount("HARNESS_TESTS=8 of 9\n# pass 2\n"), 2);
  assert.equal(testCount("HARNESS_TESTS=8\r\n"), 8);
  assert.equal(testCount("HARNESS_TESTS=123456789012345678901\n# pass 2\n"), 2);
});
