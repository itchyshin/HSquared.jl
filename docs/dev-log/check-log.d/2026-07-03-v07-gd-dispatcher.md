# Check-log — v0.7-G-D backend dispatcher (2026-07-03)

**Slice:** opt-in `backend = :cuda` kwarg on `genomic_relationship_matrix` /
`genomic_relationship_inverse` routing to their GPU twins. Branch `feat/2026-07-03-v74-dispatcher`.
Local, no compute.

## Key result

- `backend = :cpu` (default) is byte-identical to before the kwarg existed (matrix, vanraden2,
  inverse — all `==`).
- `backend = :cuda` routes to the method-less GPU stub → `MethodError` without CUDA in scope.
- Invalid backend → `ArgumentError`.
- CI-tested: "v0.7 G-D backend dispatch" testset, 7 assertions, GREEN.

## Scope

Only the two construction ops (matching CPU/GPU signatures) get the dispatcher; `gpu_fit_gblup`
(different from-markers signature than `fit_gblup(Ginv)`) stays its own entry point. A TARGETED
genomic-op dispatcher, NOT the general `backend_info()` `:cuda` backend (still `:planned`).

## Honesty

`Pkg.test()` GREEN (count 55 UNCHANGED); `V2-GRM-GPU` stays `partial`; NO covered flip;
`public_covered_count` UNCHANGED. GPU = acceleration.
