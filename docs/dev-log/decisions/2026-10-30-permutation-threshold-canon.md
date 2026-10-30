# Decision — permutation max-statistic threshold is the genome-wide canon (#48)

Date: 2026-10-30. Lane: Julia engine (`HSquared.jl`). Binding source:
[Decision (Shinichi, 25 Oct 2026) on #48](https://github.com/itchyshin/HSquared.jl/issues/48#issuecomment-6402029138).

## Decision

Accept the documented empirical max-statistic permutation threshold already in
HSquared (`genome_wide_threshold_from_null` and the add-one
`genome_wide_pvalue`) as the calibration canon for genome-wide significance.
Do not wait for PLINK, GEMMA, or GCTA runs on a machine that does not have
those tools.

This records the owner choice. It does not close #48, does not promote a
capability row, and does not activate public significance wording.

## Already banked (not reopened here)

- `V5-MARKER-THRESHOLD` is already **covered (scoped)** in
  `docs/design/capability-status.md` and
  `docs/design/validation-debt-register.md` for the exact per-dataset add-one
  permutation rule, type-I control only, fixed-effect / intercept-only, on the
  tested LD designs. `public_covered_count` remains 7. This is not a public
  default.
- Fixed-panel mini-smoke:
  `docs/dev-log/recovery-checkpoints/2026-06-21-threshold-fixed-panel-calibration.tsv`.
- hsquared PR #83 recorded that PLINK / GEMMA / GCTA were absent on PATH.

## Still required on #48

The 25 Oct next step after this record:

1. A realistic-LD type-I calibration with the existing
   `genome_wide_threshold_from_null` (new evidence, not a seed rerun of the
   mini-smoke).
2. Wire calibration metadata into marker-scan outputs without implying
   significance before that evidence exists.
3. Rose audit before any public genome-wide-significance claim or R `gwas()`
   significance wording.

Fenced out, unchanged: mixed-model / LOCO genome-wide null, power, broader-LD
or covariate-adjusted calibration, the `(1-alpha)` quantile rule as a
substitute, and any `V5-*` covered flip beyond the scoped row already on
`main`.

## Consequences

- External-tool absence is no longer a blocker for choosing the canon.
- External-tool absence is still a blocker for a second-comparator claim.
- Effective-number / FDR workflow is not decided here.
