// The resident helper: `coproc node lib/helper.mjs` (lib/record.sh's ask) answers a served script's question without a node start.
//   stdin, one line each: {"id":<n>,"script":"<name>.mjs","args":[…],"cwd":"…","env":{…}}; stdout: `<id> <rc> <bytes>\n` and exactly <bytes> bytes
// One at a time, in order; nothing kept between requests, so an answer is computed from the files as they are now.
// rc 64 declines (no bytes): the caller spawns, and the spawn gives the answer and the stderr a shell would have seen.
import { NoStdin } from "./cli.mjs";

const SERVED = new Set(["features.mjs", "metrics.mjs", "treekey.mjs", "testcount.mjs", "entries.mjs", "inbox.mjs",
  "memlint.mjs", "render.mjs", "needs.mjs", "summary.mjs", "notify.mjs", "checkdecide.mjs", "lane.mjs"]);
const DECLINE = 64, THREW = 70;

const decline = (id, why) => {
  if (why) console.error(`helper.mjs: ${why}`);
  return { id, rc: DECLINE, out: Buffer.alloc(0) };
};

// process.env itself, not only io.env: git started by a served script (needs, overlap) inherits it
const useEnv = env => {
  for (const k of Object.keys(process.env)) if (!Object.hasOwn(env, k)) delete process.env[k];
  for (const [k, v] of Object.entries(env)) if (process.env[k] !== v) process.env[k] = v;
};

async function answer(line) {
  let q;
  try { q = JSON.parse(line.toString()); } catch (e) { return decline(0, `malformed request: ${e.message}`); }
  const { id = 0, script, args, cwd, env } = q ?? {};
  if (!SERVED.has(script) || !Array.isArray(args)) return decline(id, `not served: ${script}`);
  let main;
  try { ({ main } = await import(`./${script}`)); }
  catch (e) { return decline(id, `${script}: ${e.message}`); }
  // the process's cwd, not only io.cwd: a served main resolves a relative path argument against it. One that's gone is
  // no failure of ours: a spawn may answer in it
  try { if (cwd !== undefined) process.chdir(cwd); } catch { return decline(id); }
  if (env) useEnv(env);
  let r;
  try { r = await main(args, { cwd: process.cwd(), env: process.env }); }
  catch (e) {
    if (e instanceof NoStdin) return decline(id);   // main never read the request pipe; the spawn gets the asker's stdin
    console.error(e?.stack ?? String(e));
    return { id, rc: THREW, out: Buffer.alloc(0) };
  }
  const out = Buffer.from(r.out ?? "");
  // bash's read drops a NUL: only a spawn can hand such an answer on
  return out.includes(0) ? decline(id) : { id, rc: (r.rc ?? 0) & 255, out };
}

// a pipe write over 64 KB is async: the next request, or the exit, waits for its callback
const reply = ({ id, rc, out }) => new Promise(done =>
  process.stdout.write(Buffer.concat([Buffer.from(`${id} ${rc} ${out.length}\n`), out]), done));

async function serve() {
  process.stdout.on("error", () => process.exit(0));   // the asker has gone
  let pending = Buffer.alloc(0);
  for await (const chunk of process.stdin) {
    pending = pending.length ? Buffer.concat([pending, chunk]) : chunk;
    for (let nl; (nl = pending.indexOf(10)) >= 0; pending = pending.subarray(nl + 1)) await reply(await answer(pending.subarray(0, nl)));
  }
  if (pending.length) await reply(await answer(pending));
  process.exit(0);
}

serve();
