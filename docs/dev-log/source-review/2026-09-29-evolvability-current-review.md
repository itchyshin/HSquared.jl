# Exact-current review: G-matrix evolvability utilities

Date: 2026-09-29. Candidate branch: `codex/hsquared-fa-gllvm-20260927`, HEAD `a7ca8ed557b23ec23c8486365e97a7bac4b71c16`, with existing uncommitted candidate changes. This review pins the edited source by content hash because no candidate commit exists.

## Pinned files and checks

- `src/evolvability.jl` SHA-256: `9a0779335cafe208b3bb699a06df37fb13dc93e09fa128e750282fe8f75875df`.
- `test/wave4_covariance_contracts.jl` SHA-256: `c622be6ea0327b36265dd8e389c2509507c7c8d511e57fabc7074b956f60193d`.
- Command: `OPENBLAS_NUM_THREADS=1 JULIA_NUM_THREADS=4 julia --project=. --startup-file=no -e 'using HSquared, Test; include("test/wave4_covariance_contracts.jl")'`.
- Result: covariance contracts 22/22; animal-only repeatability rejection 4/4. This is a focused test, not a package-suite result.

## Review findings

The genetic covariance formulas and PSD-versus-PD boundary are coherent in the reviewed spans. Directional evolvability, conditional evolvability, respondability, autonomy, arbitrary-index variance, mean evolvability, and the PCA summaries match their stated matrix definitions (`src/evolvability.jl:91-235`). Singular low-rank G is accepted for PSD-only metrics and rejected for metrics that invert G (`:31-79,101-149`). The scale-relative PSD amendment at `:35-65` addresses the reported unit-sized tolerance defects. This does not validate sparse precision or A-inverse routines.

Two numerical findings remain open. First, Cholesky success alone is used as the stability criterion for inverse metrics (`:73-78,116-120,144-149`). Highly ill-conditioned positive-definite G can produce inaccurate or nonfinite results; autonomy may violate its documented `(0,1]` range. Second, finite input values are not sufficient to ensure representable derived eigenvalues, quadratic forms, traces, or explained-variance fractions (`:39-47,101-104,160-171,197-206,232-265`). Subnormal-scale tolerance behavior also lacks a targeted regression (`:41-63`). No concrete subnormal counterexample was established in this static review.

The main interpretation boundary is trait coordinates. The `rotation_invariant` wording is valid for latent-factor rotations that preserve G, not for changing trait units or arbitrary coordinate transforms. Directional functions normalize beta with the Euclidean norm (`:81-89`), so mixed-unit traits need a declared or scientifically justified common scale. Make that limitation visible beside directional metrics and respondability, as the current FA payload already does for coordinate- and unit-dependent summaries (`src/multivariate.jl:239-240`). This is a documentation and estimand boundary, not evidence that the formulas are wrong under an appropriate coordinate system.

## Rose claim audit

Rose reviewed the exact candidate hash and returned **clean with limitations**. The experimental/partial status and validation-debt wording do not support promoting `V4-EVOLVE`. Rose confirms that rotation invariance means orthogonal latent-factor rotations preserving G, not trait rescaling. The manual currently makes unit dependence explicit for mean evolvability only; directional metrics and PCA axes also depend on trait coordinates and units. Singular-G rejection and one well-conditioned tiny-scale example do not establish stability over ill-conditioned positive-definite inputs or all scales. These limits remain carried; no public status or capability claim changed.

## Bounded verdict

Conditional pass for the inspected G definitions and scale-relative PSD guards, with the numerical and trait-coordinate findings above carried. The focused test passed on the pinned candidate. Whole Wave 4 remains HOLD pending independent integration signoff and disposition of the carried findings. E1, A2, and V3 remain open. No capability status, public claim, release status, or covered count changes.

## Does NOT cover

This review does not establish stable inverse metrics for ill-conditioned inputs, overflow behavior at extreme finite scales, trait-unit invariance, fitted FA or GLLVM recovery, uncertainty calibration, R-Julia parity, the remaining Wave 4 files, whole-wave signoff, full E1 completion, GPU execution, or release readiness.

## Remediation and final evidence

The exact-candidate numerical findings above were converted into regressions before the implementation changed. The new test first failed for an ill-conditioned positive-definite `G` (autonomy exceeded 1), for finite extreme covariance scales (overflow/underflow in means and explained variances), for an unrepresentable eigenvalue, and for extreme finite `beta` norms. The final source uses scale-normalized Cholesky, rejects inverse metrics above a condition-number ceiling of `1/sqrt(eps(Float64))`, rescales covariance summaries before arithmetic, and normalizes finite `beta` vectors by their maximum absolute entry before taking a norm. The final focused file passes 18/18, including autonomy and same-direction comparisons under non-isotropic `G`.

Exact final hashes: `src/evolvability.jl` `fd49987ee69c1f9b6e3335bdb6e4f8c73b6f0cdab3da4b7263cf4e87b6577ff3`; `test/test_evolvability_stability.jl` `c7281841ce51279ce4f7e68b0f94625baab04cdbe06c4519191efe06b26c4777`; `test/runtests.jl` `f55e4682015a2b4aa37b6b1c84a6c8e4df5beaf4376355687e0860af47b13ac0`; `docs/src/multivariate-models.md` `685525aeba2896be6e4697d2b04141fc7a65fcd10ae0953abb752c7de4e4bbcf`.

The final Julia 1.10 `Pkg.test()` passed, ending `Testing HSquared tests passed`; the existing Project/Manifest mismatch warning remains and neither resolve nor update was run. `git diff --check` passed. The docs build passed earlier on these unchanged manual bytes; existing missing-docstring, deployment autodetection, absent VitePress config/favicon, and bundle-size advisories were reported. Gauss and Noether approved the final numerical implementation; Kirkpatrick's matrix-definition review and Rose's claim/wording audit remain bounded to their reviewed exact spans and source bytes. The row stays `partial`; the condition ceiling is an explicit accepted-input boundary, not broad conditioning or scale-invariance evidence. No external comparator, fitted-FA inference, calibration, capability promotion, GPU work, release, or tag is established. See `docs/dev-log/check-log.d/2026-09-29-evolvability-stability.md`.
