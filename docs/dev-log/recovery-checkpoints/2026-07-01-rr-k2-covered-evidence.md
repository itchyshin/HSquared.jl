# V3-RR-REML k=2 covered evidence — gate PASS + sommer leg() comparator AGREE (2026-07-01)

Both doc-16 covered legs for the random-regression REML estimator (`fit_random_regression_reml`)
at the covered aim **k=2** (linear reaction norm, intercept + one slope, 2×2 coefficient genetic
covariance `K_g`) are satisfied. Banks the evidence for the `partial → covered` flip
(engine / validation-scale) and, paired, the R public surface (`rr()`).

## Leg 1 — PRE-DECLARED 48-seed bias/MCSE recovery gate: PASS

- Predeclaration committed **before** the run: `b3e97835`
  (`docs/dev-log/recovery-checkpoints/2026-07-01-rr-k2-recovery-gate-predeclaration.md`),
  after pre-run diagnostics right-sized the DGP (the slope variance K_g[2,2] is high-variance;
  200 animals was a coin-flip, 300 gives a fair margin — |bias|/MCSE shrinks as √n_animals).
  Harness `sim/phase3_rr_recovery_gate.jl` byte-identical pre/post.
- DGP: half-sib q=360 (300 recorded offspring × 6 spread normalized-Legendre covariate points,
  n=1800, within the dense-oracle scale fence); truth K_g=[1.0 0.3; 0.3 0.5], σ²e=1.0, μ=2.0;
  seeds 20261000..20261047; cold start K_g=I₂.
- **Result: 48/48 converged; all four `|bias| ≤ 2·MCSE`:**

  | component | mean | truth | bias | \|bias\|/MCSE |
  | --- | --- | --- | --- | --- |
  | K_g[1,1] | 0.9781 | 1.00 | −0.0219 | 1.16 |
  | K_g[2,2] | 0.5183 | 0.50 | +0.0183 | 1.67 |
  | K_g[1,2] | 0.2984 | 0.30 | −0.0016 | 0.17 |
  | σ²e      | 0.9992 | 1.00 | −0.0008 | 0.15 |

  ρ_g REPORTED (not gated): mean 0.4205 vs truth 0.4243. Read as **NO DETECTABLE across-seed
  bias** (the noisy slope variance at 1.67·MCSE), never "unbiased".

## Leg 2 — same-estimand external REML comparator (`sommer` 4.4.5 `leg()`): AGREE

- `comparator/prepare_sommer_rr.jl` reconstructs the predeclared seed-20261000 dataset EXACTLY
  (same RNG draw order as the gate) + records the engine optimum; `comparator/run_sommer_rr.R`
  fits the SAME model via the current sommer interface `mmes(y~1, random=~vsm(usm(leg(t,1)),
  ism(id), Gu=A), rcov=~units)` (the legacy `mmer`/`vsr` silently collapses the RR — do NOT use).
- **Legendre-normalization check (the load-bearing trap):** sommer's `leg()` uses the IDENTICAL
  normalized Legendre `φ_n(t)=√((2n+1)/2)·P_n(t)` as the engine — diagonal **D = I₂**, max basis
  difference 7.4e-13. No back-transform needed; the comparison is on absolute VARIANCE entries in
  the common basis (NOT correlation-only, which would be a false pass).
- **Result: AGREE — all entries + σ²e match to ≤1.9e-5 relative:**

  | component | engine | sommer | rel.diff |
  | --- | --- | --- | --- |
  | K_g[1,1] | 0.914884 | 0.914867 | 1.9e-5 |
  | K_g[2,2] | 0.469791 | 0.469795 | 7.7e-6 |
  | K_g[1,2] | 0.369880 | 0.369881 | 1.4e-6 |
  | σ²e      | 1.020958 | 1.020959 | 8.4e-7 |

  Both maximize the same REML likelihood on the same data (single-seed point-estimate leg,
  complementary to the 48-seed gate).

## Scope of the covered claim (k=2)

`fit_random_regression_reml` correctly implements the k=2 linear reaction-norm REML (2×2 `K_g` +
homogeneous σ²e) on the tested identified design (normalized Legendre, dense/validation-scale).
NOT: k≥3 (reduced-rank/FA, post-v1.0); heterogeneous residual or permanent-environment terms;
production sparse scale. h² is a covariate-INDEXED CURVE (never a scalar); the animal-block ratio
is narrow-sense h², other blocks are variance-explained proportions (with the PE-overstatement
caveat: homogeneous residual + no PE term inflates h²(t) for repeated-records designs). `(x|g)`
raw random slopes stay a frozen slot (no estimator). Convention: `docs/design/22-rr-convention-lock.md`.

Maintainer G10 delegated ("flip autonomously once evidence passes"); real `rose-systems-auditor`
audit on the flip before promotion.
