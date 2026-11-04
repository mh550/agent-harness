// lib/inbox.mjs: the INBOX.md parser (## Answers outside the steering comment), question, added, insert and repair.   node --test tests/unit/inbox.test.mjs
import { test } from "node:test";
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import * as I from "../../lib/inbox.mjs";

// n8n-home's INBOX.md at 4632d1c, byte for byte (tests/checks/57-inbox.sh checks its bytes)
const fx = readFileSync(new URL("../fixtures/inbox-q-in-comment.md", import.meta.url), "utf8");
// lib/driver.sh's INBOX.md heredoc for branch harness/r, as 57-inbox.sh's tpl.md (its bash checks read the driver's own)
const tpl = `status: run
<!-- Steer this run from the GitHub app: edit this file on branch harness/r.
     Change the first line to "status: pause" or "status: stop"; write answers to questions under the Answers heading at the end
     of this file. The harness pulls before every session; every session reads this file at startup. -->

## Answers
`;
// the template with a question planted mid-line in its comment, n8n-home's shape (57-inbox.sh's planted.md)
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

// 57-inbox.sh's lone.md, no final newline; its answers CLI against sed stays a bash check there
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
