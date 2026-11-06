#!/usr/bin/env bash
# The coverage tool's bash sample (tests/unit/coverage.test.mjs): one of each shape bash numbers its own way.
# tests/fixtures/coverage/sample.xtrace is its real trace, this box's path replaced by /ROOT.
sample() {
  local a=$1
  echo "one" \
    "two" > /dev/null
  [[ $a == 1 &&
     $a != 2 ]] && echo yes > /dev/null
  case $a in
    1) : first ;;
    *)
      : other ;;
  esac
  x=$(echo sub
      echo sub2)
  if (( a > 5 )); then
    : never
  fi
  cat <<HD > /dev/null
body $a
HD
  echo "multi
line $a" > /dev/null
  true \
    && : cont
  while read -r l; do
    : "$l"
  done < <(echo fed)
}
unused() {
  : never called
}
