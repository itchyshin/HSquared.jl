# Execution plan — remaining 7 GLMM/inference slices (2026-06-22)

The forward **plan** for the slices remaining after session 2. The session **record**
is `2026-06-22-backlog-grind-session2-handover.md` (START HERE); this is the
playbook. Full per-slice specs: `docs/design/15-backlog-wave-execution-plan.md` +
`/tmp/backlog_specs.md` (regenerate from the design-sweep workflow if gone).

## State (verify live before starting)

- **main `d1838c26`**; `validation_status()` = **44 rows** (5 covered + 3
  covered_external + 35 partial + 1 planned); `@test length(validation) == 44`
  at `test/runtests.jl:174`.
- Public-default **covered = 1 (Gaussian)**. Nothing else is covered.
- Order: **H2 → H3 → H6 → H7 → C2 → C6 → J1 (last)**.

## Why this order

The H-family (H2/H3/H6/H7) all live in `src/nongaussian.jl` and share the
derive→oracle recipe and the Laplace machinery — doing them consecutively keeps the
context warm and reuses the same oracle scaffolding. C2/C6 are inference-interval
slices on already-covered machinery (V4-MV-REML, V1-HERIT-CI). **J1 floats to the
end** because it is gated on a derivation + sign-off, not just implementation.

## The per-slice recipe (every H/C slice — rigid)

1. Branch `claude/<slice>` from fresh `main`.
2. Read the FULL spec (doc-15 + `/tmp/backlog_specs.md`). State assumptions.
3. **DERIVE** the math first (kernels, normalizer, information) — in a comment or
   on paper. Don't trust the spec's formulas; re-derive them.
4. **Build an INDEPENDENT oracle BEFORE trusting the impl:**
   - score & weight vs **central finite differences** of `_fam_loglik`;
   - a **limiting-case reduction** to a trusted family (the *binding* anchor —
     e.g. H1 used the Poisson limit θ→∞ and the geometric at θ=1);
   - for a marginal: a **tensor Gauss–Hermite quadrature of the TRUE marginal** on
     the 3-animal sire/dam/calf fixture (adapt the existing `_binom_marginal` /
     `_poisson`-style oracle in the runtests Phase-6 testsets).
5. Implement kernels + wiring. **Reuse the existing `_loggamma`** (Lanczos in
   `multivariate.jl`, in scope) — a duplicate definition breaks precompilation.
6. Run the oracle. **Commit ONLY once it passes.** The spec accelerates but does
   NOT guarantee correctness — J1 proved a spec can be wrong.
7. **Funnel** (serialized): add/update the `validation_status` row — bump
   `@test length(validation) == N` and insert the tuple **NOT-first / NOT-last**
   (the suite pins `validation[begin].id == "V0-LOAD"` / `[end].id ==
   "V6-GGLLVM-REML"`) — then mirror into the two `.md` ledgers + the doc-14 mark.
8. Opt-in recovery sim if applicable: pace heavy (background + thread-capped);
   **predeclare the gate, report-not-gated honestly if recovery is loose — NEVER
   relax a gate post-hoc** (the Bernoulli/NB precedent).
9. `Pkg.test()` + `docs/make.jl` green (thread-capped).
10. **Real `rose-systems-auditor` audit (mandatory).** Address findings.
11. `check-log.d/` entry + after-task report.
12. PR → watch CI → merge on green. **One slice per PR** (funnel serialization).

## Per-slice plan

### H2 — beta-binomial (NEXT) → new `V6-BETABINOMIAL`, count **44 → 45**
`BetaBinomialResponse(n_trials::Int, rho::Float64)` in `src/nongaussian.jl`
(internal, logit link, ρ∈(0,1) overdispersion, ρ→0 = Binomial limit). Closed-form
marginal `ℓ = lbeta(α+y, β+n−y) − lbeta(α,β) + log C(n,y)`, `α = p(1−ρ)/ρ`,
`β = (1−p)(1−ρ)/ρ`, `p = logistic(η)`. `_lbeta` from the existing `_loggamma`.
**Two traps:** (1) **weight = FISHER (expected) information**, NOT observed —
beta-binomial isn't log-concave in η, so observed info can go negative and break
`cholesky(Symmetric(H))` in the IRLS Newton loop (`nongaussian.jl:227`/`:247`);
document the deviation. (2) **`NonGaussianFit` blast radius** — add an explicit
`dispersion::Union{Float64,Nothing}` field; audit every `NonGaussianFit(` call (2 in
`fit_laplace_reml` + the `genetic_gllvm.jl` reductions). Fit σ²a at a SUPPLIED FIXED
ρ (1-param Brent); joint (σ²a,ρ) is follow-up. Reject `:variational`. **Oracle:**
ρ→0 → `BinomialResponse(m)` (binding anchor) + score-vs-FD + Fisher-weight-positive
(incl. a regime where observed is negative) + GHQ marginal value gate.

### H3 — probit / threshold → new `V6-PROBIT`, count **+1**
`BernoulliProbitResponse` (probit link `p = Φ(η)`), Laplace + VA. **Reuse the
existing `_standard_normal_cdf_approx(z)` (`src/genomic.jl:2055`) for Φ** — verify
its accuracy suffices for the Newton mode; the density is `φ(η) = exp(−η²/2)/√(2π)`.
Keep `/src` dependency-free (do NOT pull `SpecialFunctions`). **Oracle:** the binary
threshold reduces to the binary logit/Bernoulli structure conceptually but NOT
numerically — use score-vs-FD + a GHQ marginal + a known small-case probit value.
Liability/observation-scale h² is H7's job, not here.

