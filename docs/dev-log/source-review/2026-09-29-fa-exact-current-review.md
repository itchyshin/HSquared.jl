# 2026-09-29 exact-current FA review and comparator

This note records a bounded A2 update for the current Julia candidate. It
does not give full A2 signoff or promote FA.

## Exact candidate

- HEAD: `a7ca8ed557b23ec23c8486365e97a7bac4b71c16`
- `src/multivariate.jl`: `fc41aefefb61b2cc915d4f802b0017dc4daea5daa795a9d3421854e9c4958670`
- `test/test_multivariate_fa_multistart.jl`:
  `fcbb950845737a5b59aa6657a646a58486a55b530d86f03827bec6289f76d5b4`
- `test/test_fa_uniqueness_interior.jl`:
  `56022f372d787cbbe0e21a28d650f28f67b51d4593ebe5f0fbc00d79804c3d72`
- `test/test_fa_ordinary_start_driver.jl`:
  `1a4127ef91bfd160d1879f424c759be8de7ae912b3957f65c3c38d429b32934f`

The source hash was unchanged across the local test and comparator sequence.
The current exact-source focused tests passed 91 assertions: uniqueness-map
rank 29 and multistart/start, optimizer, unit, and fitted trait-permutation
checks 62. The earlier 80-assertion run used the preceding multistart test
hash `ad018c...`.

## Panel dispositions

Kirkpatrick gave a **conditional component signoff** for the T=4, K=1
covariance and interpretation contract. Noether gave a **conditional
mathematical pass** for the covariance map. Both confirm
`G = Lambda Lambda' + diag(psi)`, separate unstructured residual covariance,
and the distinction between generic covariance-map rank and fitted-likelihood
information. At the generic tested point the production map has rank 8; at the
registered sparse-loading point it has rank 7. The `1e-4` uniqueness floor is
an absolute trait-squared constraint and breaks exact scale equivariance near
the floor.

Rose's claim audit is **clean with limitations**. Julia capability wording
remains confined to the bounded T=4, K=1 engine cell; the R route remains
partial. The former source-review note used hash `a28d88...` while calling the
review current. This exact-hash re-review supersedes that attribution for
`fc41...`; the earlier findings remain historical. Rose found no capability
row or covered-count change warranted.

Kirkpatrick and Noether also reviewed the added fitted trait-permutation
assertions on multistart test hash `fcbb950...`; both passed the mapping for
this T4K1 fixture. The test permutes response columns, loading rows,
uniqueness entries, residual covariance axes, and labels consistently. It
checks fitted G/R, uniqueness, heritability, fixed effects, animal IDs, EBV
columns, and likelihood. It uses one truth-informed start and does not establish
default-start permutation behavior.

## Same-model R/Julia REML comparison

The base-R BFGS reference and HSquared.jl Nelder-Mead fitter used
the same 12-animal, 24-record, four-trait pedigree fixture, trait intercepts,
T=4/K=1 FA covariance, unstructured residual covariance, REML constant, and
`1e-4` uniqueness floor. The R and Julia harnesses build and optimize the
objective independently. R 4.6.0 converged in 1.033 seconds; Julia 1.10.0
converged in 5,500 iterations and 2.565 seconds after package load.

- R log likelihood: `-149.673026622690`
- Julia log likelihood: `-149.673015078209`
- Maximum absolute difference in G: `7.2491e-6`
- Maximum absolute difference in R: `1.5804e-5`
- Cross-evaluated R/Julia log likelihoods reproduce each optimizer's value to
  printed precision.
- Independent EBV recomputation agrees with the Julia payload within
  `3.22e-15`.

Both optimizers reached a boundary-prone solution: two uniqueness estimates
were within `5.1e-6` of the absolute floor. The comparison checks
implementation agreement on one truth-informed fixture. It does not show
global optimality, routine-start recovery, population reliability, fitted likelihood information, uniqueness
identification, interval calibration, or broad R-Julia bridge parity.

Harnesses and SHA-256 values:

- `/private/tmp/fa_same_model_reference.R`:
  `af37c74414a31574d7032d3f0db13bbabd384fe7b21879fc36456a79411c9784`
- `/private/tmp/fa_same_model_reference.jl`:
  `d645a93faaf82213df522c96c4d13e89a7edc222eb2ba330ffa51194bcd90c91`
- `/private/tmp/fa_same_model_crosscheck.R`:
  `cebeeea2864e1683345ef976c93d414b10ab993763ff9ddb1e7d4e0cc79bd7ba`

## A2 disposition

A2 remains **open**. Still required are routine-start recovery evidence,
fitted-likelihood information and genetic/residual separation checks, broader
trait-order coverage, the held multi-seed study, the remaining FA source spans,
and whole-wave panel signoff. The one-fixture fitted trait-permutation check is
now recorded. The estimated 200-seed run remains held
for explicit approval. No GPU work, release submission, registry submission,
merge, or tag occurred.
