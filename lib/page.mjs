// The debrief as one self-contained HTML page: a card per run (from its summary.json, so the numbers are the
// harness's, not the model's), then the note itself. No dependencies, no scripts, no network.
//   page <note.md> <out.html> [<summary.json>|<state>]…   (<state>: "running", or how the run ended)
import { readFileSync, writeFileSync, existsSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { resolve } from "node:path";

const esc = s => String(s ?? "").replace(/[&<>"']/g, c => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" })[c]);
const inline = s => esc(s).replace(/`([^`]+)`/g, "<code>$1</code>").replace(/\*\*([^*]+)\*\*/g, "<strong>$1</strong>")
  .replace(/(^|[\s(])_([^_]+)_(?=[\s).,;:]|$)/g, "$1<em>$2</em>");

/** Pure: the note's markdown as HTML (headings, lists, paragraphs, fences; everything escaped first). */
export function markdown(md) {
  const out = [];
  let list = null, para = [], fence = null;
  const flush = () => {
    if (para.length) { out.push(`<p>${para.map(inline).join("<br>")}</p>`); para = []; }
    if (list) { out.push(`</${list}>`); list = null; }
  };
  for (const line of md.split("\n")) {
    if (fence !== null) {
      if (/^(~~~|```)/.test(line)) { out.push(`<pre>${esc(fence.join("\n"))}</pre>`); fence = null; } else fence.push(line);
      continue;
    }
    let m;
    if (/^(~~~|```)/.test(line)) { flush(); fence = []; }
    else if ((m = line.match(/^(#{1,4})\s+(.*)$/))) { flush(); const n = Math.min(m[1].length + 1, 4); out.push(`<h${n}>${inline(m[2])}</h${n}>`); }
    else if ((m = line.match(/^\s*(?:[-*]|(\d+)\.)\s+(.*)$/))) {
      const kind = m[1] ? "ol" : "ul";
      if (para.length) { out.push(`<p>${para.map(inline).join("<br>")}</p>`); para = []; }
      if (list !== kind) { if (list) out.push(`</${list}>`); out.push(`<${kind}>`); list = kind; }
      out.push(`<li>${inline(m[2])}</li>`);
    } else if (!line.trim()) flush();
    else { if (list) { out.push(`</${list}>`); list = null; } para.push(line); }
  }
  if (fence !== null) out.push(`<pre>${esc(fence.join("\n"))}</pre>`);
  flush();
  return out.join("\n");
}

const tone = s => /^done/.test(s) ? "good" : /running/.test(s) ? "info"
  : /blocked|waiting on Michael|failed|edits|unexpected/.test(s) ? "warn" : "muted";

/** Pure: one run's card. */
export function card(s, state) {
  const f = s.features ?? {}, status = state || s.end_reason || "?";
  const ms = (s.milestones ?? []).map(m => {
    const st = m.merged ? "merged" : m.verified ? "verified" : m.passing === m.features ? "built" : m.passing ? "partial" : "todo";
    return `<li class="ms ${st}" title="${esc(`${m.id}: ${m.passing}/${m.features} passing, ${st}`)}">${esc(m.id)}</li>`;
  }).join("");
  const open = (s.features_detail ?? []).filter(x => !x.passes);
  const byCause = Object.entries(open.reduce((g, x) => ((g[x.cause ?? "not done"] ??= []).push(x), g), {}));
  const rows = byCause.map(([c, xs]) => `<li><span class="cause">${esc(c)}</span> ${xs.slice(0, 8).map(x => `<code>${esc(x.id)}</code>`).join(" ")}`
    + `${xs.length > 8 ? ` +${xs.length - 8}` : ""}${xs[0]?.detail ? `<div class="detail">${esc(xs[0].detail)}</div>` : ""}</li>`).join("");
  const tests = s.tests?.start != null || s.tests?.end != null ? `${s.tests.start ?? "?"} → ${s.tests.end ?? "?"}` : "–";
  const money = x => (x == null ? "–" : `$${Number(x).toFixed(2)}`);
  return `<article class="card">
  <header><h3>${esc(s.run)}</h3><span class="proj">${esc(s.project)}</span><span class="pill ${tone(status)}">${esc(status)}</span></header>
  <div class="big"><b>${f.passing ?? 0}/${f.total ?? 0} passing</b><span>${f.verified ?? 0} verified · ${f.merged ?? 0} merged</span></div>
  <ul class="milestones">${ms}</ul>
  <dl><div><dt>Spend</dt><dd>${money(s.cost?.total)}</dd></div><div><dt>Per feature</dt><dd>${money(s.cost?.per_passing_feature)}</dd></div>
  <div><dt>Wall</dt><dd>${s.time?.wall_h ?? "–"} h</dd></div><div><dt>Tests</dt><dd>${esc(tests)}</dd></div></dl>
  ${rows ? `<ul class="open">${rows}</ul>` : ""}
</article>`;
}

const CSS = `
:root{--bg:#f6f5f2;--panel:#fff;--ink:#1d1c1a;--soft:#6b6862;--line:#e3e0da;--good:#1f7a4d;--warn:#a5520f;--info:#2a5db0;--muted:#77736c;
--merged:#1f7a4d;--verified:#5a9b78;--built:#c9a227;--partial:#e3c97a;--todo:#d9d5ce;color-scheme:light}
@media (prefers-color-scheme:dark){:root:not([data-theme="light"]){--bg:#151514;--panel:#1f1e1c;--ink:#ecebe7;--soft:#a29e96;--line:#34322f;
--good:#5fc790;--warn:#f0a35c;--info:#7fa8f0;--muted:#9a958c;--merged:#4fb07f;--verified:#3f7a5c;--built:#b8921c;--partial:#7d6a2c;--todo:#3a3835;color-scheme:dark}}
:root[data-theme="dark"]{--bg:#151514;--panel:#1f1e1c;--ink:#ecebe7;--soft:#a29e96;--line:#34322f;--good:#5fc790;--warn:#f0a35c;--info:#7fa8f0;
--muted:#9a958c;--merged:#4fb07f;--verified:#3f7a5c;--built:#b8921c;--partial:#7d6a2c;--todo:#3a3835;color-scheme:dark}
*{box-sizing:border-box}body{margin:0;background:var(--bg);color:var(--ink);font:15px/1.5 system-ui,-apple-system,"Segoe UI",sans-serif}
main{max-width:980px;margin:0 auto;padding:24px 16px 64px}h1{font-size:22px;margin:0 0 4px}.sub{color:var(--soft);font-size:13px;margin:0 0 20px}
.headline{background:var(--panel);border:1px solid var(--line);border-left:4px solid var(--info);border-radius:10px;padding:12px 16px;margin-bottom:20px}
.headline p{margin:2px 0}.cards{display:grid;grid-template-columns:repeat(auto-fill,minmax(290px,1fr));gap:14px;margin-bottom:28px}
.card{background:var(--panel);border:1px solid var(--line);border-radius:10px;padding:14px 16px;min-width:0}
.card header{display:flex;flex-wrap:wrap;align-items:baseline;gap:6px 10px}.card h3{margin:0;font-size:16px;overflow-wrap:anywhere}
.proj{color:var(--soft);font-size:13px}.pill{margin-left:auto;font-size:12px;padding:2px 8px;border-radius:99px;border:1px solid currentColor;max-width:100%;overflow-wrap:anywhere}
.pill.good{color:var(--good)}.pill.warn{color:var(--warn)}.pill.info{color:var(--info)}.pill.muted{color:var(--muted)}
.big{margin:10px 0 8px}.big b{font-size:22px;font-variant-numeric:tabular-nums}.big span{display:block;color:var(--soft);font-size:13px}
.milestones{list-style:none;padding:0;margin:0 0 10px;display:flex;flex-wrap:wrap;gap:4px}
.ms{font-size:11px;padding:2px 6px;border-radius:5px;background:var(--todo);color:var(--ink)}.ms.merged{background:var(--merged);color:#fff}
.ms.verified{background:var(--verified);color:#fff}.ms.built{background:var(--built);color:#1d1c1a}.ms.partial{background:var(--partial)}
dl{display:grid;grid-template-columns:repeat(2,1fr);gap:8px 12px;margin:0}dl div{min-width:0}dt{font-size:11px;color:var(--soft);text-transform:uppercase;letter-spacing:.04em}
dd{margin:0;font-variant-numeric:tabular-nums;font-size:14px}.open{margin:12px 0 0;padding:10px 0 0 18px;border-top:1px solid var(--line);font-size:13px}
.open li{margin:4px 0}.cause{font-weight:600}.detail{color:var(--soft);font-size:12px;overflow-wrap:anywhere}
.note{background:var(--panel);border:1px solid var(--line);border-radius:10px;padding:6px 18px 14px}.note h2{font-size:17px;margin:18px 0 6px}
.note h3{font-size:15px;margin:14px 0 4px}.note h4{font-size:14px;margin:12px 0 4px}.note li{margin:3px 0}
code{font:12.5px ui-monospace,SFMono-Regular,Menlo,monospace;background:color-mix(in srgb,var(--line) 60%,transparent);padding:1px 4px;border-radius:4px;overflow-wrap:anywhere}
pre{font:12.5px/1.4 ui-monospace,SFMono-Regular,Menlo,monospace;background:var(--bg);border:1px solid var(--line);border-radius:8px;padding:10px;overflow-x:auto}`;

/** Pure: the whole page. runs: [{ summary, state }]. */
export function page(note, runs, now = new Date()) {
  const lines = note.split("\n");
  const title = (lines.find(l => /^# /.test(l)) ?? "# Debrief").replace(/^# /, "");
  const body = lines.filter(l => !/^# /.test(l)).join("\n");
  const head = body.match(/^## Headline\s*\n([\s\S]*?)(?=\n## |$)/m)?.[1]?.trim() ?? "";
  const rest = head ? body.replace(/^## Headline\s*\n[\s\S]*?(?=\n## |$)/m, "") : body;
  return `<!doctype html>
<html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Harness debrief</title><style>${CSS}</style></head>
<body><main>
<h1>${inline(title)}</h1>
<p class="sub">${runs.length} run${runs.length === 1 ? "" : "s"} · page built ${esc(now.toISOString().slice(0, 16).replace("T", " "))} UTC from each run's summary.json and the debrief note</p>
${head ? `<section class="headline">${markdown(head)}</section>` : ""}
<section class="cards">${runs.map(r => card(r.summary, r.state)).join("\n")}</section>
<section class="note">${markdown(rest)}</section>
</main></body></html>
`;
}

function main([note, out, ...args]) {
  if (!note || !out) { console.error("usage: page.mjs <note.md> <out.html> [<summary.json>|<state>]…"); return 2; }
  const runs = args.map(a => { const i = a.lastIndexOf("|"); return i < 0 ? [a, ""] : [a.slice(0, i), a.slice(i + 1)]; })
    .filter(([p]) => existsSync(p)).map(([p, state]) => ({ summary: JSON.parse(readFileSync(p, "utf8")), state }));
  writeFileSync(out, page(readFileSync(note, "utf8"), runs));
  return 0;
}

if (process.argv[1] && fileURLToPath(import.meta.url) === resolve(process.argv[1])) process.exit(main(process.argv.slice(2)));
