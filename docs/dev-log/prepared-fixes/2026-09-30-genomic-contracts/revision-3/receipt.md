# Prepared genomic G2-G6 contract repair, 2026-09-30

## 1. Status

**REVISION 3 PREPARATION, local author checks PASS 112/112; independent re-review pending.** The original 88-control proposal received an independent G3 HOLD and is preserved verbatim under `original-proposal/`. Revision 2 passed 100 controls and the original six independent controls, then received a second G3 HOLD for genuine overflow hidden by a finite rounded candidate. Its complete proposal, inventory, receipt, all prior logs, and the second independent HOLD report/logs are preserved under `revision-2/`. The new red controls reproduce the second HOLD. The revised boundary verification passes in author checks. The patch is not integrated into the live candidate and is not a whole-file, performance, calibration or E1 approval.

## 2. Request and owned paths

Prepare the bounded G2-G6 findings from `/private/tmp/e1-genomic-complete-current-review-20260930.md` in `/private/tmp/hsq-genomic-contracts-fix-20260930/` only. All code, tests, logs, copied package inputs and this receipt live in that directory. The parent reported the frozen FA run complete and then applied G1 to live source separately. This preparation still uses the original frozen base for isolated composition and makes no live source edit.

## 3. Pins

| Artifact | SHA-256 |
| --- | --- |
| Frozen base genomic source | `76c4053d00ed3f35db133089c5f0bfb979c1da70503a4697054bf9fa002d4b9f` |
| Frozen base source tree | `d3c2de8d7f0a1a86918f15938264bbdc892a7303b5ddd488553ac923f073ad0a` |
| Prepared genomic source | `5f903569788999c2c9366385669e1ef9d5b6ea28115d20c164945c502d95cb0e` |
| Combined source/new-tests patch | `b91e7696609ab36f8bfdc29643c64f803be358b4093a7df8ef3c8d076ef8daba` |

Base HEAD is `3d6d7ffc961b65fa5a44ce277a7d1168ba69b6fe`. Exact hashes for the Project, Manifest, source trees, new tests, runner and retained logs are in `hashinventory.json`; no dependency resolution was performed. The baseline copy remains at the frozen pins. The parent reports live genomic source `f6f8ba22302d55f81d25d36c2f8803fc22dfa4473cb0087613f37ec403e91523` after G1; no claim that live source still equals the frozen source is made. The revision-2 inventory and copied second HOLD SHA `773a2dcddefc34e1c093cb87ad0013c3dc22d6701d502fe553889cf3e01c9522` were verified unchanged before updating this proposal.

## 4. G2 label contract

A shared private label validator rejects `missing`, `nothing`, empty strings and whitespace-only strings before canonicalisation; a supplied literal `"missing"` remains valid. Both LOCO construction and scan, relationship precision keys, scan IDs, group and relationship-group payload fields, Manhattan chromosome/order fields, region chromosome selection, paired summary metadata, and optional trait/feature labels use that contract. The dictionary collision check is preserved. Symbol/ordinary string labels, literal `"missing"`, group order and map alignment remain available.

## 5. G3 numeric contract

Marker contribution arithmetic scales each finite effect by the square root of its allele variance before squaring. This preserves ordinary representable results such as frequency `1e-200` with effect `1e200`, and keeps monomorphic endpoints at zero even for large finite effects. Independent review found two near-maximum cases where rounded scale/square arithmetic overflowed despite a finite exact converted-weight answer. The second independent review found that a finite rounded candidate can also conceal genuine overflow. The revision-3 helper evaluates converted Float64 allele weight times squared converted Float64 effect at 256-bit BigFloat precision when the fast candidate is nonfinite or at least `floatmax(Float64)/2`, then converts that product back to Float64. Three Float64 significands require at most 159 bits, so this calculation is exact before its final Float64 rounding. The upper half of the finite range is a conservative boundary region: near maximum, square root, multiplication and squaring all operate on normal values and incur only a few rounding units, far smaller than a factor of two. A candidate below that bound cannot conceal an upper-boundary crossing. Ordinary candidates below it retain their prior fast computation; this does not add an exact-rounding promise for all ordinary values. Public input guards and the final finite-output rejection remain in place; genuinely unrepresentable contributions still raise ArgumentError. Derived contributions and proportions must remain finite; unrepresentable outputs raise `ArgumentError` rather than returning infinity or NaN. Both variance summaries and scan tables share the helpers.

