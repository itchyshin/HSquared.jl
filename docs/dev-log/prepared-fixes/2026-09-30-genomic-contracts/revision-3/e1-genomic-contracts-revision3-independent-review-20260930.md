# Independent genomic G2–G6 revision 3 review

Date: 2026-09-30. **PASS for the bounded revised G2–G6 proposal at the pins below.** Both prior G3 failure mechanisms are repaired. Preserve both HOLD reports and their failing evidence as history. Live application, composed G1 integration checks and full E1 approval remain open.

## 1. Scope and ownership

Reviewed `/private/tmp/hsq-genomic-contracts-fix-20260930/` revision 3: exact pins, the narrow changed fallback, 112 controls and both original independent counterexample sets. Wrote this report and two logs only. No live or prepared proposal edits, optimizer fits, biological campaigns or new seeds were run.

## 2. Exact proposal pins

- Receipt: `277de7ec66f5d9261d503999b645f5b921a9cca2d2a7e88869cd6ed191edd33f`.
- Patch: `b91e7696609ab36f8bfdc29643c64f803be358b4093a7df8ef3c8d076ef8daba`.
- Genomic source: `5f903569788999c2c9366385669e1ef9d5b6ea28115d20c164945c502d95cb0e`.
- Inventory: `2f2b890828f97269f24ff9cedc3c51e338f53300faf7247933409f61aae03dc8`.
- Prepared source tree: `83a14b32a8d955ab02f446223037d88bad9e663284d3204fe6662645fa557d0f`.
- Boundary test: `a1113c6f13defe90a419442ffd4f98b7cd6182820ba3e3095ce9020cf2b0897f`.

All inventoried artifact hashes and both baseline/result source-tree hashes match independently, before and after runtime. Frozen baseline genomic SHA remains `76c4053d00ed3f35db133089c5f0bfb979c1da70503a4697054bf9fa002d4b9f`, source tree `d3c2de8d7f0a1a86918f15938264bbdc892a7303b5ddd488553ac923f073ad0a`.

## 3. Prior HOLD preservation

The original proposal retains source `65c97421e92b3a731e49dda7122c19449dbbe43707d7a635825746be6ea9bce2` and patch `aa67600abde5cff6f62de93a7cfe903bf2a583751e893ae44493a811d3209d40`. Revision 2 retains source `3950164abeb976431171fe4664c86ddc30e434784826b899ef2b7f9404bbef5c`, patch `3d593bc66cf5e23a545310bcc80a55e9c1657e64b98f902e85a95f0782314271`, inventory `e5177ad8f6fa19bf294ba677f30f59d2edd6da1a4c5ec4db8ae4cb39ac016de3` and second HOLD report `773a2dcddefc34e1c093cb87ad0013c3dc22d6701d502fe553889cf3e01c9522`. Checked these archived pins directly. Earlier 88-control test files retain their exact hashes; the revision-2 runner remains unchanged.

## 4. Narrow source delta

Relative to revision 2, only the fallback condition and its explanatory comment change (`src/genomic.jl:2157–2173`). It now verifies an exact converted-factor product whenever the fast candidate is nonfinite **or at least floatmax(Float64)/2**. All other revision-2 source bytes remain identical. Twelve added tests cover the second HOLD inputs and their immediately preceding finite effect values, through both public APIs (`test/test_genomic_variance_boundary.jl:34–54`).

## 5. Algorithm and domain review

The reference is the product of the already converted Float64 allele variance and two converted Float64 effect factors. Their three significands need at most 159 bits; 256-bit BigFloat arithmetic computes the product exactly before final Float64 rounding. The final finite-output guard rejects the exact product when its Float64 result is Inf.

The upper-half fallback is conservative. A product near Float64 maximum has normal square-root, scaled-effect and squared-candidate intermediates; their rounding errors are a few units of relative precision, far smaller than the factor-of-two buffer. A finite candidate below half maximum therefore cannot conceal upper-range overflow. Zero allele variance remains zero, including huge finite effects. Ordinary finite candidates below the bound retain previous fast arithmetic; no correctly-rounded promise is introduced for every ordinary output. Existing converted-input/domain guards remain unchanged. Concurrent precision changes and fallback allocation/performance were not tested; this evidence is single-thread correctness under default rounding.

