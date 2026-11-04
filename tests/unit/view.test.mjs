// lib/view.mjs: the read views' formatter (context, glyphs, widths, tables, cards, times, end classes).   node --test tests/unit/view.test.mjs
import { test } from "node:test";
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import * as V from "../../lib/view.mjs";

const ctx = (env, isTTY = false, columns) => V.context({ env, isTTY, columns });
const U = ctx({ LANG: "en_US.UTF-8", COLUMNS: "80" }), A = ctx({ LC_ALL: "C", COLUMNS: "80" });
const at = w => ctx({ LANG: "en_US.UTF-8", COLUMNS: String(w) });
// the evals ran under `TZ=… node`; node rereads process.env.TZ on assignment, so a test sets it and puts it back
const inTZ = (tz, fn) => {
  const was = process.env.TZ;
  process.env.TZ = tz;
  try { fn(); } finally { if (was === undefined) delete process.env.TZ; else process.env.TZ = was; }
};

// two names keep the literal '\'' the bash names had (decisions/2026-11-03-unit-tier)
test("view: context width is COLUMNS when a whole number >= 40, else a TTY'\\''s columns, else 100; narrow below 72", () => {
  const got = [ctx({ COLUMNS: "60" }), ctx({ COLUMNS: "80" }), ctx({ COLUMNS: "junk" }), ctx({ COLUMNS: "20" }), ctx({ COLUMNS: "39" }),
    ctx({}, true, 120), ctx({ COLUMNS: "50" }, true, 120)].map(c => `${c.width}:${c.narrow}`);
  assert.deepEqual(got, ["60:true", "80:false", "100:false", "100:false", "100:false", "120:false", "50:true"]);
});

test("view: context tty from isTTY or HARNESS_TTY; colour only on a TTY without NO_COLOR or TERM=dumb, HARNESS_COLOR overrides", () => {
  const got = [ctx({ HARNESS_TTY: "1" }).tty, ctx({ HARNESS_TTY: "0" }, true).tty, ctx({}, true).tty,
    ctx({}, true).color, ctx({ NO_COLOR: "1" }, true).color, ctx({ NO_COLOR: "" }, true).color, ctx({ TERM: "dumb" }, true).color, ctx({}).color,
    ctx({ HARNESS_TTY: "1" }).color, ctx({ HARNESS_COLOR: "always", NO_COLOR: "1" }).color, ctx({ HARNESS_COLOR: "never" }, true).color];
  assert.deepEqual(got, [true, false, true, true, false, true, false, false, true, true, false]);
});

test("view: glyphs unicode from the first set of LC_ALL, LC_CTYPE, LANG naming UTF-8; HARNESS_GLYPHS overrides; ascii otherwise", () => {
  const got = [ctx({ LC_ALL: "C", LANG: "en_US.UTF-8" }), ctx({ LANG: "en_US.UTF-8" }), ctx({ LC_CTYPE: "de_DE.utf8" }), ctx({}),
    ctx({ LANG: "en_US.UTF-8", HARNESS_GLYPHS: "ascii" }), ctx({ LC_ALL: "C", HARNESS_GLYPHS: "unicode" })].map(c => c.glyphs);
  assert.deepEqual(got, ["ascii", "unicode", "unicode", "ascii", "ascii", "unicode"]);
});

test("view: context now is HARNESS_NOW when a whole number, else the clock", () => {
  const t = Math.floor(Date.now() / 1000), c = ctx({ HARNESS_NOW: "1761524400" }).now, d = ctx({ HARNESS_NOW: "x" }).now;
  assert.equal(c, 1761524400);
  assert.ok(Math.abs(d - t) <= 5, `clock ${d}, now ${t}`);
});

