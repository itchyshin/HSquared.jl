# After-Task Report: Non-Gaussian Parity Fixture

## Live Phase Snapshot

As of this report, the slice starts from Julia `main` `c25bcc1`, after
HSquared.jl PR #151 hardened the BLUPF90/AIREMLF90 multivariate starter packet.
The R lane has mirrored that status in hsquared PR #94 at `1d8565f`. Covered
public status is unchanged: v0.1 univariate Gaussian animal-model support only.
This slice does not promote any validation row to covered.

## 1. Goal

Complete the Julia-owned #44 payload-fixture checkbox by serializing a stable
`nongaussian_result_payload(::NonGaussianFit)` target that the R lane can
consume without live Julia.

## 2. Implemented

- Added `test/fixtures/non_gaussian_parity/` with a reproducible generator,
  pedigree, phenotype inputs, and expected payload CSVs.
- Serialized two deterministic validation-scale cases: Poisson Laplace and
  per-record Binomial variational.
- Added a CI testset that rebuilds both fits from CSV, recomputes the payload,
  checks exact payload fields, verifies no `heritability` field is present, and
  compares variance components, fixed effects, EBVs, loglik/ELBO, method
  strings, convergence, and `n_trials`.
- Registered the fixture in `test/fixtures/comparator_targets.toml`.
- Updated engine contract, bridge compatibility, validation status, validation
  debt, capability status, public claims, API docs, changelog, coordination
  board, check log, and this after-task report.

## 3a. Decisions and Rejected Alternatives

- Kept the fixture CSV-based so R can write Julia-free normalizer tests.
- Used both Poisson Laplace and per-record Binomial variational cases so the
  payload pins both `n_trials = nothing` and integer-vector `n_trials`.
- Did not add R-facing syntax or model-spec changes. This is a Julia bridge
  target only.
- Did not add external comparator language. No GLLVM.jl, gllvmTMB, BLUPF90,
  ASReml, MCMCglmm, or other comparator was run.

## 4. Files Touched

- `src/validation_status.jl`
- `test/runtests.jl`
- `test/fixtures/comparator_targets.toml`
- `test/fixtures/non_gaussian_parity/README.md`
- `test/fixtures/non_gaussian_parity/generate.jl`
- `test/fixtures/non_gaussian_parity/pedigree.csv`
- `test/fixtures/non_gaussian_parity/poisson_phenotypes.csv`
- `test/fixtures/non_gaussian_parity/binomial_phenotypes.csv`
- `test/fixtures/non_gaussian_parity/expected_payload_metadata.csv`
- `test/fixtures/non_gaussian_parity/expected_variance_components.csv`
- `test/fixtures/non_gaussian_parity/expected_fixed_effects.csv`
- `test/fixtures/non_gaussian_parity/expected_breeding_values.csv`
- `docs/design/03-engine-contract.md`
- `docs/design/06-public-claims-register.md`
- `docs/design/12-bridge-compatibility.md`
- `docs/design/capability-status.md`
- `docs/design/validation-debt-register.md`
- `docs/src/api.md`
- `docs/src/changelog.md`
- `docs/src/validation-status.md`
- `docs/dev-log/coordination-board.md`
- `docs/dev-log/check-log.d/2026-06-21-nongaussian-parity-fixture.md`
- `docs/dev-log/after-task/2026-06-21-nongaussian-parity-fixture.md`

## 5. Checks Run

- `julia --project=. test/fixtures/non_gaussian_parity/generate.jl` - passed.
- `julia --project=. -e 'using Pkg; Pkg.test(; test_args=["Phase 6 non-Gaussian parity fixture (#44)"])'`
  - passed. The harness ran the full package suite; the new fixture testset
  passed 44 assertions.
- `julia --project=docs docs/make.jl` - passed after adding both
  `nongaussian_result_payload` and `multivariate_result_payload` to the API
  page.
- Remote CI first failed on Julia 1.10 because the optimizer-refit payload
  comparisons used `atol = 1e-8`; Linux/Julia 1.10 differed from the stored
  fixture values by about `1e-7` to `6e-7`. A second run showed one remaining
  Binomial variance-component difference of about `1.1e-6`, so the test now
  uses `atol = 1e-5` only for refitted numeric payload values.
- `julia --project=. -e 'using Pkg; Pkg.test()'` - passed after the tolerance
  fix; the non-Gaussian fixture testset passed 44 assertions.
- `Rscript /Users/z3437171/shinichi-brain/tools/check-after-task.R docs/dev-log/after-task/2026-06-21-nongaussian-parity-fixture.md`
  - passed.
- `git diff --check` - passed.

## 6. Tests of the Tests

The fixture test reconstructs `Ainv`, `X`, `Z`, response vectors, and trial
denominators from CSV before refitting. It compares stored payload values at
`1e-5` tolerance and then perturbs the expected EBV vector to verify the parity
check would fail on value drift.

## 7a. Issue Ledger

- #44: this branch banks the Julia-side non-Gaussian payload fixture requested
  for the R bridge-normalizer handoff.
- R #18: still planned from the Julia perspective; the R lane can consume the
  fixture, but no R files were touched here.
- `V6-LAPLACE`: remains `partial`.

## 8. Consistency Audit

- The engine contract now names the exact non-Gaussian payload fields.
- The bridge matrix now points #44 at `non_gaussian_parity`.
- The public claims register, capability status, validation debt register, and
  `validation_status()` all say fixture/status only.
- The API page includes both non-Gaussian and multivariate bridge payload
  functions, preventing a dead Documenter `@ref`.

## 9. What Did Not Go Smoothly

The first docs build after adding `nongaussian_result_payload` to the API page
failed because its docstring references `multivariate_result_payload`, which
was also omitted from the API page. Adding the sibling payload function fixed
the dead link, and the docs build then passed.

The first two remote Julia 1.10 CI runs also showed that `1e-8`/`1e-6` were too
strict for refitted optimizer outputs across platforms. The fixture now uses
`1e-5` for numeric refit-value comparisons while keeping payload shape, IDs,
method strings, trial denominators, and the corrupted-EBV negative check
intact.

## 10. Known Residuals

- No R non-Gaussian formula/family/model-spec activation.
- No GLLVM.jl/gllvmTMB or other external comparator evidence.
- No calibrated non-Gaussian interval or coverage claim.
- No production-scale sparse non-Gaussian fitting claim.
- No validation-row or public-claim promotion.

## 11. Team Learning

Bridge payload docstrings can make hidden API omissions visible. When exposing
one payload helper on the API page, include its sibling payload helper too if
the docstrings cross-reference each other.
