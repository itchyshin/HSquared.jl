# Final reviewed-repair composition

Date: 2026-09-30. Verdict: PASS for isolated composition, patch replay and focused checks.

## 1. Goal

Compose the approved Julia repairs against the current dirty candidate and preserve the original FA source, campaign inputs and existing test runner work.

## 2. Base and ownership

Snapshot HEAD `3d6d7ffc961b65fa5a44ce277a7d1168ba69b6fe`; source tree `d3c2de8d7f0a1a86918f15938264bbdc892a7303b5ddd488553ac923f073ad0a`. The original directory contains the copied dirty candidate, including Project/Manifest and its weak-direction runner/test. Parent-announced source-neutral commits explain current HEAD `6271cfd58651e69cd27a64dcf02cb8960a29e260`. Only this isolated composition directory was changed; live source, schema and runner still match the original snapshot.

## 3. Inputs and changes

Thirteen pinned patch inputs are recorded in inputs.json and composition-inventory.json. The final patch changes 23 files: six docs, eight source files and nine test files. It includes both separate sections of the coefficient-field and maternal-label schema repairs. The R reader patch remains a separate parent-owned repair. The final h2 input is the pinned h2-descriptor-fix.patch `e255f85afdb3b68e77d7a5e303c7f46109340464aad52fcbb9e0315c682780c8`, independently reviewed by Astra. The intermediate source.diff was not used.

## 4. Overlap resolution

The two GLLVM entrypoints conflicted when combining input and descriptor guards. Both retain the approved record-family guard followed by the approved mode-input guard. The saved overlap inputs and resolved contexts are in overlaps/. All later patch inputs applied cleanly. C1/C4 invalid GaussianResponse(Inf) factories were moved out of the tuple into constructor exception assertions because finite-ingress rejects them at construction. This changes that test's count from 50 to 48.

## 5. Required h2 prose corrections

Astra's arithmetic review passed; the source and doc19 prose required zero-variance and conditional-variance qualifications. The final source states the theoretical population projection bound [0,1], including zero genetic variance, with finite positive observation variance and finite quadrature as an approximation (src/nongaussian.jl:1629 and :1832). Binary probit ordering is non-strict, with equality at zero genetic variance in the exact finite-moment model (:1746; doc19:152). Gamma log variance is conditional Var(log Y | eta), including the adjacent trigamma comment (:293, :1777, :1797; doc19:91, :174, :198, :207).

Parent-requested public docstring corrections state the Gaussian conditional ratio and predictor_variance = 0 requirement (:1840), additional fixed-predictor spread and zero genetic/fixed covariance plus a normal predictor approximation (:1852), and common trial counts versus genuinely varying vectors (:1857). The 20-node quadrature formula, payload shape and information-limited wording are preserved. prose-delta.json records each replacement and its origin. Reversing every logged replacement exactly reconstructs the source and doc19 immediately after the approved h2 patch. These corrections change comments, docstrings and returned caveat strings, with no arithmetic edits beyond the approved patch. The regression has no stale strict-order or Gamma-caveat string assertion.

## 6. Test registration and preservation

Eight focused test files are registered exactly once in the existing runner; seven new module scopes were appended, and the coefficient include already supplied by its patch remains once. The original runner is exactly reconstructible from the dirty snapshot plus the approved coefficient/marker edits and the appended registrations. All earlier focused test files are byte-identical after the h2 addition, and none calls its new h2 helpers. Marker tests retain their existing location. FA source multivariate.jl, the original 200-seed driver, Project/Manifest, weak-direction test and existing payload parity test are byte-identical in original, composed and live files. Ledger ID/status columns and runtime status sets are unchanged; public_covered_count stays 7.

## 7. Runtime evidence

Baseline estimate: 10-20 minutes including compilation, below the 30-minute task cap. Baseline focused-checks.log records 481/481 assertions, exit zero: syntax16, status2, GLLVM48+50, coefficient74, RR41, data29, flat35, ingress141 and marker45. These checks ran before the isolated h2 addition.

H2 estimate: under one minute. The new test ran against the final composed source with JULIA_NUM_THREADS=1 and OPENBLAS_NUM_THREADS=1, offline, compiled modules disabled. h2-composition-checks.log records 170/170, exit zero, testset time 1.2 seconds. The qualified total is 651 assertions: 481 retained baseline plus 170 executed after the h2 addition. The unchanged baseline cases were not repeated. Final source, test and runner syntax checks passed. No optimizer fit, FA rerun or full package suite was run in this composition.

## 8. Apply and replay evidence

The final combined patch passes git apply --check against both the exact dirty original and current live candidate. Applying it to a fresh copy of its 23 original target files reproduces every composed target hash. final-combined-apply-check.json records the checks; final-replay-targets/ contains the replay. A separate h2-composition-delta.patch records the transition from the tested 481-assertion state. h2-prose-corrections.patch isolates the required prose corrections.

## 9. Final pins

Combined patch SHA256 `82023fbcad6983e061435b6361c37c55733cc2efb38a2a761829b5d227944c77`.

Composed source tree `2ec4bdfe2d1ecc36a6cf73bbc834c9016fef2ffd960bae2d799038cc24c3685c`. Payload parser `9d389444008a25ddfb3ba140836bab5a3d2c8ebfb94052424d8d1ac6c0c5a3e9`. Runner `4da75986ff69040a2c8353e743fd98c336c66848c8ccb8c4cc5ac6472fdbaa23`. H2 test `6ef180997073e24708df93f1fbdd400413d140875d0aa85806649be3fe9e9986`. All original/result/input/test/log pins are in composition-inventory.json. Baseline combined patch, inventory and receipt are retained separately.

## 10. Limits and remaining work

This PASS covers isolated composition and focused checks. Independent final composition review, live application, full package checks and the A2 panel remain parent-owned work. The unchanged FA engine retains its previously measured source pin and campaign evidence. No fitted-capability status, public coverage count or release gate changed. Generic production bridge support is not established by these repairs.

## 11. Handoff

Deliver combined-repairs.patch, composition-inventory.json, this receipt and the raw focused/h2 logs for parent review and application. The scratch original and composed directories preserve the exact dirty baseline and reviewable result. All patch inputs and the h2 prose delta are retained for audit.
