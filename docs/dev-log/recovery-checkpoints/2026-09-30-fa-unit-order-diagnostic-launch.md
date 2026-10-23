# FA ordinary-start unit and trait-order diagnostic launch

The five-case diagnostic is running on Totoro CPU against the frozen FA primary source. Runtime estimate before launch: at most one hour. GNU timeout stops it at 3,600 seconds, with a 30-second kill grace. Julia threads are four and BLAS threads one. No GPU work.

## Fixed scope

Seed 20260929, 40 founder animals, five records per animal, four Gaussian traits and one factor. Cases: baseline, units (2, 0.5, 1.5, 0.8), inverse units, order (3, 1, 4, 2), and reverse order. All omit initial loadings. Each of two named starts has a 10,000-iteration cap. This diagnostic differs from the primary campaign's 5,000 cap and cannot replace its denominator. Independent fixed-covariance REML, GLS and breeding-value mapping checks accompany the optimizer comparisons.

## Frozen provenance

Source-tree SHA-256: `d3c2de8d7f0a1a86918f15938264bbdc892a7303b5ddd488553ac923f073ad0a`. Fixture source SHA-256: `e621d60892c9ec9ceab6a1b06d051495d2aa1b9d6c70346023129a993b2d9085`. Script SHA-256: `026c3d5ad3a192e26626d3bb38d146266b24b397e981d244d88c960be15f267e`. README SHA-256: `41dbe7888f95dbe30e6d0cc85e9bb8a35f1d53898f1e2f4e2866c8f79944f45e`.

Remote root: `/home/snakagaw/hsq_work/hsquared-fa-current-candidate-20260930`. Retry output: `unit_order_20260930_retry1`; log: `unit_order_retry1.log`; PID receipt: `unit_order_retry1.pid`. Timeout PID 722188 and Julia child PID 722189 were observed alive, with manifest, fixture and generating-oracle artifacts created.

## Failed launch retained

The first launch stopped before fixture generation or any fit because Git HEAD metadata was mandatory for a source-only snapshot. Its empty output directory, log, PID receipt, script and README are retained. The repaired helper records unavailable Git identity while still requiring exact source and fixture fingerprints. The retry uses a fresh output directory and the same five cases, starts, seed, cap and targets.

Exit zero denotes finite completion of the correctness checks. It does not certify optimizer invariance, population recovery or A2 completion. Floor constraints and optimizer sensitivity remain explicit. No ledger gate has been closed by this launch.

## Completion and independent verification

The retry completed in 270.264579069 seconds. Five of five fits and all ten named starts converged, with zero correctness failures. Summary exit code is zero. Curie's independent dense reconstruction passed all five fit evaluations and 30 covariance transformations. Maximum fixed-metric relative differences were G 7.88201e-6 and R 7.99561e-6. Full artifacts and verification code/log are retained under `fa-unit-order-20260930/`; panel/population acceptance remains open. After-task report: `docs/dev-log/after-task/2026-09-30-fa-unit-order-diagnostic.md`.
