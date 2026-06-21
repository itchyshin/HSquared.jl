# After-Task Report: Genomic GBLUP/SNP-BLUP Comparator Target Fixture

## Live Phase Snapshot

As of this report, the slice starts from Julia `main` `934a91e` after #139
merged the Mrode Example 3.1 published supplied-variance anchor. During the
slice, the R lane reported `hsquared` PRs #62-#66 merged and R main refreshed
to `670931f`; R is waiting for the #49 comparator-route handoff. Covered public
status is unchanged: v0.1 univariate Gaussian animal-model support only. This
slice does not promote any validation row to covered.

## 1. Goal

Advance issue #49 from the Julia side by banking a deterministic
GBLUP/SNP-BLUP comparator target fixture that external tools or the R lane can
consume later, without claiming external comparator evidence.

## 2. Implemented

- Added `test/fixtures/genomic_gblup_snpblup_target/`.
- The fixture stores phenotype IDs/responses, marker dosages, supplied allele
  frequencies, positive-definite VanRaden method-1 `G`, `Ginv`, beta, GBLUP
  GEBVs, SNP-BLUP marker effects/GEBVs, metadata, README, and a no-RNG
  generator.
- Added the CI testset `Phase 2 genomic GBLUP/SNP-BLUP target fixture (#49)`.
- The test reads every CSV, recomputes `G`, `Ginv`, `fit_gblup`, and
  `fit_snp_blup`, checks route agreement to about `1e-15`, and rejects a
  perturbed GEBV.
- Updated `validation_status()` and status tests so `V2-GBLUP` and
  `V2-SNPBLUP` record the target while keeping external comparator parity
  listed as missing.
- Updated roadmap, validation canon, bridge compatibility matrix, public-claims
  register, capability status, validation-debt register, Documenter validation
  and genomics pages, changelog, coordination board, and check-log wording.

## 3a. Decisions and Rejected Alternatives

- Used supplied allele frequencies rather than re-estimating frequencies from
  the four-record marker sample, because the supplied-frequency target gives a
  positive-definite `G` and lets the precision-route GBLUP consume `inv(G)`
  without ridge regularization.
- Did not run BLUPF90/AIREMLF90 locally. The executable family is not present
  on PATH, and the repo already has a BLUPF90 starter packet for the multivariate
  comparator route.
- Did not activate any R-side genomic syntax or bridge payload. This is a
  Julia-owned target fixture only.
- Did not promote `V2-GBLUP` or `V2-SNPBLUP` to covered, because no independent
  same-estimand comparator has consumed the target yet.

## 4. Files Touched

- `ROADMAP.md`
- `src/validation_status.jl`
- `test/runtests.jl`
- `test/fixtures/genomic_gblup_snpblup_target/`
- `docs/design/04-validation-canon.md`
- `docs/design/06-public-claims-register.md`
- `docs/design/12-bridge-compatibility.md`
- `docs/design/capability-status.md`
- `docs/design/validation-debt-register.md`
- `docs/src/changelog.md`
- `docs/src/genomics-qtl-gpu-hpc.md`
- `docs/src/validation-status.md`
- `docs/dev-log/coordination-board.md`
- `docs/dev-log/check-log.d/2026-06-21-genomic-comparator-target-fixture.md`
- `docs/dev-log/after-task/2026-06-21-genomic-comparator-target-fixture.md`

## 5. Checks Run

- `julia --project=. test/fixtures/genomic_gblup_snpblup_target/generate.jl`
  — passed; regenerated the committed CSVs.
- `julia --project=. -e 'using Pkg; Pkg.test()'` — passed. The new #49 testset
  passed 22 checks inside the full suite.
- `julia --project=docs docs/make.jl` — passed with existing local warnings for
  omitted internal docstrings, skipped deployment detection, substituted
  Vitepress defaults, missing logo/favicon, and npm audit output.
- `Rscript /Users/z3437171/shinichi-brain/tools/check-after-task.R docs/dev-log/after-task/2026-06-21-genomic-comparator-target-fixture.md`
  — passed.
- `git diff --check` — passed.

## 6. Tests of the Tests

The new test corrupts the first serialized GBLUP GEBV by `+0.1` and verifies
the fixture check would reject it. Status-row tests also require the
`genomic_gblup_snpblup_target` evidence string and the "Julia-native comparator
target only" boundary.

## 7a. Issue Ledger

- #49: this branch completes the Julia-owned GBLUP/SNP-BLUP target-fixture
  slice. It does not close #49 because external comparator parity, genomic
  single-step targets, and non-Gaussian comparator targets remain open.
- R lane: no R files were touched. The intended handoff is for R/external tools
  to consume `test/fixtures/genomic_gblup_snpblup_target/` and record package
  versions, input translation, fitted beta/GEBVs/marker effects, and tolerances.

## 8. Consistency Audit

- Checked the status surfaces around `V2-GBLUP`, `V2-SNPBLUP`,
  `validation_status()`, validation debt, capability status, public claims,
  validation canon, bridge compatibility, roadmap, and Documenter pages.
- The fixture README and all status surfaces say target fixture, not external
  comparator evidence.
- The coordination board now records the current Julia/R boundary and the exact
  R handoff point.

## 9. What Did Not Go Smoothly

The statistical wrinkle was the tiny sample-centered VanRaden `G`: with
frequencies estimated from the sample it is singular, which is expected. Using
supplied allele frequencies gives a positive-definite comparator target and
avoids mixing the target with ridge-regularization behavior.

## 10. Known Residuals

- No AGHmatrix, sommer, BLUPF90, JWAS, ASReml, DMU, or WOMBAT comparator has
  consumed the target yet.
- No public R genomic model-spec or bridge activation.
- No sparse/APY scaling evidence.
- No weighted, standardized, Bayesian, or low-rank marker-prior support.
- No genomic single-step or non-Gaussian #49 target was added in this slice.

## 11. Team Learning

For genomic comparator fixtures, make the estimand and matrix convention
explicit before asking another lane to compare. A positive-definite
supplied-frequency `G` is a cleaner first target than a sample-centered singular
fixture when the comparison needs both precision-route GBLUP and marker-route
SNP-BLUP evidence.
