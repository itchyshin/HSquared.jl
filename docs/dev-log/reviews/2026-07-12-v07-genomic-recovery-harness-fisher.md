# Fisher/Noether audit — v0.7 genomic recovery harness

**Date:** 2026-07-12  
**Reviewed commit:** `1f91763d518a5c943817f714d3ab55b8d5b3f022`  
**Initial verdict:** **CHANGES_REQUIRED**  
**Recheck verdict:** **CLEAN FOR THE JULIA DIAGNOSTIC HARNESS; NOT END-TO-END
CROSS-TWIN RECOVERY**

## Scope

I reviewed `sim/phase2_v07_genomic_activation_recovery.jl` and
`sim/totoro/v07_genomic_activation_recovery.sh` against G5--G6 of the frozen
cross-twin contract in `hsquared/docs/design/44-v07-genomic-public-activation.md`.
This is a design and executable-harness audit, not a verdict on recovery: no
pilot or confirmation results were available for this review.

## Recheck of required changes

1. **RESOLVED — confirmation size now uses the frozen upper pilot
   dispersion.** The
   frozen contract requires the one-sided 95% upper confidence bound
   `s_U = s * sqrt((n_conv-1) / qchisq(0.05, n_conv-1))` before applying the
   confirmation-size formula. The harness instead inserts the raw pilot SD
   directly (`phase2_v07_genomic_activation_recovery.jl:381-386`). With 48
   converged pilots, `s_U/s = 1.206884`, so the required sample size can be
   about `1.4566` times the former value. The harness now implements the
   dependency-free chi-square quantile, records `pilot_sd_upper`, and uses it
   in the confirmation-size calculation. Executable self-tests reproduce
   `qchisq(0.05,47) = 32.2676215299734` and `s_U/s = 1.206883783222353`.

2. **ACCEPTED EVIDENCE BOUNDARY — the simulated fit is not the preregistered
   end-to-end candidate marker route.** G5 freezes an end-to-end fit of the candidate marker route. The
   driver calls the internal Julia construction helper and then
   `fit_gblup_reml(..., construction.Q)` directly
   (`phase2_v07_genomic_activation_recovery.jl:135-145`). That is good evidence
   for Julia construction plus supplied-Q recovery, but it bypasses the public
   R formula, R validation/marshalling, and marker-route result contract. Either
   orchestrator has accepted this as a deliberately narrower Julia diagnostic:
   no R route was added, activation remains held, and output must not be
   described as end-to-end cross-twin recovery. A later public-route gate is
   still required for activation.

3. **RESOLVED — campaign state is immutable and environment-bound.** Manifest
   creation now requires an empty output directory, a clean git worktree, and
   an instantiated `Manifest.toml`; it exclusively creates pilot/environment
   manifests and checksum sidecars. Every run, resume, and summarization
   validates the clean worktree, git root and commit, Julia version, ridge,
   pilot count, driver SHA, `Project.toml` SHA, `Manifest.toml` SHA, pilot
   manifest SHA, and (for confirmation) the confirmation-manifest sidecar.
   The launcher reuses rather than overwrites valid state, rejects output paths
   inside the repository, and enforces the measured RAM cap for both automatic
   and explicit confirmation concurrency.

4. **RESOLVED FOR JULIA-OWNED FIELDS — mutations now turn the harness red.**
   Ridge is stored per seed. Every result must occupy the exact tier/cell/seed
   path and match an immutable manifest row for `n`, `m`, all three truths, and
   ridge. The summarizer regenerates markers from the frozen cell and seed,
   reconstructs `K_lambda`, and independently recomputes the marker, ID-order,
   and kernel fingerprints before accepting a row. Executable negative
   controls prove failures for truth, ridge, marker hash, ID-order hash, kernel
   hash, and cell-label mutations; duplicate seeds remain rejected. The other-
   language independent recomputation remains a separate G6 obligation.

## Checks that passed

- The nine frozen cells and three coefficient-scale ratios are encoded
  correctly (`n,m` = `120,600`; `300,150`; `300,1000`, crossed with
  `0.2,0.5,0.8`).
- Marker generation is independent HWE hard calls with population MAF drawn
  uniformly on `[0.05,0.5]`; realized monomorphic columns are removed; the
  fitted kernel uses the sample-frequency construction and ridge `0.01`.
- The DGP matches the coefficient-scale target:
  `u ~ N(0, sigma_g2 K_lambda)`, independent residual variance
  `sigma_e2 = 1-sigma_g2`, one record per individual, intercept only.
- Pilot and maximum confirmation seed blocks are disjoint. A generated pilot
  manifest had 432 unique cell-seed rows: 48 in each of nine cells.
- Failed/nonfinite seeds remain in the convergence denominator; bias is
  convergence-conditional; confirmation uses a two-sided Student-t Monte Carlo
  interval; the strict equivalence inequalities, 95% observed convergence, and
  90% Wilson-lower-bound gates are implemented.
- The launcher caps workers at 96, pins Julia/BLAS-related thread variables to
  one, and retains raw output outside git by default. `bash -n` passed.
- Numerical spot checks passed: `_tquantile(0.975,47) = 2.011740513729766` and
  the 46/48 Wilson interval was `(0.8602434413, 0.9884981065)`.
- The repaired `--mode=selftest` passed. A fresh clean temporary clone then
  created a 432-row sealed pilot manifest, ran one real seed, validated a
  resume, summarized the deliberately incomplete pilot as `INCOMPLETE`,
  refused manifest overwrite, rejected a mutated truth row, and rejected an
  output directory inside the repository. `git diff --check` and `bash -n`
  passed.
- An additional local clean-clone exercise ran all 48 frozen pilot seeds for
  `n120_m600_r020`. It produced 36/48 converged rows and the repaired harness
  correctly returned `STOP_LOW_PILOT_CONVERGENCE`; the upper-SD sizing path was
  exercised for all three targets. This temporary-clone exercise is a smoke
  test of the decision machinery, not campaign evidence or a Totoro result.

## Evidence boundary

The accepted repair changes the raw schema, confirmation-size rule, and campaign
seal. Therefore a fresh clean commit, fresh out-directory, and fresh pilot are
required; rows from the pre-repair harness cannot be reused. A green harness
would support only exact-model
recovery for independent HWE/no-LD markers, sample allele frequencies,
VanRaden1, ridge `0.01`, the nine declared cells, and the coefficient-scale
genomic variance ratio. It would not establish LD, structure, imputation,
base-frequency robustness, production scale, pedigree heritability, release
readiness, a capability-count change, or maintainer G10 approval.
