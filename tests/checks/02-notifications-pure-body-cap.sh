#!/usr/bin/env bash
source "$(dirname "$0")/../lib.sh" && suite_setup
# ---- notifications, pure: the body cap and ntfy's actions header ----
TRIM='import { trimBody } from "'$HERE'/../lib/notify.mjs"; const t = trimBody("x".repeat(4000)), e = trimBody("é".repeat(2000)), s = "y".repeat(100);
  process.exit(Buffer.byteLength(t) <= 3500 && t.endsWith("…") && Buffer.byteLength(e) <= 3500 && e.endsWith("é…") && trimBody(s) === s ? 0 : 1);'
check "notify.mjs: trimBody caps at 3500 bytes with …" 'node --input-type=module -e "$TRIM"'
ACT='import { actionsHeader as a } from "'$HERE'/../lib/notify.mjs";
  const two = a([{ label: "Edit INBOX", url: "https://e/1" }, { label: "Skip", url: "" }, { label: "Progress", url: "https://e/2" }]);
  process.exit(two === "view, Edit INBOX, https://e/1; view, Progress, https://e/2" && a([1, 2, 3, 4].map(i => ({ label: "L" + i, url: "u" + i }))).split("; ").length === 3
    && a([]) === "" && a([{ label: "x", url: "" }]) === "" ? 0 : 1);'
check "notify.mjs: actionsHeader joins view actions, skips empty urls, at most 3" 'node --input-type=module -e "$ACT"'
URLS='import { githubUrls as g } from "'$HERE'/../lib/notify.mjs"; const a = g("git@github.com:o/r.git", "harness/x", ".harness/runs/x/INBOX.md");
  const same = ["git@github.com:o/r", "https://github.com/o/r.git", "https://github.com/o/r", "https://github.com/o/r/", "ssh://git@github.com/o/r.git"].every(u => g(u, "b", "p")?.blob === "https://github.com/o/r/blob/b/p");
  process.exit(a?.blob === "https://github.com/o/r/blob/harness/x/.harness/runs/x/INBOX.md" && a.edit === "https://github.com/o/r/edit/harness/x/.harness/runs/x/INBOX.md"
    && same && g("git@github.com:o/r.git", "", "p") === null && g("/tmp/origin.git", "b", "p") === null && g("git@gitlab.com:o/r.git", "b", "p") === null && g("", "b", "p") === null ? 0 : 1);'
check "notify.mjs: githubUrls for ssh, https and non-GitHub origins" 'node --input-type=module -e "$URLS"'
QUES='import { inboxQuestion as q } from "'$HERE'/../lib/notify.mjs"; const b = "status: run\n\n## Answers\nold\n", a = "status: run\n### B: set the gatus vars, then answer\n\n## Answers\nold\nmine\n";
  process.exit(q(b, a) === "### B: set the gatus vars, then answer" && q(b, b) === "" && q("", a) === "status: run\n### B: set the gatus vars, then answer"
    && q("status: run\n", a) === "### B: set the gatus vars, then answer" && q(b, "status: run\n### B: q\nold\n") === "### B: q" ? 0 : 1);'
check "notify.mjs: inboxQuestion is the lines added above ## Answers (never Michael's old answers)" 'node --input-type=module -e "$QUES"'

suite_end
