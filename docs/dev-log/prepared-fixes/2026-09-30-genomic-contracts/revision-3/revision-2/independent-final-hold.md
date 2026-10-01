# Independent revised genomic G2–G6 review

Date: 2026-09-30. **HOLD for the remaining G3 upper-boundary domain defect.** The revision fixes the original finite-answer rejection; the new 100-control suite and original independent six controls pass. New genuine-overflow controls fail on both public paths. No live source was changed.

## 1. Scope and ownership

Reviewed the revised proposal at `/private/tmp/hsq-genomic-contracts-fix-20260930/`. Preserved the original proposal, original independent HOLD and every prior log. Wrote this report and three runtime logs only. Full E1, genomic calibration, performance and capability approval remain open.

## 2. Final pins

- Proposal patch: `3d593bc66cf5e23a545310bcc80a55e9c1657e64b98f902e85a95f0782314271`.
- Proposed genomic source: `3950164abeb976431171fe4664c86ddc30e434784826b899ef2b7f9404bbef5c`.
- Inventory: `e5177ad8f6fa19bf294ba677f30f59d2edd6da1a4c5ec4db8ae4cb39ac016de3`.
- Frozen original genomic source: `76c4053d00ed3f35db133089c5f0bfb979c1da70503a4697054bf9fa002d4b9f`.
- Frozen original source tree: `d3c2de8d7f0a1a86918f15938264bbdc892a7303b5ddd488553ac923f073ad0a`.
- Revised prepared source tree: `0d5c5b3d3f904b0eddcf681e6af7be26dd492a17556fb8aa9935c26eb4ac1814`.
- Added boundary test: `975a49f5e5a4068c97ab1b41c0a59a28bcd9c3d94ff3f7199f6e62d130b1ec0b`.

All inventory artifact hashes and both tree hashes match independently, before and after execution. Independent in-memory unified-patch replay reconstructs all four targets exactly. Base `git apply --check` passes.

## 3. Preserved earlier evidence

Archived source `65c97421e92b3a731e49dda7122c19449dbbe43707d7a635825746be6ea9bce2` and patch `aa67600abde5cff6f62de93a7cfe903bf2a583751e893ae44493a811d3209d40` retain their original pins. The original 88 controls retain their exact test-file hashes. The revised runner includes all three files in one parent testset so failed early suites retain the complete denominator.

## 4. What changed

The only source delta from the original G2–G6 proposal is a ten-line rare fallback in `_marker_variance_contributions` (`src/genomic.jl:2157–2171`). Nonfinite scaled-square candidates are recomputed as the product of converted Float64 allele weight and squared converted Float64 effect at 256-bit BigFloat precision, then converted to Float64. At most 159 significand bits are needed for this product, so 256 bits suffice before final rounding. Normal finite candidates retain their previous arithmetic. Twelve boundary tests were added; G2, G4–G6 bodies and prose are unchanged from the previously reviewed proposal.

## 5. Independent checks and estimates

Each run was estimated below one minute before execution, using Julia 1.10.0, one Julia thread, one OpenBLAS thread, startup and compiled modules disabled, existing Project/Manifest and depot `/private/tmp/hsq-goal-julia-depot:/Users/z3437171/.julia`. No optimizer, fit, recovery campaign, package update, remote or GPU work ran. Frozen malformed-alpha negatives may execute one seeded deterministic permutation, as declared.

| Independent run | Actual result |
| --- | --- |
| Revised complete suite | 100 pass / 100, exit 0; testset 22.6 s |
| Original independent boundary script, unchanged | 6 pass / 6, exit 0 |
| Frozen complete suite | 46 pass / 54 fail / 0 errors, 100 total, exit 1 |
| New finite-candidate genuine-overflow controls | 2 pass / 4 fail / 0 errors, 6 total, exit 1; testset 1.6 s |

The unchanged independent script remains `/private/tmp/e1-genomic-contracts-independent-20260930/boundary.jl` with SHA `27a25616e506faebe2d54931872f152c24da215a0db064e76fce9433ad2df4a1`.

