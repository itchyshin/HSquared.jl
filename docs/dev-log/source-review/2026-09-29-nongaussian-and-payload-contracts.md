# Exact-current source review: non-Gaussian results and payload-v2

Candidate: `codex/hsquared-fa-gllvm-20260927`, HEAD `a7ca8ed557b23ec23c8486365e97a7bac4b71c16`.

## `src/nongaussian.jl`

- SHA-256: `dd3babb8c128a055ec00e204d7e4b43cc753403e51d844f584730c59e61dc05a`.
- Reviewed Laplace/variational fit and payload paths, family enumeration, input constructors, and registered tests.
- Verdict: HOLD pending result-contract and finite-value repairs.
- High: `fit_laplace_reml` selects `r.elbo` for `marginal=:variational` (`1279–1280`), stores it in `NonGaussianFit.marginal_loglik` (`1437–1440`), and `nongaussian_result_payload` exposes it as `loglik` (`1028`). The lower-level result distinguishes `:elbo`, exact `:gaussian_reml`, and `:variational_laplace` (`932–939`), but the fit/payload drops that distinction. Preserve objective kind and lower-bound status, or prevent variational results from using a `loglik` field.
- High: `NonGaussianFit` carries `boundary` and `restart_estimate` (`953–976`), but generic payload omits them (`1017–1030`). A consumer cannot tell a start-dependent search-boundary estimate from an interior estimate. The private three-field payload refuses boundary fits, but this does not fix the generic payload.
- Medium: Laplace and VA entry points convert `y`, `X`, and `Z` without finite-after-conversion guards (`657–669`, `862–874`); Gamma response checks only positivity (`603–605`, `1392–1393`), and `GammaResponse(shape)` admits `Inf` (`170–175`). No current non-Gaussian contract test covers nonfinite `y/X/Z` or infinite Gamma shape.
- Low: accepted `:ordered_probit` and `:gamma` are absent from documented payload family enumerations (`948–952`, `994–1004`). Update the enumerations or reject these families at serialization.
- Positive math checks: observed-curvature Laplace determinant, beta-binomial score/curvature distinction, family kernels, and full-covariance Gaussian VA reduction are coherent. Ordered-probit tail underflow remains explicitly documented at lines 163–168.
- Test pins: `test/test_nongaussian_inner_convergence.jl` SHA `f405a75e14da1be035c9de29cc17accef4dbaedeeb740d0d96f7d44f401cb33c`; `test/wave2_nongaussian_contracts.jl` should also be considered in any patch. Tests cover VA labeling at the low level and inner-convergence, but not the end-to-end payload mismatch or nonfinite cases.

## `src/bridge_payload_v2.jl`

- SHA-256: `c5dbc8295362ca57a5a1dadffc88ae1f9c00f9883ca03dc5888ae68903f8f255`.
- Reviewed schema parsing/dispatch and parity-test coverage.
- Verdict: changes needed for family and finite-input bridge validation; generic-v2 is intentionally not the FA/GLLVM route.
- High: `parse_payload_v2` reads `y/Y` and `X` then method but does not retain or validate top-level `family` (`331–357`). The frozen schema includes `family` (`docs/design/21-payload-v2-multiblock-schema.md:45–64`; schema test `test/test_payload_v2_parity.jl:341–355`). `_dispatch_fit` calls `fit_animal_model` without family (`590–597`), and repeatability dispatch likewise omits it (`661–671`). A non-Gaussian request can silently take the Gaussian default. Explicitly accept the supported Gaussian/identity family or reject unsupported families before dispatch.
- Medium: `y/Y`, `X`, `Z`/partner incidence, and supplied relationship inverse are type-coerced and shape-checked without uniform finite-after-conversion checks (`133–145`, `149–209`, `331–408`). Some downstream routes check finite values, but the parser does not give a stable early error contract.
- Boundary confirmed: `ParsedPayloadV2` has no FA/GLLVM structural fields; its dispatcher does not implement those fits, and the multivariate one-block route deliberately throws (`652–659`). Keep FA and GLLVM on explicit dedicated payload/result contracts rather than routing them through this generic scalar/multiblock parser.
- Positive checks: pedigree ID alignment, second-block reordering, multivariate-repeatability ID/order checks, direct-maternal output ID checks, and Gaussian result field mapping are explicit. Current parity tests cover Gaussian animal/multi-effect cases and malformed dimensions/IDs, not family rejection or finite payload input.
- Test pin: `test/test_payload_v2_parity.jl` SHA `8f281fb60bbc9bf0ccf46559f5152ef32b68148eff1c0457fa01c9abb0dccc73`.

## Lane and evidence limits

Lane preflight found 11 foreign refs with missing changes for `src/nongaussian.jl`, four for `src/bridge_payload_v2.jl`, and two for the payload parity test. The lane census reported one active lane, but historical branches carry work absent from this checkout. No source or test changes were made pending owner coordination. Review verdicts are exact-current and the findings are carried; they are not a signoff on the bounded R routes. The parent's full `Pkg.test()` on this candidate passed, but it does not test the identified end-to-end cases.
