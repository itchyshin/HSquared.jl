# Arc 1 execution checkpoint

Status: implementation in progress. The user approved the complete programme on 2026-10-02. No acceptance gate is yet claimed complete. Continue authorized reversible work without another approval request.

## Current work

Luna produced the exact FA spectral likelihood and analytic gradient in `src/arc1_fa.jl`, with 64 focused assertions before independent review. Astra found a missing canonicalization-pivot regression; Luna is repairing that test, adding the success-only gate marker, and correcting the explicit 2,000-iteration limit in the protocol. Optimizer dispatch has not changed.

Luna produced the repeatability likelihood, analytic scale, and component-ratio core in `src/arc1_profiles.jl`. Parent review added unphenotyped ancestor coverage. Astra found cancellation in the residual quadratic, which Luna repaired. The parent reran the resulting 29 assertions successfully on Julia 1.10.0, with four Julia threads and one BLAS thread. Confidence-set search and public integration are still pending.

Luna is building independent seed-manifest and receipt-checker foundations in `tools/arc1_manifest.py`, `tools/arc1_receipt_check.py`, `test/test_arc1_receipt_adversaries.py`, and `sim/arc1/`. No development, pilot, or confirmation datasets have run. Exact seed-manifest validation is required before studies.

## Evidence and protected state

Julia baseline: `8fd54b7b170d7e989c9959a952ed80255bbdc9f0`. Isolated R baseline: `/private/tmp/hsquared-auto-fa-r-20261001`, `c9b15af350e0c5ca62e5e698716b66101251bcdc`, verified clean. Protected-state receipt: `/private/tmp/h2-arc1-baseline-20261002.json`. Preserve the original Dropbox R checkout and `.claude/settings.json` and `.cursor/hooks.json`.

Core logs: `/private/tmp/h2-arc1-objective/` and `/private/tmp/h2-arc1-profiles/arc1_profiles_test.log`. These are deterministic implementation tests, not reliability or calibration evidence. The Unlazy ledger parses with all nine gates unmet.

## Execution controls

The current isolated Julia worktree is reused to preserve its accepted unpublished history. Parent lease: `codex-h2-arc1-20261002`; child ownership is disjoint. Astra supplies scientific review, Luna implements. Totoro was reached through the existing socket; only read-only checks were performed. No remote compute has launched.

The app goal API unexpectedly contains an unrelated manuscript objective. It has not been altered or marked complete. This lane's disk goal controls the H2 work; the older root LOOP programme also remains untouched.

## Next action

Finish independent G1 verification, including the corrected pivot regression and exact checked command. Then implement the opt-in optimizer policy with a cached spectral context, while completing the finite-resolution repeatability profile search under Astra's reviewed contract. Invalid proposals must never become successful stationary fits. Continue through S3 and live R parity before measured Totoro pilots. A measured campaign above three hours still requires its specific pre-run approval.
