## 2026-10-26 05:29
Three milestones, P0 then P1 then P2, as the spec says. P0 is the suite split (docs/specs/2026-10-26-suite-split.md S1-S3; S4 only if time allows): a move by section markers with the conformance check as the gate, never a rewrite. From P1 on, every new check goes in a tests/checks/ file by topic. MAX_LANES stays 1 by default in code; Michael's config sets 2. Proceed on the spec's defaults; never park.

## 2026-10-26 15:59
Main carries retro's F1 and F2, already merged into this branch (suite green, 392 checks in tests/checks/). Every new check goes in a tests/checks/ file by topic; add its name to tests/fixtures/check-names.txt. P2 item 6 adds to prompts/initializer.md: a target number in a step is 'measured and recorded', not 'under N', unless it protects the box. In P2 the runner gets TEST_FILE_TIMEOUT=10m per file (a hung file is one FAIL line, not a 15-minute suite) and the driver notes '<id>: suite ran <n>x (<s> s) in the session' after each coding session.
