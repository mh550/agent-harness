#!/usr/bin/env bash
source "$(dirname "$0")/../lib.sh" && suite_setup
# ---- the read views' formatter, pure (U1): view.mjs context, glyphs, widths, tables, cards, times, end classes ----
V='import * as V from "'$HERE'/../lib/view.mjs";
  const ctx = (env, isTTY = false, columns) => V.context({ env, isTTY, columns });
  const U = ctx({ LANG: "en_US.UTF-8", COLUMNS: "80" }), A = ctx({ LC_ALL: "C", COLUMNS: "80" });
  const at = w => ctx({ LANG: "en_US.UTF-8", COLUMNS: String(w) });
  const fail = (...m) => { console.error(...m); process.exit(1); };'
check "view: lib/view.mjs has a usage header, imports only node: built-ins, exports the formatter's functions, and node --check passes" '
  [[ $(head -1 "$HERE/../lib/view.mjs") == "// "*formatter* ]] && node --check "$HERE/../lib/view.mjs" \
  && [[ -n $(grep "^import " "$HERE/../lib/view.mjs") && -z $(grep "^import " "$HERE/../lib/view.mjs" | grep -v " from \"node:") ]] \
  && node --input-type=module -e "$V"'\''
  const want = "context glyph paint displayWidth cut pad table section rule card ago when home duration endClass".split(" ");
  const miss = want.filter(f => typeof V[f] !== "function"); if (miss.length) fail("missing", miss);'\'
check "view: context width is COLUMNS when a whole number >= 40, else a TTY'\''s columns, else 100; narrow below 72" 'node --input-type=module -e "$V"'\''
  const got = [ctx({ COLUMNS: "60" }), ctx({ COLUMNS: "80" }), ctx({ COLUMNS: "junk" }), ctx({ COLUMNS: "20" }), ctx({ COLUMNS: "39" }), ctx({}, true, 120), ctx({ COLUMNS: "50" }, true, 120)]
    .map(c => `${c.width}:${c.narrow}`).join();
  if (got !== "60:true,80:false,100:false,100:false,100:false,120:false,50:true") fail(got);'\'
check "view: context tty from isTTY or HARNESS_TTY; colour only on a TTY without NO_COLOR or TERM=dumb, HARNESS_COLOR overrides" 'node --input-type=module -e "$V"'\''
  const got = [ctx({ HARNESS_TTY: "1" }).tty, ctx({ HARNESS_TTY: "0" }, true).tty, ctx({}, true).tty,
    ctx({}, true).color, ctx({ NO_COLOR: "1" }, true).color, ctx({ NO_COLOR: "" }, true).color, ctx({ TERM: "dumb" }, true).color, ctx({}).color,
    ctx({ HARNESS_TTY: "1" }).color, ctx({ HARNESS_COLOR: "always", NO_COLOR: "1" }).color, ctx({ HARNESS_COLOR: "never" }, true).color].join();
  if (got !== "true,false,true,true,false,true,false,false,true,true,false") fail(got);'\'
check "view: glyphs unicode from the first set of LC_ALL, LC_CTYPE, LANG naming UTF-8; HARNESS_GLYPHS overrides; ascii otherwise" 'node --input-type=module -e "$V"'\''
  const got = [ctx({ LC_ALL: "C", LANG: "en_US.UTF-8" }), ctx({ LANG: "en_US.UTF-8" }), ctx({ LC_CTYPE: "de_DE.utf8" }), ctx({}),
    ctx({ LANG: "en_US.UTF-8", HARNESS_GLYPHS: "ascii" }), ctx({ LC_ALL: "C", HARNESS_GLYPHS: "unicode" })].map(c => c.glyphs).join();
  if (got !== "ascii,unicode,unicode,ascii,ascii,unicode") fail(got);'\'
check "view: context now is HARNESS_NOW when a whole number, else the clock" 'node --input-type=module -e "$V"'\''
  const t = Math.floor(Date.now() / 1000), c = ctx({ HARNESS_NOW: "1761524400" }).now, d = ctx({ HARNESS_NOW: "x" }).now;
  if (c !== 1761524400 || Math.abs(d - t) > 5) fail(c, d);'\'
