# 2026-07-01 v0.6 Gamma JOINT (σ²a, shape) estimation

## Goal
Lens: Gauss/Fisher + Rose. Phase 2 of the 7-hour plan: extend the merged Gamma kernel to JOINT
`(σ²a, shape ν)` estimation via `fit_laplace_reml(...; family = :gamma)`. Extends the `V6-GAMMA` row
(count stays 50). Branch `feat/2026-07-01-v06-gamma-joint-estimation`. Experimental/`partial`.

## What was done
- **`src/nongaussian.jl`:** `:gamma` case in `fit_laplace_reml` — joint `(log σ²a, log ν)` NelderMead,
  the SAME shape as `:nbinom` (ν plays `theta`'s role; `theta_init` seeds it). Gamma is continuous +
  well identified given relatedness/replication, so no safety rail is needed (unlike the ordinal
  threshold). Laplace-only.
- **`test/runtests.jl`:** T-Gamma-fit testset — on a structured pedigree with a sire-pattern genetic
  signal the fit converges with meaningful σ²a (`> 1e-3`) + positive ν, a self-consistent marginal
  loglik, and beats an off-optimum; strictly-positive-response + `:variational` guards throw.
- **Status (3 surfaces):** V6-GAMMA evidence/owed/boundary extended (joint estimation landed).

## Commands / results
- Smoke: signal-carrying fixture → σ²a=0.213, ν=21.4, converged, self-consistent (a signal-less
  fixture correctly gives σ²a≈0 — no heritable variance).
- `Pkg.test()` → PASS (T-Gamma-fit testset; count 50 UNCHANGED).
- `docs/make.jl` → exit 0.

## Claim boundary
EXPERIMENTAL, INTERNAL, Laplace-only. `validation_status()` = 50 UNCHANGED (extends V6-GAMMA);
public-covered fitting = 1 UNCHANGED; NOT a covered claim; the `:gamma` fit path exists but is not
exported/R-wired. STILL OWED: the `:symbol` payload + scale-labelled h², the **glmmTMB `Gamma(link=log)`
comparator RUN** (installed locally — Phase 4), a recovery gate (Phase 5). Real Rose audit pending.
