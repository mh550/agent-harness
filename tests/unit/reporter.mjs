// The unit tier's node:test reporter: a PASS/FAIL line per test, as tests/run.sh reads them (decisions/2026-11-03-unit-tier).
//   node --test --test-reporter=./tests/unit/reporter.mjs --test-reporter-destination=stdout …   → `PASS <name>`, or
//   `FAIL <name>` then the failure's message (the node:assert diff) indented two spaces, and last, once node's run
//   is complete, `# unit tier: <n> tests` (00-unit-tier.sh requires it, counts against it and drops it); nothing else
// Tests are flat (no describe, no subtests): a test's own name is its check name in tests/fixtures/check-names.txt.
// A skipped test keeps its name with the suffix the runner strips (`PASS <name> (skipped: <reason>)`).
const indent = s => s.replace(/\n+$/, "").split("\n").map(l => `  ${l}`).join("\n") + "\n";
// the error a failing test threw (node wraps it in ERR_TEST_FAILURE): an assertion's message is its diff; anything
// else (a TypeError, a throw at import) its stack without node's own frames, so the line it came from shows
const why = err => {
  const e = err?.cause ?? err;
  return e?.code === "ERR_ASSERTION" ? e.message : String(e?.stack ?? e).split("\n").filter(l => !/^\s+at .*\(?node:/.test(l)).join("\n");
};
export default async function* reporter(source) {
  for await (const { type, data } of source) {
    if (type === "test:pass") yield `PASS ${data.name}${data.skip ? ` (skipped: ${data.skip === true ? "skip" : data.skip})` : ""}\n`;
    else if (type === "test:fail") yield `FAIL ${data.name}\n${indent(why(data.details?.error))}`;
    // the run's own summary (a file's has data.file): missing when a process.exit cut the run short
    else if (type === "test:summary" && !data.file) yield `# unit tier: ${data.counts.tests} tests\n`;
  }
}
