// lib/memlint.mjs: the project's memory read deterministically (the decisions store, its current rules, the Gotchas diff).   node --test tests/unit/memlint.test.mjs
import { test } from "node:test";
import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { mkdirSync, mkdtempSync, readFileSync, rmSync, symlinkSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { fileURLToPath } from "node:url";
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
// each case a worktree of these files under the OS temp dir (the store CLI's runs stay in memory-prompts)
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
// outside the section is none (the gotchas CLI on two files stays in gotchas-pack)
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

// S1's surviving mutant andor-05 (`cmd === "gotchas" && wt && rest.length === 1` read with `||`): a command with one
// argument too many or too few is the usage error, never an answer
test("memlint.mjs: main with a wrong argument count is the usage error: exit 2, nothing on stdout, the usage line on stderr", async () => {
  const d = mkdtempSync(join(tmpdir(), "ml-"));
  try {
    writeFileSync(join(d, "a"), "## Gotchas\n- x\n");
    for (const argv of [["store", d, "extra"], ["store-line", d, "extra"], ["gotchas", join(d, "a")], ["gotchas", join(d, "a"), join(d, "a"), "extra"]]) {
      const r = await sameAsCli("memlint.mjs", argv);
      assert.equal(r.rc, 2, argv.join(" ")); assert.equal(r.out, "", argv.join(" "));
    }
    const { main } = await import("../../lib/memlint.mjs"), said = [], err = console.error;
    console.error = (...a) => said.push(a.join(" "));
    try { await main(["store", d, "extra"], { cwd: d, env: process.env }); } finally { console.error = err; }
    assert.equal(said.length, 1); starts(said[0], "usage: memlint.mjs <worktree> | store <worktree> | ");
  } finally { rmSync(d, { recursive: true, force: true }); }
});

// ---- the lint (M4), on fixtures trimmed from the projects' files as they were before chunk 3 Part 2 tidied them ----
// The 15 cases the memlint check file (39-memlint-m4) ran through the CLI until the shape (decisions/2026-11-05-suite-shape),
// under the same names: each is the CLI's own bytes and exit code (sameAsCli: main's are held to them), on a worktree
// under the OS temp dir with the empty docs/ and .harness/ every case there had. The lint of this checkout's own
// files stays a bash check (tests/checks/memlint-self.sh), the driver's notes tests/checks/memlint-run.sh.
const MM = fileURLToPath(new URL("../../lib/memlint.mjs", import.meta.url));
const fx = name => readFileSync(new URL(`../fixtures/memlint/${name}`, import.meta.url), "utf8");
// files: path → text, null for a directory; fn(d) may be async (the worktree outlives its awaits)
const lintWt = async (files, fn) => {
  const d = mkdtempSync(join(tmpdir(), "ml4-"));
  try {
    for (const [f, text] of Object.entries({ docs: null, ".harness": null, ...files })) {
      mkdirSync(join(d, f, text === null ? "" : ".."), { recursive: true });
      if (text !== null) writeFileSync(join(d, f), text);
    }
    return await fn(d);
  } finally { rmSync(d, { recursive: true, force: true }); }
};
// the worktree's findings: the CLI's stdout, its exit 0 asserted (bash's `o=$($M "$wt") &&`)
const ml = async (d, opts) => { const r = await sameAsCli("memlint.mjs", [d], opts); assert.equal(r.rc, 0, "memlint's exit code"); return r.out; };
const count = (out, check) => out.split("\n").filter(l => l.includes(` ${check}: `)).length;
const hasLine = (out, re) => assert.ok(out.split("\n").some(l => re.test(l)), `no line matches ${re} in:\n${out}`);
const TIDY = () => ({ "docs/decisions.md": fx("rane-decisions-tidy.md"), "CLAUDE.md": fx("rane-claude-tidy.md") });
const DIRSTORE = { ".harness/config.sh": "DECISIONS=journal/decisions\n" };

test("memlint: node --check passes, the usage header lists the five checks, a missing worktree exits 2", async () => {
  assert.equal(spawnSync(process.execPath, ["--check", MM]).status, 0);
  const src = readFileSync(MM, "utf8").split("\n"), a = src.findIndex(l => l.startsWith("//   <worktree>")), b = src.findIndex(l => l.startsWith("import"));
  assert.ok(a >= 0 && b > a, "the usage header runs from its <worktree> line to the first import");
  const h = src.slice(a, b + 1).join("\n");
  for (const c of ["size", "gotchas", "derivable-count", "run-scope", "decisions"]) assert.ok(h.includes(c), `the header names ${c}`);
  await lintWt({}, async d => assert.equal((await sameAsCli("memlint.mjs", [join(d, "nope")])).rc, 2));
});

test("memlint: the dj CLAUDE.md (ed75a2d^) yields one derivable-count finding naming its line, exit 0", async () => {
  await lintWt({ "CLAUDE.md": fx("dj-claude.md") }, async d => {
    const o = await ml(d);
    assert.equal(count(o, "derivable-count"), 1); hasLine(o, /^CLAUDE.md:17 derivable-count: .*1,870 tests/);
  });
});

test("memlint: the pathways project.md (4cafb65^) yields a run-scope finding for tonight", async () => {
  await lintWt({ ".harness/project.md": fx("pathways-project.md") }, async d => {
    const o = await ml(d);
    hasLine(o, /^.harness\/project.md:22 run-scope: .*tonight/); assert.equal(count(o, "run-scope"), 1);
  });
});

test("memlint: the old rane store (aa88421^) yields a decisions finding for its Superseded line, none for the header or D9", async () => {
  await lintWt({ "docs/decisions.md": fx("rane-decisions-old.md") }, async d => {
    const o = await ml(d);
    assert.equal(count(o, "decisions"), 1); hasLine(o, /^docs\/decisions.md:33 decisions: D15 .*Updated in place/);
  });
});

test("memlint: the old rane store without its current-rule-set header yields a header finding", async () => {
  const ls = fx("rane-decisions-old.md").split("\n"); ls.splice(3, 3);   // sed -i 4,6d
  await lintWt({ "docs/decisions.md": ls.join("\n") }, async d => {
    const o = await ml(d);
    hasLine(o, /^docs\/decisions.md:1 decisions: no current-rule-set header/); assert.equal(count(o, "decisions"), 2);
  });
});

test("memlint: the tidy rane store (aa88421) beside its tidy CLAUDE.md (3d7abc9, Where things go) yields no finding", async () => {
  assert.match(fx("rane-claude-tidy.md"), /^## Where things go/m);
  await lintWt(TIDY(), async d => assert.equal(await ml(d), ""));
});

test("memlint: the voice-concierge store (99091b5) yields no finding (the rows they superseded is prose, not a marker)", async () => {
  assert.ok(fx("voice-decisions.md").includes("rows they superseded"));
  await lintWt({ "docs/decisions.md": fx("voice-decisions.md") }, async d => assert.equal(await ml(d), ""));
});

test("memlint: a worktree with neither DECISIONS= nor docs/decisions.md yields decisions: no store", async () => {
  await lintWt({ "CLAUDE.md": fx("dj-claude.md") }, async d => {
    hasLine(await ml(d), /^.harness\/config.sh:1 decisions: no store/);
    writeFileSync(join(d, ".harness/config.sh"), "DECISIONS=docs/gone.md\n");
    hasLine(await ml(d), /^.harness\/config.sh:1 decisions: store docs\/gone.md not found/);
  });
});

test("memlint: a CLAUDE.md of 121 lines yields a size finding at line 121, MEMLINT_LINES moves the cap", async () => {
  const pad = Array.from({ length: 28 }, (_, i) => `pad ${i + 1}\n`).join(""), big = fx("rane-claude-tidy.md") + pad;
  assert.equal(big.split("\n").length - 1, 121);   // wc -l
  await lintWt({ "docs/decisions.md": fx("rane-decisions-tidy.md"), "CLAUDE.md": big }, async d => {
    assert.equal(await ml(d), "CLAUDE.md:121 size: 121 lines, over 120 (MEMLINT_LINES)\n");
    writeFileSync(join(d, "CLAUDE.md"), big.replace(/pad 28\n$/, ""));   // sed -i $d
    assert.equal(await ml(d), "");
    assert.equal(await ml(d, { env: { MEMLINT_LINES: "100" } }), "CLAUDE.md:101 size: 120 lines, over 100 (MEMLINT_LINES)\n");
  });
});

test("memlint: 16 Gotchas lines yield a gotchas finding at the 16th, 15 none (a wrapped bullet is one line)", async () => {
  const added = n => fx("rane-claude-tidy.md").split("\n").flatMap(l => /^## Gotchas/.test(l) ? [l, ...Array.from({ length: n }, (_, i) => `- added fact ${i + 1}`)] : [l]).join("\n");
  await lintWt({ "docs/decisions.md": fx("rane-decisions-tidy.md"), "CLAUDE.md": added(9) }, async d => {
    assert.equal(await ml(d), "CLAUDE.md:94 gotchas: 16 lines, over 15\n");
    writeFileSync(join(d, "CLAUDE.md"), added(8));   // sed -i "/^- added fact 9$/d"
    assert.equal(await ml(d), "");
  });
});

test("memlint: a directory store file marked superseded with no Updated in place line yields a finding, with one none", async () => {
  const old = "# Old rule\n\n- **Choice:** x\n- Superseded by decisions/2026-10-26-new.\n";
  await lintWt({ ...DIRSTORE, "journal/decisions/2026-10-25-old.md": old,
    "journal/decisions/2026-10-26-new.md": "# New rule\n\n- **Choice:** y; its origin replaced by a clone (prose, not a marker)\n" }, async d => {
    assert.equal(await ml(d), 'journal/decisions/2026-10-25-old.md:4 decisions: superseded with no "Updated in place" line\n');
    writeFileSync(join(d, "journal/decisions/2026-10-25-old.md"), `${old}Updated in place 2026-10-26: now y.\n`);
    assert.equal(await ml(d), "");
  });
});

test("memlint: a stated rule is no count or run scope (1 test, as of decision 12), a month alone is a date (as of October)", async () => {
  await lintWt({ ".harness/config.sh": "DECISIONS=docs/d.md\n", "docs/d.md": "# d\nThe current rule set.\n",
    "CLAUDE.md": "# x\n- Write 1 test first, watch it fail.\n- Rules hold as of decision 12.\n- Prices as of October.\n" }, async d =>
    assert.equal(await ml(d), 'CLAUDE.md:4 run-scope: "as of October" (run scope goes in the run\'s brief)\n'));
});

test("memlint: a ### under a decision is part of it, a ## heading is named by itself, a .md directory in a dir store is skipped", async () => {
  const store = ["# d", "The current rule set, rewritten in place.", "", "## D15 old", "Superseded in part by D17.", "### History",
    "Updated in place 2026-10-20: narrowed.", "## Notes on D17 and hardware", "The jog rule was superseded by the D20 rule."].join("\n") + "\n";
  await lintWt({ "docs/decisions.md": store }, async d =>
    assert.equal(await ml(d), 'docs/decisions.md:9 decisions: Notes on D17 and hardware superseded with no "Updated in place" line\n'));
  await lintWt({ ...DIRSTORE, "journal/decisions/old.md": null }, async d => assert.equal(await ml(d), ""));
});

// the M4 review (M4-02): an unreadable file is one stderr line naming it; a header under a non-decision `## ` section is
// a header; a symlinked decision file is linted as readRules reads it
test("memlint: an unreadable CLAUDE.md is exit 1 and one stderr line naming the file and the error", async () => {
  await lintWt({ "CLAUDE.md": null }, async d => {
    const r = await sameAsCli("memlint.mjs", [d]);
    assert.equal(r.rc, 1); assert.equal(r.out, "");
    const err = spawnSync(process.execPath, [MM, d]).stderr.toString();   // the CLI's own stderr (sameAsCli swallows it)
    assert.equal(err.split("\n").length - 1, 1, err); starts(err, "memlint: cannot read CLAUDE.md: EISDIR");
  });
});

test("memlint: a current-rule-set header under a ## section before the first decision is a header; a symlinked file is linted", async () => {
  await lintWt({ "docs/decisions.md": "# Decisions\n## How this file works\nThis is the current rule set, rewritten in place.\n## D1 one\nRule.\n" },
    async d => assert.equal(await ml(d), ""));
  await lintWt({ ...DIRSTORE, "journal/decisions": null, "elsewhere/old.md": "# Old\n- Superseded by decisions/x.\n" }, async d => {
    symlinkSync("../../elsewhere/old.md", join(d, "journal/decisions/2026-10-25-old.md"));
    assert.equal(await ml(d), 'journal/decisions/2026-10-25-old.md:2 decisions: superseded with no "Updated in place" line\n');
  });
});
