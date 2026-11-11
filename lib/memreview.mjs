// The memory reviewer's files (decisions/2026-11-09-memory-reviewer): what a read-only memory-review session is given,
// the ops the gate passed as they would land (memory-review-input.json), never the raw memory-ops.json.
//   input <result.json> <base dir> <after-facts dir> <after-rules dir> [<rules base dir>]
//                                                      → the items as one JSON document: facts/<i> (apply's order),
//                                                        then rules/<n> (memory-result.json's <run>/<n>), each with its
//                                                        base and after paths and the cap read on its base
//   validate <review.json> <input.json>                → `ok` (0), or the first reason the file is refused whole (1)
//   verdicts <review.json> <input.json>                → one JSON line {reviewed, held, failed, ops: [{id, holds, reason, q}]}
//                                                        (q: the failing row's question, null otherwise)
//   render <verdicts.json> <review.json> | render --none <why> → the PRs' and memory.md's `## Review` section
//   line <verdicts.json> <memory.json>                 → the one `memory: facts …` line (the note, the F3d card's text);
//                                                        nothing before the review or with nothing reviewed
//   card <verdicts.json> <memory.json> <input.json> <policy> → the memory event's `memory` object as one JSON line
//                                                        (docs/specs/2026-11-10-review-surface.md §V1-01; no verdicts
//                                                        file: a review none; an unreadable input: no sections)
//   title <memory.json|card.json> <run>                → the memory event's title
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
    if (!rs.length) return { id, holds: false, reason: "not reviewed", q: null };
    if (f) return { id, holds: false, reason: `${cut(flat(f.saw)) || "no saw"} (q${f.q})`, q: f.q };
    if (rs.length < 4) return { id, holds: false, reason: `review too thin (${rs.length} of 4 rows)`, q: null };
    return { id, holds: true, reason: null, q: null };
  });
  const held = ops.filter(o => o.holds).length;
  return { reviewed: ops.length, held, failed: ops.length - held, ops };
}

// the counts as every reader prints them: this line, the `## Review` section and the report's `Memory` row (summary.mjs)
export const heldFailed = (h, f) => `${h} held · ${f} failed`;

const bare = (r, q) => (`${r}`.endsWith(` (q${q})`) ? `${r}`.slice(0, -` (q${q})`.length) : `${r}`);   // verdicts' reason ends ` (q<n>)`
// line's why: a none's own, or "no verdicts" when memory.json says ok and no verdicts came
const why = (v, m) => { const w = m?.review ?? "ok"; return w !== "ok" ? flat(w) : Array.isArray(v?.ops) ? "ok" : "no verdicts"; };
// verdicts (null when none) and memory.json → the one line the harness-log.md note and the F3d card carry
// (decisions/2026-11-09-memory-graduation): the facts tier's held and failed always (it is what `auto` merges), the
// rules tier's failed only when one failed (*default*), each fail `<id>: <reason>, q<n>` (thin: no q); `review none
// (<why>)` when no verdict came (an input that failed among them); "" before the review (no `reviewed`) or with nothing
// to review
export function line(v, m) {
  if (!Number.isInteger(m?.reviewed)) return "";
  // nothing would land, nothing to carry; an input that failed landed every op unreviewed: a none (R2's review, M5)
  if (m.reviewed === 0 && (m.review ?? "ok") === "ok" || m.review === "nothing to review") return "";
  const w = why(v, m), prs = ` · PR ${m.pr ?? "none"} · rules PR ${m.rules_pr ?? "none"}`;
  if (w !== "ok") return `memory: review none (${w})${prs}`;
  const fail = o => (o.q ? `${o.id}: ${bare(o.reason, o.q)}, q${o.q}` : `${o.id}: ${o.reason}`), fails = os => os.map(fail).join("; ");
  const tier = t => {
    const os = v.ops.filter(o => String(o.id).startsWith(`${t}/`)), f = os.filter(o => !o.holds), n = f.length ? ` (${fails(f)})` : "";
    return t === "facts" ? `facts ${heldFailed(os.length - f.length, f.length)}${n}` : `rules ${os.length - f.length} held${f.length ? ` · ${f.length} failed${n}` : ""}`;
  };
  return `memory: ${tier("facts")} · ${tier("rules")}${prs}`;
}

