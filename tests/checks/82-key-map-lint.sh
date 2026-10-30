#!/usr/bin/env bash
source "$(dirname "$0")/../lib.sh" && suite_setup
# ---- the key map lint (suite-time S2): CHECK_KEY_MAP names every check file that reads a mapped path ----
# A partial run (lib/check.sh) runs only the map's names on a mapped-only diff, so a check file the map leaves out that
# reads a mapped path would stay green unrun. This lint proves the map over a checks directory, from the files' own lines:
#   keymaplint <checks dir> <map> → one `<file>:<line> reads <path>, not in CHECK_KEY_MAP` per miss (exit 1), else nothing
#   (and one `<path>:<name> matches no check file` per name no file's stem holds)
# For each entry `<path>:<name>…` and each *.sh whose stem holds none of its names (tests/run.sh matches by substring),
# each line that is no full-line comment is tested against two rules over the root expressions R:
#   (a) the line holds an R and names the path or its basename, or names `../<basename>` (any depth): it reads the file
#       (the allowed forms don't apply: `git -C "$HERE/.." show HEAD:CLAUDE.md` reads it);
#   (b) after the allowed forms are cut out, an R is left that is not followed by a sub-path (`/<name>`, no `.` or `..`
#       segment, no glob, brace or variable that could reach the path): the root went to a command, which may read any file under it.
# What it can't see: a read by the code under test (lib/, bin/) or by a helper every check sources (tests/*.sh), and a
# root built some other way. So an entry is only for a file nothing but check-file lines read (decisions/2026-10-30-partial-key).
KML=$(cat <<'JS'
import { readFileSync, readdirSync } from "node:fs";
const { parseMap } = await import(process.env.KML_TREEKEY);
const [dir, map] = process.argv.slice(1), raw = String.raw;
const esc = s => s.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
// the root expressions: every spelling of this checkout's root a check file uses or could
const BASE = [
  raw`\$HERE/\.\.`, raw`\$\{HERE\}/\.\.`, raw`'"\$HERE"'/\.\.`, raw`"\$HERE"/\.\.`, raw`\$\(dirname "\$HERE"\)`, raw`\$\{HERE%/\*\}`,
  raw`\$\(dirname "\$0"\)/\.\./\.\.`, raw`\$\([^()]*rev-parse --show-toplevel[^()]*\)`,
];
const vars = vs => vs.flatMap(v => [raw`\$${v}(?!\w)`, raw`\$\{${v}(?:[:%#/^,@][^}]*)?\}`]);   // $v, ${v} and ${v:-…}, written so this file names no root
BASE.push(...vars(["HH", "HARNESS_HOME"]));   // tests/lib.sh sets HH to the root for every check file
// R: the canonicalized root ($(cd <R> && pwd), $(readlink -f <R>)) first, so it is matched whole, then BASE and the aliases
const rootRe = aliases => {
  const b = [...BASE, ...vars([...aliases])].join("|");
  return `(?:\\$\\(cd "?(?:${b})"? && pwd\\)|\\$\\(readlink -f "?(?:${b})"?\\)|${b})`;
};
const ASSIGN = R => raw`(?:local\s+)?([A-Za-z_]\w*)="?${R}"?(?=[\s;)'"]|$)`;
// the allowed forms: each reads no file under the root, so rule (b) cuts it out of the line before it looks
const ALLOWED = R => [
  raw`HARNESS_HOME="?${R}"?|HARNESS_HOME="?\$\{\w+:-${R}\}"?`,   // the harness run from this checkout reads its lib/, prompts/, templates/, bin/, never its own CLAUDE.md
  raw`git -C "?${R}"? (?:log|rev-parse|cat-file|worktree|ls-files)(?![\w-])`,   // git metadata and names, never a work-tree file's content (grep, diff, show, status read it)
  raw`harness_config "?${R}"?`,   // reads .harness/config.sh only
  ASSIGN(R),   // an alias assignment is a string; the alias's uses are linted in turn
  raw`(?<=\[\[[^\]]*)== "(?:[^"\x60$]|\$(?!\())*${R}"`,   // the right side of a [[ … == … ]] is a string no command reads (13-run-2's "PWD=$HH")
];
const out = [];
const files = readdirSync(dir).filter(f => f.endsWith(".sh")).sort();
for (const { path, names } of parseMap(map, [], () => false).entries) {
  const base = path.split("/").pop(), rel = new RegExp(raw`(?:\.\./)+${esc(base)}`);
  // a name no file holds runs nothing: tests/run.sh is red on it, on every partial of the path
  for (const n of names) if (!files.some(f => f.slice(0, -3).includes(n))) out.push(`${path}:${n} matches no check file`);
  for (const f of files.filter(f => !names.some(n => f.slice(0, -3).includes(n)))) {
    const lines = readFileSync(`${dir}/${f}`, "utf8").split("\n"), code = lines.map(l => /^\s*#/.test(l) ? "" : l);
    // the file's aliases: a name assigned exactly an R anywhere in it, to a fixed point (an alias of an alias)
    const aliases = new Set();
    for (let n = -1; n !== aliases.size;) {
      n = aliases.size; const re = new RegExp(raw`(?:^|[\s;(&|{])` + ASSIGN(rootRe(aliases)), "g");
      for (const l of code) for (const m of l.matchAll(re)) aliases.add(m[1]);
    }
    const R = rootRe(aliases), has = new RegExp(R), each = new RegExp(R, "g"), allowed = ALLOWED(R).map(a => new RegExp(a, "g"));
    code.forEach((l, i) => {
      const a = (has.test(l) && (l.includes(path) || l.includes(base))) || rel.test(l);
      const cut = allowed.reduce((s, re) => s.replace(re, " "), l);
      // a sub-path is a word after R that starts /<name>, has no . or .. segment, and whose literal part before a glob,
      // brace or variable can't lead to the path (<R>/$f and <R>/*.md can; <R>/evals/$t/x.json can't)
      const b = [...cut.matchAll(each)].some(m => { const w = cut.slice(m.index + m[0].length).match(/^[^\s"'`;|&<>()]*/)[0];
        if (!/^\/[\w-]/.test(w) || /(^|\/)\.\.?(\/|$)/.test(w)) return true;
        const lit = w.slice(1).split(/[*?[{$]/)[0]; return lit.length < w.length - 1 && path.startsWith(lit); });
      if (a || b) out.push(`${f}:${i + 1} reads ${path}, not in CHECK_KEY_MAP`);
    });
  }
}
if (out.length) { console.log(out.join("\n")); process.exit(1); }
JS
)
keymaplint() { KML_TREEKEY=$HERE/../lib/treekey.mjs node --input-type=module -e "$KML" "$@"; }
MAP=$( HARNESS_HOME=$HH; source "$HERE/../lib/config.sh" && HARNESS_CONFIG=/dev/null harness_config "$HERE/.." && printf %s "$CHECK_KEY_MAP" )
FX=$HERE/fixtures/key-map-lint
lc() { rm -rf "$T/lc" && cp -r "$HERE/checks" "$T/lc" && for f; do cp "$FX/$f.sh" "$T/lc/"; done; }   # a copy of tests/checks/ with these fixtures
lc reads-claude; o1=$(keymaplint "$T/lc" "$MAP"); c1=$?
check "key map lint: a check file reading the root's CLAUDE.md outside the map is named with its line, exit 1" \
  '(( c1 == 1 )) && [[ $o1 == "reads-claude.sh:2 reads CLAUDE.md, not in CHECK_KEY_MAP" ]]'
lc bare-root; o2=$(keymaplint "$T/lc" "$MAP"); c2=$?
check "key map lint: a check file passing the bare root to a new command is named with its line, exit 1" \
  '(( c2 == 1 )) && [[ $o2 == "bare-root.sh:2 reads CLAUDE.md, not in CHECK_KEY_MAP" ]]'
lc reads-claude bare-root; o3=$(keymaplint "$T/lc" "$MAP:reads-claude:bare-root"); c3=$?
check "key map lint: both files pass once the map's CLAUDE.md entry names them" '(( c3 == 0 )) && [[ -z $o3 ]]'
ok=1; for n in 1 2 3 4 5 6; do lc allowed-$n; o=$(keymaplint "$T/lc" "$MAP") || { ok=0; printf "%s\n" "allowed-$n: $o"; }; done
check "key map lint: each allowed form alone passes (HARNESS_HOME=, git -C log, readlink -f and cd && pwd as an alias, harness_config, == \"…\")" '(( ok ))'
lc escapes; o4=$(keymaplint "$T/lc" "$MAP"); c4=$?
check "key map lint: git -C show and grep, an alias of readlink -f, HH, a relative read up from tests/, an inline cd && pwd and a %/* root are hits; comments and sub-paths are not" \
  '(( c4 == 1 )) && [[ $(printf "%s\n" "$o4" | cut -d" " -f1 | paste -sd " ") == "escapes.sh:3 escapes.sh:4 escapes.sh:5 escapes.sh:6 escapes.sh:7 escapes.sh:8 escapes.sh:9" ]]'
lc escapes-2; o6=$(keymaplint "$T/lc" "$MAP"); c6=$?
check "key map lint: a root with a trailing /, . or .., a glob, a brace, a variable path, a defaulted HH and == outside [[ ]] are hits; a variable under a sub-path is not" \
  '(( c6 == 1 )) && [[ $(printf "%s\n" "$o6" | cut -d" " -f1 | paste -sd " ") == "escapes-2.sh:3 escapes-2.sh:4 escapes-2.sh:5 escapes-2.sh:6 escapes-2.sh:7 escapes-2.sh:8 escapes-2.sh:9 escapes-2.sh:10 escapes-2.sh:11" ]] || { printf "%s\n" "$o6"; false; }'
lc; o7=$(keymaplint "$T/lc" "$MAP:no-such-check"); c7=$?
check "key map lint: a map name no check file's name holds is named (tests/run.sh would be red on it every time), exit 1" \
  '(( c7 == 1 )) && [[ $o7 == "CLAUDE.md:no-such-check matches no check file" ]]'
o5=$(keymaplint "$HERE/checks" "$MAP"); c5=$?
check "key map lint: this repo's tests/checks/ passes with the map in .harness/config.sh (CLAUDE.md and its readers)" \
  '(( c5 == 0 )) && [[ -z $o5 && $MAP == "CLAUDE.md:39-memlint-m4:37-memory-prompts-m2:79-suite-length" ]] || { printf "%s\n" "$o5" | head -20; false; }'
suite_end
