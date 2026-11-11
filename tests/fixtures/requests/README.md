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

## v2: the card's merge and close (V2-01, docs/specs/2026-11-10-review-surface.md)

n8n-home's `buildRequest` has no v2 branch yet, so these are made here and n8n-home builds to them: the requests its card
will write for a memory PR's two actions, in the key order `v,id,at,verb,run,pr[,why],source,event`, written
`JSON.stringify(request) + "\n"` in one write as above. `tests/unit/requests.test.mjs` runs the block below into an empty
directory and compares the bytes, so a fixture and its command never differ. A test that needs another shape changes a
value (`id`, `run`, `pr`, `why`, `v`, `verb`) with jq or a spread, never a hand-typed shape. Their reader outside this
repo is n8n-home: `docs/2026-11-10-review-surface-n8n-home.md`, the checklist its session builds the card from,
names the three requests and `result-v2.json` by path (`tests/checks/memory-requests.sh` keeps every path it names real).

- `merge.json` · `{ v: 2, verb: "merge", run: "r1", pr: "https://example.test/pr/1", source: "n8n-card", event: null, at: "2026-11-10T00:00:00.000Z" }`, id `req-0101-merge`: run r1's facts PR, as tests/stub-gh.sh names a PR
- `close.json` · `{ v: 2, verb: "close", run: "r1", pr: "https://example.test/pr/2", source, event, at }`, id `req-0102-close`: its rules PR, no why
- `close-why.json` · `{ v: 2, verb: "close", run: "r1", pr: "https://example.test/pr/1", why: "These facts are already in the README.", source, event, at }`, id `req-0103-cwhy`: the facts PR closed with a reason (`why` after `pr`)
- `result-v2.json` · the stdout of `node lib/requests.mjs result --id req-0101-merge --verb merge --run r1 --ok 1 --exit 0 --output <empty file> --runner-started 0 --pr https://example.test/pr/1 --state merged --now 1794268800 --log <file>` (2026-11-10T00:00:00Z), copied from the unit test's run: the v2 result's twelve keys

```js
// node make-v2.mjs <out>
import { writeFileSync } from "node:fs";
const [out] = process.argv.slice(2);
const at = "2026-11-10T00:00:00.000Z", run = "r1", facts = "https://example.test/pr/1", rules = "https://example.test/pr/2";
const req = (id, verb, pr, why) => ({ v: 2, id, at, verb, run, pr, ...why === undefined ? {} : { why }, source: "n8n-card", event: null });
const w = (n, r) => writeFileSync(`${out}/${n}.json`, `${JSON.stringify(r)}\n`);
w("merge", req("req-0101-merge", "merge", facts));
w("close", req("req-0102-close", "close", rules));
w("close-why", req("req-0103-cwhy", "close", facts, "These facts are already in the README."));
```
