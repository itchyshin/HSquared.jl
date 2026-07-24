# Draft close-out note to Szymek — AI-REML diagnosis + eigen fast path

**2026-07-24 · engine-performance (H2) thread · draft only**

> **DRAFT for the owner (Shinichi) to review and send; not sent by the engine lane.** This file is a
> drafted collaborator note, not an outbound message. Edit freely before sending.

## Draft note

Hi Szymek,

Thanks for the report — the slow, apparently-stuck fit on the genomic G matrix at n≈1000, plus the
ASReml comparison you ran (~12.9 s at n=10000), sent us back into the engine, and it paid off. Here's
where things landed.

First: `fit_ai_reml` isn't broken. With real genetic signal in the data, it converges cleanly in 5–8
Newton iterations, and we had the underlying REML score/Newton-step math independently re-derived to
confirm there's no bug. The apparent non-convergence traced to two artifacts on our side, not the
estimator: a stale pre-fix build, and a benchmark with no real genetic signal in it — which correctly
sits at a boundary case, not a failure.

Second, the slowness is now understood: it isn't the core algorithm, it's fill-in cost inside the
sparse factorization on pedigrees with wide age/generation spread. That pointed to a real fix — an
experimental fitter (`fit_eigen_reml`, an eigen-decompose-once approach in the EMMA/GEMMA family) that
sidesteps fill-in cost and is substantially faster on high-fill-in, moderate-size, single-effect models.
It can be slower on well-structured pedigrees, so whether it helps your case depends on your data. It's
engine-side and experimental for now, not yet wired into the R package.

Third, the crash: we added guards around the numerical failure (a non-positive-definite case) that was
causing a hard crash near degenerate variance estimates, so that path now fails gracefully instead.

Honesty note, because it matters: we haven't run ASReml ourselves, and we don't know your pedigree's
actual structure, so none of this is a verified win over ASReml — the fast numbers we have are on
synthetic pedigrees, not yours. To really close the loop: could you send your real pedigree and the
`hsquared` version you ran, so we can reproduce your exact case and confirm rather than infer?

Thanks again for pushing on this — it made the engine better.

*(Optional, skip freely: the false non-convergence combined an absolute score-norm stopping rule —
unreachable at large n — since replaced by a relative-change criterion, with a no-signal benchmark
parked at the σ²a→0 boundary. On a synthetic pedigree with realistic, narrow bandwidth, a same-size fit
already runs in well under a second, and the new eigen fitter is about 7× faster than the sparse fitter
on a synthetic high-fill case — both numbers are from our synthetic proxies, not a head-to-head against
ASReml or your data.)*

## Sources (numbers and claims grounded here — no invented figures)

- `docs/dev-log/native-engine-arc/2026-07-24-ai-reml-convergence-findings.md` — convergence diagnosis,
  the stale-build + no-signal confounds, the fill-in/selected-inverse mechanism, the realistic-bandwidth
  0.64 s figure, the eigen-vs-AI-REML crossover table (6.95× at random n=10000), and the explicit
  not-head-to-head-with-ASReml fence (§4).
- `docs/dev-log/native-engine-arc/2026-07-24-eigen-fitter-r-bridge-contract.md` — `fit_eigen_reml` scope
  (Z=I, single-effect, moderate-n, high-fill-in), and that R exposure is not yet built.
- `docs/dev-log/after-task/2026-07-24-h2-engine-perf-eigen-fitter.md` — 5–8 Newton iteration headline,
  PosDefException guard summary, and the "Szymek: close the loop" next action.
