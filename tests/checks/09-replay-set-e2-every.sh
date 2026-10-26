#!/usr/bin/env bash
source "$(dirname "$0")/../lib.sh" && suite_setup
# ---- the replay set (E2): every committed task validates; each error names its field ----
EVTK='import { validateTask as v } from "'$HERE'/../lib/eval.mjs"; const has = (e, f) => e.some(x => x.startsWith(f + ":"));
  const ok = { id: "x1", project: "p", repo: "~/projects/p", base: "a".repeat(40), policy: "build-only", why: "w",
    features: [{ id: "X1", milestone: "X", description: "d", steps: ["s"] }] }, { features, ...nofeat } = ok;
  process.exit(v(ok).length === 0 && v(nofeat).length === 1 && has(v(nofeat), "features") && has(v({ ...ok, policy: "live-staged" }), "policy")
    && has(v({ ...ok, base: "abc123" }), "base") && has(v({ ...ok, features: Array(4).fill(features[0]) }), "features")
    && has(v({ ...ok, features: [{ ...features[0], steps: [] }] }), "features[0].steps") && has(v({ ...ok, chek_cmd: "x" }), "chek_cmd") ? 0 : 1);'
mkdir -p "$T/evbad/nofeat" && jq -n '{id:"nofeat",project:"p",repo:"/r",base:("a"*40),policy:"build-only",why:"w"}' > "$T/evbad/nofeat/task.json"
check "eval: every task.json validates and a bad one is rejected" 'node --input-type=module -e "$EVTK" && node "$HERE/../lib/eval.mjs" validate "$HERE/../evals/tasks" 2> /dev/null \
  && ! node "$HERE/../lib/eval.mjs" validate "$T/evbad" > "$T/evbad.out" 2>&1 && grep -q "nofeat/task.json: features: required" "$T/evbad.out" \
  && [[ -z $(grep -v "^#" "$HERE/../evals/sets/default.txt" | while read -r t; do [[ -f "$HERE/../evals/tasks/$t/task.json" ]] || echo "$t"; done) ]]'
# compare (E2-05): noise is the spread across a task's repeats; B is judged against A, in each metric's direction;
# pass rate is pass^N (w passed once in two: 0), a started run without a summary ({ missing }) a failed one; the totals
# use only the repeats every task has, and per verified feature is the sums over tasks / their verified features
EVCMP='import { compare as c, completeRepeats as cr } from "'$HERE'/../lib/eval.mjs";
  const s = (pass, cost, hit = 0.5) => { const ver = pass ? 2 : 1; return { features: { total: 2, verified: ver }, cost: { total: cost * ver }, per_verified_feature: { cost, tokens: 1000 / ver },
    tokens: { in: 900, cache_read: 50, cache_write: 50, out: 0, cache_hit_rate: hit, context_peak: 100 }, orientation: { tokens: 10 }, time: { wall_h: 1 }, rework: [] }; };
  const A = { tasks: { x: [s(1, 1.0), s(1, 1.4)], y: [s(0, 2.0), s(0, 2.1)], z: [s(1, 1.0, 0.5), s(1, 1.1, 0.5)], w: [s(1, 1), s(0, 1)], a: [s(1, 1)] } };
  const B = { tasks: { x: [s(1, 1.2), s(1, 1.3)], y: [s(1, 1.0), s(1, 1.1)], z: [s(0, 2.0, 0.8), s(0, 2.1, 0.8)], w: [s(1, 1), s(1, 1)], b: [s(1, 1)] } };
  const get = (rows, t, m) => rows.find(x => x.task === t && x.metric === m), r = c(A, B), v = (t, m) => get(r, t, m)?.verdict, one = c({ tasks: { x: [s(1, 1)] } }, B);
  const nul = { ...s(1, 1), per_verified_feature: { cost: null, tokens: null } }, pv = (a) => get(c({ tasks: { x: a } }, B), "x", "$ per verified feature").verdict, tot = get(r, "total", "pass rate");
  const sums = { tasks: { p: [s(1, 1), s(1, 1)], q: [s(0, 4), s(0, 4)] } }, P = { tasks: { x: [s(1, 1), s(0, 1)], y: [s(1, 1)] } }, pp = c(P, P), crash = get(c({ tasks: { x: [s(1, 1), { missing: true }] } }, B), "x", "pass rate");
  process.exit(v("x", "$ per verified feature") === "within noise" && v("x", "pass rate") === "within noise"
    && v("y", "$ per verified feature") === "better" && v("y", "pass rate") === "better" && v("z", "$ per verified feature") === "worse" && v("z", "pass rate") === "worse"
    && v("z", "cache hit rate") === "better" && r.filter(x => x.task === "x").length === 8 && !r.some(x => x.task === "a" || x.task === "b")
    && v("x", "rework") === "within noise" && one.every(x => x.verdict === "one sample") && pv([nul, s(1, 1)]) === "one sample" && pv([nul, nul]) === "no data"
    && get(r, "w", "pass rate").a === 0 && v("w", "pass rate") === "within noise"
    && tot.a === 0.5 && tot.b === 0.75 && tot.verdict === "within noise" && r.filter(x => x.task === "total").length === 8
    && get(c(sums, sums), "total", "$ per verified feature").a === 2 && get(c(sums, sums), "total", "tokens per verified feature").a === 2000 / 3
    && JSON.stringify(cr(P, ["x", "y"])) === "[0]" && JSON.stringify(cr(P, [])) === "[]" && get(pp, "total", "pass rate").a === 1 && get(pp, "total", "pass rate").verdict === "one sample"
    && crash.a === 0 && JSON.stringify(crash.a_values) === "[1,0]" ? 0 : 1);'
check "eval.mjs: compare verdicts" 'node --input-type=module -e "$EVCMP"'
# a repeat that verified nothing still spent: per verified feature is Σ / Σ verified over every repeat, not a mean that
# drops it; an empty feature list is no pass (E2 review)
EVPV='import { compare as c, compareText as ct } from "'$HERE'/../lib/eval.mjs";
  const s = (cost, ver) => ({ features: { total: 1, verified: ver }, cost: { total: cost }, per_verified_feature: { cost: ver ? cost / ver : null, tokens: ver ? 1000 / ver : null },
    tokens: { in: 1000, cache_read: 0, cache_write: 0, out: 0 } });
  const r = c({ tasks: { x: [s(2, 1), s(2, 1), s(2, 1)] } }, { tasks: { x: [s(1, 1), s(1.1, 1), s(20, 0)] } }), get = (t, m) => r.find(x => x.task === t && x.metric === m);
  const t = ct({ tasks: { x: [s(2, 1), s(2, 1), s(2, 1)] } }, { tasks: { x: [s(1, 1), s(1.1, 1), s(20, 0)] } }).text;
  const near = (row, v) => Math.abs(row.b - v) < 1e-9 && row.verdict === "worse";
  const e = c({ tasks: { x: [{ features: { total: 0, verified: 0 } }] } }, { tasks: { x: [s(1, 1)] } }).find(x => x.task === "x" && x.metric === "pass rate");
  process.exit(near(get("x", "$ per verified feature"), 11.05) && near(get("total", "$ per verified feature"), 11.05)
    && near(get("x", "tokens per verified feature"), 1500) && near(get("total", "tokens per verified feature"), 1500) && e.a === 0
    && t.split("\n").includes("B: x r3 verified nothing ($20.00 spent): counted in per verified feature, not in its noise") ? 0 : 1);'
check "eval.mjs: per verified feature counts every repeat's cost (E2 review)" 'node --input-type=module -e "$EVPV"'

suite_end
