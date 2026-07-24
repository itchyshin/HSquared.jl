# Findings — AI-REML convergence is fine with real signal; the "wall" is per-iteration fill-in

**2026-07-24 · Claude lane · branch `codex/2026-07-13-v07-performance-localization` · engine-performance (H2, Szymek)**
**Fences honored:** `public_covered_count=5` unchanged · no capability-status move · TMB engine NOT built · paused
D1 genomic lane NOT touched · the fix choice is the owner's.

## Headline

The 2026-07-24 handover's central claim — *"`fit_ai_reml` runs to its 100-iteration cap / `not_converged`
at every size and tolerance"* — **does not reproduce on current code with real genetic signal.** It was a
**stale-checkout + no-signal artifact of an already-fixed issue (#180, Wave F3, 2026-06-23).** With real
h²=0.4 signal **on the tested, well-identified pedigrees**, `fit_ai_reml` converges in **5–7 Newton
iterations** at every size tested. There is **no convergence bug for well-identified interior problems**
(independently confirmed by an algebra re-derivation) — Gauss's audit notes a weakly-identified / flat-ridge
likelihood surface can legitimately take dozens of iterations (an existing flat-ridge 8-animal fixture takes
~69) while still converging correctly; "fast" is a well-identified-signal claim, not a universal guarantee.
The genuine remaining performance issue is **per-iteration cost**, and at least at benchmark scale that is
dominated by **Cholesky fill-in of the random benchmark pedigree**, not the algorithm.

## What was wrong with the prior measurement (two stacked confounds)

1. **Stale code.** The Totoro checkout was at `662663e`, which **predates `b39ddc7a`** — the commit that
   added the scale-invariant *relative-change* convergence criterion (`src/likelihood.jl`, #180 / Wave F3).
   That criterion's own comment documents the exact failure the handover saw: *"the absolute REML score
   scales with n, so the `hypot(score) < tol` check … becomes unreachable at large q."* The checkout has now
   been updated to `f70559c` (current tip). The brain already held this fix
   (`2026-06-23-aireml-boundary-and-wave-f-handover`, `2026-06-23-f0-scale-baseline`).
2. **No-signal data.** `bench_aireml.jl` / `bench_tol.jl` use `y = 10 + 2·randn(n)` — no genetic signal, so
   σ²a→0, AI-REML's documented hard boundary where `converged=false` is *correct*, not a bug. The
   handover's `bench_signal.jl` (claimed present) did **not** exist on Totoro; it was written for this run
   (`~/hsq_work/bench_signal.jl`, real breeding values via Mendelian sampling down the pedigree).

## Evidence

### 1. Decision hinge — converges fast with real signal (Totoro, current code)

| n | warmup | converged | iters | termination | ĥ² (true≈0.4) | wall |
|---|---|---|---|---|---|---|
| 1000 | 0 | ✅ | 6 | relative_change_tolerance | 0.49 | 0.19 s |
| 1000 | 5 | ✅ | 5 | relative_change_tolerance | 0.49 | 0.26 s |
| 2000 | 0 | ✅ | 7 | relative_change_tolerance | 0.51 | 1.31 s |
| 2000 | 5 | ✅ | 6 | relative_change_tolerance | 0.51 | 1.92 s |
| 10000 | 0 | ✅ | 7 | relative_change_tolerance | 0.48 | 169 s |
| 10000 | 5 | ✅ | 6 | relative_change_tolerance | 0.48 | 266 s |

`halv=0` throughout → interior optimum, no boundary. `em_warmup` **does not help speed** at scale (each EM
step is itself a full factorization: warmup=5 at n=10000 is *slower*, 266 s vs 169 s, for one fewer AI step)
— it is a boundary-robustness tool, not a speed tool.

### 2. Per-iteration trajectory (instrumented `score_trace`, local n=300)

```
it  score_norm   σ²a     σ²e     relchg
1   32.45        1.00    1.00    NaN
2   14.17        0.41    0.92    0.587
3    1.907       0.34    0.84    0.183
4    0.02288     0.34    0.84    0.017     ← σ² settled; interior
...
11   1.65e-8     0.34    0.84    1.2e-8    → converged via relative_change_tolerance
```

Monotone, near-quadratic Newton descent; σ² settles by iter 4; **no step-halving**. Note the final
`score_norm = 1.65e-8 > tol = 1e-8`: the **absolute** criterion never fires — the **relative-change**
criterion (#180) is what converges it. This is the per-iteration proof that the behaviour is a healthy
interior fit, and that the earlier "iteration cap" was the scale-blind absolute criterion, exactly as #180
diagnosed. (Boundary contrast: a degenerate σ²e≈0 spec gives `step_halving_exhausted`, `halv=503`,
`score_norm=5e10`, `converged=false` — the correct boundary behaviour, visibly distinct from the above.)

### 3. Independent algebra audit (Gauss, read-only)

Verdict **NO BUG (boundary-only).** The REML score, average-information matrix, and Newton step were
re-derived from scratch (Harville/Searle REML; Henderson identity `Py=R⁻¹ê`; Gilmour–Thompson–Cullis AI
form) and are **algebraically exact**, byte-unchanged since the original AI-REML commit — only the stopping
criterion ever changed. A historical false-convergence concern about step-halving (commit `96c26e16`,
reverted) was disproved rigorously (halving forces `rel_change ≥ 0.5`, so it cannot trigger spurious
convergence). Gauss's predicted trajectory — relative-change trips in ~5–15 iters while absolute score-norm
stays large — matches the measured trace exactly. Full audit: `scratchpad/gauss-aireml-audit.md`.

### 4. NEW finding — the "slow" is Cholesky fill-in of the random pedigree, not the algorithm

Per-iteration cost scales ≈ O(n³) on the benchmark pedigree (n=2000 ~0.19 s/it → n=10000 ~24 s/it). But the
random pedigree (`parents = rand(1:i-1)`) connects individuals across the whole ID range → pathological
MME-Cholesky fill-in. Limiting the parent age-range (as in real pedigrees) collapses the cost at **identical
sparsity** (`bench_fillin.jl`):

| n | pedigree | per-iter | total | speedup vs random |
|---|---|---|---|---|
| 2000 | random(full range) | 0.194 s | 1.36 s | 1× |
| 2000 | window=200 | 0.127 s | 0.76 s | 1.5× |
| 2000 | window=50 | **0.008 s** | 0.05 s | **24×** |
| 10000 | random(full range) | 24.06 s | 168 s | 1× |
| 10000 | window=200 | 0.96 s | 6.7 s | 25× |
| 10000 | window=50 | **0.08 s** | **0.64 s** | **300×** |

All rows have `Ainv_nnz ≈ 6.9–7.0/row` — the difference is fill-in/ordering, **not** matrix density. On a
`window=50` **synthetic pedigree — a bounded-parent-age-range PROXY for realistic bandwidth, not an actual
field pedigree** — the n=10000 fit is **0.64 s**, numerically below the ASReml 12.9 s Szymek reported for his
own (different, real) dataset. **This is NOT a head-to-head comparison:** no ASReml run was performed on any
pedigree in this thread, and Szymek's pedigree structure/bandwidth is unknown. The defensible claim is only
that bandwidth-limiting structure collapses the 168 s "wall" by ~260×, **not** that HSquared.jl has been shown
to beat ASReml. **Implication:** the handover's "slow" is dominated by the random benchmark pedigree's
pathological MME-Cholesky fill-in, not the algorithm.

**Correction from the brain (2026-06-23 prior work — do NOT re-add a fill-reducing ordering):** an earlier
draft of this doc recommended a fill-reducing ordering (AMD/METIS) as the lever. That was **already tested and
overturned.** CHOLMOD applies AMD by default, and `sim/drac/f2_ordering_experiment.jl` (DRAC fir) measured the
realistic half-sib MME factorization at **0.15 s for q=300k**, with METIS reducing fill by only **~1%**
(nnz(L) ×1.01) and running **3.3× slower** at q=50k (`docs/dev-log/recovery-checkpoints/2026-07-02-v08-s1-ordering-result.md`)
— *"the half-sib MME has near-zero fill-in, so AMD is already near-optimal"*
(`docs/dev-log/scout/2026-06-23-production-sparse-algorithms.md`). The random benchmark pedigree's 24 s/iter is
the opposite extreme (a deep, pathologically-connected graph AMD cannot re-order away) and is **not** a
realistic pedigree. **Corrected action:** reproduce on Szymek's ACTUAL pedigree + hsquared version. On a normal
(shallow) pedigree the factorization is already fast (0.15 s-class at q=300k), so his "slow" is most plausibly
the pre-#180 convergence issue on his installed version. Ordering re-enters ONLY if his real pedigree genuinely
re-measures as factorization-bound — the explicit re-measure gate the 2026-06-23 note already set.

**Update (2026-07-24, `bench_symbolic.jl`, Totoro):** measured whether reusing the SYMBOLIC Cholesky across AI
iterations (`cholesky!` reusing the analysis — the "ASReml does the equation once" lever) closes the gap. It is
real and correctness-preserving (`same=true`, identical iterates): **1.3–3.25× on the factorization step**. But
the factorization is a MINORITY of the per-iteration cost, so it is only **~1.0–1.45× on the total fit**.
Decisively, at random n=10000 the factorization is **0.7 s of a 170.8 s fit (<0.5 %)** — the fill-in cost lives
in the **selected inverse** (`selinv_trace_against`, the score's `tr(A⁻¹C^uu)`) + the solves on the high-fill-in
factor, NOT the Cholesky. This REFINES the "§4 slow = Cholesky fill-in" characterization to **fill-in-driven
selected-inverse cost** (the factorization itself is cheap even at scale; on realistic pedigrees the whole fit
is 0.5 s @ n=10000). So symbolic-reuse is a cheap easy win, not the ASReml-gap closer; the structural lever
remains **eigen-once** for the single-effect model (no repeated factorization AND a closed-form O(n) trace,
eliminating the selected inverse).

**Eigen-once prototype (2026-07-24, `bench_eigen.jl`, Totoro, BLAS=8 threads):** built and VALIDATED the
eigen-once single-effect fitter (eigendecompose A once — eigenvectors of A = eigenvectors of Ainv, eigenvalues
reciprocated — rotate y/X, then 1-D Brent over the variance ratio using the codebase's already-validated
`_genomic_profile_reml` evaluator). Correctness gate PASS: it recovers AI-REML's variance components to
**~1e-8** (Δσ²a ~8e-8 realistic, ~6e-9 random). Its cost is **fill-in-INDEPENDENT** — at n=10000 the realistic
(23.4 s) and random (25.4 s) fits are essentially equal, both dominated by the dense O(n³) eigendecomposition.
The crossover:

| | eigen-once | AI-REML | speedup |
|---|---|---|---|
| realistic n=2000 | 0.43 s | 0.17 s | 0.38× (eigen loses) |
| realistic n=10000 | 23.4 s | 0.64 s | 0.03× (eigen loses badly) |
| random n=2000 | 0.47 s | 1.35 s | 2.89× |
| random n=5000 | 4.34 s | 19.6 s | 4.52× |
| random n=10000 | 25.4 s | 176.9 s | **6.95×** |

VERDICT: eigen-once is the right fitter for **moderate-n, high-fill-in / dense-genomic-G** single-effect models
(fixed O(n³) cost, no selected inverse, advantage grows with fill-in); sparse AI-REML stays right for **large,
well-structured** pedigrees (dense n³ + memory wall at large n). vs the ASReml 12.9 s Szymek cited at n=10000,
eigen-once (25.4 s) is ~2× slower at only 8 threads — but dense eigendecomposition parallelizes (Totoro/DRAC
have 100s of cores) while the sparse path does not, so more cores would likely close that. The clean design is
adaptive dispatch by n/fill-in — the engine already does this for the genomic route (`method=:auto`). Only for
Z=I single-random-effect; K≥2 cannot be simultaneously diagonalized.

## Secondary items surfaced (out of scope here — flagged, not fixed)

- **Robustness / crash risk (connects to Szymek's "crash"):** the main AI-Newton loop's Cholesky
  (`src/likelihood.jl` main loop) lacks the `PosDefException` guard the EM-warmup loop has. Near the σ²a→0
  boundary at scale this throws an **uncaught** exception and crashes rather than returning
  `converged=false`. Mirror the EM loop's `try/catch`. (Gauss §4.)
- **Validation gap:** no regression test pins an AI-REML iteration-count upper bound on a realistic-signal,
  moderate-n fixture. Capture this run's real-signal fixture as exactly such a test (expected ~5–7 iters at
  n≤10⁴). (Gauss "Validation gap".)

## Change landed in this thread

- `src/likelihood.jl` `_fit_ai_reml_diagnostics`: **append-only** `score_trace` per-iteration diagnostic
  (`(iter, score_norm, σ²a, σ²e, rel_change)`) in the diagnostics payload. Public `fit_ai_reml` `.fit` path
  **byte-identical**. Local `Pkg.test()` green; typed-assert verify passes. (Uncommitted — owner to decide
  whether to keep.)

## What this decides for the arc

- The "engine doesn't converge / is broken" framing is **retired**: on current code + real signal, **for
  well-identified problems**, it is fast and correct; weakly-identified (flat-ridge) problems remain
  slow-but-correct (dozens of iters) — not a bug, but not fast either. The **cheap Option-A ladder** is:
  (1) reproduce on Szymek's REAL pedigree + hsquared version; (2) the boundary-Cholesky crash guard
  (Gauss §4); (3) validate promoting the now-proven-fast `fit_ai_reml` over the derivative-free default.
  **Ordering is NOT on the ladder** — CHOLMOD's default is AMD and METIS was measured-and-overturned on the
  real MME (2026-06-23). And **not** the TMB native engine, which stays a deferred, owner-gated endpoint.
- Owner decision still pending only for the TMB path (the D-2026-06-12 pivot) — and nothing here requires it.

> Related: `2026-07-24-ai-reml-convergence-diagnosis-ultraplan.md` (plan + result) ·
> `scratchpad/gauss-aireml-audit.md` · brain `2026-06-23-aireml-boundary-and-wave-f-handover` (#180).
