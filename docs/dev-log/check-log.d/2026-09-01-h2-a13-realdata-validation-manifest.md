# 2026-09-01 — A13 real-data 3-tier validation manifest (Julia lane)

- Added symmetric validation ladder index:
  - `docs/design/real-data-validation-manifest.toml` (17 arcs across tiers 1–4)
  - `test/runtests.jl` — `Real-data validation manifest (A13 three-tier ladder)` testset
- Darwin review stub: `status = "pending"`; Tier 4 placeholder `darwin_review = "blocked"`.
- Draft source: `~/local-scratch/h2-a13-realdata-manifest.md`

Checks:

- `julia --project=. -e 'using TOML; m = TOML.parsefile("docs/design/real-data-validation-manifest.toml"); @assert m["schema_version"] == 1; @assert length(m["arc"]) == 17; println("manifest ok")'`
- `julia --project=. -e 'using Pkg; Pkg.test(; test_args=["Real-data validation manifest (A13 three-tier ladder)"])'`

Claim boundary: manifest index + claim boundaries only; no covered promotion or field-empirical claims.
