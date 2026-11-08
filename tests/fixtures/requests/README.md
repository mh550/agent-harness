# Request fixtures (lib/requests.mjs, tests/unit/requests.test.mjs)

Made on 2026-11-07 (A3-02) by n8n-home's own `buildRequest` (`lib/card.js`) at 859b25a, its `lib/memory.js`,
`lib/report.js` and `lib/card.js` loaded read-only into one `vm` context as its `tests/unit/card.test.mjs` does, and
written `JSON.stringify(request) + "\n"` in one write, as its D25 writes `<STATE_ROOT>/requests/<id>.json`. A test
that needs another shape changes a value of one of these (`id`, `run`, `text`, `v`, `verb`), never a hand-typed shape.

- `answer.json` · `{ verb: "answer", run: "parked", text: "Use the default.", source: "n8n-card", event: null, at: "2026-10-28T00:00:00.000Z" }`, id `req-0001-aaaa`
- `continue.json` · `{ verb: "continue", run: "stopped", source: "n8n-card", event: null, at }`, id `req-0002-bbbb`
- `continue-brief.json` · the same with `brief: "Finish B3 first."`, id `req-0003-cccc` (n8n puts `brief` after `run`)

The command, from n8n-home's root (`out` an empty directory):

```js
// node make.mjs <n8n-home> <out>
import { readFileSync, writeFileSync } from "node:fs";
import vm from "node:vm";
const [root, out] = process.argv.slice(2);
const read = rel => readFileSync(`${root}/${rel}`, "utf8");
const c = vm.runInNewContext(`${read("lib/memory.js")}\n${read("lib/report.js")}\n${read("lib/card.js")}\n({buildRequest})`);
const at = "2026-10-28T00:00:00.000Z";
const w = (n, r) => writeFileSync(`${out}/${n}.json`, `${JSON.stringify(r)}\n`);
w("answer", c.buildRequest({ verb: "answer", run: "parked", text: "Use the default.", source: "n8n-card", event: null, at }, "req-0001-aaaa"));
w("continue", c.buildRequest({ verb: "continue", run: "stopped", source: "n8n-card", event: null, at }, "req-0002-bbbb"));
w("continue-brief", c.buildRequest({ verb: "continue", run: "stopped", brief: "Finish B3 first.", source: "n8n-card", event: null, at }, "req-0003-cccc"));
```
