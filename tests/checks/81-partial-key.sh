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
M0=CLAUDE.md:39-memlint-m4:37-memory-prompts-m2   # its own line: beside harness_config "<root>" it would be a hit of 82-key-map-lint
check "CHECK_KEY_MAP: harness default empty; this repo maps CLAUDE.md; the driver exports it; the template has it commented" \
  '( source "$HERE/../lib/config.sh" && HARNESS_CONFIG=/dev/null harness_config /nonexistent && [[ -z $CHECK_KEY_MAP ]] ) \
  && ( source "$HERE/../lib/config.sh" && HARNESS_CONFIG=/dev/null harness_config "$HERE/.." && [[ $CHECK_KEY_MAP == "$M0"* ]] ) \
  && [[ $(grep -c "HARNESS_CHECK_KEY_MAP=\$CHECK_KEY_MAP" "$HERE/../lib/prompt.sh") == 1 ]] && grep -q "^# CHECK_KEY_MAP=" "$HERE/../templates/project/config.sh"'

# ---- check.sh's partial path (S2-03): the part-<reduced> sidecar, a mapped-only diff runs just its checks ----
# The repo gets the map in its own .harness/config.sh (row 4a: only the tree's map may choose a subset). One stub suite
# prints what tests/run.sh prints; each case $T/pk-<case> has its counter n, every call's arguments (args), each output
# (out<n>), and a copy of the base case's cache and scratch (the green full run of the committed tree). PK_RED=<name>:
# a call naming it (or the bare call) is red with HARNESS_FAILED=<name> (PK_NOLINE=1: without), PK_RED_ONCE=1 only the
# first; PK_HANG=<name> hangs. The base marker's wall is set to 777 after its run, so an inherited marker is told from a new one.
( cd "$T/pk" && git checkout -q -- . && mkdir -p .harness && echo "CHECK_KEY_MAP=\"$M\"" > .harness/config.sh \
  && git add -A && git -c user.name=t -c user.email=t@t commit -qm map )
