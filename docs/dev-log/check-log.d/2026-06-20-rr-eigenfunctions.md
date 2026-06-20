# 2026-06-20 Random-regression eigen-function decomposition (#54 slice 4)

- **Goal:** add the deferred Kirkpatrick covariance-function eigen-function
  decomposition of a supplied random-regression coefficient genetic covariance
  `K_g` (`random_regression.jl:23` was the explicit DEFERRED marker). Descriptive,
  supplied-covariance, rotation-invariant — no estimation, no fitting/perf claim.
- **Active lenses:** Gauss (numerics) + Kirkpatrick (genetic axes / eigenfunctions)
  + Noether (math/code consistency) + Rose (claims). Curie (deterministic gates).
- **Spawned subagents:** none (the earlier 3 Explore agents were for the genetic-GLLVM
  scout, a separate slice).
- **What landed:** `rr_eigenfunctions(K_g, ts)` (exported) — eigen-decomposes `K_g`
  via `genetic_pca` (descending eigenvalues, sign-canonicalized Legendre-coefficient
  eigenvectors) and evaluates the eigenfunctions `ψ_j(t)=φ(t)ᵀv_j` over the Legendre
  design at `ts`, returning `(covariate, eigenvalues, eigen_coefficients,
  eigenfunctions, variance_explained)`. Reuses `genetic_pca` (evolvability.jl),
  `_check_kg`, `_rr_design`/`legendre_design`. ~25 LOC + docstring.
- **TDD:** test written first (`test/runtests.jl`, new testset); RED proven via a
  standalone `using HSquared; rr_eigenfunctions(...)` → `UndefVarError`; then the
  minimal implementation.
- **Verification (deterministic, RNG-free):**
  - `~/.juliaup/bin/julia --project=. -e 'using Pkg; Pkg.test()'` → **passed**;
    the new testset `Phase 3 random-regression eigen-function decomposition
    (#54 slice 4)` is **17/17 Pass**; whole suite green.
  - Gates pinned: `eigenvalues`/`eigen_coefficients == genetic_pca(K_g)` (descending);
    eigenfunctions `== Φ·V`; spectral reconstruction `ΦK_gΦᵀ = Ψ·diag(λ)·Ψᵀ ==
    rr_genetic_covariance_surface` (atol 1e-10); `variance_explained == λ/Σλ`, sums to
    1, descending; **eigenfunction orthonormality on `[-1,1]`** (trapezoid
    `∫ψ_iψ_j = δ_ij`, atol 1e-3 on a 4001-pt grid); diagonal-`K_g` eigenvalues =
    sorted(d) desc; rank-1 `K_g` → all variance on axis 1; guards (indefinite /
    non-square `K_g`, `|t|>1`).
  - `docs/make.jl` run locally (api.md `@docs` block extended with
    `rr_eigenfunctions`); see session log.
- **Honest status:** updated `capability-status.md` (V3-RR-DESC) and
  `validation-debt-register.md` (V3-RR-DESC) — eigen-function decomposition moved
  from "deferred" to landed, with the gate list; nothing promoted to covered. The
  in-code `validation_status()` ladder is unchanged (descriptors are folded into the
  register; `V3-RR-REML` remains the in-code RR row) — 38 rows.
- **Claim boundary:** supplied-covariance, descriptive, rotation-invariant; `K_g`
  not estimated; no curve-valued EBV PEV, no R `rr()` model-spec, no comparator.
