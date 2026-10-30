# After-task: MixedModels.jl comparator lane (#275)

## Goal
Add `MixedModels.jl` as a Julia-native comparator so engine speed and estimates are compared
without an R-to-Julia boundary in the way.

## What changed
- `comparator/mixedmodels_lmm/lmm_surface.jl`: shared-surface scenarios (5 predeclared), a
  deterministic simulator, the HSquared fit (`fit_sparse_multi_effect_aireml`), a closed-form
  balanced one-way ANOVA REML oracle, and the agreement arithmetic.
- `comparator/mixedmodels_lmm/run_mixedmodels_lmm.jl` and its own `Project.toml`: opt-in runner
  (`HSQUARED_RUN_MIXEDMODELS=true`), skip-safe, writes agreement/timing/provenance receipts.
- `test/test_issue_275_mixedmodels_surface.jl` (in `runtests.jl`): runs without MixedModels.
- `comparator/README.md` section; `.gitignore` for the new Manifest; receipts under
  `docs/dev-log/evidence/2026-10-25-mixedmodels-lmm/`.

## Evidence
5/5 scenarios agree (variance relative difference at most 7.5e-7, fixed effects at most 1.1e-10).
MixedModels 5.9.1 was 1.2 to 2.4 times faster in median wall time on these millisecond-scale fits.

## Shared surface, and what is outside it
Inside: Gaussian, REML, one or two crossed iid random-intercept factors, a covariate.
Outside: every pedigree, genomic or relationship-matrix term (MixedModels.jl has no such API),
multivariate and non-Gaussian models. Those stay with sommer, BLUPF90 and the other lanes.

## Not done / open
- No larger or slower design (random slopes, heavy crossing, more than 100k records) was run.
- Timings are one machine, one run; a repeat on another host is cheap but was not done.
- No capability-status or validation-debt row changed; Rose claim audit of the README wording
  is still owed before any public use of the timing comparison.
