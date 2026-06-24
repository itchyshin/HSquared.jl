# Check log — EM-REML warm-start for `fit_ai_reml` (opt-in robustness)

**2026-06-23 · Wave F follow-up (NotebookLM scout lead — PX-AI).** `[JL]` engine; opt-in;
no `covered` promotion; no R edit.

## What landed

An **opt-in EM-REML warm-start** in `fit_ai_reml` (`em_warmup::Integer = 0`). Before the
AI/Newton loop it runs `em_warmup` EM-REML iterations, each reusing the same sparse MME solve
the AI loop uses. The EM update is the closed form that ZEROES the existing REML score —
`σ²a = (u'A⁻¹u + tr(A⁻¹C^uu))/q`, `σ²e = e'e/(n − p − q + tr(A⁻¹C^uu)/σ²a)` — so it is monotone
and stays strictly inside the parameter space (σ > 0). The step is taken only while it stays
finite and positive (else it stops warming up and lets AI run); a non-PD MME breaks out
cleanly. `em_warmup = 0` (default) is byte-identical to the pre-warm-start path.

- `src/likelihood.jl`: the `em_warmup` kwarg + the EM warm-start loop + a docstring paragraph.
- `test/runtests.jl`: new testset (23 assertions) — see below.
- `sim/em_warmstart_benchmark.jl` (NEW, opt-in): AI-loop iterations / convergence for
  `em_warmup ∈ {0,3,5,15}` from good and bad starts on identified gene-dropping fixtures + the
  non-identified #182 single-step fixture.
- Funnel (NO new validation_status row — appended to V1-AI-REML; count stays 48): capability-
  status AI-REML clause, validation-debt V1-REML clause, `validation_status()` V1-AI-REML clause.

## Honest findings (measured, not assumed)

- **Optimum-INVARIANT on identified problems.** On a seeded gene-dropping fixture (real genetic
  signal → σ²a > 0, converges), `em_warmup` 0/3/5/15 reach the IDENTICAL optimum (σ̂²a, σ̂²e).
- **Rescues convergence from extreme starts.** `sim/em_warmstart_benchmark.jl`: a deliberately
  bad (1e4, 1e-2) start is **non-converged at `em_warmup=0`** (the AI step overshoots to the
  boundary; 5*/25* iters) but **converges at `em_warmup ≥ 3`** (~8 iters) at both q=140 and
  q=1000. From a good start it is neutral (occasionally a couple fewer iters).
- **Does NOT fix the #182 boundary.** On the genuinely non-identified #182 single-step fixture
  (σ²a unidentified), the warm-start does NOT converge (still `converged=false`, all 100*) and
  the non-converged σ̂²a becomes path-dependent (em=3 → 3.10, em=50 → 5e-18). The boundary
  CONTRACT holds throughout (finite positive σ, never throws). `converged=false` is the honest
  signal — read the flag, not the value. This is documented, not hidden.

## Checks run and exact outcomes

- **Full `Pkg.test()` green** (julia 1.10.0, thread-capped, "Testing HSquared tests passed");
  the new `fit_ai_reml EM-REML warm-start` testset is **23/23**; Phase 0 scaffold 363/363 (the
  `validation_status()` count stays **48** — V1-AI-REML appended, no new row).
- **`docs/make.jl` green** (DocumenterVitepress build complete).
- `sim/em_warmstart_benchmark.jl` runs (numbers above; opt-in, NO CI gate, NO performance claim).
- Real `rose-systems-auditor`: **CLEAN**. Verified the EM update provably zeroes the same REML
  score (optimum-invariance is structural, not coincidental), the guards are sound, `em_warmup=0`
  is byte-identical, the testset gates an IDENTIFIED fixture for invariance + the #182 contract
  (not invariance) for the boundary, and — the key risk — **no overclaim** (the "does NOT fix
  #182" caveat + "read the flag, not the value" hinge are consistent across docstring, test, and
  all three rows; the rescue claim is fixture-scoped and cites the benchmark). Rose re-ran the
  benchmark and matched the cited numbers (5*/25* non-converged at em=0 → 8 converged at em≥3;
  #182 all 100*). One optional polish (a fixture-sensitivity note in the benchmark header) —
  applied. No required changes.

## Boundary / honesty

Opt-in (`em_warmup = 0` default → no behavior change); ROBUSTNESS only — NOT a new estimand and
it does NOT alter the σ²→0 boundary contract. Nothing promoted to `covered`. The "rescues
convergence" claim is backed by the committed benchmark; the "does not fix #182" caveat is
explicit in the docstring, the test, and the status rows.
