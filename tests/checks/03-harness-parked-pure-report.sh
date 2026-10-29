#!/usr/bin/env bash
source "$(dirname "$0")/../lib.sh" && suite_setup
# ---- harness parked, pure: the report and the INBOX question it quotes ----
PREP='import { parkedReport as r } from "'$HERE'/../lib/parked.mjs"; const e = { run: "r", project: "p", feature: "B", since: "2026-10-19T01:00:00Z", why: "w", question: "q", running: false, runner: false };
  const a = r([e]), b = r([{ ...e, runner: true }]), c = r([{ ...e, running: true }]), j = JSON.parse(r([e, { ...e, run: "s", since: "2026-10-18T01:00:00Z" }], { json: true }));
  process.exit(a.includes("harness answer r \"…\"") && a.includes("harness continue r") && b.includes("harness queue add --continue r") && !b.includes("harness continue r")
    && c.includes("running:  yes") && c.includes("harness answer r \"…\"") && !c.includes("continue r") && r([], {}) === "nothing parked\n" && r([], { run: "x" }) === "nothing parked in x\n"
    && JSON.parse(r([], { json: true })).length === 0 && j.map(x => x.run).join() === "s,r" && Object.keys(j[0]).join() === "run,project,feature,since,why,question,running,ending,queued,commands" ? 0 : 1);'
check "parked.mjs: the report names the answer and continue commands" 'node --input-type=module -e "$PREP"'
QFOR='import { questionFor as q, parkedReport as r } from "'$HERE'/../lib/parked.mjs";
  const i = "status: run\n<!-- Steer this run\n     from the app -->\n\n### A: db url\nwhich db?\n### B: set the gatus vars, then answer\n\n## Answers\n### B: an old answer\n";
  const t = r([{ run: "parky", project: "proj", feature: "B", since: "2026-10-19T01:00:00Z", why: "set the gatus vars", question: q(i, "A"), running: false, runner: false }], { now: Date.parse("2026-10-19T03:00:00Z") });
  process.exit(q(i, "B") === "### B: set the gatus vars, then answer" && q(i, "C") === "### A: db url\nwhich db?\n### B: set the gatus vars, then answer"
    && q("status: run\n\n## Answers\n", "B") === "" && q("### Bx: q\n## Answers\n", "B") === "### Bx: q" && q("", "B") === "" && q("### A: needs B first\n### B: the vars\n", "B") === "### B: the vars"
    && t === "parky · proj · B\n  since:    2026-10-19 01:00 (2 h ago)\n  why:      set the gatus vars\n  question: ### A: db url\n            which db?\n  running:  no\n  next:     harness answer parky \"…\"\n            harness continue parky\n" ? 0 : 1);'
check "parked.mjs: the question is the feature's INBOX section" 'TZ=UTC node --input-type=module -e "$QFOR"'
QNEW='import { questionFor as q, commandsFor as c } from "'$HERE'/../lib/parked.mjs";
  process.exit(q("status: run\n\n### B: set the gatus vars\nold, answered\n\n### B: now the token too\nnew one\n\n## Answers\n", "B") === "### B: now the token too\nnew one"
    && q("### 1.2: y\n### 1.2.3: x\n## Answers\n", "1.2") === "### 1.2: y" && q("### B: q\nthe text\n## Notes\nnot it\n## Answers\n", "B") === "### B: q\nthe text"
    && q("status: run\n### B: q\n### 2026-10-19 10:00 (local)\nmy answer\n", "C") === "### B: q"
    && q("status: run\n### B: q1\n### 2026-10-19 10:00 (local)\nans\n### B: q2 new\n", "B") === "### B: q2 new"
    && q("### B: set vars\n```bash\n# put these in .env\nFOO=1\n```\nthen answer\n## Answers\n", "B") === "### B: set vars\n```bash\n# put these in .env\nFOO=1\n```\nthen answer"
    && JSON.stringify(c("r", { queued: true })) === JSON.stringify(["harness answer r \"…\""]) ? 0 : 1);'
check "parked.mjs: the newest question wins, ids with dots, code fences, never Michael's answers" 'node --input-type=module -e "$QNEW"'
BUSY='import { commandsFor as c, runState as s, parkedReport as r, entriesFor as e } from "'$HERE'/../lib/parked.mjs";
  const b = c("r", { busy: "o" }), Q = "harness queue add --continue r # waits for o to end; o merges first", N = "harness continue r --now # runs beside o; this run merges first if it finishes first";
  const t = r(e({ run: "r", project: "p", parked: { B: { why: "w", at: "2026-10-19T01:00:00Z" } }, list: null, inbox: "", busy: "o" })), j = JSON.parse(r([{ run: "r", feature: "B", busy: "o" }], { json: true }));
  process.exit(JSON.stringify(b) === JSON.stringify(["harness answer r \"…\"", Q, N]) && JSON.stringify(c("r", { busy: "o", runner: true })) === JSON.stringify(b)
    && c("r", { busy: "o", running: true }).length === 1 && c("r", { busy: "o", queued: true }).length === 1
    && JSON.stringify(c("r", { busy: "" })) === JSON.stringify(c("r")) && JSON.stringify(c("r", { busy: "", runner: true })) === JSON.stringify(["harness answer r \"…\"", "harness queue add --continue r"])
    && s({ busy: "o" }) === "no; o is running on this project: pick one continue" && s({ busy: "o", ending: true }).startsWith("ending (answer now") && s({ busy: "o", ending: true }).endsWith("; o is running on this project: pick one continue")
    && s({ busy: "o", running: true }) === s({ running: true }) && s({ busy: "o", queued: true }) === s({ queued: true }) && s({ busy: "" }) === "no"
    && t.includes("  running:  no; o is running on this project") && t.includes("            " + Q) && t.includes("            " + N)
    && JSON.stringify(j[0].commands) === JSON.stringify(b) ? 0 : 1);'
check "parked.mjs: another live run of the project: the queue add and --now, each with its merge order" 'node --input-type=module -e "$BUSY"'
( NTFY_URL=https://ntfy.example/t NTFY_TOKEN="" NOTIFY_CMD=""; log() { :; }; source "$HERE/../lib/notify.sh"; notify "long one" title="long one" body="$(head -c 4000 /dev/zero | tr '\0' x)" )
check "a body over the cap is trimmed"    'Bd=$(curl_body "Title: long one"); (( $(printf %s "$Bd" | wc -c) <= 3500 && $(printf %s "$Bd" | wc -c) > 3000 )) && [[ $Bd == *… ]]'

suite_end
