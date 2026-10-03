# INCOMPLETE rolling progress report: Arc1 Gaussian reliability

Implementation update: the retained v1 G1/G6/G7 receipts subsequently passed through inspected Unlazy CHECK/EXPECT bindings, with seven parent-replayed verifier tests. The ledger snapshot is retained. The explicit v2 refinement decision now authorizes disjoint numerical, transport and method-identity implementation; v1 defaults and meaning remain unchanged. Reverification after the v2 source/protocol edits refused all three changed inventories. All nine current gates are unmet; the old passing snapshot remains retained. The earlier complete v1 package pass does not verify the pending v2 revision. See `profile-refinement-decision.md` and `checkpoint.md`.

Retained v1 update, 2026-10-03 UTC: source-pinned G1 passed 1,678 assertions across eight suites in 154.782 seconds. The combined G7 Julia, required-live R, R CMD check, and local documentation build passed in 977.84 seconds; the build rendered `1/validation-status.html`. The R check reported zero errors, warnings, and notes. Six authorized Totoro engineering timing cases completed in 308.84 seconds without supervisor failure; 28/30 target intervals formed, while residual variance (Ve) at N=160 and permanent-environment variance (Vpe) at N=320 remain unresolved in the near-zero-additive cases. Astra's independent numerical review found three genuine candidate-certificate deficits above the frozen 1e-8 limit. No policy changed. All G0–G8 remain open; no allocated study or campaign has been admitted, and the FA covariance-representation decision remains pending.

This interim implementation-versus-evidence record leaves programme acceptance open. It does not close a gate, authorize a study, or imply capability promotion. Recorded source for the retained combined package checks is Julia HEAD `dbba9c3a` and isolated R commit `37fdd90`; the refreshed G1 run checked the same source files under its separate oracle freeze. Earlier evidence paragraphs retain their dated snapshots; the latest checkpoint and update below govern active work.

## 1. Goal

Record the Arc1 programme's current implementation, exact evidence, unresolved defects, protected state, compute limits, and remaining decisions while G0–G8 remain open. The goal remains the separately approved Arc1 programme in `GOAL.md`; this file is its rolling progress report only.

## 2. Implemented

Independent v2 review is BLOCKED. Astra reproduced two erroneous numerical acceptances in 9.052 seconds without optimizer calls: superior final likelihood history and failed projected-coordinate finite-difference agreement. Luna is repairing these and related history/budget records. R missing-v2-identity validation now independently passes. The full synthetic cross-language test timed out; it remains unverified, with a replacement supervisor under review. No engineering replay or study has launched under v2.

The v2 transport slice is frozen with 49 focused R control assertions passing and one optional live check skipped. Julia integration and mandatory live v1/v2 parity are pending. Numerical continuation and study-record identity changes are still in focused testing. Astra is independently reviewing the frozen interface while waiting for the numerical freeze. The two-fixture replay plan is prepared but has not launched. All 40 protected Julia/R files match the baseline in `evidence/documentation-current-limits/protected-state-v2-inflight.json`.

Retained v1 source update: local commit `361f77cb` retains the profile repair accepted by Astra v9; the saved N80 engineering replay formed all five targets in 68.54 seconds with unchanged source/input hashes. Local commit `952c725b` retains the evidence harness accepted by Astra v5 in 270.10 seconds with 18 hashes unchanged. The refreshed G1 component passed 1,678 assertions across eight suites in 154.782 seconds. The combined G7 Julia suite, required-live R parity, R CMD check, and local docs build passed under the recorded external freeze; the docs build rendered `1/validation-status.html`. These package checks do not close programme gates. Six engineering timing cases completed on Totoro in 308.84 seconds; 28/30 targets formed and Ve at N=160 / Vpe at N=320 remain unresolved. Astra found three candidate-certificate deficits above 1e-8; no acceptance policy changed. All G0–G8 remain open, the factor-representation choice is pending, and no study or campaign is admitted.


The worktree contains experimental Julia FA objective, selector, profile, bootstrap, interfaces, simulation/reference, and evidence-checking components, plus paired R controls and uncertainty extraction. The interfaces are explicit opt-ins; defaults and `public_covered_count = 7` remain unchanged. The experimental guide states that general `cov = fa()` formula syntax is not opened and that reliability, calibration, and release claims are unsupported.

Evidence exists for bounded components and engineering examples, but it is version-specific. The initial S0 record was a plan with no implementation or execution evidence; later implementation and engineering receipts supersede that dated description, but do not satisfy acceptance. In particular:

