// lib/overlap.mjs: the tracked paths a spec or brief names and where two lists meet.   node --test tests/unit/overlap.test.mjs
import { test } from "node:test";
import assert from "node:assert/strict";
import { named, overlap } from "../../lib/overlap.mjs";

// the import is the check that the module parses and does no I/O at import (its CLI runs only as argv[1]); the CLI's
// named, overlap and names on files stay in 70-overlap
test("overlap: named and overlap are exported and pure (no I/O at import); node --check lib/overlap.mjs", () => {
  const n = named("`lib/a.sh` lib/b/", ["lib/a.sh", "lib/b/c.mjs"]);
  assert.equal(n.join(), "lib/a.sh,lib/b/");
  assert.equal(overlap(n, ["lib/b/c.mjs"]).join(), "lib/b/c.mjs");
});
