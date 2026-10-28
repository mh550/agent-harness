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
IMP="import * as I from \"$IM\"; import { readFileSync as r } from \"node:fs\"; const fx = r(\"$FX\", \"utf8\"), tpl = r(\"$T/tpl.md\", \"utf8\"), planted = r(\"$T/planted.md\", \"utf8\"); const ok = c => process.exit(c ? 0 : 1);"
in_node() { node --input-type=module -e "$IMP $1"; }

check "inbox fixture: n8n-home's INBOX.md at 4632d1c, byte for byte (2504 bytes; line 13 the split, line 28 the heading)" \
  '[[ $(wc -c < "$FX") == 2504 && $(sed -n 13p "$FX") == "## Answers\"." && $(sed -n 28p "$FX") == "## Answers" ]]'
check "inbox.mjs: answersLine skips the comment (27 on the fixture, not 12), allows trailing blanks, and an unclosed comment runs to the end" \
  'in_node "ok(I.answersLine(fx) === 27 && I.answersLine(\"a\n## Answers \t\nb\") === 1 && I.answersLine(\"## Answers\\\".\n## Answersx\") === -1
    && I.answersLine(\"a\n<!-- x\n## Answers\n\") === -1 && I.answersLine(\"<!-- x --> y\n## Answers\") === 1)"'
check "inbox.mjs: question(fixture, B1-05) is Q2, cut at the real heading, no comment in it" \
  'in_node "const q = I.question(fx, \"B1-05\"); ok(q.startsWith(\"**Q2 (B1-05\") && !q.includes(\"<!--\") && q.endsWith(\"newer live-staged rule. Say so if the brief should win.\"))"'
check "inbox.mjs: the driver template has no \"## Answers\" inside its comment; answers() hashes as answers_hash's sed did" \
  '[[ $(grep -c "## Answers" "$T/tpl.md") == 1 && $(tail -1 "$T/tpl.md") == "## Answers" ]] \
  && [[ $(node "$IM" answers "$T/tpl.md" | sha1sum) == $(sed -n "/^## Answers/,\$p" "$T/tpl.md" | sha1sum) ]] \
  && a=$(node "$IM" answers "$FX") && [[ ${a%%$'"'"'\n'"'"'*} == "## Answers" && $(wc -l <<< "$a") == 4 ]]'
check "inbox.mjs: added() on a session that wrote inside the comment returns that question (and only it)" \
  'in_node "ok(I.added(tpl, planted) === \"## Questions\n\n$Q1\")"'
check "inbox.mjs repair: the comment back byte for byte, the question directly above ## Answers; exit 3, then 0" \
  'cp "$T/planted.md" "$T/rep.md"; node "$IM" repair "$T/tpl.md" "$T/rep.md"; r1=$?; cp "$T/rep.md" "$T/rep1.md"; node "$IM" repair "$T/tpl.md" "$T/rep.md"; r2=$?
   (( r1 == 3 && r2 == 0 )) && cmp -s "$T/rep.md" "$T/rep1.md" && [[ $(sed -n "/<!--/,/-->/p" "$T/rep.md") == $(sed -n "/<!--/,/-->/p" "$T/tpl.md") ]] \
   && awk -v q="$Q1" "\$0 == q { n = NR } /^## Answers\$/ { a = NR } END { exit !(n && a == n + 2) }" "$T/rep.md" \
   && cp "$T/tpl.md" "$T/same.md" && node "$IM" repair "$T/tpl.md" "$T/same.md" && cmp -s "$T/same.md" "$T/tpl.md"'
check "inbox.mjs repair: n8n-home's fixture against its template keeps Q2 and moves Q1 above ## Answers, out of the comment" \
  'in_node "const l = fx.split(\"\n\"), before = [...l.slice(0, 2), \"     Change the first line to \\\"status: pause\\\" or \\\"status: stop\\\"; write answers to questions under \\\"## Answers\\\".\", ...l.slice(13)].join(\"\n\");
    const { text, changed } = I.repair(before, fx), t = text.split(\"\n\"), a = I.answersLine(text), q1 = t.findIndex(x => x.startsWith(\"**Q1 (B1-01\")), q2 = t.findIndex(x => x.startsWith(\"**Q2 (B1-05\"));
    ok(changed && text.slice(0, text.indexOf(\"-->\")) === before.slice(0, before.indexOf(\"-->\")) && q2 > 0 && q2 < q1 && q1 < a && t[a - 1] === \"\"
       && I.question(text, \"B1-01\").includes(\"(recommended)\") && I.added(before, fx).startsWith(\"## Questions\") && I.answers(text) === I.answers(fx))"'
check "inbox.mjs: insert() puts the question and a blank line above ## Answers (appended without one); questionLine and files" \
  'in_node "ok(I.insert(tpl, \"Q?\") === tpl.replace(\"## Answers\", \"Q?\n\n## Answers\") && I.insert(\"status: run\n\", \"Q?\") === \"status: run\n\nQ?\n\"
    && I.questionLine(fx, \"B1-05\") === 16 && I.questionLine(fx, \"nope\") === 16 && I.questionLine(\"## Answers\n\", \"A\") === null
    && JSON.stringify(I.files(\"x\nFiles: /a/b.sh:48, /a/c.md\nFiles (harness, from the session): /d.txt\")) === JSON.stringify([{path: \"/a/b.sh\", line: 48}, {path: \"/a/c.md\", line: null}, {path: \"/d.txt\", line: null}]))"'

# U2-02's review: what a never-split INBOX may hold, and what a session may do to the comment besides asking in it
printf '%s\n' "status: run" "<!-- Steer this run -->" "" "### A: does the \`<!--\` marker in index.html matter?" "" "## Answers" "" "### 2026-10-27 10:00 (local)" > "$T/lone.md"; printf 'no' >> "$T/lone.md"
check "inbox.mjs review: a lone <!-- in a question hides nothing; answers() equals sed on it (no final newline); a CRLF heading counts" \
  '[[ $(node "$IM" answers "$T/lone.md" | sha1sum) == $(sed -n "/^## Answers/,\$p" "$T/lone.md" | sha1sum) ]] && [[ -n $(node "$IM" answers "$T/lone.md") ]] \
  && in_node "ok(I.answersLine(r(\"$T/lone.md\", \"utf8\")) === 5 && I.question(r(\"$T/lone.md\", \"utf8\"), \"A\").endsWith(\"matter?\") && I.answersLine(\"a\r\n## Answers\r\nb\") === 1
    && I.answersLine(\"a\n<!-- x\n## Answers\n\") === -1 && I.answersLine(\"a <!-- x --> b\n## Answers\") === 1)"'
check "inbox.mjs review: a --> inside the moved question, a word-aligned insertion, a reworded comment, a comment of the session's own" \
  'in_node "const at = (t, w, x) => { const i = t.indexOf(w) + w.length; return t.slice(0, i) + x + t.slice(i); }, cmt = t => t.slice(t.indexOf(\"<!-- Steer\"), t.indexOf(\"-->\", t.indexOf(\"<!-- Steer\")) + 3);
    const q = \"### A: does \`a --> b\` mean b depends on a?\", r1 = I.repair(tpl, at(tpl, \"under \", \"\n\n\" + q + \"\n\n\"));
    const r2 = I.repair(tpl, at(tpl, \"at the end\", \" (Q for A: should the deploy wait until it the end\"));
    const r3 = I.repair(tpl, tpl.replace(\"from the GitHub app\", \"from GitHub\")), own = \"<!-- A: a note of my own -->\n\" ;
    const r4 = I.repair(tpl, tpl.replace(\"<!-- Steer\", own + \"<!-- Steer\")), r5 = I.repair(tpl, tpl.replace(cmt(tpl), \"### A: which port? <!-- tried 80 -->\"));
    ok(r1.moved === q && cmt(r1.text) === cmt(tpl) && r1.text.split(\"-->\").length === 3 && I.answersLine(r1.text) > r1.text.split(\"\n\").indexOf(q)
       && r2.moved === \"(Q for A: should the deploy wait until it the end\" && !r3.changed && I.added(tpl, tpl.replace(\"from the GitHub app\", \"from GitHub\")) === \"\"
       && !r4.changed && !r5.changed)"'

# One stub run: C's session asks inside the steering comment (split mid-line, as n8n-home's Q1) and parks
STUB_INBOX_IN_COMMENT=C STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_LENIENT=1 "$H" start "$T/proj" inc --spec SPEC.md --foreground > "$T/inc.out" 2>&1
git -C "$T/origin.git" show harness/inc:.harness/runs/inc/INBOX.md > "$T/inc-inbox.md" 2> /dev/null
check "INBOX repair in a run: noted, the record's comment as the driver wrote it, the question directly above ## Answers, C parked" \
  'hlog inc | grep "· INBOX.md: C'"'"'s question was inside the steering comment (hidden on GitHub); moved below it$" > /dev/null \
  && [[ $(sed -n "/<!--/,/-->/p" "$T/inc-inbox.md") == $(sed -n "/<!--/,/-->/p" "$T/tpl.md" | sed "s|harness/r\\.|harness/inc.|") ]] \
  && awk "/^\\*\\*Q1 \\(C, stub\\)\\.\\*\\* / { n = NR } /^## Answers\$/ { a = NR } END { exit !(n && a == n + 2) }" "$T/inc-inbox.md" \
  && hlog inc | grep "C parked (waiting on Michael)" > /dev/null && ! hlog inc | grep "C unparked" > /dev/null'

suite_end