- The objective leaf receipt records 70 assertions and `ARC1_OBJECTIVES_PASS` against its own recorded source hashes (`objective-core-receipt.json`). Those hashes predate current `src/arc1_fa.jl`, so that receipt remains historical subset evidence. The current-source G1 pass is recorded in `oracles/runs/20261003T042838Z-758ac22910f4/run.json`; its eight per-suite log counts sum to 1,678 with zero failures, errors, or broken tests.
- A parent replay recorded 672 combined objective, optimizer, profile, bootstrap, and interface assertions in 28.73 seconds and a 12-record profile fixture forming all five targets in 28.02 seconds. Its profile source/test hashes were `ab47c2ea7610ec56dd7b3d638408a6228f73cf00ed73bdc0272478921c34ddc9` and `50fc90b156aae9cebc325c2778acf76188f3a9ee49ae9f2b0a6f042e3b6a97c2`. Current profile hashes are below and differ from that replay. This establishes those recorded fixtures only.
- The previously accepted expanded reference source/test pair was `sim/arc1/reference.jl` SHA-256 `894e477df9365af289d6eca48bcd7d6597344366d4ebd2fe31770a14ef369fa8` and `test/arc1_simulation_reference.jl` SHA-256 `e461fae6bf116a962cf38b86740143e294aceec1647c1ab37b1717e133859dd1`. Astra accepted that bounded source repair, and the parent replayed 143 assertions in 11.80 seconds. One retained N=80 engineering comparison then completed 86 rows, with K0/K1 shortfalls `2.2737367544323206e-13` and `1.7053025658242404e-13`. It records one best-found engineering comparison; it says nothing about study-level reliability.
- A later 16-example engineering bootstrap scaling run formed 6/16 `B=19` intervals. There were 21 failed inner selectors among 304 fixed attempts. Eight failed selections had no eligible converged K1 start; thirteen retained a better finite K1 result that failed numerical acceptance. The evidence does not identify one cause for all failures. These are engineering inputs, not allocated study seeds, and do not estimate coverage.
- Astra's v4 review replayed 157 arithmetic assertions on v4-reviewed profile source SHA-256 `5768e810b067ac02764b888fc65acc4dc1fe985cb8194f80c177100870883c70` and test SHA-256 `276420266e7a9e9fa0ee9090951063203dc6e0dc90f1c1064ff50d92e9a5998d`. It reproduced four source defects. Later profile repairs were accepted in Astra v9; that review and the one-fixture N80 replay are current bounded engineering evidence, not calibration.
- The second Astra checker review used an 11-file frozen input set and ended blocked after 572.70 seconds. It reproduced reference-parameter/history checks, launcher identity rewriting, inspector trust of duplicated summaries, returned-failure/artifact inconsistency, and a stale-artifact pilot cache. Later harness v5 was accepted by Astra in 270.10 seconds with 18 hashes unchanged. The older v2 findings remain historical review evidence; they do not describe the accepted v5 harness or close G8.
- The fixed-coordinate high-precision pre-run regenerated three response vectors from retained outer fits and seeds, then compared Float64 objective/gradients with an independent 256-bit calculation. It completed in 8.53 seconds; these five source hashes matched before/after: `src/arc1_bootstrap.jl` `a95ebc3ecfc1ee5b1633bd78884b7f6094bf1f7b1efcf7bfbb86275610578825`, `src/arc1_fa.jl` `e890cdd7b771bf82c099ff2db94aa75393e44a61d9c361d2f7e54cc359e15895`, `src/fa_rank_selection.jl` `98680a96ca307f3c75e3ed02d5451976e5b238231fa1da1ffc0b469138db0320`, `sim/arc1/independent_dgp.jl` `f8161346578b6d7410facff6046f8f696d3577cf401287af7a79b63c164d5f3f`, and `src/multivariate.jl` `d425b0c6c75d97969bcad58af235c8662748a8d3265130d8ed468249cef35091`. The report records close objective agreement and gradient differences around `1e-17`, while selected Float64 perturbations were refused despite finite independent values. The original selector's consumed responses cannot be proven byte-identical because its inner design fingerprints were not retained. This supports the exact objective/gradient at those saved points and clarifies one representation boundary; it explains no broader share of selector failures and changes no admissibility rule.
- R commit `4c8457b` includes the experimental controls, help, and paired live tests. The focused dense-cap control replay passed 40 assertions with one optional transport skip and no warnings; an R source build completed in 14.19 seconds. A prior required-live uncertainty replay passed in 70.45 seconds on older source hashes. The later combined G7 receipt records required-live R parity, R CMD check, and a successful local HTML docs build. These package results are component evidence and do not close G6 or other programme gates.

