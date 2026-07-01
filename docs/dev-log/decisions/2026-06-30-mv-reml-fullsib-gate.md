# V4-MV-REML full-sib design recovery gate — PRE-DECLARATION — 2026-06-30

Status: **pre-registration.** Promotes nothing. This declares a recovery gate for the
**full-sib design** portion of the `V4-MV-REML` standing debt, committed **before any seed is
run** so there can be no post-hoc relaxation (the `2026-06-14-calibration-failure-response`
decision forbids it; the covered gate `2026-06-22-mv-reml-substitutable-gate.md` set the pattern).

`V4-MV-REML` is already **covered** (experimental, validation-scale, opt-in; NOT the public
default). This gate is **additive evidence** on an owed standing-debt item — a pass **discharges**
the full-sib item (point-estimate, single fixture); it does not change covered status, the
`validation_status()` row count (48), or the public-covered fitting count (1).

## Scope — what changes vs the covered gate

Exactly one variable changes: the **pedigree design**, half-sib → full-sib. Everything else
(truth, n, records, seeds, criteria) is held at the covered-gate values, so a pass isolates
"recovery holds under full-sib relatedness" and a fail isolates a design boundary.

**HONEST CAVEAT (must survive into the evidence + the debt clause):** full-sib is the *easier*
identifiability regime — both parents known, offspring within a family share `A = 0.5` (vs
half-sib paternal-only `0.25`), so the additive signal is better separated from residual. A pass
therefore **closes the literal design owed item but is NOT a stress test**. The substantive
broader-DGP test is the 3-trait cell (`2026-06-30-mv-reml-3trait-gate.md`).

## Run specification (fixed before results)

- **Harness:** `sim/phase4_multivariate_reml_recovery.jl`, **cold-start** (fitter's
  phenotypic-scale default init — tests whether the optimizer finds the basin unaided), 5000 iters.
- **Design:** full-sib, `npair = 20` pairs × `noffspring_per_pair = 2` → 40 parents + 40
  offspring = q = 80; 3 records/animal → n = 240; t = 2. (Same q/n as the covered half-sib
  gate.)
- **Truth:** `G = [1.0 0.35; 0.35 0.7]`, `R = [0.8 0.2; 0.2 0.55]` (identical to the covered gate).
- **Replicates:** 48 fresh cold-start seeds, 20260616–20260663.
- **Gate mode:** `--gate=aggregate` (the authoritative doc-33 aggregate gate; the per-seed
  Frobenius pass is NOT the gate — it measures per-replicate `G` sampling variance).

Reproduce (Totoro or any instantiated checkout):

```sh
SEEDS=$(seq -f "%.0f" 20260616 20260663 | paste -sd, -)
env JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 \
  julia --project=. sim/phase4_multivariate_reml_recovery.jl --cold-start=true \
  --design=fullsib --npair=20 --noffspring-per-pair=2 --gate=aggregate --seeds="$SEEDS"
```

## Pass criteria (ALL must hold — declared before results)

| # | criterion | required |
| --- | --- | --- |
| 1 | convergence | 48/48 |
| 2 | \|bias\| ≤ 2·MCSE, all 6 covariance params (G[1,1], G[1,2], G[2,2], R[1,1], R[1,2], R[2,2]) | all 6 |
| 3 | per-trait EBV-accuracy mean | ≥ 0.85 (both traits) |
| 4 | MCSE on each G entry | ≤ 0.045 |

These mirror the covered half-sib gate exactly. Because full-sib is the easier regime, recovery
is *expected* to pass at least as well as half-sib; a pass is confirmatory, not a stress result.

## Outcome semantics (declared before results)

- **PASS** → the full-sib design recovery item is **discharged** (point-estimate, single fixture,
  pre-declared 48-seed gate), removed from the still-owed list; covered status unchanged.
- **FAIL** → recorded as a **characterized boundary** with its failure mode (the W1 `size_med`
  precedent); item stays owed/scoped; covered status unchanged. No relaxation of these criteria.

## Honesty pins

`validation_status()` = 48 rows UNCHANGED; public-covered fitting = 1 UNCHANGED; no `src/` change
(the estimator is already `t`- and design-general); no API/default/R-wording change; no "unbiased"
wording (read a pass as "no detectable bias at this design/power"). Real **Rose** audit + maintainer
G10 sign-off required before the debt-clause wording lands.
