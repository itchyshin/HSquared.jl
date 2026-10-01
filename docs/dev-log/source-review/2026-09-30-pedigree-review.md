# Pedigree source review checkpoint: 2026-09-30

## Scope and pins

Review of `src/pedigree.jl` in the FA/GLLVM candidate at HEAD `a7ca8ed557b23ec23c8486365e97a7bac4b71c16`. Final working-tree source SHA-256: `522741349ecfca48afc29d06f04bf4f6a0206fbc84648606e1ebf9f5444267d4`; test SHA-256: `d6f123f702b929a2eb77745d22d1c4bfc7b0bf771ad4f20ea1ea680429b8f906`; registration SHA-256: `74814093a0ae4a619c35301ee8366f758822e0c3ce6a2bff05965ab26db96b78`; capability-status SHA-256: `daf32aaaa16834a148d2240336990ef835befe8a6df298be6007ce91288b3e01`; validation-debt SHA-256: `df409aab18c1de885acdabcbc84eacebac6956bc3bb2ef0ce936da1f5a41f46e`. These pin working-tree bytes, not committed HEAD.

## Findings

The clonal relationship helper at source lines 432–480 constructs the ordinary pedigree relationship, then aliases clone rows to genet rows. If a ramet is used as a sexual parent, descendants are calculated as though it were an unrelated founder. For `G = P × Q`, ramet `r` cloned from `G`, and `h = r × U` with unrelated `U`, the returned `C[h,G]` is zero. The expected additive relationship is one half for non-inbred `G`. Source, capability, and debt prose now state that ramets must be terminal and this parent case can be wrong; the function does not reject it. Breeding through ramets needs a new recursion and independent fixtures. This finding concerns an experimental primitive; it does not describe a fitted clonal model.

The inbreeding test and `V1-AINV` row called Meuwissen–Luo O(n), but the heap traversal depends on total visited ancestry and heap operations. The source docstring, capability row, backlog, wave plan, and debt row now use structural wording and avoid a general runtime bound. Rose also found `sim/phase5_sparse_aireml_benchmark.jl:88` still labels the Ainv path O(q). Preflight found divergent work for that file on the stale Claude handover ref, so the comment remains pending ownership reconciliation.

The seven-generation selfing test does not establish exact inversion across all conditioning. Deep selfing can round a parent inbreeding coefficient to one in Float64, making the Mendelian sampling variance zero. A new depth-80 regression pins the current `ArgumentError` diagnostic when this occurs; it does not claim the exact mathematical relationship matrix becomes singular or identify the earliest rounding generation.

The `_numerator_relationship` docstring says `inbreeding_coefficients` takes its diagonal. Production inbreeding uses `_meuwissen_luo_inbreeding`; the dense routine is an oracle.

Capability-status prose said selfing and clonal work remained planned, while detailed rows described experimental primitives. The summary now identifies selfing and clonal inheritance as separate experimental primitives; haplodiploid and polyploid construction remain planned.

For metafounders, multi-group Gamma coordinate order follows first appearance after pedigree normalization. Current wrapper parity tests reuse this internal ordering. A future user-facing contract needs a labelled group-order fixture.

## Final review and test evidence

Henderson's GPT-6.1 Sol High exact-byte follow-up reviewed the final source and regression design. It found no remaining numerical defect in the inverse assembly or Mendelian sampling formulas and closed the missing-mate test and reciprocal docstring findings at source/test-review level. The review covered source spans 175–183, 337–367, and 868–878, and test spans 5–55. Both known-parent positions check `F=0`, `d=11/16`, hand-calculated inverse contributions, symmetry, round-trip identity, and sire/dam swap. The descendant fixture checks `F=1/16`; the Float64 fixture checks the current zero-variance rejection boundary. Reviewer confirmation is not execution evidence.

The focused regression file passed **20/20** assertions. The full `Pkg.test()` run passed and ended `Testing HSquared tests passed`. One earlier full-suite attempt was terminated by SIGTERM; it is not counted as passing evidence. No simulation or fit campaign was run.

## Disposition

The sparse inverse / inbred known-parent test gap is closed for the reviewed candidate bytes. The new tests, docstring correction, and bounded validation-debt wording are recorded. Rose's scoped claim audit passed for the source, capability, backlog, status, and terminal-ramet wording. One benchmark O(q) comment remains on the divergent handover ref. The clonal-ramet parent defect, broad conditioning evidence, and metafounder group-label contract remain open and outside the approved FA/GLLVM cells. No capability was promoted. This review does not close E1, A2, V3, or the broader twin programme; no GPU, release, registry, merge, or tag action occurred.
