#!/usr/bin/env bash
# tier: fast
source "$(dirname "$0")/../lib.sh" && suite_setup
# ---- render: the --raw CLI (assemble's eval is tests/unit/render.test.mjs) ----
# --raw pastes the one file after it as written, so a brief with "{{X}}" in it stays out of the fill (E3 review F7)
printf 'b {{X}}\n' > "$T/rb1" && cp "$T/rb1" "$T/rb2" && printf 'top\n' > "$T/rtpl"
RW=$'top\n\nb {{X}}\n\nb x'; check "render.mjs: --raw applies to the next file only" '[[ $(HARNESS_X=x node "$HERE/../lib/render.mjs" "$T/rtpl" --raw "$T/rb1" "$T/rb2") == "$RW" ]]'
suite_end
