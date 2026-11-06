# Profile-v4 current-source N160 engineering replay

Date: 2026-10-04. Branch: `codex/arc1-gaussian-reliability-20261002`.

The exact-current-source N160 engineering run is retained at `.unlazy/h2-nongpu-completion/evidence/profile-v4-current-source-replay-20261004/receipt.md`. Current `src/arc1_profiles.jl` SHA-256 is `9c807d4b6cad596e12230c9e5c5eb0f1f3e8cc7c868902706aa3ca05aa6d180c`; current `test/arc1_profiles_v4.jl` SHA-256 is `edae11c56a9442c4eb65b810f22ee7023b8cd51834979a028b4828c51181e2ff`.

The focused test file passed 198 assertions (22 engine-path checks and 176 bounded controls) in 31.451 seconds. A pinned one-thread saved-input replay exited 0 in 156.464 seconds and formed the residual-variance target. The old-versus-current artifact check exited 0 in 3.576 seconds: all 11 prior interior unresolved points now report `:ok`; the target is formed; the singular `Ve=0` proposal remains. Astra independently checked the current source and test pins, logs, outputs, comparison, and the restricted engineering-only interpretation.

This N160 dataset was inspected during method repair and is not calibration, pilot, or confirmation evidence. The historical source-mismatched replay bundle remains preserved and is not retroactively certified. No G0-G8 or H1-H9 gate closes. No R test, package check, docs build, or study ran. Public capability status and covered count remain unchanged.

The first temporary analyzer invocation failed because it expected output names different from the replay's actual `post-bypass-fix` filenames. The failed log is retained. The corrected temporary analysis and comparison scripts passed. Lane preflight found active foreign work on the shared `docs/dev-log/check-log.md` and coordination-board paths; those files remain unchanged, as detailed in the after-task report.
