# Design — Random regression / reaction norms roadmap (#54)

Date: 2026-06-20. Lane: Julia engine. Scoped by a parallel design workflow
(Henderson — MME; Falconer — quant-gen interpretation; Curie — tests). The two
returned designs converged on a **supplied-covariance-first** sequencing that
mirrors how the multivariate lane was built (descriptors + supplied-covariance MME
before REML). This note records the slice plan so later slices implement from a
vetted design.

## Convention (fixed)

Normalized Legendre basis `φ_n(t) = sqrt((2n+1)/2)·P_n(t)` on a standardized
covariate `t ∈ [-1, 1]` (Kirkpatrick/Meyer/Schaeffer; ASReml/WOMBAT). `K_g` is the
`k×k` genetic covariance among an animal's `k = order` random-regression
coefficients. `K_g` values are NOT comparable across normalization conventions —
state this in any future comparator slice.

## Slices

- **Slice 1 — descriptors (DONE, this PR).** `legendre_basis`,
  `standardize_covariate`, and supplied-`K_g` `rr_genetic_variance` /
  `rr_genetic_covariance_surface` / `rr_genetic_correlation_surface` /
  `rr_heritability`. Descriptive, supplied-covariance, no MME, no estimation.

- **Slice 2 — supplied-covariance RR MME (DONE).** `random_regression_mme(y,
  X, Phi, Z, Ainv, K_g, sigma_e2)` + `legendre_design`: the Henderson MME for the
  polynomial RR animal model with homogeneous residual. Random-effect design
  `W = face-splitting(Z, Phi)`
  (row `r` scatters `Phi[r,:]` into animal `a(r)`'s `k`-column block — **NOT**
  `kron(Z, I_k)`); genetic precision `kron(Ainv, inv(K_g))` (reuse the multivariate
  Kronecker assembly); level-major / coefficient-fastest `vec` ordering (pin with an
  asymmetric-`K_g` ordering test — the classic silent RR bug). Validate by (a) the
  `degree = 0` reduction to `henderson_mme` (scalar animal model) and (b) a dense
  marginal-GLS oracle `V = W (A ⊗ K_g) Wᵀ + σ²e I`. Returns per-animal coefficient
  vectors + curve metadata. Effort M.

- **Slice 3 — RR REML (DONE).** `fit_random_regression_reml(y, X, Phi, Z, Ainv)`
  estimates `K_g` (log-Cholesky, reuses `_chol_params_to_cov`/`_cov_to_chol_params`)
  and the homogeneous residual `σ²e` by dense REML (NelderMead on the marginal
  `V = W(A⊗K_g)Wᵀ + σ²e I`) — the direct analogue of `fit_multivariate_reml`. EBVs/β
  via the GLS BLUP form at the estimate. Validated by an INDEPENDENT dense marginal
  oracle (loglik at the estimate + beats-off-optimum), the degree-0 (`k=1`) reduction
  to `fit_sparse_reml` via `K_g[1,1] = 2σ²a` (equal `σ²e`, equal loglik at an
  interior-σ²a fixture), and BLUP/β agreement with `random_regression_mme` at the
  estimate (`V3-RR-REML` in `validation_status()`). Estimation caveats apply; `K_g`
  known-truth recovery + comparator parity (WOMBAT/ASReml/JWAS) remain deferred. No
  permanent-environment term; homogeneous residual only.

- **Later.** Eigen-function (covariance-function) decomposition of `K_g`
  (Kirkpatrick & Heckman — carries the same rotation/interpretation gate as the FA
  convention); curve-valued EBV trajectories + PEV/reliability; heterogeneous /
  function-valued residual + permanent-environment term; spline/B-spline bases; the
  R-facing `rr(covariate, degree)` model-spec + bridge payload (coordinate with the
  R twin); sparse/large-pedigree path.

## Honesty

Every slice states "supplied covariance / descriptive" until slice 3; no
selection-response, fitting, or R-facing claim before the matching slice. The
eigen-function decomposition is gated on the rotation/interpretation convention
(parallels FA #42).
