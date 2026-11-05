#!/usr/bin/env bash
# tier: fast
source "$(dirname "$0")/../lib.sh" && suite_setup
# ---- fewer node starts: F's memo (C1-02, decisions/2026-10-31-fewer-node-starts) ----
# lib/record.sh's F answers a pure subcommand from a per-process memo keyed on the subcommand, the content hash of the
# files it reads and its other arguments. A node shim first on PATH counts the starts (one line each: whether
# HARNESS_LANE is set, then the arguments) and execs the real node, as tests/stub-claude.sh stands in for claude.
MD=$T/memo; mkdir -p "$MD/shim" "$MD/rec"
REAL_NODE=$(command -v node)
printf '#!/usr/bin/env bash\necho "lane=${HARNESS_LANE:+1} $*" >> "$NODE_COUNT"\nexec %q "$@"\n' "$REAL_NODE" > "$MD/shim/node"
chmod +x "$MD/shim/node"
L=$MD/list.json P=$MD/parked.json A=$MD/att.json
cat > "$L" << 'EOF'
{ "features": [
  { "id": "A", "milestone": "M1", "description": "a", "steps": ["x"], "passes": false },
  { "id": "B", "milestone": "M1", "description": "b", "steps": ["y"], "passes": true } ] }
EOF
cp "$L" "$MD/list.orig"; echo '{}' > "$A"; echo '{"A":{"answers":"old","why":"w","at":"t"}}' > "$MD/parked.orig"
printf '# INBOX\n\n## Answers\n\nyes\n' > "$MD/rec/INBOX.md"
# n: the node starts so far (to <file>); every step below runs in one shell, the way the driver and a lane do
(
  export PATH=$MD/shim:$PATH NODE_COUNT=$MD/count HARNESS_HOME=$HH HARNESS_HELPER=0; : > "$NODE_COUNT"
  source "$HH/lib/record.sh"
  n() { wc -l < "$NODE_COUNT" > "$MD/n-$1"; }
  touch "$MD/marker"; n 0; F model opus > "$MD/model1"; F model opus > "$MD/model2"; n model
  F model sonnet > "$MD/sonnet"; F model claude-x-1 > "$MD/claude"; n aliases
  F model bogus > "$MD/bogus1"; F model bogus > "$MD/bogus2"; n bogus
  F summary "$L" > "$MD/s1"; F summary "$L" > "$MD/s2"; n summary
  jq '.features[0].passes = true' "$MD/list.orig" > "$L"; F summary "$L" > "$MD/s3"; n flipped
  cp "$MD/list.orig" "$L"; touch -d '2001-01-01' "$L"; F summary "$L" > "$MD/s4"; n restored
  F passes "$L" A; echo $? > "$MD/p1"; F passes "$L" A; echo $? > "$MD/p2"; n passes
  Fv ids ids "$L" M1; printf '%s' "$ids" > "$MD/ids1"; ( F ids "$L" M1 > "$MD/ids2" ); n ids
  Fv pv passes "$L" A; echo "$?:$pv" > "$MD/fv-rc"; n fv-rc
  F next "$L" "$A" 2 "$P" M1 > "$MD/next1"; F next "$L" "$A" 2 "$P" M1 > /dev/null; n next
  echo '{"A":1}' > "$A"; F next "$L" "$A" 2 "$P" M1 > "$MD/next2"; n next-att
  F next "$L" "$A" 1 "$P" M1 > "$MD/next3"; n next-max
  echo '{"A":{"answers":"x","why":"w","at":"t"}}' > "$P"; F next "$L" "$A" 2 "$P" M1 > "$MD/next4"; n next-parked
  rm -f "$P"
  F unpark "$P" new > "$MD/u0"; F unpark "$P" new > /dev/null; n unpark-empty
  cp "$MD/parked.orig" "$P"; F unpark "$P" new > "$MD/u1"; cp "$MD/parked.orig" "$P"; F unpark "$P" new > "$MD/u2"; n unpark-printed
  echo '{"A":1}' > "$A"; F bump "$A" A; F bump "$A" A; n bump
  REC=$MD/rec; answers_hash > "$MD/h1"; answers_hash > "$MD/h2"; n answers
  printf '# INBOX\n\n## Answers\n\nno\n' > "$MD/rec/INBOX.md"; answers_hash > "$MD/h3"; n answers-new
  for i in 1 2; do F snapshot "$L" > "$MD/snap$i"; F lint "$L" > "$MD/lint$i"; echo $? >> "$MD/lint-rc"; done
  n pre-bad; echo '{' > "$MD/bad.json"; F summary "$MD/bad.json" > /dev/null 2>&1; echo $? > "$MD/bad1"; F summary "$MD/bad.json" > /dev/null 2>&1; echo $? > "$MD/bad2"; n bad
  ( F milestones "$L" > /dev/null; ( F milestones "$L" > /dev/null ) ); F milestones "$L" > /dev/null; n sub
  printf '{"features":[]}' > "$MD/empty.json"; F milestones "$MD/empty.json" > "$MD/ms1"; F milestones "$MD/empty.json" > "$MD/ms2"
) 2> "$MD/err"
d() { echo $(( $(cat "$MD/n-$2") - $(cat "$MD/n-$1") )); }
check "F model twice: one node start, the same model id" \
  '[[ $(d 0 model) == 1 && $(cat "$MD/model1") == claude-opus-5-5 && $(cat "$MD/model2") == claude-opus-5-5 ]]'
