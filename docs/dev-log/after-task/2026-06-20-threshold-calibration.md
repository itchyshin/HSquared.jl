# After-Task Report: Genome-wide threshold calibration-property evidence (#7)

**Date:** 2026-06-20
**Branch:** `julia/threshold-calibration`
**Slice:** Issue #7 — calibration evidence for `genome_wide_threshold_from_null` /
`genome_wide_pvalue`

---

## 1. What was done

Added a deterministic calibration-property test block inside the existing
`Phase 5 genome-wide threshold machinery (#48)` testset in `test/runtests.jl`,
and extended the `V5-MARKER-THRESHOLD` evidence text in three status documents.

No new code was written in `src/`. No new exported functions. No new validation
row. `validation_status()` stays at **41 rows**.

---

## 2. Tests added (all deterministic, no RNG)

Four sub-groups added after the existing finite-guard tests:

**(a) Analytic quantile verification.**
`nulls_cal = collect(10.0:10.0:200.0)` (n=20). Hand-computed type-7 quantile:

- alpha=0.05: `h = 19·0.95+1 = 19.05`, lo=19, frac=0.05 → `190 + 0.05·10 = 190.5` (exact)
- alpha=0.01: `h = 19·0.99+1 = 19.81`, lo=19, frac=0.81 → `190 + 0.81·10 = 198.1` (exact)

Asserts: threshold matches hand value exactly (integer arithmetic, no `atol` needed);
n_null=20; alpha=0.01 threshold > alpha=0.05 threshold.

**(b) Add-one p-value formula, all boundary positions.**
`null_cal2 = [1.0, 2.0, 3.0, 4.0, 5.0]` (n=5). Four cases:
- obs=5.0 (== max): `count(>=5)=1` → p=2/6
- obs=2.5 (interior): `count(>=2.5)=3` → p=4/6
- obs=6.0 (> max): `count(>=6)=0` → p=1/6
- obs=0.5 (< min): `count(>=0.5)=5` → p=6/6=1.0

**(c) Strict monotonicity.**
`obs_seq = [0.5, 1.5, 2.5, 3.5, 4.5, 5.5]`; p-values are strictly decreasing
(`issorted(p_seq; rev=true)`).

**(d) Threshold↔p anti-conservative gap.**
At `thr_cal_05.threshold = 190.5` against `nulls_cal`:
only element 200 satisfies `>= 190.5`, so `count=1`, p = `(1+1)/21 = 2/21 ≈ 0.095`.
Asserted: `genome_wide_pvalue(thr_cal_05.threshold, nulls_cal) == 2/21` (exact) and
`> thr_cal_05.alpha`. Documents the anti-conservative gap at small n_null; gap closes
asymptotically (already pinned at n=1000 in the prior tests).

---

## 3. Status document updates

| Document | Change |
|---|---|
| `test/runtests.jl` | 12 new assertions inside existing `Phase 5 genome-wide threshold machinery (#48)` testset |
| `src/validation_status.jl` | V5-MARKER-THRESHOLD evidence text: added calibration-property paragraph |
| `docs/design/capability-status.md` | Row 65: added calibration-property sentence block |
| `docs/design/validation-debt-register.md` | V5-MARKER-THRESHOLD: added `#7 2026-06-20` calibration-property evidence block |
| `docs/dev-log/check-log.d/2026-06-20-threshold-calibration.md` | New check-log entry |

`validation_status()` row count: **41 (unchanged)**.

---

## 4. Local checks

| Check | Result |
|---|---|
| `Pkg.test()` | All green; threshold testset: 42 Pass / 42 Total |
| `docs/make.jl` | Build complete, no errors |

---

## 5. Rose audit

**Claim boundary:** The new tests exercise the **mathematical calibration property**
of the threshold machinery — correct type-7 quantile arithmetic, exact add-one
formula, monotonicity, and the anti-conservative gap between the quantile threshold
and the exact permutation level.

What is NOT claimed:
- No type-I error control claim for realistic LD or a genomic design.
- No coverage-calibration claim.
- No external comparator evidence.
- `gwas()` significance wording in R stays **held** (#48 gate unchanged).
- Nothing promoted from `partial` to `experimental` or `covered`.

Status language in all three documents says "calibration-property tested" or
"MACHINERY calibration property", not "calibrated". The distinction is honest:
the empirical-null threshold machinery is shown to compute the correct quantile
and add-one p-value by construction, which is a necessary condition for
calibration but not sufficient for realistic genome-wide significance control.

**Rose verdict:** CLEAN. No new unsupported claim.

---

## 6. Honest status

- Threshold machinery calibration property: deterministically verified (this slice).
- Realistic-LD/design type-I error control: NOT verified (#48 gate HELD).
- External comparator (PLINK max(T)/GenABEL): NOT present (#48 gate HELD).
- R `gwas()` significance wording: HELD.
- `validation_status()`: 41 rows (unchanged).
- Covered capabilities: unchanged (v0.1 univariate Gaussian animal model only).

---

## 7. Files changed

- `test/runtests.jl` — 12 assertions added to existing testset
- `src/validation_status.jl` — V5-MARKER-THRESHOLD evidence text extended
- `docs/design/capability-status.md` — V5-MARKER-THRESHOLD row extended
- `docs/design/validation-debt-register.md` — V5-MARKER-THRESHOLD row extended
- `docs/dev-log/check-log.d/2026-06-20-threshold-calibration.md` — new
- `docs/dev-log/after-task/2026-06-20-threshold-calibration.md` — this report

---

## 8. Next steps (not blocking)

- The `sim/phase5_threshold_calibration.jl` harness can be run opt-in to
  record an empirical type-I smoke; this does not change the status.
- The realistic-LD calibration and external comparator (PLINK/GenABEL) remain
  the gate for R `gwas()` significance wording (#48).
- No cross-lane coordination needed for this slice.
