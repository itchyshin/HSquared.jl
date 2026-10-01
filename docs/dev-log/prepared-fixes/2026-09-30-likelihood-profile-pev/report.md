# Likelihood profile, PEV and scalar repair proposal, 2026-09-30

## 1. Goal

Prepare a bounded scratch proposal for LH11 profile-root failure handling, LH12 PEV alignment/domain, and the Gaussian h²/bootstrap portion of LH13. Source base is likelihood SHA-256 `90cc76897c2b977f4bebc456d1e6c8d8f2647a7bb7ec6e8c9135884da0f17e30` at candidate HEAD `6271cfd58651e69cd27a64dcf02cb8960a29e260`. This is a component proposal, not whole-file approval.

## 2. Implemented

- `_profile_root`: finite coordinates, finite evaluations, strictly negative anchor, overflow-safe midpoint, explicit unresolved-budget error. Ordinary roots and legitimate clamps are preserved. The target's continuity and scientific reference maximum remain caller assumptions.
- `_reliability_from_pev`: unique exact ID-set matching and denominator reordering into caller PEV order; finite nonnegative converted PEV; finite positive converted additive component and relationship diagonals; exponent-scaled ratio. Reliability remains unclipped and can be negative. Caller-certified relationship diagonals are still caller-certified.
- `_gaussian_variance_fraction`: finite nonnegative converted components with at least one positive, scaled sum, used by both Gaussian heritability extractors and bootstrap point/accepted-refit ratios.
- `_bootstrap_usable_refit`: validates components after Float64 conversion. Strictly positive finite components remain acceptable when their sum overflows, because their h² is representable.
- Corrected nearby profile documentation that previously described failed non-PD precision as a clamped endpoint. Documented PEV order/domain and safe h² arithmetic.

## 3a. Decisions and Rejected Alternatives

Contracts and primary tests were frozen before implementation (`contracts.md`, primary test hash below). Reordering denominators preserves the established return ID order; rejecting all reordered PEV would unnecessarily narrow reuse. Mantissa/exponent arithmetic avoids intermediate over/underflow without arbitrary precision in production. BigFloat is used only as an independent test oracle. Zero Gaussian components remain valid summary inputs when total variance is positive, while bootstrap accepted refits still require strict interior components. No optimizer or nuisance-profile redesign was performed. No original-fit convergence or bootstrap acceptance-threshold changes were bundled in this repair.

## 4. Files Touched

All files are beneath this owned scratch directory only. `src/likelihood.jl` is the proposed source; `baseline-likelihood.jl` is the exact original. `likelihood.patch` contains only scoped edits with repository-relative paths. `test/likelihood_profile_pev_contracts.jl` is the frozen primary test; `test/analytic_controls.jl` contains independent supplied-variance controls; `test/existing_bootstrap_convergence_contract.jl` is an unchanged copied regression test. `package/` is a copied source/Project/Manifest execution fixture, with the proposed likelihood substituted. `contracts.md`, `red.log`, `green.log`, `final-green.log`, `pins.json`, and this report retain evidence. Live source, runner, Git index, commits, and other lanes were untouched.

## 5. Checks Run

Julia 1.10.0, `--compiled-modules=no --startup-file=no`; JULIA_NUM_THREADS=1 and OPENBLAS_NUM_THREADS=1, both measured as 1. Existing Project/Manifest and depot `/private/tmp/hsq-goal-julia-depot:/Users/z3437171/.julia` were reused without resolve/update. Each tiny helper run was estimated below two minutes before launch. No statistical optimizer, simulation, campaign, GPU, remote compute, or package-wide suite ran.

Final run exited 0: primary contracts **71/71**, independent supplied-variance controls **23/23**, existing bootstrap convergence regressions **4/4**. Test-body times 1.2 s, 2.3 s, and 0.0 s; package startup was not separately timed. Final live source remained `90cc...`, and HEAD remained `6271cfd...`. After the parent announced the genomic G2-G6 integration, the likelihood was remeasured unchanged and `git apply --check likelihood.patch` against the live candidate exited 0. The no-index whitespace check emitted no errors (exit 1 denotes the expected difference).

The R report validator printed `after-task structure check passed`. The broader closeout compiler then returned HOLD because the existing parent-cwd `.unlazy/h2-fixer/GATES.md` and `.unlazy/h2-test-campaign/GATES.md` have UNMET gates. Those programme gates were not changed or bypassed; the bounded proposal is ready for independent parent review, while the whole programme remains unfinished.

Reproduction (from any directory):

```sh
env JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 JULIA_DEPOT_PATH=/private/tmp/hsq-goal-julia-depot:/Users/z3437171/.julia julia --compiled-modules=no --startup-file=no --project=/private/tmp/hsq-likelihood-profile-pev-fix-20260930/package -e 'using LinearAlgebra; println("Julia=", VERSION, " JuliaThreads=", Threads.nthreads(), " BLASThreads=", BLAS.get_num_threads()); include("/private/tmp/hsq-likelihood-profile-pev-fix-20260930/test/likelihood_profile_pev_contracts.jl"); include("/private/tmp/hsq-likelihood-profile-pev-fix-20260930/test/analytic_controls.jl"); include("/private/tmp/hsq-likelihood-profile-pev-fix-20260930/test/existing_bootstrap_convergence_contract.jl")'
```

## 6. Tests of the Tests

Primary test SHA-256 was frozen as `12bb5e71235cca4f6317b1e4db7cef3626eb04a84aa46b8e8dc381250b58a828` before code edits and is unchanged. Original-source run exited 1: 28 pass, 38 fail, 1 error (67 reached). The error was the reproduced rejection of zero PEV when the mathematically positive denominator product underflowed; it prevented four later controls in that testset. This was a source behavior failure, not a fixture/load error. Scratch primary green reached all 71 checks.

