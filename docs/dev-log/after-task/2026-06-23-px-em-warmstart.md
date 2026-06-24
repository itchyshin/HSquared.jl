# After-task — EM-REML warm-start for `fit_ai_reml` (opt-in robustness) — 2026-06-23

## Task goal

Turn the NotebookLM scout's #1 lead (**PX-AI**: an EM warm-start before the AI/Newton step)
into code, as a spike → full slice. `[JL]` engine. Opt-in; **no `covered` promotion**. Two
verification goals set up front: (1) correctness — the warm-start must reach the *same*
optimum on healthy fits; (2) robustness — does it help the degenerate/near-boundary #182
cases? Honest scoping from the start: implement **plain EM-REML warm-start** (where the
monotone, in-bounds robustness comes from); the "PX" parameter-expansion is a *speed*
accelerator left as a follow-up.

## What landed

`src/likelihood.jl` — `fit_ai_reml` gains `em_warmup::Integer = 0`. Before the AI loop it runs
`em_warmup` EM-REML iterations; the EM update is the closed form that ZEROES the existing REML
score (`σ²a = (u'A⁻¹u + tr(A⁻¹C^uu))/q`, `σ²e = e'e/(n−p−q + tr(A⁻¹C^uu)/σ²a)`), reusing the
same MME solve the AI loop does. Monotone and strictly in-bounds; the step is taken only while
finite and positive (else stop warming up); non-PD MME breaks cleanly. `em_warmup = 0` (default)
is byte-identical to the pre-warm-start path. Plus: a docstring paragraph, a 23-assertion
testset, an opt-in benchmark (`sim/em_warmstart_benchmark.jl`), and three appended status-row
clauses (capability-status, validation-debt, `validation_status()` V1-AI-REML — count stays 48).

## Honest findings — what the spike actually showed

- ✅ **Optimum-INVARIANT on identified problems** (seeded gene-dropping fixture, σ²a > 0):
  identical optimum across `em_warmup` 0/3/5/15.
- ✅ **Rescues convergence from extreme starts**: a (1e4, 1e-2) start is *non-converged* at
  `em_warmup=0` (AI overshoots to the boundary) but *converges* at `em_warmup ≥ 3`, at q=140
  and q=1000 (`sim/em_warmstart_benchmark.jl`). Neutral from a good start.
- ❌ **Does NOT fix the #182 boundary.** This was the key correction to my own framing. On the
  genuinely non-identified #182 single-step fixture, the warm-start still does not converge
  (`converged=false`) and the non-converged estimate is path-dependent. The boundary *contract*
  (finite positive σ, never throws) holds throughout, and `converged=false` is the honest
  signal. So #182's real fix is **B (log-Cholesky reparam)**, not this; A and B are complementary.

So the slice is an honest, opt-in **robustness** improvement (bad-start convergence rescue +
optimum-invariance), explicitly NOT a boundary fix.

## Checks run and exact outcomes

- `using HSquared` + the new kwarg: loads; default `em_warmup=0` byte-identical (asserted).
- **Full `Pkg.test()` green** (julia 1.10.0, thread-capped): new testset **23/23**; Phase 0
  scaffold 363/363 (`validation_status()` count **48**, unchanged — V1-AI-REML appended).
- **`docs/make.jl` green**.
- Benchmark runs deterministically (opt-in; numbers in the check-log).
- Real `rose-systems-auditor`: **CLEAN** (no required changes). Verified optimum-invariance is
  structural (the EM update zeroes the same score), the guards are sound, `em_warmup=0` is
  byte-identical, the tests are honestly scoped, and there is **no overclaim** — the "does NOT
  fix #182" caveat + "read the flag, not the value" hinge are consistent across docstring, test,
  and all three rows, and the rescue claim is fixture-scoped + benchmark-cited. Rose re-ran the
  benchmark and matched the numbers. Optional polish (benchmark fixture-sensitivity note) applied.

## Public claim audit (Rose) — honesty hinges

Opt-in (`em_warmup=0` default → no behavior change). ROBUSTNESS only — NOT a new estimand, does
NOT alter the σ²→0 boundary contract, nothing `covered`. The "rescues convergence" claim is
backed by the committed benchmark; the "does NOT fix #182" caveat is explicit in the docstring,
the test, and all three status rows. The non-identified-surface path-dependence is disclosed,
not hidden.

## What did not go smoothly

- My first two "identified" test fixtures were actually at the σ²→0 boundary: 5 *unrelated*
  animals (A=I) is a flat ridge (σ²a/σ²e confounded), and a deterministic `sin/cos` `y` has no
  genetic signal (σ²a → 0). Both gave path-dependent, non-converged results — useless for an
  optimum-invariance test. Switched to **seeded gene-dropping** (real additive signal → genuine
  interior optimum) after verifying it converges. Lesson: an "identified" REML fixture needs a
  real genetic signal, not just structure in `y`.
- The benchmark surfaced a stronger-but-honest result than the spike's first probe: from a bad
  start the bare AI step *fails to converge* on some fixtures (not just "slower"), and the
  warm-start rescues it — reframed the claim from "fewer iterations" to "rescues convergence".

## Next actions

1. ✅ Real `rose-systems-auditor` — **CLEAN**, no required changes (verdict recorded above).
2. Commit on a branch; push + open the PR (CI gates the suite + docs).
3. **Then B — log-Cholesky reparam** for the σ²→0 boundary (the actual #182 fix; complements
   this warm-start). Then C (G1 tamia run) and D.
4. Follow-up (not this slice): the **PX** parameter-expansion to accelerate the EM warm-start;
   and a decision (with the benchmark as evidence) on whether to flip `em_warmup`'s default on.
