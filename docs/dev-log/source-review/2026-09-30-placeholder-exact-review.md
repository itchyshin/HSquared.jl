# E1 exact source review: placeholders.jl, 2026-09-30

## Scope and verdict

Reviewed every line of `src/placeholders.jl` in `/Users/z3437171/.codex/worktrees/hsquared-fa-gllvm-foundations/HSquared.jl`. Full-file verdict: clean for the documented placeholder and fallback contract. No remaining source defect found. This receipt covers the two fallback definitions and their help/dispatch relationship; it does not validate estimator accuracy, model-fit result interpretation, R package architecture, or FA/GLLVM campaign gates.

Source stayed frozen. No source edits, fits, simulations, GPU work, commits, or pushes occurred. The only draft artifact written is this receipt.

## Exact pins

Branch: `codex/hsquared-fa-gllvm-20260927`; HEAD observed: `a7ca8ed557b23ec23c8486365e97a7bac4b71c16`. The worktree contains existing changes from other lanes.

`src/placeholders.jl` SHA-256 before and after review:
`e95f47efb13018fa8fc2fb7cbf6b08d4c4a1add8ca3b9c95b43ead259bf9955b`.

Supporting files had identical hashes before and after the runtime check:

| File | SHA-256 |
| --- | --- |
| `src/likelihood.jl` | `90cc76897c2b977f4bebc456d1e6c8d8f2647a7bb7ec6e8c9135884da0f17e30` |
| `test/test_api_docstrings.jl` | `11aef2709edc07e7c4497e763e77868a66b7c0c9bf551700e0820a9b8c20a068` |
| `test/runtests.jl` | `74814093a0ae4a619c35301ee8366f758822e0c3ce6a2bff05965ab26db96b78` |

## Reviewed spans

| Current exact span | Finding |
| --- | --- |
| `src/placeholders.jl:1-8` | The high-level Julia `hsquared` entry point is documented as planned and unimplemented. |
| `src/placeholders.jl:9-11` | The generic forwards to the shared error helper and cannot return a fitted result. |
| `src/placeholders.jl:12` | Blank separator inspected. |
| `src/placeholders.jl:13-23` | The corrected generic help lists both concrete input forms, all four targets, and the unsupported-shape error. |
| `src/placeholders.jl:24-26` | The variadic fallback uses the shared error helper; concrete overloads remain more specific. |

Supporting contract spans inspected: `src/errors.jl:1-22`; `src/HSquared.jl:61,153,243,254`; `src/likelihood.jl:3429-3499`; `docs/src/api.md:213`; `test/test_api_docstrings.jl:1-47`; `test/runtests.jl:624-625,2432-2495,2671-2728,3987-4001,11111`.

The module exports both entry points and includes the typed likelihood methods before placeholders. Runtime `methods(fit_animal_model)` lists precisely three methods: `AnimalModelSpec`, four typed data arguments, and the variadic fallback. Method documentation distinguishes Henderson's solution at supplied variances from variance estimation and identifies the experimental optimizer routes. No dependency or public signature change is needed in this file.

## Completed help correction

Consulted `docs/dev-log/source-review/2026-09-30-fit-animal-model-help-correction.md`. The current placeholder hash matches its final pin. Its earlier help defect is closed and is not repeated as a new finding. The supporting likelihood and runtests hashes have changed since that receipt; its old test result was therefore not treated as fresh runtime evidence. The API-docstrings test file still matches its pin.

## Test evidence

Executed this focused check with one Julia/OpenBLAS thread and compiled modules disabled:

```sh
OPENBLAS_NUM_THREADS=1 JULIA_NUM_THREADS=1 julia --project=. --startup-file=no --compiled-modules=no -e 'using HSquared, Test; include("test/test_api_docstrings.jl"); @test_throws Phase0NotImplementedError hsquared(nothing); @test_throws Phase0NotImplementedError fit_animal_model(nothing); println(methods(fit_animal_model))'
```

Exit status 0. API binding docstrings: 3/3 pass. Implemented-method help regression: 5/5 pass. Both standalone unsupported-call assertions passed. Runtime inspection confirmed the three methods and their current source lines.

The initial attempt without `--compiled-modules=no` stopped at a sandbox EPERM while opening the Julia compiled-cache pidfile. No assertions ran in that attempt. Disabling compiled modules completed the check without escalation.

Existing estimator/target tests were inspected only: the spec route covers dense fitting, sparse fitting, Henderson supplied variances, and target/keyword guards; the four-argument route covers dense, sparse, Henderson and input guards; the AI-REML section tests dispatch and a supplied-variance guard. Their presence is evidence of intended contracts, not evidence they passed against this candidate. No fitter testset or full package suite was run.

## Findings and suggested action

No code fix required for `src/placeholders.jl`. Preserve the completed help correction and its regression. The legacy Phase0 error remains consistent with the shared error type and now describes route-specific unavailability.

Tooling finding: Graft's cached skeleton and ranked node label report the old fallback span `20-22`; the current fallback is `24-26`. Graph refresh was denied at `graft/.cache/.sync.lock` by the sandbox. The live file was read in full and runtime method locations corroborate the corrected spans. A future authorized graph refresh can repair the stale span metadata.

Lane preflight was started before source inspection and completed with exit status 0. It reported no recent foreign lane, two live leases (FA primary run and pedigree review), and a pre-existing Claude handover; silence is weak ownership evidence. This assigned source review remained read-only and wrote only this scratch receipt. Brain search was used for routing, and `route.py HSquared.jl` returned the LOAD-FIRST manifest after the absolute-worktree lookup found none. No capability status or release rung changed.

Graft reported savings: skeleton 96 tokens; ranked source pack 59,215 tokens; total approximately 59,311 tokens. These are tool estimates against reading whole indexed files, not measured model usage.
