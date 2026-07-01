# V4-MV-REML 3-trait recovery gate — PRE-DECLARATION — 2026-06-30

Status: **pre-registration.** Promotes nothing. Declares a recovery gate for the **3-trait**
portion of the `V4-MV-REML` standing debt, committed **before any seed is run** (no post-hoc
relaxation — `2026-06-14-calibration-failure-response`; the covered gate
`2026-06-22-mv-reml-substitutable-gate.md` set the pattern).

`V4-MV-REML` is already **covered** (experimental, validation-scale, opt-in; NOT the public
default). This is **additive evidence** on an owed item; a pass **discharges** the 3+-trait
recovery item (point-estimate, single fixture), leaving covered status, the `validation_status()`
row count (48), and public-covered fitting (1) unchanged.

## Why this is the substantive broader-DGP test

Unlike the full-sib cell (which only raises identifiability), the 3-trait cell **triples the
covariance parameters to estimate**: 12 (6 genetic + 6 residual) vs 6, at the same n = 240. This
is the harder regime — the real test of whether the unstructured REML estimator recovers a larger
covariance structure without detectable bias.

## Run specification (fixed before results)

- **Harness:** `sim/phase4_multivariate_reml_recovery.jl`, **cold-start**, 5000 iters.
- **Design:** half-sib 8 sires × 16 dams × 56 offspring (q = 80), 3 records/animal (n = 240),
  **t = 3**. (Same design/scale as the covered gate; only the trait count changes.)
- **Truth (pre-declared 3×3):**
  - `G0 = [1.0 0.35 0.25; 0.35 0.7 0.2; 0.25 0.2 0.9]`
  - `R0 = [0.8 0.2 0.15; 0.2 0.55 0.1; 0.15 0.1 0.75]`
  - Implied single-record h² ≈ **0.556 / 0.560 / 0.545** (G[i,i]/(G[i,i]+R[i,i])); genetic
    correlations r_g ≈ **0.42 / 0.26 / 0.25** (moderate positive). Both `G0` and `R0` are PD
    (checked in the harness PD guard and the self-test).
- **Replicates:** 48 fresh cold-start seeds, 20260616–20260663.
- **Gate mode:** `--gate=aggregate` (authoritative doc-33 aggregate gate; per-seed Frobenius is
  NOT the gate — for t=3 it trips readily on the loose relative-error thresholds and is ignored).

Reproduce (Totoro or any instantiated checkout):

```sh
SEEDS=$(seq -f "%.0f" 20260616 20260663 | paste -sd, -)
env JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 \
  julia --project=. sim/phase4_multivariate_reml_recovery.jl --cold-start=true \
  --traits=3 --gate=aggregate --seeds="$SEEDS"
```

## Pass criteria (ALL must hold — declared before results)

| # | criterion | required |
| --- | --- | --- |
| 1 | convergence | 48/48 |
| 2 | \|bias\| ≤ 2·MCSE, **all 12** covariance params (6 G upper-triangle + 6 R upper-triangle) | all 12 |
| 3 | per-trait EBV-accuracy mean | ≥ 0.85 (all 3 traits) |
| 4 | MCSE on each **G diagonal** entry (G[1,1], G[2,2], G[3,3]) | ≤ 0.05 |

Criterion 4 is pre-declared **looser** than the 2-trait gate's 0.045 (this is deliberate and
committed before results): 12 params at the same n = 240 spread the information further, so a
slightly higher power floor on the variance estimates is expected. Criterion 2 (bias within
2·MCSE) is the primary recovery test and is applied to all 12 params without relaxation.

## Gating mechanics + reporting pre-commitment (added pre-run; Curie/Fisher/Mendel panel, no seeds run)

- **What the harness enforces:** the `gate_pass`/exit code enforces **criterion 2 only**
  (`|bias| ≤ 2·MCSE`, all 12 params). Criteria 1 (convergence), 3 (EBV floor, all 3 traits), and
  4 (G-diagonal MCSE ceiling) are verified by **reading the printed AGGREGATE / convergence / EBV
  block**. A PASS requires all four confirmed.
- **Authoritative pass signal:** the `aggregate_within_2mcse=` (equivalently `gate_pass=`) field
  on the final `GATE` line — **NOT** the process exit code. For t=3 the per-seed Frobenius gate
  trips readily on the loose relative-error thresholds and is *ignored*; exit 1 does not mean the
  aggregate gate failed. Ingest the `GATE`-line field, not the exit code.
- **Reporting pre-commitment:** a PASS is reported with the realized `bias`, `MCSE`, and
  standardized residual `|bias|/MCSE` for **all 12** parameters (criterion 4 gates the 3
  G-diagonals only, but the realized MCSE of every param is reported so an inflated off-diagonal
  MCSE is visible), plus an explicit detectability statement — "no bias larger than ≈2×(realized
  MCSE) is detectable at this design." A reporting commitment, not a threshold change.

## Outcome semantics (declared before results)

- **PASS** → the 3+-trait recovery item is **discharged** (point-estimate, single fixture,
  pre-declared 48-seed gate); removed from the still-owed list; covered status unchanged.
- **FAIL** → recorded as a **characterized boundary** with its failure mode (the W1 `size_med`
  precedent — e.g. a specific variance or covariance that does not separate at n = 240); item
  stays owed/scoped; covered status unchanged. No relaxation of these criteria.

## Honesty pins

`validation_status()` = 48 rows UNCHANGED; public-covered fitting = 1 UNCHANGED; no `src/` change
(the estimator's Kronecker MME is already `t`-general); no API/default/R-wording change; no
"unbiased" wording (a pass = "no detectable bias at this design/power"). Real **Rose** audit +
maintainer G10 sign-off required before the debt-clause wording lands.
