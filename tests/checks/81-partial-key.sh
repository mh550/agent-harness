#!/usr/bin/env bash
source "$(dirname "$0")/../lib.sh" && suite_setup
# ---- the declared partial map (suite-time S2): treekey --partial, its exported functions, CHECK_KEY_MAP's default ----
git init -q "$T/pk" && ( cd "$T/pk" && mkdir -p lib docs/plans && echo c > CLAUDE.md && echo r > README.md && echo a > lib/a.sh \
  && echo p > docs/plans/p.md && git add -A && git -c user.name=t -c user.email=t@t commit -qm a )
pk() { ( cd "$T/pk" && HARNESS_CHECK_KEY_IGNORE=".harness/runs docs/plans" HARNESS_CHECK_KEY_MAP=$1 node "$HERE/../lib/treekey.mjs" "${@:2}" ); }
M="CLAUDE.md:memlint README.md:readme"
mapfile -t pa < <(pk "$M" --partial); echo x >> "$T/pk/CLAUDE.md"; mapfile -t pb < <(pk "$M" --partial)
check "treekey --partial: a CLAUDE.md-only change moves the full key (16 hex), keeps the reduced key, and differs in CLAUDE.md's blob line only" \
  '[[ ${#pa[@]} == 4 && ${#pb[@]} == 4 && ${pa[0]} =~ ^[0-9a-f]{16}$ && ${pb[0]} =~ ^[0-9a-f]{16}$ && ${pa[0]} != "${pb[0]}" ]] \
  && [[ ${pa[1]} =~ ^[0-9a-f]{16}$ && ${pa[1]} == "${pb[1]}" && ${pa[1]} != "${pa[0]}" ]] \
  && [[ ${pa[2]} =~ ^[0-9a-f]{40}\ CLAUDE\.md$ && ${pb[2]} =~ ^[0-9a-f]{40}\ CLAUDE\.md$ && ${pa[2]} != "${pb[2]}" ]] \
  && [[ ${pa[3]} =~ ^[0-9a-f]{40}\ README\.md$ && ${pa[3]} == "${pb[3]}" ]]'
mapfile -t pg < <(pk "CLAUDE.md:memlint gone.md:g" --partial)
check "treekey --partial: a mapped path absent from the tree is a \`- <path>\` line, in map order" \
  '[[ ${#pg[@]} == 4 && ${pg[2]} == "${pb[2]}" && ${pg[3]} == "- gone.md" ]]'
mapfile -t pn < <(pk "" --partial); pbare=$(pk "$M"); pbare0=$(pk "")
check "treekey: without a map --partial prints two equal keys and no blob line; the bare call is one line, --partial's line 1, map or not" \
  '[[ ${#pn[@]} == 2 && ${pn[0]} == "${pn[1]}" && ${pn[0]} == "${pb[0]}" && $pbare == "${pb[0]}" && $pbare0 == "${pb[0]}" ]]'
pk "$M lib:x lib/:x README.md: CLAUDE.md /etc/x:y docs/plans/p.md:x ../up.md:u" --partial > "$T/pk-drop.out" 2> "$T/pk-drop.err"
pk "$M" --partial > "$T/pk-m.out" 2> "$T/pk-m.err"
check "treekey --partial: a dropped entry (directory, no name, outside the tree, under an ignored prefix) is one stderr line each; the output is the map's without it" \
  'cmp -s "$T/pk-drop.out" "$T/pk-m.out" && [[ ! -s $T/pk-m.err && $(wc -l < "$T/pk-drop.err") == 7 ]] \
  && [[ $(grep -c "^treekey: CHECK_KEY_MAP entry lib/\?:x dropped: a directory$" "$T/pk-drop.err") == 2 ]] \
  && grep -qx "treekey: CHECK_KEY_MAP entry README.md: dropped: no check name" "$T/pk-drop.err" \
  && grep -qx "treekey: CHECK_KEY_MAP entry CLAUDE.md dropped: no check name" "$T/pk-drop.err" \
  && grep -qx "treekey: CHECK_KEY_MAP entry /etc/x:y dropped: not a path in the tree" "$T/pk-drop.err" \
  && grep -qx "treekey: CHECK_KEY_MAP entry ../up.md:u dropped: not a path in the tree" "$T/pk-drop.err" \
  && grep -qx "treekey: CHECK_KEY_MAP entry docs/plans/p.md:x dropped: under the ignored prefix docs/plans" "$T/pk-drop.err"'
