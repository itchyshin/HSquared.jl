# After-task: E1 exact-current review slice

## 1. Goal

Add exact-current panel dispositions for several previously open Julia engine and bridge-adjacent source spans without implying whole-wave E1 completion.

## 2. Implemented

- Reviewed and pinned `src/errors.jl`, `src/planned_terms.jl`, `src/iterative_solve.jl`, and `src/takahashi_selinv.jl` against the active candidate.
- Recorded scoped verdicts, inspected tests, findings, and explicit residual limits in `docs/dev-log/source-review/2026-09-29-errors-planned-terms.md` and `docs/dev-log/source-review/2026-09-29-iterative-and-selinv.md`.
- Recorded exact-hash review receipts in corresponding `docs/dev-log/check-log.d/` shards.
- Added Falconer's exact-current review of the GLLVM `FΛ' + D` trait-effect reconstruction and its link-scale interpretation.
- Cross-checked the matching R candidate: it aligns `Y`/`X` rows with pedigree IDs and validates returned ID/trait order; the pinned R GLLVM live filter is recorded as 87/87.

## 3a. Decisions and Rejected Alternatives

- Treat each reviewer verdict as scoped to the exact source and test hashes, not as whole-file or programme signoff when the reviewer inspected only declared spans.
- Keep unverified performance claims and numerical gaps explicitly carried; do not run a benchmark or simulation without a pinned harness and estimate.
- Leave foreign-ref documentation and test files unchanged when lane preflight showed missing changes from other branches.

## 4. Files Touched

- `docs/dev-log/source-review/2026-09-29-errors-planned-terms.md`
- `docs/dev-log/source-review/2026-09-29-iterative-and-selinv.md`
- `docs/dev-log/check-log.d/2026-09-29-errors-planned-terms.md`
- `docs/dev-log/check-log.d/2026-09-29-iterative-and-selinv.md`
- `docs/dev-log/source-review/2026-09-29-gllvm-trait-effects.md`
- `docs/dev-log/check-log.d/2026-09-29-gllvm-trait-effects.md`
- `docs/dev-log/after-task/2026-09-29-e1-source-review-slice.md`

## 5. Checks Run

- Full local Julia `Pkg.test()` on the candidate after the latest source changes: exit 0, ending `Testing HSquared tests passed`.
- Source hashes were measured and confirmed by reviewers for all reviewed engine files and designated tests.
- `bash tools/preamble_cap.sh`: passed.
- `git diff --check`: passed.
- Falconer: PASS for the GLLVM trait-effect reconstruction; animal IDs remain caller-order dependent in the Julia object and must be mapped in R.
- Matching R candidate worktree `/private/tmp/hsquared-fa-gllvm-20260927` at `fa98c262` maps those IDs and labels explicitly; pinned hashes and live 87/87 evidence are in the GLLVM review packet.
- The after-task structural validator passes this report. The integrated acceptance ledger remains unmet at the programme level: FA/GLLVM foundation, W1-05, Wave 2 bridge, and root E1/V3 gates are still open.

## 6. Tests of the Tests

This was a read-only code-review arc; reviewers inspected the existing registered tests but did not add or run independent benchmarks. Parent's full package suite ran on the candidate and passed. Missing test coverage is explicitly listed in the review packets.

## 7a. Issue Ledger

- Fixed in documentation/evidence: exact-current review uncertainty for the four scoped source files is reduced and recorded with reviewer verdicts.
- Carried: matrix-free solver lacks explicit finite checks and rank-deficient fixed-effect handling; `Phase0NotImplementedError` lacks an operation-string rendering assertion; formula-status documentation lacks full row/enum consistency coverage; selinv performance and adversarial conditioning lack exact-source measurements.
- Open: all remaining source spans, FA/GLLVM inference and bridge acceptance, release-candidate validation, and twin closeout.

## 8. Consistency Audit

The source review distinguishes a formula diagnostic row from Julia formula parsing and preserves the boundary between fixed-rank expert-control FA and the planned formula route. The sparse precision validator canonicalizes one matrix for downstream use. The selected-inverse review supports current tested math while retaining complexity and benchmark limits. No capability, status, public claim, version, or covered count changed.

## 9. What Did Not Go Smoothly

`docs/src/model-spec-grammar.md` had a low-severity mismatch with `formula_status()`, but lane preflight showed three foreign refs with changes absent from this worktree, so the file was left untouched. A possible new error-message assertion would touch `test/runtests.jl`, which also has foreign-ref differences; the issue is carried rather than risking another lane's work.

## 10. Known Residuals

E1 is not complete. Four file reviews do not cover all 22 tracked Julia source files and public bridge contracts. This slice does not close A2, V3, any full FA/GLLVM acceptance gate, public R package checks on an exact final candidate, or hosted CI. No GPU work, release/registry submission, merge, or tag occurred.

## 11. Team Learning

An exact-current review packet is useful only when its verdict scope, source hash, test evidence, and carried findings travel together. A full-suite pass does not erase a reviewer's untested edge-case finding.

## 12. Cross-Product Coverage

This slice covers pinned source dispositions for selected Julia error, formula-status, matrix-free solver, and selected-inverse code. It does NOT cover the remaining Julia source or public bridge spans, the R fit routes, the complete FA/GLLVM validation and parity gates, or release readiness.
