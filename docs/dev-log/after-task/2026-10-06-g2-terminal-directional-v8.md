## 1. Goal

Check whether the recorded outer10 terminal directional slopes agree with independent high-precision finite differences at the exact line-search origin and rejected trial. The bounded result informs G2 diagnosis only.

## 2. Implemented

Ran one read-only diagnostic over the consumed outer10 balanced retry-0 failure. It compares stored directional slopes with 256-bit central differences at three predeclared step sizes and compares each Float64 center objective with a BigFloat reference. No optimizer, selector, simulation, or allocated study attempt ran.

## 3a. Decisions and Rejected Alternatives

Kept the diagnostic to one failed outer10 attempt. Preserved the frozen Wolfe criteria, source, seeds, denominators, and acceptance rules. Did not change the optimizer based on this result.

## 4. Files Touched

- `LOOP/lanes/arc1-gaussian-reliability-20261002/evidence/g2-bfgs-state-telemetry-v1/terminal-directional-admission-v8.json`
- `LOOP/lanes/arc1-gaussian-reliability-20261002/evidence/g2-bfgs-state-telemetry-v1/terminal-directional-source-lock-v8.tsv`
- `LOOP/lanes/arc1-gaussian-reliability-20261002/evidence/g2-bfgs-state-telemetry-v1/terminal-directional-audit-v8.toml`
- `docs/dev-log/check-log.d/2026-10-06-g2-terminal-directional-v8-supervisor.json`
- `docs/dev-log/check-log.d/2026-10-06-g2-terminal-directional-v8-stdout.log`
- `docs/dev-log/check-log.d/2026-10-06-g2-terminal-directional-v8-stderr.log`
- `docs/dev-log/check-log.d/2026-10-06-g2-terminal-directional-v8.md`
- `docs/dev-log/after-task/2026-10-06-g2-terminal-directional-v8.md`
- `LOOP/lanes/arc1-gaussian-reliability-20261002/checkpoint.md`

Other shared-worktree changes belong to prior lanes and were left untouched.

## 5. Checks Run

- Exact-source Astra admission review: PASS for candidate SHA-256 `1102af5d6aba77f8c68eb8b8664f08ca7f00e5ebdcab17539d2b25a83fda515c` and source-lock SHA-256 `c1c9eaae0033fb9a420975d38de460d14e316a07bea83efc91081c72709cb82b`. All 63 locked entries matched, including 30 source files, the active project and manifest, the exact development-v1 outer10 full input, its input metadata, and the matching telemetry artifact.
- Supervisor unit tests: exit 0, 2/2 passed.
- Supervisor preflight: pass; candidate, lock, prior receipts, and output/run-path absence verified.
- Julia syntax parse: pass before execution.
- Bounded execution estimate: 300 seconds. Actual supervisor elapsed 69.946 seconds; Julia elapsed 67.360 seconds; child exit 0; process group gone; post-run source and candidate hashes matched. Receipt SHA-256 `fe7c00a8a46df2ad3510f2e6e238b7f8059eac1792c35ee165acf6c95b6560c5`.
- Result SHA-256 `70efe8d9bde2d5755f723ccdf22c894b4976fa615a18e73c745d53eebde7dce4`; retained at `LOOP/lanes/arc1-gaussian-reliability-20261002/evidence/g2-bfgs-state-telemetry-v1/terminal-directional-audit-v8.toml`.
- Retained stdout SHA-256 `fd8a55e3128f360a8128809c5d70f3d14866872cd15f9e8595ce8a61520477dc`; stderr is empty (SHA-256 `e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`).

## 6. Tests of the Tests

The two supervisor tests verify preflight refusal on changed inputs and output collisions. The Julia driver checks source and input hashes, runtime settings, parameter dimensions, the exact outer10 origin/rejected-trial event linkage, and the 16-call budget before evaluating the bounded points. No destructive mutation test was run.

## 7a. Issue Ledger

- Observed: at both the origin and rejected trial, stored directional slopes agree with independent 256-bit central differences to about `7e-25` or better across the three step sizes.
- Observed: Float64 center objectives differ from 256-bit references by approximately `1e-16`.
- Observed: the frozen curvature bound requires a trial slope of at least `-2.13034706689e-14`; the recorded value is `-2.30398618217e-14`, missing it by `1.73639115e-15`. The 256-bit finite differences reproduce this rejection, while sufficient decrease passes. This identifies the immediate Wolfe failure, not why the search produced this direction or reached the cap.
- Unchanged: study denominators, frozen criteria, gate status, capability status, and source implementation.

## 8. Consistency Audit

The executed driver reads the same development-v1 outer10 full artifact and telemetry artifact that the reviewed lock pins. The supervisor verified post-run immutability. The calculation uses only the recorded direction, origin, step, and terminal trial; the finite differences call the exact high-precision REML reference. No selection or fit procedure is invoked. The retained telemetry result does not include the per-trial domain-rejection observations needed to reconstruct why the five cap reductions occurred. A bounded inspection confirmed the retained object has Wolfe summaries and terminal events only. No additional objective probe is justified by this missing record.

## 9. What Did Not Go Smoothly

Two exact-source review cycles found incomplete provenance pins: first the source closure omitted active files; then it pinned an outer10 artifact from a different store than the driver reads. Both were corrected and reviewed before objective evaluation. The final admission includes the exact executed inputs and 30 current Julia source files.

## 10. Known Residuals

This diagnostic is not a source repair or a reliability result. It uses one consumed failure and cannot establish population-level optimization quality. It explains the immediate curvature-condition refusal but cannot determine the upstream cause because the per-trial rejection reasons were not retained. G2, G3, G4, G5, and G8 remain open. No pilot or confirmation is authorized by this observation.

## 11. Team Learning

For hash-pinned diagnostics, compare the driver's resolved input paths directly with the source-lock entries. A matching but unused artifact is not provenance for the file actually evaluated.

## 12. Cross-Product Coverage

Covers: one Julia internal high-precision directional-slope consistency check on a retained automatic-FA optimizer failure.

Does NOT cover: optimizer repair, ordinary-fit reliability, rank-selection performance, uncertainty calibration, R parity, package release, publication, or GPU execution.

