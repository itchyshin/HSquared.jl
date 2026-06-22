# After-Task Report: R Non-Gaussian Bridge Gap Correction

## Live Phase Snapshot

As of this report, the slice starts from Julia `main` `c26ab48`, after
HSquared.jl PR #153 mirrored R PR #95 fixture-normalizer consumption. The R
lane reports hsquared PR #96 merged at `e7c7a4a`, with R-CMD-check and
post-merge pkgdown green. Covered public status is unchanged: v0.1 univariate
Gaussian animal-model support only. `V6-LAPLACE` remains `partial`.

## 1. Goal

Correct the Julia #44 and status wording that over-broadened the remaining
R-side non-Gaussian bridge gap.

## 2. Implemented

- Updated `V6-LAPLACE` evidence, missing, and claim-boundary text to credit the
  existing opt-in R `target = "nongaussian"` bridge recorded by hsquared PR #96.
- Updated the bridge compatibility matrix, public-claims register, capability
  status, validation debt, validation-status page, changelog, comparator
  manifest, fixture README, coordination board, check logs, and this report.
- Updated the comparator manifest test assertion so it guards the corrected
  per-record varying-trial boundary instead of the old broad formula-activation
  phrase.
- Retargeted live GitHub issue #44 to the corrected split.

## 3a. Decisions and Rejected Alternatives

- Kept the correction narrow and did not change any engine behavior.
- Credited the opt-in R bridge for Poisson/Binomial LA/VA fits, including
  binary Bernoulli and common-trial `cbind(successes, failures)` Binomial.
- Did not treat the opt-in bridge or normalizer fixture as external comparator,
  interval-calibration, public-default, or covered-status evidence.

## 4. Files Touched

- `src/validation_status.jl`
- `test/runtests.jl`
- `test/fixtures/comparator_targets.toml`
- `test/fixtures/non_gaussian_parity/README.md`
- `docs/design/06-public-claims-register.md`
- `docs/design/12-bridge-compatibility.md`
- `docs/design/capability-status.md`
- `docs/design/validation-debt-register.md`
- `docs/src/changelog.md`
- `docs/src/validation-status.md`
- `docs/dev-log/coordination-board.md`
- `docs/dev-log/check-log.d/2026-06-21-nongaussian-parity-fixture.md`
- `docs/dev-log/check-log.d/2026-06-21-r-nongaussian-fixture-sync.md`
- `docs/dev-log/check-log.d/2026-06-21-r-nongaussian-bridge-gap-correction.md`
- `docs/dev-log/after-task/2026-06-21-nongaussian-parity-fixture.md`
- `docs/dev-log/after-task/2026-06-21-r-nongaussian-fixture-sync.md`
- `docs/dev-log/after-task/2026-06-21-r-nongaussian-bridge-gap-correction.md`

## 5. Checks Run

- `julia --project=. -e 'using HSquared; row = only(r for r in validation_status() if r.id == "V6-LAPLACE"); @assert row.status == "partial"; @assert occursin("hsquared PR #96", row.evidence); @assert occursin("per-record varying-trial R formula/bridge activation", row.missing); @assert occursin("opt-in non-Gaussian bridge", row.claim_boundary); @assert occursin("not the public default or covered status", row.claim_boundary); println("status ok")'`
  - Passed (`status ok`).
- `julia --project=. -e 'using TOML; targets = TOML.parsefile("test/fixtures/comparator_targets.toml")["target"]; ng = only(t for t in targets if t["id"] == "non_gaussian_parity"); @assert occursin("PR #96", ng["external_status"]); @assert occursin("per-record varying-trial formula/bridge activation remains open", ng["external_status"]); @assert occursin("no per-record varying-trial R activation", ng["boundary"]); println("manifest ok")'`
  - Passed (`manifest ok`).
- `julia --project=. -e 'using Pkg; Pkg.test(; test_args=["Comparator target manifest (#49 coordination)"])'`
  - Passed; the harness ran the full package suite, including the updated
    comparator manifest assertion.
- `julia --project=docs docs/make.jl`
  - Passed; existing local warnings remained (18 docstrings not in the manual,
    local deployment skipped, no optional Vitepress logo/favicon, and npm audit
    warnings in the local docs toolchain).

## 6. Tests of the Tests

The manifest assertion now fails if the non-Gaussian target boundary drifts back
to the stale "no R non-Gaussian formula activation" wording. The status smoke
also checks that `V6-LAPLACE` names PR #96, the per-record varying-trial gap,
the opt-in bridge evidence, and the partial boundary.

## 7a. Issue Ledger

- #44: opt-in R non-Gaussian bridge support is now credited; the issue remains
  open/status partial.
- Remaining #44 bridge gate: per-record varying-trial R formula/bridge
  activation plus broader validation/comparator/calibration depth.
- `V6-LAPLACE`: remains `partial`.

## 8. Consistency Audit

- Public-claims, capability, validation-debt, `validation_status()`, the
  validation-status page, the bridge matrix, and the comparator manifest now
  agree on the corrected R bridge state.
- Historical #153 audit files now carry correction notes so grep no longer
  surfaces the old broad residual as an unqualified current truth.

## 9. What Did Not Go Smoothly

The first #153 mirror was too conservative: it correctly avoided promoting
validation evidence, but it accidentally described the existing opt-in R bridge
as absent. R PR #96 supplied the correction, and this slice narrowed the
remaining gate.

## 10. Known Residuals

- No per-record varying-trial R formula/bridge activation.
- No external GLLVM.jl/gllvmTMB, ASReml, BLUPF90, MCMCglmm, or other comparator
  evidence.
- No calibrated non-Gaussian interval or coverage claim.
- No public-default or covered-status promotion.

## 11. Team Learning

When a bridge has separate levels (opt-in live bridge, fixture normalizer,
public-default syntax, and validation coverage), status text must name the exact
level that is missing. "No activation" is too blunt once any lower bridge level
exists.
