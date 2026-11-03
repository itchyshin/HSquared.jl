# Arc 1 package gate and G1 timeout, 2026-10-08

G7 passed against the Astra-reviewed v7 package freeze. Retained run:
`.unlazy/arc1-gaussian-reliability/evidence/package-checks/20261008T191106Z-5b32dd38dc/run.json`
with SHA-256 `691fc55fdf4f00d6fbd6fb27a93ae6bebc3ee3eae8e8ac43a09cc9d940c307d7`.
The reviewed freeze is `/private/tmp/h2-arc1-g7-reviewed-v7/package-freeze-reviewed-v7.json`
with SHA-256 `e4edf19419a4ebac16de6891f4195f9818038287ef80073f42bd99314380a8d8`.
The source-review receipt SHA-256 is
`5ea37dc629fab1fa92bc772e7a29e158f50118d11f36876415c63959fa6778ab`.

The Julia component passed in 853.351 seconds. The live R parity component passed in
2,687.662 seconds with 682 assertions and zero failures, errors or skips. R CMD check
passed in 3,142.304 seconds with `Status: OK`; testthat reported 4,606 passes, zero
failures, 26 warnings and 48 skips. The warnings and skips are retained in its output.
The Julia documentation build passed in 45.68 seconds. Total run status is `passed`.
Astra independently reviewed the exact retained receipt, and
`verify_retained_checks.py --gate G7` emitted `ARC1_G7_RETAINED_RECEIPT_VERIFIED`.

Julia summary accounting has two views. The runner retained 330 parsed summaries with
11,524 passes. The raw log has one additional 9/9 summary separated by diagnostic
output, for 331 summaries and 11,533 passes across the complete log. This difference
does not change the successful Julia component marker or retained verifier result.

The refreshed G1 oracle run did not pass. Receipt:
`.unlazy/arc1-gaussian-reliability/oracles/runs/20261008T211555Z-0d61003471b8/run.json`
with SHA-256 `14f67e4978db61d29a82c2588832809cfc94743bc6d83b1380420c84f7c8fd20`.
Eight Julia test files passed; the ninth, `arc1_simulation_executor`, was stopped at
204 seconds when the 480-second G1 gate-wide cap expired. Its test assertion result is
therefore unresolved. The eight earlier files had positive passing counts and zero
failures. The same executor completed in the G7 package suite in 196.8 seconds, which
supports a timeout-budget explanation but does not prove the stopped run would pass.

The G1 runner recorded log SHA-256
`1b9e9dd1294c56450a3447da76e299467d64b62874049c11a21b6ffe213a8fcf`; after process
group termination, child Julia output continued to modify the log. Its current SHA-256
is `b00f3970aef05ed8e6198e0648677ee0ce9d3ff42c9a54601d2160850f3822b0`. This failed
receipt is unsealed diagnostic evidence and does not establish G1 completion. Preserve it.

An independent read-only review recommends a versioned runner amendment that changes
only the G1 gate-wide cap from 480 to 900 seconds, leaves the per-file 300-second limit,
test selection and scientific inputs unchanged, and records the timeout-policy version
and effective cap in the new receipt. If the executor exceeds its full per-file limit,
diagnose that result before any further increase. The amendment and rerun remain
pending. G1 stays open; G6 is currently running under its exact reviewed source freeze.