No allocated development, pilot, or confirmation study seed has run. Engineering fits and timing checks did run, including six authorized engineering timing cases on Totoro completed in 308.84 seconds. Some target nuisance estimates remained unresolved. Those cases are not study outcomes. No campaign has been admitted. No capability promotion, public-count change, default activation, release, registry action, push, or deployment occurred.

## 3a. Decisions and Rejected Alternatives

- The omitted-policy legacy route remains the default; `optimizer_policy="arc1_v1"` is opt-in. Do not infer that an eligible fit or selected rank implies selection reliability.
- The profile LR value `3.841458820694124` is documented as a candidate nominal 95% cutoff, not established 95% coverage. Refusals, unresolved targets, and disconnected sets remain visible.
- The bootstrap uses fixed requested attempts and explicit seeds; failed attempts are not replaced. The B=19 engineering result documents failure and offers no basis to relax gates or choose replacement seeds.
- The confirmation allocation remains 400 per cell. Astra's design review shows the frozen 90% Wilson rule has only about 0.081816 probability of passing all nine cells for one target when true coverage is 0.95 in every cell. An alternative allocation is not adopted; confirmation remains held for an explicit pre-study decision and updated runtime estimate.
- A user decision is still pending on whether to use retained positive covariance factors with explicit matrix-precision diagnostics, or keep strict predicates on rounded Float64 matrices. No numerical acceptance change is authorized before that decision. See `covariance-representation-decision.md`.
- The former ignored N=80 `.jls` fixture was removed from the oracle runner's required source freeze after the test became portable. The reviewed freeze remains external; the runner cannot self-approve inputs.

## 4. Files Touched

The following are intended, non-generated Arc1 programme files found by comparing the Julia checkout with baseline `8fd54b7b170d7e989c9959a952ed80255bbdc9f0` and the isolated R checkout with baseline `c9b15af350e0c5ca62e5e698716b66101251bcdc`. Protected configuration files, Python bytecode caches, and transient outputs are excluded. Evidence artifacts themselves remain under `.unlazy/arc1-gaussian-reliability/evidence/`; run receipts and manifests enumerate their source/result hashes and retained files. This report is added to the list.

Julia checkout, design, and lane records:

- `README.md`
- `docs/design/arc1-experimental-usage.md`
- `docs/design/arc1-gaussian-reliability-20261002.md`
- `docs/design/auto-fa-rank-experimental-usage.md`
- `docs/design/capability-status.md`
- `docs/design/validation-debt-register.md`
- `LOOP/lanes/arc1-gaussian-reliability-20261002/GOAL.md`
- `LOOP/lanes/arc1-gaussian-reliability-20261002/arcs.md`
- `LOOP/lanes/arc1-gaussian-reliability-20261002/after-task-progress.md`
- `LOOP/lanes/arc1-gaussian-reliability-20261002/retained-package-checks.md`
- `LOOP/lanes/arc1-gaussian-reliability-20261002/bootstrap-source-review.md`
- `LOOP/lanes/arc1-gaussian-reliability-20261002/checker-foundation-receipt.md`
- `LOOP/lanes/arc1-gaussian-reliability-20261002/checkpoint.md`
- `LOOP/lanes/arc1-gaussian-reliability-20261002/compute-prerun.md`
- `LOOP/lanes/arc1-gaussian-reliability-20261002/covariance-representation-decision.md`
- `LOOP/lanes/arc1-gaussian-reliability-20261002/coverage-gate-design-review.md`
- `LOOP/lanes/arc1-gaussian-reliability-20261002/documentation-gap-audit.md`
- `LOOP/lanes/arc1-gaussian-reliability-20261002/fa-policy-review.md`
- `LOOP/lanes/arc1-gaussian-reliability-20261002/g1-fa-objective-receipt.md`
- `LOOP/lanes/arc1-gaussian-reliability-20261002/harness-next-leaf.md`
- `LOOP/lanes/arc1-gaussian-reliability-20261002/interface-live-review.md`
- `LOOP/lanes/arc1-gaussian-reliability-20261002/objective-core-receipt.json`
- `LOOP/lanes/arc1-gaussian-reliability-20261002/profile-candidate-review.md`
- `LOOP/lanes/arc1-gaussian-reliability-20261002/profile-wrapper-timeout.txt`
- `LOOP/lanes/arc1-gaussian-reliability-20261002/r-bridge-integration-notes.md`
- `LOOP/lanes/arc1-gaussian-reliability-20261002/reference-executor-next-leaf.md`
- `LOOP/lanes/arc1-gaussian-reliability-20261002/reference-source-review.md`
- `LOOP/lanes/arc1-gaussian-reliability-20261002/simulation-source-review.md`
- `LOOP/lanes/arc1-gaussian-reliability-20261002/ultra-plan.md`
- `LOOP/lanes/arc1-gaussian-reliability-20261002/uncertainty-integration-contract.md`

