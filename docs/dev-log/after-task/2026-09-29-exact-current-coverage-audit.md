# Exact-current Julia source coverage audit

## 1. Task goal

Check whether review receipts cover every tracked Julia source file and bridge contract at the exact candidate bytes, and keep E1 honest.

## 2. Active lenses and agents

Rose systems audit reviewed Wave 1/2 coverage. Gauss reviewed Wave 3/4 numerical/source coverage. Their independent read-only audits both find E1 remains on hold. FA component reviews remain conditional and do not constitute whole-wave signoff.

## 3. Files changed

- `GATES.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/source-review/2026-09-29-exact-current-coverage-audit.md`
- This after-task report.

No Julia fitting source was edited in this slice.

## 4. Checks and outcomes

- Re-measured SHA-256 for all 22 tracked `src/*.jl` files at HEAD `a7ca8ed557b23ec23c8486365e97a7bac4b71c16`; full inventory is in the source-review audit.
- `OPENBLAS_NUM_THREADS=1 JULIA_NUM_THREADS=4 JULIA_DEPOT_PATH=/private/tmp/hsq-goal-julia-depot:/Users/z3437171/.julia julia --project=. -e 'using Pkg; Pkg.test()'` completed with `Testing HSquared tests passed`.
- Julia reported a Project/Manifest dependency or compatibility mismatch. No resolve or update was run.
- E1 gate audit: still unmet. The coverage report identifies exact-current pin gaps and explicitly unreviewed spans.

## 5. Public claim audit

This audit adds no model capability or public claim. FA and GLLVM remain at their existing bounded experimental status. GPU work, release submissions, and tags remain out of scope.

## 6. Tests of the tests

The integrated package suite exercised registered FA and GLLVM fixtures, including ordinary-start and restart contracts. It proves those registered tests passed in this run; it does not prove all source spans were reviewed or that broad recovery, calibration, or identifiability criteria pass.

## 7. Coordination

The Julia lane preflight showed one lane and a stale handover naming Claude. The approved programme continues in the existing candidate with an explicit scoped lease for gate and review records. The two coverage agents made no edits.

## 8. What did not go smoothly

Several older review packets use baseline hashes while the candidate has accumulated later fixes. Auditing the exact tree showed that a current hash on a narrow follow-up does not cover the rest of the file or original spans.

## 9. Known limitations

Waves 1–4 do not yet have a complete exact-current span-by-span disposition. Main gaps are listed in the source-review audit. The full suite is local evidence only, and its process output reported the Project/Manifest mismatch. The CUDA extension received no GPU execution or completion claim.

## 10. Next actions

1. Split uncovered spans into separate pinned review waves, beginning with `iterative_solve.jl`, `takahashi_selinv.jl`, and `nongaussian.jl`.
2. Reconcile fixed and carried findings against exact hashes, then obtain whole-wave panel signoff.
3. Continue the bounded FA/GLLVM acceptance gates; A2, E1, and V3 remain open.

## 11. Goal status

This coverage audit is complete and records an explicit HOLD. The overall twin programme remains active and incomplete.
