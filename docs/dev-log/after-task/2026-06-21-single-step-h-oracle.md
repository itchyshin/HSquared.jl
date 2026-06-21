# After-task — Single-step dense-H oracle fixture

Date: 2026-06-21. Lane: Julia engine (`HSquared.jl`). Branch:
`codex/single-step-h-roundtrip-fixture`. Type: validation hardening slice.

## Live Phase Snapshot

As of this report, Julia `main` is `426a3a5` after the H^Gamma bridge payload
hardening (#130), with post-merge CI, Documenter, and Pages green. The current
branch hardens the ordinary single-step H-inverse construction with an internal
dense-H oracle. R `hsquared` owns the public formula/model-spec lane; this
Julia thread did not edit the R repository. No capability is promoted to
covered.

## Goal

Finish the third Big-3 Julia-owned slice by reducing single-step validation
risk without depending on missing BLUPF90 executables or R-side bridge work.

## Active Lenses

Gauss + Noether checked H/H-inverse algebra. Mrode + Fisher + Curie checked the
validation target boundary. Rose kept the public claim boundary clean. Grace
covered local checks. Ada + Shannon kept the R/Julia lane split. No subagents
were spawned.

## Files Changed

- `test/runtests.jl` — adds a test-only dense single-step `H` oracle and checks
  `_single_step_Hinv * H`, `H * _single_step_Hinv`, and `inv(H)` round trips for
  trailing and scattered genotyped rows.
- `src/validation_status.jl`, `docs/src/validation-status.md`,
  `docs/design/validation-debt-register.md`, and
  `docs/design/capability-status.md` — record the internal oracle without
  promoting status.
- `docs/dev-log/coordination-board.md`
- `docs/dev-log/check-log.d/2026-06-21-single-step-h-oracle.md`

## Commands / Results

- Focused algebra probe — passed. The independent dense-H oracle round-tripped
  with `_single_step_Hinv` at machine precision for trailing genotyped rows
  (`6.66e-16`) and scattered genotyped rows (`2.22e-16`).
- `julia --project=. -e 'using Pkg; Pkg.test()'` — passed. The updated
  `Phase 2 single-step H-inverse construction` testset passed 18/18.
- `julia --project=docs docs/make.jl` — passed, with existing local-build
  warnings for omitted internal docstrings, skipped deployment detection,
  default Vitepress assets, and npm audit output.
- `git diff --check` — passed.

## Public Claim Audit

Clean with limitations. The useful claim is limited to: "the ordinary
single-step H-inverse constructor is now checked against an independent dense-H
relationship oracle for validation-scale fixtures, including scattered
genotyped rows." This is not a published Mrode Ch.11 target, not external
comparator evidence, not comparator-validated blending defaults, not sparse/APY
scaling, and not covered validation.

## Tests Of The Tests

The oracle builds the full dense single-step relationship `H` from the
Schur-style block update rather than simply replacing the `A22` block. The test
therefore checks the algebraic inverse identity directly: `_single_step_Hinv`
must be the inverse of the constructed `H` from both multiplication directions
and must match `inv(Symmetric(H))`.

## Coordination Notes

R lane was not edited. The R twin should treat this as Julia internal
validation evidence for the existing single-step primitive, not as live R
support or as external H-matrix comparator evidence.

## Known Limitations / Next Actions

- Published Mrode Ch.11 H/H-inverse numbers or an equivalent external target
  remain open.
- Comparator-validated blending/tuning defaults remain open.
- External metafounder single-step comparator evidence remains open.
- R-side formula/model-spec payload remains separate and unclaimed.
- Sparse/APY scaling remains open.
