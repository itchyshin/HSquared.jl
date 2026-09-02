# 2026-09-02 — A25a: cite banked C8 broader-DGP confirm on claim surfaces

**Arc:** A25a (compute-free register reconcile; follow-up to A28 inventory).
**Lane:** Julia engine (`HSquared.jl`).
**Worktree:** `~/local-scratch/lanes/HSquared.jl-h2-twin-20260901`
**Branch:** `claude/lane-h2-twin-20260901`. **Not pushed.**

## Problem

The C8 multivariate broader-DGP confirm (DRAC `fir` job `47925486`) was banked in
`docs/dev-log/recovery-checkpoints/2026-07-12-coverage-recovery-evidence-reconciliation.md`
but absent from `docs/design/capability-status.md`,
`docs/design/validation-debt-register.md`, and the live `validation_status()`
`V4-MV-REML` row — all still cited only the earlier W1 triage (8×50, **5/8**).

## Verified numbers (from banked checkpoints; no re-run)

| Field | Value |
|---|---|
| Job | `47925486` (16/16 array tasks `COMPLETED`, exit `0:0`) |
| Design | 16 cells × 500 seeds |
| Convergence | **500/500** every cell |
| Gate | **14/16 pass** |
| Failures | only `rg_090_rec1`, `rg_095_rec1` (preregistered single-record × r_g ≥ 0.90) |
| Covered-scope control | `base_inside` PASSES (no R9 regression) |
| Driver | `sim/phase4_v5_mv_recovery_reseed.jl` |

## Changes

- `docs/design/capability-status.md` — Multivariate REML scope edge now cites C8
  alongside W1; status remains **covered**; `public_covered_count` stays **5**.
- `docs/design/validation-debt-register.md` — `V4-MV-REML` W1 paragraph augmented
  with C8 confirm; characterization only; no status move.
- `src/validation_status.jl` — `V4-MV-REML` `missing` / `claim_boundary` cite C8;
  note full-sib/3-trait already discharged; flag R MV-1 `skip_if_not_installed`
  silent-skip risk.

## Commands and outcomes

| Command | Result |
|---|---|
| `julia --project=. -e 'using HSquared; …'` | loads; `V4-MV-REML.status == "covered"`; claim text contains `14/16` and `47925486` |

## Fence

- No covered flip; no Totoro/DRAC re-run; no push; no G10; no Registrator.
- `public_covered_count` remains **5**.
