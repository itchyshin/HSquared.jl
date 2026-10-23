# After-task: Julia source-review wave 3

## 1. Goal
Review input and public bridge paths against baseline `faed40182cdbba2bf69f3e8dff0c5054be2dd214`, with attention to pedigree ordering and honest route errors.

## 2. Implemented
The coordinator repaired W3-01 by aligning payload pedigree covariance and diagonal metadata to supplied incidence-column IDs, including the legacy alias. It separately narrowed the unwired-route error wording and added a regression for W3-02. Hopper's follow-up repaired missing legacy maternal labels (W3-03) and lone-iid animal dispatch (W3-04), while the R bridge gained an explicit multivariate ID-order guard. The packet's whole-wave verdict remains **HOLD** pending integration and review of remaining spans.

## 3a. Decisions and Rejected Alternatives
Preserve caller incidence order by permuting the normalized pedigree relationship objects, with an already-sorted fast path. Do not imply all model fitting is absent when only a requested payload route is unwired. The review did not broaden into unrelated data diagnostics or fitter internals.

## 4. Files Touched
Review packet: `docs/dev-log/source-review/2026-09-27-wave3.md`. Coordinator edits recorded in packet: `src/bridge_payload_v2.jl`, `src/errors.jl`, `test/wave3_payload_pedigree_order.jl`, and associated integration. This report records bounded review evidence only.

## 5. Checks Run
The dedicated unsorted-pedigree regression progressed from 2 pass/1 fail, through a legacy-alias mismatch at 6 pass/1 fail, to 11/11 after both fixes. `git diff --check` passed. A direct existing parity test could not start because JSON3 is test-only and unavailable under the package project. No live R-Julia parity or package suite is claimed.

## 6. Tests of the Tests
The regression checks the covariance in observation space against an independently permuted pedigree oracle, includes inbred self-relationship, preserves sorted input, and rejects missing/duplicate IDs. The route-error regression checks scoped wording and supported direct-fitter guidance.

## 7a. Issue Ledger
W3-01's targeted repair needs final candidate integration. W3-02's separate regression was added by coordinator but is not certified by the packet's focused command. Post-packet no-fit tests passed 29/29 for pedigree ordering, maternal labels, reordered `ids2`, and lone-iid refusal; unsorted R/Julia pedigree ID parity passed without a fit. The v2 result-shape mismatch (W3-05) remains open. Other source spans remain uninspected.

## 8. Consistency Audit
Scoped checks found pedigree normalization and inverse use the same parent-first order; R source sorts IDs before constructing `Z`; FA/GLLVM call direct fitters rather than the payload-v2 multivariate dispatch. These are source arguments, not proof of all R-Julia parity cases. `HSData` and `AnimalModelSpec` were confirmed not to hide the new bridge route.

## 9. What Did Not Go Smoothly
The test-only JSON3 dependency prevented direct invocation of an existing payload parity test under the package project. Default precompilation also could not create a pidfile in this sandbox; no-compiled-modules probing succeeded. Graft cache creation was blocked.

## 10. Known Residuals
Pedigree/data numerical and diagnostic regions, multivariate/GLLVM numerical bodies, full R bridge/extractor behavior, live parity, and full-wave specialist signoff remain open. The candidate commit was not pinned by this packet.

## 11. Team Learning
Whenever a covariance is normalized into another ID order, validate and apply the same permutation to every ID-indexed object that reaches the model, including covariance and metadata.

## 12. Cross-Product Coverage
This wave covers scoped Julia payload ordering and static R source alignment. It does NOT cover complete R-Julia parity, all pedigree normalization cases, numerical multivariate/GLLVM internals, or full-wave signoff. HOLD remains.
