# A2 remaining acceptance design: bounded Gaussian T4/K1 FA

Kirkpatrick independent acceptance review, 2026-09-30. Design only. No fits, simulations, source edits, driver edits, GPU work, commits, or campaign intervention were performed. This file is the sole written artifact.

## Recommendation

Close the remaining scientific diagnostic portion of A2 after (1) honest closeout of the frozen ordinary-start campaign, (2) one deterministic weak-direction check, and (3) a small ordinary-start unit/order sensitivity check on an existing fixture. Retain the experimental, complete-record Gaussian T4/K1 pedigree scope. Acceptance means the engine has been checked and its limitations are exposed; it does not mean reliable recovery on every sample, calibrated uncertainty, broad FA support, or a covered-status promotion.

The present campaign has no preregistered campaign-level pass cutoff. Its recovery rate must therefore be reported with its denominator and uncertainty, not retrospectively converted into a pass criterion. A poor rate can support an explicit usability restriction or a later optimizer patch; it cannot honestly support a broad reliability claim. Interval calibration and loading inference are separate debt because this route does not offer them.

## Candidate and evidence pins

Candidate: `/Users/z3437171/.codex/worktrees/hsquared-fa-gllvm-foundations/HSquared.jl`, branch `codex/hsquared-fa-gllvm-20260927`, HEAD `a7ca8ed557b23ec23c8486365e97a7bac4b71c16` plus existing dirty work. Other lanes' work was preserved. Parent owns the campaign and integration.

Live recomputation using the driver's sorted relative-path/NUL/file-bytes/NUL algorithm matched source-tree SHA-256 `d3c2de8d7f0a1a86918f15938264bbdc892a7303b5ddd488553ac923f073ad0a`. Driver algorithm: `sim/fa_ordinary_start_recovery_20260928.jl:98-111`.

| File | SHA-256 verified during this review |
| --- | --- |
| `src/multivariate.jl` | `fc41aefefb61b2cc915d4f802b0017dc4daea5daa795a9d3421854e9c4958670` |
| `test/test_fa_likelihood_information.jl` | `e7e1987cc042db23b813b5c4fc23b5d4b925e3f618636a18ba282ecea77bef71` |
| `test/test_multivariate_fa_multistart.jl` | `e621d60892c9ec9ceab6a1b06d051495d2aa1b9d6c70346023129a993b2d9085` |
| `test/test_fa_uniqueness_interior.jl` | `56022f372d787cbbe0e21a28d650f28f67b51d4593ebe5f0fbc00d79804c3d72` |
| `docs/design/fa-t4k1-identifiability-and-units.md` | `a0743bc517ff797cd648d8cadd6ce0057b28bfaaeece524ad8ffd6207df5ec4d` |
| `docs/dev-log/source-review/2026-09-30-fa-exact-current-component-review.md` | `e40115d252747da4db7dca9533f1d041861cae18e5dbefbf721d7bdb547c16c6` |
| `sim/fa_ordinary_start_recovery_20260928.jl` | `2161449e2e320a6d56bf5b71b1927e18b3d3b4dd60704d30bae5aaafbf057e9b` |

## Evidence that should be reused

- Production FA-map Jacobian: generic rank 8 and sparse-loading rank 7 are tested at `test/test_fa_uniqueness_interior.jl:33-61`. Do not repeat the entire algebra review.
- Expected REML information: natural loading, uniqueness, and residual coordinates, trait scaling, and full-rank/confounded designs are at `test/test_fa_likelihood_information.jl:5-84`. The fitted-point check at `test/test_multivariate_fa_multistart.jl:151-161` correctly distinguishes natural-coordinate rank from a near-floor constraint.
- Default-plus-balanced selection and status tests are at `test/test_multivariate_fa_multistart.jl:106-178`. Large between-start disagreement is deliberately represented by the fixture.
- Existing fit unit/order tests are at `test/test_multivariate_fa_multistart.jl:180-249`. They use generating covariance starts (`:204-215, :231-237`), so they do not discharge ordinary-start sensitivity.
- The independent R/Julia fit at `docs/dev-log/scout/2026-09-27-fa-same-model-reference.md:133-137` is pinned to older source hash `68f1ec...`; it is useful comparator evidence at that pin. Do not describe it as a fresh exact-current comparator against `fc41ae...` without a focused change-impact reconciliation.
- The current component review reports a full package test pass, but this reviewer did not rerun it (`docs/dev-log/source-review/2026-09-30-fa-exact-current-component-review.md:14-26`).

## Minimum check 1: weak-direction diagnostic

Use the existing 12-animal, two-record pedigree and residual covariance in `test/test_fa_likelihood_information.jl:52-64`. No optimization or new simulation is required.

