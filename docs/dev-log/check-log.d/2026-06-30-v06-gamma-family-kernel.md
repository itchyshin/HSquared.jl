# 2026-06-30 v0.6 Gamma (log-link) family kernel — T-Gamma (row deferred)

## Goal

Lens: Gauss/Noether (kernel numerics) + Curie (oracle) + Rose (mandatory). Build the next v0.6
non-Gaussian family after the ordinal kernel: the **Gamma (log-link)** Laplace family for
strictly-positive continuous traits (milk yield, longevity). EXPERIMENTAL/`partial`, INTERNAL. On
branch `feat/2026-06-30-v06-gamma-family` (off `main`), autonomous, staged for review — NOT merged.

**The `validation_status()` row is DEFERRED** (not added in this PR) to respect the repo's
`one-row-adding-PR-at-a-time` count-guard discipline while #212 (the ordinal row) is unmerged — so
this PR does NOT touch `validation_status.jl`/`capability-status`/`debt-register` and does NOT bump
the count guard (stays 48, no conflict with #212). The row lands in a follow-up once the family PRs
are merge-sequenced.

## What was done

- **`src/nongaussian.jl`:** `GammaResponse(shape)` `<: ResponseFamily` — mean `μ = exp(η)`, supplied
  shape `ν`, `ℓ = ν(log ν − η) + (ν−1)log y − ν y e^{-η} − log Γ(ν)`. Kernels
  `_fam_loglik/_fam_score/_fam_weight` (score `ν(y e^{-η} − 1)`; OBSERVED-information weight
  `ν y e^{-η} > 0`, since Gamma log-link is log-concave — the Poisson/probit convention) + a positive
  shape guard (constructor) + `_check_counts` (strictly-positive `y`). Reuses the existing `_loggamma`.
- **`test/runtests.jl`:** new testset "Phase 6 Gamma … (T-Gamma, v0.6)" — the **ν=1 → Exponential**
  reduction (loglik/score/weight exact), finite-difference score/weight gates (observed weight
  `> 0`), an end-to-end finite Laplace marginal, and guards. No count-guard/row-check change.

## Commands / results

- Kernel smoke: ν=1 exponential reduction exact; finite-diff score/weight (observed); weight `> 0`;
  end-to-end marginal finite; guards throw.
- `julia --project=. -e 'using Pkg; Pkg.test()'` → PASS at count **48** (unchanged; no row added).
- `julia --project=docs docs/make.jl` → exit 0.

## Claim boundary

EXPERIMENTAL, INTERNAL (not exported), Laplace-only, SUPPLIED shape only. `validation_status()` = 48
UNCHANGED (row DEFERRED); public-covered fitting = 1 UNCHANGED; NOT a covered claim; not the public
default; not wired to `fit_laplace_reml`'s `:symbol` resolver or R (reachable via the family object
through `laplace_marginal_loglik`). STILL OWED: the deferred status row, joint shape estimation, the
resolver/fit/R wiring, a same-estimand comparator (R `glmmTMB` DOES support `Gamma(link="log")` — a
valid same-estimand leg here, unlike the ordinal case), a recovery gate, and observation-scale h².
Real Rose audit pending.
