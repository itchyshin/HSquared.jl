# Current bounded Julia source dispositions

Updated after independently accepted hosted-platform fixes. Prior inventories are preserved verbatim in the adjacent before-hosted-platform-fixes files.

All 24 tracked core source files have baseline review dispositions and independently accepted deltas. Fresh local package and documentation checks pass; current-head hosted CI and landing remain pending.

Source aggregate: `59d4a803e4d290a840927b4bce26ea4722f4404c009c171d173ba0c300c7d76e`.
Runner: `27b7adbfe0b1c8d397e9041710fe713410d6692d9ef8ebf50af4354a0429adf3`.

| File | Lines | SHA-256 | Baseline disposition |
| --- | ---: | --- | --- |
| src/HSquared.jl | 258 | `5c6c4c84e372e9adb75dd43d326e7603243286313c788cd3c98a599d1468eaf0` | docs/dev-log/source-review/2026-09-30-support-source-reattestation.md |
| src/backends.jl | 167 | `b22f118ea8aeba5dceb80918ee40a3f7d698211c69e91ee6c7e6c5b718b10cf9` | docs/dev-log/source-review/2026-09-30-support-source-reattestation.md |
| src/bridge_payload_v2.jl | 930 | `9d389444008a25ddfb3ba140836bab5a3d2c8ebfb94052424d8d1ac6c0c5a3e9` | docs/dev-log/source-review/2026-09-30-bridge-payload-complete-current-review.md |
| src/control.jl | 107 | `c466b4cf9e33fcafe8b4821791af54cc559a2dab78755fa759f387f6601e6b3f` | docs/dev-log/source-review/2026-09-30-support-source-reattestation.md |
| src/data.jl | 1253 | `5ac87d115a0b8c41822f38cfb54cbdffc3f298578bbf1ddb9aec0edc6c823012` | docs/dev-log/source-review/2026-09-30-data-complete-current-review.md |
| src/errors.jl | 22 | `6ebb3635c308097213b1581fae26e94089969f34a07cbf5b735a5ee945d44fba` | docs/dev-log/source-review/2026-09-30-support-source-reattestation.md |
| src/evolvability.jl | 321 | `4dc5b5e0b1f51abaa97bdee77b3205129470ca5107628390cf3ef1578452306f` | docs/dev-log/source-review/2026-09-30-evolvability-complete-current-review.md |
| src/genetic_gllvm.jl | 750 | `8392d7964f72d18278db130d5afd5ada30778233581bfe4090031b3fac3b4f71` | docs/dev-log/source-review/2026-09-30-gllvm-residual-contract-review.md |
| src/genomic.jl | 3011 | `a861e0336eb8b793c2dccc8bcbdf8ff920ccc0cfa4f2f8a217bc165a33306b17` | docs/dev-log/source-review/2026-09-30-genomic-complete-current-review.md |
| src/gpu_ext.jl | 90 | `b5bfbe73e12363cb7c9d518841006554c220d93038294a1826faefc1a1b2767f` | docs/dev-log/source-review/2026-09-30-support-source-reattestation.md |
| src/iterative_solve.jl | 1484 | `e1b50131c5e38b59a200925e0ff2f2377fecc7c5e4f0c63a90fe33261dbf2133` | docs/dev-log/source-review/2026-09-30-iterative-complete-current-review.md |
| src/likelihood.jl | 4876 | `9e4b7b422f0ba6daac41b39aadf2172b56fc1879b91563ca40d2df9e374d9f11` | docs/dev-log/source-review/2026-09-30-likelihood-first-wave-current-review.md |
| src/model_spec.jl | 104 | `d49de74e3990e18e73db37bab9b3019f46dcaa29c4f7102fc3f53fe60fa9f5fb` | docs/dev-log/source-review/2026-09-30-support-source-reattestation.md |
| src/multivariate.jl | 1933 | `f975657ef43d86045171a9265e5536370043a46fc72880a3e80ee87fcad699c2` | docs/dev-log/source-review/2026-09-30-multivariate-complete-current-review.md |
| src/nongaussian.jl | 1918 | `3a43d7f1ebbc2c6b05bfe20306a2e48cfd24c9bb1bcbacf999200e800a4a6bd6` | docs/dev-log/source-review/2026-09-30-nongaussian-complete-current-review.md |
| src/pedigree.jl | 907 | `6f4661f1e64dd0c079595be5b754813ba66ea998fc301bdcbd5422c5cdf72f86` | docs/dev-log/source-review/2026-09-30-pedigree-complete-current-review.md |
| src/placeholders.jl | 26 | `e95f47efb13018fa8fc2fb7cbf6b08d4c4a1add8ca3b9c95b43ead259bf9955b` | docs/dev-log/source-review/2026-09-30-placeholder-exact-review.md |
| src/planned_terms.jl | 359 | `a47d953d72565f347db805b5d0c7bdc86d5440dedaa6454c674f6e48c9607d5c` | docs/dev-log/source-review/2026-09-30-support-source-reattestation.md |
| src/plotting_ext.jl | 61 | `e38c4d436d59bce93315eebc0296e6227fdd71990b25f2b4f608f302c458a569` | docs/dev-log/source-review/2026-09-30-support-source-reattestation.md |
| src/postfit.jl | 62 | `28486afa2c11adf38aeda6149d9b858f7968f751dbea34ef09174243d721adc3` | docs/dev-log/source-review/2026-09-30-support-source-reattestation.md |
| src/random_regression.jl | 564 | `91992a87f0c6b20101154ed000b1f993b062c73e9c032effa54923eda5ee6c33` | docs/dev-log/source-review/2026-09-30-random-regression-exact-review.md |
| src/sparse_bridge.jl | 87 | `f8a681b7491a002577747775fef26f486d53ab2b4b8def6f6071e7a5eb4c2427` | docs/dev-log/source-review/2026-09-30-support-source-reattestation.md |
| src/takahashi_selinv.jl | 475 | `3ac12ece1d095852f0937d63c97a03333665560a2c4876c138b4c547fec4e0ed` | docs/dev-log/source-review/2026-09-30-selinv-complete-current-review.md |
| src/validation_status.jl | 598 | `1d1d444bea3a5dc7a2dfccf5549b4d3082acfe3bf48761fe203a9d5f993c5316` | docs/dev-log/source-review/2026-09-30-validation-status-exact-review.md |

## Reviewed hosted-platform deltas

The likelihood delta resolves cancellation in endpoint-adjacent likelihood comparisons using the same eigen-context estimand. It preserves the strict positive-gain rule and all original tests. The solver delta verifies the true residual before stopping and restarts within the existing iteration budget. Requested tolerance and failure behavior are unchanged.

Signed independent reviews and complete author/replay archives are in docs/dev-log/prepared-fixes/2026-09-30-hosted-platform-remediation/. Original hosted failures, R landing and post-merge checks are in docs/dev-log/check-log.d/2026-09-30-hosted-platform-remediation/. Both numerical regression modules remain isolated. Two documentation readers use the supported Docs.doc API with REPL loaded, preserving their original assertions. Four empirical FA fit-outcome assertions are separately replaced by independently reviewed diagnostic/status oracles; all numerical source bytes remain unchanged.

The approved experimental outcome, covered count seven, fixed-rank scope, calibration/scaling debt and GPU/release exclusions are unchanged. The completed FA campaign is never restarted.
