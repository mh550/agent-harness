// lib/notify.mjs: the body cap, ntfy's actions header, GitHub URLs and the INBOX question.   node --test tests/unit/notify.test.mjs
import { test } from "node:test";
import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { createHash } from "node:crypto";
import { mkdtempSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { sameAsCli, sameBytes } from "./cli-same.mjs";
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

// every v1 kind's bytes before v2 (2026-11-10, the fixed now and uuid below): node -e 'import("./lib/notify.mjs").then(…)'
// over KINDS, each JSON.stringify(buildEvent({...evf, kind}, now, uuid)) joined by "\n", sha256
const V1_SHA = "84b98d33b04cba8490838428646a0a9a2ce67cc9180aebc5dd7b131e925a7c7f";
const NOW = new Date("2026-11-07T12:00:00Z"), UUID = () => "00000000-0000-4000-8000-000000000000";
test("notify.mjs event: every kind but memory is the v1 fixture's 13 keys in order with v 1, the bytes before v2", async () => {
  const { buildEvent, KINDS } = await import("../../lib/notify.mjs");
  const v1 = KINDS.filter(k => k !== "memory");
  assert.equal(v1.join(" "), "park needs_michael blocked ended debrief verified merged started limit other");
  for (const kind of v1) {
    const e = buildEvent({ ...evf, kind, memory: undefined }, NOW, UUID);
    assert.equal(`${e.v} ${Object.keys(e).join(" ")}`, `1 ${v1Keys()}`, kind);
  }
  const s = v1.map(kind => JSON.stringify(buildEvent({ ...evf, kind }, NOW, UUID))).join("\n");
  assert.equal(createHash("sha256").update(s).digest("hex"), V1_SHA);
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

// ---- v2: the memory kind alone (docs/specs/2026-11-10-review-surface.md §V1-01; tests/fixtures/n8n-event-v2-memory.json) ----
// the v2 fixture is this stdout over tests/fixtures/memory/event-card.json (itself `node lib/memreview.mjs card event-verdicts.json event-memory.json event-input.json pr` on that directory's stub-run files), with the id, at and both PR URLs put back as placeholders:
// M=tests/fixtures/memory c=$M/event-card.json f=$(jq -r .pr $c) r=$(jq -r .rules_pr $c); node lib/notify.mjs event kind=memory run=mev project=proj feature= title="$(node lib/memreview.mjs title $c mev)" body="$(node lib/memreview.mjs line $M/event-verdicts.json $M/event-memory.json)" priority= click="$f" actions="$(node lib/notify.mjs actions "Facts PR" "$f" "Rules PR" "$r")" context= memory=$c | jq -c --arg f "$f" --arg r "$r" '.id = "<uuid>" | .at = "<ISO 8601>" | walk(if type == "string" then split($f) | join("<facts PR url>") | split($r) | join("<rules PR url>") else . end)' > tests/fixtures/n8n-event-v2-memory.json
const v2 = () => JSON.parse(readFileSync(new URL("../fixtures/n8n-event-v2-memory.json", import.meta.url), "utf8"));
const MEM = new URL("../fixtures/memory/event-card.json", import.meta.url).pathname;

test("notify.mjs event: ROUTED is v1's four and ROUTED_V2 is it plus memory, the kinds notify.sh's routing arms name", async () => {
  const { ROUTED, ROUTED_V2, KINDS } = await import("../../lib/notify.mjs");
  assert.equal(JSON.stringify(ROUTED), '["park","needs_michael","blocked","debrief"]');
  assert.equal(JSON.stringify(ROUTED_V2), '["park","needs_michael","blocked","debrief","memory"]');
  assert.ok(KINDS.includes("memory"));
  // notify.sh's case line is what routes: its EVENT_URL arm names ROUTED, its EVENT_URL-and-EVENT_V2 arm the rest of ROUTED_V2
  const sh = readFileSync(new URL("../../lib/notify.sh", import.meta.url), "utf8"), arms = { v1: [], v2: [] };
  for (const m of sh.matchAll(/([a-z_|]+)\) \[\[ -n \$\{EVENT_URL:-\}( && \$\{EVENT_V2:-\} == 1)? \]\] && notify_event && return 0/g))
    arms[m[2] ? "v2" : "v1"].push(...m[1].split("|"));
  assert.equal(JSON.stringify(arms.v1), JSON.stringify(ROUTED));
  assert.equal(JSON.stringify(arms.v2), JSON.stringify(ROUTED_V2.filter(k => !ROUTED.includes(k))));
});

test("notify.mjs event: the memory kind with memory=<file> is v 2, the v2 fixture's 14 keys in order, the file's object under memory", async () => {
  const { cli } = await import("./cli-same.mjs");
  const { line, title } = await import("../../lib/memreview.mjs");
  const fx = n => JSON.parse(readFileSync(new URL(`../fixtures/memory/event-${n}.json`, import.meta.url), "utf8")), c = fx("card");
  const argv = ["event", "kind=memory", "run=mev", "project=proj", "feature=", `title=${title(c, "mev")}`, `body=${line(fx("verdicts"), fx("memory"))}`,
    "priority=", `click=${c.pr}`, `actions=${a([{ label: "Facts PR", url: c.pr }, { label: "Rules PR", url: c.rules_pr }])}`, "context=", `memory=${MEM}`];
  const r = cli("notify.mjs", argv);
  assert.equal(r.rc, 0);
  assert.equal(r.out.split("\n").length, 2, r.out);
  const e = JSON.parse(r.out);
  assert.equal(Object.keys(e).join(" "), Object.keys(v2()).join(" "));
  assert.equal(Object.keys(e).slice(0, 13).join(" "), v1Keys());
  assert.equal(JSON.stringify([e.v, e.kind, e.feature, e.priority, e.context]), '[2,"memory",null,"",null]');
  assert.equal(JSON.stringify(e.memory), JSON.stringify(JSON.parse(readFileSync(MEM, "utf8"))));
  assert.equal(Object.keys(e.memory).join(" "), Object.keys(v2().memory).join(" "));
  const placed = JSON.stringify({ ...e, id: "<uuid>", at: "<ISO 8601>" }).split(c.pr).join("<facts PR url>").split(c.rules_pr).join("<rules PR url>");
  sameBytes(`${placed}\n`, readFileSync(new URL("../fixtures/n8n-event-v2-memory.json", import.meta.url), "utf8"), "the v2 fixture");
  const m = await sameAsCli("notify.mjs", argv.map(a => (a.startsWith("memory=") ? "memory=/nonexistent/m.json" : a)));
  assert.equal(`${m.rc} ${JSON.stringify(m.out)}`, '2 ""', "an unreadable memory= file");
});

test("notify.mjs event: memory= on a v1 kind, and the memory kind without it, print nothing and exit 2; an empty memory= is none", async () => {
  const { cli } = await import("./cli-same.mjs");
  const { buildEvent } = await import("../../lib/notify.mjs");
  const a = spawnSync(process.execPath, [new URL("../../lib/notify.mjs", import.meta.url).pathname, "event", "kind=park", "title=t", `memory=${MEM}`]);
  assert.equal(`${a.status} ${JSON.stringify(a.stdout.toString())}`, '2 ""');
  assert.match(a.stderr.toString(), /memory= is the memory kind's/);
  const b = cli("notify.mjs", ["event", "kind=memory", "title=t"]);
  assert.equal(`${b.rc} ${JSON.stringify(b.out)}`, '2 ""');
  const c = cli("notify.mjs", ["event", "kind=park", "title=t", "memory="]);   // notify_event's call passes it empty
  assert.equal(`${c.rc} ${JSON.parse(c.out).v} ${Object.keys(JSON.parse(c.out)).join(" ")}`, `0 1 ${v1Keys()}`);
  assert.throws(() => buildEvent({ ...evf, memory: {} }), /memory= is the memory kind's/);
  assert.throws(() => buildEvent({ ...evf, kind: "memory" }), /needs memory=/);
});
