# FA ordinary-start primary recovery campaign launch

The frozen FA recovery campaign is running on Totoro CPU. These results are diagnostic for this cell; they do not establish covered status or release readiness.

## Approval and estimate

Shinichi approved the frozen 200-seed campaign on 2026-09-30 for Totoro CPU, with no GPU work. The initial estimate was about 18 hours, based on the Mac pre-run. A same-source Totoro pre-run completed in 36.285 seconds. The first four primary fits averaged 66.402 seconds, with a 91.141-second maximum; that gave a 10.2-hour conservative estimate. At 10 completed seeds, the mean is 80.9 seconds and the maximum is 127 seconds. The 10-seed conservative estimate was about 14.2 hours, using twice the then-current maximum across all 200 seeds. The later conservative stop/report bound is 14.4 hours. At 36 completed seeds and 54 minutes elapsed, the mean runtime is 89.82 seconds, suggesting about 5 hours total at the observed pace; later seeds may differ. This remains within the user-approved 18-hour window. The scope and seed stream did not change.

## Frozen run

- Driver: `sim/fa_ordinary_start_recovery_20260928.jl`
- Driver SHA-256: `2161449e2e320a6d56bf5b71b1927e18b3d3b4dd60704d30bae5aaafbf057e9b`
- `src/` tree SHA-256: `d3c2de8d7f0a1a86918f15938264bbdc892a7303b5ddd488553ac923f073ad0a`
- Julia: 1.10.0; Julia threads: 4; BLAS threads: 1
- Mode and seeds: primary, 20261200:20261399 (200 fits)
- Iteration cap: 5,000 per start, with two starts
- DGP: complete balanced Gaussian pedigree data, 60 animals, 4 traits, one genetic factor, 3 records per animal
- Output: `~/hsq_work/hsquared-fa-current-candidate-20260930/primary.tsv` on Totoro
- Log and PID: `primary.log` and `primary.pid` in the same Totoro directory
- Totoro PID at launch: 676046

## Exact-source pre-run

The first transfer carried macOS `._` metadata files inside `src/`, which changed the tree fingerprint. The primary was not started from that copy. Those metadata files were removed from the isolated Totoro staging directory, then the development pre-run was repeated and matched the candidate source and driver hashes above.

Seed 20261408 converged and met the frozen recovery rule. Totoro runtime was 36.285 seconds, with 1,650 iterations. The raw TSV is `2026-09-30-fa-totoro-exact-source-prerun.tsv` (SHA-256 `7cfc0f4aa45f68614fe281b9280b0b892d0a0e866ec91ec651b2ba273f90dc1a`). One seed confirms the runtime and the recovery rule; it cannot estimate the recovery frequency.

## Progress snapshot

After four of 200 seeds, three meet the recovery rule and one is classified `G_error`. The mean fit runtime is 66.402 seconds; the maximum is 91.141 seconds. Each row is flushed to the TSV as it finishes. At 10 seeds, six meet the recovery rule, two are `G_error`, one is `R_error`, and one is `nonconverged`; mean runtime is 80.9 seconds and the maximum is 127 seconds. The driver does not resume an interrupted primary stream, so preserve snapshots before any restart decision. At the independently validated 36-seed prefix, 21 are recovered, 3 are G errors, 2 are R errors, and 10 are nonconverged. The repaired independent output validator passes 22 tests and refuses to mark an incomplete prefix as complete. These are partial results.

## Independent reviews

The Gauss numerical review (GPT-6 Astra High) checked the exact source and driver hashes above. It found no reason to stop or change the frozen campaign. It confirmed the REML likelihood comparison and covariance-scale errors. The 5,000 iteration limit applies to each of two starts; the selected-start count is not total optimizer work. A recovered fit can still carry near-floor or better-nonconverged-start flags, so report those separately. Beating the generating likelihood is an optimization check, not proof of a global optimum.

