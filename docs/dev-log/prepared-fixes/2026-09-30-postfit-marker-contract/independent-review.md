# Independent marker contract repair recheck

Date: 2026-09-30. Verdict: **PASS for the revised isolated marker contract patch**. This supersedes the implementation HOLD in `/private/tmp/e1-postfit-marker-contract-independent-review-20260930.md`; the earlier findings and red evidence remain intact there. Live integration remains open.

| Artifact | SHA-256 |
| --- | --- |
| Revised patch | `67281094c94e34fd7a29414534f5304b1a5e5fb02a5598f547e909f37afff70c` |
| Revised genomic | `d99ab651d2be5e8612e1c97edcac8b3dcfbe98ee579bad0c71b452f04ad209d9` |
| Postfit, unchanged from prior proposal | `28486afa2c11adf38aeda6149d9b858f7968f751dbea34ef09174243d721adc3` |
| Registered test | `8fa409fcb673db95633afc2b6e074d35d95f19d911cd5691c4ce7bef27779633` |
| Docs, unchanged from prior proposal | `d499c33d4805abcbb2b55a0579b32ae26673b689502726590b960c32668a3a26` |

All revised prepared hashes and patch match the updated inventory. The original proposal is preserved under the author's original-proposal directory. Inventory now distinguishes actual frozen input sources (postfit d065d525...; genomic 76c4053d...) from the unsafe proposal exercised by the underflow red check (genomic 0b68901b...). The earlier misleading red-baseline labels have been replaced.

At revised src/genomic.jl:857–858 the original Real negative sign is rejected before Float64 conversion. Finite/nonnegative converted additive variance and finite/positive residual guards remain at 861–864. This closes the negative BigFloat to -0.0 bypass for both shared-helper callers. True zero remains admitted; prior convergence checks, oracle logic and row-order documentation remain unchanged.

Independent run in `/private/tmp/e1-postfit-marker-contract-independent-recheck-20260930` reused the exact prior independent green.jl, original supplied oracle script, and underflow.jl. Estimate beforehand: under one minute, one Julia/BLAS thread, Julia 1.10.0, copied Manifest, --startup-file=no --compiled-modules=no and approved depot order. **37/37 prior supplied/augmented-QR controls passed in 4.9 seconds; 4/4 independent negative-underflow assertions passed in 0.1 seconds**, exit 0. No fit, optimizer or simulation ran.

The author's three underflow assertions are a combined sign/conversion witness plus two rejection checks. The independent test splits sign and conversion into two assertions, hence four assertions; both mixed and LOCO reject the original negative Real. Historical unsafe-proposal red evidence was already independently established as two passing sign/conversion checks and two missing-rejection failures.

No remaining blocker for this bounded repair. Broader fitting, calibration, automatic ID alignment, R activation, capability promotion and post-freeze integration remain outside approval. No source or report belonging to another lane was edited. The original HOLD receipt remains as the defect trace. No new Graft lookup was needed because the shared-helper scope and callers were already reviewed.
