// The coverage tool's node sample (tests/unit/coverage.test.mjs): a called function with a branch not taken, a
// one-line function never called, and a function never called. tests/fixtures/coverage/v8.json is node's own
// NODE_V8_COVERAGE document for `pick(1)`, this box's path replaced by /ROOT.
export const twice = n => n * 2;
export function pick(n) {
  if (n > 5) {
    return "big";
  }
  const kind = n === 1 ? "one" : "other";
  return kind;
}
export function never() {
  return 0;
}