test("view: the glyph set is fixed, each one text-presentation code point of width 1, with its ASCII form; an unknown name throws", () => {
  const set = { running: ["●", "*"], done: ["✓", "+"], failed: ["✗", "x"], stopped: ["■", "#"], paused: ["‖", "="], needs: ["⚠", "!"],
    queued: ["○", "o"], sep: ["·", "-"], rule: ["─", "-"], cut: ["…", "..."] };
  assert.equal(JSON.stringify(V.GLYPHS), JSON.stringify(set));
  for (const [name, [u, a]] of Object.entries(set)) {
    const g = V.glyph(name, U);
    assert.equal(g, u, name);
    assert.equal(V.glyph(name, A), a, name);
    assert.equal([...g].length, 1, name);
    assert.equal(V.displayWidth(g), 1, name);
    assert.doesNotMatch(g, /\p{Emoji_Presentation}|️/u, name);
    assert.notEqual(g, "⏸", name);
  }
  assert.throws(() => V.glyph("pausd", U), { message: /pausd/ });
});

test("view: displayWidth ignores ANSI escapes and combining marks and counts wide characters 2", () => {
  assert.deepEqual([V.displayWidth("漢"), V.displayWidth("\x1b[31m✗\x1b[0m failed"), V.displayWidth("é"), V.displayWidth("ab漢cd"), V.displayWidth("")],
    [2, 8, 1, 6, 0]);
});

test("view: paint wraps in SGR only with colour on; an unknown style throws", () => {
  const on = ctx({ HARNESS_COLOR: "always" });
  assert.equal(V.paint("x", "red", U), "x");
  assert.equal(V.paint("x", "red", on), "\x1b[31mx\x1b[0m");
  assert.equal(V.paint("x", "dim", on), "\x1b[2mx\x1b[0m");
  assert.throws(() => V.paint("x", "mauve", on), { message: /mauve/ });
});

test("view: cut never splits a code point or an SGR sequence and ends in the cut glyph; pad right-aligns numbers", () => {
  const got = [V.cut("ab漢cd", 4, U), V.cut("ab漢cd", 4, A), V.cut("ab漢cd", 6, U), V.cut("✓✓✓✓✓", 3, U), V.cut("\x1b[31mredred\x1b[0m", 4, U), V.cut("abc", 2, A),
    V.pad(7, 4), V.pad("ab", 4), V.pad("漢", 4, "right"), V.pad("toolong", 3)];
  assert.deepEqual(got, ["ab…", "a...", "ab漢cd", "✓✓…", "\x1b[31mred\x1b[0m…", "..", "   7", "ab  ", "  漢", "toolong"]);
});

test("view: table lines stay within 40, 60, 80 and 120 columns with a 60-character id whole and a 300-character reason cut", () => {
  const id = "run-" + "x".repeat(52) + "-end", reason = ("why " + "y".repeat(9) + " ").repeat(22).slice(0, 300);
  const rows = [{ id, reason, n: 7, age: "3h" }, { id: "short", reason: "done", n: 12, age: "now" }];
  const cols = [{ key: "id", cut: false }, { key: "reason", flex: true }, { key: "n", align: "right" }, { key: "age", align: "right" }];
  assert.equal(id.length, 60);
  assert.equal(reason.length, 300);
  for (const w of [40, 60, 80, 120]) {
    const c = at(w), lines = V.table(rows, cols, c), text = lines.join("\n");
    assert.equal(lines.find(l => V.displayWidth(l) > w), undefined, `${w}: too wide`);
    assert.ok(text.replace(/\n/g, "").includes(id), `${w}: id cut`);
    if (w >= 60) assert.ok(lines.some(l => l === id || l.startsWith(id + "  ")), `${w}: id not whole on its line`);
    if (w < 80) assert.ok(lines.some(l => /^ +7   3h$/.test(l)), `${w}: the numbers of an over-wide row not on their own right-aligned line\n${text}`);
    assert.ok(lines.some(l => /why [^…]*…/.test(l)), `${w}: reason not cut with …\n${text}`);
    assert.ok(!text.includes(reason), `${w}: reason whole\n${text}`);
    assert.deepEqual(lines.filter(l => l.includes("…") && !l.includes("why")), [], `${w}: an ellipsis outside the flex column`);
    if (c.narrow) assert.ok(lines.includes("  done"), `${w}: narrow: the flex value not on its own indented line\n${text}`);
    if (w === 120) assert.match(text, /^short +done +12 +now$/m, `${w}: normal: short row`);
  }
});

