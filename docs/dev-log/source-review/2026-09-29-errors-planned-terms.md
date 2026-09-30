# Exact-current source review: errors and planned formula terms

Candidate: `codex/hsquared-fa-gllvm-20260927` at HEAD `a7ca8ed557b23ec23c8486365e97a7bac4b71c16`.

## `src/errors.jl`

- SHA-256: `6ebb3635c308097213b1581fae26e94089969f34a07cbf5b735a5ee945d44fba`.
- Reviewed complete file: `Phase0NotImplementedError` definition at lines 6–8, rendered message at 10–18, and constructor at 20–22; checked the unavailable multivariate route in `src/bridge_payload_v2.jl:657–675` and its callers.
- Verdict: scoped PASS. The message describes the specific unavailable operation and points to capability status; it does not imply that all model fitting is unimplemented. Current FA and GLLVM fits use dedicated routes.
- Carried low-severity test gap: `test/runtests.jl:81–85` checks the message wording but not that the supplied operation appears in `showerror`. Tests at 623–624 check the error type rather than rendered text. `test/runtests.jl` has foreign-ref changes this worktree does not contain, so this slice did not add the regression.

## `src/planned_terms.jl`

- SHA-256: `a47d953d72565f347db805b5d0c7bdc86d5440dedaa6454c674f6e48c9607d5c`.
- Reviewed complete file: diagnostic terms and scope at lines 20–41; typed row/status fields at 59–78; Julia-local versus R formula language at 115–126; all 17 reserved callable stubs at 169–359. Cross-checked the FA formula freeze at `docs/design/54-fa-grammar-freeze.md:99–134,164–173,230–240` and the documented route boundary.
- Verdict: scoped PASS. The experimental animal payload diagnostic is not a Julia formula parser. Fixed-rank FA remains an expert-control route; `cov=fa(K=k)` remains planned for the R formula interface. Automatic rank remains a separately validated follow-on, not part of the frozen formula row.
- Carried low-severity documentation mismatch: `docs/src/model-spec-grammar.md:52–58` calls the table the “exact typed row text,” while the displayed syntax/fitting descriptions do not match the `reserved`/`planned` and `not available` values returned by `formula_status()`. The current docs file is dirty and lane preflight reports three foreign refs carrying changes absent from this worktree; it was left untouched. Existing wording tests only pin two rows and do not compare every row/enum.

## Evidence limits

These are per-file reviews, not E1 signoff. Neither verdict closes the remaining exact-current source spans or full Julia source-review panel gate. No capability, public status, or formula grammar was changed. The full Julia `Pkg.test()` was run separately on this candidate and passed, but it does not cover the two carried message/table wording gaps.
