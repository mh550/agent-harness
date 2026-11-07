// lib/status.mjs: unquote, a printf %q word back to its text, and queue show reading one from meta.env.   node --test tests/unit/status.test.mjs
import { test } from "node:test";
import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { mkdirSync, mkdtempSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { fileURLToPath } from "node:url";
import { unquote } from "../../lib/status.mjs";

const STATUS = fileURLToPath(new URL("../../lib/status.mjs", import.meta.url));

test("queue show: a continue names its project path from meta.env, one %q quoted under a C locale too", () => {
  const d = mkdtempSync(join(tmpdir(), "status-"));
  try {
    const st = join(d, "p", "qrun"), q = join(d, "queue");
    mkdirSync(st, { recursive: true }); mkdirSync(q);
    writeFileSync(join(st, "meta.env"), "PROJECT_DIR=$'/p/caf\\303\\251 x'\nRUN_ID=qrun\n");
    writeFileSync(join(q, "0001-continue-qrun.args"), "continue\nqrun\n--queued\n");
    const row = ["qrun", "p", st, "/nonexistent", "/nonexistent", "0"].join("\t");
    const r = spawnSync(process.execPath, [STATUS, "entry", "1", "--queue", q], { input: `${row}\n`, env: { ...process.env, HARNESS_GLYPHS: "unicode" }, encoding: "utf8" });
    assert.equal(r.status, 0);
    assert.ok(r.stdout.split("\n").includes("  project    /p/café x"), r.stdout);
  } finally { rmSync(d, { recursive: true, force: true }); }
});
test("status.mjs: unquote reads a $'…' word's octal bytes and C escapes as UTF-8", () => {
  assert.equal(unquote("$'/p/caf\\303\\251 x'"), "/p/café x");
  assert.equal(unquote("$'a\\tb\\nc\\x41'"), "a\tb\ncA");
});
test("status.mjs: unquote reads a '…' word and a backslash-escaped one, and none is null", () => {
  assert.equal(unquote("'/p/my dir'"), "/p/my dir");
  assert.equal(unquote("/p/my\\ dir"), "/p/my dir");
  assert.equal(unquote(undefined), null);
});