1. At loadings `(1,1,0,0)` and an interior positive uniqueness vector, evaluate the standardized natural-coordinate expected information using the existing helper. Require numerical rank 17/18 at the existing relative threshold `1e-8`. The missing direction is the FA-map defect; genetic/residual separation remains present in this repeated design.
2. Supply the explicit natural-coordinate direction `v=(1,-1,0,0,-2,2,0,0,0,...,0)` over `(lambda, psi, vech(R))`. Its first-order covariance perturbation is zero at that loading vector. Transform it to the helper's standardized coordinates with `w=S^-1 v`, normalize w, and verify `I_standardized*w` is zero within `1e-8*opnorm(I_standardized)`. This tests a known scientific direction rather than merely an eigenvalue count.
3. Replace the last two loadings by epsilon, for epsilon `0.01` and `0.001`, holding other parameters fixed. Record the whole spectrum, smallest/maximal eigenvalue ratio, and `w' I_standardized w`. Require a finite positive directional information value and at least a tenfold decrease toward the smaller epsilon; the analytic first-order covariance perturbation is proportional to epsilon, so the leading information decays quadratically. This criterion is deliberately looser than an exact factor of 100. Check failure against the direct derivative formula before changing any threshold.
4. Apply the existing positive unit multipliers `(2,0.5,1.5,0.8)` and permutation `(3,1,4,2)`. Require eigenvalue spectra and the mapped directional quadratic to agree at `rtol=1e-7` (small eigenvalues use an absolute tolerance scaled by the largest eigenvalue). Eigenvectors themselves have arbitrary signs and can rotate in tied eigenspaces. Compare mapped subspace projectors if inspecting more than one weak direction.

Record rank, condition ratio, weak-direction composition, and floor status separately. A full-rank expected-information matrix is neither observed curvature nor a statement about interval accuracy. If a curvature diagnostic is later added in log-excess uniqueness coordinates, label the chain rule explicitly: `d psi_i/d theta_i = psi_i - 1e-4`. Its collapse near the floor is distinct from nonidentification in natural variance units. No inverse-information interval is needed for this check.

## Minimum check 2: ordinary-start unit/order sensitivity

Reuse the exact generated dataset from the existing 40-animal, five-record fixture (`test/test_multivariate_fa_multistart.jl:181-203`, seed 20260929). Retain its generating covariance solely for reconstruction and fixed-covariance oracle checks. Omit `initial` in all fits.

Freeze five calls before running: baseline; two positive unit maps `D1=diag(2,0.5,1.5,0.8)` and `D2=inv(D1)`; permutations `(3,1,4,2)` and `(4,3,2,1)`. Use the existing test cap of 10,000 per start for this optimizer comparison, clearly separated from the 5,000-cap primary recovery method. This is five ordinary-start fits, not a new recovery campaign. Estimate runtime from existing same-fixture logs before execution and use capped CPU resources. If fixture generation cannot be reused without triggering unrelated tests, extract the generator into a scratch harness with the original seed and full data hash.

For each returned fit, retain both start statuses, objective range, selected start, better-nonconverged flag, uniqueness values, floor distances, and fitted G/R. Do not demand identical iteration counts or selected-start names.

### Exact model oracle, independent of the optimizer

For complete records with record-level fixed-design rank p, positive D, and n records:

`ell(Y D; D G D, D R D) = ell(Y; G,R) - (n-p) log|D|`.

Trait permutation leaves this likelihood unchanged. The implementation's complete-record convention follows `src/multivariate.jl:762-819`. Test these identities at the original generating covariances and at every finite returned pair, using fixed-covariance likelihood evaluation (`:873-878`), to absolute tolerance `1e-8` on this fixture. A permutation or scale identity failure here is a mathematical/indexing defect, not an optimizer-sensitivity excuse.

Also cross-evaluate GLS beta and EBVs at transformed fixed covariances (`src/multivariate.jl:861-868`): undo scaling/permutation and compare to the originals at numerical solve tolerance. Reorder trait labels consistently. This isolates output mapping from fit quality.

### Optimizer comparison and interpretation

Back-transform each fit to original units/order before comparing covariance matrices. Use one fixed baseline trait metric, such as `S0=diag(sqrt(diag(Gtrue+Rtrue)))`, and errors `norm(S0^-1 (G_a-G_b) S0^-1) / norm(S0^-1 G_b S0^-1)` (likewise R). Do not let each fit choose a different standardization. Raw Frobenius differences under unequal trait rescaling are not invariant. Current start-disagreement fields use raw Frobenius norms (`src/multivariate.jl:1105-1117`); those fields are descriptive in the input units.

Use the existing bounded regression targets as a declared agreement check: corrected loglik differences at most `2e-3`, covariance relative differences at most `2e-3`, and mapped beta/EBVs with relative `2e-3` plus absolute `1e-5`. Compare K1 loadings only after one global sign alignment; G, R, and mapped predictions are the primary targets. A tied largest loading can alter the package's sign convention after permutation.

