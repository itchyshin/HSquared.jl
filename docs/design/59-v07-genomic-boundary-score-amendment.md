# v0.7 genomic boundary score amendment

Date: 2026-09-29

## Scope

This amendment applies only to the experimental genomic closed-boundary profile
resolver in `src/likelihood.jl`. Frozen design 46 remains unchanged, including
its SHA-256 seal and its finite-difference oracle. This note records the current
candidate's deliberate change to endpoint scoring and endpoint-adjacent
candidate comparison.

## Why the candidate changed

The frozen `delta = 1e-6` endpoint difference can have the opposite sign from
the one-sided score when a strict interior optimum lies much closer to zero
than `delta`. The previous implementation also replaced a successful refined
candidate within `1e-7` of an endpoint with its coarse-grid value. Together,
those rules classified a strict interior optimum as `boundary_lower` in a
positive-definite three-observation example.

The current candidate calculates the exact derivative of the profiled REML
objective at both endpoints. Let `D = diag(lambda - 1)`, where `lambda` are the
eigenvalues of `K`, `H(r) = I + r D`, `P = H^-1 - H^-1 X (X' H^-1 X)^-1 X' H^-1`,
and `u = P y`. With `t_hat = y' P y / (n - p)`, the derivative per observation is

```text
ell_R'(r) / n = -[tr(P D) - u' D u / t_hat] / (2 n).
```

The score uses the same lower and upper KKT signs as design 46. The bounded
optimizer's refined likelihood is retained even when its ratio is endpoint
adjacent. Such a candidate cannot be reported as a strict interior fit; if its
likelihood beats an endpoint, classification fails closed as
`boundary_unresolved`.

## Verification and evidence boundary

The focused regression uses `n=3`, one fixed effect, identity incidence,
`K = diag(1 + 1e8, 1/2, 1)`, and a known optimum at approximately `2e-8`. It
checks the positive exact lower score, the sign reversal in the frozen finite
difference, and the unresolved classification. A separate multi-column fixed
effect fixture compares the analytic lower and upper scores with one-sided
finite differences at moderate condition numbers. Missing/non-string
provenance and typed numerical exception handling are covered in the same
focused test file. The current candidate also returns `boundary_unresolved`
when an endpoint-adjacent refined candidate improves on its corresponding
exact endpoint, even when that improvement is within the likelihood tie
tolerance. It checks internally derived genetic and residual variances before
the gradient or likelihood call; nonpositive, nonfinite, or reciprocal-overflow
values are reported as an unresolved representation rather than passed into
the likelihood. A three-observation subnormal-scale fixture exercises that
fail-closed path.

The historical doc-46 holdout result does **not** validate this amended score
or the changed endpoint-adjacent comparison. No broad boundary calibration,
upper-endpoint near-threshold recovery, or matched R-oracle comparison is
established here. The resolver remains experimental; capability status and
public covered count do not change. No release, registry, GPU, or tag action is
authorized by this amendment.
