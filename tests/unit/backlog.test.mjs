// lib/backlog.mjs: the retro backlog's statuses, its merge of proposals and its listing order.   node --test tests/unit/backlog.test.mjs
import { test } from "node:test";
import assert from "node:assert/strict";
import { STATUSES, orderRows, mergeProposals } from "../../lib/backlog.mjs";

// was the tail of tests/checks/35-backlog-pure-m1.sh's import check, whose name is the CLI's (decisions/2026-11-03-unit-tier)
test("backlog.mjs: STATUSES in order, mergeProposals adds a new id, orderRows of none is empty", () => {
  assert.equal(STATUSES.join(), "proposed,specced,queued,merged,dropped");
  assert.equal(mergeProposals([], [{ id: "a", title: "t" }], "r", "d").rows.length, 1);
  assert.equal(orderRows([]).length, 0);
});
