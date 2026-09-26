# 2026-09-26 pin MV PE recovery Y (Julia 1.13 RNG)

## Commands

```sh
cd ~/local-scratch/lanes/HSquared.jl-237-recovery
/Users/z3437171/.juliaup/bin/julia +1.10 --startup-file=no --project=. -e 'using HSquared; include("test/test_multivariate_repeatability.jl")'
/Users/z3437171/.juliaup/bin/julia +1.13 --startup-file=no --project=. -e 'using HSquared; include("test/test_multivariate_repeatability.jl")'
```

## Outcome

- Julia 1.10.12: 37 + 8 pass (recovery 11.7 s)
- Julia 1.13.0: 37 + 8 pass (recovery 13.0 s)
- Prints `G0_P0_RECOVERY_PINNED` and `PE_AWARE_NOT_ABSORBED`
- Version stays 0.9.0; `public_covered_count` stays 7; no covered flip

## Claim boundary

The CI gate loads the committed Julia 1.10 phenotype. A live
`MersenneTwister(20260926)` draw changes between 1.10 and 1.13; A and Ainv
stay identical. The 1.13 live draw put the REML mode near a G/P swap
(`G11 ≈ 0.577`, `P11 ≈ 1.057`); `ll(G0, P0)` still beat `ll(P0, G0)`. Engine
packing is unchanged. The multi-seed `|bias| <= 2*MCSE` screen stays in
`sim/phase4_multivariate_repeatability_recovery.jl` and remains
Julia-version-specific.
