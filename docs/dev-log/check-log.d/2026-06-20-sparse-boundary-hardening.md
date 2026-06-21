# 2026-06-20 sparse AI-REML / selinv boundary hardening (#6)

- Goal: add committed deterministic BOUNDARY / STRESS tests for `fit_ai_reml` +
  `pedigree_inverse` + selinv PEV — inbred pedigree, low-h² near-zero optimum, and
  selinv-exact-at-boundary. CORRECTNESS ONLY; no timing/performance asserted.
- Lenses: Henderson (Ainv + MME self-consistency under inbreeding); Gauss (selinv
  boundary correctness); Rose (claim gate).

## What was done

- Added testset "Phase 1 sparse AI-REML / selinv boundary hardening (#6)"
  (`test/runtests.jl`, 16 assertions), placed immediately after the existing
  "Phase 1 large-pedigree sparse AI-REML fit + selinv PEV hardening (#6)" testset.
  Three cases:
  1. **Highly-inbred pedigree** (selfing chain via `allow_selfing = true`, F up to
     0.875, 8 animals): `any(F .>= 0.5)`, `any(F .>= 0.875)`,
     `pedigree_inverse ≈ inv(A)` (atol 1e-8), `fit_ai_reml` converges on a
     structured y, β + EBVs self-consistent with `henderson_mme` (atol 1e-8/1e-7).
  2. **Near-boundary low-h²** (y near-constant): VCs finite and positive (no NaN);
     self-consistency holds; `converged` not asserted (boundary may be false).
  3. **selinv at the boundary**: `prediction_error_variance(:selinv) ≈ :dense` (atol
     1e-8) and `reliability(:selinv) ≈ :dense` (atol 1e-8) on the inbred fit.
- Extended V1-REML + V1-SELINV-PEV rows in `docs/design/validation-debt-register.md`.
- Extended V1-AI-REML + V1-SELINV-PEV evidence strings in `src/validation_status.jl`.
- Extended "Sparse production fitting / AI-REML" + "Production sparse reliability /
  PEV" rows in `docs/design/capability-status.md`.

## Commands / results

```
~/.juliaup/bin/julia --project=. -e 'using Pkg; Pkg.test()'
```
→ **HSquared tests passed (exit 0)**. New boundary-hardening testset: 16/16 PASS.
`validation_status()` = **41 rows** (unchanged).

```
~/.juliaup/bin/julia --project=docs docs/make.jl
```
→ **build complete** (exit 0). No doc errors.

## Claim boundary

CORRECTNESS-AT-BOUNDARY only — three deterministic boundary cases for existing engine
paths; no new algorithm, no performance claim, nothing promoted to covered.
V1-AI-REML stays `covered`; V1-SELINV-PEV stays `partial`.
