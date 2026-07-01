# 2026-07-01 v0.6 ordinal/probit LIABILITY-scale h² (doc-20 Step 4)

## Goal
Lens: Falconer/Fisher + Rose. Extend `nongaussian_heritability` to the THRESHOLD families
(`:bernoulli_probit`, `:ordered_probit`) with the liability-scale heritability — the doc-20 Step-4
follow-up and the selection-relevant primary scale for the top v0.6 family (T1 ordinal). Extends
`V6-NS-H2` (stays `partial`, count 50). Branch `feat/2026-07-01-v06-ordinal-liability-h2` (off `main`).

## What was done
- **`src/nongaussian.jl`** — `_nongaussian_h2_core` gains a `:bernoulli_probit || :ordered_probit`
  branch: the liability scale IS the latent scale with probit `V_link = 1` (Dempster–Lerner 1950;
  doc-19 §2.3), so `h²_liab = V_A/(V_A + 1 + V_fixed)` returned in `h2_latent` (independent of μ and
  the cutpoints — they set the observed incidence, not the liability partition), `method =
  :probit_liability`. The observed/category scale (`z²/[p(1−p)]` binary; per-category ordinal) needs
  the incidence/cutpoints and is a FENCED follow-up → `h2_observation = NaN` (not guessed). Added
  `_h2_family_params(::BernoulliProbitResponse)` + `(::OrderedProbitResponse)` so both public
  signatures dispatch; docstring + error message updated.
- **`test/runtests.jl`** — new TDD testset (RED→GREEN): closed-form `h²_liab = 1/3` at V_A=0.5;
  cutpoint-independence; the EXACT K=2 ordinal→bernoulli-probit reduction; the V_fixed denominator
  (`1/(1+1+1)`); monotone-in-V_A; observed scale NaN; `method = :probit_liability`.
- **Status (3 surfaces, lockstep)** — V6-NS-H2 evidence records the liability closed form; owed field
  moves probit from "families pending" to "the threshold OBSERVED/category scale pending (liability
  is now done)".

## Commands / results
- TDD: pre-implementation the probit families THREW (RED confirmed); post-implementation the closed
  forms are exact (`h2_latent = 0.3333…`, K=2 reduction `0.4444… == 0.4444…`, `latent_total = 3.0`).
- `Pkg.test()` → PASS (new testset; count guard `== 50` UNCHANGED — extends V6-NS-H2, no new row).
- `docs/make.jl` → exit 0.

## Claim boundary
This is a CLOSED-FORM transform (a deterministic function of V_A), not an estimator — so it needs no
recovery gate and no same-estimand comparator for the liability value itself; it is exact by
construction and tested against closed forms + the K=2 reduction. The V6-NS-H2 row's standing debt (a
QGglmm/MCMCglmm comparator + Fisher/Falconer sign-off) still covers the OBSERVATION-scale decomposition.
EXPORTED but experimental; `validation_status()` = 50 UNCHANGED; public-covered fitting = 1 UNCHANGED;
NOT a covered claim. The Gamma observation-scale h² is deliberately NOT included (it needs an NS-2017
distribution-specific-variance / trigamma lit-check — not guessed).