The even-length median uses direct addition when bounded away from overflow, retaining subnormal midpoint rounding. For large values it uses a bounded same-sign difference or opposite-sign half-sum. The inflation ratio also rejects a nonfinite derived result. Ordinary finite summaries, negative effect signs, monomorphic frequencies, subnormal/equal/opposite-sign medians and independent BigFloat references are in the controls. Marker proportions may legitimately exceed one; no calibrated PVE claim or probability-range restriction was added.

## 6. G4 probability contract

The computational alpha is converted once and required to remain finite and strictly inside `(0,1)`; both supplied-null thresholds and the permutation entry use it. Underflow to zero and rounding to one are rejected before scan/permutation work. Returned alpha and threshold use the same converted value.

Null statistics retain their existing finite Float64 conversion. Exceedance comparisons use the original finite `observed::Real` against those actual null values. Controls cover positive and negative `BigFloat` observations near `1e-1000`, huge finite observations near `1e1000`, tied zeros, normal finite counts, NaN/Inf, and both alpha endpoints. No original finite extreme observation is rejected solely because it exceeds the Float64 range.

## 7. G5-G6 visible conditions

The genome-wide scan docstring limits exact/conservative permutation interpretation and cited calibration evidence to intercept-only designs with exchangeable Gaussian residuals. General supplied-covariate residual permutation remains an accepted experimental utility without an exactness or family-wise calibration claim; mixed-covariance calibration remains separate debt.

Centering/all-ones-null/rank claims now state the sample-estimated-frequency condition. Single-step reduction states default `tau = omega = 1`, `ridge = 0`; genotype matrix order follows the supplied row-index sequence. Existing numerical implementations for those conditions remain unchanged. Probability representation and absent-label rejection are visible in affected public docstrings. The helper sits before the public threshold docstring, preserving its public documentation binding.

## 8. Red and green evidence

Estimate before execution: all checks under ten minutes total; each tiny invocation under one minute, one Julia thread and one BLAS thread. The revision-3 prepared 112-control run took 23.2 seconds in the enclosing testset, including loading. Original 88-control runs remain under `original-proposal/`; revision-2 100-control runs and the second independent HOLD are preserved under `revision-2/`. Each invocation was estimated below one minute before execution. No fit, optimizer, recovery campaign, GPU or remote compute ran. Frozen invalid-alpha controls perform only one seeded permutation if the old input guard fails to reject; this is a deterministic red control, not calibration evidence.

Environment: Julia 1.10.0, copied candidate Project/Manifest, `--startup-file=no --compiled-modules=no`, `JULIA_NUM_THREADS=1`, `OPENBLAS_NUM_THREADS=1`, depot `/private/tmp/hsq-goal-julia-depot:/Users/z3437171/.julia`.

| Retained log | Result and purpose |
| --- | --- |
| `red.log` | Frozen-source original 68 controls: 33 pass, 35 fail, no test errors. Written and run before implementation. |
| `green.log` | First proposed numeric/label source: 68/68. |
| `doc-binding-before-metadata-check.log` | Initial 11 neighbour controls pass. The initial non-null `Docs.doc` test was too weak; later controls test the actual module documentation binding. This file is not labelled red evidence. |
| `midpoint-red.log` | Further median control exposed the proposal's subnormal midpoint rounding error: 11 pass, 1 fail overall. Retained as proposal-defect evidence. |
| `label-neighbours-red.log` | Before relationship-key/payload extension: 68 pass, 8 fail out of 76. |
| `original-proposal/final-baseline-red.log` | Original exact 88 controls against frozen source: 42 pass, 46 fail; exit 1. The archive remains intact. |
| `representable-boundary-red.log` | Before rare fallback: 8 pass, 4 fail out of 12. Both public paths fail for both independent near-maximum cases; true-overflow/nonfinite controls pass. |
| `representable-boundary-error-red.log` | Earlier direct-call harness recorded the same four unexpected ArgumentErrors as test errors; retained. The later catch-and-predicate controls classify them as the intended four red failures. |
| `revision-2/reused-independent-boundary-green.log` | Revision-2 author rerun of the unchanged independent boundary script: 6/6. This is historical evidence, not revision-3 approval. |
| `revision-2/final-baseline-red.log` | Revision-2 frozen-source 100 controls: 46 pass, 54 fail, zero errors; exit 1. |
| `finite-candidate-overflow-red.log` | Revision-2 source against 12 newly added controls: 4 pass, 8 fail, zero errors; exit 1. Four failures reproduce both genuine-overflow cases through both APIs; four expose rounding differences for the preceding finite values. Written and run before revision-3 implementation. |
| `final-baseline-red.log` | Revision-3 frozen-source 112 controls: 50 pass, 62 fail, zero errors; exit 1, enclosing testset 25.1 seconds. |
| `final-green.log` | Revision-3 exact prepared source/tests/runner: 112/112; exit 0, including the original 88 controls unchanged, original finite-answer cases, genuine-overflow cases and their immediately preceding representable values through both APIs. |