test("view: table puts a row'\\''s sub lines under it at 4 and gives no second line to an empty flex value when narrow", () => {
  const cols = [{ key: "id", cut: false }, { key: "why", flex: true }, { key: "n", align: "right" }];
  const n = V.table([{ id: "a", why: "", n: 1 }, { id: "b", why: "w", n: 2, sub: ["lane M1 · x"] }], cols, at(60));
  assert.deepEqual(n.map(l => l.replace(/ +(?=\d$)/, " ")), ["a 1", "b 2", "  w", "    lane M1 · x"]);
});

test("view: an over-wide narrow row breaks at a column gap before folding: an id that fits the width stays whole, no blank line", () => {
  const id = "agent-harness-2026-10-28-read-views-U1", c40 = at(40);
  const a = V.table([{ g: "●", id, why: "running U1-03", n: 3, age: "4m" }], [{ key: "g" }, { key: "id", cut: false }, { key: "why", flex: true }, { key: "n" }, { key: "age", align: "right" }], c40);
  const b = V.table([{ g: "●", id: "y".repeat(39), n: 3 }], [{ key: "g" }, { key: "id", cut: false }, { key: "n" }], c40);
  const c = V.table([{ why: "w", id: "x".repeat(50) }], [{ key: "why", flex: true }, { key: "id", cut: false }], c40);
  assert.ok(a.includes(id), "a: id");
  assert.ok(a.includes("●"), "a: glyph");
  assert.ok(a.includes("  running U1-03"), "a: flex");
  assert.match(a.find(l => /4m$/.test(l)) ?? "", /^ +3  4m$/);
  assert.ok(b.includes("y".repeat(39)), "b: id");
  assert.deepEqual([...a, ...b, ...c].filter(l => V.displayWidth(l) > 40), []);
  assert.ok(!c.includes(""), "c: a blank line");
  assert.equal(c.join(""), "x".repeat(50) + "  w");
  const t = V.table([{ id: "a", why: "tab\there\nnewline" }], [{ key: "id" }, { key: "why", flex: true }], at(80));
  assert.equal(t.length, 1);
  assert.doesNotMatch(t[0], /[\t\n]/);
});

test("view: card puts a URL inside a value on its own line at 2, splits a value at newlines, keeps a long label and a tiny width inside the line", () => {
  const url = "https://github.com/mh550/agent-harness/pull/" + "1".repeat(40);
  const c = V.card("h", [{ label: "pr", value: `see ${url} now` }, { label: "note", value: "line one\nline two" }, { label: "l".repeat(50), value: "v" }], at(40));
  assert.equal(c.find(l => V.displayWidth(l) > 40 && l !== "  " + url), undefined);
  assert.deepEqual(c.slice(2, 6), ["  pr         see", "  " + url, "             now", "  note       line one"]);
  assert.equal(c[6], " ".repeat(13) + "line two");
  const tiny = V.card("h", [{ label: "ended", value: "a few words here to wrap" }], ctx({ LANG: "C.UTF-8" }, true, 20));
  assert.deepEqual(tiny.filter(l => V.displayWidth(l) > 20), []);
});

test("view: when and duration use local time: 00:19 and a local midnight under TZ=America/New_York", () => inTZ("America/New_York", () => {
  const then = Date.UTC(2026, 9, 27, 4, 19) / 1000, now = Date.UTC(2026, 9, 27, 10, 0) / 1000;
  assert.equal(V.when(then, then + 3600), "2026-10-27 00:19 (1h ago)");
  assert.equal(V.duration("2026-10-20", now), 7 * 86400 + 6 * 3600);
  assert.equal(V.home("/home/m/x", { HOME: "/home/m/" }), "~/x");
  assert.equal(V.home("/x", { HOME: "/" }), "/x");
}));

