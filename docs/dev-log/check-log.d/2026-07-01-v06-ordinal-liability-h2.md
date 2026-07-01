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

## Update — binary observed-0/1 scale added (same PR)

After the liability-only slice, the **BINARY (`:bernoulli_probit`) observed-0/1 scale** was added to the
same probit branch: the QGglmm probit integration over `η~N(μ,V_A+V_fixed)` — `p̄=E[Φ(η)]`,
`Ψ=E[φ(η)]` (reusing the module's 20-node `_gh_expect`), `h²_obs = Ψ²V_A/[p̄(1−p̄)]`. This was FIRST
verified (numerically, 4M MC) to EQUAL the classic Dempster–Lerner transform `h²_liab·z²/[p(1−p)]`
across μ and V_A∈[0.1,2.0], so it is not a guess — the two independent formulas cross-check to MC
precision. The test asserts `h²_obs ≈ DL` (≈1e-6) and `0 < h²_obs < h²_liab` (the classic result that
the observed-0/1 scale h² is below the liability scale). The **ORDINAL (K>2)** per-category observed
scale still needs the cutpoints and stays fenced (NaN). `method` stays `:probit_liability`;
`h2_observation` is now populated for binary. `Pkg.test()` green (count 50 UNCHANGED).

## Update — QGglmm EXTERNAL comparator RUN (logit + binary-probit observation scales)

The observation-scale external comparator (doc-19 §5) is now RUN against de Villemereuil's **QGglmm**
package (installed from CRAN). `QGglmm::QGparams(mu, var.a=V_A, var.p=V_A+V_fixed, model=binom1.{logit,
probit})$h2.obs` AGREES with the engine's `h2_observation` to **≤4.5e-6** over 9 (μ,V_A,V_fixed) cases
× 2 links = 18 comparisons (`comparator/qgglmm_probit_observed/`,
`docs/dev-log/recovery-checkpoints/2026-07-01-qgglmm-probit-observed-comparator.md`). This DISCHARGES
the external-comparator debt for the **logit** and **binary-probit** observation scales — the
binary-probit scale now has an internal Dempster–Lerner cross-check AND the external QGglmm comparator;
the logit scale (previously only internal-quadrature-checked) now has its external comparator too. KEY
CONVENTION pinned by the comparator (that the internal checks could not): QGglmm's `var.p` for the
observation integration is the PREDICTOR variance `V_A+V_fixed` (the link residual is baked into the
inverse link), not `V_A+V_link+V_fixed`. Owed field updated on all 3 surfaces. STILL owed: the QGglmm
comparator for the Binomial(n>1)/Poisson/ordinal(K>2)/Gamma-data scales, MCMCglmm, a Fisher/Falconer
sign-off, and G10 — NOT a covered claim; `validation_status()` = 50 UNCHANGED; public-covered = 1.
