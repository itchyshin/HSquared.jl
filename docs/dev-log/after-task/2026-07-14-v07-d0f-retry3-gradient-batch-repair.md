# After-task report — v0.7 D0F retry-3 gradient and batch repair

## 1. Goal

Preserve retry-3 as an infrastructure-blocked corpus and prospectively harden
the Julia replay path for a fresh, disjoint retry-4 without changing its model,
estimand, or scientific thresholds.

## 2. Implemented

Recorded the exact retry-3 root, hashes, 576 successful official fits, 576
base-R recomputations, zero Julia replay rows, and missing-gradient failure.
The Julia replay tool now accepts deterministic external batch manifests bound
to the stage manifest, preseal, and corpus lock. It authenticates the complete
corpus once per batch, reauthenticates every row's official attempt and five
packet files, prechecks all targets, permits only complete-prefix resume, and
freshly recomputes every resumed row's scientific fields before continuing.

## 3a. Decisions and Rejected Alternatives

The retry-3 corpus was not patched because its preseal binds the old R attempts
and Julia bytes. The provisional summaries are not recovery evidence. A
permissive resume that merely trusted an updated replay sidecar was rejected;
resumed scientific fields must equal a fresh Julia recomputation, with only
runtime and RSS allowed to differ.

## 4. Files Touched

The Julia replay tool and sidecar, the live phase snapshot and archive, the
retry-3 blocker checkpoint, check log, and this report. The unrelated untracked
downstream-replay scaffold remains excluded and is not evidence.

## 5. Checks Run

The focused batch selftest and full D0F/D1 replay selftest pass under one-thread
BLAS. Full `Pkg.test()` passes. The tool sidecar verifies, `git diff --check`
passes, Documenter builds successfully with its existing warnings, and
`tools/preamble_cap.sh` reports one snapshot entry within the size cap. The R
twin's focused gates, live R-to-Julia genomic tests, and built-package
`R CMD check --no-manual` also pass.

## 6. Tests of the Tests

Mutations turn red for duplicate, unknown, reversed, or wrong-root batch
members; over-cap or zero batches; changed locked inputs; partial or non-prefix
outputs; an existing target under create-once mode; and a changed scientific
field in a resumed replay. Runtime/RSS differences alone remain admissible but
must be finite and nonnegative.

## 7a. Issue Ledger

| Issue | Disposition |
| --- | --- |
| Retry-3 source attempts lack finite gradients | Stop before replay row 1 and preserve the root unadjudicated. |
| Per-seed replay repeated the full corpus scan | Authenticate once per deterministic bounded batch. |
| A resumed replay could trust rewritten bytes plus a rewritten sidecar | Freshly recompute and compare all deterministic fields. |
| Interrupted output could leave a gap | Accept only a complete prefix within each strided batch. |
| Scheduling files could alter the evidence tree | Require external hash-paired manifests and an exact inventory. |

## 8. Consistency Audit

The audit covered the R bridge source, retry-3 Totoro process/root state,
preseal and corpus hashes, replay source bindings, D0F fixed-panel predecessor,
batch partition exactness, child failure propagation, sidecars, snapshot
cardinality, capability wording, and the held public route. No neighbouring
capability or count was changed.

## 9. What Did Not Go Smoothly

The first local replay selftest was run without the required one-thread BLAS
environment and failed as designed. Manual review then found that the initial
resume implementation reauthenticated inputs but did not freshly recompute an
existing replay row; that gap was repaired and mutation-tested before commit.

## 10. Known Residuals

Exact commits, five fresh reviews, Totoro deployment/preseal/preflight, retry-4
D0F, independent adjudication, D1, conditional D2-D4, final Rose review, and
maintainer G10 remain. The untracked downstream scaffold remains explicitly
non-evidence.

## 11. Team Learning

A replay resume is an evidence decision, not merely an operational convenience.
Its admissible state must be narrower than “files exist and hashes match”: the
scientific row must still be reproducible from the locked inputs and exact tool.

## 12. Cross-Product Coverage

This repair covers only the exact Julia replay machinery for the frozen
Gaussian-REML, sample-frequency VanRaden1, ridge-0.01 recovery design. It does NOT cover recovery, route activation, other genomic constructions, ML or
non-Gaussian models, multiple random effects, production scale, capability
promotion, or a public-count change. `public_covered_count` remains 5.