check "view: the glyph set is fixed, each one text-presentation code point of width 1, with its ASCII form; an unknown name throws" 'node --input-type=module -e "$V"'\''
  const set = { running: ["●", "*"], done: ["✓", "+"], failed: ["✗", "x"], stopped: ["■", "#"], paused: ["‖", "="], needs: ["⚠", "!"],
    queued: ["○", "o"], sep: ["·", "-"], rule: ["─", "-"], cut: ["…", "..."] };
  if (JSON.stringify(V.GLYPHS) !== JSON.stringify(set)) fail("GLYPHS", V.GLYPHS);
  for (const [name, [u, a]] of Object.entries(set)) {
    const g = V.glyph(name, U);
    if (g !== u || V.glyph(name, A) !== a || [...g].length !== 1 || V.displayWidth(g) !== 1 || /\p{Emoji_Presentation}|️/u.test(g) || g === "⏸") fail(name, g);
  }
  try { V.glyph("pausd", U); fail("no throw"); } catch (e) { if (!/pausd/.test(e.message)) fail(e.message); }'\'
check "view: displayWidth ignores ANSI escapes and combining marks and counts wide characters 2" 'node --input-type=module -e "$V"'\''
  const got = [V.displayWidth("漢"), V.displayWidth("\x1b[31m✗\x1b[0m failed"), V.displayWidth("é"), V.displayWidth("ab漢cd"), V.displayWidth("")].join();
  if (got !== "2,8,1,6,0") fail(got);'\'
check "view: paint wraps in SGR only with colour on; an unknown style throws" 'node --input-type=module -e "$V"'\''
  const on = ctx({ HARNESS_COLOR: "always" });
  if (V.paint("x", "red", U) !== "x" || V.paint("x", "red", on) !== "\x1b[31mx\x1b[0m" || V.paint("x", "dim", on) !== "\x1b[2mx\x1b[0m") fail("paint");
  try { V.paint("x", "mauve", on); fail("no throw"); } catch (e) { if (!/mauve/.test(e.message)) fail(e.message); }'\'
check "view: cut never splits a code point or an SGR sequence and ends in the cut glyph; pad right-aligns numbers" 'node --input-type=module -e "$V"'\''
  const got = [V.cut("ab漢cd", 4, U), V.cut("ab漢cd", 4, A), V.cut("ab漢cd", 6, U), V.cut("✓✓✓✓✓", 3, U), V.cut("\x1b[31mredred\x1b[0m", 4, U), V.cut("abc", 2, A),
    V.pad(7, 4), V.pad("ab", 4), V.pad("漢", 4, "right"), V.pad("toolong", 3)];
  const want = ["ab…", "a...", "ab漢cd", "✓✓…", "\x1b[31mred\x1b[0m…", "..", "   7", "ab  ", "  漢", "toolong"];
  const bad = got.findIndex((g, i) => g !== want[i]); if (bad >= 0) fail(bad, JSON.stringify(got[bad]));'\'
check "view: table lines stay within 40, 60, 80 and 120 columns with a 60-character id whole and a 300-character reason cut" 'node --input-type=module -e "$V"'\''
  const id = "run-" + "x".repeat(52) + "-end", reason = ("why " + "y".repeat(9) + " ").repeat(22).slice(0, 300);
  const rows = [{ id, reason, n: 7, age: "3h" }, { id: "short", reason: "done", n: 12, age: "now" }];
  const cols = [{ key: "id", cut: false }, { key: "reason", flex: true }, { key: "n", align: "right" }, { key: "age", align: "right" }];
  if (id.length !== 60 || reason.length !== 300) fail("fixture", id.length, reason.length);
  for (const w of [40, 60, 80, 120]) {
    const c = at(w), lines = V.table(rows, cols, c), text = lines.join("\n");
    const wide = lines.find(l => V.displayWidth(l) > w); if (wide) fail(w, "too wide:", wide);
    if (!text.replace(/\n/g, "").includes(id)) fail(w, "id cut");
    if (w >= 60 && !lines.some(l => l === id || l.startsWith(id + "  "))) fail(w, "id not whole on its line");
    if (w < 80 && !lines.some(l => /^ +7   3h$/.test(l))) fail(w, "the numbers of an over-wide row not on their own right-aligned line", text);
    if (!lines.some(l => /why [^…]*…/.test(l)) || text.includes(reason)) fail(w, "reason not cut with …", text);
    if (lines.some(l => l.includes("…") && !l.includes("why"))) fail(w, "an ellipsis outside the flex column");
    if (c.narrow && !lines.includes("  done")) fail(w, "narrow: the flex value not on its own indented line", text);
    if (w === 120 && !/^short +done +12 +now$/m.test(text)) fail(w, "normal: short row", text);
  }'\'
