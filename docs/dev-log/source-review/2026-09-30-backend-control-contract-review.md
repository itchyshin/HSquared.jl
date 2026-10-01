# Backend control contract review, 2026-09-30

## Scope and pins

Read-only review of backend parsing and status metadata, excluding accelerator execution. Exact pins observed:

| File | SHA-256 | Pin note |
| --- | --- | --- |
| `src/backends.jl` | `b22f118ea8aeba5dceb80918ee40a3f7d698211c69e91ee6c7e6c5b718b10cf9` | checked before and after |
| `src/control.jl` | `c466b4cf9e33fcafe8b4821791af54cc559a2dab78755fa759f387f6601e6b3f` | computed on follow-up; earlier review did not record a hash |
| `test/runtests.jl` | `b4802d82a430abc10134485a21bf387d9497d72bb2643c25afbbb6ec0cdc4691` | checked before and after |

Reviewed backend definitions/parsing/status metadata (`src/backends.jl:1-21,69-167`), control integration (`src/control.jl:14-63,75-89`), and direct tests (`test/runtests.jl:81-130`). No tests or execution benchmarks were run. The control file's hash was established after the first read, so its byte identity across the full review is not claimed.

## Findings

- The current API is metadata-only. CPU is the selectable baseline. Threads can be requested, but status remains `planned` and execution is false. No thread dispatch or thread-count behavior is demonstrated by these sources/tests.
- `backend_info` returns six rows in tested order, excludes `:auto` as a row, and marks each selectable with execution false. Tests cover CPU parsing, Threads string parsing, invalid values, status flags, and invalid `backend_info` input.
- Low-severity edge: `_coerce_backend(::AbstractBackend)` accepts any subtype, while `_backend_symbol` handles only built-in types. A deliberately defined custom subtype can be accepted by control construction and later cause `backend_info` to throw a `MethodError`. `AbstractBackend` is not exported, so ordinary users do not encounter this route. Clarify whether custom backends are intended to be extensible.
- Default `AutoBackend` reports all listed backends as not requested because `:auto` is not represented in the status rows. Tests encode this behavior; its observability is limited but internally consistent.
- No accelerator code was run or reviewed for this task. No GPU capability claim follows.

## Verdict and limits

Conditional pass for backend selection and metadata contracts at the inspected spans. The review does not demonstrate threaded execution, accelerator execution, performance, or whole-file E1 completion. `src/control.jl` lacks a before-review hash, which limits exact-current reproducibility for that dependency.
