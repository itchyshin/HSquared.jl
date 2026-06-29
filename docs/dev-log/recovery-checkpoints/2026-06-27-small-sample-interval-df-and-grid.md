# Small-sample interval df probes and grid checkpoint

Date: 2026-06-27

Status: pre-implementation note. No interval method, default, R surface, or
public claim changes.

## DF Probes

The current harness keeps two t-quantile probes:

| Probe | Formula in the harness | Why it is included |
| --- | --- | --- |
| `residual_df_probe` | `n_animals - rank(X) - 2` | A familiar shortcut, included as a weak comparator. It is not a recommended animal-model df because the random effects are integrated out. |
| `family_df_probe` | `n_sire + n_dam - rank(X) - 2` | A half-sib design proxy for family-level information. It is a DGP-specific probe, not a general derivation. |

The `-2` term is the two variance-component scalars in the current v0.1
Gaussian animal model. This is deliberately a probe-level convention. A real df
choice must be justified by simulation behaviour and Fisher/Curie review before
it is allowed near interval-method code.

## Grid Shape

The harness now accepts named half-sib designs:

```sh
--designs=tiny:4:8:24,small:8:16:96,medium:16:32:192
```

Those labels expand to:

| Label | Sires | Dams | Offspring | Animals |
| --- | ---: | ---: | ---: | ---: |
| `tiny` | 4 | 8 | 24 | 36 |
| `small` | 8 | 16 | 96 | 120 |
| `medium` | 16 | 32 | 192 | 240 |

The predeclared triage truths are `h2 = 0.1, 0.4, 0.7` at confidence levels
`0.90` and `0.95`. The low-heritability condition is deliberately included
because asymptotic and profile intervals can fail or clamp near the boundary.

## Evidence Fence

The multi-design smoke check is executable evidence for the harness shape only.
It is not calibration evidence. A useful triage table needs about 200 replicates
per cell; promotion-grade coverage needs at least 500 replicates per cell and a
separate plan for bootstrap Monte Carlo error.

## freqTLS Transfer Note

The local `freqTLS` folder is a useful precedent for the cutoff form and evidence
standard, not for directly importing a df rule. Its Phase 5 calibration used
`qt(df)` for Wald intervals and `qt(1 - alpha / 2, df)^2` for profile cutoffs,
then justified the change with a 500-replicate-per-design coverage simulation.
However, `freqTLS` uses `n_obs - length(par)` and explicitly notes that this can
overstate df for random-effects fits because conditional modes are integrated
out. HSquared.jl therefore keeps `residual_df_probe` and `family_df_probe` as
probes only until the HSquared-specific grid says otherwise.

See `docs/dev-log/scout/2026-06-27-freqtls-t-calibration-transfer.md`.

## NotebookLM SW/Satterthwaite Note

The NotebookLM algorithm notebook points to a stricter mixed-model framing. For
fixed effects, Satterthwaite and Kenward-Roger corrections are denominator-df /
covariance-adjustment methods for beta-hat inference. They are not automatically
variance-component or heritability interval methods.

For `sigma_a2`, the more relevant Satterthwaite-style candidate is a
method-of-moments effective df for a scaled chi-square reference distribution,
not another naive t multiplier. A first probe would use
`df_eff = 2 * estimate^2 / Var(estimate)`, with strong boundary guards and a
clear `sigma_a2_satterthwaite_chisq_probe` label. For `h2`, any analogous df is
less direct because h2 is a bounded ratio; simulation evidence must decide
whether a delta-scale or logit-scale probe is defensible.

See `docs/dev-log/scout/2026-06-27-notebooklm-sw-mixed-model-calibration.md`.

## 200-replicate Triage Outcome

The first 200-replicate no-bootstrap triage grid was run with the
`sigma_a2_satterthwaite_chisq_probe` included. Summary:

- residual/family t probes are baselines only; they did not show a clear h2 win;
- `sigma_a2_satterthwaite_chisq_probe` was unstable in low-h2 small designs and
  often much wider than profile-LRT;
- profile-LRT remains the stronger non-bootstrap interval family in this grid;
- no method is promoted.

See
`docs/dev-log/recovery-checkpoints/2026-06-27-small-sample-interval-calibration-triage-summary.md`.
