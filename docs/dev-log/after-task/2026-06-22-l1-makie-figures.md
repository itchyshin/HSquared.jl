# After-task — L1: HSquaredMakieExt figure kinds (markers + RR) — 2026-06-22

## Task goal

L1 of the 100-slice backlog: extend the `HSquaredMakieExt` Makie weak-dep drawing
extension with 5 new figure `kind`s — `:manhattan`, `:qq` (set D, marker scans) and
`:rr_variance`, `:rr_surface`, `:rr_eigenfunctions` (set A, random regression) — each
consuming an already-exported, backend-free `*_plot_data` preparer. DRAWING ONLY: no
new `src/` numerics, no new export, no `Project.toml` change. The R twin already ships
the equivalent `autoplot` types; this reaches Julia drawing parity for them.

## Active lenses / spawned agents

Florence (figure honesty) + Rose (claim-vs-evidence) — spawned as real subagents over
the branch (see Checks). No maintainer sign-off required (nothing promoted to covered).

## Files changed

- `ext/HSquaredMakieExt.jl` — 5 drawing methods + 5 `_infer_kind` cases (ordered so
  the g_geometry `is_eigenstructure_not_loadings` check precedes rr_eigenfunctions,
  resolving the shared-`eigenvalues` collision) + 5 dispatcher branches + 9-kind error lists.
- `src/plotting_ext.jl` — stub docstring extended (still method-less; no `/src` code).
- `test/runtests.jl` — stub testset 5 → 10 `MethodError` assertions.
- `docs/design/validation-debt-register.md` (`V-PLOT-DRAW`), `docs/design/13-plotting-layer.md` (§8).

## Checks run and exact outcomes

- `Pkg.test()` (thread-capped): **"Testing HSquared tests passed"** — the expanded
  stub testset (11 assertions; 9 `MethodError` payloads, one per dispatched kind) +
  full suite green.
- **LOCAL CairoMakie draw** (the load-bearing check; Makie is OUT of CI by cost
  discipline) — `/tmp/l1_verify.jl`, CairoMakie 0.15.11 / Makie 0.24.x: **ALL 30
  checks PASS** — routing (incl. the eigenvalues-collision guard), 10 draws
  (inferred + explicit), 6 honest-status branches (NOT-calibrated subtitles, panel
  count 2-vs-1, colorrange correlation-`(-1,1)` vs covariance-data-driven, signs-
  arbitrary), 6 PNG rasterizations.
- **Florence (figure honesty): CLEAN** — all 5 methods figure-honest; the drawing
  layer adds NO numeric the preparer didn't carry (λGC correctly absent — it lives in
  a separate `marker_genomic_inflation` preparer requiring `chisq`, which `marker_qq_data`
  does not carry); PSD-guarded `K_g` keeps `h²(t) ∈ [0,1)` and `variance_explained ∈
  [0,1]` so no boundary flag is needed; the correlation colorrange `(-1,1)` cannot clip.
- **Rose (claim-vs-evidence): MERGE-WITH-CHANGES → addressed** — caught that the stub
  testset covered 8 of 9 kinds (`:g_geometry` had no payload — a PRE-EXISTING gap my
  "nine payload shapes" doc claim over-counted). Fixed by adding a `:g_geometry` stub
  payload (now 9 payloads / 11 assertions, all kinds) and correcting the counts in
  the register + §8 + check-log. Everything else verified accurate (9-kind dispatcher,
  honest-status subtitles match code, no covered-drift, stub discipline, evidence
  pointers resolve).

## Public claim audit (Rose lens)

- DRAWING only; `validation_status()` rows UNCHANGED (no `ValidationStatusRow` for the
  drawing extension — tracked in the debt register + design-doc §8, the PR #121
  precedent). Nothing promoted to covered; public-default covered count UNCHANGED.
- Every honest-status guardrail the R twin enforces is rendered ON the figure via the
  subtitle, sourced from the preparer's carried flags:
  - Manhattan/QQ: "nominal Wald p-values, NOT genome-wide calibrated (#48)"; the
    Bonferroni line is VISUAL-ONLY; λGC is intentionally NOT recomputed (the preparer
    carries no χ² — recomputing would both duplicate `/src` numerics and risk an
    uncalibrated diagnostic being read as calibrated).
  - RR: "supplied-K_g descriptive (not REML, not phenotypic)"; the `h²(t)` panel is
    drawn only when a residual is supplied and flags it "can overstate without a PE
    term"; eigenfunctions flag "signs arbitrary; span-ambiguous under repeated
    eigenvalues"; the covariance surface uses a data-driven range (a fixed `(-1,1)`
    would clip a covariance and mislead).

## Tests of the tests

- The 5 CI stub assertions are trivially-true in the dependency-free build (the stub is
  method-less) — their job is to catch a payload shape accidentally acquiring a method.
  The LOAD-BEARING check is the LOCAL draw, which exercises the real preparers and the
  real drawing methods, and asserts the routing guard + honest-status branches + PNG.

## Coordination notes

- R-twin `autoplot.R` already ships `manhattan`/`qq`/`reaction_norm`/`rr_surface`; this
  reaches Julia drawing parity. Per-figure R↔Julia drawing-parity SNAPSHOTS remain debt.

## What did not go smoothly

- The verification script first failed on `import Makie` (only CairoMakie is in the
  scratch env; it re-exports the Makie API) — fixed by using CairoMakie's re-exported
  `Figure`/`Axis`/`Heatmap`. The `/tmp/hsq_makie_env` scratch env had to be recreated
  (cleared from /tmp).

## Known limitations

- The draw is verified LOCALLY ONLY (Makie out of CI). No render-diff guard against
  Makie-compat churn; no R↔Julia per-figure parity snapshot. Both are retained debt
  before any "Julia plots" public claim.

## Next actions

1. Fill the Rose/Florence verdicts; commit, push, PR, merge on green CI.
2. Then the GLMM/inference half — H2 (beta-binomial, reuses H1's 2-parameter pattern)
   next, derive→oracle→Rose.
