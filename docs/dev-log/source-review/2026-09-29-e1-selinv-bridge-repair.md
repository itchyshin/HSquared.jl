# E1 scoped review: selected-inverse traces and payload parser

Candidate HEAD: `a7ca8ed557b23ec23c8486365e97a7bac4b71c16` with an uncommitted worktree.

## Review inputs

- Gauss numerical-engine review of the pre-fix `src/takahashi_selinv.jl`: selected-inverse recursion and permutation restoration were correct on the intended production pattern. The direct trace APIs relied on that pattern without checking it. A nonzero outside the factor fill pattern was silently treated as zero. Invalid block dimensions and offsets also lacked early errors. The reviewer’s tiny case produced `0.0` instead of the dense trace `0.5`; random sparse SPD checks matched dense selected entries within `1.3e-15`, including a nonidentity CHOLMOD permutation.
- Boole bridge review of the pre-fix `src/bridge_payload_v2.jl`: simultaneous `y` and `Y` fields silently selected `Y`; `X` rows were not matched to response rows; empty response dimensions and invalid block names passed parsing.
- The schema’s ratification checklist remains open. “FREEZE-READY” wording in the source and parity test was corrected to “ratification pending”; historical log wording was left as historical evidence.

## Repair

- `selinv_trace_against` now checks `nfixed`, square dimensions, and the exact random-block size. `selinv_block_traces` validates sparse CSC inputs, square dimensions, integer offsets, and factor bounds. Both trace loops throw `ArgumentError` if a nonzero precision entry lies outside the selected-inverse pattern. The check is in the existing accumulation loop, so it does not add a separate scan to the hot path.
- `parse_payload_v2` now rejects both response fields together, empty `y`/`Y`, an `X` row mismatch, and names that are non-string or empty after trimming.
- The schema records those payload rules and states that ratification remains pending. R emits one response field and valid string labels on the inspected route; no R source changed.

## Exact final candidate hashes

| File | SHA-256 |
| --- | --- |
| `src/takahashi_selinv.jl` | `d737029585b6b9bf1af5e72593c3dfe69ac3e795849bc82a7c74eff25b19b30e` |
| `src/bridge_payload_v2.jl` | `7d5b9d2140fd4bc7cf2961f55246c08d071a664302fd9da68c2d6706f18d9ade` |
| `test/test_selinv_trace_contracts.jl` | `4cb1d4299d580c7cd52a08d360bbe2cbfcbaa53bde8df49aa33dc871352ee936` |
| `test/test_payload_v2_parity.jl` | `8f281fb60bbc9bf0ccf46559f5152ef32b68148eff1c0457fa01c9abb0dccc73` |
| `test/runtests.jl` | `002e066bc2d38d40656e4779d7f0b11ddad98b9e4a793a4748ea03f0e48d40b5` |
| `docs/design/21-payload-v2-multiblock-schema.md` | `2b498641c01e7135f76ad14053fa72efca46f4d2737c18810feb198b893813fd` |

## Validation and limits

- The selected-inverse regression failed before repair with six missing expected `ArgumentError`s. Final focused selected-inverse tests pass **25/25**, including an independent dense inverse comparison under a nonidentity permutation.
- The parser regression first reproduced the ambiguous response acceptance. Final focused parser tests pass **8/8**. The integrated parser-parity testsets pass in the package suite.
- Final Julia 1.10 `Pkg.test()` log: `/private/tmp/hsq-e1-current-pkg-test.log`; it ends `Testing HSquared tests passed`. The run warned that `Project.toml` dependencies/compat differ from `Manifest.toml`; no resolve or update was run. A shell wrapper could not return the Julia exit code because `zsh` reserves the variable name `status`; the test log itself records the suite success marker.
- `git diff --check` passed. No simulation, benchmark, docs deployment, GPU run, CI dispatch, release, or tag occurred.
- The reviewers inspected the pre-fix files. Their exact-current post-fix re-review remains pending, so this is a repair record, not panel signoff. E1 remains **HOLD**; A2 and V3 also remain open. No capability status or covered count changed.

## Exact-current follow-up after reviewer findings

The selected-inverse review found that malformed input guards followed the expensive `_selinv_zvals` recursion and that the dense permutation oracle did not exercise either trace API. Both were repaired. The parser/schema review found stale parser/result signatures, an unsupported mixed correlated dispatch implication, outdated sibling-emitter wording, an omitted wired multivariate-repeatability row, and an obsolete branch reference. The schema, dispatch comment, and repeatability code comment were corrected; ratification remains pending.

Gauss re-reviewed the exact selected-inverse files and found no material correctness or valid-input hot-path performance concern. Exact hashes:

| File | SHA-256 |
| --- | --- |
| `src/takahashi_selinv.jl` | `88c4f5aa23999a935d9bc7ff22601df0bae1dc1d3ac9f9b8f997522fc87643c5` |
| `test/test_selinv_trace_contracts.jl` | `85a14284651d78f82c44ed8dacb9507daecfd87b391d36cc757720a6b0db1b7b` |

The focused selected-inverse file passes 27/27, including dense comparisons for both trace APIs under a confirmed nonidentity CHOLMOD permutation. The final Julia 1.10 `Pkg.test()` then passed with exit 0 on the updated candidate and ended `Testing HSquared tests passed`; it emitted the known project/manifest mismatch warning, and no dependency update was run. Gauss noted only that `selinv_block_traces` assumes sparse entries although its argument is typed `AbstractVector`; production callers supply sparse matrices. No benchmark was warranted because the review found O(K) validation work and a predictable branch on the valid hot path.

Boole's exact-current review confirmed the parser signatures, dispatch table, provenance and unratified status. It identified one sentence that blurred the unwired single-pedigree multivariate dispatch with the wired repeatability route; the sentence was narrowed and rechecked on the final hash. Whole-wave E1 remains open; this component review is not whole-wave signoff.

| File | Final SHA-256 |
| --- | --- |
| `src/bridge_payload_v2.jl` | `c5dbc8295362ca57a5a1dadffc88ae1f9c00f9883ca03dc5888ae68903f8f255` |
| `docs/design/21-payload-v2-multiblock-schema.md` | `02fe6d274d83b2c62ae972f11d32186c507e083ef19fcb1dd6702b514adb3e80` |

Boole confirmed that the wired pedigree-plus-iid multivariate-repeatability row is present; the single-pedigree `:multivariate` and `:coefcov` fit routes remain explicitly unwired. The schema still says ratification is pending and leaves the freeze checklist unchecked. The sibling R emitter exists at the inspected candidate state; generic migration is not claimed.

Gauss raised one final input-contract caveat because `selinv_block_traces` accepts an abstract vector while its loop expects sparse matrices. The helper now checks each entry is a `SparseMatrixCSC` before selected-inverse work, with a dense-input regression. Gauss reviewed the exact update and found guard placement and its O(K) preflight cost sound.

| File | Final SHA-256 |
| --- | --- |
| `src/takahashi_selinv.jl` | `2c43535a5def218e73d3fee49cad886ca173cbf3c86a5d58167b446027388fd1` |
| `test/test_selinv_trace_contracts.jl` | `0a846c9fc6850f6808eb1229f0310cd0bc4384da66311f816f3bd6c6e92dd57d` |

The latest focused selected-inverse regression passes 28/28. Julia 1.10 `Pkg.test()` on this final code state exits 0 and ends `Testing HSquared tests passed`; the known project/manifest warning remains. The package run is local evidence only; the whole E1 source-wave gate remains open.
