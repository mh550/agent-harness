#!/usr/bin/env bash
# tier: fast
source "$(dirname "$0")/../lib.sh" && suite_setup
# ---- the resident helper: lib/helper.mjs and ask (H1-02, decisions/2026-11-03-resident-helper) ----
# A node shim first on PATH counts the starts (84-node-memo's) and execs the real node. Each scenario is a fresh bash
# under `timeout 60` that sources lib/record.sh, the way a driver or a lane does, so a hang fails its check instead of
# holding the file; the check shell's own node is the real one, the spawn every answer is compared with.
MD=$T/helper; mkdir -p "$MD/shim"
REAL_NODE=$(command -v node)
printf '#!/usr/bin/env bash\na=$*; echo "${a//[[:cntrl:]]/ }" >> "$NODE_COUNT"\nexec %q "$@"\n' "$REAL_NODE" > "$MD/shim/node"   # one line a start, an argument with newlines too
chmod +x "$MD/shim/node"
# sc <name> [<a temp HARNESS_HOME>] < its script: runs it; in it $D is its directory, c prints the starts so far, keep <name>
# stores it under $D/n-<name>. Left behind: $D/out, $D/err, $D/rc, $D/state/run.log
sc() { local d=$MD/$1 th=${2:-}; mkdir -p "$d/scratch" "$d/state"; cat > "$d/s.sh"; : > "$d/count"
  ( cd "$d" && export PATH=$MD/shim:$PATH NODE_COUNT=$d/count HARNESS_HOME=$HH HARNESS_SCRATCH=$d/scratch STATE=$d/state D=$d MD L
    [[ -n $th ]] && HARNESS_HOME=$th
    timeout -k 5 60 bash -c 'set -uo pipefail; source "$HARNESS_HOME/lib/record.sh"
      c() { wc -l < "$NODE_COUNT"; }; keep() { c > "$D/n-$1"; }; source "$D/s.sh"' > "$d/out" 2> "$d/err"; echo $? > "$d/rc" ); }
nof() { cat "$MD/$1/n-$2"; }   # <scenario> <name>
nd() { echo $(( $(nof "$1" "$3") - $(nof "$1" "$2") )); }   # <scenario> <from> <to>
slice() { awk -v a="$(nof "$1" "$2")" -v b="$(nof "$1" "$3")" 'NR > a && NR <= b' "$MD/$1/count"; }   # <scenario> <from> <to>: the starts between
lines() { grep -c -- "$2" "$MD/$1/state/run.log" 2> /dev/null; }   # <scenario> <text>: its run.log's lines holding it
L=$MD/l1.json; REALF=$HH/lib/features.mjs
# 20 lists with 20 different summaries: i of 20 features passing
for i in {1..20}; do
  jq -n --argjson i "$i" '{features: [range(20) | {id: "F\(.)", milestone: "M1", description: "d", steps: ["x"], passes: (. < $i)}]}' > "$MD/l$i.json"
done

# ---- 20 questions, one start ----
sc asks << 'EOF'
keep 0
for i in {1..20}; do ask features.mjs summary "$MD/l$i.json" > "$D/ans$i"; echo $? >> "$D/rcs"; done
keep 20
ask features.mjs passes "$MD/l1.json" F19; echo $? > "$D/rc-no"
ask features.mjs passes "$MD/l1.json" F0; echo $? > "$D/rc-yes"
keep passes
EOF
A=$MD/asks
check "ask: 20 summaries of 20 distinct lists start node once" '[[ $(nd asks 0 20) == 1 && $(cat "$A/rc") == 0 ]]'
same=1; for i in {1..20}; do cmp -s "$A/ans$i" <(node "$REALF" summary "$MD/l$i.json") || same=0; done
check "ask: each of the 20 answers is the spawn's bytes (cmp, the trailing newline included), and its exit code" \
  '[[ $same == 1 && $(sort -u "$A/rcs") == 0 && $(wc -l < "$A/rcs") == 20 ]]'
check "ask features.mjs passes: 1 for a feature not passing, 0 for a passing one, through the helper (no start)" \
  '[[ $(cat "$A/rc-no") == 1 && $(cat "$A/rc-yes") == 0 && $(nd asks 20 passes) == 0 ]]'
check "ask writes nothing to stderr when nothing is wrong" '[[ ! -s $A/err ]]'

# ---- a throw, the subshells, the lock, the off switch ----
sc throw << 'EOF'
echo '{' > "$D/bad.json"
ask features.mjs summary "$MD/l1.json" > /dev/null; p=$HELPER_PID; keep 0
ask features.mjs summary "$D/bad.json" > "$D/throw-out"; echo $? > "$D/throw-rc"; keep 1
ask features.mjs summary "$MD/l2.json" > "$D/after"; keep 2
[[ $HELPER_PID == "$p" ]] && echo same > "$D/same"
EOF
check "ask of a script that throws: 70, no stdout, the message on stderr" \
  '[[ $(cat "$MD/throw/throw-rc") == 70 && ! -s $MD/throw/throw-out ]] && grep -q "JSON" "$MD/throw/err"'
check "the call after a throw is answered by the same helper (no start, the same pid, no restart line)" \
  '[[ $(nd throw 0 2) == 0 && -f $MD/throw/same && ! -e $MD/throw/state/run.log ]] && cmp -s "$MD/throw/after" <(node "$REALF" summary "$MD/l2.json")'

sc subs << 'EOF'
x=$(ask features.mjs summary "$MD/l3.json"); printf '%s\n' "$x" > "$D/before-any"; keep first
ask features.mjs summary "$MD/l1.json" > /dev/null; keep started
x=$(ask features.mjs summary "$MD/l2.json"; echo "rc=$?"); printf '%s\n' "$x" > "$D/cmdsub"; keep cmdsub
while IFS= read -r l; do printf '%s\n' "$l"; done < <(ask features.mjs summary "$MD/l3.json") > "$D/procsub"; keep procsub
( ask features.mjs summary "$MD/l4.json" > "$D/bg" ) & wait $!; keep bg
ask features.mjs summary "$MD/l5.json" | cat > "$D/pipe"; keep pipe
exec 7> "$HARNESS_SCRATCH/helper-$$.lock"; flock -n 7 || echo "no lock" >&2
( ask features.mjs summary "$MD/l6.json" > "$D/bg-held" ) & wait $!; keep bg-held
x=$(ask features.mjs summary "$MD/l7.json"); printf '%s\n' "$x" > "$D/sub-held"; keep sub-held
ask features.mjs summary "$MD/l8.json" > "$D/held"; keep held
exec 7>&-
ask features.mjs summary "$MD/l9.json" > "$D/freed"; keep freed
while IFS= read -r l; do ask features.mjs summary "$MD/l10.json" > "$D/meet"; done < <(ask features.mjs summary "$MD/l11.json"; sleep 0.2)   # sleep-ok: the reader asks while the writer holds the pipe open
sum() { cmp -s "$D/$1" <(PATH=${PATH#*:} node "$HARNESS_HOME/lib/features.mjs" summary "$MD/l$2.json"); }
{ sum before-any 3 && sum procsub 3 && sum bg 4 && sum pipe 5 && sum bg-held 6 && sum sub-held 7 && sum held 8 && sum freed 9 && sum meet 10; } && touch "$D/all-same"
EOF
S=$MD/subs
check "a \$( ask ) before this shell has a helper spawns and starts none: a coproc started in a subshell would die with it" \
  '[[ $(nof subs first) == 1 && $(nd subs first started) == 1 ]]'
check "x=\$(ask …) answers through the parent's helper (no start), its exit code seen inside" \
  '[[ $(nd subs started cmdsub) == 0 && $(tail -1 "$S/cmdsub") == rc=0 ]]'
check "< <(ask …) answers through the parent's helper (no start)" '[[ $(nd subs cmdsub procsub) == 0 ]]'
check "( ask … ) & and ask … | cat spawn (bash closes the coproc's descriptors there: count +1 each)" '[[ $(nd subs procsub bg) == 1 && $(nd subs bg pipe) == 1 ]]'
check "with \$HARNESS_SCRATCH/helper-<pid>.lock held: ( ask ) &, \$( ask ) and the owner's own ask each spawn (+1 each), never wait" \
  '[[ $(nd subs pipe bg-held) == 1 && $(nd subs bg-held sub-held) == 1 && $(nd subs sub-held held) == 1 ]]'
check "the lock freed: the helper answers again (no start)" '[[ $(nd subs held freed) == 0 ]]'
check "every one of those answers is the spawn's bytes; a reader asking while < <(ask) runs still gets its own; nothing on stderr" \
  '[[ -f $S/all-same && ! -s $S/err && $(cat "$S/rc") == 0 ]]'

sc off << 'EOF'
export HARNESS_HELPER=0
for i in 1 2 3 4; do ask features.mjs summary "$MD/l$i.json" > "$D/a$i"; done; keep 4
x=$(ask features.mjs summary "$MD/l5.json"); keep 5
ask features.mjs passes "$L" F19; echo $? > "$D/rc-no"
[[ -z ${HELPER_PID:-} ]] && touch "$D/no-coproc"
EOF
check "HARNESS_HELPER=0: every call spawns (count = calls), no helper.mjs ever started, no coproc" \
  '[[ $(nof off 4) == 4 && $(nof off 5) == 5 && -f $MD/off/no-coproc ]] && ! grep -q helper.mjs "$MD/off/count" && cmp -s "$MD/off/a2" <(node "$REALF" summary "$MD/l2.json")'

# ---- framing: a copy of lib/ with memlint.mjs a fixture main, and a script the helper doesn't serve ----
TH=$MD/home; mkdir -p "$TH"; cp -r "$HH/lib" "$TH/lib"
cat > "$TH/lib/memlint.mjs" << 'EOF'
import { execFileSync } from "node:child_process";
import { isMain, runCli, readStdin } from "./cli.mjs";
const every = () => { let s = ""; for (let i = 1; i < 128; i++) s += String.fromCharCode(i); return `${s}é—😀Ā￿`; };
const answers = { nonl: () => "no newline", empty: () => "", newline: () => "\n", twonl: () => "a\n\n", utf8: () => "é—😀 ünï\n", big: () => `${"é".repeat(70000)}\nend`,
  nul: () => "a\0b\n", every };
export const main = async (argv, io) => {
  const m = argv[0];
  if (answers[m]) return { rc: 0, out: answers[m]() };
  if (m === "args") return { rc: 0, out: `${JSON.stringify(argv.slice(1))}\n` };
  if (m === "env") return { rc: 0, out: `${JSON.stringify(process.env[argv[1]] ?? null)} ${JSON.stringify(io.env?.[argv[1]] ?? null)}\n` };
  if (m === "cwd") return { rc: 0, out: `${process.cwd()} ${io.cwd}\n` };
  if (m === "rc") return { rc: Number(argv[1]), out: "x\n" };
  if (m === "tty") return { rc: 0, out: `${io.isTTY ? "tty" : "no tty"}\n` };
  if (m === "stdin") return { rc: 0, out: readStdin(io) };
  if (m === "err") { console.error("to-stderr"); return { rc: 0, out: "answer\n" }; }
  if (m === "childerr") { execFileSync("sh", ["-c", "echo from-child >&2"]); return { rc: 0, out: "answer\n" }; }
  if (m === "nulerr") { console.error("said-once"); return { rc: 0, out: "a\0b\n" }; }
  throw new Error(`no ${m}`);
};
if (isMain(import.meta.url)) runCli(main);
EOF
printf 'console.log("plain %%s", process.argv[2]);\n' > "$TH/lib/plain.mjs"
sc frame "$TH" << 'EOF'
ask memlint.mjs nonl > "$D/f-nonl"; keep start
for m in empty newline twonl utf8 big every; do ask memlint.mjs "$m" > "$D/f-$m"; echo "$m $?" >> "$D/rcs"; done; keep answered
ask memlint.mjs nul > "$D/f-nul"; echo $? > "$D/nul-rc"; keep nul
ask memlint.mjs rc 3 > "$D/f-rc3"; echo $? > "$D/rc3"; keep rc3
ask plain.mjs hello > "$D/f-plain"; keep plain
ask memlint.mjs nonl > "$D/f-again"; keep again
EOF
F=$MD/frame
fsame=1; for m in nonl empty newline twonl utf8 big every nul; do cmp -s "$F/f-$m" <(node "$TH/lib/memlint.mjs" "$m") || fsame=0; done
check "framing: no trailing newline, empty, lone newline, two newlines, UTF-8, every byte 1-127, 70000 two-byte chars: the spawn's bytes under cmp" \
  '[[ $fsame == 1 && $(wc -c < "$F/f-big") -gt 65536 ]]'
check "framing: those answers come from the helper (one start for all of them)" '[[ $(nof frame start) == 1 && $(nd frame start answered) == 0 ]]'
check "an answer holding a NUL: the spawn's bytes, by a spawn (count +1), the helper still up" \
  '[[ $(nd frame answered nul) == 1 && $(cat "$F/nul-rc") == 0 && $(wc -c < "$F/f-nul") == 4 && ! -e $F/state/run.log ]]'
check "a main's own exit code passes through (rc 3, its bytes, no start)" '[[ $(cat "$F/rc3") == 3 && $(cat "$F/f-rc3") == x && $(nd frame nul rc3) == 0 ]]'
check "ask of a script the helper does not serve: a spawn (count +1), the spawn's bytes, the helper still answers (no start)" \
  '[[ $(nd frame rc3 plain) == 1 && $(cat "$F/f-plain") == "plain hello" && $(nd frame plain again) == 0 ]]'

sc stdin << 'EOF'
ask features.mjs summary "$L" > /dev/null; keep 0
printf '# I\n\n## Answers\n' > "$D/piped.md"; cp "$D/piped.md" "$D/redir.md"; cp "$D/piped.md" "$D/empty.md"
printf q | ask inbox.mjs insert "$D/piped.md"; echo $? > "$D/rc-piped"; keep piped
printf q > "$D/q"; ask inbox.mjs insert "$D/redir.md" < "$D/q"; echo $? > "$D/rc-redir"; keep redir
ask inbox.mjs insert "$D/empty.md" < /dev/null; keep empty
ask features.mjs summary "$MD/l2.json" > "$D/next"; keep next
EOF
I=$MD/stdin; printf '# I\n\n## Answers\n' > "$MD/spawned.md"; printf q | node "$HH/lib/inbox.mjs" insert "$MD/spawned.md"
check "printf q | ask inbox.mjs insert <file>, and ask … < <file>: the file the spawn leaves, by a spawn (+1 each); its exit code" \
  'cmp -s "$I/piped.md" "$MD/spawned.md" && cmp -s "$I/redir.md" "$MD/spawned.md" && [[ $(nd stdin 0 piped) == 1 && $(nd stdin piped redir) == 1 && $(cat "$I/rc-piped") == 0 && $(cat "$I/rc-redir") == 0 ]]'
check "a stdin-fed call never lets main read the request pipe: the next ask is answered by the same helper; empty stdin leaves the file" \
  '[[ $(nd stdin empty next) == 0 && ! -e $I/state/run.log && ! -s $I/err && $(cat "$I/rc") == 0 ]] && cmp -s "$I/next" <(node "$REALF" summary "$MD/l2.json") && cmp -s "$I/empty.md" <(printf "# I\n\n## Answers\n")'

# ---- environment and cwd: the request carries both ----
R1=$MD/r1 R2=$MD/r2
for r in "$R1" "$R2"; do mkdir -p "$r/docs"; git -C "$r" init -q -b main; echo "$r" > "$r/a.txt"; echo d > "$r/docs/d.md"; git -C "$r" add -A; git -C "$r" -c user.name=t -c user.email=t@t commit -qm i; done
sc envcwd << 'EOF'
ask features.mjs summary "$L" > /dev/null; keep 0
cd "$MD/r1"
ask treekey.mjs --pathspec > "$D/ps"; HARNESS_CHECK_KEY_IGNORE=docs ask treekey.mjs --pathspec > "$D/ps-ign"; keep ps
HARNESS_HELPER=0 ask treekey.mjs --pathspec > "$D/ps0"; HARNESS_CHECK_KEY_IGNORE=docs HARNESS_HELPER=0 ask treekey.mjs --pathspec > "$D/ps-ign0"; keep ps0
ask treekey.mjs --pathspec > "$D/ps-after"; keep ps-after
ask treekey.mjs > "$D/k1"; cd "$MD/r2"; ask treekey.mjs > "$D/k2"; keep keys
cd "$MD"; ask features.mjs summary l2.json > "$D/rel"; cd "$D"; cp "$MD/l3.json" l2.json; ask features.mjs summary l2.json > "$D/rel2"; keep rel
EOF
E=$MD/envcwd
check "HARNESS_CHECK_KEY_IGNORE=docs ask treekey.mjs --pathspec: the bytes the same line gives with HARNESS_HELPER=0, and a different answer from the plain line's" \
  'cmp -s "$E/ps" "$E/ps0" && cmp -s "$E/ps-ign" "$E/ps-ign0" && ! cmp -s "$E/ps" "$E/ps-ign"'
check "the call's environment is the call's alone: the plain ask after it answers as before; none of them started node (the two HARNESS_HELPER=0 lines did)" \
  'cmp -s "$E/ps" "$E/ps-after" && [[ $(nd envcwd 0 ps) == 0 && $(nd envcwd ps ps0) == 2 && $(nd envcwd ps0 ps-after) == 0 ]]'
check "ask treekey.mjs after cd into two repos: each repo's own key (the cwd sent is \$PWD), through the one helper" \
  'cmp -s "$E/k1" <(cd "$R1" && node "$HH/lib/treekey.mjs") && cmp -s "$E/k2" <(cd "$R2" && node "$HH/lib/treekey.mjs") && ! cmp -s "$E/k1" "$E/k2" && [[ $(nd envcwd ps-after keys) == 0 ]]'
check "a relative path argument resolves against the asker's cwd, not the helper's" \
  'cmp -s "$E/rel" <(node "$REALF" summary "$MD/l2.json") && cmp -s "$E/rel2" <(node "$REALF" summary "$MD/l3.json") && [[ $(nd envcwd keys rel) == 0 ]]'

# every byte an argument or a value can hold, with the spawn as the judge
sc bytes "$TH" << 'EOF'
ask memlint.mjs nonl > /dev/null; keep 0
ctl=""; for i in {1..31}; do printf -v o '%03o' "$i"; printf -v ch "\\$o"; ctl+=$ch; done
args=('a"b\c' 'back\\slash\n' $'new\nline\ttab\r' "$ctl" $'\x7f' '&' 'a&b*?[x]' '' ' lead and trail ' 'é—😀' $'\xff\xc3' '{"id":1}' '$HOME' '%s')
ask memlint.mjs args "${args[@]}" > "$D/args"; HARNESS_HELPER=0 ask memlint.mjs args "${args[@]}" > "$D/args0"; keep args
{ export WEIRD=$ctl$'é\n"\\& x'; ask memlint.mjs env WEIRD > "$D/env"; HARNESS_HELPER=0 ask memlint.mjs env WEIRD > "$D/env0"; keep env; }
unset WEIRD; ask memlint.mjs env WEIRD > "$D/unset"; keep unset
ONE=1 ask memlint.mjs env ONE > "$D/tmp"; ask memlint.mjs env ONE > "$D/tmp-after"; keep tmp
ask memlint.mjs env HOME > "$D/home"; x=$(unset HOME; ask memlint.mjs env HOME); echo "$x" > "$D/home-gone"; keep home
long=$(printf 'x%.0s' {1..70000}); ask memlint.mjs args "$long" > "$D/long"; keep long
ask memlint.mjs nonl > /dev/null; keep after-long
mkdir "$D/gone"; cd "$D/gone"; rmdir "$D/gone"; ask memlint.mjs rc 5 > "$D/deleted"; echo $? > "$D/deleted-rc"; cd "$D"; keep deleted
EOF
B=$MD/bytes
check "arguments with every control byte, quotes, backslashes, &, an empty one, UTF-8 and invalid UTF-8 reach main as a spawn's do" \
  'cmp -s "$B/args" "$B/args0" && [[ -s $B/args0 && $(nd bytes 0 args) == 1 ]]'
check "an exported value with every control byte reaches process.env and io.env as a spawn's does, through the helper" \
  'cmp -s "$B/env" "$B/env0" && [[ -s $B/env0 && $(nd bytes args env) == 1 ]]'
check "a name exported and then unset is gone; X=1 ask … is that call's alone; an unset HOME in a \$( ) is that call's alone" \
  '[[ $(cat "$B/unset") == "null null" && $(cat "$B/tmp") == "\"1\" \"1\"" && $(cat "$B/tmp-after") == "null null" && $(cat "$B/home") != "null null" && $(cat "$B/home-gone") == "null null" && $(nd bytes env home) == 0 ]]'
check "a request over a pipe's buffer spawns (a wedged helper must never block the write), the spawn's bytes, the helper still up" \
  '[[ $(nd bytes home long) == 1 && $(nd bytes long after-long) == 0 && $(wc -c < "$B/long") -gt 70000 && ! -e $B/state/run.log ]]'
check "a cwd that is gone: declined and spawned (the spawn's exit code), not a restart, no line from the helper" '[[ $(cat "$B/deleted-rc") == 5 && $(cat "$B/deleted") == x && $(nd bytes after-long deleted) == 1 && ! -e $B/state/run.log ]] && ! grep -q "helper.mjs" "$B/err"'

# a request's stderr goes where that call sends its own, as a spawn's does: the helper's fd 2 is a file ask hands on
sc stderr "$TH" << 'EOF'
ask memlint.mjs nonl > /dev/null; keep 0
echo before > "$D/e-append"
ask memlint.mjs err > "$D/o-file" 2> "$D/e-file"
ask memlint.mjs err > "$D/o-null" 2> /dev/null
ask memlint.mjs err > "$D/o-append" 2>> "$D/e-append"
x=$(ask memlint.mjs err 2>&1); printf '%s\n' "$x" > "$D/o-both"
ask memlint.mjs childerr > "$D/o-child" 2> "$D/e-child"
ask memlint.mjs err > "$D/o-plain"
{ echo first >&2; ask memlint.mjs err > /dev/null; echo last >&2; } 2> "$D/e-seq"
keep served
x=$(HARNESS_HELPER=0 ask memlint.mjs err 2>&1); printf '%s\n' "$x" > "$D/o-both0"
ask memlint.mjs nulerr > "$D/o-nul" 2> "$D/e-nul"; keep nul
EOF
SE=$MD/stderr
check "a request's stderr: into the call's 2> file, nowhere under 2> /dev/null, onto the end under 2>>, in order with the shell's own writes; the answer on stdout each time, all through the helper" \
  '[[ $(cat "$SE/e-file") == to-stderr && $(cat "$SE/e-append") == before$'"'"'\n'"'"'to-stderr && $(cat "$SE/e-seq") == first$'"'"'\n'"'"'to-stderr$'"'"'\n'"'"'last && $(cat "$SE/o-file") == answer && $(cat "$SE/o-null") == answer && $(nd stderr 0 served) == 0 ]]'
check "2>&1 gives the spawn's bytes in the spawn's order (stderr, then the answer main returns)" 'cmp -s "$SE/o-both" "$SE/o-both0" && [[ $(cat "$SE/o-both") == to-stderr$'"'"'\n'"'"'answer ]]'
check "a git or other child a script runs: its stderr lands in the call's 2> file too" '[[ $(cat "$SE/e-child") == from-child && $(cat "$SE/o-child") == answer ]]'
check "with no redirect a request's stderr is this shell's, once: nothing left to go out with a later call" '[[ $(grep -c "^to-stderr$" "$SE/err") == 1 && $(cat "$SE/rc") == 0 && ! -s $(echo "$SE"/scratch/helper-*.err) ]]'
check "a declined request's stderr is dropped: the spawn says it, once" '[[ $(cat "$SE/e-nul") == said-once && $(wc -c < "$SE/o-nul") == 4 && $(nd stderr served nul) == 2 ]]'
sc throw2 << 'EOF'
echo '{' > "$D/bad.json"; ask features.mjs summary "$MD/l1.json" > /dev/null
ask features.mjs summary "$D/bad.json" > /dev/null 2> "$D/e1"; echo $? > "$D/rc1"
ask features.mjs summary "$D/bad.json" > /dev/null 2> /dev/null; echo $? > "$D/rc2"
EOF
check "a throw's message follows the call's redirect too (a file, /dev/null), rc 70, nothing on the shell's stderr" \
  'grep -q JSON "$MD/throw2/e1" && [[ $(cat "$MD/throw2/rc1") == 70 && $(cat "$MD/throw2/rc2") == 70 && ! -s $MD/throw2/err ]]'

# bytes, whatever the asker's locale: read -N and the request's length must not count characters
sc utf8 "$TH" << 'EOF'
export LC_ALL=C.UTF-8
ask memlint.mjs nonl > /dev/null; keep 0
for m in utf8 big every; do ask memlint.mjs "$m" > "$D/f-$m"; done; keep answers
args=('é—😀' $'\xff\xc3' $'a"\n\\'); ask memlint.mjs args "${args[@]}" > "$D/args"; HARNESS_HELPER=0 ask memlint.mjs args "${args[@]}" > "$D/args0"; keep args
wide=$(printf 'é%.0s' {1..31000}); ask memlint.mjs args "$wide" > "$D/wide"; keep wide
[[ $LC_ALL == C.UTF-8 && ${#wide} == 31000 ]] && touch "$D/locale-kept"
ask memlint.mjs env LC_ALL > "$D/lc"; keep lc
EOF
U=$MD/utf8; usame=1; for m in utf8 big every; do cmp -s "$U/f-$m" <(node "$TH/lib/memlint.mjs" "$m") || usame=0; done
check "under a UTF-8 locale: multi-byte answers and arguments come back as a spawn's, through the helper; the asker's locale is as it was" \
  '[[ $usame == 1 && $(nd utf8 0 answers) == 0 && $(nd utf8 answers args) == 1 && -f $U/locale-kept ]] && cmp -s "$U/args" "$U/args0"'
check "under a UTF-8 locale: a request's bound counts bytes (31000 two-byte characters, 62000 bytes: a spawn)" \
  '[[ $(nd utf8 args wide) == 1 && $(wc -c < "$U/wide") -gt 62000 && ! -e $U/state/run.log ]]'
check "under a UTF-8 locale: main sees the asker's LC_ALL, not the C that ask reads the reply under" '[[ $(cat "$U/lc") == "\"C.UTF-8\" \"C.UTF-8\"" && $(nd utf8 wide lc) == 0 ]]'

# a TTY on stdout is the view's question: main in the helper sees none, so ask spawns
( export PATH=$MD/shim:$PATH NODE_COUNT=$MD/tty-count HARNESS_HOME=$TH HARNESS_SCRATCH=$MD HO=$MD/tty-out; : > "$NODE_COUNT"
  timeout -k 5 60 script -qfc 'bash -c "source \"\$HARNESS_HOME/lib/record.sh\"; ask memlint.mjs nonl > /dev/null; ask memlint.mjs tty; ask memlint.mjs tty > \"\$HO\"; wc -l < \"\$NODE_COUNT\" > \"\$HO.n\""' "$MD/tty-log" > /dev/null 2>&1 < /dev/null )
check "ask with a TTY on stdout spawns (the view's colours are the spawn's); off a TTY the helper answers as a spawn does off one" \
  'grep -q "^tty" "$MD/tty-log" && [[ $(cat "$MD/tty-out") == "no tty" && $(cat "$MD/tty-out.n") == 2 ]]'

# ---- the failure branches: each ends in the spawn's bytes, never a hang ----
SUM2=$MD/sum2; node "$REALF" summary "$MD/l2.json" > "$SUM2"
sc killed << 'EOF'
ask features.mjs summary "$L" > /dev/null; keep 1; p=$HELPER_PID
kill "$HELPER_PID"; while kill -0 "$p" 2> /dev/null; do sleep 0.02; done   # sleep-ok: until it is gone
ask features.mjs summary "$MD/l2.json" > "$D/a1"; echo $? > "$D/rc1"; keep spawn; cp "$STATE/run.log" "$D/log1"
ask features.mjs summary "$MD/l2.json" > "$D/a2"; keep new; echo "${HELPER_PID:-}" > "$D/pid2"; echo "$p" > "$D/pid1"
ask features.mjs summary "$MD/l2.json" > "$D/a3"; keep served
EOF
K=$MD/killed
check "the helper killed between two calls: the next call is a spawn (+1), the spawn's bytes, one helper restarted: line" \
  '[[ $(nd killed 1 spawn) == 1 && $(cat "$K/rc1") == 0 && $(grep -c "helper restarted: " "$K/log1") == 1 ]] && cmp -s "$K/a1" "$SUM2" && grep -Eq "^[0-9-]+ [0-9:]+ helper restarted: " "$K/log1"'
check "the call after that starts a new helper (+1), and the one after is answered by it (no start); stderr empty; no second line" \
  '[[ $(nd killed spawn new) == 1 && $(nd killed new served) == 0 && $(cat "$K/pid1") != "$(cat "$K/pid2")" && -n $(cat "$K/pid2") && ! -s $K/err && $(lines killed "helper restarted: ") == 1 ]] && cmp -s "$K/a2" "$SUM2" && cmp -s "$K/a3" "$SUM2"'

# fake <name> <helper.mjs body>: a HARNESS_HOME whose helper misbehaves; each reads the request line as the real one does
fake() { local h=$MD/fake-$1; mkdir -p "$h"; cp -r "$HH/lib" "$h/lib"
  { printf '%s\n' 'let b = ""; process.stdin.on("data", d => { b += d; let i; while ((i = b.indexOf("\n")) >= 0) { const r = JSON.parse(b.slice(0, i)); b = b.slice(i + 1); on(r); } });'; printf '%s\n' "$2"; } > "$h/lib/helper.mjs"; }
fake silent 'const on = () => {};'
fake two 'const on = r => process.stdout.write(`${r.id} 0\n`);'
fake four 'const on = r => process.stdout.write(`${r.id} 0 0 0\n`);'
fake wrong 'const on = r => process.stdout.write(`${r.id + 1} 0 0\n`);'
fake words 'const on = r => process.stdout.write("not a header\n");'
fake dies 'const on = r => process.exit(3);'
fake cut 'const on = r => { process.stdout.write(`${r.id} 0 10\nabc`); setTimeout(() => process.exit(0), 50); };'
fake short 'const on = r => process.stdout.write(`${r.id} 0 10\nabc`);'
fake bigrc 'const on = r => process.stdout.write(`${r.id} 300 0\n`);'
fake words2 'const on = r => { console.error("last-words"); process.exit(3); };'
fbad=""
for k in silent two four wrong words dies cut short bigrc; do
  sc "f-$k" "$MD/fake-$k" << 'EOF'
export HARNESS_HELPER_TIMEOUT=1
ask features.mjs summary "$MD/l2.json" > "$D/a1"; echo $? > "$D/rc1"; keep 1
ask features.mjs summary "$MD/l2.json" > "$D/a2"; echo $? > "$D/rc2"
EOF
  d=$MD/f-$k
  { cmp -s "$d/a1" "$SUM2" && cmp -s "$d/a2" "$SUM2" && [[ $(cat "$d/rc") == 0 && $(cat "$d/rc1") == 0 && $(cat "$d/rc2") == 0 && $(nof "f-$k" 1) == 2 && $(lines "f-$k" "helper restarted: ") == 2 ]]; } || fbad+=" $k"
done
check "a helper that never replies, a two-field or four-field header, a wrong id, words, one that dies, one cut mid-answer, a short answer, an rc over 255: each call the spawn's bytes and rc, each a helper restarted: line" '[[ -z $fbad ]] || { echo "bad:$fbad" >&2; false; }'
check "the restart line says why: no reply in <n> s, a bad header, a wrong id, the helper gone" \
  'grep -q "helper restarted: no reply in 1 s" "$MD/f-silent/state/run.log" && grep -q "helper restarted: bad header" "$MD/f-two/state/run.log" && grep -q "helper restarted: wrong id" "$MD/f-wrong/state/run.log" && grep -q "helper restarted: " "$MD/f-dies/state/run.log"'

sc bound "$MD/fake-wrong" << 'EOF'
for i in {1..4}; do ask features.mjs summary "$MD/l2.json" > "$D/a$i"; [[ ${HARNESS_HELPER:-} == 0 ]] && echo "$i" >> "$D/off-at"; done; keep 4
for i in 5 6 7; do ask features.mjs summary "$MD/l2.json" > "$D/a$i"; done; x=$(ask features.mjs summary "$MD/l2.json"); keep 8
echo "${HELPER_PID:-none}" > "$D/left"
EOF
BO=$MD/bound
check "after three restarts in one process: one helper off: line, HARNESS_HELPER=0, every later call spawns and starts no helper" \
  '[[ $(lines bound "helper restarted: ") == 3 && $(lines bound "helper off: wrong id") == 1 && $(head -1 "$BO/off-at") == 4 && $(cat "$BO/left") == none ]] && [[ $(grep -c helper.mjs "$BO/count") == 4 && $(nd bound 4 8) == 4 ]] && [[ $(cat "$MD/bound/a7") == "$(cat "$SUM2")" ]]'

sc lastw "$MD/fake-words2" << 'EOF'
ask features.mjs summary "$MD/l2.json" > "$D/a1"; echo $? > "$D/rc1"; keep 1
EOF
check "a helper that dies: what it wrote to stderr reaches this shell's, its call the spawn's bytes" \
  'grep -q "^last-words$" "$MD/lastw/err" && cmp -s "$MD/lastw/a1" "$SUM2" && [[ $(cat "$MD/lastw/rc1") == 0 ]]'

# a failure met inside a $( ): the subshell logs and kills, the parent neither logs it again nor counts it twice
sc subfail "$MD/fake-silent" << 'EOF'
export HARNESS_HELPER_TIMEOUT=1
helper_start
x=$(ask features.mjs summary "$MD/l2.json"); echo "$x" > "$D/a1"; keep 1; cp "$STATE/run.log" "$D/log1"
ask features.mjs summary "$MD/l2.json" > "$D/a2"; keep 2; cp "$STATE/run.log" "$D/log2"
EOF
check "a failed read inside \$( ask ): the spawn's bytes, one line; the parent's next call finds the helper gone, logs nothing more, spawns" \
  '[[ $(grep -c "helper restarted: " "$MD/subfail/log1") == 1 && $(grep -c "helper restarted: " "$MD/subfail/log2") == 1 && $(nof subfail 2) == 3 ]] && cmp -s "$MD/subfail/a1" "$SUM2" && cmp -s "$MD/subfail/a2" "$SUM2"'
sc noscratch << 'EOF'
HARNESS_SCRATCH=$D/missing/dir
ask features.mjs summary "$L" > "$D/a1"; keep 1; ask features.mjs summary "$L" > "$D/a2"; keep 2
unset HARNESS_SCRATCH; ask features.mjs summary "$L" > "$D/a3"; keep 3
EOF
check "a scratch directory that is missing or unset: a spawn with the spawn's bytes, nothing on stderr, no restart line" \
  '[[ $(nd noscratch 1 2) -ge 1 && $(nd noscratch 2 3) == 1 && ! -s $MD/noscratch/err && ! -e $MD/noscratch/state/run.log ]] && cmp -s "$MD/noscratch/a2" <(node "$REALF" summary "$L") && cmp -s "$MD/noscratch/a3" <(node "$REALF" summary "$L")'

# the descriptors a helper could wrongly keep or lose
sc fds << 'EOF'
exec 9> "$D/record.lock"; flock 9
ask features.mjs summary "$L" > "$D/a1"; keep 1
exec 9>&-
if flock -n "$D/record.lock" true; then touch "$D/lock-free"; fi
EOF
check "a helper started while the shell holds the record lock (fd 9) keeps none of it: the lock is free when the shell lets go" '[[ -f $MD/fds/lock-free && $(cat "$MD/fds/rc") == 0 ]]'
# a refused asker's open truncates the lock file, so the holder reads nothing from it; the environment's values never reach the disk
sc files << 'EOF'
export HELPER_CHECK_VALUE=value-not-on-disk
ask features.mjs summary "$L" > /dev/null
EOF
check "the lock file stays empty (a refused asker's open truncates it); scratch holds the environment's names, never a value" \
  '[[ -f $(echo "$MD"/files/scratch/helper-*.lock) && ! -s $(echo "$MD"/files/scratch/helper-*.lock) ]] && grep -qx HELPER_CHECK_VALUE "$MD"/files/scratch/helper-*.names && ! grep -rq value-not-on-disk "$MD/files/scratch"'
sc nostate "$MD/fake-wrong" << 'EOF'
unset STATE
ask features.mjs summary "$MD/l2.json" > "$D/a1"; echo $? > "$D/rc1"
EOF
check "a failure with no STATE in this shell: the spawn's bytes, nothing fatal under set -u, nothing on stderr" \
  'cmp -s "$MD/nostate/a1" "$SUM2" && [[ $(cat "$MD/nostate/rc1") == 0 && $(cat "$MD/nostate/rc") == 0 && ! -s $MD/nostate/err ]]'

# ---- check.sh's key, from its parent's helper (check_run), and no node for an empty output's count ----
CK=$MD/ck; git init -q -b main "$CK"; echo a > "$CK/a"; mkdir "$CK/sub"; echo b > "$CK/sub/b"; git -C "$CK" add -A; git -C "$CK" -c user.name=t -c user.email=t@t commit -qm i
ckey=$(cd "$CK" && node "$HH/lib/treekey.mjs")
sc ckrun << 'EOF'
export HARNESS_CHECK_CACHE=$D/cache HARNESS_CHECK_CMD='echo "tk=${HARNESS_CHECK_TK-unset}" >> "$D/suite-saw"'
CHECK=$HARNESS_HOME/lib/check.sh; cd "$MD/ck"; ask features.mjs summary "$L" > /dev/null; keep 0
check_run > "$D/first"; echo $? > "$D/rc-first"; keep first
check_run > "$D/cached"; keep cached
( cd sub; check_run > "$D/sub" ); keep sub
"$CHECK" > "$D/direct"; keep direct
EOF
CR=$MD/ckrun
check "check_run: check.sh's key comes from the parent's helper (no treekey.mjs start), the same marker a spawn would write" \
  '[[ $(slice ckrun 0 cached | grep -c treekey) == 0 && -f $CR/cache/green-$ckey && $(cat "$CR/rc-first") == 0 ]] && grep -q "^check: green" "$CR/first" && grep -q "^check: green (cached" "$CR/cached"'
check "the suite never sees the handed key; a check.sh from a subdirectory or with no parent asks treekey.mjs itself (one start each), the same key" \
  '[[ $(sort -u "$CR/suite-saw") == tk=unset && $(slice ckrun cached sub | grep -c treekey) == 1 && $(slice ckrun sub direct | grep -c treekey) == 1 ]] && grep -q "^check: green (cached" "$CR/sub" && grep -q "^check: green (cached" "$CR/direct"'
sc ckcount << 'EOF'
CHECK=$HARNESS_HOME/lib/check.sh; cd "$MD/ck"; export HARNESS_CHECK_CACHE=$D/cache HARNESS_CHECK_CMD=true
ask features.mjs summary "$L" > /dev/null
check_run > "$D/empty"; keep empty
export HARNESS_CHECK_CACHE=$D/cache2 HARNESS_CHECK_CMD='echo "3/3 checks passed"'
check_run > "$D/counted"; keep counted
EOF
check "check.sh: an empty suite output starts no testcount.mjs, a suite that printed a count one, and says it" \
  '[[ $(grep -c testcount "$MD/ckcount/count") == 1 && $(slice ckcount empty counted | grep -c testcount) == 1 ]] && grep -q "3 tests" "$MD/ckcount/counted"'

# ---- lib/helper.mjs alone ----
HA=$MD/alone; mkdir -p "$HA"; SA=$(node "$REALF" summary "$L"); SB=$(node "$REALF" summary "$MD/l2.json")
{ printf '{"id":7,"script":"features.mjs","args":["summary","%s"],"cwd":"%s"}\n' "$L" "$HA"
  printf '{"id":8,"script":"features.mjs","args":["summary","%s"],"cwd":"%s"}\n' "$MD/l2.json" "$HA"; } | node "$HH/lib/helper.mjs" > "$HA/two" 2> "$HA/two.err"; hrc=$?
{ printf '7 0 %d\n%s\n8 0 %d\n%s\n' $(( ${#SA} + 1 )) "$SA" $(( ${#SB} + 1 )) "$SB"; } > "$HA/two.exp"
check "lib/helper.mjs: two request lines give two replies in order, each a header and exactly that many bytes; nothing else on stdout; exit 0 at EOF" \
  '[[ $hrc == 0 && ! -s $HA/two.err ]] && cmp -s "$HA/two" "$HA/two.exp"'
{ echo 'not json'; echo '{"id":3,"script":"nope.mjs","args":[],"cwd":"/"}'; echo '{"id":4,"script":"../x.mjs","args":[],"cwd":"/"}'; echo '{"id":5,"args":[]}'; } | node "$HH/lib/helper.mjs" > "$HA/bad" 2> "$HA/bad.err"; hbrc=$?
check "lib/helper.mjs: a malformed line and an unknown script each get rc 64 and no bytes, the reason on stderr; it goes on and exits 0" \
  '[[ $hbrc == 0 && $(sed -n 1p "$HA/bad") == "0 64 0" && $(sed -n 2p "$HA/bad") == "3 64 0" && $(sed -n 3p "$HA/bad") == "4 64 0" && $(sed -n 4p "$HA/bad") == "5 64 0" && $(wc -l < "$HA/bad") == 4 ]] && grep -q "nope.mjs" "$HA/bad.err" && grep -q "not json\|malformed" "$HA/bad.err"'
printf '{"id":9,"script":"features.mjs","args":["summary","%s"],"cwd":"/"}' "$L" | node "$HH/lib/helper.mjs" > "$HA/nonl"
check "lib/helper.mjs: a last line with no newline at EOF is still a request" 'cmp -s "$HA/nonl" <(printf "9 0 %d\n%s\n" $(( ${#SA} + 1 )) "$SA")'
mkfifo "$HA/in"; cp "$L" "$HA/l.json"; node "$HH/lib/helper.mjs" < "$HA/in" > "$HA/rep" 2> "$HA/rep.err" & hp=$!; exec 7> "$HA/in"
req='{"id":1,"script":"features.mjs","args":["summary","l.json"],"cwd":"'$HA'"}'
echo "$req" >&7; wait_for 30 test -s "$HA/rep"; cp "$MD/l2.json" "$HA/l.json"; echo "$req" >&7; wait_for 30 eval '(( $(wc -l < "$HA/rep") >= 4 ))'
check "lib/helper.mjs keeps nothing between requests: the same request after its file changed gives the new answer; no module-level let or var" \
  '[[ $(sed -n 2p "$HA/rep") == "$SA" && $(sed -n 4p "$HA/rep") == "$SB" ]] && ! grep -nE "^(let|var) " "$HH/lib/helper.mjs" > /dev/null'
kill "$hp"; wait "$hp"; hkrc=$?; exec 7>&-
check "lib/helper.mjs: SIGTERM ends it, a request or none pending" '[[ $hkrc == 143 ]]'
check "bash -n lib/record.sh; node --check lib/helper.mjs; helper.mjs has a one-line usage header" \
  'bash -n "$HH/lib/record.sh" && node --check "$HH/lib/helper.mjs" && head -1 "$HH/lib/helper.mjs" | grep -q "^// .*helper"'
suite_end
