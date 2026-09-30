## 1. Goal

Review the current Julia data-ingress ID, marker-count, and empty-marker contracts against their focused tests.

## 2. Implemented

No code changed. The review confirmed the covered Dict ID-length, typed-ID, marker-order, and empty-marker-status cases and identified a NamedTuple row-count validation defect plus narrower test gaps.

## 3a. Decisions and Rejected Alternatives

Kept this slice read-only because lane preflight found a divergent ref with work on `src/data.jl`. The alternative changed marker counting to exclude a literal `id`, which is incompatible with configurable `genotype_id`; it was not adopted. The concrete NamedTuple defect is recorded for resolution on an authorized source lineage.

## 4. Files Touched

Evidence only: `docs/dev-log/source-review/2026-09-30-data-input-contract-exact-review.md`, `docs/dev-log/check-log.d/2026-09-30-data-input-contract-exact-review.md`, `GATES.md`, and this report.

## 5. Checks Run

Curie checked three exact hashes and ran no tests. The coordinator ran lane preflight on the source and tests and inspected the divergent source diff. Documentation checks for this report are recorded after execution.

## 6. Tests of the Tests

Existing tests cover too-few explicit genotype IDs, expression-ID mismatch, valid status counts, unequal Dict columns, typed IDs, empty phenotype IDs, inferred table marker order, generic marker-map failures, and empty-marker status output. They do not test unequal later NamedTuple columns, explicit marker-ID count mismatch, exact diagnostics, string-key Dict sources, or empty genotype/map combinations.

## 7a. Issue Ledger

- Open: reject inconsistent NamedTuple column lengths before explicit IDs can be aligned to the first column only.
- Open: add narrow direct tests for the marker and Dict compatibility gaps listed in the source-review packet.
- Open: remaining `src/data.jl` spans and whole-source E1 disposition.

## 8. Consistency Audit

The status/output tests remain distinct from fitted-model validation. The configured genotype ID remains part of the marker-count contract. No capability or release state changed; GATES.md records a component finding only.

## 9. What Did Not Go Smoothly

The first preflight call exceeded the command wait window before printing the hash command output; hashes were obtained in a separate read-only command. The local source ref contains unrelated work on the same file, so the defect is carried rather than patched on a potentially conflicting lineage.

## 10. Known Residuals

Scope is one Julia data-ingress component. It does NOT cover every data constructor/normalizer branch, all pedigree and genotype contracts, R-Julia payload parity, fitted FA/GLLVM recovery, or whole E1/V3 completion.

## 11. Team Learning

For row-count contracts, validate every column in table-like containers; using the first column as the table's row count can silently accept malformed data when explicit IDs bypass column access.

Memory receipt: no second-brain decision or memory file was changed. Golden Set: no new fixture was added.

## 12. Cross-Product Coverage

This review covers the Julia data-ingress component and selected Julia tests. It does NOT cover R source, formula grammar, payload parity, all data shapes, full-file review, or a fitted-model capability. E1 remains open.
