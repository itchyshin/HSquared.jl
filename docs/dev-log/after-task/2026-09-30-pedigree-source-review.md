# After-task: pedigree inverse regression and source review

## 1. Goal

Close the reviewed sparse pedigree inverse validation gap for an inbred known parent with one unknown mate, and correct nearby complexity, conditioning, and variance wording.

## 2. Implemented

- Added deterministic tests for an inbred known sire or dam, the expected Mendelian variance and inverse entries, sire/dam swap, a descendant through the one-parent animal, and the Float64 `F == 1` diagnostic boundary.
- Corrected the source docstring to distinguish returned Mendelian variances `d_i` from inverse weights `1/d_i`.
- Replaced an unsupported O(n) claim and narrowed the dense-conditioning claims in the validation-debt register.
- Aligned current status wording for selfing and clonal primitives, and documented the terminal-ramet limitation in source, capability status, and validation debt.
- Updated the exact-byte review checkpoint with reviewer and test evidence.

## 3a. Decisions and Rejected Alternatives

- Kept this a test and claim-boundary repair. The independent reviewer found no inverse-construction defect.
- Did not change the current Float64 zero-Mendelian-variance error behavior or infer the earliest generation where rounding occurs.
- Did not promote a fitted capability or claim general conditioning robustness. Existing experimental status rows were aligned in wording only.

## 4. Files Touched

- `src/pedigree.jl`
- `test/test_pedigree_inbred_known_parent.jl` (new)
- `test/runtests.jl`
- `docs/design/capability-status.md`
- `docs/design/validation-debt-register.md`
- `docs/design/14-program-backlog.md`
- `docs/design/17-wave-F-foundation-and-genomic-gpu.md`
- `docs/design/23-v07-v08-programme-plan.md`
- `docs/dev-log/source-review/2026-09-30-pedigree-review.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/coordination-board.md`
- This report.

## 5. Checks Run

- Focused test: `julia --project=. test/test_pedigree_inbred_known_parent.jl`, **20/20 passed**.
- Full suite: `JULIA_DEPOT_PATH=/private/tmp/hsq-fa-gllvm-depot:/Users/z3437171/.julia OPENBLAS_NUM_THREADS=1 JULIA_NUM_THREADS=4 julia --project=. -e 'using Pkg; Pkg.test()'`, **passed**, ending `Testing HSquared tests passed`.
- The full-suite run warned that Project dependency or compatibility requirements differ from the Manifest. No resolve or update was run.
- `bash tools/preamble_cap.sh` passed. The prose style check passed with zero findings. A stale-claim search found no remaining Meuwissen O(n) claims in source or current design files.
- `Rscript .../check-after-task.R <report>` passed the structure check, then correctly reported that the integrated acceptance ledger still has unmet programme gates (A2, E1, V3 and linked gates). This report closes only the bounded review slice.
- One earlier full-suite attempt received SIGTERM before completion. It is recorded as interrupted and not counted as a pass.
- Exact final candidate hashes are recorded in the source-review checkpoint. They identify working-tree bytes at HEAD `a7ca8ed557b23ec23c8486365e97a7bac4b71c16`.

## 6. Tests of the Tests

The assertions compare against hand-derived inverse contributions and known inbreeding values, check inverse symmetry and `Ainv * A ≈ I`, swap parent positions, and exercise a descendant through the one-parent ancestor. No deliberate mutation test was run. The final focused and full test runs execute the new assertions against the candidate implementation.

## 7a. Issue Ledger

- Closed for the reviewed candidate: missing regression for an inbred known parent with one unknown mate; misleading reciprocal wording in the Mendelian-variance docstring; unsupported O(n) wording; overbroad interpretation of a single finite-conditioning fixture.
- Still open: clonal ramets used as sexual parents can yield incorrect descendant relationships; broad dense-inverse conditioning evidence; labelled metafounder group-order contract. The status-row mismatch found by Rose is corrected, but the clonal parent case remains a known limitation.
- No issue in this slice changes the approved Gaussian FA or Poisson genetic GLLVM cells.

## 8. Consistency Audit

Checked both one-parent branches, duplicate-parent/selfing assembly context, the existing dense oracle, the neighboring seven-generation finite case, and validation-debt wording. Updated nearby wording so the tests support only the fixtures actually checked. The existing review note was reread and now distinguishes source review from executed tests.

## 9. What Did Not Go Smoothly

The first full-suite attempt was terminated by SIGTERM. A retry completed successfully. The repository Project/Manifest mismatch warning remains unresolved and was not altered in this slice.

## 10. Known Residuals

- The clone-as-parent defect is experimental inheritance work and remains queued; it is not fixed here.
- The depth-80 test pins the current floating-point diagnostic, not a general numerical guarantee.
- No standalone docs build, CI run, merge, release, or cross-repository parity run was performed for this narrow pedigree slice. Rose's final scoped audit passed after the wording fixes. Rose also found `sim/phase5_sparse_aireml_benchmark.jl:88` still says `O(q)` for the Ainv path. Preflight found that file has divergent work on the stale Claude handover ref; it was not edited, and that one comment remains for ownership reconciliation.
- E1, A2, V3, the FA recovery campaign approval, and the broader twin programme remain open. No GPU work or release action occurred.

## 11. Team Learning

The exact-byte Henderson review found the inverse contribution formula correct, including omission of unknown parents and duplicate-parent accumulation. A small hand-calculated one-parent fixture closed a validation gap without broadening the model claim. Runtime evidence and source review are separate gates and both are recorded here.

## 12. Cross-Product Coverage

- Pedigree inverse construction: sire-known and dam-known missing-mate cases, descendant through the one-parent animal, and a Float64 boundary diagnostic are covered.
- This slice does NOT cover clonal inheritance, metafounder label ordering, genomic relationship paths, non-Gaussian family behavior, R-Julia parity, GPU execution, or general deep-conditioning robustness.

## Memory and coordination receipt

Memory receipt: The HSquared project instructions, candidate ROADMAP, capability table, validation-debt register, and lane preflight were used. Lane preflight found no missing path work for the review checkpoint, but the newest handover remains addressed to Claude and divergent refs exist; the approved isolated candidate worktree was retained. The actual GPT-6.1 Sol High Henderson subagent reviewed final source/test hashes and confirmed the narrow finding closure. Rose's scoped audit passed on the requested source, status, backlog, and terminal-ramet wording; one benchmark comment on a divergent ref remains. No cross-project scouting or simulation campaign was performed.

Golden Set: not run because no routed Golden Set item was available in this candidate lane.
