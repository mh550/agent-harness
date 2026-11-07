// The suite runner's decisions (lib/check.sh): what a red exit means, whether a marker answers, whether a partial run may stand for the full one, whether to rerun, whether a red is cached.
//   node lib/checkdecide.mjs before <cache> <0|1 fast> <tree-key line>… | guard <7 facts> <rerun> <out> | last <7 facts> <first> <rc0> <key> | why <7 facts>
//   the 7 facts: <rc> <seconds> <own seconds> <timeout> <its seconds, or 0> <capped 0|1> <memory cap>. Every answer but why's is labelled lines, `<label> <value>`.
// Flow and output stay in check.sh: this answers a branch and its values. The tables mirror bash's reads (read -r's trim, mapfile -t's lines).
import { readFileSync, statSync } from "node:fs";
import { join } from "node:path";
import { captured, isMain, runCli } from "./cli.mjs";
import { mapNames } from "./treekey.mjs";

const isKey = k => /^[0-9a-f]{16}$/.test(k);
// what `read -r` leaves of a line: IFS's outer blanks go (never .trim(): a no-break space and a CR stay)
const trimRead = l => l.replace(/^[ \t]+|[ \t]+$/g, "");
// mapfile -t: a final newline ends the last line, it doesn't start another
const linesOf = text => { const l = text.split("\n"); if (l.at(-1) === "") l.pop(); return l; };

// GNU timeout exits 137, not 124, when it had to KILL, so a 137 whose own seconds reach the limit is the timeout; a 137
// whose scope peaked at its cap is the kernel's kill there. line is what the RED line says.
export function redReason({ rc, seconds, own, to, limit, capped, max }) {
  if (rc === 124 || (rc === 137 && limit > 0 && own >= limit)) return { kind: "timeout", line: `timed out after ${to}, exit ${rc} after ${seconds} s` };
  if (rc === 137 && capped) return { kind: "cap", line: `killed at its ${max} memory cap, exit 137 after ${seconds} s` };
  return { kind: "exit", line: `exit ${rc} after ${seconds} s` };
}

// The markers' texts, or null for none: a full verdict stands for the fast tier too, so green, then red, then fast.
// green-<key>: the count on line 1 (older markers are empty). red-<key>: exit code, names, wall, the RED line; a marker
// caught mid-write (or planted) is still a red.
export function cachedAnswer({ key, fast, green, red, fastMarker }) {
  if (!isKey(key)) return { answer: "run" };
  const count = text => trimRead(text.split("\n")[0]);
  if (green !== null) return { answer: "green", n: count(green) };
  if (red !== null) {
    const [rc = "", names = "", , line = ""] = red.split("\n").map(trimRead);
    return { answer: "red", rc: /^[1-9][0-9]*$/.test(rc) ? rc : "1", names, line };
  }
  if (fast && fastMarker !== null) return { answer: "fast", n: count(fastMarker) };
  return { answer: "run" };
}

// the `<blob> <path>` lines as path → blob; null on a malformed line or a path twice (no set)
const blobMap = lines => {
  const m = new Map();
  for (const l of lines) {
    const x = /^([0-9a-f]{40}|[0-9a-f]{64}|-) ([^ ]+)$/.exec(l);
    if (!x || m.has(x[2])) return null;
    m.set(x[2], x[1]);
  }
  return m;
};

// Whether a partial run may stand for the full one: the invariant is that a tree is never marked green by anything but a
// green run of every check that reads what changed in it, so any doubt refuses, and the full run runs. map: the exported
// CHECK_KEY_MAP; blobs: this tree's `<blob> <path>` lines; reduced: its key without the mapped paths; sidecar: part-<reduced>'s
// text or null; refGreen: whether green-<its first line> exists; entries: the map's { path, names }. The rows are of
// docs/plans/2026-10-30-S2-partial-key.md §3; row 4a, only the tree's own map may choose, is check.sh's: only a shell can
// source the tree's config, so it comes last there (any refusal runs in full, so the order doesn't show).
export function partialPlan({ map, blobs, reduced, sidecar, refGreen, entries }) {
  const no = row => ({ go: false, row });
  if (!/[^ \t\n\v\f\r]/.test(map) || !blobs.length || !isKey(reduced)) return no("4");   // no map (treekey prints none either while the config is outside the key)
  if (sidecar === null) return no("5");   // no green full run of a tree with these unmapped paths
  const [ref = "", ...sides] = linesOf(sidecar);
  if (!isKey(ref) || !refGreen) return no("6");   // the reference is gone (run_init fresh, a new cache)
  const was = blobMap(sides), now = blobMap(blobs);
  if (!was || !now || was.size !== now.size || [...now.keys()].some(p => !was.has(p))) return no("7");   // the path sets
  const paths = [...now.keys()].filter(p => was.get(p) !== now.get(p));
  if (!paths.length) return no("8");   // nothing mapped differs (the full key would have matched)
  const names = mapNames(entries, paths);
  if (!names) return no("9");   // a path no entry's
  if (!names.length) return no("10");   // no name
  return { go: true, ref, names };
}

