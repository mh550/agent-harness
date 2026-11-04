#!/usr/bin/env bash
source "$(dirname "$0")/../lib.sh" && suite_setup
# ---- INBOX.md (U2-02, bug a): one parser that finds "## Answers" outside the steering comment, and the repair ----
# The fixture is n8n-home's INBOX.md at 4632d1c, byte for byte: a session split the comment's `"## Answers".` mid-line
# with its Q1, so GitHub hid Q1 and every `/^## Answers/` cut stopped at line 13.
FX=$HERE/fixtures/inbox-q-in-comment.md IM=$HERE/../lib/inbox.mjs
# The driver's template, as its heredoc writes it for branch harness/r
awk '/cat > "\$REC\/INBOX.md" <<EOF$/ { f = 1; next } f && /^EOF$/ { exit } f' "$HERE/../lib/driver.sh" | sed 's|\$BRANCH|harness/r|' > "$T/tpl.md"
# The template with a question planted mid-line in its comment, n8n-home's shape (tests/stub-claude.sh STUB_INBOX_IN_COMMENT)
Q1='**Q1 (A, stub).** set the gatus vars, then answer'
node -e 'const fs=require("fs"),[f,o,q]=process.argv.slice(1),t=fs.readFileSync(f,"utf8"),i=t.indexOf("under ")+6;fs.writeFileSync(o,t.slice(0,i)+"## Questions\n\n"+q+"\n\n"+t.slice(i))' "$T/tpl.md" "$T/planted.md" "$Q1"
# the pure evals of inbox.mjs (answersLine, question, added, repair, insert, files) are tests/unit/inbox.test.mjs

check "inbox fixture: n8n-home's INBOX.md at 4632d1c, byte for byte (2504 bytes; line 13 the split, line 28 the heading)" \
  '[[ $(wc -c < "$FX") == 2504 && $(sed -n 13p "$FX") == "## Answers\"." && $(sed -n 28p "$FX") == "## Answers" ]]'
check "inbox.mjs: the driver template has no \"## Answers\" inside its comment; answers() hashes as answers_hash's sed did" \
  '[[ $(grep -c "## Answers" "$T/tpl.md") == 1 && $(tail -1 "$T/tpl.md") == "## Answers" ]] \
  && [[ $(node "$IM" answers "$T/tpl.md" | sha1sum) == $(sed -n "/^## Answers/,\$p" "$T/tpl.md" | sha1sum) ]] \
  && a=$(node "$IM" answers "$FX") && [[ ${a%%$'"'"'\n'"'"'*} == "## Answers" && $(wc -l <<< "$a") == 4 ]]'
check "inbox.mjs repair: the comment back byte for byte, the question directly above ## Answers; exit 3, then 0" \
  'cp "$T/planted.md" "$T/rep.md"; node "$IM" repair "$T/tpl.md" "$T/rep.md"; r1=$?; cp "$T/rep.md" "$T/rep1.md"; node "$IM" repair "$T/tpl.md" "$T/rep.md"; r2=$?
   (( r1 == 3 && r2 == 0 )) && cmp -s "$T/rep.md" "$T/rep1.md" && [[ $(sed -n "/<!--/,/-->/p" "$T/rep.md") == $(sed -n "/<!--/,/-->/p" "$T/tpl.md") ]] \
   && awk -v q="$Q1" "\$0 == q { n = NR } /^## Answers\$/ { a = NR } END { exit !(n && a == n + 2) }" "$T/rep.md" \
   && cp "$T/tpl.md" "$T/same.md" && node "$IM" repair "$T/tpl.md" "$T/same.md" && cmp -s "$T/same.md" "$T/tpl.md"'

# U2-02's review: what a never-split INBOX may hold (its parse and the comment's other edits: tests/unit/inbox.test.mjs)
printf '%s\n' "status: run" "<!-- Steer this run -->" "" "### A: does the \`<!--\` marker in index.html matter?" "" "## Answers" "" "### 2026-10-27 10:00 (local)" > "$T/lone.md"; printf 'no' >> "$T/lone.md"
check "inbox.mjs answers CLI: on a lone <!-- INBOX with no final newline, the same bytes as sed's cut, never empty" \
  '[[ $(node "$IM" answers "$T/lone.md" | sha1sum) == $(sed -n "/^## Answers/,\$p" "$T/lone.md" | sha1sum) ]] && [[ -n $(node "$IM" answers "$T/lone.md") ]]'

# One stub run: C's session asks inside the steering comment (split mid-line, as n8n-home's Q1) and parks
STUB_INBOX_IN_COMMENT=C STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_LENIENT=1 "$H" start "$T/proj" inc --spec SPEC.md --foreground > "$T/inc.out" 2>&1
git -C "$T/origin.git" show harness/inc:.harness/runs/inc/INBOX.md > "$T/inc-inbox.md" 2> /dev/null
check "INBOX repair in a run: noted, the record's comment as the driver wrote it, the question directly above ## Answers, C parked" \
  'hlog inc | grep "· INBOX.md: C'"'"'s question was inside the steering comment (hidden on GitHub); moved below it$" > /dev/null \
  && [[ $(sed -n "/<!--/,/-->/p" "$T/inc-inbox.md") == $(sed -n "/<!--/,/-->/p" "$T/tpl.md" | sed "s|harness/r\\.|harness/inc.|") ]] \
  && awk "/^\\*\\*Q1 \\(C, stub\\)\\.\\*\\* / { n = NR } /^## Answers\$/ { a = NR } END { exit !(n && a == n + 2) }" "$T/inc-inbox.md" \
  && hlog inc | grep "C parked (waiting on Michael)" > /dev/null && ! hlog inc | grep "C unparked" > /dev/null'

suite_end
