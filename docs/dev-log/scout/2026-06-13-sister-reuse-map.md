# Sister-Repo Reuse Map (license-cleared)

Scout: Jason ×4 (one per repo) + inline synthesis. Goal: adopt existing
implementations from the local sister projects instead of reinventing, with a
hard license guardrail.

## License ledger (hard boundary)

| Repo | License | Code reuse |
| --- | --- | --- |
| `DRM.jl` | **MIT** (© 2026 Shinichi Nakagawa) | ✅ **copy/adapt** into MIT HSquared.jl, with attribution |
| `GLLVM.jl` | **MIT** (© 2026 Shinichi Nakagawa) | ✅ **copy/adapt**, with attribution |
| `drmTMB` | **GPL-3** | ⚠ **pattern-only** — never copy code into MIT HSquared.jl |
| `gllvmTMB` | **GPL-3** | ⚠ **pattern-only** |

Same author ⇒ attribution is trivial for the MIT pair. The numerical kernels we
most need live in the **MIT Julia** pair; the GPL R pair contributes
architecture/contract patterns only.

## Immediate frontier — production sparse PEV/reliability (next Phase-1 atom)

- **COPY `DRM.jl/src/takahashi_selinv.jl`** (also in `GLLVM.jl/src/takahashi_selinv.jl`)
  → HSquared.jl. Takahashi/Erisman–Tinney selected inverse over a CHOLMOD factor,
  O(nnz(L)), with a diagonal-only fast path. This is the literal kernel for the
  diagonal of the MME coefficient-matrix inverse = PEV, hence reliability/accuracy,
  and for variance-component score traces. **Load-bearing caveat (from the
  docstring): only the `L+Lᵀ` sparsity pattern is exact** — PEV (diagonal) and
  same-block entries are valid; arbitrary leaf–leaf covariances are not.
- **ADAPT `DRM.jl/src/gaussian_structured.jl`** (~lines 270–556): end-to-end sparse
  Gaussian mixed-model fit that **never forms V** — one sparse Cholesky of
  `H = blockdiag(σ_k⁻² Q_k) + Z'WZ`, **symbolic-factor reuse** (`cholesky!` into a
  pre-analysed factor across iterations), analytic VC gradients with traces from
  the selected inverse, BLUPs, and per-observation `(V⁻¹)_ii` = the PEV readout.
  Currently hard-wired to 2 components + residual → generalise to k components and
  feed pedigree `A⁻¹` as `Q`.

## Sparse REML / AI-REML (Phase-1 frontier)

- **ADAPT `DRM.jl/src/experimental/reml_q4.jl`** — REML via the **Patterson–Thompson
  bordered-augmented-state** logdet correction `−½ logdet(X̃' H_uu⁻¹ X̃)`, profiling
  the mean fixed effects out by augmenting the latent state. Built additively on
  the sparse Laplace engine. (q=4-specific, experimental — adapt the formula.)
- **ADAPT `GLLVM.jl/src/sparse_phy_grad.jl` + `node_gradient.jl`** — hand-coded
  **analytic adjoint gradient** of a sparse-Cholesky Gaussian REML-style likelihood
  (P_A/P_B adjoints, VC score equations, O(p) `C⁻¹` via Woodbury + augmented solve,
  trace via Takahashi diagonal + rank-K correction) + per-individual BLUPs. **This
  is the blueprint for sparse AI-REML.**
- **ADAPT `DRM.jl/src/locscale_grad.jl` + `locscale_inner.jl`** — the cleanest small
  example of the O(p) implicit-function-theorem marginal gradient
  (`M = jn + ½ logdet H − ½ logdet P`; adjoint `v = ½ tr(H⁻¹ dH/da)`, one solve).
- **ADAPT `DRM.jl/src/sparse_em_fit.jl` / `sparse_aug_plsm.jl` / `fit_q4_sparse_tmb.jl`**
  — sparse Laplace-**EM** with a closed-form M-step variance update using a Takahashi
  trace correction (= EM-REML step); PD-guarded sparse Cholesky with escalating
  ridge (`sparse_pd_chol`); trust-region inner solve; TMB-style exact-gradient outer
  driver (warm-start cache, Inf-barrier line-search guard, mean-objective scaling,
  singular-model stop).

### ★ AI-REML reality check (confirms Shinichi's note, 2026-06-13)

