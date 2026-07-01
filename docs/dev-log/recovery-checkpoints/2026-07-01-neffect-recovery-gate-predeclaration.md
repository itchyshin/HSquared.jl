# PRE-DECLARATION — N-effect (K=3) REML bias/MCSE recovery gate (V3-NEFFECT-REML)

**Committed BEFORE the gate is run.** This fixes the design, seeds, and pass criteria
for the arbitrary-N independent-random-effect REML estimator (`fit_multi_effect_reml`,
ultraplan Phase 2 P2.1) so there can be no post-hoc relaxation. Harness:
`sim/phase3_neffect_recovery_gate.jl` (byte-identical pre/post run). Doc-33 path-(b)
substitutable gate for a `partial → covered` close; the external same-estimand REML
comparator (`blupf90+` AIREMLF90, 3 effects) is the second leg.

## Model / DGP (K=3, all identifiable, non-confounded)

Records = 800 offspring of a half-sib pedigree (20 sires × 40 dams × 800 offspring,
q = 860 animals). Three INDEPENDENT random effects + residual:

- **animal additive** `u_a ~ N(0, σ_a²·A)` — A-structured via the pedigree (`pedigree_inverse`);
- **maternal-environment** `u_m ~ N(0, σ_m²·I₄₀)` — dam-level, dam-replicated (offspring
  sharing a dam share the value) → identified separately from `σ_a²` by the crossed
  half-sib layout;
- **contemporary group** `u_c ~ N(0, σ_c²·I₈₀)` — 80 groups assigned INDEPENDENTLY of the
  pedigree (the non-confounding device carried over from the two-effect gate);
- **residual** `e ~ N(0, σ_e²·I)`.

**Truth:** `(σ_a², σ_m², σ_c², σ_e²) = (1.0, 0.5, 0.5, 1.0)`, `μ = 2.0` — interior, well
off any boundary.

## Seeds

`20260800 .. 20260847` (48 cold-start seeds; disjoint from every prior range incl. the
two-effect gate `20260700..20260747`). `MersenneTwister(seed)` per seed (no global state).
Cold start: `initial = [1.0, 1.0, 1.0, 1.0]` (the estimator must find the basin unaided).

## PASS criteria (ALL required; NO relaxation)

1. **48/48 converged** (`fit.converged`).
2. **|bias| ≤ 2·MCSE** for EACH of `σ_a²`, `σ_m²`, `σ_c²`, `σ_e²`, where `bias = mean −
   truth`, `MCSE = sd/√48`.

Read as **NO DETECTABLE across-seed bias** (a low-power non-rejection), never "unbiased".

A FAILURE is a **banked negative**: `V3-NEFFECT-REML` stays `partial`; the design is not
re-tuned to pass.

## Scope of the resulting covered claim (if it passes + comparator agrees + Rose)

`fit_multi_effect_reml` correctly implements arbitrary-N INDEPENDENT-effect REML on the
tested identified design — NOT small-sample accuracy of any single component, NOT
correlated effects (that is `V4-DIRECT-MATERNAL`), NOT production sparse scale (dense
oracle), NOT an R public surface. Covered ≠ retires the standing debt (sparse AI-REML
`K`-component estimator, broader designs, the R bridge).

Run: `env OPENBLAS_NUM_THREADS=1 julia --project=. sim/phase3_neffect_recovery_gate.jl`
