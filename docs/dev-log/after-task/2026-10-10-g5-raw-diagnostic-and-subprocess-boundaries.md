## 1. Goal

Retain bounded engineering evidence that raw repeatability diagnostics and the receipt checker's Julia-inspector subprocess outcomes are bound and fail closed.

## 2. Implemented

Added evidence-lane probes without changing package source: one mutates target diagnostics and the point-fit candidate after result construction; one exercises subprocess success, nonzero exit, and timeout using a fake Julia executable; two measure synthetic native-container sizes; and one measures framed profile-history restoration near the historical artifact's size. No scientific fit, interval calibration, seed allocation, denominator, or gate status changed.

## 3a. Decisions and Rejected Alternatives

- Used synthetic in-memory profile data and a fake Julia executable to isolate the raw projection and process boundary from scientific computation.
- Did not read or retry the previously timed-out 130,851,693-byte artifact.
- No assumptions were made that these checks imply G5 calibration or gate completion.

## 4. Files Touched

- `LOOP/lanes/arc1-gaussian-reliability-20261002/probe_g5_raw_diagnostic_projection.jl`
- `LOOP/lanes/arc1-gaussian-reliability-20261002/probe_g5_real_inspector_subprocess.py`
- `LOOP/lanes/arc1-gaussian-reliability-20261002/probe_g5_artifact_inspector_size.py`
- `LOOP/lanes/arc1-gaussian-reliability-20261002/probe_g5_artifact_inspector_exact_size.py`
- `LOOP/lanes/arc1-gaussian-reliability-20261002/probe_g5_history_inspector.py`
- `LOOP/lanes/arc1-gaussian-reliability-20261002/probe_g5_history_inspector_exact_size.py`
- `LOOP/lanes/arc1-gaussian-reliability-20261002/evidence/g5-raw-diagnostic-projection-probe-20261010/`
- `LOOP/lanes/arc1-gaussian-reliability-20261002/evidence/g5-real-inspector-subprocess-probe-20261010/`
- `LOOP/lanes/arc1-gaussian-reliability-20261002/evidence/g5-artifact-inspector-size-20261010/`
- `LOOP/lanes/arc1-gaussian-reliability-20261002/evidence/g5-artifact-inspector-exact-size-20261010-v1-label-mismatch/`
- `LOOP/lanes/arc1-gaussian-reliability-20261002/evidence/g5-artifact-inspector-exact-size-20261010-v2/`
- `LOOP/lanes/arc1-gaussian-reliability-20261002/evidence/g5-history-inspector-size-20261010/`
- `LOOP/lanes/arc1-gaussian-reliability-20261002/evidence/g5-history-inspector-exact-size-20261010/`
- This after-task report, `docs/dev-log/check-log.md`, and `LOOP/lanes/arc1-gaussian-reliability-20261002/checkpoint.md`.

## 5. Checks Run

- Julia raw diagnostic projection probe: exit 0, 1.165 seconds; unchanged receipt accepted, changed target and point-fit diagnostics rejected. Output manifest pins the probe and both Julia source files.
- Python real-subprocess probe: exit 0, 120.736 seconds; success output accepted, nonzero exit rejected with bounded stderr, actual 120-second timeout translated to `ReceiptError`, and the child PID was absent afterward. The subprocess fixture used a fake Julia executable and did not launch Julia.
- Synthetic raw-byte container benchmarks passed at 1, 16, and 64 MiB: inspection took 13.257, 18.161, and 33.646 seconds, respectively. A synthetic container exactly 130,851,693 bytes passed inspection in 53.418 seconds; total generation and inspection took 104.451 seconds. Its 130,850,958-byte payload consists of a byte array and carries no profile history. The historical artifact was not accessed. The first exact-size run's output cap label was wrong and is retained as v1; corrected v2 is the counted result.
- Synthetic framed profile-history restoration passed at 1 and 16 MiB, restoring 16 and 256 events. A 131,171,044-byte history container restored all 1,997 events: 18.311 seconds for inspection and 21.241 seconds total. Its event values are synthetic repeated strings; it does not reproduce fitted profile diagnostics. The historical artifact was not accessed. Manifest SHA-256: `657130c7db7741bf40ac632d42995072097f1d726a0e9d49df28ac8dc6ea4f9b`.
- Python compilation and full package checks were not rerun because no package source or tests changed. G7 remains tied to its previously reviewed v26 freeze.

## 6. Tests of the Tests

Both probes include explicit mutations/failure injections. Removing either diagnostic mutation assertion would leave the corresponding case untested; accepting a subprocess nonzero exit or timeout, or retaining its process, fails the probe. These probes test engineering boundaries only.

## 7a. Issue Ledger

- Raw diagnostic projection gap: bounded probe added; no source defect found.
- Inspector subprocess boundary gap: bounded real-process probe added; no source defect found.
- Large-artifact performance and scientific interval calibration remain open under G5.

## 8. Consistency Audit

Confirmed `tools/arc1_receipt_check.py`, `sim/arc1/execute_attempt.jl`, the existing G5 v26 source map, and the evidence-lane tests agree on diagnostic identities and fail-closed behavior. The checker source hash remains `b1880621b3ba6feab951e3cc141706dc1d06b9255a526411f33af8aee3217da6`; the execute-attempt source hash remains `f12a0805ef49ab795f4b04d22dbae9e24015d03866565ef3d4dce29fc1072016`.

## 9. What Did Not Go Smoothly

The first standalone Julia probe omitted `engine_io.jl`, so it stopped before testing the projection. The corrected probe uses the runner's dependency order. The shared `closeout.py` helper resolves its root to the brain repository, so it could not create this report in the permitted HSquared worktree; the project has no local closeout validator.

## 10. Known Residuals

G5 remains open. The synthetic profile-history fixture establishes only the container's framed-event restoration performance at this approximate size. It does not establish interval formation, coverage, calibration, or performance for traces containing fitted optimizer diagnostics. The subprocess failure tests used a fake Julia executable. No G2-G5 or G8 gate is closed by these probes.

## 11. Team Learning

The successful live fixture did not establish subprocess failure-path behavior. Separate fake-executable process-boundary probes now cover nonzero exit and timeout handling. Synthetic event-history rows exercise framed restoration, while fitted optimizer diagnostics remain outside this performance fixture.

Memory receipt: reviewed `MEMORY.md` HSquared Arc 1 scope notes and the repository `AGENTS.md`; the missing LOAD-FIRST registry entry was reported by `route.py`. Golden Set: not run; this bounded probe did not modify the known-mistake classes in package code.

## 12. Cross-Product Coverage

- Repeatability retained-result projection and Python receipt inspection: covered ✓.
- Scientific repeatability interval formation and coverage across variance cells: does NOT cover ✗.
- User-facing R-to-Julia parity and package source behavior: does NOT cover ✗.
- FA rank-selection reliability and its confirmation study: does NOT cover ✗.