// Once more by CHECK_RERUN, never after a timeout or a cap kill (a rerun would cost the whole timeout again, or be killed
// again): "failed", the HARNESS_FAILED= names; "suite", the rest; "" none. An unknown setting is auto: one wasted rerun at worst.
export function rerunChoice({ rerun, names, kind }) {
  if (kind !== "exit" || rerun === "off") return "";
  if (rerun === "suite") return "suite";
  if (names.length) return "failed";
  return rerun === "failed" ? "" : "suite";
}

// A red is cached only when neither run was a timeout (the box's load), a cap kill (the scope's) or a signal's code (a
// kill the scope didn't see, a TERM: the box's, not the tree's): those the next call runs.
export const keepRed = ({ key, first, last, rc0, rc }) => !!key && first.startsWith("exit ") && last.startsWith("exit ") && rc0 < 128 && rc < 128;

// the names on an output's last HARNESS_FAILED= line (a whole line's start, as the runner prints it)
export function failedNames(text) {
  const hit = text.split("\n").findLast(l => l.startsWith("HARNESS_FAILED="));
  return hit === undefined ? [] : hit.slice("HARNESS_FAILED=".length).split(/[ \t]+/).filter(Boolean);
}

const textOf = p => { try { return statSync(p).isFile() ? readFileSync(p, "utf8") : null; } catch { return null; } };

// a full or --fast call's one question before it runs anything: the markers, then (a full call) the partial table
function before([cache, fast, ...tk], env) {
  const [key = "", reduced = "", ...rest] = tk, marker = name => textOf(join(cache, name));
  const c = cachedAnswer({ key, fast: fast === "1", green: marker(`green-${key}`), red: marker(`red-${key}`), fastMarker: marker(`fast-${key}`) });
  if (c.answer !== "run" || fast === "1" || !isKey(key)) return c;
  const sidecar = isKey(reduced) ? marker(`part-${reduced}`) : null, ref = linesOf(sidecar ?? "")[0] ?? "";
  const p = partialPlan({ map: env.HARNESS_CHECK_KEY_MAP ?? "", blobs: rest.filter(l => !l.startsWith(": ")), reduced, sidecar,
    refGreen: isKey(ref) && marker(`green-${ref}`) !== null,
    entries: rest.filter(l => l.startsWith(": ")).map(l => { const [path, ...names] = l.slice(2).split(/[ \t]+/).filter(Boolean); return { path, names }; }) });
  return p.go ? { answer: "partial", ref: p.ref, names: p.names.join(" ") } : { answer: "run", row: p.row };
}

const reason = ([rc, seconds, own, to, limit, capped, max]) =>
  redReason({ rc: +rc, seconds, own: +own, to, limit: +limit, capped: capped === "1", max });

export const main = captured((args, io, say) => {
  const [q, ...a] = args, labelled = o => Object.entries(o).forEach(([k, v]) => say(`${k} ${v}`));
  const env = io.env ?? process.env;
  if (q === "before") { labelled(before(a, env)); return 0; }
  if (q === "why") { say(reason(a).line); return 0; }
  if (q === "guard") {
    const [rerun, out] = a.slice(7), r = reason(a), names = failedNames(textOf(out) ?? "");
    labelled({ first: r.line, how: rerunChoice({ rerun, names, kind: r.kind }), names: names.join(" ") });
    return 0;
  }
  if (q === "last") {
    const [first, rc0, key] = a.slice(7), last = reason(a).line;
    labelled({ last, keep: keepRed({ key, first, last, rc0: +rc0, rc: +a[0] }) ? 1 : 0 });
    return 0;
  }
  console.error("usage: checkdecide.mjs before <cache> <0|1 fast> <tree-key line>… | guard <7 facts> <rerun> <out> | last <7 facts> <first> <rc0> <key> | why <7 facts>");
  return 2;
});

if (isMain(import.meta.url)) runCli(main);
