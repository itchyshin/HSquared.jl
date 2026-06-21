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

## 7. R-twin alignment (2026-06-20, posted to #93)

An ultracode R-twin alignment pass (read `hsquared/R/autoplot.R` +
`R/extractors.R` end-to-end vs the landed preparers) found:

- **R does NOT yet consume the Julia `*_plot_data` payloads for sets A/B/C** — it
  RECOMPUTES in R (its own `rr_genetic_variance`/`genetic_correlation`/
  `variance_components` extractors → tidy frames → `hs_gg_forest` /
  `hs_autoplot_*`). Only set D (GWAS) uses the bridge payload today. The preparers
  are nonetheless **~90% R-consumable** — the gap is R adopting them, plus a couple
  of engine field-shape tweaks.
- **R's tidy contract:** `hs_gg_forest` wants `(term, estimate, lo, hi[, panel])`;
  `hs_autoplot_g_matrix` melts `(row, col, value, label)`; `hs_autoplot_reaction_norm`
  builds `(covariate, value, panel)`; honest-status via
  `attr(p,"hsquared_meta") = list(type, source, interval_status, rotation_status, notes)`.
- **Engine adaptations (flexible — adapt to R), held pending R's answers on #93:**
  (1) `rr_genetic_variance_plot_data`: rename `genetic_variance → value` to match R's
  extractor column (fast-follow PR; no external consumer yet). (2) Sets C/D fields
  are correct as-is. (3) Optionally emit a parallel `*_meta` NamedTuple so the
  honest-status enum is engine-sourced.
- **Set B design (the next build):** `variance_components_plot_data(fit; level)`
  returns tidy parallel vectors `(term, estimate, lo, hi, panel, level,
  interval_method, interval_status, supplied = false)` that drop straight into
  `hs_gg_forest` — VC rows NOT clamped (asymptotic CI may cross 0, surfaced not
  hidden), and the h² row is the logit-delta `heritability_interval` which is in
  `(0,1)` BY CONSTRUCTION (raw + annotate, NOT clamped — per the #93 resolution);
  `supplied = false` is the honest-status hinge vs sets A/C (descriptive). The
  `heritability_interval` (0,1)-boundary throw propagates, never silently clamped.
  `breeding_values_plot_data(fit)` → `(id, trait, value, pev, pev_scale = "validation")`
  is the EBV-caterpillar preparer (EBV as `value`, validation-scale PEV) — the last
  live-parity preparer R requested (#93).
- **Discipline:** a live parity test (R `hs_rr_variance_values` == Julia
  `rr_genetic_variance` on a seeded `K_g`/`ts` fixture, re-fired on any
  Legendre/standardization change) is the guardrail wherever R recomputes.

**8 open questions to the R twin are on #93** (melt ownership, interval knob,
meta sourcing, bridge-vs-fallback, parity-test home, biplot scaling, a
`breeding_values` preparer). The engine will shape payloads to whatever lands
cleanest in `autoplot.R` — this is a proposal, R pushes back. Outward posting was
authorized by the user.

## 8. Julia drawing extension — `HSquaredMakieExt` (LANDED)

The Julia drawing half of §1. A single exported stub `hsquared_figure(data; kind,
…)` lives in `src/plotting_ext.jl` (method-less); the drawing METHODS live in the
`ext/HSquaredMakieExt.jl` package extension, which Julia loads **only** when a Makie
backend is in scope (`using CairoMakie` / `GLMakie`). `Makie` is in
`[weakdeps]`/`[extensions]` and pinned in `[compat]` (`0.24`); `/src` stays
dependency-free. Without a backend the stub throws `MethodError` (a CI test asserts
this). One dispatcher consumes the `*_plot_data` NamedTuples and infers `kind` from
the carried fields (override with `kind = :variance_components | :breeding_values |
:g_geometry`):

| `kind` | Preparer (set) | Draw | Honest-status behavior rendered ON the figure |
| --- | --- | --- | --- |
| `:variance_components` | `variance_components_plot_data` (B) | VC + h² forest | RAW whiskers (never clamped; VC crossing 0 is expected/honest); the `[0,1]` crossing is annotated on the **h² panel ONLY**; `NaN` → no whisker; supplied/estimated + `interval_status` ("NOT coverage-calibrated") in the subtitle |
| `:breeding_values` | `breeding_values_plot_data` (B) | EBV caterpillar | sorted EBV ± `√PEV`; the `pev_scale = "validation"` caveat (dense `inv(Ainv)`, not a production reliability claim) in the subtitle |
| `:g_geometry` | `genetic_pca_plot_data` (C) | eigenvalue **scree** | gated on `is_eigenstructure_not_loadings` — a loadings biplot is **rejected** (`ArgumentError`, FA rotation convention); a non-PD `G` (negative eigenvalue) draws the bar but **suppresses** %-variance labels; rotation-invariant caveat in the subtitle |
| `:genetic_correlation` | `genetic_correlation_plot_data` (C) | `D⁻¹GD⁻¹` **heatmap** | gated on `rotation_invariant` — raw loadings **rejected** (`ArgumentError`); diverging colormap centred at 0, unit diagonal; when `heritabilities` are supplied, low-h² (imprecise) traits are **flagged in the subtitle** |

The subtitle caveat is sourced from the SAME honest-status flags the preparer
carries — this is the drawing-layer half of §5.2 ("subtitle drop is the only
guardrail"). Drawing only: no estimation, no engine computation in the extension.

**Verification (local-only; Makie is deliberately OUT of default CI — cost
discipline):** all three kinds draw a `Makie.Figure` (inferred + explicit `kind`),
the stub throws `MethodError` before a backend loads, the supplied/NaN/[0,1]-boundary
forest branches and the loadings-biplot / non-PD-`G` guards all fire, and one figure
rasterizes to PNG with CairoMakie. Evidence: `docs/dev-log/check-log.md` +
after-task report `2026-06-20-…makie-ext…`. This is a **drawing capability only** —
no statistical claim is promoted by it.
