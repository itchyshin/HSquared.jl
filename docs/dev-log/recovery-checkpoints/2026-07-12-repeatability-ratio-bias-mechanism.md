# Repeatability ratio-bias mechanism analysis

Date: 2026-07-12. Status: **POST-HOC DETERMINISTIC ANALYSIS COMPLETE — non-promoting.**

This analysis uses only the already-banked doc-34 confirm TSVs. It creates no new fit,
simulation replicate, or random resample. Its purpose is descriptive: apportion the realized
repeatability-ratio bias arithmetically, not rescue the failed gate or prove a causal mechanism.

## Symbolic target

For converged replicate `i`, define

\[
s_i = \widehat{\sigma^2_{a,i}} + \widehat{\sigma^2_{pe,i}},\qquad
e_i = \widehat{\sigma^2_{e,i}},\qquad
g(s,e)=\frac{s}{s+e}.
\]

The fitted repeatability is `t_i = g(s_i,e_i)`. Let `(s0,e0)` be the DGP truth and
`(sbar,ebar)` the component means over the 1,999 converged rows. The observed gate bias has
the exact identity

\[
B_{total}
= \overline{g(s_i,e_i)}-g(s_0,e_0)
= \underbrace{g(\bar s,\bar e)-g(s_0,e_0)}_{B_{mean}:\ plug\text{-}in\ mean\ shift}
+ \underbrace{\overline{g(s_i,e_i)}-g(\bar s,\bar e)}_{B_{nonlinear}:\ nonlinear\ averaging}.
\]

`B_mean` is not “pure component bias”; it is the ratio evaluated at the mean fitted
components. `B_nonlinear` is the exact empirical Jensen/nonlinearity gap in this realized,
convergence-conditional seed bank. The identity does not attribute `t` separately to additive
and permanent-environment components because only their sum `s` enters the estimand.

## Second-order diagnostic

At `D=s+e`,

\[
\nabla g(s,e)=\left(\frac{e}{D^2},-\frac{s}{D^2}\right),\qquad
H_g(s,e)=\frac{1}{D^3}
\begin{pmatrix}
-2e & s-e\\
s-e & 2s
\end{pmatrix}.
\]

Using the empirical covariance with divisor `m`, evaluated at `(sbar,ebar)`, the
second-order approximation is

\[
B_{nonlinear}^{(2)}
=\tfrac12\operatorname{tr}\{H_g(\bar s,\bar e)S_m\}
=\frac{-\bar e\operatorname{Var}_m(s)
+(\bar s-\bar e)\operatorname{Cov}_m(s,e)
+\bar s\operatorname{Var}_m(e)}{(\bar s+\bar e)^3}.
\]

The analysis reports the remainder `B_nonlinear - B_nonlinear^(2)`. Agreement is a numerical
diagnostic, not causal proof.

## Uncertainty

No hypothesis test or new bootstrap is used. Normal-approximation 95% Monte Carlo intervals
come from seed-level influence contributions:

- total: `IF_total,i = t_i - mean(t)`;
- plug-in mean shift: `IF_mean,i = grad(g; sbar,ebar)' * ((s_i,e_i)-(sbar,ebar))`;
- nonlinear gap: `IF_nonlinear,i = IF_total,i - IF_mean,i`.

The covariance between `B_mean` and `B_nonlinear` is retained; their influence functions sum
exactly to the total-bias influence function.

## Symbolic-to-data alignment

| Symbol | Repeatability TSV | Supplied-K control TSV | Transform | Truth |
|---|---|---|---|---|
| `s_i` | `sigma_a2 + sigma_pe2` | `sk_hat` | numerator component | `1.0+0.6=1.6`; `0.6` |
| `e_i` | `sigma_e2` | `se_hat` | denominator-only component | `1.5`; `0.4` |
| `g(s_i,e_i)` | stored `t` | stored `h2_hat` | `s/(s+e)` | `0.516129...`; `0.6` |
| complete case | `converged=true` | `converged=true` | gate conditioning | 1,999/2,000; 2,000/2,000 |
| seed identity | `seed` | `seed` | uniqueness/config guard | fixed banked blocks |

Each supplied-K cell (`arbK`, `identity`, `pedA`) receives the same two-component analysis.
Those cells are pipeline controls/contrasts only: their estimator, DGP, and identifiability differ,
so their pass cannot validate or rehabilitate repeatability.

## Required pre-result gates

1. Verify the pooled repeatability SHA-256 already banked in the 2026-07-12 reconciliation.
2. Require exact schema, 2,000 rows/seeds, constant truth/config, and exactly one excluded
   nonconverged row.
3. Reconstruct stored ratios row-wise and reproduce the original bias, MCSE, and failed verdict.
4. Assert exact decomposition closure and row-order invariance.
5. Run deterministic synthetic controls: constant components imply zero nonlinear gap;
   proportional scaling leaves the ratio unchanged; paired `e` permutation preserves component
   means while changing the nonlinear term; analytic Hessian matches a finite-difference Hessian.

All five gates passed. The first self-test run deliberately went red because Julia parsed `2f0`
as the Float32 literal `2.0f0`, not `2*f0`, in the finite-difference negative control. The test
was corrected before reading the real TSVs. The first data run then stopped on an over-tight
`5e-9` stored-ratio reconstruction tolerance: independently serialized `%.10g` components and
ratios differ by up to `1.004e-8`. The tolerance was set to `2e-8`, and a mutated `1e-6` ratio
still hard-fails.

## Quantitative analysis

### Data audit

