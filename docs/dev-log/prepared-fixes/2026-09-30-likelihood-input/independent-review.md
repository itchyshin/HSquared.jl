# Independent review: likelihood input proposal

## 1. Goal

**Bounded PASS for the input component** at proposed likelihood SHA `d098830fc70ee02f781b1b0838f3ea497b38688bdca6244af9d3d4fd21ab3c0c`. No blocking regression found in its declared scope. This is independent review of Gauss's input/finite-result patch; reviewer authored a separate, disjoint profile/PEV patch. Whole-file inference approval is not conferred.

## 2. Implemented

No engine edits. Reconstructed the submitted source and regression from exact baseline `90cc76897c2b977f4bebc456d1e6c8d8f2647a7bb7ec6e8c9135884da0f17e30` by applying the exact unified patch in a separately owned scratch project. Reviewed all source mutation groups, validator callers, ingress/final-result logic and author declarations. Added independent analytical challenges.

## 3a. Decisions and Rejected Alternatives

Dense covariance accepts a positive representable Float64 variance even if its reciprocal overflows. Precision-based paths additionally require a finite reciprocal. Independently tested `nextfloat(0.0)` in both variance positions and both together for a zero-response, zero-fixed-column Gaussian model. Supplied MME permits saturated full-rank fixed effects, unlike REML estimation. QR/SPD numerical policies are inherited from signed iterative helpers and not redesigned.

Used direct block-equation solves and diagonal marginal Gaussian formulas as independent oracles. No statistical campaign or broad suite was needed to resolve these bounded contracts.

## 4. Files Touched

Only this report and `/private/tmp/hsq-likelihood-input-independent-20260930/` were written. No author proposal, live source, live test or runner was edited. Exact pins:

| Artifact | SHA256 |
| --- | --- |
| `/private/tmp/hsq-likelihood-input-fix-20260930/receipt.md` | `f3e8d612a73c650349f9678a296b26d53014e25d808ce71c2cfc0967e2552ed0` |
| `/private/tmp/hsq-likelihood-input-fix-20260930/likelihood_input.patch` | `bf52fa761fb392dd754ca3f316235676bf6fe8d860214a43a1e320c7c0f901a3` |
| `/private/tmp/hsq-likelihood-input-independent-20260930/src/likelihood.jl` | `d098830fc70ee02f781b1b0838f3ea497b38688bdca6244af9d3d4fd21ab3c0c` |
| `/private/tmp/hsq-likelihood-input-independent-20260930/test/likelihood_input_guard_regression.jl` | `84e555a68c4c6b4a360583c9fd5400ecb9af98adbc0e40e5baf9dd68f72659a9` |
| `/private/tmp/hsq-likelihood-input-independent-20260930/independent-challenges.jl` | `2820062472f863802bafad7a5b2954e1f3da6686dc181582d2eb97e857ac1655` |
| `/private/tmp/hsq-likelihood-input-independent-20260930/regression-replay.log` | `71acaa7f80c75c5f39fb2e27c1962fdd34234a3770b4fa25c6d0e950c2ef4f9a` |
| `/private/tmp/hsq-likelihood-input-independent-20260930/independent-challenges.log` | `07d964cffabb9dfc2812952e2d9a200b9dd773e6d00b66272d88b1ba037186d5` |
| `/private/tmp/hsq-likelihood-input-independent-20260930/replay.json` | `9be19bfa287067d52f3df83879de1e1d6fd09d07e4806a792cbadf4885f33469` |
| `/private/tmp/hsq-likelihood-input-independent-20260930/scope-check.json` | `83abb1cda21916ccada0fbaa69efe1025d7ac4b59a9cb7ebfe07666a2a17b342` |

## 5. Checks Run

Verified all 48 entries of author SHA256SUMS, whose hash is `c5d89949b7a456e49a47a3afa9c12b04f9bde8155f75a99de000c3ae02575bdc`. Patch application independently reproduces source and regression byte for byte. SequenceMatcher independently finds 75 mutation groups and no changes inside nine reserved baseline span ranges. Live likelihood was remeasured unchanged at baseline90cc.

Author regression independently replayed **202/202**, exit0, 28.43s including startup. Independent challenges **97/97**, exit0, 26.04s including startup. Julia1.10.0, Julia threads1, BLAS threads1. First estimate under2min; second under1min; both completed within estimate and explicit timeout. The author regression includes only three-record fits capped at one iteration; independent challenges contain no optimizer fit. Commands use `--compiled-modules=no --startup-file=no --project=.` and depot `/private/tmp/hsq-goal-julia-depot:/Users/z3437171/.julia`.

## 6. Tests of the Tests

Author retained baseline red96pass96fail and revised red96pass90fail, compatibility regression190pass1error, and metadata200pass2fail; their hashes all verified. The initially overly restrictive dense variance expectation was corrected with a valid neighboring control and disclosed. Final test differs from earliest frozen test, with each subsequent compatibility/metadata amendment documented and red evidence retained. This supports the bounded repaired contract without pretending one unchanged test file covered every refinement.

Independent challenge expectations derive from C=[X'X/e X'Z/e; Z'X/e Z'Z/e+Q/a] and diagonal Gaussian likelihood. Ordinary and saturated cases check numerical effects separately from IDs. Tests exercise valid dense values at Float64's smallest positive number, and verify rejection on corresponding reciprocal paths. No mutated tests or hidden broad campaign were used.

## 7a. Issue Ledger