## 6. Independent runtime

Each invocation was estimated under one minute before execution. Used Julia 1.10.0, one Julia thread, one BLAS thread, `--startup-file=no --compiled-modules=no`, copied existing Project/Manifest and approved depot. No dependency changes or remote/GPU work ran.

| Run | Independent result |
| --- | --- |
| Revision-3 complete controls | 112/112, exit 0; testset 24.4 s |
| Original independent finite-answer pack | 6/6, exit 0 |
| Independent finite-candidate genuine-overflow pack | 6/6, exit 0; testset 0.1 s |
| All 112 controls against frozen source | 50 pass, 62 fail, zero errors, exit 1 |

The revised suite and both independent packs ran sequentially in one process: **124/124 assertions**. The unchanged first independent script remains `/private/tmp/e1-genomic-contracts-independent-20260930/boundary.jl`, SHA `27a25616e506faebe2d54931872f152c24da215a0db064e76fce9433ad2df4a1`. The second direct command retains the same inputs, reference and six assertions used in the prior HOLD log.

## 7. Counterexample dispositions

Original finite-answer failures now pass through both `marker_variance_explained` and `marker_scan_table`: p=.5/effect=1.8961503816218352e154 and p=.1/effect=3.160250636036392e154. Independent high-precision references agree.

The second HOLD inputs p=.25/effect=2.1894858665067565e154 and p=.08/effect=3.4946515178772264e154 still have finite fast candidates and exact converted-factor references Inf. Both APIs now throw `ArgumentError`. The immediate `prevfloat(effect)` neighbours remain finite and match their high-precision references through both APIs. Doubled-effect genuine-overflow negatives, invalid effect/frequency guards and monomorphic positives also pass. Both prior defect mechanisms close at these exact pins.

## 8. Other G2–G6 contracts

The original 88 controls still pass: absent labels reject before string conversion, literal "missing" remains valid, computational alpha stays strictly inside (0,1), original Real observations preserve exceedance signs/range, subnormal/even medians remain valid, and actual documentation bindings remain attached. Unchanged prose retains the narrow intercept-only exchangeability claim, general fixed-covariate experimental fence, sample-centering condition, default GRM-knob reduction and supplied genotype row sequence. No status/count/bridge/version change occurs.

## 9. Replay and G1 composition

Independent in-memory replay of the unified patch reconstructs all four proposed targets exactly. `git apply --check` passes against frozen baseline and the parent-applied G1 live genomic source `f6f8ba22302d55f81d25d36c2f8803fc22dfa4473cb0087613f37ec403e91523`, independently checked before and after runtime. The G2–G6 patch touches no G1 scan-helper body or postfit source. Integration must apply the disjoint patch and register its three tests, retaining the original-sign, zero-additive and convergence guards and recording a new combined source hash. Do not replace live genomic source with the standalone prepared file.

## 10. Remaining limits and minimal next checks

Parent owns the next isolated composition and relevant integrated checks, then live application. Dense storage/inversion, conditioning, cache/allocation costs, row-label provenance, permutation efficiency, mixed-covariance/general-design calibration, aggregate-sum contracts and whole-source/public claims remain separate. No full E1, A2, V3, inference, performance or release approval is implied by this PASS. Reused prior exact context; no broad source audit or new Graft query was needed.

## 11. Raw evidence

- `/private/tmp/e1-genomic-contracts-revision3-independent-green-20260930.log`: `245ef52841e97bed38df958a9c367d6725c58ec5738ed0f54082e968ddea588f`.
- `/private/tmp/e1-genomic-contracts-revision3-independent-red-20260930.log`: `575d80cee97806d68eff86923f088c586a7ea40132de5cb151e4f5c3a2785dba`.

Absolute-path slop check passed with zero hits and zero findings.
