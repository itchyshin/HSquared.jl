# 2026-06-30 · V2-GREML genomic REML → covered (validation-scale) — close

The 2nd new covered model of the v0.2/v0.3/v0.4 push (after V3-TWOEFFECT-REML, V4-MV-REML).
**Validation-scale / opt-in. Public-covered FITTING surface stays 1 (v0.1 Gaussian).**

## The two G11 legs (doc-16)

1. **Pre-declared bias/MCSE recovery gate** — `sim/phase2_genomic_reml_recovery.jl`, predeclaration
   committed `cb22e679` BEFORE the run (PENDING result at declaration; harness byte-identical across the
   pre/post commits — no post-hoc relaxation). 48 cold-start seeds 20260800..847, N=300/M=1000, fresh
   VanRaden `G` per seed, `u ~ N(0, K·σ²g)` with `K = inv(Ginv)` (exact-model recovery of the supplied-`Ginv`
   REML estimator). RESULT (`6f4cbe06`): 48/48 converged; `|bias| ≤ 2·MCSE` for σ²g (0.5908, 0.41·MCSE),
   σ²e (0.4061, 0.32·MCSE), h² (0.5902, 0.50·MCSE) → **GATE PASS**. No detectable across-seed bias (never
   "unbiased"; the −1.5% σ²g tilt is expected REML finite-sample).
2. **Same-estimand external REML comparator** — `blupf90+` 2.60 AI-REML (PR #200), neutral start → the
   `fit_gblup_reml` optimum, σ²g/σ²e/h² ~1e-5, same-`Ginv` isolation. Genuinely independent of leg 1
   (different fixture: single SEED 20260630 vs the gate's 48 fresh-G seeds).

## Promotion (atomic, 3 surfaces flipped together)

- `src/validation_status.jl` — V2-GREML `partial → covered`; evidence rewritten to both legs + a
  SCOPE-OF-VALIDITY sentence (supplied-`Ginv` estimator, exact-model, N=300 single design point); owed
  column keeps the `sommer`/`rrBLUP` 2nd leg, broader N/M/h², G-construction (`V2-GRM`).
- `docs/design/capability-status.md` — "Genomic REML" `experimental → covered` with the same fence.
- `docs/design/validation-debt-register.md` — `partial → covered`; closing clause updated (gate PASSED).

## Checks

- `Pkg.test()` → **"Testing HSquared tests passed"** (exit 0). `validation_status()` = **48 rows**
  (count-guard `length==48` green); **covered 6→7, partial 38→37**; status-set guard accepts `covered`.
- Real `rose-systems-auditor` audit → **PROMOTE** (both legs verified independently incl. commit-ordering
  pre-registration check + harness re-run; no overclaim; count-guard survives).

## Honesty

`validation_status()` stays 48 rows; covered count **6 → 7**; public-covered FITTING surface **stays 1**
(v0.1 Gaussian). Covered = the supplied-`Ginv` REML ESTIMATOR at validation scale (opt-in) — NOT
G-construction (`V2-GRM` experimental), NOT production sparse-`G`, NOT the public default, NO R-facing
surface change. The flip is the maintainer's atomic **G10** (this PR is staged for sign-off, not
self-merged).
