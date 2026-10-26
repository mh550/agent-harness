// Feature-list operations for the driver. No dependencies. Every command takes explicit paths.
//
//   next <list> <attempts> <max> [<parked.json>] → "<id>\t<model>\t<milestone>" of the first feature that isn't passing,
//                                           isn't given up on or parked, and whose dependencies all pass (see deps below)
//   blocked <list> <attempts> <max> [<parked.json>] → "<id>\t<the given-up or parked feature it waits on>" for every
//                                           feature that can't run
//   undeclared <list>                     → milestones (after the first) whose first feature has no "after": each waits
//                                           on every feature before it
//   lint <list> [--note]                  → the step lint, one "<id>\tstep <n>\t<rule>\t<text>" line per finding (step "-"
//                                           for a feature's own rules), exit 1 with findings, 0 clean. Rules: no-anchor,
//                                           outside-repo, self-match, undeclared, review-small, review-missing (see
//                                           lint below). --note: the one harness-log.md line ("lint: <n> findings (…) …"
//                                           or "lint: clean"), exit 0
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
 * Pure: the step lint (decisions/2026-10-26-step-lint). Steps a verifier can't check, or can't fail:
 *   no-anchor     nothing concrete (no digit, quote, path or file name); "the suite is green" is exempt
 *   outside-repo  a path in ~, $HOME, ../ or under a system root: a session can't or mustn't use it
 *   self-match    a grep of a run-record file that quotes steps, whose pattern matches the step itself (C7-05)
 *   undeclared    a milestone after the first whose first feature has no "after" (step "-")
 *   review-small  a review feature in a milestone of one or two build features: fold it into the last one's steps
 *   review-missing a milestone of three or more build features and no review feature (on its last feature, step "-")
 * → [{ id, step, rule, text }], features in list order, each feature's steps in order, then its own rules.
 * (decisions/2026-10-26-reviews-sized-to-milestone for the last two; kinds as kindOf infers them)
 */
export const RULES = ["no-anchor", "outside-repo", "self-match", "undeclared", "review-small", "review-missing"];
const ANCHORS = [/\d/, /`[^`]+`/, /"[^"]+"/, /“[^”]+”/, /(^|\W)'[^']+'(\W|$)/, /[\w.~-]*\/[\w.-]+/, /\b[\w-]{2,}\.[A-Za-z0-9]{1,6}\b/];
// /tmp, /dev/null and web routes (GET /api/x) pass: only the roots a session has no business in trip
const OUTSIDE = [/(^|[\s`"'(=])~(\/|\s|$)/, /\$\{?HOME\b/, /(^|[\s`"'(=])\.\.\//, /(^|[\s`"'(=:])\/(home|root|srv|etc|var|opt|usr|mnt|media)\//];
// files sessions or the renderer write step text into; harness-log.md isn't one (only the driver writes it)
const quoting = t => /(^|\/)(progress\.md|progress-archive\.md|entries\.jsonl|context\.md|feature_list\.json)$/.test(t)
  || (/\.harness\/runs\//.test(t) && !/(^|\/)harness-log\.md$/.test(t));

/**
 * Pure: does a grep (egrep, fgrep, rg) in this step search a quoting file for a pattern the step's own text matches?
 * Only a grep in command position counts (the step's start, after a backtick, |, ;, &, ( or !), so prose saying
 * "grep" doesn't; a file piped in on stdin isn't seen.
 */
export function selfMatch(text) {
  for (const g of text.matchAll(/(^|[`|;&(!])\s*(e|f)?(grep|rg)\b/g)) {
    const toks = [...text.slice(g.index + g[0].length).matchAll(/"([^"]*)"|'([^']*)'|([^\s"']+)/g)]
      .map(t => ({ v: t[1] ?? t[2] ?? t[3], bare: t[3] !== undefined }));
    let flags = (g[2] ?? "").toUpperCase() + (g[3] === "rg" ? "E" : ""), pat = null;
    const targets = [];
    for (let i = 0; i < toks.length; i++) {
      const { v, bare } = toks[i];
      if (bare && /^(\||&&|;)/.test(v)) break;   // the next command in a pipeline or list
      if (bare && /^\d?>>?(&\d)?$/.test(v)) { i++; continue; }   // a redirect and its file
      if (bare && /^\d?>/.test(v)) continue;
      if (pat !== null) { targets.push(v.replace(/[`),.;:]+$/, "")); if (bare && v.endsWith("`")) break; continue; }
      if (!bare || !v.startsWith("-") || v === "-") pat = v;
      else if (v === "-e" || v === "--regexp") pat = toks[++i]?.v ?? "";
      else if (v === "-f" || v.startsWith("--file")) break;   // patterns from a file: nothing to compare
      else if (v.startsWith("--")) {
        if (/^--(max-count|(after-|before-)?context|type(-not)?|i?glob)$/.test(v)) i++;   // long options that take a value
        else flags += { "--fixed-strings": "F", "--extended-regexp": "E", "--perl-regexp": "P", "--ignore-case": "i", "--line-regexp": "x" }[v] ?? "";
      } else {
        flags += v.slice(1);
        if (/[ABCmtTgdD]$/.test(v)) i++;   // short options that take a value (grep's and rg's)
      }
    }
    if (pat === null || !targets.some(quoting)) continue;
    const ci = flags.includes("i"), x = flags.includes("x");
    const src = flags.includes("F") ? pat.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")
      : /[EP]/.test(flags) ? pat.replace(/\\[<>]/g, "\\b")
      : pat.replace(/\\([(){}|+?<>])|([(){}|+?])/g, (_, esc, bare) => esc ? (/[<>]/.test(esc) ? "\\b" : esc) : `\\${bare}`);   // BRE
    let hit;
    try { hit = new RegExp(x ? `^(?:${src})$` : src, ci ? "i" : "").test(text); }
    catch { hit = (ci ? text.toLowerCase() : text).includes(ci ? pat.toLowerCase() : pat); }   // not a JS regexp: substring
    if (hit) return true;
  }
  return false;
}

