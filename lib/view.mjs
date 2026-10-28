// The one formatter every read view renders through (decisions/2026-10-27-read-views). No dependencies.
//
//   table   → stdin: the column spec "key:min:max:align:flex" (tab-separated, one per column), then one tab-separated row per line
//   card    → stdin: the header, then "label\tvalue" lines; a line "\t<text>" is a verbatim line of the field above it
//   section → stdin: one line "title\tcount\thint" (an empty count leaves it out)
import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { fileURLToPath } from "node:url";

export const GLYPHS = { running: ["●", "*"], done: ["✓", "+"], failed: ["✗", "x"], stopped: ["■", "#"], paused: ["‖", "="],
  needs: ["⚠", "!"], queued: ["○", "o"], sep: ["·", "-"], rule: ["─", "-"], cut: ["…", "..."] };
const SGR = { red: 31, yellow: 33, green: 32, cyan: 36, dim: 2, bold: 1 };
const LABEL = 11, GAP = 2, FLEX_MIN = 10;

const whole = v => typeof v === "string" && /^\d+$/.test(v);

// The three inputs only (the caller passes process.env and process.stdout's isTTY and columns), so every rule is checkable.
export function context({ env = {}, isTTY = false, columns } = {}) {
  const c = whole(env.COLUMNS) ? Number(env.COLUMNS) : 0;
  const width = c >= 40 ? c : isTTY && Number.isInteger(columns) && columns > 0 ? columns : 100;
  const tty = env.HARNESS_TTY === "1" ? true : env.HARNESS_TTY === "0" ? false : Boolean(isTTY);
  const color = env.HARNESS_COLOR === "always" ? true : env.HARNESS_COLOR === "never" ? false
    : tty && !env.NO_COLOR && env.TERM !== "dumb";
  const locale = env.LC_ALL || env.LC_CTYPE || env.LANG || "";
  const glyphs = ["unicode", "ascii"].includes(env.HARNESS_GLYPHS) ? env.HARNESS_GLYPHS : /utf-?8/i.test(locale) ? "unicode" : "ascii";
  const now = whole(env.HARNESS_NOW) ? Number(env.HARNESS_NOW) : Math.floor(Date.now() / 1000);
  return { width, narrow: width < 72, tty, color, glyphs, now };
}

export function glyph(name, ctx) {
  const g = GLYPHS[name]; if (!g) throw new Error(`unknown glyph '${name}'`);   // a typo is a bug, not a blank
  return g[ctx.glyphs === "ascii" ? 1 : 0];
}

export function paint(text, style, ctx) {
  const n = SGR[style]; if (n === undefined) throw new Error(`unknown style '${style}'`);
  return ctx.color ? `\x1b[${n}m${text}\x1b[0m` : String(text);
}

// East Asian Wide and Fullwidth blocks, and the emoji a terminal draws two columns wide
const WIDE = [[0x1100, 0x115f], [0x2e80, 0x303e], [0x3041, 0x33ff], [0x3400, 0x4dbf], [0x4e00, 0x9fff], [0xa000, 0xa4cf],
  [0xa960, 0xa97f], [0xac00, 0xd7a3], [0xf900, 0xfaff], [0xfe10, 0xfe19], [0xfe30, 0xfe6f], [0xff00, 0xff60], [0xffe0, 0xffe6],
  [0x1f300, 0x1f64f], [0x1f900, 0x1f9ff], [0x20000, 0x2fffd], [0x30000, 0x3fffd]];
