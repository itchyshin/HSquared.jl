# Pre-declaration — V5 add-one genome-wide threshold BROADER-DESIGN robustness sweep

Status: **PRE-DECLARED, to be committed BEFORE the run** (no post-hoc relaxation; 2026-06-14 rule).
Follow-up to the #203 single-design add-one gate PASS. #203 established type-I control for the conservative
add-one `genome_wide_pvalue` rule at ONE design (n=300, m=200); its after-task explicitly recorded "one design
point" as a limitation. This sweep tests the SAME one-sided-upper criterion across a GRID of (n, m) designs.

## Machinery + DGP

`run_addone_calibration` (reused verbatim from `sim/phase5_qtl_addone_gate.jl`) — add-one decision rule
`genome_wide_pvalue ≤ α` against the LD-aware residual-permutation null. Harness:
`sim/phase5_qtl_addone_design_sweep.jl`.

- **NULL DGP** (no marker signal): correlated markers (`_simulate_markers`: LD via shared latent factors +
  allele-freq gradient), intercept-only `X`, σ²e=1, nperm=2000, type1_reps=1000, α=0.05.
- **DESIGN GRID:** (n, m) ∈ {(200, 100), (300, 200), (500, 300)} — small/medium/larger n and marker count.
- 10 cold seeds per design, UNSEEN at declaration:
  - (200, 100): 20260940..20260949
  - (300, 200): 20260950..20260959
  - (500, 300): 20260960..20260969

  (Disjoint from #203's seeds 20260920..20260939 and #202's 20260900..20260919.)

## PASS criteria (ALL required; fixed here, not adjustable after seeing results)

Per design point: 10/10 runs complete AND `mean(empirical_type1) − α ≤ 2·MCSE`
(`MCSE = sd(per-seed empirical_type1)/√10`), **ONE-SIDED UPPER** (not anti-conservative). The overall verdict
is **PASS iff ALL THREE design points pass.**

The one-sided criterion is justified identically to #203: the add-one rule `(1 + #{null ≥ obs})/(nperm + 1) ≤ α`
is a valid exact permutation test that controls type-I at **≤ α by construction** (Phipson & Smyth 2010), so
the designed estimand is an upper bound and the honest question is only whether the level is VIOLATED at any
design. Fixed before the run, not a post-hoc relaxation.

## Interpretation (declared in advance)

- **PASS** = NO DETECTABLE type-I inflation of the add-one rule across this design grid — a low-power
  non-rejection per design, read as "consistent with valid level control across designs," never "exactly
  calibrated." Conservative (below α) is the designed behaviour and still a PASS.
- **FAIL at any design** = a banked NEGATIVE and a surprise (it would mean the residual-permutation null and
  the fresh-phenotype null are not exchangeable at THAT design). The V5 covered claim would NOT proceed and
  the R `gwas()` significance wording stays held. NO relaxation after the fact.
- Either way: `validation_status()` count, public-covered fitting = 1, and the threshold row's status are
  unaffected by the OUTCOME. This sweep HARDENS the calibration leg (one design → a design grid); it does NOT
  by itself reach V5 covered, which STILL owes an external comparator (PLINK `max(T)` / GCTA / GenABEL) and the
  R `gwas()`/`marker_scan()` activation (the latter is the NEEDS-R/BRIDGE Codex leg per doc-18).

## Honest scope (declared up front)

- Three design points on ONE LD architecture and the intercept-only null. It does not test covariate-adjusted
  GWAS (Freedman–Lane / ter Braak), other LD schemes, or power.
- This is type-I-CONTROL robustness across (n, m), not an external-comparator parity check.

## RESULT (run AFTER the predeclaration commit) — **PENDING**

To be filled in by `sim/phase5_qtl_addone_design_sweep.jl` after this file is committed.
