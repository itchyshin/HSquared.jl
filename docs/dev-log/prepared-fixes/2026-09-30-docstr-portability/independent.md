# Documentation content portability: independent review

## 1. Request

Review the frozen two-test repair for the current Julia documentation representation failure. No live writes or statistical fits were authorized or performed.

## 2. Ownership and baseline

Independent reviewer: actual Sol reviewer with Gauss and Rose lenses, separate from the author. Candidate HEAD verified `ec9414c35d7621c6bd4321a9d16067ac9a2ea2eb`. Owned outputs are this receipt and `/private/tmp/e1-docstr-contract-independent-review-20261001-probes/`. Parent owns integration, evidence refresh and hosted acceptance.

## 3. Exact packet

Author root: `/private/tmp/hsq-docstr-contract-fix-20261001/`.

- Receipt: `532ebbe3a7875aa0fbbd30e5e5b3e9cdbdde6a9cc2a1b73a30da51e726ba6c10`.
- Pins: `e4d9d8dbb5b49c9a5f502cf54a3379c33bb0b18a50d08c2e37ac38da61282607`.
- Patch: `c818a18f2cc0e428709f213a07ff02c8a4f9fee72c1395d564c11454ca6d2d88`.
- Prepared runner: `27b7adbfe0b1c8d397e9041710fe713410d6692d9ef8ebf50af4354a0429adf3`.
- Prepared API test: `3a3afbfbfb1cf3f81566b8cdb7871dd874b73c4481736a8f097fda8dd3215299`.

All 48 file pins match. Patch replay in owned scratch reproduces both prepared files byte for byte. Original runner `095f584c0a78e4f51fc34f37f1feb81f314c45831bd24f5e7bdec4ffdc30ea97` and API test `11aef2709edc07e7c4497e763e77868a66b7c0c9bf551700e0820a9b8c20a068` match current live bytes.

## 4. Failure mechanism

The provided hosted log records the exact unsupported-route documentation phrase assertion failing because `string(@doc fit_payload_v2)` becomes a `Base.Docs.DocStr` storage representation with an escaped newline. A fresh independent Julia 1.13.1 process reproduces this: exit 1, zero pass, one fail, 3.09 seconds. The documentation reader causes this assertion failure. The unsupported fitting refusal remains separate.

## 5. Supported API

Shipped Julia 1.13 `base/docs/Docs.jl:847-856` specifies that `Docs.doc` requires loaded REPL on Julia 1.11 and newer. `REPL/src/docview.jl:209-257` implements binding lookup, parsing, concatenation and the object convenience method. The patch imports the existing REPL standard library and uses `string(Base.Docs.doc(...))` at both readers. The resulting value is parsed Markdown, with paragraph content preserved. No Project or Manifest change is needed or proposed.

## 6. Contract preservation

Every original assertion line remains byte identical. The unsupported `coefcov` dispatch still must throw `Phase0NotImplementedError`, preserve the exact refusal phrase and avoid an inaccurate multi-block explanation. The documentation must contain the same exact phrase. The animal-model help checks retain all implemented-method and unimplemented-language assertions. No whitespace normalization is added by the proposal. All source pins and environment pins are unchanged.

## 7. Neighbor sweep

Exhaustive Graft identifies exactly two `string(@doc)` readers: `test/runtests.jl:11137` and `test/test_api_docstrings.jl:40`. Both are addressed. The existing documentation-binding presence property remains unchanged. Graft saved approximately 148,520 tokens in this bounded sweep.

## 8. Independent controls

Estimated under 30 seconds per process, capped Julia/BLAS/OMP one thread, offline package mode, no fits. Exact proposed readers passed nine independent assertions on Julia 1.10.0 in 1.17 seconds and Julia 1.13.1 in 4.24 seconds. Controls check Markdown output, the exact refusal phrase, all animal-model content checks and binding presence. Removing or reversing the refusal phrase makes its occurrence check false. Earlier canonical plain rendering controls also passed nine assertions per runtime with whitespace normalization; these are additional executions of related controls, not independent scientific samples and not part of the proposed patch.

## 9. Author evidence inspected

Author green logs contain the unchanged malformed-block group 13/13, API documentation property 3/3 and animal-model help 5/5 on each runtime, with `DOC_CONTRACTS_PASS`. The driver dispatches only the unsupported route, which rejects before fitting. The author retained the initial diagnostic macro error and its log. All failed attempts remain in the packet.

## 10. Limits and carried work

This review does NOT cover a new full package run, hosted platform acceptance, model calibration, release or Julia landing. The observed hosted failure supplied for this review is the Linux job; no separate Windows documentation-failure log was needed or independently established. Local ARM runtime controls support the API repair but do not establish all hosted jobs. Parent must refresh runner/test freeze and package evidence after integration. Numerical source identity permits retaining earlier source-scoped bridge/docs evidence only under the parent's normal input attestation.

## 11. Memory and Golden Set

Memory receipt: no memory-derived technical fact is used; current source, shipped Julia API and retained logs are the evidence. Golden Set: original exact refusal and help assertions, plus deletion/reversal negative controls. No source, environment, campaign, manifest or public file was modified by this reviewer.

## 12. Verdict and next action

PASS for the exact frozen two-file test delta. No source repair or assertion weakening is required. Parent may integrate the pinned patch, refresh changed test evidence and run the required fresh package and hosted checks. Highest status remains a reviewed local test repair until those gates complete.

Signed: independent Sol reviewer, Gauss and Rose lenses, 2026-10-01 UTC.