Classify each case:

- **Interior agreement:** both fitted uniqueness vectors and their mapped counterparts exceed `0.01`, both fits converge, and mapped comparisons meet the targets. This supports ordinary-start equivariance only on this fixture and these transformations.
- **Floor-constrained:** transformed uniqueness approaches or crosses the fixed floor, or the fit is near it. Report results, but withhold an optimizer-equivariance claim for that comparison. The global feasible sets differ under rescaling even if one chosen point is feasible in both. Merely observing a positive distance above the floor does not prove a common global optimum.
- **Optimizer sensitivity:** fixed-covariance identities pass, but converged returned fits or their status differ outside targets. Preserve the failure as measured usability evidence. One optional mapped-start diagnostic per failed transformation can locate the issue, with no replacement of the ordinary-start result. A common objective basin can be checked by mapping the better feasible solution; it is not proof of a global optimum.
- **Correctness failure:** fixed-covariance identities fail, returned likelihood disagrees with direct reevaluation, G reconstruction fails, trait labels/predictions are misordered, or diagnostic status misrepresents the chosen attempt. Repair and rerun the affected narrow tests before bounded acceptance.

If all five ordinary fits are near the floor, do not seed-shop for a favorable interior case. Keep the ordinary-start limitation explicit, retain the existing truth-start interior result at its proper scope, and ask the panel whether that usability boundary is acceptable for this experimental cell. General unit/order robustness remains debt. A finite sensitivity exercise with transparent limitations can close review of the cell without claiming successful unrestricted invariance.

## Minimum check 3: frozen campaign closeout

Follow `docs/dev-log/recovery-checkpoints/2026-09-30-fa-ordinary-start-primary-launch.md:11-20,34-40`: verify 200 unique ordered primary seeds `20261200:20261399`, all 23 columns, source/driver hashes and interpreter/thread metadata, every exception and failed fit retained. Independently recompute per-seed classification, totals, recovery proportion, MCSE, and Wilson interval under the frozen thresholds. Report floor flags and better-nonconverged-start flags even among recovered fits. Separate covariance accuracy from convergence and from the likelihood-at-truth check. The latter does not establish a global optimum.

Keep seed-level diagnostics and report finite-output summaries with their conditional denominator. Do not alter frozen code, thresholds, or seeds to improve the result. Do not require this campaign to estimate intervals or loading coverage that it was not designed to estimate.

## Defects and later patches

One verified wording defect remains: `src/multivariate.jl:939-940` calls the test suite RNG-free despite the registered seeded fixtures. Correct after source-freeze reconciliation; the fix is documentary and does not alter campaign mathematics. Keep both pre-patch and post-patch source fingerprints.

No new blocking numerical defect was found in the reviewed spans. The absolute `1e-4` uniqueness floor (`:374-382,428-439`) is an explicit scale constraint. Replacing it with a scale-aware floor would change the estimator's admissible set and needs a separately declared patch and new evidence. Nelder-Mead's coordinate-dependent path (`:1072-1088`) is an optimizer limitation, not automatically a likelihood defect. Raw start-disagreement norms are unit dependent and need disclosure; replacing them is optional follow-up unless the product claims a unit-invariant reliability indicator.

## Panel acceptance wording and residual debt

Recommended wording after the checks: "A2 reviewed and accepted for the bounded experimental Gaussian T4/K1 complete-record pedigree engine, with the measured ordinary-start recovery result and unit/order sensitivity limitations attached. G, specific genetic variances, and residual covariance have separate meanings; near-floor fits and weak directions are explicitly diagnosed. This acceptance supplies no calibrated loading/uniqueness/evolvability intervals, general optimizer reliability, other-rank identification, missingness coverage, or R-public capability promotion."

The parent must still reconcile remaining engine/R-route spans and obtain the whole-wave panel signoff identified by `docs/dev-log/source-review/2026-09-30-fa-exact-current-component-review.md:24-32`. This design does not sign those spans. Evolvability is computed from the complete G and declared trait metric; low-rank factor covariance alone is not the FA G when uniqueness is positive. A2's tests do not add an evolvability uncertainty claim.

## Review process and verification

Lane preflight and brain routing were read; explicit parent ownership allowed this read-only subreview and scratch artifact. Brain search found no useful A2-specific decision, so repository documents supplied technical truth. Memory was used only for routing/preservation context. Graft map plus two source queries were used before source inspection; its graph could not refresh in the read-only worktree and one span was stale, so quoted source spans were verified directly. Graft tally: 3 calls, approximately 959,056 tokens saved as reported by the tool (709,930 + 106,085 + 143,041); this is a tool estimate, not measured token consumption.

This review executed no Julia test or fit. All proposed acceptance checks above remain proposed. Live source and listed file hashes matched the provided frozen candidate. The artifact was checked for em dashes and restricted to the requested scratch path.
