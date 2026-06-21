# 2026-06-20 Genetic-GLLVM consumability: per-trait families in REML + GeneticGLLVMFit

- **Goal:** add per-trait family threading to `fit_gllvm_laplace_reml` + a typed
  `GeneticGLLVMFit` wrapper with extractor methods (`genetic_covariance`, `breeding_values`,
  `latent_structure`, `loglik`). No new exported symbols. Validation_status() must stay 41.
- **Active lenses:** Emmy (struct design, extractor contract) + Gauss (scalar-path
  numeric invariance) + Rose (claim-vs-evidence gate).
- **What landed (internal):** `GeneticGLLVMFit` struct (9 fields, same as former
  `NamedTuple`); four typed extractor methods on the struct; `fit_gllvm_laplace_reml`
  signature widened to `Union{ResponseFamily, AbstractVector}` for `family`; objective
  closure passes `family` (scalar or vector) through unchanged to
  `gllvm_laplace_marginal_loglik`. All prior field access (`fit.converged`, etc.) unchanged.
- **TDD:** new testset appended to `test/runtests.jl` — 19 assertions:
  (a) `[Poisson, Gaussian]` fit converges + finite loglik + right shape;
  (b) uniform-vector family == scalar fit `genetic_covariance` (exact equality);
  (c) `genetic_covariance(fit)` → `Matrix{Float64}`, size (2,2), PSD;
      `breeding_values(fit)` → `Matrix{Float64}`, size (8,1);
      `latent_structure(fit)` → NamedTuple with `:communality`, all `≈ 1.0`;
      `loglik(fit)` → finite + equals `fit.loglik`;
  (d) the `K=1,T=1` Poisson REML spot-check: result `isa GeneticGLLVMFit`, converged,
      right shape, `uniqueness === nothing`.
- **Pkg.test() result:** ALL PASSED (full suite including all prior GLLVM testsets).
- **validation_status() = 41:** confirmed (`~/.juliaup/bin/julia --project=. -e
  'using HSquared; println(length(validation_status()))'` → `41`).
- **docs/make.jl:** exit 0 (Documenter build clean).
- **Rose audit:** CLEAN — no dispatch collision (struct method, not NamedTuple); no
  public surface change; PSD assertion correctly weakened to `>= -1e-12` for the rank-1
  low-rank case; `communality == 1.0` backed by the existing invariant; per-trait family
  claim is convergence-only (no recovery claim); honest status language throughout.
- **Honest status:** INTERNAL, EXPERIMENTAL; nothing promoted to covered;
  `validation_status()` = 41.
