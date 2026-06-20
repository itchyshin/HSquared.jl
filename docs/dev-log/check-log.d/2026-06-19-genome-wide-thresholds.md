# 2026-06-19 Genome-wide significance threshold machinery (#48)

- Goal: deliver the #48 calibrated genome-wide threshold — the gate that holds the
  R `gwas()` significance wording until a calibrated multiple-testing claim exists.
- Lenses: Curie + Fisher (calibration / multiple testing), Gauss (numerics), Rose
  (claim gate). Spec authored by the Curie lens.

## Design decision (dependency stability)

Kept the PACKAGE RNG-free (matching the project's "RNG lives in `sim/`" pattern and
avoiding a `Random` dependency in `[deps]` mid-run): the committed, CI-tested layer
is the DETERMINISTIC threshold machinery; the RNG-heavy null generation (phenotype
permutation) is the opt-in `sim/` harness.

## What was done

- `src/genomic.jl` (exported): `genome_wide_threshold_from_null(null_max_statistics;
  alpha, statistic)` → the `(1 - alpha)` empirical-quantile genome-wide threshold;
  `genome_wide_pvalue(observed, null)` → add-one empirical p `(1 + #{null ≥ obs})/
  (n_null + 1)`. Internal: `_scan_max_statistic` (max χ² / max -log10 p over a scan)
  and `_empirical_upper_quantile` (in-package type-7 interpolation, no Statistics
  dependency). The MAXIMUM-over-jointly-scanned-markers makes it correlation/LD-aware.
- `sim/phase5_threshold_calibration.jl` (new, opt-in, outside CI): builds the null
  by residual permutation conditional on `X`, calls `genome_wide_threshold_from_null`,
  contrasts the permutation threshold with Bonferroni, and records a loose empirical
  type-I smoke. RNG-seeded with `--seed`/`--n-permutations`/`--alpha` args.
- Tests (`test/runtests.jl`, "Phase 5 genome-wide threshold machinery (#48)"):
  max-statistic extraction (χ² + -log10 p), empirical-quantile interpolation vs hand
  values, threshold shape + alpha-monotonicity, add-one p identities (never zero) +
  threshold↔p consistency, and guards.
- Rows: capability-status (new "Genome-wide significance threshold" row);
  validation-debt `V5-MARKER-THRESHOLD`; `validation_status()` `V5-MARKER-THRESHOLD`
  row (inserted in the V5 cluster so `validation[end]` stays `V6-LAPLACE`); count
  34 → 35.

## Commands / results

- `~/.juliaup/bin/julia --project=. -e 'using Pkg; Pkg.test()'` → **passed (exit 0)**
  (threshold testset 26/26; `validation_status()` count 35).
- `~/.juliaup/bin/julia --project=docs docs/make.jl` → **passed (exit 0)** (incl. the
  new `api.md` entries for `genome_wide_threshold_from_null`/`genome_wide_pvalue`).
- Adversarial review → (recorded in after-task).

## Claim boundary

Deterministic threshold MACHINERY + add-one genome-wide p-value only — NOT a
production genome-wide-significance claim (the #48 gate; the R `gwas()` significance
wording stays held until a realistic-LD/design calibration lands). The permutation
driver + its calibration evidence are opt-in / outside CI. Depends on #45 for the
post-fit scan; no external (PLINK max(T) / GenABEL) comparator. No capability moved
to covered.
