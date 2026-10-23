# Poisson genetic GLLVM ordinary-start recovery pre-registration

Status: design reviewed by Curie and frozen before primary simulation; inference audit by Fisher found no denominator, interval, or estimand flaw. The opt-in-off smoke check passed. The development pre-run and frozen 50-seed primary run are complete. This is a single-cell usability recovery gate for the existing experimental genetic GLLVM route. It does not test broad calibration, other families, missing data, factor-analytic uniqueness, automatic rank selection, or release readiness.

The study follows ADEMP (Morris, White & Crowther 2019) and the 11 transparent-reporting items (Williams et al. 2024): [Morris et al.](https://doi.org/10.1002/sim.8086); [Williams et al.](https://doi.org/10.1111/2041-210X.14415).

## A: Aims

Primary aim: estimate the rate at which the current three-trait, two-factor Poisson-log genetic GLLVM fit recovers the genetic covariance from the documented default initialization on complete pedigree data.

Secondary aim: describe optimizer and inner-mode convergence, genetic-correlation error, fitted link-scale trait-mode availability, and runtime while retaining every attempted dataset.

## D: Data-generating mechanism

One pedigree contains 120 observed animals: 10 founder sires, 20 founder dams, and 90 offspring assigned cyclically to those parents. Every animal has one record for each of three traits. Let `A` be the additive numerator relationship matrix from this pedigree. For animal `i` and factor `k`, draw independent columns `f_k ~ N(0, A)`. Use the fixed loading matrix

```text
Λ = [1.0  0.0
     0.5  0.8
     0.3  0.9]
```

For trait `t`, the true genetic covariance is `G = ΛΛ'`. Each trait has intercept `β_t = 1`. Conditional on the genetic factors, draw independent responses

```text
η_it = β_t + Σ_k f_ik Λ_tk
Y_it | f ~ Poisson(exp(η_it))
```

This is one balanced, complete, known-pedigree cell with three traits, two genetic factors, pure low-rank covariance, and trait intercepts. The primary seeds are frozen to `20261600:20261649` (50 attempts); development seed `20261699` is outside that stream. A search of current `sim/`, `docs/dev-log/recovery-checkpoints/`, `docs/dev-log/after-task/`, and `docs/design/` found no use of these seed values before this pre-registration.

Fifty replicates give a recovery-proportion MCSE of `sqrt(p(1-p)/50)`, equal to 0.0424 at `p = 0.90`; three MCSEs are 0.127. This gate can identify gross default-start failure in this cell, not small differences or general calibration.

## E: Estimands / targets

The primary estimand is the probability that one dataset from this fixed DGP meets the pre-specified default-start recovery rule. For each seed, truth is `G = ΛΛ'`; estimates are `fit.genetic_covariance` and `genetic_correlation(fit.genetic_covariance)`. The reported trait genetic modes are conditional modes on the link scale; their raw error against latent generating effects is not gated because shrinkage and latent-mode estimation make that a different target.

A seed is a full success only when:

1. The outer optimizer and final inner mode both report convergence.
2. The objective and fitted `3 × 3` genetic covariance entries are finite.
3. The fitted `q × 3` link-scale trait genetic-mode matrix is finite.
4. The covariance symmetry error satisfies `norm(Ghat-Ghat', Inf) <= 1e-10 * max(1, norm(Ghat, Inf))`, and the minimum eigenvalue of its symmetrized form is at least `-1e-8 * max(1, opnorm(Ghat, 2))`.
5. Rotation-invariant relative Frobenius error `norm(Ghat-G)/norm(G)` is at most `0.45`. This reuses the existing exploratory threshold for continuity; it is not an independently validated accuracy standard.
6. Mean absolute error across the three unique off-diagonal genetic correlations is at most `0.25`. This gate is set above the largest per-seed mean error (0.1816) in the existing five-seed oracle-start rank-two scenario. It is a continuity threshold, not a calibrated precision guarantee.

The usability gate is at least 45 full successes among all 50 attempted seeds. Report the observed rate, Monte Carlo standard error, and Wilson 95% interval. Exceptions, nonconvergence, invalid/nonfinite outputs, and threshold failures remain in the denominator and receive separate failure labels. Report relative covariance error, mean absolute off-diagonal genetic-correlation error, outer and inner convergence, iterations, and wall time by seed. Do not score raw loadings.

Existing deterministic tests exercise objective invariance under loading rotation, trait order, and animal order for a fixed loading matrix. A separate fitted-output check now fits the fixed-start tiny Poisson fixture before and after trait reordering, then reorders raw pedigree input rows, rebuilds normalized pedigree and `Ainv`, and aligns the fitted trait effects by pedigree ID. The focused test compares objective, trait-permuted `G`, intercepts, and trait effects; it passed. This closes that small-fixture fitted-output ordering check, not broader bridge parity or calibration. Arbitrary trait-unit rescaling is not an invariance of Poisson count data, so no continuous response-unit scaling claim is made. Count scale remains the observed response scale.

## M: Methods

Fit only `HSquared.fit_gllvm_laplace_reml` with `rank = 2`, `structure = :lowrank`, trait intercepts, and its ordinary deterministic default loading initialization. Omit `initial`; use the documented R-route default of 1,000 outer iterations and the fitter's existing inner-mode controls. Do not add retries or tune the iteration cap after seeing primary results. The estimator uses the fixed-and-genetic-effect integrated Laplace objective with flat fixed-effect measure, as specified in `docs/design/genetic-gllvm-objective-contract.md`.

No external package comparator is included in this recovery study. A GLLVM.jl or gllvmTMB comparison supports a claim only if it matches fixed-effect treatment, integration approximation, pedigree, Poisson family, and genetic covariance. Gaussian reduction and identity-relationship checks are separate reduction evidence. No capability promotion follows from this study alone.

## P: Performance measures

- Recovery rate: `number of full successes / 50`; every attempted seed stays in the denominator.
- Recovery MCSE: `sqrt(phat * (1 - phat) / 50)`; also report a Wilson 95% interval.
- Covariance error: `norm(Ghat-G)/norm(G)`; report all finite returned fits and distinguish it from the full-success rate.
- Genetic-correlation error: mean absolute difference over the three unique off-diagonal correlations; also part of the pre-specified per-seed success rule.
- Convergence and failures: outer optimizer and inner mode fractions, counts by failure class, iterations, and nonfinite/exception records.
- Runtime: wall seconds for every attempted fit and total elapsed time.

The runner will retain a row-level result for each seed and record Julia version, package candidate SHA, host, thread limits, source hash, and timestamp. Before launching the 50-seed primary run, estimate its total wall time from a measured development seed plus Julia startup and a 2× margin. If this exceeds three hours, stop and show the pre-run receipt for Shinichi's approval. Use four Julia threads and one BLAS thread on CPU-only Totoro. A changed DGP, seed stream, iteration cap, or success criterion requires a new freeze before primary runs.

## Results and run receipt

The pre-run first exposed two runner-only namespace errors before fitting began: the script referred to internal `PoissonResponse` and `fit_gllvm_laplace_reml` as exported names. The runner now qualifies these through `HSquared`; this changed only how the frozen model is called. The same development seed then recovered with the ordinary default initialization; fit time was 3.77 s. The primary runtime estimate was 50 × 3.77 s × 2 = 377 s, plus startup, or about 6–7 minutes.

The primary run used Totoro, Julia 1.10.0, four Julia threads, one BLAS thread, the frozen seeds `20261600:20261649`, 1,000 maximum outer iterations, and the runner/source hashes recorded in the TSV. It completed in 140.13 s. All 50 attempted datasets were valid full successes: outer optimizer and inner mode converged, outputs were finite, the covariance passed symmetry and PSD tolerances, relative `G` error was at most 0.45, and mean absolute off-diagonal correlation error was at most 0.25. There were no fit exceptions or failed seeds in the primary denominator. The observed recovery rate is 50/50 = 1.00, MCSE 0, Wilson 95% interval [0.929, 1.000].

Across the 50 seeds, relative `G` error had median 0.1997 (range 0.0422–0.4179) and mean absolute correlation error had median 0.0590 (range 0.0068–0.2345). Median outer iterations were 220.5 (range 203–242), and median inner iterations were 8 (range 7–9). Minimum eigenvalues were numerical zero as expected for the rank-two covariance, with the most negative value `-4.34e-16`, far inside the pre-specified scaled PSD tolerance. Median fit time was 2.82 s.

The raw primary rows are retained at `docs/dev-log/recovery-checkpoints/2026-09-28-gllvm-ordinary-start-primary.tsv` (SHA-256 `d592bbcde8e61b53e95e3b12e0714fb15d408ca1e2ea7c36480d1da52446ac1d`). The tested runner SHA-256 was `f83132cba8571a53d1d88438bc635050f09aa40dc6650e7daa694f1a7de55651`; the Julia source snapshot SHA-256 was `1475066d4b6ff67df3c5adb2a303a96e20b3f7d8fd06e67a0dc283b96636dc0a`.

Fisher's independent read-only audit recomputed the Wilson interval and checked the denominator, thresholds, convergence flags, PSD interpretation, and runtime. Fisher found no concrete denominator, interval, or estimand flaw. Fisher also noted that the TSV contains scalar diagnostics rather than each fitted covariance matrix, so the per-seed matrix errors cannot be independently recomputed from the retained TSV.

After the primary run, the focused Julia test added paired fitted-output comparisons on the existing eight-animal fixture. The fit after trait reordering matches the corresponding covariance, intercept, and trait-mode permutations. A second fit rebuilds pedigree relationships from permuted raw ID/parent rows, then matches fitted trait modes by normalized animal ID. The focused file passes all 53 assertions. These checks are separate from the preregistered simulation and do not change its estimand or thresholds.

This supports ordinary-start usability in this one simulated cell only. The 50-seed interval is too wide for a high-precision recovery claim; the plug-in MCSE of zero at 50/50 is a boundary estimate and does not mean zero uncertainty. No calibration, heritability or EBV accuracy, external same-objective comparison, R–Julia parity, fitted-output permutation test, release promotion, or general family/rank claim follows. Those gates remain open.

## Williams 2024 reporting audit

| # | Item | Status | Where addressed |
|---|---|---|---|
| 1 | Aims | ✅ | A: one primary aim and one descriptive secondary aim |
| 2 | DGP and replicate count | ✅ | D: full model, one cell, 50 seeds with MCSE rationale |
| 3 | Estimands | ✅ | E: recovery probability, truth covariance, estimator outputs |
| 4 | Methods and literature | ✅ | M: exact fit and objective; Morris et al. and Williams et al. |
| 5 | Performance measures and formulas | ✅ | P: recovery, MCSE, Wilson interval, errors, failures, runtime |
| 6 | Software and settings | ✅ | Runner and primary TSV record Julia, candidate/source hashes, host, and thread limits |
| 7 | DGP code | ✅ | `sim/phase6_gllvm_ordinary_start_recovery_20260928.jl` |
| 8 | Performance-measure code | ✅ | Same runner computes the frozen recovery rule and per-seed metrics |
| 9 | Worked real-data example | gap | This is an internal validation gate, with no application claim |
| 10 | Full performance table | ✅ | `2026-09-28-gllvm-ordinary-start-primary.tsv`, all 50 rows |
| 11 | MCSE alongside estimates | ✅ | P reports the rate MCSE and Wilson interval |
