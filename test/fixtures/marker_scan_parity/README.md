# Marker Scan Parity Fixture (#45)

Julia-native post-fit marker-scan target for the #45 bridge contract. The
fixture pins a small relatedness-corrected `mixed_model_marker_scan(fit,
markers)` result and its `marker_scan_result_payload(scan)` shape so the R lane
can verify numeric parity without requiring live Julia execution.

This is a serialized Julia target, not calibrated GWAS validation and not
external comparator evidence.

## Model

- 6 animals (`a1`-`a6`) with the small pedigree in `pedigree.csv`.
- Fixed effect: intercept only.
- Supplied variance components: `sigma_a2 = 1.2`, `sigma_e2 = 0.8`.
- Markers: 3 biallelic dosage columns (`m1`-`m3`) in `markers.csv`.
- Scan: post-fit `mixed_model_marker_scan(fit, markers)`.

## Files

- `phenotypes.csv` - animal IDs and response values.
- `pedigree.csv` - pedigree used to construct `Ainv`.
- `markers.csv` - marker dosages, rows aligned to `phenotypes.csv`.
- `expected_marker_scan_payload.csv` - row-aligned payload fields:
  marker IDs, effects, SEs, z-scores, chi-square, p-values,
  Bonferroni/BH values, LOD, denominator, and allele frequency.
- `expected_metadata.csv` - payload target, variance components, marker count,
  and VanRaden scale.
- `generate.jl` - reproducible generator.

## Regenerate

```sh
julia --project=. test/fixtures/marker_scan_parity/generate.jl
```

## Boundary

The fixture records nominal Wald scan output plus deterministic Bonferroni/BH
adjustments over the supplied marker set. It does not calibrate genome-wide
thresholds, run LOCO as a public workflow, activate formula-level
`marker_scan()`, join marker maps, draw plots, or promote GWAS/QTL/eQTL support
to covered.
