# G5 retained artifact reavailability audit, 2026-10-09

## 1. Goal

Resume the Arc 1 G5 inspection from the retained checkpoint without creating a fit, consuming a seed, changing a denominator, or claiming interval calibration.

## 2. Implemented

Confirmed that the exact outer-2 JLS artifact from the N=320 near-zero-additive development diagnostic still exists on Totoro. The remote file is 130,851,693 bytes, matching the locally retained raw-inspection record. Admission SHA-256 is `95b806468958a01e3727615f49b22993f3aa5aee81f1e59d936a17a2dae024ac`; prior timeout receipt SHA-256 is `4cad63ed733d6932edba63a060c3aba22f2beafe8e1fcc452080aff6b13e1295`. Compared the original admission's 194 source pins with current checkout files: 15 differ and none are missing. The current inspector SHA-256 is `fc58f9444affe63c21ec854212ae00220728bf2f933735fd73e4cf71faf6b206`. The old admission therefore cannot authorize a current-source inspector replay.

Independent Astra review of candidate v1 passed source compatibility but held replay: a separate source root would fail the inspector's absolute engine/project path checks. Candidate v1 is retained at manifest SHA-256 `3c4e3c5fc0042d4099ae6ee547a9257240c68f8cc7ed3234bf015f287020502c`; it authorizes no execution.

Independent Astra review passed candidate v2's path-preserving arrangement. It requires exclusive creation and removal of a temporary sibling inspector, all output correspondence flags, actual runtime/dependency records, a 900-second cap, and before/after artifact and source-pin checks. Candidate v2 is retained at SHA-256 `e5f1c858228f8b6af1f534a40a76fb3fb1f192bb121bcb00e6f150850f880b26`.

Prepared candidate v3 at `/private/tmp/arc1-g5-inspector-candidate-v1/candidate-v3.json`, SHA-256 `58628f9e398b617965dcc80a495ad17a77ca615ec98097579b63ea4d7784ca29`. It incorporates those conditions and lists the exact success flags, timeout, runtime pins, output path, artifact identity, and cleanup. Exact review is pending. No remote source was changed and no replay has started.

## 3a. Decisions and Rejected Alternatives

Kept G5 open. Did not reuse the stale admission, rerun the fit, replace the timed-out inspection, or count the retained outer-2 outcome as coverage evidence. A new read-only inspection needs a source bundle that preserves the original fit identity while separately pinning and reviewing the corrected inspector path.

## 4. Files Touched

- Added this report and a dated G5 audit entry in the check log, coordination board, and Arc 1 lane checks.
- No production code, R checkout, protected settings, study inputs, or seed ledgers changed.

## 5. Checks Run

- `route.py HSquared.jl`: loaded the repository's validation and compute routing notes.
- `lane_preflight.sh <repo>`: found one Codex lane and no other active lane in its 12-hour census. File preflight found the new lane-check note genuinely new.
- Read-only Totoro `stat`: confirmed the retained JLS artifact exists at the path recorded in its inspection receipt and has the expected byte count.
- Python source-pin comparison: 194 original pins checked; 15 differ from current checkout and zero are missing.
- Candidate v1 review: source compatibility passed; replay was held because the copied source root changes absolute engine/project path identity.
- Candidate v2 review: path-preserving arrangement passed, subject to the specific conditions incorporated into v3.
- Candidate v3 manifest: exact runtime, artifact and source pins, output conditions, timeout and cleanup are recorded; exact review is pending.
- No Julia or R test, fit, benchmark, simulation, or campaign was started.

## 6. Tests of the Tests

Not applicable to this read-only artifact-availability check. Existing regression and G7 evidence for the corrected inspector remain separate from artifact-level validation.

## 7a. Issue Ledger

- G5 remains open. The prior inspection timed out before full receipt, semantic-identity, and recomputed-certificate checks completed.
- The stale admission is rejected for a replay because its 194 pins no longer match current source.
- No gate, capability, seed, denominator, or public covered count changed.

## 8. Consistency Audit

The retained outer-2 report says all five targets formed for that one dataset, while also stating that residual-variance and repeatability intervals missed their generating values. This remains a single diagnostic outcome and provides no coverage estimate. Current GATES still marks G5 unmet, consistent with the evidence.

## 9. What Did Not Go Smoothly

The first local path probe omitted the dated Totoro run-directory suffix and reported no file. Repeating the check against the exact path in the retained inspection record confirmed the artifact. No remote artifact was modified.

## 10. Known Residuals

The artifact has not yet passed a complete current inspector replay. Candidate v1 cannot be used because it changes absolute paths. The earlier 900-second inspector timeout remains retained and unmodified. Candidate v3 must receive exact review before any replay; no identity check may be bypassed.

## 11. Team Learning

An artifact's continued existence does not make an old admission reusable. Verify its exact remote identity, then compare all pinned inputs before constructing a new read-only review bundle.

## 12. Cross-Product Coverage

No R or Julia behavior changed. This partial audit covers only the retained G5 outer-2 artifact's availability and its admission-pin comparison. It does NOT cover profile interval correctness, calibration, R parity, the other G5 sample-size/signal cells, or any study-level acceptance criterion. Live R parity remains covered only by the separately recorded G6/G7 receipts.

**Next action:** receive independent review of candidate v3, then consider a replay with a 900-second hard cap and no fit or seed allocation. G2 remains paused pending the user's explicit development-allocation decision.
