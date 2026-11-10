#!/usr/bin/env bash
# tier: fast
source "$(dirname "$0")/../lib.sh" && suite_setup
# ---- the journal, pure (E4): an entry's schema, the minimal entry, and progress.md rendered from the entries ----
# the pure functions' tests are tests/unit/entries.test.mjs and tests/unit/memlint.test.mjs; what stays here is the CLI
# (validate, render, pack, ingest) on run directories this file writes, and init's deploy guards
mkdir -p "$T/jr/legacy" "$T/jr/new" && echo '# old progress' > "$T/jr/legacy/progress.md" \
  && echo '{"feature":"A","kind":"coding","outcome":"passes","summary":"did A","at":"2026-10-22 02:00","session":"01-A","model":"m"}' > "$T/jr/new/entries.jsonl"
check "entries.mjs: the render CLI leaves a legacy progress.md alone and renders entries.jsonl to progress.md and its archive" '
  node "$HERE/../lib/entries.mjs" render "$T/jr/legacy" && [[ $(ls "$T/jr/legacy") == progress.md && $(cat "$T/jr/legacy/progress.md") == "# old progress" ]] \
  && node "$HERE/../lib/entries.mjs" render "$T/jr/new" && grep -qx "### 2026-10-22 02:00 · A · passes" "$T/jr/new/progress.md" && grep -qx "### 2026-10-22 02:00 · A · passes" "$T/jr/new/progress-archive.md" && grep -q "^# Progress — run \`new\`" "$T/jr/new/progress.md"'
mkdir -p "$T/pk" && printf '%s\n' '{"feature":"A","kind":"coding","outcome":"not yet","summary":"a1","dead_ends":[{"tried":"t","why":"w"}],"at":"x","session":"01-A","model":"m"}' '{oops' \
  '{"feature":"A","kind":"coding","outcome":"passes","summary":"a2","at":"x","session":"02-A","model":"m"}' > "$T/pk/entries.jsonl" \
  && echo '{"features":[{"id":"A","milestone":"M1","steps":["s"]}]}' > "$T/pk/feature_list.json" && printf 'status: run\n## Answers\nuse 7900\n' > "$T/pk/INBOX.md"
check "entries.mjs: the pack CLI refuses a bad cap and packs a run directory's dead ends, entries and answers" '
  ! node "$HERE/../lib/entries.mjs" pack "$T/pk" A 8k 2> /dev/null && ! node "$HERE/../lib/entries.mjs" pack "$T/pk" A 100 2> /dev/null \
  && node "$HERE/../lib/entries.mjs" pack "$T/pk" A > "$T/pk.md" && grep -qx -- "- Dead end (A, 01-A): t — w → entries.jsonl:1" "$T/pk.md" \
  && grep -q -- "^- x · A · passes: a2 → entries.jsonl:3$" "$T/pk.md" && grep -qx -- "- use 7900 → INBOX.md" "$T/pk.md" \
  && [[ $(node "$HERE/../lib/entries.mjs" pack "$T/jr/legacy" Z | head -1) == "# Context pack for \`Z\`" ]]'
# a journal a session or an editor damaged (E4 review F1, F2): a null line, wrongly typed fields and a blank line are
# skipped, never fatal; a last line without its newline doesn't swallow the next append; references stay real lines
mkdir -p "$T/jb" && printf '%s\n' '{"feature":"A","kind":"coding","outcome":"not yet","summary":"a1","dead_ends":[{"tried":"t","why":"w"}],"at":"x","session":"01-A","model":"m"}' null \
  '{"feature":"B","kind":"coding","outcome":"passes","summary":"b","dead_ends":"x","files":"y","discoveries":[{"text":"t","affects":"run"}]}' '' > "$T/jb/entries.jsonl" \
  && printf '%s' '{"feature":"A","kind":"coding","outcome":"not yet","summary":"a2","at":"x","session":"02-A","model":"m"}' >> "$T/jb/entries.jsonl" \
  && echo '{"features":[{"id":"A","milestone":"M1","steps":["s"]}]}' > "$T/jb/feature_list.json" && printf 'status: run\n## Answers\n' > "$T/jb/INBOX.md" \
  && echo '{"feature":"A","kind":"coding","outcome":"passes","summary":"a3"}' > "$T/jb/entry.json" && printf 'a3 done\n' > "$T/jb-final"
