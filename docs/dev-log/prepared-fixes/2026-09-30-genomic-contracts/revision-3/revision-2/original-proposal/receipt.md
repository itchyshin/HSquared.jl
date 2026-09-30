# Prepared genomic G2-G6 contract repair, 2026-09-30

## 1. Status

**PREPARED, local author checks PASS 88/88; independent review pending.** Frozen-source controls give 42 passes and 46 expected failures on the same 88 checks. The patch is not integrated into the live candidate and is not a whole-file, performance, calibration or E1 approval.

## 2. Request and owned paths

Prepare the bounded G2-G6 findings from `/private/tmp/e1-genomic-complete-current-review-20260930.md` in `/private/tmp/hsq-genomic-contracts-fix-20260930/` only. All code, tests, logs, copied package inputs and this receipt live in that directory. The parent's source freeze and other owners' edits remain intact. The parent subsequently reported the frozen FA run complete; this preparation still uses the frozen base for isolated composition.

## 3. Pins

| Artifact | SHA-256 |
| --- | --- |
| Frozen base genomic source | `76c4053d00ed3f35db133089c5f0bfb979c1da70503a4697054bf9fa002d4b9f` |
| Frozen base source tree | `d3c2de8d7f0a1a86918f15938264bbdc892a7303b5ddd488553ac923f073ad0a` |
| Prepared genomic source | `65c97421e92b3a731e49dda7122c19449dbbe43707d7a635825746be6ea9bce2` |
| Combined source/new-tests patch | `aa67600abde5cff6f62de93a7cfe903bf2a583751e893ae44493a811d3209d40` |

Base HEAD is `3d6d7ffc961b65fa5a44ce277a7d1168ba69b6fe`. Exact hashes for the Project, Manifest, source trees, new tests, runner and retained logs are in `hashinventory.json`; no dependency resolution was performed. The final integrity check recomputed the live source tree and base copy and matched the frozen pins.

## 4. G2 label contract

A shared private label validator rejects `missing`, `nothing`, empty strings and whitespace-only strings before canonicalisation; a supplied literal `"missing"` remains valid. Both LOCO construction and scan, relationship precision keys, scan IDs, group and relationship-group payload fields, Manhattan chromosome/order fields, region chromosome selection, paired summary metadata, and optional trait/feature labels use that contract. The dictionary collision check is preserved. Symbol/ordinary string labels, literal `"missing"`, group order and map alignment remain available.

## 5. G3 numeric contract

Marker contribution arithmetic scales each finite effect by the square root of its allele variance before squaring. This preserves representable results such as frequency `1e-200` with effect `1e200`, and keeps monomorphic endpoints at zero even for large finite effects. Derived contributions and proportions must remain finite; unrepresentable outputs raise `ArgumentError` rather than returning infinity or NaN. Both variance summaries and scan tables share the helpers.

The even-length median uses direct addition when bounded away from overflow, retaining subnormal midpoint rounding. For large values it uses a bounded same-sign difference or opposite-sign half-sum. The inflation ratio also rejects a nonfinite derived result. Ordinary finite summaries, negative effect signs, monomorphic frequencies, subnormal/equal/opposite-sign medians and independent BigFloat references are in the controls. Marker proportions may legitimately exceed one; no calibrated PVE claim or probability-range restriction was added.

## 6. G4 probability contract

The computational alpha is converted once and required to remain finite and strictly inside `(0,1)`; both supplied-null thresholds and the permutation entry use it. Underflow to zero and rounding to one are rejected before scan/permutation work. Returned alpha and threshold use the same converted value.

Null statistics retain their existing finite Float64 conversion. Exceedance comparisons use the original finite `observed::Real` against those actual null values. Controls cover positive and negative `BigFloat` observations near `1e-1000`, huge finite observations near `1e1000`, tied zeros, normal finite counts, NaN/Inf, and both alpha endpoints. No original finite extreme observation is rejected solely because it exceeds the Float64 range.

## 7. G5-G6 visible conditions

The genome-wide scan docstring limits exact/conservative permutation interpretation and cited calibration evidence to intercept-only designs with exchangeable Gaussian residuals. General supplied-covariate residual permutation remains an accepted experimental utility without an exactness or family-wise calibration claim; mixed-covariance calibration remains separate debt.

