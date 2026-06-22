# 2026-06-21 R Non-Gaussian Bridge Gap Correction

- Goal: correct Julia #44/status wording after hsquared PR #96 (`e7c7a4a`)
  clarified that the R twin already has an opt-in non-Gaussian bridge.
- Starting point:
  - HSquared.jl `main` clean at `c26ab48` after PR #153.
  - R sync reported hsquared `main` at `e7c7a4a`, remote R-CMD-check green,
    and post-merge R pkgdown green.
- Files changed:
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
  - live GitHub issue #44 body (status text only).
- Scope:
  - record that R already has opt-in `target = "nongaussian"` bridge support
    for `poisson(log)` and `binomial(logit)` LA/VA fits, including binary
    Bernoulli and common-trial `cbind(successes, failures)` Binomial;
  - keep the remaining bridge gap narrow: per-record varying-trial
    formula/bridge activation plus broader validation/comparator/calibration
    depth;
  - keep `V6-LAPLACE` partial.
- Checks:
  - `julia --project=. -e 'using HSquared; row = only(r for r in validation_status() if r.id == "V6-LAPLACE"); @assert row.status == "partial"; @assert occursin("hsquared PR #96", row.evidence); @assert occursin("per-record varying-trial R formula/bridge activation", row.missing); @assert occursin("opt-in non-Gaussian bridge", row.claim_boundary); @assert occursin("not the public default or covered status", row.claim_boundary); println("status ok")'`:
    passed (`status ok`).
  - `julia --project=. -e 'using TOML; targets = TOML.parsefile("test/fixtures/comparator_targets.toml")["target"]; ng = only(t for t in targets if t["id"] == "non_gaussian_parity"); @assert occursin("PR #96", ng["external_status"]); @assert occursin("per-record varying-trial formula/bridge activation remains open", ng["external_status"]); @assert occursin("no per-record varying-trial R activation", ng["boundary"]); println("manifest ok")'`:
    passed (`manifest ok`).
  - `julia --project=. -e 'using Pkg; Pkg.test(; test_args=["Comparator target manifest (#49 coordination)"])'`:
    passed; the package harness ran the full suite, including the updated
    comparator manifest assertion.
  - `julia --project=docs docs/make.jl`: passed; existing local warnings
    remained (18 docstrings not in the manual, local deployment skipped, no
    optional Vitepress logo/favicon, and npm audit warnings in the local docs
    toolchain).
- Boundary: status/docs/issue/test-manifest sync only. No Julia behavior
  changed, no R files were edited, no new R behavior was implemented, no
  external comparator was run, no interval calibration was claimed, and no
  validation/public-claim promotion was made.
