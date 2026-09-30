# BP-02 through BP-04 prepared repair

Date: 2026-09-30. Owner: delegated Hopper/Boole/Emmy contract lane. Scratch root: `/private/tmp/hsq-mv-repeatability-label-fix-20260930`.

## 1. Verdict

Prepared label-validation repair and scoped schema wording: **PASS**. Integration is carried. Only scratch files were written. Generic MV matrix-result normalization, production ratification, numerical fitting, and covered status remain outside this repair.

## 2. Request and scope

Prepare isolated fixes for BP-02, BP-03 and BP-04 from `/private/tmp/e1-bridge-payload-complete-current-review-20260930.md`. The R patch changes only `hs_normalize_multivariate_repeatability_result` and adds a focused regression file. The Julia patch changes only schema-21 wording. Other lanes own live source, campaign and test files; they were preserved.

## 3. Exact contract choices

The dedicated caller at current R `R/julia-bridge.R:3201-3205,3243-3283` selects request traits from `payload$metadata$trait_names`, response column names, or generated `trait1...traitN` defaults. It sends normalized pedigree IDs to the fitter. The emitter at `R/bridge-payload.R:25-27,213-220` sets `payload$ids` to the normalized pedigree animal IDs, including unobserved ancestors. These are the expected ID labels; observed permanent-effect values are not a substitute.

The dedicated caller always emits all five result label fields: `traits`, `breeding_ids`, `pe_ids`, `breeding_traits`, and `pe_traits`. All five are required by the prepared reader. Missing, duplicate, empty, NA, reversed, short and extra result labels produce a field-specific diagnostic. Global/effect trait labels must equal the expected request trait sequence. Breeding/PE IDs must equal the complete expected animal-ID sequence. No implicit permutation or reassignment of values occurs.

Request trait defaults are retained and aligned with the caller. Existing optional `component_names`, `status` and `estimator` fallback behavior is unchanged. The old silent fallback for absent required result labels is removed. This stricter requirement is supported by the current dedicated producer's explicit field list; it does not activate the generic matrix serializer.

## 4. Prepared changes

- R: original normalizer lines 3298-3436 become prepared lines 3298-3484. Only its opening label resolution changes. The complete function body from the first `G0 <-` call onward is byte-identical.
- R regression: `prepared/tests/testthat/test-multivariate-repeatability-labels.R`, 67 meaningful assertions covering positive values/extractor methods, malformed labels, request trait defaults and an unobserved ancestor.
- Julia schema: qualify scalar stable block ordering with the MV pedigree/IID/residual exception; distinguish default independent maternal target from explicit experimental `direct_maternal`; document the dedicated paired-result adapter and exact live receipt; correct covariance `kron(G_dm,A)` and precision `kron(inv(G_dm),Ainv)` for nonsingular matrices; retain pending ratification and generic matrix-result fences.

The schema's existing unchecked ratification checklist stays unchecked. No capability or validation row, version, release flag or `public_covered_count` changed. The current R maternal paired reader at original lines 2090-2103 is byte-identical in the prepared full source.

## 5. Red and green evidence

Estimate stated before running: under one minute total, no fit, BLAS threads one. The standalone regression on the original exact source returned 22 passes and 45 expected failures out of 67 assertions, exit one, 0.356 seconds. It includes the original conflicting effect-trait and reversed global-label reproductions.

The same standalone regression on the prepared source returned **67/67 passes**, exit zero, 0.325 seconds. Actual repeatability and permanent-effect extractor methods were evaluated against the normalized synthetic result. Their tables and all positive covariance, fixed/effect values, heritability, repeatability, df, nobs and likelihood controls were preserved.

The package-shaped regression was also executed against only the selected prepared normalizer/helpers and current extractor methods. Its namespace references were mechanically mapped to the isolated exact-function environment; no package metadata engine or Julia was started. It returned **67 passes, zero failures, zero errors**, 1.027 seconds. These exercise the same 67 assertions, so they do not count as 134 distinct cases. The isolated runner initially lacked `test_that` in its base environment. Its testthat bindings were supplied before the final passing run.

Logs: `original-regression.log`, `prepared-regression.log`, `package-regression.log`. Standalone command: `OPENBLAS_NUM_THREADS=1 Rscript --vanilla regression.R prepared/R/julia-bridge.R`. Package-shaped command: `OPENBLAS_NUM_THREADS=1 Rscript --vanilla run-package-regression.R prepared/R/julia-bridge.R`, from the scratch root.

## 6. Patch checks and unchanged neighbors

Both `git apply --check` commands passed against the active exact R and Julia roots. They applied nothing. Full-file comparison verified unchanged R bytes before and after the one normalizer function, plus unchanged downstream matrix conversion/result construction within that function. The maternal paired reader segment is unchanged. Patch additions contain zero em dashes.

The prepared source and schema are saved alongside their whole originals. `original-function.R` and `prepared-function.R` preserve the full exact function bodies. `inventory.json` contains all original/result/patch/test/log hashes and the scope-check results.

## 7. Pins and parent checkpoint

R HEAD remains `fa98c262eb21694d672e671c9672491ce3369cec`. Active dirty `R/julia-bridge.R` remains SHA256 `4cb8074949c8b843727cd4d6acf8ef720113967e5820f135c5170bc3496e24c2`.

Julia HEAD at start was `9c10f09c1bdc7f7ab19cb07c339d1dc83179f429`; at close it was `3d6d7ffc961b65fa5a44ce277a7d1168ba69b6fe`. The parent announced this local checkpoint. Its changed paths are confined to `docs/dev-log/`; it is source-neutral and has no push/tag. The live schema remains SHA256 `02fe6d274d83b2c62ae972f11d32186c507e083ef19fcb1dd6702b514adb3e80`. The Julia source tree remains `d3c2de8d7f0a1a86918f15938264bbdc892a7303b5ddd488553ac923f073ad0a`, using sorted paths relative to `src/`, NUL, file bytes, NUL.

Patch pins:

| Artifact | SHA256 |
| --- | --- |
| `r-labels.patch` | `f213d8c7301bea9f3397e6f013c8cfad345f747acf7cb53aae124b5eee74ede9` |
| `schema-wording.patch` | `bb03a9d1ef664b61b28d70fd7f3658e730d1eb5a5411f42128cbf7cf1a733175` |

Full original/result pins are in `inventory.json`.

## 8. Limits

No current package suite, live R/Julia fit or generic MV parity test ran. The synthetic result tests establish defensive reader behavior and unchanged positive normalization only. Existing maternal 90-pass evidence was reused without rerunning. BP-01 coefficient parser integration and BP-05 source comments remain separately carried.

## 9. Remaining work

The parent should obtain independent review of these exact scratch artifacts, then integrate in an authorized source window. Source freeze stays mandatory during the primary campaign. The package-shaped regression is ready to ship with the R change; full package-runner integration remains unverified here.

## 10. Ownership and landing state

This lane wrote only inside the named scratch directory. All prepared artifacts are CARRIED-OVER to the parent coordinator. No live source/tests/docs edits, commit, push, external message, campaign, optimizer or GPU task occurred in this lane.

## 11. Retrieval and prose verification

The preceding full-current bridge receipt supplies the Graft context and exact source coverage. No new Graft query was necessary for these named function/schema repairs. The verification-before-completion skill was used. Final verification matched every artifact pin, the unchanged live R/schema pins and the frozen Julia source tree. The absolute-path slop checker returned zero findings; receipt and patch additions contain zero em dashes.
