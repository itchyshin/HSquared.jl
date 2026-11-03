# Current-source refresh attempt for retained G1, G6, and G7 checks

The Unlazy commands first failed before loading the verifier because the inherited /bin/sh resolved python3 to an interpreter without the standard tomllib module. The CHECK commands now call /Library/Frameworks/Python.framework/Versions/3.13/bin/python3 explicitly; that executable reports Python 3.13.15 and imports tomllib.

Reverified all three old receipts using the corrected interpreter. Each verifier exited 1 with “current Julia/R source inventory differs from the externally pinned freeze”. This is a real source-freeze mismatch, not a scientific test failure. The checkboxes are now unchecked; historical receipts remain named as historical evidence. No tests, fits, package checks, R file writes, or source changes occurred during these re-verification attempts.

Fresh unreviewed current-source freeze candidates are staged outside the repo:

- G1/G6 candidate /private/tmp/h2-arc1-g1-g6-freeze-candidate-20261006.json, SHA-256 b18bb98408f22caaf9be23de40fdb6623ab0217d150732357d7c4a215faad8f7, with unchanged 47 Julia and 100 R paths and six changed Julia hashes.
- G7 package freeze /private/tmp/h2-arc1-g7-current-source-freeze-candidate-20261006.json, SHA-256 9af2d1e9454b9520cbad1646c98768c90a8da93c7e892e57b6aff0a10c1e5ed5, with 772 Julia and 274 R paths and eleven changed hashes. Existing external Julia/R sandbox, JuliaCall bootstrap, and docs frontend pins were preserved and validated.

The candidates have candidate_pending_review metadata and cannot be used for runs. Astra exact-source review is pending. No acceptance gate has been restored or advanced.