Centering/all-ones-null/rank claims now state the sample-estimated-frequency condition. Single-step reduction states default `tau = omega = 1`, `ridge = 0`; genotype matrix order follows the supplied row-index sequence. Existing numerical implementations for those conditions remain unchanged. Probability representation and absent-label rejection are visible in affected public docstrings. The helper sits before the public threshold docstring, preserving its public documentation binding.

## 8. Red and green evidence

Estimate before execution: all checks under ten minutes total; each tiny invocation under one minute, one Julia thread and one BLAS thread. Final complete runs took 22.9 seconds on the prepared source and 23.9 seconds on the frozen source including loading. No fit, optimizer, recovery campaign, GPU or remote compute ran. Frozen invalid-alpha controls perform only one seeded permutation if the old input guard fails to reject; this is a deterministic red control, not calibration evidence.

Environment: Julia 1.10.0, copied candidate Project/Manifest, `--startup-file=no --compiled-modules=no`, `JULIA_NUM_THREADS=1`, `OPENBLAS_NUM_THREADS=1`, depot `/private/tmp/hsq-goal-julia-depot:/Users/z3437171/.julia`.

| Retained log | Result and purpose |
| --- | --- |
| `red.log` | Frozen-source original 68 controls: 33 pass, 35 fail, no test errors. Written and run before implementation. |
| `green.log` | First proposed numeric/label source: 68/68. |
| `doc-binding-before-metadata-check.log` | Initial 11 neighbour controls pass. The initial non-null `Docs.doc` test was too weak; later controls test the actual module documentation binding. This file is not labelled red evidence. |
| `midpoint-red.log` | Further median control exposed the proposal's subnormal midpoint rounding error: 11 pass, 1 fail overall. Retained as proposal-defect evidence. |
| `label-neighbours-red.log` | Before relationship-key/payload extension: 68 pass, 8 fail out of 76. |
| `final-baseline-red.log` | Final exact tests/runner against frozen source: 42 pass, 46 fail out of 88; exit 1. |
| `final-green.log` | Final exact prepared source/tests/runner: 88/88; exit 0. |

Run from this scratch root:

```sh
env JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 JULIA_DEPOT_PATH=/private/tmp/hsq-goal-julia-depot:/Users/z3437171/.julia julia --startup-file=no --compiled-modules=no --project=. run_contracts.jl
env JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 JULIA_DEPOT_PATH=/private/tmp/hsq-goal-julia-depot:/Users/z3437171/.julia julia --startup-file=no --compiled-modules=no --project=baseline run_contracts.jl
```

The runner wraps both test files in a parent testset, retaining the full denominator even when the first file fails. An earlier main-file-only red log is retained separately. No full `Pkg.test()` or Documenter build is claimed.

## 9. Patch and G1 composition

`contract-fix.patch` includes `src/genomic.jl` plus two new test files. `git apply --check ../contract-fix.patch` from the scratch `baseline/` directory passes without mutations. Register both new test files in the integrated suite when the parent composes the candidate; the standalone scratch runner is not part of the repo patch.

The complete `_mixed_marker_scan_common`, `_mixed_marker_scan_cache` and `_mixed_marker_scan_stats` bodies are byte-identical between frozen and prepared source. They are the G1 marker variance/GLS scopes. This proposal adds no hunk there and does not touch `src/postfit.jl`; the independent G1 convergence/zero-additive/raw-sign patch remains separately approved. Both proposals share the genomic file at disjoint source changes, so the parent must compose and validate a new combined source SHA rather than substitute either individual prepared SHA for the frozen source. No G1 finding is marked live-fixed here.

## 10. Residuals and claim boundary

Dense storage/inversion, SNP identity allocation, LOCO cache memory, abstract precision lookup, normal-equation conditioning, absolute scan denominator cutoffs, sparse provenance copying, permutation repeated work and broad calibration remain the debts in the complete source report. This correctness repair is not an optimisation and establishes no runtime, memory, external comparator or broad inference claim. Covered count stays 7; no status row, formula grammar, bridge result shape, version, release, GPU or R activation changed.

## 11. Next action

Independent reviewer should inspect the patch, rerun the 88 controls and frozen red denominator, challenge numeric scaling/rounding and original-Real comparisons, and verify the narrowed prose and unchanged G1 bodies. Parent then composes G1 with G2-G6 in isolation, registers tests, rehashes source/tests and executes the integrated checks justified by those changes. This receipt is author evidence only; it does not grant full-file approval.
