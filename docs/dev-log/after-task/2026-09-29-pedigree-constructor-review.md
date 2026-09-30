## 1. Goal

Fix and verify the exact-current Julia `Pedigree` constructor mismatch for unknown-parent marker IDs, while keeping the broader HSquared twin programme gates honest.

## 2. Implemented

- Added the `missing_values` keyword to direct construction, with the standard unknown-parent marker set as its default.
- Rejected IDs that match the constructor's unknown-parent markers.
- Passed custom marker semantics from `normalize_pedigree` into construction.
- Added default and custom-marker regression coverage. The focused suite passed 20/20.

## 3a. Decisions and Rejected Alternatives

- Kept `normalize_pedigree` as the preferred route for raw labels and ordering.
- Did not impose default marker rules on IDs when a caller supplies a different custom marker set.
- Did not promote capabilities or close full-file E1 review based on this scoped constructor finding.

## 4. Files Touched

- `src/pedigree.jl`
- `test/test_pedigree_constructor_contract.jl`
- `docs/dev-log/source-review/2026-09-29-pedigree-constructor-review.md`
- `docs/dev-log/check-log.d/2026-09-29-pedigree-constructor-review.md`
- `docs/dev-log/after-task/2026-09-29-pedigree-constructor-review.md`
- `GATES.md`

The source and test changes predated this report. The last four paths were created or updated for this closeout.

## 5. Checks Run

- Focused Julia test: 20/20 passed on the exact source and test hashes listed in the source-review packet.
- Full Julia `Pkg.test()`: exit 0 and ended with `Testing HSquared tests passed` on the same source and test bytes. Julia reported an existing Project/Manifest mismatch; no resolve or update was run.
- `git diff --check`: passed.
- After-task section validation passed for all required headings and the explicit negative-space section. The integrated closeout compiler remains red because this programme ledger has A2, E1, and V3 open.
- The programme ledger remains 8/11, with A2, E1, and V3 still open.
- Routing first returned no manifest for the managed-worktree path. I then ran `python3 ~/shinichi-brain/tools/route.py` on the canonical `HSquared.jl` repo and loaded its LOAD-FIRST manifest. The R-public/Julia-engine boundary and validation-first rule shaped this closeout.

## 6. Tests of the Tests

The pre-fix test reproduced direct acceptance of standard unknown-parent marker IDs and failure to preserve custom marker semantics. The added tests now reject the standard markers and verify both custom marker rejection and acceptance of a different otherwise-default marker as an ID.

## 7a. Issue Ledger

- Fixed: direct construction could accept IDs that the normalizer treats as unknown-parent markers.
- Fixed: custom marker sets were not represented by the direct constructor contract.
- Carried: complete `src/pedigree.jl` source review, the remaining E1 spans, FA engine signoff A2, final twin checks V3, and broader programme gates.

## 8. Consistency Audit

Henderson reviewed the constructor and normalization spans on the exact final hashes and found no adjacent constructor-contract issue in this scoped change. Normalization now passes the same marker set it used to parse raw parent labels. R behavior, fitted capabilities, capability status, validation debt, covered count, documentation builds, and release state were not changed by this closeout.

## 9. What Did Not Go Smoothly

The first lane-lease claim used an unsupported option and was refused. The tool usage was checked and the intended report-path lease was then granted. The repository routing tool had no manifest for this managed worktree path. The broad check log and coordination board carry active references from other work, so this report uses a dated shard rather than rewriting those shared files.

## 10. Known Residuals

This does not close full-file pedigree review or E1. It does not establish arbitrary-depth pedigree guarantees, model-fitting behavior, FA uniqueness information, broad recovery, inference, R-Julia parity, A2, or V3. The working tree remains dirty with other approved programme changes. No GPU work, release submission, registry submission, merge, or public tag was performed.

## 11. Team Learning

The same unknown-parent marker set must govern both raw-label normalization and direct normalized-object construction. Henderson's exact-current component review confirmed the aligned contract and its limits. Memory receipt: loaded the hub and HSquared.jl operating contract plus the canonical repo LOAD-FIRST manifest. The R-public/Julia-engine boundary and validation-first rule shaped this slice.

Golden Set: checked the registry with `python3 ~/shinichi-brain/tools/memory_regression.py --list`; no registered case covers unknown-parent markers in direct `Pedigree` construction, so no case was applicable.

## 12. Cross-Product Coverage

This change covers Julia direct pedigree construction and the Julia normalization path. It does NOT cover the R package, the R-Julia bridge, FA or GLLVM fitting, inference, calibration, genomic inputs, GPU routes, CRAN submission, Julia registry submission, or public release tags.