test("view: section fills to the width with the rule glyph; an empty one is one line without the rule; rule is the width", () => {
  const s = V.section("NEEDS YOU", 1, "harness needs", U), f = V.section("FINISHED", null, "last 24h · 3", at(60)), e = V.section("QUEUED", 0, "runner off", U);
  assert.equal(V.displayWidth(s), 80);
  assert.match(s, /^NEEDS YOU 1 · harness needs ─+$/);
  assert.equal(V.displayWidth(f), 60);
  assert.match(f, /^FINISHED · last 24h · 3 ─+$/);
  assert.equal(e, "QUEUED 0 · runner off");
  assert.equal(V.section("QUEUED", 0, "", A), "QUEUED 0");
  assert.equal(V.rule(A), "-".repeat(80));
  assert.equal(V.rule(at(60)), "─".repeat(60));
});

test("view: card wraps a 200-character value under an 11-wide label with a hanging indent, keeps lines verbatim at 4 and a URL whole", () => {
  const val = ("word" + "s".repeat(5) + " ").repeat(20).trim().slice(0, 200), url = "https://github.com/mh550/agent-harness/pull/" + "9".repeat(80);
  const c = V.card("■ run · proj · stopped", [{ label: "ended", value: val }, { label: "empty", value: "" },
    { label: "lanes", value: "", lines: ["lane M1 · B · session 2"] }, { label: "pr", value: "open", url }, { label: "path", value: "/a/b/" + "c".repeat(70) + "/d/e" }], at(60));
  assert.deepEqual(c.filter(l => V.displayWidth(l) > 60 && l !== "  " + url), [], "too wide");
  assert.equal(c[0], "■ run · proj · stopped");
  assert.equal(c[1], "─".repeat(60));
  const body = c.slice(2);
  assert.equal(body.findIndex(l => l.startsWith("  ended      words")), 0, "hanging");
  assert.ok(body[1].startsWith(" ".repeat(13) + "word"), `hanging: ${body[1]}`);
  assert.equal(body.slice(0, body.findIndex(l => l.startsWith("  lanes"))).map(l => l.slice(13)).join(" "), val, "wrap lost words");
  assert.ok(!body.some(l => l.startsWith("  empty")), "empty field kept");
  assert.ok(body.includes("  lanes"), "lines: label");
  assert.ok(body.includes("    lane M1 · B · session 2"), "lines: verbatim at 4");
  assert.ok(body.includes("  " + url), "url whole");
  assert.ok(body.includes("  pr         open"), "url's value");
  assert.equal(body.slice(body.findIndex(l => l.startsWith("  path"))).map(l => l.slice(13)).join(""), "/a/b/" + "c".repeat(70) + "/d/e", "path rejoined");
});

test("view: ago gives now 4m 3h 2d 5w for 0 s, 240 s, 3 h, 2 d and 5 w before now; a future time is now", () => {
  const now = 1761559200;
  assert.deepEqual([0, 240, 3 * 3600, 2 * 86400, 5 * 7 * 86400, -60, 59, 47 * 3600, 13 * 86400].map(s => V.ago(now - s, now)),
    ["now", "4m", "3h", "2d", "5w", "now", "now", "47h", "13d"]);
});

test("view: when gives 2026-10-27 00:19 (10h ago) under TZ=UTC, and (now) under a minute", () => inTZ("UTC", () => {
  const then = Date.UTC(2026, 9, 27, 0, 19) / 1000;
  assert.equal(V.when(then, then + 10 * 3600 + 30), "2026-10-27 00:19 (10h ago)");
  assert.equal(V.when(then, then + 30), "2026-10-27 00:19 (now)");
}));

test("view: duration takes 30m 6h 2d 1w and a date relative to now, and fails on abc", () => inTZ("UTC", () => {
  const now = Date.UTC(2026, 9, 27, 10, 0) / 1000;
  assert.deepEqual(["30m", "6h", "2d", "1w", "2026-10-20"].map(t => V.duration(t, now)), [1800, 21600, 172800, 604800, 7 * 86400 + 36000]);
  for (const bad of ["abc", "0h", "3x", "2026-13-01", ""])
    assert.throws(() => V.duration(bad, now), { message: /^bad duration .* \(30m, 6h, 2d, 1w or YYYY-MM-DD\)$/ }, JSON.stringify(bad));
}));

