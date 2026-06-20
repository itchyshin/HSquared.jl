# After-task — Genetic-GLLVM descriptors from an estimated FA fit (#50)

Date: 2026-06-20. Lane: Julia engine (`HSquared.jl`). Branch:
`julia/genetic-gllvm-fit-descriptors`. Genetic GLLVM (#50) — extends the
supplied-loadings descriptors (slice 1) to estimated factor-analytic fits.

## Summary

Added an overload `genetic_gllvm_descriptors(result::NamedTuple)` (same exported
name, `src/genetic_gllvm.jl`) that reports the rotation-invariant genetic-GLLVM
latent-structure descriptors for an ESTIMATED factor-analytic / low-rank multivariate
REML fit (`fit_multivariate_reml(...; genetic_structure = :factor_analytic | :lowrank`).
It reads the fit's IDENTIFIED, rotation-invariant genetic covariance
`G = result.genetic_covariance` and uniqueness `Ψ` (`genetic_uniqueness`, `nothing`
⇒ low-rank `Ψ = 0`) — never the rotation-nonidentified loadings — and returns the
same NamedTuple as the supplied-loadings method, with `communality = 1 − Ψ/diag(G)`.
Rotation-free `:diagonal`/`:unstructured` fits (no latent-factor interpretation) are
rejected.

## Definition of Done

- implementation — `genetic_gllvm_descriptors(result)` overload in
  `src/genetic_gllvm.jl`; shares the existing export (no new symbol).
- tests — "Genetic-GLLVM descriptors from an estimated FA/lowrank fit (#50)": 14
  assertions — REAL deterministic `fa`/`low` fixture fits (communality
  `= 1 − Ψ/diag(G)` ∈ (0,1) for FA; `= 1` for low-rank; `genetic_pca` delegation;
  shape; rank); a synthetic structured result pinning `communality = (ΛΛ')_tt/G_tt`;
  and rejection of `:unstructured`/`:diagonal`. Full suite green.
- documentation — docstring (rotation-invariant, identified-`G`/`Ψ`-only, honest
  caveats); the shared `docs/src/api.md` `@docs` entry renders both methods
  (docs build clean); capability-status + `V6-GGLLVM-DESC` validation-debt +
  `validation_status()` rows EXTENDED (count stays 39).
- check-log — `docs/dev-log/check-log.d/2026-06-20-genetic-gllvm-fit-descriptors.md`.
- after-task — this file.
- Rose audit — see below.
- clean local checks — `Pkg.test()` + `docs/make.jl`.
- clean CI — gated on the PR.

## Rose audit (claim-vs-evidence)

Rose-lens audit (inline review perspective). **Verdict: CLEAN.** The overload reads
ONLY the rotation-invariant identified quantities (`G`, `Ψ`) — never the loadings —
so the rotation-invariance discipline holds by construction; `communality = 1 −
Ψ/diag(G) = (ΛΛ')_tt/G_tt` is pinned both against real fits and a synthetic result;
rotation-free structures are rejected (tested); honest status preserved by folding
into `V6-GGLLVM-DESC` (no new validation row, count stays 39). Nothing estimated by
this slice (it consumes an existing fit); nothing promoted to covered.

## Claim boundary

Descriptive read-out of an existing FA/lowrank fit's identified latent structure —
no new estimation, no R model-spec or bridge payload, rotation-invariant functionals
only. `GLLVM-style animal models` stays `planned`.

## Next

The non-Gaussian latent marginal (slice 2 remainder) and genetic-GLLVM REML (slice 3)
remain the substantial genetic-GLLVM builds.
