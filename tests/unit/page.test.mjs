// lib/page.mjs: the debrief page's run cards (their tone pill).   node --test tests/unit/page.test.mjs
import { test } from "node:test";
import assert from "node:assert/strict";
import { card } from "../../lib/page.mjs";

const pill = r => card({ run: "r", project: "p", end_reason: r }, "").match(/<span class="pill (\w+)">/)?.[1];

test("the debrief page never reads a stop reason's words as its tone", () => {
  assert.equal(pill("stopped by Michael: blocked, failed"), "muted");
  assert.equal(pill("blocked on A"), "warn");
});
