# H3 convergence-accounting correction — check log

- Audit finding: `_record_ci` previously set `interval_success` from
  `fit_success && finite endpoints`; a finite `r_g` interval from an
  unconverged multivariate fit could therefore enter the coverage denominator.
- Regression test was written first and observed red: 4 expected assertions
  failed because the unconverged interval was marked successful and covered.
- The shared record helper now requires `fit_converged`; an unconverged
  finite interval is retained with `failure_reason = "fit_not_converged"` and
  `NaN` endpoints/width.
- Focused scaffold test: **102/102 pass**.  It includes the current H3 driver
  while using the sealed H1 sibling environment because candidate `4d4a55c`
  has no `Manifest.toml`; `git diff 4d4a55c..H1-head -- src` is empty.
- Standalone evidence validator: `A2_EVIDENCE_INFRA_TESTS_OK` and
  `A2_MUTATION_CONTROLS_OK`.
- No smoke, simulation, scheduler submission, remote transfer, promotion,
  version, tag, registry action, or release occurred.