Julia implementation and tests:

- `sim/arc1/execution_identity.jl`
- `sim/arc1/execute_attempt.jl`
- `sim/arc1/engine_io.jl`
- `sim/arc1/independent_dgp.jl`
- `sim/arc1/inspect_artifacts.jl`
- `sim/arc1/manifest-revisions.md`
- `sim/arc1/manifests/arc1_outer_seeds.csv`
- `sim/arc1/manifests/arc1_seed_manifest.json`
- `sim/arc1/reference.jl`
- `sim/arc1/run_cell.py`
- `sim/arc1/runner.py`
- `src/HSquared.jl`
- `src/arc1_bootstrap.jl`
- `src/arc1_fa.jl`
- `src/arc1_interfaces.jl`
- `src/arc1_profiles.jl`
- `src/fa_rank_selection.jl`
- `src/multivariate.jl`
- `test/arc1_bootstrap.jl`
- `test/arc1_exact_objectives.jl`
- `test/arc1_interfaces.jl`
- `test/arc1_optimizer_contracts.jl`
- `test/arc1_profiles.jl`
- `test/arc1_simulation_dgp.jl`
- `test/arc1_simulation_executor.jl`
- `test/arc1_simulation_identity.jl`
- `test/arc1_simulation_reference.jl`
- `test/runtests.jl`
- `test/test_arc1_executor.py`
- `test/test_arc1_receipt_adversaries.py`
- `test/test_arc1_scientific_gates.py`
- `tools/arc1_gate_aggregate.py`
- `tools/arc1_manifest.py`
- `tools/arc1_oracles.py` (canonical copy of the reviewed synthetic-tested runner; added in this report continuation)
- `tools/arc1_receipt_check.py`
- `tools/arc1_package_checks.py`

Isolated R checkout (`/private/tmp/hsquared-auto-fa-r-20261001`, HEAD `4c8457bc7690e22087fe6985017d5bb0bec39afb`):

- `NAMESPACE`
- `R/arc1-uncertainty.R`
- `R/extractors.R`
- `R/fa-rank-selection.R`
- `R/hs_control.R`
- `R/hsquared.R`
- `R/julia-bridge.R`
- `man/arc1_uncertainty.Rd`
- `man/hs_control.Rd`
- `tests/testthat/test-arc1-controls.R`
- `tests/testthat/test-arc1-live-parity.R`
- `tests/testthat/test-arc1-uncertainty-controls.R`
- `tests/testthat/test-arc1-uncertainty-live.R`

The original Dropbox R checkout remains protected and was not edited. `.claude/settings.json` and `.cursor/hooks.json` remain pre-existing protected dirty paths; do not include them as Arc1 changes. The retained state check found zero mismatches across the two protected configuration files in this Julia worktree and 38 dirty tracked files in the original R checkout.

## 5. Checks Run

This reporting pass verified the latest retained package receipts and the eight G1 per-suite counts. It ran no fit, campaign, project test suite, or remote compute and made no commit. The six Totoro engineering timing cases were run by the parent and are recorded in the latest update.

The absolute-path prose check, `python3 /Users/z3437171/shinichi-brain/tools/slop_check.py /Users/z3437171/.codex/worktrees/b9ae/HSquared.jl/LOOP/lanes/arc1-gaussian-reliability-20261002/after-task-progress.md`, returned zero findings. The structural command `Rscript /Users/z3437171/shinichi-brain/tools/check-after-task.R /Users/z3437171/.codex/worktrees/b9ae/HSquared.jl/LOOP/lanes/arc1-gaussian-reliability-20261002/after-task-progress.md` passed the report-structure check, then exited 1 in its acceptance-ledger phase because Arc1 G0–G8 are open and the scan also encountered a separate older auto-FA ledger. Its output is retained at `/private/tmp/arc1-after-task-progress-check.log`. The historical eight-gate completion for that older programme remains supported by its recorded source receipts; the scan result does not change its status. The structural pass does not complete this rolling report's programme.

Recorded checks reviewed (not rerun here):

