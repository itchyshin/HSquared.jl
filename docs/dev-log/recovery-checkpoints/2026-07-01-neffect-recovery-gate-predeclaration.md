# PRE-DECLARATION — N-effect (K=3) REML bias/MCSE recovery gate (V3-NEFFECT-REML)

**Committed BEFORE the gate is run.** Fixes the design, seeds, and pass criteria for the
arbitrary-N independent-random-effect REML estimator (`fit_multi_effect_reml`, ultraplan
Phase 2 P2.1) so there can be no post-hoc relaxation. Harness:
`sim/phase3_neffect_recovery_gate.jl` (byte-identical pre/post run). Doc-33 path-(b)
substitutable gate for a `partial → covered` close; the external same-estimand REML
comparator (`blupf90+` AIREMLF90, 3 effects; `comparator/prepare_blupf90_neffect.jl`) is
the second leg.

## Integrity note — v1 WITHDRAWN (confounded), v2 is this document

A first design (v1) used a dam-level "maternal-environment" third effect. A pre-run
single-seed diagnostic showed it was **CONFOUNDED with the additive relationship**: in the
half-sib layout dam-mates are FULL SIBS, so a dam-level effect aliases the full-sib
additive covariance — `σm²` collapsed to ~0.0008 (truth 0.5) with `converged=false`. v1 was
**withdrawn, not relaxed** (the flaw was found *before* trusting the 48-seed aggregate, and
no criteria were tuned). v2 (below) replaces the confounded effect with the proven
non-confounding device from the two-effect gate — an environmental factor assigned
INDEPENDENTLY of the pedigree — **doubled** to three identifiable effects. A 3-seed
identifiability diagnostic on v2 confirmed convergence with sensible estimates
(`σa²≈1.0–1.2, σg1²/σg2²≈0.4–0.58, σe²≈0.83–0.96`) before this predeclaration was committed.

## Model / DGP (K=3, all identifiable, non-confounded)

Records = all q = 860 animals of a half-sib pedigree (20 sires × 40 dams × 800 offspring),
`Z1 = I_q`. Three INDEPENDENT random effects + residual:

- **animal additive** `u_a ~ N(0, σ_a²·A)` — A-structured via the pedigree;
- **environment 1** `u_g1 ~ N(0, σ_g1²·I₈₀)` — 80 levels, assigned INDEPENDENTLY of the
  pedigree (the non-confounding device);
- **environment 2** `u_g2 ~ N(0, σ_g2²·I₆₀)` — 60 levels, assigned INDEPENDENTLY of the
  pedigree AND of environment 1 (crossed random factors);
- **residual** `e ~ N(0, σ_e²·I)`.

**Truth:** `(σ_a², σ_g1², σ_g2², σ_e²) = (1.0, 0.5, 0.5, 1.0)`, `μ = 2.0` — interior, off
any boundary.

## Seeds

`20260800 .. 20260847` (48 cold-start seeds; disjoint from every prior range incl. the
two-effect gate `20260700..20260747`). `MersenneTwister(seed)` per seed (no global state).
Cold start: `initial = [1.0, 1.0, 1.0, 1.0]`.

## PASS criteria (ALL required; NO relaxation)

1. **48/48 converged** (`fit.converged`).
2. **|bias| ≤ 2·MCSE** for EACH of `σ_a²`, `σ_g1²`, `σ_g2²`, `σ_e²` (`bias = mean − truth`,
   `MCSE = sd/√48`).

Read as **NO DETECTABLE across-seed bias** (a low-power non-rejection), never "unbiased".
A FAILURE is a **banked negative**: `V3-NEFFECT-REML` stays `partial`.

## Scope of the resulting covered claim (if it passes + comparator agrees + Rose)

`fit_multi_effect_reml` correctly implements arbitrary-N INDEPENDENT-effect REML on the
tested identified design — NOT small-sample accuracy of any single component, NOT
correlated effects (`V4-DIRECT-MATERNAL`), NOT production sparse scale (dense oracle), NOT
an R public surface. Covered does not retire the standing debt (sparse AI-REML
`K`-component estimator, broader designs, the R bridge).

Run: `env OPENBLAS_NUM_THREADS=1 julia --project=. sim/phase3_neffect_recovery_gate.jl`
