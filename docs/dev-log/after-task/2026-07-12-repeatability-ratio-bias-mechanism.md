# After task: repeatability ratio-bias mechanism analysis

## 1. Goal

Use only the already-banked 2,000-seed confirm data to assess whether the realized
repeatability bias is arithmetically consistent with ratio nonlinearity, without new fits,
new seeds, resampling, gate reinterpretation, or capability promotion.

## 2. Implemented

- Wrote the symbolic ratio decomposition, Hessian, uncertainty influence functions, and
  symbol-to-TSV alignment table before analysis code.
- Added a deterministic Julia analysis module/CLI that hash-checks the four raw inputs,
  validates schema/config/truth/seeds/convergence, reconstructs stored ratios, reproduces the
  original gate, performs the exact decomposition, and writes a four-row TSV.
- Added pure-logic self-tests for constant components, proportional scaling, paired-covariance
  sensitivity, row-order invariance, exact closure, stored-ratio mutation, and the analytic
  versus finite-difference Hessian.
- Ran the analysis on local temporary copies of the unchanged `fir` TSVs. No raw replicate
  file was committed.
- Independently reproduced the four exact decomposition rows in base R.
- Recorded the post-hoc result in capability status and the coordination board without a
  status/count move.

## 3a. Decisions and Rejected Alternatives

- Used the exact two-component estimand `s=sigma2_a+sigma2_pe`, `e=sigma2_e`; rejected
  path/order-dependent attribution of `t` separately to additive versus permanent-environment
  components.
- Used influence-function MCSEs and normal Monte Carlo intervals; rejected a resampling
  bootstrap so the analysis remains deterministic and creates no additional random seed stream.
- Used the supplied-K cells only as pipeline controls/contrasts; rejected treating them as a
  causal negative control because their estimator, DGP, and identifiability differ.
- Rejected “mechanism confirmed,” “engine defect excluded,” “expected behavior,” “essentially
  passes,” or “unbiased.” The strongest allowed conclusion is “consistent with ratio
  nonlinearity in this realized convergence-conditional sample.”
- Rejected any gate or status change. The original confirm failure remains load-bearing.

## 4. Files Touched

- `sim/repeatability_ratio_bias_analysis.jl`
- `Project.toml`
- `test/runtests.jl`
- `docs/dev-log/recovery-checkpoints/2026-07-12-repeatability-ratio-bias.tsv`
- `docs/dev-log/recovery-checkpoints/2026-07-12-repeatability-ratio-bias-mechanism.md`
- `docs/design/capability-status.md`
- `docs/dev-log/coordination-board.md`
- `docs/dev-log/check-log.d/2026-07-12-repeatability-ratio-bias-mechanism.md`
- `docs/dev-log/after-task/2026-07-12-repeatability-ratio-bias-mechanism.md`

## 5. Checks Run

- Mandatory git/worktree/branch/stash/twin/brain sweep: clean `main` at `6b92c652`; no
  pre-existing ratio-bias analysis found.
- Two pre-run reviews: Fisher/Curie GO with formula/uncertainty corrections; Rose/Gauss
  APPROVE-WITH-CHANGES with strict no-rescue wording and negative controls.
- Four SHA-256 input checks; exact row/seed/config/truth/convergence checks passed.
- Exact ordered input-schema guards passed; a deliberately reordered schema fails.
- Original repeatability result reproduced: 1,999/2,000 converged, bias `-0.00120188`,
  MCSE `0.00056574`, `gate_pass=false`.
- Independent base-R arithmetic matched Julia `m`, total bias, plug-in mean shift, and
  nonlinear term to `<5e-11` for all four rows.
- Wrong-hash negative control exited 1 with `SHA-256 mismatch`.
- `~/.juliaup/bin/julia --project=. -e 'using Pkg; Pkg.test()'`: PASS, including the new
  pure-logic testset.
- Full analysis rerun: byte-identical output SHA-256
  `e247d525bb0eed937dc52bb23f193a608ccf90094eb0a9bcc638b484ea3b5e05`.
- `git diff --check`: PASS.
- `bash tools/preamble_cap.sh`: PASS (1 live snapshot; 12,012 bytes).
- `Rscript shinichi-brain/tools/rose-pattern-scan.R .`: PASS.
- `Rscript shinichi-brain/tools/check-after-task.R ...`: PASS.
- `python3 shinichi-brain/tools/closeout.py check ...`: PASS.
- Independent final Fisher/Rose audit: PROMOTE-WITH-CHANGES; all numerical formulas,
  influence-function MCSEs, and covariance calculations matched independently to `3.8e-15`.
  Its two requested precision fixes were applied: exact ordered schemas are enforced, and the
  analysis-only criterion is named `ratio_bias_pass` rather than implying the full supplied-K gate.

## 6. Tests of the Tests

- The first Hessian self-test went red before any real-data analysis: `2f0` was parsed by
  Julia as the Float32 literal `2.0f0`, not multiplication. Correcting it to `2 * f0`
  restored agreement with finite differences.
- The first real-data run stopped on an over-tight ratio-reconstruction tolerance. The source
  independently serializes components and ratios with `%.10g`, producing a legitimate
  `1.004e-8` difference. The guard was set to `2e-8`; a deliberate `1e-6` mutation still fails.
