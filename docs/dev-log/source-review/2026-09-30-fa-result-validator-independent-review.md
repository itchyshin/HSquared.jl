# Independent FA result-validator review

Date: 2026-09-30. Reviewer: Curie. Read-only review of the candidate validator and frozen driver. No fits, simulations, campaign changes, or repository edits were made.

## Verdict

Conditional PASS for denominator, seed ordering, summary statistics, completion checks, and ordinary finite scalar rows. One narrow scalar-projection defect remains: the validator can reject a non-recovery class that the driver's NA serialization cannot disprove. This does not require stopping the biological campaign or changing its frozen driver. Repair or explicitly qualify the validator before claiming it accepts every driver-permitted failure row.

## Exact artifacts

The following SHA-256 values were identical before and after review:

- tools/validate_fa_ordinary_start.py: cdfd38443c78b95ddb017afe814e4ae34561bb741fbd86e4d5a416dd0222d148
- tools/test_validate_fa_ordinary_start.py: 8fa8c3f8a6e6d84be578f6731c0a148391123347121faedfc70505ce2832c2a7
- sim/fa_ordinary_start_recovery_20260928.jl: 2161449e2e320a6d56bf5b71b1927e18b3d3b4dd60704d30bae5aaafbf057e9b

The source-tree hash independently checked in the preceding campaign audit was d3c2de8d7f0a1a86918f15938264bbdc892a7303b5ddd488553ac923f073ad0a. No source file was changed during this review.

## Confirmed checks

- tools/validate_fa_ordinary_start.py:179-220 checks caller-supplied hashes, the exact manifest, all 23 columns, a unique ordered frozen seed prefix, 200 rows in complete mode, terminal counts/statistics, and the final log marker. Partial mode cannot call a prefix complete.
- Lines 83-90 implement the recovery fraction, MCSE, and Wilson interval correctly. Lines 203-215 use all recorded attempts, including exceptions. Complete mode requires all 200 attempts.
- Lines 118-125 enforce the exception serialization. Lines 127-145 audit start names, counts, selection, convergence, and iteration consistency. Lines 165-174 reproduce recovery and class precedence for finite scalar rows.
- Lines 221-252 retain failure classes, overlapping criteria, flags among recovered rows, available-scalar summaries, and per-start work. Their stated limitations prevent a scalar audit from implying independent matrix/objective verification or capability promotion.
- The existing 19 Python tests independently passed in 0.379 seconds. Tests use synthetic controls and no Julia execution. The Wilson test fixture uses separate algebra; failure, truncation, duplicate, hash, class, and completion controls are meaningful.

## Fixable scalar-projection defect

At tools/validate_fa_ordinary_start.py:162-174, the comment recognizes that missing relative errors may represent scalar norm overflow. The possible classes nevertheless omit G_error when rel_G is NA and omit R_error when rel_R is NA. The frozen driver serializes both NaN and infinity as NA (sim/fa_ordinary_start_recovery_20260928.jl:93-95), while a positive infinite relative error satisfies its greater-than-threshold class predicate (lines 158-170). Finite matrix entries alone do not guarantee a finite matrix norm. Consequently a returned G_error row with rel_G=NA and rel_R=0.1 can be consistent with an overflowing scalar norm, but the validator rejects it.

Independent control: use the existing synthetic G_error fixture, set rel_G to NA, and call parse_row. The pinned validator raises ValidationError: recovery/class inconsistent with scalar metrics and precedence. This control exercises serialization logic only; it is not an observed campaign failure.

The dlog projection has the same general issue: the driver computes it independently of the finite matrix gate, and a negative infinite dlog is serialized as NA while satisfying below_truth_objective. Exact hidden values cannot be recovered from NA. Admit driver-consistent possibilities and explicitly report projection ambiguity, preserving non-recovery and class precedence. Add regression controls for NA representing positive infinity versus NaN and for NA dlog representing negative infinity. Do not replace failed rows or change the frozen campaign rule.

## Rounding and evidence limits

Lines 64-80 allow 12-significant-digit rounding uncertainty; boundary values do not automatically become exact violations. Lines 146-153 also allow binary subtraction error when checking distance from the uniqueness floor. The intervals are conservative at a power-of-ten transition because spacing below the transition can be smaller; this can broaden ambiguity but does not reject a valid boundary row. The tests cover all four recovery thresholds and below-threshold rejection.

The full matrices, raw log likelihoods, start objectives, and unrounded scalars are absent from the TSV. Their reconstruction is impossible from this artifact. Source/driver fingerprints are declared trust anchors; they do not authenticate an arbitrary TSV independently. The final log check matches the basename because copied files may have a new parent directory. These are explicitly described limitations, not denominator or completion defects.

## Minimal remaining validation

Repair the NA class possibility handling and add the corresponding fast synthetic controls. Re-run the Python suite and validate the real partial snapshot. At campaign completion, require 200 unique primary rows, matching hashes, the terminal summary and final log marker; publish class counts and the stated scalar-projection limitations. The report must retain the one-cell diagnostic interpretation and leave A2, calibration, broad reliability, and capability promotion open.

## Amended artifact review

The earlier conditional verdict and pending NA repair above are superseded for these amended artifacts, independently reviewed in /private/tmp/fa-result-validator/tools/:

- validate_fa_ordinary_start.py: 2dc2f9e5a477815123351d358f15a53bc15ca4d96a915ddc680963962966d04d
- test_validate_fa_ordinary_start.py: f407ea0b46cdfe8b5226e1b03c879f227518b733f3955957dbef79ef61ec863f

Both amended hashes were identical before and after review. The source tree and frozen biological driver were independently rehashed after review and still match d3c2de8d7f0a1a86918f15938264bbdc892a7303b5ddd488553ac923f073ad0a and 2161449e2e320a6d56bf5b71b1927e18b3d3b4dd60704d30bae5aaafbf057e9b respectively.

Amended validator lines 156-202 separate a passed recovery comparison from a failed class comparison. Missing relative errors admit NaN and positive infinity; missing dlog admits either infinity and NaN. Numeric relative errors constrain the full finite gate, and missing uniqueness cannot coexist with a numeric relative error. Class precedence remains unchanged. Compatible outcomes and scalar-projection ambiguity are reported separately from decimal threshold ambiguity. The original false rejection is resolved.

The added synthetic controls use independent IEEE comparisons before emulating the driver's NA serialization, cover class precedence with combined missing scalars, reject impossible recovery/class combinations, and constrain the finite gate when uniqueness is missing. I independently ran all 22 tests: PASS in 0.644 seconds. No biological fits or simulations were run.

Final panel verdict: PASS for the amended validator's frozen scalar-TSV contract, subject to its explicit reconstruction, rounding, trust-anchor, and basename limitations. Completion of the biological campaign and any capability claim remain separate gates. The amended tools must be copied without changes and their exact hashes rechecked when integrated; this review does not certify a different repository artifact.

A final comment correction changed line 165 from "+Inf fails >tol" to "+Inf satisfies >tol". I inspected the corrected comment and rehashed both staged files. Final validator SHA-256 is 2b2d7d60c313180b0a0668cb7d51929bdccb95d80d8f1279cbcd27c578420abb; test SHA-256 remains f407ea0b46cdfe8b5226e1b03c879f227518b733f3955957dbef79ef61ec863f. The PASS verdict applies to this final validator hash. The comment correction changes no executable code; the independent 22-test result above still covers its executable behavior.
