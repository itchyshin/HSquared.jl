# `fit_animal_model` help correction, 2026-09-30

## Scope and pins

Corrected the exported generic help after an exact-current review found that the fallback docstring said the function was not implemented, despite concrete methods. Initial hashes before the doc edit and final hashes:

| File | Before SHA-256 | After SHA-256 |
| --- | --- | --- |
| `src/placeholders.jl` | `1f429afeb1a6f65865843a414cf397236e961b6ac4083b0c6a77f642cf77de2f` | `e95f47efb13018fa8fc2fb7cbf6b08d4c4a1add8ca3b9c95b43ead259bf9955b` |
| `src/likelihood.jl` | `19974d322f39c18e9788cccc8bf9daccd2933a21bb48680c2f2f6ec8772889a3` | `ddc9371b2115497466e9f0d003d26366060108a1e03ce7141922a04cea0c70db` |
| `test/test_api_docstrings.jl` | `021b4c0ed83efbf8a156c393ee386f9c5bc6df1ac1747e032bdc27efa692ebf4` | `11aef2709edc07e7c4497e763e77868a66b7c0c9bf551700e0820a9b8c20a068` |
| `test/runtests.jl` | `b4802d82a430abc10134485a21bf387d9497d72bb2643c25afbbb6ec0cdc4691` | unchanged |

The generic now describes the supported Gaussian overloads and the `:variance_components`, `:sparse_reml`, `:ai_reml`, and `:henderson_mme` targets. The typed method docs now include the AI-REML route. Unsupported shapes still reach the fail-closed placeholder and raise `Phase0NotImplementedError`.

## Verification

Added a help regression. Before the fix it failed two assertions: the help omitted `:ai_reml` and still said the function was intentionally unimplemented. The final regression checks both input forms, all four targets, and removal of the stale claim. `test/test_api_docstrings.jl` passes 8/8, including the existing API-doc binding checks. Rose confirmed the exact final source and test pins and the claim matches the implemented overloads. This audit does not execute runtime dispatch. No fit or simulation was run. The R API and engine behavior did not change.

## Limits

This closes a help-text mismatch only. It does not validate animal-model estimators, fitted-result interpretation, R-Julia parity, or the wider FA/GLLVM gates. Rose's exact-current public-claim review is clean with the runtime-test limitation above.