- A deliberately wrong repeatability SHA-256 fails before analysis.
- A paired permutation preserves component means while changing the nonlinear term, proving
  that the test is sensitive to the seed-level joint distribution rather than only margins.
- Constant and proportional-scaling fixtures yield zero nonlinear term; reverse row order is
  invariant; decomposition and influence contributions close to machine precision.
- The independent R checker initially went red because lowercase `"true"` was read as
  character, exposing an invalid parser assumption; explicit logical mapping then reproduced
  the Julia results.
- The first full isolated `Pkg.test()` run reached the new testset and went red twice, first
  because `SHA` and then because `Statistics` were absent from the isolated test target. Both
  standard libraries are now explicit test extra/target dependencies; the full suite was rerun
  from a fresh test environment.

## 7a. Issue Ledger

- RESOLVED: the deferred ratio-nonlinearity hypothesis now has a bounded post-hoc arithmetic
  analysis.
- CONFIRMED: 89.7% of the realized repeatability bias is the exact nonlinear-averaging term;
  the second-order curvature diagnostic matches it to about 99%.
- CONFIRMED: supplied-K cells show the same negative ratio-curvature signature but different
  plug-in cancellation; this is contrast evidence only.
- CORRECTED HERE: capability wording now records consistency rather than leaving the analysis
  as wholly unexamined.
- DEFERRED TO R LANE: sibling prose that says “not an engine defect” or treats
  ratio-nonlinearity as established should be softened; this Julia-lane slice does not edit the
  R public contract.
- UNCHANGED: repeatability interval coverage, external comparator, deeper DGP ladder, and
  additive/permanent split validation remain open.

## 8. Consistency Audit

Checked doc 34, both 2026-07-12 provenance/evidence reports, the repeatability and supplied-K
driver schemas, ROADMAP, capability status, validation debt, validation canon, coordination
board, and R-twin results/handover. The new analysis preserves the original convergence filter,
truth, seed bank, MCSE, and failed verdict. No public claim, result payload, formula grammar,
or estimator code changed.

Neighbouring language was swept for the stronger “mechanism confirmed / engine defect excluded /
essentially passes / unbiased” class. The Julia surfaces use descriptive, post-hoc wording. The
R-twin overstatement is recorded as a separate-lane correction rather than silently edited here.

## 9. What Did Not Go Smoothly

- The second-brain semantic query returned unrelated ratio/delta notes; repo/twin state remained
  the technical source of truth.
- Two negative controls found real test/serialization assumptions before the final run (`2f0`;
  independent `%.10g` roundoff).
- The independent R verifier initially mishandled lowercase character booleans and was corrected
  before comparison.
- The analysis is necessarily post hoc because it was motivated by the observed marginal fail.

## 10. Known Residuals

- One nonconverged seed (`20280439`) has unknown contribution and is not imputed; results are
  explicitly conditional on 1,999 converged fits.
- Influence-function intervals are normal Monte Carlo approximations for this fixed seed bank,
  not applied-data confidence intervals.
- Arithmetic decomposition does not identify causality or exclude an optimizer/engine
  contribution.
- The supplied-K contrast is not matched on estimator, DGP, or identifiability.
- The result does not generalize beyond the wellpowered half-sib four-record DGP without new,
  separately preregistered evidence.
- R-twin prose correction remains a coordinator/R-lane task.

## 11. Team Learning

Memory receipt: loaded the HSquared route manifest, `hsquared-rehydrate`, `ultra-plan`,
`quantitative-analysis`, `symbolic-alignment`, `validation-harness`,
`validation-canon-review`, `hsquared-team-dispatch`, and `after-task-audit`. Symbolic-first
alignment forced the exact estimand to be `s=a+pe`, prevented arbitrary a-versus-pe
attribution, and supplied the finite-difference test that caught the Julia literal bug.

Golden Set: recovery-to-truth, no-rescue, external-state verification, test-the-test, and
partial-claim negative-space guards all fired. The banked fail remained unchanged even though
the post-hoc mechanism signature is strong.

Durable lesson: for a ratio estimand, report the exact ratio-of-means versus mean-of-ratios
identity before invoking Jensen/delta language. It separates arithmetic fact from mechanistic
interpretation and shows when component-mean bias cancels rather than reinforces curvature.

## 12. Cross-Product Coverage

Covers: deterministic analysis of the banked repeatability `t` confirm rows; exact plug-in versus
nonlinear apportionment; second-order ratio curvature; seed-level Monte Carlo uncertainty; the
three supplied-K confirm cells as analysis-pipeline contrasts; schema/hash/truth/convergence
guards; pure-logic self-tests.

Does NOT cover: new simulation or fitting evidence; the excluded nonconverged seed; causal
mechanism identification; engine exoneration; additive-versus-permanent split recovery;
repeatability interval coverage; an external comparator; other DGPs, sample sizes, pedigrees,
record counts, optimizers, or non-Gaussian models; R public wording; any gate rescue, capability
promotion, validation-status change, or change to `public_covered_count`.