The Curie validation review (GPT-6.1 Sol High) independently verified the fixed 200-seed stream, separation from development and prior streams, and retention of exceptions in the denominator. It found no blocking campaign defect. Closeout must check all 200 ordered, unique rows and 23 columns, source and driver hashes, and independently recompute recovery counts, MCSE, and Wilson limits. The driver does not resume an interrupted primary stream, and the preregistration sets no campaign-level pass cutoff.

## Interpretation and follow-up

All 200 requested seeds remain in the denominator. Nonconvergence, exceptions, and non-recovery outcomes remain recorded. The thresholds are carried as conservative diagnostics from the earlier frozen S2 work and are not a validated ordinary-start accuracy standard. No covered-status change follows from this campaign alone.

Monitor the streamed TSV and log. Re-estimate from completed seeds. If the run reaches the current 14.4-hour monitoring bound before completion, stop and report before extending it. After completion, copy the raw TSV into this checkpoint directory, verify its source and driver hashes, summarize every outcome class, then complete the acceptance ledger and after-task report.

## Validated 75-seed prefix

The 2026-09-30 snapshot contains 75 ordered primary seeds. Independent scalar validation reports 45 recovered, 10 G errors, 4 R errors, and 16 nonconverged. All 75 attempts remain in the denominator. The recovery fraction is 0.60, with Monte Carlo standard error 0.05657 and Wilson 95% limits 0.48688–0.70337. These are partial diagnostic results, with no campaign-level pass cutoff or capability decision. The mean fit runtime is 76.975 seconds and maximum 137.892 seconds. The existing 14.4-hour stop/report bound is retained.

Snapshot TSV SHA-256: `b39aee659a8b02c3b34b56f42198b4e82b1700374ece56721db15bcdb44e6973`. Local scratch snapshot: `/private/tmp/fa-primary-live-snapshot-20260930.tsv`; summary: `/private/tmp/fa-primary-live-summary-20260930.json`. Full matrix quantities cannot be reconstructed from the scalar projection. One uniqueness-floor comparison is rounding-ambiguous; the recorded driver classification remains compatible. Near-floor and better-nonconverged-start flags are retained separately.

## Validated 99-seed prefix

The next preserved prefix has 99 ordered seeds: 59 recovered, 13 G errors, 6 R errors and 21 nonconverged. No exception or nonfinite class is recorded. All attempts remain in the denominator. The mean runtime is 72.87257 seconds, maximum 137.89158 seconds. This is incomplete diagnostic evidence; no acceptance cutoff has been added. TSV SHA-256: `874e5cbebb0c641bdee437004edb2d8d610e805527fa429cb4627d6b294a67c3`. It is retained at `/private/tmp/fa-primary-next-snapshot-20260930.tsv`, with summary `/private/tmp/fa-primary-next-summary-20260930.json`. The earlier 75-row snapshot is separately preserved under `/private/tmp/fa-primary-partial-20260930/75/`. The existing 14.4-hour stop/report bound remains.

## Retained 115-seed prefix, 2026-09-30

The immutable prefix and validator summary are retained under `docs/dev-log/recovery-checkpoints/fa-primary-partials-20260930/115/`. All 115 attempts are counted: 67 recovered, 13 genetic-covariance error, 7 residual-covariance error and 28 nonconverged. Exceptions, nonfinite outcomes and below-truth-objective classifications are zero. Diagnostic near-floor flags occur in 8 rows, including 4 classified recovered; one recovered row has a better nonconverged start. These flags are retained rather than silently excluded. The recovery rate is 0.5826087, Monte Carlo standard error 0.04598448, Wilson 95% interval [0.49123893, 0.66863793]. Mean per-row runtime is 71.901843 seconds. This prefix is incomplete and is not a campaign-level acceptance decision.

Raw TSV SHA-256 `b8a0ef6563febef33ed017ce03c7a605645a2b4886e530767450c0f5529fa582`; source tree and original primary driver pins are unchanged. The original process remains running without restart.
