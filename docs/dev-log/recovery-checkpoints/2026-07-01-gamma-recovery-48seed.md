# V6-GAMMA recovery gate — 48-seed known-truth — 2026-07-01

Executes the recovery gate PRE-DECLARED in `sim/phase6_gamma_recovery.jl` (committed `5e86e067`,
BEFORE this run). Known-truth recovery for the Gamma (log-link) JOINT estimator
`fit_laplace_reml(...; family = :gamma)` (Phase 2, #216). Evidence for the v0.6 Gamma covered path
(doc-20 / doc-16 G11); promotes nothing — experimental/`partial`, public-covered fitting = 1 UNCHANGED.

## Run

- Harness: `sim/phase6_gamma_recovery.jl` (opt-in, dependency-free Marsaglia–Tsang Gamma sampler),
  48 seeds. Design: A = I animal model + repeated records (80 animals × 4 records = 320 obs — so the
  iid animal variance σ²a is identified), `u ~ N(0, σ²a)`, `y | u ~ Gamma(shape ν, mean exp(β + u))`.
  Truth: σ²a = 0.35, ν = 3.0, β = 0.6.
- Reproduce: `julia --project=. sim/phase6_gamma_recovery.jl --seeds=48`.

## Result — aggregate Monte Carlo recovery (m = 48)

| param | true | mean | bias | MCSE | \|bias\| ≤ 2·MCSE |
| --- | --- | --- | --- | --- | --- |
| σ²a | 0.3500 | 0.3467 | −0.0033 | 0.0089 | yes (0.37·MCSE) |
| ν (shape) | 3.0000 | 2.9981 | −0.0019 | 0.0434 | yes (0.04·MCSE) |

- Convergence: **48/48**.
- `GATE gamma_recovery within_2mcse_all=true converged_all=true gate_pass=true seeds=48`.

## Verdict

**The pre-declared Gamma recovery gate PASSES:** 48/48 converged and `|bias| ≤ 2·MCSE` for BOTH σ²a and
the shape ν, with both biases well inside the band (σ²a at 0.37·MCSE, ν at 0.04·MCSE). Read as **no
detectable bias** at this design/power — never "unbiased". The MCSE floor (σ²a 0.0089) means a σ²a bias
above ≈0.018 (≈5%) would be detectable; the observed −0.003 is far below that.

## Covered-path status for V6-GAMMA (doc-16 prerequisites)

With this gate, the Gamma family now has ALL the doc-16 covered PREREQUISITES assembled:
1. **Joint estimator** — `fit_laplace_reml(...; family=:gamma)` (#216). ✅
2. **Same-estimand comparator** — `glmmTMB Gamma(link="log")` agrees (shape Δ0.003, σ²a Δ0.017;
   `2026-07-01-gamma-glmmtmb-comparator.md`). ✅
3. **Pre-declared recovery gate** — PASSES (this checkpoint). ✅

Owed for the covered FLIP: the maintainer's **G10** sign-off (non-delegable), a real Rose audit on the
full chain, and the surface niceties (`:symbol` payload + scale-labelled h² — NOT doc-16 covered
blockers). This is an ENGINE-covered readiness, NOT the public default (public-covered fitting = 1).

## Fences

Experimental/`partial`; `validation_status()` = 50 UNCHANGED; public-covered fitting = 1 UNCHANGED; NOT
a covered claim (only G10 flips it). Single design (A=I / q=80 / repeated records); broader-DGP recovery
+ pedigree-A (non-I) designs are follow-ups.
