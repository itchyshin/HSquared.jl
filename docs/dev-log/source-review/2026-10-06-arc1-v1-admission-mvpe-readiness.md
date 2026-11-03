# Exact-source review: Arc 1 v1 admission and MV+PE readiness

Date: 2026-10-06  
Review: independent Astra read-only source review  
Scope: Arc 1 policy route and the next bounded ordinary-start MV+PE study candidate. No files were changed by the reviewer; no fit, simulation, or seed was used.

## Arc 1 v1 route

The approved Arc 1 plan selects `optimizer_policy="arc1_v1"`. Current implementation agrees:

- `LOOP/lanes/arc1-gaussian-reliability-20261002/GOAL.md` and `tools/arc1_manifest.py` freeze v1 and the optimizer schedule.
- `sim/arc1/execute_attempt.jl` requests v1 for each FA attempt.
- `src/fa_rank_selection.jl` dispatches v1 independently from the additional v2 path.
- `sim/arc1/reference.jl` uses the original exact objective and v1-default ordinary reference optimizer.
- Run admission binds the protocol hash and discovered source set. Because the approved route is fixed to v1, a separate selectable-policy field is not required for this programme.

The v2 engine path is outside this plan. Its tests and results must not be substituted for v1 study evidence. The retained G1, G6, and G7 receipts support the reviewed source snapshot, but do not establish G2 reliability. Before G2 pilot or confirmation execution, create a fresh exact cell/source/runtime/seed admission and retain every failure and required ordinary/reference comparison.

Reviewed source hashes:

| Julia file | SHA-256 |
| --- | --- |
| `LOOP/lanes/arc1-gaussian-reliability-20261002/GOAL.md` | `39ec2b4251722c4d9017b8680d005a636eccf9a6cf84dbc16e8111a221446e0d` |
| `tools/arc1_manifest.py` | `0c437d8b4950dbaad7df0cd1f745e0ef5e15ff55c3e2720772211a2a7f481c55` |
| `sim/arc1/execute_attempt.jl` | `a6de6601c4cefb66e95124311c0d273b10a8f3752d62c259ddc8b008a4bbb7c1` |
| `sim/arc1/reference.jl` | `3fa05682b1dda61be259f21a8275a113337f39a3db007c41a69995bfe573b080` |
| `src/arc1_fa.jl` | `01a47052c2a0fb658a9ab054ade22f26af6454a000632c95e845e31783931906` |
| `src/fa_rank_selection.jl` | `61eb542bf34796c0222e1a8df7550de5dfdb03f3bb855c63a43c243f6bbbeda0` |

## Ordinary-start MV+PE readiness

The existing route is not ready for an ordinary-start study freeze:

1. The Julia screen at `sim/phase4_multivariate_repeatability_recovery.jl:110` and R helper at `tests/testthat/helper-237-mvpe.R:90` initialize from truth matrices. The engine's empirical-data start is separate and was not exercised by that screen.
2. The screen summarizes converged seeds only, uses `|bias| <= 2 MCSE`, retains only three rounded values per seed, and exits successfully even when it prints `GATE_FAIL`. This cannot support failure-inclusive, independently reconstructable acceptance.
3. The current comparator covers selected G/P diagonal elements only, uses absolute tolerance 0.35, permits dependency/layout skips, and follows the truth-started helper. It does not establish whole-covariance, likelihood, or fitted-payload agreement.

Before an execution freeze, the protocol needs an explicit ordinary-start rule; bounded DGP and record layout; fresh development, pilot, and confirmation seeds; attempt and failure denominators; recovery estimands and thresholds; complete per-attempt output; exact comparator target, objective, and scaling; package versions; mandatory non-skipped Julia/R checks; and a success-only aggregate checker. The June multivariate protocol excludes comparator and R-payload inference, so it cannot fill these gaps implicitly.

Reviewed MV+PE input pins:

| File | SHA-256 |
| --- | --- |
| Julia `src/multivariate.jl` | `2947cb72d8850593a62ca41e84c8125a52194a12730d0ad2b72b4b3d57c474a9` |
| Julia `src/bridge_payload_v2.jl` | `9d389444008a25ddfb3ba140836bab5a3d2c8ebfb94052424d8d1ac6c0c5a3e9` |
| Julia `sim/phase4_multivariate_repeatability_recovery.jl` | `50243cbd1a6765b1cee16811493cf94df452756729dfac8db51564ba749156b2` |
| Julia `test/test_multivariate_repeatability.jl` | `276017e88ebf8b266d3b613166cf43ed81f7ae31144c73e79c35a7a8e13a6d87` |
| Julia fixture `test/fixtures/hs237_mv_pe_recovery/Y.csv` | `d911ffff4f7141f94fab8ef077efcfc59b961aefd0d859843138f21fb7d24ca5` |
| Julia fixture `test/fixtures/hs237_mv_pe_recovery/generate.jl` | `dbcdd2dec1a4f8959865f82cc7cef7cd58b49ac37334f66f44e4bb4bb75d7220` |
| R `R/julia-bridge.R` | `3118add8b633a3297689f1ff282953a852ecb5e2cfd22129fdad62a0319fdecc` |
| R `R/hsquared.R` | `142bd07756b84641fdf63a348f55fda038641c9b11255dd3060a7394dafe758b` |
| R `R/model-spec.R` | `894ad7d2eccee2c1a3eef4416a737916ffb03f39e0e189c6d5e4115fb5a07149` |
| R `tests/testthat/helper-237-mvpe.R` | `f1de38213390f373cb7e9e0ae7339c177dd71962efd45a23b2d32ca6df83a02b` |
| R `tests/testthat/test-multivariate-permanent-recovery-237.R` | `b545c5daeb395e254db8fe89e8c6deda9f00e312387ba7ca34e28838797abb7e` |
| R `tests/testthat/test-multivariate-permanent-comparator-237.R` | `666397491d6961122cadb513169ecbb975941afada8d4ac5c2ff3a425999099c` |
| Protocol `docs/dev-log/decisions/2026-06-14-multivariate-recovery-calibration-protocol.md` | `3f365d1f357f9a6041c9c60a55cffdf71ad2429474e6f2c99b8d82d7bb494309` |

These are review inputs. The freeze still needs transitive includes, tests and helpers, the Julia environment, and installed R/comparator dependency identities.

## Next bounded action

Prepare the ordinary-start MV+PE protocol and complete paired-source inventory for independent review. Preparation and review are estimated at 30–60 minutes; this is not a measured fit or campaign runtime. Run no fits during this action. After protocol and source acceptance, measure a bounded timing pre-run before estimating any campaign. A campaign projected above three hours requires its measured pre-run and separate approval.

## Editorial check

Style: 2/10, moderate confidence; this is a source-audit record with claims tied to exact files and hashes. Evidence/repair: the sentence that v2 tests do not establish G2 is scoped to the approved v1 route; no change needed. Gates: science = pass for the route-identity finding after independent review, unknown for G2 reliability; facts = pass within the source hashes and receipt results checked; references = not applicable because no external literature claim is made. Provenance: self-review, 2026-10-06; current source and planning examples were seen.
