#!/usr/bin/env bash
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
  export PATH=$MD/shim:$PATH NODE_COUNT=$MD/count HARNESS_HOME=$HH; : > "$NODE_COUNT"
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
check "bash -n lib/record.sh lib/lane.sh lib/driver.sh" 'bash -n "$HH/lib/record.sh" && bash -n "$HH/lib/lane.sh" && bash -n "$HH/lib/driver.sh"'
suite_end
