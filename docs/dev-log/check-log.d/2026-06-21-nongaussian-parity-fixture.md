# 2026-06-21 Non-Gaussian Parity Fixture

- Goal: finish the Julia-owned #44 bridge payload fixture after the R lane
  mirrored the BLUPF90 packet status in hsquared PR #94 (`1d8565f`).
- Active lenses: Ada, Shannon, Hopper, Boole, Emmy, Gauss, Fisher, Curie,
  Grace, Rose.
- Starting point: `main` at `c25bcc1` (`Harden BLUPF90 multivariate packet
  (#151)`). No R files were touched from this branch.
- Implementation evidence:
  - Added `test/fixtures/non_gaussian_parity/` with a reproducible generator,
    six-animal pedigree, Poisson phenotype fixture, per-record Binomial
    phenotype fixture, and expected payload CSVs.
  - Added a CI testset that rebuilds the fits from CSV, recomputes
    `nongaussian_result_payload(::NonGaussianFit)`, checks the exact top-level
    payload fields, verifies no `heritability` field is present, validates
    canonical `:LA`/`:VA` method aliases, and catches corrupted EBV drift.
  - Registered the fixture in `test/fixtures/comparator_targets.toml` as
    `non_gaussian_parity` with evidence type `bridge_payload_fixture`.
  - Updated engine/bridge/status/public-claim ledgers and the API page.
- Commands run:
  - `julia --project=. test/fixtures/non_gaussian_parity/generate.jl` -
    passed and regenerated the checked-in fixture CSVs.
  - `julia --project=. -e 'using Pkg; Pkg.test(; test_args=["Phase 6 non-Gaussian parity fixture (#44)"])'`
    - passed. The project test harness ran the full package suite; the new
    fixture testset passed 44 assertions.
  - `julia --project=docs docs/make.jl` - passed with existing local warnings
    for omitted internal docstrings, skipped deployment detection, Vitepress
    default substitutions, missing logo/favicon, and npm audit output.
  - A second docs run failed after adding `nongaussian_result_payload` to the
    API page because its docstring referenced the omitted
    `multivariate_result_payload` entry; adding that sibling API entry fixed
    the dead `@ref`.
  - `julia --project=docs docs/make.jl` - passed after the API fix, with the
    same existing local warning class.
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
- Rose verdict: clean with limitations. This banks a Julia-side payload shape
  and deterministic parity target only. It does not activate R per-record
  varying-trial parsing, does not calibrate intervals, does not add external
  GLLVM.jl/gllvmTMB comparator evidence, and does not promote `V6-LAPLACE` or
  any public capability to covered.
