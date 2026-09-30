# 2026-09-29 Wave 4 single-step symmetry tolerance follow-up

## Scope and pinned candidate

- Baseline: integrated candidate at `a7ca8ed557b23ec23c8486365e97a7bac4b71c16`.
- Final `src/genomic.jl` SHA-256: `72423bd1523dbcf25ef55081d89328c12004797637d8506e17e5ff574a87c021`.
- Final `test/test_212_engine_controls.jl` SHA-256: `d3617990b66813a67b63d075d8d06e1988fdeb0ae7b5f46017d6dec15e21f302`.
- Exact helper span: `_single_step_symmetric_finite_matrix`, formerly using `1e-10 * max(1, opnorm(M, Inf))` as an absolute tolerance.

## Finding and repair

The previous tolerance admitted materially asymmetric relationship matrices when their entries were much smaller than one, then silently averaged them. An independent deterministic probe showed that `G = [1e-12 2e-13; 4e-13 1e-12]` passed despite a 20% relative off-diagonal mismatch.

The helper now scales the finite matrix by its largest absolute entry and checks the maximum normalized asymmetry against `1e-10`. It averages accepted pairs as `a + (b - a)/2`, avoiding overflow for finite values near `floatmax`; the normalized symmetry condition bounds the difference used by this expression. Exact zero matrices pass the symmetry check and remain subject to downstream positive-definiteness validation.

## Verification and review

- TDD red: the tiny asymmetric fixture did not throw before the repair.
- Focused `test/test_212_engine_controls.jl`: 24/24 assertions pass, including tiny and large asymmetric inputs, a tiny symmetric positive-definite control, and a finite `1e308` symmetric control.
- Full Julia 1.10.0 `Pkg.test()` on the final overflow-safe averaging edit passed, ending `Testing HSquared tests passed`. The existing project/manifest mismatch warning remains; no resolve or update was run.
- `git diff --check`: passed.
- Independent numerical re-review of the final source/test hashes passed. It confirmed normalized asymmetry, overflow-safe averaging, the four scale controls, and finite positive-definite output for the tiny symmetric single-step case.

## Limits

This closes only the scale-dependence finding in the single-step symmetry validator. It does not close Wave 4, E1, the separate FA review gate A2, or R/bridge validation V3. No capability status, covered count, release status, or GPU status changed. No simulation or external comparator was run.
