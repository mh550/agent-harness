// lib/inbox.mjs: the INBOX.md parser (## Answers outside the steering comment), question, added, insert and repair.   node --test tests/unit/inbox.test.mjs
import { test } from "node:test";
import assert from "node:assert/strict";
import { mkdirSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { sameAsCli, cli, mainOf } from "./cli-same.mjs";
import * as I from "../../lib/inbox.mjs";

// n8n-home's INBOX.md at 4632d1c, byte for byte (tests/checks/inbox.sh checks its bytes)
const fx = readFileSync(new URL("../fixtures/inbox-q-in-comment.md", import.meta.url), "utf8");
// lib/driver.sh's INBOX.md heredoc for branch harness/r, read from the driver as inbox.sh's tpl.md is (its awk)
const drv = readFileSync(new URL("../../lib/driver.sh", import.meta.url), "utf8"), heredoc = 'cat > "$REC/INBOX.md" <<EOF\n';
const tpl = (i => drv.slice(i, drv.indexOf("\nEOF\n", i) + 1))(drv.indexOf(heredoc) + heredoc.length).replace("$BRANCH", "harness/r");
// the template with a question planted mid-line in its comment, n8n-home's shape (inbox.sh's planted.md)
const Q1 = "**Q1 (A, stub).** set the gatus vars, then answer";
const planted = (i => tpl.slice(0, i) + "## Questions\n\n" + Q1 + "\n\n" + tpl.slice(i))(tpl.indexOf("under ") + 6);

test("inbox.mjs: answersLine skips the comment (27 on the fixture, not 12), allows trailing blanks, and an unclosed comment runs to the end", () => {
  assert.equal(I.answersLine(fx), 27);
  assert.equal(I.answersLine("a\n## Answers \t\nb"), 1);
  assert.equal(I.answersLine("## Answers\".\n## Answersx"), -1);
  assert.equal(I.answersLine("a\n<!-- x\n## Answers\n"), -1);
  assert.equal(I.answersLine("<!-- x --> y\n## Answers"), 1);
});

test("inbox.mjs: question(fixture, B1-05) is Q2, cut at the real heading, no comment in it", () => {
  const q = I.question(fx, "B1-05");
  assert.match(q, /^\*\*Q2 \(B1-05/);
  assert.doesNotMatch(q, /<!--/);
  assert.ok(q.endsWith("newer live-staged rule. Say so if the brief should win."), q.slice(-80));
});

test("inbox.mjs: added() on a session that wrote inside the comment returns that question (and only it)", () => {
  assert.equal(I.added(tpl, planted), "## Questions\n\n" + Q1);
});

test("inbox.mjs repair: n8n-home's fixture against its template keeps Q2 and moves Q1 above ## Answers, out of the comment", () => {
  const l = fx.split("\n");
  const before = [...l.slice(0, 2), "     Change the first line to \"status: pause\" or \"status: stop\"; write answers to questions under \"## Answers\".", ...l.slice(13)].join("\n");
  const { text, changed } = I.repair(before, fx), t = text.split("\n"), a = I.answersLine(text);
  const q1 = t.findIndex(x => x.startsWith("**Q1 (B1-01")), q2 = t.findIndex(x => x.startsWith("**Q2 (B1-05"));
  assert.equal(changed, true);
  assert.equal(text.slice(0, text.indexOf("-->")), before.slice(0, before.indexOf("-->")));
  assert.ok(q2 > 0 && q2 < q1 && q1 < a, `q2 ${q2}, q1 ${q1}, ## Answers ${a}`);
  assert.equal(t[a - 1], "");
  assert.match(I.question(text, "B1-01"), /\(recommended\)/);
  assert.match(I.added(before, fx), /^## Questions/);
  assert.equal(I.answers(text), I.answers(fx));
});

test("inbox.mjs: insert() puts the question and a blank line above ## Answers (appended without one); questionLine and files", () => {
  assert.equal(I.insert(tpl, "Q?"), tpl.replace("## Answers", "Q?\n\n## Answers"));
  assert.equal(I.insert("status: run\n", "Q?"), "status: run\n\nQ?\n");
  assert.equal(I.questionLine(fx, "B1-05"), 16);
  assert.equal(I.questionLine(fx, "nope"), 16);
  assert.equal(I.questionLine("## Answers\n", "A"), null);
  const f = I.files("x\nFiles: /a/b.sh:48, /a/c.md\nFiles (harness, from the session): /d.txt");
  assert.deepEqual(f, [{ path: "/a/b.sh", line: 48 }, { path: "/a/c.md", line: null }, { path: "/d.txt", line: null }]);
  assert.deepEqual(f.map(x => Object.keys(x).join()), ["path,line", "path,line", "path,line"]);
});

// U2-02's review: a never-split INBOX with a lone <!-- in a question and no final newline. answers() below is sed's
// cut of it (`sed -n '/^## Answers/,$p'`, byte for byte); the CLI adds nothing to answers(): main's test at the end
const lone = "status: run\n<!-- Steer this run -->\n\n### A: does the `<!--` marker in index.html matter?\n\n## Answers\n\n### 2026-10-27 10:00 (local)\nno";

test("inbox.mjs review: a lone <!-- in a question hides nothing; answers() equals sed on it (no final newline); a CRLF heading counts", () => {
  assert.equal(I.answersLine(lone), 5);
  assert.equal(I.answers(lone), "## Answers\n\n### 2026-10-27 10:00 (local)\nno");
  assert.ok(I.question(lone, "A").endsWith("matter?"), I.question(lone, "A"));
  assert.equal(I.answersLine("a\r\n## Answers\r\nb"), 1);
  assert.equal(I.answersLine("a\n<!-- x\n## Answers\n"), -1);
  assert.equal(I.answersLine("a <!-- x --> b\n## Answers"), 1);
});

test("inbox.mjs review: a --> inside the moved question, a word-aligned insertion, a reworded comment, a comment of the session's own", () => {
  const at = (t, w, x) => { const i = t.indexOf(w) + w.length; return t.slice(0, i) + x + t.slice(i); };
  const cmt = t => t.slice(t.indexOf("<!-- Steer"), t.indexOf("-->", t.indexOf("<!-- Steer")) + 3);
  const q = "### A: does `a --> b` mean b depends on a?", r1 = I.repair(tpl, at(tpl, "under ", "\n\n" + q + "\n\n"));
  const r2 = I.repair(tpl, at(tpl, "at the end", " (Q for A: should the deploy wait until it the end"));
  const r3 = I.repair(tpl, tpl.replace("from the GitHub app", "from GitHub")), own = "<!-- A: a note of my own -->\n";
  const r4 = I.repair(tpl, tpl.replace("<!-- Steer", own + "<!-- Steer")), r5 = I.repair(tpl, tpl.replace(cmt(tpl), "### A: which port? <!-- tried 80 -->"));
  assert.equal(r1.moved, q);
  assert.equal(cmt(r1.text), cmt(tpl));
  assert.equal(r1.text.split("-->").length, 3);
  assert.ok(I.answersLine(r1.text) > r1.text.split("\n").indexOf(q), r1.text);
  assert.equal(r2.moved, "(Q for A: should the deploy wait until it the end");
  assert.equal(r3.changed, false);
  assert.equal(I.added(tpl, tpl.replace("from the GitHub app", "from GitHub")), "");
  assert.equal(r4.changed, false);
  assert.equal(r5.changed, false);
});

test("needs review: a ## Answers heading with words after it (## Answers (Michael)) is the heading; ## Answersheet is not", () => {
  assert.equal(I.answers("status: run\n\nQ1?\n\n## Answers (Michael)\nyes\n"), "## Answers (Michael)\nyes\n");
  assert.ok(I.answersLine("## Answersheet\n") < 0, String(I.answersLine("## Answersheet\n")));
});

test("needs review: a short reword inside the steering comment (not a question) stays there, unmoved", () => {
  const b = "status: run\n<!-- Steer this run from the app. -->\n\n## Answers\n", a = b.replace("Steer this", "Steer not this");
  const r = I.repair(b, a);
  assert.equal(r.changed, false);
  assert.equal(r.text, a);
});

// ---- main(argv, io): the CLI's bytes and exit code; stdin only from io (decisions/2026-11-03-resident-helper) ----
const inTmpInbox = async fn => { const d = mkdtempSync(join(tmpdir(), "ib-")); try { return await fn(d); } finally { rmSync(d, { recursive: true, force: true }); } };

test("inbox.mjs: main gives the CLI's bytes for answers (no newline added), question and repair", () => inTmpInbox(async d => {
  const f = join(d, "INBOX.md"), base = join(d, "base.md");
  writeFileSync(f, "status: run\n\n## Answers\nyes, no trailing newline");
  assert.equal((await sameAsCli("inbox.mjs", ["answers", f])).out.endsWith("newline"), true);
  await sameAsCli("inbox.mjs", ["answers", join(d, "missing")]);
  writeFileSync(base, "status: run\n\n## Answers\n");
  writeFileSync(f, "status: run\n\n### H1: a question\nwhy\n\n## Answers\n");
  assert.notEqual((await sameAsCli("inbox.mjs", ["question", base, f])).out, "");
  const c = join(d, "c.md"), m = join(d, "m.md");
  writeFileSync(c, "x\n"); writeFileSync(m, "x\n");
  assert.deepEqual(await mainOf("inbox.mjs", ["repair", f, m]), cli("inbox.mjs", ["repair", f, c]));
  assert.equal(readFileSync(m, "utf8"), readFileSync(c, "utf8"));
}));

test("inbox.mjs: main's insert takes stdin from io and leaves the file the CLI leaves", () => inTmpInbox(async d => {
  const c = join(d, "c.md"), m = join(d, "m.md"), q = "### A1: asks\nwhat?\n\n";
  writeFileSync(c, "status: run\n\n## Answers\n"); writeFileSync(m, "status: run\n\n## Answers\n");
  assert.deepEqual(await mainOf("inbox.mjs", ["insert", m], { input: q }), { rc: 0, out: "" });
  assert.deepEqual(cli("inbox.mjs", ["insert", c], { input: q }), { rc: 0, out: "" });
  assert.equal(readFileSync(m, "utf8"), readFileSync(c, "utf8"));
  assert.match(readFileSync(m, "utf8"), /what\?/);
}));

test("inbox.mjs: main's insert with an io that has no stdin throws without reading fd 0", () => inTmpInbox(async d => {
  const f = join(d, "f.md"), { main } = await import("../../lib/inbox.mjs");
  writeFileSync(f, "x\n");
  assert.throws(() => main(["insert", f], { cwd: d }), /no stdin/);
  assert.equal(readFileSync(f, "utf8"), "x\n");
}));

test("inbox.mjs repair: the comment back byte for byte, the question directly above ## Answers; exit 3, then 0", () => inTmpInbox(async d => {
  const b = join(d, "tpl.md"), f = join(d, "rep.md"), same = join(d, "same.md");
  writeFileSync(b, tpl); writeFileSync(f, planted); writeFileSync(same, tpl);
  assert.equal(cli("inbox.mjs", ["repair", b, f]).rc, 3);
  const once = readFileSync(f, "utf8"), ls = once.split("\n"), comment = t => t.slice(t.indexOf("<!--"), t.indexOf("-->") + 3);
  assert.equal(comment(once), comment(tpl));
  assert.equal(ls.lastIndexOf("## Answers"), ls.lastIndexOf(Q1) + 2);
  assert.equal(cli("inbox.mjs", ["repair", b, f]).rc, 0);
  assert.equal(readFileSync(f, "utf8"), once);
  assert.equal(cli("inbox.mjs", ["repair", b, same]).rc, 0);
  assert.equal(readFileSync(same, "utf8"), tpl);
}));

// ---- the status line: control, stop_why and harness continue read it one way ----
test("inbox.mjs: status of a first-line status: stop is stop", () => assert.equal(I.status("status: stop\n\n## Answers\n"), "stop"));
test("inbox.mjs: status drops the spaces and tabs after the colon", () => {
  assert.equal(I.status("status:   pause\n"), "pause");
  assert.equal(I.status("status:\t pause now\n"), "pause now");
  assert.equal(I.status("status:stop\n"), "stop");
});
test("inbox.mjs: status of a file with no status line, and of none, is empty", () => {
  assert.equal(I.status("# nothing\n\n## Answers\n"), "");
  assert.equal(I.status(" status: stop\n"), "");
  assert.equal(I.status(""), "");
});
test("inbox.mjs: status is the first status: line anywhere in the file, one under ## Answers too", () => {
  assert.equal(I.status("status: run\nstatus: stop\n"), "run");
  assert.equal(I.status("# x\n\n## Answers\nstatus: stop\nstatus: run\n"), "stop");
});
test("inbox.mjs: status keeps a CR at the line's end, and takes it as space with nothing before it", () => {
  assert.equal(I.status("status: stop\r\n"), "stop\r");
  assert.equal(I.status("status:\r\n"), "");
});
test("inbox.mjs: status keeps a no-break space after the colon ([[:space:]] isn't \\s)", () => assert.equal(I.status("status: stop\n"), " stop"));

const ctl = (stop, pause, status) => I.control({ stop, pause, status });
test("inbox.mjs: control is stop on the STOP file, whatever the line says", () => assert.equal(ctl(true, false, "run"), "stop"));
test("inbox.mjs: control is stop on a line starting stop: stop, stopped, stop with a why, a CR behind it", () => {
  for (const s of ["stop", "stopped", "stop - the spec changed", "stop\r"]) assert.equal(ctl(false, false, s), "stop", s);
});
test("inbox.mjs: control is pause on the PAUSE file or a line starting pause", () => {
  assert.equal(ctl(false, true, "run"), "pause");
  for (const s of ["pause", "paused"]) assert.equal(ctl(false, false, s), "pause", s);
});
test("inbox.mjs: control takes stop over pause, file or line", () => {
  assert.equal(ctl(true, true, ""), "stop");
  assert.equal(ctl(false, true, "stop"), "stop");
  assert.equal(ctl(true, false, "pause"), "stop");
});
test("inbox.mjs: control with no status line and no file is run, and any other word is too", () => {
  for (const s of ["", "run", "running", "resume", "Stop", " stop"]) assert.equal(ctl(false, false, s), "run", s);
});

const by = "stopped by Michael";
test("inbox.mjs: stopWhy gives STOP's line over the INBOX's (harness stop --why wins), its CR kept", () => {
  assert.equal(I.stopWhy("from the CLI", "stop: from the phone"), `${by}: from the CLI`);
  assert.equal(I.stopWhy("from the CLI\r", ""), `${by}: from the CLI\r`);
});
test("inbox.mjs: stopWhy on an empty STOP reads the status line's why", () => {
  assert.equal(I.stopWhy("", "stop: the spec changed"), `${by}: the spec changed`);
  assert.equal(I.stopWhy(null, "stop the spec changed"), `${by}: the spec changed`);
});
test("inbox.mjs: stopWhy of stop, stopped, stop - and no line gives none", () => {
  for (const s of ["stop", "stopped", "stop -", "stop - ", "stopped: because", "", "run: x"]) assert.equal(I.stopWhy(null, s), by, s);
});
test("inbox.mjs: stopWhy starts at the first letter or digit past the marks, and drops blanks at the end only", () => {
  assert.equal(I.stopWhy(null, "stop - the spec changed"), `${by}: the spec changed`);
  assert.equal(I.stopWhy(null, "stop -- 2 things -  "), `${by}: 2 things -`);
  assert.equal(I.stopWhy(null, "stop: x"), `${by}: x`);
});
test("inbox.mjs: stopWhy's first letter may be beyond ASCII (the driver's UTF-8 locale)", () => assert.equal(I.stopWhy(null, "stop: é tout"), `${by}: é tout`));
test("inbox.mjs: stopWhy keeps a no-break space at the why's end ([[:space:]] isn't \\s)", () => assert.equal(I.stopWhy(null, "stop: x "), `${by}: x `));
test("inbox.mjs: stopWhy cuts at 200 characters by code point, STOP's line and the INBOX's alike", () => {
  const astral = `a${"😀".repeat(300)}`, want = `${by}: a${"😀".repeat(199)}`;
  assert.equal(I.stopWhy(null, `stop: ${astral}`), want);
  assert.equal(I.stopWhy(astral, ""), want);
  assert.equal(I.stopWhy(null, `stop: ${"x".repeat(200)}`).length, by.length + 2 + 200);
});
test("inbox.mjs: stopWhy takes every CR out of the status line's why", () => {
  assert.equal(I.stopWhy(null, "stop: a\rb\r"), `${by}: ab`);
  assert.equal(I.stopWhy(null, "stop\r"), by);
});

test("inbox.mjs: unstop sets the first status: stop line back to status: run, the rest byte for byte", () => {
  const r = I.unstop("# top\nstatus: stop now\nstatus: stop\n\n## Answers\nyes");
  assert.equal(r.text, "# top\nstatus: run\nstatus: stop\n\n## Answers\nyes");
  assert.equal(r.was, "status: stop now");
});
test("inbox.mjs: unstop's was keeps the line's bytes, its spaces and CR", () => {
  const r = I.unstop("status:  stopped\r\nnext\n");
  assert.equal(r.text, "status: run\nnext\n");
  assert.equal(r.was, "status:  stopped\r");
});
test("inbox.mjs: unstop of a run or pause line, or of none, changes nothing", () => {
  for (const t of ["status: run\nstatus: stop\n", "status: pause\n", "# x\n", ""]) assert.deepEqual(I.unstop(t), { text: t, was: null }, t);
});

test("inbox.mjs: main gives the CLI's bytes for control and stop-why, reading the status line and the state's markers", () => inTmpInbox(async d => {
  const f = join(d, "INBOX.md"), st = join(d, "state");
  mkdirSync(st);
  writeFileSync(f, "status: pause\n\n## Answers\n");
  assert.equal((await sameAsCli("inbox.mjs", ["control", f, st])).out, "pause\n");
  writeFileSync(f, "status: stop - the spec changed\r\n");
  assert.equal((await sameAsCli("inbox.mjs", ["control", f, st])).out, "stop\n");
  assert.equal((await sameAsCli("inbox.mjs", ["stop-why", f, st])).out, "stopped by Michael: the spec changed\n");
  writeFileSync(join(st, "STOP"), "first\nsecond\n");
  assert.equal((await sameAsCli("inbox.mjs", ["stop-why", f, st])).out, "stopped by Michael: first\n");
  writeFileSync(f, "status: run\n");
  assert.equal((await sameAsCli("inbox.mjs", ["control", f, st])).out, "stop\n");
  rmSync(join(st, "STOP"));
  writeFileSync(join(st, "PAUSE"), "");
  assert.equal((await sameAsCli("inbox.mjs", ["control", f, st])).out, "pause\n");
  rmSync(join(st, "PAUSE"));
  assert.equal((await sameAsCli("inbox.mjs", ["control", join(d, "absent.md"), join(d, "absent")])).out, "run\n");
  assert.equal((await sameAsCli("inbox.mjs", ["stop-why", join(d, "absent.md"), join(d, "absent")])).out, "stopped by Michael\n");
}));
test("inbox.mjs: control counts STOP and PAUSE only as files, as [[ -f ]] does", () => inTmpInbox(async d => {
  mkdirSync(join(d, "STOP"));
  assert.equal((await sameAsCli("inbox.mjs", ["control", join(d, "absent.md"), d])).out, "run\n");
  assert.equal((await sameAsCli("inbox.mjs", ["stop-why", join(d, "absent.md"), d])).out, "stopped by Michael\n");
}));
test("inbox.mjs: main's unstop writes the file, prints the old line and exits 3, then changes nothing and exits 0", () => inTmpInbox(async d => {
  const f = join(d, "INBOX.md"), g = join(d, "same.md");
  writeFileSync(f, "status: stop\r\n\n## Answers\n");
  const r = await I.main(["unstop", f], {});
  assert.deepEqual([r.rc, r.out, readFileSync(f, "utf8")], [3, "status: stop\r\n", "status: run\n\n## Answers\n"]);
  assert.deepEqual(await I.main(["unstop", f], {}), { rc: 0, out: "" });
  assert.deepEqual(await I.main(["unstop", join(d, "absent.md")], {}), { rc: 0, out: "" });
  writeFileSync(f, "status: stop\n"); writeFileSync(g, "status: stop\n");
  const m = await mainOf("inbox.mjs", ["unstop", f]), c = cli("inbox.mjs", ["unstop", g]);
  assert.deepEqual([m.rc, m.out, readFileSync(f, "utf8")], [c.rc, c.out, readFileSync(g, "utf8")]);
}));

test("inbox.mjs: stopWhy: [[:alnum:]] as glibc has it, no fraction or superscript: stop ½ done gives done, stop, ³ none", () => {
  assert.equal(I.stopWhy("", "stop ½ done"), `${by}: done`);
  assert.equal(I.stopWhy("", "stop, ³"), by);
  assert.equal(I.stopWhy("", "stop: ٣ Ⅻ é"), `${by}: ٣ Ⅻ é`);
});
