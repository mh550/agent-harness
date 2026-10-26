#!/usr/bin/env bash
source "$(dirname "$0")/../lib.sh" && suite_setup
# ---- deploy guards, pure and `harness init` (E0b): run branches never build on Vercel or Netlify ----
DEPL='import { addVercelGuard as av, vercelGuarded as vg, addNetlifyGuard as an, netlifyGuarded as ng, vercelDeployments as vd, vercelMergeable as vm, slug } from "'$HERE'/../lib/deploy.mjs";
  import { readFileSync } from "node:fs"; const dep = readFileSync("'$HERE'/fixtures/gh-deployments.json", "utf8");
  const a = av("{\"framework\":\"nextjs\"}"), b = av(null), c = av("{\"git\":{\"deploymentEnabled\":{\"main\":true}}}"), off = "{\"git\":{\"deploymentEnabled\":false}}";
  const toml = "[build]\n  command = \"make\"\n\n[build.environment]\n  NODE_VERSION = \"20\"\n", t = an(toml), e = an("[build.environment]\n  X = \"1\"\n"), own = an("[build]\n  ignore = \"git diff --quiet\"\n");
  process.exit(Object.keys(JSON.parse(a)).join() === "framework,git" && JSON.parse(a).git.deploymentEnabled["harness/**"] === false && vg(a) && !vg("{\"framework\":\"nextjs\"}")
    && b === "{\n  \"git\": {\n    \"deploymentEnabled\": {\n      \"harness/**\": false\n    }\n  }\n}\n" && JSON.parse(c).git.deploymentEnabled.main === true && vg(c) && av(off) === off && vg(off) && vg(av("{\"git\":{\"deploymentEnabled\":true}}"))
    && t.how === "added" && t.text.startsWith("[build]\n  ignore = \"case \\\"$BRANCH\\\" in harness/*) exit 0;; esac; exit 1\"\n  command = \"make\"\n") && t.text.includes("[build.environment]\n  NODE_VERSION = \"20\"") && ng(t.text) && !ng(toml)
    && e.how === "added" && e.text.startsWith("[build.environment]\n  X = \"1\"\n") && /\n\[build\]\n  ignore = /.test(e.text) && ng(e.text) && !ng("[build.environment]\n  ignore = \"harness/\"\n")
    && own.how === "own-ignore" && own.text === "[build]\n  ignore = \"git diff --quiet\"\n" && an(t.text).how === "kept" && an(null).how === "added" && ng(an(null).text)
    && !vd(dep) && vd(dep.replace("\"octocat\"", "\"vercel[bot]\"")) && !vd("[]") && !vd("not json")
    && slug("git@github.com:o/r.git") === "o/r" && slug("https://github.com/o/r") === "o/r" && slug("/tmp/origin.git") === null
    && an("[ build ]\n  command = \"make\"\n").text.startsWith("[ build ]\n  ignore = ") && an("build = { command = \"make\" }\n").how === "by-hand" && an("build.command = \"make\"\n").how === "by-hand"
    && an("[build]\n  \"ignore\" = \"exit 1\"\n").how === "own-ignore" && !ng("[build]\n  ignore = \"git diff --quiet HEAD^ HEAD -- packages/harness/\"\n")
    && !vd(dep.replaceAll("octocat/example", "octocat/vercel-clone")) && !vg("{\"git\":{\"deploymentEnabled\":{\"**\":true,\"harness/**\":false}}}")
    && !vg("{\"git\":{\"deploymentEnabled\":{\"harness/*\":true,\"harness/**\":false}}}") && vg("{\"git\":{\"deploymentEnabled\":{\"main\":true,\"feature/**\":true,\"harness/**\":false}}}")
    && !vm("[]") && !vm("null") && !vm("{\"git\":\"x\"}") && vm("{}") && vm("{\"git\":{}}") ? 0 : 1);'
