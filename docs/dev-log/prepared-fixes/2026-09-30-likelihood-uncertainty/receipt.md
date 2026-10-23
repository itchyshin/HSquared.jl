# Likelihood uncertainty isolated repair

Date: 2026-09-30. Revision 2. Verdict: PASS for the scoped implementation and deterministic checks; independent recheck and live integration remain pending. Noether reviewed revision 1 and found the derived-step bypass repaired here. The review filename contains astra but does not establish an Astra model invocation.

## 1. Goal

Prepare fixes for LH-05 selection, LH-06 denominator consistency, LH-07 uncertainty input rejection, and LH-09 three docstrings. No whole-file approval is given.

## 2. Base and ownership

Copied the current dirty source from HEAD `6271cfd58651e69cd27a64dcf02cb8960a29e260` with engine tree `2ec4bdfe2d1ecc36a6cf73bbc834c9016fef2ffd960bae2d799038cc24c3685c`. Original likelihood SHA256 `90cc76897c2b977f4bebc456d1e6c8d8f2647a7bb7ec6e8c9135884da0f17e30`. Work is confined to this scratch directory. The parent owns live integration and the other lanes' work.

## 3. Implementation

LH-05: both summed-ratio public routes and the internal covariance-derived helper require a nonempty collection of unique integer component indices; Boolean entries are invalid. Values stay in their existing order.

LH-06: the reported full-denominator ratio is retained, and inactive components are held at their supplied values. Its active-coordinate gradient uses total, not subtotal. math-contract.md derives the conditional information and gradient independently.

LH-07: finite positive fd_step is checked before dense fitting, finite-difference evaluation or covariance arithmetic. Variances must be positive and finite in their original and Float64 forms; the represented total must be finite. Malformed inputs throw before a ratio rail or unavailable-information result can hide them. Valid near-zero components retain the existing unavailable-information behavior. A shared component-step helper now rejects derived overflow or underflow before the summed-ratio rail return, and the covariance ingress and FD core use the same helper.

LH-09: average information is distinguished from observed information; the K-effect MME precision uses Ainv_i/sigma_i; optimizer convergence does not certify identifiability. Related boundary and input prose describes the repaired contracts.

## 4. Files changed

Only src/likelihood.jl, a new test/likelihood_uncertainty_contract_regression.jl, and an appended scoped include in the copied test/runtests.jl are patch targets. Existing runner bytes are preserved exactly. Reversing both recorded edit layers reconstructs the original source. The reviewed full-denominator ratio function is byte-identical to revision 1. Its original 2367-to-end suffix and all other source files are unchanged.

## 5. Red evidence

Tests were written before implementation. The first baseline run exposed an unsuitable positive control whose observed information was not positive definite. A small supplied-point discovery checked nine scale/variance pairs without fitting, and the corrected fixed fixture used scale 2 and supplied components 1. The corrected baseline run recorded 87 PASS, 105 expected FAIL, zero errors, exit 1. All nine valid covariance/boundary controls passed before implementation. Raw logs are retained. Revision 1 source, test, runner, patch, inventory, reports and logs, plus the independent Noether review, are preserved under revision-1/. The 22 new derived-step probes against revision 1 gave 18 PASS and 4 expected FAIL, zero errors, exit 1: overflow and underflow both bypassed validation only on the summed-ratio rail.

## 6. Green evidence

The revised isolated source passed the original 192/192 checks in 6.7 seconds and the new 22/22 derived-step checks in 0.3 seconds, total 214, exit 0. revision-green.log records both testsets. Estimate before the small runs: under one minute each. Julia and BLAS were capped at one thread, offline, with compiled modules disabled. The regression runs direct helpers and supplied-variance sparse likelihood points on 48 records, with no fitter, optimizer or recovery campaign. Final source/test/runner syntax checks also passed.

## 7. Independent controls

The accepted boundary_tol=.2 counterexample now reports estimate 1/3 and SE sqrt(20)/36, agreeing with central derivatives that leave the inactive coordinate fixed. Interior and exact-zero controls retain their analytic answers. Summed ratios use an independent analytic gradient and match under reversed unique selection. Invalid original tiny negative, converted tiny positive, huge finite BigFloat and nonfinite inputs exercise both public routes and covariance ingress. The finite-difference quadratic gives identity information, and invalid fd_step calls never evaluate its objective.

## 8. Patch and replay

likelihood-uncertainty-fix.patch SHA256 `ab3c98610c0a735aea7712521ad7ddf4cb7c6fc547f16af43ffadc15eaf029b8`. Apply-check passed against the dirty snapshot and the current live candidate. Replay reproduces all three target hashes. revision-2-delta.patch isolates the source guard and added tests relative to the archived first revision. inventory.json records original/result/test/log pins. The test include is inside E1LikelihoodUncertaintyContracts and appears once.

## 9. Source and test pins

Prepared likelihood `342b029fa482cbb9101f2f924badca31ebdec7b8f8838facb96bb0317d013f7c`. Regression `88af1ddd7943a59965708926f11ebc131021fae82f2c6c7f536f3ccf7f3c46bc`. Prepared runner `a577a86765a267001d2e8d806c0ddcea37dc87812e3ec16770c6daee6b897f32`; original runner `4da75986ff69040a2c8353e743fd98c336c66848c8ccb8c4cc5ac6472fdbaa23`.

## 10. Residual findings

LH-01 sparse final status/rank/boundary, LH-02 scalar fitted-input ingress, LH-03 supplied MME model/numeric domain, LH-04 dense two/K model ingress, and LH-08 nonconverged uncertainty/failed-point diagnostics remain open. The unchanged later half of likelihood.jl is not approved by this repair. Finite inputs and a positive-definite supplied-point covariance do not establish calibration, identifiability, convergence or production scale. No status or coverage count changed.

## 11. Handoff

Deliver the pinned patch, inventory, this receipt, unchanged math-contract.md and raw revision logs for the parent's bounded independent recheck. No live source, test or runner was edited. No release, remote compute or external action occurred. Graft caller/skeleton queries preceded source reads and reported estimated savings of 425801 tokens; refresh could not write the source graph cache, so exact hashes and source coordinates govern the patch.
