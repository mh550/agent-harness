// lib/notify.mjs: the body cap, ntfy's actions header, GitHub URLs and the INBOX question.   node --test tests/unit/notify.test.mjs
import { test } from "node:test";
import assert from "node:assert/strict";
import { mkdtempSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { sameAsCli } from "./cli-same.mjs";
import { trimBody, actionsHeader as a, githubUrls as g, inboxQuestion as q } from "../../lib/notify.mjs";

test("notify.mjs: trimBody caps at 3500 bytes with …", () => {
  const t = trimBody("x".repeat(4000)), e = trimBody("é".repeat(2000)), s = "y".repeat(100);
  assert.ok(Buffer.byteLength(t) <= 3500, `${Buffer.byteLength(t)} bytes`);
  assert.match(t, /…$/);
  assert.ok(Buffer.byteLength(e) <= 3500, `${Buffer.byteLength(e)} bytes`);
  assert.match(e, /é…$/);
  assert.equal(trimBody(s), s);
});

test("notify.mjs: actionsHeader joins view actions, skips empty urls, at most 3", () => {
  const two = a([{ label: "Edit INBOX", url: "https://e/1" }, { label: "Skip", url: "" }, { label: "Progress", url: "https://e/2" }]);
  assert.equal(two, "view, Edit INBOX, https://e/1; view, Progress, https://e/2");
  assert.equal(a([1, 2, 3, 4].map(i => ({ label: "L" + i, url: "u" + i }))).split("; ").length, 3);
  assert.equal(a([]), "");
  assert.equal(a([{ label: "x", url: "" }]), "");
});

test("notify.mjs: githubUrls for ssh, https and non-GitHub origins", () => {
  const r = g("git@github.com:o/r.git", "harness/x", ".harness/runs/x/INBOX.md");
  assert.equal(r?.blob, "https://github.com/o/r/blob/harness/x/.harness/runs/x/INBOX.md");
  assert.equal(r.edit, "https://github.com/o/r/edit/harness/x/.harness/runs/x/INBOX.md");
  for (const u of ["git@github.com:o/r", "https://github.com/o/r.git", "https://github.com/o/r", "https://github.com/o/r/", "ssh://git@github.com/o/r.git"])
    assert.equal(g(u, "b", "p")?.blob, "https://github.com/o/r/blob/b/p", u);
  assert.equal(g("git@github.com:o/r.git", "", "p"), null);
  assert.equal(g("/tmp/origin.git", "b", "p"), null);
  assert.equal(g("git@gitlab.com:o/r.git", "b", "p"), null);
  assert.equal(g("", "b", "p"), null);
});

test("notify.mjs: inboxQuestion is the lines added above ## Answers (never Michael's old answers)", () => {
  const b = "status: run\n\n## Answers\nold\n", x = "status: run\n### B: set the gatus vars, then answer\n\n## Answers\nold\nmine\n";
  assert.equal(q(b, x), "### B: set the gatus vars, then answer");
  assert.equal(q(b, b), "");
  assert.equal(q("", x), "status: run\n### B: set the gatus vars, then answer");
  assert.equal(q("status: run\n", x), "### B: set the gatus vars, then answer");
  assert.equal(q(b, "status: run\n### B: q\nold\n"), "### B: q");
});

// ---- main(argv, io): the CLI's bytes and exit code; stdin only from io (decisions/2026-11-03-resident-helper) ----
test("notify.mjs: main gives the CLI's bytes for trim (stdin from io), actions, urls and question", async () => {
  const d = mkdtempSync(join(tmpdir(), "nt-"));
  try {
    assert.equal((await sameAsCli("notify.mjs", ["trim"], { input: "body, no newline" })).out, "body, no newline");
    assert.ok((await sameAsCli("notify.mjs", ["trim", "10"], { input: "x".repeat(40) })).out.length < 40);
    await sameAsCli("notify.mjs", ["actions", "Open", "https://example.com/a", "Two", "https://example.com/b"]);
    assert.equal((await sameAsCli("notify.mjs", ["urls", "not a url", "b", "f"])).rc, 1);
    await sameAsCli("notify.mjs", ["urls", "git@github.com:o/r.git", "b", "f.md"]);
    await sameAsCli("notify.mjs", ["urls", "compare", "git@github.com:o/r.git", "main", "b"]);
    const f = join(d, "I.md");
    writeFileSync(f, "status: run\n\n### H1: q\nwhy\n\n## Answers\n");
    await sameAsCli("notify.mjs", ["question", join(d, "none"), f]);
  } finally { rmSync(d, { recursive: true, force: true }); }
});

test("notify.mjs: main's trim with an io that has no stdin throws without reading fd 0", async () => {
  const { main } = await import("../../lib/notify.mjs");
  assert.throws(() => main(["trim"], { cwd: "/" }), /no stdin/);
});

// ---- the v1 event (event-hook.sh; n8n-home's harness-reporter §4.3 contract, tests/fixtures/n8n-event-v1.json) ----
const v1Keys = () => Object.keys(JSON.parse(readFileSync(new URL("../fixtures/n8n-event-v1.json", import.meta.url), "utf8"))).join(" ");
const evf = { kind: "park", run: "r1", project: "p", feature: "B", title: "t", body: "b", priority: "high", click: "", actions: "" };

test("notify.mjs event: buildEvent's keys are the v1 fixture's, in order", async () => {
  const { buildEvent } = await import("../../lib/notify.mjs");
  assert.equal(Object.keys(buildEvent(evf)).join(" "), v1Keys());
});

test("notify.mjs event: v is 1, id a uuid, at an ISO time", async () => {
  const { buildEvent } = await import("../../lib/notify.mjs");
  const e = buildEvent(evf);
  assert.equal(e.v, 1);
  assert.match(e.id, /^[0-9a-f-]{36}$/);
  assert.ok(!Number.isNaN(Date.parse(e.at)), e.at);
  assert.notEqual(buildEvent(evf).id, e.id);
  const fixed = buildEvent(evf, new Date("2026-11-07T12:00:00Z"), () => "00000000-0000-4000-8000-000000000000");
  assert.equal(`${fixed.at} ${fixed.id}`, "2026-11-07T12:00:00.000Z 00000000-0000-4000-8000-000000000000");
});

test("notify.mjs event: an empty click, actions or context is null, an empty priority stays the empty string", async () => {
  const { buildEvent } = await import("../../lib/notify.mjs");
  const e = buildEvent({ ...evf, priority: "", context: "" });
  assert.equal(JSON.stringify([e.click, e.actions, e.context, e.priority]), '[null,null,null,""]');
  const f = buildEvent({ ...evf, click: "https://e/c", actions: "view, E, https://e/e", feature: "", project: "", run: "" });
  assert.equal(JSON.stringify([f.click, f.actions, f.feature, f.project, f.run]), '["https://e/c","view, E, https://e/e",null,null,null]');
  assert.equal(JSON.stringify([e.kind, e.project, e.run, e.feature, e.title, e.body]), '["park","p","r1","B","t","b"]');
});

test("notify.mjs event: a debrief has null project, run and feature", async () => {
  const { buildEvent } = await import("../../lib/notify.mjs");
  const e = buildEvent({ ...evf, kind: "debrief" });
  assert.equal(JSON.stringify([e.kind, e.project, e.run, e.feature]), '["debrief",null,null,null]');
});

test("notify.mjs event: the CLI prints buildEvent's JSON on one line", async () => {
  const { cli } = await import("./cli-same.mjs");
  const argv = ["event", "kind=park", "run=r1", "project=p", "feature=B", "title=t", "body=b=c", "priority=high", "click=", "actions="];
  const r = cli("notify.mjs", argv);
  assert.equal(r.rc, 0);
  assert.equal(r.out.split("\n").length, 2, r.out);   // one line and its newline
  const e = JSON.parse(r.out);
  assert.equal(Object.keys(e).join(" "), v1Keys());
  assert.equal(JSON.stringify([e.v, e.kind, e.run, e.project, e.feature, e.title, e.body, e.priority, e.click, e.actions, e.context]),
    '[1,"park","r1","p","B","t","b=c","high",null,null,null]');
  assert.match(e.id, /^[0-9a-f-]{36}$/);
  assert.ok(!Number.isNaN(Date.parse(e.at)));
  const m = await sameAsCli("notify.mjs", ["event", "kind=nope", "title=t"]);   // main in the helper answers as the spawn does
  assert.equal(m.rc, 2);
});

test("notify.mjs event: a kind outside v1 prints nothing and exits 2", async () => {
  const { cli } = await import("./cli-same.mjs");
  for (const k of ["paused", "", "PARK"]) {
    const r = cli("notify.mjs", ["event", `kind=${k}`, "title=t", "body=b"]);
    assert.equal(`${r.rc} ${JSON.stringify(r.out)}`, '2 ""', k);
  }
  assert.equal(cli("notify.mjs", ["event", "title=t"]).rc, 2);
});

test("notify.mjs event: a given id= is the event's id", async () => {
  const { buildEvent } = await import("../../lib/notify.mjs");
  const id = "6b80f60a-b34d-4abd-9ec8-3c037d8ef44d";
  assert.equal(buildEvent({ ...evf, id }).id, id);   // the bundle's events/<id>/ is the event's
  for (const bad of ["", "short", "../x/../y-zzzz", "a".repeat(65), "has space 123"])
    assert.match(buildEvent({ ...evf, id: bad }).id, /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/, bad);
});
