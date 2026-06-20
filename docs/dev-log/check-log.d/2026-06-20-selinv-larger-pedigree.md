# 2026-06-20 selinv PEV — larger multi-generation pedigree (V1-SELINV-PEV)

- Goal: advance the V1-SELINV-PEV "large-pedigree" gap — the prior `:selinv` PEV
  correctness evidence capped at an 8-animal pedigree. Add a deterministic larger
  case. Solo engine evidence slice; no new capability, no src change.
- Lenses: Henderson + Gauss (selinv correctness); Rose (claim gate).

## What was done

- Added the testset "Phase 1 selinv PEV — larger multi-generation pedigree
  (V1-SELINV-PEV)" (`test/runtests.jl`): a deterministic (RNG-free) 4-generation,
  110-animal pedigree — each generation draws sires and dams from DISJOINT halves of
  the previous generation, so parents are always distinct and precede their offspring
  (off-diagonal `Ainv`, nnz = 550). At supplied interior variances it asserts the
  `:selinv` PEV diagonal == `:dense` and `:selinv` reliability == `:dense` to rtol
  1e-8 (observed max PEV diff ≈ 5e-16, machine precision), with `nfixed = 2`.
- Updated the V1-SELINV-PEV evidence on all three honest-status surfaces
  (`src/validation_status.jl`, `docs/design/validation-debt-register.md`,
  `docs/design/capability-status.md`) to cite the 110-animal case; narrowed the
  remaining gap to "production-scale (10⁴+ sparse) validation" + external comparator.

## Commands / results

- `~/.juliaup/bin/julia --project=. -e 'using Pkg; Pkg.test()'` → **passed (exit 0)**
  (new larger-pedigree selinv testset green; full suite green; `validation_status()`
  36 rows).

## Claim boundary

Correctness evidence at LARGER validation scale (110 animals), NOT a production-scale
(10⁴+ sparse) or external-comparator claim. The `reliability` denominator still forms
the dense `inv(Ainv)`; the default extractor path stays `:dense`. No capability moved
to covered; V1-SELINV-PEV stays `partial`.