check "entries.mjs: a damaged journal line is skipped, never fused or fatal" '
  node "$HERE/../lib/entries.mjs" render "$T/jb" && [[ $(grep -c "^### " "$T/jb/progress.md") == 2 ]] \
  && node "$HERE/../lib/entries.mjs" pack "$T/jb" A > "$T/jb.md" && grep -qx -- "- Dead end (A, 01-A): t — w → entries.jsonl:1" "$T/jb.md" && grep -q -- "a2 → entries.jsonl:5$" "$T/jb.md" \
  && node "$HERE/../lib/entries.mjs" ingest "$T/jb" coding A 03-A m passes /dev/null "$T/jb-final" && [[ $(wc -l < "$T/jb/entries.jsonl") == 6 ]] \
  && node "$HERE/../lib/entries.mjs" pack "$T/jb" A | grep -- "a3 → entries.jsonl:6$" > /dev/null && node "$HERE/../lib/entries.mjs" pack "$T/jb" A | grep -- "a2 → entries.jsonl:5$" > /dev/null'
git init -q -b main "$T/vj" && echo '{"framework":"nextjs"}' > "$T/vj/vercel.json" && "$H" init "$T/vj" > "$T/init-vj.out" 2>&1 && "$H" init "$T/vj" > "$T/init-vj2.out" 2>&1
check "init: vercel.json gets git.deploymentEnabled harness/** false, other keys kept" 'jq -e ".framework == \"nextjs\" and .git.deploymentEnabled[\"harness/**\"] == false" "$T/vj/vercel.json" > /dev/null \
  && grep -q "added the deploy guard to vercel.json" "$T/init-vj.out" && grep -q "keep    vercel.json" "$T/init-vj2.out" && ! grep -q "added the deploy guard" "$T/init-vj2.out"'
git init -q -b main "$T/vd" && mkdir "$T/vd/.vercel" && "$H" init "$T/vd" > "$T/init-vd.out" 2>&1; git init -q -b main "$T/vn" && "$H" init "$T/vn" > "$T/init-vn.out" 2>&1
check "init: a Vercel project without vercel.json gets one" 'jq -e ".git.deploymentEnabled[\"harness/**\"] == false" "$T/vd/vercel.json" > /dev/null && grep -q "added the deploy guard to vercel.json" "$T/init-vd.out" \
  && [[ ! -e $T/vn/vercel.json && ! -e $T/vn/netlify.toml ]] && ! grep -q "deploy guard\|vercel\|netlify" "$T/init-vn.out"'
git init -q -b main "$T/nt" && printf '[build]\n  command = "make"\n  publish = "dist"\n\n[build.environment]\n  NODE_VERSION = "20"\n' > "$T/nt/netlify.toml" && "$H" init "$T/nt" > "$T/init-nt.out" 2>&1
ign() { sed -n 's/^ *ignore = "\(.*\)"$/\1/p' "$1" | sed 's/\\"/"/g'; }   # the [build] ignore command, unquoted
check "init: netlify.toml gets a [build] ignore for harness/* refs, other keys kept" 'grep -q "added the deploy guard to netlify.toml" "$T/init-nt.out" && grep -q "command = \"make\"" "$T/nt/netlify.toml" \
  && grep -q "NODE_VERSION = \"20\"" "$T/nt/netlify.toml" && c=$(ign "$T/nt/netlify.toml") && BRANCH=harness/x bash -c "$c" && ! BRANCH=main bash -c "$c"'

