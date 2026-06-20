# 2026-06-20 Metafounder animal-model MME solve (supplied Γ, #53)

- **Goal:** close the "not wired into `henderson_mme`" gap for the validated
  supplied-Γ metafounder relationship (#53/#82) — make `A^Γ` usable in an actual
  animal-model BLUP at supplied variance components.
- **Active lenses:** Henderson (MME/BLUP) + Mrode (animal-model canon) + Gauss
  (numerics) + Rose (claims). Falconer (quant-gen interpretation of the metafounder base).
- **Spawned subagents:** Rose audit (actual subagent) — see after-task.
- **What landed:** `metafounder_animal_model(y, X, Z, pedigree, group_of, Γ, σ²a, σ²e;
  ids = pedigree.ids)` (exported) — builds the descriptive animal-only precision
  `inv(A^Γ)` via `metafounder_relationship_inverse` and solves `henderson_mme`,
  returning the `HendersonMMEResult`. ~8 LOC (a faithful wrapper; `animal_model_spec`
  already accepts an arbitrary square `Ainv`, so no engine change was needed — the gap
  was a tested convenience + the reduction proof).
- **TDD:** test-first; RED via standalone `metafounder_animal_model` → `UndefVarError`;
  then the minimal wrapper.
- **Verification (deterministic, RNG-free):**
  - `~/.juliaup/bin/julia --project=. -e 'using Pkg; Pkg.test()'` → **passed**; new
    testset `Phase 1 metafounder animal-model MME solve (supplied Γ, #53)` green.
  - Gates: **`Γ=0` reduction** — β + EBVs equal `henderson_mme` with `pedigree_inverse`
    (atol 1e-9); **faithful wrapper** — equals the manual `metafounder_relationship_inverse`
    spec solve (atol 1e-12); **`Γ≠0` sensitivity** — the shared-metafounder base changes
    the EBVs (>1e-6); EBV ids == `pedigree.ids`; the `Z`-columns/`Ainv`-size guard throws.
  - `docs/make.jl` run locally (api.md `@docs` extended with `metafounder_animal_model`).
- **Honest status:** `capability-status.md` (metafounder row) and the in-code
  `validation_status()` `V1-METAFOUNDER` row updated — "wiring into `henderson_mme`"
  moved from deferred/missing to landed (Γ=0 reduction tested); single-step `H^Γ`,
  Γ/variance estimation, and external comparator remain deferred. `validation_status()`
  stays at 38 rows. No register row exists for metafounders (tracked in-code).
- **Claim boundary:** supplied-variance + supplied-Γ animal-only BLUP under `A^Γ`;
  neither `Γ` nor the variance components estimated; no single-step `H^Γ`, no external
  comparator, no R model-spec. Nothing promoted to covered.
