# BLUPF90 Numeric Packet Hardening

## Task Goal

Align the Julia BLUPF90/AIREMLF90 multivariate starter packet with the R-lane
executable handoff convention before the next same-estimand comparator run.

## Active Lenses

- Ada + Shannon: cross-lane coordination and no R-file overlap.
- Curie + Fisher + Mrode: validation target and estimator boundary.
- Grace: local checks and CI readiness.
- Rose: claim-vs-evidence audit.

Spawned agents: none.

## Files Changed

- `.gitignore`
- `comparator/prepare_blupf90_multitrait.jl`
- `comparator/README.md`
- `comparator/blupf90_multitrait/README.md`
- `test/runtests.jl`
- `src/validation_status.jl`
- `docs/src/validation-status.md`
- `docs/design/validation-debt-register.md`
- `docs/dev-log/check-log.d/2026-06-21-blupf90-numeric-packet.md`
- `docs/dev-log/coordination-board.md`

## Checks Run

- `julia comparator/prepare_blupf90_multitrait.jl`
  - Passed.
  - Generated and validated 80 phenotype rows and 20 pedigree rows.
  - Local probe found no `renumf90`, `airemlf90`, `blupf90`, `remlf90`, or
    `gibbsf90` executable on `PATH`.
- `julia --project=. -e 'using Pkg; Pkg.test(; test_args=["BLUPF90 multivariate starter packet preflight"])'`
  - Passed.
  - The invocation ran the package test suite; the BLUPF90 preflight testset
    passed 37/37.
- `julia --project=. -e 'using Pkg; Pkg.test()'`
  - Passed.
  - The BLUPF90 preflight testset passed 37/37.
- `julia --project=docs docs/make.jl`
  - Passed, with standing local-build warnings for omitted internal docstrings,
    skipped deployment detection, default Vitepress assets, missing local
    logo/favicon, and npm audit output.
- `Rscript /Users/z3437171/shinichi-brain/tools/check-after-task.R docs/dev-log/after-task/2026-06-21-blupf90-numeric-packet.md`
  - Passed.
- `git diff --check`
  - Passed.

## Public Claim Audit

Clean with limitations. This slice only hardens the generated BLUPF90 packet:

- data columns: `trait1 trait2 intercept x animal_code`;
- pedigree columns: `animal_code sire_code dam_code`;
- `animal_id_map.csv` for aligning BLUPF90 output back to fixture IDs;
- RENUMF90 records pinned to those numeric columns.

It does not run `renumf90`, `airemlf90`, or any other BLUPF90-family executable.
It does not record comparator estimates, convergence, likelihood scale,
tolerance, or a second independent same-estimand comparator leg. `V4-MV-REML`
remains partial.

## Tests Of The Tests

The preflight test generates the packet in a temporary directory, so it does
not rely on ignored working-tree outputs. It now pins:

- exact first data row and pedigree row;
- all-ones intercept column;
- all numeric BLUPF90 data values;
- integer-coded pedigree values;
- `animal_id_map.csv` header and endpoint IDs;
- `TRAITS 1 2`, `FIELDS_PASSED TO OUTPUT 3 4 5`, fixed-effect records, and
  `OPTION method VCE` in `renumf90.par`.

## Coordination Notes

The R lane reported hsquared PR #93 at `ce47ec6` after mirroring Julia PR #150.
This Julia slice does not edit R files. It reconciles Julia's packet convention
with the R-lane BLUPF90 executable handoff so a future host can choose either
packet without discovering a column-order mismatch mid-run.

## What Did Not Go Smoothly

The first test command was intended as focused, but `Pkg.test` still ran the
package suite. That was slower than intended but useful; the suite passed.

## Known Limitations

- Local BLUPF90-family executables are still absent from `PATH`.
- The packet is not proof that RENUMF90 accepts the template on every BLUPF90
  release.
- No generated `renf90.par`, BLUPF90 log, covariance estimates, fixed effects,
  EBVs, or alignment report exists from this slice.
- No validation row is promoted to covered.

## Next Actions

- Run the packet on a machine with `renumf90` and `airemlf90`.
- Record executable paths/versions, generated `renf90.par`, convergence output,
  final G0/R0, fixed effects, EBVs, ID alignment, tolerances, and Rose audit.
- Keep `V4-MV-REML` partial until that executed comparator evidence is banked.
