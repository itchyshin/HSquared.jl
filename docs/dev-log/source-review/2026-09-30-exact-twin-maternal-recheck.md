# Exact twin direct-maternal result recheck, 2026-09-30

## 1. Verdict

The earlier P1 result-shape mismatch is **fixed in the intended R candidate's current dirty work**. The committed R base still contains the defect. The current adapter reads Julia's one paired record and maps its direct and partner values to the documented R extractors. This removes the direct-maternal shape mismatch as a current candidate blocker. It does not establish live JuliaCall transport or numerical fit parity.

## 2. Scope

Read-only review of `/private/tmp/hsquared-fa-gllvm-20260927` and `/Users/z3437171/.codex/worktrees/hsquared-fa-gllvm-foundations/HSquared.jl`. Only this report and a synthetic R script were written under `/private/tmp`. Existing repo files, Julia source, campaign drivers, and dirty work were preserved. No fit, simulation, GPU work, commit, push, or external message ran.

## 3. Candidate pins

R HEAD: `fa98c262eb21694d672e671c9672491ce3369cec`, branch `codex/hsquared-fa-gllvm-20260927`, with dirty work. Julia HEAD: `a7ca8ed557b23ec23c8486365e97a7bac4b71c16`, same branch name, with dirty work.

The Julia source tree was independently hashed using the frozen driver's sorted relative path, NUL, file bytes, NUL algorithm, rooted at `src/`. It matches the requested frozen pin `d3c2de8d7f0a1a86918f15938264bbdc892a7303b5ddd488553ac923f073ad0a`.

| Current file | SHA-256 |
| --- | --- |
| Julia `src/bridge_payload_v2.jl` | `3f1c5eed39414860953898ec23e6a8cec622d90d7009f107519892b22b63a7e0` |
| R `R/julia-bridge.R` | `4cb8074949c8b843727cd4d6acf8ef720113967e5820f135c5170bc3496e24c2` |
| R `R/fit-object.R` | `a450dcc39b42189e91a264139b83c8af5fac564fccd46bc6e55dcd4ccddb1b0e` |
| R `R/extractors.R` | `d2a4c73453eb3e7c384ad656c0c046452a20a958a7cb61691b013393257ab163` |
| R `R/bridge-payload.R` | `a18645b6445069fef8f9c8202a9e08d59c26a3f84f8923c3b6105a6c19539ef9` |
| R `R/model-spec.R` | `894ad7d2eccee2c1a3eef4416a737916ffb03f39e0e189c6d5e4115fb5a07149` |
| R `tests/testthat/test-direct-maternal.R` | `7d2ba0e91e8c3a33a01045ad6afed5474947a782a294f297e40179714b4f17bf` |

The reader, regression file, and Julia producer hashes were unchanged when rechecked after the synthetic exercise.

## 4. Producer and consumer

Julia `src/bridge_payload_v2.jl:807-843` produces one correlated random-effect record: `(name, ids, direct, partner)`. It checks that the direct and maternal ID orders agree. The schema documents that paired shape at `docs/design/21-payload-v2-multiblock-schema.md:216-219`.

Current R `R/julia-bridge.R:2090-2103` reads `[1].ids`, `[1].direct`, and `[1].partner`, and sets `maternal_ids <- direct_ids`. Its normalizer at lines 2280-2388 creates `breeding_values`, `maternal_effects`, and named `random_effects$animal` / `$maternal` tables. `hs_new_fit` wraps them as `hsquared_fit`; the S3 extractors return those fields.

The formula parser and bridge payload were exercised with `y ~ animal(1 | id, pedigree = ped) + maternal_genetic(1 | dam)`. The adapter reassembles the two R pedigree blocks as one Julia correlated block, with direct incidence, partner incidence, and a shared pedigree.

## 5. Why the prior finding differs

The prior review inspected sibling HEAD `f5c0d46bdb2ae3c2dfb2cc932883610d88f67f77` and another reader hash. The intended R candidate differs. Its existing dirty diff replaces the old `[1].values` / `[2].values` requests with the paired reader described above. This correction was already present before this task. The current R test file also adds exact paired-record field assertions in its skip-guarded live parity test at lines 525-540.

## 6. Verification

Pre-run estimate: under 10 seconds, local R only. Final script run: 1.74 seconds, exit 0. Command:

```sh
OPENBLAS_NUM_THREADS=1 Rscript /private/tmp/e1-exact-twin-maternal-synthetic-20260930.R
```

The script sources the current R files, builds a real parsed specification and bridge payload, and runs the current adapter body after replacing only JuliaCall namespace calls with strict synthetic responses. It records the exact Julia lookup strings. A single producer-shaped record contains shared IDs and deliberately different direct and partner values.

## 7. Observed results

The adapter requested `[1].ids`, `[1].direct`, and `[1].partner`. Assertions passed for class, ID order, exact distinct vectors, `breeding_values()`, `maternal_effects()`, `ranef()`, degrees of freedom, observation count, and fixed-effect naming.

As a negative control, the committed R reader from `HEAD:R/julia-bridge.R` failed against the same synthetic producer at `collect(Float64, hsq_res_dm.random_effects[1].values)`. Thus the test distinguishes the corrected current reader from the defective committed reader. An initial negative-control script setup inherited the old helper environment and failed before the target lookup; binding that scratch function to the shared mocked helper environment resolved the script setup. The final run passed all assertions.

## 8. Limits

Julia was not loaded. This exercise proves the current R lookup and object mapping against the inspected producer shape. Actual JuliaCall conversion and a fitted producer result remain untested here. The existing live regression is skip-guarded. This report does not close the separate coefcov parser finding, whole E1, FA/GLLVM acceptance, or capability promotion.

## 9. Smallest follow-up

No additional reader fix is required on this current candidate. Preserve the existing three-field reader correction and paired-record live assertions when integrating the R dirty work. A Julia-free repository regression could adapt this scratch script, using strict producer-shaped mocks and exact extractor assertions. That would make this defect detectable when Julia parity tests skip. No repository edit was made or required to reach the current mapping verdict.

## 10. Coordination and retrieval

Both exact candidates received lane preflight before source review. Julia preflight showed active primary-run and pedigree-review leases; this review remained read-only. Graft was queried in both candidates before opening the returned spans. Julia Graft could not refresh its cache under the read-only permissions, so the reported exact source spans were inspected directly. Graft reported approximately 251,171 tokens saved across the two queries. The brain search returned historical control-forwarding notes; current repository source decided the shape verdict. Memory supplied only the preflight path and candidate-isolation reminder.

## 11. Final state

Scratch report and reproducible script are the only outputs. The current exact twin maps the paired direct-maternal result cleanly in the synthetic adapter exercise. The committed R base requires the already prepared reader correction. Fresh live bridge parity remains a separate evidence step.
