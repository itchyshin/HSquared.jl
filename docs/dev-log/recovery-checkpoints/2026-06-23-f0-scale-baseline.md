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

## F1 after — inbreeding wall removed; next wall is the fit

Post-F1 (Meuwissen–Luo) scale run on fir (`f0_scale2_45510086`, julia 1.10.10,
single-thread, mem 128G):

| q | nnz(Ainv) | Ainv build | fit_ai_reml | PCG | selinv PEV | peak RSS | converged |
|---|---|---|---|---|---|---|---|
| 30,000 | 140,400 | 0.021 s | 0.51 s | 0.030 s | 0.026 s | 546 MB | yes |
| 100,000 | 468,000 | 0.054 s | 2.82 s | 0.061 s | 0.072 s | 923 MB | yes |
| 300,000 | 1,404,000 | 0.337 s | 35.6 s | 0.193 s | 0.361 s | 1,399 MB | **no** |

- **Inbreeding wall gone.** Ainv build is now O(n) and negligible (0.021 → 0.337 s
  from q=30k → 300k; the dense path was 0.412 s at q=10⁴ and impossible beyond).
  Peak RSS ≈1.4 GB at 300k (no dense matrix).
- **Next wall = `fit_ai_reml`**: 0.51 → 2.82 → 35.6 s (100k→300k is 3× size but
  12.6× time → super-linear), and it **fails to converge at q=300k** within the
  default iterations/tol. This is the **F2 (fill-reducing ordering) + F3 (AI-REML
  convergence hardening)** target. `fit_ai_reml` is unchanged by F1, so this is the
  next measure-first finding, not an F1 regression.

## F3 resolution — the "fit" wall was convergence, not factorization

The q=300k `fit_ai_reml` wall (35.6 s, non-converged) was **not** the factorization.
Measured (`sim/drac/f2_ordering_experiment.jl`): the sparse Cholesky is **0.15 s** at q=300k
and METIS ordering gives only ~1% fill improvement (`nnz(L)` ×1.01) — the half-sib MME barely
fills in, so ordering is not the lever (**METIS dropped, not implemented**). The cost was
`fit_ai_reml` iterating to its 100-cap because `hypot(score) < tol` is not scale-invariant
(the REML score scales with n; σ̂² was already at truth). **F3** adds a relative-VC-change
criterion:

| q | before (fit_s / conv) | after F3 (fit_s / conv) |
|---|---|---|
| 100,000 | 2.82 s / yes | **0.875 s / yes** |
| 300,000 | 35.64 s / **no** | **2.30 s / yes** |

→ 15.5× at q=300k and a correctness fix (the non-convergence was a false negative).
