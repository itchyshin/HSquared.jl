# Single-Step H-Inverse Construction (_single_step_Hinv, internal)

Active lenses: Henderson, Mrode, Kirkpatrick, Gauss, Mendel, Rose (inline).
Spawned subagents: none (design from the `phase2-engine-plan` workflow; the
`A₂₂⁻¹ ≠ (A⁻¹)[g,g]` trap was flagged by the scout and re-verified locally).

## Goal

Provide the single-step (ssGBLUP) genomic relationship inverse `H⁻¹` as an
internal, property-checked construction utility — the subtlest Phase-2 piece —
without wiring it into fitting or claiming comparator-validated blending.

## Files Changed

- `src/genomic.jl` (added `_single_step_Hinv`)
- `test/runtests.jl` (testset "Phase 2 single-step H-inverse construction";
  `length(validation)` 18→19)
- `src/validation_status.jl` (row `V2-SSHINV`)
- `docs/design/capability-status.md`, `docs/design/validation-debt-register.md`,
  `docs/src/changelog.md`, `docs/dev-log/check-log.md`,
  `docs/dev-log/after-task/2026-06-13-single-step-hinv.md`

## Implementation

`_single_step_Hinv(Ainv, A, G, genotyped_rows; tau, omega, blend_weight, ridge)`
assembles `H⁻¹ = A⁻¹ + scatter(τ·Gʷ⁻¹ − ω·A₂₂⁻¹)` over the genotyped rows, with
`Gʷ = (1−blend_weight)·G + blend_weight·A₂₂` and an optional ridge. It reuses
`_numerator_relationship` for `A` and `A₂₂ = A[g,g]`. A positive-definite guard on
the (blended/ridged) genomic block gives a clear `ArgumentError` for a singular
raw `G`. Unexported and not wired into fitting.

## The Subtlety

The single ssGBLUP bug is conflating `A₂₂⁻¹ = inv(A[g,g])` with the submatrix
`(A⁻¹)[g,g]`. On the fixture these differ at `[1,1]`: `11/6 ≈ 1.833` vs `2.5`.
A pinned regression guard locks this in.

## Checks

- `Pkg.test()`: passed, 648 total. New testset = 11 checks. All invariants
  re-verified independently before pinning (distinctness, reduction `=0`,
  locality `=0`, symmetry `=0`, scattered rows `=0`, singular guard fires, blend
  rescues).

## Public Claim Audit

Allowed: a single-step H-inverse CONSTRUCTION utility (experimental,
property-checked), NOT wired into fitting, NOT exported.

Blocked (Rose-gated): the words "single-step support" / "ssGBLUP fitting"; any
claim about blending/tuning (`blend_weight`/`tau`/`omega`/`ridge`) correctness —
those defaults must be validated against AGHmatrix::Hmatrix / BLUPF90 / Mrode
Ch.11 first; any export of `single_step` or an Hinv builder; any large-pedigree
claim (dense `A`/`A₂₂⁻¹` is the known ssGBLUP bottleneck).

## Coordination Notes

`single_step()` stays inert (planned). The blending/tuning parameter names and
defaults, if they ever become user-facing controls, must be agreed across both
twins — captured in the Phase-2 coordination ask.

## Known Limitations

- Dense `A`/`A₂₂⁻¹` (`O(n³)`); validation-scale only.
- Blending/τ/ω/ridge defaults not comparator-validated.
- No Mrode Ch.11 worked H/H⁻¹ fixture or external comparator yet.

## Next Actions

1. Adversarial multi-lens review of the five engine slices.
2. R-twin comparator (AGHmatrix::Hmatrix / BLUPF90) for ssGBLUP.