test("view: home shortens a path under the home directory to a tilde and leaves other paths", () => {
  const env = { HOME: "/home/m" };
  assert.deepEqual([V.home("/home/m/worktrees/x", env), V.home("/home/m", env), V.home("/home/mx/y", env), V.home("/tmp/h", env), V.home("/x", {})],
    ["~/worktrees/x", "~", "/home/mx/y", "/tmp/h", "/x"]);
});

test("view: endClass gives each reason in tests/fixtures/end-reasons.txt its class; an unknown or empty reason is failed", () => {
  const lines = readFileSync(new URL("../fixtures/end-reasons.txt", import.meta.url), "utf8").split("\n").filter(l => l && !l.startsWith("#"));
  const classes = new Set();
  for (const l of lines) { const [want, reason] = l.split("\t"); classes.add(want); assert.equal(V.endClass(reason), want, reason); }
  assert.ok(lines.length >= 20, `fixture: ${lines.length} lines`);
  assert.equal(classes.size, 4, [...classes].join());
  assert.equal(V.endClass("some new reason"), "failed");
  assert.equal(V.endClass(""), "failed");
  assert.equal(V.endClass(null), "failed");
});

test("tty views: gcView shortens the home directory to a tilde and counts a branch named twice once", () => {
  const c = V.context({ env: { COLUMNS: "60", HARNESS_GLYPHS: "ascii" } }), R = String.fromCharCode(30), d = "-".repeat(60);
  const out = V.gcView([R + "UNITS", R + "TMUX", R + "DESKS", R + "WORKTREES", "would: git -C /h/u/my p worktree remove --force /h/u/wt/p/a",
    "keeps /h/u/wt/p/b: its desk is open (harness desk --close b)", R + "DEPS", "keeps the deps of /h/u/wt/p/b: its desk is open",
    R + "BRANCHES", "would: git -C /h/u/p branch -d harness/a", "would: git -C /h/u/p push -q origin --delete harness/a", R + "END"].join("\n"), c, { HOME: "/h/u" });
  assert.deepEqual(out, ["UNITS 0", "TMUX 0", "DESKS 0", "WORKTREES 2 " + d.slice(12), "would: git -C ~/my p worktree remove --force ~/wt/p/a",
    "keeps ~/wt/p/b: its desk is open (harness desk --close b)", "DEPS 1 " + d.slice(7), "keeps the deps of ~/wt/p/b: its desk is open",
    "BRANCHES 2 " + d.slice(11), "would: git -C ~/p branch -d harness/a", "would: git -C ~/p push -q origin --delete harness/a", d,
    "would remove 1 worktree, 1 branch; keeps 1"]);
  const cutShort = V.gcView([R + "UNITS", "? x", R + "TMUX"].join("\n"), c, {});
  assert.deepEqual(cutShort, ["UNITS 1 " + d.slice(8), "? x", "TMUX 0", "gc stopped before DESKS (see the error above)"]);
});

// view.mjs's cutFront and card as the needs cards use them (59-needs-cards.sh)
test("view.mjs cutFront keeps the end from a directory boundary; card with rule: false has no rule; a url-only field is the url line alone", () => {
  const c = V.context({ env: { HARNESS_GLYPHS: "unicode" } }), p = "/home/u/worktrees/n8n-home/n8n-home-2026-10-22/deploy/compose.yml:48";
  const k = V.card("h", [{ label: "x", value: "1" }, { label: "", url: "https://e.x/a" }], c, { rule: false });
  assert.equal(V.cutFront(p, 47, c), "…/n8n-home-2026-10-22/deploy/compose.yml:48");
  assert.equal(V.cutFront("short", 10, c), "short");
  assert.ok(V.displayWidth(V.cutFront(p, 30, c)) <= 30, V.cutFront(p, 30, c));
  assert.equal(k.join("|"), "h|  x          1|  https://e.x/a");
  assert.match(V.card("h", [], c)[1], /^─/);
});
