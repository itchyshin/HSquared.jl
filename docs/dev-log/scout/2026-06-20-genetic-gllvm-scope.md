# Genetic GLLVM (#50) — scope + reuse-not-reinvent boundary

Author: Ada (Julia engine lane), 2026-06-20. Status: **scout / design note**, no
capability claimed. This persists the synthesis the in-flight scout Workflow
(`wf_c6909293-e28`) was producing when it was killed mid-run (`result: null`,
4 Explore agents still "in progress"); the study was redone read-only this
session via three parallel Explore passes (GLLVM.jl engine, gllvmTMB
animal-keyword, HSquared Phase-6) plus a direct licence/file verification.

Binding user directives carried into this note:

1. **The GLLVM team already has working code — REUSE it, do NOT reinvent.**
2. The genetic-GLLVM work must **inherit the existing programme** — the plan
   (`ROADMAP.md` / `docs/design/11-completion-plan.md`), mission control
   (`status.json` widget), and the goal/doctrine (`AGENTS.md`: honest status,
   Definition of Done, lane routing, #61 cross-lane). It is **one programme**.

## 1. What a "genetic GLLVM" is in this ecosystem

A GLLVM (generalized linear latent-variable model) explains many responses
`y[i,t]` (individual `i`, trait/response `t`) through a few latent factors per
individual and a loadings matrix `Λ` (`t × K`), under a non-Gaussian response
family. A **genetic** GLLVM is the special case where the latent rows
(individuals) are **not i.i.d.** — they carry a **genetic-relationship
covariance** `A` (pedigree / genomic / metafounder). Concretely (mirroring the
gllvmTMB `animal_*` design):

```
η[i,t] = X β + Σ_k Λ[t,k] · g[i,k]          (linear predictor)
g[·,k] ~ N(0, A)        for each latent factor k = 1..K   (genetic latent field)
y[i,t] | η[i,t] ~ Family(link⁻¹(η[i,t]))                  (non-Gaussian response)
```

so `vec(U) ~ N(0, G_lat ⊗ A)` with `G_lat = ΛΛ' (+ Ψ)` the among-trait genetic
covariance implied by the loadings. This is **exactly** "plug HSquared's
relationship inverse + non-Gaussian marginal into the GLLVM latent layer" — NOT
a from-scratch GLLVM. HSquared already has the **single-factor** version of this
object (`nongaussian.jl`: `u ~ N(0, A σ²a)` under Poisson/Bernoulli/Binomial);
the GLLVM generalization is **K > 1 latent factors with a structured `G_lat`**.

## 2. Reuse boundary (the heart of the note)

### 2a. GLLVM.jl — MIT, Copyright 2026 Shinichi Nakagawa (the user's own engine)

Licence-clean to reuse (adapt patterns freely; still validate independently per
AGENTS.md rule 4). The reuse map indicates these are the load-bearing pieces:

| Piece | File (GLLVM.jl) | Reuse |
| --- | --- | --- |
| Loadings pack/unpack (lower-triangular, AD-safe) | `src/packing.jl` | adapt the parameterization pattern |
| PPCA warm-start | `src/ppca_init.jl` | call/adapt for init (later fitting slice) |
| EM-FA factor solver (Rubin–Thayer M-step) | `src/em_fa.jl` | adapt for the FA `G_lat` update (later) |
| Structured covariance builders (`relatedness_cov`, `spatial_cov`) | `src/structured_cov.jl` | reuse pattern for the relationship-as-row-covariance |
| Derived-quantity + CI infra (`communality`, `correlation`, profile/bootstrap CI) | `src/confint*.jl`, `src/postfit.jl` | adapt the rotation-invariant reporting + CI scaffolding (later) |

**Do NOT reinvent** (GLLVM.jl already solves these): reduced-rank loading
parameterization, the Gaussian Woodbury marginal, PPCA init, EM-FA, the Laplace
non-Gaussian families, the CI infrastructure, and the rotation-invariant derived
quantities (`communality` etc.).

**Key architectural fact:** GLLVM.jl's latent **rows are i.i.d. `N(0,I)`**; its
structured covariance (`Σ_phy`, phylogenetic) acts on the **trait/species axis**,
not the latent-row axis. So the genetic-row-covariance is exactly the gap (§3).

**Dependency decision (deferred, cross-lane):** whether HSquared.jl should take a
package *dependency* on GLLVM.jl (it is the user's own MIT package, UUID
`2dc8e01c-…`) or mirror only the needed patterns is a **later-slice / cross-team**
decision — it is NOT needed for the descriptors-first slice (§4), which reuses
only HSquared's own code.

### 2b. gllvmTMB — **GPL-3**: design/grammar to MIRROR, NO code copy

GPL-3 (and R/TMB), so the AGENTS.md rule is strict: **adapt the design and
grammar, copy no code**. The design to mirror (`R/animal-keyword.R` + the C++
latent kernel, per the reuse map):

- **Grammar:** an `animal_*()` keyword family mirroring `phylo_*()` —
  `animal_scalar` (one shared genetic variance), `animal_unique` (per-trait,
  shared relatedness), `animal_indep` (diagonal), `animal_dep` (unstructured
  `G`), **`animal_latent(id, d = K)`** (reduced-rank factor-analytic `G = ΛΛ'+Ψ`,
  the GLLVM case), `animal_slope`. Three relatedness inputs unified internally to
  `Ainv` + log-det: `pedigree`, dense `A`, or sparse `Ainv`.
- **Latent layer:** `vec(U) ~ N(0, G ⊗ A)`; for `animal_latent`, `g[·,k]~N(0,A)`
  per factor and `η[i,t] += Σ_k Λ[t,k] g[i,k]`; the prior enters as the sparse
  quadratic `0.5[n log2π + log|A| + gₖ' Ainv gₖ]` — **the same way HSquared's
  `nongaussian.jl` already uses `Ainv` as the latent prior precision.**
- **Identifiability / rotation discipline (the part that separates real from
  fake):** lower-triangular loadings, optional confirmatory pinning, and
  **report only rotation-invariant functionals** — `Σ_g = ΛΛ'`, genetic
  correlations, and **communality** `c²_t = (ΛΛ')_tt / Σ_g[t,t]`; a
  simulate-refit **Procrustes** identifiability check. Raw loadings are NOT
  reported as identified. This matches HSquared's own FA rotation convention
  (`docs/dev-log/decisions/2026-06-19-fa-rotation-convention.md`) exactly.

**Do NOT reinvent (mirror the design):** the `animal_*` grammar, the A-vs-V
boundary, the rotation-invariant reporting split, the Procrustes identifiability
diagnostic.

### 2c. HSquared.jl Phase-6 — its own code, reuse DIRECTLY

| Piece | File | Reuse for genetic GLLVM |
| --- | --- | --- |
| Non-Gaussian Laplace/VA marginal + REML; `Ainv` as latent prior precision; `ResponseFamily` (Gaussian/Poisson/Bernoulli/Binomial); `NonGaussianFit`; `nongaussian_result_payload`; `MarginalMethod` | `src/nongaussian.jl` | the **single-factor** genetic latent model — generalize to `K>1` factors |
| `multivariate_mme` (`Ainv ⊗ G0⁻¹` Kronecker); `fit_multivariate_reml` (`genetic_structure=:diagonal/:lowrank/:factor_analytic`); log-Cholesky `_cov_to_chol_params`/`_chol_params_to_cov`; `lowrank_covariance`/`factor_analytic_covariance`; `genetic_correlation`; `covariance_structure_lrt` | `src/multivariate.jl` | the structured `G_lat` machinery + the Kronecker latent precision |
| Face-splitting design `W`; `Ainv ⊗ inv(K_g)` precision | `src/random_regression.jl` | **direct precedent** for multi-coefficient-per-individual latent structure |
| `evolvability`, `genetic_pca`, `g_max`, `mean_evolvability` (rotation-invariant) | `src/evolvability.jl` | latent-`G` interpretation — **no new code** |
| `pedigree_inverse`, `additive_relationship`, `metafounder_inverse`; `genomic_relationship_inverse`, `single_step_inverse` | `src/pedigree.jl`, `src/genomic.jl` | the relationship inverses that are the latent prior |

## 3. What HSquared genuinely owns (the gap)

The one genuinely new thing: a latent field with **K>1 factors carrying a
genetic covariance among individuals** under a **non-Gaussian** response — i.e.
combining `multivariate.jl`'s structured `G_lat` (Kronecker `G_lat ⊗ A`) with
`nongaussian.jl`'s relationship-as-latent-prior. The two pathways exist
separately today; nothing wires `G_lat ⊗ A` into the non-Gaussian marginal. The
`random_regression.jl` `Ainv ⊗ inv(K_g)` face-splitting design is the closest
existing template (multi-coefficient per individual) and is ~90% of the
machinery needed for the latent solve.

## 4. The slice plan (descriptors → supplied-covariance → REML), mirroring RR

The random-regression precedent landed in three slices (descriptors → supplied-
covariance MME → REML). Genetic GLLVM mirrors that exactly. Each slice is its own
full-DoD PR, Rose-gated, deterministic/RNG-free tests, rotation-invariant.

### Slice 1 (FIRST) — genetic-GLLVM latent-structure **descriptors** (supplied Λ)

Smallest honest slice. Given SUPPLIED latent loadings `Λ` (`t×K`) and optional
uniqueness `Ψ` (`t`) — the genetic GLLVM's latent layer — produce the descriptive
objects and the rotation-invariant reporting contract, with NO solver, NO
marginal, NO estimation, NO fitting/covered claim.

- **Function (proposed):** `genetic_gllvm_descriptors(Λ; uniqueness = nothing)`
  returning a NamedTuple: `genetic_covariance` `Σ_g = ΛΛ' (+ diag Ψ)`,
  `genetic_variances = diag(Σ_g)`, `genetic_correlation`, **`communality`**
  `c²_t = (ΛΛ')_tt / Σ_g[t,t]` (the rotation-invariant per-trait GLLVM summary —
  the one genuinely new descriptor), `genetic_pca(Σ_g)`, `g_max(Σ_g)`, `rank = K`,
  `n_latent_factors = K`.
- **Reuses:** `lowrank_covariance`/`factor_analytic_covariance`,
  `genetic_correlation` (multivariate.jl); `genetic_pca`/`g_max` (evolvability.jl).
- **Deterministic validation gates (RNG-free):**
  1. `Σ_g == factor_analytic_covariance(Λ, Ψ)` (and `lowrank_covariance(Λ)` at
     `Ψ=0`) — exact.
  2. `communality ∈ [0,1]`; `== 1` when `Ψ = 0`; matches `(ΛΛ')_tt / Σ_g[t,t]`.
  3. **Rotation invariance (the binding convention test):** for any orthogonal
     `Q`, `Λ→ΛQ` leaves `Σ_g`, `genetic_variances`, `communality`,
     `genetic_correlation`, and the `genetic_pca` eigenvalues invariant.
  4. **Reduction:** `K=t, Λ=I, Ψ=0` → `Σ_g = I`, `communality = 1`, eigenvalues
     all `1`.
  5. Guards: dimension mismatch, non-PSD, bad rank.
- **Claim boundary:** descriptive, supplied-covariance only; `Λ`/`Ψ` not
  estimated; no marginal/likelihood; no R model-spec or bridge payload; rotation-
  invariant functionals only (never raw `Λ`).

### Slice 2 — supplied-covariance genetic-GLLVM **latent marginal / solve**

Wire `G_lat ⊗ A` into the non-Gaussian marginal: a supplied-covariance Gaussian
latent solve first (closed-form GLS, the `multivariate_mme`/`random_regression_mme`
analogue for the GLLVM layout), reduction-validated by (a) `K=1` →
univariate `nongaussian`/`sparse_reml_loglik`; (b) `Λ=I`, identity loadings →
`multivariate_mme`; (c) rotation invariance of the marginal. Then the
Poisson/Bernoulli/Binomial Laplace/VA latent marginal at supplied `G_lat`.

### Slice 3 — genetic-GLLVM **REML** (estimate `G_lat`, structured)

`fit_*_reml` over log-Cholesky `G_lat` (`:diagonal/:lowrank/:factor_analytic`),
reusing the multivariate REML optimizer pattern; rotation-invariant payload
(`genetic_pca`/communality), `covariance_structure_lrt` for rank selection;
known-truth recovery harness opt-in; external comparator (GLLVM.jl / gllvmTMB)
deferred. No covered claim without the evidence chain.

## 5. Honest-status framing (how it enters the ladder)

- `capability-status.md`: new `experimental` row(s) — slice 1 "genetic-GLLVM
  latent-structure descriptors (supplied loadings)", descriptive/supplied only.
- `validation-debt-register.md`: new `V6-GGLLVM-DESC` (partial) row — required
  evidence = the deterministic gates above; still needs the marginal (slice 2),
  REML (slice 3), and external comparator.
- `validation_status()` in-code: matching row (→ 39 rows).
- Nothing promoted to `covered`. The "GLLVM-style animal models" capability row
  stays `planned`; this is its first concrete foundation step beyond the
  single-factor non-Gaussian marginal.

## 6. How it inherits the programme (artifacts per slice)

Per Definition of Done (`AGENTS.md`): implementation + tests + docs + example/
not-public note + check-log evidence + after-task report + capability-status row
+ validation-debt row + `validation_status()` row + mission-control matrix row
("Genetic GLLVM (#50)") + Rose claim-vs-evidence audit + clean local checks +
clean CI. Lenses that gate it: **Kirkpatrick** (latent genetic axes /
rotation-invariance), **Fisher** (identifiability), **Gauss** (numerics), **Rose**
(claims, mandatory). It slots into `11-completion-plan.md` Phase-6 (#10/#50) as
the multi-factor generalization of the landed single-factor non-Gaussian marginal.

## 7. Cross-lane / cross-team coordination (DRAFT note — outward posting is the
user's call)

> **Genetic GLLVM (#50) — scope + reuse boundary (Julia lane).** Building the
> genetic GLLVM as the multi-factor generalization of the landed Phase-6
> single-factor non-Gaussian animal model, by plugging HSquared's relationship
> inverses + non-Gaussian marginal into the GLLVM latent layer. Reuse boundary:
> **GLLVM.jl (MIT)** patterns for loadings/EM-FA/CI; **gllvmTMB (GPL-3)**
> design/grammar only (the `animal_*` keyword family + rotation-invariant
> reporting) — no code copy; **HSquared's own** `nongaussian.jl` /
> `multivariate.jl` / `random_regression.jl` / `evolvability.jl` reused directly.
> First slice is descriptors/supplied-covariance only (rotation-invariant, no
> fitting). Questions for the GLLVM.jl/gllvmTMB teams: (Q1) is a GLLVM.jl
> *dependency* welcome, or should HSquared mirror the patterns? (Q2) does the
> `animal_*` grammar map cleanly onto the R `hsquared` formula contract, or do we
> reserve a distinct `gllvm()`/`latent()` vocabulary? (Q3) ratify the shared
> rotation-invariant reporting contract (`Σ_g`/communality/eigenbasis only). This
> ties into the FA-convention ratification already pending on #42 ↔ R #7.

## 8. Risks

1. **Reinvention** — the biggest risk given the directive. Mitigation: slice 1
   reuses only existing HSquared code; the GLLVM solver/CI reuse is explicitly
   deferred to slices 2–3 where GLLVM.jl's pieces are called/adapted, not rebuilt.
2. **Rotation / identifiability overreach** — claiming raw loadings. Mitigation:
   the binding rotation convention; slice-1 gate #3 is the rotation-invariance
   test; report only functionals of `G_lat`.
3. **Honest-status overreach** — no marginal/fitting/covered claim in slice 1;
   "genetic GLLVM" stays `planned`/`experimental` until the evidence chain exists.
4. **Provenance** — gllvmTMB is GPL-3: design-only mirror, no code copy; GLLVM.jl
   is MIT (the user's own) but still independently validated.
5. **Cross-lane contract drift** — the `animal_*` grammar touches the R formula
   contract; gate any R-facing vocabulary on the coordination note (§7) before
   building the bridge, exactly as metafounders/#61 are gated.
