# Pre-declaration — V5 QTL genome-wide threshold CALIBRATION gate, ADD-ONE rule (the #48 gate)

Status: **PRE-DECLARED, to be committed BEFORE the run** (no post-hoc relaxation; 2026-06-14 rule).
This is the **constructive follow-up** to the #202 banked NEGATIVE: there the `(1−α)` empirical-quantile
threshold failed anti-conservative (mean type-I 0.069, 2.42·MCSE). The #202 result named the calibrated path
explicitly — "the package's CONSERVATIVE add-one permutation p-value rule (`genome_wide_pvalue`)". This gate
tests that rule. Same estimand as #202 (**type-I error control**), same DGP and design; only the accept/reject
decision changes.

## Machinery + DGP

`genome_wide_pvalue` (the add-one permutation p-value `(1 + #{null ≥ observed})/(nperm + 1)`) against the same
LD-aware residual-permutation null of per-scan-MAX chi-square that feeds `genome_wide_threshold_from_null`.
Harness: `sim/phase5_qtl_addone_gate.jl` (reuses `_simulate_markers` / `_max_chisq_under_null` from
`sim/phase5_threshold_calibration.jl`; `run_addone_calibration` mirrors `run_threshold_calibration`'s RNG order
exactly, so for a given seed the null distribution and marker panel are **byte-identical** to the #202 quantile
gate — only the decision rule differs).

- **NULL DGP** (no marker signal): n=300 records, m=200 **correlated** markers (LD via shared latent factors +
  an allele-frequency gradient — `_simulate_markers`), intercept-only `X`, σ²e=1.
- Per seed: a residual-permutation null (**nperm=2000**) builds the null distribution of the per-scan max; then
  **type1_reps=1000** INDEPENDENT no-signal scans on the SAME fixed panel each get an add-one genome-wide
  p-value; **reject if p ≤ α**. Empirical type-I = fraction rejected.
- **α = 0.05.**

## Seeds (UNSEEN at declaration)

20 cold-start seeds **20260920 .. 20260939** — disjoint from the #202 quantile-gate seeds (20260900…20260919),
the mini-smoke seeds (20260620…), and the V2/V3 gate seeds. No calibration result is observed before this gate
is fixed.

## PASS criteria (ALL required; fixed here, not adjustable after seeing results)

1. **Completion:** 20/20 seed runs complete.
2. **Level control:** `mean(empirical_type1) − α ≤ 2·MCSE`, where the mean is over the 20 seeds and
   `MCSE = sd(per-seed empirical_type1)/√20`. **ONE-SIDED UPPER** (not anti-conservative).

**Why one-sided here (and not two-sided as in #202).** The add-one rule `(1 + #{null ≥ obs})/(nperm + 1) ≤ α`
is a valid exact permutation test: when the null-distribution draws and the test statistic are exchangeable, it
controls type-I at **≤ α** by construction (Phipson & Smyth 2010). The designed behaviour is therefore type-I
**at or below** α; being conservative (below α) is correct, not a defect. The honest question is only whether
the rule **violates** the level — so the gate is one-sided upper. This is a construction-justified choice fixed
BEFORE the run, not a post-hoc relaxation of the #202 two-sided criterion. (The #202 estimator targeted exact
calibration at α, so two-sided was right there; the add-one estimator targets an upper bound, so one-sided is
right here.)

## Interpretation (declared in advance)

- **PASS** = NO DETECTABLE type-I inflation of the add-one rule at α — a low-power non-rejection, read as
  "consistent with valid level control," NEVER "exactly calibrated." A mean type-I materially below α is an
  expected (conservative) outcome and still a PASS.
- **FAIL** = a banked NEGATIVE, and a genuine SURPRISE: it would mean the residual-permutation null and the
  fresh-phenotype null are NOT exchangeable on this design (the permutation scheme mis-specifies the null), so
  the add-one rule over-rejects despite its construction. The V5 covered claim would NOT proceed and the R
  `gwas()` significance wording stays held. NO relaxation of α, nperm, or the tolerance after the fact.
- Either way: `validation_status()` count, public-covered fitting = 1, and the marker-scan machinery's
  `experimental` status are unaffected by the gate OUTCOME. A PASS discharges the CALIBRATION leg of V5 only;
  V5 covered would STILL owe an external comparator (PLINK `max(T)` / GenABEL) and the R `gwas()`/`marker_scan()`
  activation. Only a PASS + Rose + maintainer G10 would move the threshold row toward covered.

## Honest scope (declared up front)

- This calibrates the **intercept-only null** (residual permutation = permuting `y`); covariate-adjusted GWAS
  needs the exact Freedman–Lane / ter Braak nulls (not in scope — an upgrade path).
- One design point (n=300, m=200, one LD scheme). A covered claim would still owe broader n/m/LD-architecture
  designs and an external comparator. This gate is the type-I-control evidence for ONE decision rule on ONE
  design, not the whole covered close.
- A PASS confirms level CONTROL, not POWER. The add-one rule's power vs. the quantile threshold (and vs. an
  external comparator) is a separate, owed question.

## RESULT (run AFTER the predeclaration commit) — **PENDING**

To be filled in by `sim/phase5_qtl_addone_gate.jl` after this file is committed. Until then this gate has no
result and nothing is promoted.