/** Pure: the review findings of each milestone, keyed by the feature they go on. */
function reviewSizing(list) {
  const out = new Map(), add = (f, rule, text) => out.set(f, [...(out.get(f) ?? []), { id: f.id, step: "-", rule, text }]);
  for (const m of new Set(list.filter(f => f.milestone).map(f => f.milestone))) {
    const fs = list.filter(f => f.milestone === m), builds = fs.filter(f => kindOf(f) === "build");
    const reviews = fs.filter(f => kindOf(f) === "review"), n = builds.length;
    if (n >= 1 && n <= 2) for (const r of reviews)
      add(r, "review-small", `${m} has ${n} build feature${n === 1 ? "" : "s"}: fold the review into ${builds[n - 1].id}'s steps`);
    if (n >= 3 && !reviews.length) add(fs[fs.length - 1], "review-missing", `${m} has ${n} build features and no review feature`);
  }
  return out;
}

export function lint(list) {
  const late = new Map(undeclared(list).map(m => [list.find(f => f.milestone === m), m])), sized = reviewSizing(list);
  return list.flatMap(f => [
    ...(Array.isArray(f.steps) ? f.steps : []).flatMap((s, i) => {
      const text = `${s}`.replace(/\s+/g, " ").trim(), at = rule => ({ id: f.id, step: i + 1, rule, text });
      return [
        !/^the suite is green\b/i.test(text) && !ANCHORS.some(r => r.test(text)) && at("no-anchor"),
        OUTSIDE.some(r => r.test(text)) && at("outside-repo"),
        selfMatch(text) && at("self-match"),
      ].filter(Boolean);
    }),
    ...(late.has(f) ? [{ id: f.id, step: "-", rule: "undeclared", text: `${late.get(f)}'s first feature has no "after": it waits on every earlier feature` }] : []),
    ...(sized.get(f) ?? []),
  ]);
}

/** Pure: the driver's one harness-log.md line for the lint's findings. */
export function lintNote(findings) {
  if (!findings.length) return "lint: clean";
  const counts = RULES.map(r => [r, findings.filter(f => f.rule === r).length]).filter(([, n]) => n).map(([r, n]) => `${r}: ${n}`);
  const [f] = findings;
  return `lint: ${findings.length} finding${findings.length === 1 ? "" : "s"} (${counts.join(", ")}); the list is not edited — first: ${f.id} step ${f.step} ${f.rule}`;
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
    case "lint": {
      const found = lint(features(a));
      if (b === "--note") { console.log(lintNote(found)); return 0; }
      for (const f of found) console.log([f.id, `step ${f.step}`, f.rule, f.text].join("\t"));
      return found.length ? 1 : 0;
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
      console.error("usage: features.mjs next|blocked|undeclared|lint|park|unpark|parked|kind|milestones|evidence|bump|snapshot|repair|repair-verify|unpass|passes|milestone|milestone-done|ids|summary …");
      return 2;
  }
}

if (process.argv[1] && fileURLToPath(import.meta.url) === resolve(process.argv[1])) process.exit(main(process.argv.slice(2)));
