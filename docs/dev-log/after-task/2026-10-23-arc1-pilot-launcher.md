## 1. Goal

Build and review a dry-run-first, source-bound launcher for the eight remaining FA-rank pilot cells. No fits were authorized or started in this slice.

## 2. Implemented

- Added `sim/arc1/run_pilot_cells.py`. It accepts only the eight cells in the 3 × 3 FA-rank pilot design after excluding the already-consumed N80/null cell. It requires eight per-cell admissions, each with 30 unique UInt64 seeds, Julia 1.10.0, and one Julia thread plus one BLAS thread.
- The default command validates and saves a plan. Execution requires a separate owner authorization bound to the exact eight-cell plan and source/output roots. The pre-run receipt must have the declared schema, contain one successful timed attempt per cell, match the plan and batch identities, and support a recomputed runtime estimate. Each receipt timing is checked against a hash-pinned launcher parent result, while the runner wrapper and Julia inner durations are independently checked as finite and positive. The launcher wall time is used for campaign sizing; nested timers are not incorrectly required to be identical. Hash-only, changed-result, inconsistent-parent-time, or failed-attempt receipts are rejected.
- Results are restricted to temporary/evidence roots and rejected when the target is inside a Git checkout. The execution check revalidates the plan shape, per-cell seed partitions, launcher identity, and output layout before honoring authorization.
- The launcher reuses `run_cell.py` for one outer at a time, runs at most eight cell workers concurrently, and refuses to overwrite prior attempt markers. Existing result and start records are checked against the admitted seed and admission hash. An unresolved retained result, started marker, retained runner failure, or new nonzero child exit stops that cell at the first affected outer; later outers cannot launch before reconciliation.
- A recorded execution batch reports its attempt-terminal state separately and always labels the scientific gate `not_evaluated`.
- Each child wrapper runs in its own process group. Timeouts and launcher interruptions terminate the wrapper and its Julia descendants; a failed launcher attempt holds later outers instead of continuing automatically.
- The launcher test file now contains 24 focused contract tests, including external source-root module loading, receipt-to-runner and launcher-parent binding, nested-timer separation, stale launcher/plan identity rejection, source-verified paired resume, fail-closed resume behavior, planned-versus-terminal attempt counts, process-tree timeout and signal-cancellation cleanup, rejection of a zero-exit child with no valid retained runner result, and rejection of single-attempt review admissions in a full batch. No fit output was created.

## 3a. Decisions and Rejected Alternatives

- Reused the existing single-attempt runner and durable attempt store instead of introducing another Julia execution path.
- Made planning the default and required explicit, separately retained authorization for execution. No fits were started because the approval in this turn covered launcher construction and review only.
- Bound each plan to its explicitly selected source root. The launcher verifies that the runner and manifest modules were loaded from that root before accepting admissions.
- Assumption: the eight remaining cells are the nine combinations of N = 80, 160, 320 and null, weak, strong, less the consumed N80/null cell. If the retained ledger says otherwise, revise the cell inventory before making admissions.

## 4. Files Touched

- `sim/arc1/run_pilot_cells.py` (created)
- `test/test_arc1_pilot_cells.py` (created)
- `docs/dev-log/check-log.md` (appended a launcher evidence entry)
- `docs/dev-log/after-task/2026-10-23-arc1-pilot-launcher.md` (created)

Existing dirty files in the checkout were preserved. No protected recovery files or Dropbox checkouts were edited. No commit or push was made.

## 5. Checks Run

