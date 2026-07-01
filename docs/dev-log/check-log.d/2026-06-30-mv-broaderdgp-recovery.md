# 2026-06-30 V4-MV-REML broader-DGP recovery — full-sib + 3-trait gates (v0.4)

## Goal

Lens: Curie/Fisher/Mrode (validation) + Mendel (full-sib construction) + Rose (mandatory). Discharge
the two still-owed *pure-Julia* recovery items on the already-covered `V4-MV-REML` row — **full-sib
design recovery** and **3+-trait recovery** — each via a pre-declared, committed 48-seed gate.
Additive evidence; covered status, `validation_status()` = 48, and public-covered fitting = 1 stay
UNCHANGED. Plan: `~/.claude/plans/plan-the-arc-concurrent-mccarthy.md`.

## What was done

- **Harness** (`sim/phase4_multivariate_reml_recovery.jl`): added `_fullsib_pedigree` (npair distinct
  sire×dam pairs, both parents known); a `PROGRAM_FILE` guard so the harness is `include`-able;
  `--design=fullsib` (default `halfsib`, byte-identical numerics); general-`t` via `t = size(g0, 1)`
  and `_covariance_params(t)` (t(t+1)/2 upper-triangle G+R, closure-capture-safe); `--traits=3` with a
  pre-declared 3×3 truth; a design-/t-aware `CELL` header (the old 2×2 print would truncate at t=3).
- **Self-test** (`sim/selftest_phase4_extensions.jl`, RNG-free, outside the package suite): full-sib
  q=80 + PD `A`; `--design` back-compat; t read from G0; t=2 param names/order unchanged; t=3 = 12
  params; closure-capture correctness; 3×3 PD truth; t=2 default byte-identical.
- **Pre-declarations** (committed BEFORE the run): `docs/dev-log/decisions/2026-06-30-mv-reml-fullsib-gate.md`
  (`0a39e93a`), `…-3trait-gate.md` (`4f3fcde6`), + panel amendments (`4f3fcde6`).
- **Pre-run lens panel** (real subagents Curie/Fisher/Mendel — all PROCEED): gates non-vacuous,
  estimand↔estimator matched, MCSE arithmetic correct, full-sib generator genetically sound
  (A=0.5 within family, F=0, d_i=0.5). Two procedure amendments applied pre-run (exit-code≠gate;
  report realized bias/MCSE per param + detectability statement).
- **Run** (Totoro, verified `HEAD=4f3fcde`, BLAS-pinned, 48 cold-start seeds/cell). Evidence:
  `docs/dev-log/recovery-checkpoints/2026-06-30-mv-{fullsib,3trait}-{48seed.md,results.txt}`.
- **Lockstep debt update**: `validation-debt-register.md` + `capability-status.md` V4-MV-REML rows —
  full-sib + 3-trait DISCHARGED (point-estimate, single fixture); `sommer`-in-suite + deep-inbreeding
  remain owed.

## Commands / results

- `julia --project=. sim/selftest_phase4_extensions.jl` → **SELFTEST PASSED** (at every TDD step).
- Full-sib (t=2): `GATE … aggregate_within_2mcse=true gate_pass=true seeds=48` — 48/48 converged,
  all 6 `|bias|≤2·MCSE`, EBV 0.898/0.903, G-entry MCSE ≤0.032. R9-clean (G[1,1] 1.05·MCSE vs
  half-sib covered 1.57·MCSE).
- 3-trait (t=3): `GATE … aggregate_within_2mcse=true gate_pass=true seeds=48` — 48/48 converged,
  all 12 `|bias|≤2·MCSE`, EBV 0.893/0.903/0.899, G-diagonal MCSE ≤0.036, no off-diagonal inflation.
- `julia --project=. -e 'using Pkg; Pkg.test()'` → PASS incl. `test/runtests.jl` `length(validation)
  == 48` (no `src/` change; suite unaffected).
- Provenance: a first run misfired on a stale Totoro clone (wrong branch → flags ignored → default
  rerun); caught at ingestion via `HEAD=` echo + identical results; discarded, re-run on guarded HEAD.

## Claim boundary

Additive evidence only. `validation_status()` = 48 UNCHANGED; public-covered fitting = 1 UNCHANGED;
no `src/`, API, default, or R-wording change. Both discharges are point-estimate / single-fixture /
pre-declared-48-seed-gate. Full-sib is the EASIER regime (confirmatory, not a stress test); 3-trait
is the substantive 12-parameter cell. "No detectable bias" (~6–7% floor), never "unbiased". STILL
OWED: the in-suite `sommer` test (needs live R), the deep-inbreeding boundary. Real Rose audit +
maintainer G10 sign-off required before merge.