## 6. Original HOLD repair verified

The p=0.5, effect=1.8961503816218352e154 and p=0.1, effect=3.160250636036392e154 finite-answer cases now succeed in both `marker_variance_explained` and `marker_scan_table`, agreeing with the independent BigFloat references. Existing far-overflow, invalid-effect/frequency, monomorphic, subnormal midpoint, ordinary numeric and documentation-binding controls pass. This closes the original four finite-answer failures at these pins.

## 7. Remaining actionable defect

The fallback only runs when the rounded fast candidate is nonfinite. Rounded arithmetic can also understate a genuinely overflowing product into a finite candidate. Independent direct Julia controls use:

| p | effect | converted weight | fast candidate | exact converted-factor Float64 result |
| --- | --- | --- | --- | --- |
| 0.25 | 2.1894858665067565e154 | 0.375 | 1.7976931348623155e308 | Inf |
| 0.08 | 3.4946515178772264e154 | 0.1472 | 1.7976931348623155e308 | Inf |

For each case, the independent reference is `Float64(BigFloat(2p*(1-p))*BigFloat(effect)^2)` evaluated at 256-bit precision. Both summary APIs return the finite fast candidate rather than `ArgumentError`. The four failing assertions test both APIs' promised genuine-overflow rejection independently of the original positive cases. All supplied far-overflow controls use doubled effects and miss this boundary mechanism. The receipt's statement that genuinely unrepresentable contributions raise remains unproven and contradicted by these inputs.

## 8. Minimal repair and validation plan

Keep ordinary fast arithmetic. Extend exact fallback/range verification to a conservative finite region close to the Float64 upper boundary, sufficient to catch fast rounding down across that boundary; document the chosen bound. Add both new cases to the complete suite with both public paths, retain the original finite-answer cases and far-overflow negatives, then rerun the focused suite and these independent controls. A fallback for every ordinary finite value is unnecessary. Reviewer made no implementation edit.

## 9. G1 composition boundary

The parent-authorized composition moved live genomic source to `f6f8ba22302d55f81d25d36c2f8803fc22dfa4473cb0087613f37ec403e91523` through G1 only. The revised G2–G6 patch independently passes `git apply --check` against that live source. Its patch has no G1 scan-helper hunk; common/cache helpers remain byte-identical to frozen source and the previously reviewed stats-body preservation is unchanged. No postfit file occurs in the patch. Future integration must apply the disjoint changes and record a new combined source hash, preserving the approved convergence, zero-additive and original-sign guards. Neither standalone prepared source can replace the full live file.

## 10. Remaining limits

Retain prior bounded G2 absent-label checks, G4 computational-alpha/original-observation comparisons, G5 intercept-only exchangeability claim, and G6 centering/GRM-knob/row-order conditions. Their assertions still pass. No summed-contribution accuracy/range contract is claimed by these per-marker outputs. Calibration, matrix/conditioning/memory/permutation efficiency, concurrency and fallback performance, whole-source review and full E1 remain separate.

## 11. Evidence and handoff

The following logs preserve exact revised passing, frozen failing and newly failing evidence. Parent should return this narrow defect to the original implementer and request fresh pins for independent recheck. Preserve both HOLD traces. No source substitution or live edit was performed. Reused prior exact context; no additional broad source audit or Graft query was needed.

- `/private/tmp/e1-genomic-contracts-final-independent-green-20260930.log`: `1860f99bf530dd950fa5f4b14218f6e8b2f2d74f2275bad2c1ca3a149b1e696a`.
- `/private/tmp/e1-genomic-contracts-final-independent-red-20260930.log`: `4a459040d8a200829c50294e3f0c72253fc464b894310287ff633eeb8f37cb8a`.
- `/private/tmp/e1-genomic-contracts-final-independent-overflow-20260930.log`: `6d8cf2408b225fa6dfd848eb2fae1146f6118292fbaf72d2bd66e02baee64367`.
