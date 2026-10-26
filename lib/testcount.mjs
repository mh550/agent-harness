// How many tests passed, from a suite's output: node:test, cargo, jest/vitest, go -v, pytest and similar. Prints "<n> tests" or nothing.
//   testcount.mjs <output file>
import { readFileSync, existsSync } from "node:fs";

// The first rule that matches wins (decisions/2026-10-26-real-test-counts; one fixture each in tests/fixtures/check-*.txt).
export function testCount(text) {
  const node = text.match(/^(?:ℹ|#) pass (\d+)/m);
  if (node) return Number(node[1]);
  // cargo: one line per test binary (doc-tests too), so the sum; before the generic rule, which would take the last
  const cargo = [...text.matchAll(/^test result: \w+\. (\d+) passed;/gm)];
  if (cargo.length) return cargo.reduce((s, m) => s + Number(m[1]), 0);
  const jest = text.match(/^\s*Tests:\s+(?:\d+ \w+, )*(\d+) passed/m);   // the Tests: line, never Test Suites:
  if (jest) return Number(jest[1]);
  const go = text.match(/^\s*--- PASS: /gm);   // go test -v only: plain go test prints `ok <pkg>` per package
  if (go) return go.length;
  const all = [...text.matchAll(/(\d+) (?:tests? )?passed/g)];
  return all.length ? Number(all.at(-1)[1]) : null;
}

const f = process.argv[2];
if (f && existsSync(f)) { const n = testCount(readFileSync(f, "utf8")); if (n != null) console.log(`${n} tests`); }
