# Likelihood uncertainty isolated repair

Date: 2026-09-30. Verdict: PASS for the scoped implementation and deterministic checks; independent review and live integration remain pending.

## 1. Goal

Prepare fixes for LH-05 selection, LH-06 denominator consistency, LH-07 uncertainty input rejection, and LH-09 three docstrings. No whole-file approval is given.

## 2. Base and ownership

Copied the current dirty source from HEAD `6271cfd58651e69cd27a64dcf02cb8960a29e260` with engine tree `2ec4bdfe2d1ecc36a6cf73bbc834c9016fef2ffd960bae2d799038cc24c3685c`. Original likelihood SHA256 `90cc76897c2b977f4bebc456d1e6c8d8f2647a7bb7ec6e8c9135884da0f17e30`. Work is confined to this scratch directory. The parent owns live integration and the other lanes' work.

## 3. Implementation

LH-05: both summed-ratio public routes and the internal covariance-derived helper require a nonempty collection of unique integer component indices; Boolean entries are invalid. Values stay in their existing order.

LH-06: the reported full-denominator ratio is retained, and inactive components are held at their supplied values. Its active-coordinate gradient uses total, not subtotal. math-contract.md derives the conditional information and gradient independently.

LH-07: finite positive fd_step is checked before dense fitting, finite-difference evaluation or covariance arithmetic. Variances must be positive and finite in their original and Float64 forms; the represented total must be finite. Malformed inputs throw before a ratio rail or unavailable-information result can hide them. Valid near-zero components retain the existing unavailable-information behavior.

LH-09: average information is distinguished from observed information; the K-effect MME precision uses Ainv_i/sigma_i; optimizer convergence does not certify identifiability. Related boundary and input prose describes the repaired contracts.

## 4. Files changed

Only src/likelihood.jl, a new test/likelihood_uncertainty_contract_regression.jl, and an appended scoped include in the copied test/runtests.jl are patch targets. Existing runner bytes are preserved exactly. Reversing the 19 recorded source replacements reconstructs the original source. Its original 2367-to-end suffix and all other source files are unchanged.

## 5. Red evidence

Tests were written before implementation. The first baseline run exposed an unsuitable positive control whose observed information was not positive definite. A small supplied-point discovery checked nine scale/variance pairs without fitting, and the corrected fixed fixture used scale 2 and supplied components 1. The corrected baseline run recorded 87 PASS, 105 expected FAIL, zero errors, exit 1. All nine valid covariance/boundary controls passed before implementation. Raw logs are retained.

## 6. Green evidence

The isolated source passed 192/192 checks, exit 0, testset time 7.2 seconds. Estimate before the small runs: under one minute each. Julia and BLAS were capped at one thread, offline, with compiled modules disabled. The regression runs direct helpers and supplied-variance sparse likelihood points on 48 records, with no fitter, optimizer or recovery campaign. Final source/test/runner syntax checks also passed.

## 7. Independent controls

The accepted boundary_tol=.2 counterexample now reports estimate 1/3 and SE sqrt(20)/36, agreeing with central derivatives that leave the inactive coordinate fixed. Interior and exact-zero controls retain their analytic answers. Summed ratios use an independent analytic gradient and match under reversed unique selection. Invalid original tiny negative, converted tiny positive, huge finite BigFloat and nonfinite inputs exercise both public routes and covariance ingress. The finite-difference quadratic gives identity information, and invalid fd_step calls never evaluate its objective.

## 8. Patch and replay

likelihood-uncertainty-fix.patch SHA256 `b36a17ff71f3ab88e15b8ad1b55cb7df4ea37e13ba94e3fd4e3de3354db92b46`. Apply-check passed against the dirty snapshot and the current live candidate. Replay reproduces all three target hashes. inventory.json records original/result/test/log pins. The test include is inside E1LikelihoodUncertaintyContracts and appears once.

## 9. Source and test pins

Prepared likelihood `4662affd4eadb5651ac6870f860f2e506b13298a23ce85e5bf443d08bcab07f6`. Regression `4f8d491599ce975171cf54cecb78d6e2c90de7d355d60a4b8cf340865640faf9`. Prepared runner `a577a86765a267001d2e8d806c0ddcea37dc87812e3ec16770c6daee6b897f32`; original runner `4da75986ff69040a2c8353e743fd98c336c66848c8ccb8c4cc5ac6472fdbaa23`.

## 10. Residual findings

LH-01 sparse final status/rank/boundary, LH-02 scalar fitted-input ingress, LH-03 supplied MME model/numeric domain, LH-04 dense two/K model ingress, and LH-08 nonconverged uncertainty/failed-point diagnostics remain open. The unchanged later half of likelihood.jl is not approved by this repair. Finite inputs and a positive-definite supplied-point covariance do not establish calibration, identifiability, convergence or production scale. No status or coverage count changed.

## 11. Handoff

Deliver the pinned patch, inventory, this receipt, math-contract.md and raw red/green logs for the parent's independent review. No live source, test or runner was edited. No release, remote compute or external action occurred. Graft caller/skeleton queries preceded source reads and reported estimated savings of 425801 tokens; refresh could not write the source graph cache, so exact hashes and source coordinates govern the patch.
