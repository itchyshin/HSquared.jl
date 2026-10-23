# Isolated multivariate contracts repair, 2026-09-30

## Scope

Parent-owned proposal for MV01-05 and bounded MV06 findings from current complete source disposition. Source originalfc41aefefb61b2cc915d4f802b0017dc4daea5daa795a9d3421854e9c4958670, HEAD6271cfd58651e69cd27a64dcf02cb8960a29e260. No live source or runner changes. Proposed final pins in pins.json. Independent review pending.

## Implementation

Exported lowrank/FA builders now reject nonfinite reconstructed covariance. Shared label validation checks dimension, missing/nothing, empty and duplicate string-normalized IDs/traits before numerical model work, while preserving supplied valid values/order. MME checks fixed-effect rank; both REML fitters require positive residual degrees of freedom and iterations; repeatability shares observed-rank rejection. Supplied-covariance MME may have saturated fixed effects because no variance estimation occurs.

Finite differences require original/converted finite-positive steps with representable positive squares, and finite converted coordinates whose two perturbations are finite and distinct. Unconverged multivariate fits are refused by SE/interval routes. Boundary/model data and calibration remain separate limitations. The interval catch only relabels ArgumentError; other programming exceptions propagate. Pair-subset normalization and synthetic result authenticity remain caller contract debts.

Nested LRT refuses original/converted nonfinite likelihoods. Positive-infinite chi-square statistics have tail zero, so finite likelihood differences that overflow are handled. NaN statistic rejects. Existing moderate calculations and mixture tokens are preserved; wording states their conditional model assumptions. Documentation corrects RNG, REML comparison, exported MME and active dedicated R repeatability-route claims. It distinguishes documented recovery cells from broad calibration.

## Test evidence and chronology

Frozen source primary96 controls produced27PASS/69FAIL/0ERROR,9.2seconds; the first unwrapped construction attempt reached6PASS/2FAIL and stopped, retained. Prepared numerical code then passed96/96. Added11 neighbor controls cover a finite FA uniqueness sum overflow and two extra invalid label cases. Final numerical source passed107/107,8.7seconds, processexit0. Last changes were precisely two docstring replacements; source-before-final-prose.jl retains the tested source, and independent review must execute the final source. Every runtime invocation was estimated under one minute before launch with Julia1/BLAS1; no campaign or deliberate recovery fit ran. Old malformed/saturated fit controls can enter their old tiny optimizer before rejection; this is included in baseline runtime. Parent direct preliminary helper probe omitted its visible estimate, recorded in the source disposition.

The test has analytic quadratic Hessian/Jacobian controls, exact lowrank/FA matrices, exponential chi-square df2 tail, single-boundary mixture algebra, finite huge statistic limits, zero-callback invalid-step checks and a hand-derived supplied MME beta15/7,26/7. Label precedence uses invalid precision as a sentinel and checks the label error itself. It is not a mirrored output-count oracle.

## Integration and residuals

Patch applies to live fc41 source and introduces one test file. Register it once in a distinct module in the current runner after independent review. Do not replace the complete dirty source from a different branch. Existing FA optimizer/objective/start-selection bodies and absolute uniqueness floor are unchanged. The immutable200-seed campaign remains at its frozen source/driver pins; this proposal requires explicit function-level reconciliation, not a new campaign.

This slice does NOT cover observed/expected-information calibration, general optimizer reliability, ordinary-start recovery beyond retained cells, general missingness, loading inference, automatic rank, generic payload authenticity, trait-pair selector redesign, performance or GPU. Fit-point and matrix-constructor positive results remain validation-scale. Full A2/E1/V3 remain open. Next: independently review final code, run107 controls and appropriate neighboring signed tests, then compose/test/apply under a new source pin.
