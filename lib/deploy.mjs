// Deploy guards for hosts that build every pushed branch (Vercel, Netlify): run branches must not deploy. No dependencies.
//
//   vercel-guard <vercel.json>    → add git.deploymentEnabled "harness/**": false (creates the file, keeps other keys); prints added|kept|by-hand
//   netlify-guard <netlify.toml>  → add a [build] ignore for harness/* refs (keeps other keys); prints added|kept|own-ignore|by-hand
//   status <vercel.json|-> <netlify.toml|-> <.vercel dir 0|1> <deployments.json|->  → one line per unguarded host: vercel|netlify
//   slug <origin url>             → owner/repo of a GitHub origin; exit 1, nothing printed, otherwise
import { existsSync, readFileSync, writeFileSync } from "node:fs";
import { resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { githubUrls } from "./notify.mjs";

const parse = text => { try { return JSON.parse(text); } catch { return undefined; } };

const isObject = x => typeof x === "object" && x !== null && !Array.isArray(x);
// Branch globs as Vercel matches them (minimatch: * within a segment, ** across).
const globMatch = (glob, ref) =>
  new RegExp("^" + glob.replace(/[.+^${}()|[\]\\]/g, "\\$&").replace(/\*\*/g, "\0").replace(/\*/g, "[^/]*").replace(/\?/g, "[^/]").replace(/\0/g, ".*") + "$").test(ref);

// Vercel reads the deployed commit's vercel.json: false turns off every branch, an object the branches it names; a
// branch several keys match deploys if any of them is true.
export function vercelGuarded(text) {
  const d = parse(text)?.git?.deploymentEnabled;
  return d === false || (isObject(d) && d["harness/**"] === false && !Object.entries(d).some(([k, v]) => v === true && globMatch(k, "harness/run")));
}

// A file whose top level (or git) isn't an object can't take the key: the guard goes in by hand.
export const vercelMergeable = text => { const o = parse(text); return isObject(o) && (o.git === undefined || isObject(o.git)); };

// Keys are only added, so the rest of the file (and its key order) stays as it was. Bad JSON throws.
export function addVercelGuard(text) {
  if (text !== null && vercelGuarded(text)) return text;
  const o = text === null ? {} : JSON.parse(text);
  o.git ??= {};
  const d = o.git.deploymentEnabled;
  o.git.deploymentEnabled = isObject(d) ? { ...d, "harness/**": false } : { "harness/**": false };
  return JSON.stringify(o, null, 2) + "\n";
}

// Netlify's ignore command cancels the build when it exits 0; $BRANCH is the ref being built.
export const NETLIFY_IGNORE = '  ignore = "case \\"$BRANCH\\" in harness/*) exit 0;; esac; exit 1"';

function buildTable(lines) {   // [header index, end index) of the [build] table ([build.environment] is another table)
  const h = lines.findIndex(l => /^\s*\[\s*build\s*\]\s*(#.*)?$/.test(l));
  if (h < 0) return null;
  const n = lines.findIndex((l, i) => i > h && /^\s*\[/.test(l));
  return [h, n < 0 ? lines.length : n];
}
const ignoreLine = (lines, [h, e]) => lines.slice(h + 1, e).find(l => /^\s*["']?ignore["']?\s*=/.test(l));
const ours = line => (line ?? "").includes("harness/*) exit 0");
// build set as an inline table or dotted keys (build = { … }, build.command = …): another [build] would be invalid TOML
const buildElsewhere = lines => lines.some(l => /^\s*["']?build["']?\s*(=|\.)/.test(l));

export function netlifyGuarded(text) {
  const lines = (text ?? "").split("\n"), t = buildTable(lines);
  return !!t && ours(ignoreLine(lines, t));
}

// A [build] ignore of the project's own is left alone (two commands can't be merged safely): "own-ignore"; build
// defined without a [build] header: "by-hand".
export function addNetlifyGuard(text) {
  const src = text ?? "", lines = src.split("\n"), t = buildTable(lines);
  if (!t && buildElsewhere(lines)) return { text: src, how: "by-hand" };
  if (!t) return { text: (src && !src.endsWith("\n") ? src + "\n" : src) + (src ? "\n" : "") + `[build]\n${NETLIFY_IGNORE}\n`, how: "added" };
  const own = ignoreLine(lines, t);
  if (own) return { text: src, how: ours(own) ? "kept" : "own-ignore" };
  lines.splice(t[0] + 1, 0, NETLIFY_IGNORE);
  return { text: lines.join("\n"), how: "added" };
}

// Vercel's Git integration creates GitHub deployments as vercel[bot]: one on the repo means Vercel builds it.
export function vercelDeployments(apiText) {
  const a = parse(apiText);
  return Array.isArray(a) && a.some(d => d?.creator?.login === "vercel[bot]" || d?.performed_via_github_app?.slug === "vercel");
}

export function slug(originUrl) {
  const m = /^https:\/\/github\.com\/([^/]+\/[^/]+)\/blob\//.exec(githubUrls(originUrl, "-", "-")?.blob ?? "");
  return m ? m[1] : null;
}

// Hosts deployed from Git (Vercel: vercel.json, .vercel/ or its deployments; Netlify: netlify.toml) without the guard.
export function unguarded({ vercel, netlify, dotVercel, deployments }) {
  const out = [];
  if ((vercel !== null || dotVercel || vercelDeployments(deployments)) && !(vercel !== null && vercelGuarded(vercel))) out.push("vercel");
  if (netlify !== null && !netlifyGuarded(netlify)) out.push("netlify");
  return out;
}

const read = f => (f && f !== "-" && existsSync(f) ? readFileSync(f, "utf8") : null);

function main([cmd, ...args]) {
  switch (cmd) {
    case "vercel-guard": {
      const text = read(args[0]);
      if (text !== null && vercelGuarded(text)) { console.log("kept"); return 0; }
      if (text !== null && !vercelMergeable(text)) { console.log("by-hand"); return 0; }
      writeFileSync(args[0], addVercelGuard(text));
      console.log("added");
      return 0;
    }
    case "netlify-guard": {
      const r = addNetlifyGuard(read(args[0]));
      if (r.how === "added") writeFileSync(args[0], r.text);
      console.log(r.how);
      return 0;
    }
    case "status":
      for (const h of unguarded({ vercel: read(args[0]), netlify: read(args[1]), dotVercel: args[2] === "1", deployments: read(args[3]) })) console.log(h);
      return 0;
    case "slug": {
      const s = slug(args[0]);
      if (!s) return 1;
      console.log(s);
      return 0;
    }
    default:
      console.error("usage: deploy.mjs vercel-guard|netlify-guard|status|slug …");
      return 2;
  }
}

if (process.argv[1] && fileURLToPath(import.meta.url) === resolve(process.argv[1])) process.exit(main(process.argv.slice(2)));
