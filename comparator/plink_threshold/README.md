# PLINK max(T) genome-wide significance comparator (V5 NEEDS-EXTERNAL leg)

External, same-method comparator for HSquared.jl's permutation genome-wide p-value
(`genome_wide_pvalue`). PLINK 1.9 `--assoc --mperm N` computes EMP2, the max(T)
family-wise add-one empirical p `(1 + #{perm max ≥ obs})/(N+1)` — the SAME
max-statistic-permutation estimand — but via an INDEPENDENT implementation
(estimated-residual-variance OLS regression statistic + PLINK's own RNG/permutation),
so agreement is a genuine cross-implementation check.

## Reproduce

PLINK is **not vendored**. Download PLINK 1.9 from <https://www.cog-genomics.org/plink/1.9/>
(tested with **v1.90b7.2, 11 Dec 2023**), then from the repo root:

```sh
PLINK=/path/to/plink JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 \
  julia --project=. comparator/prepare_plink_threshold.jl
```

This simulates five NULL-DGP-plus-planted-QTL datasets (β = 0 → 0.8; n=300, m=200
correlated markers; the same `_simulate_markers` LD DGP as the calibration gates),
runs the HSquared scan + residual-permutation max(T) null + add-one genome-wide p,
writes PLINK `.ped/.map`, runs `--assoc --mperm 2000`, and writes `comparison.tsv`.

## Result (v1.90b7.2, nperm=2000)

| config | β | HSquared top | HSquared gw add-one p | PLINK top | PLINK EMP2 | same top | per-marker cor(χ², T²) |
|---|---|---|---|---|---|---|---|
| null | 0.00 | marker_156 | 0.7166 | marker_156 | 0.7256 | ✅ | 0.99998 |
| weak | 0.25 | marker_172 | 0.4018 | marker_172 | 0.3968 | ✅ | 0.99996 |
| mod | 0.40 | marker_100 | 0.0005 | marker_100 | 0.0005 | ✅ | 0.99916 |
| strong | 0.60 | marker_100 | 0.0005 | marker_100 | 0.0005 | ✅ | 0.99861 |
| vstrong | 0.80 | marker_100 | 0.0005 | marker_100 | 0.0005 | ✅ | 0.99794 |

**Agreement:** the same top marker in every config; genome-wide p agreeing to within
Monte-Carlo error (~0.01) across the null→strong range and exactly at the add-one
floor `1/(2000+1) ≈ 0.0005`; per-marker statistics correlating 0.998–1.000.

## Honest scope

- The two per-marker statistics are NOT identical: HSquared uses a supplied known
  residual variance (σ²e = 1), PLINK estimates the residual variance per marker. They
  diverge mildly when a marker explains real variance (max relative χ² difference ~0.09
  under the null, ~0.27 at a strongly-causal marker), but the genome-wide significance
  DECISION and the family-wise p agree.
- One LD architecture, intercept-only design, single-trait. This confirms the
  permutation genome-wide-significance estimand against an independent implementation;
  it is not a calibration across LD schemes/designs (that is the type-I gates) and not
  a covariate-adjusted GWAS check.
- Discharges the V5 external-comparator leg. The V5 covered FLIP additionally requires
  the R `gwas()`/`marker_scan()` activation (the cross-lane NEEDS-R/BRIDGE leg).

Committed: `comparison.tsv`, the `*.qassoc.mperm` EMP2 outputs, this README. The bulky
regenerable PLINK inputs (`.ped/.map/.qassoc/...`) are gitignored.