check "view: table puts a row'\''s sub lines under it at 4 and gives no second line to an empty flex value when narrow" 'node --input-type=module -e "$V"'\''
  const cols = [{ key: "id", cut: false }, { key: "why", flex: true }, { key: "n", align: "right" }];
  const n = V.table([{ id: "a", why: "", n: 1 }, { id: "b", why: "w", n: 2, sub: ["lane M1 · x"] }], cols, at(60));
  if (JSON.stringify(n.map(l => l.replace(/ +(?=\d$)/, " "))) !== JSON.stringify(["a 1", "b 2", "  w", "    lane M1 · x"])) fail(JSON.stringify(n));'\'
check "view: an over-wide narrow row breaks at a column gap before folding: an id that fits the width stays whole, no blank line" 'node --input-type=module -e "$V"'\''
  const id = "agent-harness-2026-10-28-read-views-U1", c40 = at(40);
  const a = V.table([{ g: "●", id, why: "running U1-03", n: 3, age: "4m" }], [{ key: "g" }, { key: "id", cut: false }, { key: "why", flex: true }, { key: "n" }, { key: "age", align: "right" }], c40);
  const b = V.table([{ g: "●", id: "y".repeat(39), n: 3 }], [{ key: "g" }, { key: "id", cut: false }, { key: "n" }], c40);
  const c = V.table([{ why: "w", id: "x".repeat(50) }], [{ key: "why", flex: true }, { key: "id", cut: false }], c40);
  if (!a.includes(id) || !a.includes("●") || !a.includes("  running U1-03") || !/^ +3  4m$/.test(a.find(l => /4m$/.test(l)) ?? "")) fail("a", a);
  if (!b.includes("y".repeat(39)) || [...a, ...b, ...c].some(l => V.displayWidth(l) > 40)) fail("b", b);
  if (c.includes("") || c.join("") !== "x".repeat(50) + "  w") fail("c", c);
  const t = V.table([{ id: "a", why: "tab\there\nnewline" }], [{ key: "id" }, { key: "why", flex: true }], at(80));
  if (t.length !== 1 || /[\t\n]/.test(t[0])) fail("control characters in a cell", t);'\'
check "view: card puts a URL inside a value on its own line at 2, splits a value at newlines, keeps a long label and a tiny width inside the line" 'node --input-type=module -e "$V"'\''
  const url = "https://github.com/mh550/agent-harness/pull/" + "1".repeat(40);
  const c = V.card("h", [{ label: "pr", value: `see ${url} now` }, { label: "note", value: "line one\nline two" }, { label: "l".repeat(50), value: "v" }], at(40));
  if (c.find(l => V.displayWidth(l) > 40 && l !== "  " + url)) fail("too wide", c);
  if (JSON.stringify(c.slice(2, 6)) !== JSON.stringify(["  pr         see", "  " + url, "             now", "  note       line one"]) || c[6] !== " ".repeat(13) + "line two") fail(c);
  const tiny = V.card("h", [{ label: "ended", value: "a few words here to wrap" }], ctx({ LANG: "C.UTF-8" }, true, 20));
  if (tiny.some(l => V.displayWidth(l) > 20)) fail("tiny", tiny);'\'
check "view: when and duration use local time: 00:19 and a local midnight under TZ=America/New_York" 'TZ=America/New_York node --input-type=module -e "$V"'\''
  const then = Date.UTC(2026, 9, 27, 4, 19) / 1000, now = Date.UTC(2026, 9, 27, 10, 0) / 1000;
  if (V.when(then, then + 3600) !== "2026-10-27 00:19 (1h ago)" || V.duration("2026-10-20", now) !== 7 * 86400 + 6 * 3600) fail(V.when(then, then + 3600), V.duration("2026-10-20", now));
  if (V.home("/home/m/x", { HOME: "/home/m/" }) !== "~/x" || V.home("/x", { HOME: "/" }) !== "/x") fail("home");'\'
