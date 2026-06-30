# Pre-declaration — V5 PRODUCTION REBUILD gate (the EXACT per-dataset add-one rule)

Status: **PRE-DECLARED, to be committed BEFORE the run** (no post-hoc relaxation; 2026-06-14 rule).
Constructive follow-up to the REUSE-shortcut production NEGATIVE
(`2026-06-30-v5-qtl-production-calibration-predeclaration.md`: GATE FAIL because the calibration harness reuses
ONE permutation null across fresh phenotypes; the Totoro `reuse_vs_rebuild` diagnostic isolated it — REUSE
0.0642 vs REBUILD 0.0478). This gate runs the procedure REAL `gwas()` uses — a FRESH permutation null built from
each analyzed phenotype (the exact add-one test) — and confirms type-I control at realistic (n, m) scale.

## Machinery + DGP

`rebuild_cell(n, m, seed)` (`sim/phase5_qtl_rebuild_production_gate.jl`): for EACH type-I replicate, draw a
fresh NULL phenotype, build its OWN residual-permutation null (nperm=500), and apply the add-one
`genome_wide_pvalue ≤ α`. Julia `Distributed` `pmap` over cells, `OPENBLAS_NUM_THREADS=1`. Run on Totoro
(≤100 cores).

- **NULL DGP**: correlated markers (`_simulate_markers`: LD via shared latent factors + allele-freq gradient),
  intercept-only `X`, σ²e=1, α=0.05, nperm=500, type1_reps=120.
- **DESIGNS (realistic):** (n, m) ∈ {(500, 2000), (1000, 5000)}, 20 cold seeds each:
  - (500, 2000):  20263000..20263019
  - (1000, 5000): 20263020..20263039

  (Disjoint from all prior gate/diagnostic seeds.)

## PASS criteria (ALL required; fixed here, not adjustable after seeing results)

Per design: all 20 cells complete AND `mean(type1) − α ≤ 2·MCSE` (`MCSE = sd(per-seed type1)/√20`), ONE-SIDED
UPPER (not anti-conservative). Overall **PASS iff BOTH designs pass.**

The exact per-dataset add-one rule controls type-I at **≤ α by construction** (Phipson & Smyth 2010; the
deterministic add-one CI unit tests already pin the formula), so a PASS is EXPECTED — this is an empirical
confirmation at realistic scale, the complement to the reuse-shortcut NEGATIVE. A FAIL would be a banked
NEGATIVE and a genuine surprise.

## Interpretation (declared in advance)

- **PASS** = the EXACT rule (real-`gwas()` usage: rebuild the null per analysis) controls family-wise type-I at
  α at realistic (n, m) — the empirical leg of doc-18's "realistic-design calibration that controls genome-wide
  type-I error", for the exact rule. Conservative (below α) is the designed behaviour and still a PASS.
- **FAIL** = a banked NEGATIVE (would contradict the construction; investigate nperm / the null). NO relaxation.
- Either way: `validation_status()` count, public-covered fitting = 1, and the threshold row's status are
  unaffected by the OUTCOME. A PASS strengthens the calibration leg to production scale FOR THE EXACT RULE; it
  does NOT by itself reach V5 covered (still owes the R `gwas()`/`marker_scan()` activation — the gating
  cross-lane leg). The reuse-shortcut anti-conservatism remains a documented SIMULATION caveat (the validation
  harness `run_addone_calibration` / `production_cell` reuse one null; real `gwas()` does not).

## Honest scope (declared up front)

- Two realistic design points on ONE LD architecture and the intercept-only null. Not covariate-adjusted GWAS
  (Freedman–Lane / ter Braak), not other LD schemes, not power.
- `nperm=500` per replicate (the add-one floor is 1/501 ≈ 0.002; adequate for α=0.05 decisions). The exact
  rule's ≤ α property is `nperm`-independent (Phipson–Smyth); larger nperm only sharpens power.

## RESULT (run AFTER the predeclaration commit) — **PENDING**

To be filled in by `sim/phase5_qtl_rebuild_production_gate.jl` (Totoro run) after this file is committed.
