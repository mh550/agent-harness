// The coverage tool's node sample (tests/unit/coverage.test.mjs): a called function with a branch not taken, functions
// never called in each shape a declaration takes, a callback in a call that ran, an else never taken.
// tests/fixtures/coverage/v8.json is node's own NODE_V8_COVERAGE document for `pick(1); sign(1)`, this box's path replaced by /ROOT.
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
const label = a =>
  a.map(x => x.name).join("; ");
export const io = {
  get first() { return 1; },
  second: () => 2,
  third: [].map(x => x * 2),
};
export function sign(n) {
  if (n > 0) {
    return 1;
  } else {
    return -1;
  }
}
