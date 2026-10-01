# After-task: non-Gaussian and payload-v2 review

## 1. Goal

Review the current Julia non-Gaussian engine and generic payload-v2 bridge for correctness of objective labels, result warnings, input validation, and bounded FA/GLLVM routing.

## 2. Implemented

- Obtained exact-current Noether review of `src/nongaussian.jl` and Hopper review of `src/bridge_payload_v2.jl`.
- Pinned source/test hashes, spans, findings, positive checks, and limits in the source-review and check-log packets.
- Confirmed the generic payload-v2 route is not the FA/GLLVM route; those require explicit dedicated contracts.

## 3a. Decisions and Rejected Alternatives

- Do not route FA or genetic GLLVM through generic payload-v2. Preserve their dedicated payload/result surfaces.
- Preserve and expose whether the non-Gaussian objective is an exact Gaussian likelihood, a Laplace approximation, or a variational lower bound; do not collapse those into an unqualified `loglik` label.
- No code edits were made because lane preflight showed absent changes on foreign refs for the exact source and test files. Keep changes pending explicit lane coordination.

## 4. Files Touched

- `docs/dev-log/source-review/2026-09-29-nongaussian-and-payload-contracts.md`
- `docs/dev-log/check-log.d/2026-09-29-nongaussian-and-payload-contracts.md`
- `docs/dev-log/after-task/2026-09-29-nongaussian-payload-review.md`

## 5. Checks Run

- Parent-run full Julia `Pkg.test()` on this candidate after current changes: exit 0, ends `Testing HSquared tests passed`.
- Reviewers confirmed exact current source hashes and inspected registered tests; neither reviewer ran simulation or benchmark work.
- Structural review evidence is recorded. This is not a passing implementation gate: both source reviews report changes needed/HOLD.

## 6. Tests of the Tests

Existing tests cover low-level variational objective labels, VA convergence, Gaussian reductions, and Gaussian payload shapes. They do not cover end-to-end ELBO-vs-loglik payload semantics, boundary/restart payload propagation, Gamma `Inf` shape, nonfinite model inputs, non-Gaussian family rejection in generic v2, or uniform finite payload rejection. No tests were added due the lane hold.

## 7a. Issue Ledger

- Open high: variational ELBO is exposed as `loglik`; boundary/restart diagnostic is dropped; generic v2 may silently ignore `family` and dispatch Gaussian.
- Open medium: finite values are not consistently checked after conversion in either engine or payload parser; Gamma shape accepts infinity.
- Open low: supported ordered-probit and Gamma families are missing from payload family enumerations.
- Confirmed boundary: generic payload-v2 does not implement FA/GLLVM and should remain separate from their dedicated routes.

## 8. Consistency Audit

The formula/status boundary and dedicated FA/GLLVM route design remain intact. Review findings identify contract gaps, not evidence that FA/GLLVM currently use the generic parser. No capability or public-coverage row changed.

## 9. What Did Not Go Smoothly

Lane preflight found 11 foreign refs with missing changes on `src/nongaussian.jl`, four on `src/bridge_payload_v2.jl`, and two on `test/test_payload_v2_parity.jl`. The lane census showed one active lane, but the reference differences make an uncoordinated edit unsafe under the repository's lane contract. Findings are fully pinned and recorded so ownership can be resolved without repeating the review.

## 10. Known Residuals

The engine and generic bridge need targeted repairs and end-to-end regression tests before their scoped gates can pass. FA/GLLVM opt-in R usability, cross-twin parity, validation and whole-source signoff remain open. No GPU, submission, merge, or tag occurred.

## 11. Team Learning

An objective value needs its approximation type and inferential status in the public payload. A type named `loglik` is not sufficient when the value may be an ELBO or a start-dependent boundary estimate.

## 12. Cross-Product Coverage

This review covers Julia non-Gaussian result semantics and the generic payload-v2 parser/dispatcher. It does NOT cover implementation of the R FA/GLLVM public routes, their complete validation, or the rest of the Julia source review.
