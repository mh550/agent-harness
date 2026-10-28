#!/usr/bin/env bash
source "$(dirname "$0")/../lib.sh" && suite_setup
# ---- the record PR (P2-05): finish's last step puts harness/<run> on main through its own PR; gc deletes it later ----
# The suite's base config sets RECORD_PR=off (every other file's runs open none); this file turns it on per run. Each
# run gets its own gh.log (moved aside after it), so a count is that run's.
prs_of() { local f; for f in "$T"/prs/pr-*; do [[ ${f##*/} =~ ^pr-[0-9]+$ && $(cat "$f") == "$1" ]] && echo "${f##*-}"; done; }   # <head> → its PRs' numbers
has() { git -C "$1" rev-parse -q --verify "refs/heads/$2" > /dev/null; }   # <repo> <branch>
main0=$(git -C "$T/origin.git" rev-parse main)

# ra: auto. Both milestones merge through their own PRs, then the record PR is opened and merged
echo 'RECORD_PR=end' >> "$T/user-config.sh"
STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_LENIENT=1 "$H" start "$T/proj" ra --spec SPEC.md --foreground > "$T/ra.out" 2>&1
mv "$T/gh.log" "$T/gh-ra.log"
ra_n=$(prs_of harness/ra) ra_m=$(git -C "$T/origin.git" log --format=%H -1 --grep="^Merge pull request #$ra_n\$" main)
check "record PR: under auto finish opens <run>: run record from harness/<run> against main, its body the report, and merges it" \
  'grep -q "^done" "$HARNESS_STATE/proj/ra/ended" && [[ -n $ra_n && -f $T/prs/pr-$ra_n.merged && $(cat "$T/prs/pr-$ra_n.title") == "ra: run record" ]] \
  && grep -qx "gh pr create --base main --head harness/ra --title ra: run record --body-file $T/wt/proj/ra/.harness/runs/ra/report.md" "$T/gh-ra.log" \
  && [[ $(grep -c "pr merge" "$T/gh-ra.log") == 3 ]] && hlog ra | grep -F "· record PR merged into main · https://example.test/pr/$ra_n" > /dev/null'
check "record PR: its merge brings only .harness/runs/<run>/ paths onto main (the record branch is record-only)" \
  '[[ -n $ra_m ]] && git -C "$T/origin.git" diff --name-only "$ra_m^1" "$ra_m" > "$T/ra-diff.txt" && [[ -s $T/ra-diff.txt ]] \
  && ! grep -v "^\.harness/runs/ra/" "$T/ra-diff.txt" > /dev/null && grep -qx ".harness/runs/ra/entries.jsonl" "$T/ra-diff.txt"'
check "record PR: finish deletes nothing: harness/ra is still here and on origin (its last commit pushed), so a harness continue the same night finds it" \
  'has "$T/origin.git" harness/ra && has "$T/proj" harness/ra && [[ -d $T/wt/proj/ra ]] && ! grep -F -- "--delete-branch" "$T/gh-ra.log" > /dev/null \
  && [[ $(git -C "$T/origin.git" rev-parse harness/ra) == "$(git -C "$T/wt/proj/ra" rev-parse HEAD)" ]]'
# a continue right after: main now has the record; the segment ends done again and its record PR is a new one, merged
"$H" continue ra --foreground > "$T/ra-continue.out" 2>&1
mv "$T/gh.log" "$T/gh-ra2.log"
ra2=$(prs_of harness/ra | tail -1)
check "record PR: a harness continue after the merged record PR runs on main with the record, ends done and opens and merges a second one" \
  '[[ $(grep -c " run ra on harness/ra " "$HARNESS_STATE/proj/ra/run.log") == 2 ]] && grep -q "^done" "$HARNESS_STATE/proj/ra/ended" \
  && [[ -n $ra2 && $ra2 != "$ra_n" && -f $T/prs/pr-$ra2.merged ]] && hlog ra | grep -F "· record PR merged into main · https://example.test/pr/$ra2" > /dev/null'
"$H" gc "$T/proj" --all-merged --deps > "$T/gc-ra.out" 2>&1
check "record PR: the end-of-queue gc --all-merged --deps then removes the merged run's record worktree and deletes harness/ra here and on origin; the ledger keeps the record" \
  '[[ ! -e $T/wt/proj/ra ]] && ! has "$T/proj" harness/ra && ! has "$T/origin.git" harness/ra \
  && grep -F "push -q origin --delete harness/ra" "$T/gc-ra.out" > /dev/null \
  && [[ -s $T/ledger/proj/ra/entries.jsonl && -s $T/ledger/proj/ra/summary.json ]] && grep "\"run\":\"ra\"" "$T/ledger/runs.jsonl" > /dev/null \
  && cmp -s <(git -C "$T/origin.git" show main:.harness/runs/ra/entries.jsonl) "$T/ledger/proj/ra/entries.jsonl"'

# from here each run starts from the first main (the stub's work files would otherwise already be there: A's commit empty)
git -C "$T/origin.git" update-ref refs/heads/main "$main0"

# rq: pr. Nothing merges; the record PR is opened and left. harness merge lands the milestones and keeps it open;
# a harness continue then finishes again and reuses the open PR
echo 'MERGE_POLICY=pr' >> "$T/user-config.sh"
STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_LENIENT=1 "$H" start "$T/proj" rq --spec SPEC.md --foreground > "$T/rq.out" 2>&1
rq_n=$(prs_of harness/rq)
check "record PR: under pr it is opened and left for Michael, noted" \
  '[[ -n $rq_n && ! -f $T/prs/pr-$rq_n.merged && ! -f $T/prs/pr-$rq_n.closed ]] && grep -x "gh pr create --base main --head harness/rq --title rq: run record .*" "$T/gh.log" > /dev/null \
  && ! grep "pr merge https://example.test/pr/$rq_n " "$T/gh.log" > /dev/null \
  && hlog rq | grep -F "· record PR opened; left for Michael (MERGE_POLICY=pr) · https://example.test/pr/$rq_n" > /dev/null'
"$H" merge rq > "$T/rq-merge.out" 2>&1
check "record PR: harness merge's v2 closer leaves the record PR open (it closes only a PR not titled <run>: run record)" \
  'on_main run/rq/M1 && on_main run/rq/M2 && [[ ! -f $T/prs/pr-$rq_n.closed ]] && ! grep "pr close" "$T/gh.log" > /dev/null \
  && ! hlog rq | grep -F "closed the whole-run PR" > /dev/null'
"$H" continue rq --foreground > "$T/rq-continue.out" 2>&1
mv "$T/gh.log" "$T/gh-rq.log"
check "record PR: a harness continue after finish ends again and reuses the open record PR (one pr create for it), its body refreshed" \
  '[[ $(grep -c " run rq on harness/rq " "$HARNESS_STATE/proj/rq/run.log") == 3 && $(grep -c -- "--title rq: run record" "$T/gh-rq.log") == 1 ]] \
  && grep -qx "gh pr edit https://example.test/pr/$rq_n --body-file $T/wt/proj/rq/.harness/runs/rq/report.md" "$T/gh-rq.log" \
  && [[ $(hlog rq | grep -cF "· record PR opened; left for Michael (MERGE_POLICY=pr) · https://example.test/pr/$rq_n") == 2 ]]'
git -C "$T/origin.git" update-ref refs/heads/main "$main0"

# rb: a --base run under pr (its milestones proposed, not merged): harness/rb carries based.txt, which main lacks, so
# no record PR may carry it there
git -C "$T/proj" checkout -q -b based && echo based > based.txt && git add based.txt && git commit -qm based && git push -q origin based && git checkout -q main
STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_LENIENT=1 "$H" start "$T/proj" rb --spec SPEC.md --base origin/based --foreground > "$T/rb.out" 2>&1
check "record PR: none when the record branch carries changes outside its record that main lacks (a --base run), noted" \
  'grep -q "^done" "$HARNESS_STATE/proj/rb/ended" && ! grep "rb: run record" "$T/gh.log" > /dev/null \
  && hlog rb | grep -F "· record PR: none (harness/rb has changes outside .harness/runs/rb/ that main lacks: based.txt)" > /dev/null'
mv "$T/gh.log" "$T/gh-rb.log"
cp "$T/base-config.sh" "$T/user-config.sh"

# ro: the suite's default, RECORD_PR=off: none opened, noted
STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_LENIENT=1 "$H" start "$T/proj" ro --spec SPEC.md --foreground > "$T/ro.out" 2>&1
check "record PR: RECORD_PR=off opens none, noted" \
  'grep -q "^done" "$HARNESS_STATE/proj/ro/ended" && ! grep "run record" "$T/gh.log" > /dev/null && [[ $(grep -c "pr create" "$T/gh.log") == 2 ]] \
  && hlog ro | grep -F "· record PR: none (RECORD_PR=off)" > /dev/null'
suite_end
