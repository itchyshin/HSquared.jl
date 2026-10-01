# Independent FA diagnostic test portability review

Signed: Astra High, independent reviewer, 2026-10-01 UTC.

Verdict: PASS for the exact test-only proposal. The three reported failures demonstrate nonportable assumptions about realized fits; they do not demonstrate an estimator defect. The proposed assertions check the defined diagnostic quantities and start-selection behavior. Full-suite and hosted acceptance remain pending.

## 1. Goal

Independently review the FA diagnostic test correction against the current estimator's mathematical contracts, without changing numerical source, scientific tolerances, or frozen campaign evidence. Review scratch: `/private/tmp/astra-fa-diagnostic-test-portability-20261001`.

## 2. Implemented

Read-only review of the author proposal plus independent scratch probes. No live file was edited. Independently replayed the exact patch, verified its packet hashes, and ran the focused prepared tests together with separate selection and expected-information controls.

## 3a. Decisions and Rejected Alternatives

Accept replacing the two positive lower bounds on covariance disagreement and the demand for mixed convergence statuses. A valid diagnostic may report nearly identical covariance estimates or two converged starts. Reject changing the estimator or widening scientific tolerances to force the old expectations.

The author also replaces the neighboring expectation that no better nonconverged attempt exists with its defined logical condition. Separate ordinary single-start fits supply the covariance, likelihood, convergence, iteration and uniqueness values used to check the automatic-start report. The balanced reporting initializer deliberately follows the automatic initializer's arithmetic; otherwise mathematically equivalent starts can differ through rounding and produce different optimization paths. The original explicitly supplied balanced initialization remains in the original selection checks.

Mixed-status selection remains covered by deterministic synthetic attempts where a better objective from a nonconverged start must lose to a converged start. Structural information and floor assertions remain substantive and unchanged or strengthened.

## 4. Files Touched

Author patch touches only `test/test_multivariate_fa_multistart.jl`. Reviewer writes only its owned scratch controls, logs and this receipt. Numerical source, Project, Manifest, optimizer, starts, budgets, frozen FA campaign, acceptance manifests and live runner are unchanged.

## 5. Checks Run

- Verified all 23 `packet_files` hashes in the author inventory.
- Replayed the patch against the exact original test: result equals the prepared test byte for byte.
- Verified the author's fixture hash driver contains the original fixture code exactly.
- Verified only four original assertions are replaced; all others remain. The preceding original controls and the full large unit/order block are byte-identical.
- Independently confirmed the source tree and multivariate file pins below.
- Before receiving the frozen proposal, ran 19 no-fit assertions: 4 original information controls, 10 independent selector controls, and 5 independent information/negative-incidence controls. Julia1.10.0, Julia/BLAS1, 20.15 seconds, under the stated 30-second estimate and 120-second cap.
- Replayed the frozen focused tests with the independent controls on Julia1.13.1 ARM, OpenBLAS0.3.30: **83 PASS, 0 FAIL**, comprising 68 author/original assertions plus 15 independent assertions. Julia/BLAS1; 42.68 seconds, under the stated one-minute estimate and two-minute cap. Command and timings are in `reviewed-1.13.1.json`.

The author reports and pins original focused red 25 PASS/3 FAIL and focused green 68 PASS on each of Julia1.10.0 and1.13.1. These author runs remain distinguished from my replay. I did not repeat the unchanged large unit/order fits or any campaign.

## 6. Tests of the Tests

Independent selector controls challenge both orderings of a mixed pair, all-converged and all-unconverged pairs, invalid candidates, Inf/NaN objectives, exact ties, and absence of any eligible candidate. They verify the declared contract rather than asking a random fit to create a particular status combination.

For expected REML information, the reviewed helper uses `I_ab = tr(P V_a P V_b)/2`. My independent oracle Cholesky-whitens the covariance, removes the fixed-effect subspace with a QR projection, and forms the Frobenius Gram matrix of the projected derivatives. It agrees with the helper and has the expected 18-dimensional rank at the chosen generic repeated-record point. Removing genetic incidence makes its first eight rows zero and leaves residual-information rank 10. These negative controls would detect a claim of genetic identification unsupported by the design.

The replacement disagreement assertions recompute normalized Frobenius differences from separately fitted starts. They would reject fabricated zero or rescaled disagreement even when the true disagreement is small. No approximation tolerance was enlarged.

