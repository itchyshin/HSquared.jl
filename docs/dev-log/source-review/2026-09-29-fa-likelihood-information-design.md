# FA fitted-likelihood design information diagnostic

## Scope

Scope is the bounded T4/K1 Gaussian FA design check for separating genetic covariance `G` from unstructured residual covariance `R` at specified interior covariance values. It covers neither fitted-parameter uncertainty nor population recovery, inference calibration, or full A2 signoff.

## Symbolic model and computation

For complete records, `V = H ⊗ G + I ⊗ R`, with `H = ZAZ′`, record-major/trait-fast ordering, and four trait intercepts. The test forms the REML projection `P = V⁻¹ − V⁻¹X_f(X_f′V⁻¹X_f)⁻¹X_f′V⁻¹` and expected covariance information `I_ab = ½ tr(P V_a P V_b)`. The eight FA directions are derivatives with respect to four loadings and four uniquenesses; the ten residual directions are the symmetric `vech(R)` basis. Coordinates are standardized by trait SDs/variances and pairwise trait-scale products.

## Exact candidate and evidence

- Julia candidate: `a7ca8ed557b23ec23c8486365e97a7bac4b71c16` plus current uncommitted worktree changes.
- `src/multivariate.jl`: `fc41aefefb61b2cc915d4f802b0017dc4daea5daa795a9d3421854e9c4958670` (unchanged).
- `test/test_fa_likelihood_information.jl`: `e7e1987cc042db23b813b5c4fc23b5d4b925e3f618636a18ba282ecea77bef71`.
- `test/test_multivariate_fa_multistart.jl`: `e621d60892c9ec9ceab6a1b06d051495d2aa1b9d6c70346023129a993b2d9085` (fitted-point expected-information check and near-floor wording).
- `test/runtests.jl`: `0f187808ca10d67923a995dd5ac933733f828a2a82eb70b4a8e1a2a5bc23ead0`.
- Design note after plug-in-information clarification: `docs/design/fa-t4k1-identifiability-and-units.md` SHA-256 `a0743bc517ff797cd648d8cadd6ce0057b28bfaaeece524ad8ffd6207df5ec4d`.
- Focused exact information test: 4/4 passed, including standardized information eigenvalue invariance under trait-unit rescaling; repeated pedigree design numerical rank 18/18; one-record unrelated design numerical rank 10/18 at the stated relative threshold `1e-8`.
- Focused registered FA test path: 69/69 passed in 1m58s on multistart test hash `b41bafcb76cf459fde0a78a0f5ddd404c7057d8445e80889dcb5da10f70fd4c6`. The final test hash above differs only in the near-floor comment wording. The returned default-plus-balanced fit has standardized expected-information numerical rank 18/18 under the same threshold; its fit diagnostic reports uniqueness near the absolute floor. This is a plug-in expected-information check, not an observed Hessian or calibration result, and it does not certify regular inference near the floor.
- Registration chain: `test/runtests.jl` includes `test_multivariate_fa_multistart.jl`, which includes `test_fa_likelihood_information.jl`.
- `git diff --check` passed on the design/test additions.

## Independent review

Noether reviewed the final contrast definition, Kronecker ordering, information derivatives, standardization, rank interpretation, and test registration at the final design-note hash above. Fisher independently reviewed the same diagnostic and confirmed the confounded design's `G+R` structure and the bounded rank comparison. Both reviewed the fitted-point addition and confirmed that it is plug-in expected information rather than observed curvature or calibration evidence. Fisher's note hash preceded the final notation-only rename from `K` to `H` and prose cleanup; follow-up verified the final hash and resolved the fitted-point description. Neither reviewer reran the test; the 69/69 result is the local exact-candidate run. Both explicitly withheld whole A2 signoff.

## Design conclusion

The generic T4/K1 covariance map has local algebraic rank 8 when all loadings are nonzero, but that alone does not identify `G` separately from `R`. With two records per animal and the stated pedigree, expected information is numerically full rank at the selected interior generating covariances and at one returned default-plus-balanced fit. With one record per unrelated animal, only `G+R` is represented after intercept projection, and expected information has numerical rank 10. The fitted-point result is plug-in expected information, not the observed likelihood Hessian. These calculations establish local design distinctions at the specified values; they do not establish recovery, calibration, or other designs.

## Remaining A2 gates

Routine-start recovery, broader weak-direction and uncertainty diagnostics, inference checks, held multi-seed recovery, remaining `src/` spans, review of the other exact-current files, and whole-wave panel signoff remain open. No capability row, validation debt, or release status changes.
