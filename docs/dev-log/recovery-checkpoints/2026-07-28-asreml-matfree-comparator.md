# Result — F6 matrix-free REML same-estimand external comparator (ASReml-R): **AGREE**

**Date:** 2026-07-28 · **Estimators:** `fit_ai_reml` (exact, `V1-REML`) + `fit_matrix_free_reml`
(stochastic, `V1-MATFREE-REML`) · **Comparator:** ASReml-R **4.2.0.482** (R **4.6.1**), an
independent same-estimand REML lineage · **Data:** random-mating high-fill pedigree, q=2000,
fill `nnz(L)/n` = 75.2, data seed 20269000, truth `(σ²a, σ²e) = (1.0, 1.0)` ·
**Lane:** Julia engine · **Branch:** `codex/2026-07-13-v07-performance-localization`

## Scope fence — read first

This is an **ESTIMAND** comparison: variance components only. **No ASReml timing was recorded, and
none may be inferred from this document.** The standing ASReml honesty fence (§4 of
`docs/dev-log/native-engine-arc/2026-07-24-ai-reml-convergence-findings.md`) records that no
head-to-head performance comparison against ASReml has ever been run in this project; that remains
true after this run. A timing leg would be a separate exercise needing its own pre-declaration and
its own fencing. Both comparator scripts carry an in-file instruction not to add a stopwatch.

This also tests **agreement, not recovery.** Recovery-to-truth for `fit_matrix_free_reml` is a
pre-declared known-truth gate at tail scale, which remains **OPEN** (`V1-MATFREE-REML`).

## Verdict: **AGREE** (exit status 0)

ASReml was given the **pedigree**, not our `Ainv`, and built its own inverse via `ainverse()` — so
this checks the relationship construction as well as the REML optimiser. Had our Henderson `Ainv`
been wrong, supplying it would have concealed exactly that error.

```r
ainv <- ainverse(ped)
fit  <- asreml(fixed    = y ~ 1,
               random   = ~ vm(animal, ainv),
               residual = ~ idv(units),
               data     = d)
```

### Leg 1 — ASReml vs the EXACT engine (both deterministic; tol 1e-3)

| component | `fit_ai_reml` | ASReml-R | rel.diff |
|---|---|---|---|
| σ²a | 1.16309475 | 1.16309490 | **1.31e-07** |
| σ²e | 0.92332216 | 0.92332208 | **8.07e-08** |

Agreement to seven significant figures across an independent implementation and an independently
constructed `A⁻¹`.

### Leg 2 — ASReml vs the STOCHASTIC matrix-free fitter (8 seeds; |gap| ≤ 3 SD)

A Monte-Carlo estimator is not expected to hit a point value — it is expected to be **centred** on
it. So the criterion is the across-seed mean ± SD with the gap in **units of SD**, following the
precedent in `comparator/matfree_blupf90_neffect.jl`. A tight relative tolerance here would be
meaningless.

| nprobe | component | matrix-free (mean ± SD) | ASReml | \|gap\| | in SD |
|---|---|---|---|---|---|
| 128 | σ²a | 1.159278 ± 0.007449 | 1.163095 | 0.003816 | **0.51** |
| 128 | σ²e | 0.925115 ± 0.003661 | 0.923322 | 0.001793 | **0.49** |
| 512 | σ²a | 1.161054 ± 0.006146 | 1.163095 | 0.002041 | **0.33** |
| 512 | σ²e | 0.924241 ± 0.003018 | 0.923322 | 0.000919 | **0.30** |

Both the gap and its SD shrink as `nprobe` rises 128 → 512, which is the behaviour the estimator's
theory predicts (Monte-Carlo error ∝ `1/√nprobe`). The fitter is centred on the ASReml optimum at
both budgets, comfortably inside the 3-SD band. That band and the 1e-3 exact tolerance are fixed
in the script (`SD_TOL`, `TOL_EXACT`) and were set before the verdict was read — but note they are
*not* pre-declared at a freeze commit, and do not need to be: G11 requires pre-declaration for the
**recovery gate**, not for a comparator.

## What this discharges, and what it does not

**Discharges:** the external same-estimand comparator leg for `V1-MATFREE-REML` **at validation
scale**. ASReml-R satisfies G11's external-comparator clause directly
(`docs/design/16-promotion-gate-predicates.md:31-35` — "a same-estimand external comparator, its
KIND fixed — REML-vs-REML"). It is **not** invoked under the substitutability rule: that rule's
clause (a) supplies a *second* independent lineage "on top of the one existing same-estimand leg",
and this is the first such leg for this estimator, so the rule does not apply.

**Does NOT discharge:**

- **Recovery-to-truth.** ASReml is another estimator, not the truth. The pre-declared known-truth
  gate stays OPEN, and it is the leg that matters most.
- **The AT-SCALE comparator leg.** This fixture is q=2000 at fill 75.2 — **below** the measured
  crossover of 150, i.e. squarely in the regime where the exact path still wins. It therefore never
  exercised the high-fill, exact-infeasible tail the matrix-free fitter exists for. That leg remains
  owed, following the precedent of the multi-effect twin `V3-NEFFECT-MATFREE-FIT`, which retained
  its at-scale comparator leg after a q=860 `blupf90+` run.
- **Anything above `n = 10 000`.** No evidence of any kind exists there — which is why the `:auto`
  divert to the matrix-free fitter was withheld rather than shipped on an extrapolated threshold.
- **`V1-REML` / `V1-EIGEN-REML` comparator debt.** Leg 1 incidentally shows ASReml agreeing with
  `fit_ai_reml` to 1.3e-7, but those rows' owed legs are not claimed as discharged here — that
  needs a run declared against those fitters on their own fixtures.
- Calibrated intervals, `>2` components, non-Gaussian, or the R bridge.

## Toolchain note

`sommer` is **not installed** on this machine, so the five existing `comparator/run_sommer_*.R`
scripts cannot currently run here; the committed sommer evidence was produced under sommer 4.4.5 /
R 4.6.0 against this box's R 4.6.1. That is a repo-health issue independent of this comparator,
recorded so the gap is not mistaken for a silent regression.

## Reproduce

```sh
julia --project=. comparator/prepare_asreml_matfree.jl
Rscript comparator/run_asreml_matfree.R      # exit 0 = AGREE, 1 = DISAGREE
```

The packet under `comparator/asreml_matfree/` is regenerable and gitignored, matching the sommer
convention; the scripts and this document are the committed evidence.

> Related: `docs/design/16-promotion-gate-predicates.md` (G11 + substitutability) ·
> `docs/design/validation-debt-register.md` (`V1-MATFREE-REML`) ·
> `docs/dev-log/after-task/2026-07-28-f6-matrix-free-single-effect.md` ·
> `docs/dev-log/native-engine-arc/2026-07-24-ai-reml-convergence-findings.md` §4 (the ASReml fence).
