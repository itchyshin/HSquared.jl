# After-task — BLUPF90 multivariate preflight harness

Date: 2026-06-21. Lane: Julia engine (`HSquared.jl`). Branch:
`codex/blupf90-preflight-harness`. Type: validation/comparator setup hardening.

## Live Phase Snapshot

As of this report, Julia `main` is `8327cfe` after the Codex handover v1
checkpoint. The multivariate `V4-MV-REML` second-comparator gate remains locally
blocked because `renumf90`, `airemlf90`, `blupf90`, `remlf90`, and `gibbsf90`
are not on `PATH`. This slice strengthens the BLUPF90/AIREMLF90 setup path but
does not run BLUPF90-family software and does not promote any capability to
covered.

## Goal

Make the existing BLUPF90 starter packet reproducible, machine-oriented, and
test-pinned before a future run on a machine with BLUPF90-family executables.

## Active Lenses

Curie + Fisher + Mrode checked that the target stays the same two-trait
Gaussian animal-model estimand. Rose kept the claim boundary clean. Grace
covered local checks. Ada + Shannon kept the R/Julia lane split. No subagents
were spawned.

## Files Changed

- `comparator/prepare_blupf90_multitrait.jl` — refactored into reusable
  generation, validation, and executable-probe functions; generated
  BLUPF90-consumed files no longer carry header/comment records.
- `comparator/run_blupf90_multitrait.jl` — new skip-safe opt-in runner; without
  `HSQUARED_RUN_BLUPF90=true`, it validates the packet and exits without
  external software.
- `test/runtests.jl` — pins packet row counts, target covariances, no
  header/comment records, validation round-trip, and executable-probe shape.
- `src/validation_status.jl`, `docs/src/validation-status.md`,
  `docs/design/capability-status.md`, and
  `docs/design/validation-debt-register.md` — record the preflight while
  preserving the missing second-comparator evidence boundary.
- `comparator/README.md`, `comparator/blupf90_multitrait/README.md`
- `docs/dev-log/coordination-board.md`
- `docs/dev-log/check-log.d/2026-06-21-blupf90-preflight-harness.md`

## Commands / Results

- `julia comparator/prepare_blupf90_multitrait.jl` — passed. Generated and
  validated 80 phenotype rows and 20 pedigree rows; local executable probe
  found no BLUPF90-family executables on `PATH`.
- `julia comparator/run_blupf90_multitrait.jl` — passed skip guard and exited 0
  without external software.
- `julia --project=. -e 'using Pkg; Pkg.test()'` — passed. The new
  `BLUPF90 multivariate starter packet preflight (#49)` testset passed 19/19.
- `julia --project=docs docs/make.jl` — passed, with existing local-build
  warnings for omitted internal docstrings, skipped deployment detection,
  default Vitepress assets, and npm audit output.
- `git diff --check` — passed.

## Public Claim Audit

Clean with limitations. The useful claim is limited to: "the BLUPF90/AIREMLF90
second-comparator packet now has a tested preflight and skip-safe opt-in
runner." This is not BLUPF90 evidence, not RENUMF90/AIREMLF90 syntax validation
across releases, not aligned-estimate parity, not a second independent
comparator leg, and not covered validation.

## Tests Of The Tests

The normal Julia test suite generates the packet into a temporary directory
instead of relying on ignored working-tree outputs. It checks the exact fixture
row counts, target `G0`/`R0` matrices, BLUPF90 table widths, absence of
header/comment rows in generated machine inputs, and executable-probe return
shape without requiring any external executable.

## Coordination Notes

R lane was not edited. The R twin can treat this as Julia-side setup hardening
for a future BLUPF90-family run, not as evidence that the second comparator has
passed.

## Known Limitations / Next Actions

- Run the packet on a machine with `renumf90` and `airemlf90` available.
- Record executable versions, generated `renf90.par`, convergence output,
  aligned `G0`/`R0`/fixed-effect/EBV estimates, tolerance, and Rose audit.
- Keep `V4-MV-REML` partial until an executed second comparator or equivalent
  evidence is recorded.
