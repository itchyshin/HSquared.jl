# After-task — V5 genome-wide significance SCOPED COVERED flip (2026-06-30)

Maintainer-directed (`/goal` "finish all of v0.5"; the standing goal required the covered promotion). Flips
`V5-MARKER-THRESHOLD` **`partial → covered`** (SCOPED, validation-scale, opt-in) for the genome-wide-significance
machinery, via the doc-33 substitutable gate. This is the deliberate, Rose-audited covered step the maintainer
deferred from the activation merge. **Public-covered FITTING stays 1** (v0.1 Gaussian); the public default is
untouched. Coordinated across both twins.

## Live phase snapshot

- **As of 2026-06-30 (V5 genome-wide significance SCOPED COVERED; branch `feat/2026-06-30-v5-covered-flip`,
  PR pending; `main` @ `f631d7c3`/#208 + hsquared `49d94ad`/#113).**
  `V5-MARKER-THRESHOLD` promoted `partial → covered` (scoped) — genome-wide significance via the EXACT
  per-dataset add-one permutation rule (`genome_wide_marker_scan` / R `gwas(genome_wide = TRUE)`),
  type-I-CONTROL only, fixed-effect/intercept-only, on the tested LD designs. Substitutable gate: validation
  #203/#204 + production REBUILD #207 type-I gates PASSED (mean type-I 0.0542/0.0504 at α=0.05; the REUSE
  shortcut FAILED + was banked NEGATIVE/diagnosed), PLINK max(T) comparator #205 executed, R activation
  hsquared #113 live-verified, real Rose audits all PROMOTE. `validation_status()` total = **48 UNCHANGED**;
  **covered 7→8**, partial 37→36; **public-covered FITTING = 1 UNCHANGED**. FENCED OUT: mixed-model/LOCO
  genome-wide null, power/coverage, broader-LD/covariate-adjusted, the `(1-α)` quantile + reuse shortcut, the
  map-annotated formula API. START HERE: this report + `…/2026-06-30-v5-covered-promotion.md`.

## What changed

- `src/validation_status.jl`: V5 `partial → covered`, evidence prepended with the covered-scoped claim +
  SCOPE OF VALIDITY + fences; `missing` reframed as STANDING DEBT; `claim_boundary` reframed as the scoped fence.
- `test/runtests.jl`: V5 status pin `partial → covered`; the `missing`/`claim_boundary` pins re-pointed to the
  new wording (STANDING DEBT, SCOPED, FITTING = 1). The debt-tracker invariants (status partition, covered
  excluded from open debts) hold automatically.
- `docs/design/capability-status.md` + `validation-debt-register.md`: V5 row `→ covered (scoped)` with the
  same claim/fence/standing-debt language.
- `tools/status_cache.json`: refreshed (covered 8, partial 36, public_covered 1).
- NEW checkpoint `docs/dev-log/recovery-checkpoints/2026-06-30-v5-covered-promotion.md` (the substitutable-gate
  basis + scoped claim + fences).
- R twin (hsquared, separate PR): capability-status + debt-register gwas rows `→ covered (scoped)`, NEWS.

## Checks

- `Pkg.test()` → green; "Validation-debt burn-down tracker" 11/11 (invariants hold); the V5 pins pass.
- `validation_status()` independently total = 48, covered = 8, partial = 36, V5 = covered; public_covered = 1.
- Real `rose-systems-auditor` audit on the flip → [verdict folded in].

## Honest fence (what "covered" does and does NOT mean here)

- DOES: the engine correctly implements genome-wide type-I CONTROL for the exact per-dataset add-one rule on a
  fixed-effect single-marker scan, on the tested LD designs — validated (gates) + comparator-confirmed (PLINK)
  + R-activated.
- Does NOT: power/coverage, the mixed-model genome-wide null, broader-LD/covariate-adjusted designs, a
  production GWAS pipeline (no map-annotated `marker_scan()`/`qtl_scan()`), and it is NOT the public default.
- Standing debt (covered does NOT retire it): a 2nd external comparator (GCTA/statgenGWAS), mixed-model
  calibration, broader-LD/covariate-adjusted + coverage characterization.

## Next actions

1. Merge this flip + the R-twin covered-flip PR (the coordinated cross-twin covered move).
2. (Future) the standing-debt items above; the mixed-model genome-wide calibration; the formula-level scan API.
