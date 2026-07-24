# Ultra-Plan — AI-REML convergence: boundary or bug? (H2 engine-performance thread)

**2026-07-24 · Claude lane · branch `codex/2026-07-13-v07-performance-localization`**

## 🎯 GOAL (copy-paste to set a fresh session's goal)

```
Diagnose whether `fit_ai_reml` (HSquared.jl, the AI-REML Newton REML path) genuinely fails to
converge, or only appeared to because of a stale benchmark. SOLO PLATFORM = Claude (this session,
user-driven live Totoro compute — the codex/ branch name is leftover, not the platform).

DELIVERABLE: a grounded boundary-vs-bug verdict on fit_ai_reml convergence, backed by a real-signal
benchmark on CURRENT code + a per-iteration score-norm trajectory + an independent algebra audit,
written to docs/dev-log/native-engine-arc/. This decides the H2 engine-performance arc (cheap fix vs
the deferred TMB program).

HEADLINE (the one leverage item): the prior "fit_ai_reml never converges" measurement ran on a STALE
Totoro checkout (662663e, pre-#180) on NO-SIGNAL data. The brain already recorded the fix — Wave F3
/#180 (2026-06-23): the absolute score-norm test is unreachable at large n, replaced by a relative
VC-change criterion (q=300k 35.6s→2.3s). Re-measure on current code + REAL h²=0.4 signal FIRST; the
result likely collapses the whole "engine is broken" framing.

IN PARALLEL (cheap): Gauss lens audits the REML score / AI-matrix / convergence algebra in
_fit_ai_reml_diagnostics for a genuine bug, read-only, while the Totoro benchmark runs.

DEFER (fenced — do NOT touch): the TMB native engine (conditional endpoint, gated on this result +
owner sign-off on the D-2026-06-12 pivot); the PAUSED D1 genomic-recovery lane (D-68); any
capability/public claim (public_covered_count=5 stays put); the actual fix choice is the OWNER's.

DISCIPLINE: smoke-first on Totoro (n=200 non-empty/converged before scaling); read the output FILE,
never a pipe; instrumentation is append-only to the diagnostics payload (public .fit path byte-
identical) and must pass local Pkg.test; verify with the Gauss lens + termination_reason evidence;
Rose before any claim; close with an after-task note. No estimator verdict flips.
```

## Context

Triggered by collaborator **szymekdr** (Discord): `hsquared` is slow and crashes at genomic G n≈1000.
The 2026-07-24 handover measured (Totoro, direct Julia) that the A-inverse is fast and the REML *fit* is
the wall, and reported that `fit_ai_reml` "runs to its 100-iteration cap / `not_converged` at every size
and tolerance." This plan re-tests that claim, because orientation found it rests on two confounds.

## WHAT THE BRAIN ALREADY KNOWS (Phase 0.25 sweep — prior work found, not rebuilt)

- **`2026-06-23-aireml-boundary-and-wave-f-handover`** — *"F3 (#180) ✅ scale-invariant AI-REML
  convergence (stop on relative VC change, not the absolute score that scales with n): q=300k
  35.6 s→2.3 s (15.5×)."* This IS the relative-change block now in `src/likelihood.jl:515–526`.
- **`2026-06-23-f0-scale-baseline`** — *"fit_ai_reml … fails to converge at q=300k within the default
  iterations/tol."* (the pre-fix state the handover re-encountered).
- **`2026-06-23-wave-f-session-handover`** / **#182** — EM-REML warm-start (`em_warmup`) added for the
  σ²→0 boundary robustness; opt-in, default 0.
- **`2026-06-20-sparse-boundary-hardening`** / **`2026-06-20-large-pedigree-sparse-hardening`** —
  `fit_ai_reml` converges on an interior (σ²a, σ²e > 0) optimum; the boundary case correctly returns
  `converged = false`.

## Sweep receipt (Phase 0.25 — gate for Phase 1)

