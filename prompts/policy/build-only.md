## Policy: build-only

This project's harness policy is **build-only**. Build and test against fakes, temp directories and the
sandboxed suite. Never operate anything live: no deploys, no containers, no writes to production data or
services, no calls to live APIs. When a feature has a live step, write it out for Michael instead, in the
feature's plan file or your journal entry (`entry.json`): the exact commands in stages (dry run → `--limit 5` → `--limit 50` →
all), what to check after each stage, and how to undo it.
