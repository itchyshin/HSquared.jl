# After-task — Genetic-GLLVM REML: factor-analytic (+Ψ) structure (#50)

Date: 2026-06-20. Lane: Julia engine (`HSquared.jl`). Branch:
`julia/genetic-gllvm-fa-reml`. Follow-on to slice 3 (#103) — adds the factor-analytic
latent structure to the genetic-GLLVM REML.

## Summary

Extended `fit_gllvm_laplace_reml` with `structure = :lowrank | :factor_analytic`. The
FA path additionally estimates a per-trait specific genetic variance `Ψ > 0`, so
`G_lat = ΛΛ' + diag(Ψ)`. Implementation trick: `ΛΛ' + diag(Ψ) = [Λ | diag(√Ψ)] · [Λ |
diag(√Ψ)]'`, so the FA fit augments the loadings to `[Λ | diag(√Ψ)]` (with `Ψ` on the
`log` scale) and reuses `gllvm_laplace_marginal_loglik` UNCHANGED — no marginal change.
The result now also carries `uniqueness` (`Ψ̂` for FA, `nothing` for low-rank).

## Validation (correctness, not recovery)

- **Gaussian FA self-consistency**: the optimum's marginal equals
  `_multivariate_reml_loglik` at `Ĝ = Λ̂Λ̂' + Ψ̂` (rtol 1e-7).
- `communality < 1` (since `Ψ̂ > 0` ⇒ specific variance is present).
- **FA nests low-rank**: `FA loglik ≥ low-rank loglik` (the FA optimum can always match
  low-rank as `Ψ → 0`).
- A multi-trait Poisson FA fit converges with `Ψ̂ > 0`.
- Guards: bad `structure`, wrong `initial_uniqueness` length; low-rank still returns
  `uniqueness === nothing`.

## Definition of Done

- implementation — `structure`/`initial_uniqueness` kwargs on `fit_gllvm_laplace_reml`
  (`src/genetic_gllvm.jl`); the `augment` helper builds `[Λ | diag(√Ψ)]`; internal.
- tests — the "Genetic-GLLVM REML over G_lat (#50 slice 3)" testset extended 12 → 21
  assertions (the FA block + guards). Full suite green.
- documentation — docstring (the FA structure + augmentation); capability-status +
  `V6-GGLLVM-REML` validation-debt + `validation_status()` rows EXTENDED (no new row —
  same capability; `validation_status()` stays 41 rows). No `api.md` change (internal).
- check-log — `docs/dev-log/check-log.d/2026-06-20-genetic-gllvm-fa-reml.md`.
- after-task — this file.
- Rose audit — inline (below).
- clean local checks — `Pkg.test()` + `docs/make.jl`.
- clean CI — gated on the PR.

## Rose audit (claim-vs-evidence)

Rose-lens audit (inline). **CLEAN.** The FA fit reuses the verified marginal via a
mathematically exact augmentation (`[Λ | diag(√Ψ)]·[…]' = ΛΛ' + diag(Ψ)`); the Gaussian
self-consistency, `communality < 1`, FA-nests-low-rank, and Poisson-convergence checks
back the claim; rotation-invariance is preserved (only `G_lat`/descriptors/`Ψ` are
reported, never raw `Λ̂`); the no-recovery framing is unchanged. Folded into the
existing `V6-GGLLVM-REML` row (no inflated validation row, count stays 41). Nothing
covered.

## Claim boundary

Experimental, dense/validation-scale, low-rank + factor-analytic `G_lat`, one family
for all traits, balanced/fully-observed `Y`, INTERNAL. No known-truth recovery, no
fitted-object/EBV extractor surface, no per-trait families, no R model-spec/bridge.
Nothing promoted to covered.

## Next

A known-truth recovery study (opt-in), a fitted-object/EBV extractor +
`nongaussian_result_payload` analogue, per-trait families, unbalanced/missing records,
the external GLLVM.jl/gllvmTMB comparator, and the R `gllvm()` bridge (gated on #50).
