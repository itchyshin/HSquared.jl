# F0 — adversarial high-fill measure + the F6-or-not decision (Wave F, Track A)

**2026-07-24 · OPT-IN measurement, NOT a CI gate, NOT a performance claim ·
`public_covered_count` stays 5, no capability-status row moves.**

Companion to the 2026-06-23 F0 baseline (`2026-06-23-f0-scale-baseline.md`). That
baseline measured only a **benign half-sib** pedigree and found the direct sparse
path scales cleanly. The Wave-F Phase-2 plan review (Gauss/Rose, 2026-07-24)
flagged that this makes "no wall" a foregone conclusion, and required an
**adversarial high-fill** leg before the F6 (matrix-free PCG) question could be
decided honestly. Harness: `sim/drac/f0_adversarial_fill.jl` (committed `533cf0f8`),
a small-founder **random-mating** pedigree whose MME fills in heavily. Fill is the
same `nnz(L)/n` metric the `:auto` router uses (`_AUTO_EIGEN_FILL_THRESHOLD = 60`).

## Two regimes

### Regime A — low fill (half-sib; the common livestock case). NO wall.
From the 2026-06-23 baseline (post-F1 O(n) inbreeding + post-F3 convergence fix,
fir/DRAC, julia 1.10.10, single-thread):

| q | fill nnz(L)/n | Ainv build | **fit_ai_reml** | selinv PEV | peak RSS | conv |
|---|---|---|---|---|---|---|
| 100,000 | ~17–19 | 0.073 s | **0.87 s** | 0.078 s | 699 MB | yes |
| 300,000 | ~17–19 | 0.297 s | **2.30 s** | 0.359 s | 1,197 MB | yes |

The sparse Cholesky is 0.15 s at q=300k; METIS ordering gives ~1% (dropped). The
direct sparse AI-REML path is **already production-scale** here.

### Regime B — high fill (random mating). Super-linear WALL.
`sim/drac/f0_adversarial_fill.jl`, `nfounder_frac = 0.005`. Local smoke
(psychdhcp68, julia 1.10.0, single-thread):

| q | fill nnz(L)/n | chol_s (1×) | **fit_ai_reml** | selinv_s (1×) | conv |
|---|---|---|---|---|---|
| 1,000 | 50.4 | 0.001 | 0.41 s | 0.045 | yes |
| 2,000 | 76.6 | 0.004 | 1.82 s | 0.51 | yes |
| 5,000 | 148.9 | 0.056 | **32.7 s** | 5.94 | yes |

Totoro scale confirmation (julia 1.12.6, single-thread, at/across the eigen cap n=20 000):

| q | fill nnz(L)/n | chol_s | fit_ai_reml | selinv_s | peak RSS | conv |
|---|---|---|---|---|---|---|
| 10,000 | **262** | 0.065 | **132.3 s** | 26.0 | 750 MB | yes (σ̂²≈truth) |
| 20,000 | _confirmatory run in progress_ | | | | | |

The Totoro q=10 000 point is **decisive on its own**: `fit_ai_reml` takes **132 s** on the high-fill
pedigree at q=10 000, versus **0.87 s** at q=100 000 on half-sib — ~150× slower at 1/10 the size.
Note q=10 000 is *below* the eigen cap, so `:auto` (fill 262 > 60) would route it to eigen-once
(fast); the 132 s is what the direct sparse path costs when forced. The q=20 000 run (at the cap,
where eigen-once tops out) is a confirmatory add, not decision-changing.

**Reading:** unlike half-sib, the random-mating **fill ratio grows with n**
(50 → 77 → 149) and `fit_ai_reml` blows up **super-linearly** (~18× for a 2.5×
size step, 2k→5k). The single factorization stays cheap (`chol_s` = 0.056 s at
q=5k); the cost is the **Takahashi selected inverse**, which scales with `nnz(L)`
and is re-run each AI-REML iteration. This is the mechanism F6 (matrix-free PCG)
targets: it avoids forming/factoring the fill-in and the explicit selected
inverse.

## The F0 decision — F6-or-not

**F6 is NOT required for this arc's deliverable; it is the identified lever for a
DEFERRED high-fill tail.** Reasoning:

1. The goal's deliverable — a production-scale sparse fitting path for the
   univariate Gaussian model, **evidenced at q ≥ 10⁵** — is met by the **direct
   sparse AI-REML path in the low-fill regime** (Regime A: q=300k in 2.3 s,
   converged). That is the common pedigree structure (half-sib / field data).
2. The high-fill wall (Regime B) bites where **both** the direct sparse path walls
   (super-linear selinv) **and** eigen-once is unavailable (its dense O(n³) rescue
   is capped at `max_dense_n = 20 000`). That intersection — **high fill AND
   n > 20 000** — is a genuine but **narrower** boundary.
3. Therefore: **DEFER F6** (wire the existing v0.8-S2-benchmarked matrix-free PCG
   solve, `iterative_solve.jl`, into the AI-REML fit loop) to a scoped follow-on;
   it is the correct lever for the high-fill tail, consistent with the goal's own
   DEFER fence and the plan's "F6 gated on F0".

## Consequence for S4 (production-default) — scope fence

The S4 production-default declaration (staged, gated on S5+S6) must **fence its
evidenced scope to the low-fill regime** and keep the eigen `:auto` crossover,
which already routes moderate-n high-fill (n ≤ 20 000, nnz(L)/n > 60) to
`fit_eigen_reml`. The **high-fill, n > 20 000 tail is an explicit documented
boundary** of the production-scale claim (not silently in-scope), with F6 named as
its follow-on. This is exactly the "state what is NOT claimed" fence the DRM.jl
scale-claim schema requires.

## Fences
Opt-in measurement; no performance claim; no `src` change; no capability-status
move; `public_covered_count` stays 5. Benchmark + this note are the S2 (F0)
evidence leg; they do not activate or promote anything.
