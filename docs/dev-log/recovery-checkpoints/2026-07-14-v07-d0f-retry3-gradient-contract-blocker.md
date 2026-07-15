# v0.7 D0F retry-3 gradient-contract blocker

## Verdict

The sealed retry-3 root is permanently **unadjudicated**. It is a bridge/tool
contract blocker, not recovery evidence and not a negative estimator result.
No estimate or summary from this root may support activation, promotion, or a
capability claim.

## Locked diagnostic corpus

- Totoro root:
  `/home/snakagaw/hsq_work/v07-genomic-recovery-v3-d0f-retry-r3-b68d5e0-99a513e8`.
- Exact deployment:
  `/home/snakagaw/hsq_work/v07-genomic-recovery-v3-code-b68d5e0-99a513e8`.
- R driver commit: `b68d5e0abd39e907bc01bc7813f6e7a66e2efa1c`.
- Julia replay commit: `99a513e8a34aeeeb34b01552f4f96e5feb34e6d4`.
- Preseal SHA-256:
  `748d8e0e4def2d488382a5c2695e7b1a81bf6ba90581a63e03f2a72d7c2d39d9`.
- Corpus-lock SHA-256:
  `96654c9da25d2f5e173888160b77b0c970bb1340c8a0d0a1ecb739cb2d78f4f1`.
- D0F manifest SHA-256:
  `0643250f053612e88a487b501c00551458d9e54dced254de03bdb5e4a837c788`.
- Fixed-panel manifest SHA-256:
  `08a723bb4ffd51bbd6c2039b8fd5b1480b88238029fb73362f33f90331c42e9e`.
- Bootstrap-index manifest SHA-256:
  `73fe308992925ff6aeb577657262c4a6aa2a21b1534adf3d896392670933ec27`.
- Base-R summary SHA-256:
  `6aa8f1ca3f3d0f370ed18c9c5fb870a6521242a2d7c9c60aaa829c1a84fb6dbf`.

All 576 official attempts completed with `status=success` and
`converged=true`: 566 interior, five lower-boundary, and five upper-boundary.
All 576 independent base-R recomputations completed. The three provisional
design summaries were `COMPLETE`, with mean ratios 0.5018783, 0.4975003, and
0.4936754. These are diagnostic facts only because the required third route
does not exist.

## Exact failure

Every official success stored canonical `gradient_norm=NA`. The public R
payload had discarded the boundary fitter's available
`ai_diagnostics.ai_score_norm`, and the recovery driver silently substituted
`NA`. The exact Julia replay correctly required a finite successful gradient
before recomputation, so it stopped on the first source row with:

```text
gradient_norm is not finite numeric
```

No Julia replay primary or sidecar was written. The failed launcher briefly
left remote Julia workers; the exact process group was terminated and the root
was rechecked at zero replay rows. The preseal binds the old R and Julia bytes,
so changing attempts, swapping tools, relaxing parity, or synthesizing replay
rows would invalidate the evidence chain.

## Retired seeds and prospective continuation

The 576 phenotype seeds generated from base `2034000000` (observed range
`2034101001:2034324008`) and the three bootstrap-index seeds generated from
base `2035000000` are permanently retired. No D1 or D2 seed was consumed.

Prospectively, the R bridge reads the exact boundary AI score norm, the official
driver treats a missing/nonfinite value as an infrastructure contract error
before packet or attempt publication, and attempt admission independently
rejects a successful nonfinite value. The existing Julia finite check and exact
route-parity comparison stay unchanged. Fresh disjoint retry-4 seed bases, a
new root/preseal, five new exact-commit reviews, and a zero-seed live preflight
are required before another phenotype is generated. Default routing remains
held and `public_covered_count` remains **5**.
