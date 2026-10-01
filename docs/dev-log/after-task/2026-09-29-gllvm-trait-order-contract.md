## 1. Goal

Close the Julia engine side of the trait-order result contract shared with the R GLLVM bridge. Keep all GLLVM capability claims experimental.

## 2. Implemented

`GeneticGLLVMFit` carries optional trait names. The fitter validates count, uniqueness, string type, and blank Unicode labels, then retains the response-column order. Tests cover supplied labels, trait permutations, and invalid blank names, including U+2028 and U+2029.

## 3a. Decisions and Rejected Alternatives

Trait names remain metadata on the fit result and do not label internal numerical matrices. The R bridge must verify the metadata against payload order before assigning dimnames. No automatic reordering or capability promotion was added.

## 4. Files Touched

`src/genetic_gllvm.jl`, `test/genetic_gllvm_trait_effects.jl`, this report, and the check log.

## 5. Checks Run

The full Julia `Pkg.test()` passed before the final two Unicode separator cases. After those cases, the focused GLLVM trait-effects test file passed, including the Poisson T3/K2 ordinary-restart testset with 34 assertions. `git diff --check` passed before report additions; final whitespace checks are recorded after this report.

## 6. Tests of the Tests

Invalid duplicate, wrong-length, ASCII blank, and Unicode separator names are rejected. The R live permutation test confirms numerical G, correlation, trait modes, intercept estimates, and objective remain within stated tolerances after column reordering.

## 7a. Issue Ledger

Closed for this slice: the Julia fit object previously omitted its trait order. The broader solver, identifiability, and recovery questions remain open in the GLLVM foundation ledger.

## 8. Consistency Audit

The Julia output preserves caller-supplied order and the R normalizer requires exact agreement with its payload. Capability status, public covered count, version, and release state were not changed.

## 9. What Did Not Go Smoothly

Julia `strip` treats NBSP as whitespace but does not classify U+2028 or U+2029 as whitespace. The validator now handles those two explicitly so the R and Julia contracts agree.

## 10. Known Residuals

The default loading start remains position-dependent. The live permutation comparison allows small numerical differences between converged fits. The fit remains experimental and validation-scale.

## 11. Team Learning

Cross-language validation should test the Unicode edge cases supported by each runtime, not rely on similarly named trim functions to have identical definitions.

## 12. Cross-Product Coverage

This slice pairs a narrow Julia result-contract change with R bridge checks. This does NOT cover broad GLLVM recovery, other families, missing data, FA uniqueness, or release readiness.
