#!/usr/bin/env bash
source "$(dirname "$0")/../lib.sh" && suite_setup
# ---- the suite cache key (suite-split S3): CHECK_KEY_IGNORE leaves out what the suite never reads ----
git init -q "$T/ky" && ( cd "$T/ky" && mkdir -p lib docs/plans docs/plansx && echo a > lib/a.sh && echo p > docs/plans/p.md \
  && git add -A && git -c user.name=t -c user.email=t@t commit -qm a )
ky() { ( cd "$T/ky" && node "$HERE/../lib/treekey.mjs" ); }
KI=".harness/runs docs/plans docs/specs"
ky0=$(HARNESS_CHECK_KEY_IGNORE=$KI ky); ky0u=$(ky)
echo q > "$T/ky/docs/plans/new.md"; echo changed >> "$T/ky/docs/plans/p.md"; mkdir -p "$T/ky/docs/specs" && echo s > "$T/ky/docs/specs/s.md"
ky1=$(HARNESS_CHECK_KEY_IGNORE=$KI ky); ky1u=$(ky)
echo x > "$T/ky/docs/plansx/x.md"; ky2=$(HARNESS_CHECK_KEY_IGNORE=$KI ky)   # a sibling sharing the prefix's letters is not under it
rm "$T/ky/docs/plansx/x.md"; echo b >> "$T/ky/lib/a.sh"; ky3=$(HARNESS_CHECK_KEY_IGNORE=$KI ky)
check "treekey: two trees that differ only under an ignored prefix have the same 16-hex key; a change under lib/ changes it" \
  '[[ $ky0 =~ ^[0-9a-f]{16}$ && $ky1 == "$ky0" && $ky2 != "$ky0" && $ky3 != "$ky0" && $ky3 != "$ky2" ]]'
ky4=$(ky); ky5=$(HARNESS_CHECK_KEY_IGNORE=". ./ * lib/* docs/pl*" ky); ky6=$(HARNESS_CHECK_KEY_IGNORE="./docs/plans/ ." ky); ky7=$(HARNESS_CHECK_KEY_IGNORE=docs/plans ky)
check "treekey: entries are literal path prefixes (. and globs leave nothing out; ./docs/plans/ is docs/plans)" '[[ $ky5 == "$ky4" && $ky6 == "$ky7" && $ky7 != "$ky4" ]]'
ky8=$(HARNESS_CHECK_KEY_IGNORE="/docs/plans ../x docs/../lib docs/plans" ky 2>&1)   # P0 review: git rejects a pathspec outside the repo
check "treekey: an absolute or .. entry is dropped, not an error (the key is docs/plans' alone)" '[[ $ky8 == "$ky7" ]]'
check "treekey: unset, HARNESS_CHECK_KEY_IGNORE leaves out .harness/runs alone (docs/plans changes the key)" \
  '[[ $ky0u =~ ^[0-9a-f]{16}$ && $ky1u != "$ky0u" ]]'
check "CHECK_KEY_IGNORE: harness default .harness/runs docs/plans; this repo extends it; the template has it commented; the driver exports it" \
  '( source "$HERE/../lib/config.sh" && HARNESS_CONFIG=/dev/null harness_config /nonexistent && [[ $CHECK_KEY_IGNORE == ".harness/runs docs/plans" ]] ) \
  && ( source "$HERE/../lib/config.sh" && HARNESS_CONFIG=/dev/null harness_config "$HERE/.." && [[ $CHECK_KEY_IGNORE == ".harness/runs docs/plans docs/specs journal findings-and-research ledger" ]] ) \
  && grep -q "^# CHECK_KEY_IGNORE=" "$HERE/../templates/project/config.sh" && grep -q "HARNESS_CHECK_KEY_IGNORE=\$CHECK_KEY_IGNORE" "$HERE/../lib/prompt.sh"'
# check.sh's cached line: plain when the list is the default (or unset), naming the list when it is not
ck() { ( cd "$T/ky" && HARNESS_SCRATCH=$T/kys HARNESS_CHECK_CACHE=$T/kyc HARNESS_CHECK_CMD='echo "# pass 2"' "$HERE/../lib/check.sh" ); }
HARNESS_CHECK_KEY_IGNORE=$KI ck > /dev/null; ck_wide=$(HARNESS_CHECK_KEY_IGNORE=$KI ck)
HARNESS_CHECK_KEY_IGNORE=".harness/runs docs/plans" ck > /dev/null; ck_def=$(HARNESS_CHECK_KEY_IGNORE=".harness/runs docs/plans" ck)
ck > /dev/null; ck_unset=$(ck)
check "check.sh: the cached line names the key's ignore list only when it isn't the default" \
  '[[ $ck_wide == "check: green (cached for this code tree, 2 tests; key ignores: docs/plans docs/specs)" ]] \
  && [[ $ck_def == "check: green (cached for this code tree, 2 tests)" && $ck_unset == "check: green (cached for this code tree, 2 tests)" ]]'
# two stub runs, two coding sessions each (one feature's two attempts): each session edits one path and passes nothing,
# so the suite runs only before each session; the second session keeps the init output it got (STUB_EDIT); the edits
# live on the lane branch, unverified at the cap, so kept on the origin
mkdir -p lib && echo a > lib/a.sh && git add lib && git commit -qm "lib" && git push -q origin main
{ cat "$T/base-config.sh"; echo MAX_SESSIONS=2; } > "$T/ky-config.sh"
STUB_EDIT=docs/plans/x.md HARNESS_CONFIG=$T/ky-config.sh "$H" start "$T/proj" kyplan --spec SPEC.md --foreground > "$T/kyplan.out" 2>&1
STUB_EDIT=lib/a.sh HARNESS_CONFIG=$T/ky-config.sh "$H" start "$T/proj" kylib --spec SPEC.md --foreground > "$T/kylib.out" 2>&1
check "suite cache: a session that adds only docs/plans/x.md leaves the next session's suite cached green" \
  'grep -q "^check: green (cached for this code tree" "$T/init-kyplan-2.out" && git -C "$T/origin.git" cat-file -e harness-lane/kyplan/M1:docs/plans/x.md'
check "suite cache: a session that edits lib/ (tracked) makes the next session's suite run" \
  'grep -q "^check: green in " "$T/init-kylib-2.out" && ! grep -q "cached" "$T/init-kylib-2.out" && [[ $(git -C "$T/origin.git" show harness-lane/kylib/M1:lib/a.sh 2> /dev/null | wc -l) -ge 2 ]]'
# a main moved only in these paths merges without a re-base (ignored_only, lib/record.sh): no file the suite runs may read one
reads_ignored() { ( source "$HERE/../lib/config.sh" && HARNESS_CONFIG=/dev/null harness_config "$HERE/.." \
  && for p in $CHECK_KEY_IGNORE; do grep -rlE "/\.\./${p//./\\.}(/|\"|\$)" "$HERE" "$HERE/../lib" "$HERE/../bin"; done ); }
check "CHECK_KEY_IGNORE: no file under tests/, lib/ or bin/ reads a path this repo's cache key ignores (a merge skips its re-base on them)" \
  '[[ -z $(reads_ignored) ]]'
suite_end
