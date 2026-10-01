# Independent FA unit and trait-order artifact review

Date: 2026-09-30. Reviewer: Curie. No refit, RNG draw, new simulation, source edit, or campaign change was performed.

## Verdict and denominator

PASS for completion and numerical consistency of the five declared cases on one existing four-trait, rank-one fixture. All five calls returned finite converged fits, all ten named default/balanced starts were valid and converged, and the retained failure count is zero. All five comparisons satisfy the declared interior-agreement checks. A2, population recovery, general unit/order robustness, information regularity, and interval calibration remain HOLD or outside this evidence.

These are five transformations of one dataset, not five independent replicates. The fixture is seed 20260929, 40 unrelated founder animals and five records per animal. Each start has a 10,000-iteration cap. This differs from the primary campaign's pedigree DGP and 5,000 cap; their denominators must remain separate. Recorded diagnostic duration is 270.264579069 seconds.

The frozen script at fa_ordinary_unit_order_check.jl:82-89 declares all five cases. Lines 334-336 call the ordinary FA fitter with no initial keyword. Lines 350-372 retain every named result, including exceptions and unavailable inner start statuses. Summary lines 394-402 retain denominator five and explicitly set A2_complete=false. The readable artifacts contain five fit rows, ten start rows, thirty oracle rows, and five comparison rows.

## Artifact verification

All 19 entries in artifact_hashes.toml match the files. The directory has 20 files, with the hash inventory itself excluded as documented. All 24 source-file hashes in the manifest match the frozen current candidate. Fixture-file, generator-span, README, Project, and Manifest fingerprints match. The independent Julia check also recomputed every saved input array/ID/trait-label fingerprint.

Frozen script SHA-256, unchanged before and after review: 026c3d5ad3a192e26626d3bb38d146266b24b397e981d244d88c960be15f267e. Source-tree pin: d3c2de8d7f0a1a86918f15938264bbdc892a7303b5ddd488553ac923f073ad0a. Manifest and summary both preserve that source identity. Hashes establish consistency with these artifacts; they are not independent proof of execution beyond the recorded source and outputs.

## Independent mathematics and serialized results

The original script's fixed_eval uses engine likelihood and prediction helpers (lines 100-105); those evaluations are self-consistency checks. I independently rebuilt the trait-major dense covariance V = G tensor (Z A Z') + R tensor I, with trait-specific fixed design I tensor X. A Cholesky GLS calculation supplied beta, REML log likelihood, and EBVs from Cov(u,y) V-inverse (y-X beta). This calculation used the serialized arrays and standard linear algebra, without calling the engine likelihood, observation-order, or BLUP helpers.

For Y* M, covariance matrices transform as M' G M and M' R M; reverse mapping uses inverse(M)' Gfit inverse(M), beta_fit inverse(M), and EBV_fit inverse(M). The restricted log likelihood shifts by -(n-rank(X))*log(abs(det(M))). Trait permutations have zero shift. The declared fixed comparison metric is the generating standard deviation sqrt(diag(Gtrue+Rtrue)), held fixed across cases; it does not adapt to each fitted covariance.

I recomputed raw input maps, reverse-mapped covariance/uniqueness/loading/prediction arrays, trait and animal labels, named-start selection, likelihood corrections, and G/R comparisons. Independent raw-fit likelihood error was at most 1.3642420526593924e-12; beta norm error at most 8.447367374246271e-15; EBV norm error at most 5.818681269778951e-14. All thirty fixed-covariance identities, including truth and each returned covariance pair under all five maps, passed the independent dense calculation. Maximum likelihood-shift error was 2.0463630789890885e-12.

Maximum reverse-mapped fixed-metric relative differences reproduce the artifacts: G 7.882011293976801e-6; R 7.995605305247666e-6. Corrected fitted likelihood difference is at most 3.739614840014838e-9. Mapped prediction comparisons satisfy the declared relative 0.002 plus absolute 0.00001 tolerances. EBV norm differences reach 3.466603293123473e-5, so do not describe them as absolute errors below 0.00001. Uniqueness and sign-aligned loadings are secondary diagnostics, not additional campaign acceptance criteria.

## Independent check receipt and limits

Estimated before execution: under one minute, one Julia thread and one BLAS thread. Independent check exited zero. Scratch code: /private/tmp/fa-unit-order-independent-check-20260930.jl, SHA-256 1e4f4a21094929dba1805883482eaf5936e0b21f4e40d243a921e87c0e030065. Log: /private/tmp/fa-unit-order-independent-check-20260930.log, SHA-256 58184b44cd5b1d3f61105d5a3d4b5aa1103835798315c5603032d173d83bf395. The first scratch check accidentally used Julia's default isapprox tolerance for prediction agreement; it was corrected to the declared tolerances before the successful verification. No biological fit was repeated.

The interior screen examines the original, transformed, reverse-mapped, and forward-mapped baseline uniqueness (script lines 232-243). Passing it avoids the observed absolute-floor limitation in these cases, but does not equate all global feasible sets or prove a global optimum. Raw loadings remain sign metadata; successful covariance and prediction comparisons do not establish uniqueness inference. Population frequencies and broader DGPs remain untested.

Graft was consulted for likelihood normalization context; its cache refresh was unavailable and its returned source coordinates were stale. The independent dense formula supplies the numerical check without relying on that source span. Graft reported 155,383 tokens saved for this review.
