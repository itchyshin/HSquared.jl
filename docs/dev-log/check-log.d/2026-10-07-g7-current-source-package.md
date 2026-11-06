# G7 current-source package verification, 2026-10-07

The complete Julia/R package gate was rerun against the independently reviewed current-source freeze.

- Freeze: `/private/tmp/h2-arc1-g7-current-source-target-detach-freeze-reviewed-20261007-v2.json`, SHA-256 `b59837b2fe5c288caf7c7d9b66cf1b00c53621e10fe4d0339c56018c7a6b41a0`.
- Independent source review: `/private/tmp/h2-arc1-g7-current-source-target-detach-review-20261007-v2.json`, SHA-256 `3d299ab2159412c778b7741764e73ecc5ae15349e427e7acd4b747c8dc2266c0`.
- Package run: `20261007T213952Z-2aa0ccbcb8`, status `passed`, total 6939.030 seconds, receipt SHA-256 `102e37fc40522f709548f3e997f85fb101edeae71bc711947f7f14685fc2b132`.
- Julia: 857.039 seconds, direct test suite exited zero, all 330 parsed summaries passed, and required Arc 1 testsets and source/environment identity checks passed.
- Mandatory live R: 2614.108 seconds, seven required files, 628 successes, zero failures, errors, or skips.
- R CMD check: 2830.455 seconds, `Status: OK`, zero errors, warnings, or notes.
- Julia docs: 36.370 seconds, `ARC1_PACKAGE_DOCS_COMPONENT_PASS`.
- Retained verifier: exited zero with `ARC1_G7_RETAINED_RECEIPT_VERIFIED` using the exact receipt and freeze hashes above.
- Package runner synthetic self-test: exited zero with `ARC1_PACKAGE_CHECKS_SYNTHETIC_SELFTEST_PASS`, covering pass/failure markers, timeout/interruption, input and bootstrap mutation, summaries, frozen source identity, docs environment and output, and resource limits.

Two earlier current-source attempts were intentionally interrupted after their Julia commands exited zero but before the slow pre/post package-tree receipts completed. Their `interrupted` receipts and logs remain preserved. They are not counted as passes. The final run was allowed to complete both receipt validations, all three package components, and the independent retained verifier.

This refresh changes no production source, selection criterion, study seed, denominator, or scientific gate. G2, G3, G4, G5, and G8 remain open; G7 is verified for this exact freeze only.
