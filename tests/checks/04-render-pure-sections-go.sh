#!/usr/bin/env bash
source "$(dirname "$0")/../lib.sh" && suite_setup
# ---- render, pure: the sections go at the {{SECTIONS}} line, or at the end without one (E3-03) ----
ASM='import { assemble } from "'$HERE'/../lib/render.mjs"; const env = { HARNESS_X: "x" }, s = [{ title: "T", body: "b {{X}}", raw: false }, { title: null, body: "u {{X}}", raw: true }];
  const a = assemble("top\n\n{{SECTIONS}}\n\nend {{X}}\n", s, env), b = assemble("top {{X}}\n", s, env);
  process.exit(a === "top\n\n---\n\n# T\n\nb x\n\nu {{X}}\n\nend x\n" && b === "top x\n\n---\n\n# T\n\nb x\n\nu {{X}}\n" ? 0 : 1);'
check "render.mjs: assemble puts the sections at the {{SECTIONS}} line, one blank line apart" 'node --input-type=module -e "$ASM"'
# --raw pastes the one file after it as written, so a brief with "{{X}}" in it stays out of the fill (E3 review F7)
printf 'b {{X}}\n' > "$T/rb1" && cp "$T/rb1" "$T/rb2" && printf 'top\n' > "$T/rtpl"
RW=$'top\n\nb {{X}}\n\nb x'; check "render.mjs: --raw applies to the next file only" '[[ $(HARNESS_X=x node "$HERE/../lib/render.mjs" "$T/rtpl" --raw "$T/rb1" "$T/rb2") == "$RW" ]]'
suite_end
