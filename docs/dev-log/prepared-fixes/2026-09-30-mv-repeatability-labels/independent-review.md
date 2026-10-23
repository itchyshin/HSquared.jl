# Independent MV repeatability label and schema review

Date: 2026-09-30. Panel disposition: **PASS for BP-02 through BP-04 isolated reader guards and bounded schema correction**. Integration, generic matrix-result parity and production ratification remain open. Review used contract and validation lenses; no additional subagent ran.

## Exact reviewed pins

Prepared root: `/private/tmp/hsq-mv-repeatability-label-fix-20260930`. Independent applied copy/log: `/private/tmp/e1-mv-labels-independent-20260930`.

| Artifact | SHA-256 |
| --- | --- |
| R label patch | `f213d8c7301bea9f3397e6f013c8cfad345f747acf7cb53aae124b5eee74ede9` |
| Schema patch | `bb03a9d1ef664b61b28d70fd7f3658e730d1eb5a5411f42128cbf7cf1a733175` |
| Original live R bridge | `4cb8074949c8b843727cd4d6acf8ef720113967e5820f135c5170bc3496e24c2` |
| Prepared R bridge | `f3d2bbc80ea659c239906e3c60d4604c1b114a4e957a1cd0f1ff753bca8634e0` |
| Original schema | `02fe6d274d83b2c62ae972f11d32186c507e083ef19fcb1dd6702b514adb3e80` |
| Prepared schema | `0968279284f20525eef4b0b6c1a60c2682bb40d7b2f1dee0fbc9cfeb7acfd703` |
| Focused test | `5d38ab814c20be94a700b65a56cb2b039f801b0adb66c2b92ab50f9006c4a079` |

Every supplied scratch/input inventory entry independently matches, including original/prepared function files, standalone/package test scripts, logs and current extractor/payload sources. Applying each patch to owned copies reproduces all prepared source/schema/test hashes. Live R/schema/helper pins still match after review. The Julia source tree remains `d3c2de8d7f0a1a86918f15938264bbdc892a7303b5ddd488553ac923f073ad0a`; expected parent HEAD `3d6d7ffc` is source-neutral.

## Caller and producer contract

The current dedicated caller at R/julia-bridge.R:3201–3207 resolves request traits from metadata trait_names, then Y column names, then trait1...traitN. Its serializer at 3243–3283 explicitly emits traits, breeding_ids, pe_ids, breeding_traits and pe_traits. The prepared reader uses the same request-trait fallback chain and requires all five result fields. Result labels must equal the expected request sequence; it never permutes or silently relabels values.

The emitter at R/bridge-payload.R:25–27 sets ids from the normalized pedigree, and 213–220 stores that sequence in payload$ids. The caller passes normalized pedigree IDs to the Julia fitter. Therefore breeding and permanent-effect labels must use the full pedigree animal sequence, including unobserved ancestors. Observed phenotype or permanent-effect subsets cannot replace it.

Prepared normalizer at 3298–3484 validates request traits/IDs, then checks missing, duplicate, NA, empty and sequence-mismatched result labels with field-specific errors. Short/extra/zero-length/reversed labels fail before matrix conversion. The complete body from the first G0 conversion onward is byte-identical. Existing component_names, status and estimator defaults remain intact; required result-label fallback is removed according to the dedicated producer contract.

## Independent evidence

Estimate stated before running: under one minute, one BLAS thread, Rscript --vanilla, no fit. The exact supplied standalone regression ran against the independently applied R source: **67 assertions, 67 passed, zero failed**, exit 0; whole command completed in about 0.48 seconds. Current extractor methods were loaded from their pinned files. No R package metadata engine, Julia process, optimizer or campaign ran.

Tests check producer-shaped covariance/effect/fixed values, h2/repeatability, observed-record count, df, loglik/convergence and actual extractors; eight malformed-label cases for each of five required fields; prior conflicting-label reproductions; both request trait-name fallback routes; full animal IDs including an unobserved ancestor; and invalid duplicate request labels. The ID ancestor control supplies three effect rows for two phenotype rows, demonstrating that expected IDs come from payload$ids rather than observed records. A PE observed subset then fails. The verified original red log records 22 passes and 45 failures; it was hash-checked rather than rerun. Package-shaped and standalone checks exercise the same 67 assertions and are not counted twice.

## Preserved neighbors and schema

Independent byte comparisons confirm unchanged source before/after the single normalizer and unchanged maternal reader at original 2090–2103, including the live paired-reader correction. Normalizer matrix conversion/result construction is unchanged after G0.

The schema corrects direct–maternal covariance to kron(G_dm,A) and precision to kron(inv(G_dm),Ainv) for nonsingular matrices. It distinguishes the default independent maternal target from explicit experimental direct_maternal paired-result adaptation. Current bare-intercept acceptance and slope rejection match R/model-spec.R:131–166,275–301. The named maternal receipt link resolves, and its six-animal/eight-record evidence is scoped to that cell. Generic matrix-valued MV repeatability remains fenced from scalar normalizers. All ratification checkboxes remain unchecked; no count/status/capability/version changes occur.

An initial patch-application attempt ran in /private/tmp rather than the owned copy and rejected missing target paths without applying changes. Repeating from the correct owned directory passed both dry checks and produced the exact prepared artifacts. No file belonging to another lane was edited.

## Limits and next gate

No blocker found for the named label guard/schema slice. The synthetic packets establish defensive label handling and unchanged positive normalization, with actual extractor methods; they supply no numerical fit, generic MV transport approval, full package-suite evidence or production ratification. BP-01 coefficient-parser integration and BP-05 comments remain separate. After source-freeze release, integrate the exact prepared R change/test and schema, run the package-shaped regression in the real test runner, and repin combined files. Parent owns that landing decision.

No new Graft query was needed: the preceding exact-current bridge review and literal caller/producer spans supplied the bounded context. All writes are confined to this report and the independent scratch copy.
