#!/usr/bin/env bash
source "$(dirname "$0")/../lib.sh" && suite_setup
# ---- the needs cards (U2-04): a template per reason in lib/needs.mjs, harness needs as cards, harness parked its alias ----
# Plan: docs/plans/2026-10-28-U2-needs-record.md §3, §3.1, §4.3. The facts per reason are tests/fixtures/needs/<reason>.json
# (real-shaped paths under /home/u; parked is n8n-home's Q2 from tests/fixtures/inbox-q-in-comment.md with a Files: line).
NM=$HERE/../lib/needs.mjs FX=$HERE/fixtures/needs
REASONS="parked given_up verify_thin verify_red verify_recheck merge_conflict merge_refused main_conflict base_conflict feature_list_edits initializer_failed driver_crash usage_limit weekly_budget overlap"
IMP="import * as N from \"$NM\"; import * as V from \"$HERE/../lib/view.mjs\"; const ok = c => process.exit(c ? 0 : 1);"
in_node() { node --input-type=module -e "$IMP $1"; }

# every field filled: no undefined, 2 to 4 sentences of why naming a lib/ file, one recommended option with its why,
# commands, where rows {path, line, label, url} with an absolute path or a link
FILLED='(tostring | test("undefined|NaN|\\[object") | not) and (.headline | length) > 0 and (.blocked | test("; ")) and (.cost | length) > 0
  and (.why | length) > 0 and (.why | test("lib/[a-z]+\\.(sh|mjs)")) and ([.why | scan("[.!?](\\s|$)")] | length) as $s | $s >= 2 and $s <= 4
  and (.where | length) > 0 and all(.where[]; (keys == ["label", "line", "path", "url"]) and ((.path // "" | startswith("/")) or (.url // "" | startswith("https://"))))
  and (.options | length) >= 2 and ([.options[] | select(.recommended)] | length) == 1 and ([.options[] | select(.recommended) | .why | length] | .[0]) > 0
  and ([.options[].key] | join("")) == ("abc"[:(.options | length)]) and (.commands | length) > 0 and all(.commands[]; length > 0)
  and (.files_from | IN("question", "driver")) and (.branch | length) > 0'
for r in $REASONS; do
  check "needs card $r: from its fixture, every field filled (why of 2-4 sentences, one recommended option, commands)" \
    "node \"\$NM\" card $r \"\$FX/$r.json\" > \"\$T/card-$r.json\" && jq -e '$FILLED' \"\$T/card-$r.json\" > /dev/null \
     && [[ \$(jq -r '(.question != null) == (\"$r\" == \"parked\")' \"\$T/card-$r.json\") == true ]]"
done
check "needs cards: 15 fixtures, one per reason, and a reason without a template is exit 1" \
  '[[ $(ls "$FX" | sed "s/\.json$//" | sort | paste -sd" ") == $(tr " " "\n" <<< "$REASONS" | sort | paste -sd" ") ]] \
  && ! node "$NM" card nope "$FX/parked.json" 2> /dev/null && ! node "$NM" card parked "$T/none.json" 2> /dev/null'
check "parked card: the INBOX question verbatim with its line 16 and ?plain=1#L16 URL, where from its Files: line, parked.mjs's commands" \
  'jq -e ".question.line == 16 and (.question.url | endswith(\"/blob/harness/n8n-home-2026-10-22/.harness/runs/n8n-home-2026-10-22/INBOX.md?plain=1#L16\"))
    and (.question.text | startswith(\"**Q2 (B1-05\")) and (.question.text | test(\"<!--\") | not) and .files_from == \"question\"
    and .where[0].path == \"/home/u/worktrees/n8n-home/n8n-home-2026-10-22/deploy/compose.yml\" and .where[0].line == 48
    and (.where[0].url | endswith(\"/deploy/compose.yml#L48\")) and .where[-1].label == \"question\" and .run_state == \"no\"
    and .commands == [\"harness answer n8n-home-2026-10-22 \\\"…\\\"\", \"harness continue n8n-home-2026-10-22\"]
    and .blocked == \"B1-05 (B1 live deploy); 3 features wait\"" "$T/card-parked.json" > /dev/null'
check "main_conflict card: why names sync_main in lib/record.sh and the memory run's M1–M5 (PRs #32–#36), not the run's own P1; the files and the compare URL" \
  'jq -e "(.why | contains(\"sync_main in lib/record.sh\")) and (.why | contains(\"main gained agent-harness-2026-10-25-memory M1–M5 (PRs #32–#36), and\"))
    and (.why | contains(\"#41\") | not) and ([.where[] | select(.label == \"conflict\")] | length) == 4
    and .where[-1].url == \"https://github.com/mh550/agent-harness/compare/main...harness-lane/agent-harness-2026-10-26/P2\"
    and .commit == {main: \"32dccef\", branch: \"4a3064a\"} and .headline == \"main conflicts with the run branch (4 files)\"" "$T/card-main_conflict.json" > /dev/null'
check "mergedBy: one merge is <run> M3 (PR #34), five of one run collapse, gaps are listed, the run's own are left out, others are PR #<n>, none is new commits" \
  'in_node "const m = (pr, r, x) => \`Merge pull request #\${pr} from mh550/harness-merge/\${r}-\${x}\`, mem = \"agent-harness-2026-10-25-memory\";
    ok(N.mergedBy(m(34, mem, \"M3\"), \"own\") === \`\${mem} M3 (PR #34)\`
      && N.mergedBy([36, 35, 34, 33, 32].map((p, i) => m(p, mem, \`M\${5 - i}\`)).join(\"\n\"), \"own\") === \`\${mem} M1–M5 (PRs #32–#36)\`
      && N.mergedBy([m(34, mem, \"M3\"), m(32, mem, \"M1\")], \"own\") === \`\${mem} M1, M3 (PRs #32, #34)\`
      && N.mergedBy([m(40, \"own\", \"P1\"), m(34, mem, \"M3\")], \"own\") === \`\${mem} M3 (PR #34)\` && N.mergedBy(m(40, \"own\", \"P1\"), \"own\") === \"new commits\"
      && N.mergedBy([\"Merge pull request #12 from someone/fix-typo\", m(34, mem, \"M3\")], \"own\") === \`PR #12; \${mem} M3 (PR #34)\`
      && N.mergedBy(\"\", \"own\") === \"new commits\")"'
# the review's fixes: merge heads split at the last -, fences and tabs in a question, a bad at, a card without a run
cat > "$T/review.mjs" <<'JS'
const N = await import(process.argv[2]), V = await import(process.argv[3]);
const m = (pr, h) => `Merge pull request #${pr} from mh550/harness-merge/${h}`, c = V.context({ env: { HARNESS_GLYPHS: "unicode", COLUMNS: "60" } });
const q = "### B: set these\nfirst line\nsecond line\n```bash\nexport A=1\n\tindented\n```\nFiles: lib/a.sh:3";
const k = N.card("parked", { run: "r", subject: "B", inbox_text: q + "\n\n## Answers\n", worktree: "/w" });
const out = N.renderCard({ run: "r", ref: "r/1", at: "", reason: "parked", card: k }, c, {}).join("\n");
const ok = [N.mergedBy([m(40, "own-default"), m(39, "own-M1")], "own") === "new commits", N.mergedBy([m(43, "x-M3"), m(38, "x-M3")], "own") === "x M3 (PR #43)",
  N.mergedBy(m(7, "x-default"), "own") === "x default (PR #7)", out.includes("first line second line\n"), out.includes("```bash\n"),
  out.includes("    indented"), !out.includes("\t"), out.includes("r/1 · since ?"), k.where[0].path === "/w/lib/a.sh" && k.where[0].line === 3];
if (!ok.every(Boolean)) console.log(ok.map(String).join(" ") + "\n" + out);
process.exit(ok.every(Boolean) ? 0 : 1);
JS
check "needs cards (review): own default-lane merges left out, a re-merge keeps its newest PR; a fence and tabs stay on their lines; a bad at is since ?; no run is exit 1" \
  'node "$T/review.mjs" "$NM" "$HERE/../lib/view.mjs" && ! node "$NM" card overlap <(echo "{\"subject\": \"x\"}") 2> /dev/null'
check "waitsOn: a feature's and a milestone's unfinished dependants through after, every unfinished one for run" \
  'in_node "const fs = [{ id: \"A\", milestone: \"M1\", passes: true }, { id: \"B\", milestone: \"M1\" }, { id: \"C\", milestone: \"M2\", after: [\"M1\"] },
      { id: \"D\", milestone: \"M3\", after: [\"A\"] }, { id: \"E\", milestone: \"M3\", after: [\"C\"] }];
    ok(N.waitsOn(fs, \"B\").join() === \"C,E\" && N.waitsOn(fs, \"M1\").join() === \"C,D,E\" && N.waitsOn(fs, \"run\").join() === \"B,C,D,E\" && N.waitsOn(fs, \"Z\").length === 0)"'
check "notify.mjs urls compare <origin> <base> <branch>: the GitHub compare URL; exit 1 off GitHub" \
  '[[ $(node "$HERE/../lib/notify.mjs" urls compare git@github.com:mh550/agent-harness.git main harness/r1) == "https://github.com/mh550/agent-harness/compare/main...harness/r1" ]] \
  && ! node "$HERE/../lib/notify.mjs" urls compare /srv/git/x.git main harness/r1 > /dev/null'
check "view.mjs cutFront keeps the end from a directory boundary; card with rule: false has no rule; a url-only field is the url line alone" \
  'in_node "const c = V.context({ env: { HARNESS_GLYPHS: \"unicode\" } }), p = \"/home/u/worktrees/n8n-home/n8n-home-2026-10-22/deploy/compose.yml:48\";
    const k = V.card(\"h\", [{ label: \"x\", value: \"1\" }, { label: \"\", url: \"https://e.x/a\" }], c, { rule: false });
    ok(V.cutFront(p, 47, c) === \"…/n8n-home-2026-10-22/deploy/compose.yml:48\" && V.cutFront(\"short\", 10, c) === \"short\"
      && V.displayWidth(V.cutFront(p, 30, c)) <= 30 && k.join(\"|\") === \"h|  x          1|  https://e.x/a\" && V.card(\"h\", [], c)[1].startsWith(\"─\"))"'

# the text view over a parked and a main_conflict item opened from the fixtures
ST=$HARNESS_STATE/proj; NOW=$(date -d "2026-10-27 01:10" +%s); export HARNESS_GLYPHS=unicode
for r in parked main_conflict; do
  needs_fixture "$r" open "" "nc-$r"; rm -rf "$ST/nc-$r/needs"; rec=$T/wt/proj/nc-$r/.harness/runs/nc-$r
  cp "$HERE/fixtures/inbox-q-in-comment.md" "$rec/INBOX.md"
  mapfile -d '' -t kv < <(jq -j 'del(.features, .inbox_text, .run, .project, .reason, .subject) | to_entries[] | "\(.key)=\(.value)\u0000"' "$FX/$r.json")
  HARNESS_NOW=$(( NOW - 300 )) node "$NM" open "$ST/nc-$r" "nc-$r" proj "$r" "$(jq -r .subject "$FX/$r.json")" "${kv[@]}" inbox="$rec/INBOX.md" list="$rec/feature_list.json" > /dev/null
done
echo '{"B1-05":{"why":"Q2","at":"2026-10-27T00:05:00.000Z"}}' > "$ST/nc-parked/parked.json"
touch "$T/nc.stamp"
V() { HARNESS_NOW=$NOW HOME=/home/u "$H" needs "$@"; }
V nc-main_conflict > "$T/v80.out"; COLUMNS=60 V nc-main_conflict > "$T/v60.out"; COLUMNS=60 V > "$T/all60.out"
check "harness needs: NEEDS YOU, a card per item (<glyph> <run> · <headline> · since <HH:MM> (<ago>) · <ref>), blocked, why, where, URLs, options, do; the footer" \
  '[[ $(head -1 "$T/v80.out") =~ ^"NEEDS YOU 1 "(─)+$ && $(sed -n 2p "$T/v80.out") == "⚠ nc-main_conflict · main conflicts with the run branch (4 files) · since 01:05 (5m) · nc-main_conflict/1" ]] \
  && for l in "  blocked    P2 " "  why        Before each verify" "  where      /home/u/worktrees/" "  https://github.com/mh550/agent-harness/compare/main...harness-lane/agent-harness-2026-10-26/P2" \
       "  options    (a) merge main into the branch by hand" "  do         cd /home/u/worktrees/" "done by hand: harness needs done <ref> · resolved too: harness needs --all"; do
       grep -F -- "$l" "$T/v80.out" > /dev/null || { echo "missing: $l"; miss=1; }; done; [[ -z ${miss:-} && $(tail -1 "$T/v80.out") == "done by hand: harness needs done <ref> · resolved too: harness needs --all" ]]'
check "COLUMNS=60 harness needs: no line over 60 but URLs; the narrow header (… · <ago>) and a ref field; where cut at the front keeps file and line" \
  '[[ $(widest < "$T/all60.out") -le 60 && $(widest < "$T/v60.out") -le 60 ]] && [[ $(sed -n 2p "$T/v60.out") == "⚠ nc-main_conflict · main conflicts with the run branc… · 5m" ]] \
  && grep -x "  ref        nc-main_conflict/1 · since 01:05 (5m)" "$T/v60.out" > /dev/null && grep -E "^ +…/.*/tests/fixtures/check-names.txt$" "$T/v60.out" > /dev/null \
  && grep -E "^  https://.{60,}" "$T/v60.out" > /dev/null && grep -x "NEEDS YOU 2 · 2 runs ─*" "$T/all60.out" > /dev/null'
check "harness needs --json: each command's full text (no ~, no cut)" \
  'V nc-main_conflict --json | jq -e ".[0].card.commands[0] == \"cd /home/u/worktrees/agent-harness/lanes/agent-harness-2026-10-26/slot-1 && git merge origin/main\"" > /dev/null'
check "harness parked is harness needs for text: the parked card's question from INBOX.md, run, do" \
  'HARNESS_NOW=$NOW HOME=/home/u "$H" parked nc-parked > "$T/p.out" && cmp -s "$T/p.out" <(V nc-parked) && grep "^⚠ nc-parked · B1-05 parked: " "$T/p.out" > /dev/null \
  && grep -F "  question   **Q2 (B1-05, 2026-10-27 01:05)." "$T/p.out" > /dev/null && grep -x "  run        no" "$T/p.out" > /dev/null \
  && grep -x "             harness continue nc-parked" "$T/p.out" > /dev/null'
check "harness parked --json: today's keys for parked features only, plus ref and card" \
  '"$H" parked --json > "$T/p.json" && [[ $(jq -r "map(.run) | join(\" \")" "$T/p.json") == *nc-parked* && $(jq -r "map(.run) | join(\" \")" "$T/p.json") != *nc-main_conflict* ]] \
  && jq -e "map(select(.run == \"nc-parked\"))[0] | (keys_unsorted == [\"run\", \"project\", \"feature\", \"since\", \"why\", \"question\", \"running\", \"ending\", \"queued\", \"commands\", \"ref\", \"card\"])
    and .ref == \"nc-parked/1\" and .card.question.line == 16 and .feature == \"B1-05\" and .commands == .card.commands" "$T/p.json" > /dev/null'
check "harness needs and parked are read-only" '[[ -z $(find "$HARNESS_STATE" "$T/wt" -newer "$T/nc.stamp") ]]'

suite_end
