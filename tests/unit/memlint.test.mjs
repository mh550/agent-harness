// lib/memlint.mjs: the project's memory read deterministically (the decisions store, its current rules, the Gotchas diff).   node --test tests/unit/memlint.test.mjs
import { test } from "node:test";
import assert from "node:assert/strict";
import { mkdirSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { sameAsCli } from "./cli-same.mjs";
import { currentRules as cr, decisionsStore, gotchasDiff, gotchasLines } from "../../lib/memlint.mjs";

const F = { path: "docs/decisions.md", kind: "file" };
const starts = (s, prefix) => assert.equal(s.slice(0, prefix.length), prefix);
const refs = r => r.map(x => x.ref).join();

// Current rules (M3-04): the decisions store's lines newest first, from a directory (each file's `# ` title, by name) or
// a file in the three shapes the projects use (fixtures copied from rane-one-mixxx, voice-concierge, dj-crate-streaming)
test("memlint: currentRules reads a directory store and the three file shapes newest first", () => {
  const fx = n => readFileSync(new URL("../fixtures/decisions-" + n + ".md", import.meta.url), "utf8"), s = r => r.map(x => x.text + " → " + x.ref).join("\n");
  const rane = cr(F, fx("rane")), vc = cr(F, fx("voice-concierge")), dj = cr(F, fx("dj"));
  const dir = cr({ path: "journal/decisions", kind: "dir" }, [{ name: "2026-10-20-a.md", text: "# Alpha rule\nbody" }, { name: "2026-10-26-b.md", text: "intro\n# Beta rule\n" }, { name: "2026-10-22-c.md", text: "no title\n" }, { name: "README.md", text: "# About this store\n" }]);
  assert.equal(rane.length, 3);
  assert.equal(refs(rane), "docs/decisions.md:15,docs/decisions.md:13,docs/decisions.md:7");
  starts(rane[2].text, "D1 default · Playback model: hybrid. Mixxx");
  starts(rane[0].text, "D3 · Separate Mixxx dev profile at `~/.var/");
  const tail = "so it can be PR'd to `mixxxdj/mixxx` later. (2026-10-19)";
  assert.equal(rane[1].text.slice(-tail.length), tail);
  assert.equal(refs(vc), "docs/decisions.md:7,docs/decisions.md:3");
  starts(vc[1].text, "D7 default: turn detection is silero VAD only (2026-10-20, C1-01) — Finding. B1 leaves");
  assert.equal(refs(dj), "docs/decisions.md:17,docs/decisions.md:16,docs/decisions.md:15,docs/decisions.md:14,docs/decisions.md:13");
  starts(dj[4].text, "D24 · One download quality. A file is acceptable");
  starts(dj[0].text, "D53 default · A matched release gives");
  starts(dj[1].text, "D36 default · The cleanup");
  assert.equal(s(cr(F, fx("rane").replace(/\n/g, "\r\n"))), s(rane));
  assert.equal(s(dir), "Beta rule → journal/decisions/2026-10-26-b.md\nAlpha rule → journal/decisions/2026-10-20-a.md\nAbout this store → journal/decisions/README.md");
  assert.equal(cr(F, "# Decisions\nnone yet\n").length, 0);
});

// a range or a group heading is no decision, however its dash is written, and a heading never replaces a row of the same n
test("memlint: currentRules skips ranges written with any dash or to, and a heading never replaces a row", () => {
  const r = cr({ path: "d.md", kind: "file" }, "## D1—D6 the early ones\n\n## D7 – D9 later\n\n## D10 to D12\n\n| D24 | **One quality** | x |\n\n## D24 on\n\ntext\n\n## D30: a rule\n\nwhy\n");
  assert.equal(refs(r), "d.md:13,d.md:7");
  starts(r[1].text, "D24 · One quality");
});

// decisionsStore (M2): .harness/config.sh's DECISIONS= (a quoted one, after a comment) wins, else docs/decisions.md;
// each case a worktree of these files under the OS temp dir (the store CLI's runs stay in 37-memory-prompts-m2)
const inWorktree = (files, fn) => {
  const d = mkdtempSync(join(tmpdir(), "u1-"));
  try {
    for (const [f, text] of Object.entries(files)) { mkdirSync(join(d, f, text === null ? "" : ".."), { recursive: true }); if (text !== null) writeFileSync(join(d, f), text); }
    return fn(d);
  } finally { rmSync(d, { recursive: true, force: true }); }
};
const ds = files => inWorktree(files, d => JSON.stringify(decisionsStore(d)));

test("decisionsStore: DECISIONS=journal/decisions in .harness/config.sh is a directory store", () => {
  assert.equal(ds({ ".harness/config.sh": 'CHECK_CMD="true"\n# DECISIONS=docs/old.md\nDECISIONS=journal/decisions\n', "journal/decisions": null }),
    '{"path":"journal/decisions","kind":"dir","exists":true}');
});

test("decisionsStore: no DECISIONS and docs/decisions.md present is a file store", () => {
  assert.equal(ds({ "docs/decisions.md": "# decisions\n" }), '{"path":"docs/decisions.md","kind":"file","exists":true}');
});

test("decisionsStore: neither is null, and store prints nothing", () => {
  assert.equal(ds({ ".harness/config.sh": 'CHECK_CMD="true"\n' }), "null");
});

test("decisionsStore: a quoted DECISIONS= naming a missing file wins over docs/decisions.md, a file store that doesn't exist", () => {
  assert.equal(ds({ "docs/decisions.md": "# decisions\n", ".harness/config.sh": 'export DECISIONS="docs/d.md"   # one file\n' }),
    '{"path":"docs/d.md","kind":"file","exists":false}');
});

// gotchasDiff (M3): the Gotchas lines added, edited and deleted between two project-rules texts (null: no file); a change
// outside the section is none (the gotchas CLI on two files stays in 38-run-17-gotchas-and-pack-m3)
const G = "# p\nrules\n\n## Gotchas\n\n- one (r 2026-10-26)\n- two (r 2026-10-26)\n\n## Later\nx\n";
const gd = (b, a) => { const d = gotchasDiff(b, a); return `+${d.added} ~${d.edited} -${d.deleted}`; };

test("gotchasDiff: added, edited, deleted and no section", () => {
  assert.equal(gd(G, G.replace("- two (r 2026-10-26)", "- two (r 2026-10-26)\n- three (r 2026-10-26)")), "+1 ~0 -0");
  assert.equal(gd(G, G.replace("- two", "- 2")), "+0 ~1 -0");
  assert.equal(gd(G, G.replace("- two (r 2026-10-26)\n", "")), "+0 ~0 -1");
  assert.equal(gd("# p\nrules\n", "# p\nother\n"), "+0 ~0 -0");
  assert.equal(gd(null, null), "+0 ~0 -0");
  assert.equal(gd(null, "# p\n"), "+0 ~0 -0");
  assert.equal(gd(G, G.replace("rules", "changed")), "+0 ~0 -0");
  assert.equal(gd(G, G.replace("x", "y")), "+0 ~0 -0");
});

// a wrapped bullet is one line (its indented continuation joins it), and a `# ` heading ends the section too (M3-05)
test("gotchasLines: a wrapped bullet is one line and any # or ## heading ends the section", () => {
  assert.equal(gd(G, G.replace("- two (r 2026-10-26)", "- two (r 2026-10-26)\n- three wraps\n  onto a second line (r 2026-10-26)")), "+1 ~0 -0");
  assert.equal(gd(G.replace("## Later", "# Later"), G.replace("## Later\nx", "# Later\ny")), "+0 ~0 -0");
  assert.equal(JSON.stringify(gotchasLines("## Gotchas\n- a\n  b\n\n- c\n")), '["- a b","- c"]');
});

// ---- main(argv, io): the CLI's bytes and exit code; MEMLINT_LINES from io.env (decisions/2026-11-03-resident-helper) ----
test("memlint.mjs: main gives the CLI's bytes for a worktree, gotchas, store and store-line, and reads MEMLINT_LINES from io.env", async () => {
  const d = mkdtempSync(join(tmpdir(), "ml-"));
  try {
    writeFileSync(join(d, "CLAUDE.md"), `# p\n\n${"line\n".repeat(30)}`);
    const plain = await sameAsCli("memlint.mjs", [d]);
    const low = await sameAsCli("memlint.mjs", [d], { env: { MEMLINT_LINES: "10" } });
    assert.notEqual(low.out, plain.out, "the env moved the limit");
    writeFileSync(join(d, "a"), "## Gotchas\n- x\n"); writeFileSync(join(d, "b"), "## Gotchas\n- x\n- y\n");
    assert.equal((await sameAsCli("memlint.mjs", ["gotchas", join(d, "a"), join(d, "b")])).out, "+1 ~0 -0\n");
    await sameAsCli("memlint.mjs", ["store", d]);
    await sameAsCli("memlint.mjs", ["store-line", d]);
  } finally { rmSync(d, { recursive: true, force: true }); }
});
