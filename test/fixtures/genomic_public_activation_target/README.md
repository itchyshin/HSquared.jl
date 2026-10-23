# Genomic public-activation target

Deterministic cross-twin fixture for design contract 44. Seed `20270701` creates
120 genotyped individuals and 600 hard-call markers. Ninety individuals have
phenotypes, the first 30 have a second record, and 30 genotyped individuals have
no phenotype. The fixed design contains an intercept and one record-level
covariate.

The fixture freezes the sample-frequency, unweighted VanRaden method-1
construction, `K = G + 0.01I`, `Q = inv(K)`, every symbolic intermediate, the
engine-owned provenance fingerprints, and one fitted Gaussian REML target.
It is route-identity evidence, not population robustness, interval calibration,
or production-scale evidence.

The kernel and precision fingerprints in `expected_fit.csv` record the exact
generator-run Float64 values. A different BLAS/LAPACK process may differ in the
last bit while reproducing `expected_construction.csv` to tolerance; the live
test therefore requires exact marker-versus-supplied-precision fingerprints
within one engine run and tolerance-based agreement across runs.

Regenerate from the repository root:

```sh
julia --project=. test/fixtures/genomic_public_activation_target/generate.jl
```
