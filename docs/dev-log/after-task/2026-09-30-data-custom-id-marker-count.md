## 1. Goal

Check whether HSData counts genotype marker columns correctly when the identifier column has a user-specified name.

## 2. Implemented

No source changes. A read-only exact-current review confirmed that `genotype_id` is passed into the table fallback and normalized before comparison. A four-line alternative from another branch was rejected because it excludes only a literal `id` column and would miscount the supported `:sample` identifier.

## 3a. Decisions and Rejected Alternatives

Retained the current configured-ID comparison. Did not take the alternative that hard-codes `id`.

## 4. Files Touched

Evidence only: `docs/dev-log/source-review/2026-09-30-data-custom-id-marker-count.md`, `docs/dev-log/check-log.d/2026-09-30-data-custom-id-marker-count.md`, and this report.

## 5. Checks Run

The reviewer verified exact source and test hashes and inspected the focused implementation and test spans. No test, fit, or simulation was run. The reviewer returned PASS for this focused contract only. `bash tools/build_check_log.sh --check`, `bash tools/preamble_cap.sh`, `git diff --check`, and the prose check passed. The after-task structural check passed; its overall acceptance phase exited 1 because gates remain open in root `GATES.md` and the `hsq-gllvm-foundation`, `hsq-w105`, and `hsq-wave2-bridge` ledgers.

## 6. Tests of the Tests

The existing custom `:sample` test expects one marker, so it would fail under the hard-coded-`id` alternative. Default `id` tables and a dictionary with string/symbol-equivalent marker keys are also checked. Custom-ID dictionary keys and string-valued custom-ID configuration remain untested.

## 7a. Issue Ledger

- Closed: current custom `:sample` table behavior matches the configured-ID contract.
- Rejected: hard-coded `id` alternative from `origin/codex/handover-0910-20260907`.
- Open hardening: test custom-ID dictionary keys and string-valued `genotype_id`.
- Open: remaining `src/data.jl` spans and full E1 coverage.

## 8. Consistency Audit

The current input behavior and test agree. No API, capability status, or public model claim changed.

## 9. What Did Not Go Smoothly

The agent's inherited checkout first resolved to a different branch. It was redirected to the candidate worktree and verified the exact requested source hash before continuing. No edits were made in either checkout.

## 10. Known Residuals

This review does NOT cover all HSData inputs, pedigree or expression edge cases, the complete source file, bridge payloads, fitted models, or E1 signoff.

## 11. Team Learning

Identifier-column exclusion must follow the configured ID field, not assume a fixed column name. Compare normalized keys so table and dictionary names behave consistently.

Memory receipt: no second-brain decision or memory file was changed. Golden Set: no new fixture was added.

## 12. Cross-Product Coverage

This is a Julia HSData input-contract review. It does NOT cover R data conversion, R-Julia payload parity, fitted FA/GLLVM behavior, broad capability status, or release state.
