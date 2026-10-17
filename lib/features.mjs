// Feature-list operations for the driver. No dependencies. Every command takes explicit paths.
//
//   next <list> <attempts> <max>          → "<id>\t<model>\t<milestone>" of the first feature not passing and not given up on
//   bump <attempts> <id>                  → one more session spent on <id>
//   snapshot <list>                       → the list as JSON (stdout), for repair
//   repair <list> <before> <id>           → a coding session may change only its own feature's "passes".
//                                           exit 0 = nothing else changed; exit 3 = other edits reverted (list rewritten)
//   repair-verify <list> <before> <m>     → a verify session may only turn "passes" true → false within milestone <m>
//   unpass <list> <id>                    → set <id> "passes" false
//   passes <list> <id>                    → exit 0 if <id> passes
//   milestone <list> <id>                 → the milestone of <id>
//   milestone-done <list> <m>             → exit 0 if every feature of milestone <m> passes
//   ids <list> <m>                        → ids of milestone <m>, one per line
//   summary <list>                        → "<passing>/<total> passing"
//   grant <attempts> <id> <max>           → leave <id> one more attempt
//   model <alias|id>                      → full model id (fable, opus, sonnet, haiku; claude-… ids as is)
import { readFileSync, writeFileSync, existsSync } from "node:fs";
import { resolve } from "node:path";
import { fileURLToPath } from "node:url";

export const MODELS = { fable: "claude-fable-5-1", opus: "claude-opus-5-5", sonnet: "claude-sonnet-5-5", haiku: "claude-haiku-5-5" };
export const modelId = (m, fallback = "opus") => (m?.startsWith("claude-") ? m : MODELS[m ?? fallback] ?? MODELS[fallback] ?? fallback);

const read = p => JSON.parse(readFileSync(p, "utf8"));
const features = p => read(p).features;
const json = o => JSON.stringify(o, null, 2) + "\n";

/**
 * Pure: the list a session was allowed to produce. `allowed(beforeFeature, afterFeature)` says whether the change of
 * one feature's "passes" is permitted; everything else (text, order, additions, removals) comes from `before`.
 */
export function repairList(before, after, allowed) {
  const byId = new Map(after.features.map(f => [f.id, f]));
  const reverted = [];
  const features = before.features.map(b => {
    const a = byId.get(b.id);
    if (!a) { reverted.push(`${b.id}: removed`); return b; }
    const { passes: pa, ...ra } = a, { passes: pb, ...rb } = b;
    if (JSON.stringify(ra) !== JSON.stringify(rb)) reverted.push(`${b.id}: edited`);
    if (pa !== pb && !allowed(b, a)) { reverted.push(`${b.id}: passes ${pb} → ${pa}`); return b; }
    return { ...b, passes: pa };
  });
  for (const a of after.features) if (!before.features.some(b => b.id === a.id)) reverted.push(`${a.id}: added`);
  const order = after.features.map(f => f.id).filter(id => before.features.some(b => b.id === id));
  const kept = before.features.map(f => f.id).filter(id => byId.has(id));
  if (order.join() !== kept.join()) reverted.push("order changed");
  return { list: { ...before, features }, reverted };
}

function main([cmd, a, b, c]) {
  switch (cmd) {
    case "next": {
      const att = existsSync(b) ? read(b) : {};
      const f = features(a).find(f => !f.passes && (att[f.id] ?? 0) < Number(c));
      if (f) console.log([f.id, modelId(f.model), f.milestone ?? ""].join("\t"));
      return 0;
    }
    case "bump": {
      const att = existsSync(a) ? read(a) : {};
      att[b] = (att[b] ?? 0) + 1;
      writeFileSync(a, json(att));
      return 0;
    }
    case "grant": {   // leave <id> exactly one more attempt (after a verifier un-passed it)
      const att = existsSync(a) ? read(a) : {};
      att[b] = Math.min(att[b] ?? 0, Number(c) - 1);
      writeFileSync(a, json(att));
      return 0;
    }
    case "model": console.log(modelId(a)); return 0;
    case "snapshot": console.log(JSON.stringify(read(a))); return 0;
    case "repair":
    case "repair-verify": {
      const before = read(b), after = read(a);
      const allowed = cmd === "repair"
        ? (f) => f.id === c
        : (f, n) => f.milestone === c && f.passes === true && n.passes === false;
      const { list, reverted } = repairList(before, after, allowed);
      if (!reverted.length) return 0;
      writeFileSync(a, json(list));
      console.log(reverted.join("; "));
      return 3;
    }
    case "unpass": {
      const l = read(a);
      for (const f of l.features) if (f.id === b) f.passes = false;
      writeFileSync(a, json(l));
      return 0;
    }
    case "passes": return features(a).find(f => f.id === b)?.passes ? 0 : 1;
    case "milestone": console.log(features(a).find(f => f.id === b)?.milestone ?? ""); return 0;
    case "milestone-done": {
      const fs = features(a).filter(f => f.milestone === b);
      return fs.length && fs.every(f => f.passes) ? 0 : 1;
    }
    case "ids": for (const f of features(a)) if (f.milestone === b) console.log(f.id); return 0;
    case "summary": {
      const fs = features(a);
      console.log(`${fs.filter(f => f.passes).length}/${fs.length} passing`);
      return 0;
    }
    default:
      console.error("usage: features.mjs next|bump|snapshot|repair|repair-verify|unpass|passes|milestone|milestone-done|ids|summary …");
      return 2;
  }
}

if (process.argv[1] && fileURLToPath(import.meta.url) === resolve(process.argv[1])) process.exit(main(process.argv.slice(2)));
