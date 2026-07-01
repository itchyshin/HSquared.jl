# 2026-07-01 v0.6 Gamma LATENT-scale h² — trigamma V_link (doc-19 §3.1)

## Goal
Lens: Falconer/Fisher/Gauss + Rose. Resolve the fenced Gamma `V_link` convention, then implement the
Gamma latent-scale heritability in `nongaussian_heritability`. Extends `V6-NS-H2` (stays `partial`,
count 50). Branch off `main` (composes with #221 — same function, trivial keep-both at merge).

## What was done
- **Resolved the constant (doc-19 §3.1):** the Gamma-log latent residual is exactly
  `V_link = Var[log Y] = ψ₁(shape)` (trigamma), NOT the `ln(1+1/ν)` lognormal/CV approximation.
  **Verified dependency-free** (3×10⁶ Marsaglia–Tsang draws/shape): empirical `Var[log Y]` matches
  `ψ₁(ν)` to 3–4 sig figs across ν∈{0.5,1,2,5}; the lognormal approx is off ~4.5× at ν=0.5. So the
  fence is removed by DERIVATION + numerical proof (doc-19 Rule 1), not a guess.
- **`src/nongaussian.jl`:** new dependency-free `_trigamma(x)` (recurrence to x≥6 + asymptotic,
  ~3e-9, matching `_digamma`'s strategy). New `:gamma` branch in `_nongaussian_h2_core` (via a `shape`
  kwarg threaded from the fit's `variance_components.shape` or the `GammaResponse` object):
  `h²_latent = V_A/(V_A + ψ₁(ν) + V_fixed)`, **NON-degenerate** (unlike Poisson `V_link=0`),
  `var_link = ψ₁(ν)`, `method = :gamma_trigamma_latent`, observation scale fenced (NaN). Positive-shape
  + missing-shape guards. `_h2_family_params(::GammaResponse)`.
- **`test/runtests.jl`:** new testset — `_trigamma` closed forms (ψ₁(1)=π²/6, ψ₁(2)=π²/6−1,
  ψ₁(½)=π²/2) + recurrence; the Gamma latent closed form; μ-independence; V_fixed denominator;
  monotone-in-ν; NaN observation; shape guards.
- **Status (3 surfaces):** V6-NS-H2 evidence adds the Gamma latent scale; owed moves probit/Gamma from
  "families pending" → "the Gamma/threshold OBSERVATION scale pending (Gamma LATENT now done)".

## Commands / results
- `_trigamma(1)=1.6449340700 ≈ π²/6`; Gamma `h2_latent(V_A=1,ν=1)=0.37808 = 1/(1+π²/6)`;
  `var_link=ψ₁(1)`, `method=:gamma_trigamma_latent`, obs NaN; V_fixed enters; neg-shape throws.
- `Pkg.test()` → PASS (new testset; count guard `== 50` UNCHANGED — extends V6-NS-H2).
- Real `rose-systems-auditor` audit (recorded in the PR / status).

## Claim boundary
LATENT (log) scale only — an EXACT closed form (verified constant); no recovery gate / same-estimand
comparator owed for the deterministic latent value (the QGglmm/MCMCglmm debt is for the OBSERVATION
scale, retained). `validation_status()` = 50 UNCHANGED; public-covered fitting = 1 UNCHANGED; NOT a
covered claim. The Gamma OBSERVATION/data scale (NS-2017 multiplicative) + the threshold observation
scale remain fenced follow-ups. Merge note: this branch (off main) composes with #221 (liability h²)
— both add an `elseif` to `_nongaussian_h2_core` + extend the same V6-NS-H2 row → trivial keep-both.