### H6 — non-Gaussian interval coverage → **updates `V6-LAPLACE`/`V6-FIT` in place** (no new row)
The σ²a profile-LRT interval already covers `:poisson`/`:bernoulli`/`:binomial`
uniformly; this slice adds the **coverage EVIDENCE** (mostly the Bernoulli leg).
HEAVY BLAS coverage sim — run SOLO, background + capped. **Report coverage honestly**
— at small n the asymptotic interval will likely under/over-cover; that is the
finding, not a failure. Update the `V6-FIT` register row + the `V6-LAPLACE`
`validation_status` evidence in place; no count change.

### H7 — latent- & observation-scale h² → new `V6-NS-H2`, count **+1**
Nakagawa–Schielzeth / de Villemereuil (QGglmm) heritability transform. **NEW
EXPORT.** The link-specific distribution variance (logit, log, probit) maps the
latent-scale σ²a to an observation-scale h². **Oracle:** the link variance terms vs
the published QGglmm formulas / reference values; the latent-scale h² reduces to
`σ²a/(σ²a+σ²_link)`. Validation-scale, partial.

### C2 — genetic-correlation interval → **EXTENDS `V4-MV-REML`** (append a sentence; no new row; status UNCHANGED)
`genetic_correlation_interval(fit, Y, X, Z, Ainv; level=0.95, method=:delta|:profile)`
in `src/multivariate.jl`. Build on the V4-MV-REML covariance SEs. **Oracle:** delta
vs profile agreement; boundary behaviour as `|r_g|→1`; the delta SE from
`multivariate_covariance_standard_errors`. **Do NOT touch the V4-MV-REML covered
status** — it covers the POINT ESTIMATE only; the interval is partial/asymptotic.

### C6 — parametric-bootstrap VC CI → **EXTENDS `V1-HERIT-CI`** (no new row)
`bootstrap_variance_component_interval(fit)` in `src/likelihood.jl`, **Gaussian REML
only** (the validated lane). Simulate at the fitted `(β, σ²a, σ²e)` over the supplied
relationship, refit, percentile CI. HEAVY (resampling) — pace. Cross-check vs the
profile-LRT CI. Append to `V1-HERIT-CI` (held apart from C5's already-landed edit of
the same row — just append, don't clobber).

### J1 — haplodiploid (LAST; LANDMINE — do NOT mechanically land)
The design spec's convention is **self-contradictory**: the stated female rule
`½(A_sire+A_dam)` gives father→daughter = 0.5, but the canonical anchor (and the row
text) require **1.0** (a haploid drone transmits his whole genome).
- **STEP 0 (before any code):** DERIVE the diploidized haplodiploid additive-
  relationship recursion from a reference (Mrode / nadiv / a quant-gen text),
  resolve the male (haploid) vs female (diploid) rules, and get **Mendel + Falconer
  sign-off** (spawn the lenses or get maintainer ratification).
- THEN: a dense, validation-scale kernel in `src/pedigree.jl` mirroring the existing
  `clonal`/`selfing` siblings; **oracle = a hand-computed small haplodiploid
  pedigree** (drone, queen, worker daughters) against the DERIVED coefficients;
  split the `V7-INHERIT` register row + a capability-status row; Rose + **maintainer
  sign-off** before landing.

## Funnel-landing mechanics

- `src/validation_status.jl`: a new row → bump `@test length(validation) == N`
  (currently **44**) AND insert NOT-first / NOT-last. Status counts are NOT pinned
  (the `Set(status)` guard at `runtests.jl:205` only checks the status *set*), so
  adding `partial` rows is safe; a `covered` promotion needs the full sign-off chain.
- `.md` mirrors: `docs/design/validation-debt-register.md` (fine-grained, per-family
  V6 rows) + `docs/design/capability-status.md` (capability-named rows) — keep BOTH in
  sync with `validation_status.jl`.
- `docs/design/14-program-backlog.md`: mark the slice ✅ + merge commit.

## Risk register

1. **J1 convention** (landmine) — derive + sign-off FIRST; never mechanically land.
2. **H2 Fisher-vs-observed weight** — use expected info or `cholesky` breaks.
3. **H2 `NonGaussianFit` blast radius** — audit every constructor call site.
4. **H3 dependency-free Φ** — reuse `_standard_normal_cdf_approx`; no `SpecialFunctions`.
5. **Heavy sims (H6 coverage, C6 bootstrap)** — SOLO, background + capped; never two
   heavy julia jobs concurrently (precompile × N pegs the machine).
6. **Funnel contention** — one slice per PR; rebase the count assertion on the live value.
7. **Post-hoc gate relaxation** — predeclare gates; report-not-gated honestly.

## Definition of Done (per slice)

impl + tests + docs + capability-status row + validation-debt row + check-log.d +
after-task report + **real Rose audit** + clean local `Pkg.test()` / `docs/make.jl`
+ clean CI + **maintainer sign-off for any covered promotion**.

## Environment / commands

```sh
# tests (julia is off PATH; thread-capped)
PATH="$HOME/.juliaup/bin:$PATH" OPENBLAS_NUM_THREADS=2 OMP_NUM_THREADS=2 JULIA_NUM_THREADS=1 \
  julia --project=. -e 'using Pkg; Pkg.test()'
# docs (status pages regenerate from validation_status())
PATH="$HOME/.juliaup/bin:$PATH" julia --project=docs docs/make.jl
# R live bridge: add HSQUARED_JULIA_PROJECT=../HSquared.jl
# Makie local-draw env (L-slices only): /tmp/hsq_makie_env (CairoMakie 0.15.11; recreate if cleared)
# mission control: python3 -m http.server 8791 --bind 127.0.0.1 --directory ~/.claude/hsquared-control-centre
```
