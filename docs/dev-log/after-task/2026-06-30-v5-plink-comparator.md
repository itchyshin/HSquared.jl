# After-task — V5 PLINK max(T) external comparator: leg DISCHARGED (2026-06-30)

Under the maintainer `/goal` "finish all of v0.5"; the external-comparator leg was explicitly authorized by the
maintainer (the PLINK download/run had been blocked by the auto-mode classifier under the general goal). An
INDEPENDENT implementation (PLINK 1.9 max(T) permutation) reproduces HSquared's permutation genome-wide
significance. **External-comparator leg DISCHARGED; NOTHING promoted** (the V5 covered flip still owes the R
`gwas()` activation — the cross-lane leg). Claude solo, branch `feat/2026-06-30-v5-plink-comparator`.

## Live phase snapshot

- **As of 2026-06-30 (V5 PLINK max(T) external comparator — leg DISCHARGED, nothing promoted; branch
  `feat/2026-06-30-v5-plink-comparator`, PR pending; `main` @ `799d65cc`/#204).**
  Following the #203 + design-sweep type-I gates, the maintainer authorized the external comparator.
  `comparator/prepare_plink_threshold.jl` runs **PLINK 1.9 (v1.90b7.2) `--assoc --mperm 2000`** (EMP2 = max(T)
  family-wise add-one empirical p — an INDEPENDENT implementation: estimated-residual-variance OLS statistic +
  PLINK's own RNG) against `genome_wide_pvalue` on 5 datasets spanning β=0 (null) → 0.8 (strong) on the same
  n=300/m=200 LD DGP. RESULT: **SAME top marker in all 5 configs**, genome-wide p agreeing to within MC error
  (0.7166 vs 0.7256; 0.4018 vs 0.3968; add-one floor 0.0005 ×3), per-marker χ² vs PLINK T² correlation
  0.998-1.000. This DISCHARGES the V5 external-comparator (NEEDS-EXTERNAL) leg. `V5-MARKER-THRESHOLD` STAYS
  `partial`/`experimental`; `validation_status()` = 48 / covered 7 / partial 37 UNCHANGED; public-covered
  FITTING = 1; `gwas()` wording HELD. **v0.5 covered now owes ONLY the R `gwas()`/`marker_scan()` activation
  (cross-lane NEEDS-R/BRIDGE [Codex]) + coverage calibration + the #45 dependency.** START HERE: this report.

## What changed

- NEW `comparator/prepare_plink_threshold.jl` (simulate β-grid datasets → HSquared scan + permutation max(T)
  add-one p → write PLINK `.ped/.map` → run `--assoc --mperm` → parse EMP2 + per-marker statistic → compare).
- NEW `comparator/plink_threshold/` (committed: `comparison.tsv`, `*.qassoc.mperm` EMP2 outputs, `README.md`,
  `.gitignore` for the bulky regenerable PLINK inputs).
- NEW recovery-checkpoint `docs/dev-log/recovery-checkpoints/2026-06-30-v5-plink-maxt-comparator.md`.
- Evidence APPENDED + the `missing`/`claim_boundary` fences UPDATED on V5-MARKER-THRESHOLD across
  `src/validation_status.jl`, `docs/design/validation-debt-register.md`, `docs/design/capability-status.md`
  (the "no external comparator parity" fence was honestly RETIRED — a comparator now exists — and the test pins
  that asserted it were re-pointed at the new honest content; `status` stays `partial`).

## Checks run and exact outcomes

- Comparator: `PLINK=… julia --project=. comparator/prepare_plink_threshold.jl` → 5/5 configs same_top=true,
  genome-wide p agreement as tabulated, per-marker cor 0.998-1.000.
- `Pkg.test()` → initially 2 failures (the V5 `missing`/`claim_boundary` pin tests at `test/runtests.jl:430,432`
  asserted the now-retired "hsquared PR #83" / "no external comparator parity" claims) → re-pointed the two pins
  to stable phrases in the updated strings → **"Testing HSquared tests passed"** (exit 0).
- `validation_status()` independently = 48 / covered 7 / partial 37 — UNCHANGED.
- Documenter: unaffected (no `docs/src/` change).

## Public claim audit (Rose)

Real `rose-systems-auditor` audit launched on the committed slice. [Verdict folded in once it returns.]

## Tests of the tests

- The comparator is a genuine cross-implementation check: PLINK uses a DIFFERENT per-marker statistic
  (estimated vs supplied residual variance) and a DIFFERENT RNG/permutation engine, yet reproduces the same top
  marker and genome-wide p. Agreement is therefore not a tautology.
- The known-vs-estimated-variance difference is recorded honestly (max relative χ² diff ~0.09 null → ~0.27 at a
  strong-causal marker); the genome-wide DECISION agrees regardless.
- The two failing pin-tests were a FEATURE, not a nuisance: they forced a conscious, honest update of the
  claim-boundary when the underlying evidence changed (comparator landed), rather than silent drift.

## Remaining v0.5 legs (updated honest map)

1. **Calibrated thresholds** — ✅ type-I-control done (#203 + design grid, 4 designs).
2. **External comparator** — ✅ DONE (this slice; PLINK max(T), 5 datasets, same-top + agreeing genome-wide p).
3. **R `gwas()` / `marker_scan()` activation** — ⛔ still OUT OF LANE (NEEDS-R/BRIDGE [Codex], the `hsquared`
   repo). **This is now the SOLE gating leg for the V5 covered flip** (doc-18 line 120: "calibrated
   thresholds → R gwas()"), plus coverage calibration + the #45 post-fit-scan dependency.

**Conclusion:** both Julia-lane-reachable v0.5 legs (calibration + external comparator) are DONE. The covered
close is now gated solely on the R-lane `gwas()` activation (Codex) + maintainer G10 — which this Julia lane
must not perform. Nothing was promoted; honest status discipline holds.

## Next actions

1. **Cross-lane handoff to Codex/R:** activate `marker_scan()`/`gwas()` in `hsquared` against the now-complete
   Julia-lane evidence (calibration gates + PLINK comparator), then the covered flip + maintainer G10.
2. (Optional hardening) a second external comparator (GCTA `--mlma` / statgenGWAS) or a covariate-adjusted
   (Freedman–Lane) null — not required for the leg, additional robustness.