check "F model: that one start answers every alias; a claude-… id is answered without node" \
  '[[ $(d model aliases) == 0 && $(cat "$MD/sonnet") == claude-sonnet-5-5 && $(cat "$MD/claude") == claude-x-1 ]]'
check "F model of an unknown alias: node once (its fallback), then the memo" \
  '[[ $(d aliases bogus) == 1 && $(cat "$MD/bogus1") == claude-opus-5-5 && $(cat "$MD/bogus2") == claude-opus-5-5 ]]'
check "F summary twice on one list: one node start, the same line" \
  '[[ $(d bogus summary) == 1 && $(cat "$MD/s1") == "1/2 passing" && $(cat "$MD/s2") == "1/2 passing" ]]'
check "F summary after a passes flip: node again, the new count" '[[ $(d summary flipped) == 1 && $(cat "$MD/s3") == "2/2 passing" ]]'
check "F summary on the list restored to its first content (a new mtime): the memo answers, no start (content, not mtime)" \
  '[[ $(d flipped restored) == 0 && $(cat "$MD/s4") == "1/2 passing" ]]'
check "F passes twice: one start, the exit code kept (1 both times)" '[[ $(d restored passes) == 1 && $(cat "$MD/p1") == 1 && $(cat "$MD/p2") == 1 ]]'
check "Fv stores in the current shell: a \$(F …) subshell after it hits, the same lines; Fv cuts trailing newlines" \
  '[[ $(d passes ids) == 1 ]] && cmp -s "$MD/ids1" <(printf "A\nB") && cmp -s "$MD/ids2" <(printf "A\nB\n")'
check "Fv returns the answer's exit code (passes A: 1, empty) from the memo" '[[ $(d ids fv-rc) == 0 && $(cat "$MD/fv-rc") == "1:" ]]'
check "F next: keyed on attempts.json, max and parked.json (one start twice, a new start and answer after each changes)" \
  '[[ $(d fv-rc next) == 1 && $(d next next-att) == 1 && $(d next-att next-max) == 1 && $(d next-max next-parked) == 1 ]] \
   && [[ $(cut -f1 "$MD/next1") == A && $(cut -f1 "$MD/next2") == A && ! -s $MD/next3 && ! -s $MD/next4 ]]'
check "a throw in features.mjs exits 70 and is never kept (node each time)" '[[ $(d pre-bad bad) == 2 && $(cat "$MD/bad1") == 70 && $(cat "$MD/bad2") == 70 ]]'
check "a miss in a subshell is not kept (a nested subshell starts node again); the parent's own call then stores it" \
  '[[ $(d bad sub) == 3 ]]'
check "F unpark that printed nothing: memoized; one that unparked: node every time, even on the same parked.json" \
  '[[ $(d next-parked unpark-empty) == 1 && ! -s $MD/u0 && $(d unpark-empty unpark-printed) == 2 && $(cat "$MD/u1") == A && $(cat "$MD/u2") == A ]]'
check "F bump (a write) starts node every time" '[[ $(d unpark-printed bump) == 2 && $(jq .A "$A") == 3 ]]'
check "answers_hash: one inbox.mjs start for two calls on one INBOX.md, a new start and hash after its answers change" \
  '[[ $(d bump answers) == 1 && $(d answers answers-new) == 1 && $(cat "$MD/h1") == $(cat "$MD/h2") && $(cat "$MD/h1") != $(cat "$MD/h3") && -n $(cat "$MD/h1") ]]'
