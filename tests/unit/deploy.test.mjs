// lib/deploy.mjs: the Vercel and Netlify guards that keep run branches from building, and the deployments read.   node --test tests/unit/deploy.test.mjs
import { test } from "node:test";
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { addVercelGuard as av, vercelGuarded as vg, addNetlifyGuard as an, netlifyGuarded as ng, vercelDeployments as vd, vercelMergeable as vm, slug, NETLIFY_IGNORE as NI } from "../../lib/deploy.mjs";

const esc = x => x.replace(/[.*+?^${}()|[\]\\]/g, "\\$&"), starts = x => new RegExp("^" + esc(x)), lit = x => new RegExp(esc(x));

test("deploy.mjs: vercel and netlify guards merge, keep keys and detect", () => {
  const dep = readFileSync(new URL("../fixtures/gh-deployments.json", import.meta.url), "utf8");
  const a = av("{\"framework\":\"nextjs\"}"), b = av(null), c = av("{\"git\":{\"deploymentEnabled\":{\"main\":true}}}"), off = "{\"git\":{\"deploymentEnabled\":false}}";
  const toml = "[build]\n  command = \"make\"\n\n[build.environment]\n  NODE_VERSION = \"20\"\n", t = an(toml), e = an("[build.environment]\n  X = \"1\"\n"), own = an("[build]\n  ignore = \"git diff --quiet\"\n");
  // vercel
  assert.equal(Object.keys(JSON.parse(a)).join(), "framework,git");
  assert.equal(JSON.parse(a).git.deploymentEnabled["harness/**"], false);
  assert.equal(vg(a), true);
  assert.equal(vg("{\"framework\":\"nextjs\"}"), false);
  assert.equal(b, "{\n  \"git\": {\n    \"deploymentEnabled\": {\n      \"harness/**\": false\n    }\n  }\n}\n");
  assert.equal(JSON.parse(c).git.deploymentEnabled.main, true);
  assert.equal(vg(c), true);
  assert.equal(av(off), off);
  assert.equal(vg(off), true);
  assert.equal(vg(av("{\"git\":{\"deploymentEnabled\":true}}")), true);
  // netlify
  assert.equal(t.how, "added");
  assert.match(t.text, starts("[build]\n  ignore = \"case \\\"$BRANCH\\\" in harness/*) exit 0;; esac; exit 1\"\n  command = \"make\"\n"));
  assert.match(t.text, lit("[build.environment]\n  NODE_VERSION = \"20\""));
  assert.equal(ng(t.text), true);
  assert.equal(ng(toml), false);
  assert.equal(e.how, "added");
  assert.match(e.text, starts("[build.environment]\n  X = \"1\"\n"));
  assert.match(e.text, /\n\[build\]\n  ignore = /);
  assert.equal(ng(e.text), true);
  assert.equal(ng("[build.environment]\n  ignore = \"harness/\"\n"), false);
  assert.equal(own.how, "own-ignore");
  assert.equal(own.text, "[build]\n  ignore = \"git diff --quiet\"\n");
  assert.equal(an(t.text).how, "kept");
  assert.equal(an(null).how, "added");
  assert.equal(ng(an(null).text), true);
  // deployments and the slug
  assert.equal(vd(dep), false);
  assert.equal(vd(dep.replace("\"octocat\"", "\"vercel[bot]\"")), true);
  assert.equal(vd("[]"), false);
  assert.equal(vd("not json"), false);
  assert.equal(slug("git@github.com:o/r.git"), "o/r");
  assert.equal(slug("https://github.com/o/r"), "o/r");
  assert.equal(slug("/tmp/origin.git"), null);
  // the review's edge cases
  assert.match(an("[ build ]\n  command = \"make\"\n").text, starts("[ build ]\n  ignore = "));
  assert.equal(an("build = { command = \"make\" }\n").how, "by-hand");
  assert.equal(an("build.command = \"make\"\n").how, "by-hand");
  assert.equal(an("[build]\n  \"ignore\" = \"exit 1\"\n").how, "own-ignore");
  assert.equal(ng("[build]\n  ignore = \"git diff --quiet HEAD^ HEAD -- packages/harness/\"\n"), false);
  assert.equal(vd(dep.replaceAll("octocat/example", "octocat/vercel-clone")), false);
  assert.equal(vg("{\"git\":{\"deploymentEnabled\":{\"**\":true,\"harness/**\":false}}}"), false);
  assert.equal(vg("{\"git\":{\"deploymentEnabled\":{\"harness/*\":true,\"harness/**\":false}}}"), false);
  assert.equal(vg("{\"git\":{\"deploymentEnabled\":{\"main\":true,\"feature/**\":true,\"harness/**\":false}}}"), true);
  assert.equal(vm("[]"), false);
  assert.equal(vm("null"), false);
  assert.equal(vm("{\"git\":\"x\"}"), false);
  assert.equal(vm("{}"), true);
  assert.equal(vm("{\"git\":{}}"), true);
});

test("deploy.mjs: a true harness/ key or a context ignore isn't guarded (E1 review)", () => {
  const ctx = "[build]\n" + NI + "\n\n[context.deploy-preview]\n  ignore = \"exit 1\"\n";
  assert.equal(vg("{\"git\":{\"deploymentEnabled\":{\"harness/**\":false,\"harness/agent-*\":true}}}"), false);
  assert.equal(ng(ctx), false);
  assert.equal(an(ctx).how, "own-ignore");
  assert.equal(ng("[build]\n" + NI + "\n\n[context.production]\n  command = \"make\"\n"), true);
  assert.equal(ng("[build]\n" + NI + "\n\n[context.production]\n  ignore = \"git diff --quiet\"\n"), true);
  assert.equal(ng("[build]\n" + NI + "\n\n[context.deploy-preview.environment]\n  ignore = \"1\"\n"), true);
  assert.equal(ng("[build]\n" + NI + "\n\n[context.\"harness/x\"]\n  ignore = \"exit 1\"\n"), false);
  const r = an("[build]\n  command = \"make\"\n\n[context.branch-deploy]\n  ignore = \"exit 1\"\n");
  assert.equal(r.how, "own-ignore");
  assert.match(r.text, starts("[build]\n" + NI + "\n  command"));
});
