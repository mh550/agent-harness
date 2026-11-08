// lib/requests.mjs: the request inbox's rules (v1): validation, the backup window, the result JSON and the log line.   node --test tests/unit/requests.test.mjs
import { test } from "node:test";
import assert from "node:assert/strict";
import { existsSync, mkdirSync, mkdtempSync, readFileSync, rmSync, symlinkSync, utimesSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { fileURLToPath } from "node:url";
import { cli } from "./cli-same.mjs";
import { BACKUP_REFUSAL, inBackupWindow, logLine, resultJson, resultName, validateRequest } from "../../lib/requests.mjs";

// the requests n8n-home's own buildRequest wrote (tests/fixtures/requests/README.md): every shape here is one of them
const FX = fileURLToPath(new URL("../fixtures/requests/", import.meta.url));
const fx = n => JSON.parse(readFileSync(join(FX, `${n}.json`), "utf8"));
const ANSWER = fx("answer"), CONTINUE = fx("continue"), BRIEF = fx("continue-brief");
const text = (base, change = {}) => `${JSON.stringify({ ...base, ...change })}\n`;
const RUNS = new Set(["parked", "stopped", "x"]);
const ctx = (o = {}) => ({ runs: RUNS, done: new Set(), ageSeconds: 30, ...o });
const check = (base, change, o) => validateRequest(text(base, change), ctx(o));
const refused = (r, reason) => {
  assert.equal(r.verdict, "rejected", `verdict for ${reason}`);
  assert.equal(r.reason, reason);
};

test("requests.mjs: a valid answer is ok and keeps its text byte for byte", () => {
  const t = "it's `x` $(rm -rf /) \"q\"\nline two\n";
  const r = check(ANSWER, { text: t });
  assert.equal(r.verdict, "ok");
  assert.equal(r.id, "req-0001-aaaa");
  assert.equal(r.verb, "answer");
  assert.equal(r.run, "parked");
  assert.equal(r.text, t);
  assert.equal(r.reason, null);
});

test("requests.mjs: a valid continue is ok with and without a brief, and an empty brief is none", () => {
  const plain = check(CONTINUE);
  assert.equal(plain.verdict, "ok");
  assert.equal(plain.verb, "continue");
  assert.equal(plain.run, "stopped");
  assert.equal(plain.brief, null);
  const withBrief = check(BRIEF);
  assert.equal(withBrief.verdict, "ok");
  assert.equal(withBrief.brief, "Finish B3 first.");
  assert.equal(check(BRIEF, { brief: "" }).brief, null);
});

test("requests.mjs: v 2 is rejected", () => {
  refused(check(ANSWER, { v: 2 }), "v is not 1 (this harness reads request v1)");
});

test("requests.mjs: an array, a string and null are not a request object", () => {
  for (const t of ["[]\n", "\"answer\"\n", "null\n"]) refused(validateRequest(t, ctx()), "the request is not a JSON object");
});

test("requests.mjs: an id of 7 characters or with a slash is rejected and named nowhere", () => {
  for (const id of ["req-001", "req/0001-aaaa"]) {
    const r = check(ANSWER, { id });
    refused(r, "id does not match ^[A-Za-z0-9-]{8,64}$");
    assert.equal(r.id, null);
    assert.ok(!JSON.stringify(r).includes(id), `${id} is named in ${JSON.stringify(r)}`);
  }
});

test("requests.mjs: an id already in done is a duplicate", () => {
  const r = check(ANSWER, {}, { done: new Set(["req-0001-aaaa"]) });
  assert.equal(r.verdict, "duplicate");
  assert.equal(r.reason, "duplicate id: done/req-0001-aaaa.json already exists");
  assert.equal(r.id, "req-0001-aaaa");
});

test("requests.mjs: verb merge is rejected", () => {
  const r = check(ANSWER, { verb: "merge" });
  refused(r, "verb is not answer or continue");
  assert.equal(r.verb, null);
});

test("requests.mjs: a run with a parent-directory segment is rejected by its pattern before any lookup", () => {
  const r = check(ANSWER, { run: "../x" });   // runs holds x: only the pattern can refuse it
  refused(r, "run does not match ^[A-Za-z0-9._-]+$");
  assert.equal(r.run, null);
});

test("requests.mjs: a run not among the real runs is rejected with state_of's words", () => {
  const r = check(CONTINUE, { run: "nosuch" });
  refused(r, "no run 'nosuch' (see: harness status)");
  assert.equal(r.run, null);
});

test("requests.mjs: an empty text and a text of 4001 characters are rejected, 4000 is ok", () => {
  const why = "text must be 1-4000 characters for answer";
  refused(check(ANSWER, { text: "" }), why);
  refused(check(ANSWER, { text: "a".repeat(4001) }), why);
  refused(check(ANSWER, { text: 7 }), why);
  const { text: _, ...noText } = ANSWER;
  refused(validateRequest(text(noText), ctx()), why);
  assert.equal(check(ANSWER, { text: "a".repeat(4000) }).verdict, "ok");
});

test("requests.mjs: a brief that is one option word is refused, so no queue or continue loop reads it as a flag", () => {
  for (const b of ["--now", "--foreground", "--automatic", "--requested", "--keep-attempts", "--spec"]) {
    refused(check(BRIEF, { brief: b }), "brief may not be an option word (--…): queue add and continue would read it as one");
  }
  for (const b of ["-- ship B3", "--now please", "x\n--now", "-n"]) assert.equal(check(BRIEF, { brief: b }).verdict, "ok", b);
});

test("requests.mjs: a brief of 2001 characters is rejected, 2000 is ok", () => {
  refused(check(BRIEF, { brief: "b".repeat(2001) }), "brief must be a string of at most 2000 characters");
  refused(check(BRIEF, { brief: 7 }), "brief must be a string of at most 2000 characters");
  assert.equal(check(BRIEF, { brief: "b".repeat(2000) }).verdict, "ok");
});

test("requests.mjs: a NUL byte in the text is rejected as a NUL", () => {
  refused(check(ANSWER, { text: "a\u0000b" }), "the request holds a NUL byte");
  refused(validateRequest(text({ ...ANSWER, "k\u0000": 1 }), ctx()), "the request holds a NUL byte");
});

test("requests.mjs: unparsable text waits at 5 s and is rejected at 11 s", () => {
  assert.equal(validateRequest("{\"v\":1,", ctx({ ageSeconds: 5 })).verdict, "wait");
  assert.equal(validateRequest("{\"v\":1,", ctx({ ageSeconds: -3 })).verdict, "wait");
  refused(validateRequest("{\"v\":1,", ctx({ ageSeconds: 11 })), "the request is not JSON (still unparsable after 10 s)");
});

test("requests.mjs: the backup window holds 03:15:00 and 04:29:59 local, not 03:14:59 or 04:30:00", () => {
  const at = (h, m, s) => inBackupWindow(new Date(2026, 9, 28, h, m, s));
  assert.equal(at(3, 15, 0), true);
  assert.equal(at(4, 29, 59), true);
  assert.equal(at(3, 14, 59), false);
  assert.equal(at(4, 30, 0), false);
  assert.equal(BACKUP_REFUSAL, "backup window 03:15–04:30: queued, runner not started");
});

test("requests.mjs: resultJson has the contract's ten keys in order and cuts output at 2000 bytes on a character boundary", () => {
  const r = resultJson({ id: "req-0001-aaaa", verb: "answer", run: "parked", ok: true, exit: 0, output: "fine",
    runnerStarted: false, refused: null, now: Date.UTC(2026, 9, 28) / 1000 });
  assert.equal(Object.keys(r).join(","), "v,id,at,verb,run,ok,exit,output,runner_started,refused");
  assert.equal(r.v, 1);
  assert.equal(r.at, "2026-10-28T00:00:00.000Z");
  assert.equal(r.output, "fine");
  assert.equal(r.runner_started, false);
  assert.equal(r.refused, null);
  const long = resultJson({ id: "req-0001-aaaa", output: `${"a".repeat(1999)}é tail`, now: 0 });
  assert.equal(Buffer.byteLength(long.output), 1999);   // é is two bytes: 2001 would split it
  assert.ok(!long.output.includes("�"));
  assert.equal(Buffer.byteLength(resultJson({ id: "req-0001-aaaa", output: "a".repeat(5000), now: 0 }).output), 2000);
  const nil = resultJson({ id: "req-0001-aaaa", now: 0 });
  assert.equal([nil.verb, nil.run, nil.ok, nil.exit, nil.output, nil.runner_started].map(String).join(","), "null,null,false,null,,false");
});

test("requests.mjs: resultName is the id, else the file name when it passes the id rule, else none", () => {
  assert.equal(resultName({ id: "req-0001-aaaa" }, "other-name.json"), "req-0001-aaaa");
  assert.equal(resultName({ id: null }, "req-0009-zzzz.json"), "req-0009-zzzz");
  assert.equal(resultName({ id: null }, "bad.name.json"), null);
  assert.equal(resultName({ id: null }, "short.json"), null);
});

test("requests.mjs: logLine names id, verb, run, the status and exit and never the text", () => {
  const now = new Date(2026, 9, 28, 0, 0, 0).getTime() / 1000;
  assert.equal(logLine({ now, name: "req-0001-aaaa", verb: "answer", run: "parked", ok: true, exit: 0 }),
    "2026-10-28 00:00:00 id=req-0001-aaaa verb=answer run=parked ok exit=0");
  assert.equal(logLine({ now, name: "req-0002-bbbb", verb: "continue", run: "stopped", ok: true, exit: 0, runnerStarted: true }),
    "2026-10-28 00:00:00 id=req-0002-bbbb verb=continue run=stopped ok exit=0 runner=started");
  assert.equal(logLine({ now, name: "req-0003-cccc", verb: "continue", run: "stopped", ok: true, exit: 0, refused: BACKUP_REFUSAL }),
    `2026-10-28 00:00:00 id=req-0003-cccc verb=continue run=stopped ok exit=0 why=${BACKUP_REFUSAL}`);
  assert.equal(logLine({ now, name: "req-0004-dddd", ok: false, exit: null, refused: "verb is not answer or continue" }),
    "2026-10-28 00:00:00 id=req-0004-dddd verb=- run=- refused exit=- why=verb is not answer or continue");
  assert.equal(logLine({ now, name: null, verb: "answer", run: "parked", ok: false, exit: 3 }),
    "2026-10-28 00:00:00 id=- verb=answer run=parked failed exit=3");
  const line = logLine({ now, name: "req-0001-aaaa", verb: "answer", run: "parked", ok: true, exit: 0, text: "rm -rf /", brief: "rm -rf /" });
  assert.ok(!line.includes("rm -rf"), line);
  assert.ok(!line.includes("\n"), line);
});

test("requests.mjs: the validate CLI prints labelled lines and writes text and brief byte for byte", () => {
  const T = mkdtempSync(join(tmpdir(), "requests-"));
  try {
    const t = "it's `x` $(rm -rf /) \"q\"\nline two\n\n";
    const file = join(T, "req-0001-aaaa.json"), done = join(T, "done"), out = join(T, "out");
    mkdirSync(done); mkdirSync(out);
    writeFileSync(file, text(ANSWER, { text: t }));
    const mtime = 1_800_000_000;
    utimesSync(file, mtime, mtime);
    writeFileSync(join(done, "req-0002-bbbb.request.json"), "{}\n");   // a claim counts as done
    const at3 = Math.floor(new Date(2026, 9, 28, 3, 30, 0).getTime() / 1000);
    const r = cli("requests.mjs", ["validate", file, "--runs", "parked,stopped", "--done", done, "--now", String(at3), "--out", out]);
    assert.equal(r.rc, 0);
    assert.equal(r.out, "verdict ok\nname req-0001-aaaa\nid req-0001-aaaa\nverb answer\nrun parked\nwindow 1\n");
    assert.equal(readFileSync(join(out, "text"), "utf8"), t);
    assert.equal(existsSync(join(out, "brief")), false);
    const dup = join(T, "dup.json");
    writeFileSync(dup, text(CONTINUE));
    utimesSync(dup, mtime, mtime);
    const d = cli("requests.mjs", ["validate", dup, "--runs", "parked,stopped", "--done", done, "--now", String(mtime + 1), "--out", out]);
    assert.equal(d.out, "verdict duplicate\nname req-0002-bbbb\nid req-0002-bbbb\nverb -\nrun -\nwindow 0\nreason duplicate id: done/req-0002-bbbb.json already exists\n");
    assert.equal(cli("requests.mjs", ["validate"]).rc, 2);
  } finally { rmSync(T, { recursive: true, force: true }); }
});

test("requests.mjs: the result CLI prints the result JSON and appends its log line, and none for a missing name", () => {
  const T = mkdtempSync(join(tmpdir(), "requests-"));
  try {
    const log = join(T, "requests.log"), output = join(T, "out.txt"), now = Date.UTC(2026, 9, 28) / 1000;
    writeFileSync(output, "queued stopped\nqueue runner started (tmux h-queue)\n");
    const r = cli("requests.mjs", ["result", "--id", "req-0002-bbbb", "--verb", "continue", "--run", "stopped", "--ok", "1",
      "--exit", "0", "--output", output, "--runner-started", "1", "--now", String(now), "--log", log]);
    assert.equal(r.rc, 0);
    const j = JSON.parse(r.out);
    assert.equal(r.out.split("\n").length, 2);
    assert.equal([j.id, j.verb, j.run, j.ok, j.exit, j.runner_started, j.refused].map(String).join(","), "req-0002-bbbb,continue,stopped,true,0,true,null");
    assert.equal(j.output, "queued stopped\nqueue runner started (tmux h-queue)\n");
    const n = cli("requests.mjs", ["result", "--id", "-", "--verb", "-", "--run", "-", "--ok", "0", "--exit", "-",
      "--runner-started", "0", "--refused", "id does not match ^[A-Za-z0-9-]{8,64}$", "--now", String(now), "--log", log]);
    assert.equal(n.rc, 0);
    assert.equal(n.out, "");
    const lines = readFileSync(log, "utf8").split("\n");
    assert.equal(lines.length, 3);
    assert.match(lines[0], / id=req-0002-bbbb verb=continue run=stopped ok exit=0 runner=started$/);
    assert.match(lines[1], / id=- verb=- run=- refused exit=- why=id does not match/);
  } finally { rmSync(T, { recursive: true, force: true }); }
});

test("requests.mjs: the validate CLI rejects a symlink unread, whatever it points at", () => {
  const T = mkdtempSync(join(tmpdir(), "requests-"));
  try {
    const target = join(T, "target.json"), link = join(T, "link-0001-aaaa.json"), done = join(T, "done"), out = join(T, "out");
    mkdirSync(done); mkdirSync(out);
    writeFileSync(target, text(ANSWER, { id: "link-0001-aaaa" }));
    symlinkSync(target, link);
    const r = cli("requests.mjs", ["validate", link, "--runs", "parked", "--done", done, "--now", "1800000000", "--out", out]);
    assert.equal(r.rc, 0);
    assert.equal(r.out, "verdict rejected\nname link-0001-aaaa\nid -\nverb -\nrun -\nwindow 0\nreason the request is not a regular file\n");
    assert.equal(existsSync(join(out, "text")), false);
  } finally { rmSync(T, { recursive: true, force: true }); }
});

test("requests.mjs: the result CLI's --backup-window 1 gives the backup refusal", () => {
  const T = mkdtempSync(join(tmpdir(), "requests-"));
  try {
    const log = join(T, "requests.log"), now = Date.UTC(2026, 9, 28, 3, 30) / 1000;
    const r = cli("requests.mjs", ["result", "--id", "req-0004-dddd", "--verb", "continue", "--run", "stopped", "--ok", "1",
      "--exit", "0", "--runner-started", "0", "--backup-window", "1", "--now", String(now), "--log", log]);
    assert.equal(r.rc, 0);
    assert.equal(JSON.parse(r.out).refused, BACKUP_REFUSAL);
    assert.match(readFileSync(log, "utf8"), new RegExp(` why=${BACKUP_REFUSAL}\n$`));
  } finally { rmSync(T, { recursive: true, force: true }); }
});