- `parent-integrated-components/receipt.json`: exit 0, 672 combined assertions, 28.73 seconds, with its exact source hashes. Its profile hashes differ from current profile source/test hashes.
- `parent-profile-ab47/receipt.json`: exit 0, 29.89 seconds; checkpoint identifies a 12-record fixture on which all five profile targets formed. Its recorded implementation source predates the current blocked profile candidate.
- `centering-astra-review-v4/receipt.json` and `review.md`: exit 0 after 533.03 seconds with its frozen profile source and test hashes unchanged. Verdict: four remaining profile-history/adapter defects; no fit ran.
- `parent-reference-repaired/receipt.json`: exit 0, 143 assertions in 11.80 seconds at its recorded accepted reference/test hashes. Its paired engineering reference run is one N=80 dataset only.
- `parent-live-uncertainty-tuples/receipt.json`: exit 0 in 70.45 seconds with unchanged then-current hashes. The R uncertainty source hash in that receipt is `5bfce9b0555c3c3f6c1fba6cf64724b34b9fdfd81261656d3d8b1a80b193d454`; current R source is different. It is not final-source G6 evidence.
- `/private/tmp/arc1-r-controls-dense-cap.log` and R commit `4c8457b`: 40 focused assertions, one optional transport skip, no warning/failure; R build succeeded in 14.189 seconds. This is historical subset evidence. Current required-live G6 and R CMD check passed in replay `20261003T031916Z-af170e605f`; see its retained `run.json` and `r-check-result.json`.
- `totoro-fa-scaling` and `bootstrap-scaling-diagnosis` receipts/logs: 16 B=19 engineering examples, six intervals formed, 21/304 inner selectors failed; detailed failure counts and the unqualified runtime projection are in `compute-prerun.md` and its retained receipts.
- `scientific-checkers-astra-review-v2/receipt.json` and `review.md`: exit 0 as a read-only review process, but verdict blocked on five checker/launcher/artifact defects. Its reviewed source set differs from current files; no studies or admissions were created.
- `parent-oracle-selftests-v2/receipt.json`: synthetic self-tests passed on an earlier runner version at SHA-256 `980d6b1bf6dd6197ac9a146f77d02c5c44dd2d1edd64caf8fab6bd88af6723ae`.
- `parent-oracle-selftests-v3/receipt.json`: the runner with the removed N80 artifact dependency passed synthetic checks in 6.69 seconds at SHA-256 `87f449fd7b7fa68b41cdf1e5a05a228af86011c745c3efedf00a568ba4443067`; source hashes matched before/after. This validates only the runner.
- The canonical copy `tools/arc1_oracles.py` changes only the Julia-root and run-output-root expressions from that retained runner. `python3 -m py_compile tools/arc1_oracles.py` and `python3 tools/arc1_oracles.py --self-test` passed with synthetic R pass/failure/skip/error/empty cases and Julia pass/failure/skip/empty cases. Canonical copy SHA-256: `f82316db2c52b69e232b138e8df2a55807f0a4ef8df2b8959d67b46f37f319c2`. These are runner-only checks; current-source G1/G6 results are in the named run receipts above.
- Current-source G1 receipt `oracles/runs/20261003T042838Z-758ac22910f4/run.json` passed in 154.782 seconds. Its eight suite logs report 70, 217, 951, 154, 38, 35, 148, and 65 passes; an explicit assertion verified the sum is 1,678 and failures/errors/broken counts are all zero. The combined G7 receipt `evidence/package-checks/20261003T041019Z-c04d832d1f/run.json` passed Julia in 522.951 seconds, required-live R in 77.704 seconds, R CMD check in 251.202 seconds, and local documentation rendering in 30.751 seconds (total 977.84 seconds). R CMD check reported zero errors, warnings, and notes. The rendered validation page is `1/validation-status.html`. Both receipts use reviewed source freezes; neither closes programme gates.
- R-only current-source replay `20261003T031916Z-af170e605f`: required-live parity passed 219 assertions in 79.435 seconds and R CMD check returned `Status: OK` in 260.101 seconds, with zero package errors, warnings, or notes and unchanged source hashes. The trailing `sysctl` and Quarto version-probe warning belongs to the command log after `Status: OK`, not to R CMD check.
- Earlier docs-only timeout and DNS failures remain as historical failed attempts. The later combined G7 receipt records a successful local HTML documentation build under the pinned frontend tree; see `retained-package-checks.md` for exact receipts and the rendered artifact. No deployment occurred.
- The six authorized Totoro engineering timing cases completed in 308.84 seconds without supervisor failure. Some target nuisance estimates were unresolved. These are engineering diagnostics, not allocated study outcomes.
- `evidence/documentation-current-limits/protected-state.json`: a parent check at `2026-10-02T23:04:59Z` matched both protected worktree configuration hashes and all 38 original dirty R file hashes.

