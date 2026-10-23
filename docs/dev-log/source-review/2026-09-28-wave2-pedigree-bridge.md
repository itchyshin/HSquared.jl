# Arc E: wave 2 pedigree and payload bridge review

Date: 2026-09-28. Candidate base commit: `a7ca8ed557b23ec23c8486365e97a7bac4b71c16`.
Checkout: `/Users/z3437171/.codex/worktrees/hsquared-fa-gllvm-foundations/HSquared.jl`,
branch `codex/hsquared-fa-gllvm-20260927`. Reviews were read-only and pinned by source
hash. No production edits or test runs were made in this review wave.

## Scope and disposition

Henderson found no correctness blocker in ordinary pedigree normalization or sparse
`Ainv` construction. Arbitrary depth and grouped unknown founders remain outside the
proven scope. Hopper found payload-v2 validation and result-shape defects. Several fixes
change twin behavior, so they need a matching R emitter or normalizer change. At review
time, the active R lane held those paths; this report records the findings for coordinated
repair.

| File | Pinned content | Review span | Disposition |
| --- | --- | --- | --- |
| `src/pedigree.jl` | `f1d1606c16f7526bf6b2c74ddc80387ac19633e7f8241e203510b65c0b3bc8f7` | `_topological_order` at 761 and ordinary normalization/Ainv paths | Scoped PASS for standard pedigree normalization and sparse Ainv; HOLD for arbitrary depth and grouped-founder scope |
| `test/runtests.jl` | Candidate base | 1382, 1427, 3034 | Existing malformed-ID/cycle/order, deep-chain, and Mrode anchors inspected; no tests rerun |
| `src/bridge_payload_v2.jl` | Review base `867019f7cc142d34bdb187b2ff091a19c4157fa50da22e98428b01632bf9b26f`; current `5181665f96f52ea2fd5a625731bc53da08f98b35ea10db6aed8cda5f1a15a57f` | 111–169, 282–318, 330–345, 371–401, 667–680, 730–743, 780–812 | Request validation and frozen correlated result shape repaired; partial raw animal tuples now fail closed |
| `test/test_payload_v2_parity.jl`, `test/wave3_payload_result_shape.jl`, `test/wave3_payload_pedigree_order.jl` | Candidate base; parity test amended | Whole relevant testsets | Added malformed-request and partner-default tests; existing fixtures cover selected v2, order, and metadata behavior |

## Findings

### Pedigree review

- Medium: arbitrary pedigree depth remains unproven. `_topological_order` uses recursive DFS (`src/pedigree.jl:761`). The reverse-listed 12,000-animal chain test checks order, row mapping, parent indices, and finite sparse Ainv entries (`test/runtests.jl:1427`). The test establishes behavior at that depth; it does not establish a safe maximum.
- Medium: grouped unknown-parent founders are outside the proven contract. Standard unknown-parent markers form unrelated base parents. Grouped founder handling needs an explicit contract and evidence; the validation-debt register keeps this open (`docs/design/validation-debt-register.md:37`).
- High for broad capability promotion: fitted animal-model validation remains partial. Supplied-variance MME and published Mrode EBV anchors are present. Same-estimand fitted-output comparison and production sparse-solve validation remain open, so this review cannot support broader animal-model promotion.
- Existing coverage checks duplicate IDs, absent parents, self-parenting, cycles, same-parent failures, out-of-order recoding, founder and one-/two-parent structures, inbreeding, and dense inverse comparisons (`test/runtests.jl:1382`).

### Payload bridge review

- P1: unsupported versions are accepted. The parser routes every version at or below 1 to legacy handling and every version above 1 to v2 (`src/bridge_payload_v2.jl:282–318`). It should accept only explicitly supported versions.
- P1: a legacy animal request without pedigree rows can be mislabeled as an animal model. Missing relationship status defaults to `identity` when pedigree is absent, then the lifted block is labelled `pedigree` (`src/bridge_payload_v2.jl:371–401`). Require pedigree rows, or label and handle the identity case accurately.
- P1: relationship type and construction status can disagree. The relationship matrix is resolved from status alone, and the parser does not enforce type/status compatibility (`src/bridge_payload_v2.jl:111–169`). For example, a `pedigree` block with `identity` can dispatch as an animal model while fitting identity precision. Validate supported pairings.
- P1: correlated result shape disagrees with its documented target. The schema specifies one labelled direct/partner pair; the implementation emits two separate records (`src/bridge_payload_v2.jl:740–743`). A missing partner name also becomes the string `nothing` before the result fallback can supply `maternal` (`src/bridge_payload_v2.jl:164–166`). Align implementation and schema with the R normalizer.
- P2: matrix and IID identifier boundaries are incomplete. The parser checks `Z` columns against only the first relationship-matrix dimension; it does not check that the matrix is square. IID block IDs are not checked for count and uniqueness against `Z` columns (`src/bridge_payload_v2.jl:330–345`). Add boundary validation.
- P2 (fixed): raw animal-result fallback previously returned only a fragment of the legacy result. The wrapper now requires `AnimalModelFit` and delegates to `result_payload`; other shapes raise `ArgumentError` (`src/bridge_payload_v2.jl:730–743`). The regression test pins rejection of an incomplete tuple (`test/test_payload_v2_parity.jl:405–418`).
- Existing v2 parity fixtures cover selected request/result paths. Current tests do not assert correlated pair shape or these malformed-input boundaries. R S3 parity is not established by these tests.

