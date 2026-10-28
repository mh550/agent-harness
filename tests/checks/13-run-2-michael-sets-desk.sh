#!/usr/bin/env bash
source "$(dirname "$0")/../lib.sh" && suite_setup
REPLAY=1   # replayed for their state, checked in their own files (tests/split.sh REPLAYS_)
# ---- run 1: misbehaving sessions, two milestones; verified milestones merge themselves ----
"$H" start "$T/proj" demo --spec SPEC.md --brief "only A–C" --foreground > "$T/run1.out" 2>&1
WT=$T/wt/proj/demo RD=$T/wt/proj/demo/.harness/runs/demo; hlog demo > "$T/demo-hlog.md"   # gc removes the worktree; run 15e reads it
check "all features pass"                 '[[ $($F summary "$(list demo)") == "3/3 passing" ]]'
check "tampered list restored"            'hlog demo | grep -q "restored the feature list after B"'
check "tampered text reverted"            '[[ $(jq -r ".features[2].description" "$(list demo)") == c ]]'
check "red suite un-passes C"             'hlog demo | grep -q "C un-passed: suite red"'
check "C retried and passed"              'grep -q "C attempt 2" "$T/scratch/proj/demo/sessions.log"'
check "verifier caught A, re-queued"      'hlog demo | grep -q "verify M1: A failed the re-check" && grep -q "A attempt 2" "$T/scratch/proj/demo/sessions.log"'
check "M1 and M2 tagged"                  'git -C "$T/origin.git" tag | grep -qx run/demo/M1 && git -C "$T/origin.git" tag | grep -qx run/demo/M2'
check "M1 and M2 merged into main by PRs" '[[ $(grep -c "pr merge" "$T/gh.log") == 2 ]] && on_main run/demo/M2 && hlog demo | grep -q "M2 merged into main"'
check "no final tag, no false 'verified'" '! git -C "$T/origin.git" tag | grep -q final && ! hlog demo | grep -q "final verified"'
check "the verify prompt says the suite runs in full" 'grep -q "cleared the suite'"'"'s cached result" "$HARNESS_STATE/proj/demo/prompt-verify.md"'
check "brief committed with the run"      'grep -q "only A–C" "$RD/brief.md"'
check "brief, rules and policy in the prompt" 'P=$HARNESS_STATE/proj/demo/prompt-coding.md; grep -q "only A–C" "$P" && grep -qx "# Project rules" "$P" && grep -q "\`CLAUDE.md\`" "$P" && grep -q "Policy: build-only" "$P"'
check "coding prompt names CLAUDE.md but doesn't paste it" 'P=$HARNESS_STATE/proj/demo/prompt-coding.md; grep -q CLAUDE.md "$P" && ! grep -qx rules "$P"'
check "the rendered coding prompt has the deepEqual and bounded-rerun rule" 'P=$(bash "$HERE/../lib/prompt.sh" "$HARNESS_STATE/proj/demo" coding A 2> /dev/null) && grep -q "deepEqual" <<< "$P" && grep -q "exit 137" <<< "$P" && grep -q -- "--test-name-pattern" <<< "$P"'
# each session's prompt is kept beside its transcript; two coding sessions share everything up to and past the policy (E3-03)
off() { grep -bo "$1" "$2" 2> /dev/null | head -1 | cut -d: -f1; }   # the 0-based byte offset of the first $1 in $2
PA=$(ls "$HARNESS_STATE"/proj/demo/logs/*-A.prompt.md 2> /dev/null | head -1) PB=$(ls "$HARNESS_STATE"/proj/demo/logs/*-B.prompt.md 2> /dev/null | head -1)
CB=$(cmp "$PA" "$PB" 2> /dev/null | sed -n 's/.* differ: \(byte\|char\) \([0-9]*\),.*/\2/p')
check "two coding prompts share a byte-identical prefix that includes the policy" '[[ -s $PA && -s $PB && -n $CB && -n $(off "Policy: build-only" "$PA") ]] \
  && (( CB - 1 > $(off "Policy: build-only" "$PA") && CB - 1 > $(off "Policy: build-only" "$PB") )) \
  && (( $(off "Policy: build-only" "$PA") < $(off "only A–C" "$PA") && $(off "only A–C" "$PA") < $(off "# This session" "$PA") )) \
  && (( CB - 1 > $(off "# This session" "$PA") && $(off "Clock:" "$PA") > $(off "# This session" "$PA") ))'
# the clock line: time, deadline, budget, turns, attempt or verify round (E3-04); C's later prompt is its second attempt
PC=$(ls "$HARNESS_STATE"/proj/demo/logs/*-C.prompt.md 2> /dev/null | tail -1)
check "the prompt says the time, the budget and the attempt" '[[ -s $PC ]] && grep -Eqx "Clock: [0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2} · run [0-9]+h[0-9]{2}m of [0-9]+h([0-9]{2}m)?, ends [0-9]{2}:[0-9]{2} · this session: \\\$20 budget, 250 turns, 100m timeout · attempt 2 of 2" "$PC" \
  && [[ $(grep -l "verify round 2 of 2" "$HARNESS_STATE"/proj/demo/logs/*-verify-M1.prompt.md 2> /dev/null | wc -l) == 1 ]]'
check "metrics: wall time and roles"      'jq -e "select(.kind==\"coding\") | .wall_s != null and .role == \"build\"" "$RD/metrics.jsonl" > /dev/null'
check "metrics: coding rows carry tokens, cache rate and context peak" 'jq -se "map(select(.kind==\"coding\")) | length > 0 and all(.tokens_in > 0 and .cache_hit_rate >= 0 and .cache_hit_rate <= 1 and .context_peak > 0)" "$RD/metrics.jsonl" > /dev/null'
check "metrics.jsonl: every session line has mem_peak_mb from its scope" 'jq -se "length >= 9 and all(.mem_peak_mb == 2)" "$RD/metrics.jsonl" > /dev/null && ! grep -q "Memory peaks" "$RD/report.md"'
check "metrics: orientation recorded per session" 'jq -se "map(select(.kind==\"coding\")) | length > 0 and all(.orient_tokens > 0 and .orient_turns >= 1 and (.orient_s | type) == \"number\")" "$RD/metrics.jsonl" > /dev/null'
# the journal (E4-03): one line per session in session order, stamped by the driver, and no entry.json left behind;
# C's first attempt (it left the suite red) carries its dead end; the record branch has every line, the tag (code) none of the record
check "entries: the driver appends each session's entry" '[[ $(jq -r .feature "$RD/entries.jsonl" 2> /dev/null | paste -sd" ") == "init A B M1 A M1 C C M2" ]] \
  && [[ $(jq -r .session "$RD/entries.jsonl" | sed "s/^[0-9]\{6\}-verify-/verify-/" | paste -sd" ") == "00-init 01-A 02-B verify-M1 03-A verify-M1 04-C 05-C verify-M2" ]] \
  && jq -se "all(.at | test(\"^[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}$\")) and all(.model | startswith(\"claude-\")) and all(has(\"minimal\") | not) \
    and (map(select(.session == \"04-C\"))[0].dead_ends[0].tried == \"left BROKEN in the tree\")" "$RD/entries.jsonl" > /dev/null && [[ ! -e $RD/entry.json ]] \
  && ! git -C "$T/origin.git" cat-file -e harness/demo:.harness/runs/demo/entry.json 2> /dev/null \
  && [[ $(git -C "$T/origin.git" show harness/demo:.harness/runs/demo/entries.jsonl 2> /dev/null | tail -1 | jq -r .feature) == M2 ]] \
  && ! git -C "$T/origin.git" cat-file -e run/demo/M2:.harness/runs/demo 2> /dev/null'
# progress.md is rendered from the journal (E4-04): its entry headers are entries.jsonl's, newest first; the newest verify
# M1 entry carries its evidence table; the archive has every entry; the M2 PR quotes its verify entry with its rows
check "progress.md is rendered from the journal" 'head -1 "$RD/progress.md" | grep -q "^<!-- harness: rendered from entries.jsonl" \
  && [[ $(grep "^### " "$RD/progress.md") == "$(jq -r "\"### \" + .at + \" · \" + (if .kind == \"verify\" then \"verify \" else \"\" end) + .feature + \" · \" + .outcome" "$RD/entries.jsonl" | tac)" ]] \
  && awk "index(\$0, \"### \") == 1 { if (on) exit; if (index(\$0, \"verify M1\")) on = 1 } on" "$RD/progress.md" | grep -q "^| A | 1 |" \
  && [[ $(grep -c "^### " "$RD/progress-archive.md") == $(wc -l < "$RD/entries.jsonl") ]] \
  && grep -q "^### .* · verify M2 · passes$" "$HARNESS_STATE/proj/demo/pr-body.md" && grep -q "^| C | 1 |" "$HARNESS_STATE/proj/demo/pr-body.md"'
# the context pack before each coding and verify session (E4-05): C's second attempt got its first attempt's dead end,
# both prompts send the session there first, and the pack is committed with the run record on the record branch
check "context.md carries the earlier attempt's dead end" 'C5=$HARNESS_STATE/proj/demo/logs/05-C.context.md; grep -q "left BROKEN in the tree" "$C5" && (( $(wc -c < "$C5") <= 8192 )) \
  && grep -q "^# Context pack for \`M1\`" "$(ls "$HARNESS_STATE"/proj/demo/logs/*-verify-M1.context.md | head -1)" \
  && grep -qx "Read context.md first; the full record is entries.jsonl / progress-archive.md (all in the run directory)." "$HARNESS_STATE/proj/demo/prompt-coding.md" \
  && grep -qx "Read context.md first; the full record is entries.jsonl / progress-archive.md (all in the run directory)." "$HARNESS_STATE/proj/demo/prompt-verify.md" \
  && git -C "$T/origin.git" cat-file -e harness/demo:.harness/runs/demo/context.md && hlog demo | grep -q "context.md for C: [0-9]* bytes"'
check "ended: done; status says so"       'grep -q "^done" "$HARNESS_STATE/proj/demo/ended" && S=$(HARNESS_GLYPHS=unicode "$H" status demo) && [[ ${S%%$'"'"'\n'"'"'*} == "✓ demo · proj · done · "* ]] && [[ $("$H" status demo --json | jq -r .end_reason) == done ]]'
check "summary, report and retro written" '[[ $(jq .features.merged "$RD/summary.json") == 3 ]] && grep -q "per passing feature" "$RD/report.md" && grep -q "Stub retro" "$RD/retro.md"'
check "summary: tokens, per verified feature, first-attempt rate, rework" 'jq -e ".tokens.in > 0 and .per_verified_feature.cost > 0 and .rework == [\"A\", \"C\"] and .first_attempt_pass_rate == 0.33 and .verify_fail_rate > 0" "$RD/summary.json" > /dev/null'
check "report shows tokens and quality"   'R=$("$H" report demo); grep -q "^| Tokens | .* in (cache hit .*context peak .*per verified feature " <<< "$R" && grep -q "^| Quality | first-attempt pass rate 0.33 · rework A, C · verify-fail rate " <<< "$R"'
check "ledger has the run"                'grep -q "\"run\":\"demo\"" "$T/ledger/runs.jsonl" && [[ -f $T/ledger/proj/demo/summary.json ]]'
HV=$(git -C "$HERE/.." log -1 --format=%h -- . ":(exclude)ledger")   # the demo run's harness is this checkout; its own ledger commits don't count
check "ledger row has harness_version and harness_dirty" 'jq -se --arg v "$HV" "map(select(.run == \"demo\"))[0] | .harness_version == \$v and (.harness_dirty | type == \"boolean\")" "$T/ledger/runs.jsonl" > /dev/null \
  && grep -q " run demo on .* · harness $HV\(+dirty\)\?$" "$HARNESS_STATE/proj/demo/run.log" && [[ $(cat "$HARNESS_STATE/proj/demo/harness-version") == "$HV" ]]'
# the live harness commits its ledger/ after every run: such a commit is not a new version, nor ledger files dirt
VR=$T/vrepo; mkdir -p "$VR/lib" "$VR/ledger"; vg() { git -C "$VR" -c user.name=t -c user.email=t@t "$@"; }
vg init -q -b main; echo a > "$VR/lib/x"; vg add -A; vg commit -qm code; VC=$(vg rev-parse --short HEAD)
echo r > "$VR/ledger/runs.jsonl"; vg add -A; vg commit -qm ledger; echo r2 >> "$VR/ledger/runs.jsonl"; echo n > "$VR/ledger/new"
check "harness version skips ledger commits" 'V1=$(source "$HERE/../lib/version.sh"; harness_version "$VR"; echo "$HARNESS_VERSION $HARNESS_DIRTY") \
  && echo b >> "$VR/lib/x" && V2=$(source "$HERE/../lib/version.sh"; harness_version "$VR"; echo "$HARNESS_VERSION $HARNESS_DIRTY") \
  && V3=$(source "$HERE/../lib/version.sh"; harness_version "$T/nonexistent"; echo "$HARNESS_VERSION $HARNESS_DIRTY") && [[ $V1 == "$VC 0" && $V2 == "$VC 1" && $V3 == "unknown 0" ]]'
check "harness report prints the writeup" 'grep -q "Spend by role" <<< "$("$H" report demo)"'
# reviews sized to the milestone (R2): the demo has no review feature, so a copy of its summary gets a review cost
check "the report lists the review role when a review ran" 'jq ".cost.by_role.review = 1.25" "$RD/summary.json" > "$T/summary-review.json" \
  && grep -q "^| Spend by role | .*build \$[0-9.]* · review \$1.25 · .*manager (the bash driver) \$0.00 |$" <<< "$(node "$HERE/../lib/summary.mjs" report "$T/summary-review.json")"'
check "init model resolved to fable"      'grep -q "initializer · claude-fable-5-1" "$HARNESS_STATE/proj/demo/run.log"'
check "summary end reason is how the run ended" '[[ $(jq -r .end_reason "$RD/summary.json") == done ]]'
check "a milestone without an after list is noted" 'hlog demo | grep -q "dependencies: M2 has no after list"'
# the step lint (R3) and the after rule (R10): the initializer runs the live harness's lint; the driver notes what is left, once
check "the initializer prompt has the resolved lint command" 'grep -qF "\`node $(readlink -f "$HERE/..")/lib/features.mjs lint <run directory>/feature_list.json\`" "$HARNESS_STATE/proj/demo/prompt-initializer.md"'
check "the initializer prompt sizes reviews to the milestone" 'grep -q "folds its review" "$HARNESS_STATE/proj/demo/prompt-initializer.md" \
  && grep -q "milestone'\''s size doesn'\''t call for). No output means clean." "$HARNESS_STATE/proj/demo/prompt-initializer.md"'
check "the initializer prompt asks for after on independent features and on every milestone's first" 'grep -qF "Give \`after\` on any feature that doesn'\''t need its predecessor in the same milestone, and on every milestone'\''s first feature (\`[]\` when independent)" "$HARNESS_STATE/proj/demo/prompt-initializer.md"'
check "the driver notes the lint once after the initializer" '[[ $(hlog demo | grep -c "lint: ") == 1 ]] \
  && hlog demo | grep -q "lint: 5 findings (no-anchor: 4, undeclared: 1); the list is not edited — first: A step 1 no-anchor$" && hlog demo | grep -q "dependencies: M2 has no after list"'
LF=$(git -C "$T/origin.git" log harness/demo --format=%H --grep="^HARNESS: feature list" -1) LI=$(git -C "$T/origin.git" log harness/demo --format=%H --grep="^HARNESS: initializer done" -1)
check "the driver never edits the list: the initializer's feature_list.json is byte for byte the stub's" '[[ -n $LF && -n $LI ]] \
  && git -C "$T/origin.git" show "$LF:.harness/runs/demo/feature_list.json" > "$T/list-stub.json" && git -C "$T/origin.git" show "$LI:.harness/runs/demo/feature_list.json" > "$T/list-init.json" \
  && [[ -s $T/list-stub.json ]] && cmp -s "$T/list-stub.json" "$T/list-init.json"'
check "NTFY_URL: curl posts the fields as headers, NOTIFY_CMD not called" 'B=$(curl_with "[demo] started:"); [[ $(tail -1 <<< "$B") == https://ntfy.example/t ]] && grep -A1 -x -- -H <<< "$B" | grep -qx "Title: harness" && grep -A1 -x -- --data-binary <<< "$B" | grep -qx "\[demo\] started: 0/3 passing" && [[ ! -e $T/notify-cmd.log ]]'
check "NTFY_TOKEN: bearer header sent, never logged" 'grep -qx "Authorization: Bearer tok-secret-123" "$T/curl.log" && [[ -d $HARNESS_STATE/proj/demo && -d $RD ]] && ! grep -rq tok-secret-123 "$HARNESS_STATE/proj/demo" "$RD"'
check "a successful post: a line in run.log only" 'grep -q "notified: harness" "$HARNESS_STATE/proj/demo/run.log" && ! hlog demo | grep -q "notified\|notification failed"'
check "routine notifications keep the default priority" 'Bs=$(curl_with "[demo] started:") Bm=$(curl_with "[demo] M1 merged") && [[ -n $Bs && -n $Bm ]] && ! grep -q "^Priority:" <<< "$Bs$Bm" \
  && grep -qx "Click: $GHP/blob/harness/demo/.harness/runs/demo/progress.md" <<< "$Bs" && U=$(grep -o "https://example.test/pr/[0-9]*" <<< "$Bm" | head -1) && [[ -n $U ]] && grep -qx "Click: $U" <<< "$Bm"'
# the record travels on its own branch (lanes P1-03): main gets exactly the verified lane tips, never the record
check "what lands on main is byte for byte what was verified" 'git -C "$T/origin.git" diff --quiet run/demo/M2 main'
check "no code PR touches the run record, and the record branch holds every entry" '[[ -z $(git -C "$T/origin.git" log --first-parent -m --name-only --format= main | grep "^\.harness/runs/") ]] \
  && [[ $(git -C "$T/origin.git" show harness/demo:.harness/runs/demo/entries.jsonl | jq -s length) == $(grep -cE " (init|coding|verify) exit " "$HARNESS_STATE/proj/demo/run.log") ]] \
  && [[ $(git -C "$T/origin.git" ls-tree -r main --name-only | grep -c "\.harness/runs/") == 0 ]]'

# ---- gc: main has every milestone; the run branch is record-only ----
"$H" gc "$T/proj" > "$T/gc.out" 2>&1
check "gc removed the finished worktree"  '[[ ! -d $WT ]]'
check "gc deleted the run branch"         '! git -C "$T/origin.git" rev-parse -q --verify harness/demo >/dev/null'
check "gc kept the tags"                  'git -C "$T/origin.git" tag | grep -qx run/demo/M2'
# gc's unit step (L2-05): units a SIGKILLed driver left. demo ended; killed's driver.pid is dead and it wrote no ended;
# gclive and demo-x have a live driver (demo's prefix also claims demo-x's unit, as lane x's: the live owner keeps it); oth is another project's
# c.d (proj, ended) and c-d (other, live) share harness-c-d-: the live one keeps the unit. 999999999 is over any pid_max
sleep 60 & GL1=$!; sleep 60 & GL2=$!; sleep 60 & GL3=$!; GLD=999999999
for r in gclive:$GL1 demo-x:$GL2 killed:$GLD other/oth: c.d: other/c-d:$GL3; do d=$HARNESS_STATE/${r%%:*}; [[ $d == */other/* ]] || d=$HARNESS_STATE/proj/${r%%:*}
  mkdir -p "$d"; cp "$HARNESS_STATE/proj/demo/meta.env" "$d/"; [[ -n ${r#*:} ]] && echo "${r#*:}" > "$d/driver.pid"; done
echo done > "$HARNESS_STATE/other/oth/ended"; echo done > "$HARNESS_STATE/proj/c.d/ended"
GCU="harness-demo-svc harness-demo-s99 harness-killed-svc harness-gclive-svc harness-demo-x-svc harness-oth-svc harness-nosuch-svc harness-c-d-svc"
for u in $GCU; do touch "$T/scope/$u".{alive,running}; done
gc_stops() { awk 'BEGIN { RS = "===\n" } /^systemctl\n--user\nstop\n/ { sub(/^systemctl\n--user\nstop\n/, ""); printf "%s", $0 }' "$T/systemd.log" 2>/dev/null | sort; }
GS0=$(gc_stops); "$H" gc "$T/proj" --dry-run > "$T/gcu1.out" 2>&1; GS1=$(gc_stops)
"$H" gc "$T/proj" > "$T/gcu2.out" 2>&1; GS2=$(comm -13 <(echo "$GS1") <(gc_stops) | paste -sd" ")
GCL=$("$HARNESS_SYSTEMCTL" --user list-units 'harness-*' --plain --no-legend | cut -d" " -f1 | sort | paste -sd" ")
check "harness gc stops the units of this project's runs with no live driver; --dry-run stops none" '[[ $GS1 == "$GS0" ]] \
  && grep -qx "would: systemctl --user stop harness-demo-svc.scope (demo ended)" "$T/gcu1.out" && grep -qx "would: systemctl --user stop harness-demo-s99.scope (demo ended)" "$T/gcu1.out" \
  && grep -qx "would: systemctl --user stop harness-killed-svc.scope (killed: driver gone)" "$T/gcu1.out" && [[ $(grep -c "^would: systemctl" "$T/gcu1.out") == 3 ]] \
  && grep -qx "? harness-nosuch-svc.scope (no run of this project)" "$T/gcu1.out" && grep -qx "? harness-oth-svc.scope (no run of this project)" "$T/gcu1.out" \
  && grep -qx "+ stopped harness-demo-svc.scope (demo ended)" "$T/gcu2.out" && grep -qx "+ stopped harness-demo-s99.scope (demo ended)" "$T/gcu2.out" \
  && grep -qx "+ stopped harness-killed-svc.scope (killed: driver gone)" "$T/gcu2.out" && [[ $(grep -c "^+ stopped" "$T/gcu2.out") == 3 ]] \
  && [[ $GS2 == "harness-demo-s99.scope harness-demo-svc.scope harness-killed-svc.scope" ]] \
  && ! grep -q harness-c-d-svc "$T/gcu1.out" "$T/gcu2.out" && ( for u in harness-demo-x-svc harness-gclive-svc harness-nosuch-svc harness-oth-svc harness-c-d-svc; do [[ " $GCL " == *" $u.scope "* ]] || exit 1; done )'
kill "$GL1" "$GL2" "$GL3" 2> /dev/null; wait "$GL1" "$GL2" "$GL3" 2> /dev/null
rm -rf "$HARNESS_STATE"/proj/{gclive,demo-x,killed,c.d} "$HARNESS_STATE/other"; for u in $GCU; do rm -f "$T/scope/$u".*; done   # a live fake driver.pid counts against MAX_PARALLEL_RUNS
# gc's branch passes (L4-01): a `*` doesn't cross a `/` in for-each-ref, so --all-merged must list by prefix and run
# every pass. Five merged branches (at origin/main) and an unmerged spec/u, each pushed to the origin with -u, as runs
# push. harness/noup has no upstream and this checkout's main is behind origin/main, so its `branch -d` is refused:
# gc says so and goes on (it used to end under set -e, before harness-merge/w).
git -C "$T/proj" fetch -q origin; GB=$(git -C "$T/proj" rev-parse origin/main)
gb_make() { local b; for b; do git -C "$T/proj" branch -f "$b" "$GB"; done; git -C "$T/proj" push -q -u origin "$@" 2> /dev/null; }
gb_has() { git -C "$1" rev-parse -q --verify "refs/heads/$2" > /dev/null; }   # gb_has <repo> <branch>
gb_both() { gb_has "$T/proj" "$1" && gb_has "$T/origin.git" "$1"; }; gb_none() { ! gb_has "$T/proj" "$1" && ! gb_has "$T/origin.git" "$1"; }
gb_make spec/x docs/y harness/z harness-merge/w flat
git -C "$T/proj" branch -f spec/u "$(git -C "$T/proj" commit-tree "$GB^{tree}" -p "$GB" -m unmerged)" && git -C "$T/proj" push -q -u origin spec/u 2> /dev/null
git -C "$T/proj" branch -f harness/noup "$GB" && git -C "$T/proj" push -q origin harness/noup
"$H" gc "$T/proj" > "$T/gcb1.out" 2>&1; GBR=$?
check "plain gc deletes only the merged harness/ and harness-merge/ branches, locally and on the origin" '[[ $GBR == 0 ]] && gb_none harness/z && gb_none harness-merge/w \
  && gb_both spec/x && gb_both docs/y && gb_both flat && gb_both spec/u && grep -qx "+ git -C $T/proj push -q origin --delete harness/z" "$T/gcb1.out"'
check "a refused branch -d (merged into origin/main, not into HEAD, no upstream) is logged and gc goes on" '! git -C "$T/proj" merge-base --is-ancestor origin/main main \
  && gb_has "$T/proj" harness/noup && ! gb_has "$T/origin.git" harness/noup && grep -qx "! failed: git -C $T/proj branch -d harness/noup" "$T/gcb1.out"'
git -C "$T/proj" branch -qD harness/noup
gb_make harness/z harness-merge/w
"$H" gc "$T/proj" --all-merged --dry-run > "$T/gcb2.out" 2>&1; GBD=$(for b in spec/x docs/y harness/z harness-merge/w flat; do gb_both "$b" || echo "$b"; done)
"$H" gc "$T/proj" --all-merged > "$T/gcb3.out" 2>&1
check "gc --all-merged deletes every merged branch whatever its name, locally and on the origin; an unmerged one survives" '[[ -z $GBD ]] \
  && [[ $(grep -c "^would: git -C $T/proj branch -d " "$T/gcb2.out") == 5 && $(grep -c "^would: git -C $T/proj push -q origin --delete " "$T/gcb2.out") == 5 ]] \
  && gb_none spec/x && gb_none docs/y && gb_none harness/z && gb_none harness-merge/w && gb_none flat && gb_both spec/u && gb_both main \
  && grep -qx "+ git -C $T/proj branch -d docs/y" "$T/gcb3.out" && grep -qx "+ git -C $T/proj push -q origin --delete spec/x" "$T/gcb3.out"'
git -C "$T/proj" branch -qD spec/u; git -C "$T/proj" push -q origin --delete spec/u
# gc's worktree removal finishes (L4-02, R9): merged, clean worktrees in path order (git worktree list sorts by path).
# gcw-a holds gitignored build output; gcw-c-ro/wt can't go (its parent is read-only) and gcw-d after it still must
gw_add() { local w; for w; do gb_make "harness/${w##*/}"; git -C "$T/proj" worktree add -q "$HARNESS_WORKTREES/proj/$w" "harness/${w##*/}"; done; }
gw_listed() { git -C "$T/proj" worktree list --porcelain | grep -qx "worktree $HARNESS_WORKTREES/proj/$1"; }
echo .next/ >> "$T/proj/.git/info/exclude"; mkdir -p "$HARNESS_WORKTREES/proj/gcw-c-ro"
gw_add gcw-a gcw-b gcw-c-ro/wt gcw-d; mkdir "$HARNESS_WORKTREES/proj/gcw-a/.next"; echo built > "$HARNESS_WORKTREES/proj/gcw-a/.next/f"
"$H" gc "$T/proj" --dry-run > "$T/gcw1.out" 2>&1
GWD=$(for w in gcw-a gcw-b gcw-c-ro/wt gcw-d; do gw_listed "$w" && [[ -d $HARNESS_WORKTREES/proj/$w ]] || echo "$w"; done)
chmod a-w "$HARNESS_WORKTREES/proj/gcw-c-ro"; "$H" gc "$T/proj" > "$T/gcw2.out" 2>&1; GWR=$?; chmod u+w "$HARNESS_WORKTREES/proj/gcw-c-ro"
check "gc removes merged, clean worktrees holding ignored build output (--force, then rm -rf)" '! gw_listed gcw-a && ! gw_listed gcw-b \
  && [[ ! -e $HARNESS_WORKTREES/proj/gcw-a && ! -e $HARNESS_WORKTREES/proj/gcw-b ]] \
  && grep -qx "+ git -C $T/proj worktree remove --force $HARNESS_WORKTREES/proj/gcw-a" "$T/gcw2.out" \
  && grep -qx "+ git -C $T/proj worktree remove --force $HARNESS_WORKTREES/proj/gcw-b" "$T/gcw2.out"'
check "a worktree gc can't remove is logged and the next one still goes; --dry-run removes none" '[[ -z $GWD && $GWR == 0 ]] \
  && [[ $(grep -c "^would: git -C $T/proj worktree remove --force $HARNESS_WORKTREES/proj/gcw-" "$T/gcw1.out") == 4 ]] \
  && grep -qx "! could not remove $HARNESS_WORKTREES/proj/gcw-c-ro/wt: .*Permission denied" "$T/gcw2.out" \
  && ! gw_listed gcw-d && [[ ! -e $HARNESS_WORKTREES/proj/gcw-d ]] && grep -qx "+ git -C $T/proj worktree remove --force $HARNESS_WORKTREES/proj/gcw-d" "$T/gcw2.out"'
rm -rf "$HARNESS_WORKTREES/proj/gcw-c-ro"; git -C "$T/proj" worktree prune
for w in gcw-a gcw-b wt gcw-d; do git -C "$T/proj" branch -qD "harness/$w" 2> /dev/null; git -C "$T/proj" push -q origin --delete "harness/$w" 2> /dev/null; done
# what gc must never remove, from the L4 review (L4-05), in one unattended --all-merged run: a worktree that is no run's
# (Michael's own session's: its branch isn't harness/<run>); a locked one (git refuses: no rm -rf after); one holding
# an untracked file that status.showUntrackedFiles=no hides; a locked one whose directory is gone (gc goes on past it);
# the origin's default branch (trunk here); a live run's merged branch
GWM=$HARNESS_WORKTREES/proj/mine; git -C "$T/proj" worktree add -q -b mine "$GWM" "$GB"
gw_add gcw-lk gcw-u gcw-gone; git -C "$T/proj" worktree lock "$HARNESS_WORKTREES/proj/gcw-lk"; echo note > "$HARNESS_WORKTREES/proj/gcw-u/notes.txt"
git -C "$T/proj" worktree lock "$HARNESS_WORKTREES/proj/gcw-gone"; rm -rf "$HARNESS_WORKTREES/proj/gcw-gone"
gb_make trunk harness/gcw-live harness/gcw-tail; git -C "$T/origin.git" symbolic-ref HEAD refs/heads/trunk; git -C "$T/proj" remote set-head origin trunk > /dev/null
mkdir -p "$HARNESS_STATE/proj/gcw-live"; echo $$ > "$HARNESS_STATE/proj/gcw-live/driver.pid"
git -C "$T/proj" config status.showUntrackedFiles no
"$H" gc "$T/proj" --all-merged > "$T/gcw3.out" 2>&1; GW3=$?
git -C "$T/proj" config --unset status.showUntrackedFiles
check "gc never removes a worktree that is no run's (its branch isn't harness/<run>), even merged and clean" '[[ -d $GWM ]] && gw_listed mine && gb_has "$T/proj" mine \
  && grep -qx "keeps $GWM: not a run worktree (branch mine)" "$T/gcw3.out"'
check "gc never rm -rfs a worktree git refused to remove (locked): it is said and stays" '[[ -f $HARNESS_WORKTREES/proj/gcw-lk/.git ]] && gw_listed gcw-lk \
  && grep -qx "! could not remove $HARNESS_WORKTREES/proj/gcw-lk: .*locked.*" "$T/gcw3.out" && ! grep -qx "+ rm -rf $HARNESS_WORKTREES/proj/gcw-lk" "$T/gcw3.out"'
check "gc keeps a worktree with an untracked file even when status.showUntrackedFiles=no hides it" '[[ $(cat "$HARNESS_WORKTREES/proj/gcw-u/notes.txt" 2> /dev/null) == note ]] && gw_listed gcw-u'
check "a listed worktree whose directory is gone never ends gc: every later step still runs" '[[ $GW3 == 0 ]] && gb_none harness/gcw-tail'
check "gc --all-merged keeps the origin default branch and a live run branch, merged or not" 'gb_both trunk && gb_both harness/gcw-live'
git -C "$T/origin.git" symbolic-ref HEAD refs/heads/main; git -C "$T/proj" remote set-head origin main > /dev/null; rm -rf "$HARNESS_STATE/proj/gcw-live"
for w in gcw-lk gcw-gone; do git -C "$T/proj" worktree unlock "$HARNESS_WORKTREES/proj/$w"; done
git -C "$T/proj" worktree remove --force "$GWM"; git -C "$T/proj" worktree remove --force --force "$HARNESS_WORKTREES/proj/gcw-lk" 2> /dev/null
git -C "$T/proj" worktree remove --force "$HARNESS_WORKTREES/proj/gcw-u" 2> /dev/null; git -C "$T/proj" worktree prune
for b in mine trunk harness/gcw-lk harness/gcw-u harness/gcw-gone harness/gcw-live harness/gcw-tail; do
  git -C "$T/proj" branch -qD "$b" 2> /dev/null; git -C "$T/proj" push -q origin --delete "$b" 2> /dev/null; done
# gc --deps (L4-03, B8): the dependency directories in the worktrees of ended runs go, merged or not (the branch keeps
# the work); a live run's (driver.pid = this shell), one with a queued continuation and the project checkout keep theirs
gd_run() { local r=$1 wt=${2:-$HARNESS_WORKTREES/proj/$1} d=$HARNESS_STATE/proj/$1; mkdir -p "$d"; touch "$d/ended"
  printf 'PROJECT_DIR=%q\nWT=%q\nRUN_ID=%q\nSTATE=%q\n' "$T/proj" "$wt" "$r" "$d" > "$d/meta.env"
  [[ $wt == "$T/proj" ]] || git -C "$T/proj" worktree add -q -b "harness/$r" "$wt" "$GB"; mkdir -p "$wt/node_modules"; echo x > "$wt/node_modules/x.js"; }
gd_run deps-end; gd_run deps-live; gd_run deps-q; gd_run deps-co "$T/proj"
GDE=$HARNESS_WORKTREES/proj/deps-end; mkdir "$GDE/.venv"; echo y > "$GDE/.venv/y"
echo kept > "$GDE/work.txt"; git -C "$GDE" add work.txt; git -C "$GDE" commit -qm "unmerged work"; GDH=$(git -C "$GDE" rev-parse HEAD)
echo $$ > "$HARNESS_STATE/proj/deps-live/driver.pid"; mkdir -p "$HARNESS_STATE/queue"; : > "$HARNESS_STATE/queue/x-continue-deps-q.args"
"$H" gc "$T/proj" --dry-run --deps > "$T/gcd1.out" 2>&1
GDD=$(for w in deps-end deps-live deps-q; do [[ -f $HARNESS_WORKTREES/proj/$w/node_modules/x.js ]] || echo "$w"; done; [[ -f $GDE/.venv/y ]] || echo venv)
"$H" gc "$T/proj" --deps > "$T/gcd2.out" 2>&1; GDR=$?
check "gc --deps empties an ended, unmerged run's worktree of its DEPS_DIRS; its branch and committed files stay; --dry-run deletes none" '[[ -z $GDD && $GDR == 0 ]] \
  && grep -qx "would: freed [0-9]* MB in $GDE: node_modules .venv" "$T/gcd1.out" && [[ $(grep -c "freed" "$T/gcd1.out") == 1 ]] \
  && [[ ! -e $GDE/node_modules && ! -e $GDE/.venv ]] && grep -qx "+ freed [0-9]* MB in $GDE: node_modules .venv" "$T/gcd2.out" \
  && [[ $(git -C "$T/proj" rev-parse harness/deps-end) == "$GDH" && $(cat "$GDE/work.txt") == kept && -z $(git -C "$GDE" status --porcelain) ]]'
check "gc --deps keeps the worktree of a live run and the project checkout" '[[ -f $HARNESS_WORKTREES/proj/deps-live/node_modules/x.js && -f $T/proj/node_modules/x.js ]] \
  && [[ $(grep -c "freed" "$T/gcd2.out") == 1 ]]'
check "gc --deps keeps the worktree of a run with a queued continuation" '[[ -f $HARNESS_WORKTREES/proj/deps-q/node_modules/x.js ]] && ! grep -q "freed .* in $HARNESS_WORKTREES/proj/deps-q:" "$T/gcd1.out" "$T/gcd2.out"'
# a deps dir gc can't read or delete (root-owned in real life: a mode-000 subdirectory here) is said and gc goes on; a
# symlinked .next pointing out of the tree is never followed (L4-05 review)
gd_run deps-ro; GDO=$HARNESS_WORKTREES/proj/deps-ro; mkdir -p "$GDO/node_modules/sub" "$T/outside"; echo k > "$GDO/node_modules/sub/f"; echo keep > "$T/outside/f"
ln -s "$T/outside" "$GDO/.next"; chmod 000 "$GDO/node_modules/sub"
"$H" gc "$T/proj" --deps > "$T/gcd3.out" 2>&1; GD3=$?; chmod 755 "$GDO/node_modules/sub"
check "a deps dir gc can't measure or delete is said and gc goes on; a symlinked deps dir is never followed" '[[ $GD3 == 0 ]] && grep -qx "! could not free $GDO: .*" "$T/gcd3.out" \
  && [[ $(cat "$T/outside/f") == keep && -L $GDO/.next ]]'
rm -f "$GDO/.next"; rm -rf "$T/outside"
rm -f "$HARNESS_STATE/queue/x-continue-deps-q.args"; rm -rf "$T/proj/node_modules"
for w in deps-end deps-live deps-q deps-ro; do git -C "$T/proj" worktree remove --force "$HARNESS_WORKTREES/proj/$w"; git -C "$T/proj" branch -qD "harness/$w"; done
rm -rf "$HARNESS_STATE"/proj/deps-{end,live,q,co,ro}   # a live fake driver.pid counts against MAX_PARALLEL_RUNS

REPLAY=
# ---- run 2: Michael sets "status: stop" in INBOX.md from the phone (and only NOTIFY_CMD is configured) ----
printf '%s\n' 'KEEP_SCRATCH=1 LEDGER_COMMIT=0 MAX_PARALLEL_RUNS=1' "NOTIFY_CMD='{ printf \"%s\\n\" \"\$1\"; env | grep ^HARNESS_NOTIFY_; echo ===; } >> \"$T/notify-env.log\"'" > "$T/user-config.sh"
# a continuation Michael requested before this stop (state_of needs a meta.env; the start writes the real one)
mkdir -p "$HARNESS_STATE/proj/stoppy" && printf 'RUN_ID=stoppy\n' > "$HARNESS_STATE/proj/stoppy/meta.env" && "$H" queue add --continue stoppy > /dev/null
STUB_PHONE_STOP=1 "$H" start "$T/proj" stoppy --spec SPEC.md --foreground > "$T/run2.out" 2>&1
cp "$T/base-config.sh" "$T/user-config.sh"
check "NOTIFY_CMD-only: \$1 unchanged, fields as env" 'grep -q "^\[stoppy\] started: 0/3 passing$" "$T/notify-env.log" && grep -qx "HARNESS_NOTIFY_TITLE=harness" "$T/notify-env.log" && grep -qx "HARNESS_NOTIFY_PRIORITY=" "$T/notify-env.log" && [[ -s $T/curl.log ]] && ! grep -q "\[stoppy\]" "$T/curl.log"'
check "phone stop honoured before any coding session" 'hlog stoppy | grep -q "stopped by Michael" && ! grep -q attempt "$T/scratch/proj/stoppy/sessions.log"'
check "a stop from the phone stops the services through finish" 'hlog stoppy | grep -q "· services stopped (stopped by Michael)$" && [[ -f $T/scratch/proj/stoppy/teardown-stopped-by-Michael.marker ]]'
check "a stop makes a queued requested continuation of its run automatic (the later word wins)" 'f=$(compgen -G "$HARNESS_STATE/queue/*-continue-stoppy.args") && grep -qx -- --queued "$f" \
  && ! grep -qx -- --requested "$f" && hlog stoppy | grep -qF "stop: the queued continuation ${f##*/} is automatic now (the stop came after the request)"'
rm -f "$HARNESS_STATE"/queue/*.args
check "second run got its own port"       '[[ $(cat "$HARNESS_STATE/proj/stoppy/port") != $(cat "$HARNESS_STATE/proj/demo/port") ]]'

# ---- run 3: a verifier that always rejects; C is independent of M1 ----
SPY3='printf "%s · %s\n" "$(printf "%s\n" "$@" | sed -n "s/^Title: //p")" "$(git -C "$STUB_DIR/origin.git" log -1 --format=%s harness/strict)" >> "$STUB_DIR/spy-strict.log"'
STUB_CURL_SPY=$SPY3 STUB_STRICT_VERIFIER=1 STUB_INDEPENDENT_M2=1 "$H" start "$T/proj" strict --spec SPEC.md --foreground > "$T/run3.out" 2>&1
check "verify ping-pong capped, needs Michael" 'hlog strict | grep -q "M1 needs Michael" && (( $(grep -c "^A attempt" "$T/scratch/proj/strict/sessions.log") <= 2 ))'
check "verify needs Michael: priority high, click = progress.md (GitHub-shaped origin)" 'Bv=$(curl_with "[strict] M1 needs Michael: A fails verification"); grep -qx "Title: \[strict\] M1 needs you" <<< "$Bv" \
  && grep -qx "Priority: high" <<< "$Bv" && grep -qx "Click: $GHP/blob/harness/strict/.harness/runs/strict/progress.md" <<< "$Bv"'
check "verify needs Michael goes out after the verify entry is pushed" 'grep -qxF "[strict] M1 needs you · HARNESS: verify M1" "$T/spy-strict.log"'
check "independent M2 verified and merged alone (its tag carries no M1 work)" 'on_main run/strict/M2 && [[ -n $(git -C "$T/origin.git" rev-list harness-lane/strict/M1 --not main) ]] \
  && [[ -z $(comm -12 <(git -C "$T/origin.git" rev-list harness-lane/strict/M1 --not main | sort) <(git -C "$T/origin.git" rev-list run/strict/M2 | sort)) ]]'
check "no dependency note when every milestone has after" '! hlog strict | grep -q "dependencies:"'

# ---- run 10: merges refused (MERGE_POLICY=auto but GitHub says no) → `harness merge` later ----
STUB_REFUSE_MERGE=1 STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_LENIENT=1 "$H" start "$T/proj" later --spec SPEC.md --foreground > "$T/run10.out" 2>&1
check "refused merge leaves the PR, needs Michael" 'hlog later | grep -q "merge was refused" && ! on_main run/later/M1'
check "a refused merge: priority high, click = the PR" 'Br=$(curl_with "[later] M1 needs Michael: merge refused"); U=$(grep -o "https://example.test/pr/[0-9]*" <<< "$Br" | head -1) \
  && [[ -n $U ]] && grep -qx "Title: \[later\] M1 needs you" <<< "$Br" && grep -qx "Priority: high" <<< "$Br" && grep -qx "Click: $U" <<< "$Br"'
echo old1234 > "$HARNESS_STATE/proj/later/harness-version"
"$H" merge later > "$T/run10b.out" 2>&1
check "harness merge keeps the harness version of the run (E1 review)" '[[ $(cat "$HARNESS_STATE/proj/later/harness-version") == old1234 ]]'
check "harness merge merges verified milestones afterwards" 'on_main run/later/M2 && grep -q "^done" "$HARNESS_STATE/proj/later/ended"'

# ---- run 16: a feature waiting on Michael parks (no attempt); independent work goes on; an answer unparks it ----
{ cat "$T/base-config.sh"; echo 'DESK_URL=https://claude.ai/code/env-test'; } > "$T/user-config.sh"
STUB_PARK=B STUB_INDEPENDENT_M2=1 STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_LENIENT=1 "$H" start "$T/proj" parky --spec SPEC.md --foreground > "$T/run16.out" 2>&1
S16=$T/wt/proj/parky/.harness/runs/parky/summary.json
check "parked: not an attempt, not retried" 'hlog parky | grep -q "B parked (waiting on Michael): set the gatus vars" && [[ $(jq -r ".B // 0" "$HARNESS_STATE/proj/parky/attempts.json") == 0 && $(grep -c "^B attempt" "$T/scratch/proj/parky/sessions.log") == 1 ]]'
check "independent work goes on past a parked feature" 'grep -q "^C attempt" "$T/scratch/proj/parky/sessions.log"'
check "ends waiting on Michael; the summary says so" 'grep -q "^waiting on Michael: B" "$HARNESS_STATE/proj/parky/ended" && [[ $(jq -r .end_reason "$S16") == "waiting on Michael: B" && $(jq -r ".features_detail[1].cause" "$S16") == "waiting on Michael" ]]'
# two short parks without DESK_URL (A parks; B and C wait on it): one with the GitHub origin, one with a local origin
# whose posts fail (both runs stay behind, ended waiting on Michael)
cp "$T/base-config.sh" "$T/user-config.sh"
SPY='printf "%s · %s\n" "$(printf "%s\n" "$@" | sed -n "s/^Title: //p")" "$(git -C "$STUB_DIR/origin.git" log -1 --format=%s harness/parkn)" >> "$STUB_DIR/spy.log"'
STUB_CURL_SPY=$SPY STUB_PARK=A STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_LENIENT=1 "$H" start "$T/proj" parkn --spec SPEC.md --foreground > "$T/run16n.out" 2>&1
git -C "$T/proj" config remote.origin.url "$T/origin.git"
STUB_CURL_FAIL=1 STUB_PARK=A STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_LENIENT=1 "$H" start "$T/proj" parkl --spec SPEC.md --foreground > "$T/run16l.out" 2>&1
git -C "$T/proj" config remote.origin.url git@github.com:test/proj.git
{ cat "$T/base-config.sh"; echo 'DESK_URL=https://claude.ai/code/env-test'; } > "$T/user-config.sh"
B16=$(curl_with "Title: [parky] B needs you"); BB16=$(curl_body "Title: [parky] B needs you")
check "a park notification: title, question, answer command, click and Edit INBOX action" 'grep -qx "Priority: high" <<< "$B16" && grep -qx "Tags: question" <<< "$B16" \
  && grep -qx "Click: $GHP/blob/harness/parky/.harness/runs/parky/INBOX.md" <<< "$B16" && grep "^Actions: " <<< "$B16" | grep -qF "view, Edit INBOX, $GHP/edit/harness/parky/.harness/runs/parky/INBOX.md" \
  && grep "^Actions: " <<< "$B16" | grep -qF "view, Progress, $GHP/blob/harness/parky/.harness/runs/parky/progress.md" \
  && grep -qx "PARKED: set the gatus vars" <<< "$BB16" && grep -qx "### B: set the gatus vars, then answer" <<< "$BB16" && grep -q "^Answer: harness answer parky \"" <<< "$BB16" \
  && grep -q "notified: \[parky\] B needs you" "$HARNESS_STATE/proj/parky/run.log"'
check "Answer with Claude only when DESK_URL is set" 'grep "^Actions: " <<< "$B16" | grep -qF "view, Answer with Claude, https://claude.ai/code/env-test" \
  && grep -q "^Actions: .*Edit INBOX" <<< "$(curl_with "Title: [parkn] A needs you")" && ! grep -q "Answer with Claude" <<< "$(curl_with "Title: [parkn] A needs you")"'
check "the park goes out after the run branch is pushed (the link shows the question)" 'grep -qx "\[parkn\] A needs you · HARNESS: after A (passes=false)" "$T/spy.log"'
check "the run end goes out before the retro, once report.md is pushed" 'grep -qxF "[parkn] ended: waiting on Michael: A · HARNESS: run ended (waiting on Michael: A)" "$T/spy.log" \
  && git -C "$T/origin.git" cat-file -e "$(git -C "$T/origin.git" log -1 --format=%H --grep="^HARNESS: run ended" harness/parkn):.harness/runs/parkn/report.md" \
  && awk "/notified: \[parky\] ended:/ { n = NR } /retro · / && !r { r = NR } END { exit !(n && r && n < r) }" "$HARNESS_STATE/proj/parky/run.log"'
check "a failed park post is noted and committed at once" 'hlog parkl | grep -q "notification failed (curl exit 22): \[parkl\] A needs you" && git -C "$T/origin.git" log --format=%s harness/parkl | grep -x "HARNESS: park notification failed" > /dev/null'
check "no URLs for a non-GitHub origin" 'Bl=$(curl_with "Title: [parkl] A needs you"); grep -qx "Priority: high" <<< "$Bl" && grep -q "^Answer: harness answer parkl \"" <<< "$(curl_body "Title: [parkl] A needs you")" \
  && ! grep -q "^Click: " <<< "$Bl" && ! grep -q "^Actions: " <<< "$Bl" && ! grep -q "https://github.com" <<< "$Bl"'
check "a waiting-on-Michael run end: priority high, click = report.md" 'Be=$(curl_with "[parky] ended (waiting on Michael: B)"); grep -qx "Title: \[parky\] ended: waiting on Michael: B" <<< "$Be" \
  && grep -qx "Priority: high" <<< "$Be" && grep -qx "Click: $GHP/blob/harness/parky/.harness/runs/parky/report.md" <<< "$Be" \
  && grep "^Actions: " <<< "$Be" | grep -qF "view, Edit INBOX, $GHP/edit/harness/parky/.harness/runs/parky/INBOX.md"'
check "one notification per run end" '[[ $(curl_count "[parky] ended (") == 1 && $(curl_count "needs Michael: waiting on Michael") == 0 && $(curl_count "needs Michael: blocked on") == 0 ]] \
  && ! grep -q "Priority:" <<< "$(curl_with "[demo] ended (done)")" && grep -q "^Click: .*/demo/report.md" <<< "$(curl_with "[demo] ended (done)")"'
# harness parked: parky, parkn and parkl are all parked and ended; no queue runner
touch "$T/parked.stamp"; "$H" parked > "$T/parked.out" 2>&1; "$H" parked parky --json > "$T/parked.json" 2>&1
check "harness parked: id, why, question, both commands" 'P=$(cat "$T/parked.out"); [[ $P == *"parky · proj · B"* && $P == *"why:      set the gatus vars"* && $P == *"question: ### B: set the gatus vars, then answer"* \
  && $P == *"harness answer parky \"…\""* && $P == *"harness continue parky"* && $P == *"parkn · proj · A"* && $P == *"parkl · proj · A"* ]]'
check "harness parked is read-only" '[[ -z $(find "$HARNESS_STATE" "$T/wt/proj/parky" -newer "$T/parked.stamp") && -z $(git -C "$T/wt/proj/parky" status --porcelain) ]]'
check "harness parked --json parses" 'jq -e ".[0].feature == \"B\" and .[0].running == false and (.[0].commands | length) == 2" "$T/parked.json" > /dev/null'
RP=$HARNESS_STATE/queue/runner.pid; mkdir -p "$HARNESS_STATE/queue"; [[ -f $RP ]] && mv "$RP" "$RP.keep"; echo $$ > "$RP"
check "with a queue runner going, the continue command is a queue add" 'P=$("$H" parked parky); [[ $P == *"harness queue add --continue parky"* && $P != *"harness continue parky"* ]]'
rm -f "$RP"; [[ -f $RP.keep ]] && mv "$RP.keep" "$RP"
# parky's driver still alive (our pid): wrapping up after "ended" (finish: merge, suite, retro), then mid-run
DP=$HARNESS_STATE/proj/parky/driver.pid; echo $$ > "$DP"
check "a run still ending: answer now, continue once it has ended" 'P=$("$H" parked parky); [[ $P == *"running:  ending"* && $P == *"harness continue parky"* ]] \
  && "$H" parked parky --json | jq -e ".[0].running == false and .[0].ending == true and (.[0].commands | length) == 2" > /dev/null'
mv "$HARNESS_STATE/proj/parky/ended" "$T/parky.ended"
check "a run still going: only the answer command" 'P=$("$H" parked parky); [[ $P == *"running:  yes"* && $P == *"harness answer parky"* && $P != *"continue parky"* ]]'
mv "$T/parky.ended" "$HARNESS_STATE/proj/parky/ended"; rm -f "$DP"
check "harness parked: an unknown or glob run id is an error" '! "$H" parked nosuch 2> /dev/null && ! "$H" parked "parky*" > /dev/null 2>&1 \
  && ! "$H" answer "park*" "a glob answers no run" > /dev/null 2>&1 && ! grep -rqs "a glob answers" "$HARNESS_STATE"/proj/park*/inbox.md'
# a session-cap end queues its own continuation (finish): a second one would restart the run twice
touch "$HARNESS_STATE/queue/9999-continue-parky.args"
check "a queued continuation: only the answer command" 'P=$("$H" parked parky); [[ $P == *"continuation queued"* && $P == *"harness answer parky"* && $P != *"continue parky"* ]] \
  && "$H" parked parky --json | jq -e ".[0].queued == true and (.[0].commands | length) == 1" > /dev/null'
rm -f "$HARNESS_STATE/queue/9999-continue-parky.args"
# demo's worktree is gc'd: a parked.json left in its state dir names nothing that can be answered or continued
echo '{"Z":{"answers":"x","why":"stale","at":"2026-10-19T01:00:00.000Z"}}' > "$HARNESS_STATE/proj/demo/parked.json"
check "nothing parked"                    '[[ $("$H" parked demo) == "nothing parked in demo" ]] && ! "$H" parked | grep -q "^demo "'
check "the answer skill exists and names the commands and the never-list" 'S=$HH/skills/harness-answer/SKILL.md; [[ $(head -1 "$S") == --- ]] && grep -q "^name: harness-answer$" "$S" && grep -q "harness parked" "$S" && grep -q "harness answer" "$S" && grep -qi "never edit INBOX.md" "$S" && grep -q sudo "$S"'
check "the answer skill passes Michael's words through a quoted heredoc" 'S=$HH/skills/harness-answer/SKILL.md; grep -qF "\"\$(cat <<'"'"'HARNESS_ANSWER_END'"'"'" "$S" && grep -qi "never let his words reach the shell" "$S"'
check "the user config template sets nothing" 'bash -n "$HH/templates/user/config.sh" && ( unset NTFY_URL NTFY_TOKEN DESK_URL NOTIFY_CMD; source "$HH/templates/user/config.sh"; [[ -z ${NTFY_URL:-}${NTFY_TOKEN:-}${DESK_URL:-}${NOTIFY_CMD:-} ]] )'
rm -f "$HARNESS_STATE/proj/demo/parked.json"
"$H" answer parky "gatus vars set" > /dev/null
STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_LENIENT=1 "$H" continue parky --keep-attempts --foreground > "$T/run16b.out" 2>&1
check "an INBOX answer unparks it; the run finishes" 'hlog parky | grep -q "B unparked" && [[ $($F summary "$(list parky)") == "3/3 passing" ]]'

# ---- the desk: a Remote Control claude in a tmux window briefs Michael (stub claude's interactive mode, private server) ----
cp "$T/base-config.sh" "$T/user-config.sh"   # NTFY_URL: the checks read curl.log
# every run so far (parky parked and ended, strict and later needed Michael) had the default DESK=0
check "DESK=0: no desk" '[[ -z $(compgen -G "$HARNESS_STATE/*/*/desk") && -z $(wins) && ! -e $T/desk/count ]] && ! grep -rqs "desk started\|desk: " "$T"/wt/proj/*/.harness/runs/*/harness-log.md'
SU=$T/stubunit; mkdir -p "$SU"   # its own counter: the suite's first desk stays session_TEST1
BIG=$(printf '# Retro\n%0122880d' 0)   # > the 64 KB pipe buffer, < the 128 KB argument limit
check "the stub claude's interactive mode prints the pane line and records input" 'O=$(printf "hello\n" | STUB_DIR=$SU "$HERE/stub-claude.sh" --remote-control "desk · u · x" --model m) \
  && [[ $O == "/remote-control is active · Continue here, on your phone, or at https://claude.ai/code/session_TEST1" && $(cat "$SU/desk/1-desk_u_x.in") == hello ]] \
  && grep -qx -- --remote-control "$SU/desk/1-desk_u_x.args" && [[ $(tail -1 "$SU/desk/1-desk_u_x.args") == "PWD=$PWD" ]] \
  && [[ -z $(STUB_DESK_NO_URL=1 STUB_DIR=$SU "$HERE/stub-claude.sh" --remote-control "desk · v" < /dev/null) && $(cat "$SU/desk/count") == 2 ]] \
  && STUB_DIR=$SU HARNESS_SCRATCH=$SU "$HERE/stub-claude.sh" -p "$BIG" --model m < /dev/null | grep -q "Stub retro" && [[ $(cat "$SU/desk/count") == 2 ]]'
check "DESK=0 by default, DESK_MODEL=opus" '( source "$HH/lib/config.sh"; harness_config /nonexistent; [[ $DESK == 0 && $DESK_MODEL == opus ]] )'
"$H" desk parky --why "B parked: set the gatus vars" > "$T/desk1.out" 2> "$T/desk1.err"; D1=$?
DS=$HARNESS_STATE/proj/parky/desk; DP1=$(ls "$DS"/*.md 2> /dev/null | head -1)
check "harness desk: one window, the Read line, the prompt, the notification click" '[[ $D1 == 0 && $(cat "$T/desk1.out") == https://claude.ai/code/session_TEST1 && $(wins) == parky && -n $DP1 ]] \
  && in_has "$(desk_of parky | sed "s/\.args$/.in/")" "Read" && [[ $(cat "$(desk_of parky | sed "s/\.args$/.in/")") == "Read $DP1 and follow it." ]] \
  && grep -q parky "$DP1" && grep -qF "$T/wt/proj/parky/.harness/runs/parky/INBOX.md" "$DP1" && grep -q "harness answer parky" "$DP1" \
  && [[ $(cat "$DS/url") == https://claude.ai/code/session_TEST1 && $DP1 == "$DS"/[0-9]*-[0-9]*.md ]]'
check "the desk notification" 'Bd=$(curl_last "Title: [parky] needs you"); grep -qx "Title: \[parky\] needs you: B parked: set the gatus vars" <<< "$Bd" \
  && grep -qx "Priority: high" <<< "$Bd" && grep -qx "Click: https://claude.ai/code/session_TEST1" <<< "$Bd" && ! grep -q tok-secret "$DP1"'
check "the desk's claude: --remote-control, the model id, --add-dir the worktree, in the project directory" 'A=$(desk_of parky); [[ -n $A ]] && grep -qx -- --remote-control "$A" \
  && grep -qx "desk · parky · B parked: set the gatus vars" "$A" && grep -qx -- --model "$A" && grep -qx "$($F model opus)" "$A" && grep -qx -- --add-dir "$A" \
  && grep -qx "$T/wt/proj/parky" "$A" && [[ $(tail -1 "$A") == "PWD=$T/proj" ]]'
check "the desk prompt names the run, its commands and the never-list" '( for k in "harness parked parky" "harness status parky" progress.md "by name only" .env sudo "1 yes" "harness answer parky" \
  "harness queue add --continue parky" CLAUDE.md; do grep -qF -- "$k" "$DP1" || exit 1; done ) && grep -qi "never edit INBOX.md" "$DP1" && ! grep -qF "{{" "$DP1" && ! grep -qF "<!--" "$DP1" && ! grep -q "Needs Michael" "$DP1"'
check "harness desk notes 'desk started:' in the run record" 'hlog parky | grep -qF "desk started: https://claude.ai/code/session_TEST1 (B parked: set the gatus vars)" && [[ -z $(git -C "$T/wt/proj/parky" status --porcelain) ]]'
"$H" desk parky --why "C parked: db url" > "$T/desk2.out" 2> "$T/desk2.err"; D2=$?
DP2=$(ls -t "$DS"/*.md 2> /dev/null | head -1)
check "a second event reuses the desk window" 'I=$(desk_of parky | sed "s/\.args$/.in/"); [[ $D2 == 0 && $(cat "$T/desk2.out") == https://claude.ai/code/session_TEST1 && $(wins) == parky && $DP2 != "$DP1" ]] \
  && in_has "$I" "New since" && [[ $(tail -1 "$I") == "New since your last brief: C parked: db url. Re-read $DP2." && $(head -1 "$I") == "Read $DP1 and follow it." ]] \
  && Bd=$(curl_last "Title: [parky] needs you") && grep -qx "Title: \[parky\] needs you: C parked: db url" <<< "$Bd" && grep -qx "Click: https://claude.ai/code/session_TEST1" <<< "$Bd" \
  && hlog parky | grep -qF "desk: sent to the open desk: https://claude.ai/code/session_TEST1 (C parked: db url)" && [[ $(hlog parky | grep -c "desk started:") == 1 && -z $(git -C "$T/wt/proj/parky" status --porcelain) ]]'
STUB_DESK_NO_URL=1 HARNESS_DESK_WAIT=2 "$H" desk stoppy --why "x" > "$T/desk3.out" 2> "$T/desk3.err"; D3=$?
check "no URL in time: no window, the plain notification" '[[ $D3 == 0 && ! -s $T/desk3.out && -z $(win stoppy) ]] && grep -q "no session URL" "$T/desk3.err" \
  && hlog stoppy | grep -qF "desk: no session URL within 2 s; killed the window; plain notification" && [[ ! -s $HARNESS_STATE/proj/stoppy/desk/url ]] \
  && Bn=$(curl_last "Title: [stoppy] needs you") && grep -qx "Title: \[stoppy\] needs you: x" <<< "$Bn" && grep -qx "Priority: high" <<< "$Bn" && ! grep -q "Click: https://claude.ai" <<< "$Bn" \
  && ! grep -q "Open the desk" <<< "$Bn" && grep -qx "Or by hand: harness parked stoppy" <<< "$Bn" && grep -q "; notified)$" "$T/desk3.err" \
  && [[ -z $(git -C "$T/wt/proj/stoppy" status --porcelain -- .harness/runs/stoppy/harness-log.md) ]]'   # committed (the debrief checks planted the INBOX and report edits)
W=$(win parky); [[ -n $W ]] && tmux kill-window -t "$W"   # the session goes with its last window (an empty -t would hit the current window)
"$H" desk parky --why "again" > "$T/desk4.out" 2> "$T/desk4.err"; D4=$?
check "a dead desk is replaced" 'I=$(desk_of parky | sed "s/\.args$/.in/"); [[ $D4 == 0 && $(cat "$T/desk4.out") == https://claude.ai/code/session_TEST3 && $(wins | grep -cx parky) == 1 && $I == */3-desk_parky_again.in ]] \
  && in_has "$I" "Read" && [[ $(head -1 "$I") == "Read "*" and follow it." ]] && ! grep -q "New since" "$I" && [[ $(cat "$DS/url") == https://claude.ai/code/session_TEST3 ]]'
"$H" desk --debrief > "$T/desk5.out" 2> "$T/desk5.err"; D5=$?
QP=$(ls -t "$HARNESS_STATE"/queue/desk/*.md 2> /dev/null | head -1)
check "harness desk --debrief" 'A=$(desk_of debrief); [[ $D5 == 0 && $(cat "$T/desk5.out") == https://claude.ai/code/session_TEST4 && -n $(win debrief) && -n $QP && -n $A ]] \
  && grep -qF "ledger/debrief.md" "$QP" && grep -q "Needs Michael" "$QP" && ! grep -qF "{{" "$QP" && ! grep -qF "<!--" "$QP" && ! grep -q "harness parked parky" "$QP" \
  && in_has "${A%.args}.in" "Read" && [[ $(cat "${A%.args}.in") == "Read $QP and follow it." && $(tail -1 "$A") == "PWD=$HH" ]] && grep -qx "$T/wt" "$A" && grep -qx "$T/ledger" "$A" \
  && grep -qx "Title: \[debrief\] needs you" <<< "$(curl_last "Title: [debrief]")" && grep -qx "Click: https://claude.ai/code/session_TEST4" <<< "$(curl_last "Title: [debrief]")" \
  && grep -qF "desk started: https://claude.ai/code/session_TEST4" "$HARNESS_STATE/queue/runner.log"'
W0=$(wins | sort)
rc() { "$@" > /dev/null 2>&1; echo $?; }
check "harness desk: an unknown run or a bad option is an error, nothing started" '[[ $(rc "$H" desk nosuch) == 1 && $(rc "$H" desk "park*") == 1 && $(rc "$H" desk debrief) == 1 && $(rc "$H" desk desk) == 1 ]] \
  && [[ $(rc "$H" desk parky --nope) == 2 && $(rc "$H" desk --debrief parky) == 2 && $(rc "$H" start "$T/proj" desk --spec SPEC.md) == 1 ]] \
  && [[ ! -d $HARNESS_STATE/proj/nosuch && ! -d $HARNESS_STATE/proj/desk && ! -d $T/wt/proj/desk && $(wins | sort) == "$W0" ]]'
W=$(win parky); [[ -n $W ]] && tmux kill-window -t "$W"; tmux new-window -d -t "=$HARNESS_DESK_SESSION:" -n parky sleep 600; rm -f "$DS/url"   # a window of that name that is no desk
"$H" desk parky --why "stale" > "$T/desk6.out" 2> /dev/null; D6=$?
check "a window of the run's name that never showed a URL is replaced" '[[ $D6 == 0 && $(cat "$T/desk6.out") == https://claude.ai/code/session_TEST5 && $(wins | grep -cx parky) == 1 ]] \
  && in_has "$(desk_of parky | sed "s/\.args$/.in/")" "Read" && ! tmux list-panes -a -F "#{pane_start_command}" | grep -q "sleep 600"'
# DESK=1: the driver and the debrief start desks themselves (a park, a run end needing Michael, verify, the debrief)
{ cat "$T/base-config.sh"; echo 'DESK=1'; } > "$T/user-config.sh"
STUB_PARK=B STUB_INDEPENDENT_M2=1 STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_LENIENT=1 "$H" start "$T/proj" desky --spec SPEC.md --foreground > "$T/run18.out" 2>&1
check "DESK=1: a park starts one desk, the run end reuses it" 'I=$(desk_of desky | sed "s/\.args$/.in/"); grep -q "^waiting on Michael: B" "$HARNESS_STATE/proj/desky/ended" && [[ $(wins | grep -cx desky) == 1 ]] \
  && in_has "$I" "New since" && [[ $(sed -n 1p "$I") == "Read $HARNESS_STATE/proj/desky/desk/"*".md and follow it." ]] \
  && [[ $(sed -n 2p "$I") == "New since your last brief: ended: waiting on Michael: B. Re-read $HARNESS_STATE/proj/desky/desk/"*.md. && $(wc -l < "$I") == 2 ]] \
  && [[ $(hlog desky | grep -c "desk started:") == 1 ]] && hlog desky | grep -qF "(B parked: set the gatus vars)" && hlog desky | grep -q "desk: sent to the open desk: .* (ended: waiting on Michael: B)" \
  && [[ -n $(curl_with "Title: [desky] B needs you") && -n $(curl_with "Title: [desky] needs you: B parked: set the gatus vars") && -z $(git -C "$T/wt/proj/desky" status --porcelain) ]]'
STUB_DESK_NO_URL=1 HARNESS_DESK_WAIT=2 STUB_PARK=B STUB_INDEPENDENT_M2=1 STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_LENIENT=1 "$H" start "$T/proj" deskno --spec SPEC.md --foreground > "$T/run19.out" 2>&1
check "a desk that cannot start never changes the run" 'grep -q "^waiting on Michael: B" "$HARNESS_STATE/proj/deskno/ended" && [[ -n $(curl_with "Title: [deskno] B needs you") && -z $(win deskno) ]] \
  && [[ $(hlog deskno | grep -c "desk: no session URL within 2 s; killed the window; plain notification") == 2 ]] && ! hlog deskno | grep -q "desk: could not start" \
  && [[ $($F summary "$(list deskno)") == "2/3 passing" && -z $(git -C "$T/wt/proj/deskno" status --porcelain) ]]'
STUB_STRICT_VERIFIER=1 STUB_INDEPENDENT_M2=1 "$H" continue strict --foreground > "$T/run3b.out" 2>&1   # clears needs-M1: M1 fails its re-checks again
check "verify needs Michael starts a desk" 'I=$(desk_of strict | sed "s/\.args$/.in/"); [[ -n $(win strict) ]] && in_has "$I" "Read" && P=$(sed -n "1s/^Read \(.*\) and follow it\.$/\1/p" "$I") \
  && [[ $P == "$HARNESS_STATE/proj/strict/desk/"*.md ]] && grep -q "M1 needs Michael: A fails verification" "$P" && hlog strict | grep -q "desk started: .* (M1 needs Michael: A fails verification)"'
W=$(win debrief); [[ -n $W ]] && tmux kill-window -t "$W"   # the by-hand one above (an empty -t would hit the current window)
ran stoppy; "$H" debrief > "$T/ddesk1.out" 2>&1; DW1=$(win debrief)
ran stoppy; STUB_DEBRIEF_NEEDS=1 "$H" debrief > "$T/ddesk2.out" 2>&1
check "the debrief starts a desk when Needs Michael is non-empty" '[[ -z $DW1 && -n $(win debrief) ]] && grep -q "debrief written" "$T/ddesk1.out" && grep -q "debrief written" "$T/ddesk2.out" \
  && [[ $(grep -c "desk started: .*session_TEST" "$HARNESS_STATE/queue/runner.log") == 2 ]]'
# housekeeping: list, close, gc's 24 h rule, close them all (open now: parky, desky, strict, debrief)
tmux new-window -d -t "=$HARNESS_DESK_SESSION:" -n odd sleep 600   # a window that is no desk
"$H" desk --list > "$T/dlist.out" 2>&1; DL=$?
check "harness desk --list" '"$H" help | grep -qF -- "harness desk --list | --close <run>|--all" && [[ $DL == 0 && $(wins | wc -l) == 5 && $(wc -l < "$T/dlist.out") == 5 ]] && grep -qE "^parky +parky +$(cat "$DS/url") +[0-9]+ min$" "$T/dlist.out" \
  && ( for w in desky strict; do grep -qE "^$w +$w +https://claude\.ai/code/session_TEST[0-9]+ +[0-9]+ min$" "$T/dlist.out" || exit 1; done ) \
  && grep -qE "^debrief +\(debrief\) +https://claude\.ai/code/session_TEST[0-9]+ +[0-9]+ min$" "$T/dlist.out" && grep -qE "^odd +- +- +-$" "$T/dlist.out"'
"$H" desk --close desky > "$T/dclose1.out" 2>&1; DC1=$?; "$H" desk --close parkn > "$T/dclose2.out" 2>&1; DC2=$?
check "harness desk --close <run>" '[[ $DC1 == 0 && $(cat "$T/dclose1.out") == "closed desk desky" && -z $(win desky) && ! -e $HARNESS_STATE/proj/desky/desk/url ]] \
  && [[ $DC2 == 0 && $(cat "$T/dclose2.out") == "no desk for parkn" && $(rc "$H" desk --close) == 2 && $(wins | wc -l) == 4 ]]'
ago() { echo $(( $(date +%s) - $1 * 3600 )); }   # an epoch <n> hours ago
ago 25 > "$HARNESS_STATE/proj/strict/desk/last-event"; ago 23 > "$DS/last-event"; ago 25 > "$HARNESS_STATE/proj/stoppy/desk/last-event"   # stoppy: idle, no window
"$H" gc "$T/proj" --dry-run > "$T/dgc1.out" 2>&1; DG1=$(win strict)
"$H" gc "$T/proj" > "$T/dgc2.out" 2>&1; DG2=$?
check "harness gc closes idle desks" '[[ -n $DG1 && $DG2 == 0 && -z $(win strict) && -n $(win parky) && -n $(win debrief) ]] && grep -qx "would close idle desk strict" "$T/dgc1.out" \
  && grep -qx "closed idle desk strict" "$T/dgc2.out" && [[ $(grep -c "idle desk" "$T/dgc2.out") == 1 && ! -e $HARNESS_STATE/proj/strict/desk/url ]] && grep -q "desk: closed" "$HARNESS_STATE/proj/strict/run.log"'
check "harness gc keeps the worktree of a run whose desk is open" '[[ -d $T/wt/proj/parky ]] && grep -qx "keeps $T/wt/proj/parky: its desk is open (harness desk --close parky)" "$T/dgc2.out"'
"$H" desk --all > "$T/dall1.out" 2>&1; DA1=$?; "$H" desk --all > "$T/dall2.out" 2>&1; DA2=$?
check "harness desk --all" '[[ $DA1 == 0 && $(cat "$T/dall1.out") == "closed every desk (3)" ]] && ! tmux has-session -t "=$HARNESS_DESK_SESSION" 2> /dev/null \
  && [[ -z $(compgen -G "$HARNESS_STATE/*/*/desk/url") && ! -e $HARNESS_STATE/queue/desk/url && $DA2 == 0 && $(cat "$T/dall2.out") == "no desks" && $("$H" desk --list) == "no desks" ]] && grep -q "desk: closed every desk (3" "$HARNESS_STATE/queue/runner.log"'
# review (P3-06): an open desk showing a dialog gets nothing typed; the token never reaches a desk; a refused merge
# tells Michael (and his desk) once, and `harness merge` starts no desk
NTFY_TOKEN=tok-env-456 STUB_DESK_MENU=1 "$H" desk parky --why "menu one" > "$T/dmenu1.out" 2>&1
IM=$(desk_of parky | sed 's/\.args$/.in/'); in_has "$IM" Read; sleep 1   # the stub draws its dialog after the Read line
STUB_DESK_MENU=1 "$H" desk parky --why "menu two" > "$T/dmenu2.out" 2> "$T/dmenu2.err"; DM=$?; sleep 1
check "an open desk showing a dialog gets nothing typed" '[[ $DM == 0 && -n $(cat "$T/dmenu1.out") && $(cat "$T/dmenu2.out") == "$(cat "$T/dmenu1.out")" && $(wc -l < "$IM") == 1 ]] \
  && hlog parky | grep -qF "desk: the open desk shows a dialog; nothing typed (menu two)" && Bm=$(curl_last "Title: [parky] needs you: menu two") \
  && grep -qx "Click: $(cat "$T/dmenu1.out")" <<< "$Bm" && grep -q "answer its dialog" <<< "$Bm" && [[ $(wins | grep -cx parky) == 1 ]]'
check "the desk's environment has no NTFY_TOKEN" 'E=$(desk_of parky | sed "s/\.args$/.env/"); [[ -s $E ]] && grep -qx HARNESS_STATE "$E" && ! grep -qx NTFY_TOKEN "$E" \
  && ! tmux show-environment -g 2> /dev/null | grep -q tok-env'
"$H" desk --all > /dev/null
STUB_REFUSE_MERGE=1 STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_LENIENT=1 "$H" start "$T/proj" refusy --spec SPEC.md --foreground > "$T/run20.out" 2>&1
check "a refused merge tells Michael and his desk once" '[[ $(hlog refusy | grep -c "merge was refused") == 1 && $(curl_count "Title: [refusy] M1 needs you") == 1 ]] \
  && [[ $(hlog refusy | grep -c "M1: merge refused") == 1 && $(wins | grep -cx refusy) == 1 ]] && hlog refusy | grep -q "desk started: .* (M1: merge refused)"'
"$H" desk --close refusy > /dev/null
STUB_REFUSE_MERGE=1 "$H" merge refusy > "$T/run20b.out" 2>&1   # Michael retries at the terminal: still refused
check "harness merge says it was refused again, and starts no desk" '[[ $(hlog refusy | grep -c "merge was refused") == 2 && $(curl_count "Title: [refusy] M1 needs you") == 2 ]] \
  && [[ -z $(win refusy) && $(hlog refusy | grep -c "desk started:") == 1 ]]'
check "the dialog guard: the CLI's dialog words, not the desk's own questions" 'DG=$(sed -n "s/^DIALOG=\x27\(.*\)\x27$/\1/p" "$HH/lib/desk.sh"); [[ -n $DG ]] \
  && sed 1d "$HERE/fixtures/permission-menu.txt" | grep -qE "$DG" && ! printf "%s\n" "Do you want to merge M1 now?" "1. yes  2. no" "Enter the value" | grep -qE "$DG"'
"$H" desk --all > /dev/null
echo 'KEEP_SCRATCH=1 LEDGER_COMMIT=0 MAX_PARALLEL_RUNS=1' > "$T/user-config.sh"

suite_end
