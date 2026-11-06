# M0 map status and MV route correction

## New 2026-10-04 result

The declared eight-seed MV+PE screen passed on the current dirty Julia tree: 8/8 converged and all 11 predeclared printed bias/MCSE summaries passed. Astra independently reviewed it and classified it as a truth-started development screen only: every fit starts at the true G/P/R matrices, eight per-seed summary series are not retained for reconstruction, and eight seeds give weak bias discrimination. The corrected record, DGP, output, source fingerprints, and limitations are in `docs/dev-log/check-log.d/2026-10-04-mv-pe-8-seed-screen.md`. It is not ordinary-start recovery or calibration evidence. The next step is a complete paired-source and protocol freeze for an ordinary-start study; no broader study is admitted by this screen.

Date: 2026-10-04.

Prose assessment: style 2/10, medium confidence; this is a short internal handover correction. The opening phrase “This note supplements” accurately signals its scope, so no repair is needed. Science is checked for the limited status claim; facts are checked against the cited gate, recovery, and current-screen records; references are internal repository paths and verified. Self-reviewed on 2026-10-04 after reading those records; no independent prose review.

This note supplements `2026-10-04-m0-acceptance-map-audit.md` with the current MV+PE screen and sequencing evidence. The amended map has passed exact-hash Astra and Rose review for planning readiness; the accepted hashes and scope are recorded in the root gate ledger and after-task report.

At the time of the earlier status correction, `.unlazy/h2-nongpu-completion/GATES.md` left H0 unchecked while exact-hash review remained open; this note's older claim that H0 had passed was stale and is withdrawn. Astra and Rose have now passed the amended planning artifacts. H0 closes inventory, ownership, bounded route contracts, and first leaves; it does not pass any route's runtime, calibration, or capability gate. H1–H9 remain open.

The old M0-08 first leaf says to choose an unstructured-MV recovery cell and same-estimand comparator. That repeats already retained narrow evidence: `docs/dev-log/check-log.d/2026-06-29-v04-mv-scoped-finish.md` records a predeclared 48-seed V4-MV-REML recovery gate and a separate BLUPF90+ point-estimate comparator, scoped to its validation-scale contract. This does not close repeatability or MV+PE.

On 2026-10-04, four focused R tests were rerun against the current dirty paired worktrees. Their outputs, directly implicated source hashes, exit status, and scope limits are recorded in `docs/dev-log/check-log.d/2026-10-04-mv-parity-and-pe-route-tests.md`. The MV+PE route now has a current-tree contract check, one pinned-seed live fit, and one same-fixture `sommer` comparison. These are useful engineering checks, not seed-based recovery or calibration evidence.

The next M0-08 work is to freeze and independently review the complete paired source, tests, dependencies, and protocol for the bounded ordinary-start MV+PE recovery/comparator cell. The eight-seed screen has passed as recorded above; it does not authorize confirmation. Repeatability interval coverage and broader MV route gates remain open. Do not rerun the already-covered narrow V4-MV recovery cell absent a specific source-regression reason. Arc 1's G0–G8 gates remain separate.