- Repeatability input SHA-256:
  `f064582f8626743177b8bf72de62f43ffdc00c086c34b03593f7f983b3dc1eba`.
- Exactly 2,000 unique seeds (`20280000:20281999`); 1,999 converged complete cases;
  excluded seed `20280439` is retained as nonconverged and not imputed.
- Constant DGP/config: half-sib 20/40/800, four records, truth
  `(sigma2_a,sigma2_pe,sigma2_e)=(1.0,0.6,1.5)`.
- Reconstructed row ratios match stored `t`; original result reproduced before decomposition:
  bias `-0.00120188`, MCSE `0.00056574`, `gate_pass=false`.
- The four-row machine-readable result is
  `2026-07-12-repeatability-ratio-bias.tsv` beside this note (deterministic rerun SHA-256
  `e247d525bb0eed937dc52bb23f193a608ccf90094eb0a9bcc638b484ea3b5e05`).

### Statistical findings

No new hypothesis test was selected. Estimates below are arithmetic functionals of the fixed seed
bank; 95% intervals use the seed-level influence-function MCSE under the original independent-seed,
convergence-conditional Monte Carlo design.

| Contribution | Estimate | MCSE | 95% Monte Carlo interval | Share of observed bias |
|---|---:|---:|---:|---:|
| total banked bias | -0.00120188 | 0.00056574 | [-0.00231071, -0.00009305] | 100.0% |
| plug-in mean shift `B_mean` | -0.00012399 | 0.00056883 | [-0.00123887, 0.00099089] | 10.3% |
| nonlinear averaging `B_nonlinear` | -0.00107789 | 0.00003861 | [-0.00115355, -0.00100222] | 89.7% |

The exact identity closes to machine precision. The contribution-estimate covariance is
`-2.496e-9` (correlation `-0.114`), so the total MCSE is retained rather than constructed by
naively adding the two component MCSEs.

The second-order diagnostic gives `B_nonlinear^(2)=-0.00108957`, leaving a remainder
`+0.00001168` (1.08% of the exact nonlinear term). Its curvature pieces are:

- numerator variance: `-0.00118607`;
- numerator-residual covariance: `-0.00000140`;
- residual variance: `+0.00009791`.

Thus the negative curvature contribution is dominated by variability in the summed numerator
`s=sigma2_a+sigma2_pe`, partly offset by residual-variance curvature. The weakly identified split
moves oppositely across seeds: `Var_m(sigma2_a)=0.07339`, `Var_m(sigma2_pe)=0.02430`, and
`2Cov_m=-0.07405`, collapsing to `Var_m(s)=0.02364`. This describes why the sum is much more stable
than its two parts; it is not separate recovery evidence for either part.

### Supplied-K controls/contrasts

| Cell | Total bias (MCSE) | Plug-in mean shift | Nonlinear averaging | Second-order diagnostic | Ratio criterion |
|---|---:|---:|---:|---:|---|
| `arbK` | -0.0000863 (0.0006850) | +0.0008904 | -0.0009767 | -0.0009770 | pass |
| `identity` | -0.0000430 (0.0006533) | +0.0007180 | -0.0007610 | -0.0007606 | pass |
| `pedA` | -0.0008101 (0.0007623) | +0.0005630 | -0.0013731 | -0.0013696 | pass |

All three controls show a negative nonlinear-averaging term of similar order, closely matched by
the Hessian diagnostic. Their positive plug-in mean shifts offset that term enough that the
analysis-only ratio criterion, `abs(total_bias) <= 2 MCSE`, passes. The original preregistered
supplied-K gates also passed in the banked evidence, but those full gates additionally require the
component-bias and convergence criteria and are not recomputed by this mechanism analysis. This
demonstrates that the analysis pipeline does not
manufacture a repeatability-only signature. It does not validate repeatability, exclude an engine
defect, or provide a causal negative control because the supplied-K estimator, DGP, and
identifiability differ.

### Interpretation and practical significance

In this realized, convergence-conditional seed bank, 89.7% of the observed repeatability bias is
arithmetically assigned to nonlinear averaging, and the second-order ratio curvature reproduces that
term to about 99%. The supplied-K contrasts show the same negative curvature signature with different
plug-in cancellation. These results are **consistent with finite-sample ratio nonlinearity in this
realized sample**. They do not establish a universal mechanism or alter the confirm-tier failure.

### Threats to statistical validity

- Post-hoc: the decomposition was motivated after seeing the marginal fail.
- Conditional on convergence: seed `20280439` has unknown contribution and is not imputed.
- Monte Carlo intervals assume independent preregistered seed replicates and use normal/influence
  approximations; they are descriptive, not model-based confidence intervals for applied data.
- The exact arithmetic apportionment is sample-specific; contribution shares need not generalize to
  other pedigrees, records-per-individual, variance truths, or optimizers.
- Supplied-K is a contrast, not a matched causal control.

## Claim fence

Allowed: “post-hoc deterministic decomposition”; arithmetic contribution signs, magnitudes,
Monte Carlo intervals, and whether the second-order curvature diagnostic approximates the realized
nonlinear gap; “consistent with ratio nonlinearity in this realized sample.”

Forbidden: “mechanism confirmed,” “explains the failure,” “expected finite-sample behavior,”
“engine defect excluded,” “essentially passes,” “unbiased,” any gate reinterpretation, any new
capability claim, or generalization beyond this fixed DGP/design/seed bank. The doc-34 result remains
`gate_pass=false`; V3-REPEAT-REML remains experimental/partial; `public_covered_count` remains 5.
