# GLLVM current-source ordinary-start replay checkpoint

## 1. Goal

Check whether the frozen ordinary-start Poisson GLLVM recovery result reproduces on the current Julia source snapshot, after source changes made since the original run.

## 2. Implemented

Replayed the same 50 preregistered seeds against the current source bundle on Totoro. The replay left the frozen primary TSV unchanged and retained all six unique entries of each fitted genetic covariance matrix. Separately recomputed the DGP's Poisson means for those seeds to check the original product-based sampler's underflow risk.

## 3a. Decisions and Rejected Alternatives

This replay audits the frozen primary result under current code using the same seeds. It adds code-version reproducibility evidence while leaving the population sample unchanged. Preserve the original primary result and its original driver. Use the unchanged DGP, rank, default loading start, iteration limits, and success thresholds. Do not add retries or use truth to select a fit.

## 4. Files Touched

- `sim/phase6_gllvm_current_source_replay_20260929.jl`
- `docs/dev-log/recovery-checkpoints/2026-09-29-gllvm-current-source-replay.tsv`
- This report.
- `docs/dev-log/check-log.d/2026-09-29-gllvm-current-source-replay.md`

No fitter source, public API, or existing result file was changed.

## 5. Checks Run

- Independently parsed the original primary TSV: all 50 frozen seeds occur once, all recorded fit and convergence flags pass, and all recorded relative-G, correlation, and PSD thresholds pass. Recomputed its Wilson 95% interval as [0.9286524, 1.0000000].
- Verified the source archive used for that run against its recorded hash: `1475066d4b6ff67df3c5adb2a303a96e20b3f7d8fd06e67a0dc283b96636dc0a`.
- DGP-only replay on Totoro examined 18,000 rate cells across seeds 20261600 to 20261649. Maximum rate was 86.7194767488 at seed 20261621; no `exp(-lambda)` value underflowed to zero.
- Current-source replay ran on Totoro with Julia 1.10.0, four Julia threads, and one BLAS thread. It completed 50/50 full successes in 141.68 seconds; every row met the frozen rule. The Wilson 95% interval was [0.9286524, 1.0000000].
- Current replay source bundle SHA-256: `6def389126ebc31e49da58ae8d7197a5a5e8fb8f26ba2873a6d052a056d81e96`. Replay driver SHA-256: `6b5ebdbdd58c22860a3f6c54a552677d2d9d149a5a07fbd93aecc61a22791ff9`. Retained result TSV SHA-256: `02f0af3c974691007acb39e55d07c499fd42705e8dbf4d050587c1d889faa030`.
- Recomputed relative-G error, mean absolute genetic-correlation error, and minimum eigenvalue from each retained covariance matrix. Maximum absolute discrepancies from the logged values were 2.04e-12, 2.21e-12, and 5.76e-12, respectively. Relative-G and correlation errors match the original primary per seed within 2.04e-12 and 2.21e-12; per-seed log likelihoods match exactly.
- Totoro hygiene reported 0 zombies, no stopped supervisors, no stale watchers, and 0 busy process from this task.

## 6. Tests of the Tests

The replay used the exact frozen seed sequence and success criteria. Every output row retains outer and inner convergence, stop reason, iterations, covariance entries, and the failure class. An independent parser reconstructed G and recalculated the reported errors from the retained entries.

## 7a. Issue Ledger

- Closed for this seed stream: the original DGP rates did not trigger the identified `exp(-lambda)` underflow condition.
- Closed for current-source reproducibility in this cell: all 50 frozen seeds reproduced their recovery classification, logged error metrics, and objective to rounding or exactly.
- Open: the original TSV did not contain covariance matrices; the current replay does. The original fit matrices therefore cannot be compared entry-by-entry with the new replay.
- Open: broader recovery, calibration, a matched external comparator, and R-to-Julia parity.

## 8. Consistency Audit

The current replay used the same complete, balanced, 120-animal known-pedigree Poisson-log cell, three traits, rank two, pure low-rank G, trait intercepts, default loading start, and fixed iteration limits. It does not change capability status or the bounded R route.

## 9. What Did Not Go Smoothly

The frozen primary result had scalar covariance-error summaries but no retained matrices. The current replay driver therefore adds the six unique covariance entries to its separate output. No changes were made to the preregistered thresholds or original primary artifact.

## 10. Known Residuals

This is one simulated cell with 50 seeds. Its interval is broad and does not establish calibration or high-precision recovery. No other family, rank, missing-data pattern, genetic structure, real-data example, EBV accuracy, matched external comparator, or public capability claim is covered. The broader GLLVM remains experimental; G4/G6 and the overall A2/E1/V3 gates remain open.

## 11. Team Learning

The numerical and validation reviewers confirmed the ordinary-start evidence already existed and recommended auditing its retained seed rows and source provenance before rerunning. A current-source replay was justified because the engine source had changed since the frozen primary. The rate audit addressed the runner's simple product-based Poisson sampler without changing or replacing the original result.

## 12. Cross-Product Coverage

This slice covers current Julia-source replay and output audit for the single experimental Poisson genetic GLLVM cell. It does NOT cover R-to-Julia parity, other response families, missing records, FA uniqueness, automatic rank selection, broad calibration, external comparator validation, public promotion, GPU work, or release activity.
