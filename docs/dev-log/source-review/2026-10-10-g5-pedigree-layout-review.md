# G5 pedigree container layout review, 2026-10-10

## Scope

Independent, read-only source review of the current pedigree-layout repair in
the Arc 1 artifact container. This review does not close G5, authorize a study,
or certify the reported Julia package test log.

## Exact source pins

| File | SHA-256 |
| --- | --- |
| `sim/arc1/artifact_container.jl` | `93162bc7c56fad7e238248c558207e5f03e472a4a3f9c4349431b68a1a648c13` |
| `test/arc1_simulation_executor.jl` | `4d63897f1bc9b5b4ced9b157e11765fbdaf1d96677e2764319a5e8cb14045f90` |
| `test/arc1_container_framing.jl` | `cd3e8a8fea73e611f7ed7351beffbed4723f8d3eea5579f4ae13480d9dd9cdb5` |

## Finding

PASS, scoped to the pedigree-layout repair. Both type and value validators
accept exactly `(:ids, :sire, :dam, :order)` and
`(:ids, :sire, :dam, :original_order)`. The existing `HSquared` module-name
and `Pedigree` type-name checks remain, and fields are still recursively
validated. No unintended type widening was found.

The regression uses the imported current engine pedigree, validates it, writes
and reads a container, then checks `ids` and `original_order`. The embedded
fake engine retains the legacy `order` layout. Framing and serialization code
remain unchanged. The reviewer noted that this supports round trips with the
matching engine definition; it does not add cross-layout migration for
serialized structs.

## Limits

The reviewer did not rerun Julia or independently inspect the full package test
log. No model fit, study seed, Totoro access, remote contact, or file edit was
part of this review. Style assessment: NOTASSESSED.
