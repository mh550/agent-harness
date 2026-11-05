// lib/render.mjs: a prompt's assembly from a template and its sections.   node --test tests/unit/render.test.mjs
import { test } from "node:test";
import assert from "node:assert/strict";
import { mkdtempSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { sameAsCli } from "./cli-same.mjs";
import { assemble } from "../../lib/render.mjs";

test("render.mjs: assemble puts the sections at the {{SECTIONS}} line, one blank line apart", () => {
  const env = { HARNESS_X: "x" }, s = [{ title: "T", body: "b {{X}}", raw: false }, { title: null, body: "u {{X}}", raw: true }];
  assert.equal(assemble("top\n\n{{SECTIONS}}\n\nend {{X}}\n", s, env), "top\n\n---\n\n# T\n\nb x\n\nu {{X}}\n\nend x\n");
  assert.equal(assemble("top {{X}}\n", s, env), "top x\n\n---\n\n# T\n\nb x\n\nu {{X}}\n");
});

test("render.mjs: a line opening {{?X}} stays (the marker cut) only when HARNESS_X is set and not empty, one opening {{!X}} only when not", () => {
  const t = "a\n{{?X}}x is {{X}}\n{{!X}}no x\nb\n", s = [{ title: "T", body: "{{?X}}sx\n{{!X}}sn\nend", raw: false }];
  assert.equal(assemble(t, [], { HARNESS_X: "1" }), "a\nx is 1\nb\n");
  assert.equal(assemble(t, [], { HARNESS_X: "" }), "a\nno x\nb\n");
  assert.equal(assemble(t, [], {}), "a\nno x\nb\n");
  assert.equal(assemble("top\n{{SECTIONS}}\n", s, { HARNESS_X: "y" }), "top\n\n---\n\n# T\n\nsx\nend\n\n");
  // a raw section keeps its markers; one mid-line is no marker
  assert.equal(assemble("{{SECTIONS}}", [{ title: null, body: "{{?X}}r", raw: true }], {}), "\n\n{{?X}}r\n\n");
  assert.equal(assemble("m {{?X}}k\n", [], {}), "m {{?X}}k\n");
});

test("render.mjs: main gives the CLI's bytes, HARNESS_ variables from io.env, a titled and a --raw section", async () => {
  const d = mkdtempSync(join(tmpdir(), "rd-"));
  try {
    writeFileSync(join(d, "t.md"), "top {{X}}\n\n{{SECTIONS}}\n\nend\n"); writeFileSync(join(d, "s.md"), "s {{X}}\n");
    const r = await sameAsCli("render.mjs", [join(d, "t.md"), `T=${join(d, "s.md")}`, "--raw", join(d, "s.md")], { env: { HARNESS_X: "x1" } });
    assert.equal(r.rc, 0);
    assert.match(r.out, /^top x1\n/);
    assert.match(r.out, /s \{\{X\}\}/);
    assert.notEqual((await sameAsCli("render.mjs", [join(d, "t.md")], { env: { HARNESS_X: "x2" } })).out, r.out);
  } finally { rmSync(d, { recursive: true, force: true }); }
});
