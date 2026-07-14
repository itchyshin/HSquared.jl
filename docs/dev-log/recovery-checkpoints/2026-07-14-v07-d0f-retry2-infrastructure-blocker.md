# v0.7 D0F retry-2 replay-infrastructure blocker

The root
`/home/snakagaw/hsq_work/v07-genomic-recovery-v3-d0f-retry-r2-2cb5308-f7ff838`
is permanently unadjudicated: 576 official fits, 576 base-R recomputations, and
zero Julia replay rows.

- Preseal: `e55e68ef8734219572bf22cf51932b78c3efd38d2e04cb9eb83323ef80f98fa5`.
- Corpus lock: `3191ba42c5061dc3693f930c81433682ff44a74f78bc27a6561c8292789ebc3f`.
- Base-R summary: `ea624296b249e37334c384c5a349037a5e91acd8f5c02b14615e2b35a25f6a6b`.
- Julia replay commit/tool: `f7ff83855c4b4d14aad39516f37b7c1b5994b7ae` /
  `8aac6c50775fcb0f5ebcd15235b2d2979bc2ac50a7b7006165342f8208d9d7de`.
- Failure: `MethodError: no method matching Cmd(::Vector{AbstractString})`
  before replay row 1.

No estimate or summary from this root may enter evidence. Its phenotype base
`2032000000` and bootstrap base `2033000000` are retired. The only continuation
is a prospective third retry at disjoint bases `2034000000` / `2035000000`
after committed bytes, exact reviews, and live Julia 1.10 preflight. D1/D2 seed
consumption remains zero.
