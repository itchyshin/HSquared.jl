# G2 outer10 K0 expanded-reference comparison

Date: 2026-10-08  
Reviewer: Astra, independent read-only review  
Verdict: PASS for interpretation of retained K0 records; numerical comparison remains failed.

## Scope

Audit the outer10 K0 ordinary/reference likelihood gap using retained records only. Check input identity, ordering, model/objective construction, covariance differences, and whether the records support a local start-dependent solution. No fits, edits, policy changes, or G2 credit were authorized or performed.

## Evidence

- Expanded-reference case: `LOOP/lanes/arc1-gaussian-reliability-20261002/evidence/g2-reference-only-v5/output/run-20261007T213821Z-70db5b9c/outer0010.json`, SHA-256 `09da833de62ce18dc94db6b81d56652feb4739b43a8bf80cc83723f310fd6f9e`.
- Current selector case: `LOOP/lanes/arc1-gaussian-reliability-20261002/evidence/g2-next-method-v1/output/run-20261008T024259Z-2015b815/outer0010.toml`, SHA-256 `66070cb30a67fb288363d1b540ec0c6da40c9a527ca3154e7ab69dc1443b7ac4`.
- The independent comparison verified matching serialized input, seed, data identity, all 37 shared source pins, execution identity, model construction, observation ordering, and exact objective.
- The current selector source is `LOOP/lanes/arc1-gaussian-reliability-20261002/evidence/g2-next-method-v1/retained_full_selector.jl:136`; reference source is `LOOP/lanes/arc1-gaussian-reliability-20261002/evidence/g2-reference-only-v5/expanded_reference.jl:63`; both use `src/arc1_fa.jl:527` for the exact objective.

## Finding

The ordinary default and reference `split_0.5` reproduce the same initial parameters, terminal parameters, and 71 BFGS iterations. Their objective values agree within rounding. Five other reference initial splits reach the stronger point in 60 to 130 iterations, below the ordinary iteration cap. The best retained reference point is from `split_0.3`.

The ordinary default has log-likelihood `-448.48762549016914`; the reference `split_0.3` point has `-448.3180917486068`. The shortfall is `0.16953374156236123`, exceeding the frozen `0.0001` tolerance. The covariance solutions differ materially: genetic variance for trait 2 is `1.31550414` versus `1.03000413`, and residual variance for trait 2 is `0.02198401` versus `0.19708023`; relative Frobenius differences are 0.2195 for G and 0.1402 for R. Both records have small gradients and pass their recorded convergence checks, but transformed-coordinate gradients near the covariance boundary do not establish a strict local maximum or global optimality.

The retained data support a start-dependent solution or boundary-stopping interpretation. They show no ordering or differing-objective defect. This does not exclude a shared numerical defect and does not establish global optimality. The ordinary K0/reference comparison therefore remains failed. G2 remains open with zero credit from this consumed case.

## Decision needed before an implementation change

The frozen Arc 1 policy specifies the existing K0 start. These records show that it can miss the stronger best-found K0 point. Before changing the ordinary-start schedule, record an explicit method decision that preserves the frozen acceptance thresholds, refusal rules, and all-attempt denominators. Independently review that amendment and its exact source before any new numerical execution. Do not count this consumed case again.
