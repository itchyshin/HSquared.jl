# 2026-06-20 Genetic-GLLVM per-trait response families (#50 extension)

- **Goal:** generalize `gllvm_laplace_marginal_loglik` to accept a `Vector` of
  `ResponseFamily` objects (one per trait column of `Y`), applying `families[t]` to
  all records of trait `t`. Keep the single-family scalar path EXACTLY unchanged.
- **Active lenses (perspectives, not running agents):** Gauss (Newton loop), Karpinski
  (dispatch overhead), Noether (equation consistency), Curie (test design), Rose
  (claims).
- **TDD:** three-assertion testset written and confirmed ERROR before implementation.
  Implementation then made all 8 assertions pass.
- **Gates (8 assertions, "Genetic-GLLVM per-trait response families" testset):**
  (1) `Vector` of 2 identical `PoissonResponse()` == scalar `PoissonResponse()` EXACT
  (same loglik bit-for-bit); converged; shapes `(1,2)` β and `(q,2)` g. (2) Mixed
  `[PoissonResponse(), GaussianResponse(1.2)]` converges, finite loglik, correct shapes.
  (3+4) wrong-length vectors (length 1 and length 3 for `T=2`) throw `ArgumentError`.
- **Pkg.test():** `Testing HSquared tests passed`; all testsets pass including
  `validation_status()` 41 rows / `[end].id == "V6-GGLLVM-REML"`.
- **Docs:** `docs/make.jl` → `build complete in 4.13s.`
- **Honest status:** `V6-GGLLVM-MARGINAL` extended in capability-status, debt-register,
  and validation_status.jl; `V6-GGLLVM-REML` debt-register updated to note REML is
  still single-family. Row count: 41 (unchanged). Nothing covered.
- **`fit_gllvm_laplace_reml`:** left single-family (scalar `family` path unchanged);
  per-trait families available via `gllvm_laplace_marginal_loglik` directly.
