# FA weak-direction deterministic check, 2026-09-30

PASS: 36/36 new assertions, plus 4/4 existing helper assertions. Julia 1.10.0, one Julia thread and one BLAS thread. Printed matrix-test timings: 0.5 seconds per testset. Estimate stated before execution: under one minute. No fit, RNG draw, simulation, optimizer, GPU call, source edit, driver edit, or repository write occurred.

The first command stopped during package loading with EPERM on the compiled-cache pidfile. The permitted retry with `--compiled-modules=no` exited 0. Full successful output is `run.log` in this scratch directory.

```sh
OPENBLAS_NUM_THREADS=1 JULIA_NUM_THREADS=1 \
HSQUARED_FA_INFORMATION_HELPER='/Users/z3437171/.codex/worktrees/hsquared-fa-gllvm-foundations/HSquared.jl/test/test_fa_likelihood_information.jl' \
julia --project='/Users/z3437171/.codex/worktrees/hsquared-fa-gllvm-foundations/HSquared.jl' \
  --startup-file=no --compiled-modules=no \
  /private/tmp/fa-weak-direction-20260930/test_fa_weak_direction.jl
```

| epsilon | Information rank at relative threshold 1e-8 | Minimum/maximum eigenvalue | Standardized directional information |
| --- | --- | --- | --- |
| 0 | 17/18 | 1.6842173434477085e-17 | 3.0582316242457447e-16 |
| 0.01 | 18/18 | 1.5249482458536264e-5 | 0.0007187037064672384 |
| 0.001 | 18/18 | 1.5247144561941927e-7 | 7.185853062817942e-6 |

The directional information contraction ratio was 0.009998352586964854, satisfying the declared less-than-0.1 criterion. Positive unit changes and trait permutation passed eigenvalue and mapped-direction invariance checks, including relative-only checks of both positive weak-direction quadratics.

Negative controls: the correct null-direction residual was 1.4165255149211353e-17 relative to the information operator norm. Deliberately changing the first uniqueness cancellation from -2 to -1 produced 0.06734119796930865, failing the scientific null criterion of at most 1e-8. Reversing the epsilon contraction also failed the same contraction oracle. These rejected controls are asserted by the green suite; no intentional failing assertion is shipped.

All dependency hashes matched before and after execution:

| Dependency | SHA-256 |
| --- | --- |
| `src/` tree | `d3c2de8d7f0a1a86918f15938264bbdc892a7303b5ddd488553ac923f073ad0a` |
| `src/multivariate.jl` | `fc41aefefb61b2cc915d4f802b0017dc4daea5daa795a9d3421854e9c4958670` |
| `test/test_fa_likelihood_information.jl` | `e7e1987cc042db23b813b5c4fc23b5d4b925e3f618636a18ba282ecea77bef71` |
| `Project.toml` | `37f0e6aaa6492c76519ed7771b226972cea531a7104866e5753890e31e163033` |
| `Manifest.toml` | `c5940f2be0347f7ff987468aed67f17070f556a0aa99e0e5ec5317898cfa0fad` |

New test SHA-256: `158ae089596b4c2bcf9e1fd889e0777771776d11c417359a9aba350fe6b82b5c`.

Proposed parent integration: copy the new file to `test/test_fa_weak_direction.jl`; register it immediately after `include("test_multivariate_fa_multistart.jl")` at current `test/runtests.jl:11107`. The helper is already defined there, so its existing testset will not rerun. A standalone invocation after integration loads the adjacent information helper automatically. Source and frozen campaign driver remain unchanged.

Scope: deterministic expected information in natural covariance coordinates for the bounded T4/K1 complete-record Gaussian design. This does not establish observed curvature, fitted-sample recovery, interval calibration, or ordinary-start unit/order agreement. The five-fit sensitivity exercise remains separate.

Em-dash check passed on the new test and this receipt. No additional Graft calls were needed in this follow-up; it reused the earlier source review.