Independent controls use a hand-written 4-by-4 Henderson coefficient matrix and its inverse, checking both AnimalModelFit and HendersonMMEResult through dense, selected-inverse and auto PEV/reliability paths. Extreme scalar comparisons use 256-bit BigFloat arithmetic and exact 3/5. All result containers are explicitly constructed supplied-variance fixtures (`constructed_nofit`); convergence metadata is not evidence of optimization. Bootstrap refit acceptance and ratio wiring were tested as helpers and read statically; bootstrap simulation/refitting was not executed.

## 7a. Issue Ledger

- LH11: scoped root finite/bracket/budget repair proposed and checked. Nuisance optimizer convergence/search-rail checks, source-fit convergence/maximality, and calibration remain OPEN.
- LH12: scoped caller PEV ID alignment/domain and safe finite ratio repair proposed and checked. Arbitrary conditioning, consistency of a caller-supplied relationship diagonal and resource guarantees remain outside scope.
- LH13: Gaussian two-component summary/bootstrap ratio and converted bootstrap acceptance repaired in proposal. Direct-maternal correlation, squared delta totals and other summaries belong to other lanes or remain open.
- LH17: legacy payload shape, original bootstrap fit checks, untyped catch/failure taxonomy and minimum surviving-replicate count are untouched. No payload expansion or provenance field was added.
- LH01-LH10, LH14-LH16: no closure asserted. Neighboring ingress/control/numerical repairs belong to the parent and other workers.

## 8. Consistency Audit

Graft callers queried before edits for `_profile_root`, `reliability`, `_bootstrap_usable_refit`, and `heritability`. Overloaded extractors have incomplete graph edges, so exact current definitions and their immediate call sites were read. Current non-Gaussian `laplace_reml_interval` uses the same profile root and already validates finite/converged point/profile likelihoods; the stricter root contract is compatible with its negative-anchor likelihood-ratio construction. No non-Gaussian source or fitted interval was changed/tested here. Both Gaussian h² methods and both reliability methods route through their shared guard/arithmetic helpers. Bootstrap computes accepted h² before pushing any replicate components. The legacy payload fields remain unchanged.

## 9. What Did Not Go Smoothly

Graft cache refresh could not write `.cache/.sync.lock` (EPERM); exact current source coordinates/hashes were used. Brain retrieval returned broad historical leads, which were not used for numerical conclusions. The red run's expected domain exception stopped four later primary tests; the unchanged green test reached them. Existing shared-lane preflight findings were respected by writing only the assigned scratch directory. One combined instruction read was output-truncated; relevant skill bodies and report headings were read separately/as available.

## 10. Known Residuals

No whole likelihood approval, actual fitted-model extreme-scale approval, inference calibration, Gaussian nuisance-search certification, full-suite pass, production-memory guarantee, release authorization or public capability expansion follows from this proposal. Profile continuity and maximum validity cannot be established by bisection guards. A finite relative error is still ordinary floating-point arithmetic. Bootstrap's generic predicate assumes a numeric model-shaped object; malformed field types may throw rather than return false. The original-fit checks and broad catch behavior remain visible in the parent review receipt.

## 11. Team Learning

Memory receipt: route.py LOAD-FIRST, canonical lane instructions, 00-INDEX, WHAT-WORKS, and symbolic-alignment/test-driven-development/validation-harness/verification skills guided scope and test order. The Codex memory registry was queried for routing only; no historical numerical result was promoted. Golden Set: exact second-wave receipt, exact original likelihood, unchanged bootstrap convergence regression and independent analytic controls. The broad memory-regression tool was not run for this component proposal. Durable lesson: validate the arithmetic that is consumed after conversion; preserve the estimand through scaling rather than rejecting a finite ratio solely because an intermediate sum or product overflows.

## 12. Cross-Product Coverage

Covers Gaussian AnimalModelFit/HendersonMMEResult scalar summaries, reused PEV alignment, finite profile-root inversion, and bootstrap accepted-component predicates/ratio wiring. It **does NOT cover** Gaussian nuisance optimization, fitted non-Gaussian intervals, direct-maternal/repeatability inference, multivariate summaries, bootstrap coverage, simulations, R bridge/schema, GPU or releases.

Proposed scoped registration: copy primary test to `test/likelihood_profile_pev_contracts.jl`, analytic controls to `test/likelihood_profile_pev_analytic_controls.jl`; add exactly those two includes near the existing bootstrap convergence contract include. Preserve the existing bootstrap test/include. Parent owns registration and combined integration; this worker did not edit the runner. Apply only `likelihood.patch`, never overwrite the parent’s concurrently edited whole source with this snapshot.

Exact proposal inventory:

| Artifact | SHA-256 |
| --- | --- |
| src/likelihood.jl | 0a0ed083e23f7e2131133ba238d65d1edcff45c7b516673f9e16148f14bd8019 |
| likelihood.patch | 31bbfdfb5c27987158f66e8359eb3e484d9d957bc37fc8e273ac632a444e03c1 |
| contracts.md | 1240ec14bf6bb1f6428bc1c30b5df0b3375d328cd32ac14193c92b07855a634a |
| test/likelihood_profile_pev_contracts.jl | 12bb5e71235cca4f6317b1e4db7cef3626eb04a84aa46b8e8dc381250b58a828 |
| test/analytic_controls.jl | 2f0052579bcd63b2529d6979d9f58955d64381f9f75bee004cbe1b8df5ebfd42 |
| unchanged bootstrap test | ba4ae9c3dfa977dd156781102af708db4ca155ebb2adf6b79e4f6c81b2992df6 |

`pins.json` also records every copied source/dependency and retained log. Graft tool-estimated avoided reads total 400,127 tokens; this is not measured model-token usage.
