# 2026-06-20 Genome-wide threshold calibration-property evidence (#7)

- **Goal:** add deterministic calibration-property tests for the threshold
  machinery (`genome_wide_threshold_from_null` / `genome_wide_pvalue`); extend
  the `V5-MARKER-THRESHOLD` text in capability-status, validation-debt-register,
  and `src/validation_status.jl` with the new evidence. No new validation row
  (`validation_status()` stays at 41 rows).
- **Active lenses:** Curie (simulation/recovery tests) + Fisher (inference) +
  Rose (claims gate).
- **What landed (new tests, inside the existing testset):**
  - (a) Hand-computed type-7 (1-alpha) quantile: `nulls_cal = 10:10:200` (n=20);
    alpha=0.05 → threshold=190.5 (exact arithmetic); alpha=0.01 → threshold=198.1
    (exact); both verified against the formula `h=(n-1)*(1-alpha)+1`, `q=v[lo]+frac*(v[lo+1]-v[lo])`.
  - (b) Add-one p-value `(1+count)/(n+1)` at all four boundary positions on a
    5-element null: below-all (6/6), at-max (2/6), interior (4/6), above-all (1/6).
  - (c) Strict monotonicity of `genome_wide_pvalue` in `observed` over a 6-point
    sequence; `issorted(p_seq; rev = true)`.
  - (d) Threshold↔p anti-conservative gap pinned: at the alpha=0.05 threshold of
    the n=20 null (threshold=190.5), add-one p = 2/21 ≈ 0.095 > alpha. Documents
    that the type-7 quantile undershoots the exact permutation level (gap closes
    asymptotically, as already pinned at n=1000 in the prior tests).
  - All RNG-free; placed inside the existing `Phase 5 genome-wide threshold
    machinery (#48)` testset.
- **Test count:** testset now 42 Pass (was 30 before this session's branch;
  this slice adds 12 assertions).
- **Local checks:**
  - `Pkg.test()` → **42 Pass / 42 Total** in the threshold testset; full suite
    **all green**.
  - `docs/make.jl` → build complete, no errors.
- **Status document updates (text extended, NOT a new row):**
  - `src/validation_status.jl` V5-MARKER-THRESHOLD evidence text: added
    calibration-property paragraph.
  - `docs/design/capability-status.md` row 65: added calibration-property sentence.
  - `docs/design/validation-debt-register.md` V5-MARKER-THRESHOLD: added #7
    calibration-property evidence block.
  - `validation_status()` row count: **41 rows unchanged**.
- **Rose audit (inline lens):** the new tests exercise the MACHINERY's mathematical
  calibration property (correct type-7 quantile arithmetic, exact add-one formula,
  monotonicity, anti-conservative gap). They do NOT claim type-I error control for
  realistic LD/design — that gate (#48) remains held. No new public claim;
  `gwas()` significance wording stays HELD. Status language is bounded: "calibration
  property tested" not "calibrated". Nothing promoted to covered.
- **Honest status:** deterministic threshold-machinery calibration-property evidence
  only. NOT a production genome-wide-significance claim. Realistic-LD/design
  calibration, external comparator, and R `gwas()` significance wording all remain
  held (#48 gate unchanged).
- **Branch:** `julia/threshold-calibration` (not pushed; commit only).
