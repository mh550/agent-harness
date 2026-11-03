// Usage: node mdtable.mjs <exectable.txt> → markdown: node rows (script · subcommand · caller · count · CPU-s), program
// counts by caller class, top five by execs × unit cost (node 26.9 ms, git 1.1, cat/date 0.8; others not ranked)
import fs from 'node:fs';
const rows = fs.readFileSync(process.argv[2], 'utf8').split('\n').slice(1).filter((l) => l && !l.startsWith('#') && l.split('\t').length === 4 && !/^\S+\t\d+$/.test(l))
  .map((l) => { const [k, c, cl, n] = l.split('\t'); return { k, c, cl, n: +n }; });
const cls = (c, r) => r.cl;
const unit = { node: 26.9, git: 1.1, cat: 0.8, date: 0.8 };
const prog = (k) => k.startsWith('lib/') || k.startsWith('node ') || k.startsWith('tests/') && k.endsWith('.mjs') ? 'node' : k;
const agg = new Map();
for (const r of rows) { const p = prog(r.k); const key = [p === 'node' ? r.k : p, cls(r.c, r), p === 'node' ? r.c.split(' < ')[0] : ''].join('\t'); agg.set(key, (agg.get(key) || 0) + r.n); }
const nodeRows = [...agg].filter(([k]) => prog(k.split('\t')[0]) === 'node').map(([k, n]) => [...k.split('\t'), n]).sort((a, b) => b[3] - a[3]);
console.log('| script | subcommand | caller | count | CPU-s |\n|---|---|---|---|---|');
for (const [k, c, via, n] of nodeRows) { const [s, ...sub] = k.split(' '); console.log(`| \`${s}\` | ${sub.length ? '`' + sub.join(' ') + '`' : '–'} | ${c}${via ? ` (\`${via}\`)` : ''} | ${n} | ${(n * 0.0269).toFixed(2)} |`); }
const byP = new Map();
for (const r of rows) { const p = prog(r.k); const c = cls(r.c, r); const m = byP.get(p) || {}; m[c] = (m[c] || 0) + r.n; byP.set(p, m); }
const C = ['driver', 'lane', 'cli', 'stub', 'tests/lib.sh', '?'];
console.log('\n| program | ' + C.join(' | ') + ' | all |\n|---|' + C.map(() => '---|').join('') + '---|');
for (const p of ['node', 'git', 'date', 'cat', 'bash']) { const m = byP.get(p) || {}; console.log(`| ${p} | ${C.map((c) => m[c] || 0).join(' | ')} | ${C.reduce((s, c) => s + (m[c] || 0), 0)} |`); }
// top five callers: (program-or-node-row, caller class [script]) by count × unit
const all = new Map();
for (const r of rows) { const p = prog(r.k); if (!unit[p]) continue; const key = `${p === 'node' ? r.k.split(' ')[0] + ' (all subcommands)' : p} · ${cls(r.c, r)} · ${r.c.split(' < ')[0]}`; all.set(key, { p, n: ((all.get(key) || {}).n || 0) + r.n }); }
console.log('\nTop five by execs × unit cost:');
[...all].map(([k, v]) => [k, v.n, v.n * unit[v.p] / 1000]).sort((a, b) => b[2] - a[2]).slice(0, 8).forEach(([k, n, s], i) => console.log(`${i + 1}. ${k}: ${n} × → ${s.toFixed(2)} CPU-s`));
