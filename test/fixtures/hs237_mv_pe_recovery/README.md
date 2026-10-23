# hsquared #237 multivariate animal+PE recovery pin

`Y.csv` is the two-trait phenotype matrix for the known-truth screen in
`test/test_multivariate_repeatability.jl`.

It was drawn on **Julia 1.10.12** with `MersenneTwister(20260926)` and the
same half-sib pedigree the test rebuilds (8 sires / 16 dams / 48 offspring,
4 records). Julia 1.13 changed both `randn()` and `MersenneTwister(Int)`
uniforms, so a live seed is not a pin. The 1.13 stream put the REML mode
near a G/P swap (`G11 ≈ 0.577`, `P11 ≈ 1.057`) even though `A` is unchanged
and `ll(G0, P0)` still beats `ll(P0, G0)`.

Regenerate only with `julia +1.10 --project=. test/fixtures/hs237_mv_pe_recovery/generate.jl`.
Experimental; no covered flip.
