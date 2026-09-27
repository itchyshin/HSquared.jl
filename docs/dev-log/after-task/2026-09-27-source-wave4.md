# After-task: Julia source-review wave 4

## 1. Goal
Review post-fit, G geometry, plotting, validation status, backend, placeholder, planned-term, and GPU interface sources against baseline `faed40182cdbba2bf69f3e8dff0c5054be2dd214`.

## 2. Implemented
Scoped repairs addressed PSD/correlation geometry (E4-01/02, coordinator), misleading planned-term wording (E4-03), and the GPU stub's generic MethodError wording (E4-04). Planned-term regression passed 8/8; coordinator's final covariance regression passed 24/24. Whole-wave signoff remains **HOLD**; validation-status integration and panel review remain open.

## 3a. Decisions and Rejected Alternatives
Use scale-aware PSD checks plus normalized-correlation validation to handle unequal trait units. Scope unavailable-language messages to reserved formula terms and point to existing direct Julia utilities. Describe GPU as a static interface only; no device run or performance claim was made.

## 4. Files Touched
Review packet: `docs/dev-log/source-review/2026-09-27-wave4.md`. Coordinator fixes recorded there: `src/evolvability.jl`, `src/multivariate.jl`, `src/planned_terms.jl`, `src/gpu_ext.jl`; regressions: `test/wave4_covariance_contracts.jl`, `test/wave4_planned_term_wording.jl`, plus integration/status work. This report records the review only.

## 5. Checks Run
Packet reports planned-term test red before and 8/8 after; coordinator's final covariance suite 24/24 (the initial packet cited 23/23 before later near-PSD fixtures). Static source/interface inspection was bounded. No full GPU test, R route, simulation, or package-suite run belongs to the review packet.

## 6. Tests of the Tests
Geometry tests include tiny and unequal trait scales, legitimate near-zero numerical PSD matrices, rank-deficient PSD matrices, and refusal of animal-only uncertainty for repeatability fits. Planned-term tests verify unavailable formula terms and direct utility pointers. No test demonstrates device execution.

## 7a. Issue Ledger
E4-03/04 repaired. E4-01/02 coordinator repairs are not independently numerically signed off by this reviewer. `src/validation_status.jl` wording/generated-page integration remains with coordinator. Drawing extension behavior, numerical fitters, and validation evidence bodies remain outside reviewed spans.

## 8. Consistency Audit
Scoped PASS for post-fit delegation, plotting stubs/docs, backend metadata, and inert placeholders. Static cross-check showed CUDA weak dependency and extension methods correspond to generic declarations; `HSControl` reports execution unavailable/planned. Bounded R FA/GLLVM source paths do not call reviewed stubs. This is not runtime evidence.

## 9. What Did Not Go Smoothly
Graft had no graph and could not create its cache. Exact numbered source reads were used. Existing near-PSD expectations required adding explicit legitimate-roundoff cases to the final coordinator geometry suite.

## 10. Known Residuals
Whole-wave and Rose signoff remain open, including validation status integration. No GPU execution, device agreement, speed, live R-Julia parity, or numerical fitter certification is claimed. Public covered count remains seven per check-log.

## 11. Team Learning
A global covariance scale can mask an invalid correlation when trait units differ. Check normalized geometry as well as the raw covariance, and retain legitimate near-PSD cases in the same regression set.

## 12. Cross-Product Coverage
This wave covers the scoped Julia extraction/support paths and static bounded R source checks described in its packet. It does NOT cover runtime GPU behavior, Makie drawing behavior, live R-Julia parity, or unreviewed validation evidence. No GPU execution claim; whole-wave HOLD remains.