check "view: section fills to the width with the rule glyph; an empty one is one line without the rule; rule is the width" 'node --input-type=module -e "$V"'\''
  const s = V.section("NEEDS YOU", 1, "harness needs", U), f = V.section("FINISHED", null, "last 24h · 3", at(60)), e = V.section("QUEUED", 0, "runner off", U);
  if (V.displayWidth(s) !== 80 || !/^NEEDS YOU 1 · harness needs ─+$/.test(s)) fail(s);
  if (V.displayWidth(f) !== 60 || !/^FINISHED · last 24h · 3 ─+$/.test(f)) fail(f);
  if (e !== "QUEUED 0 · runner off" || V.section("QUEUED", 0, "", A) !== "QUEUED 0") fail(e);
  if (V.rule(A) !== "-".repeat(80) || V.rule(at(60)) !== "─".repeat(60)) fail("rule");'\'
check "view: card wraps a 200-character value under an 11-wide label with a hanging indent, keeps lines verbatim at 4 and a URL whole" 'node --input-type=module -e "$V"'\''
  const val = ("word" + "s".repeat(5) + " ").repeat(20).trim().slice(0, 200), url = "https://github.com/mh550/agent-harness/pull/" + "9".repeat(80);
  const c = V.card("■ run · proj · stopped", [{ label: "ended", value: val }, { label: "empty", value: "" },
    { label: "lanes", value: "", lines: ["lane M1 · B · session 2"] }, { label: "pr", value: "open", url }, { label: "path", value: "/a/b/" + "c".repeat(70) + "/d/e" }], at(60));
  const wide = c.filter(l => V.displayWidth(l) > 60 && l !== "  " + url);
  if (wide.length) fail("too wide", wide);
  if (c[0] !== "■ run · proj · stopped" || c[1] !== "─".repeat(60)) fail("header", c[0], c[1]);
  const body = c.slice(2), ended = body.findIndex(l => l.startsWith("  ended      words"));
  if (ended !== 0 || !body[1].startsWith(" ".repeat(13) + "word")) fail("hanging", body.slice(0, 2));
  const back = body.slice(0, body.findIndex(l => l.startsWith("  lanes"))).map(l => l.slice(13)).join(" ");
  if (back !== val) fail("wrap lost words", back);
  if (body.some(l => l.startsWith("  empty"))) fail("empty field kept");
  if (!body.includes("  lanes") || !body.includes("    lane M1 · B · session 2")) fail("lines", body);
  if (!body.includes("  " + url) || !body.includes("  pr         open")) fail("url", body);
  const p = body.slice(body.findIndex(l => l.startsWith("  path"))).map(l => l.slice(13)).join("");
  if (p !== "/a/b/" + "c".repeat(70) + "/d/e") fail("path rejoined", p);'\'
check "view: ago gives now 4m 3h 2d 5w for 0 s, 240 s, 3 h, 2 d and 5 w before now; a future time is now" 'node --input-type=module -e "$V"'\''
  const now = 1761559200, got = [0, 240, 3 * 3600, 2 * 86400, 5 * 7 * 86400, -60, 59, 47 * 3600, 13 * 86400].map(s => V.ago(now - s, now)).join();
  if (got !== "now,4m,3h,2d,5w,now,now,47h,13d") fail(got);'\'
check "view: when gives 2026-10-27 00:19 (10h ago) under TZ=UTC, and (now) under a minute" 'TZ=UTC node --input-type=module -e "$V"'\''
  const then = Date.UTC(2026, 9, 27, 0, 19) / 1000, w = [V.when(then, then + 10 * 3600 + 30), V.when(then, then + 30)];
  if (w[0] !== "2026-10-27 00:19 (10h ago)" || w[1] !== "2026-10-27 00:19 (now)") fail(w);'\'
check "view: duration takes 30m 6h 2d 1w and a date relative to now, and fails on abc" 'TZ=UTC node --input-type=module -e "$V"'\''
  const now = Date.UTC(2026, 9, 27, 10, 0) / 1000;
  const got = ["30m", "6h", "2d", "1w", "2026-10-20"].map(t => V.duration(t, now)).join();
  if (got !== `1800,21600,172800,604800,${7 * 86400 + 36000}`) fail(got);
  for (const bad of ["abc", "0h", "3x", "2026-13-01", ""]) try { V.duration(bad, now); fail("no throw", bad); } catch (e) { if (!/^bad duration .* \(30m, 6h, 2d, 1w or YYYY-MM-DD\)$/.test(e.message)) fail(e.message); }'\'
