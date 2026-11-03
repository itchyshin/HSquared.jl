# Arc 1 G8 readiness reconciliation, 2026-10-10

## 1. Goal

Reconcile the current Arc 1 gate state against the approved non-GPU plan, retain current evidence, and correct stale readiness wording. The G8 gate remains open; this record documents current readiness.

## 2. Implemented

Corrected the stale GATES appendix that said G1, G6, and G7 were reopened. Archived the prior checkpoint headline verbatim and replaced it with a 2026-10-10 status pointer. This report is the current provisional G8 readiness reconciliation. No package source, public grammar, capability row, seed allocation, or gate checkbox changed.

## 3a. Decisions and Rejected Alternatives

Keep the 2026-10-09 crosswalk as a dated historical snapshot. A new 2026-10-10 record is the current G8 readiness view. Keep G8 open until final scientific review and G2-G5 study evidence pass.

## 4. Files Touched

- `.unlazy/arc1-gaussian-reliability/GATES.md`
- `LOOP/lanes/arc1-gaussian-reliability-20261002/checkpoint.md`
- `LOOP/lanes/arc1-gaussian-reliability-20261002/checkpoint-archive-20261010-before-g8-refresh.md`
- `docs/dev-log/after-task/2026-10-10-g8-readiness-reconciliation.md`
- `docs/dev-log/check-log.md`

## 5. Checks Run

- Gate checker reports 4 met and 5 open: G0, G1, G6, G7 met; G2-G5 and G8 open.
- Current scientific-gate checker suite passed 22/22. It exercises all-attempt denominators, interval formation, Wilson coverage rules, pilot/confirmation markers, and exact-zero diagnostics.
- Current seed manifest validation passed: 1,001 historical paths, 394 literals, 10,330 outer rows, 634,420 nested rows, and 644,750 unique keys/seeds.
- G5 map v26 received independent exact-source PASS; this verifies its eight pins, 46 mapped ranges, 58/58 full adversary suite, and 1/1 retained live fixture.
- Independent inference review found G3/G4 acceptance logic consistent with the frozen plan and no checker-only defect. Reviewed inputs included the pre-correction GATES snapshot SHA-256 `f5cfe5c399b7165eee228d5b0653fd441cd36979c0341d91ec7f0e51020160b0`, goal SHA-256 `39ec2b4251722c4d9017b8680d005a636eccf9a6cf84dbc16e8111a221446e0d`, aggregator SHA-256 `ec1bee2bdda71a5cfff4226ba2cc9e5e0a713f13726029e8131050a37a7f4600`, manifest validator SHA-256 `ad42f93728c12d3df17fd2be307561ec08b320d550271bdc6f456e408e99f64f`, and focused test SHA-256 `4d117e71e6ef9f42db2076c56f9595f3dc443e278c703cb4128562ae896ccb78`.
- `git diff --check` and the naturalness/style check passed for the updated prose.
- The after-task structure check passed. The completion check correctly withheld closeout because the Arc 1, automatic-rank, and parent non-GPU ledgers still have unmet gates.

## 6. Tests of the Tests

The existing checker tests include missing-cell and failed-eligibility holds, all-attempt rank denominators, interval formation counts, Wilson under/over-coverage examples, repeatability confirmation markers, and exact-zero boundary cells with no nominal coverage claim. No test implementation changed in this reconciliation.

## 7a. Issue Ledger

- Stale GATES statement contradicting current G1/G6/G7 receipts: corrected and replaced by a dated current-status note.
- G2 development tranche: exact current-source admission and independent review remain necessary; the separate 270-attempt approval is unresolved.
- G3 and G4: checker logic agrees with the frozen plan; fresh exact admissions, pilots, pilot qualification, independent pins, and confirmation evidence remain absent.
- G5: bounded inspector and checker engineering evidence is reviewed; interval formation, coverage, exact-zero diagnostics from model fits, and fitted-trace performance evidence remain absent.
- G8: final-source scientific review and complete plan-to-admitted-artifact reconciliation remain open until G2-G5 pass.

## 8. Consistency Audit

Current evidence supports G0, G1, G6, and G7 at their recorded scopes. The latest G7 receipt is `20261010T114934Z-f6b8b36958`, with 11,895 Julia assertions, 682 required-live R assertions, `R CMD check` Status OK, and local documentation passing. G5 v26 and the focused checker/manifest tests are engineering evidence only. The capability remains experimental and `public_covered_count` remains seven; GPU, release, publication, and capability-promotion work remains outside this arc.

