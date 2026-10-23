# Wave 4 genomic boundary underflow and endpoint-tie review

## Scope and exact candidate

Reviewed only the derived-variance and endpoint-adjacent comparison portions of the genomic boundary resolver in `src/likelihood.jl`, its focused regression file, and the design amendment. Exact hashes are recorded in `docs/dev-log/after-task/2026-09-29-genomic-boundary-underflow-and-ties.md`.

## Findings and disposition

1. Internally derived Float64 variances could underflow to zero or have an infinite reciprocal before likelihood validation. The resolver now checks representability before the interior gradient and likelihood calls and before the boundary likelihood call. Failure returns a structured unresolved result.
2. An endpoint-adjacent candidate could strictly improve on an endpoint by less than the tie tolerance and still be labeled a boundary. The resolver now fails closed for strict improvements at either endpoint. Exact ties and non-adjacent candidates are distinguished by direct tests.

## Verification and limits

- Focused test: 28/28 passed.
- Full Julia 1.10 package suite: exit 0, ending `Testing HSquared tests passed` on the exact-current candidate.
- Noether passed the numerical representation review. Gauss passed the bounded endpoint-classification review and confirmed the exact-current suite result.
- This is not whole-file review or whole-wave signoff. E1 remains open; A2 and V3 remain open. No public capability or covered-count row changed.
