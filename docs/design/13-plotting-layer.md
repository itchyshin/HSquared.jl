# Plotting / visualization layer — design + cross-lane contract

Status: **design note + ratified architecture**, 2026-06-20 (Florence + Hopper +
Rose, ultracode design pass). Set A (RR plot-data preparers, PR #91), set B
(VC/h² forest + EBV caterpillar), and set C (G-geometry preparers) are landed, and
the **Julia drawing half — the `HSquaredMakieExt` weak-dep extension (§8)** — is now
landed for sets B and C; the rest is the agreed runway. No capability is claimed
here; the honest-status figure contract (§4) is binding, and the drawing layer
renders those caveats ON the figure.

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
| **A** Random regression | `rr_eigenfunctions_plot_data`, `rr_genetic_variance_plot_data`, `rr_covariance_surface_plot_data` | **landed** (PR #91) | `rr_eigenfunctions`/`rr_genetic_variance`/`rr_genetic_covariance_surface` (PR #88) |
| **B** Variance components + h² | `variance_components_plot_data(fit; level)` | **landed** | `variance_components` / `heritability_interval` / `variance_component_standard_errors` |
| **C** Genetic correlations | `genetic_correlation_plot_data(G; traits, heritabilities)` | **landed** | `genetic_correlation` |
| **C** G geometry (rotation-invariant) | `genetic_pca_plot_data(G; n_axes)` | **landed** | `genetic_pca` / `g_max` / `evolvability` |
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
Julia ships the plot-data shape; R fires the matching `autoplot` type.

## 7. R-twin alignment (#93 resolved)

The #93 plot-data contract is now consumed on both sides of the twin.

- **R-side consumption is landed.** The R lane consumes all seven landed engine
  `*_plot_data` preparers with recompute fallbacks and skip-guarded live parity
  tests in `tests/testthat/test-plot-data-parity.R`: `genetic_correlation`,
  `genetic_pca`, `variance_components`, `rr_genetic_variance`,
  `rr_eigenfunctions`, `rr_covariance_surface`, and `breeding_values`. The
  follow-up fit-time attachment slice landed as `hsquared` PR #35
  (`6098839`, `codex/a3-fit-time-plot-data`) with R-CMD-check green.
- **The #93 naming and honesty decisions are ratified.** R accepts
  `rr_genetic_variance_plot_data` through `value` or the current
  `genetic_variance` field; wide matrices remain wide and R melts them;
  `variance_components_plot_data` ships raw interval bounds plus
  `interval_status` / `interval_method`; `breeding_values_plot_data` ships
  `(id, trait, value, pev, pev_scale = "validation")`; flat honest-status fields
  map to R's canonical `hsquared_meta` enum.
- **Julia-side preparers are landed.** Sets A, B, C, and D are implemented as
  dependency-free plot-data helpers and tested in `test/runtests.jl`. The Julia
  drawing extension consumes the set B/C helpers locally through
  `HSquaredMakieExt`, with Makie deliberately kept out of default CI.
- **Closure boundary.** Closing #93 means the plot-data bridge contract is
  ratified, consumed, and parity-guarded. It does not claim production plotting
  coverage for every future figure, does not make Makie drawing CI-gated, does
  not calibrate marker-scan p-values (#48), and does not promote any statistical
  model capability to covered.

## 8. Julia drawing extension — `HSquaredMakieExt` (LANDED)

The Julia drawing half of §1. A single exported stub `hsquared_figure(data; kind,
…)` lives in `src/plotting_ext.jl` (method-less); the drawing METHODS live in the
`ext/HSquaredMakieExt.jl` package extension, which Julia loads **only** when a Makie
backend is in scope (`using CairoMakie` / `GLMakie`). `Makie` is in
`[weakdeps]`/`[extensions]` and pinned in `[compat]` (`0.24`); `/src` stays
dependency-free. Without a backend the stub throws `MethodError` (a CI test asserts
this). One dispatcher consumes the `*_plot_data` NamedTuples and infers `kind` from
the carried fields (override with `kind = :variance_components | :breeding_values |
:g_geometry | :genetic_correlation | :manhattan | :qq | :rr_variance | :rr_surface |
:rr_eigenfunctions`):

| `kind` | Preparer (set) | Draw | Honest-status behavior rendered ON the figure |
| --- | --- | --- | --- |
| `:variance_components` | `variance_components_plot_data` (B) | VC + h² forest | RAW whiskers (never clamped; VC crossing 0 is expected/honest); the `[0,1]` crossing is annotated on the **h² panel ONLY**; `NaN` → no whisker; supplied/estimated + `interval_status` ("NOT coverage-calibrated") in the subtitle |
| `:breeding_values` | `breeding_values_plot_data` (B) | EBV caterpillar | sorted EBV ± `√PEV`; the `pev_scale = "validation"` caveat (dense `inv(Ainv)`, not a production reliability claim) in the subtitle |
| `:g_geometry` | `genetic_pca_plot_data` (C) | eigenvalue **scree** | gated on `is_eigenstructure_not_loadings` — a loadings biplot is **rejected** (`ArgumentError`, FA rotation convention); a non-PD `G` (negative eigenvalue) draws the bar but **suppresses** %-variance labels; rotation-invariant caveat in the subtitle |
| `:genetic_correlation` | `genetic_correlation_plot_data` (C) | `D⁻¹GD⁻¹` **heatmap** | gated on `rotation_invariant` — raw loadings **rejected** (`ArgumentError`); diverging colormap centred at 0, unit diagonal; when `heritabilities` are supplied, low-h² (imprecise) traits are **flagged in the subtitle** |
| `:manhattan` | `marker_manhattan_data` (D) | chromosome-coloured **scatter** of cumulative `plot_positions` vs `-log10(p)` | a **VISUAL-ONLY** Bonferroni guide line at `-log10(0.05/m)`; subtitle: "nominal Wald p-values, **NOT genome-wide calibrated** (#48); threshold line is visual guidance only" |
| `:qq` | `marker_qq_data` (D) | observed vs expected `-log10(p)` **scatter** | the `y = x` uniform-null line; subtitle: "nominal Wald p-values, **NOT genome-wide calibrated** (#48); y=x is the uniform null". λGC is **intentionally NOT** recomputed (the preparer carries no χ²; keep numerics in `/src`) |
| `:rr_variance` | `rr_genetic_variance_plot_data` (A) | genetic-variance `v_g(t)` (+ optional `h²(t)`) panels | the `h²(t)` panel is drawn **only** when a residual was supplied (else a single panel + note); subtitle: "supplied-`K_g` descriptive (not REML, not phenotypic); h²(t) can overstate without a permanent-environment term" |
| `:rr_surface` | `rr_covariance_surface_plot_data` (A) | covariance/correlation **surface heatmap** | diverging RdBu centred at 0; the **correlation** surface uses a fixed `(-1, 1)` colorrange, the **covariance** surface a data-driven symmetric-about-0 range (a fixed `(-1,1)` would clip); subtitle: "supplied-`K_g` descriptive; rotation-invariant; genetic, not phenotypic" |
| `:rr_eigenfunctions` | `rr_eigenfunctions_plot_data` (A) | one **eigenfunction per line** | per-axis variance-explained legend; subtitle: "rotation-invariant; supplied-`K_g` descriptive; **signs arbitrary**; span-ambiguous under repeated eigenvalues" |

The subtitle caveat is sourced from the SAME honest-status flags the preparer
carries — this is the drawing-layer half of §5.2 ("subtitle drop is the only
guardrail"). Drawing only: no estimation, no engine computation in the extension.

**Verification (local-only; Makie is deliberately OUT of default CI — cost
discipline):** all **nine** kinds draw a `Makie.Figure` (inferred + explicit `kind`),
the stub throws `MethodError` before a backend loads (a CI test asserts this across
all **nine** payload shapes — one per kind — in 11 total assertions), the
`_infer_kind` eigenvalues-collision guard holds
(`genetic_pca_plot_data` still infers `:g_geometry`, `rr_eigenfunctions_plot_data`
infers `:rr_eigenfunctions`), the honest-status branches all fire (supplied/NaN/[0,1]
forest; loadings-biplot / non-PD-`G` guards; the Manhattan/QQ NOT-calibrated subtitles;
the reaction-norm single-vs-two-panel split; the correlation-`(-1,1)` vs
covariance-data-driven surface colorrange; the eigenfunction signs-arbitrary subtitle),
and all figures rasterize to PNG with CairoMakie 0.15.11 / Makie 0.24.x. Evidence:
`docs/dev-log/check-log.d/2026-06-22-l1-makie-figures.md` + after-task report
`2026-06-22-l1-makie-figures.md`. This is a **drawing capability only** — no
statistical claim is promoted by it.
