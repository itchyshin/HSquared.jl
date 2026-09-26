# After-task: pin MV PE recovery phenotype (hsquared #237)

Date: 2026-09-26
Lane: Julia `cursor/237-mv-recovery-jl` at `~/local-scratch/lanes/HSquared.jl-237-recovery`
Fence: experimental 0.9.0 / public_covered_count 7; no covered flip; REGISTERED=no

Active lenses: Shannon, Curie, Gauss, Rose
Spawned subagents: none
Current lane: Julia recovery (do not touch `cursor/237-mv-permanent-jl`)

## What landed

`test/fixtures/hs237_mv_pe_recovery/Y.csv` is the Julia 1.10.12 phenotype
(`Y11 = 1.6723615736876525`, `Ysum = 1110.1019795549014`, 288 rows) for the
known-truth G0/P0 screen. The test now loads that file and keeps the split
gates `G11 ≈ 1.0` and `P11 ≈ 0.5` at `atol = 0.25`.

This supersedes `461e9eea`, which gated the G0+P0 sum instead of the split.
The engine packing (G0 then P0 then R0) and `V` construction did not change.

## Root cause

Julia 1.13 changed both `randn()` and `MersenneTwister(Int)` uniforms.
`A`, `Ainv`, and the Cholesky factor of `A` are bit-identical across 1.10.12
and 1.13.0 (`A_sum = 252`). A live seed is therefore not a pin.

On the 1.13 live draw the MLE sat near a G/P swap
(`Ghat11 = 0.5768773581487859`, `Phat11 = 1.0569704926193966`), matching the
failed Julia 1 ubuntu/windows jobs. `ll(G0, P0)` still beat the exact
`(P0, G0)` swap by 0.66, so the likelihood is not swapped. The same seed on
1.10 recovered the split and is the committed pin.

## Checks

Focused file only (not full `Pkg.test()`):

- Julia 1.10.12: 37 + 8 pass
- Julia 1.13.0: 37 + 8 pass

## Claim boundary

Experimental recovery pin. No covered flip. The gated estimator is
`fit_multivariate_repeatability_reml`; animal-only `fit_multivariate_reml`
is the absorption contrast only. The multi-seed screen in
`sim/phase4_multivariate_repeatability_recovery.jl` is Julia-version-specific
and sits outside this CI gate.