check "view: home shortens a path under the home directory to a tilde and leaves other paths" 'node --input-type=module -e "$V"'\''
  const env = { HOME: "/home/m" };
  const got = [V.home("/home/m/worktrees/x", env), V.home("/home/m", env), V.home("/home/mx/y", env), V.home("/tmp/h", env), V.home("/x", {})].join();
  if (got !== "~/worktrees/x,~,/home/mx/y,/tmp/h,/x") fail(got);'\'
check "view: endClass gives each reason in tests/fixtures/end-reasons.txt its class; an unknown or empty reason is failed" 'node --input-type=module -e "$V"'\''
  const lines = (await import("node:fs")).readFileSync("'$HERE'/fixtures/end-reasons.txt", "utf8").split("\n").filter(l => l && !l.startsWith("#"));
  const classes = new Set();
  for (const l of lines) { const [want, reason] = l.split("\t"); classes.add(want); if (V.endClass(reason) !== want) fail(reason, V.endClass(reason), "want", want); }
  if (lines.length < 20 || classes.size !== 4) fail("fixture", lines.length, [...classes]);
  if (V.endClass("some new reason") !== "failed" || V.endClass("") !== "failed" || V.endClass(null) !== "failed") fail("unknown");'\'
check "view: tests/fixtures/end-reasons.txt holds every literal reason finish, END_REASON and a run-ending lane exit write" '
  R=$(grep -v "^#" "$HERE/fixtures/end-reasons.txt" | cut -f2) miss=""
  lits=$( { grep -o "finish \"[^\"\$]*" "$HERE/../lib/driver.sh" | sed "s/^finish \"//"
    grep -o "END_REASON=\"[^\"\$]*" "$HERE/../lib/driver.sh" | sed "s/^END_REASON=\"//"
    grep -oE "lane_exit (13 \"[^\"\$]*|12 \"feature-list edits)" "$HERE/../lib/lane.sh" | sed "s/^lane_exit 1[23] \"//"; } | grep . | sort -u)
  while read -r l; do ok=0; while read -r r; do [[ $r == "$l"* ]] && ok=1; done <<< "$R"; (( ok )) || miss+="$l|"; done <<< "$lits"
  [[ $(wc -l <<< "$lits") -ge 12 && -z $miss ]] || { echo "literals: $(wc -l <<< "$lits"), missing: $miss"; false; }'
check "view: the CLI renders a table, a card and a section from tab-separated stdin" '
  t=$(printf "id:::left:\twhy::::flex\tn:::right:\nabc\tsome reason\t7\nlong-id-xyz\tother\t12\n" | COLUMNS=40 HARNESS_GLYPHS=unicode node "$HERE/../lib/view.mjs" table)
  c=$(printf "✓ run · proj · done\nended\tdone\nlanes\t\n\tlane M1 · B\n" | COLUMNS=40 HARNESS_GLYPHS=unicode node "$HERE/../lib/view.mjs" card)
  s=$(printf "RUNNING\t1\t\n" | COLUMNS=40 HARNESS_GLYPHS=ascii node "$HERE/../lib/view.mjs" section)
  [[ $(sed -n 1p <<< "$t") =~ ^abc\ +7$ && $(sed -n 2p <<< "$t") == "  some reason" && $(sed -n 3p <<< "$t") =~ ^long-id-xyz\ +12$ ]] || { echo "table: $t"; false; } \
  && [[ $c == "✓ run · proj · done"$'\''\n'\''"$(printf "─%.0s" {1..40})"$'\''\n  ended      done\n  lanes\n    lane M1 · B'\'' ]] || { echo "card: $c"; false; } \
  && [[ $s == "RUNNING 1 $(printf -- "-%.0s" {1..30})" ]] || { echo "section: $s"; false; } \
  && ! node "$HERE/../lib/view.mjs" frob < /dev/null 2> /dev/null \
  && t=$(printf "id\tn\twhy::::0\r\nabc\t7\tx\r\nabcdef\t12\ty\r\n" | COLUMNS=40 node "$HERE/../lib/view.mjs" table) \
  && [[ $t == "abc      7  x"$'\''\n'\''"abcdef  12  y" ]] || { echo "numbers, flex 0, CRLF: $(cat -A <<< "$t")"; false; } \
  && [[ $(printf "X\tabc\thint\n" | COLUMNS=40 HARNESS_GLYPHS=ascii node "$HERE/../lib/view.mjs" section) == "X - hint "* ]]'
suite_end
