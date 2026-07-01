# V4-MV-REML full-sib design recovery — 48-seed cold-start — 2026-06-30

Executes the recovery gate **pre-registered** in
`docs/dev-log/decisions/2026-06-30-mv-reml-fullsib-gate.md` (committed `0a39e93a`, with the
Curie/Fisher/Mendel pre-run panel amendments in `4f3fcde6` — both **before** this run). Additive
evidence on the already-covered `V4-MV-REML` row; discharges the **full-sib design recovery**
standing-debt item. Covered status, `validation_status()` = 48, and public-covered fitting = 1 are
UNCHANGED.

## Run

- Harness: `sim/phase4_multivariate_reml_recovery.jl`, **cold-start**, 5000 iters. Run on **Totoro**
  (branch `feat/2026-06-30-v04-broaderdgp-recovery`, verified `HEAD = 4f3fcde`; BLAS/threads pinned
  to 1). Raw log: `2026-06-30-mv-fullsib-results.txt` (48 seeds, one START, one GATE).
- Design (confirmed on the `CELL` line): `fullsib npair=20 noffspring_per_pair=2` → 40 parents +
  40 offspring, q = 80; 3 records/animal, n = 240; t = 2. Truth `G = [1 .35; .35 .7]`,
  `R = [.8 .2; .2 .55]` (identical to the covered gate — design is the only changed variable).
- 48 fresh cold-start seeds 20260616–20260663.

Reproduce:

    SEEDS=$(seq -f "%.0f" 20260616 20260663 | paste -sd, -)
    env JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 \
      julia --project=. sim/phase4_multivariate_reml_recovery.jl --cold-start=true \
      --design=fullsib --npair=20 --noffspring-per-pair=2 --gate=aggregate --seeds="$SEEDS"

(Provenance note: an earlier run misfired — a stale pre-existing Totoro clone was not switched to
this branch, so unknown `--design`/`--traits` flags were ignored and it silently reran the default
half-sib/t=2 cell; caught at ingestion via the `HEAD=` echo + impossible-identical results, no
evidence written. The run above was re-executed on the verified `HEAD = 4f3fcde` with a hard
branch/harness guard and a `CELL`-header design check.)

## Result — aggregate Monte Carlo recovery (m = 48)

| param | true | mean | bias | MCSE | \|bias\|/MCSE | \|bias\| ≤ 2·MCSE |
| --- | --- | --- | --- | --- | --- | --- |
| G[1,1] | 1.0000 | 0.9666 | −0.0334 | 0.0319 | 1.05 | yes |
| G[1,2] | 0.3500 | 0.3529 | +0.0029 | 0.0232 | 0.13 | yes |
| G[2,2] | 0.7000 | 0.7075 | +0.0075 | 0.0193 | 0.39 | yes |
| R[1,1] | 0.8000 | 0.7816 | −0.0184 | 0.0133 | 1.38 | yes |
| R[1,2] | 0.2000 | 0.2011 | +0.0011 | 0.0065 | 0.17 | yes |
| R[2,2] | 0.5500 | 0.5405 | −0.0095 | 0.0085 | 1.12 | yes |

- EBV accuracy: trait 1 mean 0.8975 (sd 0.0231), trait 2 mean 0.9029 (sd 0.0263).
- Convergence: 48/48. Per-seed Frobenius gate (NOT the gate): 24/48 = 0.500 — as expected, per-
  replicate `G` sampling variance, not a defect; the harness exits 1 on it (`gate_pass=true` is the
  authoritative aggregate signal on the GATE line).

## Verdict against the pre-declared gate

| # | criterion | required | observed | pass |
| --- | --- | --- | --- | --- |
| 1 | convergence | 48/48 | 48/48 | ✅ |
| 2 | \|bias\| ≤ 2·MCSE, all 6 | all | all 6 yes | ✅ |
| 3 | per-trait EBV mean | ≥ 0.85 | 0.898 / 0.903 | ✅ |
| 4 | MCSE each G entry | ≤ 0.045 | 0.032 / 0.023 / 0.019 | ✅ |

**The pre-declared full-sib recovery gate PASSES on all four criteria** (`GATE …
aggregate_within_2mcse=true gate_pass=true seeds=48`). → the **full-sib design recovery** owed item
is **DISCHARGED** (point-estimate, single fixture, pre-declared 48-seed gate).

## Detectability + honest caveats (must survive into the debt clause)

- **Detectability (Amendment B):** the largest standardized residual is R[1,1] at 1.38·MCSE and
  G[1,1] at 1.05·MCSE. With G-entry MCSE ≈ 0.019–0.032, **no genetic-variance bias larger than
  ≈2×0.032 ≈ 0.064 (≈6.4%) is detectable at this design/power.** Read a pass as "**no detectable
  bias**", never "unbiased."
- **Full-sib is the EASIER regime** (both parents known, within-family `A = 0.5` vs half-sib 0.25).
  This pass **closes the literal full-sib design owed item but is confirmatory, not a stress test.**
  Consistent with that, G[1,1] recovers at 1.05·MCSE here vs 1.57·MCSE in the half-sib covered gate
  — i.e. the easier design recovers the genetic variance *slightly better*, exactly as expected.
- **R9 covered-regression check:** the full-sib cell reuses the covered truth; all 6 covered params
  pass within 2·MCSE, so the covered scope is not regressed (if anything G[1,1] is cleaner). R9-clean.

## Honesty pins

`validation_status()` = 48 UNCHANGED; public-covered fitting = 1 UNCHANGED; no `src/` change; no
API/default/R-wording change. Real **Rose** audit + maintainer G10 sign-off required before the
debt-clause wording lands.
