# Small-sample interval calibration decision checkpoint

Date: 2026-06-27

Decision: do not implement or expose a t-calibrated / Satterthwaite-calibrated
Gaussian interval method yet.

## Evidence in hand

- Current package intervals remain asymptotic: normal-z delta/Wald intervals and
  chi-square-one profile-LRT intervals.
- The planned debt row `V1-HERIT-TCAL` records the missing finite-sample
  calibration path.
- The no-bootstrap 200-rep triage grid found no clean win for residual-df or
  family-df t probes for h2.
- The current `sigma_a2_satterthwaite_chisq_probe` can behave reasonably in
  some medium/high-information cells, but it is unstable in low-h2 small designs
  and can fail or become very wide.
- The focused bootstrap subset proves the resumable bootstrap path is wired; it
  is too small to support coverage conclusions.
- NotebookLM and freqTLS scouting support the general idea of calibrated
  finite-sample cutoffs, but not a transferable animal-model df rule.

## Boundary

No API, no interval default, no `validation_status()` row, no capability-status
promotion, and no R-facing wording should be added from this evidence.

## Next technical move

If this lane continues, do not add an interval method first. Instead:

1. Stage or clone this branch on DRAC `/project`.
2. Run the resumable harness through SLURM with one array task per design/truth
   cell or per replicate block.
3. Use the detail TSV diagnostics (`df_eff`, `failure_reason`, `near_boundary`,
   bootstrap convergence counts, widths) to decide whether a better effective-df
   derivation is worth implementing.
4. Only after Fisher + Curie + Rose review should a prototype method label be
   considered.

Profile-LRT and bootstrap remain the safer finite-sample interval families to
calibrate first.
