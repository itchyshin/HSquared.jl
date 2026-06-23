# After-task — F3 AI-REML scale-invariant convergence — 2026-06-23

## Task goal

Wave F / Track A, next hardening slice after F1. F1's after-curve flagged `fit_ai_reml` as
the q=300k bottleneck (35.6 s, non-converged). Identify the real cause by measurement and
fix it. `[JL]` engine-only; existing experimental AI-REML path; no `covered` promotion.

## What the measure-first found (and overturned)

The plan (doc 17) and the citation-backed scout research both said the next lever was
**factorization ordering → inject METIS** (what WOMBAT/BLUPF90/YAMS use). I built an
experiment on the REAL sparse MME (`sim/drac/f2_ordering_experiment.jl`) and **the data
overturned it**: the Cholesky at q=300k is **0.15 s**, and METIS reduces fill by ~1%
(`nnz(L)` ×1.01) — the half-sib MME has near-zero fill-in, so AMD is already near-optimal.
**METIS was NOT implemented.** The 35.6 s was `fit_ai_reml` running to its 100-iteration cap
because the convergence check `hypot(score_a, score_e) < 1e-8` is the ABSOLUTE REML score,
which scales with n and is unreachable at q=300k — even though σ̂² had reached the truth
(0.999, 1.001). A correctness bug (false-negative `converged`) masquerading as a speed wall.

## Files changed

- `src/likelihood.jl` (`fit_ai_reml`): added a scale-invariant convergence path — also stop
  when `max(|Δσ²a|/σ²a, |Δσ²e|/σ²e) < tol` (relative VC change). The absolute-score check is
  retained (it fires first on small fits). 6 lines.
- `test/runtests.jl` ("Phase 1 AI-REML estimator"): `@test ai.iterations < 50`.
- `sim/drac/f2_ordering_experiment.jl`: the AMD-vs-METIS experiment (committed — it's the
  evidence that METIS was correctly NOT adopted).
- `docs/design/validation-debt-register.md` (V1-REML) + `docs/design/capability-status.md`
  (AI-REML row): F3 convergence clause.
- `docs/dev-log/recovery-checkpoints/2026-06-23-f0-scale-baseline.md`: F3 resolution table.
- `docs/dev-log/scout/2026-06-23-production-sparse-algorithms.md`: postscript (METIS
  overturned by measurement).
- `docs/dev-log/check-log.d/2026-06-23-f3-aireml-convergence.md`.

## Checks run and exact outcomes

- **DRAC scale (fir, opt-in):** q=300k **35.6 s/non-converged → 2.3 s/converged** (15.5×);
  q=100k 2.82 → 0.875 s. `sim/drac/results/f0_scale2_45512689.tsv`.
- **AMD-vs-METIS experiment (fir):** factorization 0.15 s at q=300k; METIS fill ×1.01 →
  METIS dropped.
- **Local `Pkg.test()`** (thread-capped, julia 1.10.10): green, `JULIA_EXIT=0`, "Testing
  HSquared tests passed" — regression-clean.
- **`docs/make.jl`:** not re-run (no docstring/API change in this slice; src change is a
  function-body convergence check). CI Documenter will confirm.
- **Real `rose-systems-auditor` audit:** __PENDING__ (next).

## Public claim audit (Rose)

- Nothing promoted to `covered`; V1-REML stays `partial`. The claim is a convergence
  correctness + speed fix on the existing experimental path, with the numbers framed as
  opt-in single-machine DRAC measurements (not competitive/performance claims).
- Honest boundary: the in-CI test cannot reproduce the large-n non-convergence (only
  manifests ~q≥200k); it guards efficient convergence, the DRAC checkpoint demonstrates the
  scale fix.

## What did not go smoothly / lessons

- **The research-recommended fix (METIS) was wrong for this workload — caught by
  measuring.** The literature correctly describes production practice; the measured
  bottleneck here was convergence, not ordering. This is the single best example this
  session of why measure-first beats assume-and-implement. (METIS stays a candidate only if
  a deep multi-generation pedigree re-measures as factorization-bound.)
- The benchmark uses a SHALLOW half-sib pedigree (minimal fill); a deep pedigree is the
  honest stress case for the ordering question and for inbreeding-path depth — a future
  measure-first.

## Next actions

1. Real `rose-systems-auditor` over the branch; commit; PR; self-merge on green CI.
2. Re-run F0 measure-first after F3 to find the NEXT wall (selinv? the per-iteration solves?
   or is q=10⁶ now reachable?). Consider the deep-pedigree benchmark.
3. Track B (interleaved): finish the G0 GPU smoke, then the genomic-GPU slices.
