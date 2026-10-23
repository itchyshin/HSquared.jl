# 2026-09-29 Wave 4 genomic symmetry and overflow follow-up

## Candidate and exact files

- Julia source: `src/genomic.jl`, SHA-256 `8fb4965f398177eb4ab4160036e92070acc83110a0d987ecf6b3e3719e1e0b3d`.
- Main regression file: `test/wave1_numerical_contracts.jl`, SHA-256 `c0e21b925bf59b4d48f2b22afcbf7740a6df081c78494d8ad9787a4d578b8c9a`.
- Single-step regression file: `test/test_212_engine_controls.jl`, SHA-256 `9c3b9d4bd8d075ff3931d59f3e909e9983c98ebe8bf02d7908d38be1950a7d6b`.

## Findings and changes

Two independent numerical reviews found and helped close these component defects:

1. Constructor documentation had attached to the private symmetry helper. The helper now precedes the public constructor docstring; the API-docstring property test verifies the public binding.
2. APY accepted finite values that overflowed during Float64 conversion or ridge addition. It now validates converted `G`, converted ridge, and the regularized core. Tests cover finite `BigFloat` values that overflow Float64 and regularization overflow.
3. A matrix-wide symmetry tolerance masked asymmetry in a small block when another block had much larger values. The single-step helper now checks each off-diagonal pair relative to that pair and symmetrizes in place. A mixed-scale counterexample is registered.
4. Weighted genomic construction could produce an infinite cross-product even when its denominator stayed finite. The constructor symmetry helper now rejects nonfinite results. The regression asserts the fixture denominator is finite and its cross-product overflows before checking constructor rejection.

The APY conditional-variance cutoff remains a scale-relative cancellation heuristic without a conditioning-aware error guarantee. The APY result is dense and validation-scale. Review noted a redundant second finite scan on its output; no performance claim or benchmark is made.

## Verification and review

- Focused Wave 1 numerical contracts: 126/126.
- Constructed genomic relationship symmetry and inverse tests: 16/16.
- APY finite-input and scale tests: 8/8.
- APY partial-core formula and Schur-cutoff tests: 5/5, including an independent block-formula reference and cases below and above the cancellation threshold.
- Focused single-step and API-docstring tests: 25/25 and 3/3.
- Full Julia 1.10 `Pkg.test()` on the final implementation source: exit 0, ending `Testing HSquared tests passed`; captured in `/private/tmp/hsq-pkg-test-20260929-final.log`. The later weighted-overflow and partial-core test additions passed focused Wave 1 runs.
- `julia --project=docs docs/make.jl`: exit 0; captured in `/private/tmp/hsq-docs-make-20260929-final.log`. It emitted existing warnings about docstrings not listed in canonical docs blocks, local deployment detection, and VitePress defaults; no deploy occurred.
- `git diff --check` passed for the three code/test files. `bash tools/preamble_cap.sh` passed at 11,024/14,000 bytes.
- Gauss and Karpinski reviewed the exact implementation hash. Both found no remaining component-level correctness blocker. This is not a whole E1 signoff. Neither reviewer ran the package suite or docs build.

## Limits

This follow-up closes only the reviewed CPU genomic constructor, APY, and single-step boundary findings. It does not close Wave 4, E1, FA gate A2, validation/bridge gate V3, or the twin programme. No capability row, covered count, release status, or GPU status changed. No simulation, benchmark, CI dispatch, merge, release submission, registry submission, or tag occurred.
