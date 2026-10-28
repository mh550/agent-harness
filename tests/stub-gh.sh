#!/usr/bin/env bash
# Stand-in for `gh` in tests: records calls; PRs are files (prs/pr-N holds the head branch, pr-N.title its title;
# pr-N.merged once merged, pr-N.closed once closed); "pr merge" really merges into the bare origin's main.
# prs/branch-<name> stands for an old v2 whole-run PR (title "v2 run"). "pr view <head> --json <fields> -q <expr>"
# answers as gh does: the head's open PR, else its newest, as {url, state, title, headRefName}, -q applied by jq -r.
# "pr create" refuses a head with an open PR, "pr merge --match-head-commit" a head that moved, as gh does.
# "api repos/<o>/<r>/deployments…" answers GitHub's published example (fixtures/gh-deployments.json, creator octocat).
HERE=$(cd "$(dirname "$0")" && pwd)
echo "gh $*" >> "$STUB_DIR/gh.log"
P=$STUB_DIR/prs; mkdir -p "$P"
prs_of() { local f; for f in "$P"/pr-*; do [[ ${f##*/} =~ ^pr-[0-9]+$ && $(cat "$f") == "$1" ]] && echo "${f##*-}"; done | sort -n; }   # <head> → its PRs, oldest first
state() { if [[ -f $P/pr-$1.merged ]]; then echo MERGED; elif [[ -f $P/pr-$1.closed ]]; then echo CLOSED; else echo OPEN; fi; }
open_pr() { local n; for n in $(prs_of "$1"); do [[ $(state "$n") == OPEN ]] && { echo "$n"; return 0; }; done; return 1; }
# <url> <state> <title> <head> [-q expr]: gh's --json object, or its -q result
answer() { local j; j=$(jq -nc --arg u "$1" --arg s "$2" --arg t "$3" --arg h "$4" '{url: $u, state: $s, title: $t, headRefName: $h}')
  if [[ -n ${5:-} ]]; then jq -r "$5" <<< "$j"; else echo "$j"; fi; }
case "$1 $2" in
  "api repos/"*)   # the repo's deployments (read-only): STUB_DEPLOYMENTS=0 → none, =vercel → made by Vercel's app
    case ${STUB_DEPLOYMENTS:-} in 0) echo '[]' ;; vercel) sed 's/"octocat"/"vercel[bot]"/' "$HERE/fixtures/gh-deployments.json" ;;
      *) cat "$HERE/fixtures/gh-deployments.json" ;; esac ;;
  "pr view")
    b=$3 q=""; while (( $# )); do [[ $1 == -q ]] && q=$2; shift; done
    if [[ -f $P/branch-${b//\//_} ]]; then answer "https://example.test/pr/old" OPEN "v2 run" "$b" "$q"; exit 0; fi
    n=$(open_pr "$b") || n=$(prs_of "$b" | tail -1)
    [[ -n $n ]] || { echo "no pull requests found for branch \"$b\"" >&2; exit 1; }
    answer "https://example.test/pr/$n" "$(state "$n")" "$(cat "$P/pr-$n.title" 2> /dev/null)" "$b" "$q" ;;
  "pr close")   # one PR: the v2 one if the head has it, else its open one
    if [[ -f $P/branch-${3//\//_} ]]; then rm -f "$P/branch-${3//\//_}"; elif n=$(open_pr "$3"); then touch "$P/pr-$n.closed"; fi ;;
  "pr create")
    head="" title=""; while (( $# )); do case $1 in --head) head=$2 ;; --title) title=$2 ;; esac; shift; done
    if n=$(open_pr "$head"); then echo "a pull request for branch \"$head\" into branch \"main\" already exists:"; echo "https://example.test/pr/$n"; exit 1; fi
    n=$(( $(ls "$P" | grep -c '^pr-[0-9]*$') + 1 )); echo "$head" > "$P/pr-$n"; echo "$title" > "$P/pr-$n.title"; echo "https://example.test/pr/$n" ;;
  "pr merge")
    n=${3##*/} c=""; while (( $# )); do [[ $1 == --match-head-commit ]] && c=$2; shift; done
    [[ ${STUB_REFUSE_MERGE:-} ]] && { echo "merge refused" >&2; exit 1; }
    origin=$(git remote get-url origin) tmp=$(mktemp -d)
    # --match-head-commit: the PR's head branch must still be at that commit
    [[ -z $c || $(git ls-remote "$origin" "refs/heads/$(cat "$P/pr-$n")" | cut -f1) == "$c" ]] \
      || { echo "GraphQL: Head branch was modified. Review and try the merge again. (mergePullRequest)" >&2; exit 1; }
    git clone -q "$origin" "$tmp" && git -C "$tmp" fetch -q origin "$c" \
      && git -C "$tmp" -c user.name=gh -c user.email=gh@test merge -q --no-ff -m "Merge pull request #$n" "$c" \
      && git -C "$tmp" push -q origin HEAD:main && touch "$P/pr-$n.merged" ;;
esac
