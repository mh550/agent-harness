// lib/notify.mjs: the body cap, ntfy's actions header, GitHub URLs and the INBOX question.   node --test tests/unit/notify.test.mjs
import { test } from "node:test";
import assert from "node:assert/strict";
import { mkdtempSync, rmSync, writeFileSync } from "node:fs";
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