The Arc1 ledger `.unlazy/arc1-gaussian-reliability/GATES.md` still marks every gate G0–G8 unchecked. The G1 component and all G7 package-check components passed, but these do not establish scientific acceptance. The structural validator also reported its acceptance phase UNMET because Arc1 remains open and it scans a separate older auto-FA ledger. That older programme's original eight-gate completion remains supported at its recorded historical sources; the scan result does not revise that outcome. No old programme file was changed.

## 6. Tests of the Tests

There is meaningful adversarial evidence for bounded components. Astra's profile v4 controlled cases exercised terminal-only history, returned certificate history, inactive/missing scalar history flags, and invalid scalar coordinates; they reproduced four live defects despite the preceding 157 arithmetic assertions passing. Later profile repairs passed the independent Astra v9 review and one retained N=80 engineering replay formed all five targets. Those bounded checks address the reviewed defects on their frozen inputs; they do not establish profile coverage or population reliability.

The checker review replayed five source-traced adversaries (altered encoded reference parameters, rewritten returned identities, inconsistent artifact summaries, legitimate returned failures rejected by the checker, and stale artifact reuse). Later harness v5 passed Astra's bounded independent review with 18 hashes unchanged. Earlier parent receipts include synthetic fresh-process transport and receipt tests. These checks support the reviewed harness version only; the complete scientific admission pipeline and G8 remain open.

## 7a. Issue Ledger

- Profile component: bounded source review and one-fixture engineering replay passed. Astra v9 accepted the profile repair, and the saved N=80 replay formed all five targets in 68.54 seconds. This does not close profile coverage, G5, or any study gate.
- Evidence harness: bounded Astra v5 review passed with 18 hashes unchanged. G8 remains open because the complete evidence-admission pipeline and scientific review are not complete.
- Bootstrap numerical behavior: OPEN. Six of sixteen B=19 intervals formed; 21 of 304 inner selectors failed. Inner failures remain in the results; none were replaced. The current source is awaiting study-admission review.
- Covariance representation decision: USER INPUT PENDING. No source-level numerical relaxation is authorized before the user's explicit choice in `covariance-representation-decision.md`.
- Confirmation allocation/admission: OPEN. Frozen allocation remains 400; the 95%-true-coverage operating-characteristic review recommends holding confirmation pending an explicit allocation decision and measured runtime.
- R/Julia integration: OPEN. Current-source required-live G6 passed 219 assertions in the Julia component receipt and 219 assertions in the R-only replay. The independent full R check passed. These component and package checks do not by themselves close G6 or the remaining gates.
- Isolated R help recovery: LIMITATION. The exact pre-edit `man/hs_control.Rd` bytes were not recovered. Captured Git status showed unrelated tracked Rd pages clean; optimizer-policy paragraphs and newly supported controls were semantically compared. Current help is treated as a reviewed update, not byte-for-byte restoration. Provenance: `evidence/rd-recovery/recovery-provenance.md`.
- Study / promotion / release: NOT ADMITTED. No allocated study ran; no gate or public capability was promoted.

## 8. Consistency Audit

The implementation, tests, R help, experimental usage guide, capability row, debt row, and gate ledger were compared for default behavior, explicit method names, limits, uncertainty interpretation, and status. The refreshed G1 and combined G7 package receipts now pass on their reviewed source freezes; see `retained-package-checks.md` for counts, hashes, and scope. The guide distinguishes the candidate nominal 95% profile cutoff from actual coverage; it says three bootstrap seeds only illustrate API shape, even though `ceil(0.99*3)=3` can permit interval formation. Its bootstrap and profile examples expose the opt-in controls and current refusal conditions. The README cross-links the experimental route without claiming promotion.

Rose claim-versus-evidence read-only verdict on the parent-updated Arc1 rows in `capability-status.md`, `validation-debt-register.md`, and `arc1-experimental-usage.md`: **CLEAR for the claims currently made.** The rows label the 672 assertions and formed-profile fixture as engineering evidence; include the 6/16 B=19 formation and 21/304 selector failures; explicitly say no Arc1 study/campaign has run; keep all gates open and covered count seven; and distinguish bounded Astra v9 profile acceptance and the N=80 fixture from study-level evidence. Harness v5 also has bounded acceptance. The experimental guide limits each pass to its recorded source version. No edits to these three files were made in this audit.

The original S0 planning statement is preserved as historical, dated context; it is not presented as the current implementation state. Current executable and scientific status is reported from the later receipts and latest reviews. Retained engineering fits are clearly separated from allocated studies. Protected configuration files, isolated/original R boundaries, and the exact help-recovery caveat were checked.