- `bash /Users/z3437171/shinichi-brain/tools/lane_preflight.sh ... --file sim/arc1/run_pilot_cells.py --file test/test_arc1_pilot_cells.py`: both paths were new and unowned; other active lanes were reported and left untouched.
- `python3 -B -m unittest discover -s test -p 'test_arc1_pilot_cells.py'`: 9 tests passed.
- Follow-up red/green tests: hash-only and runner-result-mismatch receipts were accepted before their guard changes, then rejected. The timeout/process-tree test confirmed that the grandchild stopped after its wrapper timed out. At that stage, the focused suite reported 13 passing tests.
- An independent read-only review found that the first receipt implementation equated parent launcher time with nested runner time. Corrected the contract to hash-bind both timing records separately and added a regression where runner time is 8 seconds, wrapper time 9 seconds, and launcher parent time 10 seconds. The 10-second parent measurement determines the estimate. Further independent review findings were resolved: persisted launcher results now carry plan, batch, and launcher hashes, and receipt validation checks all three; unresolved retained starts/errors and nonzero child exits stop the cell before a later outer. Regression tests cover each branch. Retained success is accepted only when the launcher result matches the current plan, batch, and launcher hashes and its runner result hash, source identity, seed, admission, status, and timings all verify. Runner-only files require reconciliation. Partial cells report planned and terminal counts and cannot be labeled complete. The final review also required retained launcher durations to be finite and positive; resume now enforces this, with a regression proving a zero-duration otherwise-valid record is held. That reviewer found no further blocker in the then-current source. The reviewer inspected the current source and tests but did not independently execute them; the 18/18 test result was from this lane at that stage.
- Follow-up suite: `python3 -B -m unittest discover -s test -p 'test_arc1_pilot_cells.py' -v`: 20 tests passed, including distinct nested timers, stale launcher identity rejection, source-verified paired resume, identity-less runner rejection, fail-closed resume paths, partial-cell accounting, nonzero-child stopping, zero-exit/missing-result rejection, and synthetic process-group cleanup after SIGTERM cancellation. CLI `--help` and `git diff --check` passed.
- Latest regression run: `PYTHONDONTWRITEBYTECODE=1 python3 -B -m unittest discover -s test -p 'test_arc1_pilot_cells.py' -v`: 24 tests passed. `git diff --check` and `bash tools/preamble_cap.sh` passed. An independent read-only reviewer confirmed the single-attempt-scope mismatch is rejected before the full-batch plan is accepted; no adjacent contract regression was found.
- Retained recovery-tree verification: `PYTHONDONTWRITEBYTECODE=1 python3 -B -m unittest discover -s /private/tmp/HSquared.jl-arc1-recovery-20261015/test -p 'test_arc1_pilot_cells.py' -v`: 27 tests passed. Its launcher/test SHA-256 values are `15a46078fdc1d5db6f868079373642e4a3526a1061de0668ed7af428bc37cc6b` and `2e706f236f91025a5fbfccade56d62b852b713182685c08a1707e17f4dc196ce`; the current worktree copies hash to `638fe9c611e204038d5ca885e149ab696f81e2bb2258d9b0adc38758fe4c0cc7` and `271211b4b262a31a3213bdf5a950efc040f7f54fe6e2cc13c385f3a93a8b8b5d`. These are separate source versions; the test results are not interchangeable source-freeze evidence. The tests ran no fits, seeds, launcher plans, or campaigns.
- Python AST parsing, CLI `--help`, and whitespace checks: passed.
- An earlier report revision passed `check-after-task.R`. The v2 structure check could not be rerun because `Rscript` is unavailable; an earlier acceptance-ledger check warned UNKNOWN because Node or `gate-check` was unavailable.
- `slop_check.py` on the absolute report path: 0 findings; 0 em dashes.
- Source identity check: `sim/arc1/execute_attempt.jl` in this checkout hashes to `753a7aabede49031e2526a97865aafc6f8802fde813fce9ae10437e73573e4f3`; the retained recovery source hashes to `9395f338015ceb8db6ea622d33df2bafd788c655e3a2a54c5fc38ea00be8f971`. They differ, so this checkout is not interchangeable with the retained source.
- `graft build` could not run because the Graft CLI is unavailable in this environment.
- The prescribed `closeout.py new` resolved its output through a symlink to the Dropbox checkout and was blocked by filesystem permissions. The relative-path style-check call made the same mistake and was rerun with an absolute worktree path. This report was written in the authorized worktree. The source checkout state was not changed by the failed write.
- No Julia fit, simulation, campaign, R test, package test, or evidence-gate run was performed.

## 6. Tests of the Tests

A deliberate mutation that removed the Julia and BLAS thread flags from the command builder caused the thread-pinning test to fail, confirming that the test detects that regression. Hash-only and runner-result mismatch tests failed before implementation and passed afterward. The zero-exit/missing-runner-result regression also failed before its guard and passed afterward. The new single-attempt-scope regression supplies a valid marker in both embedded and retained admission data and asserts the targeted refusal; the independent reviewer confirmed it would catch the previous validator, which accepted that scope. Synthetic child/grandchild fixtures verify timeout and signal cleanup without running Julia. Negative tests reject the consumed N80/null cell, missing or duplicate cells, incomplete seed counts, non-single-thread admissions, altered plans, failed or incomplete pre-run receipts, timing/result mismatches, Git-checkout output paths, and missing execution authorization.

