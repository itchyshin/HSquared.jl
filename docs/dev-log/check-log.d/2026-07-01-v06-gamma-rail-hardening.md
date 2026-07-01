# 2026-07-01 v0.6 Gamma joint fit — safety-rail hardening

## Goal
Lens: Gauss/Fisher + Rose (real subagent). Close a robustness gap in the `:gamma` JOINT estimator
found while verifying the Phase-3 payload. Extends `V6-GAMMA` (stays `partial`, count 50). Branch
`feat/2026-07-01-v06-gamma-recovery` (#219).

## Supersedes a prior claim
`2026-07-01-v06-gamma-joint-estimation.md` stated *"Gamma is continuous + well identified given
relatedness/replication, so no safety rail is needed (unlike the ordinal threshold)."* That is TRUE
only on identified data. On UNINFORMATIVE data (few subjects, no replication) the Gamma **shape ν** is
weakly identified through a flat large-ν likelihood, and the raw joint optimum can run away
(`ν ≈ 4e5` on a tiny 12-animal fixture). So a rail IS needed — the sibling of the ordinal σ²a guard
(Rose principle: one weakly-identified scalar rail implies the sibling needs it too).

## What was done
- **`src/nongaussian.jl` (`:gamma` case, `7666b656`):** confine both `log σ²a` and `log ν` to
  `init ± 8` (return a `1e12` penalty outside; an estimate at a rail = "not credibly identified at
  this design"), and wrap the marginal in a `try/catch` that returns the same finite penalty on
  `Singular`/`PosDef`/`Domain` errors (all other errors rethrow). Mirrors the ordinal guard.
- **`test/runtests.jl`:** Phase-2 Gamma-fit fixture switched from a 12-animal pedigree to an
  A = I / repeated-records design (q=6 × 4 reps, n=24) so ν is identified; assertion bounded
  (`0 < ν < 1e4`).
- **Status (3 surfaces, lockstep):** `validation_status.jl` V6-GAMMA evidence records the new fixture,
  the rail, AND the passed 48-seed gate; owed field drops the now-done comparator + gate.
  `capability-status.md` + `validation-debt-register.md` matched (Rose-required: `capability-status.md`
  had been missed on the first pass).

## Commands / results
- Informative fixture: σ²a=0.402, ν=28.3 (sane, bounded — no runaway). `payload.variance_components`
  carries `shape` (Phase-3 satisfied by construction).
- **48-seed recovery gate re-run post-rail** (`sim/phase6_gamma_recovery.jl --seeds=48`):
  `gate_pass=true`, 48/48, σ²a bias −0.0033/MCSE 0.0089, ν bias −0.0019/MCSE 0.0434 — **byte-identical**
  to the pre-rail checkpoint → the rail is INERT on identified data (proof it does not relax the gate).
- `Pkg.test()` → PASS (count guard `== 50`). `docs/make.jl` → exit 0.
- **Real `rose-systems-auditor` → PROMOTE-WITH-CHANGES** (3 documentation-lockstep fixes; all applied;
  Rose independently re-ran the gate + suite and verified the rail inert + no overclaim).

## Claim boundary
EXPERIMENTAL, INTERNAL, Laplace-only. `validation_status()` = 50 UNCHANGED; public-covered fitting
= 1 UNCHANGED. NOT a covered claim (covered flip = maintainer G10). The rail changes behavior ONLY on
pathological/uninformative data; it is a robustness guard, not a re-estimation.
