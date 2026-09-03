# 2026-09-03 — 0.8 S1 FA diagnose predeclaration (design-42)

**Status: PREDECLARED · NOT RUN as a recovery campaign · NOT a covered flip.**  
Lane: `cursor/08-fa-20260903` (WT `~/local-scratch/lanes/HSquared.jl-08-fa-20260903`).  
Owner: 0.8 G0 YES · auto-flip #6 only after design-41 §3 + Rose CLEAN.

## What this is

The discriminating test in `docs/design/42-fa-calibration-diagnosis.md`:
per-seed fitted REML loglik vs loglik at TRUE `(G, R)`, jointly with
`min(ψ̂)` and `cond(Ĝ)`, on the **already-banked** Phase 4B FA seeds.

This is **S1 diagnose**, not S2 prereg of a new recovery gate, not S3 engine
fix, not S4 campaign. `V4-FA` stays **partial / experimental**.

## Locked fixture

Reuse `sim/phase4b_structured_covariance_recovery.jl` DGP:

- 6 sires / 12 dams / 42 offspring / 3 records (`q=60`, `n=180`)
- `t=3`, `K=1` (Ledermann-saturated: `(t−K)² − (t+K) = 0`)
- `Λ = [0.9, 0.55, −0.35]'`, `ψ = [0.35, 0.45, 0.55]`, same `R`
- near-oracle start `(0.7·Λ, 1.3·ψ, 1.2·R)` — already refutes EM warm-start
- thresholds remain the banked `rel_g ≤ 0.45`, `rel_r ≤ 0.25`

Banked FA fails: `20260616` (G), `20260619` (G+R).  
Contrast pass: `20260614`. Full panel: `20260614..20260623`.

## Classification (frozen before any fit cell)

| class | rule |
|---|---|
| `ok_recovery` | converged AND `rel_g ≤ 0.45` AND `rel_r ≤ 0.25` |
| `heywood_boundary` | `ℓ_fit − ℓ_truth ≥ −1e-6` AND `min(ψ̂) < 1e-4` |
| `optimizer_miss` | `ℓ_fit − ℓ_truth < −1e-6` |
| `sampling_vs_threshold` | `Δℓ ≥ −1e-6` AND `min(ψ̂) ≥ 1e-4` AND failed G/R AND `max(rel_g/0.45, rel_r/0.25) ≤ 1.5` |
| `unclassified` | else |

`heywood_flag` is always emitted independently. Driver:
`sim/v08_fa_s1_diagnose.jl`.

## Compute

- `--mode=truth-only` may run on a laptop (no fit).
- `--mode=fit` is **Totoro-first**, 1 thread / 1 BLAS thread.
- Do **not** launch a multi-start / DRAC campaign from this note.

## Explicit non-claims

- No `V4-FA` / factor-analytic G covered flip.
- No `cov = fa(K)` Boole freeze.
- No loadings-with-SE public claim.
- No WOMBAT parity (tool not installed).
- No 0.8.0 version bump, no count 7→8, no 1.0 / CRAN.

## After S1

Only then: S2 prereg SHA → S3 engine fix (Heywood bound / Ledermann guard /
justified threshold — not blind EM warm-start) → S4 recovery under locked gate.
If `fa` resists and `lowrank` passes, ship low-rank and hold `fa` partial
(design-36 §3.4).
