# After-task — v0.6 Gamma latent + data-scale h² (trigamma V_link + multiplicative) — 2026-07-01

> **Update — data scale added (commit `51a06d6c`, same PR #222).** This PR grew from latent-only to
> ALSO implement the Gamma **observation/DATA** scale: `h²_obs = V_A/[e^{V_pred}(1+1/ν)−1]` (NS-2017
> multiplicative, μ-independent lognormal closed form), **externally validated** against QGglmm's
> custom Gamma-log model (`var.func=μ²/ν`) to ~5e-11 (`comparator/qgglmm_gamma_observed/`). The Gamma
> testset is now **16 assertions** (as the test runner reports) covering latent + data + μ-independence
> (the earlier `isnan(h2_observation)` assertion is replaced by the data-scale value). Only the
> **ordinal (K>2)** observation scale now remains fenced. Rose PROMOTE-with-changes (this update + the
> doc-19 §3.1 Status paragraph). Below documents the original latent-scale commit `0e5a0755`.

## Task goal
Continue the overnight v0.6 loop. Resolve the fenced Gamma `V_link` convention (doc-19 flagged it
"needs derivation") and implement the Gamma **latent (log)-scale** heritability in the exported
`nongaussian_heritability`. Exact closed form with a numerically-verified constant; NOT a covered
flip. Branch off `main` (composes with #221).

## Active lenses and spawned agents
- Review lenses: Falconer/Fisher (the latent estimand), Gauss (the trigamma numerics).
- Real subagent: `rose-systems-auditor` (recorded in the PR / status).

## Live phase snapshot
Extends `V6-NS-H2` with the Gamma latent scale (`V_link = trigamma(shape)`). `main` @ `94d20319`,
count 50, public-covered fitting 1 — UNCHANGED. Independent of the 6-PR family chain + #221 (all
compose on `nongaussian_heritability`).

## Files changed (this slice)
- `docs/design/19-h2-scale-contract.md` — §3.1 + the Gamma row + §2.1: resolve `V_link = ψ₁(ν)`.
- `src/nongaussian.jl` — `_trigamma`; `:gamma` branch in `_nongaussian_h2_core` (shape kwarg);
  `_h2_family_params(::GammaResponse)`; shape threaded through both public methods.
- `test/runtests.jl` — new 14-assertion testset.
- `src/validation_status.jl`, `docs/design/capability-status.md`,
  `docs/design/validation-debt-register.md` — V6-NS-H2 row lockstep.
- `docs/dev-log/check-log.d/2026-07-01-v06-gamma-latent-h2.md`, this report.

## What changed
The Gamma-log latent residual is exactly `Var[log Y] = ψ₁(shape)` (trigamma) — verified numerically
(3×10⁶ draws/shape match to 3–4 sig figs; the `ln(1+1/ν)` lognormal/CV approximation is off ~4.5× at
ν=0.5). So `h²_latent = V_A/(V_A + ψ₁(ν) + V_fixed)` — NON-degenerate (unlike Poisson `V_link = 0`).
The observation/data scale is fenced (NaN).

## Checks run and exact outcomes
- Numerical: `_trigamma(1)=1.6449340700 ≈ π²/6`; Gamma `h2_latent(V_A=1,ν=1)=0.37808 = 1/(1+π²/6)`.
- `Pkg.test()` → **PASS**: new testset 14/14; count guard `== 50`.
- Docs build: `docs/design/*` are design docs (not Documenter pages) — no build needed; the code
  docstrings render (Documenter was exercised on the sibling #221 slice, exit 0).
- Real Rose audit → (PR / status).

## Public claim audit
V6-NS-H2 stays `partial`/`experimental`. No covered flip; `public_covered` = 1; count 50. The latent
value is an EXACT closed form (verified constant) — no "unbiased"/"validated coverage" claim; the
QGglmm/MCMCglmm comparator debt (OBSERVATION scale) is retained. The trigamma-accuracy comment was
corrected from "~1e-10" to the measured "~3e-9" (honesty).

## Tests of the tests
`_trigamma` is pinned against THREE independent closed forms (ψ₁ at 1, 2, ½) AND its recurrence
`ψ₁(x)=ψ₁(x+1)+1/x²`. The Gamma latent h² is checked for μ-independence, the V_fixed denominator, and
monotone-in-ν (larger shape → smaller V_link → larger h²), plus the NON-degeneracy contrast with
Poisson. The MC verification of `Var[log Y] = ψ₁(ν)` (in doc-19 §3.1) is the external anchor for the
constant.

## Coordination notes
Julia-engine lane, solo. No R edits. Composes with #221 (liability h²) — both add an `elseif` to
`_nongaussian_h2_core` + extend the same V6-NS-H2 row → trivial keep-both at merge (documented).

## What did not go smoothly
The branch was created off `main` (not stacked on #221), so it will have a trivial same-row / same-
function keep-both conflict with #221 at merge. Chosen deliberately over git-rebase gymnastics at
night; the conflict is documented in the PR + check-log.

## Known limitations
LATENT (log) scale only. The Gamma OBSERVATION/data scale (NS-2017 multiplicative) and the threshold
observation scale remain fenced follow-ups. No R surface. `ψ₁` accurate to ~3e-9 (ample for h²).

## Next actions
1. Rose audit → address → PR is open.
2. Follow-up: the Gamma observation/data-scale h² (NS-2017 multiplicative); the threshold observation
   scale; a same-estimand QGglmm comparator for the observation scales.
3. Maintainer: merge (this + #221 + the 6-PR chain) + G10 (unchanged).