check "a hit prints what node prints, byte for byte, and its exit code (snapshot, lint, a lone newline)" \
  'node "$HH/lib/features.mjs" snapshot "$L" | cmp -s - "$MD/snap2" && cmp -s "$MD/snap1" "$MD/snap2" && cmp -s <(node "$HH/lib/features.mjs" lint "$L") "$MD/lint2" \
   && [[ $(paste -sd, "$MD/lint-rc") == "$(node "$HH/lib/features.mjs" lint "$L" > /dev/null; echo $?),$(node "$HH/lib/features.mjs" lint "$L" > /dev/null; echo $?)" ]] \
   && [[ $(od -An -c "$MD/ms2") == "$(od -An -c "$MD/ms1")" && $(wc -c < "$MD/ms2") == 1 ]]'
check "the memo writes nothing to disk (no file outside the check's own) and nothing to stderr" \
  '[[ ! -s $MD/err && -z $(find "$T" -newer "$MD/marker" -type f ! -path "$MD/*" ! -name "*.lock" -print -quit) ]]'
check "features.mjs models: every alias of MODELS, <alias>\\t<id>; node --check lib/features.mjs" \
  'node --check "$HH/lib/features.mjs" && [[ $(node "$HH/lib/features.mjs" models | grep -c "^opus	claude-opus-5-5$") == 1 && $(node "$HH/lib/features.mjs" models | wc -l) == 4 ]]'
# ---- C1-03: features.mjs poll (five answers, one start), the memo it seeds, unpark_warm, the coordinator's lanes_v ----
# A fixture with one parked feature (B) and one blocked by it (C, in its lane; D, M2's, through its lane), a next (E,
# after: []) and a default-lane feature (Z)
PD=$MD/poll; mkdir -p "$PD"; PL=$PD/list.json PA=$PD/att.json PP=$PD/parked.json
cat > "$PL" << 'EOF'
{ "features": [
  { "id": "A", "milestone": "M1", "description": "a", "steps": ["x"], "passes": true },
  { "id": "B", "milestone": "M1", "description": "b", "steps": ["x"], "passes": false },
  { "id": "C", "milestone": "M1", "description": "c", "steps": ["x"], "passes": false },
  { "id": "D", "milestone": "M2", "description": "d", "steps": ["x"], "passes": false },
  { "id": "E", "milestone": "M3", "after": [], "model": "sonnet", "description": "e", "steps": ["x"], "passes": false },
  { "id": "Z", "after": [], "description": "z", "steps": ["x"], "passes": true } ] }