pd=$(pk "lib:x README.md:" --partial 2> /dev/null | wc -l); pbare_bad=$(pk "lib:x" 2>&1)
check "treekey: a map whose every entry is dropped is as no map (two lines); the bare call never parses the map (no stderr)" \
  '[[ $pd == 2 && $pbare_bad == "${pb[0]}" ]]'
pn1=$(pk "CLAUDE.md:a ./CLAUDE.md:b:a README.md:readme" --names CLAUDE.md); pn2=$(pk "$M" --names README.md CLAUDE.md)
pk "$M" --names x.md > "$T/pk-nx.out" 2> /dev/null; pnx=$?
check "treekey --names: the entries' names in map order (a duplicate path merged into the first), exit 1 and no line for a path no entry has" \
  '[[ $pn1 == "a b" && $pn2 == "memlint readme" && $pnx == 1 && ! -s $T/pk-nx.out ]]'
# the pure functions, imported without running the CLI (no git)
pure=$(cd "$T" && node --input-type=module -e '
import { ignoreList, parseMap, treeKey, partialKeys, mapNames } from "'"$HERE"'/../lib/treekey.mjs";
const f = ["a", "b", "c"], b = ["1".repeat(40), "2".repeat(40), "3".repeat(40)];
const out = [];
const k0 = partialKeys(f, b, []); out.push(k0.full === treeKey(f, b) && k0.full === k0.reduced && k0.lines.length === 0);
const kb = partialKeys(f, b, [{ path: "b", names: ["x"] }]);
out.push(kb.full === k0.full && kb.reduced === treeKey(["a", "c"], [b[0], b[2]]) && kb.lines.join("|") === `${b[1]} b`);
out.push(partialKeys(f, b, [{ path: "z", names: ["x"] }]).lines.join("|") === "- z");
const ig = ignoreList({ HARNESS_CHECK_KEY_IGNORE: "./docs/plans/ /abs" });
out.push(ig.join(" ") === ".harness/runs docs/plans");
const pm = parseMap("CLAUDE.md:a::b d:x docs/plans/q.md:y R.md R.md:c ./CLAUDE.md:e:a", ig, p => p === "d");
out.push(pm.dropped.length === 3 && pm.entries.map(e => `${e.path}=${e.names.join(",")}`).join(" ") === "CLAUDE.md=a,b,e R.md=c");
out.push(mapNames(pm.entries, ["R.md", "CLAUDE.md"]).join(" ") === "a b e c" && mapNames(pm.entries, ["nope"]) === null);
console.log(out.join(" "));' 2>&1)
check "treekey.mjs exports ignoreList, parseMap, treeKey, partialKeys and mapNames, pure on a fixed file list and blobs" \
  '[[ $pure == "true true true true true true" ]]'
check "CHECK_KEY_MAP: harness default empty; this repo maps CLAUDE.md; the driver exports it; the template has it commented" \
  '( source "$HERE/../lib/config.sh" && HARNESS_CONFIG=/dev/null harness_config /nonexistent && [[ -z $CHECK_KEY_MAP ]] ) \
  && ( source "$HERE/../lib/config.sh" && HARNESS_CONFIG=/dev/null harness_config "$HERE/.." && [[ $CHECK_KEY_MAP == CLAUDE.md:39-memlint-m4:37-memory-prompts-m2* ]] ) \
  && [[ $(grep -c "HARNESS_CHECK_KEY_MAP=\$CHECK_KEY_MAP" "$HERE/../lib/prompt.sh") == 1 ]] && grep -q "^# CHECK_KEY_MAP=" "$HERE/../templates/project/config.sh"'
suite_end
