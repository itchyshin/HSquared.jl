# Proposal — discharge the larger-n / broader-DGP portion of the V4-MV-REML standing debt

Status: **Rose-audited 2026-06-29 (verdict: revise-before-applying → revised below; fences CLEAN).** Does
NOT change covered status (V4-MV-REML is already `covered`, experimental/validation-scale/opt-in). A modest,
additive-evidence + honest-caveat update to the row's standing-debt list — **"characterized (partial)", not
"discharged"** (Rose). No `validation_status()` count change; public-covered stays 1. Apply on maintainer nod.

## The standing debt (current V4-MV-REML row)

> Standing debt (covered does NOT retire it): (1) an executed 2nd same-estimand comparator
> (ASReml/BLUPF90/DMU/WOMBAT; MCMCglmm/JWAS are Bayesian agreement only); (2) the full-unstructured
> `sommer` leg as a skip-guarded in-suite test; (3) **broader recovery (full-sib/larger-n/3+ traits)**;
> (4) the deep-inbreeding boundary.

## W1 evidence (this branch, committed)

- **Campaign 2 broader-DGP factorial** (`46235637`, 8 cells × 50 cold-start seeds, 50/50 converged;
  `2026-06-29-w1-c2-v4-broaderdgp-{results.txt,summary.md}`): r_g ∈ {0.10, 0.42, 0.70} × records ∈ {1,3}
  × an asymmetric-h² cell × a larger design. **R9 clean** (`base_inside` reproduces the covered scope).
  5/8 pass; the failures are explained (below), not breakdowns.
- **σ²a bias-vs-n sweep** (`46237216`; `2026-06-29-w1-sigma_a2-bias-vs-n.md`): G[1,1] bias
  −9.7%(q=80) → −6.9%(q=160) → −3.5%(q=400) → **−1.0%(q=800)**, monotone; all converge in ~240–360
  iters; 20000 iters gives the same bias. → the σ²a underestimate is a **small-sample REML bias that
  vanishes with n**, not a defect, not a convergence artifact. This confirms + quantifies the existing
  row caveat ("G[1,1] −5.7%/1.57·MCSE, REML finite-sample").

## What this discharges vs leaves owed (debt #3 "broader recovery")

| sub-part of debt #3 | status after W1 (Rose-corrected) |
| --- | --- |
| **larger-n recovery** | **characterized (partial)** — σ²a bias quantified vanishing to −1% at q=800; but the only enlarged-design factorial cell (`size_med`, q≈112) still *fails* its gate on G[1,1] → larger-n is where a boundary appeared, not where the debt closed |
| **broader-DGP** (r_g, h²-balance, records) | **characterized (partial)** — the half-sib / 2-trait C2 factorial: **5/8 cells pass, 3/8 map honest boundaries** (incl. single-record × extreme-r_g) |
| full-sib design | still owed (C2 was half-sib) |
| 3+ traits | still owed (C2 was 2-trait) |
| debts #1 (2nd same-estimand comparator), #2 (in-suite `sommer`), #4 (deep-inbreeding) | unchanged — still owed |

## Proposed register append (to the V4-MV-REML standing-debt clause)

> "Broader-DGP + larger-n recovery is now **characterized (partial)** (W1, `2026-06-29-w1-c2-*` +
> `...-sigma_a2-bias-vs-n.md`): an 8-cell × **50**-seed cold-start factorial over r_g/h²-balance/records
> (half-sib, 2-trait; **50/50 converged each cell**; **5/8 pass**, R9-clean on `base_inside` → no
> covered-claim regression), and a single-DGP q=80→800 sweep (30 seeds; 20 at q=800) showing the
> additive-variance downward bias decays monotonically with n (≈−9.7%→−1.0%; the small-q level is itself
> MCSE-noisy — q≈80 G[1,1] bias ranges −4.7%/−5.7%/−9.7% across the 50/48/30-seed runs, so the **monotone
> decay** is the robust signal, not the precise small-q level), iteration-stable **at q=400** (it=5000 vs
> 20000 agree; the large-bias q=80/160 cells were not re-run at high iters, so 'not a tolerance artifact'
> is established at moderate-n and inferred at small-n via the clean decay + fast ~240–360-iter
> convergence). Two characterized boundaries: the **n-vanishing σ²a bias** (becomes MCSE-detectable at
> larger n, e.g. `size_med`), and a **single-record × extreme-r_g identifiability limit** (per-seed pass
> ~2%, EBV ~0.74 — a genuine scope limit, not a bug; `records_1` at base r_g still passes). STILL OWED:
> full-sib + 3+-trait recovery, the 2nd same-estimand REML comparator, the in-suite `sommer` test, the
> deep-inbreeding boundary."

## Fences

- V4-MV-REML stays `covered` (no status change); this is additive evidence + an honest new caveat on an
  already-covered, validation-scale, opt-in row — NOT a new covered flip, NOT a public-default change.
- The 2nd same-estimand comparator (BLUPF90/ASReml) remains owed — Bayesian agreement never substitutes.
- Apply only after a real **Rose** audit (this proposal) + maintainer nod. `V1-HERIT-TCAL` stays planned.