EOF
echo '{"E":1}' > "$PA"; echo '{"B":{"answers":"h0","why":"needs a key","at":"t"}}' > "$PP"; cp "$PP" "$PD/parked.orig"
pollu=$(cd "$PD" && FMJS=$HH/lib/features.mjs node --input-type=module -e '
import { spawnSync } from "node:child_process";
import { readFileSync } from "node:fs";
const FM = process.env.FMJS, { pollLines } = await import(FM), run = a => spawnSync(process.execPath, [FM, ...a], { encoding: "utf8" });
const lab = (l, r) => r.stdout.split("\n").filter(Boolean).map(x => `${l}\t${x}`);
const out = [];
for (const lane of [null, "M1", "M2", "M3", "default"]) {
  const args = ["list.json", "att.json", "3", "parked.json", ...(lane ? [lane] : [])];
  const exp = [...lab("summary", run(["summary", "list.json"])), ...lab("parked", run(["parked", "parked.json", "list.json"])),
    ...lab("blocked", run(["blocked", ...args])), ...lab("next", run(["next", ...args])),
    ...(lane ? [`milestone-done\t${run(["milestone-done", "list.json", lane]).status}`] : [])];
  const cli = run(["poll", ...args]), fn = pollLines(JSON.parse(readFileSync("list.json", "utf8")).features, JSON.parse(readFileSync("att.json", "utf8")), 3,
    JSON.parse(readFileSync("parked.json", "utf8")), lane);
  out.push(cli.status === 0 && cli.stdout === exp.map(l => l + "\n").join("") && fn.join("\n") === exp.join("\n") && exp.length >= 3);
}
console.log(out.join(" "), run(["blocked", "list.json", "att.json", "3", "parked.json"]).stdout.split("\n").filter(Boolean).length);' 2>&1)
check "features.mjs poll: its labelled lines are what summary, parked, blocked, next and milestone-done answer, for no lane and four lanes (pollLines the same)" \
  '[[ $pollu == "true true true true true 2" ]]'
(
  export PATH=$MD/shim:$PATH NODE_COUNT=$PD/count HARNESS_HOME=$HH HARNESS_HELPER=0; : > "$NODE_COUNT"
  source "$HH/lib/record.sh"
  n() { wc -l < "$NODE_COUNT" > "$PD/n-$1"; }
  n 0; Fv pv poll "$PL" "$PA" 3 "$PP" M1; printf '%s\n' "$pv" > "$PD/poll1"; n poll
  { F summary "$PL"; F parked "$PP" "$PL"; F blocked "$PL" "$PA" 3 "$PP" M1; F next "$PL" "$PA" 3 "$PP" M1; F milestone-done "$PL" M1; echo "md=$?"
    ( F summary "$PL"; F next "$PL" "$PA" 3 "$PP" M1 ); } > "$PD/seeded"; n seeded
  Fv pv poll "$PL" "$PA" 3 "$PP"; { F blocked "$PL" "$PA" 3 "$PP"; F next "$PL" "$PA" 3 "$PP"; } > "$PD/seeded0"; n seeded0
  echo '{"E":3}' > "$PA"; F next "$PL" "$PA" 3 "$PP" M3 > "$PD/next-gone"; n att-changed
  REC=$PD/rec PARKED=$PP; mkdir -p "$REC"; printf '# INBOX\n\n## Answers\n\nnew\n' > "$REC/INBOX.md"
  unpark_warm; n warm1; ( F unpark "$PP" "$(answers_hash)" ) > "$PD/u1"; n unpark1
  unpark_warm; n warm2; ( F unpark "$PP" "$(answers_hash)" ) > "$PD/u2"; n unpark2; unpark_warm; n warm3
  S=$PD/state; mkdir -p "$S/lanes/M3"; echo 'RUN_ID=pr' > "$S/meta.env"; cp "$PD/parked.orig" "$PP"; echo '{"E":1}' > "$PA"
  lanes_v l1 "$PL" "$PA" 3 "$PP" "$S"; lanes_v l2 "$PL" "$PA" 3 "$PP" "$S"; n lanes; printf '%s\n' "$l1" > "$PD/l1"
  touch "$S/verified-M1"; lanes_v l3 "$PL" "$PA" 3 "$PP" "$S"; n verified; printf '%s\n' "$l3" > "$PD/l3"
  sleep 30 & sp=$!; echo "$sp" > "$S/lanes/M3/pid"   # sleep-ok: a lane's live pid
  lanes_v l4 "$PL" "$PA" 3 "$PP" "$S"; lanes_v l4 "$PL" "$PA" 3 "$PP" "$S"; n alive; printf '%s\n' "$l4" > "$PD/l4"
  kill "$sp"; wait "$sp" 2> /dev/null; lanes_v l5 "$PL" "$PA" 3 "$PP" "$S"; n dead; printf '%s\n' "$l5" > "$PD/l5"
  printf 'x\n' > "$S/lanes/M3/review-escalate"; echo 0x1 > "$S/lanes/M3/pid"; lanes_v l6 "$PL" "$PA" 3 "$PP" "$S"; lanes_v l6 "$PL" "$PA" 3 "$PP" "$S"; n odd
) 2> "$PD/err"
pd() { echo $(( $(cat "$PD/n-$2") - $(cat "$PD/n-$1") )); }
FMJ=$HH/lib/features.mjs
check "F poll: one node start, and it fills the memo: summary, parked, blocked, next and milestone-done after it start none and print node's answers" \
  '[[ $(pd 0 poll) == 1 && $(pd poll seeded) == 0 ]] && cmp -s "$PD/seeded" <( cd "$PD"; node "$FMJ" summary "$PL"; node "$FMJ" parked "$PP" "$PL"; node "$FMJ" blocked "$PL" "$PA" 3 "$PP" M1
     node "$FMJ" next "$PL" "$PA" 3 "$PP" M1; node "$FMJ" milestone-done "$PL" M1; echo "md=$?"; node "$FMJ" summary "$PL"; node "$FMJ" next "$PL" "$PA" 3 "$PP" M1 ) \
   && [[ $(pd seeded seeded0) == 1 ]] && cmp -s "$PD/seeded0" <(node "$FMJ" blocked "$PL" "$PA" 3 "$PP"; node "$FMJ" next "$PL" "$PA" 3 "$PP") \
   && [[ $(grep -c "^E	claude-sonnet-5-5	M3$" "$PD/seeded0") == 1 && $(pd seeded0 att-changed) == 1 && ! -s $PD/next-gone ]]'
