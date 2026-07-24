# Check log — AI-REML convergence diagnosis (boundary-vs-bug)

**2026-07-24 · Claude lane · branch `codex/2026-07-13-v07-performance-localization` · engine-performance (H2, Szymek)**

## What was checked

| Check | Command / method | Result |
|---|---|---|
| Totoro checkout currency | `git fetch origin … && git reset --hard FETCH_HEAD` on `~/hsq_work/HSquared.jl` | `662663e` (stale, pre-#180) → `f70559c` (current); relative-change + em_warmup blocks present |
| Real-signal convergence | `~/hsq_work/bench_signal.jl` (Mendelian-sampling h²=0.4), Totoro | n=1000–10000: converged 5–7 it, `relative_change_tolerance`, `halv=0`, ĥ²≈0.48–0.51 |
| Per-iteration trajectory | instrumented `score_trace`, local n=300 | monotone Newton descent 32→…→1.6e-8; σ² settled by iter 4; converged via relative-change |
| Boundary contrast | degenerate σ²e≈0 spec | `step_halving_exhausted`, `halv=503`, `converged=false` (correct boundary behaviour) |
| Fill-in discrimination | `~/hsq_work/bench_fillin.jl` (windowed vs full-range pedigree) | n=10000 per-iter 24.06 s → 0.08 s (300×) at identical nnz; total fit 0.64 s |
| Algebra audit | Gauss (independent, read-only) | NO BUG (boundary-only); score/AI/Newton exact; predicted trajectory matched measurement |
| Instrumentation safety | `git diff src/likelihood.jl` | +9 / −0, append-only; public `fit_ai_reml` `.fit` path byte-identical |
| Local test suite | `julia --project=. -e 'using Pkg; Pkg.test()'` | **passed** (exit 0, `Testing HSquared tests passed`) |
| Trace verify asserts | `scratchpad/verify_trace.jl` | public path returns `AnimalModelFit` w/o `score_trace`; diagnostics carries well-formed per-iteration trace |
| Claim audit | Rose (independent, read-only) | see `scratchpad/rose-findings-audit.md` (verdict applied to findings doc) |

## Verdict

Decision hinge RESOLVED: `fit_ai_reml` converges fast (5–7 iters) with real signal on current code; the prior
"never converges" was a stale-checkout + no-signal artifact of already-fixed #180. No engine bug (Gauss). The
"slow" is random-pedigree Cholesky fill-in (300× recoverable). Boundary-vs-bug = **boundary**.

## Fences

`public_covered_count=5` unchanged · no capability-status move · no experimental→covered flip · TMB engine NOT
built · paused D1 lane NOT touched. Instrumentation `score_trace` is internal diagnostics only (uncommitted;
owner to decide). Two follow-ups flagged (PosDefException guard; iteration-count regression test).

Evidence: `docs/dev-log/native-engine-arc/2026-07-24-ai-reml-convergence-findings.md` ·
`…-diagnosis-ultraplan.md` · `scratchpad/{gauss-aireml-audit,rose-findings-audit,verify_trace}.md` ·
Totoro `~/hsq_work/{bench_signal,bench_fillin}.jl`.
