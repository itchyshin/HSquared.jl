## 1. Goal

Review residual pedigree normalization, sparse relationship inverse, metafounder boundary, and constructor-test spans for the E1 Julia source programme.

## 2. Implemented

No code changed. The exact-current review passed the inspected sparse Henderson inverse and wrapper alignment contracts conditionally and recorded constructor, depth, metafounder, and fitted-model evidence gaps.

## 3a. Decisions and Rejected Alternatives

Kept this read-only because preflight found divergent work on `src/pedigree.jl`. Did not infer fitted animal-model correctness from constructor tests or sparse inverse construction alone.

## 4. Files Touched

Evidence only: `docs/dev-log/source-review/2026-09-30-pedigree-core-spans-review.md`, `docs/dev-log/check-log.d/2026-09-30-pedigree-core-spans-review.md`, `GATES.md`, and this report.

## 5. Checks Run

Henderson checked exact source/test pins and ran no tests, fits, or simulations. The coordinator ran lane preflight before review and found two refs with `src/pedigree.jl` work. Check-log generation and `--check`, `preamble_cap.sh`, `git diff --check`, and the prose check passed. The after-task structural check passed; its acceptance phase reports open programme gates in `GATES.md` and the three scoped ledgers. The source-review report passed `slop_check.py` with zero findings.

## 6. Tests of the Tests

Direct tests cover wrapper alignment, custom parent markers, selfing, and single-step row alignment. They do not validate fitted Henderson MME equations, estimated variance-component output, deep-chain recursion, invalid/singular metafounder `Γ`, or the fully parented unknown-group marker requirement.

## 7a. Issue Ledger

- Open: decide whether direct self-parent construction is an intentional selfing API.
- Open: stress very deep pedigrees against recursive topological sorting.
- Open: add or identify direct malformed-metafounder contract tests.
- Open: matched MME/EBV/fitted-output and production sparse-solve checks.
- Open: remaining `src/pedigree.jl` spans and whole-wave E1 signoff.

## 8. Consistency Audit

The review separates relationship construction from fitted animal-model estimation and EBV claims. No capability status, covered count, release status, or GPU status changed. GATES.md records a component review only.

## 9. What Did Not Go Smoothly

The source has two divergent refs, so findings were preserved without editing the shared implementation or moving the branch.

## 10. Known Residuals

Scope is selected Julia pedigree spans. It does NOT cover all pedigree source code, every constructor route, Mrode fitted examples, R-Julia parity, fitted variance components, production sparse scaling, or whole E1/A2/V3 completion.

## 11. Team Learning

Keep the constructor's selfing policy aligned with normalization policy, and validate recursion depth independently of sparse matrix storage; sparse arithmetic does not prevent call-stack exhaustion in pedigree traversal.

Memory receipt: no second-brain decision or memory file was changed. Golden Set: no new fixture was added.

## 12. Cross-Product Coverage

The reviewed code is Julia engine code, and the tests cover direct construction only. It does NOT cover R syntax or extraction, fitted animal-model output parity, release state, full-source review, or capability promotion. E1 remains open.
