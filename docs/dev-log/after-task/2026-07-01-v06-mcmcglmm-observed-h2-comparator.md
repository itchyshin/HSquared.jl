# After-task — v0.6 MCMCglmm external comparator for the observation-scale h² — 2026-07-01

## Task goal
Add the **MCMCglmm** same-estimand external comparator for the non-Gaussian **observation-scale**
heritability (`nongaussian_heritability`) — the remaining owed h² comparator (the QGglmm exact-transform
leg is already done). EXPERIMENTAL/partial only; NOT a covered flip (G10 is the maintainer's). Branch
`feat/2026-07-01-v06-mcmcglmm-h2-comparator`, off `feat/2026-07-01-v06-ordinal-liability-h2` (the branch
carrying the h² code + the QGglmm comparator).

## Active lenses and spawned agents
- Review lenses: Fisher (the distributional estimand + the var.p convention), Curie (the DGP/design),
  Jason (MCMCglmm/QGglmm scout).
- **Real subagent:** a `rose-systems-auditor` claim-vs-evidence audit (verdict recorded below).

## Live phase snapshot
Extends `V6-NS-H2` (the h² transform) with its SECOND external comparator (the MCMCglmm leg). Base
merge `94d20319`, count 50, public-covered fitting 1 — UNCHANGED. Discharges the MCMCglmm item that
doc-19 §5 + the QGglmm checkpoint list as owed.

## Files changed (this slice)
- **NEW** `comparator/mcmcglmm_observed/` — `generate.jl`, `run_mcmcglmm.R`, `README.md`, `result.txt`
  (committed evidence), `.gitignore` (generated CSVs ignored).
- **NEW** `docs/dev-log/recovery-checkpoints/2026-07-01-mcmcglmm-observed-h2-comparator.md`.
- **NEW** `docs/dev-log/check-log.d/2026-07-01-v06-mcmcglmm-observed-h2-comparator.md`, this report.
- `src/validation_status.jl` — V6-NS-H2 owed field (MCMCglmm RUN) + fixed a **pre-existing drift** in
  the caveat field ("NO external-comparator (QGglmm/MCMCglmm) evidence" — stale since the QGglmm merge).
- `docs/design/capability-status.md`, `docs/design/validation-debt-register.md` — V6-NS-H2 owed field
  lockstep.
- `src/nongaussian.jl` — the `nongaussian_heritability` docstring + the `_nongaussian_h2_core` code
  comment (both stated the comparator status; brought consistent — the docstring was itself stale,
  still saying QGglmm covered only "logit + binary-probit").
- `docs/design/14-program-backlog.md` — the H7 backlog note (comparators now RUN).
- `docs/design/19-h2-scale-contract.md` — the two now-false "no same-estimand comparator yet" premises
  (line 16 + the §5 honesty fence) corrected (Rose-required; the still-owed families table + the
  point-in-time authoring count left as-is, the latter annotated "since grown to 50").

## What changed
The MCMCglmm leg is an INDEPENDENT END-TO-END Bayesian check, complementing the QGglmm leg (which feeds
identical `(V_A, μ)` into two implementations of the same closed form → ~1e-6, a transform-math check).
`generate.jl` simulates a deterministic **A = I / repeated-records** Poisson dataset (N=300 individuals
× 6 records = 1800; `a_i ~ N(0, σ²a=0.5)` iid; μ=0.8; no record-level over-dispersion; seed 20260701),
fits `fit_laplace_reml(family=:poisson)` with `Ainv=I`, and serializes the engine `h2_observation`
point. `run_mcmcglmm.R` fits `count ~ 1, random = ~id, family="poisson"` (MCMCglmm 2.36; units residual
ESTIMATED), transforms the posterior via **de Villemereuil's documented QGglmm workflow** (QGglmm 0.8.0
vignette *"Integrating over a posterior prediction"*: `var.a = VCV[,"id"]`, `var.p = rowSums(VCV)`,
`QGparams(model="Poisson.log")` per draw), and checks the engine point against the posterior 95% CI.

**Design rationale (verified, not assumed).** A=I ⇒ the breeding value is a plain iid `id` random
effect. Repeated records + a no-over-dispersion DGP let MCMCglmm estimate its units residual separately
and drive it to ~0, so `var.p = rowSums(VCV) ≈ V_A` — matching the engine's integration convention
(predictor variance `V_A + V_fixed`; doc-19 §2.2) and removing the over-dispersion-scale gap that the
fitting comparators (`comparator/poisson_mcmcglmm/`) can only report. Poisson is chosen because its
`var.p` convention is unambiguous (no link constant added). The **probit route is a trap**, checked
empirically: `QGparams(binom1.probit, var.p=V_A+1)` = 0.102 vs the engine's 0.170 (μ=0.5, V_A=0.4) — a
convention artifact unrelated to MCMC error; the engine matches `QGparams(var.p=V_A)` exactly for both
Poisson (0.40469) and probit (0.17041).

## Checks run and exact outcomes
- **Convention pre-check** (before choosing the family): engine == `QGparams(var.p=V_A, Poisson.log)` =
  0.4046904; engine == `QGparams(var.p=V_A, binom1.probit)` = 0.1704118 ≠ `QGparams(var.p=V_A+1)` =
  0.1021516. → Poisson chosen; probit rejected.
