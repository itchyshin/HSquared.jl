# After-task report — v0.7 genomic recovery-v3 pure preseal replay layer

## 1. Goal

Provide the Julia half of a fail-closed D0F/D1 evidence contract without
opening an official seed or generating recovery evidence.

## 2. Implemented

Added exact preseal, packet, attempt, replay, summary, tree, provenance, live
environment, and typed cross-language parity validation.

## 3a. Decisions and Rejected Alternatives

Kept final adjudication disabled until the schema-bound R adjudicator exists;
used official R performance fields in scientific summaries; rejected
path-scoped cleanliness, substring host matching, missing-surface filtering,
and broad floating tolerance.

## 4. Files Touched

- `sim/phase2_v07_genomic_recovery_v3_stage_replay.jl`
- this report and the matching check-log entry/index/coordination note.

## 5. Checks Run

Direct selftest, cross-twin D0F/D1 parity, full `Pkg.test()`, and diff checks
passed. Exact evidence is in the matching check-log file.

## 6. Tests of the Tests

Deliberate mutations cover environment, commits/blobs/trees, D0 identity,
packets, unsuccessful rows, source-replay evidence, all summary fields,
performance sourcing, and illegal final admission.

## 7a. Issue Ledger

| Issue | Disposition |
| --- | --- |
| Cyclic seal | Replaced by acyclic preseal/corpus/recompute/adjudication phases. |
| Replay performance leaked into summaries | Official R attempt performance is now authoritative. |
| Arbitrary final receipt admitted | Final mode now fails closed pending the operational adjudicator. |
| Missing/deleted surface bypass | Frozen full surface lists are diffed without filtering. |

## 8. Consistency Audit

Julia schemas match the current R tool and doc 49. The actual sibling cell
table is validated; only marker ratio receives `1e-12` tolerance.

## 9. What Did Not Go Smoothly

Multiple ordinary-green implementations failed adversarial mutations. Each was
repaired before official compute.

## 10. Known Residuals

The official R driver, base-R recomputer, launcher, adjudicator, reviews,
D0F/D1 compute, D2-D4, Rose/G10, and activation remain pending.

## 11. Team Learning

Validate deployed bytes and phase dependencies, not plausible strings or file
existence.

## 12. Cross-Product Coverage

Prospective integrity only. This covers the held Gaussian-REML single-genomic
route's evidence contract. It does NOT cover recovery, robustness, production
scale, public activation, release, or a new fitted/covered capability;
`public_covered_count` stays 5.