# the trim (R2-02) through ingest: a summary over its cap, the only error, is cut and the entry kept whole; validate exits 2
# when only the caps fail
mkdir -p "$T/jt" && node -e 'process.stdout.write(JSON.stringify({ feature: "A", kind: "coding", outcome: "not yet", summary: "A: " + "x".repeat(407), dead_ends: [{ tried: "t", why: "w" }] }))' > "$T/jt/entry.json" \
  && echo done > "$T/jt-final" && node "$HERE/../lib/entries.mjs" ingest "$T/jt" coding A 01-A m "not yet" /dev/null "$T/jt-final" > "$T/jt.out"; echo "exit $?" >> "$T/jt.out"
check "journal: ingest prints trimmed summary 410, exits 0 and appends the cut entry whole" '[[ $(cat "$T/jt.out") == "trimmed summary 410"$'"'"'\n'"'"'"outcome not yet"$'"'"'\n'"'"'"exit 0" ]] \
  && jq -e "(.minimal | not) and (.dead_ends | length) == 1 and (.summary | length) == 400" "$T/jt/entries.jsonl" > /dev/null'
# a project fact over 160 characters (prompts/coding.md's cap, which nothing checked before) is kept whole and named: the curator's gate decides what is written
mkdir -p "$T/jl" && node -e 'process.stdout.write(JSON.stringify({ feature: "N1-01", kind: "coding", outcome: "passes", summary: "s", discoveries: [{ text: "A project fact of 199 characters: " + "x".repeat(165), affects: ["project"] }, { text: "y".repeat(170), affects: ["run"] }] }))' > "$T/jl/entry.json" \
  && node "$HERE/../lib/entries.mjs" ingest "$T/jl" coding N1-01 01-N1-01 m passes /dev/null "$T/jt-final" > "$T/jl.out"; echo "exit $?" >> "$T/jl.out"
check "journal: ingest prints long 199 for a project fact over 160, exits 0 and keeps the fact whole" '[[ $(cat "$T/jl.out") == "long 199"$'"'"'\n'"'"'"outcome passes"$'"'"'\n'"'"'"exit 0" ]] \
  && jq -e "(.minimal | not) and (.discoveries[0].text | length) == 199" "$T/jl/entries.jsonl" > /dev/null'
node -e 'const w = (f, e) => require("fs").writeFileSync(process.argv[1] + "/" + f, JSON.stringify(e)), c = { feature: "A", kind: "coding", outcome: "passes" };
  w("caps.json", { ...c, summary: "s".repeat(401) }); w("hcap.json", { feature: "init", kind: "init", outcome: "passes", summary: "s", header: "h".repeat(2001) });
  w("hnum.json", { feature: "init", kind: "init", outcome: "passes", summary: "s", header: 7 }); w("mixed.json", { ...c, summary: "s".repeat(401), files: "f" }); w("good.json", { ...c, summary: "s" })' "$T/jt"
vx() { node "$HERE/../lib/entries.mjs" validate "$T/jt/$1" "${@:2}" > "$T/jt/$1.out"; echo $?; }
printf '{not json' > "$T/jt/bad.json" && echo '{"feature":"C","kind":"coding","outcome":"done","summary":"s"}' > "$T/jt/outdone.json"
check "journal: validate exits 2 when its only errors are the caps, 1 with any other" '[[ $(vx caps.json A coding) == 2 && $(cat "$T/jt/caps.json.out") == "summary: 401 characters (at most 400)" ]] \
  && [[ $(vx hcap.json) == 2 && $(cat "$T/jt/hcap.json.out") == "header: 2001 characters (at most 2000)" ]] && [[ $(vx hnum.json) == 1 && $(cat "$T/jt/hnum.json.out") == "header: not a string" ]] \
  && [[ $(vx mixed.json) == 1 && $(vx good.json A coding) == 0 && $(vx caps.json B coding) == 1 && $(vx nope.json) == 1 ]] \
  && [[ $(vx bad.json) == 1 ]] && grep "^not JSON: " "$T/jt/bad.json.out" > /dev/null \
  && [[ $(vx outdone.json C coding) == 1 && $(cat "$T/jt/outdone.json.out") == "outcome: \"done\" is not passes · not yet · parked" ]]'

suite_end
