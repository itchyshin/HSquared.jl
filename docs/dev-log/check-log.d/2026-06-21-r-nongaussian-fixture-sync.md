# 2026-06-21 R Non-Gaussian Fixture Sync

- Goal: mirror hsquared PR #95 (`05fbdd3`) into Julia-owned #44/status
  surfaces after the R lane consumed `test/fixtures/non_gaussian_parity/` in
  Julia-free `NonGaussianFit` normalizer tests.
- Starting point:
  - HSquared.jl `main` clean at `3843ddb` after PR #152.
  - R sync reported hsquared `main` at `05fbdd3`, remote R-CMD-check green,
    and post-merge R pkgdown green.
- Files changed:
  - `src/validation_status.jl`
  - `test/fixtures/comparator_targets.toml`
  - `test/fixtures/non_gaussian_parity/README.md`
  - `docs/design/06-public-claims-register.md`
  - `docs/design/12-bridge-compatibility.md`
  - `docs/design/capability-status.md`
  - `docs/design/validation-debt-register.md`
  - `docs/src/changelog.md`
  - `docs/src/validation-status.md`
  - `docs/dev-log/coordination-board.md`
  - `docs/dev-log/check-log.d/2026-06-21-r-nongaussian-fixture-sync.md`
  - `docs/dev-log/after-task/2026-06-21-r-nongaussian-fixture-sync.md`
  - live GitHub issue #44 body (status text only).
- Scope:
  - record that R normalizer fixture consumption is banked via hsquared PR #95;
  - keep per-record varying-trial formula/bridge activation,
    GLLVM/gllvmTMB comparator evidence, interval calibration, and promotion
    open.
- Checks:
  - `julia --project=. -e 'using HSquared; row = only(r for r in validation_status() if r.id == "V6-LAPLACE"); @assert row.status == "partial"; @assert occursin("hsquared PR #95", row.evidence); @assert occursin("live R bridge fitting", row.missing); @assert occursin("R family/model-spec activation remains pending", row.claim_boundary); println("status ok")'`:
    passed (`status ok`).
  - `julia --project=docs docs/make.jl`: passed; existing local warnings
    remained (18 docstrings not in the manual, local deployment skipped, no
    optional Vitepress logo/favicon, and npm audit warnings in the local docs
    toolchain).
  - `julia --project=. -e 'using TOML; targets = TOML.parsefile("test/fixtures/comparator_targets.toml")["target"]; ng = only(t for t in targets if t["id"] == "non_gaussian_parity"); @assert occursin("PR #95", ng["external_status"]); @assert occursin("family/model-spec activation remains planned", ng["external_status"]); println("manifest ok")'`:
    passed (`manifest ok`).
  - `Rscript /Users/z3437171/shinichi-brain/tools/check-after-task.R docs/dev-log/after-task/2026-06-21-r-nongaussian-fixture-sync.md`:
    passed.
  - `git diff --check`: passed.
- Boundary: status/ledger/issue sync only. No Julia behavior changed, no R
  files were edited, no per-record varying-trial R formula/bridge activation
  was added, no external comparator was run, no interval calibration was
  claimed, and no validation/public-claim promotion was made.

- Correction after hsquared PR #96 (`e7c7a4a`): the wording above was too broad
  about the R-side residual. The R twin already had the opt-in
  `target = "nongaussian"` bridge for Poisson/Binomial LA/VA fits, including
  binary Bernoulli and common-trial `cbind(successes, failures)` Binomial, plus
  live bridge tests when Julia is available. The remaining R-side bridge gap is
  per-record varying-trial formula/bridge activation plus broader
  validation/comparator/calibration depth.
