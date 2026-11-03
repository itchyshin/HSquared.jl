# G2 retained BFGS state certification, 2026-10-07

## 1. Goal

Certify exact-source consistency of the retained terminal BFGS states for G2 outer7 and outer10. This bounded diagnostic was not intended to establish optimizer reliability or close a scientific gate.

## 2. Implemented

Built a read-only certifier and hardened its runner for bounded process cleanup, signals, admission digest binding, post-run pin checks, and durable failure receipts. The final run verified both retained traces and their saved transitions. It made zero objective, optimizer, selector, fit, or simulation calls.

## 3a. Decisions and Rejected Alternatives

Kept the frozen acceptance criteria, starts, seeds, denominators, and strict covariance/Wolfe refusals unchanged. The diagnostic result does not qualify G2. Astra's read-only review passed the exact pinned candidate before execution. No production optimizer repair was justified by this state-consistency result alone.

## 4. Files Touched

Created or changed only the following diagnostic and report files:

- `LOOP/lanes/arc1-gaussian-reliability-20261002/evidence/g2-bfgs-state-certification-20261007/certify_terminal_bfgs_states.jl`
- `LOOP/lanes/arc1-gaussian-reliability-20261002/evidence/g2-bfgs-state-certification-20261007/test_certifier.jl`
- `LOOP/lanes/arc1-gaussian-reliability-20261002/evidence/g2-bfgs-state-certification-20261007/run_certifier.py`
- `LOOP/lanes/arc1-gaussian-reliability-20261002/evidence/g2-bfgs-state-certification-20261007/test_runner.py`
- `LOOP/lanes/arc1-gaussian-reliability-20261002/evidence/g2-bfgs-state-certification-20261007/certifier-source-lock-v1.tsv`
- `LOOP/lanes/arc1-gaussian-reliability-20261002/evidence/g2-bfgs-state-certification-20261007/certifier-admission-v1.json`
- `LOOP/lanes/arc1-gaussian-reliability-20261002/evidence/g2-bfgs-state-certification-20261007/run-20261007T192834Z-31584177/`
- `docs/dev-log/after-task/2026-10-07-g2-bfgs-state-certification.md`

No production optimizer, study, denominator, seed, threshold, R package, public grammar, or capability-status file changed.

## 5. Checks Run

- Python AST parse of `run_certifier.py` and `test_runner.py`: passed.
- Julia certifier tests: 10/10 passed.
- Julia certifier self-test: `ARC1_BFGS_STATE_CERTIFIER_SELF_TEST_PASS`.
- Python runner lifecycle suite: 8/8 passed.
- Admission binding and all nine current certifier pins: passed. Admission SHA-256 `cf40009053a36d37f34d8b0d466bdb0d381c543a72b4ca37b7100c92e3cdcc64`; source-lock SHA-256 `aff95b2c1994340be1754c4409b30f079f424ddd1142b05937ca24e97cf963c6`.
- Astra's exact-hash read-only review: PASS. All 63 historical source-lock entries matched.
- Bounded certifier run: PASS in 2.344 seconds, exit 0, 120-second cap. The receipt records both processes reaped, no timeout, no interruption, no finalization error, and no post-run pin mismatch.
- Astra's independent output review: PASS for the retained run only. Receipt SHA-256 `2a0b62bcbb0cbfc2799a500948136e85390ce40a1c6810526774c1134e4596d0`; output SHA-256 `271c87e8d541ed81774c42bd965ee9336b31750e95cffe555b184e00fce93de5`. It confirmed 110 outer7 states/109 updates and 167 outer10 states/166 updates; maximum relative update reconstruction errors were `2.10875e-14` and `2.92573e-14`. No gate transition is supported.
- `Rscript ~/shinichi-brain/tools/check-after-task.R <this report>`: the 12-section structure passed; its final promotion check correctly stopped because Arc 1 still has unmet G2, G3, G4, G5, and G8 gates.
- `python3 ~/shinichi-brain/tools/slop_check.py <this report>`: passed with zero flagged findings; the final report has 763 words and no em dashes.

The scoped Unlazy status reports G0, G1, G6, and G7 met; G2, G3, G4, G5, and G8 remain unchecked. This diagnostic does not change that status.

## 6. Tests of the Tests

The lifecycle tests first failed on missing runner features. A targeted adversary also reproduced a PASS receipt remaining on disk after corrective publication failed; the fallback repair made that test pass. The final eight-test suite exercises descendant cleanup, a live-child SIGTERM, signal during receipt publication, a post-run hash failure, and failed corrective receipt publication. Julia's certifier self-test passed. No test called the scientific objective or optimizer.

## 7a. Issue Ledger

- **Fixed:** runner lifecycle gaps identified by successive Astra HOLD reviews: child cleanup on signals and exceptions, signal-aware finalization, admission digest validation, finalization error retention, and corrective receipt fallback.
- **Open:** G2 ordinary-start eligibility and the underlying numerical causes of outer7/outer10 refusal. This diagnostic supplies no optimizer-reliability evidence.
- **Deferred:** G3, G4, G5, and G8 scientific acceptance work remains unchanged.

## 8. Consistency Audit

Verified the certifier's nine pinned inputs, its nine-row source lock, the original 63-entry historical source lock, the two retained witness identities, and the prior directional audit identity. The run output identifies outer7 and outer10 as failed line-search attempts and reports reconstructed BFGS updates within the saved tolerance. These checks establish consistency of saved records only. No shared check log, coordination board, gate status, capability status, or acceptance denominator was changed. Preflight showed missing-reference work on the shared check log and coordination board, so they were left untouched.

Memory receipt: loaded the HSquared LOAD-FIRST route and repo `AGENTS.md`; the validation-harness and R-public/Julia-engine boundary informed the narrow diagnostic scope. The cross-project GLLVM Golden Set was not applicable, so `tools/memory_regression.py` was not run. No sibling-project statistical thresholds were transferred.

## 9. What Did Not Go Smoothly

Three earlier runner candidates received HOLD findings and were repaired. One first version of the post-run failure fixture stopped before the intended lifecycle path; the fixture was corrected, and the final adversarial tests reached the target code paths. No scientific run began during those repairs.

## 10. Known Residuals

This diagnostic does not prove convergence, numerical reliability, reference-likelihood quality, or G2 eligibility. It does not resolve the failed outer7 or outer10 fits. The full Arc 1 goal remains active. Latest retained checkpoint information about G6/G7 must be reconciled before their status is repeated; this diagnostic made no claim about those gates.

## 11. Team Learning

A diagnostic receipt should say exactly what it verifies and what it cannot establish. Lifecycle tests must inject failures after a successful first write, since a nonzero process result alone does not prove that retained evidence records failure safely. No broader reusable method was promoted in this slice.

## 12. Cross-Product Coverage

This task touched only a Julia-side diagnostic runner and retained-state checker. It covers the two named historical Julia traces and their pinned source/evidence identities. It does NOT cover production Julia FA fitting, automatic rank selection, R controls or parity, interval calibration, any study gate, or public capability status.