## 7a. Issue Ledger

Resolved by the test proposal: three empirical assumptions incompatible with the measured Julia1.13.1 fixture, plus the neighboring fixed `!better_nonconverged_start` assumption.

Preserved: valid/converged start selection, returned likelihood/covariance/status/iteration agreement, hard uniqueness floor, near-floor interpretation, fitted expected-information rank, one-iteration nonconvergence control, and unit/order checks.

Still owed: parent full-suite and hosted replay on the integrated candidate. This receipt does not close those gates.

## 8. Consistency Audit

The current source defines G/R disagreement as Frobenius distance divided by the larger fitted covariance norm, with an eps floor. It imposes no minimum disagreement. Selection minimizes finite valid negative log likelihood among converged attempts when available, otherwise among all valid attempts. Better-nonconverged status compares each valid nonconverged likelihood with the selected likelihood. Floor distance is `min(psi - 1e-4)` and the near-floor threshold is one percent of that fixed absolute floor.

The measured fixture premise is specific: both original seeds produce different normal draws and Y bytes under Julia1.10.0 and1.13.1, while Ainv/G/R hashes agree. Author executable paths, commands and logs substantiate this. This establishes changed input data; it does not exclude additional optimizer/platform differences or assert that every Julia version behaves identically.

Expected information at a fitted covariance, even when full rank, does not establish observed curvature, regular inference near the floor, or interval coverage. The remaining empirical fitted-rank and near-floor assertions passed the measured runtimes and remain fixture-specific checks. The independent fixed-covariance information controls retain their structural meaning.

## 9. What Did Not Go Smoothly

The author's initial prepared whole-file replay entered the unchanged large unit/order fit block and was terminated at its 120-second cap. Its log and timing remain in the packet; it is not a completed check. The bounded focused replay then passed. My isolated Julia1.13.1 run without compiled modules emitted import warnings while loading dependencies, but completed with exit zero within its estimate. A process-status inspection was denied by the sandbox; no permission bypass or external process action was taken.

## 10. Known Residuals

No whole-estimator, global-optimization, broad portability, calibration, performance, GPU, covered-status or release claim follows. The original 200-seed FA campaign remains bound to its historical environment and exact source; it was not rerun or reinterpreted. The preserved large unit/order block has not been freshly completed by this reviewer. The parent owns its full-suite execution.

## 11. Team Learning

For diagnostics, verify the defined quantity from actual outputs. Use controlled attempts to test convergence-selection policy and independent covariance calculations to test information. A random seed is not an exact cross-version data artifact. Graft supplied source context before inspection and reported about 259,431 tokens saved in this review.

## 12. Cross-Product Coverage

This approval covers the exact FA diagnostic test-only delta. It does NOT cover the concurrent endpoint/PCG author changes, full package or hosted acceptance, R bridge parity, the FA recovery campaign, broad inference, or release. Earlier numerical components retain their separate independent approvals.

## Exact pins

- Candidate HEAD: `ec9414c35d7621c6bd4321a9d16067ac9a2ea2eb`.
- Unchanged source tree: `59d4a803e4d290a840927b4bce26ea4722f4404c009c171d173ba0c300c7d76e`.
- Unchanged multivariate source: `f975657ef43d86045171a9265e5536370043a46fc72880a3e80ee87fcad699c2`.
- Original test: `e621d60892c9ec9ceab6a1b06d051495d2aa1b9d6c70346023129a993b2d9085`.
- Approved prepared test: `e340a84b71b6ae3b62ffa96591d5b576ba9c0d43c6fdb9e24382fa198ef942ea`.
- Approved patch: `ce51d97a34b485aaec7c963b7566e4d71fbda45e02ef28655606391e8644bada`.
- Author pins.json: `8df752af82c02c0956a681b92c8512df9354b180f897f4664898da42a41af0bd`.
- Author receipt: `c525922ff2a1539ca5c50bac7fe4528e116e2790a0dc165ec42030eea34115b1`.
- Independent controls: `456822e5190f064fa28ecfb1e350db1aeb50f52ec5d16bb8a48f8b970255fb54`.

Reviewer logs, command metadata and verification results are pinned in the accompanying `SHA256SUMS`.
