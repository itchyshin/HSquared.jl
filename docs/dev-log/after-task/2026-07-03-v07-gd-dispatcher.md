# After-task — v0.7-G-D: opt-in GPU backend dispatcher (2026-07-03)

**Owner:** Claude solo (Opus), autonomous (goal: finish doc-25). **Branch:**
`feat/2026-07-03-v74-dispatcher` off `main` @ `feb101d6`. **Counts:** rows **55**, covered **13**,
`public_covered_count` **5** — NO covered flip. Local slice, no GPU/compute.

## Headline

Added the GPU analogue of the `:auto` solver dispatch: an opt-in `backend = :cuda` kwarg on the two
genomic-construction ops whose CPU/GPU signatures match — `genomic_relationship_matrix` and
`genomic_relationship_inverse` — routing them to their GPU twins. `backend = :cpu` (default) is
byte-identical to before the kwarg existed.

## What landed

- **`src/genomic.jl`** — `genomic_relationship_matrix(...; backend = :cpu)` and
  `genomic_relationship_inverse(G; ridge, backend = :cpu)`. `:cuda` routes to
  `gpu_genomic_relationship_matrix` / `gpu_genomic_relationship_inverse` (the `HSquaredCUDAExt`
  twins, MethodError without CUDA); `:cpu` default unchanged; invalid backend → `ArgumentError`.
  Docstrings updated.
- **`test/runtests.jl`** — "v0.7 G-D backend dispatch" testset (7 assertions): `:cpu` byte-identical
  (matrix, vanraden2, inverse), `:cuda` → `MethodError` (both ops), invalid backend → `ArgumentError`
  (both ops).
- **Status:** `V2-GRM-GPU` evidence + capability-status GPU row + doc-25 V7.4 → DONE.

## Scope / honesty pins

- Only the two CONSTRUCTION ops get the dispatcher — their CPU/GPU signatures match. The
  device-resident GBLUP `gpu_fit_gblup` has a DIFFERENT (from-markers) signature than the CPU
  `fit_gblup` (which takes `Ginv`), so it is NOT wired into `backend =` routing — it stays its own
  entry point. This is honest, not a gap.
- This is a TARGETED genomic-op dispatcher, NOT the general `backend_info()` `:cuda` backend (still
  `:planned`). No covered flip; `public_covered_count` UNCHANGED. `Pkg.test()` GREEN (55).

## Next (finish doc-25)

V7.3 (real/large-panel benchmark, tamia job 360812 queued) → V7.5 (close-out) → the owed V8.4
at-scale leg + coverage-calibrated intervals.
