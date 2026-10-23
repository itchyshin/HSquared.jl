# GLLVM current-source ordinary-start replay

Goal: replay the frozen 50-seed ordinary-start GLLVM cell against the current Julia source after post-primary engine changes.

- Original primary artifact audit: 50 exact seeds, 50/50 recorded successes, all stored covariance, correlation, and PSD thresholds pass; recomputed Wilson 95% interval [0.9286524, 1.0000000]. Original archive hash matched recorded source SHA `1475066d4b6ff67df3c5adb2a303a96e20b3f7d8fd06e67a0dc283b96636dc0a`.
- Totoro DGP-only audit: 18,000 rates across the frozen seeds; maximum lambda 86.7194767488 at seed 20261621; zero `exp(-lambda)` underflow cells.
- Current-source replay on Totoro, Julia 1.10.0, four Julia threads, one BLAS thread: 50/50 full successes in 141.68 s; Wilson 95% interval [0.9286524, 1.0000000].
- Current source bundle SHA-256 `6def389126ebc31e49da58ae8d7197a5a5e8fb8f26ba2873a6d052a056d81e96`; replay driver SHA-256 `6b5ebdbdd58c22860a3f6c54a552677d2d9d149a5a07fbd93aecc61a22791ff9`; output TSV SHA-256 `02f0af3c974691007acb39e55d07c499fd42705e8dbf4d050587c1d889faa030`.
- Recalculation from retained G entries reproduced logged relative-G error, correlation error, and minimum eigenvalue within 2.04e-12, 2.21e-12, and 5.76e-12. Original-versus-replay per-seed log likelihood differences were zero; error metric differences were below 2.21e-12.
- `bash /Users/z3437171/shinichi-brain/tools/totoro_hygiene.sh`: clean, 0 zombies, no stopped supervisors, stale watchers, or busy process.

Claim boundary: one same-seed current-source replay for the complete balanced Poisson T=3/K=2 cell. No broad calibration, other-family or missing-data recovery, R parity, external comparator, capability promotion, GPU, or release claim.