cat > "$T/pk-suite.sh" <<'EOF'
n=$(( $(cat "$PK/n" 2> /dev/null || echo 0) + 1 )); echo "$n" > "$PK/n"; echo "$*" >> "$PK/args"; o=$PK/out$n
[[ -n ${PK_HANG:-} && " $* " == *" $PK_HANG "* ]] && sleep 10   # sleep-ok: a check that outlives its timeout
if [[ -n ${PK_RED:-} && ! -e $PK/red-once ]] && { (( ! $# )) || [[ " $* " == *" $PK_RED "* ]]; }; then
  [[ -n ${PK_RED_ONCE:-} ]] && touch "$PK/red-once"
  printf '%s\n' "FAIL $PK_RED" ${PK_NOLINE:-"HARNESS_FAILED=$PK_RED"} "0/1 checks passed" > "$o"; cat "$o"; exit 1
fi
if (( $# )); then for a; do echo "PASS $a"; done; echo "$#/$# checks passed"; else printf '%s\n' "PASS t1" "PASS t2" "2/2 checks passed"; fi > "$o"
cat "$o"
EOF
pc() { local c=$1; shift; mkdir -p "$T/pk-$c"
  ( cd "$T/pk" && PK=$T/pk-$c HARNESS_SCRATCH=$T/pk-$c/s HARNESS_CHECK_CACHE=$T/pk-$c/c HARNESS_CHECK_KEY_IGNORE=${PKIGN-".harness/runs docs/plans"} \
    HARNESS_CHECK_KEY_MAP=${PKMAP-$M} HARNESS_CHECK_CMD="bash $T/pk-suite.sh" "$HERE/../lib/check.sh" "$@" ); }
pkcase() { ( cd "$T/pk" && git checkout -q -- . && git clean -fdq ) && mkdir -p "$T/pk-$1" && cp -r "$T/pk-base/c" "$T/pk-base/s" "$T/pk-$1/"; }
pargs() { sed -n "$2p" "$T/pk-$1/args"; }
pkeys() { mapfile -t "$1" < <(pk "$M" --partial); }
o_pb=$(pc base; echo "rc=$?"); pkeys k0
check "check partial: a green full run writes green-<full> (count, wall) and part-<reduced>: the full key, then the blob lines" \
  '[[ $o_pb =~ ^check:\ green\ in\ [0-9]+\ s,\ 2\ tests$'"'"'\n'"'"'rc=0$ ]] && [[ $(sed -n 1p "$T/pk-base/c/green-${k0[0]}") == "2 tests" ]] \
  && [[ $(sed -n 2p "$T/pk-base/c/green-${k0[0]}") =~ ^wall\ [0-9]+$ && $(ls "$T/pk-base/c" | grep -c "^part-") == 1 ]] \
  && diff <(printf "%s\n" "${k0[0]}" "${k0[@]:2}") "$T/pk-base/c/part-${k0[1]}" > /dev/null'
printf '%s\n' "2 tests" "wall 777" > "$T/pk-base/c/green-${k0[0]}"

pkcase cl; echo x >> "$T/pk/CLAUDE.md"; pkeys k1; o_cl=$(pc cl; echo "rc=$?"); o_cl2=$(pc cl)
check "check partial: a CLAUDE.md-only diff runs exactly memlint: the partial line, exit 0, check-partial.out, check.out untouched" \
  '[[ $(pargs cl 1) == memlint && $(cat "$T/pk-cl/n") == 1 ]] && [[ $(head -1 <<< "$o_cl") =~ ^check:\ green\ \(partial:\ memlint,\ [0-9]+\ s\;\ cached\ for\ the\ rest\)$ && $(tail -n +2 <<< "$o_cl") == rc=0 ]] \
  && grep -qx "PASS memlint" "$T/pk-cl/s/check-partial.out" && cmp -s "$T/pk-cl/s/check.out" "$T/pk-base/s/check.out"'
check "check partial: a partial green inherits the reference marker (count and wall) byte for byte, writes no part-, and the next call is cached" \
  '[[ ${k1[0]} != "${k0[0]}" && ${k1[1]} == "${k0[1]}" && $(sed -n 2p "$T/pk-cl/c/green-${k1[0]}") == "wall 777" ]] && cmp -s "$T/pk-cl/c/green-${k1[0]}" "$T/pk-base/c/green-${k0[0]}" \
  && [[ ! -e $T/pk-cl/c/red-${k1[0]} ]] && [[ $(ls "$T/pk-cl/c" | grep -c "^part-") == 1 ]] && cmp -s "$T/pk-cl/c/part-${k0[1]}" "$T/pk-base/c/part-${k0[1]}" \
  && [[ $o_cl2 == "check: green (cached for this code tree, 2 tests)" && $(cat "$T/pk-cl/n") == 1 ]]'
check "check partial: check-runs.log gets a partial row for the partial run" \
  '[[ $(awk -F"\t" "\$2 == \"partial\"" "$T/pk-cl/s/check-runs.log" | wc -l) == 1 ]]'

pkcase lib; echo b >> "$T/pk/lib/a.sh"; pc lib > /dev/null
pkcase two; echo x >> "$T/pk/CLAUDE.md"; echo y >> "$T/pk/README.md"; o_two=$(pc two)
check "check partial: a lib/ diff runs the full suite (no arguments); a diff of both mapped paths runs memlint readme, map order" \
  '[[ $(cat "$T/pk-lib/n") == 1 && -z $(pargs lib 1) && $(pargs two 1) == "memlint readme" ]] \
  && [[ $o_two =~ ^check:\ green\ \(partial:\ memlint\ readme,\ [0-9]+\ s\;\ cached\ for\ the\ rest\)$ ]]'

pkcase red; echo x >> "$T/pk/CLAUDE.md"; o_red=$(PK_RED=memlint pc red; echo "rc=$?")
check "check partial: red twice is rerun once on memlint, says so, exits 1 and leaves no marker of either kind" \
  '[[ $(cat "$T/pk-red/n") == 2 && $(pargs red 1) == memlint && $(pargs red 2) == memlint && $(tail -1 <<< "$o_red") == rc=1 ]] \
  && grep -qx "check: RED (partial: memlint; exit 1 after [0-9]* s; red again on a rerun of memlint) — last lines of $T/pk-red/s/check-partial-rerun.out:" <<< "$o_red" \
  && [[ ! -e $T/pk-red/c/green-${k1[0]} && ! -e $T/pk-red/c/red-${k1[0]} && ! -e $T/pk-red/c/flakes.jsonl ]]'
pkcase flk; echo x >> "$T/pk/CLAUDE.md"; o_flk=$(PK_RED=memlint PK_RED_ONCE=1 pc flk; echo "rc=$?")
check "check partial: red once then green is a flake: one flakes.jsonl row with partial, the green-after-a-rerun line, the reference marker" \
  '[[ $o_flk == $'"'"'check: green after a rerun (partial: memlint; flaky: memlint), 2 tests\nrc=0'"'"' ]] \
  && [[ $(grep -c "" "$T/pk-flk/c/flakes.jsonl") == 1 ]] && cmp -s "$T/pk-flk/c/green-${k1[0]}" "$T/pk-base/c/green-${k0[0]}" \
  && jq -e '"'"'.partial == ["memlint"] and .names == ["memlint"] and .rerun == "failed" and (.first | startswith("exit 1 after"))'"'"' "$T/pk-flk/c/flakes.jsonl" > /dev/null'

pkcase nol; echo x >> "$T/pk/CLAUDE.md"; o_nol=$(PK_RED=memlint PK_RED_ONCE=1 PK_NOLINE=1 pc nol; echo "rc=$?")
pkcase del; rm "$T/pk/CLAUDE.md"; o_del=$(pc del)
check "check partial: a red with no HARNESS_FAILED line reruns the partial's names (a flake row naming them); a deleted mapped file is a partial" \
  '[[ $o_nol == $'"'"'check: green after a rerun (partial: memlint; flaky: memlint), 2 tests\nrc=0'"'"' && $(pargs nol 2) == memlint ]] \
  && jq -e '"'"'.partial == ["memlint"] and .names == ["memlint"] and .rerun == "partial"'"'"' "$T/pk-nol/c/flakes.jsonl" > /dev/null \
  && [[ $(pargs del 1) == memlint && $o_del == "check: green (partial: memlint, "* ]]'
pkcase ign; PKIGN=".harness" pc ign > /dev/null; echo x >> "$T/pk/CLAUDE.md"; PKIGN=".harness" pc ign > /dev/null
check "check partial: with .harness/config.sh outside the key (its map could change under an equal reduced key) a CLAUDE.md diff runs in full" \
  '[[ $(cat "$T/pk-ign/n") == 2 && -z $(pargs ign 1) && -z $(pargs ign 2) && $(ls "$T/pk-ign/c" | grep -c "^part-") == 2 ]]'
pkcase noref; rm "$T/pk-noref/c/green-${k0[0]}"; echo x >> "$T/pk/CLAUDE.md"; pc noref > /dev/null
pkcase stale; echo x >> "$T/pk/CLAUDE.md"; PKMAP="CLAUDE.md:memlint:other README.md:readme" pc stale > /dev/null
check "check partial: the reference green-<ref> gone, or an exported map other than the tree's .harness/config.sh one, runs in full" \
  '[[ $(cat "$T/pk-noref/n") == 1 && -z $(pargs noref 1) && $(cat "$T/pk-stale/n") == 1 && -z $(pargs stale 1) ]]'
# the map grew: the tree's config names SPEC.md too while the exported map is still the old one (a full run, row 4a,
# writes this tree's part- with the old path set); once the driver exports the grown map, a CLAUDE.md diff runs in full
# and its green rewrites that part- with the grown path set (same reduced key: CLAUDE.md is mapped)
pkcase grow; echo "CHECK_KEY_MAP=\"$M SPEC.md:spec\"" > "$T/pk/.harness/config.sh"; pc grow > /dev/null
echo x >> "$T/pk/CLAUDE.md"; PKMAP="$M SPEC.md:spec" pc grow > /dev/null
check "check partial: a part- whose path set is not the map's (the map grew an entry) runs in full" \
  '[[ $(cat "$T/pk-grow/n") == 2 && -z $(pargs grow 1) && -z $(pargs grow 2) ]] \
  && [[ $(ls "$T/pk-grow/c" | grep -c "^part-") == 2 && $(cat "$T/pk-grow/c"/part-* | grep -c " SPEC.md$") == 1 ]]'

pkcase sub; echo x >> "$T/pk/CLAUDE.md"; ls "$T/pk-sub/c" > "$T/pk-sub.before"; o_sub=$(pc sub memlint)
check "check partial: the subset form on the diffed tree runs its subset and reads no map, sidecar or marker" \
  '[[ $o_sub == $'"'"'PASS memlint\n1/1 checks passed'"'"' && $(pargs sub 1) == memlint ]] && diff "$T/pk-sub.before" <(ls "$T/pk-sub/c") > /dev/null'
pkcase hang; echo x >> "$T/pk/CLAUDE.md"; o_hang=$(HARNESS_CHECK_TIMEOUT=2s PK_HANG=memlint pc hang; echo "rc=$?")
check "check partial: a timeout in a partial run is said as such, no rerun, no marker" \
  'grep -qx "check: RED (partial: memlint; timed out after 2s, exit 124 after [0-9]* s) — last lines of $T/pk-hang/s/check-partial.out:" <<< "$o_hang" \
  && [[ $(tail -1 <<< "$o_hang") == rc=124 && $(cat "$T/pk-hang/n") == 1 && ! -e $T/pk-hang/c/green-${k1[0]} && ! -e $T/pk-hang/c/red-${k1[0]} ]]'
( cd "$T/pk" && git checkout -q -- . && git clean -fdq )
suite_end