## 7a. Issue Ledger

- Fixed in this slice: plan tampering, admission-file drift, cross-cell admission reuse, single-attempt review scopes in full-batch admissions, hash-only or failed pre-run receipts, receipt/result/timing mismatch, unsafe output paths, orphaned child groups on timeout/interruption, duplicate or ambiguous attempt restart paths, and zero-exit children without a source-verified runner result are rejected.
- Open: the current working checkout differs from the retained recovery source, so no real source-bound eight-cell admissions can be generated or executed from this slice.
- Open: no measured runtime estimate for the eight-cell campaign is available. The required pre-run and a separate owner approval remain outstanding.
- Open: all original Arc 1 scientific gates remain governed by the retained ledger. This launcher changes no thresholds or covered status.

## 8. Consistency Audit

Checked the launcher against `sim/arc1/run_cell.py` and `sim/arc1/runner.py`. The child command uses the existing `--outer` interface and fixes both thread counts at one. Existing successful result records are skipped only when outer, seed, admission, and source-plan identity match. Existing started records and failed results stop the cell and require reconciliation before later outers. The new launcher does not alter the selector, fit objective, denominator rules, or reference calculations.

Read-only freeze-path review: the handoff's cited v6 path `evidence/g7-current-refresh-20261019-v6/g7-reviewed-freeze.json` is absent. The newest nested snapshot is v9 (`8a879ad40c05584309bc56f5e28f6eeffdbcc12720b21429d2eca459133ab9eb`). A full comparison using the checker's own inventory functions found Julia 453 live / 773 frozen paths: 9 current paths absent from the freeze, 329 frozen paths absent from the tree, and 9 changed common paths. R had 274 live / 318 frozen paths: 0 current paths absent, 44 frozen paths absent, and 0 changed common paths. The full path lists and source-lineage question are in `docs/dev-log/after-task/2026-10-23-g7-freeze-inventory-issue-draft.md`. Five of the nine new Julia paths are the BLUPF90 comparator packet; the other four are the pilot launcher, its tests, and the 24/30 amendment helper and test. The three profile paths named in the earlier eight-path review are present in v9 with matching hashes. These differences do not establish which lineage or path inventory should be frozen. No freeze, checker, gate, or protected file was changed or verified, and G7 remains open.

## 9. What Did Not Go Smoothly

The clean managed worktree from `origin/main` did not contain the Arc 1 runner, so implementation stayed on the already-active checkout and only used the two preflighted new code paths. The generated report command followed a symlink into Dropbox and was denied; no Dropbox file was changed. The Graft MCP context was available earlier in the turn, but the local `graft` executable was unavailable for a build refresh.

## 10. Known Residuals

- This is launcher engineering evidence only. It is not a fit, pilot result, or gate pass.
- The current worktree and retained recovery launcher/test files have different hashes. Both focused suites pass independently, but neither result binds the other source version or qualifies a source freeze.
- The plan builder can now load the exact runner, manifest, and cell entry point from a separately selected engine source root; a no-fit regression verifies module paths against the retained recovery tree. It has not been exercised with real source-bound admissions because no admission bundle exists or was authorized.
- The read-only freeze review found the handoff's v6 path missing and the current v9 snapshot omitting five in-scope comparator packet files. An owner must reconcile the intended snapshot lineage and inventory policy before any freeze or G7 verification change.
- No timing pre-run or eight-cell pilot run was started. The launcher requires a hash-matched measured pre-run receipt and a separate authorization before it can execute.
- Per the latest owner-provided state, G0 and G1 are met; G2 through G8 remain open. `public_covered_count` remains 7 and v7 remains HOLD. This slice does not change them.
- Memory receipt: the Brain HSquared.jl dossier was retrieved, but its dated content was treated as background only. `route.py` found no LOAD-FIRST manifest for this worktree. The user-provided recovery state and current source hashes governed this slice.
- Golden Set: not checked. The change is orchestration tooling and no scientific estimator behavior was changed.

## 11. Team Learning

Keep the owner-approval boundary in a separate artifact bound to the source, plan, and measured pre-run receipt. A launcher defaulting to plan-only prevents engineering approval from being mistaken for study authorization. Always compare the active checkout against the retained source before creating admissions.

## 12. Cross-Product Coverage

