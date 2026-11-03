# Exact-scope review: H0 planning readiness

Date: 2026-10-06  
Review: independent Rose read-only audit  
Scope: current M0 route map, paired ledger crosswalk, H0 gate wording, and remaining planning assignments. This is planning evidence only. No route, fit, simulation, or scientific gate was tested.

## Verified planning inputs

The exact Julia/R capability and validation-debt ledger hashes match those recorded in the M0 crosswalk:

| Input | SHA-256 |
| --- | --- |
| Julia `docs/design/capability-status.md` | `bfb9449f2072ea92dff4c0ee1753742c10008e1e6405af2b86e486f514ea557a` |
| Julia `docs/design/validation-debt-register.md` | `ec1c4a418b7c483faeff934ed91cf2049de9a51957f1697d3fead7ced8283f7e` |
| R `docs/design/capability-status.md` | `8b88537e70fb6fe0f2d3be96a69da136a307c94ab437119d7144df3b50e67a83` |
| R `docs/design/validation-debt-register.md` | `f81925f2d85e1989f6b6a2c44f7ab32f253581676bbe3f17dd253269b69ebb48` |
| H2 non-GPU plan | `dc30a25a1f052dadff19684537e4628e1ef24d480e9354932d2caa9eb2368d92` |
| M0 row crosswalk | `78a06932e1908e267f5b9aeb8a4c1457367ac376f4912515d2d41671d8c1c0091` |
| M0 acceptance map | `7c7664fbfb83d9c3f0bd7e7cb5df22de0da90a1fb2d42d83caa235b14a8c6d10a` |
| M0 status correction | `95acee57f5bbb20dbf5bd767aa50fc395c8b12372ff3b16ee2bcae9f9e6d036f` |

The map covers 20 route groups and assigns owners, baseline tests, acceptance outcomes, dependencies, and first executable leaves. The format cases distinguish VCF from BCF. These assignments do not pass runtime routes. Exact checks, current source/test freezes, and execution evidence are assigned to later implementation leaves.

## H0 limits and unresolved assignments

H0 is best described as **planning readiness reviewed**, not as proof that any capability route works. The current root gate marks H0 complete, while the amended M0 status note limits an earlier pass to an earlier snapshot. Current GATES wording also says formats still need route contracts, although the current map provides those contracts. Reader or bounded-refusal behavior, fixtures, and executable acceptance checks remain due.

Three planning assignments still need resolution:

1. **Plots:** Julia rendering still has a TODO, and the map has not chosen whether the missing R drawing validation becomes a dedicated debt row or an equivalent explicit gate.
2. **Non-standard inheritance:** Julia lists multiple inheritance kernels, while R has one aggregate planned capability row and no kernel-specific validation-debt rows. The map needs per-kernel acceptance IDs, an evidence/checker route, and a named first leaf, or an explicit owner-approved bounded exclusion for each kernel.
3. **Paired R source pins:** the M0 map records that the relevant R bridge/backend source files are absent from its pinned identity set. Pin them before M0 closes.

The audit does not find a reason to change capability or covered status. GPU execution, publication, and releases remain excluded.

## Coordination boundary

The lane preflight for parent H0 files reports two live lanes and directs the current task to name one lane and avoid touching the other lane's files. This task owns the Arc 1 lane. It therefore records the H0 findings here without editing `.unlazy/h2-nongpu-completion/GATES.md`, the shared M0 map, or the coordination board. The exact owner of the other live lane is not established by the preflight output.

## Next bounded action

Resolve H0 wording, plotting and per-kernel inheritance assignments, and paired R source pins in the parent planning lane. Then obtain an exact-hash review of the amended planning snapshot. Keep all H1-H9 runtime and scientific gates open until their own retained checks pass.

## Editorial check

Style: 2/10, moderate confidence; this is a concise planning-audit record. Evidence/repair: the explicit lane boundary explains why the parent files remain untouched; no change needed. Gates: science = not applicable because no model result was tested; facts = pass for the audited planning hashes and row assignments, with H0 wording inconsistency left open; references = not applicable because no external literature claim is made. Provenance: self-review of the written audit, 2026-10-06; the review examples and repo files were seen.
