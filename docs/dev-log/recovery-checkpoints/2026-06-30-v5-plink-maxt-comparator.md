# Recovery checkpoint — V5 PLINK max(T) external comparator (NEEDS-EXTERNAL leg discharged)

Date: 2026-06-30. Under the maintainer `/goal` "finish all of v0.5"; the external-comparator leg was authorized
by the maintainer (the download/run of PLINK had been blocked by the auto-mode classifier under the general
goal). This banks the **external-comparator leg** of V5 — an INDEPENDENT implementation reproducing HSquared's
permutation genome-wide significance. NOTHING promoted (the V5 covered flip still owes the R `gwas()` activation).

## What was compared

- **HSquared:** `genome_wide_pvalue` (add-one max(T) genome-wide p `(1 + #{null ≥ obs})/(nperm+1)`) against the
  residual-permutation null of the per-scan-MAX chi-square from `single_marker_scan` (supplied known variance
  σ²e=1).
- **PLINK 1.9 (v1.90b7.2, 11 Dec 2023):** `--assoc --mperm 2000` → EMP2, the max(T) family-wise add-one
  empirical p, via an estimated-residual-variance OLS regression statistic and PLINK's own RNG/permutations.
- **Same estimand** (max-statistic permutation genome-wide significance), **independent implementation**
  (different per-marker statistic + different RNG/permutation engine) — so agreement is a real cross-check.
- Harness: `comparator/prepare_plink_threshold.jl` (committed); results `comparator/plink_threshold/`.

## DGP

Five datasets, n=300 records, m=200 correlated markers (the same `_simulate_markers` LD DGP as the V5
calibration gates), intercept-only `X`, σ²e=1, with a planted QTL at marker 100 of effect β ∈ {0, 0.25, 0.40,
0.60, 0.80} (null → strong). Seeds 20260980..20260984. PLINK seed 42. nperm=2000.

## RESULT — close agreement across the null→strong range

| config | β | HSquared top | HSquared gw p | PLINK top | PLINK EMP2 | same top | per-marker cor(χ², T²) |
|---|---|---|---|---|---|---|---|
| null | 0.00 | marker_156 | 0.7166 | marker_156 | 0.7256 | ✅ | 0.99998 |
| weak | 0.25 | marker_172 | 0.4018 | marker_172 | 0.3968 | ✅ | 0.99996 |
| mod | 0.40 | marker_100 | 0.0005 | marker_100 | 0.0005 | ✅ | 0.99916 |
| strong | 0.60 | marker_100 | 0.0005 | marker_100 | 0.0005 | ✅ | 0.99861 |
| vstrong | 0.80 | marker_100 | 0.0005 | marker_100 | 0.0005 | ✅ | 0.99794 |

- **Same top marker in all 5 configs** — HSquared and PLINK pick the identical lead SNP.
- **Genome-wide p agrees** to within Monte-Carlo error (~0.01) for the intermediate (null/weak) cases and
  exactly at the add-one floor `1/2001 ≈ 0.0005` for the three significant cases.
- **Per-marker statistics correlate 0.998–1.000** (HSquared known-variance χ² vs PLINK estimated-variance T²).

## Honest scope / caveats

- The two per-marker statistics are not identical (known vs estimated residual variance); they diverge mildly
  where a marker explains real variance (max relative χ² difference ~0.09 null → ~0.27 at the strong-causal
  marker). The genome-wide DECISION and family-wise p agree regardless.
- One LD architecture, intercept-only design, single trait. This is a cross-implementation check of the
  permutation genome-wide-significance estimand — not a calibration across LD schemes (that is the #203 +
  design-sweep type-I gates) and not a covariate-adjusted GWAS comparator.
- PLINK is not vendored; reproduce by downloading PLINK 1.9 and running the committed harness with `PLINK=...`.

## Status impact

- **DISCHARGES the V5 external-comparator leg** (the NEEDS-EXTERNAL `PLINK max(T)/GCTA/GenABEL` item).
- `V5-MARKER-THRESHOLD` **STAYS `partial`/`experimental`** — the covered FLIP still requires the R
  `gwas()`/`marker_scan()` activation (the cross-lane NEEDS-R/BRIDGE [Codex] leg per doc-18 line 120-121).
- `validation_status()` count, public-covered fitting = 1, and `gwas()` wording are UNCHANGED. NOTHING promoted.
