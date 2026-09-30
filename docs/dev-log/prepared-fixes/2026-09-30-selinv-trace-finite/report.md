# Selected inverse complete current source review and trace guard proposal

## Scope and verdict

All453 original lines in src/takahashi_selinv.jl were inspected on SHA38a07e2e34da2f4a295e52e25b1f1d067a0b7e1b2893bdef8c73f1f78c704782. Coverage PASS; numerical approval HOLD until the isolated trace repair receives independent review. This is a parent source review, with existing Gauss finite-inverse component approval reused at its exact pin.

## Disjoint original spans

| Span | Disposition |
| --- | --- |
|1-69|MIT sister provenance and selected-pattern derivation reviewed; performance figures remain historical named-fixture evidence, not new measurements. Exactness describes selected entries in exact arithmetic; finite precision conditioning remains a debt.|
|70-85|CSC sorted-row binary search and absent-entry sentinel inspected. Valid CSC internals are required.|
|86-225|Shared finite factor/pivot guards, reference dispatch, scatter/SIMD/merge/search branches, final finite guard reviewed against L-transpose-Z equation. Existing strict-order versus default numerical bounds stay unchanged.|
|226-260|Per-pair reference recurrence inspected; selected-pattern clique closure supports the looked-up entries; no numerical change proposed.|
|261-311|Symmetric sparse materialization and original-order diagonal extraction inspected against ch.p permutation convention. Existing nontrivial-permutation dense checks retained.|
|312-380|Single-block dimensions, permutation support lookup, structural-zero refusal and trace accumulation inspected. Missing finite weight/result guards confirmed.|
|381-453|Multi-block dimensions, offset conversion, one shared recursion and per-block support lookup inspected. Same finite weight/result gaps confirmed.|

## Confirmed finding

Finite selected-inverse entries do not ensure finite trace output. NaN/Inf weights, a finite BigFloat weight outside Float64 range, overflowing finite products, or overflowing positive accumulation escape from both exported trace helpers. The19-assertion no-fit regression reaches all12 bad cases and seven ordinary controls. Original source:7PASS/12FAIL, exit1. The prepared source requires original finite real and converted finite Float64 weights, then refuses nonfinite accumulated traces. Existing recursion and selected-inverse value guards remain byte-identical.

## Evidence and runtime

Before each launch, estimated runtime below30seconds, one Julia and one BLAS thread. Original and prepared sources loaded in a standalone module under Julia1.10, startup/compiled modules disabled. No fit, optimizer, campaign, remote compute or GPU ran. Prepared19/19 plus existing33/33 PASS, exit0. Existing tests include actual nontrivial factor permutation, independent dense selected entries and trace, unsupported sparse pattern/dimensions, failed factor and an overflowing inverse from a valid tiny SPD factor.

## Symbolic contract

The helper returns sum over stored Q[i,j] times C-inverse[offset+i,offset+j]. Every nonzero Q entry must lie in the selected inverse pattern; otherwise it throws. It restores the original coordinate ordering through inverse permutation. Q need not be positive definite for this linear trace helper. The repair therefore preserves finite negative weights and signed traces. It does not substitute zero for missing inverse entries.

## Retained limits

Support validation still occurs after the selected-inverse recursion; an invalid pattern can waste kernel work before refusal. Severe conditioning, high fill, sparse allocation/type stability, generalized factors and performance remain explicit debts. Cancellation after an overflowing Float64 product/partial sum is refused; no arbitrary-precision trace claim is made. The complete E1 panel, final integrated checks and public bridge acceptance remain open. This repair does NOT cover GPU, calibration, a capability promotion, submission or tag.

## Independent HOLD and revision2

Sol independently caught two consequences of converting a nonzero BigFloat weight to Float64 zero: an unsupported inverse pattern became a structural zero, and a small weight times a large finite selected-inverse entry lost its representable trace. Revision1 source/test/green logs and pins are preserved. Revision2 rejects nonzero weights that convert to zero before pattern checks or trace arithmetic. The visible docstring states this Float64 acceptance boundary. Actual Float64 subnormal weights remain valid and have positive-product controls. This is an explicit rejection of unsupported weight conversion, not arbitrary-precision trace support. The revised29 new assertions and33 existing assertions are estimated below30seconds before launch, one Julia and one BLAS thread. Independent revision2 approval remains pending.
