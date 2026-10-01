# Isolated non-Gaussian heritability descriptor repair

## 1. Goal

Implement the parent-approved bounded model in `/private/tmp/hsq-nongaussian-h2-descriptors-fix-20260930/`. Repair Gaussian fixed-spread acceptance, constant binomial trial representation, malformed descriptor inputs, and the zero-genetic-variance projection limit. Preserve the existing family formulas and experimental scope.

Frozen candidate HEAD is `3d6d7ffc961b65fa5a44ce277a7d1168ba69b6fe`. Frozen complete source tree is `d3c2de8d7f0a1a86918f15938264bbdc892a7303b5ddd488553ac923f073ad0a`. Base nongaussian source SHA256 is `24a31752319a1c51dbded522d8e20d066227d208e71be970cb94891beb87da00`.

## 2. Implemented

- Added descriptor input helpers beginning at the frozen line 1591 boundary. Original Real values and converted Float64 values must be finite; variance inputs must be nonnegative; Gaussian residual variance and Gamma shape must stay strictly positive through conversion. Both public overloads and the Float64 core enforce their applicable domains.
- Reject nonzero Gaussian predictor_variance explicitly. Preserve the conditional ratio V_A/(V_A+sigma_e2), total conditional variance, and valid default behavior. Both original and converted values matter: a tiny positive supplied spread that becomes zero in Float64 still violates the Gaussian conditional contract and rejects.
- Derive V_eta=V_A+V_fixed and reject a nonfinite total before quadrature/moments. Latent denominators also require representable finite totals.
- Validate scalar and vector binomial trials. Constant vectors use their common scalar; genuinely varying vectors retain finite latent output, NaN observation output, and the visible varying-trial caveat. Preserve acceptance of scalar integer-valued Real trials and maximum Int values. No average denominator or record weighting is inferred.
- Validate nonempty, finite, strictly increasing ordered cutpoints from synthetic-fit metadata, including singleton and conversion-collapse cases.
- Return the continuous observation-scale additive projection value zero when V_A==0. This applies to Poisson, logit, binary probit, Gamma, and ordinal category indicators. Preserve Poisson latent NaN and ordinal scalar observation NaN. Gaussian already has its zero limit through the positive residual denominator.
- Clarified doc-19's conditional Gaussian exception, additional fixed-spread meaning, covariance assumption, valid domains, and trial representation.

Count/Gamma/lognormal/trigamma equations and family/result shapes remain unchanged apart from the zero projection limit and validation. V_fixed is additional spread. No V_fixed>=V_A requirement was introduced.

## 3a. Decisions and Rejected Alternatives

The symbolic design receipt is `/private/tmp/e1-nongaussian-h2-contract-design-20260930.md`, now SHA256 `ff81f37688c4c750e8dc7ae467385f23fb4f85412bf2ab2264051c3ebf0dd9f6`. Its final two-call check pins the scalar binomial counterexample: V_A=1, mu=0, n=5 gives .5040211874317815. V_A=.8 gives .45778710056742744.

The accepted Gaussian contract is conditional on fixed effects. A different population-total Gaussian denominator was not introduced. For non-Gaussian transforms, V_eta=V_A+V_fixed assumes zero covariance of genetic and population fixed-effect contributions and the documented normal predictor approximation. A covariance-bearing model or varying-trial population weighting would need a separately declared estimand.

Nonnegative variance underflow to zero is allowed because zero is in the descriptor domain. Positive family-field underflow is invalid. The original tiny nonzero Gaussian fixed-spread value rejects because the Gaussian contract requires exactly zero supplied spread.

## 4. Files Touched

Only this assigned scratch directory and the assigned symbolic design report were written. Deliverable patch changes:

1. `src/nongaussian.jl`, only the heritability helper region: insertion at frozen 1591, changes within frozen 1591-1704 and 1762-1803.
2. `docs/design/19-h2-scale-contract.md`, limited clarification.
3. New `test/nongaussian_h2_descriptor_regression.jl`.

