# Payload v2 direct-maternal and coefcov bridge review, 2026-09-30

## Scope and pins

Read-only bridge-contract review by Hopper, the R-Julia translator role. The Julia checkout was at HEAD `a7ca8ed557b23ec23c8486365e97a7bac4b71c16` with in-flight modifications. Exact hashes supplied by the reviewer:

| File | SHA-256 |
| --- | --- |
| `src/bridge_payload_v2.jl` | `3f1c5eed39414860953898ec23e6a8cec622d90d7009f107519892b22b63a7e0` |
| `docs/design/21-payload-v2-multiblock-schema.md` | `02fe6d274d83b2c62ae972f11d32186c507e083ef19fcb1dd6702b514adb3e80` |
| `test/test_payload_v2_parity.jl` | `8f281fb60bbc9bf0ccf46559f5152ef32b68148eff1c0457fa01c9abb0dccc73` |
| `test/wave3_payload_result_shape.jl` | `fa2c2b2324f11f2fcb0f97ed2a8cae07355317aab19fee184df0b0c32ed3fa48` |
| `test/wave3_payload_pedigree_order.jl` | `c4b77610ad8cb4530c936fed708e133012ca07a5f5d87a1d098123bf0c9c571a` |
| sibling `R/julia-bridge.R` | `c6917226b96e4255b9446f89dca8617a141837883c853834d4e40130a87bad7c` |
| sibling `R/bridge-payload.R` | `37c12b94c2e327c2ab41883b538f5d5f76666e34ad488efe7ad5a6e39385693f` |

The R checkout was at HEAD `f5c0d46bdb2ae3c2dfb2cc932883610d88f67f77`. No files or tests were changed/run by the reviewer. Julia preflight found four other refs with work on `src/bridge_payload_v2.jl` and one on the schema; R preflight found 20 refs with work on `R/julia-bridge.R`, one on `tests/testthat/test-maternal.R`, and an active Codex lease over the FA/GLLVM opt-in tests. The R handover names Cursor as intended owner. These warnings are material; the review remains read-only and no edits were made.

## Findings

1. **P1, direct-maternal result shape mismatch:** Julia `result_payload_v2` emits one `random_effects` record with shared `ids` and separate `direct` and `partner` vectors (`src/bridge_payload_v2.jl:823`). The current R caller reads records one and two, each expecting a `.values` member (`R/julia-bridge.R:1101,1124`). The schema documents Julia's paired single-record shape (`docs/design/21-payload-v2-multiblock-schema.md:216`), so the producer and extractor disagree. The direct-maternal result-shape test checks parameter count and metadata but not the actual record fields or the R extractor contract (`test/wave3_payload_result_shape.jl:98`). This route cannot be considered bridged until the twin contract and regression test agree.

2. **P2, `coefcov` validation gap:** the schema defines `basis`, `order`, `Phi`, covariate metadata, and covariance structure, and says the parser validates this frozen slot while fitting remains unwired (`docs/design/21-payload-v2-multiblock-schema.md:108,288`). `_parse_one_block` reads common and correlated-block fields but does not validate the `coefcov` fields; dispatch accepts the block before fitting raises `Phase0NotImplementedError` (`src/bridge_payload_v2.jl:148,266`). This is a parser-contract gap, not fitted support.

## Mappings supported in the inspected slice

- R emits ordered `random_effects` blocks and `payload_version=2L` (`R/bridge-payload.R:81`).
- Julia preserves block order, resolves relationship matrices, and reorders pedigree-derived relationship matrices and diagonals to declared IDs (`src/bridge_payload_v2.jl:71`). Tests cover reordered pedigree IDs and legacy maternal alias order (`test/wave3_payload_pedigree_order.jl:5`).
- One-pedigree-block output uses the legacy result wrapper and parity test (`src/bridge_payload_v2.jl:757`, `test/test_payload_v2_parity.jl:433`). Independent multi-effect output preserves block order in variance and random-effect records, consistent with the current R positional extractor (`src/bridge_payload_v2.jl:787`, `R/julia-bridge.R:1393`).
- Multivariate repeatability remains Julia-only pending R matrix-field and trait-order normalization plus parity tests (`docs/design/21-payload-v2-multiblock-schema.md:226`). Its fields are not established as an R S3 mapping.

The schema's R-lane field/order ratification checklist is still unchecked at line 321. Verdict: **hold** on direct-maternal bridge parity and `coefcov` parser-contract completion. This is a scoped result-shape/parser review only, not whole E1, broad formula support, or a capability promotion.