## Cross-twin handling

The initial review was read-only because a paired FA/GLLVM lane had edits in the R bridge file. The later follow-up acquired a narrow lease and changed only direct-maternal result extraction and its live test, preserving the in-flight FA changes. The correlated 2×2 formula slot remains opt-in; this change aligns its output with the frozen schema without expanding formula support.

## Follow-up implementation (2026-09-28)

The pinned review's Julia parser findings were repaired in the candidate checkout:

- `payload_version` accepts only absent/1 for the legacy shape and integer 2 for v2. It rejects unknown, boolean, and non-integer values, plus v1 payloads that also contain `random_effects`.
- Live `iid` blocks require identity construction; pedigree blocks reject identity construction; correlated blocks accept Julia-built or supplied precision, matching the schema. Resolved precision matrices must be square, and IDs must be unique and match incidence columns on v2 and lifted legacy blocks. Unknown legacy animal and second-effect relationship statuses now error.
- Legacy identity precision no longer dispatches under an animal/pedigree label. A missing correlated `partner_name` defaults to `maternal`; empty partner labels and collisions with block names are rejected.
- Added malformed-boundary tests for supplied correlated precision, legacy precision/ID/status defects, partner collisions, and the partner default. Updated the multivariate repeatability fixture to use the frozen schema's identity status for an identity permanent effect.
- `result_payload_v2` emits one correlated record with shared IDs and `direct`/`partner` vectors. The R bridge reads that record and maps both effects to the existing hsquared result structure; its live test asserts the raw Julia shape.
- Latest full `Pkg.test()` passed in writable mirror `/private/tmp/hsq-wave2-payload-final-20260928`; candidate-to-mirror hashes matched for parser `5181665f96f52ea2fd5a625731bc53da08f98b35ea10db6aed8cda5f1a15a57f`, payload tests `f361d0fa9a512f931975a796f32f3782bf6ccac294df31d6afb52ed5e35582df`, and repeatability fixture `760802d7afca31f795949fb6fdd0128a5c02e676923817cc0a102a15a4161a1c`. The validate-only comparator tests passed (37/37) with two expected Git lookup diagnostics because the mirror has no `.git`.
- R direct-maternal live bridge test passed 90 assertions; it checks Julia's single paired record and the corresponding R extraction.
- Full `Pkg.test()` passed in writable copy `/private/tmp/hsq-wave1-precision-final4`; candidate-to-copy SHA-256 matched: parser `3bc57de096640f2f4d2e0560f8d23e6549367d91f94269657a72d0e674bcebef`, payload tests `13563a7565bac994506b0597c8478c8144f789436e5064ce5d246232f35f34b2`, repeatability tests `760802d7afca31f795949fb6fdd0128a5c02e676923817cc0a102a15a4161a1c`.

The correlated result shape now follows the frozen twin contract, and partial raw animal tuples are rejected. Broader JuliaCall/R S3 parity remains unverified beyond the direct-maternal route. No capability status, release metadata, GPU code, or public claim changed.

## Recommended checks

1. Add broader JuliaCall/R S3 parity checks for legacy single- and two-effect routes.
2. For pedigree depth, add an analytic sparse-structure assertion and a permuted pedigree/record-design alignment test. Each is expected to take seconds; retain grouped-founder tests only if that feature is admitted.

## Team signoff

- Henderson: **scoped PASS** for ordinary pedigree normalization and sparse Ainv construction; limits above remain open.
- Hopper: **scoped PASS** for paired output agreement and fail-closed raw animal output at current hashes; broader JuliaCall/R parity remains unverified.
- Whole-wave acceptance: **PASS for this bounded review/fix slice**; broader parity, grouped founders, arbitrary depth, and production animal-model validation remain outside this slice.

## What this review does not establish

This review does not establish R–Julia S3 parity, broad animal-model fitting validity, grouped-founder support, arbitrary pedigree depth, or support for frozen correlated covariance slots. No GPU execution, simulation, benchmark, release submission, or public tag occurred.
