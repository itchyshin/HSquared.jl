# 2026-09-03 — 0.8 S2 FA recovery-gate prereg (SHA-locked)

**Status: FROZEN · NOT RUN as a recovery campaign · NOT a covered flip.**  
Lane: `cursor/08-fa-20260903` (WT `~/local-scratch/lanes/HSquared.jl-08-fa-20260903`).  
Owner: 0.8 G0 YES · auto-flip #6 only after design-41 §3 + Rose CLEAN.  
S1 classify is closed: Totoro d3-panel 8/10 `ok_recovery`, 2 `heywood_boundary`,
0 `optimizer_miss`; `heywood_flag` on 7/10; design-42 start-sensitivity REFUTED.

Driver: `sim/v08_fa_s2_prereg.jl`  
Driver SHA-256: `47a1b619e83b468cec28dae57918f755064a32528f16bf775943b8b7e36b4b83`  
Driver git blob: `370cf69773a52dc7e158a9415d389e31ddf7a8e7`  
**Freeze commit: `eff57e3d`** (`eff57e3dff381dfb94315bde7ef762b09dbb6640`).
That commit introduced this file and the driver together. Do not edit the
driver after freeze; a new prereg is a new commit. This stamp does not
change gate text.

`public_covered_count` stays **7**. `V4-FA` stays **partial / experimental**.
No 0.8.0. No 1.0 / CRAN. Rose CLEAN is **not** written.

## Why S1 cannot be the covered-flip gate

S1 reused the Phase 4B DGP (`t=3`, `K=1`) and the old G/R-only pass rule
(`converged` AND `rel_g ≤ 0.45` AND `rel_r ≤ 0.25`). That rule **accepts
collapsed uniqueness**. On the banked panel:

| class | n/10 | note |
|---|---|---|
| `ok_recovery` (old G/R gates) | 8 | 5 of these still have `heywood_flag=true` |
| `heywood_boundary` | 2 | seeds `20260616`, `20260619` |
| `optimizer_miss` | 0 | every seed has `ℓ_fit > ℓ_truth` |

`ledermann_slack = (t−K)² − (t+K) = 0` on all ten. Uniqueness collapse is the
typical optimum at Ledermann saturation, not a fail-seed-only event. A
covered-flip gate that keeps those G/R cuts and that DGP would promote a
Heywood-typical fitter.

## Frozen DGP (gate cell)

**Chosen: `t=4`, `K=1` (`--cell=d4-k1`).**

| quantity | value | why |
|---|---|---|
| pedigree / records | 6 sires / 12 dams / 42 offspring / 3 records (`q=60`, `n=180`) | same as Phase 4B / S1 |
| `t`, `K` | 4, 1 | smallest `t` step that keeps `K=1` and gives slack `> 0` |
| `ledermann_slack` | `(4−1)² − (4+1) = 4` | driver asserts exactly 4 |
| `Λ` | `[0.9, 0.55, −0.35, 0.40]'` | first three copy S1; fourth moderate |
| `ψ` | `[0.35, 0.45, 0.55, 0.50]` | all interior |
| `R` | 4×4 PD embedding the S1 3×3 block; `R[4,4]=0.70`; off-block `0.06, 0.04, 0.03` | driver asserts PD |
| start | `(0.7·Λ, 1.3·ψ, 1.2·R)` | same near-oracle family as S1 |

**Rejected for this gate: `t=5`, `K=2`** (`slack = (5−2)² − (5+2) = 2`).
Positive slack, but it changes rank at the same time as identifiability.
S1's failure was uniqueness collapse at `K=1` saturation. S2 isolates that
one change. `t=5 K=2` may be a later diagnostic cell, not this SHA.

**Not the gate:** `--cell=d3-diagnostic` keeps the S1 `t=3 K=1` fixture as a
Heywood disclosure cell. A seed on that cell can never be `ok_recovery`
under this prereg (`slack = 0`).

## Frozen pass criterion (one seed)

A seed is `ok_recovery` only if **all** hold:

1. `converged`
2. `rel_g ≤ 0.45` (banked G cut; not retuned here)
3. `rel_r ≤ 0.25` (banked R cut; not retuned here)
4. **`min(ψ̂) ≥ 1e-4`** (uniqueness interior; S1 Heywood cut, now first-class)
5. cell `ledermann_slack > 0`

Rotation-invariant functionals only (`G`, `R`, `ψ`). Loadings are not a
pass object (2026-06-19 rotation convention).

The driver also emits `old_gr_ok` and, when the old G/R gates would have
passed a Heywood seed, class `heywood_accepted_by_old_gr`. That class exists
so S4 cannot hide the S1 lesson.

## Frozen S4 seed list (not run)

`20260914` … `20260923` (10 seeds). New block: **not** the Phase 4B panel
and **not** comparable to S1 tables. Same RNG integers on a different DGP
would also be incomparable; a new block makes that obvious.

S4 pass bar, if and when Ada launches it after S3: **8/10** `ok_recovery`
under **this** definition. Same n as the old banked bar, strictly harder
because uniqueness must stay interior. Do not relax after seeing output.

## S3 gate condition (engine change; do not run a campaign from this note)

S3 is a **fitter change**, not a multi-seed run:

- implement a uniqueness-interior bound so fitted `min(ψ) ≥ 1e-4` (or a
  documented equivalent constraint), **and/or**
- refuse Ledermann-saturated FA (`slack ≤ 0`) as a covered-flip cell.

**Not S3:** EM warm-start, DRAC arrays, retuning `rel_g`/`rel_r`, or editing
this frozen script. If `fa` still fails this SHA after the bound, ship
`:lowrank` and hold `:factor_analytic` partial (design-36 §3.4).

S4 may run `sim/v08_fa_s2_prereg.jl --cell=d4-k1 --mode=fit` only after S3
lands, on Totoro first, 1 thread / 1 BLAS thread.

## Comparators (still S0b)

WOMBAT is not installed (laptop or Totoro). Any later covered flip still
needs WOMBAT or an explicit recovery-substitution disclosure (design-16
G11). AGHmatrix single-step is a different lane (`cursor/08-ss-20260903`).

## Explicit non-claims

- No `V4-FA` / factor-analytic G covered flip.
- No `cov = fa(K)` Boole freeze.
- No loadings-with-SE public claim.
- No WOMBAT parity.
- No 0.8.0 version bump, no count 7→8, no 1.0 / CRAN.
- No Rose CLEAN (not requested, not written, not forged).
