// lib/parked.mjs: `harness parked`'s report, the INBOX question it quotes, its commands and run state.   node --test tests/unit/parked.test.mjs
import { test } from "node:test";
import assert from "node:assert/strict";
import { parkedReport as r, questionFor as q, commandsFor as c, runState as s, entriesFor } from "../../lib/parked.mjs";

const esc = x => x.replace(/[.*+?^${}()|[\]\\]/g, "\\$&"), lit = x => new RegExp(esc(x));
// the eval ran under `TZ=UTC node`; node rereads process.env.TZ on assignment, so the test sets it and puts it back
const inTZ = (tz, fn) => {
  const was = process.env.TZ;
  process.env.TZ = tz;
  try { fn(); } finally { if (was === undefined) delete process.env.TZ; else process.env.TZ = was; }
};

test("parked.mjs: the report names the answer and continue commands", () => {
  const e = { run: "r", project: "p", feature: "B", since: "2026-10-19T01:00:00Z", why: "w", question: "q", running: false, runner: false };
  const a = r([e]), b = r([{ ...e, runner: true }]), cc = r([{ ...e, running: true }]), j = JSON.parse(r([e, { ...e, run: "s", since: "2026-10-18T01:00:00Z" }], { json: true }));
  assert.match(a, lit("harness answer r \"…\""));
  assert.match(a, lit("harness continue r"));
  assert.match(b, lit("harness queue add --continue r"));
  assert.doesNotMatch(b, lit("harness continue r"));
  assert.match(cc, lit("running:  yes"));
  assert.match(cc, lit("harness answer r \"…\""));
  assert.doesNotMatch(cc, lit("continue r"));
  assert.equal(r([], {}), "nothing parked\n");
  assert.equal(r([], { run: "x" }), "nothing parked in x\n");
  assert.equal(JSON.parse(r([], { json: true })).length, 0);
  assert.equal(j.map(x => x.run).join(), "s,r");
  assert.equal(Object.keys(j[0]).join(), "run,project,feature,since,why,question,running,ending,queued,commands");
});

test("parked.mjs: the question is the feature's INBOX section", () => inTZ("UTC", () => {
  const i = "status: run\n<!-- Steer this run\n     from the app -->\n\n### A: db url\nwhich db?\n### B: set the gatus vars, then answer\n\n## Answers\n### B: an old answer\n";
  const t = r([{ run: "parky", project: "proj", feature: "B", since: "2026-10-19T01:00:00Z", why: "set the gatus vars", question: q(i, "A"), running: false, runner: false }], { now: Date.parse("2026-10-19T03:00:00Z") });
  assert.equal(q(i, "B"), "### B: set the gatus vars, then answer");
  assert.equal(q(i, "C"), "### A: db url\nwhich db?\n### B: set the gatus vars, then answer");
  assert.equal(q("status: run\n\n## Answers\n", "B"), "");
  assert.equal(q("### Bx: q\n## Answers\n", "B"), "### Bx: q");
  assert.equal(q("", "B"), "");
  assert.equal(q("### A: needs B first\n### B: the vars\n", "B"), "### B: the vars");
  assert.equal(t, "parky · proj · B\n  since:    2026-10-19 01:00 (2 h ago)\n  why:      set the gatus vars\n  question: ### A: db url\n            which db?\n  running:  no\n  next:     harness answer parky \"…\"\n            harness continue parky\n");
}));

test("parked.mjs: the newest question wins, ids with dots, code fences, never Michael's answers", () => {
  assert.equal(q("status: run\n\n### B: set the gatus vars\nold, answered\n\n### B: now the token too\nnew one\n\n## Answers\n", "B"), "### B: now the token too\nnew one");
  assert.equal(q("### 1.2: y\n### 1.2.3: x\n## Answers\n", "1.2"), "### 1.2: y");
  assert.equal(q("### B: q\nthe text\n## Notes\nnot it\n## Answers\n", "B"), "### B: q\nthe text");
  assert.equal(q("status: run\n### B: q\n### 2026-10-19 10:00 (local)\nmy answer\n", "C"), "### B: q");
  assert.equal(q("status: run\n### B: q1\n### 2026-10-19 10:00 (local)\nans\n### B: q2 new\n", "B"), "### B: q2 new");
  assert.equal(q("### B: set vars\n```bash\n# put these in .env\nFOO=1\n```\nthen answer\n## Answers\n", "B"), "### B: set vars\n```bash\n# put these in .env\nFOO=1\n```\nthen answer");
  assert.deepEqual(c("r", { queued: true }), ["harness answer r \"…\""]);
});

test("parked.mjs: another live run of the project: the queue add and --now, each with its merge order", () => {
  const b = c("r", { busy: "o" }), Q = "harness queue add --continue r # waits for o to end; o merges first", N = "harness continue r --now # runs beside o; this run merges first if it finishes first";
  const t = r(entriesFor({ run: "r", project: "p", parked: { B: { why: "w", at: "2026-10-19T01:00:00Z" } }, list: null, inbox: "", busy: "o" })), j = JSON.parse(r([{ run: "r", feature: "B", busy: "o" }], { json: true }));
  assert.deepEqual(b, ["harness answer r \"…\"", Q, N]);
  assert.deepEqual(c("r", { busy: "o", runner: true }), b);
  assert.equal(c("r", { busy: "o", running: true }).length, 1);
  assert.equal(c("r", { busy: "o", queued: true }).length, 1);
  assert.deepEqual(c("r", { busy: "" }), c("r"));
  assert.deepEqual(c("r", { busy: "", runner: true }), ["harness answer r \"…\"", "harness queue add --continue r"]);
  assert.equal(s({ busy: "o" }), "no; o is running on this project: pick one continue");
  assert.match(s({ busy: "o", ending: true }), /^ending \(answer now/);
  assert.match(s({ busy: "o", ending: true }), /; o is running on this project: pick one continue$/);
  assert.equal(s({ busy: "o", running: true }), s({ running: true }));
  assert.equal(s({ busy: "o", queued: true }), s({ queued: true }));
  assert.equal(s({ busy: "" }), "no");
  assert.match(t, lit("  running:  no; o is running on this project"));
  assert.match(t, lit("            " + Q));
  assert.match(t, lit("            " + N));
  assert.deepEqual(j[0].commands, b);
});
