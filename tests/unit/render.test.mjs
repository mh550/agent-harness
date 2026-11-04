// lib/render.mjs: a prompt's assembly from a template and its sections.   node --test tests/unit/render.test.mjs
import { test } from "node:test";
import assert from "node:assert/strict";
import { assemble } from "../../lib/render.mjs";

test("render.mjs: assemble puts the sections at the {{SECTIONS}} line, one blank line apart", () => {
  const env = { HARNESS_X: "x" }, s = [{ title: "T", body: "b {{X}}", raw: false }, { title: null, body: "u {{X}}", raw: true }];
  assert.equal(assemble("top\n\n{{SECTIONS}}\n\nend {{X}}\n", s, env), "top\n\n---\n\n# T\n\nb x\n\nu {{X}}\n\nend x\n");
  assert.equal(assemble("top {{X}}\n", s, env), "top x\n\n---\n\n# T\n\nb x\n\nu {{X}}\n");
});
