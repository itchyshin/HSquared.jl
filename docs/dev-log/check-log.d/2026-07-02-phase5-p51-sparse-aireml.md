# 2026-07-02 — Phase 5 P5.1: sparse K-component AI-REML (engine scale path, experimental) `[JL]`

New engine estimator `fit_sparse_multi_effect_aireml` (`src/likelihood.jl`) — the sparse
average-information REML generalization of `fit_ai_reml` to K INDEPENDENT random effects: the
production-shaped scale path behind the DENSE `fit_multi_effect_reml` oracle (which forms an
`n×n` `V` and is `max_dense_cells`-guarded). Merged PR #240 (`df95ec12` + Rose fix `6aa17ccf`,
merge `8a8a28f1`).

## Numerics

- Sparse Henderson MME `C` (`blockdiag(Aᵢ⁻¹/σᵢ²)` precision + `hcat(Zᵢ)` design), ONE sparse-Cholesky
  factorization reused per iteration.
- Each block's REML score `tr(Aᵢ⁻¹ C^{uᵢuᵢ})` read from a SINGLE Takahashi selected inverse
  (`selinv_block_traces`, `src/takahashi_selinv.jl`, `O(nnz(L))`, no dense inverse formed).
- `(K+1)×(K+1)` average-information matrix from working-variate re-solves that reuse the factor;
  AI/Newton step with step-halving + the scale-invariant relative-variance (F3) stop shared with
  `fit_ai_reml`. `σ²→0` on uninformative data self-reports `converged=false`, never NaN.

## Correctness gate (deterministic, `test/runtests.jl`)

| check | result |
| --- | --- |
| objective identity `sparse_multi_reml_loglik == _multi_effect_dense − 0.5(n−p)log2π` | ~1e-13 |
| N=1 reduces to `fit_ai_reml` (σa²/σe²/loglik) | ~1e-14 |
| analytic selected-inverse score == central-FD gradient | ~2e-8 |
| K=2 optimum reduces to dense `fit_multi_effect_reml` (loglik / VC rtol) | 1.3e-9 / 2.3e-4 |
| K=3 optimum reduces to dense (loglik / VC rtol) | 1.1e-8 / 2.0e-4 |

The ~2e-4 VC gap is the dense NelderMead oracle stopping short (dense REML gradient ~6e-9 at the
sparse optimum vs ~1e-3 at the dense stop; sparse loglik ≥ dense) — the sparse optimum is the true
stationary point, NOT an estimator error. This is a REDUCTION proof, not an absolute-accuracy claim.

## Honesty

- `validation_status()` 52→**53** (new `partial` row `V3-NEFFECT-SPARSE`; partial 35→36).
- `public_covered_count` UNTOUCHED = **5**; NOTHING flipped to covered.
- `bridge_payload_v2.jl` change is COMMENT-ONLY (no dispatch wiring; the sparse path is not exposed
  on any public/bridge surface).
- **NO performance/scale claim** — measure-first. Opt-in benchmark scaffold
  `sim/phase5_sparse_aireml_benchmark.jl` (OUT of CI, env-gated `HSQUARED_RUN_SPARSE_BENCH`);
  benchmark evidence explicitly OWED.
- Real `rose-systems-auditor` audit → PROMOTE-WITH-CHANGES (one stale "row count stays 52" comment
  made count-agnostic; applied `6aa17ccf`).

## Owed for a future covered / perf close

A pre-declared bias/MCSE recovery gate for THIS code path; a same-estimand external comparator run
through the sparse path at scale; the UNRUN sparse-vs-dense timing/scaling benchmark; production
large-`q` fixtures; and the R multi-term `(1|g)` bridge to the sparse estimator.

## Checks

`Pkg.test()` green (count 53); `docs/make.jl` exit 0; CI green (Julia 1 + 1.10 + docs + documenter).
