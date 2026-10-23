# Iterative solver documentation follow-up

## Scope and verdict

Read-only numerical re-review plus a narrow correction of the matrix-free REML docstrings in `src/iterative_solve.jl`. The final exact-current reviewer found that the prose now matches the implementation. SHA-256 after the edits: `a4adfe04fe736fd55039b329d9d1d1fa4083b02478dc33c60181c7c453c42132`.

This is a scoped wording PASS only. It does not close E1, A2, or V3.

## Corrections

- Calls the optimizer a stochastic REML score fixed-point iteration, not an EM ascent procedure; convergence means small relative variance-component changes, not proof of a unique or global optimum.
- Limits `trace_mcse` to uncertainty in the trace estimate and states that it excludes PCG error and is not parameter uncertainty.
- Describes the multi-effect `loglik` field as `NaN` when disabled and a stochastic full REML likelihood estimate using SLQ for the log determinant when requested.
- Describes the single-effect wrapper's likelihood as exact when requested and evaluated at the returned estimate, regardless of the convergence flag.
- Removes the claim that current tests establish recovery rates; they contain a bounded exact AI-REML comparison only.

## Review and verification

The exact-current numerical reviewer confirmed the earlier fixes for square full-rank fixed effects, final-variance trace MCSE, shared-probe precision wording, finite MME diagonals, and wrapper diagnostic limits. After the doc edits, the reviewer signed off the wording at the hash above. The pedigree reviewer separately confirmed the selfing, metafounder conditional-variance, and group-marker contract fixes on exact source/test hashes. Neither review is whole-wave E1 signoff.

Focused current tests: Wave 1 numerical contracts 167/167; constructed genomic relationships 16/16; APY finite/scale 8/8; APY partial-core 5/5; dense Gaussian precision checks 8/8; direct pedigree constructor 21/21; metafounder conditional-variance rejection 5/5; fully parented group entry 1/1; raw metafounder ID alignment 18/18. Total: 249 assertions passed.

`git diff --check` and `bash tools/preamble_cap.sh` passed; the preamble measured 11,024 bytes of a 14,000-byte cap. The documentation build passed in a content-matched temporary copy after retaining the worktree's `.git` pointer and resolving the local package path. Documenter reported its existing 47 orphan docstrings, local-build deployment skip, missing favicon/config defaults, and VitePress large-chunk warning; rendering completed successfully. The first temporary-copy attempt failed because the copy lacked Git metadata, then passed after adding the pointer file.

The full Julia 1.10 package suite also exited 0 on the exact current candidate with `Testing HSquared tests passed`. Julia reported the existing Project/Manifest mismatch warning; no resolve or update was run. The GATES runner needed Juliaup added to PATH for its `/bin/sh` checks; after that correction it read the V1/V2 evidence and reported only the still-open programme gates.

## Carry-forward

`src/validation_status.jl` still contains matrix-free REML wording and a recovery-status statement requiring exact-current evidence review. File preflight found 34 other refs carrying divergent edits to that path. It was not edited in this scoped slice. Whole-wave source dispositions, Rose claim audit, FA ordinary-start recovery, GLLVM acceptance, and final twin parity remain open in `GATES.md`.

No capability status, covered count, API, release state, GPU status, registry submission, or tag changed.
