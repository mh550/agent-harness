// The memory reviewer's files (decisions/2026-11-09-memory-reviewer): what a read-only memory-review session is given,
// the ops the gate passed as they would land (memory-review-input.json), never the raw memory-ops.json.
//   input <result.json> <base dir> <after-facts dir> <after-rules dir> [<rules base dir>]
//                                                      → the items as one JSON document: facts/<i> (apply's order),
//                                                        then rules/<n> (memory-result.json's <run>/<n>), each with its
//                                                        base and after paths and the cap read on its base
//   validate <review.json> <input.json>                → `ok` (0), or the first reason the file is refused whole (1)
//   verdicts <review.json> <input.json>                → one JSON line {reviewed, held, failed, ops: [{id, holds, reason}]}
//   render <verdicts.json> <review.json> | render --none <why> → the PRs' and memory.md's `## Review` section
import { readFileSync } from "node:fs";
import { join } from "node:path";
import { captured, isMain, runCli, textOf } from "./cli.mjs";
import { FILES, lineCount } from "./curator.mjs";
import { ROW_MAX, evidenceTable } from "./entries.mjs";
import { gotchasEntries } from "./memlint.mjs";

// a file's text → the gate's own reading of the cap: its `## Gotchas` entries and its lines; no file is null
export const capReading = text => (text == null ? null : { gotchas: gotchasEntries(text).length, lines: lineCount(text) });

// one apply result → the review's items; caps: the base file's path → its capReading (the CLI reads them)
export function input(result, { base, afterFacts, afterRules, rulesBase = base }, caps = {}) {
  const item = (id, o, b, a) => ({ id, op: o.op, file: o.file, section: o.section, anchor: o.anchor ?? null, text: o.text ?? null,
    why: o.why, from: o.from, evicted: o.evicted ?? null, base: join(b, o.file), after: join(a, o.file), cap: caps[join(b, o.file)] ?? null });
  return [...(result?.applied ?? []).map((o, i) => item(`facts/${i + 1}`, o, base, afterFacts)),
    ...(result?.rules ?? []).map(o => item(`rules/${o.n}`, o, rulesBase, afterRules))];
}

// memory-review.json (its text or parsed) and the input's items → null, or the first reason it is refused whole, naming
// the row: an id not in the input, a q outside 1 to 4, a non-string ran or saw, a non-boolean holds, a doubled (id, q),
// more than four rows per item (the rescue's 64 KB bound stays far off: ROW_MAX cuts every cell it renders)
export function validate(review, items) {
  let x = review;
  if (typeof x === "string") { try { x = JSON.parse(x); } catch (e) { return `not JSON: ${e.message}`; } }
  if (x === null || typeof x !== "object" || Array.isArray(x)) return "not a JSON object";
  if (!Array.isArray(x.rows)) return "rows is not a list";
  if (x.summary !== undefined && typeof x.summary !== "string") return "summary is not a string";
  const ids = new Set(items.map(i => i.id)), seen = new Set();
  if (x.rows.length > 4 * items.length) return `${x.rows.length} rows, at most ${4 * items.length} (4 per item)`;
  for (const [i, r] of x.rows.entries()) {
    const bad = w => `row ${i + 1}: ${w}`;
    if (r === null || typeof r !== "object" || Array.isArray(r)) return bad("not an object");
    if (!ids.has(r.id)) return bad(`id ${JSON.stringify(r.id)} is not in the input`);
    if (![1, 2, 3, 4].includes(r.q)) return bad(`q ${JSON.stringify(r.q)} is not 1 to 4`);
    for (const k of ["ran", "saw"]) if (typeof r[k] !== "string") return bad(`${k} is not a string`);
    if (typeof r.holds !== "boolean") return bad("holds is not a boolean");
    const k = `${r.id}\0${r.q}`;
    if (seen.has(k)) return bad(`(${r.id}, q${r.q}) twice`);
    seen.add(k);
  }
  return null;
}

const flat = s => `${s ?? ""}`.replace(/\s+/g, " ").trim(), cut = s => ([...s].length > ROW_MAX ? [...s].slice(0, ROW_MAX).join("") + "…" : s);
// a valid review and the input's items → one verdict per item, in the input's order: it holds when its four rows hold;
// it fails on its first failing row (by q) with that row's saw and the question, as thin with fewer than four rows, as
// not reviewed with none (decisions/2026-11-09-memory-reviewer: thin is a fail, never an escalation)
export function verdicts(review, items) {
  const ops = items.map(({ id }) => {
    const rs = review.rows.filter(r => r.id === id).sort((a, b) => a.q - b.q), f = rs.find(r => !r.holds);
    if (!rs.length) return { id, holds: false, reason: "not reviewed" };
    if (f) return { id, holds: false, reason: `${cut(flat(f.saw)) || "no saw"} (q${f.q})` };
    if (rs.length < 4) return { id, holds: false, reason: `review too thin (${rs.length} of 4 rows)` };
    return { id, holds: true, reason: null };
  });
  const held = ops.filter(o => o.holds).length;
  return { reviewed: ops.length, held, failed: ops.length - held, ops };
}

// verdicts and the review → the `## Review` section: the counts, one line per op (never trimmed from a body), then the
// rows in the verify's table (evidenceTable: one renderer), by op then question, each cell cut to ROW_MAX
export function render(v, review) {
  const at = new Map(v.ops.map((o, i) => [o.id, i])), q = o => (o.holds ? `- ${o.id} holds` : `- ${o.id} **fails**: ${o.reason}`);
  const rows = [...(review?.rows ?? [])].filter(r => at.has(r.id)).sort((a, b) => at.get(a.id) - at.get(b.id) || a.q - b.q)
    .map(r => ({ a: r.id, b: r.q, ran: cut(flat(r.ran)), saw: cut(flat(r.saw)), holds: r.holds }));
  return ["## Review", "", `${v.reviewed} reviewed · ${v.held} held · ${v.failed} failed`, "", ...v.ops.map(q),
    ...(rows.length ? ["", ...evidenceTable(rows, ["Op", "Q"])] : [])].join("\n") + "\n";
}
export const renderNone = why => `## Review\n\nnone: ${flat(why)}\n`;

export const main = captured(([cmd, ...a], io, say, put) => {
  if (cmd === "input" && (a.length === 4 || a.length === 5)) {
    const [res, base, afterFacts, afterRules, rulesBase = base] = a, caps = {};
    for (const d of new Set([base, rulesBase])) for (const f of FILES) caps[join(d, f)] = capReading(textOf(join(d, f)));
    say(JSON.stringify(input(JSON.parse(readFileSync(res, "utf8")), { base, afterFacts, afterRules, rulesBase }, caps), null, 2));
    return 0;
  }
  const json = f => JSON.parse(readFileSync(f, "utf8"));
  if ((cmd === "validate" || cmd === "verdicts") && a.length === 2) {
    const items = json(a[1]), why = validate(readFileSync(a[0], "utf8"), items);
    if (cmd === "validate" || why) { say(why ?? "ok"); return why ? 1 : 0; }
    say(JSON.stringify(verdicts(json(a[0]), items))); return 0;
  }
  if (cmd === "render" && a.length === 2) { put(a[0] === "--none" ? renderNone(a[1]) : render(json(a[0]), json(a[1]))); return 0; }
  console.error("usage: memreview.mjs input <result.json> <base dir> <after-facts dir> <after-rules dir> [<rules base dir>] | validate|verdicts <review.json> <input.json> | render <verdicts.json> <review.json> | render --none <why>");
  return 2;
});

if (isMain(import.meta.url)) runCli(main);
