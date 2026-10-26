// M6-07: compares a census take replayed into the dev Mixxx with the same take through the Node harness.
//   node .harness/runs/rane-one-mixxx-2026-10-24/checks/M6-replay-compare.mjs <take.jsonl> <mixxx-log-slice>
// The harness (RaneOne.DEBUG on) says which (group, key) each MIDI row changes; the slice of dev-profile/mixxx.log
// written during the replay says which ones Mixxx logged as `RaneOne: <group>,<key> = <value>`. Prints JSON: the
// messages sent, the distinct keys logged, ten sample lines, and per row the keys expected and whether any was
// logged. A row whose harness run changes nothing (the counted no-ops, the platter, a press Mixxx takes as no
// change) is listed as `quiet`; a row with expected keys and none logged is a `gap`.
import { readFileSync } from "node:fs";
import vm from "node:vm";
import { loadMapping } from "../../../../tests/helpers/fake-mixxx.mjs";

const [take, slice] = process.argv.slice(2);
if (!take || !slice) { console.error("usage: M6-replay-compare.mjs <take.jsonl> <mixxx-log-slice>"); process.exit(2); }

const h = loadMapping();
if (h.skip) { console.error(h.skip); process.exit(1); }
// The dev Mixxx has 8 samplers (its log connects [Sampler1]..[Sampler8]); the fake's num_samplers is 0 otherwise.
h.setValue("[App]", "num_samplers", 8);
vm.runInContext("RaneOne.DEBUG = true; RaneOne.init('debug')", h.ctx);
const connected = new Set(h.connections.filter((c) => c.isConnected).map((c) => `${c.group},${c.key}`));
const rowOf = (s, d1) => {
  const kind = (s & 0xf0) === 0x80 ? 0x90 : s & 0xf0;
  return `${kind.toString(16)} ch${(s & 0x0f) + 1} ${kind === 0xe0 ? "bend" : d1}`;
};
const rows = new Map(); // row → { messages, expected: Set, handlers: Set }
const handlersOf = (s, d1) => h.controls.filter((c) => c.status === s && ((s & 0xf0) === 0xe0 || c.midino === d1)).map((c) => c.key);
let sent = 0, last;
for (const line of readFileSync(take, "utf8").split("\n")) {
  if (!line.trim()) continue;
  const rec = JSON.parse(line);
  const [s, d1] = rec.bytes.match(/../g).map((b) => parseInt(b, 16));
  if (s >= 0xf0) continue;
  if (last !== undefined && rec.t_us > last) h.tick((rec.t_us - last) / 1000);
  last = rec.t_us;
  const n = { sets: h.sets.length, params: h.params.length };
  h.dispatch(rec);
  sent++;
  const row = rows.get(rowOf(s, d1)) ?? { messages: 0, expected: new Set(), handlers: new Set() };
  row.messages++;
  for (const k of handlersOf(s, d1)) row.handlers.add(k);
  for (const [g, k] of [...h.sets.slice(n.sets), ...h.params.slice(n.params)]) {
    if (connected.has(`${g},${k}`)) row.expected.add(`${g},${k}`);
  }
  rows.set(rowOf(s, d1), row);
}

const lines = readFileSync(slice, "utf8").split("\n").filter((l) => /RaneOne: \[[^,]*\],\S+ = /.test(l));
const logged = new Set(lines.map((l) => l.match(/RaneOne: (\[[^,]*\],\S+) = /)[1]));
const step = Math.max(1, Math.floor(lines.length / 10));
const out = {
  take: take.split("/").pop(), sent, logLines: lines.length, distinctLogged: logged.size,
  samples: lines.filter((_, i) => i % step === 0).slice(0, 10).map((l) => l.replace(/^.*?(RaneOne: )/, "$1")),
  rows: [...rows].sort().map(([row, r]) => {
    const expected = [...r.expected].sort();
    const hit = expected.filter((k) => logged.has(k));
    return { row, messages: r.messages, handlers: [...r.handlers].sort(), expected, logged: hit, status: !expected.length ? "quiet" : hit.length ? "ok" : "gap" };
  }),
};
out.expectedNotLogged = [...new Set(out.rows.flatMap((r) => r.expected.filter((k) => !logged.has(k))))].sort();
out.loggedNotExpected = [...logged].filter((k) => !out.rows.some((r) => r.expected.includes(k))).sort();
console.log(JSON.stringify(out, null, 1));