DRM.jl has **NO working AI-REML average-information matrix** — only the
**score-trace machinery** it would be built on (selected-inverse traces +
analytic VC gradients). This is consistent with "AI-REML did not work in DRM.jl":
the AI matrix itself was never completed there. **Path for HSquared.jl:** build
the average-information matrix *on top of* the existing selinv score traces
(`gaussian_structured._trace_*`, `sparse_phy_grad`), rather than expecting a
ready AI-REML to lift. Treat AI-REML as a high-uncertainty research item (see the
fastest-REML/ML standing directive). A robust fallback exists: **EM-REML** (the
closed-form M-step in `sparse_em_fit.jl`) and **Newton/Fisher-scoring** on the
analytic gradient.

### Key design note (both MIT repos)

CHOLMOD is **Float64-only**, so `ForwardDiff` cannot flow through a sparse
Cholesky — which is *why* both repos use **analytic** gradients/traces (not AD)
on the sparse path. HSquared.jl must do the same.

## Per-phase reuse

| Phase | Capability | Source (mode) |
| --- | --- | --- |
| 1 | sparse PEV/reliability | `DRM.jl`/`GLLVM.jl` `takahashi_selinv.jl` (copy) |
| 1 | sparse Gaussian fit (no V) | `DRM.jl` `gaussian_structured.jl` (adapt) |
| 1 | REML correction | `DRM.jl` `reml_q4.jl` (adapt) |
| 1 | AI-REML gradient blueprint | `GLLVM.jl` `sparse_phy_grad.jl`/`node_gradient.jl` (adapt) |
| 1 | A⁻¹ assembly idiom | `DRM.jl` `sparse_phy.jl` triplets (pattern); `gllvmTMB` `animal-keyword.R` Henderson-Quaas algo (pattern) |
| 2 | user-supplied G/GRM intake | `GLLVM.jl` `structured_cov.jl` `relatedness_cov` (adapt); `gllvmTMB` `kernel-keywords.R` (pattern) |
| 3 | h²/repeatability ratio CIs | `DRM.jl` `heritability.jl` (adapt); `GLLVM.jl` `confint_*` (adapt); `drmTMB` `methods.R` derived-summary (pattern) |
| 4 | multivariate / missing records | `gllvmTMB` C++ kron + `drmTMB` `missing-data.R` mask (pattern) |
| 4B | factor-analytic G `ΛΛ'+Ψ` | `GLLVM.jl` `lowrank_cholesky.jl` (adapt, **drops in**) + `em_fa.jl`/`ppca_init.jl`/`packing.jl`/`postfit.jl` (adapt); `gllvmTMB` C++ packed-Λ + `lambda-constraint.R` index map (pattern) |
| 6/7 | matrix-free logdet (huge SPD) | `GLLVM.jl` `structured_schur.jl` SLQ+CG (adapt) |
| bridge | R↔Julia bridge + result contract | `DRM.jl` `bridge.jl` (adapt, **MIT**); `drmTMB`/`gllvmTMB` `julia-bridge.R` (pattern: marshalling, row-order round-trip, partial-vcov status, loud-reject-with-fallback) |
| contract | tidy result schema + provenance | `gllvmTMB` `extract-sigma-table.R` / `diagnostic-tables.R` (pattern: estimand/level/component/interval_method/interval_status/validation_row) |
| contract | honest uncertainty reporting | `gllvmTMB` `loading-ci.R` pdHess gate (NA + status, never invented numbers) (pattern) |

## Caveats / gaps

- Neither GPL R repo has selected-inversion / PEV (both delegate to TMB
  `sdreport`). The PEV/selinv math comes only from the **MIT Julia** repos.
- DRM.jl is single-trait / 2-component (Gaussian) or fixed q=4 (Laplace): **no**
  multivariate A⊗G, **no** genomic G/APY, **no** factor-analytic, **no** AI-REML
  matrix, **no** pedigree parser (takes A/K as supplied). The QG-specific structure
  (A⁻¹ from pedigree, G, single-step, multivariate kron, FA-G) is built fresh in
  HSquared.jl *on top of* the selinv + analytic-trace + symbolic-reuse spine.
- HSquared.jl already has `pedigree_inverse` (native Henderson) — keep it; use the
  sister `animal-keyword.R` only as an edge-case/ID-handling reference.

Provenance: workflow `wf_ce6cef1e-01f` (4 scout scans completed; synthesis inline
after the run was interrupted). MIT copies require an attribution note to the
source repo/author.
