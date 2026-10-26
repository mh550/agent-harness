## agent-harness-2026-10-26 · agent-harness

| | |
|---|---|
| Passing | **2/17** · verified 0 (none) · merged 0 (none) |
| Tests | not recorded |
| Spend | **$22.76** total · **$11.38** per passing feature |
| Spend by role | init $4.71 · build $18.05 · manager (the bash driver) $0.00 |
| Tokens | 34.5M in (cache hit 0.97) · context peak 206.4k · orientation 843.5k tokens / 15 turns (median) · per verified feature – tokens, – |
| Quality | first-attempt pass rate 0.67 · rework P0-02 · verify-fail rate – |
| Time | 3.01 h wall: sessions 2.79 h (init 0.17, build 2.62), driver 0.22 h |
| Sessions | 5 (5 real, 0 refused by limits/API errors) |
| Ended | blocked on P0-02 |
| Not passing | not done 1 · blocked 14 |

| Feature | Cause | Detail | Sessions | $ |
|---|---|---|---|---|
| P0-02 | not done | P0-02 does **not** pass. I left `passes` false because step 5, a full suite under 150 s with `TEST_JOBS=4`, isn't met. Steps 1–4, 6 and 7 hold, and the suite is green: 335/335 in 165 s. - **Why splitt | 2 | $10.44 |
| P0-04 | blocked | waits on P0-02, which was given up | 0 | $0.00 |
| P1-01 | blocked | waits on P0-02, which was given up | 0 | $0.00 |
| P1-02 | blocked | waits on P0-02, which was given up | 0 | $0.00 |
| P1-03 | blocked | waits on P0-02, which was given up | 0 | $0.00 |
| P1-04 | blocked | waits on P0-02, which was given up | 0 | $0.00 |
| P1-05 | blocked | waits on P0-02, which was given up | 0 | $0.00 |
| P1-06 | blocked | waits on P0-02, which was given up | 0 | $0.00 |
| P2-01 | blocked | waits on P0-02, which was given up | 0 | $0.00 |
| P2-02 | blocked | waits on P0-02, which was given up | 0 | $0.00 |
| P2-03 | blocked | waits on P0-02, which was given up | 0 | $0.00 |
| P2-04 | blocked | waits on P0-02, which was given up | 0 | $0.00 |
| P2-05 | blocked | waits on P0-02, which was given up | 0 | $0.00 |
| P2-06 | blocked | waits on P0-02, which was given up | 0 | $0.00 |
| P2-07 | blocked | waits on P0-02, which was given up | 0 | $0.00 |