Project.toml, Manifest.toml, and the source directory were copied without git directories or old run artifacts. SHA inventory confirms every other source file matches the frozen candidate. Source lines 1-1590 remain byte identical. The complete existing heritability docstring remains byte identical because the parent owns its separate correction.

## 5. Checks Run

Each regression run was estimated below one minute before launch. All used Julia 1.10.0, one Julia thread, one OpenBLAS thread, startup disabled, compiled modules disabled, the copied existing Manifest, and depot `/private/tmp/hsq-goal-julia-depot:/Users/z3437171/.julia`. No statistical fit, optimizer, mode solve, package update, GPU, remote compute, or full suite ran.

Command shape:

```sh
OPENBLAS_NUM_THREADS=1 JULIA_NUM_THREADS=1 \
JULIA_DEPOT_PATH=/private/tmp/hsq-goal-julia-depot:/Users/z3437171/.julia \
julia --compiled-modules=no --startup-file=no --project=. \
test/nongaussian_h2_descriptor_regression.jl
```

| Preserved log | Result |
|---|---|
| red.log | Frozen source: 91 pass, 70 expected failures, 161 checks; exit 1. No test errors. |
| green-attempt-1.log | First repair: 161/161 pass; exit 0. |
| red-original-gaussian-fence.log | Added original tiny-spread edge plus controls: 166 pass, 2 expected failures, 168 checks; exit 1. No test errors. |
| green-final.log | Final repair plus independent moderate logit oracle: 170/170 pass; exit 0. Test summary 1.2 seconds; total process 17.54 seconds. |

Graft callers were checked before changes. The core has both public overloads plus the existing missing-cutpoints internal test as callers. Overloaded public callers are ambiguous in the graph; its no-indexed-callers statement is not an exhaustive absence claim. Graft reported 197,812 tokens saved in this implementation slice. Cache refresh had EPERM, and exact frozen source pins were verified directly.

## 6. Tests of the Tests

The original 70 red failures expose accepted malformed domains, ignored Gaussian spread, NaN constant trials, and zero projection NaN values. The second red stage isolates a conversion-specific Gaussian contract failure that the first passing suite missed. Both failed logs and the preceding passing implementation/test snapshots are retained.

Ordinary controls use an independent 64-node logit integral at one moderate positive fixed-spread point; direct Poisson/Gamma analytic formulas; Gamma mean cancellation; constant/scalar complete-summary parity; all-one trials; maximum Int trials; unsupported families; ambiguous mean; and nonconverged fit refusal. Synthetic NonGaussianFit objects exercise metadata ingress without fitting. Negative high-precision variance tests catch original-domain values that would become signed zero; huge high-precision and finite-sum overflow tests catch converted-domain failures. Positive family-field underflow, singleton NaN/Inf cutpoints, and rounded duplicate cutpoints reject.

The zero-projection tests include ordinary and finite large means. Other moment fields may overflow at those large means; the zero genetic projection remains mathematically zero. No claim of universal finite-moment output or quadrature accuracy follows from that limit check.

## 7a. Issue Ledger

| Issue | Isolated disposition |
|---|---|
| NG-07 Gaussian fixed-spread convention | Repaired through explicit conditional fence, original-value fence, result caveat, and doc-19 clarification. Parent helper docstring integration remains required. |
| NG-08 constant trial vectors | Repaired: same homogeneous proportion model and scalar numerical result. Genuinely varying trials remain visibly unsupported on observation scale. |
| NG-09 malformed h2 inputs | Repaired within both helper entries/core and relevant stored family metadata. Finite converted total guards added. |
| Zero genetic-variance projection | Repaired as continuous zero without changing count/Gamma projection formulas for positive genetic variance. |
| Family/count finite-ingress patch | Independent prepared repair. This patch does not modify constructors or count validators. |
| General separation, outer failures, VA provenance/stationarity | Carried from the frozen full-file review. No closure claimed. |

## 8. Consistency Audit

