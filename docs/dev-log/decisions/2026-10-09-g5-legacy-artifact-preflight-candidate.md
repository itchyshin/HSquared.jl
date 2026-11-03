# G5 legacy artifact disposition and synthetic preflight candidate

Status: revised candidate for independent read-only source review. This proposal grants no legacy-artifact read, study attempt, seed allocation, denominator change, or gate credit.

## Decision requested

Approve one bounded engineering preflight of the current Arc1 container path using a deterministic fake-engine repeatability artifact, then keep the timed-out legacy diagnostic closed and unverified. The preflight tests current-format writing, canonical inspection, and result projection on one synthetic artifact. It provides no G5 validation evidence. No later artifact read, pilot, or confirmation follows automatically.

## Exact evidence and scope

- The consumed legacy target is the N=320 near-zero-additive development outer-2 diagnostic, SHA-256 `6868c4b15c85f58d261b5935dd860a94a071ea7f71047215ab1d11c821386172`, 130,851,693 bytes.
- Its single permitted read-only replay used candidate v6 SHA-256 `f1bb79d97ca30be5519ebe73f85d1a01422be166f16d2cd2e6f627f8c512f599`. The exact inspector bytes are retained in the request's `inspector_base64`; they call `open(deserialize, path)` at line 155. The run record confirms a 900-second timeout, empty stdout, successful postchecks and cleanup, and `gate_credit=false`. That dispatched attempt is terminal.
- Keep the legacy file labelled `diagnostic_legacy_unverified`. Do not reread, retry, copy, convert, or claim that its modeled output was validated. It is not a calibration or confirmation row and does not change a frozen denominator.
- Current attempts use `arc1_write_artifact_container_new` at `sim/arc1/execute_attempt.jl:566`. The inspector dispatches current containers to `arc1_read_artifact_container` and legacy files to Julia deserialization (`sim/arc1/inspect_artifacts.jl:17-23`). The current container reader verifies section digests in chunks, then eagerly decodes and restores the full artifact (`sim/arc1/artifact_container.jl:199-274, 483-535`). This does not make the legacy target selectively readable.
- The synthetic builder, `build_synthetic_repeatability_artifact.jl`, is hash-pinned by the source-freeze manifest. It checks the existing executor test source, evaluates only helper definitions before its first testset, creates the fake engine, and makes one N=16 `engineering_probe` attempt using fixed test seed 20261002 with no bootstrap seeds. The deterministic fake engine returns synthetic profile values; it does not fit a statistical model. It does not execute a testset or study runner.
- The supervised inspector child invokes the canonical `_inspect_full_artifacts` implementation from `tools/arc1_receipt_check.py`. That implementation launches the repository's exact Julia inspector on the synthetic artifact with its existing 120-second timeout and one Julia/BLAS thread. The child remains in an owned process group, so a stuck Julia subprocess and descendants are terminated as a unit.
- The sealed source inventory contains 46 files: `Project.toml`, `Manifest.toml`, every Julia source under `src/` and `sim/arc1/` (including reference and artifact code), the executor test helpers, receipt checker and manifest tool, and all four preflight runner/builder/test sources. Source hashes and the freeze-file hash are checked before and after execution. The current source-freeze SHA-256 is `2dd5bb7c111d017c02eeff8ff06bf694df355a63f9b4508af5e1d2b60228e57d`; individual source hashes are in `source-freeze.json`.
- Exact review-source candidates: builder `00dcbc898507ca84f6016fbf7a3ab3487afb03dc1d5fadbc9405087ffdb69a23`; runner `04a282b596b8e0d8ddeeabc57b3a44881f43cbe3d01101ca57f74af5145d51d6`; inspector child `a9ce645b93268cab1283b71f5b6aa1c1c8aa30bc933739c1feaa53453731b367`; tests `4c0a04f0a0b332fb64b2e74c250e2e1dfd8308ba81f34b391160cf658f6efba4`.
- The Python 3.13 suite has 13 passing checks, including a new 4 ms remaining-budget process-probe test, successful completion, parent/descendant timeout, supervisor SIGTERM, injected interruptions during wait and cleanup, cleanup deadline exhaustion, group-signal denial, builder output-directory compatibility, exact projection keys and types, post-run source/freeze hashes, failure-receipt retention, late-signal status replacement, and cleanup despite evidence-copy failure. Retained log SHA-256: `668af4ba551c13a7b6f3b1a8aff5e79ce3f786a8d60cf1f055d043ed821fad10`. Python compilation passed, the builder parsed without execution, and the 46-file freeze check passed.
- The current Julia regression log `/private/tmp/arc1-container-julia-current-source-rerun.log` has SHA-256 `a8edd5e20650970f8adfa8e047e5b90e9cf6cdacf14feb4e70cd425f7d76fd3d` and records 194/194 executor checks, 10/10 admission checks, and 15/15 diagnostic identity checks. The partial container map reviewed earlier is SHA-256 `7272f73738207968823b8aeadfaf6a2cc8b35e0ff6289f4a1070ef20de52272a`. Neither grants G5 credit.

## Bounded preflight, only after PASS

Run exactly once from this worktree with the inspected source-freeze SHA-256:

```sh
python3.13 LOOP/lanes/arc1-gaussian-reliability-20261002/evidence/g5-current-container-preflight-v1/run_preflight.py \
  --root "$PWD" \
  --outdir /private/tmp/arc1-g5-current-container-preflight-v1 \
  --freeze-sha256 <reviewed-source-freeze-sha256>
```

The builder process has a 30-second execution limit and a shared 12-second cleanup deadline covering TERM, KILL, process-group probes, and direct-child reaping. The canonical inspector retains its 120-second Julia subprocess timeout; its outer supervisor allows 125 seconds for startup/return, followed by the same 12-second cleanup deadline. The combined execution-and-cleanup budget is 179 seconds, excluding source hashing, receipt writing, and operating-system scheduling. Julia and BLAS each use one thread. No RSS ceiling is asserted; the small synthetic fixture establishes no large-artifact memory claim.

Acceptance requires exactly one inspector row and exact, present values: `retained_result_present is True`, `raw_result_matches_derived_receipt is True`, `raw_result_projection_difference is None`, and `receipt_summary_matches_retained_result is True`. The runner verifies synthetic artifact byte count and SHA-256, source inventory and manifest hashes before and after, child-process cleanup, retained failure receipt, and temporary-fixture removal. It emits the success marker only after closeout and receipt publication. An absent field, wrong type, nonzero exit, timeout, interruption, source/artifact identity mismatch, surviving live process, or cleanup failure is a failed preflight. It does not retry.

This one preflight tests the current-format path on one small synthetic artifact only. It does not inspect the legacy file or establish large-file timing, memory use, bootstrap behavior, or campaign performance. A pass grants no G5 statistical evidence. All G5 interval calibration, formation-rate, coverage, refusal, and retained-artifact requirements remain open. G0, G1, G6, and G7 retain only their recorded scopes; G2-G5 and G8 remain open.

## Review questions

1. Is the timed-out legacy replay correctly terminal and excluded from study denominators?
2. Does the fake-engine fixture exercise a non-null raw repeatability result, derived projection, embedded receipt summary, and current container format without a model fit or testset?
3. Are all transitive source inputs pinned, and are execution, cleanup, post-hash, failure-receipt, and child-process bounds executable as written?
4. Does the scope preserve all scientific G5 requirements and grant no legacy read, study, seed allocation, or gate transition?

Any HOLD returns to design. PASS permits only the single synthetic preflight above. It does not authorize another legacy read, study, seed allocation, or Arc1 gate transition.
