// lib/testcount.mjs: the passing-test count lib/check.sh reads from a suite's output.   node --test tests/unit/testcount.test.mjs
import { test } from "node:test";
import assert from "node:assert/strict";
import { mkdtempSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { sameAsCli } from "./cli-same.mjs";
import { testCount, total } from "../../lib/testcount.mjs";

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

// the --total CLI's bytes are main's test below; through check.sh, 73-check-rerun's green marker
test("testcount.mjs: total is the last N/M line's M, null without one", () => {
  assert.equal(total("3/5 checks passed\nx 7/9 tests passed\n"), 9);
  assert.equal(total("FAIL a\n3/5 checks passed\nPASS b\n2/2 checks passed\n"), 2);
  assert.equal(total("ok"), null);
  // a count with no /M (the contract line, a bare "12 passed") is a count, never a total
  assert.equal(total("HARNESS_TESTS=4\n12 passed\n"), null);
});

test("testcount.mjs: main gives the CLI's bytes with and without --total and --source, and a missing file is no output and 0", async () => {
  const d = mkdtempSync(join(tmpdir(), "tc-"));
  try {
    const f = join(d, "out"), n = join(d, "none");
    writeFileSync(f, "PASS a\n3/5 checks passed\n"); writeFileSync(n, "ok\n");
    assert.deepEqual(await sameAsCli("testcount.mjs", [f]), { rc: 0, out: "3 tests\n" });
    assert.deepEqual(await sameAsCli("testcount.mjs", [f, "--total"]), { rc: 0, out: "5 tests\n" });
    assert.deepEqual(await sameAsCli("testcount.mjs", [f, "--source"]), { rc: 0, out: "3 tests · generic\n" });
    assert.deepEqual(await sameAsCli("testcount.mjs", [n]), { rc: 0, out: "" });
    assert.deepEqual(await sameAsCli("testcount.mjs", [n, "--total"]), { rc: 0, out: "" });
    assert.deepEqual(await sameAsCli("testcount.mjs", [n, "--source"]), { rc: 0, out: "? tests · none\n" });
    assert.deepEqual(await sameAsCli("testcount.mjs", [join(d, "missing")]), { rc: 0, out: "" });
    assert.deepEqual(await sameAsCli("testcount.mjs", []), { rc: 0, out: "" });
  } finally { rmSync(d, { recursive: true, force: true }); }
});
