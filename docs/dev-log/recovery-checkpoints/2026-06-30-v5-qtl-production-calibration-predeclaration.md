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

## RESULT (run 2026-06-30 on Totoro, AFTER the predeclaration commit `807f3d8a`) — **GATE: FAIL (1 of 3) — banked NEGATIVE**

`sim/phase5_qtl_production_calibration.jl`, 96 workers, 150 cells, 41.2 min:

| design (n, m) | seeds | mean type-I | excess (mean − α) | 2·MCSE | per-seed range | verdict |
|---|---|---|---|---|---|---|
| (500, 2000)   | 50 | 0.0576 | +0.0076 | 0.0107 | [0.013, 0.185] | PASS |
| (1000, 5000)  | 50 | 0.0606 | +0.0106 | 0.0077 | [0.014, 0.119] | **FAIL** |
| (2000, 10000) | 50 | 0.0559 | +0.0059 | 0.0064 | [0.022, 0.122] | PASS |

**Overall GATE FAIL** — the (1000, 5000) excess (+0.0106) exceeds 2·MCSE (0.0077) at 50 seeds. All three means
sit CONSISTENTLY above α (0.0559–0.0606); the tighter 50-seed MCSE makes the small anti-conservatism detectable
where the 20-seed validation gates could not resolve it. Banked NEGATIVE.

### Diagnosis (verified, not hand-waved) — the FAIL is a SIMULATION null-REUSE artifact, NOT the add-one rule

The calibration harness (this campaign AND #203/#204) builds ONE permutation null from a single calibration
phenotype and REUSES it across many fresh type-I phenotypes (a standard efficiency shortcut — rebuilding the
null per replicate is ~`type1_reps`× more expensive). The add-one rule's exact `≤ α` guarantee (Phipson–Smyth)
holds only when the null draws and the test statistic are EXCHANGEABLE; a null built from one phenotype's
residual multiset is NOT exactly exchangeable with a FRESH phenotype, giving a small finite-sample
anti-conservatism. A confirmatory check on Totoro (`reuse_vs_rebuild.jl`, n=600, m=300, 12 seeds, nperm=400,
K=300) isolates this:

| procedure | mean type-I |
|---|---|
| **REUSE** (one null → many fresh phenotypes; what the gate does) | **0.0642** |
| **REBUILD** (fresh null per phenotype; what real `gwas()` does — the EXACT add-one test) | **0.0478** |

reuse − rebuild = **+0.0164**: the REUSE shortcut is the anti-conservatism source. The EXACT per-dataset rule
(rebuild) is CONSERVATIVE (0.0478 ≤ α), exactly as the Phipson–Smyth construction predicts (and as the
deterministic add-one CI unit tests already pin).

### Consequence — banked NEGATIVE, with an honest REFINEMENT (not an overturning)

- The production REUSE gate does NOT pass; the production genome-wide-significance claim does NOT proceed on
  the reuse-shortcut calibration; `gwas()` wording stays held. Nothing promoted.
- This REFINES the #203/#204 validation-scale PASSes: those were "no DETECTABLE inflation at 20 seeds" —
  accurate, but the reuse shortcut's small anti-conservatism (~0.006–0.016) IS real and detectable at
  production scale. The honest claim is therefore "the EXACT per-dataset add-one rule controls type-I at α
  (theorem + verified); the type-I-simulation's fixed-null-reuse shortcut is mildly anti-conservative."
- The CONSTRUCTIVE follow-up is a production REBUILD gate (the exact rule) — see the companion predeclaration
  `2026-06-30-v5-qtl-rebuild-production-gate-predeclaration.md`.
- NO post-hoc relaxation: the criterion was fixed at `807f3d8a` before the run; the FAIL is reported as a FAIL.