## 9. What Did Not Go Smoothly

The profile path passed substantial controlled checks before independent reviewers found adapter/history failures, including a false-acceptance route. The evidence pipeline similarly passed positive synthetic suites before source review found mutation paths and a stale cache boundary. The R documentation generation episode also caused unrelated help-page restoration work; exact historical bytes remain unavailable, so the report keeps that limitation explicit.

The project `route.py` lookup found no manifest for this worktree's absolute path. The hub `closeout.py new` helper resolved a relative destination under the brain repository rather than this project, so I generated the report template using an absolute target. The structural validator checks report form; the hub-wide evidence gate remains separate from project acceptance.

## 10. Known Residuals

- All original gates G0–G8 remain open. The approved programme is not complete.
- No allocated development, pilot, confirmation, or calibration study has run. Engineering-only fits, B=19 runs, and a single expanded-reference comparison do not change that statement.
- Astra v9 accepted the profile repair, and the saved N=80 engineering replay formed all five targets. The reference remains a one-fixture comparison and supplies no study-level reliability evidence.
- Harness v5 passed bounded independent review. The full evidence-admission pathway and G8 remain open; no scientific studies or campaign admissions are recorded.
- Bootstrap formation was poor in the 16-example engineering batch; population formation and coverage are unknown. Rank-selection reliability is unknown.
- Current-source G6 live checks passed in the combined G7 package run, and the R CMD check and local docs build passed under the same reviewed package freeze. Any future source changes require the applicable parity replay; all Arc1 acceptance gates remain open.
- No fully qualified campaign timing estimate exists. An earlier conditional projection was 84.87 hours at four fully occupied Totoro workers from one B=19 rate, excluding overhead and slower cells; a later 16-worker estimate was 16.08 elapsed hours before overhead. These are not approved campaign schedules. Any campaign over three hours requires the prescribed estimate, pre-run, and approval.
- User covariance-representation and pre-study confirmation-allocation decisions remain pending. No numerical criteria, seeds, or sample sizes may be changed silently.
- `public_covered_count` remains seven. No reliability, calibration, production-readiness, broad formula-support, release, or promotion claim is supported.

## 11. Team Learning

Actual execution used `gpt-6-astra` at high effort for scientific decisions and independent source challenges, and `gpt-6-luna` for implementation and testing. The current Luna reference/profile worker runs at high effort; the simulation/checker and documentation workers run at medium effort. These are real delegated workers. The parent coordinates file ownership, checks returned evidence and creates local checkpoints. Rose is the claim-versus-evidence lens applied by the documentation worker, not a separate running agent. Once the native agent limit was reached, bounded Astra reviews used the inspected CLI launcher. No more than three children, including those CLI reviews, run at once.

Totoro supplied the retained CPU engineering measurements through its existing SSH socket. The scaling check compared four with sixteen workers, each using four Julia threads and one BLAS thread. The six authorized engineering timing cases completed in 308.84 seconds without supervisor failure; some target nuisance estimates remained unresolved. Local arithmetic and controlled tests use the thread limits recorded in their receipts. No GPU or allocated scientific campaign ran.

Memory receipt: for this report audit, I used the repository instructions, checkpoint, gate ledger, source reviews, retained receipts, and the active lane lease as technical sources. `route.py` returned no LOAD-FIRST manifest for this absolute worktree path; that lookup describes this report pass. Golden Set: not run; this report pass did not repair a known-mistake class. No memory files were edited because this rolling report owns only the assigned lane file.

For the next worker, a component pass is not a contract pass. Carry exact source hashes into every review; test result adapters and history aggregation at boundaries; validate the retained artifact against its underlying result; and keep engineering examples out of pilot denominators. Resume from the current checkpoint and named blocked reviews rather than treating older passing receipts as current acceptance.

## 12. Cross-Product Coverage

Bounded implementation or recorded checks exist for the explicit `arc1_v1` selector in Julia and paired R controls, plus Julia profile/bootstrap routes with R-facing controls and extractors. Refreshed G1 and combined G7 package checks passed; the Arc1 acceptance ledger remains open and scientific claims remain unsupported.

This Arc1 route does NOT cover the ordinary default, general factor-analytic `cov = fa()` formula syntax, all covariance representations, inheritance systems, non-Gaussian families, or observation layouts. It also does not establish selection reliability across populations, calibrated interval coverage, confirmed study performance, production-scale readiness, or capability promotion. G6 paired R/Julia parity, G5 interval calibration, G3 selection reliability, and the remaining G0–G8 acceptance conditions remain open.

