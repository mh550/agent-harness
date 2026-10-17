#!/usr/bin/env bash
# Stand-in for `gh` in tests: records calls; PRs are files (prs/pr-N holds the head branch; pr-N.merged once merged);
# "pr merge" really merges into the bare origin's main. prs/branch-<name> stands for an old v2 whole-run PR.
echo "gh $*" >> "$STUB_DIR/gh.log"
P=$STUB_DIR/prs; mkdir -p "$P"
open_pr() { local f; for f in "$P"/pr-*; do [[ $f == *.merged || ! -f $f ]] && continue; [[ $(cat "$f") == "$1" && ! -f $f.merged ]] && { echo "${f##*-}"; return 0; }; done; return 1; }
case "$1 $2" in
  "pr view")
    if [[ -f $P/branch-${3//\//_} ]]; then [[ $* == *" .state"* ]] && echo OPEN || echo "https://example.test/pr/old"; exit 0; fi
    n=$(open_pr "$3") && echo "https://example.test/pr/$n" || exit 1 ;;
  "pr close") rm -f "$P/branch-${3//\//_}" ;;
  "pr create")
    head=""; while (( $# )); do [[ $1 == --head ]] && head=$2; shift; done
    n=$(( $(ls "$P" | grep -c '^pr-[0-9]*$') + 1 )); echo "$head" > "$P/pr-$n"; echo "https://example.test/pr/$n" ;;
  "pr merge")
    n=${3##*/} c=""; while (( $# )); do [[ $1 == --match-head-commit ]] && c=$2; shift; done
    [[ ${STUB_REFUSE_MERGE:-} ]] && { echo "merge refused" >&2; exit 1; }
    origin=$(git remote get-url origin) tmp=$(mktemp -d)
    git clone -q "$origin" "$tmp" && git -C "$tmp" fetch -q origin "$c" \
      && git -C "$tmp" -c user.name=gh -c user.email=gh@test merge -q --no-ff -m "Merge pull request #$n" "$c" \
      && git -C "$tmp" push -q origin HEAD:main && touch "$P/pr-$n.merged" ;;
esac
