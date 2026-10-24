// Feature-list operations for the driver. No dependencies. Every command takes explicit paths.
//
//   next <list> <attempts> <max> [<parked.json>] → "<id>\t<model>\t<milestone>" of the first feature that isn't passing,
//                                           isn't given up on or parked, and whose dependencies all pass (see deps below)
//   blocked <list> <attempts> <max> [<parked.json>] → "<id>\t<the given-up or parked feature it waits on>" for every
//                                           feature that can't run
//   undeclared <list>                     → milestones (after the first) whose first feature has no "after": each waits
//                                           on every feature before it
//   park <parked.json> <id> <answers> <why> → <id> waits on Michael until INBOX.md's answers (a hash) change
//   unpark <parked.json> <answers>        → un-park (and print) every feature parked under other answers
//   parked <parked.json> <list>           → "<id>\t<why>" of every parked feature that isn't passing
//   kind <list> <id>                      → plan | build | review | check | docs (explicit "kind", else inferred)
//   milestones <list>                     → milestone ids in list order
//   evidence <list> <m> <progress.md>     → exit 0 if the newest "verify <m>" entry has a table row per step of
//                                           every feature of <m>; else prints the shortfall ("T1-02 2/6; …"), exit 1
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
//   unbump <attempts> <id>                → give back the attempt a limit-killed session used
//   reset <attempts> <list>               → a continuation: every feature that isn't passing gets its attempts back
//   touched-outside <list> <attempts> <m> <verified,…> → ids of features outside milestone <m> that have been worked on
//                                           (an attempt or passes) but whose milestone isn't verified: their commits are
//                                           in <m>'s tag, so that tag must not merge on its own
//   model <alias|id>                      → full model id (fable, opus, sonnet, haiku; claude-… ids as is)
import { readFileSync, writeFileSync, existsSync } from "node:fs";
import { resolve } from "node:path";
import { fileURLToPath } from "node:url";

export const MODELS = { fable: "claude-fable-5-1", opus: "claude-opus-5-5", sonnet: "claude-sonnet-5-5", haiku: "claude-haiku-5-5" };
export const modelId = (m, fallback = "opus") => (m?.startsWith("claude-") ? m : MODELS[m ?? fallback] ?? MODELS[fallback] ?? fallback);

const read = p => JSON.parse(readFileSync(p, "utf8"));

/**
 * Pure: what a feature waits on. An explicit "after" wins (the initializer marks independent work that way): feature
 * ids, or milestone ids meaning every feature of that milestone before this one. Otherwise a feature depends on every
 * feature before it, so array order is dependency order and nothing is built on top of work that failed.
 */
export function deps(list, f) {
  const before = list.slice(0, list.indexOf(f));
  if (!Array.isArray(f.after)) return before.map(x => x.id);
  return f.after.flatMap(a => list.some(x => x.id === a) || !list.some(x => x.milestone === a) ? [a]
    : before.filter(x => x.milestone === a).map(x => x.id));
}

/** Pure: milestones after the first whose first feature has no "after" (so the whole milestone waits on everything). */
export function undeclared(list) {
  const firsts = [...new Map(list.filter(f => f.milestone).map(f => [f.milestone, null])).keys()]
    .map(m => list.find(f => f.milestone === m));
  return firsts.slice(1).filter(f => !Array.isArray(f.after)).map(f => f.milestone);
}

/**
 * Pure: the next feature to work on, or null; and which features are blocked by one that can't run (given up, or
 * parked: waiting on Michael).
 */
export function schedule(list, att, max, parked = new Set()) {
  const byId = new Map(list.map(f => [f.id, f]));
  const givenUp = f => !f.passes && ((att[f.id] ?? 0) >= max || parked.has(f.id));
  // the given-up feature a feature ultimately waits on, if any (transitively)
  const blocker = (f, seen = new Set()) => {
    for (const id of deps(list, f)) {
      const d = byId.get(id);
      if (!d || d.passes || seen.has(id)) continue;
      seen.add(id);
      if (givenUp(d)) return d.id;
      const b = blocker(d, seen); if (b) return b;
    }
    return null;
  };
  const next = list.find(f => !f.passes && !givenUp(f) && deps(list, f).every(id => byId.get(id)?.passes ?? true)) ?? null;
  const blocked = list.filter(f => !f.passes && !givenUp(f)).map(f => [f.id, blocker(f)]).filter(([, b]) => b);
  return { next, blocked };
}

