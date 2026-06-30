# 2026-06-30 · V5-MARKER-THRESHOLD genome-wide significance → covered (SCOPED, validation-scale) — close

The first **non-point-estimator** covered model (type-I-CONTROL, not parameter recovery). **Validation-scale /
opt-in. Public-covered FITTING surface stays 1 (v0.1 Gaussian).** Substitutable gate (doc-16 §doc-33,
path (b)), adapted for a type-I-control estimand.

## The substitutable-gate legs (doc-16, type-I-control adaptation of G11)

1. **Pre-declared type-I-CONTROL gates** (the recovery-gate analogue for a significance rule). The accept/reject
   rule is the EXACT per-dataset add-one permutation p (`genome_wide_pvalue`):
   - #203 single-design add-one gate PASS (mean type-I 0.0543) + #204 design-grid PASS (0.068/0.058/0.061),
     each ≤ α + 2·MCSE, one-sided-upper (not-anti-conservative). Predeclarations committed BEFORE each run.
   - #207 **production** REBUILD gate (the exact per-dataset rule at realistic scale) — re-derived from the raw
     TSV `sim/phase5_rebuild_production_gate.tsv`: n=500 block mean **0.054167**, n=1000 block mean **0.050417**
     (→ 0.0542 / 0.0504), both ≤ α + 2·MCSE → **GATE PASS**.
   - Banked NEGATIVES (not buried): the `(1-α)` quantile rule FAILED anti-conservative (#202, mean 0.069 =
     2.42·MCSE); the fixed-null-REUSE simulation shortcut is mildly anti-conservative (mean 0.056-0.061),
     diagnosed (`sim/phase5_reuse_vs_rebuild_diagnostic.jl`: REUSE 0.0642 vs REBUILD 0.0478) as a simulation
     artifact, NOT a flaw in the shipped per-dataset rule.
2. **External comparator** — PLINK 1.9 `--assoc --mperm 2000` (max(T) family-wise add-one EMP2), an INDEPENDENT
   implementation (estimated-variance OLS + own RNG), reproduces `genome_wide_pvalue` across β=0→0.8: same top
   marker ×5, genome-wide p to MC error, per-marker χ²/T² cor 0.998-1.000 (#205, merged;
   `comparator/prepare_plink_threshold.jl`).
3. **R activation** — `gwas(fit, markers, method = "single", genome_wide = TRUE)` surfaces the validated exact
   rule, live-verified element-wise (hsquared #113, merged); engine entry point `genome_wide_marker_scan`
   exported (#208, merged).

## Promotion (atomic, 3 surfaces flipped together)

- `src/validation_status.jl` — V5-MARKER-THRESHOLD `partial → covered`; evidence scoped to the EXACT
  per-dataset add-one rule, **type-I CONTROL only**, fixed-effect/intercept-only, the tested LD designs
  (n∈{300..2000}, m∈{100..10000}); FENCED OUT: mixed-model/LOCO null, power/coverage, broader-LD/
  covariate-adjusted, the `(1-α)` quantile rule + reuse shortcut, the map-annotated formula API.
- `docs/design/capability-status.md` — genome-wide threshold row `experimental → covered` with the same fence.
- `docs/design/validation-debt-register.md` — `partial → covered`; STANDING DEBT retained (2nd external
  comparator e.g. GCTA/statgenGWAS, mixed-model calibration, broader-LD/covariate-adjusted + coverage, the #45
  dependency) — "covered does NOT retire debt".

## Checks run + exact outcomes

- `julia --project=. -e 'using Pkg; Pkg.test()'` → **"Testing HSquared tests passed"** (exit 0; zero Fail/Error;
  count-guard `test/runtests.jl:174` == 48 and the V5 covered pin `:424` pass).
- `validation_status()` → total **48** (UNCHANGED), covered **8** (was 7), covered_external 3, partial **36**
  (was 37), planned 1.
- `tools/status_cache.json` refreshed: 48 / covered 8 / covered_external 3 / partial 36 / **public_covered 1**
  (hard-pinned in `tools/gen_status_json.jl` with an honesty assertion — V5 is opt-in, NOT a fitting capability
  and NOT the public default).
- Real `rose-systems-auditor` audit on the flip → **PROMOTE-WITH-CHANGES** (substance airtight: gate type-I
  re-derived exactly, invariants hold, fences consistent, cross-twin discipline exemplary; the two required
  changes — this check-log entry + the doc-16 V5 exemplar — are the DoD-completeness paperwork, now added).

## Cross-twin

- The covered claim is the **Julia engine** row. The R public `gwas(genome_wide = TRUE)` surface STAYS
  experimental/`partial` (engine-covered ≠ R-public-covered; the V4-MV-REML / Rose-risk-5 pattern) — hsquared
  PR #114 (the R-side note), held OPEN for G10.
- Both flip PRs (HSquared.jl #209, hsquared #114) are **held OPEN, "G10 awaiting"** — NOT self-merged.