const TOKEN = /\x1b\[[0-9;]*m|[\s\S]/gu;   // an SGR sequence or one whole code point
const ZERO = /^[\p{M}\p{Cc}​-‏⁠﻿]$/u;

function cpWidth(t) {
  if (t[0] === "\x1b" || ZERO.test(t)) return 0;
  const cp = t.codePointAt(0);
  return WIDE.some(([a, b]) => cp >= a && cp <= b) || /\p{Emoji_Presentation}/u.test(t) ? 2 : 1;
}

export function displayWidth(s) {
  let w = 0; for (const [t] of String(s).matchAll(TOKEN)) w += cpWidth(t); return w;
}

export function cut(s, n, ctx) {
  s = String(s); if (displayWidth(s) <= n) return s;
  const g = glyph("cut", ctx), room = n - displayWidth(g);
  if (room < 0) return g.slice(0, Math.max(0, n));
  let out = "", w = 0, open = false;
  for (const [t] of s.matchAll(TOKEN)) {
    if (t[0] === "\x1b") { out += t; open = !/^\x1b\[0?m$/.test(t); continue; }
    const tw = cpWidth(t); if (w + tw > room) break;
    out += t; w += tw;
  }
  return out + (open ? "\x1b[0m" : "") + g;
}

export function pad(s, n, align = typeof s === "number" ? "right" : "left") {
  s = String(s); const fill = " ".repeat(Math.max(0, n - displayWidth(s)));
  return align === "right" ? fill + s : s + fill;
}

// s in lines of at most n columns, never splitting a code point: what the terminal would do with an id wider than the line
function fold(s, n) {
  const out = []; let cur = "", w = 0;
  for (const [t] of String(s).matchAll(TOKEN)) {
    const tw = cpWidth(t);
    if (w + tw > n && w > 0) { out.push(cur); cur = ""; w = 0; }
    cur += t; w += tw;
  }
  return [...out, cur];
}

// cells joined by the gap, a new line where the next would pass the width; only a cell wider than the width is folded
function lay(cells, n) {
  const out = []; let cur = "";
  for (const c of cells.map(c => c.trimEnd()).filter(Boolean)) {
    if (cur && displayWidth(cur) + GAP + displayWidth(c) <= n) { cur += " ".repeat(GAP) + c; continue; }
    if (cur) out.push(cur);
    const f = fold(c, n); cur = f.pop(); out.push(...f);
  }
  return cur ? [...out, cur] : out;
}

// Normal: one line per row, the flex column taking what the others leave. Narrow (or a flex left under its min): the flex
// value on an indented second line. A `cut: false` column (ids) is never cut; a line still wider than the width is folded.
export function table(rows, columns, ctx) {
  const str = v => v == null ? "" : String(v).replace(/[\t\r\n]+/g, " "), W = ctx.width, gap = " ".repeat(GAP);
  const flex = columns.find(c => c.flex), fi = columns.indexOf(flex);
  const width = new Map(columns.filter(c => c !== flex).map(c => {
    let w = Math.max(c.min ?? 0, ...rows.map(r => displayWidth(str(r[c.key]))));
    if (c.max != null && c.cut !== false) w = Math.min(w, c.max);
    return [c, w];
  }));
  const fixed = [...width.values()].reduce((a, w) => a + w, 0) + GAP * Math.max(0, columns.length - 1);
  let fw = flex ? W - fixed : 0;
  if (flex?.max != null) fw = Math.min(fw, flex.max);
  const narrow = flex && (ctx.narrow || fw < (flex.min ?? FLEX_MIN));
  const cell = (c, r) => {
    const v = str(r[c.key]), w = width.get(c);
    return pad(c.cut === false ? v : cut(v, w, ctx), w, c.align ?? (typeof r[c.key] === "number" ? "right" : "left"));
  };
  const fit = cells => { const j = cells.join(gap).trimEnd(); return displayWidth(j) <= W ? [j] : lay(cells, W); };
  const out = [];
  for (const r of rows) {
    if (!narrow) out.push(...fit(columns.map(c => c === flex ? pad(cut(str(r[c.key]), fw, ctx), fw) : cell(c, r))));
    else {   // the flex slot is blank on the first line, so the columns after it keep to the right edge
      const preC = columns.slice(0, fi).map(c => cell(c, r)), postC = columns.slice(fi + 1).map(c => cell(c, r));
      const pre = preC.join(gap).trimEnd(), post = postC.join(gap), room = W - displayWidth(pre) - displayWidth(post);
      if (!postC.length) out.push(...fit(preC));
      else if (room >= GAP) out.push(pre + " ".repeat(room) + post);
      else out.push(...(pre ? fit(preC) : []), ...(displayWidth(post) <= W ? [pad(post, W, "right")] : lay(postC, W)));   // too wide to share a line
    }
    const long = flex ? str(r[flex.key]) : "";
    if (narrow && long) out.push("  " + cut(long, W - 2, ctx));
    for (const s of r.sub ?? []) out.push(cut("    " + s, W, ctx));
  }
  return out;
}

// "TITLE <count>[ · <hint>] ───…" to the width; count null leaves it out; an empty section (count 0) is the bare line
export function section(title, count, hint, ctx) {
  const head = cut([count == null ? title : `${title} ${count}`, hint].filter(Boolean).join(` ${glyph("sep", ctx)} `), ctx.width, ctx);
  const fill = ctx.width - displayWidth(head) - 1;
  return count === 0 || fill < 1 ? head : `${head} ${paint(glyph("rule", ctx).repeat(fill), "dim", ctx)}`;
}

export function rule(ctx) { return paint(glyph("rule", ctx).repeat(ctx.width), "dim", ctx); }

const URL = /^[a-z][a-z0-9+.-]*:\/\/\S+$/i;

// Words at spaces; a word wider than the room breaks after its slashes, then by code point; a URL too wide is {url}.
function wrap(text, room) {
  const lines = []; let cur = "";
  const put = piece => {
    if (!cur) cur = piece;
    else if (displayWidth(cur) + displayWidth(piece) <= room) cur += piece;
    else { lines.push(cur); cur = piece; }
  };
  for (const word of String(text).split(/ +/).filter(Boolean)) {
    if (cur && displayWidth(cur) + 1 + displayWidth(word) <= room) { cur += " " + word; continue; }
    if (cur) { lines.push(cur); cur = ""; }
    if (URL.test(word) && displayWidth(word) > room) { lines.push({ url: word }); continue; }   // the card prints it at 2, whole
    if (displayWidth(word) <= room) { cur = word; continue; }
    for (const p of word.split(/(?<=\/)/)) for (const q of displayWidth(p) > room ? fold(p, room) : [p]) put(q);
  }
  return cur ? [...lines, cur] : lines;
}

// header, a rule, then "  <label padded to 11><value>" with a hanging indent of 13; `lines` verbatim at 4, `url` whole at 2
export function card(header, fields, ctx) {
  const out = [cut(header, ctx.width, ctx), rule(ctx)];
  for (const f of fields) {
    const values = (Array.isArray(f.value) ? f.value : [f.value]).flatMap(v => v == null ? [] : String(v).split(/\r?\n/)).filter(Boolean);
    const lines = f.lines ?? [];
    if (!values.length && !lines.length && !f.url) continue;
    const label = cut(f.label ?? "", Math.max(LABEL - 1, Math.floor(ctx.width / 3)), ctx);
    const lw = Math.max(LABEL, displayWidth(label) + 1), ind = 2 + lw, room = Math.max(1, ctx.width - ind);
    const wrapped = values.flatMap(v => wrap(v, room)), first = typeof wrapped[0] === "string" ? wrapped.shift() : "";
    out.push(cut(("  " + pad(label, lw) + first).trimEnd(), ctx.width, ctx), ...wrapped.map(l => l.url ? "  " + l.url : " ".repeat(ind) + l));
    out.push(...lines.map(l => cut("    " + l, ctx.width, ctx)));
    if (f.url) out.push("  " + f.url);
  }
  return out;
}

export function ago(epoch, now) {
  const s = Math.max(0, now - epoch);
  return s < 60 ? "now" : s < 3600 ? `${Math.floor(s / 60)}m` : s < 48 * 3600 ? `${Math.floor(s / 3600)}h`
    : s < 14 * 86400 ? `${Math.floor(s / 86400)}d` : `${Math.floor(s / 604800)}w`;
}

export function day(epoch) {
  const d = new Date(epoch * 1000), p = n => String(n).padStart(2, "0");
  return `${d.getFullYear()}-${p(d.getMonth() + 1)}-${p(d.getDate())} ${p(d.getHours())}:${p(d.getMinutes())}`;
}

export function when(epoch, now) {
  const a = ago(epoch, now);
  return `${day(epoch)} (${a === "now" ? a : a + " ago"})`;
}

export function home(path, env = process.env) {
  const h = (env.HOME ?? "").replace(/\/+$/, ""); path = String(path);
  return h && (path === h || path.startsWith(h + "/")) ? "~" + path.slice(h.length) : path;
}

// "30m" "6h" "2d" "1w" → seconds; "YYYY-MM-DD" → seconds from that local midnight to now
export function duration(text, now = Math.floor(Date.now() / 1000)) {
  const m = /^([1-9]\d*)([mhdw])$/.exec(text ?? "");
  if (m) return Number(m[1]) * { m: 60, h: 3600, d: 86400, w: 604800 }[m[2]];
  const d = /^(\d{4})-(\d{2})-(\d{2})$/.exec(text ?? "");
  if (d) {
    const t = new Date(Number(d[1]), Number(d[2]) - 1, Number(d[3]));
    if (t.getFullYear() === Number(d[1]) && t.getMonth() === Number(d[2]) - 1 && t.getDate() === Number(d[3])) return now - t.getTime() / 1000;
  }
  throw new Error(`bad duration '${text}' (30m, 6h, 2d, 1w or YYYY-MM-DD)`);
}

// By prefix, first match wins; `done` only exactly. A compound "blocked on X; waiting on Michael: Y" classes by its first part.
export const END_CLASSES = [
  ["waiting", ["blocked on ", "waiting on Michael"]],
  ["stopped", ["stopped by Michael", "session cap (", "deadline", "weekly budget (", "usage limit (", "merge only"]],
];

export function endClass(reason) {
  const r = String(reason ?? "").replace(/ · \d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\s*$/, "").trim();
  if (r === "done") return "done";
  for (const [cls, prefixes] of END_CLASSES) if (prefixes.some(p => r.startsWith(p))) return cls;
  return "failed";   // the driver's own failures, and any reason this table has not met yet: never a crash
}

function main([cmd]) {
  const ctx = context({ env: process.env, isTTY: process.stdout.isTTY, columns: process.stdout.columns });
  const lines = (() => { try { return readFileSync(0, "utf8"); } catch { return ""; } })().replace(/\r?\n$/, "").split(/\r?\n/);
  let out;
  if (cmd === "table") {
    const cols = lines[0].split("\t").map(s => {
      const [key, min, max, align, flex] = s.split(":");
      return { key, ...(min ? { min: Number(min) } : {}), ...(max ? { max: Number(max) } : {}), ...(align ? { align } : {}), flex: flex === "flex" || flex === "1" };
    });
    out = table(lines.slice(1).filter(Boolean).map(l => Object.fromEntries(l.split("\t").map((v, i) => [cols[i]?.key ?? i, /^-?\d+(\.\d+)?$/.test(v) ? Number(v) : v]))), cols, ctx);
  } else if (cmd === "card") {
    const fields = [];
    for (const l of lines.slice(1)) {
      const [label, ...v] = l.split("\t");
      if (label === "" && fields.length) fields.at(-1).lines.push(v.join("\t"));
      else fields.push({ label, value: v.join("\t"), lines: [] });
    }
    out = card(lines[0] ?? "", fields, ctx);
  } else if (cmd === "section") {
    const [title, count, hint] = lines[0].split("\t");
    out = [section(title, whole(count) ? Number(count) : null, hint ?? "", ctx)];
  } else { console.error("usage: view.mjs table|card|section < tab-separated rows"); return 2; }
  process.stdout.write(out.join("\n") + "\n");
  return 0;
}

if (process.argv[1] && fileURLToPath(import.meta.url) === resolve(process.argv[1])) process.exit(main(process.argv.slice(2)));
