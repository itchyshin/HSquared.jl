# 2026-06-20 Genetic-GLLVM descriptors from an estimated FA fit (#50)

- **Goal:** extend the genetic-GLLVM descriptors (slice 1, supplied loadings) to
  ESTIMATED factor-analytic / low-rank multivariate REML fits.
- **Active lenses:** Kirkpatrick (rotation invariance) + Fisher (identifiability) +
  Rose (claims).
- **What landed (`src/genetic_gllvm.jl`):** an overload
  `genetic_gllvm_descriptors(result::NamedTuple)` that reads the fit's IDENTIFIED
  `G = result.genetic_covariance` and `Ψ = genetic_uniqueness(result)` (never the
  loadings) and returns the same descriptor NamedTuple with
  `communality = 1 − Ψ/diag(G)` (`= 1` for low-rank, `Ψ = nothing`). Rejects the
  rotation-free `:diagonal`/`:unstructured` structures. Shares the existing export.
- **TDD:** targeted RED→GREEN; new testset 14 assertions green; full `Pkg.test()` green.
- **Gates:** REAL deterministic `fa`/`low` fixture fits (FA communality `1 − Ψ/diag(G)`
  ∈ (0,1); low-rank communality all 1; `genetic_pca` delegation; shape; rank); a
  synthetic structured result pinning `communality = (ΛΛ')_tt/G_tt`; rejection of
  `:unstructured`/`:diagonal`.
- **Docs:** docstring; shared `api.md` `@docs` renders both methods (docs build clean,
  no missing-docstring warning); capability-status + `V6-GGLLVM-DESC` validation-debt +
  `validation_status()` rows EXTENDED (count stays 39).
- **Honest status:** descriptive read-out of an existing fit's identified latent
  structure — no new estimation, no R model-spec/bridge, rotation-invariant only.
  Nothing covered.
- **Rose audit:** CLEAN (inline). Rotation-invariance holds by construction (reads
  `G`/`Ψ` only, never loadings); communality pinned vs real + synthetic; folded into
  `V6-GGLLVM-DESC` (no inflated row).