| Scope | Independent disposition |
| --- | --- |
| LH02 finite converted y/X/Z and rank | PASS on declared14 routes through author regression; independent NaN/conversion-overflow probes on7 routes |
| LH03 supplied precision, IDs, final solve | PASS; direct equation oracles for p0,p1,saturated scalar/two/K, order preserved |
| LH04 dense two/K inputs/starts | PASS within declared finite domain; no generic reciprocal narrowing |
| LH10 supplied K likelihood finite output | PASS; finite checks and reciprocal policy appropriate |
| LH15 direct-maternal/repeatability ingress | PASS for declared guards; old allocation and derived-correlation limits remain separate |
| LH01 sparse fit finite/rank and scalar-AI update | PASS for narrow repair; stationarity and closed-boundary inference not certified |
| LH05–09,LH11–14,LH16–17 | Outside component or separately assigned; no closure inferred from this review |

## 8. Consistency Audit

`_coerce_supplied_variance_components` callers are fit_animal_model's Henderson target and matrix-free fitting. Its reciprocal requirement does not enter a dense covariance route. Generic dense starts use `_coerce_initial_variances` without reciprocal narrowing. Canonical Q is carried consistently into computations and stored specification. Independent nearly symmetric Q control matches the explicitly averaged Q and dense/sparse likelihood; IDs remain in original caller order.

Array validation is on converted Float64 arrays; ordinary NaN/Inf inputs and finite BigFloat overflow are rejected. Variance validation checks original Real values and converted positivity/finite range. No guarantee is claimed for adversarial user-defined numeric conversion semantics. Signed rank/precision helper bytes are unchanged in the copied iterative source `a4adfe04fe736fd55039b329d9d1d1fa4083b02478dc33c60181c7c453c42132`.

Scalar AI recomputes final likelihood at the retained variance after a rejected update. The public false-convergence result remains finite when that retained calculation is representable. Earlier-iteration score/step diagnostics can still describe a previous point on iteration exhaustion; they are not final-point stationarity certification. Arithmetic beyond Float64 range may throw a clear range error instead of returning a failed-fit object. Neither behavior is misrepresented by the bounded receipt.

## 9. What Did Not Go Smoothly

No independent numerical test failure occurred. The report checker first rejected a missing hyphen in its required section12 heading; corrected and rerun. Graft's graph-refresh lock was permission-denied; cached caller information was checked against source and exhaustive literal lookup used for overloaded coercers. Graft reported total estimated tokens saved462070 across current-review queries. This metric is tooling only. Some log/source excerpts were truncated by output budgets; substantive checks used exact files and source ranges.

## 10. Known Residuals

This review does NOT cover optimizer score-stationarity, closed variance boundaries, conditioning guarantees, uncertainty calibration, full likelihood approval, performance, GPU behavior, or release readiness. The author leaves direct-maternal correlation arithmetic, cap-product overflow, profile/PEV and uncertainty helper changes to their assigned lanes.

Original-fit bootstrap convergence/finite-parameter validation, broad bootstrap/plot exception catches, replicate failure reasons and one-survivor interval policy remain unresolved. Refitted-bootstrap acceptance repair in the separate proposal is not original-fit validation. Direct-maternal likelihood-convention metadata and legacy payload provenance remain separate debts. The retained mixed-iterate diagnostic limitation is explicit; the final reported variance/likelihood pair is recomputed consistently.

## 11. Team Learning

A guard shared between optimization and supplied equations must preserve their different mathematical domains. Positive covariance variance and representable reciprocal precision are distinct contracts. Independent saturated-equation and extreme valid dense controls prevented permissive-input fixes from becoming unintended input restrictions.

## 12. Cross-Product Coverage

Total independent execution299checks:202 submitted regression plus97 independent challenges. Seven malformed-array routes, scalar/two/K equation oracles at p0,p1,p=n, two dense variance positions at nextfloat0, both-tiny dense p0 covariance, canonical near-symmetry, nonalphabetic IDs and explicit finite-arithmetic failure messages. The proposed runner include `likelihood_input_guard_regression.jl` is appropriately scoped; no runner was edited here. Parent composition remains a separate integration check.

This scoped component review does NOT cover interval calibration, large or ill-conditioned models, mutable-input concurrency, public payload expansion or the later composed source.

### Separate subsequent composition check

Bounded PASS for deterministic composition at source `5219cf48be1933a01afe4bb5ba40278d4610b455b5fd7d85a078ce2947c10e57`. Independently derived all112 mutation groups from the three exact source proposals, verified disjoint baseline spans, matched the parent inventory after coordinate sorting, and simultaneously replayed them to the exact composed bytes. Parent's composed log `31a09365daff67f67c477029a36e490ac1f30c5b78847bcdbb96a5c794c6a220` records514passing checks (202input+214uncertainty+98profile); I verified that log's pin and counts without rerunning its numerical checks. Composition patch `ef090df9a6bc700ffbd2d5c5fab98ff7a7673bb0f735ffa530dfdf9bcc9904fa` also matches its receipt. Evidence: `/private/tmp/hsq-likelihood-input-independent-20260930/composition-independent.json`, SHA `ec43bc28b2cc31e338c1416c8ef2770c077036b3db24e374cf9e6a6ae1c08427`. The first direct inventory comparison failed because parent groups entries by component whereas my derived list sorted by coordinate; sorting both demonstrated identical content. This check does NOT cover new statistical validity or whole-file inference approval.
