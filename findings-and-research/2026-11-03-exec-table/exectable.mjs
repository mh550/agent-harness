// Usage: node exectable.mjs <strace -f -e trace=execve,clone,clone3,fork,vfork -s 512 output> [<harness home>]
// Groups successful execs by program (node: script + subcommand) and by caller: the image the exec'ing process ran
// before its exec (a forked bash subshell carries its parent's image), named by its script.
import fs from 'node:fs';
const [file, home = ''] = process.argv.slice(2);
const lines = fs.readFileSync(file, 'utf8').split('\n');
const image = new Map();   // pid -> argv of the image it runs now
const pending = new Map(); // pid -> partial line of an unfinished execve
const execs = []; const parent = new Map();
for (const raw of lines) { const m = raw.match(/^(\d+)\s+(?:<\.\.\. )?(clone3?|fork|vfork)\b.*=\s+(\d+)\s*$/); if (m) parent.set(m[3], m[1]); }
const imageOf = (pid, d = 0) => image.get(pid) || (parent.has(pid) && d < 50 ? imageOf(parent.get(pid), d + 1) : ['?']);
const parseArgv = (s) => { const out = []; const re = /"((?:[^"\\]|\\.)*)"/g; let m; while ((m = re.exec(s))) out.push(m[1]); return out; };
for (let raw of lines) {
  let m = raw.match(/^(\d+)\s+(.*)$/); if (!m) continue;
  let [, pid, rest] = m;
  if (rest.includes('<unfinished ...>')) { pending.set(pid, rest.replace(/<unfinished \.\.\.>.*/, '')); continue; }
  const r = rest.match(/^<\.\.\. (\w+) resumed>(.*)$/);
  if (r) { rest = (pending.get(pid) || r[1] + '(') + r[2]; pending.delete(pid); }
  const c = rest.match(/^(clone3?|fork|vfork)\(.*\)\s+=\s+(\d+)/);
  if (c) { if (!image.has(c[2])) image.set(c[2], imageOf(pid)); continue; }
  const e = rest.match(/^execve\("([^"]*)", \[(.*)\](?:\.\.\.)?, (?:0x[0-9a-f]+|NULL|\[).*\)\s+=\s+(-?\d+)/);
  if (!e || e[3] !== '0') continue;
  const argv = parseArgv(e[2]);
  const chain = []; for (let q = parent.get(pid), d = 0; q && d < 50; q = parent.get(q), d++) chain.push(imageOf(q));
  execs.push({ pid, path: e[1], argv, before: imageOf(pid), chain });
  image.set(pid, argv);
}
const short = (p) => p.replace(home + '/', '').replace(/^.*\/tests\//, 'tests/').replace(/^.*\/lib\//, 'lib/').replace(/^.*\/bin\//, 'bin/');
const script = (argv) => {   // the script an image runs: bash X, node X, or the executable itself
  const a0 = argv[0].split('/').pop();
  if (a0 === 'bash' || a0 === 'sh') { const s = argv.slice(1).find((x) => !x.startsWith('-')); return s && !argv.includes('-c') ? short(s) : (argv.includes('-c') ? 'bash -c' : 'bash'); }
  return short(argv[0]);
};
// the caller, and the first script above it that differs (who ran check.sh, prompt.sh, a stub)
const callerOf = (x) => { const c = script(x.before); const up = x.chain.map(script).find((s) => s !== c && /\.(sh|mjs)$|^bin\//.test(s)); return up && !/^lib\/(lane|driver)\.sh$|^bin\/harness$/.test(c) ? `${c} < ${up}` : c; };
const nodeKey = (argv) => {
  if (argv[1] === '-e') return 'node -e (inline)';
  if (argv[1] === '--input-type=module') return 'node --input-type=module -e';
  const s = short(argv[1] || '?'); const sub = argv[2] && !argv[2].startsWith('/') ? ' ' + argv[2] : '';
  return s + sub;
};
// the class: the nearest image in [before, …chain] that is a stub, the lane, the driver, the CLI or a check file
const classOf = (x) => { for (const im of [x.before, ...x.chain]) { const s = script(im);
  if (/^tests\/stub-/.test(s)) return 'stub'; if (s === 'lib/lane.sh') return 'lane'; if (s === 'lib/driver.sh') return 'driver';
  if (/^bin\/harness$|^lib\/[a-z-]+\.sh$/.test(s) && !/^lib\/(check|prompt|record|scope)\.sh$/.test(s)) return 'cli';
  if (/^tests\/(checks\/|lib\.sh|run\.sh)/.test(s)) return 'tests/lib.sh'; } return '?'; };
const rows = new Map(); const progs = new Map();
for (const x of execs) {
  const prog = x.path.split('/').pop();
  progs.set(prog, (progs.get(prog) || 0) + 1);
  const key = prog === 'node' ? nodeKey(x.argv) : prog;
  const k = key + '\t' + callerOf(x) + '\t' + classOf(x);
  rows.set(k, (rows.get(k) || 0) + 1);
}
const out = [...rows].map(([k, n]) => [...k.split('\t'), n]).sort((a, b) => b[3] - a[3]);
console.log('# programs'); for (const [p, n] of [...progs].sort((a, b) => b[1] - a[1])) console.log(`${p}\t${n}`);
console.log('# rows: key\tcaller\tclass\tcount'); for (const r of out) console.log(r.join('\t'));