This slice covers only a Julia-side Python launcher for the eight FA-rank pilot cells and its use of the existing single-attempt runner. It does NOT cover R access or parity, model fitting, likelihood correctness, automatic rank-selection performance, interval calibration, G2 through G8, confirmation studies, GPU execution, releases, or public capability claims.


## 13. Current retained-source rehydration (read-only)

The Arc 1 handoff and overnight blockers were re-read before this continuation. Current worktree versus retained recovery SHA-256s differ for `sim/arc1/run_cell.py` (80ead4069b86ec309846113239a44e1695c7022f92c2206027ce4eed7818330c vs 6b31b0ca2287c8995cc99006de7e897ae82dfbddaf5c2d3bb5ea20971d293a2c), `sim/arc1/runner.py` (b6fe2abaf34dd618b27f376254cf64d341071179e2b572078cf8b232e1a3de55 vs 60d312f48abb3c3f8fc17bf4316c042fb89bc1127319caa34e38f84e68eaae9d), `tools/arc1_manifest.py` (0c17bc8cb1d488d305ab2434675b22cfd759e3034e8c142ee9b5cfcba77348ad vs ae9c2eeeebee4d956406e068abfa8f6e821b405085c41aaaccdb15a6ef619d36), `sim/arc1/execute_attempt.jl` (753a7aabede49031e2526a97865aafc6f8802fde813fce9ae10437e73573e4f3 vs 9395f338015ceb8db6ea622d33df2bafd788c655e3a2a54c5fc38ea00be8f971), `sim/arc1/reference.jl` (2d57e75f30ef3e15c5f5c1aaa24b58cae49554335b01bbdf8a7ead8f67b95c13 vs cdb0cbed68763b6469a2b468c578024539b318167145114b8ffc6ed177d63574), and `src/HSquared.jl` (70a896e236b63f63d097e5826fea058b5ce1ad2c7adee86fe811c627852c1a48 vs 46fcc36771c83c3fb9c8ef38281b9f04250e7d9f5113cc6a1058c4560971bee6). The launcher now supports selecting the retained source root and imports the runner and manifest from that tree; a focused test passed exact `__file__` and shared-manifest identity checks. No launcher plan, admission, output root, or fit was created.

The exact G6 verifier command from the handoff exited 1 with `ARC1_RETAINED_RECEIPT_REFUSED gate=G6: retained run receipt must be a regular nonsymlink file`; the specified `run.json` is absent. The G7 verifier exited 1 with `ARC1_RETAINED_RECEIPT_REFUSED gate=G7: reviewed source freeze must be a regular nonsymlink file`; the specified v6 freeze JSON is absent. `lstat` showed each path missing, not a symlink. Thus the older inventory-specific refusal is not what these exact retained paths currently prove. No recovery source, receipt, freeze, GATES.md, checkpoint, coordination board, AGENTS.md, or Dropbox checkout was changed. G0/G1 remain met; G2-G8 remain open; covered count 7; v7 HOLD.

## 14. Final source-root review

An independent read-only reviewer passed the integration that selects the engine source root. The reviewer confirmed that runner and manifest imports resolve from the selected root, the configured root is applied before admissions are processed, and the regression checks module paths and shared manifest identity. The reviewer did not run tests or fits. Local focused verification remains 19/19; this review covers launcher engineering only and adds no admission, pre-run, pilot, or scientific-gate evidence.

## 15. Follow-up adversarial review

A read-through review found that a child exit code of zero was treated as a successful attempt even if `run_cell.py` had not retained its runner result. The launcher now requires the result file and verifies its outer, seed, admission, status, timings, and source execution identity before recording success. A missing or invalid result becomes a launcher error and holds later outers for reconciliation. The regression failed before the change and passes afterward. The final focused suite passed 20/20 tests. CLI help and `git diff --check` passed. No live runner, fit, seed, admission, or campaign was started; G2-G8, covered count 7, and v7 HOLD are unchanged.

The latest independent review found that the current worktree copy still accepted a non-null `single_attempt_review_scope` while scheduling all 30 outers. Batch validation now rejects that scope before accepting an admission, with a synthetic regression that keeps the embedded and retained admission copies equal. Independent follow-up review passed this fix. The focused suite now passes 24/24 tests. No fit, seed, or campaign was started; G0/G1 remain met, G2-G8 remain open, `public_covered_count` remains 7, and v7 remains HOLD.