/** Pure: plan | build | review | check | docs. */
export function kindOf(f) {
  if (f.kind) return f.kind;
  const d = `${f.description ?? ""}`;
  if (/^an? (short |reviewed )?(docs )?plan\b/i.test(d)) return "plan";
  if (/review (\+|and) simplif|reviewed and simplified|^whole-run review/i.test(d)) return "review";
  if (/what michael will see/i.test(d)) return "check";
  if (/^docs wrap-up|^docs\/\S+\.md (is|are)\b|README fully describes|STATUS\.md is rewritten/i.test(d)) return "docs";
  return "build";
}

/** Pure: per feature of milestone m, how many evidence rows the newest verify entry has vs. how many steps it has. */
export function evidence(list, m, progress) {
  const entries = progress.split(/^(?=### )/m);
  const entry = entries.find(e => new RegExp(`^### .*\\bverify ${m.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")}\\b`).test(e)) ?? "";
  return list.filter(f => f.milestone === m).map(f => {
    const rows = entry.split("\n").filter(l => new RegExp(`^\\|\\s*\\**${f.id.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")}\\**\\s*\\|`).test(l)).length;
    return { id: f.id, rows, steps: (f.steps ?? []).length };
  });
}
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

const parkedIds = p => new Set(p && existsSync(p) ? Object.keys(read(p)) : []);

function main([cmd, a, b, c, d]) {
  switch (cmd) {
    case "next":
    case "blocked": {
      const att = existsSync(b) ? read(b) : {};
      const { next, blocked } = schedule(features(a), att, Number(c), parkedIds(d));
      if (cmd === "next" && next) console.log([next.id, modelId(next.model), next.milestone ?? ""].join("\t"));
      if (cmd === "blocked") for (const [id, by] of blocked) console.log(`${id}\t${by}`);
      return 0;
    }
    case "undeclared": { const u = undeclared(features(a)); if (u.length) console.log(u.join(", ")); return 0; }
    case "park": {
      const p = existsSync(a) ? read(a) : {};
      p[b] = { answers: c, why: d ?? "", at: new Date().toISOString() };
      writeFileSync(a, json(p));
      return 0;
    }
    case "unpark": {
      const p = existsSync(a) ? read(a) : {};
      for (const [id, v] of Object.entries(p)) if (v.answers !== b) { delete p[id]; console.log(id); }
      if (existsSync(a)) writeFileSync(a, json(p));
      return 0;
    }
    case "parked": {
      const p = existsSync(a) ? read(a) : {}, fs = features(b);
      for (const [id, v] of Object.entries(p)) if (!fs.find(f => f.id === id)?.passes) console.log(`${id}\t${v.why}`);
      return 0;
    }
    case "kind": { const f = features(a).find(f => f.id === b); console.log(f ? kindOf(f) : ""); return 0; }
    case "milestones": console.log([...new Set(features(a).map(f => f.milestone).filter(Boolean))].join("\n")); return 0;
    case "evidence": {
      const rows = evidence(features(a), b, existsSync(c) ? readFileSync(c, "utf8") : "");
      const short = rows.filter(r => r.rows < r.steps);
      if (short.length) { console.log(short.map(r => `${r.id} ${r.rows}/${r.steps}`).join("; ")); return 1; }
      return 0;
    }
    case "bump": {
      const att = existsSync(a) ? read(a) : {};
      att[b] = (att[b] ?? 0) + 1;
      writeFileSync(a, json(att));
      return 0;
    }
    case "unbump": {   // a session that died on a usage limit does not count as an attempt
      const att = existsSync(a) ? read(a) : {};
      att[b] = Math.max(0, (att[b] ?? 0) - 1);
      writeFileSync(a, json(att));
      return 0;
    }
    case "grant": {   // leave <id> exactly one more attempt (after a verifier un-passed it)
      const att = existsSync(a) ? read(a) : {};
      att[b] = Math.min(att[b] ?? 0, Number(c) - 1);
      writeFileSync(a, json(att));
      return 0;
    }
    case "reset": {
      const att = existsSync(a) ? read(a) : {};
      for (const f of features(b)) if (!f.passes) delete att[f.id];
      writeFileSync(a, json(att));
      return 0;
    }
    case "touched-outside": {
      const att = existsSync(b) ? read(b) : {}, [m, ver] = [c, new Set((process.argv[6] ?? "").split(",").filter(Boolean))];
      for (const f of features(a)) if (f.milestone !== m && !ver.has(f.milestone) && ((att[f.id] ?? 0) > 0 || f.passes)) console.log(f.id);
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
      console.error("usage: features.mjs next|blocked|undeclared|park|unpark|parked|kind|milestones|evidence|bump|snapshot|repair|repair-verify|unpass|passes|milestone|milestone-done|ids|summary …");
      return 2;
  }
}

if (process.argv[1] && fileURLToPath(import.meta.url) === resolve(process.argv[1])) process.exit(main(process.argv.slice(2)));
