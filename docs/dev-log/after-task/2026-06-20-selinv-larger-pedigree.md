# After-task — selinv PEV larger-pedigree evidence (V1-SELINV-PEV)

Date: 2026-06-20. Lane: Julia engine. Branch: `julia/s1-selinv-largeped`. Type:
evidence slice (test + honest-status update; no `src/` change).

## Summary

The `:selinv` Takahashi PEV/reliability path was previously validated against the
dense MME inverse diagonal only up to an 8-animal pedigree. This adds a deterministic
110-animal, 4-generation pedigree (disjoint sire/dam pools per generation → genuine
off-diagonal `Ainv`, nnz = 550) and pins `:selinv` PEV-diagonal + reliability ==
`:dense` to rtol 1e-8 (observed ≈ machine precision), `nfixed = 2`. This advances the
V1-SELINV-PEV "large-pedigree" gap at validation scale.

## Definition of Done

- implementation — none (existing `:selinv` path; test-only evidence).
- tests — new testset "Phase 1 selinv PEV — larger multi-generation pedigree
  (V1-SELINV-PEV)"; full suite green (36 status rows).
- documentation — V1-SELINV-PEV evidence updated in `validation_status.jl`,
  `validation-debt-register.md`, `capability-status.md`; gap narrowed to
  production-scale (10⁴+) + external comparator.
- check-log — `docs/dev-log/check-log.d/2026-06-20-selinv-larger-pedigree.md`.
- after-task — this file.
- Rose audit — claim is "selinv == dense to machine precision on a 110-animal
  pedigree; still validation-scale, not production-scale / external-comparator" —
  bounded and honest.
- clean local checks — `Pkg.test()` exit 0.

## Claim boundary

Larger validation-scale correctness only. NOT production-scale (10⁴+ sparse), NOT an
external comparator. `reliability` still forms dense `inv(Ainv)`; default path stays
`:dense`. V1-SELINV-PEV stays `partial`; nothing promoted to covered.

## Next

The remaining V1-SELINV-PEV blocker (production-scale 10⁴+ sparse validation) needs
the production sparse fitting path (planned, not this lane's validation-scale scope).
The cross-lane covered-blockers (external comparators) are unchanged and tracked on
#61.
