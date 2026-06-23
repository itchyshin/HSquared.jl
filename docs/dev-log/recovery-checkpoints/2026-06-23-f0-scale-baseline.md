# F0 — production-sparse scale baseline (Wave F, Track A, measure-first)

**2026-06-23 · fir (DRAC, `def-snakagaw_cpu`) · julia 1.10.10 · single-thread ·
OPT-IN measurement, NOT a CI gate, NOT a performance claim.**

Harness: `sim/drac/f0_scale_benchmark.jl` (+ `f0_fir.sbatch`). Deterministic
half-sib pedigree; gene-dropping (O(q)) breeding values so AI-REML reaches an
interior optimum; times each sparse primitive separately + peak RSS.

## Result — the first scaling wall is the dense inbreeding step

| q | nnz(Ainv) | **Ainv build** | fit_ai_reml | PCG | selinv PEV | peak RSS |
|---|---|---|---|---|---|---|
| 5,000 | 23,400 | **0.083 s** | 0.025 s | 0.001 s | 0.002 s | 650 MB |
| 10,000 | 46,800 | **0.412 s** | 0.066 s | 0.004 s | 0.005 s | 1,214 MB |
| 30,000 | — | **THROWS** (`max_relationship_cache = 10000`) | — | — | — | — |

- **`pedigree_inverse` (Ainv build) is the bottleneck and the only step near a
  wall.** It scales ≈5×/doubling (quadratic) and is **memory-bound**: peak RSS
  tracks the dense `n×n` numerator-relationship matrix (~0.8 GB at q=10⁴ →
  ~80 GB at q=10⁵).
- **Hard cap at q=10⁴.** `inbreeding_coefficients` calls `_numerator_relationship`
  (`src/pedigree.jl`), which **materializes the entire dense `A` just to read its
  diagonal** (`A[i,i]−1`), guarded by `max_relationship_cache = 10_000`. Because
  `pedigree_inverse` depends on it, the whole sparse-Ainv build refuses to run
  past 10⁴.
- **`fit_ai_reml`, PCG, selinv PEV are all fast and far from their own walls** at
  10⁴ — they are not (yet) the problem. We cannot see their scaling past 10⁴
  until the inbreeding wall is removed.

## Conclusion → F1 is the critical path

**F1 (B3): Meuwissen–Luo O(n) inbreeding** replaces the dense diagonal-read with
a direct O(n·ancestors) computation of `F_i` that never forms `A`, removing both
the quadratic time and the 80 GB memory wall. Oracle: the new `F` must equal the
existing dense `inbreeding_coefficients` **exactly** on every q≤10⁴ pedigree +
the selfing / deep-inbreeding fixtures (the dense method is retained as the
validation oracle). Only after F1 can the next measure-first run reveal whether
the sparse factorization fill-in becomes the next wall (→ F2 fill-reducing
ordering).
