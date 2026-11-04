#!/usr/bin/env bash
# tier: fast
source "$(dirname "$0")/../lib.sh" && suite_setup
# ---- the read views' formatter, pure (U1): view.mjs context, glyphs, widths, tables, cards, times, end classes ----
# the pure formatter's tests are tests/unit/view.test.mjs; what stays here is the file itself, the fixture against the
# driver's literals, and the CLI
check "view: lib/view.mjs has a usage header, imports only node: built-ins, exports the formatter's functions, and node --check passes" '
  [[ $(head -1 "$HERE/../lib/view.mjs") == "// "*formatter* ]] && node --check "$HERE/../lib/view.mjs" \
  && [[ -n $(grep "^import " "$HERE/../lib/view.mjs") && -z $(grep "^import " "$HERE/../lib/view.mjs" | grep -v " from \"node:") ]] \
  && miss="" && for fn in context glyph paint displayWidth cut pad table section rule card ago when home duration endClass; do
    grep -E "^export (async )?function $fn\\(" "$HERE/../lib/view.mjs" > /dev/null || miss+=" $fn"; done && { [[ -z $miss ]] || { echo "missing:$miss"; false; }; }'
check "view: tests/fixtures/end-reasons.txt holds every literal reason finish, END_REASON and a run-ending lane exit write" '
  R=$(grep -v "^#" "$HERE/fixtures/end-reasons.txt" | cut -f2) miss=""
  lits=$( { grep -o "finish \"[^\"\$]*" "$HERE/../lib/driver.sh" | sed "s/^finish \"//"
    grep -o "END_REASON=\"[^\"\$]*" "$HERE/../lib/driver.sh" | sed "s/^END_REASON=\"//"
    grep -oE "lane_exit (13 \"[^\"\$]*|12 \"feature-list edits)" "$HERE/../lib/lane.sh" | sed "s/^lane_exit 1[23] \"//"; } | grep . | sort -u)
  while read -r l; do ok=0; while read -r r; do [[ $r == "$l"* ]] && ok=1; done <<< "$R"; (( ok )) || miss+="$l|"; done <<< "$lits"
  [[ $(wc -l <<< "$lits") -ge 12 && -z $miss ]] || { echo "literals: $(wc -l <<< "$lits"), missing: $miss"; false; }'
check "view: the CLI renders a table, a card and a section from tab-separated stdin" '
  t=$(printf "id:::left:\twhy::::flex\tn:::right:\nabc\tsome reason\t7\nlong-id-xyz\tother\t12\n" | COLUMNS=40 HARNESS_GLYPHS=unicode node "$HERE/../lib/view.mjs" table)
  c=$(printf "✓ run · proj · done\nended\tdone\nlanes\t\n\tlane M1 · B\n" | COLUMNS=40 HARNESS_GLYPHS=unicode node "$HERE/../lib/view.mjs" card)
  s=$(printf "RUNNING\t1\t\n" | COLUMNS=40 HARNESS_GLYPHS=ascii node "$HERE/../lib/view.mjs" section)
  [[ $(sed -n 1p <<< "$t") =~ ^abc\ +7$ && $(sed -n 2p <<< "$t") == "  some reason" && $(sed -n 3p <<< "$t") =~ ^long-id-xyz\ +12$ ]] || { echo "table: $t"; false; } \
  && [[ $c == "✓ run · proj · done"$'\''\n'\''"$(printf "─%.0s" {1..40})"$'\''\n  ended      done\n  lanes\n    lane M1 · B'\'' ]] || { echo "card: $c"; false; } \
  && [[ $s == "RUNNING 1 $(printf -- "-%.0s" {1..30})" ]] || { echo "section: $s"; false; } \
  && ! node "$HERE/../lib/view.mjs" frob < /dev/null 2> /dev/null \
  && t=$(printf "id\tn\twhy::::0\r\nabc\t7\tx\r\nabcdef\t12\ty\r\n" | COLUMNS=40 node "$HERE/../lib/view.mjs" table) \
  && [[ $t == "abc      7  x"$'\''\n'\''"abcdef  12  y" ]] || { echo "numbers, flex 0, CRLF: $(cat -A <<< "$t")"; false; } \
  && [[ $(printf "X\tabc\thint\n" | COLUMNS=40 HARNESS_GLYPHS=ascii node "$HERE/../lib/view.mjs" section) == "X - hint "* ]]'
suite_end
