// How many tests passed, from a suite's output: a HARNESS_TESTS=<n> line, else node:test, cargo, jest/vitest, go -v, pytest and similar.
//   testcount.mjs <output file> [--source]   → "<n> tests" or nothing; with --source "<n> tests · <source>" ("? tests · none")
import { readFileSync, existsSync } from "node:fs";

// { n, source }: the first rule that matches wins (decisions/2026-10-26-real-test-counts; one fixture each in
// tests/fixtures/check-*.txt). A project's check may print the contract line itself (decisions/2026-10-26-test-count-contract).
export function countSource(text) {
  // the last whole line at column 0 (a wrapper may print one after its runner's); a count past 2^53 is no count
  const contract = [...text.matchAll(/^HARNESS_TESTS=(\d+)\s*$/gm)].map(m => Number(m[1])).filter(Number.isSafeInteger);
  if (contract.length) return { n: contract.at(-1), source: "contract" };
  const node = text.match(/^(?:ℹ|#) pass (\d+)/m);
  if (node) return { n: Number(node[1]), source: "node" };
  // cargo: one line per test binary (doc-tests too), so the sum; before the generic rule, which would take the last
  const cargo = [...text.matchAll(/^test result: \w+\. (\d+) passed;/gm)];
  if (cargo.length) return { n: cargo.reduce((s, m) => s + Number(m[1]), 0), source: "cargo" };
  const jest = text.match(/^\s*Tests:\s+(?:\d+ \w+, )*(\d+) passed/m);   // the Tests: line, never Test Suites:
  if (jest) return { n: Number(jest[1]), source: "jest" };
  const go = text.match(/^\s*--- PASS: /gm);   // go test -v only: plain go test prints `ok <pkg>` per package
  if (go) return { n: go.length, source: "go" };
  const all = [...text.matchAll(/(\d+)(?:\/\d+)? (?:tests? |checks )?passed/g)];   // "12 passed", this repo's "325/326 checks passed"
  return all.length ? { n: Number(all.at(-1)[1]), source: "generic" } : { n: null, source: "none" };
}

export function testCount(text) { return countSource(text).n; }

const [f, flag] = process.argv.slice(2);
if (f && existsSync(f)) {
  const { n, source } = countSource(readFileSync(f, "utf8"));
  if (flag === "--source") console.log(`${n ?? "?"} tests · ${source}`);
  else if (n != null) console.log(`${n} tests`);
}
