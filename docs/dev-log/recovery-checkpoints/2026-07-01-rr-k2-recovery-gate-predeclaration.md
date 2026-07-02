# PRE-DECLARATION — random-regression k=2 K_g recovery gate (V3-RR-REML)

**Committed BEFORE the gate is run.** Fixes the design, seeds, and pass criteria for a
known-truth `K_g` recovery gate on the random-regression REML estimator
(`fit_random_regression_reml`, `src/random_regression.jl:439`), SCOPED to the covered
aim `k = 2` (the linear reaction norm: intercept + one slope, 2×2 `K_g`). Harness:
`sim/phase3_rr_recovery_gate.jl` (byte-identical pre/post run). Convention lock:
`docs/design/22-rr-convention-lock.md`. Doc-16 path-(b) substitutable gate for a
`partial → covered` close; a same-estimand comparator (WOMBAT / ASReml / sommer `leg()`
on the SAME normalized-Legendre-on-`[-1,1]` basis) is the second leg (a separate slice —
comparator-basis normalization is not part of this gate).

## Load-bearing design point — SLOPE identifiability (records × covariate spread)

The RR estimand adds a SLOPE variance `K_g[2,2]`. It is identified only if animals carry
several records at WELL-SPREAD covariate points across `[-1, 1]`; a narrow range (or one
record per animal) leaves the slope non-identified and the gate would fail for the WRONG
reason (a bad design, not a bad estimator). So every recorded animal gets **MREC = 6
records at `t = -1, -0.6, -0.2, 0.2, 0.6, 1`** (endpoints included, evenly spread) — the
normalized-Legendre design `Φ` then has full column rank and `K_g[2,2]` is identified.
A 3-seed identifiability diagnostic (below) confirmed the slope variance recovers near
truth (does NOT collapse) BEFORE this predeclaration was committed — the same "catch it
pre-declaration" discipline as the neffect gate's v1→v2 withdrawal (`68cc7acc`).

## Model / DGP (k = 2 linear reaction norm)

- **Pedigree:** half-sib q = 360 (20 sires × 40 dams × 300 offspring),
  `normalize_pedigree`, `Ainv = pedigree_inverse(ped)`, `A = inv(Ainv)`.
- **Recorded animals:** the 300 OFFSPRING only (parents unrecorded, the usual layout),
  each recorded at all MREC = 6 covariate points → **n = 1800 records** (kept within the
  dense-oracle scale fence ≲2000; 300 half-sib offspring × 6 spread points identify the
  2×2 K_g incl. the noisy slope variance K_g[2,2]. 300 animals was chosen after a pre-run
  diagnostic showed K_g[2,2] is high-variance — |bias|/MCSE shrinks as √(n_animals), so
  300 gives a comfortable margin for a fair no-detectable-bias test).
- **Per-animal coefficient curves:** `vec(a) ~ N(0, A ⊗ K_g)`, drawn as
  `acoef = chol(A).L · Ξ · chol(K_g).L'` with `Ξ` a `q×k` iid-N(0,1) matrix.
- **Records:** `y_r = μ + φ(t_r)ᵀ a_{animal(r)} + e_r`, `e_r ~ N(0, σ²e)`, with
  `φ` the normalized Legendre basis (`legendre_basis`, `k = 2`) and `Φ =
  legendre_design(ts, 2)`, `Z` the record→animal incidence.
- **Truth:** `K_g = [1.0 0.3; 0.3 0.5]` (so `ρ_g = 0.3/√0.5 ≈ 0.4243`), `σ²e = 1.0`,
  `μ = 2.0` — interior, off any boundary; the slope variance 0.5 is comfortably positive.

## Seeds

`20261000 .. 20261047` (48 cold-start seeds; disjoint from every prior range — two-effect
`20260700..`, neffect `20260800..`, QTL add-one `20260920..`). `MersenneTwister(seed)` per
seed (no global state). **Cold start:** `initial = (K_g = I₂, sigma_e2 = 1.0)` — NOT the
truth.

## PASS criteria (ALL required; NO relaxation)

1. **48/48 converged** (`fit.converged`).
2. **|bias| ≤ 2·MCSE** for EACH of `K_g[1,1]`, `K_g[2,2]`, `K_g[1,2]`, and `σ²e`
   (`bias = mean − truth`, `MCSE = sd/√48`).
3. **`ρ_g = K_g[1,2]/√(K_g[1,1]·K_g[2,2])` is REPORTED, not gated** (a ratio of
   estimates, not an additive component).

Read as **NO DETECTABLE across-seed bias** (a low-power non-rejection), never "unbiased".
A FAILURE is a **banked negative**: `V3-RR-REML` stays `partial`.

## Scope of the resulting covered claim (if it passes + comparator agrees + Rose)

`fit_random_regression_reml` correctly implements dense REML estimation of a 2×2
coefficient genetic covariance `K_g` + homogeneous `σ²e` for the normalized-Legendre
linear reaction norm on the tested identified design — NOT small-sample accuracy of any
single `K_g` entry, NOT `k ≥ 3` (post-v1.0 via reduced-rank / factor-analytic `K_g`), NOT
a permanent-environment decomposition (homogeneous residual only; `h²(t)` can overstate —
see the convention lock §3), NOT a curve-valued EBV-trajectory PEV claim, NOT the R public
default, NOT a production sparse RR solver. Covered does not retire the standing debt (the
comparator-basis-normalization slice, the PE random-regression term, curve-valued PEV, the
R `rr()` public claim). `public_covered_count` unchanged (engine-covered ≠ R-public-covered).

Run: `env OPENBLAS_NUM_THREADS=1 julia --project=. sim/phase3_rr_recovery_gate.jl`
