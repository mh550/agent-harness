// How many tests passed, from a suite's output: node:test, pytest, jest/vitest and similar. Prints "<n> tests" or nothing.
//   testcount.mjs <output file>
import { readFileSync, existsSync } from "node:fs";

export function testCount(text) {
  const node = text.match(/^(?:ℹ|#) pass (\d+)/m);
  if (node) return Number(node[1]);
  const all = [...text.matchAll(/(\d+)(?:\/\d+)? (?:tests? |checks )?passed/g)];   // "12 passed", this repo's "325/326 checks passed"
  return all.length ? Number(all.at(-1)[1]) : null;
}

const f = process.argv[2];
if (f && existsSync(f)) { const n = testCount(readFileSync(f, "utf8")); if (n != null) console.log(`${n} tests`); }
