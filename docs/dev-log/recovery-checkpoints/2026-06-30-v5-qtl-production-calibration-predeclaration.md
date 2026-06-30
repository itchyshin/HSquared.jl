# Pre-declaration — V5 PRODUCTION-SCALE realistic-design type-I calibration campaign (add-one rule)

Status: **PRE-DECLARED, to be committed BEFORE the run** (no post-hoc relaxation; 2026-06-14 rule).
Follow-up to the validation-scale add-one gates (#203 single design n=300/m=200; #204 3-point grid, all n≤500,
m≤300, ≤20 seeds). doc-18 lists "a realistic-LD/design calibration run that controls genome-wide type-I error"
as an OWED item that holds the production genome-wide-significance claim (the #48 gate). This campaign supplies
that at REALISTIC marker counts / sample sizes with many more seeds, run in parallel on **Totoro** (Shinichi's
384-core server; ≤100 cores used).

## Machinery + DGP

`production_cell(n, m, seed)` (mirrors `run_addone_calibration`'s RNG order) — add-one decision rule
`genome_wide_pvalue ≤ α` against the LD-aware residual-permutation null. Harness:
`sim/phase5_qtl_production_calibration.jl` (Julia `Distributed` `pmap` over independent cells, `NWORKERS=96`,
`OPENBLAS_NUM_THREADS=1`).

- **NULL DGP** (no marker signal): correlated markers (`_simulate_markers`: LD via shared latent factors +
  allele-freq gradient), intercept-only `X`, σ²e=1, nperm=2000, type1_reps=1000, α=0.05.
- **DESIGN GRID (production scale):** (n, m) ∈ {(500, 2000), (1000, 5000), (2000, 10000)} — realistic marker
  counts (2k–10k) and sample sizes (500–2000), 1–2 orders of magnitude larger than the validation gates.
- 50 cold seeds per design, UNSEEN at declaration:
  - (500, 2000):   20261000..20261049
  - (1000, 5000):  20261050..20261099
  - (2000, 10000): 20261100..20261149

  (Disjoint from all prior gate seeds 20260900..20260969.)

## PASS criteria (ALL required; fixed here, not adjustable after seeing results)

Per design point: all 50 cells complete AND `mean(empirical_type1) − α ≤ 2·MCSE`
(`MCSE = sd(per-seed empirical_type1)/√50`), **ONE-SIDED UPPER** (not anti-conservative). Overall verdict
**PASS iff ALL THREE design points pass.**

The one-sided criterion is justified identically to #203/#204: the add-one rule
`(1 + #{null ≥ obs})/(nperm + 1) ≤ α` is a valid exact permutation test controlling type-I at **≤ α by
construction** (Phipson & Smyth 2010); the gate tests only that the level is not VIOLATED. With **50 seeds**
the MCSE is √(50/20) ≈ 1.6× tighter than the #203 gate, so this is a **STRICTER** test of the same null
hypothesis at larger scale.

## Interpretation (declared in advance)

- **PASS** = NO DETECTABLE type-I inflation of the add-one rule at production scale — a (now higher-power)
  non-rejection, read as "consistent with valid level control at realistic marker counts," never "exactly
  calibrated." Conservative (below α) is the designed behaviour and still a PASS.
- **FAIL at any design** = a banked NEGATIVE. With the tighter 50-seed MCSE, a small systematic excess that
  was within noise at validation scale could become detectable — that would be an honest finding (the
  permutation/fresh-phenotype nulls are not perfectly exchangeable, or more nperm is needed), the production
  genome-wide-significance claim would NOT proceed, and `gwas()` wording stays held. NO post-hoc relaxation.
- Either way: `validation_status()` count, public-covered fitting = 1, and the threshold row's status are
  unaffected by the OUTCOME. A PASS strengthens the calibration leg from validation→production scale; it does
  NOT by itself reach V5 covered (which still owes the R `gwas()`/`marker_scan()` activation — the gating
  cross-lane leg).

## Honest scope (declared up front)

- Three production-scale design points on ONE LD architecture and the intercept-only null. It does not test
  covariate-adjusted GWAS (Freedman–Lane / ter Braak), other LD schemes, or power.
- Type-I CONTROL at scale, not an external-comparator parity check (that is the merged #205 PLINK leg).
- Run on Totoro (his own server), ≤100 cores, `OPENBLAS_NUM_THREADS=1`; the result TSV
  (`sim/phase5_production_calibration.tsv`) is banked.

## RESULT (run AFTER the predeclaration commit) — **PENDING**

To be filled in by `sim/phase5_qtl_production_calibration.jl` (Totoro run) after this file is committed.
