// Start-of-session end-to-end check: the editor and the Live view load in headless Chromium at 1280 and 390 px,
// with no page errors and no horizontal scroll on the phone width. Run after harness/init.sh.
//   node harness/smoke.mjs [baseUrl]     screenshots → /tmp/pathways-harness/smoke-<page>-<width>.png
import { createRequire } from "node:module";

const require = createRequire("/tmp/pathways-harness/pw/");
const { chromium } = require("playwright");
const base = process.argv[2] ?? "http://localhost:7791";

const browser = await chromium.launch();
let failed = 0;
for (const [name, path] of [["editor", "/"], ["live", "/live"]]) {
  for (const width of [1280, 390]) {
    const page = await browser.newPage({ viewport: { width, height: 900 } });
    const errors = [];
    page.on("pageerror", e => errors.push(e.message));
    // missing cover art answers 404 by design; anything else logged as an error counts
    page.on("console", m => { if (m.type() === "error" && !/status of 404/.test(m.text())) errors.push(m.text()); });
    await page.goto(base + path, { waitUntil: "load" });   // not networkidle: /live keeps an SSE stream open
    await page.waitForTimeout(1000);
    const scroll = await page.evaluate(() => document.documentElement.scrollWidth - window.innerWidth);
    await page.screenshot({ path: `/tmp/pathways-harness/smoke-${name}-${width}.png` });
    const ok = !errors.length && (width > 400 || scroll <= 0);
    if (!ok) failed++;
    console.log(`${ok ? "PASS" : "FAIL"} ${name} @${width}${errors.length ? ` errors: ${errors.join(" | ")}` : ""}${width <= 400 && scroll > 0 ? ` horizontal scroll ${scroll}px` : ""}`);
    await page.close();
  }
}
await browser.close();
process.exit(failed ? 1 : 0);
