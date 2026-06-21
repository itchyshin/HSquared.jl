# After-task — Genetic-GLLVM consumability: per-trait families in REML + GeneticGLLVMFit

Date: 2026-06-20. Lane: Julia engine (`HSquared.jl`). Branch:
`julia/gllvm-consumability`. Issue: #50 slice 3 consumability additions.

## Summary

Landed two consumability improvements to `fit_gllvm_laplace_reml` (internal,
`src/genetic_gllvm.jl`), with 19 new passing assertions:

**(1) Per-trait families threaded through REML.** The `family` parameter of
`fit_gllvm_laplace_reml` was widened from `ResponseFamily` to
`Union{ResponseFamily, AbstractVector}`. The marginal (`gllvm_laplace_marginal_loglik`)
already supported per-trait vectors; this change threads them through the REML
optimizer's objective closure. The scalar path is numerically unchanged: a uniform
vector of `T` identical families gives exact `genetic_covariance` equality to the
scalar-family fit on the 8-animal fixture (same optimizer seed, same NelderMead path).
A mixed `[PoissonResponse(), GaussianResponse(1.0)]` fit on a 2-trait response
converges on the same fixture.

**(2) GeneticGLLVMFit fitted-object wrapper.** `fit_gllvm_laplace_reml` now returns a
typed `GeneticGLLVMFit` struct (internal, `src/genetic_gllvm.jl`) instead of a bare
`NamedTuple`. The struct carries the same nine fields (`loglik`, `genetic_covariance`,
`latent_structure`, `uniqueness`, `beta`, `breeding_values`, `n_latent_factors`,
`converged`, `iterations`). Typed extractor methods dispatching on the struct are
defined: `genetic_covariance(fit)`, `breeding_values(fit)`, `latent_structure(fit)`,
`loglik(fit)`. All dispatch on `GeneticGLLVMFit` (not `NamedTuple`), so they do not
collide with the multivariate `NamedTuple` extractors in `multivariate.jl` or the
`AnimalModelFit` extractors in `likelihood.jl`. Field access `fit.fieldname` continues
to work unchanged. The struct and its extractors are INTERNAL (not exported), mirroring
`fit_gllvm_laplace_reml` itself.

## Definition of Done

- implementation — widened `family` signature + `GeneticGLLVMFit` struct + four
  extractor methods in `src/genetic_gllvm.jl`. No other source files changed.
- tests — new testset "Genetic-GLLVM consumability: per-trait families in REML +
  GeneticGLLVMFit (#50)" appended to `test/runtests.jl` (19 assertions): (a)
  `[Poisson, Gaussian]` fit converges; (b) uniform-vector family equals scalar fit
  (exact `genetic_covariance`); (c) extractor methods return expected field types and
  shapes (`GeneticGLLVMFit`, `Matrix{Float64}`, PSD, right size, `communality == 1`
  for low-rank); (d) prior REML tests still pass with the new return type. Full
  `Pkg.test()` green (21 prior REML assertions + 19 new = 40 across the two testsets).
- documentation — docstring on `GeneticGLLVMFit` + four extractor docstrings;
  `fit_gllvm_laplace_reml` docstring extended to describe per-trait families and the
  new return type. `V6-GGLLVM-REML` row extended in `capability-status.md`,
  `validation-debt-register.md`, and `src/validation_status.jl`.
- check-log — `docs/dev-log/check-log.d/2026-06-20-gllvm-consumability.md`.
- after-task — this file.
- capability-status — `V6-GGLLVM-REML` row extended; `GLLVM-style animal models`
  planned row updated to note per-trait families + extractor surface now exist.
- validation-debt — `validation_status()` = 41 (unchanged); no new row added.
- Rose audit — see below.
- clean local checks — `Pkg.test()` green (all tests passed); `docs/make.jl` exit 0.
- CI — not yet pushed; a no-op push re-triggers Actions on the clean checkout if needed.

## Rose audit (claim-vs-evidence)

Rose lens applied:

1. **Per-trait family claim.** The capability claim is narrow and tested: uniform
   vector == scalar (exact equality asserted), mixed Poisson+Gaussian converges
   (asserted). No recovery or comparator claim made for per-trait families beyond
   convergence — honest, since no recovery study has been run with mixed families.

2. **GeneticGLLVMFit extractor claim.** The PSD claim for `genetic_covariance` is
   weakened to `eigvals >= -1e-12` (not strict positive definiteness), which is correct
   for a rank-1 low-rank fit whose smallest eigenvalue is numerically zero. The
   `communality == 1` claim for the low-rank path is exact and backed by the existing
   `genetic_gllvm_descriptors` invariant (Ψ absent ⟹ communality = 1.0 exactly).

3. **No dispatch collision.** Verified: `breeding_values(::GeneticGLLVMFit)` dispatches
   on the concrete struct, not on `NamedTuple`; the multivariate
   `breeding_values(::NamedTuple)` and `breeding_values(::AnimalModelFit)` are
   unaffected. `genetic_covariance` is not exported from `HSquared.jl` (not in the
   export list); it is internal. No public surface change.

4. **validation_status() = 41.** Confirmed. No new row was added; the `V6-GGLLVM-REML`
   row was extended in place.

5. **Honest status language.** All three updated documents use "per-trait families" and
   "extractor surface" language consistently, without promotion to covered.

No blockers. Honest.

## Claim boundary

INTERNAL, EXPERIMENTAL. `fit_gllvm_laplace_reml` and `GeneticGLLVMFit` are not
exported. The per-trait family path exercises the existing marginal — no new numerical
code was written. The extractor surface is a struct wrapper for field access with typed
dispatch — no numerical claim beyond what the existing REML validation already covers.
Nothing promoted to covered.

## Next

Remaining open items on `V6-GGLLVM-REML`: FA(+Ψ) recovery study, Bernoulli bias
correction or many-trial path (Binomial route already demonstrated), unbalanced /
missing-record support, and an external GLLVM.jl/gllvmTMB comparator run (the gap
between the current internal validation and a public claim).
