## 1. Goal

Continue the approved HSquared twin milestones by closing two bounded Wave 3 input-contract findings in Julia: one-sided aliases in raw pedigree diagnostics and unchecked direct construction of `Pedigree`.

## 2. Implemented

- Resolve sire and dam aliases independently in raw pedigree diagnostics. Preserve a recognized side and infer only a missing side from its conventional positional slot when available and distinct. Keep the existing positional fallback when neither side has an alias.
- Validate direct `Pedigree` construction for equal vector lengths, unique IDs, nonnegative earlier-row parent indices, and a valid `original_order` permutation.
- Preserve selfing by allowing equal sire and dam indices when the shared parent precedes the offspring.
- Document the direct-constructor contract and raw-table alias behavior. Clarify that selfing is rejected by default and can be enabled.

## 3a. Decisions and Rejected Alternatives

- Keep `normalize_pedigree()` as the preferred path for raw labels, duplicate/cycle checks, and parent-first ordering.
- Do not infer a missing diagnostic parent side from the recognized side's column. An absent or colliding positional slot remains unknown.
- Do not reject equal known sire and dam indices in the direct constructor because selfing is supported.
- Do not change a capability-status or validation-debt row; these are input-contract repairs and do not establish new fitting evidence.

## 4. Files Touched

- `src/data.jl`
- `src/pedigree.jl`
- `test/test_data_empty_marker_status.jl`
- `test/test_pedigree_constructor_contract.jl`
- `test/runtests.jl`
- `docs/src/data.md`
- `docs/src/pedigree-ainv.md`
- `docs/dev-log/source-review/2026-09-27-wave3.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/coordination-board.md`
- `docs/dev-log/after-task/2026-09-29-pedigree-input-contracts.md`

## 5. Checks Run

- Focused Julia tests passed 20/20: empty marker status 2/2, raw parent aliases 7/7, and direct constructor 11/11.
- Julia 1.10.0 `Pkg.test()` exited 0 and ended with `Testing HSquared tests passed`, using four Julia threads and one BLAS thread.
- Julia docs build exited 0 after the final wording correction. Existing missing-docstring, local deploy autodetection, default VitePress config/favicon, and bundle-size warnings remain.
- `git diff --check` passed.
- Programme GATES still reports 8 met and 3 unmet: A2, E1, V3.
- The after-task structure check passed. Its integrated ledger check exits nonzero because it also requires the broader programme gates A2, E1, and V3 to close; this bounded slice does not abandon those remaining gates.

## 6. Tests of the Tests

The new direct-constructor tests failed on the unchecked constructor before implementation. The alias regressions failed when a single recognized parent alias was discarded and when an alias vector had the wrong length. After the source changes, all focused assertions passed and the full package suite passed with both test files registered.

## 7a. Issue Ledger

- Fixed: loss of a lone recognized sire/dam alias in `data_status()` and unchecked structural invariants in direct `Pedigree` construction.
- Preserved: conventional positional fallback when neither parent alias is present; supported selfing with an earlier shared parent.
- Carried: remaining Wave 3 source spans, full Julia engine review, bridge parity, panel signoff, and overall programme gates A2, E1, V3.

## 8. Consistency Audit

The documentation now distinguishes raw-table warning diagnostics from normalized-pedigree validation and names the selfing exception. Tests are included in `test/runtests.jl`. No R-side API, fitted capability, validation-status claim, or release state changed. The full Wave 3 review remains HOLD.

## 9. What Did Not Go Smoothly

The first test attempt could not write Julia's default cache under the user home. Tests then ran with a writable cache in `/private/tmp` and the existing user depot as a read-only fallback. The first docs-build attempt was blocked from writing inside the managed worktree; the escalated local build completed successfully. Rose also found one overbroad neighboring selfing sentence, which was corrected before the final docs build.

## 10. Known Residuals

This slice does not review all of `src/pedigree.jl` or `src/data.jl`, establish arbitrary-depth pedigree guarantees, validate model fitting, or close Wave 3. The public `Pedigree` fields remain mutable vectors, so callers can mutate a valid object after construction; this change validates construction-time inputs only. The full FA recovery campaign remains separately approval-gated despite Totoro availability.

## 11. Team Learning

Curie isolated the alias-resolution contract, Henderson defined direct-constructor invariants and the selfing exception, and Rose audited neighboring public wording. The independent lenses caught both a data-loss bug and a documentation overclaim before closeout.

## 12. Cross-Product Coverage

This slice covers Julia raw-data diagnostics and Julia `Pedigree` input construction. It does NOT cover the R package, R-Julia bridge, FA/GLLVM estimation, calibration, GPU routes, CRAN submission, Julia registry submission, or public release tags.
