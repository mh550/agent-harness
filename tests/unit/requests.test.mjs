// lib/requests.mjs: the request inbox's rules (v1 and v2): validation, the backup window, the result JSON and the log line.   node --test tests/unit/requests.test.mjs
import { test } from "node:test";
import assert from "node:assert/strict";
import { existsSync, mkdirSync, mkdtempSync, readFileSync, rmSync, symlinkSync, utimesSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";
import { cli } from "./cli-same.mjs";
import { BACKUP_REFUSAL, declineItems, inBackupWindow, logLine, resultJson, resultName, validateRequest } from "../../lib/requests.mjs";

// the requests n8n-home's own buildRequest wrote (tests/fixtures/requests/README.md): every shape here is one of them
const FX = fileURLToPath(new URL("../fixtures/requests/", import.meta.url));
const fx = n => JSON.parse(readFileSync(join(FX, `${n}.json`), "utf8"));
const ANSWER = fx("answer"), CONTINUE = fx("continue"), BRIEF = fx("continue-brief");
// v2 (V2-01): the card's merge and close, made by the README's make-v2.mjs (n8n-home's buildRequest has no v2 yet)
const MERGE = fx("merge"), CLOSE = fx("close"), CLOSE_WHY = fx("close-why");
// ledger/memory.jsonl's rows as validate reads them: run r1's facts and rules PRs, and one of another run
const FACTS_PR = "https://example.test/pr/1", RULES_PR = "https://example.test/pr/2", OTHER_PR = "https://example.test/pr/3";
const LEDGER = [{ run: "r1", project: "p", tier: "facts", url: FACTS_PR, review: "ok" }, { run: "r1", project: "p", tier: "rules", url: RULES_PR, review: "ok" },
  { run: "r2", project: "p", tier: "facts", url: OTHER_PR, review: "ok" }];
const text = (base, change = {}) => `${JSON.stringify({ ...base, ...change })}\n`;
const RUNS = new Set(["parked", "stopped", "x", "r1", "r2"]);
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

test("requests.mjs: v 2 with answer is rejected, v 3 is not 1 or 2", () => {
  refused(check(ANSWER, { v: 2 }), "v 2 carries merge or close");
  refused(check(ANSWER, { v: 3 }), "v is not 1 or 2");
  refused(check(ANSWER, { v: "1" }), "v is not 1 or 2");
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
  const r = check(ANSWER, { verb: "merge" });   // v 1: merge is v 2's
  assert.equal(check(MERGE, { v: 1 }, { memory: LEDGER }).reason, "verb is not answer or continue");
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

// ---- v2 (V2-01, docs/specs/2026-11-10-review-surface.md): merge and close on a memory PR the ledger knows ----
const v2 = (base, change, o) => check(base, change, { memory: LEDGER, ...o });

test("requests.mjs: a v2 merge and close on a known PR of the request's run are ok with pr, and the close's why", () => {
  const m = v2(MERGE);
  assert.equal([m.verdict, m.id, m.verb, m.run, m.pr, m.why, m.text, m.review].map(String).join(","), `ok,${MERGE.id},merge,r1,${FACTS_PR},null,null,ok`);
  const c = v2(CLOSE);
  assert.equal([c.verdict, c.verb, c.pr, c.why, c.text].map(String).join(","), `ok,close,${RULES_PR},null,null`);
  const w = v2(CLOSE_WHY);
  assert.equal([w.verdict, w.pr, w.why].join(","), `ok,${FACTS_PR},${CLOSE_WHY.why}`);
  assert.equal(v2(CLOSE_WHY, { why: "" }).why, null, "an empty why is none");
  assert.equal(v2(CLOSE_WHY, { why: "w".repeat(300) }).verdict, "ok");
  // the row's review is the request's to carry: requests.sh refuses a merge of an unreviewed PR (V2-02)
  assert.equal(v2(MERGE, {}, { memory: [{ ...LEDGER[0], review: "nothing to review" }] }).review, "nothing to review");
  assert.equal(v2(MERGE, {}, { memory: [{ ...LEDGER[0], review: undefined }] }).review, null);
});

test("requests.mjs: a v2 pr no ledger row has, or of another run, is refused naming the PR", () => {
  refused(v2(MERGE, { pr: "https://example.test/pr/9" }), "pr https://example.test/pr/9 is not a memory PR the ledger knows (ledger/memory.jsonl)");
  refused(v2(MERGE, {}, { memory: [] }), `pr ${FACTS_PR} is not a memory PR the ledger knows (ledger/memory.jsonl)`);
  refused(v2(CLOSE, { pr: OTHER_PR }), `pr ${OTHER_PR} belongs to run r2, not r1`);
  // a ledger row whose run fails the run rule (a hand edit) is never quoted
  refused(v2(CLOSE, {}, { memory: [{ ...LEDGER[1], run: "x y\nz" }] }), `pr ${RULES_PR} belongs to another run, not r1`);
  refused(v2(CLOSE, {}, { memory: [{ ...LEDGER[1], run: undefined }] }), `pr ${RULES_PR} belongs to another run, not r1`);
  // a pr that is no URL is never quoted (a reason never holds a value that failed its rule)
  for (const pr of [7, "", "ftp://x/1", "https://example.test/pr/1 x", "https://example.test/pr/1\nwhy=x", `https://example.test/${"a".repeat(300)}`]) {
    const r = v2(MERGE, { pr });
    refused(r, "pr is not a PR URL (https://<host>/<path>, at most 200 characters)");
    assert.equal(r.pr, null);
  }
});

test("requests.mjs: a v2 why of two lines or 301 characters, a blank one and any why on a merge are refused, the reason never quoting it", () => {
  const bad = "why must be one line of at most 300 characters";
  for (const why of ["first\nsecond", "w".repeat(301), "   ", 7, "a\u2028b", "a\u0085b", "a\u001b[2Jb", "a\tb"]) {
    const r = v2(CLOSE_WHY, { why });
    refused(r, bad);
    assert.equal(r.why, null);
  }
  refused(v2(MERGE, { why: "merged anyway" }), "a merge takes no why");
  const secret = "SECRET-WHY-TEXT";
  for (const r of [v2(CLOSE_WHY, { why: `${secret}\n` }), v2(MERGE, { why: secret }), v2(CLOSE_WHY, { why: secret.repeat(30) })])
    assert.ok(!String(r.reason).includes(secret), r.reason);
});

test("requests.mjs: a v2 request passes v1's id, NUL, grace and duplicate rules", () => {
  refused(v2(MERGE, { id: "short" }), "id does not match ^[A-Za-z0-9-]{8,64}$");
  refused(v2(CLOSE_WHY, { why: "a\u0000b" }), "the request holds a NUL byte");
  refused(v2(MERGE, { run: "nosuch" }), "no run 'nosuch' (see: harness status)");
  assert.equal(validateRequest("{\"v\":2,", ctx({ ageSeconds: 5, memory: LEDGER })).verdict, "wait");
  const d = v2(MERGE, {}, { done: new Set([MERGE.id]) });
  assert.equal(`${d.verdict} ${d.reason}`, `duplicate duplicate id: done/${MERGE.id}.json already exists`);
});

test("requests.mjs: resultJson for a v2 request has twelve keys, v 2, pr and state, runner_started false, a v1 result its ten; logLine carries pr= after run= and never the why", () => {
  const r = resultJson({ v: 2, id: MERGE.id, verb: "merge", run: "r1", ok: true, exit: 0, output: "merged", runnerStarted: true, pr: FACTS_PR, state: "merged", now: 0 });
  assert.equal(Object.keys(r).join(","), "v,id,at,verb,run,ok,exit,output,runner_started,refused,pr,state");
  assert.equal([r.v, r.runner_started, r.pr, r.state].join(","), `2,false,${FACTS_PR},merged`);
  const n = resultJson({ v: 2, id: MERGE.id, now: 0 });
  assert.equal([n.pr, n.state].map(String).join(","), "null,null");
  assert.equal(Object.keys(resultJson({ id: MERGE.id, pr: FACTS_PR, state: "merged", now: 0 })).length, 10);
  const now = new Date(2026, 10, 10, 0, 0, 0).getTime() / 1000;
  assert.equal(logLine({ now, name: MERGE.id, verb: "merge", run: "r1", pr: FACTS_PR, ok: true, exit: 0 }),
    `2026-11-10 00:00:00 id=${MERGE.id} verb=merge run=r1 pr=${FACTS_PR} ok exit=0`);
  assert.equal(logLine({ now, name: MERGE.id, verb: "-", run: null, pr: null, ok: false, exit: null, refused: "v 2 carries merge or close" }),
    `2026-11-10 00:00:00 id=${MERGE.id} verb=- run=- pr=- refused exit=- why=v 2 carries merge or close`);
  const line = logLine({ now, name: CLOSE_WHY.id, verb: "close", run: "r1", pr: FACTS_PR, ok: true, exit: 0, why: CLOSE_WHY.why });
  assert.ok(!line.includes(CLOSE_WHY.why), line);
});

test("requests.mjs: the validate CLI takes --memory and prints pr, review and why as labelled lines, the why to --out's why file; the result CLI's --pr and --state give the v2 result", () => {
  const T = mkdtempSync(join(tmpdir(), "requests-"));
  try {
    const done = join(T, "done"), out = join(T, "out"), mem = join(T, "memory.jsonl"), mtime = 1_800_000_000;
    mkdirSync(done); mkdirSync(out);
    writeFileSync(mem, `${LEDGER.map(r => JSON.stringify(r)).join("\n")}\n`);
    const why = "it's `x` $(rm -rf /) \"q\"";
    const put = (n, base, change = {}) => { const f = join(T, `${n}.json`); writeFileSync(f, text(base, change)); utimesSync(f, mtime, mtime); return f; };
    const run = (f, more = ["--memory", mem]) => cli("requests.mjs", ["validate", f, "--runs", "r1,r2", "--done", done, "--now", String(mtime + 30), "--out", out, ...more]);
    const c = run(put("c", CLOSE_WHY, { why }));
    assert.equal(c.rc, 0);
    assert.equal(c.out, `verdict ok\nname ${CLOSE_WHY.id}\nid ${CLOSE_WHY.id}\nverb close\nrun r1\npr ${FACTS_PR}\nreview ok\nwhy 1\nwindow 0\n`);
    assert.equal(readFileSync(join(out, "why"), "utf8"), why);
    assert.ok(!c.out.includes("rm -rf"), "the why is never on stdout");
    rmSync(join(out, "why"));
    const m = run(put("m", MERGE));
    assert.equal(m.out, `verdict ok\nname ${MERGE.id}\nid ${MERGE.id}\nverb merge\nrun r1\npr ${FACTS_PR}\nreview ok\nwhy 0\nwindow 0\n`);
    assert.equal(existsSync(join(out, "why")), false);
    const u = run(put("u", MERGE), []);   // no --memory: no row is known
    assert.equal(u.out, `verdict rejected\nname ${MERGE.id}\nid ${MERGE.id}\nverb merge\nrun r1\npr -\nreview -\nwhy 0\nwindow 0\nreason pr ${FACTS_PR} is not a memory PR the ledger knows (ledger/memory.jsonl)\n`);
    // the result CLI with --pr and --state: the v2 result and its log line's pr=
    const log = join(T, "requests.log"), output = join(T, "out.txt"), now = Date.UTC(2026, 10, 10) / 1000;
    writeFileSync(output, "");
    const r = cli("requests.mjs", ["result", "--id", MERGE.id, "--verb", "merge", "--run", "r1", "--ok", "1", "--exit", "0", "--output", output,
      "--runner-started", "0", "--pr", FACTS_PR, "--state", "merged", "--now", String(now), "--log", log]);
    assert.equal(r.rc, 0);
    // the result fixture is this run's stdout (tests/fixtures/requests/README.md)
    assert.equal(r.out, readFileSync(join(FX, "result-v2.json"), "utf8"));
    assert.match(readFileSync(log, "utf8"), new RegExp(` id=${MERGE.id} verb=merge run=r1 pr=${FACTS_PR} ok exit=0\n$`));
    const n = cli("requests.mjs", ["result", "--id", MERGE.id, "--verb", "-", "--run", "-", "--ok", "0", "--exit", "-", "--runner-started", "0",
      "--pr", "-", "--refused", "v 2 carries merge or close", "--now", String(now), "--log", log]);
    assert.equal([JSON.parse(n.out).v, JSON.parse(n.out).pr, JSON.parse(n.out).state].map(String).join(","), "2,null,null");
    assert.equal(cli("requests.mjs", ["result", "--id", MERGE.id, "--ok", "1", "--pr", FACTS_PR, "--state", "open", "--now", String(now), "--log", log]).rc, 2);
  } finally { rmSync(T, { recursive: true, force: true }); }
});

test("requests.mjs: merge.json, close.json and close-why.json are the README's make-v2.mjs bytes, keys v,id,at,verb,run,pr[,why],source,event", () => {
  const T = mkdtempSync(join(tmpdir(), "requests-"));
  try {
    const readme = readFileSync(join(FX, "README.md"), "utf8"), code = /```js\n(\/\/ node make-v2\.mjs <out>\n[\s\S]*?)```/.exec(readme)?.[1];
    assert.ok(code, "README.md holds the make-v2.mjs block");
    writeFileSync(join(T, "make-v2.mjs"), code);
    mkdirSync(join(T, "out"));
    const r = spawnSync(process.execPath, [join(T, "make-v2.mjs"), join(T, "out")], { encoding: "utf8" });
    assert.equal(r.status, 0, r.stderr);
    for (const n of ["merge", "close", "close-why"]) {
      assert.equal(readFileSync(join(T, "out", `${n}.json`), "utf8") === readFileSync(join(FX, `${n}.json`), "utf8"), true, n);
      assert.equal(Object.keys(fx(n)).join(","), n === "close-why" ? "v,id,at,verb,run,pr,why,source,event" : "v,id,at,verb,run,pr,source,event", n);
    }
  } finally { rmSync(T, { recursive: true, force: true }); }
});

test("requests.mjs: declineItems gives the run for a closed facts PR and <run>/<n> per rules/<n> for a closed rules PR, a why when the result has none", () => {
  // memory-result.json's shape as curator.mjs apply writes it: rules[] then proposed[], numbered in one series
  const result = { rules: [{ op: "add", tier: 2, n: 1 }, { op: "add", tier: 2, n: 2 }], proposed: [{ op: "add", tier: 3, n: 3 }] };
  assert.equal(JSON.stringify(declineItems(LEDGER[0], result)), JSON.stringify({ items: ["r1"] }));
  assert.equal(JSON.stringify(declineItems(LEDGER[0], null)), JSON.stringify({ items: ["r1"] }));
  assert.equal(JSON.stringify(declineItems({ run: "r1", url: FACTS_PR }, null)), JSON.stringify({ items: ["r1"] }));   // a row before N1-01: facts
  assert.equal(JSON.stringify(declineItems(LEDGER[1], result)), JSON.stringify({ items: ["r1/1", "r1/2"] }));
  assert.equal(declineItems(LEDGER[1], null).why, "no memory-result.json for r1 in the ledger yet");
  assert.equal(declineItems(LEDGER[1], { rules: [], proposed: [{ n: 1 }] }).why, "r1's memory-result.json has no numbered rules");
});
