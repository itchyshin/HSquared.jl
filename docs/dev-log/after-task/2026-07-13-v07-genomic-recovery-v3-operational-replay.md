# After-task report — v0.7 genomic recovery-v3 operational Julia replay

## 1. Goal

Make the committed prospective replay contract operational and safe for the
forthcoming parallel D0F/D1 corpus without consuming an official seed.

## 2. Implemented

- Bound D0F replay to the frozen D0 diagnostic corpus actually present on
  Totoro.
- Added per-row replay, quiescent replay verification, and summary execution.
- Added an in-tool Totoro/live-SLURM guard so direct replay cannot bypass the
  launcher on GitHub Actions, generic CI, or a DRAC login node.
- Aligned the R tool binding with the operational independent recomputer rather
  than the earlier pure preseal helper, and aligned the D0 tool key with the R
  D0 recomputer that the preseal actually hashes.
- Preserved official-R performance sourcing and fail-closed final admission.
- Removed whole-mutable-tree scans from parallel workers and retained them at
  the post-fan-out verification boundary.
- Added the exact tool SHA-256 sidecar required by deployment admission.
- Replaced platform-fragile raw hashes of generated R parity fixtures with the
  existing typed exact/`1e-10` field comparison, while retaining exact hashes
  for the presealed R tool bytes.

## 3a. Decisions and Rejected Alternatives

- Chose per-row atomic create-once publication followed by one quiescent exact
  tree audit. A global interprocess lock was rejected because distinct seeds are
  independent and should remain parallel.
- Rejected replay performance as a scientific substitute for public-route R
  timing/RSS.
- Kept final adjudication R-owned: the operational R adjudicator binds the
  complete evidence graph, while Julia independently replays and summarizes.

## 4. Files Touched

- `sim/phase2_v07_genomic_recovery_v3_stage_replay.jl`
- `sim/phase2_v07_genomic_recovery_v3_stage_replay.jl.sha256`
- `docs/dev-log/check-log.d/2026-07-13-v07-genomic-recovery-v3-operational-replay.md`
- `docs/dev-log/after-task/2026-07-13-v07-genomic-recovery-v3-operational-replay.md`
- `docs/dev-log/coordination-board.md`

## 5. Checks Run

The focused replay selftest, all deliberate mutations, the full Julia package
suite, `git diff --check`, and an independent post-repair Grace review passed.
Exact commands and the tool hash are in the matching check-log entry.

## 6. Tests of the Tests

The suite turns red for a changed frozen-D0 packet fingerprint, corrupted
corpus member, missing/extra replay, unexpected member, empty directory, and an
in-flight primary at the quiescent gate. It separately demonstrates that the
same unrelated in-flight window does not fail a parallel worker's own valid
pair.

## 7a. Issue Ledger

| Issue | Disposition |
| --- | --- |
| Obsolete D0 source layout expected | Fixed against the exact pinned diagnostic corpus. |
| Parallel worker scanned another worker's temporary state | Fixed by moving whole-tree validation to quiescence. |
| Julia expected the pure preseal helper at the operational recomputer slot | Fixed to bind the deployed independent recomputer. |
| Final adjudication ownership | Operational R adjudicator owns the final receipt; Julia final mode stays explicitly R-owned. |
| Direct replay could bypass launcher compute guards | Added the same Totoro/live-SLURM and no-CI guard inside the Julia tool. |
| R 4.5/4.6 generated fixture bytes differed at last-bit quantiles | Kept exact schema/tool binding and typed semantic parity; raw generated hash is descriptive. |

## 8. Consistency Audit

The audit walked D0F source identity, all four construction fingerprints,
manifest/preseal/corpus bindings, source-R comparison, replay-tree membership,
summary performance provenance, create-once semantics, and final-admission
negative space. The R twin's forthcoming worker and recomputer were explicitly
warned to use the same quiescent-tree pattern.

## 9. What Did Not Go Smoothly

The first operational implementation inherited an obsolete D0 layout
assumption. A later ordinary-green worker implementation also contained a real
parallel race that only an adversarial interleaving review exposed. Both were
repaired before deployment or official data generation.

## 10. Known Residuals

- The official R generator/fitter, base-R recomputer, launcher, and final
  adjudicator exist but are not yet committed or presealed.
- No D0F/D1 output exists, and D2-D4 remain conditional on the earlier stages.
- Public activation and capability/count changes remain held.

## 11. Team Learning

Atomic per-file publication is not enough if every worker also audits the whole
mutable tree. Parallel writers need target-local admission; corpus-wide exact
tree checks belong after the writers are quiescent.

## 12. Cross-Product Coverage

This covers Julia replay integrity for the held Gaussian-REML marker route and
its D0F/D1 evidence stages. It does NOT cover official R fitting, recovery,
robustness, production scale, public activation, release, or a new capability.
`public_covered_count` remains 5.