| Surface | Evidence it ran | Finding | Call |
|---|---|---|---|
| repo git state | `git status -sb`; `git log -S relative_change_tolerance`; `merge-base --is-ancestor` | branch ahead 5 (docs-only, no `src/`); local src == origin tip f70559c0; Totoro checkout **662663e predates b39ddc7a** (the #180 fix) | **update Totoro to current code (done)**; nothing else to resume |
| twin / sister repos | handover + AGENTS snapshot; hsquared is the R twin | hsquared untouched this thread, bridges to Julia; no native engine involved in the diagnosis | n/a for this arc |
| brain (`search_all_projects: true`) | `search_notes "AI-REML convergence score norm boundary sigma_a2 relative change"` | #180 F3 fix (relative VC criterion) + #182 EM warm-start already landed 2026-06-23; interior optima converge | **reuse** — re-measure on current code, don't re-derive |
| **Verdict** | — | The "never converges" claim is **not genuinely new**; it is a stale-checkout + no-signal artifact of an already-fixed issue. GAP = confirm on current code + real signal, and characterize the trajectory. | build only the measurement + trajectory |

## Two confounds in the prior measurement

1. **Stale code.** Totoro ran `662663e`, which is *before* `b39ddc7a` (#180). That checkout has only the
   absolute `ai_score_norm < tol` test — the exact criterion #180 documented as unreachable at large n.
2. **No-signal data.** `bench_aireml.jl` / `bench_tol.jl` use `y = 10 + 2·randn(n)` → σ²a→0, AI-REML's
   documented hard boundary (`converged=false` is *correct* there, not a bug). `bench_signal.jl` (the
   file the handover said existed — it does **not** exist on Totoro) must inject real signal.

## Slice table

| # | Slice | Member · model/effort | Dispatch | Time | Detail / files | Dep |
|---|---|---|---|---|---|---|
| RECON | git ancestry + Totoro checkout state + brain sweep | Ada (this session) · inline | — | done | confirmed stale checkout + brain #180 | — |
| S1 | Update Totoro checkout → f70559c | Ada · inline Bash | — | done | `git reset --hard FETCH_HEAD` | — |
| S2 | Write `bench_signal.jl` (Mendelian-sampling real signal) + smoke n=200 | Ada · inline | — | ~10 m | `~/hsq_work/bench_signal.jl` | S1 |
| S3 | Run signal benchmark, em_warmup {0,5}, n {1k,2k,10k} | Ada · inline (Totoro) | — | ~15–30 m | `~/hsq_work/signal_out.txt` | S2 |
| S4 | Gauss algebra audit (score / AI-matrix / convergence) | **Gauss · Sonnet/high** | Agent | ~parallel | read-only, `scratchpad/gauss-aireml-audit.md` | ∥ S3 |
| S5 | Instrument per-iteration score trajectory (append-only) | Ada · inline edit + `Pkg.test` | — | ~15 m | `src/likelihood.jl`, run on Totoro | S3 |
| S6 | Diagnose boundary-vs-bug + write findings + Rose claim check | Ada + Rose lens · inline | — | ~15 m | `docs/dev-log/native-engine-arc/` | S3,S4,S5 |
| VERIFY | termination_reason + trajectory + Gauss verdict agree; Pkg.test green | Ada · inline | — | ~5 m | — | S5,S6 |

LUNA/HAIKU SUITABILITY: low — the live-Totoro slices are one operator's sequential critical path; the one
genuinely independent lens (S4 Gauss) needs method judgment → Sonnet, not Haiku. No mechanical fan-out.

VERIFY: does `fit_ai_reml` converge fast (few iters, `termination_reason ∈ {relative_change_tolerance,
score_tolerance}`) on current code + real signal? Gauss finds no score/AI bug? Trajectory monotone (not
oscillating)? → boundary-artifact verdict. Any of these fail → genuine bug, localize from the trajectory.

CONSOLIDATE: findings note in `native-engine-arc/`; update mission-control / brain triage; after-task note.
FENCES: public_covered_count=5 unchanged; no capability-status move; TMB + D1 untouched; fix is owner's call.

## RESULT (2026-07-24, measured on current code f70559c + real h²=0.4 signal)

**Decision hinge RESOLVED: `fit_ai_reml` converges FAST with real signal — the "never converges" claim
was a stale-code + no-signal artifact, NOT a bug.**

| n | warmup | converged | iters | termination | ĥ² | wall |
|---|---|---|---|---|---|---|
| 1000 | 0 | ✅ | 6 | relative_change_tolerance | 0.49 | 0.19 s |
| 1000 | 5 | ✅ | 5 | relative_change_tolerance | 0.49 | 0.26 s |
| 2000 | 0 | ✅ | 7 | relative_change_tolerance | 0.51 | 1.31 s |
| 2000 | 5 | ✅ | 6 | relative_change_tolerance | 0.51 | 1.92 s |
| 10000 | 0 | ✅ | 7 | relative_change_tolerance | 0.48 | 169 s |

- All `halv=0` (no step-halving) → interior optimum, not a boundary.
- Local trajectory (n=300): score-norm 32 → 14 → 1.9 → 0.02 → … → 1.6e-8, monotone near-quadratic
  Newton descent; σ² settles by iter 4. Final score-norm 1.6e-8 > tol 1e-8 → the ABSOLUTE criterion
  never fires; the **relative-change criterion (#180)** is what converges it. Boundary-vs-bug = **boundary
  (already fixed), no bug**.
- **NEW, separate finding (the "slow" half of Szymek's report) — CONFIRMED a fill-in artifact:** per-iteration
  cost is ≈ O(n³) on the *random* benchmark pedigree, but windowing the parent age-range collapses it at
  identical nnz — n=10000 per-iter 24.06 s → **0.08 s (300×)**, total fit **0.64 s** (below the ASReml 12.9 s
  Szymek cited — NOT a head-to-head run). The "168 s wall" is random-pedigree MME-Cholesky fill-in, not the
  algorithm (`bench_fillin.jl`). **Ordering is NOT the lever** (brain 2026-06-23: AMD is CHOLMOD default,
  METIS overturned, real half-sib MME 0.15 s @ q=300k) — the action is to reproduce on Szymek's REAL pedigree
  + hsquared version; on normal structure the factorization is already fast, so his "slow" is most plausibly
  the pre-#180 convergence issue on his installed version. Not a native engine.
- Instrumentation landed: `score_trace` appended to `_fit_ai_reml_diagnostics` diagnostics payload
  (public `fit_ai_reml` `.fit` path byte-identical; local verify + typed asserts pass).