### Historical appendix: superseded status snapshot, 2026-10-03 00:06 UTC

The following paragraphs are retained verbatim from the prior report state. They record what was known at that time and are not the current status above.

> This interim implementation-versus-evidence record leaves programme acceptance open. It does not close a gate, release a source freeze, authorize a study, or imply capability promotion. Current state is anchored to Julia HEAD `0e29fd02` and isolated R HEAD `4c8457bc7690e22087fe6985017d5bb0bec39afb`, checked 2026-10-03 UTC. Earlier evidence paragraphs retain their dated source snapshots; the latest checkpoint and the update below govern active work.

> Update at 2026-10-03 00:06 UTC: the observation-only FA diagnostics passed 217 parent assertions in 11.87 seconds with unchanged hashes and are retained in local commit `0e29fd02`. The v6 profile source (`4a3f7e7f…`, tests `3c7ef153…`) passed 881 worker assertions in 42.0 seconds and failed Astra review v6 on a native failed-start policy regression plus four neighboring adapter defects. Luna owns repairs; no current-source full profile fit has run. The third checker review completed in 622.64 seconds with all 18 hashes unchanged: launcher identities, returned failures and cache removal were accepted, while native reference transport, start derivation, maximum provenance and retained seed/raw-result bindings remain blocked. Luna owns those repairs. The first G7 runner also needs a scratch docs environment pinned to the current source and complete transitive input freezing before real checks.

> The objective leaf receipt records 70 assertions and `ARC1_OBJECTIVES_PASS` against its own recorded source hashes (`objective-core-receipt.json`). Those hashes predate current `src/arc1_fa.jl`; the receipt is historical component evidence. Current-source G1 evidence is still absent.

> R commit `4c8457b` includes the experimental controls, help, and paired live tests. The focused dense-cap control replay passed 40 assertions with one optional transport skip and no warnings; an R source build completed in 14.19 seconds. A prior required-live uncertainty replay passed in 70.45 seconds on its recorded older Julia/R source hashes. Final-source live parity and full package checks remain unverified.

> The canonical copy `tools/arc1_oracles.py` changes only the Julia-root and run-output-root expressions from that retained runner. `python3 -m py_compile tools/arc1_oracles.py` and `python3 tools/arc1_oracles.py --self-test` passed with synthetic R pass/failure/skip/error/empty cases and Julia pass/failure/skip/empty cases. Canonical copy SHA-256: `f82316db2c52b69e232b138e8df2a55807f0a4ef8df2b8959d67b46f37f319c2`. No actual G1/G6 project tests or fits were run.

> - Profile history and adapter acceptance: OPEN. The v4-reviewed source snapshot is `5768e810…` / test `27642026…`; Astra v4 found four reproducible defects. N=80 arithmetic resolves candidate 24 and still refuses candidate 7 at centered spread `1.3393616882240167e-8`; thresholds remain unchanged.
> - Evidence admission and checker: OPEN. Current source and tests require a new complete transitive freeze and review. Astra v2 found five blockers, including reference parameter/history checks, launcher identity rewriting, summary/result mismatch, legitimate failed-result semantics, and stale cache use.
> - R/Julia integration: OPEN. Controls/build evidence exists; the last live pass predates current R/Julia source, and complete G6 replay remains owed.

> Rose claim-versus-evidence read-only verdict on the parent-updated Arc1 rows in `capability-status.md`, `validation-debt-register.md`, and `arc1-experimental-usage.md`: **CLEAR for the claims currently made.** The rows label the 672 assertions and formed-profile fixture as engineering evidence; include the 6/16 B=19 formation and 21/304 selector failures; explicitly say no Arc1 study/campaign has run; keep all gates open and covered count seven; and say current-source profile/checker reviews are blocked or still required. The experimental guide separately limits prior passes to their recorded source versions. No edits to these three files were made in this audit.

> - Astra v6 found a native failed-start refusal-policy regression and four neighboring adapter defects. Luna owns repairs; full wrapper and retained N=80 fit replays remain pending.
> - The current reference/checker/executor path still needs fresh independent review after repairs and a frozen transitive source set. Current checker source is not accepted for study admission.
> - Paired R/Julia live checks and failure/interruption behavior must be rerun on the final frozen sources; the prior 70.45-second live pass is source-specific and stale relative to current code.

> Totoro supplied the retained CPU engineering measurements through its existing SSH socket. The scaling check compared four with sixteen workers, each using four Julia threads and one BLAS thread. Those processes have ended. Local arithmetic and controlled tests use the thread limits recorded in their receipts. No GPU or allocated scientific campaign ran.
