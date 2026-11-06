# G5 N320 outer-2 development diagnostic

The Astra-reviewed admission and plan for outer 2 are retained under `LOOP/lanes/arc1-gaussian-reliability-20261002/evidence/g5-n320-dev-prerun-v2/`. All 194 staged source pins matched. The Totoro run used Julia 1.10.0, four Julia threads, BLAS one, and the exact seed `688524427072088691`. It completed with `status=ok`, exit zero, and all five profile targets formed. End-to-end time was 447.46 seconds, with maximum RSS 9,554,532 KiB.

The compact hash-bound result is `evidence/g5-n320-dev-prerun-v2/outer2-verification.json` (SHA-256 `6e108a8301b1fcb7d2090f7abc1234b4f383f91213c7fcb9cad17253a8b436a4`). Result, JLS, Julia log, and profile-summary hashes are recorded in that file and independently checked by Astra. This is one development outcome, not a coverage estimate or G5 pass. G5 and all other open scientific gates remain unchanged. Full discussion: `docs/dev-log/after-task/2026-10-07-g5-n320-outer2-diagnostic.md`.
