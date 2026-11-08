// lib/queue.mjs: the queue entry format, one encoder and one decoder (bin/harness, lib/queue.sh, lib/spec.sh, lib/status.mjs).   node --test tests/unit/queue.test.mjs
import { test } from "node:test";
import assert from "node:assert/strict";
import { mkdirSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { sameAsCli } from "./cli-same.mjs";
import * as Q from "../../lib/queue.mjs";

const inTmp = async f => { const d = mkdtempSync(join(tmpdir(), "queue-")); try { return await f(d); } finally { rmSync(d, { recursive: true, force: true }); } };

test("queue.mjs: encodeEntry writes one argument per line", () => assert.equal(Q.encodeEntry(["start", "/p/x", "--until", "06:00"]), "start\n/p/x\n--until\n06:00\n"));
test("queue.mjs: encodeEntry keeps a multi-line argument on one line, each newline as 0x1f", () => assert.equal(Q.encodeEntry(["start", "--brief", "a\nb\n"]), "start\n--brief\na\x1fb\x1f\n"));
test("queue.mjs: encodeEntry gives an empty argument its empty line", () => assert.equal(Q.encodeEntry(["start", "", "x"]), "start\n\nx\n"));
test("queue.mjs: encodeEntry leaves a line that already holds 0x1f as it is (queue unpark passes raw lines)", () => assert.equal(Q.encodeEntry(["a\x1fb"]), "a\x1fb\n"));
test("queue.mjs: decodeEntry takes back what encodeEntry wrote, a multi-line argument whole", () => {
  const args = ["start", "/p/x", "--brief", "one\ntwo\n\nthree", ""];
  assert.deepEqual(Q.decodeEntry(Q.encodeEntry(args)), args);
});
test("queue.mjs: decodeEntry reads a last line with no final newline", () => assert.deepEqual(Q.decodeEntry("start\n/p/x"), ["start", "/p/x"]));
test("queue.mjs: decodeEntry drops a CR at each line's end (a file edited elsewhere), a last line's too, and no other", () => {
  assert.deepEqual(Q.decodeEntry("start\r\n/p/z\r\n"), ["start", "/p/z"]);
  assert.deepEqual(Q.decodeEntry("start\r\n/p/z\r"), ["start", "/p/z"]);
  assert.deepEqual(Q.decodeEntry("a\rb\n"), ["a\rb"]);
});
test("queue.mjs: decodeEntry reads an empty file as no arguments and one blank line as one empty argument", () => {
  assert.deepEqual(Q.decodeEntry(""), []);
  assert.deepEqual(Q.decodeEntry("\n"), [""]);
});
test("queue.mjs: decodeEntry keeps an empty argument in the middle and at the end", () => assert.deepEqual(Q.decodeEntry("a\n\nb\n\n"), ["a", "", "b", ""]));

test("queue.mjs: entryName of an empty queue is 0001", () => assert.equal(Q.entryName([], "start", "/p/x"), "0001-start-x.args"));
test("queue.mjs: entryName numbers past the highest name, a parked one's included, and reads no name that isn't an entry", () => {
  assert.equal(Q.entryName(["0003-start-a.args", "0012-continue-b.args", "0012-b.why", "done", "held", "runner.log", "12345-start-z.args", "007-start-y.args"], "start", "/p/x"), "0013-start-x.args");
  assert.equal(Q.entryName(["0000-start-a.args"], "start", "/p/x"), "0001-start-x.args");
});
test("queue.mjs: entryName of a continue names its run id", () => assert.equal(Q.entryName([], "continue", "demo-2"), "0001-continue-demo-2.args"));
test("queue.mjs: entryName takes what follows a start path's last slash, so a trailing slash leaves none", () => {
  assert.equal(Q.entryName([], "start", "/srv/p/proj"), "0001-start-proj.args");
  assert.equal(Q.entryName([], "start", "/srv/p/"), "0001-start-.args");
});
test("queue.mjs: entryName grows past four digits as printf %04d does", () => assert.equal(Q.entryName(["9999-start-a.args"], "start", "x"), "10000-start-x.args"));

const known = new Map([["r1", "proj"]]);
test("queue.mjs: entryProject of a start is its repository's directory name", () => assert.equal(Q.entryProject(["start", "/srv/p/proj", "run"], known), "proj"));
test("queue.mjs: entryProject of a start reads a trailing slash as basename does", () => assert.equal(Q.entryProject(["start", "/srv/p/proj/"], known), "proj"));
test("queue.mjs: entryProject of a continue is its run id looked up", () => assert.equal(Q.entryProject(["continue", "r1", "--queued"], known), "proj"));
test("queue.mjs: entryProject of a continue whose run is unknown is none", () => assert.equal(Q.entryProject(["continue", "gone"], known), null));
test("queue.mjs: entryProject of a start with no path, and of an empty entry, is none", () => {
  assert.equal(Q.entryProject(["start"], known), null);
  assert.equal(Q.entryProject([], known), null);
});

test("queue.mjs: entryFacts of a start gives its path and run id, and a start with options first has no run", () => {
  const a = Q.entryFacts(["start", "/p/x", "r9", "--until", "06:00"]), b = Q.entryFacts(["start", "/p/x", "--until", "06:00"]);
  assert.deepEqual([a.start, a.project, a.run, a.spec, a.brief], [true, "/p/x", "r9", null, ""]);
  assert.deepEqual([b.start, b.project, b.run], [true, "/p/x", ""]);
});
test("queue.mjs: entryFacts of a continue gives its run and no project", () => {
  const c = Q.entryFacts(["continue", "r1", "--queued", "--spec", "S.md"]);
  assert.deepEqual([c.start, c.project, c.run, c.spec], [false, "", "r1", "S.md"]);
});
test("queue.mjs: entryFacts takes the last --spec, a --spec with no value being empty", () => {
  assert.equal(Q.entryFacts(["start", "/p", "--spec", "a", "--spec", "b"]).spec, "b");
  assert.equal(Q.entryFacts(["start", "/p", "--spec"]).spec, "");
});
test("queue.mjs: entryFacts gives each --brief behind a newline, a multi-line one whole", () => {
  assert.equal(Q.entryFacts(["start", "/p", "--brief", "one\ntwo", "--brief", "three"]).brief, "\none\ntwo\nthree");
  assert.equal(Q.entryFacts(["start", "/p", "--brief"]).brief, "\n");
});
test("queue.mjs: entryFacts reads every place from the third on, a value that looks like an option too", () => {
  const f = Q.entryFacts(["start", "/p", "--spec", "--brief", "x"]);
  assert.deepEqual([f.run, f.spec, f.brief], ["", "--brief", "\nx"]);
  assert.equal(Q.entryFacts(["continue", "--spec", "S.md"]).spec, null);
});

test("queue.mjs: main's add writes the entry, makes done and held, prints its path, and numbers past a parked entry", () => inTmp(async d => {
  const q = join(d, "queue");
  const a = await Q.main(["add", q, "start", "/p/x", "--brief", "a\nb"], {});
  assert.deepEqual([a.rc, a.out], [0, `${q}/0001-start-x.args\n`]);
  assert.equal(readFileSync(`${q}/0001-start-x.args`, "latin1"), "start\n/p/x\n--brief\na\x1fb\n");
  writeFileSync(`${q}/held/0007-start-y.args`, "start\n/p/y\n");
  assert.equal((await Q.main(["add", q, "continue", "r1", "--queued"], {})).out, `${q}/0008-continue-r1.args\n`);
}));
test("queue.mjs: main's add with no verb or first argument is a usage error and writes nothing", () => inTmp(async d => {
  assert.equal((await Q.main(["add", join(d, "q"), "start"], {})).rc, 2);
}));
test("queue.mjs: main's write replaces an entry with its arguments encoded, a multi-line one on one line", () => inTmp(async d => {
  const f = join(d, "0003-continue-r1.args");
  writeFileSync(f, "continue\nr1\n--queued\n");
  const w = await Q.main(["write", f, "continue", "r1", "--queued", "--requested", "--brief", "first\n--now"], {});
  assert.deepEqual([w.rc, w.out], [0, ""]);
  assert.equal(readFileSync(f, "latin1"), "continue\nr1\n--queued\n--requested\n--brief\nfirst\x1f--now\n");
  assert.equal((await Q.main(["write"], {})).rc, 2);
}));
test("queue.mjs: main gives the CLI's bytes for decode, projects and facts: NUL-separated, a missing file empty", () => inTmp(async d => {
  writeFileSync(join(d, "s.args"), "start\n/srv/p/proj\nr9\n--brief\na\x1fb\n");
  writeFileSync(join(d, "c.args"), "continue\nr1\n");
  writeFileSync(join(d, "u.args"), "continue\ngone\n");
  mkdirSync(join(d, "state", "proj2", "r1"), { recursive: true });
  const r = await sameAsCli("queue.mjs", ["decode", join(d, "s.args")]);
  assert.equal(r.out, "start\0/srv/p/proj\0r9\0--brief\0a\nb\0");
  assert.equal((await sameAsCli("queue.mjs", ["decode", join(d, "absent.args")])).out, "");
  assert.equal((await sameAsCli("queue.mjs", ["projects", join(d, "state"), join(d, "s.args"), join(d, "c.args"), join(d, "u.args")])).out, "proj\0proj2\0\0");
  assert.equal((await sameAsCli("queue.mjs", ["facts", join(d, "s.args")])).out, "start\0/srv/p/proj\0r9\x000\0\0\na\nb\0");
  assert.equal((await sameAsCli("queue.mjs", ["facts", join(d, "c.args")])).out, "other\0\0r1\x000\0\0\0");
}));
test("queue.mjs: main with no question is a usage error", async () => assert.equal((await sameAsCli("queue.mjs", [])).rc, 2));
