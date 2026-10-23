## 1. Goal

Align the raw-array metafounder wrappers on pedigree ID ordering, genotype row mapping, keyword controls, and honest capability wording.

## 2. Implemented

All five raw-array wrappers share pedigree normalization. The single-step wrapper maps genotype row positions through normalized pedigree IDs while preserving the supplied ordering of rows in `G`. The source documentation describes the ordering rules and distinguishes the combined precision utility from the animal-model MME route. A direct out-of-range genotype-row regression is present. V1-METAFOUNDER remains partial and experimental.

## 3a. Decisions and Rejected Alternatives

Kept `G` in caller-supplied genotype-row order and mapped only the pedigree row indices. This preserves the matrix-to-genotype-row contract and avoids silently permuting user matrix data. Did not promote the capability or add an R-facing model claim.

## 4. Files Touched

Implementation and test: `src/pedigree.jl`, `src/genomic.jl`, `test/test_pedigree_constructor_contract.jl`. Status source and rendered page: `src/validation_status.jl`, `docs/src/validation-status.md`. Evidence: `docs/dev-log/source-review/2026-09-30-metafounder-wrapper-alignment.md` and `docs/dev-log/check-log.d/2026-09-30-metafounder-wrapper-alignment.md`.

## 5. Checks Run

Exact-current focused Julia test passed 38/38. The full `Pkg.test()` passed before the final docs wording refinements and one added status assertion; those final changes are covered by the exact-current focused test. Generated validation page matched the checked-in page byte-for-byte. `git diff --check`, `bash tools/build_check_log.sh --check`, and `bash tools/preamble_cap.sh` passed. The after-task structural check passed; its overall acceptance phase exited 1 because unmet gates remain in root `GATES.md` and the `hsq-gllvm-foundation`, `hsq-w105`, and `hsq-wave2-bridge` ledgers. This wrapper slice does not clear those programme gates. The prose check found 0 findings. Julia printed an existing Project/Manifest compatibility warning; no dependency resolution was run.

## 6. Tests of the Tests

The out-of-range raw genotype-row test checks the failure boundary directly. The scattered unsorted-ID fixture checks normalized pedigree positions separately from the supplied `G` row order. The status assertions prevent an experimental utility from being described as covered or as an R-facing fit.

## 7a. Issue Ledger

- Closed: shared ordering and keyword behavior across five raw-array wrappers.
- Closed: direct out-of-range raw genotype-row regression.
- Open: direct cache-limit assertions for all wrappers; current explicit assertion covers the relationship wrapper and source forwarding is structurally consistent elsewhere.
- Open: fitted-model/comparator evidence and broader programme gates.

## 8. Consistency Audit

Source, tests, and generated validation page agree on normalized pedigree order and caller-supplied genomic matrix order. The capability remains partial. No covered count, release state, or public R contract changed.

## 9. What Did Not Go Smoothly

The generated page is a derived artifact; a manual wording change initially failed the package's exact table-parity test. The source wording was corrected and the page regenerated to a temporary path for byte comparison. The current comparison is clean.

## 10. Known Residuals

This work does NOT cover fitted metafounder inference, an external Mrode comparator, R-facing syntax or payload, general performance, or capability promotion. Full docs build, package closeout, and repository-wide source review remain open.

## 11. Team Learning

Keep raw input positions and normalized internal positions explicit at the wrapper boundary. Tests should use unsorted IDs and scattered genotype rows so an accidental assumption of matching order is observable.

Memory receipt: no second-brain decision or memory file was changed. Golden Set: no new golden fixture was added.

## 12. Cross-Product Coverage

This is a Julia engine wrapper slice. It does NOT cover R source, formula grammar, the R-Julia payload, package version, submission, registry state, release tag, fitted FA or GLLVM usability, or whole-source-wave signoff. Twin-level FA/GLLVM usability gates remain open.
