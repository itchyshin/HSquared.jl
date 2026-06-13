# REML Optimizer Recovery Validation

Active lenses: Curie, Gauss, Fisher, Rose (inline perspectives).
Spawned subagents: none.

## Goal

Strengthen the REML optimizer evidence from "improves over the supplied start"
to "recovers the same optimum." This closes the review finding on the sparse
REML optimizer (`270e7b2`): the prior tests only checked `loglik >= start`, not
that the optimizer lands at the correct optimum.

## Files Changed

- `test/runtests.jl` (new testset "Phase 1 REML optimizer recovery (dense vs
  sparse)")
- `src/validation_status.jl` (V1-SPARSE-REML-OPT evidence)
- `docs/design/validation-debt-register.md` (V1-SPARSE-REML-OPT, V1-OPT evidence)
- `docs/dev-log/check-log.md`, `docs/dev-log/after-task/2026-06-13-reml-recovery-validation.md`

## Implementation

An interior-optimum fixture (8-animal pedigree, one record each) where both
`fit_variance_components(spec; method = :REML)` (dense) and `fit_sparse_reml`
(sparse) optimize the SAME REML objective. The test asserts they recover the
same variance components, heritability, log-likelihood, and EBVs; that a
different starting point reaches the same optimum (multi-start robustness); and
that dense and sparse still agree when the REML optimum is at the σ²a = 0
boundary (a small fixture). No engine code changed — this is validation only.

## Checks

- `julia --project=. -e 'using Pkg; Pkg.test()'`: passed. New testset = 11
  checks. Exploratory fit (recorded): interior optimum σ²a ≈ 1.322,
  σ²e ≈ 0.226, dense == sparse to ~5 digits, logLik = -10.855294; the alternate
  start (3.0, 0.3) reached the same optimum.

## Public Claim Audit

Allowed: the dense and sparse REML optimizers recover the same optimum (variance
components, h², logLik, EBVs) on an interior fixture, robust to the starting
point, and agree at the σ²a = 0 boundary.

Blocked: external comparator parity (ASReml/BLUPF90/sommer/nadiv); fitted Mrode
source-recorded estimates; recovery of a known data-generating truth at scale;
AI-REML. V1-MRODE-FIT and V1-COMPARATORS remain planned.

## Tests Of The Tests

The recovery test would fail for an optimizer that improves over the start but
converges to a wrong optimum (dense and sparse would disagree, or a second start
would land elsewhere). EBV agreement uses `atol` because individual EBVs can be
near zero. The boundary case guards against a regression where the two paths
diverge at σ²a = 0.

## Coordination Notes

Coordination-light: tests + evidence rows only; no engine, bridge, payload, or
capability change. The EXTERNAL comparator (nadiv `makeAinv`-based fitted check,
or sommer/ASReml) is the R twin's lane — requested via issue #7 to close
V1-COMPARATORS / fitted-Mrode jointly.

## What Did Not Go Smoothly

- The original tiny 3-animal fixture has a boundary REML optimum (σ²a = 0), so it
  is a weak "recovery" example; added an 8-animal interior fixture for the main
  recovery assertions and kept the tiny one only as a boundary-agreement check.

## Known Limitations

- Internal recovery (independent optimizer + start), not external comparator
  parity. No large-pedigree or simulation-recovery-at-scale study yet.

## Next Actions

1. Coordinate the external comparator with the R twin (issue #7) to move
   V1-COMPARATORS / V1-MRODE-FIT toward covered.
2. (Queued, task #5) fastest CPU REML/ML algorithm search — analytic-gradient
   and AI-REML candidates now have a correctness harness to validate against.
