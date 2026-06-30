# After-task — V2-GREML genomic REML promoted partial → covered (validation-scale) (2026-06-30)

The 24-hour goal's headline: genomic REML variance-component estimation (`fit_gblup_reml`) cleared the
doc-16 G11 covered bar on two independent legs and was promoted `partial → covered` at validation scale.
Claude solo, baton held. Branch `feat/2026-06-30-v2-genomic-recovery-gate`, PR pending (staged for G10,
NOT self-merged). **Public-covered FITTING surface stays 1 (v0.1 Gaussian).**

## Live phase snapshot

- **As of 2026-06-30 (V2-GREML genomic REML → covered; branch `feat/2026-06-30-v2-genomic-recovery-gate`, PR pending for G10; `main` @ `6acd451c`/#200).**
  The genomic REML estimator cleared G11 on BOTH owed legs: a PRE-DECLARED bias/MCSE recovery gate
  (`sim/phase2_genomic_reml_recovery.jl`; predeclaration committed `cb22e679` BEFORE the run; 48/48 seeds,
  `|bias| ≤ 2·MCSE` on σ²g/σ²e/h² — no detectable bias) + the executed `blupf90+` 2.60 same-estimand
  comparator (PR #200). Real Rose audit → PROMOTE (both legs verified independently incl. the
  predeclaration-before-result commit ordering + a harness re-run). Atomic flip across all 3 surfaces
  (`validation_status()` 6→7 covered, capability-status, debt-register). `validation_status()` = 48 rows
  UNCHANGED; public-covered FITTING = 1. Validation-scale / opt-in; covers the supplied-`Ginv` REML
  ESTIMATOR only (G-construction `V2-GRM` stays experimental; no production sparse-`G`; no R surface).
  **NEXT: v0.5 (QTL null-DGP thresholds) or v0.4 (broader-DGP MV).** START HERE: this report.

## What changed

- NEW `sim/phase2_genomic_reml_recovery.jl` (the gate harness) + `...-v2-genomic-recovery-gate-predeclaration.md`
  (predeclaration + PASS result) — committed `cb22e679` (predeclaration) → `6f4cbe06` (result).
- Atomic promotion flip: `src/validation_status.jl` (V2-GREML status + evidence + scope-of-validity),
  `docs/design/capability-status.md`, `docs/design/validation-debt-register.md`.

## Checks run and exact outcomes

- Gate: `JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 julia sim/phase2_genomic_reml_recovery.jl` → 48/48
  converged, GATE PASS (σ²g 0.5908/0.41·MCSE, σ²e 0.4061/0.32·MCSE, h² 0.5902/0.50·MCSE).
- `Pkg.test()` (post-flip) → **"Testing HSquared tests passed"** (exit 0); `validation_status()` = 48 rows
  (covered 6→7, partial 38→37); count-guard (`length==48`) + status-set guard green.
- Documenter: unaffected (no `docs/src/` change).

## Public claim audit (Rose)

Real `rose-systems-auditor` audit → **PROMOTE** (covered-READY confirmed). Verified INDEPENDENTLY: the
predeclaration genuinely precedes the result (commit timestamps `cb22e679` 08:03:53 → `6f4cbe06` 08:06:13;
PENDING at declaration; harness byte-identical across commits → no post-hoc relaxation); the RESULT table
reproduces exactly (Rose re-ran the harness); both legs are genuine, independent, same-estimand REML; no
overclaim (public FITTING surface stays 1; G-construction not implied; `V2-GRM` stays experimental); the
count-guard survives a status-field flip. The atomic flip + merge is the maintainer's non-delegable G10.

## Tests of the tests

The gate is a genuine pre-registration: criteria fixed in the committed predeclaration before any seed was
run, no relaxation. The two G11 legs are deliberately NON-coincident fixtures (gate: 48 fresh-G seeds;
comparator: single fixed-G fixture) — methodologically stronger than sharing one fixture (gate proves
recovery across genomic structures; comparator proves estimator agreement on a fixed G).

## Coordination notes

Claude solo, baton held. No R files touched; no R-facing surface change. A covered genomic engine model does
NOT activate the R `genomic()` path (still reserved) — that is the v0.9 bridge work.

## Known limitations (covered does NOT retire these)

- SCOPE: supplied-`Ginv` REML ESTIMATOR, exact-model recovery, N=300 single design point. Owed: a
  `sommer`/`rrBLUP` 2nd same-estimand REML leg; broader N/M/h² recovery designs; deep-relatedness/boundary
  fixtures; the VanRaden G-construction comparator (`V2-GRM`: AGHmatrix/sommer); production sparse-`G`.
- NOT the public default, NOT production sparse fitting, NO R model-spec.

## Next actions

1. Maintainer **G10** sign-off on this PR (the atomic covered flip).
2. v0.5: calibrated genome-wide thresholds (null-DGP sims) + `marker_scan()` activation; or v0.4 broader-DGP
   MV recovery + the in-suite `sommer` test.
