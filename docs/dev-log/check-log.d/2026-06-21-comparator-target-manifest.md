# 2026-06-21 Comparator Target Manifest

- Goal: give the R lane and any external comparator runner one machine-readable
  index of the current Julia comparator/bridge target fixtures without changing
  fitting behavior or validation status.
- Added `test/fixtures/comparator_targets.toml` with entries for the fitted
  animal-model target, multivariate parity target, genomic GBLUP/SNP-BLUP
  target, marker-scan payload fixture, and structured-covariance diagonal
  fixture.
- Added a test that parses the TOML, checks target IDs are unique, verifies all
  listed files exist, pins the allowed evidence classes, and checks the
  multivariate/genomic claim boundaries.
- Updated `comparator/README.md` so external runners know the TOML is the
  current index.
- Checks:
  - `julia --project=. -e 'using TOML; d = TOML.parsefile("test/fixtures/comparator_targets.toml"); @assert d["schema_version"] == 1; @assert length(d["target"]) == 5; println("manifest ok")'`:
    passed (`manifest ok`).
  - `git diff --check`: passed.
  - First `julia --project=. -e 'using Pkg; Pkg.test()'`: failed because `TOML`
    was not declared as a test extra in the isolated `Pkg.test()` environment.
    Fixed by adding stdlib `TOML` to `[extras]` and `[targets].test`.
  - Final `julia --project=. -e 'using Pkg; Pkg.test()'`: passed; the new
    `Comparator target manifest (#49 coordination)` testset passed 79/79
    assertions.
  - `julia --project=docs docs/make.jl`: passed; only the existing 20
    not-in-manual docstring warnings and local Vitepress/npm audit warnings
    appeared.
- Boundary: no external comparator was run, no R files were touched, no
  capability moved to covered, and this does not activate any R-facing model
  spec or threshold wording.
