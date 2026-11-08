// The queue entry format, written once: one argument per line, a newline inside one stored as the byte 0x1f.
//
//   add <queue dir> <verb> <arg>…   → writes <queue dir>/<n>-<verb>-<name>.args, numbered past queue/held too; prints its path
//   write <file> <arg>…             → replaces the entry <file> with these arguments (queue add --continue's request)
//   decode <file>                   → the entry's arguments, each followed by a NUL
//   projects <state root> <file>…   → each entry's project (empty when it has none), each followed by a NUL
//   facts <file>                    → start|other, project, run, 0|1 --spec given, its value, the --brief text, each followed by a NUL
import { existsSync, mkdirSync, readdirSync, readFileSync, writeFileSync } from "node:fs";
import { basename, join } from "node:path";
import { isMain, runCli, captured } from "./cli.mjs";

export const encodeEntry = args => args.map(a => `${a.replaceAll("\n", "\x1f")}\n`).join("");

// A CR at a line's end goes (a file edited elsewhere). An empty file is no arguments, as mapfile reads it; a file of one
// blank line is one empty argument.
export function decodeEntry(text) {
  if (!text) return [];
  return text.replace(/\n$/, "").split("\n").map(l => l.replace(/\r$/, "").replaceAll("\x1f", "\n"));
}

// <n>-<verb>-<what follows first's last slash>.args: n past every four-digit name in queue/ and queue/held/.
export function entryName(names, verb, first) {
  const top = names.reduce((n, f) => Math.max(n, Number(/^(\d{4})-.*\.args$/.exec(f)?.[1] ?? 0)), 0);
  return `${String(top + 1).padStart(4, "0")}-${verb}-${first.slice(first.lastIndexOf("/") + 1)}.args`;
}

// A start's project is its repository's directory name (what the state dir is named after); a continue's, its run's. None: null.
export function entryProject(args, projects) {
  const [verb, first] = args;
  return verb === "start" ? basename(first ?? "") || null : projects.get(first) ?? null;
}

// What entry_overlaps needs: a start's path and optional run id, or a continue's run; the last --spec (null: none given,
// so a continue keeps its run's); each --brief behind a newline. Every place from the third on is read, as bash's loop does.
export function entryFacts(args) {
  const start = args[0] === "start", third = args[2] ?? "";
  const f = { start, project: start ? args[1] ?? "" : "", run: start ? (third && !third.startsWith("--") ? third : "") : args[1] ?? "", spec: null, brief: "" };
  for (let i = 2; i < args.length; i++) {
    if (args[i] === "--spec") f.spec = args[i + 1] ?? "";
    else if (args[i] === "--brief") f.brief += `\n${args[i + 1] ?? ""}`;
  }
  return f;
}

// The project holding a run: the first <root>/<project>/<run> in name order. What the runner's glob read before this module; a run in two
// projects is no case the harness makes.
function runProject(root, run) {
  if (!run || !existsSync(root)) return null;
  return readdirSync(root).filter(p => !p.startsWith(".")).sort().find(p => existsSync(join(root, p, run))) ?? null;
}

const entry = f => existsSync(f) ? decodeEntry(readFileSync(f, "utf8")) : [];   // the runner may just have taken it
const fields = xs => xs.map(x => `${x}\0`).join("");

export const main = captured(([cmd, ...args], _io, say, put) => {
  switch (cmd) {
    case "add": {
      const [q, verb, first] = args;
      if (first === undefined) { console.error("usage: queue.mjs add <queue dir> <verb> <arg>…"); return 2; }
      mkdirSync(join(q, "done"), { recursive: true }); mkdirSync(join(q, "held"), { recursive: true });
      const f = `${q}/${entryName([...readdirSync(q), ...readdirSync(join(q, "held"))], verb, first)}`;
      writeFileSync(f, encodeEntry(args.slice(1)));
      say(f);
      return 0;
    }
    case "write": {   // a request replacing a queued entry: encoded as add encodes, so a brief's lines stay one argument
      const [f, ...rest] = args;
      if (!f || !rest.length) { console.error("usage: queue.mjs write <file> <arg>…"); return 2; }
      writeFileSync(f, encodeEntry(rest));
      return 0;
    }
    case "decode":
      put(fields(entry(args[0])));
      return 0;
    case "projects": {
      const [root, ...files] = args, known = new Map();
      put(fields(files.map(f => {
        const a = entry(f), run = a[1];
        if (a[0] !== "start" && !known.has(run)) known.set(run, runProject(root, run));
        return entryProject(a, known) ?? "";
      })));
      return 0;
    }
    case "facts": {
      const x = entryFacts(entry(args[0]));
      put(fields([x.start ? "start" : "other", x.project, x.run, x.spec === null ? 0 : 1, x.spec ?? "", x.brief]));
      return 0;
    }
    default:
      console.error("usage: queue.mjs add|decode|projects|facts …");
      return 2;
  }
});

if (isMain(import.meta.url)) runCli(main);
