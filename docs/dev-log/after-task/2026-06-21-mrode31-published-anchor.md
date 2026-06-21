# After-Task Report: Mrode Example 3.1 published animal-model anchor

## Live Phase Snapshot

As of this report, the slice starts from Julia `main` `945bd2a` after #138
merged the R-lane Mrode multivariate anchor sync. Post-#138 `main` CI,
Documenter, and Pages were green before this branch was finalized. Covered
public status is unchanged: v0.1 univariate Gaussian animal-model support only;
this slice does not promote any validation row to covered.

## 1. Goal

Add a Julia-native, source-recorded published anchor for #46 by testing the
Henderson MME supplied-variance animal-model path against Mrode (2014) Example
3.1 published EBVs and the invariant sex contrast.

## 2. Implemented

- Added `Phase 1 Mrode Example 3.1 published animal-model anchor (#46)` to
  `test/runtests.jl`.
- The test builds the 8-animal Example 3.1 pedigree, records animals 4-8,
  sex fixed-effect design, and `Z` incidence matrix directly in Julia.
- The test pins `sigma_a2 = 20`, `sigma_e2 = 40`, published EBVs for animals
  1-8, and the published male-minus-female contrast `0.95407223`.
- `fit_animal_model(...; target = :henderson_mme)` and direct
  `henderson_mme()` are both checked against the published EBVs.
- Updated `validation_status()` and status tests so `V1-MME` records the
  published Example 3.1 supplied-variance evidence while preserving its
  `partial` status.
- Updated validation canon, validation-debt, public-claims, capability-status,
  Documenter validation page, coordination board, and check-log wording.

## 3a. Decisions and Rejected Alternatives

- Treated Mrode Example 3.1 as a supplied-variance animal-model anchor, not as
  estimated-variance-component validation.
- Did not add the Mrode Example 3.2 sire model to Julia. The R lane records it,
  but Julia does not currently expose a sire-model path as a public engine
  surface.
- Did not promote `V1-MME`, `V1-DENSE-OUT`, or `V1-MRODE-FIT` to covered. The
  same-estimand fitted-output comparator and estimated-VC evidence gates remain
  open.

## 4. Files Touched

- `src/validation_status.jl`
- `test/runtests.jl`
- `docs/design/04-validation-canon.md`
- `docs/design/06-public-claims-register.md`
- `docs/design/capability-status.md`
- `docs/design/validation-debt-register.md`
- `docs/src/validation-status.md`
- `docs/dev-log/coordination-board.md`
- `docs/dev-log/check-log.d/2026-06-21-mrode31-published-anchor.md`
- `docs/dev-log/after-task/2026-06-21-mrode31-published-anchor.md`

## 5. Checks Run

- `julia --project=. -e 'using Pkg; Pkg.test()'` — passed. The new Mrode
  Example 3.1 testset passed 9 checks inside the full suite.
- `julia --project=docs docs/make.jl` — passed with existing local warnings
  for omitted internal docstrings, skipped deployment detection, substituted
  Vitepress defaults, missing logo/favicon, and npm audit output.
- `git diff --check` — passed.
- `gh run list --limit 5` — confirmed post-#138 `main` CI, Documenter, and
  Pages were green before this branch was finalized.
- `rg -n "fitted textbook Mrode|fitted Mrode validation is covered|missing fitted Mrode|missing from the Mrode lane|no fitted Mrode|not fitted Mrode|fitted Mrode output validation remains planned|fitted Mrode animal-model outputs are validated|published Mrode Example 3.1|Mrode Example 3.1" docs/design docs/src src test docs/dev-log --glob '!docs/build/**' --glob '!docs/node_modules/**'`
  — current edited surfaces now describe Example 3.1 as supplied-variance
  evidence; remaining older hits are historical after-task/check-log snapshots
  or intentional boundary language.

## 6. Tests of the Tests

The new test rejects EBVs perturbed by `+0.1` at the same `atol = 1e-6`
tolerance used for the published anchor. The status-row tests also require
`Mrode Example 3.1` in the `V1-MME` evidence and `not variance-component
estimation` in the claim boundary.

## 7a. Issue Ledger

- #46: this branch adds Julia-native published Example 3.1 supplied-variance
  evidence. The estimated-VC and same-estimand comparator parts remain open
  unless the PR review decides this is sufficient to close the issue as a
  narrower anchor.
- #49: unchanged and still next in sequence for comparator evidence.
- No R issue or file was changed from this Julia lane.

## 8. Consistency Audit

- Checked the immediate status surfaces:
  `src/validation_status.jl`, `test/runtests.jl`,
  `docs/design/04-validation-canon.md`,
  `docs/design/06-public-claims-register.md`,
  `docs/design/capability-status.md`,
  `docs/design/validation-debt-register.md`, and
  `docs/src/validation-status.md`.
- Confirmed the new evidence is consistently framed as supplied-variance
  published-anchor evidence.
- Left historical after-task/check-log entries untouched as time-stamped
  snapshots.

## 9. What Did Not Go Smoothly

The main statistical wrinkle was wording, not code: "fitted Mrode validation"
would overstate this slice because Example 3.1 uses supplied variance
components. The final wording credits the published EBV anchor while keeping
estimated-VC and same-estimand comparator gates explicit.

## 10. Known Residuals

- No variance components are estimated in the Mrode Example 3.1 test.
- No same-estimand external REML comparator is added.
- The R-lane Mrode Example 3.2 sire-model anchor is not mirrored in Julia.
- No covered-status promotion follows from this slice.

## 11. Team Learning

When the R lane supplies published textbook constants, Julia can safely consume
them as engine tests if the evidence class is stated narrowly. For Mrode
anchors, distinguish "published supplied-variance EBVs" from "estimated-VC
fitted-output comparator parity"; they answer different validation gates.
