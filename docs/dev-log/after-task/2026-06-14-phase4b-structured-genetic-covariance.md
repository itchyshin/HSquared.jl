# Phase 4B: structured genetic covariance (diag / lowrank / fa)

Active lenses: Ada/Shannon, Kirkpatrick/Noether, Gauss/Fisher, Curie, Rose
(inline). Spawned subagents: none.

## Goal

Start Phase 4B with direct Julia engine support for constrained multivariate
genetic covariance matrices:

- diagonal: `G0 = diag(σ²)`;
- low-rank: `G0 = ΛΛ'`;
- factor-analytic: `G0 = ΛΛ' + Ψ`.

The slice is engine-internal and must not change the R bridge or public formula
contract.

## What Landed

- `src/multivariate.jl`:
  - `diagonal_covariance(variances)`;
  - `lowrank_covariance(loadings)`;
  - `factor_analytic_covariance(loadings, uniqueness)`;
  - `fit_multivariate_reml(...; genetic_structure = :diagonal | :lowrank |
    :factor_analytic, rank = K)`.
- `src/HSquared.jl`: exports the three covariance builders.
- `fit_multivariate_reml` remains backward-compatible:
  `genetic_structure = :unstructured` is the default and existing calls keep the
  same meaning.
- Structured fits constrain the genetic covariance only; residual `R0` remains
  unstructured.
- Returned metadata now includes `genetic_structure`, `genetic_rank`,
  `genetic_loadings`, and `genetic_uniqueness`. `result_payload()` is unchanged.

## Validation

Committed deterministic checks:

- covariance constructor identities:
  - `diagonal_covariance(v) == diag(v)`;
  - `lowrank_covariance(Λ) == ΛΛ'`;
  - `factor_analytic_covariance(Λ, ψ) == ΛΛ' + Ψ`;
- constructor guards for invalid/non-positive covariance inputs;
- structured REML metadata for diagonal, low-rank, and factor-analytic fits;
- returned loglik equals `_multivariate_reml_loglik` at the returned covariance
  matrices;
- low-rank covariance is PSD and factor-analytic covariance is PD;
- constrained structured fits do not exceed the unstructured REML loglik;
- invalid `genetic_structure` / missing or invalid `rank` guards.

`validation_status()` 27 → 28 with `V4-FA` marked `partial`.

## Checks

- `~/.juliaup/bin/julia --project=. -e 'using Pkg; Pkg.test()'`: passed.
  New testset "Phase 4B structured genetic covariance (diag/lowrank/fa)" =
  34 checks.
- `~/.juliaup/bin/julia --project=docs docs/make.jl`: green.
- `git diff --check`: passed.

Docs build caveats: the existing Documenter warning about unrelated exported
Phase-3/internal docstrings not included in the manual remains; local deployment
is skipped outside CI; VitePress reports npm audit advisories in generated docs
dependencies.

## Status Surfaces

Updated in lockstep:

- `src/validation_status.jl`;
- `docs/design/capability-status.md`;
- `docs/design/validation-debt-register.md`;
- `docs/design/06-public-claims-register.md`;
- `docs/design/03-engine-contract.md`;
- `ROADMAP.md`;
- `docs/src/api.md`;
- `docs/src/multivariate-models.md`;
- `docs/src/changelog.md`;
- `docs/dev-log/check-log.md`;
- this report.

## Public Claim Audit

Allowed:

- experimental dense/validation-scale structured genetic covariance builders;
- experimental dense multivariate REML with constrained genetic covariance
  structures;
- deterministic self-consistency validation as listed above.

Blocked / not claimed:

- R-facing covariance-structure syntax;
- bridge payload or `result_payload()` change;
- committed low-rank / factor-analytic recovery harness;
- loading sign/rotation convention;
- covariance standard errors or likelihood-ratio tests;
- sommer/ASReml/BLUPF90 comparator parity;
- production sparse factor-analytic fitting.

## What Did Not Go Smoothly

- `gh` is not available in the local shell, so PR/issue state had to be checked
  through the GitHub connector where possible.
- Documenter still reports pre-existing missing-manual warnings unrelated to
  this slice. I did not fold the independent docs-cleanup PR into this engine
  branch.

## Next Actions

1. Add an opt-in, non-CI recovery script for structured covariance fits, in the
   style approved by `2026-06-13-rng-recovery-test-harness.md`.
2. Decide and document loading sign / rotation conventions before interpreting
   `Λ` directly.
3. Prepare a shared multi-trait fixture for R-side sommer/ASReml/BLUPF90
   comparator parity.
4. Keep R covariance-structure syntax design out of this repo until the R lane
   intentionally opens that contract.
