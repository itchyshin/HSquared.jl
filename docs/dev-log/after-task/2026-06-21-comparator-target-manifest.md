# Comparator Target Manifest

## Task Goal

Create a Julia-owned, machine-readable handoff index for the current comparator
and bridge fixtures so the R lane and future external runners can consume
targets without reverse-engineering fixture directories.

## Active Lenses

- Ada + Shannon: cross-lane sequencing and lane boundary.
- Curie + Fisher + Mrode: validation target shape and comparator semantics.
- Grace: cheap CI-friendly test coverage.
- Rose: claim-vs-evidence boundary.

Spawned agents: none.

## Files Changed

- `test/fixtures/comparator_targets.toml`
- `test/runtests.jl`
- `comparator/README.md`
- `docs/dev-log/check-log.d/2026-06-21-comparator-target-manifest.md`
- `docs/dev-log/coordination-board.md`
- `docs/dev-log/after-task/2026-06-21-comparator-target-manifest.md`

## Checks Run

- `julia --project=. -e 'using TOML; d = TOML.parsefile("test/fixtures/comparator_targets.toml"); @assert d["schema_version"] == 1; @assert length(d["target"]) == 5; println("manifest ok")'`
  - Passed: `manifest ok`.
- `git diff --check`
  - Passed.
- `julia --project=. -e 'using Pkg; Pkg.test()'`
  - First run failed before tests because `TOML` was not declared as a test
    extra in the isolated `Pkg.test()` environment.
  - After adding stdlib `TOML` to `[extras]` and `[targets].test`, the final run
    passed. The new `Comparator target manifest (#49 coordination)` testset
    passed 79/79 assertions.
- `julia --project=docs docs/make.jl`
  - Passed. Existing warnings remain: 20 docstrings not included in the manual,
    local deployment skipped, and Vitepress/npm audit warnings in the local
    docs toolchain.
- `gh run list --limit 5`
  - Confirmed the previous `main` push for `Sync structured covariance status`
    was green: CI success, Documenter success, Pages success.

## Public Claim Audit

Clean with limitations. The new TOML is an index only. It records that the
fixtures are Julia targets, bridge payload fixtures, or partial external
evidence scaffolds; it does not claim a new comparator run, public R activation,
or covered validation status.

## Tests Of The Tests

The manifest test mutates the usual failure surface indirectly: it requires
every listed fixture file to exist, pins unique IDs, restricts evidence classes,
and checks the multivariate and genomic entries carry the still-open comparator
boundaries. A stale or over-broad target entry should fail loudly.

## Coordination Notes

This responds to the R lane's #80 marker-scan fixture consumption and keeps the
next comparator/status handoffs in one parseable Julia-owned file. The R lane is
free to mirror or consume the TOML; no `hsquared` files were edited here.

## What Did Not Go Smoothly

The broad `rg` scan initially wandered into generated docs assets. The actual
slice stayed bounded after switching back to the source fixture and comparator
surfaces.

The first full `Pkg.test()` run failed because `TOML` worked in the normal
project environment but was not available in the isolated test project. Adding
it as a test extra fixed the package-level contract.

## Known Limitations

- The manifest is not a comparator runner.
- BLUPF90/ASReml/DMU/WOMBAT or equivalent same-estimand executables remain
  absent from this local evidence chain.
- The genomic target still has no external comparator.
- Lowrank/factor-analytic bridge exposure remains blocked on rotation/loading
  semantics.

## Next Actions

- R lane can mirror/consume `test/fixtures/comparator_targets.toml` as a status
  or fixture-index slice.
- Julia lane should continue #49 only when a same-estimand comparator runner or
  executable-backed environment is available, or otherwise move to another
  evidence-producing target that does not overclaim.
