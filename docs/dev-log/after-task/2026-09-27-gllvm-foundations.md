# Genetic GLLVM foundations, candidate report

## 1. Goal

Align the Julia genetic GLLVM objective with its symbolic model, return invariant trait breeding values, and test ordinary starts before exposing the bounded R route.

## 2. Implemented

The objective note specifies `U = F Λ′ + D`, `G = ΛΛ′ + diag(ψ)`, pedigree covariance, link-scale trait modes, and the fixed-and-genetic-effect integrated Laplace objective. The fitter returns q-by-T conditional trait effects in `breeding_values` rather than q-by-K factor scores. The selected Poisson fixture is tested from default and ordinary loading starts. All-zero Poisson traits with an intercept and rank-deficient `X` are refused; the Poisson intercept starts at log trait mean for finite nonzero counts.

## 3a. Decisions and Rejected Alternatives

The historical `fit_gllvm_laplace_reml` function name remains for compatibility, but documentation does not call its non-Gaussian value ordinary ML or REML. The Gaussian reduction is checked separately. The accepted Poisson cell is pure low rank at K=2; non-Gaussian FA uniqueness and automatic rank selection are later work.

## 4. Files Touched

`src/genetic_gllvm.jl`, `test/genetic_gllvm_trait_effects.jl`, `test/runtests.jl`, `docs/design/genetic-gllvm-objective-contract.md`, `src/validation_status.jl`, generated `docs/src/validation-status.md`, `docs/design/capability-status.md`, `docs/design/validation-debt-register.md`, `ROADMAP.md`, `GATES.md`, and `docs/dev-log/check-log.md`.

## 5. Checks Run

Focused Julia tests passed across four testsets: 4/4, 7/7, 9/9, and 5/5. The deterministic T=3, K=2 pedigree fixture converged from default and three ordinary starts with objective spread below `1e-5`. The final full `Pkg.test()` suite passed from a writable content-identical source copy (`/private/tmp/hsq-fa-gllvm-pkg-test-20260927-final4.log`); earlier reruns exposed stale text assertions, a comparator write restriction, and a near-PSD G contract that were repaired. The final local docs build exited 0 from the writable copy (`/private/tmp/hsq-fa-gllvm-docs-20260927-final2.log`).

## 6. Tests of the Tests

The trait-effect test constructs `F Λ′ + D` directly and checks rotations, trait order, and pedigree animal order. Invalid-input tests check all-zero Poisson with an intercept, rank-deficient fixed design, and high finite counts. The ordinary-start test does not initialize at true loadings. The Gaussian reduction compares to the Gaussian REML objective at the same covariance.

## 7a. Issue Ledger

Fixed: q-by-K factor scores masquerading as breeding values, an improper Poisson intercept cell falsely converging, high-count zero-start instability, and misleading objective labels. Open: independent same-objective pedigree comparator, broader recovery, non-Gaussian FA, and source-review wave findings outside this bounded cell.

## 8. Consistency Audit

R and Julia payloads agree on q-by-T trait modes, link-scale G/correlations, and the bounded T=3, K=2 route. The Julia status row stays partial and the public covered count stays seven. Rose's final audit is clean with limitations for the bounded partial claim and blocks broader covered or release wording.

## 9. What Did Not Go Smoothly

An initial recovery study started at true loadings, so it did not establish ordinary user starts. A direct ordinary-start check was added. A default Poisson intercept at zero destabilized large finite counts, and an all-zero trait produced a misleading converged result; both prompted negative regressions.

## 10. Known Residuals

This report closes only the foundation edits as a candidate. Source-review findings, a same-objective external comparator, response-scale summaries, and panel/CI gates remain open. The full Julia suite and local docs build passed from the writable source copy.

## 11. Team Learning

Memory receipt: `route.py HSquared.jl`, the brain auto-rank D-293 note, and the repo objective/status notes informed scope. Golden Set: not run; deterministic reduction and negative tests are the scoped checks. Factor scores are coordinates; users need trait genetic effects for breeding-value interpretation.

## 12. Cross-Product Coverage

Covers: the bounded Poisson T=3, K=2 pure low-rank pedigree objective, approximate conditional modes on the link scale, rotation/ordering invariance, and ordinary-start convergence on one deterministic fixture.

This foundation does NOT cover broad non-Gaussian calibration, Bernoulli, mixed families, FA uniqueness, missing records, response-scale heritability, automatic rank selection, loading inference, or public covered status.
