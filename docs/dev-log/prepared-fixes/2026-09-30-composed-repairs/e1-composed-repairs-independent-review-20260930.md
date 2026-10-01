# Independent final composed repair review

Date: 2026-09-30. **PASS for the isolated composition and its focused checks.** No full E1, A2, V3, capability, bridge-production or release approval follows from this verdict.

## 1. Scope and ownership

Reviewed `/private/tmp/hsq-reviewed-repairs-composed-20260930/`: thirteen pinned inputs, the combined patch, 23 changed targets, registration, overlapping guards and final h² prose. Wrote only this report and the independent runtime log. Preserved all live files and other lanes' work.

## 2. Exact baseline

The original snapshot and current live Julia source both independently hash to `d3c2de8d7f0a1a86918f15938264bbdc892a7303b5ddd488553ac923f073ad0a`, before and after the check. Current live HEAD is the announced source-neutral `6271cfd58651e69cd27a64dcf02cb8960a29e260`; the packet snapshot HEAD is `3d6d7ffc961b65fa5a44ce277a7d1168ba69b6fe`.

## 3. Final artifact pins

- Combined patch: `82023fbcad6983e061435b6361c37c55733cc2efb38a2a761829b5d227944c77`.
- Inventory: `e15eca420ae00e0dba042c6dead059a98e47d518e6b335fa4ed4bc501b9d6b6e`.
- Composed source tree: `2ec4bdfe2d1ecc36a6cf73bbc834c9016fef2ffd960bae2d799038cc24c3685c`.
- Runner: `4da75986ff69040a2c8353e743fd98c336c66848c8ccb8c4cc5ac6472fdbaa23`.
- Independent runtime log: `13d6bcfa6394b814586b8c8d095067e4c37f4d4234732df913a26731ff0aabd0` at `/private/tmp/e1-composed-repairs-independent-check-20260930.log`.

## 4. Input and replay checks

All thirteen input hashes match both their retained snapshots and their current source artifacts. All 23 original/result/replay pins match the inventory. Independently parsed and replayed every unified patch hunk in memory against the original file bytes; all 23 reconstructed target hashes equal the composed targets. Independently reran `git apply --check` against both the exact original snapshot and current dirty live candidate: exit zero for both. The eight source files, six documentation files and nine test files are the complete patch target set.

## 5. Protected evidence

Original, composed and live copies agree for Project/Manifest, weak-direction tests, old payload parity tests, `src/multivariate.jl` (`fc41aefefb61b2cc915d4f802b0017dc4daea5daa795a9d3421854e9c4958670`) and the 200-seed driver (`2161449e2e320a6d56bf5b71b1927e18b3d3b4dd60704d30bae5aaafbf057e9b`). Existing weak runner entries remain. The runner diff retains prior content apart from the approved marker and coefficient controls, followed by the declared registrations.

## 6. Composition overlaps

Both GLLVM entrypoints retain record-family rejection immediately before mode-input validation (`composed/src/genetic_gllvm.jl:287–288,670–671`). Both guard suites execute successfully together. The shared finite Gaussian constructor now throws before tuple creation; the C1 fixture explicitly tests those constructor errors (`composed/test/gllvm_input_guard_regression.jl:28–30`) and retains valid scalar/vector and dense Gaussian comparisons. Its count changes from 50 to 48 because constructor assertions replace duplicated route assertions.

Non-Gaussian finite constructors, shared finite-count validation, improper-endpoint rejection, the objective docstring and h² helpers coexist. Endpoint rejection remains before numerical mode work (`composed/src/nongaussian.jl:644–664,714,922`). The approved h² source tail, beginning `_h2_finite_real`, is byte-identical to the final approved h² proposal after reversing the logged source prose replacements. Forward application of every prose-delta entry exactly reproduces final source and doc19; no arithmetic alteration is hidden in those replacements.

## 7. Registration and status

All eight focused test filenames occur exactly once in the final runner; seven declared module scopes were appended and the existing coefficient registration remains once. The sequential runtime command loads the earlier focused check file then the h² test through an absolute path in a fresh module. Runtime validation ID/status equality passes; both documentation ledgers retain their complete ID/status signature columns. The validation-status source equals the previously approved wording source `1d1d444bea3a5dc7a2dfccf5549b4d3082acfe3bf48761fe203a9d5f993c5316`, so covered status history and public count 7 remain.

The combined schema retains coefficient bounds/fields, the covariance `kron(G_dm,A)` versus precision `kron(inv(G_dm),Ainv)` distinction, default independent maternal versus explicit correlated adapter, and trait/component ordering. The R reader repair is separate; no R runtime was tested here.

## 8. Independent one-process runtime

Estimate stated before launch: under two minutes. Ran Julia 1.10.0, one Julia thread, one OpenBLAS thread, startup disabled, compiled modules disabled, existing composed Manifest and approved depot. Single process exited zero, **651/651 assertions passed**:

| Suite | Pass |
| --- | ---: |
| Syntax / status | 16 / 2 |
| GLLVM input / descriptor | 48 / 50 |
| Coefficient / RR / data | 74 / 41 / 29 |
| Flat endpoints / finite ingress | 35 / 141 |
| Existing marker testset | 45 |
| H² descriptors | 170 |

This reruns all 481 earlier assertions against the final h²-containing composition, then runs all 170 h² assertions in the same process. It resolves the builder's explicitly qualified 481-plus-170 evidence gap. Cleanup assertions also completed without an error. No optimizer fit, campaign, additional seed, package update, remote or GPU work ran. The supplied checks include bounded Gaussian mode/reduction calculations and synthetic fit descriptors.

## 9. H² interpretation qualifications

Final source/doc19 state a theoretical population projection bound [0,1] when observation variance is finite and positive, allow zero genetic variance, and distinguish finite quadrature from exact population moments (`composed/src/nongaussian.jl:1629–1632,1832–1837`). Binary probit ordering is non-strict, allowing equality at zero genetic variance (`:1746`; doc19:152–157). Gamma trigamma is conditional `Var(log Y | eta)`, including returned caveat/comment and historical fixed-eta receipt (`:293,1777,1797`; doc19:174,198–208).

The public docstring correctly requires zero supplied fixed spread for conditional Gaussian h², defines V_fixed as additional fixed-predictor spread with zero genetic/fixed covariance and a normal approximation, and distinguishes common trial vectors from genuinely varying denominators (`:1840–1859`). These match the approved arithmetic guards and the passing scalar/fit, tiny original-domain, common/varying trials, zero projection and independent moderate-logit controls. No new estimand or numerical claim was introduced.

## 10. Exclusions and residual gates

Only the approved G1 marker-domain change is added to frozen genomic source: its original-sign guard and converted nonnegative additive domain. Genomic G2–G6 rounding/label/statistics repair is absent and remains separate. General improper-integral/design separation and outer-failure handling, rank/conditioning and basis provenance, whole-source calibration, comparator/inference debts, full package/documentation checks, live application and broader A2/R/whole-wave review remain open. None is closed by 651 focused assertions.

## 11. Handoff and checking

Parent may use the pinned packet for the next authorized integration step. Recheck live target hashes immediately before applying; preserve frozen FA evidence. This report supersedes only the composition runtime gap, and retains all earlier bounded repair dispositions. Used prior exact review context and supplied artifact spans; no new broad source read or Graft query was needed. Absolute-path slop check completed with zero findings and zero style hits.
