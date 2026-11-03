## 1. Goal

Determine whether the retained G2 outer 7 and outer 10 artifacts contain enough optimizer state to reconstruct the BFGS updates before proposing a numerical repair.

## 2. Implemented

Added an artifact-hash-pinned, read-only Julia inventory under `LOOP/lanes/arc1-gaussian-reliability-20261002/evidence/g2-v7-batch-driver-20261006/retained-telemetry-audit-20261006/`. It deserializes the exact retained development inputs and Wolfe witness outputs, checks identity and accepted-step endpoint continuity, and reports available attempt/event fields. It invokes no fitting or objective API.

The inventory confirms that the artifacts retain final gradient norms, finite-difference gradient summaries, scalar line-search slopes, origins, directions, and accepted-step continuity. They do not retain full gradient vectors, Hessian matrices, or BFGS update/skip/reset history. This evidence can validate recorded line-search arithmetic, but cannot reconstruct the optimizer's BFGS state or independently check each stored directional slope.

## 3a. Decisions and Rejected Alternatives

No source repair is justified by these records. Keep the frozen Wolfe, final-gradient, covariance, reference, start, and refusal rules unchanged. A diagnostic capable of reconstructing BFGS state needs new exact-source telemetry and independent review before any additional optimizer/objective evaluations.

## 4. Files Touched

- `LOOP/lanes/arc1-gaussian-reliability-20261002/evidence/g2-v7-batch-driver-20261006/retained-telemetry-audit-20261006/inspect_retained_optimizer_telemetry.jl`
- The same directory's `audit-v2.stdout.log` and `audit-v2.stderr.log`
- The same directory's preserved first-pass `audit.stdout.log` and `audit.stderr.log`
- `docs/dev-log/check-log.d/2026-10-06-g2-retained-telemetry-inventory.md`
- `docs/dev-log/after-task/2026-10-06-g2-retained-telemetry-inventory.md`
- `LOOP/lanes/arc1-gaussian-reliability-20261002/checkpoint.md`

## 5. Checks Run

- Read-only Julia 1.10.0 inventory command with one Julia thread and BLAS thread, `--compiled-modules=no`, and the scratch-first depot: exit 0. The script and stdout are hash-pinned in the check log. Stderr is empty.
- Both exact input and witness hashes matched the pins in the script. Accepted endpoint continuity passed exact Float64 equality for all 109 outer 7 accepted events and all 166 outer 10 accepted events.
- `git diff --check`: exit 0.
- `python3 ~/shinichi-brain/tools/slop_check.py <absolute report path>`: 0 findings.
- Structural after-task validation: pass. The full project closeout gate is not claimed by this slice because the scientific gates remain open.
- Current Arc 1 ledger/checkpoint status remains G2-G5 and G8 open; G0, G1, G6, and G7 are recorded as verified. No gate status changed.

## 6. Tests of the Tests

The inventory refuses changed input hashes, wrong outer/seed/data identity, a mismatched frozen start, unexpected line-search counts, discontinuous accepted endpoints, or unexpected gradient/update telemetry. No deliberate mutation run was performed. The source is an evidence inventory, not an optimizer test.

## 7a. Issue Ledger

- Resolved for the retained files: whether they contain full gradient vectors or Hessian/update history. They do not.
- Deferred: exact-source optimizer instrumentation and a separately reviewed one-index diagnostic, if the implementation owner and reviewer agree the additional telemetry can distinguish an optimizer defect.

## 8. Consistency Audit

The inventory targets the exact input files referenced by `audit_wolfe_witness_results.jl`, under `g2-current-source-n80-null-development-v1`, not the later v7-store files with the same outer indices. The mismatch was caught during the read-only inspection and the exact named inputs were rechecked. This report does not merge results from those different retained stores.

## 9. What Did Not Go Smoothly

The first Julia deserialization probe ran without loading the `HSquared` module and stopped because Julia Serialization could not resolve its package-defined types. It performed no fit. The successful inventory loaded `HSquared` definitions, then deserialized the pinned artifacts without calling a model fit or objective function. The first audit stdout is preserved with SHA-256 `6a5047b71b7fdcfea319b75d64e912a74ec0e56e0d895d26a13c173e74d5677a`; its result values were valid, but its first-line wording could be misread as describing the original fits. Version 2 corrects the wording and is the final audit log.

## 10. Known Residuals

G2 remains unmet. The saved records cannot establish the curvature update state or independently validate the stored scalar slopes. G3 and the G4/G5 calibration studies remain open, and G8 final review remains open. No new fit, pilot, confirmation study, R parity run, or capability-status change occurred.

## 11. Team Learning

Before diagnosing an optimizer from retained rows, verify that the exact row contains the state needed by the proposed analysis. Final gradient norms and scalar directional slopes are not substitutes for gradient vectors and BFGS update history. Also confirm the exact retained input path in the audit source before comparing artifacts with matching outer indices.

## 12. Cross-Product Coverage

Covers: read-only Julia inventory of two retained G2 development attempts and their Wolfe event streams.

Does NOT cover: new fitting, source repair, expanded-reference qualification, G2 reliability, automatic-rank confirmation, FA interval calibration, repeatability calibration, R parity, public status, releases, or GPU execution.
