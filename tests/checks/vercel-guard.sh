#!/usr/bin/env bash
# tier: fast
source "$(dirname "$0")/../lib.sh" && suite_setup
# ---- deploy guards (E0b): the vercel-guard CLI; the pure evals are tests/unit/deploy.test.mjs (summary's and metrics' in their own test files) ----
check "deploy: vercel-guard prints by-hand for a vercel.json with a true harness/ key (E1 review)" \
  'echo "{\"git\":{\"deploymentEnabled\":{\"harness/**\":false,\"harness/*\":true}}}" > "$T/vover.json" && [[ $(node "$HERE/../lib/deploy.mjs" vercel-guard "$T/vover.json") == by-hand ]]'

suite_end
