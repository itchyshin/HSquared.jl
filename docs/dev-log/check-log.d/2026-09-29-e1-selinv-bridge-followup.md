# 2026-09-29 E1 selected-inverse and bridge-schema follow-up

- Focused Julia selected-inverse regression: **28/28 passed** using `--compiled-modules=no`; this includes both trace functions compared with a dense inverse under a nonidentity CHOLMOD permutation and early rejection of dense block inputs.
- Final Julia 1.10 `Pkg.test()` completed with **exit 0**, ending `Testing HSquared tests passed`. The test run included the final selected-inverse, FA, GLLVM, and payload-v2 code. It emitted the known Project/Manifest mismatch warning; no dependency resolution was run.
- Exact-current Gauss review passed for final `src/takahashi_selinv.jl` SHA-256 `2c43535a5def218e73d3fee49cad886ca173cbf3c86a5d58167b446027388fd1` and `test/test_selinv_trace_contracts.jl` SHA-256 `0a846c9fc6850f6808eb1229f0310cd0bc4384da66311f816f3bd6c6e92dd57d`.
- Exact-current Boole review passed for `src/bridge_payload_v2.jl` SHA-256 `c5dbc8295362ca57a5a1dadffc88ae1f9c00f9883ca03dc5888ae68903f8f255` and `docs/design/21-payload-v2-multiblock-schema.md` SHA-256 `02fe6d274d83b2c62ae972f11d32186c507e083ef19fcb1dd6702b514adb3e80`.
- `git diff --check` and `bash tools/preamble_cap.sh` passed on the recorded candidate state.
- E1 remains HOLD for unreviewed source spans and whole-wave signoff. A2 and V3 remain open. No capability or public covered count changed. No GPU, release, registry, merge, or tag action occurred.