// verdicts (null when none), memory.json, the review input's items and the policy → the memory event's object (the
// card): both PRs, the counts, one failure per failed op of either tier (its input item's section, the failing row's q,
// null for thin or not reviewed, the reason as line prints it), `merged` when the driver merged the facts PR, and
// `review` so the card knows whether a merge is offered (*default*, decisions/2026-11-10-review-surface-event)
export function card(v, m, items, policy) {
  const review = why(v, m), sec = new Map((items ?? []).map(i => [i.id, i.section ?? null]));
  const failures = review !== "ok" ? [] : v.ops.filter(o => !o.holds)
    .map(o => ({ id: o.id, section: sec.get(o.id) ?? null, q: o.q ?? null, reason: o.q ? bare(o.reason, o.q) : `${o.reason}` }));
  return { pr: m?.pr ?? null, rules_pr: m?.rules_pr ?? null, policy, reviewed: m?.reviewed ?? 0, held: m?.held ?? 0, failed: m?.failed ?? 0,
    failures, state: m?.merged_by === "driver" ? "merged" : "open", review };
}

// memory.json or the card, and the run → R2-02 §5's title; `review none` when no verdict came (*default*: `0 held · 0
// failed` would read as a verdict where there was none)
export const title = (m, run) => `[${run}] memory: ${(m?.review ?? "ok") === "ok" ? heldFailed(m?.held ?? 0, m?.failed ?? 0) : "review none"}`;

// verdicts and the review → the `## Review` section: the counts, one line per op (never trimmed from a body), then the
// rows in the verify's table (evidenceTable: one renderer), by op then question, each cell cut to ROW_MAX
export function render(v, review) {
  const at = new Map(v.ops.map((o, i) => [o.id, i])), q = o => (o.holds ? `- ${o.id} holds` : `- ${o.id} **fails**: ${o.reason}`);
  const rows = [...(review?.rows ?? [])].filter(r => at.has(r.id)).sort((a, b) => at.get(a.id) - at.get(b.id) || a.q - b.q)
    .map(r => ({ a: r.id, b: r.q, ran: cut(flat(r.ran)), saw: cut(flat(r.saw)), holds: r.holds }));
  return ["## Review", "", `${v.reviewed} reviewed · ${heldFailed(v.held, v.failed)}`, "", ...v.ops.map(q),
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
  if (cmd === "line" && a.length === 2) {
    let v = null; try { v = JSON.parse(textOf(a[0]) ?? "null"); } catch { v = null; }   // no verdicts file: the why none
    const x = line(v, json(a[1])); if (x) say(x); return 0;
  }
  if (cmd === "card" && a.length === 4) {
    let v = null, items = []; try { v = JSON.parse(textOf(a[0]) ?? "null"); } catch { v = null; }   // no verdicts file: a review none
    try { items = JSON.parse(textOf(a[2]) ?? "[]"); } catch { items = []; }   // an input that failed: its none still has a card
    say(JSON.stringify(card(v, json(a[1]), Array.isArray(items) ? items : [], a[3]))); return 0;
  }
  if (cmd === "title" && a.length === 2) { say(title(json(a[0]), a[1])); return 0; }
  if (cmd === "render" && a.length === 2) { put(a[0] === "--none" ? renderNone(a[1]) : render(json(a[0]), json(a[1]))); return 0; }
  console.error("usage: memreview.mjs input <result.json> <base dir> <after-facts dir> <after-rules dir> [<rules base dir>] | validate|verdicts <review.json> <input.json> | render <verdicts.json> <review.json> | render --none <why> | line <verdicts.json> <memory.json> | card <verdicts.json> <memory.json> <input.json> <policy> | title <memory.json> <run>");
  return 2;
});

if (isMain(import.meta.url)) runCli(main);
