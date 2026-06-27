# freqTLS t-calibration transfer note

Date: 2026-06-27

Status: local-method scout note. This is not HSquared.jl implementation
evidence and does not change interval defaults or public claims.

## Local Source

Local reference repo:
`/Users/z3437171/Dropbox/Github Local/freqTLS`.

Relevant local evidence:

- `docs/dev-log/after-task/2026-06-24-freqtls-phase-5-calibration.md:16-21`
  records the implemented rule: Wald intervals use `qt(df)` and profile
  intervals use `qt(1 - alpha / 2, df)^2` instead of a normal or chi-square-one
  cutoff.
- `docs/dev-log/after-task/2026-06-24-freqtls-phase-5-calibration.md:28-43`
  records the coverage evidence: 500 replicates per design; at median df about
  10, asymptotic CTmax coverage was about 0.927 and t-calibrated coverage about
  0.964.
- `R/utils.R:25-36` records `tls_ci_df(fit) = n_obs - length(par)`, and also
  records the caveat that for random-effects fits this overstates df because
  conditional modes are integrated out.
- `data-raw/calibration-study.R:1-64` records the simulation structure:
  z-versus-t Wald coverage, width, convergence filtering, and MCSE reporting.
- `R/profile.R:455-458` records the profile-t cutoff in code:
  `qt(1 - (1 - level) / 2, df = df_t)^2`.

## Transferable Pieces

- The cutoff form is relevant: a t-calibrated Wald interval uses the same SE
  estimate with a `qt` critical value; a profile-t interval uses the squared
  `qt` cutoff, which tends to the chi-square-one cutoff as df grows.
- The evidence standard is relevant: the calibration claim was made only after
  an in-repo coverage simulation with per-design coverage, widths, convergence
  counts, and MCSE.
- The implementation tests are relevant: freqTLS pinned df calculation, the
  t/z width ratio, and profile equivariance.

## Non-transferable Pieces

- The freqTLS df rule is not directly portable. `n_obs - length(par)` is
  defensible for its fixed-effect TMB likelihood slice, but HSquared.jl's
  Gaussian animal model integrates BLUPs and estimates variance components.
- The freqTLS note itself says random-effects df are approximate and can be
  overstated. HSquared.jl therefore must not adopt naive `n - p` as a default
  or public method without HSquared-specific coverage evidence.

## HSquared.jl Consequence

Keep the HSquared.jl harness focused on falsifying df probes:

- `residual_df_probe = n_animals - rank(X) - 2` is only a weak comparator.
- `family_df_probe = n_sire + n_dam - rank(X) - 2` is only a half-sib design
  proxy.

If a probe survives the no-bootstrap triage grid, the next implementation
slice should still be prototype-only and explicit in the label, with tests for
the cutoff form, method labels, width ratio, and profile cutoff equivalence.
No R-facing wording or default change follows from the freqTLS analogy alone.
