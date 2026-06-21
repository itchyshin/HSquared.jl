# 2026-06-20 Binomial/Bernoulli profile-LRT σ²a interval

- **Goal:** close the `V6-BINOMIAL`/`V6-BERNOULLI` "no intervals" gap by extending the
  validated Poisson profile-LRT interval (`laplace_reml_interval`) to the other
  single-variance-component families. Accuracy/inference; pure reuse of the existing,
  validated `_profile_root` LRT-inversion machinery.
- **Active lenses:** Fisher (interval validity / honest-status) + Gauss/Noether
  (LRT inversion) + Rose (claims).
- **What landed (`src/nongaussian.jl`):**
  - `_resolve_single_family(family, n_trials)`: a shared helper resolving
    `:poisson`/`:bernoulli`/`:binomial` (+ scalar/vector `n_trials`) to the
    `ResponseFamily`. `fit_laplace_reml`'s single-component branch now calls it
    (DRY — the fitter and the interval can no longer drift). Refactor only; the
    existing fitter tests (31 scalar + 39 per-record) pass unchanged.
  - `laplace_reml_interval` generalized from `:poisson`-only to
    `:poisson`/`:bernoulli`/`:binomial` (same `n_trials` contract as the fitter,
    length/integer-validated); the LRT target now uses the resolved family.
    Docstring updated with the HONEST informativeness caveat.
- **The honest-status finding (initial claim CORRECTED by the adversarial review — see below):**
  - The interval is two-sided ONLY when `σ̂²a` sits clear of the flat near-zero region
    — NOT a property of "adequate trials". Scalar **Binomial** m=20 (`σ̂²a≈0.98`): two
    interior χ²₁ roots (`dev ≈ 3.841` at 95% / `2.706` at 90%). The SAME `yb` with a
    per-record vector (`σ̂²a≈0.37`): the LOWER endpoint clamps (only upper interior).
    Binary **Bernoulli**: doubly clamped/degenerate (`σ̂²a` runs to a box edge).
  - To make this honest at the API, the interval now returns
    `lower_clamped`/`upper_clamped`/`converged` flags (a clamp is exactly
    `_profile_root`'s non-crossing condition `target(bound) ≤ 0`), so a non-crossing
    endpoint is self-describing — not a silent finite triple mistaken for a CI.
  - `marginal = :variational` is REJECTED: the VA ELBO is a lower bound, so
    `2·(ELBÔ − ELBO(σ²a))` is not a χ²₁-calibrated LRT (it would dress an uncalibrated
    quantity as a CI). Scalar non-integer `n_trials` now gives a clean `ArgumentError`
    (via the shared `_resolve_single_family`), not a `MethodError`.
- **TDD (`test/runtests.jl`, new testset "Phase 6 Binomial/Bernoulli profile-LRT
  interval (σ²a)", 20 assertions, GREEN):** point == MLE, deviance vanishes at the MLE,
  brackets + σ²a > 0; the scalar m=20 fixture is genuinely two-sided (`!lower_clamped &&
  !upper_clamped`, both interior χ²₁ at 95% AND 90%, nesting); the per-record fixture
  WITNESSES the lower clamp (`lower_clamped && !upper_clamped`); the Bernoulli witnesses
  the double clamp; `marginal = :variational` rejected; guards (`:gaussian`, missing
  `n_trials`, length-mismatch, non-integer scalar). The Poisson interval testset (12) is
  unchanged.
- **Checks:** `Pkg.test()` GREEN (20 new + Poisson 12 + scalar-Binomial 31 + per-record
  39 all unchanged); `docs/make.jl` GREEN; `validation_status()` UNCHANGED (41 — this
  widens an existing experimental family, no new statistical claim promoted).
- **Adversarial review (Fisher inference + Rose claim-gate, 2 subagents over the diff):**
  Fisher (SOUND-with-concerns) confirmed the LRT inversion is as valid for Binomial/
  Bernoulli as for Poisson (single-parameter χ²₁, same boundary-mixture caveat inherited
  from Poisson), and CAUGHT: (1) the "fully two-sided" claim was over-generalized (the
  per-record fixture clamps) — FIXED (softened everywhere + the clamp flags now witness
  it); (2) the silent-clamp hazard — FIXED (the `*_clamped`/`converged` flags); (3)
  `marginal = :variational` produced an uncalibrated quantity — FIXED (rejected); (4)
  scalar non-integer `n_trials` → `MethodError` — FIXED (clean `ArgumentError`). Rose
  (Rose-principle sweep) CAUGHT two stale "Poisson-only" claims the first sweep missed:
  `src/validation_status.jl:340` (the `V6-LAPLACE` row) and `docs/design/capability-status.md`
  V6-FIT's trailing "Poisson interval exercised" clause — BOTH FIXED. The earlier
  "no other live stale claim" assertion was itself an overclaim; this is the corrected record.
- **Honest status:** EXPERIMENTAL, asymptotic, single-component only, NO coverage
  calibration, no Gaussian/two-component interval (still future), no external
  comparator, no R model-spec. Nothing promoted to `covered`.