The frozen source has 1803 lines; the isolated source has 1863 lines. Unchanged complete public docstring is an intentional composition dependency, not current contract approval. Parent must retain its explicit conditional Gaussian, additional V_fixed, constant-versus-varying trials, and zero-projection wording when composing its separate docstring repair.

The finite-ingress constructor/count patch and endpoint patch occupy disjoint earlier source spans. Apply against the frozen base or reconcile line offsets after composition. This source patch is not pre-stacked with either. The docs/design clarification is separate from source and should be retained. Existing C3/C5 genetic_gllvm changes remain untouched.

No h2 fields were added to result payloads or the genetic GLLVM R route. No public grammar, family fitting support, validation status, or capability row was activated.

## 9. What Did Not Go Smoothly

The first passing suite omitted a tiny nonzero Gaussian keyword that converted to zero. The added regression failed twice as expected, and the final original-value guard fixed that edge. Failed attempts were preserved rather than overwritten. Graft's cache permission issue prevented refresh; exact source matching and caller inspection supplied the bounded evidence.

## 10. Known Residuals

This work does NOT cover calibration, confidence intervals, general design separation, optimizer failure handling, covariance stationarity of VA, generic objective-kind/boundary transport, arbitrary correlated predictors, a varying-trial population estimand, or response-scale heritability for the new genetic GLLVM R route.

For positive genetic variance and extreme finite means/variances, existing Poisson/Gamma moment products can overflow, and logit/probit probabilities can numerically degenerate. The patch does not replace their formulas with a wider numerical-range implementation, silently clamp ratios, or prove 20-node quadrature accuracy everywhere. The zero projection is handled directly without certifying the returned moment fields at extreme inputs.

The experimental helper's ambiguity about a lone non-intercept coefficient and inherited fit uncertainty/boundary limitations remain documented in the design receipt. No source-level acceptance of a fitted point establishes calibrated inference.

## 11. Team Learning

A keyword can meet a Float64 domain check and still violate an original-value model contract. Checking the original Gaussian spread prevents conversion from silently choosing a different estimand. Constant record denominators require normalization; varying denominators require population weighting, which the current interface does not supply.

Memory receipt: evidence is the exact candidate source, doc-19, existing test source, Graft caller edges, prior probes, and current red/green runs. No memory files were modified. Golden Set: original/converted domains; Gaussian default and nonzero-spread fence; tiny original spread; trial representation; valid V_fixed=0 with positive V_A; zero genetic projection; metadata validation; finite derived totals; Poisson/Gamma formulas; independent logit oracle; inherited rejection controls.

## 12. Cross Product Coverage

170 deterministic assertions cover both public overloads, Float64 core guard, original/converted values, stored/keyword trial vectors, scalar/constant/varying trials, Gaussian/count/logit/probit/ordinal/Gamma branches, and valid ordinary controls. Full source review retains coverage PASS and approval HOLD beyond this patch's exact repaired helper contracts.

Next parent action: independent review, then composition with the separately owned docstring, finite-ingress, and endpoint patches after the freeze permits integration. Re-run this bounded suite on the composed source. No live application, commit, push, or contact was performed here.

### Exact artifacts

| Artifact | SHA256 |
|---|---|
| Isolated src/nongaussian.jl | `a9cc2b986da539a0108985c625e4e7694337e2cb55ffd33025f5a87ee25d27dc` |
| Isolated docs/design/19-h2-scale-contract.md | `8a50b1af0cccf4eab638fd6f50acc51f4b5cd25294a70a825d4e54f4f3e2c371` |
| New regression | `6ef180997073e24708df93f1fbdd400413d140875d0aa85806649be3fe9e9986` |
| Unified patch | `e255f85afdb3b68e77d7a5e303c7f46109340464aad52fcbb9e0315c682780c8` |
| SHA inventory | `22b524dcff895cd3617166d339edabf8c1f1d73647cde4e700f3bcc1e12a381e` |

The inventory includes exact hashes for every copied source file, Project/Manifest, logs, and preserved attempt snapshots.