check "deploy.mjs: vercel and netlify guards merge, keep keys and detect" 'node --input-type=module -e "$DEPL"'
DREV='import { vercelGuarded as vg, addNetlifyGuard as an, netlifyGuarded as ng, NETLIFY_IGNORE as NI } from "'$HERE'/../lib/deploy.mjs";
  const ctx = "[build]\n" + NI + "\n\n[context.deploy-preview]\n  ignore = \"exit 1\"\n";
  process.exit(!vg("{\"git\":{\"deploymentEnabled\":{\"harness/**\":false,\"harness/agent-*\":true}}}") && !ng(ctx) && an(ctx).how === "own-ignore"
    && ng("[build]\n" + NI + "\n\n[context.production]\n  command = \"make\"\n") && ng("[build]\n" + NI + "\n\n[context.production]\n  ignore = \"git diff --quiet\"\n")
    && ng("[build]\n" + NI + "\n\n[context.deploy-preview.environment]\n  ignore = \"1\"\n") && !ng("[build]\n" + NI + "\n\n[context.\"harness/x\"]\n  ignore = \"exit 1\"\n")
    && (r => r.how === "own-ignore" && r.text.startsWith("[build]\n" + NI + "\n  command"))(an("[build]\n  command = \"make\"\n\n[context.branch-deploy]\n  ignore = \"exit 1\"\n")) ? 0 : 1);'
check "deploy.mjs: a true harness/ key or a context ignore isn't guarded (E1 review)" 'node --input-type=module -e "$DREV" \
  && echo "{\"git\":{\"deploymentEnabled\":{\"harness/**\":false,\"harness/*\":true}}}" > "$T/vover.json" && [[ $(node "$HERE/../lib/deploy.mjs" vercel-guard "$T/vover.json") == by-hand ]]'
SREV='import { redSuite, failedRecheck } from "'$HERE'/../lib/summary.mjs";
  const h = "- 2026-10-21 12:00 · 11 un-passed: suite red after the session\n- 2026-10-21 12:05 · verify M1: A failed the re-check, back in the queue\n";
  process.exit(!redSuite(h, "1") && redSuite(h, "11") && !redSuite(h, "c++") && !redSuite(h, "auth(x") && failedRecheck(h, "A") && !failedRecheck(h, "c++") && !failedRecheck(h, "1") ? 0 : 1);'
check "summary.mjs: cause and rework read the log by exact id (E1 review)" 'node --input-type=module -e "$SREV"'
# memory peaks (L1-04): a 12th append argument, and report's section from the metrics rows beside summary.json
MPEAK='import { metricsRow, outcome } from "'$HERE'/../lib/metrics.mjs";
  const r = p => metricsRow(outcome([]), ["s", "o", "run", "coding", "A", "opus", "true", "10", "0", "false", "build", p]).mem_peak_mb;
  process.exit(r("2048") === 2048 && r("") === null && r("null") === null && r(undefined) === null ? 0 : 1);'
check "metrics.mjs: append writes mem_peak_mb as a number or null" 'node --input-type=module -e "$MPEAK"'
RPEAK='import { build, report } from "'$HERE'/../lib/summary.mjs";
  const s = build("/nonexistent/p/w", "r", "/nonexistent/s"), keys = JSON.stringify(Object.keys(s));
  const rows = [{ kind: "coding", feature: "A", model: "opus", mem_peak_mb: 1500 }, { kind: "coding", feature: "B", model: "sonnet", mem_peak_mb: 2500 },
    { kind: "init", role: "init", feature: null, model: "opus", mem_peak_mb: null }];
  const R = report(s, rows), none = report(s, rows.slice(0, 1)) + report(s);
  process.exit(R.includes("\n### Memory peaks over 2 GB\n\n- B · sonnet · 2500 MB") && !R.includes("1500") && !/Memory peaks/.test(none)
    && JSON.stringify(Object.keys(build("/nonexistent/p/w", "r", "/nonexistent/s"))) === keys && !/mem|peak_mb/.test(keys) ? 0 : 1);'
check "summary.mjs: report lists only the sessions over 2 GB" 'node --input-type=module -e "$RPEAK"'

suite_end
