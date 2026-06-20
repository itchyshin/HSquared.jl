# Plotting / visualization layer — design + cross-lane contract

Status: **design note + ratified architecture**, 2026-06-20 (Florence + Hopper +
Rose, ultracode design pass). The first engine slice (RR plot-data preparers) is
landing; the rest is the agreed runway. No capability is claimed here; the
honest-status figure contract (§4) is binding.

## 1. Ratified architecture (user-confirmed)

A first-class plotting layer (brms/bayesplot-style), split across the twin:

- **Julia engine** returns **plot-ready DATA only** — deterministic, RNG-free,
  backend-free NamedTuples, extending the existing `marker_manhattan_data` /
  `marker_qq_data` / `marker_region_data` `*_plot_data` convention. `/src` stays
  dependency-free (DRM.jl/GLLVM.jl discipline).
- **R draws** with ggplot2, building on the **existing** `hsquared/R/autoplot.R`
  (`autoplot.hsquared_fit`, `autoplot.hs_gwas`, `hs_gg_forest()`,
  `theme_hsquared()`, the `hsquared_meta`/`hsquared_data` attribute pattern from
  gllvmTMB/drmTMB).
- **Julia draws** via a thin **`HSquaredMakieExt` weak-dependency package
  extension** (Makie in `[weakdeps]`/`[extensions]`, pinned in `[compat]`) — gives
  Julia users real `plot()` functions while keeping the base install light. Docs
  figures call the extension (or isolated docs-scripts), never embedded in `/src`.

Twin boundary holds: R owns user language; Julia computes. The plot-data layer is
the shared contract both drawing layers consume.

**Sister precedent:** DRM.jl (`src/visualization.jl`) + GLLVM.jl use docs-script +
dependency-free plot-data (no extension — viz was a low-priority boundary for
them). HSquared keeps their `/src`-clean + plot-data-first discipline but ADDS the
Makie extension because plotting is a first-class goal here.

## 2. Engine plot-data API (the four ratified figure sets)

All return `NamedTuple`s; new ones mirror the `marker_*_data` shape and carry
honest-status flags (`supplied`, `rotation_invariant`, `interval_status`, …).

| Set | Preparer(s) | Status | Source |
| --- | --- | --- | --- |
| **A** Random regression | `rr_eigenfunctions_plot_data`, `rr_genetic_variance_plot_data`, `rr_covariance_surface_plot_data` | **landing** (this slice) | `rr_eigenfunctions`/`rr_genetic_variance`/`rr_genetic_covariance_surface` (PR #88) |
| **B** Variance components + h² | `variance_components_plot_data(fit; level)` | planned | `variance_components` / `heritability_interval` / `multivariate_covariance_standard_errors` |
| **C** Genetic correlations | `genetic_correlation_plot_data(fit; traits)` | planned | `genetic_correlation` |
| **C** G geometry (rotation-invariant) | `genetic_pca_plot_data(G; n_axes)` | planned | `genetic_pca` / `g_max` / `evolvability` |
| **D** GWAS | `marker_manhattan_data`, `marker_qq_data`, `marker_genomic_inflation` | **already exists** (`src/genomic.jl`) | — |

**HARD CONTRACT (set C):** `genetic_pca_plot_data` accepts a covariance `G` and
returns only its **rotation-invariant eigenstructure** (eigenvalues + sign-
canonicalized principal axes + biplot-scaled vectors), NEVER raw factor-analytic
loadings `Λ` — enforcing the FA rotation convention
(`docs/dev-log/decisions/2026-06-19-fa-rotation-convention.md`). Raw `Λ` is not an
accepted input or output.

## 3. R drawing contract (R lane owns)

Add new `type=` values to `autoplot.hsquared_fit` (gllvmTMB 7-type pattern), each
backed by a `.{type}_plot_data()` tidy-data builder + a `.plot_{type}()` wrapper,
attaching `attr(p, "hsquared_meta") = list(type, source, interval_status,
rotation_status, notes)` and `attr(p, "hsquared_data")`. Base-graphics
`plot.hsquared_fit` stays as the low-dependency fallback. R consumes the Julia
`*_plot_data` payloads over the bridge OR recomputes from the fitted object (a live
parity test must keep the two in step — see §5 risks).

## 4. Florence honest-status figure contract (BINDING)

Every figure carries a caption stating estimator + interval method + rotation
convention, and a subtitle caveat:

- **A / v_g(t), surface, eigenfunctions** — "SUPPLIED `K_g`, descriptive; not a
  REML estimate, not phenotypic." Eigenfunctions rotation-invariant; signs
  arbitrary; span-ambiguous under repeated `λ_j`. RR `h²(t)` without a
  permanent-environment term can overstate heritability.
- **B / variance components, h²** — "asymptotic delta/AI-matrix intervals,
  EXPERIMENTAL, NOT coverage-calibrated; small-n coverage may be <95%." No
  fabricated whiskers when SEs are absent. `heritability_interval` throws on the
  (0,1) boundary — surfaced, never clamped.
- **C / genetic-correlation heatmap** — "rotation-invariant `D⁻¹GD⁻¹`; cells
  involving low-h² traits are imprecise (flag them)." **G geometry** — "rotation-
  invariant G eigenstructure (eigenvalues + principal axes), NEVER raw loadings."
- **D / Manhattan, QQ, λGC** — "nominal Wald p-values, NOT genome-wide calibrated
  (#48); threshold/envelope are visual guidance only; λGC diagnostic only, not LD/
  structure-corrected." Raw p preserved; `p_floor` caps display only.

## 5. Risks (Rose)

1. **Honest-status leak via R labels** — Julia returns rotation-invariant
   eigenstructure, but an R convenience that plots `Λ` would reintroduce rotation
   overreach. The contract forbids it; Florence reviews R figures.
2. **Subtitle drop** — the caveat subtitle is the only guardrail against reading a
   nominal-p Manhattan / asymptotic forest as calibrated. Keep it.
3. **Parity drift** — R recomputes some RR descriptors rather than calling the
   bridge; keep the live parity test, re-check on any basis change.
4. **Makie compat churn** — pin Makie in `[compat]`; all numerics stay in `/src`,
   so an extension break never touches the engine.

## 6. Coordination

The engine `*_plot_data` preparers + this contract are the cross-lane proposal for
the R sister (who already has `autoplot.R`). Mirrors the bridge-payload discipline:
Julia ships the plot-data shape; R fires the matching `autoplot` type. Posted as a
cross-lane note (outward posting is the user's call).
