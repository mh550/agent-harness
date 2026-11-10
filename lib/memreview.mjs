// The memory reviewer's files (decisions/2026-11-09-memory-reviewer): what a read-only memory-review session is given,
// the ops the gate passed as they would land (memory-review-input.json), never the raw memory-ops.json.
//   input <result.json> <base dir> <after-facts dir> <after-rules dir> [<rules base dir>]
//                                                      → the items as one JSON document: facts/<i> (apply's order),
//                                                        then rules/<n> (memory-result.json's <run>/<n>), each with its
//                                                        base and after paths and the cap read on its base
import { readFileSync } from "node:fs";
import { join } from "node:path";
import { captured, isMain, runCli, textOf } from "./cli.mjs";
import { FILES, lineCount } from "./curator.mjs";
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

export const main = captured(([cmd, ...a], io, say) => {
  if (cmd === "input" && (a.length === 4 || a.length === 5)) {
    const [res, base, afterFacts, afterRules, rulesBase = base] = a, caps = {};
    for (const d of new Set([base, rulesBase])) for (const f of FILES) caps[join(d, f)] = capReading(textOf(join(d, f)));
    say(JSON.stringify(input(JSON.parse(readFileSync(res, "utf8")), { base, afterFacts, afterRules, rulesBase }, caps), null, 2));
    return 0;
  }
  console.error("usage: memreview.mjs input <result.json> <base dir> <after-facts dir> <after-rules dir> [<rules base dir>]");
  return 2;
});

if (isMain(import.meta.url)) runCli(main);