| Plan item | Evidence in hand | Open requirement |
| --- | --- | --- |
| G0 protocol and execution boundary | Approved frozen protocol and scoped review | No additional G0 requirement; each study still needs a fresh admission |
| G1 exact FA likelihood and identities | Current retained objective/oracle checks pass | Does not prove ordinary-start fitting reliability on fresh data |
| G2 ordinary FA and reference reliability | Three consumed development attempts and reviewed engineering diagnostics | Freshly admitted 270-case development tranche, pilot qualification, reference audits, and confirmation evidence |
| G3 automatic K0/K1 selection | Aggregator rules and 22-test checker suite pass | Nine-cell pilot and confirmation, all-attempt denominators, and independent cell pins |
| G4 FA h² bootstrap intervals | Frozen bootstrap checker and endpoint-screen rules | Three-cell pilot, nested endpoint stability, then 400-per-cell confirmation if qualified |
| G5 five repeatability targets | v26 map review, raw-diagnostic checks, subprocess and synthetic sizing probes | Fitted-profile engineering performance plus the full interval formation/coverage and boundary studies |
| G6 R transport and failure handling | Required-live R receipt passes 682/682 | No further G6 work at this recorded scope |
| G7 package and documentation | Current reviewed freeze v26; Julia, R, R CMD check, docs pass | No further G7 work at this recorded scope |
| G8 final review and reconciliation | This provisional crosswalk and prior scoped reviews | Final-source review after G2-G5 pass, followed by exact artifact reconciliation |

G3 pilot qualification requires 30 attempts in each of nine cells, at least 29/30 eligible per cell, null K1 selection no greater than 6/30 in each null cell, strong N=320 K1 selection at least 24/30, and complete preselected/flagged reference audits. G3 confirmation uses 400 attempts per cell, eligibility Wilson 95% lower bound at least 0.90 in every cell, null K1 Wilson 95% upper bound at most 0.20 at all three N values, and strong N=320 K1 Wilson 95% lower bound at least 0.80. Every attempted dataset remains in the denominator.

G4 pilot uses 30 attempts in each of three N=160 cells. Each of four h² targets must form at least 29/30 and cover truth in at least 26/30 all attempts. All 20 pooled nested B=499/999 endpoint comparisons must exist; at least 18 must have maximum endpoint difference no greater than 0.02, and none may exceed 0.05. If qualified, confirmation uses 400 attempts per signal with B=499; every target must form at least 396/400 intervals and its 90% Wilson interval for all-attempt coverage must lie wholly inside [0.92, 0.98].

This review preceded the correction of the stale GATES chronology paragraph. That edit changed no G3/G4 row, threshold, or checker source; current GATES SHA-256 is `90a616ada95803e7abcf7df1be553a09dc4fe8895b292daef874058933cde127`.

The frozen plan SHA-256 is `1e5d09b59c7519d92850ecd50cab51e7ee7b45a5bd68cba90ec976c79d1c1103`. Inputs to this update included GATES SHA-256 `f5cfe5c399b7165eee228d5b0653fd441cd36979c0341d91ec7f0e51020160b0`, checkpoint SHA-256 `0c352b3e6702d3b7360a755c539a396f303f5735d037d657007ca10de69bd9eb`, and historical crosswalk SHA-256 `c5eab0b73f6ebb0f609178a8e9e7a91738f75f5c29c94fd3423d0ff2fccac4b3`.

## 9. What Did Not Go Smoothly

The repo-specific route helper has no manifest for this worktree path. The lane preflight script exists in the brain tools rather than the repository's `tools/` directory. The initial G5 full-suite command used Python 3.10, which lacks `tomllib`; it stopped at import. The exact current suite already has a reviewed Python 3.13 pass, so no failed assertion was hidden or replaced.

## 10. Known Residuals

No pilot or confirmation study has run. The 270-case G2 development tranche requires the pending separate approval after fresh source admission and review. G3, G4, and G5 pilots and confirmations each require exact per-cell source/protocol/environment/seed admissions and independent pins. Any campaign projected above three hours requires a measured pre-run and separate approval. The completion check remains blocked by unmet Arc 1, automatic-rank, and parent non-GPU gates. This report cannot close G8.

## 11. Team Learning

Use the dated current crosswalk as the active reconciliation and retain earlier crosswalks as historical snapshots. A passing receipt check proves only its pinned scope; stale narrative status must be reconciled whenever a gate is rerun.

Naturalness assessment: 7/10, medium confidence. Scientific claim gate: no calibration or coverage claim. Factual gate: statuses and thresholds checked against the current ledger, receipts, tests, and checkpoint. Reference gate: local evidence paths and hashes are cited in the linked records.

## 12. Cross-Product Coverage

Covers: the shared Julia/R Arc 1 readiness ledger and current evidence reconciliation.

does NOT cover: model behavior or fitting on new data, statistical reliability, public R grammar activation, capability promotion, GPU, release, or publication.
