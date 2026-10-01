# 2026-09-29 Wave 2 random-regression contract follow-up

## Pinned candidate and scope

- Candidate HEAD: `a7ca8ed557b23ec23c8486365e97a7bac4b71c16`.
- Final working-tree SHA-256 for `src/random_regression.jl`:
  `e282760b01cfb6b05c1affc6e24089aa66cb575a3bfdaba374b4f27589f73868`.
- Final working-tree SHA-256 for `ROADMAP.md`:
  `68708ec765caf9844d044b59300fd928c530d7a95208d1a333132b9ac30427a4`.
- Final working-tree SHA-256 for `test/wave2_precision_contracts.jl`:
  `ca13fb83ac9d35abcd08a4115e78b229c57283a512da19e0b1f3d88dbf0c0719`.
- This follow-up covers the random-regression portions of W2-03 and W2-07 from
  `2026-09-27-wave2.md`, plus adjacent finite-input guards. It does not close
  Wave 2 or E1.

## Findings and changes

- The original W2-03 random-regression matrix issue was already repaired in
  this candidate: supplied `K_g`, starting `K_g`, and `Ainv` use the shared
  finite, symmetry, and positive-definiteness checks before coercion or use.
- W2-07 remained in the supplied-covariance MME, and the REML path checked ID
  count only after fitting. Both public functions now collect and validate the
  `q` animal IDs before numerical work and return that validated vector.
- Both routes now convert `Z` once, reject nonfinite dense or sparse values,
  and use the checked matrix to build the random design.
- Supplied residual variance and the REML starting residual variance must be
  finite and positive. `rr_heritability` applies the same rule to scalar and
  vector residual inputs. REML validates initial covariance and residual
  values before building the dense design or inverting `Ainv`.
- Docstrings now state the finite-positive residual contract. No fitting or
  capability claim was added.
- Rose found and the candidate corrected two stale neighboring status
  statements. The source header now separates experimental descriptors and
  supplied MME from the covered k=2 dense REML cell, and says broader R routes
  beyond the existing opt-in k=2 `rr()` surface plus a general R model-spec
  remain open. The REML docstring now identifies the existing opt-in R k=2
  `rr()` surface as covered, separate from the Julia engine row, while leaving
  broader orders open. `ROADMAP.md` states the same boundary.

## Independent review

Gauss and Astra independently reviewed the final source hash and confirmed the
ID, finite-`Z`, and finite-positive residual guards are before the numerical
work they protect. Astra's final pass also confirmed the start values precede
design construction and inversion. They reviewed the sparse-`Z` regression
after it was added. Rose checked the final source and roadmap wording against
capability and public-claim rows. These are scoped reviews, not whole-wave
signoff.

## Tests and limits

The focused `test/wave2_precision_contracts.jl` suite passes 105/105 on Julia
1.10.0. Before the guards, the new regressions reproduced solver errors,
silent acceptance of malformed values, or a nonfinite optimizer initialization.
The full package-suite result is recorded in the dated check-log entry.

The descriptors and supplied-covariance MME remain dense, experimental routes;
the covered k=2 REML validation cell is unchanged. This review does not
establish sparse scaling, optimizer reliability, broader Wave 2 signoff, or
E1 completion. Other W2-03 routes and W2 findings remain open.
No simulations, GPU execution, release submission, registry submission, or
tag were part of this slice.