Run from this scratch root:

```sh
env JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 JULIA_DEPOT_PATH=/private/tmp/hsq-goal-julia-depot:/Users/z3437171/.julia julia --startup-file=no --compiled-modules=no --project=. run_contracts.jl
env JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 JULIA_DEPOT_PATH=/private/tmp/hsq-goal-julia-depot:/Users/z3437171/.julia julia --startup-file=no --compiled-modules=no --project=baseline run_contracts.jl
```

The runner wraps all three test files in a parent testset, retaining the full denominator even when the first file fails. An earlier main-file-only red log is retained separately. No full `Pkg.test()` or Documenter build is claimed.

## 9. Patch and G1 composition

`contract-fix.patch` includes `src/genomic.jl` plus three new test files. `git apply --check ../contract-fix.patch` from the scratch `baseline/` directory passes without mutations. A separate read-only `git apply --check` against the live candidate also passes at observed genomic SHA `f6f8ba22302d55f81d25d36c2f8803fc22dfa4473cb0087613f37ec403e91523` and HEAD `6271cfd58651e69cd27a64dcf02cb8960a29e260`; no patch was applied there. Register all three new test files in the integrated suite when the parent composes the candidate; the standalone scratch runner is not part of the repo patch.

The complete `_mixed_marker_scan_common`, `_mixed_marker_scan_cache` and `_mixed_marker_scan_stats` bodies are byte-identical between frozen and prepared source. They are the G1 marker variance/GLS scopes. This proposal adds no hunk there and does not touch `src/postfit.jl`; the independent G1 convergence/zero-additive/raw-sign patch remains separately approved. Both proposals share the genomic file at disjoint source changes, so the parent must compose and validate a new combined source SHA rather than substitute either individual prepared SHA for the frozen source. No G1 finding is marked live-fixed here.

## 10. Residuals and claim boundary

Dense storage/inversion, SNP identity allocation, LOCO cache memory, abstract precision lookup, normal-equation conditioning, absolute scan denominator cutoffs, sparse provenance copying, permutation repeated work and broad calibration remain the debts in the complete source report. This correctness repair is not an optimisation and establishes no runtime, memory, external comparator or broad inference claim. Covered count stays 7; no status row, formula grammar, bridge result shape, version, release, GPU or R activation changed.

## 11. Next action

Independent reviewer should inspect the revised patch, rerun the 112 controls and frozen red denominator, challenge the conservative upper-half BigFloat boundary fallback and true-overflow rejection, and preserve the already-passing midpoint/doc-binding and G2/G4-G6 dispositions. The unchanged independent boundary script is available with the copied original HOLD artifacts. Only single-thread correctness is measured here; fallback allocation and concurrent calls have no performance approval. Parent then composes G1 with G2-G6 in isolation, registers tests, rehashes source/tests and executes the integrated checks justified by those changes. This receipt is author evidence only; it does not grant full-file approval or supersede the independent HOLD until its reviewer checks the revised pins. The first independent HOLD remains copied under `original-proposal/independent-review.md`, with scripts/logs in `original-proposal/independent-artifacts/`. The second HOLD remains under `revision-2/independent-final-hold.md`, with its three independent runtime logs. Neither review packet is overwritten. No aggregate-sum accuracy or range contract is added: the reviewed outputs remain per-marker vectors and proportions.
