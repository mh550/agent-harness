// Feature-list helper for harness/run.sh (no dependencies).
//   next <maxAttempts>        → "<id>\t<model>" of the first feature not passing and not given up on
//   bump <id>                 → count one more session spent on <id>
//   snapshot                  → JSON of the list, for check
//   check <snapshot> <id>     → exit 1 if anything changed besides <id>'s "passes" (features may not be edited)
//   summary                   → "<passing>/<total> passing"
import { readFileSync, writeFileSync, existsSync } from "node:fs";

const LIST = "harness/feature_list.json", ATTEMPTS = "harness/logs/attempts.json";
const MODELS = { fable: "claude-fable-5-1", opus: "claude-opus-5-5", sonnet: "claude-sonnet-5-5", haiku: "claude-haiku-5-5" };
const load = () => JSON.parse(readFileSync(LIST, "utf8")).features;
const attempts = () => (existsSync(ATTEMPTS) ? JSON.parse(readFileSync(ATTEMPTS, "utf8")) : {});
const [cmd, a, b] = process.argv.slice(2);

if (cmd === "next") {
  const att = attempts();
  const f = load().find(f => !f.passes && (att[f.id] ?? 0) < Number(a));
  if (f) console.log(`${f.id}\t${MODELS[f.model] ?? MODELS.opus}`);
} else if (cmd === "bump") {
  const att = attempts();
  att[a] = (att[a] ?? 0) + 1;
  writeFileSync(ATTEMPTS, JSON.stringify(att, null, 2));
} else if (cmd === "snapshot") {
  console.log(JSON.stringify(load()));
} else if (cmd === "check") {
  const before = JSON.parse(readFileSync(a, "utf8")), after = load();
  const strip = list => JSON.stringify(list.map(({ passes, ...rest }) => rest));
  const problems = [];
  if (strip(before) !== strip(after)) problems.push("features were added, removed, reordered or edited");
  for (const f of after) {
    const old = before.find(o => o.id === f.id);
    if (old && old.passes !== f.passes && f.id !== b) problems.push(`${f.id} "passes" changed but the session's feature was ${b}`);
  }
  if (problems.length) { console.error(problems.join("\n")); process.exit(1); }
} else if (cmd === "summary") {
  const list = load();
  console.log(`${list.filter(f => f.passes).length}/${list.length} passing`);
} else {
  console.error("usage: features.mjs next|bump|snapshot|check|summary");
  process.exit(2);
}