- **Recorded run** (chain 260000/60000/100 → 2000 samples; ESS[id]=455, ESS[units]=56): MCMCglmm
  V_id mean 0.5018, **V_units mean 0.0132 ≈ 0**; MCMCglmm h².obs mean 0.4852 / median 0.4860 / sd 0.0169;
  **95% CI [0.449053, 0.515349]**; engine h².obs point **0.501739 INSIDE the CI** (+0.98 posterior SD;
  83.5% of mass below). `PASS`.
- `julia --project=. -e 'using Pkg; Pkg.test()'` → **"Testing HSquared tests passed"**; count guard
  `@test length(validation_status()) == 50` holds; V6-NS-H2 `status == "partial"` holds.
- `julia --project=docs docs/make.jl` → **exit 0** ("build complete").
- `tools/status_cache.json` `public_covered_count` = **1** UNCHANGED.

## Public claim audit
A **DISTRIBUTIONAL** agreement — a Bayesian posterior vs the engine's asymptotic point, "within MCMC
error" — framed as such on every surface. It is explicitly **NOT machine precision** (that is the
QGglmm leg) and **NOT a validation of unbiasedness** (the Laplace engine and MCMCglmm share the same
Poisson-GLMM information limit). V6-NS-H2 stays `partial`; `validation_status()` = 50; public-covered
fitting = 1; nothing flipped. The +0.98-SD offset is disclosed and attributed to the tiny residual
over-dispersion inflating `var.p`, not to a transform error.

## Tests of the tests
The load-bearing check is that MCMCglmm's `V_units → ~0` (0.0132), which is what makes `var.p ≈ V_A`
and the comparison apples-to-apples; it is reported, not assumed. The probit convention counter-example
(0.102 vs 0.170) is the guard that justifies the Poisson choice over a superficially-attractive probit
design. The engine point sitting at the 83.5th posterior percentile (not a tail) shows the containment
is comfortable, not marginal.

## Coordination notes
Julia-engine lane, solo. No R-repo edits (the R twin `hsquared` is untouched; an R-facing
`nongaussian_heritability` surface remains owed). Tooling banked: **MCMCglmm 2.36** installed (CRAN,
macOS arm64), joining **QGglmm 0.8.0**.

## What did not go smoothly
- The base-branch topology is a thicket of divergent stacked branches; confirmed
  `feat/2026-07-01-v06-ordinal-liability-h2` (not my worktree's default tip) carries both the h² code
  and the QGglmm template, and branched off it as instructed.
- Found **pre-existing drift**: `validation_status.jl`'s V6-NS-H2 caveat field still said "NO
  external-comparator (QGglmm/MCMCglmm) evidence" although the QGglmm merge had updated the owed field —
  fixed as part of making the row internally consistent.

## Known limitations
- **One design, one family (Poisson).** A distributional characterization, not a multi-seed calibration.
- **doc-19 contained fix (post-Rose).** My first pass deferred doc-19; the Rose audit correctly
  overruled that — doc-19 is a live "design contract", and its two "no same-estimand comparator yet"
  premises (line 16 + the §5 fence) were categorically false present-tense claims (falsified even by the
  prior QGglmm merge). Fixed those two premises only; left the still-owed families table (§5) and the
  point-in-time authoring count (annotated "since grown to 50").
- Still owed for the row's covered path: the ordinal(K>2)/Gamma-data observation-scale comparators, a
  Fisher/Falconer sign-off, intervals/SEs, an R surface, and the maintainer G10.

## Next actions
1. Rose audit → DONE (PROMOTE-WITH-CHANGES; the one required change applied) → open PR (stacked on
   `feat/2026-07-01-v06-ordinal-liability-h2`).
2. Follow-ups: the ordinal(K>2) + Gamma-data observation-scale comparators; a Fisher/Falconer sign-off;
   an h² interval/SE; the R-facing `nongaussian_heritability` surface.
3. Maintainer: the v0.6 merge + G10 (unchanged; this slice is additive and does not affect it).

## Rose audit verdict
**Real `rose-systems-auditor` → PROMOTE-WITH-CHANGES → change applied → clean PROMOTE.** Rose
independently reproduced every headline number (a byte-identical full MCMCglmm re-run:
CI [0.449053, 0.515349], engine inside, V_units 0.0132), verified the engine Poisson transform equals
`QGparams(var.p=V_A)` to 2.2e-16, confirmed the probit-trap numbers exactly (0.102152 vs engine
0.170412), and confirmed the honesty pins (count 50, public_covered 1, V6-NS-H2 partial, `Pkg.test()`
exit 0). It found NO overclaiming (the distributional/not-machine-precision/not-unbiasedness framing is
consistent on every surface and never conflated with the exact QGglmm leg) and judged the diff surgical.
The **one required change** — fixing the same drift class I had deferred in doc-19 (`19-h2-scale-contract.md`
line 16 + the §5 fence still asserted "no same-estimand comparator yet", now categorically false) — was
applied (see Files changed). Rose explicitly verified the other "no external comparator" mentions
(`src/genomic.jl`, `src/pedigree.jl`, `src/nongaussian.jl:836,890`, dev-log history, the scout doc)
refer to different capabilities / are dated records and are correctly left untouched.
