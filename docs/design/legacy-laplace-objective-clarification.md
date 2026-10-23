# Legacy Ordinal/Gamma objective clarification

Date: 2026-09-30. This note corrects the current interpretation of historical July comparator evidence. The owner-approved engine status labels, historical numerical results, and current R-public covered count of **7** are retained. Neither family gains an R formula/bridge route through this clarification.

## Objective and measure

The legacy engine integrates fixed effects under a flat measure in the supplied X coefficient coordinates and genetic effects under a normalized Gaussian density. With `G = σ²a A`, the intended integral is

```text
I(α; X) = ∫∫ exp(ℓ(y | Xβ + Zu, α)) φ_q(u; 0, G) du dβ.
F(β, u; α) = ℓ(y | Xβ + Zu, α) - u′G⁻¹u/2.
J(α) = F(β̂_J, û_J; α) - log|G|/2 + p*log(2π)/2 - log|H_joint|/2.
```

Here `α` contains the optimized variance, shape, or free cutpoint spacings, `p = size(X, 2)`, and `H_joint` is the negative observed-curvature Hessian of F in `(β, u)` at their joint mode. The normalized Gaussian prior and the joint Laplace integration leave the `p*log(2π)/2` term. The fixed-effect measure has density one in the supplied coordinates; it is unnormalized, so the integrated value is not an ordinary marginal sampling density for y. Absolute values depend on that measure convention.

Conventional profiled-fixed-effect Laplace-ML integrates genetic effects conditional on β and then optimizes β. It generally uses a different optimizing mode and determinant correction. Close corresponding parameter estimates do not prove equality of those optimized objectives. Matching a final likelihood value by adding a Gaussian-style correction would also require matching the mode, curvature, measure, and parameterization.

The integral must be proper. Current necessary endpoint/design guards and local mode convergence do not establish propriety for every non-Gaussian design. For Gaussian responses, the likelihood is quadratic and the joint integration is exact: it reduces to the package's Gaussian REML convention under the same X measure and likelihood normalization. This Gaussian reduction does not define general non-Gaussian REML or AI-REML. The historical `fit_laplace_reml` name remains for compatibility.

## Historical comparison evidence

The July external fits profile fixed effects; the engine flat-integrates them jointly with genetic effects. Those comparisons support numerical proximity of corresponding parameters on their specified packets. They establish neither same-objective parity nor the cause of the parameter differences.

| Dated comparison | Packet | Reported absolute differences |
|---|---|---|
| Ordinal `ordinal::clmm`, 2026-07-01 | A=I, K=3, 80 animals × 4 records, threshold location aligned | Cutpoint spacing 0.0044, genetic variance 0.0241, location 0.0119 |
| Gamma `glmmTMB Gamma(link="log")+(1|id)`, 2026-07-01 | A=I, 40 animals × 4 records, shape convention matched | Shape 0.0032, genetic variance 0.0167, intercept 0.0322 |

The rounded values already recorded in the capability/debt rows remain unchanged. Both comparisons recorded convergence. Their variance differences have no demonstrated decomposition or established sign/size prediction attributable to fixed-effect integration. The historical 48-seed recovery gates remain separate evidence with their original pins, informative designs, and convergence denominators. A recovery pass does not supply a missing same-objective equivalence proof or uncertainty calibration.

Ordinal joint estimation optimizes σ²a and **K−2 free cutpoint spacings**, returns **K−1 cutpoints** with `θ₁ = 0`, and obtains β from the joint mode. Supplied family cutpoints still number K−1. This distinction changes documentation of the existing parameterization.

The historical owner-approved `V6-ORDINAL` and `V6-GAMMA` covered labels remain. An independently verified comparator matching the joint integrated-Laplace objective, fixed-effect measure, and parameterization remains unestablished. Broader-DGP/pedigree-A recovery and R activation remain separate debts. Supplied-parameter observation-scale heritability transformations retain their separate evidence; they do not supply fitted uncertainty or calibration.

## Provenance

This interpretation follows the independent mathematical review dated 2026-09-30 and the approved VS-4 source wording. The reviewed live source was `src/nongaussian.jl`, SHA-256 `24a31752319a1c51dbded522d8e20d066227d208e71be970cb94891beb87da00`, particularly its joint objective at 722-735. A separate prepared docstring patch carries these qualifications into the API documentation. Source endpoint changes are handled separately.

The historical receipts remain intact:

- [Ordinal comparison](../dev-log/recovery-checkpoints/2026-07-01-ordinal-clmm-comparator.md).
- [Gamma comparison](../dev-log/recovery-checkpoints/2026-07-01-gamma-glmmtmb-comparator.md).
- [Ordinal 48-seed recovery](../dev-log/recovery-checkpoints/2026-07-01-ordinal-recovery-48seed.md).
- [Gamma 48-seed recovery](../dev-log/recovery-checkpoints/2026-07-01-gamma-recovery-48seed.md).

Current source/ledger synchronization preserves history while carrying the objective-comparator debt. No new fit, recovery campaign, source capability, GPU result, or public count expansion is supplied by this note.
