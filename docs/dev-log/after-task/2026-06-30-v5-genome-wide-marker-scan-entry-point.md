# After-task — V5 `genome_wide_marker_scan` exported entry point (R-activation foundation, 2026-06-30)

Under the maintainer `/goal` "finish all of v0.5" + explicit authorization to do the R `gwas()` activation. This
is the **Julia-engine half**: an exported, genome-wide-CALIBRATED fixed-effect scan entry point that packages the
validated exact per-dataset add-one rule for the R-twin `gwas(..., genome_wide = TRUE)` bridge to call. Claude
solo, branch `feat/2026-06-30-v5-genome-wide-scan-r-activation`. **NOTHING promoted** — this exposes the
validated machinery; the covered flip is the coordinated cross-twin move after the R activation + G10.

## Live phase snapshot

- **As of 2026-06-30 (V5 `genome_wide_marker_scan` exported — R-activation engine foundation; branch
  `feat/2026-06-30-v5-genome-wide-scan-r-activation`, PR pending; `main` @ `1a042f63`/#207).**
  NEW EXPORT `genome_wide_marker_scan(y, X, markers; n_permutations, alpha, sigma_e2, marker_ids, rng)` runs
  `single_marker_scan` + the EXACT per-dataset residual-permutation null + `genome_wide_pvalue` (per marker +
  observed max) + the `(1-alpha)` threshold, returning a `calibration = (method = :permutation_addone,
  rebuilt_per_dataset = true, …)` payload. This is the REBUILD-gate procedure (type-I at α, production-validated),
  NOT the anti-conservative reuse shortcut and NOT the failed quantile-only rule. FIXED-effect scope (the
  mixed-model genome-wide null is a separate, unvalidated calibration). 27 CI assertions + a pinned-seed
  cross-twin parity fixture (`test/fixtures/genome_wide_scan_parity/`). It is the engine bridge target for the R
  `gwas(..., genome_wide = TRUE)` activation. `validation_status()` = 48 / covered 7 / partial 37 UNCHANGED (V5
  evidence APPENDED, no row added); public-covered fitting = 1; `gwas()` wording HELD. NEXT: the R-side
  activation in `hsquared`, then the coordinated scoped covered flip + Rose + G10. START HERE: this report.

## What changed

- NEW `genome_wide_marker_scan` (`src/genomic.jl`) + export (`src/HSquared.jl`).
- NEW tests (`test/runtests.jl`, testset "genome_wide_marker_scan …", 27 assertions).
- NEW deterministic cross-twin parity fixture `test/fixtures/genome_wide_scan_parity/` (`generate.jl` + CSVs).
- Docs: `docs/src/api.md` lists the export; V5 evidence APPENDED in `src/validation_status.jl`,
  `docs/design/capability-status.md` (status UNCHANGED).

## Checks run and exact outcomes

- `Pkg.test()` → **"Testing HSquared tests passed"**; the new testset = **27/27**.
- Standalone: planted causal marker is the top hit with genome-wide p 0.0033; pure-null genome-wide p 0.21
  (not spuriously significant); calibration payload `method = :permutation_addone, rebuilt_per_dataset = true`.
- Fixture regeneration with the pinned seed reproduces the committed payload to `rtol 1e-12`.
- `validation_status()` independently = 48 / covered 7 / partial 37 — UNCHANGED. `genome_wide_marker_scan`
  exported = true.

## Public claim audit (Rose)

Real `rose-systems-auditor` audit → **PROMOTE** (clean; one optional housekeeping note, applied). Verified
INDEPENDENTLY: (1) the entry point is byte-for-byte the production-validated REBUILD procedure (permute THIS y's
residuals conditional on X; add-one `genome_wide_pvalue` decision; the `(1-alpha)` threshold is display-only),
NOT the reuse shortcut and NOT the failed quantile rule — Rose re-derived the REBUILD type-I (0.0542/0.0504)
from `sim/phase5_rebuild_production_gate.tsv` and confirmed the pre-registration ordering; (2) FIXED-effect scope
stated in docstring + status + after-task, mixed-model null explicitly out of scope; (3) `validation_status()`
independently 48/covered 7/partial 37, V5 stays `partial`, evidence APPENDED (no row/status change), count-guard
passes, nothing promoted, `gwas()` held; (4) Rose regenerated the fixture with the pinned seed and diffed —
chisq + genome-wide p max-abs-diff 0.0; (5) no "finishes R activation/v0.5" overclaim (framed as the engine
foundation; the R activation + covered flip left owed). NOTE: a later CI fix relaxed the fixture's
genome-wide-p assertion to STRUCTURAL checks (the permutation `MersenneTwister` stream is not stable across Julia
MAJOR versions — Julia 1.11 produced different p's; the deterministic `chisq` parity is kept exact, and the R
LIVE bridge checks exact parity within a single Julia version).

## Tests of the tests

- The reduction test pins `genome_wide_marker_scan` == `single_marker_scan` on the per-marker fields (it only
  ADDS the genome-wide layer). The add-one p tests pin validity/monotonicity/floor; the planted-signal and
  pure-null tests pin discrimination; the fixture-parity test keeps the cross-twin contract in sync.
- The calibration is the per-dataset REBUILD procedure (the production-validated exact rule), explicitly NOT the
  reuse shortcut that the production REUSE gate showed mildly anti-conservative.

## Known limitations

- FIXED-effect `X` only. The relatedness-corrected MIXED-model genome-wide permutation null is unvalidated and
  out of scope (a separate future item).
- The genome-wide calibration is per-dataset permutation on one LD architecture / intercept-only design (the
  validated scope); broader-LD/covariate-adjusted calibration remains owed.

## Next actions

1. **R activation (`hsquared`):** `gwas(..., genome_wide = TRUE, n_perm = …)` calls `genome_wide_marker_scan`
   via the JuliaCall bridge; populate the existing `hs_gwas_calibration_required_fields()` metadata; unhold the
   "NOT genome-wide calibrated" wording; pure-R fixture parity + skip-guarded live test.
2. **Coordinated scoped covered flip** across both twins (Rose + maintainer G10) — the fixed-effect genome-wide
   add-one rule, the tested designs, with the reuse-shortcut/mixed-model caveats documented.
