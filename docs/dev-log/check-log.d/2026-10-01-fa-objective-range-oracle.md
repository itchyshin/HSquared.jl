# 2026-10-01 FA objective-range test oracle

Two Julia 1.13 hosted jobs failed one assertion because the expected range used a manually constructed start whose algebra matched, but whose floating-point arithmetic differed from, the production balanced start. The assertion now compares against the fit returned from the exact reported start. Independent review confirms the correction and finds no numerical-source issue.

Fresh Julia 1.13.1 `Pkg.test()` passed in 476.04 seconds. The Julia documentation build passed in 49.00 seconds, and required live R-Julia bridge tests passed in 24.87 seconds. The three installed exact-source evidence modes passed. Package output, exact input freeze, and the pre-fix failures are retained in `check-log.d/2026-09-30-final-integrated/`.

Rose's audit is clean with limitations. The approved push, exact-current hosted CI, and merge remain pending. No capability, covered-count, release, or campaign status changed.