check "unpark_warm: with a feature to unpark it fills nothing (the unpark on the note line runs and prints it); with none, that unpark starts no node" \
  '[[ $(pd att-changed warm1) == 2 && $(pd warm1 unpark1) == 1 && $(cat "$PD/u1") == B && $(pd unpark1 warm2) == 1 && $(pd warm2 unpark2) == 0 && ! -s $PD/u2 && $(pd unpark2 warm3) == 0 ]]'
check "lanes_v: F lanes memoized on the list, attempts, parked and the state laneState reads (two starts, milestones with it), a hit, then one start each on verified-, a lane pid alive, dead" \
  '[[ $(pd warm3 lanes) == 2 && $(pd lanes verified) == 1 && $(pd verified alive) == 1 && $(pd alive dead) == 1 ]] \
   && [[ $(cut -f1 "$PD/l1" | paste -sd,) == M3 && $(cut -f1 "$PD/l3" | paste -sd,) == M2,M3 && $(cut -f1 "$PD/l4" | paste -sd,) == M2 && $(cut -f1 "$PD/l5" | paste -sd,) == M2,M3 ]]'
check "lanes_v: a pid file that is not digits is never memoized (node reads it its own way); stderr empty" '[[ $(pd dead odd) == 2 && ! -s $PD/err ]]'
# C1-06 (the review's minor 2): a poll short of parked.json's argument answers, seeds nothing, and set -u holds
pshort=$( export HARNESS_HOME=$HH; source "$HH/lib/record.sh"; set -u; cd "$PD"; F poll "$PL" > /dev/null; echo "rc=$? left=${#F_MEMO[@]}" ) 2>&1
check "F poll with only the list: no unbound name ends the shell under set -u (f_poll_seed seeds nothing)" '[[ $pshort == rc=0\ left=* ]]'

# ---- C1-03: an idle coordinator poll starts node at most once (MAX_LANES=2, M1's lane held, M2 waiting on M1) ----
# needs_sweep's needs.mjs start is the poll's one (it writes needs.md: never skipped), so the window counts its polls by
# it: from just after one coordinator sweep to the fifth after it, every coordinator start is counted. It opens a full
# poll after the session is held: the lane's attempt bump just before it is a new lanes_v key once (not idle yet)
echo 'MAX_LANES=2' >> "$T/user-config.sh"
IC=$MD/idle-count; : > "$IC"
sweeps() { grep -c "^lane= .*needs\.mjs sweep" "$IC"; }
( export HARNESS_HELPER=0 PATH=$MD/shim:$PATH NODE_COUNT=$IC STUB_BARRIER=A:idle STUB_NO_TAMPER=1 STUB_NO_RED=1; exec "$H" start "$T/proj" idle --spec SPEC.md --foreground ) > "$T/idle.out" 2>&1 & ip=$!
stub_wait idle.held 120; s0=$(sweeps); wait_for 60 eval '(( $(sweeps) > s0 + 1 ))'; c0=$(wc -l < "$IC"); s1=$(sweeps)
wait_for 60 eval '(( $(sweeps) >= s1 + 5 ))'; c1=$(wc -l < "$IC")
stub_go idle; wait "$ip"
sed -n "$(( c0 + 1 )),${c1}p" "$IC" > "$MD/idle-window"
iw_polls=$(grep -c "^lane= .*needs\.mjs sweep" "$MD/idle-window") iw_starts=$(grep -c "^lane= " "$MD/idle-window")
check "an idle coordinator poll (a free slot, nothing to open) starts node at most once: the window's starts without HARNESS_LANE are at most its polls (5 or more)" \
  '(( iw_polls >= 5 && iw_starts <= iw_polls )) && [[ -n $(hlog idle | grep -F "every feature passes") ]]'
check "bash -n lib/record.sh lib/lane.sh lib/driver.sh" 'bash -n "$HH/lib/record.sh" && bash -n "$HH/lib/lane.sh" && bash -n "$HH/lib/driver.sh"'
suite_end
