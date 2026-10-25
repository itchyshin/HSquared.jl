# HSquared.jl #352 animal + permanent-environment recovery fixture

`pedigree.csv` (300 animals: 100 founders, 200 offspring) and `y.csv` (900
records, 3 per animal) are the known-truth data for
`test/test_issue_352_pe_recovery.jl`. Truth: Va = 1.0, Vpe = 0.6, Ve = 0.8,
intercept 2.0. Breeding values are gene-dropped.

Drawn on **Julia 1.10** with `MersenneTwister(20261026)`. Julia 1.13 changed
`randn()` and `MersenneTwister(Int)` uniforms, so a live seed is not a pin; the
test reads these CSVs. Seed note: the first seed tried, 20261025, gave a Va
estimate 2.6 standard errors below truth (a tail draw), so the next seed was
taken without a further search. The fixture is one draw, so the test is a
recovery smoke gate, not a bias or coverage claim.

Regenerate only with
`julia +1.10 --project=. test/fixtures/issue_352_pe_recovery/generate.jl`.
