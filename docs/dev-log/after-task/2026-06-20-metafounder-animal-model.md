# After-task — Metafounder animal-model MME solve (supplied Γ, #53)

Date: 2026-06-20. Lane: Julia engine (`HSquared.jl`). Branch:
`julia/metafounder-animal-model`. Wires the validated supplied-Γ metafounder
relationship (#82) into the supplied-variance animal-model solve.

## Summary

Added `metafounder_animal_model(y, X, Z, pedigree, group_of, Gamma, sigma_a2,
sigma_e2; ids = pedigree.ids)` (exported): builds the descriptive animal-only
metafounder precision `inv(A^Γ)` via `metafounder_relationship_inverse` and solves
the standard Henderson MME (`henderson_mme`), returning the `HendersonMMEResult` — an
animal-only BLUP under the metafounder-augmented relationship `A^Γ` (Legarra et al.
2015). Closes the documented "not wired into `henderson_mme`" gap. ~8 LOC: because
`animal_model_spec` already accepts an arbitrary square `Ainv`, the engine needed no
change — the gap was a tested convenience + the reduction proof.

## Definition of Done

- implementation — `metafounder_animal_model` in `src/likelihood.jl` (after
  `henderson_mme`); exported in `src/HSquared.jl`.
- tests — "Phase 1 metafounder animal-model MME solve (supplied Γ, #53)" (7 assertions):
  `Γ=0` reduction to the classical animal model (β/EBVs == `henderson_mme` with
  `pedigree_inverse`); faithful-wrapper identity vs the manual spec solve; `Γ≠0`
  EBV-sensitivity; EBV ids; `Z`-columns/`Ainv`-size guard.
- documentation — docstring; `docs/src/api.md` `@docs` block; `docs/make.jl` exit 0.
- example / not-public note — EXPERIMENTAL caveats; no R model-spec.
- check-log — `docs/dev-log/check-log.d/2026-06-20-metafounder-animal-model.md`.
- after-task — this file.
- capability-status row — metafounder row updated (wiring deferred→landed).
- validation-debt row — in-code `validation_status()` `V1-METAFOUNDER` evidence +
  "missing" updated (no register row exists for metafounders; tracked in-code). 38 rows.
- Rose audit — ran (actual subagent). Verdict **MERGE**; no must-fix/should-fix.
- clean local checks — `Pkg.test()` passed (new testset 7/7; suite green) +
  `docs/make.jl` exit 0.
- clean CI — gated on the PR.

## Review (Rose claim-vs-evidence, actual subagent)

Verdict **MERGE** (clean). Rose reproduced the `Γ=0` reduction (bit-exact, Δ=0.0 —
the test's atol 1e-9 is a conservative envelope), the faithful-wrapper identity, and
the `Γ≠0` sensitivity (0.0146). Crucially she added an independent check the slice
itself does not: the animal-only EBVs from `metafounder_relationship_inverse` match
the **full combined MME with explicit metafounder levels** (`metafounder_inverse`) to
**1.5e-15** — confirming the descriptive animal-only precision is the correct choice
for an animal-only solve (the two inverses differ, but yield identical animal
predictions). Confirmed: no overclaim, row stays `partial`, nothing promoted to
covered, no Γ/variance-estimation or comparator claim. One cosmetic nit (cite
"machine precision" vs "atol 1e-9") — left as the committed test tolerance.

## Claim boundary

Supplied-variance + supplied-Γ animal-only BLUP under `A^Γ`; neither `Γ` nor the
variance components is estimated. NOT included: single-step `H^Γ`, the combined
system with explicit metafounder effects as a fitted path, Γ estimation, an external
comparator (Legarra 2015 / BLUPF90), and any R model-spec / bridge payload. Nothing
promoted to covered.

## Next

Genetic GLLVM (#50) remains gated (cross-team Q1/Q2 + #44/#37). Other unblocked solo
candidates: RR permanent-environment term / curve-valued EBV-trajectory PEV; a
metafounder external comparator (opt-in BLUPF90, cross-lane); the matrix-free-PCG
large-pedigree benchmark (a performance claim — gated on a recorded measurement).
