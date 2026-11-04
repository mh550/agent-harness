// lib/memlint.mjs: the project's memory read deterministically (the decisions store's current rules).   node --test tests/unit/memlint.test.mjs
import { test } from "node:test";
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { currentRules as cr } from "../../lib/memlint.mjs";

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
