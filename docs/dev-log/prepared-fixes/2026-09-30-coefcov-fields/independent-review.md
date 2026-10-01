# Independent coefcov parser patch review

Date: 2026-09-30. Reviewer: Curie. Reviewed scratch patch /private/tmp/e1-coefcov-fix-20260930/coefcov-field-validation.patch. No live source, schema, tests, primary driver, or repository state was changed. No numerical fit ran.

## Verdict

HOLD for the promised dense-Phi contract: one wrapped sparse input bypasses the new guard and is densified. The remaining reviewed shape, value, metadata, and dispatch changes pass this narrow review. Correct the sparse guard and add a regression before claiming complete closure of the enumerated parser defect. The coefficient fitting route remains unwired regardless of this repair.

## Confirmed behavior and contracts

Patched src/bridge_payload_v2.jl:152-191 reads and retains all six fields. Basis is raw or Legendre; order is a positive integer counting columns, with Boolean excluded. Phi must have Z's observation rows and order columns, real non-Boolean finite entries, and finite Float64 conversion. Covariate is a nonblank string. Bounds are required for Legendre and optional for raw; supplied bounds must be real, finite before and after conversion, length two, and strictly increasing after conversion. Covariance structure is unstructured or diagonal. The shape check precedes Int conversion, and numerical conversion is followed by finiteness validation.

The basis-column meaning agrees with schema lines 108-110, including order=2 as intercept plus slope. The conditional bounds requirement is newly made explicit in accompanying schema lines 117-127. It should land with the code as a contract clarification. Phi-to-basis reconstruction is not verified because original covariate values are absent.

The coefficient branch at patched lines 238-241 adds these fields to the resolved common block; common field/relationship checks remain before it. Existing correlated and independent branches remain unchanged. Dispatch and the Phase0NotImplementedError at patched lines 723-727 remain intact. Positive animal and two-effect parser controls pass; no fitted numerical route was tested. The R route, emitters, maternal result parsing, mixed coefficient/independent behavior, and general schema completion are outside this patch's closure.

## Concrete defect and minimal repair

Patched line 160 rejects AbstractSparseMatrix directly. Julia's Transpose wrapper around a sparse matrix is an AbstractMatrix without being an AbstractSparseMatrix. A parser-only independent probe supplied transpose(sparse([1.0 1 1; -1 0 1])) as the required 3-by-2 Phi. Julia reported issparse=true and abstract_sparse=false; the parser accepted it and returned Matrix{Float64}. This contradicts the dense-input contract and permits accidental densification.

Use a sparse-aware check such as !issparse(Phi_raw) before conversion. Add a transpose/adjoint sparse regression and any supported sparse-view form; retain acceptance of ordinary dense matrices/views. This finding concerns representation validation; no fit was run. Log: /private/tmp/e1-coefcov-independent-sparse-wrapper-20260930.log.

## Tests and integration scope

Estimate stated before execution: under 30 seconds, one Julia and one BLAS thread. I independently ran the isolated differential file in patched mode: 53/53 PASS, 1.9 seconds of test time, exit zero. The supplemental sparse-wrapper probe reproduced the bypass without a fit. The retained baseline copy matches the exact live parser; original receipt reports 8 passes and 38 expected failures, comprising 32 malformed inputs and six discarded fields. Existing tests meaningfully cover missing fields, domain/type/shape failures, Float64 overflow, supported bases and covariance structures, key encodings, preservation, and the frozen fit error.

The patch updates the prior coefficient-slot fixture and includes test_coefcov_fields.jl in the package runner. Dry git apply --check passed against the exact working tree without applying it. The isolated tests load a separate parser module; passing them does not certify the proposed package-runner include or the full suite. After repair and the freeze, land source, schema, fixture, and test registration together and run the focused integrated parser tests.

## Exact pins and preserved state

- Patch reviewed: d8d80fe075e4e70f713e905a1da7f1cb16f96ac2ad85e242fcd86b5ef54b791b
- Patched parser: fe9353bbfb75f4449ed83ed2266292484ed046017b940d912ee9ed9f60a5f3a7
- Repo-shaped test: e074829ca5a71d723fcb3a2c48bd260fba9d87a9a828669c4966c34819b046eb
- Isolated test: 44d17ddd97e262665edb569bb2618fb515365c060aeed5c4e3c196cf3a053d2d
- Baseline and live parser: 3f1c5eed39414860953898ec23e6a8cec622d90d7009f107519892b22b63a7e0
- Live schema: 02fe6d274d83b2c62ae972f11d32186c507e083ef19fcb1dd6702b514adb3e80
- Live test runner: b2d77c7f0937f5fcf0ed8ec32913c816b2c942f27c83825c8424107a5bc58b24

The parent-authorized validator-only HEAD advance does not change these source contracts. This review supplies no general E1 signoff, coefcov fit wiring, interval calibration, capability promotion, or release approval. Graft was consulted before detailed source review and reported 147,159 tokens saved; stale cache spans were replaced with exact scratch numbered coordinates.

## Repaired sparse-wrapper recheck

The original HOLD finding above is fixed in the following exact scratch artifacts; the original trace is retained for provenance:

- Corrected patch: ea88557d2533bc8bb5e2f0270eb825967e8622d32543188fedf959808403f72f
- Corrected parser: 9d389444008a25ddfb3ba140836bab5a3d2c8ebfb94052424d8d1ac6c0c5a3e9
- Corrected repo-shaped test: 45f9ebd3d4d65e7b4c2d3d394ef338f72efae648c1c7d448df7e48b92d2c9c4d
- Corrected isolated test: 2bafc4d75550d271dc9533b0f6ced56d7f4a8ea874b799f2c6c30553bc41121d

I verified these hashes before and after the check. Patched parser line 160 now requires AbstractMatrix and !issparse before materialization. New repo-shaped controls at test/test_coefcov_fields.jl:83-90 reject sparse transpose, adjoint, and view objects, asserting their sparse representation first. Lines 94-106 preserve matching dense transpose, adjoint, and view values and verify Matrix{Float64} output. The implementer's retained old-guard log reports 71 passes and three expected failures, isolating these sparse-wrapper rejection assertions.

Estimated before recheck: under 30 seconds with one Julia and one BLAS thread. I independently ran the expanded isolated suite: 74/74 PASS, exit zero, 2.1 seconds of test time. Log: /private/tmp/e1-coefcov-independent-repaired-test-20260930.log. Dry git apply --check also passes. No fitting, source application, or broader test rerun was performed.

Final verdict: PASS for the enumerated parser field and sparse-representation contract on these corrected artifacts. The earlier sparse-wrapper HOLD is resolved. Live source tree, parser, schema, and test-runner pins remain unchanged at the values recorded above. Fitting is still unwired; required bounds/field wording must land together with the implementation. Package-runner integration, general E1 signoff, maternal retesting, and the other earlier scope limits remain separate gates. No additional Graft query was needed for this targeted recheck.
