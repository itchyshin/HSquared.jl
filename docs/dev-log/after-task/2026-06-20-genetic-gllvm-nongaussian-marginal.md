# After-task — Genetic-GLLVM non-Gaussian K-factor latent marginal (#50 slice 2)

Date: 2026-06-20. Lane: Julia engine (`HSquared.jl`). Branch:
`julia/genetic-gllvm-nongaussian-marginal`. Genetic GLLVM (#50) — the non-Gaussian
remainder of slice 2: **the genuinely new capability** (the gap §3 of the scope doc).
Built under a `/goal` push ("finish all of 1") with ultracode verification.

## Summary

Landed `gllvm_laplace_marginal_loglik(Y, Ainv, loadings, family; X)` (internal,
`src/genetic_gllvm.jl`) — the Laplace-approximate marginal log-likelihood of the
**K-factor genetic GLLVM**: latent field `vec(g) ~ N(0, I_K ⊗ A)` (each factor
`g[·,k] ~ N(0,A)` independently), `η[i,t] = (Xβ)[i,t] + Σ_k Λ[t,k] g[i,k]`,
`y[i,t] | η ~ family` (Gaussian/Poisson/Bernoulli/Binomial), `β` flat-integrated.
It generalizes the single-factor `laplace_marginal_loglik` by replacing
`(Z, Ainv/σ²a)` with `(W, I_K ⊗ Ainv)`, where `W` is the Λ-weighted latent design
(record `(i,t)` scatters `Λ[t,:]` into animal `i`'s `K` factor slots) — penalized-IRLS
Newton over `[β; vec(g)]`, then a Gaussian integral at the mode.

This is the genuinely new genetic-GLLVM piece: a `K>1` latent field carrying a genetic
relationship under a non-Gaussian response — what neither `nongaussian.jl` (single
factor) nor `multivariate.jl` (Gaussian) provided alone.

## Validation (two INDEPENDENT trusted-path reductions, machine precision)

1. **`K=1, T=1` → single-factor `laplace_marginal_loglik`** (`σ²a = λ²`), EXACTLY for
   BOTH Gaussian (machine precision) and Poisson (rtol 1e-7) — the Laplace
   approximation is invariant under the affine latent reparameterization `u = λg`.
2. **Gaussian, full-rank `Λ` (`K=T`) → `_multivariate_reml_loglik`** at `G0 = ΛΛ'`,
   `R0 = σ²e·I` (Gaussian Laplace is exact, rtol 1e-7).
3. Bernoulli/Binomial convergence with mode-stationarity (`‖∇‖ < 1e-8`) + guards.

## Definition of Done

- implementation — `gllvm_laplace_marginal_loglik` in `src/genetic_gllvm.jl` (moved
  the include AFTER `nongaussian.jl` so `ResponseFamily`/`_fam_*` resolve at
  method-definition time); internal (not exported), mirroring the single-factor kernel.
- tests — "Genetic-GLLVM K-factor latent Laplace marginal (#50 slice 2, non-Gaussian)":
  11 assertions (the two reductions × families, mode-stationarity, shapes, guards). Full suite green.
- documentation — docstring (model + reductions + scope caveats); capability-status
  row (NEW) + `V6-GGLLVM-MARGINAL` validation-debt row (NEW) + `validation_status()`
  row (NEW → **40 rows**; count assertion + `[end].id` updated). No `api.md` change
  (internal, like the single-factor kernel).
- check-log — `docs/dev-log/check-log.d/2026-06-20-genetic-gllvm-nongaussian-marginal.md`.
- after-task — this file.
- Rose audit — see below (ultracode adversarial verification + Rose synthesis).
- clean local checks — `Pkg.test()` + `docs/make.jl`.
- clean CI — gated on the PR.

## Rose audit / ultracode verification

A bounded adversarial-verification Workflow ran (3 independent lenses — Gauss
[numerics + Laplace formula], Noether [design-matrix/ordering], Curie [test soundness
+ untested failure modes] — then a Rose claim-vs-evidence synthesis). **Verdict:
`confirmed_correct` (all 3 lenses) — MERGE.** Rose verified the math against a
first-principles re-derivation, an independent finite-difference Hessian, and the
three machine-precision reductions; Curie independently recomputed the Bernoulli
K=2 Laplace value (matched to 0.0) and verified K>T + singular-`G_lat` work. Every
finding was a test-coverage gap or a documented scope limit — none undermined
correctness. **The two MEDIUM test gaps were closed in-PR before merge:**

1. The non-Gaussian K>1 loglik VALUE is now pinned (not just stationarity) via a
   block-diagonal-`Λ` anchor: independent traits ⇒ the K=2 Poisson marginal equals
   the SUM of two single-factor `laplace_marginal_loglik` calls (machine precision).
2. K>T and singular-`ΛΛ'` (K<T, no Ψ) are now tested against `_multivariate_reml_loglik`
   (the `P = I_K ⊗ Ainv` full-rank property that distinguishes the Laplace path from
   the Gaussian-MME path, which rejects a singular `G_lat`).

LOW findings (convergence-flag off-by-one → `maxiter ≥ 2` for an exact Gaussian solve;
missing-Y → honest NaN; non-convergence partial-result contract; dense/canonical-link
scope) are documented (docstring) or are inherited documented scope limits — no code
change needed.

## Claim boundary

Experimental, dense/validation-scale, SUPPLIED loadings (NOT estimated — slice 3 REML),
one family for all traits, balanced/fully-observed `Y` only; internal/not-exported; no
R model-spec or bridge payload. `GLLVM-style animal models` stays `planned`. Nothing
promoted to covered.

## Next

Slice 3 — genetic-GLLVM REML: estimate the structured `G_lat` (loadings `Λ` / `Ψ`) by
maximizing this marginal (reusing the `fit_laplace_reml` / multivariate-REML optimizer
patterns over the FA parameterization), with a fitted-object/EBV extractor surface and
an external GLLVM.jl/gllvmTMB comparator. Then per-trait families + unbalanced records.
