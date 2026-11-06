# G5 N=320 development pre-run timeout

## 1. Goal

Measure one frozen repeatability-profile development attempt at N=320 to improve the campaign runtime estimate. The result provides no G5 qualification and authorizes no pilot or confirmation work.

## 2. Implemented

No production code changed. Corrected the pre-run plan so both the estimate and stop are 1,800 seconds, obtained Astra approval, staged the exact 194-file source closure on Totoro, ran one admitted development seed, and retained its timeout result and logs locally.

The approved plan SHA-256 is `38f549850e25cf6af3b353cbc824d56e8b8b68c75137099423a429e312a05dc0`. Admission SHA-256 is `9dc1e43003017fb5602882d2b677332b2a52562e1463f587e3bf986e1fbec595`.

## 3a. Decisions and Rejected Alternatives

The attempt was repeatability / development / N=320 / near-zero additive, outer 1, seed `5697631027019374296`, using `arc1_profile_v4`. It ran on Totoro with Julia 1.10.0, four Julia threads, and one BLAS thread. At 1,800 seconds the child was terminated and the runner recorded `timeout`, success false, child exit -15. This is development attempt 1 of 30 for the cell and will not be replaced.

The first launch passed a Juliaup selector where the runner requires an executable path. It failed before allocation or fitting. The corrected launch used the concrete Julia 1.10.0 binary and is the only attempt that consumed the seed.

## 4. Files Touched

- `LOOP/lanes/arc1-gaussian-reliability-20261002/evidence/g5-n320-dev-prerun-v1/pre-run-plan.json` was corrected and reviewed.
- `LOOP/lanes/arc1-gaussian-reliability-20261002/evidence/g5-n320-dev-prerun-v1/source-bundle.tar.gz` retains the exact source closure; SHA-256 `68e3084316554b016b9561ae6f16a45e661bfd72d5e2a84250c6123800dd9b8b`.
- `LOOP/lanes/arc1-gaussian-reliability-20261002/evidence/g5-n320-dev-prerun-v1/totoro-20261007/` retains run output. Attempt result SHA-256 `daf752dfbee3dc423a97da32450144e9834d87e5955b9df64765ea6d40b793a9`; Julia log SHA-256 `f6a2e0c89de80c8328e957620b2d0a5fa7abc25e00e915f73259cad7380c8305`; run-admission file SHA-256 `052c7fdb93eea24523c732aeaaa734320e76ec8d293d44e76aea24c0b6bd78dd`.
- This report and `LOOP/lanes/arc1-gaussian-reliability-20261002/checkpoint.md` were updated.
- No production Julia source, R source, public grammar, capability status, seed manifest, or gate status changed.

## 5. Checks Run

- All 194 staged source hashes matched admission before execution.
- Julia 1.10.0 load-only identity preflight passed with 56 loaded dependencies, four Julia threads, one BLAS thread, and the admitted project path.
- `arc1_manifest.verify_run_admission` passed against the current source tree and frozen admission.
- Attempt start/result records, outer index, seed, canonical run-admission identity, profile-method version, timeout status, and result hash were independently cross-checked.
- After termination, process inspection found no remaining runner or Julia child. `/usr/bin/time -v` recorded wall time 30:00.77 and maximum resident set size 2,956,424 KB.
- `slop_check.py` reported zero findings. The structural check is rerun after this header correction.

The Julia stack trace places execution in `arc1_repeatability_receipt` while hashing `repr(profile.targets)` at `sim/arc1/execute_attempt.jl:227`. The profile object had been returned to receipt construction. This does not establish that all five intervals formed or reveal their endpoints/statuses. No profile result or interval summary was written. Astra's independent diagnosis is pending.

## 6. Tests of the Tests

No checker was modified or adversarially tested during this attempt. Source/admission validation was applied to the retained run. The attempt result hash and seed/admission binding were recomputed independently.

## 7a. Issue Ledger

- Open: exact cause of the long receipt path and the narrowest safe repair; Astra's independent diagnosis is pending.
- Open: G5 formation rate and all-attempt coverage across frozen cells.
- Open: G2, G3, G4, and G8.

## 8. Consistency Audit

The source still matches the frozen admission. The result binds the only consumed seed to outer 1 and the canonical run admission. Source, protocol, thresholds, denominators, seed assignments, capability status, and gate states remain unchanged. No other lane's production source was edited.

## 9. What Did Not Go Smoothly

The model did not finish receipt construction within the 30-minute allowance. The initial launch command also used a Juliaup selector rather than its installed executable; it failed before consuming a seed. The corrected run used the pinned runtime and preserved the timed-out attempt.

## 10. Known Residuals

This is one failed N=320 development attempt. It does not estimate formation or coverage and does not qualify G5. The profile computation may have completed statistical optimization before receipt construction timed out, but retained evidence cannot confirm any interval outputs. Campaign time cannot be projected from this censored attempt alone. Any source repair needs a new source freeze, exact review, tests, and a new unused admitted seed. Keep pilot and confirmation held.

## 11. Team Learning

When a runner probes Julia with `--version`, give it the concrete executable path from Juliaup's installed-version directory; selector syntax is not an executable. For expensive profile objects, measure fitting and receipt construction separately. Preserve a timed-out seed as a failed attempt rather than replacing it.

## 12. Cross-Product Coverage

Covers ✓: one source-pinned Julia G5 N=320 development attempt, runtime identity, timeout outcome, and retained runner evidence.

does NOT cover ✗: R access or parity, any G5 formation or calibration gate, exact-zero diagnostic cells, pilot or confirmation, G2-G4 or G8, GPU, package release, or H2 project completion.

Style: 2/10, medium confidence; prose is direct and tied to retained evidence. Genre/coverage: complete 12-section after-task report. Evidence/repair: §§1 and 3 state the bounded purpose and distinguish profile return from interval formation; no further change needed. Gates: science = pass for the narrow attempt interpretation with no qualification claim; facts = pass against pinned admission, preflight, result, log, and process state; references = not applicable because no external references occur. Provenance: self-review, draft version 2026-10-07-v1, 2026-10-07; no controls/examples consulted. Independent diagnosis review: pending.
